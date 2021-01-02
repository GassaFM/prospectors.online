// Author: Ivan Kazmenko (gassa@mail.ru)
module scopelist_piper;
import std.algorithm;
import std.conv;
import std.json;
import std.range;
import std.stdio;

void main (string [] args)
{
	JSONValue t;
	foreach (ref name; args[2..$])
	{
		try
		{
			auto s = File (name, "rb").byLineCopy.joiner.parseJSON;
			if (t == JSONValue.init)
			{
				t = s;
			}
			else
			{
				t["tables"].array ~= s["tables"].array;
			}
		}
		catch (Exception e)
		{
		}
	}
	File (args[1], "wb").writeln (t);
}
