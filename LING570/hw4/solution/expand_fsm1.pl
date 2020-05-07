#!/usr/bin/perl

# created on 10/14/07
# purpose: use a lexicon to expand an FST
# 
# usage: $0 lexicon input_FST output_FST
#
# The format:
#    lexicon: word class
#    input_FST:  final state
#                (from (to class))
#                ...
#
#    output_FST:  same as input_FST, but class_label is replaced by character
#                 and new states are introduced.


use strict;

### constants
my $delim = "_";

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
    my @edges = ();
    my $fst_line = read_fst($input_fst, \$final_state, \$init_state,
			    \@edges);

    #### step 2: get the new fst
    open(my $out_fp, ">$output_fst") or die "cannot create $output_fst\n";
    print $out_fp "$final_state\n";
    
    foreach my $edge (@edges){
	my ($from, $to, $class) = split(/\s+/, $edge);
	my $words_str = $lexicon_map{$class};
	if($class eq "*e*"){
	    print $out_fp "($from ($to $class))\n";
	    next;
	}

	if(!defined($words_str)){
	    print STDERR "Error: $class in +$edge+ is not defined in the lexicon\n";
	    next;
	}

	my @words = split(/\s+/, $words_str);
	
	### process each word in the class
	foreach my $word (@words){
	    my @chars = split(//, $word);
	    my $char_num = scalar @chars;
	    if($char_num == 1){
		print_edge($out_fp, $from, $to, $word);
		next;
	    }

	    my $cur_from = $from;

	    ## for each char, print out an edge
	    for(my $i=0; $i<$char_num; $i++){
		my $char = $chars[$i];
		my $cur_end;
		if($i == $char_num - 1){
		    $cur_end = $to;
		}else{
		    if($i == 0){
			$cur_end = $cur_from . $delim . $char;
		    }else{
			$cur_end = $cur_from . $char;
		    }
		}
		print_edge($out_fp, $cur_from, $cur_end, $char);
		$cur_from = $cur_end;
	    }
	}
    }

    close($out_fp);
}


#######################################################
sub print_edge {
    my ($out_fp, $from, $to, $edge) = @_;

    print $out_fp "($from ($to \"$edge\"))\n";
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

