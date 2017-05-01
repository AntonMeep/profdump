module profdump.tree;

import profdump.func;
import profdump.utility : HASH;
struct TreeNode {
	char[] Name;
	char[] Mangled;
	ulong FunctionTime;
	ulong Time;
	TreeNode[HASH] Children;

	this(Function main) {
	}
}

