#!/usr/bin/env perl
#
# 384-variant-selection-mini.pl — Drop 1.5 (#384) prototype against ltl's
# live format-registry code.
#
# Loads ltl's source up to its `## MAIN ##` marker and evals it together
# with the driver below (the `__DATA__` section), so the driver shares the
# script's file-scoped lexicals (@format_registry, @format_scan_order,
# %format_scan_sub_cache, the record scalars) and drives the real
# build_format_registry() / compile_format_scan_sub() /
# sample_file_for_detection() — the production mechanism, not a copy
# (the #58 F9 lesson: a convenience baseline measures the wrapper).
#
# Four jobs (features/log-format-registry.md § Drop 1.5, 2026-08-23):
#   1  D47  per-file variant member selection: rebuild cost (upper bound),
#           cold compile per new (order, members) signature, warm cache-hit
#           flip, and steady-loop scan throughput with groups present.
#   2  D52  probe costs: (a) out-of-range month guard in the generated
#           block's cache-miss branch, (b) monotonicity 1-in-N in the loop,
#           full probes over the D53 sample (one-time per file; x200 for
#           the many-small-files case).
#   3  I1   evidence weights: every D51 fixture (name + real content)
#           scored; invariants "stem alone decides" and "extension alone
#           never decides" asserted.
#   4  I4   rotation index: producer-true names decomposed through the D45
#           component matcher; reports whether any pair is separable only
#           by the index form.
#
# Usage:
#   perl prototype/384-variant-selection-mini.pl [--runs N] [--size 100k|1m]
#        [--jobs 1,2,3,4] [--fixtures DIR]
#
# TSV rows on stdout (job<TAB>candidate<TAB>fixture<TAB>lines<TAB>metric
# <TAB>median<TAB>min<TAB>max); narrative on stderr.

use strict;
use warnings;
use FindBin;

my $ltl_path = "$FindBin::Bin/../ltl";
my $ltl_src = do { open my $fh, '<', $ltl_path or die "open $ltl_path: $!"; local $/; <$fh> };
$ltl_src =~ s/^## MAIN ##.*\z//ms or die "no ## MAIN ## marker in $ltl_path";
my $driver = do { local $/; <DATA> };
our @PROTO_ARGV = @ARGV;
@ARGV = ();
eval "#line 1 \"$ltl_path\"\n$ltl_src\n;\n#line 1 \"384-driver\"\n$driver";
die $@ if $@;
exit 0;

__DATA__
# ---------------------------------------------------------------------------
# Driver: runs inside ltl's file scope.
# ---------------------------------------------------------------------------
use Time::HiRes qw(gettimeofday tv_interval);
use Getopt::Long qw(GetOptionsFromArray);

my ($P_RUNS, $P_SIZE, $P_JOBS, $P_FIX) = (3, '100k', '1,2,3,4', '/tmp/ltl-58-fixtures');
GetOptionsFromArray(\@main::PROTO_ARGV,
    'runs=i' => \$P_RUNS, 'size=s' => \$P_SIZE, 'jobs=s' => \$P_JOBS, 'fixtures=s' => \$P_FIX)
    or die "bad options\n";
my %P_JOB = map { $_ => 1 } split /,/, $P_JOBS;
my $LOGS = "$FindBin::Bin/../logs";

sub p_note { print STDERR "# @_\n" }
sub p_row  { print join("\t", @_), "\n" }
sub p_stats {   # list of numbers -> (median, min, max)
    my @s = sort { $a <=> $b } @_;
    my $n = @s; return (0,0,0) unless $n;
    my $med = $n % 2 ? $s[($n-1)/2] : ($s[$n/2-1] + $s[$n/2]) / 2;
    return ($med, $s[0], $s[-1]);
}
sub p_time {    # (runs, coderef) -> list of elapsed seconds (one untimed warmup)
    my ($runs, $code) = @_;
    $code->();
    my @t;
    for (1 .. $runs) { my $t0 = [gettimeofday]; $code->(); push @t, tv_interval($t0) }
    return @t;
}
sub p_count_lines { my ($f) = @_; open my $fh, '<', $f or return 0; my $n = 0; $n++ while <$fh>; close $fh; $n }

# ---------------------------------------------------------------------------
# Variant members (D47): full entries sharing the default member's pattern.
# ---------------------------------------------------------------------------
my @IR_SAMPLES = (
    '2025-28-01 07:26:36.541 [vert.x-eventloop-thread-0] INFO  c.t.i.IntegrationRuntimeConfiguration - Reading from config file D:\THINGW~1\integration-runtime\integrationRuntime-settings.json.encrypted',
    '2025-28-01 07:26:36.635 [vert.x-eventloop-thread-0] INFO  c.t.s.SecurityManagerBootstrapper - initializing KeyStore provider',
);
my @IR_EXPECT = (
    [ '2025-28-01 07:26:36', 'INFO', 'c.t.i.IntegrationRuntimeConfiguration', undef, undef, undef, undef, 'vert.x-eventloop-thread-0', 'Reading from config file D:\THINGW~1\integration-runtime\integrationRuntime-settings.json.encrypted', undef, undef, '0', '0' ],
    [ '2025-28-01 07:26:36', 'INFO', 'c.t.s.SecurityManagerBootstrapper', undef, undef, undef, undef, 'vert.x-eventloop-thread-0', 'initializing KeyStore provider', undef, undef, '0', '0' ],
);

# Filename evidence declarations (D45) keyed by entry name. `placement`
# says where rotation/date suffixes sit relative to the extension:
#   before — stem[.date][.index]ext        (logback, Tomcat)
#   after  — stem ext[-date][.index]       (httpd logrotate, HotSpot GC)
my %FILENAME = (
    mt1std => { stem => '(?:Application|Error|ScriptError|Script|Communication|AkkaCommunication|Auth|Configuration|Database|Security)Log',
                date => 'iso', index => 'dot_n', ext => '.log', placement => 'before' },
    mt3    => { stem => 'localhost_access_log', date => 'iso', ext => '.txt', placement => 'before' },
    mt3us  => { stem => 'access(?:_log)?', date => 'compact', ext => '.log', placement => 'after' },
    mt6    => { stem => 'gc(?:-[^.]+)?', index => 'dot_n', ext => '.out', placement => 'after' },
    mt10   => { stem => 'cxserver', index => 'dash_n_n', ext => '.log', placement => 'before' },
    mt10ir => { stem => 'IntegrationRuntime-[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}', ext => '.log', placement => 'before' },
);
my %GROUP = ( mt3 => 'access_duration', mt3us => 'access_duration', mt10 => 'cxserver_layout', mt10ir => 'cxserver_layout' );
my %GROUP_DEFAULT = ( access_duration => 'mt3', cxserver_layout => 'mt10' );

my $orig_specs = \&format_registry_specs;
sub variant_specs {
    my @base = $orig_specs->();
    my %by = map { $_->{name} => $_ } @base;
    my $mt3us  = { %{ $by{mt3} }, name => 'mt3us', slug => 'httpd_access_with_duration',
                   duration_unit => 'us', unit_ambiguous => 0 };
    my $mt10ir = { %{ $by{mt10} }, name => 'mt10ir', slug => 'integration_runtime_standard',
                   time => { %{ $by{mt10}{time} }, layout => 'iso_ms_ddmm' },
                   samples => \@IR_SAMPLES, expect => \@IR_EXPECT };
    return ( \@base, { mt3us => $mt3us, mt10ir => $mt10ir } );
}

# Selection: group => member name. The registry is built with exactly one
# member per identical pattern per group (D47); `none` = today's registry
# (no groups at all — the base arm).
my %SELECT;
my $GROUPS_ON = 0;
{
    no warnings 'redefine';
    *format_registry_specs = sub {
        my ($base, $variants) = variant_specs();
        return @$base unless $GROUPS_ON;
        # Pinned-ancestor constraints are a property of the group's shared
        # pattern, not of the member: every other entry's declared
        # expect_ancestors that names a group member is rewritten to the
        # selected member (finding F1 — production keys this by group).
        my %rename = map { $GROUP_DEFAULT{$_} => $SELECT{$_} } grep { $SELECT{$_} } keys %SELECT;
        return map {
            my $g = $GROUP{ $_->{name} };
            my $spec = ($g && $SELECT{$g} && $SELECT{$g} ne $_->{name}) ? $variants->{ $SELECT{$g} } : $_;
            %rename ? { %$spec, expect_ancestors => [ map { $rename{$_} // $_ } @{ $spec->{expect_ancestors} // [] } ] } : $spec
        } @$base;
    };
}

# The generated block's time parse uses fixed substr offsets; the ddMM
# layout swaps the day/month reads. Optionally injects probe (a) — the
# out-of-range month guard — into the cache-miss branch only.
my $PROBE_A_IN_BLOCK = 0;
my $PROBE_B_IN_BLOCK = 0;
our $probe_a_hits = 0;
our $probe_b_viol = 0;
my $orig_block_src = \&format_entry_block_src;
{
    no warnings 'redefine';
    *format_entry_block_src = sub {
        my ($spec) = @_;
        my @r = $orig_block_src->(@_);
        my $layout = $spec->{time}{layout} // '';
        my ($mo, $dy) = (5, 8);
        if ($layout eq 'iso_ms_ddmm') {
            $r[2] =~ s/substr\(\$timestamp_str, 8, 2\), substr\(\$timestamp_str, 5, 2\) - 1/substr(\$timestamp_str, 5, 2), substr(\$timestamp_str, 8, 2) - 1/
                or die "ddmm patch failed for $spec->{name}";
            ($mo, $dy) = (8, 5);
        }
        if ($PROBE_A_IN_BLOCK && $layout ne 'apache_clf' && $layout ne 'csv') {
            # Guard sits in the cache-miss branch: evaluated once per
            # distinct timestamp string, never once per line.
            $r[2] =~ s/(\n\s*\$timestamp = \$format_last_ts_epoch = \$timestamp_cache\{\$timestamp_str\} = )/\n    if (substr(\$timestamp_str, $mo, 2) > 12) { \$main::probe_a_hits++; \$timestamp = \$format_last_ts_epoch = \$timestamp_cache{\$timestamp_str} = \$format_last_ts_epoch \/\/ 0; \$format_last_ts_str = \$timestamp_str; }\n    else { \$timestamp = \$format_last_ts_epoch = \$timestamp_cache{\$timestamp_str} = /
                or die "probe-a patch failed for $spec->{name}";
            $r[2] =~ s/(\$format_last_ts_str = \$timestamp_str;\n\})\z/$1\n}/;
            if ($PROBE_B_IN_BLOCK) {
                # monotonicity over DISTINCT timestamps: the new epoch against
                # the previous distinct one, inside the same miss branch.
                $r[2] =~ s/else \{ (\$timestamp = \$format_last_ts_epoch = \$timestamp_cache\{\$timestamp_str\} = )/else { my \$__prev = \$format_last_ts_epoch; $1/
                    or die "probe-b patch failed for $spec->{name}";
                $r[2] =~ s/(\n\s*\$format_last_ts_str = \$timestamp_str;\n\}\n\})\z/\n    \$main::probe_b_viol++ if defined \$__prev && \$timestamp < \$__prev;$1/
                    or die "probe-b tail patch failed for $spec->{name}";
            }
        }
        return @r;
    };
}

sub p_build {   # (groups_on, %select) -> elapsed seconds of build_format_registry
    my ($on, %sel) = @_;
    $GROUPS_ON = $on; %SELECT = %sel;
    my $t0 = [gettimeofday];
    build_format_registry();
    return tv_interval($t0);
}
sub p_sig { join(',', map { $_->[FR_NAME] } @format_scan_order) }

sub p_scan_file {   # scan-only loop over a file through the live scan sub
    my ($path, $mono_every) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    my ($n, $viol, $prev) = (0, 0, undef);
    ( $format_last_ts_str, $format_last_ts_epoch ) = ( '', undef );
    %timestamp_cache = ();
    if ($mono_every) {
        my $mask = $mono_every - 1;
        while (my $line = <$fh>) {
            chomp $line;
            my $e = $format_scan_sub->($line) or next;
            if (($n++ & $mask) == 0) {
                $viol++ if defined $prev && $timestamp < $prev;
                $prev = $timestamp;
            }
        }
    } else {
        while (my $line = <$fh>) {
            chomp $line;
            $format_scan_sub->($line) or next;
            $n++;
        }
    }
    close $fh;
    return ($n, $viol);
}

# ---------------------------------------------------------------------------
# Job 1 — D47 member selection cost
# ---------------------------------------------------------------------------
if ($P_JOB{1}) {
    p_note("JOB 1 — D47: per-file member selection");
    for my $arm ( [ base => 0, {} ],
                  [ 'groups-default' => 1, {} ],
                  [ 'groups-variant' => 1, { access_duration => 'mt3us', cxserver_layout => 'mt10ir' } ] ) {
        my ($name, $on, $sel) = @$arm;
        my @t = p_time($P_RUNS, sub { p_build($on, %$sel) });
        my ($m, $lo, $hi) = p_stats(@t);
        p_row(1, $name, '-', 0, 'build_format_registry_ms', map { sprintf '%.2f', $_ * 1000 } $m, $lo, $hi);
        p_note(sprintf "%-16s build %.2f ms [%.2f–%.2f]  cache entries=%d  order=%s", $name, $m*1000, $lo*1000, $hi*1000, scalar(keys %format_scan_sub_cache), p_sig());
    }
    # Flip cost: the registry is built under the default members; a flip
    # to the variant member for the CURRENT order is (cold) one
    # compile_format_scan_sub, then (warm) one hash lookup keyed by
    # order + members.
    p_build(1, access_duration => 'mt3us', cxserver_layout => 'mt10ir');
    my @cold = p_time($P_RUNS, sub { compile_format_scan_sub($format_registry_opts) });
    my ($m, $lo, $hi) = p_stats(@cold);
    p_row(1, 'flip-cold-compile', '-', 0, 'compile_scan_sub_ms', map { sprintf '%.3f', $_ * 1000 } $m, $lo, $hi);
    p_note(sprintf "flip (cold: new order+members signature) %.3f ms [%.3f–%.3f]", $m*1000, $lo*1000, $hi*1000);
    my %members_cache = ( p_sig() . '|mt3us,mt10ir' => $format_scan_sub );
    my $key = p_sig() . '|mt3us,mt10ir';
    my @warm = p_time($P_RUNS, sub { my $s; for (1 .. 100_000) { $s = $members_cache{$key} } });
    ($m, $lo, $hi) = p_stats(@warm);
    p_row(1, 'flip-warm-lookup', '-', 100000, 'lookup_ns', map { sprintf '%.1f', $_ * 1e9 / 100_000 } $m, $lo, $hi);
    p_note(sprintf "flip (warm: cache hit) %.1f ns per lookup", $m * 1e9 / 100_000);

    # Steady-loop throughput with groups present vs today's registry.
    my @fixtures = grep { -f $_->[1] }
        map { [ "$_-$P_SIZE", "$P_FIX/$_-$P_SIZE.log" ] } qw(pure-access concat-pair twx-blend);
    my $cx = (glob("$LOGS/ThingworxLogs/CXS/cxserver.1-*.log"))[0];
    push @fixtures, [ 'cxserver', $cx ] if $cx;
    for my $fx (@fixtures) {
        my ($label, $path) = @$fx;
        my $lines = p_count_lines($path);
        for my $arm ( [ base => 0, {} ], [ 'groups-default' => 1, {} ] ) {
            my ($name, $on, $sel) = @$arm;
            p_build($on, %$sel);
            my $matched;
            my @t = p_time($P_RUNS, sub { ($matched) = p_scan_file($path, 0) });
            my ($m, $lo, $hi) = p_stats(@t);
            p_row(1, $name, $label, $lines, 'scan_s', map { sprintf '%.3f', $_ } $m, $lo, $hi);
            p_note(sprintf "%-16s %-22s %8d lines  scan %.3f s [%.3f–%.3f]  matched=%d", $name, $label, $lines, $m, $lo, $hi, $matched);
        }
    }
    # The IR member on IR content (the only content it can legally read).
    my $ir = (glob("$LOGS/IntegrationRuntimeLogs/IntegrationRuntime-*.log"))[0];
    if ($ir) {
        p_build(1, cxserver_layout => 'mt10ir');
        my $lines = p_count_lines($ir);
        my $matched;
        my @t = p_time($P_RUNS, sub { ($matched) = p_scan_file($ir, 0) });
        my ($m, $lo, $hi) = p_stats(@t);
        p_row(1, 'groups-variant', 'integration-runtime', $lines, 'scan_s', map { sprintf '%.4f', $_ } $m, $lo, $hi);
        p_note(sprintf "%-16s %-22s %8d lines  scan %.4f s  matched=%d (ddMM layout, no fatal)", 'groups-variant', 'integration-runtime', $lines, $m, $matched);
    }
}

# ---------------------------------------------------------------------------
# Job 2 — D52 probe costs
# ---------------------------------------------------------------------------
if ($P_JOB{2}) {
    p_note("JOB 2 — D52: probe costs");
    my @fixtures = grep { -f $_->[1] }
        map { [ "$_-$P_SIZE", "$P_FIX/$_-$P_SIZE.log" ] } qw(pure-access twx-blend);
    for my $fx (@fixtures) {
        my ($label, $path) = @$fx;
        my $lines = p_count_lines($path);
        my %t;
        for my $arm ( [ 'probes-off' => 0, 0 ], [ 'probe-a-miss-branch' => 1, 0 ],
                      [ 'probe-b-every-line' => 0, 1 ], [ 'probe-b-1in256' => 0, 256 ],
                      [ 'probe-a+b-1in256' => 1, 256 ],
                      [ 'probe-a+b-miss-branch' => 1, 0, 1 ] ) {
            my ($name, $pa, $pb, $pbb) = @$arm;
            $PROBE_A_IN_BLOCK = $pa; $PROBE_B_IN_BLOCK = $pbb // 0; $probe_a_hits = 0; $probe_b_viol = 0;
            p_build(1);
            my ($matched, $viol);
            my @tt = p_time($P_RUNS, sub { ($matched, $viol) = p_scan_file($path, $pb) });
            my ($m, $lo, $hi) = p_stats(@tt);
            $t{$name} = $m;
            p_row(2, $name, $label, $lines, 'scan_s', map { sprintf '%.3f', $_ } $m, $lo, $hi);
            p_note(sprintf "%-20s %-18s %8d lines  %.3f s [%.3f–%.3f]  Δ vs off %+.3f s/M  probe_a_hits=%d mono_viol=%d",
                $name, $label, $lines, $m, $lo, $hi, ($m - ($t{'probes-off'} // $m)) / $lines * 1e6, $probe_a_hits, ($viol // 0) + $probe_b_viol);
        }
    }
    $PROBE_A_IN_BLOCK = 0; $PROBE_B_IN_BLOCK = 0;

    # Full probes over the D53 sample: one-time per-file cost.
    p_build(1);
    my @files = grep { defined && -f } (
        (glob("$LOGS/IntegrationRuntimeLogs/IntegrationRuntime-*.log"))[0],
        (glob("$LOGS/ThingworxLogs/CXS/cxserver.1-*.log"))[0],
        "$LOGS/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log",
        "$LOGS/ThingworxLogs/ApplicationLog.2025-05-06.0.log",
    );
    for my $f (@files) {
        my $obs = sample_file_for_detection($f) or next;
        my @t = p_time($P_RUNS, sub { p_full_probes($obs->{lines}, $f) });
        my ($m, $lo, $hi) = p_stats(@t);
        my $r = p_full_probes($obs->{lines}, $f);
        p_row(2, 'sample-probes', (split m{/}, $f)[-1], scalar @{ $obs->{lines} }, 'probe_us', map { sprintf '%.0f', $_ * 1e6 } $m, $lo, $hi);
        p_note(sprintf "sample probes %-60s sample=%.0f us  probes=%.0f us [%.0f–%.0f] over %d lines  x200 files=%.1f ms  MMdd{oor=%d viol=%d} ddMM{oor=%d viol=%d} span_MMdd=%s span_ddMM=%s",
            (split m{/}, $f)[-1], $obs->{elapsed_us}, $m*1e6, $lo*1e6, $hi*1e6, scalar @{ $obs->{lines} }, ($m + $obs->{elapsed_us}/1e6) * 200 * 1000,
            $r->{mmdd}{oor}, $r->{mmdd}{viol}, $r->{ddmm}{oor}, $r->{ddmm}{viol}, $r->{mmdd}{span} // '-', $r->{ddmm}{span} // '-');
    }
    p_note(sprintf "memory: probe conclusions retained per file = %d bytes (Devel::Size total_size of the result hash)", total_size(p_full_probes(sample_file_for_detection($files[0])->{lines}, $files[0])));
}

# Full probes (D52 a/b/c) over a list of sample lines, under both date
# layouts; consumes lines, never a file position (D53).
sub p_full_probes {
    my ($lines, $path) = @_;
    my $res = { mmdd => { oor => 0, viol => 0, n => 0 }, ddmm => { oor => 0, viol => 0, n => 0 } };
    my %prev;
    my (%first, %last);
    for my $line (@$lines) {
        my ($ts) = $line =~ /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/ or next;
        my ($y, $a, $b, $h, $mi, $s) = $ts =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
        for my $lay ( [ mmdd => $a, $b ], [ ddmm => $b, $a ] ) {
            my ($k, $mo, $dy) = @$lay;
            my $r = $res->{$k};
            $r->{n}++;
            if ($mo > 12 || $dy > 31) { $r->{oor}++; next }
            my $epoch = eval { timegm($s, $mi, $h, $dy, $mo - 1, $y) };
            if (!defined $epoch) { $r->{oor}++; next }
            $r->{viol}++ if defined $prev{$k} && $epoch < $prev{$k};
            $prev{$k} = $epoch;
            $first{$k} //= $epoch; $last{$k} = $epoch;
        }
    }
    for my $k (qw(mmdd ddmm)) {
        $res->{$k}{span} = defined $first{$k} ? sprintf('%.1fd', ($last{$k} - $first{$k}) / 86400) : undef;
    }
    # (c) filename-date cross-check
    my $name = (split m{/}, $path)[-1];
    if (my ($fy, $fm, $fd) = $name =~ /(\d{4})-(\d{2})-(\d{2})/) {
        for my $k (qw(mmdd ddmm)) {
            next unless defined $first{$k};
            my @g = gmtime($first{$k});
            $res->{$k}{fdate} = ($g[5] + 1900 == $fy && $g[4] + 1 == $fm && $g[3] == $fd) ? 'match' : 'mismatch';
        }
    }
    return $res;
}

# ---------------------------------------------------------------------------
# D45 component matcher — composes the full-name matcher from declared
# components; strips compression suffixes; returns which components hit.
# ---------------------------------------------------------------------------
my %DATE_RE  = ( iso => '\d{4}-\d{2}-\d{2}', compact => '\d{8}' );
my %INDEX_RE = ( dot_n => '\d+', dash_n_n => '\d+-\d+' );
sub p_match_filename {
    my ($decl, $name) = @_;
    $name =~ s/\.(?:gz|bz2|xz|zst)\z//;
    my $ext = defined $decl->{ext} ? quotemeta $decl->{ext} : undef;
    my $date = $decl->{date}  ? $DATE_RE{ $decl->{date} }   : undef;
    my $idx  = $decl->{index} ? $INDEX_RE{ $decl->{index} } : undef;
    my $re;
    if (($decl->{placement} // 'before') eq 'before') {
        $re = "^(?<stem>$decl->{stem})" . ($date ? "(?:\\.(?<date>$date))?" : '') . ($idx ? "(?:\\.(?<index>$idx))?" : '')
            . "(?:(?<ext>$ext)|\\.[A-Za-z][A-Za-z0-9]*)?\\z";
    } else {
        $re = "^(?<stem>$decl->{stem})(?:(?<ext>$ext)|\\.[A-Za-z][A-Za-z0-9]*)?" . ($date ? "(?:-(?<date>$date))?" : '') . ($idx ? "(?:\\.(?<index>$idx))?" : '') . "\\z";
    }
    return undef unless $name =~ /$re/;
    return { stem => 1, ext => (defined $+{ext} ? 'match' : 'absent'), date => $+{date}, index => $+{index} };
}

# ---------------------------------------------------------------------------
# Job 3 — I1 evidence weights over the D51 fixture table
# ---------------------------------------------------------------------------
# Candidate weights (one table in source, D46). Every signal is additive;
# the group default holds a standing credit equal to the extension weight
# so an extension alone ties and ties stay on the default.
my %W = ( shape => 1.0, stem => 3.0, ext => 1.0, fdate => 0.5, index => 0.25, default => 1.0, mono_per_violation => 0.5, mono_cap => 1.0 );

sub p_score {   # (staged name, sample lines, path-for-fdate) -> per-group decision
    my ($name, $lines, $path) = @_;
    my $probes = p_full_probes($lines, $name);
    my %out;
    for my $g (keys %GROUP_DEFAULT) {
        my @members = grep { $GROUP{$_} eq $g } keys %GROUP;
        my ($base, $variants) = variant_specs();
        my %spec = ( (map { $_->{name} => $_ } @$base), %$variants );
        my %score; my %why;
        for my $m (@members) {
            my $pat = qr/$spec{$m}{pattern_src}/;
            my $shape = grep { $_ =~ $pat } @$lines;
            if (!$shape) { $score{$m} = 0; $why{$m} = 'no-shape'; next }
            my $s = $W{shape}; my @why = ('shape');
            if ($m eq $GROUP_DEFAULT{$g}) { $s += $W{default}; push @why, 'default' }
            # Every signal is additive and independent (architect, 2026-08-23):
            # the extension counts whether or not the stem matched.
            my $fm = p_match_filename($FILENAME{$m}, $name);
            if ($fm) {
                $s += $W{stem}; push @why, 'stem';
                if (defined $fm->{index}) { $s += $W{index}; push @why, 'index' }
            }
            my $ext_hit = $fm ? $fm->{ext} eq 'match'
                        : (defined $FILENAME{$m}{ext} && $name =~ /\Q$FILENAME{$m}{ext}\E(?:-\d{8})?(?:\.\d+)?(?:\.(?:gz|bz2|xz|zst))?\z/);
            if ($ext_hit) { $s += $W{ext}; push @why, 'ext' }
            my $lay = ($spec{$m}{time}{layout} // '') eq 'iso_ms_ddmm' ? 'ddmm' : 'mmdd';
            if ($g eq 'cxserver_layout') {
                my $pr = $probes->{$lay};
                if ($pr->{oor}) { $s = 0; push @why, "probe-a:oor=$pr->{oor}" }
                elsif (($pr->{fdate} // '') eq 'mismatch') { $s = 0; push @why, 'probe-c:mismatch' }
                else {
                    if (($pr->{fdate} // '') eq 'match') { $s += $W{fdate}; push @why, 'fdate' }
                    my $pen = $pr->{viol} * $W{mono_per_violation}; $pen = $W{mono_cap} if $pen > $W{mono_cap};
                    if ($pen) { $s -= $pen; push @why, "probe-b:viol=$pr->{viol}" }
                }
            }
            $score{$m} = $s; $why{$m} = join '+', @why;
        }
        my @live = grep { $score{$_} > 0 } @members;
        my ($sel, $basis, $conf);
        if (!@live) { ($sel, $basis, $conf) = ($GROUP_DEFAULT{$g}, 'none', 0) }
        else {
            my @rank = sort { $score{$b} <=> $score{$a} || ($a eq $GROUP_DEFAULT{$g} ? -1 : 1) } @live;
            $sel = $rank[0];
            my $tot = 0; $tot += $score{$_} for @live;
            $conf = $score{$sel} / $tot;
            $basis = (@live == 1 && $why{$sel} =~ /probe-a|probe-c/) ? 'evidence'
                   : ($why{$sel} =~ /stem|fdate/) ? 'evidence'
                   : (@live > 1 && $score{$rank[0]} == $score{$rank[1]}) ? 'default' : 'default';
            $basis = 'evidence' if grep { $why{$_} =~ /probe-a:oor/ } @members;
        }
        $out{$g} = { selected => $sel, basis => $basis, confidence => $conf, scores => { %score }, why => { %why } };
    }
    return \%out;
}

if ($P_JOB{3}) {
    p_note("JOB 3 — I1: weights over the D51 fixture table  (W: " . join(' ', map { "$_=$W{$_}" } sort keys %W) . ")");
    p_build(1);
    my $ir  = (glob("$LOGS/IntegrationRuntimeLogs/IntegrationRuntime-*.log"))[0];
    my $cx  = (glob("$LOGS/ThingworxLogs/CXS/cxserver.1-*.log"))[0];
    my $tc  = "$LOGS/AccessLogs/localhost_access_log.2025-03-21.txt";
    my $hd  = "$LOGS/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log";
    my $app = "$LOGS/ThingworxLogs/ApplicationLog.2025-05-06.0.log";
    my @cases = (   # [ staged name, content path, group, expected member, expected basis, invariant ]
        [ 'cxserver.1.log',                                     $cx, 'cxserver_layout', 'mt10',   'evidence', 'stem' ],
        [ 'IntegrationRuntime-46b44bb3-cd86-44a6-a268-012144ff23af.log', $ir, 'cxserver_layout', 'mt10ir', 'evidence', 'stem alone decides (I1 invariant)' ],
        [ 'app.log',                                            $ir, 'cxserver_layout', 'mt10ir', 'evidence', 'no name evidence; probe (a) decides from the sample' ],
        [ 'app.log',                                            $cx, 'cxserver_layout', 'mt10',   'evidence', 'no name evidence; cxserver content spans day>12 so probe (a) eliminates ddMM from the sample' ],
        [ 'localhost_access_log.2025-05-05.txt',                $tc, 'access_duration', 'mt3',    'evidence', 'stem + .txt' ],
        [ 'access.log-20260609',                                $hd, 'access_duration', 'mt3us',  'evidence', 'stem + ext -> us, no -du' ],
        [ 'access_log',                                         $hd, 'access_duration', 'mt3us',  'evidence', 'stem alone (httpd default name)' ],
        [ 'renamed.txt',                                        $hd, 'access_duration', 'mt3',    'default',  'ext absent -> default + note' ],
        [ 'whatever.log',                                       $tc, 'access_duration', 'mt3',    'default',  'extension alone must NOT decide (I1 invariant)' ],
    );
    my $fail = 0;
    for my $c (@cases) {
        my ($name, $path, $g, $want, $want_basis, $inv) = @$c;
        next unless -f $path;
        my $obs = sample_file_for_detection($path);
        my $d = p_score($name, $obs->{lines}, $path)->{$g};
        my $ok = ($d->{selected} eq $want && $d->{basis} eq $want_basis) ? 'ok  ' : 'FAIL';
        $fail++ if $ok ne 'ok  ';
        p_note(sprintf "%s %-64s -> %-7s basis=%-8s conf=%.2f  scores{%s}  [%s]", $ok, $name, $d->{selected}, $d->{basis}, $d->{confidence},
            join(' ', map { "$_=$d->{scores}{$_}($d->{why}{$_})" } sort keys %{ $d->{scores} }), $inv);
    }
    p_note($fail ? "I1: $fail case(s) FAILED under the candidate weights" : "I1: all cases resolve as the D51 table requires under the candidate weights");
}

# ---------------------------------------------------------------------------
# Job 4 — I4: rotation index form
# ---------------------------------------------------------------------------
if ($P_JOB{4}) {
    p_note("JOB 4 — I4: producer-true names through the D45 component matcher");
    my @names = qw(
        ApplicationLog.log ApplicationLog.2025-05-05.0.log ErrorLog.2025-05-05.1.log ScriptLog.2025-04-09.4.log
        AkkaCommunicationLog.log ApplicationLog.2025-05-05.0.log.gz
        localhost_access_log.2025-03-21.txt localhost_access_log.txt
        access.log-20260609 access_log access.log access_log.1
        gc-2025-01-01.out.3 gc.out
        cxserver.1-16.log cxserver.log
        IntegrationRuntime-46b44bb3-cd86-44a6-a268-012144ff23af.log
        app.log renamed.txt
    );
    my $collisions = 0;
    for my $n (@names) {
        my @hits;
        for my $e (sort keys %FILENAME) {
            my $fm = p_match_filename($FILENAME{$e}, $n) or next;
            push @hits, sprintf "%s{ext=%s date=%s index=%s}", $e, $fm->{ext}, $fm->{date} // '-', $fm->{index} // '-';
        }
        $collisions++ if @hits > 1;
        p_note(sprintf "%-58s %s", $n, @hits ? join('  ', @hits) : '(no entry)');
    }
    # Would dropping the index FORM (present/absent only) create a collision?
    my %loose = map { my %d = %{ $FILENAME{$_} }; $d{index} = 'any' if $d{index}; ($_ => \%d) } keys %FILENAME;
    $INDEX_RE{any} = '[0-9][0-9-]*';
    my $loose_collisions = 0;
    for my $n (@names) {
        my @hits = grep { p_match_filename($loose{$_}, $n) } sort keys %loose;
        $loose_collisions++ if @hits > 1;
    }
    p_note("I4: cross-entry name collisions with declared index forms = $collisions; with index as present/absent only = $loose_collisions");
}
