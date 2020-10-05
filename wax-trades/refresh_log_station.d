// Author: Ivan Kazmenko (gassa@mail.ru)
module refresh_log_station;
import std.algorithm;
import std.conv;
import std.format;
import std.json;
import std.range;
import std.stdio;
import std.string;
import std.traits;

import prospectorsc_abi;
import transaction;
import utilities;

alias thisToolName = moduleName !({});

immutable string queryForm = `{"query": "query {
  searchTransactionsForward(query: \"%s\",
                            irreversibleOnly: true,
                            limit: 100,
                            cursor: \"%s\") {
    cursor
    results {
      cursor
      trace {
        receipt {
          status
        }
        block {
          timestamp
        }
        matchingActions {
          authorization {
            actor
          }
          hexData
          order: dbOps (table: \"order\") {
            oldData
          }
        }
      }
    }
  }
}"}`.splitter ('\n').map !(strip).join (' ');

void updateLogStation (ref string [] res, const ref JSONValue resultTrace,
    const string timeStamp, const string curCursor)
{
	foreach (const ref actionJSON; resultTrace["matchingActions"].array)
	{
		auto orderHex = actionJSON["order"].array
		    .front["oldData"]
		    .str.chunks (2).map !(value =>
		    to !(ubyte) (value, 16)).array;

		auto orderHexDup = orderHex.dup;
		auto order = parseBinary !(orderElement)
		    (orderHexDup);
		if (!orderHexDup.empty)
		{
			assert (false);
		}
		if (order.job_type != 7) // buying
		{
			continue;
		}

		auto actor = actionJSON["authorization"]
		    .array.map !(line => line["actor"].str)
		    .filter !(line => line != "prospectorsb")
		    .front;

		auto actionHex = actionJSON["hexData"]
		    .str.chunks (2).map !(value =>
		    to !(ubyte) (value, 16)).array;

		res ~= format !("%s\t%s\t%s\t%s\t%s") (timeStamp, actor,
		    actionHex.format !("%(%02x%)"),
		    orderHex.format !("%(%02x%)"), curCursor);
	}
}

int main (string [] args)
{
	auto gameAccount = args[1];

	stdout.setvbuf (16384, _IOLBF);
	prepare ();
	updateLogGeneric !(updateLogStation) (args[2],
	    queryForm, "account:" ~ gameAccount ~ " action:sellstuff");
	return 0;
}
