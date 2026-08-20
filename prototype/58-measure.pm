package Measure58;
#
# Shared measurement scaffold for the #58 prototypes.
#
# Every #58 prototype surfaces the same two evaluation measures — time
# taken and memory used — in the same TSV shape, so results from any
# candidate/mini-proto paste directly into the feature doc's decision
# tables:
#
#   candidate<TAB>fixture<TAB>lines<TAB>metric<TAB>median<TAB>min<TAB>max
#
# Timing protocol: one untimed warmup pass (filesystem cache), then N
# timed runs; report median with min-max range. Memory: process RSS
# delta around the workload, and callers may additionally report
# Devel::Size::total_size of persistent structures as their own metric
# rows.

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);

sub time_runs {          # (runs, coderef) -> list of wall-clock seconds
    my ($runs, $code) = @_;
    $code->();           # warmup, untimed
    my @secs;
    for (1 .. $runs) {
        my $t0 = [gettimeofday];
        $code->();
        push @secs, tv_interval($t0);
    }
    return @secs;
}

sub median_min_max {     # (list) -> (median, min, max)
    my @s = sort { $a <=> $b } @_;
    my $n = @s;
    my $median = $n % 2 ? $s[$n >> 1] : ($s[$n / 2 - 1] + $s[$n / 2]) / 2;
    return ($median, $s[0], $s[-1]);
}

sub rss_kb {             # current process RSS in kB
    my $rss = `ps -o rss= -p $$`;
    $rss =~ s/\s+//g;
    return $rss + 0;
}

sub emit_tsv {           # (fh, candidate, fixture, lines, metric, median, min, max)
    my ($fh, @cols) = @_;
    printf {$fh} "%s\t%s\t%d\t%s\t%.6g\t%.6g\t%.6g\n", @cols;
}

sub tsv_header {
    my ($fh) = @_;
    print {$fh} join("\t", qw(candidate fixture lines metric median min max)), "\n";
}

1;
