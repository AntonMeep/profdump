import std.stdio;
import std.getopt;
import std.file : exists;

import profdump;

int main(string[] args) {
	File input = stdin;
	File output = stdout;
	bool pretty = true;
	float threshold = 1.0;
	enum TARGET : ubyte {
		nul,
		json,
		plain,
		dot
	}
	TARGET target = TARGET.nul;

	void setTarget(string option) {
		if(option == "json|j") {
			target = TARGET.json;
		} else if(option == "plain|p") {
			target = TARGET.plain;
		} else if(option == "dot|d") {
			target = TARGET.dot;
		}
	}
	auto result = args.getopt(
		"json|j", "", &setTarget,
		"plain|p", "", &setTarget,
		"dot|d", "", &setTarget,
		"threshold|t", "", &threshold,
		"pretty", "", &pretty
	);

	if(result.helpWanted) {
		return help(result);
	}

	if(args.length <= 1) {
		if(exists("trace.log")) {
			input = File("trace.log", "r");
		} else {
			stderr.writeln("'trace.log' not found, input file not specified");
			return help(result);
		}
	} else {
		if(args[1] == "-") {
			input = stdin;
		} else {
			if(exists(args[1])) {
				input = File(args[1], "r");
			} else {
				stderr.writefln("File '%s' does not exist", args[1]);
				return help(result);
			}
		}
	}

	if(args.length > 2) {
		if(args[2] == "-") {
			output = stdout;
		} else {
			if(exists(args[2])) {
				output = File(args[2], "w");
			} else {
				stderr.writefln("File '%s' does not exist", args[2]);
				return help(result);
			}
		}
	}

	auto prof = Profile(input);

	auto writer = (const(char)[] s) {
		output.write(s);
	};

	switch(target) with (TARGET) {
		case json:
			prof.toJSONString(writer, threshold, pretty);
			return 0;
		case plain:
			prof.toString(writer, threshold);
			return 0;
		case dot:
			prof.toDOT(writer, threshold);
			return 0;
		default:
			stderr.writeln("Wrong target");
			return help(result);
	}
}

int help(ref GetoptResult result) {
	defaultGetoptPrinter("profdump", result.options);
	return 0;
}
