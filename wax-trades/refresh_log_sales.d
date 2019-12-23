// Author: Ivan Kazmenko (gassa@mail.ru)
module refresh_log_sales;
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

immutable string queryForm = `{"query": "{
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
          market: dbOps (table: \"market\") {
            oldData
          }
        }
      }
    }
  }
}"}`.splitter ('\n').map !(strip).join (' ');

void updateLogSales (ref string [] res, const ref JSONValue resultTrace,
    const string timeStamp, const string curCursor)
{
	foreach (const ref actionJSON; resultTrace["matchingActions"].array)
	{
		auto marketHex = actionJSON["market"].array
		    .front["oldData"]
		    .str.chunks (2).map !(value =>
		    to !(ubyte) (value, 16)).array;

		auto actor = actionJSON["authorization"]
		    .array.map !(line => line["actor"].str)
		    .filter !(line => line != "prospectorsb")
		    .front;

		auto actionHex = actionJSON["hexData"]
		    .str.chunks (2).map !(value =>
		    to !(ubyte) (value, 16)).array;

		res ~= format !("%s\t%s\t%s\t%s\t%s") (timeStamp, actor,
		    actionHex.format !("%(%02x%)"),
		    marketHex.format !("%(%02x%)"), curCursor);
	}
}

int main (string [] args)
{
	stdout.setvbuf (16384, _IOLBF);
	prepare ();
	updateLogGeneric !(updateLogSales) (args[1],
	    queryForm, "account:prospectorsc action:mkpurchase");
	return 0;
}
