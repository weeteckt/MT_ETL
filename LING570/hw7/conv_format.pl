#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





use POSIX qw(log10);

$input_data = "";
$i_c = 0;
$j_c = 0;
$k_c = 0;
$n = 0;
$from_cnt = 0;
$to_cnt = 0;
$state_id = 0;
$state_count = 0;



while($input_data = <STDIN>) {	## accept input from file

	process_input();
	create_output();
}





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub process_input {

	$c = 0;

	@data_table = ();
	@word_table = ();
	@tag_table = ();
	@tag = ();

	@data_table = split /\=\>/, $input_data;
	@word_table = split /\s+/, $data_table[0];
	@tag_table = split /\s+/, $data_table[1];

	for ($t=0; $t<=$#tag_table; $t++) {
	
		if (($tag_table[$t] =~ /\_/) && (!($tag_table[$t] =~ /BOS_BOS/))) {

			$tag_table[$t] =~ s/\_/ /;
			@temp = split /\s+/, $tag_table[$t];
 
			$tag[$c] = $temp[1];
			$c += 1;
		}
	}
}


sub create_output() {

	for ($t=0; $t<=$#tag; $t++) {

		print $word_table[$t], "/", $tag[$t], " ";
 	}
	
	print "\n";
}

