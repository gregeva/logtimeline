#!/usr/bin/env bash
# validate-udm-counting.sh — Validate the udm-counting `-V` section and the
# counting-aggregation UDM behavior it makes observable (Issue #313):
# count/distinct/ratio/rate/drate values, highlight counterparts, the
# sessions oracle, alias canonicalization, token-key extraction, rate-unit
# scaling, consolidation-merge conservation, and -mem lifecycle tracking.
#
# Follows the self-documenting assertion design from tests/HARNESS-DESIGN.md
# (reference: tests/validate-histogram-bin-counters.sh). Every assertion
# records asserts / produced_by / contract and surfaces all three on failure.
#
# Fixture: tests/fixtures/udm-counting-tokens.txt — synthetic Tomcat access
# log, 12 lines across two 1-minute buckets (epoch 1769421600 and 1769421660),
# with hand-computed expectations:
#   bucket 10:00 — 6 userId lines (alice x2, bob x2, carol x2) + 1 sessionless
#     probe; sessions AAAA../BBBB../CCCC..; "orders" URLs highlight alice x2 +
#     carol x1 (sessions A and C)
#   bucket 10:01 — 4 userId lines (dave x3, alice x1) + 1 sessionless probe;
#     sessions DDDD../AAAA../EEEE..; "orders" highlights dave x1 (session D)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
FIXTURE="$REPO_DIR/tests/fixtures/udm-counting-tokens.txt"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$FIXTURE" ]]; then
    echo "ERROR: fixture not found: $FIXTURE"
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

CONTRACT='features/user-defined-metrics.md section Counting Aggregations (Issue #313) - decisions locked 2026-07-06/2026-07-08; section content stability-contracted per tests/HARNESS-DESIGN.md'

# Run ltl with the given args against the fixture; capture combined output.
run_ltl() {
    local outfile
    outfile=$(mktemp "$TMP_DIR/out.XXXXXX")
    "$LTL" --disable-progress "$@" "$FIXTURE" > "$outfile" 2>&1 || true
    echo "$outfile"
}

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

# Self-documenting assertion for checks that are not a single line grep.
# `command` is eval'd; PASS if it exits 0. `label` names the check.
assert_command() {
    local command label asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            command)     command="$2";     shift 2 ;;
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_command: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${command:?assert_command requires command}"
    : "${label:?assert_command requires label}"
    : "${asserts:?assert_command requires asserts}"
    : "${produced_by:?assert_command requires produced_by}"
    : "${contract:?assert_command requires contract}"

    if eval "$command" > /dev/null 2>&1; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        label:       $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# Per HARNESS-DESIGN "harnesses must fail on missing anchors": every scenario
# consuming the section asserts its header first, so a renamed section fails
# visibly rather than as zero matches on the other assertions.
assert_header_present() {
    local outfile="$1"
    assert_line "$outfile" \
        pattern     '^=== udm-counting ===$' \
        asserts     'The udm-counting section is emitted whenever -V udm-counting is requested' \
        produced_by 'emit_udm_counting_verbose() in ltl' \
        contract    "$CONTRACT"
}

# ---------------------------------------------------------------------------
# Scenario: fixture-values — every counting aggregation, both buckets, plain
# and highlight, against hand-computed expectations, plus the sessions oracle.
# ---------------------------------------------------------------------------
scenario_fixture_values() {
    current_scenario="fixture-values"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl -bs 1 -h orders -V udm-counting -n 5 \
        -udm "users::distinct:userId" \
        -udm "actions::count:userId" \
        -udm "repeat::ratio:userId" \
        -udm "urate::rate:userId" \
        -udm "udrate::drate:userId" \
        -udm 'sess::distinct:/ ([0-9A-F]{32})$/')

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^bucket: 1769421600  metric: users  occurrences: 6  occurrences_hl: 3  distinct: 3  distinct_hl: 2  value: 3  value_hl: 2$' \
        asserts     'distinct counts unique extracted strings per bucket (3 users from 6 occurrences) and the highlight set counts only -h-matched lines (2 users from 3 highlighted occurrences)' \
        produced_by 'read_and_process_logs() (%udm_distinct accumulation) + calculate_all_statistics() (counting branch) in ltl' \
        contract    "$CONTRACT"

    assert_line "$out" \
        pattern     '^bucket: 1769421600  metric: actions  .*  value: 6  value_hl: 3$' \
        asserts     'count displays the per-bucket extracted-occurrence total, with the highlight value from the -HL occurrence counter' \
        produced_by 'calculate_all_statistics() counting branch in ltl' \
        contract    "$CONTRACT"

    assert_line "$out" \
        pattern     '^bucket: 1769421600  metric: repeat  .*  value: 2  value_hl: 1\.5$' \
        asserts     'ratio is occurrences / distinct (6/3=2) and the highlight ratio computes over the highlight counterparts (3/2=1.5), not the totals' \
        produced_by 'calculate_all_statistics() counting branch in ltl' \
        contract    "$CONTRACT"

    assert_line "$out" \
        pattern     '^bucket: 1769421600  metric: urate  .*  value: 6  value_hl: 3$' \
        asserts     'rate is occurrences / bucket_size_seconds * rate multiplier (6 occurrences in a 60s bucket = 6/min at the default -ru)' \
        produced_by 'calculate_all_statistics() counting branch in ltl (reuses %rate_multiplier)' \
        contract    "$CONTRACT"

    assert_line "$out" \
        pattern     '^bucket: 1769421600  metric: udrate  .*  value: 3  value_hl: 2$' \
        asserts     'drate is distinct / bucket_size_seconds * rate multiplier (3 distinct in a 60s bucket = 3/min at the default -ru)' \
        produced_by 'calculate_all_statistics() counting branch in ltl (reuses %rate_multiplier)' \
        contract    "$CONTRACT"

    assert_line "$out" \
        pattern     '^bucket: 1769421660  metric: users  occurrences: 4  occurrences_hl: 1  distinct: 2  distinct_hl: 1  value: 2  value_hl: 1$' \
        asserts     'second bucket distinct/highlight values are independent of the first (per-bucket sets, freed after counting)' \
        produced_by 'calculate_all_statistics() counting branch in ltl (free-after-count lifecycle)' \
        contract    "$CONTRACT"

    assert_line "$out" \
        pattern     '^bucket: 1769421660  metric: repeat  .*  value: 2  value_hl: 1$' \
        asserts     'ratio in the second bucket is 4/2=2 with highlight ratio 1/1=1' \
        produced_by 'calculate_all_statistics() counting branch in ltl' \
        contract    "$CONTRACT"

    # Sessions oracle: the distinct UDM extracting the session token must agree
    # with the built-in sessions column, bucket for bucket, plain and highlight.
    # Compared value-to-value from the section rather than against frozen
    # numbers, so the oracle holds regardless of fixture edits.
    assert_command \
        command     "awk '/^bucket: [0-9]+  metric: sess  /{ sess[\$2]=\$14; sess_hl[\$2]=\$16 } /^bucket: [0-9]+  sessions: /{ ses[\$2]=\$4; ses_hl[\$2]=\$6 } END { n=0; for (b in sess) { n++; if (!(b in ses) || sess[b] != ses[b] || sess_hl[b] != ses_hl[b]) exit 1 } exit (n >= 2 ? 0 : 1) }' '$out'" \
        label       'distinct UDM on the session token equals the built-in sessions column per bucket, plain and highlight, across >= 2 buckets' \
        asserts     'A distinct-count UDM extracting the session ID reproduces the sessions column exactly (the sessions-column semantics the feature mirrors), including the -HL dimension' \
        produced_by 'read_and_process_logs() (%udm_distinct vs %log_sessions accumulation) + calculate_all_statistics() in ltl' \
        contract    "$CONTRACT"

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario: token-key-equivalence — a token-keyed metric equals the same
# metric named after the token, value for value; the name is label-only.
# ---------------------------------------------------------------------------
scenario_token_key() {
    current_scenario="token-key-equivalence"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl -bs 1 -V udm-counting -n 5 \
        -udm "who::distinct:userId" \
        -udm "userId::distinct")

    assert_header_present "$out"

    assert_command \
        command     "awk '/  metric: who  /{ who[\$2]=\$14 } /  metric: userId  /{ uid[\$2]=\$14 } END { n=0; for (b in who) { n++; if (who[b] != uid[b]) exit 1 } exit (n >= 2 ? 0 : 1) }' '$out'" \
        label       'who::distinct:userId equals userId::distinct value-for-value across >= 2 buckets' \
        asserts     'A bare fourth field is the token key: the default pattern is built from the key, so the metric name is purely a display label' \
        produced_by 'parse_udm_configs() in ltl (token_key field and default-pattern construction)' \
        contract    "$CONTRACT"

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario: rate-unit-scaling — -ru h scales rate/drate by the rate multiplier.
# ---------------------------------------------------------------------------
scenario_rate_unit() {
    current_scenario="rate-unit-scaling"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl -bs 1 -ru h -V udm-counting -n 5 \
        -udm "urate::rate:userId" \
        -udm "udrate::drate:userId")

    assert_header_present "$out"

    assert_line "$out" \
        pattern     '^bucket: 1769421600  metric: urate  .*  value: 360  ' \
        asserts     'rate honors the tool-wide -ru unit: 6 occurrences in a 60s bucket = 360/hour under -ru h' \
        produced_by 'calculate_all_statistics() counting branch in ltl (%rate_multiplier lookup)' \
        contract    "$CONTRACT"

    assert_line "$out" \
        pattern     '^bucket: 1769421600  metric: udrate  .*  value: 180  ' \
        asserts     'drate honors the tool-wide -ru unit: 3 distinct in a 60s bucket = 180/hour under -ru h' \
        produced_by 'calculate_all_statistics() counting branch in ltl (%rate_multiplier lookup)' \
        contract    "$CONTRACT"

    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario: validation-warnings — every parse-time rejection and guard.
# ---------------------------------------------------------------------------
scenario_validation_warnings() {
    current_scenario="validation-warnings"
    echo "[$current_scenario]"
    local out

    out=$(run_ltl -bs 1 -n 1 -udm "u::distinct(delta)")
    assert_line "$out" \
        pattern     "Warning: Counting aggregation 'distinct' cannot be combined with a transform" \
        asserts     'Counting aggregations combined with a transform are rejected at parse with a warning and the config is skipped' \
        produced_by 'parse_udm_configs() in ltl (counting-transform rejection branch)' \
        contract    "$CONTRACT"
    rm -f "$out"

    out=$(run_ltl -bs 1 -n 1 -udm "u:ms:distinct:userId")
    assert_line "$out" \
        pattern     "Warning: Unit 'ms' ignored for counting aggregation 'distinct'" \
        asserts     'A unit combined with a counting aggregation warns and the unit is ignored (counting operates on raw strings)' \
        produced_by 'parse_udm_configs() in ltl (counting unit guard)' \
        contract    "$CONTRACT"
    rm -f "$out"

    out=$(run_ltl -bs 1 -n 1 -udm 'u::count:key:/foo=(\d+)/')
    assert_line "$out" \
        pattern     'supplies both a token key and a /pattern/' \
        asserts     'Supplying both a token key and a /pattern/ warns and skips the config' \
        produced_by 'parse_udm_configs() in ltl (token-key/pattern conflict check)' \
        contract    "$CONTRACT"
    rm -f "$out"

    out=$(run_ltl -bs 1 -n 1 -udm "u::distinct:userId" -hm u)
    assert_line "$out" \
        pattern     "Warning: Heatmap metric 'u' uses counting aggregation 'distinct'" \
        asserts     '-hm naming a counting UDM warns and disables the heatmap (a per-line distribution over string events is meaningless)' \
        produced_by 'adapt_to_command_line_options() in ltl (heatmap UDM metric validation)' \
        contract    "$CONTRACT"
    rm -f "$out"

    out=$(run_ltl -bs 1 -n 1 -udm "u::distinct:userId" -hg u)
    assert_line "$out" \
        pattern     "Warning: Histogram metric 'u' uses counting aggregation 'distinct'" \
        asserts     '-hg naming a counting UDM warns and skips that metric' \
        produced_by 'adapt_to_command_line_options() in ltl (histogram UDM metric validation)' \
        contract    "$CONTRACT"
    rm -f "$out"

    out=$(run_ltl -bs 1 -n 1 -udm "u::median")
    assert_line "$out" \
        pattern     'valid: sum, min, max, mean, count, distinct, ratio, rate, drate, delta, idelta' \
        asserts     'An unknown aggregation keyword lists the full valid set, including the counting keywords and canonical mean' \
        produced_by 'parse_udm_configs() in ltl (function parse fallthrough)' \
        contract    "$CONTRACT"
    rm -f "$out"
}

# ---------------------------------------------------------------------------
# Scenario: alias-canonical — avg parses as canonical mean; dcount/unique as
# distinct. Duplicate names disambiguate with the canonical keyword (#99).
# ---------------------------------------------------------------------------
scenario_alias_canonical() {
    current_scenario="alias-canonical"
    echo "[$current_scenario]"
    local out

    # dcount alias resolves to distinct: identical values to a distinct config
    out=$(run_ltl -bs 1 -V udm-counting -n 5 \
        -udm "a::dcount:userId" \
        -udm "b::unique:userId")
    assert_header_present "$out"
    assert_line "$out" \
        pattern     '^metric: a  aggregation: distinct  base_name: a$' \
        asserts     'The dcount alias is normalized to the canonical distinct keyword before parsing' \
        produced_by 'parse_udm_configs() in ltl (%udm_agg_aliases normalization)' \
        contract    "$CONTRACT"
    assert_line "$out" \
        pattern     '^metric: b  aggregation: distinct  base_name: b$' \
        asserts     'The unique alias is normalized to the canonical distinct keyword before parsing' \
        produced_by 'parse_udm_configs() in ltl (%udm_agg_aliases normalization)' \
        contract    "$CONTRACT"
    rm -f "$out"

    # avg -> mean canonicalization on the #99 collision suffix, observed in the
    # STATS CSV header (input written with the alias, output in canonical form)
    local csvdir="$TMP_DIR/alias-csv"
    mkdir -p "$csvdir"
    ( cd "$csvdir" && "$LTL" --disable-progress -bs 1 -n 5 -o \
        -udm 'x::avg:/ (\d+\.\d+) pool/' \
        -udm 'x::max:/ (\d+\.\d+) pool/' \
        "$FIXTURE" > run.out 2>&1 || true )
    assert_command \
        command     "head -1 \"\$(ls $csvdir/*STATS*.csv)\" | grep -q 'x:mean' && head -1 \"\$(ls $csvdir/*STATS*.csv)\" | grep -qv 'x:avg'" \
        label       'duplicate x::avg + x::max produce STATS CSV column x:mean (canonical), never x:avg' \
        asserts     'avg is accepted as an input alias but the canonical aggregation value is mean, so the #99 collision suffix and CSV column use :mean' \
        produced_by 'parse_udm_configs() in ltl (alias normalization + #99 disambiguation)' \
        contract    "$CONTRACT"
}

# ---------------------------------------------------------------------------
# Scenario: csv-columns — counting UDM CSV shape: {base_name}_{agg} single
# value columns in STATS; MESSAGES count populated, distinct-derived blank.
# ---------------------------------------------------------------------------
scenario_csv_columns() {
    current_scenario="csv-columns"
    echo "[$current_scenario]"
    local csvdir="$TMP_DIR/shape-csv"
    mkdir -p "$csvdir"
    ( cd "$csvdir" && "$LTL" --disable-progress -bs 1 -n 5 -o \
        -udm "users::distinct:userId" \
        -udm "actions::count:userId" \
        -udm "urate::rate:userId" \
        "$FIXTURE" > run.out 2>&1 || true )

    assert_command \
        command     "head -1 \"\$(ls $csvdir/*STATS*.csv)\" | grep -q 'users_distinct' && head -1 \"\$(ls $csvdir/*STATS*.csv)\" | grep -q 'actions_count' && head -1 \"\$(ls $csvdir/*STATS*.csv)\" | grep -q 'urate_rate_min'" \
        label       'STATS CSV headers are users_distinct, actions_count, and urate_rate_min (rate carries the -ru suffix)' \
        asserts     'Counting UDMs emit a single STATS CSV value column named {base_name}_{agg}, with the -ru CSV suffix appended for rate/drate' \
        produced_by 'normalize_data_for_output() in ltl (STATS CSV column registration)' \
        contract    "$CONTRACT"

    assert_command \
        command     "python3 -c \"
import csv, glob, sys
f = glob.glob('$csvdir/*MESSAGES*.csv')[0]
rows = list(csv.reader(open(f)))
hdr = rows[0]
ci, di = hdr.index('actions_count'), hdr.index('users_distinct')
total = sum(int(r[ci]) for r in rows[1:] if r[ci])
blanks = all(r[di] == '' for r in rows[1:])
sys.exit(0 if total == 10 and blanks else 1)
\"" \
        label       'MESSAGES CSV: actions_count sums to 10 (all fixture token lines) and users_distinct is blank on every row' \
        asserts     'In the MESSAGES CSV, count carries per-message occurrences while distinct-derived aggregations are blank (distinct sets are bucket-scoped)' \
        produced_by 'print_message_summary() in ltl (MESSAGES CSV UDM value emission)' \
        contract    "$CONTRACT"
}

# ---------------------------------------------------------------------------
# Scenario: consolidation-conservation — -g merges preserve counting
# occurrences (the merge helpers must not drop configs without a _sum key).
# ---------------------------------------------------------------------------
scenario_consolidation() {
    current_scenario="consolidation-conservation"
    echo "[$current_scenario]"
    local csvdir="$TMP_DIR/consol-csv"
    mkdir -p "$csvdir"
    ( cd "$csvdir" && "$LTL" --disable-progress -bs 1 -n 100 -o -g 70 \
        -udm "actions::count:userId" \
        "$FIXTURE" > run.out 2>&1 || true )

    assert_command \
        command     "python3 -c \"
import csv, glob, sys
f = glob.glob('$csvdir/*MESSAGES*.csv')[0]
rows = list(csv.reader(open(f)))
hdr = rows[0]
ci = hdr.index('actions_count')
total = sum(int(r[ci]) for r in rows[1:] if r[ci])
sys.exit(0 if total == 10 else 1)
\"" \
        label       'under -g, MESSAGES actions_count still totals 10 - occurrences survive consolidation merges' \
        asserts     'The consolidation merge helpers carry counting-UDM occurrences through cluster merges instead of dropping configs that have no _sum key' \
        produced_by 'group_similar_messages() + merge_consolidation_stats() in ltl (agg_kind merge branches)' \
        contract    "$CONTRACT"
}

# ---------------------------------------------------------------------------
# Scenario: mem-tracking — %udm_distinct is visible in the -mem report.
# ---------------------------------------------------------------------------
scenario_mem() {
    current_scenario="mem-tracking"
    echo "[$current_scenario]"
    local out
    out=$(run_ltl -bs 1 -mem -n 1 -udm "users::distinct:userId")

    assert_line "$out" \
        pattern     'udm_distinct' \
        asserts     'The per-bucket distinct value sets are tracked in the -mem structure report' \
        produced_by 'measure_memory_structures() in ltl' \
        contract    "$CONTRACT"
    rm -f "$out"
}

# ---------------------------------------------------------------------------

scenario_fixture_values
scenario_token_key
scenario_rate_unit
scenario_validation_warnings
scenario_alias_canonical
scenario_csv_columns
scenario_consolidation
scenario_mem

echo
echo "Results: $pass passed, $fail failed"
if [[ $fail -gt 0 ]]; then
    echo "Failed assertions:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
