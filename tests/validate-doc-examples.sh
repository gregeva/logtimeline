#!/usr/bin/env bash
# validate-doc-examples.sh — Validate that ltl example invocations in
# user-facing documentation parse and execute successfully against
# real fixture logs that ship in the repo.
# Usage: ./tests/validate-doc-examples.sh
#
# Drift class targeted: option renames, removed flags, restructured
# output sections that break a documented `-V | grep` example. These
# have shipped silently to the wiki in the past because release-step 15
# (wiki sync) has no gate.
#
# Asserts exit code 0 AND non-empty stdout for each runnable example.
# Skips: structural synopsis lines (`ltl [options] …`), -V examples
# (deferred until #226-driven section names settle into the canonical
# user-facing surface), examples whose placeholder filenames have no
# substitution mapping.
#
# Implements the self-documenting-assertion design from
# tests/HARNESS-DESIGN.md. Reference: tests/validate-histogram-bin-counters.sh.
#
# Sub-task of issue #225. Issue #234.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
EXTRACTOR="$SCRIPT_DIR/extract-doc-examples.pl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"

# Temp dir for per-test stdout/stderr captures; cleaned up on EXIT per
# HARNESS-DESIGN.md Trap 10.
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -x "$EXTRACTOR" ]]; then
    echo "ERROR: extractor not found or not executable at $EXTRACTOR"
    exit 1
fi

# Substitution table: placeholder name → real fixture path under logs/.
# Per repo memory (feedback_test_logs.md), do NOT use
# logs/AccessLogs/localhost_access_log.2025-03-21.txt — corrupt lines.
#
# We truncate each fixture to a small number of lines at harness start
# and point substitutions at the truncated copies. The harness asserts
# "the example parses and runs," not "the example produces interesting
# output" — a 1000-line slice is plenty for that.
#
# Parallel arrays rather than `declare -A` because the system bash on
# macOS is 3.2, which does not support associative arrays (added in 4.0).
# Matches the bash-3.2-compatible style of tests/validate-histogram-bin-counters.sh.
FIXTURE_LINES=1000

# Source fixtures committed in the repo.
FIXTURE_KEYS=(
    "access.log"
    "app.log"
    "error.log"
)
FIXTURE_SOURCES=(
    "logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log"
    "logs/ThingworxLogs/ApplicationLog.log"
    "logs/ThingworxLogs/ErrorLog.log"
)
# Truncated copies live under $TMP_DIR. Built before any example runs.
SUBSTITUTION_KEYS=( "${FIXTURE_KEYS[@]}" )
SUBSTITUTION_VALS=()

# Docs in scope. Per decisions locked at scoping time
# (features/225-test-harness-coverage-gaps.md):
#   - demo-use-cases.md is internal use → out of scope
#   - docs/test-logs.md:191 corrupt-file reference is intentionally left
#     untouched in this PR → docs/test-logs.md is out of scope
#   - README.md and CLAUDE.md have only structural/build examples → out of scope
# Scope is docs/usage.md only.
DOCS=(
    "docs/usage.md"
)

# Per-fixture stable terminal width for deterministic invocations.
LTL_INJECT="--disable-progress --terminal-width 120"

pass=0
fail=0
skip=0
failures=()
current_scenario=""

# Self-documenting failure emitter, matching the shape of assert_line in
# the reference harness. Used directly here because each example is its
# own scenario rather than a per-line grep against captured output.
emit_failure() {
    local label asserts produced_by contract detail
    while [[ $# -gt 0 ]]; do
        case "$1" in
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            detail)      detail="$2";      shift 2 ;;
            *) echo "emit_failure: unknown field '$1'"; exit 2 ;;
        esac
    done
    echo "  FAIL  $current_scenario"
    echo "        label:       $label"
    echo "        asserts:     $asserts"
    echo "        produced_by: $produced_by"
    echo "        contract:    $contract"
    echo "        detail:      $detail"
    fail=$((fail + 1))
    failures+=("$current_scenario :: $label")
}

# Apply substitutions to a command. Returns the substituted command on
# stdout. If the command contains a placeholder with no mapping, OR a
# glob/path-form pattern we can't safely substitute, returns empty
# (caller treats as skipped).
substitute_command() {
    local cmd="$1"
    local result="$cmd"
    local saw_placeholder=0

    # Direct word substitutions for known placeholders. Iterate the
    # parallel arrays by index for bash-3.2 compatibility.
    local i placeholder fixture
    for i in "${!SUBSTITUTION_KEYS[@]}"; do
        placeholder="${SUBSTITUTION_KEYS[$i]}"
        fixture="${SUBSTITUTION_VALS[$i]}"
        if [[ "$result" =~ (^|[[:space:]])${placeholder}([[:space:]]|$) ]]; then
            saw_placeholder=1
            result="${result//${placeholder}/${fixture}}"
        fi
    done

    # If the command still references a glob (logs/*/access.log,
    # logs/2025-05-*.txt) or any unknown bare *.log/*.txt name that
    # isn't a real fixture, return empty so the caller skips.
    if [[ "$result" == *"logs/"*"*"* ]] || [[ "$result" == *"logs/2025-"*"*"* ]]; then
        echo ""
        return
    fi

    # If no substitution applied AND no fixture is referenced, the example
    # is a structural/synopsis line (e.g. `ltl [options] <logfile> ...`).
    # Caller skips.
    if [[ "$saw_placeholder" -eq 0 ]]; then
        echo ""
        return
    fi

    echo "$result"
}

run_doc_example() {
    local doc="$1"
    local line="$2"
    local cmd="$3"
    current_scenario="${doc}:${line}"

    # Skip structural synopsis lines like `ltl [options] <logfile>`.
    if [[ "$cmd" == *"[options]"* ]] || [[ "$cmd" == *"<logfile"* ]]; then
        echo "  SKIP  $current_scenario (structural synopsis)"
        skip=$((skip + 1))
        return
    fi

    # Skip -V examples per locked scoping decision: the -V surface is
    # currently churning with #226 follow-ups; pinning examples here
    # would create more breakage than the harness catches.
    if [[ "$cmd" == *" -V"* ]] || [[ "$cmd" == *" -V" ]]; then
        echo "  SKIP  $current_scenario (-V example, deferred)"
        skip=$((skip + 1))
        return
    fi

    local subbed
    subbed=$(substitute_command "$cmd")
    if [[ -z "$subbed" ]]; then
        echo "  SKIP  $current_scenario (no substitution match for placeholder)"
        skip=$((skip + 1))
        return
    fi

    # Strip the leading `ltl ` or `./ltl ` and prepend our pinned LTL
    # binary + injected flags. This keeps `--disable-progress
    # --terminal-width 120` consistent across every example.
    local ltl_args="${subbed#./ltl }"
    ltl_args="${ltl_args#ltl }"

    local stdout_file="$TMP_DIR/$(echo "$current_scenario" | tr -c 'A-Za-z0-9._-' '_').stdout"
    local stderr_file="${stdout_file%.stdout}.stderr"

    # HARNESS-DESIGN.md Trap 1: preserve stderr, check the exit code
    # without set -e aborting the harness.
    set +e
    # shellcheck disable=SC2086
    (cd "$REPO_DIR" && "$LTL" $LTL_INJECT $ltl_args > "$stdout_file" 2> "$stderr_file")
    local ec=$?
    set -e

    if [[ "$ec" -ne 0 ]]; then
        emit_failure \
            label       "doc example exited $ec" \
            asserts     "Every non-skipped ltl example in user-facing documentation parses its options and runs to completion (exit 0) against a known fixture. A non-zero exit means an option was renamed, removed, or the example was wrong from the start." \
            produced_by 'docs/usage.md (example) + ltl option parser' \
            contract    'features/225-test-harness-coverage-gaps.md section #234 - docs/usage.md is the canonical wiki source per CLAUDE.md release-process step 15; broken examples ship to the wiki' \
            detail      "command: $LTL $LTL_INJECT $ltl_args ; stderr: $(head -3 "$stderr_file" 2>/dev/null | tr '\n' ' ')"
        return
    fi

    # Runtime-warning cleanliness (HARNESS-DESIGN.md section Runtime-warning
    # cleanliness): intentional ltl notices on stderr never carry the
    # ` at <file> line <N>` suffix, so they do not trip this check.
    if ! assert_no_runtime_warnings "$stderr_file" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
        return
    fi

    if [[ ! -s "$stdout_file" ]]; then
        emit_failure \
            label       "doc example produced empty stdout" \
            asserts     'Successful example runs produce non-empty output. An empty stdout with exit 0 indicates the example silently no-ops (matched 0 lines, filtered everything out) - the example is misleading even if technically functional.' \
            produced_by 'docs/usage.md (example) + ltl output writer' \
            contract    'features/225-test-harness-coverage-gaps.md section #234 - examples must demonstrate something, not just exit cleanly' \
            detail      "command: $LTL $LTL_INJECT $ltl_args"
        return
    fi

    echo "  PASS  $current_scenario"
    pass=$((pass + 1))
}

# ---------- Run ----------------------------------------------------------

# Build truncated fixtures (HARNESS-DESIGN.md Trap 9: transient artifacts
# live under $TMP_DIR, never alongside deliverables).
for i in "${!FIXTURE_KEYS[@]}"; do
    src="${REPO_DIR}/${FIXTURE_SOURCES[$i]}"
    if [[ ! -f "$src" ]]; then
        echo "ERROR: fixture source not found: $src"
        exit 1
    fi
    dst="$TMP_DIR/${FIXTURE_KEYS[$i]}"
    head -n "$FIXTURE_LINES" "$src" > "$dst"
    SUBSTITUTION_VALS+=( "$dst" )
done

echo "Validating documentation examples (issue #234)"
echo "  ltl:       $LTL"
echo "  inject:    $LTL_INJECT"
echo "  docs:      ${DOCS[*]}"
echo "  fixtures:  truncated to $FIXTURE_LINES lines under \$TMP_DIR"
echo ""

EXAMPLES_TSV="$TMP_DIR/examples.tsv"
( cd "$REPO_DIR" && "$EXTRACTOR" "${DOCS[@]}" ) > "$EXAMPLES_TSV"

total=$(wc -l < "$EXAMPLES_TSV" | tr -d ' ')
echo "Extracted $total candidate example(s)."
echo ""

while IFS=$'\t' read -r file line cmd; do
    [[ -z "$file" ]] && continue
    run_doc_example "$file" "$line" "$cmd"
done < "$EXAMPLES_TSV"

echo ""
echo "Results: $pass passed, $fail failed, $skip skipped"

if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL DOC-EXAMPLE TESTS PASSED"
exit 0
