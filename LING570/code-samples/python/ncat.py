#!/usr/bin/python

"""%prog [--help] [N]

This script prints the first N lines from STDIN.  If N is not specified, STDIN
is printed until exhausted."""

import sys


def n_lines_from_stdin(n):
	"""Print the first n lines from STDIN
	"""
	while n:
		line = sys.stdin.readline()
		if not line:
			break
		print line.rstrip()
		n -= 1

if __name__ == "__main__":
	from optparse import OptionParser
	
	parser = OptionParser(__doc__)
	options, args = parser.parse_args()
	if len(args) == 0:
		n = -1
	else:
		n = int(args[0])
		
	n_lines_from_stdin(n)
