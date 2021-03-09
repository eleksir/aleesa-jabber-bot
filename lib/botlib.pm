package botlib;
# TODO: исправить #/bin/bash и #/bin/env
# TODO: добавить сов и кроликов flickr и imgur

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Carp qw (carp);
use Math::Random::Secure qw (irand);
use archeologist qw (dig);
use buni qw (buni);
use conf qw (loadConf);
use fisher qw (fish);
use fortune qw (fortune);
use fox qw (fox);
use friday qw (friday);
use karma qw (karmaGet);
use kitty qw (kitty);
use lat qw (latAnswer);
use util qw (trim utf2sha1);
use weather qw (weather);
use xkcd qw (xkcd);

use version; our $VERSION = qw (1.0);
use Exporter qw(import);
our @EXPORT_OK = qw(command randomCommonPhrase realjid);

my $c = loadConf ();

sub randomCommonPhrase () {
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

sub command {
	my %hash = @_;
	my $bot = $hash{bot_object};
	my $text = $hash{body};
	my %jid = realjid (%hash);
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

	if (substr ($text, 1, 3) eq 'rum' || substr ($text, 1, 3) eq 'ром') {
		my $target;

		if (($hash{'type'} eq 'groupchat') && (length ($text) > 5)) {
			$target = trim (substr $text, 5);
		}

		if (! defined $target || ($target eq '')) {
			$target = $chattername;
		}

		$reply = '/me притаскивает на подносе стопку рома для ' . $target . ', края стопки искрятся кристаллами соли.';
	} elsif (substr ($text, 1, 5) eq 'vodka' || substr ($text, 1, 5) eq 'водка') {
		my $target;

		if (($hash{'type'} eq 'groupchat') && (length ($text) > 7)) {
			$target = trim (substr $text, 7);
		}

		if (! defined $target || ($target eq '')) {
			$target = $chattername;
		}

		$reply = '/me подаёт шот водки с небольшим маринованным огурчиком на блюдце для ' . $target . '. Из огурчика торчит небольшая вилочка.';
	} elsif (substr ($text, 1, 4) eq 'beer' || substr ($text, 1, 4) eq 'пиво') {
		my $target;

		if (($hash{'type'} eq 'groupchat') && (length ($text) > 6)) {
			$target = trim (substr $text, 6);
		}

		if (! defined $target || ($target eq '')) {
			$target = $chattername;
		}

		$reply = '/me бахает об стол перед ' . $target . ' кружкой холодного пива, часть пенной шапки сползает по запотевшей стенке кружки.';
	} elsif (substr ($text, 1, 7) eq 'tequila') {
		my $target;

		if (($hash{'type'} eq 'groupchat') && (length ($text) > 9)) {
			$target = trim (substr $text, 9);
		}

		if (! defined $target || ($target eq '')) {
			$target = $chattername;
		}

		$reply = '/me ставит рядом с ' . $target . ' шот текилы, аккуратно на ребро стопки насаживает дольку лайма и ставит кофейное блюдце с горочкой соли.';
	} elsif (substr ($text, 1, 6) eq 'текила') {
		my $target;

		if (($hash{'type'} eq 'groupchat') && (length ($text) > 8)) {
			$target = trim (substr $text, 8);
		}

		if (! defined $target || ($target eq '')) {
			$target = $chattername;
		}

		$reply = '/me ставит рядом с ' . $target . ' шот текилы, аккуратно на ребро стопки насаживает дольку лайма и ставит кофейное блюдце с горочкой соли.';
	} elsif (substr ($text, 1, 6) eq 'whisky') {
		my $target;

		if (($hash{'type'} eq 'groupchat') && (length ($text) > 8)) {
			$target = trim (substr $text, 8);
		}

		if (! defined $target || ($target eq '')) {
			$target = $chattername;
		}

		$reply = '/me демонстративно достаёт из морозилки пару кубических камушков, бросает их в толстодонный стакан и аккуратно наливает Jack Daniels. Запускает стакан вдоль барной стойки, он останавливается около ' . $target . '.';
	} elsif (substr ($text, 1, 5) eq 'виски') {
		my $target;

		if (($hash{'type'} eq 'groupchat') && (length ($text) > 7)) {
			$target = trim (substr $text, 7);
		}

		if (! defined $target || ($target eq '')) {
			$target = $chattername;
		}

		$reply = '/me демонстративно достаёт из морозилки пару кубических камушков, бросает их в толстодонный стакан и аккуратно наливает Jack Daniels. Запускает стакан вдоль барной стойки, он останавливается около ' . $target . '.';
	} elsif (substr ($text, 1, 8) eq 'absinthe') {
		my $target;

		if (($hash{'type'} eq 'groupchat') && (length ($text) > 10)) {
			$target = trim (substr $text, 10);
		}

		if (! defined $target || ($target eq '')) {
			$target = $chattername;
		}

		$reply = '/me наливает абсент в стопку. Смочив кубик сахара в абсенте кладёт его на дырявую ложечку и пожигает. Как только пламя потухнет, ' . $bot->{'alias'} . ' размешивает оплавившийся кубик в абсенте и подносит стопку ' . $target . '.';
	} elsif (substr ($text, 1, 6) eq 'абсент') {
		my $target;

		if (($hash{'type'} eq 'groupchat') && (length ($text) > 8)) {
			$target = trim (substr $text, 8);
		}

		if (! defined $target || ($target eq '')) {
			$target = $chattername;
		}

		$reply = '/me наливает абсент в стопку. Смочив кубик сахара в абсенте кладёт его на дырявую ложечку и пожигает. Как только пламя потухнет, ' . $bot->{'alias'} . ' размешивает оплавившийся кубик в абсенте и подносит стопку ' . $target . '.';
	} elsif (substr ($text, 1, 2) eq 'w '  ||  substr ($text, 1, 2) eq 'п ') {
		my $city = substr $text, 2;
		$reply = weather ($city) =~ tr/\n/ /r;
	} elsif (substr ($text, 1) eq 'version'  ||  substr ($text, 1) eq 'ver') {
		$reply = 'Версия нуль.чего-то_там.чего-то_там';
	} elsif (substr ($text, 1) eq 'help'  ||  substr ($text, 1) eq 'помощь') {
		$reply = <<"EOL";

${csign}help | ${csign}помощь           - это сообщение
${csign}buni                     - комикс-стрип hapi buni
${csign}cat | ${csign}кис               - кошечка
${csign}dig | ${csign}копать            - заняться археологией
${csign}fish | ${csign}fisher           - порыбачить
${csign}рыба | ${csign}рыбка | ${csign}рыбалка - порыбачить
${csign}f | ${csign}ф                   - рандомная фраза из сборника цитат fortune_mod
${csign}fortune | ${csign}фортунка      - рандомная фраза из сборника цитат fortune_mod
${csign}fox | ${csign}лис               - лисичка
${csign}friday | ${csign}пятница        - а не пятница ли сегодня?
${csign}karma фраза              - посмотреть карму фразы
${csign}карма фраза              - посмотреть карму фразы
фраза++ | фраза--         - повысить или понизить карму фразы
${csign}lat | ${csign}лат               - сгенерировать фразу из крылатого латинского выражения
${csign}ping | ${csign}пинг             - попинговать бота
${csign}some_brew                - выдать соответствующий напиток, бармен может налить rum, ром, vodka, водку, beer, пиво, tequila, текила, whisky, виски, absinthe, абсент
${csign}ver | ${csign}version           - написать что-то про версию ПО
${csign}версия                   - написать что-то про версию ПО
${csign}w город | ${csign}п город       - погода в городе
${csign}xkcd                     - комикс-стрип с xkcb.ru
EOL

	} elsif (substr ($text, 1) eq 'lat'  ||  substr ($text, 1) eq 'лат') {
		$reply = latAnswer ();
	} elsif (substr ($text, 1) eq 'cat'  ||  substr ($text, 1) eq 'кис') {
		$reply = kitty ();
	} elsif (substr ($text, 1) eq 'fox'  ||  substr ($text, 1) eq 'лис') {
		$reply = fox ();
	} elsif (substr ($text, 1) eq 'dig'  ||  substr ($text, 1) eq 'копать') {
		$reply = dig ($chattername);
	} elsif (substr ($text, 1) eq 'fish'  ||  substr ($text, 1) eq 'fisher'  ||  substr ($text, 1) eq 'рыба'  ||  substr ($text, 1) eq 'рыбка'  ||  substr ($text, 1) eq 'рыбалка') {
		$reply = fish ($chattername);
	} elsif (substr ($text, 1) eq 'buni') {
		$reply = buni ();
	} elsif (substr ($text, 1) eq 'xkcd') {
		$reply = xkcd ();
	} elsif ((length ($text) >= 6 && (substr ($text, 1, 6) eq 'karma ' || substr ($text, 1, 6) eq 'карма '))  ||  substr ($text, 1) eq 'karma'  ||  substr ($text, 1) eq 'карма') {
		my $mytext = '';

		if (length ($text) > 6) {
			$mytext = substr $text, 7;
			chomp $mytext;
			$mytext = trim $mytext;
		} else {
			$mytext = '';
		}

		$reply = karmaGet ($chatid, $mytext);
	} elsif (substr ($text, 1) eq 'friday'  ||  substr ($text, 1) eq 'пятница') {
		$reply = friday ();
	} elsif (substr ($text, 1) eq 'fortune'  ||  substr ($text, 1) eq 'фортунка'  ||  substr ($text, 1) eq 'f'  ||  substr ($text, 1) eq 'ф') {
		my $phrase = fortune ();
		# workaround Net::Jabber::Bot outgoing message ![:print:] replacement
		$phrase =~ s/\s\s+\-\-/\n \-\-/xmsg;
		$reply = $phrase;
	} elsif (substr ($text, 1) eq 'ping') {
		$reply = 'Pong.';
	} elsif (substr ($text, 1) eq 'пинг') {
		$reply = 'Понг.';
	} elsif (substr ($text, 1) eq 'kde' || substr ($text, 1) eq 'кде') {
		my @phrases = (
			'Нет, я не буду поднимать вам плазму.',
			'Повторяйте эту мантру по утрам не менее 5 раз: "Плазма не падает." И, возможно, она перестанет у вас падать.'
		);

		$reply = $phrases[irand ($#phrases + 1)];
	} elsif (substr ($text, 1) eq '=(' || substr ($text, 1) eq ':(' || substr ($text, 1) eq '):') {
		$reply = ':)';
	} elsif (substr ($text, 1) eq '=)' || substr ($text, 1) eq ':)' || substr ($text, 1) eq '(:') {
		$reply = ':D';
	} elsif (substr ($text, 1, 11) eq '#/bin/bash' || substr ($text, 1, 9) eq '#/bin/sh' || substr ($text, 1, 14) eq '#/usr/bin/env') {
		$reply = 'Кажется, вы ошиблись окном, это не паста.';
	}

	return $reply;
}

# in this particular case real jid is really hidden :) and i hope that i found where it is hiding.
sub realjid {
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
