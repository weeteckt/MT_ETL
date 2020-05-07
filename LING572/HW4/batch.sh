#!/bin/sh


build_kNN.sh train.vectors.txt test.vectors.txt 1 1 sys_euclidean_1 >acc_euclidean_1
build_kNN.sh train.vectors.txt test.vectors.txt 5 1 sys_euclidean_5 >acc_euclidean_5
build_kNN.sh train.vectors.txt test.vectors.txt 10 1 sys_euclidean_10 >acc_euclidean_10

build_kNN.sh train.vectors.txt test.vectors.txt 1 2 sys_cosine_1 >acc_cosine_1
build_kNN.sh train.vectors.txt test.vectors.txt 5 2 sys_cosine_5 >acc_cosine_5
build_kNN.sh train.vectors.txt test.vectors.txt 10 2 sys_cosine_10 >acc_cosine_10

build_kNN.sh train2.vectors.txt test2.vectors.txt 1 1 sys_b_euclidean_1 >acc_b_euclidean_1
build_kNN.sh train2.vectors.txt test2.vectors.txt 5 1 sys_b_euclidean_5 >acc_b_euclidean_5
build_kNN.sh train2.vectors.txt test2.vectors.txt 10 1 sys_b_euclidean_10 >acc_b_euclidean_10

build_kNN.sh train2.vectors.txt test2.vectors.txt 1 2 sys_b_cosine_1 >acc_b_cosine_1
build_kNN.sh train2.vectors.txt test2.vectors.txt 5 2 sys_b_cosine_5 >acc_b_cosine_5
build_kNN.sh train2.vectors.txt test2.vectors.txt 10 2 sys_b_cosine_10 >acc_b_cosine_10