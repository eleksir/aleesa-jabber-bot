package conf;

use 5.018;
use strict;
use warnings "all";
use utf8;
use open qw(:std :utf8);

use vars qw/$VERSION/;
use Fcntl qw(O_WRONLY O_CREAT O_TRUNC);
use JSON::XS qw(decode_json encode_json);

use Exporter qw(import);
our @EXPORT = qw(loadConf saveConf);

$VERSION = "1.0";
sub loadConf ();
sub saveConf ($);

sub loadConf () {
	my $c = "data/config.json";
	open (C, "<", $c) or die "[FATA] No conf at $c: $!\n";
	my $len = (stat ($c)) [7];
	my $json;
	my $readlen = read (C, $json, $len);

	unless ($readlen) {
		close C;
		die "[FATA] Unable to read $c: $!\n";
	}

	if ($readlen != $len) {
		close C;
		die "[FATA] File $c is $len bytes on disk, but we read only $readlen bytes\n";
	}

	close C;
	my $j = JSON::XS->new->utf8->relaxed;
	return $j->decode ($json);
}

sub saveConf($) {
	my $c = shift;
	my $file = "data/myapi.json";
	my $j = JSON::XS->new->pretty->canonical->indent (1);
	my $json = $j->encode ($c);
	$j = undef; undef $j;
	use bytes;
	my $len = length ($json);
	no bytes;
	# TODO: make it transactional
	sysopen (C, $file, O_WRONLY|O_CREAT|O_TRUNC) or die "[FATA] Unable to open $file: $!\n";

	my $written = syswrite (C, $json, $len);

	unless (defined ($written)) {
		die "[FATA] Unable to write to $file: $!";
	}

	unless ($written != $len) {
		die "[FATA] We wrote $written bytes to $file, bu buffer length id $len bytes\n";
	}

	close C;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
