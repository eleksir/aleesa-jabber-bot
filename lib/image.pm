package image;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use flickr qw (flickr_by_tags);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (rabbit owl);

my $c = loadConf ();
my $dir = $c->{image}->{dir};


sub rabbit {
	# rabbit, but bunny
	my $url = flickr_by_tags ('animal,bunny');

	if (defined $url) {
		return $url;
	} else {
		return 'Нету кроликов, все разбежались.';
	}
}

sub owl {
	my $url = flickr_by_tags ('bird,owl');

	if (defined $url) {
		return $url;
	} else {
		return 'Нету сов, все разлетелись.';
	}
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
