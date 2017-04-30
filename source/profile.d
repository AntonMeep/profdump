module profile;

import core.demangle : demangle;
import std.stdio : File;
import std.string : indexOfAny, indexOfNeither;
import std.conv : to;
import std.regex : regex, matchFirst;

alias HASH = ubyte[4];

struct FunctionElement {
	char[] Name;
	char[] Mangled;
	ulong Calls;
}

struct Function {
	FunctionElement Me;
	FunctionElement[HASH] CallsTo;
	FunctionElement[HASH] CalledBy;
	ulong FunctionTime;
	ulong Time;

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
				s("\t\t%s\t%d times\n".format(v.Name, v.Calls));
		}
		if(this.CalledBy) {
			s("\tCalled by:\n");
			foreach(k, v; this.CalledBy)
				s("\t\t%s\t%d times\n".format(v.Name, v.Calls));
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

	const void toJSON(scope void delegate(const(char)[]) s, ulong tps = 0) {
		import std.format;
		s('{');
		s('"name":"%s","mangled":"%s",'.format(this.Me.Name, this.Me.Mangled));
		if(this.CalledBy) {
			s('"calledBy":{');
			foreach(k, v; this.CalledBy)
				s('[')
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
				if(temp.Me.Name.length != 0) {
					this.functions ~= temp;
					temp = Function();
				}
			} else if(line[0] == '=') {
				if(temp.Me.Name.length != 0)
					this.functions ~= temp;
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
						cap[2].demangle.dup,
						cap[2].dup,
						cap[1].to!ulong));
				} else {
					temp.callsTo(FunctionElement(
						cap[2].demangle.dup,
						cap[2].dup,
						cap[1].to!ulong));
				}
			} else {
				auto cap = line.matchFirst(
					regex(r"(\w+)\t\s*-?(\d+)\t\s*-?(\d+)\t\s*-?(\d+)"));
				assert(!cap.empty);
				newEntry = false;
				temp.Me = FunctionElement(
					cap[1].demangle.dup,
					cap[1].dup,
					cap[2].to!ulong);
				temp.FunctionTime = cap[3].to!ulong;
				temp.Time = cap[4].to!ulong;
			}
		}
	}

	const void toString(scope void delegate(const(char)[]) s) {
		foreach(ref f; this.functions) {
			f.toString(s, this.TicksPerSecond);
		}
	}

	JSONValue toJSON() {
		JSONValue ret;
		foreach(ref f; this.functions) {
			ret ~= f.toJSON;
		}
		return ret;
	}
}
