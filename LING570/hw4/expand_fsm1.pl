#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------




if(@ARGV != 2){
    die "usage: $0 lexicon morph_rules\n";
}

open($lexicon, $ARGV[0]) or die "cannot open $ARGV[0] - file not found\n";
open($morph_rules, $ARGV[1]) or die "cannot open $ARGV[1] - file not found\n";

$input_lexicon = "";
$input_rule = "";
$rule_counter = 0;
$search_rule = "";
$counter = 0;
$accept_state = 0;
$state_counter = 0;
$end_state = 0;



while ($input_lexicon = <$lexicon>) {
		
	chomp($input_lexicon);
	
	if ($input_lexicon ne ""){

		@lexi = split /\s+/, $input_lexicon;	

		$word_table[$counter] = $lexi[0];
		$lexicon_table[$counter] = $lexi[1];
	
		$counter += 1;
	}	
}



while ($input_rule = <$morph_rules>) {	## accept input from rules file
    
	$counter = 0;
	$word_key = "";
	
	chomp($input_rule);

	@rules = split /\s+/, $input_rule; 
	
	$rule_counter = $#rules;

	if ($rule_counter eq 0) {

		print "$rules[0] \n";
		$end_state = $rules[0];			
		$accept_state = $rules[0];		
		$accept_state =~ s/\w//;
		$state_counter = $accept_state + 21;
	}

	else {
		$search_rule = "";
		$search_rule = $rules[2];
		$search_rule =~ s/\)\)//g;

		while ($counter <= $#lexicon_table) {	
			create_fst();
			$counter += 1;	
		}
	}					

}
	



#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------



sub create_fst {


	$start_state = $rules[0];
	$stop_state = $rules[1];
	$stop_state =~ s/\w//;
	$stop_state =~ s/\(//g;

	if ($lexicon_table[$counter] eq ($search_rule)) {
				
		@word_key = split //, $word_table[$counter];
		
		print_fst();
	}
}



sub print_fst {

	

	$start_state = $rules[0];
	$stop_state = $rules[1];
	$start_state =~ s/\w//;
	$start_state =~ s/\(//g;
	$stop_state =~ s/\w//;
	$stop_state =~ s/\(//g;
	$char_counter = 0;
	$previous_state = 0;

	foreach $word_key(@word_key) {

		if ($char_counter eq $#word_key) {

			if ($#word_key > 0) {
				print "\(q$previous_state $rules[1] \"$word_key\" \"$word_key\"\)\) \n";			
				print "$rules[1] \($end_state *e* *e*\)\) \n";
			}

			else {
				print "$rules[0] $rules[1] \"$word_key\" \"$word_key\"\)\) \n";	
				print "$rules[1] \($end_state *e* *e*\)\) \n";
			}
		}

		elsif ($char_counter eq 0) {
			print "$rules[0] \(q$state_counter \"$word_key\" \"$word_key\"\)\) \n";
			$previous_state = $state_counter;
			$state_counter += 1;
		}

		else {
			print "\(q$previous_state \(q$state_counter \"$word_key\" \"$word_key\"\)\) \n";
			$previous_state = $state_counter;
			$state_counter += 1;
		}

	$char_counter += 1;

	}

}
