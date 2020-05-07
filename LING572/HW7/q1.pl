#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





use File::Copy;

%train_table = ();
%test_table = ();
%class = ();

$class_index = 1;
$out_dir = $ARGV[2];


open($train, $ARGV[0]) or die "cannot open train file for input\n";
open($test, $ARGV[1]) or die "cannot open test file for input\n";


while ($train_f = <$train>) {

	$temp_str = "";
	$temp_str = $train_f;

	@temp_input = ();	
	@temp_input = split /\s+/, $temp_str;

	if (!(exists $class{$temp_input[1]})) {
 
		$class{$temp_input[1]} = $class_index;
		$class_index += 1;
	}

	$train_table{$temp_input[0]} = $train_f;
}
close $train;


while ($test_f = <$test>) {

	$temp_str = "";
	$temp_str = $test_f;

	@temp_input = ();	
	@temp_input = split /\s+/, $temp_str;

	$test_table{$temp_input[0]} = $test_f;
}
close $test;


class_binary ();


	


#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub class_binary {

	open($class_m, '>', "class_map");

	foreach $key (sort {$class{$a} <=> $class{$b}} keys %class) {

		open($train_out, '>', "train");
		open($test_out, '>', "test");

		$class_key = "";
		$class_key = $key;

		$dir_name = "";
		$dir_name = $class{$key} . "-vs-all";
		
		mkdir $dir_name;
		
		foreach $key (sort keys %train_table) {
			
			$temp_key = "";
			$temp_key = $train_table{$key};
			chomp($temp_key);
		
			@temp_input = ();	
			@temp_input = split /\s+/, $temp_key;

			if ($temp_input[1] =~ m/$class_key/) {

				$temp_key =~ s/ $temp_input[1] / 1 /;	
			}

			else {
				$temp_key =~ s/ $temp_input[1] / -1 /;
			}

			print {$train_out} $temp_key, "\n";
		}

		close $train_out;
		copy("train", $dir_name);
		 
		foreach $key (sort keys %test_table) {
			
			$temp_key = "";
			$temp_key = $test_table{$key};
			chomp($temp_key);
		
			@temp_input = ();	
			@temp_input = split /\s+/, $temp_key;

			if ($temp_input[1] =~ m/$class_key/) {

				$temp_key =~ s/ $temp_input[1] / 1 /;	
			}

			else {
				$temp_key =~ s/ $temp_input[1] / -1 /;
			}

			print {$test_out} $temp_key, "\n";
		}
		
		close $test_out; 
		copy("test", $dir_name);

		print {$class_m} $key, "\t", $class{$key}, "\n";
	}

	close $class_m; 	
}

