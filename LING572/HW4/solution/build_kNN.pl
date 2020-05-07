#!/usr/bin/env perl


## created on 1/20/08

## Purpose: build a kNN learner 

## to run:
##    $0 training_data test_data k similarity_function test_raw 

## the format of the training and testing data is:
##  instanceName label f1 v1 f2 v2 ....

## features are NOT treated as binary features.

## test_raw has the format
##   instanceName label c1 p1 c2 p2 ...
##
## where label1 is the true label, (c_i, p_i) is sorted according to the p_i.
## p_i is the percentage of neighbors with label c_i.

## stdout shows the confusion matrix and training and test accuracy


############ options
my $debug = 0;
my $output_all_prob = 1;

############ constants
my $log10 = log(10);
my $Euclidean_Distance_Func = 1;
my $Cosine_Func = 2;

use strict;

main();

1;


#########################
sub main {
    my $cnt = 0;
    
    my $arg_num = @ARGV;
    
    if($arg_num != 5){
	die "kNN: classify training and test data\n usage: $0 training_data test_data k similarity_function test_raw > acc_file\n Similarity function: $Euclidean_Distance_Func: Euclidean distance; $Cosine_Func: cosine\n";
    }

    my $training_file = $ARGV[0];
    my $test_file = $ARGV[1];
    my $k_val = $ARGV[2];
    my $sim_func = $ARGV[3];
    my $sys = $ARGV[4];

    print STDERR "k_val=$k_val\n";
    if($k_val <= 0){
	die "k_val should be >= 0.\n";
    }

    print STDERR "similarity_func=$sim_func\n";
    if(($sim_func <= 0) || ($sim_func > $Cosine_Func)){
	die "sim_func should be between 1 and $Cosine_Func\n";
    }

    open(my $sys_fp, ">$sys") or die "cannot create system output file $sys\n";

    #### step 1: read the instance files
    my %feat2idx = ();
    my %class2idx = ();
    
    my @featnames = ();
    my @classnames = ();
  
    my @training_instlist = ();
    my @test_instlist = ();

    ## Step 1: read the training and test data
    my $add_new = 1;
    my $training_inst_num = read_instances($training_file, \@training_instlist,
					   \%class2idx, \@classnames,
					   \%feat2idx, \@featnames,
					   $add_new);

    $add_new = 0;
    my $test_inst_num = read_instances($test_file, \@test_instlist,
				       \%class2idx, \@classnames,
				       \%feat2idx, \@featnames,
				       $add_new);

    print STDERR "training_inst_num=$training_inst_num test_inst_num=$test_inst_num\n";

    ### print out the class labels
    my $class_num = scalar @classnames;
    my $feat_num = scalar @featnames;
    print STDERR "class_num=$class_num feat_num=$feat_num\n";

    print STDERR "class_labels=", join(" ", @classnames), "\n";


    ######### step 2: testing on the training data
    print STDERR "Start classifying training data ...\n";
    my @train_confusion_matrix = ();
    print $sys_fp "%%%%% training data:\n";
    my $acc = 0;

    print "Confusion matrix for the training data:\n";
    ## print_confusion_matrix(\@classnames, \@train_confusion_matrix);
    print "\n Training accuracy=$acc\n";
    print STDERR "Finish classifying training data\n";

    ######### step 3: testing on the test data
    print STDERR "Start classifying testing data ...\n";

    my @test_confusion_matrix = ();
    print $sys_fp "\n\n%%%%% test data:\n";
    $acc =
	classify_instlist_with_kNN(\@test_instlist, \@training_instlist,
				   $k_val, $sim_func, \@classnames,
				   $sys_fp, \@test_confusion_matrix);

    print "\n\nConfusion matrix for the test data:\n";
    print_confusion_matrix(\@classnames, \@test_confusion_matrix);
    print "\n Test accuracy=$acc\n";
    close($sys_fp);

    print STDERR "Finish classifying testing data\n";
    print STDERR "All done\n";
}



#############################################################################
### matrix[i][j] is the number of instances where the truth is class i and 
###   the system predicts class j.
###
sub print_confusion_matrix {
    my ($classnames_ptr, $matrix) = @_;

    print "row is the truth, column is the system output\n\n";

    my $class_num = scalar @$classnames_ptr;

    print "             ", join(" ", @$classnames_ptr), "\n";

    for(my $i=0; $i<$class_num; $i++){
	my $ptr = $matrix->[$i];
	print $classnames_ptr->[$i], " ", join(" ", @$ptr), "\n";
    }
}


################### classify with DT
### return accuracy
sub classify_instlist_with_kNN {
    my ($instlist, $training_instlist, $k_val, $sim_func, 
	$classnames_ptr, $output_fp, $confusion_matrix_ptr) = @_;

    my $cnt = 0;
    my $corr_cnt = 0;

    ############## initize the confusion matrix
    @$confusion_matrix_ptr = ();
    my $class_num = scalar @$classnames_ptr;

    my @tmp = ();
    for(my $i=0; $i<$class_num; $i++){
	push(@tmp, 0);
    }

    for(my $i=0; $i<$class_num; $i++){
	push(@$confusion_matrix_ptr, [@tmp]);
    }

    ############# classify the instlist
    foreach my $ptr (@$instlist){
	my $true_idx;
	my $sys_idx;
	my $str = 
	    classify_inst_with_kNN($ptr, $training_instlist, $k_val, $sim_func,
				   $classnames_ptr, \$true_idx, \$sys_idx);
	$cnt ++;

	if($true_idx == $sys_idx){
	    $corr_cnt ++;
	}
	my $ptr = $confusion_matrix_ptr->[$true_idx];
	$ptr->[$sys_idx] ++;
	print $output_fp "$str\n";

	print STDERR "Finish $cnt instances, corr_cnt=$corr_cnt\n";
    }

    my $acc = $corr_cnt/$cnt;
    return $acc;
}


#### return the str with the format
####  "instanceName true_class_name c1 p1 c2 p2 ..."
####  p_i is the percentage of k neighbors that vote for c_i.
####
#### choose k neighborest neighbors and let them vote.
####
sub classify_inst_with_kNN {
    my ($inst_ptr, $training_instlist, $k_val, $sim_func, 
	$classnames_ptr, $true_idx_ptr, $sys_idx_ptr) = @_;

    my @inst = @$inst_ptr;
    my $inst_name = $inst[0];
    my $true_class_idx = $inst[1];
    my $true_class_name = $classnames_ptr->[$true_class_idx];

    ##### 1. set the hash that indicates what features are present in the inst
    my %hash = ();  ## A[feat_idx]=feat_val
    my $size = scalar @inst;
    for(my $i=2; $i<$size; $i+=2){
	my $feat_idx = $inst[$i];
	my $feat_val = $inst[$i+1];
	$hash{$feat_idx} = $feat_val;
    }

    ##### 2. calculate the distance between x and all the training data
    my $training_num = scalar @$training_instlist;

    my %res_hash = ();  ## A[inst_idx]=dist(x, inst)
    for(my $i=0; $i<$training_num; $i++){
	my $training_x = $training_instlist->[$i];
	my $sim = calc_similarity($training_x, \%hash, $sim_func);
	$res_hash{$i} = $sim;
    }

    ##### 3. find the k nearest neighbor and let them vote
    my $cnt = 0;
    my %cnt_c = ();
    my $class_num = scalar @$classnames_ptr;
    for(my $i=0; $i<$class_num; $i++){
	$cnt_c{$i} = 0;
    }

    
    print STDERR "kNN:\n";

    foreach my $train_x_idx (sort {$res_hash{$b} <=> $res_hash{$a}}
			     keys %res_hash){
	my $dist = $res_hash{$train_x_idx};
	### choose the k neighborest neighbors
	if($cnt >= $k_val){
	    last;
	}

	my $training_x = $training_instlist->[$train_x_idx];
	my $true_idx = $training_x->[1];
	$cnt_c{$true_idx} ++;
	$cnt ++;
	print STDERR "rank=$cnt inst_idx=$train_x_idx dist=$dist true_idx=$true_idx\n"; 
    }

    ###### 4. print out the results
    my $answer = "";
    my $sys_idx = -1;

    foreach my $c (sort {$cnt_c{$b} <=> $cnt_c{$a}} keys %cnt_c){
	my $cnt = $cnt_c{$c};
	my $prob = $cnt/$k_val;

	my $classname = $classnames_ptr->[$c];
	if($sys_idx < 0){
	    $sys_idx = $c;
	    $answer = "$classname $prob";
	}else{
	    $answer .= " $classname $prob";
	}
    }

    my $str = "$inst_name $true_class_name $answer";

    $$true_idx_ptr = $true_class_idx;
    $$sys_idx_ptr = $sys_idx;

    return $str;
}

####  return the distance between a training instance x1 and x
####  for x, (feat_idx, feat_val) is stored in hash
####  
####  similarity function: 
####   Euclidean distance: sqrt(sum_k (a_{ik} - a_{jk})^2
####   cos(d_i, d_j) = sum_k a_{ik} a_{jk}/sqrt(sum_k a_{ak}^2) Const
####
####  We don't have to calculate the exact function.
####  
#### For the "similarity", the larger the measure is,
####   the similar the two points are.
####
#### Because the Euclidean distance is a distance measure, 
####   we use its negative for the similarity measure.
####
sub calc_similarity {
    my ($inst_x, $hash, $sim_func) = @_;

    my @inst = @$inst_x;
    my $size = scalar @inst;

    my $res = 0;

    if($sim_func == $Cosine_Func){
	my $nom = 0;
	my $denom = 0;  

	for(my $i=2; $i<$size; $i+=2){
	    my $feat_idx = $inst_x->[$i];
	    my $feat_val = $inst_x->[$i+1];
	    my $val = $hash->{$feat_idx};
	    if(defined($val)){
		$nom += $val * $feat_val;
	    }
	    $denom += $feat_val * $feat_val;
	}

	if($denom != 0){
	    $res = $nom/sqrt($denom);
	}else{
	    $res = 0;    # when train_x has no feat, we assume that
                         # the similarity is zero.
	}

	return $res;
    }

    if($sim_func == $Euclidean_Distance_Func){
	my %tmp_hash = ();
	for(my $i=2; $i<$size; $i+=2){
	    my $feat_idx = $inst_x->[$i];
	    my $feat_val = $inst_x->[$i+1];
	    my $val = $hash->{$feat_idx};
	    if(defined($val)){
		$res += ($feat_val - $val) * ($feat_val - $val);
		$tmp_hash{$feat_idx} = 1;
	    }else{
		$res += $feat_val * $feat_val;
	    }
	}

	#### deal with the features that are presented in x, but not in train_x
	foreach my $feat_idx (keys %$hash){
	    if(defined($tmp_hash{$feat_idx})){
		next;
	    }

	    my $val = $hash->{$feat_idx};
	    $res += $val * $val;
	}

	return -$res;
    }

    die "unknown sim_func value $sim_func\n";
}





### return the number of valid instances
sub print_instlist {
    my ($fp, $instlist, $classnames_ptr, $featnames_ptr) = @_;

    my $cnt = 0;

    my $class_num = scalar (@$classnames_ptr);
    my $feat_num = scalar (@$featnames_ptr);

    foreach my $inst_ptr (@$instlist){
	my @inst = @$inst_ptr;
	my $size = scalar (@inst);
	my $instName = $inst[0];
	my $classidx = $inst[1];

	if($classidx < 0 || $classidx >= $class_num){
	    print STDERR "unknown classidx $classidx. The instance is ignored\n";
	    next;
	}

	my $classname = $classnames_ptr->[$classidx];
	my $res = "$instName $classname";

	for(my $i=2; $i<$size; $i+=2){
	    my $featidx = $inst[$i];
	    my $featval = $inst[$i+1];
	    if($featidx < 0  || $featidx >= $feat_num){
		if($debug > 10){
		    print STDERR "unknown featidx $featidx. The feat is ignored.\n";
		}
		
	    }else{
		my $featname = $featnames_ptr->[$featidx];
		$res .= " $featname $featval";
	    }
	}

	print $fp "$res\n";
	$cnt ++;
    }

    print STDERR "finish printing $cnt instances to the file\n";
    return $cnt;
}



### return the number of valid instances
sub read_instances {
    my ($filename, $instList, $class2idx, $classnames_ptr,
	$feat2idx, $featnames_ptr, $add_new) = @_;

    my $valid_cnt = 0;
    my $invalid_cnt = 0;

    open(my $fp, "$filename") or die "cannot open $filename\n";
    
    @$instList = ();
    while(<$fp>){
	chomp;
	if(/^\s*$/){
	    next;
	}

	s/^\s+//;
	s/\s+$//;

	my $line = $_;
	my @inst = ();

	my $res = line_to_inst($line, \@inst, $class2idx, $classnames_ptr,
			       $feat2idx, $featnames_ptr, $add_new);
	if(!$res){
	    print STDERR "line of the wrong format: +$line+\n";
	    $invalid_cnt ++;
	    next;
	}

	push(@$instList, [@inst]);
	$valid_cnt ++;
    }
    
    print STDERR "Finish reading $filename, valid=$valid_cnt, invalid=$invalid_cnt\n";
    
    my $class_num = scalar (keys %$class2idx);
    my $feat_num = scalar (keys %$feat2idx);

    print "class_num=$class_num feat_num=$feat_num\n";
    return $valid_cnt;
}

### return suc
### store both feat_idx and feat_val for each feature.
###
sub line_to_inst {
    my ($line, $inst, $class2idx, $classnames_ptr, 
	$feat2idx, $featnames_ptr, $add_new) = @_;

    my @parts = split(/\s+/, $line);

    my $part_num = scalar @parts;

    if($part_num < 2 || $part_num % 2 != 0){
	return 0;
    }

    @$inst = ();
    my $class_num = scalar (keys %$class2idx);
    my $feat_num = scalar (keys %$feat2idx);

    ### push instanceName
    push(@$inst, $parts[0]);
    
    ### push classLabel
    my $class_label = $parts[1];
    my $class_idx = $class2idx->{$class_label};
    if(defined($class_idx)){
	push(@$inst, $class_idx);
    }else{
	if($add_new){
	    $class2idx->{$class_label} = $class_num;
	    push(@$inst, $class_num);
	    push(@$classnames_ptr, $class_label);
	    $class_num ++;
	}else{
	    print STDERR "class_label $class_label is not defined\n";
	    return 0;
	}
    }

    #### deal with features
    for(my $i=2; $i<$part_num; $i+=2){
	my $featname = $parts[$i];
	my $featval = $parts[$i+1];
	
	if($featval == 0){
	    next;
	}

	my $feat_idx = $feat2idx->{$featname};
	if(defined($feat_idx)){
	    push(@$inst, $feat_idx);
	    push(@$inst, $featval);
	}else{
	    if($add_new){
		$feat2idx->{$featname} = $feat_num;
		push(@$inst, $feat_num);
		push(@$inst, $featval);

		push(@$featnames_ptr, $featname);
		$feat_num ++;
	    }else{
		if($debug > 10){
		    print STDERR "featname $featname is new and the feat is ignored\n";
		}
		next;
	    }
	}
    }

    return 1;
}



