// Author: Ivan Kazmenko (gassa@mail.ru)
module refresh_log_banks;
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

void updateLogBanks (ref string [] res, const ref JSONValue resultTrace,
    const string timeStamp, const string curCursor)
{
	foreach (const ref actionJSON; resultTrace["matchingActions"].array)
	{
		auto actor = actionJSON["authorization"]
		    .array.map !(line => line["actor"].maybeStr)
		    .filter !(line => line != "prospectorsb")
		    .front;

		auto name = actionJSON["name"].maybeStr;

		auto hexData = actionJSON["hexData"].maybeStr;

		string [] dbOps;
		foreach (const ref op; actionJSON["dbOps"].array)
		{
			auto table =
			    op["key"]["table"].maybeStr;
			auto key = op["key"]["key"].maybeStr;
			auto oldData = op["oldData"].maybeStr;
			auto newData = op["newData"].maybeStr;
			dbOps ~= format !("%s:%s:%s:%s")
			    (table, key, oldData, newData);
		}

		res ~= format !("%s\t%s\t%s\t%s%-(\t%s%)")
		    (timeStamp, name, actor, hexData, dbOps);
	}
}

int main (string [] args)
{
	stdout.setvbuf (16384, _IOLBF);
	auto lowBlockNum = args[2];
	immutable string queryForm = (`{"query": "{
  searchTransactionsForward(query: \"%s\",
                            lowBlockNum: ` ~ lowBlockNum ~ `,
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
          hexData
          dbOps {
            key {
              table
              key(encoding: DECIMAL)
            }
            oldData
            newData
          }
        }
      }
    }
  }
}"}`).splitter ('\n').map !(strip).join (' ');

	updateLogGeneric !(updateLogBanks) (args[1],
	    queryForm, "account:prospectorsc " ~
	    "(action:mvwrkgold OR action:mvstorgold OR action:setbankp)");
	return 0;
}
