#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------

$fsa_output = "";

open (INPUT, "result.out");

while ((defined($fsa_output = <INPUT>)) && (chomp($input_file = <stdin>))) {

	if ($fsa_output =~ / 1/) {
		printf "%-11s", $input_file; 
		print " => yes \n";
		
	} else {
		printf "%-11s", $input_file;
		print " => no \n";
	}

}

close (INPUT);

	