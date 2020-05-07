#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





%data_table = ();
%model_table = ();
%class = ();
%feature = ();

$instance_cnt = 0;
$class_cnt = 0;


open($train, $ARGV[0]) or die "cannot open train file for input\n";
open($e_exp, '>>', $ARGV[1]) or die "cannot open model expectation file for output\n";


while($train_f = <$train>) {

	$temp_str = "";
	@temp_input = ();	
	@temp_input = split /\s+/, $train_f;
		
	$class{$temp_input[1]} = 1;
	$instance_cnt += 1;

	for (my $cnt=2; $cnt<$#temp_input; $cnt+=2)  {

		$data_table{$temp_input[1]}{$temp_input[$cnt]} += 1;
		$feature{$temp_input[$cnt]} += 1;
	}
}


calc_acc_pipe();


close $train;
close $e_exp;





#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub calc_acc_pipe {


	foreach $key (sort keys %class) {

		$class_key = "";
		$class_key = $key;

		foreach $key (sort keys %feature) {

			print {$e_exp} $class_key, " ", $key, " ", $data_table{$class_key}{$key}/$instance_cnt, "\n";
		}
	}
}

	

