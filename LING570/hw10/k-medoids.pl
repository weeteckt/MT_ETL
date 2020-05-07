#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





@vector_list = ();
%vector = ();
%medoid = ();
%cluster_str = ();
$medoid_pointer = 0;
$stop_flag = "false";


$cluster_size = $ARGV[1];

open($vector_file, $ARGV[0]) or die "cannot open vector file for input\n";

input_vector();
do_clustering();
find_medoid();
$iterate = 1;

while ($stop_flag ne "true") {

	%medoid = ();
	$stop_cnt = 0;
	$cluster_c = 0;

	foreach $key (keys %cluster_table) {
		
		if ($cluster_table{$key} eq "unchanged") {

			$stop_cnt += 1;
		}

		$cluster_c += 1;

		#print "iterate=", $iterate, " ", $cluster_table{$key}, "\t", $key, "\n";
	}

	if ($stop_cnt eq $cluster_c) {

		$stop_flag = "true";
	}

	if ($stop_flag ne "true") {

		foreach $key (keys %cluster_table) {
		
			$medoid{$key} = $vector{$key};
			$cluster_str{$key} = $key;
		}

	do_clustering();
	find_medoid();
	$iterate += 1;

	}
}


open($cluster_file, '>>', $ARGV[2]) or die "please provide a cluster file name\n";

$sum = 0;

foreach $key (sort keys %cluster_str) {

	print {$cluster_file} $key, " ",  $cluster_str{$key}, "\n";

}

print $iterate;





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub input_vector {

	$line_input = "";
	$line_count = 0;
	$num = 0;
	%word_l = ();

	while(($line_input = <$vector_file>)) {	## accept vector input from file

		@temp_w = ();
		@temp_w = split /\s+/, $line_input;

		if ($line_input ne "") {

			$vector_list[$line_count] = $line_input;
			$vector{$temp_w[0]} = $line_input;
			$word_l{$temp_w[0]} = $line_count;	
			$line_count += 1;
		}
	}
		
	$medoid_pointer = $line_count/$cluster_size;
	$medoid_pointer =~ s/\.[0-9]+//;
	$num = $medoid_pointer * $cluster_size;

	for (my $cnt=0; $cnt<$num; $cnt+=$medoid_pointer) {

		@temp_w = ();
		@temp_w = split /\s+/, $vector_list[$cnt];

		$medoid{$temp_w[0]} = $vector_list[$cnt];
		$cluster_str{$temp_w[0]} = $temp_w[0];
	}

	close $line_input;
}





sub do_clustering {

	foreach $key (keys %vector) {

		$j = 3;
		@temp_v = ();
		$sum_p = 0;
		@vector_ind = ();
		$max_cos = 0;
		$max_word = "";
		$max_word = $key;
		
		$curr_vector = "";
		$curr_vector = $vector{$key};
		$vector_str = "";
		$vector_str = $vector{$key};
		$vector_str =~ s/_L=/ L=/g;
		$vector_str =~ s/_R=/ R=/g;

		@temp_v = split /\s+/, $vector_str;
		
		for (my $cnt=1; $cnt<=$#temp_v; $cnt+=3) {

			$vector_ind[$temp_v[$cnt]] = $temp_v[$j];
			$sum_p += $temp_v[$j]**2;
			$j += 3;
		}

		$sum_p = sqrt($sum_p);

		foreach $key (keys %medoid) {

			$i = 3;
			@temp_str = ();
			$sum_pq = 0;
			$sum_q = 0;
			$cos_o = 0;
			$sqroot_pq = 0;

			$medoid_str = "";
			$medoid_str = $medoid{$key};
			$medoid_str =~ s/_L=/ L=/g;
			$medoid_str =~ s/_R=/ R=/g;

			@temp_str = split /\s+/, $medoid_str;

			for (my $ct=1; $ct<=$#temp_str; $ct+=3) {

				$sum_pq += $vector_ind[$temp_str[$ct]] * $temp_str[$i];
				$sum_q += $temp_str[$i]**2;
				$i += 3;
			}

			$sqroot_pq = $sum_p * sqrt($sum_q);

			if ($sqroot_pq > 0) {

				$cos_o = $sum_pq / $sqroot_pq;
			}

			if ($cos_o > $max_cos) {

				$max_cos = $cos_o;
				$max_word = $temp_str[0];
			}

		}

		if (!(exists ($medoid{$temp_v[0]}))) {

			$cluster_str{$max_word} = $cluster_str{$max_word} . " " . $temp_v[0]; 
		}
	}				
}





sub find_medoid {

	%cluster_table = ();

	foreach $key (keys %cluster_str) {
	
		$temp_string = "";
		@temp_c = ();
		$max_sim = 0;
					
		$curr_key = "";
		$curr_key = $key;
		
		$temp_string = $cluster_str{$key};
		@temp_c = split /\s+/, $temp_string;

		for (my $cnt=0; $cnt<=$#temp_c; $cnt++) {

			@medoid_ind = ();
			@temp_cm = ();
			$k = 3;
			$new_p = 0;
			$sum_sim = 0;
			$new_key = "";
			$new_key = $temp_c[$cnt];
	
			$curr_medoid = "";
			$curr_medoid = $vector{$new_key};
			$curr_medoid =~ s/_L=/ L=/g;
			$curr_medoid =~ s/_R=/ R=/g;

			@temp_cm = split /\s+/, $curr_medoid;

			for (my $ct=1; $ct<=$#temp_cm; $ct+=3) {

				$medoid_ind[$temp_cm[$ct]] = $temp_cm[$k];

				$new_p += $temp_cm[$k]**2;
				$k += 3;
			}

			$new_p = sqrt($new_p);

			for (my $c=0; $c<=$#temp_c; $c++) {

				@temp_nm = ();
				$l = 3;
				$new_pq = 0;
				$new_q = 0;
				$new_cos = 0;
				$new_sqr_pq = 0;

				$new_str = "";
				$new_str = $vector{$temp_c[$c]};
				$new_str =~ s/_L=/ L=/g;
				$new_str =~ s/_R=/ R=/g;

				@temp_nm = split /\s+/, $new_str;
				
				for (my $d=1; $d<=$#temp_nm; $d+=3) {						

					$new_pq += $medoid_ind[$temp_nm[$d]] * $temp_nm[$l];
					$new_q += $temp_nm[$l]**2;
					$l += 3;
				}

				$new_sqr_pq = $new_p * sqrt($new_q);

				if ($new_sqr_pq > 0) {

					$new_cos = $new_pq / $new_sqr_pq;
				}


				$sum_sim = $sum_sim + $new_cos;
			}

			if ($sum_sim > $max_sim) {
				
				$max_sim = $sum_sim;
				$new_medoid = $new_key;	
			}

			elsif (($sum_sim == $max_sim) && ($word_l{$new_key} < $word_l{$curr_key})) {

				$new_medoid = $new_key;
			}

			elsif (($sum_sim == $max_sim) && ($word_l{$new_key} > $word_l{$curr_key})) {

				$new_medoid = $curr_key;
			}
		}

		if (!(exists ($cluster_str{$new_medoid}))) {
			
			$cluster_table{$new_medoid} = "changed";
			$cluster_str{$new_medoid} = $cluster_str{$curr_key};
			delete $cluster_str{$curr_key};
		}

		else {

			$cluster_table{$curr_key} = "unchanged";	
		}
	}
}

