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
%class_table = ();

$used = "";
$used_2 = "";

%dir_str = ();

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
		$class_table{$class_index} = $temp_input[1];
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


open($class_m, '>', "class_map");

foreach $key (sort keys %class) {

	$one = "";
	$one = $class{$key};
	
	foreach $key (sort keys %class) {

		$two = "";
		$two = $class{$key};

		if ($one ne $two) {
			
			$used = "";
			$used = $one . " " . $two;
			$used_2 = $two . " " . $one;

			if ((!(exists $dir_str{$used})) && (!(exists $dir_str{$used_2}))) {

				$dir_str{$used} = $two;
			}
		} 
	}

	print {$class_m} $key, "\t", $class{$key}, "\n";
}
close $class_m;


class_binary ();


	


#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub class_binary {

	foreach $key (keys %dir_str) {
				
		open($train_out, '>', "train");
		open($test_out, '>', "test");
		
		$t_class = "";
		$t_class = $key;

		@temp_class = ();
		@temp_class = split /\s+/, $t_class;

		$class_key = "";
		$class_key = $class_table{$temp_class[0]};

		$compare_key = "";
		$compare_key = $class_table{$temp_class[1]};

		$dir_name = "";
		$dir_name = $key;
		$dir_name =~ s/ /\-vs\-/;
		
		mkdir $dir_name;
		
		foreach $key (sort keys %train_table) {
			
			$temp_key = "";
			$temp_key = $train_table{$key};
			chomp($temp_key);
		
			@temp_input = ();	
			@temp_input = split /\s+/, $temp_key;

			if ($temp_input[1] =~ m/$class_key/) {

				$temp_key =~ s/ $temp_input[1] / 1 /;
				print {$train_out} $temp_key, "\n";	
			}

			elsif ($temp_input[1] =~ m/$compare_key/) {

				$temp_key =~ s/ $temp_input[1] / -1 /;
				print {$train_out} $temp_key, "\n";
			}
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
				print {$test_out} $temp_key, "\n";	
			}

			else {

				$temp_key =~ s/ $temp_input[1] / -1 /;
				print {$test_out} $temp_key, "\n";
			}			
		}
		
		close $test_out; 
		copy("test", $dir_name);
	} 	
}

