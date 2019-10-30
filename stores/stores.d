// Author: Ivan Kazmenko (gassa@mail.ru)
module stores;
import core.stdc.stdint;
import std.algorithm;
import std.conv;
import std.datetime;
import std.digest.md;
import std.exception;
import std.format;
import std.json;
import std.random;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

import prospectorsc_abi;
import transaction;

alias thisToolName = moduleName !({});

alias ItemPlan = Tuple !(long, q{id}, string, q{name}, int, q{weight});

bool isResource (int id)
{
	return 1 <= id && id <= 6 || id == 31;
}

auto parseBinary (T) (ref ubyte [] buffer)
{
	static if (is (Unqual !(T) == E [], E))
	{
		size_t len; // for sizes > 127, should use VarInt32 here
		len = parseBinary !(byte) (buffer);
		E [] res;
		res.reserve (len);
		foreach (i; 0..len)
		{
			res ~= parseBinary !(E) (buffer);
		}
		return res;
	}
	else static if (is (T == struct))
	{
		T res;
		alias fieldNames = FieldNameTuple !(T);
		alias fieldTypes = FieldTypeTuple !(T);
		static foreach (i; 0..fieldNames.length)
		{
			mixin ("res." ~ fieldNames[i]) =
			    parseBinary !(fieldTypes[i]) (buffer);
		}
		return res;
	}
	else
	{
		enum len = T.sizeof;
		T res = *(cast (T *) (buffer.ptr));
		buffer = buffer[len..$];
		return res;
	}
}

int toColorHash (string name)
{
	auto d = md5Of (name);
	int color;
	foreach (value; d[].retro.take (3))
	{
		color = (color << 8) | (0x70 + (value & 0x7F));
	}
	return color;
}

string toCommaNumber (real value, bool doStrip)
{
	string res = format ("%.3f", value);
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
	if (pointPos >= 4)
	{
		res = res[0..pointPos - 3] ~ ',' ~ res[pointPos - 3..$];
	}
	if (pointPos >= 7)
	{
		res = res[0..pointPos - 6] ~ ',' ~ res[pointPos - 6..$];
	}
	if (pointPos >= 10)
	{
		res = res[0..pointPos - 9] ~ ',' ~ res[pointPos - 9..$];
	}
	return res;
}

string toAmountString (long value, bool isGold = false, byte doStrip = 1)
{
	if (value == -1)
	{
		return "?";
	}
	if (doStrip > 1)
	{
		if (value >= 10_000)
		{
			value = (value / 1000) * 1000;
		}
	}
	if (isGold)
	{
		if (doStrip > 1 && value % 1000 == 0)
		{
			return toCommaNumber (value / 1000 * 1E+0L,
			    true) ~ "K";
		}
		else
		{
			return toCommaNumber (value * 1E+0L, true);
		}
	}
	else
	{
		return toCommaNumber (value * 1E-3L,
		    !!doStrip || isGold) ~ " kg";
	}
}

int main (string [] args)
{
	auto now = Clock.currTime (UTC ());
	auto nowString = now.toSimpleString[0..20];

	auto itemList = [ItemPlan.init] ~
	    File ("items.txt").byLineCopy.map !(split)
	    .map !(t => ItemPlan (t[0].to !(long), t[1], t[2].to !(int)))
	    .array;

	long [long] total;
	long [string] [long] num;

	auto locJSON = File ("loc.binary", "rb")
	    .byLine.joiner.parseJSON;
	foreach (ref row; locJSON["rows"].array)
	{
		auto hex = row["hex"].str.chunks (2).map !(value =>
		    to !(ubyte) (value, 16)).array;
		auto location = parseBinary !(locElement) (hex);
		static immutable int [] emptyAlt = [0, 0, 0];
		if (!hex.empty && !hex.equal (emptyAlt))
		{
			assert (false);
		}

		auto owner = location.owner.text;
		foreach (stuff; location.storage)
		{
			auto typeId = stuff.type_id;
			auto amount = stuff.amount;
			num[typeId][owner] += amount;
			total[typeId] += amount;
		}
	}

	auto accountJSON = File ("account.binary", "rb")
	    .byLine.joiner.parseJSON;
	foreach (ref row; accountJSON["rows"].array)
	{
		auto hex = row["hex"].str.chunks (2).map !(value =>
		    to !(ubyte) (value, 16)).array;
		auto account = parseBinary !(accountElement) (hex);
		if (!hex.empty)
		{
			assert (false);
		}

		auto owner = account.name.text;
		foreach (purchase; account.purchases)
		{
			auto typeId = purchase.stuff.type_id;
			auto amount = purchase.stuff.amount;
			num[typeId][owner] += amount;
			total[typeId] += amount;
		}
	}

	auto items = itemList.length.to !(int);

	foreach (int id; 0..items)
	{
		if (id !in total)
		{
			continue;
		}

		auto itemName = itemList[id].name;

		auto a = num[id].byKey.array;
		a.schwartzSort !(owner => tuple (-num[id][owner], owner));

		File file;

		file = File (format ("stores.%02d.txt", id), "wt");
		file.writefln (`Tycoons by amount of %s:`, itemName);
		file.writefln ("Generated on %s (UTC).", nowString);
		file.writefln ("%-14s %12s", "Total:", total[id]);
		foreach (ref owner; a)
		{
			file.writefln ("%13s: %12s", owner, num[id][owner]);
		}
		file.close ();

		file = File (format ("stores.%02d.html", id), "wt");
		file.writefln (`<h2>Tycoons by amount of %s:</h2>`, itemName);
		file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
		file.writefln (`<p><a href="stores.html">` ~
		    `Back to stores page</a></p>`);
		file.writeln (`<table border="1px" padding="2px">`);
		file.writeln (`<tbody>`);

		file.writeln (`<tr>`);
		file.writefln (`<th>#</th>`);
		file.writefln (`<th class="plot" ` ~
		    `width="16px">&nbsp;</th>`);
		file.writefln (`<th>Account</th>`);
		file.writefln (`<th>Amount of %s</th>`, itemName);
		file.writeln (`</tr>`);

		file.writeln (`<tr>`);
		file.writeln (`<td style="text-align:right">` ~
		    `&nbsp;</td>`);
		file.writefln (`<td class="plot" width="16px">` ~
		    `&nbsp;</td>`);
		file.writeln (`<td style="font-weight:bold">` ~
		    `Total</td>`);
		file.writeln (`<td style="text-align:right">`,
		    toAmountString (total[id],
		    !isResource (id) || itemName == "raw-gold", false),
		    `</td>`);
		file.writeln (`</tr>`);

		foreach (i, ref owner; a)
		{
			file.writeln (`<tr>`);
			file.writeln (`<td style="text-align:right">`,
			    (i + 1), `</td>`);
			auto backgroundColor = (owner == "") ?
			    0xEEEEEE : toColorHash (owner);
			file.writefln (`<td class="plot" ` ~
			    `width="16px" ` ~
			    `style="background-color:#%06X">` ~
			    `&nbsp;</td>`, backgroundColor);
			file.writeln (`<td style='font-family:` ~
			    `"Courier New", Courier, monospace'>`,
			    owner == "" ? "(free plots)" : owner,
			    `</td>`);
			file.writeln (`<td style="text-align:right">`,
			    toAmountString (num[id][owner],
			    !isResource (id) || itemName == "raw-gold", false),
			    `</td>`);
			file.writeln (`</tr>`);
		}

		file.writeln (`</tbody>`);
		file.writeln (`</table>`);
		file.writefln (`<p><a href="stores.html">` ~
		    `Back to stores page</a></p>`);
		file.writeln (`</body>`);
		file.writeln (`</html>`);
		file.close ();
	}

	void doMainStoresPage ()
	{
		auto codeList = iota (1, 7).array ~ (items - 1) ~
		    iota (7, items - 1).array;
		auto codeBreaks = [31: true, 16: true, 24: true];

		File file;

		file = File ("stores.html", "wt");
		file.writeln (`<!DOCTYPE html>`);
		file.writeln (`<html xmlns=` ~
		    `"http://www.w3.org/1999/xhtml">`);
		file.writeln (`<meta http-equiv="content-type" ` ~
		    `content="text/html; charset=UTF-8">`);
		file.writeln (`<head>`);
		file.writefln (`<title>%s</title>`, "stores");
		file.writeln (`<link rel="stylesheet" ` ~
		    `href="../earnings/log.css" type="text/css">`);
		file.writeln (`<link rel="stylesheet" ` ~
		    `href="../maps/map.css" type="text/css">`);
		file.writeln (`</head>`);
		file.writeln (`<body>`);

		file.writefln (`<h2>Stores and Tycoons</h2>`);
		file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
		file.writeln (`<p><a href="..">Back to main page</a></p>`);

		file.writeln (`<table border="1px" padding="2px">`);
		file.writeln (`<tbody>`);

		file.writeln (`<tr>`);
		file.writefln (`<th>Item</th>`);
		file.writefln (`<th>Total amount</th>`);
		file.writefln (`<th>Tycoons (HTML)</th>`);
		file.writefln (`<th>Tycoons (plain text)</th>`);
		file.writeln (`</tr>`);

		foreach (id; codeList)
		{
			auto itemName = itemList[id].name;

			file.writeln (`<tr>`);
			file.writeln (`<td class="item">`,
			    itemList[id].name, `</td>`);
			file.writeln (`<td class="amount">`,
			    toAmountString (total[id],
			    !isResource (id) || itemName == "raw-gold", false),
			    `</td>`);
			file.writefln (`<td style="text-align:center">` ~
			    `<a href="stores.%02d.html">details</a></td>`, id);
			file.writefln (`<td style="text-align:center">` ~
			    `<a href="stores.%02d.txt">raw data</a></td>`, id);
			file.writeln (`</tr>`);

			if (id in codeBreaks)
			{
				file.writeln (`<tr height=5px></tr>`);
			}
		}

		file.writeln (`</tbody>`);
		file.writeln (`</table>`);
		file.writeln (`<h3>Disclaimer:</h3>`);
		file.writeln (`<p>This is an estimate only!<br/>`);
		file.writeln (`Currently, it takes into account:<br/>`);
		file.writeln (`&nbsp;<tt>+</tt> ` ~
		    `stuff in stores<br/>`);
		file.writeln (`&nbsp;<tt>+</tt> ` ~
		    `(including stuff locked up in orders)<br/>`);
		file.writeln (`&nbsp;<tt>+</tt> ` ~
		    `stuff in purchases<br/>`);
		file.writeln (`In particular, it does ` ~
		    `<b>NOT</b> include:<br/>`);
		file.writeln (`&nbsp;<tt>x</tt> ` ~
		    `stuff on workers</p>`);
		file.writeln (`<p><a href="..">Back to main page</a></p>`);
		file.writeln (`</body>`);
		file.writeln (`</html>`);
		file.close ();
	}

	doMainStoresPage ();

	return 0;
}
