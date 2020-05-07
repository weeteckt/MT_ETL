#!/bin/sh

rm $1 2>stderr
rm $2 2>stderr

./create_vectors.pl $@