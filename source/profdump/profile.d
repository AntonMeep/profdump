module profdump.profile;

import profdump.func;
import profdump.utility;
import std.stdio : File;
import std.string : indexOfAny, indexOfNeither;
import std.conv : to;
import std.regex : regex, matchFirst;
import std.json : JSONValue;;

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
				if(temp.Name.length != 0) {
					this.Functions[temp.Mangled.crc32Of] = temp;
					temp = Function();
				}
			} else if(line[0] == '=') {
				if(temp.Name.length != 0)
					this.Functions[temp.Mangled.crc32Of] = temp;
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
				temp.Name = cap[1].demangle.dup;
				temp.Mangled = cap[1].dup;
				temp.Calls = cap[2].to!ulong;
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
				f.Mangled.tr("\"", "\\\""),
				f.Name.tr("\"", "\\\"").wrap(40),
				time));
			foreach(ref c; f.CallsTo) {
				s("\"%s\" -> \"%s\" [label=\"%dx\"];\n"
					.format(
						f.Mangled.tr("\"", "\\\""),
						c.Mangled.tr("\"", "\\\""),
						c.Calls));
			}
		}
		s("}\n");
	}
}
