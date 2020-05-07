#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





%master_feature_table = ();
%master_feature_class_table = ();
%class_table = ();
%master_instance_table = ();
%test_instance_table = ();
%best_feature_path = ();
%best_feature_count = ();

$tree_depth = $ARGV[2];
$min_gain = $ARGV[3];
$model = $ARGV[4];
$sys = $ARGV[5];
$acc = $ARGV[6];

$depth = 0;
$level = 0;


open($train_file, $ARGV[0]) or die "cannot open training file for input\n";
open($test_file, $ARGV[1]) or die "cannot open test file for input\n";
open($model_file, '>>', $model) or die "cannot find model file\n";


if ($tree_depth <= 0) {

	print "Please enter a tree depth of more than 0", "\n";
}


else {
	process_input();

	%instance_table = %master_instance_table;
	%feature_table = %master_feature_table;
	%feature_class_table = %master_feature_class_table;
	$parent = "";
	$l_child = "";
	$r_child = "";

	$top_entropy = 0;
	
	foreach $key (keys %class_table) {

		if ($class_table{$key} ne 0) {

			$top_entropy = $top_entropy + (-($class_table{$key}/$total_instance)*(log($class_table{$key}/$total_instance)/log(2)));
		}
	}
	
	find_best_feature();
	#$depth += 1;
	$level = 1;
	$r_level = 1;

	process_decision($best_feature);
	

	#output_result();
	#output_model();
	classify();
	calc_acc();
}





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
		$total_instance += 1;

		for (my $cnt=2; $cnt<=$#temp_input; $cnt+=2)  {

			$master_feature_table{$temp_input[$cnt]} += 1;
			$master_feature_class_table{$temp_input[1]}{$temp_input[$cnt]} += 1;
		}
	}

	while(($test_line = <$test_file>)) {	## accept input from file

		$temp_str = "";
		@temp_input = ();	
		@temp_input = split /\s+/, $test_line;

		$temp_str = $temp_input[0] . " " . $temp_input[1];

		$test_instance_table{$temp_str} = $test_line;
	}
}

		



sub process_decision {

	my $best_feature = @_;

	split_tree($best_feature);


	#if (($depth < $tree_depth) && ($max_ent >= $min_gain)) {

	if ($left_flag eq "yes") {

		%feature_table = ();
		%feature_class_table = ();
		%instance_table = ();

		$parent = $new_l_path;
				
		%instance_table = %left_instance;
		%feature_table = %l_feature_table;
		%feature_class_table = %l_feature_class;

		foreach $key(keys %class_table) {

			if (exists $l_class_table{$key}) {

				$class_table{$key} = $l_class_table{$key};
			}

			else {

				$class_table{$key} = 0;
			}
		}
				
		$top_entroy = $n_entropy;
		$l_feature = find_best_feature();

		$depth += 1;

		if (($depth < $tree_depth) && ($max_ent >= $min_gain)) {
			process_decision($l_feature);
		}
	}

	if ($right_flag eq "yes") {
		
		%feature_table = ();
		%feature_class_table = ();
		%instance_table = ();

		$parent = $new_r_path;

		%instance_table = %right_instance;
		%feature_table = %r_feature_table;
		%feature_class_table = %r_feature_class;
		
		foreach $key(keys %class_table) {

			if (exists $r_class_table{$key}) {

				$class_table{$key} = $r_class_table{$key};
			}

			else {

				$class_table{$key} = 0;
			}
		}

		$top_entroy = $y_entropy;
		find_best_feature();
		$r_feature = find_best_feature();
		
		$depth += 1;
		if (($depth < $tree_depth) && ($max_ent >= $min_gain)) {
			process_decision($l_feature);
		}
	}

	

}







sub find_best_feature {

	$max_ent = 0;
	$best_feature = "";
	
	foreach $key (keys %feature_table) {

		$y_entropy = 0;
		$n_entropy = 0;
		$y_total_count = 0;
		$n_total_count = 0;
		$info_gain = 0;
		$curr_feat = $key;
		$sub_count = 0;

		$y_total_count = $feature_table{$key};
		$n_total_count = $total_instance - $y_total_count;

		if ($y_total_count > 0) {
		
			foreach $key (keys %feature_class_table) {

				$y_class_count = 0;
				$n_class_count = 0;
				$y_class_count = $feature_class_table{$key}{$curr_feat};
				$sub_count += $y_class_count;
				$n_class_count = $class_table{$key} - $y_class_count;

				if ($y_class_count > 0) {
				
					$y_entropy = $y_entropy + (-($y_class_count/$y_total_count)*(log($y_class_count/$y_total_count)/log(2)));
				}

				if ($n_class_count > 0) {

					$n_entropy = $n_entropy + (-($n_class_count/$n_total_count)*(log($n_class_count/$n_total_count)/log(2)));
				}
			}
		}

		$info_gain = $top_entropy - ((($sub_count/$total_instance)*$y_entropy) + ((($total_instance-$sub_count)/$total_instance)*$n_entropy));
		

		if ($info_gain > $max_ent) {

			$max_ent = $info_gain;
			$best_feature = $curr_feat;
		}
	} 

	#print $best_feature, " ", $max_ent;
	return $best_feature;
}





sub split_tree {

	my $b_feature = $best_feature;
	my $depth = $level;

	%left_instance = ();
	%right_instance = ();
	%l_class_table = ();
	%r_class_table = ();
	%l_feature_class = ();
	%r_feature_class = ();
	%l_feature_table = ();
	%r_feature_table = ();
	$left_flag = "false";
	$right_flag = "false";

	$new_l_path = "";
	$new_r_path = "";

	$l_cnt = 0;
	$r_cnt = 0;

	$l_child = $b_feature;
	$r_child = "!" . $b_feature;

	if ($parent ne "") {

		$new_l_path = $parent . "&" . $l_child;
		$new_r_path = $parent . "&" . $r_child;
	}

	else {

		$new_l_path = $l_child;
		$new_r_path = $r_child;
	}

	$best_feature_path{$new_l_path} = $new_l_path;
	$best_feature_path{$new_r_path} = $new_r_path;


	#foreach $key (keys %best_feature_path) {

	#	print $key, "\n";
	#}


	foreach $key (keys %instance_table) {

		$temp_path = "";
		$search_str = "";
		$temp_str = "";
		@temp_arr = ();
		

		$temp_str = $instance_table{$key};
		$search_str = " " . $b_feature . " ";
		@temp_arr = split /\s+/, $temp_str;

		if ($temp_str =~ /$search_str/) {
	
			$left_instance{$key} = $temp_str;
			$l_class_table{$temp_arr[1]} += 1;
			$l_cnt += 1;
			$left_flag = "yes";

			for (my $cnt=2; $cnt<=$#temp_arr; $cnt+=2)  {

				if ($temp_arr[$cnt] ne $b_feature) {

					$l_feature_table{$temp_arr[$cnt]} += 1;
					$l_feature_class{$temp_arr[1]}{$temp_arr[$cnt]} += 1;
				}
			}

			$best_feature_count{$depth}{$temp_arr[1]}{$new_l_path} += 1;
		}
	
		else {

			$right_instance{$key} = $temp_str;
			$r_class_table{$temp_arr[1]} += 1;
			$r_cnt += 1;
			$right_flag = "yes";

			for (my $cnt=2; $cnt<=$#temp_arr; $cnt+=2)  {

				if ($temp_arr[$cnt] ne $b_feature) {

					$r_feature_table{$temp_arr[$cnt]} += 1;			
					$r_feature_class{$temp_arr[1]}{$temp_arr[$cnt]} += 1;
				}
			}
			
			$best_feature_count{$depth}{$temp_arr[1]}{$new_r_path} += 1;
		}
	}

	$total_instance = $l_cnt + $r_cnt;
	return $depth;
}





sub output_result {

	foreach $key (keys %best_feature_path) {

		$t_path = "";
		$t_path = $key;

		$t_total = 0;

		foreach $key (keys %class_table) {

			$t_total = $t_total + $best_feature_count{$tree_depth}{$key}{$t_path}; 
		}

		if ($t_total ne 0) {

			print $t_path, " ", $t_total, " ";

			foreach $key (keys %class_table) {

				$t_class = $key;

				print $t_class, " ";

				printf ("%.1f", $best_feature_count{$tree_depth}{$key}{$t_path}/$t_total);
				print " ";
			}
				print "\n";
		}
	}

	#foreach $key (keys %class_table) {

	#	print $key;

	#}
}





sub output_model {

	foreach $key (keys %best_feature_path) {

		$t_path = "";
		$t_path = $key;

		$t_total = 0;

		foreach $key (keys %class_table) {

			$t_total = $t_total + $best_feature_count{$tree_depth}{$key}{$t_path}; 
		}

		if ($t_total ne 0) {

			print {$model_file} $t_path, " ", $t_total, " ";

			foreach $key (keys %class_table) {

				$t_class = $key;

				print {$model_file} $t_class, " ";

				printf {$model_file} ("%.1f", $best_feature_count{$tree_depth}{$key}{$t_path}/$t_total);
				print {$model_file} " ";
			}

			print {$model_file} "\n";
		}
	}
	
	close $model_file;
}





sub classify {

	open($model_f, $model) or die "cannot open model file for classification\n";

	%model_hash = ();
	$input_line = "";

	while(($input_line = <$model_f>)) {	## accept input from file

		$temp_str = "";
		$l_prob = 0;
		$l_class = "";
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
	open($acc_f, '>>', $acc) or die "cannot open accuracy file for output\n";

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

	print {$acc_f} "Confusion matrix for the training data:", "\n";
	print {$acc_f} "row is the truth, column is the system output", "\n";
	print {$acc_f} "\n";
	print {$acc_f} "\t", "\t", "talk.politics.guns talk.politics.misc talk.politics.mideast", "\n";
	print {$acc_f} "talk.politics.guns", "\t", $correct{$guns}, "\t\t", $w_gun{$misc}, "\t\t", $w_gun{$mid}, "\n"; 
	print {$acc_f} "talk.politics.misc", "\t", $w_misc{$guns}, "\t\t", $correct{$misc}, "\t\t", $w_misc{$mid}, "\n"; 
	print {$acc_f} "talk.politics.mideast", "\t", $w_mid{$guns}, "\t\t", $w_mid{$misc}, "\t\t", $correct{$mid}, "\n"; 
	print {$acc_f} "\n";
	print {$acc_f} " Training accuracy=", ($correct{$guns} + $correct{$misc} + $correct{$mid})/$t_total, "\n";
	print {$acc_f} "\n";
	print {$acc_f} "\n";

	print {$acc_f} "Confusion matrix for the test data:", "\n";
	print {$acc_f} "row is the truth, column is the system output", "\n";
	print {$acc_f} "\n";
	print {$acc_f} "\t", "\t", "talk.politics.guns talk.politics.misc talk.politics.mideast", "\n";
	print {$acc_f} "talk.politics.guns", "\t", $t_correct{$guns}, "\t\t", $wt_gun{$misc}, "\t\t", $wt_gun{$mid}, "\n"; 
	print {$acc_f} "talk.politics.misc", "\t", $wt_misc{$guns}, "\t\t", $t_correct{$misc}, "\t\t", $wt_misc{$mid}, "\n"; 
	print {$acc_f} "talk.politics.mideast", "\t", $wt_mid{$guns}, "\t\t", $wt_mid{$misc}, "\t\t", $t_correct{$mid}, "\n"; 
	print {$acc_f} "\n";
	print {$acc_f} " Test accuracy=", ($t_correct{$guns} + $t_correct{$misc} + $t_correct{$mid})/$tt_total, "\n";
	print {$acc_f} "\n";

}





































