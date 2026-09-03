#!/usr/bin/env bash
# validate-aggregate-export.sh - the YAML aggregate export -o writes beside the
# STATS CSV, observed through the file itself and -V aggregate-export
# (Issue #503).
#
# Every scenario writes the file in a scratch directory of its own, reads it
# back under a strict parser (tests/aggregate-export/validate-aggregate-export.pl
# against tests/aggregate-export/rules/keys.tsv: an unknown key is a failure),
# and ties its values to the surfaces that already print them: the run summary
# heading, the echoed option line, -V filter-summary, -V format-detection,
# -V benchmark-data, -V histogram-percentile-ticks, and the STATS CSV under
# -cp full. The last scenario walks tests/statistics-drift/scenarios.tsv over
# the CSV cache the statistics harness fills, so the file is tied to the
# NumPy/SciPy oracle through the CSV: oracle -> STATS CSV -> file.
#
# Contract: features/503-yaml-aggregate-export.md § Acceptance criteria and
# § -V aggregate-export section contract; tests/HARNESS-DESIGN.md.
#
# Invocation shape (HARNESS-DESIGN.md section Invocation coherence): the
# assertions read the file and the -V sections, so runs take the coarsest
# bucket, no empty buckets, no messages and no index (-bs 1440 -oe -n 0 -ni);
# a scenario that reads the heading or the timeline drops -osum or -n 0.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
FIXTURES="$REPO_DIR/tests/fixtures"
CHECKER="$REPO_DIR/tests/aggregate-export/validate-aggregate-export.pl"
RULES="$REPO_DIR/tests/aggregate-export/rules/keys.tsv"
SCENARIOS_TSV="$REPO_DIR/tests/statistics-drift/scenarios.tsv"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/logs-dir.sh
source "$SCRIPT_DIR/lib/logs-dir.sh"
# shellcheck source=lib/csv-cache.sh
source "$SCRIPT_DIR/lib/csv-cache.sh"
neutralize_colour_env

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"; csv_cache_maybe_cleanup' EXIT

[[ -x "$LTL" ]] || { echo "ERROR: ltl not found or not executable at $LTL"; exit 1; }
[[ -f "$RULES" ]] || { echo "ERROR: rules file missing: $RULES"; exit 1; }

ONLY_SCENARIO=""
[[ "${1:-}" == "--scenario" ]] && ONLY_SCENARIO="${2:?--scenario needs a name}"

pass=0; fail=0; failures=(); current_scenario=""
CONTRACT='features/503-yaml-aggregate-export.md section Acceptance criteria - the export exposes what the run computed, in ltl names, exact values, absent means not produced or not supported (D1, D3, D4, D12, D15, D16)'
PRODUCER='write_aggregate_export() in ltl'

want() { [[ -z "$ONLY_SCENARIO" || "$ONLY_SCENARIO" == "$1" ]]; }

fail_with() {   # label, asserts, produced_by, contract, detail
    echo "  FAIL  $current_scenario :: $1"
    echo "        asserts:     $2"
    echo "        produced_by: $3"
    echo "        contract:    $4"
    [[ -n "${5:-}" ]] && echo "        detail:      $5"
    fail=$((fail + 1)); failures+=("$current_scenario :: $1")
}
pass_with() { echo "  PASS  $current_scenario :: $1"; pass=$((pass + 1)); }

# assert_equal label left right asserts .. produced_by .. contract ..
assert_equal() {
    local label="$1" left="$2" right="$3"; shift 3
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do case "$1" in asserts) asserts="$2"; shift 2;; produced_by) produced_by="$2"; shift 2;; contract) contract="$2"; shift 2;; *) echo "assert_equal: unknown field '$1'"; exit 2;; esac; done
    : "${asserts:?}" "${produced_by:?}" "${contract:?}"
    if [[ -n "$left" && "$left" == "$right" ]]; then pass_with "$label ('$left')"; else fail_with "$label" "$asserts" "$produced_by" "$contract" "'$left' != '$right'"; fi
}
# assert_near label left right (numeric, relative 1e-12)
assert_near() {
    local label="$1" left="$2" right="$3"; shift 3
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do case "$1" in asserts) asserts="$2"; shift 2;; produced_by) produced_by="$2"; shift 2;; contract) contract="$2"; shift 2;; *) exit 2;; esac; done
    : "${asserts:?}" "${produced_by:?}" "${contract:?}"
    if [[ -n "$left" && -n "$right" ]] && perl -e 'my ($a,$b)=@ARGV; my $m = abs($a) > abs($b) ? abs($a) : abs($b); exit(($a == $b || abs($a-$b) <= 1e-12*$m) ? 0 : 1)' "$left" "$right"; then pass_with "$label ($left ~ $right)"; else fail_with "$label" "$asserts" "$produced_by" "$contract" "'$left' vs '$right'"; fi
}
# assert_absent_key path asserts .. (checker get exits 3 when absent)
assert_absent_key() {
    local path="$1"; shift
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do case "$1" in asserts) asserts="$2"; shift 2;; produced_by) produced_by="$2"; shift 2;; contract) contract="$2"; shift 2;; *) exit 2;; esac; done
    : "${asserts:?}" "${produced_by:?}" "${contract:?}"
    local rc=0; perl "$CHECKER" get --yaml "$YAML_FILE" --path "$path" >/dev/null 2>&1 || rc=$?
    if [[ $rc -eq 3 ]]; then pass_with "absent: $path"; else fail_with "absent: $path" "$asserts" "$produced_by" "$contract" "present (checker exit $rc)"; fi
}
assert_present_key() {
    local path="$1"; shift
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do case "$1" in asserts) asserts="$2"; shift 2;; produced_by) produced_by="$2"; shift 2;; contract) contract="$2"; shift 2;; *) exit 2;; esac; done
    : "${asserts:?}" "${produced_by:?}" "${contract:?}"
    local v; v="$(yget "$path")"
    if [[ -n "$v" ]]; then pass_with "present: $path = $v"; else fail_with "present: $path" "$asserts" "$produced_by" "$contract" "absent"; fi
}
# The checker's structural pass over the file.
assert_checker() {
    local out="$TMP_DIR/${current_scenario//\//_}.check"
    if perl "$CHECKER" check --rules "$RULES" --yaml "$YAML_FILE" > "$out" 2>&1; then
        pass_with "structural check: $(tail -1 "$out")"
    else
        fail_with "structural check" 'The file parses strictly, every key is named by the rules with the right type, required keys are present, percentiles sit exactly where the count supports them, and the identities hold' "$PRODUCER; tests/aggregate-export/validate-aggregate-export.pl" "$CONTRACT" "$(grep -A1 FAIL "$out" | head -6 | tr '\n' ' ')"
    fi
}
yget() { perl "$CHECKER" get --yaml "$YAML_FILE" --path "$1" 2>/dev/null || true; }
section_value() { grep -E "^$2: " "$1" | head -1 | sed -E 's/^[^:]+: //'; }
strip_colour() { sed 's/\x1b\[[0-9;]*m//g'; }

# Run ltl with -o in a scratch directory of its own; the file paths and the
# stdout capture are exported. Extra args precede the log operands.
YAML_FILE=""; STATS_CSV=""; MSG_CSV=""; OUT=""
run_export() {
    local dir="$TMP_DIR/$current_scenario"; mkdir -p "$dir"
    OUT="$dir/stdout"
    set +e
    ( cd "$dir" && "$LTL" --disable-progress -ni -o -V aggregate-export,filter-summary,format-detection,benchmark-data,histogram-percentile-ticks,profile "$@" > "$OUT" 2> "$OUT.stderr" )
    local ec=$?
    set -e
    if [[ $ec -ne 0 ]]; then echo "FAIL: ltl exited $ec for $current_scenario; stderr:" >&2; sed 's/^/    /' "$OUT.stderr" >&2; exit 1; fi
    if ! assert_no_runtime_warnings "$OUT.stderr" "$current_scenario"; then fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr"); fi
    YAML_FILE="$(ls "$dir"/*.yaml 2>/dev/null | head -1 || true)"
    STATS_CSV="$(ls "$dir"/*-LTL-STATS-*.csv 2>/dev/null | head -1 || true)"
    MSG_CSV="$(ls "$dir"/*-LTL-MESSAGES-*.csv 2>/dev/null | head -1 || true)"
    if [[ -z "$YAML_FILE" ]]; then fail_with "file written" 'A -o run writes exactly one YAML file beside the STATS CSV' "$PRODUCER" "$CONTRACT" "no .yaml in $dir"; return 1; fi
    return 0
}

echo "Validating the YAML aggregate export (Issue #503)"
echo ""

# ---------------------------------------------------------------------------
current_scenario="histogram-n0"
if want "$current_scenario"; then
    run_export -bs 1440 -oe -n 0 -cp full -hg duration -h orders "$FIXTURES/http-status-families.txt" "$FIXTURES/tomcat-access-duration-spread.txt" || true
    if [[ -n "$YAML_FILE" ]]; then
        local_count=$(ls "$TMP_DIR/$current_scenario"/*.yaml | wc -l | tr -d ' ')
        assert_equal "exactly one YAML file" "$local_count" 1 asserts 'One file per run' produced_by "$PRODUCER" contract "$CONTRACT"
        name="$(basename "$YAML_FILE")"
        if [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}-LTL-AGGREGATE\.yaml$ ]]; then pass_with "file name carries no argument text ($name)"; else fail_with "file name" 'The name is <stamp>-LTL-AGGREGATE.yaml with no argument suffix (D18)' "run_file_stamp() and $PRODUCER" "$CONTRACT" "$name"; fi
        stamp_yaml="${name%%-LTL-*}"; stamp_csv="$(basename "$STATS_CSV")"; stamp_csv="${stamp_csv%%-LTL-*}"
        assert_equal "same stamp as the STATS CSV" "$stamp_yaml" "$stamp_csv" asserts 'The YAML and the STATS CSV of one run share the stamp' produced_by 'run_file_stamp() in ltl' contract 'features/503-yaml-aggregate-export.md D18'
        assert_equal "no MESSAGES CSV under -n 0" "${MSG_CSV:-none}" none asserts '-n 0 -o writes no per-message artifact' produced_by 'pipeline_render() in ltl (#458)' contract 'features/503-yaml-aggregate-export.md R1/R3'
        assert_checker
        # -V aggregate-export
        agg="$TMP_DIR/$current_scenario.agg"; sed -n '/=== aggregate-export ===/,/=== END aggregate-export ===/p' "$OUT" > "$agg"
        assert_equal "section file" "$(section_value "$agg" file)" "$name" asserts 'The section names the file written' produced_by "$PRODUCER (-V aggregate-export)" contract 'features/503-yaml-aggregate-export.md section -V aggregate-export section contract'
        assert_equal "section bytes" "$(section_value "$agg" bytes)" "$(stat -f %z "$YAML_FILE")" asserts 'The section reports the file size' produced_by "$PRODUCER (-V aggregate-export)" contract 'features/503-yaml-aggregate-export.md section -V aggregate-export section contract'
        assert_equal "section blocks" "$(section_value "$agg" blocks)" "provenance,population,measurements.histogram,measurements,series" asserts 'With -hg the histogram block is written and named; no heatmap ran' produced_by "$PRODUCER (-V aggregate-export)" contract 'features/503-yaml-aggregate-export.md section -V aggregate-export section contract'
        assert_equal "section buckets_written" "$(section_value "$agg" buckets_written)" "$(yget series.bucket_count)" asserts 'buckets_written equals the file bucket_count' produced_by "$PRODUCER (-V aggregate-export)" contract 'features/503-yaml-aggregate-export.md section -V aggregate-export section contract'
        # cross-surface: filter-summary, format-detection / classification, benchmark-data
        for k in read:lines_read unmatched:lines_unmatched included:lines_included; do
            assert_equal "lines.${k%%:*} = filter-summary ${k##*:}" "$(yget population.lines.${k%%:*})" "$(section_value "$OUT" ${k##*:})" asserts 'The file line accounting is the -V filter-summary accounting' produced_by "$PRODUCER; emit_filter_summary_verbose() in ltl" contract "$CONTRACT (D12)"
        done
        assert_equal "lines.excluded.other = excluded_other" "$(yget population.lines.excluded.other)" "$(section_value "$OUT" excluded_other)" asserts 'Per-cause counters agree' produced_by "$PRODUCER; emit_filter_summary_verbose() in ltl" contract "$CONTRACT (D12)"
        assert_equal "lines.highlighted = lines_highlighted" "$(yget population.lines.highlighted)" "$(section_value "$OUT" lines_highlighted)" asserts 'The highlighted count is the sister row' produced_by "$PRODUCER; emit_filter_summary_verbose() in ltl" contract "$CONTRACT (D12)"
        cls="$TMP_DIR/$current_scenario.cls"; sed -n '/=== format-detection \/ classification ===/,/=== END format-detection \/ classification ===/p' "$OUT" > "$cls"
        for k in classified successes failures unclassified; do
            assert_equal "measurements.$k = classification $k" "$(yget measurements.$k)" "$(section_value "$cls" $k)" asserts 'The run-level outcome figures are classification_reconciliation() as -V format-detection prints them' produced_by "$PRODUCER; emit_format_detection_verbose() in ltl" contract "$CONTRACT (D16)"
        done
        assert_equal "non_qualifying_lines" "$(yget measurements.non_qualifying_lines)" "$(section_value "$cls" non_qualifying_lines)" asserts 'The provenance count behind eligibility agrees' produced_by "$PRODUCER; emit_format_detection_verbose() in ltl" contract "$CONTRACT (D16)"
        assert_equal "pct_eligible" "$(yget measurements.pct_eligible)" "$( [[ "$(section_value "$cls" pct_eligible)" == 1 ]] && echo true || echo false )" asserts 'Eligibility is a YAML boolean of the same state' produced_by "$PRODUCER" contract "$CONTRACT (D16)"
        assert_equal "lines.unmatched = unmatched_lines" "$(yget population.lines.unmatched)" "$(section_value "$cls" unmatched_lines)" asserts 'One unmatched counter, two surfaces' produced_by "$PRODUCER; emit_format_detection_verbose() in ltl" contract "$CONTRACT (D22)"
        ledger="$(section_value "$cls" event_ledger_files)"
        assert_equal "files_event_ledger/files_bound" "$(yget population.files_event_ledger)/$(yget population.files_bound)" "$ledger" asserts 'The two counts behind event_ledger_files N/M' produced_by "$PRODUCER; format_ledger_file_counts() in ltl" contract "$CONTRACT (D11)"
        assert_equal "rule_changes" "$(yget population.rule_changes)" "$(section_value "$cls" rule_changes)" asserts 'The mid-file rule-change count agrees' produced_by "$PRODUCER" contract "$CONTRACT (R7)"
        legend="$(section_value "$OUT" legend | tr ',' '\n' | sed 's/^[^=]*=//' | tr '\n' ',' | sed 's/,$//')"
        formats=""; i=0; while v="$(yget population.formats.$i.name)" && [[ -n "$v" ]]; do formats="${formats:+$formats,}$v"; i=$((i+1)); done
        assert_equal "formats = legend slugs" "$formats" "$legend" asserts 'population.formats lists the distinct slugs the legend names, in its order (both fixtures bind the one slug)' produced_by "$PRODUCER" contract "$CONTRACT (D10)"
        bd_read="$(grep -E '^lines_read	' "$OUT" | cut -f2)"; bd_incl="$(grep -E '^lines_included	' "$OUT" | cut -f2)"; bd_excl="$(grep -E '^lines_excluded	' "$OUT" | cut -f2)"
        assert_equal "lines.read = benchmark-data lines_read" "$(yget population.lines.read)" "$bd_read" asserts 'benchmark-data reads the same counter' produced_by "$PRODUCER; print_verbose_output() in ltl" contract 'tests/HARNESS-DESIGN.md section one source, two surfaces'
        assert_equal "lines.included = benchmark-data lines_included" "$(yget population.lines.included)" "$bd_incl" asserts 'benchmark-data reads the same counter' produced_by "$PRODUCER; print_verbose_output() in ltl" contract 'tests/HARNESS-DESIGN.md section one source, two surfaces'
        assert_equal "bucket_count = COUNTS log_occurrences_entries" "$(yget series.bucket_count)" "$(grep -E '^COUNTS	log_occurrences_entries	' "$OUT" | cut -f3)" asserts 'The series row count is the one benchmark-data counts' produced_by "$PRODUCER; print_verbose_output() in ltl" contract "$CONTRACT (F6)"
        assert_equal "version = benchmark-data version" "$(yget provenance.determining.version)" "$(grep -E '^version	' "$OUT" | cut -f2)" asserts 'Provenance carries $version_number' produced_by "$PRODUCER" contract "$CONTRACT (R4)"
        # histogram: the chart's selected percentiles at full precision
        ticks="$TMP_DIR/$current_scenario.ticks"; sed -n '/=== histogram-percentile-ticks ===/,/=== END histogram-percentile-ticks ===/p' "$OUT" > "$ticks"
        for p in P50:p50 P75:p75 P90:p90 P95:p95; do
            tv="$(grep -E "^\s+${p%%:*}=" "$ticks" | head -1 | sed 's/.*=//')"; fv="$(yget measurements.histogram.duration.${p##*:})"
            assert_near "histogram ${p##*:} = ticks ${p%%:*}" "$fv" "$tv" asserts 'The population-wide percentile is the value the histogram computed, as -V histogram-percentile-ticks prints it' produced_by "$PRODUCER; finalize_histogram_unified() in ltl" contract "$CONTRACT (D3)"
        done
        assert_equal "histogram occurrences excludes non-positive values" "$(yget measurements.histogram.duration.occurrences)" "$(section_value "$OUT" 'lines_included' | awk -v z=0 '{print $1}' | xargs -I{} sh -c 'echo $(( {} - 85 ))')" asserts 'Of the 444 included lines, 85 carry a zero duration the histogram capture gate excludes (10 in the status fixture, 75 in the spread fixture)' produced_by "$PRODUCER; read_and_process_logs() in ltl (histogram capture gate)" contract "$CONTRACT (D3, F1)"
        assert_present_key measurements.histogram.duration.highlighted.occurrences asserts 'A highlight yields the highlighted subset block' produced_by "$PRODUCER" contract "$CONTRACT (D3)"
        assert_absent_key series.buckets.0.heatmap asserts 'Without -hm no bucket carries a heatmap block' produced_by "$PRODUCER" contract "$CONTRACT (D4)"
        # gating: the two fixtures share one day, so one bucket of 444 lines
        assert_equal "one bucket of 444 lines" "$(yget series.buckets.0.duration.occurrences)" 444 asserts 'Both fixtures fall in the one 1440-minute bucket' produced_by "$PRODUCER" contract "$CONTRACT (D15: the count each block is measured against)"
        assert_present_key series.buckets.0.duration.p95 asserts 'A bucket of 444 lines carries p95 (needs 200)' produced_by "$PRODUCER" contract "$CONTRACT (D15)"
        assert_absent_key series.buckets.0.duration.p99 asserts 'A bucket of 444 lines (below the 1000 p99 needs) carries no p99' produced_by "$PRODUCER" contract "$CONTRACT (D15)"
        assert_present_key series.buckets.0.duration.p75 asserts 'p75 needs 40' produced_by "$PRODUCER" contract "$CONTRACT (D15)"
        # STATS CSV under -cp full: every shared value equal
        cmp="$TMP_DIR/$current_scenario.compare"
        if perl "$CHECKER" compare --yaml "$YAML_FILE" --csv "$STATS_CSV" > "$cmp" 2>&1; then pass_with "file = STATS CSV under -cp full: $(grep PASS "$cmp" | sed 's/^ *PASS *//')"; else fail_with "file = STATS CSV under -cp full" 'Every per-bucket value both surfaces carry is equal to the last digit' "$PRODUCER; print_bar_graph() in ltl" "$CONTRACT (D14)" "$(grep -A1 FAIL "$cmp" | head -4 | tr '\n' ' ')"; fi
        # timestamps: file = CSV column 1
        stamps=""; i=0; while v="$(yget series.buckets.$i.timestamp)" && [[ -n "$v" ]]; do stamps="${stamps:+$stamps|}$v"; i=$((i+1)); done
        assert_equal "bucket timestamps = CSV timestamps" "$stamps" "$(awk -F, 'NR>1{gsub(/"/,"",$1); print $1}' "$STATS_CSV" | paste -sd'|' -)" asserts 'Every bucket timestamp is the STATS CSV timestamp of the same row' produced_by "$PRODUCER; format_bucket_timestamp() in ltl" contract "$CONTRACT (D7/D14)"
        # options string
        opt_line="$(strip_colour < "$OUT" | grep -E '^command-line options: ' | head -1 | sed 's/^command-line options: //')"
        assert_equal "options.command-line = echoed line" "$(yget provenance.determining.options.command-line)" "$opt_line" asserts 'The option string is byte-identical to the terminal echo, colour stripped' produced_by "$PRODUCER; build_run_options_string() in ltl" contract "$CONTRACT (D5)"
        # data model and unit
        assert_equal "data_model.histogram" "$(yget provenance.determining.data_model.histogram)" bin asserts 'The histogram default model is bin' produced_by "$PRODUCER" contract "$CONTRACT (R4)"
        assert_equal "data_model.bucket_stats" "$(yget provenance.determining.data_model.bucket_stats)" raw asserts 'The bucket-stats default model is raw' produced_by "$PRODUCER" contract "$CONTRACT (R4)"
        assert_equal "duration_unit_resolved" "$(yget provenance.determining.duration_unit_resolved)" ms asserts 'Values are milliseconds' produced_by "$PRODUCER" contract "$CONTRACT (D20)"
        # no per-message content and no working directory
        if grep -q "http-status-families\|tomcat-access-duration-spread\|/store/" "$YAML_FILE"; then fail_with "no file name or path text" 'No file name, URL or message text appears in the file' "$PRODUCER" "$CONTRACT (R3)" "$(grep -m1 'http-status-families\|/store/' "$YAML_FILE")"; else pass_with "no file name, URL or message text in the file"; fi
    fi
fi

# ---------------------------------------------------------------------------
current_scenario="gating-small-bucket"
if want "$current_scenario"; then
    run_export -bs 1440 -oe -n 0 "$FIXTURES/http-status-families.txt" || true
    if [[ -n "$YAML_FILE" ]]; then
        assert_checker
        assert_equal "ten lines" "$(yget series.buckets.0.duration.occurrences)" 10 asserts 'The bucket holds the ten fixture lines' produced_by "$PRODUCER" contract "$CONTRACT (D15)"
        assert_absent_key series.buckets.0.duration.p50 asserts 'Ten lines are below the 20 p50 needs: no p50' produced_by "$PRODUCER" contract "$CONTRACT (D15)"
        assert_absent_key series.buckets.0.duration.p75 asserts 'Below the 40 p75 needs: no p75' produced_by "$PRODUCER" contract "$CONTRACT (D15)"
        for k in min mean max sum; do assert_present_key series.buckets.0.duration.$k asserts "$k is never withheld" produced_by "$PRODUCER" contract "$CONTRACT (D15)"; done
        assert_equal "percentiles_gated counts them" "$(sed -n '/=== aggregate-export ===/,/=== END aggregate-export ===/p' "$OUT" | section_value /dev/stdin percentiles_gated)" 12 asserts 'Every one of the twelve ladder slugs is withheld on a ten-line bucket, and the section counts them' produced_by "$PRODUCER (-V aggregate-export)" contract 'features/503-yaml-aggregate-export.md section -V aggregate-export section contract'
    fi
fi

# ---------------------------------------------------------------------------
current_scenario="no-surfaces"
if want "$current_scenario"; then
    run_export -bs 1440 -oe -n 0 "$FIXTURES/tomcat-access-duration-spread.txt" || true
    if [[ -n "$YAML_FILE" ]]; then
        assert_checker
        assert_absent_key measurements.histogram asserts 'Without -hg there are no population-wide percentiles' produced_by "$PRODUCER" contract "$CONTRACT (D3)"

        assert_absent_key series.buckets.0.heatmap asserts 'Without -hm no bucket carries a heatmap block' produced_by "$PRODUCER" contract "$CONTRACT (D4)"
        agg="$TMP_DIR/$current_scenario.agg"; sed -n '/=== aggregate-export ===/,/=== END aggregate-export ===/p' "$OUT" > "$agg"
        assert_equal "section blocks" "$(section_value "$agg" blocks)" "provenance,population,measurements,series" asserts 'Only the four blocks are written' produced_by "$PRODUCER (-V aggregate-export)" contract 'features/503-yaml-aggregate-export.md section -V aggregate-export section contract'
        assert_absent_key population.lines.highlighted asserts 'No highlight, no highlighted count' produced_by "$PRODUCER" contract "$CONTRACT (R9)"
        assert_absent_key population.lines.excluded.time_window asserts 'No window given, no time_window key' produced_by "$PRODUCER" contract "$CONTRACT (D12: a key is present when its cause was active)"
    fi
fi

# ---------------------------------------------------------------------------
current_scenario="profile-week-heading"
if want "$current_scenario"; then
    run_export -bs 60 -pr week "$FIXTURES/profile-weekend-fold.txt" || true
    if [[ -n "$YAML_FILE" ]]; then
        assert_checker
        heading="$(strip_colour < "$OUT" | grep 'spanning' | head -1 | sed 's/.*spanning //' | sed 's/ *$//' || true)"
        assert_equal "observation.start/end = heading" "$(yget population.observation.start) to $(yget population.observation.end)" "$heading" asserts 'The window is the two strings the run summary heading prints; under -pr the heading reads spanning <start> to <end> in the folded day/time form' produced_by "$PRODUCER; format_observation_timestamp() in ltl" contract "$CONTRACT (D7, D8)"
        assert_equal "duration_seconds" "$(yget population.observation.duration_seconds)" 345600 asserts 'Wednesday 10:00 to Sunday 10:00 is four days' produced_by "$PRODUCER" contract "$CONTRACT (D13)"
        assert_equal "duration" "$(yget population.observation.duration)" "4 days" asserts 'The long form at three significant digits, plural' produced_by "$PRODUCER; format_time() in ltl" contract "$CONTRACT (D13)"
        assert_equal "profile" "$(yget provenance.determining.profile)" week asserts 'The fold mode is recorded' produced_by "$PRODUCER" contract "$CONTRACT (D8)"
        assert_equal "excluded.profile = samples_dropped" "$(yget population.lines.excluded.profile)" "$(section_value "$OUT" samples_dropped)" asserts 'The fold cause reads -V profile samples_dropped' produced_by "$PRODUCER; emit_profile_verbose() in ltl" contract "$CONTRACT (D12)"
        assert_equal "bucket timestamp = CSV timestamp (folded)" "$(yget series.buckets.0.timestamp)" "$(awk -F, 'NR==2{gsub(/"/,"",$1); print $1}' "$STATS_CSV")" asserts 'Under -pr the bucket timestamp is the folded string the CSV writes' produced_by "$PRODUCER; format_bucket_timestamp() in ltl" contract "$CONTRACT (D8)"
    fi
fi

# ---------------------------------------------------------------------------
current_scenario="seconds-heading"
if want "$current_scenario"; then
    run_export -bs 1 -s "$FIXTURES/http-status-families.txt" || true
    if [[ -n "$YAML_FILE" ]]; then
        assert_checker
        heading="$(strip_colour < "$OUT" | grep -A1 'results between' | tail -1 | sed 's/[─ ]*//' | sed 's/^ *//;s/ *$//' || true)"
        assert_equal "observation.start/end = heading (-s)" "$(yget population.observation.start) and $(yget population.observation.end)" "$heading" asserts 'Under -s the bounds carry seconds, as the heading does' produced_by "$PRODUCER; format_observation_timestamp() in ltl" contract "$CONTRACT (D7)"
        assert_equal "duration_seconds" "$(yget population.observation.duration_seconds)" 9 asserts 'Ten lines one second apart span nine seconds' produced_by "$PRODUCER" contract "$CONTRACT (D13)"
        assert_equal "duration" "$(yget population.observation.duration)" "9 seconds" asserts 'The long form' produced_by "$PRODUCER; format_time() in ltl" contract "$CONTRACT (D13)"
    fi
fi

# ---------------------------------------------------------------------------
current_scenario="precision-not-csv"
if want "$current_scenario"; then
    run_export -bs 1440 -oe -n 0 "$FIXTURES/tomcat-access-duration-spread.txt" || true
    if [[ -n "$YAML_FILE" ]]; then
        col=$(head -1 "$STATS_CSV" | tr ',' '\n' | grep -n '^duration_mean$' | cut -d: -f1)
        csv_mean="$(awk -F, -v c="$col" 'NR==2{print $c}' "$STATS_CSV")"; file_mean="$(yget series.buckets.0.duration.mean)"
        if [[ "$file_mean" != "$csv_mean" && "$file_mean" == *.* ]]; then pass_with "duration.mean is the in-memory value ($file_mean), not the default -cp rendering ($csv_mean)"; else fail_with "precision" 'No value passes through format_csv_value(): the file differs from the default -cp CSV on a fractional mean' "$PRODUCER" "$CONTRACT (R12)" "file $file_mean csv $csv_mean"; fi
    fi
fi


# ---------------------------------------------------------------------------
current_scenario="users-and-highlight-twins"
if want "$current_scenario"; then
    # #444 D13: whatever is captured as a metric is exported. With a highlight
    # the sessions and users scalars gain their _hl twins; without one neither
    # twin is written.
    USERS_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/access-users-sessions.txt"
    run_export -bs 1440 -oe -n 0 -h alice "$USERS_FIXTURE" || true
    if [[ -n "$YAML_FILE" ]]; then
        assert_equal "users" "$(yget series.buckets.0.users)" 3 asserts 'The users scalar: three distinct remote users in the day bucket' produced_by "$PRODUCER" contract 'features/444-access-log-format-family-and-user-surface.md D10/D13'
        assert_equal "users_hl" "$(yget series.buckets.0.users_hl)" 1 asserts 'The highlighted twin under -h alice: one highlighted user' produced_by "$PRODUCER" contract 'features/444-access-log-format-family-and-user-surface.md D13'
        assert_equal "sessions_hl" "$(yget series.buckets.0.sessions_hl)" 3 asserts 'The sessions twin under the same highlight: alice holds three sessions across her lines' produced_by "$PRODUCER" contract 'features/444-access-log-format-family-and-user-surface.md D13'
    fi
    run_export -bs 1440 -oe -n 0 "$USERS_FIXTURE" || true
    if [[ -n "$YAML_FILE" ]]; then
        assert_equal "no users_hl without a highlight" "$(yget series.buckets.0.users_hl)|$(yget series.buckets.0.sessions_hl)" "|" asserts 'Without a highlight neither twin is written' produced_by "$PRODUCER" contract 'features/444-access-log-format-family-and-user-surface.md D13'
    fi
fi

# ---------------------------------------------------------------------------
current_scenario="directories-relative"
if want "$current_scenario"; then
    dir="$TMP_DIR/$current_scenario"; mkdir -p "$dir"; OUT="$dir/stdout"
    set +e
    ( cd "$REPO_DIR" && "$LTL" --disable-progress -ni -o -bs 1440 -oe -n 0 -osum tests/fixtures/http-status-families.txt tests/fixtures/category-contribution-skew.txt > "$OUT" 2> "$OUT.stderr" )
    ec=$?; set -e
    [[ $ec -eq 0 ]] || { echo "FAIL: ltl exited $ec for $current_scenario" >&2; sed 's/^/    /' "$OUT.stderr" >&2; exit 1; }
    assert_no_runtime_warnings "$OUT.stderr" "$current_scenario" || { fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr"); }
    # the run wrote into the repository root: move the products out at once
    for f in "$REPO_DIR"/*-LTL-AGGREGATE.yaml "$REPO_DIR"/*-LTL-STATS-*.csv; do [[ -f "$f" ]] && mv "$f" "$dir/"; done
    YAML_FILE="$(ls "$dir"/*.yaml | head -1)"
    assert_equal "directory_list" "$(yget population.sources.directory_list.0)|$(yget population.sources.directories)" "tests/fixtures|1" asserts 'Relative paths as given, file part removed, de-duplicated; the count counts the list' produced_by "$PRODUCER" contract "$CONTRACT (D9)"
    assert_equal "files/files_matched" "$(yget population.sources.files)/$(yget population.sources.files_matched)" "2/2" asserts 'Two files read, both contributed an included line' produced_by "$PRODUCER" contract "$CONTRACT (R8)"
    if grep -q "$REPO_DIR" "$YAML_FILE"; then fail_with "no working directory" 'The working directory never appears in the file' "$PRODUCER" "$CONTRACT (D9)" "$(grep -m1 "$REPO_DIR" "$YAML_FILE")"; else pass_with "the working directory appears nowhere in the file"; fi
fi
current_scenario="directories-absolute"
if want "$current_scenario"; then
    run_export -bs 1440 -oe -n 0 "$FIXTURES/http-status-families.txt" || true
    [[ -n "$YAML_FILE" ]] && assert_equal "directory_list (absolute)" "$(yget population.sources.directory_list.0)" "$FIXTURES" asserts 'An absolute path yields its absolute directory part' produced_by "$PRODUCER" contract "$CONTRACT (D9)"
fi

# ---------------------------------------------------------------------------
current_scenario="environment-options"
if want "$current_scenario"; then
    dir="$TMP_DIR/$current_scenario"; mkdir -p "$dir"; OUT="$dir/stdout"
    set +e
    ( cd "$dir" && LTL_CONFIG="-oe" "$LTL" --disable-progress -ni -o -bs 1440 -n 0 "$FIXTURES/http-status-families.txt" > "$OUT" 2> "$OUT.stderr" )
    ec=$?; set -e
    [[ $ec -eq 0 ]] || { echo "FAIL: ltl exited $ec for $current_scenario" >&2; exit 1; }
    assert_no_runtime_warnings "$OUT.stderr" "$current_scenario" || { fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr"); }
    YAML_FILE="$(ls "$dir"/*.yaml | head -1)"
    env_line="$(strip_colour < "$OUT" | grep -E '^environment options: ' | head -1 | sed 's/^environment options: //')"
    assert_equal "options.environment = echoed line" "$(yget provenance.determining.options.environment)" "$env_line" asserts 'The environment option string is the text after environment options:' produced_by "$PRODUCER" contract "$CONTRACT (D5)"
    assert_equal "omit_empty from the environment" "$(yget series.omit_empty)" true asserts 'The option took effect and the series records it' produced_by "$PRODUCER" contract "$CONTRACT (R2)"
fi

# ---------------------------------------------------------------------------
current_scenario="heatmap-vs-bucket-store-pinned"
if want "$current_scenario"; then
    # Both surfaces on the bin model at the tier where they share bins per
    # decade (tier 7: 616 on both), so the heatmap ladder and the bucket store's
    # duration percentiles are the same computation over the same values.
    run_export -bs 1440 -oe -n 0 -cp full -hm duration -bdm bin -dmp 7 "$FIXTURES/tomcat-access-duration-spread.txt" || true
    if [[ -n "$YAML_FILE" ]]; then
        assert_checker
        assert_equal "bins per decade equal on both surfaces" "$(yget provenance.determining.data_model.heatmap)/$(yget provenance.determining.data_model.bucket_stats)/$(yget provenance.determining.data_model.precision)" "bin/bin/7" asserts 'The scenario pins both surfaces to bin at tier 7' produced_by "$PRODUCER" contract "$CONTRACT (open item: bins-per-decade)"
        assert_equal "heatmap block nests its metric" "$(yget series.buckets.0.heatmap.duration.data_model)/$(yget series.buckets.0.heatmap.duration.occurrences)" "bin/349" asserts 'The bucket heatmap block is heatmap.<metric>.<key>, the histogram shape, with the model and the partition count inside; the partition holds the 349 positive durations of the 434 (the capture gate excludes non-positive values, as the histogram does)' produced_by "$PRODUCER" contract "$CONTRACT (D4; architect 2026-09-03: the metric a level below heatmap)"
        assert_absent_key series.buckets.0.heatmap.occurrences asserts 'No key sits directly under heatmap: the metric level is mandatory' produced_by "$PRODUCER" contract "$CONTRACT (D4)"
        # the section's ladder line equals the file's block for the first bucket
        ladder="$(sed -n '/=== aggregate-export \/ heatmap-ladder ===/,/=== END aggregate-export \/ heatmap-ladder ===/p' "$OUT" | sed -n 2p)"
        assert_equal "heatmap-ladder line: timestamp and metric" "$(echo "$ladder" | cut -f1,2)" "$(yget series.buckets.0.timestamp)	metric=duration" asserts 'One line per bucket: timestamp, metric, then the values' produced_by "$PRODUCER (-V aggregate-export / heatmap-ladder)" contract 'features/503-yaml-aggregate-export.md section -V aggregate-export section contract'
        for kv in $(echo "$ladder" | cut -f3- ); do
            k="${kv%%=*}"; v="${kv#*=}"; fv="$(yget series.buckets.0.heatmap.duration.$k)"
            [[ -z "$fv" ]] && continue   # gated in the file, printed on the section
            assert_near "bucket 0 heatmap.duration.$k = ladder line" "$fv" "$v" asserts 'The file carries the values the section prints' produced_by "$PRODUCER" contract "$CONTRACT (D4)"
        done
        n=0
        for p in p25 p50 p75 p90 p95; do
            hv="$(yget series.buckets.0.heatmap.duration.$p)"; dv="$(yget series.buckets.0.duration.$p)"
            [[ -z "$hv" || -z "$dv" ]] && continue
            assert_near "heatmap.$p = duration.$p" "$hv" "$dv" asserts 'Same model, same bins per decade, same values: the two ladders agree' produced_by "$PRODUCER; finalize_heatmap_unified() and calculate_statistics_bin() in ltl" contract "$CONTRACT (D4)"; n=$((n+1))
        done
        [[ $n -gt 0 ]] || fail_with "heatmap vs bucket store" 'At least one percentile compared' "$PRODUCER" "$CONTRACT (D4)" "no shared percentile present"
    fi
fi

# ---------------------------------------------------------------------------
# The oracle chain: every statistics-drift scenario's file against its STATS
# CSV from the same cached run (the CSV the statistics harness validates
# against its NumPy/SciPy oracle).
current_scenario="oracle-chain"
if want "$current_scenario"; then
    rows=0
    while IFS=$'\t' read -r scenario logfile options; do
        [[ -z "$scenario" || "$scenario" == \#* ]] && continue
        rows=$((rows + 1))
        current_scenario="oracle-chain/$scenario"
        abs_log="$(resolve_log_path "$logfile")"
        log_shorthand="$(csv_cache_logfile_shorthand "$logfile")"
        set +e; csv_cache_produce "$scenario" "$logfile" "$options" "$log_shorthand"; rc=$?; set -e
        if [[ $rc -ne 0 ]]; then fail_with "csv cache" 'The cached run exists' 'tests/lib/csv-cache.sh' "$CONTRACT" "csv_cache_produce rc=$rc"; continue; fi
        YAML_FILE="$CSV_CACHE_AGGREGATE"
        assert_checker
        cmp="$TMP_DIR/oracle-$scenario.compare"
        if perl "$CHECKER" compare --yaml "$YAML_FILE" --csv "$CSV_CACHE_STATS" > "$cmp" 2>&1; then pass_with "file = STATS CSV: $(grep PASS "$cmp" | sed 's/^ *PASS *//')"; else fail_with "file = STATS CSV" 'Every per-bucket value both carry is equal to the last digit; the CSV is the row the statistics harness ties to its oracle' "$PRODUCER" "$CONTRACT (oracle -> STATS CSV -> file)" "$(grep -A1 FAIL "$cmp" | head -4 | tr '\n' ' ')"; fi
    done < <(grep -v '^#' "$SCENARIOS_TSV")
    current_scenario="oracle-chain"
    [[ $rows -gt 0 ]] || fail_with "scenarios" 'scenarios.tsv has rows' 'tests/statistics-drift/scenarios.tsv' "$CONTRACT"
fi

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then echo "Failures:"; for f in "${failures[@]}"; do echo "  - $f"; done; exit 1; fi
echo "ALL AGGREGATE-EXPORT TESTS PASSED"
