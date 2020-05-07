#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





use File::Copy;

%class_table = ();
%class_table_train = ();
%test_instance = ();
%train_instance = ();
%class = ();
%class_id = ();

$class_ind = "";

open($class_m, "class_map") or die "cannot open class map file for input\n";
while ($class_ind = <$class_m>) {

	$temp_str = "";
	$temp_str = $class_ind;

	@temp_input = ();	
	@temp_input = split /\s+/, $temp_str;
 
	$class{$temp_input[1]} = $temp_input[0];
	$class_id{$temp_input[0]} = $temp_input[1];
}
close $class_m;


open($test, $ARGV[1]) or die "cannot open test file for input\n";
while ($test_f = <$test>) {

	$temp_str = "";
	$temp_str = $test_f;

	@temp_input = ();	
	@temp_input = split /\s+/, $temp_str;

	$test_instance{$temp_input[0]} = $temp_input[1];
}
close $test;


open($train, $ARGV[0]) or die "cannot open train file for input\n";
while ($train_f = <$train>) {

	$temp_str = "";
	$temp_str = $train_f;

	@temp_input = ();	
	@temp_input = split /\s+/, $temp_str;

	$train_instance{$temp_input[0]} = $temp_input[1];
}
close $train;


@train_list = ();
@train_list = glob("train_temp*");

for (my $cnt=0; $cnt<=$#train_list; $cnt++)  {

	$sys_input = "";
	$compare_key = "";	
	$compare_key = $train_list[$cnt];
	$compare_key =~ s/train_temp//;
	$compare_key =~ s/v/\:/;

	$train_file = "";
	$train_file = $train_list[$cnt];

	open($train_sys, $train_file);

	while ($train_sys_input = <$train_sys>) {

		if (($train_sys_input =~ m/ 1:/) && ($train_sys_input =~ m/ -1:/)) {

			$t_str = "";
			$t_str = $train_sys_input;
			chomp($t_str);

			@t_input = ();	
			@t_input = split /\s+/, $t_str;

			if ($t_input[2] =~ m/-1:/) {

				$class_table_train{$t_input[0]} = $class_table_train{$t_input[0]} . " " . $compare_key . " " .$t_input[3];
			}

			elsif ($t_input[3] =~ m/-1:/) {

				$class_table_train{$t_input[0]} = $class_table_train{$t_input[0]} . " " . $compare_key . " " .$t_input[2];
			}
		}
	}

	close $train_sys;
}

output_train_sys();
calc_train_acc();


@test_list = ();
@test_list = glob("test_temp*");

for (my $cnt=0; $cnt<=$#test_list; $cnt++)  {

	$sys_input = "";
	$compare_key = "";	
	$compare_key = $test_list[$cnt];
	$compare_key =~ s/test_temp//;
	$compare_key =~ s/v/\:/;

	$sys_file = "";
	$sys_file = $test_list[$cnt];

	open($t_sys, $sys_file);

	while ($sys_input = <$t_sys>) {

		if (($sys_input =~ m/ 1:/) && ($sys_input =~ m/ -1:/)) {

			$t_str = "";
			$t_str = $sys_input;
			chomp($t_str);

			@t_input = ();	
			@t_input = split /\s+/, $t_str;

			if ($t_input[2] =~ m/-1:/) {

				$class_table{$t_input[0]} = $class_table{$t_input[0]} . " " . $compare_key . " " .$t_input[3];
			}

			elsif ($t_input[3] =~ m/-1:/) {

				$class_table{$t_input[0]} = $class_table{$t_input[0]} . " " . $compare_key . " " .$t_input[2];
			}
		}
	}

	close $t_sys;
}

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
	
		$true_class = "";

		$temp_str = "";
		$temp_str = $class_table_train{$key};

		@temp_input = ();	
		@temp_input = split /\s+/, $temp_str;

		foreach $key (sort keys %class) {

			$c_k = "";
			$c_k = "c" . $key;
 
			$class_cnt{$c_k} = 0;
		}

		print {$sys} $key, " ", $train_instance{$key}, " ";

		$true_class = $class_id{$train_instance{$key}};

		for (my $cnt=1; $cnt<=$#temp_input; $cnt+=2)  {

			$c_key = "";
			$c_key = $temp_input[$cnt];
			$c_key =~ s/:/ /;

			@compare = ();
			@compare = split /\s+/, $c_key;

			$c_key = "";

			$temp_input[$cnt+1] =~ s/1://;

			if ($temp_input[$cnt+1] > 0.5) {

				$c_key = "c" . $compare[0];
				$class_cnt{$c_key} += 1;
			}

			else {
				$c_key = "c" . $compare[1];
				$class_cnt{$c_key} += 1;
			}	

			$p_sort{$temp_input[$cnt]} = $temp_input[$cnt+1];	
		}
 
		foreach $key (sort {$p_sort{$b} <=> $p_sort{$a}} keys %p_sort) {

			print {$sys} $key, " ", $p_sort{$key}, " ";
		}

		foreach $key (sort {$class_cnt{$b} <=> $class_cnt{$a}} keys %class_cnt) {

			print {$sys} $key, "=", $class_cnt{$key}, " ";
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

			$temp_str = "";
			@temp_class = ();
		
			$t_total += 1;

			@temp_input = ();	
			@temp_input = split /\s+/, $input_line;

			$temp_str = $temp_input[8];
			$temp_str =~ s/=/ /;

			@temp_class = split /\s+/, $temp_str;

			$t_str = $temp_input[1];
	
			$temp_str = $temp_class[0];
			$temp_str =~ s/c//;

			$s_str = $class{$temp_str};

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

	foreach $key (sort keys %class_table) {

		%p_sort = ();
	
		$true_class = "";

		$temp_str = "";
		$temp_str = $class_table{$key};

		@temp_input = ();	
		@temp_input = split /\s+/, $temp_str;

		foreach $key (sort keys %class) {

			$c_k = "";
			$c_k = "c" . $key;
 
			$class_cnt{$c_k} = 0;
		}

		print {$sys} $key, " ", $test_instance{$key}, " ";

		$true_class = $class_id{$test_instance{$key}};

		for (my $cnt=1; $cnt<=$#temp_input; $cnt+=2)  {

			$c_key = "";
			$c_key = $temp_input[$cnt];
			$c_key =~ s/:/ /;

			@compare = ();
			@compare = split /\s+/, $c_key;

			$c_key = "";

			$temp_input[$cnt+1] =~ s/1://;

			if ($temp_input[$cnt+1] > 0.5) {

				$c_key = "c" . $compare[0];
				$class_cnt{$c_key} += 1;
			}

			else {
				$c_key = "c" . $compare[1];
				$class_cnt{$c_key} += 1;
			}	

			$p_sort{$temp_input[$cnt]} = $temp_input[$cnt+1];	
		}
 
		foreach $key (sort {$p_sort{$b} <=> $p_sort{$a}} keys %p_sort) {

			print {$sys} $key, " ", $p_sort{$key}, " ";
		}

		foreach $key (sort {$class_cnt{$b} <=> $class_cnt{$a}} keys %class_cnt) {

			print {$sys} $key, "=", $class_cnt{$key}, " ";
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

			$temp_str = "";
			@temp_class = ();
		
			$t_total += 1;

			@temp_input = ();	
			@temp_input = split /\s+/, $input_line;

			$temp_str = $temp_input[8];
			$temp_str =~ s/=/ /;

			@temp_class = split /\s+/, $temp_str;

			$t_str = $temp_input[1];
	
			$temp_str = $temp_class[0];
			$temp_str =~ s/c//;

			$s_str = $class{$temp_str};

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




