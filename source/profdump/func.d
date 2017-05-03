module profdump.func;

import std.json : JSONValue;
import profdump.utility : HASH;

struct FunctionElement {
	char[] Name;
	char[] Mangled;
	ulong Calls;
}

struct Function {
	char[] Name;
	char[] Mangled;
	ulong Calls;
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

	const void toString(scope void delegate(const(char)[]) s, ulong tps = 0, float threshold = 0) {
		import std.format : format;
		if(threshold != 0 && (cast(float) this.Time / cast(float) tps) < threshold)
			return;
		s("Function '%s':\n".format(this.Name));
		s("\tMangled name: '%s'\n".format(this.Mangled));
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
				.format(cast(float) this.FunctionTime / cast(float) tps));
			s("\tFinished in: %f seconds (this function and all descendants)\n"
				.format(cast(float) this.Time / cast(float) tps));
		} else {
			s("\tFinished in: %d ticks (just this function)\n".format(this.FunctionTime));
			s("\tFinished in: %d ticks (this function and all descendants)\n"
				.format(this.Time));
		}
	}

	JSONValue toJSON(ulong tps = 0, float threshold = 0) {
		if(threshold != 0 && (cast(float) this.Time / cast(float) tps) < threshold)
			return JSONValue(null);
		JSONValue ret = JSONValue([
			"name": this.Name,
			"mangled": this.Mangled
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
				cast(float) this.FunctionTime / cast(float) tps);
			ret["timeSec"] = JSONValue(
				cast(float) this.Time / cast(float) tps);
		}
		ret["functionTime"] = JSONValue(this.FunctionTime);
		ret["time"] = JSONValue(this.Time);
		return ret;
	}
}
