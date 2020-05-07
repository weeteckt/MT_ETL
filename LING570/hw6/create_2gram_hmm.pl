#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





use POSIX qw(log10);


$input_data ="";
$counter = 0;
$BOS = "<s>/BOS";
$EOS = "</s>/EOS";
$state_counter = 0;
$symbol_counter = 0;
$transition_state = 0;
$emission_state = 0;
$tag_counter = 0;
$sentence_count = 0;


while($input_data = <STDIN>) {	## accept input from file
    
	split_data();
	create_unigram();
	create_bigram();
	$sentence_count += 1;		
}


$symbol_counter += 1;
$bos_t = "BOS <s>";
$eos_t = "EOS </s>";
$tag_word{$bos_t} = $sentence_count;
$tag_word{$eos_t} = $sentence_count;

process_summary ();
process_transition();
process_emission();





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub split_data {
	
	$counter = 0;
	$temp_sentence = $BOS . " " . $input_data . " " . $EOS;

	@pos_table = ();
	@tag_column = ();
	@word_column = ();

	@pos_table = split /\s+/, $temp_sentence; 	

	foreach $pos_table(@pos_table) {  

		@temp_table = ();

		$tagandword = $pos_table;

		$tagandword =~ s/\\\//{{{/g;
		$tagandword =~ s/\<\/s\>/}}}/g;
		$tagandword =~ s/\// /g;
		$tagandword =~ s/{{{/\\\//g;
		$tagandword =~ s/}}}/\<\/s\>/g;
		

		@temp_table = split /\s+/, $tagandword;

		$tagandword = "";
		$tagandword = $temp_table[1] . " " . $temp_table[0];

		if ((exists ($tag_word{$tagandword})) && ($tagandword ne "")) {

			$tag_word{$tagandword} += 1;	
		}

		elsif ($tagandword ne "") {

			$tag_word{$tagandword} = 1;
			$emission_counter += 1;		
		}	


		if (($temp_table[0] ne "") && ($temp_table[1] ne "")) {
			
			$tag_column[$counter] = $temp_table[1];
			$word_column[$counter] = $temp_table[0];
		}
		
	$counter += 1;
	
	}
}





sub create_unigram {

	$bi_cnt = 0;

	for ($uni_cnt=0; $uni_cnt<$#tag_column+1; $uni_cnt++) {

	
		if (exists ($unigram_tag{$tag_column[$uni_cnt]}) && ($tag_column[$uni_cnt] ne "")) {

			$unigram_tag{$tag_column[$uni_cnt]} += 1;	
			$unigram_counter += 1;
		}

		elsif ($tag_column[$uni_cnt] ne "") {

			$unigram_tag{$tag_column[$uni_cnt]} = 1;
			$state_counter += 1;
		}


		if (exists ($uni_word{$word_column[$bi_cnt]}) && ($word_column[$bi_cnt] ne "")) {

			$uni_word{$word_column[$bi_cnt]} += 1;	
		}

		elsif ($word_column[$bi_cnt] ne "") {

			$uni_word{$word_column[$bi_cnt]} = 1;	
			$symbol_counter += 1;	
		}

	#print $tag_column[$uni_cnt], "\n";
	$bi_cnt += 1;

	}	
}





sub create_bigram {

	$bi_cnt = 1;
	

	for ($uni_cnt=0; $uni_cnt<$#tag_column; $uni_cnt++) {		

		$bigram_pos = "";

		$bigram_pos = $tag_column[$uni_cnt] . " " . $tag_column[$bi_cnt];

		if (exists ($bigram_tag{$bigram_pos}) && ($bigram_pos ne "")) {

			$bigram_tag{$bigram_pos} += 1;
		}

		elsif ($bigram_pos ne "") {

			$bigram_tag{$bigram_pos} = 1;
			$trans_counter += 1;
		}

	$bi_cnt += 1;
	#print $bigram_pos, "\n";
	
	}	
}





sub process_summary {

	$init_state_count = 0;
	$init_prob = 0;

	print "state_num=$state_counter\n";
	print "sym_num=$symbol_counter\n";
	print "init_line_num=1\n";
	print "trans_line_num=$trans_counter\n";
	print "emiss_line_num=$emission_counter\n";
	print "\n";
	print "\\init\n";
	print "BOS \t 1.0 \t 0 \n";
	print "\n";
}





sub process_transition {

	print "\\transition\n";

	foreach $key (sort keys %bigram_tag) {

		@temp_uni = split /\s+/, $key;

		print $temp_uni[0], "\t", $temp_uni[1], "\t"; 
		print $bigram_tag{$key}/$unigram_tag{$temp_uni[0]}, "\t", log10($bigram_tag{$key}/$unigram_tag{$temp_uni[0]});
		print "\n";	
	}

	print "\n";
}





sub process_emission {

	print "\\emission\n";

	foreach $key (sort keys %tag_word) {

		@temp_tagword = split /\s+/, $key;

		print $temp_tagword[0], "\t", $temp_tagword[1], "\t";
		print $tag_word{$key}/$unigram_tag{$temp_tagword[0]}, "\t", log10($tag_word{$key}/$unigram_tag{$temp_tagword[0]});
		print "\n";
	}
}

