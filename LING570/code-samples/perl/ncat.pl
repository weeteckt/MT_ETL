#!/usr/bin/perl

=head1 NAME

ncat.pl -- Write a specified number of lines from STDIN to STDOUT

=head1 SYNOPSIS

ncat.pl [options] [N]

N is the number of lines to read from STDIN. If not specified, STDIN is read until it is exhausted.

=head1 OPTIONS

=over

=item B<help|?>

Show this help message.

=item B<man>

Show the manual page for this script.

=back

=head1 DESCRIPTION

More detailed description here.

=head1 AUTHOR

Your name and email here.

=cut

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

my ($help, $man);

GetOptions('help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(1) if ($help);
pod2usage(-exitstatus => 0, -verbose => 2) if ($man);

# If no command line arguments are specified, n=-1 will make the loop run
# until STDIN is exhausted.
my $n = (scalar(@ARGV) == 0) ? -1 : $ARGV[0];

while (<STDIN>){
	last if (--$n == 0);
	print $_;
}
