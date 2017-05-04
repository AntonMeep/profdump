module profdump.profile;

import profdump.func;
import profdump.utility;
import std.stdio : File;
import std.string : indexOfAny, indexOfNeither;
import std.conv : to;
import std.regex : regex, matchFirst;
import std.json : JSONValue;
import std.experimental.logger;

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

	const void toString(scope void delegate(const(char)[]) s, float threshold = 0) {
		foreach(ref f; this.Functions) {
			f.toString(s, this.TicksPerSecond, threshold);
		}
	}

	JSONValue toJSON(float threshold = 0) {
		JSONValue[] ret;
		foreach(ref f; this.Functions) {
			ret ~= f.toJSON(this.TicksPerSecond, threshold);
		}
		return JSONValue([
			"tps" : JSONValue(this.TicksPerSecond),
			"functions" : JSONValue(ret)]);
	}

	const float timeOf(HASH f)
	in {
		assert(f in this.Functions);
	} body {
		return cast(float) this.Functions[f].Time /
			cast(float) this.TicksPerSecond;
	}

	const float functionTimeOf(HASH f)
	in {
		assert(f in this.Functions);
	} body {
		return cast(float) this.Functions[f].FunctionTime /
			cast(float) this.TicksPerSecond;
	}

	const void toDOT(scope void delegate(const(char)[]) s,
			float threshold = 0,
			string[float] colours = [
				0: "limegreen",
				10: "slateblue",
				25: "steelblue",
				50: "royalblue",
				75: "navy",
				95: "red"
			]
		) {
		import std.format : format;
		import std.string : tr, wrap;
		import std.digest.crc : crc32Of;

		string clr(float f) {
			import std.algorithm : sort;
			foreach(k; sort!("a>b")(colours.keys)) {
				if(k <= f) {
					return colours[k];
				}
			}
			return "gray";
		}

		s("digraph {\n");
		HASH[][HASH] func;
		const HASH main = "_Dmain".crc32Of;
		assert(main in this.Functions);

		const float mainTime = this.timeOf(main);
		enum fmt = "\"%s\" [label=\"%s\\n%.2f%%(%.2f%%)\\n%fs(%fs)\", shape=\"box\"," ~
			" style=filled, fillcolor=\"%s\"];\n";

		foreach(k, ref v; this.Functions) {
			if(threshold == 0 || this.timeOf(k) > threshold) {
				func[k] = [];
				foreach(key, unused; v.CallsTo) {
					if(threshold != 0 && this.timeOf(key) <= threshold)
						continue;
					if(key !in func)
						func[key] = [];
					func[k] ~= key;
				}
			} else {
				continue;
			}
		}

		foreach(k, ref v; func) {
			s(fmt.format(
				this.Functions[k].Mangled.tr("\"", "\\\""),
				this.Functions[k].Name.tr("\"", "\\\"").wrap(40),
				this.timeOf(k) / mainTime * 100,
				this.functionTimeOf(k) / mainTime * 100,
				this.timeOf(k),
				this.functionTimeOf(k),
				clr(this.timeOf(k) / mainTime * 100)));
			foreach(i; v) {
				if(i !in func) {
					s(fmt.format(
						this.Functions[i].Mangled.tr("\"", "\\\""),
						this.Functions[i].Name.tr("\"", "\\\"").wrap(40),
						this.timeOf(i) / mainTime * 100,
						this.functionTimeOf(i) / mainTime * 100,
						this.timeOf(i),
						this.functionTimeOf(i),
						clr(this.timeOf(i) / mainTime * 100)));
				}
			}
		}

		foreach(k, ref v; func) {
			foreach(i; v)
				s("\"%s\" -> \"%s\" [label=\"%dx\"];\n".format(
					this.Functions[k].Mangled.tr("\"", "\\\""),
					this.Functions[i].Mangled.tr("\"", "\\\""),
					this.Functions[k].CallsTo[i].Calls));
		}
		s("}\n");
	}
}

