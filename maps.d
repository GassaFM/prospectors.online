// Author: Ivan Kazmenko (gassa@mail.ru)
module maps;
import std.algorithm;
import std.ascii;
import std.conv;
import std.datetime;
import std.digest.md;
import std.format;
import std.json;
import std.math;
import std.range;
import std.stdio;
import std.string;
import std.typecons;

immutable int colorThreshold = 0x80;

struct Location
{
	int row;
	int col;
	int gold;
	int wood;
	int stone;
	int coal;
	int clay;
	int ore;
	int coffee;
	int space;
	string owner;
	string name;
	long rentTime;
	short buildId;
	short buildStep;
	int buildAmount;
	long buildReadyTime;
	long [] buildJobStartTime;
	long [] buildJobReadyTime;
	long auctionCompleteTime;
	string auctionBidder;
	long auctionPrice;
}

alias Coord = Tuple !(int, q{row}, int, q{col});

auto toCoord (long id)
{
	return Coord (cast (short) (id & 0xFFFF), cast (short) (id >> 16));
}

string classString (string value)
{
	if (value.front == 'c')
	{
		return "c";
	}
	if (value.back == 'x')
	{
		return "x";
	}
	if (value == "?")
	{
		return "q";
	}
	return value;
}

string valueString (string value)
{
	if (value.back == 'x')
	{
		value.popBack ();
	}
	if (value == "c")
	{
		return "&nbsp;";
	}
	if (value == "z")
	{
		return "&nbsp;";
	}
	return value;
}

bool canImprove (string a, string b)
{
	if (!a.empty && a.back == 'x')
	{
		a.popBack ();
	}
	if (!b.empty && b.back == 'x')
	{
		b.popBack ();
	}
	auto na = a.all !(isDigit);
	auto nb = b.all !(isDigit);
	auto va = a.empty ? -4 : (a[0] == 'z') ? -2 : (a[0] == '?') ? -1 :
	    na ? a.to !(int) : -3;
	auto vb = b.empty ? -4 : (b[0] == 'z') ? -2 : (b[0] == '?') ? -1 :
	    nb ? b.to !(int) : -3;
	return va < vb;
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

int main (string [] args)
{
	immutable int buildStepLength =
	    (args.length > 1 && args[1] == "testnet") ? 1500 : 15000;
	immutable int buildSteps = 3;

	auto rentPrice = File ("stat.json", "rt").byLine.joiner
	    .parseJSON["rows"].array.front["json"]["rent_price"].integer * 30;

	auto locJSON = File ("loc.json", "rt").byLine.joiner.parseJSON;
	immutable int livePeriod = 60 * 60 * 24 * 2;
	int minRow = int.max;
	int maxRow = int.min;
	int minCol = int.max;
	int maxCol = int.min;
	int totalPlots = 0;

	auto workerJSON = File ("worker.json", "rt").byLine.joiner.parseJSON;
	int [Coord] workerNum;
	JSONValue [] [string] workersByOwner;
	foreach (ref row; workerJSON["rows"].array)
	{
		auto pos = row["json"]["loc_id"].integer;
		auto coord = toCoord (pos);
		workerNum[coord] += 1;
		auto owner = row["json"]["owner"].str;
		workersByOwner[owner] ~= row["json"];
	}

	Location [Coord] a;
	foreach (ref row; locJSON["rows"].array)
	{
		totalPlots += 1;

		auto id = row["json"]["id"].integer;
		auto coord  = toCoord (id);
		auto gold   = row["json"]["gold"]  .integer.to !(int);
		auto wood   = row["json"]["wood"]  .integer.to !(int);
		auto stone  = row["json"]["stone"] .integer.to !(int);
		auto coal   = row["json"]["coal"]  .integer.to !(int);
		auto clay   = row["json"]["clay"]  .integer.to !(int);
		auto ore    = row["json"]["ore"]   .integer.to !(int);
		auto coffee = row["json"]["coffee"].integer.to !(int);
		auto owner  = row["json"]["owner"] .str;
		auto name   = row["json"]["name"]  .str;
		auto space  = !gold && !wood && !stone && !coal && !clay &&
		              !ore && !coffee && owner == "";
		auto rentTime = row["json"]["rent_time"].integer.to !(long);
		auto buildId = row["json"]
		    ["building"]["build_id"].integer.to !(short);
		auto buildStep = row["json"]
		    ["building"]["build_step"].integer.to !(short);
		auto buildAmount = row["json"]
		    ["building"]["build_amount"].integer.to !(int);
		auto buildReadyTime = row["json"]
		    ["building"]["ready_time"].integer.to !(int);
		auto buildJobOwners = row["json"]["jobs"].array
		    .filter !(line => line["job_type"].integer == 4)
		    .map !(line => line["owner"].str).array;
		sort (buildJobOwners);
		buildJobOwners = buildJobOwners.uniq.array;
		long [] buildJobStartTime;
		long [] buildJobReadyTime;
		foreach (curOwner; buildJobOwners)
		{
			foreach (worker; workersByOwner[curOwner])
			{
				if (worker["job"]["job_type"].integer == 4 &&
				    worker["job"]["loc_id"].integer == id)
				{
					buildJobStartTime ~= worker["job"]
					    ["loc_time"].integer;
					buildJobReadyTime ~= worker["job"]
					    ["ready_time"].integer;
				}
			}
		}
		a[coord] = Location (coord.row, coord.col,
		    gold, wood, stone, coal, clay, ore, coffee,
		    space, owner, name, rentTime,
		    buildId, buildStep, buildAmount, buildReadyTime,
		    buildJobStartTime, buildJobReadyTime);
	}

	foreach (ref cur; a)
	{
		minRow = min (minRow, cur.row);
		maxRow = max (maxRow, cur.row);
		minCol = min (minCol, cur.col);
		maxCol = max (maxCol, cur.col);
	}

	auto nowTime = Clock.currTime (UTC ());
	auto nowString = nowTime.toSimpleString[0..20];
	auto nowUnix = nowTime.toUnixTime ();

	auto auctionJSON = File ("auction.json", "rt").byLine.joiner.parseJSON;
	foreach (ref row; auctionJSON["rows"].array)
	{
		auto type = row["json"]["type"].integer;
		auto target = row["json"]["target"].str;
		auto endTime = row["json"]["end_time"].integer;
		if (target != "" || endTime < nowUnix ||
		    (type != 0 && type != 2))
		{
			continue;
		}
		auto id = row["json"]["loc_id"].integer.toCoord;
		a[id].auctionPrice = row["json"]["price"].integer;
		a[id].auctionBidder = row["json"]["bid_user"].str;
		a[id].auctionCompleteTime = endTime;
	}

	auto buildings = Building.init ~ File ("../buildings.txt", "rt")
	    .byLineCopy.map !(line => Building (line)).array;

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
		if (a[pos].name != "")
		{
			res ~= ", " ~ a[pos].name;
		}
		return res;
	}

	int buildingDone () (auto ref Coord pos)
	{
		auto res = a[pos].buildAmount;
		res += buildStepLength * a[pos].buildStep;
		res *= 60;
		foreach (j; 0..a[pos].buildJobStartTime.length)
		{
			auto start = a[pos].buildJobStartTime[j];
			auto ready = a[pos].buildJobReadyTime[j];
			start = max (start, nowUnix);
			auto duration = ready - start;
			duration = max (0, duration);
			res -= duration;
		}
		res /= 60;
		return res;
	}

	int rentDaysLeft () (auto ref Coord pos)
	{
		auto rentTime = a[pos].rentTime;
		auto secLeft = rentTime - nowUnix;
		auto realDaysLeft = floor (secLeft / (1.0L * 60 * 60 * 24));
		return realDaysLeft.to !(int);
	}

	foreach (row; minRow..maxRow + 1)
	{
		foreach (col; minCol..maxCol + 1)
		{
			auto pos = Coord (row, col);
			if (pos !in a)
			{
				assert (false);
			}
			auto intDaysLeft = rentDaysLeft (pos);
			if (intDaysLeft == -8 && a[pos].auctionPrice == 0)
			{
				a[pos].auctionPrice = rentPrice;
				a[pos].auctionBidder = "";
				a[pos].auctionCompleteTime = a[pos].rentTime +
				    60 * 60 * 24 * 8;
			}
		}
	}

	void writeHtmlHeader (ref File file, string title)
	{
		file.writeln (`<!DOCTYPE html>`);
		file.writeln (`<html xmlns="http://www.w3.org/1999/xhtml">`);
		file.writeln (`<meta http-equiv="content-type" ` ~
		    `content="text/html; charset=UTF-8">`);
		file.writeln (`<head>`);
		file.writefln (`<title>%s map</title>`, title);
		file.writeln (`<link rel="stylesheet" href="map.css" ` ~
		    `type="text/css">`);
		file.writeln (`</head>`);
		file.writeln (`<body>`);
		file.writeln (`<table class="map">`);
		file.writeln (`<tbody>`);
	}

	void writeCoordRow (ref File file)
	{
		file.writeln (`<tr>`);
		file.writeln (`<td class="coord">&nbsp;</td>`);
		foreach (col; minCol..maxCol + 1)
		{
			file.writeln (`<td class="coord">`, col, `</td>`);
		}
		file.writeln (`<td class="coord">&nbsp;</td>`);
		file.writeln (`</tr>`);
	}

	alias ResTemplate = Tuple !(string, q{name},
	    int delegate (Coord), q{fun}, int, q{divisor});

	string makeValue () (auto ref ResTemplate resource, Coord pos)
	{
		auto value = resource.fun (pos);
		string res = value.text;
		if (pos == Coord (0, 0))
		{
			res = "c";
		}
		else if (res == "-1")
		{
			res = "?";
		}
		else if (value > 0)
		{
			res = text (value / resource.divisor);
		}
		else if (value == 0)
		{
			res = "z";
		}
		else
		{
			assert (false);
		}
		if (a[pos].owner != "")
		{
			res ~= "x";
		}
		return res;
	}

	int [string] resourceLimit;
	resourceLimit["gold"]   = 32_000_000;
	resourceLimit["wood"]   = 19_000_000;
	resourceLimit["stone"]  = 22_000_000;
	resourceLimit["coal"]   = 16_000_000;
	resourceLimit["clay"]   = 16_000_000;
	resourceLimit["ore"]    = 32_000_000;
	resourceLimit["coffee"] =    300_000;

	ResTemplate [] resTemplate;
	resTemplate ~= ResTemplate ("gold",   pos => a[pos].gold,   10 ^^ 6);
	resTemplate ~= ResTemplate ("wood",   pos => a[pos].wood,   10 ^^ 6);
	resTemplate ~= ResTemplate ("stone",  pos => a[pos].stone,  10 ^^ 6);
	resTemplate ~= ResTemplate ("coal",   pos => a[pos].coal,   10 ^^ 6);
	resTemplate ~= ResTemplate ("clay",   pos => a[pos].clay,   10 ^^ 6);
	resTemplate ~= ResTemplate ("ore",    pos => a[pos].ore,    10 ^^ 6);
	resTemplate ~= ResTemplate ("coffee", pos => a[pos].coffee, 10 ^^ 4);
	resTemplate ~= ResTemplate ("worker",
	    pos => pos in workerNum ? workerNum[pos] : 0, 10 ^^ 0);

	int totalResources = resTemplate.length.to !(int) - 1;

	void doHtml (ResTemplate [] resources)
	{
		auto title = format ("%-(%s_%)", resources.map !(t => t.name));
		if (resources.length == totalResources)
		{
			title = "combined";
		}

		auto file = File (title ~ ".html", "wt");
		writeHtmlHeader (file, title);
		writeCoordRow (file);
		long [string] [string] quantity;
		int [string] [string] richPlots;
		int [string] totalRichPlots;
		int [string] totalUnknownPlots;
		long [string] totalQuantity;
		foreach (name; resources.map !(t => t.name))
		{
			totalRichPlots[name] = 0;
			totalUnknownPlots[name] = 0;
			totalQuantity[name] = 0;
		}

		foreach (row; minRow..maxRow + 1)
		{
			file.writeln (`<tr>`);
			file.writeln (`<td class="coord">`, row, `</td>`);
			foreach (col; minCol..maxCol + 1)
			{
				auto pos = Coord (row, col);
				if (pos !in a)
				{
					assert (false);
				}
				auto owner = a[pos].owner;
				auto hoverText = toCoordString (pos);
				string bestName;
				string bestValue;
				int total = 0;
				foreach (ref resource; resources)
				{
					auto name = resource.name;
					auto fun = resource.fun;
					auto divisor = resource.divisor;
					auto value = makeValue (resource, pos);
					quantity[owner][name] +=
					    max (0, fun (pos));
					total += max (0, fun (pos));
					auto isRichPlot = (fun (pos) * 2 >
					    resourceLimit[name]);
					richPlots[owner][name] += isRichPlot;
					totalRichPlots[name] += isRichPlot;
					totalUnknownPlots[name] +=
					    (fun (pos) == -1);
					totalQuantity[name] += fun (pos);
					hoverText ~= `&#10;` ~ name ~ `: ` ~
					    fun (pos).toAmountString
					    (name == "gold");
					if (canImprove (bestValue, value))
					{
						bestName = name;
						bestValue = value;
					}
				}
				if (owner != "")
				{
					hoverText ~= `&#10;owner: ` ~ owner;
				}
				file.writefln (`<td class="plot %s-%s" ` ~
				    `title="%s">%s</td>`,
				    bestName, classString (bestValue),
				    hoverText, valueString (bestValue));
			}
			file.writeln (`<td class="coord">`, row, `</td>`);
			file.writeln (`</tr>`);
		}
		writeCoordRow (file);
		file.writeln (`</tbody>`);
		file.writeln (`</table>`);
		file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
		file.writefln (`<p>Tip: hover the mouse over a plot ` ~
		    `to see details.</p>`);

		if (resources.length == 1)
		{
			auto name = resources.front.name;
			bool showRich = (name != "wood" &&
			    name != "stone" &&
			    name != "coffee");

			auto plotOwners = quantity.byKey ().array;
			if (showRich)
			{
				plotOwners.schwartzSort !(owner =>
				    tuple (-richPlots[owner][name],
				    -quantity[owner][name], owner));
			}
			else
			{
				plotOwners.schwartzSort !(owner =>
				    tuple (-quantity[owner][name], owner));
			}
			file.writefln (`<h2>Richest %s plot owners:</h2>`,
			    name);
			file.writeln (`<table border="1px" padding="2px">`);
			file.writeln (`<tbody>`);

			file.writeln (`<tr>`);
			file.writefln (`<th>#</th>`);
			file.writefln (`<th class="plot" ` ~
			    `width="16px">&nbsp;</th>`);
			file.writefln (`<th>Account</th>`);
			if (showRich)
			{
				file.writefln (`<th>Rich plots</th>`);
			}
			file.writefln (`<th>Total quantity</th>`);
			file.writeln (`</tr>`);

			foreach (i, owner; plotOwners)
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
				if (showRich)
				{
					file.writeln (`<td style=` ~
					    `"text-align:right">`,
					    richPlots[owner][name], `</td>`);
				}
				file.writeln (`<td style="text-align:right">`,
				    toAmountString (quantity[owner][name],
				    name == "gold", false), `</td>`);
				file.writeln (`</tr>`);
			}

			file.writeln (`<tr>`);
			file.writeln (`<td style="text-align:right">` ~
			    `&nbsp;</td>`);
			file.writefln (`<td class="plot" width="16px">` ~
			    `&nbsp;</td>`);
			file.writeln (`<td style="font-weight:bold">` ~
			    `Total</td>`);
			if (showRich)
			{
				file.writeln (`<td style="text-align:right">` ~
				    `&nbsp;</td>`);
			}
			file.writeln (`<td style="text-align:right">`,
			    toAmountString (totalQuantity[name],
			    name == "gold", false), `</td>`);
			file.writeln (`</tr>`);

			if (showRich)
			{
				file.writeln (`<tr>`);
				file.writeln (`<td style="text-align:right">` ~
				    `&nbsp;</td>`);
				file.writeln (`<td class="plot" ` ~
				    `width="16px">&nbsp;</td>`);
				file.writeln (`<td style="font-weight:bold">` ~
				    `Rich plots</td>`);
				file.writeln (`<td style="text-align:right">` ~
				    `&nbsp;</td>`);
				file.writeln (`<td style="text-align:right">`,
				    totalRichPlots[name], `</td>`);
				file.writeln (`</tr>`);

				file.writeln (`<tr>`);
				file.writeln (`<td style="text-align:right">` ~
				    `&nbsp;</td>`);
				file.writeln (`<td class="plot" ` ~
				    `width="16px">&nbsp;</td>`);
				file.writeln (`<td style="font-weight:bold">` ~
				    `Unknown</td>`);
				file.writeln (`<td style="text-align:right">` ~
				    `&nbsp;</td>`);
				file.writeln (`<td style="text-align:right">`,
				    totalUnknownPlots[name], `</td>`);
				file.writeln (`</tr>`);
			}

			file.writeln (`</tbody>`);
			file.writeln (`</table>`);

			if (showRich)
			{
				file.writefln (`<p>A plot is rich ` ~
				    `if it contains more than %s %s.</p>`,
				    toAmountString (resourceLimit[name] / 2,
				    name == "gold"), name);
			}
		}
		file.writefln (`<p><a href="..">Back to main page</a></p>`);
		file.writeln (`</body>`);
		file.writeln (`</html>`);
	}

	void doHtmlWorker (ResTemplate [] resources)
	{
		if (resources.length != 1)
		{
			assert (false);
		}

		auto title = format ("%-(%s_%)", resources.map !(t => t.name));

		auto file = File (title ~ ".html", "wt");
		writeHtmlHeader (file, title);
		writeCoordRow (file);
		real midRow = 0.0;
		real midCol = 0.0;
		real midDen = 0.0;
		foreach (row; minRow..maxRow + 1)
		{
			file.writeln (`<tr>`);
			file.writeln (`<td class="coord">`, row, `</td>`);
			foreach (col; minCol..maxCol + 1)
			{
				auto pos = Coord (row, col);
				if (pos !in a)
				{
					assert (false);
				}
				auto owner = a[pos].owner;
				auto hoverText = toCoordString (pos);
				string bestName;
				string bestValue;
				foreach (ref resource; resources)
				{
					auto name = resource.name;
					auto fun = resource.fun;
					auto divisor = resource.divisor;
					auto value = min (fun (pos), 99).text;
					midRow += row * fun (pos);
					midCol += col * fun (pos);
					midDen += fun (pos);
					hoverText ~= `&#10;workers: ` ~
					    fun (pos).text;
					if (fun (pos) == 0)
					{
						value = "z";
					}
					if (canImprove (bestValue, value))
					{
						bestName = name;
						bestValue = value;
					}
				}
				if (owner != "")
				{
					hoverText ~= `&#10;owner: ` ~ owner;
				}
				file.writefln (`<td class="plot %s-%s" ` ~
				    `title="%s">%s</td>`,
				    bestName, classString (bestValue),
				    hoverText, valueString (bestValue));
			}
			file.writeln (`<td class="coord">`, row, `</td>`);
			file.writeln (`</tr>`);
		}
		writeCoordRow (file);
		file.writeln (`</tbody>`);
		file.writeln (`</table>`);
		file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
		file.writefln (`<p>Average worker position: ` ~
		    `%.2f/%.2f.</p>`, midCol / midDen, midRow / midDen);
		file.writefln (`<p>Tip: hover the mouse over a plot ` ~
		    `to see details.</p>`);
		file.writefln (`<p><a href="..">Back to main page</a></p>`);
		file.writeln (`</body>`);
		file.writeln (`</html>`);
	}

	enum RentMapType {simple, daysLeft, auction}

	void doHtmlRent (string name, RentMapType type)
	{
		auto title = name;

		auto file = File (title ~ ".html", "wt");
		writeHtmlHeader (file, title);
		writeCoordRow (file);

		int [string] numPlots;
		foreach (row; minRow..maxRow + 1)
		{
			file.writeln (`<tr>`);
			file.writeln (`<td class="coord">`, row, `</td>`);
			foreach (col; minCol..maxCol + 1)
			{
				auto pos = Coord (row, col);
				if (pos !in a)
				{
					assert (false);
				}
				auto owner = a[pos].owner;
				numPlots[owner] += 1;
				auto backgroundColor = (owner == "") ?
				    0xEEEEEE : toColorHash (owner);
				if (type == RentMapType.auction &&
				    owner != "" &&
				    a[pos].auctionPrice == 0)
				{
					backgroundColor = 0xBBBBBB;
				}
				auto hoverText = toCoordString (pos);
				if (owner != "")
				{
					hoverText ~= `&#10;owner: ` ~ owner;
				}
				auto daysLeft = "&nbsp;";
				if (type != RentMapType.simple && owner != "")
				{
					auto rentTime = a[pos].rentTime;
					auto secLeft = rentTime - nowUnix;
					auto intDaysLeft = rentDaysLeft (pos);
					intDaysLeft = min (intDaysLeft, 99);
					intDaysLeft = max (intDaysLeft, -9);
					daysLeft = intDaysLeft.text;
					hoverText ~= `&#10;rent paid: ` ~
					    dur !(q{minutes}) (secLeft / 60)
					    .text;
				}
				file.writefln (`<td class="plot" ` ~
				    `style="background-color:#%06X" ` ~
				    `title="%s">%s</td>`,
				    backgroundColor, hoverText, daysLeft);
			}
			file.writeln (`<td class="coord">`, row, `</td>`);
			file.writeln (`</tr>`);
		}
		writeCoordRow (file);

		file.writeln (`</tbody>`);
		file.writeln (`</table>`);
		file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
		file.writefln (`<p>Tip: hover the mouse over a plot ` ~
		    `to see details.</p>`);

		if (type == RentMapType.simple)
		{
			auto plotsByNum = numPlots.byKeyValue ().array;
			plotsByNum.schwartzSort !(line =>
			    tuple (-line.value, line.key));
			file.writeln (`<h2>Owners by number of plots:</h2>`);
			file.writeln (`<table border="1px" padding="2px">`);
			file.writeln (`<tbody>`);

			file.writeln (`<tr>`);
			file.writefln (`<th>#</th>`);
			file.writefln (`<th class="plot" ` ~
			    `width="16px">&nbsp;</th>`);
			file.writefln (`<th>Account</th>`);
			file.writefln (`<th>Plots</th>`);
			file.writeln (`</tr>`);

			foreach (i, t; plotsByNum)
			{
				auto backgroundColor = (t.key == "") ?
				    0xEEEEEE : toColorHash (t.key);
				file.writeln (`<tr>`);
				file.writeln (`<td style="text-align:right">`,
				    (i + 1), `</td>`);
				file.writefln (`<td class="plot" ` ~
				    `width="16px" ` ~
				    `style="background-color:#%06X">` ~
				    `&nbsp;</td>`, backgroundColor);
				file.writeln (`<td style='font-family:` ~
				    `"Courier New", Courier, monospace'>`,
				    t.key == "" ? "(free plots)" : t.key,
				    `</td>`);
				file.writeln (`<td style="text-align:right">`,
				    t.value, `</td>`);
				file.writeln (`</tr>`);
			}
			file.writeln (`</tbody>`);
			file.writeln (`</table>`);
		}
		else if (type == RentMapType.daysLeft)
		{
			auto plotsBlocked = a.byKeyValue ().filter !(line =>
			    line.value.owner != "" &&
			    rentDaysLeft (line.key) < 0).array;
			plotsBlocked.schwartzSort !(line =>
			    tuple (rentDaysLeft (line.key),
			    toCoordString (line.key)));
			file.writeln (`<h2>Blocked plots:</h2>`);
			file.writeln (`<p>Click on a column header ` ~
			    `to sort.</p>`);
			file.writeln (`<table id="blocked-list" ` ~
			    `border="1px" padding="2px">`);
			file.writeln (`<thead>`);
			file.writeln (`<tr>`);
			file.writefln (`<th>#</th>`);
			file.writefln (`<th class="plot" ` ~
			    `width="16px">&nbsp;</th>`);
			file.writefln (`<th>Plot</th>`);
			file.writefln (`<th class="header" ` ~
			    `id="col-owner">Owner</th>`);
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
			    `id="col-building">Building</th>`);
			file.writeln (`</tr>`);
			file.writeln (`</thead>`);
			file.writeln (`<tbody>`);

			foreach (i, t; plotsBlocked)
			{
				auto backgroundColor = (t.value.owner == "") ?
				    0xEEEEEE : toColorHash (t.value.owner);
				file.writeln (`<tr>`);
				file.writeln (`<td style="text-align:right">`,
				    (i + 1), `</td>`);
				file.writefln (`<td class="plot" ` ~
				    `width="16px" ` ~
				    `style="background-color:#%06X">` ~
				    `&nbsp;</td>`, backgroundColor);
				file.writeln (`<td>`,
				    toCoordString (t.key), `</td>`);
				file.writeln (`<td style='font-family:` ~
				    `"Courier New", Courier, monospace'>`,
				    t.value.owner, `</td>`);
				auto rentLeft = rentDaysLeft (t.key);
				file.writeln (`<td style="text-align:right">`,
				    rentLeft, `</td>`);
				foreach (r; 0..totalResources)
				{
					file.writefln (`<td class="%s-%s" ` ~
					    `style="text-align:right">%s</td>`,
					    resTemplate[r].name, classString
					    (makeValue (resTemplate[r], t.key)
					    [0..$ - 1]),
					    toAmountString (resTemplate[r].fun
					    (t.key), resTemplate[r].name ==
					    "gold", false));
				}
				auto backgroundColorBuilding = 0xEEEEEE;
				auto buildingDetails = "&nbsp;";
				auto buildId = t.value.buildId;
				if (buildId != 0)
				{
					buildingDetails =
					    buildings[buildId].name;
					auto done = buildingDone (t.key);
					if (done != buildStepLength *
					    buildSteps)
					{
						buildingDetails ~= format
						    (`, %d%% built`,
						    done * 100L /
						    (buildStepLength *
						    buildSteps));
					}
					backgroundColorBuilding = mixColor
					    (buildings[buildId].loColor,
					    buildings[buildId].hiColor,
					    0, done, buildStepLength *
					    buildSteps).toColorInt;
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
				file.writefln (`<td style="text-align:left;` ~
				    `background-color:#%06X%s">%s</td>`,
				    backgroundColorBuilding, whiteFont,
				    buildingDetails);
				file.writeln (`</tr>`);
			}
			file.writeln (`</tbody>`);
			file.writeln (`</table>`);
			file.writeln (`<script src="blocked.js"></script>`);
		}
		else if (type == RentMapType.auction)
		{
			auto plotsAuction = a.byKeyValue ().filter !(line =>
			    line.value.auctionPrice > 0).array;
			plotsAuction.schwartzSort !(line =>
			    tuple (line.value.auctionPrice,
			    line.value.auctionCompleteTime,
			    -line.value.rentTime));
			file.writeln (`<h2>Active auctions:</h2>`);
			file.writeln (`<p>Click on a column header ` ~
			    `to sort.</p>`);
			file.writeln (`<table id="auction-list" ` ~
			    `border="1px" padding="2px">`);
			file.writeln (`<thead>`);
			file.writeln (`<tr>`);
			file.writefln (`<th>#</th>`);
			file.writefln (`<th class="plot" ` ~
			    `width="16px">&nbsp;</th>`);
			file.writefln (`<th>Plot</th>`);
			file.writefln (`<th class="header" ` ~
			    `id="col-owner">Owner</th>`);
			file.writefln (`<th class="header" ` ~
			    `id="col-active">Active</th>`);
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
			    `id="col-building">Building</th>`);
			file.writeln (`</tr>`);
			file.writeln (`</thead>`);
			file.writeln (`<tbody>`);

			foreach (i, t; plotsAuction)
			{
				auto backgroundColor = (t.value.owner == "") ?
				    0xEEEEEE : toColorHash (t.value.owner);
				file.writeln (`<tr>`);
				file.writeln (`<td style="text-align:right">`,
				    (i + 1), `</td>`);
				file.writefln (`<td class="plot" ` ~
				    `width="16px" ` ~
				    `style="background-color:#%06X">` ~
				    `&nbsp;</td>`, backgroundColor);
				file.writeln (`<td>`,
				    toCoordString (t.key), `</td>`);
				file.writeln (`<td style='font-family:` ~
				    `"Courier New", Courier, monospace'>`,
				    t.value.owner, `</td>`);
				auto minutesLeft =
				    t.value.auctionCompleteTime - nowUnix;
				minutesLeft /= 60;
				minutesLeft = max (0, minutesLeft);
				file.writefln (`<td ` ~
				    `style="text-align:center" ` ~
				    `style='font-family:` ~
				    `"Courier New", Courier, monospace'>` ~
				    `%02d:%02d</td>`,
				    minutesLeft / 60,
				    minutesLeft % 60);
				file.writefln (`<td ` ~
				    `style="text-align:right">%s</td>`,
				    toCommaNumber (t.value.auctionPrice,
				    true));
				file.writeln (`<td style='font-family:` ~
				    `"Courier New", Courier, monospace'>`,
				    t.value.auctionBidder, `</td>`);
				auto rentLeft = rentDaysLeft (t.key);
				file.writeln (`<td style="text-align:right">`,
				    rentLeft, `</td>`);
				foreach (r; 0..totalResources)
				{
					file.writefln (`<td class="%s-%s" ` ~
					    `style="text-align:right">%s</td>`,
					    resTemplate[r].name, classString
					    (makeValue (resTemplate[r], t.key)
					    [0..$ - 1]),
					    toAmountString (resTemplate[r].fun
					    (t.key), resTemplate[r].name ==
					    "gold", false));
				}
				auto backgroundColorBuilding = 0xEEEEEE;
				auto buildingDetails = "&nbsp;";
				auto buildId = t.value.buildId;
				if (buildId != 0)
				{
					buildingDetails =
					    buildings[buildId].name;
					auto done = buildingDone (t.key);
					if (done != buildStepLength *
					    buildSteps)
					{
						buildingDetails ~= format
						    (`, %d%% built`,
						    done * 100L /
						    (buildStepLength *
						    buildSteps));
					}
					backgroundColorBuilding = mixColor
					    (buildings[buildId].loColor,
					    buildings[buildId].hiColor,
					    0, done, buildStepLength *
					    buildSteps).toColorInt;
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
				file.writefln (`<td style="text-align:left;` ~
				    `background-color:#%06X%s">%s</td>`,
				    backgroundColorBuilding, whiteFont,
				    buildingDetails);
				file.writeln (`</tr>`);
			}
			file.writeln (`</tbody>`);
			file.writeln (`</table>`);
			file.writeln (`<script src="auction.js"></script>`);
		}
		else
		{
			assert (false);
		}

		file.writefln (`<p><a href="..">Back to main page</a></p>`);
		file.writeln (`</body>`);
		file.writeln (`</html>`);
	}

	void doHtmlBuildings ()
	{
		auto title = "buildings";

		auto file = File (title ~ ".html", "wt");
		writeHtmlHeader (file, title);
		writeCoordRow (file);

		auto completed = new int [buildings.length];
		auto inProgress = new int [buildings.length];
		foreach (row; minRow..maxRow + 1)
		{
			file.writeln (`<tr>`);
			file.writeln (`<td class="coord">`, row, `</td>`);
			foreach (col; minCol..maxCol + 1)
			{
				auto pos = Coord (row, col);
				if (pos !in a)
				{
					assert (false);
				}
				auto owner = a[pos].owner;
				auto backgroundColor = 0xEEEEEE;
				auto sign = "&nbsp;";
				if (owner != "")
				{
					backgroundColor = 0xBBBBBB;
				}
				auto hoverText = toCoordString (pos);
				auto buildId = a[pos].buildId;
				if (buildId != 0)
				{
					hoverText ~= `&#10;` ~
					    buildings[buildId].name;
					auto done = buildingDone (pos);
					if (done == buildStepLength *
					    buildSteps)
					{
						sign = buildings[buildId].sign;
						completed[buildId] += 1;
					}
					else
					{
						hoverText ~= format
						    (`&#10;progress: %s of %s`,
						    done, buildStepLength *
						    buildSteps);
						inProgress[buildId] += 1;
					}
					backgroundColor = mixColor
					    (buildings[buildId].loColor,
					    buildings[buildId].hiColor,
					    0, done, buildStepLength *
					    buildSteps).toColorInt;
				}
				if (pos == Coord (0, 0))
				{
					hoverText ~= `&#10;Government`;
					backgroundColor = 0xBB88FF;
				}
				if (owner != "")
				{
					hoverText ~= `&#10;owner: ` ~ owner;
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
				file.writefln (`<td class="plot" ` ~
				    `style="background-color:#%06X%s" ` ~
				    `title="%s">%s</td>`,
				    backgroundColor, whiteFont,
				    hoverText, sign);
			}
			file.writeln (`<td class="coord">`, row, `</td>`);
			file.writeln (`</tr>`);
		}
		writeCoordRow (file);
		file.writeln (`</tbody>`);
		file.writeln (`</table>`);
		file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
		file.writeln (`<p>Classification by production: ` ~
		    `M = Material, R = Resource, ` ~
		    `T = Tools and Transport.</p>`);
		file.writefln (`<p>Tip: hover the mouse over a plot ` ~
		    `to see details.</p>`);

		file.writefln (`<h2>Building types:</h2>`);
		file.writeln (`<table border="1px" padding="2px">`);
		file.writeln (`<tbody>`);

		file.writeln (`<tr>`);
		file.writefln (`<th class="plot" ` ~
		    `width="16px">&nbsp;</th>`);
		file.writefln (`<th>Building type</th>`);
		file.writefln (`<th>Completed</th>`);
		file.writefln (`<th>In progress</th>`);
		file.writeln (`</tr>`);

		foreach (ref building; buildings)
		{
			if (building == Building.init)
			{
				continue;
			}

			auto backgroundColor = building.hiColor.toColorInt;
			string whiteFont;
			if (building.loColor.all !(c => c < colorThreshold))
			{
				whiteFont ~= `;color:#FFFFFF`;
				whiteFont ~= `;border-color:#000000`;
			}

			file.writeln (`<tr>`);
			file.writefln (`<td class="plot" width="16px" ` ~
			    `style="text-align:center;` ~
			    `background-color:#%06X%s">%s</td>`,
			    backgroundColor, whiteFont, building.sign);
			file.writeln (`<td style="text-align:left">`,
			    building.name, `</td>`);
			file.writeln (`<td style="text-align:right">`,
			    completed[building.id.to !(int)], `</td>`);
			file.writeln (`<td style="text-align:right">`,
			    inProgress[building.id.to !(int)], `</td>`);
			file.writeln (`</tr>`);
		}

		file.writeln (`<tr>`);
		file.writefln (`<td class="plot" width="16px">` ~
		    `&nbsp;</td>`);
		file.writeln (`<td style="font-weight:bold;` ~
		    `text-align:left">Total</td>`);
		file.writeln (`<td style="text-align:right">`,
		    completed.sum, `</td>`);
		file.writeln (`<td style="text-align:right">`,
		    inProgress.sum, `</td>`);
		file.writeln (`</tr>`);

		file.writeln (`</tbody>`);
		file.writeln (`</table>`);
		file.writefln (`<p><a href="..">Back to main page</a></p>`);
		file.writeln (`</body>`);
		file.writeln (`</html>`);
	}

	doHtml (resTemplate[0..1]);
	doHtml (resTemplate[1..2]);
	doHtml (resTemplate[2..3]);
	doHtml (resTemplate[3..4]);
	doHtml (resTemplate[4..5]);
	doHtml (resTemplate[5..6]);
	doHtml (resTemplate[6..7]);
	doHtml (resTemplate[1..3] ~ resTemplate[6]);
	doHtml (resTemplate[0..7]);
	doHtmlWorker (resTemplate[7..8]);
	doHtmlRent ("rent", RentMapType.simple);
	doHtmlRent ("rent-days", RentMapType.daysLeft);
	doHtmlRent ("auction", RentMapType.auction);
	doHtmlBuildings ();

	return 0;
}
