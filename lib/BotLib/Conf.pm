package BotLib::Conf;
# loads config

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use JSON::XS;
use Log::Any qw ($log);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (LoadConf);

sub LoadConf {
	my $c = 'data/config.json';
	open my $CH, '<', $c or die "[FATA] No conf at $c: $OS_ERROR\n";
	my $len = (stat $c) [7];
	my $json;
	my $readlen = read $CH, $json, $len;

	unless ($readlen) {
		close $CH;                                   ## no critic (InputOutput::RequireCheckedSyscalls
		$log->fata ("[FATA] Unable to read $c: $OS_ERROR");
	}

	if ($readlen != $len) {
		close $CH;                                   ## no critic (InputOutput::RequireCheckedSyscalls
		$log->fata ("[FATA] File $c is $len bytes on disk, but we read only $readlen bytes");
	}

	close $CH;                                       ## no critic (InputOutput::RequireCheckedSyscalls
	my $j = JSON::XS->new->utf8->relaxed;
	return $j->decode ($json);
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
