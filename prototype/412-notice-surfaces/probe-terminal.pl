#!/usr/bin/env perl
# What can be learned about the terminal that draws the output, from the
# program's side: the environment it was given, the terminal's own answers to
# identity and colour queries, and the width it gives each glyph the surfaces
# draw. Over SSH the environment is the remote host's and says little about
# the terminal; the answers to queries come from the terminal itself, wherever
# the program runs. Ends with a sample of the frame and the bullets, to be
# looked at, since whether lines join is visible only on the screen.
#
#   perl probe-terminal.pl --label NAME     writes terminals/NAME.json
#
# Run in the terminal being probed, not through a pipe.

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use JSON::PP;
use Term::ReadKey;
use NoticeProto qw(raw_mode restore_mode);

binmode STDOUT, ':encoding(UTF-8)';
$| = 1;

my %opt;
GetOptions( \%opt, 'label=s' ) or die "usage: perl probe-terminal.pl --label NAME\n";
die "usage: perl probe-terminal.pl --label NAME\n" unless $opt{label} && $opt{label} =~ /^[\w.-]+$/;
die "run this in a terminal: standard input and output must both be one\n" unless -t STDIN && -t STDOUT;

my @env = qw(TERM COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION LC_TERMINAL LC_TERMINAL_VERSION
    LANG LC_ALL LC_CTYPE VTE_VERSION WT_SESSION KITTY_WINDOW_ID WEZTERM_EXECUTABLE TMUX STY SSH_TTY);

# The terminal's answer to a query, read up to the reply to the primary device
# attributes request sent after it: every terminal answers that one, so a
# query the terminal ignores costs no timeout.
sub ask {
    my ($query) = @_;
    print $query, "\e[c";
    my ( $buf, $t0 ) = ( '', time );
    while ( time - $t0 < 3 ) {
        my $c = ReadKey(0.5);
        next unless defined $c;
        $buf .= $c;
        last if $buf =~ /\e\[\?[\d;]*c\z/;
    }
    $buf =~ s/\e\[\?[\d;]*c\z//;
    return printable($buf);
}

sub printable {
    my ($s) = @_;
    $s =~ s/\e/ESC/g;
    $s =~ s/\a/BEL/g;
    $s =~ s/([\x00-\x1f\x7f])/sprintf('\\x%02X', ord $1)/ge;
    return $s;
}

# The cells the terminal advances for a glyph: printed at the start of a
# cleared row, then the cursor position report.
sub width_of {
    my ($g) = @_;
    print "\r\e[K", $g, "\e[6n";
    my ( $buf, $t0 ) = ( '', time );
    while ( time - $t0 < 3 ) {
        my $c = ReadKey(0.5);
        next unless defined $c;
        $buf .= $c;
        last if $buf =~ /\e\[\d+;\d+R\z/;
    }
    print "\r\e[K";
    return $buf =~ /\e\[\d+;(\d+)R\z/ ? $1 - 1 : undef;
}

# Every glyph the surfaces draw on any platform, the bullet candidates among
# them (docs/design-language.md, docs/terminal-output.md § Glyphs and width).
my @glyphs = (
    qw(⚠ ≈ ⚙ ↻ ⏱ ➤ ▲ △ ⛭ ⧖ ►),
    qw(╶ — ‒ – ·),
    qw(─ │ ╭ ╮ ╰ ╯ ├ ┤ ━ ┃ ┣ ┫ ┳ ┻ ┗ ┛ ╋),
    qw(▶ ◇ √ → ← ↑ ↓ … ▂ ▃ ▇ █),
);

my %r = ( label => $opt{label}, os => $^O, time => scalar gmtime . ' UTC' );
$r{env}{$_} = $ENV{$_} for grep { defined $ENV{$_} } @env;
$r{ssh} = defined $ENV{SSH_CONNECTION} ? 1 : 0;

raw_mode('raw');
$r{answers} = {
    'secondary device attributes (CSI > c)'  => ask("\e[>c"),
    'terminal name and version (CSI > 0 q)'  => ask("\e[>0q"),
    'foreground colour (OSC 10)'             => ask("\e]10;?\e\\"),
    'background colour (OSC 11)'             => ask("\e]11;?\e\\"),
};
# The primary attributes, asked alone: ask() uses them as its sentinel.
print "\e[c";
{
    my ( $buf, $t0 ) = ( '', time );
    while ( time - $t0 < 3 ) { my $c = ReadKey(0.5); next unless defined $c; $buf .= $c; last if $buf =~ /c\z/ }
    $r{answers}{'primary device attributes (CSI c)'} = printable($buf);
}
$r{widths}{$_} = width_of($_) for @glyphs;
restore_mode();

my $dir = "$FindBin::Bin/terminals";
mkdir $dir unless -d $dir;
open my $fh, '>:raw', "$dir/$opt{label}.json" or die "cannot write $dir/$opt{label}.json: $!\n";
print $fh JSON::PP->new->utf8->canonical->pretty->encode( \%r );
close $fh;

print "Terminal probe: $opt{label}\n\n";
printf "  %-40s %s\n", "$_:", $r{env}{$_} for sort keys %{ $r{env} };
printf "  %-40s %s\n", 'ssh:', $r{ssh} ? 'yes' : 'no';
print "\n";
printf "  %-40s %s\n", "$_:", ( length $r{answers}{$_} ? $r{answers}{$_} : '(no answer)' ) for sort keys %{ $r{answers} };
my @wide = grep { ( $r{widths}{$_} // -1 ) != 1 } @glyphs;
print "\n  glyphs not one cell: ", ( @wide ? join( '  ', map { "$_=" . ( $r{widths}{$_} // '?' ) } @wide ) : 'none' ), "\n";

# What only the eye can judge: the frame as the surfaces draw it (colour 90),
# then plain, then bold; the bullets after a category glyph.
print "\n  The frame, as drawn (grey), plain, bold:\n\n";
for my $sgr ( "\e[90m", '', "\e[1m" ) {
    print "  $sgr╭─ notices (7) ", '─' x 31, "╮\e[0m\n";
    print "  $sgr│\e[0m", ' ' x 45, "$sgr│\e[0m\n" for 1 .. 2;
    print "  $sgr├", '─' x 45, "┤\e[0m\n";
    print "  $sgr╰─ ←→ Tab: move ", '─' x 30, "╯\e[0m\n\n";
}
print "  The bullets:\n\n";
print "  \e[38;5;208m⚠ DATA ANOMALY\e[0m\n";
printf "  \e[38;5;208m%s\e[0m \e[37m%s\e[0m\n", $_->[0], "$_->[1], a notice under the heading" for
    [ '╶', 'U+2576 box drawings light right' ], [ '—', 'U+2014 em dash' ], [ '‒', 'U+2012 figure dash' ], [ '–', 'U+2013 en dash' ];
print "\n  Written to terminals/$opt{label}.json\n";
