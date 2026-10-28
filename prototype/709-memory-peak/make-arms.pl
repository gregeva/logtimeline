#!/usr/bin/env perl
# #709 P1: generate the arms for grouping's structure walks under -mem.
# Question: at which of grouping's two reading sites (each checkpoint, in
# run_consolidation_checkpoint(), and each final-pass window, in
# process_final_pass_window()) should -mem walk the named-structure map, given
# the cost of the walk against the grouping high-water marks it captures?
#
# Every arm is the given ltl with a mechanical edit; this script is the only
# author of an arm and asserts every landmark and substitution count, so a base
# that has moved fails loudly. Every arm but `tracked` carries the 38 stores of
# features/memory-tracking-improvements.md § Store inventory in
# named_structure_sizes(), as delivered, since the map's size sets a walk's
# cost, and times each walk per reading site.
#
#   tracked      the base, verbatim: the floor arm, run without -mem
#   every        a walk at every checkpoint and every final-pass window, as the
#                base does
#   boundaries   no reading inside grouping; the phase-boundary walks only
#   grouponly    at every checkpoint and window a walk of only the stores
#                grouping writes (GROUPING_STORES below); every store at the
#                phase boundaries
#   transient    grouponly without the message store and its counters: at every
#                checkpoint and window a walk of the consolidation_* stores only
#   cond-<count>-<margin>
#                a reading at a checkpoint or window only when <count> has
#                grown past its value at the last such reading by <margin>
#                percent; <count> is `held` (the keys awaiting grouping,
#                %consolidation_key_message), `clusters` (the groups found,
#                over every category) or `either` (whichever of the two has
#                grown past its own value at the last reading)
#   trace        every, also writing a record per reading to the file named by
#                $ENV{P1_TRACE}: the site, both counts, the walk's time, the
#                RSS and every store's size; not timed, it lets the conditional
#                arms be simulated over every margin from one run
#
# Under D1 (features/memory-tracking-improvements.md § Decisions) the peak is
# the operating system's kept high-water mark, so a reading inside grouping
# serves only the walk: an arm that skips the walk skips the whole
# measure_memory_structures() call, its RSS reading included.
#
#   usage: make-arms.pl <ltl> <output dir> [margin percent ...]   (default 0 25 100)
use strict;
use warnings;

my ($base, $out, @margins) = @ARGV;
die "usage: make-arms.pl <ltl> <output dir> [margin percent ...]\n" unless defined $base && defined $out;
@margins = (0, 25, 100) unless @margins;
mkdir $out unless -d $out;
open my $fh, '<', $base or die "$base: $!";
my $src = do { local $/; <$fh> };
close $fh;

sub rep {
    my ($t, $from, $to, $want, $what) = @_;
    my $n = () = $$t =~ /\Q$from\E/g;
    die "make-arms: $what: expected $want of [" . substr($from, 0, 80) . "], found $n\n" unless $n == $want;
    $$t =~ s/\Q$from\E/$to/g;
}
sub write_arm {
    my ($name, $text) = @_;
    my $path = "$out/ltl-$name";
    open my $o, '>', $path or die "$path: $!";
    print {$o} $text;
    close $o;
    chmod 0755, $path;
    print "wrote $path\n";
}

# The 38 stores of § Store inventory, as `name => \%store` lines of the map.
my @inventory = qw(
    %histogram_values_hl %histogram_buckets %histogram_buckets_hl %histogram_stats
    %histogram_stats_hl %histogram_boundaries %heatmap_percentiles
    %consolidation_cat_stats %consolidation_category_unmatched_count
    %consolidation_pattern_generation %consolidation_key_generation
    %consolidation_key_checkpoint_count %consolidation_absorption_ema
    %consolidation_streaming_absorbed %consolidation_final_pass_skipped
    %consolidation_cliff_edge
    @files_processed %in_files_matched %index_file_data %index_preseed
    %index_aggregated %format_detection %format_detection_evidence
    %format_detection_sample %timestamp_date_cache %unregistered_levels
    %unregistered_levels_by_file
    @verbose_output %verbose_section_buffer %section_rows %category_totals
    @progress_history @notice_records @memory_debug_records %bin_counter_telemetry
    %stats_demand_telemetry %udm_skipped_lines %numeric_filter_no_metric
);
die "make-arms: expected 38 inventory stores, have " . scalar(@inventory) . "\n" unless @inventory == 38;
sub map_line { my ($v) = @_; (my $name = $v) =~ s/^[%@]//; sprintf "        %-26s => Devel::Size::total_size(\\%s),\n", $name, $v }

# The stores run_consolidation_checkpoint() and process_final_pass_window()
# write, directly or through the subs they call: the message store, the
# message counters a merge deletes from, and every consolidation_* store.
my @grouping_stores = qw(
    %log_messages %log_messages_counters
    %consolidation_clusters %consolidation_patterns %consolidation_key_message
    %consolidation_unmatched %consolidation_id_index %consolidation_key_trigrams
    %consolidation_cat_stats %consolidation_category_unmatched_count
    %consolidation_pattern_generation %consolidation_key_generation
    %consolidation_key_checkpoint_count %consolidation_absorption_ema
    %consolidation_streaming_absorbed %consolidation_final_pass_skipped
    %consolidation_cliff_edge
);

my $map_end = "        consolidation_key_trigrams => Devel::Size::total_size(\\%consolidation_key_trigrams),\n    );\n}\n";
my $measure_head = "sub measure_memory_structures {\n    my (\$site) = \@_;\n";
my $walk = "    my %current_sizes = named_structure_sizes();\n";
my $hwm_end = "        if (\$current > \$hwm) {\n            \$memory_high_water_marks{\$struct} = \$current;\n        }\n    }\n}\n";
my $site_cp = "    measure_memory_structures('grouping_checkpoint');\n";
my $site_fp = "    measure_memory_structures('grouping_final_pass');\n";

# --- common: the 38 stores, the per-site walk timer ---------------------------
my $common = $src;
rep(\$common, $map_end,
    "        consolidation_key_trigrams => Devel::Size::total_size(\\%consolidation_key_trigrams),\n"
    . join('', map { map_line($_) } @inventory) . "    );\n}\n"
    . "\n# P1: the stores grouping writes, walked alone by the grouponly arm.\n"
    . "sub p1_grouping_structure_sizes {\n    require Devel::Size;\n    return (\n"
    . join('', map { map_line($_) } @grouping_stores) . "    );\n}\n",
    1, 'common: map end');
my $timer_head = "# P1: walks per reading site, [count, seconds], printed to stderr at exit.\n";
rep(\$common, $measure_head,
    $timer_head
    . "my %p1_walks;\n"
    . "my \$p1_last_walk_s = 0;\n"
    . "END { printf STDERR \"P1WALK\\t%s\\t%d\\t%.6f\\n\", \$_, \@{ \$p1_walks{\$_} } for sort keys %p1_walks; }\n"
    . "sub measure_memory_structures {\n    my (\$site, \$p1_subset) = \@_;\n",
    1, 'common: measure head');
rep(\$common, $walk,
    "    my \$p1_t0 = [gettimeofday];\n"
    . "    my %current_sizes = \$p1_subset ? p1_grouping_structure_sizes() : named_structure_sizes();\n"
    . "    \$p1_last_walk_s = tv_interval(\$p1_t0);\n"
    . "    my \$p1_tally = \$p1_walks{\$site} //= [ 0, 0 ];\n"
    . "    \$p1_tally->[0]++;\n"
    . "    \$p1_tally->[1] += \$p1_last_walk_s;\n",
    1, 'common: walk timer');
for ($site_cp, $site_fp) { rep(\$common, $_, $_, 1, 'common: grouping site') }
rep(\$common, $hwm_end, $hwm_end, 1, 'common: high-water update end');

write_arm('tracked', $src);
write_arm('every', $common);

# --- boundaries ---------------------------------------------------------------
{
    my $t = $common;
    rep(\$t, $site_cp, '', 1, 'boundaries: checkpoint');
    rep(\$t, $site_fp, '', 1, 'boundaries: window');
    write_arm('boundaries', $t);
}

# --- grouponly ------------------------------------------------------------------
{
    my $t = $common;
    rep(\$t, $site_cp, "    measure_memory_structures('grouping_checkpoint', 1);\n", 1, 'grouponly: checkpoint');
    rep(\$t, $site_fp, "    measure_memory_structures('grouping_final_pass', 1);\n", 1, 'grouponly: window');
    write_arm('grouponly', $t);
}

# --- transient --------------------------------------------------------------------
# grouponly without the message store and its counters: inside grouping, a walk
# of the consolidation_* stores alone; the boundary walks cover the rest.
{
    my $t = $common;
    my @transient = grep { !/^%log_messages/ } @grouping_stores;
    die "make-arms: expected 15 transient stores, have " . scalar(@transient) . "\n" unless @transient == 15;
    rep(\$t, "\n# P1: the stores grouping writes, walked alone by the grouponly arm.\n"
             . "sub p1_grouping_structure_sizes {\n    require Devel::Size;\n    return (\n"
             . join('', map { map_line($_) } @grouping_stores) . "    );\n}\n",
             "\n# P1: grouping's consolidation_* stores, walked alone by the transient arm.\n"
             . "sub p1_grouping_structure_sizes {\n    require Devel::Size;\n    return (\n"
             . join('', map { map_line($_) } @transient) . "    );\n}\n",
             1, 'transient: subset');
    rep(\$t, $site_cp, "    measure_memory_structures('grouping_checkpoint', 1);\n", 1, 'transient: checkpoint');
    rep(\$t, $site_fp, "    measure_memory_structures('grouping_final_pass', 1);\n", 1, 'transient: window');
    write_arm('transient', $t);
}

# --- cond-<count>-<margin> --------------------------------------------------------
my %count_expr = (
    held     => 'scalar keys %consolidation_key_message',
    clusters => 'do { my $n = 0; $n += keys %$_ for values %consolidation_clusters; $n }',
);
# `either` reads when one of the two counts has grown past its own high.
my %count_parts = ( held => ['held'], clusters => ['clusters'], either => [ 'held', 'clusters' ] );
for my $count (qw(held clusters either)) {
    my @parts = @{ $count_parts{$count} };
    for my $margin (@margins) {
        my $t = $common;
        my $factor = 1 + $margin / 100;
        rep(\$t, $timer_head,
            "# P1: a reading inside grouping only when the count has grown past its\n"
            . "# value at the last such reading by the margin; [evaluated, read] at exit.\n"
            . join('', map { "my \$p1_high_$_ = 0;\n" } @parts)
            . "my \@p1_cond = ( 0, 0 );\n"
            . "END { printf STDERR \"P1COND\\t$count\\t$margin\\t%d\\t%d\\n\", \@p1_cond; }\n"
            . "sub p1_grouping_grown {\n"
            . "    \$p1_cond[0]++;\n"
            . join('', map { "    my \$$_ = $count_expr{$_};\n" } @parts)
            . "    return 0 unless " . join(' || ', map { "\$$_ > \$p1_high_$_ * $factor" } @parts) . ";\n"
            . join('', map { "    \$p1_high_$_ = \$$_ if \$$_ > \$p1_high_$_;\n" } @parts)
            . "    \$p1_cond[1]++;\n"
            . "    return 1;\n"
            . "}\n"
            . $timer_head, 1, "cond-$count-$margin: condition");
        rep(\$t, $site_cp, "    measure_memory_structures('grouping_checkpoint') if p1_grouping_grown();\n", 1, "cond-$count-$margin: checkpoint");
        rep(\$t, $site_fp, "    measure_memory_structures('grouping_final_pass') if p1_grouping_grown();\n", 1, "cond-$count-$margin: window");
        write_arm("cond-$count-$margin", $t);
    }
}

# --- trace ------------------------------------------------------------------------
{
    my $t = $common;
    rep(\$t, $hwm_end,
        "        if (\$current > \$hwm) {\n            \$memory_high_water_marks{\$struct} = \$current;\n        }\n    }\n"
        . "    p1_trace(\$site, \\%current_sizes);\n}\n"
        . "# P1: one record per reading: a `reading` line, then a `store` line per store.\n"
        . "my \$p1_trace_fh;\n"
        . "my \$p1_trace_seq = 0;\n"
        . "sub p1_trace {\n"
        . "    my (\$site, \$sizes) = \@_;\n"
        . "    return unless \$ENV{P1_TRACE};\n"
        . "    unless (\$p1_trace_fh) { open \$p1_trace_fh, '>', \$ENV{P1_TRACE} or die \"P1_TRACE: \$!\"; }\n"
        . "    my \$seq = ++\$p1_trace_seq;\n"
        . "    my \$held = $count_expr{held};\n"
        . "    my \$clusters = $count_expr{clusters};\n"
        . "    printf {\$p1_trace_fh} \"reading\\t%d\\t%s\\t%d\\t%d\\t%d\\t%.6f\\n\", \$seq, \$site, \$held, \$clusters, \$current_memory_usage, \$p1_last_walk_s;\n"
        . "    printf {\$p1_trace_fh} \"store\\t%d\\t%s\\t%d\\n\", \$seq, \$_, \$sizes->{\$_} for sort keys %\$sizes;\n"
        . "}\n",
        1, 'trace: record');
    write_arm('trace', $t);
}
