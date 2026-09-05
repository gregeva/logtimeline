#!/usr/bin/env perl
#
# #432 — per-line cost of the bytes parity capture, at both scopes.
#
# Measures candidate shapes for adding bytes_occurrences / bytes_min / bytes_max
# against the production code as baseline. The baseline arms are the accumulation
# blocks sliced out of `ltl` by extract-blocks.sh, so what is compared is the real
# call structure and not a convenience rewrite of it (#58 F9).
#
# Design: order-balanced ABBA over N pairs, medians with ranges. #447 proved that
# single-order interleaving is insufficient for effects of this size — the same
# code measured +0.44% and +1.99% in different sessions because within-arm spread
# exceeded the effect (see tests/profile/results/447-control-char-normalisation/
# analysis.md § Method).
#
# Usage:
#   ./bytes-capture-cost.pl [--lines N] [--pairs N] [--keys N] [--buckets N]

use strict;
use warnings;
use Time::HiRes qw(time);
use List::Util qw(min max);

my %opt = ( lines => 1_000_000, pairs => 8, keys => 20_000, buckets => 1_440 );
while (@ARGV) {
    my $a = shift @ARGV;
    if    ($a eq '--lines')   { $opt{lines}   = shift @ARGV }
    elsif ($a eq '--pairs')   { $opt{pairs}   = shift @ARGV }
    elsif ($a eq '--keys')    { $opt{keys}    = shift @ARGV }
    elsif ($a eq '--buckets') { $opt{buckets} = shift @ARGV }
    else { die "unknown option: $a\n" }
}

# ---------------------------------------------------------------------------
# Input generation.
#
# Deterministic, seeded, and shaped like the reference access log: a heavy-tailed
# message-key distribution, bytes values spanning several decades, and a fraction
# of matched lines carrying NO bytes value at all.
#
# That last property is load-bearing. It is the condition under which the shipped
# mean_bytes is wrong (F1), and #447's lesson 2 applies: a probe that reports zero
# must be shown capable of reporting non-zero. A fixture where every line carries
# bytes cannot exhibit the defect the parity work fixes.
# ---------------------------------------------------------------------------

srand(4321);

my $NO_BYTES_FRACTION = 0.15;   # matched lines with no bytes field

my (@key_of, @bucket_of, @bytes_of);
{
    # Zipf-ish key selection: a few very hot keys, a long tail of singletons.
    my @keyspace = map { "GET /api/resource/$_" } 0 .. ($opt{keys} - 1);
    for my $i (0 .. $opt{lines} - 1) {
        my $r = rand();
        my $k = $r < 0.60 ? int(rand(50))                       # hot head
              : $r < 0.90 ? int(rand($opt{keys} / 10))          # warm body
              :             int(rand($opt{keys}));              # cold tail
        push @key_of,    $keyspace[$k];
        push @bucket_of, int($i / ($opt{lines} / $opt{buckets}));
        push @bytes_of,  rand() < $NO_BYTES_FRACTION
                            ? undef
                            : int(10 ** (1 + rand(5)));         # ~10 B .. ~1 MB
    }
}

my $n_with_bytes = scalar grep { defined } @bytes_of;
printf "input: %d lines, %d distinct keys, %d buckets, %d lines with bytes (%.1f%%)\n",
    $opt{lines}, $opt{keys}, $opt{buckets}, $n_with_bytes,
    100 * $n_with_bytes / $opt{lines};

# ---------------------------------------------------------------------------
# Arms.
#
# Each arm is a closure over the shared input running one full pass. Per-message
# and per-bucket scopes are measured separately so H3 (they are not equal) is
# answerable, and then together for the end-to-end figure.
#
# Naming: A = baseline (production shape), B = candidate.
# ---------------------------------------------------------------------------

# --- per-message -----------------------------------------------------------

# A: production. One bytes field, no companion counter, no extrema.
#    Sliced from ltl:11118 — `{total_bytes} += $bytes if defined $bytes;`
sub msg_baseline {
    my %log_messages;
    for my $i (0 .. $#key_of) {
        my ($k, $bytes) = ($key_of[$i], $bytes_of[$i]);
        $log_messages{$k} //= { occurrences => 0, total_bytes => 0 };
        $log_messages{$k}{occurrences}++;
        $log_messages{$k}{total_bytes} += $bytes if defined $bytes;
    }
    return \%log_messages;
}

# B1: the shipped count-family idiom, copied verbatim in shape.
#     Repeated full hash-path resolution per field; !defined test per line.
sub msg_count_idiom {
    my %log_messages;
    for my $i (0 .. $#key_of) {
        my ($k, $bytes) = ($key_of[$i], $bytes_of[$i]);
        $log_messages{$k} //= { occurrences => 0, total_bytes => 0 };
        $log_messages{$k}{occurrences}++;
        if ( defined $bytes ) {
            $log_messages{$k}{total_bytes} += $bytes;
            $log_messages{$k}{bytes_occurrences}++;
            $log_messages{$k}{bytes_min} = $bytes if !defined $log_messages{$k}{bytes_min} || $bytes < $log_messages{$k}{bytes_min};
            $log_messages{$k}{bytes_max} = $bytes if !defined $log_messages{$k}{bytes_max} || $bytes > $log_messages{$k}{bytes_max};
        }
    }
    return \%log_messages;
}

# B2: entry reference cached once, then written through (H1).
sub msg_entry_ref {
    my %log_messages;
    for my $i (0 .. $#key_of) {
        my ($k, $bytes) = ($key_of[$i], $bytes_of[$i]);
        my $e = ( $log_messages{$k} //= { occurrences => 0, total_bytes => 0 } );
        $e->{occurrences}++;
        if ( defined $bytes ) {
            $e->{total_bytes} += $bytes;
            $e->{bytes_occurrences}++;
            $e->{bytes_min} = $bytes if !defined $e->{bytes_min} || $bytes < $e->{bytes_min};
            $e->{bytes_max} = $bytes if !defined $e->{bytes_max} || $bytes > $e->{bytes_max};
        }
    }
    return \%log_messages;
}

# B3: entry reference AND extrema seeded at first observation, removing the
#     per-line !defined test from the steady state (H2).
sub msg_seeded {
    my %log_messages;
    for my $i (0 .. $#key_of) {
        my ($k, $bytes) = ($key_of[$i], $bytes_of[$i]);
        my $e = ( $log_messages{$k} //= { occurrences => 0, total_bytes => 0 } );
        $e->{occurrences}++;
        if ( defined $bytes ) {
            $e->{total_bytes} += $bytes;
            if ( $e->{bytes_occurrences}++ ) {
                $e->{bytes_min} = $bytes if $bytes < $e->{bytes_min};
                $e->{bytes_max} = $bytes if $bytes > $e->{bytes_max};
            } else {
                $e->{bytes_min} = $e->{bytes_max} = $bytes;
            }
        }
    }
    return \%log_messages;
}

# --- per-bucket ------------------------------------------------------------

# A: production. Sliced from ltl:11361.
sub bkt_baseline {
    my %log_analysis;
    for my $i (0 .. $#bucket_of) {
        my ($b, $bytes) = ($bucket_of[$i], $bytes_of[$i]);
        if ( defined $bytes && $bytes ) {
            $log_analysis{$b}{total_bytes} += $bytes;
        }
    }
    return \%log_analysis;
}

# B1: shipped count-family idiom (ltl:11366 shape).
sub bkt_count_idiom {
    my %log_analysis;
    for my $i (0 .. $#bucket_of) {
        my ($b, $bytes) = ($bucket_of[$i], $bytes_of[$i]);
        if ( defined $bytes && $bytes ) {
            $log_analysis{$b}{total_bytes} += $bytes;
            $log_analysis{$b}{bytes_occurrences}++;
            $log_analysis{$b}{bytes_min} = $bytes if !defined $log_analysis{$b}{bytes_min} || $bytes < $log_analysis{$b}{bytes_min};
            $log_analysis{$b}{bytes_max} = $bytes if !defined $log_analysis{$b}{bytes_max} || $bytes > $log_analysis{$b}{bytes_max};
        }
    }
    return \%log_analysis;
}

# B3: entry reference + seeded extrema.
sub bkt_seeded {
    my %log_analysis;
    for my $i (0 .. $#bucket_of) {
        my ($b, $bytes) = ($bucket_of[$i], $bytes_of[$i]);
        if ( defined $bytes && $bytes ) {
            my $e = ( $log_analysis{$b} //= {} );
            $e->{total_bytes} += $bytes;
            if ( $e->{bytes_occurrences}++ ) {
                $e->{bytes_min} = $bytes if $bytes < $e->{bytes_min};
                $e->{bytes_max} = $bytes if $bytes > $e->{bytes_max};
            } else {
                $e->{bytes_min} = $e->{bytes_max} = $bytes;
            }
        }
    }
    return \%log_analysis;
}

# ---------------------------------------------------------------------------
# Correctness gate, run before any timing.
#
# Every candidate must agree with an independently computed reference on every key, and
# the reference must disagree with the shipped mean_bytes derivation on at least
# one key — otherwise the fixture cannot demonstrate F1 and the probe is measuring
# a case that does not exercise the defect (#447 lesson 2).
# ---------------------------------------------------------------------------

sub reference_per_key {
    my %ref;
    for my $i (0 .. $#key_of) {
        my ($k, $bytes) = ($key_of[$i], $bytes_of[$i]);
        # Mirror the production initialiser (ltl:11092): total_bytes is
        # 0-initialised at entry creation, so a key whose lines never carried a
        # bytes value reads 0, not undef. bytes_occurrences is the field that
        # distinguishes "summed to zero" from "never observed" — which is the
        # whole reason F1 needs it as the divisor.
        $ref{$k} //= { total_bytes => 0 };
        $ref{$k}{occurrences}++;
        next unless defined $bytes;
        $ref{$k}{total_bytes}      += $bytes;
        $ref{$k}{bytes_occurrences}++;
        $ref{$k}{bytes_min} = $bytes if !defined $ref{$k}{bytes_min} || $bytes < $ref{$k}{bytes_min};
        $ref{$k}{bytes_max} = $bytes if !defined $ref{$k}{bytes_max} || $bytes > $ref{$k}{bytes_max};
    }
    return \%ref;
}

sub check_agrees {
    my ($name, $got, $ref) = @_;
    my $checked = 0;
    for my $k (keys %$ref) {
        my $r = $ref->{$k};
        my $g = $got->{$k} or die "$name: key missing: $k\n";
        for my $f (qw(total_bytes bytes_occurrences bytes_min bytes_max)) {
            no warnings 'uninitialized';
            die sprintf("%s: %s.%s = %s, expected %s\n", $name, $k, $f, $g->{$f} // 'undef', $r->{$f} // 'undef')
                unless ( $g->{$f} // '' ) eq ( $r->{$f} // '' );
        }
        $checked++;
    }
    printf "  %-18s agrees with reference on %d keys\n", $name, $checked;
}

print "\n== correctness gate ==\n";
my $ref = reference_per_key();
check_agrees('msg_count_idiom', msg_count_idiom(), $ref);
check_agrees('msg_entry_ref',   msg_entry_ref(),   $ref);
check_agrees('msg_seeded',      msg_seeded(),      $ref);

# The F1 demonstration: the shipped divisor vs the correct one.
{
    my ($n_diff, $worst_pct, $worst_key) = (0, 0, undef);
    for my $k (keys %$ref) {
        my $r = $ref->{$k};
        next unless $r->{bytes_occurrences};
        my $shipped = $r->{total_bytes} / $r->{occurrences};        # ltl:15952 divisor
        my $correct = $r->{total_bytes} / $r->{bytes_occurrences};  # the fix
        next if $shipped == $correct;
        $n_diff++;
        my $pct = 100 * ( $correct - $shipped ) / $correct;
        ( $worst_pct, $worst_key ) = ( $pct, $k ) if $pct > $worst_pct;
    }
    printf "  F1 divisor: %d of %d keys differ; worst understatement %.1f%% (%s)\n",
        $n_diff, scalar(keys %$ref), $worst_pct, $worst_key // '-';
    die "PROBE INVALID: fixture cannot demonstrate F1 — no key differs\n" unless $n_diff;
}

# ---------------------------------------------------------------------------
# ABBA timing.
# ---------------------------------------------------------------------------

sub timed { my $f = shift; my $t0 = time; $f->(); return time - $t0 }

sub abba {
    my ($label, $a_name, $a, $b_name, $b, $pairs) = @_;
    my (@ta, @tb, $b_slower);
    for my $p (1 .. $pairs) {
        # ABBA: pair p runs A,B then B,A on alternate iterations, cancelling
        # monotonic drift (thermal, cache warming) across the pair.
        my ($x, $y);
        if ( $p % 2 ) { $x = timed($a); $y = timed($b) }
        else          { $y = timed($b); $x = timed($a) }
        push @ta, $x; push @tb, $y;
        $b_slower++ if $y > $x;
    }
    my $ma = median(\@ta);
    my $mb = median(\@tb);
    my $delta_pct = 100 * ( $mb - $ma ) / $ma;
    my $per_line_ns = 1e9 * ( $mb - $ma ) / $opt{lines};
    printf "%-14s %-18s %.4fs [%.4f-%.4f]  %-18s %.4fs [%.4f-%.4f]  %+7.2f%%  %+7.0f ns/line  %d/%d pairs\n",
        $label, $a_name, $ma, min(@ta), max(@ta), $b_name, $mb, min(@tb), max(@tb),
        $delta_pct, $per_line_ns, $b_slower, $pairs;
    return { delta_pct => $delta_pct, per_line_ns => $per_line_ns, positive => $b_slower, pairs => $pairs };
}

sub median {
    my @s = sort { $a <=> $b } @{ $_[0] };
    return @s % 2 ? $s[$#s/2] : ( $s[@s/2 - 1] + $s[@s/2] ) / 2;
}

printf "\n== ABBA, %d pairs, %d lines/run ==\n", $opt{pairs}, $opt{lines};

print "\n-- per message --\n";
abba('msg', 'baseline', \&msg_baseline, 'count_idiom', \&msg_count_idiom, $opt{pairs});
abba('msg', 'baseline', \&msg_baseline, 'entry_ref',   \&msg_entry_ref,   $opt{pairs});
abba('msg', 'baseline', \&msg_baseline, 'seeded',      \&msg_seeded,      $opt{pairs});

print "\n-- per bucket --\n";
abba('bucket', 'baseline', \&bkt_baseline, 'count_idiom', \&bkt_count_idiom, $opt{pairs});
abba('bucket', 'baseline', \&bkt_baseline, 'seeded',      \&bkt_seeded,      $opt{pairs});

print "\n-- both scopes together (the end-to-end figure) --\n";
abba('both', 'baseline',
     sub { msg_baseline(); bkt_baseline() },
     'seeded',
     sub { msg_seeded();   bkt_seeded()   },
     $opt{pairs});

print "\nNote: these are in-memory accumulation costs only. The end-to-end ltl\n";
print "percentage is this delta over total runtime, not over this loop.\n";
