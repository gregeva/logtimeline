#!/usr/bin/env perl
# P4: a choice raised in two stages once statistical analysis has detected a
# pattern, after the data work and before the charts are drawn. Stage one is a
# yes or no that defaults after a few seconds to continuing as planned; only a
# yes leads to stage two, the views on offer.
# Terminal layout only, from fixed content.
#
#   perl p4-pattern-choice.pl [--selector list|keys] [--form lines|boxes]
#        [--style ltl|new] [--seconds N] [--answer y,2 | n | default]
#        [--glyphs symbol|emoji|ascii] [--bg dark|light] [--width N]
#
#   list  the views as a vertical list: arrow keys or 1-3 move, Enter
#         chooses, Esc continues as planned; the highlighted view's effect is
#         shown beneath
#   keys  the views on one row, chosen by a single digit; Enter continues as
#         planned

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use NoticeProto qw(interactive terminal_size style_for display_width timed_yes_no
                   set_answers_ahead answer_ahead read_key raw_mode restore_mode categories);
use NoticeForms qw(set_glyphs glyph_of %render);

my %opt = ( selector => 'list', form => 'boxes', style => 'ltl', seconds => 5, glyphs => 'symbol', bg => 'dark' );
GetOptions( \%opt, 'selector=s', 'form=s', 'style=s', 'seconds=i', 'answer=s', 'glyphs=s', 'bg=s', 'width=i' )
    or die "bad options\n";
my ($W) = terminal_size( width => $opt{width} );
set_glyphs( $opt{glyphs} );
set_answers_ahead( $opt{answer} );

my $s = style_for( $opt{style}, $opt{bg} );
my ($cat) = grep { $_->{name} eq 'guidance' } categories();
my $fg = $s->{fg}{guidance};
my $green = "\e[92m";

my $sets = do "$FindBin::Bin/notices/sets.pl" or die "notices/sets.pl: $@ $!\n";
my $pattern = { %{ $sets->{notice}{bimodal} } };
delete $pattern->{remedy};    # the views on offer take the remedy's place

my @views = (
    { label => 'Sort the messages by bimodality', args => '-so bimodality_coef',
      effect => 'this API comes first in the messages table, with any other whose durations split the same way' },
    { label => 'Isolate this API, with its histogram', args => '-i QueryStreamEntries -hg',
      effect => "only this API's lines are kept, and the two populations are drawn as a histogram of its durations" },
    { label => 'Continue as planned', args => '',
      effect => 'the charts are drawn with the options given' },
);
my $default_view = $#views;

print "\n$green", 'Processing completed.', "\e[0m\n";
print "$green", 'Calculating statistics completed.', "\e[0m\n\n";

# Stage one.
print "$_\n" for $render{ $opt{form} }->( [$pattern], $s, $W );
my ($look) = timed_yes_no( style => $s, question => ' ' . ( @views - 1 ) . ' views might change what this run shows. Look at them?',
    default => 'n', seconds => $opt{seconds}, yes => 'looking', no => 'continuing as planned' );

my ( $chosen, $how ) = ( $default_view, 'stage one declined' );
( $chosen, $how ) = $opt{selector} eq 'keys' ? choose_by_key() : choose_from_list() if $look eq 'y';

my $v = $views[$chosen];
print ' ', $fg, glyph_of($cat), $s->{reset}, ' ', $s->{text}, 'view: ', $s->{reset}, $s->{bold}, $v->{label}, $s->{reset},
    ( $v->{args} ? " $fg($v->{args})$s->{reset}" : '' ), " $s->{dim}($how)$s->{reset}\n";
print "\n $s->{dim}(the charts would follow"
    . ( $v->{args} ? ", as if given $v->{args}" : '' ) . ")$s->{reset}\n\n";

# --- stage two: a vertical list ---------------------------------------------

sub list_rows {
    my ($sel) = @_;
    my @rows = ( ' ' . $s->{bold} . 'Choose a view' . $s->{reset} . '  ' . $s->{dim}
        . '↑↓ move · Enter choose · 1-' . scalar(@views) . ' jump · Esc continue as planned' . $s->{reset} );
    for my $i ( 0 .. $#views ) {
        my $v = $views[$i];
        my $text = sprintf '%d  %-40s %s', $i + 1, $v->{label}, $v->{args};
        if ( $i == $sel ) {
            push @rows, "  $fg▶$s->{reset} " . ( $s->{name} eq 'ltl' ? "\e[7m $text \e[27m" : "$s->{bold}$fg $text $s->{reset}" ) . $s->{reset};
        }
        else {
            push @rows, "    $s->{text} $text $s->{reset}";
        }
    }
    push @rows, "      $s->{dim}" . $views[$sel]{effect} . $s->{reset};
    return @rows;
}

sub choose_from_list {
    my $given = answer_ahead();
    if ( defined $given || !interactive() ) {
        my $i = defined $given && $given =~ /^\d+$/ && $given >= 1 && $given <= @views ? $given - 1 : $default_view;
        return ( $i, defined $given ? 'given ahead' : 'default, no terminal' );
    }
    my $sel = 0;
    my @rows = list_rows($sel);
    print "$_\n" for @rows;
    raw_mode('cbreak');
    print "\e[?25l";
    my ( $i, $how );
    while (1) {
        my $k = read_key();
        next unless defined $k;
        if    ( $k eq 'up' )    { $sel = ( $sel - 1 ) % @views }
        elsif ( $k eq 'down' )  { $sel = ( $sel + 1 ) % @views }
        elsif ( $k =~ /^[1-9]$/ && $k <= @views ) { $sel = $k - 1 }
        elsif ( $k eq 'enter' ) { ( $i, $how ) = ( $sel, 'key' ); last }
        elsif ( $k eq 'esc' || $k eq 'q' ) { ( $i, $how ) = ( $default_view, 'Esc' ); last }
        else { next }
        # Redraw the list in place.
        printf "\e[%dA\r", scalar @rows;
        @rows = list_rows($sel);
        print "\e[2K$_\n" for @rows;
    }
    restore_mode();
    # The list collapses: the row recording the choice takes its place.
    printf "\e[%dA\r\e[J", scalar @rows;
    return ( $i, $how );
}

# --- stage two: one row, a digit ------------------------------------------

sub choose_by_key {
    my $given = answer_ahead();
    if ( defined $given || !interactive() ) {
        my $i = defined $given && $given =~ /^\d+$/ && $given >= 1 && $given <= @views ? $given - 1 : $default_view;
        return ( $i, defined $given ? 'given ahead' : 'default, no terminal' );
    }
    my $row = ' ' . join( '  ', map { "$s->{bold}$fg\[" . ( $_ + 1 ) . "]$s->{reset} $s->{text}" . lc( $views[$_]{label} ) . $s->{reset} } 0 .. $#views )
        . "   $s->{dim}1-" . scalar(@views) . ', Enter: ' . ( $default_view + 1 ) . $s->{reset};
    print $row;
    raw_mode('cbreak');
    my ( $i, $how );
    while (1) {
        my $k = read_key();
        next unless defined $k;
        if ( $k =~ /^[1-9]$/ && $k <= @views ) { ( $i, $how ) = ( $k - 1, 'key' ); last }
        if ( $k eq 'enter' || $k eq 'esc' )    { ( $i, $how ) = ( $default_view, $k eq 'esc' ? 'Esc' : 'Enter' ); last }
    }
    restore_mode();
    print "\r\e[2K";
    return ( $i, $how );
}
