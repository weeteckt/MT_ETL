#!/bin/sh


rmdir $6 2>stderr
mkdir $6 2>stderr

rm $6/vectors 2>stderr
rm $6/sys_cluster 2>stderr
rm $6/*.map 2>stderr
rm $6/*.acc 2>stderr

./create_vector.sh $1 $6/vectors $2 $3
./k-medoids.sh $6/vectors $4 $6/sys_cluster
./calc_acc.sh $5 $6/sys_cluster 0 > $6/res.1_to_1.map 2>$6/res.1_to_1.acc
./calc_acc.sh $5 $6/sys_cluster 1 > $6/res.many_to_1.map 2>$6/res.many_to_1.acc  
