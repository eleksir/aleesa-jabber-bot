package BotLib::Fox;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use JSON::XS qw (decode_json);
use HTTP::Tiny;
use Log::Any qw ($log);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Fox);

sub Fox {
	my $r;
	my $ret = 'Нету лисичек, все разбежались.';

	for (1..3) {
		my $http = HTTP::Tiny->new (timeout => 3);
		$r = $http->get ('https://randomfox.ca/floof/');

		if ($r->{success}) {
			last;
		}

		sleep 2;
	}

	if ($r->{success}) {
		my $jfox = eval {
			decode_json ($r->{content})
		};

		unless (defined $jfox) {
			$log->warn ("[WARN] Unable to decode JSON: $EVAL_ERROR");
		} else {
			if ($jfox->{image}) {
				$jfox->{image} =~ s/\\//xmsg;
				$ret = $jfox->{image};
			}
		}
	} else {
		$log->warn (sprintf '[WARN] Server return status %s with message: %s', $r->{status}, $r->{reason});
	}

	return $ret;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
