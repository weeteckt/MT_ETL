#!/bin/sh

./format_word.pl < $2 > input_words
cat input_words | /opt/dropbox/09-10/570/hw2/graehl/carmel/bin/carmel -b -k 1 -q -sli -OE $1 > fsm.out 2>fsm.log
./morph_acceptor2.pl < $2 > $3
rm input_words
rm fsm.out
rm fsm.log