#!/usr/bin/env perl

## created on 10/25/09
##  modified from 193/e/eb193.exec
##  (remove the GT smoothing part)

## Purpose: create LM models from ngram counts 

## usage: $0 ngram_count_file lm_output_file
##

use strict;

my $log10 = log(10);

main();

1;

##################################
sub main {
    if(@ARGV < 2){
	die "usage: $0 ngram_file lm_file {max_n}\n";
    }

    my $ngram_file = $ARGV[0];
    my $lm_output_file = $ARGV[1];

    my $max_ngram = 3;
    if(@ARGV > 2){
	$max_ngram = $ARGV[2];
    }

    open(my $input_fp, "$ngram_file") or die "cannot open $ngram_file\n";
    open(my $output_fp, ">$lm_output_file") or
	die "cannot create $lm_output_file\n";

    print STDERR "max_ngram=$max_ngram, ngram_file=$ngram_file\n";

    ######## step 1: initialize the arrays
    my @ngram_hash = (-1);
    my @ngram_N = (-1);  # the number of ngram tokens in the corpus 
    for(my $i=1; $i<=$max_ngram; $i++){
	push(@ngram_hash, {});
	push(@ngram_N, 0);
    }


    ############# step 2: read ngram files
    my $voc_size =  
	read_ngram_file($input_fp, $max_ngram, \@ngram_hash, \@ngram_N);

    print STDERR "voc_size=$voc_size\n";
    print STDERR "training size: \n";
    for(my $i=1; $i<=$max_ngram; $i++){
	print STDERR "$i-gram: ngram_token_num=$ngram_N[$i]\n";
    }
    

    ############ step 3: output the LM
    output_LM($output_fp, \@ngram_hash, \@ngram_N);
}


###### output LM
sub output_LM {
    my ($fp, $ngram_hash_ptr, $ngram_N_ptr) = @_;
    
    my $max_ngram = (scalar @$ngram_hash_ptr) - 1;
    my $unigram_N = 0;

    print $fp "\\data\\\n";
    
    for(my $i=1; $i<=$max_ngram; $i++){
	my $ptr = $ngram_hash_ptr->[$i];
	my $type_cnt = scalar (keys %$ptr);  # number of unique i-grams
	my $token_cnt = $ngram_N_ptr->[$i];  # the N for i-grams

	print $fp "ngram $i: type=$type_cnt token=$token_cnt\n";
    }

    ##### print out unigrams
    for(my $i=1; $i<2; $i++){
	print $fp "\n\\$i-grams:\n";
	my $ptr = $ngram_hash_ptr->[$i];
	
	my $unigram_N = $ngram_N_ptr->[$i];

	foreach my $key (sort {$ptr->{$b} <=> $ptr->{$a}} keys %$ptr){
	    my $cnt = $ptr->{$key};
	    my $prob = $cnt/$unigram_N;
	    my $logprob = log($prob)/$log10;
	    ## print $fp "$logprob\t$key\t$prob c=$cnt c'=$cprime\n";
	    print $fp "$cnt $prob $logprob $key\n";
	}
    }

    #### print out other ngrams
    for(my $i=2; $i<=$max_ngram; $i++){
	#### print out n-grams
	print $fp "\n\\$i-grams:\n";
	my $ptr = $ngram_hash_ptr->[$i];
	my $ptr1 = $ngram_hash_ptr->[$i-1];

	foreach my $key (sort {$ptr->{$b} <=> $ptr->{$a}} keys %$ptr){
	    my $cnt = $ptr->{$key};

	    my $key1 = $key;
	    $key1 =~ s/\s+\S+$//; ##remove w3
	    my $cnt1 = $ptr1->{$key1};
	    if(!defined($cnt1)){
		die "this should not happen: +$key1+ is not defined\n";
	    }

	    my $prob = $cnt/$cnt1;
	    my $logprob = log($prob)/$log10;
	    print $fp "$cnt $prob $logprob $key\n";
	}
    }

    print $fp "\n\\end\\\n";
    close($fp);

}



# read ngram files, and calculate Nc and store each type of ngram into hash
# read (voc_size, unigram_N)
#
sub read_ngram_file {
    my ($fp, $max_ngram, $hash_ptr, $ngram_N_ptr) = @_;
    
    my $voc_size = 0;  # set to be the number of unigram in the input file

    while(<$fp>){
	chomp;
	if(/^\s*$/){
	    next;
	}

	s/\s+$//;
	s/^\s+//;
	my $line = $_;
	my @parts = split(/\s+/,$line);
	if(scalar @parts < 2){
	    print STDERR "wrong format: +$line+\n";
	    next;
	}

	my $cnt = shift(@parts);
	my $cur_ngram_leng = scalar @parts;

	if($cur_ngram_leng > $max_ngram){
	    ## print STDERR "higher ngram ignored: +$line+\n";
	    next;
	}

	if($cur_ngram_leng == 1){
	    $voc_size ++;
	}

	$ngram_N_ptr->[$cur_ngram_leng] += $cnt;

	### add the ngram
	my $key = join(" ", @parts);
	my $ptr = $hash_ptr->[$cur_ngram_leng];
	$ptr->{$key} = $cnt;
    }
    
    return $voc_size;
}
