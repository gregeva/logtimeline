#!/usr/bin/env perl
#
# 58-guards-mini.pl — cheap per-entry superset guards + atomic-head variants
# (#58 F8-5, A1, coverage item 2; follows P3's finding that the access-log
# prize is same-head sibling rejects, not ordering).
#
# A guard is registry-entry DATA compiled to a closure at load: a cheap test
# that may pass lines the pattern will reject (false positive, costs one
# wasted attempt) but must NEVER reject a line the pattern would match
# (false negative = misclassification). Phase A asserts that superset
# property empirically on every fixture line and sample, plus full
# classification parity vs the static cascade.
#
# Candidates (all orderings are pinned-closure MTF from P3 unless noted):
#   pinned               P3 replica, no guards (baseline)
#   pinned+guards        guard closure consulted before each regex attempt
#   pinned+atomic        access-family patterns with atomic-group heads, no guards
#   pinned+guards+atomic both
#   mtf-free             unconstrained ceiling (correctness-invalid, reference)
#
# Usage:
#   perl prototype/58-guards-mini.pl [--runs N] [--phase A|B|all] <fixture> [...]
#
# Phase A (correctness) reads the fixtures given; phase B (timing) reads the
# same list. TSV on stdout (58-measure.pm shape); reports on stderr.

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
die "usage: $0 [--runs N] [--phase A|B|all] <fixture> [...]\n" unless @ARGV;

## ---------------------------------------------------------------------------
## Entries: cascade order; qr / qr_atomic / guard spec (compiled below).
## Guard specs are declarative registry data: {lit=>...} an index() literal;
## {head=>...} a leading-substring equality; {tail1=>1} the mt4 one-token-
## after-closing-quote test; absent = always attempt.
## ---------------------------------------------------------------------------

my @ENTRY_DEFS = (
    { name => 'mt1std',
      qr => qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/,
      guard => { lit => ' [L: ' } },
    { name => 'mt10',
      qr => qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) \[([^\]]*)\] ([^ ]*)\s+([^ ]*) - (.*)/,
      guard => { lit => ' - ' } },
    { name => 'mt1gen',
      qr => qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\+\d{4} \[L: ([^\]]*)\]/,
      guard => { lit => ' [L: ' } },
    { name => 'mt2',
      qr => qr/^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3}).*? \[[L: ]*([^\]]*)\]/,
      guard => { lit => ' [' } },
    { name => 'mt12',
      qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?\[([0-9.]+)ms\] \[(.+)s\]/,
      qr_atomic => qr/^(?>[^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?\[([0-9.]+)ms\] \[(.+)s\]/,
      atomic_shift => 1,
      guard => { lit => 'ms] [' },
      guard2 => { tail_eq => 's]' } },
    { name => 'mt4',
      qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)$/,
      qr_atomic => qr/^(?>[^ ]+ ){3}[\[]([^\]]+)[\]] "(?>[^"]+)" (\d{3}) (\d+|-)$/,
      atomic_shift => 1,
      guard => { tail1 => 1 },
      guard2 => { numtail_tail1 => 1 } },
    { name => 'mt9',
      qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+) "([^"]+)" "([^"]+)" (\d+)$/,
      qr_atomic => qr/^(?>[^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+) "([^"]+)" "([^"]+)" (\d+)$/,
      atomic_shift => 1,
      guard => { lit => '" "' },
      guard2 => { digit_6q => 1 } },
    { name => 'mt3',
      qr => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?/,
      qr_atomic => qr/^(?>[^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?/,
      atomic_shift => 1 },
    { name => 'mt5',
      qr => qr/^{"\@timestamp":"([^"]*).*"level":"([^"]*)/,
      guard => { head => '{"' } },
    { name => 'mt6',
      qr => qr/^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3})[+-]\d{4}.*?\[info\]\[gc\s*\] GC\(\d+\) (.+?) (\(.+?\)) (\d[^-]+)->(\d[^(]+)\((\d[^)]+)\) (\d.*)ms/,
      guard => { lit => 'GC(' } },
    { name => 'mt7',
      qr => qr/^([^ ]+)\s+\[(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[.,]\d{3})\] (.*)$/,
      guard => { lit => '[' } },
    { name => 'mt8',
      qr => qr/^(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[^ ]*)\s+\[([^]]+)\]\s+(\w+)\s+(.*)$/,
      guard => { lit => '[' } },
    { name => 'mt11',
      qr => qr/^([^ ]+) (\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}[,.]\d+) (.*)/ },
);

## Compile guard specs to closures (load-time, registry-realistic).
sub compile_guard {
    my ($spec) = @_;
    return undef unless $spec;
    if (defined $spec->{lit}) {
        my $lit = $spec->{lit};
        return sub { index($_[0], $lit) >= 0 };
    }
    if (defined $spec->{head}) {
        my $head = $spec->{head};
        my $len = length $head;
        return sub { substr($_[0], 0, $len) eq $head };
    }
    if (defined $spec->{tail_eq}) {
        # O(1): the pattern forces a fixed line-ending literal (mt12 ends "s]")
        my $t = $spec->{tail_eq};
        my $tl = length $t;
        return sub { substr($_[0], -$tl) eq $t };
    }
    if ($spec->{numtail_tail1}) {
        # O(1) precheck (mt4 must end in a digit or '-') before the bounded
        # tail1 test; the rindex then runs only on lines whose quote sits
        # near the end (access-shaped), keeping the miss path constant-cost
        return sub {
            my $c = substr($_[0], -1);
            return 0 unless $c eq '-' || ($c ge '0' && $c le '9');
            my $p = rindex($_[0], '" ');
            return 0 if $p < 0;
            return (substr($_[0], $p + 2) =~ tr/ //) == 1;
        };
    }
    if ($spec->{digit_6q}) {
        # mt9 must end in a digit and carries three quoted sections (6 quotes);
        # tr/"// is a fast counted scan, the digit test is O(1)
        return sub {
            my $c = substr($_[0], -1);
            return 0 unless $c ge '0' && $c le '9';
            return ($_[0] =~ tr/"//) >= 6;
        };
    }
    if ($spec->{tail1}) {
        # true when exactly one space-separated token follows the LAST closing
        # quote — the mt4 shape ("... HTTP/1.1" 200 17626). A line matching
        # mt4 always has its final '" ' as the request-closing quote (the
        # quoted request cannot contain '"' and nothing follows bytes).
        return sub {
            my $p = rindex($_[0], '" ');
            return 0 if $p < 0;
            my $tail = substr($_[0], $p + 2);
            return ($tail =~ tr/ //) == 1;
        };
    }
    die "unknown guard spec";
}

$_->{guard_fn}  = compile_guard($_->{guard})  for @ENTRY_DEFS;
$_->{guard2_fn} = compile_guard($_->{guard2}) for @ENTRY_DEFS;
my %ENTRY_IDX = map { $ENTRY_DEFS[$_]{name} => $_ } 0 .. $#ENTRY_DEFS;

## ---------------------------------------------------------------------------
## Samples + constraint derivation (as P3; ancestors feed pinned promotion).
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

sub classify_static {
    my ($line) = @_;
    for my $e (@ENTRY_DEFS) {
        return $e->{name} if $line =~ $e->{qr};
    }
    return '';
}

my %must_precede;
my %ancestors;
{
    for my $s (@SAMPLES) {
        my ($intended, $line) = @$s;
        my $truth = classify_static($line);
        warn "NOTE: sample intended '$intended' statically classifies as '$truth'\n"
            if $truth ne $intended;
        next unless $truth;
        my $ti = $ENTRY_IDX{$truth};
        for my $e (@ENTRY_DEFS) {
            next if $e->{name} eq $truth;
            $must_precede{$e->{name}}{$truth} = 1
                if $ENTRY_IDX{$e->{name}} > $ti && $line =~ $e->{qr};
        }
    }
    for my $x (map { $_->{name} } @ENTRY_DEFS) {
        my (%seen, @queue);
        @queue = keys %{ $must_precede{$x} // {} };
        while (@queue) {
            my $p = shift @queue;
            next if $seen{$p}++;
            push @queue, keys %{ $must_precede{$p} // {} };
        }
        $ancestors{$x} = [ keys %seen ];
    }
}

## ---------------------------------------------------------------------------
## Scan-policy factory: pinned-closure MTF (P3), parameterized by
## use_guards / use_atomic; plus the mtf-free ceiling.
## ---------------------------------------------------------------------------

sub build_entries {
    my ($use_atomic) = @_;
    return [ map {
        { name     => $_->{name},
          qr       => ($use_atomic && $_->{qr_atomic}) ? $_->{qr_atomic} : $_->{qr},
          guard_fn => $_->{guard_fn} }
    } @ENTRY_DEFS ];
}

sub make_policy {
    my ($kind) = @_;
    my ($free, $use_guards, $use_atomic) = (0, 0, 0);
    $free       = 1 if $kind eq 'mtf-free';
    $use_guards = 1 if $kind =~ /guards/;
    $use_atomic = 1 if $kind =~ /atomic/;
    my @order = @{ build_entries($use_atomic) };
    if ($kind =~ /sel-guards/) {
        # guards only where the failed attempt is expensive (same-head access
        # siblings); everywhere else the plain attempt is cheaper than a guard
        my %keep = map { $_ => 1 } qw(mt12 mt4 mt9);
        $_->{guard_fn} = undef for grep { !$keep{$_->{name}} } @order;
        $use_guards = 1;
    }
    my $winner_skip = 0;
    if ($kind =~ /tail-guards/) {
        # O(1)-bounded guard2 specs on the access siblings only, plus guard
        # skip for the last-winning entry. 10k iteration verdict: premise
        # fails — digit-ending non-access lines pass the prechecks and pay
        # full-line rindex/tr scans; superseded by fam-guards
        my %g2 = map { $_->{name} => $_->{guard2_fn} } @ENTRY_DEFS;
        $_->{guard_fn} = $g2{$_->{name}} for @order;
        $use_guards = 1;
        $winner_skip = 1;
    }
    my $use_family = 0;
    if ($kind =~ /fam2?-guards/) {
        # family-level shared guard: all four access entries require the
        # literal '] "' (bracketed timestamp then quoted request). One
        # memoized index() per line answers "access-shaped?" for the whole
        # family; per-entry lit guards then discriminate within it.
        my %fam = map { $_ => 1 } qw(mt12 mt4 mt9 mt3);
        my %keep = map { $_ => 1 } qw(mt12 mt4 mt9);
        for my $e (@order) {
            $e->{family}   = $fam{$e->{name}} ? 1 : 0;
            $e->{guard_fn} = undef unless $keep{$e->{name}};
        }
        $use_guards = 1;
        $use_family = 1;
        # fam2 variant: while the last winner is itself a family member the
        # stream is presumed access-shaped and the family check is skipped
        # (skipping a superset guard is always sound — it only costs the
        # per-entry guard misses if the presumption is wrong)
        $use_family = 2 if $kind =~ /fam2-guards/;
    }
    my $last_winner;
    my ($attempts, $guard_skips, $reorders) = (0, 0, 0);

    my $classify = sub {
        my ($line) = @_;
        my $fam_ok;                       # memoized per line: undef = not yet tested
        for my $i (0 .. $#order) {
            my $e = $order[$i];
            if ($use_family && $e->{family}
                && !($use_family == 2 && defined $last_winner && $last_winner->{family})) {
                $fam_ok //= index($line, '] "') >= 0 ? 1 : 0;
                if (!$fam_ok) { $guard_skips++; next; }
            }
            if ($use_guards && $e->{guard_fn}
                && !($winner_skip && defined $last_winner && $e == $last_winner)
                && !$e->{guard_fn}->($line)) {
                $guard_skips++;
                next;
            }
            $attempts++;
            if ($line =~ $e->{qr}) {
                my $name = $e->{name};
                $last_winner = $e if $winner_skip || $use_family == 2;
                if ($i > 0) {
                    if ($free) {
                        $reorders++;
                        my ($w) = splice(@order, $i, 1);
                        unshift @order, $w;
                    } else {
                        my %anc = map { $_ => 1 } @{ $ancestors{$name} };
                        my $optimal = 1;
                        for my $j (0 .. $i - 1) {
                            if (!$anc{$order[$j]{name}}) { $optimal = 0; last }
                        }
                        if (!$optimal) {
                            $reorders++;
                            my %front = (%anc, $name => 1);
                            my (@f, @r);
                            for my $x (@order) {
                                if ($front{$x->{name}}) { push @f, $x } else { push @r, $x }
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
    return { classify => $classify, attempts => \$attempts,
             guard_skips => \$guard_skips, reorders => \$reorders };
}

# Final battery set. 'pinned+tail-guards' and 'pinned+fam2-guards' remain
# implemented but were rejected during 10k iteration (tail: digit-ending
# non-access lines defeat the O(1) premise; fam2: the per-entry last-winner
# branch costs what the skipped family check saves).
my @POLICY_KINDS = ('pinned', 'pinned+guards', 'pinned+sel-guards', 'pinned+fam-guards', 'pinned+atomic', 'mtf-free');

## ---------------------------------------------------------------------------
## Phase A — guard soundness (superset property) + classification parity
## ---------------------------------------------------------------------------

sub load_lines {
    my ($file) = @_;
    open my $fh, '<', $file or die "Cannot open file: $file";
    my @lines;
    while (<$fh>) { s/[\r\n]+$//; push @lines, $_; }
    close $fh;
    return \@lines;
}

if ($phase eq 'A' || $phase eq 'all') {
    print STDERR "=== Phase A: guard superset soundness + classification parity ===\n";

    # superset property: pattern match (plain AND atomic) implies guard pass
    my $violations = 0;
    my $checked = 0;
    my $check_line = sub {
        my ($line) = @_;
        for my $e (@ENTRY_DEFS) {
            for my $gkey (qw(guard_fn guard2_fn)) {
                next unless $e->{$gkey};
                if (!$e->{$gkey}->($line)) {
                    for my $q (grep { defined } $e->{qr}, $e->{qr_atomic}) {
                        if ($line =~ $q) {
                            $violations++;
                            print STDERR "  FALSE NEGATIVE: $gkey of $e->{name} rejects a matching line: $line\n";
                            last;
                        }
                    }
                }
            }
        }
        $checked++;
    };
    $check_line->($_->[1]) for @SAMPLES;
    for my $file (@ARGV) {
        my $lines = load_lines($file);
        $check_line->($_) for @$lines;
    }
    printf STDERR "  superset check: %d lines, %d false negatives%s\n",
        $checked, $violations, $violations ? ' — GUARDS UNSOUND' : ' — sound';

    # atomic-pattern equivalence + per-policy classification parity
    for my $file (@ARGV) {
        (my $fixture = $file) =~ s{.*/}{};
        my $lines = load_lines($file);
        my @truth = map { classify_static($_) } @$lines;
        for my $kind (@POLICY_KINDS) {
            my $pol = make_policy($kind);
            my ($div, $first);
            my $n = 0;
            for my $line (@$lines) {
                my $got = $pol->{classify}->($line);
                if ($got ne $truth[$n]) {
                    $div++;
                    $first //= sprintf("line %d: static=%s got=%s", $n + 1, $truth[$n] || '(none)', $got || '(none)');
                }
                $n++;
            }
            printf STDERR "  %-22s %-24s %s\n", $kind, $fixture,
                $div ? "DIVERGES ($div lines; first: $first)" : "identical to static";
        }
    }
}

## ---------------------------------------------------------------------------
## Phase B — timing (1m protocol: absolute wall + ns/line)
## ---------------------------------------------------------------------------

if ($phase eq 'B' || $phase eq 'all') {
    Measure58::tsv_header(\*STDOUT);
    for my $file (@ARGV) {
        (my $fixture = $file) =~ s{.*/}{};
        my $lines = load_lines($file);
        for my $kind (@POLICY_KINDS) {
            my ($attempts, $skips, $reorders);
            my @secs = Measure58::time_runs($runs, sub {
                my $pol = make_policy($kind);
                my $c = $pol->{classify};
                $c->($_) for @$lines;
                $attempts = ${ $pol->{attempts} };
                $skips    = ${ $pol->{guard_skips} };
                $reorders = ${ $pol->{reorders} };
            });
            my ($med, $min, $max) = Measure58::median_min_max(@secs);
            Measure58::emit_tsv(\*STDOUT, "guards-$kind", $fixture, scalar @$lines, 'wall_s', $med, $min, $max);
            Measure58::emit_tsv(\*STDOUT, "guards-$kind", $fixture, scalar @$lines, 'ns_per_line',
                map { $_ / @$lines * 1e9 } $med, $min, $max);
            printf STDERR "  %-22s %-24s attempts/line=%.2f guard_skips/line=%.2f reorders=%d\n",
                $kind, $fixture, $attempts / @$lines, $skips / @$lines, $reorders;
        }
    }
}
