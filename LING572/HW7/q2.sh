#!/bin/sh

rm test train test_temp* train_temp* class_map final_sys_output 2>stderr
rm -r 1-vs-2 2-vs-3 1-vs-3 $3 2>stderr
mkdir $3
cd $3
mkdir 1-vs-2 2-vs-3 1-vs-3
cd ..

perl q2.pl $@


rm test train temp* 2>stderr

cp $1 1-vs-2/train.txt
cp $1 1-vs-3/train.txt
cp $1 2-vs-3/train.txt

cd 1-vs-2
info2vectors --input train --output train.vectors 2>stderr
info2vectors --input test --output test.vectors --use-pipe-from train.vectors > /dev/null 2>&1
info2vectors --input train.txt --output train.v --use-pipe-from train.vectors > /dev/null 2>&1
vectors2train --training-file train.vectors --trainer MaxEnt --output-classifier maxent_model --report train:accuracy train:confusion > train.stdout 2>train.stderr
classify --testing-file test.vectors --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output 2>sys_output.stderr
classify --testing-file train.v --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output_train 2>sys_output.stderr
rm *stderr *.vectors *model *.v *.txt *.stdout
cd ..
cp 1-vs-2/sys_output test_temp1v2
cp 1-vs-2/sys_output_train train_temp1v2
rm 1-vs-2/sys_output_train
cp 1-vs-2/* $3/1-vs-2/

cd 2-vs-3
info2vectors --input train --output train.vectors 2>stderr
info2vectors --input test --output test.vectors --use-pipe-from train.vectors > /dev/null 2>&1
info2vectors --input train.txt --output train.v --use-pipe-from train.vectors > /dev/null 2>&1
vectors2train --training-file train.vectors --trainer MaxEnt --output-classifier maxent_model --report train:accuracy train:confusion > train.stdout 2>train.stderr
classify --testing-file test.vectors --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output 2>sys_output.stderr
classify --testing-file train.v --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output_train 2>sys_output.stderr
rm *stderr *.vectors *model *.v *.txt *.stdout
cd ..
cp 2-vs-3/sys_output test_temp2v3
cp 2-vs-3/sys_output_train train_temp2v3
rm 2-vs-3/sys_output_train
cp 2-vs-3/* $3/2-vs-3/

cd 1-vs-3
info2vectors --input train --output train.vectors 2>stderr
info2vectors --input test --output test.vectors --use-pipe-from train.vectors > /dev/null 2>&1
info2vectors --input train.txt --output train.v --use-pipe-from train.vectors > /dev/null 2>&1
vectors2train --training-file train.vectors --trainer MaxEnt --output-classifier maxent_model --report train:accuracy train:confusion > train.stdout 2>train.stderr
classify --testing-file test.vectors --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output 2>sys_output.stderr
classify --testing-file train.v --classifier maxent_model --report test:accuracy test:confusion test:raw > sys_output_train 2>sys_output.stderr
rm *stderr *.vectors *model *.v *.txt *.stdout
cd ..
cp 1-vs-3/sys_output test_temp1v3
cp 1-vs-3/sys_output_train train_temp1v3
rm 1-vs-3/sys_output_train
cp 1-vs-3/* $3/1-vs-3/

rm -r 1-vs-2 2-vs-3 1-vs-3 2>stderr

perl write_final_q2.pl $1 $2

cp final_sys_output $3
cp class_map $3
cp acc* $3

rm class_map train_sys final_sys_output acc* test_temp* train_temp* 2>stderr
rm stderr