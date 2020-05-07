#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





%test_table = ();
@model_table = ();

$p = 0; 		## p value
$c = 0; 		## coefficient value
$d = 0; 		## degree
$e = 2.718281828;	## exponent
$gamma = 0; 		## gamma value

$kernel = "";
$line_cnt = 0;
$begin = "no";


open($model, $ARGV[1]) or die "cannot open model file for input\n";

while ($model_f = <$model>) {

	$temp_str = "";
	$temp_str = $model_f;

	if ($temp_str =~ m/kernel_type /) {

		$temp_str =~ s/\n//;
		$temp_str =~ s/kernel_type //;
		$kernel = $temp_str;
	}
	
	if ($temp_str =~ m/degree /) {

		$temp_str =~ s/\n//;
		$temp_str =~ s/degree //;
		$d = $temp_str;
	}

	if ($temp_str =~ m/gamma /) {

		$temp_str =~ s/\n//;
		$temp_str =~ s/gamma //;
		$gamma = $temp_str;
	}

	if ($temp_str =~ m/coef0 /) {

		$temp_str =~ s/\n//;
		$temp_str =~ s/coef0 //;
		$c = $temp_str;
	}

	if ($temp_str =~ m/rho /) {

		$temp_str =~ s/\n//;
		$temp_str =~ s/rho //;
		$p = $temp_str;
	}

	if ($begin eq "yes") {

		
		$temp_str =~ s/\n//;
		$model_table[$line_cnt] = $temp_str;
		$line_cnt += 1;
	}

	if ($temp_str =~ m/SV/) {

		$begin = "yes";
	}
	
}

close $model;





open($test, $ARGV[0]) or die "cannot open test file for input\n";

if ($kernel eq "linear") {

	decode_linear();
}

elsif ($kernel eq "polynomial") {

	decode_polynomial();
}

elsif ($kernel eq "rbf") {

	decode_rbf();
}

elsif ($kernel eq "sigmoid") {

	decode_sigmoid();
}

close $test;



	

#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub decode_linear {

	open($sys, '>', $ARGV[2]) or die "cannot open sys file for output\n";

	$total = 0;
	$match = 0;

	while ($test_f = <$test>) {

		$true_class = "";
		$sys_class = "";

		$f_x = 0;

		$temp_str = "";
		@temp_input = ();
		%test_feature = ();

		$temp_str = $test_f;
		$temp_str =~ s/\n//;

		@temp_input = split /\s+/, $temp_str;
		$true_class = $temp_input[0]; 

		print {$sys} $true_class, " ";
					
		for (my $cnt=1; $cnt<=$#temp_input; $cnt++)  {

			$test_x = "";
			$test_x = $temp_input[$cnt];
			$test_x =~ s/\:/ /;
			
			@t_x = split /\s+/, $test_x;
			$test_feature{$t_x[0]} = $t_x[1];
		}

		for (my $cnt=0; $cnt<=$#model_table; $cnt++)  { 

			$weight = 0;
			$xz = 0;
		
			$model_x = "";
			$model_x = $model_table[$cnt];
			$model_x =~ s/\:/ /g;

			@m_x = split /\s+/, $model_x;
			$weight = $m_x[0];

			for (my $m_cnt=1; $m_cnt<=$#m_x; $m_cnt+=2)  { 

				$xz += $m_x[$m_cnt+1] * $test_feature{$m_x[$m_cnt]};
			}

			$f_x += ($weight * $xz);
		}

		$f_x = $f_x - $p;
		
		if ($f_x > 0) {

			$sys_class = 0;
		}

		else {

			$sys_class = 1;
		}

		$total += 1;

		if ($true_class eq $sys_class) {

			$match += 1;
		}

		print {$sys} $sys_class, " ", $f_x, "\n";
	}

	print "\n";

	print $kernel, " function accuracy: ", ($match/$total)*100, "%", "\n";

	close $sys
}





sub decode_polynomial {

	open($sys, '>', $ARGV[2]) or die "cannot open sys file for output\n";

	$total = 0;
	$match = 0;

	while ($test_f = <$test>) {

		$true_class = "";
		$sys_class = "";

		$f_x = 0;

		$temp_str = "";
		@temp_input = ();
		%test_feature = ();

		$temp_str = $test_f;
		$temp_str =~ s/\n//;

		@temp_input = split /\s+/, $temp_str;
		$true_class = $temp_input[0]; 

		print {$sys} $true_class, " ";
					
		for (my $cnt=1; $cnt<=$#temp_input; $cnt++)  {

			$test_x = "";
			$test_x = $temp_input[$cnt];
			$test_x =~ s/\:/ /;
			
			@t_x = split /\s+/, $test_x;
			$test_feature{$t_x[0]} = $t_x[1];
		}

		for (my $cnt=0; $cnt<=$#model_table; $cnt++)  { 

			$weight = 0;
			$xz = 0;
			
			$model_x = "";
			$model_x = $model_table[$cnt];
			$model_x =~ s/\:/ /g;

			@m_x = split /\s+/, $model_x;
			$weight = $m_x[0];

			for (my $m_cnt=1; $m_cnt<=$#m_x; $m_cnt+=2)  { 

				$xz += $m_x[$m_cnt+1] * $test_feature{$m_x[$m_cnt]};
			}

			$f_x += ($weight * ((($gamma * $xz) + $c)**$d));
		}

		$f_x = $f_x - $p;
		
		if ($f_x > 0) {

			$sys_class = 0;
		}

		else {

			$sys_class = 1;
		}

		$total += 1;

		if ($true_class eq $sys_class) {

			$match += 1;
		}

		print {$sys} $sys_class, " ", $f_x, "\n";
	}

	print "\n";

	print $kernel, " function accuracy: ", ($match/$total)*100, "%", "\n";

	close $sys
}





sub decode_rbf {

	open($sys, '>', $ARGV[2]) or die "cannot open sys file for output\n";

	$total = 0;
	$match = 0;

	while ($test_f = <$test>) {

		$true_class = "";
		$sys_class = "";

		$f_x = 0;

		$temp_str = "";
		@temp_input = ();

		%test_feature = ();

		$temp_str = $test_f;
		$temp_str =~ s/\n//;

		@temp_input = split /\s+/, $temp_str;
		$true_class = $temp_input[0]; 

		print {$sys} $true_class, " ";
					
		for (my $cnt=1; $cnt<=$#temp_input; $cnt++) {

			$test_x = "";
			$test_x = $temp_input[$cnt];
			$test_x =~ s/\:/ /;
			
			@t_x = split /\s+/, $test_x;

			$test_feature{$t_x[0]} = $t_x[1]**2;
		}

		for (my $cnt=0; $cnt<=$#model_table; $cnt++) { 

			$weight = 0;
			$xz = 0;
			
			$model_x = "";
			$model_x = $model_table[$cnt];
			$model_x =~ s/\:/ /g;

			%model_feature = ();

			%model_feature = %test_feature;

			@m_x = split /\s+/, $model_x;
			$weight = $m_x[0];

			for (my $m_cnt=1; $m_cnt<=$#m_x; $m_cnt+=2) { 

				if (exists $test_feature{$m_x[$m_cnt]}) {

					if (sqrt($test_feature{$m_x[$m_cnt]}) ne $m_x[$m_cnt+1]) {
				
						$model_feature{$m_x[$m_cnt]} = (sqrt($test_feature{$m_x[$m_cnt]}) - $m_x[$m_cnt+1])**2;
					}

					else {

						$model_feature{$m_x[$m_cnt]} = 0;
					}
				}

				else {

					$model_feature{$m_x[$m_cnt]} = $m_x[$m_cnt+1]**2;
				}
			}

			foreach $key (keys %model_feature) {

				$xz += $model_feature{$key};
			}

			$f_x += $weight * ($e**(-$gamma * ((sqrt($xz))**2)));
		}

		$f_x = $f_x - $p;
		
		if ($f_x > 0) {

			$sys_class = 0;
		}

		else {
			$sys_class = 1;
		}

		$total += 1;

		if ($true_class eq $sys_class) {

			$match += 1;
		}

		print {$sys} $sys_class, " ", $f_x, "\n";
	}

	print "\n";

	print $kernel, " function accuracy: ", ($match/$total)*100, "%", "\n";

	close $sys
}





sub decode_sigmoid {

	open($sys, '>', $ARGV[2]) or die "cannot open sys file for output\n";

	$total = 0;
	$match = 0;

	while ($test_f = <$test>) {

		$true_class = "";
		$sys_class = "";

		$f_x = 0;

		$temp_str = "";
		@temp_input = ();
		%test_feature = ();

		$temp_str = $test_f;
		$temp_str =~ s/\n//;

		@temp_input = split /\s+/, $temp_str;
		$true_class = $temp_input[0]; 

		print {$sys} $true_class, " ";
					
		for (my $cnt=1; $cnt<=$#temp_input; $cnt++)  {

			$test_x = "";
			$test_x = $temp_input[$cnt];
			$test_x =~ s/\:/ /;
			
			@t_x = split /\s+/, $test_x;
			$test_feature{$t_x[0]} = $t_x[1];
		}

		for (my $cnt=0; $cnt<=$#model_table; $cnt++)  { 

			$weight = 0;
			$xz = 0;
			$tanh = 0;
			$tan_x = 0;
			
			$model_x = "";
			$model_x = $model_table[$cnt];
			$model_x =~ s/\:/ /g;

			@m_x = split /\s+/, $model_x;
			$weight = $m_x[0];

			for (my $m_cnt=1; $m_cnt<=$#m_x; $m_cnt+=2)  { 

				$xz += $m_x[$m_cnt+1] * $test_feature{$m_x[$m_cnt]};
			}

			$tan_x = ($gamma * $xz) + $c;
			$tanh = (($e**$tan_x) - ($e**(-$tan_x))) / (($e**$tan_x) + ($e**(-$tan_x)));

			$f_x += ($weight * $tanh);
		}

		$f_x = $f_x - $p;
		
		if ($f_x > 0) {

			$sys_class = 0;
		}

		else {

			$sys_class = 1;
		}

		$total += 1;

		if ($true_class eq $sys_class) {

			$match += 1;
		}

		print {$sys} $sys_class, " ", $f_x, "\n";
	}

	print "\n";

	print $kernel, " function accuracy: ", ($match/$total)*100, "%", "\n";

	close $sys
}