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

sub find_consolidation_candidates {
    my ($cat_gk, $source_key, $threshold_pct, $max_candidates, $skip) = @_;
    return find_consolidation_candidates_shipped($cat_gk, $source_key, $threshold_pct, $max_candidates) if $ltl569_search eq 'shipped';
    return find_consolidation_candidates_sized($cat_gk, $source_key, $threshold_pct, $max_candidates)   if $ltl569_search eq 'sized';
    return ltl569_hits_first($cat_gk, $source_key, $threshold_pct, $ltl569_want, $skip)                 if $ltl569_search eq 'hits_first';
    return ltl569_incremental($cat_gk, $source_key, $threshold_pct, $ltl569_want, $skip)                if $ltl569_search eq 'incremental';
    die "LTL569_SEARCH=$ltl569_search is not a search strategy\n";
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
'''

lines[n:j + 1] = [shipped, '', sized, variants]
out = '\n'.join(lines)
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
