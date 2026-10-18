#!/usr/bin/env perl
# Asking: one surface for a question raised during the run, called at each
# moment with that moment's notices and choices.
#   modal  a dialog with two buttons, on the alternate screen over the dimmed
#          run (--screen alt) or below the cursor (--screen inline)
#   box    the compact form: a box below the cursor in the category's colour,
#          the question on its last row inside the frame
# Once answered it is erased and leaves no trace; --record leaves the notice
# and the answer as inline text instead. A notice offering views (the
# pattern moment) leads to a list of them in the same surface.
# Terminal layout only, from fixed content.
#
#   perl surfaces/ask.pl --moment preread|read|pattern [--surface modal|box]
#        [--screen alt|inline] [--record] [--style new|ltl] [--seconds N]
#        [--answer y|n|default[,view]] [--bg dark|light] [--width N] [--height N]

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Getopt::Long;
use Time::HiRes qw(sleep);
use NoticeProto qw(interactive terminal_size style_for set_answers_ahead);
use NoticeSurfaces qw(out live_row ask);

my %opt = ( moment => 'read', surface => 'modal', screen => 'alt', style => 'new', seconds => 10, bg => 'dark' );
GetOptions( \%opt, 'moment=s', 'surface=s', 'screen=s', 'record', 'style=s', 'seconds=i', 'answer=s', 'bg=s', 'width=i', 'height=i' )
    or die "bad options\n";
my ( $W, $H ) = terminal_size( width => $opt{width}, height => $opt{height} );
set_answers_ahead( $opt{answer} );
my $s = style_for( $opt{style}, $opt{bg} );
my $sets = do "$FindBin::Bin/../notices/round2.pl" or die "notices/round2.pl: $@ $!\n";
my $live = interactive();
my $green = "\e[92m";
my %common = ( s => $s, W => $W, H => $H, surface => $opt{surface}, screen => $opt{screen}, seconds => $opt{seconds},
    record => $opt{record} );

out( '', "$s->{dim}\$ ltl access_log.2025-05-05.txt$s->{reset}", '' );

if ( $opt{moment} eq 'preread' ) {
    my ($b) = ask( %common, category => 'your options', notices => $sets->{options},
        question => 'Continue with these options?', buttons => [ 'Continue', 'Stop and correct them' ], default => 0 );
    if ( $b == 1 ) {
        out( "\e[93mStopped before reading: correct the options and run again.\e[0m", '' );
        exit 0;
    }
    progress( 1, 100 );
    finish();
}
elsif ( $opt{moment} eq 'read' ) {
    progress( 1, 40 );
    my ($b) = ask( %common, category => 'runtime condition', notices => [ $sets->{notice}{memory} ],
        question => 'Continue reading?', buttons => [ 'Continue reading', 'Stop here' ], default => 0 );
    if ( $b == 1 ) {
        print "\r\e[2K";
        out( "\e[93mProcessing stopped at 40%.\e[0m" );
        finish('the figures would cover the lines read so far');
        exit 0;
    }
    progress( 41, 100 );
    finish();
}
else {
    progress( 1, 100 );
    my $n = $sets->{notice}{bimodal};
    my ( $b, $how, $v ) = ask( %common, category => 'guidance', notices => [$n],
        question => 'Look at the views on offer?',
        buttons => [ 'Look at the views', 'Continue as planned' ], default => 1,
        views => $n->{views}, view_default => $#{ $n->{views} } );
    my $view = defined $v ? $n->{views}[$v] : undef;
    finish( $view && $view->{args} ? "the charts would follow, as if given $view->{args}" : undef );
}

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
    my ($after) = @_;
    out( '', " $s->{dim}(" . ( $after // 'the timeline would follow' ) . ")$s->{reset}", '' );
}
