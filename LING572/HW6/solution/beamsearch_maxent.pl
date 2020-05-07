#!/usr/bin/env perl


## created on 2/19/08

## Purpose: beam search with a MaxEnt model for POS tagging

## to run:
##   $0 test_data boundary_file input_model sys_output topN beam_size_ratio max_hyps > acc_file


## The format of the test data is:
##  instanceName label f1 v1 f2 v2 ....

## The boundary_file has one number per line, which is the 
##  length of a sentence.

## The input_model has the format: (the same as the Mallet format)
##  FEATURES FOR CLASS classname
##  <default> weight
##  featname  weight
##  ...


## sys_output has the format
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

### A hypothesis is stored as an array with the format
###   (logprob_sum, t1, prob1, t2, prob2, ....)
###   prob_i = P(t_i | w_i)
###   logprob_sum = sum_i log(prob_i)

### An instance is stored as 
##    (instName, trueLabel, featname1, featval1, featname2, featval2, ...)   


############ options
my $debug = 0;

############ constants
my $default_feat_name = "<default>";  # the default_feat_name in the model file
my $EXP_BASE = 2.71828182845904523536;

my $prevtag_feat_pref = "prevT=";
my $prev2tag_feat_pref = "prevTwoTags=";
my $BOS_str = "BOS";


use strict;

main();

1;


#########################
sub main {
    my $cnt = 0;

    ##### step 0: read the parameters
    my $arg_num = @ARGV;
    
    if($arg_num < 5){
	die "Beam search with a MaxEnt model for POS tagging\n Usage: $0 test_data boundary_file input_model sys_output beam_size_ratio {topN} {max_hyps} > acc_file\n";
    }

    my $test_file = $ARGV[0];
    my $boundary_file = $ARGV[1];
    my $model = $ARGV[2];
    my $sys = $ARGV[3];
    my $beam_size_ratio = $ARGV[4];

    my $topN = 0;
    my $max_hyps = 0;

    if($arg_num > 5){
	$topN = $ARGV[5];
    }

    if($arg_num > 6){
	$max_hyps = $ARGV[6];
    }

    if($beam_size_ratio < 1){
	die "beam_size_ratio should be >= 1\n";
    }

    my $log_ratio = log($beam_size_ratio);

    print STDERR "topN=$topN beam_size_ratio=$beam_size_ratio log_ratio=$log_ratio max_hyps=$max_hyps\n";

    open(my $test_fp, "$test_file") 
	or die "cannot open test file $test_file\n";

    open(my $boundary_fp, "$boundary_file") 
	or die "cannot open boundary_file $boundary_file\n";

    open(my $model_fp, "$model") or die "cannot open model file $model\n";

    open(my $sys_fp, ">$sys") or die "cannot create system output file $sys\n";


    #### step 1: read the MaxEnt model
    my %feat2idx = ();
    my %class2idx = ();
    
    my @featnames = ();
    my @classnames = ();
  
    my $model = new MaxEnt_model;

    print STDERR "start reading MaxEnt model ...\n";
    my $suc = read_model($model_fp, $model, \%class2idx, \@classnames,
			 \%feat2idx, \@featnames);

    print STDERR "Finish reading MaxEnt model ...\n";


    ##### step 2: print out classnames, etc.
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


    ######## step 4: read the boundary file
    my @sent_lengs = ();

    my $tmp_inst_num = 0;
    my $sent_num = read_boundary_file($boundary_fp, \@sent_lengs, 
				      \$tmp_inst_num);

    if($test_inst_num != $tmp_inst_num){
	die "different numbers of instances: $boundary_file has $tmp_inst_num instances, and $test_file has $test_inst_num instances\n";
    }

    print STDERR "finish reading boundary file, sent_num=$sent_num\n";


    ######## step 5: create mapping from prevtag=c to feat_idx
    my @prevtag_map = (); # A[i] is the feat_idx for prevtag=c_i
    create_prevtag_map(\@classnames, \%feat2idx, $prevtag_feat_pref,
		       \@prevtag_map);

    # A[i*(class_num+1]+j] is the feat_idx for prev2tag=c_i+c_j
    my @prev2tag_map = (); 
    create_prev2tag_map(\@classnames, \%feat2idx, $prev2tag_feat_pref,
			\@prev2tag_map);

    
    ######## step 6: testing on the test data
    print STDERR "Start classifying testing data ...\n";

    my @test_confusion_matrix = ();
    print $sys_fp "\n\n%%%%% test data:\n";
    my $acc = classify_instlist_with_beam_search(\@test_instlist,
                    \@sent_lengs, $model, 
		    \@prevtag_map, \@prev2tag_map,
		    $topN, $beam_size_ratio, $max_hyps, 
		    \@classnames, $sys_fp, \@test_confusion_matrix);

    print "\n\nConfusion matrix for the test data:\n";
    print_confusion_matrix(\@classnames, \@test_confusion_matrix);
    print "\n Test accuracy=$acc\n";
    close($sys_fp);

    print STDERR "Finish classifying testing data\n";

    ####### step 5: print the model
    if($debug > 5){
	open(my $out_fp, ">$sys.model") or die "cannot open $sys.model\n";
	print_model($out_fp, $model, \@classnames, \@featnames);
	close($out_fp);
    }

    print STDERR "All done\n";
}


############################################ beamsearch function
### set $map_ptr->[i] = feat_idx, where feat_idx is the index of 
###  the feature prevTag=c_i.
###
### The last element of the array is for BOS.
###
sub create_prevtag_map {
    my ($classnames_ptr, $feat2idx_ptr, $prevtag_pref, $map_ptr) = @_;

    @$map_ptr = ();
    foreach my $classname (@$classnames_ptr){
	my $feat_name = $prevtag_pref . "$classname";
	my $feat_idx = $feat2idx_ptr->{$feat_name};
	if(!defined($feat_idx)){
	    print STDERR "warning: prevtag feature $feat_name is not defined\n";
	    $feat_idx = -1;
	}
	push(@$map_ptr, $feat_idx);
    }

    #### add the feature where c_i = BOS
    my $feat_name = $prevtag_pref . $BOS_str;
    my $feat_idx = $feat2idx_ptr->{$feat_name};
    if(!defined($feat_idx)){
	print STDERR "warning: prevtag feature $feat_name is not defined\n";
	$feat_idx = -1;
    }
    push(@$map_ptr, $feat_idx);
}


### set $map_ptr->[i*(class_num+1)+j] = feat_idx, 
#### where feat_idx is the index of 
###  the feature prev2Tag=c_i+c_j.
###
### The "1" is for BOS
###
sub create_prev2tag_map {
    my ($classnames_ptr, $feat2idx_ptr, $prev2tag_pref, $map_ptr) = @_;

    @$map_ptr = ();

    my @new_class_names = @$classnames_ptr;
    push(@new_class_names, $BOS_str);

    foreach my $name1 (@new_class_names){
	foreach my $name2 (@new_class_names){
	    my $feat_name = $prev2tag_pref . $name1 . "+" . $name2;
	    my $feat_idx = $feat2idx_ptr->{$feat_name};
	    if(!defined($feat_idx)){
		print STDERR "warning: prevtag feature $feat_name is not defined\n";
		$feat_idx = -1;
	    }
	    push(@$map_ptr, $feat_idx);
	}
    }
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


################### beam search
### return accuracy
sub classify_instlist_with_beam_search {
    my ($instlist, $sent_lengs, $model, 
	$prevtag_map, $prev2tag_map, 
	$topN, $beam_size_ratio, $max_hyps,
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
    my $sent_num = scalar @$sent_lengs;
    
    my $beam_size_log_ratio = log($beam_size_ratio);

    for(my $i=0; $i<$sent_num; $i++){
	my $sent_leng = $sent_lengs->[$i];
	my $tmp_corr_cnt = 0;
	
	if($debug){
	    print STDERR "sent_num=$i start=$cnt leng=$sent_leng\n";
	}

	my $str = classify_inst_group($instlist, $cnt, $sent_leng, $model,
				      $prevtag_map, $prev2tag_map, 
				      $topN, $beam_size_log_ratio, $max_hyps,
				      $classnames_ptr, \$tmp_corr_cnt,
				      $confusion_matrix_ptr);
	

	print $output_fp "$str\n";

	$corr_cnt += $tmp_corr_cnt;
	$cnt += $sent_leng;

	if($sent_num % 100 == 0){
	    print STDERR " Finish classifying $sent_num sentences. inst=$cnt correct_cnt=$corr_cnt\n";
	}
    }

    my $acc = $corr_cnt/$cnt;
    return $acc;
}


#### return the result for the whole group (i.e., the sentence)
#### e.g., "instname true_class sys_class prob 
####        ....
####        ...."
####
sub classify_inst_group {
    my ($instlist, $start, $leng, $model, 
	$prevtag_map, $prev2tag_map, 
	$topN, $beam_size_log_ratio, $max_hyps,
	$classnames_ptr, $corr_cnt_ptr, $confusion_matrix_ptr) = @_;

    my $corr_cnt = 0;

    #### step 0: set the initial hyp: it is "0 BOS 1 BOS 1"
    my $class_num = scalar @$classnames_ptr;
    my @cur_hyp = (0);
    push(@cur_hyp, $class_num);  # w_{-2}=BOS 
    push(@cur_hyp, 1);
    push(@cur_hyp, $class_num);  # w_{-1}=BOS 
    push(@cur_hyp, 1);

    my @cur_hyps = ();
    push(@cur_hyps, [@cur_hyp]);
    
    ##### step 1: build the beam search tree
    for(my $i=0; $i<$leng; $i++){
	my $hyp_num = scalar @cur_hyps;
	if($debug > 5){
	    print STDERR "pos=$i hyp_num=$hyp_num\n";
	    print_hyps(\@cur_hyps);
	}
	
	### process each instance
	my $inst = $instlist->[$start+$i];
	
	#### step 1a: set @new_hyps
	my @new_hyps = ();
	my $max_logprob = 0;

	##### reserve the space for PrevTag and Prev2Tag features
	push(@$inst, -1);
	push(@$inst, 1);
	push(@$inst, -1);
	push(@$inst, 1);

	my $cnt = 0;
	my $max_logprob = 0;
	foreach my $h (@cur_hyps){
	    my $tmp_logprob = 
		get_new_hyps($h, $inst, $model, $prevtag_map, $prev2tag_map, 
			     $topN, $beam_size_log_ratio, $max_hyps,
			     \@new_hyps);

	    if($cnt == 0 || ($max_logprob < $tmp_logprob)){
		$max_logprob = $tmp_logprob;
	    }

	    $cnt ++;

	    ### only use max_hyps hyps
	    if(($max_hyps > 0) && ($cnt >= $max_hyps)){
		last;
	    }
	}
	
	#### step 1b: prune new hyps
	prune_hyps(\@new_hyps, $max_logprob, $beam_size_log_ratio, $max_hyps, 
		   \@cur_hyps);
    }

    ###### step 2: use the top hyp for the output
    my $top_hyp = $cur_hyps[0];

    my $res_str = "";

    for(my $i=0; $i<$leng; $i++){
	my $inst = $instlist->[$start+$i];

	my $inst_name = $inst->[0];
	my $true_idx = $inst->[1];

        # the 1st 5 elements of the hyp are "logprob BOS 1 BOS 1"
	my $sys_idx = $top_hyp->[$i*2 + 5];   
	my $sys_prob = $top_hyp->[$i*2 + 6];
	
	my $true_class_name = $classnames_ptr->[$true_idx];
	my $sys_class_name = $classnames_ptr->[$sys_idx];

	my $str = "$inst_name $true_class_name $sys_class_name $sys_prob";
	if($i){
	    $res_str .= "\n" . $str;
	}else{
	    $res_str = $str;
	}

	if($true_idx == $sys_idx){
	    $corr_cnt ++;
	}

	my $ptr = $confusion_matrix_ptr->[$true_idx];
	$ptr->[$sys_idx] ++;
    }
    
    $$corr_cnt_ptr = $corr_cnt;

    return $res_str;
}

### return max_logprob 
### Given a hyp h, extend the h to get a new set of hyps
###
sub get_new_hyps {
    my ($h, $inst, $model, $prevtag_map, $prev2tag_map, 
	$topN, $beam_size_log_ratio, $max_hyps,	$new_hyps_ptr) = @_;

    ##### step 1: form the instance
    form_new_inst_from_hyp($h, $inst, $prevtag_map, $prev2tag_map);

    #### step 2: classify the instance
    my @probs = ();
    my @select_labels = (); 
    my $new_hyp_num = classify_inst_with_ME($inst, $model, $topN, 
					    \@select_labels, \@probs);

    ##### step 3: add the new hyps
    my $max_logprob = 0;

    my $old_logprob = $h->[0];
    my @new_hyp = @$h;
    push(@new_hyp, -1);
    push(@new_hyp, -1);

    my $size = scalar @new_hyp;

    for(my $i=0; $i<$new_hyp_num; $i++){
	my $prob = $probs[$i];
	$new_hyp[$size-2] = $select_labels[$i];
	$new_hyp[$size-1] = $prob;
	$new_hyp[0] = $old_logprob + log($prob);
	push(@$new_hyps_ptr, [@new_hyp]);

	if($i > 0){
	    if($max_logprob < $new_hyp[0]){
		$max_logprob = $new_hyp[0];
	    }
	}else{
	    $max_logprob = $new_hyp[0];
	}
    }
    
    return $max_logprob;
}


## The last two featnames in the instance are changed.
##
sub form_new_inst_from_hyp {
    my ($h, $inst, $prevtag_map, $prev2tag_map) = @_;

    my $inst_size = scalar @$inst;

    my $h_leng = scalar @$h;
    my $prevtag_idx = $h->[$h_leng - 2];
    my $prev2tag_idx = $h->[$h_leng - 4];

    #### add PrevTag feature
    my $prevtag_feat_idx = $prevtag_map->[$prevtag_idx];
    if($prevtag_feat_idx < 0){
	print STDERR "warning: prevTag=$prevtag_idx is undefined\n";
    }else{
	$inst->[$inst_size-4] = $prevtag_feat_idx;
    }

    #### add Prev2Tag feature
    my $class_num = scalar @$prevtag_map;
    my $idx = $prev2tag_idx * $class_num + $prevtag_idx;
    my $prev2tag_feat_idx = $prev2tag_map->[$idx];
    if($prev2tag_feat_idx < 0){
	print STDERR "warning: prev2Tag=$prev2tag_idx+$prevtag_idx is undefined\n";
    }else{
	$inst->[$inst_size-2] = $prev2tag_feat_idx;
    }
}


### prune hyps by beam_size_ratio and max_hyps
### That is, keep only the hyps whose prob * ratio >= max_prob.
###           (i.e., log prob >= log max_prob - beam_size_log_ratio)
###
### If there are more than max_hyps, keep only the top max_hyps
### We don't pop out the unwanted ones, but they won't be used.
###
sub prune_hyps {
    my ($new_hyps_ptr, $max_logprob, $beam_size_log_ratio, $max_hyps, 
	$cur_hyps_ptr) = @_;

    my $thres = $max_logprob - $beam_size_log_ratio;

    if($debug > 1){
	print STDERR "max_logprob=$max_logprob thres=$thres\n";
	print STDERR "\n\nbefore pruning\n";
	print_hyps($new_hyps_ptr);
    }

    ##### keep only the ones whose prob is within the beam_size_ratio
    #####   and save the results in @tmp_hyps.
    my @tmp_hyps = ();
    my %hash = ();
    my $cnt = 0;

    foreach my $new_hyp (@$new_hyps_ptr){
	my $logprob = $new_hyp->[0];
	if($logprob >= $thres){
	    push(@tmp_hyps, $new_hyp);
	    $hash{$cnt} = $logprob;
	    $cnt++;
	}
    }

    if($debug > 1){
	print STDERR "\n\nAfter pruning with ratio\n";
	print_hyps(\@tmp_hyps);
    }

    #### sort and keep only the topN hyps
    @$cur_hyps_ptr = ();
    $cnt = 0;
    foreach my $i (sort {$hash{$b} <=> $hash{$a}} keys %hash){
	my $h = $tmp_hyps[$i];
	push(@$cur_hyps_ptr, $h);
	$cnt ++;
	if($max_hyps > 0 && $cnt >= $max_hyps){
	    last;
	}
    }

    if($debug > 1){
	print STDERR "\n\nAfter pruning with max_hyps\n";
	print_hyps($cur_hyps_ptr);
    }

    return $cnt;
}


sub print_hyps {
    my ($hyps) = @_;

    my $hyp_num = scalar @$hyps;
    print STDERR "hyp_num=$hyp_num\n";

    my $cnt = 0;
    foreach my $h (@$hyps){
	$cnt ++;
	print STDERR "\#$cnt: ", join(" ", @$h), "\n";
    }
}


#### classify the instance and put the topN choices in 
###    $class_ptr and $probs_ptr
###
### choose the c that maximizes 
###  log P(x|c) = default(c) + sum_i weight_i f_i(x,c)
###
### return the number of classes selected by the decoder.
###
sub classify_inst_with_ME {
    my ($inst_ptr, $model, $topN, $class_ptr, $probs_ptr) = @_;

    my @inst = @$inst_ptr;
    my $inst_name = $inst[0];

    my $size = scalar @inst;
    my $tmp_feat_num = $size/2 - 1;

    ##### check each class
    my $class_num = $model->class_num;
    my $feat_num = $model->feat_num;

    my %res_hash = ();
    my $norm = 0;  # the normalizer: sum_i P(x, c_i)
    my $feat_weight_ptr = $model->feat_weight;

    ###### step 1: calc sum_j \lambda_j f_j
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

    #### step 2: get the answer: val=P(x,c)/sum_c P(x,c)
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

    @$class_ptr = ();
    @$probs_ptr = ();

    my $cnt = 0;
    foreach my $c (sort {$res_hash{$b} <=> $res_hash{$a}} keys %res_hash){
	my $val = $res_hash{$c};
	my $prob = $val/$sum;

	if($prob <= 0){
	    last;
	}

	push(@$class_ptr, $c);
	push(@$probs_ptr, $prob);

	$cnt ++;
	if(($topN > 0) && ($cnt >= $topN)){
	    last;
	}
    }

    return $cnt;
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


### return sent_num
sub read_boundary_file {
    my ($fp, $lengs_ptr, $inst_num_ptr) = @_;

    my $sent_num = 0;
    @$lengs_ptr = ();

    my $total = 0;
    while(<$fp>){
	chomp;
	next if(/^\s*$/);

	my @parts = split(/\s+/);
	my $leng = $parts[0];
	
	push(@$lengs_ptr, $leng);
	$total += $leng;
	$sent_num ++;
    }

    $$inst_num_ptr = $total;
    return $sent_num;
}

