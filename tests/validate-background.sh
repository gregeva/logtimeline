#!/usr/bin/env bash
# validate-background.sh — Validate the `-V background` section: what settles
# the background the output is drawn for, and what ltl asks the terminal
# (features/749-terminal-colour-codes.md § 13, AC1, AC3; D3).
# Usage: ./tests/validate-background.sh [--scenario NAME]... [--list]
#
# Follows the self-documenting assertion design from tests/HARNESS-DESIGN.md.
# Every assertion records:
#   - asserts:     the application invariant being tested
#   - produced_by: where in ltl the invariant is produced (function name)
#   - contract:    the stability contract that makes it stable
#
# Why this harness exists: the background is one setting for the whole run.
# -dbg and -lbg settle it, -dbg winning; with neither, a run in a terminal asks
# the terminal for its background colour once, and a run with no terminal, or
# whose terminal does not answer, has no background known. The terminal's name
# is asked only when something reads it, and nothing in a run does.
#
# The option scenarios run piped. The terminal scenarios run ltl in a tmux
# pane whose background is set by its window style, which tmux answers the
# colour query with (tmux 3.8: `window-style bg=#fbfbfb` answers
# rgb:fbfb/fbfb/fbfb; an unstyled pane does not answer). The style is set
# before ltl starts. macOS and Linux only; skipped where tmux is absent.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="${LTL:-$REPO_DIR/ltl}"

# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# every scenario reads the -V background section, which is settled from the
# options and the terminal before any line is read; the ten-line fixture at
# `-bs 1440 -oe -n 1 -osum` produces the same section as any input.
FIXTURE="$REPO_DIR/tests/fixtures/http-status-families.txt"
SHAPE="-ni -bs 1440 -oe -n 1 -osum"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

neutralize_colour_env

DOC='features/749-terminal-colour-codes.md'
C_SECTION="$DOC § 13 (the -V background section contract)"
C_OPTIONS="features/665-background-setting-global.md § 2 (-dbg wins over -lbg whenever both are given); $DOC AC1"
C_ASK="$DOC AC1 (a run in a terminal asks it for its background once; with no reply the background is not known)"
C_NAME="$DOC D3 (the terminal's name is asked only when something reads it)"

scenario_register \
    option-dbg option-lbg option-lbg-then-dbg option-dbg-then-lbg option-long-forms piped \
    terminal-light terminal-dark terminal-silent terminal-option
scenario_parse_args "$@"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi

pass=0
fail=0
failures=()
current_scenario=""

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

# run_failed REASON STDERR: one failure for a run that gave nothing to read;
# the caller skips its checks.
run_failed() {
    echo "  FAIL  $current_scenario :: $1"
    echo "        asserts:     the run exits 0 and writes the output its checks read"
    echo "        produced_by: ltl"
    echo "        contract:    tests/HARNESS-DESIGN.md Trap 13"
    sed 's/^/        | /' "$2" | head -5
    echo "  SKIP  $current_scenario :: its checks (the run gave nothing to read)"
    fail=$((fail + 1)); failures+=("$current_scenario :: $1")
}

check_warnings() {
    if ! assert_no_runtime_warnings "$1" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
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

# The section alone, out of a capture, so a pattern cannot match elsewhere.
SECTION=""
extract_section() {
    SECTION="$1.section"
    sed -n '/^=== background ===$/,/^=== END background ===$/p' "$1" > "$SECTION"
}

# run_piped ARGS...: ltl piped with -V background; the section in SECTION.
run_piped() {
    local out="$TMP_DIR/$current_scenario.txt" rc=0
    # shellcheck disable=SC2086
    "$LTL" --disable-progress $SHAPE -V background "$@" "$FIXTURE" > "$out" 2> "$out.stderr" || rc=$?
    if [[ $rc -ne 0 || ! -s "$out" ]]; then
        run_failed "the -V background run (exit $rc): $*" "$out.stderr"
        return 1
    fi
    check_warnings "$out.stderr"
    extract_section "$out"
}

tmux_ready() {
    if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == CYGWIN* ]] || ! command -v tmux > /dev/null 2>&1; then
        echo "  SKIP  $current_scenario :: tmux is not available on this host"
        return 1
    fi
}

# run_pane STYLE ARGS...: ltl in a tmux pane of its own, its window style
# STYLE (or none) set before ltl starts, standard input and output the pane,
# standard error to a file; the pane's history in a capture, the section in
# SECTION. The environment names no terminal (TERM_PROGRAM, which tmux sets,
# and WT_SESSION are removed), as over SSH, so a run that read the name would
# have to ask for it.
run_pane() {
    local style="$1"; shift
    local out="$TMP_DIR/$current_scenario.txt" sess="ltl-background-$$-$RANDOM" args i
    printf -v args '%q ' "$(command -v perl)" "$LTL" --disable-progress $SHAPE -V background "$@" "$FIXTURE"
    tmux new-session -d -s "$sess" -x 160 -y 50 -c "$TMP_DIR" \
        bash --noprofile --norc -c "tmux wait-for go-$sess; env -u TERM_PROGRAM -u WT_SESSION $args 2> '$out.stderr'; echo EXIT=\$?; sleep 30"
    [[ "$style" != none ]] && tmux set-option -w -t "$sess" window-style "$style"
    tmux wait-for -S "go-$sess"
    for i in $(seq 1 150); do
        tmux capture-pane -p -J -S - -t "$sess" 2>/dev/null | grep -q '^EXIT=' && break
        sleep 0.1
    done
    tmux capture-pane -p -J -S - -t "$sess" > "$out" 2>/dev/null || true
    tmux kill-session -t "$sess" 2>/dev/null || true
    local rc
    rc=$(sed -n 's/^EXIT=//p' "$out" | tail -1)
    if [[ "$rc" != 0 ]]; then
        run_failed "the -V background run in a tmux pane (exit ${rc:-none}): $*" "$out.stderr"
        return 1
    fi
    check_warnings "$out.stderr"
    extract_section "$out"
}

# assert_settled BACKGROUND SETTLED_BY TERMINAL: the section's settlement facts.
assert_settled() {
    local bg="$1" by="$2" terminal="$3" contract="$4"
    assert_line "$SECTION" \
        pattern     '^=== END background ===$' \
        asserts     'The background section is emitted whenever -V background is requested, bracketed by its start and END markers' \
        produced_by 'emit_background_verbose() in ltl' \
        contract    "$C_SECTION; tests/HARNESS-DESIGN.md section Delimiter contract"
    assert_line "$SECTION" \
        pattern     "^background: ${bg}\$" \
        asserts     "background reports what the output is drawn for (${bg}), - when it is not known" \
        produced_by 'settle_background() in ltl' \
        contract    "$contract"
    assert_line "$SECTION" \
        pattern     "^settled_by: ${by}\$" \
        asserts     "settled_by reports what settled the background (${by}): -dbg or -lbg, the terminal's answer, or none" \
        produced_by 'settle_background() in ltl' \
        contract    "$contract"
    assert_line "$SECTION" \
        pattern     "^terminal: ${terminal}\$" \
        asserts     "terminal reports whether standard input and output are a terminal in the foreground (${terminal}), the condition for asking" \
        produced_by 'terminal_attached() in ltl' \
        contract    "$C_SECTION"
    local colours=today
    [[ "$bg" != '-' ]] && colours="$bg"
    assert_line "$SECTION" \
        pattern     "^colours: ${colours}\$" \
        asserts     "colours reports the colours written (${colours}): the set for the background when it is known, ltl's own codes (today) when it is not" \
        produced_by 'resolve_colour_set() in ltl' \
        contract    "$C_SECTION; $DOC AC2, AC4"
}

# assert_query NAME SENT ANSWERED CONTRACT: one query line.
assert_query() {
    local q="$1" sent="$2" answered="$3" contract="$4" ms
    if [[ "$sent" == yes ]]; then ms='[0-9]+'; else ms='-'; fi
    assert_line "$SECTION" \
        pattern     "^query: ${q} sent=${sent} answered=${answered} elapsed_ms=${ms}\$" \
        asserts     "the ${q} query was sent=${sent}, answered=${answered}" \
        produced_by 'terminal_ask() in ltl, through terminal_background() and terminal_name()' \
        contract    "$contract"
}

# assert_no_name_query: D3, on every run.
assert_no_name_query() {
    assert_query name no no "$C_NAME"
    assert_query identity no no "$C_NAME"
}

# ---------------------------------------------------------------------------
# The options, piped: nothing is asked.
# ---------------------------------------------------------------------------
scenario_option() {
    scenario_wanted "$1" || return 0
    current_scenario="$1"; shift
    local bg="$1" by="$2"; shift 2
    echo "[$current_scenario]"
    run_piped "$@" || return 0
    assert_settled "$bg" "$by" no "$C_OPTIONS"
    assert_query background no no "$C_ASK"
    assert_no_name_query
}

scenario_option option-dbg           dark  -dbg -dbg
echo ""
scenario_option option-lbg           light -lbg -lbg
echo ""
scenario_option option-lbg-then-dbg  dark  -dbg -lbg -dbg
echo ""
scenario_option option-dbg-then-lbg  dark  -dbg -dbg -lbg
echo ""
scenario_option option-long-forms    light -lbg --light-background
echo ""
# No option and no terminal: nothing is asked, and the background is not known.
scenario_option piped                '-'   none
echo ""

# ---------------------------------------------------------------------------
# In a terminal: asked once, and settled by the answer when one comes.
# ---------------------------------------------------------------------------
scenario_terminal() {
    scenario_wanted "$1" || return 0
    current_scenario="$1"; shift
    local style="$1" bg="$2" by="$3" sent="$4" answered="$5" reply="$6"; shift 6
    echo "[$current_scenario]"
    tmux_ready || return 0
    run_pane "$style" "$@" || return 0
    assert_settled "$bg" "$by" yes "$C_ASK"
    assert_query background "$sent" "$answered" "$C_ASK"
    assert_line "$SECTION" \
        pattern     "^background_reply: ${reply}\$" \
        asserts     "background_reply reports the colour the terminal answered (${reply})" \
        produced_by 'terminal_background() in ltl' \
        contract    "$C_SECTION"
    assert_no_name_query
}

scenario_terminal terminal-light  'bg=#fbfbfb' light terminal yes yes 'fbfb/fbfb/fbfb'
echo ""
scenario_terminal terminal-dark   'bg=#292f3b' dark  terminal yes yes '2929/2f2f/3b3b'
echo ""
# An unstyled pane does not answer: asked, and the background is not known.
scenario_terminal terminal-silent none         '-'   none     yes no  '-'
echo ""
# An option settles it in a terminal too, and nothing is asked.
scenario_terminal terminal-option 'bg=#292f3b' light -lbg     no  no  '-' -lbg

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL BACKGROUND TESTS PASSED"
