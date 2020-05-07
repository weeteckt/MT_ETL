#!/bin/sh

# Build the jar file, rerouting the output of ant to STDERR.
ant jar 1>&2

java -jar build/jar/NCat.jar $@
