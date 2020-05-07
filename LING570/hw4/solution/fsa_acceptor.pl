#!/usr/bin/env perl

### Purpose: 
### created on 

use strict;

main();

1;

sub main {
  my $arg_num = scalar @ARGV;
  if($arg_num != 2){
	die "usage: $0 fsa input_file > output_file\n";
  }	 

  my $fsa_file = $ARGV[0];
  my $input_file = $ARGV[1];

  my $tmp_stdout = "/tmp/a1";
  my $tmp_stderr = "/tmp/a2";

  my $cmd = "cat $input_file | carmel -b -E -Ok 1 -sli $fsa_file > $tmp_stdout 2>$tmp_stderr";
  system($cmd);

  open(my $fp, "$tmp_stderr") or die "cannot open $tmp_stderr\n";
  my $str_num = 0;
  my $acc_str_num = 0;

  my $cur_str = "";
  while(<$fp>){
      if(/^Input\s+line\s+\d+:\s*(.+)\s*$/){
	  $cur_str = $1;
	  $str_num ++;
	  next;
      }

      if(/^\s*\((\d+)\s+states\s*\/\s*(\d+)\s+arcs/){
	  my $state_num = $1;
	  my $arc_num = $2;

	  if($state_num > 0){
	      print "$cur_str => yes\n";
	      $acc_str_num++;
	  }else{
	      print "$cur_str => no\n";
	  }
	  next;
      }
  }

  print STDERR "string_num=$str_num accepted=$acc_str_num\n";
}

1;
