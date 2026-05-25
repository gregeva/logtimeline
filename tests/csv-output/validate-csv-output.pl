#!/usr/bin/env perl
#
# CSV-output integrity validator (Issue #223)
#
# Categorical, pass/fail validation of -o CSV output: column structure,
# population, group consistency, data-type correctness, fixed-decimal rules.
#
# Sibling to validate-percentile-values.sh (#224), which handles numeric drift.
# This validator never checks numeric drift — only structural/type integrity.
#
# Usage:
#   validate-csv-output.pl --rules <rules.tsv> --csv <file.csv>
#                          --scenario <name> --file-kind messages|stats
#                          --expected-families <comma-list>
#
# Exit 0 on success, 1 on any FAIL.

use strict;
use warnings;
use Text::CSV;
use Getopt::Long;

my %opt;
GetOptions(
    'rules=s'              => \$opt{rules},
    'csv=s'                => \$opt{csv},
    'scenario=s'           => \$opt{scenario},
    'file-kind=s'          => \$opt{file_kind},
    'expected-families=s'  => \$opt{expected_families},
    'v-precision=s'        => \$opt{v_precision},
) or die "bad args\n";

for my $k (qw(rules csv scenario file_kind expected_families v_precision)) {
    die "missing --$k\n" unless defined $opt{$k};
}

my %active_family = map { $_ => 1 } split /,/, $opt{expected_families};

# Parse the -V csv-output / precision block — locked observability surface
# per #268. Field-name keys without source-annotation suffix.
my %vp = load_v_precision($opt{v_precision});

my @rules = load_rules($opt{rules});

my $csv = Text::CSV->new({ binary => 1 });
open my $fh, '<', $opt{csv} or die "open $opt{csv}: $!";
my $header_row = $csv->getline($fh);
die "empty CSV: $opt{csv}\n" unless $header_row;

my $fails = 0;
my $checks = 0;

# --- Phase 0: observability surface (#268 test class A + F) ---
# Field presence is asserted on the messages pass only; the surface is a
# run-level property, not a per-file one.
if ($opt{file_kind} eq 'messages') {
    $fails += check_observability_surface(\%vp);
}

# --- Phase 1: column structure ---
$fails += check_column_structure($header_row, \@rules);

my %rule_by_name = map { $_->{column} => $_ } @rules;
my %col_index;
for my $i (0 .. $#$header_row) {
    $col_index{$header_row->[$i]} = $i;
}

# --- Phase 2: per-row checks ---
my $row_num = 1;  # header is row 1; first data row is 2
while (my $row = $csv->getline($fh)) {
    $row_num++;

    # alignment: row column count must match header
    if (scalar(@$row) != scalar(@$header_row)) {
        emit_fail({
            scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
            column => '(row)',
            asserts => 'every data row has the same column count as the header',
            produced_by => 'Text::CSV row emission in ltl',
            contract => 'Issue #223 § Column structure',
            expected => scalar(@$header_row),
            actual => scalar(@$row),
            rule => 'row column count == header column count',
        });
        $fails++;
        next;  # alignment broken, skip cell-level checks for this row
    }

    # per-cell type + decimal checks
    for my $col_name (keys %col_index) {
        my $rule = $rule_by_name{$col_name};
        next unless $rule;  # unknown column already flagged in structure phase
        my $idx = $col_index{$col_name};
        my $val = $row->[$idx];
        $val = '' unless defined $val;

        # population check
        if ($val eq '') {
            if ($rule->{required} eq 'yes') {
                emit_fail({
                    scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                    column => $col_name,
                    asserts => "column '$col_name' must be populated in every row",
                    produced_by => producer($opt{file_kind}),
                    contract => 'Issue #223 § Population correctness',
                    expected => 'non-empty',
                    actual => 'empty',
                    rule => "required=yes",
                });
                $fails++;
            }
            next;  # empty cells get no further checks
        }

        # type + decimal checks on non-empty cells
        $fails += check_type_and_decimals($rule, $val, $col_name, $row_num);
        $checks++;
    }

    # --- Storage-precision invariants (#268 test class D) ---
    # Asserted under -cp full because default/N modes round emit and would
    # mask sub-ceiling drift. The invariants describe what storage must
    # uphold; full-mode emit exposes the stored values directly.
    if ($vp{precision_mode} eq 'full') {
        $fails += check_storage_precision_invariants($row, \%col_index, $row_num);
    }

    # group-consistency check: for each active family, all conditional columns
    # in this row must be uniformly populated or uniformly empty.
    for my $family (keys %active_family) {
        my @cols_in_family = grep {
            $_->{family} eq $family
            && $_->{required} =~ /^conditional:/
            && exists $col_index{$_->{column}}
        } @rules;
        next unless @cols_in_family;

        my (@populated, @empty);
        for my $r (@cols_in_family) {
            my $v = $row->[$col_index{$r->{column}}];
            if (defined $v && $v ne '') {
                push @populated, $r->{column};
            } else {
                push @empty, $r->{column};
            }
        }

        if (@populated && @empty) {
            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                column => "(family=$family)",
                asserts => "if any column in family '$family' is populated, all conditional columns in that family must be populated in the same row",
                produced_by => producer($opt{file_kind}),
                contract => 'Issue #223 § Functional group consistency',
                expected => 'all populated or all empty',
                actual => sprintf('populated=[%s] empty=[%s]', join(',', @populated), join(',', @empty)),
                rule => "family group consistency",
            });
            $fails++;
        }
    }
}
close $fh;

# --- Summary ---
my $status = $fails == 0 ? 'PASS' : 'FAIL';
printf STDERR "%s scenario=%s file=%s rows=%d cells_checked=%d fails=%d\n",
    $status, $opt{scenario}, $opt{file_kind}, $row_num - 1, $checks, $fails;

exit($fails == 0 ? 0 : 1);

# ---- subs ----

sub load_rules {
    my ($path) = @_;
    open my $fh, '<', $path or die "open rules $path: $!";
    my $header = <$fh>;
    chomp $header;
    my @cols = split /\t/, $header;
    my @rows;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*$/;
        next if $line =~ /^#/;
        my @vals = split /\t/, $line, -1;
        my %r;
        @r{@cols} = @vals;
        push @rows, \%r;
    }
    close $fh;
    return @rows;
}

sub check_column_structure {
    my ($header, $rules) = @_;
    my $fails = 0;
    my %header_set = map { $_ => 1 } @$header;

    # Fixed-position columns must appear at the expected position
    for my $r (@$rules) {
        next if $r->{position} eq '*';
        my $expected_idx = $r->{position} - 1;
        if ($expected_idx >= scalar(@$header)) {
            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => 1,
                column => $r->{column},
                asserts => "column '$r->{column}' must appear at position $r->{position}",
                produced_by => producer($opt{file_kind}),
                contract => 'Issue #223 § Column structure',
                expected => "position $r->{position}",
                actual => "header has only " . scalar(@$header) . " columns",
                rule => "fixed-position column",
            });
            $fails++;
            next;
        }
        if ($header->[$expected_idx] ne $r->{column}) {
            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => 1,
                column => $r->{column},
                asserts => "column '$r->{column}' must appear at position $r->{position}",
                produced_by => producer($opt{file_kind}),
                contract => 'Issue #223 § Column structure',
                expected => $r->{column},
                actual => $header->[$expected_idx],
                rule => "fixed-position column",
            });
            $fails++;
        }
    }

    # Dynamic-position columns: if their family is active, they must appear
    # somewhere in the header.
    for my $r (@$rules) {
        next unless $r->{position} eq '*';
        my $family = $r->{family};
        next unless $active_family{$family};
        next if $r->{required} eq 'no';
        # 'conditional:X' is checked at row level (populated when X active),
        # but at structural level we only require the column to *exist* if
        # the family is declared active for this scenario.
        if (!$header_set{$r->{column}}) {
            # For dynamic-position with conditional:<other-family>, the column
            # is optional unless the *other* family is active.
            my $cond_family = $family;
            if ($r->{required} =~ /^conditional:(.+)$/) {
                $cond_family = $1;
            }
            next unless $active_family{$cond_family};

            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => 1,
                column => $r->{column},
                asserts => "column '$r->{column}' must appear in the header when family '$cond_family' is active",
                produced_by => producer($opt{file_kind}),
                contract => 'Issue #223 § Column structure',
                expected => "present in header",
                actual => "missing",
                rule => "dynamic column for active family",
            });
            $fails++;
        }
    }

    return $fails;
}

sub check_type_and_decimals {
    my ($rule, $val, $col_name, $row_num) = @_;
    my $f = 0;
    my $type = $rule->{type};

    if ($type eq 'int') {
        if ($val !~ /^-?\d+$/) {
            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                column => $col_name,
                asserts => "column '$col_name' must contain an integer",
                produced_by => producer($opt{file_kind}),
                contract => 'Issue #223 § Data-type correctness',
                expected => 'integer (-?\\d+)',
                actual => $val,
                rule => "type=int",
            });
            $f++;
        }
    }
    elsif ($type eq 'float') {
        if ($val !~ /^-?\d+(\.\d+)?$/ && $val !~ /^-?\d+([eE][+-]?\d+)?$/) {
            # Reject NaN, Inf, embedded strings — accept plain decimals or
            # plain integers (a float column may legitimately produce a whole-
            # number value).
            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                column => $col_name,
                asserts => "column '$col_name' must contain a numeric value (no NaN/Inf/strings)",
                produced_by => producer($opt{file_kind}),
                contract => 'Issue #223 § Data-type correctness',
                expected => 'numeric',
                actual => $val,
                rule => "type=float",
            });
            $f++;
        }
        # decimal-count check, honoring the --csv-precision mode (#268).
        # The effective ceiling is sourced from the -V csv-output / precision
        # block, not the rules TSV literal. Full mode bypasses the check.
        my $ceiling = effective_max_decimals($rule, $col_name);
        if ($val =~ /\.(\d+)$/ && defined $ceiling) {
            my $decimals = length($1);
            if ($decimals > $ceiling) {
                emit_fail({
                    scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                    column => $col_name,
                    asserts => "column '$col_name' must not exceed effective decimal ceiling=$ceiling (resolved from -V csv-output / precision)",
                    produced_by => producer($opt{file_kind}),
                    contract => 'Issue #223 § Fixed-decimal rule; Issue #268 § Precision-mode ceiling',
                    expected => "<= $ceiling decimal places",
                    actual => "$decimals decimal places ($val)",
                    rule => "effective_ceiling=$ceiling (precision_mode=$vp{precision_mode})",
                });
                $f++;
            }
        }
    }
    elsif ($type eq 'nice') {
        # Nice columns are human-readable strings; they must NOT be bare
        # numbers, and must contain a unit token.
        if ($val =~ /^-?\d+(\.\d+)?$/) {
            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                column => $col_name,
                asserts => "column '$col_name' must be human-readable (string + unit), not a bare number",
                produced_by => producer($opt{file_kind}),
                contract => 'Issue #223 § Data-type correctness',
                expected => 'string with unit (e.g., "1.5 MiB", "230 ms")',
                actual => $val,
                rule => "type=nice",
            });
            $f++;
        }
        elsif ($val !~ /[A-Za-z]/) {
            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                column => $col_name,
                asserts => "column '$col_name' must contain a unit token (alphabetic suffix)",
                produced_by => producer($opt{file_kind}),
                contract => 'Issue #223 § Data-type correctness',
                expected => 'numeric value + unit token',
                actual => $val,
                rule => "type=nice",
            });
            $f++;
        }
    }
    elsif ($type eq 'timestamp') {
        if ($val !~ /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(:\d{2}(\.\d+)?)?/) {
            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                column => $col_name,
                asserts => "column '$col_name' must be an ISO-style timestamp",
                produced_by => producer($opt{file_kind}),
                contract => 'Issue #223 § Data-type correctness',
                expected => 'YYYY-MM-DD HH:MM[:SS[.fff]]',
                actual => $val,
                rule => "type=timestamp",
            });
            $f++;
        }
    }
    elsif ($type =~ /^enum:(.+)$/) {
        my %allowed = map { $_ => 1 } split /,/, $1;
        if (!$allowed{$val}) {
            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                column => $col_name,
                asserts => "column '$col_name' must be one of: " . join(',', sort keys %allowed),
                produced_by => producer($opt{file_kind}),
                contract => 'Issue #223 § Data-type correctness',
                expected => join('|', sort keys %allowed),
                actual => $val,
                rule => "type=$type",
            });
            $f++;
        }
    }
    elsif ($type eq 'string') {
        # any non-empty string is fine; population already checked
    }
    else {
        die "unknown type '$type' for column '$col_name'\n";
    }

    return $f;
}

sub producer {
    my ($kind) = @_;
    return $kind eq 'messages' ? 'print_message_summary' : 'print_bar_graph';
}

sub emit_fail {
    my ($f) = @_;
    # Multi-line indented form per tests/HARNESS-DESIGN.md § Self-documenting
    # assertions. Each field is quoted uniformly via qquote() so embedded
    # parentheses or whitespace cannot confuse a reader.
    printf "FAIL  scenario=%s file=%s row=%s column=%s\n",
        $f->{scenario}, $f->{file}, $f->{row}, qquote($f->{column});
    printf "        asserts:     %s\n", qquote($f->{asserts});
    printf "        produced_by: %s\n", qquote($f->{produced_by});
    printf "        contract:    %s\n", qquote($f->{contract});
    printf "        expected:    %s\n", qquote($f->{expected});
    printf "        actual:      %s\n", qquote($f->{actual});
    printf "        rule:        %s\n", qquote($f->{rule});
}

sub qquote {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/"/\\"/g;
    return qq("$s");
}

# Issue #268: parse the -V csv-output / precision sub-section block.
# Returns a hash keyed by field name. Source annotations '(<source>)'
# are stripped to leave a bare value the validator can compare.
sub load_v_precision {
    my ($path) = @_;
    open my $fh, '<', $path or die "open v-precision $path: $!";
    my %h;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*$/;
        next unless $line =~ /^(\w+):\s*(.+?)(?:\s*\(.*\))?\s*$/;
        $h{$1} = $2;
    }
    close $fh;
    return %h;
}

# Issue #268 test class A + F. Assert the locked surface fields are
# present and that enum values are within their locked sets. precision_mode
# values are 'default', 'full', or a non-negative integer string; the
# duration unit is one of ns/us/ms/s/n/a; max_decimals_ceiling is 5, 'n/a',
# or a non-negative integer.
sub check_observability_surface {
    my ($vp) = @_;
    my $f = 0;
    my @locked_fields = qw(
        precision_mode
        duration_unit_resolved
        decimals_meta
        decimals_count
        decimals_duration
        decimals_percentile
        decimals_shape
        decimals_bytes
        decimals_level
        max_decimals_ceiling
    );

    for my $field (@locked_fields) {
        next if exists $vp->{$field};
        emit_fail({
            scenario => $opt{scenario}, file => $opt{file_kind}, row => 0,
            column => "(v-csv-output/$field)",
            asserts => "the locked -V csv-output / precision surface must include field '$field'",
            produced_by => 'emit_csv_output_verbose() in ltl',
            contract => 'Issue #268 § locked observability surface',
            expected => "$field: <value>",
            actual => 'field missing from -V csv-output / precision block',
            rule => 'locked field presence',
        });
        $f++;
    }
    return $f if $f;  # short-circuit further enum checks if fields missing

    if ($vp->{precision_mode} !~ /^(default|full|\d+)$/) {
        emit_fail({
            scenario => $opt{scenario}, file => $opt{file_kind}, row => 0,
            column => '(v-csv-output/precision_mode)',
            asserts => "precision_mode must be 'default', 'full', or a non-negative integer",
            produced_by => 'emit_csv_output_verbose() in ltl',
            contract => 'Issue #268 § precision_mode enum',
            expected => "default | full | integer",
            actual => $vp->{precision_mode},
            rule => 'precision_mode enum',
        });
        $f++;
    }

    if ($vp->{duration_unit_resolved} !~ /^(ns|us|ms|s|n\/a)$/) {
        emit_fail({
            scenario => $opt{scenario}, file => $opt{file_kind}, row => 0,
            column => '(v-csv-output/duration_unit_resolved)',
            asserts => "duration_unit_resolved must be one of ns, us, ms, s, n/a",
            produced_by => 'emit_csv_output_verbose() in ltl',
            contract => 'Issue #268 § duration_unit_resolved enum',
            expected => "ns | us | ms | s | n/a",
            actual => $vp->{duration_unit_resolved},
            rule => 'duration_unit_resolved enum',
        });
        $f++;
    }

    if ($vp->{max_decimals_ceiling} !~ /^(5|n\/a|\d+)$/) {
        emit_fail({
            scenario => $opt{scenario}, file => $opt{file_kind}, row => 0,
            column => '(v-csv-output/max_decimals_ceiling)',
            asserts => "max_decimals_ceiling must be 5, n/a, or a non-negative integer",
            produced_by => 'emit_csv_output_verbose() in ltl',
            contract => 'Issue #268 § max_decimals_ceiling enum',
            expected => "5 | n/a | integer",
            actual => $vp->{max_decimals_ceiling},
            rule => 'max_decimals_ceiling enum',
        });
        $f++;
    }

    return $f;
}

# Issue #268: compute the effective max_decimals ceiling for a column.
# The ceiling comes from -V csv-output / precision (max_decimals_ceiling),
# not the rules TSV literal — that lets sub-ms duration units lift the
# ceiling above 5 without amending the rules TSV per run.
# In full mode the check is suppressed (returns undef). In N mode the
# ceiling is N. In default mode it's the value ltl resolved.
sub effective_max_decimals {
    my ($rule, $col_name) = @_;
    return undef if $vp{precision_mode} eq 'full';
    return undef if $rule->{max_decimals} eq 'n/a';
    my $ceiling = $vp{max_decimals_ceiling};
    return undef unless defined $ceiling && $ceiling =~ /^\d+$/;
    return $ceiling;
}

# Issue #268 test class D: storage-precision invariants. Asserted in full
# mode because that mode exposes stored values directly. Tolerance is
# float-quantization scale (1e-9 relative).
sub check_storage_precision_invariants {
    my ($row, $col_index, $row_num) = @_;
    my $f = 0;
    my $eps = 1e-9;

    my $get = sub {
        my ($name) = @_;
        return undef unless exists $col_index->{$name};
        my $v = $row->[$col_index->{$name}];
        return undef unless defined $v && $v ne '';
        return $v;
    };

    # D1: mean == duration / occurrences (when duration data is present)
    my $mean        = $get->('mean');
    my $duration    = $get->('duration');
    my $occurrences = $get->('occurrences');
    if (defined $mean && defined $duration && defined $occurrences && $occurrences > 0) {
        my $expected = $duration / $occurrences;
        my $delta = abs($mean - $expected);
        my $tolerance = $eps * (abs($expected) > 1 ? abs($expected) : 1);
        if ($delta > $tolerance) {
            emit_fail({
                scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                column => '(invariant: mean == duration / occurrences)',
                asserts => 'mean must equal duration / occurrences within float-quantization tolerance',
                produced_by => 'calculate_statistics() in ltl',
                contract => 'Issue #268 § storage-precision invariants',
                expected => sprintf('%.15g (= %s / %s)', $expected, $duration, $occurrences),
                actual => sprintf('%.15g (delta %.3e, tolerance %.3e)', $mean, $delta, $tolerance),
                rule => 'mean derivation',
            });
            $f++;
        }
    }

    # D2: min <= p1 (when both are present)
    my $min = $get->('min');
    my $p1  = $get->('p1');
    if (defined $min && defined $p1 && $min > $p1) {
        emit_fail({
            scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
            column => '(invariant: min <= p1)',
            asserts => 'min must not exceed p1; both come from the same sorted sample array',
            produced_by => 'calculate_statistics() in ltl',
            contract => 'Issue #268 § storage-precision invariants',
            expected => "min ($min) <= p1 ($p1)",
            actual => "min ($min) > p1 ($p1)",
            rule => 'percentile ordering',
        });
        $f++;
    }

    return $f;
}
