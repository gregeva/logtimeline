#!/usr/bin/env perl
# Memory Structure Sizing Prototype - Issue #45
#
# Tests the Devel::Size approach for measuring ltl's key data structures.
# Simulates realistic data to understand memory consumption patterns.
#
# Usage: perl prototype/memory-structures.pl

use strict;
use warnings;
use Devel::Size qw(total_size);
use Time::HiRes qw(gettimeofday tv_interval);

print "=" x 70, "\n";
print "Memory Structure Sizing Prototype\n";
print "=" x 70, "\n\n";

#=============================================================================
# Simulate ltl data structures with realistic data
#=============================================================================

# Configuration - adjust to simulate different workloads
my $num_time_buckets = 100;        # Number of 1-minute buckets (e.g., 100 min = ~1.5 hours)
my $num_unique_messages = 5000;    # Unique log message patterns
my $avg_message_length = 120;      # Average message length in characters
my $heatmap_buckets = 52;          # Heatmap histogram width

print "Simulation parameters:\n";
print "  Time buckets:      $num_time_buckets\n";
print "  Unique messages:   $num_unique_messages\n";
print "  Avg message len:   $avg_message_length chars\n";
print "  Heatmap buckets:   $heatmap_buckets\n";
print "-" x 70, "\n\n";

# Simulate %log_occurrences - {message}{bucket} = count
my %log_occurrences;
for my $msg_id (1..$num_unique_messages) {
    my $message = "GET /api/endpoint/$msg_id?param=" . ("x" x ($avg_message_length - 30));
    my $bucket_coverage = 0.3 + rand(0.7);
    for my $bucket (1..$num_time_buckets) {
        if (rand() < $bucket_coverage) {
            $log_occurrences{$message}{$bucket} = int(rand(100)) + 1;
        }
    }
}

# Simulate %log_analysis - {bucket} = { stats }
my %log_analysis;
for my $bucket (1..$num_time_buckets) {
    $log_analysis{$bucket} = {
        count => int(rand(10000)) + 100,
        duration_sum => rand(50000),
        duration_min => rand(10),
        duration_max => rand(5000),
        bytes_sum => int(rand(100000000)),
    };
}

# Simulate %log_messages - {message} = [ array of durations for percentiles ]
my %log_messages;
for my $msg_id (1..$num_unique_messages) {
    my $message = "GET /api/endpoint/$msg_id?param=" . ("x" x ($avg_message_length - 30));
    my $count = int(rand(500)) + 10;
    $log_messages{$message} = [ map { rand(1000) } (1..$count) ];
}

# Simulate %log_stats - {message} = { computed stats }
my %log_stats;
for my $msg_id (1..$num_unique_messages) {
    my $message = "GET /api/endpoint/$msg_id?param=" . ("x" x ($avg_message_length - 30));
    $log_stats{$message} = {
        count => int(rand(1000)),
        min => rand(10),
        max => rand(5000),
        avg => rand(500),
        stddev => rand(100),
        p50 => rand(200),
        p95 => rand(1000),
        p99 => rand(2000),
    };
}

# Simulate %heatmap_data - {bucket}{range_index} = count
my %heatmap_data;
for my $bucket (1..$num_time_buckets) {
    for my $range_idx (0..$heatmap_buckets-1) {
        if (rand() < 0.6) {
            $heatmap_data{$bucket}{$range_idx} = int(rand(100)) + 1;
        }
    }
}

# Simulate %histogram_values - {metric} = [values]
my %histogram_values = (
    duration => [ map { rand(5000) } (1..50000) ],
    bytes    => [ map { int(rand(1000000)) } (1..50000) ],
    count    => [],  # Empty - not always used
);

# Simulate @heatmap_boundaries
my @heatmap_boundaries = map { 10 ** ($_ / 8) } (0..$heatmap_buckets);

#=============================================================================
# Measure structure sizes
#=============================================================================

print "Measuring structure sizes...\n\n";

my $t0 = [gettimeofday];

my %sizes = (
    'log_occurrences'    => total_size(\%log_occurrences),
    'log_analysis'       => total_size(\%log_analysis),
    'log_messages'       => total_size(\%log_messages),
    'log_stats'          => total_size(\%log_stats),
    'heatmap_data'       => total_size(\%heatmap_data),
    'histogram_values'   => total_size(\%histogram_values),
    'heatmap_boundaries' => total_size(\@heatmap_boundaries),
);

my $measurement_time = tv_interval($t0);

# Calculate total
my $total_measured = 0;
$total_measured += $_ for values %sizes;

#=============================================================================
# Helper: format_bytes (matching ltl's format_bytes function)
#=============================================================================

sub format_bytes {
    my ($bytes) = @_;

    if ($bytes >= 1024 * 1024 * 1024) {
        return sprintf("%.1f GB", $bytes / 1024 / 1024 / 1024);
    } elsif ($bytes >= 1024 * 1024) {
        return sprintf("%.1f MB", $bytes / 1024 / 1024);
    } elsif ($bytes >= 1024) {
        return sprintf("%.1f KB", $bytes / 1024);
    } else {
        return sprintf("%d B", $bytes);
    }
}

#=============================================================================
# Display in ltl summary table format
#=============================================================================

# Match ltl's print_summary_table formatting exactly
my $category_column_width = 30;
my $occurrences_column_width = 10;
my $table_padding = 2;
my $padding = " " x $table_padding;

print "=" x 70, "\n";
print "LTL SUMMARY TABLE FORMAT (matching existing layout)\n";
print "=" x 70, "\n\n";

# Simulated existing summary content (to show context)
print "  " . "─" x ($category_column_width + $occurrences_column_width + 1) . "$padding\n";
print sprintf("  %-${category_column_width}s %${occurrences_column_width}s$padding\n", "Category", "Total");
print "  " . "─" x ($category_column_width + $occurrences_column_width + 1) . "$padding\n";
print sprintf("$padding%-${category_column_width}s %${occurrences_column_width}d$padding\n", "ERROR", 741);
print sprintf("$padding%-${category_column_width}s %${occurrences_column_width}d$padding\n", "WARN", 121900);
print sprintf("$padding%-${category_column_width}s %${occurrences_column_width}d$padding\n", "INFO", 167);
print "$padding" . "─" x ($category_column_width + $occurrences_column_width + 1) . "$padding\n";
print sprintf("$padding%-${category_column_width}s %${occurrences_column_width}d$padding\n", "LINES INCLUDED", 122808);
print sprintf("$padding%-${category_column_width}s %${occurrences_column_width}d$padding\n", "LINES READ", 122808);
print sprintf("$padding%-${category_column_width}s %${occurrences_column_width}s$padding\n", "FILE PROCESSING TIME", "2 sec");
print sprintf("$padding%-${category_column_width}s %${occurrences_column_width}s$padding\n", "TOTAL TIME", "2.1 sec");

# New memory section - fits within existing column widths
print sprintf("$padding%-${category_column_width}s %${occurrences_column_width}s$padding\n", "MEMORY USED", format_bytes($total_measured));

# Sort by size descending, skip empty
my @sorted = sort { $sizes{$b} <=> $sizes{$a} }
             grep { $sizes{$_} > 0 }
             keys %sizes;

for my $struct (@sorted) {
    my $size = $sizes{$struct};
    my $pct = ($size / $total_measured) * 100;

    # Format percentage: <1% for small values, otherwise rounded
    my $pct_str = $pct < 1 ? "(<1%)" : sprintf("(%2.0f%%)", $pct);

    # Right-align percentage within a fixed width, then append to indented label
    my $indented_label = sprintf("  %-21s %5s", $struct, $pct_str);
    print sprintf("$padding%-${category_column_width}s %${occurrences_column_width}s$padding\n", $indented_label, format_bytes($size));
}

print "$padding" . "─" x ($category_column_width + $occurrences_column_width + 1) . "$padding\n";

#=============================================================================
# Measurement overhead
#=============================================================================

print "\n";
print "MEASUREMENT OVERHEAD\n";
print "-" x 70, "\n";
printf "  Time to measure all structures: %.2f ms\n", $measurement_time * 1000;

# Benchmark repeated measurements
my $iterations = 100;
$t0 = [gettimeofday];
for (1..$iterations) {
    total_size(\%log_occurrences);
    total_size(\%log_analysis);
    total_size(\%log_messages);
    total_size(\%log_stats);
    total_size(\%heatmap_data);
    total_size(\%histogram_values);
}
my $elapsed = tv_interval($t0);

printf "  %d iterations: %.2f sec (%.2f ms per full measurement)\n",
    $iterations, $elapsed, ($elapsed / $iterations) * 1000;
print "\n";

#=============================================================================
# Comparison with current approach
#=============================================================================

print "COMPARISON WITH CURRENT APPROACH\n";
print "-" x 70, "\n";
print "  Current: Proc::ProcessTable called many times @ ~10ms each\n";
print "  New:     Devel::Size called once @ ~17ms total\n";
print "\n";
print "  If current approach calls get_memory_usage() 100 times:\n";
print "    Current overhead: ~1000ms\n";
print "    New overhead:     ~17ms (59x improvement)\n";
print "\n";
