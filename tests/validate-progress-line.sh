#!/usr/bin/env bash
# validate-progress-line.sh — the read pass's progress line (Issues #397, #446).
#
# While a run reads its input, ltl rewrites one line in place reporting what it
# is doing: how far through the current file it is, how far through the whole
# selected set, which file of how many is in flight, the line counts and the
# rate. That line is the only feedback a long run gives, and nothing asserted
# against it until this harness existed — every other harness runs
# --disable-progress, so the whole surface could break silently.
#
# What it holds:
#
#   - the multi-file line carries both percentages (file over overall), the
#     file counter, the current line, the run total and the filename, in that
#     order, with the filename last;
#   - the overall percentage is bytes-based over the whole selected set: three
#     fixture files of known sizes make each frame's figure an arithmetic fact,
#     not a plausible-looking number;
#   - a run reports something even when it finishes inside one repaint
#     interval — the small-file symptom that the every-N-lines gate left behind
#     (#31), which is why the opening frame is painted outside the throttle;
#   - the single-file run shows the file percentage alone: no overall figure,
#     no counter, because a second identical percentage says nothing;
#   - the run ends on 'Processing completed.', so the last thing the reader
#     sees is never a frame parked below 100%;
#   - --disable-progress emits no progress text at all;
#   - a narrow terminal shortens the filename rather than wrapping the line,
#     and the line never exceeds the width the clear covers.
#
# This is a RENDER-INVARIANT harness (tests/HARNESS-DESIGN.md § Render-invariant
# harnesses): the rendered line is the surface under test, and there is no -V
# equivalent — the line exists only while the read pass runs. It asserts
# properties of that surface (which fields appear, in what order, what the
# percentages must equal given the fixture sizes), never a frozen copy of it.
#
# Every assertion carries:
#   - asserts:     the application invariant, in plain language
#   - produced_by: where in ltl it is produced (function name, never a line)
#   - contract:    the source that makes the invariant stable
# All three are surfaced on failure.
#
# Usage: ./tests/validate-progress-line.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LTL="$REPO_DIR/ltl"

# Invocation shape (HARNESS-DESIGN.md § Invocation coherence): every assertion
# reads the progress line, which the read pass emits. Nothing it carries depends
# on the time axis, the messages table or the statistics, so the runs use the
# coarsest bucket with empty buckets suppressed and -n 1. -lf pins the access
# format so the run does not depend on filename evidence and emits no
# unit-ambiguity note on stderr. -ni keeps the developer's ltl-index.csv out of
# the run. --terminal-width pins the width the line is fitted to.
#
# The runs deliberately do NOT pass --disable-progress: the progress line is the
# subject. One scenario passes it, to assert the suppression.
#
# The fixture is three files of 790 / 790 / 1580 bytes — 3160 in total, a 1:1:2
# ratio chosen so the overall percentage at each file's opening frame is a
# distinct whole number (0%, 25%, 50%) that no other weighting could produce.
FIXTURE_DIR="$REPO_DIR/tests/fixtures/progress-multi-file"
PART1="$FIXTURE_DIR/part-1.txt"
PART2="$FIXTURE_DIR/part-2.txt"
PART3="$FIXTURE_DIR/part-3.txt"
ACCESS_FORMAT="access_common_duration"
WIDTH=140

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

neutralize_colour_env

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"; exit 1
fi
for f in "$PART1" "$PART2" "$PART3"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: fixture not found: $f"; exit 1
    fi
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

# Checker for the row the progress line owns, run against a capture's RAW
# stdout — not the whitespace-trimmed frames the other assertions read, because
# the trailing spaces are precisely what it is about.
#
#   width   <raw> <terminal-width>  every painted frame occupies exactly
#                                   terminal-width - 1 columns
#   residue <raw>                   replaying the stream through a terminal
#                                   (carriage returns move the cursor, writes
#                                   overwrite) leaves nothing of any frame
#                                   standing past the end of its successor
#
# The two are the mechanism and its consequence: the frame is padded to the row
# width so that whatever the previous frame left is covered by this one. Both
# exit non-zero when no frame is found at all — a run that painted nothing must
# fail here rather than pass vacuously (HARNESS-DESIGN.md § Harnesses must fail
# on missing anchors).
ROW_CHECK="$TMP_DIR/progress-row-check.py"
cat > "$ROW_CHECK" <<'PYEOF'
import re, sys

check, raw_path = sys.argv[1], sys.argv[2]
# Read as bytes and decode: Python's text mode applies universal newlines,
# which turns every carriage return into a line feed — so the row would appear
# to start empty for each frame and the residue check could never fail.
text = re.sub(r'\x1b\[[0-9;]*m', '', open(raw_path, 'rb').read().decode('utf-8', 'replace'))
FRAME = re.compile(r'^Processing +[0-9]+%')

# The row as the terminal holds it: '\r' returns the cursor to column 0, a
# write overwrites what is under it, '\n' ends the row.
row, col, frames, problems = [], 0, 0, []
for piece in re.split(r'(\r|\n)', text):
    if piece == '\r':
        col = 0
        continue
    if piece == '\n':
        row, col = [], 0
        continue
    if not piece:
        continue
    for ch in piece:
        if col < len(row):
            row[col] = ch
        else:
            row.append(ch)
        col += 1
    if not FRAME.match(piece):
        continue
    frames += 1
    if check == 'width':
        expected = int(sys.argv[3]) - 1
        if len(piece) != expected:
            problems.append("frame is %d columns, expected %d: %r" % (len(piece), expected, piece))
    else:
        leftover = ''.join(row[len(piece):])
        if leftover.strip():
            problems.append("frame leaves %r visible after it: %r" % (leftover, piece))

if frames == 0:
    print("no progress frame found in %s" % raw_path)
    sys.exit(1)
for p in problems[:5]:
    print(p)
if problems:
    print("%d of %d frames failed the %s check" % (len(problems), frames, check))
    sys.exit(1)
sys.exit(0)
PYEOF

pass=0
fail=0
failures=()
current_scenario=""

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

# Run ltl and reduce its stdout to the progress frames, one per line.
#
# The line is rewritten in place, so every frame of a run arrives on one
# physical line separated by carriage returns, interleaved with the space runs
# that erase the previous frame. Splitting on \r and keeping the non-blank
# pieces recovers the frames in the order they were painted; the erase runs
# collapse to nothing and drop out. ANSI is stripped: 'Processing completed.'
# is coloured and the frames are not, and neither fact is what this harness is
# about.
#
# Writes the frames to $1 and the run's stderr to $1.stderr. Fails hard on a
# non-zero exit or an empty capture (HARNESS-DESIGN.md Trap 1).
capture_frames() {
    local outfile="$1"; shift
    local rawfile="$outfile.raw"
    local stderrfile="$outfile.stderr"
    set +e
    ( cd "$TMP_DIR" && with_ascii_colour "$LTL" "$@" ) >"$rawfile" 2>"$stderrfile"
    local status=$?
    set -e
    if [[ "$status" -ne 0 ]]; then
        echo "  FAIL  $current_scenario :: ltl exited $status" >&2
        sed 's/^/        /' "$stderrfile" >&2
        exit 1
    fi
    if [[ ! -s "$rawfile" ]]; then
        echo "  FAIL  $current_scenario :: ltl produced no output" >&2
        exit 1
    fi
    tr '\r' '\n' < "$rawfile" \
        | sed -E 's/\x1b\[[0-9;]*m//g' \
        | sed -E 's/[[:space:]]+$//' \
        | grep -v '^$' \
        > "$outfile"
    if ! assert_no_runtime_warnings "$stderrfile" "$current_scenario"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# ---------------------------------------------------------------------------
# Scenario: multi-file — the full line, and the overall percentage's arithmetic
# ---------------------------------------------------------------------------
current_scenario="multi-file"

MULTI="$TMP_DIR/multi.frames"
capture_frames "$MULTI" \
    -ni --terminal-width "$WIDTH" -bs 1440 -oe -n 1 -lf "$ACCESS_FORMAT" \
    "$PART1" "$PART2" "$PART3"

# The anchor itself: a run that painted no frame at all would leave every
# pattern below unmatched, and a harness that cannot find its anchor is a
# failure, not a pass (HARNESS-DESIGN.md § Harnesses must fail on missing
# anchors).
assert_command \
    command     "grep -q '^Processing ' '$MULTI'" \
    label       'the read pass paints at least one progress frame' \
    asserts     'A run without --disable-progress reports its progress on stdout while reading; a run that painted nothing would report nothing about a long read' \
    produced_by 'read_and_process_logs() in ltl (the opening frame per file and the throttled repaint)' \
    contract    'features/446-overall-progress-indicator.md D4 — a final frame or the completion line is emitted unconditionally outside the throttle'

assert_command \
    command     "grep -qE '^Processing +[0-9]+%/[0-9]+% \\(file [0-9]+/3\\) line [0-9.]+[kMB]?[a-z]*, [0-9.]+[kMB]?[a-z]* total(, [0-9.]+[kMB]?[a-z]* lines/sec)?: [^ ]*part-[0-9]+\\.txt\$' '$MULTI'" \
    label       'the multi-file line carries file%, overall%, the counter, line, total and the filename, in that order' \
    asserts     'With two or more files the line reads: the file percentage over the overall percentage, the file counter, the current line, the run total, optionally the rate, and the filename LAST — the filename is the only variable-length element, so it sits where it cannot shift the numerics as the run moves between files' \
    produced_by 'progress_line_text() in ltl' \
    contract    'features/446-overall-progress-indicator.md D5 — the line shape is locked; docs/percentage-presentation.md (progress line: integer, 3 characters, floored)'

# 790 / 790 / 1580 of 3160 bytes: the opening frame of each file reports the
# bytes already closed over the total. Any other weighting — per-file count,
# a blend, sizes taken from somewhere other than the selected set — lands on
# different numbers.
assert_command \
    command     "grep -qE '^Processing +0%/0% \\(file 1/3\\) .*: [^ ]*part-1\\.txt\$' '$MULTI'" \
    label       'file 1 of 3 opens at 0% overall' \
    asserts     'The overall percentage is bytes of closed files plus the live handle position over the sum of the selected sets sizes; before any file has closed that is 0 of 3160 bytes' \
    produced_by 'progress_line_text() in ltl, from the sweep in size_selected_files_for_progress()' \
    contract    'features/446-overall-progress-indicator.md D1/D2 — bytes own the percentage; the total is taken once over the final selected list'

assert_command \
    command     "grep -qE '^Processing +0%/25% \\(file 2/3\\) .*: [^ ]*part-2\\.txt\$' '$MULTI'" \
    label       'file 2 of 3 opens at 25% overall (790 of 3160 bytes closed)' \
    asserts     'A file credits its whole size to the overall numerator when it closes, so the next file opens at exactly the closed bytes over the total: 790/3160 = 25%' \
    produced_by 'read_and_process_logs() in ltl (the roll from the live position to the full size at close) and progress_line_text()' \
    contract    'features/446-overall-progress-indicator.md D2/D3 — the contribution rolls from tell to the stat size at close, so the figure is monotonic and a skipped file still reaches 100%'

assert_command \
    command     "grep -qE '^Processing +0%/50% \\(file 3/3\\) .*: [^ ]*part-3\\.txt\$' '$MULTI'" \
    label       'file 3 of 3 opens at 50% overall (1580 of 3160 bytes closed)' \
    asserts     'The overall figure accumulates across files: two closed files of 790 bytes each is 1580 of 3160, which is 50% — bytes, not the file count, which would read 66% here' \
    produced_by 'progress_line_text() in ltl' \
    contract    'features/446-overall-progress-indicator.md D1 — the file counter is a companion, it never enters the percentage'

# The counter is padded to the width of N so it does not shift the rest of the
# line; with N = 3 that is one character, and the assertions above already read
# 'file 1/3'. What is asserted here is that the counter tracks the file in
# flight rather than being emitted once.
assert_command \
    command     "test \"\$(grep -cE '^Processing .*\\(file [0-9]+/3\\)' '$MULTI')\" -ge 3" \
    label       'every file of the set gets a frame naming its position' \
    asserts     'Each file paints an opening frame, so a run over many files shows the reader which file it has reached even when each one is read inside a single repaint interval' \
    produced_by 'read_and_process_logs() in ltl (the opening frame, painted outside the throttle)' \
    contract    'features/446-overall-progress-indicator.md D4 — the throttle governs repaints; issue #31, where small files produced no indicator at all'

assert_command \
    command     "grep -q '^Processing completed\\.\$' '$MULTI'" \
    label       'the run closes on the completion line' \
    asserts     'The read pass ends with Processing completed., so the last thing the reader sees is never a frame parked below 100% — the completion line stands in for a final 100% frame' \
    produced_by 'read_and_process_logs() in ltl (end-of-run block)' \
    contract    'docs/progress-indication-best-practices.md § What ltl adopts, point 6 — 100% means done; leaving the last painted frame short of 100 is not acceptable'

# The line must fit inside what the line-clear erases, or a longer frame leaves
# characters of itself behind when a shorter one replaces it. Only the progress
# frames are measured: the rendered table and its rules are laid out by the
# column engine and are not this surface.
assert_command \
    command     "! grep '^Processing ' '$MULTI' | awk -v w=$WIDTH 'length(\$0) > w - 1 { print; found = 1 } END { exit !found }'" \
    label       "no frame exceeds the width the line-clear covers ($((WIDTH - 1)) characters)" \
    asserts     'Every frame fits within terminal_width - 1 characters, which is exactly what the line-clear writes: a longer frame would leave its tail on screen when a shorter one replaced it, and would wrap on a real terminal' \
    produced_by 'progress_line_text() in ltl (the filename absorbs the fit; the rate is dropped before the name)' \
    contract    'features/446-overall-progress-indicator.md D5 and the in-drop obligation that the line clear covers the longest form of the line'

# The other side of the same invariant: no frame may fall SHORT of the row
# either. The line shrinks between repaints as a matter of course — the rate
# falls from 148.2k to 71k, the line count from 278.5k to 279k — and a carriage
# return moves the cursor without erasing, so a frame that stops early leaves
# the tail of its predecessor standing beside it.
assert_command \
    command     "python3 '$ROW_CHECK' width '$MULTI.raw' $WIDTH" \
    label       "every painted frame occupies exactly $((WIDTH - 1)) columns" \
    asserts     'Each frame is padded out to the width of the row it owns, so painting it covers whatever the previous frame left behind — the row never has to be blanked first, and no frame can be partly a fragment of an older one' \
    produced_by 'paint_progress_line() in ltl' \
    contract    'features/446-overall-progress-indicator.md D8 — every frame is written at the full row width'

assert_command \
    command     "python3 '$ROW_CHECK' residue '$MULTI.raw'" \
    label       'no frame leaves characters of itself visible after the next one is painted' \
    asserts     'Replaying the run through a terminal — carriage returns moving the cursor, writes overwriting — leaves nothing of any frame standing past the end of the frame that replaced it: what the reader sees is always one frame, never two spliced together' \
    produced_by 'paint_progress_line() in ltl' \
    contract    'features/446-overall-progress-indicator.md D8 — the padding exists to make this true without tracking what the row held'

# ---------------------------------------------------------------------------
# Scenario: single file — one percentage, no counter
# ---------------------------------------------------------------------------
current_scenario="single-file"

SINGLE="$TMP_DIR/single.frames"
capture_frames "$SINGLE" \
    -ni --terminal-width "$WIDTH" -bs 1440 -oe -n 1 -lf "$ACCESS_FORMAT" \
    "$PART3"

assert_command \
    command     "grep -qE '^Processing +[0-9]+% line [0-9.]+[kMB]?[a-z]*(, [0-9.]+[kMB]?[a-z]* lines/sec)?: [^ ]*part-3\\.txt\$' '$SINGLE'" \
    label       'the single-file line carries one percentage and the filename' \
    asserts     'With one file the line shows the file percentage, the current line, optionally the rate, and the filename — the same shape as the multi-file line with the overall figure and counter removed' \
    produced_by 'progress_line_text() in ltl' \
    contract    'features/446-overall-progress-indicator.md D5 — the single-file form is locked'

assert_command \
    command     "! grep -qE '^Processing .*\\(file ' '$SINGLE'" \
    label       'no file counter on a single-file run' \
    asserts     'A one-file run shows no file counter: (file 1/1) reports nothing the reader does not already know' \
    produced_by 'progress_line_text() in ltl (the counter is gated on the sweep having run)' \
    contract    'features/446-overall-progress-indicator.md R4/D2 — with one file the run behaves exactly as before the overall figure existed'

assert_command \
    command     "! grep -qE '^Processing +[0-9]+%/[0-9]+%' '$SINGLE'" \
    label       'no overall percentage on a single-file run' \
    asserts     'A one-file run shows no overall percentage: it would equal the file percentage, and two identical figures side by side say nothing' \
    produced_by 'size_selected_files_for_progress() in ltl (the sweep does not run below two files) read by progress_line_text()' \
    contract    'features/446-overall-progress-indicator.md R4 — no size sweep and no overall figure for a single file'

# ---------------------------------------------------------------------------
# Scenario: suppression — --disable-progress emits nothing
# ---------------------------------------------------------------------------
current_scenario="disable-progress"

QUIET="$TMP_DIR/quiet.frames"
capture_frames "$QUIET" \
    -ni --disable-progress --terminal-width "$WIDTH" -bs 1440 -oe -n 1 -lf "$ACCESS_FORMAT" \
    "$PART1" "$PART2" "$PART3"

assert_command \
    command     "! grep -q '^Processing' '$QUIET'" \
    label       'no progress frame and no completion line under --disable-progress' \
    asserts     'The progress line is an indicator, so --disable-progress suppresses it entirely — including the completion line. This is the only suppression: the indicator gets no option of its own' \
    produced_by 'read_and_process_logs() in ltl (every progress print is gated on $disable_progress)' \
    contract    'features/446-overall-progress-indicator.md D6 — suppression is --disable-progress only; CLAUDE.md § Before writing or changing code, which forbids gating BEHAVIOURAL notices behind that flag but requires it for indicators'

# The analysis itself must be unaffected by which of the two modes ran: the
# progress line reads state, it never writes any. The summary's included-line
# count is the check — it is the run's own count of what it analysed, and the
# suppressed run must reach the same number as the painting one.
assert_command \
    command     "test \"\$(grep -E '^ +LINES INCLUDED ' '$MULTI' | tr -s ' ')\" = \"\$(grep -E '^ +LINES INCLUDED ' '$QUIET' | tr -s ' ')\" && grep -qE '^ +LINES INCLUDED ' '$MULTI'" \
    label       'both modes analyse the same lines' \
    asserts     'Whether the progress line is painted or suppressed, the run reads and includes the same lines: the indicator observes the read pass without participating in it' \
    produced_by 'read_and_process_logs() in ltl — the progress block reads $total_lines_read and the handle position, and writes neither' \
    contract    'features/446-overall-progress-indicator.md D6 — the indicator is a display surface over the read pass, suppressed only by --disable-progress'

# ---------------------------------------------------------------------------
# Scenario: narrow terminal — the filename absorbs the fit
# ---------------------------------------------------------------------------
current_scenario="narrow-terminal"

NARROW_WIDTH=60
NARROW="$TMP_DIR/narrow.frames"
capture_frames "$NARROW" \
    -ni --terminal-width "$NARROW_WIDTH" -bs 1440 -oe -n 1 -lf "$ACCESS_FORMAT" \
    "$PART1" "$PART2" "$PART3"

assert_command \
    command     "! grep '^Processing ' '$NARROW' | awk -v w=$NARROW_WIDTH 'length(\$0) > w - 1 { print; found = 1 } END { exit !found }'" \
    label       "no frame exceeds $((NARROW_WIDTH - 1)) characters at a 60-column width" \
    asserts     'The line is fitted to the terminal it is painted on: at a narrow width the filename is shortened, and the rate is dropped before the name, so the numerics stay readable and the line never wraps' \
    produced_by 'progress_line_text() in ltl (the room calculation and shorten_filename())' \
    contract    'features/446-overall-progress-indicator.md D5 — the filename is shortened to fit the terminal; if even the shortened name cannot fit, the rate segment is dropped before the name'

assert_command \
    command     "grep -qE '^Processing +[0-9]+%/[0-9]+% \\(file [0-9]+/3\\) ' '$NARROW'" \
    label       'the percentages and counter survive the narrowing' \
    asserts     'The numerics are what the narrowing protects: the file and overall percentages and the counter are still present at 60 columns, because the filename gives up its characters first' \
    produced_by 'progress_line_text() in ltl' \
    contract    'features/446-overall-progress-indicator.md D5 — truncate the variable part, never the numbers'

assert_command \
    command     "python3 '$ROW_CHECK' width '$NARROW.raw' $NARROW_WIDTH" \
    label       "every painted frame occupies exactly $((NARROW_WIDTH - 1)) columns at a 60-column width" \
    asserts     'The row the frame fills is the terminal it is painted on: at 60 columns the padding runs to 59, so the same self-covering property holds on a narrow terminal, where the filename shortening makes the line length vary most' \
    produced_by 'paint_progress_line() in ltl (the pad is measured from $terminal_width)' \
    contract    'features/446-overall-progress-indicator.md D8 — the row width is the terminal width the run was given'

# ---------------------------------------------------------------------------
# Scenario: the frame names the file by its path, shortened in the middle
#
# The name is rendered the way the "Processed files" table renders it: the path
# as given when it fits, otherwise the start of the path, an ellipsis, and the
# end of the file name. The fixtures are copied under directories inside
# $TMP_DIR (where capture_frames runs) and passed by relative path, so the
# expected text is exact and independent of where the repo is checked out.
# ---------------------------------------------------------------------------
current_scenario="path-in-frame"

SHORT_DIR="alpha"
LONG_DIR="a-directory-whose-name-is-long-enough-that-the-frame-cannot-hold-it"
mkdir -p "$TMP_DIR/$SHORT_DIR" "$TMP_DIR/$LONG_DIR"
cp "$PART1" "$TMP_DIR/$SHORT_DIR/part-1.txt"
cp "$PART2" "$TMP_DIR/$SHORT_DIR/part-2.txt"
cp "$PART1" "$TMP_DIR/$LONG_DIR/part-1.txt"
cp "$PART2" "$TMP_DIR/$LONG_DIR/part-2.txt"

PATHED="$TMP_DIR/pathed.frames"
capture_frames "$PATHED" \
    -ni --terminal-width "$WIDTH" -bs 1440 -oe -n 1 -lf "$ACCESS_FORMAT" \
    "$SHORT_DIR/part-1.txt" "$SHORT_DIR/part-2.txt"

assert_command \
    command     "grep -qE '^Processing .*\\(file 1/2\\) .*: $SHORT_DIR/part-1\\.txt\$' '$PATHED'" \
    label       'a path that fits is shown whole, directory included' \
    asserts     'The frame ends with the path exactly as it was given, so the reader sees which folder the run is in and not just the file name' \
    produced_by 'progress_line_text() in ltl (shorten_filename() on the path as given)' \
    contract    'features/532-progress-line-file-path.md D1 — the progress line calls the shortener on the path as given, with no directory strip'

LONG_PATHED="$TMP_DIR/long-pathed.frames"
capture_frames "$LONG_PATHED" \
    -ni --terminal-width "$NARROW_WIDTH" -bs 1440 -oe -n 1 -lf "$ACCESS_FORMAT" \
    "$LONG_DIR/part-1.txt" "$LONG_DIR/part-2.txt"

assert_command \
    command     "grep -qE '^Processing .*\\(file 1/2\\) .*: a-d[^ ]*\\.\\.\\.[^ ]*1\\.txt\$' '$LONG_PATHED'" \
    label       'a path that does not fit keeps its start and the end of the file name around an ellipsis' \
    asserts     'Shortening removes the middle of the path: the frame ends with the first characters of the directory, an ellipsis, and the tail of the file name, so both the folder and the file remain identifiable' \
    produced_by 'progress_line_text() in ltl (shorten_filename() keeps the start and the end)' \
    contract    'features/532-progress-line-file-path.md — requirement: shortened in the middle so the start of the path and the end of the file name both remain visible'

assert_command \
    command     "! grep '^Processing ' '$LONG_PATHED' | awk -v w=$NARROW_WIDTH 'length(\$0) > w - 1 { print; found = 1 } END { exit !found }'" \
    label       "no frame with a shortened path exceeds $((NARROW_WIDTH - 1)) characters" \
    asserts     'Keeping the directory does not change what absorbs the fit: the name is still shortened to the room the numerics leave, and the line never wraps' \
    produced_by 'progress_line_text() in ltl (the room calculation)' \
    contract    'features/446-overall-progress-indicator.md D5 — the filename is the variable-length element and is shortened to fit the terminal'

# ---------------------------------------------------------------------------
# Scenario: an unreadable file keeps the two-percentage shape.
#
# A zero-byte file has no size to divide by. Guarding the division is right;
# dropping the file percentage with it is not, because the multi-file line then
# renders one figure where the reader expects two — and the one left standing is
# the OVERALL figure sitting in the slot the FILE figure occupies. The counter
# still advances, so the run reads as though that file were most of the way
# through. A file with nothing in it has been read in full: it reports 0%.
# ---------------------------------------------------------------------------
current_scenario="empty-file-keeps-both-percentages"

EMPTY_PART="$TMP_DIR/part-empty.txt"
: > "$EMPTY_PART"

EMPTY_RUN="$TMP_DIR/empty.frames"
capture_frames "$EMPTY_RUN" \
    -ni --terminal-width "$WIDTH" -bs 1440 -oe -n 1 -lf "$ACCESS_FORMAT" \
    "$PART1" "$EMPTY_PART" "$PART3"

assert_command \
    command     "! grep -qE '^Processing +[0-9]+% \\(file ' '$EMPTY_RUN'" \
    label       'no multi-file frame carries a single percentage' \
    asserts     'Every frame of a multi-file run shows the file percentage over the overall one. A frame carrying just one figure beside the file counter is the empty-file path having dropped the file percentage, which leaves the overall figure standing in the file figure position with nothing to say which it is' \
    produced_by 'progress_line_text() in ltl' \
    contract    'features/446-overall-progress-indicator.md D5 — the multi-file line is file percentage over overall percentage'

assert_command \
    command     "grep -qE '^Processing +0%/[0-9]+% \\(file 2/3\\)' '$EMPTY_RUN'" \
    label       'the empty file reports 0% of itself, and the run continues' \
    asserts     'A zero-byte file has been read in full the moment it is opened, so its own figure is 0 rather than absent; the overall figure beside it keeps climbing, and the counter still names the file in flight' \
    produced_by 'progress_line_text() in ltl' \
    contract    'features/446-overall-progress-indicator.md D3 — a skipped file is credited its full size, and the run still reaches 100%'

# ---------------------------------------------------------------------------
# Scenario: a notice raised mid-read does not land in the progress line's row
# ---------------------------------------------------------------------------
# The other scenarios pin the format with -lf, which keeps the run
# deterministic AND suppresses the unit-ambiguity note — so they assert what
# the line looks like, never that nothing writes over it. This scenario drops
# the pin so detection runs and the note fires, and captures stdout and stderr
# INTERLEAVED, which is the only arrangement in which the collision exists: the
# progress line holds a terminal row open on stdout while the notice is written
# to stderr, and a notice emitted where it is discovered appends to that row.
current_scenario="notice-not-in-progress-row"

COLLIDE="$TMP_DIR/collide.frames"
COLLIDE_RAW="$COLLIDE.raw"
set +e
# The access parts raise no note (their shape is one format, #444); a
# connection-server file with no name evidence and a day-3 date (neither
# member of its group eliminated) falls to the group default and raises the
# note the scenario needs.
sed 's/^2026-05-30/2026-05-03/' "$REPO_DIR/tests/fixtures/format-detection/connection-server.txt" > "$TMP_DIR/renamed-cxserver.txt"
( cd "$TMP_DIR" && with_ascii_colour "$LTL" \
    -ni --terminal-width "$WIDTH" -bs 1440 -oe -n 1 \
    "$PART1" "$PART2" "$PART3" "$TMP_DIR/renamed-cxserver.txt" ) >"$COLLIDE_RAW" 2>&1
collide_status=$?
set -e
if [[ "$collide_status" -ne 0 ]]; then
    echo "  FAIL  $current_scenario :: ltl exited $collide_status" >&2
    sed 's/^/        /' "$COLLIDE_RAW" >&2
    exit 1
fi
tr '\r' '\n' < "$COLLIDE_RAW" \
    | sed -E 's/\x1b\[[0-9;]*m//g' \
    | sed -E 's/[[:space:]]+$//' \
    | grep -v '^$' \
    > "$COLLIDE"

# The anchor: without -lf this fixture must actually produce the note. If a
# future format change makes detection unambiguous here, the scenario stops
# testing anything and must fail rather than pass silently.
assert_command \
    command     "grep -q '^Note: [^:]*: the detected log format' '$COLLIDE'" \
    label       'the unpinned run raises the format-ambiguity notice' \
    asserts     'This fixture matches more than one producer of the same line shape, so an unpinned run raises the unit-ambiguity notice — the mid-read notice this scenario exists to place' \
    produced_by 'format_variant_ambiguity_note() in ltl' \
    contract    'features/log-format-registry.md section Drop 1.5 I6 — a default-basis selection surfaces the assumption'

assert_command \
    command     "! grep -E '^Processing .*Note:' '$COLLIDE'" \
    label       'no progress frame carries a notice in its row' \
    asserts     'A notice discovered while reading is held until the read ends, so it never lands in the row the progress line is holding open; a notice printed where it is discovered would appear appended to a Processing frame' \
    produced_by 'defer_notice() / flush_deferred_notices() in ltl' \
    contract    'features/446-overall-progress-indicator.md section Implementation — notices are held until the read ends'

assert_command \
    command     "test \"\$(grep -n '^Processing completed\\.' '$COLLIDE' | head -1 | cut -d: -f1)\" -lt \"\$(grep -n '^Note: [^:]*: the detected log format' '$COLLIDE' | head -1 | cut -d: -f1)\"" \
    label       'the notice is emitted after the read completes' \
    asserts     'The held notice is flushed once the read is over, so it appears below the completion line rather than between frames — the reader sees an uninterrupted progress line, then the notices' \
    produced_by 'flush_deferred_notices() in ltl, called at the end of read_and_process_logs()' \
    contract    'features/446-overall-progress-indicator.md section Implementation — flush_deferred_notices() empties the queue once the read is over'

# The deferral changes WHEN a notice is written, never whether: a behavioural
# notice always prints, --disable-progress or not (CLAUDE.md section Before writing or changing code:
# conventions). Without this, deferral could silently become suppression.
QUIET_NOTICE="$TMP_DIR/quiet-notice.err"
set +e
( cd "$TMP_DIR" && with_ascii_colour "$LTL" \
    -ni --disable-progress --terminal-width "$WIDTH" -bs 1440 -oe -n 1 \
    "$PART1" "$PART2" "$PART3" "$TMP_DIR/renamed-cxserver.txt" ) >/dev/null 2>"$QUIET_NOTICE"
set -e
assert_command \
    command     "grep -q '^Note: [^:]*: the detected log format' '$QUIET_NOTICE'" \
    label       'the notice still prints under --disable-progress' \
    asserts     'Deferral moves a notice past the read; it never suppresses one. --disable-progress silences the indicator, and a behavioural notice is not an indicator' \
    produced_by 'flush_deferred_notices() in ltl — the flush is not gated on $disable_progress' \
    contract    'CLAUDE.md section Before writing or changing code — user-facing behavioural messages are never gated behind --disable-progress'

# ---------------------------------------------------------------------------

echo
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failed assertions:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
exit 0
