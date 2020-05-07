#!/usr/bin/env perl

## created on 10/26/09, modified from 193/e/ee193.exec

## Purpose: calculate the perplexity of test data with interpolation.
##

## usage: $0 lm_file l1 l2 l3 test_file output_file
##

use strict;

############ smoothing methods
my $debug = 0;

############# default strings
my $BOS_str = "<s>";
my $EOS_str = "</s>";

my $delim = " "; # delim to separate words in a n-gram

my $log10 = log(10);

main();

1;

##################################
sub main {

    if(@ARGV != 6){
	die "usage: $0 lm_file l1 l2 l3 test_file output_file\n";
    }

    my $lm_file = $ARGV[0];
    my $l1 = $ARGV[1];
    my $l2 = $ARGV[2];
    my $l3 = $ARGV[3];
    my $test_file = $ARGV[4];
    my $output_file = $ARGV[5];

    my $max_ngram = 3;

    my @lambdas = (-1, $l1, $l2, $l3);

    print STDERR "max_ngram=$max_ngram\n";
    print STDERR "lambdas: ", join(" ", @lambdas[1..$max_ngram]), "\n";

    open(my $lm_fp, "$lm_file") or die "cannot open $lm_file\n";
    open(my $test_fp, "$test_file") or die "cannot open $test_file\n";

    open(my $output_fp, ">$output_file") or 
	die "cannot create output file $output_file\n";

    ######## step 1: read the LM
    my %ngram_prob_hash = ();

    my $suc = read_lm($lm_fp, \%ngram_prob_hash);

    if(!$suc){
	print STDERR "read_lm failed\n";
	return 0;
    }

    ############# step 2: read ngram files
    calc_perplex($test_fp, $max_ngram, \%ngram_prob_hash, \@lambdas,
		 $output_fp);
}



### two cases:
###  (1) cur_ngram=2, $key is "w1 w2 w3"
###      prob(w3 | w1, w2) = l1*P(w3) + l2*P(w3|w2) + l3*P(w3|w1,w2)
###
###  (2) cur_ngram=3, $key is "<s> w1"
###      prob(w1 |BOS) = l1*P(w1) + (l2+l3)*P(w1 |BOS)
###
### return lg(prob)
### if prob is zero, return "-inf"
###
sub get_ngram_logprob {
    my ($key, $cur_ngram, $prob_hash_ptr, $lambda_ptr) = @_;

    my $prob_sum = 0;
    
    
    for(my $i=$cur_ngram; $i>=1; $i--){
	my $tmp_prob = $prob_hash_ptr->{$i}->{$key};

	if(!defined($tmp_prob)){
	    $tmp_prob = 0;
	}

	my $cur_l = $lambda_ptr->[$i];

	my $tmp = $tmp_prob * $cur_l;
	if($cur_ngram == 2 && $i==2){
	    ### deal with P(w | BOS)
	    $tmp = $tmp_prob * ($lambda_ptr->[$i+1] + $cur_l);
	}

	$prob_sum += $tmp;

	$key =~ s/^\S+\s+//;  # to remove w_i from the beginning
    }

    my $logprob = "-inf3";

    if($prob_sum > 0){
	$logprob = log($prob_sum)/$log10;
    }

    ## print STDOUT "$key $logprob\n";
    return $logprob;
}


############### Calculate perplexity of the whole test corpus.
sub calc_perplex {
    my ($test_fp, $max_ngram, $prob_hash_ptr, $lambda_ptr,
	$output_fp) = @_;

    my $sent_num = 0;
    my $line_num = 0; # including blank lines

    my $total_word_num = 0;
    my $total_oov_num = 0;
    my $total_zeroprob_num = 0;
    my $total_logprob = 0;

    my $voc = $prob_hash_ptr->{1}; # voc = words in unigram hash

    while(<$test_fp>){
	chomp;
	$line_num ++;
	if(/^\s*$/){
	    next;
	}

	s/^\s+//;
	s/\s+$//;

	$sent_num ++;

	my $line = $BOS_str . " " . $_. " " . $EOS_str;
	my @words = split(/\s+/, $line);
	my $word_num = (scalar @words) - 2; # include BOS and EOS

	my $oov_num = 0;
	my $logprob = 0;

	print $output_fp "\n\nSent \#$sent_num: $line\n";

	for (my $i=1; $i<$word_num+2; $i++){
	    # P(w1|BOS) P(w2 | BOS, w1) ... P(w_n | ...) P(EOS | ..., wn)
	    my $j = $i - $max_ngram + 1;
	    if($j < 0){
		$j = 0;
	    }
	    my $cur_ngram = $i - $j + 1;
	    my $cur_word = $words[$i];
	    
	    my $i1 = $i-1;
	    my $cond_str = join($delim, @words[$j..$i1]);	    

	    my $display_str = "$i: log P($cur_word | $cond_str) = ";
	    if(!defined($voc->{$cur_word})){
		## w3 is unknown
		$oov_num ++;
		$display_str .= "-inf (unknown word)"; 
	    }else{
		my $key = $cond_str . $delim . $cur_word;
		my $tmp_logprob = 
		    get_ngram_logprob($key, $cur_ngram,
				      $prob_hash_ptr, $lambda_ptr);
		
		if($tmp_logprob =~ /^\-?\d+/){
		    $display_str .= "$tmp_logprob";
		    if(!defined($prob_hash_ptr->{$cur_ngram}->{$key})){
			$display_str .= " (unseen ngrams)";
		    }
		    $logprob += $tmp_logprob;
		}else{
		    $display_str .= " = -inf2"; ## this should never happen
		    $oov_num ++;
		}
	    }

	    print $output_fp "$display_str\n";
	} # end of each sentence
	
	print $output_fp "1 sentence, $word_num words, $oov_num OOVs\n";
	my $N = 1 + $word_num - $oov_num;
	my $ppl = 10 ** (-$logprob/$N);
	print $output_fp "logprob=$logprob ppl=$ppl\n\n";

	$total_oov_num += $oov_num;
	$total_word_num += $word_num;
	$total_logprob += $logprob;
    }

    print $output_fp "\n\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
    print $output_fp "sent_num=$sent_num word_num=$total_word_num oov_num=$total_oov_num\n";
    my $N = $sent_num + $total_word_num - $total_oov_num;
    my $ave = $total_logprob/$N;
    my $ppl = 10 ** (-$ave);
    print $output_fp "logprob=$total_logprob ave_logprob=$ave ppl=$ppl\n";

    print STDERR "sent_num=$sent_num word_num=$total_word_num oov_num=$total_oov_num\n";
    print STDERR "logprob=$total_logprob ave_logprob=$ave ppl=$ppl\n";
}



### return suc
## logprob_hash_ptr stores log P(w_i | w_1 ..., w_{i-1})
##
sub read_lm {
    my ($fp, $prob_hash_ptr) = @_;
    
    my %ngram_num1 = ();  # numbers according to the header 
    my %ngram_num2 = ();  # numbers according to the file

    my $cur_ngram = -1;
    my $cur_cnt = 0;

    my $cur_prob_hash = "";

    my $line_num = 0;
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
	
	### "ngram 1: type=5171 token=25551"
	if($line =~ /^ngram\s+(\d+)\:\s*type=(\d+)\s+token=(\d+)/){
	    ## ngram 2=346198 
	    my $key = $1;
	    my $num = $2;

	    $ngram_num1{$key} = $num;
	    next;
	}

	## e.g., \data\
	if($line =~ /^\\[a-z]+\\\s*$/){
	    next;
	}

	## e.g., \1-grams:
	if($line =~ /^\\(\d+)\-grams\:/i){
	    if($cur_cnt != 0){
		$ngram_num2{$cur_ngram} = $cur_cnt;
		$cur_cnt = 0;
	    }
	    $cur_ngram = $1;

	    $prob_hash_ptr->{$cur_ngram} = {};
	    $cur_prob_hash = $prob_hash_ptr->{$cur_ngram};

	    next;
	}

	### the format is "cnt prob logprob key"
	if($line=~ /^(\d+)\s+/){
	    my @parts = split(/\s+/, $line);
	    if(scalar @parts < 4){
		print STDERR "wrong format: +$line+\n";
		next;
	    }

	    my $cnt = shift(@parts);
	    my $prob = shift(@parts);
	    my $logprob = shift(@parts);
	    my $key = join(" ", @parts);
	    my $tmp = scalar @parts;

	    if($tmp != $cur_ngram){
		print STDERR "wrong format: +$line+ $tmp != $cur_ngram\n";
		next;
	    }
	    
	    $cur_prob_hash->{$key}= $prob;

	    $cur_cnt ++;
	    next;
	}

	print STDERR "unknown format: +$line+\n";
    }

    if($cur_cnt != 0){
	$ngram_num2{$cur_ngram} = $cur_cnt;
	$cur_cnt = 0;
    }

    print STDERR "According to the header:\n";
    foreach my $key (sort keys %ngram_num1){
	print STDERR "$key-gram = $ngram_num1{$key}\n";
    }

    print STDERR "read the following from the file:\n";
    foreach my $key (sort keys %ngram_num2){
	print STDERR "$key-gram = $ngram_num2{$key}\n";
    }
    

    print STDERR "Finish reading the LM file\n";

    return 1;
}
