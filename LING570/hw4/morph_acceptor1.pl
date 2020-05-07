#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------


open (INPUT, "fsm.out");

while ((defined($fsm_output = <INPUT>)) && (chomp($input_file = <stdin>))) {
	
	chomp($fsm_output);
	
	if ($fsm_output =~ / 1/) {
		print "$input_file => yes \n"; 
		
	} else {
		print "$input_file => no \n";
	}

}

close (INPUT);

	