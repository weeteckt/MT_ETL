#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





%data_table = ();
%model_table = ();
%master_instance = ();
%class = ();
%feature = ();

$instance_cnt = 0;
$class_cnt = 0;


open($train, $ARGV[0]) or die "cannot open train file for input\n";
open($m_exp, '>>', $ARGV[1]) or die "cannot open model expectation file for output\n";
open($model, $ARGV[2]) or $success = 1;



while($train_f = <$train>) {

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $train_f;
		
	$class{$temp_input[1]} = 1;
	$instance_cnt += 1;
	$master_instance{$temp_input[0]} = $train_f;

	for (my $cnt=2; $cnt<$#temp_input; $cnt+=2)  {

		$data_table{$temp_input[1]}{$temp_input[$cnt]} = 0;
		$feature{$temp_input[$cnt]} += 1;
	}
}


calc_acc_pipe();

close $train;
close $m_exp;





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub calc_acc_pipe {

	if ($success ne 1) {

		while ($model_f = <$model>) {

			$temp_str = "";
			@temp_input = ();	
			@temp_input = split /\s+/, $model_f;
	
			if ($#temp_input > 2) {

				$temp_class = $temp_input[3];
				$class{$temp_class} = 1;
			}

			if ((!($#temp_input > 2)) && ($temp_input[1] ne "")) {

				$model_table{$temp_class}{$temp_input[1]} = $temp_input[2];
			}
		}
	}

	else {

		foreach $key (keys %class) {
	
			$class_cnt += 1;
		}

		foreach $key (sort keys %class) {

			$class_key = "";
			$class_key = $key;

			foreach $key (sort keys %feature) {

				$model_table{$class_key}{$key} = 1/$class_cnt;
			}
		}
	}	

	foreach $key (sort keys %master_instance) {

		$temp_str = "";
		@temp_input = ();	
		@temp_input = split /\s+/, $master_instance{$key};

		%class_sum = ();

		$z = 0;

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

		foreach $key (keys %class) {

			for (my $cnt=2; $cnt<$#temp_input; $cnt+=2)  {

				$data_table{$key}{$temp_input[$cnt]} += (1/$instance_cnt) * ($class_sum{$key}/$z);
			}
		}
	}

	foreach $key (sort keys %class) {

		$class_key = "";
		$class_key = $key;

		foreach $key (sort keys %feature) {

			print {$m_exp } $class_key, " ", $key, " ", $data_table{$class_key}{$key}, "\n";
		}
	} 
}

	

