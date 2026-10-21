#!/usr/bin/env perl
# surface-capture.pl — assertions over a captured notice surface, read as
# cells through tests/lib/rendered-output.pl, never as escape sequences
# (tests/HARNESS-DESIGN.md § Asserting rendered output). A capture is a
# redirected run (plain rows) or a tmux pane captured with its attributes
# (`capture-pane -e -p`), how an interactive surface is seen.
#
#   surface-capture.pl panes    CAPTURE --side N [--rows]
#       every box in the capture: each pane (the rows between rules) has N
#       cells of padding inside its left edge and, with --rows, an empty row
#       above and below its content
#   surface-capture.pl unmoved  BEFORE WITH [--upto N]
#       the rows of BEFORE (the first N, with --upto) are at the same rows in
#       WITH (the screen with a pop-up), outside the pop-up's rectangle
#   surface-capture.pl no-trace BEFORE AFTER --upto N
#       the first N rows of BEFORE are the first N rows of AFTER, and no box row
#       remains in AFTER: the pop-up left nothing behind
#   surface-capture.pl plain    CAPTURE --boxes N
#       a redirected run: no escape sequence but colour codes, N boxes drawn
#       once, and the run went on past them to its summary
#
# Prints what it compared; exit 0 when the assertion holds, 1 with each miss.
# The predicates were shown to tell a known-good build from the defect each is
# for in prototype/412-notice-surfaces/findings.md § Unattended capture.

use strict;
use warnings;
use utf8;
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long;
require( File::Spec->rel2abs( dirname(__FILE__) . '/rendered-output.pl' ) );

binmode STDOUT, ':encoding(UTF-8)';
my $mode = shift @ARGV // die "usage: surface-capture.pl panes|unmoved|no-trace|plain ...\n";
my %opt;
GetOptions( \%opt, 'side=i', 'rows', 'upto=i', 'boxes=i' ) or exit 2;

sub read_rows {
    my ($file) = @_;
    open my $fh, '<:encoding(UTF-8)', $file or die "$file: $!\n";
    my @rows = map { chomp; $_ } <$fh>;
    close $fh;
    return @rows;
}
sub text_of { my ($row) = @_; my $t = row_text( decode_line($row) ); $t =~ s/\s+\z//; return $t }
sub is_blank { return $_[0] !~ /\S/ }

my $fail = 0;
sub miss { print "MISS: @_\n"; $fail = 1 }

if ( $mode eq 'panes' ) {
    my $side = $opt{side} // die "--side N required\n";
    my ($file) = @ARGV;
    my @rows = map { text_of($_) } read_rows($file);
    my $box = 0;
    for ( my $i = 0 ; $i < @rows ; $i++ ) {
        next unless $rows[$i] =~ /╭/;
        my $left = index( $rows[$i], '╭' );
        my $j = $i + 1;
        $j++ while $j < @rows && $rows[$j] !~ /╰/;
        last if $j >= @rows;
        $box++;
        my ( @panes, @cur );
        for my $r ( @rows[ $i + 1 .. $j - 1 ] ) {
            if ( length $r > $left && substr( $r, $left, 1 ) eq '├' ) { push @panes, [@cur]; @cur = (); next }
            my $in = length $r > $left ? substr( $r, $left + 1 ) : '';
            $in =~ s/│\s*\z//;
            push @cur, $in;
        }
        push @panes, [@cur];
        for my $p ( 0 .. $#panes ) {
            my @content = @{ $panes[$p] };
            my @nonblank = grep { !is_blank( $content[$_] ) } 0 .. $#content;
            my $lead = 10_000;
            for my $k (@nonblank) { my ($l) = $content[$k] =~ /^( *)/; $lead = length $l if length $l < $lead }
            my $top    = @nonblank && $nonblank[0] > 0 ? 1 : 0;
            my $bottom = @nonblank && $nonblank[-1] < $#content ? 1 : 0;
            printf "box %d pane %d: side=%s top=%d bottom=%d\n", $box, $p + 1, ( @nonblank ? $lead : '-' ), $top, $bottom;
            miss( "box $box pane " . ( $p + 1 ) . ": $lead cells inside the left edge, $side expected" ) if @nonblank && $lead != $side;
            if ( $opt{rows} ) {
                miss( "box $box pane " . ( $p + 1 ) . ': no empty row above its content' ) unless $top;
                miss( "box $box pane " . ( $p + 1 ) . ': no empty row below its content' ) unless $bottom;
            }
        }
        $i = $j;
    }
    miss("no box found in $file") unless $box;
}
elsif ( $mode eq 'unmoved' ) {
    my ( $before, $with ) = @ARGV;
    my @b = map { text_of($_) } read_rows($before);
    my @a = map { text_of($_) } read_rows($with);
    @b = @b[ 0 .. $opt{upto} - 1 ] if $opt{upto} && @b > $opt{upto};
    my ($top) = grep { $a[$_] =~ /╭/ } 0 .. $#a;
    my ($bot) = grep { $a[$_] =~ /╰/ } 0 .. $#a;
    defined $top && defined $bot or do { miss("no pop-up in $with"); print "FAIL\n"; exit 1 };
    my $l = index( $a[$top], '╭' );
    my $r = index( $a[$top], '╮' );
    my $compared = 0;
    for my $i ( 0 .. $#b ) {
        next if is_blank( $b[$i] );
        my ( $want, $got ) = ( $b[$i], $a[$i] // '' );
        if ( $i >= $top && $i <= $bot ) {
            $_ = substr( $_ . ( ' ' x $r ), 0, $l ) . ( ' ' x ( $r - $l + 1 ) ) . ( length $_ > $r ? substr( $_, $r + 1 ) : '' ) for $want, $got;
        }
        s/\s+\z// for $want, $got;
        $compared++;
        miss( sprintf "row %d moved: before '%s' / with the pop-up '%s'", $i + 1, substr( $want, 0, 60 ), substr( $got, 0, 60 ) ) if $want ne $got;
    }
    miss('nothing compared') unless $compared;
    print "compared $compared rows outside the pop-up (rows ", $top + 1, '-', $bot + 1, ")\n";
}
elsif ( $mode eq 'no-trace' ) {
    my ( $before, $after ) = @ARGV;
    my $upto = $opt{upto} // die "--upto N required\n";
    my @b = map { text_of($_) } read_rows($before);
    my @a = map { text_of($_) } read_rows($after);
    for my $i ( 0 .. $upto - 1 ) {
        miss( sprintf "row %d differs after the pop-up: '%s' / '%s'", $i + 1, substr( $b[$i] // '', 0, 60 ), substr( $a[$i] // '', 0, 60 ) )
            if ( $b[$i] // '' ) ne ( $a[$i] // '' );
    }
    my $frames = grep { /[╭╰]/ } @a;
    miss("$frames box rows remain on screen after the pop-up closed") if $frames;
    print "compared $upto rows; box rows left: $frames\n";
}
elsif ( $mode eq 'plain' ) {
    my ($file) = @ARGV;
    open my $fh, '<:encoding(UTF-8)', $file or die "$file: $!\n";
    my $raw = do { local $/; <$fh> };
    close $fh;
    my @other = $raw =~ /(\e\[[0-9;?]*[A-Za-ln-z]|\e[^\[])/g;
    miss( scalar(@other) . ' escape sequences other than colour codes, e.g. ' . join( ' ', map { ( my $x = $_ ) =~ s/\e/ESC/g; $x } @other[ 0 .. ( @other > 3 ? 2 : $#other ) ] ) ) if @other;
    my @rows = map { text_of($_) } split /\n/, $raw;
    my $boxes = grep { /╭/ } @rows;
    my $want = $opt{boxes} // 1;
    miss("$boxes boxes drawn, $want expected") if $boxes != $want;
    my $continued = grep { /^\s*LINES READ\s/ } @rows;
    miss('the run did not go on past the surface to its summary') unless $continued;
    print 'escapes other than colour: ', scalar(@other), "; boxes: $boxes; continued: ", ( $continued ? 'yes' : 'no' ), "\n";
}
else { print STDERR "unknown mode '$mode'\n"; exit 2 }
print $fail ? "FAIL\n" : "PASS\n";
exit $fail;
