// Author: Ivan Kazmenko (gassa@mail.ru)
module pretty;
import std.json;
import std.stdio;

void main (string [] args)
{
	auto t = readln.parseJSON;
	t.toPrettyString.write;
}
