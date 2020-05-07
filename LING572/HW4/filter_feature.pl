#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





$p_thres = $ARGV[2];

%chi_table = ();
%input_instance = ();

if ($p_thres eq 0.1) {
	
	$cut_off = 4.605;
}

elsif ($p_thres eq 0.05) {

	$cut_off = 5.991;
}

elsif ($p_thres eq 0.025) {

	$cut_off = 7.378;
}

elsif ($p_thres eq 0.01) {

	$cut_off = 9.210;
}

elsif ($p_thres eq 0.001) {

	$cut_off = 13.816;
}

else {

	print "valid p values are 0.1, 0.05, 0.025, 0.01, 0.001";
}


open($input_file, $ARGV[0]) or die "cannot open instance input file for input\n";
open($chi_file, $ARGV[1]) or die "cannot open chi input file for input\n";


while($chi_line = <$chi_file>) {

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $chi_line;

	if ($temp_input[1] > $cut_off) {
	
		$chi_table{$temp_input[0]} = $temp_input[1];
	}
}


while($input_line = <$input_file>) {

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $input_line;
	
	print $temp_input[0], " ", $temp_input[1], " ";

	for (my $cnt=2; $cnt<$#temp_input; $cnt+=2)  {

		if (exists $chi_table{$temp_input[$cnt]}) {

			print $temp_input[$cnt], " ", $temp_input[$cnt+1], " ";
		}
	}

	print "\n";
}

close $chi_file;
close $input_file;





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------
