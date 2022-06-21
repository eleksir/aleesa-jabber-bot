package BotLib::Drink;

use 5.018; ## no critic (ProhibitImplicitImport)
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Encode qw (decode);
use CHI ();
use CHI::Driver::BerkeleyDB ();
use DateTime ();
use HTTP::Tiny ();
use HTML::TokeParser ();
use Log::Any qw ($log);
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
		my $url = 'https://prazdniki-segodnya.ru/';
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
			my $p = HTML::TokeParser->new (\$r->{content});
			my @a;
			my %holiday;

			do {
				$#a = -1;
				@a = $p->get_tag ('div'); ## no critic (Variables::RequireLocalizedPunctuationVars)

				if ($#{$a[0]} > 2) {
					my @shitty_array = $a[0];
					foreach my $item (@shitty_array) {
						if (ref $item) {
							foreach my $item1 (@{$item}) {
								my %h = eval { %{$item1} };

								if (defined ($h{class}) && $h{class} eq 'list-group-item text-monospace') {
									$holiday {'* ' . decode ('UTF-8', $p->get_trimmed_text ('/div'))} = 1;
								}
							}
						}
					}
				}
			} while ($#{$a[0]} > 1);

			if (int (keys %holiday) > 0) {
				$ret = join "\n", sort (keys %holiday);
			}
		} else {
			$log->warn (sprintf '[WARN] Server return status %s with message: %s', $r->{status}, $r->{reason});
			return undef;
		}

		return $ret;
	};

	my $cache = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $c->{cachedir},
		namespace => __PACKAGE__,
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
		second => 0,
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
		$drinkCallBack,
	);

	if (defined $res && $res ne '') {
		return $res;
	} else {
		return 'Не знаю праздников - вджобываю весь день на шахтах, как проклятая.';
	}
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
