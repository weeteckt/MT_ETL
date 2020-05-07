#!/usr/bin/env perl


## Purpose: test hmm.pm: read in an hmm and output a warning file


use strict;

use lib "/home/fxia/dt_chain/193/e";
use hmm;

main();
1;

####### 
sub main {
    if(@ARGV != 1){
	die "usage: $0 input_hmm 2>warning_file\n";
    }

    my $input_file = $ARGV[0];
    ## my $output_file = $ARGV[1];

    open(my $input_fp, "$input_file") or die "cannot open $input_file\n";
    ## open(my $output_fp, ">$output_file") or die "cannot create $output_file\n";
    
    my $hmm = new Hmm;
    my $suc = read_hmm_from_file($input_fp, $hmm);

    ## output_hmm($output_fp, $hmm);
    ## close($output_fp);
}
	

