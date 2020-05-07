#!/usr/bin/env perl


## created on 1/21/08

## Purpose: rank features according to their chi square

## to run:
##    cat vector_input | $0 > feat_ranked_list

## the format of the input has the format
##  instanceName label f1 v1 f2 v2 ....

## the output has the format:
##  feat chi_square_score doc_num_w_feat
##
##  doc_num_w_feat is the num of doc that the feat is present


############ options
my $debug = 0;

############ constants
use strict;

main();

1;


#########################
sub main {
    my $cnt = 0;
    
    #### step 1: read the instance files
    my %feat2idx = ();
    my %class2idx = ();
    
    my @featnames = ();
    my @classnames = ();
  
    my @instlist = ();

    #### Step 1: read the instlist
    my $add_new = 1;
    my $inst_num = read_instances(\@instlist,
				  \%class2idx, \@classnames,
				  \%feat2idx, \@featnames,
				  $add_new);

    print STDERR "Finish reading instances: inst_num=$inst_num\n";

    ### print out the class labels
    my $class_num = scalar @classnames;
    my $feat_num = scalar @featnames;
    print STDERR "class_num=$class_num feat_num=$feat_num\n";

    print STDERR "class_labels=", join(" ", @classnames), "\n";

    
    #### step 2: collect counts
    my @cnt_c = ();
    my @cnt_f = ();
    my @cnt_f_c = ();
    collect_counts(\@instlist, $class_num, $feat_num,
		   \@cnt_c, \@cnt_f, \@cnt_f_c);
    
    print STDERR "collect_counts() done\n";

    #### step 3: calc chi square scores
    my %res_hash = ();

    my $N = scalar @instlist;
    for(my $f=0; $f<$feat_num; $f++){
	my $res = calc_chi_square($f, $class_num, $feat_num,
				  \@cnt_c, \@cnt_f, \@cnt_f_c, $N);
	$res_hash{$f} = $res;
    }

    #### step 4: output the results
    foreach my $f (sort {$res_hash{$b} <=> $res_hash{$a}} keys %res_hash){
	my $score = $res_hash{$f};
	my $cnt = $cnt_f[$f];
	my $feat_name = $featnames[$f];
	print "$feat_name\t$score\t$cnt\n";
    }
    
    print STDERR "All done\n";
}

#### The observation matrix:
####
####          c1        ...    c_i ...     total
####  not_f                                 cnt(not_f)
####      f  cnt(c1, f) ...   cnt(c_i,f)    cnt(f)  
####         cnt(c1)    ...   cnt(c_i)      N
####
####  N is the total number of document
####
#### return the score: sum_ij (O_ij - E_ij)^/E_ij
####
sub calc_chi_square {
    my ($f, $class_num, $feat_num,
	$cnt_c_ptr, $cnt_f_ptr, $cnt_f_c_ptr, $N) = @_;

    my $cnt_f = $cnt_f_ptr->[$f];
    my $cnt_not_f = $N - $cnt_f;

    my $res = 0;
    
    ### calc the not_f row
    for(my $c=0; $c<$class_num; $c++){
	my $cnt_c = $cnt_c_ptr->[$c];
	my $expected = $cnt_not_f * $cnt_c/$N;
	my $observ = $cnt_c - $cnt_f_c_ptr->[$c * $feat_num + $f];
	my $diff = $observ - $expected;
	$res += $diff * $diff / $expected;
    }

    ### calc the f row
    for(my $c=0; $c<$class_num; $c++){
	my $cnt_c = $cnt_c_ptr->[$c];
	my $expected = $cnt_f * $cnt_c/$N;
	my $observ = $cnt_f_c_ptr->[$c * $feat_num + $f];
	my $diff = $observ - $expected;
	$res += $diff * $diff / $expected;
    }

    return $res;
}


### count cnt(c) and cnt(f,c)
sub collect_counts {
    my ($instlist, $class_num, $feat_num, 
	$cnt_c_ptr, $cnt_f_ptr, $cnt_f_c_ptr) = @_;

    ###### init
    for(my $c=0; $c<$class_num; $c++){
	push(@$cnt_c_ptr, 0);

	for(my $f=0; $f<$feat_num; $f++){
	    push(@$cnt_f_c_ptr, 0);
	}
    }

    for(my $f=0; $f<$feat_num; $f++){
	push(@$cnt_f_ptr, 0);
    }

    ##### collect the counts
    foreach my $ptr (@$instlist){
	my @inst = @$ptr;
	my $size = scalar @inst;
	my $true_c_idx = $inst[1];
	my $base = $true_c_idx * $feat_num;
	$cnt_c_ptr->[$true_c_idx] ++;

	for(my $i=2; $i<$size; $i+=2){
	    my $feat_idx = $inst[$i];
	    $cnt_f_ptr->[$feat_idx] ++;
	    $cnt_f_c_ptr->[$base+$feat_idx] ++;
	}
    }
}

### return the number of valid instances
sub read_instances {
    my ($instList, $class2idx, $classnames_ptr,
	$feat2idx, $featnames_ptr, $add_new) = @_;

    my $valid_cnt = 0;
    my $invalid_cnt = 0;

    @$instList = ();
    while(<STDIN>){
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
    
    print STDERR "Finish reading the input, valid=$valid_cnt, invalid=$invalid_cnt\n";
    
    my $class_num = scalar (keys %$class2idx);
    my $feat_num = scalar (keys %$feat2idx);

    print STDERR "class_num=$class_num feat_num=$feat_num\n";
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



