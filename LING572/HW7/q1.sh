#!/bin/sh

rm test train test_temp* train_temp* class_map final_sys_output 2>stderr
rm -r 1-vs-all 2-vs-all 3-vs-all $3 2>stderr
mkdir $3
cd $3
mkdir 1-vs-all 2-vs-all 3-vs-all 
cd ..


perl q1.pl $@

rm test train temp* 2>stderr


cd 1-vs-all
info2vectors --input train --output train.vectors 2>stderr
info2vectors --input test --output test.vectors --use-pipe-from train.vectors > /dev/null 2>&1
vectors2train --training-file train.vectors --trainer MaxEnt --output-classifier maxent_model --report train:accuracy train:confusion > train.stdout 2>train.stderr
classify --testing-file test.vectors --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output 2>sys_output.stderr
classify --testing-file train.vectors --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output_train 2>sys_output.stderr
rm *stderr *.vectors *model *.stdout
cd ..
cp 1-vs-all/sys_output test_temp1
cp 1-vs-all/sys_output_train train_temp1
rm 1-vs-all/sys_output_train
cp 1-vs-all/* $3/1-vs-all/

cd 2-vs-all
info2vectors --input train --output train.vectors 2>stderr
info2vectors --input test --output test.vectors --use-pipe-from train.vectors > /dev/null 2>&1
vectors2train --training-file train.vectors --trainer MaxEnt --output-classifier maxent_model --report train:accuracy train:confusion > train.stdout 2>train.stderr
classify --testing-file test.vectors --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output 2>sys_output.stderr
classify --testing-file train.vectors --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output_train 2>sys_output.stderr
rm *stderr *.vectors *model *.stdout
cd ..
cp 2-vs-all/sys_output test_temp2
cp 2-vs-all/sys_output_train train_temp2
rm 2-vs-all/sys_output_train
cp 2-vs-all/* $3/2-vs-all/

cd 3-vs-all
info2vectors --input train --output train.vectors 2>stderr
info2vectors --input test --output test.vectors --use-pipe-from train.vectors > /dev/null 2>&1
vectors2train --training-file train.vectors --trainer MaxEnt --output-classifier maxent_model --report train:accuracy train:confusion > train.stdout 2>train.stderr
classify --testing-file test.vectors --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output 2>sys_output.stderr
classify --testing-file train.vectors --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output_train 2>sys_output.stderr
rm *stderr *.vectors *model *.stdout
cd ..
cp 3-vs-all/sys_output test_temp3
cp 3-vs-all/sys_output_train train_temp3
rm 3-vs-all/sys_output_train
cp 3-vs-all/* $3/3-vs-all/

rm -r 1-vs-all 2-vs-all 3-vs-all 2>stderr

perl write_final_q1.pl

cp final_sys_output $3
cp class_map $3
cp acc* $3

rm class_map train_sys final_sys_output acc* test_temp* train_temp* 2>stderr
rm stderr