#!/usr/bin/env bash
# nondeterministic.sh — the rows of ltl's output that differ between two runs
# of the same command: the elapsed time and memory figures of the run summary.
#
# One definition: every harness comparing the output of two runs drops these
# rows through this file rather than restating the labels, so a new timing or
# memory row is added here once and every comparison ignores it.
#
#   RUN_FIGURE_ROWS            the labels of those rows, a Perl pattern matched
#                              case-insensitively
#   drop_run_figure_rows       filter: standard input without those rows
#   strip_nondeterministic     filter: the surface the regression references
#                              freeze (validate-regression.sh, capture-regression.sh)
#
# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: nondeterministic.sh is a library; source it, do not execute it." >&2
    exit 2
fi

RUN_FIGURE_ROWS='PROCESSING TIME|TOTAL TIME|MAXIMUM MEMORY|INITIALIZE EMPTY|CALCULATE STATISTICS|HEATMAP STATISTICS|HISTOGRAM STATISTICS|GROUP SIMILAR MESSAGES|SCALE DATA|DETECT: FORMAT REGISTRY BUILD|PARSE: FILE PROCESSING|ACCUMULATE: EMPTY BUCKETS|FINALIZE: (?:GROUP SIMILAR|CALCULATE STATISTICS|HEATMAP STATISTICS|HISTOGRAM STATISTICS)|RENDER: SCALE DATA'
export RUN_FIGURE_ROWS

drop_run_figure_rows() {
    perl -ne 'print unless /$ENV{RUN_FIGURE_ROWS}/io'
}

# ANSI stripped and the version normalised, then the run figures dropped.
#
# The version banner is normalised to [VERSION] so the references survive a
# version bump. The pattern accepts the branch marker as well as the release
# number: a feature branch stamps $version_number as X.Y.Z-{issue} for the life
# of the branch (docs/process/workflow.md § Version stamping), so every
# development build carries a suffix.
#
# The TOP OVERALL MESSAGES block is not part of the layout surface these
# references freeze, so it is dropped. The drop is bounded by the run summary that closes
# the output: the skip ends on the summary's first line -- the rule above the
# Category header, two spaces in and padded on the right -- so the category
# totals, the HIGHLIGHTED row and the file/format legend stay inside the
# surface. Per tests/HARNESS-DESIGN.md an anchor that matches nothing is a
# failure: reaching end of input with the skip still open exits 3, so a
# truncated surface aborts. A run invoked with -osum prints no summary, and the
# echoed options line -- which sits under the bar graph, ahead of the skipped
# block -- says so, so such a run has nothing to close the skip and is exempt.
strip_nondeterministic() {
    perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g; s/\e\[\d*m//g; s/log timeline \[[^\]]+\]/log timeline [VERSION]/' \
    | perl -ne 'BEGIN{$skip=0; $want_summary=1} END{ $? = 3 if $skip && $want_summary } $want_summary=0 if /^(?:environment|command-line) options: / && /(?:^|\s)(?:-osum|--omit-summary)(?=\s|$)/; $skip=1 if /TOP OVERALL/; $skip=0 if /^ {2}(?:─)+ +$/; print unless $skip || /$ENV{RUN_FIGURE_ROWS}/io'
}
