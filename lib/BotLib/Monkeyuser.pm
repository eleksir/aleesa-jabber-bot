package BotLib::Monkeyuser;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use HTTP::Tiny;
use HTML::TokeParser;
use Log::Any qw ($log);
use Math::Random::Secure qw (irand);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Monkeyuser);

sub Monkeyuser {
	my $r;
	my $ret = 'Нету Monkey User-ов, они все спрятались.';
	my @link;

	for (1..3) {
		my $http = HTTP::Tiny->new (timeout => 3);
		$r = $http->get ('https://www.monkeyuser.com/toc/');

		if ($r->{success}) {
			last;
		}

		sleep 2;
	}

	if ($r->{success}) {
		my $p = HTML::TokeParser->new(\$r->{content});
		my @a;

		do {
			$#a = -1;
			@a = $p->get_tag ('a'); ## no critic (Variables::RequireLocalizedPunctuationVars)

			if (defined $a[0][1]->{class} && $a[0][1]->{class} eq 'lazyload small-image') {
				if (defined $a[0][1]->{'data-src'} && ($a[0][1]->{'data-src'} !~ /adlitteram/)) {
					push @link, $a[0][1]->{'data-src'};
				}
			}

		} while ($#{$a[0]} > 1);

		if ($#link > 0) {
			$ret = sprintf 'https://www.monkeyuser.com%s', $link[irand (1 + $#link)];
		}
	} else {
		$log->warn (sprintf '[WARN] Monkeyuser server return status %s with message: %s', $r->{status}, $r->{reason});
	}

	return $ret;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
