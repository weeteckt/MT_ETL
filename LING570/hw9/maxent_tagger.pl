#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------





$input_file = "";
$rare_thres = $ARGV[2];
$feat_thres = $ARGV[3];
$directory_name = $ARGV[4];
$pref = "pref=";
$suf = "suf=";
%word_hash = ();
%feature_hash = ();


process_training_word();
clean_up_word();
clean_up_feature();

$t_flag = "Train";
output_vector();
$t_flag = "Test";
output_vector();
output_vocab();
output_feat();


	


#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------





sub process_training_word {

	$line_input = "";

	open($input_file, $ARGV[0]) or die "cannot open training file for input\n";

	while(($line_input = <$input_file>)) {	## accept input from file

		$cnt = 0;
		$temp_line = "";
		@temp_input = ();
		@word_table = ();
		@tag_table = ();
		
		$temp_line = "BOS/BOS BOS/BOS " . $line_input . " EOS/EOS EOS/EOS";		
		@temp_input = split /\s+/, $temp_line;

		foreach $temp_input(@temp_input) {

			@wt = ();
			$temp_wt = "";

			$temp_wt = $temp_input;
			$temp_wt =~ s/\,/comma/g;
			$temp_wt =~ s/\\\//{{{/g;
			$temp_wt =~ s/\// /g;
			$temp_wt =~ s/{{{/\\\//g;

			@wt = split /\s+/, $temp_wt;

			if (($wt[0] ne "") && ($wt[1] ne "")) {

				$word_hash{$wt[0]} += 1;				
			}
		}	
	}

	close $input_file;
}





sub clean_up_word {

	foreach $key (sort keys %word_hash) {

		if ($word_hash{$key} < $rare_thres) {

			delete $word_hash{$key};
		}
	}
}





sub clean_up_feature {

	$line_input = "";

	open($input_file, $ARGV[0]) or die "cannot open training file for input\n";

	while(($line_input = <$input_file>)) {	## accept input from file

		$cnt = 0;
		$temp_line = "";
		@temp_input = ();
		@word_table = ();
		@tag_table = ();
		
		$temp_line = "BOS/BOS BOS/BOS " . $line_input . " EOS/EOS EOS/EOS";		
		@temp_input = split /\s+/, $temp_line;

		foreach $temp_input(@temp_input) {

			@wt = ();
			$temp_wt = "";

			$temp_wt = $temp_input;
			$temp_wt =~ s/\,/comma/g;
			$temp_wt =~ s/\\\//{{{/g;
			$temp_wt =~ s/\// /g;
			$temp_wt =~ s/{{{/\\\//g;

			@wt = split /\s+/, $temp_wt;

			if (($wt[0] ne "") && ($wt[1] ne "")) {

				$word_table[$cnt] = $wt[0];
				$tag_table[$cnt] = $wt[1];				

				$cnt += 1;
			}
		}
						
		for ($cnt=2; $cnt<= $#word_table-2; $cnt++) {	

			$curw = "";
			$nextw = "";
			$next2w = "";
			$prevw = "";
			$prev2w = "";
			$prevt = "";
			$prev2t = "";			

			$pref1 = "";
			$pref2 = "";
			$pref3 = "";
			$pref4 = "";

			$suf1 = "";
			$suf2 = "";
			$suf3 = "";
			$suf4 = "";

			$containuc = "";
			$containnum = "";
			$containhyp = "";

			$nextw = "nextW=" . $word_table[$cnt+1] . " 1 ";
			$next2w = "next2W=" . $word_table[$cnt+2] . " 1 ";
			$prevw = "prevW=" . $word_table[$cnt-1] . " 1 ";
			$prev2w = "prev2W=" . $word_table[$cnt-2] . " 1 ";
			$prevt = "prevT=" . $tag_table[$cnt-1] . " 1 ";
			$prev2t = "prevTwoTags=" . $tag_table[$cnt-2] . "+" . $tag_table[$cnt-1] . " 1 ";
	
			$feature_hash{$nextw} += 1;
			$feature_hash{$next2w} += 1;
			$feature_hash{$prevw} += 1;
			$feature_hash{$prev2w} += 1;
			$feature_hash{$prevt} += 1;
			$feature_hash{$prev2t} += 1;
			
			$special = "";

			if (exists ($word_hash{$word_table[$cnt]})) {

				$curw = "curW=" . $word_table[$cnt] . " 1 ";
				$feature_hash{$curw} += 1;
			}
			
			else {

				@special_c = ();
				$special = $word_table[$cnt];
				@special_c = split //, $special;

				if ($word_table[$cnt] =~ /[A-Z]/) {
				
					$containuc = "containUC" . " 1 ";
					$feature_hash{$containuc} += 1;
				}
			
				if ($word_table[$cnt] =~ /[0-9]/) {
				
					$containnum = "containNum" . " 1 ";
					$feature_hash{$containnum} += 1;
				}

				if ($word_table[$cnt] =~ /-/) {
				
					$containhyp = "containHyp" . " 1 ";
					$feature_hash{$containhyp} += 1;
				}

				$pref1 = $pref . $special_c[0] . " 1 ";
				$pref2 = $pref . $special_c[0] . $special_c[1] . " 1 ";
				$pref3 = $pref . $special_c[0] . $special_c[1] . $special_c[2] . " 1 ";
				$pref4 = $pref . $special_c[0] . $special_c[1] . $special_c[2] . $special_c[3] . " 1 ";

				$suf1 = $suf . $special_c[$#special_c]. " 1 ";
				$suf2 = $suf . $special_c[$#special_c-1] . $special_c[$#special_c] . " 1 ";
				$suf3 = $suf . $special_c[$#special_c-2] . $special_c[$#special_c-1] . $special_c[$#special_c] . " 1 ";
				$suf4 = $suf . $special_c[$#special_c-3] . $special_c[$#special_c-2] . $special_c[$#special_c-1] . $special_c[$#special_c] . " 1 ";

				if ($#special_c eq 2) {

					$suf4 = "";
					$pref4 = "";
				}

				elsif ($#special_c eq 1) {

					$suf3 = "";
					$suf4 = "";
					$pref3 = "";
					$pref4 = "";
				}

				elsif ($#special_c eq 0) {

					$suf2 = "";
					$suf3 = "";
					$suf4 = "";
					$pref2 = "";
					$pref3 = "";
					$pref4 = "";
				}

				$feature_hash{$pref1} += 1;
				$feature_hash{$pref2} += 1;
				$feature_hash{$pref3} += 1;
				$feature_hash{$pref4} += 1;
				$feature_hash{$suf1} += 1;
				$feature_hash{$suf2} += 1;
				$feature_hash{$suf3} += 1;
				$feature_hash{$suf4} += 1;
			}
		}
	}

	close $input_file;
}





sub output_vector {

	$line_input = "";
	$sentence_cnt = 1;
	$output_v =  "";
	
	if ($t_flag eq "Train") {

		open($input_file, $ARGV[0]) or die "cannot open training file for input\n";
		open (my $train_v, '>>', "final_train.vectors.txt") or die "unable to create train vector file\n";
		$output_v = $train_v;
	}

	elsif ($t_flag eq "Test") {

		open($input_file, $ARGV[1]) or die "cannot open testing file for input\n";
		open (my $test_v, '>>', "final_test.vectors.txt") or die "unable to create test vector file\n";
		$output_v = $test_v;
	}


	while(($line_input = <$input_file>)) {	## accept input from file

		$cnt = 0;
		$temp_line = "";
		@temp_input = ();
		@word_table = ();
		@tag_table = ();
		
		$temp_line = "BOS/BOS BOS/BOS " . $line_input . " EOS/EOS EOS/EOS";		
		@temp_input = split /\s+/, $temp_line;

		foreach $temp_input(@temp_input) {

			@wt = ();
			$temp_wt = "";

			$temp_wt = $temp_input;
			$temp_wt =~ s/\,/comma/g;
			$temp_wt =~ s/\\\//{{{/g;
			$temp_wt =~ s/\// /g;
			$temp_wt =~ s/{{{/\\\//g;

			@wt = split /\s+/, $temp_wt;

			if (($wt[0] ne "") && ($wt[1] ne "")) {

				$word_table[$cnt] = $wt[0];
				$tag_table[$cnt] = $wt[1];				

				$cnt += 1;
			}
		}
						
		$word_pos = 0;

		for ($cnt=2; $cnt<= $#word_table-2; $cnt++) {

			$curw = "";
			$nextw = "";
			$next2w = "";
			$prevw = "";
			$prev2w = "";
			$prevt = "";
			$prev2t = "";

			$pref1 = "";
			$pref2 = "";
			$pref3 = "";
			$pref4 = "";

			$suf1 = "";
			$suf2 = "";
			$suf3 = "";
			$suf4 = "";

			$containuc = "";
			$containnum = "";
			$containhyp = "";

			$special = "";

			if (exists ($word_hash{$word_table[$cnt]})) {

				$curw = "curW=" . $word_table[$cnt] . " 1 ";
			}

			
			else {

				@special_c = ();
				$special = $word_table[$cnt];
				@special_c = split //, $special;

				if ($word_table[$cnt] =~ /[A-Z]/) {
				
					$containuc = "containUC" . " 1 ";
				}
			
				if ($word_table[$cnt] =~ /[0-9]/) {
				
					$containnum = "containNum" . " 1 ";
				}

				if ($word_table[$cnt] =~ /-/) {
				
					$containhyp = "containHyp" . " 1 ";
				}

				$pref1 = $pref . $special_c[0] . " 1 ";
				$pref2 = $pref . $special_c[0] . $special_c[1] . " 1 ";
				$pref3 = $pref . $special_c[0] . $special_c[1] . $special_c[2] . " 1 ";
				$pref4 = $pref . $special_c[0] . $special_c[1] . $special_c[2] . $special_c[3] . " 1 ";

				$suf1 = $suf . $special_c[$#special_c]. " 1 ";
				$suf2 = $suf . $special_c[$#special_c-1] . $special_c[$#special_c] . " 1 ";
				$suf3 = $suf . $special_c[$#special_c-2] . $special_c[$#special_c-1] . $special_c[$#special_c] . " 1 ";
				$suf4 = $suf . $special_c[$#special_c-3] . $special_c[$#special_c-2] . $special_c[$#special_c-1] . $special_c[$#special_c] . " 1 ";

				if ($#special_c eq 2) {

					$suf4 = "";
					$pref4 = "";
				}

				elsif ($#special_c eq 1) {

					$suf3 = "";
					$suf4 = "";
					$pref3 = "";
					$pref4 = "";
				}

				elsif ($#special_c eq 0) {

					$suf2 = "";
					$suf3 = "";
					$suf4 = "";
					$pref2 = "";
					$pref3 = "";
					$pref4 = "";
				}
			}
				
			$nextw = "nextW=" . $word_table[$cnt+1] . " 1 ";
			$next2w = "next2W=" . $word_table[$cnt+2] . " 1 ";
			$prevw = "prevW=" . $word_table[$cnt-1] . " 1 ";
			$prev2w = "prev2W=" . $word_table[$cnt-2] . " 1 ";
			$prevt = "prevT=" . $tag_table[$cnt-1] . " 1 ";
			$prev2t = "prevTwoTags=" . $tag_table[$cnt-2] . "+" . $tag_table[$cnt-1] . " 1 ";

			print {$output_v} $sentence_cnt, "-", $word_pos, "-", $word_table[$cnt], " ", $tag_table[$cnt], " ";

			print {$output_v} $curw if ($curw ne "");  
			print {$output_v} $prevw if ($feature_hash{$prevw} >= $feat_thres);
			print {$output_v} $prev2w if ($feature_hash{$prev2w} >= $feat_thres);
			print {$output_v} $nextw if ($feature_hash{$nextw} >= $feat_thres);
			print {$output_v} $next2w if ($feature_hash{$next2w} >= $feat_thres);
			print {$output_v} $prevt if ($feature_hash{$prevt} >= $feat_thres);
			print {$output_v} $prev2t if ($feature_hash{$prev2t} >= $feat_thres);
			
			print {$output_v} $pref1 if (($feature_hash{$pref1} >= $feat_thres) && ($pref1 ne ""));
			print {$output_v} $pref2 if (($feature_hash{$pref2} >= $feat_thres) && ($pref2 ne ""));
			print {$output_v} $pref3 if (($feature_hash{$pref3} >= $feat_thres) && ($pref3 ne ""));
			print {$output_v} $pref4 if (($feature_hash{$pref4} >= $feat_thres) && ($pref4 ne ""));

			print {$output_v} $suf1 if (($feature_hash{$suf1} >= $feat_thres) && ($suf1 ne ""));
			print {$output_v} $suf2 if (($feature_hash{$suf2} >= $feat_thres) && ($suf2 ne ""));
			print {$output_v} $suf3 if (($feature_hash{$suf3} >= $feat_thres) && ($suf3 ne ""));
			print {$output_v} $suf4 if (($feature_hash{$suf4} >= $feat_thres) && ($suf4 ne ""));
	
			print {$output_v} $containuc if ($feature_hash{"$containuc"} >= $feat_thres);
			print {$output_v} $containnum if ($feature_hash{"$containnum"} >= $feat_thres);
			print {$output_v} $containhyp if ($feature_hash{"$containhyp"} >= $feat_thres);

			print {$output_v} "\n";

			$word_pos += 1;
		}

		$sentence_cnt += 1;
	}

	close $input_file;
}





sub output_vocab {

	open (my $voc_out, '>>', "train_voc") or die "unable to create train vocab file\n";

	foreach $key (sort {$word_hash{$b} <=> $word_hash{$a}} keys %word_hash) {

		if (($key ne "BOS") && ($key ne "EOS")) {

			print {$voc_out} $key;
			print {$voc_out} "\t";
			print {$voc_out} $word_hash{$key};
			print {$voc_out} "\n";			
		}
	}
	
	close $voc_out;		
}





sub output_feat {

	$kept = 0;
	$feat = 0;
	$temp_k = "";
	$temp_f = "";

	open (my $feat_out, '>>', "train.vectors.feats") or die "unable to create train vectors features file\n";
	open (my $kfeat_out, '>>', "kept_feats") or die "unable to create kept features file\n";	

	foreach $key (sort {$feature_hash{$b} <=> $feature_hash{$a}} keys %feature_hash) {

		if ($key ne "") {
			
			$temp_f = $key;
			$temp_f =~ s/comma/,/;

			print {$feat_out} $temp_f;
			print {$feat_out} " ";
			print {$feat_out} $feature_hash{$key};
			print {$feat_out} "\n";	
			$feat += 1;
		}

		if (($feature_hash{$key} >= $feat_thres) && ($key ne "")) {

			$temp_k = $key;
			$kemp_k =~ s/comma/,/;

			print {$kfeat_out} $temp_k;
			print {$kfeat_out} " ";
			print {$kfeat_out} $feature_hash{$key};
			print {$kfeat_out} "\n";
			$kept += 1;			
		}
	}
	
	#print "Kept=", $kept, "\t", "Feat=", $feat, "\n";
	#print "rare=", $rare_thres, "\t", "feat=", $feat_thres;

	close $feat_out;
	close $kfeat_out;		
}
