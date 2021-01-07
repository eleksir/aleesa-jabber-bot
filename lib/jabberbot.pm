# note http://www.gentoo.ru/node/21449
# необходимо закомменировать строку $response{authzid} = $authzid;
# в vendor_perl/5.24.3/Authen/SASL/Perl/DIGEST_MD5.pm
package jabberbot;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Carp qw(carp);
use File::Path qw (make_path);
use Hailo;
use Net::Jabber::Bot;
use botlib qw (command randomCommonPhrase realjid);
use conf qw (loadConf);
use karma qw (karmaSet);
use util qw (trim utf2sha1);

use Exporter qw (import);
use vars qw/$VERSION/;
$VERSION = '1.0';
our @EXPORT_OK = qw (run_jabberbot);

my $c = loadConf ();
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
	if ($hash{'from_full'} eq $bot->{'from_full'}) {
		return;
	}

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

	my $reply;

	# lazy init chat-bot brains
	unless (defined ($hailo->{$chatid})) {
		my $braindir = $c->{jabberbot}->{braindir};
		my $brainname = sprintf '%s/%s.sqlite', $braindir, $chatid;

		unless (-d $braindir) {
			make_path ($braindir) or do {
				carp "[ERROR] Unable to create $braindir: $OS_ERROR";
				return;
			};
		}

		$hailo->{$chatid} = Hailo->new (
			brain => $brainname,
			order => 2
		);

		if ($hash{'type'} eq 'groupchat') {
			carp "[INFO] Initialized brain for chat $hash{'reply_to'}: $brainname";
		} else {
			carp "[INFO] Initialized brain for chat $jid{'jid'}: $brainname";
		}
	}

	# parse messages
	my $qname = quotemeta ($bot->{'alias'});

	if ($text =~ /^$qname\,?\s*$/) {
		$reply = 'Чего тебе?';
	} elsif (($text =~ /^$qname[\,|\:]? (.+)/) && ($hash{'type'} eq 'groupchat')) {
		$reply = $hailo->{$chatid}->learn_reply ($1);
	} elsif (substr ($text, 0, 1) eq $c->{jabberbot}->{aleesa}->{csign}) {
		$reply = command (%hash);
	# karma agjustment
	} elsif (substr ($text, -2) eq '++'  ||  substr ($text, -2) eq '--') {
		my @arr = split(/\n/, $text);

		if ($#arr < 1) {
			$reply = karmaSet ($chatid, trim (substr ($text, 0, -2)), substr ($text, -2));
		} else {
			# just message in chat
			# in groupchat we answer only to phrases that mention us
			if ($hash{'type'} eq 'groupchat') {
				$hailo->{$chatid}->learn ($text);
			# in tet-a-tet chat we must always answer, if possible
			} elsif ($hash{'type'} eq 'chat') {
				$reply = $hailo->{$chatid}->learn_reply ($text);
			}
		}
	# just message in chat
	} else {
		# in groupchat we answer only to phrases that mention us
		if ($hash{'type'} eq 'groupchat') {
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


sub run_jabberbot {
	my %conflist = ();
	$conflist{$c->{jabberbot}->{aleesa}->{room}} = [];
	my $qname = quotemeta ($c->{jabberbot}->{aleesa}->{mucname});

	my $bot = Net::Jabber::Bot->new (
		server => $c->{jabberbot}->{aleesa}->{host},
		server_host => $c->{jabberbot}->{aleesa}->{host},
		conference_server => $c->{jabberbot}->{aleesa}->{confsrv},
		tls => 1,
		ssl_verify => 0,
		username => $c->{jabberbot}->{aleesa}->{authname},
# threre is some nasty bug in module, so we have to set from_full explicitly
		from_full => sprintf (
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
			$bot->Start ();
		};
	}

	return;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
