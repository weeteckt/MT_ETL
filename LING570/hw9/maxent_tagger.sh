#!/bin/sh

rm final_test.vectors.txt 2>stderr
rm final_train.vectors.txt 2>stderr
rm kept_feats 2>stderr
rm train.vectors.feats 2>stderr
rm train_voc 2>stderr

./maxent_tagger.pl $@

rmdir $5 2>stderr
mkdir $5 2>stderr

cp final_test.vectors.txt $5
cp final_train.vectors.txt $5
cp kept_feats $5
cp train.vectors.feats $5
cp train_voc $5

cd $5

info2vectors --input final_train.vectors.txt --output final_train.vectors
info2vectors --input final_test.vectors.txt --output final_test.vectors --use-pipe-from final_train.vectors
vectors2train -Xmx1000m --training-file final_train.vectors --trainer MaxEnt --output-classifier me_model --report train:accuracy train:confusion >me.stdout 2>me.stderr
classify --testing-file final_test.vectors --classifier me_model  --report test:accuracy test:confusion test:raw >me_res.stdout 2>me_res.stderr

cd ..

rm final_test.vectors.txt 2>stderr
rm final_train.vectors.txt 2>stderr
rm kept_feats 2>stderr
rm train.vectors.feats 2>stderr
rm train_voc 2>stderr
rm stderr 2>stderr