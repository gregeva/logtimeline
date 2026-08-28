#!/usr/bin/env bash
# validate-recursive-file-selection.sh — harness for the -r/--recursive file
# argument expansion contract.
#
# The system under test is file selection: which files a pattern resolves to,
# how many, in what order, and whether any is selected twice. `-r` replaces
# one-level matching with all-depth matching of the same filename pattern
# against the same root set, and nothing else changes — every assertion here
# is a consequence of that sentence.
#
# Assertion surface: `-V format-detection`, which emits `files: N` followed by
# one `file: <path>` line per entry in @in_files order (the canonical order).
# That carries everything the contract needs. It is more reliable than the
# rendered summary, which aggregates across files: the fixture files are empty,
# so no file contributes lines and none would be distinguishable there, but
# each still appears as a `file:` entry here.
#
# Two scenarios instead assert on stderr, because what they test is a
# diagnostic and not a selection: the note naming directories the sweep could
# not read, and the guidance a failed `-r` run gives about quoting the pattern.
#
# Each assertion records, per HARNESS-DESIGN.md § Self-documenting assertions:
#   - asserts:     the file-selection invariant being tested
#   - produced_by: where in ltl the behaviour is produced (function name)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure alongside the failing command.
#
# Usage: ./tests/validate-recursive-file-selection.sh

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
# never inherited; issue #438).
neutralize_colour_env

# Committed fixture tree. Empty files with numeric extensions: .888 matches,
# .123 and .000 are non-matching siblings at each level, so filtering is
# assertable positively and negatively and a wrong `file:` line is
# self-evident on failure. Numeric extensions cannot collide with code or
# tooling extensions and are untouched by .gitignore, unlike *.log and *.csv.
FIXTURE_ROOT="$REPO_DIR/tests/fixtures/recursive-file-selection"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
if [[ ! -d "$FIXTURE_ROOT" ]]; then
    echo "ERROR: fixture tree not found: $FIXTURE_ROOT"; exit 1
fi

TMP_DIR=$(mktemp -d); trap 'chmod -R u+rwX "$TMP_DIR" 2>/dev/null || true; rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

# Invocation shape (tests/HARNESS-DESIGN.md § Invocation coherence): every
# assertion reads the file-selection lines of -V format-detection and never a
# bucket, so the run uses the coarsest bucket and skips empty ones. -n 1 keeps
# the message table to a single row. The fixture files are empty, so the run
# reads no lines at all — the whole cost is argument expansion.
SHAPE="-bs 1440 -oe -n 1 -V format-detection"

CONTRACT_GOVERNING='features/420-recursive-file-selection.md § Governing statement — -r replaces one-level matching with all-depth matching of the same filename pattern against the same root set; nothing else changes'
PRODUCED_BY_EXPAND='expand_recursive_pattern() in ltl (breadth-first sweep) via the file-argument globbing loop in adapt_to_command_line_options()'

# Run ltl and capture the `files:`/`file:` selection lines to <outfile>, with
# stderr to <outfile>.stderr. Fails hard if ltl itself fails (HARNESS-DESIGN.md
# Trap 1: never let a crashed run read as "no files selected").
# Usage: capture_selection <outfile> <ltl-args-and-patterns...>
capture_selection() {
    local outfile="$1"; shift
    local errfile="$outfile.stderr"
    local rawfile="$outfile.raw"
    set +e
    # Run inside TMP_DIR so cwd artifacts never land in the repo
    # (HARNESS-DESIGN.md Trap 9: temp artifacts stay out of deliverables).
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni "$@" ) > "$rawfile" 2>"$errfile"
    local rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $rc" >&2
        sed 's/^/        /' "$errfile" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: ltl run failed"); return 1
    fi
    # -a: -V output can carry non-ASCII, which flips grep into binary mode.
    grep -a '^files:\|^file:' "$rawfile" > "$outfile" || true
    if [[ ! -s "$outfile" ]]; then
        echo "  FAIL  $current_scenario :: no file-selection lines in -V format-detection output" >&2
        echo "        (a missing anchor is a failure, not a pass — HARNESS-DESIGN.md § Harnesses must fail on missing anchors)" >&2
        fail=$((fail + 1)); failures+=("$current_scenario :: missing selection anchor"); return 1
    fi
    # Runtime-warning cleanliness at the point of capture (HARNESS-DESIGN.md
    # § Runtime-warning cleanliness). The intentional unreadable-directory
    # note this harness asserts never carries the ` at <file> line <N>`
    # suffix, so the check and the note assertion coexist on one capture.
    if ! assert_no_runtime_warnings "$errfile" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# Self-documenting assertion (assert_command shape, HARNESS-DESIGN.md):
# runs `command`; PASS on exit 0, FAIL otherwise. On failure surfaces the
# command plus asserts/produced_by/contract.
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

# --- Scenario: without -r, selection is exactly what ships today (D3) ---
# The same pattern that recurses below matches only the root level here. This
# is the baseline the depth-widening assertion is measured against.
current_scenario="non-recursive-unchanged"
echo "[$current_scenario]"
plain="$TMP_DIR/plain.sel"
if capture_selection "$plain" $SHAPE "$FIXTURE_ROOT/*.888"; then
    assert_command \
        command     "grep -aq '^files: 2\$' '$plain'" \
        label       'without -r, only the two root-level .888 files are selected' \
        asserts     'Without -r, a file argument matches exactly one directory level, as it does today: the fixture root holds two .888 files and the pattern selects those two, no deeper ones' \
        produced_by 'the file-argument globbing loop in adapt_to_command_line_options() in ltl (bsd_glob branch)' \
        contract    'features/420-recursive-file-selection.md § D3 — without -r, behavior is exactly what ships today; -r is purely additive'
    assert_command \
        command     "grep -aq '/alpha\\.888\$' '$plain' && grep -aq '/beta\\.888\$' '$plain'" \
        label       'the two selected files are the root-level ones' \
        asserts     'The non-recursive selection is the root-level .888 files specifically, not an arbitrary pair of the same size' \
        produced_by 'the file-argument globbing loop in adapt_to_command_line_options() in ltl (bsd_glob branch)' \
        contract    'features/420-recursive-file-selection.md § D3 — without -r, behavior is exactly what ships today'
fi

# --- Scenario: -r widens the same pattern to every depth (D1, D4, D5) ---
current_scenario="recursive-depth-widening"
echo "[$current_scenario]"
rec="$TMP_DIR/recursive.sel"
if capture_selection "$rec" $SHAPE -r "$FIXTURE_ROOT/*.888"; then
    assert_command \
        command     "grep -aq '^files: 8\$' '$rec'" \
        label       '-r selects all eight .888 files across all four depths' \
        asserts     'With -r, the filename component of the pattern matches at every depth beneath the directory component: the fixture tree holds eight .888 files spread over four levels and all eight are selected' \
        produced_by "$PRODUCED_BY_EXPAND" \
        contract    "$CONTRACT_GOVERNING"
    assert_command \
        command     "! grep -aq '\\.123\$' '$rec' && ! grep -aq '\\.000\$' '$rec'" \
        label       'non-matching siblings are filtered out at every depth' \
        asserts     'The filename component filters files at depth exactly as it does at the root: .123 and .000 siblings sit beside .888 files at every level of the fixture tree and none is selected' \
        produced_by 'basename_matches_glob() in ltl (per-basename filename filter)' \
        contract    'features/420-recursive-file-selection.md § D1 — the final component is a filename filter applied to basenames at every depth beneath each root'
    assert_command \
        command     "grep -aq '/archive/2026-07/papa\\.888\$' '$rec' && grep -aq '/archive/2026-08/romeo\\.888\$' '$rec'" \
        label       'directories are descended regardless of their own names' \
        asserts     'The filename filter gates files only, never directories: the directories 2026-07 and 2026-08 do not match the *.888 filter themselves, yet are entered and their .888 contents selected' \
        produced_by "$PRODUCED_BY_EXPAND" \
        contract    'features/420-recursive-file-selection.md § D4 — directories are descended regardless of their own name; same shape as grep --include'
    assert_command \
        command     "grep -aq '/nested/deep/deeper/bravo\\.888\$' '$rec'" \
        label       'the sweep reaches the deepest level of the tree' \
        asserts     'Recursion is all-depth, not one-extra-level: the deepest .888 file sits three directories below the root and is selected' \
        produced_by "$PRODUCED_BY_EXPAND" \
        contract    "$CONTRACT_GOVERNING"

    # Breadth-first with alphanumeric ordering within each level (D5). The
    # expected order is asserted whole rather than pairwise: any reordering,
    # depth interleaving, or omission shows up as one diff.
    cat > "$TMP_DIR/expected-order.txt" <<EOF
alpha.888
beta.888
archive/mike.888
nested/xray.888
archive/2026-07/papa.888
archive/2026-08/romeo.888
nested/deep/zulu.888
nested/deep/deeper/bravo.888
EOF
    sed -e 's/^file: //' -e "s|^$FIXTURE_ROOT/||" "$rec" | grep -av '^files:' > "$TMP_DIR/actual-order.txt"
    assert_command \
        command     "diff -u '$TMP_DIR/expected-order.txt' '$TMP_DIR/actual-order.txt' > '$TMP_DIR/order.diff' 2>&1" \
        label       'breadth-first order, alphanumeric within each level' \
        asserts     'Every match at one level precedes every match one level down (shallower always first, regardless of name); within a level, matching files are emitted in alphanumeric order and subdirectories are queued in alphanumeric order, so the traversal is deterministic and identical across platforms' \
        produced_by "$PRODUCED_BY_EXPAND" \
        contract    'features/420-recursive-file-selection.md § D5 — breadth-first traversal, alphanumeric within each level; log trees put current files at the top and archives nested below, so breadth-first leads with the most relevant files'
fi

# --- Scenario: an empty directory part makes the root the current directory (D1) ---
current_scenario="empty-directory-part"
echo "[$current_scenario]"
dotroot="$TMP_DIR/dotroot.sel"
set +e
( cd "$FIXTURE_ROOT" && "$LTL" --disable-progress -ni $SHAPE -r '*.888' ) > "$TMP_DIR/dotroot.raw" 2>"$dotroot.stderr"
dotroot_rc=$?
set -e
if [[ "$dotroot_rc" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl exited $dotroot_rc" >&2
    sed 's/^/        /' "$dotroot.stderr" >&2
    fail=$((fail + 1)); failures+=("$current_scenario :: ltl run failed")
else
    grep -a '^files:\|^file:' "$TMP_DIR/dotroot.raw" > "$dotroot" || true
    if ! assert_no_runtime_warnings "$dotroot.stderr" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
    assert_command \
        command     "grep -aq '^files: 8\$' '$dotroot'" \
        label       'a pattern with no directory part recurses from the current directory' \
        asserts     'When the file argument carries no directory component, the root is the current directory: run from the fixture root, the bare pattern *.888 selects the same eight files the fully-qualified pattern does' \
        produced_by "$PRODUCED_BY_EXPAND" \
        contract    'features/420-recursive-file-selection.md § D1 — an empty directory part makes the root the current directory, so -r *.888 recurses from there'
    assert_command \
        command     "grep -aq '^file: alpha\\.888\$' '$dotroot'" \
        label       'paths from a "." root are emitted without a "./" prefix' \
        asserts     'A current-directory sweep emits the plain relative path the user would have typed, not a ./-prefixed one' \
        produced_by "$PRODUCED_BY_EXPAND" \
        contract    'features/420-recursive-file-selection.md § D1 — an empty directory part makes the root the current directory'
fi

# --- Scenario: results are deduplicated when patterns nest (D6) ---
current_scenario="dedup-across-nesting-patterns"
echo "[$current_scenario]"
dedup="$TMP_DIR/dedup.sel"
if capture_selection "$dedup" $SHAPE -r "$FIXTURE_ROOT/*.888" "$FIXTURE_ROOT/archive/*.888"; then
    assert_command \
        command     "grep -aq '^files: 8\$' '$dedup'" \
        label       'a file reachable from two nesting patterns is selected once' \
        asserts     'The second pattern sweeps a subtree the first already swept, so its three .888 files are reached twice; with -r the selection is deduplicated and stays at eight files rather than growing to eleven. Reading a file twice would double its lines into the analysis' \
        produced_by 'the -r deduplication pass in adapt_to_command_line_options() in ltl (after the file-argument globbing loop)' \
        contract    'features/420-recursive-file-selection.md § D6 — multiple patterns expand independently; results are deduplicated when -r is given'
    assert_command \
        command     "[ \"\$(grep -ac '^file: ' '$dedup')\" -eq \"\$(grep -a '^file: ' '$dedup' | sort -u | wc -l | tr -d ' ')\" ]" \
        label       'no path appears twice in the selection' \
        asserts     'Deduplication is by path across the whole run, so the emitted file list contains no repeated entry' \
        produced_by 'the -r deduplication pass in adapt_to_command_line_options() in ltl' \
        contract    'features/420-recursive-file-selection.md § D6 — results are deduplicated when -r is given'
fi

# --- Scenario: a bare directory argument matches nothing, with or without -r (D2) ---
# A directory name carries no filename component, so there is nothing to match.
# ltl exits 2 with "unable to open any files" — the same outcome as today.
current_scenario="bare-directory-matches-nothing"
echo "[$current_scenario]"
for variant in "with-r" "without-r"; do
    args=($SHAPE)
    [[ "$variant" == "with-r" ]] && args+=(-r)
    set +e
    ( cd "$TMP_DIR" && "$LTL" --disable-progress -ni "${args[@]}" "$FIXTURE_ROOT/archive" ) \
        > "$TMP_DIR/baredir-$variant.out" 2>"$TMP_DIR/baredir-$variant.stderr"
    baredir_rc=$?
    set -e
    assert_command \
        command     "[ $baredir_rc -eq 2 ] && grep -aq 'unable to open any files' '$TMP_DIR/baredir-$variant.out' '$TMP_DIR/baredir-$variant.stderr'" \
        label       "bare directory argument selects nothing ($variant)" \
        asserts     'A file argument naming only a directory carries no filename component, so it matches nothing and ltl reports that it could not open any files — identical with and without -r, because -r changes where a filename pattern is matched, never what counts as one' \
        produced_by 'the file-argument globbing loop in adapt_to_command_line_options() in ltl (the -f filter and the empty-@in_files guard)' \
        contract    'features/420-recursive-file-selection.md § D2 — a bare directory argument matches nothing, with or without -r'
done

# --- Scenario: unreadable directories are skipped, the sweep continues, one note (D8) ---
# Constructed at run time via chmod: an unreadable directory cannot be
# committed, and the case does not apply on Windows.
current_scenario="unreadable-directory-note"
echo "[$current_scenario]"
if [[ "$(id -u)" -eq 0 ]]; then
    echo "  SKIP  $current_scenario :: running as root, which can read a 0-mode directory"
else
    SWEEP="$TMP_DIR/sweep"
    mkdir -p "$SWEEP/readable" "$SWEEP/locked"
    touch "$SWEEP/top.888" "$SWEEP/readable/reachable.888" "$SWEEP/locked/unreachable.888"
    chmod 000 "$SWEEP/locked"
    unreadable="$TMP_DIR/unreadable.sel"
    if capture_selection "$unreadable" $SHAPE -r "$SWEEP/*.888"; then
        assert_command \
            command     "grep -aq '^files: 2\$' '$unreadable' && grep -aq '/top\\.888\$' '$unreadable' && grep -aq '/readable/reachable\\.888\$' '$unreadable'" \
            label       'the sweep continues past an unreadable directory and collects everything readable' \
            asserts     'A directory that cannot be opened partway through a tree does not abort the sweep: the files above it and in its readable siblings are still selected' \
            produced_by 'expand_recursive_pattern() in ltl (opendir failure path)' \
            contract    'features/420-recursive-file-selection.md § D8 — unreadable directories: collect, continue, report once at the end'
        assert_command \
            command     "grep -aq 'Note: 1 directory could not be read and was skipped during recursive file selection' '$unreadable.stderr'" \
            label       'one note on stderr names the skipped directory' \
            asserts     'The gap left by an unreadable directory is reported rather than silent: a single Note on stderr states how many directories were skipped and names them. It goes to stderr so it stays clear of -o CSV and piped output' \
            produced_by 'read_and_process_logs() in ltl (end-of-processing note emission, @unreadable_directories)' \
            contract    'features/420-recursive-file-selection.md § D8 — reported as a single Note to STDERR at the tail of read_and_process_logs(), following the deferred-note precedent there'
        assert_command \
            command     "grep -aq \"locked\" '$unreadable.stderr' && [ \"\$(grep -ac 'could not be read and' '$unreadable.stderr')\" -eq 1 ]" \
            label       'the note is emitted once and names the directory' \
            asserts     'The skipped directories are accumulated during the sweep and reported in one note at the end, not once per directory as they are encountered' \
            produced_by 'read_and_process_logs() in ltl (end-of-processing note emission)' \
            contract    'features/420-recursive-file-selection.md § D8 — collect, continue, report once at the end'
    fi
    chmod 755 "$SWEEP/locked"
fi

# --- Scenario: a readable sweep emits no unreadable-directory note ---
current_scenario="silent-when-all-readable"
echo "[$current_scenario]"
if capture_selection "$TMP_DIR/silent.sel" $SHAPE -r "$FIXTURE_ROOT/*.888"; then
    assert_command \
        command     "! grep -aq 'could not be read' '$TMP_DIR/silent.sel.stderr'" \
        label       'no note when every directory in the sweep is readable' \
        asserts     'The unreadable-directory note is tied to an actual failure to open a directory, not to the use of -r: a fully readable tree produces no note' \
        produced_by 'read_and_process_logs() in ltl (end-of-processing note emission, guarded on @unreadable_directories)' \
        contract    'features/420-recursive-file-selection.md § D8 — unreadable directories: collect, continue, report once at the end'
fi

# --- Scenario: a -r run that selects nothing points at quoting the pattern ---
# Invocation shape (tests/HARNESS-DESIGN.md § Invocation coherence): the
# assertion reads a stderr diagnostic emitted while the file arguments are
# still being expanded, before a bucket, a table or a -V section exists, so the
# run carries no analysis options at all — the pattern is the whole input.
current_scenario="no-match-quoting-guidance"
echo "[$current_scenario]"
GUIDANCE_ANCHOR='Hint: with -r, put the file pattern in double quotes'
CONTRACT_GUIDANCE='features/445-unquoted-glob-consumed-by-shell-before-r.md § The failure message — the quoting guidance rides on the no-files failure and on no other path'

for variant in "with-r" "without-r"; do
    # The array is seeded with the two options every invocation in this harness
    # carries: bash 3.2 expands an empty array under `set -u` as an unbound
    # variable, which would abort the subshell before ltl ever ran.
    nomatch_args=(--disable-progress -ni)
    [[ "$variant" == "with-r" ]] && nomatch_args+=(-r)
    set +e
    ( cd "$TMP_DIR" && "$LTL" "${nomatch_args[@]}" 'no-such-*.888' ) \
        > "$TMP_DIR/nomatch-$variant.out" 2>"$TMP_DIR/nomatch-$variant.stderr"
    nomatch_rc=$?
    set -e
    # Runtime-warning cleanliness (HARNESS-DESIGN.md § Runtime-warning
    # cleanliness). The intentional diagnostics this scenario asserts on never
    # carry the ` at <file> line <N>` suffix, so both live on one capture.
    if ! assert_no_runtime_warnings "$TMP_DIR/nomatch-$variant.stderr" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
    assert_command \
        command     "[ $nomatch_rc -eq 2 ] && grep -aqF -- 'unable to open any files' '$TMP_DIR/nomatch-$variant.stderr'" \
        label       "a pattern matching nothing is a hard error ($variant)" \
        asserts     'A file pattern that selects no file leaves nothing to read, so the run stops with the same could-not-open-any-files error whether or not -r was given' \
        produced_by 'the empty-@in_files guard in adapt_to_command_line_options() in ltl, rendered via print_usage()' \
        contract    'features/445-unquoted-glob-consumed-by-shell-before-r.md § The failure message — a pattern matching no file stops the run with the same could-not-open-any-files error, with or without -r'
done

assert_command \
    command     "grep -aqF -- '$GUIDANCE_ANCHOR' '$TMP_DIR/nomatch-with-r.stderr'" \
    label       'the -r no-match failure tells the user to quote the pattern' \
    asserts     'When -r selected nothing, the failure names the commonest cause the tool cannot detect for itself: the shell consumed the pattern before ltl started. The guidance says to enclose the pattern in double quotes, and why' \
    produced_by 'the empty-@in_files guard in adapt_to_command_line_options() in ltl (the -r hint handed to print_usage()), rendered by print_usage()' \
    contract    "$CONTRACT_GUIDANCE"

assert_command \
    command     "! grep -aqF -- '$GUIDANCE_ANCHOR' '$TMP_DIR/nomatch-without-r.stderr'" \
    label       'the same failure without -r carries no quoting guidance' \
    asserts     'The guidance is specific to -r: without it, a pattern the shell expanded selects exactly what ltl would have selected itself, so quoting is not the explanation and the advice would misdirect' \
    produced_by 'the empty-@in_files guard in adapt_to_command_line_options() in ltl (the hint is conditional on -r)' \
    contract    "$CONTRACT_GUIDANCE"

# Reuses the stderr of the preceding scenario's successful -r sweep rather than
# running ltl again: the assertion is that a run which selected files says
# nothing about quoting, and that run has already happened.
assert_command \
    command     "[ -f '$TMP_DIR/silent.sel.stderr' ] && ! grep -aqF -- '$GUIDANCE_ANCHOR' '$TMP_DIR/silent.sel.stderr'" \
    label       'a -r run that selected files carries no quoting guidance' \
    asserts     'The guidance is tied to selecting nothing, never to the use of -r: a sweep that found its files says nothing about quoting, so a correct invocation is never warned about a problem it does not have' \
    produced_by 'the empty-@in_files guard in adapt_to_command_line_options() in ltl (the hint is reached only on the failure path)' \
    contract    "$CONTRACT_GUIDANCE"

echo
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    printf '  failed: %s\n' "${failures[@]}"
    exit 1
fi
exit 0
