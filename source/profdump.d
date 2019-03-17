module profdump;

import containers;

alias HASH = ubyte[4];

import std.typecons : RefCounted;

alias String = RefCounted!(DynamicArray!char);

struct Function {
	private {
		String m_name;
		ulong m_calls;
	}

	this(string name, ulong calls = 0) {
		m_name.reserve(name.length);
		foreach(ref c; name)
			m_name ~= c;
		m_calls = calls;
	}

	this(String name, ulong calls = 0) {
		m_name = name;
		m_calls = calls;
	}

@property:
	auto name()         { return m_name;  }
	void name(String m) { m_name = m;     }

	auto calls()        { return m_calls; }
	void calls(ulong c) { m_calls = c;    }

	HASH hashOf() {
		import std.digest.murmurhash : MurmurHash3;
		import std.digest            : digest;

		return m_name[].digest!(MurmurHash3!32);
	}
}

@("Function is alrighty")
unittest {
	Function("_Dmain", 1).hashOf;
}

alias FuncMap = RefCounted!(HashMap!(HASH, Function));

struct Entity {
	private {
		Function m_function;
		FuncMap m_callsTo;
		FuncMap m_calledBy;
		ulong m_time;
		ulong m_total_time;
	}

	alias m_function this;

@property:
	auto callsTo()                    { return m_callsTo;     }
	void callsTo(typeof(m_callsTo) t) { m_callsTo     = t;    }
	void callsTo(Function f)
	in(f.hashOf !in m_callsTo) {
		m_callsTo[f.hashOf] = f;
	}

	auto calledBy()                    { return m_calledBy;   }
	void calledBy(typeof(m_callsTo) t) { m_calledBy   = t;    }
	void calledBy(Function f)
	in(f.hashOf !in m_calledBy) {
		m_calledBy[f.hashOf] = f;
	}

	auto time()                        { return m_time;       }
	void time(ulong t)                 { m_time       = t;    }

	auto totalTime()                   { return m_total_time; }
	void totalTime(ulong t)            { m_total_time = t;    }
}
