module profdump.utility;

alias HASH = ubyte[4];
char[] demangle(const(char)[] buf) {
	static import core.demangle;
	if(buf == "_Dmain".dup) {
		return "void main()".dup;
	} else {
		return core.demangle.demangle(buf);
	}
}
