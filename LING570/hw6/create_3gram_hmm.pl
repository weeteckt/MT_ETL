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

$lamda_1 = $ARGV[1];
$lamda_2 = $ARGV[2];
$lamda_3 = $ARGV[3];	


while($input_data = <STDIN>) {	## accept input from file
    
	split_data();
	create_unigram();
	create_bigram();
	create_trigram();
	create_tri_word();
	$sentence_count += 1;		
}


open ($unk_in, $ARGV[4]) or die "please provide input filename after l1 l2 l3\n";

while($unk_input = <$unk_in>) {	## accept smoothing input from file
    
	@smooth_table = split /\s+/, $unk_input;

	$unknown_tag{@smooth_table[0]} = $smooth_table[1];
	$emission_counter += 1;	
}


$symbol_counter += 1;
$bos_t = "BOS <s>";
$eos_t = "EOS </s>";
$tag_word{$bos_t} = $sentence_count;
$tag_word{$eos_t} = $sentence_count;

create_unseen_seq();
count_state();
count_emission();
count_transition();
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
	$temp_sentence = $BOS . " " . $BOS . " " . $input_data . " " . $EOS;

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
		}	

		if (($temp_table[0] ne "") && ($temp_table[1] ne "")) {
			
			$tag_column[$counter] = $temp_table[1];
			$word_column[$counter] = $temp_table[0];
			$uni_tag{$temp_table[1]} += 1;
			$tag_counter += 1;
		}
		
	$counter += 1;
	
	}
}





sub create_unigram {

	$uni_cnt = 1;
	$bi_cnt = 0;

	for ($uni_cnt=1; $uni_cnt<$#tag_column+1; $uni_cnt++) {

	
		if (exists ($unigram_tag{$tag_column[$uni_cnt]}) && ($tag_column[$uni_cnt] ne "") && ($tag_column[$uni_cnt] ne "BOS") && ($tag_column[$uni_cnt] ne "EOS")) {

			$unigram_tag{$tag_column[$uni_cnt]} += 1;	
			$unigram_counter += 1;
		}

		elsif ($tag_column[$uni_cnt] ne "") {

			$unigram_tag{$tag_column[$uni_cnt]} = 1;
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

	$uni_cnt = 0;
	$bi_cnt = 1;
	
	for ($uni_cnt=0; $uni_cnt<$#tag_column; $uni_cnt++) {		

		$bigram_pos = "";
		
		if (($tag_column[$uni_cnt] ne "EOS") && ($tag_column[$bi_cnt] ne "BOS")) { 

			$bigram_pos = $tag_column[$uni_cnt] . " " . $tag_column[$bi_cnt];
		}
		
		if (exists ($bigram_tag{$bigram_pos}) && ($bigram_pos ne "")) {

			$bigram_tag{$bigram_pos} += 1;			
		}

		elsif ($bigram_pos ne "") {

			$bigram_tag{$bigram_pos} = 1;
			$state_counter += 1;
		}

	$bi_cnt += 1;
	#print $bigram_pos, "\n";
	
	}	
}





sub create_trigram {

	$bi_cnt = 1;
	$tri_cnt = 2;

	for ($uni_cnt=0; $uni_cnt<$#tag_column-1; $uni_cnt++) {		

		$trigram_pos = "";

		if (($tag_column[$tri_cnt] ne "BOS") && ($tag_column[$uni_cnt] ne "EOS") && ($tag_column[$bi_cnt] ne "EOS")) { 

			$trigram_pos = $tag_column[$uni_cnt] . " " . $tag_column[$bi_cnt] . " " . $tag_column[$tri_cnt];
		}


		if (exists ($trigram_tag{$trigram_pos}) && ($trigram_pos ne "")) {

			$trigram_tag{$trigram_pos} += 1;
		}

		elsif ($trigram_pos ne "") {

			$trigram_tag{$trigram_pos} = 1;	
		}

	$bi_cnt += 1;
	$tri_cnt += 1;
	#print $tri_w_pos, "\n";

	}	
}





sub create_tri_word {

	$bi_cnt = 1;
	$tri_cnt = 2;

	for ($uni_cnt=0; $uni_cnt<$#tag_column; $uni_cnt++) {	

		$tri_w_pos = "";
		$bi_w = "";
		$uni_t = "";

		$tri_w_pos = $tag_column[$uni_cnt] . " " . $tag_column[$bi_cnt] . " " . $word_column[$bi_cnt];
		$tri_w_uk = $tag_column[$uni_cnt] . " " . $tag_column[$bi_cnt] . " " . "<unk>";

		$bi_w = $tag_column[$bi_cnt] . " " .  $word_column[$bi_cnt];
		$bi_c = $tag_column[$uni_cnt] . " " .  $tag_column[$bi_cnt];
		$bi_w_uk = $tag_column[$bi_cnt] . " " .  "<unk>";

	

		if ($tri_w_pos ne "") {

			$tri_word{$tri_w_pos} = 1;
		}

		if (exists ($tri_word{$tri_w_uk})) {

		}

		else {

			$tri_word{$tri_w_uk} = 1;	
		}
	
		if ($bi_w ne ""){

			$bi_word_p{$bi_w} = 1;
			$bi_word_c{$bi_c} = 1;	
		}

	#print $bi_w, "\n";
	$bi_cnt += 1;
	$tri_cnt += 1;

	}
}





sub create_unseen_seq {

	foreach $key (sort keys %unigram_tag) {
		
		$k_u = $key;

		foreach $key (sort keys %unigram_tag) {
			
			$k_b = $key . " " . $k_u;		

			if (exists ($bigram_tag{$k_b})) {

			}

			else {
				#$bigram_tag{$k_b} = 1;
				#$unigram_tag{$key} += 1;
			}

			foreach $key (sort keys %unigram_tag) {
			
				$k_t = $key . " " . $k_u . " " . $k_b;
				$k_v = $key . " " . $k_u;
				$k_k = $k_u . " " . $key;
			
				if (exists ($trigram_tag{$k_t})) {

				}

				else {
					$trigram_tag{$k_t} = 1;
					
					if (exists ($bigram_tag{$k_v})) {

						$bigram_tag{$k_v} += 1;
						$unigram_tag{$key} += 1;
					}

					else {

						$bigram_tag{$k_v} = 1;
						$unigram_tag{$key} += 1;
					}
				}
			}
		}
	}	
}




	
sub count_state {

	foreach $key (sort keys %bigram_tag) {

		$unitag_counter += 1;
	}
}





sub count_emission {

	foreach $key (sort keys %tri_word) {

		@temp_emit = split /\s+/, $key;

		if (($temp_emit[1] ne "BOS") && ($temp_emit[2] ne "BOS") && ($temp_emit[0] ne "EOS") && ($temp_emit[1] ne "EOS") && ($temp_emit[0] ne "")) { 

			$emission_counter += 1;	
		}
	}
}





sub count_transition {

	foreach $key (sort keys %trigram_tag) {
	
		@temp_count = split /\s+/, $key;

		if (($temp_count[1] ne "BOS") && ($temp_count[2] ne "BOS") && ($temp_count[1] ne "EOS") && ($temp_count[0] ne "EOS")) { 

			$transition_counter += 1;
		}
	}
}





sub process_summary {

	$init_state_count = 0;
	$init_prob = 0;

	print "state_num=$unitag_counter\n";
	print "sym_num=$symbol_counter\n";
	print "init_line_num=1\n";
	print "trans_line_num=$transition_counter\n";
	print "emiss_line_num=$emission_counter\n";
	print "\n";
	print "\\init\n";
	print "BOS_BOS \t 1.0 \t 0 \n";
	print "\n";
}





sub process_transition {

	$total_tag = 0;
	
	print "\\transition\n";
	
	foreach $key (sort keys %unigram_tag) {

		$total_tag += $unigram_tag{$key};
	}

	foreach $key (sort keys %trigram_tag) {
		
		$from_state = "";
		$to_state = "";
		$smooth_prob = 0;
		$uni_prob = 0;
		$bi_prob = 0;
		$tri_prob = 0;

		@temp_uni = split /\s+/, $key;
		$from_state = $temp_uni[0] . " " . $temp_uni[1];
		$to_state = $temp_uni[1] . " " . $temp_uni[2];

		$uni_prob = $unigram_tag{$temp_uni[2]}/$total_tag;
		$bi_prob = $bigram_tag{$to_state}/$unigram_tag{$temp_uni[1]};
		$tri_prob = $trigram_tag{$key}/$bigram_tag{$from_state};
		
		if ($tri_prob eq 0) {
		
			$tri_prob = 1/$unigram_tag{$temp_uni[2]};
		}

		$smooth_prob = ($lamda_3*$tri_prob) + ($lamda_2*$bi_prob) + ($lamda_1*$uni_prob);	
	
		if (($smooth_prob ne 0) && ($temp_uni[1] ne "BOS") && ($temp_uni[2] ne "BOS") && ($temp_uni[1] ne "EOS") && ($temp_uni[0] ne "EOS")) {
		
			print $temp_uni[0], "_", $temp_uni[1], "\t", $temp_uni[1], "_", $temp_uni[2], "\t"; 
			print $smooth_prob, "\t", log10($smooth_prob), "\n";
		}
	}
	
	print "\n";
	
}


	


sub process_emission {

	print "\\emission\n";

	$smooth_tag = 0;
	$unk_tag = 0;
	$unknown = "";
	
	foreach $key (sort keys %unknown_tag) {

		$unknown = $key . " " . "<unk>";
		$bi_word_p{$unknown} = $unknown_tag{$key};
	}
	
	foreach $key (sort keys %bi_word_p) {

		
		@temp_b = split /\s+/, $key;

		$temp_p = $key;
	

		if ($temp_b[1] eq "<unk>") {
			
			$bi_word_p{$key} = $unknown_tag{$temp_b[0]};
		}

		else {

			$bi_word_p{$key} = ($tag_word{$temp_p}/$uni_tag{$temp_b[0]})*(1-($unknown_tag{$temp_b[0]}));
		}

			#print $em_state{$temp_b[0]}, "_", $temp_b[0], "\t" . $temp_b[1]. " " . "\t"; 
			#print $bi_word_p{$key}, "\t", log10($bi_word_p{$key});
			#print "\n";
	}

	foreach $key (sort keys %tri_word) {

		@temp_t = split /\s+/, $key;

		$temp_s = $temp_t[1] . " " . $temp_t[2];

		if (exists ($bi_word_p{$temp_s})) {

			print $temp_t[0], "_", $temp_t[1], "\t" . $temp_t[2]. " " . "\t"; 
			print $bi_word_p{$temp_s}, "\t", log10($bi_word_p{$temp_s});
			print "\n";
		}
	}	
}









