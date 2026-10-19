#!/usr/bin/env perl
# Round 4: one driver for the three components of the surface framework, each
# exercised with a named input (notices/inputs.pl); the use cases are data,
# never scripts of their own. The input chooses the moment: the option notices
# are asked before the read, memory during it, the pattern once the
# statistics are done; the panel and the browser come after the run.
#
#   perl show.pl panel   [--input typical|deprecation|heavy] [--bullet N|glyph] [--edge]
#   perl show.pl bullets                                 the bullet glyph sheet
#   perl show.pl ask     --input memory|preread|pattern [--form modal|box]
#                        [--placement alt|inline] [--size small|medium|large]
#                        [--quit on|off] [--keybar full|letters|none] [--record]
#                        [--seconds N] [--answer letter|default[,option]] [--fixed-height]
#   perl show.pl browser [--input heavy] [--placement alt|inline] [--size ...]
#                        [--rows N] [--seconds N]
#   every component:     [--bg dark|light] [--width N] [--height N]
#
# A parameter not given takes the defaults table's value for the use.
# Terminal layout only, from fixed content; nothing here runs ltl.

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use Time::HiRes qw(sleep);
use NoticeProto qw(interactive terminal_size style_for set_answers_ahead ltl_constants);
use NoticeSurfaces qw(panel bullet_candidates bullet_sheet ask browser out live_row);

my $component = shift(@ARGV) // '';
$component =~ /^(panel|bullets|ask|browser)$/ or die "usage: show.pl panel|bullets|ask|browser [options]\n";
my %opt = ( bg => 'dark' );
GetOptions( \%opt, 'input=s', 'bullet=s', 'edge', 'form=s', 'placement=s', 'size=s', 'quit=s', 'keybar=s', 'record', 'seconds=i',
    'answer=s', 'rows=i', 'fixed-height', 'bg=s', 'width=i', 'height=i' ) or die "bad options\n";
my ( $W, $H ) = terminal_size( width => $opt{width}, height => $opt{height} );
set_answers_ahead( $opt{answer} );
my $s      = style_for( 'new', $opt{bg} );
my $inputs = do "$FindBin::Bin/notices/inputs.pl"   or die "notices/inputs.pl: $@ $!\n";
my $bd     = do "$FindBin::Bin/notices/backdrop.pl" or die "notices/backdrop.pl: $@ $!\n";
my $live   = interactive();
my %param  = map { $_ => $opt{$_} } grep { defined $opt{$_} } qw(form placement size keybar seconds rows);
$param{quit}   = $opt{quit} eq 'on' ? 1 : 0 if defined $opt{quit};
$param{record} = 1 if $opt{record};
$param{fixed_height} = 1 if $opt{'fixed-height'};

my $input_name = $opt{input} // { panel => 'typical', bullets => 'typical', ask => 'memory', browser => 'heavy' }->{$component};
my $in = $inputs->{$input_name} or die "no input '$input_name'\n";

# --- the run around the surface ----------------------------------------------

sub backdrop {
    out( @{ $bd->{before_prompt} }, $bd->{prompt}->('ltl access_log.2025-05-05.txt'), split( /\n/, ltl_constants()->{title} ), '', @{ $bd->{scanning} } );
}

sub progress {
    my ( $from, $to ) = @_;
    for my $pct ( $from .. $to ) {
        live_row( $bd->{progress}->($pct), $W );
        sleep 0.02 if $live;
    }
    return unless $to == 100;
    print "\r\e[2K";
    out( @{ $bd->{completed} } );
}

sub finish {
    my ($after) = @_;
    out( '', " $s->{dim}(" . ( $after // 'the timeline would follow' ) . ")$s->{reset}", '' );
}

# q/x: the surface is cleared and the run stops cleanly.
sub quit_run {
    out( '', "$s->{dim}Stopped: the analyst quit (q/x).$s->{reset}", '' );
    exit 0;
}

# --- the components ----------------------------------------------------------

if ( $component eq 'panel' ) {
    backdrop();
    progress( 1, 100 );
    my $bullet = $opt{bullet};
    $bullet = ( bullet_candidates() )[ $bullet - 1 ][0] if defined $bullet && $bullet =~ /^\d+$/;
    out( '', panel( s => $s, W => $W, notices => $in->{notices}, bullet => $bullet, form => $opt{edge} ? 'edge' : 'headed' ) );
    finish();
}
elsif ( $component eq 'bullets' ) {
    out( '', bullet_sheet( s => $s, W => $W, notices => $in->{notices} ), '' );
}
elsif ( $component eq 'ask' ) {
    backdrop();
    my %ask = ( s => $s, W => $W, H => $H, %param, map { $_ => $in->{$_} } grep { defined $in->{$_} } qw(category notices question buttons options option_default) );
    if ( $input_name eq 'preread' ) {
        my ( $role, $how ) = ask(%ask);
        quit_run() if $role eq 'quit';
        if ( $role eq 'stop' ) { out( "\e[93mStopped before reading: correct the options and run again.\e[0m", '' ); exit 0 }
        progress( 1, 100 );
        finish();
    }
    elsif ( $input_name eq 'memory' ) {
        progress( 1, 40 );
        my ( $role, $how ) = ask(%ask);
        quit_run() if $role eq 'quit';
        if ( $role eq 'stop' ) {
            print "\r\e[2K";
            out("\e[93mProcessing stopped at 40%.\e[0m");
            finish('the figures would cover the lines read so far');
            exit 0;
        }
        progress( 41, 100 );
        finish();
    }
    else {
        progress( 1, 100 );
        my ( $role, $how, $oi ) = ask(%ask);
        quit_run() if $role eq 'quit';
        my $o = defined $oi ? $in->{options}[$oi] : undef;
        finish( $o && $o->{args} ? "the charts would follow, as if given $o->{args}" : undef );
    }
}
else {
    backdrop();
    progress( 1, 100 );
    print "\n";
    my $chosen = browser( s => $s, W => $W, H => $H, %param, notices => $in->{notices} );
    quit_run() if !ref $chosen && $chosen eq 'quit';
    my @args = grep { $_ ne '' } map { $_->[0]{options}[ $_->[1] ]{args} } @$chosen;
    finish( @args ? 'the timeline would follow, as if given ' . join( ' ', @args ) : undef );
}
