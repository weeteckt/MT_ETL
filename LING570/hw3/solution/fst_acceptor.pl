#!/usr/bin/env perl

### Purpose: run a fst: given x, it generates y
### created on 10/11/2009

### the output has the format "x => y prob"

use strict;

main();

1;

sub main {
  my $arg_num = scalar @ARGV;
  if($arg_num != 2){
	die "usage: $0 fst input_file > output_file\n";
  }	 

  my $fst_file = $ARGV[0];
  my $input_file = $ARGV[1];

  my $tmp_stdout = "/tmp/a1";
  my $tmp_stderr = "/tmp/a2";

  ### step 1: call Carmel to get the output
  my $cmd = "cat $input_file | carmel -b -E -Ok 1 -sli $fst_file > $tmp_stdout 2>$tmp_stderr";
  system($cmd);


  ### step 2: process stdout to get y
  open(my $stdout_fp, "$tmp_stdout") or die "cannot open $tmp_stdout\n";
  my @y_arr = ();
  while(<$stdout_fp>){
      chomp;
      if(/^\s*$/){
	  next;
      }
      push(@y_arr, $_);
  }

  ### step 3: process stderr
  open(my $stderr_fp, "$tmp_stderr") or die "cannot open $tmp_stderr\n";
  my $str_num = 0;
  my $acc_str_num = 0;

  my $cur_str = "";
  while(<$stderr_fp>){
      if(/^Input\s+line\s+\d+:\s*(.+)\s*$/){
	  $cur_str = $1;
	  $str_num ++;
	  next;
      }

      if(/^\s*\((\d+)\s+states\s*\/\s*(\d+)\s+arcs/){
	  my $state_num = $1;
	  my $arc_num = $2;

	  my $y = $y_arr[$str_num-1];

	  if($state_num > 0){
	      print "$cur_str => $y\n";
	      $acc_str_num++;
	  }else{
	      print "$cur_str => *none* $y\n";
	  }
	  next;
      }
  }

  my $tmp_num = scalar @y_arr;
  if($tmp_num == $str_num){
      print STDERR "All done: string_num=$str_num accepted=$acc_str_num\n";
  }else{      
      print STDERR "this should never happen: diff number of strings: tmp_num != $str_num\n";
  }
}

1;
