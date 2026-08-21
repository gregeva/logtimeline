#!/usr/bin/env perl
#
# 58-mtf-mini.pl — constrained-MTF ordering candidate comparison (#58 A2/F8-3,
# audit coverage item 1).
#
# Recognition-only (no extraction): 12 regex registry entries in cascade
# order (CSV/mt13 is stateful and lives outside the array per A7; the two
# mt1 branches are separate entries, standard before generic).
#
# Ground truth is R3 extraction parity: a candidate ordering policy is
# CORRECT iff it classifies every line identically to today's static
# cascade order. Phase B tests exactly that, per line, on real fixtures
# and on adversarial stray-line streams.
#
# Ordering constraints are DERIVED, not hand-written: every format's
# sample lines are cross-tested against every pattern at load (the F4/D24
# cross-shadowing test). If pattern G also matches a sample whose static
# classification is F (G tried later than F today), the pair F-before-G is
# pinned. A2's documented pairs must fall out of this automatically.
#
# Policies:
#   static      today's fixed cascade order (baseline + ground truth)
#   mtf-free    unconstrained move-to-front (expected correctness FAILURE;
#               retained as the performance ceiling)
#   mtf-pinned  winner moves to front together with its pinned-ancestor
#               closure, preserving their current relative order
#   tier-mtf    entries layered by constraint-DAG depth; MTF within tier,
#               tiers never mix
#
# Usage:
#   perl prototype/58-mtf-mini.pl [--runs N] [--phase A|B|C|all] <fixture> [...]
#
# TSV on stdout (58-measure.pm shape) for phase C; phases A/B report on stderr.

use strict;
use warnings;
use FindBin;
require "$FindBin::Bin/58-measure.pm";

my $runs = 5;
my $phase = 'all';
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $opt = shift @ARGV;
    if    ($opt eq '--runs')  { $runs = shift @ARGV; }
    elsif ($opt eq '--phase') { $phase = shift @ARGV; }
    else  { die "unknown option $opt\n"; }
}

## ---------------------------------------------------------------------------
## Registry entries: name + recognition pattern, in cascade order.
## Patterns are verbatim from read_and_process_logs() (capture groups kept
## so cost matches the real patterns; captures are unused here).
## ---------------------------------------------------------------------------

my @ENTRIES = (
    { name => 'mt1std',  qr => qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/ },
    { name => 'mt10',    qr => qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) \[([^\]]*)\] ([^ ]*)\s+([^ ]*) - (.*)/ },
    { name => 'mt1gen',  qr => qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\+\d{4} \[L: ([^\]]*)\]/ },
    { name => 'mt2',     qr => qr/^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3}).*? \[[L: ]*([^\]]*)\]/ },
    { name => 'mt12',    qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?\[([0-9.]+)ms\] \[(.+)s\]/ },
    { name => 'mt4',     qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)$/ },
    { name => 'mt9',     qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+) "([^"]+)" "([^"]+)" (\d+)$/ },
    { name => 'mt3',     qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?/ },
    { name => 'mt5',     qr => qr/^{"\@timestamp":"([^"]*).*"level":"([^"]*)/ },
    { name => 'mt6',     qr => qr/^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3})[+-]\d{4}.*?\[info\]\[gc\s*\] GC\(\d+\) (.+?) (\(.+?\)) (\d[^-]+)->(\d[^(]+)\((\d[^)]+)\) (\d.*)ms/ },
    { name => 'mt7',     qr => qr/^([^ ]+)\s+\[(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[.,]\d{3})\] (.*)$/ },
    { name => 'mt8',     qr => qr/^(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[^ ]*)\s+\[([^]]+)\]\s+(\w+)\s+(.*)$/ },
    { name => 'mt11',    qr => qr/^([^ ]+) (\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}[,.]\d+) (.*)/ },
);
my %ENTRY_IDX = map { $ENTRIES[$_]{name} => $_ } 0 .. $#ENTRIES;

## ---------------------------------------------------------------------------
## Per-format sample lines (R1 samples). Intended format is informational;
## ground truth for constraint derivation is each sample's STATIC cascade
## classification, so a sample landing elsewhere is surfaced, not hidden.
## ---------------------------------------------------------------------------

my @SAMPLES = (
    [ mt1std => '2025-05-05 00:00:00.006+0000 [L: ERROR] [O: c.p.a.u.JobPurgeScheduler] [I: ] [U: SuperUser] [S: ] [P: ] [T: pool-1-thread-1] Job purge completed' ],
    [ mt1std => '2025-05-05 00:00:01.100+0000 [L: INFO] [O: S.c.t.d.e.DSLScript] [I: ] [U: Administrator] [S: ] [P: ] [T: TWEventProcessor-4] Executed service durationMS=42 result bytes=1024 count=7' ],
    [ mt10   => '2025-08-14 21:00:34.633 [vert.x-eventloop-thread-12] INFO  c.t.c.a.AlwaysOnHttpServerVerticle - Enabled fix for WebSocket compression sometimes causing frames to exceed maximum WebSocket frame size' ],
    [ mt10   => '2025-08-14 21:00:35.001 [vert.x-eventloop-thread-3] INFO  c.t.c.a.RequestHandler - Processed request from 10.1.2.3:51234 in 18 milliseconds' ],
    [ mt1gen => '2025-02-04 12:05:57.481+0000 [L: DEBUG] trailing content that does not carry the full bracket sections' ],
    [ mt2    => '[2025-02-04T12:06:22.784] [TRACE] tunnel keepalive sent' ],
    [ mt12   => '192.168.223.1 - - [29/Oct/2025:08:52:11 +0000] "GET /urlversioned/202510290803/images/newskin/login_page/icon_qa.png HTTP/1.1" 200 20097 [5ms] [0.005s]' ],
    [ mt4    => '43.52.82.172 - - [02/Feb/2025:00:00:11 +0000] "GET /Thingworx/Metrics?x-thingworx-session=false HTTP/1.1" 200 17626' ],
    [ mt9    => '127.0.0.1 - - [13/Mar/2025:09:02:41 +0000] "GET /async/prediction/evaluation?limit=99999 HTTP/1.1" 200 51 "-" "Jersey/2.37 (HttpUrlConnection 11.0.22)" 651' ],
    [ mt3    => '43.52.82.172 - - [02/Feb/2025:00:00:11 +0000] "GET /Thingworx/Metrics?x-thingworx-session=false HTTP/1.1" 200 17626 295' ],
    [ mt3    => '10.224.34.60 - - [05/May/2025:00:00:00 +0000] "POST /Thingworx/WS HTTP/1.1" 200 261 1' ],
    [ mt5    => '{"@timestamp":"2025-02-02T21:03:06.725+00:00","@version":1,"message":"Error encountered, closing WebSocket: endpointId=2608459","logger_name":"com.thingworx.connectionserver.alwayson.AbstractClientEndpoint","thread_name":"vert.x-eventloop-thread-16","level":"WARN","level_value":30000}' ],
    [ mt6    => '[2025-04-05T11:10:47.867+0000][info][gc] GC(0) Pause Young (Normal) (G1 Evacuation Pause) 2433M->66M(49152M) 18.406ms' ],
    [ mt7    => 'ERROR [2025-02-19 18:31:00,284] com.thingworx.sdk.impl.transport.netty.NettyChannelHandler: WebSocket error: connection forcibly closed' ],
    [ mt7    => 'INFO  [2025-02-20 04:49:11,450] org.ehcache.core.EhcacheManager: Cache scorefunc_cachex created in EhcacheManager.' ],
    [ mt8    => '2025-02-20 10:06:10 [nioEventLoopGroup-2-1] WARN  io.netty.channel.ChannelInitializer - Failed to initialize a channel. Closing: [id: 0x8171dc41]' ],
    [ mt11   => 'INFO 2025-08-09 18:19:04,479 8012 twx_connection.cpp:246 Run Error in the TWX processor thread, have to reinitialize.' ],
    [ mt11   => 'ERROR 2025-08-09 18:27:18,38 TW_SSL_READ: Error reading from SSL stream' ],
);

## ---------------------------------------------------------------------------
## Classification under a policy. Each policy carries its own mutable order
## state, reset per stream. classify() returns the entry name or ''.
## ---------------------------------------------------------------------------

sub classify_static {
    my ($line) = @_;
    for my $e (@ENTRIES) {
        return $e->{name} if $line =~ $e->{qr};
    }
    return '';
}

## Constraint derivation (phase A also reports it) -------------------------

my (%must_precede);      # $must_precede{G}{F}=1  means F must be tried before G
my (%ancestors);         # transitive closure: $ancestors{X} = [names before X], cascade-ordered

sub derive_constraints {
    my @pairs;
    for my $s (@SAMPLES) {
        my ($intended, $line) = @$s;
        my $truth = classify_static($line);
        warn "NOTE: sample intended '$intended' statically classifies as '$truth'\n"
            if $truth ne $intended;
        next unless $truth;
        my $truth_idx = $ENTRY_IDX{$truth};
        for my $e (@ENTRIES) {
            next if $e->{name} eq $truth;
            if ($line =~ $e->{qr}) {
                # $e also matches a line owned by $truth. If $e sits later in
                # the cascade, pin truth-before-e; if earlier, the cascade
                # already gives $e the line — that would be a mislabeled
                # sample, caught by the $truth reassignment above.
                if ($ENTRY_IDX{$e->{name}} > $truth_idx) {
                    push @pairs, [ $truth, $e->{name} ]
                        unless $must_precede{$e->{name}}{$truth}++;
                }
            }
        }
    }
    # transitive closure, ancestors listed in cascade order
    for my $x (map { $_->{name} } @ENTRIES) {
        my %seen;
        my @queue = keys %{ $must_precede{$x} // {} };
        while (@queue) {
            my $p = shift @queue;
            next if $seen{$p}++;
            push @queue, keys %{ $must_precede{$p} // {} };
        }
        $ancestors{$x} = [ sort { $ENTRY_IDX{$a} <=> $ENTRY_IDX{$b} } keys %seen ];
    }
    return \@pairs;
}

## Policy engines ----------------------------------------------------------

sub make_policy {
    my ($kind) = @_;
    if ($kind eq 'static') {
        my $attempts = 0;
        my $classify = sub {
            my ($line) = @_;
            for my $e (@ENTRIES) {
                $attempts++;
                return $e->{name} if $line =~ $e->{qr};
            }
            return '';
        };
        return { classify => $classify, reorders => \(my $z = 0), attempts => \$attempts };
    }
    if ($kind eq 'mtf-free' || $kind eq 'mtf-pinned') {
        my @order = @ENTRIES;
        my $reorders = 0;
        my $attempts = 0;
        my $classify = sub {
            my ($line) = @_;
            for my $i (0 .. $#order) {
                $attempts++;
                if ($line =~ $order[$i]{qr}) {
                    my $name = $order[$i]{name};
                    if ($i > 0) {
                        if ($kind eq 'mtf-free') {
                            $reorders++;
                            my ($e) = splice(@order, $i, 1);
                            unshift @order, $e;
                        } else {
                            # promote winner together with its ancestor closure,
                            # preserving current relative order; skip when the
                            # winner already sits directly behind its ancestors
                            # (every entry ahead of it is an ancestor)
                            my %anc = map { $_ => 1 } @{ $ancestors{$name} };
                            my $optimal = 1;
                            for my $j (0 .. $i - 1) {
                                if (!$anc{$order[$j]{name}}) { $optimal = 0; last }
                            }
                            if (!$optimal) {
                                $reorders++;
                                my %front = (%anc, $name => 1);
                                my (@f, @r);
                                for my $e (@order) {
                                    if ($front{$e->{name}}) { push @f, $e } else { push @r, $e }
                                }
                                @order = (@f, @r);
                            }
                        }
                    }
                    return $name;
                }
            }
            return '';
        };
        return { classify => $classify, reorders => \$reorders, attempts => \$attempts,
                 order => \@order };
    }
    if ($kind eq 'tier-mtf') {
        # tier = longest ancestor chain length (DAG depth)
        my %depth;
        my $d; $d = sub {
            my ($x) = @_;
            return $depth{$x} //= @{ $ancestors{$x} // [] }
                ? 1 + (sort { $b <=> $a } map { $d->($_) } @{ $ancestors{$x} })[0]
                : 0;
        };
        my @tiers;
        for my $e (@ENTRIES) {
            push @{ $tiers[ $d->($e->{name}) ] }, $e;
        }
        @tiers = grep { defined } @tiers;
        my $reorders = 0;
        my $attempts = 0;
        my $classify = sub {
            my ($line) = @_;
            for my $t (@tiers) {
                for my $i (0 .. $#$t) {
                    $attempts++;
                    if ($line =~ $t->[$i]{qr}) {
                        if ($i > 0) {
                            $reorders++;
                            my ($e) = splice(@$t, $i, 1);
                            unshift @$t, $e;
                        }
                        return $t->[0]{name};
                    }
                }
            }
            return '';
        };
        return { classify => $classify, reorders => \$reorders, attempts => \$attempts,
                 tiers => \@tiers };
    }
    die "unknown policy kind $kind";
}

my @POLICY_KINDS = qw(static mtf-free mtf-pinned tier-mtf);

## ---------------------------------------------------------------------------
## Phase A — overlap matrix and derived constraints
## ---------------------------------------------------------------------------

my $pairs = derive_constraints();

if ($phase eq 'A' || $phase eq 'all') {
    print STDERR "=== Phase A: derived ordering constraints (specific-before-general) ===\n";
    for my $p (sort { $ENTRY_IDX{$a->[0]} <=> $ENTRY_IDX{$b->[0]}
                   || $ENTRY_IDX{$a->[1]} <=> $ENTRY_IDX{$b->[1]} } @$pairs) {
        printf STDERR "  %-7s must precede %-7s\n", @$p;
    }
    for my $e (@ENTRIES) {
        my $a = $ancestors{$e->{name}};
        printf STDERR "  closure: %-7s <- [%s]\n", $e->{name}, join(' ', @$a) if @$a;
    }
    my $tp = make_policy('tier-mtf');
    my $ti = 0;
    printf STDERR "  tiers: %s\n",
        join(' | ', map { 'T' . $ti++ . ': ' . join(' ', map { $_->{name} } @$_) } @{ $tp->{tiers} });
}

## ---------------------------------------------------------------------------
## Phase B — correctness: per-line equality vs static classification
## ---------------------------------------------------------------------------

## adversarial streams: a run of one format's real-shaped lines with strays
## of a sibling format injected — the A2 promotion scenario, both directions.
my %sample_line = map { $_->[0] => $_->[1] } reverse @SAMPLES;   # first sample per format
sub adversarial_stream {
    my ($main_fmt, $stray_fmt, $n) = @_;
    my @s = ( ($sample_line{$main_fmt}) x ($n/2), $sample_line{$stray_fmt}, ($sample_line{$main_fmt}) x ($n/2) );
    return \@s;
}

sub check_policy_on_stream {
    my ($kind, $lines, $label) = @_;
    my $pol = make_policy($kind);
    my $divergent = 0;
    my $first;
    my $n = 0;
    for my $line (@$lines) {
        $n++;
        my $got = $pol->{classify}->($line);
        my $want = classify_static($line);
        if ($got ne $want) {
            $divergent++;
            $first //= sprintf("line %d: static=%s %s=%s", $n, $want || '(none)', $kind, $got || '(none)');
        }
    }
    printf STDERR "  %-10s %-28s %s\n", $kind, $label,
        $divergent ? "DIVERGES ($divergent lines; first: $first)" : "identical to static ($n lines)";
    return $divergent;
}

if ($phase eq 'B' || $phase eq 'all') {
    print STDERR "=== Phase B: classification parity vs static cascade order ===\n";
    my @streams = (
        [ 'mt4 run + mt3 stray',  adversarial_stream('mt4', 'mt3', 200) ],
        [ 'mt3 run + mt4 stray',  adversarial_stream('mt3', 'mt4', 200) ],
        [ 'mt9 run + mt3 stray',  adversarial_stream('mt9', 'mt3', 200) ],
        [ 'mt12 run + mt3 stray', adversarial_stream('mt12', 'mt3', 200) ],
        [ 'mt10 run + mt2 stray', adversarial_stream('mt10', 'mt2', 200) ],
        [ 'mt8 run + mt10 stray', adversarial_stream('mt8', 'mt10', 200) ],
        [ 'all samples round-robin x50', [ (map { $_->[1] } @SAMPLES) x 50 ] ],
    );
    for my $s (@streams) {
        my ($label, $lines) = @$s;
        check_policy_on_stream($_, $lines, $label) for @POLICY_KINDS;
    }
    for my $file (@ARGV) {
        (my $fixture = $file) =~ s{.*/}{};
        open my $fh, '<', $file or die "Cannot open file: $file";
        my @lines;
        while (<$fh>) { s/[\r\n]+$//; push @lines, $_; }
        close $fh;
        check_policy_on_stream($_, \@lines, $fixture) for @POLICY_KINDS;
    }
}

## ---------------------------------------------------------------------------
## Phase C — timing + scan-depth counters per policy per fixture
## ---------------------------------------------------------------------------

if ($phase eq 'C' || $phase eq 'all') {
    Measure58::tsv_header(\*STDOUT);
    for my $file (@ARGV) {
        (my $fixture = $file) =~ s{.*/}{};
        open my $fh, '<', $file or die "Cannot open file: $file";
        my @lines;
        while (<$fh>) { s/[\r\n]+$//; push @lines, $_; }
        close $fh;

        for my $kind (@POLICY_KINDS) {
            my ($attempts, $reorders);
            my @secs = Measure58::time_runs($runs, sub {
                my $pol = make_policy($kind);          # fresh order state per run
                my $c = $pol->{classify};
                $c->($_) for @lines;
                $attempts = ${ $pol->{attempts} };
                $reorders = ${ $pol->{reorders} };
            });
            my ($med, $min, $max) = Measure58::median_min_max(@secs);
            Measure58::emit_tsv(\*STDOUT, "order-$kind", $fixture, scalar @lines, 'ns_per_line',
                map { $_ / @lines * 1e9 } $med, $min, $max);
            printf STDERR "  %-10s %-24s attempts/line=%.2f reorders=%d\n",
                $kind, $fixture, ($attempts // 0) / @lines, $reorders // 0;
        }
    }
}
