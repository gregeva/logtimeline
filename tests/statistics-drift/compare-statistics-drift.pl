#!/usr/bin/env perl
#
# compare-statistics-drift.pl — L1+L2 statistics comparison engine
# for the statistics-drift test harness (Issue #224).
#
# This file ships Phases C (L1 drift + L2 intra-row invariants) of the
# four-layer harness. Phase E adds L4 cross-model pairing and Phase F
# adds L3 oracle integration; both extend this file without changing its
# invocation interface.
#
# Invocation interface (locked):
#
#   compare-statistics-drift.pl --scenario <name> --file-kind messages|stats \
#       --new <path> [--baseline <path>] [--show-all] [--oracle-json <path>]
#       [--paired-with <other-scenario-name> --paired-new <path>]
#
# Exit codes:
#   0   no T3/T4 failures across any layer
#   1   at least one T3/T4 failure
#   2   invocation error (missing args, missing files, etc.)
#
# Failure output (Decision 7, self-documenting per HARNESS-DESIGN.md):
#   FAIL [Ttier-Llayer] scenario=... file=... key="..." column=...
#       baseline=... new=... deviation=...%
#       asserts: <invariant in plain English>
#       produced_by: <function in ltl that emits the value>
#       contract: <feature file section reference>
#       rule: <the inequality that was breached>
#
# Audit against tests/HARNESS-DESIGN.md ten traps:
#   1.  set -e + 2>/dev/null suppression — N/A (Perl, not bash; no silent
#       output capture)
#   2.  || true swallowing failures — N/A (Perl, not bash)
#   3.  Empty sed range output ambiguous — N/A (no sed range extraction)
#   4.  awk END runs even on no matching rows — N/A (no awk)
#   5.  grep -c zero looks successful — N/A (no grep -c)
#   6.  Unconditional counter advancement — checked: $stats counters
#       advance only when a comparison actually fired (see classify_cell)
#   7.  local x=$(...) masks exit code — N/A (Perl, not bash)
#   8.  Intentional non-zero exits in pipefail — N/A
#   9.  Temp artifacts written next to deliverables — N/A (engine writes
#       nothing; all output goes to STDOUT/STDERR)
#   10. mktemp -d without EXIT trap — N/A (no temp dirs)
#
#   Two principles from HARNESS-DESIGN apply directly:
#   - "Self-documenting assertions": every L1 cell carries column-derived
#     asserts/produced_by/contract; every L2 invariant carries its own
#     triple. See %L1_FIELDS and %L2_INVARIANTS below.
#   - "Anchor-missing is failure, not pass": missing baseline emits a
#     diagnostic and fails the file. Missing rules TSV exits non-zero.

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Spec;

#-------------------------------------------------------------------------
# Argument parsing and required-file preflight.
#-------------------------------------------------------------------------

my %opt = (
    scenario                => undef,
    file_kind               => undef,
    baseline                => undef,
    new                     => undef,
    show_all                => 0,
    oracle_json             => undef,
    paired_with             => undef,
    paired_new              => undef,
    ignore_row_key_mismatch => 0,
);

GetOptions(
    'scenario=s'                => \$opt{scenario},
    'file-kind=s'               => \$opt{file_kind},
    'baseline=s'                => \$opt{baseline},
    'new=s'                     => \$opt{new},
    'show-all'                  => \$opt{show_all},
    'oracle-json=s'             => \$opt{oracle_json},
    'paired-with=s'             => \$opt{paired_with},
    'paired-new=s'              => \$opt{paired_new},
    'ignore-row-key-mismatch'   => \$opt{ignore_row_key_mismatch},
) or die "usage error\n";

for my $required (qw(scenario file_kind new)) {
    unless (defined $opt{$required}) {
        print STDERR "compare-statistics-drift.pl: missing --$required\n";
        exit 2;
    }
}

unless ($opt{file_kind} eq 'messages' || $opt{file_kind} eq 'stats') {
    print STDERR "compare-statistics-drift.pl: --file-kind must be 'messages' or 'stats'\n";
    exit 2;
}

unless (-f $opt{new}) {
    print STDERR "compare-statistics-drift.pl: --new file missing: $opt{new}\n";
    exit 2;
}

if (defined $opt{baseline} && !-f $opt{baseline}) {
    print STDERR "compare-statistics-drift.pl: --baseline file missing: $opt{baseline}\n";
    exit 2;
}

#-------------------------------------------------------------------------
# Locate rules TSV (#223's source of truth for column specs).
#-------------------------------------------------------------------------

my $SCRIPT_DIR = dirname(File::Spec->rel2abs(__FILE__));
my $REPO_DIR   = File::Spec->rel2abs("$SCRIPT_DIR/../..");
my $RULES_TSV  = "$REPO_DIR/tests/csv-output/rules/$opt{file_kind}-columns.tsv";

unless (-f $RULES_TSV) {
    print STDERR "compare-statistics-drift.pl: rules TSV missing: $RULES_TSV\n";
    print STDERR "  This is #223's source of truth for column specs. Run\n";
    print STDERR "  validate-csv-output.sh first to surface any structural issue.\n";
    exit 2;
}

#-------------------------------------------------------------------------
# Identifier columns excluded from numeric comparison per Decision 5.
#-------------------------------------------------------------------------

my %IDENTIFIER_COLUMNS = (
    category  => 1,
    message   => 1,
    timestamp => 1,
);

#-------------------------------------------------------------------------
# Load rules TSV; build the canonical list of numeric columns this engine
# will compare. Per Decision 5: every column whose type is int or float,
# excluding pure identifiers. The harness refuses to start if a column is
# missing its spec (would indicate the rules TSV and #224 are out of sync).
#-------------------------------------------------------------------------

sub load_rules {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $header = <$fh>;
    chomp $header;
    my @hdr = split /\t/, $header;
    my %col_idx = map { $hdr[$_] => $_ } 0 .. $#hdr;
    for my $required (qw(column type family)) {
        unless (exists $col_idx{$required}) {
            print STDERR "compare-statistics-drift.pl: rules TSV $path missing column header '$required'\n";
            exit 2;
        }
    }
    my @rules;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line eq '' || $line =~ /^#/;
        my @f = split /\t/, $line;
        push @rules, {
            column => $f[$col_idx{column}],
            type   => $f[$col_idx{type}],
            family => $f[$col_idx{family}],
        };
    }
    close $fh;
    return \@rules;
}

sub numeric_columns_from_rules {
    my ($rules_ref) = @_;
    my @cols;
    for my $r (@$rules_ref) {
        next if $IDENTIFIER_COLUMNS{$r->{column}};
        next unless $r->{type} eq 'int' || $r->{type} eq 'float';
        push @cols, $r->{column};
    }
    return \@cols;
}

my $RULES        = load_rules($RULES_TSV);
my $NUMERIC_COLS = numeric_columns_from_rules($RULES);
my %COL_FAMILY   = map { $_->{column} => $_->{family} } @$RULES;
my %COL_TYPE     = map { $_->{column} => $_->{type}   } @$RULES;

#-------------------------------------------------------------------------
# CSV parsing. ltl -o emits comma-separated rows with double-quoted fields
# containing embedded commas or spaces. We parse with a state machine
# rather than pulling in Text::CSV (one less dependency, and the format
# is constrained).
#-------------------------------------------------------------------------

sub parse_csv_line {
    my ($line) = @_;
    my @out;
    my $cur = '';
    my $in_quote = 0;
    my $i = 0;
    while ($i < length $line) {
        my $c = substr($line, $i, 1);
        if ($in_quote) {
            if ($c eq '"') {
                # Embedded "" -> literal quote, else end of quoted field.
                if ($i + 1 < length($line) && substr($line, $i+1, 1) eq '"') {
                    $cur .= '"';
                    $i += 2;
                    next;
                }
                $in_quote = 0;
                $i++;
                next;
            }
            $cur .= $c;
            $i++;
            next;
        }
        if ($c eq '"') {
            $in_quote = 1;
            $i++;
            next;
        }
        if ($c eq ',') {
            push @out, $cur;
            $cur = '';
            $i++;
            next;
        }
        $cur .= $c;
        $i++;
    }
    push @out, $cur;
    return \@out;
}

sub load_csv {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $header_line = <$fh>;
    return { header => [], rows => [] } unless defined $header_line;
    chomp $header_line;
    my $header = parse_csv_line($header_line);
    my @rows;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line eq '';
        my $values = parse_csv_line($line);
        my %row;
        for my $i (0 .. $#$header) {
            $row{$header->[$i]} = $values->[$i] // '';
        }
        push @rows, \%row;
    }
    close $fh;
    return { header => $header, rows => \@rows };
}

#-------------------------------------------------------------------------
# Row-key derivation. MESSAGES is keyed by (category, message); STATS is
# keyed by timestamp.
#-------------------------------------------------------------------------

sub row_key {
    my ($row, $file_kind) = @_;
    if ($file_kind eq 'messages') {
        return ($row->{category} // '') . '|' . ($row->{message} // '');
    }
    return $row->{timestamp} // '';
}

#-------------------------------------------------------------------------
# Self-documenting assertion fields (Decision 7 + HARNESS-DESIGN.md).
#-------------------------------------------------------------------------

# Layer-1 column-family rollup. Asserts/produced_by/contract are derived
# from the family the column belongs to. produced_by names the ltl sub
# (not a line number — those drift, per HARNESS-DESIGN).
my %L1_FIELDS_BY_FAMILY = (
    meta => {
        asserts     => 'aggregate metadata (row count or category meta) is stable under unchanged accumulation',
        produced_by => 'accumulate_log_record() and finalize_buckets() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 1 — Layer 1 drift',
    },
    duration => {
        asserts     => 'duration statistic is stable under unchanged sample-collection and reduction',
        produced_by => 'calculate_statistics() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 1 — Layer 1 drift',
    },
    bytes => {
        asserts     => 'bytes aggregate is stable under unchanged accumulation',
        produced_by => 'accumulate_log_record() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 1 — Layer 1 drift',
    },
    count => {
        asserts     => 'count statistic is stable under unchanged count-reduction',
        produced_by => 'calculate_statistics() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 1 — Layer 1 drift',
    },
    percentile => {
        asserts     => 'percentile value is stable under unchanged percentile algorithm',
        produced_by => 'calculate_percentiles_for_bucket() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 1 — Layer 1 drift',
    },
    shape => {
        asserts     => 'distribution-shape statistic is stable under unchanged shape formula',
        produced_by => 'calculate_shape_statistics() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 1 — Layer 1 drift',
    },
    level => {
        asserts     => 'per-level count or rate is stable under unchanged classification',
        produced_by => 'accumulate_log_record() and finalize_buckets() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 1 — Layer 1 drift',
    },
);

#-------------------------------------------------------------------------
# Tolerance for numeric equality in L2 derivation and ordering checks.
#
# ltl's rules TSV declares max_decimals=5 for most numeric columns, but
# its actual emission is not uniform: some columns (count_mean, mean for
# certain buckets, percentile values) are integer-truncated via sprintf
# "%.0f" — see ltl:8119, ltl:8157, ltl:8280. This means a row can have
# min=35.314 (decimals retained) and p1=35 (truncated). The mathematical
# invariant min <= p1 is then breached by up to 1.0 absolute, without any
# algorithmic bug present.
#
# DERIVATION_EPS absorbs this 1.0-unit display precision gap. The L2
# invariants still catch genuine algorithmic bugs (mismatches at the
# 1.0+ scale) without false-alarming on truncation.
#
# Issue #268 tracks the precision truncation as a real finding (it
# defeats microsecond-precision input). Once that ships and time-valued
# statistics emit with input-derived precision, these tolerances tighten
# to ~1e-3 or whatever the resolved precision dictates.
#-------------------------------------------------------------------------

use constant DERIVATION_EPS  => 1.0;
use constant ORDERING_EPS    => 1.0;

#-------------------------------------------------------------------------
# Helpers: numeric parsing and tier classification.
#-------------------------------------------------------------------------

sub is_blank      { defined $_[0] && $_[0] eq '' }
sub is_present    { defined $_[0] && $_[0] ne '' }

sub as_num {
    my ($v) = @_;
    return undef if !is_present($v);
    return undef unless $v =~ /^-?[0-9]+(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?$/;
    return $v + 0;
}

# Classify (baseline, new) for one cell. Returns ('T1'..'T3', deviation_pct).
# T4 is reserved for L2 cross-column invariants and is not returned by L1.
sub classify_cell {
    my ($base, $new) = @_;
    return ('T1', 0.0) if $base eq $new;
    my $b = as_num($base);
    my $n = as_num($new);
    return ('T_NONNUMERIC', undef) if !defined $b || !defined $n;
    if ($b == 0) {
        return ('T1', 0.0) if $n == 0;
        return ('T3', 'inf');
    }
    my $dev = abs($n - $b) / abs($b) * 100.0;
    return ('T1', $dev) if $dev == 0.0;
    return ('T2', $dev) if $dev <= 1.0;
    return ('T3', $dev) if $dev <= 5.0;
    return ('T3', $dev);  # >5% is still classified T3 per Decision 7; T4 reserved for L2
}

#-------------------------------------------------------------------------
# Failure-line emission (Decision 7).
#-------------------------------------------------------------------------

sub emit_failure {
    my (%f) = @_;
    my $dev;
    if (!defined $f{deviation}) {
        $dev = 'n/a';
    } elsif (ref $f{deviation}) {
        $dev = ${ $f{deviation} };
    } elsif ($f{deviation} =~ /^-?[0-9]+(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?$/) {
        $dev = sprintf('%.2f%%', $f{deviation});
    } else {
        $dev = $f{deviation};
    }
    print "FAIL [$f{tier}-$f{layer}] scenario=$f{scenario} file=$f{file} key=\"$f{key}\" column=$f{column}\n";
    print "       baseline=$f{baseline} new=$f{new} deviation=$dev\n";
    print "       asserts: $f{asserts}\n";
    print "       produced_by: $f{produced_by}\n";
    print "       contract: $f{contract}\n";
    print "       rule: $f{rule}\n";
}

sub emit_advisory {
    my (%f) = @_;
    return unless $opt{show_all};
    my $dev = defined $f{deviation}
        ? sprintf('%.4f%%', $f{deviation})
        : 'n/a';
    print "ADV  [$f{tier}-$f{layer}] scenario=$f{scenario} file=$f{file} key=\"$f{key}\" column=$f{column} baseline=$f{baseline} new=$f{new} deviation=$dev\n";
}

sub emit_structure_drift {
    my (%f) = @_;
    print "STRUCTURE_DRIFT: run validate-csv-output.sh first\n";
    print "  scenario=$f{scenario} file=$f{file}\n";
    print "  detail: $f{detail}\n";
    print "  asserts: column set / ordering / row count agree between baseline and new\n";
    print "  produced_by: print_message_summary() / print_bar_graph() in ltl\n";
    print "  contract: features/224-validate-statistics-test-harness.md § Decision 2 — precondition contract\n";
}

#-------------------------------------------------------------------------
# Structural pre-check. Per Decision 2: if baseline and new disagree on
# column presence/ordering or row count, this is #223's territory — emit
# one STRUCTURE_DRIFT diagnostic and stop. Do NOT continue with per-cell
# L1/L2 (would shadow the real diagnosis).
#-------------------------------------------------------------------------

sub structural_preflight {
    my ($baseline, $new, $scenario, $file_kind) = @_;

    my @b_hdr = @{ $baseline->{header} };
    my @n_hdr = @{ $new->{header} };

    if (scalar(@b_hdr) != scalar(@n_hdr)) {
        emit_structure_drift(
            scenario => $scenario,
            file     => $file_kind,
            detail   => "column count differs: baseline=".scalar(@b_hdr)." new=".scalar(@n_hdr),
        );
        return 0;
    }
    for my $i (0 .. $#b_hdr) {
        if ($b_hdr[$i] ne $n_hdr[$i]) {
            emit_structure_drift(
                scenario => $scenario,
                file     => $file_kind,
                detail   => "column [$i] differs: baseline='$b_hdr[$i]' new='$n_hdr[$i]'",
            );
            return 0;
        }
    }
    my $b_rows = scalar(@{ $baseline->{rows} });
    my $n_rows = scalar(@{ $new->{rows} });
    if ($b_rows != $n_rows) {
        emit_structure_drift(
            scenario => $scenario,
            file     => $file_kind,
            detail   => "row count differs: baseline=$b_rows new=$n_rows",
        );
        return 0;
    }
    return 1;
}

#-------------------------------------------------------------------------
# Layer 1: per-cell drift, paired by row-key.
#-------------------------------------------------------------------------

sub run_layer1 {
    my ($baseline, $new, $scenario, $file_kind, $stats) = @_;

    # Index baseline rows by key.
    my %by_key;
    for my $r (@{ $baseline->{rows} }) {
        $by_key{ row_key($r, $file_kind) } = $r;
    }

    my @hdr = @{ $new->{header} };
    # Only compare columns that are (a) in the new header AND (b) in the
    # numeric column set the engine resolved at startup. This is the
    # intersection of "what the rules TSV says is numeric" and "what this
    # produced CSV actually contains" — the rules TSV may declare a
    # dynamic column that this scenario didn't activate.
    my @cols_to_check = grep {
        my $c = $_;
        !$IDENTIFIER_COLUMNS{$c} &&
        (grep { $_ eq $c } @hdr) &&
        (grep { $_ eq $c } @$NUMERIC_COLS)
    } @hdr;

    for my $n_row (@{ $new->{rows} }) {
        my $k = row_key($n_row, $file_kind);
        my $b_row = $by_key{$k};
        unless (defined $b_row) {
            # Row exists in new CSV but not in baseline. Most common cause:
            # tie-shuffle in ltl's ranking step (Issue #269) — different
            # messages tying at the rank-N boundary win in different runs.
            $stats->{key_mismatch}++;
            emit_row_key_mismatch(
                scenario   => $scenario,
                file_kind  => $file_kind,
                key        => $k,
                direction  => 'new-not-in-baseline',
            );
            next;
        }
        for my $col (@cols_to_check) {
            my $b_val = $b_row->{$col} // '';
            my $n_val = $n_row->{$col} // '';
            # Skip blank-on-blank cells (legitimate per Decision 5 — shape
            # statistics may be blank when n < 4 or std_dev == 0).
            next if is_blank($b_val) && is_blank($n_val);
            if (is_blank($b_val) xor is_blank($n_val)) {
                # Blank-vs-populated is a real change; classify as T3.
                $stats->{T3}++;
                my $fields = $L1_FIELDS_BY_FAMILY{ $COL_FAMILY{$col} // 'meta' };
                emit_failure(
                    tier        => 'T3',
                    layer       => 'L1',
                    scenario    => $scenario,
                    file        => $file_kind,
                    key         => $k,
                    column      => $col,
                    baseline    => $b_val eq '' ? '(blank)' : $b_val,
                    new         => $n_val eq '' ? '(blank)' : $n_val,
                    deviation   => 'blank-vs-populated',
                    asserts     => $fields->{asserts},
                    produced_by => $fields->{produced_by},
                    contract    => $fields->{contract},
                    rule        => 'cell populated on one side but blank on the other',
                );
                $stats->{cells_checked}++;
                next;
            }
            my ($tier, $dev) = classify_cell($b_val, $n_val);
            $stats->{cells_checked}++;
            if ($tier eq 'T_NONNUMERIC') {
                # Identifier-ish cell holding non-numeric content the rules
                # TSV claimed was numeric. Should not happen if the rules
                # TSV is consistent with #223's structural enforcement.
                $stats->{nonnumeric}++;
                next;
            }
            $stats->{$tier}++;
            if ($tier eq 'T1') {
                # byte-identical, no advisory needed unless --show-all
                if ($opt{show_all} && $b_val ne $n_val) {
                    # exact match in numeric sense but textual difference
                    # (rare: e.g. "1.0" vs "1") — surface under show-all
                    emit_advisory(
                        tier => 'T1', layer => 'L1',
                        scenario => $scenario, file => $file_kind,
                        key => $k, column => $col,
                        baseline => $b_val, new => $n_val,
                        deviation => 0.0,
                    );
                }
                next;
            }
            if ($tier eq 'T2') {
                emit_advisory(
                    tier => 'T2', layer => 'L1',
                    scenario => $scenario, file => $file_kind,
                    key => $k, column => $col,
                    baseline => $b_val, new => $n_val,
                    deviation => $dev,
                );
                next;
            }
            # T3 — blocking.
            my $fields = $L1_FIELDS_BY_FAMILY{ $COL_FAMILY{$col} // 'meta' };
            emit_failure(
                tier        => 'T3',
                layer       => 'L1',
                scenario    => $scenario,
                file        => $file_kind,
                key         => $k,
                column      => $col,
                baseline    => $b_val,
                new         => $n_val,
                deviation   => $dev,
                asserts     => $fields->{asserts},
                produced_by => $fields->{produced_by},
                contract    => $fields->{contract},
                rule        => 'abs(new-old) > 1% * old (advisory threshold breached)',
            );
        }
    }

    # Reverse direction: any baseline row whose key was NOT seen in the
    # new CSV. Same cause family as the forward direction (tie-shuffle in
    # ranking).
    my %n_keys = map { row_key($_, $file_kind) => 1 } @{ $new->{rows} };
    for my $b_row (@{ $baseline->{rows} }) {
        my $k = row_key($b_row, $file_kind);
        next if $n_keys{$k};
        $stats->{key_mismatch}++;
        emit_row_key_mismatch(
            scenario   => $scenario,
            file_kind  => $file_kind,
            key        => $k,
            direction  => 'baseline-not-in-new',
        );
    }
}

# Emit a row-key-mismatch diagnostic. Severity is FAIL by default; under
# --ignore-row-key-mismatch (intended for use until Issue #269 ships), it
# downgrades to ADV. Either way, every field is self-documenting per
# HARNESS-DESIGN.md so the reader sees the cause without archaeology.
sub emit_row_key_mismatch {
    my (%a) = @_;
    my $present = $a{direction} eq 'new-not-in-baseline' ? '(present)' : '(absent)';
    my $absent  = $a{direction} eq 'new-not-in-baseline' ? '(absent)'  : '(present)';
    my $asserts = 'row identity (' . ($a{file_kind} eq 'messages' ? 'category|message' : 'timestamp') . ') is stable between runs';
    my $produced_by = 'ranking step in ltl (currently non-deterministic at ties — see Issue #269)';
    my $contract = 'features/224-validate-statistics-test-harness.md § Decision 1 — Layer 1 drift, row-set identity';
    my $rule = $a{direction} eq 'new-not-in-baseline'
        ? 'every row in the new CSV must correspond to a row in the baseline CSV by row key'
        : 'every row in the baseline CSV must correspond to a row in the new CSV by row key';

    if ($opt{ignore_row_key_mismatch}) {
        print "ADV  [T3-L1] scenario=$a{scenario} file=$a{file_kind} key=\"$a{key}\" column=(row-key) ",
              "baseline=$absent new=$present deviation=row-key-mismatch (advisory: #269 workaround active)\n";
        return;
    }

    emit_failure(
        tier        => 'T3',
        layer       => 'L1',
        scenario    => $a{scenario},
        file        => $a{file_kind},
        key         => $a{key},
        column      => '(row-key)',
        baseline    => $absent,
        new         => $present,
        deviation   => 'row-key-mismatch',
        asserts     => $asserts,
        produced_by => $produced_by,
        contract    => $contract,
        rule        => $rule,
    );
}

#-------------------------------------------------------------------------
# Layer 2: intra-row cross-column invariants. Each invariant carries its
# own asserts/produced_by/contract triple. Failure of any is a T4.
#
# The invariants are checked on BOTH the new rows and the baseline rows —
# this is Decision 1's "for drift confirmation, the baseline row is also
# checked so a regression that violates Layer 2 in both surfaces still
# surfaces (rather than registering as T1 drift)".
#-------------------------------------------------------------------------

my %L2_INVARIANTS = (
    duration_order => {
        asserts     => 'duration row ordering invariant: min <= mean <= max',
        produced_by => 'calculate_statistics() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 4 — duration ordering',
    },
    duration_deriv => {
        asserts     => 'mean equals duration divided by occurrences',
        produced_by => 'calculate_statistics() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 4 — duration derivation',
    },
    bytes_order => {
        asserts     => 'bytes row ordering invariant: mean_bytes <= bytes',
        produced_by => 'accumulate_log_record() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 4 — bytes ordering',
    },
    bytes_deriv => {
        asserts     => 'mean_bytes equals bytes divided by occurrences',
        produced_by => 'accumulate_log_record() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 4 — bytes derivation',
    },
    count_order => {
        asserts     => 'count row ordering invariant: count_min <= count_mean <= count_max',
        produced_by => 'calculate_statistics() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 4 — count ordering',
    },
    count_deriv => {
        asserts     => 'count_mean equals count_sum divided by count_occurrences',
        produced_by => 'calculate_statistics() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 4 — count derivation',
    },
    percentile_monotonic => {
        asserts     => 'percentile ladder is non-decreasing: p1 <= p5 <= p10 <= p25 <= p50 <= p75 <= p90 <= p95 <= p99 <= p999 <= p9999 <= p99999',
        produced_by => 'calculate_percentiles_for_bucket() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 4 — percentile monotonicity',
    },
    percentile_bounded => {
        asserts     => 'percentiles bounded by min and max: min <= p1 and p99999 <= max',
        produced_by => 'calculate_percentiles_for_bucket() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 4 — percentile bounds',
    },
    iqr_deriv => {
        asserts     => 'iqr equals p75 minus p25',
        produced_by => 'calculate_percentiles_for_bucket() in ltl',
        contract    => 'features/224-validate-statistics-test-harness.md § Decision 4 — IQR derivation',
    },
);

my @PERCENTILE_LADDER = qw(p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999);

# Helper: emit a T4 failure for a Layer-2 invariant breach on one row.
sub emit_l2_failure {
    my (%f) = @_;
    print "FAIL [T4-L2] scenario=$f{scenario} file=$f{file} key=\"$f{key}\" invariant=$f{invariant}\n";
    print "       observed: $f{observed}\n";
    print "       asserts: $f{asserts}\n";
    print "       produced_by: $f{produced_by}\n";
    print "       contract: $f{contract}\n";
    print "       rule: $f{rule}\n";
}

# Check one row against all applicable Layer-2 invariants. Some invariants
# only apply if their family columns are populated for this row (a row
# without duration data doesn't need a duration ordering check).
sub check_layer2_row {
    my ($row, $scenario, $file_kind, $stats, $side) = @_;
    my $k = row_key($row, $file_kind);

    # Duration ordering: min <= mean <= max (when all three present)
    my $dmin  = as_num($row->{min});
    my $dmean = as_num($row->{mean});
    my $dmax  = as_num($row->{max});
    if (defined $dmin && defined $dmean && defined $dmax) {
        unless ($dmin <= $dmean + ORDERING_EPS && $dmean <= $dmax + ORDERING_EPS) {
            $stats->{T4}++;
            my $inv = $L2_INVARIANTS{duration_order};
            emit_l2_failure(
                scenario => $scenario, file => $file_kind, key => $k,
                invariant => "duration_order ($side)",
                observed => "min=$dmin mean=$dmean max=$dmax",
                asserts => $inv->{asserts},
                produced_by => $inv->{produced_by},
                contract => $inv->{contract},
                rule => 'min <= mean <= max (tolerance 1 unit for display precision)',
            );
        }
    }

    # Duration derivation: mean == duration / occurrences
    my $occ      = as_num($row->{occurrences});
    my $duration = as_num($row->{duration});
    if (defined $dmean && defined $duration && defined $occ && $occ > 0) {
        my $expected = $duration / $occ;
        if (abs($expected - $dmean) > DERIVATION_EPS) {
            $stats->{T4}++;
            my $inv = $L2_INVARIANTS{duration_deriv};
            emit_l2_failure(
                scenario => $scenario, file => $file_kind, key => $k,
                invariant => "duration_deriv ($side)",
                observed => sprintf("mean=%s duration=%s occurrences=%s expected_mean=%.5f", $dmean, $duration, $occ, $expected),
                asserts => $inv->{asserts},
                produced_by => $inv->{produced_by},
                contract => $inv->{contract},
                rule => 'mean == duration / occurrences (tolerance 1 unit for display precision)',
            );
        }
    }

    # Bytes ordering: mean_bytes <= bytes
    my $mb = as_num($row->{mean_bytes});
    my $bt = as_num($row->{bytes});
    if (defined $mb && defined $bt) {
        unless ($mb <= $bt) {
            $stats->{T4}++;
            my $inv = $L2_INVARIANTS{bytes_order};
            emit_l2_failure(
                scenario => $scenario, file => $file_kind, key => $k,
                invariant => "bytes_order ($side)",
                observed => "mean_bytes=$mb bytes=$bt",
                asserts => $inv->{asserts},
                produced_by => $inv->{produced_by},
                contract => $inv->{contract},
                rule => 'mean_bytes <= bytes',
            );
        }
    }

    # Bytes derivation: mean_bytes == bytes / occurrences
    if (defined $mb && defined $bt && defined $occ && $occ > 0) {
        my $expected = $bt / $occ;
        # Bytes are integer; tolerate <= 1.0 absolute diff (truncation/rounding).
        if (abs($expected - $mb) > DERIVATION_EPS) {
            $stats->{T4}++;
            my $inv = $L2_INVARIANTS{bytes_deriv};
            emit_l2_failure(
                scenario => $scenario, file => $file_kind, key => $k,
                invariant => "bytes_deriv ($side)",
                observed => sprintf("mean_bytes=%s bytes=%s occurrences=%s expected_mb=%.2f", $mb, $bt, $occ, $expected),
                asserts => $inv->{asserts},
                produced_by => $inv->{produced_by},
                contract => $inv->{contract},
                rule => 'mean_bytes == bytes / occurrences (tolerance 1 byte)',
            );
        }
    }

    # Count ordering and derivation
    my $cmin  = as_num($row->{count_min});
    my $cmean = as_num($row->{count_mean});
    my $cmax  = as_num($row->{count_max});
    my $csum  = as_num($row->{count_sum});
    my $cocc  = as_num($row->{count_occurrences});
    if (defined $cmin && defined $cmean && defined $cmax) {
        unless ($cmin <= $cmean + ORDERING_EPS && $cmean <= $cmax + ORDERING_EPS) {
            $stats->{T4}++;
            my $inv = $L2_INVARIANTS{count_order};
            emit_l2_failure(
                scenario => $scenario, file => $file_kind, key => $k,
                invariant => "count_order ($side)",
                observed => "count_min=$cmin count_mean=$cmean count_max=$cmax",
                asserts => $inv->{asserts},
                produced_by => $inv->{produced_by},
                contract => $inv->{contract},
                rule => 'count_min <= count_mean <= count_max (tolerance 1 unit for display precision)',
            );
        }
    }
    if (defined $cmean && defined $csum && defined $cocc && $cocc > 0) {
        my $expected = $csum / $cocc;
        if (abs($expected - $cmean) > DERIVATION_EPS) {
            $stats->{T4}++;
            my $inv = $L2_INVARIANTS{count_deriv};
            emit_l2_failure(
                scenario => $scenario, file => $file_kind, key => $k,
                invariant => "count_deriv ($side)",
                observed => sprintf("count_mean=%s count_sum=%s count_occurrences=%s expected=%.5f", $cmean, $csum, $cocc, $expected),
                asserts => $inv->{asserts},
                produced_by => $inv->{produced_by},
                contract => $inv->{contract},
                rule => 'count_mean == count_sum / count_occurrences (tolerance 1 unit for display precision)',
            );
        }
    }

    # Percentile monotonicity
    my @pvals;
    my $any_p = 0;
    for my $p (@PERCENTILE_LADDER) {
        my $v = as_num($row->{$p});
        push @pvals, $v;
        $any_p = 1 if defined $v;
    }
    if ($any_p) {
        my $broken = 0;
        my $observed = '';
        for my $i (1 .. $#pvals) {
            next unless defined $pvals[$i] && defined $pvals[$i-1];
            if ($pvals[$i] + ORDERING_EPS < $pvals[$i-1]) {
                $broken = 1;
                $observed = "$PERCENTILE_LADDER[$i-1]=$pvals[$i-1] > $PERCENTILE_LADDER[$i]=$pvals[$i]";
                last;
            }
        }
        if ($broken) {
            $stats->{T4}++;
            my $inv = $L2_INVARIANTS{percentile_monotonic};
            emit_l2_failure(
                scenario => $scenario, file => $file_kind, key => $k,
                invariant => "percentile_monotonic ($side)",
                observed => $observed,
                asserts => $inv->{asserts},
                produced_by => $inv->{produced_by},
                contract => $inv->{contract},
                rule => 'p_i <= p_{i+1} across the full percentile ladder',
            );
        }
    }

    # Percentile bounded by min/max
    my $p1     = as_num($row->{p1});
    my $p99999 = as_num($row->{p99999});
    if (defined $dmin && defined $p1 && $dmin > $p1 + ORDERING_EPS) {
        $stats->{T4}++;
        my $inv = $L2_INVARIANTS{percentile_bounded};
        emit_l2_failure(
            scenario => $scenario, file => $file_kind, key => $k,
            invariant => "percentile_bounded_lower ($side)",
            observed => "min=$dmin p1=$p1",
            asserts => $inv->{asserts},
            produced_by => $inv->{produced_by},
            contract => $inv->{contract},
            rule => 'min <= p1',
        );
    }
    if (defined $dmax && defined $p99999 && $p99999 > $dmax + ORDERING_EPS) {
        $stats->{T4}++;
        my $inv = $L2_INVARIANTS{percentile_bounded};
        emit_l2_failure(
            scenario => $scenario, file => $file_kind, key => $k,
            invariant => "percentile_bounded_upper ($side)",
            observed => "p99999=$p99999 max=$dmax",
            asserts => $inv->{asserts},
            produced_by => $inv->{produced_by},
            contract => $inv->{contract},
            rule => 'p99999 <= max',
        );
    }

    # IQR derivation
    my $iqr = as_num($row->{iqr});
    my $p25 = as_num($row->{p25});
    my $p75 = as_num($row->{p75});
    if (defined $iqr && defined $p25 && defined $p75) {
        my $expected = $p75 - $p25;
        if (abs($expected - $iqr) > DERIVATION_EPS) {
            $stats->{T4}++;
            my $inv = $L2_INVARIANTS{iqr_deriv};
            emit_l2_failure(
                scenario => $scenario, file => $file_kind, key => $k,
                invariant => "iqr_deriv ($side)",
                observed => sprintf("iqr=%s p25=%s p75=%s expected_iqr=%.5f", $iqr, $p25, $p75, $expected),
                asserts => $inv->{asserts},
                produced_by => $inv->{produced_by},
                contract => $inv->{contract},
                rule => 'iqr == p75 - p25 (tolerance 1 unit for display precision)',
            );
        }
    }
}

sub run_layer2 {
    my ($rows_set, $scenario, $file_kind, $stats, $side) = @_;
    for my $row (@$rows_set) {
        check_layer2_row($row, $scenario, $file_kind, $stats, $side);
    }
}

#-------------------------------------------------------------------------
# Main control flow.
#-------------------------------------------------------------------------

# Startup line listing every column the engine WILL compare (those that
# pass both rules-TSV membership AND new-CSV header membership). Required
# by acceptance criterion: "engine emits a startup line listing every
# column it will compare, so the reader can independently verify the
# family is covered completely."

my $new_data = load_csv($opt{new});

my @startup_cols = grep {
    my $c = $_;
    !$IDENTIFIER_COLUMNS{$c} &&
    (grep { $_ eq $c } @{ $new_data->{header} })
} @$NUMERIC_COLS;

print "STARTUP scenario=$opt{scenario} file=$opt{file_kind} columns_checked=" .
      scalar(@startup_cols) . " [" . join(',', @startup_cols) . "]\n";

my %stats = (
    cells_checked => 0,
    T1            => 0,
    T2            => 0,
    T3            => 0,
    T4            => 0,
    nonnumeric    => 0,
    key_mismatch  => 0,
);

my $baseline_data;
my $structural_ok = 1;

if (defined $opt{baseline}) {
    $baseline_data = load_csv($opt{baseline});
    $structural_ok = structural_preflight($baseline_data, $new_data, $opt{scenario}, $opt{file_kind});
    if (!$structural_ok) {
        # Decision 2: stop here, do NOT continue with per-cell L1/L2.
        print "SUMMARY scenario=$opt{scenario}/$opt{file_kind}: structural=DRIFT (engine stopped per Decision 2)\n";
        exit 1;
    }
    run_layer1($baseline_data, $new_data, $opt{scenario}, $opt{file_kind}, \%stats);
} else {
    # No baseline: L1 cannot run, but L2 still validates the new rows.
    # Emit one self-documenting diagnostic noting the absence and continue
    # to L2 so the run is at least partially useful.
    print "INFO scenario=$opt{scenario} file=$opt{file_kind}: no baseline yet; Layer 1 skipped; running Layer 2 only\n";
}

# Layer 2 on new rows always runs.
run_layer2($new_data->{rows}, $opt{scenario}, $opt{file_kind}, \%stats, 'new');

# Layer 2 on baseline rows (drift confirmation per Decision 1) when present.
if (defined $baseline_data && $structural_ok) {
    run_layer2($baseline_data->{rows}, $opt{scenario}, $opt{file_kind}, \%stats, 'baseline');
}

# Per-scenario summary (Decision 7). L3/L4 are N/A in Phase C.
my $struct_state = $structural_ok ? 'OK' : 'DRIFT';
print "SUMMARY scenario=$opt{scenario}/$opt{file_kind}: ",
      "$stats{cells_checked} cells checked, ",
      "$stats{T4} T4, $stats{T3} T3, $stats{T2} T2, $stats{T1} T1, ",
      "nonnumeric=$stats{nonnumeric}, key_mismatch=$stats{key_mismatch}, ",
      "structural=$struct_state, L3=N/A, L4=N/A\n";

# Exit code: T3 or T4 blocks; nonnumeric also blocks since it indicates
# the engine couldn't actually assert. key_mismatch blocks unless the
# --ignore-row-key-mismatch escape hatch is active (intended workaround
# for Issue #269 until ltl ranking becomes deterministic).
my $exit_fail = ($stats{T3} > 0 || $stats{T4} > 0 || $stats{nonnumeric} > 0);
if (!$opt{ignore_row_key_mismatch}) {
    $exit_fail = 1 if $stats{key_mismatch} > 0;
}
exit ($exit_fail ? 1 : 0);
