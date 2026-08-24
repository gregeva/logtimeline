#!/usr/bin/env perl
#
# 426-revalidate-v4.pl — aspect V4 of the #426 revalidation (mirror of #189 V4):
# the `-V histogram-bin-counters` section for the summary_table consumer,
# rendered in ltl's CURRENT format (emit_bin_counter_mode_verbose, ltl:4625-4776,
# the #293 form) from each of the three arms of prototype/426-revalidate-lib.pm:
#
#   T  today's primitives (verbatim), keyed hash of ltl-shape entries
#   S  span-only columnar, verbatim geometry (P8+P9)
#   G  shared log-spaced grid, span-only (P10)
#
# Six scenarios, mapped from #189 V4 onto today's precision lever (#293
# dissolved -pbpd / --percentile-precision; the only knob is
# --data-model-precision 1..9 and the opt-out is `-mdm raw`):
#
#   1  default precision             tier 5  -> bpd 53   (`-mdm bin`)
#   2  --data-model-precision 7      tier 7  -> bpd 115  (#189's "--percentile-precision 7")
#   3  -pbpd 100                     UNREACHABLE in today's ltl (dissolved by #293);
#                                    rendered as the max tier 9 -> bpd 616 substitute
#   4  -pbpd + --percentile-precision UNREACHABLE (no competing flag remains); not rendered
#   5  overflow audit firing         max_rebins 0 on T/S (189's --max-rebins 0);
#                                    G has no cap — rendered to show the constant block
#   6  opt-out                       `-mdm raw` -> path: user_opt_out; no store built
#
# For arm G two blocks are rendered per scenario: the locked Decision 8 field set
# exactly as today's emitter would print it (undefined telemetry -> `// 0`), and a
# PROPOSED variant with replacement telemetry, clearly labelled as a proposal for
# a Decision 8 amendment (not a lock).
#
# Parity: T and S digests are compared per scenario before anything else is
# printed for that scenario; exit non-zero on divergence.
#
# Usage:
#   perl prototype/426-revalidate-v4.pl --file F [--bpd N] [--arm T|S|G|all]
#        [--scenario 1..6|all] [--timing N] [--help]
#   --bpd     overrides the tier-derived bpd for scenario 1 only (tier label then
#             reads `n/a (--bpd N)` — a prototype-only annotation)
#   --timing  N timed runs (one untimed warmup) of telemetry+render per arm;
#             use one arm per process for timing (--arm T etc.)

use strict;
use warnings;
use FindBin;
use POSIX ();
use Getopt::Long qw(GetOptions);
require "$FindBin::Bin/426-revalidate-lib.pm";

my %opt = (file => undef, bpd => undef, arm => 'all', scenario => 'all', timing => 0);
GetOptions(\%opt, 'file=s', 'bpd=i', 'arm=s', 'scenario=s', 'timing=i', 'help') or usage(1);
usage(0) if $opt{help};
usage(1) unless defined $opt{file} && -f $opt{file};

sub usage {
    my ($rc) = @_;
    print <<"USAGE";
usage: perl $0 --file F [--bpd N] [--arm T|S|G|all] [--scenario 1..6|all] [--timing N]
  --file      access log (Tomcat) or ThingWorx ScriptLog; format auto-detected
  --bpd N     override the tier-derived bpd (scenario 1 only)
  --arm       T (today), S (span-only columnar), G (shared grid), all
  --scenario  1 default | 2 tier 7 | 3 tier 9 substitute for -pbpd | 4 unreachable
              | 5 overflow (max_rebins 0) | 6 opt-out (-mdm raw) | all
  --timing N  N timed runs (after one warmup) of telemetry+render, median/min/max
USAGE
    exit $rc;
}

my @arms = $opt{arm} eq 'all' ? qw(T S G) : (uc $opt{arm});
die "arm must be T|S|G|all\n" if grep { !/^[TSG]$/ } @arms;
my @scenarios = $opt{scenario} eq 'all' ? (1 .. 6) : split /,/, $opt{scenario};

# The summary_table ladder (ltl emit_bin_counter_mode_verbose %percentile_set).
my @LADDER = (
    [p1 => 0.01], [p5 => 0.05], [p10 => 0.10], [p25 => 0.25], [p50 => 0.50], [p75 => 0.75],
    [p90 => 0.90], [p95 => 0.95], [p99 => 0.99], [p999 => 0.999], [p9999 => 0.9999], [p99999 => 0.99999],
);

# Scenario table: tier, source string exactly as ltl prints it, cap, opt-out.
my %SCEN = (
    1 => { title => 'Default precision (tier 5)',
           ltl   => './ltl -ni -mdm bin -V histogram-bin-counters ...',
           tier  => 5, source => 'default' },
    2 => { title => '--data-model-precision 7 (#189 scenario 2: --percentile-precision 7, bpd 115)',
           ltl   => './ltl -ni -mdm bin -dmp 7 -V histogram-bin-counters ...',
           tier  => 7, source => '--data-model-precision 7' },
    3 => { title => '-pbpd 100 (#189 scenario 3) — UNREACHABLE: -pbpd dissolved by #293; substitute: tier 9 (bpd 616, the lever maximum)',
           ltl   => './ltl -ni -mdm bin -dmp 9 -V histogram-bin-counters ...',
           tier  => 9, source => '--data-model-precision 9' },
    4 => { title => '-pbpd 100 + --percentile-precision 4 (#189 scenario 4) — UNREACHABLE: no competing flag exists after #293',
           ltl   => '(none)', unreachable => 1 },
    5 => { title => 'Overflow audit firing (max_rebins 0 on T/S; G has no rebin cap)',
           ltl   => '(no ltl flag: --max-rebins is a #189-prototype hook; ltl has no growth cap today)',
           tier  => 5, source => 'default', max_rebins => 0 },
    6 => { title => 'Opt-out: -mdm raw (#189 scenario 6: --exact-percentiles) -> path: user_opt_out',
           ltl   => './ltl -ni -mdm raw -V histogram-bin-counters ...',
           tier  => 5, source => 'default', opt_out => 1 },
);

# ---------------------------------------------------------------------------
# Load the samples once (format detected by the library; dur > 0 only).
my (%keys_seen);
my $samples = [];
my $counts = Revalidate426::iterate_durations($opt{file}, sub {
    my ($cat, $key, $d) = @_;
    push @$samples, ["$cat\x1f$key", $d];
    $keys_seen{"$cat\x1f$key"}++;
}, count_keys => 1);
(my $fx = $opt{file}) =~ s{.*/}{};
printf "file: %s format=%s lines=%d matched=%d positive=%d zero=%d negative=%d keys_positive=%d\n",
    $fx, $counts->{format}, @$counts{qw(lines matched positive zero negative keys_positive)};
printf "arms: %s scenarios: %s\n", join(',', @arms), join(',', @scenarios);

sub build_store {
    my ($arm, $bpd) = @_;
    my $st = Revalidate426::store_new($arm, bpd => $bpd);
    $st->add($_->[0], $_->[1]) for @$samples;
    return $st;
}

# out_of_range_bounded aggregate across every key, ltl's precedence
# (calculate_statistics_bin: high > low > none), native ceil(q*N) rank.
sub audit_aggregate {
    my ($st) = @_;
    my %agg;
    for my $k ($st->keys) {
        for my $pair (@LADDER) {
            my ($name, $q) = @$pair;
            my (undef, $a) = $st->percentile($k, $q, 'ceil');
            $a //= 'none';
            my $cur = $agg{$name};
            if    ($a eq 'high')                              { $agg{$name} = 'high' }
            elsif ($a eq 'low' && (!$cur || $cur eq 'none'))  { $agg{$name} = 'low'  }
            elsif (!defined $cur)                             { $agg{$name} = 'none' }
        }
    }
    return \%agg;
}

# Inactive consumers exactly as the real run prints them (the real capture
# prototype/426-results/revalidate-v4-ltl-real.txt): csv_output/heatmap_*/
# histogram_* feature_not_active; time_bucket_stats user_opt_out because -mdm
# pins message-stats only and bucket-stats resolves raw.
my @INACTIVE = (
    [csv_output => 'feature_not_active'], [time_bucket_stats => 'user_opt_out'],
    [heatmap_markers => 'feature_not_active'], [heatmap_cells => 'feature_not_active'],
    [histogram_view => 'feature_not_active'], [histogram_bins => 'feature_not_active'],
);

# Render the section in today's format from a telemetry hash (T/S: the 12
# verbatim fields; G: whatever telemetry() returns — missing fields print 0
# through the emitter's `// 0`, exactly as ltl:4752-4760 would).
sub render_locked {
    my (%a) = @_;
    my $t = $a{telemetry} // {};
    my @o = ("=== histogram-bin-counters ===", "data_model_precision: $a{tier} ($a{source})", "");
    push @o, "consumer: summary_table";
    if ($a{opt_out}) {
        push @o, "  path: user_opt_out";
    } else {
        push @o, "  path: unified";
        push @o, "  partition_keying: (category, log_key)";
        push @o, "  partition_count: "                 . ($t->{partition_count}                 // 0);
        push @o, "  total_rebin_events: "              . ($t->{total_rebin_events}              // 0);
        push @o, "  max_partition_bins: "              . ($t->{max_partition_bins}              // 0);
        push @o, "  partitions_with_overflow_count: "  . ($t->{partitions_with_overflow_count}  // 0);
        push @o, "  partitions_with_underflow_count: " . ($t->{partitions_with_underflow_count} // 0);
        push @o, "  counter_memory_bytes: "            . ($t->{counter_memory_bytes}            // 0);
        push @o, sprintf("  rebins_per_partition: p50=%d p95=%d p99=%d max=%d",
            $t->{rebins_p50} // 0, $t->{rebins_p95} // 0, $t->{rebins_p99} // 0, $t->{rebins_max} // 0);
        push @o, "  percentiles_emitted: " . join(' ', map { $_->[0] } @LADDER);
        my $audit = $a{audit} // {};
        push @o, "  out_of_range_bounded: " . join(' ', map { "$_->[0]=" . ($audit->{$_->[0]} // 'none') } @LADDER);
    }
    for my $c (@INACTIVE) { push @o, "", "consumer: $c->[0]", "  path: $c->[1]" }
    push @o, "=== END histogram-bin-counters ===";
    return join("\n", @o) . "\n";
}

# PROPOSED Decision 8 amendment rendering for a shared-grid store (NOT locked):
# the five Decision 5 fields that are structurally constant under G are
# replaced by grid telemetry; the Decision 4 audit line is kept only as a
# constant so downstream greps do not break (its value can never be high/low).
sub render_proposed_G {
    my (%a) = @_;
    my $t = $a{telemetry};
    my @o = ("=== histogram-bin-counters ===", "data_model_precision: $a{tier} ($a{source})", "");
    push @o, "consumer: summary_table";
    push @o, "  path: unified";
    push @o, "  partition_keying: (category, log_key)";
    push @o, "  partition_count: $t->{partition_count}";
    push @o, "  grid_bpd: $a{bpd}";
    push @o, sprintf("  grid_index_range: %d..%d", $t->{index_min}, $t->{index_max});
    push @o, sprintf("  span_slots: p50=%d p95=%d p99=%d max=%d", @$t{qw(span_p50 span_p95 span_p99 span_max)});
    push @o, "  counter_slots_total: $a{slots_total}";
    push @o, "  counter_memory_bytes: $t->{counter_memory_bytes}";
    push @o, "  percentiles_emitted: " . join(' ', map { $_->[0] } @LADDER);
    push @o, "  out_of_range_bounded: " . join(' ', map { "$_->[0]=none" } @LADDER);
    for my $c (@INACTIVE) { push @o, "", "consumer: $c->[0]", "  path: $c->[1]" }
    push @o, "=== END histogram-bin-counters ===";
    return join("\n", @o) . "\n";
}

sub banner {
    my (@lines) = @_;
    print "\n", "#" x 78, "\n";
    print "# $_\n" for @lines;
    print "#" x 78, "\n";
}

my $fail = 0;
for my $s (@scenarios) {
    my $sc = $SCEN{$s} or die "unknown scenario $s\n";
    if ($sc->{unreachable}) {
        banner("Scenario $s: $sc->{title}", "ltl equivalent: $sc->{ltl}");
        print "NOT RENDERED: ltl has no -pbpd and no --percentile-precision flag (grep count 0 in ltl); the\n";
        print "only precision knob is --data-model-precision 1..9, so a two-flag conflict cannot be constructed.\n";
        print "Decision 2's '-pbpd always wins' clause and Decision 8's '; overridden' annotation were dissolved\n";
        print "by the #293 amendment (features/187-histogram-bin-counter-percentiles.md § Decision 8, 2026-05-27).\n";
        next;
    }
    my $tier = $sc->{tier};
    my $bpd  = Revalidate426::tier_to_bpd($tier);
    my $source = $sc->{source};
    if ($s == 1 && defined $opt{bpd}) { $bpd = $opt{bpd}; $tier = 'n/a'; $source = "--bpd $opt{bpd} (prototype-only override)" }

    Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => $sc->{max_rebins});

    my %st;
    my %rss;
    if (!$sc->{opt_out}) {
        for my $arm (@arms) {
            my $r0 = Revalidate426::rss_kb();
            $st{$arm} = build_store($arm, $bpd);
            $rss{$arm} = Revalidate426::rss_kb() - $r0;
        }
        # Parity BEFORE anything else is printed for this scenario.
        if ($st{T} && $st{S}) {
            my ($dT, $dS) = ($st{T}->digest, $st{S}->digest);
            my $ok = $dT eq $dS;
            printf "\n%s scenario %d bpd=%d T/S digest %s: T=%s S=%s\n", ($ok ? 'PASS' : 'FAIL'), $s, $bpd, ($ok ? 'identical' : 'DIVERGE'), $dT, $dS;
            $fail++ unless $ok;
        }
        if ($st{G}) {
            printf "info scenario %d bpd=%d G digest=%s keys=%d\n", $s, $bpd, $st{G}->digest, scalar $st{G}->keys;
        }
    }

    for my $arm (@arms) {
        banner("Scenario $s: $sc->{title}",
               "ltl equivalent: $sc->{ltl}",
               sprintf("arm: %s   bpd=%s   tier=%s   max_rebins=%s", $arm, $bpd, $tier, $sc->{max_rebins} // 'none'));
        if ($sc->{opt_out}) {
            print "(no counter store is built under -mdm raw — the block below is representation-independent)\n";
            print render_locked(tier => $tier, source => $source, opt_out => 1);
            next;
        }
        my $st  = $st{$arm};
        my $tel = $st->telemetry;
        my $audit = audit_aggregate($st);
        printf "rss_delta_kb(store build): %d\n", $rss{$arm};
        if ($arm ne 'G') {
            printf "overflow_total=%d underflow_total=%d (telemetry extras, not Decision 8 fields)\n",
                $tel->{overflow_total}, $tel->{underflow_total};
            print render_locked(tier => $tier, source => $source, telemetry => $tel, audit => $audit);
        } else {
            my $slots = 0;
            $slots += $st->geometry($_)->{span} for $st->keys;
            print "--- G under the LOCKED Decision 8 field set (as today's emitter would print it):\n";
            print render_locked(tier => $tier, source => $source, telemetry => $tel, audit => $audit);
            print "--- G vacuous fields (structurally constant under a shared grid):\n";
            print "    total_rebin_events: 0 (no rebin exists)\n";
            print "    max_partition_bins: telemetry has no such field -> emitter prints 0 via `// 0`\n";
            print "    partitions_with_overflow_count: 0 / partitions_with_underflow_count: 0 (an index exists for every positive value)\n";
            print "    rebins_per_partition: p50=0 p95=0 p99=0 max=0\n";
            print "    out_of_range_bounded: every quantile 'none' (percentile() audit is constant 'none' under G)\n";
            print "--- PROPOSED Decision 8 amendment rendering for G (NOT a lock; architect's decision):\n";
            print render_proposed_G(tier => $tier, source => $source, telemetry => $tel, bpd => $bpd, slots_total => $slots);
        }

        if ($opt{timing} > 0) {
            my @secs = Revalidate426::time_runs($opt{timing}, sub {
                my $t = $st->telemetry; my $a = audit_aggregate($st);
                my $txt = $arm eq 'G'
                    ? render_proposed_G(tier => $tier, source => $source, telemetry => $t, bpd => $bpd, slots_total => 0)
                    : render_locked(tier => $tier, source => $source, telemetry => $t, audit => $a);
            });
            my ($med, $min, $max) = Revalidate426::median_min_max(@secs);
            printf "timing arm=%s scenario=%d bpd=%d telemetry+audit+render runs=%d median=%.4fs min=%.4fs max=%.4fs devel_size_bytes=%d rss_delta_kb=%d\n",
                $arm, $s, $bpd, $opt{timing}, $med, $min, $max, $st->memory_bytes, $rss{$arm};
        }
    }
    Revalidate426::configure(max_rebins => undef);
}

print "\n", ($fail ? "FAIL: $fail T/S digest divergence(s)\n" : "ALL PARITY PASS\n");
exit($fail ? 1 : 0);
