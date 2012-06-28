#!/usr/bin/perl

# Quick and dirty Irssi plugin to announce "Morning" to all the channels
# specified in the config var "morning_channels"

use strict;
use Irssi ();

our $VERSION = '0.1';
our %IRSSI = (
	authors     => 'James Ronan',
	contact     => 'james@ronanweb.co.uk',
	url         => 'http://www.ronanweb.co.uk/',
	name        => 'morning',
	description => 'Adds a /morning command to greet multiple channels',
	license     => q(GNU GPLv2 or later),
);

Irssi::settings_add_str('morning', 'morning_channels' => '');
Irssi::command_bind('morning', 'cmd_morning');

sub cmd_morning {
    my ($params, $server, $win_item) = @_;

    if (   !$server
        || !$server->{connected}
        )
    {
        Irssi::print("[morning plugin] Not connected to server");
        return;
    }

    my $morning_message = 'Morning';

    # Parse the params - if we've been asked to "setchannels" then update
    # the setting - else set the message to what was sent.
    my @params = split " ", $params;
    if (@params) {
        if ($params[0] eq 'help') {
            Irssi::print(<<HELP);
[morning plugin] Help:
  /morning                         - broadcasts "Morning" to all configured channels
  /morning Hola peeps!             - broadcasts "Hola peeps!" to all configured channels
  /morning setchannels foo,bar,baz - sets the channel list to #foo, #bar and #baz
  /morning help                    - prints this help message
HELP
            return;

        } elsif ($params[0] eq 'setchannels') {
            Irssi::settings_set_str("morning_channels" => $params[1]);
            Irssi::print('[morning plugin] Channels updated:'
                         . Irssi::settings_get_str('morning_channels'));
            return;

        } else {
            $morning_message = join " ", @params;
        }
    }

    my @channels = split ',', Irssi::settings_get_str('morning_channels');
    if (!@channels) {
        Irssi::print("[morning plugin] No channels configured");
        return;
    }

    # Ok, must be good, send the message.
    for my $channel (@channels) {
        $server->command("MSG #$channel $morning_message");
    }
    return;
}


