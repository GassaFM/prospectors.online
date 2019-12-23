// Author: Ivan Kazmenko (gassa@mail.ru)
module display_deals;
import core.stdc.stdint;
import std.algorithm;
import std.conv;
import std.datetime;
import std.digest.sha;
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
import utilities;

alias thisToolName = moduleName !({});

SysTime now;
string nowString;

enum RecordType : bool {buying, selling};

struct Record
{
	string timeStamp;
	RecordType type;
	Name alliance;
	Name seller;
	Coord location;
	Name buyer;
	string item;
	int itemId;
	int amount;
	int price;
}

string itemNameWithHealth (int typeId, int health)
{
	string res = itemList[typeId].name;
	if (health > 0)
	{
		res ~= ", " ~ health.text ~ " minutes";
	}
	return res;
}

auto buyRecord (const string [] input)
{
	auto res = Record ();
	res.timeStamp = input[0];
	res.type = RecordType.buying;

	auto actor = Name (input[1]);

	auto actionHex = input[2].hexStringToBinary;
	auto action = actionHex.parseBinary !(doorder);
	if (!actionHex.empty)
	{
		assert (false);
	}

	auto orderHex = input[3].hexStringToBinary;
	auto order = orderHex.parseBinary !(orderElement);
	if (!orderHex.empty)
	{
		assert (false);
	}

	res.alliance = order.alliance;
	res.seller = actor;
	res.location = Coord (order.loc_id);
	res.buyer = order.owner;
	res.itemId = order.item_id;
	res.item = itemNameWithHealth (res.itemId, 0);
	auto amount = action.amount;
	auto amountInOrder = order.amount;
	if (isResource (res.itemId))
	{
		amount /= 1000;
		amountInOrder /= 1000;
	}
	auto price = order.gold / amountInOrder;
	res.amount = amount;
	res.price = price;

	return res;
}

auto saleRecord (const string [] input)
{
	auto res = Record ();
	res.timeStamp = input[0];
	res.type = RecordType.selling;

	auto actor = Name (input[1]);

	auto actionHex = input[2].hexStringToBinary;
	auto action = actionHex.parseBinary !(mkpurchase);
	if (!actionHex.empty)
	{
		assert (false);
	}

	auto marketHex = input[3].hexStringToBinary;
	auto market = marketHex.parseBinary !(marketElement);
	if (!marketHex.empty)
	{
		assert (false);
	}

	res.alliance = market.alliance;
	res.seller = market.owner;
	res.location = Coord (market.loc_id);
	res.buyer = actor;
	res.itemId = market.stuff.type_id;
	res.item = itemNameWithHealth (res.itemId, market.stuff.health);
	auto amount = action.amount;
	if (isResource (res.itemId))
	{
		amount /= 1000;
	}
	auto price = market.price;
	res.amount = amount;
	res.price = price;

	return res;
}

void doHtml (string name, const ref Record [] records)
{
	File file;

	file = File (name ~ ".html", "wt");
	file.writeln (`<!DOCTYPE html>`);
	file.writeln (`<html xmlns="http://www.w3.org/1999/xhtml">`);
	file.writeln (`<meta http-equiv="content-type" ` ~
	    `content="text/html; charset=UTF-8">`);
	file.writeln (`<head>`);
	file.writefln (`<title>%s</title>`, name);
	file.writeln (`<link rel="stylesheet" href="log.css" ` ~
	    `type="text/css">`);
	file.writeln (`</head>`);
	file.writeln (`<body>`);
	file.writeln (`<table class="log" style="width:100%">`);
	file.writeln (`<tbody>`);
	file.writeln (`<tr style="font-weight:bold ` ~
	    `text-align:center" border-style:solid border-width:1px>`);
	file.writeln (`<th>ID</th>`);
	file.writeln (`<th>Timestamp</th>`);
	file.writeln (`<th>Type</th>`);
	file.writeln (`<th>Alliance</th>`);
	file.writeln (`<th>Seller</th>`);
	file.writeln (`<th>Location</th>`);
	file.writeln (`<th>Buyer</th>`);
	file.writeln (`<th>Item</th>`);
	file.writeln (`<th>Amount</th>`);
	file.writeln (`<th>Price</th>`);
	file.writeln (`</tr>`);
	foreach (i, record; records)
	{
		auto id = records.length - i;
		file.writeln (`<tr>`);
		file.writeln (`<td class="time">`, id, `</td>`);
		file.writeln (`<td class="time">`,
		    record.timeStamp, `</td>`);
		file.writeln (`<td class="name deal-`,
		    ["buying", "selling"][record.type], `">`,
		    ["buy order", "market sale"][record.type],
		    `</td>`);
		file.writeln (`<td class="name">`,
		    record.alliance.text != "" ? record.alliance.text :
		    `&nbsp;`, `</td>`);
		file.writeln (`<td class="name">`,
		    record.seller, `</td>`);
		file.writeln (`<td class="place">`,
		    record.location, `</td>`);
		file.writeln (`<td class="name">`,
		    record.buyer, `</td>`);
		file.writeln (`<td class="item">`,
		    record.item, `</td>`);
		file.writeln (`<td class="amount">`,
		    record.amount, `</td>`);
		file.writeln (`<td class="amount">`,
		    record.price, `</td>`);
		file.writeln (`</tr>`);
	}
	file.writeln (`</tbody>`);
	file.writeln (`</table>`);
	file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
	file.writefln (`<p><a href="trades.html">Back to trades page</a></p>`);
	file.writeln (`</body>`);
	file.writeln (`</html>`);
	file.close ();
}

int [int] doRecords (const ref Record [] records, string kind)
{
	Record [] [int] recordsById;
	int [int] lastPrice;

	foreach (record; records)
	{
		auto itemId = record.itemId;
		recordsById[itemId] ~= record;
		if (itemId !in lastPrice)
		{
			lastPrice[itemId] = record.price;
		}
	}

	doHtml (kind, records);
	foreach (id, list; recordsById)
	{
		doHtml (kind ~ format !(".%02d") (id), list);
	}

	return lastPrice;
}

void doMainTradesPage (const ref int [int] lastPriceDeals,
    const ref int [int] lastPriceBuys, const ref int [int] lastPriceSales)
{
	auto items = itemList.length.to !(int);
	auto codeList = iota (1, 7).array ~ (items - 1) ~
	    iota (7, items - 1).array;
	auto codeBreaks = [31: true, 16: true, 24: true];

	File file;

	file = File ("trades.html", "wt");
	file.writeln (`<!DOCTYPE html>`);
	file.writeln (`<html xmlns=` ~
	    `"http://www.w3.org/1999/xhtml">`);
	file.writeln (`<meta http-equiv="content-type" ` ~
	    `content="text/html; charset=UTF-8">`);
	file.writeln (`<head>`);
	file.writefln (`<title>%s</title>`, "Trades");
	file.writeln (`<link rel="stylesheet" ` ~
	    `href="log.css" type="text/css">`);
	file.writeln (`</head>`);
	file.writeln (`<body>`);

	file.writefln (`<h2>Trades</h2>`);
	file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
	file.writeln (`<p><a href="..">Back to main page</a></p>`);

	file.writeln (`<table border="1px" padding="2px">`);
	file.writeln (`<thead>`);
	file.writeln (`</thead>`);
	file.writeln (`<tr>`);
	file.writeln (`<th align="center" colspan="3">` ~
	    `History by day</th>`);
	file.writeln (`</tr>`);
	file.writeln (`<tbody>`);
	file.writeln (`<tr>`);
	file.writeln (`<td align="center" width="33.3333%" ` ~
	    `class="place deal-general">` ~
	    `<a href="deals-days.html">Deals by day</a>` ~ `</td>`);
	file.writeln (`<td align="center" width="33.3333%" ` ~
	    `class="place deal-selling">` ~
	    `<a href="sales-days.html">Sales by day</a>` ~ `</td>`);
	file.writeln (`<td align="center" width="33.3333%" ` ~
	    `class="place deal-buying">` ~
	    `<a href="buys-days.html">Buys by day</a>` ~ `</td>`);
	file.writeln (`</tr>`);
	file.writeln (`</tbody>`);
	file.writeln (`</table>`);

	file.writeln (`<p height="5px"></p>`);

	file.writeln (`<table border="1px" padding="2px">`);
	file.writeln (`<thead>`);
	file.writeln (`<tr>`);
	file.writefln (`<th>Item</th>`);
	file.writefln (`<th>Deals history</th>`);
	file.writefln (`<th>Last sale price</th>`);
	file.writefln (`<th>Sales history</th>`);
	file.writefln (`<th>Last buy price</th>`);
	file.writefln (`<th>Buys history</th>`);
	file.writeln (`</tr>`);
	file.writeln (`</thead>`);

	file.writeln (`<tbody>`);
	file.writeln (`<tr>`);
	file.writefln (`<td>ALL</td>`);
	file.writefln (`<td class="place deal-general">` ~
	    `<a href="deals.html">All deals</a>` ~ `</td>`);
	file.writefln (`<td class="place">&nbsp;</td>`);
	file.writefln (`<td class="place deal-selling">` ~
	    `<a href="sales.html">All sales</a>` ~ `</td>`);
	file.writefln (`<td class="place">&nbsp;</td>`);
	file.writefln (`<td class="place deal-buying">` ~
	    `<a href="buys.html">All buys</a>` ~ `</td>`);
	file.writeln (`</tr>`);

	file.writeln (`<tr height=5px></tr>`);

	foreach (id; codeList)
	{
	        scope (exit)
	        {
			if (id in codeBreaks)
			{
				file.writeln (`<tr height=5px></tr>`);
			}
		}

		if (id !in lastPriceDeals)
		{
			continue;
		}

		auto itemName = itemList[id].name;

		file.writeln (`<tr>`);

		file.writeln (`<td class="item">`,
		    itemList[id].name, `</td>`);

		file.writeln (`<td class="place deal-general">` ~
		    (id in lastPriceDeals ? format
		    !(`<a href="deals.%02d.html">%s deals</a>`)
		    (id, itemName) : `&nbsp;`) ~ `</td>`);

		file.writeln (`<td class="amount">` ~
		    (id in lastPriceSales ? lastPriceSales[id].text :
		    `&nbsp;`) ~ `</td>`);

		file.writeln (`<td class="place deal-selling">` ~
		    (id in lastPriceSales ? format
		    !(`<a href="sales.%02d.html">%s sales</a>`)
		    (id, itemName) : `&nbsp;`) ~ `</td>`);

		file.writeln (`<td class="amount">` ~
		    (id in lastPriceBuys ? lastPriceBuys[id].text :
		    `&nbsp;`) ~ `</td>`);

		file.writeln (`<td class="place deal-buying">` ~
		    (id in lastPriceBuys ? format
		    !(`<a href="buys.%02d.html">%s buys</a>`)
		    (id, itemName) : `&nbsp;`) ~ `</td>`);

		file.writeln (`</tr>`);
	}

	file.writeln (`</tbody>`);
	file.writeln (`</table>`);
	file.writeln (`<p><a href="..">Back to main page</a></p>`);
	file.writeln (`</body>`);
	file.writeln (`</html>`);
	file.close ();
}

struct Alliance
{
	string name;
	bool [string] memberNames;
	string colorBack;
	string colorFont;
	string colorInv;

	this (string name_, string colorBack_, string colorFont_,
	    string colorInv_)
	{
		name = name_;
		auto fileName = "alliance-" ~ name ~ ".txt";
		foreach (memberName; File (fileName, "rt").byLineCopy)
		{
			memberNames[memberName.strip] = true;
		}
		colorBack = colorBack_;
		colorFont = colorFont_;
		colorInv = colorInv_;
	}
}

Alliance [] alliances;

string allianceColor (string name)
{
	foreach (const ref alliance; alliances)
	{
		if (name in alliance.memberNames)
		{
			return ` style="background-color:` ~
			    alliance.colorBack ~ `"`;
		}
	}
	return "";
}

void doStats (const ref Record [] records, string name)
{
	// The following does not work without the "Z"!
	auto startDate = SysTime.fromSimpleString
	    ("2019-Dec-02 00:00:00Z", UTC ());
	immutable int hoursInDay = 24;
	immutable int hourDuration = 60 * 60;
	immutable int dayDuration = hourDuration * hoursInDay;
	immutable int items = 32; // itemList.length.to !(int);
	auto codeList = iota (1, 7).array ~ (items - 1) ~
	    iota (7, items - 1).array;
	auto codeBreaks = [31: true, 16: true, 24: true, 30: true];

	alias RecordRow = int [items];
	RecordRow [] quantity;
	RecordRow total;
	auto quantityAlly = new RecordRow [] [alliances.length];
	auto totalAlly = new RecordRow [alliances.length];
	auto quantityAllyTo = new RecordRow [] [alliances.length];
	auto totalAllyTo = new RecordRow [alliances.length];

	foreach (record; records)
	{
		auto moment = SysTime.fromSimpleString
		    (record.timeStamp ~ 'Z').toUnixTime -
		    startDate.toUnixTime;
		auto dayNumber = moment / dayDuration;

		while (quantity.length <= dayNumber)
		{
			quantity.length += 1;
		}
		quantity[dayNumber][record.itemId] += record.amount;
		total[record.itemId] += record.amount;

		foreach (i, alliance; alliances)
		{
			while (quantityAlly[i].length <= dayNumber)
			{
				quantityAlly[i].length += 1;
			}
			if (record.seller.text in alliance.memberNames)
			{
				quantityAlly[i][dayNumber][record.itemId] +=
				    record.amount;
				totalAlly[i][record.itemId] += record.amount;
			}

			while (quantityAllyTo[i].length <= dayNumber)
			{
				quantityAllyTo[i].length += 1;
			}
			if (record.buyer.text in alliance.memberNames)
			{
				quantityAllyTo[i][dayNumber][record.itemId] +=
				    record.amount;
				totalAllyTo[i][record.itemId] += record.amount;
			}
		}
	}

	File file;

	void writeHeaderRowDays ()
	{
		file.writeln (`<tr style="font-weight:bold ` ~
		    `text-align:center">`);
		file.writeln (`<th>&nbsp;</th>`);
		file.writeln (`<th>Total</th>`);
		foreach_reverse (dayNumber; 0..quantity.length)
		{
			file.writefln (`<th style="` ~
			    `border-style:solid;border-width:1px"` ~
			    `>%s</th>`, (startDate +
			    dayNumber.days).toSimpleString[5..11]);
		}
		file.writeln (`</tr>`);
	}

	foreach (allianceIndex, const ref alliance;
	    alliances ~ Alliance.init)
	{
		auto nameWithAlliance = name ~ "-days";
		if (alliance.name != "")
		{
			nameWithAlliance ~= "-" ~ alliance.name;
		}
		file = File (nameWithAlliance ~ ".html", "wt");
		file.writeln (`<!DOCTYPE html>`);
		file.writeln (`<html xmlns=` ~
		    `"http://www.w3.org/1999/xhtml">`);
		file.writeln (`<meta http-equiv="content-type" ` ~
		    `content="text/html; charset=UTF-8">`);
		file.writeln (`<head>`);
		file.writefln (`<title>%s by day</title>`, name);
		file.writeln (`<link rel="stylesheet" ` ~
		    `href="log.css" type="text/css">`);
		file.writeln (`</head>`);

		file.writeln (`<body>`);
		file.writefln (`<h2>%s%s by day</h2>`,
		    name[0].toUpper, name[1..$]);
		file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
		file.writeln (`<p><a href="trades.html">` ~
		    `Back to trades</a></p>`);
        	file.writeln (`<table class="log"`);
		file.writeln (`<tbody>`);

		writeHeaderRowDays ();

		bool headerFlag = true;
		foreach (i; codeList)
		{
		        scope (exit)
		        {
				if (i in codeBreaks && !headerFlag)
				{
					writeHeaderRowDays ();
					headerFlag = true;
				}
			}

			if (total[i] == 0)
			{
				continue;
			}
			headerFlag = false;

			file.writeln (`<tr>`);
			file.writeln (`<td class="item">`,
			    itemList[i].name, `</td>`);
			file.writeln (`<td class="amount" ` ~
			    `style="font-weight:bold">`,
			    (allianceIndex < alliances.length &&
			    totalAlly[allianceIndex][i] > 0) ?
			    `<span style="color:` ~
			    alliances[allianceIndex].colorFont ~ `">` ~
			    totalAlly[allianceIndex][i].text ~
			    `</span>/` : ``,
			    total[i],
			    (allianceIndex < alliances.length &&
			    totalAllyTo[allianceIndex][i] > 0) ?
			    `/<span style="color:` ~
			    alliances[allianceIndex].colorInv ~ `">` ~
			    totalAllyTo[allianceIndex][i].text ~
			    `</span>` : ``, `</td>`);
			foreach_reverse (dayNumber; 0..quantity.length)
			{
				file.writeln (`<td class="amount">`,
				    (allianceIndex <
				    alliances.length &&
				    quantityAlly[allianceIndex]
				    [dayNumber][i] > 0) ?
				    `<span style="color:` ~
				    alliances[allianceIndex]
				    .colorFont ~ `">` ~
				    quantityAlly[allianceIndex]
				    [dayNumber][i].text ~
				    `</span>/` : ``,
				    quantity[dayNumber][i],
				    (allianceIndex <
				    alliances.length &&
				    quantityAllyTo[allianceIndex]
				    [dayNumber][i] > 0) ?
				    `/<span style="color:` ~
				    alliances[allianceIndex]
				    .colorInv ~ `">` ~
				    quantityAllyTo[allianceIndex]
				    [dayNumber][i].text ~
				    `</span>` : ``, `</td>`);
			}
			file.writeln (`</tr>`);
		}

		file.writeln (`</tbody>`);
		file.writeln (`</table>`);
		file.writeln (`<p><a href="trades.html">` ~
		    `Back to trades</a></p>`);
		file.writeln (`</body>`);
		file.writeln (`</html>`);
		file.close ();
	}
}

T [] merge (alias pred, T) (T [] a, T [] b)
{
	T [] res;
	res.reserve (a.length + b.length);
	while (!a.empty || !b.empty)
	{
		if (b.empty || (!a.empty && pred (a.front, b.front)))
		{
			res ~= a.front;
			a.popFront ();
		}
		else
		{
			res ~= b.front;
			b.popFront ();
		}
	}
	return res;
}

int main (string [] args)
{
	stdout.setvbuf (16384, _IOLBF);
	prepare ();

	auto buysQuery = "account:prospectorsc action:doorder";
	auto buysLogName = buysQuery.sha256Of.format !("%(%02x%)") ~ ".log";

	auto recordsBuys = File (buysLogName).byLineCopy
	    .map !(line => line.strip.split ("\t")).map !(buyRecord).array;

	auto salesQuery = "account:prospectorsc action:mkpurchase";
	auto salesLogName = salesQuery.sha256Of.format !("%(%02x%)") ~ ".log";

	auto recordsSales = File (salesLogName).byLineCopy
	    .map !(line => line.strip.split ("\t")).map !(saleRecord).array;

	auto records = merge !((a, b) =>
	    DateTime.fromSimpleString (a.timeStamp) <
	    DateTime.fromSimpleString (b.timeStamp))
	    (recordsSales, recordsBuys)
	    .array;

	reverse (recordsSales);
	reverse (recordsBuys);
	reverse (records);

	now = Clock.currTime (UTC ());
	nowString = now.toSimpleString[0..20];

	auto lastPriceDeals = doRecords (records, "deals");
	auto lastPriceBuys = doRecords (recordsBuys, "buys");
	auto lastPriceSales = doRecords (recordsSales, "sales");

	doMainTradesPage (lastPriceDeals, lastPriceBuys, lastPriceSales);

	alliances ~= Alliance ("ek", "#CCFFCC", "#00CC00", "#FF7777");

	doStats (records, "deals");
	doStats (recordsBuys, "buys");
	doStats (recordsSales, "sales");

	return 0;
}
