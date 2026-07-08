#!/usr/bin/env perl
#
# CSV-output integrity validator (Issue #223)
#
# Categorical, pass/fail validation of -o CSV output: column structure,
# population, group consistency, data-type correctness, fixed-decimal rules,
# and — when a scenario declares an expected-categories file — categorical
# content: which MESSAGES rows land in category `highlight` vs `plain`, and
# which are absent from the output entirely (dropped by a hard filter).
#
# Sibling to validate-statistics.sh (#224), which handles numeric drift.
# This validator never checks numeric drift — only structural/type/categorical
# integrity.
#
# Usage:
#   validate-csv-output.pl --rules <rules.tsv> --csv <file.csv>
#                          --scenario <name> --file-kind messages|stats
#                          --expected-families <comma-list>
#                          [--expected-categories <expected.tsv>]
#
# Expected-categories TSV (messages kind only): header `message_match\texpected`,
# one row per assertion. `message_match` is a fixed substring matched against
# the message column; `expected` is `highlight`, `plain`, or `absent` (no row
# may match). A directive row `@no_highlight_rows` asserts the file contains
# no highlight-category rows at all.
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
    'profile-mode=s'       => \$opt{profile_mode},   # optional: '' = none; else a --profile mode
    'expected-categories=s' => \$opt{expected_categories},  # optional: messages-kind categorical content assertions
) or die "bad args\n";

for my $k (qw(rules csv scenario file_kind expected_families v_precision)) {
    die "missing --$k\n" unless defined $opt{$k};
}
$opt{profile_mode} //= '';

my %active_family = map { $_ => 1 } split /,/, $opt{expected_families};

# Parse the -V csv-output / precision block — locked observability surface
# per #268. Field-name keys without source-annotation suffix.
my %vp = load_v_precision($opt{v_precision});

my @rules = load_rules($opt{rules});

my @expected_categories;
if (defined $opt{expected_categories}) {
    die "expected-categories is only valid for --file-kind messages\n"
        unless $opt{file_kind} eq 'messages';
    @expected_categories = load_expected_categories($opt{expected_categories});
    die "expected-categories file has no assertions: $opt{expected_categories}\n"
        unless @expected_categories;
}

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
my @message_rows;  # (row, category, message) collected for expected-categories checks
my $row_num = 1;  # header is row 1; first data row is 2
while (my $row = $csv->getline($fh)) {
    $row_num++;

    if (@expected_categories
        && exists $col_index{category} && exists $col_index{message}
        && scalar(@$row) == scalar(@$header_row)) {
        push @message_rows, {
            row      => $row_num,
            category => $row->[$col_index{category}] // '',
            message  => $row->[$col_index{message}] // '',
        };
    }

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

# --- Phase 3: expected-categories checks (messages kind, opt-in per scenario) ---
if (@expected_categories) {
    for my $exp (@expected_categories) {
        $checks++;
        $fails += check_expected_category($exp, \@message_rows);
    }
}

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
        if ($opt{profile_mode} ne '') {
            # Under --profile the timestamp is a folded position, not a calendar
            # date: week/workweek modes prefix the weekday on EVERY row (the CSV
            # carries the full label, not the terminal's once-per-day blank), so
            # the column reads coherently with the timeline. day/workday modes
            # render time-of-day only.
            my $is_week = $opt{profile_mode} =~ /^(week|workweek)/ ? 1 : 0;
            my $ok = $is_week
                ? $val =~ /^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun) \d{2}:\d{2}(:\d{2}(\.\d+)?)?$/
                : $val =~ /^\d{2}:\d{2}(:\d{2}(\.\d+)?)?$/;
            if (!$ok) {
                emit_fail({
                    scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                    column => $col_name,
                    asserts => "under --profile $opt{profile_mode}, column '$col_name' must be a folded position"
                             . ($is_week ? " carrying the weekday on every row (Wkd HH:MM)" : " in time-of-day form (HH:MM)"),
                    produced_by => producer($opt{file_kind}) . ' under --profile (print_bar_graph builds $bucket_time_str; the CSV keeps the full folded label, terminal-only weekday blanking excluded)',
                    contract => 'Issue #223 § Data-type correctness + Issue #256 § CSV coherence (folded timestamp on every row)',
                    expected => $is_week ? 'Wkd HH:MM[:SS[.fff]]' : 'HH:MM[:SS[.fff]]',
                    actual => $val,
                    rule => "type=timestamp,profile=$opt{profile_mode}",
                });
                $f++;
            }
        }
        elsif ($val !~ /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(:\d{2}(\.\d+)?)?/) {
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

sub load_expected_categories {
    my ($path) = @_;
    open my $fh, '<', $path or die "open expected-categories $path: $!";
    my $header = <$fh>;
    my @exps;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*$/;
        next if $line =~ /^#/;
        if ($line =~ /^\@no_highlight_rows\s*$/) {
            push @exps, { directive => 'no_highlight_rows' };
            next;
        }
        my ($match, $expected) = split /\t/, $line, -1;
        die "bad expected-categories row (need message_match<TAB>expected): $line\n"
            unless defined $match && $match ne ''
                && defined $expected && $expected =~ /^(highlight|plain|absent)$/;
        push @exps, { match => $match, expected => $expected };
    }
    close $fh;
    return @exps;
}

sub check_expected_category {
    my ($exp, $rows) = @_;

    if (($exp->{directive} // '') eq 'no_highlight_rows') {
        my @hl = grep { $_->{category} eq 'highlight' } @$rows;
        return 0 unless @hl;
        emit_fail({
            scenario => $opt{scenario}, file => $opt{file_kind}, row => $hl[0]{row},
            column => 'category',
            asserts => 'no MESSAGES row may carry category=highlight — the highlight criterion can never be satisfied in this scenario (metric absent from the log format)',
            produced_by => 'read_and_process_logs() highlight tag point in ltl',
            contract => 'features/312-numeric-criteria-highlight-selection.md § Decisions — a record missing the metric never satisfies a criterion on it',
            expected => '0 highlight rows',
            actual => scalar(@hl) . ' highlight rows (first: ' . $hl[0]{message} . ')',
            rule => '@no_highlight_rows',
        });
        return 1;
    }

    my @matched = grep { index($_->{message}, $exp->{match}) >= 0 } @$rows;

    if ($exp->{expected} eq 'absent') {
        return 0 unless @matched;
        emit_fail({
            scenario => $opt{scenario}, file => $opt{file_kind}, row => $matched[0]{row},
            column => 'message',
            asserts => "no MESSAGES row may match '$exp->{match}' — the record is outside the hard-filter range (or lacks the filtered metric) and must be dropped",
            produced_by => 'read_and_process_logs() numeric filter drop guards in ltl',
            contract => 'features/312-numeric-criteria-highlight-selection.md § Decisions — closed-interval filter bounds (boundary normalization)',
            expected => 'no matching row',
            actual => scalar(@matched) . ' matching rows (first: ' . $matched[0]{message} . ')',
            rule => "expected=absent match='$exp->{match}'",
        });
        return 1;
    }

    # expected highlight|plain: the anchor must exist (zero matches is a hard
    # failure per HARNESS-DESIGN.md), and every matching row must carry the
    # expected category.
    if (!@matched) {
        emit_fail({
            scenario => $opt{scenario}, file => $opt{file_kind}, row => '-',
            column => 'message',
            asserts => "a MESSAGES row matching '$exp->{match}' must exist with category=$exp->{expected}",
            produced_by => 'print_message_summary() MESSAGES CSV emission in ltl',
            contract => 'tests/HARNESS-DESIGN.md § Harnesses must fail on missing anchors',
            expected => "row matching '$exp->{match}'",
            actual => 'no matching row',
            rule => "expected=$exp->{expected} match='$exp->{match}'",
        });
        return 1;
    }
    my @wrong = grep { $_->{category} ne $exp->{expected} } @matched;
    return 0 unless @wrong;
    emit_fail({
        scenario => $opt{scenario}, file => $opt{file_kind}, row => $wrong[0]{row},
        column => 'category',
        asserts => "every MESSAGES row matching '$exp->{match}' must carry category=$exp->{expected} under this scenario's highlight/filter options",
        produced_by => 'read_and_process_logs() highlight tag point in ltl',
        contract => 'features/312-numeric-criteria-highlight-selection.md § Decisions — inclusive bands, AND across metrics and with the regex highlight, undefined metric never highlights',
        expected => $exp->{expected},
        actual => $wrong[0]{category} . " (row $wrong[0]{row}: $wrong[0]{message})",
        rule => "expected=$exp->{expected} match='$exp->{match}'",
    });
    return 1;
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
