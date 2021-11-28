// Author: Ivan Kazmenko (gassa@mail.ru)
module generate_map_css;
import std.range;
import std.stdio;

void main ()
{
	stdout = File ("map.css", "wt");
	writeln (`.map {`);
	writeln (`  table-layout: fixed;`);
	writeln (`  width: 100%;`);
	writeln (`  margin: 0px;`);
	writeln (`  padding: 0px;`);
	writeln (`  border-style: solid;`);
	writeln (`  border-collapse: collapse;`);
	writeln (`  text-align: center;`);
	writeln (`  font-family: Tahoma, Geneva, sans-serif;`);
	writeln (`}`);
	writeln (``);
	writeln (`.coord {`);
//	writeln (`  width: 1.785%;`);
//	writeln (`  height: 1.785%;`);
	writeln (`  width: 21px;`);
	writeln (`  font-weight: bold;`);
	writeln (`  font-size: 10px;`);
	writeln (`  border-style: solid;`);
	writeln (`  border-width: 2px;`);
	writeln (`}`);
	writeln (``);
	writeln (`.plot {`);
	writeln (`  width: 21px;`);
	writeln (`  font-size: 14px;`);
	writeln (`  border-style: solid;`);
	writeln (`  border-width: 1px;`);
	writeln (`}`);
	writeln (``);
	writeln (`.header:hover {`);
	writeln (`  background-color: #BBBBBB;`);
	writeln (`}`);

	void generateResourceClasses (string name, int lo, int hi,
	    int [] loColor, int [] hiColor, int [] specialColors,
	    bool whiteMainFont = false, bool generateSuffix = true)
	{
		foreach (me; lo..hi + 1)
		{
			int [] meColor;
			foreach (v; zip (loColor, hiColor))
			{
				meColor ~= (v[0] * (hi - me) +
				    v[1] * (me - lo)) / (hi - lo);
			}
			writeln (``);
			writefln (`.%s-%s {`, name, me);
			writefln (`  background-color: #%(%02X%);`, meColor);
			if (whiteMainFont)
			{
				writefln (`  color: #FFFFFF;`);
				writefln (`  border-color: #000000;`);
			}
			writeln (`}`);
		}
		if (generateSuffix)
		{
			foreach (i, c; "xzqca")
			{
				writeln (``);
				writefln (`.%s-%s {`, name, c);
				writefln (`  background-color: #%06X;`,
				    specialColors[i]);
				writeln (`}`);
			}
		}
	}

	generateResourceClasses ("gold",    0, 100,
	    [0xFF, 0xF7, 0xD0], [0xFF, 0xD7, 0x00],
	    [0xBBBBBB, 0xEEEEEE, 0x99CCEE, 0xBB88FF, 0x77FF77]);
	generateResourceClasses ("wood",    0, 109,
	    [0xD0, 0xFF, 0xD0], [0x30, 0xAF, 0x30],
	    [0xBBBBBB, 0xEEEEEE, 0x99CCEE, 0xBB88FF, 0x77FF77]);
	generateResourceClasses ("stone",   0,  61,
	    [0xDF, 0xDF, 0xFF], [0x88, 0x8C, 0xAD],
	    [0xBBBBBB, 0xEEEEEE, 0x99CCEE, 0xBB88FF, 0x77FF77]);
	generateResourceClasses ("coal",    0,  76,
	    [0x7F, 0x7F, 0x7F], [0x1F, 0x1F, 0x1F],
	    [0xBBBBBB, 0xEEEEEE, 0x99CCEE, 0xBB88FF, 0x77FF77], true);
	generateResourceClasses ("clay",    0,  96,
	    [0xEF, 0xDF, 0xDF], [0xAD, 0x50, 0x49],
	    [0xBBBBBB, 0xEEEEEE, 0x99CCEE, 0xBB88FF, 0x77FF77]);
	generateResourceClasses ("ore",     0,  86,
	    [0xEF, 0xDF, 0xF7], [0x7F, 0x50, 0xA7],
	    [0xBBBBBB, 0xEEEEEE, 0x99CCEE, 0xBB88FF, 0x77FF77]);
	generateResourceClasses ("coffee",  0,  30,
	    [0xDC, 0xAB, 0x75], [0x72, 0x40, 0x1C],
	    [0xBBBBBB, 0xEEEEEE, 0x99CCEE, 0xBB88FF, 0x77FF77], true);
	generateResourceClasses ("moss",    0,  30,
	    [0xCD, 0xDF, 0xB5], [0x8A, 0x9A, 0x5B],
	    [0xBBBBBB, 0xEEEEEE, 0x99CCEE, 0xBB88FF, 0x77FF77], true);
	generateResourceClasses ("worker",  0,   9,
	    [0xCF, 0xCF, 0xEF], [0x7F, 0x7F, 0xDF],
	    [0xBBBBBB, 0xEEEEEE, 0x99CCEE, 0xBB88FF, 0x77FF77], false, false);
	generateResourceClasses ("worker", 10,  99,
	    [0x7F, 0x7F, 0xDF], [0x1F, 0x1F, 0xBF],
	    [0xBBBBBB, 0xEEEEEE, 0x99CCEE, 0xBB88FF, 0x77FF77]);
}
