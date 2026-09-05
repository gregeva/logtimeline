#!/usr/bin/env bash
# validate-bucket-size-units.sh — Validate the unit form of -bs/--bucket-size
# and the one time-unit ladder every time-unit surface reads (issue #524).
#
# Contract: features/524-bucket-size-unit.md (D1 one ladder, D2 the ladder
# and its spellings, D3 the -bs grammar, D4 width and precision separate,
# D5 documentation) and its Acceptance criteria. The surfaces read are the
# existing `-V runtime-config` (`bucket-size:` row) and `-V benchmark-data`
# (`CONFIG time_bucket_size` / `CONFIG bucket_size_seconds` rows); the
# harness file name tracks the surface under test rather than a section
# because the criteria compare whole runs.
#
# Usage: ./tests/validate-bucket-size-units.sh
#
# Implements the self-documenting-assertion design from
# tests/HARNESS-DESIGN.md. Reference: tests/validate-runtime-config.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited).
neutralize_colour_env

# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# every criterion compares the timeline text and the resolved bucket width,
# so each run keeps the timeline and nothing else: no index, no empty
# buckets, no summary, no messages, a pinned width. The five-line fixture
# spans Wednesday to Sunday, so day-, week- and month-wide buckets all
# produce rows; the four-line display fixture carries one duration per
# ladder step above a day plus one sub-microsecond value under -du ns.
SPAN_FIXTURE="$REPO_DIR/tests/fixtures/profile-weekend-fold.txt"
DISPLAY_FIXTURE="$REPO_DIR/tests/fixtures/bucket-size-units.txt"
COMMON=(--disable-progress -ni -oe -osum -n 0 --terminal-width 160)

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

for f in "$LTL" "$SPAN_FIXTURE" "$DISPLAY_FIXTURE"; do
    if [[ ! -e "$f" ]]; then
        echo "ERROR: required file missing: $f" >&2
        exit 1
    fi
done

CONTRACT_D1='features/524-bucket-size-unit.md D1 (one time-unit ladder at file scope, read by every time-unit surface)'
CONTRACT_D2='features/524-bucket-size-unit.md D2 (the ladder and its spellings; m is minute; month 30 days, year 365 days)'
CONTRACT_D3='features/524-bucket-size-unit.md D3 (-bs <number>[<unit>]; bare number unchanged; rejections)'
CONTRACT_D4='features/524-bucket-size-unit.md D4 (bucket width and timestamp precision are separate)'

pass=0
fail=0
failures=()
current_scenario=""

fail_with() {
    # fail_with LABEL ASSERTS PRODUCED_BY CONTRACT [DETAIL...]
    local label="$1" asserts="$2" produced_by="$3" contract="$4"
    shift 4
    echo "  FAIL  $current_scenario :: $label"
    echo "        asserts:     $asserts"
    echo "        produced_by: $produced_by"
    echo "        contract:    $contract"
    local d
    for d in "$@"; do echo "        $d"; done
    fail=$((fail + 1))
    failures+=("$current_scenario :: $label")
}

pass_with() {
    echo "  PASS  $current_scenario :: $1"
    pass=$((pass + 1))
}

# run_ltl TAG ARGS... — runs ltl, captures stdout to $TMP_DIR/TAG.out and
# stderr to $TMP_DIR/TAG.err, records the exit code in $TMP_DIR/TAG.rc, and
# applies the runtime-warning check. Never exits the harness on a non-zero
# ltl exit: the rejection scenarios assert on it.
run_ltl() {
    local tag="$1"; shift
    set +e
    "$LTL" "$@" > "$TMP_DIR/$tag.out" 2> "$TMP_DIR/$tag.err"
    echo $? > "$TMP_DIR/$tag.rc"
    set -e
    if ! assert_no_runtime_warnings "$TMP_DIR/$tag.err" "$current_scenario/$tag"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: runtime warnings ($tag)")
    fi
}

# timeline_text FILE — the rendered run without the echoed options line,
# which is the one line that legitimately differs between two equivalent
# invocations.
timeline_text() {
    sed -E 's/\x1b\[[0-9;]*m//g' "$1" | grep -vE '^(command-line|environment) options: '
}

# benchmark_row FILE KEY — the value of one CONFIG row of -V benchmark-data;
# a missing anchor is a hard failure (tests/HARNESS-DESIGN.md Trap 3/4).
benchmark_row() {
    local file="$1" key="$2" value
    value=$(awk -F'\t' -v k="$key" '$1 == "CONFIG" && $2 == k { print $3 }' "$file")
    if [[ -z "$value" ]]; then
        echo "MISSING-ANCHOR:$key"
    else
        echo "$value"
    fi
}

# ---------------------------------------------------------------------------
# Criteria 1, 2, 3, 7 — a unit form and a bare number are the same run
# ---------------------------------------------------------------------------
# Each row: scenario | args A | args B | compare (timeline+seconds or seconds)
EQUIVALENCES=(
    "day-unit-vs-minutes|-bs 1d|-bs 1440|full"
    "hours-vs-minutes|-bs 24h|-bs 1440|full"
    "seconds-run-minute-unit|-s -bs 2m|-s -bs 120|full"
    "ms-run-second-unit|-ms -bs 1s|-ms -bs 1000|full"
    "hour-unit-vs-seconds-run|-bs 1h|-s -bs 3600|seconds"
    "decimal-hours|-bs 1.5h|-bs 90|full"
    "m-is-minute|-bs 1m|-bs 1|full"
    "month-is-thirty-days|-bs 1month|-bs 43200|full"
    "half-month|-bs 0.5month|-bs 21600|full"
    "uppercase-m-is-minute|-bs 1M|-bs 1|full"
    "seconds-run-90s|-s -bs 90s|-s -bs 90|full"
    "ms-run-500ms|-ms -bs 500ms|-ms -bs 500|full"
)

for row in "${EQUIVALENCES[@]}"; do
    IFS='|' read -r name args_a args_b mode <<< "$row"
    current_scenario="equivalence/$name"
    # shellcheck disable=SC2086
    run_ltl a "${COMMON[@]}" $args_a "$SPAN_FIXTURE"
    # shellcheck disable=SC2086
    run_ltl b "${COMMON[@]}" $args_b "$SPAN_FIXTURE"
    # shellcheck disable=SC2086
    run_ltl av "${COMMON[@]}" $args_a -V benchmark-data "$SPAN_FIXTURE"
    # shellcheck disable=SC2086
    run_ltl bv "${COMMON[@]}" $args_b -V benchmark-data "$SPAN_FIXTURE"

    for t in a b av bv; do
        if [[ "$(cat "$TMP_DIR/$t.rc")" != 0 ]]; then
            fail_with "run $t exits 0" \
                "both '$args_a' and '$args_b' are accepted invocations" \
                'adapt_to_command_line_options() in ltl (bucket-size resolution)' \
                "$CONTRACT_D3" "exit: $(cat "$TMP_DIR/$t.rc")" "stderr: $(head -3 "$TMP_DIR/$t.err")"
        fi
    done

    sec_a=$(benchmark_row "$TMP_DIR/av.out" bucket_size_seconds)
    sec_b=$(benchmark_row "$TMP_DIR/bv.out" bucket_size_seconds)
    if [[ "$sec_a" == "$sec_b" && "$sec_a" != MISSING-ANCHOR:* ]]; then
        pass_with "bucket_size_seconds agree ($sec_a) for '$args_a' and '$args_b'"
    else
        fail_with "bucket_size_seconds agree for '$args_a' and '$args_b'" \
            "a bucket width given with a unit resolves to the same number of seconds as the bare number in the run's unit" \
            'adapt_to_command_line_options() and adapt_to_terminal_settings() in ltl' \
            "$CONTRACT_D3" "a: $sec_a" "b: $sec_b"
    fi

    if [[ "$mode" == "full" ]]; then
        if diff -q <(timeline_text "$TMP_DIR/a.out") <(timeline_text "$TMP_DIR/b.out") > /dev/null; then
            pass_with "timeline byte-identical for '$args_a' and '$args_b'"
        else
            fail_with "timeline byte-identical for '$args_a' and '$args_b'" \
                "the rendered timeline of a unit-form bucket width is byte-identical to the bare-number form (the echoed options line excepted)" \
                'print_bar_graph() in ltl, fed by the resolved bucket width' \
                "$CONTRACT_D3; $CONTRACT_D4" \
                "$(diff <(timeline_text "$TMP_DIR/a.out") <(timeline_text "$TMP_DIR/b.out") | head -6 | tr '\n' '~')"
        fi
    fi
done

# ---------------------------------------------------------------------------
# Criterion 7 — a unit never changes the timestamp precision
# ---------------------------------------------------------------------------
current_scenario="precision/90s-on-minute-run"
run_ltl p "${COMMON[@]}" -bs 90s "$SPAN_FIXTURE"
run_ltl pv "${COMMON[@]}" -bs 90s -V benchmark-data "$SPAN_FIXTURE"
if grep -qE '^ 2025-05-[0-9]{2} [0-9]{2}:[0-9]{2} ' "$TMP_DIR/p.out" \
   && ! grep -qE '^ 2025-05-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' "$TMP_DIR/p.out"; then
    pass_with "rows labelled at minute precision under -bs 90s"
else
    fail_with "rows labelled at minute precision under -bs 90s" \
        "a unit on -bs sets the bucket width only; without -s the timeline keeps minute-precision labels" \
        'print_bar_graph() in ltl (timestamp label precision from -s/-ms)' \
        "$CONTRACT_D4" "$(grep -E '^ 2025' "$TMP_DIR/p.out" | head -3 | cut -c1-40 | tr '\n' '~')"
fi
sec_p=$(benchmark_row "$TMP_DIR/pv.out" bucket_size_seconds)
if [[ "$sec_p" == "90.00" ]]; then
    pass_with "bucket_size_seconds is 90.00 under -bs 90s"
else
    fail_with "bucket_size_seconds is 90.00 under -bs 90s" \
        "-bs 90s on a minute run resolves to a 90-second bucket (1.5 in the run's unit)" \
        'adapt_to_terminal_settings() in ltl' "$CONTRACT_D3" "got: $sec_p"
fi

# ---------------------------------------------------------------------------
# Criterion 8 — the -V rows report the resolved value in the run's unit
# ---------------------------------------------------------------------------
check_v_rows() {
    # check_v_rows TAG ARGS EXPECTED
    local tag="$1" args="$2" expected="$3"
    current_scenario="verbose-rows/$tag"
    # shellcheck disable=SC2086
    run_ltl v "${COMMON[@]}" $args -V runtime-config,benchmark-data "$SPAN_FIXTURE"
    if grep -qE "^bucket-size: ${expected}\$" "$TMP_DIR/v.out"; then
        pass_with "runtime-config bucket-size: $expected for '$args'"
    else
        fail_with "runtime-config bucket-size: $expected for '$args'" \
            "-V runtime-config reports the resolved bucket width in the run's unit, decimals only when fractional" \
            'emit_runtime_config_verbose() in ltl' "$CONTRACT_D3" \
            "got: $(grep -E '^bucket-size:' "$TMP_DIR/v.out" || echo '(no bucket-size row)')"
    fi
    local tbs
    tbs=$(benchmark_row "$TMP_DIR/v.out" time_bucket_size)
    if [[ "$tbs" == "$expected" ]]; then
        pass_with "benchmark-data time_bucket_size $expected for '$args'"
    else
        fail_with "benchmark-data time_bucket_size $expected for '$args'" \
            "-V benchmark-data CONFIG time_bucket_size agrees with runtime-config: resolved value, decimals only when fractional" \
            'emit_benchmark_data() in ltl' "$CONTRACT_D3" "got: $tbs"
    fi
}
check_v_rows day-in-minutes "-bs 1d" 1440
check_v_rows fractional-minutes "-bs 90s" 1.5
check_v_rows bare-number "-bs 5" 5

# ---------------------------------------------------------------------------
# Criterion 6 — rejections
# ---------------------------------------------------------------------------
for bad in "5x" "d" "1.2.3h" "-1h" "0h"; do
    current_scenario="rejection/-bs $bad"
    run_ltl r "${COMMON[@]}" -bs "$bad" "$SPAN_FIXTURE"
    rc=$(cat "$TMP_DIR/r.rc")
    if [[ "$rc" != 0 ]] && grep -qE 'Invalid bucket size' "$TMP_DIR/r.err" \
       && grep -qE 'ns, us, ms, s, m, h, d, w, month, year' "$TMP_DIR/r.err"; then
        pass_with "-bs $bad rejected with the accepted forms named (exit $rc)"
    else
        fail_with "-bs $bad rejected with the accepted forms named" \
            "an unreadable bucket width (unknown unit, no number, malformed number, zero or negative width with a unit) exits non-zero with a usage line naming the accepted forms" \
            'adapt_to_command_line_options() in ltl (bucket-size validation, beside the -du and -ru rejections)' \
            "$CONTRACT_D3" "exit: $rc" "stderr: $(grep -iE 'invalid|error' "$TMP_DIR/r.err" | head -2 | tr '\n' '~')"
    fi
done

current_scenario="rejection/bare-number-control"
run_ltl c "${COMMON[@]}" -bs 5 "$SPAN_FIXTURE"
if [[ "$(cat "$TMP_DIR/c.rc")" == 0 ]]; then
    pass_with "a bare number is never rejected"
else
    fail_with "a bare number is never rejected" \
        "-bs 5 keeps today's meaning and exit code" \
        'adapt_to_command_line_options() in ltl' "$CONTRACT_D3" "exit: $(cat "$TMP_DIR/c.rc")"
fi

# ---------------------------------------------------------------------------
# Criterion 5 — one mechanism: every ladder spelling on every surface
# ---------------------------------------------------------------------------
LADDER_SPELLINGS=(ns nsec us usec ms msec s sec second seconds m min minute minutes
                  h hr hour hours d day days w wk week weeks month mo mon months
                  year y yr years D H MIN Sec)
current_scenario="one-mechanism/spellings"
spelling_failures=0
for u in "${LADDER_SPELLINGS[@]}"; do
    # The four parsing surfaces. -udm names the value in the line's last field
    # so the unit slot is exercised on a real conversion.
    run_ltl s-bs  "${COMMON[@]}" -bs "1$u" "$SPAN_FIXTURE"
    run_ltl s-du  "${COMMON[@]}" -bs 1440 -du "$u" "$SPAN_FIXTURE"
    run_ltl s-ru  "${COMMON[@]}" -bs 1440 -ru "$u" "$SPAN_FIXTURE"
    # 'min' is also an aggregation name, and the metric parser reads a
    # function name in the unit slot as a mis-slotted function (a rule of
    # features/user-defined-metrics.md); the unit slot is exercised with
    # every other spelling, and the exception is recorded in
    # features/524-bucket-size-unit.md.
    if [[ "$u" == min ]]; then
        run_ltl s-udm "${COMMON[@]}" -bs 1440 -udm "x:minutes:max:/ ([0-9]+)\$/" -V udm-specs "$SPAN_FIXTURE"
    else
        run_ltl s-udm "${COMMON[@]}" -bs 1440 -udm "x:$u:max:/ ([0-9]+)\$/" -V udm-specs "$SPAN_FIXTURE"
    fi
    for t in s-bs s-du s-ru s-udm; do
        if [[ "$(cat "$TMP_DIR/$t.rc")" != 0 ]]; then
            spelling_failures=$((spelling_failures + 1))
            echo "        spelling '$u' rejected on $t: $(grep -iE 'invalid|error|warning' "$TMP_DIR/$t.err" | head -1)"
        fi
    done
    if ! grep -qE '^  read_as: unit=[a-z]+\(time\)' "$TMP_DIR/s-udm.out"; then
        spelling_failures=$((spelling_failures + 1))
        echo "        spelling '$u' not read as a time unit by -udm: $(grep -E '^  read_as:' "$TMP_DIR/s-udm.out" || echo '(no read_as row)')"
    fi
done
if [[ "$spelling_failures" -eq 0 ]]; then
    pass_with "every ladder spelling is accepted by -bs, -du, -ru and the -udm unit slot"
else
    fail_with "every ladder spelling is accepted by -bs, -du, -ru and the -udm unit slot" \
        "the parsing surfaces are mutually sufficient: every spelling one accepts, all accept, case-insensitively" \
        'time_unit_canonical() in ltl, called by adapt_to_command_line_options() and parse_udm_configs()' \
        "$CONTRACT_D1; $CONTRACT_D2" "spellings failing: $spelling_failures"
fi

current_scenario="one-mechanism/udm-day-matches-bs-day"
run_ltl m "${COMMON[@]}" -bs 1d -udm 'days:d:max:/ ([0-9]+)$/' -V udm-specs,benchmark-data "$SPAN_FIXTURE"
sec_day=$(benchmark_row "$TMP_DIR/m.out" bucket_size_seconds)
# The grep's no-match exit is diagnostic here (an empty value is asserted on
# below), so it must not abort the harness under pipefail (HARNESS-DESIGN.md Trap 8).
udm_max=$({ grep -E '^  produced: ' "$TMP_DIR/m.out" || true; } | sed -nE 's/.* max=([0-9.]+).*/\1/p')
# Every fixture line ends in the duration 11: eleven days through the metric
# multiplier must equal eleven of the seconds -bs 1d resolves to, in ms.
expected_max=$(awk -v s="$sec_day" 'BEGIN { printf "%d", 11 * s * 1000 }')
if grep -qE '^  read_as: unit=d\(time\)' "$TMP_DIR/m.out" && [[ -n "$udm_max" && "$udm_max" == "$expected_max" ]]; then
    pass_with "-udm days:d:max converts 11 days by the multiplier -bs 1d resolves with ($udm_max ms)"
else
    fail_with "-udm days:d:max converts by the multiplier -bs 1d resolves with" \
        "the metric unit slot and -bs share one conversion: a value of 11 days in -udm equals eleven of the seconds -bs 1d resolves to, in milliseconds" \
        'convert_duration_to_ms() in ltl, called from parse_udm_configs() and the -bs resolution' \
        "$CONTRACT_D1" "read_as: $(grep -E '^  read_as:' "$TMP_DIR/m.out" || echo none)" "udm max: ${udm_max:-none}" "expected: $expected_max (bucket_size_seconds $sec_day)"
fi

current_scenario="one-mechanism/ru-week-matches-bs-week"
mkdir -p "$TMP_DIR/csv" && cp "$SPAN_FIXTURE" "$TMP_DIR/csv/span.txt"
( cd "$TMP_DIR/csv" && "$LTL" "${COMMON[@]}" -bs 1w -ru w -o span.txt > run.out 2> run.err; echo $? > run.rc )
if ! assert_no_runtime_warnings "$TMP_DIR/csv/run.err" "$current_scenario"; then
    fail=$((fail + 1)); failures+=("$current_scenario :: runtime warnings")
fi
stats_csv=$(find "$TMP_DIR/csv" -iname '*STATS*.csv' | head -1)
if [[ -n "$stats_csv" ]] && grep -q 'msg-rate_wk' "$stats_csv"; then
    # With week-wide buckets, a per-week rate equals the bucket's occurrences.
    mismatches=$(awk -F',' 'NR == 1 { for (i = 1; i <= NF; i++) { if ($i == "msg-rate_wk") r = i; if ($i == "occurrences") o = i } next }
                            { if ($r + 0 != $o + 0) bad++ } END { print bad + 0 }' "$stats_csv")
    if [[ "$mismatches" == 0 ]]; then
        pass_with "msg-rate_wk equals occurrences per bucket under -bs 1w -ru w"
    else
        fail_with "msg-rate_wk equals occurrences per bucket under -bs 1w -ru w" \
            "-ru w scales a rate by the same length -bs 1w resolves to, so a per-week rate over week-wide buckets is the bucket count" \
            'calculate_all_statistics() in ltl (msg-rate), rate multiplier read from the ladder' \
            "$CONTRACT_D1" "mismatching rows: $mismatches" "csv: $stats_csv"
    fi
else
    fail_with "STATS CSV carries msg-rate_wk under -ru w" \
        "the CSV rate suffix is the ladder's medium name (_wk for weeks), the terminal suffix its short name" \
        'write_stats_csv() in ltl' "$CONTRACT_D1" "csv: ${stats_csv:-none}" "header: $(head -1 "${stats_csv:-/dev/null}" | cut -c1-200)"
fi
if grep -q '/w' "$TMP_DIR/csv/run.out"; then
    pass_with "terminal rate suffix is /w under -ru w"
else
    fail_with "terminal rate suffix is /w under -ru w" \
        "the terminal rate suffix is / plus the ladder step's short name" \
        'print_bar_graph() in ltl (rate legend)' "$CONTRACT_D1"
fi

current_scenario="one-mechanism/structure"
ladder_defs=$(grep -cE '^my @time_unit_ladder\b' "$LTL" || true)
# The ladder's own rows are the one place a spelling list belongs.
# A format's recognition pattern describes a line shape (a bracketed duration
# token carries its unit on the line); the value it captures is converted
# through the ladder, so pattern_src lines are not unit tables either.
stray_lists=$(grep -nE "qw\([^)]*\b(ns|us|ms|msec|usec)\b|\((ns|us|ms|s)\|(us|ms|s|m)|\(s\|m\|h\|d\)" "$LTL" | grep -vE '^\s*[0-9]+:\s*#' | grep -vE "token => '|pattern_src =>" || true)
if [[ "$ladder_defs" == 1 && -z "$stray_lists" ]]; then
    pass_with "exactly one ladder definition; no stray time-unit token list or regex"
else
    fail_with "exactly one ladder definition; no stray time-unit token list or regex" \
        "a single file-scope table defines every time unit; no sub keeps a qw() token list or an ns|us|ms|s-style regex of time units" \
        'ltl globals (@time_unit_ladder) and every former private table' "$CONTRACT_D1" \
        "ladder definitions: $ladder_defs" "stray: ${stray_lists:-none}"
fi

# ---------------------------------------------------------------------------
# Criterion 5b — the display ladder is complete
# ---------------------------------------------------------------------------
current_scenario="display-ladder/above-a-day"
run_ltl d "${COMMON[@]}" -bs 1440 "$DISPLAY_FIXTURE"
for pair in "2025-06-01|1\.4w" "2025-06-02|1\.5mo" "2025-06-03|1\.1y"; do
    IFS='|' read -r day want <<< "$pair"
    if grep -E "^ $day " "$TMP_DIR/d.out" | grep -qE "P50:$want\b"; then
        pass_with "$day row renders $want"
    else
        fail_with "$day row renders $want" \
            "format_time() climbs the whole ladder: 10 days render 1.4w, 45 days 1.5mo, 400 days 1.1y (short names)" \
            'format_time() in ltl, via format_duration() for the latency cells' \
            "$CONTRACT_D1; $CONTRACT_D2" "row: $(grep -E "^ $day " "$TMP_DIR/d.out" | cut -c1-160)"
    fi
done
current_scenario="display-ladder/below-a-microsecond"
run_ltl dn "${COMMON[@]}" -bs 1440 -du ns "$DISPLAY_FIXTURE"
if grep -E '^ 2025-06-04 ' "$TMP_DIR/dn.out" | grep -qE 'P50:500ns\b'; then
    pass_with "500 ns renders 500ns"
else
    fail_with "500 ns renders 500ns" \
        "the ladder's lowest step is nanoseconds: a 500 ns duration renders 500ns" \
        'format_time() in ltl, via format_duration()' "$CONTRACT_D1; $CONTRACT_D2" \
        "row: $(grep -E '^ 2025-06-04 ' "$TMP_DIR/dn.out" | cut -c1-160)"
fi

# ---------------------------------------------------------------------------
echo
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    printf '  %s\n' "${failures[@]}"
    exit 1
fi
exit 0
