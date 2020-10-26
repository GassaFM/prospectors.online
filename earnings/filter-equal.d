// Author: Ivan Kazmenko (gassa@mail.ru)
module filter_equal;
import std.stdio;

void main ()
{
	bool [string] dict;
	foreach (line; stdin.byLineCopy ())
	{
		if (line !in dict)
		{
			writeln (line);
			dict[line] = true;
		}
	}
}
