package BotLib::Drink;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Encode;
use Carp qw (cluck);
use HTTP::Tiny;
use HTML::TokeParser;

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Drink Drink2);

my @MONTH = qw (yanvar fevral mart aprel may iyun iyul avgust sentyabr oktyabr noyabr dekabr);

sub Drink {
	my $r;
	my $ret = 'Не знаю праздников - вджобываю весь день на шахтах, как проклятая.';
	my ($dayNum, $monthNum) = (localtime ())[3, 4];
	my $url = sprintf 'https://kakoysegodnyaprazdnik.ru/baza/%s/%s', $MONTH[$monthNum], $dayNum;

	for (1..3) {
		my $http = HTTP::Tiny->new (timeout => 3);
		$r = $http->get ($url, {'Accept-Charset' => 'utf-8', 'Accept-Language' => 'ru-RU'});

		if ($r->{success}) {
			last;
		}

		sleep 2;
	}

	if ($r->{success}) {
		my $p = HTML::TokeParser->new(\$r->{content});
		my @a;
		my @holyday;

		do {
			$#a = -1;
			@a = $p->get_tag('span'); ## no critic (Variables::RequireLocalizedPunctuationVars)

			if ($#{$a[0]} > 2 && defined $a[0][1]->{itemprop} && $a[0][1]->{itemprop} eq 'text') {
				push @holyday,'* ' . decode ('UTF-8', $p->get_trimmed_text ('/span'));
			}

		} while ($#{$a[0]} > 1);

		if ($#holyday > 0) {
			# cut off something weird, definely not a "holyday"
			$#holyday = $#holyday - 1;
		}

		if ($#holyday > 0) {
			$ret = join "\n", @holyday;
		}
	} else {
		cluck sprintf 'Server return status %s with message: %s', $r->{status}, $r->{reason};
	}

	return $ret;
}

sub drink2 {
	my $r;
	my $ret = 'Не знаю праздников - вджобываю весь день на шахтах, как проклятая.';
	my ($dayNum, $monthNum) = (localtime ())[3, 4];
	my $url = sprintf 'https://calendareveryday.ru/?id=prazdniki', $MONTH[$monthNum], $dayNum;

	for (1..3) {
		my $http = HTTP::Tiny->new (timeout => 3);
		$r = $http->get ($url, {'Accept-Charset' => 'utf-8', 'Accept-Language' => 'ru-RU'});

		if ($r->{success}) {
			last;
		}

		sleep 2;
	}

	if ($r->{success}) {
		my $p = HTML::TokeParser->new(\$r->{content});
		my @a;
		my @holyday;

		do {
			$#a = -1;
			@a = $p->get_tag('span'); ## no critic (Variables::RequireLocalizedPunctuationVars)

			if ($#{$a[0]} > 2 && defined $a[0][1]->{itemprop} && $a[0][1]->{itemprop} eq 'text') {
				push @holyday,'* ' . decode ('UTF-8', $p->get_trimmed_text ('/span'));
			}

		} while ($#{$a[0]} > 1);

		if ($#holyday > 0) {
			# cut off something weird, definely not a "holyday"
			$#holyday = $#holyday - 1;
		}

		if ($#holyday > 0) {
			$ret = join "\n", @holyday;
		}
	} else {
		cluck sprintf 'Server return status %s with message: %s', $r->{status}, $r->{reason};
	}

	return $ret;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
