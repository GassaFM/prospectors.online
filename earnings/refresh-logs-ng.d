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
          name
          account
          hexData
        }
      }
    }
  }
}"}`.splitter ('\n').map !(strip).join (' ');

void updateLogData (ref string [] res, const ref JSONValue resultTrace,
    const string timeStamp, const string curCursor)
{
	foreach (const ref actionJSON;
	    resultTrace["matchingActions"].array[0..1])
	{ // [0..1] is a hack to exclude notifications, could use "input:true"
		auto contract = actionJSON["account"].str;
		auto actionName = actionJSON["name"].str;
		auto actors = actionJSON["authorization"]
		    .array.map !(line => line["actor"].str).array;
		auto hexData = actionJSON["hexData"].str;

		res ~= format ("%s %s %s %-(%s+%) %s",
		    timeStamp, contract, actionName,
		    actors, hexData);
	}
}

int main (string [] args)
{
	stdout.setvbuf (16384, _IOLBF);
	prepare ();
	updateLogGeneric !(updateLogData) (args[1], queryForm, args[2]);
	updateLogGeneric !(updateLogData) (args[1], queryForm, args[3]);
	return 0;
}
