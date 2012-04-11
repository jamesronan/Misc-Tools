#!/usr/bin/perl

# Auto detect the maximum resolution of all connected monitors
# and set them up as one big desktop.

use strict;
use Data::Dump;
use Getopt::Long;

Getopt::Long::GetOptions(
    \my %options,
    'v|verbose+', # Verbosity level - by default, outputs nothing.
    'f|flip',     # By default places monitors in Alphabetical order,
                  # this flag reverses the order.
);

my $xrandr = `which xrandr`;
chomp $xrandr;
if (!$xrandr) {
    print "Unable to locate XRANDR - maybe you forgot to install it?";
    exit;
}

# Ascertain the the screen names of the monitors, and the max resolutions
print "Getting XRANDR output...\n" if $options{v};
my @xrandr_output = `$xrandr`;
print "Got XRANDR output, OK\n" if $options{v};
print "XRANDR Output:\n" . join('', @xrandr_output) . "\n"
    if $options{v} && $options{v} > 1;

my (%monitors, $get_resolution);
print "Parsing XRANDR output...\n" if $options{v};
line:
for (@xrandr_output) {
    next line if /^Screen/; # Skip the virtual screen details.

    if (my ($monitor) = /^ ( [A-Z]{3,4} \d ) \s+ connected /x) {
        print "Found monitor: $monitor\n" if $options{v};
        $get_resolution = $monitor;
        next line;
    }

    # If we saw a monitor name on the previous line, get the resolution
    # from here as xrandr always lists the best resolution first.
    if ($get_resolution) {
        print "Obtaining best res for $get_resolution ... " if $options{v};
        my ($resolution) = /^ \s* (\d{3,4}x\d{3,4}) \s+ /x;
        print "$resolution\n" if $options{v};
        $monitors{$get_resolution} = $resolution;
        undef $get_resolution;
    }
}

print "Got monitors: \n" . Data::Dump::dump(\%monitors) . "\n"
    if $options{v} && $options{v} > 1;

# If there is only one monitor connected, then we need not take action.
if (scalar keys %monitors <= 1) {
    print "Only one monitor found. Doing nothing\n";
    exit;
}

# Now set up the monitors in using xrandr.
my $disposition = ($options{f}) ? '--right-of' : '--left-of';

# Order the displays, backwards if the flip flag was spcified
my @displays = keys %monitors;
if ($options{f}) {
    @displays = reverse @displays;
}

# Now set up the modes.
my @output_modes;
for my $display (@displays) {
    push @output_modes, "--output $display --mode $monitors{$display}";
}

# And the dispositions
my $xrandr_disposition;
my $last_display;
for (@displays) {
    if (!$last_display) {
        $last_display = $_;
        next;
    }

    $xrandr_disposition .= "--output $last_display $disposition $_";
}

my $config_command = "$xrandr "
                   . join (' ', @output_modes)
                   . " $xrandr_disposition";

print "Configuring displays with XRANDR command: $config_command\n"
    if $options{v};

`$config_command`;


