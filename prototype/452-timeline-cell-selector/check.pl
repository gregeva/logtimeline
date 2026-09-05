#!/usr/bin/env perl
# check.pl — prototype driver (#452 trigger (d)): demonstrate that the
# timeline-cell selector distinguishes known-good from known-bad rendering.
#
# Arms:
#   A  offset cross-validation — every visible column's header word falls
#      inside the slice the debug-layout arithmetic computes for it
#   B  known-good bytes column — fill from the bytes colour table, inversion
#      holds, value text carries colour
#   C  sabotage: offsets shifted by +2 — arm A's check and arm B's inversion
#      must both report the damage
#   D  #448 defect classes reproduced inside a column slice:
#        S5 lost colour   — value cell stripped of its foreground
#        S6 twin shades   — two-tone fill flattened to one shade
#        S4 extent        — fill one cell wider than the data supports
#   E  centring predicate (AC5 rule: odd remainder leaves the extra space on
#      the left) against crafted good and bad slices
#
# Usage: perl check.pl <capture-file>
use strict;
use warnings;
use FindBin;
require "$FindBin::Bin/../../tests/lib/rendered-output.pl";
require "$FindBin::Bin/selector.pl";

binmode STDOUT, ':encoding(UTF-8)';
my $capture = shift @ARGV or die "usage: check.pl <capture>\n";
my ( $pass, $fail ) = ( 0, 0 );
sub verdict { my ($ok, $label, $detail) = @_; printf "  %s  %s%s\n", $ok ? 'PASS' : 'FAIL', $label, $detail ? " — $detail" : ''; $ok ? $pass++ : $fail++ }

my $layout = parse_debug_layout($capture);

open my $fh, '<:encoding(UTF-8)', $capture or die $!;
my @lines = <$fh>; close $fh;
my ($header_line) = grep { my $p = $_; $p =~ s/\e\[[0-9;]*m//g; $p =~ /timestamp\s+legend/ } @lines;
my ($data_line)   = grep { my $p = $_; $p =~ s/\e\[[0-9;]*m//g; $p =~ /^\s*\d{4}-\d{2}-\d{2} \d{2}:\d{2}/ } @lines;
die "capture lacks a timeline header or data row\n" unless $header_line && $data_line;

# --- Arm A: header words land inside their computed slices --------------------
my %header_word = ( timestamp => 'timestamp', legend => 'legend',
                    occurrences => 'occurrences', duration => 'duration',
                    bytes => 'bytes', latency => 'latency' );
my $hcells = decode_line($header_line);
for my $col (@$layout) {
    my $want = $header_word{ $col->{id} } or next;
    my $text = row_text( column_slice( $hcells, $layout, $col->{id} ) );
    verdict( ( index( $text, $want ) >= 0 ),
             "A: header '$want' inside computed slice", "slice='$text'" );
}

# --- Arm B: known-good bytes column ------------------------------------------
my $dcells = decode_line($data_line);
my $bytes  = column_slice( $dcells, $layout, 'bytes' );
my $fill   = fill_colour($bytes);
verdict( ( $fill =~ /^(?:256:46|256:34|MIXED:256:34,256:46)$/ ),
         'B: bytes fill drawn from the bytes colour table (46/34)', "fill=$fill" );
my ($viol) = bar_inverts($bytes);
verdict( !@$viol, 'B: bytes bar inverts (black text on fill, coloured text off it)',
         @$viol ? join( '; ', @$viol ) : 'no violations' );
verdict( fill_extent($bytes) > 0 && fill_extent($bytes) <= scalar(@$bytes),
         'B: fill extent within the column width', 'extent=' . fill_extent($bytes) );

# --- Arm C: sabotaged offsets (+2) must be detected ---------------------------
my @shifted = map { { %$_, start => $_->{start} + 2 } } @$layout;
my $btext_good = row_text( column_slice( $hcells, $layout, 'bytes' ) );
my $btext_bad = eval { row_text( column_slice( $hcells, \@shifted, 'bytes' ) ) };
if ( !defined $btext_bad ) {
    ( my $err = $@ ) =~ s/\n.*//s;
    verdict( 1, 'C: +2 offset shift fails loudly past the row end', $err );
}
else {
    verdict( ( index( $btext_bad, 'bytes' ) < 0 || $btext_bad ne $btext_good ),
             'C: +2 offset shift changes what the slice reads', "good='$btext_good' bad='$btext_bad'" );
}
my $bytes_bad = eval { column_slice( $dcells, \@shifted, 'bytes' ) };
if ( !$bytes_bad ) {
    # The shifted slice ran past the row end and the selector died loudly —
    # a wrong offset is a hard failure, never silent garbage.
    ( my $err = $@ ) =~ s/\n.*//s;
    verdict( 1, 'C: shifted slice fails loudly past the row end', $err );
}
else {
    my ($viol_bad) = bar_inverts($bytes_bad);
    my $changed = ( fill_extent($bytes_bad) != fill_extent($bytes) ) || @$viol_bad;
    verdict( $changed, 'C: shifted slice reports different fill facts',
             sprintf( 'extent %d -> %d, violations=%d', fill_extent($bytes), fill_extent($bytes_bad), scalar @$viol_bad ) );
}

# --- Arm D: #448 defect classes inside a column slice -------------------------
# S5 lost colour: strip the value text's foreground. text_colour() reads only
# the UNFILLED portion of the slice, so the arm needs a value that overflows
# the bar; where the fill covers the whole value there is nothing to strip
# (at width 120 the bytes fill covers its value entirely). For the #452
# columns the premise always holds: they render no fill at all.
my @s5 = map { { %$_ } } @$bytes;
$_->{fg} = 'default' for grep { $_->{bg} eq 'default' && $_->{ch} ne ' ' } @s5;
if ( text_colour($bytes) eq 'none' ) {
    printf "  SKIP  D/S5: fill covers the whole value on this row — nothing unfilled to strip\n";
}
else {
    verdict( text_colour( \@s5 ) eq 'none',
             'D/S5: stripped value colour reads none, real value reads a colour',
             'real=' . text_colour($bytes) . ' sabotaged=' . text_colour( \@s5 ) );
}
# S6 twin shades: flatten the two-tone fill to one shade.
my @s6 = map { { %$_ } } @$bytes;
$_->{bg} = '256:46' for grep { $_->{bg} ne 'default' } @s6;
verdict( fill_colour( \@s6 ) ne $fill,
         'D/S6: flattened fill distinguishable from the two-tone fill',
         'real=' . $fill . ' sabotaged=' . fill_colour( \@s6 ) );
# S4 extent: widen the fill by one cell.
my @s4 = map { { %$_ } } @$bytes;
for my $i ( 0 .. $#s4 - 1 ) {
    if ( $s4[$i]{bg} ne 'default' && $s4[ $i + 1 ]{bg} eq 'default' ) {
        $s4[ $i + 1 ]{bg} = $s4[$i]{bg};
        $s4[ $i + 1 ]{fg} = '256:0';
        last;
    }
}
verdict( fill_extent( \@s4 ) == fill_extent($bytes) + 1,
         'D/S4: one-cell overdraw measurable as extent difference',
         'real=' . fill_extent($bytes) . ' sabotaged=' . fill_extent( \@s4 ) );

# --- Arm E: centring predicate -----------------------------------------------
my $mk = sub { [ map { { ch => $_, fg => 'ansi:32', bg => 'default' } } split //, $_[0] ] };
verdict( centred_report( $mk->('  75%  ') ) eq 'centred', 'E: even padding reads centred' );
verdict( centred_report( $mk->('  75% ') )  eq 'centred', 'E: odd remainder, extra space left, reads centred' );
verdict( centred_report( $mk->(' 75%  ') )  ne 'centred', 'E: extra space on the right is flagged',
         centred_report( $mk->(' 75%  ') ) );
verdict( centred_report( $mk->('75%    ') ) ne 'centred', 'E: left-aligned value is flagged',
         centred_report( $mk->('75%    ') ) );

printf "\n%d passed, %d failed\n", $pass, $fail;
exit( $fail ? 1 : 0 );
