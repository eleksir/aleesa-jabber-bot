package BotLib::Image;

use 5.018;  ## no critic (ProhibitImplicitImport)
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use BotLib::Image::Flickr qw (FlickrByTags);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Rabbit Owl Frog Horse Snail);

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

sub Frog {
	# unable to find any one-line ascii art for frog :(
	my $url = FlickrByTags ('frog,toad,amphibian');

	if (defined $url) {
		return $url;
	} else {
		return 'Нету лягушек, все свалили.';
	}
}

sub Horse {
	# unable to find any one-line ascii art for frog :(
	my $url = FlickrByTags ('horse,equine,mammal');

	if (defined $url) {
		return $url;
	} else {
		return 'Нету коняшек, все разбежались.';
	}
}

sub Snail {
	# unable to find any one-line ascii art for frog :(
	my $url = FlickrByTags ('snail,slug');

	if (defined $url) {
		return $url;
	} else {
		return 'Нету улиток, все расползлись.';
	}
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
