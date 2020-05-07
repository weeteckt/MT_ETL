#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------




$input_sentence ="";
$counter = 0;	

while($input_sentence = <STDIN>) {	## accept input from file
    
	split_sentence();		
}

process_probability();
create_fst();


#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------




sub split_sentence {
	

	@word_table = split /\s+/, $input_sentence; 	

	foreach $word_table(@word_table) {  
	
		if ((exists ($tag_word{$word_table})) && ($word_table ne "")) {

			$tag_word{$word_table} += 1;	
		}

		elsif ($word_table ne "") {

			$tag_word{$word_table} = 1;		
		}	

		$tagandword = $word_table;

		$tagandword =~ s/\\\//{{{/g;
		$tagandword =~ s/\// /g;
		$tagandword =~ s/{{{/\\\//g;
		@temp_table = split /\s+/, $tagandword;
		
		$word_column[$counter] = $temp_table[0];
		
		#print "$word_column[$counter] \n";
		
		$counter += 1;
			
	}
}



sub process_probability {

	foreach $word_column(@word_column) {
	
		if ((exists ($word_token{$word_column})) && ($word_column ne "")) {

			$word_token{$word_column} += 1;	
		}

		elsif ($word_column ne "") {

			$word_token{$word_column} = 1;		
		}
	
	}

}



sub create_fst {

	$tag_counter = 0;
	$tag_probability = 0;
	$fst = "";

	print "S\n";
			
	foreach $key (sort keys %tag_word) {  
		
		$fst = "";
		$tag_reference = $key;

		$tag_reference =~ s/\\\//{{{/g;
		$tag_reference =~ s/\// /g;
		$tag_reference =~ s/{{{/\\\//g;
		
		@temp_tag = split /\s+/, $tag_reference;
		$tag_reference = $temp_tag[0];
		
	
		if ((exists ($word_token{$tag_reference})) && ($tag_reference ne "")) {
			
			$tag_counter = $word_token{$tag_reference};
			$tag_probability = $tag_word{$key}/$tag_counter;
			$tag_word{$key} = $tag_probability;
	
			$fst = $key;
			$fst =~ s/\\\//{{{/g;
			$fst =~ s/\//\" \"/g;
			$fst =~ s/{{{/\\\//g;
			
			print "(S (S \"$fst\" ";
			print $tag_word{$key};
			print ")) \n";
		
		}
			
	}

}