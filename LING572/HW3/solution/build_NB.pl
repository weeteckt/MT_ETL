#!/usr/bin/env perl


## created on 1/14/08

## Purpose: build NB learner (Bernoulli event model)
##   i.e., treat each feature as binary    

## to run:
##    $0 training_data test_data add_delta model test_raw 

## the format of the training and testing data is:
##  instanceName label f1 v1 f2 v2 ....
##
## We treat all the features as binary; that is, only feat whose value is 
##   non-zero will be kept, and the exact feature values are ignored.

## model has the format
##  f_j c_i P(f_j | c_i)
##  where f_j is a feature, c_i is a class label

## test_raw has the format
##   instanceName label c1 logp(x,c1) c2 logp(x,c2) ...
##
## where label1 is the true label, (c_i, p_i) is sorted according to the p_i.

## stdout shows the confusion matrix and training and test accuracy

use Class::Struct;

struct( NB_model => {
    class_num => '$',          # the number of classes
    feat_num  => '$',          # the number of features

    training_instance_num => '$',   # the num of training instances
    class_delta => '$',        # the delta for calc p(c)
    feat_class_delta => '$',   # the delta for calc p(f|c)

    prior => '@',              # prior[i] is P(c_i) 
    log_prior => '@',          # A[i] is log_10 P(c_i)

    condition_prob => '@',     # A[c_i*feat_num+f_k]=P(f_k | c_i)
    log_condition_prob => '@', # A[c_i*feat_num+f_k]=log_10 P(f_k | c_i)
    log_condition_prob2 => '@', # A[c_i*feat_num+f_k]=log_10 (1 - P(f_k | c_i))

     
    sum_of_log_condition_prob2 => '@' # func(c_i) = sum log10 (1-P(f_k|c_i)) 
    }
);


############ options
my $debug = 0;
my $output_all_prob = 1;

############ constants
my $log10 = log(10);
my $LOG_ZERO = -10000;

use strict;

main();

1;


#########################
sub main {
    my $cnt = 0;
    
    my $arg_num = @ARGV;
    
    if($arg_num != 6){
	die "Build Bernoulli NB model and classify training and test data\n usage: $0 training_data test_data class_delta feat_class_delta model test_raw > acc_file\n";
    }

    my $training_file = $ARGV[0];
    my $test_file = $ARGV[1];
    my $class_delta = $ARGV[2];
    my $feat_class_delta = $ARGV[3];
    my $model = $ARGV[4];
    my $sys = $ARGV[5];

    if($feat_class_delta < 0){
	die "The add_delta should be >= 0.\n";
    }

    print STDERR "class_delta=$class_delta\n";
    print STDERR "feat_class_delta=$feat_class_delta\n";

    open(my $model_fp, ">$model") or die "cannot create model file $model\n";
    open(my $sys_fp, ">$sys") or die "cannot create system output file $sys\n";

    #### step 1: read the instance files
    my %feat2idx = ();
    my %class2idx = ();
    
    my @featnames = ();
    my @classnames = ();
  
    my @training_instlist = ();
    my @test_instlist = ();

    ## 1(a): read the training data
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

    ######## step 2: training stage: build NB model
    my $model = new NB_model;

    my $suc = 
	build_NB(\@training_instlist, $class_num, \@classnames,
		 $feat_num, \@featnames, $class_delta, $feat_class_delta,
		 $model);

    print STDERR "Finish building the NB model.\n";


    ########## step 3: print DT
    print STDERR "Start printing NB model ...\n";
    print_NB_model($model_fp, $model, $class_num, $feat_num, 
		   \@classnames, \@featnames);

    close($model_fp);
    print STDERR "Finish printing NB model\n";

    print STDERR "prior and sum\n";
    for(my $c=0; $c<$class_num; $c++){
	my $classname = $classnames[$c];
	my $sum = $model->sum_of_log_condition_prob2->[$c];
	my $prior = $model->prior->[$c];
	my $log_prior = $model->log_prior->[$c];
	print STDERR "$classname\tprior=$prior\tlog_prior=$log_prior\tsum=$sum\n";
    }

    ######### step 4: testing on the training data
    print STDERR "Start classifying training data ...\n";
    my @train_confusion_matrix = ();
    print $sys_fp "%%%%% training data:\n";
    my $acc 
	= classify_instlist_with_NB(\@training_instlist, $model,
				    \@classnames,\@featnames,
				    $sys_fp, \@train_confusion_matrix);

    print "Confusion matrix for the training data:\n";
    print_confusion_matrix(\@classnames, \@train_confusion_matrix);
    print "\n Training accuracy=$acc\n";
    print STDERR "Finish classifying training data\n";

    ######### step 4: testing on the test data
    print STDERR "Start classifying testing data ...\n";

    my @test_confusion_matrix = ();
    print $sys_fp "\n\n%%%%% test data:\n";
    $acc =
	classify_instlist_with_NB(\@test_instlist, $model,
				  \@classnames, \@featnames,
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
sub classify_instlist_with_NB {
    my ($instlist, $model, $classnames_ptr, $featnames_ptr,
	$output_fp, $confusion_matrix_ptr) = @_;

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
	    classify_inst_with_NB($ptr, $model, 
				  $classnames_ptr, $featnames_ptr,
				  \$true_idx, \$sys_idx);
	$cnt ++;
	if($true_idx == $sys_idx){
	    $corr_cnt ++;
	}
	my $ptr = $confusion_matrix_ptr->[$true_idx];
	$ptr->[$sys_idx] ++;
	print $output_fp "$str\n";
    }

    my $acc = $corr_cnt/$cnt;
    return $acc;
}


#### return the str with the format
####  "instanceName true_class_name c1 logp(x,c1) c2 logp(x,c2) ..."
#### 
#### choose the c that maximizes P(x,c) = P(c) P(x|c)
#### = log P(c) \prod_{k is present} P(w_k|c) [\prod_{k is absent} (1-P(w_k|c))
#### = log p(c) + \sum_{k is present} log p(w_k|c) + 
####              \sum_{k is absent} log (1-P(w_k|c))
#### = log P(c) + \sum_{k is present}(log P(w_k |c) - log (1-P(w_k|c))) + const
####
sub classify_inst_with_NB {
    my ($inst_ptr, $model, $classnames_ptr, $featnames_ptr,
	$true_idx_ptr, $sys_idx_ptr) = @_;

    my @inst = @$inst_ptr;
    my $inst_name = $inst[0];
    my $true_class_idx = $inst[1];
    my $true_class_name = $classnames_ptr->[$true_class_idx];

    my $size = scalar @inst;

    ##### check each class
    my $class_num = $model->class_num;
    my $feat_num = $model->feat_num;

    my %res_hash = ();
    my $str = " ";

    for(my $c=0; $c<$class_num; $c++){
	my $res = $model->log_prior->[$c];
	$res += $model->sum_of_log_condition_prob2->[$c];

	my $log_prob1 = $model->log_condition_prob;
	my $log_prob2 = $model->log_condition_prob2;
	
	my $base = $c * $feat_num;
	for(my $i=2; $i<$size; $i++){
	    my $f = $inst[$i];
	    if($debug > 0){
		my $t1 = $log_prob1->[$base+$f];
		my $t2 = $log_prob2->[$base+$f];
		my $featname = $featnames_ptr->[$f];
		$str .= " $f $featname +$t1 -$t2\n";
	    }
	    $res += $log_prob1->[$base+$f];
	    $res -= $log_prob2->[$base+$f];
	}
	
	$res_hash{$c} = $res;
    }

    #### get the answer
    my $answer = "";
    my $sys_idx = -1;

    my $max_logprob = 0;
    my $sum = 0;

    foreach my $c (sort {$res_hash{$b} <=> $res_hash{$a}} keys %res_hash){
	my $logprob = $res_hash{$c};
	
	my $classname = $classnames_ptr->[$c];
	$answer .= " $classname $logprob";

	my $val = 1;
	if($sys_idx < 0){
	    $max_logprob = $logprob;
	    $sys_idx = $c;
	}else{
	    $val = 10 ** ($logprob - $max_logprob);
	}
	$sum += $val;
	$res_hash{$c} = $val;
    }

    foreach my $c (sort {$res_hash{$b} <=> $res_hash{$a}} keys %res_hash){
	my $val = $res_hash{$c};
	my $classname = $classnames_ptr->[$c];
	my $prob = $val/$sum;
	if($val == 1){
	    $answer .= " $classname $prob";
	}else{
	    $answer .= " $classname $prob";
	}
    }

    $str .= "$inst_name $true_class_name $answer";

    $$true_idx_ptr = $true_class_idx;
    $$sys_idx_ptr = $sys_idx;

    return $str;
}


################### print the NB model
sub print_NB_model {
    my ($fp, $model, $class_num, $feat_num, 
	$classnames_ptr, $featnames_ptr) = @_;

    print $fp "%%%%% prior prob P(c) %%%%%\n";
    my $prior = $model->prior;
    my $log_prior = $model->log_prior;
    
    for(my $c=0; $c<$class_num; $c++){
	my $classname = $classnames_ptr->[$c];
	my $prob = $prior->[$c];
	my $logprob = $log_prior->[$c];
	print $fp "$classname\t$prob\t$logprob\n";
    }

    print $fp "%%%%% conditional prob P(f|c) %%%%%\n";
    for(my $c=0; $c<$class_num; $c++){
	my $ptr = $model->condition_prob;
	my $log_ptr = $model->log_condition_prob;
	my $classname = $classnames_ptr->[$c];
	print $fp "%%%%% conditional prob P(f|c) c=$classname %%%%%\n";
	
	my $base = $c * $feat_num;
	for(my $f=0; $f<$feat_num; $f++){
	    my $featname = $featnames_ptr->[$f];
	    my $prob = $ptr->[$base + $f];
	    my $logprob = $log_ptr->[$base + $f];
	    print $fp "$featname\t$classname\t$prob\t$logprob\n"; 
	}
    }
}


### P(c) = (\delta + cnt(C))/(|C|*\delta + N), N is the num of instlist
### P(f|c) = (1 + cnt(f,c))/(2 + cnt(c))
###
sub build_NB {
    my ($instlist, $class_num, $classnames_ptr, $feat_num, $featnames_ptr, 
	$class_delta, $feat_class_delta, $model) = @_;

    my $training_inst_num = scalar @$instlist;  ## N

    ############## set some values
    $model->class_num($class_num);
    $model->feat_num($feat_num);
    $model->training_instance_num($training_inst_num);
    $model->class_delta($class_delta);
    $model->feat_class_delta($feat_class_delta);


    ############## initialize the count arrays
    my @cnt_c = ();
    my @cnt_f_c = (); # $cnt_f_c[c][f] stores cnt(f,c)

    for(my $c=0; $c<$class_num; $c++){
	push(@cnt_c, 0);
	for(my $f=0; $f<$feat_num; $f++){
	    push(@cnt_f_c, 0);
	}
    }

    ############# count cnt(c) and cnt(f,c)
    foreach my $ptr (@$instlist){
	my @inst = @$ptr;
	my $c = $inst[1];   ## true_class_idex
	$cnt_c[$c] ++;

	my $size = scalar @inst;
	my $base = $c * $feat_num;
	for(my $i=2; $i<$size; $i++){
	    my $feat_idx = $inst[$i];
	    $cnt_f_c[$base + $feat_idx] ++;
	}
    }
    
    ############## calculate the prior P(c)
    $model->prior('()');
    my $prior_ptr = $model->prior;

    $model->log_prior('()');
    my $log_prior_ptr = $model->log_prior;

    for(my $c=0; $c<$class_num; $c++){
	my $p = ($class_delta + $cnt_c[$c])/
	    ($class_num*$class_delta + $training_inst_num);
	my $logprob = log($p)/$log10;

	push(@$prior_ptr, $p);
	push(@$log_prior_ptr, $logprob);
    }

    
    ############## calculate the conditional prob P(f|c)
    $model->condition_prob('()');
    my $prob_ptr = $model->condition_prob;

    $model->log_condition_prob('()');
    my $log_prob_ptr = $model->log_condition_prob;

    $model->log_condition_prob2('()');
    my $log_prob_ptr2 = $model->log_condition_prob2;

    $model->sum_of_log_condition_prob2('()');
    my $sum_logprob2_ptr = $model->sum_of_log_condition_prob2;

    for(my $c=0; $c<$class_num; $c++){
	my $base = $c * $feat_num;
	my $c_c = $cnt_c[$c] + 2*$feat_class_delta;
	my $sum_prob2 = 0;

	for(my $f=0; $f<$feat_num; $f++){
	    my $c_fc = $cnt_f_c[$base+$f];
	    my $p = ($feat_class_delta + $c_fc)/$c_c;
	    my $logprob = $LOG_ZERO;
            my $logprob2 = $LOG_ZERO;

            if($p>0){
               $logprob = log($p)/$log10;
            }

            if($p < 1){
	       $logprob2 = log(1-$p)/$log10;
            }

	    push(@$prob_ptr, $p);
	    push(@$log_prob_ptr, $logprob);
	    push(@$log_prob_ptr2, $logprob2);
	    $sum_prob2 += $logprob2;
	}
	push(@$sum_logprob2_ptr, $sum_prob2);
    }
    

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

	for(my $i=2; $i<$size; $i++){
	    my $featidx = $inst[$i];
	    if($featidx < 0  || $featidx >= $feat_num){
		if($debug > 10){
		    print STDERR "unknown featidx $featidx. The feat is ignored.\n";
		}
		
	    }else{
		my $featname = $featnames_ptr->[$featidx];
		$res .= " $featname";
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
	}else{
	    if($add_new){
		$feat2idx->{$featname} = $feat_num;
		push(@$inst, $feat_num);
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



