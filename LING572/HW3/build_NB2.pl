#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





$p_delta = $ARGV[2];
$c_delta = $ARGV[3];

%class = ();
%class_prob = ();
%class_logprob = ();

%class_word = ();
%class_word_prob = ();
%class_word_logprob = ();

%word_prob = ();
%wordlogprob = ();

%total_class_word = ();
%word = ();

$total_class = 0;
$class_label = 0;
$vocab = 0;

%train_instance = ();
%test_instance = ();


open($train_file, $ARGV[0]) or die "cannot open training file for input\n";
while($train_line = <$train_file>) {	## accept input from file

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $train_line;
	
	$train_instance{$temp_input[0]} = $train_line;
	$class{$temp_input[1]} += 1;
	$total_class += 1;

	for (my $cnt=2; $cnt<=$#temp_input; $cnt+=2)  {

		$class_word{$temp_input[1]}{$temp_input[$cnt]} += $temp_input[$cnt+1];
		$total_class_word{$temp_input[1]} += $temp_input[$cnt+1];
		$word{$temp_input[$cnt]} += $temp_input[$cnt];
	}
}

close $train_file;


foreach $key (sort keys %class) {

	$class_label += 1;
}


foreach $key (keys %word) {

	$vocab += 1;
}


calculate_prob ();
classify_train ();
classify_test ();
calc_acc_pipe ();





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub calculate_prob {

	open($model_file, '>>', $ARGV[4]) or die "cannot open model file for output\n";

	print {$model_file} "%%%%% prior prob P(c) %%%%% \n";
	
	foreach $key (sort keys %class) {

		$class_prob{$key} = ($p_delta + $class{$key})/(($p_delta * $class_label) + $total_class);
		$class_logprob{$key} = log(($p_delta + $class{$key})/(($p_delta * $class_label) + $total_class))/log(10);
		print {$model_file} $key, "\t", $class_prob{$key}, "\t", $class_logprob{$key}, "\n";
	}

	print {$model_file} "%%%%% conditional prob P(f|c) %%%%% \n";

	foreach $key (sort keys %class) {

		$class_str = $key;

		print {$model_file} "%%%%% conditional prob P(f|c) c=", $class_str, " %%%%%\n";

		foreach $key (sort keys %word) {

			$prob_w = 0;
			$l_prob_w = 0;

			$prob_w = ($c_delta + $class_word{$class_str}{$key})/(($c_delta * $vocab) + $total_class_word{$class_str});

			if ($prob_w ne 0) {
				
				$l_prob_w = log($prob_w)/log(10);
				$class_word_logprob{$class_str}{$key} = $l_prob_w;

				print {$model_file} $key, "\t", $class_str, "\t"; 
				print {$model_file} $prob_w, "\t";
				print {$model_file} $l_prob_w, "\n";
			} 
		}
	}

	close $model_file;
}





sub classify_train {

	open($sys_file, '>>', $ARGV[5]) or die "cannot open sys file for output\n";

	print {$sys_file} "%%%%% training data:\n";

	foreach $key (sort keys %train_instance) {

		$max_prob = -999999999;
		$max_sum = 0;
		$best_class = "";
		$prob_x = 0;
		%prob_cx_hash = ();

		$temp_str = "";
		@temp_input = ();	
		@temp_input = split /\s+/, $train_instance{$key};

		foreach $key (keys %class) {
			
			$c_prob = 0;
			$instance_prob = 0;
			$sum_yprob = 0;
			
			$class_str = "";
			$class_str = $key;

			$c_prob = $class_logprob{$class_str};

			for (my $cnt=2; $cnt<=$#temp_input; $cnt+=2) {
			
				$sum_yprob = $sum_yprob + (($temp_input[$cnt+1])*($class_word_logprob{$class_str}{$temp_input[$cnt]}));
			}

			$instance_prob = $c_prob + $sum_yprob;

			if ($instance_prob > $max_prob) {

				$max_prob = $instance_prob;
				$max_sum = $instance_prob;
				$best_class = $class_str;
			}

			$prob_cx_hash{$class_str} = $instance_prob;
		}

		foreach $key (keys %prob_cx_hash) {

			$prob_cx_hash{$key} = $prob_cx_hash{$key}-$max_sum;
			$prob_x += 10**$prob_cx_hash{$key};
		}

		print {$sys_file} $temp_input[0], " ", $temp_input[1], " ";

		foreach $key (sort {$prob_cx_hash{$b} <=> $prob_cx_hash{$a}} keys %prob_cx_hash) {

			print {$sys_file} $key, " ", (10**$prob_cx_hash{$key})/$prob_x, " " if ($prob_x ne 0); 
			print {$sys_file} $key, " ", "0", " " if ($prob_x eq 0); 
		}

		print {$sys_file} "\n";
	}

	print {$sys_file} "\n";
	print {$sys_file} "\n";
}





sub classify_test {

	open($test_file, $ARGV[1]) or die "cannot open training file for input\n";

	print {$sys_file} "%%%%% test data:\n";

	while($test_line = <$test_file>) {	## accept input from file

		$temp_str = "";
		@temp_input = ();	
		@temp_input = split /\s+/, $test_line;
	
		$test_instance{$temp_input[0]} = $test_line;
	}

	foreach $key (sort keys %test_instance) {

		$max_prob = -999999999;
		$max_sum = 0;
		$best_class = "";
		$prob_x = 0;
		%prob_cx_hash = ();

		$temp_str = "";
		@temp_input = ();	
		@temp_input = split /\s+/, $test_instance{$key};

		foreach $key (keys %class) {
			
			$c_prob = 0;
			$instance_prob = 0;
			$sum_yprob = 0;
			
			$class_str = "";
			$class_str = $key;

			$c_prob = $class_logprob{$class_str};

			for (my $cnt=2; $cnt<=$#temp_input; $cnt+=2) {
			
				$sum_yprob = $sum_yprob + (($temp_input[$cnt+1])*($class_word_logprob{$class_str}{$temp_input[$cnt]}));
			}

			$instance_prob = $c_prob + $sum_yprob;

			if ($instance_prob > $max_prob) {

				$max_prob = $instance_prob;
				$max_sum = $instance_prob;
				$best_class = $class_str;
			}

			$prob_cx_hash{$class_str} = $instance_prob;
		}

		foreach $key (keys %prob_cx_hash) {

			$prob_cx_hash{$key} = $prob_cx_hash{$key}-$max_sum;
			$prob_x += 10**$prob_cx_hash{$key};
		}

		print {$sys_file} $temp_input[0], " ", $temp_input[1], " ";

		foreach $key (sort {$prob_cx_hash{$b} <=> $prob_cx_hash{$a}} keys %prob_cx_hash) {

			print {$sys_file} $key, " ", (10**$prob_cx_hash{$key})/$prob_x, " " if ($prob_x ne 0); 
			print {$sys_file} $key, " ", "0", " " if ($prob_x eq 0); 
		}

		print {$sys_file} "\n";
	}

	close $sys_file;
	close $test_file;
}





sub calc_acc_pipe {

	open($sys_f, $ARGV[5]) or die "cannot open sys file for calculation\n";
	
	$guns = "talk.politics.guns";
	$mid = "talk.politics.mideast";
	$misc = "talk.politics.misc";

	$input_line = "";
	
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

	$t_total = 0;
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
		
			$t_total += 1;

			@temp_input = ();	
			@temp_input = split /\s+/, $input_line;

			$a_str = $temp_input[1];
			$t_str = $temp_input[2];

			if ($a_str eq $t_str) {

				$correct{$a_str} += 1;
			}

			elsif (($a_str ne $t_str) && ($a_str =~ /gun/ )) {


				if ($t_str =~ /mideast/) {

					$w_gun{$mid} += 1;
				}

				elsif ($t_str =~ /misc/) {

					$w_gun{$misc} += 1;
				}
			}

			elsif (($a_str ne $t_str) && ($a_str =~ /mideast/ )) {

				if ($t_str =~ /gun/) {

					$w_mid{$guns} += 1;
				}

				if ($t_str =~ /misc/) {

					$w_mid{$misc} += 1;
				}
			}
			
			elsif (($a_str ne $t_str) && ($a_str =~ /misc/ )) {

				if ($t_str =~ /gun/) {

					$w_misc{$guns} += 1;
				}

				if ($t_str =~ /mideast/) {

					$w_misc{$mid} += 1;
				}
			}
		}

		if (($test_flag eq "y") && (!($input_line =~ /%%%%% test/)) && ($input_line ne "")) {

			$tt_str = "";
			$aa_str = "";

			$tt_total += 1;

			@temp_input = ();	
			@temp_input = split /\s+/, $input_line;

			$aa_str = $temp_input[1];
			$tt_str = $temp_input[2];

			if ($aa_str eq $tt_str) {

				$t_correct{$aa_str} += 1;
			}

			elsif (($aa_str ne $tt_str) && ($aa_str =~ /gun/ )) {


				if ($tt_str =~ /mideast/) {

					$wt_gun{$mid} += 1;
				}

				elsif ($tt_str =~ /misc/) {

					$wt_gun{$misc} += 1;
				}
			}

			elsif (($aa_str ne $tt_str) && ($aa_str =~ /mideast/ )) {

				if ($tt_str =~ /gun/) {

					$wt_mid{$guns} += 1;
				}

				if ($tt_str =~ /misc/) {

					$wt_mid{$misc} += 1;
				}
			}
			
			elsif (($aa_str ne $tt_str) && ($aa_str =~ /misc/ )) {

				if ($tt_str =~ /gun/) {

					$wt_misc{$guns} += 1;
				}

				if ($tt_str =~ /mideast/) {

					$wt_misc{$mid} += 1;
				}
			}
		}
	}

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
