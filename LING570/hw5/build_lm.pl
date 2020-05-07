#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------

use POSIX qw(log10);


$input_text = "";
$token = "";
$unigram_type_count = 0;
$unigram_token_count = 0;
$bigram_type_count = 0;
$bigram_token_count = 0;
$trigram_type_count = 0;
$trigram_token_count = 0;


while($input_text = <STDIN>) {	## accept input from file 
	
	@token_list = split /\s+/, $input_text;
		
		if ($#token_list == 1) {

			create_unigram_lm();	
		}
	
		elsif ($#token_list == 2) {
  
			create_bigram_lm();
		}

		elsif ($#token_list == 3) {
 
			create_trigram_lm();
		}	

	$ngram{$token} = $token_list[0];	
}


output_lm_summary();
output_unigram();
output_bigram();
output_trigram();
print "\\end\\\n";




#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------




sub create_unigram_lm {		
	
	$unigram_token_count = $unigram_token_count + $token_list[0];
	$unigram_type_count = $unigram_type_count + 1;
	$token = $token_list[1];
	$unigram{$token} = $token_list[0];			
}




sub create_bigram_lm {		

	$bigram_token_count = $bigram_token_count + $token_list[0];
	$bigram_type_count = $bigram_type_count + 1;
	$token = $token_list[1] . " " . $token_list[2];
	$bigram{$token} = $token_list[0];
}




sub create_trigram_lm {		

	$trigram_token_count = $trigram_token_count + $token_list[0];
	$trigram_type_count = $trigram_type_count + 1;
	$token = $token_list[1] . " " . $token_list[2] . " " . $token_list[3];
	$trigram{$token} = $token_list[0];
}




sub output_lm_summary {	

	print "\\data\\\n";
	print "ngram 1: type=", $unigram_type_count, " token=", $unigram_token_count, "\n";
	print "ngram 2: type=", $bigram_type_count, " token=", $bigram_token_count, "\n";
	print "ngram 3: type=", $trigram_type_count, " token=", $trigram_token_count, "\n";
	print "\n";
	
}




sub output_unigram {	
	
	print "\\1-grams:\n";
	
	foreach $key (sort {$unigram{$b} <=> $unigram{$a}} keys %unigram) {

		print $unigram{$key}, " ", $unigram{$key}/$unigram_token_count, " ", log10($unigram{$key}/$unigram_token_count), " ", $key, "\n";				
	}
	
	print "\n";	
}




sub output_bigram {	

	$search_key = "";

	print "\\2-grams:\n";
	
	foreach $key (sort {$bigram{$b} <=> $bigram{$a}} keys %bigram) {

		@token_key = split /\s+/, $key;
		$search_key = $token_key[0];

		print $bigram{$key}, " ", $bigram{$key}/$ngram{$search_key}, " ", log10($bigram{$key}/$ngram{$search_key}), " ", $key, "\n";				
	}	

	print "\n";		
}




sub output_trigram {	

	$search_key = "";

	print "\\3-grams:\n";
	
	foreach $key (sort {$trigram{$b} <=> $trigram{$a}} keys %trigram) {

		@token_key = split /\s+/, $key;
		$search_key = $token_key[0] . " " . $token_key[1];

		print $trigram{$key}, " ", $trigram{$key}/$ngram{$search_key}, " ", log10($trigram{$key}/$ngram{$search_key}), " ", $key, "\n";			
	}
	
	print "\n";		
}

