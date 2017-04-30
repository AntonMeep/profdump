import std.stdio;

import profile;

int main(string[] args) {
	auto f = File(args[1], "r");
	writeln(Profile(f).toJSON);
	return 0;
}
