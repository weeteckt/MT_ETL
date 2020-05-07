#!/bin/sh


TBL_classify.sh train2.txt model_file sys_output_train_1 1 > acc_train_1
TBL_classify.sh train2.txt model_file sys_output_train_5 5 > acc_train_5
TBL_classify.sh train2.txt model_file sys_output_train_10 10 > acc_train_10
TBL_classify.sh train2.txt model_file sys_output_train_20 20 > acc_train_20
TBL_classify.sh train2.txt model_file sys_output_train_30 50 > acc_train_50
TBL_classify.sh train2.txt model_file sys_output_train_100 100 > acc_train_100
TBL_classify.sh train2.txt model_file sys_output_train_150 150 > acc_train_150
TBL_classify.sh train2.txt model_file sys_output_train_200 200 > acc_train_200
TBL_classify.sh train2.txt model_file sys_output_train_250 250 > acc_train_250

TBL_classify.sh test2.txt model_file sys_output_test_1 1 > acc_test_1
TBL_classify.sh test2.txt model_file sys_output_test_5 5 > acc_test_5
TBL_classify.sh test2.txt model_file sys_output_test_10 10 > acc_test_10
TBL_classify.sh test2.txt model_file sys_output_test_20 20 > acc_test_20
TBL_classify.sh test2.txt model_file sys_output_test_30 50 > acc_test_50
TBL_classify.sh test2.txt model_file sys_output_test_100 100 > acc_test_100
TBL_classify.sh test2.txt model_file sys_output_test_150 150 > acc_test_150
TBL_classify.sh test2.txt model_file sys_output_test_200 200 > acc_test_200
TBL_classify.sh test2.txt model_file sys_output_test_250 250 > acc_test_250
