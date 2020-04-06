// Author: Ivan Kazmenko (gassa@mail.ru)
module show_log_banks;
import std.algorithm;
import std.ascii;
import std.conv;
import std.datetime;
import std.digest.sha;
import std.format;
import std.json;
import std.math;
import std.range;
import std.stdio;
import std.string;
import std.typecons;

import prospectorsc_abi;
import transaction;
import utilities;

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

string toAmountString (long value, bool isGold = false, bool doStrip = true)
{
	if (value == -1)
	{
		return "?";
	}
	if (isGold)
	{
		return toCommaNumber (value * 1E+0L,
		    doStrip || isGold);
	}
	else
	{
		return toCommaNumber (value * 1E-3L,
		    doStrip || isGold) ~ " kg";
	}
}

string toCoordString (Coord pos)
{
	string numString (int value)
	{
		immutable int base = 10;
		string res;
		if (value < 0)
		{
			res ~= "-";
			value = -value;
		}
		res ~= cast (char) (value / base + '0');
		res ~= cast (char) (value % base + '0');
		return res;
	}

	// as in the game: first column, then row
	auto res = numString (pos.col) ~ "/" ~ numString (pos.row);
	return res;
}

int main (string [] args)
{
	auto nowTime = Clock.currTime (UTC ());
	auto nowString = nowTime.toISOExtString[0..19];
	auto nowUnix = nowTime.toUnixTime ();

	auto fileName = sha256Of ("account:prospectorsc " ~
	    "(action:mvwrkgold OR action:mvstorgold OR action:setbankp)")
	    .format !("%(%02x%)") ~ ".log";
	auto banksLog = File (fileName, "rb").byLineCopy.map !(split).array;

	void doHtmlBanksLog (string name)
	{
		int [Coord] param;
		long [string] convByOwner;
		long [string] taxByOwner;
		long [Coord] earnByLocation;
		long [string] earnByOwner;

		string [] [] htmlLog;
		int num = 0;
		foreach (line; banksLog)
		{
			auto actor = line[3];
			auto dataHex = line[4].hexStringToBinary;
			if (line[2] == "setbankp")
			{
				auto data = dataHex.parseBinary !(setbankp);
				if (!dataHex.empty)
				{
					assert (false);
				}
				param[Coord (data.loc_id)] =
				    cast (int) (data.percent * 10 + 0.5);
				continue;
			}

			Coord loc;
			string owner;
			long amount;
			if (line[2] == "mvwrkgold")
			{
				auto data = dataHex.parseBinary !(mvwrkgold);
				if (!dataHex.empty)
				{
					assert (false);
				}

				auto workerHex = line[5..$]
				    .find !(x => x.startsWith ("worker:"))
				    .front.splitter (':').drop (2).front
				    .hexStringToBinary;
				auto worker = workerHex.parseBinary
				    !(workerElement);
				if (!workerHex.empty)
				{
					assert (false);
				}

				loc = Coord (worker.loc_id);
				owner = worker.owner.text;
				amount = data.amount;
			}
			else if (line[2] == "mvstorgold")
			{
				auto data = dataHex.parseBinary !(mvstorgold);
				if (!dataHex.empty)
				{
					assert (false);
				}

				loc = Coord (data.loc_id);
				owner = actor;
				amount = data.amount;
			}
			else
			{
				assert (false);
			}

			auto rate = (loc in param) ? param[loc] * 0.1 : 5.0;

			convByOwner[actor] += amount;
			foreach (x; line[5..$]
			    .filter !(x => x.startsWith ("account:")))
			{
				auto temp = x.split (":");
				auto accountOldHex =
				    temp[2].hexStringToBinary;
				auto accountOld = accountOldHex
				    .parseBinary !(accountElement);
				if (!accountOldHex.empty)
				{
					assert (false);
				}

				auto accountNewHex =
				    temp[3].hexStringToBinary;
				auto accountNew = accountNewHex
				    .parseBinary !(accountElement);
				if (!accountNewHex.empty)
				{
					assert (false);
				}

				auto curName = accountNew.name.text;
				auto add = accountNew.balance -
				    accountOld.balance;
				if (curName != actor &&
				    curName != "prospectorsc")
				{
					owner = curName;
					earnByOwner[owner] += add;
					earnByLocation[loc] += add;
				}
				if (curName != actor)
				{
					taxByOwner[actor] += add;
				}
			}

			string [] curHtmlLog;
			num += 1;
			curHtmlLog ~= `<tr>`;
			curHtmlLog ~= format (`<td class="amount">%s</td>`,
			    num);
			curHtmlLog ~= format (`<td class="time">%s %s</td>`,
			    line[0], line[1]);
			curHtmlLog ~= format (`<td class="place">%s</td>`,
			    toCoordString (loc));
			curHtmlLog ~= format (`<td class="amount">%s</td>`,
			    (owner == actor) ? "&nbsp;" :
			    format ("%.1f%%", rate));
			curHtmlLog ~= format (`<td class="name">%s</td>`,
			    (owner == "prospectorsd") ? "(central bank)" :
			    owner);
			curHtmlLog ~= format (`<td class="name">%s</td>`,
			    actor);
			curHtmlLog ~= format (`<td class="amount">%s</td>`,
			    toAmountString (amount, true));
			curHtmlLog ~= `</tr>`;
			htmlLog ~= curHtmlLog;
		}

		void writeHeader (ref File file, string title)
		{
			file.writeln (`<!DOCTYPE html>`);
			file.writeln (`<html xmlns=` ~
			    `"http://www.w3.org/1999/xhtml">`);
			file.writeln (`<meta http-equiv="content-type" ` ~
			    `content="text/html; charset=UTF-8">`);
			file.writeln (`<head>`);
			file.writefln (`<title>%s</title>`, title);
			file.writeln (`<link rel="stylesheet" ` ~
			    `href="../earnings/log.css" type="text/css">`);
			file.writeln (`<link rel="stylesheet" ` ~
			    `href="../maps/map.css" type="text/css">`);
			file.writeln (`</head>`);
			file.writeln (`<body>`);

			file.writefln (`<h2>%s:</h2>`, title);
		}

		void writeFooter (ref File file)
		{
			file.writefln (`<p>Generated on %s (UTC).</p>`,
			    nowString);
			file.writefln (`<p><a href="banks.html">` ~
			    `Back to banks page</a></p>`);
			file.writeln (`</body>`);
			file.writeln (`</html>`);
		}

		{
			auto file = File (name ~ "-log.html", "wt");
			writeHeader (file, "Banks log");

			file.writeln (`<table class="log">`);
			file.writeln (`<thead>`);
			file.writeln (`<tr>`);
			file.writefln (`<th>#</th>`);
			file.writefln (`<th>Timestamp</th>`);
			file.writefln (`<th>Plot</th>`);
			file.writefln (`<th>Rate</th>`);
			file.writefln (`<th>Owner</th>`);
			file.writefln (`<th>Actor</th>`);
			file.writefln (`<th>Amount</th>`);
			file.writeln (`</tr>`);
			file.writeln (`</thead>`);
			file.writeln (`<tbody>`);

			foreach (const ref line; htmlLog.retro)
			{
				file.writefln ("%-(%s\n%)", line);
			}

			file.writeln (`</tbody>`);
			file.writeln (`</table>`);
			writeFooter (file);
		}

		auto convertors = convByOwner.byKey.array;
		convertors.schwartzSort !(owner =>
		    tuple (-convByOwner[owner], owner));

		{
			auto file = File (name ~ "-convert.html", "wt");
			writeHeader (file, "Bank conversions");

			file.writeln (`<table class="log">`);
			file.writeln (`<thead>`);
			file.writeln (`<tr>`);
			file.writefln (`<th>#</th>`);
			file.writefln (`<th>Account</th>`);
			file.writefln (`<th>Raw Gold</th>`);
			file.writefln (`<th>Tax Paid</th>`);
			file.writeln (`</tr>`);
			file.writeln (`</thead>`);
			file.writeln (`<tbody>`);

			foreach (i, const ref owner; convertors)
			{
				file.writeln (`<tr>`);
				file.writefln (`<td class="amount">%s</td>`,
				    i + 1);
				file.writefln (`<td class="name">%s</td>`,
				    owner);
				file.writefln (`<td class="amount">%s</td>`,
				    toCommaNumber (convByOwner[owner], true));
				file.writefln (`<td class="amount">%s</td>`,
				    toCommaNumber (taxByOwner[owner], true));
				file.writeln (`</tr>`);
			}

			file.writeln (`</tbody>`);
			file.writeln (`</table>`);
			writeFooter (file);
		}

		auto earners = earnByOwner.byKey.array;
		earners.schwartzSort !(owner =>
		    tuple (-earnByOwner[owner], owner));
		auto banks = earnByLocation.byKey.array;
		banks.schwartzSort !(loc =>
		    tuple (-earnByLocation[loc], loc.text));

		{
			auto file = File (name ~ "-earn.html", "wt");
			writeHeader (file, "Bank earnings");

			file.writeln (`<table class="log">`);
			file.writeln (`<thead>`);
			file.writeln (`<tr>`);
			file.writefln (`<th>#</th>`);
			file.writefln (`<th>Account</th>`);
			file.writefln (`<th>Earnings</th>`);
			file.writeln (`</tr>`);
			file.writeln (`</thead>`);
			file.writeln (`<tbody>`);

			foreach (i, const ref owner; earners)
			{
				file.writeln (`<tr>`);
				file.writefln (`<td class="amount">%s</td>`,
				    i + 1);
				file.writefln (`<td class="name">%s</td>`,
				    (owner == "prospectorsd") ?
				    "(central bank)" : owner);
				file.writefln (`<td class="amount">%s</td>`,
				    toCommaNumber (earnByOwner[owner], true));
				file.writeln (`</tr>`);
			}

			file.writeln (`</tbody>`);
			file.writeln (`</table>`);

			file.writeln (`<p height="5px"></p>`);

			file.writeln (`<table class="log">`);
			file.writeln (`<thead>`);
			file.writeln (`<tr>`);
			file.writefln (`<th>#</th>`);
			file.writefln (`<th>Location</th>`);
			file.writefln (`<th>Earnings</th>`);
			file.writeln (`</tr>`);
			file.writeln (`</thead>`);
			file.writeln (`<tbody>`);

			foreach (i, const ref loc; banks)
			{
				file.writeln (`<tr>`);
				file.writefln (`<td class="amount">%s</td>`,
				    i + 1);
				file.writefln (`<td class="place">%s</td>`,
				    loc);
				file.writefln (`<td class="amount">%s</td>`,
				    toCommaNumber (earnByLocation[loc], true));
				file.writeln (`</tr>`);
			}

			file.writeln (`</tbody>`);
			file.writeln (`</table>`);
			writeFooter (file);
		}
	}

	doHtmlBanksLog ("banks");

	return 0;
}
