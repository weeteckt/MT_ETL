#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





use POSIX qw(log10);

open($lm_file, $ARGV[0]) or die "cannot open $ARGV[0] - file not found\n";
open($input_file, $ARGV[4]) or die "cannot open $ARGV[1] - file not found\n";

$lm_input = "";
$input_sentence = "";
$counter = 0;
$bos = "<s> ";
$eos = " </s>";
$processed_sentence = "";

$lamda_1 = $ARGV[1];
$lamda_2 = $ARGV[2];
$lamda_3 = $ARGV[3];

accept_lm();
load_lm();
accept_test_data();
calculate_ppl();





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------




sub accept_lm {

	while(chomp($lm_input = <$lm_file>)) {	## accept input from language model
		
		$lm_list[$counter] = $lm_input;	
		$counter += 1;	
	}
}




sub load_lm {

$counter = 0;
#$unigram_counter = 0;
#$bigram_counter = 0;
#$trigram_counter = 0;	

	foreach $lm_list(@lm_list) {

		@tmp = split /\s+/, $lm_list[$counter];
		$tmp_key = "";

		if (($#tmp == 3) && ($tmp[0] ne "ngram")) {
			
			$tmp_key = $tmp[3];
			$unigram{$tmp_key} = $counter;
			
			#print "$tmp_key $unigram{$tmp_key}\n";				
		}

		elsif ($#tmp == 4) {

			$tmp_key = $tmp[3] . " " . $tmp[4];
			$bigram{$tmp_key} = $counter;
			
			#print "$tmp_key $bigram{$tmp_key}\n";		
		}

		elsif ($#tmp == 5) {

			$tmp_key = $tmp[3] . " " . $tmp[4] . " " . $tmp[5];
			$trigram{$tmp_key} = $counter;
			
			#print "$tmp_key $trigram{$tmp_key}\n";
		}

	$counter += 1;	
	
	}
}




sub accept_test_data {

$counter = 0;

	while(chomp($input_sentence = <$input_file>)) {	## accept input from input file 	
	
		$processed_sentence = "";
		$processed_sentence = $bos . $input_sentence . $eos;
		$sentence_table[$counter] = $processed_sentence;	
		$counter += 1;
	}
}




sub calculate_ppl {	
	
	$sentence_counter = 0;
	$master_entropy = 0;
	$master_cnt = 0;				
	$master_oov = 0;
	$master_logprob = 0;

	print "\n";
	print "\n";
	
	foreach $sentence_table(@sentence_table) {

		$word_counter = 0;
		$entropy = 0;
		$oov_num = 0;
		$sum_prob = 0;
		$cnt = 0;
		$uni_counter = 1;
		$bi_counter = 0;

		@word_table = split /\s+/, $sentence_table[$sentence_counter];

		print "Sent #", $sentence_counter+1, ": ", $sentence_table[$sentence_counter], "\n";	

		foreach $word_table(@word_table) {	

			$tmp_lm = 0;
			$uni_prob = 0;
			$bi_prob = 0;
			$tri_prob = 0;
			$ngram_prob = 0;
			$ngram_flag = "false";
			$word_flag = "true";						

			if ($uni_counter == 1) {
			
				$uni_text = $word_table[$uni_counter];
				$bi_text = $word_table[$bi_counter] . " " . $word_table[$uni_counter];
				$tri_text = $word_table[$bi_counter] . " " . $word_table[$uni_counter];
				$output_text = $uni_text . " | " . "<s>";
			}

			else {

				$uni_text = $word_table[$uni_counter];
				$bi_text = $word_table[$bi_counter] . " " . $word_table[$uni_counter];
				$tri_text = $word_table[$bi_counter-1] . " " . $word_table[$bi_counter] . " " . $word_table[$uni_counter];
				$output_text = $uni_text . " | " . $word_table[$bi_counter-1] . " " . $word_table[$bi_counter];	
			}
			
			if (exists ($trigram{$tri_text})) {
				
				$tmp_lm = $trigram{$tri_text};
				@tmp_tri = split /\s+/, $lm_list[$tmp_lm];
				$tri_prob = ($lamda_3*$tmp_tri[2]);
				$ngram_flag = "true";
			}

			if (exists ($bigram{$bi_text})) {

				$tmp_lm = $bigram{$bi_text};
				@tmp_bi = split /\s+/, $lm_list[$tmp_lm];

				if ($word_table[$bi_counter] eq "<s>") {

					$ngram_flag = "true";
					$bi_prob = (($lamda_2 + $lamda_3)*$tmp_bi[2]);
				}

				else {

					$bi_prob = ($lamda_2*$tmp_bi[2]);
				}
			}

			if (exists ($unigram{$uni_text})) {

				$tmp_lm = $unigram{$uni_text};
				@tmp_uni = split /\s+/, $lm_list[$tmp_lm];
				$uni_prob = ($lamda_1*$tmp_uni[2]);
			} 

			else {
				$word_flag = "false";
			}


			if ($uni_text ne "") {

				$ngram_prob = $uni_prob + $bi_prob + $tri_prob;
				
				if (($word_flag eq "true") && ($ngram_flag eq "true")) {
					
					$sum_prob = $sum_prob + $ngram_prob;
					$cnt += 1;
					print "$uni_counter", ": log P(", $output_text, ") = ", $ngram_prob, "\n";
				}
			
				elsif (($word_flag eq "true") && ($ngram_flag eq "false")) {
	
					$sum_prob = $sum_prob + $ngram_prob;
					$cnt += 1;
					print "$uni_counter", ": log P(", $output_text, ") = ", $ngram_prob, " (unseen ngrams)", "\n";
				}

				else {
					$oov_num += 1;
					print "$uni_counter", ": log P(", $output_text, ") = -inf (unknown word)", "\n";
				}

			$uni_counter += 1;
			$bi_counter += 1;
			$word_counter += 1;

			}

		}
			
	$master_cnt = $master_cnt + ($word_counter-1);
	$master_oov = $master_oov + $oov_num;
	$master_logprob = $master_logprob + $sum_prob;

	$entropy = 10**(-($sum_prob/$cnt));
	print "1 sentence, ", $word_counter-1, " words, ", $oov_num, " OOVs\n";
	print "logprob=", $sum_prob, " ppl=", $entropy;
	print "\n";
	print "\n";
	print "\n";
	print "\n";
		
	$sentence_counter += 1;

	}

	$master_entropy = 10**(-($master_logprob/(($master_cnt + $sentence_counter) - $master_oov)));

	print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
	print "sent_num=", $sentence_counter, " word_num=", $master_cnt, " oov_num=", $master_oov, "\n";
	print "logprob=", "$master_logprob", " ave_logpro=", $master_logprob/(($master_cnt + $sentence_counter) - $master_oov), " ppl=", $master_entropy, "\n";
}







