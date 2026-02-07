#!/usr/bin/env perl
# Memory Tracking Benchmark - Issue #45
# Compares different approaches for getting process memory usage
#
# Usage: perl prototype/memory-benchmark.pl [iterations]
#        Default: 1000 iterations

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);

my $iterations = $ARGV[0] // 1000;
my $platform = $^O;

print "=" x 60, "\n";
print "Memory Tracking Benchmark\n";
print "=" x 60, "\n";
print "Platform: $platform\n";
print "Iterations: $iterations\n";
print "PID: $$\n";
print "-" x 60, "\n\n";

# Store results for comparison
my %results;

#=============================================================================
# Method 1: Current implementation (Proc::ProcessTable)
#=============================================================================
if ($platform eq 'darwin' || $platform eq 'linux') {
    print "Method 1: Proc::ProcessTable (current implementation)\n";

    eval { require Proc::ProcessTable };
    if ($@) {
        print "  SKIPPED: Proc::ProcessTable not installed\n\n";
    } else {
        my $t0 = [gettimeofday];
        my $memory;

        for (1..$iterations) {
            my $t = Proc::ProcessTable->new();
            ($memory) = map { $_->rss } grep { $_->pid == $$ } @{$t->table};
        }

        my $elapsed = tv_interval($t0);
        my $per_call = ($elapsed / $iterations) * 1000;  # ms

        $results{'Proc::ProcessTable'} = {
            elapsed => $elapsed,
            per_call_ms => $per_call,
            memory => $memory,
        };

        printf "  Total time: %.4f sec\n", $elapsed;
        printf "  Per call:   %.4f ms\n", $per_call;
        printf "  RSS value:  %d bytes (%.2f MB)\n\n", $memory, $memory / 1024 / 1024;
    }
}

#=============================================================================
# Method 2: Direct /proc access (Linux only)
#=============================================================================
if ($platform eq 'linux') {
    print "Method 2: Direct /proc/PID/statm access\n";

    my $t0 = [gettimeofday];
    my $memory;
    my $page_size = `getconf PAGE_SIZE` || 4096;
    chomp $page_size;

    for (1..$iterations) {
        if (open my $fh, '<', "/proc/$$/statm") {
            my $line = <$fh>;
            close $fh;
            my @fields = split /\s+/, $line;
            $memory = $fields[1] * $page_size;  # RSS is 2nd field
        }
    }

    my $elapsed = tv_interval($t0);
    my $per_call = ($elapsed / $iterations) * 1000;

    $results{'/proc/statm'} = {
        elapsed => $elapsed,
        per_call_ms => $per_call,
        memory => $memory,
    };

    printf "  Total time: %.4f sec\n", $elapsed;
    printf "  Per call:   %.4f ms\n", $per_call;
    printf "  RSS value:  %d bytes (%.2f MB)\n\n", $memory, $memory / 1024 / 1024;
}

#=============================================================================
# Method 3: ps command (Unix - portable)
#=============================================================================
if ($platform eq 'darwin' || $platform eq 'linux') {
    print "Method 3: ps command (portable Unix)\n";

    my $t0 = [gettimeofday];
    my $memory;

    for (1..$iterations) {
        # ps returns RSS in KB on both macOS and Linux
        $memory = `ps -o rss= -p $$`;
        chomp $memory;
        $memory *= 1024;  # Convert to bytes
    }

    my $elapsed = tv_interval($t0);
    my $per_call = ($elapsed / $iterations) * 1000;

    $results{'ps command'} = {
        elapsed => $elapsed,
        per_call_ms => $per_call,
        memory => $memory,
    };

    printf "  Total time: %.4f sec\n", $elapsed;
    printf "  Per call:   %.4f ms\n", $per_call;
    printf "  RSS value:  %d bytes (%.2f MB)\n\n", $memory, $memory / 1024 / 1024;
}

#=============================================================================
# Method 4: macOS vm_stat / task_info via ps -o rss (already covered)
# Method 4 alt: Direct syscall approach placeholder
#=============================================================================
if ($platform eq 'darwin') {
    print "Method 4: macOS - read from ps with minimal shell\n";

    my $t0 = [gettimeofday];
    my $memory;

    for (1..$iterations) {
        # Slightly optimized: avoid shell interpretation
        open my $ps, '-|', 'ps', '-o', 'rss=', '-p', $$;
        $memory = <$ps>;
        close $ps;
        chomp $memory if $memory;
        $memory = ($memory // 0) * 1024;
    }

    my $elapsed = tv_interval($t0);
    my $per_call = ($elapsed / $iterations) * 1000;

    $results{'ps (no shell)'} = {
        elapsed => $elapsed,
        per_call_ms => $per_call,
        memory => $memory,
    };

    printf "  Total time: %.4f sec\n", $elapsed;
    printf "  Per call:   %.4f ms\n", $per_call;
    printf "  RSS value:  %d bytes (%.2f MB)\n\n", $memory, $memory / 1024 / 1024;
}

#=============================================================================
# Method 5: Devel::Size for data structure measurement
#=============================================================================
print "Method 5: Devel::Size (for measuring data structures)\n";

eval { require Devel::Size };
if ($@) {
    print "  SKIPPED: Devel::Size not installed\n";
    print "  Install with: cpanm Devel::Size\n\n";
} else {
    Devel::Size->import('total_size');

    # Create some test data structures similar to ltl
    my %test_hash;
    my @test_array;
    for (1..10000) {
        $test_hash{"key_$_"} = "value_" . ("x" x 100);
        push @test_array, "element_$_";
    }

    my $t0 = [gettimeofday];
    my ($hash_size, $array_size);

    for (1..$iterations) {
        $hash_size = total_size(\%test_hash);
        $array_size = total_size(\@test_array);
    }

    my $elapsed = tv_interval($t0);
    my $per_call = ($elapsed / $iterations) * 1000;

    $results{'Devel::Size'} = {
        elapsed => $elapsed,
        per_call_ms => $per_call,
        memory => $hash_size + $array_size,
    };

    printf "  Total time: %.4f sec (measuring 2 structures per iteration)\n", $elapsed;
    printf "  Per call:   %.4f ms\n", $per_call;
    printf "  Hash size:  %d bytes (%.2f MB)\n", $hash_size, $hash_size / 1024 / 1024;
    printf "  Array size: %d bytes (%.2f KB)\n\n", $array_size, $array_size / 1024;
}

#=============================================================================
# Method 6: Windows - Win32::Process::Info
#=============================================================================
if ($platform eq 'MSWin32') {
    print "Method 6: Win32::Process::Info (current Windows implementation)\n";

    eval {
        require Win32::Process::Info;
        Win32::Process::Info->import();
    };
    if ($@) {
        print "  SKIPPED: Win32::Process::Info not installed\n\n";
    } else {
        my $t0 = [gettimeofday];
        my $memory;

        for (1..$iterations) {
            my $pi = Win32::Process::Info->new();
            my $info = $pi->GetProcInfo();
            ($memory) = map { $_->{WorkingSetSize} }
                        grep { $_->{ProcessId} == $$ } @$info;
        }

        my $elapsed = tv_interval($t0);
        my $per_call = ($elapsed / $iterations) * 1000;

        $results{'Win32::Process::Info'} = {
            elapsed => $elapsed,
            per_call_ms => $per_call,
            memory => $memory,
        };

        printf "  Total time: %.4f sec\n", $elapsed;
        printf "  Per call:   %.4f ms\n", $per_call;
        printf "  Working Set: %d bytes (%.2f MB)\n\n", $memory, $memory / 1024 / 1024;
    }

    # Windows alternative: wmic or tasklist
    print "Method 7: Windows - tasklist command\n";

    my $t0 = [gettimeofday];
    my $memory;

    # Note: tasklist is slow, only run fewer iterations
    my $win_iterations = $iterations > 100 ? 100 : $iterations;

    for (1..$win_iterations) {
        my $output = `tasklist /FI "PID eq $$" /FO CSV /NH 2>nul`;
        if ($output =~ /"([0-9,]+)\s*K"/) {
            $memory = $1;
            $memory =~ s/,//g;
            $memory *= 1024;
        }
    }

    my $elapsed = tv_interval($t0);
    my $per_call = ($elapsed / $win_iterations) * 1000;

    $results{'tasklist'} = {
        elapsed => $elapsed,
        per_call_ms => $per_call,
        memory => $memory,
        note => "(only $win_iterations iterations)",
    };

    printf "  Total time: %.4f sec (%d iterations)\n", $elapsed, $win_iterations;
    printf "  Per call:   %.4f ms\n", $per_call;
    printf "  Memory:     %d bytes (%.2f MB)\n\n", $memory // 0, ($memory // 0) / 1024 / 1024;
}

#=============================================================================
# Summary
#=============================================================================
print "=" x 60, "\n";
print "SUMMARY\n";
print "=" x 60, "\n";

my @sorted = sort { $results{$a}{per_call_ms} <=> $results{$b}{per_call_ms} } keys %results;

printf "%-25s %12s %12s\n", "Method", "Per Call", "Relative";
print "-" x 50, "\n";

my $baseline = $sorted[0] ? $results{$sorted[0]}{per_call_ms} : 1;

for my $method (@sorted) {
    my $r = $results{$method};
    my $relative = $r->{per_call_ms} / $baseline;
    printf "%-25s %10.4f ms %10.1fx\n", $method, $r->{per_call_ms}, $relative;
}

print "\n";
print "Fastest method: $sorted[0]\n" if @sorted;

#=============================================================================
# Recommendations based on platform
#=============================================================================
print "\n";
print "=" x 60, "\n";
print "RECOMMENDATIONS\n";
print "=" x 60, "\n";

if ($platform eq 'linux') {
    print "For Linux:\n";
    print "  - Use direct /proc/\$\$/statm access (fastest, no dependencies)\n";
    print "  - Use Devel::Size for per-structure breakdown\n";
} elsif ($platform eq 'darwin') {
    print "For macOS:\n";
    print "  - Use ps command (portable, reasonably fast)\n";
    print "  - Consider caching/throttling to reduce overhead\n";
    print "  - Use Devel::Size for per-structure breakdown\n";
} elsif ($platform eq 'MSWin32') {
    print "For Windows:\n";
    print "  - Current Win32::Process::Info is slow\n";
    print "  - Consider single measurement at peak instead of continuous\n";
    print "  - Use Devel::Size for per-structure breakdown\n";
}

print "\nAlternative approach:\n";
print "  - Measure RSS once at 'peak' (after all structures populated)\n";
print "  - Use Devel::Size to measure individual data structures\n";
print "  - Calculate percentage breakdown from structure sizes\n";
print "  - This gives structural insight with minimal runtime cost\n";
