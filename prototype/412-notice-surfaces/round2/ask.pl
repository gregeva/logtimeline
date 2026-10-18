#!/usr/bin/env perl
# Round 2, asking: the same three surfaces at each moment a choice arises.
#   row    one row in place of what was there (the progress row), the notice
#          cut to fit beside the question
#   box    a box below the cursor in the category's colour, the question on
#          its last row inside the frame
#   modal  a dialog with two buttons, on the alternate screen over the dimmed
#          run (--screen alt) or below the cursor (--screen inline)
# Each erases itself once answered; the notice and the answer are carried to
# the panel at the end of the run. A notice offering views (the pattern
# moment) leads to a list of them in the same surface.
# Terminal layout only, from fixed content.
#
#   perl round2/ask.pl --moment preread|read|pattern --surface row|box|modal
#        [--screen alt|inline] [--style ltl|new] [--seconds N]
#        [--answer y|n|default[,view]] [--bg dark|light] [--width N] [--height N]

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Getopt::Long;
use Time::HiRes qw(sleep);
use NoticeProto qw(interactive terminal_size style_for set_answers_ahead);
use NoticeSurfaces qw(panel out live_row ask);

my %opt = ( moment => 'read', surface => 'box', screen => 'alt', style => 'ltl', seconds => 10, bg => 'dark' );
GetOptions( \%opt, 'moment=s', 'surface=s', 'screen=s', 'style=s', 'seconds=i', 'answer=s', 'bg=s', 'width=i', 'height=i' )
    or die "bad options\n";
my ( $W, $H ) = terminal_size( width => $opt{width}, height => $opt{height} );
set_answers_ahead( $opt{answer} );
my $s = style_for( $opt{style}, $opt{bg} );
my $sets = do "$FindBin::Bin/../notices/round2.pl" or die "notices/round2.pl: $@ $!\n";
my $live = interactive();
my $green = "\e[92m";
my %common = ( s => $s, W => $W, H => $H, surface => $opt{surface}, screen => $opt{screen}, seconds => $opt{seconds} );
my $how_text = sub { "$_[0]" };

out( '', "$s->{dim}\$ ltl access_log.2025-05-05.txt$s->{reset}", '' );

if ( $opt{moment} eq 'preread' ) {
    my ( $b, $how ) = ask( %common, category => 'your options', notices => $sets->{options},
        question => 'Continue with these options?', buttons => [ 'Continue', 'Stop and correct them' ], default => 0 );
    if ( $b == 1 ) {
        out( "\e[93mStopped before reading: correct the options and run again.\e[0m", '' );
        exit 0;
    }
    progress( 1, 100 );
    finish( [ @{ $sets->{options} }, record( 'your options', "continued with these options ($how)" ) ] );
}
elsif ( $opt{moment} eq 'read' ) {
    progress( 1, 40 );
    my ( $b, $how ) = ask( %common, category => 'runtime condition', notices => [ $sets->{notice}{memory} ],
        question => 'Continue reading?', buttons => [ 'Continue reading', 'Stop here' ], default => 0 );
    my @carry = ( $sets->{notice}{memory}, record( 'runtime condition', ( $b ? 'stopped' : 'continued' ) . " at 40% ($how)" ) );
    if ( $b == 1 ) {
        print "\r\e[2K";
        out( "\e[93mProcessing stopped at 40%.\e[0m" );
        finish( \@carry, 'the figures would cover the lines read so far' );
        exit 0;
    }
    progress( 41, 100 );
    finish( \@carry );
}
else {
    progress( 1, 100 );
    my $n = $sets->{notice}{bimodal};
    my ( $b, $how, $v, $vhow ) = ask( %common, category => 'guidance', notices => [$n],
        question => 'Look at the views on offer?',
        buttons => [ 'Look at the views', 'Continue as planned' ], default => 1,
        views => $n->{views}, view_default => $#{ $n->{views} } );
    my $view = defined $v ? $n->{views}[$v] : undef;
    my @carry = ($n);
    push @carry, record( 'guidance', "view: \l$view->{label} $view->{args} ($vhow)" ) if $view && $view->{args};
    finish( \@carry, $view && $view->{args} ? "the charts would follow, as if given $view->{args}" : undef );
}

sub record { return { category => $_[0], record => 1, statement => $_[1] } }

# The progress line, as paint_progress_line() paints it, then the
# completion rows once it reaches 100%.
sub progress {
    my ( $from, $to ) = @_;
    for my $pct ( $from .. $to ) {
        my $line = int( 14306.78 * $pct );
        1 while $line =~ s/^(\d+)(\d{3})/$1,$2/;
        live_row( "Processing $pct% line $line, 856.2k lines/sec: access_log.2025-05-05.txt", $W );
        sleep 0.02 if $live;
    }
    return unless $to == 100;
    print "\r\e[2K";
    out( "${green}Processing completed.\e[0m", "${green}Calculating statistics completed.\e[0m" );
}

sub finish {
    my ( $carry, $after ) = @_;
    out('');
    out( panel( $carry, $s, $W ) );
    out( '', " $s->{dim}(" . ( $after // 'the timeline would follow' ) . ")$s->{reset}", '' );
}
