#!/usr/bin/env perl


## created on 2/11/09 
## modified from 194/e/maxent_train.pl

## Purpose: calc model expectation

## to run:
##    $0 training_data output_file {model_file}


## The format of the training data is:
##  instanceName label f1 v1 f2 v2 ....
##
## The format of the output file is
##   class_label feat_name expectation

## The model_file has the format: (the same as the Mallet format)
##  FEATURES FOR CLASS classname
##  <default> default_weight
##  featname  weight
##  ...
##


############ options
my $debug = 0;

############ constants
my $default_feat_name = "<default>";
my $EXP_BASE = 2.71828182845904523536;
my $LOG_ZERO = -10000;   # log 0

use strict;

use Class::Struct;

struct( MaxEnt_model => {
    class_num => '$',     # the number of classes
    feat_num  => '$',     # the number of features excluding default_feat

    feat_weight => '@',   # A[c_i*feat_num+f_k] is weight for (c_i, f_k)

    default_feat_weight => '@' # default feature weight for class c_i
    }
);



main();

1;


#########################
sub main {
    my $cnt = 0;
    
    my $arg_num = @ARGV;

    ##### step 0: read parameters
    if(($arg_num < 2) || ($arg_num > 3)){
	die "Usage: $0 training_data output_file {model_file}\n";
    }

    my $training_file = $ARGV[0];
    my $output_file = $ARGV[1];

    open(my $output_fp, ">$output_file") or die "cannot create $output_file\n";

    ##### step 1: read model
    my $model_exist = 0;
    my $add_new = 1;
    
    my $model = new MaxEnt_model;
    my %feat2idx = ();
    my %class2idx = ();
    
    my @featnames = ();
    my @classnames = ();

    if($arg_num == 3){
	my $model_file = $ARGV[2];
	open(my $model_fp, "$model_file") or 
	    die "cannot open $model_file\n";


	my $suc = read_model($model_fp, $model, \%class2idx, \@classnames,
			     \%feat2idx, \@featnames);
	if($suc){
	    print STDERR "Finish reading the model\n";
	}else{
	    die "wrong model!\n";
	}
	$add_new = 0;
	$model_exist = 1;
    }

    
    #### step 2: read the training data
    my @train_instlist = ();

    my $train_inst_num = read_instances($training_file, \@train_instlist,
					\%class2idx, \@classnames,
					\%feat2idx, \@featnames,
					$add_new);
    my $class_num = scalar @classnames;
    my $feat_num = scalar @featnames;

    print STDERR "class_num=$class_num feat_num=$feat_num\n";
    print STDERR "class_labels=", join(" ", @classnames), "\n";

    ##### step 3: calc model expectation
    my @model_expect = ();  # store model_expectation(f_i)
    init_array_with_zeros(\@model_expect, $class_num * $feat_num);

    my $correct_cnt = 0;

    my $cur_LL =
	compute_model_expectation(\@train_instlist, $class_num, $feat_num,
				  $model_exist, $model, \@model_expect,
				  \$correct_cnt);

    my $acc = $correct_cnt/$train_inst_num;

    print STDERR "correct=$correct_cnt, acc=$acc\n";

    ####### step 4: print out expectation
    print_expectation($output_fp, \@model_expect, \@classnames,
		      \@featnames, $train_inst_num);
    close($output_fp);

    print STDERR "All done\n";
}



#### classify an instance and return the index of the best class
### modified from classify_inst_with_ME() in maxent_classify.pl
###
### The space for dist_ptr has been allocated before the function call.
###
### The function sets $dist_ptr and return the system_class_idx
###
sub classify_inst {
    my ($inst_ptr, $class_num, $feat_num, $model,
	$dist_ptr) = @_;

    my $size = scalar @$inst_ptr;

    my @vals = ();
    my $max_logprob = 0;  ## it is max_c(\lambda(c) + \sum_j \lambda_j f_j)
    my $sys_idx = -1;
    my $feat_weight_ptr = $model->feat_weight;

    #### calc sum_i \lambda_i f_i(x,y)
    for(my $c=0; $c<$class_num; $c++){
	my $res = $model->default_feat_weight->[$c];
	my $base = $c * $feat_num;

	for(my $i=2; $i<$size; $i+=2){
	    my $feat_idx = $inst_ptr->[$i];
	    my $feat_val = $inst_ptr->[$i+1];
	    my $lambda = $feat_weight_ptr->[$base+$feat_idx];
	    $res += $lambda * $feat_val;
	}
	push(@vals, $res);
	if($max_logprob == 0 || $max_logprob < $res){
	    $max_logprob = $res;
	    $sys_idx = $c;
	}
    }

    ##### calc the normalizer Z
    my $sum = 0;
    for(my $c=0; $c<$class_num; $c++){
	my $new_val = $EXP_BASE ** ($vals[$c] - $max_logprob);
	$vals[$c] = $new_val;
	$sum += $new_val;
    }

    #### get the prob P(y|x)
    for(my $c=0; $c<$class_num; $c++){
	$dist_ptr->[$c] = $vals[$c]/$sum;
    }
    
    return $sys_idx;
}


### calc the model expectation
###  model_expect(f_j) = 1/N \sum_i P(y|x_i) f_j (x_i, y)
###
###  We ignore 1/N, as we ignore 1/N when calculating observ_expect(f_j)
###  The model_expect() has been initialized before the function call.
### 
### return the log_LL of the data
###   log_LL = sum_i log P(y_i | x_i)
###
sub compute_model_expectation {
   my ($train_instlist, $class_num, $feat_num, $model_exist,
       $model, $model_expect, $correct_cnt_ptr) = @_; 

   print STDERR "Start: compute_model_expectation\n";

   my $log_LL = 0;

   #### init p(y|x)
   my @p_dist = ();  # p(y|x)
   my $default_prob = 1/$class_num;
   for(my $i=0; $i<$class_num; $i++){
       push(@p_dist, $default_prob);
   }

   my $correct_cnt = 0;
   my $total_cnt = 0;

   foreach my $inst_ptr (@$train_instlist){
       ### go through each instance
       my $true_class_idx = $inst_ptr->[1];
       
       my $sys_class_idx = 0;

       if($model_exist){
	   $sys_class_idx = classify_inst($inst_ptr, $class_num, $feat_num,
					  $model, \@p_dist);
       }

       if($debug){
	   my $str = $inst_ptr->[0] . " " . $inst_ptr->[1];
	   for(my $i=0; $i<scalar @p_dist; $i++){
	       $str .= " $i " . $p_dist[$i];
	   }
	   $str .= "\n";
	   print STDERR "$str\n";
       }

       if($sys_class_idx == $true_class_idx){
	   $correct_cnt ++;
       }

       my $tmp = $p_dist[$true_class_idx];
       if($tmp > 0){
	   $log_LL += log($tmp);
       }else{
	   $log_LL += $LOG_ZERO;
       }

       my $size = scalar @$inst_ptr;
       for(my $i=2; $i<$size; $i+=2){
	   ## go through each feature
	   my $feat_idx = $inst_ptr->[$i];
	   my $feat_val = $inst_ptr->[$i+1];
	   
	   for(my $c=0; $c<$class_num; $c++){
	       my $base = $c * $feat_num;
	       $model_expect->[$base+$feat_idx] += $feat_val * $p_dist[$c];
	   }
       }
       
       $total_cnt ++;
       if($total_cnt % 1000 == 0){
	   print STDERR " Finish processing ", $total_cnt/1000, "K instances\n";
       }
   }
   
   $$correct_cnt_ptr =  $correct_cnt;

   print STDERR "Finish calculating model expectation\n";
   return $log_LL;
}

### calc log prob, log is based on e.
sub compute_log_probs {
    my ($probs, $log_probs, $log_zero) = @_;
    
    foreach my $prob (@$probs){
	if($prob > 0){
	    push(@$log_probs, log($prob));
	}else{
	    push(@$log_probs, $log_zero);
	}
    }
}

### push n zeros to the array
sub init_array_with_zeros {
    my ($array_ptr, $n) = @_;

    @$array_ptr = ();
    for(my $i=0; $i<$n; $i++){
	push(@$array_ptr, 0);
    }
}


### set all the weights to be zero.
sub form_init_weights {
    my ($init_weights_ptr, $class_num, $feat_num) = @_;

    init_array_with_zeros($init_weights_ptr, $class_num * $feat_num);
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
