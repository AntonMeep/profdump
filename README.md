profdump [![Page on DUB](https://img.shields.io/dub/v/profdump.svg)](http://code.dlang.org/packages/profdump) [![License](https://img.shields.io/dub/l/profdump.svg)](https://github.com/ohdatboi/profdump/blob/master/LICENSE)
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
### Example of plain text output:
```
Function 'int example.child1(..)':
	Mangled name: '_D7example6child1FiZi'
	Called by:
		int example.child2(..)	2 times
		void main()	1 times
	Took: 0.000015 seconds (0.118131%)
	Finished in: 0.000015 seconds (0.118131%)
Function 'ulong example.fib(..)':
	Mangled name: '_D7example3fibFmZm'
	Calls:
		ulong example.fib(..)	266 times
	Called by:
		ulong example.fib(..)	266 times
		void main()	10 times
	Took: 0.011525 seconds (90.252014%)
	Finished in: 0.011525 seconds (90.252014%)
Function 'int example.sum(..)':
	Mangled name: '_D7example3sumFiiZi'
	Called by:
		void main()	10 times
	Took: 0.000003 seconds (0.026251%)
	Finished in: 0.000003 seconds (0.026251%)
Function 'int example.child2(..)':
	Mangled name: '_D7example6child2FiZi'
	Calls:
		int example.child1(..)	2 times
	Called by:
		void main()	1 times
	Took: 0.000107 seconds (0.835667%)
	Finished in: 0.000117 seconds (0.914421%)
Function 'void main()':
	Mangled name: '_Dmain'
	Calls:
		int example.child1(..)	1 times
		ulong example.fib(..)	10 times
		int example.sum(..)	10 times
		int example.child2(..)	1 times
	Took: 0.001120 seconds (8.767939%)
	Finished in: 0.012770 seconds (100.000000%)
```
