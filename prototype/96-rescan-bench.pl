#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(time);
use List::Util qw(min max);

# ============================================================================
# Benchmark: Re-scan approaches for #96 Fuzzy Message Consolidation
#
# Tests three approaches for matching N strings against M compiled patterns:
#   1. Perl loop:       for each string, test each pattern with $str =~ $pat
#   2. Alternation:     combine patterns into qr/(?:p1)|(?:p2)|.../ single eval
#   3. Inline::C loop:  move the match loop to C using Perl's regex engine
#
# Uses real patterns discovered from ApplicationLog to test realistic scenarios.
# ============================================================================

use Inline C => <<'END_C';

#include <string.h>

/* Match a string against an array of compiled qr// patterns.
 * Returns the index of the first matching pattern, or -1 if none match.
 * Uses Perl's native regex engine — no external libraries needed.
 */
int match_first_pattern_c(SV* string_sv, AV* patterns_av) {
    dTHX;
    STRLEN retlen;
    char* input = SvPV(string_sv, retlen);
    int pattern_count = av_len(patterns_av) + 1;

    for (int i = 0; i < pattern_count; i++) {
        SV** pattern_svp = av_fetch(patterns_av, i, 0);
        if (!pattern_svp || !SvROK(*pattern_svp)) continue;

        REGEXP* rx = (REGEXP*)SvRV(*pattern_svp);
        if (SvTYPE((SV*)rx) != SVt_REGEXP) continue;

        if (pregexec(rx, input, input + retlen, input, 0, string_sv, 0)) {
            return i;
        }
    }

    return -1;
}

/* Batch match: test all strings against all patterns.
 * Returns an AV* of integers: matched pattern index or -1.
 * This is the key optimization — the entire double loop runs in C,
 * eliminating per-iteration Perl interpreter overhead.
 */
SV* batch_match_c(AV* strings_av, AV* patterns_av) {
    dTHX;
    int string_count = av_len(strings_av) + 1;
    int pattern_count = av_len(patterns_av) + 1;

    AV* results = newAV();
    av_extend(results, string_count - 1);

    /* Pre-extract pattern REGEXP* pointers for the inner loop */
    REGEXP** rxs = (REGEXP**)malloc(pattern_count * sizeof(REGEXP*));
    for (int j = 0; j < pattern_count; j++) {
        SV** p = av_fetch(patterns_av, j, 0);
        if (p && SvROK(*p) && SvTYPE(SvRV(*p)) == SVt_REGEXP) {
            rxs[j] = (REGEXP*)SvRV(*p);
        } else {
            rxs[j] = NULL;
        }
    }

    for (int i = 0; i < string_count; i++) {
        SV** s = av_fetch(strings_av, i, 0);
        if (!s) {
            av_push(results, newSViv(-1));
            continue;
        }

        STRLEN retlen;
        char* input = SvPV(*s, retlen);
        int matched = -1;

        for (int j = 0; j < pattern_count; j++) {
            if (!rxs[j]) continue;
            if (pregexec(rxs[j], input, input + retlen, input, 0, *s, 0)) {
                matched = j;
                break;
            }
        }

        av_push(results, newSViv(matched));
    }

    free(rxs);
    return newRV_noinc((SV*)results);
}

SV* compute_mask_c(const char *str_a, const char *str_b) {
    int len_a = strlen(str_a);
    int len_b = strlen(str_b);
    int min_len = len_a < len_b ? len_a : len_b;
    int prefix_len = 0;
    while (prefix_len < min_len && str_a[prefix_len] == str_b[prefix_len]) prefix_len++;
    int suffix_len = 0;
    while (suffix_len < (min_len - prefix_len) && str_a[len_a-1-suffix_len] == str_b[len_b-1-suffix_len]) suffix_len++;
    char *mask = (char *)calloc(len_a, 1);
    int i;
    for (i = 0; i < prefix_len; i++) mask[i] = 1;
    for (i = 0; i < suffix_len; i++) mask[len_a-1-i] = 1;
    int mid_a = len_a - prefix_len - suffix_len;
    int mid_b = len_b - prefix_len - suffix_len;
    if (mid_a > 0 && mid_b > 0) {
        const char *a = str_a + prefix_len, *b = str_b + prefix_len;
        int m = mid_a, n = mid_b;
        int k = (m > n ? m : n) * 6 / 10 + 2;
        int big = m + n + 1;
        int row_bytes = (n + 1 + 3) / 4;
        unsigned char *dir = (unsigned char *)calloc((m+1), row_bytes);
        int *prev = (int *)malloc((n+1) * sizeof(int));
        int *curr = (int *)malloc((n+1) * sizeof(int));
        int j;
        for (j = 0; j <= n; j++) prev[j] = j;
        for (j = 1; j <= n && j <= k; j++) { dir[j/4] |= (2 << ((j%4)*2)); }
        for (i = 1; i <= m; i++) {
            int j_min = i - k; if (j_min < 1) j_min = 1;
            int j_max = i + k; if (j_max > n) j_max = n;
            unsigned char *dr = dir + i * row_bytes;
            curr[0] = i;
            for (j = 1; j < j_min; j++) curr[j] = big;
            for (j = j_min; j <= j_max; j++) {
                if (a[i-1] == b[j-1]) { curr[j] = prev[j-1]; }
                else {
                    int sc = prev[j-1]+1, dc = prev[j]+1, ic = curr[j-1]+1;
                    if (sc <= dc && sc <= ic) { curr[j] = sc; }
                    else if (dc <= ic) { curr[j] = dc; dr[j/4] |= (1 << ((j%4)*2)); }
                    else { curr[j] = ic; dr[j/4] |= (2 << ((j%4)*2)); }
                }
            }
            for (j = j_max+1; j <= n; j++) curr[j] = big;
            int *tmp = prev; prev = curr; curr = tmp;
        }
        i = m; j = n;
        while (i > 0 && j > 0) {
            unsigned char *dr = dir + i * row_bytes;
            int d = (dr[j/4] >> ((j%4)*2)) & 3;
            if (d == 0) { if (a[i-1] == b[j-1]) mask[prefix_len+i-1] = 1; i--; j--; }
            else if (d == 1) { i--; } else { j--; }
        }
        free(dir); free(prev); free(curr);
    }
    AV *av = newAV();
    av_extend(av, len_a - 1);
    for (i = 0; i < len_a; i++) av_push(av, newSViv(mask[i]));
    free(mask);
    return newRV_noinc((SV*)av);
}

END_C

# --- CLI Options ---
my $file;
my $threshold = 80;
my $trigger = 5000;
my $message_length_cap = 300;
my $occurrence_ceiling = 3;
my $iterations = 3;

GetOptions(
    'file=s'       => \$file,
    'threshold=i'  => \$threshold,
    'trigger=i'    => \$trigger,
    'ceiling=i'    => \$occurrence_ceiling,
    'iterations=i' => \$iterations,
) or die "Usage: $0 --file <logfile> [--threshold N] [--iterations N]\n";

die "Error: --file is required\n" unless defined $file;
die "Error: file '$file' not found\n" unless -f $file;

# --- ThingWorx regex ---
my $twx_regex = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;

# ========================================================================
# Phase 1: Parse + discover patterns (reuse from main prototype)
# ========================================================================

my %log_messages;
my %key_message;
my %ngram_index;
my %key_trigrams;

print "Parsing: $file\n";
my $t0 = time();

open(my $fh, '<', $file) or die "Cannot open $file: $!\n";
while (my $line = <$fh>) {
    chomp $line;
    if (my ($timestamp, $category, $object, $instance, $user, $session, $platform, $thread, $message) = $line =~ $twx_regex) {
        my $max_object_length = 25;
        my $truncated_thread = substr($thread, 0, 20);
        my $truncated_object = substr($object, length($object) > $max_object_length ? length($object) - $max_object_length : 0, $max_object_length);
        my $log_key = substr("[$category] [$truncated_thread] [$truncated_object] $message", 0, 350);
        $log_messages{$category}{$log_key}{occurrences}++;
        $key_message{$log_key} //= $log_key;
    }
}
close($fh);

printf "Parsed in %.2f s\n", time() - $t0;

for my $cat (sort keys %log_messages) {
    printf "  %-10s %6d unique keys\n", $cat, scalar keys %{$log_messages{$cat}};
}

# --- N-gram functions (copied from prototype) ---
sub get_trigrams {
    my ($str) = @_;
    my $capped = substr($str, 0, $message_length_cap);
    my %trigrams;
    for my $i (0 .. length($capped) - 3) {
        $trigrams{substr($capped, $i, 3)} = 1;
    }
    return \%trigrams;
}

sub dice_coefficient {
    my ($trig_a, $trig_b) = @_;
    my $size_a = scalar keys %$trig_a;
    my $size_b = scalar keys %$trig_b;
    return 0 if $size_a == 0 || $size_b == 0;
    my $intersection = 0;
    if ($size_a <= $size_b) {
        for my $t (keys %$trig_a) { $intersection++ if exists $trig_b->{$t}; }
    } else {
        for my $t (keys %$trig_b) { $intersection++ if exists $trig_a->{$t}; }
    }
    return int((2 * $intersection * 100) / ($size_a + $size_b));
}

sub build_ngram_index {
    my ($category, $log_keys_ref) = @_;
    for my $log_key (@$log_keys_ref) {
        my $message = $key_message{$log_key};
        next unless defined $message;
        my $trigrams = get_trigrams($message);
        $key_trigrams{$log_key} = $trigrams;
        for my $trig (keys %$trigrams) {
            $ngram_index{$category}{$trig}{$log_key} = 1;
        }
    }
}

sub find_candidates {
    my ($category, $source_key, $threshold_pct) = @_;
    my $source_trigrams = $key_trigrams{$source_key};
    return () unless defined $source_trigrams;
    my $source_size = scalar keys %$source_trigrams;
    return () if $source_size == 0;
    my $min_hits = int($threshold_pct * $source_size / 100);
    my $min_cand_size = int($source_size * $threshold_pct / (200 - $threshold_pct));
    my $max_cand_size = int($source_size * (200 - $threshold_pct) / $threshold_pct) + 1;
    my %candidate_hits;
    for my $trig (keys %$source_trigrams) {
        next unless exists $ngram_index{$category}{$trig};
        for my $cand_key (keys %{$ngram_index{$category}{$trig}}) {
            next if $cand_key eq $source_key;
            $candidate_hits{$cand_key}++;
        }
    }
    my @top = sort { $candidate_hits{$b} <=> $candidate_hits{$a} }
              grep { $candidate_hits{$_} >= $min_hits } keys %candidate_hits;
    splice(@top, 50) if @top > 50;
    my @results;
    for my $ck (@top) {
        my $ct = $key_trigrams{$ck};
        next unless $ct;
        my $cs = scalar keys %$ct;
        next if $cs < $min_cand_size || $cs > $max_cand_size;
        my $score = dice_coefficient($source_trigrams, $ct);
        push @results, { key => $ck, score => $score } if $score >= $threshold_pct;
    }
    return sort { $b->{score} <=> $a->{score} } @results;
}

# --- Alignment functions (Inline::C compute_mask from prototype) ---
# compute_mask_c is in the Inline C block above

sub compute_mask { return compute_mask_c($_[0], $_[1]); }

sub coalesce_mask {
    my ($mask) = @_;
    my @m = @$mask;
    my $len = scalar @m;
    my $i = 0;
    while ($i < $len) {
        if ($m[$i] == 1) {
            my $start = $i;
            while ($i < $len && $m[$i] == 1) { $i++; }
            my $run_len = $i - $start;
            if ($run_len < 3) {
                my $vb = ($start == 0) ? 0 : ($m[$start-1] == 0);
                my $va = ($i >= $len) ? 0 : ($m[$i] == 0);
                if ($vb && $va) { $m[$_] = 0 for ($start .. $start + $run_len - 1); }
            }
        } else { $i++; }
    }
    $i = 0;
    while ($i < $len) {
        if ($m[$i] == 0) {
            my $ss = $i; my $j = $i;
            while ($j < $len) {
                if ($m[$j] == 1) {
                    my $ks = $j;
                    while ($j < $len && $m[$j] == 1) { $j++; }
                    if ($j - $ks >= 10) { $j = $ks; last; }
                } else { $j++; }
            }
            my $sl = $j - $ss;
            if ($sl >= 5) {
                my $kc = 0;
                for my $k ($ss..$j-1) { $kc++ if $m[$k] == 1; }
                if ($kc / $sl < 0.40) { $m[$_] = 0 for ($ss..$j-1); }
            }
            $i = $j;
        } else { $i++; }
    }
    return \@m;
}

sub derive_canonical {
    my ($ref, $mask) = @_;
    my @chars = split //, $ref;
    my $result = '';
    my $inv = 0;
    for my $i (0..$#chars) {
        if ($mask->[$i]) {
            if ($chars[$i] eq '*') { $result .= '*' unless $inv; $inv = 1; }
            else { $inv = 0; $result .= $chars[$i]; }
        } else { $result .= '*' unless $inv; $inv = 1; }
    }
    return $result;
}

sub derive_regex {
    my ($ref, $mask) = @_;
    my @chars = split //, $ref;
    my $pattern = '^';
    my $lit = '';
    my $inv = 0;
    for my $i (0..$#chars) {
        if ($mask->[$i]) {
            if ($chars[$i] eq '*') {
                if (length $lit) { $pattern .= quotemeta($lit); $lit = ''; }
                $inv = 1 unless $inv;
            } else {
                if ($inv) { $pattern .= '.+?'; $inv = 0; }
                $lit .= $chars[$i];
            }
        } else {
            if (length $lit) { $pattern .= quotemeta($lit); $lit = ''; }
            $inv = 1 unless $inv;
        }
    }
    $pattern .= '.+?' if $inv;
    $pattern .= quotemeta($lit) if length $lit;
    $pattern .= '$';
    return qr/$pattern/;
}

# ========================================================================
# Discover patterns (simplified Phase 4 — just discovery, no stats)
# ========================================================================

print "\n=== Discovering patterns ===\n";
my $t_disc = time();

my %discovered_patterns;  # {category} => [ { pattern => qr//, canonical => $str }, ... ]

for my $cat (sort keys %log_messages) {
    my @keys = keys %{$log_messages{$cat}};
    next if @keys < 10;

    my @eligible = grep { ($log_messages{$cat}{$_}{occurrences} // 1) < $occurrence_ceiling } @keys;
    next if @eligible < 2;

    my $limit = min($trigger, scalar @eligible);
    my @batch = @eligible[0..$limit-1];

    delete $ngram_index{$cat};
    build_ngram_index($cat, \@batch);

    my %consumed;
    my $max_search = min(500, scalar @batch);
    my $searched = 0;

    for my $key (@batch) {
        last if $searched >= $max_search;
        next if $consumed{$key};
        $searched++;

        my @matches = find_candidates($cat, $key, $threshold);
        for my $match (@matches) {
            next if $consumed{$match->{key}};
            my $msg_a = substr($key_message{$key} // '', 0, $message_length_cap);
            my $msg_b = substr($key_message{$match->{key}} // '', 0, $message_length_cap);
            my $raw_mask = compute_mask($msg_a, $msg_b);
            my $mask = coalesce_mask($raw_mask);
            my $canonical = derive_canonical($msg_a, $mask);
            my $regex = derive_regex($msg_a, $mask);
            next unless ($msg_a =~ $regex) && ($msg_b =~ $regex);

            $consumed{$key} = 1;
            $consumed{$match->{key}} = 1;
            push @{$discovered_patterns{$cat}}, { pattern => $regex, canonical => $canonical };
            last;
        }
    }

    printf "  %-10s %d patterns from %d keys\n", $cat, scalar @{$discovered_patterns{$cat} // []}, scalar @keys;
}

printf "Discovery time: %.2f s\n", time() - $t_disc;

# ========================================================================
# Build test data: strings to match = all unmatched keys per category
# ========================================================================

print "\n=== Benchmark: Re-scan approaches ===\n";

for my $cat (sort keys %discovered_patterns) {
    my @patterns = @{$discovered_patterns{$cat}};
    next unless @patterns >= 2;

    my @all_keys = keys %{$log_messages{$cat}};
    my @test_strings;
    for my $key (@all_keys) {
        my $msg = $key_message{$key};
        next unless defined $msg;
        push @test_strings, substr($msg, 0, $message_length_cap);
    }

    my $n_strings = scalar @test_strings;
    my $n_patterns = scalar @patterns;
    printf "\n--- %s: %d strings × %d patterns = %d potential evals ---\n",
        $cat, $n_strings, $n_patterns, $n_strings * $n_patterns;

    # --- Approach 1: Perl loop (baseline) ---
    my @perl_results;
    my $t_perl_total = 0;
    for my $iter (1..$iterations) {
        @perl_results = ();
        my $t1 = time();
        for my $str (@test_strings) {
            my $matched = -1;
            for my $i (0..$#patterns) {
                if ($str =~ $patterns[$i]{pattern}) {
                    $matched = $i;
                    last;
                }
            }
            push @perl_results, $matched;
        }
        $t_perl_total += time() - $t1;
    }
    my $t_perl = $t_perl_total / $iterations;
    my $perl_matched = scalar grep { $_ >= 0 } @perl_results;
    printf "  Perl loop:       %.4f s  (%d matched, %d unmatched)\n",
        $t_perl, $perl_matched, $n_strings - $perl_matched;

    # --- Approach 2: Alternation regex ---
    # Build mega-pattern from all pattern sources
    my $alt_source = join('|', map {
        my $p = "$_->{pattern}";
        # Extract pattern body from qr/^...$/ — strip (?^: wrapper and anchors
        $p =~ s/^\(\?\^[a-z]*://;
        $p =~ s/\)$//;
        "($_)";  # wrap each in capture group for identification
    } @patterns);
    my $alt_regex = eval { qr/$alt_source/ };
    my $alt_ok = defined $alt_regex;

    my @alt_results;
    my $t_alt_total = 0;
    if ($alt_ok) {
        for my $iter (1..$iterations) {
            @alt_results = ();
            my $t1 = time();
            for my $str (@test_strings) {
                if ($str =~ $alt_regex) {
                    # Find which group matched
                    my $matched = -1;
                    for my $i (1..scalar @patterns) {
                        if (defined $+[$i] && $+[$i] > 0) {
                            $matched = $i - 1;
                            last;
                        }
                    }
                    push @alt_results, $matched;
                } else {
                    push @alt_results, -1;
                }
            }
            $t_alt_total += time() - $t1;
        }
        my $t_alt = $t_alt_total / $iterations;
        my $alt_matched = scalar grep { $_ >= 0 } @alt_results;
        printf "  Alternation:     %.4f s  (%d matched, %d unmatched)  %.1fx vs Perl\n",
            $t_alt, $alt_matched, $n_strings - $alt_matched, $t_perl / ($t_alt || 0.0001);
    } else {
        printf "  Alternation:     FAILED to compile (%s)\n", $@ // 'unknown error';
    }

    # --- Approach 3: Inline::C batch match ---
    my @pattern_objects = map { $_->{pattern} } @patterns;
    my @c_results;
    my $t_c_total = 0;
    for my $iter (1..$iterations) {
        my $t1 = time();
        my $results_ref = batch_match_c(\@test_strings, \@pattern_objects);
        @c_results = @$results_ref;
        $t_c_total += time() - $t1;
    }
    my $t_c = $t_c_total / $iterations;
    my $c_matched = scalar grep { $_ >= 0 } @c_results;
    printf "  Inline::C batch: %.4f s  (%d matched, %d unmatched)  %.1fx vs Perl\n",
        $t_c, $c_matched, $n_strings - $c_matched, $t_perl / ($t_c || 0.0001);

    # --- Verify correctness ---
    my $mismatches = 0;
    for my $i (0..$#perl_results) {
        if ($perl_results[$i] != $c_results[$i]) {
            $mismatches++;
            if ($mismatches <= 3) {
                printf "    MISMATCH at [%d]: Perl=%d, C=%d, str=%.80s\n",
                    $i, $perl_results[$i], $c_results[$i], $test_strings[$i];
            }
        }
    }
    if ($alt_ok) {
        my $alt_mismatches = 0;
        for my $i (0..$#perl_results) {
            # Alternation may match a different pattern index (both valid)
            # Only check matched-vs-unmatched agreement
            my $perl_hit = $perl_results[$i] >= 0 ? 1 : 0;
            my $alt_hit = $alt_results[$i] >= 0 ? 1 : 0;
            $alt_mismatches++ if $perl_hit != $alt_hit;
        }
        printf "  Alternation correctness: %d match/unmatch disagreements\n", $alt_mismatches if $alt_mismatches > 0;
    }
    printf "  C correctness: %d mismatches vs Perl\n", $mismatches if $mismatches > 0;
    printf "  All approaches agree.\n" if $mismatches == 0 && (!$alt_ok || (grep { ($perl_results[$_] >= 0 ? 1 : 0) != ($alt_results[$_] >= 0 ? 1 : 0) } 0..$#perl_results) == 0);
}
