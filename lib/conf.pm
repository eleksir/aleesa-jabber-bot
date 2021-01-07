package conf;
# loads config

use 5.018;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use English qw( -no_match_vars );
use JSON::XS;

use vars qw/$VERSION/;
use Exporter qw(import);
our @EXPORT_OK = qw(loadConf);
$VERSION = '1.0';

sub loadConf {
	my $c = 'data/config.json';
	open my $CH, '<', $c or die "[FATA] No conf at $c: $OS_ERROR\n";
	my $len = (stat $c) [7];
	my $json;
	my $readlen = read $CH, $json, $len;

	unless ($readlen) {
		close $CH;                                   ## no critic (InputOutput::RequireCheckedSyscalls
		die "[FATA] Unable to read $c: $OS_ERROR\n";
	}

	if ($readlen != $len) {
		close $CH;                                   ## no critic (InputOutput::RequireCheckedSyscalls
		die "[FATA] File $c is $len bytes on disk, but we read only $readlen bytes\n";
	}

	close $CH;                                       ## no critic (InputOutput::RequireCheckedSyscalls
	my $j = JSON::XS->new->utf8->relaxed;
	return $j->decode ($json);
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
