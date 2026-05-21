#!/usr/bin/env perl
# compare-percentiles.pl — Tiered tolerance comparison engine for the
# percentile-value regression harness.
#
# Compares one baseline CSV against one freshly-produced CSV for a single
# scenario+file (either MESSAGES or STATS). Emits one line per failure with
# full context (scenario, file, key, column, baseline, new, deviation, rule).
# Exits 0 if no T3/T4 failures; exits 1 otherwise. T1/T2 advisories are
# reported when --show-all is given; they never affect exit code.
#
# Usage:
#   compare-percentiles.pl --scenario <name> --kind messages|stats \
#       --baseline <path> --new <path> [--show-all]
#
# Per-cell tier rules (locked — see tests/percentile-values/README.md):
#   T1  byte-identical
#   T2  abs(new - old) <= 1% * abs(old)
#   T3  abs(new - old) <= 5% * abs(old)
#   T4  structural: same key set, monotonicity (p50<=p90<=p99<=p999), same row count
#
# Percentile columns checked (only these — totals/counts/means are out of
# scope per the harness charter; see issue #223 for those):
#   MESSAGES: P1, P50, P75, P90, P95, P99, P99.9
#   STATS:    p1, p50, p75, p90, p95, p99, p999
#
# Join keys:
#   MESSAGES: composite Category|Message
#   STATS:    timestamp

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

my %opt = (
    scenario => undef,
    kind     => undef,
    baseline => undef,
    new      => undef,
    show_all => 0,
);

GetOptions(
    'scenario=s' => \$opt{scenario},
    'kind=s'     => \$opt{kind},
    'baseline=s' => \$opt{baseline},
    'new=s'      => \$opt{new},
    'show-all'   => \$opt{show_all},
) or die_usage('bad arguments');

die_usage('--scenario required') unless defined $opt{scenario};
die_usage('--kind must be messages or stats')
    unless defined $opt{kind} && $opt{kind} =~ /^(messages|stats)$/;
die_usage('--baseline required') unless defined $opt{baseline} && -f $opt{baseline};
die_usage('--new required')      unless defined $opt{new}      && -f $opt{new};

sub die_usage {
    my $msg = shift // '';
    print STDERR "compare-percentiles.pl: $msg\n" if $msg;
    print STDERR "Usage: compare-percentiles.pl --scenario NAME --kind messages|stats \\\n";
    print STDERR "         --baseline PATH --new PATH [--show-all]\n";
    exit 2;
}

# Column specs per kind. Locked at the values observed in v0.14.5 CSV output.
# Will need an update if issue #221 (header naming alignment) lands.
my %SPEC = (
    messages => {
        key_cols     => [qw(Category Message)],
        join_sep     => '|',
        pct_cols     => [qw(P1 P50 P75 P90 P95 P99 P99.9)],
        monotonic    => [qw(P50 P90 P99 P99.9)],
    },
    stats => {
        key_cols     => [qw(timestamp)],
        join_sep     => '|',
        pct_cols     => [qw(p1 p50 p75 p90 p95 p99 p999)],
        monotonic    => [qw(p50 p90 p99 p999)],
    },
);

my $spec = $SPEC{$opt{kind}};

my ($base_hdr, $base_rows) = read_csv($opt{baseline});
my ($new_hdr,  $new_rows)  = read_csv($opt{new});

# Column-presence preflight. Any percentile column we expect to compare must
# exist in both files; otherwise the harness has nothing to compare. This is
# a T4 (structural) failure that aborts the per-cell loop entirely.
my %t4_failures;
for my $col (@{$spec->{pct_cols}}) {
    if (!exists $base_hdr->{$col}) {
        emit_failure('T4',
            column => $col,
            rule   => "expected percentile column missing from baseline header");
        $t4_failures{header}++;
    }
    if (!exists $new_hdr->{$col}) {
        emit_failure('T4',
            column => $col,
            rule   => "expected percentile column missing from new output header");
        $t4_failures{header}++;
    }
}

# Row-count check (T4).
my $base_n = scalar @$base_rows;
my $new_n  = scalar @$new_rows;
if ($base_n != $new_n) {
    emit_failure('T4',
        rule => "row count differs: baseline=$base_n new=$new_n");
    $t4_failures{row_count}++;
}

# Build keyed maps.
my %base_by_key = map { join_key($_, $base_hdr) => $_ } @$base_rows;
my %new_by_key  = map { join_key($_, $new_hdr)  => $_ } @$new_rows;

# Key-set check (T4). Missing or extra keys are structural failures.
for my $k (sort keys %base_by_key) {
    if (!exists $new_by_key{$k}) {
        emit_failure('T4',
            key  => $k,
            rule => "key present in baseline but missing from new output");
        $t4_failures{missing_key}++;
    }
}
for my $k (sort keys %new_by_key) {
    if (!exists $base_by_key{$k}) {
        emit_failure('T4',
            key  => $k,
            rule => "key present in new output but missing from baseline");
        $t4_failures{extra_key}++;
    }
}

# Per-cell tier checks across the shared key set.
my %tier_counts = (T1 => 0, T2 => 0, T3 => 0, T4 => 0);
my $cells_checked = 0;
my $structural_ok = (keys %t4_failures) ? 0 : 1;

for my $k (sort keys %base_by_key) {
    next unless exists $new_by_key{$k};
    my $b_row = $base_by_key{$k};
    my $n_row = $new_by_key{$k};

    # Per-row monotonicity (T4) on the new output. If baseline had a
    # monotonicity violation we'd see it during baseline regeneration, so
    # check new output only.
    my @mono_vals;
    for my $col (@{$spec->{monotonic}}) {
        next unless exists $new_hdr->{$col};
        my $v = $n_row->[$new_hdr->{$col}];
        next unless defined $v && $v ne '';
        push @mono_vals, [$col, $v];
    }
    for (my $i = 1; $i < @mono_vals; $i++) {
        my ($pcol, $pval) = @{$mono_vals[$i-1]};
        my ($ccol, $cval) = @{$mono_vals[$i]};
        # Skip if either value isn't a clean number.
        next unless looks_like_num_strict($pval) && looks_like_num_strict($cval);
        if ($cval + 0 < $pval + 0) {
            emit_failure('T4',
                key    => $k,
                column => "$pcol -> $ccol",
                baseline => "n/a",
                new    => "$pcol=$pval $ccol=$cval",
                rule   => "monotonicity violated: $ccol < $pcol");
            $tier_counts{T4}++;
            $structural_ok = 0;
        }
    }

    # Per-cell tier classification across percentile columns only.
    for my $col (@{$spec->{pct_cols}}) {
        next unless exists $base_hdr->{$col} && exists $new_hdr->{$col};
        my $bv = $b_row->[$base_hdr->{$col}];
        my $nv = $n_row->[$new_hdr->{$col}];
        $bv //= ''; $nv //= '';
        $cells_checked++;

        my ($tier, $rule, $dev) = classify_cell($bv, $nv);
        $tier_counts{$tier}++;

        # Always emit T3/T4. Emit T1/T2 only when --show-all.
        if ($tier eq 'T3' || $tier eq 'T4') {
            emit_failure($tier,
                key      => $k,
                column   => $col,
                baseline => $bv,
                new      => $nv,
                deviation => $dev,
                rule     => $rule);
        } elsif ($opt{show_all} && ($tier eq 'T1' || $tier eq 'T2')) {
            # T1 is the "no drift" baseline state — only worth printing under
            # --show-all when investigating, since the typical run is all-T1.
            emit_advisory($tier,
                key      => $k,
                column   => $col,
                baseline => $bv,
                new      => $nv,
                deviation => $dev,
                rule     => $rule);
        }
    }
}

# Summary line — always emitted, machine-grep friendly.
printf "%s/%s: %d cells checked, %d T4, %d T3, %d T2, %d T1, structural=%s\n",
    $opt{scenario}, $opt{kind},
    $cells_checked,
    $tier_counts{T4}, $tier_counts{T3}, $tier_counts{T2}, $tier_counts{T1},
    ($structural_ok ? 'OK' : 'FAIL');

exit (($tier_counts{T3} + $tier_counts{T4}) > 0 ? 1 : 0);

# ---------------------------------------------------------------------------

# Classify a single cell.
#
# Returns (tier, rule_string, deviation_string).
#
# Tier ladder (worst-first):
#   T4 if one side parses as a number and the other doesn't (type-mismatch
#      structural failure — but only when the value is expected numeric,
#      which it is for percentile columns).
#   T1 if byte-identical.
#   T2 if abs(new-old) <= 1% * abs(old).
#   T3 if abs(new-old) <= 5% * abs(old) but > 1%.
#   T3 if both empty -> treat as T1 (matches byte-identical case).
#   T3 if baseline is 0 and new is nonzero -> use absolute comparison
#      against 1 (any nonzero is a 100% deviation, so it lands in T3+).
sub classify_cell {
    my ($bv, $nv) = @_;

    # Byte-identical (covers both-empty case too).
    return ('T1', 'byte-identical', '0.00%') if $bv eq $nv;

    my $b_num = looks_like_num_strict($bv);
    my $n_num = looks_like_num_strict($nv);

    if (!$b_num || !$n_num) {
        # One side is non-numeric (likely empty or junk) and the values
        # differ. Structural for a percentile column.
        return ('T4', 'numeric value expected but one side is non-numeric or empty', 'n/a');
    }

    my $b = $bv + 0;
    my $n = $nv + 0;
    my $diff = abs($n - $b);

    # Handle zero baseline.
    if ($b == 0) {
        if ($n == 0) {
            # Both numerically zero but string-different (e.g. "0" vs "0.0").
            # That's a T1 from a value perspective.
            return ('T1', 'numerically zero on both sides', '0.00%');
        }
        # Baseline is zero, new is nonzero — undefined relative deviation.
        # Treat as T3 (loose threshold breached) with a descriptive rule.
        return ('T3', 'baseline is 0; new value is nonzero (undefined relative deviation)', 'inf');
    }

    my $rel = $diff / abs($b);
    my $dev_pct = sprintf('%.2f%%', $rel * 100);

    if ($rel <= 0.01) {
        return ('T2', "abs(new-old) <= 1% * old", $dev_pct);
    }
    if ($rel <= 0.05) {
        return ('T3', "abs(new-old) > 1% * old", $dev_pct);
    }
    return ('T3', "abs(new-old) > 5% * old", $dev_pct);
}

# Strict numeric check — accepts integers and decimals only. Rejects
# scientific notation, NaN, Inf, leading/trailing whitespace. Stricter
# than Scalar::Util::looks_like_number on purpose: percentile columns
# emit plain decimal/integer values, and anything else is suspicious.
sub looks_like_num_strict {
    my $v = shift;
    return 0 unless defined $v;
    return 0 if $v eq '';
    return $v =~ /\A-?\d+(?:\.\d+)?\z/ ? 1 : 0;
}

# Compose the composite key for a row.
sub join_key {
    my ($row, $hdr) = @_;
    my @parts;
    for my $col (@{$spec->{key_cols}}) {
        die "compare-percentiles.pl: key column '$col' missing from header\n"
            unless exists $hdr->{$col};
        my $v = $row->[$hdr->{$col}];
        $v = '' unless defined $v;
        push @parts, $v;
    }
    return join($spec->{join_sep}, @parts);
}

# Print one FAIL line with full context.
sub emit_failure {
    my ($tier, %f) = @_;
    print join_failure_line('FAIL', $tier, %f), "\n";
}

sub emit_advisory {
    my ($tier, %f) = @_;
    print join_failure_line('INFO', $tier, %f), "\n";
}

sub join_failure_line {
    my ($prefix, $tier, %f) = @_;
    my @parts = (
        "$prefix [$tier]",
        "scenario=$opt{scenario}",
        "file=$opt{kind}",
    );
    push @parts, qq{key="$f{key}"}            if defined $f{key};
    push @parts, "column=$f{column}"          if defined $f{column};
    push @parts, "baseline=$f{baseline}"      if defined $f{baseline};
    push @parts, "new=$f{new}"                if defined $f{new};
    push @parts, "deviation=$f{deviation}"    if defined $f{deviation};
    push @parts, qq{rule="$f{rule}"}          if defined $f{rule};
    return join(' ', @parts);
}

# Minimal CSV reader. Handles double-quoted fields with embedded commas and
# escaped quotes ("" -> "), which is what ltl's -o output uses. Comment
# lines (`# …`) at the top of the file are skipped (allows baseline files
# to carry a provenance comment).
sub read_csv {
    my $path = shift;
    open my $fh, '<', $path or die "compare-percentiles.pl: open $path: $!\n";
    my @rows;
    my $header;
    my %hdr_idx;
    while (defined(my $line = <$fh>)) {
        $line =~ s/\r?\n\z//;
        next if !defined $header && $line =~ /^\s*#/;   # skip header comments
        next if $line eq '';
        my @fields = parse_csv_line($line);
        if (!defined $header) {
            $header = \@fields;
            for (my $i = 0; $i < @$header; $i++) {
                $hdr_idx{$header->[$i]} = $i;
            }
            next;
        }
        push @rows, \@fields;
    }
    close $fh;
    die "compare-percentiles.pl: no header found in $path\n" unless defined $header;
    return (\%hdr_idx, \@rows);
}

# Parse one CSV line into fields. Supports quoted fields and "" escapes.
# Does NOT support embedded newlines (ltl doesn't emit those).
sub parse_csv_line {
    my $line = shift;
    my @out;
    my $i = 0;
    my $len = length $line;
    while ($i < $len) {
        my $c = substr($line, $i, 1);
        if ($c eq '"') {
            # Quoted field.
            my $val = '';
            $i++;
            while ($i < $len) {
                my $ch = substr($line, $i, 1);
                if ($ch eq '"') {
                    if ($i + 1 < $len && substr($line, $i+1, 1) eq '"') {
                        $val .= '"';
                        $i += 2;
                    } else {
                        $i++;
                        last;
                    }
                } else {
                    $val .= $ch;
                    $i++;
                }
            }
            push @out, $val;
            # Expect a comma or end-of-line.
            if ($i < $len && substr($line, $i, 1) eq ',') {
                $i++;
            }
        } else {
            # Unquoted field — read until comma.
            my $val = '';
            while ($i < $len) {
                my $ch = substr($line, $i, 1);
                last if $ch eq ',';
                $val .= $ch;
                $i++;
            }
            push @out, $val;
            $i++ if $i < $len && substr($line, $i, 1) eq ',';
        }
    }
    # Handle trailing comma -> empty field.
    if ($len > 0 && substr($line, -1) eq ',') {
        push @out, '';
    }
    return @out;
}
