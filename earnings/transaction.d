// Author: Ivan Kazmenko (gassa@mail.ru)
module transaction;
import core.bitop;
import core.stdc.stdint;
import std.algorithm;
import std.conv;
import std.datetime;
import std.exception;
import std.format;
import std.json;
import std.net.curl;
import std.range;
import std.stdio;
import std.string;
import std.traits;

uint64_t charToBase32 (char c)
{
	if ('a' <= c && c <= 'z')
	{
		return (c - 'a') + 6;
	}
	if ('1' <= c && c <= '5')
	{
		return (c - '1') + 1;
	}
	if (c == '.')
	{
		return 0;
	}
	assert (false);
}

char base32ToChar (uint64_t v)
{
	if (v == 0)
	{
		return '.';
	}
	if (1 <= v && v < 6)
	{
		return cast (char) (v - 1 + '1');
	}
	if (6 <= v && v < 32)
	{
		return cast (char) (v - 6 + 'a');
	}
	assert (false);
}

uint64_t stringToName (string input)
{
	uint64_t name = 0;
	foreach (i; 0..input.length)
	{
		name |= (charToBase32 (input[i]) & 0x1f) << (64 - 5 * (i + 1));
	}
	return name;
}

string nameToString (uint64_t input)
{
	string res;
	for (int pos = 64 - 5; input != 0; pos -= 5)
	{
		auto cur = (input >> pos) & 0x1f;
		res ~= base32ToChar (cur);
		input ^= cur << pos;
	}
	return res;
}

struct VarUint32
{
	uint value;

	this (uint value_)
	{
		value = value_;
	}

	alias value this;

	ubyte [] toBinary () const
	{
		ubyte [] res;
		uint cur = value;
		do
		{
			if (!res.empty)
			{
				res.back |= 128;
			}
			res ~= cur & 127;
			cur >>= 7;
		}
		while (cur > 0);
		return res;
	}
}

ubyte [] toBinary (T) (T value)
{
	ubyte [] res;
	static if (is (Unqual !(T) == E [], E))
	{
		res ~= VarUint32 (value.length.to !(uint)).toBinary;
		foreach (ref element; value)
		{
			res ~= element.toBinary;
		}
	}
	else
	{
		res ~= * (cast (ubyte [T.sizeof] *) (&value));
	}
	return res;
}

struct Name
{
	uint64_t value;
	alias value this;

	this (string name)
	{
		value = stringToName (name);
	}

	string toString () const
	{
		return nameToString (value);
	}
}

struct CurrencyAmount
{
	static immutable int maxNameLength = 7;

	uint64_t quantity;
	uint8_t point;
	char [maxNameLength] name;

	this (string s)
	{
		auto t = s.split (" ");
		auto r = t[0].split (".");
		point = 0;
		if (r.length == 2)
		{
			point = to !(uint8_t) (r[1].length);
			r[0] ~= r[1];
		}
		name[] = '\0';
		enforce (t[1].length <= maxNameLength);
		name[0..t[1].length] = t[1][];
		quantity = to !(uint64_t) (r[0]);
	}

	CurrencyAmount opBinary (string op)
	    (const auto ref CurrencyAmount that) const
	    if (op == "+")
	{
		enforce (this.point == that.point);
		enforce (this.name == that.name);
		CurrencyAmount res = this;
		res.quantity = this.quantity + that.quantity;
		return res;
	}

	ubyte [] toBinary () const
	{
		ubyte [] res;
		res ~= quantity.toBinary;
		res ~= point.toBinary;
		res ~= name.toBinary;
		return res;
	}
}

class AuthLevel
{
	Name actor;
	Name permission;

	this (string actor_, string permission_)
	{
		actor = actor_;
		permission = permission_;
	}

	override string toString () const
	{
		return format (`{"actor": "%s", "permission": "%s"}`,
		    actor, permission);
	}

	ubyte [] toBinary () const
	{
		ubyte [] res;
		res ~= actor.toBinary;
		res ~= permission.toBinary;
		return res;
	}
}

class Action
{
	Name account;
	Name name;
	AuthLevel [] auths;

	ubyte [] hexData;

	this (Args...) (string account_, string name_, string [] auths_,
	    Args args)
	{
		account = account_;
		name = name_;
		auths = auths_.chunks (2).map !(line =>
		    new AuthLevel (line[0], line[1])).array;
		hexData = null;
		static foreach (cur; args)
		{
			hexData ~= cur.toBinary;
		}
	}

	override string toString () const
	{
		return format (`    {
      "account": "%s",
      "name": "%s",
      "authorization": [%(
        %s,
%)
      ],
      "data": "%(%02x%)"
    }`, account, name, auths, hexData);
	}

	ubyte [] toBinary () const
	{
		ubyte [] res;
		res ~= account.toBinary;
		res ~= name.toBinary;
		res ~= auths.toBinary;
		res ~= hexData.toBinary;
		return res;
	}
}

class TransactionHeader
{
	uint expiration;
	ushort refBlockNum;
	uint refBlockPrefix;
	VarUint32 maxNetUsageWords;
	ubyte maxCpuUsageMs;
	VarUint32 delaySec;

	this ()
	{
		expiration = cast (uint) ((Clock.currTime (UTC ()) +
		    1.hours - 2.minutes).toUnixTime !(int));
		refBlockNum = ChainState.chainState.refBlockNum;
		refBlockPrefix = ChainState.chainState.refBlockPrefix;
		maxNetUsageWords = 0;
		maxCpuUsageMs = 0;
		delaySec = 0;
	}

	override string toString () const
	{
		return format (`
  "expiration": "%s",
  "ref_block_num": %s,
  "ref_block_prefix": %s,
  "max_net_usage_words": %s,
  "max_cpu_usage_ms": %s,
  "delay_sec": %s,`, SysTime.fromUnixTime (expiration.to !(long), UTC ())
		    .toISOExtString[0..$ - 1], refBlockNum, refBlockPrefix,
		    maxNetUsageWords.value, maxCpuUsageMs, delaySec.value);
	}

	ubyte [] toBinary () const
	{
		ubyte [] res;
		res ~= expiration.toBinary;
		res ~= refBlockNum.toBinary;
		res ~= refBlockPrefix.toBinary;
		res ~= maxNetUsageWords.toBinary;
		res ~= maxCpuUsageMs.toBinary;
		res ~= delaySec.toBinary;
		return res;
	}
}

class Transaction
{
	TransactionHeader header;
	Action [] contextFreeActions;
	Action [] actions;
	uint [] transactionExtensions;

	this (Action [] actions_)
	{
		header = new TransactionHeader ();
		contextFreeActions = null;
		actions = actions_;
		transactionExtensions = null;
	}

	override string toString () const
	{
		return format (`{%s
  "context_free_actions": [%(
%s,
%)
  ],
  "actions": [%(
%s,
%)
  ],
  "transaction_extensions": [%(
%s,
%)
  ]
}`, header, contextFreeActions, actions, transactionExtensions);
	}

	ubyte [] toBinary () const
	{
		ubyte [] res;
		res ~= header.toBinary;
		res ~= contextFreeActions.toBinary;
		res ~= actions.toBinary;
		res ~= transactionExtensions.toBinary;
		return res;
	}
}

class EosUrl
{
	static string defaultUrl = "https://eos.greymass.com";

	string url;

	this (string url_)
	{
		url = url_;
	}

	static EosUrl eosUrl_ = null;

	@property static string eosUrl ()
	{
		if (eosUrl_ is null)
		{
			eosUrl_ = new EosUrl (defaultUrl);
		}
		return eosUrl_.url;
	}

	@property static void eosUrl (string url_)
	{
		eosUrl_ = new EosUrl (url_);
	}
}

class ChainState
{
	ushort refBlockNum;
	uint refBlockPrefix;

	this ()
	{
		auto cur = get (EosUrl.eosUrl ~ "/v1/chain/get_info")
		    .parseJSON;
		auto temp = cur["last_irreversible_block_id"].str;
		refBlockNum = temp[4..8].to !(ushort) (16);
		refBlockPrefix = temp[16..24].to !(uint) (16).bswap;
	}

	this (string url)
	{
		EosUrl.eosUrl = url;
		this ();
	}

	static ChainState chainState_ = null;

	@property static ChainState chainState ()
	{
		if (chainState_ is null)
		{
			chainState_ = new ChainState ();
		}
		return chainState_;
	}

	@property static void chainState (ChainState that)
	{
		chainState_ = that;
	}
}

void testTransaction ()
{
	EosUrl.eosUrl = "https://jungle2.cryptolions.io";
	auto a = new Action ("eosio.token", "transfer",
	    ["useraccount1", "active"],
	    Name ("useraccount1"), Name ("useraccount2"),
	    CurrencyAmount ("0.0001 EOS") + CurrencyAmount ("0.0002 EOS"),
	    "test");
	auto t = new Transaction ([a]);
	auto s = t.toString;
	auto b = t.toBinary;
//	writeln (s);
//	writefln ("%(%02x%)", b);
}

unittest
{
//	testTransaction ();
}
