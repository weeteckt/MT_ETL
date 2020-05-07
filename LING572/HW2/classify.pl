#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





%class_table = ();
%master_instance_table = ();
@ran = {1, 2, 3};

$model = $ARGV[2];
$sys = $ARGV[3];
#$acc = $ARGV[4];

open($train_file, $ARGV[0]) or die "cannot open training file for input\n";
open($test_file, $ARGV[1]) or die "cannot open test file for input\n";
#open($model_file, '>>', $model) or die "cannot find model file\n";


process_input();
classify();
calc_acc();





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub process_input {

	$input_line = "";
	$test_line = "";
	$total_instance = 0;

	while(($input_line = <$train_file>)) {	## accept input from file

		$temp_str = "";
		@temp_input = ();	
		@temp_input = split /\s+/, $input_line;

		$temp_str = $temp_input[0] . " " . $temp_input[1];

		$master_instance_table{$temp_str} = $input_line;
		$class_table{$temp_input[1]} += 1;
	}

	while(($test_line = <$test_file>)) {	## accept input from file

		$temp_str = "";
		@temp_input = ();	
		@temp_input = split /\s+/, $test_line;

		$temp_str = $temp_input[0] . " " . $temp_input[1];

		$test_instance_table{$temp_str} = $test_line;
	}
}





sub classify {

	open($model_f, $model) or die "cannot open model file for classification\n";

	%model_hash = ();
	$input_line = "";

	while(($input_line = <$model_f>)) {	## accept input from file

		$temp_str = "";
		$l_prob = 0;
		$l_class = "";
		$c = 0;
		%class_ran = ();
		@temp_input = ();	
		@temp_input = split /\s+/, $input_line;

		for (my $cnt=3; $cnt<=$#temp_input; $cnt+=2)  {
			
			if ($temp_input[$cnt] > $l_prob) {

				$l_prob = $temp_input[$cnt];
				$l_class = $temp_input[$cnt-1];
			}
		}

		$model_hash{$temp_input[0]} = $l_class . " " . $temp_input[2] . " " . $temp_input[3] . " " . $temp_input[4] . " " . $temp_input[5] . " " . $temp_input[6] . " " . $temp_input[7];
	}

	classify_train();
	classify_test();
}





sub classify_train {

	open($sys_f, '>>', $sys) or die "cannot open sys file for output\n";
	
	print {$sys_f} "%%%%% training data:", "\n";

	foreach $key (keys %master_instance_table) {
			
		$temp_m = "";
		@t_m = ();
		%word_h = ();

		$best_count = 0;
		$best_class = "";
		$max_prob = 0;
		$best_model = "";

		$temp_m = $master_instance_table{$key};
		@t_m = split /\s+/, $temp_m;

		for (my $cnt=2; $cnt<=$#t_m; $cnt+=2)  {
			
			$word_h{$t_m[$cnt]} = $t_m[$cnt];
		}

		foreach $key (keys %model_hash) {

			$hash_line;
			$hash_line = $key;
			$hash_line =~ s/&/ /g;
			@temp_h = ();
			
			$t_prob = 0;
			
			$t_count = 0;
			$n_count = 0;
			$y_count = 0;

			@temp_h = split /\s+/, $hash_line;
			
			for (my $cnt=0; $cnt<=$#temp_h; $cnt++)  {
		
				$tree_str = "";
				$tree_str = $temp_h[$cnt];
				
				if ($tree_str =~ /!/) {

					$tree_str =~ s/!//;
					
					if (!(exists $word_h{$tree_str})){

						$n_count += 1;
					}
				}
	
				elsif (!($tree_str =~ /!/)) {

					if (exists $word_h{$tree_str}){

						$y_count += 1;
					}		
				}
				
				$t_count += 1;
			}

			if ($#temp_h > 0) {

				$t_prob = ($n_count + $y_count) / $t_count;
			}

			if ($t_prob > $max_prob) {
			
				$max_prob = $t_prob;
				$best_model = $key;
			}
		}

		print {$sys_f} $t_m[0], " ", $model_hash{$best_model}, "\n";
	}

	close $sys_f;
}





sub classify_test {

	open($sys_f, '>>', $sys) or die "cannot open sys file for output\n";
	
	print {$sys_f} "\n";
	print {$sys_f} "%%%%% test data:", "\n";

	foreach $key (keys %test_instance_table) {
			
		$temp_m = "";
		@t_m = ();
		%word_h = ();

		$best_count = 0;
		$best_class = "";
		$max_prob = 0;
		$best_model = "";

		$temp_m = $test_instance_table{$key};
		@t_m = split /\s+/, $temp_m;

		for (my $cnt=2; $cnt<=$#t_m; $cnt+=2)  {
			
			$word_h{$t_m[$cnt]} = $t_m[$cnt];
		}

		foreach $key (keys %model_hash) {

			$hash_line;
			$hash_line = $key;
			$hash_line =~ s/&/ /g;
			@temp_h = ();
			
			$t_prob = 0;
			
			$t_count = 0;
			$n_count = 0;
			$y_count = 0;

			@temp_h = split /\s+/, $hash_line;
			
			for (my $cnt=0; $cnt<=$#temp_h; $cnt++)  {
		
				$tree_str = "";
				$tree_str = $temp_h[$cnt];
				
				if ($tree_str =~ /!/) {

					$tree_str =~ s/!//;
					
					if (!(exists $word_h{$tree_str})){

						$n_count += 1;
					}
				}
	
				elsif (!($tree_str =~ /!/)) {

					if (exists $word_h{$tree_str}){

						$y_count += 1;
					}		
				}
				
				$t_count += 1;
			}

			if ($#temp_h > 0) {

				$t_prob = ($n_count + $y_count) / $t_count;
			}

			if ($t_prob > $max_prob) {
			
				$max_prob = $t_prob;
				$best_model = $key;
			}
		}

		print {$sys_f} $t_m[0], " ", $model_hash{$best_model}, "\n";
	}

	close $sys_f;
}





sub calc_acc {

	open($sys_f, $sys) or die "cannot open sys file for calculation\n";
	#open($acc_f, '>>', $acc) or die "cannot open accuracy file for output\n";

	$guns = "talk.politics.guns";
	$mid = "talk.politics.mideast";
	$misc = "talk.politics.misc";

	$input_line = "";
	
	$t_total = 0;
	
	$w_gun{$guns} = 0;
	$w_gun{$mid} = 0;
	$w_gun{$misc} = 0;

	$w_mid{$guns} = 0;
	$w_mid{$mid} = 0;
	$w_mid{$misc} = 0;

	$w_misc{$guns} = 0;
	$w_misc{$mid} = 0;
	$w_misc{$misc} = 0;

	$wt_gun{$guns} = 0;
	$wt_gun{$mid} = 0;
	$wt_gun{$misc} = 0;

	$wt_mid{$guns} = 0;
	$wt_mid{$mid} = 0;
	$wt_mid{$misc} = 0;

	$wt_misc{$guns} = 0;
	$wt_misc{$mid} = 0;
	$wt_misc{$misc} = 0;

	$correct{$guns} = 0;
	$correct{$mid} = 0;
	$correct{$misc} = 0;

	$t_correct{$guns} = 0;
	$t_correct{$mid} = 0;
	$t_correct{$misc} = 0;

	%wrong = ();
	%t_wrong = ();

	$tt_total = 0;

	$test_flag = "n";
	$train_flag = "y";

	while(chomp($input_line = <$sys_f>)) {	## accept input from file

		if ($input_line =~ /%%%%% test data:/) {

			$test_flag = "y";
		}

		if (($test_flag eq "n") && (!($input_line =~ /%%%%% training/)) && ($input_line ne "")) {

			$t_str = "";
			$a_str = "";
			$c_str = "";
			$l_cnt = 0;
		
			$t_total += 1;

			@temp_input = ();	
			@temp_input = split /\s+/, $input_line;

			for (my $cnt=3; $cnt<=$#temp_input; $cnt+=2)  {

				if ($temp_input[$cnt] > $l_cnt) {

					$l_cnt = $temp_input[$cnt];
					$c_str = $temp_input[$cnt-1];
				}
			}

			$t_str = $temp_input[0];
			$t_str =~ s/\/[0-9]*//g;
			$t_str =~ s/\.\.\_newsgroups//g;
			$t_str =~ s/\s+//g;

			$a_str = $temp_input[1];

			if ($a_str eq $t_str) {

				if ($a_str eq $c_str) {

					$correct{$a_str} += 1;
				}

				else {

					$wrong{$a_str} += 1;
				}
			}

			if ($t_str ne $c_str) {

				if ($c_str =~ /gun/) {

					$w_gun{$t_str} += 1;
				}

				if ($c_str =~ /mideast/) {

					$w_mid{$t_str} += 1;
				}

				if ($c_str =~ /misc/) {

					$w_misc{$t_str} += 1;
				}
			}

			if ($a_str ne $c_str) {

				if ($c_str =~ /gun/) {

					$w_gun{$a_str} += 1;
				}

				if ($c_str =~ /mideast/) {

					$w_mid{$a_str} += 1;
				}

				if ($c_str =~ /misc/) {

					$w_misc{$a_str} += 1;
				}
			}
		}

		if (($test_flag eq "y") && (!($input_line =~ /%%%%% test/)) && ($input_line ne "")) {

			$tt_str = "";
			$aa_str = "";
			$cc_str = "";
			$ll_cnt = 0;

			$tt_total += 1;

			@temp_input = ();	
			@temp_input = split /\s+/, $input_line;

			for (my $cnt=3; $cnt<=$#temp_input; $cnt+=2)  {

				if ($temp_input[$cnt] > $ll_cnt) {

					$ll_cnt = $temp_input[$cnt];
					$cc_str = $temp_input[$cnt-1];
				}
			}

			$tt_str = $temp_input[0];
			$tt_str =~ s/\/[0-9]*//g;
			$tt_str =~ s/\.\.\_newsgroups//g;
			$tt_str =~ s/\s+//g;

			$aa_str = $temp_input[1];

			if ($aa_str eq $tt_str) {

				if ($aa_str eq $cc_str) {

					$t_correct{$aa_str} += 1;
				}

				else {

					$t_wrong{$aa_str} += 1;
				}
			}

			if ($tt_str ne $cc_str) {

				if ($cc_str =~ /gun/) {

					$wt_gun{$tt_str} += 1;
				}

				if ($cc_str =~ /mideast/) {

					$wt_mid{$tt_str} += 1;
				}

				if ($cc_str =~ /misc/) {

					$wt_misc{$tt_str} += 1;
				}
			}

			if ($aa_str ne $cc_str) {

				if ($cc_str =~ /gun/) {

					$wt_gun{$aa_str} += 1;
				}

				if ($cc_str =~ /mideast/) {

					$wt_mid{$aa_str} += 1;
				}

				if ($cc_str =~ /misc/) {

					$wt_misc{$aa_str} += 1;
				}
			}
		}
	}

	#print {$acc_f} "Confusion matrix for the training data:", "\n";
	#print {$acc_f} "row is the truth, column is the system output", "\n";
	#print {$acc_f} "\n";
	#print {$acc_f} "\t", "\t", "talk.politics.guns talk.politics.misc talk.politics.mideast", "\n";
	#print {$acc_f} "talk.politics.guns", "\t", $correct{$guns}, "\t\t", $w_gun{$misc}, "\t\t", $w_gun{$mid}, "\n"; 
	#print {$acc_f} "talk.politics.misc", "\t", $w_misc{$guns}, "\t\t", $correct{$misc}, "\t\t", $w_misc{$mid}, "\n"; 
	#print {$acc_f} "talk.politics.mideast", "\t", $w_mid{$guns}, "\t\t", $w_mid{$misc}, "\t\t", $correct{$mid}, "\n"; 
	#print {$acc_f} "\n";
	#print {$acc_f} " Training accuracy=", ($correct{$guns} + $correct{$misc} + $correct{$mid})/$t_total, "\n";
	#print {$acc_f} "\n";
	#print {$acc_f} "\n";

	#print {$acc_f} "Confusion matrix for the test data:", "\n";
	#print {$acc_f} "row is the truth, column is the system output", "\n";
	#print {$acc_f} "\n";
	#print {$acc_f} "\t", "\t", "talk.politics.guns talk.politics.misc talk.politics.mideast", "\n";
	#print {$acc_f} "talk.politics.guns", "\t", $t_correct{$guns}, "\t\t", $wt_gun{$misc}, "\t\t", $wt_gun{$mid}, "\n"; 
	#print {$acc_f} "talk.politics.misc", "\t", $wt_misc{$guns}, "\t\t", $t_correct{$misc}, "\t\t", $wt_misc{$mid}, "\n"; 
	#print {$acc_f} "talk.politics.mideast", "\t", $wt_mid{$guns}, "\t\t", $wt_mid{$misc}, "\t\t", $t_correct{$mid}, "\n"; 
	#print {$acc_f} "\n";
	#print {$acc_f} " Test accuracy=", ($t_correct{$guns} + $t_correct{$misc} + $t_correct{$mid})/$tt_total, "\n";
	#print {$acc_f} "\n";



	print "Confusion matrix for the training data:", "\n";
	print "row is the truth, column is the system output", "\n";
	print "\n";
	print "\t", "\t", "talk.politics.guns talk.politics.misc talk.politics.mideast", "\n";
	print "talk.politics.guns", "\t", $correct{$guns}, "\t\t", $w_gun{$misc}, "\t\t", $w_gun{$mid}, "\n"; 
	print "talk.politics.misc", "\t", $w_misc{$guns}, "\t\t", $correct{$misc}, "\t\t", $w_misc{$mid}, "\n"; 
	print "talk.politics.mideast", "\t", $w_mid{$guns}, "\t\t", $w_mid{$misc}, "\t\t", $correct{$mid}, "\n"; 
	print "\n";
	print " Training accuracy=", ($correct{$guns} + $correct{$misc} + $correct{$mid})/$t_total, "\n";
	print "\n";
	print "\n";

	print "Confusion matrix for the test data:", "\n";
	print "row is the truth, column is the system output", "\n";
	print "\n";
	print "\t", "\t", "talk.politics.guns talk.politics.misc talk.politics.mideast", "\n";
	print "talk.politics.guns", "\t", $t_correct{$guns}, "\t\t", $wt_gun{$misc}, "\t\t", $wt_gun{$mid}, "\n"; 
	print "talk.politics.misc", "\t", $wt_misc{$guns}, "\t\t", $t_correct{$misc}, "\t\t", $wt_misc{$mid}, "\n"; 
	print "talk.politics.mideast", "\t", $wt_mid{$guns}, "\t\t", $wt_mid{$misc}, "\t\t", $t_correct{$mid}, "\n"; 
	print "\n";
	print " Test accuracy=", ($t_correct{$guns} + $t_correct{$misc} + $t_correct{$mid})/$tt_total, "\n";
	print "\n";


}





































