#!/usr/bin/env bash
# validate-message-grouping.sh — harness for the message-grouping -V section.
#
# Two systems under test.
#
# 1. The threshold message grouping (-g) applies in its final pass. The final
#    pass scores at the sensitivity the run resolved from -g (or its default),
#    unless --final-threshold is given explicitly, and the section header
#    reports the threshold the final pass used.
#
#    The fixture's four request paths are each requested three times, so every
#    key reaches the occurrence ceiling, streaming discovery skips it, and only
#    the final pass can group them. They form two pairs at Dice 77 and Dice 89,
#    so the number of patterns the final pass creates says which threshold it
#    scored at.
#
# 2. The candidate search finds every partner at the requested similarity, and
#    grouping never replaces UUIDs.
#
#    The signed direct-download fixture is 400 scrubbed request lines whose
#    message keys, under -xqs, each have a partner at Dice 75 to 79 and no pair
#    at Dice 85; their rarest trigrams come from per-request values (signature,
#    signing time, counter). The UUID fixture is two request lines whose keys
#    differ only in a hex UUID sharing its first 18 characters: Dice 73 on the
#    keys as written, 100 with the UUIDs replaced by one placeholder.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the invariant being tested
#   - produced_by: where in ltl it is produced (function name)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure alongside the failing command.
#
# Usage: ./tests/validate-message-grouping.sh

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

FIXTURE="$REPO_DIR/tests/fixtures/grouping-final-pass-threshold.txt"
FIXTURE_DOWNLOADS="$REPO_DIR/tests/fixtures/grouping-signed-downloads.txt"
FIXTURE_UUID="$REPO_DIR/tests/fixtures/grouping-uuid-pair.txt"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
for f in "$FIXTURE" "$FIXTURE_DOWNLOADS" "$FIXTURE_UUID"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: fixture not found: $f"; exit 1
    fi
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

CONTRACT='features/fuzzy-message-consolidation.md § Final pass follows the sensitivity (#571) — acceptance criteria and the -V message-grouping keys asserted'
CONTRACT_SEARCH='features/fuzzy-message-consolidation.md § Design: candidate search that finds every partner (#569) — acceptance criteria'
HEADER_PRODUCER='pipeline_finalize() in ltl (message-grouping header line)'
FINAL_PASS_PRODUCER='group_similar_messages() in ltl (final-pass threshold), counted per group by process_final_pass_window()'
REDUCTION_PRODUCER='pipeline_finalize() in ltl (per-group Reduction line), over the patterns run_consolidation_checkpoint() and process_final_pass_window() form from find_consolidation_candidates() results'
PATTERNS_PRODUCER='run_consolidation_checkpoint() (streaming) and process_final_pass_window() via group_similar_messages() (final pass) in ltl, candidates from find_consolidation_candidates(); reported by pipeline_finalize()'
MEMBERSHIP_PRODUCER='group_similar_messages() in ltl (message-grouping-membership buffer), emitted by pipeline_finalize()'

# Run ltl, capture the message-grouping section, fail hard on a failed run, an
# empty capture, a missing section, or a runtime warning (HARNESS-DESIGN.md
# Trap 1, Trap 3 and Runtime-warning cleanliness).
# Usage: capture_section <outfile> <ltl-args...>
capture_section() {
    local outfile="$1"; shift
    local errfile="$outfile.stderr"
    set +e
    # Run inside TMP_DIR so cwd artifacts never land in the repo (Trap 9).
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni "$@" ) > "$outfile" 2>"$errfile"
    local rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $rc" >&2
        sed 's/^/        /' "$errfile" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: ltl run failed"); return 1
    fi
    if ! grep -q '^=== message-grouping ===$' "$outfile" || ! grep -q '^=== END message-grouping ===$' "$outfile"; then
        echo "  FAIL  $current_scenario :: message-grouping section missing from $outfile" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: section missing"); return 1
    fi
    if ! assert_no_runtime_warnings "$errfile" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr"); return 1
    fi
}

# Self-documenting assertion (assert_command shape, HARNESS-DESIGN.md).
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

    local cmd_out cmd_rc
    set +e
    cmd_out=$(eval "$command" 2>&1); cmd_rc=$?
    set -e
    if [[ "$cmd_rc" -eq 0 ]]; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario :: $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "$cmd_out" | sed 's/^/        | /'
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# Prints one counter from a group's phase block; exits non-zero when the block
# or the counter is absent (HARNESS-DESIGN.md Trap 4: a missing anchor is never
# an empty value).
# Usage: block_counter <file> <group> <Streaming Phase|Final Pass> <counter label>
block_counter() {
    awk -v grp="--- $2: $3" -v key="$4:" '
        index($0, "  --- ") == 1 { inblock = (index($0, grp) > 0) }
        inblock && index($0, key) { sub(/^.*: */, ""); split($0, v, " "); print v[1]; found = 1; exit }
        END { if (!found) exit 1 }
    ' "$1"
}

# Prints "<keys> <rows>" from a group's "Reduction: N -> M" line; exits
# non-zero when the group has no Reduction line.
# Usage: group_reduction <file> <group>
group_reduction() {
    awk -v grp="  --- $2: " '
        index($0, "===") == 1 { ingroup = 0 }
        index($0, "  --- ") == 1 { ingroup = (index($0, grp) == 1) }
        ingroup && $1 == "Reduction:" && $3 == "->" { print $2, $4; found = 1; exit }
        END { if (!found) exit 1 }
    ' "$1"
}

# Passes when the group's reduction ends at no more than <max> rows from
# <keys> keys; prints the observed line on failure.
# Usage: check_rows_at_most <file> <group> <keys> <max>
check_rows_at_most() {
    local r
    if ! r=$(group_reduction "$1" "$2"); then
        echo "no 'Reduction:' line for group $2 in $1"; return 1
    fi
    set -- "$@" $r
    echo "observed: Reduction $5 -> $6 (expected $3 keys, at most $4 rows)"
    [[ "$5" -eq "$3" && "$6" -le "$4" ]]
}

# Passes when the group's reduction is exactly <keys> -> <rows>.
# Usage: check_rows_equal <file> <group> <keys> <rows>
check_rows_equal() {
    local r
    if ! r=$(group_reduction "$1" "$2"); then
        echo "no 'Reduction:' line for group $2 in $1"; return 1
    fi
    set -- "$@" $r
    echo "observed: Reduction $5 -> $6 (expected $3 -> $4)"
    [[ "$5" -eq "$3" && "$6" -eq "$4" ]]
}

# Passes when the group has at least one phase block and every block reports
# zero patterns: the streaming block's "(N checkpoints, P patterns)" and the
# final-pass block's "New patterns created:". A block whose count cannot be
# read fails. Prints each block's count.
# Usage: check_no_patterns <file> <group>
check_no_patterns() {
    awk -v grp="  --- $2: " '
        function close_block() {
            if (inblock != "" && !(inblock in count)) { missing = 1; print inblock ": no pattern count" }
            inblock = ""
        }
        index($0, "===") == 1 { close_block() }
        index($0, "  --- ") == 1 {
            close_block()
            if (index($0, grp) == 1) { inblock = $0; blocks++ }
        }
        inblock ~ /Streaming Phase/ && $1 == "Keys" && match($0, /, [0-9]+ patterns\)/) {
            p = substr($0, RSTART + 2, RLENGTH - 2); sub(/ .*/, "", p); count[inblock] = p
        }
        inblock ~ /Final Pass/ && $1 == "New" && $2 == "patterns" { count[inblock] = $4 }
        END {
            close_block()
            if (blocks == 0) { print "no phase block for group"; exit 1 }
            bad = 0
            for (b in count) { print b ": " count[b] " pattern(s)"; if (count[b] + 0 != 0) bad = 1 }
            exit (missing || bad) ? 1 : 0
        }
    ' "$1"
}

# Writes the message-grouping / cluster-membership sub-section of <capture> to
# <outfile>; fails when either delimiter is absent or no cluster is listed.
# Usage: membership_section <capture> <outfile>
membership_section() {
    if ! grep -q '^=== message-grouping / cluster-membership ===$' "$1"; then
        echo "no '=== message-grouping / cluster-membership ===' in $1"; return 1
    fi
    if ! grep -q '^=== END message-grouping / cluster-membership ===$' "$1"; then
        echo "no '=== END message-grouping / cluster-membership ===' in $1"; return 1
    fi
    sed -n '/^=== message-grouping \/ cluster-membership ===$/,/^=== END message-grouping \/ cluster-membership ===$/p' "$1" > "$2"
    if ! grep -q '^  cluster: ' "$2"; then
        echo "cluster-membership in $1 lists no cluster"; return 1
    fi
}

# Passes when both captures carry a non-empty cluster-membership sub-section
# and the two are byte-identical.
# Usage: check_membership_identical <capture-a> <capture-b>
check_membership_identical() {
    membership_section "$1" "$1.membership" || return 1
    membership_section "$2" "$2.membership" || return 1
    if ! cmp -s "$1.membership" "$2.membership"; then
        echo "cluster-membership differs between runs:"
        { diff "$1.membership" "$2.membership" || true; } | head -20
        return 1
    fi
}

# Asserts the header thresholds, that all fixture keys reach the final pass,
# and the final pass's pattern count for one scenario.
# Usage: check_scenario <capture> <streaming T> <final-pass T> <expected patterns> <why>
check_scenario() {
    local out="$1" t="$2" f="$3" patterns="$4" why="$5"
    assert_command \
        command     "grep -Eq '^  Threshold: ${t}%  .*Final pass: on \\(threshold=${f}%,' '$out'" \
        label       "header reports sensitivity ${t}% and final pass at ${f}%" \
        asserts     "The message-grouping header reports the resolved -g sensitivity and the threshold the final pass scored at ($why)" \
        produced_by "$HEADER_PRODUCER" \
        contract    "$CONTRACT"
    assert_command \
        command     "[ \"\$(block_counter '$out' 'plain|200' 'Final Pass' 'Keys seen')\" = 4 ]" \
        label       'the final pass receives all 4 keys' \
        asserts     'Every fixture key reaches the occurrence ceiling, so streaming groups none of them and all 4 reach the final pass; any pattern counted in the final-pass block was formed there, at its own threshold' \
        produced_by 'group_similar_messages() in ltl (fp_keys_seen), after run_consolidation_pass() skips ceiling keys' \
        contract    "$CONTRACT"
    assert_command \
        command     "[ \"\$(block_counter '$out' 'plain|200' 'Final Pass' 'New patterns created')\" = $patterns ]" \
        label       "final pass creates $patterns pattern(s)" \
        asserts     "With pairs at Dice 77 and 89, a final pass scoring at ${f}% groups exactly $patterns pair(s) ($why)" \
        produced_by "$FINAL_PASS_PRODUCER" \
        contract    "$CONTRACT"
}

# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# every assertion reads the message-grouping section; one wide bucket, no empty
# buckets and a single reported row keep the rest of the run trivial.
SHAPE="-bs 1440 -oe -n 1 -V message-grouping"

current_scenario="sensitivity-70"
echo "[$current_scenario]"
out="$TMP_DIR/g70.out"
if capture_section "$out" $SHAPE -g 70 "$FIXTURE"; then
    check_scenario "$out" 70 70 2 'the final pass follows -g 70, so both the Dice 77 and Dice 89 pairs group'
fi

current_scenario="sensitivity-95"
echo "[$current_scenario]"
out="$TMP_DIR/g95.out"
if capture_section "$out" $SHAPE -g 95 "$FIXTURE"; then
    check_scenario "$out" 95 95 0 'the final pass follows -g 95, so neither pair groups'
fi

current_scenario="default-sensitivity"
echo "[$current_scenario]"
out="$TMP_DIR/gdefault.out"
# -g without a value takes the default sensitivity; -V follows so the option
# parser does not read the fixture path as the -g value.
if capture_section "$out" -bs 1440 -oe -n 1 -g -V message-grouping "$FIXTURE"; then
    check_scenario "$out" 85 85 1 'the final pass follows the default 85, so only the Dice 89 pair groups'
fi

current_scenario="explicit-final-threshold"
echo "[$current_scenario]"
out="$TMP_DIR/g95-final70.out"
if capture_section "$out" $SHAPE -g 95 --final-threshold 70 "$FIXTURE"; then
    check_scenario "$out" 95 70 2 'an explicit --final-threshold 70 overrides -g 95 for the final pass only'
fi

# Candidate search scenarios. -du us binds the fixture's microsecond durations
# as the source log is read; -xqs keeps the query string, which carries the
# per-request values the search must look past. Same SHAPE otherwise.
DOWNLOAD_KEYS=$(wc -l < "$FIXTURE_DOWNLOADS" | tr -d ' ')

current_scenario="signed-downloads-75"
echo "[$current_scenario]"
out_downloads_75="$TMP_DIR/downloads-g75.out"
if capture_section "$out_downloads_75" $SHAPE -du us -xqs -g 75 "$FIXTURE_DOWNLOADS"; then
    assert_command \
        command     "check_rows_at_most '$out_downloads_75' 'plain|200' $DOWNLOAD_KEYS 10" \
        label       "plain|200 reduces $DOWNLOAD_KEYS keys to at most 10 rows" \
        asserts     "Every signed download key has a partner at Dice 75 or above, so at -g 75 the candidate search finds them and the group reduces to at most 10 rows; a search that passes over partners whose rarest trigrams are per-request values leaves every key ungrouped" \
        produced_by "$REDUCTION_PRODUCER" \
        contract    "$CONTRACT_SEARCH (criterion 1)"
fi

current_scenario="signed-downloads-85"
echo "[$current_scenario]"
out="$TMP_DIR/downloads-g85.out"
if capture_section "$out" $SHAPE -du us -xqs -g 85 "$FIXTURE_DOWNLOADS"; then
    assert_command \
        command     "check_no_patterns '$out' 'plain|200'" \
        label       'no pattern formed in any plain|200 block' \
        asserts     "No two signed download keys score Dice 85, so at -g 85 no phase forms a pattern: the streaming block reports 0 patterns and a final-pass block, when present, creates 0" \
        produced_by "$PATTERNS_PRODUCER" \
        contract    "$CONTRACT_SEARCH (criterion 2)"
fi

current_scenario="uuid-pair-85"
echo "[$current_scenario]"
out="$TMP_DIR/uuid-g85.out"
if capture_section "$out" $SHAPE -g 85 "$FIXTURE_UUID"; then
    assert_command \
        command     "! grep -n '<UUID>' '$out'" \
        label       'no <UUID> placeholder anywhere in the output' \
        asserts     "Consolidation never replaces a UUID, so no <UUID> placeholder reaches any pattern, row or verbose line" \
        produced_by 'build_consolidation_ngram_index() and find_consolidation_candidates() in ltl (trigram sets scored by dice_coefficient())' \
        contract    "$CONTRACT_SEARCH (criterion 4)"
    assert_command \
        command     "check_rows_equal '$out' 'plain|200' 2 2" \
        label       'the two keys remain two rows' \
        asserts     "The two keys differ only in a UUID and score Dice 73 as written, so at -g 85 they are not grouped; grouping them means Dice was scored with the UUIDs replaced" \
        produced_by "$REDUCTION_PRODUCER" \
        contract    "$CONTRACT_SEARCH (criterion 4)"
fi

current_scenario="uuid-pair-85-masked"
echo "[$current_scenario]"
out="$TMP_DIR/uuid-g85-masked.out"
if capture_section "$out" $SHAPE -g 85 -uuid "$FIXTURE_UUID"; then
    assert_command \
        command     "check_rows_equal '$out' 'plain|200' 1 1" \
        label       'with -uuid the two lines are one row' \
        asserts     "-uuid masks the UUID before the message key is built, so the two lines share one key and report one row" \
        produced_by "read_and_process_logs() in ltl (-uuid mask on the message), reported by pipeline_finalize()" \
        contract    "$CONTRACT_SEARCH (criterion 4)"
fi

current_scenario="signed-downloads-75-repeat"
echo "[$current_scenario]"
out="$TMP_DIR/downloads-g75-repeat.out"
if [[ -s "$out_downloads_75" ]] && capture_section "$out" $SHAPE -du us -xqs -g 75 "$FIXTURE_DOWNLOADS"; then
    assert_command \
        command     "check_membership_identical '$out_downloads_75' '$out'" \
        label       'cluster-membership byte-identical across two runs' \
        asserts     "The same invocation on the same input groups the same keys under the same canonical forms: the cluster-membership sub-section is non-empty and byte-identical between two runs" \
        produced_by "$MEMBERSHIP_PRODUCER" \
        contract    "$CONTRACT_SEARCH (criterion 5)"
fi

# --- Final-pass skip when streaming absorbed nothing (#584) -----------------
#
# The download fixture's keys have no partner at Dice 85, so streaming absorbs
# none of them: the condition the skip tests. The population floor is lowered
# with the hidden --skip-final-min-keys so the decision is exercised on a
# committed 400-line fixture instead of a corpus-sized input.
#
# `-bs 1440 -oe -n 1`: the assertions read the message-grouping section and the
# notice on stderr, neither of which depends on the time axis or the rendered
# table.

CONTRACT_SKIP='features/fuzzy-message-consolidation.md § Design: skip the final pass when streaming absorbed nothing (#584) — acceptance criteria'
SKIP_PRODUCER='group_similar_messages() in ltl (the per-group skip decision at the streaming/final-pass boundary), reported by pipeline_finalize()'
NOTICE_PRODUCER='report_skipped_final_pass() in ltl'
CLIFF_PRODUCER='consolidation_cliff_edge() in ltl, called from group_similar_messages() when the skip fires'

current_scenario="skip-final-pass-fires"
echo "[$current_scenario]"
out="$TMP_DIR/skip-fires.out"
if capture_section "$out" $SHAPE -du us -xqs -g 85 --skip-final-min-keys 100 "$FIXTURE_DOWNLOADS"; then
    assert_command \
        command     "grep -q '^    Final pass skipped:    yes\$' '$out'" \
        label       'the final pass is skipped when streaming absorbed nothing and the population is above the floor' \
        asserts     "A group whose streaming phase absorbed at or below the absorption floor, and which would hand at least the floor number of keys to the final pass, has that pass skipped" \
        produced_by "$SKIP_PRODUCER" \
        contract    "$CONTRACT_SKIP (criterion 1)"

    assert_command \
        command     "grep -q 'the final consolidation pass was skipped' '$out.stderr'" \
        label       'the notice states that the final pass was skipped and why' \
        asserts     "When the skip fires, ltl prints a notice naming what was skipped and the reason: grouping at the requested similarity absorbed almost none of the data as it was read" \
        produced_by "$NOTICE_PRODUCER" \
        contract    "$CONTRACT_SKIP (criterion 1)"

    assert_command \
        command     "grep -qE 'No messages were grouped before it was skipped|already grouped before it was skipped remain grouped' '$out.stderr'" \
        label       'the notice is truthful about rows grouped before the skip' \
        asserts     "The notice states what happened to rows grouped before the skip: either that none were, or that those already grouped remain grouped in the output" \
        produced_by "$NOTICE_PRODUCER" \
        contract    "$CONTRACT_SKIP (criterion 1, criterion 7)"

    assert_command \
        command     "grep -qE '^    Similarity cliff edge: [0-9]+%\$' '$out' && awk '/^    Similarity cliff edge:/ { gsub(/[^0-9]/, \"\", \$4); exit (\$4 < 85 && \$4 >= 50) ? 0 : 1 }' '$out'" \
        label       'a similarity cliff edge is reported, below the requested sensitivity' \
        asserts     "When the skip fires, the run reports the similarity the data clusters at, and it falls below the requested sensitivity (the data does not group at what was asked for)" \
        produced_by "$CLIFF_PRODUCER" \
        contract    "$CONTRACT_SKIP (criterion 5)"
fi

current_scenario="skip-final-pass-population-below-floor"
echo "[$current_scenario]"
out="$TMP_DIR/skip-below-floor.out"
if capture_section "$out" $SHAPE -du us -xqs -g 85 --skip-final-min-keys 100000 "$FIXTURE_DOWNLOADS"; then
    assert_command \
        command     "grep -q '^    Final pass skipped:    no\$' '$out'" \
        label       'a group below the population floor keeps its final pass' \
        asserts     "Absorbing nothing is not on its own a reason to skip: a group handing fewer keys forward than the floor runs its final pass, because skipping a cheap pass saves nothing and costs grouping" \
        produced_by "$SKIP_PRODUCER" \
        contract    "$CONTRACT_SKIP (criterion 4)"

    assert_command \
        command     "! grep -q 'the final consolidation pass was skipped' '$out.stderr'" \
        label       'no notice when nothing is skipped' \
        asserts     "A run that skips no final pass prints no skip notice" \
        produced_by "$NOTICE_PRODUCER" \
        contract    "$CONTRACT_SKIP (criterion 2)"
fi

current_scenario="skip-final-pass-absorbing-data"
echo "[$current_scenario]"
out="$TMP_DIR/skip-absorbing.out"
if capture_section "$out" $SHAPE -du us -xqs -g 75 --skip-final-min-keys 100 "$FIXTURE_DOWNLOADS"; then
    assert_command \
        command     "grep -q '^    Final pass skipped:    no\$' '$out'" \
        label       'a sensitivity the data does reach keeps its final pass' \
        asserts     "At a sensitivity whose partners the data does have, streaming absorbs and the final pass runs: the skip is governed by absorption, not by population size alone" \
        produced_by "$SKIP_PRODUCER" \
        contract    "$CONTRACT_SKIP (criterion 2, criterion 3)"
fi

echo
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    printf '  failed: %s\n' "${failures[@]}"
    exit 1
fi
exit 0
