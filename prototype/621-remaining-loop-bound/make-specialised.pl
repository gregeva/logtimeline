#!/usr/bin/env perl
# #621: the read loop specialised for the default options, the body a
# generator would emit for a run that names none.
#
# Question: what does removing the loop's tests of values fixed for the run
# actually recover on the default options, against the bound computed from
# their count and the cost of one inserted test (analysis.md beside the
# results)?
#
# Every edit is mechanical and asserted: a site is found by a substring of its
# source line inside the per-line loop, the number of sites found must equal
# the number expected, and a block is delimited by counting braces from its
# opening line. A base that has moved fails here instead of producing a probe
# that measures something else. Tests fixed for a file or a format, and the
# first-observation latches, stay: a body generated per run cannot know them.
#
# A guard before the loop stops the probe on any run whose options differ from
# the values the body was specialised for (read from the benchmark runner's
# invocation on both benchmark files), so a probe run is either the specialised
# default or nothing.
#
#   usage: make-specialised.pl <base ltl> <output file>
use strict;
use warnings;

my ($base, $out) = @ARGV;
die "usage: make-specialised.pl <base ltl> <output file>\n" unless defined $base && defined $out;
open my $fh, '<', $base or die "$base: $!";
my @p = <$fh>;
close $fh;

# --- the loop, found afresh before every edit -------------------------------
sub loop_range {
    my ($sub) = grep { $p[$_] =~ /^sub read_and_process_logs \{/ } 0 .. $#p;
    die "make-specialised: no sub read_and_process_logs\n" unless defined $sub;
    my ($next) = grep { $p[$_] =~ /^sub / } $sub + 1 .. $#p;
    my @loops = grep { $p[$_] =~ /^\s*while \(1\) \{/ } $sub .. $next;
    die "make-specialised: expected one per-line loop, found " . @loops . "\n" unless @loops == 1;
    my ($close) = grep { $p[$_] =~ /^\s*close \$fh;/ } $loops[0] .. $next;
    die "make-specialised: no close \$fh after the loop\n" unless defined $close;
    return ($loops[0], $close);
}
sub hits {
    my ($snip, $want) = @_;
    my ($l, $c) = loop_range();
    my @h = grep { index($p[$_], $snip) >= 0 } $l + 1 .. $c - 1;
    die "make-specialised: expected $want line(s) carrying [$snip] in the loop, found " . @h . "\n" unless @h == $want;
    return @h;
}
# The line on which the block opened at line $i closes. The block's brace is
# the last character of the first line from $i that ends in one (a condition
# may span lines); braces are counted from there. Comments are stripped (a #
# preceded by whitespace or at the start; $# and \# are not comments).
sub strip_comment { (my $t = $_[0]) =~ s/(?:^|(?<=\s))#.*$//; return $t }
sub close_of {
    my ($i) = @_;
    my $o = $i;
    $o++ until $o > $#p || strip_comment($p[$o]) =~ /\{\s*$/;
    die "make-specialised: no block opens at or after line " . ($i + 1) . "\n" if $o > $#p;
    my $depth = 1;
    for my $j ($o + 1 .. $#p) {
        for my $ch (split //, strip_comment($p[$j])) {
            if ($ch eq '{') { $depth++ }
            elsif ($ch eq '}' && --$depth == 0) {
                die "make-specialised: the block opened at line " . ($i + 1) . " closes on a line that does not start with a brace: line " . ($j + 1) . " [$p[$j]]\n"
                    unless $p[$j] =~ /^\s*\}/;
                return $j;
            }
        }
    }
    die "make-specialised: no close for the block opened at line " . ($i + 1) . "\n";
}
my @log;
sub note { push @log, sprintf "%-12s %2d  %s\n", @_ }

# An if-block whose condition is false for the run: deleted whole, with its
# else arm when $with_else (a condition false whose else arm is also not needed).
sub del_block {
    my ($snip, $want, $with_else) = @_;
    for my $i (reverse hits($snip, $want)) {
        my $end = close_of($i);
        if ($p[$end] =~ /^\s*\}\s*else\s*\{/) {
            die "make-specialised: [$snip] has an else arm\n" unless $with_else;
            $end = close_of($end);
        }
        die "make-specialised: [$snip] closes on [$p[$end]]\n" unless $p[$end] =~ /^\s*\}\s*(?:#.*)?$/;
        splice @p, $i, $end - $i + 1;
    }
    note('del_block', $want, $snip);
}
# An if/else whose condition is false for the run: the else arm's body stays.
sub take_else {
    my ($snip, $want) = @_;
    for my $i (reverse hits($snip, $want)) {
        my $else = close_of($i);
        die "make-specialised: [$snip] has no else arm\n" unless $p[$else] =~ /^\s*\}\s*else\s*\{\s*$/;
        my $end = close_of($else);
        die "make-specialised: [$snip] else arm closes on [$p[$end]]\n" unless $p[$end] =~ /^\s*\}\s*(?:#.*)?$/;
        splice @p, $end, 1;
        splice @p, $i, $else - $i + 1;
    }
    note('take_else', $want, $snip);
}
# An if-block whose condition is true for the run: the body stays.
sub unwrap {
    my ($snip, $want) = @_;
    for my $i (reverse hits($snip, $want)) {
        die "make-specialised: [$snip] does not open its block on its own line\n" unless $p[$i] =~ /\{\s*$/;
        my $end = close_of($i);
        die "make-specialised: [$snip] closes on [$p[$end]]\n" unless $p[$end] =~ /^\s*\}\s*(?:#.*)?$/;
        splice @p, $end, 1;
        splice @p, $i, 1;
    }
    note('unwrap', $want, $snip);
}
# A statement that does nothing for the run, from the line carrying the
# snippet to the first line ending in a semicolon.
sub del_stmt {
    my ($snip, $want) = @_;
    for my $i (reverse hits($snip, $want)) {
        my $end = $i;
        $end++ until $p[$end] =~ /;\s*(?:#.*)?$/;
        splice @p, $i, $end - $i + 1;
    }
    note('del_stmt', $want, $snip);
}
# A line that does nothing for the run, deleted whole (a one-line statement or
# a one-line block).
sub del_line {
    my ($snip, $want) = @_;
    splice @p, $_, 1 for reverse hits($snip, $want);
    note('del_line', $want, $snip);
}
# A test whose answer is fixed for the run, taken out of a condition.
sub subst {
    my ($from, $to, $want) = @_;
    for my $i (hits($from, $want)) {
        my $n = $p[$i] =~ s/\Q$from\E/$to/g;
        die "make-specialised: [$from] occurs $n times on one line\n" unless $n == 1;
    }
    note('subst', $want, $from);
}

# --- the edits, in an order where each count is exact ----------------------
# every line read
del_line(q`memory_debug_sample("read_lines") if $show_memory_debug`, 1);            # -mem debug off
del_block(q`if ($total_lines_read % PROGRESS_LINE_STRIDE == 0 && !$disable_progress) {`, 1);   # --disable-progress
del_block(q`if (@udm_configs && !$csv_detected) {`, 1);                             # no -udm
del_block(q`if( $discard_any_field ) {`, 1);                                        # no -d field
subst(q`if( !$omit_count && defined $message ) {`, q`if( defined $message ) {`, 1); # no -oc
subst(q` count=?/g unless $expose_count;`, q` count=?/g;`, 1);                      # no -x count
del_block(q`if (@udm_configs && $is_line_match && defined $message) {`, 1);         # no -udm
del_line(q`my %udm_values;`, 1);
del_line(q`$metrics_observed = 1 if %udm_values;`, 1);
# every matched line: -du is not given, so only the format's declared unit applies
del_stmt(q`if (defined $duration_unit_override) {`, 1);     # the if line and its statement up to the first ;
subst(q`} elsif ($line_entry && defined $line_entry->[FR_DURATION_UNIT]`, q`if ($line_entry && defined $line_entry->[FR_DURATION_UNIT]`, 1);
del_block(q`if ($index_capture_demand) {`, 3);                                      # the run index is not written
del_block(q`if (%filter_range_tod) {`, 1, 1);                                       # no -st/-et: neither the window nor the absolute bounds
del_block(q`if ($profile_mode) {`, 1);                                              # no --profile
del_line(q`if( defined( $exclude_filter )`, 1);                                     # no -exclude
del_line(q`if( defined( $include_filter )`, 1);                                     # no -include
del_block(q`if( $outcome_filter_active ) {`, 1);                                    # no outcome filter
del_block(q`if( $numeric_filter_active ) {`, 1);                                    # no numeric filter
del_line(q`if ($udm_skipped) {`, 1);
del_line(q`my $udm_skipped;`, 1);
take_else(q`if( $highlight_active`, 1);                                             # no -highlight
del_block(q`if ($timestamp_capture_ns) {`, 1);                                      # no nanosecond bound in demand
take_else(q`if ($bucket_key_scale > 1) {`, 1);                                      # whole-second buckets
# every included line
del_line(q`$profile_included_samples++ if $profile_mode;`, 1);
subst(q`if( $capture_messages && defined( $message ) ) {`, q`if( defined( $message ) ) {`, 1);   # messages retained
del_line(q`$log_level =~ s/-HL$//;`, 1);                                            # no -HL suffix without -highlight
del_block(q`if( $expose_active ) {`, 1);                                            # no -x
del_block(q`if( $discard_active ) {`, 1);                                           # no -d
del_block(q`if( $mask_active ) {`, 1);                                              # no -m
del_line(q`my $consolidation_s1_matched = 0;`, 1);
del_block(q`if ($grouping_active) {`, 1);                                           # no -g
del_stmt(q`$new_key_grouping_key = $log_level // ""`, 1);                            # -V message-grouping not asked for
del_block(q`if (defined $new_key_grouping_key) {`, 1);
del_line(q`my $new_key_grouping_key;`, 1);
unwrap(q`if (!$consolidation_s1_matched) {`, 1);
subst(q`++ if $message_outcomes_demand && $line_outcome;`, q`++ if $line_outcome;`, 2);   # outcomes per message demanded
del_block(q`if( defined $bytes && $message_bytes_demand ) {`, 1);                   # no per-message bytes demand
del_block(q`if (@udm_configs) {`, 2);                                               # no -udm (message and bucket stores)
subst(q`if( defined $duration && !$omit_durations ) {`, q`if( defined $duration ) {`, 1);       # no -od
unwrap(q`if( $message_duration_stats_demand ) {`, 1);                               # per-message statistics demanded
subst(q`unless $message_stats_bin;`, q`;`, 1);                                      # raw per-message model
del_block(q`if ($message_stats_bin) {`, 1);
subst(q`if( $duration_observed && !$omit_durations && $duration >= 0 ) {`, q`if( $duration_observed && $duration >= 0 ) {`, 1);
unwrap(q`if( $bucket_duration_stats_demand ) {`, 1);                                # per-bucket statistics demanded
subst(q`unless $bucket_stats_bin;`, q`;`, 1);                                       # raw per-bucket model
del_block(q`if ($bucket_stats_bin) {`, 1);
subst(q`if( $bytes_observed_line && $bucket_bytes_demand ) {`, q`if( $bytes_observed_line ) {`, 1);   # per-bucket bytes demanded
take_else(q`if( $bytes_aggregate_demand ) {`, 1);                                   # no bytes extrema demanded
del_block(q`if ($heatmap_enabled) {`, 1);                                           # no -hm
del_block(q`if ($histogram_enabled) {`, 1);                                         # no -hg
del_block(q`if( ( defined $threadpool && $threadpool ne "" ) && ( ( defined $threadpool_activity_regex`, 1);   # no thread-pool activity asked for
del_block(q`if( $line_is_highlighted ) {`, 2);                                      # session and user highlight counts
del_line(q` if $line_is_highlighted;`, 4);                                          # the remaining highlight read-backs
del_line(q`$line_is_highlighted = 0;`, 2);                                          # its declaration and the plain arm's reset
subst(q` && $session_capture_demand ) {`, q` ) {`, 1);                              # the session column is shown
subst(q` && $user_capture_demand ) {`, q` ) {`, 1);                                 # the user column is shown

# --- the guard: the options the body was specialised for -------------------
my $guard = <<'GUARD';
        die "specialised probe: the run's options differ from those the loop was specialised for\n"
            unless !$show_memory_debug && $disable_progress && !@udm_configs && !$discard_any_field
                && !$omit_count && !$expose_count && !defined $duration_unit_override
                && !$index_capture_demand && !%filter_range_tod
                && $filter_range_epoch{start} == 0 && $filter_range_epoch{end} == 2521843200
                && !$profile_mode && !defined $exclude_filter && !defined $include_filter
                && !$outcome_filter_active && !$numeric_filter_active && !$highlight_active
                && !$timestamp_capture_ns && $bucket_key_scale <= 1 && $capture_messages
                && !$expose_active && !$discard_active && !$mask_active && !$grouping_active
                && !$message_grouping_section_wanted && $message_outcomes_demand && !$message_bytes_demand
                && !$omit_durations && $message_duration_stats_demand && !$message_stats_bin
                && $bucket_duration_stats_demand && !$bucket_stats_bin && $bucket_bytes_demand
                && !$bytes_aggregate_demand && !$heatmap_enabled && !$histogram_enabled
                && $session_capture_demand && $user_capture_demand
                && !defined $threadpool_activity_regex && !$include_threadpool_summary;
GUARD
my ($loop) = loop_range();
splice @p, $loop, 0, $guard;

open my $o, '>', $out or die "$out: $!";
print {$o} @p;
close $o;
chmod 0755, $out;
my ($l, $c) = loop_range();
print @log;
printf "wrote %s: loop %d lines (base: see make-probes.pl)\n", $out, $c - $l + 1;

