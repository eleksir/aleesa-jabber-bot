package BotLib;

use 5.018; ## no critic (ProhibitImplicitImport)
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Math::Random::Secure qw (irand);
use BotLib::Anek qw (Anek);
use BotLib::Archeologist qw (Dig);
use BotLib::Buni qw (Buni);
use BotLib::Conf qw (LoadConf);
use BotLib::Drink qw (Drink);
use BotLib::Fisher qw (Fish);
use BotLib::Fortune qw (Fortune);
use BotLib::Fox qw (Fox);
use BotLib::Friday qw (Friday);
use BotLib::Image qw (Rabbit Owl Frog Horse Snail);
use BotLib::Karma qw (KarmaGet);
use BotLib::Kitty qw (Kitty);
use BotLib::Lat qw (Lat);
use BotLib::Monkeyuser qw (Monkeyuser);
use BotLib::Proverb qw (Proverb);
use BotLib::Util qw (trim utf2sha1);
use BotLib::Weather qw (Weather);
use BotLib::Xkcd qw (Xkcd);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Command RandomCommonPhrase RealJID);

sub RandomCommonPhrase ();
sub Command;
sub RealJID(%);

my $c = LoadConf ();

sub RandomCommonPhrase () {
	my @myphrase = (
		'Так, блядь...',
		'*Закатывает рукава* И ради этого ты меня позвал?',
		'Ну чего ты начинаешь, нормально же общались',
		'Повтори свой вопрос, не поняла',
		'Выйди и зайди нормально',
		'Я подумаю',
		'Даже не знаю что на это ответить',
		'Ты упал такие вопросы девочке задавать?',
		'Можно и так, но не уверена',
		'А как ты думаешь?',
	);

	return $myphrase[irand ($#myphrase + 1)];
}

sub Command {
	my %hash = @_;
	my $bot = $hash{bot_object};
	my $text = $hash{body};
	my %jid = RealJID (%hash);
	my $chattername = $jid{'name'};
	my $chatid;

	if ($hash{'type'} eq 'groupchat') {
		$chatid = utf2sha1 $hash{'reply_to'};
	} else {
		$chatid = utf2sha1 $jid{'name'};
	}

	$chatid =~ s/\//-/xmsg;
	%jid = (); undef %jid;
	my $csign = $c->{jabberbot}->{aleesa}->{csign};

	my $reply;
	my $cmd = substr $text, length ($csign);

	if (($cmd =~ /rum\s?/u)  ||  ($cmd =~ /ром\s?/u)) {
		my $target = $chattername;

		if ($hash{'type'} eq 'groupchat') {
			if ($cmd =~ /rum\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			} elsif ($cmd =~ /ром\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			}
		}

		$reply = '/me притаскивает на подносе стопку рома для ' . $target . ', края стопки искрятся кристаллами соли.';
	} elsif (($cmd =~ /vodka\s?/u)  ||  ($cmd =~ /водка\s?/u)) {
		my $target = $chattername;

		if ($hash{'type'} eq 'groupchat') {
			if ($cmd =~ /vodka\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			} elsif ($cmd =~ /водка\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			}
		}

		$reply = '/me подаёт шот водки с небольшим маринованным огурчиком на блюдце для ' . $target . '. Из огурчика торчит небольшая вилочка.';
	} elsif (($cmd =~ /^beer\s?/u)  ||  ($cmd =~ /^пиво\s?/u)) {
		my $target = $chattername;

		if ($hash{'type'} eq 'groupchat') {
			if ($cmd =~ /^beer\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			} elsif ($cmd =~ /^пиво\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			}
		}

		$reply = '/me бахает об стол перед ' . $target . ' кружкой холодного пива, часть пенной шапки сползает по запотевшей стенке кружки.';
	} elsif ($cmd =~ /^tequila\s?/u) {
		my $target = $chattername;

		if ($hash{'type'} eq 'groupchat') {
			if ($cmd =~ /^tequila\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			}
		}

		$reply = '/me ставит рядом с ' . $target . ' шот текилы, аккуратно на ребро стопки насаживает дольку лайма и ставит кофейное блюдце с горочкой соли.';
	} elsif ($cmd =~ /^текила\s?/u) {
		my $target = $chattername;

		if ($hash{'type'} eq 'groupchat') {
			if ($cmd =~ /^текила\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			}
		}

		$reply = '/me ставит рядом с ' . $target . ' шот текилы, аккуратно на ребро стопки насаживает дольку лайма и ставит кофейное блюдце с горочкой соли.';
	} elsif ($cmd =~ /^whisky\s?/u) {
		my $target = $chattername;

		if ($hash{'type'} eq 'groupchat') {
			if ($cmd =~ /^whisky\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			}
		}

		$reply = '/me демонстративно достаёт из морозилки пару кубических камушков, бросает их в толстодонный стакан и аккуратно наливает Jack Daniels. Запускает стакан вдоль барной стойки, он останавливается около ' . $target . '.';
	} elsif ($cmd =~ /^виски\s?/u) {
		my $target = $chattername;

		if ($hash{'type'} eq 'groupchat') {
			if ($cmd =~ /^виски\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			}
		}

		$reply = '/me демонстративно достаёт из морозилки пару кубических камушков, бросает их в толстодонный стакан и аккуратно наливает Jack Daniels. Запускает стакан вдоль барной стойки, он останавливается около ' . $target . '.';
	} elsif ($cmd =~ /^absinthe\s?/u) {
		my $target = $chattername;

		if ($hash{'type'} eq 'groupchat') {
			if ($cmd =~ /^absinthe\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			}
		}

		$reply = '/me наливает абсент в стопку. Смочив кубик сахара в абсенте кладёт его на дырявую ложечку и пожигает. Как только пламя потухнет, ' . $bot->{'alias'} . ' размешивает оплавившийся кубик в абсенте и подносит стопку ' . $target . '.';
	} elsif ($cmd =~ /^абсент\s?/u) {
		my $target = $chattername;

		if ($hash{'type'} eq 'groupchat') {
			if ($cmd =~ /^абсент\s+(.*)/u) {
				$target = $1 if ($1 ne '');
			}
		}

		$reply = '/me наливает абсент в стопку. Смочив кубик сахара в абсенте кладёт его на дырявую ложечку и пожигает. Как только пламя потухнет, ' . $bot->{'alias'} . ' размешивает оплавившийся кубик в абсенте и подносит стопку ' . $target . '.';
	} elsif ($cmd =~ /^[wп]\s+.+/u) {
		$cmd =~ /^[wп]\s+(.*)/;
		my $city = $1; ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)
		$reply = Weather ($city) =~ tr/\n/ /r;
	} elsif ($cmd eq 'anek'  ||  $cmd eq 'анек' || $cmd eq 'анекдот' ) {
		$reply = Anek ();
	} elsif ($cmd eq 'coin' || $cmd eq 'монетка') {
		if (rand (101) < 0.016) {
			$reply = 'ребро';
		} else {
			if (irand (2) == 0) {
				if (irand (2) == 0) {
					$reply = 'орёл';
				} else {
					$reply = 'аверс';
				}
			} else {
				if (irand (2) == 0) {
					$reply = 'решка';
				} else {
					$reply = 'реверс';
				}
			}
		}
	} elsif ($cmd eq 'roll'  ||  $cmd eq 'dice'  ||  $cmd eq 'кости') {
		$reply = sprintf 'На первой кости выпало %d, а на второй — %d.', irand (6) + 1, irand (6) + 1;
	} elsif ($cmd eq 'version'  ||  $cmd eq 'ver'  ||  $cmd eq 'версия') {
		$reply = 'Версия три.чего-то_там.чего-то_там';
	} elsif ($cmd eq 'help'  ||  $cmd eq 'помощь') {
		$reply = <<"EOL";

${csign}help | ${csign}помощь             - это сообщение
${csign}anek | ${csign}анек | ${csign}анекдот    - рандомный анекдот с anekdot.ru
${csign}buni                       - комикс-стрип hapi buni
${csign}bunny                      - кролик
${csign}rabbit | ${csign}кролик           - кролик
${csign}cat | ${csign}кис                 - кошечка
${csign}coin | ${csign}монетка            - подбросить монетку - орёл или решка?
${csign}dig | ${csign}копать              - заняться археологией
${csign}drink | ${csign}праздник          - какой сегодня праздник?
${csign}fish | ${csign}fisher             - порыбачить
${csign}рыба | ${csign}рыбка | ${csign}рыбалка   - порыбачить
${csign}f | ${csign}ф                     - рандомная фраза из сборника цитат fortune_mod
${csign}fortune | ${csign}фортунка        - рандомная фраза из сборника цитат fortune_mod
${csign}fox | ${csign}лис                 - лисичка
${csign}friday | ${csign}пятница          - а не пятница ли сегодня?
${csign}frog | ${csign}лягушка            - лягушка
${csign}horse | ${csign}лошадь | ${csign}лошадка - лошадка
${csign}karma фраза                - посмотреть карму фразы
${csign}карма фраза                - посмотреть карму фразы
фраза++ | фраза--           - повысить или понизить карму фразы
${csign}lat | ${csign}лат                 - сгенерировать фразу из крылатого латинского выражения
${csign}monkeyuser                 - комикс-стрип MonkeyUser
${csign}owl | ${csign}сова                - сова
${csign}ping | ${csign}пинг               - попинговать бота
${csign}proverb | ${csign}пословица       - рандомная русская пословица
${csign}roll | ${csign}dice | ${csign}кости      - бросить кости
${csign}snail | ${csign}улитк а           - улитка
${csign}some_brew                  - выдать соответствующий напиток, бармен может налить rum, ром, vodka, водку, beer, пиво, tequila, текила, whisky, виски, absinthe, абсент
${csign}ver | ${csign}version             - написать что-то про версию ПО
${csign}версия                     - написать что-то про версию ПО
${csign}w город | ${csign}п город         - погода в городе
${csign}xkcd                       - комикс-стрип с xkcb.ru
EOL

	} elsif ($cmd eq 'lat'  ||  $cmd eq 'лат') {
		$reply = Lat ();
	} elsif ($cmd eq 'cat'  ||  $cmd eq 'кис') {
		$reply = Kitty ();
	} elsif ($cmd eq 'fox'  ||  $cmd eq 'лис') {
		$reply = Fox ();
	} elsif ($cmd eq 'frog'  ||  $cmd eq 'лягушка') {
		$reply = Frog ();
	} elsif ($cmd eq 'horse'  ||  $cmd eq 'лошадь'  || $cmd eq 'лошадка') {
		$reply = Horse ();
	} elsif ($cmd eq 'snail'  ||  $cmd eq 'улитка') {
		$reply = Snail ();
	} elsif ($cmd eq 'dig'  ||  $cmd eq 'копать') {
		$reply = Dig ($chattername);
	} elsif ($cmd eq 'fish'  ||  $cmd eq 'fisher'  ||  $cmd eq 'рыба'  ||  $cmd eq 'рыбка'  ||  $cmd eq 'рыбалка') {
		$reply = Fish ($chattername);
	} elsif ($cmd eq 'buni') {
		$reply = Buni ();
	} elsif ($cmd eq 'xkcd') {
		$reply = Xkcd ();
	} elsif ($cmd eq 'monkeyuser') {
		$reply = Monkeyuser ();
	} elsif ($cmd eq 'drink' || $cmd eq 'праздник') {
		$reply = Drink ();
	} elsif ($cmd eq 'bunny' || $cmd eq 'rabbit' || $cmd eq 'кролик') {
		$reply = Rabbit ();
	} elsif ($cmd eq 'owl' || $cmd eq 'сова') {
		$reply = Owl ();
	} elsif ($cmd =~ /^karma\s*/  ||  $cmd =~ /^карма\s*/) {
		my $mytext = '';

		if (length ($cmd) > length ('karma')) {
			$mytext = substr $cmd, length ('karma');
			while ($mytext =~ /\n$/) { chomp $mytext }
			$mytext = trim $mytext;
		} elsif (length ($cmd) > length ('карма')) {
			$mytext = substr $cmd, length ('карма');
			while ($mytext =~ /\n$/) { chomp $mytext }
			$mytext = trim $mytext;
		} else {
			$mytext = '';
		}

		$reply = KarmaGet ($chatid, $mytext);
	} elsif ($cmd eq 'friday'  ||  $cmd eq 'пятница') {
		$reply = Friday ();
	} elsif ($cmd eq 'proverb'  ||  $cmd eq 'пословица') {
		$reply = Proverb ();
	} elsif ($cmd eq 'fortune'  ||  $cmd eq 'фортунка'  ||  $cmd eq 'f'  ||  $cmd eq 'ф') {
		my $phrase = Fortune ();
		# workaround Net::Jabber::Bot outgoing message ![:print:] replacement
		$phrase =~ s/\s\s+\-\-/\n \-\-/xmsg;
		$reply = $phrase;
	} elsif ($cmd eq 'ping') {
		$reply = 'Pong.';
	} elsif ($cmd eq 'пинг') {
		$reply = 'Понг.';
	} elsif ($cmd eq 'kde' || $cmd eq 'кде') {
		my @phrases = (
			'Нет, я не буду поднимать вам плазму.',
			'Повторяйте эту мантру по утрам не менее 5 раз: "Плазма не падает." И, возможно, она перестанет у вас падать.',
		);

		$reply = $phrases[irand ($#phrases + 1)];
	}

	return $reply;
}

# in this particular case real jid is really hidden :) and i hope that i found where it is hiding.
sub RealJID (%) {
	my %hash = @_;
	my $bot = $hash{'bot_object'};
	my $myjid = $hash{'from_full'}; # in case of real jid myjid is name@server/resource in case of "groupchat" jid it is group@conf_server/name
	my $presencedb = $bot->{'jabber_client'}->{'PRESENCEDB'};
	my %result;

	# there is missing case where user' name part of jid same as chat name (sic!)

	# in case of groupchat we have to compare reply_to and 1-st part of myjid (one that before slash)
	# in case 1-on-1 chat we have to compare 2-nd component of myjid (that between @ and /) and conference server
	#    assuming that bot sits only on same conference server where bot is registered
	if (
			(($hash{'reply_to'} eq (split (/\//, $myjid))[0]) && ($hash{'type'} eq 'groupchat')) ||
			(($bot->{'conference_server'} eq (split (/\@/, (split (/\//, $myjid))[0]))[1]) && ($hash{'type'} eq 'chat'))
		) {
		foreach my $knownjid (keys %{$presencedb}) {
			foreach my $prionum (keys %{$presencedb->{$knownjid}->{'priorities'}}) {
				foreach my $presence (@{$presencedb->{$knownjid}->{'priorities'}->{$prionum}}) {
					if ($presence->{'presence'}->{'TREE'}->{'ATTRIBS'}->{'from'} eq $myjid) {
						foreach my $child (@{$presence->{'presence'}->{'TREE'}->{'CHILDREN'}}) {
							() = eval {
								$child->{'CHILDREN'};
							};

							unless ($EVAL_ERROR) {
								foreach my $subchild ($child->{'CHILDREN'}) {
									foreach my $elem (@{$subchild}) {
										() = eval {
											$elem->{'ATTRIBS'};
										};

										unless ($EVAL_ERROR) {
											() = eval {
												$elem->{'ATTRIBS'}->{'jid'};
											};

											unless ($EVAL_ERROR) {
												if (defined $elem->{'ATTRIBS'}->{'jid'}) {
													%result = (
														'fulljid' => $elem->{'ATTRIBS'}->{'jid'},
														'jid' => (split (/\//, $elem->{'ATTRIBS'}->{'jid'})) [0],
														'name' => (split (/\@/, $elem->{'ATTRIBS'}->{'jid'})) [0],
													);

													return %result;
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}

		# we tried hard :( and if we here, assume that we have no permissions to to guess real jid in chat
		%result = (
			'fulljid' => $myjid,
			'jid' => $myjid,
			'name' => (split (/\//, $myjid))[1],
		);
	} else {
		# looks like it is correct real jid, assume that conference server and main server reside on different domains
		# at least i hope that this assumption correct
		%result = (
			'fulljid' => $myjid,
			'jid' => (split (/\//, $myjid))[0],
			'name' => (split (/\@/, $myjid))[0],
		);
	}

	return %result;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
