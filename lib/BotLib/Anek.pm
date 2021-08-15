package BotLib::Anek;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Encode;
use HTML::TokeParser;
use HTTP::Tiny;
use JSON::XS;
use Log::Any qw ($log);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Anek);

sub Anek {
	my $r;
	my $ret = 'Все рассказчики анекдотов отдыхают';
	my $got_anek = 0;

	# time to time anekdot.ru can give valid but unparsable response
	# i've no clue where's err, just fetch another response and try again :)
	for (1..3) {
		for (1..3) {
			my $ua = HTTP::Tiny->new (timeout => 3);
			$r = $ua->get ('https://www.anekdot.ru/rss/randomu.html');

			if ($r->{success}) {
				last;
			}

			sleep 2;
		}

		if ($r->{success}) {
			my $json;
			my $response_text = decode ('UTF-8', $r->{content});
			my @text = split /\n/, $response_text;

			while (my $str = pop @text) {
				if ($str =~ /^var anekdot_texts \= JSON/) {
					$str = (split /JSON\.parse\(\'/, $str, 2)[1];

					if (defined $str && length ($str) > 10) {
						$json = (split /\';\)/, $str, 2)[0];
						last;
					}
				}
			}

			if (defined $json && length ($json) > 10) {
				$json =~ s/\\"/"/g;
				$json =~ s/\\\\"/\\"/g;
				$json = substr $json, 0, -3;

				my $anek = eval { ${JSON::XS->new->relaxed->decode ($json)}[0] };

				if (defined $anek) {
					my @anek = split /<br>/, $anek;
					$ret = join "\n", @anek;

					if (length ($ret) > 1) {
						$got_anek = 1;
					}
				} else {
					$log->warn (sprintf '[WARN] anekdot.ru server returns incorrect json, full response text message: %s', $response_text);
				}
			} else {
				$log->warn (sprintf '[WARN] anekdot.ru server returns unexpected response text: %s', $response_text);
			}

		} else {
			$log->warn (sprintf '[WARN] anekdot.ru server return status %s with message: %s', $r->code, $r->message);
		}

		if ($got_anek) {
			last;
		}
	}

	return $ret;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
