// Author: Ivan Kazmenko (gassa@mail.ru)
module refresh_logs;
import std.algorithm;
import std.conv;
import std.datetime;
import std.digest.sha;
import std.format;
import std.json;
import std.net.curl;
import std.range;
import std.stdio;
import std.string;

int allowedSeconds;
long nowUnix;

shared static this ()
{
	nowUnix = Clock.currTime (UTC ()).toUnixTime ();
	try
	{
		auto f = File ("utilities_config.txt", "rt");
		allowedSeconds = f.readln.strip.to !(int);
	}
	catch (Exception e)
	{
		allowedSeconds = 86400;
	}
}

shared static this ()
{
	try
	{
		auto f = File ("error.txt", "rt");
	}
	catch (Exception e)
	{
		return;
	}
	throw new Exception ("error.txt is present");
}

void updateLog (string endPoint, string query)
{
	string dfuseToken;
	try
	{
		dfuseToken = File ("../dfuse.token").readln.strip;
	}
	catch (Exception e)
	{
		dfuseToken = "";
	}
	auto sha256 = query.sha256Of.format !("%(%02x%)");

	immutable string cursorFileName = sha256 ~ ".cursor";
	string cursor;
	try
	{
		cursor = File (cursorFileName).readln.strip;
	}
	catch (Exception e)
	{
		cursor = "";
	}

	auto connection = HTTP ();
//	connection.verbose (true);
	connection.addRequestHeader ("content-type", "text/plain");
	stderr.writeln ("dfuse: ", dfuseToken);
	if (dfuseToken != "")
	{
		connection.addRequestHeader ("Authorization",
		    "Bearer " ~ dfuseToken);
	}
	while (true)
	{
		writeln ("updating ", query, ", cursor = ", cursor);
		auto raw = post
		    (endPoint,
		    ["q": query,
		    "start_block": "0",
		    "limit": "100",
		    "sort": "asc",
		    "cursor": cursor],
		    connection);
		auto cur = raw.parseJSON;
		auto newCursor = cur["cursor"].str;
		if (newCursor == "")
		{
			writeln (query, " update complete");
			break;
		}
		auto oldCursor = cursor;
		cursor = newCursor;

		string [] res;
		foreach (t; cur["transactions"].array)
		{
			auto ts1 = t["lifecycle"]
			    ["execution_block_header"]["timestamp"].str;
			auto ts2 = SysTime.fromISOExtString (ts1);
			auto ts3 = ts2.toSimpleString;
			auto timestamp = ts3[0..20];

			auto curUnix = ts2.toUnixTime ();
			if (nowUnix - curUnix > allowedSeconds)
			{
				auto f = File ("error.txt", "wt");
				f.writeln (nowUnix);
				f.writeln (curUnix);
				f.writeln (oldCursor);
				f.writeln (cursor);
				throw new Exception ("error.txt generated");
			}

			foreach (action; t["lifecycle"]["transaction"]
			    ["actions"].array)
			{
				auto contract = action["account"].str;
				if (!contract.startsWith ("prospectors"))
				{
					continue;
				}
				auto actionName = action["name"].str;
				auto actors = action["authorization"].array
				    .map !(line => line["actor"].str).array;
				auto hexData = action["hex_data"].str;
				res ~= format ("%s %s %s %-(%s+%) %s",
				    timestamp, contract, actionName,
				    actors, hexData);
			}
		}
		auto logFile = File (sha256 ~ ".log", "ab");
		foreach (line; res)
		{
			logFile.writeln (line);
		}
		File (cursorFileName, "wb").writeln (cursor);
	}
}

int main (string [] args)
{
	updateLog (args[1], args[2]);
	updateLog (args[1], args[3]);
	return 0;
}
