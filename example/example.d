
void main() {
	foreach(i; 0..10) {
		fib(i);
	}

	foreach(i; 0..10) {
		sum(i,1);
	}
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

