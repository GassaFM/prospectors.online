// Author: Ivan Kazmenko (gassa@mail.ru)
module past_auctions;
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

immutable int colorThreshold = 0x80;

alias Coord = Tuple !(int, q{row}, int, q{col});

auto toCoord (long id)
{
	return Coord (cast (short) (id & 0xFFFF), cast (short) (id >> 16));
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

string makeValue (int value)
{
	string res = value.text;
	if (res == "-1")
	{
		res = "q";
	}
	else if (value > 0)
	{
		res = text (value / 10 ^^ 6);
	}
	else if (value == 0)
	{
		res = "z";
	}
	else
	{
		assert (false);
	}
	return res;
}

int [] toColorArray (string code)
{
	return code.drop (1).chunks (2).map !(x => to !(int) (x, 16)).array;
}

int [] mixColor (T) (int [] a, int [] b, T lo, T me, T hi)
{
	return zip (a, b).map !(v =>
	    (v[0] * (hi - me) + v[1] * (me - lo)) / (hi - lo)).array;
}

int toColorInt (int [] c)
{
	int res = 0;
	foreach (ref e; c)
	{
		res = (res << 8) | e;
	}
	return res;
}

struct Building
{
	long id;
	string name;
	string sign;
	int [] loColor;
	int [] hiColor;

	this (string cur)
	{
		auto t = cur.split ("\t").map !(strip).array;
		id = t[0].to !(int);
		name = t[1];
		sign = t[2];
		loColor = toColorArray (t[3]);
		hiColor = toColorArray (t[4]);
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

int rentDaysLeft () (int secLeft)
{
	auto realDaysLeft = floor (secLeft / (1.0L * 60 * 60 * 24));
	return realDaysLeft.to !(int);
}

string auctionClass (int type)
{
	if (type == 0)
	{
		return "auction";
	}
	else if (type == 1)
	{
		return "deal";
	}
	else if (type == 2)
	{
		return "confiscation";
	}
	else if (type == 9)
	{
		return "release";
	}
	else
	{
		return "unknown";
	}
}

int main (string [] args)
{
	auto gameAccount = args[1];

	immutable int buildStepLength =
	    (args.length > 2 && args[2] == "testnet") ? 1500 : 15000;
	immutable int buildSteps = 3;

	auto nowTime = Clock.currTime (UTC ());
	auto nowString = nowTime.toISOExtString[0..19];
	auto nowUnix = nowTime.toUnixTime ();

	auto buildings = Building.init ~ File ("../buildings.txt", "rt")
	    .byLineCopy.map !(line => Building (line)).array;

	string [] resNames = ["gold", "wood", "stone",
	    "coal", "clay", "ore", "coffee", "moss"];

	auto fileName = sha256Of ("account:" ~ gameAccount ~ " " ~
	    "(action:endauction OR action:endlocexpr OR action:endlocsale" ~
	    " OR action:mkfreeloc)")
	    .format !("%(%02x%)") ~ ".log";
	auto auctionLog = File (fileName, "rb").byLineCopy.map !(split).array;
	auctionLog.schwartzSort !(line =>
	    tuple (line[0], line[1], toCoord (line[4].to !(long))), q{a > b});
	
	void doHtmlAuctionHistory (string name, bool delegate (int) pred)
	{
		auto title = name;
		if (title == "all")
		{
			title = "transfers";
		}
		auto file = File ("history-" ~ name ~ ".html", "wt");

		file.writeln (`<!DOCTYPE html>`);
		file.writeln (`<html xmlns="http://www.w3.org/1999/xhtml">`);
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

		file.writeln (`<h2>Past land ` ~ title ~ `:</h2>`);
		file.writeln (`<p>Click on a column header ` ~
		    `to sort.</p>`);
		file.writeln (`<table id="auction-history" class="log">`);
		file.writeln (`<thead>`);
		file.writeln (`<tr>`);
		file.writefln (`<th>#</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-timestamp">Timestamp</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-type">Type</th>`);
		file.writefln (`<th>Plot</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-owner">Owner</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-price">Price</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-bidder">Bidder</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-rent">Rent days left</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-gold">Gold</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-wood">Wood</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-stone">Stone</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-coal">Coal</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-clay">Clay</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-ore">Ore</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-coffee">Coffee</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-coffee">Moss</th>`);
		file.writefln (`<th class="header" ` ~
		    `id="col-building">Building</th>`);
		file.writeln (`</tr>`);
		file.writeln (`</thead>`);
		file.writeln (`<tbody>`);

		foreach (i, line; auctionLog)
		{
			if (!pred (line[2].to !(int)))
			{
				continue;
			}
			file.writeln (`<tr>`);
			file.writeln (`<td class="amount">`,
			    (auctionLog.length - i), `</td>`);
			file.writeln (`<td class="time">`,
			    line[0] ~ " " ~ line[1], `</td>`);
			auto curClass = auctionClass (line[2].to !(int));
			file.writeln (`<td class="place land-`, curClass, `">`,
			    curClass, `</td>`);
			file.writeln (`<td class="place">`,
			    toCoordString (toCoord (line[4].to !(long))),
			    `</td>`);
			file.writeln (`<td class="name">`, line[3], `</td>`);
			file.writeln (`<td class="amount">`,
			    toCommaNumber (line[6].to !(int), true), `</td>`);
			file.writeln (`<td class="name">`, line[5], `</td>`);
			file.writeln (`<td class="amount">`,
			    toCommaNumber (line[7].to !(long) / (60 * 60 * 24),
			    true), `</td>`);
			foreach (r; 0..8)
			{
				file.writefln (`<td class="plot %s-%s">` ~
				    `%s</td>`, resNames[r],
				    makeValue (line[r + 8].to !(int)),
				    toAmountString (line[r + 8].to !(int),
				    resNames[r] == "gold", false));
			}
			auto backgroundColorBuilding = 0xEEEEEE;
			auto buildingDetails = "&nbsp;";
			auto buildId = line[16].to !(int);
			if (buildId != 0)
			{
				buildingDetails =
				    buildings[buildId].name;
				auto done = line[18].to !(int) +
				    buildStepLength * line[17].to !(int);
				if (done < buildStepLength * buildSteps)
				{
					buildingDetails ~= format
					    (`, %d%% built`,
					    done * 100L /
					    (buildStepLength *
					    buildSteps));
				}
				else if (buildStepLength * buildSteps < done &&
				    done < buildStepLength * (buildSteps + 1))
				{
					buildingDetails ~= format
					    (`, %d%% upgraded`,
					    (done % buildStepLength) * 100L /
					    buildStepLength);
				}
				else if (done ==
				    buildStepLength * (buildSteps + 1))
				{
					buildingDetails ~= format
					    (`, level %d`, 2);
				}
				else if (buildStepLength * (buildSteps + 1) <
				    done &&
				    done < buildStepLength * (buildSteps + 2))
				{
					buildingDetails ~= format
					    (`, level %d, %d%% upgraded`, 2,
					    (done % buildStepLength) * 100L /
					    buildStepLength);
				}
				else if (done ==
				    buildStepLength * (buildSteps + 2))
				{
					buildingDetails ~= format
					    (`, level %d`, 3);
				}
				backgroundColorBuilding = mixColor
				    (buildings[buildId].loColor,
				    buildings[buildId].hiColor,
				    0, done, buildStepLength *
				    (buildSteps + 2)).toColorInt;
			}
			string whiteFont;
			immutable int colorThreshold = 0x80;
			if (buildId != 0 &&
			    buildings[buildId].loColor.all !(c =>
			    c < colorThreshold))
			{
				whiteFont ~= `;color:#FFFFFF`;
				whiteFont ~= `;border-color:#000000`;
			}
			file.writefln (`<td class="log" ` ~
			    `style="text-align:left;` ~
			    `background-color:#%06X%s">%s</td>`,
			    backgroundColorBuilding, whiteFont,
			    buildingDetails);
			file.writeln (`</tr>`);
		}

		file.writeln (`</tbody>`);
		file.writeln (`</table>`);
		file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
		file.writeln (`<script src="auction-history.js"></script>`);

		file.writefln (`<p><a href="..">Back to main page</a></p>`);
		file.writeln (`</body>`);
		file.writeln (`</html>`);
	}

	doHtmlAuctionHistory ("all",           x => true);
	doHtmlAuctionHistory ("auctions",      x => x == 0);
	doHtmlAuctionHistory ("deals",         x => x == 1);
	doHtmlAuctionHistory ("confiscations", x => x == 2);
	doHtmlAuctionHistory ("releases",      x => x == 9);

	return 0;
}
