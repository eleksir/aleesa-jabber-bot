package karma;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Carp qw (carp);
use DB_File;
use File::Path qw (make_path);
use conf qw (loadConf);
use util qw (utf2sha1 trim);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (karmaSet karmaGet);

my $c = loadConf ();
my $karmadir = $c->{karma}->{dir};
my $max = 5;

# swallow phrase and return answer
sub karmaSet (@) {
	my $chatid = shift;
	my $phrase = shift;
	my $action = shift;
	$phrase = trim $phrase;
	my $score = 0;
	# sha1* does not understand utf8, so explicitly construct string cost of decimal numbers only 
	my $karmafile = utf2sha1 $chatid;
	$karmafile =~ s/\//-/xmsg;
	$karmafile = sprintf '%s/%s.db', $karmadir, $karmafile;

	unless (-d $karmadir) {
		make_path ($karmadir) or do {
			carp "Unable to create $karmadir: $OS_ERROR";
			return sprintf 'Карма %s составляет 0', $phrase;
		};
	}

	# init hash, store phrase and score
	tie my %karma, 'DB_File', $karmafile || do {
		carp "[ERROR] Something nasty happen when karma ties to its data: $OS_ERROR";
		return sprintf 'Карма %s составляет 0', $phrase;
	};

	# bdb does not understand utf8, so tied hash too, we do not want store original phrase anyway
	my $sha1_phrase = utf2sha1 $phrase;

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
	$phrase = trim $phrase;
	my $karmafile = utf2sha1 $chatid;
	$karmafile =~ s/\//-/xmsg;
	$karmafile = sprintf '%s/%s.db', $karmadir, $karmafile;

	unless (-d $karmadir) {
		make_path ($karmadir) or do {
			carp "Unable to create $karmadir: $OS_ERROR";
			return sprintf 'Карма %s составляет 0', $phrase;
		};
	}

	# init hash, store phrase and score
	tie my %karma, 'DB_File', $karmafile || do {
		carp "[ERROR] Something nasty happen when karma ties to its data: $OS_ERROR";
		return sprintf 'Карма %s составляет 0', $phrase;
	};

	my $sha1_phrase = utf2sha1 $phrase;
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
