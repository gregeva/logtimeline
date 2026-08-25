#!/usr/bin/env perl
#
# 58-baseline-extractor.pl — today's inline cascade as the #58 prototype baseline.
#
# A faithful copy of the recognition/extraction region of ltl's
# read_and_process_logs() per-line loop: scalar initialization, the
# 13-branch match-type cascade, lazy CSV detection, the count-metric
# probe, threadpool derivation, the UDM capture block, format-detection
# tracking, and the bytes/duration guards. It stops where timestamp
# parsing begins (that is a separate prototype axis) and excludes the
# log-level filter and all downstream statistics.
#
# Fidelity notes:
#   - Flag-guarded blocks that are inert in the measured configuration
#     (progress, memory debug, CSV/UDM with no -udm configs) keep their
#     per-line guard tests so the baseline pays the same guard costs.
#   - Every candidate prototype must accumulate the same counters this
#     baseline does (per-match-type counts, metric sums) so outputs are
#     comparable for parity and nothing is optimized away.
#
# Usage:
#   perl prototype/58-baseline-extractor.pl [--runs N] <fixture> [...]
#
# TSV measurements on stdout (see 58-measure.pm); per-fixture match
# distribution on stderr.

use strict;
use warnings;
use FindBin;
require "$FindBin::Bin/58-measure.pm";

my $runs = 5;
if (@ARGV >= 2 && $ARGV[0] eq '--runs') { shift @ARGV; $runs = shift @ARGV; }
die "usage: $0 [--runs N] <fixture> [...]\n" unless @ARGV;

## Configuration state mirrored from ltl's GLOBALS (measured configuration:
## no -udm, no -du, count capture on, query strings/sessions excluded,
## progress disabled).
my @udm_configs             = ();
my %udm_last_value          = ();
my $omit_count              = 0;
my $include_query_string    = 0;
my $include_session         = 0;
my $disable_progress        = 1;
my $show_memory_debug       = 0;
my $duration_unit_override  = undef;
my $csv_separator           = ',';
my $csv_timestamp_col       = 0;
my $total_lines_read        = 0;
my %format_detection;

my %match_type_to_slug = (
    1  => 'thingworx_standard',
    2  => 'thingworx_rac_client',
    3  => 'tomcat_access_with_duration',
    4  => 'tomcat_access_common',
    5  => 'connection_server_json',
    6  => 'java_gc_log',
    7  => 'tw_analytics_v2',
    8  => 'tw_analytics_worker',
    9  => 'jboss_access',
    10 => 'connection_server_standard',
    11 => 'tw_edge_c_sdk',
    12 => 'tomcat_codebeamer',
    13 => 'csv',
);

sub convert_bytes {
    my ($input_value, $input_unit) = @_;
    my ($value, $unit);

    if( defined( $input_unit ) ) {
        $value = $input_value;
        $unit = $input_unit;
    } else {
        ( $value, $unit ) = $input_value =~ /^(\d+)[ ]?(\w+)$/;
    }

    my %units = (
        'B'  => 1,
        'b'  => 1,
        'kB' => 1000,
        'k'  => 1000,
        'MB' => 1000**2,
        'M'  => 1000**2,
        'GB' => 1000**3,
        'G'  => 1000**3,
        'TB' => 1000**4,
        'T'  => 1000**4,
        'KB'  => 1024,
        'K'   => 1024,
        'KiB' => 1024,
        'MiB' => 1024**2,
        'GiB' => 1024**3,
        'TiB' => 1024**4,
    );

    my $bytes = $value * $units{$unit};

    return $bytes;
}

## parse_file — the measured unit: one full recognition pass over a file.
## Returns the accumulator hashref every candidate must reproduce.
sub parse_file {
    my ($in_file) = @_;
    my %acc = (
        lines => 0, matched => 0, unmatched => 0,
        by_mt => {},
        duration_sum => 0, bytes_sum => 0, count_sum => 0,
    );
    %format_detection = ();

    open my $fh, '<', $in_file or die "Cannot open file: $in_file";
    my $line_number = 0;
    my $csv_detected = 0;
    my %csv_col_index = ();
    my @csv_udm_col_indices = ();
    my @csv_message_col_indices = ();
    my $potential_csv_header;

    while (<$fh>) {
        s/[\r\n]+$//;
        $line_number++;
        my ( $timestamp_str, $log_level, $category_bucket, $category, $object, $instance, $user, $platform, $thread, $threadpool, $session, $message ) = ("") x 12;
        my ( $is_line_match, $is_access_log, $match_type, $status_code, $heap_from, $heap_to, $heap_size ) = ( 0, 0, 0, 0, 0, 0, 0 );
        my ( $bytes, $duration, $occurrences, $count ) = ( undef, undef, undef, undef );
        my ( $timestamp, $threadname );
        my @csv_fields;
        $total_lines_read++;

        if ($total_lines_read % 4999 == 0 && !$disable_progress) {
            ;   # progress emission elided; guard cost retained
        }

        ## CSV data line (only after CSV confirmed via two-line validation) ##
        if ($csv_detected) {
            @csv_fields = split(/\Q$csv_separator\E/, $_, -1);
            $timestamp_str = $csv_fields[$csv_timestamp_col];
            $timestamp_str =~ s/^\s+|\s+$//g if defined $timestamp_str;

            if (@csv_message_col_indices) {
                $message = join(' ', map { ($_ < @csv_fields ? $csv_fields[$_] : '') =~ s/^\s+|\s+$//gr } @csv_message_col_indices);
            } else {
                $message = "CSV data";
            }

            $category_bucket = "DATA";
            $is_line_match = 1;
            $is_access_log = 1;
            $match_type = 13;

        ## ThingWorx Standard Log Format (ApplicationLog, ErrorLog, ScriptLog, ...) ##
        } elsif ( ($timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message ) = $_ =~ /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/) {
            $is_line_match = 1;
            $match_type = 1;

            ( $bytes ) = $message =~ / bytes\s*=\s*(\d+)/;
            ( $duration ) = $message =~ / durationM[sS]\s*=\s*(\d+)/;
            if (defined $bytes || defined $duration) {
                $is_access_log = 1;
                $message =~ s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g;
            }

        ## ThingWorx Connection Server Standard Log Format ##
        } elsif ( ($timestamp_str, $thread, $category_bucket, $object, $message ) = $_ =~ /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) \[([^\]]*)\] ([^ ]*)\s+([^ ]*) - (.*)/) {
            $is_line_match = 1;
            $match_type = 10;

            ( $duration ) = $message =~ / (\d+) milliseconds/;
            $message =~ s/ (\d+) milliseconds/ ? millseconds/g;

            $message =~ s/(from \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:)\d{4,5} /${1}XXXXX /;
            $is_access_log = 1 if defined $bytes || defined $duration;

        ## Generic Java/Logback Pattern with timestamp and level ##
        } elsif ( ($timestamp_str, $category_bucket) = $_ =~ /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\+\d{4} \[L: ([^\]]*)\]/) {
            $is_line_match = 1;
            $match_type = 1;

        ## ThingWorx Remote Access Client Log Format ##
        } elsif ( ($timestamp_str, $category_bucket ) = $_ =~ /^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3}).*? \[[L: ]*([^\]]*)\]/ ) {
            $is_line_match = 1;
            $match_type = 2;
            $timestamp_str =~ tr/T/ /;

        ## Apache Tomcat Access Log with CodeBeamer format ([%Dms] [%Ts]) ##
        # The ([^ ]+ ){3} host/ident/authuser prefix in the access-log family
        # must remain backtracking-free (see ltl).
        } elsif ( (undef, $timestamp_str, $message, $category_bucket, $bytes, $duration, undef) = $_ =~ /^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?\[([0-9.]+)ms\] \[(.+)s\]/ ) {
            $is_line_match = 1;
            $match_type = 12;

            $is_access_log = 1;
            $status_code = $category_bucket;
            $category_bucket =~ s/(\d)\d{2}/$1xx/;
            $timestamp_str =~ s/ \+\d{4}$//;
            undef $bytes if $bytes eq "-";

            $message =~ s/ HTTP\/\d\.\d$//;
            $message =~ s/\?.+$// unless $include_query_string;
            $message = "[$session] $message" if defined $session && $include_session;

        ## Apache Tomcat Standard/Common Access Log Format (no duration field) ##
        } elsif ( (undef, $timestamp_str, $message, $category_bucket, $bytes) = $_ =~ /^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)$/ ) {
            $is_line_match = 1;
            $match_type = 4;
            $is_access_log = 1;
            $status_code = $category_bucket;
            $category_bucket =~ s/(\d)\d{2}/$1xx/;
            $timestamp_str =~ s/ \+\d{4}$//;
            undef $bytes if $bytes eq "-";

            $message =~ s/ HTTP\/\d\.\d$//;
            $message =~ s/\?.+$// unless $include_query_string;

        ## JBoss/Jersey Enhanced Access Log Format ##
        } elsif ( (undef, $timestamp_str, $message, $category_bucket, $bytes, undef, undef, $duration) = $_ =~ /^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+) "([^"]+)" "([^"]+)" (\d+)$/ ) {
            $is_line_match = 1;
            $match_type = 9;
            $is_access_log = 1;
            $status_code = $category_bucket;
            $category_bucket =~ s/(\d)\d{2}/$1xx/;
            $timestamp_str =~ s/ \+\d{4}$//;

            $message =~ s/ HTTP\/\d\.\d$//;
            $message =~ s/\?.+$// unless $include_query_string;

        ## Apache Tomcat Access Log with Service Execution Time (%D) ##
        } elsif ( (undef, $timestamp_str, $message, $category_bucket, $bytes, $duration, $thread, $session) = $_ =~ /^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?/ ) {
            $is_line_match = 1;
            $match_type = 3;
            $is_access_log = 1;
            $status_code = $category_bucket;
            $category_bucket =~ s/(\d)\d{2}/$1xx/;
            $timestamp_str =~ s/ \+\d{4}$//;
            undef $bytes if $bytes eq "-";

            $message =~ s/ HTTP\/\d\.\d$//;
            $message =~ s/\?.+$// unless $include_query_string;
            $message = "[$session] $message" if defined $session && $include_session;

        ## ThingWorx Connection Server JSON Formatted Logs ##
        } elsif ( ($timestamp_str, $category_bucket) = $_ =~ /^{"\@timestamp":"([^"]*).*"level":"([^"]*)/ ) {
            $is_line_match = 1;
            $match_type = 5;
            $timestamp_str =~ s/\+\d{2}:\d{2}$//;
            $timestamp_str =~ tr/T/ /;

        ## Java 11 GC Log Format with Timestamps Enabled ##
        } elsif ( ( $timestamp_str, $category_bucket, $message, $heap_from, $heap_to, $heap_size, $duration ) = $_ =~ /^[\[]?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{3})[+-]\d{4}.*?\[info\]\[gc\s*\] GC\(\d+\) (.+?) (\(.+?\)) (\d[^-]+)->(\d[^(]+)\((\d[^)]+)\) (\d.*)ms/ ) {
            $is_line_match = 1;
            $match_type = 6;
            $is_access_log = 1;

            $bytes = convert_bytes( $heap_from ) - convert_bytes( $heap_to );
            $bytes = $bytes < 0 ? 0 : $bytes;

        ## ThingWorx Analytics Log Formats (adaptor, sync, async) ##
        } elsif ( ( $category_bucket, $timestamp_str, $message ) = $_ =~ /^([^ ]+)\s+\[(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[.,]\d{3})\] (.*)$/ ) {
            $is_line_match = 1;
            $match_type = 7;
            $timestamp_str =~ tr/,/./;
            $timestamp_str =~ tr/T/ /;
            $message =~ s/\s+$//g;

        ## ThingWorx Analytics worker type ##
        } elsif ( ( $timestamp_str, $thread, $category_bucket, $message ) = $_ =~ /^(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[^ ]*)\s+\[([^]]+)\]\s+(\w+)\s+(.*)$/ ) {
            $is_line_match = 1;
            $match_type = 8;
            $timestamp_str =~ tr/,/./;
            $timestamp_str =~ tr/T/ /;
            $message =~ s/\s+$//g;

        ## ThingWorx Edge C SDK format ##
        } elsif ( ( $category_bucket, $timestamp_str, $message ) = $_ =~ /^([^ ]+) (\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}[,.]\d+) (.*)/ ) {
            $is_line_match = 1;
            $match_type = 11;
            chop $message;

            $message =~ s/\d+ (.*)$/$1/;
            if( $message =~ /\w+\.cpp:\d+ / ) {
                $message =~ s/(\w+\.cpp:\d+) (.*)$/$2/;
                $object = $1;
            }

        }

        ## LAZY CSV DETECTION (inert here: no -udm configs; guard cost retained) ##
        if (@udm_configs && !$csv_detected) {
            if ($is_line_match) {
                $potential_csv_header = undef;
            } elsif ($line_number == 1) {
                $potential_csv_header = $_;
                next;
            }
        }

        ## COUNT METRICS ##
        if( !$omit_count && defined $message ) {
            ( $count ) = $message =~ / count\s*=\s*(\d+)/;
            if( defined $count ) {
                $message =~ s/ count\s*=\s*\d+/ count=?/g;
                $is_access_log = 1;
            }
        }

        ## THREAD POOL ##
        if( defined $thread && $thread ne "" ) {
            ( $threadpool ) = $thread =~ /(.*)-\d+$/;
            $threadname = defined $threadpool ? $threadpool : $thread;
        }

        ## USER DEFINED METRICS CAPTURE (inert here; guard cost retained) ##
        my %udm_values;
        if (@udm_configs && defined $message) {
            ;
        }
        $is_access_log = 1 if %udm_values;

        if( $is_line_match ) {
            my $fdd = $format_detection{$in_file} //= {
                match_type       => undef,
                slug             => undef,
                is_access_log    => 0,
                matched_lines    => 0,
                unmatched_lines  => 0,
                first_match_line => undef,
            };
            if (!defined $fdd->{match_type}) {
                $fdd->{match_type}       = $match_type;
                $fdd->{slug}             = $match_type_to_slug{$match_type} // 'unknown';
                $fdd->{first_match_line} = $line_number;
            }
            $fdd->{matched_lines}++;
            $fdd->{is_access_log} = 1 if $is_access_log;

            $bytes = 0 if( defined( $bytes ) && $bytes < 0 );

            $duration = undef if defined $duration && $duration !~ /^[0-9]+(?:\.[0-9]+)?$/;

            if (defined $duration && defined $duration_unit_override) {
                ;   # convert_duration_to_ms elided: no -du in measured configuration
            }

            ## Accumulators: parity surface + dead-code defeat (every candidate
            ## prototype must produce these same values).
            $acc{matched}++;
            $acc{by_mt}{$match_type}++;
            $acc{duration_sum} += $duration if defined $duration;
            $acc{bytes_sum}    += $bytes    if defined $bytes;
            $acc{count_sum}    += $count    if defined $count;
        } else {
            $acc{unmatched}++;
            if (my $fdd = $format_detection{$in_file}) {
                $fdd->{unmatched_lines}++;
            }
        }
    }
    close $fh;
    $acc{lines} = $line_number;
    return \%acc;
}

## Driver ##
Measure58::tsv_header(\*STDOUT);

foreach my $file (@ARGV) {
    (my $fixture = $file) =~ s{.*/}{};

    my $rss_before = Measure58::rss_kb();
    my $acc;
    my @secs = Measure58::time_runs($runs, sub { $acc = parse_file($file) });
    my $rss_after = Measure58::rss_kb();

    my ($med, $min, $max) = Measure58::median_min_max(@secs);
    my $lines = $acc->{lines};

    Measure58::emit_tsv(\*STDOUT, 'baseline-inline-cascade', $fixture, $lines, 'wall_s',      $med, $min, $max);
    Measure58::emit_tsv(\*STDOUT, 'baseline-inline-cascade', $fixture, $lines, 'ns_per_line', map { $_ / $lines * 1e9 } $med, $min, $max);
    Measure58::emit_tsv(\*STDOUT, 'baseline-inline-cascade', $fixture, $lines, 'rss_delta_kb', ($rss_after - $rss_before) x 3);

    my $dist = join(' ', map { sprintf('%s=%d', $match_type_to_slug{$_} // $_, $acc->{by_mt}{$_}) }
                         sort { $a <=> $b } keys %{$acc->{by_mt}});
    printf STDERR "%s: lines=%d matched=%d unmatched=%d [%s] dur_sum=%s bytes_sum=%s count_sum=%s\n",
        $fixture, $lines, $acc->{matched}, $acc->{unmatched}, $dist,
        $acc->{duration_sum}, $acc->{bytes_sum}, $acc->{count_sum};
}
