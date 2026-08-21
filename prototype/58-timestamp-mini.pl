#!/usr/bin/env perl
#
# 58-timestamp-mini.pl — timestamp-cache parity semantics (#58 A6, F8-7):
# today's two parse families + shared %timestamp_cache expressed as a
# registry TIME CONTRACT (layout declared per entry, compiled into a parse
# closure at load), with byte-exact output parity, plus F6's last-seen-date
# cache as a measured alternative.
#
# Isolation protocol (as P2/P6): per fixture, an untimed prep pass runs the
# format's recognition regex + its timezone chop to yield the
# (family, timestamp_str) stream today's code would see; candidates then
# process only the timestamp stage. Every candidate pays the same string
# copy (the fractional strip mutates).
#
# Candidates:
#   inline      today's code verbatim: shared fractional strip, family
#               if/elsif, %timestamp_cache keyed by post-strip second string
#   contract    per-layout closure compiled at load from the declared time
#               contract (iso_ms / apache_clf); same cache semantics. In the
#               real design this code is inlined into the extraction closure,
#               so its call overhead here is an upper bound.
#   datecache   same contract closures, but cache holds one key per DATE
#               (midnight epoch); HMS added arithmetically. Output-identical;
#               cache cardinality drops from unique-seconds to unique-days.
#
# Parity: (timestamp, fractional_ms, timestamp_epoch) triple identical to
# inline for every line; ts_precision flip semantics identical. Cache
# entry-count and Devel::Size reported after each full pass.
#
# Usage:
#   perl prototype/58-timestamp-mini.pl [--runs N] <fixture> [...]

use strict;
use warnings;
use FindBin;
use Time::Local qw(timegm);
use Devel::Size qw(total_size);
require "$FindBin::Bin/58-measure.pm";

my $runs = 5;
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $opt = shift @ARGV;
    if ($opt eq '--runs') { $runs = shift @ARGV; }
    else { die "unknown option $opt\n"; }
}
die "usage: $0 [--runs N] <fixture> [...]\n" unless @ARGV;

my %month_map = ( Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6, Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12 );

## Fixture prep: recognition + tz chop per format family (untimed).
## Returns arrayref of [family, timestamp_str_with_fraction].
sub prep_stream {
    my ($file) = @_;
    my @ts;
    open my $fh, '<', $file or die "Cannot open file: $file";
    while (<$fh>) {
        s/[\r\n]+$//;
        if (my ($t) = /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: /) {
            push @ts, [ 'iso', $t ];                        # mt1 (chop in-pattern)
        } elsif (my ($t2) = /^[^ ]+ [^ ]+ [^ ]+ [\[](\d{2}\/[A-Za-z]+\/\d{4}:\d{2}:\d{2}:\d{2})/) {
            push @ts, [ 'apache', $t2 ];                    # access family (offset chopped)
        } elsif (my ($t3) = /^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3})[+-]\d{4}.*?\[info\]\[gc/) {
            push @ts, [ 'iso', $t3 ];                       # mt6 (offset outside capture)
        }
    }
    close $fh;
    return \@ts;
}

## Shared fractional strip (today's code): mutates, returns fractional_ms.
sub strip_fraction {
    if ($_[0] =~ s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/) {
        my $frac_digits = $2;
        return $frac_digits * (10 ** (3 - length($frac_digits)));
    }
    return 0;
}

## ---------------------------------------------------------------------------
## Candidate: inline (today's code verbatim, family if/elsif + shared cache)
## ---------------------------------------------------------------------------

sub run_inline {
    my ($stream) = @_;
    my %timestamp_cache;
    my ($epoch_sum, $fms_sum, $prec_ms) = (0, 0, 0);
    for my $rec (@$stream) {
        my ($family, $ts) = @$rec;
        my $timestamp_str = $ts;                        # copy: strip mutates
        my $fractional_ms = strip_fraction($timestamp_str);
        my $timestamp;
        if ($family eq 'iso') {
            if (exists $timestamp_cache{$timestamp_str}) {
                $timestamp = $timestamp_cache{$timestamp_str};
            } else {
                $timestamp = timegm(
                    substr($timestamp_str, 17, 2),
                    substr($timestamp_str, 14, 2),
                    substr($timestamp_str, 11, 2),
                    substr($timestamp_str, 8, 2),
                    substr($timestamp_str, 5, 2) - 1,
                    substr($timestamp_str, 0, 4),
                );
                $timestamp_cache{$timestamp_str} = $timestamp;
            }
        } else {
            if (exists $timestamp_cache{$timestamp_str}) {
                $timestamp = $timestamp_cache{$timestamp_str};
            } else {
                my ($day, $month_str, $year, $hour, $minute, $second) = $timestamp_str =~ m/(\d{2})\/([A-Za-z]+)\/(\d{4}):(\d{2}):(\d{2}):(\d{2})/;
                my $month = $month_map{$month_str};
                $timestamp = timegm($second, $minute, $hour, $day, $month - 1, $year);
                $timestamp_cache{$timestamp_str} = $timestamp;
            }
        }
        my $timestamp_epoch = $timestamp + ($fractional_ms / 1000);
        $epoch_sum += $timestamp_epoch;
        $fms_sum   += $fractional_ms;
        $prec_ms = 1 if $fractional_ms > 0;
    }
    return { epoch_sum => $epoch_sum, fms_sum => $fms_sum, prec_ms => $prec_ms,
             cache_keys => 0 + keys %timestamp_cache, cache_bytes => total_size(\%timestamp_cache) };
}

## ---------------------------------------------------------------------------
## Candidate: contract — per-layout closures compiled at load, same cache
## semantics (key = post-strip second string). Closure returns (epoch, fms).
## ---------------------------------------------------------------------------

sub compile_contract {
    my ($layout, $cache) = @_;
    if ($layout eq 'iso_ms') {
        return sub {
            my $timestamp_str = $_[0];
            my $fractional_ms = strip_fraction($timestamp_str);
            my $timestamp = $cache->{$timestamp_str} //= timegm(
                substr($timestamp_str, 17, 2),
                substr($timestamp_str, 14, 2),
                substr($timestamp_str, 11, 2),
                substr($timestamp_str, 8, 2),
                substr($timestamp_str, 5, 2) - 1,
                substr($timestamp_str, 0, 4),
            );
            return ($timestamp, $fractional_ms);
        };
    }
    if ($layout eq 'apache_clf') {
        return sub {
            my $timestamp_str = $_[0];
            my $fractional_ms = strip_fraction($timestamp_str);
            my $timestamp = $cache->{$timestamp_str} //= do {
                my ($day, $month_str, $year, $hour, $minute, $second) = $timestamp_str =~ m/(\d{2})\/([A-Za-z]+)\/(\d{4}):(\d{2}):(\d{2}):(\d{2})/;
                timegm($second, $minute, $hour, $day, $month_map{$month_str} - 1, $year);
            };
            return ($timestamp, $fractional_ms);
        };
    }
    die "unknown layout $layout";
}

sub run_contract {
    my ($stream) = @_;
    my %cache;
    my %parser = ( iso => compile_contract('iso_ms', \%cache),
                   apache => compile_contract('apache_clf', \%cache) );
    my ($epoch_sum, $fms_sum, $prec_ms) = (0, 0, 0);
    for my $rec (@$stream) {
        my ($timestamp, $fractional_ms) = $parser{$rec->[0]}->($rec->[1]);
        $epoch_sum += $timestamp + ($fractional_ms / 1000);
        $fms_sum   += $fractional_ms;
        $prec_ms = 1 if $fractional_ms > 0;
    }
    return { epoch_sum => $epoch_sum, fms_sum => $fms_sum, prec_ms => $prec_ms,
             cache_keys => 0 + keys %cache, cache_bytes => total_size(\%cache) };
}

## ---------------------------------------------------------------------------
## Candidate: datecache — contract closures with one cache key per DATE
## (midnight epoch); HMS added arithmetically. timegm is pure UTC, so
## midnight + h*3600 + m*60 + s is exact — outputs must be identical.
## ---------------------------------------------------------------------------

sub compile_datecache {
    my ($layout, $cache) = @_;
    if ($layout eq 'iso_ms') {
        return sub {
            my $timestamp_str = $_[0];
            my $fractional_ms = strip_fraction($timestamp_str);
            my $date = substr($timestamp_str, 0, 10);
            my $midnight = $cache->{$date} //= timegm(0, 0, 0,
                substr($date, 8, 2), substr($date, 5, 2) - 1, substr($date, 0, 4));
            my $timestamp = $midnight
                + substr($timestamp_str, 11, 2) * 3600
                + substr($timestamp_str, 14, 2) * 60
                + substr($timestamp_str, 17, 2);
            return ($timestamp, $fractional_ms);
        };
    }
    if ($layout eq 'apache_clf') {
        return sub {
            my $timestamp_str = $_[0];
            my $fractional_ms = strip_fraction($timestamp_str);
            my $date = substr($timestamp_str, 0, 11);       # dd/Mon/yyyy
            my $midnight = $cache->{$date} //= timegm(0, 0, 0,
                substr($date, 0, 2), $month_map{substr($date, 3, 3)} - 1, substr($date, 7, 4));
            my $timestamp = $midnight
                + substr($timestamp_str, 12, 2) * 3600
                + substr($timestamp_str, 15, 2) * 60
                + substr($timestamp_str, 18, 2);
            return ($timestamp, $fractional_ms);
        };
    }
    die "unknown layout $layout";
}

sub run_datecache {
    my ($stream) = @_;
    my %cache;
    my %parser = ( iso => compile_datecache('iso_ms', \%cache),
                   apache => compile_datecache('apache_clf', \%cache) );
    my ($epoch_sum, $fms_sum, $prec_ms) = (0, 0, 0);
    for my $rec (@$stream) {
        my ($timestamp, $fractional_ms) = $parser{$rec->[0]}->($rec->[1]);
        $epoch_sum += $timestamp + ($fractional_ms / 1000);
        $fms_sum   += $fractional_ms;
        $prec_ms = 1 if $fractional_ms > 0;
    }
    return { epoch_sum => $epoch_sum, fms_sum => $fms_sum, prec_ms => $prec_ms,
             cache_keys => 0 + keys %cache, cache_bytes => total_size(\%cache) };
}

## ---------------------------------------------------------------------------
## Per-line exact parity (not just sums): compare triples on every line.
## ---------------------------------------------------------------------------

sub verify_stream {
    my ($stream) = @_;
    my %c1; my %c2;
    my %p_contract  = ( iso => compile_contract('iso_ms', \%c1),  apache => compile_contract('apache_clf', \%c1) );
    my %p_datecache = ( iso => compile_datecache('iso_ms', \%c2), apache => compile_datecache('apache_clf', \%c2) );
    my %timestamp_cache;
    my $n = 0;
    for my $rec (@$stream) {
        $n++;
        my ($family, $ts) = @$rec;
        # inline oracle
        my $s = $ts;
        my $fms = strip_fraction($s);
        my $t;
        if ($family eq 'iso') {
            $t = $timestamp_cache{$s} //= timegm(substr($s,17,2), substr($s,14,2), substr($s,11,2), substr($s,8,2), substr($s,5,2)-1, substr($s,0,4));
        } else {
            my ($day, $mon, $yr, $h, $m, $sec) = $s =~ m/(\d{2})\/([A-Za-z]+)\/(\d{4}):(\d{2}):(\d{2}):(\d{2})/;
            $t = $timestamp_cache{$s} //= timegm($sec, $m, $h, $day, $month_map{$mon}-1, $yr);
        }
        my ($tc, $fc) = $p_contract{$family}->($ts);
        my ($td, $fd) = $p_datecache{$family}->($ts);
        if ($tc != $t || $fc != $fms || $td != $t || $fd != $fms) {
            die sprintf("PARITY FAILURE line %d ts='%s': inline=(%s,%s) contract=(%s,%s) datecache=(%s,%s)\n",
                $n, $ts, $t, $fms, $tc, $fc, $td, $fd);
        }
    }
    return $n;
}

## ---------------------------------------------------------------------------
## Driver
## ---------------------------------------------------------------------------

my @CANDS = (
    [ 'ts-inline',    \&run_inline ],
    [ 'ts-contract',  \&run_contract ],
    [ 'ts-datecache', \&run_datecache ],
);

Measure58::tsv_header(\*STDOUT);
foreach my $file (@ARGV) {
    (my $fixture = $file) =~ s{.*/}{};
    my $stream = prep_stream($file);
    if (!@$stream) {
        print STDERR "$fixture: no timestamps extracted — skipping\n";
        next;
    }
    my $n = verify_stream($stream);
    printf STDERR "%s: parity OK (%d timestamps, per-line triples identical across all candidates)\n", $fixture, $n;

    for my $cand (@CANDS) {
        my ($name, $runner) = @$cand;
        my $acc;
        my @secs = Measure58::time_runs($runs, sub { $acc = $runner->($stream) });
        my ($med, $min, $max) = Measure58::median_min_max(@secs);
        Measure58::emit_tsv(\*STDOUT, $name, $fixture, scalar @$stream, 'ns_per_line',
            map { $_ / @$stream * 1e9 } $med, $min, $max);
        printf STDERR "  %-13s epoch_sum=%.3f fms_sum=%s prec_ms=%d cache_keys=%d cache_bytes=%d\n",
            $name, $acc->{epoch_sum}, $acc->{fms_sum}, $acc->{prec_ms}, $acc->{cache_keys}, $acc->{cache_bytes};
    }
}
