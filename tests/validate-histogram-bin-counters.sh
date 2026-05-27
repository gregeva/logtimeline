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
LTL="$REPO_DIR/ltl"
ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt"

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
    "$LTL" --disable-progress -V histogram-bin-counters "$@" "$ACCESS_LOG" > "$outfile" 2>&1 || true
    echo "$outfile"
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
        contract    'Issue #226 framework + features/187-histogram-bin-counter-percentiles.md § Decision 8 — section name is stability-contracted; renames are breaking'
}

# ---------------------------------------------------------------------------
# Scenario 1: default run — no percentile-mode flags
# ---------------------------------------------------------------------------
scenario_default() {
    current_scenario="default"
    echo "[$current_scenario]"
    local out
    out=$(run_section)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^percentile_precision: 5 \(default\)$' \
        asserts     'With no precision flags, percentile_precision reports tier 5 (the default level in the locked tier table) with source annotation `(default)`' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 + § Decision 2 — tier 5 is the default level; source annotation form is locked'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 53 \(default\)$' \
        asserts     'With no precision flags, buckets_per_decade reports the default 53 (the bpd corresponding to tier 5) with source annotation `(default)`' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 + § Decision 2 — tier 5 → bpd 53 is locked'

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 3: --percentile-precision 7 (tier override)
# ---------------------------------------------------------------------------
scenario_precision_tier() {
    current_scenario="precision-tier"
    echo "[$current_scenario]"
    local out
    out=$(run_section --percentile-precision 7)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^percentile_precision: 7 \(--percentile-precision 7\)$' \
        asserts     'When --percentile-precision N is given without -pbpd, percentile_precision reports N with source annotation `(--percentile-precision N)`' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block; --percentile-precision branch of source annotation)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — source annotation form is locked per branch'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 115 \(--percentile-precision 7\)$' \
        asserts     'When --percentile-precision 7 resolves through the tier table, buckets_per_decade reports 115 (the bpd for tier 7) with matching source annotation' \
        produced_by 'adapt_to_command_line_options() in ltl (tier table %level_to_bpd) + emit_bin_counter_mode_verbose() (source annotation)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 2 — tier 7 → bpd 115 is locked'

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 4: -pbpd 100 (non-tier value -> literal `n/a` per audit A5)
# ---------------------------------------------------------------------------
scenario_pbpd_non_tier() {
    current_scenario="pbpd-non-tier"
    echo "[$current_scenario]"
    local out
    out=$(run_section -pbpd 100)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^percentile_precision: n/a \(-pbpd 100\)$' \
        asserts     'When -pbpd resolves to a value with no tier-table match, percentile_precision reports the literal string `n/a` (not an integer) with source annotation reflecting the -pbpd source' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block; bpd-without-tier-match branch)' \
        contract    'features/189-percentile-mode-audit.md § Bucket A § A5 — literal `n/a` rendering for non-tier bpd values is locked'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 100 \(-pbpd 100\)$' \
        asserts     'When -pbpd N is given, buckets_per_decade reports N with source annotation `(-pbpd N)`' \
        produced_by 'adapt_to_command_line_options() in ltl (-pbpd branch) + emit_bin_counter_mode_verbose() (source annotation)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — source annotation form is locked'

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 5: -pbpd + --percentile-precision conflict (-pbpd wins)
# ---------------------------------------------------------------------------
scenario_flag_conflict() {
    current_scenario="flag-conflict"
    echo "[$current_scenario]"
    local out
    out=$(run_section -pbpd 100 --percentile-precision 4)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^percentile_precision: 4 \(--percentile-precision 4; overridden\)$' \
        asserts     'When both -pbpd and --percentile-precision are given, percentile_precision reports the *requested* level from --percentile-precision with `; overridden` suffix indicating -pbpd won' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl (run-level header block; conflict branch of $level_source)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — conflict annotation form is locked'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 100 \(-pbpd 100; --percentile-precision 4 overridden\)$' \
        asserts     'When both flags conflict, buckets_per_decade reports the *active* bpd from -pbpd with full conflict annotation showing both flags and which one was overridden' \
        produced_by 'adapt_to_command_line_options() in ltl ($percentile_precision_source assembly)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — full conflict annotation is locked'

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario 6: invalid -pbpd value warns + falls back to default
# ---------------------------------------------------------------------------
scenario_pbpd_out_of_range() {
    current_scenario="pbpd-out-of-range"
    echo "[$current_scenario]"
    local out
    out=$(run_section -pbpd 9999)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     'Invalid -pbpd: 9999' \
        asserts     'When -pbpd is outside the locked 4..616 range, ltl emits a warning to stderr naming the invalid value' \
        produced_by 'adapt_to_command_line_options() in ltl (-pbpd range-check branch)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 2 — valid range is locked at 4..616'

    assert_line "$out" \
        pattern     '^percentile_precision: 5 \(default\)$' \
        asserts     'When -pbpd is out of range, percentile_precision falls back to the default tier 5 (not the invalid value)' \
        produced_by 'adapt_to_command_line_options() in ltl (range-check fallback) + emit_bin_counter_mode_verbose() (source annotation)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 2 — fallback to default is locked behavior'

    assert_line "$out" \
        pattern     '^buckets_per_decade: 53 \(default\)$' \
        asserts     'When -pbpd is out of range, buckets_per_decade falls back to 53 with source annotation reset to `(default)`' \
        produced_by 'adapt_to_command_line_options() in ltl (range-check fallback resets $percentile_precision_source to "default")' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 2 — fallback resets source annotation'

    rm -f "$out"
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

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^consumer: summary_table$' \
        asserts     'The summary_table consumer block is emitted in the -V histogram-bin-counters output under -mdm bin (per Issue #287 Commit 4 — summary_table was added to %migrated alongside #34s heatmap_cells/markers and histogram_view/bins).' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — the @consumer_order iteration emits one consumer: block per migrated consumer' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — consumer name string is locked; renames are breaking. features/287-message-stats-bin-counter-data-model.md § R8.1.'

    assert_line "$out" \
        pattern     '^  path: unified$' \
        asserts     'Under -mdm bin (no opt-outs), the summary_table consumer reports path: unified — the bin-counter path is running end-to-end on the per-message-key statistics surface.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — path determined by %migrated AND not opted out' \
        contract    'features/187-histogram-bin-counter-percentiles.md § R10 path vocabulary — unified is the post-migration label.'

    assert_line "$out" \
        pattern     '^  partition_keying: \(category, log_key\)$' \
        asserts     'summary_tables partition keying is (category, log_key), distinct from time_bucket and metric_global. This is the F1 keying shape per #189 R3.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — %partition_keying lookup' \
        contract    'features/189-histogram-bin-counter-primitives.md § R3 — keying shape per consumer is locked; features/287 § R8.1 sets summary_tables shape.'

    assert_line "$out" \
        pattern     '^  partition_count: [1-9][0-9]*$' \
        asserts     'partition_count reports a positive integer — at least one (category, log_key) had a duration sample that triggered counter_update and lazily allocated a partition.' \
        produced_by 'snapshot_counter_telemetry() in ltl, invoked from finalize_message_stats_unified()' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — partition_count field is locked; format is integer.'

    assert_line "$out" \
        pattern     '^  total_rebin_events: [0-9]+$' \
        asserts     'total_rebin_events is present and a non-negative integer — the auto-resize lifecycle has either fired zero or more rebins across all partitions.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — total_rebin_events field is locked; format is integer.'

    assert_line "$out" \
        pattern     '^  max_partition_bins: [0-9]+$' \
        asserts     'max_partition_bins is present and a non-negative integer — the high-water-mark bin count across all partitions for this consumer (#187 Decision 5 telemetry).' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — max_partition_bins is locked.'

    assert_line "$out" \
        pattern     '^  partitions_with_overflow_count: [0-9]+$' \
        asserts     'partitions_with_overflow_count reports the count of partitions where the overflow counter was non-zero (per #187 Decision 4 / #189 R6). Zero on the test log; non-zero is the audit signal.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 + § Decision 4 — overflow tally is the audit surface; field name and integer format are locked.'

    assert_line "$out" \
        pattern     '^  partitions_with_underflow_count: [0-9]+$' \
        asserts     'partitions_with_underflow_count reports the symmetric tally for underflow per #187 Decision 4. Zero on the test log; non-zero is the audit signal.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 + § Decision 4 — underflow tally is the audit surface.'

    assert_line "$out" \
        pattern     '^  counter_memory_bytes: [0-9]+$' \
        asserts     'counter_memory_bytes is present and a non-negative integer — the Devel::Size measurement of the counter store carrying the empirical-tuning signal for partition-count vs memory.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — counter_memory_bytes is locked.'

    assert_line "$out" \
        pattern     '^  rebins_per_partition: p50=[0-9]+ p95=[0-9]+ p99=[0-9]+ max=[0-9]+$' \
        asserts     'rebins_per_partition reports the percentile distribution of per-partition rebin counts in the locked four-field format (p50, p95, p99, max). The seed-heuristic tuning signal per #187 Decision 5.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 5 + § Decision 8 — telemetry field name and four-quartile format are locked.'

    assert_line "$out" \
        pattern     '^  percentiles_emitted: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999$' \
        asserts     'summary_table emits the 12-quantile ladder per #187 R3 for this surface. Order is fixed: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — %percentile_set{summary_table}' \
        contract    'features/187-histogram-bin-counter-percentiles.md § R3 — per-consumer percentile set is locked; features/287 § R8.1 sets summary_tables ladder.'

    assert_line "$out" \
        pattern     '^  out_of_range_bounded: p1=(none|low|high)' \
        asserts     'out_of_range_bounded emits per-quantile audit code (none|low|high) per #187 Decision 4. Pattern checks at least p1 is reported; subsequent quantiles follow the same triple.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — reads $t->{out_of_range_bounded} populated by finalize_message_stats_unified()' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 4 + § Decision 8 — per-quantile audit code triple is locked.'

    assert_line "$out" \
        pattern     '^consumer: csv_output$' \
        asserts     'csv_output consumer block is emitted in the -V histogram-bin-counters output. Without -o, csv_output reports feature_not_active; with -o, it reports the shared-partition short form.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — @consumer_order iteration' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — csv_output consumer is locked.'

    assert_line "$out" \
        pattern     '^  path: feature_not_active$' \
        asserts     'Without -o, csv_output reports path: feature_not_active. csv_output is gated on $write_messages_to_csv (the -o flag); when not active, no telemetry block is emitted.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — %feature_active map' \
        contract    'features/187-histogram-bin-counter-percentiles.md § R10 — feature_not_active is the no-op label.'

    rm -f "$out"
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

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^consumer: csv_output$' \
        asserts     'csv_output consumer block is emitted under -mdm bin -o.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8'

    assert_line "$out" \
        pattern     '^  shares_partitions_with: summary_table$' \
        asserts     'Under -mdm bin -o, csv_output reports the locked shares_partitions_with short-form block, declaring that csv_output reads percentile values from the same per-key partition that summary_table populates (no duplicate store).' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — %shares_with map carrying csv_output => summary_table' \
        contract    'features/189-histogram-bin-counter-primitives.md § R7 — shared partitions across consumers; features/187 § Decision 8 — locked short-form block; features/287 § R8.1.'

    # Cleanup: -o leaves CSV files in the cwd
    rm -f *MESSAGES-*.csv *STATS-*.csv 2>/dev/null || true
    rm -f "$out"
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

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^consumer: summary_table$' \
        asserts     'summary_table consumer block is emitted even under -mdm raw — the consumer is migrated; the path label distinguishes engaged-vs-opt-out.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8'

    assert_line "$out" \
        pattern     '^  path: user_opt_out$' \
        asserts     'Under -mdm raw, summary_table reports path: user_opt_out — the consumer is migrated but the user pinned raw on this surface, so the pre-migration code runs. No telemetry block follows.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — %consumer_opted_out_to_raw map (Issue #287 Commit 4)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § R10 path vocabulary — user_opt_out is the migrated-but-pinned-raw label.'

    assert_no_line "$out" \
        pattern     '^  partition_count:' \
        asserts     'Under -mdm raw, no telemetry block follows path: user_opt_out — counter store is empty (producer never fired) and emit logic short-circuits.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — next-after-path-emit short-circuit' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — opt-out blocks emit only the path: line.'

    rm -f "$out"
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
    out=$(run_section -bdm bin -bs 240)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^consumer: time_bucket_stats$' \
        asserts     'The time_bucket_stats consumer block is emitted under -bdm bin (per Issue #289 — time_bucket_stats was added to %migrated alongside the #34/#287 consumers).' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — the @consumer_order iteration emits one consumer: block per migrated consumer' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — consumer name string is locked; renames are breaking. features/289-bucket-stats-bin-counter-data-model.md.'

    assert_line "$out" \
        pattern     '^  path: unified$' \
        asserts     'Under -bdm bin (no opt-outs), the time_bucket_stats consumer reports path: unified — the bin-counter path is running end-to-end on the per-time-bucket statistics surface.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — path determined by %migrated AND not opted out' \
        contract    'features/187-histogram-bin-counter-percentiles.md § R10 path vocabulary — unified is the post-migration label.'

    assert_line "$out" \
        pattern     '^  partition_keying: time_bucket$' \
        asserts     'time_bucket_stats partition keying is time_bucket — one partition per time bucket, the same keying #34 uses for heatmap_cells/markers. Distinct from (category, log_key) and metric_global.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — %partition_keying lookup' \
        contract    'features/189-histogram-bin-counter-primitives.md § R3 — keying shape per consumer is locked; features/289 sets time_bucket_stats shape.'

    assert_line "$out" \
        pattern     '^  partition_count: [1-9][0-9]*$' \
        asserts     'partition_count reports a positive integer — at least one time bucket had a duration sample that triggered counter_update and lazily allocated a partition.' \
        produced_by 'snapshot_counter_telemetry() in ltl, invoked from finalize_bucket_stats_unified()' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — partition_count field is locked; format is integer.'

    assert_line "$out" \
        pattern     '^  total_rebin_events: [0-9]+$' \
        asserts     'total_rebin_events is present and a non-negative integer — the auto-resize lifecycle has fired zero or more rebins across all per-bucket partitions.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — total_rebin_events field is locked; format is integer.'

    assert_line "$out" \
        pattern     '^  max_partition_bins: [0-9]+$' \
        asserts     'max_partition_bins is present and a non-negative integer — the high-water-mark bin count across all per-bucket partitions (#187 Decision 5 telemetry).' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — max_partition_bins is locked.'

    assert_line "$out" \
        pattern     '^  partitions_with_overflow_count: [0-9]+$' \
        asserts     'partitions_with_overflow_count reports the count of per-bucket partitions where the overflow counter was non-zero (per #187 Decision 4 / #189 R6).' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 + § Decision 4 — overflow tally is the audit surface; field name and integer format are locked.'

    assert_line "$out" \
        pattern     '^  partitions_with_underflow_count: [0-9]+$' \
        asserts     'partitions_with_underflow_count reports the symmetric per-bucket underflow tally per #187 Decision 4.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 + § Decision 4 — underflow tally is the audit surface.'

    assert_line "$out" \
        pattern     '^  counter_memory_bytes: [0-9]+$' \
        asserts     'counter_memory_bytes is present and a non-negative integer — the Devel::Size measurement of the dedicated per-time-bucket counter store.' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — counter_memory_bytes is locked.'

    assert_line "$out" \
        pattern     '^  rebins_per_partition: p50=[0-9]+ p95=[0-9]+ p99=[0-9]+ max=[0-9]+$' \
        asserts     'rebins_per_partition reports the percentile distribution of per-partition rebin counts in the locked four-field format (p50, p95, p99, max).' \
        produced_by 'snapshot_counter_telemetry() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 5 + § Decision 8 — telemetry field name and four-quartile format are locked.'

    assert_line "$out" \
        pattern     '^  percentiles_emitted: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999$' \
        asserts     'time_bucket_stats emits the 12-quantile ladder per #187 R3 for this surface. Order is fixed: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — %percentile_set{time_bucket_stats}' \
        contract    'features/187-histogram-bin-counter-percentiles.md § R3 — per-consumer percentile set is locked; features/289 sets time_bucket_stats ladder.'

    assert_line "$out" \
        pattern     '^  out_of_range_bounded: p1=(none|low|high)' \
        asserts     'out_of_range_bounded emits per-quantile audit code (none|low|high) per #187 Decision 4. Pattern checks at least p1 is reported; subsequent quantiles follow the same triple.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — reads $t->{out_of_range_bounded} populated by finalize_bucket_stats_unified() from %bucket_stats_audit' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 4 + § Decision 8 — per-quantile audit code triple is locked.'

    assert_no_line "$out" \
        pattern     '^  shares_partitions_with: ' \
        asserts     'time_bucket_stats has a DEDICATED counter store (not in %shares_with), so it emits the full telemetry block — never a shares_partitions_with short form. Inverting the heatmap sharing is a separate follow-up.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — %shares_with map has no time_bucket_stats entry' \
        contract    'features/289-bucket-stats-bin-counter-data-model.md § dedicated-store decision (divergence 2).'

    rm -f "$out"
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
    out=$(run_section -bdm raw -bs 240)

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^consumer: time_bucket_stats$' \
        asserts     'time_bucket_stats consumer block is emitted even under -bdm raw — the consumer is migrated; the path label distinguishes engaged-vs-opt-out.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl' \
        contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8'

    assert_line "$out" \
        pattern     '^  path: user_opt_out$' \
        asserts     'Under -bdm raw, time_bucket_stats reports path: user_opt_out — the consumer is migrated but the user pinned raw on this surface, so the pre-migration code runs. No telemetry block follows.' \
        produced_by 'emit_bin_counter_mode_verbose() in ltl — %consumer_opted_out_to_raw map (Issue #289)' \
        contract    'features/187-histogram-bin-counter-percentiles.md § R10 path vocabulary — user_opt_out is the migrated-but-pinned-raw label.'

    rm -f "$out"
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

    assert_header_present "$out"

    rm -f "$out"
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
scenario_pbpd_non_tier
echo ""
scenario_flag_conflict
echo ""
scenario_pbpd_out_of_range
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
