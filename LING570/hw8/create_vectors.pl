#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





$input_file = ""; 



open (my $train_v, '>>', $ARGV[0]) or die "please provide train vector filename\n";
open (my $test_v, '>>', $ARGV[1]) or die "please provide test vector filename\n";

$v_ratio = $ARGV[2];
 
#print {$train_v} "train vector\n";
#print {$test_v} "test vector\n";

for ($cnt=3; $cnt<= $#ARGV; $cnt++) {

	$total_line = 0;
	$output_cnt = 0;

	$env_path = "\~\/dropbox\/09-10\/570\/hw8\/20_newsgroups\/";
	$dir_path = $env_path . $ARGV[$cnt];
	

	@dir_list = ();
	@dir_list = glob("$dir_path/*");

	$total_line = $#dir_list + 1;
	
	$train_ratio = $v_ratio * $total_line;
	$train_ratio =~ s/\.[0-9]+//;
	$test_ratio = $total_line - $train_ratio;

	foreach $dir_list(@dir_list) {
		
		$file_t = $dir_list;
		$file_t =~ s/\// /g;
		
		%word_table = ();
		$line_input = "";
		$input_file = "";
		$first_blank = 0;
		
		@temp_f = ();
		@temp_f = split /\s+/, $file_t;

		open($input_file, "$dir_list") or die "cannot open file for input\n";
		process_input();
		output_vector();
		close $input_file;
	}
}

close $train_v;
close $test_v;

	



#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub process_input {


	while(chomp($line_input = <$input_file>)) {	## accept input from file

		@text_table = ();

		if ($line_input eq "") {
	
			$first_blank += 1;
		}

		if ($first_blank > 0) {


			$line_input =~ s/[^a-zA-Z]+/ /g;

			$_ = $line_input;
			s/($_)/\L$1/ig;			
			$line_input = $_;	
			

			@text_table = split /\s/, $line_input;
		
			foreach $text_table(@text_table) {

				if ((exists ($word_table{$text_table})) && ($word_table{$text_table} ne "")) {

					$word_table{$text_table} += 1;
				}

				else {

					$word_table{$text_table} = 1;
				}

			}
		
		}
	}
}





sub output_vector {

	$output_v = "";
	$output_cnt += 1;

	if ($output_cnt <= $train_ratio) { 
	
		$output_v = $train_v;
	}

	else {

		$output_v = $test_v;
	}


	print {$output_v} $temp_f[$#temp_f], " ", $temp_f[$#temp_f-1], " ";

	foreach $key (sort keys %word_table) {

		if ($key ne "") {

			print {$output_v} $key, " ", $word_table{$key}, " ";
		}
	}

	print {$output_v} "\n";
}


