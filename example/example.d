void main() {
	foreach(i; 0..10) {
		fib(i);
	}

	foreach(i; 0..10) {
		sum(i,1);
	}

	child1(10);
	child2(20);
}

int sum(int a, int b) {
	return a + b;
}

size_t fib(size_t i) {
	if(i == 0) {
		return 0;
	} else if(i == 1) {
		return 1;
	} else {
		return (fib(i - 1) + fib(i - 2));
	}
}

int child1(int i) {
	return i+1;
}

int child2(int i) {
	child1(i);
	child1(i);
	return i;
}
 
