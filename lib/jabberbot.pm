# note http://www.gentoo.ru/node/21449
# необходимо закомменировать строку $response{authzid} = $authzid;
# в vendor_perl/5.24.3/Authen/SASL/Perl/DIGEST_MD5.pm
package jabberbot;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Net::Jabber::Bot;
use Hailo;

use conf qw(loadConf);
use botlib qw(weather logger trim randomCommonPhrase);
use lat qw(latAnswer);
use karma qw(karmaSet karmaGet);
use friday qw(friday);

use Exporter qw(import);
use vars qw/$VERSION/;
$VERSION = '1.0';
our @EXPORT_OK = qw(run_jabberbot);

my $c = loadConf();
my $hailo;
my $imonline = 0;

sub __background_checks {
	my $bot = shift;

	unless ($imonline) {
		$bot->ChangeStatus('Available', 'I\'m here');
		$imonline = 1;
	}

	return;
}

sub __new_bot_message {
	my %hash = @_;
	my $bot = $hash{bot_object};
	my $text = $hash{body};

	if ($hash{'type'} eq 'groupchat') {
		# ignore self messages
		return if ($hash{'from_full'} eq $bot->{'from_full'});
		# parse messages
		my $qname = quotemeta($c->{jabberbot}->{aleesa}->{mucname});
		if ($text =~ /^$qname$/) {
			$bot->SendGroupMessage($hash{'reply_to'}, 'Чего тебе?');
		} elsif ($text =~ /^$qname[\,|\:]? (.+)/) {
			$bot->SendGroupMessage($hash{'reply_to'}, $hailo->learn_reply($1));
		} elsif ($text eq "$c->{jabberbot}->{aleesa}->{csign}пинг") {
			$bot->SendGroupMessage($hash{'reply_to'}, 'Понг.');
		} elsif ($text eq "$c->{jabberbot}->{aleesa}->{csign}ping") {
			$bot->SendGroupMessage($hash{'reply_to'}, 'Pong.');
		} elsif (substr($text, 0, 1) eq $c->{jabberbot}->{aleesa}->{csign}) {
			if (substr($text, 1, 3) eq 'rum') {
				eval {
					$bot->SendGroupMessage(
						$hash{'reply_to'},
						'/me притаскивает на подносе стопку рома для ' . (split(/\//,$hash{from_full}))[1] . ', края стопки искрятся кристаллами соли.'
					);
				};
			} elsif (substr($text, 1, 5) eq 'vodka') {
				eval {
					$bot->SendGroupMessage(
						$hash{'reply_to'},
						'/me подаёт водку с маринованным огурчиком для ' . (split(/\//,$hash{from_full}))[1]
					);
				};
			} elsif (substr($text, 1, 4) eq 'beer') {
				eval {
					$bot->SendGroupMessage(
						$hash{'reply_to'},
						'/me бахает об стол перед ' . (split(/\//,$hash{from_full}))[1] . ' кружкой холодного пива, часть пенной шапки сползает по запотевшей спенке кружки.'
					);
				};
			} elsif (substr($text, 1, 7) eq 'tequila') {
				eval {
					$bot->SendGroupMessage(
						$hash{'reply_to'},
						'/me ставит рядом с ' . (split(/\//,$hash{from_full}))[1] . ' шот текилы, аккуратно на ребро стопки насаживает дольку лайма и ставит кофейное блюдце с горочкой соли.'
					);
				};
			} elsif (substr($text, 1, 6) eq 'whisky') {
				eval {
					$bot->SendGroupMessage(
						$hash{'reply_to'},
						'/me демонстративно достаёт из морозилки пару кубических камушков, бросает их в толстодонный стакан и аккуратно наливает Jack Daniels. Запускает стакан вдоль барной стойки, он останавливается около ' . (split(/\//,$hash{from_full}))[1] . '.'
					);
				};
			} elsif (substr($text, 1, 8) eq 'absinthe') {
				eval {
					$bot->SendGroupMessage(
						$hash{'reply_to'},
						"/me наливает абсент в стопку. Смочив кубик сахара в абсенте кладёт его на дырявую ложечку и пожигает. Как только пламя потухнет, $c->{jabberbot}->{aleesa}->{mucname} размешивает оплавившийся кубик в абсенте и подносит стопку " .(split(/\//,$hash{from_full}))[1] . '.'
					);
				};
			} elsif (substr($text, 1, 2) eq 'w '  ||  substr($text, 1, 2) eq 'п ') {
				my $city = substr($text, 2);

				eval {
					$bot->SendGroupMessage(
						$hash{'reply_to'},
						weather($city) =~ tr/\n/ /r
					);
				};
			} elsif (substr($text, 1) eq 'version'  ||  substr($text, 1) eq 'ver') {
				$bot->SendGroupMessage($hash{'reply_to'}, 'Версия нуль.чего-то_там.чего-то_там');
			} elsif (substr($text, 1) eq 'help'  ||  substr($text, 1) eq 'помощь') {
				$bot->SendGroupMessage($hash{'reply_to'}, <<"EOL" );
!help | !помощь - это сообщение
!friday | !пятница - а не пятница ли сегодня?
!lat | !лат - сгенерировать фразу из крылатого латинского выражения
!ping | !пинг - попинговать бота
!some_brew - выдать соответсвующий напиток, бармен может налить rum, vodka, beer, tequila, whisky, absinthe
!ver | !version | !версия - написать что-то про версию ПО
!w город | !п город - погода в городе
!karma фраза | !карма фраза - посмотреть карму фразы
фраза++ | фраза-- - повысить или понизить карму фразы
EOL

			} elsif (substr($text, 1) eq 'lat'  ||  substr($text, 1) eq 'лат') {
				$bot->SendGroupMessage($hash{'reply_to'}, latAnswer());
			} elsif (substr($text, 1, 6) eq 'karma '  ||  substr($text, 1, 6) eq 'карма '  ||  substr($text, 1) eq 'karma'  ||  substr($text, 1) eq 'карма') {
				my $mytext = substr($text, 7);

				if ($mytext ne '') {
					chomp($mytext);
					$mytext = trim($mytext);
				}

				$bot->SendGroupMessage($hash{'reply_to'}, karmaGet($hash{'reply_to'}, $mytext));
			} elsif (substr($text, 1) eq 'friday'  ||  substr($text, 1) eq 'пятница') {
				$bot->SendGroupMessage($hash{'reply_to'}, friday());
			} else {
				$hailo->learn($text);
				return;
			}
		} elsif ((substr($text, -2) eq '++') || (substr($text, -2) eq '--')) {
			my @arr = split(/\n/, $text);

			if ($#arr < 1) {
				my $reply = karmaSet($hash{'reply_to'}, substr($text, 0, -2), substr($text, -2));
				$bot->SendGroupMessage($hash{'reply_to'}, $reply);
			} else {
				# just message in chat
				$hailo->learn($text);
			}
		} else {
			$hailo->learn($text);
			return;
		}
	} elsif ($hash{'type'} eq 'chat') {
		$bot->SendPersonalMessage($hash{'reply_to'}, 'Я вас не знаю, идите нахуй.');
		return;
	}

	return;
}


sub run_jabberbot {
	$hailo = Hailo->new(
		brain => $c->{jabberbot}->{aleesa}->{brain},
		order => 2
	);

	my %conflist = ();
	$conflist{$c->{jabberbot}->{aleesa}->{room}} = [];
	my $qname = quotemeta($c->{jabberbot}->{aleesa}->{mucname});

	my $bot = Net::Jabber::Bot->new(
		server => $c->{jabberbot}->{aleesa}->{host},
		server_host => $c->{jabberbot}->{aleesa}->{host},
		conference_server => $c->{jabberbot}->{aleesa}->{confsrv},
		tls => 0,
		username => $c->{jabberbot}->{aleesa}->{authname},
# threre is some nasty bug in module, so we have to set from_full explicitly
		from_full => sprintf(
			"%s@%s/%s",
			$c->{jabberbot}->{aleesa}->{room},
			$c->{jabberbot}->{aleesa}->{confsrv},
			$c->{jabberbot}->{aleesa}->{authname}
		),
		password => $c->{jabberbot}->{aleesa}->{password},
		alias => $c->{jabberbot}->{aleesa}->{mucname}, # name on confs
		resource => 'bot',
		safety_mode => 1,
		message_function => \&__new_bot_message,
		background_function => \&__background_checks,
		loop_sleep_time => 60,
		forums_and_responses => \%conflist,
	);

	while (sleep 3) {
		eval {
			$imonline = 0;
			$bot->Start();
		};
	}

	return;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
