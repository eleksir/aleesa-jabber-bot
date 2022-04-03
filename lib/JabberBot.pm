# note http://www.gentoo.ru/node/21449
# необходимо закомментировать строку $response{authzid} = $authzid;
# в vendor_perl/5.24.3/Authen/SASL/Perl/DIGEST_MD5.pm
package JabberBot;

use 5.018; ## no critic (ProhibitImplicitImport)
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use File::Path qw (make_path);
use Hailo ();
use Log::Any qw ($log);
use Net::Jabber::Bot ();
use BotLib qw (Command RealJID);
use BotLib::Conf qw (LoadConf);
use BotLib::Karma qw (KarmaSet);
use BotLib::Util qw (trim utf2sha1);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (RunJabberBot);

my $c = LoadConf ();
my $csign = $c->{jabberbot}->{aleesa}->{csign};
my $hailo;
my $imonline = 0;

sub __background_checks {
	my $bot = shift;

	unless ($imonline) {
		$bot->ChangeStatus ('Available', 'I\'m here');
		$imonline = 1;
	}

	return;
}

sub __new_bot_message {
	my %hash = @_;
	my $bot = $hash{bot_object};

	# ignore self messages
	if ($hash{from_full} eq $bot->{from_full}) {
		return;
	}

	my $text = $hash{body};
	my %jid = RealJID (%hash);
	my $chattername = $jid{name};
	my $chatid;

	if ($hash{type} eq 'groupchat') {
		$chatid = utf2sha1 $hash{reply_to};
	} else {
		$chatid = utf2sha1 $jid{name};
	}

	$chatid =~ s/\//-/xmsg;

	my $reply;

	# lazy init chat-bot brains
	unless (defined $hailo->{$chatid}) {
		my $braindir = $c->{jabberbot}->{braindir};
		my $brainname = sprintf '%s/%s.sqlite', $braindir, $chatid;

		unless (-d $braindir) {
			make_path ($braindir) or do {
				$log->error ("[ERROR] Unable to create $braindir: $OS_ERROR");
				return;
			};
		}

		$hailo->{$chatid} = Hailo->new (
			brain => $brainname,
			order => 2,
		);

		if ($hash{type} eq 'groupchat') {
			$log->info ("[INFO] Initialized brain for chat $hash{'reply_to'}: $brainname");
		} else {
			$log->info ("[INFO] Initialized brain for chat $jid{'jid'}: $brainname");
		}
	}

	# parse messages
	my $qname = quotemeta $bot->{alias};

	if ($text =~ /^$qname\,?\s*$/u) {
		$reply = 'Чего тебе?';
	} elsif (($text =~ /^$qname[\,|\:]? (.+)/u) && ($hash{type} eq 'groupchat')) {
		$reply = $hailo->{$chatid}->learn_reply ($1);
	} elsif ($text =~ /^\=\($/u || $text =~ /^\:\($/u || $text eq /^\)\:$/u) {
		$reply = ':)';
	} elsif ($text =~ /^\=\)$/u || $text =~ /^\:\)$/u || $text =~ /^\(\:$/u) {
		$reply = ':D';
	# karma adjustment
	} elsif ($text =~ /(\+\+|\-\-)$/) {
		my @arr = split /\n/, $text;

		if ($#arr < 1) {
			$text =~ /(.*)(\+\+|\-\-)$/u;
			$reply = KarmaSet ($chatid, trim ($1), $2); ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)
		} else {
			# just message in chat
			# in groupchat we answer only to phrases that mention us
			if ($hash{type} eq 'groupchat') {
				$hailo->{$chatid}->learn ($text);
			# in tet-a-tet chat we must always answer, if possible
			} elsif ($hash{type} eq 'chat') {
				$reply = $hailo->{$chatid}->learn_reply ($text);
			}
		}
	} elsif ((length ($text) > length ($csign)) && (substr ($text, 0, length ($csign)) eq $csign)) {
		$reply = Command (%hash);
	# just message in chat
	} else {
		# in groupchat we answer only to phrases that mention us
		if ($hash{type} eq 'groupchat') {
			$hailo->{$chatid}->learn ($text);
		# in tet-a-tet chat we must always answer, if possible
		} elsif ($hash{'type'} eq 'chat') {
			$reply = $hailo->{$chatid}->learn_reply ($text);
		}
	}

	if (defined $reply && ($reply ne '')) {
		if ($hash{'type'} eq 'groupchat') {
			$bot->SendGroupMessage ($hash{'reply_to'}, $reply);
		} elsif ($hash{'type'} eq 'chat') {
			$bot->SendPersonalMessage ($hash{'reply_to'}, $reply);
		}
	}

	return;
}


sub RunJabberBot {
	my %conflist = ();
	$conflist{$c->{jabberbot}->{aleesa}->{room}} = [];
	my $qname = quotemeta $c->{jabberbot}->{aleesa}->{mucname};

	my $bot = Net::Jabber::Bot->new (
		server              => $c->{jabberbot}->{aleesa}->{host},
		server_host         => $c->{jabberbot}->{aleesa}->{host},
		conference_server   => $c->{jabberbot}->{aleesa}->{confsrv},
		tls                 => 1,
		ssl_verify          => 0,
		username            => $c->{jabberbot}->{aleesa}->{authname},

		# threre is some nasty bug in module, so we have to set from_full explicitly
		from_full           => sprintf (
			'%s@%s/%s',
			$c->{jabberbot}->{aleesa}->{room},
			$c->{jabberbot}->{aleesa}->{confsrv},
			$c->{jabberbot}->{aleesa}->{authname},
		),
		password            => $c->{jabberbot}->{aleesa}->{password},
		alias               => $c->{jabberbot}->{aleesa}->{mucname}, # name on confs
		resource            => 'bot',
		safety_mode         => 1,
		message_function    => \&__new_bot_message,
		background_function => \&__background_checks,
		loop_sleep_time     => 60,
		forums_and_responses => \%conflist,
	);

	while (sleep 3) {
		eval {
			$imonline = 0;
			$bot->Start ();
		};
	}

	return;
}


1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
