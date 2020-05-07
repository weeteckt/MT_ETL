#!/bin/sh

rm train_bin_vectors 2>stderr
rm test_bin_vectors 2>stderr

perl binarize.pl $1 $2
 
info2vectors --input $1 --output train.vectors
info2vectors --input $2 --output test.vectors  --use-pipe-from train.vectors

info2vectors --input train_bin_vectors --output train_bin.vectors
info2vectors --input test_bin_vectors --output test_bin.vectors  --use-pipe-from train_bin.vectors

vectors2classify --training-file train.vectors --testing-file test.vectors --trainer DecisionTree > q1.stdout 2>q1.stderr

vectors2classify --training-file train_bin.vectors --testing-file test_bin.vectors --trainer DecisionTree > q1_bin.stdout 2>q1_bin.stderr

clear
echo
echo Results Before Binarization:
grep -i Summary* q1.stdout
echo 

echo Results After Binarization:
grep -i Summary* q1_bin.stdout
echo  