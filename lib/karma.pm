package karma;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use English qw( -no_match_vars );
use Digest::SHA qw(sha1_base64);
use DB_File;
use Carp qw(cluck);

use vars qw/$VERSION/;
use Exporter qw(import);
our @EXPORT_OK = qw(karmaSet karmaGet);

$VERSION = '1.0';

use conf qw(loadConf);

my $c = loadConf();
my $karmadir = $c->{karma}->{dir};
my $max = 5;

# swallow phrase and return answer
sub karmaSet (@) {
	my $chatid = shift;
	my $phrase = shift;
	my $action = shift;
	my $score = 0;
	# sha1* does not understand utf8, so explicitly construct string cost of decimal numbers only 
	my $karmafile = join ('', unpack ('C*', $chatid));
	$karmafile = sha1_base64 ($karmafile);
	# sha1 string can contain slashes, so make a bit longer string consist of only decimal numbers
	$karmafile = join ('', unpack ('C*', $karmafile));
	$karmafile = sprintf '%s/%s.db', $karmadir, $karmafile;

	if (($phrase eq '') || ($phrase =~ /^ +$/)) {
		$phrase = '';
	}

	# init hash, store phrase and score
	tie my %karma, 'DB_File', $karmafile || do {
		cluck "Something nasty happen when cachedata ties to its data: $OS_ERROR";
		return sprintf 'Карма %s составляет 0', $phrase;
	};

	# bdb does not understand utf8, so tied hash too, we do not want store original phrase anyway
	my $sha1_phrase = sha1_base64 (join ('', unpack ('C*', $phrase)));

	if (defined $karma{$sha1_phrase}) {
		if ($action eq '++') {
			$score = $karma{$sha1_phrase} + 1;
			$karma{$sha1_phrase} = $score;
		} else {
			$score = $karma{$sha1_phrase} - 1;
			$karma{$sha1_phrase} = $score;
		}
	} else {
		if ($action eq '++') {
			$karma{$sha1_phrase} = 1;
			$score = 1;
		} else {
			$karma{$sha1_phrase} = -1;
			$score = -1;
		}
	}

	untie %karma;

	if ($score < -1 && (($score % (0 - $max)) + 1) == 0) {
		if ($phrase eq '') {
			return sprintf 'Зарегистрировано пробитие дна, карма пустоты составляет %d', $score;
		} else {
			return sprintf 'Зарегистрировано пробитие дна, карма %s составляет %d', $phrase, $score;
		}
	} else {
		if ($phrase eq '') {
			return sprintf 'Карма пустоты составляет %d', $score;
		} else {
			return sprintf 'Карма %s составляет %d', $phrase, $score;
		}
	}
}

# just return answer
sub karmaGet (@) {
	my $chatid = shift;
	my $phrase = shift;
	# sha1* does not understand utf8, so explicitly construct string cost of decimal numbers only 
	my $karmafile = join ('', unpack ('C*', $chatid));
	$karmafile = sha1_base64 ($karmafile);
	# sha1 string can contain slashes, so make a bit longer string consist of only decimal numbers
	$karmafile = join ('', unpack ('C*', $karmafile));
	$karmafile = sprintf '%s/%s.db', $karmadir, $karmafile;

	if (($phrase eq '') || ($phrase =~ /^ +$/)) {
		$phrase = '';
	}

	# init hash, store phrase and score
	tie my %karma, 'DB_File', $karmafile || do {
		cluck "Something nasty happen when karma ties to its data: $OS_ERROR";
		return sprintf 'Карма %s составляет 0', $phrase;
	};

	# bdb does not understand utf8, so tied hash too, we do not want store original phrase anyway
	my $sha1_phrase = sha1_base64 (join ('', unpack ('C*', $phrase)));
	my $score = $karma{$sha1_phrase};
	untie %karma;

	unless (defined $score) {
		$score = 0;
	}

	if ($phrase eq '') {
		return sprintf 'Карма пустоты составляет %d', $score;
	} else {
		return sprintf 'Карма %s составляет %d', $phrase, $score;
	}
}

1;

# vim: ft=perl noet ai ts=4 sw=4 sts=4:
