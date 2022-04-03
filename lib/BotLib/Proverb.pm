package BotLib::Proverb;
# Any fortune_mod sources are suitable. Text file with "\n%\n" sentence delimeter.

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
use BotLib::Util qw (trim);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Seed Proverb);

my $c = LoadConf ();
my $dir = $c->{proverb}->{dir};
my $srcdir = $c->{proverb}->{srcdir};

sub Seed () {
	unless (-d $dir) {
		make_path ($dir)  ||  croak "Unable to create $dir: $OS_ERROR";
	}

	my $backingfile = sprintf '%s/proverb.sqlite', $dir;

	if (-e $backingfile) {
		unlink $backingfile   ||  croak "Unable to remove $backingfile: $OS_ERROR";
	}

	tie my @proverb, 'SQLite_File', $backingfile  ||  croak "Unable to tie to $backingfile: $OS_ERROR";
	opendir (my $srcdirhandle, $srcdir)  ||  croak "Unable to open $srcdir: $OS_ERROR";

	while (my $proverbfile = readdir ($srcdirhandle)) {
		my $srcfile = sprintf '%s/%s', $srcdir, $proverbfile;

		unless (-e $srcfile) {
			next;
		}

		if ($proverbfile =~ m/^\.+$/) {
			next;
		}

		open (my $fh, '<', $srcfile)  ||  croak "Unable to open $srcfile, $OS_ERROR";

		while (readline $fh) {
			chomp;
			my $str = trim ($_);

			if ($str ne '') {
				push @proverb, $str;
			}
		}

		close $fh;  ## no critic (InputOutput::RequireCheckedSyscalls, InputOutput::RequireCheckedOpen)
	}

	closedir $srcdirhandle;
	untie @proverb;
	return;
}

# just return answer
sub Proverb () {
	my $backingfile = sprintf '%s/proverb.sqlite', $dir;

	tie my @array, 'SQLite_File', $backingfile  ||  do {
		$log->error ("[ERROR] Unable to tie to $backingfile: $OS_ERROR");
		return '';
	};

	my $phrase = $array[irand ($#array + 1)];
	# decode?
	utf8::decode $phrase;
	untie @array;
	return $phrase;
}

1;

# vim: ft=perl noet ai ts=4 sw=4 sts=4:
