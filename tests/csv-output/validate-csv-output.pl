#!/usr/bin/env perl
#
# CSV-output integrity validator (Issue #223)
#
# Categorical, pass/fail validation of -o CSV output: column structure,
# population, group consistency, data-type correctness, fixed-decimal rules.
#
# Sibling to validate-statistics.sh (#224), which handles numeric drift.
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
) or die "bad args\n";

for my $k (qw(rules csv scenario file_kind expected_families)) {
    die "missing --$k\n" unless defined $opt{$k};
}

my %active_family = map { $_ => 1 } split /,/, $opt{expected_families};

my @rules = load_rules($opt{rules});

my $csv = Text::CSV->new({ binary => 1 });
open my $fh, '<', $opt{csv} or die "open $opt{csv}: $!";
my $header_row = $csv->getline($fh);
die "empty CSV: $opt{csv}\n" unless $header_row;

my $fails = 0;
my $checks = 0;

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
        # decimal-count check
        if ($val =~ /\.(\d+)$/ && $rule->{max_decimals} ne 'n/a') {
            my $decimals = length($1);
            if ($decimals > $rule->{max_decimals}) {
                emit_fail({
                    scenario => $opt{scenario}, file => $opt{file_kind}, row => $row_num,
                    column => $col_name,
                    asserts => "column '$col_name' must not exceed max_decimals=$rule->{max_decimals}",
                    produced_by => producer($opt{file_kind}),
                    contract => 'Issue #223 § Fixed-decimal rule',
                    expected => "<= $rule->{max_decimals} decimal places",
                    actual => "$decimals decimal places ($val)",
                    rule => "max_decimals=$rule->{max_decimals}",
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
    printf "FAIL scenario=%s file=%s row=%s column=%s asserts=%s produced_by=%s contract=%s expected=%s actual=%s rule=%s\n",
        $f->{scenario}, $f->{file}, $f->{row}, $f->{column},
        qquote($f->{asserts}),
        $f->{produced_by},
        qquote($f->{contract}),
        qquote($f->{expected}),
        qquote($f->{actual}),
        qquote($f->{rule});
}

sub qquote {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/"/\\"/g;
    return qq("$s");
}
