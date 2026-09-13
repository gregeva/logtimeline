#!/usr/bin/env perl
#
# Prototype for issue #528 (a transform that assigns arithmetic into a shared
# record lexical enlarges every duration the raw statistics model retains for
# the rest of the run).
#
# THE QUESTION, as features/528-record-lexical-retained-representation.md
# § The question states it: does normalising the retained duration to a number
# at each copy site buy enough memory to be worth a per-retention operation on
# the hot path?
#
# THE TWO ARMS, as § The arms states them:
#
#   baseline    the five retention sites exactly as `ltl` carries them today:
#               each pushes the shared record lexical itself.
#   normalised  identical, except that each retention site pushes a numeric
#               normalisation of the lexical rather than the lexical.
#
# PRODUCTION CALL STRUCTURE. Per prototype/README.md the baseline arm
# reproduces the production call structure, not just its logic. What that means
# here, and what this file does about it:
#
#   - the record fields are FILE-SCOPE lexicals (`our`-free `my` at file
#     scope), shared by every line of the run, not per-line `my` variables.
#     This is D39 of features/log-format-registry.md (a single generated scan
#     sub per scan order: zero per-line sub calls, write-direct into
#     file-scoped record lexicals), and it is the whole reason the defect
#     exists: a scalar body grows and never shrinks.
#   - the extraction is a GENERATED closure compiled from a source string and
#     writing direct into those lexicals, as build_format_registry() compiles
#     one, not a sub that returns a record.
#   - the registry's startup extraction-parity gate runs before line 1, over
#     the declared samples of an entry whose transform converts a unit. This
#     is gate 2 of build_format_registry(), and it is what puts a
#     representation into $duration before any input is read.
#   - the index block's numeric read, `$fd->{duration_sum} += $duration`, runs
#     ahead of every retention site on every line, exactly as it does in
#     read_and_process_logs().
#   - the five retention sites carry their production conditions: the two
#     capture-mode `unless`es, the two demand gates, the histogram condition.
#
# Every one of those lines is sliced out of `ltl` verbatim by extract-sites.sh
# and asserted against this file's own arm source at startup, so a reader can
# check in one grep that the arms carry what `ltl` carries. Nothing here is
# restated from memory.
#
# INSTRUMENTATION IS OFF BY DEFAULT. § The arms records the constraint the
# sabotage proof established: a build used as a memory comparand is valid only
# if it differs from its comparand by the change under test alone, and
# instrumentation that reads a scalar's size is itself an allocation. So the
# timed and measured arms run with no probe; `--probe` is a third build whose
# figures are reported separately and never compared against the other two.
#
# THIS PROTOTYPE SHIPS NO CODE INTO ltl. Its output is a measured
# recommendation (D2, architect-locked).
#
# Usage:
#   retained-representation.pl --arm baseline|normalised --lines N --file F \
#       [--sites all|bucket-message] [--probe] [--emit-values FILE]
#
# Prints one TSV block on stdout: RESULT rows carrying the arm, the line count,
# the wall clock, the retained-population sizes and the checksums the
# correctness diff reads.

use strict;
use warnings;
use Time::HiRes qw( time );
use Getopt::Long;

# ---------------------------------------------------------------------------
# The production lines, sliced from `ltl`.
# ---------------------------------------------------------------------------
our %SITES;
my $sites_file = $ENV{LTL528_SITES} || '/tmp/528-sites.pl';
die "prototype 528: no sliced-site fragment at $sites_file.\n"
  . "Run extract-sites.sh first (it slices the production lines out of ltl).\n"
  unless -f $sites_file;
do $sites_file or die "prototype 528: could not load $sites_file: $@ $!\n";
die "prototype 528: $sites_file defined no \%SITES\n" unless keys %SITES;

# ---------------------------------------------------------------------------
# Options.
# ---------------------------------------------------------------------------
my $arm          = 'baseline';
my $want_lines   = 5000;
my $file         = '';
my $sites        = 'all';
my $probe        = 0;
my $emit_values  = '';
my $show_sites   = 0;
my $dump_loop    = 0;
my $shape        = 'access_common_duration';
GetOptions(
    'arm=s'         => \$arm,
    'lines=i'       => \$want_lines,
    'file=s'        => \$file,
    'sites=s'       => \$sites,
    'probe'         => \$probe,
    'emit-values=s' => \$emit_values,
    'show-sites'    => \$show_sites,
    'dump-loop'     => \$dump_loop,
    'shape=s'       => \$shape,
) or die "prototype 528: bad options\n";

if ($show_sites) {
    printf "%-36s ltl:%-6d %s\n", $_, $SITES{$_}{ltl_line}, $SITES{$_}{src}
      for sort { $SITES{$a}{ltl_line} <=> $SITES{$b}{ltl_line} } keys %SITES;
    exit 0;
}

die "prototype 528: --arm must be baseline or normalised\n"
  unless $arm eq 'baseline' || $arm eq 'normalised';
die "prototype 528: --sites must be all or bucket-message\n"
  unless $sites eq 'all' || $sites eq 'bucket-message';
die "prototype 528: --file is required\n" unless length $file;
die "prototype 528: no such file: $file\n" unless -f $file;

if ($probe) {
    require Devel::Size;
    Devel::Size->import(qw( total_size size ));
}

# ---------------------------------------------------------------------------
# The record lexicals.
#
# ltl:2693 `my ( $bytes, $duration );`  — file scope, shared by every entry for
# the whole run. Declared here at file scope for the same reason: a per-line
# `my` would give each line a fresh scalar with a fresh body and the defect
# under measurement would not exist.
# ---------------------------------------------------------------------------
my ( $timestamp_str, $category_bucket, $message, $user, $thread, $session );
my ( $bytes, $duration );
my ( $status_code );

# ---------------------------------------------------------------------------
# The demand booleans and capture modes.
#
# Named after their `ltl` symbols. The values are those a default run on the
# access-log corpus resolves to: raw capture on both stores (choose_data_model
# returns undef, so `// 'raw'` wins, ltl:14139-14140), both duration demands
# set (a timeline latency column and a messages table are both drawn,
# ltl:13942/13949), no highlight, no histogram unless --sites all is asked for
# a histogram-drawing configuration.
#
# The histogram sites 4 and 5 are active only when a histogram is drawn
# (ltl:15442 `if ($histogram_enabled)`), and site 5 additionally only for
# highlighted lines. The default corpus run draws no histogram; --sites all
# measures the sites that are actually live on it, which is sites 1, 2 and 3.
# ---------------------------------------------------------------------------
my $bucket_duration_stats_demand  = 1;      # ltl:13942, default raw-mode run
my $message_duration_stats_demand = 1;      # ltl:13949, default raw-mode run
my $bucket_stats_capture_mode     = 'raw';  # ltl:14140, choose_data_model('bucket-stats')  // 'raw'
my $message_stats_capture_mode    = 'raw';  # ltl:14139, choose_data_model('message-stats') // 'raw'
my $omit_durations                = 0;      # no -od
my $histogram_enabled             = 0;      # no -hg on the corpus run
my %histogram_metrics             = ();     # ltl:15443's first disjunct
my $duration_unit_token           = 'ms';   # the corpus writes milliseconds

# ---------------------------------------------------------------------------
# The retained stores, named for the `ltl` structures the `-V benchmark-data`
# MEMORY rows report.
# ---------------------------------------------------------------------------
my %log_analysis;        # per-time-bucket store; MEMORY log_analysis
my %log_messages;        # per-message-key store; MEMORY log_messages
my %histogram_values;    # MEMORY histogram_values
my %histogram_values_hl;
my %index_file_data;     # the per-file index block's accumulators

# ---------------------------------------------------------------------------
# convert_duration_to_ms, as the unit transform calls it.
#
# Only the ladder steps the access family can name are restated; the source is
# `sub convert_duration_to_ms` in ltl. The prototype calls it exactly where the
# production transform calls it: inside the generated extraction closure, on
# the registry entry whose samples carry a unit token.
# ---------------------------------------------------------------------------
my %duration_unit_divisor = (      # ltl: sub convert_duration_to_ms
    ms => 1,
    s  => 0.001,                   # a second is 1000 ms: value / 0.001
    us => 1000,
    ns => 1_000_000,
);
sub convert_duration_to_ms {
    my ( $value, $unit ) = @_;
    return $value unless defined $value && defined $unit;
    my $d = $duration_unit_divisor{$unit};
    return $value unless defined $d;
    return $value / $d;
}

# ---------------------------------------------------------------------------
# The generated extraction closure.
#
# build_format_registry() compiles one source string per entry into a closure
# that writes DIRECTLY into the record lexicals above and returns nothing.
# This reproduces that shape: a string of Perl source, eval'd once, closing
# over the file-scope lexicals. A sub that parsed a line and returned a record
# would measure a different program.
#
# The pattern is access_common_duration's (ltl:3135), with its field map
# (ltl:3136) and the transforms of its list that touch the record fields this
# prototype retains.
#
# THE ASSIGNMENT SHAPE IS LOAD-BEARING and is reproduced exactly. The generator
# (ltl: compile_format_scan_block) builds the condition as
#
#     ( ( $targets ) = $_[0] =~ m~$pattern~ )
#
# — one list assignment from the match's list-context result, with `undef`
# placeholders for the discarded ordinals, evaluated in boolean context. That
# shape leaves $duration a pure string SV (POK only, 48 bytes measured). The
# nearby-looking alternative of assigning from the numbered capture variables
# ( ( $user, ... ) = ( $3, $4, ... ) ) leaves it carrying an extra
# representation from the start (88 bytes measured), so a prototype written
# that way would report a baseline `ltl` does not have and would understate
# the candidate's saving.
#
# Two shapes, both with their recognition pattern sliced from the registry
# spec rather than restated: the integer-millisecond shape the timed corpus
# binds, and the fractional-millisecond thread-session shape the
# correctness-only arm binds (§ The risk to check: fractional durations are
# where a retained value that becomes numeric could change a rendered
# spelling).
# ---------------------------------------------------------------------------
my %shape_spec = (
    # slug => [ sliced-pattern key, the field_map's capture targets in ordinal
    #           order with undef for the discarded ones, extra transforms ]
    access_common_duration => [
        'pattern_access_common_duration',
        'undef, undef, $user, $timestamp_str, $message, $category_bucket, $bytes, $duration',
        '',                                         # ltl:3137's transform list, minus the session/user prepends
    ],
    access_common_duration_thread_session => [
        'pattern_access_common_duration_thread_session',
        'undef, undef, $user, $timestamp_str, $message, $category_bucket, $bytes, $duration, $thread, $session',
        '',                                         # ltl:3006's transform list, minus the session/user prepends
    ],
);
my $spec = $shape_spec{$shape}
  or die "prototype 528: --shape must be one of: " . join( ', ', sort keys %shape_spec ) . "\n";
my ( $pattern_key, $targets, $extra_transforms ) = @$spec;
my $pattern = $SITES{$pattern_key}{src};
# The sliced line is the spec's `pattern_src => '...',`; take the quoted value.
$pattern =~ s/^pattern_src\s*=>\s*'//  or die "prototype 528: cannot read the sliced pattern for $shape\n";
$pattern =~ s/',$//                    or die "prototype 528: cannot read the sliced pattern for $shape\n";
$pattern =~ s/\\'/'/g;

my $extract_src = qq{
    sub {
        return 0 unless
            ( ( $targets ) = \$_[0] =~ m~$pattern~ );
        \$status_code = \$category_bucket; \$category_bucket =~ s/(\\d)\\d{2}/\$1xx/;  # status_bucket, ltl:2802
        \$timestamp_str =~ s/ \\+\\d{4}\$//;                                           # chop_tz_offset, ltl:2800
        undef \$bytes if \$bytes eq "-";                                               # undef_bytes_dash, ltl:2803
        \$message =~ s/ HTTP\\/\\d\\.\\d\$//;                                          # chop_http_proto, ltl:2804
        \$message =~ s/\\?.+\$//;                                                      # strip_query_string, ltl:2805
        $extra_transforms
        return 1;
    }
};
my $extract = eval $extract_src;   ## no critic
die "prototype 528: extraction closure failed to compile: $@\n" if $@;

# ---------------------------------------------------------------------------
# The startup extraction-parity gate, gate 2 of build_format_registry().
#
# It runs every entry's real extraction closure over that entry's declared
# sample lines BEFORE the first line of input is read, and a transform is part
# of an extraction closure. The access_common_duration_bracketed entry declares
# samples whose durations carry a unit token, so its unit transform
# (duration_from_unit_token, ltl:2796) fires on every run of the tool whatever
# the input.
#
# Both arms run this gate, in the form `ltl` carries today: the transform
# concatenates the empty string, so the lexical is asked to carry a string. The
# candidate under test is about the RETENTION sites, not about the transform,
# so changing this would measure a different question.
# ---------------------------------------------------------------------------
sub run_extraction_parity_gate {
    # The bracketed entry's samples (ltl: the access_common_duration_bracketed
    # spec's `samples`), reduced to the duration token and its unit, which is
    # the only part of the sample this gate's effect on $duration depends on.
    for my $sample ( [ '0.005', 's' ], [ '0.012', 's' ] ) {
        ( my $v, my $unit ) = @$sample;
        $duration = $v;
        # ltl:2796, verbatim in effect: the empty-string concatenation is what
        # keeps the lexical string-shaped.
        $duration = '' . convert_duration_to_ms( $duration, $unit )
          if defined $duration && $unit ne 'ms';
    }
    # format_record_reset() restores the values between gates and cannot
    # restore the shape (ltl: sub format_record_reset).
    ( $bytes, $duration ) = ( undef, undef );
}

# ---------------------------------------------------------------------------
# The retention sites.
#
# Two arms, compiled from source strings so that each arm's text can be
# asserted against the lines extract-sites.sh sliced out of `ltl`. The baseline
# arm's site bodies are the production lines; the normalised arm's differ from
# them by the normalisation alone.
#
# The normalisation is `0 + $duration`: the candidate as § The question states
# it, "normalising the retained duration to a number at each copy site", which
# is the effect `-du` already produces as a side effect.
# ---------------------------------------------------------------------------
my %site_body = (
    baseline => {
        site1 => q{push @{$log_analysis{$bucket}{durations}}, $duration
                       unless $bucket_stats_capture_mode eq 'bin';},
        site2 => q{push @{$log_messages{$category}{$log_key}{durations}}, $duration
                       unless $message_stats_capture_mode eq 'bin';},
        site3 => q{$stats_source->{durations} = [$duration] unless $message_stats_capture_mode eq 'bin';},
        site4 => q{push @{$histogram_values{duration}}, $duration;},
        site5 => q{push @{$histogram_values_hl{duration}}, $duration if $is_highlighted;},
    },
    normalised => {
        site1 => q{push @{$log_analysis{$bucket}{durations}}, 0 + $duration
                       unless $bucket_stats_capture_mode eq 'bin';},
        site2 => q{push @{$log_messages{$category}{$log_key}{durations}}, 0 + $duration
                       unless $message_stats_capture_mode eq 'bin';},
        site3 => q{$stats_source->{durations} = [0 + $duration] unless $message_stats_capture_mode eq 'bin';},
        site4 => q{push @{$histogram_values{duration}}, 0 + $duration;},
        site5 => q{push @{$histogram_values_hl{duration}}, 0 + $duration if $is_highlighted;},
    },
);

# Assert each baseline site body against the line extract-sites.sh sliced out
# of `ltl`, with whitespace collapsed. A prototype whose baseline has drifted
# from production measures nothing, so this is fatal rather than a warning.
sub collapse { my $s = shift; $s =~ s/\s+/ /g; $s =~ s/^ | $//g; return $s }
{
    my @checks = (
        [ 'site1', "$SITES{site1_bucket_durations_push}{src} $SITES{site1_bucket_durations_cond}{src}" ],
        [ 'site2', "$SITES{site2_message_durations_push}{src} $SITES{site2_message_durations_cond}{src}" ],
        [ 'site3', $SITES{site3_first_sample_store}{src} ],
        [ 'site4', $SITES{site4_histogram_push}{src} ],
        [ 'site5', $SITES{site5_histogram_hl_push}{src} ],
    );
    for my $c (@checks) {
        my ( $name, $production ) = @$c;
        my $mine = collapse( $site_body{baseline}{$name} );
        my $theirs = collapse($production);
        next if $mine eq $theirs;
        die "prototype 528: the baseline arm's $name has drifted from ltl.\n"
          . "  prototype: $mine\n"
          . "  ltl:       $theirs\n"
          . "Re-run extract-sites.sh and reconcile before trusting any figure.\n";
    }
}

# ---------------------------------------------------------------------------
# The read loop, compiled per arm.
#
# One generated sub per arm, so that neither arm pays a per-line branch on
# which arm it is. The loop body is the production sequence: extract, index
# block (numeric read included), bucket accumulation, message accumulation,
# histogram capture.
# ---------------------------------------------------------------------------
my $b = $site_body{$arm};
my $histogram_block = $sites eq 'all' ? qq{
            # ltl:15442 `if (\$histogram_enabled)`, then ltl:15443's condition.
            if (\$histogram_enabled) {
                my \$is_highlighted = 0;
                if ((!%histogram_metrics || \$histogram_metrics{duration}) && defined \$duration && \$duration > 0 && !\$omit_durations) {
                    $b->{site4}
                    $b->{site5}
                }
            }
} : '';

my $loop_src = qq{
    sub {
        my ( \$fh, \$limit ) = \@_;
        my \$n = 0;
        while ( my \$line = <\$fh> ) {
            last if \$limit && \$n >= \$limit;
            \$n++;
            next unless \$extract->(\$line);

            # ltl: the per-file index block. The numeric read below runs ahead
            # of every retention site on every line, which is why the lexical
            # always carries a string AND an integer by the time a copy is
            # taken.
            my \$fd = \$index_file_data{'corpus'} ||= {};
            \$fd->{match_count}++;
            if (defined \$duration) {
                \$fd->{duration_occurrences}++;
                \$fd->{duration_sum} += \$duration;
                \$fd->{duration_min} = \$duration if !defined \$fd->{duration_min} || \$duration < \$fd->{duration_min};
                \$fd->{duration_max} = \$duration if !defined \$fd->{duration_max} || \$duration > \$fd->{duration_max};
            }

            # The bucket key. ltl derives it from the parsed timestamp; the
            # prototype derives it from the timestamp string's minute, which
            # produces the same bucket cardinality on this corpus without
            # pulling the whole time machinery in. The retained population per
            # bucket is what the measurement reads, and it is identical.
            my \$bucket = substr(\$timestamp_str, 0, 17);

            \$log_analysis{\$bucket}{occurrences}++;
            if (defined \$duration && !\$omit_durations && \$duration >= 0) {
                \$log_analysis{\$bucket}{total_duration} += \$duration;
                if( \$bucket_duration_stats_demand ) {
                    \$log_analysis{\$bucket}{sum_of_squares} += \$duration ** 2;
                    $b->{site1}
                }
            }

            # The message key: ltl's (category, log_key) pair.
            my \$category = \$category_bucket;
            my \$log_key  = \$message;
            if (exists \$log_messages{\$category}{\$log_key}) {
                \$log_messages{\$category}{\$log_key}{occurrences}++;
                if( defined \$duration && !\$omit_durations ) {
                    \$log_messages{\$category}{\$log_key}{total_duration} += \$duration;
                    \$log_messages{\$category}{\$log_key}{total_duration_num} += \$duration;
                    if( \$message_duration_stats_demand ) {
                        \$log_messages{\$category}{\$log_key}{sum_of_squares} += \$duration ** 2;
                        $b->{site2}
                    }
                }
            }
            else {
                # ltl: the branch that creates a message key's statistics
                # source, carrying site 3.
                my \$stats_source = \$log_messages{\$category}{\$log_key} = { occurrences => 1 };
                if (defined \$duration && !\$omit_durations) {
                    \$stats_source->{total_duration} = \$duration;
                    \$stats_source->{total_duration_num} = \$duration;
                    \$stats_source->{sum_of_squares} = \$duration ** 2;
                    $b->{site3}
                }
            }
$histogram_block
        }
        return \$n;
    }
};
if ($dump_loop) {
    print $loop_src;
    exit 0;
}
my $read_loop = eval $loop_src;   ## no critic
die "prototype 528: read loop failed to compile: $@\n" if $@;

# ---------------------------------------------------------------------------
# Run.
# ---------------------------------------------------------------------------
run_extraction_parity_gate();

open( my $fh, '<', $file ) or die "prototype 528: cannot read $file: $!\n";
my $t0 = time();
my $read = $read_loop->( $fh, $want_lines );
my $elapsed = time() - $t0;
close $fh;

# ---------------------------------------------------------------------------
# The probe, if asked for, reads the stores BEFORE anything else touches them.
#
# Order is load-bearing twice over. Reading a retained value in string context
# — which the correctness checksum below does to every one of them — asks that
# scalar to carry a string, and a scalar's body grows on demand and never
# shrinks. So a size taken after the checksum reports the shape the checksum
# imposed, identical in both arms, rather than the shape the arm retained. And
# the per-scalar size is taken from the array element in place: sizing a copy
# of it measures the copy's body, not the retained one's.
#
# This is the same constraint § The arms records from the sabotage proof, in a
# second form: instrumentation that reads a value is itself a mutation of what
# it is reading.
# ---------------------------------------------------------------------------
my @probe_rows;
if ($probe) {
    my ( $first_bucket ) = grep { $log_analysis{$_}{durations} && @{ $log_analysis{$_}{durations} } }
                           sort keys %log_analysis;
    push @probe_rows, [ 'retained_scalar_body_bytes',
        defined $first_bucket ? Devel::Size::size( $log_analysis{$first_bucket}{durations}[0] ) : 'none' ];
    push @probe_rows, [ 'log_analysis_total_size', Devel::Size::total_size( \%log_analysis ) ];
    push @probe_rows, [ 'log_messages_total_size', Devel::Size::total_size( \%log_messages ) ];
}

# ---------------------------------------------------------------------------
# Report.
#
# The retained population is summarised two ways: the counts, which must be
# identical between the arms, and a checksum over every retained value's
# rendered spelling, which is the correctness check § The risk to check calls
# for — a value retained as a number may render differently from one retained
# as the string it was read as.
# ---------------------------------------------------------------------------
my ( $bucket_count, $bucket_retained ) = ( 0, 0 );
my $bucket_checksum = '';
for my $bk ( sort keys %log_analysis ) {
    $bucket_count++;
    my $d = $log_analysis{$bk}{durations} || [];
    $bucket_retained += scalar @$d;
    $bucket_checksum .= "$bk:" . join( ',', @$d ) . "\n";
}
my ( $message_count, $message_retained ) = ( 0, 0 );
my $message_checksum = '';
for my $cat ( sort keys %log_messages ) {
    for my $k ( sort keys %{ $log_messages{$cat} } ) {
        $message_count++;
        my $d = $log_messages{$cat}{$k}{durations} || [];
        $message_retained += scalar @$d;
        $message_checksum .= "$cat|$k:" . join( ',', @$d ) . "\n";
    }
}

if ( length $emit_values ) {
    open( my $out, '>', $emit_values ) or die "prototype 528: cannot write $emit_values: $!\n";
    print $out $bucket_checksum;
    print $out $message_checksum;
    close $out;
}

sub md5_of {
    my $s = shift;
    require Digest::MD5;
    return Digest::MD5::md5_hex($s);
}

print "RESULT\tarm\t$arm\n";
print "RESULT\tfile\t$file\n";
print "RESULT\tlines_read\t$read\n";
print "RESULT\tsites\t$sites\n";
print "RESULT\twall_clock_s\t" . sprintf( '%.4f', $elapsed ) . "\n";
print "RESULT\tbucket_keys\t$bucket_count\n";
print "RESULT\tbucket_retained_durations\t$bucket_retained\n";
print "RESULT\tmessage_keys\t$message_count\n";
print "RESULT\tmessage_retained_durations\t$message_retained\n";
print "RESULT\tbucket_values_md5\t" . md5_of($bucket_checksum) . "\n";
print "RESULT\tmessage_values_md5\t" . md5_of($message_checksum) . "\n";

# The probe rows, captured above before the checksum touched the stores. This
# is a third build: its figures are reported on their own and are never
# compared against the two measured arms, because loading Devel::Size and
# walking the stores is itself an allocation.
for my $r (@probe_rows) {
    print "PROBE\t$r->[0]\t$r->[1]\n";
}
