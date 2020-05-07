#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------


open (INPUT, "fst.out");

while (defined($fsa_output = <INPUT>)) {
	
	#chomp($fsa_output);
	
	$fsa_output =~ s/\([0-9]+ -> [0-9]+ "//g; 
	$fsa_output =~ s/" \/ [0-9][.][0-9]+\)//g; 
	$fsa_output =~ s/" \/ [0-9]+\)//g; 
	$fsa_output =~ s/" : "/\//g; 
	print $fsa_output;

}

close (INPUT);