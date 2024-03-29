// Author: Ivan Kazmenko (gassa@mail.ru)
module rent_price;
import std.algorithm;
import std.ascii;
import std.conv;
import std.datetime;
import std.format;
import std.json;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

import prospectorsc_abi;
import transaction;

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

int main (string [] args)
{
	long oldPrice;
	long jobMinutes;
	long jobGold;
	SysTime moment;

	{
		auto statJSON = File ("stat.binary", "rb")
		    .byLine.joiner.parseJSON;
		foreach (ref row; statJSON["rows"].array)
		{
			auto hex = row["hex"].str.chunks (2).map !(value =>
			    to !(ubyte) (value, 16)).array;
			auto curStat = parseBinary !(statElement) (hex);
			if (!hex.empty)
			{
				assert (false);
			}
			oldPrice = curStat.rent_price * 30;
			jobMinutes = curStat.job_count;
			jobGold = curStat.job_sum;
			moment =
			    SysTime.fromUnixTime (curStat.begin_time, UTC ());
		}
	}

	auto timeSpan = 24 * 60;
	auto now = Clock.currTime (UTC ());
	auto nowString = now.toSimpleString[0..20];
	auto timePassed = (now - moment).total !(q{minutes});
	timePassed = min (timePassed, timeSpan);
	auto timeToWait = timeSpan - timePassed;
	auto goldPerMinute = jobMinutes ? jobGold * 1.0L / jobMinutes : 0.0L;
	auto newPrice = cast (long) (goldPerMinute * 1350 * 30);
	auto prePrice = cast (long) (newPrice * 0.2 + oldPrice * 0.8);
	auto resPrice = cast (long)
	    ((prePrice * timePassed + oldPrice * timeToWait) / timeSpan);

	auto file = File ("rent-price.html", "wt");
	file.writeln (`<!DOCTYPE html>`);
	file.writeln (`<html xmlns="http://www.w3.org/1999/xhtml">`);
	file.writeln (`<meta http-equiv="content-type" ` ~
	    `content="text/html; charset=UTF-8">`);
	file.writeln (`<head>`);
	file.writefln (`<title>rent price</title>`);
	file.writeln (`<link rel="stylesheet" href="rent-price.css" ` ~
	    `type="text/css">`);
	file.writeln (`</head>`);
	file.writeln (`<body>`);
	file.writefln (`<p style="font-weight:bold;font-size:20px">` ~
	    `Current rent price: %s gold for a month.<br/>`, oldPrice);
	file.writefln (`Rent price prediction: %s gold for a month.<br/>`,
	    resPrice);
	file.writefln (`Time until recalculation: %s hours %s minutes.</p>`,
	    timeToWait / 60, timeToWait % 60);
	file.writeln (`<h2>How it is calculated:</h2>`);
	file.writeln (`<table class="rent-price">`);
	file.writeln (`<tbody>`);

	file.writeln (`<tr>`);
	file.writefln (`<td class="data" ` ~
	    `title="set on %s UTC">` ~
	    `Old rent price</td>`, moment.toSimpleString[0..17]);
	file.writefln (`<td class="amount" ` ~
	    `title="data from the blockchain">%s</td>`, oldPrice);
	file.writeln (`</tr>`);

	file.writeln (`<tr>`);
	file.writefln (`<td class="data" ` ~
	    `title="since %s UTC, for jobs with two tools">` ~
	    `Gold earned</td>`, moment.toSimpleString[0..17]);
	file.writefln (`<td class="amount" ` ~
	    `title="data from the blockchain">%s</td>`, jobGold);
	file.writeln (`</tr>`);

	file.writeln (`<tr>`);
	file.writefln (`<td class="data" ` ~
	    `title="since %s UTC, for jobs with two tools">` ~
	    `Minutes of work</td>`, moment.toSimpleString[0..17]);
	file.writefln (`<td class="amount" ` ~
	    `title="data from the blockchain">%s</td>`, jobMinutes);
	file.writeln (`</tr>`);

	file.writeln (`<tr height="5px">`);
	file.writeln (`</tr>`);

	file.writeln (`<tr>`);
	file.writefln (`<td class="data" ` ~
	    `title="since %s UTC, for jobs with two tools">` ~
	    `Average salary</td>`, moment.toSimpleString[0..17]);
	file.writefln (`<td class="amount" ` ~
	    `title="(Gold earned) / (Minutes of work)">` ~
	    `%.3f</td>`, goldPerMinute);
	file.writeln (`</tr>`);

	file.writeln (`<tr>`);
	file.writefln (`<td class="data" ` ~
	    `title="in the future if average salary stays constant">` ~
	    `Target rent price</td>`);
	file.writefln (`<td class="amount" ` ~
	    `title="(Average salary) * (3 workers) * ` ~
	    `(60 minutes in hour) * (15 hours per day) * (15 days)">` ~
	    `%s</td>`, newPrice);
	file.writeln (`</tr>`);

	file.writeln (`<tr>`);
	file.writefln (`<td class="data" ` ~
	    `title="smoothed out between old and target rent price">` ~
	    `Next rent price</td>`);
	file.writefln (`<td class="amount" ` ~
	    `title="(Target rent price) * 0.2 + (Old rent price) * 0.8">` ~
	    `%s</td>`, prePrice);
	file.writeln (`</tr>`);

	file.writeln (`<tr>`);
	file.writefln (`<td class="data" ` ~
	    `title="as %s of %s minutes passed to next calculation">` ~
	    `Predicted rent price</td>`,
	    timePassed, timeSpan);
	file.writefln (`<td class="amount" ` ~
	    `title="(Next rent price) * %s / %s + ` ~
	    `(Old rent price) * %s / %s">%s</td>`,
	    timePassed, timeSpan, timeToWait, timeSpan, resPrice);
	file.writeln (`</tr>`);

	file.writeln (`</tbody>`);
	file.writeln (`</table>`);
	file.writefln (`<p>Generated on %s (UTC).</p>`, nowString);
	file.writefln (`<p>Tip: hover the mouse over table cells ` ~
	    `to see explanations.</p>`);

	file.writeln (`<h2>Current diploma prices:</h2>`);
	file.writeln (`<table id="diploma-price" border="1px" padding="2px">`);

	file.writeln (`<thead>`);
	file.writeln (`<tr>`);
	file.writefln !(`<th>Diploma</th>`);
	file.writefln !(`<th>Study Time</th>`);
	file.writefln !(`<th>Cost of Studies</th>`);
	file.writeln (`</tr>`);
	file.writeln (`</thead>`);

	file.writeln (`<tbody>`);
	auto diplomaList = File ("../diplomas.txt").byLineCopy
	    .map !(line => line.strip.split ("\t")).array;

	foreach (const ref line; diplomaList.drop (1))
	{
		file.writeln (`<tr>`);
		file.writefln !(`<td style='font-family:` ~
		    `"Courier New", Courier, monospace'>%s</td>`) (line[0]);
		file.writefln !(`<td class="amount">%s days</td>`) (line[2]);
		auto d = line[1].to !(int);
		file.writefln !(`<td class="amount" ` ~
		    `title="as %s days of rent">%s gold</td>`)
		    (d, oldPrice / 30 * d);
		file.writeln (`</tr>`);
	}

	file.writeln (`</tbody>`);
	file.writeln (`</table>`);

	file.writefln (`<p><a href="index.html">Back to main page</a></p>`);
	file.writeln (`</body>`);
	file.writeln (`</html>`);

	return 0;
}
