profdump [![Page on DUB](https://img.shields.io/dub/v/profdump.svg)](http://code.dlang.org/packages/profdump) 
[![License](https://img.shields.io/dub/l/profdump.svg)](https://github.com/AntonMeep/profdump/blob/master/LICENSE)
=============
profdump converts output of D programming language profiler into:
- Plain text
- JSON
- DOT graph

## Why?
Because profiler gives you [this](./example/simple.log). It's very hard to read and understand it.
profdump can convert it to:
- [plain text](./example/sample/simple.txt)
- [json](./example/sample/simple.json)

or just draw this beautiful graph:
![simple graph](./example/example.png?raw=true)

## Usage
```
Usage: profdump [options] [input file] [output file]
Converts the output of dlang compiler into a plain text, json or dot graph.
If input file is not specified, looks for 'trace.log' file.
You can set input and output file to stdin/stdout by passing '-' instead of file name.

Options:
-p     --plain print detailed information about functions (default)
-j      --json print JSON
-d       --dot output dot graph
-b     --blame print list of functions ordered by time
-t --threshold (% of main function) hide functions below this threshold (default: 0.0)
      --pretty prettify JSON output (default: true)
      --colour customize colours of dot graph nodes (default: [0:"limegreen", 10:"slateblue", 50:"royalblue", 95:"red", 25:"steelblue", 75:"navy"])
-f     --force overwrite output file if exists
-v   --verbose do not minimize function names
-h      --help This help information.
```

## Graph output
Every node represents a function and has the following layout:
```
+----------------------------+
|        Function name       |
| total time % (self time %) |
+----------------------------+
```

And edge represents the calls between two functions and has the following layout:
```
           calls
parent --------------> child

```

## Plain text output
Prints everything. Basically converts `trace.log` making it easier to read.
Check out examples:
- [Simple example](./example/sample/simple.txt)
- [Profdump's trace.log dump](./example/sample/profdump.txt)

## `--blame` option
Prints functions ordered by time:
```
void main()                             	0.01277s 100.00%
ulong example.fib(..)                   	0.01153s 90.25%
int example.child2(..)                  	0.00012s 0.91%
int example.child1(..)                  	0.00002s 0.12%
int example.sum(..)                     	0.00000s 0.03%
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
			"perc": <float>, // Time spent on this function and all its children in % of main function time
			"functionPerc": <float>, // Time spent on this function in % of main function time
			"callsTo": [ // All children which are called by this function
				{
					"name": <string>, // Demangled name of children
					"mangled": <string, // Mangled name of children
					"calls": <integer>, // Number of calls
				}
				<...>
			],
			"calledBy": [ // All functions that call this function
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
