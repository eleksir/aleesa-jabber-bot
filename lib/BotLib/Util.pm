package BotLib::Util;

use 5.018; ## no critic (ProhibitImplicitImport)
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Carp qw (cluck);
use Digest::SHA qw (sha1_base64);
use Encode qw (encode_utf8);
use MIME::Base64 qw (encode_base64);
use Text::Fuzzy qw (distance_edits);
use URI::URL qw (url);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (trim urlencode fmatch utf2b64 utf2sha1);

sub trim {
	my $str = shift;

	unless (defined $str) {
		cluck '[ERROR] Str is undefined';
		return '';
	}

	if ($str eq '') {
		return $str;
	}

	$str =~ s/^\s+//u;
	$str =~ s/\s+$//u;

	return $str;
}

sub urlencode {
	my $str = shift;

	unless (defined $str) {
		cluck '[ERROR] Str is undefined';
		return '';
	}

	my $urlobj = url $str;
	return $urlobj->as_string;
}

sub fmatch {
	my $srcphrase = shift;
	my $answer = shift;

	if ((! defined $srcphrase) || (! defined $answer)) {
		if (defined $srcphrase) {
			cluck '[ERROR] Answer undefined';
		} elsif (defined $answer) {
			cluck '[ERROR] Srcphrase undefined';
		} else {
			cluck '[ERROR] Both srcphrase and answer are undefined';
		}

		return 0;
	}

	my ($distance, undef) = distance_edits ($srcphrase, $answer);
	my $srcphraselen = length $srcphrase;
	my $distance_max = int ($srcphraselen - ($srcphraselen * (100 - (90 / ($srcphraselen ** 0.5))) * 0.01));

	if ($distance >= $distance_max) {
		return 0;
	} else {
		return 1;
	}
}

sub utf2b64 {
	my $string = shift;

	unless (defined $string) {
		cluck '[ERROR] String is undefined';
		return sha1_base64 '';
	}

	if ($string eq '') {
		return encode_base64 '';
	}

	my $bytes = encode_utf8 $string;
	return encode_base64 $bytes;
}

sub utf2sha1 {
	my $string = shift;

	unless (defined $string) {
		cluck '[ERROR] String is undefined';
		return sha1_base64 '';
	}

	if ($string eq '') {
		return sha1_base64 '';
	}

	my $bytes = encode_utf8 $string;
	return sha1_base64 $bytes;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
