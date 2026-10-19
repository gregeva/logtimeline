#!/usr/bin/env perl
# Assertions over a captured surface, read as cells through the repository's
# own decoder (tests/lib/rendered-output.pl), never as escape sequences
# (tests/HARNESS-DESIGN.md § Asserting rendered output). A capture is either a
# redirected run (plain rows) or a tmux pane captured with its attributes
# (`capture-pane -e -p`), which is how an interactive surface is seen.
#
#   assert-surface.pl panes   CAPTURE --side N [--rows N]
#       every box in the capture: each pane (the rows between rules) has N
#       cells of padding inside each side edge and, with --rows, an empty row
#       above and below its content; prints one line per pane; exit 1 on a miss
#   assert-surface.pl unmoved BEFORE AFTER
#       the rows of BEFORE (the screen before a pop-up opened) are at the same
#       rows in AFTER (the screen with the pop-up), outside the pop-up's
#       rectangle; the live progress row is not compared
#   assert-surface.pl no-trace BEFORE AFTER
#       the rows of BEFORE above its live row are the first rows of AFTER: the
#       pop-up left nothing behind
#   assert-surface.pl plain   CAPTURE
#       a redirected run: no escape sequence other than a colour code, the box
#       drawn once, the run continued past it
#
# Exit 0 when the assertion holds; 1 with what differed on standard output.

use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
use Getopt::Long;
require File::Spec->catfile( $FindBin::Bin, '..', '..', '..', 'tests', 'lib', 'rendered-output.pl' );

binmode STDOUT, ':encoding(UTF-8)';
my $mode = shift @ARGV // die "usage: assert-surface.pl panes|unmoved|no-trace|plain ...\n";
my %opt;
GetOptions( \%opt, 'side=i', 'rows=i' ) or die "bad options\n";

sub read_rows {
    my ($file) = @_;
    open my $fh, '<:encoding(UTF-8)', $file or die "$file: $!\n";
    my @rows = map { chomp; $_ } <$fh>;
    close $fh;
    return @rows;
}
sub text_of { my ($row) = @_; my $t = row_text( decode_line($row) ); $t =~ s/\s+\z//; return $t }
sub cells_of { my ($row) = @_; return decode_line($row) }
sub is_blank { my ($t) = @_; return $t !~ /\S/ }

my $fail = 0;
sub miss { print "MISS: @_\n"; $fail = 1 }

if ( $mode eq 'panes' ) {
    my $side = $opt{side} // die "--side N required\n";
    my ($file) = @ARGV;
    my @rows = map { text_of($_) } read_rows($file);
    # Boxes: from a row holding ╭ to the next holding ╰; inside rows hold │ at
    # the box's left column; rules (├) split the panes.
    my $box = 0;
    for ( my $i = 0 ; $i < @rows ; $i++ ) {
        next unless $rows[$i] =~ /╭/;
        my $left = index( $rows[$i], '╭' );
        my $j = $i + 1;
        $j++ while $j < @rows && $rows[$j] !~ /╰/;
        last if $j >= @rows;
        $box++;
        my @inside = @rows[ $i + 1 .. $j - 1 ];
        my ( @panes, @cur );
        for my $r (@inside) {
            if ( substr( $r, $left, 1 ) eq '├' ) { push @panes, [@cur]; @cur = (); next }
            push @cur, $r;
        }
        push @panes, [@cur];
        for my $p ( 0 .. $#panes ) {
            my @pr = @{ $panes[$p] };
            # the content rows: inside the │ edges, the text between them
            my @content;
            for my $r (@pr) {
                my $in = substr( $r, $left + 1 );
                $in =~ s/│\s*\z//;
                push @content, $in;
            }
            my @nonblank = grep { !is_blank( $content[$_] ) } 0 .. $#content;
            my $min_lead = 10_000;
            for my $k (@nonblank) { my ($lead) = $content[$k] =~ /^( *)/; $min_lead = length $lead if length $lead < $min_lead }
            my $top    = @nonblank ? ( $nonblank[0] > 0 ? 1 : 0 ) : 1;
            my $bottom = @nonblank ? ( $nonblank[-1] < $#content ? 1 : 0 ) : 1;
            printf "box %d pane %d: side=%s top=%d bottom=%d rows=%d\n", $box, $p + 1, ( @nonblank ? $min_lead : '-' ), $top, $bottom, scalar @pr;
            miss("box $box pane " . ( $p + 1 ) . ": $min_lead cells inside the left edge, $side expected") if @nonblank && $min_lead != $side;
            if ( $opt{rows} ) {
                miss("box $box pane " . ( $p + 1 ) . ": no empty row above its content") unless $top;
                miss("box $box pane " . ( $p + 1 ) . ": no empty row below its content") unless $bottom;
            }
        }
        $i = $j;
    }
    miss("no box found in $file") unless $box;
}
elsif ( $mode eq 'unmoved' ) {
    my ( $before, $after ) = @ARGV;
    my @b = map { text_of($_) } read_rows($before);
    my @a = map { text_of($_) } read_rows($after);
    # the pop-up's rectangle in AFTER: the rows from ╭ to ╰ and the columns
    # between them
    my ($top) = grep { $a[$_] =~ /╭/ } 0 .. $#a;
    my ($bot) = grep { $a[$_] =~ /╰/ } 0 .. $#a;
    defined $top && defined $bot or do { miss("no pop-up in $after"); exit 1 };
    my $l = index( $a[$top], '╭' );
    my $r = index( $a[$top], '╮' );
    my $compared = 0;
    for my $i ( 0 .. $#b ) {
        next if $b[$i] =~ /^Processing \d+%/;    # the live row, repainted
        next if is_blank( $b[$i] );
        my $want = $b[$i];
        my $got  = $a[$i] // '';
        if ( $i >= $top && $i <= $bot ) {
            # outside the rectangle only
            $want = substr( $want, 0, $l ) . ( ' ' x ( $r - $l + 1 ) ) . ( length $want > $r ? substr( $want, $r + 1 ) : '' );
            $got  = substr( $got, 0, $l ) . ( ' ' x ( $r - $l + 1 ) ) . ( length $got > $r ? substr( $got, $r + 1 ) : '' );
        }
        s/\s+\z// for $want, $got;
        $compared++;
        miss( sprintf "row %d moved: before '%s' / with the pop-up '%s'", $i + 1, substr( $want, 0, 60 ), substr( $got, 0, 60 ) ) if $want ne $got;
    }
    print "compared $compared rows outside the pop-up (rows ", $top + 1, "-", $bot + 1, ", columns ", $l + 1, "-", $r + 1, ")\n";
}
elsif ( $mode eq 'no-trace' ) {
    my ( $before, $after ) = @ARGV;
    my @b = map { text_of($_) } read_rows($before);
    my @a = map { text_of($_) } read_rows($after);
    my ($live) = grep { $b[$_] =~ /^Processing \d+%/ } 0 .. $#b;
    $live //= scalar @b;
    my $compared = 0;
    for my $i ( 0 .. $live - 1 ) {
        $compared++;
        miss( sprintf "row %d differs after the pop-up: '%s' / '%s'", $i + 1, substr( $b[$i], 0, 60 ), substr( $a[$i] // '', 0, 60 ) ) if $b[$i] ne ( $a[$i] // '' );
    }
    my $frames = grep { /[╭╰│]/ } @a;
    miss("$frames box rows remain on screen after the pop-up closed") if $frames;
    # From the live row on, the first rows must be the run's own continuation
    # (its progress or completion rows): anything else there is a trace.
    my @left;
    for my $i ( $live .. $#a ) {
        next if $a[$i] =~ /^Processing \d+%/;    # the live row, stale or repainted
        last if $a[$i] =~ /completed\.|would follow|Stopped/;
        push @left, $a[$i] if !is_blank( $a[$i] );
    }
    miss( scalar(@left) . " rows left where the pop-up was, e.g. '" . substr( $left[0], 0, 60 ) . "'" ) if @left;
    print "compared $compared rows above the live row; box rows left: $frames; rows left in place: ", scalar(@left), "\n";
}
elsif ( $mode eq 'plain' ) {
    my ($file) = @ARGV;
    open my $fh, '<:encoding(UTF-8)', $file or die "$file: $!\n";
    my $raw = do { local $/; <$fh> };
    close $fh;
    my @other = $raw =~ /(\e\[[0-9;?]*[A-Za-ln-z]|\e[^\[])/g;    # any CSI not ending in m, or a non-CSI escape
    miss( scalar(@other) . " escape sequences other than colour codes, e.g. " . join( ' ', map { my $x = $_; $x =~ s/\e/ESC/g; $x } @other[ 0 .. ( @other > 3 ? 2 : $#other ) ] ) ) if @other;
    my @rows = map { text_of($_) } split /\n/, $raw;
    my $boxes = grep { /╭/ } @rows;
    miss("$boxes boxes drawn, one expected") if $boxes != 1;
    my $continued = grep { /completed\.|would follow|[Ss]topped/ } @rows;
    miss("the run did not continue past the surface") unless $continued;
    print "escapes other than colour: ", scalar(@other), "; boxes: $boxes; continued: ", ( $continued ? 'yes' : 'no' ), "\n";
}
else { die "unknown mode '$mode'\n" }
print $fail ? "FAIL\n" : "PASS\n";
exit $fail;
