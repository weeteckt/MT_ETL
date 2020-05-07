#!/bin/sh

build_dt.py $1 $2 $3 $4 >$5
perl classify.pl $1 $2 $5 $6 $7