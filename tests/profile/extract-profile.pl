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
#   --checks-file <path>   Declarative cross-validation table (TSV) — see tests/profile/checks/
#   --help                 Show this help
#
# Output columns:
#   Rank  Subroutine  Calls  Incl(s)  Excl(s)  ms/call  %Tot
#
# Cross-validation (--verbose-file):
#   Parses -V output from the feature's own section (NOT the BENCHMARK DATA block).
#   With --checks-file: runs declarative checks from TSV table.
#   Without --checks-file: runs built-in checks (lines_read sanity only).
#   Flags >tolerance discrepancies as [WARN].
#
# Checks file format (TSV, see tests/profile/checks/README.md):
#   nytprof_sub   v_expression   tolerance   label
#   find_candidates   fc_calls   5%   "find_candidates vs fc_calls"
#   match_against_patterns   s1_inline+s3_checkpoint   5%   "match vs S1+S3"
#   read_and_process_logs   1   exact   "called exactly once"
#
# Examples:
#   extract-profile.pl --file results/20260309-120000/1k/nytprof.out
#   extract-profile.pl --top 40 --sort excl
#   extract-profile.pl --match consolidat --all
#   extract-profile.pl --lines dice_coefficient
#   extract-profile.pl --verbose-file verbose.txt
#   extract-profile.pl --verbose-file verbose.txt --checks-file tests/profile/checks/consolidation.tsv
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
my $checks_file  = undef;
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
    'checks-file=s'  => \$checks_file,
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

# --- Parse verbose file ---
# Extracts machine-readable counters from ltl -V output.
# The BENCHMARK DATA block covers performance regression metrics (lines_read, timing, memory).
# Feature-specific flow counters (fc_calls, S1-S5, etc.) live in their own sections.
my %v;  # verbose metrics
my @verbose_lines;  # all lines, for regex-based extraction by checks file
if (defined $verbose_file && -f $verbose_file) {
    open my $fh, '<', $verbose_file or die "Cannot read verbose file: $verbose_file\n";
    my $in_benchmark = 0;
    while (<$fh>) {
        chomp;
        push @verbose_lines, $_;
        if (/^=== BENCHMARK DATA ===/) { $in_benchmark = 1; next }
        if (/^=== END BENCHMARK DATA ===/) { $in_benchmark = 0; next }
        if ($in_benchmark) {
            if (/^lines_read\t(\d+)/)       { $v{lines_read}  = $1 }
            if (/^TIMING\ttotal\t([\d.]+)/) { $v{total_time}  = $1 }
            if (/^MEMORY\trss_peak\t(\d+)/) { $v{rss_peak}    = $1 }
        }
    }
    close $fh;
}

# --- Parse checks file ---
# Format: nytprof_sub <TAB> v_expression <TAB> tolerance <TAB> label
# v_expression: a key name (extracted by regex from verbose file), a sum (key1+key2),
#               or a literal integer (for "exact N" checks).
# tolerance: "N%" for percentage, "exact" for exact match.
# Lines starting with # are comments.
#
# Each check entry declares an extraction regex to find its counter in the verbose output.
# Format with regex: nytprof_sub <TAB> v_expression <TAB> tolerance <TAB> label <TAB> regex
# If regex is absent, v_expression is treated as a key already populated in %v.
my @check_rows;
if (defined $checks_file) {
    die "Checks file not found: $checks_file\n" unless -f $checks_file;
    open my $fh, '<', $checks_file or die "Cannot read checks file: $checks_file\n";
    while (<$fh>) {
        chomp;
        next if /^\s*#/ || /^\s*$/;
        my ($sub, $expr, $tol, $label, $regex) = split /\t/, $_, 5;
        next unless defined $sub && defined $expr && defined $tol;
        $label //= "$sub vs $expr";
        push @check_rows, {
            sub   => $sub,
            expr  => $expr,
            tol   => $tol,
            label => $label,
            regex => $regex,
        };
    }
    close $fh;
    # Extract values for each check that has a regex
    for my $row (@check_rows) {
        next unless defined $row->{regex} && length($row->{regex});
        my $rx = $row->{regex};
        # Support summing across multiple lines (e.g., S1 per category)
        my $accumulate = ($rx =~ s/^\+//);  # leading + means sum all matches
        my $val = undef;
        for my $line (@verbose_lines) {
            if ($line =~ /$rx/) {
                my $n = $1 // 0;
                if ($accumulate) {
                    $val = ($val // 0) + $n;
                } else {
                    $val //= $n;
                }
            }
        }
        # Store extracted value under the expression key for later evaluation
        $v{$row->{expr}} = $val if defined $val && !exists $v{$row->{expr}};
    }
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
my $do_xval = (defined $verbose_file && -f $verbose_file && %v) || @check_rows;
if ($do_xval) {
    print "\n" . "=" x 100 . "\n";
    print "Cross-Validation: NYTProf call counts vs ltl -V output\n";
    print "-" x 100 . "\n";

    my @warnings;
    my @checks;

    # --- Declarative checks from --checks-file ---
    for my $row (@check_rows) {
        my $sub_name = $row->{sub};
        my $expr     = $row->{expr};
        my $tol      = $row->{tol};
        my $label    = $row->{label};

        my $nyt = $nytprof_calls{$sub_name} // 0;

        # Evaluate v_expression: may be a key, a sum (key1+key2), or a literal integer
        my $expected = undef;
        if ($expr =~ /^\d+$/) {
            $expected = $expr + 0;
        } elsif ($expr =~ /\+/) {
            my $sum = 0;
            my $all_defined = 1;
            for my $key (split /\+/, $expr) {
                if (exists $v{$key}) { $sum += $v{$key} }
                else { $all_defined = 0 }
            }
            $expected = $sum if $all_defined;
        } elsif (exists $v{$expr}) {
            $expected = $v{$expr};
        }

        unless (defined $expected) {
            push @checks, sprintf("  %-40s  (counter not found in -V output — check regex or run with relevant options)", $label);
            next;
        }

        if ($tol eq 'exact') {
            my $status = $nyt == $expected ? "OK" : "MISMATCH";
            push @checks, sprintf("  %-40s  NYTProf=%7d  ltl-V=%7d  [%s]", $label, $nyt, $expected, $status);
            push @warnings, "$label (expected $expected, got $nyt)" if $nyt != $expected;
        } else {
            my ($pct_tol) = $tol =~ /^([\d.]+)%$/;
            $pct_tol //= 5;
            my $pct = $expected > 0 ? abs($nyt - $expected) / $expected * 100 : 0;
            my $status = $pct <= $pct_tol ? "OK" : "MISMATCH";
            push @checks, sprintf("  %-40s  NYTProf=%7d  ltl-V=%7d  diff=%+.1f%%  [%s]",
                $label, $nyt, $expected, ($nyt - $expected) / ($expected || 1) * 100, $status);
            push @warnings, "$label ($pct% diff, tolerance ${pct_tol}%)" if $pct > $pct_tol;
        }
    }

    # --- Always: lines_read sanity (from BENCHMARK DATA block) ---
    if (exists $v{lines_read}) {
        my $nyt_read = $nytprof_calls{read_and_process_logs} // 0;
        push @checks, sprintf("  %-40s  NYTProf calls=%d  ltl-V lines_read=%d",
            "read_and_process_logs", $nyt_read, $v{lines_read});
        push @checks, "    (called once; loops internally over lines)";
    }

    print "$_\n" for @checks;

    if (@warnings) {
        print "\n";
        for my $w (@warnings) {
            print "  [WARN] $w\n";
        }
        print "  => Investigate: is a function being called from an unexpected code path?\n";
        print "     Check flow counters in verbose.txt for accounting gaps.\n";
    } elsif (@checks) {
        print "\n  [OK] All cross-validation checks within tolerance.\n";
    } else {
        print "  (no checks — pass --checks-file to enable declarative cross-validation)\n";
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
