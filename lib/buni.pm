package buni;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Carp qw (cluck);
use HTTP::Tiny;
use HTML::TokeParser;

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (buni);

sub buni {
	my $r;
	my $ret = 'Нету Buni';

	for (1..3) {
		my $http = HTTP::Tiny->new (timeout => 3);
		$r = $http->get ('http://www.bunicomic.com/?random&nocache=1');

		if ($r->{success}) {
			last;
		}

		sleep 2;
	}

	if ($r->{success}) {
		my $p = HTML::TokeParser->new(\$r->{content});
		my @a;

		# additional {} required in order "last" to work properly :)
		{
			do {
				$#a = -1;
				@a = $p->get_tag("meta");

				if (defined $a[0][1]->{property} && $a[0][1]->{property} eq 'og:image') {
					$ret = $a[0][1]->{content};
					last;
				}

			} while ($#{$a[0]} > 1);
		}
	} else {
		cluck sprintf 'Server return status %s with message: %s', $r->{status}, $r->{reason};
	}

	return $ret;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
