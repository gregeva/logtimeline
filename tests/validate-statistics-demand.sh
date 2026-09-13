#!/usr/bin/env bash
# validate-statistics-demand.sh — Validate the statistics-demand `-V` section:
# per-store statistics-group demand resolution with raising consumers, the
# per-store moment source, and the per-store statistics-calculation counters
# (stats_calls invocations plus per-group computed/skipped_demand/ineligible)
# (Issues #305, #303), and the resolution when the run retains no message at
# all (-n 0, or any non-positive count, Issue #458).
#
# Also asserts the representation of what the per-time-bucket store retains,
# read from the `MEMORY log_analysis` row of `-V benchmark-data` (Issue #528):
# `benchmark-data` is a transport with no owning harness, so each of its rows
# is asserted by the harness owning the feature that produces it
# (tests/HARNESS-DESIGN.md section Naming rules).
# Usage: ./tests/validate-statistics-demand.sh
#
# Follows the self-documenting assertion design from tests/HARNESS-DESIGN.md
# (reference implementation: tests/validate-histogram-bin-counters.sh).
# Every assertion records:
#   - asserts:     the application invariant being tested
#   - produced_by: where in ltl the invariant is produced (function name)
#   - contract:    the stability contract that makes it stable
# All three are surfaced on failure.

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

# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence): the
# demand registry is driven by which consumers are active (summary table,
# CSV, sort field, heatmap), so display options are the subject and none is
# suppressed; the 5k, 4-minute slice is already minimal.
ACCESS_LOG="$LOGS_DIR/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"
NO_METRICS_FIXTURE="$REPO_DIR/tests/fixtures/log-level-vocabulary.txt"
SINGLE_SAMPLE_FIXTURE="$REPO_DIR/tests/fixtures/tomcat-access-single-sample-keys.txt"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$ACCESS_LOG" ]]; then
    echo "ERROR: ACCESS_LOG not found: $ACCESS_LOG"
    exit 1
fi

# Scenario 2 passes -o, which writes CSV artifacts into the CWD; run every
# scenario inside a scratch workdir so no artifacts land in the repo.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

CONTRACT='features/duration-statistics.md § -V statistics-demand section contract — stability-contracted; renames are breaking'

pass=0
fail=0
failures=()
current_scenario=""

# Run ltl with the requested -V section(s) and the standard suppression flag.
# Captures stdout to a temp file (path echoed); stderr lands beside it.
# Args after the function name are forwarded verbatim before the input file.
run_section() {
    local sections="$1"; shift
    local outfile
    outfile=$(mktemp)
    "$LTL" --disable-progress -ni --terminal-width 200 -V "$sections" "$@" "$ACCESS_LOG" > "$outfile" 2>"$outfile.stderr" || true
    echo "$outfile"
}

# Same, against an explicit input file instead of $ACCESS_LOG — for the
# unsatisfiable-sort scenarios (#418), whose fixtures are chosen for what the
# run does NOT contain. `-bs 1440 -oe`: these read a stderr note and the
# sort_gate line, never a bucket.
run_section_on() {
    local sections="$1" input="$2"; shift 2
    local outfile
    outfile=$(mktemp)
    "$LTL" --disable-progress -ni --terminal-width 200 -bs 1440 -oe -V "$sections" "$@" "$input" > "$outfile" 2>"$outfile.stderr" || true
    echo "$outfile"
}

# Runtime-warning cleanliness for a run_section capture (stderr lives beside
# the captured stdout as <capture>.stderr). Runs in the main shell so the
# fail counters persist. HARNESS-DESIGN.md § Runtime-warning cleanliness.
check_capture_warnings() {
    local capture="$1"
    if ! assert_no_runtime_warnings "$capture.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# Self-documenting assertion: a line matching `pattern` must be present.
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

# Self-documenting assertion for anything beyond a single-line grep.
# `command` is eval'd (PASS if exit 0); `label` names it on the PASS line.
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

    if eval "$command" >/dev/null 2>&1; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        command:     $command"
        echo "        label:       $label"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# Extract the statistics-demand section body; hard-fail (per HARNESS-DESIGN
# "must fail on missing anchors") if the start or end marker is absent.
extract_section() {
    local outfile="$1"
    local body="$outfile.section"
    if ! grep -q '^=== statistics-demand ===$' "$outfile" \
       || ! grep -q '^=== END statistics-demand ===$' "$outfile"; then
        echo "  FAIL  $current_scenario"
        echo "        pattern:     === statistics-demand === ... === END statistics-demand ==="
        echo "        asserts:     The statistics-demand section is emitted with both start and end markers when requested via -V"
        echo "        produced_by: emit_statistics_demand_verbose() in ltl"
        echo "        contract:    $CONTRACT"
        echo "        (anchor not found in $outfile)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: section-anchor-missing")
        return 1
    fi
    sed -n '/^=== statistics-demand ===$/,/^=== END statistics-demand ===$/p' "$outfile" > "$body"
    echo "$body"
}

# Extract the per-store sub-block (lines from `store: <name>` up to the next
# `store:` or the section end marker) so per-store assertions cannot match
# the other store's lines.
extract_store() {
    local body="$1" store="$2"
    local out="$body.$store"
    awk -v store="$store" '
        $0 == "store: " store { inside=1; print; next }
        inside && (/^store: / || /^=== END /) { inside=0 }
        inside { print }
    ' "$body" > "$out"
    echo "$out"
}

echo "=== validate-statistics-demand: statistics-demand -V section (Issue #305) ==="
echo "fixture: $ACCESS_LOG"
echo

############################################################
current_scenario="scenario-1-terminal-only-default"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    for store in bucket message; do
        sb=$(extract_store "$body" "$store")
        assert_line "$sb" \
            pattern     '^  store_demand: 1$' \
            asserts     "On a default terminal run the $store store is demanded (its terminal surface is active)" \
            produced_by 'resolve_statistics_group_demand() in ltl (store-level booleans from adapt_to_command_line_options)' \
            contract    "$CONTRACT"
        assert_line "$sb" \
            pattern     '^  group terminal_core: demanded=1 consumers=' \
            asserts     "terminal_core is demanded on the $store store whenever the store is (every store-activating consumer declares it)" \
            produced_by 'resolve_statistics_group_demand() in ltl' \
            contract    "$CONTRACT"
        for group in csv_body extended_percentiles shape_moments; do
            assert_line "$sb" \
                pattern     "^  group $group: demanded=0 consumers=-\$" \
                asserts     "On a terminal-only run no consumer raises $group demand on the $store store (terminal surfaces read only terminal_core fields)" \
                produced_by 'resolve_statistics_group_demand() in ltl' \
                contract    "$CONTRACT"
        done
        assert_line "$sb" \
            pattern     '^  moment_source: none$' \
            asserts     "With shape_moments undemanded the $store store reports moment_source none" \
            produced_by 'emit_statistics_demand_verbose() in ltl' \
            contract    "$CONTRACT"
        assert_line "$sb" \
            pattern     '^  stats_calls: [1-9][0-9]*$' \
            asserts     "The $store store reports a non-zero count of statistics-primitive invocations on a demanded store (every call is counted, including no-duration early returns)" \
            produced_by 'calculate_statistics() / calculate_statistics_bin() in ltl (stats_calls in %stats_demand_telemetry)' \
            contract    "$CONTRACT"
        assert_line "$sb" \
            pattern     '^  group_calc terminal_core: computed=[1-9][0-9]* skipped_demand=0 ineligible=0$' \
            asserts     "terminal_core is derived on every non-early-returned invocation of the $store store's statistics primitive (never demand-skipped: terminal_core demand equals store demand)" \
            produced_by 'calculate_statistics() / calculate_statistics_bin() in ltl (group_calc counters)' \
            contract    "$CONTRACT"
        assert_line "$sb" \
            pattern     '^  group_calc shape_moments: computed=0 skipped_demand=[0-9]+ ineligible=[0-9]+$' \
            asserts     "On a terminal-only run the $store store's shape-moment derivation never runs — eligible (n>=4) calls are demand-skipped and n<4 calls are counted ineligible, so every invocation is accounted for" \
            produced_by 'calculate_statistics() / calculate_statistics_bin() in ltl (group_calc counters)' \
            contract    "$CONTRACT"
    done
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  group_calc shape_moments: computed=0 skipped_demand=[1-9][0-9]* ineligible=[0-9]+$' \
        asserts     'On a terminal-only run the message store demand-skips the shape derivation for every eligible key — the observable proof that demand gating fires' \
        produced_by 'calculate_statistics() in ltl (group_calc counters in %stats_demand_telemetry)' \
        contract    "$CONTRACT"
    assert_command \
        command     "! grep -qE '^  sort_(selection|calc):' '$sm'" \
        label       'no sort_selection/sort_calc lines under the default occurrences sort' \
        asserts     'The #303 sort-path lines appear only when a calculated-statistic sort ran; an available-value sort (default occurrences) emits neither' \
        produced_by 'emit_statistics_demand_verbose() in ltl (sort_selection telemetry populated only on the two-pass sort path)' \
        contract    "$CONTRACT"
fi
echo

############################################################
current_scenario="scenario-2-csv-full-demand"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand -o)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    sb=$(extract_store "$body" bucket)
    assert_line "$sb" \
        pattern     '^  group shape_moments: demanded=1 consumers=.*stats-csv' \
        asserts     'With -o active the STATS CSV raises shape_moments demand on the bucket store' \
        produced_by 'resolve_statistics_group_demand() in ltl (@STAT_CONSUMERS stats-csv declaration)' \
        contract    "$CONTRACT"
    assert_line "$sb" \
        pattern     '^  group extended_percentiles: demanded=1 consumers=.*stats-csv' \
        asserts     'With -o active the STATS CSV raises extended_percentiles demand on the bucket store' \
        produced_by 'resolve_statistics_group_demand() in ltl' \
        contract    "$CONTRACT"
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  group shape_moments: demanded=1 consumers=.*messages-csv' \
        asserts     'With -o active the MESSAGES CSV raises shape_moments demand on the message store' \
        produced_by 'resolve_statistics_group_demand() in ltl (@STAT_CONSUMERS messages-csv declaration)' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  moment_source: second_pass$' \
        asserts     'Under the default raw data model with shape demanded, the message store reports moment_source second_pass' \
        produced_by 'emit_statistics_demand_verbose() in ltl' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  group_calc shape_moments: computed=[1-9][0-9]* skipped_demand=0 ineligible=[0-9]+$' \
        asserts     'With every group demanded the message store derives shape moments for every eligible key and demand-skips nothing — output parity with the pre-gating behavior' \
        produced_by 'calculate_statistics() in ltl (group_calc counters)' \
        contract    "$CONTRACT"
    assert_command \
        command     "calls=\$(awk '/^  stats_calls: /{print \$2; exit}' '$sm'); tc=\$(grep -oE '^  group_calc terminal_core: computed=[0-9]+' '$sm' | grep -oE '[0-9]+\$'); [[ -n \"\$calls\" && -n \"\$tc\" && \"\$calls\" -ge \"\$tc\" ]]" \
        label       'message stats_calls >= terminal_core computed (early-returned calls are counted as invocations)' \
        asserts     'stats_calls counts every statistics-primitive invocation, so it is always >= the terminal_core computed count (the difference is the early-returned no-duration calls)' \
        produced_by 'calculate_statistics() / calculate_statistics_bin() in ltl (stats_calls vs group_calc counters)' \
        contract    "$CONTRACT"
fi
echo

############################################################
current_scenario="scenario-3-sort-on-skewness"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand -so skewness)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  group shape_moments: demanded=1 consumers=sort-on:skewness$' \
        asserts     'Sorting on a statistic makes -so an explicit demand contributor: -so skewness raises shape_moments demand on the message store with sort-on:<field> provenance' \
        produced_by 'resolve_statistics_group_demand() in ltl (@STAT_CONSUMERS sort-on declaration)' \
        contract    "$CONTRACT"
    sb=$(extract_store "$body" bucket)
    assert_line "$sb" \
        pattern     '^  group shape_moments: demanded=0 consumers=-$' \
        asserts     'A message-store sort key raises no demand on the bucket store' \
        produced_by 'resolve_statistics_group_demand() in ltl' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  moment_source: second_pass$' \
        asserts     'The message store computes shape moments (via the raw second pass) when demanded by the sort key alone' \
        produced_by 'emit_statistics_demand_verbose() in ltl' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  group_calc shape_moments: computed=[1-9][0-9]* skipped_demand=0 ineligible=0$' \
        asserts     'Under the #303 two-pass sort the shape derivation runs only for keys that met the n>=4 eligibility floor (population pass) or won a display slot (top-N pass) — nothing is demand-skipped and no ineligible key ever reaches the primitive' \
        produced_by 'calculate_statistics() in ltl (group_calc counters; two-pass sort path in calculate_all_statistics)' \
        contract    "$CONTRACT"
    # Sabotage record (HARNESS-DESIGN.md § Proving a new assertion can fail),
    # 2026-07-13, three probes against emit_statistics_demand_verbose(), each
    # restored after confirming the expected failure with the full
    # asserts/produced_by/contract triple and exit 1:
    #   1. key renamed sort_selection -> sort_sel  => sort_selection line
    #      assertion failed;
    #   2. population count emitted +1             => the population =
    #      defined + demoted invariant failed;
    #   3. sort lines emitted unconditionally      => both absence assertions
    #      (scenario-1 message store, scenario-3 bucket store) failed.
    assert_line "$sm" \
        pattern     '^  sort_selection: statistic=skewness defined=[1-9][0-9]* fill=[1-9][0-9]* demoted=[0-9]+$' \
        asserts     'The calculated-statistic sort reports its eligibility split: keys ranked by the computed value (defined) vs keys ranked by occurrences (fill), with demoted counting eligible keys whose value computed to undef' \
        produced_by 'calculate_all_statistics() in ltl (sort_selection telemetry), emitted by emit_statistics_demand_verbose()' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  sort_calc: population=[1-9][0-9]* topn=[1-9][0-9]*$' \
        asserts     'The two-pass sort attributes primitive invocations per pass: population (defined-block candidates, sort-statistic group only) and topn (displayed keys, full demanded statistics)' \
        produced_by 'calculate_all_statistics() in ltl (population_calls telemetry); topn derived at emit time as stats_calls minus population' \
        contract    "$CONTRACT"
    assert_command \
        command     "pop=\$(grep -oE '^  sort_calc: population=[0-9]+' '$sm' | grep -oE '[0-9]+\$'); def=\$(grep -oE 'defined=[0-9]+' '$sm' | grep -oE '[0-9]+\$'); dem=\$(grep -oE 'demoted=[0-9]+' '$sm' | grep -oE '[0-9]+\$'); [[ -n \"\$pop\" && -n \"\$def\" && -n \"\$dem\" && \"\$pop\" -eq \$((def + dem)) ]]" \
        label       'population calls = defined + demoted (every pass-1 call produced a ranked value or a demotion)' \
        asserts     'Every population-pass invocation is accounted for: it either yielded a defined sort value or demoted the key to the fill block' \
        produced_by 'calculate_all_statistics() in ltl (two-pass sort path)' \
        contract    "$CONTRACT"
    # #418 control for the D6 amendment: the ordinary partial case (some keys
    # rank, some fill) is untouched — the gate stands aside and stays quiet.
    assert_line "$body" \
        pattern     '^sort_gate: operand=skewness family=duration observed=1 fallback=none$' \
        asserts     'A statistic sort that ranks at least one key is left standing: the unsatisfiable-sort gate resolves the family, sees it observed, and takes no fallback' \
        produced_by 'apply_pre_walk_sort_gate() / apply_post_walk_sort_gate() in ltl, emitted by emit_statistics_demand_verbose()' \
        contract    "$CONTRACT"
    assert_command \
        command     "! grep -q '^Note: .*ordered by occurrences' '$out.stderr'" \
        label       'no fallback note on stderr in the partial case' \
        asserts     'The fallback note is printed only in the degenerate case (no key ranks); a partial ranking with a fill block prints nothing — the blank statistic cell remains the signal' \
        produced_by 'sort_fallback_to_occurrences() in ltl (reached only from a detection point that fired)' \
        contract    "features/303-calculated-statistic-sort-path.md § sort contract point 4, as amended by features/418-unsatisfiable-sort-selection-cost.md § D6"
    assert_command \
        command     "! grep -qE '^  sort_(selection|calc):' '$sb'" \
        label       'no sort_selection/sort_calc lines on the bucket store' \
        asserts     'The sort-path lines are emitted only for the store where the two-pass selection ran (the message store); their absence elsewhere is contractual' \
        produced_by 'emit_statistics_demand_verbose() in ltl (sort_selection telemetry is message-store only)' \
        contract    "$CONTRACT"
fi
echo

############################################################
current_scenario="scenario-3b-sort-on-p99"
# The sort_selection/sort_calc assertions below grep the same emitted lines
# already sabotage-proven under scenario-3 (see the record there); the group
# demand-line shapes are the long-established scenario-1/2/3 patterns.
echo "--- $current_scenario ---"
out=$(run_section statistics-demand -so p99)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  group terminal_core: demanded=1 consumers=messages-table,sort-on:p99$' \
        asserts     'Sorting on p99 raises no group beyond terminal_core (p99 is a terminal_core field): the sort-on consumer joins the existing terminal_core demand with provenance' \
        produced_by 'resolve_statistics_group_demand() in ltl (@STAT_CONSUMERS sort-on declaration)' \
        contract    "$CONTRACT"
    for group in csv_body extended_percentiles shape_moments; do
        assert_line "$sm" \
            pattern     "^  group $group: demanded=0 consumers=-\$" \
            asserts     "A terminal_core sort key ($group check) raises no demand on any other statistics group" \
            produced_by 'resolve_statistics_group_demand() in ltl' \
            contract    "$CONTRACT"
    done
    assert_line "$sm" \
        pattern     '^  sort_selection: statistic=p99 defined=[1-9][0-9]* fill=[0-9]+ demoted=[0-9]+$' \
        asserts     'The two-pass sort path runs (and reports its eligibility split) even when the sort statistic needs no extra group demand — a percentile sort at n>=1 makes every duration-bearing key defined' \
        produced_by 'calculate_all_statistics() in ltl (sort_selection telemetry), emitted by emit_statistics_demand_verbose()' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  sort_calc: population=[1-9][0-9]* topn=[1-9][0-9]*$' \
        asserts     'Both passes run under a percentile sort: population over the defined block, top-N over the displayed keys' \
        produced_by 'calculate_all_statistics() in ltl (population_calls telemetry); topn derived at emit time' \
        contract    "$CONTRACT"
fi
echo

############################################################
# Unsatisfiable statistic sort (#418): each scenario proves the PATH taken at
# one detection point, across the three metric families. An occurrences-
# ordered table looks the same whichever way it was reached, so the
# assertions read the sort_gate line (the decision), the presence or absence
# of sort_selection (whether the walk ran), and the stderr note.
# Sabotage record (HARNESS-DESIGN.md § Proving a new assertion can fail),
# 2026-08-28, each probe restored after confirming the expected failure with
# the full asserts/produced_by/contract triple and exit 1:
#   1. apply_parse_time_sort_gate() made to return before resetting the sort
#      key            => scenario-6 sort_gate fallback=parse and the
#                        no-sort_selection assertions failed;
#   2. apply_pre_walk_sort_gate() observed forced to 1
#                     => scenario-7 fallback=pre-walk, the note, and the
#                        no-sort_selection assertions failed;
#   3. apply_post_walk_sort_gate() made to return unconditionally
#                     => scenario-8 fallback=post-walk and the note failed;
#   4. note printed unconditionally from sort_fallback_to_occurrences()
#      call site      => scenario-3 no-note control failed.
GATE_CONTRACT='features/418-unsatisfiable-sort-selection-cost.md § D3 (three detection points), D5 (parse-time fallback is literal), D12 (gate state on -V) — stability-contracted via features/duration-statistics.md § sort_gate'

current_scenario="scenario-6-sort-unsatisfiable-at-parse"
echo "--- $current_scenario ---"
# -so <family operand> together with that family's --omit flag, all three
# families. Knowable before a line is read: the sort key is reset to
# occurrences at parse time, so the calculated-statistic branch never runs.
for combo in "p99:-od:duration:-od/--omit-durations" "bytes_mean:-ob:bytes:-ob/--omit-bytes" "count_mean:-oc:count:-oc/--omit-count"; do
    IFS=: read -r operand flag family flagname <<< "$combo"
    out=$(run_section_on statistics-demand "$ACCESS_LOG" -so "$operand" "$flag")
    check_capture_warnings "$out"
    if body=$(extract_section "$out"); then
        assert_line "$body" \
            pattern     "^sort_gate: operand=$operand family=$family observed=0 fallback=parse\$" \
            asserts     "-so $operand with $flag is a contradiction knowable at option parsing: the gate resolves the $family family, records the metric as never collected, and falls back at parse time" \
            produced_by 'apply_parse_time_sort_gate() in ltl, emitted by emit_statistics_demand_verbose()' \
            contract    "$GATE_CONTRACT"
        assert_command \
            command     "! grep -qE '^  sort_(selection|calc):' '$body'" \
            label       "no sort_selection line: the calculated-statistic branch was never entered (-so $operand $flag)" \
            asserts     'A parse-time fallback resets the sort key to occurrences before demand resolution, so the two-pass sort path — and its telemetry — never runs (D5: the fallback is literal, not an outcome reached by another route)' \
            produced_by 'apply_parse_time_sort_gate() in ltl (sort key reset); calculate_all_statistics() emits sort_selection only on the calculated-statistic branch' \
            contract    "$GATE_CONTRACT"
        assert_command \
            command     "grep -qF 'Note: cannot apply -so/--sort-on $operand because $flagname discards the $family metric - the messages table is ordered by occurrences' '$out.stderr'" \
            label       "contradiction note on stderr names -so/--sort-on $operand, $flagname and the fallback" \
            asserts     'The parse-time note names the contradiction (the option that discarded the metric, short and long form) and states that the table is ordered by occurrences' \
            produced_by 'apply_parse_time_sort_gate() in ltl' \
            contract    'features/418-unsatisfiable-sort-selection-cost.md § D1 (contradiction notice)'
    fi
done
echo

############################################################
current_scenario="scenario-7-sort-unsatisfiable-before-walk"
echo "--- $current_scenario ---"
# A log carrying no duration, bytes or count field at all: the family is
# collectable but nothing was observed, so the walk is skipped outright.
for combo in "p99:duration" "bytes_mean:bytes" "count_mean:count"; do
    IFS=: read -r operand family <<< "$combo"
    out=$(run_section_on statistics-demand "$NO_METRICS_FIXTURE" -so "$operand")
    check_capture_warnings "$out"
    if body=$(extract_section "$out"); then
        assert_line "$body" \
            pattern     "^sort_gate: operand=$operand family=$family observed=0 fallback=pre-walk\$" \
            asserts     "-so $operand on a log with no $family values: the gate reads the family's observation state after the read loop, finds nothing observed, and falls back before the population walk" \
            produced_by 'apply_pre_walk_sort_gate() in ltl, emitted by emit_statistics_demand_verbose()' \
            contract    "$GATE_CONTRACT"
        assert_command \
            command     "! grep -qE '^  sort_(selection|calc):' '$body'" \
            label       "no sort_selection line: the population walk was skipped, not run and discarded (-so $operand)" \
            asserts     'A pre-walk fallback resets the sort key before the per-category loop, so the population walk and the fill-block re-sort never execute — the cost the fix removes' \
            produced_by 'apply_pre_walk_sort_gate() in ltl, called at the head of the per-message block in calculate_all_statistics()' \
            contract    "$GATE_CONTRACT"
        assert_command \
            command     "grep -qF 'Note: no $family values were found - the requested sort (-so/--sort-on $operand) could not be produced, so the messages table is ordered by occurrences' '$out.stderr'" \
            label       "absence note on stderr names the $family family, -so/--sort-on $operand and the fallback" \
            asserts     'The pre-walk note states that no values of the family were found, names the requested sort option in short and long form, and states that the table is ordered by occurrences' \
            produced_by 'sort_fallback_to_occurrences() in ltl (pre-walk text)' \
            contract    'features/418-unsatisfiable-sort-selection-cost.md § D1 (absence notice, before the walk)'
    fi
done
echo

############################################################
current_scenario="scenario-8-sort-unsatisfiable-after-walk"
echo "--- $current_scenario ---"
# Durations observed, but every key carries one sample: below the n>=4 shape
# floor (skewness) and the n>=2 spread floor (cv). The walk runs, the defined
# block is empty, and the gate says so afterwards.
for combo in "skewness:12" "cv:12"; do
    IFS=: read -r operand keys <<< "$combo"
    out=$(run_section_on statistics-demand "$SINGLE_SAMPLE_FIXTURE" -so "$operand")
    check_capture_warnings "$out"
    if body=$(extract_section "$out"); then
        sm=$(extract_store "$body" message)
        assert_line "$sm" \
            pattern     "^  sort_selection: statistic=$operand defined=0 fill=$keys demoted=0\$" \
            asserts     "With durations present but one sample per key, the walk runs and every key lands in the fill block: defined=0 with all $keys keys in fill" \
            produced_by 'calculate_all_statistics() in ltl (sort_selection telemetry), emitted by emit_statistics_demand_verbose()' \
            contract    "$CONTRACT"
        assert_line "$body" \
            pattern     "^sort_gate: operand=$operand family=duration observed=1 fallback=post-walk\$" \
            asserts     "-so $operand where no key meets the eligibility floor: the family was observed (so neither earlier point fired), and the gate falls back after the walk on an empty defined block" \
            produced_by 'apply_post_walk_sort_gate() in ltl, emitted by emit_statistics_demand_verbose()' \
            contract    "$GATE_CONTRACT"
        assert_command \
            command     "grep -qF 'Note: the requested sort (-so/--sort-on $operand) could not be produced from the duration values in this run - the messages table is ordered by occurrences' '$out.stderr'" \
            label       "post-walk note on stderr names -so/--sort-on $operand, the duration family and the fallback" \
            asserts     'The post-walk note states that the sort could not be produced from the values the run had (they exist, but never enough per message), names the sort option in short and long form, and states that the table is ordered by occurrences' \
            produced_by 'sort_fallback_to_occurrences() in ltl (post-walk text)' \
            contract    'features/418-unsatisfiable-sort-selection-cost.md § D1 (absence notice, after the walk)'
    fi
done
# The available-value branch has no floor above one observation: a bytes
# operand on a log that carries bytes must NOT trip the post-walk gate.
out=$(run_section_on statistics-demand "$SINGLE_SAMPLE_FIXTURE" -so bytes_mean)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    assert_line "$body" \
        pattern     '^sort_gate: operand=bytes_mean family=bytes observed=1 fallback=none$' \
        asserts     'A bytes operand on a log carrying bytes ranks on the available-value branch, which the post-walk gate never judges — the gate is scoped to calculated statistics with an eligibility floor' \
        produced_by 'apply_post_walk_sort_gate() in ltl (%STAT_FIELD_GROUP membership test)' \
        contract    "$GATE_CONTRACT"
fi
echo

############################################################
current_scenario="scenario-4-heatmap-no-bucket-demand"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand -hm duration)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    sb=$(extract_store "$body" bucket)
    assert_line "$sb" \
        pattern     '^  store_demand: 0$' \
        asserts     'With the heatmap replacing the timeline latency column and no CSV active, the bucket store has no consumer and store demand is 0' \
        produced_by 'adapt_to_command_line_options() in ltl (store-level demand resolution, #349)' \
        contract    "$CONTRACT"
    for group in terminal_core csv_body extended_percentiles shape_moments; do
        assert_line "$sb" \
            pattern     "^  group $group: demanded=0 consumers=-\$" \
            asserts     "With the bucket store undemanded no group can be demanded on it ($group)" \
            produced_by 'resolve_statistics_group_demand() in ltl (store-level demand is a precondition for every consumer)' \
            contract    "$CONTRACT"
    done
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  store_demand: 1$' \
        asserts     'The heatmap does not suppress the message store: the messages table remains active' \
        produced_by 'adapt_to_command_line_options() in ltl (store-level demand resolution, #349)' \
        contract    "$CONTRACT"
fi
echo

############################################################
current_scenario="scenario-5-runtime-config-crosscheck"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand,runtime-config)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    assert_command \
        command     "bd=\$(grep -oE 'bucket-duration-stats-demand: [01]' '$out' | grep -oE '[01]\$'); sd=\$(awk '/^store: bucket\$/{f=1;next} f&&/store_demand:/{print \$2; exit}' '$body'); [[ -n \"\$bd\" && \"\$bd\" == \"\$sd\" ]]" \
        label       'bucket store_demand agrees with runtime-config bucket-duration-stats-demand' \
        asserts     'The statistics-demand store_demand line and the runtime-config bucket-duration-stats-demand boolean report the same resolved value (single resolution surface)' \
        produced_by 'emit_statistics_demand_verbose() and emit_runtime_config_verbose() in ltl, both reading $bucket_duration_stats_demand' \
        contract    "$CONTRACT"
    assert_command \
        command     "md=\$(grep -oE 'message-duration-stats-demand: [01]' '$out' | grep -oE '[01]\$'); sd=\$(awk '/^store: message\$/{f=1;next} f&&/store_demand:/{print \$2; exit}' '$body'); [[ -n \"\$md\" && \"\$md\" == \"\$sd\" ]]" \
        label       'message store_demand agrees with runtime-config message-duration-stats-demand' \
        asserts     'The statistics-demand store_demand line and the runtime-config message-duration-stats-demand boolean report the same resolved value (single resolution surface)' \
        produced_by 'emit_statistics_demand_verbose() and emit_runtime_config_verbose() in ltl, both reading $message_duration_stats_demand' \
        contract    "$CONTRACT"
fi
echo

############################################################
# -n 0 retains no message at all, so the message store has no consumer, no
# population and no rendered table — while the bucket store and the timeline
# are untouched. The demand side is read from the statistics-demand section
# and the store size from benchmark-data's COUNTS rows; the two render
# assertions read the displayed surface itself, because "the messages table is
# absent" and "the timeline is present" are properties of that surface with no
# internal-state equivalent (tests/HARNESS-DESIGN.md section Render-invariant
# harnesses). The layout is pinned by run_section's --terminal-width 200 and
# ANSI is stripped before matching.
current_scenario="scenario-9-no-message-retention"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand,benchmark-data -n 0)
check_capture_warnings "$out"
sed -E 's/\x1b\[[0-9;]*m//g' "$out" > "$out.plain"
if body=$(extract_section "$out"); then
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  store_demand: 0$' \
        asserts     'With no message retained the message store has no active consumer, so its store demand is 0' \
        produced_by 'adapt_to_command_line_options() in ltl (store-level demand resolution gated on $capture_messages)' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  population: 0$' \
        asserts     'No message key is walked because none was ever stored: the message store block-boundary population is 0' \
        produced_by 'calculate_all_statistics() in ltl ($stats_population_messages, per-category population accumulation)' \
        contract    "$CONTRACT"
    for group in terminal_core csv_body extended_percentiles shape_moments; do
        assert_line "$sm" \
            pattern     "^  group $group: demanded=0 consumers=-\$" \
            asserts     "With the message store undemanded no group can be demanded on it ($group)" \
            produced_by 'resolve_statistics_group_demand() in ltl (store-level demand is a precondition for every consumer)' \
            contract    "$CONTRACT"
    done
    assert_line "$sm" \
        pattern     '^  stats_calls: 0$' \
        asserts     'The per-message statistics primitive is never invoked when no message is retained' \
        produced_by 'calculate_statistics() / calculate_statistics_bin() in ltl (stats_calls in %stats_demand_telemetry)' \
        contract    "$CONTRACT"
    sb=$(extract_store "$body" bucket)
    assert_line "$sb" \
        pattern     '^  store_demand: 1$' \
        asserts     'Retaining no message leaves the per-time-bucket store untouched: the timeline latency column still consumes it' \
        produced_by 'adapt_to_command_line_options() in ltl (store-level demand resolution)' \
        contract    "$CONTRACT"
fi
assert_line "$out" \
    pattern     '^COUNTS[[:space:]]+log_messages_entries[[:space:]]+0$' \
    asserts     'No log message is added to the per-message store, so it holds zero entries at the end of the run' \
    produced_by 'emit_benchmark_data_verbose() in ltl (COUNTS rows over %log_messages)' \
    contract    'tests/HARNESS-DESIGN.md section Reserved section names — benchmark-data COUNTS rows are stability-contracted; renames are breaking'
assert_line "$out" \
    pattern     '^COUNTS[[:space:]]+log_messages_population[[:space:]]+0$' \
    asserts     'The walk-time message population re-emitted into benchmark-data agrees with the statistics-demand population line (one source, two surfaces)' \
    produced_by 'emit_benchmark_data_verbose() in ltl (re-emitted $stats_population_messages)' \
    contract    'tests/HARNESS-DESIGN.md section Counters serving benchmark attribution — one source, two surfaces'
assert_command \
    command     "! grep -qE 'TOP (OVERALL|HIGHLIGHTED) MESSAGES' '$out.plain'" \
    label       'neither messages-table header is rendered' \
    asserts     'The message summary table is skipped entirely - not printed empty, and not printed with a header only' \
    produced_by 'pipeline_render() in ltl (print_message_summary is not called when no message is retained)' \
    contract    'features/458-top-messages-zero-no-per-message-retention.md section Decisions'
assert_line "$out.plain" \
    pattern     '^[[:space:]]+timestamp[[:space:]]+legend[[:space:]]+(success[[:space:]]+failure[[:space:]]+)?occurrences[[:space:]]' \
    asserts     'The timeline bar graph is still produced when no message is retained' \
    produced_by 'print_bar_graph() in ltl (column header row)' \
    contract    'features/458-top-messages-zero-no-per-message-retention.md section Decisions'
assert_line "$out.plain" \
    pattern     'P50:[0-9]+' \
    asserts     'Statistics over the whole population are still computed and displayed: the timeline latency column carries its percentiles' \
    produced_by 'print_bar_graph() in ltl (latency statistics column, fed by the per-time-bucket store)' \
    contract    'features/458-top-messages-zero-no-per-message-retention.md section Decisions'
echo

############################################################
# The options that configure only the per-message store are ignored rather than
# rejected, and the tool says so on stderr. The notice is a behavioural notice,
# not progress output, so it is emitted whatever --disable-progress is set to.
current_scenario="scenario-10-no-message-retention-inert-options"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand -n 0 -g 85 -mdm bin -so p50)
check_capture_warnings "$out"
assert_line "$out.stderr" \
    pattern     'Note: -n/--top-messages 0 retains no message, so .*-g/--group-similar.*-mdm/--message-stats-data-model.*-so/--sort-on have no effect' \
    asserts     'Message grouping, the message statistics data model and the message ranking are reported inert (not rejected) when no message is retained, naming each option the user passed' \
    produced_by 'adapt_to_command_line_options() in ltl (per-message retention fold, before the statistics-demand resolution)' \
    contract    'features/458-top-messages-zero-no-per-message-retention.md section Decisions'
if body=$(extract_section "$out"); then
    assert_line "$body" \
        pattern     '^sort_gate: operand=p50 family=duration observed=n/a fallback=none$' \
        asserts     'A ranking request is recorded as given but never falls back, because with no message retained there is nothing to rank and no fallback to report' \
        produced_by 'apply_parse_time_sort_gate() / apply_pre_walk_sort_gate() / apply_post_walk_sort_gate() in ltl' \
        contract    "$CONTRACT"
fi
echo

############################################################
# A negative top-message count takes the same path as zero: it cannot rank a
# row either, so nothing is retained. Read from the demand section alone —
# nothing here depends on the render or on the bucket axis.
current_scenario="scenario-11-negative-top-messages-retains-nothing"
echo "--- $current_scenario ---"
out=$(run_section statistics-demand -n -5)
check_capture_warnings "$out"
if body=$(extract_section "$out"); then
    sm=$(extract_store "$body" message)
    assert_line "$sm" \
        pattern     '^  store_demand: 0$' \
        asserts     'A negative top-message count retains nothing, exactly as zero does: the message store has no active consumer' \
        produced_by 'adapt_to_command_line_options() in ltl (retention resolved from the top-message count being greater than zero)' \
        contract    "$CONTRACT"
    assert_line "$sm" \
        pattern     '^  population: 0$' \
        asserts     'No message key is walked under a negative top-message count, because none was ever stored' \
        produced_by 'calculate_all_statistics() in ltl ($stats_population_messages, per-category population accumulation)' \
        contract    "$CONTRACT"
fi
echo

############################################################
# A CSV request under -n 0 is half-served: the STATS CSV is written, the
# MESSAGES CSV is not, and the user is told so at run time. The run gets its
# own scratch directory so the two file assertions see only its own artifacts
# (scenario 2 also writes CSVs into the shared workdir). `-bs 1440 -oe`: this
# scenario reads a stderr notice and which files exist, never a bucket row.
current_scenario="scenario-12-no-message-retention-csv-request"
echo "--- $current_scenario ---"
CSV_ONLY_DIR="$WORKDIR/csv-no-message-retention"
mkdir -p "$CSV_ONLY_DIR"
cd "$CSV_ONLY_DIR"
out=$(run_section statistics-demand -bs 1440 -oe -n 0 -o)
cd "$WORKDIR"
check_capture_warnings "$out"
assert_line "$out.stderr" \
    pattern     'Note: -n/--top-messages 0 retains no message, so -o/--output-csv writes the STATS CSV only: no MESSAGES CSV is written' \
    asserts     'A CSV request is reported as half-served when no message is retained: the user is told at run time which of the two files is not written and why' \
    produced_by 'adapt_to_command_line_options() in ltl (per-message retention fold, before the statistics-demand resolution)' \
    contract    'features/458-top-messages-zero-no-per-message-retention.md section Decisions'
assert_command \
    command     "ls '$CSV_ONLY_DIR'/*-LTL-STATS-*.csv" \
    label       'the STATS CSV is still written' \
    asserts     'Retaining no message does not affect the per-time-bucket CSV: -o still writes it' \
    produced_by 'pipeline_render() in ltl (STATS CSV open, gated only on the CSV request)' \
    contract    'features/458-top-messages-zero-no-per-message-retention.md section Decisions'
assert_command \
    command     "! ls '$CSV_ONLY_DIR'/*-LTL-MESSAGES-*.csv" \
    label       'no MESSAGES CSV file is created' \
    asserts     'The MESSAGES CSV is the per-message store written out: with nothing retained no file is created, not even a header-only one' \
    produced_by 'pipeline_render() in ltl (MESSAGES CSV open gated on message retention)' \
    contract    'features/458-top-messages-zero-no-per-message-retention.md section Decisions'
echo

############################################################
# What the per-time-bucket store retains is not only how many durations, but
# how wide each retained scalar is. A Perl scalar's body grows on demand and
# never shrinks, every copy inherits a body able to carry what its source
# carries, and the record lexicals are shared by every format for the whole
# run — so one format transform assigning a value Perl represents as a double
# into $duration widens every duration retained afterwards, for every format,
# on every file. The startup extraction-parity gate executes every entry's
# transforms against those lexicals before line 1, so the breach does not need
# the run to encounter the offending format.
#
# The ceiling is one-sided, because the defect can only make the store larger.
# On this fixture the two forms are separated by 8 bytes per retained duration:
# 32,329 bytes as committed against 35,801 bytes with the coercion removed, a
# 3,472-byte gap over 434 lines, each figure bit-identical across five runs.
# The 33,000-byte ceiling sits 671 bytes above the committed figure and 2,801
# below the breached one, so a hash-bucket resize or a fixture edit of a few
# lines cannot trip it and a breach cannot hide under it. One run is therefore
# enough; the tolerance carries the margin instead of repetition.
#
# The fixture's line count is stated with the threshold: a regeneration that
# changed it changes the retained population, and that must surface as a
# failure to be re-derived rather than pass as drift.
#
# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# `-mem` because the structure rows are gated on it; `-bs 1440` folds the
# fixture's 14.5 h span into one bucket, removing per-bucket hash overhead
# that is unrelated to the signal and is the only observed source of variance;
# `-oe` switches off the empty-bucket fill; `-n 1` because no rendered row is
# read; `-V benchmark-data` narrows the output to the transport. The exact
# byte counts are read rather than the `-mem` summary's whole-KiB rows, whose
# rounding boundary sits close enough to the signal to move between runs of
# the same build.
current_scenario="scenario-13-retained-duration-representation"
echo "--- $current_scenario ---"
DURATION_SPREAD_FIXTURE="$REPO_DIR/tests/fixtures/tomcat-access-duration-spread.txt"
DURATION_SPREAD_LINES=434
LOG_ANALYSIS_CEILING=33000
REPRESENTATION_ASSERTS='The retained per-bucket durations carry no floating-point slot: a transform that assigns a double into a shared record lexical enlarges every duration retained afterwards, and the per-bucket statistics store grows by 8 bytes per retained duration when one does'
REPRESENTATION_PRODUCED_BY='named_structure_sizes() in ltl, reached through measure_memory_structures(); the retained values come from the per-bucket durations push in read_and_process_logs()'
REPRESENTATION_CONTRACT='features/528-record-lexical-retained-representation.md section The contract, and features/log-format-registry.md F11a: a transform may not leave a shared record lexical holding a value Perl represents as a double'

if [[ ! -f "$DURATION_SPREAD_FIXTURE" ]]; then
    echo "ERROR: fixture not found: $DURATION_SPREAD_FIXTURE"
    exit 1
fi

rep_out=$(mktemp)
"$LTL" --disable-progress -mem -bs 1440 -oe -V benchmark-data -n 1 \
    "$DURATION_SPREAD_FIXTURE" > "$rep_out" 2>"$rep_out.stderr" || true
check_capture_warnings "$rep_out"

# The fixture's retained population is part of the threshold's derivation, so a
# regeneration that changed the line count invalidates the ceiling rather than
# drifting under it.
actual_lines=$(wc -l < "$DURATION_SPREAD_FIXTURE" | tr -d ' ')
assert_command \
    command     "[[ '$actual_lines' -eq $DURATION_SPREAD_LINES ]]" \
    label       "the fixture still carries $DURATION_SPREAD_LINES lines, the population the ceiling was derived from" \
    asserts     "The retained-duration ceiling is derived from this fixture's $DURATION_SPREAD_LINES durations; a regenerated fixture with a different line count changes the retained population and the threshold must be re-derived rather than silently absorb the change" \
    produced_by 'tests/duration-display/generate-fixture.py (fixture generator); the population is retained by the per-bucket durations push in read_and_process_logs()' \
    contract    "$REPRESENTATION_CONTRACT"

# A missing row is a hard failure: the assertion below compares a number, and an
# absent row must never read as a value under the ceiling.
log_analysis_bytes=$(awk -F'\t' '$1 == "MEMORY" && $2 == "log_analysis" { print $3; found=1 } END { exit !found }' "$rep_out") || log_analysis_bytes=""
if [[ -z "$log_analysis_bytes" ]]; then
    echo "  FAIL  $current_scenario"
    echo "        pattern:     MEMORY<TAB>log_analysis<TAB><bytes>"
    echo "        asserts:     $REPRESENTATION_ASSERTS"
    echo "        produced_by: $REPRESENTATION_PRODUCED_BY"
    echo "        contract:    $REPRESENTATION_CONTRACT"
    echo "        (row absent from $rep_out — the size of the per-bucket statistics store could not be read, so nothing was measured)"
    fail=$((fail + 1))
    failures+=("$current_scenario :: memory-log_analysis-row-missing")
else
    assert_command \
        command     "[[ '$log_analysis_bytes' -le $LOG_ANALYSIS_CEILING ]]" \
        label       "MEMORY log_analysis is $log_analysis_bytes bytes, at or below the $LOG_ANALYSIS_CEILING ceiling" \
        asserts     "$REPRESENTATION_ASSERTS" \
        produced_by "$REPRESENTATION_PRODUCED_BY" \
        contract    "$REPRESENTATION_CONTRACT"
fi
echo

############################################################
# The retained duration is the number, not the string the log line carried.
# $duration is a shared record lexical whose body carries both the source
# string and the integer the per-file index block's duration_sum read out of
# it on the same line, and every copy inherits a body able to carry what its
# source carries. No consumer of either duration-sample store reads that
# string — the percentile path sorts numerically and indexes the sorted array,
# the moments path sums and squares — so a plain copy retains 40 bytes of
# string buffer per duration that nothing will ever read.
#
# The ceiling is one-sided in the same direction as scenario 13's: a revert of
# the normalisation, at any of the five retention sites, can only make the
# store larger. Measured on this fixture over five runs of each build under
# the invocation below: 32,329 bytes retaining the string, 14,969 bytes
# retaining the number, each bit-identical across its five runs. The delta is
# 17,360 bytes, which is 40 bytes on each of the 434 retained durations. The
# 20,000-byte ceiling sits 5,031 above the normalised figure and 12,329 below
# the string one, so a hash-bucket resize cannot trip it and a revert cannot
# hide under it.
#
# log_messages moves by one 1,024-byte hash-bucket resize step between runs of
# the same build (49,875 on four runs and 48,851 on one, retaining the string),
# which is why the assertion reads log_analysis alone — the same reason
# scenario 13 gives. The per-message store's saving is read from the gate's
# before/after benchmark instead.
#
# Invocation shape: identical to scenario 13's, and for the same reasons, so
# that the two ceilings are read from the same measurement.
current_scenario="scenario-14-retained-durations-are-numbers"
echo "--- $current_scenario ---"
NUMERIC_RETENTION_CEILING=20000
NUMERIC_RETENTION_ASSERTS='Every duration the raw statistics model retains is normalised to a number at the copy, so the per-bucket store keeps no string buffer: retaining the string the log line carried costs 40 bytes per retained duration that no consumer of the store reads'
NUMERIC_RETENTION_PRODUCED_BY='named_structure_sizes() in ltl, reached through measure_memory_structures(); the retained values come from the per-bucket durations push in read_and_process_logs()'
NUMERIC_RETENTION_CONTRACT='features/561-retained-durations-as-numbers.md section The decisions carried over from the prototype section measured result, D1: the numeric normalisation happens at the copy, at each of the five retention sites'

num_out=$(mktemp)
"$LTL" --disable-progress -mem -bs 1440 -oe -V benchmark-data -n 1 \
    "$DURATION_SPREAD_FIXTURE" > "$num_out" 2>"$num_out.stderr" || true
check_capture_warnings "$num_out"

# A missing row is a hard failure: an absent row must never read as a value
# under the ceiling.
num_analysis_bytes=$(awk -F'\t' '$1 == "MEMORY" && $2 == "log_analysis" { print $3; found=1 } END { exit !found }' "$num_out") || num_analysis_bytes=""
if [[ -z "$num_analysis_bytes" ]]; then
    echo "  FAIL  $current_scenario"
    echo "        pattern:     MEMORY<TAB>log_analysis<TAB><bytes>"
    echo "        asserts:     $NUMERIC_RETENTION_ASSERTS"
    echo "        produced_by: $NUMERIC_RETENTION_PRODUCED_BY"
    echo "        contract:    $NUMERIC_RETENTION_CONTRACT"
    echo "        (row absent from $num_out — the size of the per-bucket statistics store could not be read, so nothing was measured)"
    fail=$((fail + 1))
    failures+=("$current_scenario :: memory-log_analysis-row-missing")
else
    assert_command \
        command     "[[ '$num_analysis_bytes' -le $NUMERIC_RETENTION_CEILING ]]" \
        label       "MEMORY log_analysis is $num_analysis_bytes bytes, at or below the $NUMERIC_RETENTION_CEILING ceiling the numeric retention produces" \
        asserts     "$NUMERIC_RETENTION_ASSERTS" \
        produced_by "$NUMERIC_RETENTION_PRODUCED_BY" \
        contract    "$NUMERIC_RETENTION_CONTRACT"
fi
echo

############################################################
# Retaining the number rather than the string is visible on exactly one user
# surface: `-cp full` passes a retained scalar to the file unformatted, so the
# exported duration columns now carry the number's own spelling instead of the
# log line's. On a format whose durations are written with fractional decimals
# that drops trailing zeros the line carried — `5.000` exports as `5` and
# `35.010` as `35.01`. The architect accepted that change as the trade for
# halving the two duration-sample stores.
#
# Both halves of what was accepted are asserted here, because the decision
# rests on them together: the spelling, so the accepted change is a stated
# invariant that a later change cannot silently reverse or widen; and the
# numeric equality with the spelling the log line carried, so that a
# truncation — which int($duration) would produce, and which D1 rejects for
# exactly this reason — fails rather than passes the spelling half.
#
# Invocation shape: `-o -cp full` because the export path under that one
# precision mode is the whole subject; `-bs 1440 -oe` folds the fixture's
# 11-second span into one bucket and switches off the empty-bucket fill, so
# the STATS CSV carries a single row to read; `-n 1` because no rendered row
# is read. The run gets a directory it owns, since -o writes into the CWD.
current_scenario="scenario-15-exported-spelling-on-fractional-durations"
echo "--- $current_scenario ---"
FRACTIONAL_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/access-thread-session.txt"
SPELLING_PRODUCED_BY='format_csv_value() in ltl, which returns the value unchanged under -cp full; the value is retained by the per-bucket durations push in read_and_process_logs()'
SPELLING_CONTRACT='features/561-retained-durations-as-numbers.md section The exported-spelling finding: the -cp full spelling change on fractional-duration formats is accepted, the values unchanged'

if [[ ! -f "$FRACTIONAL_FIXTURE" ]]; then
    echo "ERROR: fixture not found: $FRACTIONAL_FIXTURE"
    exit 1
fi

SPELLING_DIR="$WORKDIR/exported-spelling"
mkdir -p "$SPELLING_DIR"
# The directory a -o run writes into carries no product this harness did not
# create; a stranger is named and the run stops, never swept or deleted
# (tests/HARNESS-DESIGN.md section A harness owns the directory it runs ltl in).
stranger="$(ls "$SPELLING_DIR"/*-LTL-STATS-*.csv "$SPELLING_DIR"/*-LTL-MESSAGES-*.csv 2>/dev/null | head -1 || true)"
if [[ -n "$stranger" ]]; then
    echo "ERROR: $current_scenario: pre-existing CSV product not written by this run: $stranger"
    exit 1
fi

spell_out=$(mktemp)
( cd "$SPELLING_DIR" && "$LTL" --disable-progress -bs 1440 -oe -n 1 -o -cp full \
    "$FRACTIONAL_FIXTURE" > "$spell_out" 2>"$spell_out.stderr" ) || true
check_capture_warnings "$spell_out"

SPELLING_STATS_CSV="$(ls "$SPELLING_DIR"/*-LTL-STATS-*.csv 2>/dev/null | head -1 || true)"
if [[ -z "$SPELLING_STATS_CSV" ]]; then
    echo "  FAIL  $current_scenario"
    echo "        asserts:     A -cp full run writes the STATS CSV whose duration columns carry the retained spelling"
    echo "        produced_by: $SPELLING_PRODUCED_BY"
    echo "        contract:    $SPELLING_CONTRACT"
    echo "        (no STATS CSV in $SPELLING_DIR — nothing was measured)"
    fail=$((fail + 1))
    failures+=("$current_scenario :: stats-csv-not-written")
else
    # Read the two columns by name from the header rather than by position, so
    # a column added elsewhere in the row cannot move what is asserted. A
    # header name that matches nothing yields an empty value, which fails the
    # assertions below rather than passing them.
    csv_column() {
        awk -F',' -v want="$1" '
            NR == 1 { for (i = 1; i <= NF; i++) { h = $i; gsub(/^"|"$/, "", h); if (h == want) col = i } next }
            NR == 2 && col { v = $col; gsub(/^"|"$/, "", v); print v; found = 1 }
            END { exit !found }
        ' "$SPELLING_STATS_CSV"
    }
    dmin="$(csv_column duration_min || true)"
    dp90="$(csv_column duration_p90 || true)"

    assert_command \
        command     "[[ '$dmin' == '5' ]]" \
        label       "duration_min exports as '$dmin', the number's spelling and not the log line's 5.000" \
        asserts     'Under -cp full a retained duration reaches the file with the number spelling, so a trailing zero the log line carried is not exported' \
        produced_by "$SPELLING_PRODUCED_BY" \
        contract    "$SPELLING_CONTRACT"
    assert_command \
        command     "[[ '$dp90' == '35.01' ]]" \
        label       "duration_p90 exports as '$dp90', the number's spelling and not the log line's 35.010" \
        asserts     'Under -cp full a retained fractional duration keeps its significant digits and loses only the trailing zeros the log line carried' \
        produced_by "$SPELLING_PRODUCED_BY" \
        contract    "$SPELLING_CONTRACT"
    # The accepted change is a spelling change and nothing more: each exported
    # value still equals the spelling the log line carried. A truncation would
    # satisfy neither comparison.
    assert_command \
        command     "awk -v v='$dmin' 'BEGIN { exit !(v == 5.000) }'" \
        label       "duration_min is numerically equal to the 5.000 the log line carried" \
        asserts     'The accepted export change is a spelling change only: the exported duration equals the value the log line carried, so no consumer parsing the column numerically is affected' \
        produced_by "$SPELLING_PRODUCED_BY" \
        contract    "$SPELLING_CONTRACT"
    assert_command \
        command     "awk -v v='$dp90' 'BEGIN { exit !(v == 35.010) }'" \
        label       "duration_p90 is numerically equal to the 35.010 the log line carried" \
        asserts     'A retained fractional duration is normalised, never truncated: the exported value equals the log lines value rather than its integer part' \
        produced_by "$SPELLING_PRODUCED_BY" \
        contract    "$SPELLING_CONTRACT"
fi
echo

############################################################
echo "=== validate-statistics-demand: $pass passed, $fail failed ==="
if [[ $fail -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
exit 0
