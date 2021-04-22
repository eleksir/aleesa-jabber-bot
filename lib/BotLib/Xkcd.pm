package BotLib::Xkcd;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use HTTP::Tiny;

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Xkcd);

sub Xkcd {
	my $http = HTTP::Tiny->new (timeout => 5, max_redirect => 0);
	my $location;
	my $status = 400;
	my $c = 0;

	do {
		my $r = $http->get ('https://xkcd.ru/random/');

		if (defined $r->{headers} && defined $r->{headers}->{location} && $r->{headers}->{location} ne '') {
			$location = substr ($r->{headers}->{location}, 1, -1);
			$location = sprintf 'https://xkcd.ru/i/%s_v1.png', $location;
			$r = $http->head ($location);
		}

		$c++;
		$status = $r->{status};
	} while ($c < 3 || $status >= 404);

	if ($status == 200) {
		return $location;
	}

	return 'Комикс-стрип нарисовать не так-то просто :(';
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
