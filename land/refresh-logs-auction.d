// Author: Ivan Kazmenko (gassa@mail.ru)
module update_logs_auction;
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

immutable string queryForm = (`{"query": "{
  searchTransactionsForward(query: \"%s\", limit: 100, cursor: \"%s\", ` ~
    `irreversibleOnly: true) {
    cursor
    results {
      trace {
        block {
          timestamp
        }
        matchingActions {
          auction: dbOps (table: \"auction\") {
            oldJSON {
              object
            }
          }
          loc: dbOps (table: \"loc\") {
            oldJSON {
              object
            }
            newJSON {
              object
            }
          }
        }
      }
    }
  }
}"}`).splitter ('\n').map !(strip).join (' ');

auto getWithData (Conn) (string url, string [string] data, Conn conn)
{
	return get (url ~ "?" ~ data.byKeyValue.map !(line =>
	    line.key ~ "=" ~ line.value).join ("&"), conn);
}

string maybeStr () (const auto ref JSONValue value)
{
	if (value.isNull)
	{
		return "";
	}
	return value.str;
}

void updateLog (string endPoint, string query)
{
	auto dfuseToken = File ("../dfuse.token").readln.strip;
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
	connection.addRequestHeader ("Authorization", "Bearer " ~ dfuseToken);
	auto logFile = File (sha256 ~ ".log", "ab");
	while (true)
	{
		auto filledQuery = format (queryForm, query, cursor);
		writeln ("updating ", query, ", cursor = ", cursor);
		auto raw = post (endPoint, filledQuery, connection);
		auto data = raw.parseJSON["data"]["searchTransactionsForward"];
		auto newCursor = data["cursor"].maybeStr;
		if (newCursor == "")
		{
			writeln (query, " update complete");
			break;
		}
		cursor = newCursor;

		foreach (ref line; data["results"].array
		    .map !(t => t["trace"]))
		{
			auto timeStamp = SysTime.fromISOExtString
			    (line["block"]["timestamp"].str, UTC ());
			auto timeString = timeStamp.toISOExtString[0..19];
			timeString = timeString[0..10] ~ " " ~
			    timeString[11..19];
			auto timeUnix = timeStamp.toUnixTime;

			foreach (cur; line["matchingActions"].array)
			{
				if (cur["loc"].array.empty)
				{
					// skip strange mkfreeloc transactions
					continue;
				}

				auto hasAuction = !cur["auction"].array.empty;
				auto auction = hasAuction ?
				    cur["auction"].array.front
				    ["oldJSON"]["object"] :
				    parseJSON (`{"type": 9, "price": 0}`);
				auto locFrom = cur["loc"].array.front
				    ["oldJSON"]["object"];
				auto locTo = cur["loc"].array.front
				    ["newJSON"]["object"];

				string [] buf;
				buf ~= timeString;
				buf ~= auction["type"].integer.text;
				buf ~= locFrom["owner"].str;
				buf ~= locFrom["id"].integer.text;
				auto target = locTo["owner"].str;
				if (target == "")
				{
					target = "(free)";
				}
				buf ~= target;
				buf ~= auction["price"].integer.text;

				buf ~= (locFrom["rent_time"].integer -
				    timeUnix).text;
				buf ~= locFrom["gold"].integer.text;
				buf ~= locFrom["wood"].integer.text;
				buf ~= locFrom["stone"].integer.text;
				buf ~= locFrom["coal"].integer.text;
				buf ~= locFrom["clay"].integer.text;
				buf ~= locFrom["ore"].integer.text;
				auto coffee = "0";
				if ("coffee" in locFrom)
				{
					coffee = locFrom["coffee"]
					    .integer.text;
				}
				buf ~= coffee;
				buf ~= locFrom["building"]["build_id"]
				    .integer.text;
				buf ~= locFrom["building"]["build_step"]
				    .integer.text;
				buf ~= locFrom["building"]["build_amount"]
				    .integer.text;

				logFile.writefln ("%-(%s %)", buf);
				logFile.flush ();
			}
		}
		File (cursorFileName, "wb").writeln (cursor);
	}
}

int main (string [] args)
{
	updateLog (args[1], args.drop (2).join (" "));
	return 0;
}
