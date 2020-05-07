#!/bin/sh

./format_input.pl < $2 > format_input
cat format_input | /opt/dropbox/09-10/570/hw2/graehl/carmel/bin/carmel -b -k 1 -q -sli $1 > fst.out 2>fst.log
./decoder.pl < fst.out > $3
rm format_input
rm fst.out
rm fst.log