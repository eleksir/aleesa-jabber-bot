package BotLib::Image::Flickr;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Carp qw (cluck);
use Digest::HMAC_SHA1 qw (hmac_sha1);
use File::Path qw (make_path);
use JSON::XS;
use HTTP::Tiny;
use Math::Random::Secure qw (irand);
use MIME::Base64;
use SQLite_File;
use URI::Encode::XS qw (uri_encode);

use BotLib::Conf qw (LoadConf);
use BotLib::Util qw (urlencode);

use Data::Dumper;

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (FlickrInit FlickrByTags FlickrByText FlickrTestLogin);

my $c = LoadConf ();
my $dir = $c->{image}->{dir};

my $flickr_consumer_key      = $c->{image}->{flickr}->{consumer_key};
my $flickr_consumer_secret   = $c->{image}->{flickr}->{consumer_secret};
my $flickr_verifier          = $c->{image}->{flickr}->{verifier};
my $flickr_request_token_url = 'https://www.flickr.com/services/oauth/request_token';
my $flickr_authorization_url = 'https://www.flickr.com/services/oauth/authorize';
my $flickr_access_token_url  = 'https://www.flickr.com/services/oauth/access_token';
my $flickr_callback_url      = 'http://www.example.com';
my $flickr_api_url           = 'https://www.flickr.com/services/rest/';

sub mknonce {
	# make random number, 8 symbols in length
	my $nonce = sprintf '%08d', irand (99999999);
	return $nonce;
}

sub flickerSignReq {
	my %p = @_;
	my $string;
	my $hmac;

	if ($p{type} eq 'request_token') {
		my @parameters;
		delete $p{type};
		push @parameters, 'oauth_signature_method=HMAC-SHA1';
		push @parameters, 'oauth_version=1.0';
		push @parameters, sprintf 'oauth_callback=%s', uri_encode ($flickr_callback_url);
		push @parameters, sprintf 'oauth_consumer_key=%s', $flickr_consumer_key;

		foreach my $param (keys %p) {
			push @parameters, sprintf ('%s=%s', $param, $p{$param});
		}

		$string = sprintf 'GET&%s&', uri_encode ($flickr_request_token_url);
		$string .= uri_encode (join '&', sort (@parameters));
		# Thanks to twitter api dev portal, they explain this particular case: while we requesting this token
		# we do not yet know access_token secret, so we just omit it in this signature
		# https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
		$hmac = Digest::HMAC_SHA1->new (sprintf '%s&', uri_encode ($flickr_consumer_secret));
	} elsif ($p{type} eq 'access_token') {
		my @parameters;
		my $flickr_request_token_secret = $p{oauth_token_secret};
		delete $p{oauth_token_secret};
		delete $p{type};
		push @parameters, 'oauth_signature_method=HMAC-SHA1';
		push @parameters, 'oauth_version=1.0';
		push @parameters, sprintf 'oauth_consumer_key=%s', $flickr_consumer_key;

		foreach my $param (keys %p) {
			push @parameters, sprintf ('%s=%s', $param, $p{$param});
		}

		$string = sprintf 'GET&%s&', uri_encode ($flickr_access_token_url);
		$string .= uri_encode (join '&', sort (@parameters));
		$hmac = Digest::HMAC_SHA1->new (sprintf '%s&%s', uri_encode ($flickr_consumer_secret), uri_encode ($flickr_request_token_secret));
	} elsif ($p{type} eq 'test_login' || $p{type} eq 'search_text' ||  $p{type} eq 'search_tags') {
		my @parameters;
		my $flickr_request_token_secret = $p{oauth_token_secret};
		delete $p{oauth_token_secret};
		delete $p{type};

		foreach my $param (keys %p) {
			push @parameters, sprintf ('%s=%s', $param, $p{$param});
		}

		$string = sprintf 'GET&%s&', uri_encode ($flickr_api_url);
		$string .= uri_encode (join '&', sort (@parameters));
		$hmac = Digest::HMAC_SHA1->new (sprintf '%s&%s', uri_encode ($flickr_consumer_secret), uri_encode ($flickr_request_token_secret));
	}

	$hmac->add ($string);
	return encode_base64 ($hmac->digest, '');
}

sub flickrRequestToken {
	my $oauth_timestamp = time ();
	my $oauth_nonce = mknonce ();

	my $oauth_signature = flickerSignReq (
		type => 'request_token',
		oauth_timestamp => $oauth_timestamp,
		oauth_nonce => $oauth_nonce
	);

	my $url = $flickr_request_token_url . sprintf (
		'?oauth_nonce=%s&oauth_timestamp=%s&oauth_consumer_key=%s&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&&oauth_signature=%s&oauth_callback=%s',
		$oauth_nonce,
		$oauth_timestamp,
		$flickr_consumer_key,
		uri_encode ($oauth_signature),
		uri_encode ($flickr_callback_url)
	);

	my $http = HTTP::Tiny->new (timeout => 5);
	my $r = $http->get ($url);
	my %params;

	if ($r->{success}) {
		# they ignore format=json, so...
		%params = map {split /=/} split /&/, $r->{content};
	} else {
		say "Something bad returns from flickr api: $r->{status} $r->{content}"; ## no critic (InputOutput::RequireCheckedSyscalls)
	}

	return %params;
}

sub flickrAccessToken {
	my $flickr_request_token = shift;
	my $flickr_request_token_secret = shift;
	my $flickr_verifier = shift; ## no critic (Variables::ProhibitReusedNames)

	my $oauth_timestamp = time ();
	my $oauth_nonce = mknonce ();

	my $oauth_signature = flickerSignReq (
		type => 'access_token',
		oauth_timestamp => $oauth_timestamp,
		oauth_nonce => $oauth_nonce,
		oauth_token => $flickr_request_token,
		oauth_token_secret => $flickr_request_token_secret,
		oauth_verifier => $flickr_verifier
	);

	my $url = $flickr_access_token_url . sprintf (
		'?oauth_nonce=%s&oauth_timestamp=%s&oauth_verifier=%s&oauth_consumer_key=%s&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=%s&oauth_signature=%s',
		$oauth_nonce,
		$oauth_timestamp,
		$flickr_verifier,
		$flickr_consumer_key,
		$flickr_request_token,
		uri_encode ($oauth_signature)
	);

	my $http = HTTP::Tiny->new (timeout => 5);
	my $r = $http->get ($url);
	my %params;

	if ($r->{success}) {
		# they ignore format=json
		%params = map {split /=/} split /&/, $r->{content};
	} else {
		say "Something bad returns from flickr api: $r->{status} $r->{content}"; ## no critic (InputOutput::RequireCheckedSyscalls)
	}

	return %params;
}

sub flickrAuthorization {
	my $flickr_request_token = shift;

	my $url = $flickr_authorization_url . sprintf (
		'?oauth_token=%s&perms=read',
		$flickr_request_token,
	);

	my $http = HTTP::Tiny->new (timeout => 5);
	my $r = $http->get ($url);

	if ($r->{success}) {
		return $r->{url};
	} else {
		say "Something went wrong: $r->{status} $r->{content}"; ## no critic (InputOutput::RequireCheckedSyscalls)
		return;
	}
}

sub flickrTestLogin {
	my $flickr_access_token = shift;
	my $flickr_access_token_secret = shift;

	my $oauth_timestamp = time ();
	my $oauth_nonce = mknonce ();

	my $oauth_signature = flickerSignReq (
		nojsoncallback => 1,
		oauth_nonce => $oauth_nonce,
		format => 'json',
		oauth_consumer_key => $flickr_consumer_key,
		oauth_timestamp => $oauth_timestamp,
		type => 'test_login',
		method => 'flickr.test.login',
		oauth_token => $flickr_access_token,
		oauth_token_secret => $flickr_access_token_secret,
		oauth_signature_method => 'HMAC-SHA1',
		oauth_version => '1.0'
	);

	my $url = $flickr_api_url . sprintf (
		'?nojsoncallback=1&oauth_nonce=%s&format=json&oauth_consumer_key=%s&oauth_timestamp=%s&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=%s&oauth_signature=%s&method=flickr.test.login',
		$oauth_nonce,
		$flickr_consumer_key,
		$oauth_timestamp,
		$flickr_access_token,
		uri_encode ($oauth_signature)
	);

	my $http = HTTP::Tiny->new (timeout => 5);
	my $r = $http->get ($url);

	if ($r->{success}) {
		my $response = eval {
			my $j = JSON::XS->new->utf8->relaxed;
			return $j->decode ($r->{content});
		};

		if (defined $response) {
			say Dumper $response; ## no critic (InputOutput::RequireCheckedSyscalls)
			return 1;
		} else {
			say "Flickr api returns incorrect json: $r->{content}"; ## no critic (InputOutput::RequireCheckedSyscalls)
			return 0;
		}
	} else {
		say "HTTP status code not 200: $r->{status}, $r>{contenr}"; ## no critic (InputOutput::RequireCheckedSyscalls)
		return 0;
	}
}

sub flickrSearchByText {
	my $flickr_access_token = shift;
	my $flickr_access_token_secret = shift;
	my $text = shift;

	my $oauth_timestamp = time ();
	my $oauth_nonce = mknonce ();

	my $oauth_signature = flickerSignReq (
		nojsoncallback => 1,
		oauth_nonce => $oauth_nonce,
		format => 'json',
		oauth_consumer_key => $flickr_consumer_key,
		oauth_timestamp => $oauth_timestamp,
		type => 'search_text',
		content_type => 1,
		media => 'photos',
		method => 'flickr.photos.search',
		text => $text,
		per_page => 1,
		oauth_token => $flickr_access_token,
		oauth_token_secret => $flickr_access_token_secret,
		oauth_signature_method => 'HMAC-SHA1',
		oauth_version => '1.0'
	);

	my $url = $flickr_api_url . sprintf (
		'?nojsoncallback=1&oauth_nonce=%s&format=json&oauth_consumer_key=%s&oauth_timestamp=%s&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=%s&oauth_signature=%s&method=flickr.photos.search&content_type=1&media=photos&per_page=1&text=%s',
		$oauth_nonce,
		$flickr_consumer_key,
		$oauth_timestamp,
		$flickr_access_token,
		uri_encode ($oauth_signature),
		uri_encode ($text)
	);

	my $http = HTTP::Tiny->new (timeout => 5);
	my $r = $http->get ($url);

	if ($r->{success}) {
		my $response = eval {
			my $j = JSON::XS->new->utf8->relaxed;
			return $j->decode ($r->{content});
		};

		if (defined $response) {
			# lets make another query, this time with random picture
			my $page = irand int ($response->{photos}->{total} / 500);
			$oauth_timestamp = time ();
			$oauth_nonce = mknonce ();
			$oauth_signature = flickerSignReq (
				nojsoncallback => 1,
				oauth_nonce => $oauth_nonce,
				format => 'json',
				oauth_consumer_key => $flickr_consumer_key,
				oauth_timestamp => $oauth_timestamp,
				type => 'search_text',
				content_type => 1,
				media => 'photos',
				method => 'flickr.photos.search',
				text => $text,
				page => $page,
				per_page => 500,
				oauth_token => $flickr_access_token,
				oauth_token_secret => $flickr_access_token_secret,
				oauth_signature_method => 'HMAC-SHA1',
				oauth_version => '1.0'
			);

			$url = $flickr_api_url . sprintf (
				'?nojsoncallback=1&oauth_nonce=%s&format=json&oauth_consumer_key=%s&oauth_timestamp=%s&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=%s&oauth_signature=%s&method=flickr.photos.search&content_type=1&media=photos&per_page=500&page=%d&text=%s',
				$oauth_nonce,
				$flickr_consumer_key,
				$oauth_timestamp,
				$flickr_access_token,
				uri_encode ($oauth_signature),
				$page,
				uri_encode ($text)
			);

			$http = HTTP::Tiny->new (timeout => 5);
			$r = $http->get ($url);

			if ($r->{success}) {
				$response = eval {
					my $j = JSON::XS->new->utf8->relaxed;
					return $j->decode ($r->{content});
				};

				if (defined $response) {
					return $response;
				} else {
					cluck "Flickr api returns incorrect json: $r->{content}";
					return undef;
				}
			} else {
				cluck "Flickr api returns incorrect json: $r->{content}";
				return undef;
			}
		} else {
			cluck "Flickr api returns incorrect json: $r->{content}";
			return undef;
		}
	} else {
		cluck "HTTP status code not 200: $r->{status}, $r->{content}";
		return undef;
	}
}

sub flickrSearchByTags {
	my $flickr_access_token = shift;
	my $flickr_access_token_secret = shift;
	my $tags = shift;

	my $oauth_timestamp = time ();
	my $oauth_nonce = mknonce ();

	my $oauth_signature = flickerSignReq (
		nojsoncallback => 1,
		oauth_nonce => $oauth_nonce,
		format => 'json',
		oauth_consumer_key => $flickr_consumer_key,
		oauth_timestamp => $oauth_timestamp,
		type => 'search_tags',
		content_type => 1,
		media => 'photos',
		method => 'flickr.photos.search',
		tags => $tags,
		per_page => 1,
		oauth_token => $flickr_access_token,
		oauth_token_secret => $flickr_access_token_secret,
		oauth_signature_method => 'HMAC-SHA1',
		oauth_version => '1.0'
	);

	my $url = $flickr_api_url . sprintf (
		'?nojsoncallback=1&oauth_nonce=%s&format=json&oauth_consumer_key=%s&oauth_timestamp=%s&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=%s&oauth_signature=%s&method=flickr.photos.search&content_type=1&media=photos&per_page=1&tags=%s&tag_mode=all',
		$oauth_nonce,
		$flickr_consumer_key,
		$oauth_timestamp,
		$flickr_access_token,
		uri_encode ($oauth_signature),
		uri_encode ($tags)
	);

	my $http = HTTP::Tiny->new (timeout => 5);
	my $r = $http->get ($url);

	if ($r->{success}) {
		my $response = eval {
			my $j = JSON::XS->new->utf8->relaxed;
			return $j->decode ($r->{content});
		};

		if (defined $response) {
			# lets make another query, this time with random picture
			my $page = irand int ($response->{photos}->{total} / 500);
			$oauth_timestamp = time ();
			$oauth_nonce = mknonce ();
			$oauth_signature = flickerSignReq (
				nojsoncallback => 1,
				oauth_nonce => $oauth_nonce,
				format => 'json',
				oauth_consumer_key => $flickr_consumer_key,
				oauth_timestamp => $oauth_timestamp,
				type => 'search_text',
				content_type => 1,
				media => 'photos',
				method => 'flickr.photos.search',
				tags => $tags,
				page => $page,
				per_page => 500,
				oauth_token => $flickr_access_token,
				oauth_token_secret => $flickr_access_token_secret,
				oauth_signature_method => 'HMAC-SHA1',
				oauth_version => '1.0'
			);

			$url = $flickr_api_url . sprintf (
				'?nojsoncallback=1&oauth_nonce=%s&format=json&oauth_consumer_key=%s&oauth_timestamp=%s&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=%s&oauth_signature=%s&method=flickr.photos.search&content_type=1&media=photos&per_page=500&page=%d&tags=%s&tag_mode=all',
				$oauth_nonce,
				$flickr_consumer_key,
				$oauth_timestamp,
				$flickr_access_token,
				uri_encode ($oauth_signature),
				$page,
				uri_encode ($tags)
			);

			$http = HTTP::Tiny->new (timeout => 5);
			$r = $http->get ($url);

			if ($r->{success}) {
				$response = eval {
					my $j = JSON::XS->new->utf8->relaxed;
					return $j->decode ($r->{content});
				};

				if (defined $response) {
					return $response;
				} else {
					cluck "Flickr api returns incorrect json: $r->{content}";
					return undef;
				}
			} else {
				cluck "Flickr api returns incorrect json: $r->{content}";
				return undef;
			}
		} else {
			cluck "Flickr api returns incorrect json: $r->{content}";
			return undef;
		}
	} else {
		cluck "HTTP status code not 200: $r->{status}, $r>{contenr}";
		return undef;
	}
}

sub FlickrInit {
	my $backingfile = sprintf '%s/secrets.sqlite', $dir;

	unless (-d $dir) {
		make_path ($dir) or do {
			say "Unable to create $dir: $OS_ERROR"; ## no critic (InputOutput::RequireCheckedSyscalls)
			return 0;
		};
	}

	tie my %secret, 'SQLite_File', $backingfile  ||  do {
		say "[ERROR] Unable to tie to $backingfile: $OS_ERROR"; ## no critic (InputOutput::RequireCheckedSyscalls)
		return 0;
	};

	if (defined $flickr_verifier && $flickr_verifier) {
		my $flickr_request_token = $secret{flickr_request_token};
		my $flickr_request_token_secret = $secret{flickr_request_token_secret};

		unless (defined $flickr_request_token || defined $flickr_request_token_secret) {
			say "Looks like there is no request token or request token secret in $backingfile"; ## no critic (InputOutput::RequireCheckedSyscalls)
			say 'Please remove verifier settings from config.json and run this script again';   ## no critic (InputOutput::RequireCheckedSyscalls)
			untie %secret;
			return 0;
		}

		my %accessToken = flickrAccessToken ($flickr_request_token, $flickr_request_token_secret, $flickr_verifier);

		if (defined ($accessToken{oauth_token}) && defined ($accessToken{oauth_token_secret})) {
			$secret{flickr_access_token} = $accessToken{oauth_token};
			$secret{flickr_access_token_secret} = $accessToken{oauth_token_secret};

			say sprintf ( ## no critic (InputOutput::RequireCheckedSyscalls)
				'Access token (%s) and access token secret (%s) are in %s',
				$accessToken{oauth_token},
				$accessToken{oauth_token_secret},
				$backingfile
			);

			untie %secret;
			return 1;
		}
	} else {
		my %req = flickrRequestToken ();
		if (defined ($req{oauth_token}) && defined ($req{oauth_token_secret}) && defined ($req{oauth_token})) {
			$secret{flickr_request_token} = $req{oauth_token};
			$secret{flickr_request_token_secret} = $req{oauth_token_secret};
			my $confirm_url = flickrAuthorization ($req{oauth_token});

			if (defined $confirm_url) {
				say "Please open this url in your browser and grant access for this app:\n$confirm_url"; ## no critic (InputOutput::RequireCheckedSyscalls)
				say 'Do not forget to put oauth_verifier to config.json file and re-run this script to get access token'; ## no critic (InputOutput::RequireCheckedSyscalls)
				say 'Note that you should be logged off from flickr account.'; ## no critic (InputOutput::RequireCheckedSyscalls)
				untie %secret;
				return 1;
			}
		}
	}

	untie %secret;
	return 0;
}

sub FlickrTestLogin {
	my $text = shift;
	my $backingfile = sprintf '%s/secrets.sqlite', $dir;

	unless (-d $dir) {
		make_path ($dir) or do {
			say "Unable to create $dir: $OS_ERROR"; ## no critic (InputOutput::RequireCheckedSyscalls)
			return 0;
		};
	}

	tie my %secret, 'SQLite_File', $backingfile  ||  do {
		say "[ERROR] Unable to tie to $backingfile: $OS_ERROR"; ## no critic (InputOutput::RequireCheckedSyscalls)
		return 0;
	};

	my $flickr_access_token = $secret{flickr_access_token};
	my $flickr_access_token_secret = $secret{flickr_access_token_secret};
	untie %secret;

	if (flickrTestLogin ($flickr_access_token, $flickr_access_token_secret)) {
		return 1;
	} else {
		return 0;
	}
}

sub FlickrByTags {
	my $text = shift;
	my $backingfile = sprintf '%s/secrets.sqlite', $dir;

	unless (-d $dir) {
		make_path ($dir) or do {
			say "Unable to create $dir: $OS_ERROR"; ## no critic (InputOutput::RequireCheckedSyscalls)
			return 0;
		};
	}

	tie my %secret, 'SQLite_File', $backingfile  ||  do {
		say "[ERROR] Unable to tie to $backingfile: $OS_ERROR"; ## no critic (InputOutput::RequireCheckedSyscalls)
		return 0;
	};

	my $flickr_access_token = $secret{flickr_access_token};
	my $flickr_access_token_secret = $secret{flickr_access_token_secret};
	untie %secret;

	# NB: I honestly query random page (among number of pages) of results from api, but always got first page,
	# no matter what is shown in response' "page" parameter. Looks like bug in API. Try to little bit mitigate
	# this bug via query 500 results per page, then we can select random result in this heap. But anyway, let's
	# make this thing future proof and leave randomizer in page select.
	my $result = flickrSearchByTags ($flickr_access_token, $flickr_access_token_secret, $text);

	if ($result) {
		if (defined ($result->{photos}) && defined ($result->{photos}->{photo})) {
			my $item = irand int(@{$result->{photos}->{photo}});
			$item = ${$result->{photos}->{photo}}[$item];
			$item = sprintf 'https://live.staticflickr.com/%s/%s_%s_z.jpg', $item->{server}, $item->{id}, $item->{secret};
			return $item;
		} else {
			cluck 'Flickr api returns empty search result list';
			return;
		}
	} else {
		return;
	}
}

sub FlickrByText {
	my $text = shift;
	my $backingfile = sprintf '%s/secrets.sqlite', $dir;

	unless (-d $dir) {
		make_path ($dir) or do {
			say "Unable to create $dir: $OS_ERROR"; ## no critic (InputOutput::RequireCheckedSyscalls)
			return 0;
		};
	}

	tie my %secret, 'SQLite_File', $backingfile  ||  do {
		say "[ERROR] Unable to tie to $backingfile: $OS_ERROR"; ## no critic (InputOutput::RequireCheckedSyscalls)
		return 0;
	};

	my $flickr_access_token = $secret{flickr_access_token};
	my $flickr_access_token_secret = $secret{flickr_access_token_secret};
	untie %secret;

	# NB: I honestly query random page (among number of pages) of results from api, but always got first page,
	# no matter what is shown in response' "page" parameter. Looks like bug in API. Try to little bit mitigate
	# this bug via query 500 results per page, then we can select random result in this heap. But anyway, let's
	# make this thing future proof and leave randomizer in page select.
	my $result = flickrSearchByText ($flickr_access_token, $flickr_access_token_secret, $text);

	if ($result) {
		if (defined ($result->{photos}) && defined ($result->{photos}->{photo})) {
			my $item = irand int(@{$result->{photos}->{photo}});
			$item = ${$result->{photos}->{photo}}[$item];
			$item = sprintf 'https://live.staticflickr.com/%s/%s_%s_z.jpg', $item->{server}, $item->{id}, $item->{secret};
			return $item;
		} else {
			cluck 'Flickr api returns empty search result list';
			return;
		}
	} else {
		return;
	}
}

1;
