#!/usr/bin/env perl
# Question: does a candidate gate whose probe length follows the requested
# similarity and the key's trigram count, with one shared trigram required,
# find the partners the shipped gate misses, and at what cost per search?
#
# One first-checkpoint batch (the sorted unmatched keys run_consolidation_checkpoint()
# hands to discovery). Sources are the first N keys in batch order, the order and
# limit of run_consolidation_pass(). For each source and threshold:
#   partner  best direct Dice over the whole batch >= T (UUID-normalised where ltl scores normalised)
#   found    the arm returns at least one candidate
#   missed   partner and not found
# Arms: shipped = find_consolidation_candidates() verbatim; sized = the same sub
# with Phase 1's probe length and required hits changed (extract-subs.sh).
# Cost: probe length and posting entries visited per search (from the index, in
# the sub's own order), Dice verifications per search (counting pass), and
# milliseconds per search (median and range over timed passes, arms interleaved).
#   usage: probe.pl <subs.pl> <label> <batch file> [sources=500] [timed passes=3]
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

open my $fh, '<', $file or die "$file: $!";
chomp(my @keys = <$fh>);
close $fh;
my $cg = 'batch';
$consolidation_key_message{$_} = $_ for @keys;
build_consolidation_ngram_index($cg, \@keys);
my $ps  = $consolidation_posting_size{$cg};
my $tri = sub { $consolidation_key_trigrams_norm{$_[0]} // $consolidation_key_trigrams{$_[0]} };

my @T    = (50, 60, 70, 75, 80, 85, 90, 95);
my %arm  = (shipped => \&find_consolidation_candidates, sized => \&find_consolidation_candidates_sized);
my @arms = sort keys %arm;
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

my %probe_len = (shipped => sub { min($consolidation_discriminative_topk, $_[1]) },
                 sized   => sub { my ($T, $n) = @_; min(max(1, $n - int(($n * $T + (200 - $T) - 1) / (200 - $T)) + 1), $n) });
my (%len, %visits);
for my $s (@src) {
    my @order = sort { ($ps->{$a} // 0) <=> ($ps->{$b} // 0) || ($a cmp $b) } keys %{$consolidation_key_trigrams{$s}};
    for my $T (@T) {
        for my $am (@arms) {
            my $p = $probe_len{$am}->($T, scalar @order);
            push @{$len{$am}{$T}}, $p;
            push @{$visits{$am}{$T}}, sum(0, map { $ps->{$_} - 1 } @order[0 .. $p - 1]);
        }
    }
}

my $dice_calls = 0;
my $dice_orig  = \&dice_coefficient;
my (%partner, %found, %missed, %dice, %returned);
{
    no warnings 'redefine';
    *dice_coefficient = sub { $dice_calls++; $dice_orig->(@_) };
    for my $T (@T) {
        for my $am (@arms) {
            for my $s (@src) {
                $dice_calls = 0;
                my @c = $arm{$am}->($cg, $s, $T);
                $dice{$am}{$T} += $dice_calls;
                $returned{$am}{$T} += @c;
                my $p = $best{$s} >= $T;
                $partner{$T}++ if $p && $am eq 'shipped';
                $found{$am}{$T}++ if @c;
                $missed{$am}{$T}++ if $p && !@c;
            }
        }
    }
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
print join("\t", qw(label keys sources T arm partner found missed miss_rate probe_len_median
                    posting_visits_median dice_per_search returned_per_search ms_median ms_min ms_max)), "\n";
for my $T (@T) {
    for my $am (@arms) {
        my $pt = $partner{$T} // 0;
        my $mi = $missed{$am}{$T} // 0;
        printf "%s\t%d\t%d\t%d\t%s\t%d\t%d\t%d\t%s\t%d\t%d\t%.1f\t%.1f\t%.3f\t%.3f\t%.3f\n",
            $label, scalar @keys, scalar @src, $T, $am, $pt, $found{$am}{$T} // 0, $mi,
            ($pt ? sprintf('%.1f%%', 100 * $mi / $pt) : '-'),
            $median->(@{$len{$am}{$T}}), $median->(@{$visits{$am}{$T}}),
            $dice{$am}{$T} / @src, $returned{$am}{$T} / @src,
            $median->(@{$ms{$am}{$T}}), min(@{$ms{$am}{$T}}), max(@{$ms{$am}{$T}});
    }
}
