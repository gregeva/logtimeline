#!/usr/bin/env perl
#
# 58-window-mini.pl — detection-window replay cost (#58 charter item 5, D17):
# hold the first N lines for detection, then replay. Prices four designs:
#
#   no-window            today's shape: classify+extract every line as read
#   two-phase-store      window loop holds [line, entry] (classification
#                        happens once, extraction deferred to flush), then a
#                        CLEAN steady loop with no window check — the
#                        intended implementation
#   two-phase-reclassify window holds raw lines only; flush re-classifies
#                        and extracts (double classification of N lines,
#                        smaller/simpler buffer)
#   naive-branch         single loop with a per-line "window active?" branch
#                        — prices leaving that check in the hot path
#
# Scan is the P4-winning configuration (pinned-closure MTF + selective
# access-sibling guards); extraction is a fixed closure-call stand-in,
# identical in every candidate (dispatch cost was P2's axis). Every
# candidate must classify every line identically and produce the same
# accumulators. Buffer memory is reported via Devel::Size at flush.
#
# Usage:
#   perl prototype/58-window-mini.pl [--runs N] [--window N] <fixture> [...]

use strict;
use warnings;
use FindBin;
use Devel::Size qw(total_size);
require "$FindBin::Bin/58-measure.pm";

my $runs = 5;
my $window = 1000;
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $opt = shift @ARGV;
    if    ($opt eq '--runs')   { $runs = shift @ARGV; }
    elsif ($opt eq '--window') { $window = shift @ARGV; }
    else  { die "unknown option $opt\n"; }
}
die "usage: $0 [--runs N] [--window N] <fixture> [...]\n" unless @ARGV;

## ---------------------------------------------------------------------------
## Scan machinery (P4 sel-guards configuration, aoh shape)
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

## per-entry extraction stand-in: fixed closure call (identical everywhere)
my $EXTRACT_SINK = 0;
my $EXTRACT = sub { $EXTRACT_SINK += $_[0] };

sub make_scan {
    my @order = @ENTRY_DEFS;
    my $classify = sub {
        my ($line) = @_;
        for my $i (0 .. $#order) {
            my $e = $order[$i];
            my $g = $e->{guard};
            if ($g && !$g->($line)) { next; }
            if ($line =~ $e->{qr}) {
                if ($i > 0) {
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
                return $e;
            }
        }
        return undef;
    };
    return $classify;
}

## ---------------------------------------------------------------------------
## Candidates. Each returns {matched, unmatched} and drives $EXTRACT once per
## matched line (never more), except two-phase-reclassify which classifies
## window lines twice by design.
## ---------------------------------------------------------------------------

sub run_no_window {
    my ($lines) = @_;
    my $c = make_scan();
    my ($m, $u) = (0, 0);
    for my $line (@$lines) {
        my $e = $c->($line);
        if ($e) { $m++; $EXTRACT->(1); } else { $u++; }
    }
    return { matched => $m, unmatched => $u, buffer_bytes => 0 };
}

sub run_two_phase_store {
    my ($lines) = @_;
    my $c = make_scan();
    my ($m, $u) = (0, 0);
    my $n = @$lines;
    my $w = $window < $n ? $window : $n;
    my @held;
    my $buffer_bytes = 0;
    for my $k (0 .. $w - 1) {                    # window: classify once, hold
        my $line = $lines->[$k];
        push @held, [ $line, $c->($line) ];
    }
    $buffer_bytes = total_size(\@held);
    for my $h (@held) {                          # flush: deferred extraction
        if ($h->[1]) { $m++; $EXTRACT->(1); } else { $u++; }
    }
    @held = ();
    for my $k ($w .. $n - 1) {                   # clean steady loop
        my $e = $c->($lines->[$k]);
        if ($e) { $m++; $EXTRACT->(1); } else { $u++; }
    }
    return { matched => $m, unmatched => $u, buffer_bytes => $buffer_bytes };
}

sub run_two_phase_reclassify {
    my ($lines) = @_;
    my $c = make_scan();
    my ($m, $u) = (0, 0);
    my $n = @$lines;
    my $w = $window < $n ? $window : $n;
    my @held;
    for my $k (0 .. $w - 1) {                    # window: classify (for
        my $line = $lines->[$k];                 # detection) but hold raw
        $c->($line);
        push @held, $line;
    }
    my $buffer_bytes = total_size(\@held);
    for my $line (@held) {                       # flush: re-classify + extract
        my $e = $c->($line);
        if ($e) { $m++; $EXTRACT->(1); } else { $u++; }
    }
    @held = ();
    for my $k ($w .. $n - 1) {
        my $e = $c->($lines->[$k]);
        if ($e) { $m++; $EXTRACT->(1); } else { $u++; }
    }
    return { matched => $m, unmatched => $u, buffer_bytes => $buffer_bytes };
}

sub run_naive_branch {
    my ($lines) = @_;
    my $c = make_scan();
    my ($m, $u) = (0, 0);
    my @held;
    my $in_window = 1;
    my $buffer_bytes = 0;
    my $k = 0;
    for my $line (@$lines) {
        if ($in_window) {                        # branch evaluated EVERY line
            push @held, [ $line, $c->($line) ];
            if (++$k >= $window) {
                $buffer_bytes = total_size(\@held);
                for my $h (@held) {
                    if ($h->[1]) { $m++; $EXTRACT->(1); } else { $u++; }
                }
                @held = ();
                $in_window = 0;
            }
            next;
        }
        my $e = $c->($line);
        if ($e) { $m++; $EXTRACT->(1); } else { $u++; }
    }
    if ($in_window) {                            # EOF before window closed
        $buffer_bytes = total_size(\@held);
        for my $h (@held) {
            if ($h->[1]) { $m++; $EXTRACT->(1); } else { $u++; }
        }
    }
    return { matched => $m, unmatched => $u, buffer_bytes => $buffer_bytes };
}

my @CANDS = (
    [ 'window-none',        \&run_no_window ],
    [ 'window-store',       \&run_two_phase_store ],
    [ 'window-reclassify',  \&run_two_phase_reclassify ],
    [ 'window-naive',       \&run_naive_branch ],
);

## ---------------------------------------------------------------------------
## Driver: parity (accumulator equality) then timing
## ---------------------------------------------------------------------------

Measure58::tsv_header(\*STDOUT);
foreach my $file (@ARGV) {
    (my $fixture = $file) =~ s{.*/}{};
    open my $fh, '<', $file or die "Cannot open file: $file";
    my @lines;
    while (<$fh>) { s/[\r\n]+$//; push @lines, $_; }
    close $fh;

    my $base = run_no_window(\@lines);
    for my $cand (@CANDS) {
        my ($name, $runner) = @$cand;
        my $acc = $runner->(\@lines);
        if ($acc->{matched} != $base->{matched} || $acc->{unmatched} != $base->{unmatched}) {
            print STDERR "  $name $fixture PARITY FAILURE (matched $acc->{matched} vs $base->{matched}) — skipping\n";
            next;
        }
        my @secs = Measure58::time_runs($runs, sub { $acc = $runner->(\@lines) });
        my ($med, $min, $max) = Measure58::median_min_max(@secs);
        Measure58::emit_tsv(\*STDOUT, $name, $fixture, scalar @lines, 'ns_per_line',
            map { $_ / @lines * 1e9 } $med, $min, $max);
        printf STDERR "  %-18s %-24s window=%d matched=%d unmatched=%d buffer=%d bytes\n",
            $name, $fixture, $window, $acc->{matched}, $acc->{unmatched}, $acc->{buffer_bytes};
    }
}
