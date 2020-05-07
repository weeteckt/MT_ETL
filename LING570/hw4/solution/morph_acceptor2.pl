#!/usr/bin/perl

# created on 10/16/09
# purpose: a wrapper for Q3 of Hw4 (a morphological acceptor)
# 
# usage: $0 expand_fsa word_list output
#
# The format of word_list: one word per line
#
# The format of expand_fst: 
#        final state
#       (from (to x y))
#       ...
#
# The format for output: "word => morph/tag morph/tag ..." 

use strict;


main();
1;

sub main {
    my $argc = scalar @ARGV;

    if($argc != 3){
	die "usage: $0 expand_fst word_list output\n";
    }

    my $fst_file = $ARGV[0];
    my $word_file = $ARGV[1];
    my $output_file = $ARGV[2];

    #### step 1: preprocess the input
    my $cmd = "cat $word_file | db193.exec  > $output_file.input";
    systemx($cmd);
    
    #### step 2: run Carmel
    $cmd = "cat $output_file.input | carmel -b -Ok 1 -sli $fst_file > $output_file.sys 2>$output_file.sys.log";
    systemx($cmd);

    #### step 3: postprocessing
    $cmd = "db193-fall09.exec $word_file  $output_file.sys > $output_file\n";
    systemx($cmd);

    print STDERR "All done. Files stored in $output_file\n";
}

sub systemx {
    my ($cmd) = @_;

    print STDERR "\n\n***************$cmd\n\n";
    system($cmd);
    if($?){
        die "$cmd failed\n";
    }else{
        print STDERR "+++++$cmd++++ succeeds\n\n\n";
    }
}




