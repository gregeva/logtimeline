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
# Checkpoint-based batched processing architecture:
#   Parse line-by-line → S1 inline match → accumulate unmatched →
#   checkpoint fires at trigger → S2 ceiling → S3 checkpoint match →
#   S4 pairwise discovery → interleaved re-scan → delete absorbed keys
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
my $show_memory = 0;

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
    'mem'                 => \$show_memory,
) or die "Usage: $0 --file <logfile> [--threshold N] [--trigger N] [--top N] [--ceiling N] [--max-patterns N] [--final-pass] [--final-threshold N] [--final-ceiling N] [--mem] [--verbose]\n";

die "Error: --file is required\n" unless defined $file;
die "Error: file '$file' not found\n" unless -f $file;

# --- Data Structures ---
my %log_messages;        # {category}{log_key} => { occurrences => N } — currently unmatched + cluster entries
my %ngram_index;         # {category}{trigram}{log_key} => 1  (built and freed per checkpoint)
my %posting_size;        # {category}{trigram} => count  (posting list size cache, per checkpoint)
my %key_trigrams;        # {log_key} => { trigram => 1, ... }  (freed per checkpoint)
my %key_trigrams_norm;   # {log_key} => { trigram => 1, ... }  (UUID-normalized, for Dice scoring)
my %key_message;         # {log_key} => $message  (deleted when key absorbed)
my %canonical_patterns;  # {category} => [ { pattern => qr//, cluster_key => $key, canonical => $str, match_count => N }, ... ]
my %clusters;            # {category}{canonical} => { canonical, pattern, mask, occurrences, match_count }

# --- Memory Tracking ---
my $rss_high_water = 0;          # MB — progressive high-water mark
my %structure_hwm;               # {name} => peak bytes (Devel::Size)
my @memory_snapshots;            # [ { label, rss, structures => { name => bytes } }, ... ]
my $deleted_log_messages_bytes = 0;  # cumulative bytes freed from %log_messages (would still exist in ltl)
my $deleted_key_message_bytes = 0;   # cumulative bytes freed from %key_message

# --- UUID normalization for Dice scoring ---
my $uuid_re = qr/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i;

# --- Find-candidates tuning ---
my $discriminative_topk = 50;       # use top-50 most discriminative trigrams
my $prefilter_ratio    = 0.30;      # require 30% of topk hits as loose pre-filter

# --- Checkpoint Tracking ---
my %unmatched_keys;      # {category} => { $log_key => 1 } — keys awaiting consolidation
my %checkpoint_count;    # {category} => N
my $total_keys_seen = 0; # total unique keys ever encountered
my %cat_keys_seen;       # {category} => N — unique keys seen per category
my %cat_stats;           # {category} => { s1_inline, s2_ceiling, s3_checkpoint, s4_pairwise, fc_calls,
                         #                  patterns_discovered, patterns_final, checkpoints }

# --- ThingWorx ApplicationLog Regex (from ltl line 1827) ---
my $twx_regex = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;

# ========================================================================
# Parse Log File with Checkpoint-Based Consolidation
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

        # Is this a brand-new unique key?
        my $is_new_key = !exists $log_messages{$category}{$log_key};

        if ($is_new_key) {
            $total_keys_seen++;
            $cat_keys_seen{$category}++;

            # S1 inline match: try matching against existing patterns
            my $entry = match_against_patterns($category, substr($log_key, 0, $message_length_cap));
            if ($entry) {
                # Absorbed — merge into cluster, don't create %log_messages entry
                my $cluster = $clusters{$category}{$entry->{canonical}};
                if ($cluster) {
                    $cluster->{occurrences}++;
                }
                $cat_stats{$category}{s1_inline}++;
                next;  # don't add to %log_messages or unmatched
            }

            # No pattern match — add as unmatched
            $log_messages{$category}{$log_key} = { occurrences => 1 };
            $key_message{$log_key} = substr($log_key, 0, $message_length_cap);
            $unmatched_keys{$category}{$log_key} = 1;

            # Check if checkpoint should fire
            if (scalar(keys %{$unmatched_keys{$category}}) >= $trigger) {
                run_checkpoint($category);
            }
        } else {
            # Existing key — just increment
            $log_messages{$category}{$log_key}{occurrences}++;
        }
    } else {
        $unmatched_lines++;
    }
}
close($fh);

# MEASURE: after parsing loop completes, before final checkpoints
measure_memory("after parsing");

# Final checkpoint for all categories with remaining unmatched keys
for my $cat (sort keys %unmatched_keys) {
    run_checkpoint($cat) if scalar(keys %{$unmatched_keys{$cat}}) >= 2;
}

# MEASURE: after final checkpoints
measure_memory("after final checkpoints");

my $t_parsed = time();

my $total_categories = scalar keys %cat_keys_seen;
my $remaining_keys = 0;
for my $cat (sort keys %log_messages) {
    $remaining_keys += scalar keys %{$log_messages{$cat}};
}

print "\n=== Parsing + Checkpoints Complete ===\n";
printf "Total lines:      %d\n", $total_lines;
printf "Matched lines:    %d\n", $matched_lines;
printf "Unmatched lines:  %d\n", $unmatched_lines;
printf "Categories:       %d\n", $total_categories;
printf "Total unique keys seen: %d\n", $total_keys_seen;
printf "Remaining in log_messages: %d\n", $remaining_keys;
printf "Processing time:  %.2f s\n\n", $t_parsed - $t_start;

print "=== Category Breakdown ===\n";
for my $cat (sort keys %cat_keys_seen) {
    my $seen = $cat_keys_seen{$cat};
    my $remaining = scalar keys %{$log_messages{$cat} // {}};
    my $checkpoints = $cat_stats{$cat}{checkpoints} // 0;
    printf "  %-10s %6d seen, %6d remaining, %d checkpoints\n", $cat, $seen, $remaining, $checkpoints;
}
print "\n";

# ========================================================================
# Memory Instrumentation
# ========================================================================

sub get_rss {
    my $rss = `ps -o rss= -p $$`;
    chomp $rss;
    return ($rss && $rss > 0) ? $rss / 1024 : 0;  # returns MB
}

sub measure_memory {
    my ($label) = @_;

    # Always update RSS high-water mark
    my $rss = get_rss();
    $rss_high_water = $rss if $rss > $rss_high_water;

    return unless $show_memory;

    require Devel::Size;

    my %sizes = (
        log_messages       => Devel::Size::total_size(\%log_messages),
        key_message        => Devel::Size::total_size(\%key_message),
        clusters           => Devel::Size::total_size(\%clusters),
        canonical_patterns => Devel::Size::total_size(\%canonical_patterns),
        unmatched_keys     => Devel::Size::total_size(\%unmatched_keys),
        ngram_index        => Devel::Size::total_size(\%ngram_index),
        key_trigrams       => Devel::Size::total_size(\%key_trigrams),
        key_trigrams_norm  => Devel::Size::total_size(\%key_trigrams_norm),
        posting_size       => Devel::Size::total_size(\%posting_size),
    );

    # Update per-structure high-water marks
    for my $name (keys %sizes) {
        my $hwm = $structure_hwm{$name} // 0;
        $structure_hwm{$name} = $sizes{$name} if $sizes{$name} > $hwm;
    }

    # ltl-equivalent: log_messages + key_message would retain deleted keys
    my $ltl_log_messages = $sizes{log_messages} + $deleted_log_messages_bytes;
    my $ltl_key_message  = $sizes{key_message}  + $deleted_key_message_bytes;

    # Record snapshot
    push @memory_snapshots, {
        label      => $label,
        rss        => $rss,
        structures => \%sizes,
        ltl_equiv  => {
            log_messages => $ltl_log_messages,
            key_message  => $ltl_key_message,
            deleted_lm   => $deleted_log_messages_bytes,
            deleted_km   => $deleted_key_message_bytes,
        },
    };
}

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
        # Build UUID-normalized trigrams for Dice scoring
        if ($message =~ $uuid_re) {
            (my $normalized = $message) =~ s/$uuid_re/<UUID>/g;
            $key_trigrams_norm{$log_key} = get_trigrams($normalized);
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
    # Uses UUID-normalized trigrams when available, so UUIDs don't drag scores down.
    my $source_trig_dice = $key_trigrams_norm{$source_key} // $source_trigrams;
    my $source_size_dice = scalar keys %$source_trig_dice;
    my $min_dice_size = int($source_size_dice * $threshold_pct / (200 - $threshold_pct));
    my $max_dice_size = int($source_size_dice * (200 - $threshold_pct) / $threshold_pct) + 1;

    my @results;
    for my $cand_key (keys %candidate_hits) {
        next if $candidate_hits{$cand_key} < $loose_min;

        my $cand_trigrams = $key_trigrams{$cand_key};
        next unless defined $cand_trigrams;

        my $cand_size = scalar keys %$cand_trigrams;
        next if $cand_size < $min_cand_size || $cand_size > $max_cand_size;

        # Dice on normalized trigrams (UUID-stripped) when available
        my $cand_trig_dice = $key_trigrams_norm{$cand_key} // $cand_trigrams;
        my $cand_size_dice = scalar keys %$cand_trig_dice;
        next if $cand_size_dice < $min_dice_size || $cand_size_dice > $max_dice_size;

        my $score = dice_coefficient($source_trig_dice, $cand_trig_dice);
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
# Pattern Matching + Checkpoint Subroutines
# ========================================================================

# match_against_patterns: linear scan of compiled patterns for a category
# Returns pattern entry on match, undef otherwise
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

# ========================================================================
# Consolidation Subroutines
# ========================================================================

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
# Returns: ($patterns_discovered, $messages_absorbed, $ceiling_skipped, $cap_hit, $gate2_absorbed, $fc_calls, $gate2_survivors_count)

sub run_consolidation_pass {
    my ($cat, $unmatched_ref, $pass_num) = @_;
    my @unmatched_keys = @$unmatched_ref;
    my $initial_count = scalar @unmatched_keys;

    return (0, 0, 0, 0, 0, 0, 0) if $initial_count < 2;

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

    # Hoist %consumed before Gate 2 so both gates share it
    my %consumed;
    my $gate2_absorbed = 0;
    my $fc_calls = 0;
    my $messages_absorbed = 0;

    return (0, 0, $ceiling_skipped, 0, 0, 0, scalar @discovery_candidates) if scalar @discovery_candidates < 2;

    # Gate 2: match discovery candidates against existing compiled patterns
    # Keys that match existing patterns are absorbed without expensive pairwise work
    my @gate2_survivors;
    for my $key (@discovery_candidates) {
        my $entry = match_against_patterns($cat, $key_message{$key});
        if ($entry) {
            $consumed{$key} = 1;
            my $cluster = $clusters{$cat}{$entry->{canonical}};
            if ($cluster && exists $log_messages{$cat}{$key}) {
                merge_stats($cluster, $log_messages{$cat}{$key});
                $messages_absorbed++;
            }
            $gate2_absorbed++;
        } else {
            push @gate2_survivors, $key;
        }
    }

    if (scalar @gate2_survivors < 2) {
        # Remove consumed keys from unmatched list
        my @remaining = grep { !$consumed{$_} } @unmatched_keys;
        @$unmatched_ref = @remaining;
        return (0, $messages_absorbed, $ceiling_skipped, 0, $gate2_absorbed, $fc_calls, scalar @gate2_survivors);
    }

    # Build n-gram index for gate2 survivors only
    my $index_limit = min($trigger, scalar @gate2_survivors);
    my @index_batch = @gate2_survivors[0 .. $index_limit - 1];

    # Clear and rebuild category index
    delete $ngram_index{$cat};
    build_ngram_index($cat, \@index_batch);

    my $patterns_discovered = 0;
    my $merges_into_existing = 0;
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
        $fc_calls++;
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
    printf "    (gate2: %d absorbed by existing patterns)\n", $gate2_absorbed if $verbose && $gate2_absorbed > 0;

    return ($patterns_discovered, $messages_absorbed, $ceiling_skipped, $cap_hit, $gate2_absorbed, $fc_calls, scalar @gate2_survivors);
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

# run_checkpoint: fire a consolidation checkpoint for one category.
# Called during parsing when unmatched count hits trigger, and after EOF for remaining keys.
sub run_checkpoint {
    my ($cat) = @_;
    $cat_stats{$cat}{checkpoints}++;
    my $cp_num = $cat_stats{$cat}{checkpoints};

    my @unmatched = keys %{$unmatched_keys{$cat}};
    my $pre_count = scalar @unmatched;
    return if $pre_count < 2;

    my ($discovered, $absorbed, $ceiling_skipped, $cap_hit, $g2_absorbed, $fc_calls, $g2_survivors) =
        run_consolidation_pass($cat, \@unmatched, $cp_num);

    # MEASURE: after consolidation pass, BEFORE freeing memory — this is peak
    measure_memory("CP $cp_num [$cat] after consolidation");

    # S4 pairwise absorbed = total absorbed minus S3 checkpoint absorbed
    my $pairwise_absorbed = $absorbed - $g2_absorbed;
    my $discovery_candidates = $pre_count - $ceiling_skipped;
    my $post_count = scalar @unmatched;

    # Update per-category accumulators (S2-S4)
    $cat_stats{$cat}{s2_ceiling}          += $ceiling_skipped;
    $cat_stats{$cat}{s3_checkpoint}       += $g2_absorbed;
    $cat_stats{$cat}{s4_pairwise}         += $pairwise_absorbed;
    $cat_stats{$cat}{fc_calls}            += $fc_calls;
    $cat_stats{$cat}{patterns_discovered} += $discovered;
    $cat_stats{$cat}{patterns_final} = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;

    # Per-checkpoint output: full pipeline visibility (S2 → S3 → S4)
    printf "  CP %d [%s]: %d keys → S2: %d ceiling, %d candidates → S3: %d absorbed, %d survivors → S4: fc=%d, %d new patterns (%d total), %d absorbed → %d remaining\n",
        $cp_num, $cat,
        $pre_count,
        $ceiling_skipped, $discovery_candidates,
        $g2_absorbed, $g2_survivors,
        $fc_calls, $discovered, $cat_stats{$cat}{patterns_final},
        $pairwise_absorbed,
        $post_count;

    # Rebuild %unmatched_keys from the modified @unmatched list
    # (run_consolidation_pass modifies it in-place via $unmatched_ref)
    %{$unmatched_keys{$cat}} = map { $_ => 1 } @unmatched;

    # Delete absorbed keys from %log_messages and %key_message to free memory
    # Track deleted bytes for ltl-equivalent projection
    if ($show_memory) {
        require Devel::Size;
        my $lm_before = Devel::Size::total_size(\%log_messages);
        my $km_before = Devel::Size::total_size(\%key_message);
        for my $key (keys %{$log_messages{$cat}}) {
            unless (exists $unmatched_keys{$cat}{$key}) {
                delete $log_messages{$cat}{$key};
                delete $key_message{$key};
            }
        }
        $deleted_log_messages_bytes += $lm_before - Devel::Size::total_size(\%log_messages);
        $deleted_key_message_bytes  += $km_before - Devel::Size::total_size(\%key_message);
    } else {
        for my $key (keys %{$log_messages{$cat}}) {
            unless (exists $unmatched_keys{$cat}{$key}) {
                delete $log_messages{$cat}{$key};
                delete $key_message{$key};
            }
        }
    }

    # Free trigram data — only needed during pairwise discovery
    delete $ngram_index{$cat};
    delete $posting_size{$cat};
    for my $key (keys %key_trigrams) {
        unless (exists $unmatched_keys{$cat}{$key}) {
            delete $key_trigrams{$key};
            delete $key_trigrams_norm{$key};
        }
    }

    # Cross-cluster merge periodically
    if ($discovered > 0) {
        merge_overlapping_patterns($cat);
        $cat_stats{$cat}{patterns_final} = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;
    }

    # MEASURE: after freeing — shows what cleanup achieved
    measure_memory("CP $cp_num [$cat] after cleanup");
}

# ========================================================================
# Final Pass: High-similarity consolidation of ceiling-excluded keys
# ========================================================================

if ($final_pass) {
    my $t_final_start = time();
    print "\n=== Final Pass: Consolidating ceiling-excluded keys (threshold=${final_threshold}%, ceiling=$final_ceiling) ===\n";

    for my $cat (sort keys %unmatched_keys) {
        my @remaining = keys %{$unmatched_keys{$cat}};
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

        # Update unmatched keys — remove consumed
        if ($show_memory) {
            require Devel::Size;
            my $lm_before = Devel::Size::total_size(\%log_messages);
            my $km_before = Devel::Size::total_size(\%key_message);
            for my $key (keys %consumed) {
                delete $unmatched_keys{$cat}{$key};
                delete $log_messages{$cat}{$key};
                delete $key_message{$key};
            }
            $deleted_log_messages_bytes += $lm_before - Devel::Size::total_size(\%log_messages);
            $deleted_key_message_bytes  += $km_before - Devel::Size::total_size(\%key_message);
        } else {
            for my $key (keys %consumed) {
                delete $unmatched_keys{$cat}{$key};
                delete $log_messages{$cat}{$key};
                delete $key_message{$key};
            }
        }

        my $final_patterns = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;
        printf "    Discovered %d patterns (%d merged into existing), absorbed %d messages\n",
            $patterns_discovered, $merges_into_existing, $messages_absorbed;
        printf "    Remaining: %d (was %d)\n", scalar(keys %{$unmatched_keys{$cat}}), scalar @remaining;
        printf "    Total patterns for %s: %d\n", $cat, $final_patterns if $verbose;
    }

    my $t_final_done = time();
    printf "\nFinal pass time: %.2f s\n", $t_final_done - $t_final_start;

    # MEASURE: after final pass
    measure_memory("after final pass");
}

# ========================================================================
# Per-Category Summary (S1-S5 Tracking)
# ========================================================================

my ($grand_keys, $grand_s1, $grand_s2, $grand_s2_cum, $grand_s3, $grand_s4, $grand_s5, $grand_fc) = (0) x 8;

for my $cat (sort keys %cat_stats) {
    my $s = $cat_stats{$cat};
    my $remaining = scalar(keys %{$unmatched_keys{$cat} // {}});
    my $patterns = $s->{patterns_final} // 0;
    my $keys_seen = $cat_keys_seen{$cat} // 0;

    # Split remaining into ceiling-filtered vs genuinely unmatched
    my $ceiling_remaining = 0;
    my $genuinely_unmatched = 0;
    for my $key (keys %{$unmatched_keys{$cat} // {}}) {
        my $occ = $log_messages{$cat}{$key}{occurrences} // 1;
        if ($occ >= $occurrence_ceiling) {
            $ceiling_remaining++;
        } else {
            $genuinely_unmatched++;
        }
    }

    printf "\n--- %s: %d unique keys seen, %d checkpoints ---\n",
        $cat, $keys_seen, $s->{checkpoints} // 0;
    printf "  S1 Inline match:       %d\n", $s->{s1_inline} // 0;
    printf "  S2 Ceiling filter:     %d  (occurrences >= %d, proven distinct)\n", $ceiling_remaining, $occurrence_ceiling;
    printf "  S3 Checkpoint match:   %d\n", $s->{s3_checkpoint} // 0;
    printf "  S4 Pairwise discovery: %d  (discovery + interleaved re-scan)\n", $s->{s4_pairwise} // 0;
    printf "  S5 Unmatched:          %d\n", $genuinely_unmatched;
    printf "  ---\n";
    printf "  S2 cumulative filtered:  %d  (across all checkpoints)\n", $s->{s2_ceiling} // 0;
    printf "  S4 find_candidates:      %d  calls\n", $s->{fc_calls} // 0;
    printf "  Patterns discovered:     %d  (before merging), final: %d\n",
        $s->{patterns_discovered} // 0, $patterns;

    # Sanity check: all 5 stages must sum to keys_seen
    my $accounted = ($s->{s1_inline} // 0) + $ceiling_remaining + ($s->{s3_checkpoint} // 0) + ($s->{s4_pairwise} // 0) + $genuinely_unmatched;
    if ($accounted != $keys_seen) {
        printf "  [WARN] Tracking mismatch: %d accounted vs %d seen (delta %d)\n",
            $accounted, $keys_seen, $keys_seen - $accounted;
    }

    printf "  Reduction: %d → %d (%.1f%%)\n",
        $keys_seen, $remaining + $patterns,
        (1 - ($remaining + $patterns) / ($keys_seen || 1)) * 100;

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

    $grand_keys += $keys_seen;
    $grand_s1 += ($s->{s1_inline} // 0);
    $grand_s2 += $ceiling_remaining;
    $grand_s2_cum += ($s->{s2_ceiling} // 0);
    $grand_s3 += ($s->{s3_checkpoint} // 0);
    $grand_s4 += ($s->{s4_pairwise} // 0);
    $grand_s5 += $genuinely_unmatched;
    $grand_fc += ($s->{fc_calls} // 0);
}

printf "\n=== Grand Totals ===\n";
printf "  Unique keys seen:        %d\n", $grand_keys;
printf "  S1 Inline match:         %d\n", $grand_s1;
printf "  S2 Ceiling filter:       %d\n", $grand_s2;
printf "  S3 Checkpoint match:     %d\n", $grand_s3;
printf "  S4 Pairwise discovery:   %d\n", $grand_s4;
printf "  S5 Unmatched:            %d\n", $grand_s5;
printf "  S2 cumulative filtered:  %d  (across all checkpoints)\n", $grand_s2_cum;
printf "  S4 find_candidates:      %d  calls\n", $grand_fc;

# ========================================================================
# Top N Output
# ========================================================================

print "\n=== Top $top_n Messages ===\n\n";

# Build a unified list of all entries: consolidated clusters + remaining unmatched
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

# Add remaining unmatched keys from %log_messages
for my $cat (sort keys %log_messages) {
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

# --- Timing ---
my $t_done = time();
printf "\n=== Timing ===\n";
printf "  Total:          %.2f s\n", $t_done - $t_start;

# --- Memory ---
my $total_patterns = 0;
$total_patterns += scalar @{$canonical_patterns{$_}} for keys %canonical_patterns;
my $total_clusters = 0;
$total_clusters += scalar keys %{$clusters{$_}} for keys %clusters;

# MEASURE: end of processing
measure_memory("end of processing");

printf "\n=== Memory ===\n";
printf "  RSS high-water mark: %.1f MB\n", $rss_high_water;
printf "  RSS at end:          %.1f MB\n", get_rss();

if ($show_memory && @memory_snapshots) {
    # Per-snapshot timeline
    printf "\n  --- Memory Timeline ---\n";
    my $peak_ltl_equiv = 0;
    for my $snap (@memory_snapshots) {
        printf "  [%6.1f MB] %s\n", $snap->{rss}, $snap->{label};
        my %s = %{$snap->{structures}};
        my $total = 0;
        $total += $_ for values %s;
        # Show structures > 1KB, sorted by size descending
        for my $name (sort { $s{$b} <=> $s{$a} } grep { $s{$_} >= 1024 } keys %s) {
            printf "    %-20s %7.1f MB  (%4.1f%%)\n",
                $name, $s{$name} / 1024 / 1024,
                $total > 0 ? ($s{$name} / $total) * 100 : 0;
        }
        # ltl-equivalent projection
        if ($snap->{ltl_equiv} && $snap->{ltl_equiv}{deleted_lm} > 0) {
            printf "    --- ltl-equivalent (retained keys) ---\n";
            printf "    log_messages         %7.1f MB  (actual %.1f + deleted %.1f)\n",
                $snap->{ltl_equiv}{log_messages} / 1024 / 1024,
                $s{log_messages} / 1024 / 1024,
                $snap->{ltl_equiv}{deleted_lm} / 1024 / 1024;
            printf "    key_message          %7.1f MB  (actual %.1f + deleted %.1f)\n",
                $snap->{ltl_equiv}{key_message} / 1024 / 1024,
                $s{key_message} / 1024 / 1024,
                $snap->{ltl_equiv}{deleted_km} / 1024 / 1024;
            my $ltl_total = $total + $snap->{ltl_equiv}{deleted_lm} + $snap->{ltl_equiv}{deleted_km};
            printf "    projected total      %7.1f MB  (vs actual %.1f)\n",
                $ltl_total / 1024 / 1024, $total / 1024 / 1024;
            $peak_ltl_equiv = $ltl_total if $ltl_total > $peak_ltl_equiv;
        }
        # Track peak even for snapshots without deletions yet
        my $ltl_total = $total + ($snap->{ltl_equiv}{deleted_lm} // 0) + ($snap->{ltl_equiv}{deleted_km} // 0);
        $peak_ltl_equiv = $ltl_total if $ltl_total > $peak_ltl_equiv;
    }

    # High-water marks per structure
    printf "\n  --- Structure High-Water Marks ---\n";
    my $total_hwm = 0;
    $total_hwm += $_ for values %structure_hwm;
    for my $name (sort { $structure_hwm{$b} <=> $structure_hwm{$a} }
                  grep { $structure_hwm{$_} >= 1024 } keys %structure_hwm) {
        printf "    %-20s %7.1f MB  (%4.1f%%)\n",
            $name, $structure_hwm{$name} / 1024 / 1024,
            $total_hwm > 0 ? ($structure_hwm{$name} / $total_hwm) * 100 : 0;
    }

    # ltl comparison summary
    printf "\n  --- ltl Comparison ---\n";
    printf "    Peak ltl-equivalent (structures): %7.1f MB\n", $peak_ltl_equiv / 1024 / 1024;
    printf "    Cumulative deleted log_messages:   %7.1f MB\n", $deleted_log_messages_bytes / 1024 / 1024;
    printf "    Cumulative deleted key_message:    %7.1f MB\n", $deleted_key_message_bytes / 1024 / 1024;
}

printf "\n  Compiled patterns:  %d (cap: %d)\n", $total_patterns, $max_patterns;
printf "  Total clusters:     %d\n", $total_clusters;
printf "  Remaining log_messages keys: %d\n", $remaining_keys;
