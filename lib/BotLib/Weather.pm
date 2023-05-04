package BotLib::Weather;

use 5.018; ## no critic (ProhibitImplicitImport)
use strict;
use warnings;
use utf8;
use open         qw (:std :utf8);
use English      qw ( -no_match_vars );
use CHI             ();
use CHI::Driver::BerkeleyDB ();
use HTTP::Tiny      ();
use JSON::XS     qw (decode_json);
use Log::Any     qw ($log);
use BotLib::Conf qw (LoadConf);
use BotLib::Util qw (trim urlencode);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Weather);

my $c = LoadConf ();

sub Weather {
	my $city = shift;
	$city = trim $city;

	return 'Мне нужно ИМЯ города.' if ($city eq '');
	return 'Длинновато для названия города.' if (length ($city) > 80);

	$city = ucfirst $city;

	my $cache = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $c->{cachedir},
		namespace => __PACKAGE__,
	);

	my $geoCallBack = sub {
		my $appid = $c->{openweathermap}->{appid};
		my $geo;

		my $r;

		# Try 3 times and giveup
		for (1..3) {
			my $http = HTTP::Tiny->new (timeout => 3);
			$r = $http->get (
				sprintf (
					'http://api.openweathermap.org/geo/1.0/direct?q=%s&limit=1&APPID=%s',
					urlencode ($city),
					$appid,
				),
			);

			if ($r->{success}) {
				last;
			}

			sleep 2;
		}

		# All 3 times it can give us error, so check this case here
		if ($r->{success}) {
			$geo = eval {
				decode_json ($r->{content});
			};

			unless ($geo) {
				$log->warn ("[WARN] openweathermap geo api returns corrupted json: $EVAL_ERROR");
				return undef;
			}
		} else {
			$log->warn (
				sprintf (
					'[WARN] Server api.openweathermap.org return status %s with message: %s in request to geo',
					$r->{status},
					$r->{reason},
				),
			);

			return undef;
		}

		if (defined ($geo->[0]->{lat}) && defined ($geo->[0]->{lon})) {
			# Success
			return $geo->[0];
		} else {
			# Error, no coordinates
			$log->warn ('[WARN] Server api.openweathermap.org does not return coordinates in response to geo request');
			return undef;
		}
	};

	my $geo = $cache->compute (
		$city,
		'2 months',
		$geoCallBack,
	);

	my $weatherCallBack = sub {
		my $appid = $c->{openweathermap}->{appid};

		unless (defined $appid) {
			$log->warn ('[WARN] No appid specified for openweathermap');
			return undef;
		}

		my $fc;
		my $w;
		my $r;

		if (defined $geo) {
			# try 3 times and giveup
			for (1..3) {
				my $http = HTTP::Tiny->new (timeout => 3);
				$r = $http->get (
					sprintf (
						'http://api.openweathermap.org/data/2.5/weather?lat=%s&lon=%s&lang=ru&APPID=%s',
						$geo->{lat},
						$geo->{lon},
						$appid,
					),
				);

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

				unless (defined $fc) {
					$log->warn ("[WARN] openweathermap returns corrupted json: $EVAL_ERROR");
					return undef;
				}
			} else {
				$log->warn (sprintf 'Server return status %s with message: %s', $r->{status}, $r->{reason});
				return undef;
			}

			# TODO: check all of this for existence
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
		} else {
			# No geo, no weather :'(
			return undef;
		}
	};

	my $w = $cache->compute (
		"$geo->{lat}+$geo->{lon}",
		'3 hours',
		$weatherCallBack,
	);

	my $reply;

	if ($w) {
		if ($w->{temperature_min} == $w->{temperature_max}) {
			$reply = sprintf (
				"Погода в городе %s, %s:\n%s, ветер %s %s м/c, температура %s°C, ощущается как %s°C, относительная влажность %s%%, давление %s мм.рт.с",
				$city,
				$w->{country},
				ucfirst ($w->{description}),
				$w->{wind_direction},
				$w->{wind_speed},
				$w->{temperature_min},
				$w->{temperature_feelslike},
				$w->{humidity},
				$w->{pressure},
			);
		} else {
			$reply = sprintf (
				"Погода в городе %s, %s:\n%s, ветер %s %s м/c, температура %s-%s°C, ощущается как %s°C, относительная влажность %s%%, давление %s мм.рт.ст",
				$city,
				$w->{country},
				ucfirst ($w->{description}),
				$w->{wind_direction},
				$w->{wind_speed},
				$w->{temperature_min},
				$w->{temperature_max},
				$w->{temperature_feelslike},
				$w->{humidity},
				$w->{pressure},
			);
		}
	} else {
		$reply = "Я не знаю, какая погода в $city";
	}

	return $reply;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
