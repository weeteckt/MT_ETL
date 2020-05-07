#!/usr/bin/env perl

## Purpose: decoder for a unigram POS tagger
## created on 10/12/09
##
## $0 fst test_data sys_output
##
## test_data has the format: 
##  w1 w2 ...
##
## the sys_output has the format: 
##  w1/t1 ... wn/tn prob
##

## Remember to replace " with -QUOTE- 

use strict;

main();

1;


##############################################
sub main {
    if(@ARGV != 3){
	die "usage: $0 fst test_file sys_output\n";
    }

    my $fst_file = $ARGV[0];
    my $test_file = $ARGV[1];
    my $sys_output = $ARGV[2];

    my $path_file = "$sys_output.path";
    my $path_log_file = "$sys_output.path.log";

    #### step 1: preprocess the test data and run Carmel
    my $cmd = "cat $test_file | aac100.exec | carmel -b -k 1 -sli ~/dt_NB_data/193-fall09_NB/c/word_tag.fst > $path_file 2>$path_log_file";

    system($cmd);

    #### step 2: process the output of Carmel
    $cmd = "cat $path_file | aae100.exec > $sys_output";
    system($cmd);
}



	

