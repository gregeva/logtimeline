#!/usr/bin/env bash
# validate-profile.sh — State-observability harness for time-axis folding
# (--profile, Issue #256).
#
# This is a STATE-OBSERVABILITY harness (tests/HARNESS-DESIGN.md § Application-
# observability contract): the system under test is internal computed state —
# how the fold maps and drops samples — so it asserts on the named `-V profile`
# section and never greps the rendered timeline. The rendered surface (x-axis
# labels, folded first/last-seen) is the separate render-invariant harness's job.
#
# The fixture is a synthetic month-long log produced by
# tests/profile/generate-profile-log.py, which also emits a JSON manifest
# declaring, per mode, the expected samples_included / samples_dropped and the
# total line count. The harness asserts the emitted -V values against that
# manifest, so the expectations are the generator's declared truth rather than
# numbers hardcoded here. The default month (January 2025) is chosen so the
# four work-modes have distinct dropped-day totals (workweek drops 16,
# workweek-alt drops 18) — a bug dropping the wrong day-set cannot pass.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the application invariant being tested
#   - produced_by: where in ltl the value is produced (function name)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure alongside the captured output.
#
# Usage:
#   ./tests/validate-profile.sh                # all modes
#   ./tests/validate-profile.sh --mode workweek
#
# Exit codes:
#   0  all assertions passed
#   1  at least one assertion failed, or a setup/extraction breakdown
#   2  usage error
#
# Requires python3 (the generator; standard library only — no numpy).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
GENERATOR="$SCRIPT_DIR/profile/generate-profile-log.py"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"

PRODUCED_BY='emit_profile_verbose() in ltl (sample counts accumulated in read_and_process_logs() via fold_epoch(); included on the all-filters-passed path, dropped on the excluded-weekday path).'
CONTRACT='Issue #256 + tests/HARNESS-DESIGN.md reserved-names list. The profile section name and field names (profile_active, mode, period_seconds, included_weekdays, samples_included, samples_dropped) are stability-contracted; renames are breaking. Expected values come from the generator manifest, the single source of truth for the fixture.'

ALL_MODES=(day week week-alt workweek workweek-alt workday workday-alt)

ONLY_MODE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode) ONLY_MODE="$2"; shift 2 ;;
        -h|--help) sed -n '2,33p' "$0"; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

for f in "$LTL" "$GENERATOR"; do
    if [[ ! -e "$f" ]]; then
        echo "ERROR: required file missing: $f" >&2
        exit 1
    fi
done
if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not executable: $LTL" >&2
    exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: this harness requires python3 (not found on PATH)." >&2
    echo "       macOS:  brew install python" >&2
    echo "       Ubuntu: sudo apt-get install python3" >&2
    exit 1
fi

# All transient artifacts under one temp root, cleaned unconditionally.
TMP_ROOT=$(mktemp -d); trap 'rm -rf "$TMP_ROOT"' EXIT

LOGFILE="$TMP_ROOT/profile.log"
MANIFEST="$TMP_ROOT/profile.manifest.json"

pass=0
fail=0
failures=()
current_mode=""

strip_ansi() { sed -E 's/\x1b\[[0-9;]*m//g'; }

# Runtime-warning cleanliness for an ltl stderr capture. Called from functions
# running in the main shell so the fail counters persist.
# HARNESS-DESIGN.md section Runtime-warning cleanliness.
check_stderr_warnings() {
    local stderr_file="$1"
    if ! assert_no_runtime_warnings "$stderr_file" "$current_mode"; then
        fail=$((fail + 1))
        failures+=("$current_mode :: perl-runtime-warnings-on-stderr")
    fi
}

# Generate the fixture log + manifest ONCE (capture-once). Hard-fail on any
# breakdown so a broken setup can never present as a passing assertion.
if ! python3 "$GENERATOR" "$LOGFILE" --manifest "$MANIFEST" 2>"$TMP_ROOT/gen.err"; then
    echo "ERROR: fixture generation failed:" >&2
    sed 's/^/    /' "$TMP_ROOT/gen.err" >&2
    exit 1
fi
if [[ ! -s "$LOGFILE" || ! -s "$MANIFEST" ]]; then
    echo "ERROR: generator produced an empty log or manifest" >&2
    exit 1
fi

# Read one expected scalar from the manifest. Exits non-zero with a diagnostic
# if the key path is absent — a missing expectation is a setup failure, not a
# silent pass.
manifest_get() {
    local jqpath="$1"
    python3 - "$MANIFEST" "$jqpath" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
cur = m
for k in sys.argv[2].split("."):
    if isinstance(cur, dict) and k in cur:
        cur = cur[k]
    else:
        sys.stderr.write(f"ERROR: manifest key path not found: {sys.argv[2]}\n")
        sys.exit(1)
print(cur)
PY
}

# Capture the -V profile section for one mode (ANSI-stripped) into a file.
# The section is range-extracted between its delimiters (HARNESS-DESIGN.md
# delimiter contract). Hard-fail if the section is absent (zero-match anchor).
capture_section() {
    local mode="$1" outfile="$2"
    local raw="$TMP_ROOT/$mode.raw"
    if ! "$LTL" --disable-progress -V profile -pr "$mode" "$LOGFILE" \
         > "$raw" 2>"$TMP_ROOT/$mode.err"; then
        echo "  FAIL  $current_mode :: ltl exited non-zero emitting -V profile" >&2
        sed 's/^/        /' "$TMP_ROOT/$mode.err" >&2
        fail=$((fail + 1)); failures+=("$current_mode :: ltl failed"); return 1
    fi
    check_stderr_warnings "$TMP_ROOT/$mode.err"
    strip_ansi < "$raw" | sed -n '/^=== profile ===$/,/^=== END profile ===$/p' > "$outfile"
    if [[ ! -s "$outfile" ]]; then
        echo "  FAIL  $current_mode :: '=== profile ===' section not found in -V output" >&2
        fail=$((fail + 1)); failures+=("$current_mode :: profile section missing"); return 1
    fi
}

# Assert that a `key: value` line in the captured section has the expected
# value. Treats a missing key as a hard failure (zero-match anchor), distinct
# from a wrong value. Surfaces asserts/produced_by/contract on any failure.
assert_field() {
    local section="" key="" expected="" asserts=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            section)  section="$2";  shift 2 ;;
            key)      key="$2";      shift 2 ;;
            expected) expected="$2"; shift 2 ;;
            asserts)  asserts="$2";  shift 2 ;;
            *) echo "assert_field: unknown field '$1'" >&2; exit 2 ;;
        esac
    done
    : "${section:?}"; : "${key:?}"; : "${asserts:?}"

    local line actual
    line=$(grep -aE "^${key}: " "$section" || true)
    if [[ -z "$line" ]]; then
        echo "  FAIL  $current_mode :: key '$key' not found in profile section"
        echo "        asserts:     $asserts"
        echo "        produced_by: $PRODUCED_BY"
        echo "        contract:    $CONTRACT"
        echo "        (section: $section)"
        fail=$((fail + 1)); failures+=("$current_mode :: $key missing")
        return
    fi
    actual="${line#"$key": }"
    if [[ "$actual" == "$expected" ]]; then
        echo "  PASS  $current_mode :: $key = $actual"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_mode :: $key"
        echo "        expected:    $expected"
        echo "        actual:      $actual"
        echo "        asserts:     $asserts"
        echo "        produced_by: $PRODUCED_BY"
        echo "        contract:    $CONTRACT"
        echo "        (section: $section)"
        fail=$((fail + 1)); failures+=("$current_mode :: $key=$actual expected $expected")
    fi
}

# Expected included-weekday string per mode (calendar order: Mon-first default,
# Sun-first for -alt; work modes drop the weekend pair). These mirror the fold
# mode table in features/256-time-axis-folding.md.
expected_weekdays() {
    case "$1" in
        day|week)        echo "Mon,Tue,Wed,Thu,Fri,Sat,Sun" ;;
        week-alt)        echo "Sun,Mon,Tue,Wed,Thu,Fri,Sat" ;;
        workweek|workday)        echo "Mon,Tue,Wed,Thu,Fri" ;;
        workweek-alt|workday-alt) echo "Sun,Mon,Tue,Wed,Thu" ;;
        *) echo "" ;;
    esac
}

expected_period() {
    case "$1" in
        day|workday|workday-alt) echo 86400 ;;
        *) echo 604800 ;;
    esac
}

run_mode() {
    local mode="$1"
    current_mode="$mode"
    echo "[$current_mode]"

    local section="$TMP_ROOT/$mode.section"
    capture_section "$mode" "$section" || return 0

    local exp_incl exp_drop total
    exp_incl=$(manifest_get "expected.$mode.included") || { echo "  FAIL  $current_mode :: manifest missing expected.$mode.included"; fail=$((fail+1)); failures+=("$current_mode :: manifest"); return 0; }
    exp_drop=$(manifest_get "expected.$mode.dropped")  || { echo "  FAIL  $current_mode :: manifest missing expected.$mode.dropped";  fail=$((fail+1)); failures+=("$current_mode :: manifest"); return 0; }
    total=$(manifest_get "total_lines")                || { echo "  FAIL  $current_mode :: manifest missing total_lines";            fail=$((fail+1)); failures+=("$current_mode :: manifest"); return 0; }

    assert_field section "$section" key profile_active expected yes \
        asserts 'When --profile is set the section reports profile_active: yes (the fold is engaged).'

    assert_field section "$section" key mode expected "$mode" \
        asserts 'The section echoes the resolved profile mode, matching the --profile argument.'

    assert_field section "$section" key period_seconds expected "$(expected_period "$mode")" \
        asserts 'The fold period is 86400s for day/workday modes and 604800s for week/workweek modes.'

    assert_field section "$section" key included_weekdays expected "$(expected_weekdays "$mode")" \
        asserts 'The included weekday set matches the mode: all seven for day/week, Mon-Fri for workweek/workday, Sun-Thu for the -alt work modes; listed in calendar order (Mon-first default, Sun-first for -alt).'

    assert_field section "$section" key samples_included expected "$exp_incl" \
        asserts 'samples_included equals the count of lines on included weekdays — equal to the fixture total for day/week, and total minus the dropped weekend pair for the work modes.'

    assert_field section "$section" key samples_dropped expected "$exp_drop" \
        asserts 'samples_dropped equals the count of lines on weekdays the mode excludes: zero for day/week, the Sat+Sun pair for default work modes, the Fri+Sat pair for -alt work modes.'

    # Arithmetic invariant: included + dropped reconciles to the fixture total.
    # The fixture applies no exclude/duration filters, so every matched line is
    # either folded-and-included or dropped on an excluded day.
    local incl drop
    incl=$(grep -aE '^samples_included: ' "$section" | sed 's/^samples_included: //')
    drop=$(grep -aE '^samples_dropped: '  "$section" | sed 's/^samples_dropped: //')
    if [[ "$incl" =~ ^[0-9]+$ && "$drop" =~ ^[0-9]+$ ]] && (( incl + drop == total )); then
        echo "  PASS  $current_mode :: samples_included + samples_dropped = $total (total)"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_mode :: included + dropped invariant"
        echo "        expected:    samples_included + samples_dropped = $total"
        echo "        actual:      $incl + $drop"
        echo "        asserts:     Every matched line is either folded-and-included or dropped on an excluded day; the two counts must reconcile to the fixture total (no filters applied)."
        echo "        produced_by: $PRODUCED_BY"
        echo "        contract:    $CONTRACT"
        fail=$((fail + 1)); failures+=("$current_mode :: included+dropped != total")
    fi
}

# Off case: without --profile the section reports profile_active: no.
run_off_case() {
    current_mode="no-profile"
    echo "[$current_mode]"
    local raw="$TMP_ROOT/off.raw" section="$TMP_ROOT/off.section"
    if ! "$LTL" --disable-progress -V profile "$LOGFILE" > "$raw" 2>"$TMP_ROOT/off.err"; then
        echo "  FAIL  $current_mode :: ltl exited non-zero emitting -V profile" >&2
        sed 's/^/        /' "$TMP_ROOT/off.err" >&2
        fail=$((fail + 1)); failures+=("$current_mode :: ltl failed"); return
    fi
    check_stderr_warnings "$TMP_ROOT/off.err"
    strip_ansi < "$raw" | sed -n '/^=== profile ===$/,/^=== END profile ===$/p' > "$section"
    if [[ ! -s "$section" ]]; then
        echo "  FAIL  $current_mode :: '=== profile ===' section not found in -V output"
        fail=$((fail + 1)); failures+=("$current_mode :: profile section missing"); return
    fi
    assert_field section "$section" key profile_active expected no \
        asserts 'When --profile is not set the section reports profile_active: no (folding is off, no fold geometry emitted).'
}

echo "Validating --profile folding observability (Issue #256)"
echo "Surface: -V profile section; expectations from the generator manifest"
echo ""

if [[ -n "$ONLY_MODE" ]]; then
    run_mode "$ONLY_MODE"
else
    for m in "${ALL_MODES[@]}"; do run_mode "$m"; echo ""; done
    run_off_case
fi

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
echo "ALL PROFILE OBSERVABILITY TESTS PASSED"
