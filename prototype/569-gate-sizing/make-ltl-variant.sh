#!/usr/bin/env bash
# Stage 2. Write a scratch copy of `ltl` whose candidate search is chosen at run
# time, so whole runs can compare search strategies on real logs:
#   LTL569_SEARCH=shipped      find_consolidation_candidates() as in ltl (default)
#   LTL569_SEARCH=sized        the same sub, probe sized from the similarity, one hit admits
#   LTL569_SEARCH=hits_first   sized probe, verify from the highest hit count down,
#                              stop after the hit level holding LTL569_WANT partners
#   LTL569_SEARCH=incremental  sized probe walked rarest first, each candidate verified
#                              when first seen, stop after the posting list holding
#                              LTL569_WANT partners
# hits_first and incremental skip candidates the calling pass has already consumed.
# Nothing else in ltl changes.
#   usage: make-ltl-variant.sh <output path>
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 - "$1" <<'PY'
import re, sys, os
out_path = sys.argv[1]
src = open('ltl').read()
lines = src.split('\n')

start = [i for i, l in enumerate(lines) if l.startswith('sub find_consolidation_candidates {')]
if len(start) != 1:
    raise SystemExit("find_consolidation_candidates: %d definitions" % len(start))
n = start[0]; depth = 0; j = n
while True:
    depth += lines[j].count('{') - lines[j].count('}')
    if depth == 0:
        break
    j += 1
original = '\n'.join(lines[n:j + 1])

shipped = original.replace('sub find_consolidation_candidates {', 'sub find_consolidation_candidates_shipped {', 1)
sized = original.replace('sub find_consolidation_candidates {', 'sub find_consolidation_candidates_sized {', 1)
for old, new in [
    ('my $topk_actual = min($consolidation_discriminative_topk, scalar @disc_trigrams);',
     'my $topk_actual = min(max(1, $source_size - int(($source_size * $threshold_pct + (200 - $threshold_pct) - 1) / (200 - $threshold_pct)) + 1), scalar @disc_trigrams);'),
    ('my $loose_min = max(1, int($consolidation_prefilter_ratio * $topk_actual));', 'my $loose_min = 1;'),
]:
    if sized.count(old) != 1:
        raise SystemExit("sized arm: expected one occurrence of: %s" % old)
    sized = sized.replace(old, new)

variants = r'''
our $ltl569_search = $ENV{LTL569_SEARCH} // 'shipped';
our $ltl569_want   = $ENV{LTL569_WANT} // 1;
our $ltl569_budget = $ENV{LTL569_BUDGET} // 64;
our $ltl569_frac   = $ENV{LTL569_FRAC} // 0;
our $ltl569_sizeorder = $ENV{LTL569_SIZEORDER} // 0;
# LTL569_STATS=1: per category and phase, searches, posting entries visited, Dice calls,
# searches that returned a partner, and seconds spent searching, printed to STDERR at exit
our $ltl569_stats_on = $ENV{LTL569_STATS} // 0;
our (%ltl569_stats, $ltl569_visits, $ltl569_dice);
END {
    if ($ltl569_stats_on) {
        for my $k (sort keys %ltl569_stats) {
            my $s = $ltl569_stats{$k};
            printf STDERR "LTL569_STATS\t%s\tsearches=%d\tfound=%d\tvisits=%d\tdice=%d\tseconds=%.3f\tms_per_search=%.3f\n",
                $k, $s->{searches}, $s->{found}, $s->{visits}, $s->{dice}, $s->{seconds},
                $s->{searches} ? 1000 * $s->{seconds} / $s->{searches} : 0;
        }
    }
}
our %ltl569_int;

sub find_consolidation_candidates {
    my ($cat_gk, $source_key, $threshold_pct, $max_candidates, $skip) = @_;
    return find_consolidation_candidates_shipped($cat_gk, $source_key, $threshold_pct, $max_candidates) if $ltl569_search eq 'shipped';
    return find_consolidation_candidates_sized($cat_gk, $source_key, $threshold_pct, $max_candidates)   if $ltl569_search eq 'sized';
    return ltl569_hits_first($cat_gk, $source_key, $threshold_pct, $ltl569_want, $skip)                 if $ltl569_search eq 'hits_first';
    return ltl569_incremental($cat_gk, $source_key, $threshold_pct, $ltl569_want, $skip)                if $ltl569_search eq 'incremental';
    return ltl569_hybrid($cat_gk, $source_key, $threshold_pct, $ltl569_want, $ltl569_budget, $skip)     if $ltl569_search eq 'hybrid';
    if ($ltl569_search eq 'cut') {
        return ltl569_cut($cat_gk, $source_key, $threshold_pct, $ltl569_want, $ltl569_budget, $skip) unless $ltl569_stats_on;
        ($ltl569_visits, $ltl569_dice) = (0, 0);
        my $t0 = [gettimeofday];
        my @r = ltl569_cut($cat_gk, $source_key, $threshold_pct, $ltl569_want, $ltl569_budget, $skip);
        my $s = $ltl569_stats{"$cat_gk\t" . ($consolidation_phase // 'streaming')} //= { searches => 0, found => 0, visits => 0, dice => 0, seconds => 0 };
        $s->{searches}++;
        $s->{found}++ if @r;
        $s->{visits} += $ltl569_visits;
        $s->{dice} += $ltl569_dice;
        $s->{seconds} += tv_interval($t0);
        return @r;
    }
    die "LTL569_SEARCH=$ltl569_search is not a search strategy\n";
}

# Sized probe walked rarest first against the full index. The first $budget
# candidates met are scored when first seen; after that a candidate is scored only
# once its shared trigrams inside the probe reach ceil(T*(|r|+|s|)/200) - (|r| - p),
# below which its Dice cannot reach T. Keys scored on UUID-normalised trigrams get
# no bound. Stops after the posting list that yields $want partners.
sub ltl569_hybrid {
    my ($cat_gk, $source_key, $threshold_pct, $want, $budget, $skip) = @_;
    my $source_trigrams = $consolidation_key_trigrams{$source_key};
    return () unless $source_trigrams && %$source_trigrams;
    my $source_size = scalar keys %$source_trigrams;
    my $probe = ltl569_sized_probe($cat_gk, $source_key, $threshold_pct);
    my $outside = $source_size - scalar @$probe;
    my $min_cand_size = int($source_size * $threshold_pct / (200 - $threshold_pct));
    my $max_cand_size = int($source_size * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_trig_dice = $consolidation_key_trigrams_norm{$source_key} // $source_trigrams;
    my $source_size_dice = scalar keys %$source_trig_dice;
    my $min_dice_size = int($source_size_dice * $threshold_pct / (200 - $threshold_pct));
    my $max_dice_size = int($source_size_dice * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_normalised = exists $consolidation_key_trigrams_norm{$source_key};
    my (%hits, %need, @results);
    my $score_it = sub {
        my ($cand_key) = @_;
        my $cand_trig_dice = $consolidation_key_trigrams_norm{$cand_key} // $consolidation_key_trigrams{$cand_key};
        my $cand_size_dice = scalar keys %$cand_trig_dice;
        return if $cand_size_dice < $min_dice_size || $cand_size_dice > $max_dice_size;
        my $score = dice_coefficient($source_trig_dice, $cand_trig_dice);
        push @results, { key => $cand_key, score => $score } if $score >= $threshold_pct;
    };
    for my $trig (@$probe) {
        for my $cand_key (keys %{$consolidation_ngram_index{$cat_gk}{$trig}}) {
            next if $cand_key eq $source_key;
            my $need = $need{$cand_key};
            if (!defined $need) {
                my $cand_trigrams = $consolidation_key_trigrams{$cand_key};
                my $cand_size = defined $cand_trigrams ? scalar keys %$cand_trigrams : 0;
                if (!$cand_size || $cand_size < $min_cand_size || $cand_size > $max_cand_size
                    || ($skip && $skip->{$cand_key})) {
                    $need{$cand_key} = -1;
                    next;
                }
                if ($budget > 0) {
                    $budget--;
                    $need{$cand_key} = -1;
                    $score_it->($cand_key);
                    next;
                }
                if ($source_normalised || exists $consolidation_key_trigrams_norm{$cand_key}) {
                    $need = 1;
                } else {
                    $need = int(($threshold_pct * ($source_size + $cand_size) + 199) / 200) - $outside;
                    $need = 1 if $need < 1;
                }
                $need{$cand_key} = $need;
            }
            next if $need < 0;
            next if ++$hits{$cand_key} != $need;
            $score_it->($cand_key);
        }
        last if @results >= $want;
    }
    return sort { $b->{score} <=> $a->{score} || $a->{key} cmp $b->{key} } @results;
}

sub ltl569_sized_probe {
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

sub ltl569_verifier {
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

sub ltl569_hits_first {
    my ($cat_gk, $source_key, $threshold_pct, $want, $skip) = @_;
    return () unless $consolidation_key_trigrams{$source_key} && %{$consolidation_key_trigrams{$source_key}};
    my $probe = ltl569_sized_probe($cat_gk, $source_key, $threshold_pct);
    my $verify = ltl569_verifier($source_key, $threshold_pct);
    my %hits;
    for my $trig (@$probe) {
        for my $cand_key (keys %{$consolidation_ngram_index{$cat_gk}{$trig}}) {
            next if $cand_key eq $source_key;
            $hits{$cand_key}++;
        }
    }
    my @by_hits;
    for my $cand_key (keys %hits) {
        next if $skip && $skip->{$cand_key};
        push @{$by_hits[$hits{$cand_key}]}, $cand_key;
    }
    my @results;
    for (my $h = $#by_hits; $h >= 1; $h--) {
        next unless $by_hits[$h];
        for my $cand_key (@{$by_hits[$h]}) {
            my $score = $verify->($cand_key);
            push @results, { key => $cand_key, score => $score } if $score >= 0;
        }
        last if @results >= $want;
    }
    return sort { $b->{score} <=> $a->{score} || $a->{key} cmp $b->{key} } @results;
}

sub ltl569_incremental {
    my ($cat_gk, $source_key, $threshold_pct, $want, $skip) = @_;
    return () unless $consolidation_key_trigrams{$source_key} && %{$consolidation_key_trigrams{$source_key}};
    my $probe = ltl569_sized_probe($cat_gk, $source_key, $threshold_pct);
    my $verify = ltl569_verifier($source_key, $threshold_pct);
    my %seen = ($source_key => 1);
    my @results;
    for my $trig (@$probe) {
        for my $cand_key (keys %{$consolidation_ngram_index{$cat_gk}{$trig}}) {
            next if $seen{$cand_key}++;
            next if $skip && $skip->{$cand_key};
            my $score = $verify->($cand_key);
            push @results, { key => $cand_key, score => $score } if $score >= 0;
        }
        last if @results >= $want;
    }
    return sort { $b->{score} <=> $a->{score} || $a->{key} cmp $b->{key} } @results;
}

# Integer-id index for LTL569_SEARCH=cut, built beside the hash index for the same
# keys in batch order: posting arrays split into non-UUID and UUID keys, per-key raw
# and scored sizes, scored trigram sets, and the sorted raw sizes of non-UUID keys.
sub ltl569_build_int_index {
    my ($cat_gk, $log_keys_ref) = @_;
    my (%ids, @keys, %post_plain, %post_norm, %post_size, @size, @size_dice, @trig_dice, @norm);
    # With LTL569_SIZEORDER ids follow raw trigram count (then batch order), so every
    # posting array is ordered by key size and a search can crop it to its size filter
    my @order = grep { $consolidation_key_trigrams{$_} } @$log_keys_ref;
    if ($ltl569_sizeorder) {
        my (%pos, %sz);
        my $n = 0;
        $pos{$_} //= $n++ for @order;
        $sz{$_} = scalar keys %{$consolidation_key_trigrams{$_}} for @order;
        @order = sort { $sz{$a} <=> $sz{$b} || $pos{$a} <=> $pos{$b} } @order;
    }
    for my $log_key (@order) {
        my $trigrams = $consolidation_key_trigrams{$log_key};
        next unless $trigrams;
        next if exists $ids{$log_key};
        my $id = scalar @keys;
        push @keys, $log_key;
        $ids{$log_key} = $id;
        $size[$id] = scalar keys %$trigrams;
        my $norm_t = $consolidation_key_trigrams_norm{$log_key};
        $norm[$id] = $norm_t ? 1 : 0;
        $trig_dice[$id] = $norm_t // $trigrams;
        $size_dice[$id] = scalar keys %{$trig_dice[$id]};
        my $target = $norm_t ? \%post_norm : \%post_plain;
        for my $t (keys %$trigrams) { push @{$target->{$t}}, $id; $post_size{$t}++; }
    }
    my @plain_sizes = sort { $a <=> $b } map { $size[$_] } grep { !$norm[$_] } 0 .. $#keys;
    $ltl569_int{$cat_gk} = { ids => \%ids, keys => \@keys, post_plain => \%post_plain, post_norm => \%post_norm,
                             post_size => \%post_size, size => \@size, size_dice => \@size_dice,
                             trig_dice => \@trig_dice, norm => \@norm, plain_sizes => \@plain_sizes };
}

# Sized probe over the integer index; the first $budget candidates met are scored when
# first seen, the rest only once their shared trigrams reach the overlap their size
# needs (no bound for UUID keys). Past the position where no new non-UUID candidate
# can reach its bound, only candidates already seen are followed, and the walk of
# non-UUID lists ends once none of them can still qualify.
sub ltl569_cut {
    my ($cat_gk, $source_key, $threshold_pct, $want, $budget, $skip) = @_;
    my $ix = $ltl569_int{$cat_gk} or return ();
    my $sid = $ix->{ids}{$source_key};
    return () unless defined $sid;
    my ($size, $size_dice, $trig_dice, $norm) = @{$ix}{qw(size size_dice trig_dice norm)};
    my ($post_plain, $post_norm, $post_size) = @{$ix}{qw(post_plain post_norm post_size)};
    my $source_size = $size->[$sid];
    return () if $source_size == 0;
    my @probe = sort { ($post_size->{$a} <=> $post_size->{$b}) || ($a cmp $b) }
                keys %{$consolidation_key_trigrams{$source_key}};
    my $p = min(max(1, $source_size - int(($source_size * $threshold_pct + (200 - $threshold_pct) - 1) / (200 - $threshold_pct)) + 1), scalar @probe);
    splice(@probe, $p);
    my $outside = $source_size - $p;
    my $min_cand_size = int($source_size * $threshold_pct / (200 - $threshold_pct));
    my $max_cand_size = int($source_size * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_trig_dice = $trig_dice->[$sid];
    my $source_size_dice = $size_dice->[$sid];
    my $min_dice_size = int($source_size_dice * $threshold_pct / (200 - $threshold_pct));
    my $max_dice_size = int($source_size_dice * (200 - $threshold_pct) / $threshold_pct) + 1;
    my $source_normalised = $norm->[$sid];
    my $sum_const = $threshold_pct * $source_size + 199;

    my $cut = $p - 1;
    if (!$source_normalised) {
        my $sizes = $ix->{plain_sizes};
        my ($lo, $hi) = (0, scalar @$sizes);
        while ($lo < $hi) { my $mid = int(($lo + $hi) / 2); if ($sizes->[$mid] < $min_cand_size) { $lo = $mid + 1 } else { $hi = $mid } }
        if ($lo >= @$sizes || $sizes->[$lo] > $max_cand_size) { $cut = -1; }
        else {
            my $need_min = int(($sum_const + $threshold_pct * $sizes->[$lo]) / 200) - $outside;
            $need_min = 1 if $need_min < 1;
            $cut = $p - $need_min;
        }
    }

    # With LTL569_FRAC > 0 a candidate is scored once its hits reach that fraction of its
    # bound; Dice is exact, so a candidate that fails there cannot qualify and is dropped.
    my (@hits, @need, @verify_at, @deadline, @dying, @results);
    my $live = 0;
    $need[$sid] = -1;
    my $score_it = sub {
        my ($cid) = @_;
        my $cs = $size_dice->[$cid];
        return if $cs < $min_dice_size || $cs > $max_dice_size;
        $ltl569_dice++;
        my $score = dice_coefficient($source_trig_dice, $trig_dice->[$cid]);
        push @results, { key => $ix->{keys}[$cid], score => $score } if $score >= $threshold_pct;
    };
    # Size-ordered ids: the ids whose raw size is inside the size filter form one range
    my ($id_lo, $id_hi) = (0, $#{$ix->{keys}});
    if ($ltl569_sizeorder) {
        my ($lo, $hi) = (0, scalar @$size);
        while ($lo < $hi) { my $mid = ($lo + $hi) >> 1; if ($size->[$mid] < $min_cand_size) { $lo = $mid + 1 } else { $hi = $mid } }
        $id_lo = $lo;
        ($lo, $hi) = ($id_lo, scalar @$size);
        while ($lo < $hi) { my $mid = ($lo + $hi) >> 1; if ($size->[$mid] <= $max_cand_size) { $lo = $mid + 1 } else { $hi = $mid } }
        $id_hi = $lo - 1;
    }
    for my $i (0 .. $p - 1) {
        my $trig = $probe[$i];
        my @lists = ($source_normalised || $i <= $cut || $live > 0) ? ($post_plain->{$trig}, $post_norm->{$trig}) : ($post_norm->{$trig});
        for my $list (@lists) {
            next unless $list;
            my $start = 0;
            if ($ltl569_sizeorder) {
                my ($lo, $hi) = (0, scalar @$list);
                while ($lo < $hi) { my $mid = ($lo + $hi) >> 1; if ($list->[$mid] < $id_lo) { $lo = $mid + 1 } else { $hi = $mid } }
                $start = $lo;
            }
            for my $k ($start .. $#$list) {
                my $cid = $list->[$k];
                last if $cid > $id_hi;
                $ltl569_visits++;
                my $need = $need[$cid];
                if (!defined $need) {
                    next if !$source_normalised && !$norm->[$cid] && $i > $cut;
                    my $cand_size = $size->[$cid];
                    if ($cand_size < $min_cand_size || $cand_size > $max_cand_size
                        || ($skip && $skip->{$ix->{keys}[$cid]})) { $need[$cid] = -1; next; }
                    if ($budget > 0) { $budget--; $need[$cid] = -1; $score_it->($cid); next; }
                    if ($source_normalised || $norm->[$cid]) { $need = 1; }
                    else { $need = int(($sum_const + $threshold_pct * $cand_size) / 200) - $outside; $need = 1 if $need < 1; }
                    $need[$cid] = $need;
                    $verify_at[$cid] = $ltl569_frac > 0 ? max(1, int($need * $ltl569_frac + 0.999)) : $need;
                    if ($need > 1) {
                        # With h hits after position i it can still reach its bound while i <= p - 1 - need + h
                        my $d = $p - $need;
                        if ($d < $i) { $need[$cid] = -1; next; }
                        $deadline[$cid] = $d; $dying[$d]++; $live++;
                    }
                }
                next if $need < 0;
                if ($need > 1 && defined $hits[$cid] && $deadline[$cid] < $i - 1) { $need[$cid] = -1; next; }
                my $h = ++$hits[$cid];
                if ($h == $verify_at[$cid]) {
                    if ($need > 1) { $dying[$deadline[$cid]]--; $live--; }
                    $need[$cid] = -1;
                    $score_it->($cid);
                } elsif ($h > 1) {
                    $dying[$deadline[$cid]]--; $deadline[$cid]++; $dying[$deadline[$cid]]++;
                }
            }
        }
        $live -= $dying[$i - 1] // 0 if $i > 0;
        last if @results >= $want;
        last if !$source_normalised && $i >= $cut && $live <= 0 && !grep { $post_norm->{$probe[$_]} } $i + 1 .. $p - 1;
    }
    return sort { $b->{score} <=> $a->{score} || $a->{key} cmp $b->{key} } @results;
}
'''

lines[n:j + 1] = [shipped, '', sized, variants]
out = '\n'.join(lines)
hook_old = '    return $indexed;\n}'
if out.count(hook_old) != 1:
    raise SystemExit("index build hook: expected one occurrence of the index build's return")
out = out.replace(hook_old, "    ltl569_build_int_index($cat_gk, $log_keys_ref) if $main::ltl569_search eq 'cut';\n" + hook_old)
# The cutoff search reads only the integer index: its mode does not fill the hash postings
hash_post_old = ('        for my $trig (keys %$trigrams) {\n'
                 '            $consolidation_ngram_index{$cat_gk}{$trig}{$log_key} = 1;\n'
                 '        }\n')
if out.count(hash_post_old) != 1:
    raise SystemExit("hash posting loop: expected one occurrence")
out = out.replace(hash_post_old,
                  "        if ($main::ltl569_search ne 'cut') {\n" + hash_post_old + "        }\n")
# The integer index is freed where the hash index is, and reported beside it under -mem
free_old = '    delete $consolidation_ngram_index{$cat_gk};\n    delete $consolidation_posting_size{$cat_gk};\n'
if out.count(free_old) != 2:
    raise SystemExit("index cleanup: expected two occurrences, found %d" % out.count(free_old))
out = out.replace(free_old, free_old + '    delete $main::ltl569_int{$cat_gk};\n')
mem_old = '        consolidation_posting_size => Devel::Size::total_size(\\%consolidation_posting_size),\n'
if out.count(mem_old) != 1:
    raise SystemExit("memory structures: expected one posting size entry")
out = out.replace(mem_old, mem_old + '        ltl569_int_index => Devel::Size::total_size(\\%main::ltl569_int),\n')
calls = [
    ('find_consolidation_candidates($cat_gk, $key, $consolidation_threshold);',
     'find_consolidation_candidates($cat_gk, $key, $consolidation_threshold, undef, \\%consumed);'),
    ('find_consolidation_candidates($cat_gk, $log_key, $consolidation_threshold);',
     'find_consolidation_candidates($cat_gk, $log_key, $consolidation_threshold, undef, \\%consumed);'),
]
for old, new in calls:
    if out.count(old) != 1:
        raise SystemExit("call site: expected one occurrence of: %s" % old)
    out = out.replace(old, new)
open(out_path, 'w').write(out)
os.chmod(out_path, 0o755)
print("wrote %s" % out_path)
PY
