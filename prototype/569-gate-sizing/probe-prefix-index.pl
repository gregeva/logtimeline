#!/usr/bin/env perl
# Stage 1c. Question: does prefix filtering applied to both sides (each indexed key
# contributes only its own sized prefix of rarest trigrams, and the source probes
# its sized prefix) keep the guarantee of finding a partner whenever one exists,
# while admitting few enough candidates that a search with no partner is cheap?
#
# Global order: trigrams by document frequency in the batch ascending, then by
# string (the order find_consolidation_candidates() sorts by). For similarity T a
# key s contributes its first |s| - ceil(T*|s|/(200-T)) + 1 trigrams. A pair with
# Dice >= T has overlap >= that bound on both sides, so the two prefixes share a
# trigram (prefix filtering principle), and the source's probe reaches the partner.
#
# Arms (same size filters and Dice as find_consolidation_candidates(), sliced verbatim):
#   shipped            find_consolidation_candidates() verbatim (control)
#   prefix2_all        probe the prefix index, verify every candidate, top 50 by score
#   prefix2_incr_1     walk the source prefix rarest first, verify each candidate when
#                      first seen, stop after the posting list that yields a partner
#   prefix2_incr_5     as prefix2_incr_1, stopping once 5 partners are held
# Per threshold: time to build the prefix index for the batch and its posting
# entries (the full index's entries for comparison). Per search: partners missed
# against a direct Dice scan, top candidate is the best partner and its score gap,
# Dice verifications, posting entries visited, milliseconds (median and range).
#   usage: probe-prefix-index.pl <subs.pl> <label> <batch file> [sources=500] [timed passes=3]
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

sub prefix_len {
    my ($n, $T) = @_;
    return min(max(1, $n - int(($n * $T + (200 - $T) - 1) / (200 - $T)) + 1), $n);
}

sub ordered_prefix {
    my ($cat_gk, $key, $T) = @_;
    my $ps = $consolidation_posting_size{$cat_gk};
    my $trigrams = $consolidation_key_trigrams{$key};
    my @order = sort { (($ps->{$a} // 0) <=> ($ps->{$b} // 0)) || ($a cmp $b) } keys %$trigrams;
    splice(@order, prefix_len(scalar @order, $T));
    return \@order;
}

# Prefix index for threshold T: trigram => { key => 1 } over each key's own prefix
sub build_prefix_index {
    my ($cat_gk, $keys, $T) = @_;
    my %index;
    for my $key (@$keys) {
        $index{$_}{$key} = 1 for @{ ordered_prefix($cat_gk, $key, $T) };
    }
    return \%index;
}

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

sub prefix2 {
    my ($cat_gk, $index, $source_key, $T, $want) = @_;
    my $probe = ordered_prefix($cat_gk, $source_key, $T);
    my $verify = verifier($source_key, $T);
    my %seen = ($source_key => 1);
    my @results;
    for my $trig (@$probe) {
        my $posting = $index->{$trig} or next;
        $visits += scalar keys %$posting if $counting;
        for my $cand_key (keys %$posting) {
            next if $seen{$cand_key}++;
            my $score = $verify->($cand_key);
            push @results, { key => $cand_key, score => $score } if $score >= 0;
        }
        last if $want && @results >= $want;
    }
    @results = ranked(@results);
    splice(@results, 50) if @results > 50;
    return @results;
}

open my $fh, '<', $file or die "$file: $!";
chomp(my @keys = <$fh>);
close $fh;
my $cg = 'batch';
$consolidation_key_message{$_} = $_ for @keys;
build_consolidation_ngram_index($cg, \@keys);
my $full_entries = sum(0, values %{$consolidation_posting_size{$cg}});
my $tri = sub { $consolidation_key_trigrams_norm{$_[0]} // $consolidation_key_trigrams{$_[0]} };

my @T    = (50, 60, 70, 75, 80, 85, 90, 95);
my @arms = qw(shipped prefix2_all prefix2_incr_1 prefix2_incr_5);
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

my (%index, %build_ms, %index_entries);
for my $T (@T) {
    my @times;
    for (1 .. $passes) {
        my $t0 = time;
        $index{$T} = build_prefix_index($cg, \@keys, $T);
        push @times, 1000 * (time - $t0);
    }
    $build_ms{$T} = [sort { $a <=> $b } @times];
    $index_entries{$T} = sum(0, map { scalar keys %$_ } values %{$index{$T}});
}

my %arm = (
    shipped        => sub { my ($T, $s) = @_; find_consolidation_candidates($cg, $s, $T) },
    prefix2_all    => sub { my ($T, $s) = @_; prefix2($cg, $index{$T}, $s, $T, 0) },
    prefix2_incr_1 => sub { my ($T, $s) = @_; prefix2($cg, $index{$T}, $s, $T, 1) },
    prefix2_incr_5 => sub { my ($T, $s) = @_; prefix2($cg, $index{$T}, $s, $T, 5) },
);

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
                my @c = $arm{$am}->($T, $s);
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
            $arm{$am}->($T, $_) for @src;
            push @{$ms{$am}{$T}}, 1000 * (time - $t0) / @src;
        }
    }
}

my $median = sub { my @x = sort { $a <=> $b } @_; @x ? $x[int($#x / 2)] : 0 };
print join("\t", qw(label keys sources T arm partner missed top_is_best returned_any gap_median gap_max
                    dice_per_search visits_per_search ms_median ms_min ms_max
                    index_build_ms_median index_entries full_index_entries)), "\n";
for my $T (@T) {
    for my $am (@arms) {
        my @g = @{$gap{$am}{$T} // []};
        printf "%s\t%d\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%.1f\t%.0f\t%.3f\t%.3f\t%.3f\t%.1f\t%d\t%d\n",
            $label, scalar @keys, scalar @src, $T, $am, $partner{$T} // 0, $missed{$am}{$T} // 0,
            $is_best{$am}{$T} // 0, scalar @g, (@g ? $median->(@g) : '-'), (@g ? max(@g) : '-'),
            $dice{$am}{$T} / @src, $vis{$am}{$T} / @src,
            $median->(@{$ms{$am}{$T}}), min(@{$ms{$am}{$T}}), max(@{$ms{$am}{$T}}),
            ($am eq 'shipped' ? 0 : $median->(@{$build_ms{$T}})), ($am eq 'shipped' ? 0 : $index_entries{$T}), $full_entries;
    }
}
