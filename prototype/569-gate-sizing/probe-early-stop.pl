#!/usr/bin/env perl
# Stage 1b. Question: can a candidate search sized from the requested similarity
# (probe the |r| - ceil(T*|r|/(200-T)) + 1 rarest trigrams, one shared trigram
# admits) stop once it has a partner, keep the guarantee of finding one whenever
# one exists, and approach the shipped search's cost?
#
# Arms, all on the same batch index and the same size filters and Dice as
# find_consolidation_candidates() (sliced verbatim by extract-subs.sh):
#   shipped         find_consolidation_candidates() verbatim (control)
#   hits_first_1    count hits over the sized probe, verify candidates from the
#                   highest hit count down, stop after the hit level that yields a partner
#   incremental_1   walk the sized probe rarest first, verify each candidate the
#                   first time it is seen, stop after the posting list that yields a partner
#   incremental_5   as incremental_1, stopping once 5 partners are held
# Guarantee: a partner at T shares a trigram inside the sized probe, so a walk
# that reaches the end of the probe without stopping has verified it.
# Per search: partners missed against a direct Dice scan, whether the top returned
# candidate is the batch's best partner and its score gap, Dice verifications,
# posting entries visited, milliseconds (median and range over timed passes).
#   usage: probe-early-stop.pl <subs.pl> <label> <batch file> [sources=500] [timed passes=3]
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

sub sized_probe {
    my ($cat_gk, $source_key, $threshold_pct) = @_;
    my $source_trigrams = $consolidation_key_trigrams{$source_key};
    my $ps = $consolidation_posting_size{$cat_gk};
    my @disc = sort { (($ps->{$a} // 0) <=> ($ps->{$b} // 0)) || ($a cmp $b) }
               grep { exists $consolidation_ngram_index{$cat_gk}{$_} }
               keys %$source_trigrams;
    my $n = scalar keys %$source_trigrams;
    my $len = min(max(1, $n - int(($n * $threshold_pct + (200 - $threshold_pct) - 1) / (200 - $threshold_pct)) + 1), scalar @disc);
    splice(@disc, $len) if @disc > $len;
    return \@disc;
}

# Size filters and Dice exactly as find_consolidation_candidates() Phase 2
sub verifier {
    my ($source_key, $threshold_pct) = @_;
    my $source_size = scalar keys %{$consolidation_key_trigrams{$source_key}};
    my $min_cand_size = int($source_size * $threshold_pct / (200 - $threshold_pct));
    my $max_cand_size = int($source_size * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_trig_dice = $consolidation_key_trigrams_norm{$source_key} // $consolidation_key_trigrams{$source_key};
    my $source_size_dice = scalar keys %$source_trig_dice;
    my $min_dice_size = int($source_size_dice * $threshold_pct / (200 - $threshold_pct));
    my $max_dice_size = int($source_size_dice * (200 - $threshold_pct) / $threshold_pct) + 1;
    return sub {
        my ($cand_key) = @_;
        my $cand_trigrams = $consolidation_key_trigrams{$cand_key};
        return -1 unless defined $cand_trigrams;
        my $cand_size = scalar keys %$cand_trigrams;
        return -1 if $cand_size < $min_cand_size || $cand_size > $max_cand_size;
        my $cand_trig_dice = $consolidation_key_trigrams_norm{$cand_key} // $cand_trigrams;
        my $cand_size_dice = scalar keys %$cand_trig_dice;
        return -1 if $cand_size_dice < $min_dice_size || $cand_size_dice > $max_dice_size;
        my $score = dice_coefficient($source_trig_dice, $cand_trig_dice);
        return $score >= $threshold_pct ? $score : -1;
    };
}

sub ranked { sort { $b->{score} <=> $a->{score} || $a->{key} cmp $b->{key} } @_ }

sub hits_first {
    my ($cat_gk, $source_key, $threshold_pct, $want) = @_;
    my $probe = sized_probe($cat_gk, $source_key, $threshold_pct);
    my $verify = verifier($source_key, $threshold_pct);
    my %hits;
    for my $trig (@$probe) {
        my $posting = $consolidation_ngram_index{$cat_gk}{$trig};
        $visits += scalar keys %$posting if $counting;
        for my $cand_key (keys %$posting) {
            next if $cand_key eq $source_key;
            $hits{$cand_key}++;
        }
    }
    my @by_hits;
    push @{$by_hits[$hits{$_}]}, $_ for keys %hits;
    my @results;
    for (my $h = $#by_hits; $h >= 1; $h--) {
        next unless $by_hits[$h];
        for my $cand_key (@{$by_hits[$h]}) {
            my $score = $verify->($cand_key);
            push @results, { key => $cand_key, score => $score } if $score >= 0;
        }
        last if @results >= $want;
    }
    return ranked(@results);
}

sub incremental {
    my ($cat_gk, $source_key, $threshold_pct, $want) = @_;
    my $probe = sized_probe($cat_gk, $source_key, $threshold_pct);
    my $verify = verifier($source_key, $threshold_pct);
    my %seen = ($source_key => 1);
    my @results;
    for my $trig (@$probe) {
        my $posting = $consolidation_ngram_index{$cat_gk}{$trig};
        $visits += scalar keys %$posting if $counting;
        for my $cand_key (keys %$posting) {
            next if $seen{$cand_key}++;
            my $score = $verify->($cand_key);
            push @results, { key => $cand_key, score => $score } if $score >= 0;
        }
        last if @results >= $want;
    }
    return ranked(@results);
}

open my $fh, '<', $file or die "$file: $!";
chomp(my @keys = <$fh>);
close $fh;
my $cg = 'batch';
$consolidation_key_message{$_} = $_ for @keys;
build_consolidation_ngram_index($cg, \@keys);
my $tri = sub { $consolidation_key_trigrams_norm{$_[0]} // $consolidation_key_trigrams{$_[0]} };

my @T = (50, 60, 70, 75, 80, 85, 90, 95);
my %arm = (
    shipped       => sub { find_consolidation_candidates(@_) },
    hits_first_1  => sub { hits_first(@_, 1) },
    incremental_1 => sub { incremental(@_, 1) },
    incremental_5 => sub { incremental(@_, 5) },
);
my @arms = qw(shipped hits_first_1 incremental_1 incremental_5);
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
                my $p = $best{$s} >= $T;
                $partner{$T}++ if $p && $am eq 'shipped';
                $missed{$am}{$T}++ if $p && !@c;
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
