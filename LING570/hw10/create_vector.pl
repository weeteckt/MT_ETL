#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





%bigram = ();
@word_l = ();
%feat_l = ();
%w_list = ();


open($train_file, $ARGV[0]) or die "cannot open training file for input\n";
open($vector_f, '>>', $ARGV[1]) or die "please provide a vector file name\n";
open($word_list, $ARGV[2]) or die "cannot open word list file for input\n";
open($feat_list, $ARGV[3]) or die "cannot open feature list file for input\n";

process_input();
process_vector();


	


#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub process_input {

	$line_input = "";
	$word_input = "";
	$feat_input = "";
	$i = 0;
	$j = 0;	

	while(($line_input = <$train_file>)) {	## accept input from file

		@temp_input = ();
			
		@temp_input = split /\s+/, $line_input;

		for (my $cnt=0; $cnt<=$#temp_input; $cnt++)  {

			$bi_text = $temp_input[$cnt] . " " . $temp_input[$cnt+1];

			if (($temp_input[$cnt] ne "") && ($temp_input[$cnt+1] ne "")) {

				$bigram{$bi_text} += 1;	
			}				
		}	
	}

	while(($word_input = <$word_list>)) {

		@temp_word = ();	
		@temp_input = split /\s+/, $word_input;

		if ($temp_input[0] ne "") {
			
			$word_l[$i] = $temp_input[0];
		
			$i += 1;
		}
	}

	while(($feat_input = <$feat_list>)) {

		@temp_word = ();	
		@temp_input = split /\s+/, $feat_input;

		if ($temp_input[0] ne "") {

			$feat_l{$temp_input[0]} = $j;
		
			$j += 1;
		}
	}
	
	close $line_input;
	close $word_input;
	close $feat_input;
}





sub process_vector {

	for ($cnt=0; $cnt<=$#word_l; $cnt++) {

		%output_hash = ();
		
		foreach $key (keys %bigram) {

			$l_text = "";
			$r_text = "";

			@temp_input = ();
			@temp_input = split /\s+/, $key;

			if ($word_l[$cnt] eq $temp_input[0]) {

				if (exists ($feat_l{$temp_input[1]})) {
				
					$l_text = ($feat_l{$temp_input[1]}+$j) . "_" . "R" . "=" . $temp_input[1] . " " . $bigram{$key} ;
					$output_hash{$l_text} = ($feat_l{$temp_input[1]}+$j);
				}
			}

			elsif ($word_l[$cnt] eq $temp_input[1]) {

				if (exists ($feat_l{$temp_input[0]})) {
						
					$r_text = $feat_l{$temp_input[0]} . "_" . "L" . "=" . $temp_input[0] . " " . $bigram{$key};
					$output_hash{$r_text} = $feat_l{$temp_input[0]};
				}
			}
		}
		
		print {$vector_f} $word_l[$cnt], " ";

		foreach $key (sort {$output_hash{$a} <=> $output_hash{$b}} keys %output_hash) {

			print {$vector_f} $key, " ";
		}

		print {$vector_f} "\n";
	}

	close $vector_f;	
}


