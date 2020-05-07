#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





$first_blank = 0;
$input_line = "";
$input_file = "";
%word_table = ();

open($input_file, $ARGV[0]) or die "cannot open $ARGV[0] - file not found\n";

accept_input();
output_vector();





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub accept_input {

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
		
			#print $line_input, "\n";
		}
	}
}





sub output_vector {

	print $ARGV[0], " ", $ARGV[1], " ";

	foreach $key (sort keys %word_table) {

		if ($key ne "") {

			print $key, " ", $word_table{$key}, " ";

		}

	}
	
	print "\n";
}

