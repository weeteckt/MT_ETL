#!/usr/bin/perl

# created on 12/14/05
# purpose: create a voc from stdin.
#          The voc is either not sorted or 
#           sorted by frequency.
# Note: we will not ignore input lines that start with "#"

# to run:
#    cat input | $0 {sort_flag} {get_tag_voc_flag} > voc_file

# the input is of the format "word/tag ...."

use strict;

my $get_tag_voc_flag = 1;  #0: get word voc, 1: get tag voc
my $sort_flag = 1;         #0: not-sort, 1: by freq

if(@ARGV > 0){
    $sort_flag = $ARGV[0];
}

if(@ARGV > 1){
    $get_tag_voc_flag = $ARGV[1];
}


my %voc = ();

my $word_num = 0;
my $token_num = 0;

while (<STDIN>) {
    chomp;
    next if (/^\s*$/);
    s/^\s+//;
    s/\s+$//;
    my @parts = split(/\s+/);
    foreach my $pair (@parts) {
	if($pair =~ /^(.+)\/([^\/]+)$/){
	    my $w = $1;
	    my $t = $2;
	    if($get_tag_voc_flag){
		$voc{$t}++;
	    }else{
		$voc{$w}++;
	    }
	}else{
	    die "wrong format: +$pair+\n";
	}
    }
}

if ($sort_flag){
    foreach my $key (sort {$voc{$b} <=> $voc{$a}} keys %voc) {
	print "$key\t$voc{$key}\n";
	$word_num ++;
	$token_num += $voc{$key}
    }
}else{
    foreach my $key (keys %voc) {
	print "$key\t$voc{$key}\n";
	$word_num ++;
	$token_num += $voc{$key}
    }
}
    

print STDERR "Success! voc_size=$word_num, token_num=$token_num\n";
exit 0;
