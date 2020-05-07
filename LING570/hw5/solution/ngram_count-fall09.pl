#!/usr/bin/env perl

## created on 10/25/09
##  modified from 193/e/ngram_count.pl
##  (search for "Fei" to see the one-line difference)

## Purpose: collect n-gram counts from the training data

## usage: $0 training_data output_file
##


use strict;

my $sent_num = 0;   # non-blank line
my $voc_size = 0;   # without EOS, BOS, unk
my $token_num = 0;  # number of word types
my $bigram_num = 0;

my $unk_str = "UNK_UNK";
my $BOS_str = "<s>"; 
my $EOS_str = "</s>";
my $delim = " ";

my $log10 = log(10);

main();

1;


##########################################
sub main {
    if(@ARGV != 2){
	die "usage: $0 training_data output_file\n";
    }

    my $ngram = 3; 
    my $training_file = $ARGV[0];
    my $output_file = $ARGV[1];

    my @hash_array = ();

    open(my $out_fp, ">$output_file") or die "cannot create $output_file\n";
    open(my $in_fp, "$training_file") or die "cannot open $training_file\n";
    print STDERR "max_ngram=$ngram\n";

    for(my $i=1; $i<=$ngram; $i++){
	push(@hash_array, {});
    }



    ################# step 1: collect the counts
    my $sent_num = 0;
    my $word_num = 0;  # word type number, w/o EOS/BOS

    while(<$in_fp>){
	chomp;
	if($sent_num % 10000 == 0){
           my $tmp = $sent_num / 1000;
	   print STDERR "Finish $tmp K lines\n";
        }

	if(/^\s*$/){
	    next;
	}

	s/^\s+//;
	s/\s+$//;

	my $line = $_;
	$line = $BOS_str . " " . $line . " " . $EOS_str;

	my @parts = split(/\s+/, $line);
	my $sent_leng = scalar @parts;
	$sent_num ++;
	$word_num += $sent_leng - 2;

	for(my $j=1; $j<=$ngram; $j++){
	    ## collect ngram
	    my $hash = $hash_array[$j-1];
	    
	    for(my $i=0; $i<$sent_leng - $j + 1; $i++){
		## the ngram is w_i, w_{i+1}, ... w_{i+j-1}
		my $k = $i + $j - 1;
		my $key = join($delim, @parts[$i..$k]);
		if(defined($hash->{$key})){
		    $hash->{$key} ++;
		}else{
		    $hash->{$key} ++;
		}
	    } # end of each pass
	} # end for each n
    } # end for each sentence

    
    ######## step 3: print out the LM
    print STDERR "sent_num=$sent_num, word_num=$word_num\n";

    for(my $i=1; $i<=$ngram; $i++){
	my $hash = $hash_array[$i-1];
	my ($ngram_type_size, $ngram_token_num) = print_ngram($out_fp, $hash);
	
	print STDERR "$i-gram: type=$ngram_type_size, token=$ngram_token_num\n";
    }

    close($out_fp);
    print STDERR "All done. Output is under $output_file\n";
}

# return (voc_size, token_num)
sub print_ngram {
    my ($fp, $hash_ptr) = @_;

    my $voc_size = 0;
    my $token_num = 0;

    foreach my $key (sort {$hash_ptr->{$b} <=> $hash_ptr->{$a}}
		     keys %$hash_ptr){
	my $val = $hash_ptr->{$key};

        ### Fei: this line is the only difference from ngram_count.pl
	print $fp "$val\t$key\n";  

	$voc_size ++;
	$token_num += $val;
    }

    return ($voc_size, $token_num);
}


sub systemx {
    my ($cmd) = @_;

    print STDERR "\n\n***************$cmd\n\n";
    system($cmd);
    if($?){
        die "$cmd failed\n";
    }else{
        print STDERR "+++++$cmd++++ succeeds\n\n\n";
    }
}
