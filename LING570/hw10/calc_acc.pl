#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------




$mapping_type = "";

$map_flag = $ARGV[2];

open($gold_cluster, $ARGV[0]) or die "cannot open gold cluster file for input\n";
open($sys_cluster, $ARGV[1]) or die "cannot open sys cluster file for input\n";

input_data();
populate_map();

if ($map_flag eq 0) {
	
	$mapping_type = "One-to-One Mapping";
	do_one_map();
}

elsif ($map_flag eq 1) {

	$mapping_type = "Many-to-One Mapping";
	do_many_map();
} 

else {

	die "cannot calculate accuracy, flag must be either 0 or 1\n";
}





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub input_data {

	$gold_input = "";
	%gold_id = ();
	$gold_c = 0;
	$sys_input = "";
	%sys_id = ();
	$sys_c = 0;
	%gold_list = ();
	%sys_list = ();
	%gold_ptr = ();
	%sys_ptr = ();
	%word_table = ();

	while($gold_input = <$gold_cluster>) {	## accept gold cluster from file

		@temp_c = ();
		@temp_c = split /\s+/, $gold_input;

		$gold_id{$temp_c[0]} = $gold_c;
		$gold_ptr{$gold_c} = $temp_c[0];

		$gold_c += 1;

		for (my $cnt=1; $cnt<=$#temp_c; $cnt++) {
			
			$gold_list{$temp_c[$cnt]} = $temp_c[0];
		}
	}

	while($sys_input = <$sys_cluster>) {	## accept sys cluster from file

		@temp_c = ();
		@temp_c = split /\s+/, $sys_input;

		$sys_id{$temp_c[0]} = $sys_c;
		$sys_ptr{$sys_c} = $temp_c[0];

		$sys_c += 1;

		for (my $cnt=1; $cnt<=$#temp_c; $cnt++) {

			$sys_list{$temp_c[$cnt]} = $temp_c[0];
			$word_table{$temp_c[$cnt]} = $cnt;
		}
	}
	
	close $sys_input;
	close $gold_input;
}





sub populate_map {

	@matrix = ();
	%matrix_hash = ();
	$matrix_count = 0;
	$sum = 0;
	$total = 0;

	foreach $key (keys %word_table) {

		$g_id = 0;
		$s_id = 0;
		$s_word = $key;

		if ((exists ($gold_list{$key})) && (exists ($sys_list{$key}))) {
			
			$g_id = $gold_id{$gold_list{$key}};
			$s_id = $sys_id{$sys_list{$key}};
			
			$matrix[$s_id][$g_id] += 1;
			$total += 1;
		}
	}
			
	for (my $i=0; $i<=$sys_c; $i++) {

		for (my $j=0; $j<=$gold_c; $j++) {
		
			$matrix_str = "";

			if ($matrix[$i][$j] > 0) {
				
				$matrix_str = $sys_ptr{$i} . " " . $gold_ptr{$j};
				$matrix_hash{$matrix_str} = $matrix[$i][$j];
				$matrix_count += 1;

				$sum = $sum + $matrix[$i][$j];
			}
		}	
	}	
}





sub do_one_map {

	%output_hash = ();
	$acc_count = 0;
	$stop_flag = 0;

	while ($stop_flag ne $matrix_count) {

		$max_str = "";
		$out_str = "";
		$max_count = 0;
		@temp_c = ();

		foreach $key (keys %matrix_hash) {

			if ($matrix_hash{$key} > $max_count) {

				$max_str = $key;
				$max_count = $matrix_hash{$key};
			}
		}

		$acc_count = $acc_count + $max_count;
		
		$out_str = $max_str;	
		$out_str =~ s/ / => /;

		print $out_str, " ", $max_count, "\n";

		@temp_c = split /\s+/, $max_str;

		foreach $key (keys %matrix_hash) {

			@temp_a = ();
			@temp_a = split /\s+/, $key;

			if (($temp_c[0] eq $temp_a[0]) || ($temp_c[1] eq $temp_a[1])) {

				delete $matrix_hash{$key};
				$stop_flag += 1;
			}
		}
	}

	print STDERR "$mapping_type\n";
	print STDERR "Gold_Cluster: ", $ARGV[0], " ", "Cluster_Num=", $gold_c, "\n";
	print STDERR "Sys_Cluster: ", $ARGV[1], " ", "Cluster_Num=", $sys_c, "\n";
	print STDERR "Total_Token_Num=", $sum, " ", "Match=", $acc_count, "\n";
	print STDERR "Acc=", $acc_count/$sum;
}





sub do_many_map {

	%output_hash = ();
	$acc_count = 0;
	$stop_flag = 0;

	while ($stop_flag ne $matrix_count) {

		$max_str = "";
		$out_str = "";
		$max_count = 0;
		@temp_c = ();

		foreach $key (sort keys %matrix_hash) {

			if ($matrix_hash{$key} > $max_count) {

				$max_str = $key;
				$max_count = $matrix_hash{$key};
			}
		}

		$acc_count = $acc_count + $max_count;
		
		$out_str = $max_str;	
		$out_str =~ s/ / => /;

		print $out_str, " ", $max_count, "\n";

		@temp_c = split /\s+/, $max_str;

		foreach $key (sort keys %matrix_hash) {
		
			@temp_a = ();
			@temp_a = split /\s+/, $key;

			if ($temp_c[0] eq $temp_a[0]) {

				delete $matrix_hash{$key};
				$stop_flag += 1;
			}
		}
	}

	print STDERR "$mapping_type\n";
	print STDERR "Gold_Cluster: ", $ARGV[0], " ", "cluster_Num=", $gold_c, "\n";
	print STDERR "Sys_Cluster: ", $ARGV[1], " ", "cluster_Num=", $sys_c, "\n";
	print STDERR "Total_Token_Num=", $sum, " ", "Match=", $acc_count, "\n";
	print STDERR "Acc=", $acc_count/$sum;

}