#!/opt/homebrew/bin/perl
#
# extract-profile.pl — Extract subroutine profile data from nytprof.out
#
# Usage:
#   extract-profile.pl [options]
#
# Options:
#   --file <path>          Path to nytprof.out (default: ./nytprof.out)
#   --top N                Show top N subroutines (default: 25)
#   --sort incl|excl       Sort by inclusive or exclusive time (default: incl)
#   --all                  Include XSubs [xs] and opcodes [op] (default: Perl subs only)
#   --package <pkg>        Filter to specific package (e.g. main)
#   --match <pattern>      Filter subroutine names by regex pattern
#   --lines <subname>      Show line-level hotspots for a specific subroutine
#   --verbose-file <path>  Parse ltl -V output for cross-validation
#   --help                 Show this help
#
# Output columns:
#   Rank  Subroutine  Calls  Incl(s)  Excl(s)  ms/call  %Tot
#
# Cross-validation (--verbose-file):
#   Compares NYTProf call counts against ltl's internal counters from -V output:
#   - find_candidates NYTProf calls vs fc_calls from consolidation summary
#   - match_against_patterns calls vs S1 inline match count
#   - lines_read sanity check
#   Flags >5% discrepancies as [WARN].
#
# Examples:
#   extract-profile.pl --file results/20260309-120000/1k/nytprof.out
#   extract-profile.pl --top 40 --sort excl
#   extract-profile.pl --match consolidat --all
#   extract-profile.pl --lines dice_coefficient
#   extract-profile.pl --verbose-file verbose.txt
#
# Issue #138: Standardized NYTProf profiling workflow

use strict;
use warnings;
use Devel::NYTProf::Data;
use Getopt::Long qw(:config no_ignore_case);

# --- Option parsing ---
my $file         = 'nytprof.out';
my $top          = 25;
my $sort_by      = 'incl';
my $show_all     = 0;
my $package_filt = undef;
my $match        = undef;
my $lines_sub    = undef;
my $verbose_file = undef;
my $help         = 0;

GetOptions(
    'file=s'         => \$file,
    'top=i'          => \$top,
    'sort=s'         => \$sort_by,
    'all'            => \$show_all,
    'package=s'      => \$package_filt,
    'match=s'        => \$match,
    'lines=s'        => \$lines_sub,
    'verbose-file=s' => \$verbose_file,
    'help'           => \$help,
) or die "Error parsing options. Use --help for usage.\n";

if ($help) {
    open my $fh, '<', $0 or die "Cannot read self: $!";
    while (<$fh>) {
        last unless /^#/;
        s/^# ?//;
        print;
    }
    exit 0;
}

die "Unknown --sort value '$sort_by'. Use 'incl' or 'excl'.\n"
    unless $sort_by eq 'incl' || $sort_by eq 'excl';

die "Profile file not found: $file\n" unless -f $file;

# --- Load profile ---
my $profile = Devel::NYTProf::Data->new({ filename => $file, quiet => 1 });
my %subs    = %{ $profile->subname_subinfo_map };

# --- Compute total CPU time ---
# Sum of all excl_time = total measurable Perl CPU time (avoids double-counting)
my $total_cpu = 0;
for my $si (values %subs) {
    $total_cpu += ($si->excl_time // 0);
}
$total_cpu = 1e-9 if $total_cpu < 1e-9;

# --- Filter ---
my @filtered;
for my $name (keys %subs) {
    my $si = $subs{$name};
    unless ($show_all) {
        next if eval { $si->is_xsub };
        next if eval { $si->is_opcode };
    }
    if (defined $package_filt) {
        next unless (eval { $si->package } // '') eq $package_filt;
    }
    if (defined $match) {
        next unless $name =~ /$match/i;
    }
    next unless (eval { $si->calls } // 0) > 0;
    push @filtered, $si;
}

# --- Sort ---
if ($sort_by eq 'excl') {
    @filtered = sort { ($b->excl_time // 0) <=> ($a->excl_time // 0) } @filtered;
} else {
    @filtered = sort { ($b->incl_time // 0) <=> ($a->incl_time // 0) } @filtered;
}

my $show_count = $top < scalar(@filtered) ? $top : scalar(@filtered);
my @top_subs = @filtered[0 .. $show_count - 1];

# --- Format helpers ---
sub fmt_time {
    my ($t) = @_;
    return '       -' unless defined $t && $t > 0;
    return sprintf('%8.4f', $t) if $t >= 0.0001;
    return sprintf('%8.6f', $t);
}

sub fmt_ms_per_call {
    my ($incl, $calls) = @_;
    return '       -' unless defined $incl && defined $calls && $calls > 0;
    my $ms = ($incl / $calls) * 1000;
    return sprintf('%8.3f', $ms) if $ms >= 0.001;
    return sprintf('%8.6f', $ms);
}

sub fmt_pct {
    my ($incl) = @_;
    return '    -' unless defined $incl && $total_cpu > 0;
    return sprintf('%5.1f', ($incl / $total_cpu) * 100);
}

sub shorten_name {
    my ($name) = @_;
    $name =~ s/^main:://;
    return length($name) > 52 ? substr($name, 0, 49) . '...' : $name;
}

# --- Build call count index for cross-validation ---
# Map short name (no main::) to NYTProf call count
my %nytprof_calls;
for my $si (values %subs) {
    my $short = eval { $si->subname } // '';
    $short =~ s/^main:://;
    $nytprof_calls{$short} = eval { $si->calls } // 0;
}

# --- Parse verbose file for cross-validation ---
my %v;  # verbose metrics
if (defined $verbose_file && -f $verbose_file) {
    open my $fh, '<', $verbose_file or die "Cannot read verbose file: $verbose_file\n";
    my $in_benchmark = 0;
    while (<$fh>) {
        chomp;
        if (/^=== BENCHMARK DATA ===/) { $in_benchmark = 1; next }
        if (/^=== END BENCHMARK DATA ===/) { $in_benchmark = 0; next }
        if ($in_benchmark) {
            if (/^lines_read\t(\d+)/)       { $v{lines_read}  = $1 }
            if (/^TIMING\ttotal\t([\d.]+)/) { $v{total_time}  = $1 }
            if (/^MEMORY\trss_peak\t(\d+)/) { $v{rss_peak}    = $1 }
        }
        # Consolidation summary — fc_calls
        if (/Grand total.*find_candidates calls:\s*(\d+)/i) { $v{fc_calls} = $1 }
        if (/find_candidates calls:\s*(\d+)/) { $v{fc_calls} //= $1 }
        # S1 inline match count (sum across all cat_gk)
        if (/S1 inline.*?:\s*(\d+)/) { $v{s1_inline} = ($v{s1_inline} // 0) + $1 }
        # Single cat_gk fc_calls (fallback if no grand total)
        if (/fc_calls:\s*(\d+)/) { $v{fc_calls} //= $1 }
    }
    close $fh;
}

# --- Print header ---
my $attrs    = $profile->attributes // {};
my $app      = $attrs->{application}       // '(unknown)';
my $perl_ver = $attrs->{perl_version}      // '(unknown)';

print  "=" x 100 . "\n";
printf "Profile:  %s\n", $file;
printf "Script:   %s\n", $app;
printf "Perl:     %s\n", $perl_ver;
printf "CPU time: %.4f s (sum of exclusive times)\n", $total_cpu;
printf "Subs:     %d shown of %d matching (from %d total)\n",
    $show_count, scalar(@filtered), scalar(keys %subs);
printf "Sort:     %s time | Filter: %s\n",
    $sort_by,
    ($show_all ? 'all' : 'Perl subs only')
    . (defined $package_filt ? ", package=$package_filt" : '')
    . (defined $match        ? ", match=$match"          : '');

# Show key verbose metrics if available
if (%v) {
    printf "ltl -V:   lines_read=%s  total=%.3fs  rss=%.0f MB\n",
        ($v{lines_read} // '?'),
        ($v{total_time} // 0),
        (($v{rss_peak} // 0) / 1_048_576);
}
print  "=" x 100 . "\n\n";

# --- Print table ---
printf "%-4s  %-52s  %8s  %8s  %8s  %8s  %5s\n",
    'Rank', 'Subroutine', 'Calls', 'Incl(s)', 'Excl(s)', 'ms/call', '%Tot';
print "-" x 100 . "\n";

my $rank = 1;
for my $si (@top_subs) {
    my $name  = shorten_name(eval { $si->subname } // '(anon)');
    my $calls = eval { $si->calls }     // 0;
    my $incl  = eval { $si->incl_time } // 0;
    my $excl  = eval { $si->excl_time } // 0;

    my $kind_marker = '';
    $kind_marker = ' [xs]' if eval { $si->is_xsub };
    $kind_marker = ' [op]' if eval { $si->is_opcode };

    printf "%4d  %-52s  %8d  %s  %s  %s  %s\n",
        $rank++,
        $name . $kind_marker,
        $calls,
        fmt_time($incl),
        fmt_time($excl),
        fmt_ms_per_call($incl, $calls),
        fmt_pct($incl);
}

print "\n";
printf "Note: %%Tot = incl_time / %.4f s (total Perl CPU time)\n", $total_cpu;
print  "      Use --all to include XSubs [xs] and opcodes [op]\n" unless $show_all;
print  "      Use --sort excl to rank by exclusive time\n" if $sort_by eq 'incl';

# --- Cross-validation section ---
if (defined $verbose_file && -f $verbose_file && %v) {
    print "\n" . "=" x 100 . "\n";
    print "Cross-Validation: NYTProf call counts vs ltl -V output\n";
    print "-" x 100 . "\n";

    my @warnings;
    my @checks;

    # Check 1: find_candidates call count
    if (exists $v{fc_calls}) {
        my $nyt = $nytprof_calls{find_candidates} // 0;
        my $v   = $v{fc_calls};
        my $pct = $v > 0 ? abs($nyt - $v) / $v * 100 : 0;
        my $status = $pct <= 5 ? "OK" : "MISMATCH";
        push @checks, sprintf("  find_candidates:        NYTProf=%7d  ltl-V=%7d  diff=%+.1f%%  [%s]",
            $nyt, $v, ($nyt - $v) / ($v || 1) * 100, $status);
        push @warnings, "find_candidates call count mismatch ($pct% diff)" if $pct > 5;
    } else {
        push @checks, "  find_candidates:        (no fc_calls in -V output — run with -g to get consolidation stats)";
    }

    # Check 2: match_against_patterns vs S1 inline count
    if (exists $v{s1_inline}) {
        my $nyt = $nytprof_calls{match_against_patterns}
               // $nytprof_calls{inline_match}
               // 0;
        my $v   = $v{s1_inline};
        my $pct = $v > 0 ? abs($nyt - $v) / $v * 100 : 0;
        my $status = $pct <= 5 ? "OK" : "MISMATCH";
        push @checks, sprintf("  match/inline vs S1:     NYTProf=%7d  ltl-V=%7d  diff=%+.1f%%  [%s]",
            $nyt, $v, ($nyt - $v) / ($v || 1) * 100, $status);
        push @warnings, "match_against_patterns vs S1 inline mismatch ($pct% diff)" if $pct > 5;
    }

    # Check 3: lines_read sanity
    if (exists $v{lines_read}) {
        my $nyt_read = $nytprof_calls{read_and_process_logs} // 0;
        push @checks, sprintf("  read_and_process_logs:  NYTProf calls=%d  ltl-V lines_read=%d",
            $nyt_read, $v{lines_read});
        push @checks, "    (read_and_process_logs is called once; it loops internally over lines)";
    }

    print "$_\n" for @checks;

    if (@warnings) {
        print "\n";
        for my $w (@warnings) {
            print "  [WARN] Cross-validation mismatch: $w\n";
        }
        print "  => Investigate: are hot functions being called more than expected?\n";
        print "     Check S1/S2/S3/S4/S5 counts in verbose.txt for accounting gaps.\n";
    } else {
        print "\n  [OK] All cross-validation checks within 5% tolerance.\n";
    }
}

# --- Line-level hotspots ---
if (defined $lines_sub) {
    my $target = "main::$lines_sub";
    $target = $lines_sub if $lines_sub =~ /::/;

    my $si = $subs{$target};
    unless (defined $si) {
        ($si) = grep { lc(eval { $_->subname } // '') eq lc($target) } values %subs;
    }

    print "\n" . "=" x 100 . "\n";
    if (!defined $si) {
        print "Sub not found: $lines_sub\n";
        print "Subs matching pattern:\n";
        for my $name (sort grep { /$lines_sub/i } keys %subs) {
            printf "  %s (calls=%d)\n", $name, ($subs{$name}->calls // 0);
        }
    } else {
        my $fi     = eval { $si->fileinfo };
        my $first  = eval { $si->first_line } // 0;
        my $last   = eval { $si->last_line }  // 0;
        printf "Line hotspots: %s (lines %d-%d)\n", $si->subname, $first, $last;

        if (!$fi) {
            print "  (no file info available — may be built-in or XSub)\n";
        } else {
            printf "  %-6s  %10s  %12s\n", 'Line', 'Count', 'Time(s)';
            print  "  " . "-" x 32 . "\n";

            my $fid = eval { $si->fid };
            my $line_data = defined($fid) ? eval { $fi->line_time_data([$fid]) } : undef;

            if ($line_data) {
                my @hot;
                for my $lineno ($first .. $last) {
                    my $ld = $line_data->[$lineno] or next;
                    my ($count, $time) = @$ld;
                    next unless ($count // 0) > 0;
                    push @hot, [$lineno, $count, $time // 0];
                }
                @hot = sort { $b->[2] <=> $a->[2] } @hot;
                @hot = @hot[0..19] if @hot > 20;
                for my $row (@hot) {
                    printf "  %-6d  %10d  %12.6f\n", @$row;
                }
                print "  (showing top 20 lines by time)\n" if @hot == 20;
            } else {
                print "  (no line-level data available — profile may lack statement timing)\n";
            }
        }
    }
}
