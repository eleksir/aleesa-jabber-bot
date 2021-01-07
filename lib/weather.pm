package weather;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Carp qw (carp cluck);
use DB_File;
use Digest::MD5 qw (md5_base64);
use File::Path qw (make_path);
use HTTP::Tiny;
use JSON::XS;
use conf qw (loadConf);
use util qw (trim urlencode);

use vars qw/$VERSION/;
use Exporter qw (import);
our @EXPORT_OK = qw (weather);
$VERSION = '1.0';

my $c = loadConf ();

sub weather {
	my $city = shift;
	$city = trim $city;

	return 'Мне нужно ИМЯ города.' if ($city eq '');
	return 'Длинновато для названия города.' if (length ($city) > 80);

	$city = ucfirst $city;
	my $w = __weather ($city);
	my $reply;

	if ($w) {
		if ($w->{temperature_min} == $w->{temperature_max}) {
			$reply = sprintf ("Погода в городе %s, %s:\n%s, ветер %s %s м/c, температура %s°C, ощущается как %s°C, относительная влажность %s%%, давление %s мм.рт.с",
				$w->{name},
				$w->{country},
				ucfirst ($w->{description}),
				$w->{wind_direction},
				$w->{wind_speed},
				$w->{temperature_min},
				$w->{temperature_feelslike},
				$w->{humidity},
				$w->{pressure}
			);
		} else {
			$reply = sprintf ("Погода в городе %s, %s:\n%s, ветер %s %s м/c, температура %s-%s°C, ощущается как %s°C, относительная влажность %s%%, давление %s мм.рт.ст",
				$w->{name},
				$w->{country},
				ucfirst ($w->{description}),
				$w->{wind_direction},
				$w->{wind_speed},
				$w->{temperature_min},
				$w->{temperature_max},
				$w->{temperature_feelslike},
				$w->{humidity},
				$w->{pressure}
			);
		}
	} else {
		$reply = "Я не знаю, какая погода в $city";
	}

	return $reply;
}

sub __weather {
	my $city = shift;
	$city = urlencode $city;
	my $id = md5_base64 $city;
	my $appid = $c->{openweathermap}->{appid};
	my $cachedir = $c->{openweathermap}->{cachedir};
	my $cachetimefile = $cachedir . '/openweathermap.Id-Timestamp.db';
	my $cachedatafile = $cachedir . '/openweathermap.Id-Data.db';
	my $now = time ();
	my $fc;
	my $w;

	unless (-d $cachedir) {
		make_path ($cachedir)  ||  do {
			carp "[ERROR] Unable to create $cachedir: $OS_ERROR";
			return;
		};
	}

	# attach to cache data
	tie my %cachetime, 'DB_File', $cachetimefile or do {
		carp "[ERROR] Something nasty happen when cachetime ties to its data: $OS_ERROR";
		return undef;
	};

	tie my %cachedata, 'DB_File', $cachedatafile or do {
		carp "[ERROR] Something nasty happen when cachedata ties to its data: $OS_ERROR";
		return undef;
	};

	# lookup cache
	if (defined ($cachetime{$id}) && ($now - $cachetime{$id}) < 10800) {
		$fc = decode_json ($cachedata{$id});
	} else {
		my $r;

		# try 3 times and giveup
		for (1..3) {
			my $http = HTTP::Tiny->new (timeout => 3);
			$r = $http->get (sprintf ('http://api.openweathermap.org/data/2.5/weather?q=%s&lang=ru&APPID=%s', $city, $appid));

			if ($r->{success}) {
				last;
			}

			sleep 2;
		}

		# all 3 times can give error, so check it here
		if ($r->{success}) {
			$fc = eval {
				decode_json ($r->{content});
			};

			if ($EVAL_ERROR) {
				carp "[WARN] openweathermap returns corrupted json: $EVAL_ERROR";
				untie %cachetime;
				untie %cachedata;
				return undef;
			};

			$cachetime{$id} = $now;
			$cachedata{$id} = encode_json ($fc);
		} else {
			carp sprintf 'Server return status %s with message: %s', $r->{status}, $r->{reason};
			untie %cachetime;
			untie %cachedata;
			return undef;
		}
	}

	untie %cachetime;
	untie %cachedata;

	# TODO: check all of this for existance
	$w->{'name'} = $fc->{name};
	$w->{'state'} = $fc->{state};
	$w->{'country'} = $fc->{sys}->{country};
	$w->{'longitude'} = $fc->{coord}->{lon};
	$w->{'latitude'} = $fc->{coord}->{lat};
	$w->{'temperature_min'} = int ($fc->{main}->{temp_min} - 273.15);
	$w->{'temperature_max'} = int ($fc->{main}->{temp_max} - 273.15);
	$w->{'temperature_feelslike'} = int ($fc->{main}->{feels_like} - 273.15);
	$w->{'humidity'} = $fc->{main}->{humidity};
	$w->{'pressure'} = int ($fc->{main}->{pressure} * 0.75006375541921);
	$w->{'description'} = $fc->{weather}->[0]->{description};
	$w->{'wind_speed'} = $fc->{wind}->{speed};
	$w->{'wind_direction'} = 'разный';
	my $dir = int ($fc->{wind}->{deg} + 0);

	if ($dir == 0) {
		$w->{'wind_direction'} = 'северный';
	} elsif ($dir > 0   && $dir <= 30) {
		$w->{'wind_direction'} = 'северо-северо-восточный';
	} elsif ($dir > 30  && $dir <= 60) {
		$w->{'wind_direction'} = 'северо-восточный';
	} elsif ($dir > 60  && $dir <  90) {
		$w->{'wind_direction'} = 'восточно-северо-восточный';
	} elsif ($dir == 90) {
		$w->{'wind_direction'} = 'восточный';
	} elsif ($dir > 90  && $dir <= 120) {
		$w->{'wind_direction'} = 'восточно-юго-восточный';
	} elsif ($dir > 120 && $dir <= 150) {
		$w->{'wind_direction'} = 'юговосточный';
	} elsif ($dir > 150 && $dir <  180) {
		$w->{'wind_direction'} = 'юго-юго-восточный';
	} elsif ($dir == 180) {
		$w->{'wind_direction'} = 'южный';
	} elsif ($dir > 180 && $dir <= 210) {
		$w->{'wind_direction'} = 'юго-юго-западный';
	} elsif ($dir > 210 && $dir <= 240) {
		$w->{'wind_direction'} = 'юго-западный';
	} elsif ($dir > 240 && $dir <  270) {
		$w->{'wind_direction'} = 'западно-юго-западный';
	} elsif ($dir == 270) {
		$w->{'wind_direction'} = 'западный';
	} elsif ($dir > 270 && $dir <= 300) {
		$w->{'wind_direction'} = 'западно-северо-западный';
	} elsif ($dir > 300 && $dir <= 330) {
		$w->{'wind_direction'} = 'северо-западный';
	} elsif ($dir > 330 && $dir <  360) {
		$w->{'wind_direction'} = 'северо-северо-западный';
	} elsif ($dir == 360) {
		$w->{'wind_direction'} = 'северный';
	}

	return $w;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
