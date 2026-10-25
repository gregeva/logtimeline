#!/usr/bin/env bash
# run-suite.sh - the full harness suite: every tests/validate-*.sh, run once
# at the completion gate before the PR (docs/process/workflow.md § 3) and at
# the release cut (§ 5). It is long and resource-intensive; work in progress
# runs the harnesses it needs by scenario (tests/HARNESS-DESIGN.md § Running
# what the change needs). The Bash guard refuses it in a checkout that is not
# at the gate (process/claude-hooks/guard-bash.sh).
#
# Every harness runs to its end, whatever an earlier one returned:
# validate-csv-output.sh, then validate-statistics.sh, which share the CSV
# cache, then the rest in name order, validate-harness-failed-run.sh last.
# Each runs with CI=1, so the cache lives through the chain, and
# tests/cleanup-test-artifacts.sh clears it before the first and after the last.
#
# Usage: tests/run-suite.sh [--generated-read-path] OUTPUT_DIR
#   OUTPUT_DIR, empty or not yet made, receives each harness's standard output
#   and standard error as <harness>.txt, its exit status as <harness>.txt.rc,
#   and suite.tsv, one row per harness: harness, result, exit, summary
#   (yes|no), passed, failed, seconds, capture.
#   --generated-read-path runs the release cut's second pass (§ 5, step 4):
#   LTL names a copy of ltl whose read-path threshold is 0, written to
#   OUTPUT_DIR, and validate-read-path.sh and validate-harness-failed-run.sh
#   are left out.
#
# A harness passes when it exits 0 and its capture reaches a summary counting
# at least one passed check (process/check-harness-capture.pl). One line is
# printed per harness as it finishes, then the count.
# Exit status: 0 when every harness passed, 1 otherwise, 2 on a usage error.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$TESTS_DIR")"
CAPTURE_CHECKER="$REPO_DIR/process/check-harness-capture.pl"

usage() {
    echo "usage: tests/run-suite.sh [--generated-read-path] OUTPUT_DIR" >&2
    echo "run-suite.sh: $1" >&2
    exit 2
}

generated=0
out=''
for arg in "$@"; do
    case "$arg" in
        --generated-read-path) generated=1 ;;
        -*) usage "unknown option $arg" ;;
        *)  [[ -z "$out" ]] || usage "more than one output directory named"
            out="$arg" ;;
    esac
done
[[ -n "$out" ]] || usage "no output directory named"
[[ ! -e "$out" || -z "$(ls -A "$out")" ]] || usage "$out is not empty"
mkdir -p "$out" && out="$(cd "$out" && pwd)" || exit 2
cd "$REPO_DIR" || exit 2

first=("$TESTS_DIR/validate-csv-output.sh" "$TESTS_DIR/validate-statistics.sh")
last="$TESTS_DIR/validate-harness-failed-run.sh"
harnesses=("${first[@]}")
for harness in "$TESTS_DIR"/validate-*.sh; do
    case "$harness" in
        "${first[0]}" | "${first[1]}" | "$last") continue ;;
        "$TESTS_DIR/validate-read-path.sh") (( generated )) && continue ;;
    esac
    harnesses+=("$harness")
done
(( generated )) || harnesses+=("$last")

if (( generated )); then
    copy="$out/ltl-generated-read-path"
    perl -pe 's/^(my \$read_path_threshold\s*=\s*)2_097_152;/${1}0;/' ltl > "$copy" && chmod +x "$copy" || exit 2
    if [[ "$(diff ltl "$copy" | grep -c '^>')" != 1 ]]; then
        echo "run-suite.sh: the copy of ltl for the generated read path must differ in its read-path threshold alone" >&2
        exit 2
    fi
    export LTL="$copy"
fi

"$TESTS_DIR/cleanup-test-artifacts.sh"
printf 'harness\tresult\texit\tsummary\tpassed\tfailed\tseconds\tcapture\n' > "$out/suite.tsv"
passed=0
failed=()
for harness in "${harnesses[@]}"; do
    name="$(basename "$harness" .sh)"
    capture="$out/$name.txt"
    start=$SECONDS
    CI=1 bash "$harness" > "$capture" 2>&1
    echo $? > "$capture.rc"
    seconds=$(( SECONDS - start ))
    IFS=$'\t' read -r _ summary status checks_passed checks_failed _ \
        < <(perl "$CAPTURE_CHECKER" --brief "$capture")
    if [[ "$status" == 0 && "$summary" == yes && "$checks_passed" =~ ^[0-9]+$ ]] && (( checks_passed > 0 )); then
        result=pass
        passed=$(( passed + 1 ))
    else
        result=FAIL
        failed+=("$name")
    fi
    if [[ "$summary" == yes ]]; then
        counts="$checks_passed passed, $checks_failed failed"
    else
        counts='no summary'
    fi
    printf '%-4s  %-42s  exit %-3s  %-24s  %5ss  %s\n' "$result" "$name" "$status" "$counts" "$seconds" "$capture"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$result" "$status" "$summary" \
        "$checks_passed" "$checks_failed" "$seconds" "$capture" >> "$out/suite.tsv"
done
"$TESTS_DIR/cleanup-test-artifacts.sh"

echo
if (( ${#failed[@]} )); then
    echo "Suite: ${#harnesses[@]} harnesses, $passed passed, ${#failed[@]} failed: ${failed[*]}"
    exit 1
fi
echo "Suite: ${#harnesses[@]} harnesses, $passed passed, 0 failed"
