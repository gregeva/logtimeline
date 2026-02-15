#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(time);
use List::Util qw(min max);

# ============================================================================
# N-gram Tuning Harness for #96
# Tests different gram sizes and step sizes against the real log data
# to find the best time/memory/quality tradeoff.
# ============================================================================

my $file;
my $threshold = 80;
my $trigger = 5000;
my $message_length_cap = 300;
my $occurrence_ceiling = 3;
my $max_patterns = 50;

GetOptions(
    'file=s'    => \$file,
    'threshold=i' => \$threshold,
) or die "Usage: $0 --file <logfile>\n";

die "Error: --file is required\n" unless defined $file;
die "Error: file '$file' not found\n" unless -f $file;

# --- ThingWorx regex ---
my $twx_regex = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;

# ============================================================================
# Parse log file once — shared across all tests
# ============================================================================
my %log_messages;
my %key_message;

print "Parsing: $file\n";
my $t_parse_start = time();

open(my $fh, '<', $file) or die "Cannot open $file: $!\n";
while (my $line = <$fh>) {
    chomp $line;
    if (my ($timestamp, $category, $object, $instance, $user, $session, $platform, $thread, $message) = $line =~ $twx_regex) {
        my $truncated_thread = substr($thread, 0, 20);
        my $truncated_object = substr($object, length($object) > 25 ? length($object) - 25 : 0, 25);
        my $log_key = substr("[$category] [$truncated_thread] [$truncated_object] $message", 0, 350);
        $log_messages{$category}{$log_key}{occurrences}++;
        $key_message{$log_key} //= $log_key;
    }
}
close($fh);

my $t_parse_done = time();
printf "Parse time: %.2f s\n", $t_parse_done - $t_parse_start;

my $total_keys = 0;
for my $cat (keys %log_messages) {
    my $n = scalar keys %{$log_messages{$cat}};
    printf "  %s: %d unique keys\n", $cat, $n;
    $total_keys += $n;
}
printf "Total: %d unique keys\n\n", $total_keys;

# ============================================================================
# Parameterized n-gram functions
# ============================================================================

sub get_ngrams {
    my ($str, $gram_size, $step) = @_;
    my $capped = substr($str, 0, $message_length_cap);
    my $len = length($capped);
    my %grams;
    for (my $i = 0; $i <= $len - $gram_size; $i += $step) {
        $grams{substr($capped, $i, $gram_size)} = 1;
    }
    return \%grams;
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

# ============================================================================
# Alignment functions (same as prototype)
# ============================================================================

sub compute_mask {
    my ($str_a, $str_b) = @_;
    my $len_a = length $str_a;
    my $len_b = length $str_b;

    my $prefix_len = 0;
    my $min_len = $len_a < $len_b ? $len_a : $len_b;
    while ($prefix_len < $min_len &&
           substr($str_a, $prefix_len, 1) eq substr($str_b, $prefix_len, 1)) {
        $prefix_len++;
    }

    my $suffix_len = 0;
    while ($suffix_len < ($min_len - $prefix_len) &&
           substr($str_a, $len_a - 1 - $suffix_len, 1) eq substr($str_b, $len_b - 1 - $suffix_len, 1)) {
        $suffix_len++;
    }

    my @mask = (0) x $len_a;
    for my $i (0 .. $prefix_len - 1) { $mask[$i] = 1; }
    for my $i (0 .. $suffix_len - 1) { $mask[$len_a - 1 - $i] = 1; }

    my $mid_a_len = $len_a - $prefix_len - $suffix_len;
    my $mid_b_len = $len_b - $prefix_len - $suffix_len;
    return \@mask if $mid_a_len <= 0 || $mid_b_len <= 0;

    my @a = split //, substr($str_a, $prefix_len, $mid_a_len);
    my @b = split //, substr($str_b, $prefix_len, $mid_b_len);
    my $m = scalar @a;
    my $n = scalar @b;

    my $row_bytes = int(($n + 1 + 3) / 4);
    my @dir_rows;
    my $zero_row = "\0" x $row_bytes;
    for my $i (0 .. $m) { $dir_rows[$i] = $zero_row; }

    my @prev = (0) x ($n + 1);
    my @curr;

    for my $i (1 .. $m) {
        @curr = (0) x ($n + 1);
        for my $j (1 .. $n) {
            if ($a[$i-1] eq $b[$j-1]) {
                $curr[$j] = $prev[$j-1] + 1;
            } elsif ($prev[$j] >= $curr[$j-1]) {
                $curr[$j] = $prev[$j];
                vec($dir_rows[$i], $j, 2) = 1;
            } else {
                $curr[$j] = $curr[$j-1];
                vec($dir_rows[$i], $j, 2) = 2;
            }
        }
        @prev = @curr;
    }

    my ($i, $j) = ($m, $n);
    while ($i > 0 && $j > 0) {
        my $d = vec($dir_rows[$i], $j, 2);
        if ($d == 0) { $mask[$prefix_len + $i - 1] = 1; $i--; $j--; }
        elsif ($d == 1) { $i--; }
        else { $j--; }
    }
    return \@mask;
}

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
                my $has_var_before = ($start == 0) ? 0 : ($m[$start-1] == 0);
                my $has_var_after  = ($i >= $len)  ? 0 : ($m[$i] == 0);
                if ($has_var_before && $has_var_after) {
                    for my $k ($start .. $start + $run_len - 1) { $m[$k] = 0; }
                }
            }
        } else { $i++; }
    }

    $i = 0;
    while ($i < $len) {
        if ($m[$i] == 0) {
            my $span_start = $i;
            my $j = $i;
            while ($j < $len) {
                if ($m[$j] == 1) {
                    my $keep_start = $j;
                    while ($j < $len && $m[$j] == 1) { $j++; }
                    if ($j - $keep_start >= 10) { $j = $keep_start; last; }
                } else { $j++; }
            }
            my $span_end = $j;
            my $span_len = $span_end - $span_start;
            if ($span_len >= 5) {
                my $keep_count = 0;
                for my $k ($span_start .. $span_end - 1) { $keep_count++ if $m[$k] == 1; }
                if ($keep_count / $span_len < 0.40) {
                    for my $k ($span_start .. $span_end - 1) { $m[$k] = 0; }
                }
            }
            $i = $span_end;
        } else { $i++; }
    }
    return \@m;
}

sub derive_canonical {
    my ($reference_string, $mask) = @_;
    my @chars = split //, $reference_string;
    my $result = '';
    my $in_variable = 0;
    for my $i (0 .. $#chars) {
        if ($mask->[$i]) {
            if ($chars[$i] eq '*') {
                if (!$in_variable) { $result .= '*'; $in_variable = 1; }
            } else {
                $in_variable = 0;
                $result .= $chars[$i];
            }
        } else {
            if (!$in_variable) { $result .= '*'; $in_variable = 1; }
        }
    }
    return $result;
}

sub derive_regex {
    my ($reference_string, $mask) = @_;
    my @chars = split //, $reference_string;
    my $pattern = '^';
    my $literal_buf = '';
    my $in_variable = 0;
    for my $i (0 .. $#chars) {
        if ($mask->[$i]) {
            if ($chars[$i] eq '*') {
                if (length $literal_buf) { $pattern .= quotemeta($literal_buf); $literal_buf = ''; }
                if (!$in_variable) { $in_variable = 1; }
            } else {
                if ($in_variable) { $pattern .= '.+?'; $in_variable = 0; }
                $literal_buf .= $chars[$i];
            }
        } else {
            if (length $literal_buf) { $pattern .= quotemeta($literal_buf); $literal_buf = ''; }
            if (!$in_variable) { $in_variable = 1; }
        }
    }
    if ($in_variable) { $pattern .= '.+?'; }
    if (length $literal_buf) { $pattern .= quotemeta($literal_buf); }
    $pattern .= '$';
    return qr/$pattern/;
}

# ============================================================================
# Run one full consolidation test with given gram_size and step
# ============================================================================

sub run_test {
    my ($gram_size, $step) = @_;

    my %ngram_index;
    my %key_grams;
    my %canonical_patterns;
    my %clusters;

    my $t_start = time();

    # --- Index building ---
    my $total_gram_entries = 0;  # total postings in index

    for my $cat (sort keys %log_messages) {
        my @keys = keys %{$log_messages{$cat}};
        my $batch_size = min($trigger, scalar @keys);
        my @batch = @keys[0 .. $batch_size - 1];

        # Filter by ceiling
        @batch = grep { ($log_messages{$cat}{$_}{occurrences} // 1) < $occurrence_ceiling } @batch;
        next unless @batch >= 2;

        for my $log_key (@batch) {
            my $message = $key_message{$log_key};
            next unless defined $message;
            my $grams = get_ngrams($message, $gram_size, $step);
            $key_grams{$log_key} = $grams;
            for my $g (keys %$grams) {
                $ngram_index{$cat}{$g}{$log_key} = 1;
                $total_gram_entries++;
            }
        }
    }

    my $t_indexed = time();

    # --- Discovery + Consolidation ---
    my $total_patterns = 0;
    my $total_absorbed = 0;
    my $total_compute_mask_calls = 0;

    for my $cat (sort keys %log_messages) {
        my @all_keys = keys %{$log_messages{$cat}};
        my @unmatched = @all_keys;
        next unless @unmatched >= 10;

        my $pass = 0;
        my $max_passes = 10;

        while ($pass < $max_passes) {
            $pass++;

            # Get discovery candidates (below ceiling, not yet matched)
            my @discovery = grep {
                ($log_messages{$cat}{$_}{occurrences} // 1) < $occurrence_ceiling
                && exists $key_grams{$_}
            } @unmatched;

            last if @discovery < 2;

            my %consumed;
            my $pass_patterns = 0;
            my $pass_absorbed = 0;
            my $keys_searched = 0;
            my $max_search = min(500, scalar @discovery);
            my $current_patterns = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;

            for my $key (@discovery) {
                last if $keys_searched >= $max_search;
                last if $current_patterns >= $max_patterns;
                next if $consumed{$key};

                $keys_searched++;
                my $source_grams = $key_grams{$key};
                next unless $source_grams;
                my $source_size = scalar keys %$source_grams;
                next if $source_size == 0;

                my $min_hits = int($threshold * $source_size / 100);
                my $min_cand_size = int($source_size * $threshold / (200 - $threshold));
                my $max_cand_size = int($source_size * (200 - $threshold) / $threshold) + 1;

                # Find candidates
                my %candidate_hits;
                for my $g (keys %$source_grams) {
                    next unless exists $ngram_index{$cat}{$g};
                    for my $ck (keys %{$ngram_index{$cat}{$g}}) {
                        next if $ck eq $key;
                        $candidate_hits{$ck}++;
                    }
                }

                my @top = sort { $candidate_hits{$b} <=> $candidate_hits{$a} }
                          grep { $candidate_hits{$_} >= $min_hits }
                          keys %candidate_hits;
                splice(@top, 50) if @top > 50;

                for my $cand_key (@top) {
                    next if $consumed{$cand_key};
                    my $cand_grams = $key_grams{$cand_key};
                    next unless $cand_grams;
                    my $cand_size = scalar keys %$cand_grams;
                    next if $cand_size < $min_cand_size || $cand_size > $max_cand_size;

                    my $score = dice_coefficient($source_grams, $cand_grams);
                    next unless $score >= $threshold;

                    # Align
                    my $msg_a = substr($key_message{$key} // '', 0, $message_length_cap);
                    my $msg_b = substr($key_message{$cand_key} // '', 0, $message_length_cap);

                    my $raw_mask = compute_mask($msg_a, $msg_b);
                    $total_compute_mask_calls++;
                    my $mask = coalesce_mask($raw_mask);
                    my $canonical = derive_canonical($msg_a, $mask);
                    my $regex = derive_regex($msg_a, $mask);

                    next unless ($msg_a =~ $regex) && ($msg_b =~ $regex);

                    $consumed{$key} = 1;
                    $consumed{$cand_key} = 1;

                    my $cluster_occ = ($log_messages{$cat}{$key}{occurrences} // 0)
                                    + ($log_messages{$cat}{$cand_key}{occurrences} // 0);
                    my $cluster_matches = 2;
                    $pass_absorbed += 2;

                    # Interleaved re-scan
                    for my $ukey (@unmatched) {
                        next if $consumed{$ukey};
                        my $umsg = $key_message{$ukey};
                        next unless defined $umsg;
                        my $capped = substr($umsg, 0, $message_length_cap);
                        if ($capped =~ $regex) {
                            $consumed{$ukey} = 1;
                            $cluster_occ += ($log_messages{$cat}{$ukey}{occurrences} // 0);
                            $cluster_matches++;
                            $pass_absorbed++;
                        }
                    }

                    $clusters{$cat}{$canonical} = {
                        occurrences => $cluster_occ,
                        match_count => $cluster_matches,
                    };
                    push @{$canonical_patterns{$cat}}, {
                        pattern     => $regex,
                        canonical   => $canonical,
                        match_count => $cluster_matches,
                    };
                    $current_patterns++;
                    $pass_patterns++;

                    last;  # one pattern per source key
                }
            }

            # Remove consumed
            @unmatched = grep { !$consumed{$_} } @unmatched;

            $total_patterns += $pass_patterns;
            $total_absorbed += $pass_absorbed;

            last if $pass_patterns == 0;
            last if $pass_absorbed == 0;
        }
    }

    my $t_done = time();

    # Count remaining unique entries
    my $remaining = 0;
    for my $cat (keys %log_messages) {
        my $cluster_count = exists $clusters{$cat} ? scalar keys %{$clusters{$cat}} : 0;
        # Rough: total keys - absorbed + cluster_count
        $remaining += (scalar keys %{$log_messages{$cat}}) + $cluster_count;
    }
    $remaining -= $total_absorbed;

    # Get RSS
    my $rss_mb = 0;
    eval {
        my $rss = `ps -o rss= -p $$`;
        chomp $rss;
        $rss_mb = $rss / 1024 if $rss;
    };

    # Count unique grams in index
    my $unique_grams = 0;
    for my $cat (keys %ngram_index) {
        $unique_grams += scalar keys %{$ngram_index{$cat}};
    }

    # Grams per message (average)
    my $total_indexed = scalar keys %key_grams;
    my $avg_grams = 0;
    if ($total_indexed > 0) {
        my $sum = 0;
        for my $k (keys %key_grams) { $sum += scalar keys %{$key_grams{$k}}; }
        $avg_grams = $sum / $total_indexed;
    }

    return {
        gram_size   => $gram_size,
        step        => $step,
        index_time  => $t_indexed - $t_start,
        total_time  => $t_done - $t_start,
        patterns    => $total_patterns,
        absorbed    => $total_absorbed,
        remaining   => $remaining,
        mask_calls  => $total_compute_mask_calls,
        unique_grams => $unique_grams,
        avg_grams   => $avg_grams,
        gram_entries => $total_gram_entries,
        rss_mb      => $rss_mb,
    };
}

# ============================================================================
# Test matrix
# ============================================================================

my @configs = (
    # [gram_size, step]
    [3, 1],   # current: trigrams, step 1
    [4, 1],   # 4-grams, step 1
    [4, 2],   # 4-grams, step 2
    [5, 1],   # 5-grams, step 1
    [5, 2],   # 5-grams, step 2
    [5, 3],   # 5-grams, step 3
    [6, 2],   # 6-grams, step 2
    [6, 3],   # 6-grams, step 3
    [8, 3],   # 8-grams, step 3
    [8, 4],   # 8-grams, step 4
);

printf "=== N-gram Tuning Test ===\n";
printf "Threshold: %d%%  Trigger: %d  Ceiling: %d  MaxPatterns: %d\n\n", $threshold, $trigger, $occurrence_ceiling, $max_patterns;

printf "%-12s %8s %8s %8s %8s %8s %8s %8s %10s %8s\n",
    "Config", "IdxTime", "Total", "Patterns", "Absorbed", "Remain", "Masks", "AvgGrams", "GramIdx", "RSS MB";
printf "%-12s %8s %8s %8s %8s %8s %8s %8s %10s %8s\n",
    "------", "-------", "-----", "--------", "--------", "------", "-----", "--------", "-------", "------";

my @results;
for my $cfg (@configs) {
    my ($gs, $st) = @$cfg;
    printf "Testing %d-gram step %d...", $gs, $st;
    my $r = run_test($gs, $st);
    push @results, $r;

    printf "\r%-12s %7.2fs %7.2fs %8d %8d %8d %8d %8.1f %10d %7.1f\n",
        "${gs}-gram/s$st",
        $r->{index_time}, $r->{total_time}, $r->{patterns}, $r->{absorbed},
        $r->{remaining}, $r->{mask_calls}, $r->{avg_grams}, $r->{gram_entries},
        $r->{rss_mb};
}

printf "\nDone.\n";
