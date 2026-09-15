#!/usr/bin/env perl
# Stage 1d. Question: does a per-candidate count bound on the sized probe keep the
# guarantee of finding a partner whenever one exists while scoring few candidates
# when no partner exists?
#
# The source r probes its p = |r| - ceil(T*|r|/(200-T)) + 1 rarest trigrams against
# the full batch index (find_consolidation_candidates()'s own index and order). For
# a candidate s, h(s) = shared trigrams inside that probe; the overlap is at most
# h(s) + (|r| - p). Dice >= T needs overlap >= ceil(T*(|r|+|s|)/200), so a
# candidate is scored only once h(s) >= ceil(T*(|r|+|s|)/200) - (|r| - p).
# A candidate that never reaches its bound cannot score T; none is lost.
#
# Arms (same size filters and Dice as find_consolidation_candidates(), sliced verbatim):
#   shipped          find_consolidation_candidates() verbatim (control)
#   bound_all        walk the whole probe, score each candidate when it reaches its bound
#   bound_incr_1     as bound_all, stopping after the posting list that yields a partner
#   bound_incr_5     as bound_all, stopping once 5 partners are held
# Per search: partners missed against a direct Dice scan, top candidate is the best
# partner and its score gap, Dice verifications, posting entries visited,
# milliseconds (median and range over timed passes, arms interleaved).
#   usage: probe-count-bound.pl <subs.pl> <label> <batch file> [sources=500] [timed passes=3]
use strict;
use warnings;
use List::Util qw(min max sum);
use Time::HiRes qw(time);

our ($consolidation_message_length_cap, $consolidation_discriminative_topk,
     $consolidation_prefilter_ratio, $uuid_re);
our (%consolidation_key_message, %consolidation_key_trigrams, %consolidation_key_trigrams_norm,
     %consolidation_ngram_index, %consolidation_posting_size);

my ($subs, $label, $file, $n_src, $passes) = @ARGV;
$n_src  //= 500;
$passes //= 3;
require $subs;

my ($visits, $counting) = (0, 0);

sub bound_search {
    my ($cat_gk, $source_key, $threshold_pct, $want, $budget) = @_;
    $budget //= 0;
    my $source_trigrams = $consolidation_key_trigrams{$source_key};
    my $source_size = scalar keys %$source_trigrams;
    return () if $source_size == 0;
    my $ps = $consolidation_posting_size{$cat_gk};
    my @probe = sort { (($ps->{$a} // 0) <=> ($ps->{$b} // 0)) || ($a cmp $b) }
                grep { exists $consolidation_ngram_index{$cat_gk}{$_} }
                keys %$source_trigrams;
    my $p = min(max(1, $source_size - int(($source_size * $threshold_pct + (200 - $threshold_pct) - 1) / (200 - $threshold_pct)) + 1), scalar @probe);
    splice(@probe, $p);
    my $outside = $source_size - $p;

    my $min_cand_size = int($source_size * $threshold_pct / (200 - $threshold_pct));
    my $max_cand_size = int($source_size * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_trig_dice = $consolidation_key_trigrams_norm{$source_key} // $source_trigrams;
    my $source_size_dice = scalar keys %$source_trig_dice;
    my $min_dice_size = int($source_size_dice * $threshold_pct / (200 - $threshold_pct));
    my $max_dice_size = int($source_size_dice * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_normalised = exists $consolidation_key_trigrams_norm{$source_key};

    my (%hits, %need, @results);
    for my $trig (@probe) {
        my $posting = $consolidation_ngram_index{$cat_gk}{$trig};
        $visits += scalar keys %$posting if $counting;
        for my $cand_key (keys %$posting) {
            next if $cand_key eq $source_key;
            my $need = $need{$cand_key};
            if (!defined $need) {
                my $cand_trigrams = $consolidation_key_trigrams{$cand_key};
                my $cand_size = defined $cand_trigrams ? scalar keys %$cand_trigrams : 0;
                if (!$cand_size || $cand_size < $min_cand_size || $cand_size > $max_cand_size) {
                    $need = $need{$cand_key} = -1;
                } elsif ($source_normalised || exists $consolidation_key_trigrams_norm{$cand_key}) {
                    # Dice is scored on UUID-normalised trigrams here; raw counts bound nothing
                    $need = $need{$cand_key} = 1;
                } else {
                    $need = int(($threshold_pct * ($source_size + $cand_size) + 199) / 200) - $outside;
                    $need = 1 if $need < 1;
                    $need{$cand_key} = $need;
                }
                # Within the budget a candidate is scored when first seen and not again
                if ($need >= 0 && $budget > 0) {
                    $budget--;
                    $need = $need{$cand_key} = -1;
                    my $cand_trig_dice = $consolidation_key_trigrams_norm{$cand_key} // $cand_trigrams;
                    my $cand_size_dice = scalar keys %$cand_trig_dice;
                    next if $cand_size_dice < $min_dice_size || $cand_size_dice > $max_dice_size;
                    my $score = dice_coefficient($source_trig_dice, $cand_trig_dice);
                    push @results, { key => $cand_key, score => $score } if $score >= $threshold_pct;
                    next;
                }
            }
            next if $need < 0;
            next if ++$hits{$cand_key} != $need;
            my $cand_trig_dice = $consolidation_key_trigrams_norm{$cand_key} // $consolidation_key_trigrams{$cand_key};
            my $cand_size_dice = scalar keys %$cand_trig_dice;
            next if $cand_size_dice < $min_dice_size || $cand_size_dice > $max_dice_size;
            my $score = dice_coefficient($source_trig_dice, $cand_trig_dice);
            push @results, { key => $cand_key, score => $score } if $score >= $threshold_pct;
        }
        last if $want && @results >= $want;
    }
    @results = sort { $b->{score} <=> $a->{score} || $a->{key} cmp $b->{key} } @results;
    splice(@results, 50) if @results > 50;
    return @results;
}

open my $fh, '<', $file or die "$file: $!";
chomp(my @keys = <$fh>);
close $fh;
my $cg = 'batch';
$consolidation_key_message{$_} = $_ for @keys;
build_consolidation_ngram_index($cg, \@keys);
my $tri = sub { $consolidation_key_trigrams_norm{$_[0]} // $consolidation_key_trigrams{$_[0]} };

my @T    = (50, 60, 70, 75, 80, 85, 90, 95);
my %arm  = (
    shipped         => sub { find_consolidation_candidates(@_) },
    bound_incr_1    => sub { bound_search(@_, 1, 0) },
    first_seen_1    => sub { bound_search(@_, 1, 1e9) },
    hybrid_b16_1    => sub { bound_search(@_, 1, 16) },
    hybrid_b64_1    => sub { bound_search(@_, 1, 64) },
    hybrid_b64_5    => sub { bound_search(@_, 5, 64) },
);
my @arms = qw(shipped bound_incr_1 first_seen_1 hybrid_b16_1 hybrid_b64_1 hybrid_b64_5);
my @src  = @keys[0 .. min($n_src, scalar @keys) - 1];

my %best;
for my $s (@src) {
    my ($b, $ts) = (-1, $tri->($s));
    for my $k (@keys) {
        next if $k eq $s;
        my $d = dice_coefficient($ts, $tri->($k));
        $b = $d if $d > $b;
    }
    $best{$s} = $b;
}

my $dice_calls = 0;
my $dice_orig  = \&dice_coefficient;
my (%partner, %missed, %is_best, %gap, %dice, %vis);
{
    no warnings 'redefine';
    *dice_coefficient = sub { $dice_calls++; $dice_orig->(@_) };
    $counting = 1;
    for my $T (@T) {
        for my $am (@arms) {
            for my $s (@src) {
                ($dice_calls, $visits) = (0, 0);
                my @c = $arm{$am}->($cg, $s, $T);
                $dice{$am}{$T} += $dice_calls;
                $vis{$am}{$T}  += $visits;
                my $pt = $best{$s} >= $T;
                $partner{$T}++ if $pt && $am eq 'shipped';
                $missed{$am}{$T}++ if $pt && !@c;
                if (@c) {
                    $is_best{$am}{$T}++ if $c[0]{score} == $best{$s};
                    push @{$gap{$am}{$T}}, $best{$s} - $c[0]{score};
                }
            }
        }
    }
    $counting = 0;
    *dice_coefficient = $dice_orig;
}

my %ms;
for my $pass (1 .. $passes) {
    for my $T (@T) {
        for my $am ($pass % 2 ? @arms : reverse @arms) {
            my $t0 = time;
            $arm{$am}->($cg, $_, $T) for @src;
            push @{$ms{$am}{$T}}, 1000 * (time - $t0) / @src;
        }
    }
}

my $median = sub { my @x = sort { $a <=> $b } @_; @x ? $x[int($#x / 2)] : 0 };
print join("\t", qw(label keys sources T arm partner missed top_is_best returned_any gap_median gap_max
                    dice_per_search visits_per_search ms_median ms_min ms_max)), "\n";
for my $T (@T) {
    for my $am (@arms) {
        my @g = @{$gap{$am}{$T} // []};
        printf "%s\t%d\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%.1f\t%.0f\t%.3f\t%.3f\t%.3f\n",
            $label, scalar @keys, scalar @src, $T, $am, $partner{$T} // 0, $missed{$am}{$T} // 0,
            $is_best{$am}{$T} // 0, scalar @g, (@g ? $median->(@g) : '-'), (@g ? max(@g) : '-'),
            $dice{$am}{$T} / @src, $vis{$am}{$T} / @src,
            $median->(@{$ms{$am}{$T}}), min(@{$ms{$am}{$T}}), max(@{$ms{$am}{$T}});
    }
}
