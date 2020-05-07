#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





@rule_table = ();
%class = ();
%instance_table = ();
%initial_class = ();


open($input, $ARGV[0]) or die "cannot open training/test file for input\n";
open($model, $ARGV[1]) or die "cannot open model file for input\n";
open($sys, '>', $ARGV[2]) or die "cannot open sys file for output\n";


$N = $ARGV[3];
$N_cnt = 1;
$i_class = "";


while (($model_f = <$model>) && ($N_cnt <= $N)) {

	$temp_str = "";
	$temp_str = $model_f;
	chomp($temp_str);

	@temp_input = ();	
	@temp_input = split /\s+/, $temp_str;
	
	if ($#temp_input eq 0) {

		$i_class = $temp_str;
	}

	else {

		$rule_table[$N_cnt] = $temp_str;
		$N_cnt += 1;
	}
}
close $model_f;


while ($input_f = <$input>) {

	$temp_str = "";
	$temp_str = $input_f;
	chomp($temp_str);

	$new_str = "";

	@temp_input = ();	
	@temp_input = split /\s+/, $temp_str;

	$class{$temp_input[1]} = 0;

	for (my $cnt=2; $cnt<=$#temp_input; $cnt++)  {

		$new_str = $new_str . $temp_input[$cnt] . " ";
	}

	$instance_table{$temp_input[0]} = $i_class . " " . $temp_str;
	$initial_class{$temp_input[0]} = $new_str;
}		
close $input_f;	


classify();
calc_acc();





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub classify {

	%acc_table = ();

	foreach $key (sort keys %instance_table) {

		$found = "no";

		$temp_str = "";
		$temp_str = $instance_table{$key}; 

		@temp_instance = ();
		@temp_instance = split /\s+/, $temp_str; 

		$current_key = "";
		$current_key = $temp_instance[0];

		$start_key = "";
		$start_key = $temp_instance[2];

		$true_key = "";
		$true_key = $temp_instance[2];

		$history = "";
		
		for (my $cnt=0; $cnt<=$#rule_table; $cnt++)  {

			@temp_rule = ();
			@temp_rule = split /\s+/, $rule_table[$cnt];

			$from_class = "";
			$to_class = "";
			$feature = "";

			$from_class = $temp_rule[1];
			$to_class = $temp_rule[2];
			$feature = $temp_rule[0];

			for (my $cnt=3; $cnt<=$#temp_instance; $cnt+=2)  {

				if ($feature eq $temp_instance[$cnt]) {

					$found = "yes";
				}
			}

			if (($current_key eq $from_class) && ($found eq "yes")) {
				
					$history = $history . $feature . " " . $from_class . " " . $to_class . " ";
					$current_key = $to_class;
			}
		}

		$acc_table{$key} = $key . " " . $true_key . " " . $current_key . " " . $history;
		print {$sys} $key, " ", $true_key, " ", $current_key, " ", $history, "\n";
	}

	close $sys;
}





sub calc_acc {
	
	$t_total = 0;
	$correct_cnt = 0;
	
	%output = ();

	foreach $key (keys %acc_table) {

		$t_str = "";
		$s_str = "";
		
		$t_total += 1;

		@temp_input = ();	
		@temp_input = split /\s+/, $acc_table{$key};

		$t_str = $temp_input[1];
		$s_str = $temp_input[2];

		if ($t_str eq $s_str) {

			$correct_cnt += 1;
		}
			
		$output{$t_str}{$s_str} += 1;
	}

	print "\n";
	print "\n";
	print "Confusion matrix for the ", $ARGV[0], " data:", "\n";
	print "row is the truth, column is the system output", "\n";
	print "\n";
	print "\t";

	foreach $key (sort keys %class) {

		print $key, "\t\t", 
	}

	print "\n";

	foreach $key (sort keys %class) {
		
		$truth_key = $key;
		print $truth_key, "\t";

		foreach $key (sort keys %class) {

			if ($output{$truth_key}{$key} > 0) {

				print $output{$truth_key}{$key}, "\t\t  ";
			}

			else {

				print "0", "\t\t  ";
			}
		}
		
		print "\n";
	}

	print "\n";
	print $ARGV[0], " accuracy=", $correct_cnt/$t_total, "\n";
	print "\n";
	print "\n";
}
