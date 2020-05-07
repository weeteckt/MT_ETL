#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------


open (INPUT, "result.out");

while ((defined($fsa_output = <INPUT>)) && (chomp($input_file = <stdin>))) {
	
	chomp($fsa_output);

	$fsa_output =~ s/}/"/g;
	
	if ($fsa_output =~ / 1/) {
		print "$input_file => $fsa_output \n"; 
		
	} else {
		print "$input_file => *none* 0 \n";
	}

}

close (INPUT);

	