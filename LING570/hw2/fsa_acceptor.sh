#!/bin/sh

cat /opt/dropbox/09-10/570/$2 | /opt/dropbox/09-10/570/hw2/graehl/carmel/bin/carmel -b -sli -IE $1 > result.out
./fsa_acceptor.pl < /opt/dropbox/09-10/570/$2