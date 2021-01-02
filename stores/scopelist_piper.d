// Author: Ivan Kazmenko (gassa@mail.ru)
module scopelist_piper;
import std.algorithm;
import std.conv;
import std.json;
import std.range;
import std.stdio;

int main (string [] args)
{
	auto scopes = stdin.byLineCopy.join ("\n").parseJSON["scopes"].array;
	auto num = scopes.length.to !(int);
	auto lo = (args.length <= 1) ? 0 : max (0, args[1].to !(int));
	auto hi = (args.length <= 2) ? num : min (num, args[2].to !(int));
	if (!(0 <= lo && lo < hi && hi <= num))
	{
		return 1;
	}
	scopes[lo..hi].map !(v => v.str).joiner ("|").writeln;
	return 0;
}
