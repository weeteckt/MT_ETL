#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------




$input_sentence = "";
$open_quote = "\"";
$close_quote ="\" ";

while($input_sentence = <STDIN>) {	## accept input from file
    
	split_sentence();		
}




#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------



sub split_sentence {
	
	chomp($input_sentence);
	@word_input = split //, $input_sentence; 	

	foreach $word_input(@word_input) {  
	
		$tmp_word = $open_quote.$word_input.$close_quote;
		print $tmp_word;
		
	}			
	print "\n";
}