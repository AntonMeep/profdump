import std.stdio;
import std.string;
import std.conv;
import std.demangle;
import core.time : Duration;
import std.regex;

alias HASH = ubyte[4];

struct FunctionElement {
	string Name;
	string Mangled;
	ulong Calls;
}

struct Function {
	FunctionElement Me;
	FunctionElement[HASH] CallsTo;
	FunctionElement[HASH] CalledBy;
	ulong Time;
	ulong FunctionTime;

	this(string name, string mangled, ulong calls) {
		this.Me.Name = name;
		this.Me.Mangled = mangled;
		this.Me.Calls = calls;
	}

	void callsTo(FunctionElement func) {
		import std.digest.crc : crc32Of;
		HASH h = func.Mangled.crc32Of;
		this.CallsTo[h] = func;
	}

	void calledBy(FunctionElement func) {
		import std.digest.crc : crc32Of;
		HASH h = func.Mangled.crc32Of;
		this.CalledBy[h] = func;
	}

	const void toString(scope void delegate(const(char)[]) s, ulong tps = 0) {
		import std.format : format;
		s("Function '%s':\n".format(this.Me.Name));
		s("\tMangled name: '%s'\n".format(this.Me.Mangled));
		if(this.CallsTo) {
			s("\tCalls:\n");
			foreach(k, v; this.CallsTo)
				s("\t\t%s\n".format(v.Name));
		}
		if(this.CalledBy) {
			s("\tCalled by:\n");
			foreach(k, v; this.CalledBy)
				s("\t\t%s\n".format(v.Name));
		}
		if(tps) {
			s("\tFinished in: %f seconds (just this function)\n"
				.format(cast(double) this.FunctionTime / cast(double) tps));
			s("\tFinished in: %f seconds (this function and all descendants)\n"
				.format(cast(double) this.Time / cast(double) tps));
		} else {
			s("\tFinished in: %d ticks (just this function)\n".format(this.FunctionTime));
			s("\tFinished in: %d ticks (this function and all descendants)\n"
				.format(this.Time));
		}
	}
}

struct Profile {
	Function[] functions;
	ulong TicksPerSecond;

	this(ref File f) {
		Function temp;
		bool newEntry = false;
		foreach(ref line; f.byLine) {
			if(line.length == 0) {
				continue;
			} else if(line[0] == '-') {
				newEntry = true;
				if(temp.Me.Name.length)
					this.functions ~= temp;
					temp = Function();
			} else if(line[0] == '=') {
				auto i = line.indexOfAny("0123456789");
				assert(i > 0);
				auto s = line[i..$].indexOfNeither("0123456789");
				this.TicksPerSecond = line[i..i + s].to!ulong;
				break;
			} else if(line[0] == '\t') {
				auto cap = line.matchFirst(
					regex(r"\t\s*(\d+)\t\s*(\w+)"));
				assert(!cap.empty);
				if(newEntry) {
					temp.calledBy(FunctionElement(
						cap[2].to!string.demangle,
						cap[2].to!string,
						cap[1].to!ulong));
				} else {
					temp.callsTo(FunctionElement(
						cap[2].to!string.demangle,
						cap[2].to!string,
						cap[1].to!ulong));
				}
			} else {
				auto cap = line.matchFirst(
					regex(r"(\w+)\t\s*-?(\d+)\t\s*-?(\d+)\t\s*-?(\d+)"));
				assert(!cap.empty);
				newEntry = false;

				temp.Me = FunctionElement(
					cap[1].to!string.demangle,
					cap[1].to!string,
					cap[2].to!ulong);
				temp.Time = cap[3].to!ulong;
				temp.FunctionTime = cap[4].to!ulong;
			}
		}
	}

	const void toString(scope void delegate(const(char)[]) s) {
		foreach(ref f; this.functions) {
			f.toString(s, this.TicksPerSecond);
		}
	}
}

int main(string[] args) {
	auto f = File(args[1], "r");
	writeln(Profile(f));
	return 0;
}
