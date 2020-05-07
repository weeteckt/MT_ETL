#!/usr/bin/env perl

# created by Fei on 11/4/07

# The format is:
# state_num=nn
# sym_num=nn
# init_line_num=nn
# trans_line_num=nn
# emiss_line_num=nn
#
# \init
# state prob
#
# \transition
# from_state to_state prob
#
# \emission
# state symbol prob
#

use strict;

use Class::Struct;


## the input hmm file format is similar to the ARPA format
## 
################################################### class
#################  HMM
struct ( Hmm => {
    state_num  => '$',   # the number of states 
    sym_num    => '$',   # the number of output symbols

    
    trans_line_num => '$',  # the number of transitions
    emiss_line_num => '$',  # the number of emission
    
    #### mapping between string and index
    state2idx  => '%',   # state_str => state_idx
    idx2state  => '@',   # state_idx => state_str,  size N

    sym2idx    => '%',   # symbol_str => symbol_idx
    idx2sym    => '@',   # symbol_idx => symbol_str, size V

    ### check the constraints
    init_prob_sum => '$',  # the sum of init prob. Should be one. 
    trans_prob_sum => '@', # trans_prob_sum[i] is sum_j A[i][j], size N
    emiss_prob_sum => '@', # emiss_prob_sum[i] is sum_k B[i][k], size N 

    ### the probabilities: 
    ### Note we store the trans_prob and emiss_prob this way because we will
    ### use j to access a_ij, and k to access b_jk
    ###
    init_prob  => '%',   # the initial state prob init_prob->{i}
    trans_prob => '@',   # A[i][j] is stored as trans_prob[j] = "i1 p1 logp1 i2 p2 logp2 ...", size N
    emiss_prob => '@'    # B[j][k] is stored as emiss_prob[k] = "j1 p1 logp1 j2 p2 logp2...", size V
    }
	 );



####################################################### sub for Hmm

my $log10 = log(10);
my $inf = -1000000; 
my $eps = 0.01;   # for real number comparison. 

## test_hmm_main();


sub test_hmm_main {
    if(@ARGV != 2){
	die "usage: $0 input_hmm output_file\n";
    }
  
    my $input_file = $ARGV[0];
    my $output_file = $ARGV[1];

    open(my $input_fp, "$input_file") or die "cannot open $input_file\n";
    open(my $output_fp, ">$output_file") or die "cannot create $output_file\n";
    
    my $hmm = new Hmm;
    my $suc = read_hmm_from_file($input_fp, $hmm);

    output_hmm($output_fp, $hmm);
    close($output_fp);

    my $sent_num = 0;

    while(<STDIN>){
	chomp;
	if(/^\s*$/){
	    next;
	}

	s/^\s+//;
	s/\s+$//;

	my $line = $_;	

	$sent_num ++; 

	my @ids = ();
	my $unk_sym_idx = -1;
	my $unk_word_num = line_to_sym_idxes($line, $hmm, \@ids, $unk_sym_idx);
	if($unk_word_num > 0){
	    print STDERR "+$line+ contains unknown words\n";
	    next;
	}

	my @best_path = ();
	my $debug = 1;
	if($debug){
	    print "\n\n%%%%%%%%%% sent_num=$sent_num sent=$line\n\n";
	}

	my $state_seq = "";
	my $total_logprob = $inf;
	$suc = viterbi($hmm, \@ids, \@best_path, \$state_seq, 
		       \$total_logprob, $debug);
    }
}

###################################### Part 1: read hmm
sub init_hmm {
    my ($hmm) = @_;
    
    $hmm->state_num(0);
    $hmm->sym_num(0);

    ## $hmm->state2idx('{}');
    $hmm->sym2idx('()');
    ## $hmm->idx2state('{}');
    $hmm->idx2sym('()');

    $hmm->init_prob_sum(0);
    $hmm->trans_prob_sum('()');
    $hmm->emiss_prob_sum('()');

    $hmm->init_prob('{}');
    $hmm->trans_prob('()');
    $hmm->emiss_prob('()');
}



## return 1 if succeed, return 0 otherwise
## the format is "state prob"
sub add_init_prob {
    my ($hmm, $line) = @_;

    my @parts = split(/\s+/, $line);
    if(scalar @parts < 2){
	return 0;
    }

    my $state_str = $parts[0];
    my $prob = $parts[1];

    my $insert = 1;
    my $idx = state_str_to_idx($hmm, $state_str, $insert);

    my $tmp_val = $hmm->init_prob->{$idx};
    if(defined($tmp_val)){
	print STDERR "init prob for $state_str has been defined already with val $tmp_val. New value $prob is ignored\n";
	return 0;
    }else{
	if($prob <= 0){
	    print STDERR "prob=$prob. The init line +$line+ is ignored\n";
	    next;
	}
	my $logprob = log($prob)/$log10;

	$hmm->init_prob->{$idx} = "$prob $logprob";
	$hmm->init_prob_sum($hmm->init_prob_sum + $prob);
	return 1;
    }
}

## return 1 if succeed, return 0 otherwise
## the format is "from_state to_state prob"
sub add_trans_prob {
    my ($hmm, $line) = @_;

    my @parts = split(/\s+/, $line);
    if(scalar @parts < 3){
	return 0;
    }
    
    my $from_state_str = $parts[0];
    my $to_state_str = $parts[1];
    my $prob = $parts[2];

    my $insert = 1;
    my $from_state_idx = state_str_to_idx($hmm, $from_state_str, $insert);
    my $to_state_idx = state_str_to_idx($hmm, $to_state_str, $insert);

    my $state_num = $hmm->state_num;
    if($from_state_idx >= $state_num || $to_state_idx >= $state_num){
	die "this should never happen: $from_state_idx >= $state_num or $to_state_idx >= $state_num\n";
    }

    if($prob <= 0){
	print STDERR "prob=$prob. The transition line +$line+ is ignored\n";
	return 0;
    }

    my $logprob = log($prob)/$log10;

    $hmm->trans_prob->[$to_state_idx] .= "$from_state_idx $prob $logprob ";
    $hmm->trans_prob_sum->[$from_state_idx] += $prob;

    return 1;
}


## return 1 if succeed, return 0 otherwise
## the format is "state symbol prob"
sub add_emission_prob {
    my ($hmm, $line) = @_;

    my @parts = split(/\s+/, $line);
    if(scalar @parts < 3){
	return 0;
    }
    
    my $state_str = $parts[0];
    my $sym_str = $parts[1];
    my $prob = $parts[2];

    my $insert = 1;
    my $state_idx = state_str_to_idx($hmm, $state_str, $insert);
    my $sym_idx = sym_str_to_idx($hmm, $sym_str, $insert);

    my $state_num = $hmm->state_num;
    if($state_idx >= $state_num){
	die "add_emiss_prob state_idx: $state_idx >= $state_num\n";
    }

    my $sym_num = $hmm->sym_num;
    if($sym_idx >= $sym_num){
	die "add_emiss_prob sym_idx: $sym_idx >= $sym_num\n";
    }

    if($prob <= 0){
        if($prob < 0){
	   print STDERR "prob=$prob. The emission line +$line+ is ignored\n";
           return 0;
        }else{
	   return 1;
        }
    }

    my $logprob = log($prob)/$log10;

    $hmm->emiss_prob->[$sym_idx] .= "$state_idx $prob $logprob ";
    
    $hmm->emiss_prob_sum->[$state_idx] += $prob;
    return 1;
}


# return sym_index
sub sym_str_to_idx {
    my ($hmm, $sym_str, $insert) = @_;

    my $ptr = $hmm->sym2idx;
    my $idx = $ptr->{$sym_str};
    if(defined($idx)){
	return $idx;
    }

    if($insert){
	$idx = $hmm->sym_num;
	$hmm->sym_num($idx+1);
	$hmm->sym2idx->{$sym_str} = $idx;
	
	$ptr = $hmm->idx2sym;
	push(@$ptr, $sym_str);
	
	$ptr = $hmm->emiss_prob;
	push(@$ptr, "");
	
	return $idx;
    }else{
	return -1;
    }
}

### symbol idx => symbol str
sub sym_idx_to_str {
    my ($hmm, $idx) = @_;
    if(($idx >= $hmm->sym_num) || ($idx < 0)){
	my $t1 = $hmm->sym_num;
	die "sym_idx_to_str error: $idx >= $t1\n";
    }

    my $str = $hmm->idx2sym->[$idx];
    return $str;
}


### state idx => state str
sub state_idx_to_str {
    my ($hmm, $idx) = @_;
    if(($idx >= $hmm->state_num) || ($idx < 0)){
	my $t1 = $hmm->state_num;
	die "state_idx_to_str error: $idx >= $t1\n";
    }

    my $str = $hmm->idx2state->[$idx];
    return $str;
}

## return state_idx
sub state_str_to_idx {
    my ($hmm, $state_str, $insert) = @_;
    my $ptr = $hmm->state2idx;
    my $idx = $ptr->{$state_str};
    if(defined($idx)){
	return $idx;
    }

    if($insert){
	$idx = $hmm->state_num;
	$hmm->state_num($idx+1);
	
	my $ptr1 = $hmm->state2idx;
	$ptr1->{$state_str} = $idx;
	
	$ptr1 = $hmm->idx2state;
	push(@$ptr1, $state_str);
    
	$ptr1 = $hmm->trans_prob_sum;
	push(@$ptr1, 0);

	$ptr1 = $hmm->emiss_prob_sum;
	push(@$ptr1, 0);

	$ptr1 = $hmm->trans_prob;
	push(@$ptr1, "");

	return $idx;
    }else{
	return -1;
    }
}

## return 1 if succeed, return 0 otherwise
##
##
sub read_hmm_from_file {
    my ($fp, $hmm) = @_;

    my $init_line_num = 0;
    my $trans_line_num = 0;
    my $emission_line_num = 0;

    my $real_init_line_num = 0;
    my $real_trans_line_num = 0;
    my $real_emiss_line_num = 0;

    my $state_num = 0;
    my $sym_num = 0;

    my $line_num = 0;
    
    my $stage = 0;
    my $INIT_STAGE = 1;
    my $TRANS_STAGE = 2;
    my $EMISSION_STAGE = 3;

    #### step 1: initialization
    init_hmm($hmm);

    ### step 2: read lines
    while(<$fp>){
	chomp;
	$line_num ++;

	if($line_num % 100000 == 0){
	    my $t1 = $line_num/1000;
	    print STDERR "Finish reading $t1 K lines\n";
	}

	if(/^\s*$/){
	    next;
	}

	s/\s+$//;
	s/^\s+//;
	
	my $line = $_;

	if($line =~ /^state_num=(\d+)$/i){
	    $state_num = $1;
	    next;
	}

	if($line =~ /^sym_num=(\d+)$/i){
	    $sym_num = $1;
	    next;
	}

	if($line =~ /^init_line_num=(\d+)$/i){
	    $init_line_num = $1;
	    next;
	}

	if($line =~ /^trans_line_num=(\d+)$/i){
	    $trans_line_num = $1;
	    next;
	}

	if($line =~ /^emiss_line_num=(\d+)$/i){
	    $emission_line_num = $1;
	    next;
	}

	if($line =~ /^\\init\\?$/i){
	    $stage = $INIT_STAGE;
	    next;
	}

	if($line =~ /^\\transition$/i){
	    $stage = $TRANS_STAGE;
	    next;
	}

	if($line =~ /^\\emission$/i){
	    $stage = $EMISSION_STAGE;
	    next;
	}

	if($line =~/^\\[a-z]+\\?$/){
	    # e.g., \data\, \end\
	    next;
	}

	### deal with the content line
	my $res = 0;
	if($stage == $INIT_STAGE){
	    $res = add_init_prob($hmm, $line);
	    if($res){
		$real_init_line_num ++;
	    }

	}elsif($stage == $TRANS_STAGE){
	    $res = add_trans_prob($hmm, $line);
	    if($res){
		$real_trans_line_num ++;
	    }
	}elsif($stage == $EMISSION_STAGE){
	    $res = add_emission_prob($hmm, $line);
	    if($res){
		$real_emiss_line_num ++;
	    }
	}

	if(!$res){
	    print STDERR "skip line with wrong format: stage=$stage, line=+$line+\n";
	}
	    
    }

    ### step 3: check line numbers
    check_line_num("state_num", $state_num, $hmm->state_num);
    check_line_num("sym_num", $sym_num, $hmm->sym_num);

    check_line_num("init_line_num", $init_line_num, $real_init_line_num);
    check_line_num("trans_line_num", $trans_line_num, $real_trans_line_num);
    check_line_num("emission_line_num", $emission_line_num, 
		   $real_emiss_line_num);

    $hmm->trans_line_num($real_trans_line_num);
    $hmm->emiss_line_num($real_emiss_line_num);

    #### step 4: check probability
    my $warning_num = check_hmm_prob_constraints($hmm);

    return 1;
}



sub check_line_num {
    my ($str, $num1, $num2) = @_;
    if($num1 != $num2){
	print STDERR "warning: different numbers of $str: claimed=$num1, real=$num2\n";
    }else{
	print STDERR "$str=$num1\n";
    }
}

## return the number of warnings
sub check_hmm_prob_constraints {
    my ($hmm) = @_;
    
    my $warning_num = 0;
    if($hmm->init_prob_sum != 1){
	my $t1 = $hmm->init_prob_sum;
	print STDERR "warning: init_prob_sum=$t1, not equal to 1\n";
	$warning_num ++;
    }

    ### check trans_prob
    my $ptr = $hmm->trans_prob_sum;
    for(my $i=0; $i<scalar (@$ptr); $i++){
	my $val = $ptr->[$i];
	if(($val < 1-$eps) || ($val > 1+$eps)){
	    my $state_str = $hmm->idx2state->[$i];
	    print STDERR "warning: the trans_prob_sum for state $state_str is $val\n";
	    $warning_num ++;
	}
    }

    ### check the emission prob
    $ptr = $hmm->emiss_prob_sum;
    for(my $i=0; $i<scalar (@$ptr); $i++){
	my $val = $ptr->[$i];
	if(($val < 1 - $eps) || ($val > 1+$eps)){
	    my $state_str = $hmm->idx2state->[$i];
	    print STDERR "warning: the emiss_prob_sum for state $state_str is $val\n";
	    $warning_num ++;
	}
    }

    return $warning_num;
}



################################### Part 2: print out the hmm
sub output_hmm {
    my ($fp, $hmm) = @_;

    ##### step 1: header
    print $fp "state_num=", $hmm->state_num, "\n";
    print $fp "sym_num=", $hmm->sym_num, "\n";

    my $ptr = $hmm->init_prob;
    my $num = scalar (keys %$ptr);
    print $fp "init_line_num=$num\n";

    $num = $hmm->trans_line_num;
    print $fp "trans_line_num=$num\n";

    $num = $hmm->emiss_line_num;
    print $fp "emiss_line_num=$num\n\n";

    ##### step 2: init, sorted by the prob
    print $fp "\\init\n";
    $ptr = $hmm->init_prob;
    foreach my $key (sort {$ptr->{$b} <=> $ptr->{$a}} keys %$ptr){
	my $prob_str = $ptr->{$key};
	my $state_str = state_idx_to_str($hmm, $key);
	print $fp "$state_str\t$prob_str\n";
    }

    ####### step 3: transmission prob, sorted by to-state
    print $fp "\n\\transition\n";
    $ptr = $hmm->trans_prob;
    for(my $to_state=0; $to_state<scalar (@$ptr); $to_state++){
	my $str = $ptr->[$to_state];
	$str =~ s/\s+$//;
	my @parts = split(/\s+/, $str);
	my $part_num = scalar @parts;
	if($part_num % 3 != 0){
	    die "this should never happen: $part_num parts in +$str+\n";
	}
	
	my $to_state_str = state_idx_to_str($hmm, $to_state);

	## print $fp "\n\n to_state=$to_state_str part_num=$part_num +$str+\n";
	for(my $i=0; $i<$part_num; $i+=3){
	    my $from_state_idx = $parts[$i];
	    my $prob = $parts[$i+1];
	    my $logprob = $parts[$i+2];
	    my $from_state_str = state_idx_to_str($hmm, $from_state_idx);
	    print $fp "$from_state_str\t$to_state_str\t$prob\t$logprob\n";
	}
    } 

    ###### emission prob
    print $fp "\n\\emission\n";
    $ptr = $hmm->emiss_prob;
    for(my $sym=0; $sym<scalar (@$ptr); $sym++){
	my $str = $ptr->[$sym];
	$str =~ s/\s+$//;
	my @parts = split(/\s+/, $str);
	my $part_num = scalar @parts;
	if($part_num % 3 != 0){
	    die "this should never happen: $part_num parts in +$str+\n";
	}
	
	my $sym_str = sym_idx_to_str($hmm, $sym);

	for(my $i=0; $i<$part_num; $i+=3){
	    my $state_idx = $parts[$i];
	    my $prob = $parts[$i+1];
	    my $logprob = $parts[$i+2];
	    my $state_str = state_idx_to_str($hmm, $state_idx);
	    print $fp "$state_str\t$sym_str\t$prob\t$logprob\n";
	}
    } 

}


########################### step 3: Viterbi algorithm
# return the number of unknown words in the sent
sub line_to_sym_idxes {
    my ($line, $hmm, $ptr, $unk_sym_idx) = @_;

    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    @$ptr = ();

    my $res = 0;
    my @parts = split(/\s+/, $line);
    my $insert = 0;
    for my $part (@parts){
	my $sym_idx = sym_str_to_idx($hmm, $part, $insert);
	if($sym_idx < 0){
	    push(@$ptr, $unk_sym_idx);
	    $res ++;
	}else{
	    push(@$ptr, $sym_idx);
	}
    }

    return $res;
}

## return 1 if the best path is found.
## return 0 otherwise
##
## given a hmm and observation, calculate the best_path and total logprob
sub viterbi {
    my ($hmm, $observ, $best_path, $state_seq_ptr, 
	$total_logprob_ptr, $debug) = @_;
    

    my @init_logprob = ();  # the init logprob
    my @bk_2D = ();         # store backtrack pointers
    my @val_2D = ();        # val_2D[t][j] stores logprob delta_j(t)
                            # init prob \pi(t) is not stored in val_2D.

    ##### calculating and displaying trellis 
    my $res = calc_delta_func($hmm, $observ, $best_path, $total_logprob_ptr,
			      \@init_logprob, \@val_2D, \@bk_2D); 

    if($debug){
	my $is_prob = 0;
	display_trellis_w_backptr($hmm, $observ, \@init_logprob,
				  \@val_2D, \@bk_2D, $is_prob);
    }
	
    if(!$res){
	if($debug){
	    print "Cannot find the best path\n";
	}
	return 0;
    }

    ####### get the best state sequence
    my $include_word = 0;
    $res = get_best_state_sequence($hmm, $observ, $best_path, 
				   $state_seq_ptr, $include_word);
    
    if($debug){
	print "==> the best path=", join(" ", @$best_path), "\n";
	print "==> tag sequence=$$state_seq_ptr\n"; 
	print "==> logprob=$$total_logprob_ptr\n";
    }
 
    return 1;
}


## return success. It should always succeed.
##
## given a hmm and observation, calculate the prob of the observ
sub get_lm_score {
    my ($hmm, $observ, $total_prob_ptr, $debug) = @_;

    my @init_prob = ();  # the init logprob
    my @val_2D = ();        # val_2D[t][j] stores logprob delta_j(t)
                            # init prob \pi(t) is not stored in val_2D.

    ##### calculating and displaying trellis 
    my $res = calc_alpha_func($hmm, $observ, $total_prob_ptr,
			      \@init_prob, \@val_2D); 

    if($debug){
	my $is_prob = 1;
	display_trellis($hmm, $observ, \@init_prob, \@val_2D, $is_prob);
    }
	
    return 1;
}



# return 1 if there is at least one surviving path.
# return 0 otherwise
#
# calc the forward function
# modified from calc_delta_func(), replacing max with the sum
#  and replace all the logprob with probs.
#
sub calc_alpha_func {
    my ($hmm, $observ, $total_prob_ptr,
	$init_prob_ptr, $val_2D) = @_;

    @$init_prob_ptr = ();
    @$val_2D = ();
    
    my $leng = scalar (@$observ);

    my $state_num = $hmm->state_num;
    my $init_prob = $hmm->init_prob;

    my @cur_vals = ();  # cur_vals[j] stores alpha_j(t) at iteration t

    #### initialize with the inital prob: when t=1
    for(my $i=0; $i<$state_num; $i++){
	## i is the state_idx
	my $val_str = $init_prob->{$i};
	if(defined($val_str)){
	    my @parts = split(/\s+/, $val_str);
	    push(@cur_vals, $parts[0]);
	}else{
	    push(@cur_vals, 0);
	}
    }

    @$init_prob_ptr = @cur_vals;

    #### recursion: from delta(t), calc delta(t+1)
    for(my $t=0; $t<$leng; $t++){
	############ (a): find j where b_{j, Ot} > 0
	my $Ot = $observ->[$t];
	my $str = $hmm->emiss_prob->[$Ot];

	$str =~ s/\s+$//;
	my @parts = split(/\s+/, $str);
	my $part_num = scalar @parts;
	my %emiss_probs = ();  # b_{j, O_t}
	
	for(my $i=0; $i<$part_num; $i+=3){
	    my $j = $parts[$i];
	    my $prob = $parts[$i+1];
	    $emiss_probs{$j} = $prob;  # b_{j,Ot}
	}

	my @new_vals = ();  # new_vals[j] stores delta_j(t)

	for(my $j=0; $j<$state_num; $j++){
	    ############# (b) for each j, calc delta_j(t+1)
	    my $emiss_prob = $emiss_probs{$j};
	    if(!defined($emiss_prob)){
		push(@new_vals, 0);
		next;
	    }

	    $str = $hmm->trans_prob->[$j];
	    @parts = split(/\s+/, $str);
	    $part_num = scalar @parts;

	    my $sum = 0;
	    for(my $m=0; $m<$part_num; $m+=3){
		my $i = $parts[$m];
		my $trans_prob = $parts[$m+1];  # log a_ij
		my $tmp_val = $cur_vals[$i] * $trans_prob * $emiss_prob;
		if($tmp_val < 0){
		    die "this should never happen: tmp_val=$tmp_val\n";
		}
		$sum += $tmp_val;
	    }
	    
	    push(@new_vals, $sum);
	}  # end for each j

	push(@$val_2D, [@new_vals]);
	@cur_vals = @new_vals;
    } # end for each t


    ####### get the sum of the last column
    my $ret_val = 0;
    foreach my $val (@cur_vals){
	$ret_val += $val;
    }

    $$total_prob_ptr = $ret_val;

    return 1;
}



# return 1 if there is at least one surviving path.
# return 0 otherwise
sub calc_delta_func {
    my ($hmm, $observ, $best_path, $total_logprob_ptr,
	$init_logprob, $val_2D, $bk_2D) = @_;

    @$init_logprob = ();
    @$val_2D = ();
    @$bk_2D = ();
    @$best_path = ();
    
    my $leng = scalar (@$observ);

    my $state_num = $hmm->state_num;
    my $init_prob = $hmm->init_prob;

    my @cur_vals = ();  # cur_vals[j] stores delta_j(t) at iteration t

    #### initialize with the inital prob: when t=1
    for(my $i=0; $i<$state_num; $i++){
	## i is the state_idx
	my $val_str = $init_prob->{$i};
	if(defined($val_str)){
	    my @parts = split(/\s+/, $val_str);
	    push(@cur_vals, $parts[1]);
	}else{
	    push(@cur_vals, $inf);
	}
    }

    @$init_logprob = @cur_vals;

    #### recursion: from delta(t), calc delta(t+1)
    for(my $t=0; $t<$leng; $t++){
	############ (a): find j where b_{j, Ot} > 0
	my $Ot = $observ->[$t];
	my $str = $hmm->emiss_prob->[$Ot];

	$str =~ s/\s+$//;
	my @parts = split(/\s+/, $str);
	my $part_num = scalar @parts;
	my %log_emiss_probs = ();  # b_{j, O_t}

	for(my $i=0; $i<$part_num; $i+=3){
	    my $j = $parts[$i];
	    my $logprob = $parts[$i+2];
	    $log_emiss_probs{$j} = $logprob;  # b_{j,Ot}
	}

	my @new_vals = ();  # new_vals[j] stores delta_j(t)
	my @bk_1D = ();     # the i for each j at time t

	for(my $j=0; $j<$state_num; $j++){
	    ############# (b) for each j, calc delta_j(t+1)
	    my $emiss_logprob = $log_emiss_probs{$j};
	    if(!defined($emiss_logprob)){
		push(@new_vals, $inf);
		push(@bk_1D, "");
		next;
	    }

	    $str = $hmm->trans_prob->[$j];
	    @parts = split(/\s+/, $str);
	    $part_num = scalar @parts;

	    my $max = $inf;
	    my $bk_i = "";    # i for backtracking
	    for(my $m=0; $m<$part_num; $m+=3){
		my $i = $parts[$m];
		my $trans_logprob = $parts[$m+2];  # log a_ij
		my $tmp_val = $cur_vals[$i] + $trans_logprob + $emiss_logprob;
		if($max < $tmp_val){
		    $max = $tmp_val;
		    $bk_i = "$i $cur_vals[$i] $trans_logprob $emiss_logprob";
		}
	    }
	    
	    push(@new_vals, $max);
	    push(@bk_1D, $bk_i);
	}  # end for each j

	push(@$val_2D, [@new_vals]);
	push(@$bk_2D, [@bk_1D]);

	@cur_vals = @new_vals;
    } # end for each t

    
    ###### backtracking
    my $max_i = 0;
    my $max = $cur_vals[0];

    for(my $i=1; $i<scalar @cur_vals; $i++){
	my $tmp_val = $cur_vals[$i];
	if($tmp_val > $max){
	    $max_i = $i;
	    $max = $tmp_val;
	}
    }

    if($max <= $inf){
	return 0;
    }

    $$total_logprob_ptr = $max;

    my $res = backtrack_trellis($bk_2D, $max_i, $best_path);

    return $res;
}



### return suc. 
###  Given hmm, observ and best_path, 
###  $$state_seq_ptr is "t0 o1 t1 o2 t2 ..." or "t0 t1 t2 ..."
###  $$logprob_ptr is the logprob.
###
sub get_best_state_sequence {
    my ($hmm, $observ, $best_path, 
	$state_seq_ptr, $include_observ) = @_;
    
    my $leng = scalar @$observ;
    my $leng1 = scalar @$best_path; 

    if($leng + 1 != $leng1){
	print STDERR "get_best_tag_seq error: $leng + 1 != $leng1\n";
	return "";
    }

    my $res = state_idx_to_str($hmm, $best_path->[0]); # the X0 

    
    for(my $i=0; $i<$leng; $i++){
	my $sym_idx = $observ->[$i];
	my $state_idx = $best_path->[$i+1];
	my $sym_str = sym_idx_to_str($hmm, $sym_idx);
	my $state_str = state_idx_to_str($hmm, $state_idx);

	if($include_observ){
	    $res .= " $sym_str $state_str";
	}else{
	    $res .= " $state_str";
	}
    }

    $$state_seq_ptr = $res;

    return 1;
}

## max_i_to_start is the max_i for the last column in the trellis
## the "path" is stored in ret_val.  There are n+1 points in ret_val,
## where n is the sentence length.
##
## return 1 if succeed. return 0 otherwise.
##
sub backtrack_trellis {
    my ($bk_2D_ptr, $max_i_to_start, $ret_val) = @_;

    my @arr = ();
    
    my $leng = scalar (@$bk_2D_ptr);

    my $cur_max_i = $max_i_to_start;
    push(@arr, $cur_max_i);

    for(my $j=$leng-1; $j>=0; $j--){
	my $bk_1D_ptr = $bk_2D_ptr->[$j];
	my $prev_i_str = $bk_1D_ptr->[$cur_max_i];
	if($prev_i_str =~ /^(\d+)/){
	    $cur_max_i = $1;
	    push(@arr, $cur_max_i);
	}else{
	    return 0;
	}
    }

    @$ret_val = reverse(@arr);
    return 1;
}



### show the whole trellis. We use it for debug purpose.
sub display_trellis_w_backptr {
    my ($hmm, $observ, $init_ptr, $val_2D_ptr, $bk_2D_ptr, $is_prob) = @_;

    print "\n%%%%% Init prob:\n";
    for(my $i=0; $i<scalar @$init_ptr; $i++){
	my $val = $init_ptr->[$i];
	if( ($is_prob && $val <= 0) ||
	    (!$is_prob && $val <= $inf) ){
	    next;
	}
	my $state_str = state_idx_to_str($hmm, $i);
	print "state_idx=$i\t$state_str\t$val\n";
    }

    print "\n";

    my $leng = scalar (@$observ);
    
    for(my $t=0; $t<$leng; $t++){
	##### print the column at time t
	my $val_1D = $val_2D_ptr->[$t];
	my $bk_1D = $bk_2D_ptr->[$t];

	my $sym_idx = $observ->[$t];
	my $sym_str = sym_idx_to_str($hmm, $sym_idx);

	print "%%%% t=$t symbol=$sym_str\n";
	for(my $i=0; $i<scalar @$val_1D; $i++){
	    my $val = $val_1D->[$i];
	    my $bk = $bk_1D->[$i];
	    if( ($is_prob && $val <= 0) ||
		(!$is_prob && $val <= $inf) ){
		next;
	    }
	    my $state_str = state_idx_to_str($hmm, $i);

	    print "state_idx=$i\t$state_str\t$val";
	    my @parts = split(/\s+/, $bk);
	    if(scalar @parts > 3){
		my $add = $parts[2] + $parts[3];
		my $new_val = $parts[1] + $add;
		print " i=$parts[0] \#\# prev_val=$parts[1] trans=$parts[2] emiss=$parts[3] add=$add new_val=$new_val\n\n";
	    }
	}
    }
}


### show the whole trellis. We use it for debug purpose.
sub display_trellis {
    my ($hmm, $observ, $init_ptr, $val_2D_ptr, $is_prob) = @_;

    print "\n%%%%% Init prob:\n";
    for(my $i=0; $i<scalar @$init_ptr; $i++){
	my $val = $init_ptr->[$i];
	if( ($is_prob && $val <= 0) ||
	    (!$is_prob && $val <= $inf) ){
	    next;
	}
	my $state_str = state_idx_to_str($hmm, $i);
	print "state_idx=$i\t$state_str\t$val\n";
    }

    print "\n";

    my $leng = scalar (@$observ);
    
    for(my $t=0; $t<$leng; $t++){
	##### print the column at time t
	my $val_1D = $val_2D_ptr->[$t];

	my $sym_idx = $observ->[$t];
	my $sym_str = sym_idx_to_str($hmm, $sym_idx);

	print "\n%%%% t=$t symbol=$sym_str\n";
	for(my $i=0; $i<scalar @$val_1D; $i++){
	    my $val = $val_1D->[$i];
	    if( ($is_prob && $val <= 0) ||
		(!$is_prob && $val <= $inf) ){
		next;
	    }
	    my $state_str = state_idx_to_str($hmm, $i);

	    print "state_idx=$i\t$state_str\t$val\n";
	}
    }
}


1;
