#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





use File::Copy;

%class_table_train = ();
%class_table_test = ();
%train_instance = ();
%test_instance = ();
%class = ();

$class_ind = "";

open($class_m, "class_map") or die "cannot open class map file for input\n";

while ($class_ind = <$class_m>) {

	$temp_str = "";
	$temp_str = $class_ind;

	@temp_input = ();	
	@temp_input = split /\s+/, $temp_str;
 
	$class{$temp_input[1]} = $temp_input[0];
}

foreach $key (sort keys %class) {

	$train_input = "";
	$train_file = "";

	$train_file = "train_temp" . $key;

	open($train_sys, $train_file);

	while ($sys_train = <$train_sys>) {

		if (($sys_train =~ m/ 1:/) && ($sys_train =~ m/ -1:/)) {

			$t_str = "";
			$t_str = $sys_train;
			chomp($t_str);

			@t_input = ();	
			@t_input = split /\s+/, $t_str;

			if ($t_input[1] eq 1) {

				$train_instance{$t_input[0]} = $class{$key};
			}

			if ($t_input[2] =~ m/-1:/) {

				$class_table_train{$t_input[0]} = $class_table_train{$t_input[0]} . " " . $class{$key} . " " .$t_input[3];
			}

			elsif ($t_input[3] =~ m/-1:/) {

				$class_table_train{$t_input[0]} = $class_table_train{$t_input[0]} . " " . $class{$key} . " " .$t_input[2];
			}
		}
	}

	$test_input = "";
	$test_file = "";

	$test_file = "test_temp" . $key;

	open($test_sys, $test_file);

	while ($sys_test = <$test_sys>) {

		if (($sys_test =~ m/ 1:/) && ($sys_test =~ m/ -1:/)) {

			$t_str = "";
			$t_str = $sys_test;
			chomp($t_str);

			@t_input = ();	
			@t_input = split /\s+/, $t_str;

			if ($t_input[1] eq 1) {

				$test_instance{$t_input[0]} = $class{$key};
			}

			if ($t_input[2] =~ m/-1:/) {

				$class_table_test{$t_input[0]} = $class_table_test{$t_input[0]} . " " . $class{$key} . " " .$t_input[3];
			}

			elsif ($t_input[3] =~ m/-1:/) {

				$class_table_test{$t_input[0]} = $class_table_test{$t_input[0]} . " " . $class{$key} . " " .$t_input[2];
			}
		}
	}
}


close $class_m;
close $train_sys;
close $test_sys;


output_train_sys();
calc_train_acc();


output_test_sys();
calc_test_acc();
	




#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub output_train_sys {
	
	open($sys, '>', "train_sys");

	foreach $key (sort keys %class_table_train) {

		%p_sort = ();

		$temp_str = "";
		$temp_str = $class_table_train{$key};

		@temp_input = ();	
		@temp_input = split /\s+/, $temp_str;

		print {$sys} $key, " ", $train_instance{$key}, " ";

		for (my $cnt=1; $cnt<=$#temp_input; $cnt+=2)  {

			$temp_input[$cnt+1] =~ s/1://;
			$p_sort{$temp_input[$cnt]} = $temp_input[$cnt+1];
		}
 
		foreach $key (sort {$p_sort{$b} <=> $p_sort{$a}} keys %p_sort) {

			print {$sys} $key, " ", $p_sort{$key}, " ";
		}

		print {$sys} "\n";
	}

	close $sys; 	
}





sub calc_train_acc {

	open($sys_f, "train_sys") or die "cannot open sys file for calculation\n";
	
	%output = ();

	$t_total = 0;
	$correct_cnt = 0;

	while(chomp($input_line = <$sys_f>)) {	## accept input from file

		if ($input_line ne "") {

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

	print "\n";
	print "\n";
	print "Confusion matrix for the train data:", "\n";
	print "row is the truth, column is the system output", "\n";
	print "\n";
	print "\t", "\t";

	foreach $key (sort keys %class) {

		print $class{$key}, " ", 
	}

	print "\n";

	foreach $key (sort keys %class) {

		$class_key = $class{$key};
		
		print $class_key, "\t";

		foreach $key (sort keys %class) {

			if ($output{$class_key}{$class{$key}} > 0) {

				print $output{$class_key}{$class{$key}}, "\t\t  ";
			}

			else {

				print "0", "\t\t  ";
			}
		}
		
		print "\n";
	}

	print "\n";
	print " Train accuracy=", $correct_cnt/$t_total, "\n";
	print "\n";
	print "\n";

	close $sys; 
}





sub output_test_sys {
	
	open($sys, '>', "final_sys_output");

	foreach $key (sort keys %class_table_test) {

		%p_sort = ();

		$temp_str = "";
		$temp_str = $class_table_test{$key};

		@temp_input = ();	
		@temp_input = split /\s+/, $temp_str;

		print {$sys} $key, " ", $test_instance{$key}, " ";

		for (my $cnt=1; $cnt<=$#temp_input; $cnt+=2)  {

			$temp_input[$cnt+1] =~ s/1://;
			$p_sort{$temp_input[$cnt]} = $temp_input[$cnt+1];
		}
 
		foreach $key (sort {$p_sort{$b} <=> $p_sort{$a}} keys %p_sort) {

			print {$sys} $key, " ", $p_sort{$key}, " ";
		}

		print {$sys} "\n";
	}

	close $sys; 	
}





sub calc_test_acc {

	open($sys_f, "final_sys_output") or die "cannot open sys file for calculation\n";
	
	%output = ();

	$t_total = 0;
	$correct_cnt = 0;

	while(chomp($input_line = <$sys_f>)) {	## accept input from file

		if ($input_line ne "") {

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

	print "\n";
	print "\n";
	print "Confusion matrix for the test data:", "\n";
	print "row is the truth, column is the system output", "\n";
	print "\n";
	print "\t", "\t";

	foreach $key (sort keys %class) {

		print $class{$key}, " ", 
	}

	print "\n";

	foreach $key (sort keys %class) {

		$class_key = $class{$key};
		
		print $class_key, "\t";

		foreach $key (sort keys %class) {

			if ($output{$class_key}{$class{$key}} > 0) {

				print $output{$class_key}{$class{$key}}, "\t\t  ";
			}

			else {

				print "0", "\t\t  ";
			}
		}
		
		print "\n";
	}

	print "\n";
	print " Test accuracy=", $correct_cnt/$t_total, "\n";
	print "\n";
	print "\n";

	close $sys; 
}




