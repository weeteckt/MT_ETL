#!/bin/sh

cat $2 | /opt/dropbox/09-10/570/hw2/graehl/carmel/bin/carmel -b -sli -q -OE $1 > result.out
./fst_acceptor.pl < $2