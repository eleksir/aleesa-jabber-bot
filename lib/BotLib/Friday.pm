package BotLib::Friday;
# for friday data stolen from https://raw.githubusercontent.com/isida/vi/master/data/friday.txt

use 5.018; ## no critic (ProhibitImplicitImport)
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Carp qw (croak);
use File::Path qw (make_path);
use Log::Any qw ($log);
use Math::Random::Secure qw (irand);
use SQLite_File ();
use BotLib::Conf qw (LoadConf);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Seed Friday);

my $c = LoadConf ();
my $dir = $c->{friday}->{dir};
my $srcfile = $c->{friday}->{src};
my @dow = qw (monday tuesday wednesday thursday friday saturday sunday);

sub Seed () {
	unless (-d $dir) {
		make_path ($dir)  ||  croak "Unable to create $dir: $OS_ERROR";
	}

	my $friday;

	for (0..$#dow) {
		my $backingfile = sprintf '%s/%s.sqlite', $dir, $dow[$_];

		if (-e $backingfile) {
			unlink $backingfile   ||  croak "Unable to remove $backingfile: $OS_ERROR\n";
		}

		tie @{$friday->[$_]}, 'SQLite_File', $backingfile  ||  croak "Unable to tie to $backingfile: $OS_ERROR\n";
	}

	open (my $fh, '<', $srcfile)  ||  croak "Unable to open $srcfile, $OS_ERROR\n";

	while (readline $fh) {
		unless  (m/ \|\| /xmsg) {
			next;
		}

		chomp ();
		my ($phrase, $days) = split (/ \|\| /);
		my @daylist = split (//, $days);

		foreach my $day (@daylist) {
			unless (defined $day) {
				next ;
			}

			unless ($day =~ /^\d$/) {
				next ;
			}

			if (defined ($phrase) && ($phrase ne '') && ($phrase !~ m/^\s+$/xmsg)) {
				push @{$friday->[$day - 1]}, $phrase;
			}
		}
	}

	close $fh;  ## no critic (InputOutput::RequireCheckedSyscalls, InputOutput::RequireCheckedOpen)

	for (0..$#dow) {
		untie $friday->[$_];
	}

	return;
}

# just return answer
sub Friday () {
	my $today = (localtime (time))[6] - 1;
	my $backingfile = sprintf '%s/%s.sqlite', $dir, $dow[$today];

	tie my @array, 'SQLite_File', $backingfile  ||  do {
		$log->error ("[ERROR] Unable to tie to $backingfile: $OS_ERROR");
		return '';
	};

	my $phrase = $array[irand ($#array - 1)];
	# decode?
	utf8::decode $phrase;
	untie @array;
	return $phrase;
}

1;

# vim: ft=perl noet ai ts=4 sw=4 sts=4:
