package friday;
# for friday data stolen from https://raw.githubusercontent.com/isida/vi/master/data/friday.txt

use 5.018;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use English qw( -no_match_vars );
use Carp qw(cluck croak);

use vars qw/$VERSION/;
use Exporter qw(import);
our @EXPORT_OK = qw(seed friday);

$VERSION = '1.0';

use SQLite_File;
use MIME::Base64;
use File::Path qw(mkpath);
use conf qw(loadConf);
use botlib qw(logger);

my $c = loadConf();
my $dir = $c->{friday}->{dir};
my $srcfile = $c->{friday}->{src};
my @dow = qw (monday tuesday wednesday thursday friday saturday sunday);

sub seed () {
	unless (-d $dir) {
		mkpath ($dir)  ||  croak "Unable to create $dir: $OS_ERROR";
	}

	my $friday;

	for (0..$#dow) {
		my $backingfile = sprintf '%s/%s.sqlite', $dir, $dow[$_];

		if (-f $backingfile) {
			unlink $backingfile   ||  croak "Unable to remove $backingfile: $OS_ERROR\n";
		}

		tie @{$friday->[$_]}, 'SQLite_File', $backingfile  ||  croak "Unable to tie to $backingfile: $OS_ERROR\n";
	}

	open (my $fh, '<', $srcfile)  ||  croak "Unable to open $srcfile, $OS_ERROR\n";

	while (readline $fh) {
		next unless  m/ \|\| /xmsg;
		chomp();
		my ($phrase, $days) = split(/ \|\| /);
		my @daylist = split(//, $days);

		foreach my $day (@daylist) {
			next unless (defined $day);
			next unless ($day =~ /^\d$/);
			push @{$friday->[$day - 1]}, $phrase if (defined $phrase && ($phrase ne '') && ($phrase !~ m/^\s+$/xmsg));
		}
	}

	close $fh;  ## no critic (InputOutput::RequireCheckedSyscalls, InputOutput::RequireCheckedOpen)
	for (0..$#dow) { untie $friday->[$_]; }

	return;
}

# just return answer
sub friday () {
	my $today = (localtime(time))[6] - 1;
	my $backingfile = sprintf '%s/%s.sqlite', $dir, $dow[$today];

	tie my @array, 'SQLite_File', $backingfile  ||  do {
		cluck "Unable to tie to $backingfile: $OS_ERROR\n";
		return '';
	};

	my $phrase = $array[int (rand ($#array - 1))];
	# decode?
	utf8::decode $phrase;
	untie @array;
	return $phrase;
}

1;

# vim: ft=perl noet ai ts=4 sw=4 sts=4:
