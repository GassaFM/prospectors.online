// Author: Ivan Kazmenko (gassa@mail.ru)
module earnings_all;
import std.algorithm;
import std.conv;
import std.datetime;
import std.digest.sha;
import std.exception;
import std.format;
import std.json;
import std.net.curl;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

import prospectorsc_abi;
import transaction;
import utilities;

// Curl curl;
HTTP connection;

auto getWithData (Conn) (string url, string [string] data, Conn conn)
{
/*
	curl = Curl ();
	curl.initialize ();
	curl.set (CurlOption.encoding, "deflate");
*/
	return get (url ~ "?" ~ data.byKeyValue.map !(line =>
	    line.key ~ "=" ~ line.value).join ("&"), conn);
}

string endPointBlockId;
string endPointTable;

long getBlockNumber (TimeType) (TimeType t)
{
	auto fileName = "block_by_unix_time." ~ t.toUnixTime.text ~ ".json";
	try
	{
		return File (fileName).readln.strip.to !(long);
	}
	catch (Exception e)
	{
	}

	auto raw = post
	    (endPointBlockId,
	    ["time": t.toISOExtString,
	    "comparator": "gte"],
	    connection);
	auto cur = raw.parseJSON;
	auto res = cur["block"]["num"].integer;
	File (fileName, "wb").write (res);
	return res;
}

JSONValue getTableAtMoment (TimeType) (string tableName, TimeType t)
{
	debug {writeln ("Getting table ", tableName, " at moment ", t);}
	auto blockNumber = getBlockNumber (t);
	auto fileName = tableName.text ~ "." ~ blockNumber.text ~ ".binary";
	try
	{
		return File (fileName).byLineCopy.joiner ("\n").parseJSON;
	}
	catch (Exception e)
	{
	}

	try
	{
		auto raw = getWithData
		    (endPointTable,
		    ["account": "prospectorsc",
		    "scope": "prospectorsc",
		    "table": tableName,
		    "block_num": blockNumber.text,
		    "with_block_num": "false",
		    "json": "false"],
		    connection);
//		debug {writeln (raw);}
		auto res = raw.parseJSON;
		// speedup hack: don't write to file, as it's used only once
//		File (fileName, "wb").write (res.toPrettyString);
		return res;
	}
	catch (Exception e)
	{
	}

	return JSONValue ();
}

string toCommaNumber (real value, bool doStrip)
{
	string res = format ("%+.3f", value);
	auto pointPos = res.countUntil ('.');
	if (doStrip)
	{
		while (res.back == '0')
		{
			res.popBack ();
		}
		if (res.back == '.')
		{
			res.popBack ();
		}
	}
	if (pointPos >= 5)
	{
		res = res[0..pointPos - 3] ~ ',' ~ res[pointPos - 3..$];
	}
	if (pointPos >= 8)
	{
		res = res[0..pointPos - 6] ~ ',' ~ res[pointPos - 6..$];
	}
	if (pointPos >= 11)
	{
		res = res[0..pointPos - 9] ~ ',' ~ res[pointPos - 9..$];
	}
	return res;
}

auto parseBinaryByValue (T, R) (R range)
{
	auto cur = range.array;
//	writeln (cur);
//	writeln (T.stringof);
	auto res = parseBinary !(T) (cur);
//	writeln ("!");
	assert (cur.empty || cur.length == 3);
	return res;
}

int main (string [] args)
{
	auto dfuseToken = File ("../dfuse.token").readln.strip;
	endPointBlockId = args[1];
	endPointTable = args[2];
	auto isTestnet = (args.length > 5 && args[5] == "testnet");

	connection = HTTP ();
	connection.addRequestHeader ("Authorization", "Bearer " ~ dfuseToken);

	auto nowTime = Clock.currTime (UTC ());
	nowTime = SysTime.fromUnixTime
	    (nowTime.toUnixTime () / (60 * 60) * (60 * 60), UTC ());
	auto nowUnix = nowTime.toUnixTime ();
	auto nowString = nowTime.toSimpleString[0..20];

	auto accounts = getTableAtMoment ("account", nowTime)["rows"].array
	    .map !(row => row["hex"].str.chunks (2).map !(value =>
	    to !(ubyte) (value, 16)))
	    .map !(row => parseBinaryByValue !(accountElement) (row)).array;
	auto orders = getTableAtMoment ("order", nowTime)["rows"].array
	    .map !(row => row["hex"].str.chunks (2).map !(value =>
	    to !(ubyte) (value, 16)))
	    .map !(row => parseBinaryByValue !(orderElement) (row)).array;
	auto locations = getTableAtMoment ("loc", nowTime)["rows"].array
	    .map !(row => row["hex"].str.chunks (2).map !(value =>
	    to !(ubyte) (value, 16)))
	    .map !(row => parseBinaryByValue !(locElement) (row)).array;
	auto workers = getTableAtMoment ("worker", nowTime)["rows"].array
	    .map !(row => row["hex"].str.chunks (2).map !(value =>
	    to !(ubyte) (value, 16)))
	    .map !(row => parseBinaryByValue !(workerElement) (row)).array;

	void doHtmlBalances (string allianceName)
	{
		string [] names;
		if (allianceName == "all")
		{
			names = accounts
			    .map !(account => account.name.text).array;
			names = names.filter !(line => line != "prospectorsc")
			    .array;
		}
		else
		{
			names = File (allianceName ~ ".txt")
			    .byLineCopy.map !(strip).array;
		}

		bool [string] namesSet;
		foreach (ref name; names)
		{
			namesSet[name] = true;
		}

		long [string] balances;
		long [string] flags;

		foreach (const ref account; accounts)
		{
			auto name = account.name.text;
			if (name in namesSet)
			{
				balances[name] += account.balance;
				flags[name] = account.flags;
			}
		}

		foreach (const ref order; orders)
		{
			if (order.state == 0)
			{
				balances[order.owner.text] +=
				    order.gold;
			}
		}

		immutable int buildStepLength = isTestnet ? 1500 : 15000;
		immutable int buildSteps = 3;

		long [string] plotsNum;
		long [string] buildingsNum;
		long [string] richGoldPlotsNum;

		int [string] resourceLimit;
		resourceLimit["gold"]  = 24_000_000;
		resourceLimit["wood"]  = 50_000_000;
		resourceLimit["stone"] = 53_000_000;
		resourceLimit["coal"]  = 23_000_000;
		resourceLimit["clay"]  = 18_000_000;
		resourceLimit["ore"]   = 32_000_000;

		foreach (const ref location; locations)
		{
			auto owner = location.owner.text;
			plotsNum[owner] += 1;

			auto buildStep =
			    location.building.build_step;
			auto buildAmount =
			    location.building.build_amount;
			auto buildReadyTime =
			    location.building.ready_time;
			if (buildStep + 1 == buildSteps &&
			    buildAmount == buildStepLength &&
			    buildReadyTime <= nowUnix)
			{
				buildingsNum[owner] += 1;
			}

			if (location.gold * 2 >
			    resourceLimit["gold"])
			{
				richGoldPlotsNum[owner] += 1;
			}

			auto cur = location.storage.find !(line =>
			    line.type_id == 1);
			if (!cur.empty)
			{
				balances[owner] += cur.front.amount;
			}
		}

		bool [string] isJailed;

		foreach (const ref worker; workers)
		{
			auto owner = worker.owner.text;
			if (worker.job.job_type == 8 &&
			    nowUnix < worker.job.ready_time)
			{
				isJailed[owner] = true;
			}

			auto cur = worker.backpack.find !(line =>
			    line.type_id == 1);
			if (!cur.empty)
			{
				balances[owner] += cur.front.amount;
			}
		}

		long [string] withdrawals;
		auto withdrawalsName =
		    sha256Of (args[3])
		    .format !("%(%02x%)") ~ ".log";
		foreach (line; File (withdrawalsName).byLineCopy.map !(split))
		{
			auto moment = SysTime.fromSimpleString
			    (line[0..2].join (" ") ~ "Z");
			if (nowTime < moment)
			{
				continue;
			}
			if (!line[2].startsWith ("prospectors"))
			{
				continue;
			}

			auto hexData = line[5].chunks (2)
			    .map !(x => to !(ubyte) (x, 16)).array;
			auto from = hexData.parseBinary !(Name);
			if (!line[4].split ("+").canFind (from.toString))
			{
				assert (false);
			}
			auto gold = hexData.parseBinary !(uint);
			if (!hexData.empty)
			{
				assert (false);
			}
			withdrawals[from.toString] += gold;
		}

		long [string] deposits;
		auto depositsName = sha256Of (args[4])
		    .format !("%(%02x%)") ~ ".log";
		foreach (line; File (depositsName).byLineCopy.map !(split))
		{
			auto moment = SysTime.fromSimpleString
			    (line[0..2].join (" ") ~ "Z");
			if (nowTime < moment)
			{
				continue;
			}
			if (!line[2].startsWith ("prospectors"))
			{
				continue;
			}

			auto hexData = line[5].chunks (2)
			    .map !(x => to !(ubyte) (x, 16)).array;
			auto from = hexData.parseBinary !(Name);
			if (!line[4].split ("+").canFind (from.toString))
			{
				assert (false);
			}
			auto to = hexData.parseBinary !(Name);
			if (to.toString != "prospectorsc")
			{
				assert (false);
			}
			auto pgl = hexData.parseBinary !(ulong);
			auto pglId = hexData.parseBinary !(ulong);
			auto memoEmpty = hexData.parseBinary !(ubyte);
			if (!hexData.empty)
			{ // just the memo is not empty, relax!
//				assert (false);
			}
			if (pgl % 10 != 0)
			{
				assert (false);
			}
			deposits[from.toString] += pgl / 10;
		}

		long [string] delta;

		foreach (ref name; names)
		{
			delta[name] = balances.get (name, 0) +
			    withdrawals.get (name, 0) - deposits.get (name, 0);
		}

		auto file = File (allianceName ~ ".html", "wb");

		file.writeln (`<!DOCTYPE html>`);
		file.writeln (`<html xmlns="http://www.w3.org/1999/xhtml">`);
		file.writeln (`<meta http-equiv="content-type" ` ~
		    `content="text/html; charset=UTF-8">`);
		file.writeln (`<head>`);
		file.writefln (`<title>%s earnings</title>`, allianceName);
		file.writeln (`<link rel="stylesheet" href="log.css" ` ~
		    `type="text/css">`);
		file.writeln (`</head>`);
		file.writeln (`<body>`);

		file.writefln (`<h2>Earnings:</h2>`);
		file.writeln (`<table class="log">`);
		file.writeln (`<tbody>`);

		file.writeln (`<tr>`);
		file.writefln (`<th>Rank</th>`);
//		file.writefln (`<th class="plot" width="16px">&nbsp;</th>`);
		file.writefln (`<th>Account</th>`);
		file.writefln (`<th>Gold earned</th>`);
		file.writefln (`<th>Characteristics</th>`);
		file.writeln (`</tr>`);

		bool showFT = false;
		auto queryFT = "account:simpleassets " ~
		    "action:transferf data.to:prospectorsc";
		try
		{
			auto ftName = queryFT.sha256Of.format !("%(%02x%)");
			auto ftLog = File (ftName ~ ".binary");
			foreach (line; ftLog.byLineCopy)
			{
			}
		}
		catch (Exception e)
		{
		}

		long total = 0;
		names.schwartzSort !(name => tuple (-delta[name], name));
		int num = 0;
		foreach (ref name; names)
		{
			if (balances.get (name, 0) == 0 &&
			    withdrawals.get (name, 0) == 0 &&
			    deposits.get (name, 0) == 0 &&
			    name !in plotsNum &&
			    name !in richGoldPlotsNum &&
			    name !in buildingsNum)
			{
				continue;
			}
			num += 1;

			auto style = "";
			if ((flags[name] & 1) == 1)
			{
				style = ` style="background-color:#FFFFAA"`;
			}
			if ((flags[name] & 16) == 16)
			{
				style = ` style="background-color:#BBBBBB"`;
			}
			if ((flags[name] & 17) == 17)
			{
				style = ` style="background-color:#BBBB88"`;
			}
/*
			if (name in isJailed)
			{
				style = ` style="background-color:#BBBBBB"`;
			}
*/
			file.writefln (`<tr%s>`, style);
			file.writefln (`<td class="time">%s</td>`, num);
			file.writefln (`<td class="name">%s</td>`, name);
			file.writefln (`<td class="amount">%s</td>`,
			    toCommaNumber (delta[name], true));
			string [] chars;
			if (name in plotsNum)
			{
				chars ~= plotsNum[name].text ~ " plots";
			}
			if (name in richGoldPlotsNum)
			{
				chars ~= richGoldPlotsNum[name].text ~
				    " rich gold plots";
			}
			if (name in buildingsNum)
			{
				chars ~= buildingsNum[name].text ~
				    " buildings";
			}
			auto charsString = chars.empty ? "&nbsp;" :
			    format ("%-(%s, %)", chars);
			file.writefln (`<td class="amount" ` ~
			    `style="text-align:left">%s</td>`, charsString);
			file.writeln (`</tr>`);
			total += delta[name];
		}

		file.writeln (`<tr>`);
		file.writefln (`<td>&nbsp;</td>`);
		file.writefln (`<td style="font-weight:bold">Total</td>`);
		file.writefln (`<td class="amount">%s</td>`,
		    toCommaNumber (total, true));
		file.writefln (`<td class="amount">&nbsp;</td>`);
		file.writeln (`</tr>`);

		file.writeln (`</tbody>`);
		file.writeln (`</table>`);
		file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
		file.writeln (`<h3>Disclaimer:</h3>`);
		file.writeln (`<p>This is an estimate only!<br/>`);
		file.writeln (`Currently, it takes only the following ` ~
		    `factors into account:<br/>`);
		file.writeln (`&nbsp;<tt>-</tt> all deposit actions<br/>`);
		file.writeln (`&nbsp;<tt>+</tt> all withdraw actions<br/>`);
		if (showFT)
		{
			file.writeln (`&nbsp;<tt>-</tt> all gold ` ~
			    `from the pre-sale auction<br/>`);
		}
		file.writeln (`&nbsp;<tt>+</tt> current gold balance<br/>`);
		file.writeln (`&nbsp;<tt>+</tt> gold in all open orders<br/>`);
		file.writeln (`&nbsp;<tt>+</tt> raw mined gold on all ` ~
		    `plots<br/>`);
		file.writeln (`&nbsp;<tt>+</tt> raw mined gold in all ` ~
		    `worker backpacks<br/>`);
		file.writeln (`The above notoriously does ` ~
		    `<b>NOT</b> include:<br/>`);
		file.writeln (`&nbsp;<tt>x</tt> deals with payment ` ~
		    `in PGL<br/>`);
		file.writeln (`&nbsp;<tt>x</tt> alliance member ` ~
		    `specializations<br/>`);
		file.writeln (`&nbsp;<tt>x</tt> presale items<br/>`);
		file.writeln (`&nbsp;<tt>x</tt> price of property ` ~
		    `other than gold<br/>`);
		file.writeln (`&nbsp;<tt>x</tt> ...<br/>`);
		file.writefln (`<p><a href="..">Back to main page</a></p>`);
		file.writeln (`</body>`);
		file.writeln (`</html>`);
		file.close ();
	}

	foreach (name; args.drop (5 + isTestnet).chain (only ("all")))
	{
		doHtmlBalances (name);
	}

	return 0;
}
