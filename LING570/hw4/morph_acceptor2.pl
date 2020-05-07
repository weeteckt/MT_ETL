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

		$fsm_output =~ s/\"//g;
		$fsm_output =~ s/1//g;

		print "$input_file => $fsm_output \n"; 
		
	} else {
		print "$input_file => *NONE* \n";
	}

}

close (INPUT);

	