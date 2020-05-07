#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





$feat_num = 0;
$class_num = 0;
$temp_class = "";
$default = "<default>";

%model_table = ();
%feat_table = ();
%class = ();
@sentence_array = ();
@class_tab = ();

$beam_size = $ARGV[4];
$topN = $ARGV[5];
$topK = $ARGV[6];

open($test, $ARGV[0]) or die "cannot open test file for input\n";
open($bound, $ARGV[1]) or die "cannot open boundary file for input\n";
open($model, $ARGV[2]) or die "cannot open model file for input\n";

open($sys_file, '>>', $ARGV[3]) or die "cannot open sys file for output\n";


while ($model_f = <$model>) {

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $model_f;
	
	if ($#temp_input > 2) {

		$temp_class = $temp_input[3];
		$class{$temp_class} = 1;
		$class_tab[$class_num] = $temp_class;
		$class_num += 1;
	}

	if ((!($#temp_input > 2)) && ($temp_input[1] ne "")) {

		$feat_table{$temp_input[1]} = 1; 
		$model_table{$temp_class}{$temp_input[1]} = $temp_input[2];
	}

	#print $temp_class, "\t", $temp_input[1], "\t", $temp_input[2], "\n";
}
close $model;


print {$sys_file} "\n";
print {$sys_file} "\n";
print {$sys_file} "%%%%% test data:\n";


$b_cnt = 0;
while ($bound_f = <$bound>) {

	$sentence_array[$b_cnt] = $bound_f;
	$b_cnt += 1;
}
close $bound;


process_input();

close $sys_file;

foreach $key (keys %feat_table) {

	$feat_num += 1;
}

calc_acc();





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub process_input {

	$sentence_cnt = 0;
	$current_sentence = 1;
	@test_table = (); 

	$curr1_tag = "";
	$curr2_tag = "";
	$curr_tag = "";
	$pre_tag = "";
	$pre_twotag = "";

 	while ($test_f = <$test>) {

		if ($current_sentence <= $sentence_array[$sentence_cnt]) {

			$temp_str = "";
			$temp_str = $test_f;
			chomp($temp_str); 

			@temp_input = ();	
			@temp_input = split /\s+/, $temp_str;

			$curr_tag = $temp_input[1];
		
			if ($current_sentence eq 1) {

				$pre_tag = "prevT=BOS";
				$pre_twotag = "prevTwoTags=BOS+BOS";
			
				$test_table[$current_sentence] = $temp_str . " " . $pre_tag . " 1" . " " . $pre_twotag . " 1";
			}

			else {
				$test_table[$current_sentence] = $temp_str;
			}
		}

		$current_sentence += 1;
	
		if ($current_sentence > $sentence_array[$sentence_cnt]) {

			beam_search();
			output_sys();

			$sentence_cnt += 1;
			$current_sentence = 1;
			@test_table = (); 

			$curr1_tag = "";
			$curr2_tag = "";
			$curr_tag = "";
			$pre_tag = "";
			$pre_twotag = "";
		}
	}

	close $test;
}





sub beam_search {

	########## Find the Initial TopN ##########

	%class_sum = ();
	@top_tag = ();
	@topN_node = ();
	@top_prob = ();
	%survive_node = ();
	
	$t_cnt = 1;
	$s_cnt = 1;

	$z = 0;

	$temp_str = "";
	$temp_str = $test_table[1];

	@temp_input = ();	
	@temp_input = split /\s+/, $temp_str;
	
	foreach $key (keys %class) {

		$class_key = "";
		$class_key = $key;
		
		$sum = 0;
		$sum = $model_table{$class_key}{$default}; 

		for (my $cnt=2; $cnt<$#temp_input; $cnt+=2)  {

			$sum += $model_table{$class_key}{$temp_input[$cnt]};
		}

		$class_sum{$class_key} = (2.718281828)**$sum;
		$z += $class_sum{$class_key};
	}

	foreach $key (sort {$class_sum{$b} <=> $class_sum{$a}} keys %class_sum) {

		$class_sum{$key} = $class_sum{$key}/$z;
		
		if ($s_cnt <= $topN) {

			$topN_node[$s_cnt] = $key . " " . $class_sum{$key};
			$top_prob[$s_cnt] = $class_sum{$key};
			$survive_node{$key} = $class_sum{$key};
			$s_cnt += 1;
		}
	}

	$top_tag[$t_cnt] = $top_prob[1];
	$t_cnt += 1;

	
	########## Find the subsequent TopN ##########

	for (my $a_cnt=2; $a_cnt<=$#test_table; $a_cnt++)  {
		
		@topK_node = ();
		@top_prob = ();
		%new_table = ();

		$best_p = 0;
		
		%t_survive_node = ();
		
		%t_survive_node = %survive_node;
		%survive_node = ();

		$sk_cnt = 1;

		$max_prob = 0;

		foreach $key (keys %t_survive_node) {
	
			$pre_tag = "";
			$pre_twotag = "";

			$node_key = "";
			$node_key = $key;

			@topN_node = ();
			$sn_cnt = 1;

			$z = 0;
			%class_sum = ();

			@s_temp = ();
			@s_temp = split /\s+/, $key;

			if ($a_cnt eq 2) {

				$curr2_tag = "BOS";
			}

			else {

				$curr2_tag = $s_temp[$#s_temp-1];
			}

			$curr1_tag = $s_temp[$#s_temp];
			
			$pre_tag = "prevT=" . $curr1_tag;
			$pre_twotag = "prevTwoTags=" . $curr2_tag . "+" . $curr1_tag;

			$temp_str = "";
			$temp_str = $test_table[$a_cnt] . " " . $pre_tag . " 1" . " " . $pre_twotag . " 1";

			@temp_input = ();	
			@temp_input = split /\s+/, $temp_str;

			foreach $key (keys %class) {

				$class_key = "";
				$class_key = $key;
		
				$sum = 0;
				$sum = $model_table{$class_key}{$default}; 

				for (my $cnt=2; $cnt<$#temp_input; $cnt+=2)  {

					$sum += $model_table{$class_key}{$temp_input[$cnt]};
				}

				$class_sum{$class_key} = (2.718281828)**$sum;
				$z += $class_sum{$class_key};
			}

			foreach $key (sort {$class_sum{$b} <=> $class_sum{$a}} keys %class_sum) {

				$class_sum{$key} = $class_sum{$key}/$z;

				if ($sn_cnt <= $topN) {

					$topN_node[$sn_cnt] = $key . " " . $class_sum{$key};
					$sn_cnt += 1;
				}
			}

			for (my $b_cnt=1; $b_cnt<=$#topN_node; $b_cnt++) {

				@n_input = ();	
				@n_input = split /\s+/, $topN_node[$b_cnt];

				$new_node = "";
				$new_node = $node_key . " " . $n_input[0];

				$new_table{$new_node} = $t_survive_node{$node_key} * $n_input[1];

				
				if ($new_table{$new_node} > $max_prob) {

					$max_prob = $new_table{$new_node};
					$best_p = $n_input[1];
				}
			}
		}
		
		$top_tag[$t_cnt] = $best_p;
		$t_cnt += 1;

		foreach $key (sort {$new_table{$b} <=> $new_table{$a}} keys %new_table) {
		
			if (($sk_cnt <= $topK) && ((log($new_table{$key})/log(10)) + $beam_size) >= (log($max_prob)/log(10))) {

				$survive_node{$key} = $new_table{$key};
			}
			
			$sk_cnt += 1;	
		}
	}
}





sub output_sys {

	$max_prob = 0;
	$best_seq = "";
	@best_temp = ();

	foreach $key (keys %survive_node) {

		if ($survive_node{$key} > $max_prob) {

			$max_prob = $survive_node{$key};
			$best_seq = $key;
		}
	}

	@best_temp = split /\s+/, $best_seq;

	for (my $cnt=1; $cnt<=$#test_table; $cnt++)  {
		
		$b_str = "";
		$b_str = $test_table[$cnt];

		@b_input = ();	
		@b_input = split /\s+/, $b_str;

		print {$sys_file} $b_input[0], " ", $b_input[1], " ", $best_temp[$cnt-1], " ", $top_tag[$cnt], "\n";	
	}
}





sub calc_acc {

	open($sys_f, $ARGV[3]) or die "cannot open sys file for calculation\n";
	
	%output = ();

	$t_total = 0;
	$correct_cnt = 0;

	while(chomp($input_line = <$sys_f>)) {	## accept input from file

		if ((!($input_line =~ /%%%%% test data/)) && ($input_line ne "")) {

			$t_str = "";
			$s_str = "";
		
			$t_total += 1;

			@temp_input = ();	
			@temp_input = split /\s+/, $input_line;

			$t_str = $temp_input[1];
			$s_str = $temp_input[2];

			if ($t_str eq $s_str) {

				$correct_cnt += 1;
			}
			
			$output{$t_str}{$s_str} += 1;
		}
	}

	print "class_num=", $class_num, " ", "feat_num=", $feat_num-1, "\n";
	print "\n";
	print "\n";
	print "Confusion matrix for the test data:", "\n";
	print "row is the truth, column is the system output", "\n";
	print "\n";
	print "\t", "\t";

	for (my $cnt=0; $cnt<=$#class_tab; $cnt++)  {

		print $class_tab[$cnt], " ";
	}
	
	print "\n";
	
	for (my $cnt=0; $cnt<=$#class_tab; $cnt++)  {

		$t_out = $class_tab[$cnt];
		
		print $class_tab[$cnt], " ";

		for (my $o_cnt=0; $o_cnt<=$#class_tab; $o_cnt++)  {

			$s_out = $class_tab[$o_cnt];

			if ($output{$t_out}{$s_out} > 0) {

				print $output{$t_out}{$s_out}, " ";
			}

			else {

				print "0", " ";
			}
		}

		print "\n";
	}
	
	print "\n";
	print " Test accuracy=", $correct_cnt/$t_total, "\n";
	print "\n";
	print "\n";
}

