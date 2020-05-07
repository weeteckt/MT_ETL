#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------




$input_sentence ="";
$unique_count = 0;	

while($input_sentence = <STDIN>) {	## accept input from file
    
	split_sentence();		
}


count_words();

#print $total_count, "\n";
#print $unique_count;




#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------




sub split_sentence {

	@word_table = split /\s+/, $input_sentence; 	

	foreach $word_table(@word_table) {  
	
		if ((exists ($all_text{$word_table})) && ($word_table ne "")) {

			$all_text{$word_table} += 1;	
		}

		elsif ($word_table ne "") {

			$all_text{$word_table} = 1;
			$unique_count += 1;		
		}				
	}
}




sub count_words {

	$largest_count = 0;
	$total_count =0;

	foreach $key (sort {$all_text{$b} <=> $all_text{$a}} keys %all_text) {

		$current_count = $all_text{$key}; 

		$total_count = $total_count + $current_count;

		$largest_count = $current_count if $current_count > $largest_count;

		printf "%-20s \t\t\t %s\n", "$key", $all_text{$key};			

	}		
}

