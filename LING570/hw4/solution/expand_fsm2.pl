#!/usr/bin/perl

# created on 10/16/09
#  modified from expand_fsm1.pl (=da193.exec)
#  The difference is that class labels are outputed.
#  We achieve this by using an expanded FST, not FSA, and for each edge
#   q_i => q_j, we added an edge from q_i-q_j-class to q_j with *e*:class_label


# purpose: use a lexicon to expand an FST
# 
# usage: $0 lexicon input_FST output_FST
#
# The format:
#    lexicon: word class
#    input_FST:  final_state
#                (from (to class))
#                ...
#
#    output_FST:  same as input_FSA, except that class_label is replaced by
#                  character and the class is printed out
#                  (and new states are introduced)


use strict;

### constants
my $delim = "_";
my $EMPTY_STR = "*e*";

main();
1;

sub main {
    my $argc = scalar @ARGV;

    if($argc != 3){
	die "usage: $0 lexicon input_fst output_fst\n";
    }

    my $lexicon = $ARGV[0];
    my $input_fst = $ARGV[1];
    my $output_fst = $ARGV[2];

    #### step 1: read the files and FST
    my %lexicon_map = ();
    my $lexicon_entry_num = read_lexicon($lexicon, \%lexicon_map);
    print STDERR "read $lexicon_entry_num from $lexicon\n";

    my $init_state;
    my $final_state;
    my @edges = ();  ## edges in the input_FSA
    my $fst_line = read_fst($input_fst, \$final_state, \$init_state,
			    \@edges);

    #### step 2: get the new fst
    open(my $out_fp, ">$output_fst") or die "cannot create $output_fst\n";
    print $out_fp "$final_state\n";
    
    foreach my $edge (@edges){
	### the edge is $from to $to and the edge has the label $class
	my ($from, $to, $class) = split(/\s+/, $edge);
	my $words_str = $lexicon_map{$class};
	if($class eq $EMPTY_STR){
	    print_edge($out_fp, $from, $to, $EMPTY_STR, $EMPTY_STR);
	    next;
	}

	if(!defined($words_str)){
	    print STDERR "Error: $class in +$edge+ is not defined in the lexicon\n";
	    next;
	}

	my @words = split(/\s+/, $words_str);
	my $new_to_state = $from . "-" . $to . "-" . $class;

	### process each word in the class
	foreach my $word (@words){
	    my @chars = split(//, $word);
	    my $char_num = scalar @chars;
	    if($char_num == 1){
		print_edge($out_fp, $from, $new_to_state, $word, $EMPTY_STR);
		next;
	    }

	    my $cur_from = $from;

	    ## for each char, print out an edge
	    for(my $i=0; $i<$char_num; $i++){
		my $char = $chars[$i];
		my $cur_end;
		if($i == $char_num - 1){
		    $cur_end = $new_to_state;
		}else{
		    if($i == 0){
			$cur_end = $cur_from . $delim . $char;
		    }else{
			$cur_end = $cur_from . $char;
		    }
		}
		print_edge($out_fp, $cur_from, $cur_end, $char, $EMPTY_STR);
		$cur_from = $cur_end;
	    }
	}  # end of every word

	print_edge($out_fp, $new_to_state, $to, $EMPTY_STR, $class);
    }

    close($out_fp);
}


#######################################################
sub print_edge {
    my ($out_fp, $from, $to, $x, $y) = @_;

    if($x ne $EMPTY_STR){
	$x = "\"$x\"";
    }

    if($y ne $EMPTY_STR){
	$y = "\"$y\"";
    }

    print $out_fp "($from ($to $x $y))\n";
}

## return the number of entries
sub read_lexicon {
    my ($filename, $hash) = @_;
    my $cnt = 0;

    open(my $fp, "$filename") or die "cannot open $filename\n";
    while(<$fp>){
	chomp;
	if(/^\s*$/){
	    next;
	}
	s/\s+$//;
	s/^\s+//;
	my @parts = split(/\s+/);
	if(scalar @parts != 2){
	    print STDERR "wrong format: +$_+\n";
	    next;
	}
	my $class = $parts[1];
	my $word = $parts[0];

	$cnt ++;
	my $ptr = $hash->{$class};
	if(defined($ptr)){
	    $hash->{$class} = $ptr . " " . $word;
	}else{
	    $hash->{$class} = $word;
	}
    }

    return $cnt;
}


# return the number of valid lines
sub read_fst {
    my ($filename, $final_ptr, $init_ptr, $edges_ptr) = @_;
    my $cnt = 0;

    open(my $fp, "$filename") or die "cannot open $filename\n";
    @$edges_ptr = ();

    while(<$fp>){
	chomp;
	if(/^\s*$/){
	    next;
	}

	s/^\s+//;
	s/\s+$//;

	my $line = $_;
	
	if($cnt == 0){
	    if($line =~ /^\S+$/){
		$$final_ptr = $line;
		$cnt ++;
		next;
	    }
	}
	
	# Ex: (q0 (q1 reg_verb_stem))
	if($line =~ /^\((\S+)\s+\((\S+)\s+(\S+)\)\s*\)$/){
	    my $from_state = $1;
	    my $to_state = $2;
	    my $class = $3;
	    push(@$edges_ptr, "$from_state $to_state $class");

	    if($cnt == 1){
		$$init_ptr = $from_state;
	    }
	    $cnt ++;
	    next;
	}

	print STDERR "wrong fst line: +$line+\n";
    }

    return $cnt;
}

