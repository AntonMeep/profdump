import std.stdio;

import profdump;

int main(string[] args) {
	auto f = File(args[1], "r");
	Profile(f).toDOT((const(char)[] s) {write(s);}, 0.5);
	return 0;
}
