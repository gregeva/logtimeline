#!/usr/bin/env bash
# validate-csv-output.sh — Categorical CSV-output integrity harness (Issue #223)
#
# Validates structural and categorical correctness of -o CSV outputs
# (MESSAGES and STATS): column presence, ordering, population, family group
# consistency, data-type correctness, fixed-decimal rules, and — for scenarios
# that declare an expected-categories file (Issue #312) — which MESSAGES rows
# land in category highlight vs plain, and which are absent (dropped by a
# hard filter). All checks are pass/fail (no tolerance).
#
# Sibling to validate-statistics.sh (#224), which handles numeric drift,
# intra-row consistency, and oracle correctness.
# Run this BEFORE the statistics harness — structural correctness is a
# precondition for meaningful drift comparison.
#
# CSV production is delegated to tests/lib/csv-cache.sh which caches
# produced CSVs under deterministic filenames in tests/.artifacts/csv/
# so the statistics harness can reuse them.
#
# Orchestration: set CI=1 (industry-standard env var, also set by all
# major CI runners) when chaining this harness with others, so the cache
# is preserved for the next harness in the chain. The orchestrator is
# responsible for calling cleanup-test-artifacts.sh at the end. When CI
# is unset, this harness cleans up its own artifacts at end of run.
#
# Usage:
#   ./tests/validate-csv-output.sh                       # all scenarios
#   ./tests/validate-csv-output.sh --scenario <name>     # single scenario

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/logs-dir.sh
source "$SCRIPT_DIR/lib/logs-dir.sh"
LTL="$REPO_DIR/ltl"
HARNESS_DIR="$SCRIPT_DIR/csv-output"
# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence): each
# scenario's options and fixture in scenarios.tsv are the subject (the CSV
# rows and -V csv-output fields derive from them); display options stay as
# the scenario declares them.
SCENARIOS_TSV="$HARNESS_DIR/scenarios.tsv"
RULES_MESSAGES="$HARNESS_DIR/rules/messages-columns.tsv"
RULES_STATS="$HARNESS_DIR/rules/stats-columns.tsv"
VALIDATOR="$HARNESS_DIR/validate-csv-output.pl"
PROFILE_GENERATOR="$SCRIPT_DIR/profile/generate-profile-log.py"

# shellcheck source=lib/csv-cache.sh
source "$SCRIPT_DIR/lib/csv-cache.sh"

# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited; issue #438).
neutralize_colour_env


# End-of-run cleanup runs only when standalone (CI unset). Trap covers
# both clean exit and error paths.
trap csv_cache_maybe_cleanup EXIT

ONLY_SCENARIO=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --scenario) ONLY_SCENARIO="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,24p' "$0"
            exit 0
            ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

# Sanity: required files exist. A missing file would silently skip work and
# falsely pass, so fail loudly here.
for f in "$LTL" "$SCENARIOS_TSV" "$RULES_MESSAGES" "$RULES_STATS" "$VALIDATOR" "$PROFILE_GENERATOR"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: required file missing: $f" >&2
        exit 1
    fi
done

# Profile scenarios reference @PROFILE_LOG@ in scenarios.tsv. Generate the
# synthetic month-long log (the same fixture the dedicated --profile harnesses
# use) once into the gitignored artifacts dir, and substitute the marker with
# its path in the loop. Using the generated fixture — not a real multi-day log
# — is required: its dates are known a priori, so a week fold genuinely spans
# all seven weekdays and the folded CSV timestamps are verifiable.
PROFILE_LOG="$SCRIPT_DIR/.artifacts/profile-csv-fixture.log"
if grep -q '@PROFILE_LOG@' "$SCENARIOS_TSV"; then
    mkdir -p "$(dirname "$PROFILE_LOG")"
    if ! python3 "$PROFILE_GENERATOR" "$PROFILE_LOG" >/dev/null 2>"$SCRIPT_DIR/.artifacts/profile-gen.err"; then
        echo "ERROR: failed to generate the profile CSV fixture:" >&2
        sed 's/^/    /' "$SCRIPT_DIR/.artifacts/profile-gen.err" >&2
        exit 1
    fi
fi

# Scenarios that assert only column families over the ThingWorx
# ApplicationLog reference @APPLOG_HEAD@: the first 100,000 lines of
# ApplicationLog.2025-05-05.0.log (~2.8 h, every level and -udm token class
# present), staged once into the artifacts dir. The assertions are
# structural - which families appear and are well-formed - so the 480k-line
# day file adds rows to walk, not signal (HARNESS-DESIGN.md section
# Invocation coherence).
APPLOG_HEAD="$SCRIPT_DIR/.artifacts/applicationlog-head-100k.log"
if grep -q '@APPLOG_HEAD@' "$SCENARIOS_TSV"; then
    mkdir -p "$(dirname "$APPLOG_HEAD")"
    head -100000 "$LOGS_DIR/ThingworxLogs/ApplicationLog.2025-05-05.0.log" > "$APPLOG_HEAD"
    if [[ ! -s "$APPLOG_HEAD" ]]; then
        echo "ERROR: could not stage the ApplicationLog head fixture at $APPLOG_HEAD" >&2
        exit 1
    fi
fi

total_pass=0
total_fail=0
scenarios_run=0

# Single loop fed by process substitution so counter mutations stay in the
# parent shell. Skip the header line of the TSV.
while IFS=$'\t' read -r scenario logfile options families expected_categories; do
    [[ -z "$scenario" ]] && continue
    [[ "$scenario" =~ ^# ]] && continue
    if [[ -n "$ONLY_SCENARIO" && "$scenario" != "$ONLY_SCENARIO" ]]; then
        continue
    fi

    # Resolve the generated-fixture marker to its absolute path.
    [[ "$logfile" == "@PROFILE_LOG@" ]] && logfile="$PROFILE_LOG"
    [[ "$logfile" == "@APPLOG_HEAD@" ]] && logfile="$APPLOG_HEAD"

    # Derive the --profile mode (if any) from the scenario's options so the
    # validator can expect the folded timestamp form instead of ISO. Matches
    # -pr/--profile <mode> anywhere in the options string.
    profile_mode=""
    if [[ "$options" =~ (-pr|--profile)[[:space:]]+([a-z-]+) ]]; then
        profile_mode="${BASH_REMATCH[2]}"
    fi

    log_shorthand="$(csv_cache_logfile_shorthand "$logfile")"

    set +e
    csv_cache_produce "$scenario" "$logfile" "$options" "$log_shorthand"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        # csv_cache_produce already printed the diagnostic.
        total_fail=$((total_fail + 1))
        scenarios_run=$((scenarios_run + 1))
        continue
    fi

    msg_csv="$CSV_CACHE_MESSAGES"
    stats_csv="$CSV_CACHE_STATS"

    # The -V csv-output capture comes from the producing run itself
    # (csv_cache_produce requests the section and caches the stdout), so
    # the precision assertions read the contract of the run that wrote
    # the CSVs under test - no second identical ltl run.
    v_capture_dir="$SCRIPT_DIR/.artifacts/v-csv-output/$scenario"
    mkdir -p "$v_capture_dir"
    cp "$CSV_CACHE_STDOUT" "$v_capture_dir/ltl.stdout"

    # Extract -V csv-output / precision sub-section into a file the
    # validator reads. Anchored by the 'precision' sub-section markers
    # so the parent 'csv-output' wrapper is filtered out. (#268)
    v_precision="$v_capture_dir/csv-output-precision.txt"
    awk '/=== csv-output \/ precision ===/{flag=1; next} /=== END csv-output \/ precision ===/{flag=0} flag' \
        "$v_capture_dir/ltl.stdout" > "$v_precision"
    if [[ ! -s "$v_precision" ]]; then
        echo "FAIL  scenario=$scenario missing-v-csv-output-precision-block" >&2
        echo "        -V csv-output / precision sub-section was empty or absent in ltl stdout" >&2
        echo "        asserts: every -o run must emit -V csv-output / precision when -V csv-output is requested" >&2
        echo "        produced_by: emit_csv_output_verbose() in ltl" >&2
        echo "        contract: Issue #268 section locked observability surface" >&2
        total_fail=$((total_fail + 1))
        scenarios_run=$((scenarios_run + 1))
        continue
    fi

    # Expected-categories file (optional 5th scenario column, Issue #312):
    # categorical content assertions against the MESSAGES CSV. Path is
    # relative to the harness dir; a declared-but-missing file is a hard
    # failure, not a silent skip.
    expected_args=()
    if [[ -n "${expected_categories:-}" ]]; then
        expected_path="$HARNESS_DIR/$expected_categories"
        if [[ ! -f "$expected_path" ]]; then
            echo "FAIL  scenario=$scenario expected-categories file missing: $expected_path" >&2
            total_fail=$((total_fail + 1))
            scenarios_run=$((scenarios_run + 1))
            continue
        fi
        expected_args=(--expected-categories "$expected_path")
    fi

    scen_fail=0

    for kind in messages stats; do
        if [[ "$kind" == "messages" ]]; then
            rules="$RULES_MESSAGES"
            csv="$msg_csv"
            kind_expected_args=("${expected_args[@]+"${expected_args[@]}"}")
        else
            rules="$RULES_STATS"
            csv="$stats_csv"
            kind_expected_args=()
        fi

        set +e
        perl "$VALIDATOR" \
            --rules "$rules" \
            --csv "$csv" \
            --scenario "$scenario" \
            --file-kind "$kind" \
            --expected-families "$families" \
            --v-precision "$v_precision" \
            --profile-mode "$profile_mode" \
            "${kind_expected_args[@]+"${kind_expected_args[@]}"}"
        vrc=$?
        set -e

        if [[ $vrc -ne 0 ]]; then
            scen_fail=$((scen_fail + 1))
        fi
    done

    scenarios_run=$((scenarios_run + 1))
    if [[ $scen_fail -eq 0 ]]; then
        echo "PASS  scenario=$scenario messages+stats validated"
        total_pass=$((total_pass + 1))
    else
        echo "FAIL  scenario=$scenario validator-failures=$scen_fail"
        total_fail=$((total_fail + 1))
    fi
done < <(tail -n +2 "$SCENARIOS_TSV")

# ---------------------------------------------------------------------------
# Cache validity (#448).
#
# The cached CSV artifacts are shared with validate-statistics.sh and a CI=1 run
# leaves them behind on purpose so that chaining is cheap. They must therefore
# expire, or a session that never ran cleanup-test-artifacts.sh leaves them to
# be read back forever: forty artifacts three days old validated 21 of 23
# scenarios here against an ltl that predated two of the columns the contract
# had since gained, and both harnesses then failed against output no version of
# the tool would produce.
#
# The three staleness decisions are asserted against the helper directly, on a
# crafted artifact, with no ltl run at all. The refresh itself is proved once,
# end to end, on the smallest fixture scenario — the warning must reach stderr
# and the artifact must actually be produced again.
# ---------------------------------------------------------------------------

CACHE_PERL="${PERL:-perl}"
CACHE_SCENARIO="gc-g1-categories"
CACHE_PRODUCED_BY='csv_cache_staleness_reason() and csv_cache_produce() in tests/lib/csv-cache.sh'
CACHE_CONTRACT='tests/HARNESS-DESIGN.md § Cached capture artifacts expire; features/448-category-summary-share-and-bar.md § Harness defect found while fixing the monochrome option'

cache_assert() {
    local label="$1" rc="$2" detail="$3" asserts="$4"
    if [[ "$rc" -eq 0 ]]; then
        echo "PASS  cache-validity :: $label"
        total_pass=$((total_pass + 1))
    else
        echo "FAIL  cache-validity :: $label"
        echo "        asserts:     $asserts"
        echo "        produced_by: $CACHE_PRODUCED_BY"
        echo "        contract:    $CACHE_CONTRACT"
        echo "$detail" | sed 's/^/        | /'
        total_fail=$((total_fail + 1))
    fi
}

cache_backdate() {
    "$CACHE_PERL" -e 'my $t = time - $ARGV[1]; utime($t, $t, $ARGV[0]) or die "cannot backdate $ARGV[0]\n";' "$1" "$2"
}

cache_row="$(awk -F'\t' -v s="$CACHE_SCENARIO" '$1 == s { print; exit }' "$SCENARIOS_TSV")"
if [[ -z "$cache_row" ]]; then
    echo "ERROR: cache-validity scenario '$CACHE_SCENARIO' is not in $SCENARIOS_TSV" >&2
    exit 1
fi
IFS=$'\t' read -r _cs cache_logfile cache_options _rest <<<"$cache_row"

if ! csv_cache_produce "$CACHE_SCENARIO" "$cache_logfile" "$cache_options" \
        "$(csv_cache_logfile_shorthand "$cache_logfile")"; then
    echo "ERROR: cache-validity could not obtain a cached artifact for $CACHE_SCENARIO" >&2
    exit 1
fi
CACHE_MSG="$CSV_CACHE_MESSAGES"
CACHE_SIG="$(csv_cache_signature_path "$CACHE_MSG")"

# 1. A freshly captured artifact is reusable.
set +e
reason="$(csv_cache_staleness_reason "$CACHE_MSG")"; rc=$?
set -e
cache_assert 'a freshly captured artifact is read back rather than produced again' \
    "$([[ $rc -eq 1 ]] && echo 0 || echo 1)" \
    "staleness_rc=$rc reason=${reason:-<none>}" \
    'The cache must still do its job: within the validity period, and with the CSV-emitting code unchanged, the artifact is reused. An expiry that refuses everything would turn a chained CI run into two full captures and the sharing this helper exists for would be gone.'

# 2. Past the validity period.
cache_backdate "$CACHE_MSG" $(( (_CSV_CACHE_MAX_AGE_MINUTES + 5) * 60 ))
set +e
reason="$(csv_cache_staleness_reason "$CACHE_MSG")"; rc=$?
set -e
cache_assert 'an artifact older than the validity period is stale' \
    "$([[ $rc -eq 0 && "$reason" == *"validity period"* ]] && echo 0 || echo 1)" \
    "staleness_rc=$rc reason=${reason:-<none>}" \
    'Age alone expires an artifact. This is the case that shipped the incident: the artifacts were left behind by a CI=1 run days earlier and were read back without anything noticing that the tool had moved on.'

# 3. The CSV-emitting code changed since the capture.
"$CACHE_PERL" -e 'my $t = time; utime($t, $t, $ARGV[0]) or die;' "$CACHE_MSG"
printf 'not-the-signature-that-produced-this\n' > "$CACHE_SIG"
set +e
reason="$(csv_cache_staleness_reason "$CACHE_MSG")"; rc=$?
set -e
cache_assert 'an artifact whose producing CSV code has changed is stale whatever its age' \
    "$([[ $rc -eq 0 && "$reason" == *"changed after it was captured"* ]] && echo 0 || echo 1)" \
    "staleness_rc=$rc reason=${reason:-<none>}" \
    'A minutes-old artifact is still wrong if the CSV columns moved under it. The signature covers the CSV-emitting code of ltl and the column-rule spec, so an edit to either expires the capture while an edit elsewhere in the tool leaves it alone — the cache would be worthless if every touch of ltl threw it away.'

# 4. No record of what produced it.
rm -f "$CACHE_SIG"
set +e
reason="$(csv_cache_staleness_reason "$CACHE_MSG")"; rc=$?
set -e
cache_assert 'an artifact with no record of its producing code is stale' \
    "$([[ $rc -eq 0 && "$reason" == *"without a record"* ]] && echo 0 || echo 1)" \
    "staleness_rc=$rc reason=${reason:-<none>}" \
    'Artifacts captured before this rule existed carry no signature, and an unanswerable question is never answered as "fresh": the artifact is produced again.'

# 5. The refresh itself: the warning reaches stderr and the artifact is rebuilt.
cache_backdate "$CACHE_MSG" $(( (_CSV_CACHE_MAX_AGE_MINUTES + 5) * 60 ))
cache_refresh_err="$(mktemp)"
set +e
csv_cache_produce "$CACHE_SCENARIO" "$cache_logfile" "$cache_options" \
    "$(csv_cache_logfile_shorthand "$cache_logfile")" 2>"$cache_refresh_err"
rc=$?
set -e
refresh_age="$("$CACHE_PERL" -e 'my @s = stat($ARGV[0]); printf "%d", time - $s[9];' "$CACHE_MSG")"
cache_assert 'a stale cache is refreshed, and says so' \
    "$([[ $rc -eq 0 && $refresh_age -lt 300 ]] && grep -q 'WARNING stale cache' "$cache_refresh_err" && echo 0 || echo 1)" \
    "produce_rc=$rc artifact_age_seconds=$refresh_age stderr=$(sed 's/^/          /' "$cache_refresh_err")" \
    'The refresh is not silent. A cache that quietly serves stale artifacts is what kept this invisible for three days, so the run states that the artifacts were stale and are being produced again, and the artifact on disk is the new one.'
rm -f "$cache_refresh_err"

echo ""
echo "=== CSV output integrity: $scenarios_run scenarios, $total_pass pass, $total_fail fail ==="

if [[ $scenarios_run -eq 0 ]]; then
    echo "ERROR: no scenarios were run (check --scenario filter and scenarios.tsv)" >&2
    exit 1
fi

[[ $total_fail -eq 0 ]] || exit 1
exit 0
