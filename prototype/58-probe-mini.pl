#!/usr/bin/env perl
#
# 58-probe-mini.pl — message-metric probe placement (#58 A11/D25, coverage
# item 8): fused into the recognition regex vs in-closure probe regexes
# (today's shape) vs index()-guarded probes, measured on metric-bearing
# (dense) and metric-less (sparse) mt1 streams.
#
# Single-pattern recognition (mt1 standard), lines pre-loaded — the P2
# isolation protocol — so the only variable is where the bytes/durationMs/
# count probes run. Masking is identical in every candidate (it cannot be
# fused into a match), and every candidate must produce byte-identical
# (message, bytes, duration, count) to inline on every line.
#
# Candidates:
#   inline    recognition regex; then bytes+duration probes (mt1 branch)
#             and the count probe, exactly today's code
#   fused     one regex: recognition + optional LOOKAHEAD captures per
#             metric anchored at message start (order-independent, lazy
#             .*? for first-occurrence parity) — the A11 "single compiled
#             regex" candidate, implemented as fairly as possible
#   guarded   index() literal pre-check before each probe regex (D25 lead)
#   eq-gate   one index($message,'=') superset gate around the guarded
#             probes — bounds the miss path to a single scan
#
# Usage:
#   perl prototype/58-probe-mini.pl [--runs N] [--verify-only] <fixture> [...]

use strict;
use warnings;
use FindBin;
require "$FindBin::Bin/58-measure.pm";

my $runs = 5;
my $verify_only = 0;
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $opt = shift @ARGV;
    if    ($opt eq '--runs')        { $runs = shift @ARGV; }
    elsif ($opt eq '--verify-only') { $verify_only = 1; }
    else  { die "unknown option $opt\n"; }
}
die "usage: $0 [--runs N] [--verify-only] <fixture> [...]\n" unless @ARGV;

my $MT1 = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;

## fused: same recognition, message captured by lookahead, then one optional
## lookahead per metric — each anchored at message start so capture is
## order-independent; lazy .*? preserves first-occurrence semantics.
my $MT1_FUSED = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (?=(.*))(?:(?=.*? bytes\s*=\s*(\d+)))?(?:(?=.*? durationM[sS]\s*=\s*(\d+)))?(?:(?=.*? count\s*=\s*(\d+)))?/;

## masking, shared verbatim by every candidate (today's code)
sub apply_masks {
    my ($message, $bytes, $duration, $count) = @_;
    if (defined $bytes || defined $duration) {
        $message =~ s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g;
    }
    if (defined $count) {
        $message =~ s/ count\s*=\s*\d+/ count=?/g;
    }
    return $message;
}

## Each runner returns an accumulator; per line it must produce
## (message-after-mask, bytes, duration, count) identical to inline.

sub run_inline {
    my ($lines) = @_;
    my %acc = ( matched => 0, bytes_sum => 0, duration_sum => 0, count_sum => 0, msg_len => 0 );
    for my $line (@$lines) {
        if (my ($ts, $lvl, $obj, $inst, $user, $sess, $plat, $thr, $message) = $line =~ $MT1) {
            my ( $bytes ) = $message =~ / bytes\s*=\s*(\d+)/;
            my ( $duration ) = $message =~ / durationM[sS]\s*=\s*(\d+)/;
            my ( $count ) = $message =~ / count\s*=\s*(\d+)/;
            $message = apply_masks($message, $bytes, $duration, $count);
            $acc{matched}++;
            $acc{bytes_sum}    += $bytes    if defined $bytes;
            $acc{duration_sum} += $duration if defined $duration;
            $acc{count_sum}    += $count    if defined $count;
            $acc{msg_len}      += length $message;
        }
    }
    return \%acc;
}

sub run_fused {
    my ($lines) = @_;
    my %acc = ( matched => 0, bytes_sum => 0, duration_sum => 0, count_sum => 0, msg_len => 0 );
    for my $line (@$lines) {
        if (my ($ts, $lvl, $obj, $inst, $user, $sess, $plat, $thr, $message, $bytes, $duration, $count) = $line =~ $MT1_FUSED) {
            $message = apply_masks($message, $bytes, $duration, $count);
            $acc{matched}++;
            $acc{bytes_sum}    += $bytes    if defined $bytes;
            $acc{duration_sum} += $duration if defined $duration;
            $acc{count_sum}    += $count    if defined $count;
            $acc{msg_len}      += length $message;
        }
    }
    return \%acc;
}

sub run_guarded {
    my ($lines) = @_;
    my %acc = ( matched => 0, bytes_sum => 0, duration_sum => 0, count_sum => 0, msg_len => 0 );
    for my $line (@$lines) {
        if (my ($ts, $lvl, $obj, $inst, $user, $sess, $plat, $thr, $message) = $line =~ $MT1) {
            my ($bytes, $duration, $count);
            ( $bytes ) = $message =~ / bytes\s*=\s*(\d+)/       if index($message, ' bytes') >= 0;
            ( $duration ) = $message =~ / durationM[sS]\s*=\s*(\d+)/ if index($message, ' durationM') >= 0;
            ( $count ) = $message =~ / count\s*=\s*(\d+)/       if index($message, ' count') >= 0;
            $message = apply_masks($message, $bytes, $duration, $count);
            $acc{matched}++;
            $acc{bytes_sum}    += $bytes    if defined $bytes;
            $acc{duration_sum} += $duration if defined $duration;
            $acc{count_sum}    += $count    if defined $count;
            $acc{msg_len}      += length $message;
        }
    }
    return \%acc;
}

sub run_eq_gate {
    my ($lines) = @_;
    my %acc = ( matched => 0, bytes_sum => 0, duration_sum => 0, count_sum => 0, msg_len => 0 );
    for my $line (@$lines) {
        if (my ($ts, $lvl, $obj, $inst, $user, $sess, $plat, $thr, $message) = $line =~ $MT1) {
            my ($bytes, $duration, $count);
            if (index($message, '=') >= 0) {
                ( $bytes ) = $message =~ / bytes\s*=\s*(\d+)/       if index($message, ' bytes') >= 0;
                ( $duration ) = $message =~ / durationM[sS]\s*=\s*(\d+)/ if index($message, ' durationM') >= 0;
                ( $count ) = $message =~ / count\s*=\s*(\d+)/       if index($message, ' count') >= 0;
            }
            $message = apply_masks($message, $bytes, $duration, $count);
            $acc{matched}++;
            $acc{bytes_sum}    += $bytes    if defined $bytes;
            $acc{duration_sum} += $duration if defined $duration;
            $acc{count_sum}    += $count    if defined $count;
            $acc{msg_len}      += length $message;
        }
    }
    return \%acc;
}

## Per-line parity oracle: returns canonical tuple string, or undef if no match.
sub tuple_inline {
    my ($line) = @_;
    if (my (undef, undef, undef, undef, undef, undef, undef, undef, $message) = $line =~ $MT1) {
        my ( $bytes ) = $message =~ / bytes\s*=\s*(\d+)/;
        my ( $duration ) = $message =~ / durationM[sS]\s*=\s*(\d+)/;
        my ( $count ) = $message =~ / count\s*=\s*(\d+)/;
        $message = apply_masks($message, $bytes, $duration, $count);
        return join("\x01", map { $_ // "\x00" } $message, $bytes, $duration, $count);
    }
    return undef;
}

sub tuple_fused {
    my ($line) = @_;
    if (my (undef, undef, undef, undef, undef, undef, undef, undef, $message, $bytes, $duration, $count) = $line =~ $MT1_FUSED) {
        $message = apply_masks($message, $bytes, $duration, $count);
        return join("\x01", map { $_ // "\x00" } $message, $bytes, $duration, $count);
    }
    return undef;
}

sub tuple_guarded {
    my ($line) = @_;
    if (my (undef, undef, undef, undef, undef, undef, undef, undef, $message) = $line =~ $MT1) {
        my ($bytes, $duration, $count);
        ( $bytes ) = $message =~ / bytes\s*=\s*(\d+)/       if index($message, ' bytes') >= 0;
        ( $duration ) = $message =~ / durationM[sS]\s*=\s*(\d+)/ if index($message, ' durationM') >= 0;
        ( $count ) = $message =~ / count\s*=\s*(\d+)/       if index($message, ' count') >= 0;
        $message = apply_masks($message, $bytes, $duration, $count);
        return join("\x01", map { $_ // "\x00" } $message, $bytes, $duration, $count);
    }
    return undef;
}

my @CANDS = (
    [ 'probe-inline',  \&run_inline ],
    [ 'probe-fused',   \&run_fused ],
    [ 'probe-guarded', \&run_guarded ],
    [ 'probe-eq-gate', \&run_eq_gate ],
);

Measure58::tsv_header(\*STDOUT) unless $verify_only;

foreach my $file (@ARGV) {
    (my $fixture = $file) =~ s{.*/}{};
    open my $fh, '<', $file or die "Cannot open file: $file";
    my @lines;
    while (<$fh>) { s/[\r\n]+$//; push @lines, $_; }
    close $fh;

    ## parity gate (eq-gate shares tuple_guarded semantics: the '=' gate is a
    ## superset of every probe literal, so its tuple must equal guarded's)
    my ($div_f, $div_g, $first) = (0, 0);
    my $n = 0;
    for my $line (@lines) {
        $n++;
        my $ti = tuple_inline($line);
        my $tf = tuple_fused($line);
        my $tg = tuple_guarded($line);
        if (($ti // '') ne ($tf // '')) { $div_f++; $first //= "fused line $n"; }
        if (($ti // '') ne ($tg // '')) { $div_g++; $first //= "guarded line $n"; }
    }
    printf STDERR "%s: parity %s (%d lines%s)\n", $fixture,
        ($div_f || $div_g) ? "FAILED fused=$div_f guarded=$div_g (first: $first)" : 'OK',
        $n, ($div_f || $div_g) ? '' : ', fused+guarded byte-identical to inline';
    next if $verify_only;

    for my $cand (@CANDS) {
        my ($name, $runner) = @$cand;
        my $acc;
        my @secs = Measure58::time_runs($runs, sub { $acc = $runner->(\@lines) });
        my ($med, $min, $max) = Measure58::median_min_max(@secs);
        Measure58::emit_tsv(\*STDOUT, $name, $fixture, scalar @lines, 'ns_per_line',
            map { $_ / @lines * 1e9 } $med, $min, $max);
        printf STDERR "  %-14s matched=%d bytes=%s dur=%s count=%s msg_len=%s\n",
            $name, $acc->{matched}, $acc->{bytes_sum}, $acc->{duration_sum}, $acc->{count_sum}, $acc->{msg_len};
    }
}
