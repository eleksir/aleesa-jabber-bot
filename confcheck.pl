#!/usr/bin/perl

use 5.018;
use strict;
use warnings "all";
use utf8;
use open qw(:std :utf8);

use lib ("./lib", "./vendor_perl", "./vendor_perl/lib/perl5");

use JSON::PP;

my $c = "data/config.json";
open (C, "<", $c) or die "No conf at $c: $!\n";
my $len = (stat ($c)) [7];
my $json;
my $readlen = read (C, $json, $len);

unless ($readlen) {
	close C;
	die "Unable to read $c: $!\n";
}

if ($readlen != $len) {
	close C;
	die "File $c is $len bytes on disk, but we read only $readlen bytes\n";
}

close C;
$c = decode_json ($json);

my $j = JSON::PP->new->pretty->canonical->indent_length (4);
print $j->encode ($c);

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
