#!/usr/bin/env bash
# validate-histogram-bin-counters.sh — Validate the histogram-bin-counters `-V`
# section emits the locked Decision 8 contract surface (Issues #187, #189).
# Usage: ./tests/validate-histogram-bin-counters.sh
#
# Reference implementation of the self-documenting assertion design from
# tests/HARNESS-DESIGN.md. Every assertion records:
#   - asserts:     the application invariant being tested
#   - produced_by: where in ltl the invariant is produced (function name)
#   - contract:    the stability contract that makes it stable
# All three are surfaced on failure so the reader can act without
# opening external docs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/logs-dir.sh
source "$SCRIPT_DIR/lib/logs-dir.sh"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited; issue #438).
neutralize_colour_env


# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# every assertion here reads the -V section's contract surface - which
# consumer blocks appear, their path: labels, source annotations, the
# tier -> effective_bpd table, and the telemetry field shapes ([0-9]+) -
# never a statistic, a count, or the time axis. The 5k slice (5,000 lines,
# 4-minute span, durations on every line) carries every signal, and
# `-bs 1440 -oe` keeps the timeline to the one bucket the per-time-bucket
# partition assertions need. -osum/-hst stay OFF: the summary table and the
# per-bucket statistics demand are what activate the consumers under test.
ACCESS_LOG="$LOGS_DIR/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"
SHAPE="-bs 1440 -oe"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$ACCESS_LOG" ]]; then
    echo "ERROR: ACCESS_LOG not found: $ACCESS_LOG"
    exit 1
fi

pass=0
fail=0
failures=()
current_scenario=""

# Run ltl with -V histogram-bin-counters and the standard suppression flag.
# Captures combined output to a temp file, echoes the path.
# Args after the function name are forwarded verbatim before the input file.
run_section() {
    local outfile
    outfile=$(mktemp)
    # shellcheck disable=SC2086
    "$LTL" --disable-progress -ni $SHAPE -V histogram-bin-counters "$@" "$ACCESS_LOG" > "$outfile" 2>"$outfile.stderr" || true
    echo "$outfile"
}

# Runtime-warning cleanliness for a run_section/run_pa_section capture (its
# stderr lives beside the captured stdout as <capture>.stderr). Runs in the
# main shell so the fail counters persist - a command-substitution subshell
# could not update them. HARNESS-DESIGN.md section Runtime-warning cleanliness.
check_capture_warnings() {
    local capture="$1"
    if ! assert_no_runtime_warnings "$capture.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# Self-documenting assertion: a line matching `pattern` must be present.
# Required named fields: pattern, asserts, produced_by, contract.
# On failure, all four are surfaced alongside the captured output path.
assert_line() {
    local outfile="$1"
    shift
    local pattern asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_line: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${pattern:?assert_line requires pattern}"
    : "${asserts:?assert_line requires asserts}"
    : "${produced_by:?assert_line requires produced_by}"
    : "${contract:?assert_line requires contract}"

    if grep -qE "$pattern" "$outfile"; then
        echo "  PASS  $current_scenario :: $pattern"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        pattern:     $pattern"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "        (not found in $outfile)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $pattern")
    fi
}

# Self-documenting assertion: no line matching `pattern` may be present.
# Same field requirements as assert_line.
assert_no_line() {
    local outfile="$1"
    shift
    local pattern asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_no_line: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${pattern:?assert_no_line requires pattern}"
    : "${asserts:?assert_no_line requires asserts}"
    : "${produced_by:?assert_no_line requires produced_by}"
    : "${contract:?assert_no_line requires contract}"

    if grep -qE "$pattern" "$outfile"; then
        echo "  FAIL  $current_scenario"
        echo "        pattern:     !$pattern (unexpectedly present)"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: !$pattern (unexpectedly present)")
    else
        echo "  PASS  $current_scenario :: !$pattern"
        pass=$((pass + 1))
    fi
}

# Common assertion shared by every scenario: the section header must be
# present. Per HARNESS-DESIGN.md "harnesses must fail on missing anchors",
# this guard ensures a renamed section header produces a visible failure
# rather than zero matches across the scenario's other assertions.
assert_header_present() {
    local outfile="$1"
    assert_line "$outfile" \
        pattern     '^=== histogram-bin-counters ===$' \
        asserts     'The histogram-bin-counters section is emitted whenever -V histogram-bin-counters is requested, regardless of which downstream features are active' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl' \
        contract    'Issue #226 framework + features/187-histogram-bin-counter-percentiles.md section Decision 8 - section name is stability-contracted; renames are breaking'
}

# ---------------------------------------------------------------------------
# Scenario 1: default run — no precision flag
# ---------------------------------------------------------------------------
scenario_default() {
    current_scenario="default"
    echo "[$current_scenario]"
    local out
    out=$(run_section)
    check_capture_warnings "$out"

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^data_model_precision: 5 \(default\)$' \
        asserts     'With no precision flag, data_model_precision reports tier 5 (the default level in the locked tier table) with source annotation `(default)`' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block)' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 + section Decision 2 - tier 5 is the default level; source annotation form is locked'

    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario 3: --data-model-precision 7 (tier override)
# ---------------------------------------------------------------------------
scenario_precision_tier() {
    current_scenario="precision-tier"
    echo "[$current_scenario]"
    local out
    out=$(run_section --data-model-precision 7)
    check_capture_warnings "$out"

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^data_model_precision: 7 \(--data-model-precision 7\)$' \
        asserts     'When --data-model-precision N is given, data_model_precision reports N with source annotation `(--data-model-precision N)`' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block; supplied-flag branch of source annotation)' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - source annotation form is locked per branch'

    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario 4: invalid --data-model-precision warns + falls back to default
# ---------------------------------------------------------------------------
scenario_precision_out_of_range() {
    current_scenario="precision-out-of-range"
    echo "[$current_scenario]"
    local out
    out=$(run_section --data-model-precision 12)
    check_capture_warnings "$out"

    assert_header_present "$out"

    # The intentional out-of-range diagnostic is printed to stderr, so the
    # assertion reads the stderr capture (runtime-warning split, issue #341).
    assert_line "$out.stderr" \
        pattern     'Invalid --data-model-precision: 12 \(must be 1\.\.9\)' \
        asserts     'When --data-model-precision is outside the locked 1..9 range, ltl emits a warning to stderr naming the invalid value' \
        produced_by 'adapt_to_command_line_options() in ltl (tier range-check branch)' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 2 - valid tier range is locked at 1..9'

    assert_line "$out" \
        pattern     '^data_model_precision: 5 \(default\)$' \
        asserts     'When the tier is out of range, data_model_precision falls back to the default tier 5 with source annotation reset to `(default)`' \
        produced_by 'adapt_to_command_line_options() in ltl (range-check fallback) + emit_bin_counter_mode_verbose() (source annotation)' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 2 - fallback to default is locked behavior'

    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario T: the per-surface tier table (Issue #293). The single precision
# tier resolves each bin-counter surface's effective_bpd; this asserts the
# table cells end-to-end via -V percentile-algorithm. message-stats and
# bucket-stats are pinned to the bin model so their effective_bpd is emitted
# (the raw nearest-rank path has no bin resolution). Histogram and heatmap are
# bin by default. Expected cells per surface row:
#   tier 1 -> histogram 53,  heatmap 53,  bucket-stats 16,  message-stats 4
#   tier 5 -> histogram 616, heatmap 616, bucket-stats 53,  message-stats 53
#   tier 7 -> histogram 616, heatmap 616, bucket-stats 616, message-stats 115
#   tier 9 -> histogram 616, heatmap 616, bucket-stats 616, message-stats 616
# ---------------------------------------------------------------------------
run_pa_section() {
    # Capture -V percentile-algorithm with all four surfaces on the bin model.
    local outfile
    outfile=$(mktemp)
    # shellcheck disable=SC2086
    "$LTL" --disable-progress -ni $SHAPE -V percentile-algorithm -hg -hm \
        -mdm bin -bdm bin "$@" "$ACCESS_LOG" > "$outfile" 2>"$outfile.stderr" || true
    echo "$outfile"
}

# Assert one surface's effective_bpd within its percentile-algorithm block.
assert_surface_bpd() {
    local outfile="$1" surface="$2" expected="$3"
    local actual
    actual=$(sed -nE "/^=== percentile-algorithm \/ ${surface} ===$/,/^=== END percentile-algorithm \/ ${surface} ===$/p" "$outfile" \
        | sed -nE 's/^effective_bpd: ([0-9]+)$/\1/p' | head -1)
    if [[ "$actual" == "$expected" ]]; then
        echo "  PASS  $current_scenario :: ${surface} effective_bpd=$expected"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        surface:     $surface"
        echo "        expected:    effective_bpd=$expected"
        echo "        actual:      effective_bpd=${actual:-<absent>}"
        echo "        asserts:     The precision tier resolves this surface to its locked per-surface bpd via %TIER_BPD."
        echo "        produced_by: bpd_for_surface() in ltl -> per-surface globals -> @surfaces array in emit_percentile_algorithm_verbose()"
        echo "        contract:    features/293-precision-lever-unification.md (per-surface tier table) + features/187 section Decision 2"
        fail=$((fail + 1))
        failures+=("$current_scenario :: ${surface} effective_bpd expected=$expected got=${actual:-<absent>}")
    fi
}

scenario_tier_table() {
    current_scenario="tier-table"
    echo "[$current_scenario]"
    local out tier cells hg hm bs ms
    # Each row: "histogram heatmap bucket-stats message-stats" for the tier.
    for tier in 1 5 7 9; do
        case "$tier" in
            1) cells="53 53 16 4" ;;
            5) cells="616 616 53 53" ;;
            7) cells="616 616 616 115" ;;
            9) cells="616 616 616 616" ;;
        esac
        read -r hg hm bs ms <<< "$cells"
        out=$(run_pa_section --data-model-precision "$tier")
        check_capture_warnings "$out"
        current_scenario="tier-table[dmp=$tier]"
        assert_surface_bpd "$out" histogram     "$hg"
        assert_surface_bpd "$out" heatmap       "$hm"
        assert_surface_bpd "$out" bucket-stats  "$bs"
        assert_surface_bpd "$out" message-stats "$ms"
        rm -f "$out" "$out.stderr"
    done
    current_scenario="tier-table"
}

# ---------------------------------------------------------------------------
# Scenario 7a (Issue #287): -mdm bin engages the per-message-key bin path.
# Asserts summary_table consumer block emits path: unified + all locked
# Decision 8 telemetry fields populated from the real partition state, and
# csv_output is feature_not_active because -o is not supplied.
# ---------------------------------------------------------------------------
scenario_message_stats_bin() {
    current_scenario="message-stats-bin"
    echo "[$current_scenario]"
    local out
    out=$(run_section -mdm bin -n 3)
    check_capture_warnings "$out"

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^consumer: summary_table$' \
        asserts     'The summary_table consumer block is emitted in the -V histogram-bin-counters output under -mdm bin (per Issue #287 Commit 4 - summary_table was added to %migrated alongside #34s heatmap_cells/markers and histogram_view/bins).' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - the @consumer_order iteration emits one consumer: block per migrated consumer' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - consumer name string is locked; renames are breaking. features/287-message-stats-bin-counter-data-model.md section R8.1.'

    assert_line "$out" \
        pattern     '^  path: unified$' \
        asserts     'Under -mdm bin (no opt-outs), the summary_table consumer reports path: unified - the bin-counter path is running end-to-end on the per-message-key statistics surface.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - path determined by %migrated AND not opted out' \
        contract    'features/187-histogram-bin-counter-percentiles.md section R10 path vocabulary - unified is the post-migration label.'

    assert_line "$out" \
        pattern     '^  partition_keying: \(category, log_key\)$' \
        asserts     'summary_tables partition keying is (category, log_key), distinct from time_bucket and metric_global. This is the F1 keying shape per #189 R3.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - %partition_keying lookup' \
        contract    'features/189-histogram-bin-counter-primitives.md section R3 - keying shape per consumer is locked; features/287 section R8.1 sets summary_tables shape.'

    assert_line "$out" \
        pattern     '^  partition_count: [1-9][0-9]*$' \
        asserts     'partition_count reports a positive integer - at least one (category, log_key) had a duration sample that triggered counter_update and lazily allocated a partition.' \
        produced_by 'snapshot_counter_telemetry() in ltl, invoked from finalize_message_stats_unified()' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - partition_count field is locked; format is integer.'

    assert_line "$out" \
        pattern     '^  rebin_growth_events: [0-9]+$' \
        asserts     'rebin_growth_events counts one mechanism only - a partition outgrowing its range and doubling. It is carried on the store entry, not the partition, so a combination that replaces the partition adds to it rather than resetting it.' \
        produced_by 'snapshot_counter_telemetry() in ltl, summing $entry->{rebin_growth}' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - re-binning is reported per mechanism; no summed figure is reported.'

    assert_line "$out" \
        pattern     '^  rebin_merge_events: [0-9]+$' \
        asserts     'rebin_merge_events counts each projection onto a union geometry performed while combining two histograms - zero, one or two per combination, since a side already congruent with the union is not projected.' \
        produced_by 'merge_bin_counter_entries() in ltl, accumulated on the target entry and summed by snapshot_counter_telemetry()' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - re-binning is reported per mechanism.'

    assert_line "$out" \
        pattern     '^  rebin_finalize_events: [0-9]+$' \
        asserts     'rebin_finalize_events on summary_table counts the collapse of a consolidated row: every member histogram absorbed into a cluster is projected into one union geometry exactly once when that cluster is finalized (#459). Zero on a run with no consolidation; a positive count otherwise. It is NOT a display-shape projection - summary_table has no display geometry.' \
        produced_by 'finalize_message_stats_unified() in ltl - initialised to 0 by snapshot_counter_telemetry(), incremented only by the finalizers that project' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - re-binning is reported per mechanism.'

    assert_line "$out" \
        pattern     '^  max_partition_bins: [0-9]+$' \
        asserts     'max_partition_bins is present and a non-negative integer - the high-water-mark bin count across all partitions for this consumer (#187 Decision 5 telemetry).' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - max_partition_bins is locked.'

    assert_line "$out" \
        pattern     '^  partitions_with_overflow_count: [0-9]+$' \
        asserts     'partitions_with_overflow_count reports the count of partitions where the overflow counter was non-zero (per #187 Decision 4 / #189 R6). Zero on the test log; non-zero is the audit signal.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 + section Decision 4 - overflow tally is the audit surface; field name and integer format are locked.'

    assert_line "$out" \
        pattern     '^  partitions_with_underflow_count: [0-9]+$' \
        asserts     'partitions_with_underflow_count reports the symmetric tally for underflow per #187 Decision 4. Zero on the test log; non-zero is the audit signal.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 + section Decision 4 - underflow tally is the audit surface.'

    assert_line "$out" \
        pattern     '^  overflow_total: [0-9]+$' \
        asserts     'overflow_total is the summed overflow count across partitions - a guard expected to read zero, kept visible so that if it ever fires it can be investigated.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 + section Decision 4 - the out-of-range counters are safety instrumentation, not an audit signal expected to go non-zero.'

    assert_line "$out" \
        pattern     '^  underflow_total: [0-9]+$' \
        asserts     'underflow_total is the symmetric summed underflow count - likewise a guard expected to read zero.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 + section Decision 4 - the out-of-range counters are safety instrumentation.'

    assert_line "$out" \
        pattern     '^  counter_memory_bytes: [0-9]+$' \
        asserts     'counter_memory_bytes is reproducible across runs on identical input. It reports the counters payload - partition geometry plus the bin slots spanned - not a measurement of the live structure, whose allocation depends on growth history and moves between runs while no observation changes.' \
        produced_by 'counter_store_bytes() in ltl via snapshot_counter_telemetry()' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - counter_memory_bytes is locked; format is bare bytes.'

    assert_line "$out" \
        pattern     '^  members_live: [1-9][0-9]*$' \
        asserts     'members_live counts the member histograms alive across combined keys. It is conserved under consolidation - folding keys into clusters lowers partition_count but not members_live - so it is positive whenever any partition exists.' \
        produced_by 'snapshot_counter_telemetry() in ltl, summing $entry->{members}' \
        contract    'features/bin-counter-accuracy-and-observability.md section D4 - member-histogram retention across combined keys is observable.'

    assert_line "$out" \
        pattern     '^  members_max: [1-9][0-9]*$' \
        asserts     'members_max is the largest membership reached by any single entry - at least 1, since an entry always stands for itself.' \
        produced_by 'snapshot_counter_telemetry() in ltl, high-water over $entry->{members}' \
        contract    'features/bin-counter-accuracy-and-observability.md section D4 - the maximum member count reached across the population is observable.'

    assert_line "$out" \
        pattern     '^  members_memory_bytes: [0-9]+$' \
        asserts     'members_memory_bytes is the footprint of the member histograms the store stands for. On summary_table it is the live store plus the payload of every member retained until its cluster collapsed, so it is a high-water figure that diverges from counter_memory_bytes whenever consolidation retained anything, and equals it otherwise (#459).' \
        produced_by 'counter_store_bytes() in ltl via snapshot_counter_telemetry()' \
        contract    'features/bin-counter-accuracy-and-observability.md section D4 - the member-histogram footprint is observable.'

    assert_line "$out" \
        pattern     '^  members_per_partition: p50=[0-9]+ p95=[0-9]+ p99=[0-9]+ max=[0-9]+$' \
        asserts     'members_per_partition reports how many member histograms each surviving partition stands for, in the same four-field format as rebins_per_partition. It is the figure a retention ceiling would be sized from: members_live and members_max cannot say between them whether the retained load is spread across partitions or concentrated in one, and on real logs it is heavily concentrated (#459).' \
        produced_by 'snapshot_counter_telemetry() in ltl, over $entry->{members}' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - field added 2026-08-27 by #459; four-field format matches rebins_per_partition.'

    assert_line "$out" \
        pattern     '^  rebins_per_partition: p50=[0-9]+ p95=[0-9]+ p99=[0-9]+ max=[0-9]+$' \
        asserts     'rebins_per_partition reports the percentile distribution of per-partition rebin counts in the locked four-field format (p50, p95, p99, max). The seed-heuristic tuning signal per #187 Decision 5.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 5 + section Decision 8 - telemetry field name and four-quartile format are locked.'

    assert_line "$out" \
        pattern     '^  percentiles_emitted: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999$' \
        asserts     'summary_table emits the 12-quantile ladder per #187 R3 for this surface. Order is fixed: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - %percentile_set{summary_table}' \
        contract    'features/187-histogram-bin-counter-percentiles.md section R3 - per-consumer percentile set is locked; features/287 section R8.1 sets summary_tables ladder.'

    assert_line "$out" \
        pattern     '^  out_of_range_bounded: p1=(none|low|high)' \
        asserts     'out_of_range_bounded emits per-quantile audit code (none|low|high) per #187 Decision 4. Pattern checks at least p1 is reported; subsequent quantiles follow the same triple.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - reads $t->{out_of_range_bounded} populated by finalize_message_stats_unified()' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 4 + section Decision 8 - per-quantile audit code triple is locked.'

    assert_line "$out" \
        pattern     '^consumer: csv_output$' \
        asserts     'csv_output consumer block is emitted in the -V histogram-bin-counters output. Without -o, csv_output reports feature_not_active; with -o, it reports the shared-partition short form.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - @consumer_order iteration' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - csv_output consumer is locked.'

    assert_line "$out" \
        pattern     '^  path: feature_not_active$' \
        asserts     'Without -o, csv_output reports path: feature_not_active. csv_output is gated on $write_messages_to_csv (the -o flag); when not active, no telemetry block is emitted.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - %feature_active map' \
        contract    'features/187-histogram-bin-counter-percentiles.md section R10 - feature_not_active is the no-op label.'

    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario 7b (Issue #287): -mdm bin -o engages both summary_table and
# csv_output. csv_output is the downstream consumer sharing summary_tables
# partition store per #189 R7. Assert the shares_partitions_with short-form
# block is emitted correctly.
# ---------------------------------------------------------------------------
scenario_message_stats_csv_shared() {
    current_scenario="message-stats-csv-shared"
    echo "[$current_scenario]"
    local out
    out=$(run_section -mdm bin -n 3 -o)
    check_capture_warnings "$out"

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^consumer: csv_output$' \
        asserts     'csv_output consumer block is emitted under -mdm bin -o.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8'

    assert_line "$out" \
        pattern     '^  shares_partitions_with: summary_table$' \
        asserts     'Under -mdm bin -o, csv_output reports the locked shares_partitions_with short-form block, declaring that csv_output reads percentile values from the same per-key partition that summary_table populates (no duplicate store).' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - %shares_with map carrying csv_output => summary_table' \
        contract    'features/189-histogram-bin-counter-primitives.md section R7 - shared partitions across consumers; features/187 section Decision 8 - locked short-form block; features/287 section R8.1.'

    # Cleanup: -o leaves CSV files in the cwd
    rm -f *MESSAGES-*.csv *STATS-*.csv 2>/dev/null || true
    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario 7c (Issue #287): -mdm raw routes summary_table through user_opt_out
# even though the consumer is migrated, because the user explicitly pinned raw
# on this surface. The default (no -mdm) also routes through user_opt_out
# because default is raw on this surface.
# ---------------------------------------------------------------------------
scenario_message_stats_raw() {
    current_scenario="message-stats-raw"
    echo "[$current_scenario]"
    local out
    out=$(run_section -mdm raw -n 3)
    check_capture_warnings "$out"

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^consumer: summary_table$' \
        asserts     'summary_table consumer block is emitted even under -mdm raw - the consumer is migrated; the path label distinguishes engaged-vs-opt-out.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8'

    assert_line "$out" \
        pattern     '^  path: user_opt_out$' \
        asserts     'Under -mdm raw, summary_table reports path: user_opt_out - the user pinned the raw data model on this surface, so the sort-based statistics path runs and no bin counters are kept. No telemetry block follows.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - %consumer_opted_out_to_raw map (Issue #287 Commit 4)' \
        contract    'features/187-histogram-bin-counter-percentiles.md section R10 path vocabulary - user_opt_out is the migrated-but-pinned-raw label.'

    assert_no_line "$out" \
        pattern     '^  partition_count:' \
        asserts     'Under -mdm raw, no telemetry block follows path: user_opt_out - counter store is empty (producer never fired) and emit logic short-circuits.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - next-after-path-emit short-circuit' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - opt-out blocks emit only the path: line.'

    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario 7d (Issue #289): -bdm bin engages the per-time-bucket bin path.
# Asserts the time_bucket_stats consumer block emits path: unified plus the
# locked Decision 8 telemetry fields populated from the real per-bucket
# partition state. Unlike summary_table/csv_output, time_bucket_stats has a
# DEDICATED store (it is NOT in %shares_with), so it emits the full telemetry
# block with partition_keying: time_bucket, not a shares_partitions_with
# short form. The ThingWorx access log carries duration data, so the
# per-time-bucket statistics surface is active (no -hm, no -os).
# ---------------------------------------------------------------------------
scenario_bucket_stats_bin() {
    current_scenario="bucket-stats-bin"
    echo "[$current_scenario]"
    local out
    out=$(run_section -bdm bin)
    check_capture_warnings "$out"

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^consumer: time_bucket_stats$' \
        asserts     'The time_bucket_stats consumer block is emitted under -bdm bin (per Issue #289 - time_bucket_stats was added to %migrated alongside the #34/#287 consumers).' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - the @consumer_order iteration emits one consumer: block per migrated consumer' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - consumer name string is locked; renames are breaking. features/289-bucket-stats-bin-counter-data-model.md.'

    assert_line "$out" \
        pattern     '^  path: unified$' \
        asserts     'Under -bdm bin (no opt-outs), the time_bucket_stats consumer reports path: unified - the bin-counter path is running end-to-end on the per-time-bucket statistics surface.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - path determined by %migrated AND not opted out' \
        contract    'features/187-histogram-bin-counter-percentiles.md section R10 path vocabulary - unified is the post-migration label.'

    assert_line "$out" \
        pattern     '^  partition_keying: time_bucket$' \
        asserts     'time_bucket_stats partition keying is time_bucket - one partition per time bucket, the same keying #34 uses for heatmap_cells/markers. Distinct from (category, log_key) and metric_global.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - %partition_keying lookup' \
        contract    'features/189-histogram-bin-counter-primitives.md section R3 - keying shape per consumer is locked; features/289 sets time_bucket_stats shape.'

    assert_line "$out" \
        pattern     '^  partition_count: [1-9][0-9]*$' \
        asserts     'partition_count reports a positive integer - at least one time bucket had a duration sample that triggered counter_update and lazily allocated a partition.' \
        produced_by 'snapshot_counter_telemetry() in ltl, invoked from finalize_bucket_stats_unified()' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - partition_count field is locked; format is integer.'

    assert_line "$out" \
        pattern     '^  rebin_growth_events: [0-9]+$' \
        asserts     'rebin_growth_events counts one mechanism only - a partition outgrowing its range and doubling. It is carried on the store entry, not the partition, so a combination that replaces the partition adds to it rather than resetting it.' \
        produced_by 'snapshot_counter_telemetry() in ltl, summing $entry->{rebin_growth}' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - re-binning is reported per mechanism; no summed figure is reported.'

    assert_line "$out" \
        pattern     '^  rebin_merge_events: [0-9]+$' \
        asserts     'rebin_merge_events counts each projection onto a union geometry performed while combining two histograms - zero, one or two per combination, since a side already congruent with the union is not projected.' \
        produced_by 'merge_bin_counter_entries() in ltl, accumulated on the target entry and summed by snapshot_counter_telemetry()' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - re-binning is reported per mechanism.'

    assert_line "$out" \
        pattern     '^  rebin_finalize_events: 0$' \
        asserts     'rebin_finalize_events counts projections into display shape, and is asserted as exactly zero for time_bucket_stats, whose dedicated store is read directly by the percentile path and never projected into display shape.' \
        produced_by 'finalize_bucket_stats_unified() in ltl - initialised to 0 by snapshot_counter_telemetry(), incremented only by the finalizers that project' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - re-binning is reported per mechanism.'

    assert_line "$out" \
        pattern     '^  max_partition_bins: [0-9]+$' \
        asserts     'max_partition_bins is present and a non-negative integer - the high-water-mark bin count across all per-bucket partitions (#187 Decision 5 telemetry).' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - max_partition_bins is locked.'

    assert_line "$out" \
        pattern     '^  partitions_with_overflow_count: [0-9]+$' \
        asserts     'partitions_with_overflow_count reports the count of per-bucket partitions where the overflow counter was non-zero (per #187 Decision 4 / #189 R6).' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 + section Decision 4 - overflow tally is the audit surface; field name and integer format are locked.'

    assert_line "$out" \
        pattern     '^  partitions_with_underflow_count: [0-9]+$' \
        asserts     'partitions_with_underflow_count reports the symmetric per-bucket underflow tally per #187 Decision 4.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 + section Decision 4 - underflow tally is the audit surface.'

    assert_line "$out" \
        pattern     '^  overflow_total: [0-9]+$' \
        asserts     'overflow_total is the summed overflow count across partitions - a guard expected to read zero, kept visible so that if it ever fires it can be investigated.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 + section Decision 4 - the out-of-range counters are safety instrumentation, not an audit signal expected to go non-zero.'

    assert_line "$out" \
        pattern     '^  underflow_total: [0-9]+$' \
        asserts     'underflow_total is the symmetric summed underflow count - likewise a guard expected to read zero.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 + section Decision 4 - the out-of-range counters are safety instrumentation.'

    assert_line "$out" \
        pattern     '^  counter_memory_bytes: [0-9]+$' \
        asserts     'counter_memory_bytes is reproducible across runs on identical input. It reports the counters payload - partition geometry plus the bin slots spanned - not a measurement of the live structure, whose allocation depends on growth history and moves between runs while no observation changes.' \
        produced_by 'counter_store_bytes() in ltl via snapshot_counter_telemetry()' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - counter_memory_bytes is locked; format is bare bytes.'

    assert_line "$out" \
        pattern     '^  members_live: [1-9][0-9]*$' \
        asserts     'members_live counts the member histograms alive across combined keys. It is conserved under consolidation - folding keys into clusters lowers partition_count but not members_live - so it is positive whenever any partition exists.' \
        produced_by 'snapshot_counter_telemetry() in ltl, summing $entry->{members}' \
        contract    'features/bin-counter-accuracy-and-observability.md section D4 - member-histogram retention across combined keys is observable.'

    assert_line "$out" \
        pattern     '^  members_max: [1-9][0-9]*$' \
        asserts     'members_max is the largest membership reached by any single entry - at least 1, since an entry always stands for itself.' \
        produced_by 'snapshot_counter_telemetry() in ltl, high-water over $entry->{members}' \
        contract    'features/bin-counter-accuracy-and-observability.md section D4 - the maximum member count reached across the population is observable.'

    assert_line "$out" \
        pattern     '^  members_memory_bytes: [0-9]+$' \
        asserts     'members_memory_bytes is the footprint of the retained member histograms. It equals counter_memory_bytes while combination still collapses members into one histogram; the two diverge once members are retained.' \
        produced_by 'counter_store_bytes() in ltl via snapshot_counter_telemetry()' \
        contract    'features/bin-counter-accuracy-and-observability.md section D4 - the member-histogram footprint is observable.'

    assert_line "$out" \
        pattern     '^  members_per_partition: p50=[0-9]+ p95=[0-9]+ p99=[0-9]+ max=[0-9]+$' \
        asserts     'members_per_partition reports how many member histograms each surviving partition stands for, in the same four-field format as rebins_per_partition. It is the figure a retention ceiling would be sized from: members_live and members_max cannot say between them whether the retained load is spread across partitions or concentrated in one, and on real logs it is heavily concentrated (#459).' \
        produced_by 'snapshot_counter_telemetry() in ltl, over $entry->{members}' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8 - field added 2026-08-27 by #459; four-field format matches rebins_per_partition.'

    assert_line "$out" \
        pattern     '^  rebins_per_partition: p50=[0-9]+ p95=[0-9]+ p99=[0-9]+ max=[0-9]+$' \
        asserts     'rebins_per_partition reports the percentile distribution of per-partition rebin counts in the locked four-field format (p50, p95, p99, max).' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 5 + section Decision 8 - telemetry field name and four-quartile format are locked.'

    assert_line "$out" \
        pattern     '^  percentiles_emitted: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999$' \
        asserts     'time_bucket_stats emits the 12-quantile ladder per #187 R3 for this surface. Order is fixed: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - %percentile_set{time_bucket_stats}' \
        contract    'features/187-histogram-bin-counter-percentiles.md section R3 - per-consumer percentile set is locked; features/289 sets time_bucket_stats ladder.'

    assert_line "$out" \
        pattern     '^  out_of_range_bounded: p1=(none|low|high)' \
        asserts     'out_of_range_bounded emits per-quantile audit code (none|low|high) per #187 Decision 4. Pattern checks at least p1 is reported; subsequent quantiles follow the same triple.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - reads $t->{out_of_range_bounded} populated by finalize_bucket_stats_unified() from %bucket_stats_audit' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 4 + section Decision 8 - per-quantile audit code triple is locked.'

    assert_no_line "$out" \
        pattern     '^  shares_partitions_with: ' \
        asserts     'time_bucket_stats has a DEDICATED counter store (not in %shares_with), so it emits the full telemetry block - never a shares_partitions_with short form. Inverting the heatmap sharing is a separate follow-up.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - %shares_with map has no time_bucket_stats entry' \
        contract    'features/289-bucket-stats-bin-counter-data-model.md section dedicated-store decision (divergence 2).'

    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario 7e (Issue #289): -bdm raw routes time_bucket_stats through
# user_opt_out even though the consumer is migrated, because the user pinned
# raw on this surface (also the default). No telemetry block follows.
# ---------------------------------------------------------------------------
scenario_bucket_stats_raw() {
    current_scenario="bucket-stats-raw"
    echo "[$current_scenario]"
    local out
    out=$(run_section -bdm raw)
    check_capture_warnings "$out"

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^consumer: time_bucket_stats$' \
        asserts     'time_bucket_stats consumer block is emitted even under -bdm raw - the consumer is migrated; the path label distinguishes engaged-vs-opt-out.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md section Decision 8'

    assert_line "$out" \
        pattern     '^  path: user_opt_out$' \
        asserts     'Under -bdm raw, time_bucket_stats reports path: user_opt_out - the user pinned the raw data model on this surface, so the sort-based statistics path runs and no bin counters are kept. No telemetry block follows.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl - %consumer_opted_out_to_raw map (Issue #289)' \
        contract    'features/187-histogram-bin-counter-percentiles.md section R10 path vocabulary - user_opt_out is the migrated-but-pinned-raw label.'

    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Scenario 8: section is always present under -V histogram-bin-counters
# even when no percentile-consuming feature is in use
# ---------------------------------------------------------------------------
scenario_always_present() {
    current_scenario="always-present"
    echo "[$current_scenario]"
    local out
    # Heatmap is enabled but no percentile flags; the section should still emit.
    out=$(run_section -hm duration)
    check_capture_warnings "$out"

    assert_header_present "$out"

    rm -f "$out" "$out.stderr"
}

# ---------------------------------------------------------------------------
# Run all scenarios
# ---------------------------------------------------------------------------

echo "Validating histogram-bin-counters -V section (Issues #189, #187, #226)"
echo ""

scenario_default
echo ""
scenario_precision_tier
echo ""
scenario_precision_out_of_range
echo ""
scenario_tier_table
echo ""
scenario_message_stats_bin
echo ""
scenario_message_stats_csv_shared
echo ""
scenario_message_stats_raw
echo ""
scenario_bucket_stats_bin
echo ""
scenario_bucket_stats_raw
echo ""
scenario_always_present

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL HISTOGRAM-BIN-COUNTERS TESTS PASSED"
