#!/usr/bin/env perl
# Stage 1e. Question: how much of the combined search's cost is the index's
# shape? A profile of the combined search at -g 80 on the PLM download requests
# puts 75% of CPU in its own walk, which looks up full message keys (up to 350
# characters) in hashes for every posting entry. Here the same search runs over
# an index of integer key ids: posting lists are arrays of ids, and the per-key
# size, UUID flag and per-search hit and bound counters are arrays.
#
# Arms, same batch, same sized probe, same budget/bound/stop rules, same Dice:
#   shipped          find_consolidation_candidates() verbatim (control)
#   hybrid_str_b64_1 the combined search over ltl's hash index (as in probe-count-bound.pl)
#   hybrid_int_b64_1 the combined search over the integer-id array index
#   hybrid_int_b64_5 as hybrid_int_b64_1, stopping once 5 partners are held
# The integer index is built once per batch from the same keys; its build time
# and the hash index's are reported. Results must be identical between the two
# hybrid_b64_1 arms (same candidates returned for every source and threshold).
#   usage: probe-int-index.pl <subs.pl> <label> <batch file> [sources=500] [timed passes=3]
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

sub sized_len {
    my ($n, $T) = @_;
    return min(max(1, $n - int(($n * $T + (200 - $T) - 1) / (200 - $T)) + 1), $n);
}

# The combined search over ltl's hash index (probe-count-bound.pl's bound_search with the exemption)
sub hybrid_str {
    my ($cat_gk, $source_key, $threshold_pct, $want, $budget) = @_;
    my $source_trigrams = $consolidation_key_trigrams{$source_key};
    my $source_size = scalar keys %$source_trigrams;
    return () if $source_size == 0;
    my $ps = $consolidation_posting_size{$cat_gk};
    my @probe = sort { (($ps->{$a} // 0) <=> ($ps->{$b} // 0)) || ($a cmp $b) }
                grep { exists $consolidation_ngram_index{$cat_gk}{$_} } keys %$source_trigrams;
    splice(@probe, sized_len($source_size, $threshold_pct));
    my $outside = $source_size - scalar @probe;
    my $min_cand_size = int($source_size * $threshold_pct / (200 - $threshold_pct));
    my $max_cand_size = int($source_size * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_trig_dice = $consolidation_key_trigrams_norm{$source_key} // $source_trigrams;
    my $source_size_dice = scalar keys %$source_trig_dice;
    my $min_dice_size = int($source_size_dice * $threshold_pct / (200 - $threshold_pct));
    my $max_dice_size = int($source_size_dice * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_normalised = exists $consolidation_key_trigrams_norm{$source_key};
    my (%hits, %need, @results);
    for my $trig (@probe) {
        for my $cand_key (keys %{$consolidation_ngram_index{$cat_gk}{$trig}}) {
            next if $cand_key eq $source_key;
            my $need = $need{$cand_key};
            if (!defined $need) {
                my $cand_size = scalar keys %{$consolidation_key_trigrams{$cand_key}};
                if ($cand_size < $min_cand_size || $cand_size > $max_cand_size) { $need{$cand_key} = -1; next; }
                if ($budget > 0) {
                    $budget--;
                    $need{$cand_key} = -1;
                    my $cd = $consolidation_key_trigrams_norm{$cand_key} // $consolidation_key_trigrams{$cand_key};
                    my $cs = scalar keys %$cd;
                    next if $cs < $min_dice_size || $cs > $max_dice_size;
                    my $score = dice_coefficient($source_trig_dice, $cd);
                    push @results, { key => $cand_key, score => $score } if $score >= $threshold_pct;
                    next;
                }
                if ($source_normalised || exists $consolidation_key_trigrams_norm{$cand_key}) { $need = 1; }
                else { $need = int(($threshold_pct * ($source_size + $cand_size) + 199) / 200) - $outside; $need = 1 if $need < 1; }
                $need{$cand_key} = $need;
            }
            next if $need < 0;
            next if ++$hits{$cand_key} != $need;
            my $cd = $consolidation_key_trigrams_norm{$cand_key} // $consolidation_key_trigrams{$cand_key};
            my $cs = scalar keys %$cd;
            next if $cs < $min_dice_size || $cs > $max_dice_size;
            my $score = dice_coefficient($source_trig_dice, $cd);
            push @results, { key => $cand_key, score => $score } if $score >= $threshold_pct;
        }
        last if @results >= $want;
    }
    return sort { $b->{score} <=> $a->{score} || $a->{key} cmp $b->{key} } @results;
}

# Integer-id index: @ikeys id => key, %iid key => id, %ipost trigram => [ids],
# @isize raw trigram count, @isize_dice scored trigram count, @inorm UUID flag.
my (@ikeys, %iid, %ipost, @isize, @isize_dice, @inorm, @itrig_dice);
sub build_int_index {
    my ($keys) = @_;
    (@ikeys, %iid, %ipost, @isize, @isize_dice, @inorm, @itrig_dice) = ();
    for my $key (@$keys) {
        my $id = scalar @ikeys;
        push @ikeys, $key;
        $iid{$key} = $id;
        my $t = $consolidation_key_trigrams{$key};
        $isize[$id] = scalar keys %$t;
        $inorm[$id] = exists $consolidation_key_trigrams_norm{$key} ? 1 : 0;
        $itrig_dice[$id] = $consolidation_key_trigrams_norm{$key} // $t;
        $isize_dice[$id] = scalar keys %{$itrig_dice[$id]};
        push @{$ipost{$_}}, $id for keys %$t;
    }
}

sub hybrid_int {
    my ($source_key, $threshold_pct, $want, $budget) = @_;
    my $sid = $iid{$source_key};
    my $source_size = $isize[$sid];
    return () if $source_size == 0;
    my @probe = sort { (scalar @{$ipost{$a}} <=> scalar @{$ipost{$b}}) || ($a cmp $b) }
                keys %{$consolidation_key_trigrams{$source_key}};
    splice(@probe, sized_len($source_size, $threshold_pct));
    my $outside = $source_size - scalar @probe;
    my $min_cand_size = int($source_size * $threshold_pct / (200 - $threshold_pct));
    my $max_cand_size = int($source_size * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_trig_dice = $itrig_dice[$sid];
    my $source_size_dice = $isize_dice[$sid];
    my $min_dice_size = int($source_size_dice * $threshold_pct / (200 - $threshold_pct));
    my $max_dice_size = int($source_size_dice * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_normalised = $inorm[$sid];
    my $sum_const = $threshold_pct * $source_size + 199;
    my (@hits, @need, @results);
    $need[$sid] = -1;
    for my $trig (@probe) {
        for my $cid (@{$ipost{$trig}}) {
            my $need = $need[$cid];
            if (!defined $need) {
                my $cand_size = $isize[$cid];
                if ($cand_size < $min_cand_size || $cand_size > $max_cand_size) { $need[$cid] = -1; next; }
                if ($budget > 0) {
                    $budget--;
                    $need[$cid] = -1;
                    my $cs = $isize_dice[$cid];
                    next if $cs < $min_dice_size || $cs > $max_dice_size;
                    my $score = dice_coefficient($source_trig_dice, $itrig_dice[$cid]);
                    push @results, { key => $ikeys[$cid], score => $score } if $score >= $threshold_pct;
                    next;
                }
                if ($source_normalised || $inorm[$cid]) { $need = 1; }
                else { $need = int(($sum_const + $threshold_pct * $cand_size) / 200) - $outside; $need = 1 if $need < 1; }
                $need[$cid] = $need;
            }
            next if $need < 0;
            next if ++$hits[$cid] != $need;
            my $cs = $isize_dice[$cid];
            next if $cs < $min_dice_size || $cs > $max_dice_size;
            my $score = dice_coefficient($source_trig_dice, $itrig_dice[$cid]);
            push @results, { key => $ikeys[$cid], score => $score } if $score >= $threshold_pct;
        }
        last if @results >= $want;
    }
    return sort { $b->{score} <=> $a->{score} || $a->{key} cmp $b->{key} } @results;
}

# As hybrid_int, plus a discovery cutoff. With s_min the smallest raw size among
# the batch's non-UUID keys inside the size filter, a candidate first seen at
# probe position i can gather at most p - i hits and needs at least
# need_min = ceil(T*(|r|+s_min)/200) - (|r| - p); past position p - need_min no
# new non-UUID candidate can qualify. Seen candidates are tracked by the last
# position at which they can still reach their bound; once none is alive past the
# cutoff, the non-UUID posting lists are no longer walked. UUID keys have no bound:
# a UUID source walks the whole probe, and UUID candidates are still discovered
# from their own posting lists after the cutoff.
my (%ipost_plain, %ipost_norm, @plain_sizes_sorted);
sub build_int_split {
    (%ipost_plain, %ipost_norm) = ();
    for my $trig (keys %ipost) {
        for my $cid (@{$ipost{$trig}}) {
            push @{ $inorm[$cid] ? $ipost_norm{$trig} : $ipost_plain{$trig} }, $cid;
        }
    }
    @plain_sizes_sorted = sort { $a <=> $b } map { $isize[$_] } grep { !$inorm[$_] } 0 .. $#ikeys;
}

sub first_size_at_least {
    my ($floor) = @_;
    my ($lo, $hi) = (0, scalar @plain_sizes_sorted);
    while ($lo < $hi) { my $mid = int(($lo + $hi) / 2); if ($plain_sizes_sorted[$mid] < $floor) { $lo = $mid + 1 } else { $hi = $mid } }
    return $lo < @plain_sizes_sorted ? $plain_sizes_sorted[$lo] : undef;
}

my ($cut_visits, $cut_counting) = (0, 0);
# $rare_max, when given, limits first-seen scoring to posting lists of at most that
# many keys: a key's near-duplicate shares its rare trigrams, while a search with
# no partner meets only failing candidates in the common lists.
sub hybrid_int_cut {
    my ($source_key, $threshold_pct, $want, $budget, $rare_max) = @_;
    my $sid = $iid{$source_key};
    my $source_size = $isize[$sid];
    return () if $source_size == 0;
    my @probe = sort { (scalar @{$ipost{$a}} <=> scalar @{$ipost{$b}}) || ($a cmp $b) }
                keys %{$consolidation_key_trigrams{$source_key}};
    my $p = sized_len($source_size, $threshold_pct);
    splice(@probe, $p);
    my $outside = $source_size - $p;
    my $min_cand_size = int($source_size * $threshold_pct / (200 - $threshold_pct));
    my $max_cand_size = int($source_size * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_trig_dice = $itrig_dice[$sid];
    my $source_size_dice = $isize_dice[$sid];
    my $min_dice_size = int($source_size_dice * $threshold_pct / (200 - $threshold_pct));
    my $max_dice_size = int($source_size_dice * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_normalised = $inorm[$sid];
    my $sum_const = $threshold_pct * $source_size + 199;

    my $cut = $p - 1;
    if (!$source_normalised) {
        my $s_min = first_size_at_least($min_cand_size);
        if (!defined $s_min || $s_min > $max_cand_size) { $cut = -1; }
        else {
            my $need_min = int(($sum_const + $threshold_pct * $s_min) / 200) - $outside;
            $need_min = 1 if $need_min < 1;
            $cut = $p - $need_min;
        }
    }

    my (@hits, @need, @deadline, @dying, @results);
    my $live = 0;
    $need[$sid] = -1;
    my $score_it = sub {
        my ($cid) = @_;
        my $cs = $isize_dice[$cid];
        return if $cs < $min_dice_size || $cs > $max_dice_size;
        my $score = dice_coefficient($source_trig_dice, $itrig_dice[$cid]);
        push @results, { key => $ikeys[$cid], score => $score } if $score >= $threshold_pct;
    };
    for my $i (0 .. $p - 1) {
        my $trig = $probe[$i];
        my $rare = !defined $rare_max || @{$ipost{$trig}} <= $rare_max;
        my @lists = ($source_normalised || $i <= $cut || $live > 0) ? ($ipost_plain{$trig}, $ipost_norm{$trig}) : ($ipost_norm{$trig});
        for my $list (@lists) {
            next unless $list;
            $cut_visits += scalar @$list if $cut_counting;
            for my $cid (@$list) {
                my $need = $need[$cid];
                if (!defined $need) {
                    next if !$source_normalised && !$inorm[$cid] && $i > $cut;
                    my $cand_size = $isize[$cid];
                    if ($cand_size < $min_cand_size || $cand_size > $max_cand_size) { $need[$cid] = -1; next; }
                    if ($budget > 0 && $rare) { $budget--; $need[$cid] = -1; $score_it->($cid); next; }
                    if ($source_normalised || $inorm[$cid]) { $need = 1; }
                    else { $need = int(($sum_const + $threshold_pct * $cand_size) / 200) - $outside; $need = 1 if $need < 1; }
                    $need[$cid] = $need;
                    if ($need > 1) {
                        # With h hits after position i the candidate can still reach its bound
                        # while i <= p - 1 - need + h; one hit now gives deadline p - need.
                        my $d = $p - $need;
                        if ($d < $i) { $need[$cid] = -1; next; }
                        $deadline[$cid] = $d; $dying[$d]++; $live++;
                    }
                }
                next if $need < 0;
                if ($need > 1 && defined $hits[$cid] && $deadline[$cid] < $i - 1) {
                    # Its last chance was position deadline + 1 and it was not hit there
                    $need[$cid] = -1;
                    next;
                }
                my $h = ++$hits[$cid];
                if ($h == $need) {
                    if ($need > 1) { $dying[$deadline[$cid]]--; $live--; }
                    $need[$cid] = -1;
                    $score_it->($cid);
                } elsif ($h > 1) {
                    $dying[$deadline[$cid]]--; $deadline[$cid]++; $dying[$deadline[$cid]]++;
                }
            }
        }
        # Candidates whose deadline was i - 1 and that were not hit at i can no longer qualify
        $live -= $dying[$i - 1] // 0 if $i > 0;
        last if @results >= $want;
        last if !$source_normalised && $i >= $cut && $live <= 0 && !grep { $ipost_norm{$probe[$_]} } $i + 1 .. $p - 1;
    }
    return sort { $b->{score} <=> $a->{score} || $a->{key} cmp $b->{key} } @results;
}

open my $fh, '<', $file or die "$file: $!";
chomp(my @keys = <$fh>);
close $fh;
my $cg = 'batch';
$consolidation_key_message{$_} = $_ for @keys;
my @build_str;
for (1 .. $passes) {
    my $t0 = time;
    delete $consolidation_ngram_index{$cg};
    build_consolidation_ngram_index($cg, \@keys);
    push @build_str, 1000 * (time - $t0);
}
my @build_int;
for (1 .. $passes) {
    my $t0 = time;
    build_int_index(\@keys);
    push @build_int, 1000 * (time - $t0);
}
build_int_split();
my $tri = sub { $consolidation_key_trigrams_norm{$_[0]} // $consolidation_key_trigrams{$_[0]} };

my @T    = (50, 60, 70, 75, 80, 85, 90, 95);
my %arm  = (
    shipped          => sub { my ($T, $s) = @_; find_consolidation_candidates($cg, $s, $T) },
    hybrid_str_b64_1 => sub { my ($T, $s) = @_; hybrid_str($cg, $s, $T, 1, 64) },
    hybrid_int_b64_1 => sub { my ($T, $s) = @_; hybrid_int($s, $T, 1, 64) },
    hybrid_int_b64_5 => sub { my ($T, $s) = @_; hybrid_int($s, $T, 5, 64) },
    cut_int_b64_1    => sub { my ($T, $s) = @_; hybrid_int_cut($s, $T, 1, 64) },
    cut_int_b64_5    => sub { my ($T, $s) = @_; hybrid_int_cut($s, $T, 5, 64) },
    cut_int_b0_1     => sub { my ($T, $s) = @_; hybrid_int_cut($s, $T, 1, 0) },
    cut_rare16_b64_1  => sub { my ($T, $s) = @_; hybrid_int_cut($s, $T, 1, 64, 16) },
    cut_rare64_b64_1  => sub { my ($T, $s) = @_; hybrid_int_cut($s, $T, 1, 64, 64) },
    cut_rare256_b64_1 => sub { my ($T, $s) = @_; hybrid_int_cut($s, $T, 1, 64, 256) },
);
my @arms = qw(shipped hybrid_str_b64_1 hybrid_int_b64_1 hybrid_int_b64_5 cut_int_b64_1 cut_int_b64_5 cut_int_b0_1
              cut_rare16_b64_1 cut_rare64_b64_1 cut_rare256_b64_1);
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

my (%partner, %missed, %differ, %differ_cut);
for my $T (@T) {
    for my $s (@src) {
        my %got = map { $_ => [ $arm{$_}->($T, $s) ] } @arms;
        my $p = $best{$s} >= $T;
        $partner{$T}++ if $p;
        for my $am (@arms) { $missed{$am}{$T}++ if $p && !@{$got{$am}}; }
        my $sig = sub { join ',', map { "$_->{key}=$_->{score}" } @{$_[0]} };
        $differ{$T}++ if $sig->($got{hybrid_str_b64_1}) ne $sig->($got{hybrid_int_b64_1});
        $differ_cut{$T}++ if $sig->($got{hybrid_int_b64_1}) ne $sig->($got{cut_int_b64_1});
    }
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
print join("\t", qw(label keys sources T arm partner missed str_int_results_differ int_cut_results_differ ms_median ms_min ms_max
                    index_build_ms_median)), "\n";
for my $T (@T) {
    for my $am (@arms) {
        printf "%s\t%d\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%.3f\t%.3f\t%.3f\t%.1f\n",
            $label, scalar @keys, scalar @src, $T, $am, $partner{$T} // 0, $missed{$am}{$T} // 0,
            $differ{$T} // 0, $differ_cut{$T} // 0, $median->(@{$ms{$am}{$T}}), min(@{$ms{$am}{$T}}), max(@{$ms{$am}{$T}}),
            ($am =~ /_int_/ ? $median->(@build_int) : $median->(@build_str));
    }
}
