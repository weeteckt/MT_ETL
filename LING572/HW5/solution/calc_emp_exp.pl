#!/usr/bin/env perl


## created on 2/11/09
## modified from 194/e/maxent_train.pl

## Purpose: calculate empirical expectation 

## to run:
##    $0 training_data output


## The format of the training data is:
##  instanceName label f1 v1 f2 v2 ....
##

## The format the output is:
##  class_label featname expectation
##  ...
##


############ options
my $debug = 0;

############ constants
use strict;

main();

1;


#########################
sub main {
    my $cnt = 0;
    
    my $arg_num = @ARGV;

    ##### step 1: read parameters
    if($arg_num != 2){
	die "Usage: $0 training_data output\n";
    }

    my $training_file = $ARGV[0];
    my $output_file = $ARGV[1];

    open(my $output_fp, ">$output_file") or die "cannot create $output_file\n";

    #### step 2: read the training data
    my %feat2idx = ();
    my %class2idx = ();
    
    my @featnames = ();
    my @classnames = ();
  
    my @train_instlist = ();

    my $class_num = 0;
    my $feat_num = 0;


    my $add_new = 1;
    my $train_inst_num = read_instances($training_file, \@train_instlist,
					\%class2idx, \@classnames,
					\%feat2idx, \@featnames,
					$add_new);
    print STDERR "reading $train_inst_num instances from $training_file\n";
    $class_num = scalar @classnames;
    $feat_num = scalar @featnames;

    print STDERR "class_num=$class_num feat_num=$feat_num\n";
    print STDERR "class_labels=", join(" ", @classnames), "\n";

    ##### step 3: calc empirical expectation
    my @observ_expect = ();
    init_array_with_zeros(\@observ_expect, $class_num * $feat_num);

    my $C = 0;
    compute_observ_expectation(\@train_instlist, $class_num, $feat_num,
			       \@observ_expect, \$C);

    print STDERR "C=$C  i.e., max sum_i f_i(x)\n";

    ####### step 4: print out expectation
    print_expectation($output_fp, \@observ_expect, \@classnames,
		      \@featnames, $train_inst_num);
    close($output_fp);

    print STDERR "All done\n";
}


#########################################################################
sub print_expectation {
    my ($output_fp, $expect_ptr, $class_names, $feat_names, $inst_num) = @_;

    my $class_num = scalar @$class_names;
    my $feat_num = scalar @$feat_names;

    for(my $c=0; $c<$class_num; $c++){
	my $classname = $class_names->[$c];
	my $base = $c * $feat_num;
	for(my $f=0; $f<$feat_num; $f++){
	    my $featname = $feat_names->[$f];
	    my $expt = $expect_ptr->[$base + $f];
	    my $t1 = $expt/$inst_num;
	    print $output_fp "$classname $featname $t1 $expt\n";
	}
    }
}


## calculate the observed expectation 
## (i.e., the expected value of f_j w.r.t. the empirical distribution)
##
## observ_expect(f_j) = 1/N sum_i f_j (x_i, y_i)
## N is the number of training data
## We skip 1/N as it also used in model_expectation
## 
## $$C_ptr = max sum_j f_j(x,y).
##
## Remember that f_j in MaxEnt corresponds to a (feat, class) pair in NB.
##
sub compute_observ_expectation {
    my ($train_instlist, $class_num, $feat_num, 
	$observ_expect, $C_ptr) = @_;

    print STDERR "Start computing observation expectation ...\n";

    my $C = 0;  # max_i sum_j f_j (x_i, y_i)

    my $cnt = 0;
    foreach my $inst_ptr (@$train_instlist){
	### go through each training instance
	my $true_class_idx = $inst_ptr->[1];
	my $base = $true_class_idx * $feat_num;

	my $cur_C = 0;
	my $size = scalar @$inst_ptr;
	for(my $i=2; $i<$size; $i+=2){
	    ## go through each feature
	    my $feat_idx = $inst_ptr->[$i];
	    my $feat_val = $inst_ptr->[$i+1];
	    $cur_C += $feat_val;

	    $observ_expect->[$base + $feat_idx] += $feat_val;
	}

	if($cur_C > $C){
	    $C = $cur_C;
	}

	$cnt ++;
	if($cnt % 1000 == 0){
	    print STDERR " Finish ", $cnt/1000, "K instances\n";
	}
    }

    $$C_ptr = $C;

    if($debug){
	print STDERR "Observed expectation: C=$C\n";
	for(my $j=0; $j < $class_num * $feat_num; $j++){
	    my $t = $observ_expect->[$j];
	    print STDERR "feature j=$j observ_freq=$t\n";
	}
    }

    print STDERR "Finish computing observation expectation\n\n";
}

### push n zeros to the array
sub init_array_with_zeros {
    my ($array_ptr, $n) = @_;

    @$array_ptr = ();
    for(my $i=0; $i<$n; $i++){
	push(@$array_ptr, 0);
    }
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



