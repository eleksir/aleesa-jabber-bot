package lat;
# famous latin phases taken from https://ru.wikipedia.org/wiki/Список_крылатых_латинских_выражений

use 5.018;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use English qw( -no_match_vars );
use Carp qw(cluck);

use vars qw/$VERSION/;
use Exporter qw(import);
our @EXPORT_OK = qw(train latAnswer);

$VERSION = '1.0';

use Hailo;
use File::Basename qw(dirname);
use File::Path qw(mkpath);
use conf qw(loadConf);
use botlib qw(logger);

my $c = loadConf();
my $brain = $c->{lat}->{brain};

# swallow phrase and return answer
sub train () {
	my $braindir = dirname ($brain);

	unless (-d $braindir) {
		mkpath ($braindir) or do {
			cluck "Unable to create $braindir: $OS_ERROR";
			exit 1;
		};
	}

	my $lat = Hailo->new (
		brain => $brain,
		# in our case mean amount of words in phase is 3
		order => 2
	);

	$lat->train('data/phrases.txt');
	my ($tokens, $expressions) = ($lat->stats())[0,1];
	printf "Total tokens: %s\nTotal expressins: %s\n", $tokens, $expressions;
	$lat->save();
	return;
}

# just return answer
sub latAnswer () {
	my $braindir = dirname ($brain);

	unless (-d $braindir) {
		cluck "No lat module data: $braindir is absent! Train lat first.";
		return '';
	}

	unless (-f $brain) {
		cluck "No lat module data: $brain is absent! Train lat first.";
		return '';
	}

	my $lat = Hailo->new (
		brain => $brain,
		# in our case mean amount of words in phase is 3
		order => 2,
		save_on_exit => 0
	);

	return $lat->reply();
}

1;

# vim: ft=perl noet ai ts=4 sw=4 sts=4:
