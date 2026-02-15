#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(time);
use List::Util qw(min max);

use Inline C => <<'END_C';

/* Banded edit distance with backtrace — returns mask as arrayref.
 * Handles prefix/suffix stripping in C for zero Perl overhead.
 */
SV* compute_mask_c(const char *str_a, const char *str_b) {
    int len_a = strlen(str_a);
    int len_b = strlen(str_b);
    int min_len = len_a < len_b ? len_a : len_b;

    int prefix_len = 0;
    while (prefix_len < min_len && str_a[prefix_len] == str_b[prefix_len])
        prefix_len++;

    int suffix_len = 0;
    while (suffix_len < (min_len - prefix_len) &&
           str_a[len_a - 1 - suffix_len] == str_b[len_b - 1 - suffix_len])
        suffix_len++;

    char *mask = (char *)calloc(len_a, 1);
    int i;
    for (i = 0; i < prefix_len; i++) mask[i] = 1;
    for (i = 0; i < suffix_len; i++) mask[len_a - 1 - i] = 1;

    int mid_a = len_a - prefix_len - suffix_len;
    int mid_b = len_b - prefix_len - suffix_len;

    if (mid_a > 0 && mid_b > 0) {
        const char *a = str_a + prefix_len;
        const char *b = str_b + prefix_len;
        int m = mid_a, n = mid_b;
        int k = (m > n ? m : n) * 6 / 10 + 2;
        int big = m + n + 1;

        /* Direction table: 2 bits per cell, packed 4 per byte */
        int row_bytes = (n + 1 + 3) / 4;
        unsigned char *dir = (unsigned char *)calloc((m + 1), row_bytes);
        int *prev = (int *)malloc((n + 1) * sizeof(int));
        int *curr = (int *)malloc((n + 1) * sizeof(int));

        int j;
        for (j = 0; j <= n; j++) prev[j] = j;

        for (j = 1; j <= n && j <= k; j++) {
            int byte_idx = j / 4;
            int bit_shift = (j % 4) * 2;
            dir[byte_idx] |= (2 << bit_shift);
        }

        for (i = 1; i <= m; i++) {
            int j_min = i - k; if (j_min < 1) j_min = 1;
            int j_max = i + k; if (j_max > n) j_max = n;
            unsigned char *dr = dir + i * row_bytes;

            curr[0] = i;

            for (j = 1; j < j_min; j++) curr[j] = big;

            for (j = j_min; j <= j_max; j++) {
                if (a[i-1] == b[j-1]) {
                    curr[j] = prev[j-1];
                } else {
                    int sc = prev[j-1] + 1;
                    int dc = prev[j] + 1;
                    int ic = curr[j-1] + 1;
                    if (sc <= dc && sc <= ic) {
                        curr[j] = sc;
                    } else if (dc <= ic) {
                        curr[j] = dc;
                        int byte_idx = j / 4;
                        int bit_shift = (j % 4) * 2;
                        dr[byte_idx] |= (1 << bit_shift);
                    } else {
                        curr[j] = ic;
                        int byte_idx = j / 4;
                        int bit_shift = (j % 4) * 2;
                        dr[byte_idx] |= (2 << bit_shift);
                    }
                }
            }

            for (j = j_max + 1; j <= n; j++) curr[j] = big;

            int *tmp = prev; prev = curr; curr = tmp;
        }

        /* Backtrace */
        i = m; j = n;
        while (i > 0 && j > 0) {
            unsigned char *dr = dir + i * row_bytes;
            int byte_idx = j / 4;
            int bit_shift = (j % 4) * 2;
            int d = (dr[byte_idx] >> bit_shift) & 3;

            if (d == 0) {
                if (a[i-1] == b[j-1]) mask[prefix_len + i - 1] = 1;
                i--; j--;
            } else if (d == 1) {
                i--;
            } else {
                j--;
            }
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

# ============================================================================
# Prototype for #96 — Fuzzy Message Consolidation
# Phase 1: Log Parsing + N-gram Indexing + Dice Scoring
# Phase 2: Diff-Style Alignment + Mask + Canonical Form
# Phase 3: Pattern Compilation + Incoming Matching
# Phase 4: Full Consolidation Loop
# ============================================================================

# --- CLI Options ---
my $file;
my $threshold = 80;
my $trigger = 5000;
my $top_n = 20;
my $verbose = 0;
my $message_length_cap = 300;
my $occurrence_ceiling = 3;
my $max_patterns = 50;
my $final_pass = 0;
my $final_threshold = 95;
my $final_ceiling = 100;

GetOptions(
    'file=s'              => \$file,
    'threshold=i'         => \$threshold,
    'trigger=i'           => \$trigger,
    'top=i'               => \$top_n,
    'verbose'             => \$verbose,
    'ceiling=i'           => \$occurrence_ceiling,
    'max-patterns=i'      => \$max_patterns,
    'final-pass'          => \$final_pass,
    'final-threshold=i'   => \$final_threshold,
    'final-ceiling=i'     => \$final_ceiling,
) or die "Usage: $0 --file <logfile> [--threshold N] [--trigger N] [--top N] [--ceiling N] [--max-patterns N] [--final-pass] [--final-threshold N] [--final-ceiling N] [--verbose]\n";

die "Error: --file is required\n" unless defined $file;
die "Error: file '$file' not found\n" unless -f $file;

# --- Data Structures ---
my %log_messages;        # {category}{log_key} => { occurrences => N }
my %ngram_index;         # {category}{trigram}{log_key} => 1
my %posting_size;        # {category}{trigram} => count  (posting list size cache)
my %key_trigrams;        # {log_key} => { trigram => 1, ... }  (cache)
my %key_message;         # {log_key} => $message  (the message portion, for similarity)
my %canonical_patterns;  # {category} => [ { pattern => qr//, cluster_key => $key, canonical => $str, match_count => N }, ... ]

# --- ThingWorx ApplicationLog Regex (from ltl line 1827) ---
my $twx_regex = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;

# ========================================================================
# Phase 1: Parse Log File
# ========================================================================
my $t_start = time();
my $total_lines = 0;
my $matched_lines = 0;
my $unmatched_lines = 0;

print "Parsing: $file\n";
print "Threshold: ${threshold}%  Trigger: $trigger  Top: $top_n  Ceiling: $occurrence_ceiling  MaxPatterns: $max_patterns\n";
if ($final_pass) {
    print "Final pass: enabled  Threshold: ${final_threshold}%  Ceiling: $final_ceiling\n";
}
print "\n";

open(my $fh, '<', $file) or die "Cannot open $file: $!\n";
while (my $line = <$fh>) {
    chomp $line;
    $total_lines++;

    if (my ($timestamp, $category, $object, $instance, $user, $session, $platform, $thread, $message) = $line =~ $twx_regex) {
        $matched_lines++;

        my $log_level = $category;
        my $max_object_length = 25;
        my $truncated_thread = substr($thread, 0, 20);
        my $truncated_object = substr($object, length($object) > $max_object_length ? length($object) - $max_object_length : 0, $max_object_length);
        my $log_key = substr("[$log_level] [$truncated_thread] [$truncated_object] $message", 0, 350);

        $log_messages{$category}{$log_key}{occurrences}++;

        unless (exists $key_message{$log_key}) {
            $key_message{$log_key} = substr($log_key, 0, $message_length_cap);
        }
    } else {
        $unmatched_lines++;
    }
}
close($fh);

my $t_parsed = time();

my $total_categories = scalar keys %log_messages;
my $total_unique_keys = 0;
for my $cat (sort keys %log_messages) {
    $total_unique_keys += scalar keys %{$log_messages{$cat}};
}

print "=== Parsing Complete ===\n";
printf "Total lines:      %d\n", $total_lines;
printf "Matched lines:    %d\n", $matched_lines;
printf "Unmatched lines:  %d\n", $unmatched_lines;
printf "Categories:       %d\n", $total_categories;
printf "Total unique keys: %d\n", $total_unique_keys;
printf "Parse time:       %.2f s\n\n", $t_parsed - $t_start;

print "=== Category Breakdown ===\n";
for my $cat (sort keys %log_messages) {
    my $count = scalar keys %{$log_messages{$cat}};
    printf "  %-10s %6d unique keys\n", $cat, $count;
}
print "\n";

# ========================================================================
# N-gram Functions (Phase 1)
# ========================================================================

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
        for my $t (keys %$trig_a) {
            $intersection++ if exists $trig_b->{$t};
        }
    } else {
        for my $t (keys %$trig_b) {
            $intersection++ if exists $trig_a->{$t};
        }
    }

    return int((2 * $intersection * 100) / ($size_a + $size_b));
}

sub build_ngram_index {
    my ($category, $log_keys_ref) = @_;
    my $indexed = 0;
    for my $log_key (@$log_keys_ref) {
        my $message = $key_message{$log_key};
        next unless defined $message;
        my $trigrams = get_trigrams($message);
        $key_trigrams{$log_key} = $trigrams;
        for my $trig (keys %$trigrams) {
            $ngram_index{$category}{$trig}{$log_key} = 1;
        }
        $indexed++;
    }
    # Cache posting list sizes for discriminative trigram selection
    delete $posting_size{$category};
    for my $trig (keys %{$ngram_index{$category}}) {
        $posting_size{$category}{$trig} = scalar keys %{$ngram_index{$category}{$trig}};
    }
    return $indexed;
}

my $discriminative_topk = 50;       # use top-50 most discriminative trigrams
my $prefilter_ratio    = 0.30;      # require 30% of topk hits as loose pre-filter

sub find_candidates {
    my ($category, $source_key, $threshold_pct, $max_candidates) = @_;
    $max_candidates //= 50;
    my $source_trigrams = $key_trigrams{$source_key};
    return () unless defined $source_trigrams;

    my $source_size = scalar keys %$source_trigrams;
    return () if $source_size == 0;

    # Length pre-filter: Dice >= T% requires |B| >= |A|*T/(200-T) and |B| <= |A|*(200-T)/T
    my $min_cand_size = int($source_size * $threshold_pct / (200 - $threshold_pct));
    my $max_cand_size = int($source_size * (200 - $threshold_pct) / $threshold_pct) + 1;

    # Phase 1: Use top-K most discriminative trigrams (smallest posting lists)
    # to build a small candidate set cheaply. This avoids iterating huge posting
    # lists for common trigrams like "[WA", "ARN", "] [" that appear in every key.
    my $ps = $posting_size{$category};
    my @disc_trigrams = sort { ($ps->{$a} // 0) <=> ($ps->{$b} // 0) }
                        grep { exists $ngram_index{$category}{$_} }
                        keys %$source_trigrams;
    my $topk_actual = min($discriminative_topk, scalar @disc_trigrams);
    splice(@disc_trigrams, $topk_actual) if @disc_trigrams > $topk_actual;

    # Loose pre-filter threshold: require prefilter_ratio * topk hits
    my $loose_min = max(1, int($prefilter_ratio * $topk_actual));

    my %candidate_hits;
    for my $trig (@disc_trigrams) {
        for my $cand_key (keys %{$ngram_index{$category}{$trig}}) {
            next if $cand_key eq $source_key;
            $candidate_hits{$cand_key}++;
        }
    }

    # Phase 2: Full Dice verification on candidates passing the loose pre-filter.
    # The pre-filter narrows ~5000 candidates to ~200, then Dice is cheap.
    my @results;
    for my $cand_key (keys %candidate_hits) {
        next if $candidate_hits{$cand_key} < $loose_min;

        my $cand_trigrams = $key_trigrams{$cand_key};
        next unless defined $cand_trigrams;

        my $cand_size = scalar keys %$cand_trigrams;
        next if $cand_size < $min_cand_size || $cand_size > $max_cand_size;

        my $score = dice_coefficient($source_trigrams, $cand_trigrams);
        if ($score >= $threshold_pct) {
            push @results, { key => $cand_key, score => $score };
        }
    }

    @results = sort { $b->{score} <=> $a->{score} } @results;
    splice(@results, $max_candidates) if @results > $max_candidates;
    return @results;
}

# ========================================================================
# Alignment Functions (Phase 2)
# ========================================================================

# Character-level alignment returning mask array (1=keep, 0=variable).
# Uses Inline::C banded edit distance — 100x faster than pure Perl LCS DP.
sub compute_mask {
    my ($str_a, $str_b) = @_;
    return compute_mask_c($str_a, $str_b);
}

# Remove spurious keep regions that are accidental matches inside variable spans.
# Two-pass approach:
#   Pass 1: Remove short keep runs (<3 chars) surrounded by variable
#   Pass 2: Detect variable-dominated spans and collapse isolated keep islands within them
sub coalesce_mask {
    my ($mask) = @_;
    my @m = @$mask;
    my $len = scalar @m;

    # Pass 1: Remove very short keep runs (<3 chars) between variable regions
    my $i = 0;
    while ($i < $len) {
        if ($m[$i] == 1) {
            my $start = $i;
            while ($i < $len && $m[$i] == 1) { $i++; }
            my $run_len = $i - $start;

            if ($run_len < 3) {
                my $has_var_before = ($start == 0) ? 0 : ($m[$start-1] == 0);
                my $has_var_after  = ($i >= $len)  ? 0 : ($m[$i] == 0);
                if ($has_var_before && $has_var_after) {
                    for my $k ($start .. $start + $run_len - 1) {
                        $m[$k] = 0;
                    }
                }
            }
        } else {
            $i++;
        }
    }

    # Pass 2: Scan for variable-dominated spans and collapse keep islands within them.
    # A "variable span" starts at the first variable char and ends at the last variable
    # char before a long keep region (>=10 chars) or end of string.
    # Within such a span, if the keep/total ratio is below 40%, collapse all keeps.
    $i = 0;
    while ($i < $len) {
        # Find start of a variable region
        if ($m[$i] == 0) {
            my $span_start = $i;
            # Scan forward to find the end of this variable-dominated span
            # A span ends when we hit a keep run >= 10 chars, or end of string
            my $j = $i;
            while ($j < $len) {
                if ($m[$j] == 1) {
                    # Count this keep run
                    my $keep_start = $j;
                    while ($j < $len && $m[$j] == 1) { $j++; }
                    my $keep_len = $j - $keep_start;
                    # Long keep run = end of span (don't include this keep run)
                    if ($keep_len >= 10) {
                        $j = $keep_start;  # back up to before this keep run
                        last;
                    }
                    # Short keep run: continue scanning
                } else {
                    $j++;
                }
            }
            my $span_end = $j;
            my $span_len = $span_end - $span_start;

            if ($span_len >= 5) {
                # Count keeps within this span
                my $keep_count = 0;
                for my $k ($span_start .. $span_end - 1) {
                    $keep_count++ if $m[$k] == 1;
                }
                my $keep_ratio = $keep_count / $span_len;

                # If variable-dominated, collapse all keeps to variable
                if ($keep_ratio < 0.40) {
                    for my $k ($span_start .. $span_end - 1) {
                        $m[$k] = 0;
                    }
                }
            }

            $i = $span_end;
        } else {
            $i++;
        }
    }

    return \@m;
}

# Derive canonical form: keep positions retain chars, variable regions become *
sub derive_canonical {
    my ($reference_string, $mask) = @_;
    my @chars = split //, $reference_string;
    my $result = '';
    my $in_variable = 0;

    for my $i (0 .. $#chars) {
        if ($mask->[$i]) {
            # If this keep position is a literal '*' from a previous canonical,
            # treat it as variable to avoid emitting '**'
            if ($chars[$i] eq '*') {
                if (!$in_variable) {
                    $result .= '*';
                    $in_variable = 1;
                }
            } else {
                $in_variable = 0;
                $result .= $chars[$i];
            }
        } else {
            if (!$in_variable) {
                $result .= '*';
                $in_variable = 1;
            }
        }
    }

    return $result;
}

# Derive regex: keep positions become \Q..\E literals, variable regions become .+?
sub derive_regex {
    my ($reference_string, $mask) = @_;
    my @chars = split //, $reference_string;
    my $pattern = '^';
    my $literal_buf = '';
    my $in_variable = 0;

    for my $i (0 .. $#chars) {
        if ($mask->[$i]) {
            # If this keep position is a literal '*' from a previous canonical,
            # treat it as variable to avoid matching only literal asterisks
            if ($chars[$i] eq '*') {
                if (length $literal_buf) {
                    $pattern .= quotemeta($literal_buf);
                    $literal_buf = '';
                }
                if (!$in_variable) {
                    $in_variable = 1;
                }
            } else {
                if ($in_variable) {
                    $pattern .= '.+?';
                    $in_variable = 0;
                }
                $literal_buf .= $chars[$i];
            }
        } else {
            if (length $literal_buf) {
                $pattern .= quotemeta($literal_buf);
                $literal_buf = '';
            }
            if (!$in_variable) {
                $in_variable = 1;
            }
        }
    }

    # Flush remaining
    if ($in_variable) {
        $pattern .= '.+?';
    }
    if (length $literal_buf) {
        $pattern .= quotemeta($literal_buf);
    }

    $pattern .= '$';
    return qr/$pattern/;
}

# ========================================================================
# Phase 1: Build Index and Find Similar Pairs
# ========================================================================

my $t_index_start = time();
my $total_indexed = 0;
my $total_trigrams = 0;

for my $cat (sort keys %log_messages) {
    my @keys = keys %{$log_messages{$cat}};
    my $batch_size = $trigger < scalar @keys ? $trigger : scalar @keys;
    my @batch = @keys[0 .. $batch_size - 1];

    my $indexed = build_ngram_index($cat, \@batch);
    $total_indexed += $indexed;

    my $cat_trigrams = exists $ngram_index{$cat} ? scalar keys %{$ngram_index{$cat}} : 0;
    $total_trigrams += $cat_trigrams;

    printf "  %-10s indexed %d keys, %d unique trigrams\n", $cat, $indexed, $cat_trigrams if $verbose;
}

my $t_index_done = time();
printf "=== N-gram Index Built ===\n";
printf "Total indexed:    %d keys\n", $total_indexed;
printf "Total trigrams:   %d unique\n", $total_trigrams;
printf "Index time:       %.2f s\n\n", $t_index_done - $t_index_start;

# --- Find sample similar pairs per category, with diversity ---
print "=== Sample Similar Pairs with Alignment (Phase 2 Validation) ===\n";

my $pairs_found = 0;
my $pairs_searched = 0;
my $t_search_start = time();

for my $cat (sort keys %log_messages) {
    my @indexed_keys = grep { exists $key_trigrams{$_} } keys %{$log_messages{$cat}};
    next unless @indexed_keys;

    my $cat_pairs = 0;
    my $max_cat_pairs = ($cat eq 'ERROR') ? 5 : 5;  # up to 5 pairs per category
    my $max_cat_search = 500;  # search budget per category
    my $cat_searched = 0;
    my %already_paired;
    # Track which message "prefix" we've already shown, for diversity within ERROR
    my %seen_prefix;

    printf "\n--- Category: %s (%d indexed keys) ---\n", $cat, scalar @indexed_keys;

    for my $key (@indexed_keys) {
        last if $cat_searched >= $max_cat_search;
        last if $cat_pairs >= $max_cat_pairs;
        next if $already_paired{$key};

        # For diversity: extract first 30 chars of message as a "prefix signature"
        my $msg = $key_message{$key} // '';
        my $prefix = substr($msg, 0, 30);
        next if $seen_prefix{$prefix} && $cat eq 'ERROR';  # skip same-prefix in ERROR

        $cat_searched++;
        $pairs_searched++;
        my @matches = find_candidates($cat, $key, $threshold);

        for my $match (@matches) {
            next if $already_paired{$match->{key}};
            $cat_pairs++;
            $pairs_found++;
            $already_paired{$key} = 1;
            $already_paired{$match->{key}} = 1;
            $seen_prefix{$prefix} = 1;

            my $msg_a = substr($key_message{$key} // '', 0, $message_length_cap);
            my $msg_b = substr($key_message{$match->{key}} // '', 0, $message_length_cap);

            printf "\n  Pair %d (Dice: %d%%):\n", $pairs_found, $match->{score};
            printf "    A: %s\n", $msg_a;
            printf "    B: %s\n", $msg_b;

            # Phase 2: Alignment
            my $raw_mask = compute_mask($msg_a, $msg_b);
            my $mask = coalesce_mask($raw_mask);
            my $canonical = derive_canonical($msg_a, $mask);
            my $regex = derive_regex($msg_a, $mask);

            # Mask visualization: K=keep, .=variable
            my $mask_vis = join('', map { $_ ? 'K' : '.' } @$mask);
            printf "    Mask: %s\n", $mask_vis;
            printf "    Canon: %s\n", $canonical;

            # Validate regex matches both messages
            my $match_a = ($msg_a =~ $regex) ? 'Y' : 'N';
            my $match_b = ($msg_b =~ $regex) ? 'Y' : 'N';
            printf "    Regex matches: A=%s B=%s\n", $match_a, $match_b;
            if ($verbose) {
                printf "    Regex: %s\n", $regex;
            }

            last;  # one match per source key
        }
    }

    if ($cat_pairs == 0) {
        print "  (no similar pairs found)\n";
    }
}

my $t_search_done = time();
printf "\nTotal keys searched: %d\n", $pairs_searched;
printf "Total pairs found:   %d\n", $pairs_found;
printf "Search time:         %.2f s\n", $t_search_done - $t_search_start;

# ========================================================================
# Phase 3: Pattern Compilation + Incoming Matching
# ========================================================================

# match_against_patterns: linear scan of compiled patterns for a category
# Returns cluster_key on match, undef otherwise
sub match_against_patterns {
    my ($category, $message) = @_;
    return undef unless exists $canonical_patterns{$category};
    my $patterns = $canonical_patterns{$category};
    for my $i (0 .. $#$patterns) {
        if ($message =~ $patterns->[$i]{pattern}) {
            my $entry = $patterns->[$i];
            $entry->{match_count}++;
            # Hot-sort: bubble this entry up if it now has more matches than its predecessor
            if ($i > 0 && $entry->{match_count} > $patterns->[$i-1]{match_count}) {
                # Swap with predecessor
                ($patterns->[$i], $patterns->[$i-1]) = ($patterns->[$i-1], $patterns->[$i]);
            }
            return $entry;
        }
    }
    return undef;
}

# Phase 3 validation: discover patterns from sample pairs, then test matching
# against ALL messages in each category.
# This is a validation-only step — not needed in the actual ltl implementation.
# Gated behind --verbose since it scans all keys and takes ~6s on the test file.

my $t_phase3_start = time();
my $t_phase3_done = $t_phase3_start;

if ($verbose) {
print "\n=== Phase 3: Pattern Compilation + Matching Validation ===\n";

# Step 1: Discover patterns by finding similar pairs and creating canonical forms
# Process each category: find pairs, build patterns
for my $cat (sort keys %log_messages) {
    my @indexed_keys = grep { exists $key_trigrams{$_} } keys %{$log_messages{$cat}};
    next unless @indexed_keys;

    my %consumed;  # keys already consumed into a pattern
    my $patterns_created = 0;
    my $max_patterns = 50;  # cap pattern discovery for prototype
    my $keys_searched = 0;
    my $max_search = 500;

    for my $key (@indexed_keys) {
        last if $keys_searched >= $max_search;
        last if $patterns_created >= $max_patterns;
        next if $consumed{$key};

        $keys_searched++;
        my @matches = find_candidates($cat, $key, $threshold);

        for my $match (@matches) {
            next if $consumed{$match->{key}};

            # Create pattern from this pair
            my $msg_a = substr($key_message{$key} // '', 0, $message_length_cap);
            my $msg_b = substr($key_message{$match->{key}} // '', 0, $message_length_cap);

            my $raw_mask = compute_mask($msg_a, $msg_b);
            my $mask = coalesce_mask($raw_mask);
            my $canonical = derive_canonical($msg_a, $mask);
            my $regex = derive_regex($msg_a, $mask);

            # Only keep patterns where regex matches both source messages
            my $match_a = ($msg_a =~ $regex);
            my $match_b = ($msg_b =~ $regex);
            next unless $match_a && $match_b;

            $consumed{$key} = 1;
            $consumed{$match->{key}} = 1;

            push @{$canonical_patterns{$cat}}, {
                pattern     => $regex,
                cluster_key => $canonical,
                canonical   => $canonical,
                match_count => 2,  # the two source messages
            };
            $patterns_created++;
            last;  # one pattern per source key
        }
    }

    printf "\n  %s: discovered %d patterns (searched %d keys)\n", $cat, $patterns_created, $keys_searched;
}

# Step 2: Test all messages against discovered patterns
print "\n--- Pattern Matching Results ---\n";

my $total_matched = 0;
my $total_unmatched = 0;

for my $cat (sort keys %log_messages) {
    my $cat_total = scalar keys %{$log_messages{$cat}};
    my $cat_matched = 0;
    my $cat_unmatched = 0;
    my $t_cat_start = time();

    for my $log_key (keys %{$log_messages{$cat}}) {
        my $message = $key_message{$log_key};
        next unless defined $message;
        my $hit = match_against_patterns($cat, $message);
        if ($hit) {
            $cat_matched++;
        } else {
            $cat_unmatched++;
        }
    }

    my $t_cat_elapsed = time() - $t_cat_start;
    my $pct = $cat_total > 0 ? ($cat_matched * 100.0 / $cat_total) : 0;
    my $pattern_count = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;

    printf "\n  %s: %d patterns, %d/%d matched (%.1f%%), %d unmatched, %.2f s\n",
        $cat, $pattern_count, $cat_matched, $cat_total, $pct, $cat_unmatched, $t_cat_elapsed;

    $total_matched += $cat_matched;
    $total_unmatched += $cat_unmatched;

    # Show top patterns by match count
    if (exists $canonical_patterns{$cat}) {
        my @sorted = sort { $b->{match_count} <=> $a->{match_count} } @{$canonical_patterns{$cat}};
        my $show = min(5, scalar @sorted);
        for my $i (0 .. $show - 1) {
            printf "    Pattern %d: %d matches — %s\n",
                $i + 1, $sorted[$i]{match_count}, $sorted[$i]{canonical};
        }
    }
}

$t_phase3_done = time();
my $grand_total = $total_matched + $total_unmatched;
printf "\n  Total: %d/%d matched (%.1f%%), %d unmatched\n",
    $total_matched, $grand_total, ($grand_total > 0 ? $total_matched * 100.0 / $grand_total : 0), $total_unmatched;
printf "  Phase 3 time: %.2f s\n", $t_phase3_done - $t_phase3_start;

# Reset patterns and structures from Phase 3 validation
%canonical_patterns = ();
%ngram_index = ();
%key_trigrams = ();

} else {
    print "\n(Phase 3 validation skipped — use --verbose to enable)\n";
}

# ========================================================================
# Phase 4: Full Consolidation Loop
# ========================================================================

my $t_phase4_start = time();
print "\n=== Phase 4: Full Consolidation Loop ===\n";

# Consolidated clusters: {category}{cluster_key} => { canonical, pattern, mask, occurrences, match_count }
my %clusters;

# merge_stats: sum occurrences from source into target
sub merge_stats {
    my ($target, $source) = @_;
    $target->{occurrences} += $source->{occurrences};
}

# try_merge_into_existing: before creating a new pattern, check if a similar one exists
# If found, generalize the existing pattern to also cover the new canonical form
# Returns: merged regex ref if merged, undef if no suitable merge target
sub try_merge_into_existing {
    my ($cat, $new_canonical, $new_regex, $new_mask, $new_cluster) = @_;
    return undef unless exists $canonical_patterns{$cat};

    my $new_trigrams = get_trigrams($new_canonical);

    for my $entry (@{$canonical_patterns{$cat}}) {
        my $existing = $clusters{$cat}{$entry->{canonical}};
        next unless $existing;

        # Compare canonical forms using Dice similarity
        my $existing_trigrams = get_trigrams($entry->{canonical});
        my $score = dice_coefficient($new_trigrams, $existing_trigrams);

        if ($score >= $threshold) {
            # Align the two canonical forms to create a more general pattern
            my $raw_mask = compute_mask($entry->{canonical}, $new_canonical);
            my $mask = coalesce_mask($raw_mask);
            my $merged_canonical = derive_canonical($entry->{canonical}, $mask);
            my $merged_regex = derive_regex($entry->{canonical}, $mask);

            # Verify the merged regex matches both canonicals
            next unless ($entry->{canonical} =~ $merged_regex) && ($new_canonical =~ $merged_regex);

            # Merge: update existing cluster and pattern
            merge_stats($existing, $new_cluster);
            $existing->{match_count} += $new_cluster->{match_count};

            # Update canonical and pattern to the more general form
            my $old_canonical = $entry->{canonical};
            $existing->{canonical} = $merged_canonical;
            $existing->{pattern} = $merged_regex;
            $existing->{mask} = $mask;
            $entry->{canonical} = $merged_canonical;
            $entry->{cluster_key} = $merged_canonical;
            $entry->{pattern} = $merged_regex;
            $entry->{match_count} = $existing->{match_count};

            # Move cluster entry to new canonical key
            if ($old_canonical ne $merged_canonical) {
                $clusters{$cat}{$merged_canonical} = $existing;
                delete $clusters{$cat}{$old_canonical};
            }

            return $merged_regex;
        }
    }
    return undef;
}

# extract_bucket_key: extract partitioning key from a log_key for re-scan bucketing.
# Extracts [LEVEL] and [class] (skipping [thread] which varies).
# Example: "[ERROR] [TWEventProcessor-5] [c.t.p.Reflection] msg" => "[ERROR][c.t.p.Reflection]"
sub extract_bucket_key {
    my ($log_key) = @_;
    if ($log_key =~ /^(\[[^\]]+\]) \[[^\]]+\] (\[[^\]]+\])/) {
        return "$1$2";
    }
    # Fallback: first 20 chars
    return substr($log_key, 0, 20);
}

# partition_keys: partition an array of keys into buckets by bucket_key.
# Returns hashref: { bucket_key => [@keys] }
sub partition_keys {
    my ($keys_ref) = @_;
    my %buckets;
    for my $key (@$keys_ref) {
        my $bk = extract_bucket_key($key_message{$key} // $key);
        push @{$buckets{$bk}}, $key;
    }
    return \%buckets;
}

# extract_pattern_bucket: extract bucket key from a pattern's canonical form.
# The canonical starts with the same [LEVEL] [thread*] [class] prefix.
sub extract_pattern_bucket {
    my ($canonical) = @_;
    return extract_bucket_key($canonical);
}


# run_consolidation_pass: discover patterns for one category with partitioned interleaved re-scan.
# Uses key partitioning (PF-16) to reduce re-scan cost: each new pattern only scans
# its matching bucket instead of all unmatched keys.
# Keeps interleaved re-scan (after each pattern discovery) to preserve cascading reduction —
# critical for power-law data where pattern 1 absorbs 99%+ of keys.
# Returns: ($patterns_discovered, $messages_absorbed, $ceiling_skipped, $cap_hit)

sub run_consolidation_pass {
    my ($cat, $unmatched_ref, $pass_num) = @_;
    my @unmatched_keys = @$unmatched_ref;
    my $initial_count = scalar @unmatched_keys;

    return (0, 0, 0, 0) if $initial_count < 2;

    # Separate keys by occurrence ceiling
    my @discovery_candidates;  # below ceiling — eligible for pattern discovery
    my @ceiling_keys;          # at/above ceiling — already well-counted, skip discovery
    for my $key (@unmatched_keys) {
        my $occ = $log_messages{$cat}{$key}{occurrences} // 1;
        if ($occ >= $occurrence_ceiling) {
            push @ceiling_keys, $key;
        } else {
            push @discovery_candidates, $key;
        }
    }
    my $ceiling_skipped = scalar @ceiling_keys;

    return (0, 0, $ceiling_skipped, 0) if scalar @discovery_candidates < 2;

    # Build n-gram index for discovery candidates only
    my $index_limit = min($trigger, scalar @discovery_candidates);
    my @index_batch = @discovery_candidates[0 .. $index_limit - 1];

    # Clear and rebuild category index
    delete $ngram_index{$cat};
    build_ngram_index($cat, \@index_batch);

    my %consumed;  # keys consumed into patterns this pass
    my $patterns_discovered = 0;
    my $merges_into_existing = 0;
    my $messages_absorbed = 0;
    my $keys_searched = 0;
    my $max_search = min(500, scalar @index_batch);
    my $cap_hit = 0;

    # Current pattern count for this category
    my $current_pattern_count = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;

    # Build partitioned buckets for fast re-scan
    # Key optimization: instead of scanning ALL unmatched keys per pattern,
    # partition by [LEVEL][class] and only scan the matching bucket.
    my %buckets;  # bucket_key => { keys => [@keys] }
    for my $key (@unmatched_keys) {
        my $bk = extract_bucket_key($key_message{$key} // $key);
        push @{$buckets{$bk}}, $key;
    }

    for my $key (@index_batch) {
        last if $keys_searched >= $max_search;
        next if $consumed{$key};

        $keys_searched++;
        my @matches = find_candidates($cat, $key, $threshold);

        for my $match (@matches) {
            next if $consumed{$match->{key}};

            my $msg_a = substr($key_message{$key} // '', 0, $message_length_cap);
            my $msg_b = substr($key_message{$match->{key}} // '', 0, $message_length_cap);

            my $raw_mask = compute_mask($msg_a, $msg_b);
            my $mask = coalesce_mask($raw_mask);
            my $canonical = derive_canonical($msg_a, $mask);
            my $regex = derive_regex($msg_a, $mask);

            # Only keep if regex matches both sources
            next unless ($msg_a =~ $regex) && ($msg_b =~ $regex);

            $consumed{$key} = 1;
            $consumed{$match->{key}} = 1;

            # Create the new cluster (accumulate stats before deciding where it goes)
            my $new_cluster = {
                canonical   => $canonical,
                pattern     => $regex,
                mask        => $mask,
                occurrences => 0,
                match_count => 0,
            };

            # Merge the two source keys into new cluster
            for my $src_key ($key, $match->{key}) {
                if (exists $log_messages{$cat}{$src_key}) {
                    merge_stats($new_cluster, $log_messages{$cat}{$src_key});
                    $new_cluster->{match_count}++;
                    $messages_absorbed++;
                }
            }

            # Merge-first: try to merge into an existing similar pattern
            my $scan_regex = $regex;
            my $scan_cluster = $new_cluster;
            my $scan_entry;
            my $merged_regex = try_merge_into_existing($cat, $canonical, $regex, $mask, $new_cluster);
            if ($merged_regex) {
                $merges_into_existing++;
                $patterns_discovered++;
                $scan_regex = $merged_regex;

                # Find the entry that was merged into
                for my $entry (@{$canonical_patterns{$cat}}) {
                    if ($entry->{pattern} eq $merged_regex) {
                        $scan_entry = $entry;
                        $scan_cluster = $clusters{$cat}{$entry->{canonical}};
                        last;
                    }
                }
            } else {
                # Hard cap check: can we add a new pattern?
                if ($current_pattern_count >= $max_patterns) {
                    $cap_hit = 1;
                    printf "    [WARN] Pattern cap (%d) reached — cannot add new pattern\n", $max_patterns if $verbose;
                    $clusters{$cat}{$canonical} = $new_cluster;
                    $patterns_discovered++;
                    last;
                }

                # Add as new pattern
                $clusters{$cat}{$canonical} = $new_cluster;
                $scan_entry = {
                    pattern     => $regex,
                    cluster_key => $canonical,
                    canonical   => $canonical,
                    match_count => $new_cluster->{match_count},
                };
                push @{$canonical_patterns{$cat}}, $scan_entry;
                $current_pattern_count++;
                $patterns_discovered++;
            }

            # Interleaved re-scan with partitioning:
            # Only scan the bucket matching this pattern's [LEVEL][class]
            my $pattern_bk = extract_pattern_bucket($scan_entry ? $scan_entry->{canonical} : $canonical);
            my $bucket_keys = $buckets{$pattern_bk};
            if ($bucket_keys) {
                my @surviving;  # keys that survive this scan (not consumed)
                for my $ukey (@$bucket_keys) {
                    if ($consumed{$ukey}) { next; }
                    my $umsg = $key_message{$ukey};
                    unless (defined $umsg) { push @surviving, $ukey; next; }
                    if ($umsg =~ $scan_regex) {
                        $consumed{$ukey} = 1;
                        if (exists $log_messages{$cat}{$ukey}) {
                            merge_stats($scan_cluster, $log_messages{$cat}{$ukey});
                            $scan_cluster->{match_count}++;
                            $scan_entry->{match_count} = $scan_cluster->{match_count} if $scan_entry;
                            $messages_absorbed++;
                        }
                    } else {
                        push @surviving, $ukey;
                    }
                }
                # Prune bucket: replace with only surviving keys
                $buckets{$pattern_bk} = \@surviving;
            }

            last;  # one pattern per source key, then move on
        }
    }

    # Remove consumed keys from unmatched list
    my @remaining = grep { !$consumed{$_} } @unmatched_keys;
    @$unmatched_ref = @remaining;

    printf "    (merge-first: %d merged into existing patterns)\n", $merges_into_existing if $verbose && $merges_into_existing > 0;
    printf "    (ceiling: %d keys skipped with occurrences >= %d)\n", $ceiling_skipped, $occurrence_ceiling if $verbose && $ceiling_skipped > 0;

    return ($patterns_discovered, $messages_absorbed, $ceiling_skipped, $cap_hit);
}

# Cross-cluster merge: compare canonical forms and merge overlapping patterns
sub merge_overlapping_patterns {
    my ($cat) = @_;
    return 0 unless exists $canonical_patterns{$cat};
    my @patterns = @{$canonical_patterns{$cat}};
    return 0 if @patterns < 2;

    my $merges = 0;
    my %removed;

    # Sort by match count descending — most general patterns first
    @patterns = sort { ($clusters{$cat}{$b->{canonical}}{match_count} // 0) <=> ($clusters{$cat}{$a->{canonical}}{match_count} // 0) } @patterns;

    for my $i (0 .. $#patterns) {
        next if $removed{$i};
        my $parent = $patterns[$i];
        my $parent_cluster = $clusters{$cat}{$parent->{canonical}};
        next unless $parent_cluster;

        for my $j ($i + 1 .. $#patterns) {
            next if $removed{$j};
            my $child = $patterns[$j];
            my $child_cluster = $clusters{$cat}{$child->{canonical}};
            next unless $child_cluster;

            # Check if the parent pattern matches the child's canonical form
            # (i.e., the child is a more specific version of the parent)
            if ($child->{canonical} =~ $parent->{pattern}) {
                # Merge child into parent
                merge_stats($parent_cluster, $child_cluster);
                $parent_cluster->{match_count} += $child_cluster->{match_count};
                delete $clusters{$cat}{$child->{canonical}};
                $removed{$j} = 1;
                $merges++;
            }
        }
    }

    # Rebuild pattern list without removed entries
    if ($merges > 0) {
        $canonical_patterns{$cat} = [ grep { exists $clusters{$cat}{$_->{canonical}} } @patterns ];
    }

    return $merges;
}

# Main consolidation loop
my $max_passes = 10;
my $total_ceiling_skipped = 0;
my $total_cap_hits = 0;
my %phase4_unmatched;  # {category} => [ @remaining_keys ] — preserved for Phase 5

for my $cat (sort keys %log_messages) {
    my @unmatched = keys %{$log_messages{$cat}};
    my $original_count = scalar @unmatched;
    next if $original_count < 10;  # skip tiny categories

    my $current_trigger = $trigger;
    my $pass_num = 0;

    printf "\n--- %s: %d unique keys, trigger=%d, ceiling=%d, max_patterns=%d ---\n",
        $cat, $original_count, $current_trigger, $occurrence_ceiling, $max_patterns;

    while ($pass_num < $max_passes && scalar @unmatched >= min($current_trigger, 10)) {
        $pass_num++;
        my $pre_count = scalar @unmatched;

        my ($discovered, $absorbed, $ceiling_skipped, $cap_hit) =
            run_consolidation_pass($cat, \@unmatched, $pass_num);

        $total_ceiling_skipped += $ceiling_skipped;
        $total_cap_hits += $cap_hit;

        my $yield = $pre_count > 0 ? ($absorbed * 100.0 / $pre_count) : 0;
        my $post_count = scalar @unmatched;
        my $current_pattern_count = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;

        printf "  Pass %d: discovered %d patterns (%d total), absorbed %d/%d messages (%.1f%% yield), %d remaining\n",
            $pass_num, $discovered, $current_pattern_count, $absorbed, $pre_count, $yield, $post_count;

        if ($cap_hit) {
            printf "    [WARN] Pattern cap reached (%d) — stopping discovery for %s\n", $max_patterns, $cat;
            last;
        }

        # Adaptive trigger
        if ($yield > 50) {
            $current_trigger = min($current_trigger * 2, 50000);
            printf "    Trigger raised to %d (high yield)\n", $current_trigger if $verbose;
        } elsif ($yield < 10) {
            $current_trigger = max(int($current_trigger / 2), 1000);
            printf "    Trigger lowered to %d (low yield)\n", $current_trigger if $verbose;
        }

        last if $discovered == 0;
        last if $absorbed == 0;
    }

    # Cross-cluster merge
    my $merges = merge_overlapping_patterns($cat);
    my $final_patterns = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;

    # Separate remaining keys into ceiling-excluded vs genuinely unmatched
    my $ceiling_excluded = 0;
    my $genuinely_unmatched = 0;
    for my $key (@unmatched) {
        my $occ = $log_messages{$cat}{$key}{occurrences} // 1;
        if ($occ >= $occurrence_ceiling) {
            $ceiling_excluded++;
        } else {
            $genuinely_unmatched++;
        }
    }

    printf "  Cross-cluster merges: %d, final patterns: %d\n", $merges, $final_patterns;
    printf "  Remaining: %d ceiling-excluded (occurrences >= %d), %d genuinely unmatched\n",
        $ceiling_excluded, $occurrence_ceiling, $genuinely_unmatched;
    printf "  Reduction: %d → %d unique entries (%.1f%% reduction)\n",
        $original_count, scalar(@unmatched) + $final_patterns,
        (1 - (scalar(@unmatched) + $final_patterns) / $original_count) * 100;

    # Show top patterns
    if (exists $canonical_patterns{$cat}) {
        my @sorted = sort { ($clusters{$cat}{$b->{canonical}}{match_count} // 0) <=> ($clusters{$cat}{$a->{canonical}}{match_count} // 0) } @{$canonical_patterns{$cat}};
        my $show = min(5, scalar @sorted);
        for my $i (0 .. $show - 1) {
            my $c = $clusters{$cat}{$sorted[$i]{canonical}};
            printf "    Top %d: %d matches, %d occurrences — %s\n",
                $i + 1, $c->{match_count}, $c->{occurrences},
                substr($sorted[$i]{canonical}, 0, 120);
        }
    }

    # Preserve unmatched list for Phase 5
    $phase4_unmatched{$cat} = \@unmatched;
}

my $t_phase4_done = time();
printf "\nPhase 4 time: %.2f s\n", $t_phase4_done - $t_phase4_start;

# ========================================================================
# Final Pass: High-similarity consolidation of ceiling-excluded keys
# ========================================================================

if ($final_pass) {
    my $t_final_start = time();
    print "\n=== Final Pass: Consolidating ceiling-excluded keys (threshold=${final_threshold}%, ceiling=$final_ceiling) ===\n";

    for my $cat (sort keys %phase4_unmatched) {
        my @remaining = @{$phase4_unmatched{$cat}};
        next unless @remaining > 1;

        # Select keys that were ceiling-excluded (occurrences >= normal ceiling but < final ceiling)
        my @candidates;
        my @keep_as_is;
        for my $key (@remaining) {
            my $occ = $log_messages{$cat}{$key}{occurrences} // 1;
            if ($occ >= $occurrence_ceiling && $occ < $final_ceiling) {
                push @candidates, $key;
            } else {
                push @keep_as_is, $key;
            }
        }

        next unless @candidates >= 2;

        printf "\n  %s: %d ceiling-excluded candidates for final pass\n", $cat, scalar @candidates;

        # Build n-gram index for candidates
        delete $ngram_index{$cat};
        # Clear cached trigrams for these keys so they get re-indexed
        delete $key_trigrams{$_} for @candidates;
        build_ngram_index($cat, \@candidates);

        my %consumed;
        my $patterns_discovered = 0;
        my $messages_absorbed = 0;
        my $merges_into_existing = 0;
        my $keys_searched = 0;
        my $max_search = min(500, scalar @candidates);

        for my $key (@candidates) {
            last if $keys_searched >= $max_search;
            next if $consumed{$key};

            $keys_searched++;
            my @matches = find_candidates($cat, $key, $final_threshold);

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

                my $new_cluster = {
                    canonical   => $canonical,
                    pattern     => $regex,
                    mask        => $mask,
                    occurrences => 0,
                    match_count => 0,
                };

                # Merge the two source keys
                for my $src_key ($key, $match->{key}) {
                    if (exists $log_messages{$cat}{$src_key}) {
                        merge_stats($new_cluster, $log_messages{$cat}{$src_key});
                        $new_cluster->{match_count}++;
                        $messages_absorbed++;
                    }
                }

                # Interleaved re-scan against all remaining candidates
                for my $ukey (@candidates) {
                    next if $consumed{$ukey};
                    my $umsg = $key_message{$ukey};
                    next unless defined $umsg;
                    if ($umsg =~ $regex) {
                        $consumed{$ukey} = 1;
                        if (exists $log_messages{$cat}{$ukey}) {
                            merge_stats($new_cluster, $log_messages{$cat}{$ukey});
                            $new_cluster->{match_count}++;
                            $messages_absorbed++;
                        }
                    }
                }

                # Try merge-first into existing patterns
                my $merged_regex = try_merge_into_existing($cat, $canonical, $regex, $mask, $new_cluster);
                if ($merged_regex) {
                    $merges_into_existing++;
                    $patterns_discovered++;

                    # Re-scan remaining candidates against generalized pattern
                    for my $ukey (@candidates) {
                        next if $consumed{$ukey};
                        my $umsg = $key_message{$ukey};
                        next unless defined $umsg;
                        if ($umsg =~ $merged_regex) {
                            $consumed{$ukey} = 1;
                            for my $entry (@{$canonical_patterns{$cat}}) {
                                if ($entry->{pattern} eq $merged_regex) {
                                    my $cluster = $clusters{$cat}{$entry->{canonical}};
                                    if ($cluster && exists $log_messages{$cat}{$ukey}) {
                                        merge_stats($cluster, $log_messages{$cat}{$ukey});
                                        $cluster->{match_count}++;
                                        $entry->{match_count} = $cluster->{match_count};
                                        $messages_absorbed++;
                                    }
                                    last;
                                }
                            }
                        }
                    }
                    last;
                }

                # Add as new pattern
                $clusters{$cat}{$canonical} = $new_cluster;
                push @{$canonical_patterns{$cat}}, {
                    pattern     => $regex,
                    cluster_key => $canonical,
                    canonical   => $canonical,
                    match_count => $new_cluster->{match_count},
                };
                $patterns_discovered++;

                last;
            }
        }

        # Update unmatched list
        my @new_remaining = grep { !$consumed{$_} } @candidates;
        push @new_remaining, @keep_as_is;
        $phase4_unmatched{$cat} = \@new_remaining;

        my $final_patterns = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;
        printf "    Discovered %d patterns (%d merged into existing), absorbed %d messages\n",
            $patterns_discovered, $merges_into_existing, $messages_absorbed;
        printf "    Remaining: %d (was %d)\n", scalar @new_remaining, scalar @remaining;
        printf "    Total patterns for %s: %d\n", $cat, $final_patterns if $verbose;
    }

    my $t_final_done = time();
    printf "\nFinal pass time: %.2f s\n", $t_final_done - $t_final_start;
}

# ========================================================================
# Phase 5: Output + Verbose Stats
# ========================================================================

my $t_phase5_start = time();
print "\n=== Phase 5: Top $top_n Messages ===\n\n";

# Build a unified list of all entries: consolidated clusters + unconsolidated individual keys
# Each entry: { log_key, occurrences, is_consolidated, canonical }
my @all_entries;

# Add consolidated clusters
for my $cat (keys %clusters) {
    for my $canonical (keys %{$clusters{$cat}}) {
        my $c = $clusters{$cat}{$canonical};
        push @all_entries, {
            log_key         => $canonical,
            occurrences     => $c->{occurrences},
            is_consolidated => 1,
            category        => $cat,
            match_count     => $c->{match_count},
        };
    }
}

# Add unconsolidated keys from Phase 4's unmatched lists (no re-scanning needed)
for my $cat (sort keys %log_messages) {
    my $unmatched_ref = $phase4_unmatched{$cat};
    next unless $unmatched_ref;
    for my $log_key (@$unmatched_ref) {
        push @all_entries, {
            log_key         => $log_key,
            occurrences     => $log_messages{$cat}{$log_key}{occurrences},
            is_consolidated => 0,
            category        => $cat,
            match_count     => 0,
        };
    }

    # Also add keys from categories too small for consolidation (< 10 unique keys)
}
# Add keys from categories that were skipped by Phase 4 (< 10 unique keys)
for my $cat (sort keys %log_messages) {
    next if exists $phase4_unmatched{$cat};
    for my $log_key (keys %{$log_messages{$cat}}) {
        push @all_entries, {
            log_key         => $log_key,
            occurrences     => $log_messages{$cat}{$log_key}{occurrences},
            is_consolidated => 0,
            category        => $cat,
            match_count     => 0,
        };
    }
}

# Sort by occurrences descending
@all_entries = sort { $b->{occurrences} <=> $a->{occurrences} } @all_entries;

# Print top N
my $show_count = min($top_n, scalar @all_entries);
printf "  %1s %12s  %s\n", '', 'Occurrences', 'Message';
printf "  %1s %12s  %s\n", '', '-----------', '-------';

for my $i (0 .. $show_count - 1) {
    my $e = $all_entries[$i];
    my $prefix = $e->{is_consolidated} ? '~' : ' ';
    my $display_msg = substr($e->{log_key}, 0, 200);
    printf "  %1s %12s  %s\n", $prefix, commify($e->{occurrences}), $display_msg;
}

# commify: add thousands separators
sub commify {
    my ($n) = @_;
    my $text = reverse $n;
    $text =~ s/(\d{3})(?=\d)/$1,/g;
    return scalar reverse $text;
}

# --- Verbose Stats ---
if ($verbose) {
    print "\n=== Verbose Consolidation Stats ===\n";

    for my $cat (sort keys %log_messages) {
        my $original = scalar keys %{$log_messages{$cat}};
        my $pattern_count = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;
        my $cluster_count = exists $clusters{$cat} ? scalar keys %{$clusters{$cat}} : 0;

        # Count remaining unconsolidated
        my $unconsolidated = 0;
        my $ceiling_excluded = 0;
        for my $e (@all_entries) {
            next unless $e->{category} eq $cat && !$e->{is_consolidated};
            if ($e->{occurrences} >= $occurrence_ceiling) {
                $ceiling_excluded++;
            } else {
                $unconsolidated++;
            }
        }

        printf "\n  %s:\n", $cat;
        printf "    Original unique keys:   %d\n", $original;
        printf "    Consolidated clusters:  %d\n", $cluster_count;
        printf "    Active patterns:        %d\n", $pattern_count;
        printf "    Ceiling-excluded:       %d (occurrences >= %d)\n", $ceiling_excluded, $occurrence_ceiling;
        printf "    Genuinely unmatched:    %d\n", $unconsolidated;
        printf "    Final unique entries:   %d\n", $cluster_count + $ceiling_excluded + $unconsolidated;

        if ($original > 0) {
            my $reduction = (1 - ($cluster_count + $ceiling_excluded + $unconsolidated) / $original) * 100;
            printf "    Reduction:              %.1f%%\n", $reduction;
        }
    }
}

# --- Timing Breakdown ---
my $t_phase5_done = time();
printf "\n=== Timing ===\n";
printf "  Parse:          %.2f s\n", $t_parsed - $t_start;
printf "  Index (Ph1):    %.2f s\n", $t_index_done - $t_index_start;
printf "  Pairs (Ph1-2):  %.2f s\n", $t_search_done - $t_search_start;
printf "  Phase 3:        %.2f s\n", $t_phase3_done - $t_phase3_start;
printf "  Phase 4:        %.2f s\n", $t_phase4_done - $t_phase4_start;
printf "  Phase 5:        %.2f s\n", $t_phase5_done - $t_phase5_start;
printf "  Total:          %.2f s\n", $t_phase5_done - $t_start;

# --- Memory ---
my $total_patterns = 0;
$total_patterns += scalar @{$canonical_patterns{$_}} for keys %canonical_patterns;
my $total_clusters = 0;
$total_clusters += scalar keys %{$clusters{$_}} for keys %clusters;

printf "\n=== Memory ===\n";
printf "  Compiled patterns:  %d (cap: %d)\n", $total_patterns, $max_patterns;
printf "  Total clusters:     %d\n", $total_clusters;
printf "  Cached trigram sets: %d\n", scalar keys %key_trigrams;
printf "  Cap hits:           %d\n", $total_cap_hits;

eval {
    my $pid = $$;
    my $rss = `ps -o rss= -p $pid`;
    chomp $rss;
    if ($rss && $rss > 0) {
        printf "  Process RSS:        %.1f MB\n", $rss / 1024;
    }
};
