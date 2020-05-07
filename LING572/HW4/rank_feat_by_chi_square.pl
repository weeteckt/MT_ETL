#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





%class_feat = ();

%class = ();
%feature = ();
%chi_sq_table = ();
%chi_sq_doc = ();

%input_instance = ();


while($input_sentence = <STDIN>) {

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $input_sentence;
	
	$input_instance{$temp_input[0]} = $input_sentence;

	$class{$temp_input[1]} += 1;
	$total_instance += 1;

	for (my $cnt=2; $cnt<$#temp_input; $cnt+=2)  {

		$class_feat{$temp_input[1]}{$temp_input[$cnt]} += 1;
		$feature{$temp_input[$cnt]} += 1;
	}
}


calc_chi_sq ();


foreach $key (sort {$chi_sq_table{$b} <=> $chi_sq_table{$a}} keys %chi_sq_table) { 

	print $key, " ", $chi_sq_table{$key}, " ", $chi_sq_doc{$key},  "\n";
}





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub calc_chi_sq {

	foreach $key (keys %feature) {

		$f_key = "";
		$f_key = $key;

		$not_total = 0;
		$yes_total = 0;
		$chi_sq = 0;

		foreach $key (keys %class) {
		
			$c_key = "";
			$c_key = $key;
			
			$yes_total += ($class{$c_key} - $class_feat{$c_key}{$f_key});
			$not_total += $class_feat{$c_key}{$f_key}; 
		}

		foreach $key (keys %class) {
		
			$c_key = "";
			$c_key = $key;
			
			$class_total = 0;
			$not = 0;
			$yes = 0;

			$y_o_value = 0;
			$y_e_value = 0;
			$n_o_value = 0;
			$n_e_value = 0;

		
			$class_total = ($class{$c_key} - $class_feat{$c_key}{$f_key}) + $class_feat{$c_key}{$f_key}; 

			$y_o_value = ($class{$c_key} - $class_feat{$c_key}{$f_key});
			$y_e_value = ($class_total*$yes_total)/($yes_total+$not_total);
			$yes = (($y_o_value-$y_e_value)**2)/$y_e_value;

			$n_o_value = $class_feat{$c_key}{$f_key};
			$n_e_value = ($class_total*$not_total)/($yes_total+$not_total);
			$not = (($n_o_value-$n_e_value)**2)/$n_e_value;
			
 			$chi_sq += ($yes+$not);
		}

		$chi_sq_table{$f_key} = $chi_sq;
		$chi_sq_doc{$f_key} = $not_total;
	}
}


