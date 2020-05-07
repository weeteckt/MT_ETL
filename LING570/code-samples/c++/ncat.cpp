#include <iostream>
#include <string>

using namespace std;

// This program takes a single integer arguments and prints that many lines
// from STDIN to STDOUT.

int main(int argc, char* argv[]) {
	int n;
	string line;
	
	// If no arguments are specified, n=-1 will cause the program to loop until
	// STDIN is exhausted.
	n = argc >= 2 ? atoi(argv[1]) : -1;
	while(n-- && getline(cin, line)) {
		cout << line << endl;
	};
	return 0;
}
