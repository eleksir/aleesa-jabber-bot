package BotLib::Image;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use BotLib::Image::Flickr qw (FlickrByTags);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Rabbit Owl);

sub Rabbit {
	# rabbit, but bunny
	my $url = FlickrByTags ('animal,bunny');

	if (defined $url) {
		return $url;
	} else {
		return 'Нету кроликов, все разбежались.';
	}
}

sub Owl {
	my $url = FlickrByTags ('bird,owl');

	if (defined $url) {
		return $url;
	} else {
		return 'Нету сов, все разлетелись.';
	}
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
