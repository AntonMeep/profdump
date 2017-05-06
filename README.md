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
