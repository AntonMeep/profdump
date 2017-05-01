module profile;

import core.demangle : demangle;
import std.stdio : File;
import std.string : indexOfAny, indexOfNeither;
import std.conv : to;
import std.regex : regex, matchFirst;
import std.json : JSONValue;;

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

	const void toString(scope void delegate(const(char)[]) s, ulong tps = 0, double threshold = 0) {
		import std.format : format;
		if(threshold != 0 && (cast(double) this.Time / cast(double) tps) < threshold)
			return;
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

	JSONValue toJSON(ulong tps = 0, double threshold = 0) {
		if(threshold != 0 && (cast(double) this.Time / cast(double) tps) < threshold)
			return JSONValue(null);
		JSONValue ret = JSONValue([
			"name": this.Me.Name,
			"mangled": this.Me.Mangled
		]);
		if(this.CallsTo) {
			JSONValue[] temp;
			foreach(k, v; this.CallsTo) {
				temp ~= JSONValue([
					"name": JSONValue(v.Name),
					"mangled": JSONValue(v.Mangled),
					"calls": JSONValue(v.Calls)
				]);
			}
			ret["callsTo"] = JSONValue(temp);
		}
		if(this.CalledBy) {
			JSONValue[] temp;
			foreach(k, v; this.CalledBy) {
				temp ~= JSONValue([
					"name": JSONValue(v.Name),
					"mangled": JSONValue(v.Mangled),
					"calls": JSONValue(v.Calls)
				]);
			}
			ret["calledBy"] = JSONValue(temp);
		}
		if(tps) {
			ret["functionTimeSec"] = JSONValue(
				cast(double) this.FunctionTime / cast(double) tps);
			ret["timeSec"] = JSONValue(
				cast(double) this.Time / cast(double) tps);
		}
		ret["functionTime"] = JSONValue(this.FunctionTime);
		ret["time"] = JSONValue(this.Time);
		return ret;
	}
}

struct Profile {
	Function[HASH] Functions;
	ulong TicksPerSecond;

	this(ref File f) {
		import std.digest.crc : crc32Of;

		Function temp;
		bool newEntry = false;
		foreach(ref line; f.byLine) {
			if(line.length == 0) {
				continue;
			} else if(line[0] == '-') {
				newEntry = true;
				if(temp.Me.Name.length != 0) {
					this.Functions[temp.Me.Mangled.crc32Of] = temp;
					temp = Function();
				}
			} else if(line[0] == '=') {
				if(temp.Me.Name.length != 0)
					this.Functions[temp.Me.Mangled.crc32Of] = temp;
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
				temp.FunctionTime = cap[4].to!ulong;
				temp.Time = cap[3].to!ulong;
			}
		}
	}

	const void toString(scope void delegate(const(char)[]) s, double threshold = 0) {
		foreach(ref f; this.Functions) {
			f.toString(s, this.TicksPerSecond, threshold);
		}
	}

	JSONValue toJSON(double threshold = 0) {
		JSONValue[] ret;
		foreach(ref f; this.Functions) {
			ret ~= f.toJSON(this.TicksPerSecond, threshold);
		}
		return JSONValue([
			"tps" : JSONValue(this.TicksPerSecond),
			"functions" : JSONValue(ret)]);
	}

	const void toDOT(scope void delegate(const(char)[]) s, double threshold = 0) {
		import std.format : format;
		import std.string : tr, wrap;
		s("digraph {\n");
		foreach(ref f; this.Functions) {
			double time = cast(double) f.Time / cast(double) this.TicksPerSecond;
			if(threshold != 0 && time < threshold) {
					continue;
			}
			s("\"%s\" [label=\"%s\\n%f s\", shape=\"box\"];\n".format(
				f.Me.Mangled.tr("\"", "\\\""),
				f.Me.Name.tr("\"", "\\\"").wrap(40),
				time));
			foreach(ref c; f.CallsTo) {
				s("\"%s\" -> \"%s\" [label=\"%dx\"];\n"
					.format(
						f.Me.Mangled.tr("\"", "\\\""),
						c.Mangled.tr("\"", "\\\""),
						c.Calls));
			}
		}
		s("}\n");
	}
}
