#!/usr/bin/env perl


## created on 1/21/08

## Purpose: keep only features that are mentioned in a feature list file

## to run:
##    cat input_file | $0 feat_list_file  > output_file

## the format of the input and output file is:
##  instanceName label f1 v1 f2 v2 ....


use strict;

main();

1;


#########################
sub main {
    if(@ARGV < 1){
	die "usage: cat input | $0 feat_list_file {topN} > output\n If topN is 0 or unspecified, it means uses all the features in the feat_list_file\n";
    }

    my $feat_file = $ARGV[0];
    my $topN = 0;

    if(@ARGV == 2){
	$topN = $ARGV[1];
    }

    print STDERR "topN = $topN\n";

    ###### step 1: read the feat_file
    my %feat_hash = ();
    open(my $feat_fp, "$feat_file") or die "cannot open $feat_file\n";
    my $cnt = 0;
    while(<$feat_fp>){
	chomp;
	if(/^\s*$/){
	    next;
	}
	my @parts = split(/\s+/);
	my $featname = $parts[0];
	if(defined($feat_hash{$featname})){
	    print STDERR "Feature $featname has been defined before. The current line +$_+ is ignored\n";
	    next;
	}

	$feat_hash{$featname} = 1;
	$cnt ++;
	if($topN && $cnt >= $topN){
	    last;
	}
    }

    print STDERR "$cnt features read from $feat_file\n";

    ####### step 2: filter features
    my $total_feat_cnt = 0;
    my $kept_feat_cnt = 0;

    $cnt = 0;

    my $inst_w_no_feat = 0;
    my %hash = ();
    while(<STDIN>){
	chomp;
	if(/^\s*$/){
	    next;
	}

	my @parts = split(/\s+/);
	my $part_num = scalar @parts;

	if(scalar @parts < 2 || ($part_num % 2 != 0)){
	    print STDERR "wrong format +$_+\n";
	    next;
	}

	my $true_class = $parts[1];
	my $res = $parts[0] . " " . $true_class;

	my $kept_feat = 0;
	for(my $i=2; $i<$part_num; $i+=2){
	    my $featname = $parts[$i];
	    my $featval = $parts[$i+1];

	    $total_feat_cnt ++;
	    if( defined($feat_hash{$featname}) &&
		($featval > 0)){
		$res .= " $featname $featval";
		$kept_feat_cnt ++;
		$kept_feat ++;
	    }
	}

	if($kept_feat == 0){
	    $inst_w_no_feat ++;
	    if(defined($hash{$true_class})){
		$hash{$true_class} ++;
	    }else{
		$hash{$true_class} = 1;
	    }
	}

	print "$res\n";

	$cnt ++;
    }

    print STDERR "total_feat_cnt=$total_feat_cnt, kept_feat_cnt=$kept_feat_cnt\n";
    print STDERR "Finish processing $cnt instances from the input\n";

    print STDERR "instance_w_no_feature=$inst_w_no_feat\n";
    
    foreach my $c (sort {$hash{$b} <=> $hash{$a}} keys %hash){
	my $val = $hash{$c};
	print STDERR "$c\t$val\n";
    }
}
