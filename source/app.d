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
		dot,
		blame
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
		} else if(option == "blame|b") {
			target = TARGET.blame;
		}
	}
	auto result = args.getopt(
		std.getopt.config.stopOnFirstNonOption,
		std.getopt.config.bundling,
		"plain|p", "print detailed information about functions (default)", &setTarget,
		"json|j", "print JSON", &setTarget,
		"dot|d", "output dot graph", &setTarget,
		"blame|b", "print list of functions ordered by time", &setTarget,
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
			if(exists(args[2]) && !force) {
				stderr.writefln("File '%s' already exists. Specify other file or pass '-f' option", args[2]);
				return help(result);
			} else {
				output = File(args[2], "w");
			}
		}
	}

	auto prof = Profile(input, verbose);

	final switch(target) with (TARGET) {
		case json:
			prof.writeJSON(output, threshold, pretty);
			return 0;
		case plain: case nul:
			prof.writeString(output, threshold);
			return 0;
		case dot:
			prof.writeDOT(output, threshold, colour);
			return 0;
		case blame: {
			import std.algorithm : sort;
			import std.string : leftJustify;
			import std.regex : regex, replaceAll;

			HASH[float] funcs;
			foreach(k, ref unused; prof.Functions) {
				auto perc = prof.percOf(k);
				if(threshold == 0 || perc >= threshold)
					funcs[perc] = k;
			}
			if(verbose) {
				foreach(k; sort!"a > b"(funcs.keys))
				output.writefln("%s\t%3.5fs %3.2f%%\t%3.5fs %3.2f%%",
					prof.Functions[funcs[k]]
						.Name
						.leftJustify(40),
					prof.timeOf(funcs[k]),
					prof.percOf(funcs[k]),
					prof.functionTimeOf(funcs[k]),
					prof.functionPercOf(funcs[k]));
			} else {
				foreach(k; sort!"a > b"(funcs.keys))
				output.writefln("%s\t%3.5fs %3.2f%%",
					prof.Functions[funcs[k]]
						.Name
						.replaceAll(
							regex(r"(?:@\w+\s|pure\s|nothrow\s)", "g"),
								"")
						.replaceAll(
							regex(r"\([ ,*A-Za-z0-9\(\)!\[\]@]+\)", "g"),
								"(..)")
						.leftJustify(40),
					prof.timeOf(funcs[k]),
					prof.percOf(funcs[k]));
			}
			return 0;
		}
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
