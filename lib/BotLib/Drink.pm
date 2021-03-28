package BotLib::Drink;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Encode;
use Carp qw (cluck);
use CHI;
use CHI::Driver::BerkeleyDB;
use DateTime;
use HTTP::Tiny;
use HTML::TokeParser;
use POSIX qw (strftime);
use BotLib::Conf qw (LoadConf);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Drink);

my @MONTH = qw (yanvar fevral mart aprel may iyun iyul avgust sentyabr oktyabr noyabr dekabr);
my $c = LoadConf ();

sub Drink {
	my $drinkCallBack = sub {
		my $ret;
		my ($dayNum, $monthNum) = (localtime ())[3, 4];
		my $url = sprintf 'https://kakoysegodnyaprazdnik.ru/baza/%s/%s', $MONTH[$monthNum], $dayNum;
		my $r;

		for (1..3) {
			my $http = HTTP::Tiny->new (timeout => 3);
			$r = $http->get ($url, {'Accept-Charset' => 'utf-8', 'Accept-Language' => 'ru-RU'});

			if ($r->{success}) {
				last;
			}

			sleep 2;
		}

		if ($r->{success}) {
			# TODO: Handle unexpected content
			my $p = HTML::TokeParser->new (\$r->{content});
			my @a;
			my @holiday;

			do {
				$#a = -1;
				@a = $p->get_tag ('span'); ## no critic (Variables::RequireLocalizedPunctuationVars)

				if ($#{$a[0]} > 2 && defined $a[0][1]->{itemprop} && $a[0][1]->{itemprop} eq 'text') {
					push @holiday,'* ' . decode ('UTF-8', $p->get_trimmed_text ('/span'));
				}

			} while ($#{$a[0]} > 1);

			if ($#holiday > 0) {
				# cut off something weird, definely not a "holyday"
				$#holiday = $#holiday - 1;
			}

			if ($#holiday > 0) {
				$ret = join "\n", @holiday;
			}
		} else {
			cluck sprintf 'Server return status %s with message: %s', $r->{status}, $r->{reason};
			return undef;
		}

		return $ret;
	};

	my $cache = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $c->{cachedir},
		namespace => __PACKAGE__
	);

	# Those POSIX assholes just forgot to add unix timestamps without TZ offset, so...
	my ($mday, $mon, $year) = (gmtime ())[3, 4, 5];
	my $offset = strftime ('%z', gmtime ());
	my $offsetMinutes = (substr $offset, -2) * 60;
	my $offsetHours = (substr $offset, 1, 2) * 60 * 60;
	my $offsetSign;

	if ((substr $offset, 0, 1) eq '+') {
		$offsetSign = 1;
	}

	my $expirationDate = DateTime->new (
		year => $year + 1900,
		month => $mon + 1,
		day => $mday,
		hour => 0,
		minute => 0,
		second => 0
	)->add (days => 1)->strftime ('%s');

	if ((substr $offset, 0, 1) eq '+') {
		$expirationDate = $expirationDate - $offsetHours - $offsetMinutes;
	} else {
		$expirationDate = $expirationDate + $offsetHours + $offsetMinutes;
	}

	# Okay, now we have correct unix timestamp, heh
	my $res = $cache->compute (
		'Holiday',
		{ expires_at => $expirationDate },
		$drinkCallBack
	);

	if (defined $res && $res ne '') {
		return $res;
	} else {
		return 'Не знаю праздников - вджобываю весь день на шахтах, как проклятая.';
	}
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
