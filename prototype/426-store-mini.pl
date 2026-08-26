#!/usr/bin/env perl
#
# 426-store-mini.pl — per-message statistics store candidates (#426):
# write-side cost per line, population traversal, comparator-shaped sort,
# memory, and deletion churn, per store representation.
#
# Arms (features/426-per-message-statistics-store.md § Candidate representations):
#   A   baseline: $log_messages{$category}{$log_key}{field}. The production
#       read-loop store block and the calculate_all_statistics traversal
#       blocks, extracted verbatim (call shape, scoping, data movement) with
#       the -mdm bin branches omitted (this mini measures capture mode raw).
#   B   A's store, comparator hoist: the sort metric is extracted once into a
#       flat array and the sort compares array elements; store unchanged.
#   C   A's store, entry aliasing: `my $entry = ... //= {...}` hoisted once
#       per line; every field write goes through $entry. In the non-access
#       branch the production statement has one field access, so C:twx is
#       byte-identical to A:twx (kept as an arm for the layout comparison).
#   D   columnar: per-category message->ordinal hash + one array per hot
#       field, indexed by ordinal; a lazily created per-ordinal "cold" hash
#       carries rare/arbitrary fields (count_*, udm_*, statistics outputs) —
#       the E hybrid policy. On these fixtures no cold field is ever written,
#       so D and E are one arm here. The ordinal->key column the sort
#       tiebreaker needs is built after the read loop with `each`.
#   D2  D with a single hash operation per line (`//=` insert) and the
#       ordinal->key column built with `keys` + hash/array slices.
#   D3  D2 with the ordinal->key column written at insert time (a second
#       copy of every key string; no post-read pass).
#
# One arm and one fixture per process, so every arm builds its store on a
# fresh heap the way a real run does (the first build is the store that is
# traversed and sized; later builds only time the write side).
#
# Usage:
#   perl prototype/426-store-mini.pl --arm A|B|C|D|D2|D3 [--runs N] [--top-n N]
#        [--width W] [--churn F] [--no-header] <fixture>
#
# Family is inferred from the fixture name: twx-unique-* takes the ThingWorx
# application-log path (non-access-log branch), access-* the Tomcat access
# path. TSV on stdout (58-measure.pm shape); PARITY digests on stderr.
# LTL426_DUMP=1 prints the assembled per-line build sub for the arm/family
# and exits, for inspecting exactly what is measured.

use strict;
use warnings;
use FindBin;
use List::Util qw(min max);
use Devel::Size qw(total_size);
use Digest::MD5;
use Time::HiRes qw(gettimeofday tv_interval);
require "$FindBin::Bin/58-measure.pm";

my ($runs, $arm, $top_n_messages, $width, $churn_frac, $no_header) = (5, 'A', 10, 200, 0.9, 0);
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $o = shift @ARGV;
    if    ($o eq '--runs')      { $runs = shift @ARGV }
    elsif ($o eq '--arm')       { $arm = shift @ARGV }
    elsif ($o eq '--top-n')     { $top_n_messages = shift @ARGV }
    elsif ($o eq '--width')     { $width = shift @ARGV }
    elsif ($o eq '--churn')     { $churn_frac = shift @ARGV }
    elsif ($o eq '--no-header') { $no_header = 1 }
    else { die "unknown option $o\n" }
}
die "usage: $0 --arm A|B|C|D|D2|D3 [--runs N] <fixture>\n" unless @ARGV == 1 && $arm =~ /^(?:A|B|C|D|D2|D3)$/;
my $file = shift @ARGV;
(my $fixture = $file) =~ s{.*/}{};
my $family = $fixture =~ /^twx-unique/ ? 'twx' : $fixture =~ /^access/ ? 'access' : die "unknown fixture family: $fixture\n";

## ---------------------------------------------------------------------------
## Production globals the extracted blocks read (values of the measured
## construct: -so p99 / default sort, raw capture, durations demanded).
## ---------------------------------------------------------------------------
our $impact_time_exponent          = 7;
our $omit_durations                = 0;
our $message_duration_stats_demand = 1;
our $message_stats_capture_mode    = 'raw';
our $sort_ascending                = 0;
our $n_floor                       = 1;
our @udm_configs                   = ();
our %udm_values                    = ();
our $max_log_message_length        = $width;
our $write_messages_to_csv         = 0;
our $group_similar_sensitivity     = 'none';

my $re_twx = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;
my $re_acc = qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?/;

## ---------------------------------------------------------------------------
## Build subs are assembled from a per-family parse prelude and a per-arm
## store-write block, then compiled once with string eval — so every arm
## runs the identical per-line allocation churn (captures, substr, the
## per-bucket side hash) around its own store write, and the store block
## itself is the production text.
## ---------------------------------------------------------------------------

my %PARSE = (
    twx => <<'PERL',
        my ($timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message) = $_ =~ $re_twx;
        next unless defined $timestamp_str;
        my ($status_code, $bytes, $duration, $count, $threadname, $threadpool) = (0, undef, undef, undef);
        if( defined $thread && $thread ne "" ) {
            ( $threadpool ) = $thread =~ /(.*)-\d+$/;
            $threadname = defined $threadpool ? $threadpool : $thread;
        }
        $log_occurrences{substr($timestamp_str, 0, 16)}{$category_bucket}{occurrences}++;
        my $category = 'plain';
        my $is_access_log = 0;
PERL
    access => <<'PERL',
        my (undef, $timestamp_str, $message, $status_code, $bytes, $duration, $threadname, $session) = $_ =~ $re_acc;
        next unless defined $timestamp_str;
        my $category_bucket = substr($status_code, 0, 1) . 'xx';
        $bytes = undef if $bytes eq '-';
        $message =~ s{ HTTP/\d\.\d$}{};
        $message =~ s/\?.*//;
        my ($count, $object);
        $log_occurrences{substr($timestamp_str, 0, 17)}{$category_bucket}{occurrences}++;
        my $category = 'plain';
        my $is_access_log = 1;
PERL
);

# Key derivation: read_and_process_logs, verbatim.
my $KEY = <<'PERL';
        my $log_key = "";
        my $max_object_length = 25;
        my $log_level = $status_code > 0 ? $status_code : $category_bucket;
        $log_level =~ s/-HL$//;
        my $truncated_thread = defined($threadname) ? substr($threadname, 0, 20) : undef;
        my $truncated_object = defined($object) ? substr($object, length($object) > $max_object_length ? length($object)-$max_object_length : 0, $max_object_length) : undef;
        if( defined( $threadname ) && defined( $object ) ) {
            $log_key = substr("[$log_level] [$truncated_thread] [$truncated_object] $message", 0, ( ($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length ) );
        } elsif( defined( $object ) ) {
            $log_key = substr("[$log_level] [$truncated_object] $message", 0, ( ($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length ) );
        } elsif( defined( $threadname ) ) {
            $log_key = substr("[$log_level] [$truncated_thread] $message", 0, ( ($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length ) );
        } else {
            $log_key = substr("[$log_level] $message", 0, ( ($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length ) );
        }
PERL

# Store write blocks. A/C: production text (raw-mode branches). D: the candidate.
my %WRITE = (
    'A:twx' => <<'PERL',
        $log_messages{$category}{$log_key}{occurrences}++;
PERL
    'A:access' => <<'PERL',
        $log_messages{$category}{$log_key} //= {
            occurrences    => 0,
            total_bytes    => 0,
            total_duration => 0,
            sum_of_squares => 0,
            durations      => [],
        };

        $log_messages{$category}{$log_key}{occurrences}++;
        $log_messages{$category}{$log_key}{total_bytes} += $bytes if defined $bytes;

        if( defined $count ) {
            $log_messages{$category}{$log_key}{count_sum} += $count if defined $count;
            $log_messages{$category}{$log_key}{count_occurrences}++;
            $log_messages{$category}{$log_key}{count_min} = $count if !defined $log_messages{$category}{$log_key}{count_min} || $count < $log_messages{$category}{$log_key}{count_min};
            $log_messages{$category}{$log_key}{count_max} = $count if !defined $log_messages{$category}{$log_key}{count_max} || $count > $log_messages{$category}{$log_key}{count_max};
        }

        foreach my $config (@udm_configs) {
            my $name = $config->{name};
            next unless defined $udm_values{$name};
            my $value = $udm_values{$name};
            if ($config->{agg_kind} eq 'counting') {
                $log_messages{$category}{$log_key}{"udm_${name}_occurrences"}++;
                next;
            }
            $log_messages{$category}{$log_key}{"udm_${name}_sum"} += $value;
            $log_messages{$category}{$log_key}{"udm_${name}_occurrences"}++;
            $log_messages{$category}{$log_key}{"udm_${name}_min"} = $value if !defined $log_messages{$category}{$log_key}{"udm_${name}_min"} || $value < $log_messages{$category}{$log_key}{"udm_${name}_min"};
            $log_messages{$category}{$log_key}{"udm_${name}_max"} = $value if !defined $log_messages{$category}{$log_key}{"udm_${name}_max"} || $value > $log_messages{$category}{$log_key}{"udm_${name}_max"};
        }

        if( defined $duration && !$omit_durations ) {
            $log_messages{$category}{$log_key}{total_duration} += $duration;
            $log_messages{$category}{$log_key}{total_duration_num} += $duration;

            if( $message_duration_stats_demand ) {
                $log_messages{$category}{$log_key}{sum_of_squares} += $duration ** 2;
                push @{$log_messages{$category}{$log_key}{durations}}, $duration
                    unless $message_stats_capture_mode eq 'bin';
            }

            if( $duration > 0 ) {
                my $mean = $log_messages{$category}{$log_key}{total_duration} / $log_messages{$category}{$log_key}{occurrences};
                $log_messages{$category}{$log_key}{impact} = log( $mean ** $impact_time_exponent * $log_messages{$category}{$log_key}{occurrences} );
            }
        }
PERL
    'C:twx' => <<'PERL',
        $log_messages{$category}{$log_key}{occurrences}++;
PERL
    'C:access' => <<'PERL',
        my $entry = $log_messages{$category}{$log_key} //= {
            occurrences    => 0,
            total_bytes    => 0,
            total_duration => 0,
            sum_of_squares => 0,
            durations      => [],
        };

        $entry->{occurrences}++;
        $entry->{total_bytes} += $bytes if defined $bytes;

        if( defined $count ) {
            $entry->{count_sum} += $count if defined $count;
            $entry->{count_occurrences}++;
            $entry->{count_min} = $count if !defined $entry->{count_min} || $count < $entry->{count_min};
            $entry->{count_max} = $count if !defined $entry->{count_max} || $count > $entry->{count_max};
        }

        foreach my $config (@udm_configs) {
            my $name = $config->{name};
            next unless defined $udm_values{$name};
            my $value = $udm_values{$name};
            if ($config->{agg_kind} eq 'counting') {
                $entry->{"udm_${name}_occurrences"}++;
                next;
            }
            $entry->{"udm_${name}_sum"} += $value;
            $entry->{"udm_${name}_occurrences"}++;
            $entry->{"udm_${name}_min"} = $value if !defined $entry->{"udm_${name}_min"} || $value < $entry->{"udm_${name}_min"};
            $entry->{"udm_${name}_max"} = $value if !defined $entry->{"udm_${name}_max"} || $value > $entry->{"udm_${name}_max"};
        }

        if( defined $duration && !$omit_durations ) {
            $entry->{total_duration} += $duration;
            $entry->{total_duration_num} += $duration;

            if( $message_duration_stats_demand ) {
                $entry->{sum_of_squares} += $duration ** 2;
                push @{$entry->{durations}}, $duration
                    unless $message_stats_capture_mode eq 'bin';
            }

            if( $duration > 0 ) {
                my $mean = $entry->{total_duration} / $entry->{occurrences};
                $entry->{impact} = log( $mean ** $impact_time_exponent * $entry->{occurrences} );
            }
        }
PERL
    'D:twx' => <<'PERL',
        if ($category ne $cur_cat) {
            $st = $store{$category};
            ($ord, $occ) = @$st{qw(ord occ)};
            $cur_cat = $category;
        }
        my $i = $ord->{$log_key};
        if (defined $i) {
            $occ->[$i]++;
        } else {
            $i = $ord->{$log_key} = $st->{n}++;
            $occ->[$i] = 1;
        }
PERL
    'D:access' => <<'PERL',
        if ($category ne $cur_cat) {
            $st = $store{$category};
            ($ord, $occ, $tb, $td, $tdn, $ss, $dur, $imp, $cold) = @$st{qw(ord occ tb td tdn ss dur imp cold)};
            $cur_cat = $category;
        }
        my $i = $ord->{$log_key};
        if (!defined $i) {
            $i = $ord->{$log_key} = $st->{n}++;
            $occ->[$i] = 0;
            $tb->[$i]  = 0;
            $td->[$i]  = 0;
            $ss->[$i]  = 0;
            $dur->[$i] = [];
        }

        $occ->[$i]++;
        $tb->[$i] += $bytes if defined $bytes;

        if( defined $count ) {
            my $c = $cold->[$i] //= {};
            $c->{count_sum} += $count if defined $count;
            $c->{count_occurrences}++;
            $c->{count_min} = $count if !defined $c->{count_min} || $count < $c->{count_min};
            $c->{count_max} = $count if !defined $c->{count_max} || $count > $c->{count_max};
        }

        foreach my $config (@udm_configs) {
            my $name = $config->{name};
            next unless defined $udm_values{$name};
            my $value = $udm_values{$name};
            my $c = $cold->[$i] //= {};
            if ($config->{agg_kind} eq 'counting') {
                $c->{"udm_${name}_occurrences"}++;
                next;
            }
            $c->{"udm_${name}_sum"} += $value;
            $c->{"udm_${name}_occurrences"}++;
            $c->{"udm_${name}_min"} = $value if !defined $c->{"udm_${name}_min"} || $value < $c->{"udm_${name}_min"};
            $c->{"udm_${name}_max"} = $value if !defined $c->{"udm_${name}_max"} || $value > $c->{"udm_${name}_max"};
        }

        if( defined $duration && !$omit_durations ) {
            $td->[$i]  += $duration;
            $tdn->[$i] += $duration;

            if( $message_duration_stats_demand ) {
                $ss->[$i] += $duration ** 2;
                push @{$dur->[$i]}, $duration
                    unless $message_stats_capture_mode eq 'bin';
            }

            if( $duration > 0 ) {
                my $mean = $td->[$i] / $occ->[$i];
                $imp->[$i] = log( $mean ** $impact_time_exponent * $occ->[$i] );
            }
        }
PERL
);
$WRITE{'B:twx'}    = $WRITE{'A:twx'};       # B differs only in the sort
$WRITE{'B:access'} = $WRITE{'A:access'};

# D2: one hash operation per line — `//=` fetches-or-creates the ordinal
# slot in a single hv_fetch; a new key is recognised by receiving the
# next ordinal. $n is the per-category next ordinal, hoisted to a lexical
# and written back on category switch.
$WRITE{'D2:twx'} = <<'PERL';
        if ($category ne $cur_cat) {
            $st->{n} = $n if $st;
            $st = $store{$category};
            ($ord, $occ, $key) = @$st{qw(ord occ key)};
            $n = $st->{n};
            $cur_cat = $category;
        }
        my $i = ($ord->{$log_key} //= $n);
        if ($i == $n) {
            $n++;
            $occ->[$i] = 1;
        } else {
            $occ->[$i]++;
        }
PERL
($WRITE{'D2:access'} = $WRITE{'D:access'}) =~ s{^(\s*)\$st = \$store\{\$category\};$}!$1\$st->{n} = \$n if \$st;\n$1\$st = \$store{\$category};!m
    or die "D2:access rewrite 1a failed";
$WRITE{'D2:access'} =~ s{^(\s*)\(\$ord, \$occ, \$tb, \$td, \$tdn, \$ss, \$dur, \$imp, \$cold\) = \@\$st\{qw\(ord occ tb td tdn ss dur imp cold\)\};$}!$1(\$ord, \$occ, \$tb, \$td, \$tdn, \$ss, \$dur, \$imp, \$cold, \$key) = \@\$st{qw(ord occ tb td tdn ss dur imp cold key)};\n$1\$n = \$st->{n};!m
    or die "D2:access rewrite 1b failed";
$WRITE{'D2:access'} =~ s{^(\s*)my \$i = \$ord->\{\$log_key\};\n\s*if \(!defined \$i\) \{\n(\s*)\$i = \$ord->\{\$log_key\} = \$st->\{n\}\+\+;$}!$1my \$i = (\$ord->{\$log_key} //= \$n);\n$1if (\$i == \$n) {\n$2\$n++;!m
    or die "D2:access rewrite 2 failed";
# D3: D2 plus the key column written at insert time.
($WRITE{'D3:twx'} = $WRITE{'D2:twx'}) =~ s/(\$n\+\+;\n)/$1            \$key->[\$i] = \$log_key;\n/ or die "D3:twx rewrite failed";
($WRITE{'D3:access'} = $WRITE{'D2:access'}) =~ s/(\$n\+\+;\n)/$1            \$key->[\$i] = \$log_key;\n/ or die "D3:access rewrite failed";

my $is_columnar = $arm =~ /^D/;
my $keymap_method = $arm eq 'D' ? 'each' : $arm eq 'D2' ? 'slice' : 'insert';

# Columns a D store allocates for each family — allocated by demand at
# option-resolution time (Q3): the twx path has no bytes/duration producer.
my @D_COLS = $family eq 'twx' ? qw(occ) : qw(occ tb td tdn ss dur imp);

sub new_D_store {
    return { map { $_ => { ord => {}, n => 0, dead => 0, key => [], cold => [], map { $_ => [] } @D_COLS } } qw(plain highlight) };
}

my $PROLOGUE_HASH = <<'PERL';
    my (%log_messages, %log_occurrences);
    my $lines = 0;
    open my $fh, '<', $file or die "open $file: $!";
    while (<$fh>) {
        $lines++;
PERL
my $PROLOGUE_D = <<'PERL';
    my (%log_occurrences);
    my %store = %{ new_D_store() };
    my ($cur_cat, $st, $ord, $occ, $tb, $td, $tdn, $ss, $dur, $imp, $cold, $key, $n) = ('');
    my $lines = 0;
    open my $fh, '<', $file or die "open $file: $!";
    while (<$fh>) {
        $lines++;
PERL
my $EPILOGUE_HASH = <<'PERL';
    }
    close $fh;
    return { lm => \%log_messages, side => \%log_occurrences, lines => $lines };
PERL
my $EPILOGUE_D = <<'PERL';
    }
    close $fh;
    $st->{n} = $n if $st && defined $n;
    return { store => \%store, side => \%log_occurrences, lines => $lines };
PERL

my $build_src = "sub {\n    my (\$file) = \@_;\n"
    . ($is_columnar ? $PROLOGUE_D : $PROLOGUE_HASH)
    . $PARSE{$family} . $KEY . $WRITE{"$arm:$family"}
    . ($is_columnar ? $EPILOGUE_D : $EPILOGUE_HASH) . "}\n";
if ($ENV{LTL426_DUMP}) { print STDERR $build_src; exit 0 }     # inspect the assembled build sub
my $build = eval $build_src or die "build sub failed to compile for $arm:$family: $@\n$build_src";

## ---------------------------------------------------------------------------
## Traversal blocks — calculate_all_statistics, verbatim shapes.
## ---------------------------------------------------------------------------

# Population walk (calculated-statistic sort branch): eligibility split.
# The per-key statistics call for eligible keys is not part of the store
# question and is left out; the split itself is the measured block.
sub walk_hash {
    my ($lm, $category) = @_;
    my (@fill_block, @eligible);
    foreach my $log_key (keys %{$lm->{$category}}) {
        my $entry = $lm->{$category}{$log_key};
        my $n = $message_stats_capture_mode eq 'bin'
            ? ($entry->{duration_count} // 0)
            : scalar @{ $entry->{durations} // [] };
        if (!$message_duration_stats_demand || $n < $n_floor
            || !defined $entry->{occurrences}) {
            push @fill_block, $log_key;
            next;
        }
        push @eligible, $log_key;
    }
    return (\@fill_block, \@eligible);
}

sub walk_D {
    my ($st) = @_;
    my ($occ, $dur) = @$st{qw(occ dur)};
    my (@fill_block, @eligible);
    for my $i (0 .. $#$occ) {
        my $o = $occ->[$i];
        next unless defined $o;                        # tombstone
        my $n = $dur ? scalar @{ $dur->[$i] // [] } : 0;
        if (!$message_duration_stats_demand || $n < $n_floor) {
            push @fill_block, $i;
            next;
        }
        push @eligible, $i;
    }
    return (\@fill_block, \@eligible);
}

# Two-stage selection (available-value branch): stage 1 sorts the whole
# category by the metric alone, the pool is extended through ties at the
# display cut, stage 2 applies the key tiebreaker to the pool.
sub sort_avail_hash {
    my ($lm, $category, $sort_key) = @_;
    my @by_metric = sort {
        my $occurrences_a = $lm->{$category}{$a}{$sort_key} // 0;
        my $occurrences_b = $lm->{$category}{$b}{$sort_key} // 0;
        $sort_ascending
            ? ($occurrences_a <=> $occurrences_b)
            : ($occurrences_b <=> $occurrences_a);
    } keys %{$lm->{$category}};
    my $cut = min($#by_metric, $top_n_messages - 1);
    my $cut_val = $lm->{$category}{$by_metric[$cut]}{$sort_key} // 0;
    my $pool_end = $cut;
    $pool_end++ while $pool_end < $#by_metric
        && (($lm->{$category}{$by_metric[$pool_end + 1]}{$sort_key} // 0) == $cut_val);
    my @pool = @by_metric[0 .. $pool_end];
    my @sorted_log_keys = sort {
        my $occurrences_a = $lm->{$category}{$a}{$sort_key} // 0;
        my $occurrences_b = $lm->{$category}{$b}{$sort_key} // 0;
        ($sort_ascending
            ? ($occurrences_a <=> $occurrences_b)
            : ($occurrences_b <=> $occurrences_a))
        || ($a cmp $b);
    } @pool;
    return [ @sorted_log_keys[0 .. min($#sorted_log_keys, $top_n_messages - 1)] ];
}

# Fill block (calculated-statistic branch): same idiom over @fill_block,
# metric fixed to occurrences.
sub sort_fill_hash {
    my ($lm, $category, $fill_block) = @_;
    return [] unless @$fill_block;                     # production: if ($fill_needed > 0 && @fill_block)
    my @by_occ = sort {
        my $occurrences_a = $lm->{$category}{$a}{occurrences} // 0;
        my $occurrences_b = $lm->{$category}{$b}{occurrences} // 0;
        $sort_ascending
            ? ($occurrences_a <=> $occurrences_b)
            : ($occurrences_b <=> $occurrences_a);
    } @$fill_block;
    my $cut = min($#by_occ, $top_n_messages - 1);
    my $cut_val = $lm->{$category}{$by_occ[$cut]}{occurrences} // 0;
    my $pool_end = $cut;
    $pool_end++ while $pool_end < $#by_occ
        && (($lm->{$category}{$by_occ[$pool_end + 1]}{occurrences} // 0) == $cut_val);
    my @occ_pool = @by_occ[0 .. $pool_end];
    my @fill_sorted = sort {
        my $occurrences_a = $lm->{$category}{$a}{occurrences} // 0;
        my $occurrences_b = $lm->{$category}{$b}{occurrences} // 0;
        ($sort_ascending
            ? ($occurrences_a <=> $occurrences_b)
            : ($occurrences_b <=> $occurrences_a))
        || ($a cmp $b);
    } @occ_pool;
    return [ @fill_sorted[0 .. min($#fill_sorted, $top_n_messages - 1)] ];
}

# Arm B: the same two stages over a flat metric array, keys resolved once.
sub sort_hoisted_hash {
    my ($lm, $category, $sort_key, $keys) = @_;
    my @ks = $keys ? @$keys : keys %{$lm->{$category}};
    return [] unless @ks;
    my $h = $lm->{$category};
    my @v = map { $h->{$_}{$sort_key} // 0 } @ks;
    my @by_metric = sort {
        $sort_ascending ? ($v[$a] <=> $v[$b]) : ($v[$b] <=> $v[$a])
    } 0 .. $#ks;
    my $cut = min($#by_metric, $top_n_messages - 1);
    my $cut_val = $v[$by_metric[$cut]];
    my $pool_end = $cut;
    $pool_end++ while $pool_end < $#by_metric
        && $v[$by_metric[$pool_end + 1]] == $cut_val;
    my @pool = @by_metric[0 .. $pool_end];
    my @sorted = sort {
        ($sort_ascending ? ($v[$a] <=> $v[$b]) : ($v[$b] <=> $v[$a]))
        || ($ks[$a] cmp $ks[$b]);
    } @pool;
    return [ map { $ks[$_] } @sorted[0 .. min($#sorted, $top_n_messages - 1)] ];
}

# Arm D: ordinals sort on the metric column; the tiebreaker reads the
# ordinal->key column.
sub sort_D {
    my ($st, $sort_key, $ids) = @_;
    my ($v, $key, $occ) = ($st->{$sort_key}, $st->{key}, $st->{occ});
    my @ids = $ids ? @$ids
            : $st->{dead} ? (grep { defined $occ->[$_] } 0 .. $#$occ)
            : (0 .. $#$occ);
    return [] unless @ids;
    my @by_metric = sort {
        $sort_ascending ? ($v->[$a] <=> $v->[$b]) : ($v->[$b] <=> $v->[$a])
    } @ids;
    my $cut = min($#by_metric, $top_n_messages - 1);
    my $cut_val = $v->[$by_metric[$cut]];
    my $pool_end = $cut;
    $pool_end++ while $pool_end < $#by_metric
        && $v->[$by_metric[$pool_end + 1]] == $cut_val;
    my @pool = @by_metric[0 .. $pool_end];
    my @sorted = sort {
        ($sort_ascending ? ($v->[$a] <=> $v->[$b]) : ($v->[$b] <=> $v->[$a]))
        || ($key->[$a] cmp $key->[$b]);
    } @pool;
    return [ map { $key->[$_] } @sorted[0 .. min($#sorted, $top_n_messages - 1)] ];
}

# D: ordinal->key column, built after the read loop from the hash's own
# keys (shared-HEK copy-on-write scalars — no second string buffer).
sub keymap_D {
    my ($st, $method) = @_;
    my ($ord, $key) = @$st{qw(ord key)};
    @$key = ();
    if ($method eq 'each') {
        while (my ($k, $i) = each %$ord) { $key->[$i] = $k }
    } else {
        my @ks = keys %$ord;
        @{$key}[ @{$ord}{@ks} ] = @ks;
    }
}

# Locality self-check (the #415 ladder's L0 vs L2 lookup): the comparator-
# shaped keyed loop over the store as built, then over the same entries
# rebuilt into fresh memory.
sub lookup_hash {
    my ($h, $ks) = @_;
    my $s = 0;
    for my $k (@$ks) { $s += $h->{$k}{occurrences} // 0 }
    return $s;
}

## ---------------------------------------------------------------------------
## Deletion churn (Q4): the -g final pass deletes most keys after merging
## each into a cluster, then injects the clusters as new keys.
## ---------------------------------------------------------------------------
sub churn_hash {
    my ($lm, $category, $sorted_keys, $frac) = @_;
    my $n_del = int($frac * @$sorted_keys);
    my $sum = 0;
    for my $k (@$sorted_keys[0 .. $n_del - 1]) {
        my $source = $lm->{$category}{$k};
        $sum += $source->{occurrences};
        delete $lm->{$category}{$k};
    }
    my $n_inj = int(0.01 * @$sorted_keys) || 1;
    for my $j (1 .. $n_inj) {
        $lm->{$category}{"[ERROR] [cluster-thread] [c.t.cluster] canonical pattern $j absorbed ##### keys"} = {
            occurrences     => 100 + $j,
            is_consolidated => 1,
        };
    }
    return $sum;
}

sub churn_D {
    my ($st, $sorted_keys, $frac) = @_;
    my ($ord, $occ) = @$st{qw(ord occ)};
    my @cols = map { $st->{$_} } @D_COLS;
    my $n_del = int($frac * @$sorted_keys);
    my $sum = 0;
    for my $k (@$sorted_keys[0 .. $n_del - 1]) {
        my $i = delete $ord->{$k};
        $sum += $occ->[$i];
        $_->[$i] = undef for @cols;                    # tombstone every column
        $st->{cold}[$i] = undef;
        $st->{key}[$i]  = undef;
        $st->{dead}++;
    }
    my $n_inj = int(0.01 * @$sorted_keys) || 1;
    for my $j (1 .. $n_inj) {
        my $k = "[ERROR] [cluster-thread] [c.t.cluster] canonical pattern $j absorbed ##### keys";
        my $i = $ord->{$k} = $st->{n}++;
        $occ->[$i] = 100 + $j;
        $st->{cold}[$i] = { is_consolidated => 1 };
        $st->{key}[$i] = $k;
    }
    return $sum;
}

# D: compaction after churn — drop tombstoned ordinals, renumber in place.
sub compact_D {
    my ($st) = @_;
    my $occ = $st->{occ};
    my @live = grep { defined $occ->[$_] } 0 .. $#$occ;
    my @map; $map[$live[$_]] = $_ for 0 .. $#live;
    for my $c (@D_COLS, 'key', 'cold') {
        my $a = $st->{$c};
        @$a = @{$a}[@live];
    }
    my $ord = $st->{ord};
    while (my ($k, $i) = each %$ord) { $ord->{$k} = $map[$i] }
    $st->{n} = scalar @live;
    $st->{dead} = 0;
}

## ---------------------------------------------------------------------------
## Parity rows: one canonical line per key, identical across arms.
## ---------------------------------------------------------------------------
sub digest_rows_hash {
    my ($lm) = @_;
    my $ctx = Digest::MD5->new;
    my $n = 0;
    for my $cat (sort keys %$lm) {
        for my $k (sort keys %{$lm->{$cat}}) {
            my $e = $lm->{$cat}{$k};
            $ctx->add(join("\t", $cat, $k, map { defined $_ ? $_ : '' }
                $e->{occurrences}, $e->{total_bytes}, $e->{total_duration}, $e->{total_duration_num},
                $e->{sum_of_squares}, scalar @{ $e->{durations} // [] }, $e->{impact}), "\n");
            $n++;
        }
    }
    return ($ctx->hexdigest, $n);
}

sub digest_rows_D {
    my ($store) = @_;
    my $ctx = Digest::MD5->new;
    my $n = 0;
    for my $cat (sort keys %$store) {
        my $st = $store->{$cat};
        my ($ord, $occ) = @$st{qw(ord occ)};
        for my $k (sort keys %$ord) {
            my $i = $ord->{$k};
            $ctx->add(join("\t", $cat, $k, map { defined $_ ? $_ : '' }
                $occ->[$i], ($st->{tb} ? $st->{tb}[$i] : undef), ($st->{td} ? $st->{td}[$i] : undef),
                ($st->{tdn} ? $st->{tdn}[$i] : undef), ($st->{ss} ? $st->{ss}[$i] : undef),
                ($st->{dur} ? scalar @{ $st->{dur}[$i] // [] } : 0), ($st->{imp} ? $st->{imp}[$i] : undef)), "\n");
            $n++;
        }
    }
    return ($ctx->hexdigest, $n);
}

sub digest_list { Digest::MD5::md5_hex(join("\n", @{ $_[0] })) }

## ---------------------------------------------------------------------------
## Run.
## ---------------------------------------------------------------------------
Measure58::tsv_header(\*STDOUT) unless $no_header;
my $cand = "arm-$arm";
my $emit = sub {
    my ($metric, @secs) = @_;
    my ($med, $min, $max) = Measure58::median_min_max(@secs);
    Measure58::emit_tsv(\*STDOUT, $cand, $fixture, $LINES::n // 0, $metric, $med, $min, $max);
};

# Build: the first store (fresh heap) is kept; later builds time the write
# side only.
my $rss0 = Measure58::rss_kb();
my @build_secs;
my $t0 = [gettimeofday];
my $S = $build->($file);
push @build_secs, tv_interval($t0);
$LINES::n = $S->{lines};
my $rss_after_build = Measure58::rss_kb();
for (2 .. $runs) {
    my $t = [gettimeofday];
    my $tmp = $build->($file);
    push @build_secs, tv_interval($t);
    undef $tmp;
}
$emit->('build_ns_per_line', map { $_ / $S->{lines} * 1e9 } @build_secs);
$emit->('rss_delta_after_build_kb', ($rss_after_build - $rss0) x 3);

my $category = 'plain';
my ($lm, $st) = ($S->{lm}, $S->{store} ? $S->{store}{$category} : undef);
my $distinct = $is_columnar ? scalar keys %{$st->{ord}} : scalar keys %{$lm->{$category}};
$emit->('distinct_keys', ($distinct) x 3);

# Memory of the store as built.
my $store_ref = $is_columnar ? $S->{store} : $lm;
if ($is_columnar) {
    if ($keymap_method eq 'insert') {
        $emit->('keymap_s', (0) x 3);                   # written in the read loop; cost is in build_ns_per_line
    } else {
        my @km = Measure58::time_runs($runs, sub { keymap_D($st, $keymap_method) });
        $emit->('keymap_s', @km);
    }
    $emit->('devel_size_keymap_bytes', (total_size($st->{key})) x 3);
}
$emit->('devel_size_bytes', (total_size($store_ref)) x 3);

# Locality self-check on hash arms.
if (!$is_columnar) {
    my $h = $lm->{$category};
    my @ks = keys %$h;
    my @l0 = Measure58::time_runs($runs, sub { lookup_hash($h, \@ks) });
    $emit->('lookup_asbuilt_s', @l0);
    my %f2 = map { $_ => { %{ $h->{$_} } } } @ks;
    my @l2 = Measure58::time_runs($runs, sub { lookup_hash(\%f2, \@ks) });
    $emit->('lookup_rebuilt_s', @l2);
    undef %f2;
}

# Traversal.
my ($fill_block, $eligible);
my $walk = $is_columnar ? sub { ($fill_block, $eligible) = walk_D($st) }
                        : sub { ($fill_block, $eligible) = walk_hash($lm, $category) };
$emit->('walk_s', Measure58::time_runs($runs, $walk));
$walk->();
$emit->('walk_fill_count', (scalar @$fill_block) x 3);

my ($top_avail, $top_fill);
my $sort_avail = $arm eq 'B' ? sub { $top_avail = sort_hoisted_hash($lm, $category, 'occurrences') }
               : $is_columnar ? sub { $top_avail = sort_D($st, 'occ') }
               :                sub { $top_avail = sort_avail_hash($lm, $category, 'occurrences') };
my $sort_fill  = $arm eq 'B' ? sub { $top_fill = sort_hoisted_hash($lm, $category, 'occurrences', $fill_block) }
               : $is_columnar ? sub { $top_fill = sort_D($st, 'occ', $fill_block) }
               :                sub { $top_fill = sort_fill_hash($lm, $category, $fill_block) };
$emit->('sort_avail_s', Measure58::time_runs($runs, $sort_avail));
$emit->('sort_fill_s',  Measure58::time_runs($runs, $sort_fill));
$sort_avail->(); $sort_fill->();

my ($store_digest, $rows) = $is_columnar ? digest_rows_D($S->{store}) : digest_rows_hash($lm);
printf STDERR "PARITY\t%s\t%s\tstore=%s rows=%d avail=%s fill=%s\n",
    $fixture, $cand, $store_digest, $rows, digest_list($top_avail), digest_list($top_fill);

# Deletion churn, destructive — last.
my @sorted_keys = $is_columnar ? sort keys %{$st->{ord}} : sort keys %{$lm->{$category}};
my $rss_before_churn = Measure58::rss_kb();
my $t_churn = [gettimeofday];
my $absorbed = $is_columnar ? churn_D($st, \@sorted_keys, $churn_frac)
                            : churn_hash($lm, $category, \@sorted_keys, $churn_frac);
$emit->('churn_s', (tv_interval($t_churn)) x 3);
$emit->('churn_rss_delta_kb', (Measure58::rss_kb() - $rss_before_churn) x 3);
$emit->('churn_devel_size_bytes', (total_size($store_ref)) x 3);
$emit->('churn_walk_s', Measure58::time_runs($runs, $walk));
$walk->();
$emit->('churn_sort_fill_s', Measure58::time_runs($runs, $sort_fill));
$sort_fill->();
my $churn_digest = $is_columnar ? (digest_rows_D($S->{store}))[0] : (digest_rows_hash($lm))[0];
printf STDERR "PARITY\t%s\t%s\tchurn=%s absorbed=%d churn_fill=%s\n", $fixture, $cand, $churn_digest, $absorbed, digest_list($top_fill);

if ($is_columnar) {
    my $t_c = [gettimeofday];
    compact_D($st);
    $emit->('compact_s', (tv_interval($t_c)) x 3);
    $emit->('compact_devel_size_bytes', (total_size($store_ref)) x 3);
    $emit->('compact_walk_s', Measure58::time_runs($runs, $walk));
    $walk->();
    $emit->('compact_sort_fill_s', Measure58::time_runs($runs, $sort_fill));
    $sort_fill->();
    my $cd = (digest_rows_D($S->{store}))[0];
    printf STDERR "PARITY\t%s\t%s\tcompact=%s compact_fill=%s\n", $fixture, $cand, $cd, digest_list($top_fill);
}
