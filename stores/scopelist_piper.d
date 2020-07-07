// Author: Ivan Kazmenko (gassa@mail.ru)
module scopelist_piper;
import std.algorithm;
import std.json;
import std.range;
import std.stdio;

void main ()
{
	stdin.byLineCopy.join ("\n").parseJSON["scopes"].array
	    .map !(v => v.str).joiner ("|").writeln;
}
