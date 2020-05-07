#!/bin/sh


build_kNN.sh train.vectors_0.1.txt test.vectors_0.1.txt 1 2 sys_cosine_0.1 >acc_cosine_0.1
build_kNN.sh train.vectors_0.05.txt test.vectors_0.05.txt 1 2 sys_cosine_0.05 >acc_cosine_0.05
build_kNN.sh train.vectors_0.01.txt test.vectors_0.01.txt 1 2 sys_cosine_0.01 >acc_cosine_0.01
build_kNN.sh train.vectors_0.025.txt test.vectors_0.025.txt 1 2 sys_cosine_0.025 >acc_cosine_0.025
build_kNN.sh train.vectors_0.001.txt test.vectors_0.001.txt 1 2 sys_cosine_0.001 >acc_cosine_0.001


build_kNN.sh train2.vectors_0.1.txt test2.vectors_0.1.txt 10 2 sys_cosine2_0.1 >acc_cosine2_0.1
build_kNN.sh train2.vectors_0.05.txt test2.vectors_0.05.txt 10 2 sys_cosine2_0.05 >acc_cosine2_0.05
build_kNN.sh train2.vectors_0.01.txt test2.vectors_0.01.txt 10 2 sys_cosine2_0.01 >acc_cosine2_0.01
build_kNN.sh train2.vectors_0.025.txt test2.vectors_0.025.txt 10 2 sys_cosine2_0.025 >acc_cosine2_0.025
build_kNN.sh train2.vectors_0.001.txt test2.vectors_0.001.txt 10 2 sys_cosine2_0.001 >acc_cosine2_0.001
