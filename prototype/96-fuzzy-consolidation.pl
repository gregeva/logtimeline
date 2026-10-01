#!/usr/bin/env perl
# ============================================================================
# Prototype for #96 — Fuzzy Message Consolidation
#
# A driver for experimenting with message grouping outside ltl's full
# pipeline. The consolidation engine is not a copy: every sub, constant and
# variable before ltl's "## MAIN ##" marker is compiled from ltl's own source
# at start-up, so the prototype groups exactly as ltl -g does and follows
# features/fuzzy-message-consolidation.md (the master specification) by
# construction. The prototype supplies only what ltl's main code does around
# the engine: reading lines, building message keys, the read loop's
# consolidation step, the end-of-file checkpoints and the final pass.
#
# Formats read, with their line patterns taken from ltl's format registry
# (entry name, then format name):
#   mt1std  thingworx_standard                     ThingWorx application logs
#   mt3ts   access_common_duration_thread_session  Tomcat access logs with thread and session
#   mt3     access_common_duration                 Tomcat access logs
#
# Usage:
#   prototype/96-fuzzy-consolidation.pl --file <log> [--file <log> ...]
#       [--sensitivity N] [--group-ceiling N] [--no-final-pass]
#       [--top N] [--membership] [--ltl <path to ltl>]
# ============================================================================
use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(dirname);
use File::Spec;

my @files;
my $sensitivity;                 # unset: ltl's own default ($consolidation_threshold)
my $group_ceiling;               # unset: ltl's own default ($consolidation_final_ceiling)
my $final_pass    = 1;
my $top_n         = 20;
my $membership    = 0;
my $ltl_path      = File::Spec->catfile(dirname(File::Spec->rel2abs($0)), '..', 'ltl');

GetOptions(
    'file=s@'         => \@files,
    'sensitivity=i'   => \$sensitivity,
    'group-ceiling=i' => \$group_ceiling,
    'final-pass!'     => \$final_pass,
    'top=i'           => \$top_n,
    'membership'      => \$membership,
    'ltl=s'           => \$ltl_path,
) or die "Usage: $0 --file <log> [--file <log> ...] [--sensitivity N] [--group-ceiling N] [--no-final-pass] [--top N] [--membership] [--ltl <path>]\n";

@files = map { my @m = glob($_); @m ? @m : die "Error: no files match '$_'\n" } @files;
die "Error: --file is required\n" unless @files;
-f $_ or die "Error: file '$_' not found\n" for @files;

# --- The engine: ltl's own source, everything before its main code ---------
open my $ltl_fh, '<', $ltl_path or die "Cannot read ltl at $ltl_path: $!\n";
my @ltl_lines = <$ltl_fh>;
close $ltl_fh;
my ($globals_at) = grep { $ltl_lines[$_] =~ /^## GLOBALS ##/ } 0 .. $#ltl_lines;
my ($main_at)    = grep { $ltl_lines[$_] =~ /^## MAIN ##/ }    0 .. $#ltl_lines;
die "Cannot find the GLOBALS and MAIN markers in $ltl_path\n" unless defined $globals_at && defined $main_at;
my $ltl_imports = join '', grep { /^\s*(use|no) / } @ltl_lines[0 .. $globals_at - 1];

my $driver = <<'DRIVER';

# --- Driver: the steps ltl's main code takes around the engine -------------
# Compiled in the same scope as ltl's globals, so it reads and writes them.

my @proto_formats;
my $proto_lines_read    = 0;
my $proto_lines_matched = 0;

sub proto_configure {
    my (%o) = @_;
    $consolidation_threshold         = $o{sensitivity} if defined $o{sensitivity};
    $group_similar_sensitivity       = $consolidation_threshold;
    $consolidation_final_ceiling     = $o{group_ceiling} if defined $o{group_ceiling};
    $consolidation_final_pass        = $o{final_pass};
    $consolidation_membership_wanted = 1;
    $max_log_message_length          = MESSAGE_KEY_CAP;   # the per-run cut under -g
    $message_stats_capture_mode      = 'raw';
    $disable_progress                = 1;
    my %spec = map { $_->{name} => $_ } format_registry_specs();
    for my $name (qw(mt1std mt3ts mt3)) {
        my $s = $spec{$name} or die "ltl has no format entry '$name'\n";
        my $slug = $s->{slug};
        my %field_at = map { $_->[1] => $_->[0] } @{ $s->{field_map} };
        my $mask;
        if (my $mm = $s->{message_metrics}) {
            my $keys = join '|', map { $_->{mask_key} } @{ $mm->{probes} };
            (my $pattern = $mm->{mask}{pattern}) =~ s/KEYS/$keys/;
            $mask = { gate => $mm->{gate_lit}, re => qr/$pattern/, probes => [ map { [ $_->{field}, qr/$_->{pattern}/ ] } @{ $mm->{probes} } ] };
        }
        # The entry's message transforms, compiled from ltl's own transform table
        # (%format_transform_code); query strings are not exposed, so
        # strip_query_string applies as it does in ltl by default.
        my @message_transforms = map { my $code = $format_transform_code{$_}; eval "sub { my \$message = shift; $code return \$message }" or die $@ }
                                 grep { /^(chop_http_proto|strip_query_string)$/ } @{ $s->{transforms} };
        push @proto_formats, { slug => $slug, re => qr/$s->{pattern_src}/, field_at => \%field_at,
                               message_transforms => \@message_transforms, mask => $mask };
    }
}

# One line: the fields ltl's format and transforms would give, then the key.
sub proto_read_line {
    my ($line) = @_;
    $proto_lines_read++;
    for my $f (@proto_formats) {
        my @c = $line =~ $f->{re} or next;
        my %v = map { $_ => $c[ $f->{field_at}{$_} - 1 ] } keys %{ $f->{field_at} };
        my ($level, $message, $thread, $object, $duration) = ($v{category_bucket}, $v{message}, $v{thread}, $v{object}, $v{duration});
        $message = $_->($message) for @{ $f->{message_transforms} };
        if (my $m = $f->{mask}) {
            if (index($message, $m->{gate}) >= 0) {
                for my $p (@{ $m->{probes} }) {
                    my ($n) = $message =~ $p->[1];
                    $duration = $n if $p->[0] eq 'duration' && defined $n;
                }
                $message =~ s/$m->{re}/ $1?/g;
            }
        }
        # Restated from read_and_process_logs (## COUNT METRICS and ## THREAD POOL):
        # read-loop code, not a sub, so it cannot be compiled from ltl's source.
        $message =~ s/ count\s*=\s*\d+/ count=?/g;
        my $threadname;
        if (defined $thread && $thread ne '' && $thread ne '-') {
            my ($pool) = $thread =~ /(.*)-\d+$/;
            $threadname = defined $pool ? $pool : $thread;
        }
        $proto_lines_matched++;
        proto_add_key('plain', $level, $message, $threadname, $object, $duration);
        return;
    }
}

# The read loop's message-key and consolidation step, restated from
# read_and_process_logs (the key construction, ## CONSOLIDATION: S1 INLINE MATCH
# and the message-store entry), which is read-loop code, not a sub.
sub proto_add_key {
    my ($category, $log_level, $message, $threadname, $object, $duration) = @_;
    my $truncated_thread = defined($threadname) ? substr($threadname, 0, MESSAGE_KEY_THREAD_LENGTH) : undef;
    my $truncated_object = defined($object) ? substr($object, length($object) > MESSAGE_KEY_OBJECT_LENGTH ? length($object)-MESSAGE_KEY_OBJECT_LENGTH : 0, MESSAGE_KEY_OBJECT_LENGTH) : undef;
    my $log_key;
    if    (defined $threadname && defined $object) { $log_key = substr("[$log_level] [$truncated_thread] [$truncated_object] $message", 0, $max_log_message_length) }
    elsif (defined $object)                        { $log_key = substr("[$log_level] [$truncated_object] $message", 0, $max_log_message_length) }
    elsif (defined $threadname)                    { $log_key = substr("[$log_level] [$truncated_thread] $message", 0, $max_log_message_length) }
    else                                           { $log_key = substr("[$log_level] $message", 0, $max_log_message_length) }

    my $grouping_key = $log_level // "";
    my $is_new_key = !exists $log_messages{$category}{$log_key};
    if ($is_new_key) {
        my $stats_source = { occurrences => 1 };
        if (defined $duration) {
            $stats_source->{total_duration} = $duration;
            $stats_source->{sum_of_squares} = $duration ** 2;
            $stats_source->{durations}      = [ 0 + $duration ];
            $stats_source->{duration_count} = 1;
        }
        return if consolidation_process_key($log_key, $category, "$category|$grouping_key", $log_key, $stats_source);
    }
    my $e = $log_messages{$category}{$log_key} //= { occurrences => 0, total_duration => 0, sum_of_squares => 0, durations => [] };
    $e->{occurrences}++;
    if (defined $duration) {
        $e->{total_duration} += $duration;
        $e->{sum_of_squares} += $duration ** 2;
        push @{ $e->{durations} }, 0 + $duration;
        $e->{duration_count}++;
    }
    $e->{grouping_key} = $grouping_key if $is_new_key;
}

# End of input, restated from read_and_process_logs (the EOF checkpoints) and
# pipeline_finalize (the final pass).
sub proto_finish {
    for my $cat_gk (sort keys %consolidation_unmatched) {
        next unless scalar(keys %{ $consolidation_unmatched{$cat_gk} }) >= 2;
        my ($cat, $gk) = split(/\|/, $cat_gk, 2);
        run_consolidation_checkpoint($cat, $gk);
    }
    group_similar_messages();
}

sub proto_report {
    my (%o) = @_;
    my $rows = 0;
    $rows += scalar keys %{ $log_messages{$_} } for keys %log_messages;
    printf "Lines read: %d, matched: %d\n", $proto_lines_read, $proto_lines_matched;
    printf "Sensitivity: %d%%, final pass: %s, group ceiling: %d\n", $consolidation_threshold,
        $consolidation_final_pass ? 'on' : 'off', $consolidation_final_ceiling;
    printf "Keys seen: %d, rows after grouping: %d, groups: %d\n", $consolidation_total_keys_seen, $rows,
        scalar(grep { /^  cluster: / } @{ $verbose_section_buffer{'message-grouping-membership'} // [] });
    print "\nTop $o{top} rows by occurrences:\n";
    my @all;
    for my $cat (keys %log_messages) { push @all, [ $cat, $_, $log_messages{$cat}{$_}{occurrences} ] for keys %{ $log_messages{$cat} } }
    for my $r ((sort { $b->[2] <=> $a->[2] || $a->[1] cmp $b->[1] } @all)[0 .. min($o{top}, scalar @all) - 1]) {
        printf "  %9d  %s%s\n", $r->[2], ($log_messages{$r->[0]}{$r->[1]}{is_consolidated} ? '~ ' : '  '), $r->[1];
    }
    if ($o{membership}) {
        print "\n=== message-grouping / cluster-membership ===\n";
        print "$_\n" for @{ $verbose_section_buffer{'message-grouping-membership'} // [] };
        print "=== END message-grouping / cluster-membership ===\n";
    }
}
DRIVER

my $engine = "package main;\n$ltl_imports\n#line " . ($globals_at + 1) . " \"$ltl_path\"\n"
           . join('', @ltl_lines[$globals_at .. $main_at - 1])
           . "\n#line 1 \"prototype driver\"\n$driver\n1;\n";
eval $engine or die "Compiling ltl's consolidation engine from $ltl_path failed: $@";

proto_configure(sensitivity => $sensitivity, group_ceiling => $group_ceiling, final_pass => $final_pass);
for my $file (@files) {
    open my $fh, '<', $file or die "Cannot open $file: $!\n";
    while (my $line = <$fh>) {
        $line =~ s/\r?\n\z//;
        proto_read_line($line);
    }
    close $fh;
}
proto_finish();
proto_report(top => $top_n, membership => $membership);
