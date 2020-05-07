#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------






open($train_file, $ARGV[0]) or die "cannot open training file for input\n";
open($test_file, $ARGV[1]) or die "cannot open test file for input\n";

open($train_bin, '>>', train_bin_vectors) or die "cannot open training file for output\n";
open($test_bin, '>>', test_bin_vectors) or die "cannot open test file for output\n";


while($train_line = <$train_file>) {	## accept input from file

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $train_line;

	for (my $cnt=3; $cnt<=$#temp_input; $cnt+=2)  {

		$temp_input[$cnt] = 1;
	}

	for (my $cnt=0; $cnt<=$#temp_input; $cnt++)  {

		print {$train_bin} $temp_input[$cnt], " ";
	}

	print {$train_bin} "\n";
}


while($test_line = <$test_file>) {	## accept input from file

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $test_line;

	for (my $cnt=3; $cnt<=$#temp_input; $cnt+=2)  {

		$temp_input[$cnt] = 1;
	}

	for (my $cnt=0; $cnt<=$#temp_input; $cnt++)  {

		print {$test_bin} $temp_input[$cnt], " ";
	}

	print {$test_bin} "\n";
}




#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------


