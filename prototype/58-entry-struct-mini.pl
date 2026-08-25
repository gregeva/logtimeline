#!/usr/bin/env perl
#
# 58-entry-struct-mini.pl — registry entry structure & memory (#58 charter
# items 1–2): build-up cost at startup, memory footprint (Devel::Size + RSS),
# and per-line container-access cost in the hot scan loop.
#
# The same fully-loaded 13-entry registry (R1 shape: identity, compiled
# pattern + source, capture->field map, transform list, time contract,
# duration unit, statistics-eligible flag, sample lines, message-metric
# probe declarations, compiled extraction/guard closures, pinned ancestors)
# is materialized in four container shapes:
#
#   aoh   array of hashrefs, fields by name       (the P3/P4 mini shape)
#   hoh   hash of hashrefs by name + order array  (natural for YAML merge;
#                                                  double indirection per step)
#   aoa   array of arrayrefs, constant indices
#   soa   parallel arrays indexed by entry id, scan-order index array
#
# Scan measurement runs the P4-winning configuration (pinned-closure MTF +
# selective access-sibling guards) with identical logic per shape, so the
# measured difference is container access alone. Classification parity vs
# the static cascade is asserted per shape before any timing.
#
# Usage:
#   perl prototype/58-entry-struct-mini.pl [--runs N] [--phase build|scan|all] <fixture> [...]
#
# TSV on stdout (58-measure.pm shape); build/memory report and parity lines
# on stderr.

use strict;
use warnings;
use FindBin;
use Devel::Size qw(total_size);
require "$FindBin::Bin/58-measure.pm";
use Time::HiRes qw(gettimeofday tv_interval);

my $runs = 5;
my $phase = 'all';
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $opt = shift @ARGV;
    if    ($opt eq '--runs')  { $runs = shift @ARGV; }
    elsif ($opt eq '--phase') { $phase = shift @ARGV; }
    else  { die "unknown option $opt\n"; }
}

## ---------------------------------------------------------------------------
## Declarative registry source — the "user-facing" definition data each
## build converts into a live registry. Patterns as source strings (compiled
## per build, as a real startup would).
## ---------------------------------------------------------------------------

my @SPEC = (
    { name => 'mt1std', slug => 'thingworx_standard',
      pattern_src => '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)',
      field_map => [ [1,'timestamp_str'],[2,'category_bucket'],[3,'object'],[4,'instance'],[5,'user'],[6,'session'],[7,'platform'],[8,'thread'],[9,'message'] ],
      transforms => [],
      time => { layout => 'iso_ms', precision => 'ms', tz => 'offset_in_line' },
      duration_unit => 'ms', stats_eligible => 0,
      message_metrics => [ { name => 'bytes', pattern => ' bytes\s*=\s*(\d+)', unit => 'B' },
                           { name => 'duration', pattern => ' durationM[sS]\s*=\s*(\d+)', unit => 'ms' } ],
      samples => [ '2025-05-05 00:00:00.006+0000 [L: ERROR] [O: c.p.a.u.JobPurgeScheduler] [I: ] [U: SuperUser] [S: ] [P: ] [T: pool-1-thread-1] Job purge completed',
                   '2025-05-05 00:00:01.100+0000 [L: INFO] [O: S.c.t.d.e.DSLScript] [I: ] [U: Administrator] [S: ] [P: ] [T: TWEventProcessor-4] Executed service durationMS=42 result bytes=1024 count=7' ] },
    { name => 'mt10', slug => 'connection_server_standard',
      pattern_src => '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) \[([^\]]*)\] ([^ ]*)\s+([^ ]*) - (.*)',
      field_map => [ [1,'timestamp_str'],[2,'thread'],[3,'category_bucket'],[4,'object'],[5,'message'] ],
      transforms => [ 'mask_milliseconds', 'mask_ephemeral_port' ],
      time => { layout => 'iso_ms', precision => 'ms', tz => 'local' },
      duration_unit => 'ms', stats_eligible => 0,
      message_metrics => [],
      samples => [ '2025-08-14 21:00:34.633 [vert.x-eventloop-thread-12] INFO  c.t.c.a.AlwaysOnHttpServerVerticle - Enabled fix for WebSocket compression sometimes causing frames to exceed maximum WebSocket frame size' ] },
    { name => 'mt1gen', slug => 'thingworx_standard',
      pattern_src => '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\+\d{4} \[L: ([^\]]*)\]',
      field_map => [ [1,'timestamp_str'],[2,'category_bucket'] ],
      transforms => [],
      time => { layout => 'iso_ms', precision => 'ms', tz => 'offset_in_line' },
      duration_unit => 'ms', stats_eligible => 0,
      message_metrics => [],
      samples => [ '2025-02-04 12:05:57.481+0000 [L: DEBUG] trailing content that does not carry the full bracket sections' ] },
    { name => 'mt2', slug => 'thingworx_rac_client',
      pattern_src => '^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3}).*? \[[L: ]*([^\]]*)\]',
      field_map => [ [1,'timestamp_str'],[2,'category_bucket'] ],
      transforms => [ 'tr_T_space' ],
      time => { layout => 'iso_ms', precision => 'ms', tz => 'local' },
      duration_unit => 'ms', stats_eligible => 0,
      message_metrics => [],
      samples => [ '[2025-02-04T12:06:22.784] [TRACE] tunnel keepalive sent' ] },
    { name => 'mt12', slug => 'tomcat_codebeamer',
      pattern_src => '^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?\[([0-9.]+)ms\] \[(.+)s\]',
      field_map => [ [2,'timestamp_str'],[3,'message'],[4,'category_bucket'],[5,'bytes'],[6,'duration'] ],
      transforms => [ 'status_bucket','chop_tz','undef_bytes_dash','chop_http_proto','strip_query','session_prefix' ],
      time => { layout => 'apache_clf', precision => 's', tz => 'offset_in_line' },
      duration_unit => 'ms', stats_eligible => 1,
      guard => { lit => 'ms] [' },
      message_metrics => [],
      samples => [ '192.168.223.1 - - [29/Oct/2025:08:52:11 +0000] "GET /urlversioned/202510290803/images/newskin/login_page/icon_qa.png HTTP/1.1" 200 20097 [5ms] [0.005s]' ] },
    { name => 'mt4', slug => 'tomcat_access_common',
      pattern_src => '^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)$',
      field_map => [ [2,'timestamp_str'],[3,'message'],[4,'category_bucket'],[5,'bytes'] ],
      transforms => [ 'status_bucket','chop_tz','undef_bytes_dash','chop_http_proto','strip_query' ],
      time => { layout => 'apache_clf', precision => 's', tz => 'offset_in_line' },
      duration_unit => undef, stats_eligible => 1,
      guard => { tail1 => 1 },
      message_metrics => [],
      samples => [ '43.52.82.172 - - [02/Feb/2025:00:00:11 +0000] "GET /Thingworx/Metrics?x-thingworx-session=false HTTP/1.1" 200 17626' ] },
    { name => 'mt9', slug => 'jboss_access',
      pattern_src => '^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+) "([^"]+)" "([^"]+)" (\d+)$',
      field_map => [ [2,'timestamp_str'],[3,'message'],[4,'category_bucket'],[5,'bytes'],[8,'duration'] ],
      transforms => [ 'status_bucket','chop_tz','chop_http_proto','strip_query' ],
      time => { layout => 'apache_clf', precision => 's', tz => 'offset_in_line' },
      duration_unit => 'ms', stats_eligible => 1,
      guard => { lit => '" "' },
      message_metrics => [],
      samples => [ '127.0.0.1 - - [13/Mar/2025:09:02:41 +0000] "GET /async/prediction/evaluation?limit=99999 HTTP/1.1" 200 51 "-" "Jersey/2.37 (HttpUrlConnection 11.0.22)" 651' ] },
    { name => 'mt3', slug => 'tomcat_access_with_duration',
      pattern_src => '^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?',
      field_map => [ [2,'timestamp_str'],[3,'message'],[4,'category_bucket'],[5,'bytes'],[6,'duration'],[7,'thread'],[8,'session'] ],
      transforms => [ 'status_bucket','chop_tz','undef_bytes_dash','chop_http_proto','strip_query','session_prefix' ],
      time => { layout => 'apache_clf', precision => 's', tz => 'offset_in_line' },
      duration_unit => 'ms_ambiguous', stats_eligible => 1,
      message_metrics => [],
      samples => [ '43.52.82.172 - - [02/Feb/2025:00:00:11 +0000] "GET /Thingworx/Metrics?x-thingworx-session=false HTTP/1.1" 200 17626 295',
                   '10.224.34.60 - - [05/May/2025:00:00:00 +0000] "POST /Thingworx/WS HTTP/1.1" 200 261 1' ] },
    { name => 'mt5', slug => 'connection_server_json',
      pattern_src => '^{"\@timestamp":"([^"]*).*"level":"([^"]*)',
      field_map => [ [1,'timestamp_str'],[2,'category_bucket'] ],
      transforms => [ 'chop_tz_colon','tr_T_space' ],
      time => { layout => 'iso_ms', precision => 'ms', tz => 'offset_in_line' },
      duration_unit => undef, stats_eligible => 0,
      message_metrics => [],
      samples => [ '{"@timestamp":"2025-02-02T21:03:06.725+00:00","@version":1,"message":"Error encountered","logger_name":"x","thread_name":"vert.x-eventloop-thread-16","level":"WARN","level_value":30000}' ] },
    { name => 'mt6', slug => 'java_gc_log',
      pattern_src => '^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3})[+-]\d{4}.*?\[info\]\[gc\s*\] GC\(\d+\) (.+?) (\(.+?\)) (\d[^-]+)->(\d[^(]+)\((\d[^)]+)\) (\d.*)ms',
      field_map => [ [1,'timestamp_str'],[2,'category_bucket'],[3,'message'],[4,'heap_from'],[5,'heap_to'],[6,'heap_size'],[7,'duration'] ],
      transforms => [ 'gc_heap_delta' ],
      time => { layout => 'iso_ms', precision => 'ms', tz => 'offset_in_line' },
      duration_unit => 'ms', stats_eligible => 1,
      message_metrics => [],
      samples => [ '[2025-04-05T11:10:47.867+0000][info][gc] GC(0) Pause Young (Normal) (G1 Evacuation Pause) 2433M->66M(49152M) 18.406ms' ] },
    { name => 'mt7', slug => 'tw_analytics_v2',
      pattern_src => '^([^ ]+)\s+\[(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[.,]\d{3})\] (.*)$',
      field_map => [ [1,'category_bucket'],[2,'timestamp_str'],[3,'message'] ],
      transforms => [ 'tr_comma_dot','tr_T_space','rstrip' ],
      time => { layout => 'iso_ms', precision => 'ms', tz => 'local' },
      duration_unit => undef, stats_eligible => 0,
      message_metrics => [],
      samples => [ 'ERROR [2025-02-19 18:31:00,284] com.thingworx.sdk.impl.transport.netty.NettyChannelHandler: WebSocket error: connection forcibly closed' ] },
    { name => 'mt8', slug => 'tw_analytics_worker',
      pattern_src => '^(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[^ ]*)\s+\[([^]]+)\]\s+(\w+)\s+(.*)$',
      field_map => [ [1,'timestamp_str'],[2,'thread'],[3,'category_bucket'],[4,'message'] ],
      transforms => [ 'tr_comma_dot','tr_T_space','rstrip' ],
      time => { layout => 'iso_flex', precision => 's', tz => 'local' },
      duration_unit => undef, stats_eligible => 0,
      message_metrics => [],
      samples => [ '2025-02-20 10:06:10 [nioEventLoopGroup-2-1] WARN  io.netty.channel.ChannelInitializer - Failed to initialize a channel. Closing: [id: 0x8171dc41]' ] },
    { name => 'mt11', slug => 'tw_edge_c_sdk',
      pattern_src => '^([^ ]+) (\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}[,.]\d+) (.*)',
      field_map => [ [1,'category_bucket'],[2,'timestamp_str'],[3,'message'] ],
      transforms => [ 'chop','strip_pid','hoist_cpp_object' ],
      time => { layout => 'iso_flex_frac', precision => 'ms', tz => 'local' },
      duration_unit => undef, stats_eligible => 0,
      message_metrics => [],
      samples => [ 'INFO 2025-08-09 18:19:04,479 8012 twx_connection.cpp:246 Run Error in the TWX processor thread, have to reinitialize.' ] },
);

## Compile a guard spec (P4 sel-guard set) to a closure.
sub compile_guard {
    my ($spec) = @_;
    return undef unless $spec;
    if (defined $spec->{lit}) {
        my $lit = $spec->{lit};
        return sub { index($_[0], $lit) >= 0 };
    }
    if ($spec->{tail1}) {
        return sub {
            my $p = rindex($_[0], '" ');
            return 0 if $p < 0;
            return (substr($_[0], $p + 2) =~ tr/ //) == 1;
        };
    }
    die "unknown guard spec";
}

## A stand-in extraction closure per entry (dispatch cost itself was P2's
## axis; here it only needs to exist and be reachable so container access
## to it is realistic).
sub compile_extractor {
    my ($spec) = @_;
    my $n = scalar @{ $spec->{field_map} };
    return sub { return $n };
}

## Pinned ancestors (P3-derived closure, hardcoded here — derivation was
## P3's axis; this mini consumes the result).
my %ANCESTORS = (
    mt1gen => [ 'mt1std' ],
    mt2    => [ 'mt1std', 'mt10', 'mt1gen' ],
    mt3    => [ 'mt12', 'mt4', 'mt9' ],
    mt8    => [ 'mt1std', 'mt10', 'mt1gen' ],
);

## ---------------------------------------------------------------------------
## Builders: declarative spec -> live registry, per container shape.
## Every builder compiles patterns, guards, and extractors (real startup work).
## ---------------------------------------------------------------------------

my @FIELDS = qw(name slug qr pattern_src field_map transforms time
                duration_unit stats_eligible guard_fn extract_fn
                message_metrics samples ancestors);
use constant { F_NAME=>0, F_SLUG=>1, F_QR=>2, F_SRC=>3, F_FMAP=>4, F_XFORMS=>5,
               F_TIME=>6, F_DUNIT=>7, F_STATS=>8, F_GUARD=>9, F_EXTRACT=>10,
               F_MM=>11, F_SAMPLES=>12, F_ANC=>13 };

sub build_common {
    my ($spec) = @_;
    return (
        $spec->{name}, $spec->{slug}, qr/$spec->{pattern_src}/, $spec->{pattern_src},
        $spec->{field_map}, $spec->{transforms}, $spec->{time},
        $spec->{duration_unit}, $spec->{stats_eligible},
        compile_guard($spec->{guard}), compile_extractor($spec),
        $spec->{message_metrics}, $spec->{samples},
        $ANCESTORS{$spec->{name}} // [],
    );
}

sub build_aoh {
    my @reg;
    for my $s (@SPEC) {
        my @v = build_common($s);
        push @reg, { map { $FIELDS[$_] => $v[$_] } 0 .. $#FIELDS };
    }
    return \@reg;
}

sub build_hoh {
    my (%reg, @order);
    for my $s (@SPEC) {
        my @v = build_common($s);
        $reg{$s->{name}} = { map { $FIELDS[$_] => $v[$_] } 0 .. $#FIELDS };
        push @order, $s->{name};
    }
    return { reg => \%reg, order => \@order };
}

sub build_aoa {
    my @reg;
    for my $s (@SPEC) {
        push @reg, [ build_common($s) ];
    }
    return \@reg;
}

sub build_soa {
    my %soa = map { $_ => [] } @FIELDS;
    for my $s (@SPEC) {
        my @v = build_common($s);
        push @{ $soa{$FIELDS[$_]} }, $v[$_] for 0 .. $#FIELDS;
    }
    $soa{scan_order} = [ 0 .. $#SPEC ];
    return \%soa;
}

## ---------------------------------------------------------------------------
## Phase build — construction time + memory footprint
## ---------------------------------------------------------------------------

my %BUILDERS = ( aoh => \&build_aoh, hoh => \&build_hoh, aoa => \&build_aoa, soa => \&build_soa );
my @SHAPES = qw(aoh hoh aoa soa);

if ($phase eq 'build' || $phase eq 'all') {
    Measure58::tsv_header(\*STDOUT);
    print STDERR "=== Phase build: construction time (median of $runs x 1000 builds) + memory ===\n";
    for my $shape (@SHAPES) {
        my $builder = $BUILDERS{$shape};
        my @secs = Measure58::time_runs($runs, sub { $builder->() for 1 .. 1000 });
        my ($med, $min, $max) = Measure58::median_min_max(@secs);
        Measure58::emit_tsv(\*STDOUT, "struct-$shape", 'registry-build', 1000, 'us_per_build',
            map { $_ / 1000 * 1e6 } $med, $min, $max);

        my $rss_before = Measure58::rss_kb();
        my $reg = $builder->();
        my $bytes = total_size($reg);
        my $rss_after = Measure58::rss_kb();
        Measure58::emit_tsv(\*STDOUT, "struct-$shape", 'registry-memory', scalar @SPEC, 'devel_size_bytes',
            ($bytes) x 3);
        printf STDERR "  %-4s build %.1f us  total_size %d bytes (%.0f/entry)  rss_delta %d kB\n",
            $shape, $med / 1000 * 1e6, $bytes, $bytes / @SPEC, $rss_after - $rss_before;
    }
}

## ---------------------------------------------------------------------------
## Phase scan — per-shape classification loop (pinned + sel-guards, P4
## winner), identical logic, container access is the variable. After each
## match, five metadata fields are read (extractor, unit, stats flag, slug,
## precision) — the realistic per-line consumption.
## ---------------------------------------------------------------------------

sub classify_static_ref {
    my ($reg_aoh) = @_;
    return sub {
        my ($line) = @_;
        for my $e (@$reg_aoh) {
            return $e->{name} if $line =~ $e->{qr};
        }
        return '';
    };
}

sub make_scanner {
    my ($shape) = @_;
    my $sink = 0;

    if ($shape eq 'aoh' || $shape eq 'hoh') {
        # identical logic, direct {field} access; hoh adds the name->entry
        # lookup per scan step (its inherent cost)
        my ($reg, @order);
        if ($shape eq 'hoh') {
            my $b = build_hoh();
            $reg = $b->{reg};
            @order = @{ $b->{order} };           # names
        } else {
            @order = @{ build_aoh() };           # entry refs
        }
        my $hoh = $shape eq 'hoh';
        my $classify = sub {
            my ($line) = @_;
            for my $i (0 .. $#order) {
                my $e = $hoh ? $reg->{$order[$i]} : $order[$i];
                my $g = $e->{guard_fn};
                if ($g && !$g->($line)) { next; }
                if ($line =~ $e->{qr}) {
                    if ($i > 0) {
                        my %anc = map { $_ => 1 } @{ $e->{ancestors} };
                        my $optimal = 1;
                        for my $j (0 .. $i - 1) {
                            my $pn = $hoh ? $order[$j] : $order[$j]{name};
                            if (!$anc{$pn}) { $optimal = 0; last }
                        }
                        if (!$optimal) {
                            my %front = (%anc, $e->{name} => 1);
                            my (@f, @r);
                            for my $o (@order) {
                                my $on = $hoh ? $o : $o->{name};
                                if ($front{$on}) { push @f, $o } else { push @r, $o }
                            }
                            @order = (@f, @r);
                        }
                    }
                    $sink += $e->{extract_fn}->() + $e->{stats_eligible} + length($e->{slug})
                           + (defined $e->{duration_unit} ? 1 : 0) + length($e->{time}{precision});
                    return $e->{name};
                }
            }
            return '';
        };
        return { classify => $classify, sink => \$sink };
    }

    if ($shape eq 'aoa') {
        my @order = @{ build_aoa() };
        my $classify = sub {
            my ($line) = @_;
            for my $i (0 .. $#order) {
                my $e = $order[$i];
                my $g = $e->[F_GUARD];
                if ($g && !$g->($line)) { next; }
                if ($line =~ $e->[F_QR]) {
                    if ($i > 0) {
                        my %anc = map { $_ => 1 } @{ $e->[F_ANC] };
                        my $optimal = 1;
                        for my $j (0 .. $i - 1) {
                            if (!$anc{ $order[$j][F_NAME] }) { $optimal = 0; last }
                        }
                        if (!$optimal) {
                            my %front = (%anc, $e->[F_NAME] => 1);
                            my (@f, @r);
                            for my $o (@order) {
                                if ($front{ $o->[F_NAME] }) { push @f, $o } else { push @r, $o }
                            }
                            @order = (@f, @r);
                        }
                    }
                    $sink += $e->[F_EXTRACT]->() + $e->[F_STATS] + length($e->[F_SLUG])
                           + (defined $e->[F_DUNIT] ? 1 : 0) + length($e->[F_TIME]{precision});
                    return $e->[F_NAME];
                }
            }
            return '';
        };
        return { classify => $classify, sink => \$sink };
    }

    if ($shape eq 'soa') {
        my $soa = build_soa();
        my ($qrs, $guards, $names, $ancs, $extracts, $stats, $slugs, $dunits, $times) =
            @$soa{qw(qr guard_fn name ancestors extract_fn stats_eligible slug duration_unit time)};
        my @order = @{ $soa->{scan_order} };
        my $classify = sub {
            my ($line) = @_;
            for my $i (0 .. $#order) {
                my $id = $order[$i];
                my $g = $guards->[$id];
                if ($g && !$g->($line)) { next; }
                if ($line =~ $qrs->[$id]) {
                    if ($i > 0) {
                        my %anc = map { $_ => 1 } @{ $ancs->[$id] };
                        my $optimal = 1;
                        for my $j (0 .. $i - 1) {
                            if (!$anc{ $names->[ $order[$j] ] }) { $optimal = 0; last }
                        }
                        if (!$optimal) {
                            my %front = (%anc, $names->[$id] => 1);
                            my (@f, @r);
                            for my $o (@order) {
                                if ($front{ $names->[$o] }) { push @f, $o } else { push @r, $o }
                            }
                            @order = (@f, @r);
                        }
                    }
                    $sink += $extracts->[$id]->() + $stats->[$id] + length($slugs->[$id])
                           + (defined $dunits->[$id] ? 1 : 0) + length($times->[$id]{precision});
                    return $names->[$id];
                }
            }
            return '';
        };
        return { classify => $classify, sink => \$sink };
    }
    die "unknown shape $shape";
}

if ($phase eq 'scan' || $phase eq 'all') {
    Measure58::tsv_header(\*STDOUT) if $phase eq 'scan';
    die "scan phase needs fixture arguments\n" unless @ARGV;
    my $static = classify_static_ref(build_aoh());
    for my $file (@ARGV) {
        (my $fixture = $file) =~ s{.*/}{};
        open my $fh, '<', $file or die "Cannot open file: $file";
        my @lines;
        while (<$fh>) { s/[\r\n]+$//; push @lines, $_; }
        close $fh;
        my @truth = map { $static->($_) } @lines;

        for my $shape (@SHAPES) {
            # parity gate before timing
            my $sc = make_scanner($shape);
            my $div = 0;
            for my $k (0 .. $#lines) {
                $div++ if $sc->{classify}->($lines[$k]) ne $truth[$k];
            }
            if ($div) {
                print STDERR "  $shape $fixture PARITY FAILURE ($div lines) — skipping timing\n";
                next;
            }
            my $sink;
            my @secs = Measure58::time_runs($runs, sub {
                my $s = make_scanner($shape);
                my $c = $s->{classify};
                $c->($_) for @lines;
                $sink = ${ $s->{sink} };
            });
            my ($med, $min, $max) = Measure58::median_min_max(@secs);
            Measure58::emit_tsv(\*STDOUT, "struct-$shape", $fixture, scalar @lines, 'ns_per_line',
                map { $_ / @lines * 1e9 } $med, $min, $max);
            printf STDERR "  %-4s %-24s parity OK sink=%s\n", $shape, $fixture, $sink;
        }
    }
}
