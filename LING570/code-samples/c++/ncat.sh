#!/bin/sh

# Build the program if needing, rerouting the output of make to STDERR.
make 1>&2

./ncat $@
