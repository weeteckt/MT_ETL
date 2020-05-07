#!/usr/bin/env perl

## Purpose: trainer for a unigram POS tagger
##
## $0 training_data output_fsa
##
## training_data has the format: 
##  w1/t1 w2/t2 ...
##
## output_fsa has the format: 
##  S
##  (S (S t w prob))
##

## Remember to replace " with -QUOTE- 

use strict;

main();

1;


##############################################
sub main {
    if(@ARGV != 2){
	die "usage: $0 training_file output_fst\n";
    }

    my $training_file = $ARGV[0];
    my $fst_file = $ARGV[1];

    #### step 1: collect counts
    my $cmd = "cat $training_file | ca193.exec > $fst_file.prob";
    system($cmd);

    #### step 2: build FST
    $cmd = "cat $fst_file.prob | cb193.exec > $fst_file";
    system($cmd);
}



	

