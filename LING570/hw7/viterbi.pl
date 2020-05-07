#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





use POSIX qw(log10);


$input_hmm = "";
$i_c = 0;
$j_c = 0;
$k_c = 0;
$n = 0;
$unk = "<unk>";
$from_cnt = 0;
$to_cnt = 0;
$state_id = 0;
$state_count = 0;

$word_id = 0;

@hmm_matrix = ();

$marker_cnt = 0;
$init_marker = "";
$transition_marker = "";
$emission_marker = "";	


open ($hmm_file, $ARGV[0]) or die "please provide input hmm filename\n";
open ($o_file, $ARGV[1]) or die "please provide input observation filename\n";


while($input_hmm = <$hmm_file>) {	## accept HMM input from file
    
	load_hmm();	
}



while($o_input = <$o_file>) {	## accept observation input from file
    
	@o_table = ();	
	@o_table = split /\s+/, $o_input;
	do_viterbi();
	print_result();	
}





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub load_hmm {

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
		$init_prob{BOS_BOS} = 1;
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

	
	if (($hmm_table[0] ne "") && ($hmm_table[1] ne "")) {

		$aij{$hmm_table[0]}{$hmm_table[1]} = log10($hmm_table[2]);

		$from_state{$hmm_table[0]} = 1;	
	}
}





sub process_hmm_emission {

	if (($hmm_table[1] ne "" ) && ($hmm_table[0] ne "")) {

		$bjk{$hmm_table[0]}{$hmm_table[1]} = log10($hmm_table[2]);

		$word{$hmm_table[1]} = 1;
		
		$to_state{$hmm_table[0]} = 1;

	}
}

		



sub do_viterbi {

	$i_cnt = 0;	
	$j_cnt = 0;
	@back_p = ();
	@delta_p = ();
	@f_pointer = ();
	@f_vals = ();
	$large_i = 0;
	$last_state = "";

	@delta = ();
	@bk_pointer = ();
	

	foreach $key (sort keys %from_state) {  

		$delta[0][$key] = 0;
		$bk_pointer[0][$key] = -1;
	}

	for ($t=0; $t<=$#o_table; $t++) {

		
		@i_vals = ();
		@backpointer = ();
		@delta_p = ();
		@back_p = ();
		

		$k = $o_table[$t];

		foreach $key (keys %from_state) { 

			$i = $key;
			$emit = 0;
			$emit_p = 0;
			
			$emit_max = -100000000;

			

			if ((exists ($bjk{i}{$unk})) && (!(exists ($word{$k})))) {
						
				$emit = $bjk{$i}{$unk};	
				
			}

			elsif (exists ($bjk{$i}{$k})) {

				$emit = $bjk{$i}{$k};
			}

			else {

				$emit = 0;
			}
			
			if ($emit ne 0) {

				foreach $key (keys %to_state) {

					$j = $key;

					$emit_p = $delta[$t][$j] + $aij{$i}{$j} + $emit;
			
					if (($emit_p > $emit_max) && ($emit_p ne 0)) {	

						$v_max = $emit_p;
						$emit_max = $emit_p;
						$i_max = $i;
					}
					
				}
					
			}
			
			$bk_pointer[$t+1][$j] = $i_max;
			$delta[$t+1][$j] = $v_max;

			push(@backpointer, $i_max);
			push(@i_vals, $v_max);	
		}

		push(@f_pointer, [@backpointer]);
		push(@f_vals, [@i_vals]);
				
	}


	$large_i = -100000000;
	$last_state = "";
	$total = 0;

	for ($i_cnt=0; $i_cnt<=$#i_vals; $i_cnt++) {
		
		if (($f_vals[$#o_table][$i_cnt] > $large_i) && ($f_vals[$#o_table][$i_cnt] ne 0)) {
			
			$large_i = $f_vals[$#o_table][$i_cnt];
			$last_state = $f_pointer[$#o_table][$i_cnt];

			#print $f_pointer[$#o_table][$i_cnt], "\n";
		}
		
	}

	push (@back_p, $last_state);
	push (@delta_p, $large_i);

	for ($t=$#o_table; $t>0; $t--) {

		$i_pt = $bk_pointer[$t][$last_state];
		$i_prob = $delta[$t][$last_state];
		$total += $i_prob;
		push (@back_p, $i_pt);
		push (@delta_p, $i_prob); 

		$last_state = $i_pt;
	}
}

	



sub print_result {

	for ($t=0; $t<=$#o_table; $t++) {

		print $o_table[$t], " ";
	}
	
	print "=> ";

	for ($t=$#o_table; $t>0; $t--) {

		print $back_p[$t], " ";  
	}

	print $total, "\n";
}
