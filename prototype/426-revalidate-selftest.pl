#!/usr/bin/env perl
#
# 426-revalidate-selftest.pl — self-test of prototype/426-revalidate-lib.pm.
#
#   (a) T and S digests identical; every percentile (7 quantiles x every key,
#       both rank conventions) identical to 1e-12 relative, audits identical.
#   (b) G: every observed value v satisfies 10**(i/bpd) <= v < 10**((i+1)/bpd)
#       after grid_index_checked; count of closed-form indices that needed a
#       correction.
#   (c) 20 keys (largest N): G percentiles ('int' convention) vs the oracle
#       within one bin width (10**(1/bpd) - 1) relative.
#   (d) merge(a,b): T equals a standalone verbatim ltl-shape merge; S equals T;
#       G equals the index-wise sum of the two spans and a fresh G built from
#       the union of samples.
#   (e) max_rebins cap: T and S digest-identical under cap 0; counts reported.
#   (f) parser key counts on the DPM ThingWorx log.
#
# Usage: perl prototype/426-revalidate-selftest.pl [--file F] [--twx F] [--bpd 53,616]
# Exit non-zero on any failure.

use strict;
use warnings;
use FindBin;
use POSIX ();
require "$FindBin::Bin/426-revalidate-lib.pm";

my $file = "$FindBin::Bin/../logs/AccessLogs/localhost_access_log.2025-03-21.txt";
my $twx  = "$FindBin::Bin/../logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log";
my @bpds = (53, 616);
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $o = shift @ARGV;
    if    ($o eq '--file') { $file = shift @ARGV }
    elsif ($o eq '--twx')  { $twx  = shift @ARGV }
    elsif ($o eq '--bpd')  { @bpds = split /,/, shift @ARGV }
    elsif ($o eq '--help') { print "usage: $0 [--file F] [--twx F] [--bpd 53,616]\n"; exit 0 }
    else { die "unknown option $o\n" }
}

my @Q = (0.01, 0.5, 0.75, 0.9, 0.95, 0.99, 0.999);
my $fail = 0;
sub ok { my ($cond, $line) = @_; printf "%s %s\n", ($cond ? 'PASS' : 'FAIL'), $line; $fail++ unless $cond; return $cond }

# --- load the samples once ----------------------------------------------------
my (%samples, %values_seen);
my $counts = Revalidate426::iterate_durations($file, sub {
    my ($cat, $key, $d) = @_;
    push @{ $samples{"$cat\x1f$key"} }, $d;
    $values_seen{$d}++;
}, count_keys => 1);
(my $fx = $file) =~ s{.*/}{};
printf "file: %s format=%s lines=%d matched=%d unparsed=%d no_duration=%d positive=%d zero=%d negative=%d keys_any=%d keys_positive=%d distinct_values=%d\n",
    $fx, $counts->{format}, @$counts{qw(lines matched unparsed no_duration positive zero negative keys_any keys_positive)}, scalar keys %values_seen;

my @keys_by_n = sort { @{ $samples{$b} } <=> @{ $samples{$a} } || $a cmp $b } keys %samples;

for my $bpd (@bpds) {
    Revalidate426::configure(bpd => $bpd, seed_decades => 5, max_rebins => undef);
    my $width = 10 ** (1 / $bpd) - 1;
    print "\n--- bpd=$bpd (one bin = " . sprintf('%.4f%%', 100 * $width) . ")\n";

    my %st = map { $_ => Revalidate426::store_new($_) } qw(T S G);
    my ($n_checked, $n_corrected, $n_bound_fail) = (0, 0, 0);
    Revalidate426::iterate_durations($file, sub {
        my ($cat, $key, $d) = @_;
        my $k = "$cat\x1f$key";
        $st{$_}->add($k, $d) for qw(T S G);
        # (b) grid cross-check on every observed value
        my ($i, $corr) = Revalidate426::grid_index_checked($d, $bpd);
        $n_checked++; $n_corrected += $corr;
        $n_bound_fail++ unless 10 ** ($i / $bpd) <= $d && $d < 10 ** (($i + 1) / $bpd);
    });

    # (a) digests + percentiles
    my ($dT, $dS, $dG) = map { $st{$_}->digest } qw(T S G);
    printf "digest T=%s S=%s G=%s keys T=%d S=%d G=%d\n", $dT, $dS, $dG, map { scalar $st{$_}->keys } qw(T S G);
    ok($dT eq $dS, "(a) bpd=$bpd T and S digests identical");
    my ($n_cmp, $n_bad, $max_rel) = (0, 0, 0);
    for my $k (keys %samples) {
        for my $conv (qw(ceil int)) {
            for my $q (@Q) {
                my ($vt, $at) = $st{T}->percentile($k, $q, $conv);
                my ($vs, $as) = $st{S}->percentile($k, $q, $conv);
                $n_cmp++;
                my $rel = (defined $vt && defined $vs && $vt != 0) ? abs($vt - $vs) / abs($vt) : (defined $vt || defined $vs ? 1 : 0);
                $max_rel = $rel if $rel > $max_rel;
                $n_bad++ if $rel > 1e-12 || $at ne $as;
            }
        }
    }
    ok($n_bad == 0, sprintf("(a) bpd=%d T vs S percentiles: %d compared (%d keys x 7 q x 2 conventions), %d beyond 1e-12 or audit mismatch, max rel diff %.3g",
                            $bpd, $n_cmp, scalar(keys %samples), $n_bad, $max_rel));
    my $tel = $st{T}->telemetry;
    printf "T telemetry: partitions=%d rebin_events=%d max_bins=%d over=%d under=%d rebins p50=%d p95=%d p99=%d max=%d mem=%d\n",
        @$tel{qw(partition_count total_rebin_events max_partition_bins overflow_total underflow_total rebins_p50 rebins_p95 rebins_p99 rebins_max counter_memory_bytes)};
    my $tels = $st{S}->telemetry;
    my $tel_same = join(',', map { $tel->{$_} } grep { $_ ne 'counter_memory_bytes' } sort keys %$tel)
                eq join(',', map { $tels->{$_} } grep { $_ ne 'counter_memory_bytes' } sort keys %$tels);
    ok($tel_same, "(a) bpd=$bpd T and S telemetry fields identical (excluding counter_memory_bytes: T=$tel->{counter_memory_bytes} S=$tels->{counter_memory_bytes})");
    my $telg = $st{G}->telemetry;
    printf "G telemetry: partitions=%d span p50=%d p95=%d p99=%d max=%d index_range=[%d,%d] mem=%d\n",
        @$telg{qw(partition_count span_p50 span_p95 span_p99 span_max index_min index_max counter_memory_bytes)};
    printf "memory_bytes: T=%d S=%d G=%d\n", map { $st{$_}->memory_bytes } qw(T S G);

    # (b)
    ok($n_bound_fail == 0, "(b) bpd=$bpd G bound 10**(i/bpd) <= v < 10**((i+1)/bpd) holds after grid_index_checked on $n_checked values; closed-form indices corrected: $n_corrected");

    # (c) 20 largest-N keys, G 'int' vs oracle within one bin width
    my ($c_cmp, $c_bad, $c_max) = (0, 0, 0);
    my ($t_bad, $t_max) = (0, 0);
    for my $k (@keys_by_n[0 .. 19]) {
        my @orc = Revalidate426::oracle_percentiles($samples{$k}, \@Q);
        for my $j (0 .. $#Q) {
            my ($g) = $st{G}->percentile($k, $Q[$j], 'int');
            my ($t) = $st{T}->percentile($k, $Q[$j], 'int');
            my $eg = abs($g - $orc[$j]) / $orc[$j];
            my $et = abs($t - $orc[$j]) / $orc[$j];
            $c_cmp++;
            $c_max = $eg if $eg > $c_max; $c_bad++ if $eg > $width + 1e-12;
            $t_max = $et if $et > $t_max; $t_bad++ if $et > $width + 1e-12;
        }
    }
    ok($c_bad == 0, sprintf("(c) bpd=%d G ('int' rank) vs oracle on 20 largest keys (N %d..%d): %d compared, %d beyond one bin width, max rel err %.4f%% (bound %.4f%%); T for reference: %d beyond, max %.4f%%",
                            $bpd, scalar @{ $samples{$keys_by_n[0]} }, scalar @{ $samples{$keys_by_n[19]} }, $c_cmp, $c_bad, 100 * $c_max, 100 * $width, $t_bad, 100 * $t_max));

    # (d) merge
    my ($ka, $kb) = @keys_by_n[0, 1];
    # find a pair whose geometries differ (a real remap) if one exists among the top keys
    for my $j (1 .. $#keys_by_n) {
        my ($ga, $gb) = ($st{T}->geometry($ka), $st{T}->geometry($keys_by_n[$j]));
        if ($ga->{min} != $gb->{min} || $ga->{max} != $gb->{max}) { $kb = $keys_by_n[$j]; last }
    }
    my (%A, %B);
    Revalidate426::counter_update(\%A, 'a', $_, $bpd) for @{ $samples{$ka} };
    Revalidate426::counter_update(\%B, 'b', $_, $bpd) for @{ $samples{$kb} };
    my $geo_before = join('/', @{ $st{T}->geometry($ka) }{qw(min max bin_count)});
    Revalidate426::merge_bin_counter_entries($A{a}, $B{b});
    my $ref_store = Revalidate426::store_new('T'); $ref_store->{store}{$ka} = $A{a};
    my $ref_canon = $ref_store->canonical($ka);
    $st{$_}->merge($ka, $kb, drop_source => 1) for qw(T S);
    my $geo_after = join('/', @{ $st{T}->geometry($ka) }{qw(min max bin_count)});
    ok($st{T}->canonical($ka) eq $ref_canon, "(d) bpd=$bpd T merge == standalone verbatim merge_bin_counter_entries (geometry $geo_before -> $geo_after, remap=" . ($geo_before eq $geo_after ? 'no' : 'yes') . ")");
    ok($st{S}->canonical($ka) eq $st{T}->canonical($ka) && !$st{S}->has($kb) && !$st{T}->has($kb), "(d) bpd=$bpd S merge canonical == T merge canonical; source dropped in both");
    ok($st{T}->digest eq $st{S}->digest, "(d) bpd=$bpd T and S whole-store digests identical after merge");
    # post-merge add: exercises pdec (decades after partition_rebin) on both arms
    my $probe = $st{T}->geometry($ka)->{max} * 10;
    $st{$_}->add($ka, $probe) for qw(T S);
    ok($st{T}->canonical($ka) eq $st{S}->canonical($ka), "(d) bpd=$bpd T and S identical after a post-merge out-of-range add (extend on merged geometry; rebins now " . $st{T}->geometry($ka)->{rebins} . ")");
    my %expect; $expect{ Revalidate426::grid_index($_, $bpd) }++ for (@{ $samples{$ka} }, @{ $samples{$kb} });
    my $exp_canon = "grid/$bpd|o0|u0|" . join(',', map { "$_:$expect{$_}" } sort { $a <=> $b } keys %expect);
    my $fresh = Revalidate426::store_new('G'); $fresh->add('u', $_) for (@{ $samples{$ka} }, @{ $samples{$kb} });
    $st{G}->merge($ka, $kb, drop_source => 1);
    ok($st{G}->canonical($ka) eq $exp_canon && $fresh->canonical('u') eq $exp_canon && !$st{G}->has($kb),
       "(d) bpd=$bpd G merge == index-wise sum of spans == fresh G over the union of samples (N=" . $st{G}->n($ka) . ")");

    # (e) cap
    Revalidate426::configure(max_rebins => 0);
    my %cs = map { $_ => Revalidate426::store_new($_) } qw(T S);
    Revalidate426::iterate_durations($file, sub { my ($cat, $key, $d) = @_; $cs{$_}->add("$cat\x1f$key", $d) for qw(T S) });
    my $ct = $cs{T}->telemetry;
    ok($cs{T}->digest eq $cs{S}->digest && $ct->{total_rebin_events} == 0,
       "(e) bpd=$bpd max_rebins=0: T and S digests identical; rebin_events=$ct->{total_rebin_events} partitions_with_overflow=$ct->{partitions_with_overflow_count} partitions_with_underflow=$ct->{partitions_with_underflow_count} overflow_total=$ct->{overflow_total} underflow_total=$ct->{underflow_total}");
    Revalidate426::configure(max_rebins => undef);
}

# (f) twx parser key counts
print "\n--- twx parser\n";
my %tk;
my $tc = Revalidate426::iterate_durations($twx, sub { my ($cat, $key, $d) = @_; $tk{"$cat\x1f$key"}++ }, count_keys => 1);
(my $tx = $twx) =~ s{.*/}{};
printf "file: %s format=%s lines=%d matched=%d unparsed=%d positive=%d zero=%d negative=%d keys_any=%d keys_positive=%d\n",
    $tx, $tc->{format}, @$tc{qw(lines matched unparsed positive zero negative keys_any keys_positive)};
ok($tc->{format} eq 'twx' && $tc->{keys_positive} == scalar(keys %tk), "(f) twx parser: keys_positive=$tc->{keys_positive} keys_any=$tc->{keys_any} (report says 3,419 positive / 3,421 total)");

print "\n", ($fail ? "FAILED ($fail)" : "ALL PASS"), "\n";
exit($fail ? 1 : 0);
