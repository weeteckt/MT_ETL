#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





%rule_table = ();
%instance_table = ();
%feat_table = ();
%class_table = ();

open($train, $ARGV[0]) or die "cannot open training file for input\n";
open($model, '>', $ARGV[1]) or die "cannot open model file for output\n";

$min_gain = $ARGV[2];

$class_cnt = 0;


while ($train_f = <$train>) {

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $train_f;
	
	for (my $cnt=2; $cnt<=$#temp_input; $cnt+=2)  {

		$feat_table{$temp_input[$cnt]}{$temp_input[1]} += 1;
	}

	$instance_table{$temp_input[0]} = $train_f;
	
	if (!(exists $class_table{$temp_input[1]})) {

		$class_table{$temp_input[1]} = $class_cnt;
		$class_cnt += 1;
	}
}
close $train_f;


initialize();
find_best_rule();
print {$model} $best_rule, " ", $gain, "\n" if ((!($gain < 1)) && (!($gain < $min_gain)));


while ((!($gain < 1)) && (!($gain < $min_gain))) {

	transform();	
	find_best_rule();

	print {$model} $best_rule, " ", $gain, "\n" if ((!($gain < 1)) && (!($gain < $min_gain)));
}
close $model;





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub initialize {

	$initial_class = "";
	%working_table = ();

	foreach $key (keys %class_table) {

		if ($class_table{$key} eq 0) {

			$initial_class = $key;
		}
	}
	
	print {$model} $initial_class, "\n";
	
	foreach $key (keys %instance_table) {

		$working_table{$key} = $initial_class . " " . $instance_table{$key};
		$instance_table{$key} = $initial_class . " " . $instance_table{$key};
	}	
}





sub find_best_rule {

	%transform_table = ();

	foreach $key (keys %working_table) {

		@temp_instance = ();
		$temp_str = "";

		$correct_class = "";
		$current_class = "";

		$temp_str = $working_table{$key};
		chomp($temp_str); 

		@temp_instance = split /\s+/, $temp_str;
		
		$correct_class = $temp_instance[2];
		$current_class = $temp_instance[0];

		if ($correct_class ne $current_class) {

			for (my $cnt=3; $cnt<=$#temp_instance; $cnt+=2)  {

				$tran_key = "";
				$tran_key = $temp_instance[$cnt] . " " . $current_class . " " . $correct_class;
				$transform_table{$tran_key} += 1;
			}
		}
	}
	
	$gain = 0;
	$best_rule = "";

	foreach $key (keys %transform_table) {

		$correct = "";
		$current = "";
		$feat_check = 0;

		@temp_compare = ();
		@temp_compare = split /\s+/, $key;

		$current = $temp_compare[1];
		$correct = $temp_compare[2];

		$feat_check = $feat_table{$temp_compare[0]}{$current};
		$transform_table{$key} = $transform_table{$key} - $feat_check;

		if ($transform_table{$key} > $gain) {

			$gain = $transform_table{$key};
			$best_rule = $key;
		}
	}

	$rule_table{$best_rule} = $gain;
}	





sub transform {

	@temp_rule = ();
	@temp_rule = split /\s+/, $best_rule;

	$from_class = "";
	$to_class = "";
	$feature = "";

	$from_class = $temp_rule[1];
	$to_class = $temp_rule[2];
	$feature = $temp_rule[0];

	%working_table = ();

	foreach $key (keys %instance_table) {

		$found = "no";

		$temp_str = "";
		$temp_str = $instance_table{$key};

		@temp_instance = ();
		@temp_instance = split /\s+/, $temp_str; 

		$correct_key = "";
		$correct_key = $temp_instance[2];

		$current_key = "";
		$current_key = $temp_instance[0];

		if ($current_key ne $correct_key) {

			$current_str = "";
			$current_str = $temp_instance[1] . " " . $correct_key;

			$feat_str = "";

			for (my $cnt=3; $cnt<=$#temp_instance; $cnt+=2)  {

				$feat_str = $feat_str . " " . $temp_instance[$cnt] . " " . "1";

				if ($feature eq $temp_instance[$cnt]) {

					$found = "yes";
				}
			}

			$current_str = $current_str . $feat_str;

			if (($found eq "yes") && ($from_class eq $current_key)) {

				$instance_table{$key} = $to_class . " " . $current_str;
			}
		}
	}

	%working_table = %instance_table;
}



