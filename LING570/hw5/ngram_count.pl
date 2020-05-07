#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------




$input_sentence = "";
$bos = "<s> ";
$eos = " </s>";
	

while($input_sentence = <STDIN>) {	## accept input from file 

	split_sentence();
	create_unigram();
	create_bigram();
	create_trigram();		
}


output_unigram();
output_bigram();
output_trigram();




#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------




sub split_sentence {
	
	$processed_sentence = "";

	$processed_sentence = $bos . $input_sentence . $eos;
	@word_list = split /\s+/, $processed_sentence; 
}




sub create_unigram {		

	foreach $word_list(@word_list) {  
	
		if ((exists ($unigram{$word_list})) && ($word_list ne "")) {

			$unigram{$word_list} += 1;	
		}

		elsif ($word_list ne "") {

			$unigram{$word_list} = 1;		
		}				
	}
}




sub create_bigram {		

	$current_counter = 0;
	$next_counter = 1;
	$bigram_text = "";
	$current_text = "";
	$next_text = "";

	while ($current_counter != $#word_list) {
			
		$current_text = $word_list[$current_counter];
		$next_text = $word_list[$next_counter];

		$bigram_text = $current_text . " " . $next_text;

		$next_counter += 1;
		$current_counter += 1;	
			
	
		if ((exists ($bigram{$bigram_text})) && ($bigram_text ne "")) {

			$bigram{$bigram_text} += 1;
			$bigram_text = "";				
					
		}
		
		elsif ($bigram_text ne "") {					
				
			$bigram{$bigram_text} = 1;
			$bigram_text = "";			
		}
	}
}




sub create_trigram {		

	$uni_counter = 0;
	$bi_counter = 1;
	$tri_counter = 2;
	$trigram_text = "";
	$uni_text = "";
	$bi_text = "";
	$tri_text = "";

	while ($bi_counter != $#word_list) {
			
		$uni_text = $word_list[$uni_counter];
		$bi_text = $word_list[$bi_counter];
		$tri_text = $word_list[$tri_counter];

		$trigram_text = $uni_text . " " . $bi_text . " " . $tri_text;

		$uni_counter += 1;
		$bi_counter += 1;
		$tri_counter += 1;			
	
		if ((exists ($trigram{$trigram_text})) && ($trigram_text ne "")) {

			$trigram{$trigram_text} += 1;
			$trigram_text = "";				
					
		}
		
		elsif ($trigram_text ne "") {					
				
			$trigram{$trigram_text} = 1;
			$trigram_text = "";			
		}
	}
}




sub output_unigram {	

	$largest_count = 0;
	$total_count = 0;
	$current_count = 0;

	foreach $key (sort {$unigram{$b} <=> $unigram{$a}} keys %unigram) {

		$current_count = $unigram{$key}; 

		$total_count = $total_count + $current_count;

		$largest_count = $current_count if $current_count > $largest_count;

		print $unigram{$key}, "\t", $key, "\n";			
	}		
}




sub output_bigram {	

	$largest_count = 0;
	$total_count = 0;
	$current_count = 0;

	foreach $key (sort {$bigram{$b} <=> $bigram{$a}} keys %bigram) {

		$current_count = $bigram{$key}; 

		$total_count = $total_count + $current_count;

		$largest_count = $current_count if $current_count > $largest_count;

		print $bigram{$key}, "\t", $key, "\n";			
	}		
}




sub output_trigram {	

	$largest_count = 0;
	$total_count = 0;
	$current_count = 0;

	foreach $key (sort {$trigram{$b} <=> $trigram{$a}} keys %trigram) {

		$current_count = $trigram{$key}; 

		$total_count = $total_count + $current_count;

		$largest_count = $current_count if $current_count > $largest_count;

		print $trigram{$key}, "\t", $key, "\n";			
	}		
}

