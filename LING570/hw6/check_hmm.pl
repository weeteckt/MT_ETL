#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





use POSIX qw(log10);


$input_hmm = "";
$i_cnt = 0;
$j_cnt = 0;
$k_cnt = 0;
$l_cnt = 0;
$state_id = 0;
$word_id = 0;
$epilson = 0.001;
$emission = 0;

@hmm_matrix = ();

$marker_cnt = 0;
$init_marker = "";
$transition_marker = "";
$emission_marker = "";
	


while($input_hmm = <STDIN>) {	## accept HMM input from file
    
	input_data();	
}

print_summary();
check_transition();

if ($emission eq 1) {

	check_3emission();
}

else {

	check_2emission();
}





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub input_data {

	@temp = ();
	@hmm_table = ();

	$input_hmm =~ s/< unk >/<unk>/;

	@hmm_table = split /\s+/, $input_hmm;
		
	

	if (($#hmm_table eq 0) && ($input_hmm =~ /=/) && ($input_hmm ne "")) {
	
		$input_hmm =~ s/=/ /;
		@temp = split /\s+/, $input_hmm;
		$hmm_summary{$temp[0]} = $temp[1];
		
	}

	elsif ($input_hmm =~ /\\init/) {
		
		$init_marker = "start";
		$init_prob{BOS} = 1;
	}

	elsif ($input_hmm =~ /\\transition/) {

		$transition_marker =  "start";
		$init_marker = "end";
	}
	
	elsif ($input_hmm =~ /\\emission/) {

		$emission_marker = "start";
		$transition_marker = "end";
	}

	elsif ($input_hmm ne "") {

		@hmm_table = ();
		$input_hmm =~ s/< unk >/<unk>/;
		@hmm_table = split /\s+/, $input_hmm;	

		if (($transition_marker eq "start") && ($emission_marker eq "")) {

			process_hmm_transition();
			
		}

		elsif (($transition_marker eq "end") && ($emission_marker eq "start"))  {

			process_hmm_emission();
		}
		
	}

	$marker_cnt += 1;
}





sub process_hmm_transition {

	if ($hmm_table[1] ne "" ) {

		$state_str = "";
		$state_str = $hmm_table[0] . " " . $hmm_table[1];
		$state_hash{$state_str} = $state_id;
		$aij_hash{$hmm_table[0]} += $hmm_table[2];

		$from_state[$i_cnt] = $hmm_table[0];
		$to_state[$j_cnt] = $hmm_table[1];
		$state_prob[$state_id] = $hmm_table[2]; 

		$state_id += 1;
		$i_cnt += 1;
		$j_cnt += 1;

		#print $hmm_table[0], "\t", $hmm_table[1], "\t", $hmm_table[2], "\n";
	}
}





sub process_hmm_emission {

	if ($hmm_table[1] ne "" ) {

		$word_str = "";
		$word_str = $hmm_table[0] . " " . $hmm_table[1];
		$word_hash{$word_str} = $word_id;

		$bjk_hash{$hmm_table[0]} += $hmm_table[2];
		
		$temp_o = $hmm_table[0];
		$temp_o =~ s/_/ /;
		@temp_b = split /\s+/, $temp_o;


		if ($#temp_b eq 1) {

			$emission = 1;
		}

		else {

			$emission = 2;
		}

			
		$temp_tw = $temp_b[1] . " " . $hmm_table[1];

		$t_w{$temp_tw} = $hmm_table[2];			
			
		$from_tag[$k_cnt] = $hmm_table[0];
		$to_word[$l_cnt] = $hmm_table[1];
		$word_prob[$word_id] = $hmm_table[2];	

		$word_id += 1;
		$k_cnt += 1;
		$l_cnt += 1;

		#print $temp_b[1], "\t", $hmm_table[0], "\t", $word_prob[word_id], "\n";
	}
}

		



sub print_summary {

	$counter = 0;
	
	print "state_num=", $hmm_summary{state_num}, "\n";	
	print "sym_num=", $hmm_summary{sym_num}, "\n";
	print "init_line_num=", $hmm_summary{init_line_num}, "\n";

	if (($#to_state+1) ne $hmm_summary{trans_line_num}) {

		print "warning: different numbers of trans_line_num: claimed=", $hmm_summary{trans_line_num}, ", real=", $#to_state+1, "\n";

	}

	else {

		print "transmission_line_num=", $hmm_summary{trans_line_num}, "\n";
	}

	if (($#to_word+1) ne $hmm_summary{emiss_line_num}) {

		print "warning: different numbers of emiss_line_num: claimed=", $hmm_summary{emiss_line_num}, ", real=", $#to_word+1, "\n";

	}

	else {

		print "emission_line_num=", $hmm_summary{emiss_line_num}, "\n";
		
	}	
	
}





sub check_transition {

	foreach $key (sort keys %aij_hash) {

		$aij_prob = $aij_hash{$key};

		if ($aij_prob >= 0.999) {

			if ($aij_prob <= 1.001) {
					
			}

			else {
				print "warning: the trans_prob_sum for state ", $key, " is ", $aij_prob, "\n";
			}
		}

		elsif ($aij_prob <= 1.001) {
					
			if ($aij_prob >= 0.999) {

			}

			else {
				print "warning: the trans_prob_sum for state ", $key, " is ", $aij_prob, "\n";
			}
		}
			
		else {
						
			print "warning: the trans_prob_sum for state ", $key, " is ", $aij_prob, "\n";
		}
	}
}





sub check_3emission {


		for ($cnt=0; $cnt<$#from_tag; $cnt++) {

			$t_s = $from_tag[$cnt];
			$t_s =~ s/_/ /;
			@t_q = split /\s+/, $t_s;

			$sum_f{$t_q[0]} += 1;
			$sum_t{$t_q[1]} += 1;
			$sum_p{$t_q[1]} += $word_prob[cnt];
		}

		foreach $key (sort keys %t_w) {

			$t_prob = $key;
			$t_prob =~ s/_/ /;
			@tprob = split /\s+/, $t_prob;
			$tag_prob{$tprob[0]} += $t_w{$key};
		}

		foreach $key (sort keys %tag_prob) {

			#print $key, " ", $tag_prob{$key}, "\n";
		}

		for ($cnt=0; $cnt<$#from_tag; $cnt++) {

			$bjk_t = $from_tag[$cnt];
			$bjk_t =~ s/_/ /;
			@bjk_h = split /\s+/, $bjk_t;

			$f = $bjk_h[0];
			$t = $bjk_h[1];

			if (exists ($tag_prob{$t})) {
				
				#if (($tag_prob{$t} >= (1-$epilson)) && ($tag_prob{$t} <= (1+$epilson)))  {

				if ($tag_prob{$t} >= 0.999) {

					if ($tag_prob{$t} <= 1.001) {
					
					}

					else {

						print "warning: the emiss_prob_sum for state ", $bjk_t, " is ", $tag_prob{$t}, "\n";
					}
				}

				elsif ($tag_prob{$t} <= 1.001) {
					
					if ($tag_prob{$t} >= 0.999) {

					}

					else {

						print "warning: the emiss_prob_sum for state ", $bjk_t, " is ", $tag_prob{$t}, "\n";
					}
				}
			
				else {
			
					print "warning: the emiss_prob_sum for state ", $bjk_t, " is ", $tag_prob{$t}, "\n";
				}
			}
		}
}





sub check_2emission {

	foreach $key (sort keys %bjk_hash) {

		$bjk_prob = $bjk_hash{$key};

		#if ($bjk_prob eq 1) {

		if (!(($bjk_prob >= (1-$epilson)) && ($bjk_prob <= (1+$epilson)))) {

			print "warning: the emiss_prob_sum for state ", $key, " is ", $bjk_prob, "\n";
		}
	}
}


