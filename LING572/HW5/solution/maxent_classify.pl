#!/usr/bin/env perl


## created on 1/27/08

## Purpose: classify test data using a MaxEnt model

## to run:
##    $0 test_data input_model test_raw > acc


## The format of the test data is:
##  instanceName label f1 v1 f2 v2 ....
##

## The input_model has the format: (the same as the Mallet format)
##  FEATURES FOR CLASS classname
##  <default> weight
##  featname  weight
##  ...


## test_raw has the format
##   instanceName label c1 logp(x,c1) c2 logp(x,c2) ...
##
## where label1 is the true label, (c_i, p_i) is sorted according to the p_i.

## stdout shows the confusion matrix and training and test accuracy

use Class::Struct;

struct( MaxEnt_model => {
    class_num => '$',     # the number of classes
    feat_num  => '$',     # the number of features excluding default_feat

    feat_weight => '@',   # A[c_i*feat_num+f_k] is weight for (c_i, f_k)

    default_feat_weight => '@' # default feature weight for class c_i
    }
);


############ options
my $debug = 0;

############ constants
my $default_feat_name = "<default>";  # the default_feat_name in the model file
my $EXP_BASE = 2.71828182845904523536;


use strict;

main();

1;


#########################
sub main {
    my $cnt = 0;
    
    my $arg_num = @ARGV;
    
    if($arg_num != 3){
	die "Usage: $0 test_data input_model test_raw > acc_file\n";
    }

    my $test_file = $ARGV[0];
    my $model = $ARGV[1];
    my $sys = $ARGV[2];

    open(my $test_fp, "$test_file") 
	or die "cannot open test file $test_file\n";
    open(my $model_fp, "$model") or die "cannot open model file $model\n";
    open(my $sys_fp, ">$sys") or die "cannot create system output file $sys\n";

    #### step 1: read the model
    my %feat2idx = ();
    my %class2idx = ();
    
    my @featnames = ();
    my @classnames = ();
  
    my $model = new MaxEnt_model;

    my $suc = read_model($model_fp, $model, \%class2idx, \@classnames,
			 \%feat2idx, \@featnames);

    ##### step 2: print out classnames, etc.

    ### print out the class labels
    my $class_num = scalar @classnames;
    my $feat_num = scalar @featnames;
    print STDERR "class_num=$class_num feat_num=$feat_num\n";

    print STDERR "class_labels=", join(" ", @classnames), "\n";

    ###### step 3: read the test data
    my @test_instlist = ();
    my $add_new = 0;
    my $test_inst_num = read_instances($test_file, \@test_instlist,
				       \%class2idx, \@classnames,
				       \%feat2idx, \@featnames,
				       $add_new);

    print STDERR "test_inst_num=$test_inst_num\n";


    ######### step 4: testing on the test data
    print STDERR "Start classifying testing data ...\n";

    my @test_confusion_matrix = ();
    print $sys_fp "\n\n%%%%% test data:\n";
    my $acc =
	classify_instlist_with_ME(\@test_instlist, $model, \@classnames,
				  $sys_fp, \@test_confusion_matrix);

    print "\n\nConfusion matrix for the test data:\n";
    print_confusion_matrix(\@classnames, \@test_confusion_matrix);
    print "\n Test accuracy=$acc\n";
    close($sys_fp);

    print STDERR "Finish classifying testing data\n";

    ####### step 5: print the model
    if($debug){
	open(my $out_fp, ">$sys.model") or die "cannot open $sys.model\n";
	print_model($out_fp, $model, \@classnames, \@featnames);
	close($out_fp);
    }

    print STDERR "All done\n";
}


#########################################################################
sub print_model {
    my ($fp, $model, $classnames_ptr, $featnames_ptr) = @_;

    my $class_num = scalar @$classnames_ptr;
    my $feat_num = scalar @$featnames_ptr;

    for(my $c=0; $c<$class_num; $c++){
	my $classname = $classnames_ptr->[$c];
	my $default_weight = $model->default_feat_weight->[$c];

	print $fp "FEATURES FOR CLASS $classname\n";
	print $fp " $default_feat_name $default_weight\n";

	my $base = $c * $feat_num;
	for(my $f=0; $f<$feat_num; $f++){
	    my $featname = $featnames_ptr->[$f];
	    my $weight = $model->feat_weight->[$base + $f];
	    print $fp " $featname $weight\n";
	}
    }

}

sub read_model {
    my ($fp, $model, $class2idx_ptr, $classnames_ptr, 
	$feat2idx_ptr, $featnames_ptr) = @_;

    ####### init
    my $total_cnt = 0;
    my $valid_cnt = 0;

    %$class2idx_ptr = ();
    @$classnames_ptr = ();

    %$feat2idx_ptr = ();
    @$featnames_ptr = ();

    my $class_num = 0;
    my $feat_num = 0;

    $model->feat_weight('()');
    my $feat_weight_ptr = $model->feat_weight;

    $model->default_feat_weight('()');
    my $default_feat_weight_ptr = $model->default_feat_weight;
    
    my $cur_class_idx = -1;
    my $cur_base = 0;
    my $cur_classname = "";

    ############ process each line
    my $undefined = "";
    my $tmp_feat_num = 0; ## count the number of feat for other classes
    while(<$fp>){
	chomp;
	if(/^\s*$/){
	    next;
	}

	s/^\s+//;
	s/\s+$//;

	$total_cnt = 0;

	my $line = $_;

	my @parts = split(/\s+/, $line);
	my $part_num = scalar @parts;
	
	if($part_num != 2 && $part_num != 4){
	    print STDERR "wrong format: +$line+\n";
	    next;
	}

	#### class line
	if($part_num == 4){
	    if($line =~ /^FEATURES\s+FOR\s+CLASS\s+(.+)$/i){
		my $classname = $1;
		my $class_idx = $class2idx_ptr->{$classname};
		if(defined($class_idx)){
		    die "class $classname has been defined already\n";
		}
		push(@$classnames_ptr, $classname);
		$class2idx_ptr->{$classname} = $class_num;
		if($class_num != 0){
		    ### not the first class, reserve the place in the array
		    for(my $i=0; $i<$feat_num; $i++){
			push(@$feat_weight_ptr, $undefined);
		    }
		    $cur_base += $feat_num;
		    if(($class_num > 1) && ($feat_num != $tmp_feat_num)){
			die "$cur_classname has $tmp_feat_num, != $feat_num\n";
		    }
		    $tmp_feat_num = 0;
		}
		push(@$default_feat_weight_ptr, $undefined);
		$cur_classname = $classname;
		$cur_class_idx = $class_num;

		$class_num ++;
		$valid_cnt ++;
	    }else{
		print STDERR "wrong format: +$line+\n";
	    }
	    next;
	}

	### part_num = 2
	my $featname = $parts[0];
	my $weight = $parts[1];

	if($featname eq $default_feat_name){
	    $default_feat_weight_ptr->[$cur_class_idx] = $weight;
	    next;
	}

	my $feat_idx = $feat2idx_ptr->{$featname};
	if($cur_class_idx == 0){
	    #### the first class
	    if(defined($feat_idx)){
		print STDERR "warning: $featname in the first class has been defined already\n";
	    }else{
		### add the feature name
		$feat2idx_ptr->{$featname} = $feat_num;
		$feat_idx = $feat_num;
		$feat_num ++;
		push(@$featnames_ptr, $featname);
		push(@$feat_weight_ptr, $weight);
	    }
	}else{
	    ### not the first class
	    if(defined($feat_idx)){
		my $val = $feat_weight_ptr->[$cur_base + $feat_idx];
		if($val ne $undefined){
		    print STDERR "warning: $featname in $cur_classname has been defined before, with weight $val\n";
		}else{
		    $feat_weight_ptr->[$cur_base + $feat_idx] = $weight;
		    $tmp_feat_num ++;
		} 
	    }else{
		print STDERR "warning: $featname in $cur_classname is not defined before\n";
	    }
	}
    }

    $model->class_num($class_num);
    $model->feat_num($feat_num);
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
sub classify_instlist_with_ME {
    my ($instlist, $model, $classnames_ptr, 
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
	    classify_inst_with_ME($ptr, $model, $classnames_ptr, 
				  \$true_idx, \$sys_idx);
	if($true_idx == $sys_idx){
	    $corr_cnt ++;
	}
	my $ptr = $confusion_matrix_ptr->[$true_idx];
	$ptr->[$sys_idx] ++;
	print $output_fp "$str\n";

	$cnt ++;
	if($cnt % 1000 == 0){
	    print STDERR " Finish classifying ", $cnt/1000, "K instances\n";
	}
    }

    my $acc = 0;
    if($cnt > 0){
       $acc = $corr_cnt/$cnt;
    }
    return $acc;
}



#### return the str with the format
####  "instanceName true_class_name c1 logp(x,c1) c2 logp(x,c2) ..."
#### 
#### choose the c that maximizes 
####  log P(x|c) = default(c) + sum_i weight_i f_i(x,c)
####
sub classify_inst_with_ME {
    my ($inst_ptr, $model, $classnames_ptr, 
	$true_idx_ptr, $sys_idx_ptr) = @_;

    my @inst = @$inst_ptr;
    my $inst_name = $inst[0];
    my $true_class_idx = $inst[1];
    my $true_class_name = $classnames_ptr->[$true_class_idx];

    my $size = scalar @inst;
    my $tmp_feat_num = $size/2 - 1;

    ##### check each class
    my $class_num = $model->class_num;
    my $feat_num = $model->feat_num;

    my %res_hash = ();
    my $norm = 0;  # the normalizer: sum_i P(x, c_i)
    my $feat_weight_ptr = $model->feat_weight;

    for(my $c=0; $c<$class_num; $c++){
	my $res = $model->default_feat_weight->[$c];
	my $base = $c * $feat_num;
	my $pos = 2;
	for(my $f=0; $f<$tmp_feat_num; $f++){
	    my $feat_idx = $inst[$pos];
	    my $feat_val = $inst[$pos+1];
	    $pos += 2;
	    
	    my $lambda = $feat_weight_ptr->[$base+$feat_idx];
	    $res += $lambda * $feat_val;
	}
	
	$res_hash{$c} = $res;
    }

    #### get the answer: val=P(x,c)/sum_c P(x,c)
    ####   Need to do it cleverly as P(x,c) can be very small.
    ####   So we increase log P(x,c) first by the max of log P(x,c).
    my $answer = "";
    my $sys_idx = -1;

    my $max_logprob = 0;
    my $sum = 0;
    foreach my $c (sort {$res_hash{$b} <=> $res_hash{$a}} keys %res_hash){
	my $logprob = $res_hash{$c};

	my $val = 1;
	if($sys_idx < 0){
	    $max_logprob = $logprob;
	    $sys_idx = $c;
	}else{
	    $val = $EXP_BASE ** ($logprob - $max_logprob);
	}
	$sum += $val;
	$res_hash{$c} = $val;
    }


    foreach my $c (sort {$res_hash{$b} <=> $res_hash{$a}} keys %res_hash){
	my $val = $res_hash{$c};
	my $classname = $classnames_ptr->[$c];
	my $prob = $val/$sum;
	if($val == 1){
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


### return the number of valid instances
### store featname and featvalue
###
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
	    print STDERR "Error: class_label $class_label is not defined\n The instance is ignored\n";
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



