#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





$k_value = $ARGV[2];
$sim_func = $ARGV[3];

$feat_count = 0;

%class = ();
%word = ();

%train_instance = ();
%test_instance = ();


open($train_file, $ARGV[0]) or die "cannot open training file for input\n";
while($train_line = <$train_file>) {

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $train_line;
	
	$train_instance{$temp_input[0]} = $train_line;

	$class{$temp_input[1]} = 0;

	for (my $cnt=2; $cnt<$#temp_input; $cnt+=2)  {

		$word{$temp_input[$cnt]} += $temp_input[$cnt+1];
	}
}



open($test_file, $ARGV[1]) or die "cannot open test file for input\n";
while($test_line = <$test_file>) {

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $test_line;
	
	$test_instance{$temp_input[0]} = $test_line;
}


close $train_file;
close $test_file;


if ($sim_func eq 1) {

	open($sys_file, '>>', $ARGV[4]) or die "cannot open sys file for output\n";

	euclidean ();

	close $sys_file;
}

elsif ($sim_func eq 2) {

	open($sys_file, '>>', $ARGV[4]) or die "cannot open sys file for output\n";

	cosine ();

	close $sys_file;
}


calc_acc_pipe ();

foreach $key (keys %word) {

	$feat_count += 1;
}


open($feat_cnt, '>>', "feature_count");
print {$feat_cnt} "number of feature for ", $ARGV[0], "=", $feat_count, "\n";
close $feat_cnt;


#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub euclidean {

	print {$sys_file} "%%%%% test data:\n";

	foreach $key (sort keys %test_instance) {

		$query_key = "";
		%query_hash = ();

		%vocab_test = ();

		%ranking = ();
		@sorted_rank = ();
		
		$query_key = $key;
		@query_input = ();	
		@query_input = split /\s+/, $test_instance{$query_key};

		foreach $key (keys %class) {
		
			$class{$key} = 0;	
		}

		for (my $q_cnt=2; $q_cnt<$#query_input; $q_cnt+=2) {

			$query_hash{$query_input[$q_cnt]} = $query_input[$q_cnt+1];

			if (exists $word{$query_input[$q_cnt]}) {
	
				$vocab_test{$query_input[$q_cnt]} = $query_input[$q_cnt+1];
			}
		}

		foreach $key (keys %train_instance) {
			
			$sqroot = 0;
			$sum_sqr = 0;

			$master_key = "";
			%master_hash = ();

			$master_key = $key;
			@master_input = ();	
			@master_input = split /\s+/, $train_instance{$master_key};

			for (my $m_cnt=2; $m_cnt<$#master_input; $m_cnt+=2) {
	
				$master_hash{$master_input[$m_cnt]} = $master_input[$m_cnt+1];
				$sum_sqr += (($master_input[$m_cnt+1] - $query_hash{$master_input[$m_cnt]})**2);
			}

			foreach $key (keys %vocab_test) {

				if (!(exists $master_hash{$key})) {

					$sum_sqr += (($vocab_test{$key})**2);
				}
			}

			$sqroot = sqrt($sum_sqr);
			$ranking{$master_key} = $sqroot;
		}

		#foreach $key (keys %ranking) {

		#	print $key, "\t", $query_key, "\t", $ranking{$key}, "\n";
		#}

		@sorted_rank = sort ({$ranking{$a} <=> $ranking{$b}} keys %ranking); 

		for (my $t_cnt=0; $t_cnt<$k_value; $t_cnt++) {

			$t_str = $sorted_rank[$t_cnt];
			$t_str =~ s/\/[0-9]*//g;
			$t_str =~ s/\.\.\_newsgroups//g;
			$t_str =~ s/\s+//g;

			$class{$t_str} += 1;
		}

		print {$sys_file} $query_input[0], " ", $query_input[1], " ";

		foreach $key (sort {$class{$b} <=> $class{$a}} keys %class) {

			print {$sys_file} $key, " ", $class{$key}/$k_value, " ";
		}

		print {$sys_file} "\n";
	}

	print {$sys_file} "\n";
	print {$sys_file} "\n";
}





sub cosine {

	print {$sys_file} "%%%%% test data:\n";

	foreach $key (sort keys %test_instance) {

		$query_key = "";
		%query_hash = ();
		$sum_j2 = 0;

		%ranking = ();
		%vocab_test = ();

		@sorted_rank = ();
		
		$query_key = $key;
		@query_input = ();	
		@query_input = split /\s+/, $test_instance{$key};

		foreach $key (keys %class) {
		
			$class{$key} = 0;	
		}

		for (my $q_cnt=2; $q_cnt<$#query_input; $q_cnt+=2) {

			$query_hash{$query_input[$q_cnt]} = $query_input[$q_cnt+1];
			$sum_j2 += ($query_input[$q_cnt+1]**2);
		}

		$sum_j2 = sqrt($sum_j2);

		foreach $key (keys %train_instance) {
			
			$sum_sqroot = 0;
			$sum_ij = 0;
			$sum_i2 = 0;
			
			$master_key = "";
			%master_hash = ();

			$master_key = $key;
			@master_input = ();	
			@master_input = split /\s+/, $train_instance{$master_key};

			for (my $m_cnt=2; $m_cnt<$#master_input; $m_cnt+=2) {
	
				$master_hash{$master_input[$m_cnt]} = $master_input[$m_cnt+1];

				$sum_ij += ($master_input[$m_cnt+1] * $query_hash{$master_input[$m_cnt]});
				$sum_i2 += ($master_input[$m_cnt+1]**2);
			}

			$sum_i2 = sqrt($sum_i2);
			
			if (sqrt($sum_i2)*sqrt($sum_j2) ne 0) {

				$sum_sqroot = $sum_ij/($sum_i2*$sum_j2);
			}

			$ranking{$master_key} = $sum_sqroot;
		}

		#foreach $key (keys %ranking) {

		#	print $key, "\t", $query_key, "\t", $ranking{$key}, "\n";
		#}

		@sorted_rank = sort ({$ranking{$b} <=> $ranking{$a}} keys %ranking); 

		for (my $t_cnt=0; $t_cnt<$k_value; $t_cnt++) {

			$t_str = $sorted_rank[$t_cnt];
			$t_str =~ s/\/[0-9]*//g;
			$t_str =~ s/\.\.\_newsgroups//g;
			$t_str =~ s/\s+//g;

			$class{$t_str} += 1;
		}

		print {$sys_file} $query_input[0], " ", $query_input[1], " ";

		foreach $key (sort {$class{$b} <=> $class{$a}} keys %class) {

			print {$sys_file} $key, " ", $class{$key}/$k_value, " ";
		}

		print {$sys_file} "\n";
	}

	print {$sys_file} "\n";
	print {$sys_file} "\n";
}





sub calc_acc_pipe {

	open($sys_f, $ARGV[4]) or die "cannot open sys file for calculation\n";
	
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

	$correct{$guns} = 0;
	$correct{$mid} = 0;
	$correct{$misc} = 0;

	$t_total = 0;

	while(chomp($input_line = <$sys_f>)) {	## accept input from file

		if ((!($input_line =~ /%%%%% test data/)) && ($input_line ne "")) {

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
	}

	print "Confusion matrix for the test data:", "\n";
	print "row is the truth, column is the system output", "\n";
	print "\n";
	print "\t", "\t", "talk.politics.guns talk.politics.misc talk.politics.mideast", "\n";
	print "talk.politics.guns", "\t", $correct{$guns}, "\t\t", $w_gun{$misc}, "\t\t", $w_gun{$mid}, "\n"; 
	print "talk.politics.misc", "\t", $w_misc{$guns}, "\t\t", $correct{$misc}, "\t\t", $w_misc{$mid}, "\n"; 
	print "talk.politics.mideast", "\t", $w_mid{$guns}, "\t\t", $w_mid{$misc}, "\t\t", $correct{$mid}, "\n"; 
	print "\n";
	print " Test accuracy=", ($correct{$guns} + $correct{$misc} + $correct{$mid})/$t_total, "\n";
	print "\n";
	print "\n";
}

