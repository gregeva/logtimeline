#!/usr/bin/env perl
#
# 58-csv-mini.pl — CSV matcher-kind decision (#58 A7): correctness
# demonstration that the lazy CSV stage (Issue #107 mechanics) composes
# unchanged with the registry's ordered scan, because CSV confirmation
# consumes only the match/no-match OUTCOME of the scan — which P3 proved
# identical under pinned-closure MTF and static order on every line.
#
# The design decision this demonstrates (recorded as P9 in the feature
# doc): CSV does NOT become a matcher-kind inside the MTF array — it stays
# a stateful per-file stage outside it, exactly as today:
#   - unconfirmed: runs only after the full scan fails a line (lines 1-2)
#   - confirmed:  a per-file extractor override short-circuits the scan
#     entirely (today's $csv_detected branch at the top of the loop)
# The registry still carries a 'csv' entry (slug, time contract,
# split-based extraction closure) — referenced by the stage, never scanned.
#
# Scenarios (each run under BOTH static and pinned+sel-guards order;
# outcomes must be identical):
#   1. real CSV files with a matching UDM config -> confirmed at line 2,
#      every data line classified csv
#   2. a log fixture with UDM configs          -> CSV never confirmed
#      (line 1 matches a format), classification untouched
#   3. adversarial: CSV data whose line 1 is a log line -> disqualified
#   4. CSV with no UDM configs                 -> stage inert, no detection
#
# Usage: perl prototype/58-csv-mini.pl

use strict;
use warnings;
use FindBin;

my $REPO = "$FindBin::Bin/..";

## ---------------------------------------------------------------------------
## Scan machinery (P4 configuration), both orderings
## ---------------------------------------------------------------------------

my @ENTRY_DEFS = (
    { name => 'mt1std',  qr => qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/ },
    { name => 'mt10',    qr => qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) \[([^\]]*)\] ([^ ]*)\s+([^ ]*) - (.*)/ },
    { name => 'mt1gen',  qr => qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\+\d{4} \[L: ([^\]]*)\]/ },
    { name => 'mt2',     qr => qr/^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3}).*? \[[L: ]*([^\]]*)\]/ },
    { name => 'mt12',    qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?\[([0-9.]+)ms\] \[(.+)s\]/,
      guard => do { my $lit = 'ms] ['; sub { index($_[0], $lit) >= 0 } } },
    { name => 'mt4',     qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)$/,
      guard => sub { my $p = rindex($_[0], '" '); return 0 if $p < 0; return (substr($_[0], $p + 2) =~ tr/ //) == 1; } },
    { name => 'mt9',     qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+) "([^"]+)" "([^"]+)" (\d+)$/,
      guard => do { my $lit = '" "'; sub { index($_[0], $lit) >= 0 } } },
    { name => 'mt3',     qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?/ },
    { name => 'mt5',     qr => qr/^{"\@timestamp":"([^"]*).*"level":"([^"]*)/ },
    { name => 'mt6',     qr => qr/^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3})[+-]\d{4}.*?\[info\]\[gc\s*\] GC\(\d+\) (.+?) (\(.+?\)) (\d[^-]+)->(\d[^(]+)\((\d[^)]+)\) (\d.*)ms/ },
    { name => 'mt7',     qr => qr/^([^ ]+)\s+\[(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[.,]\d{3})\] (.*)$/ },
    { name => 'mt8',     qr => qr/^(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[^ ]*)\s+\[([^]]+)\]\s+(\w+)\s+(.*)$/ },
    { name => 'mt11',    qr => qr/^([^ ]+) (\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}[,.]\d+) (.*)/ },
);
my %ANCESTORS = (
    mt1gen => [ 'mt1std' ],
    mt2    => [ 'mt1std', 'mt10', 'mt1gen' ],
    mt3    => [ 'mt12', 'mt4', 'mt9' ],
    mt8    => [ 'mt1std', 'mt10', 'mt1gen' ],
);

sub make_scan {
    my ($kind) = @_;                  # 'static' | 'pinned'
    my @order = @ENTRY_DEFS;
    return sub {
        my ($line) = @_;
        for my $i (0 .. $#order) {
            my $e = $order[$i];
            my $g = $e->{guard};
            if ($g && !$g->($line)) { next; }
            if ($line =~ $e->{qr}) {
                if ($kind eq 'pinned' && $i > 0) {
                    my %anc = map { $_ => 1 } @{ $ANCESTORS{$e->{name}} // [] };
                    my $optimal = 1;
                    for my $j (0 .. $i - 1) {
                        if (!$anc{$order[$j]{name}}) { $optimal = 0; last }
                    }
                    if (!$optimal) {
                        my %front = (%anc, $e->{name} => 1);
                        my (@f, @r);
                        for my $o (@order) {
                            if ($front{$o->{name}}) { push @f, $o } else { push @r, $o }
                        }
                        @order = (@f, @r);
                    }
                }
                return $e->{name};
            }
        }
        return '';
    };
}

## ---------------------------------------------------------------------------
## Lazy CSV stage (faithful to ltl: separator autodetect, header map,
## 80% field-count validation, disqualification on any log match in lines 1-2)
## ---------------------------------------------------------------------------

sub parse_csv_header {
    my ($header_line, $udm_names) = @_;
    my $comma = () = $header_line =~ /,/g;
    my $semi  = () = $header_line =~ /;/g;
    my $tab   = () = $header_line =~ /\t/g;
    my %sep_counts = ( ',' => $comma, ';' => $semi, "\t" => $tab );
    my ($best) = sort { $sep_counts{$b} <=> $sep_counts{$a} || ($a cmp $b) } keys %sep_counts;
    return undef if $sep_counts{$best} < 1;
    my @headers = split(/\Q$best\E/, $header_line, -1);
    my %col_index;
    for my $i (0 .. $#headers) {
        my $col = $headers[$i];
        $col =~ s/^\s+|\s+$//g;
        $col_index{lc($col)} = $i;
    }
    return { sep => $best, col_index => \%col_index,
             udm_cols => [ map { $col_index{lc $_} // -1 } @$udm_names ] };
}

## process a line stream through scan + lazy CSV stage; returns outcome record
sub run_stream {
    my ($lines, $scan_kind, $udm_names) = @_;
    my $c = make_scan($scan_kind);
    my $have_udm = @$udm_names ? 1 : 0;
    my ($csv_detected, $potential_csv_header, $csv_meta) = (0, undef, undef);
    my ($line_number, @kinds) = (0);
    my ($csv_lines, $matched, $unmatched) = (0, 0, 0);
    for my $line (@$lines) {
        $line_number++;
        if ($csv_detected) {
            $csv_lines++;
            push @kinds, 'csv';
            next;
        }
        my $name = $c->($line);
        if ($have_udm && !$csv_detected) {
            if ($name) {
                $potential_csv_header = undef;
            } elsif ($line_number == 1) {
                $potential_csv_header = $line;
                push @kinds, 'held';
                next;
            } elsif ($line_number == 2 && defined $potential_csv_header) {
                if ($csv_meta = parse_csv_header($potential_csv_header, $udm_names)) {
                    my @data_fields = split(/\Q$csv_meta->{sep}\E/, $line, -1);
                    my $header_count = scalar keys %{ $csv_meta->{col_index} };
                    if (scalar @data_fields >= $header_count * 0.8) {
                        $csv_detected = 1;
                        $csv_lines++;
                        push @kinds, 'csv';
                        next;
                    }
                    $csv_meta = undef;
                }
                $potential_csv_header = undef;
            }
        }
        if ($name) { $matched++; push @kinds, $name; }
        else       { $unmatched++; push @kinds, ''; }
    }
    return { csv_detected => $csv_detected, csv_lines => $csv_lines,
             matched => $matched, unmatched => $unmatched,
             kinds => join(',', @kinds),
             udm_cols => $csv_meta ? join(',', @{ $csv_meta->{udm_cols} }) : '' };
}

## ---------------------------------------------------------------------------
## Scenarios
## ---------------------------------------------------------------------------

sub load_file {
    my ($path, $limit) = @_;
    open my $fh, '<', $path or die "Cannot open file: $path";
    my @lines;
    while (<$fh>) {
        s/[\r\n]+$//;
        push @lines, $_;
        last if $limit && @lines >= $limit;
    }
    close $fh;
    return \@lines;
}

my $csv_small = load_file("$REPO/logs/UDM/connection-server-custom-metrics.csv");
my $csv_big   = load_file("$REPO/logs/UDM/results_data_idonly-timestampMs.csv", 10000);
my $log_mixed = load_file('/tmp/ltl-58-fixtures/twx-blend-1k.log');
my @adversarial = ( $log_mixed->[0], @{$csv_small}[0 .. $#{$csv_small}] );

my @scenarios = (
    [ 'csv-small + udm(system_cpu_total)', $csv_small, ['system_cpu_total'],
      { csv_detected => 1 } ],
    [ 'csv-big + udm(latency_ms)',         $csv_big,   ['latency_ms'],
      { csv_detected => 1 } ],
    [ 'log fixture + udm(latency_ms)',     $log_mixed, ['latency_ms'],
      { csv_detected => 0 } ],
    [ 'adversarial log-line-first CSV',    \@adversarial, ['system_cpu_total'],
      { csv_detected => 0 } ],
    [ 'csv-small, NO udm configs',         $csv_small, [],
      { csv_detected => 0 } ],
);

my $failures = 0;
for my $s (@scenarios) {
    my ($label, $lines, $udm, $expect) = @$s;
    my $a = run_stream($lines, 'static', $udm);
    my $b = run_stream($lines, 'pinned', $udm);
    my $same = ($a->{kinds} eq $b->{kinds} && $a->{csv_detected} == $b->{csv_detected}
             && $a->{udm_cols} eq $b->{udm_cols});
    my $exp_ok = $a->{csv_detected} == $expect->{csv_detected};
    printf "%-36s csv_detected=%d csv_lines=%-6d matched=%-5d unmatched=%-5d udm_cols=[%s]  %s%s\n",
        $label, $a->{csv_detected}, $a->{csv_lines}, $a->{matched}, $a->{unmatched}, $a->{udm_cols},
        $same ? 'static==pinned' : 'ORDER DIVERGENCE!',
        $exp_ok ? '' : '  UNEXPECTED OUTCOME!';
    $failures++ unless $same && $exp_ok;
}
print $failures ? "FAIL: $failures scenario(s)\n" : "All scenarios: outcomes identical under static and pinned-MTF order, expectations met\n";
exit($failures ? 1 : 0);
