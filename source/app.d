import std.stdio;
import std.getopt;
import std.file : exists;
import std.format : format;

import profdump;

int main(string[] args) {
	File input = stdin;
	File output = stdout;
	bool pretty = true;
	bool force = false;
	bool verbose = false;
	float threshold = 0.0;
	enum TARGET : ubyte {
		nul,
		json,
		plain,
		dot
	}
	TARGET target = TARGET.nul;
	string[float] colour;
	string[float] colourDefault = [
		0: "limegreen",
		10: "slateblue",
		25: "steelblue",
		50: "royalblue",
		75: "navy",
		95: "red"
	];

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
		std.getopt.config.stopOnFirstNonOption,
		std.getopt.config.bundling,
		"json|j", "output JSON", &setTarget,
		"plain|p", "output plain text", &setTarget,
		"dot|d", "output dot graph", &setTarget,
		"threshold|t", "(%% of main function) hide functions below this threshold (default: %1.1f)"
			.format(threshold), &threshold,
		"pretty", "output pretty JSON (default: true)", &pretty,
		"colour", "customize colours of dot graph nodes (default: %s)"
			.format(colourDefault), &colour,
		"force|f", "overwrite output file if exists", &force,
		"verbose|v", "do not minimize function names", &verbose
	);

	if(colour.length == 0)
		colour = colourDefault;

	if(result.helpWanted || target == TARGET.nul) {
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
			if(exists(args[2]) && !force) {
				stderr.writefln("File '%s' already exists. Specify other file or pass '-f' option", args[2]);
				return help(result);
			} else {
				output = File(args[2], "w");
			}
		}
	}

	auto prof = Profile(input, verbose);

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
			prof.toDOT(writer, threshold, colour);
			return 0;
		default:
			stderr.writeln("Wrong target");
			return help(result);
	}
}

enum HELPTEXT = "Usage: profdump [options] [input file] [output file]\n" ~
"Converts the output of dlang compiler into a plain text, json or dot graph.\n" ~
"If input file is not specified, looks for 'trace.log' file.\n" ~
"You can set input and output file to stdin/stdout by passing '-' instead of file name.\n" ~
"\n" ~
"Options:";


int help(ref GetoptResult result) {
	defaultGetoptPrinter(HELPTEXT, result.options);
	return 0;
}
