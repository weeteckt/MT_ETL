#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





$temp_class = "";
$default = "<default>";

%model_table = ();
%class = ();


open($test, $ARGV[0]) or die "cannot open test file for input\n";
open($model, $ARGV[1]) or die "cannot open model file for input\n";
open($sys_file, '>>', $ARGV[2]) or die "cannot open sys file for output\n";


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


print {$sys_file} "%%%%% test data:\n";


while($test_f = <$test>) {

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $test_f;

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

	print {$sys_file} $temp_input[0], " ", $temp_input[1], " ";

	foreach $key (sort {$class_sum{$b} <=> $class_sum{$a}} keys %class_sum)  {

		print {$sys_file} $key, " ", $class_sum{$key}/$z, " ";
	}

	print {$sys_file} "\n";
}


close $sys_file;
close $test;
close $model;


calc_acc_pipe();





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub calc_acc_pipe {

	open($sys_f, $ARGV[2]) or die "cannot open sys file for calculation\n";
	
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

		
			$test += 1 if ($t_str eq $misc);

			if ($a_str eq $t_str) {

				$correct{$a_str} += 1;
			}

			elsif (($a_str ne $t_str) && ($a_str =~ /$guns/ )) {


				if ($t_str =~ /mideast/) {

					$w_gun{$mid} += 1;
				}

				elsif ($t_str =~ /misc/) {

					$w_gun{$misc} += 1;
				}
			}

			elsif (($a_str ne $t_str) && ($a_str =~ /$mid/ )) {

				if ($t_str =~ /gun/) {

					$w_mid{$guns} += 1;
				}

				if ($t_str =~ /misc/) {

					$w_mid{$misc} += 1;
				}
			}
			
			elsif (($a_str ne $t_str) && ($a_str =~ /$misc/ )) {

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
	print "\t", "\t", "talk.politics.guns talk.politics.mideast talk.politics.misc", "\n";
	print "talk.politics.guns", "\t", $correct{$guns}, "\t\t", $w_gun{$mid}, "\t\t", $w_gun{$misc}, "\n"; 
	print "talk.politics.mideast", "\t", $w_mid{$guns}, "\t\t", $correct{$mid}, "\t\t", $w_mid{$misc}, "\n"; 
	print "talk.politics.misc", "\t", $w_misc{$guns}, "\t\t",$w_misc{$mid}, "\t\t", $correct{$misc}, "\n"; 
	print "\n";
	print " Test accuracy=", ($correct{$guns} + $correct{$misc} + $correct{$mid})/$t_total, "\n";
	print "\n";
	print "\n";
}

