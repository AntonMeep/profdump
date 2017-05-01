import std.stdio;

import profile;

int main(string[] args) {
	auto f = File(args[1], "r");
	Profile(f).toDOT((const(char)[] s) {write(s);});
	return 0;
}
