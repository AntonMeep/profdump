profdump [![Page on DUB](https://img.shields.io/dub/v/profdump.svg)](http://code.dlang.org/packages/profdump) [![License](https://img.shields.io/dub/l/profdump.svg)](https://github.com/ohdatboi/profdump/blob/master/LICENSE)
=============
profdump converts output of D programming language profiler into:
- Plain text
- JSON
- DOT graph

## Why?
Because profiler gives you [this](./example/simple.log). It's very hard to read and understand it.
profdump can convert it to:
- [plain text](./example/simple.txt)
- [json](./example/simple.json)

or just draw this beautiful graph:
![simple graph](./example/simple.png?raw=true)

## Usage
```
Usage: profdump [options] [input file] [output file]
Converts the output of dlang compiler into a plain text, json or dot graph.
If input file is not specified, looks for 'trace.log' file.
You can set input and output file to stdin/stdout by passing '-' instead of file name.

Options:
-j      --json output JSON
-p     --plain output plain text
-d       --dot output dot graph
-t --threshold (seconds) hide functions below this threshold (default: 0.0)
      --pretty output pretty JSON (default: true)
      --colour customize colours of dot graph nodes (default: [0:"limegreen", 10:"slateblue", 50:"royalblue", 95:"red", 25:"steelblue", 75:"navy"])
-f     --force overwrite output file if exists
-h      --help This help information.
```

## Graph output
Every node represents a function and has the following layout:
```
+----------------------------+
|        Function name       |
| total time % (self time %) |
| total time s (self time s) |
+----------------------------+
```

And edge represents the calls between two functions and has the following layout:
```
           calls
parent --------------> child

```

## JSON output
Has the following layout:
```
{
	"functions": [
		{
			"name": <string>, // Demangled name of function
			"mangled": <string>, // Mangled name of function
			"time": <integer>, // Time spent on this function and all its children in ticks
			"timeSec": <float>, // Time spent on this function and all its children in seconds
			"functionTime": <integer>, // Time spent on this function in ticks
			"functionTimeSec": <float>, // Time spent on this function in seconds
			"callsTo": [ // All children which are called by this function
				{
					"name": <string>, // Demangled name of children
					"mangled": <string, // Mangled name of children
					"calls": <integer>, // Number of calls
				}
				<...>
			],
			"calledBy": [ // All parents which calls this function
				{
					"name": <string>, // Demangled name of parent
					"mangled": <string, // Mangled name of parent
					"calls": <integer>, // Number of calls
				}
				<...>
			]
		}
		<...>
	],
	"tps": <integer> // Number of ticks per second
}

```

## Plain text output
Should be easy to understand
