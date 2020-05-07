#!/usr/bin/env perl


## created on 12/27/07

## Purpose: DT learner

## to run:
##    $0 training_data test_data max_depth min_gain model test_raw 

## the format of the training and testing data is:
##  instanceName label f1 v1 f2 v2 ....
##
## We treat all the features as binary; that is, only feat whose value is 
##   non-zero will be kept, and the exact feature values are ignored.

## model has the format
##  x1&x2&...&x_n label
##  where x_i is w or !w and w is a word

## test_raw has the format
##   instanceName label c1 p1 c2 p2 ....
##
## where label1 is the true label, (c_i, p_i) is sorted according to the p_i.

## stdout shows the confusion matrix and training and test accuracy

use Class::Struct;

struct( DT_node => {
    ##################### available for all nodes
    depth => '$',               # the depth of the root is 0.
    parent => 'DT_node',

    training_instance_num => '$',   # the num of training instances in the subtree
    probs => '@',         # probs[c_i] = P(c_i) for the nodes in the subtree
    entropy => '$',       # H(S)

    class_idx => '$',     # the class with the highest prob
    prob_str => '$',      # "training_instance_num c1 p1 c2 p2 ..."

    ################### set after choosing the best feature
    is_leaf_node => '$',        # 1 if it is a leaf node
    left_child => 'DT_node',    # feature is absent
    right_child => 'DT_node',   # feature is present

    feat_idx => '$',            # the feature used to split the data
    info_gain => '$'            # H(S) - H(S|f)
 }
);


struct( DT_tree => {
    root => 'DT_node'
}
);

############ options
my $debug = 0;
my $output_all_prob = 1;

############ constants
my $log2 = log(2);
my %log2_hash = ();  ## A{x}=log2(x)  i.e., the 2-based log(x) 

use strict;

main();

1;


#########################
sub main {
    my $cnt = 0;
    
    my $arg_num = @ARGV;
    
    if($arg_num != 6){
	die "Build DT and classify training and test data\n usage: $0 training_data test_data max_depth min_gain model test_raw > acc_file\n";
    }

    my $training_file = $ARGV[0];
    my $test_file = $ARGV[1];
    my $max_depth = $ARGV[2];
    my $min_gain = $ARGV[3];
    my $model = $ARGV[4];
    my $sys = $ARGV[5];

    if($max_depth <= 0){
	die "depth is $max_depth. It should be > 0\n";
    }

    print STDERR "max_depth=$max_depth\n";
    print STDERR "min_gain=$min_gain\n";

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


    
    ## my $t1 = print_instlist($model_fp, \@training_instlist, \@classnames, 
    ##			    \@featnames);


    ### print out the class labels
    print STDERR "class_labels=", join(" ", @classnames), "\n";

    ######## step 2: training stage: build DT tree
    my $ttree = new DT_tree;

    my $class_num = scalar @classnames;
    my $feat_num = scalar @featnames;

    my $node_num = 
	build_DT(\@training_instlist, $class_num, \@classnames,
		 $feat_num, \@featnames,
		 $max_depth, $min_gain, $output_all_prob, $ttree);

    print STDERR "Finish building the DT. It has $node_num nodes\n";


    ########## step 3: print DT
    print_DT($model_fp, $ttree, $class_num, $feat_num, 
	     \@classnames, \@featnames, $output_all_prob);

    close($model_fp);

    ######### step 4: testing on the training data
    my @train_confusion_matrix = ();
    print $sys_fp "%%%%% training data:\n";
    my $acc 
	= classify_instlist_with_DT(\@training_instlist, $ttree, \@classnames,
				    $sys_fp, \@train_confusion_matrix);

    print "Confusion matrix for the training data:\n";
    print_confusion_matrix(\@classnames, \@train_confusion_matrix);
    print "\n Training accuracy=$acc\n";

    ######### step 4: testing on the test data
    my @test_confusion_matrix = ();

    print $sys_fp "\n\n%%%%% test data:\n";
    $acc =
	classify_instlist_with_DT(\@test_instlist, $ttree, \@classnames,
				  $sys_fp, \@test_confusion_matrix);

    print "\n\nConfusion matrix for the test data:\n";
    print_confusion_matrix(\@classnames, \@test_confusion_matrix);
    print "\n Test accuracy=$acc\n";

    close($sys_fp);

}


############################################################################
### return log(x), where log is based 2.
### update the hash table if needed.
sub my_log2 {
    my ($x) = @_;

    my $val = $log2_hash{$x};
    if(defined($val)){
	return $val;
    }else{
	$val = log($x)/$log2;
	$log2_hash{$x} = $val;
	return $val;
    }
}


#############################################################################
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
sub classify_instlist_with_DT {
    my ($instlist, $ttree, $classnames_ptr, 
	$output_fp, $confusion_matrix_ptr) = @_;

    my $cnt = 0;
    my $corr_cnt = 0;

    ############## init
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
	    classify_inst_with_DT($ptr, $ttree, $classnames_ptr, 
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


#### return the str "instanceName true_class_name c1 p1 c2 p2 ..."
sub classify_inst_with_DT {
    my ($inst_ptr, $ttree, $classnames_ptr, 
	$true_idx_ptr, $sys_idx_ptr) = @_;

    my $tnode = find_tnode_in_DT($inst_ptr, $ttree);

    my @inst = @$inst_ptr;
    my $inst_name = $inst[0];
    my $true_class_idx = $inst[1];
    my $true_class_name = $classnames_ptr->[$true_class_idx];
    my $answer = $tnode->prob_str;
    
    my $str = "$inst_name $true_class_name $answer";

    $$true_idx_ptr = $true_class_idx;
    $$sys_idx_ptr = $tnode->class_idx;

    return $str;
}


sub find_tnode_in_DT {
    my ($inst_ptr, $ttree) = @_;

    my $root = $ttree->root;
    return find_tnode_in_DT_from_tnode($inst_ptr, $root);
}


sub find_tnode_in_DT_from_tnode {
    my ($inst_ptr, $tnode) = @_;

    if($tnode->is_leaf_node){
	return $tnode;
    }

    my $test_feat_idx = $tnode->feat_idx;
    my @inst = @$inst_ptr;
    my $size = scalar @inst;
    
    my $found = 0;
    for(my $i=2; $i<$size; $i++){
	my $feat_idx = $inst[$i];
	if($feat_idx == $test_feat_idx){
	    $found = 1;
	}
    }

    my $next_tnode = $tnode->left_child;
    if($found){
	$next_tnode = $tnode->right_child;
    }

    return find_tnode_in_DT_from_tnode($inst_ptr, $next_tnode);
}


################### print the DT
sub print_DT {
    my ($fp, $ttree, $class_num, $feat_num, 
	$classnames_ptr, $featnames_ptr, $print_flag) = @_;

    my @list = ();
    
    my $root = $ttree->root;
    my $rule_num = 
	get_rule_list_from_tnode($root, $class_num, $feat_num, 
				 $classnames_ptr, $featnames_ptr, 
				 $print_flag, \@list);

    foreach my $rule (@list){
	print $fp "$rule\n";
    }
}

### return class_idx with the highest prob
sub best_class_from_probs {
    my ($prob_ptr) = @_;
    my $max_prob = 0;
    my $max_class_idx = -1;
 
    my $class_num = scalar @$prob_ptr;
    for(my $i=0; $i<$class_num; $i++){
	my $prob = $prob_ptr->[$i];  
	if($prob > $max_prob){
	    $max_prob = $prob;
	    $max_class_idx = $i;
	}
    }

    return $max_class_idx;
}



### return prob_str which is "classname prob ..."
sub probs_to_str {
    my ($prob_ptr, $class_idx, $classnames_ptr, $incl_all) = @_;

    my $str = "";
    my $class_num = scalar @$prob_ptr;
    
    if($incl_all){
	for(my $i=0; $i<$class_num; $i++){
	    my $classname = $classnames_ptr->[$i];
	    my $prob = $prob_ptr->[$i];
	    $str .= " $classname $prob";
	    $str =~ s/^\s+//;
	}
    }else{
	my $max_classname = $classnames_ptr->[$class_idx];
	my $max_prob = $prob_ptr->[$class_idx];
	$str = "$max_classname $max_prob";
    }

    return $str;
}

### return the number of rules
sub get_rule_list_from_tnode {
    my ($tnode, $class_num, $feat_num, $classnames_ptr,
	$featnames_ptr, $print_flag, $list_ptr) = @_;

    if($tnode->is_leaf_node){
	my $ptr = $tnode->probs;
	my $str = $tnode->training_instance_num;
	$str .= " " . $tnode->prob_str;
	push(@$list_ptr, $str);
	return 1;
    }

    my $left_child = $tnode->left_child;
    my @list1 = ();
    my $rule_num1 = 
	get_rule_list_from_tnode($left_child, $class_num, $feat_num,
				 $classnames_ptr, $featnames_ptr,
				 $print_flag, \@list1);

    my $right_child = $tnode->right_child;
    my @list2 = ();
    my $rule_num2 = 
	get_rule_list_from_tnode($right_child, $class_num, $feat_num,
				 $classnames_ptr, $featnames_ptr, 
				 $print_flag, \@list2);

    my $feat_idx = $tnode->feat_idx;
    my $featname = $featnames_ptr->[$feat_idx];
    
    my $delim = " ";
    if($rule_num1 >1){
	$delim = "&";
    }

    my $pref = "!" . $featname . $delim;
    foreach my $val (@list1){
	push(@$list_ptr, $pref . $val);
    }

    if($rule_num2 > 1){
	$delim = "&";
    }else{
	$delim = " ";
    }

    my $pref =  $featname . $delim;
    foreach my $val (@list2){
	push(@$list_ptr, $pref . $val);
    }

    my $ret = scalar @$list_ptr;
    return $ret;
    
}


sub build_DT {
    my ($instlist, $class_num, $classnames_ptr, $feat_num, $featnames_ptr,
	$max_depth, $min_gain, $incl_all, $ttree) = @_;

    my $training_inst_num = scalar @$instlist;
    my @subset = ();
    for(my $i=0; $i<$training_inst_num; $i++){
	push(@subset, $i);
    }

    my $root = new DT_node;
    $root->depth(0);
    $root->training_instance_num($training_inst_num);
    my @probs = ();
    my $entropy = calc_entropy($instlist, $class_num, \@probs);

    $root->entropy($entropy);
    $root->probs('()');
    my $ptr = $root->probs;
    @$ptr = @probs;

    my $class_idx = best_class_from_probs(\@probs);
    my $prob_str = probs_to_str(\@probs, $class_idx, $classnames_ptr, 
				$incl_all);
    $root->class_idx($class_idx);
    $root->prob_str($prob_str);

    my $node_num = 
	build_DT_from_tnode($instlist, \@subset, $class_num, $classnames_ptr,
			    $feat_num, $featnames_ptr, $max_depth, $min_gain, 
			    $incl_all, $root);

    $ttree->root($root);
    return $node_num;
}



#  the tnode fields that are set before the function call:
#     - depth, parent, training_instance_num, probs, entropy
#
#  the tnode fields that are set by the function:
#     - is_leaf_node, left_child, right_child, feat_idx, info_gain
#
#  return the number of nodes in the subtree, including tnode.
#
sub build_DT_from_tnode {
    my ($instlist, $subset, $class_num, $classnames_ptr,
	$feat_num, $featnames_ptr,
	$max_depth, $min_gain, $incl_all, $tnode) = @_;

    ### 1. check the depth and entropy
    my $depth = $tnode->depth;
    my $entropy = $tnode->entropy;
    if($depth >= $max_depth || $entropy == 0){
	$tnode->is_leaf_node(1);
	return 1;
    }

    #### 2. select the features
    my @prob_not_f = (); # P(C|not f)
    my @prob_f = ();     # P(C|f)
    my ($suc, $min, $min_feat_idx, $h_not_f, $h_f) = 
    select_best_feat($instlist, $subset, $class_num, $feat_num,
		     $featnames_ptr, \@prob_not_f, \@prob_f);

    my $gain = $entropy - $min;

    if(!$suc){
	my $featname = $featnames_ptr->[$min_feat_idx];
	print STDERR "Cannot find the best feature: feat_idx=$min_feat_idx, feat=$featname entropy=$entropy min=$min gain=$gain\n";

	$tnode->is_leaf_node(1);
	return 1;
    }


    if($gain < $min_gain){
	### no need to split
	$tnode->is_leaf_node(1);
	return 1;
    }

    my $featname = $featnames_ptr->[$min_feat_idx];
    print STDERR "==> best feat: gain=$gain feat_idx=$min_feat_idx, featname=$featname\n";

    #### 3. split the data
    my @left_subset = ();
    my @right_subset = ();
    my $left_subset_size = 
	split_instance_set($instlist, $subset, $min_feat_idx,
			   \@left_subset, \@right_subset);

    #### 4. create left child
    my $left_child = new DT_node;
    my $size = scalar @left_subset;

    $left_child->parent($tnode);
    $left_child->depth($depth+1);
    $left_child->training_instance_num($size);
    $left_child->entropy($h_not_f);
    $left_child->probs('()');
    my $ptr = $left_child->probs;
    @$ptr = @prob_not_f;

    my $class_idx = best_class_from_probs(\@prob_not_f);
    my $prob_str = probs_to_str(\@prob_not_f, $class_idx, $classnames_ptr, 
				$incl_all);
    $left_child->class_idx($class_idx);
    $left_child->prob_str($prob_str);


    ### 5. create the right child
    my $right_child = new DT_node;
    $size = scalar @right_subset;

    $right_child->parent($tnode);
    $right_child->depth($depth+1);
    $right_child->training_instance_num($size);
    $right_child->entropy($h_f);
    $right_child->probs('()');
    $ptr = $right_child->probs;
    @$ptr = @prob_f;

    $class_idx = best_class_from_probs(\@prob_f);
    $prob_str = probs_to_str(\@prob_f, $class_idx, $classnames_ptr, 
			     $incl_all);
    $right_child->class_idx($class_idx);
    $right_child->prob_str($prob_str);


    ### 6: update tnode
    $tnode->is_leaf_node(0);

    $tnode->left_child($left_child);
    $tnode->right_child($right_child);

    $tnode->feat_idx($min_feat_idx);
    $tnode->info_gain($gain);

    ### 7. call the function recursively
    my $node_num = 
	build_DT_from_tnode($instlist, \@left_subset,
			    $class_num, $classnames_ptr,
			    $feat_num, $featnames_ptr, $max_depth, $min_gain,
			    $incl_all, $left_child);

    $node_num += 
	build_DT_from_tnode($instlist, \@right_subset, 
			    $class_num, $classnames_ptr,
			    $feat_num, $featnames_ptr, $max_depth, $min_gain, 
			    $incl_all, $right_child);

    return $node_num + 1;
    
}

### return the entropy
### H(p) = - sum_i p_i log p_i = - sum_i cnt_i/N log cnt_i/N
###      = (- 1/N sum_i cnt_i log cnt_i) + logN 
###
sub calc_entropy {
    my ($instlist, $class_num, $probs) = @_;

    @$probs = ();
    for(my $i=0; $i<$class_num; $i++){
	push(@$probs, 0);
    }

    foreach my $ptr (@$instlist){
	my @inst = @$ptr;
	my $class_idx = $inst[1];
	$probs->[$class_idx] ++;
    }

    my $inst_num = scalar @$instlist;
    my $res = 0;
    for(my $i=0; $i<$class_num; $i++){
	my $cnt = $probs->[$i];
	my $p = $cnt / $inst_num;
	$probs->[$i] = $p;
	if($cnt == 0){
	    next;
	}
	my $log_cnt = my_log2($cnt);
	$res += $cnt * $log_cnt;
    }

    $res = -$res/$inst_num + my_log2($inst_num);

    return $res;
}


## return the size of left_subset
##
## split the subset into left and right subset.
## left_subset contains the instances where the feature is absent.
##
sub split_instance_set {
    my ($instlist, $subset, $split_feat, $left_subset, $right_subset) = @_;

    @$left_subset = ();
    @$right_subset = ();
    
    my $cnt = 0;
    foreach my $idx (@$subset){
	my $inst_ptr = $instlist->[$idx];
	my @inst = @$inst_ptr;

	my $class_idx = $inst[1];
	my $found = 0;
	for(my $i=2; $i<scalar @inst; $i++){
	    my $feat_idx = $inst[$i];
	    if($feat_idx == $split_feat){
		$found = 1;
		last;
	    }
	}

	if($found){
	    push(@$right_subset, $idx);
	}else{
	    push(@$left_subset, $idx);
	    $cnt ++;
	}
    }

    return $cnt;
}






### return (suc, min, min_feat_idx, h_not_f, h_f)
###  suc is 1 if succeed
###  min is min_f sum_a P(f=a) H(S|f=a), for the best f
###
###  h_f is H(S|f=a), h_not_f is H(S|f!=a)
###

### subset is a set of instanceIdx.
### Suppose the subset contains N instances
### for each feature f, suppose the values are as follows:
###
###         c1    c2    ...    c_k
###  f      n1    n2           n_k    Cnt(f)
### not f   m1    m2     ...   m_k    N-Cnt(f) 
### 
### H(S|f is present) = - sum_i n_i/cnt(f) log n_i/cnt(f)  
###                   = - 1/cnf(f) * sum n_i log n_i + log cnt(f)
###
### H(S|f is absent) = - sum_i m_i/(N-cnt(f)) log m_i/(N-cnt(f))
###                  = 
### InfoGain(S,f) 
###   = H(S) - cnt(f)/N H(S|f is presnt) 
###          - (N-cnt(f))/N H(S |f is not present)
###   = H(S) - 1/N (cnt(f) log cnt(f) - sum_i n_i log n_i 
###                 (N-cnt(f)) log (N-cnt(f)) - sum_i m_i log m_i) 
###
### we will store "n log n" in a hash table nlogn_hash to avoid all the 
###   log computation.
###
sub select_best_feat {
    my ($instlist, $subset, $class_num, $feat_num, $featnames_ptr,
	$prob_not_f, $prob_f) = @_;

    my $inst_num = scalar (@$instlist);
    my $N = scalar (@$subset);

    # it stores cnt[f_i][c_j] (i.e., the count of seeing f_i and c_j)
    my @n2D_cnt = ();   
    
    my @c_cnt = ();     # it stores cnt[c_j]

    my @feat_cnt = ();  # it stores cnt[f_i]

    ### step 1: init the counts
    my @c_cnt = ();
    for(my $i=0; $i<$class_num; $i++){
	push(@c_cnt, 0);
    }

    my @feat_flags = ();  # X[i]=1 iff the feat vector has f_i.
    for(my $i=0; $i<$feat_num; $i++){
	push(@n2D_cnt, [@c_cnt]);
	push(@feat_cnt, 0);
	push(@feat_flags, 0);
    }

    ### step 2: collect the real counts
    print STDERR "\n\ncollecting counts starts\n";

    foreach my $idx (@$subset){
	## to deal with each instance

	if($idx < 0 || $idx > $inst_num){
	    die "wrong inst_idx $idx\n";
	}
	my $inst_ptr = $instlist->[$idx];
	## my @inst = @$inst_ptr;

	my $class_idx = $inst_ptr->[1];
	$c_cnt[$class_idx] ++;

	for(my $i=2; $i<scalar @$inst_ptr; $i++){
	    my $feat_idx = $inst_ptr->[$i];
	    my $ptr = $n2D_cnt[$feat_idx];
	    $ptr->[$class_idx] ++;
	    $feat_cnt[$feat_idx] ++;
	}
    }

    #### step 3: select the best feature
    my $min = 0;
    my $min_feat_idx = -1;
    my $min_h_f = -1;
    my $min_h_not_f = -1;

    print STDERR "selecting the best feature\n";

    for(my $i=0; $i<$feat_num; $i++){
	my $ptr = $n2D_cnt[$i];
	my $cnt_f = $feat_cnt[$i];
	my $cnt_not_f = $N - $cnt_f;

	if($cnt_f == 0){
	    next;
	}

	my $h_f = 0;      # H(S |f is present)
	my $h_not_f = 0;  # H(S |f is abssent)

	if($cnt_f == 0 || $cnt_f == $N){
	    next;
	}

	for(my $c=0; $c<$class_num; $c++){
	    my $c_feat_cnt = $ptr->[$c];
	    
	    if($c_feat_cnt > 0){
		my $log_cnt = my_log2($c_feat_cnt);
		$h_f += $c_feat_cnt * $log_cnt;
	    }

	    my $c_not_feat_cnt = $c_cnt[$c] - $c_feat_cnt;
	    if($c_not_feat_cnt){
		my $log_cnt = my_log2($c_not_feat_cnt);
		$h_not_f += $c_not_feat_cnt * $log_cnt;
	    }
	}

	my $featname = $featnames_ptr->[$i];
	if($debug){
	    print STDERR "*** feat_idx=$i featname=$featname\n";
	    print STDERR "f is present: ", join(" ", @$ptr), "\n";
	}



	if($debug){
	    print STDERR "f is absent:  ", join(" ", @$ptr), "\n";
	}


	$h_f =  $cnt_f * my_log2($cnt_f) - $h_f;
	$h_not_f = $cnt_not_f * my_log2($cnt_not_f) - $h_not_f;
	my $val = ($h_f + $h_not_f)/$N;

	$h_f /= $cnt_f;
        $h_not_f /= $cnt_not_f;

	if($min == 0 || $min > $val){
	    $min = $val;
	    $min_feat_idx = $i;
	    $min_h_f = $h_f;
	    $min_h_not_f = $h_not_f;
	}
	
	if($debug){
	    print STDERR "featidx=$i val=$val H(X|f)=$h_f H(X|not_f)=$h_not_f\n";
	    print STDERR "val=$val feat_name=$featname\n\n";
	}
    }

    ##### set the distribution
    my $ptr_f = $n2D_cnt[$min_feat_idx];
    my $cnt_f = $feat_cnt[$min_feat_idx];

    my $suc = 1;
    if($cnt_f > 0 && $cnt_f < $N){
	set_probs($ptr_f, \@c_cnt, $N, $cnt_f,
		  $prob_not_f, $prob_f);
    }else{
	$suc = 0;
    }

    return ($suc, $min, $min_feat_idx, $min_h_not_f, $min_h_f);
}


### set the distribution: P(S|f is absent) and P(S|f is present)
sub set_probs {
    my ($ptr_f, $cnt_c, $N, $cnt_f, $prob_not_f, $prob_f) = @_;

    @$prob_not_f = ();
    @$prob_f = ();

    for(my $c=0; $c<scalar @$cnt_c; $c++){
	my $c_f_cnt = $ptr_f->[$c];
	my $p = $c_f_cnt / $cnt_f;
	push(@$prob_f, $p);

	my $c_not_f_cnt = $cnt_c->[$c] - $c_f_cnt;
	$p = $c_not_f_cnt / ($N - $cnt_f);
	push(@$prob_not_f, $p);
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



