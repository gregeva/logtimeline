#!/usr/bin/env perl
# ============================================================================
# Alignment benchmark for #96: ltl's compute_mask against alternative aligners.
#
# ltl's arm is ltl's own compute_mask (the banded edit distance, pure Perl),
# compiled from ltl's source by prototype/96-ltl-engine.pl; it is the reference
# every other arm's masks are checked against. The test pairs are message keys
# read and built as ltl builds them. The other arms are the alternatives the
# benchmark compares, recorded in features/fuzzy-message-consolidation.md PF-03
# (the LCS DP ltl first used) and PF-15 (the alignment algorithm). None of them
# is ltl's code.
#
# Usage: prototype/96-alignment-bench.pl [--file <ThingWorx application log>] [--ltl <path>]
# ============================================================================
use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(dirname);
use File::Spec;
require File::Spec->catfile(dirname(File::Spec->rel2abs($0)), '96-ltl-engine.pl');
use Time::HiRes qw(time);
use Algorithm::Diff qw(sdiff traverse_sequences);
use List::Util qw(min max);

eval { require Algorithm::Diff::XS };
my $has_xs = !$@;

use Inline C => <<'END_C';

SV* compute_mask_inline_c(const char *str_a, const char *str_b) {
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

        /* First row directions: insert (left = 2) */
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
                    /* dir = 0, already zero from calloc */
                } else {
                    int sc = prev[j-1] + 1;
                    int dc = prev[j] + 1;
                    int ic = curr[j-1] + 1;
                    if (sc <= dc && sc <= ic) {
                        curr[j] = sc;
                        /* dir = 0 (sub) */
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

            /* Swap prev/curr */
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
# Benchmark: all alignment approaches for compute_mask
# ============================================================================

my $file     = 'logs/ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log';
my $ltl_path = default_ltl_path();
GetOptions('file=s' => \$file, 'ltl=s' => \$ltl_path) or die "Usage: $0 [--file <log>] [--ltl <path>]\n";

# Keys read and built as ltl builds them, not grouped
load_ltl_engine($ltl_path);
proto_configure(group => 0);
print "Parsing log...\n";
proto_read_file($file);
my %level_keys;
push @{ $level_keys{ $_->[1] =~ /^\[([^\]]*)\]/ ? $1 : '' } }, $_->[1] for proto_store();

# Build test pairs
my @keys = sort @{ $level_keys{ERROR} // [] };
my @pairs;

my %by_prefix;
for my $k (@keys) {
    my $p = substr($k, 0, 40);
    push @{$by_prefix{$p}}, $k;
}
for my $p (sort keys %by_prefix) {
    my @group = @{$by_prefix{$p}};
    next unless @group >= 2;
    for my $i (0 .. min($#group - 1, 2)) {
        push @pairs, [ $group[$i], $group[$i+1] ];
    }
}

printf "Test pairs: %d\n\n", scalar @pairs;

my $repeats = 5;

# ============================================================================
# Alternative: LCS DP (pure Perl), the aligner ltl used before PF-15
# ============================================================================

sub compute_mask_current {
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

# ============================================================================
# Approach 3: Algorithm::Diff sdiff (pure Perl)
# ============================================================================

sub compute_mask_sdiff {
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

    my @diff = sdiff(\@a, \@b);

    my $pos_a = 0;
    for my $hunk (@diff) {
        my $op = $hunk->[0];
        if ($op eq 'u') { $mask[$prefix_len + $pos_a] = 1; $pos_a++; }
        elsif ($op eq 'c') { $pos_a++; }
        elsif ($op eq '-') { $pos_a++; }
    }
    return \@mask;
}

# ============================================================================
# Approach 4: Algorithm::Diff traverse_sequences (pure Perl)
# ============================================================================

sub compute_mask_traverse {
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

    traverse_sequences(\@a, \@b, {
        MATCH => sub { $mask[$prefix_len + $_[0]] = 1; },
        DISCARD_A => sub { },
        DISCARD_B => sub { },
    });
    return \@mask;
}

# ============================================================================
# Approach 5: Algorithm::Diff::XS traverse_sequences (C inner loop)
# ============================================================================

sub compute_mask_xs_traverse {
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

    Algorithm::Diff::XS::traverse_sequences(\@a, \@b, {
        MATCH => sub { $mask[$prefix_len + $_[0]] = 1; },
        DISCARD_A => sub { },
        DISCARD_B => sub { },
    });
    return \@mask;
}

# ============================================================================
# Approach 6: Inline::C banded edit distance
# ============================================================================

sub compute_mask_c_wrapper {
    my ($str_a, $str_b) = @_;
    return compute_mask_inline_c($str_a, $str_b);
}

# ============================================================================
# Run benchmarks
# ============================================================================

my @approaches = (
    ['1. ltl compute_mask',     \&main::compute_mask,        'ltl: banded edit distance, pure Perl'],
    ['2. LCS DP (pre-PF-15)',    \&compute_mask_current,      'Pure Perl, LCS O(mn)'],
    ['3. Alg::Diff sdiff',      \&compute_mask_sdiff,         'Pure Perl, Myers O(ND)'],
    ['4. Alg::Diff traverse',   \&compute_mask_traverse,      'Pure Perl, Myers O(ND)'],
);

if ($has_xs) {
    push @approaches, ['5. Alg::Diff::XS trav', \&compute_mask_xs_traverse, 'XS C core, Myers O(ND)'];
}

push @approaches, ['6. Inline::C banded ED', \&compute_mask_c_wrapper, 'Full C, banded O(nk)'];

printf "=== Alignment Benchmark (%d pairs x %d repeats = %d calls each) ===\n",
    scalar @pairs, $repeats, scalar(@pairs) * $repeats;
printf "Algorithm::Diff::XS: %s\n\n", $has_xs ? "available" : "NOT available";

# Consistency check
print "Verifying mask consistency (first 20 pairs)...\n";
my $check_count = min(20, scalar @pairs);
my %diff_pairs;

for my $pi (0 .. $check_count - 1) {
    my $pair = $pairs[$pi];
    my $ref_mask = main::compute_mask($pair->[0], $pair->[1]);

    for my $ai (1 .. $#approaches) {
        my $test_mask = $approaches[$ai][1]->($pair->[0], $pair->[1]);
        my $diffs = 0;
        if (scalar @$ref_mask == scalar @$test_mask) {
            for my $i (0 .. $#$ref_mask) {
                $diffs++ if $ref_mask->[$i] != $test_mask->[$i];
            }
        } else {
            $diffs = -1;
        }
        $diff_pairs{$approaches[$ai][0]}++ if $diffs != 0;
    }
}

for my $ai (1 .. $#approaches) {
    my $name = $approaches[$ai][0];
    my $dp = $diff_pairs{$name} // 0;
    printf "  %-24s %d/%d pairs differ%s\n", $name, $dp, $check_count,
        $dp > 0 ? " (expected: edit-dist vs LCS produce equivalent masks)" : "";
}

# Timing
printf "\n%-26s %10s %10s %10s  %s\n", 'Approach', 'Total', 'Per-call', 'Speedup', 'Notes';
printf "%-26s %10s %10s %10s  %s\n", '-' x 26, '-' x 10, '-' x 10, '-' x 7, '-' x 30;

my $baseline_time;

for my $approach (@approaches) {
    my ($name, $func, $notes) = @$approach;

    # Warmup
    for my $pair (@pairs[0 .. min(4, $#pairs)]) {
        $func->($pair->[0], $pair->[1]);
    }

    my $t_start = time();
    for my $rep (1 .. $repeats) {
        for my $pair (@pairs) {
            $func->($pair->[0], $pair->[1]);
        }
    }
    my $t_elapsed = time() - $t_start;
    my $total_calls = scalar(@pairs) * $repeats;
    my $per_call = ($t_elapsed / $total_calls) * 1000;

    $baseline_time //= $t_elapsed;
    my $speedup = $baseline_time / $t_elapsed;

    printf "%-26s %9.3fs %8.3f ms %8.1fx  %s\n",
        $name, $t_elapsed, $per_call, $speedup, $notes;
}

print "\nDone.\n";
