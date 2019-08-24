import std.json, std.stdio;
void main () {File ("dfuse.token", "wt").write (File ("token.json").readln.parseJSON["token"].str);}
