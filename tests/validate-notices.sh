#!/usr/bin/env bash
# validate-notices.sh — harness for the notice store: one record per notice
# raised, in raising order, each with its kind, category, stage, producer,
# immediacy, visibility, the surface that drew it, its parts, the choice it
# carries and the answer.
#
# The file name tracks the -V notices section. The scenarios read that section,
# from runs of the real producers (the read-path fallback, injected into a copy
# of ltl in the harness's own directory, never into ltl) and of the hidden
# --notice-fixture option, which raises a named set of fixture notices through
# notice() as each stage begins, so every field and value of the record is
# reached through the calls a producer makes. The panel scenarios read the
# notices panel through the cell decoder (tests/notices/panel-report.pl over
# tests/lib/rendered-output.pl).
#
# Each assertion records, per tests/HARNESS-DESIGN.md § Self-documenting
# assertions: asserts, produced_by (function name), contract. All three are
# surfaced on failure.
#
# Usage: ./tests/validate-notices.sh [--list | --scenario NAME...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="${LTL:-$REPO_DIR/ltl}"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"
# shellcheck source=lib/notices.sh
source "$SCRIPT_DIR/lib/notices.sh"

neutralize_colour_env

# Twelve lines each of two combined-format web-server access logs, one carrying
# a duration field.
ACCESS_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/access-combined.txt"
DURATION_FIXTURE="$REPO_DIR/tests/fixtures/format-detection/access-combined-duration.txt"

DOC='features/412-notice-surfaces.md'
C_STORE="$DOC § D11 and D13; acceptance criteria, store and record"
C_SECTION="$DOC § D15; acceptance criteria, -V notices"
C_FIXTURE="$DOC § D17; acceptance criteria, store and record"
C_PRODUCER="$DOC § Inventory of current notices (the read-path fallback) and § D16; acceptance criteria, migration"

pass=0
fail=0
failures=()
current_scenario=""

pass_with() {
    echo "  PASS  $current_scenario :: $1"
    pass=$((pass + 1))
}

# fail_with <label> <asserts> <produced_by> <contract> [detail...]
fail_with() {
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

# check <label> <actual> <expected> <asserts> <produced_by> <contract>
check() {
    if [[ -n "$2" && "$2" == "$3" ]]; then
        pass_with "$1 ($2)"
    else
        fail_with "$1" "$4" "$5" "$6" "expected: $3" "actual:   ${2:-MISSING-ANCHOR}"
    fi
}

# run_ltl <tag> <ltl> <args...>: one run in the harness's own directory; stdout
# and stderr land in $TMP_DIR/<tag>.out and .err, the exit code in
# $TMP_DIR/<tag>.rc. A Perl runtime warning on stderr is a failure; the exit
# code is the caller's to assert.
run_ltl() {
    local tag="$1" ltl="$2"; shift 2
    local rc=0
    ( cd "$TMP_DIR" && env ${RUN_ENV:-} perl "$ltl" --disable-progress "$@" ) > "$TMP_DIR/$tag.out" 2> "$TMP_DIR/$tag.err" || rc=$?
    echo "$rc" > "$TMP_DIR/$tag.rc"
    if ! assert_no_runtime_warnings "$TMP_DIR/$tag.err" "$current_scenario/$tag"; then
        fail=$((fail + 1)); failures+=("$current_scenario :: $tag perl-runtime-warnings-on-stderr")
    fi
}
# run_ok <tag> <ltl> <args...>: run_ltl, and a non-zero exit is a failure.
run_ok() {
    run_ltl "$@"
    local rc
    rc=$(cat "$TMP_DIR/$1.rc")
    if [[ "$rc" -ne 0 ]]; then
        fail=$((fail + 1)); failures+=("$current_scenario :: $1 exit $rc")
        echo "  FAIL  $current_scenario :: $1 exited $rc"; sed 's/^/        /' "$TMP_DIR/$1.err" | head -5
    fi
}

# section <tag>: the notices section's body, delimiters excluded; empty when absent.
section() { awk '/^=== notices ===$/ { s = 1; next } /^=== END notices ===$/ { s = 0 } s' "$TMP_DIR/$1.out"; }
# has_section <tag>: yes when the section's opening and closing delimiters are both present.
has_section() {
    grep -qx '=== notices ===' "$TMP_DIR/$1.out" && grep -qx '=== END notices ===' "$TMP_DIR/$1.out" && echo yes || echo no
}
# fact <tag> <key>: a top-level "key: value" of the section.
fact() { section "$1" | sed -n "s/^$2: //p"; }
# field <tag> <key>: the value of one record field, one line per record, in order.
field() { section "$1" | sed -n "s/^  $2: //p"; }
# list <tag> <key>: field values joined by commas.
list() { field "$1" "$2" | paste -sd, -; }
# block <tag> <kind>: the lines of the record of that kind (the first, when raised twice).
block() {
    section "$1" | awk -v k="$2" '/^notice: / { if (inb) exit; n = $0; buf = ""; next }
        /^  kind: / { cur = substr($0, 9) } { buf = buf $0 "\n" }
        cur == k && /^  answer: / { printf "%s\n%s", n, buf; inb = 1 }'
}
# block_field <tag> <kind> <key>: one field of the record of that kind, lines joined by commas.
block_field() { block "$1" "$2" | sed -n "s/^  $3: //p" | paste -sd, -; }

# ---------------------------------------------------------------------------
# The section is registered, listed by -V list, emitted by a bare -V and alone
# under -V notices, and named among the reserved section names.
# ---------------------------------------------------------------------------
scenario_registered() {
    current_scenario="registered"
    echo "[$current_scenario]"
    run_ok list "$LTL" -V list
    check "listed by -V list" "$(grep -c '^  notices  ' "$TMP_DIR/list.out" || true)" "1" \
        'The notices section is in the -V registry, so -V list names it' '%verbose_section_registry in ltl' "$C_SECTION"
    run_ok bare "$LTL" -bs 1440 -oe -V "$ACCESS_FIXTURE"
    check "emitted by a bare -V" "$(has_section bare)" "yes" \
        'A bare -V emits every registered section, notices among them' 'emit_notices_verbose() in ltl' "$C_SECTION"
    run_ok alone "$LTL" -bs 1440 -oe -V notices "$ACCESS_FIXTURE"
    check "alone under -V notices" "$(grep -c '^=== [a-z-]* ===$' "$TMP_DIR/alone.out" || true)" "1" \
        '-V notices emits the notices section and no other' 'section_requested() in ltl' "$C_SECTION"
    check "reserved in the harness design" "$(grep -c '^- `notices` — ' "$REPO_DIR/tests/HARNESS-DESIGN.md" || true)" "1" \
        'The section is listed among the implemented reserved section names' 'tests/HARNESS-DESIGN.md § Reserved section names' "$C_SECTION"
}

# ---------------------------------------------------------------------------
# A run whose conditions raise no notice: the section is present with
# count: 0 and no record.
# ---------------------------------------------------------------------------
scenario_clean_run() {
    current_scenario="clean-run"
    echo "[$current_scenario]"
    run_ok clean "$LTL" -bs 1440 -oe -V notices "$ACCESS_FIXTURE"
    check "section present" "$(has_section clean)" "yes" \
        'The section is written on a run that raised nothing' 'emit_notices_verbose() in ltl' "$C_SECTION"
    check "count zero, no record" "$(fact clean count)|$(section clean | grep -c '^notice: ' || true)" "0|0" \
        'A run whose conditions raise no notice has count: 0 and no notice block' 'notice() in ltl' "$C_STORE"
}

# ---------------------------------------------------------------------------
# The read-path fallback, the first producer on the store: a gate marker
# renamed in a copy of ltl so the generated body cannot be prepared, and two
# files read with the threshold at 0, so both fall back. One record for the
# run, and the notice still printed on standard error until the panel draws it.
# ---------------------------------------------------------------------------
scenario_read_path_fallback() {
    current_scenario="read-path-fallback"
    echo "[$current_scenario]"
    perl -pe 's/^(\s*#\@and )!\$disable_progress$/$1!\$disable_progress_renamed/' "$LTL" > "$TMP_DIR/ltl-altered"
    check "fault injected" "$(grep -c 'disable_progress_renamed' "$TMP_DIR/ltl-altered" || true)" "1" \
        'The copy carries the renamed marker term, so generation fails' 'generated_loop_text() in ltl' "$C_PRODUCER"
    run_ok fallback "$TMP_DIR/ltl-altered" -bs 1440 -oe --generated-loop-threshold=0 -V notices,read-path "$ACCESS_FIXTURE" "$DURATION_FIXTURE"
    check "the run fell back" "$(sed -n 's/^fallback_reason: //p' "$TMP_DIR/fallback.out")" "marker_mismatch" \
        'Both files take the standard path because the body could not be prepared' 'read_path_fall_back() in ltl' "$C_PRODUCER"
    check "one record for the run" "$(fact fallback count)|$(list fallback kind)" "1|read-path-fallback" \
        'The fallback raises one record a run, however many files fell back' 'read_path_fall_back() in ltl' "$C_PRODUCER"
    check "the record's fields" \
        "$(list fallback category)|$(list fallback producer)|$(list fallback stage)|$(list fallback immediacy)|$(list fallback visible)|$(list fallback shown)|$(list fallback choice)|$(list fallback answer)" \
        "decision_taken_for_you|read_path_fall_back|parse|deferred|yes|panel|no|-" \
        'The fallback is a decision taken for the analyst, raised by read_path_fall_back during the read, deferred, visible, drawn by the panel, with no choice' \
        'read_path_fall_back() and notice() in ltl' "$C_PRODUCER"
    check "the statement" "$(list fallback statement)" \
        "the faster read path could not be prepared, so large files are read with the standard path, which is slower" \
        'The statement is the notice text, without its prefix' 'read_path_fall_back() in ltl' "$C_PRODUCER"
    check "drawn in the panel, not on standard error" \
        "$(sed 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/fallback.out" | grep -c 'DECISION TAKEN FOR YOU (1)' || true)|$(grep -c 'faster read path' "$TMP_DIR/fallback.err" || true)" "1|0" \
        'The fallback is drawn once in the notices panel, in its category, and never on standard error' 'draw_deferred_notices() in ltl' "$DOC § Migration"
    run_ok normal "$LTL" -bs 1440 -oe --generated-loop-threshold=0 -V notices "$ACCESS_FIXTURE" "$DURATION_FIXTURE"
    check "no record when the body is prepared" "$(fact normal count)" "0" \
        'A run whose generated body is prepared raises no fallback record' 'read_path_fall_back() in ltl' "$C_PRODUCER"
}

# ---------------------------------------------------------------------------
# The record-fields fixture set: between its records, every stage, every
# category, every part present and absent, evidence none, one and two, a kind
# raised twice, an invisible record, a choice of buttons, a choice of options
# with the default headings and with the producer's.
# ---------------------------------------------------------------------------
scenario_record_fields() {
    current_scenario="record-fields"
    echo "[$current_scenario]"
    run_ok fields "$LTL" -bs 1440 -oe --notice-fixture record-fields -V notices "$ACCESS_FIXTURE"
    local blocks
    blocks=$(section fields | grep -c '^notice: ' || true)
    check "count equals the blocks" "$(fact fields count)|$blocks" "9|9" \
        'count is the number of records, one block each' 'emit_notices_verbose() in ltl' "$C_SECTION"
    check "ids in raising order" "$(section fields | sed -n 's/^notice: //p' | paste -sd, -)" "1,2,3,4,5,6,7,8,9" \
        'Each raising gets the next id, and blocks are in raising order' 'notice() in ltl' "$C_STORE"
    check "stage set by the store" "$(list fields stage)" "options,detect,parse,accumulate,accumulate,finalize,finalize,render,render" \
        'The stage is the pipeline stage the call ran in' 'enter_notice_stage() in ltl' "$C_STORE"
    check "every category" "$(field fields category | sort -u | paste -sd, -)" \
        "data_anomaly,decision_taken_for_you,figure_caveat,guidance,runtime_condition,your_options" \
        'The six categories are each carried' 'notice() in ltl' "$C_STORE"
    check "producer is the calling sub" "$(field fields producer | sort -u | paste -sd, -)" "raise_fixture_notices" \
        'The producer recorded is the sub that called notice()' 'notice() in ltl' "$C_STORE"
    check "raised twice, never merged" "$(field fields kind | grep -c '^fixture-raised-twice$' || true)|$(field fields statement | grep -c '^a notice raised twice' || true)" "2|2" \
        'Two raisings of one kind are two records' 'notice() in ltl' "$C_STORE"
    check "parts absent" "$(block_field fields fixture-statement focus)|$(block_field fields fixture-statement evidence)|$(block_field fields fixture-statement remedy)" "-|-|-" \
        'An absent focus, evidence and remedy are written -' 'emit_notices_verbose() in ltl' "$C_SECTION"
    check "every part present, evidence one line per piece" \
        "$(block_field fields fixture-every-part focus)|$(block_field fields fixture-every-part evidence)|$(block_field fields fixture-every-part remedy)" \
        "the focus|the first piece of evidence,the second piece: after a colon|-x example" \
        'Focus and remedy are written as given; each piece of evidence is its own evidence: line, in order' 'emit_notices_verbose() in ltl' "$C_SECTION"
    check "one piece of evidence" "$(block_field fields fixture-one-evidence evidence)" "the one piece" \
        'Evidence given as one value is one evidence: line' 'notice() in ltl' "$C_SECTION"
    check "visible yes and no" "$(block_field fields fixture-invisible visible)|$(block_field fields fixture-statement visible)" "no|yes" \
        'visible is yes by default and no when the producer says so' 'notice() in ltl' "$C_STORE"
    check "immediacy and shown" "$(field fields immediacy | sort -u | paste -sd, -)|$(block_field fields fixture-invisible shown)|$(field fields shown | sort | uniq -c | awk '{ printf "%s=%s ", $2, $1 }')" "deferred|none|none=1 panel=8 " \
        'A deferred, visible notice is drawn by the panel; an invisible one by no surface' 'draw_deferred_notices() in ltl' "$C_STORE"
    check "choice yes and no" "$(block_field fields fixture-statement choice)|$(block_field fields fixture-choice-buttons choice)|$(block_field fields fixture-choice-options choice)" "no|yes|yes" \
        'A record with a question or buttons carries a choice' 'emit_notices_verbose() in ltl' "$C_SECTION"
    check "buttons only: no headings, no options" "$(block fields fixture-choice-buttons | grep -cE '^  (headings|option): ' || true)" "0" \
        'A choice with buttons and no options list has no headings and no option blocks' 'emit_notices_verbose() in ltl' "$C_SECTION"
    check "default headings" "$(block_field fields fixture-choice-options headings)" "What? | How? | Why?" \
        'Options given no headings are headed What? How? Why?, as many as their parts' 'notice() in ltl' "$C_STORE"
    check "the producer's headings" "$(block_field fields fixture-choice-headings headings)" "Order | Option" \
        'Headings the producer gives are kept' 'notice() in ltl' "$C_STORE"
    check "option blocks" "$(block fields fixture-choice-options | sed -n 's/^  option: //p' | paste -sd, -)" "three,two,one" \
        'Each option offered is an option: block named by its key, in order' 'emit_notices_verbose() in ltl' "$C_SECTION"
    check "option parts, args, effect" \
        "$(block fields fixture-choice-options | sed -nE 's/^    (parts|args|effect): //p' | paste -sd '#' -)" \
        "the what | the how | the why#-so count#the effect of three parts#the what | the how#-so bytes#the effect of two parts#the what#-n 5#the effect of one part" \
        'Each option block carries its parts joined by " | ", its command options and its effect; three, two and one parts' 'emit_notices_verbose() in ltl' "$C_SECTION"
    check "no answer yet" "$(field fields answer | sort -u | paste -sd, -)" "-" \
        'A record no surface has asked carries no answer' 'emit_notices_verbose() in ltl' "$C_SECTION"
}

# ---------------------------------------------------------------------------
# kind is the same in every run of the same condition.
# ---------------------------------------------------------------------------
scenario_kind_stable() {
    current_scenario="kind-stable"
    echo "[$current_scenario]"
    run_ok first "$LTL" -bs 1440 -oe --notice-fixture record-fields -V notices "$ACCESS_FIXTURE"
    run_ok second "$LTL" -bs 1440 -oe --notice-fixture record-fields -V notices "$DURATION_FIXTURE"
    local a b
    a=$(list first kind); b=$(list second kind)
    check "kinds identical across runs" "$([[ -n "$a" && "$a" == "$b" ]] && echo yes || echo "no ($a / $b)")" "yes" \
        'The same conditions raise the same kinds, whatever the input' 'notice() in ltl' "$C_STORE"
}

# ---------------------------------------------------------------------------
# The section keeps the content shape, ASCII only, and requesting it leaves the
# run's output rows unchanged.
# ---------------------------------------------------------------------------
scenario_shape() {
    current_scenario="shape"
    echo "[$current_scenario]"
    run_ok shape "$LTL" -bs 1440 -oe --notice-fixture record-fields -V notices "$ACCESS_FIXTURE"
    local departures rc=0
    departures=$(perl "$SCRIPT_DIR/lib/verbose-content-shape.pl" --registered notices "$TMP_DIR/shape.out") || rc=$?
    check "content shape" "$rc" "0" \
        'Every line of the section is in the harness content shape' 'emit_notices_verbose() in ltl' \
        "tests/HARNESS-DESIGN.md § Content shape; $C_SECTION"
    [[ "$rc" -eq 0 ]] || echo "$departures" | sed 's/^/        /' | head -10
    check "ASCII only" "$(section shape | LC_ALL=C grep -c '[^[:print:][:space:]]' || true)" "0" \
        'The section is ASCII; glyphs and bullets belong to the surfaces' 'emit_notices_verbose() in ltl' "$C_SECTION"
    run_ok layout "$LTL" -bs 5 --notice-fixture record-fields -V section-layout "$DURATION_FIXTURE"
    run_ok layout-notices "$LTL" -bs 5 --notice-fixture record-fields -V section-layout,notices "$DURATION_FIXTURE"
    local a b
    a=$(sed -n '/^=== section-layout ===$/,/^=== END section-layout ===$/p' "$TMP_DIR/layout.out")
    b=$(sed -n '/^=== section-layout ===$/,/^=== END section-layout ===$/p' "$TMP_DIR/layout-notices.out")
    check "no effect on the output's rows" "$([[ -n "$a" && "$a" == "$b" ]] && echo yes || echo no)" "yes" \
        'The -V section-layout rows are identical with and without -V notices' 'emit_notices_verbose() in ltl' "$C_SECTION"
}

# ---------------------------------------------------------------------------
# An unknown fixture set is refused as a usage error, naming the sets.
# ---------------------------------------------------------------------------
scenario_fixture_refused() {
    current_scenario="fixture-refused"
    echo "[$current_scenario]"
    run_ltl refused "$LTL" --notice-fixture no-such-set "$ACCESS_FIXTURE"
    check "refused with its reason" \
        "$(cat "$TMP_DIR/refused.rc")|$(grep -c "^--notice-fixture: 'no-such-set' is not a fixture set; the sets are .*record-fields" "$TMP_DIR/refused.err" || true)" "1|1" \
        'An unknown fixture set exits 1 with a message naming the sets' '_validate_notice_fixture() in ltl' "$C_FIXTURE"
}

# ---------------------------------------------------------------------------
# The panel (#412 D2, D3, D6, D10), read through the cell decoder
# (tests/notices/panel-report.pl over tests/lib/rendered-output.pl).
# ---------------------------------------------------------------------------

# report <tag>: the panel report of a run, kept beside its capture; empty when
# the capture holds no panel.
report() {
    [[ -e "$TMP_DIR/$1.panels" ]] || perl "$SCRIPT_DIR/notices/panel-report.pl" "$TMP_DIR/$1.out" > "$TMP_DIR/$1.panels" 2>&1 || true
    cat "$TMP_DIR/$1.panels"
}
# panel <tag> <n> <key>: a fact of the n-th panel.
panel() { report "$1" | awk -F'\t' -v n="$2" -v k="$3" '$1 == "P" && $2 == n && $3 == k { print $4 }'; }
# panel_rows <tag> <n> <kind>: the text of each row of that kind, one a line.
panel_rows() { report "$1" | awk -F'\t' -v n="$2" -v k="$3" '$1 == "R" && $2 == n && $4 == k { print $5 }'; }
# row_attr <tag> <n> <text prefix> <attribute>: an attribute of the first row whose text starts so.
row_attr() {
    report "$1" | awk -F'\t' -v n="$2" -v p="$3" -v a="$4" '$1 == "R" && $2 == n && index($5, p) == 1 {
        m = split($6, kv, ";"); for (i = 1; i <= m; i++) { split(kv[i], x, "="); if (x[1] == a) { print substr(kv[i], length(a) + 2); exit } } exit }'
}
# layout <tag> <section>: "state start rows" of a section in -V section-layout.
layout() { awk -F'\t' -v s="$2" '/^=== section-layout ===$/ { in_s = 1; next } /^=== END section-layout ===$/ { in_s = 0 } in_s && $1 == s { print $2 " " $3 " " $4 }' "$TMP_DIR/$1.out"; }
# panels <tag>: how many panels the capture holds.
panels() { report "$1" | awk -F'\t' '$1 == "P" && $3 == "first" { n++ } END { print n + 0 }'; }

C_PANEL="$DOC § D3, D5 and D6; acceptance criteria, panel"
C_SHEET="docs/design-language.md § The category sheet; $DOC § D2; acceptance criteria, panel"
C_LIGHT="docs/design-language.md § Light background; $DOC § D10; acceptance criteria, panel"

scenario_panel_placement() {
    current_scenario="panel-placement"
    echo "[$current_scenario]"
    run_ok place "$LTL" -bs 1440 -oe -n 1 --terminal-width 100 --notice-fixture panel-categories -V section-layout,notices "$DURATION_FIXTURE"
    local first rows state start count timeline
    first=$(panel place 1 first); rows=$(panel place 1 rows)
    read -r state start count <<<"$(layout place notices)"
    check "a section of its own" "$state|$start|$count" "rendered|$first|$rows" \
        'The panel is the notices section of -V section-layout, its start and rows those of the box' \
        'draw_deferred_notices() and print_section_layout() in ltl' "$C_PANEL"
    read -r state timeline _ <<<"$(layout place timeline)"
    check "after the title, before the timeline" "$(( $(layout place title | awk '{ print $2 + $3 }') + 1 ))|$(( first + rows + 1 ))" "$first|$timeline" \
        'One blank row after the title, the panel, one blank row, then the timeline' 'open_section() in ltl' "$C_PANEL"
    check "on standard output only" "$(wc -c < "$TMP_DIR/place.err" | tr -d ' ')" "0" \
        'The panel prints on standard output; standard error carries nothing' 'draw_notice_panel() in ltl' "$C_PANEL"
}

scenario_panel_none() {
    current_scenario="panel-none"
    echo "[$current_scenario]"
    run_ok none "$LTL" -bs 1440 -oe -n 1 --terminal-width 100 -V section-layout "$DURATION_FIXTURE"
    check "no panel, no empty section" "$(panels none)|$(layout none notices)" "0|absent  " \
        'A run with no visible deferred notice draws no panel and opens no section' 'draw_deferred_notices() in ltl' "$C_PANEL"
    run_ok invisible "$LTL" -bs 1440 -oe -n 1 --terminal-width 100 --notice-fixture record-fields "$DURATION_FIXTURE"
    check "an invisible notice stays off the panel" "$(panel invisible 1 title)|$(panel_rows invisible 1 notice | grep -c 'kept off' || true)" "notices (8)|0" \
        'A notice with visible: no is not drawn by the panel' 'draw_deferred_notices() in ltl' "$C_STORE"
}

scenario_panel_headed() {
    current_scenario="panel-headed"
    echo "[$current_scenario]"
    local w
    for w in 80 120 160; do
        run_ok "headed-$w" "$LTL" -bs 1440 -oe -n 1 --terminal-width "$w" --notice-fixture panel-categories "$DURATION_FIXTURE"
        check "box spans $w columns" "$(panel "headed-$w" 1 width)|$(panel "headed-$w" 1 widths)" "$(( w - 1 ))|equal" \
            'Every row of the box is one cell narrower than the terminal, so none overflows or wraps' 'notice_panel_rows() in ltl' "$C_PANEL"
    done
    check "title and frame" "$(panel headed-120 1 title)|$(panel headed-120 1 title_dim)|$(panel headed-120 1 frame_fg)|$(panel headed-120 1 side_fg)" \
        "notices (7)|yes|ansi:90|ansi:90" \
        'The title is notices and its count in secondary text; the frame of a box with several categories is grey' 'notice_panel_rows() in ltl' "$C_PANEL"
    check "one cell of padding" "$(panel headed-80 1 pad_left)|$(panel headed-80 1 pad_right)" "1|1" \
        'A box that stays on screen has one cell inside each side: at 80 columns the cut heading fills the row up to it' 'notice_frame() in ltl' "$C_PANEL"
    check "headings in category order" "$(panel_rows headed-120 1 heading | sed -E 's/  .*//' | paste -sd'|' -)" \
        "⚠ DATA ANOMALY (2)|≈ FIGURE CAVEAT (1)|⚙ YOUR OPTIONS (1)|↻ DECISION TAKEN FOR YOU (1)|⏱ RUNTIME CONDITION (1)|➤ GUIDANCE (1)" \
        'Each category is headed once, glyph, name in upper case and count, in presentation order' 'notice_heading() in ltl' "$C_SHEET"
    check "how to read each" "$(panel_rows headed-120 1 heading | sed -E 's/^[^)]*\)  //' | paste -sd'|' -)" \
        "check the source data or the options before trusting the figures|the figures cover less than they appear to|command usage warnings|what the run did instead of what was asked|a condition of the run's environment|a next step worth trying" \
        'Each heading carries how to read its category' 'notice_heading() in ltl' "$C_SHEET"
    check "category colours" "$(for p in '⚠' '≈' '⚙' '↻' '⏱' '➤'; do row_attr headed-120 1 "$p" glyph_fg; done | paste -sd, -)" \
        "256:208,256:170,256:44,256:33,256:43,256:40" \
        'Each category draws in its colour of the category sheet on a dark background' 'notice_style() in ltl' "$C_SHEET"
    check "headings bold, how to read it secondary" \
        "$(for p in '⚠' '≈' '⚙' '↻' '⏱' '➤'; do echo "$(row_attr headed-120 1 "$p" glyph_bold)$(row_attr headed-120 1 "$p" name_bold)$(row_attr headed-120 1 "$p" reads_dim)"; done | sort -u)" "yesyesyes" \
        'The glyph and name are bold in every category, the how-to-read text dim' 'notice_heading() in ltl' "$C_PANEL"
    check "one blank row between categories" "$(panel_rows headed-120 1 blank | wc -l | tr -d ' ')|$(panel headed-120 1 rows)" "5|20" \
        'Six categories are divided by five blank rows, and the box has no other empty row' 'notice_panel_rows() in ltl' "$C_PANEL"
    check "the bullet in the category colour" \
        "$(report headed-120 | awk -F'\t' '$4 == "notice" { split($6, a, ";"); print a[1] }' | sort | uniq -c | awk '{ print $2 "x" $1 }' | paste -sd, -)" \
        "bullet_fg=256:170x1,bullet_fg=256:208x2,bullet_fg=256:33x1,bullet_fg=256:40x1,bullet_fg=256:43x1,bullet_fg=256:44x1" \
        'Each notice is one row led by the em dash in its category colour' 'notice_rows() in ltl' "$C_PANEL"
}

scenario_panel_parts() {
    current_scenario="panel-parts"
    echo "[$current_scenario]"
    run_ok parts "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 --notice-fixture panel-categories "$DURATION_FIXTURE"
    check "focus bold, statement in text" "$(row_attr parts 1 '— file.txt' bold)|$(row_attr parts 1 '— file.txt' text_fg)" "file.txt|ansi:37" \
        'The focus is bold and the statement in the text colour' 'notice_rows() in ltl' "$C_PANEL"
    check "evidence after a dot, secondary" "$(panel_rows parts 1 notice | grep -c '^— a figure caveat · one; two$' || true)|$(row_attr parts 1 '— a figure caveat' evidence_dim)" "1|yes" \
        'Evidence follows a middle dot, its pieces in order, in secondary text' 'notice_rows() in ltl' "$C_PANEL"
    check "remedy after an arrow, in the category colour" "$(panel_rows parts 1 notice | grep -c '^— a guidance notice → -so count$' || true)|$(row_attr parts 1 '— a guidance notice' remedy_fg)" "1|256:40" \
        'The remedy follows an arrow, in the category colour' 'notice_rows() in ltl' "$C_PANEL"
}

scenario_panel_edge() {
    current_scenario="panel-edge"
    echo "[$current_scenario]"
    run_ok edge "$LTL" -bs 1440 -oe -n 1 --terminal-width 100 --notice-fixture panel-edge "$DURATION_FIXTURE"
    check "the category in the top edge" "$(panel edge 1 title)|$(panel edge 1 frame_fg)|$(panel edge 1 side_fg)" \
        "≈ FIGURE CAVEAT (3)  the figures cover less than they appear to|256:170|256:170" \
        'One category takes the edge form: glyph, name, count and how to read it in the top edge, the frame in its colour' 'notice_panel_rows() in ltl' "$C_PANEL"
    check "the notices alone inside" "$(panel_rows edge 1 heading | wc -l | tr -d ' ')|$(panel_rows edge 1 notice | wc -l | tr -d ' ')|$(panel edge 1 rows)" "0|3|5" \
        'In the edge form the box holds the notices and no heading' 'notice_panel_rows() in ltl' "$C_PANEL"
    run_ok one "$LTL" -bs 1440 -oe -n 1 --terminal-width 100 --notice-fixture panel-one "$DURATION_FIXTURE"
    check "one notice, one row" "$(panel one 1 title)|$(panel_rows one 1 notice)|$(panel one 1 rows)" \
        "↻ DECISION TAKEN FOR YOU (1)  what the run did instead of what was asked|— the one notice of the run|3" \
        'One notice is a box of one row in the edge form' 'notice_panel_rows() in ltl' "$C_PANEL"
}

scenario_panel_wrap() {
    current_scenario="panel-wrap"
    echo "[$current_scenario]"
    run_ok wrap "$LTL" -bs 1440 -oe -n 1 --terminal-width 80 --notice-fixture panel-wrap "$DURATION_FIXTURE"
    check "wraps within the box" "$(panel wrap 1 widths)|$(panel_rows wrap 1 continuation | wc -l | tr -d ' ')" "equal|3" \
        'A notice wider than the box wraps onto rows of the box, none longer' 'notice_rows() in ltl' "$C_PANEL"
    local words
    words=$(report wrap | awk -F'\t' '$1 == "R" && ($4 == "notice" || $4 == "continuation") { print $5 }' | sed -n '1,4p' | sed 's/^— //' | tr '\n' ' ' | sed 's/ $//')
    check "by words" "$words" \
        "the focus of a long notice a notice whose statement runs on well past the width of the narrowest terminal the tool supports, so it wraps by words onto the rows below · the first piece of evidence it carries; the second piece → -x example -d another" \
        'Rows break between words, every word whole, in order' 'notice_rows() in ltl' "$C_PANEL"
    check "continuation under the text" "$(grep -c '^│     [^ ]' <(sed 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/wrap.out") || true)|$(grep -c '^│   [^ ]' <(sed 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/wrap.out") || true)" "0|3" \
        'A continuation row starts under the text after the bullet, with no hanging indent beyond it' 'notice_rows() in ltl' "$C_PANEL"
}

scenario_panel_light() {
    current_scenario="panel-light"
    echo "[$current_scenario]"
    run_ok light "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 -lbg --notice-fixture panel-categories "$DURATION_FIXTURE"
    check "frame and title grey 244, never faint" "$(panel light 1 frame_fg)|$(panel light 1 title_fg)|$(panel light 1 title_dim)" "256:244|256:244|no" \
        'On a light background the frame and the title are 256-colour grey 244, not faint' 'notice_style() in ltl' "$C_LIGHT"
    check "secondary text grey 244, never faint" "$(row_attr light 1 '⚠' reads_fg)|$(row_attr light 1 '⚠' reads_dim)|$(row_attr light 1 '— a figure caveat' evidence_fg)|$(row_attr light 1 '— a figure caveat' evidence_dim)" "256:244|no|256:244|no" \
        'How to read a category and the evidence are grey 244 on a light background' 'notice_style() in ltl' "$C_LIGHT"
    check "text black 16" "$(row_attr light 1 '— a second data anomaly' text_fg)" "256:16" \
        'Text is 256-colour black on a light background' 'notice_style() in ltl' "$C_LIGHT"
    check "categories at their darkest light step" "$(for p in '⚠' '≈' '⚙' '↻' '⏱' '➤'; do row_attr light 1 "$p" glyph_fg; done | paste -sd, -)" \
        "256:166,256:93,256:30,256:27,256:29,256:35" \
        'Each category takes the darkest step of its light gradient' 'notice_style() in ltl' "$C_LIGHT"
}

scenario_panel_windows_glyphs() {
    current_scenario="panel-windows-glyphs"
    echo "[$current_scenario]"
    RUN_ENV="WT_SESSION=1" run_ok windows "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 --notice-fixture panel-categories "$DURATION_FIXTURE"
    check "the Windows glyphs" "$(panel_rows windows 1 heading | cut -c1 | paste -sd, -)" "△,≈,⛭,↻,⧖,►" \
        'In Windows Terminal each category takes the glyph that terminal draws one cell wide' 'notice_style() and detect_terminal() in ltl' \
        "docs/terminal-output.md § Glyphs and width; $C_SHEET"
}

scenario_panel_immediate() {
    current_scenario="panel-immediate"
    echo "[$current_scenario]"
    run_ok immediate "$LTL" -bs 1440 -oe -n 1 --terminal-width 100 --notice-fixture panel-immediate -V section-layout,notices "$DURATION_FIXTURE"
    check "drawn at the call, then the deferred panel" "$(panels immediate)|$(panel immediate 1 title | sed -E 's/  .*//')|$(panel immediate 2 title | sed -E 's/  .*//')" \
        "2|⚙ YOUR OPTIONS (1)|⏱ RUNTIME CONDITION (1)" \
        'An immediate notice is drawn inline at its call; the deferred panel follows with the deferred notice alone' 'notice() and draw_deferred_notices() in ltl' "$C_PANEL"
    check "recorded as shown by the panel" "$(block_field immediate fixture-immediate immediacy)|$(block_field immediate fixture-immediate shown)|$(block_field immediate fixture-deferred shown)" "now|panel|panel" \
        'Both records are shown by the panel, the immediate one at its call' 'draw_notice_panel() in ltl' "$C_STORE"
    check "the notices section is the deferred panel" "$(layout immediate notices | awk '{ print $2 }')" "$(panel immediate 2 first)" \
        'The section -V section-layout names notices starts at the deferred panel' 'draw_deferred_notices() in ltl' "$C_PANEL"
}

# ---------------------------------------------------------------------------
# The migration (features/412-notice-surfaces.md § Inventory of current
# notices, rows 1 to 31, and the ask before the read): every kind on the store is raised with the category
# the inventory settled, read from the notice() calls in ltl's source; and a
# run raising four of them records each with its producer and stage. Each
# kind's own condition is asserted by the harness of the feature that raises
# it, from -V notices.
# ---------------------------------------------------------------------------
C_MIGRATION="$DOC § Inventory of current notices (categories settled 2026-10-21); acceptance criteria, migration"
MIGRATED_KINDS=(
    # rows 1 to 11, raised as the options are read, each your options
    "deprecated-spelling=your_options"
    "discard-switches-off-metric=your_options"
    "discard-wins=your_options"
    "heatmap-counting-metric=your_options"
    "histogram-counting-metric=your_options"
    "invalid-chart-value=your_options"
    "merged-regex-too-long=your_options"
    "pattern-file-binary=your_options"
    "pattern-file-empty=your_options"
    "pattern-file-many-patterns=your_options"
    "pattern-file-missing=your_options"
    "pattern-file-too-large=your_options"
    "pattern-file-unreadable=your_options"
    "range-unsatisfiable=your_options"
    "sort-gated-by-omit=your_options"
    "top-messages-zero=your_options"
    "udm-counting-with-transform=your_options"
    "udm-fixed-string-pattern=your_options"
    "udm-function-in-unit-slot=your_options"
    "udm-invalid-function=your_options"
    "udm-invalid-regex=your_options"
    "udm-key-and-pattern=your_options"
    "udm-name-collision=your_options"
    "udm-no-name=your_options"
    "udm-repeat-dropped=your_options"
    "udm-unit-ignored=your_options"
    "udm-unit-unknown=your_options"
    "options-review=your_options"
    # rows 12 to 31
    "read-path-fallback=decision_taken_for_you"
    "classification-rules-changed=data_anomaly"
    "date-cannot-exist=data_anomaly"
    "format-producer-undecided=data_anomaly"
    "du-not-applied=your_options"
    "csv-message-column-absent=data_anomaly"
    "udm-csv-column-absent=your_options"
    "level-not-recognised=data_anomaly"
    "filter-excluded-no-value=figure_caveat"
    "directory-unreadable=data_anomaly"
    "byte-notations-differ=decision_taken_for_you"
    "timestamp-precision-coarser=decision_taken_for_you"
    "bound-finer-than-log=your_options"
    "final-pass-skipped=decision_taken_for_you"
    "sort-not-produced=decision_taken_for_you"
    "bin-percentiles-approximate=figure_caveat"
    "udm-no-metrics=your_options"
    "udm-capture-not-number=data_anomaly"
    "classification-columns-not-shown=figure_caveat"
    "classified-shares-omitted=figure_caveat"
    "classification-not-event-ledger=figure_caveat"
    "classification-not-matched=data_anomaly"
)

scenario_migration_categories() {
    current_scenario="migration-categories"
    echo "[$current_scenario]"
    local raised entry kind want got
    raised=$(perl -0ne 'while (/\b(?:notice|ask)\(\s*kind\s*=>\s*\x27([^\x27]+)\x27,\s*category\s*=>\s*\x27([^\x27]+)\x27/g) { print "$1=$2\n" }' "$LTL" | sort -u)
    for entry in "${MIGRATED_KINDS[@]}"; do
        kind="${entry%%=*}"; want="${entry#*=}"
        got=$(awk -F= -v k="$kind" '$1 == k { print $2 }' <<<"$raised" | paste -sd, -)
        check "$kind is $want" "$got" "$want" \
            'Each migrated notice is raised with the category the inventory settled, at every call that raises it' \
            'the producer named in the inventory, through notice() in ltl' "$C_MIGRATION"
    done
    local extra
    extra=$(cut -d= -f1 <<<"$raised" | grep -vxF -f <(printf '%s\n' "${MIGRATED_KINDS[@]%%=*}") | paste -sd, - || true)
    check "no kind outside the inventory" "${extra:-none}" "none" \
        'Every kind ltl raises is one the inventory names' 'notice() calls in ltl' "$C_MIGRATION"
}

scenario_migration_raised() {
    current_scenario="migration-raised"
    echo "[$current_scenario]"
    run_ok raised "$LTL" -bs 1440 -oe -n 3 -tp ns -g 50 -mdm bin -udm 'nosuchkey::max' -dmin 1us -V notices "$DURATION_FIXTURE"
    local kind
    for kind in timestamp-precision-coarser:resolve_timestamp_precision:parse \
                bound-finer-than-log:note_finer_duration_bounds:parse \
                bin-percentiles-approximate:bin_consolidation_notice:finalize \
                udm-no-metrics:emit_udm_zero_match_notices:finalize; do
        IFS=: read -r k producer stage <<<"$kind"
        check "$k: producer and stage" "$(block_field raised "$k" producer)|$(block_field raised "$k" stage)|$(block_field raised "$k" immediacy)|$(block_field raised "$k" shown)" \
            "$producer|$stage|deferred|panel" \
            'A migrated notice is recorded by the sub that raised it, in the stage it ran in, deferred, and drawn in the panel' \
            "$producer() and notice() in ltl" "$C_MIGRATION"
    done
    check "nothing on standard error" "$(wc -c < "$TMP_DIR/raised.err" | tr -d ' ')" "0" \
        'The notices raised after the read and at finalize reach the panel, never standard error' 'draw_deferred_notices() in ltl' "$C_MIGRATION"
}

# ---------------------------------------------------------------------------
# ask in a terminal (#412 D4, D5, D7, D8, D12; D17's tmux scenarios): ltl runs
# in a tmux pane, keys are sent, and the pane is captured as it is seen; the
# assertions read the captures through tests/lib/surface-capture.pl and the
# -V notices section the run prints at its end. macOS and Linux only; skipped
# where tmux is absent, never run on Windows (docs/terminal-interaction.md
# § Unattended runs and how a surface is tested).
# ---------------------------------------------------------------------------
C_ASK="$DOC § D4, D5, D7, D8, D12, D14; docs/terminal-interaction.md § Keys, § Taking input; acceptance criteria, ask"
TMUX_W=120
TMUX_H=50

tmux_ready() {
    if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == CYGWIN* ]] || ! command -v tmux > /dev/null 2>&1; then
        echo "  SKIP  $current_scenario :: tmux is not available on this host"
        return 1
    fi
}

# tmux_run NAME "STEPS" LTL-ARGS...: ltl in a pane of its own, no shell around
# it; STEPS is sleep:N, cap:LABEL (the pane, with and without its attributes,
# to NAME.LABEL.ansi and .txt), under:LABEL (the normal screen while a pop-up
# holds the alternate one: what the terminal showed before it) or a key name
# for send-keys. Afterwards the
# whole pane history, wrapped rows joined, is NAME.final.txt, and the pane's
# terminal state NAME.state ("alternate_on cursor_flag").
tmux_run() {
    local name="$1" steps="$2"; shift 2
    local sess="ltl-notices-$$-$RANDOM" step args
    printf -v args '%q ' "$(command -v perl)" "$LTL" --disable-progress "$@"
    # bash, not the default shell: it goes on after a child that handled an
    # interrupt itself, so the pane outlives the Ctrl-C a scenario sends.
    tmux new-session -d -s "$sess" -x "$TMUX_W" -y "$TMUX_H" -c "$TMP_DIR" \
        bash --noprofile --norc -c "$args; echo EXIT=\$?; sleep 60"
    for step in $steps; do
        case "$step" in
            sleep:*) sleep "${step#sleep:}" ;;
            under:*) tmux capture-pane -a -p -t "$sess" > "$TMP_DIR/$name.${step#under:}.txt" || true ;;
            cap:*)   tmux capture-pane -e -p -t "$sess" > "$TMP_DIR/$name.${step#cap:}.ansi" || true
                     tmux capture-pane -p -t "$sess"    > "$TMP_DIR/$name.${step#cap:}.txt" || true ;;
            *)       tmux send-keys -t "$sess" "$step" || true ;;
        esac
    done
    sleep 0.5
    # A capture that fails (the pane gone) leaves its file empty, which the
    # checks that read it then fail on.
    tmux capture-pane -p -J -S - -t "$sess" > "$TMP_DIR/$name.final.txt" || true
    tmux capture-pane -p -t "$sess" > "$TMP_DIR/$name.screen.txt" || true
    tmux display-message -p -t "$sess" '#{alternate_on} #{cursor_flag}' > "$TMP_DIR/$name.state" || true
    tmux kill-session -t "$sess" 2>/dev/null || true
}

# pane_exit NAME: the exit status the pane printed; pane_answer NAME KIND: the
# answer recorded for that kind in the run's -V notices.
pane_exit()   { sed -n 's/^EXIT=//p' "$TMP_DIR/$1.final.txt" | tail -1; }
pane_answer() { notice_field "$TMP_DIR/$1.final.txt" "$2" answer; }
# pane_boxes NAME LABEL: how many box tops the capture holds.
pane_boxes()  { grep -c '╭' "$TMP_DIR/$1.$2.txt" || true; }
# box_size NAME LABEL: "width x height" of the capture's box.
box_size() {
    awk '/╭/ { top = NR; w = length($0) } /╰/ && top { print "rows=" (NR - top + 1); exit }' "$TMP_DIR/$1.$2.txt" | tr -d '\n'
    perl -CSD -ne 'if (/(\x{256d}.*\x{256e})/) { print " cols=" . length($1); exit }' "$TMP_DIR/$1.$2.txt"
}
# predicate LABEL ASSERTS MODE ARGS...: one surface-capture.pl predicate as a check.
predicate() {
    local label="$1" asserts="$2"; shift 2
    local out rc=0
    out=$(perl "$SCRIPT_DIR/lib/surface-capture.pl" "$@" 2>&1) || rc=$?
    if [[ "$rc" -eq 0 ]]; then pass_with "$label"; else
        fail_with "$label" "$asserts" 'ask() and the drawing subs (notice_drawer, notice_draw_rows, notice_close_drawer) in ltl' "$C_ASK" "$(grep MISS <<<"$out" | head -3 | tr '\n' ' ')"
    fi
}

scenario_tmux_modal_keys() {
    current_scenario="tmux-modal-keys"
    echo "[$current_scenario]"
    tmux_ready || return 0
    tmux_run mk "sleep:2.5 cap:up under:before BTab sleep:0.4 cap:btab Tab sleep:0.4 cap:tab Escape sleep:1.5" -bs 1440 -oe -n 1 --notice-fixture ask-modal -V notices "$DURATION_FIXTURE"
    check "the modal is up, counting down" "$(pane_boxes mk up)|$(grep -c 'RUNTIME CONDITION' "$TMP_DIR/mk.up.txt")|$(grep -cE '\[ Stop here \] +Continue reading +\([0-9]+s\)' "$TMP_DIR/mk.up.txt")" "1|1|1" \
        'The modal opens on the alternate screen, the default rightmost and highlighted, its countdown beside it' 'ask() in ltl' "$C_ASK"
    predicate "two cells of padding, an empty row above and below each pane" 'A pop-up that will be erased has two cells inside its sides and an empty row above and below its content' panes "$TMP_DIR/mk.up.ansi" --side 2 --rows
    predicate "the run's rows unmoved under the modal" 'The rows the run printed are at their place under the pop-up, dimmed, outside its rectangle' unmoved "$TMP_DIR/mk.before.txt" "$TMP_DIR/mk.up.txt"
    check "Shift-Tab moves left, Tab back" "$(grep -c '  Stop here  *\[ Continue reading \]' "$TMP_DIR/mk.btab.txt")|$(grep -c '\[ Stop here \]' "$TMP_DIR/mk.tab.txt")" "1|1" \
        'Shift-Tab moves the highlight one button left, Tab one right, wrapping round' 'ask() in ltl (the stage-one key handling)' "$C_ASK"
    check "Esc takes the default" "$(pane_answer mk fixture-ask)|$(pane_exit mk)" "button=c option=- how=esc|0" \
        'Esc closes the surface and takes the default, recorded how=esc' 'ask() in ltl' "$C_ASK"
    check "the screen is given back" "$(cat "$TMP_DIR/mk.state")|$(grep -c '╭' "$TMP_DIR/mk.screen.txt" || true)" "0 1|0" \
        'Leaving, the alternate screen is closed, the cursor shown, and no box row is left' 'notice_close_drawer() and notice_restore_terminal() in ltl' "$C_ASK"
}

scenario_tmux_countdown() {
    current_scenario="tmux-countdown"
    echo "[$current_scenario]"
    tmux_ready || return 0
    tmux_run cd "sleep:2.5 cap:up Space sleep:2 cap:stopped Escape sleep:1.5" -bs 1440 -oe -n 1 --notice-fixture ask-modal -V notices "$DURATION_FIXTURE"
    check "any other key stops the countdown, and nothing says so" "$(grep -cE '\([0-9]+s\)' "$TMP_DIR/cd.up.txt")|$(grep -cE '\([0-9]+s\)' "$TMP_DIR/cd.stopped.txt" || true)|$(pane_boxes cd stopped)" "1|0|1" \
        'A key that is not a choice stops the countdown: the bracket disappears, the surface stays, nothing is said (D7)' 'notice_wait_choice() in ltl' "$C_ASK"
    tmux_run cr "sleep:4.5" -bs 1440 -oe -n 1 --notice-fixture ask-record -V notices "$DURATION_FIXTURE"
    check "the countdown runs out to the default, and the record stays" "$(pane_answer cr fixture-ask-record)|$(grep -c '↳ Continue reading? continue reading (default)' "$TMP_DIR/cr.final.txt")" "button=c option=- how=default|1" \
        'When the countdown ends the default is taken, how=default; with the record flag the notice and the answer stay inline (D4)' 'notice_wait_choice() and notice_leave_record() in ltl' "$C_ASK"
}

scenario_tmux_quit() {
    current_scenario="tmux-quit"
    echo "[$current_scenario]"
    tmux_ready || return 0
    tmux_run mq "sleep:2.5 x sleep:1.5" -bs 1440 -oe -n 1 --notice-fixture ask-modal -V notices "$DURATION_FIXTURE"
    check "q or x quits the run, -V notices written first" "$(pane_answer mq fixture-ask)|$(pane_exit mq)|$(grep -c 'LINES READ' "$TMP_DIR/mq.final.txt" || true)|$(cat "$TMP_DIR/mq.state")" \
        "button=c option=- how=quit|0|0|0 1" \
        'Quitting clears the surface, writes the -V notices section and stops the run cleanly before the read; the terminal is given back' 'notice_quit_run() in ltl' "$C_ASK"
    tmux_run mi "sleep:2.5 C-c sleep:1.5" -bs 1440 -oe -n 1 --notice-fixture ask-modal "$DURATION_FIXTURE"
    check "Ctrl-C gives the terminal back" "$(pane_exit mi)|$(cat "$TMP_DIR/mi.state")" "130|0 1" \
        'An interrupt during an ask leaves the alternate screen, shows the cursor, restores the input mode and exits 130' 'notice_restore_terminal() and the INT handler in ask() in ltl' "$C_ASK"
}

scenario_tmux_options() {
    current_scenario="tmux-options"
    echo "[$current_scenario]"
    tmux_ready || return 0
    tmux_run mo "sleep:2.5 cap:stage1 l sleep:0.6 cap:list Down sleep:0.4 cap:list2 Escape sleep:1.5" -bs 1440 -oe -n 1 --notice-fixture ask-options -V notices "$DURATION_FIXTURE"
    local s1 l1
    s1=$(box_size mo stage1); l1=$(box_size mo list)
    check "the list opens: the width kept, the height grown" "${s1#* }|${l1#* }|$([[ ${s1%% *} != "${l1%% *}" ]] && echo grown || echo same)" "${s1#* }|${s1#* }|grown" \
        'A choice keeps its width at the second stage and takes the list stage its own height (docs/terminal-interaction.md § Pop-up size)' 'ask() in ltl (frame_rows per stage)' "$C_ASK"
    check "the list in columns, the first highlighted, then the next" "$(grep -c 'What? *How? *Why?' "$TMP_DIR/mo.list.txt")|$(grep -c '▶ 1  the what' "$TMP_DIR/mo.list.txt")|$(grep -c '▶ 2  the what' "$TMP_DIR/mo.list2.txt")" "1|1|1" \
        'The options list shows its headings and one row per option; Down moves the highlight' 'notice_options_rows() in ltl' "$C_ASK"
    check "Esc on the list continues as planned" "$(pane_answer mo fixture-ask-options)" "button=l option=three how=esc" \
        'Esc on the options list takes the list default and records how=esc' 'ask() in ltl (the stage-two key handling)' "$C_ASK"
    tmux_run mf "sleep:2.5 cap:stage1 l sleep:0.6 cap:list Escape sleep:1.5" -bs 1440 -oe -n 1 --notice-fixture ask-fixed -V notices "$DURATION_FIXTURE"
    check "a fixed height is the taller stage's for both" "$(box_size mf stage1)" "$(box_size mf list)" \
        'A caller asking for a fixed height gets the taller stage height for both stages' 'ask() in ltl (fixed_height)' "$C_ASK"
}

scenario_tmux_below_cursor() {
    current_scenario="tmux-below-cursor"
    echo "[$current_scenario]"
    tmux_ready || return 0
    tmux_run bi "sleep:2.5 cap:up BTab sleep:0.4 Enter sleep:1.5" -bs 1440 -oe -n 1 --notice-fixture ask-inline -V notices "$DURATION_FIXTURE"
    check "below the cursor, one empty row above it" "$(awk '/╭/ { print NR; exit }' "$TMP_DIR/bi.up.txt")|$(sed -n 5p "$TMP_DIR/bi.up.txt" | tr -d ' ')" "6|" \
        'Below the cursor the modal starts one empty row under the title, never two' 'notice_draw_rows() in ltl (inline)' "$C_ASK"
    predicate "two cells of padding below the cursor too" 'A pop-up below the cursor keeps the pop-up padding' panes "$TMP_DIR/bi.up.ansi" --side 2 --rows
    check "Enter takes the highlighted button" "$(pane_answer bi fixture-ask-inline)" "button=s option=- how=key" \
        'Enter activates the highlighted button, here Stop after Shift-Tab' 'ask() in ltl' "$C_ASK"
    check "erased, the run going on" "$(grep -c '╭' "$TMP_DIR/bi.final.txt" || true)|$(grep -c 'LINES READ' "$TMP_DIR/bi.final.txt")" "0|1" \
        'Once answered the surface is erased with its empty row and the run continues in its place' 'notice_close_drawer() in ltl' "$C_ASK"
}

scenario_tmux_box() {
    current_scenario="tmux-box"
    echo "[$current_scenario]"
    tmux_ready || return 0
    tmux_run bx "sleep:2.5 cap:up q sleep:0.5 cap:q Escape sleep:1.5" -bs 1440 -oe -n 1 --notice-fixture ask-box -V notices "$DURATION_FIXTURE"
    check "the compact box spans the width" "$(box_size bx up | sed 's/.* //')" "cols=$(( TMUX_W - 1 ))" \
        'The compact box is drawn below the cursor across the terminal, one cell narrower' 'ask() in ltl (form box)' "$C_ASK"
    check "q is ignored, quitting is off" "$(pane_boxes bx q)|$(pane_answer bx fixture-ask-box)" "1|button=c option=- how=esc" \
        'On the compact box quitting is off by default, so q does nothing; Esc then takes the default' 'notice_action() in ltl' "$C_ASK"
    tmux_run bo "sleep:2.5 L sleep:0.6 cap:list 2 sleep:0.4 cap:list2 Enter sleep:1.5" -bs 1440 -oe -n 1 --notice-fixture ask-options-box -V notices "$DURATION_FIXTURE"
    check "a choice letter in upper case, a number, Enter" "$(grep -c 'Order *Option' "$TMP_DIR/bo.list.txt")|$(pane_answer bo fixture-ask-options-box)" "1|button=l option=by-bytes how=key" \
        'A choice letter is accepted in either case; a number chooses the n-th option and Enter takes it' 'ask() in ltl' "$C_ASK"
}

scenario_tmux_ahead() {
    current_scenario="tmux-ahead"
    echo "[$current_scenario]"
    tmux_ready || return 0
    tmux_run ah "sleep:2.5 cap:up" -bs 1440 -oe -n 1 --notice-fixture ask-modal --notice-answers s -V notices "$DURATION_FIXTURE"
    check "an answer given ahead draws nothing and is taken" "$(grep -c 'RUNTIME CONDITION' "$TMP_DIR/ah.final.txt" || true)|$(pane_answer ah fixture-ask)" "0|button=s option=- how=ahead" \
        'With the answer given ahead in a terminal the surface is not drawn and the answer is taken, how=ahead' 'ask() in ltl (answers given ahead)' "$C_ASK"
}

# ---------------------------------------------------------------------------
# ask with no terminal: drawn once as it appears, in the state the default or
# the answer given ahead reaches; nothing waits, and the run goes on.
# ---------------------------------------------------------------------------
scenario_ask_unattended() {
    current_scenario="ask-unattended"
    echo "[$current_scenario]"
    run_ok am "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 --notice-fixture ask-modal -V notices "$DURATION_FIXTURE"
    predicate "drawn once, nothing but colour codes, the run going on" 'With no terminal the surface is drawn once, with no cursor control, and the run continues to its summary' plain "$TMP_DIR/am.out" --boxes 1
    check "the default, no terminal to wait on" "$(block_field am fixture-ask answer)|$(block_field am fixture-ask shown)|$(block_field am fixture-ask immediacy)|$(block_field am fixture-ask choice)" \
        "button=c option=- how=no_terminal|ask|now|yes" \
        'A choice with no terminal takes its default at once, recorded how=no_terminal; the record is shown by ask, immediate, with a choice' 'ask() in ltl' "$C_ASK"
    check "the default highlighted, the countdown shown" "$(sed 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/am.out" | grep -cE '\[ Stop here \] +Continue reading +\(10s\)')" "1" \
        'The surface appears as it first would: the default rightmost and highlighted, the 10 s countdown beside it' 'notice_button_row() in ltl' "$C_ASK"
    run_ok aa "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 --notice-fixture ask-options --notice-answers l,two -V notices "$DURATION_FIXTURE"
    check "an answer given ahead, with its option" "$(block_field aa fixture-ask-options answer)|$(sed 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/aa.out" | grep -c '▶ 2  the what')" "button=l option=two how=ahead|1" \
        'Given ahead, the button letter and the option key are taken, how=ahead, and the surface is drawn in the state they reach: the list, the option highlighted' 'ask() in ltl (answers given ahead)' "$C_ASK"
    run_ok au "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 --notice-fixture ask-options --notice-answers L,nosuch -V notices "$DURATION_FIXTURE"
    check "an unknown option key falls to the list's default" "$(block_field au fixture-ask-options answer)" "button=l option=three how=ahead" \
        'A choice letter in either case; an option key the list does not carry takes its default' 'ask() in ltl (answers given ahead)' "$C_ASK"
    run_ok ab "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 --notice-fixture ask-box -V notices "$DURATION_FIXTURE"
    check "the compact box" "$(panel ab 1 width)|$(sed 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/ab.out" | grep -cE 'Continue reading\?  Stop here   Continue reading \(10s\)')|$(sed 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/ab.out" | grep -c 's: stop here · c: continue reading · Esc: continue reading')" "119|1|1" \
        'The compact box spans the width, the question on its last inside row with the choices, the key bar the choice letters and Esc' 'ask() in ltl (form box)' "$C_ASK"
    run_ok ar "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 --notice-fixture ask-record --notice-answers s -V notices "$DURATION_FIXTURE"
    check "the record flag leaves the answer inline" "$(sed 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/ar.out" | grep -c '↳ Continue reading? stop here (ahead)')|$(sed 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/ar.out" | grep -c '(3s)')" "1|1" \
        'With the record flag the notice and the answer are left inline; the caller sets the seconds' 'notice_leave_record() in ltl' "$C_ASK"
    run_ok as "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 --notice-fixture ask-several -V notices "$DURATION_FIXTURE"
    check "shows names the notices presented" "$(block_field as fixture-ask-several shows)|$(block_field as fixture-shown-first shown)|$(block_field as fixture-shown-first visible)|$(block_field as fixture-shown-second visible)|$(panels as)" \
        "1,2|ask|no|no|1" \
        'An ask presenting notices raised before it names their ids in shows; each is shown by ask and kept off the deferred panel' 'ask() in ltl' "$DOC § D13 (the shows row); $C_ASK"
    check "several notices bulleted under the category" "$(panel as 1 title | sed -E 's/  .*//')|$(panel_rows as 1 notice | wc -l | tr -d ' ')" "⚙ YOUR OPTIONS (2) command usage warnings|2" \
        'An ask over several notices heads them with the category and its count, one bulleted row each' 'ask() in ltl' "$C_ASK"
}

# ---------------------------------------------------------------------------
# The notices of option parsing, asked about before the read (#412 D16): the
# real producer of the ask. With no terminal, drawn once and continued; in a
# terminal, s stops the run before the read with -V notices written.
# ---------------------------------------------------------------------------
scenario_preread() {
    current_scenario="preread"
    echo "[$current_scenario]"
    run_ok pr "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 -so time -dmin 500 -dmax 100 -V notices "$DURATION_FIXTURE"
    check "one question over the option notices" \
        "$(block_field pr options-review shows)|$(block_field pr options-review answer)|$(block_field pr deprecated-spelling shown)|$(block_field pr range-unsatisfiable visible)" \
        "1,2|button=c option=- how=no_terminal|ask|no" \
        'The notices raised while the options were read are put in one ask before the read, which presents them (shows) and keeps them off the panel' \
        'ask_about_option_notices() in ltl' "$DOC § D16; $C_ASK"
    check "with no terminal the run continues" "$(grep -c 'LINES READ' "$TMP_DIR/pr.out")|$(sed 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/pr.out" | grep -c 'Continue with these options?')|$(wc -c < "$TMP_DIR/pr.err" | tr -d ' ')" "1|1|0" \
        'With no terminal the question is drawn once, the default continues the run, and nothing goes to standard error' 'ask_about_option_notices() in ltl' "$DOC § D16; $C_ASK"
    run_ok clean "$LTL" -bs 1440 -oe -n 1 --terminal-width 120 -V notices "$DURATION_FIXTURE"
    check "no option notice, no question" "$(notice_kind_count "$TMP_DIR/clean.out" options-review)" "0" \
        'A run whose options raise nothing is not asked' 'ask_about_option_notices() in ltl' "$DOC § D16"
    tmux_ready || return 0
    tmux_run ps "sleep:2.5 cap:up s sleep:1.5" -bs 1440 -oe -n 1 -so time -V notices "$DURATION_FIXTURE"
    check "in a terminal the question waits" "$(grep -c 'Continue with these options?' "$TMP_DIR/ps.up.txt")" "1" \
        'In a terminal the question is a modal over the run, waiting with its countdown' 'ask() in ltl' "$C_ASK"
    check "s stops the run before the read, -V notices written" "$(pane_answer ps options-review)|$(pane_exit ps)|$(grep -c 'LINES READ' "$TMP_DIR/ps.final.txt" || true)" "button=s option=- how=key|0|0" \
        'Stop and correct them ends the run before any file is read, the -V notices section written first' 'ask_about_option_notices() in ltl' "$DOC § D16; $C_ASK"
}

scenario_register registered \
                  clean-run \
                  read-path-fallback \
                  record-fields \
                  kind-stable \
                  shape \
                  fixture-refused \
                  panel-placement \
                  panel-none \
                  panel-headed \
                  panel-parts \
                  panel-edge \
                  panel-wrap \
                  panel-light \
                  panel-windows-glyphs \
                  panel-immediate \
                  migration-categories \
                  migration-raised \
                  ask-unattended \
                  tmux-modal-keys \
                  tmux-countdown \
                  tmux-quit \
                  tmux-options \
                  tmux-below-cursor \
                  tmux-box \
                  tmux-ahead \
                  preread
scenario_parse_args "$@"

if [[ ! -f "$LTL" ]]; then
    echo "ERROR: ltl not found at $LTL"; exit 1
fi
for f in "$ACCESS_FIXTURE" "$DURATION_FIXTURE"; do
    if [[ ! -f "$f" ]]; then echo "ERROR: fixture not found: $f"; exit 1; fi
done

TMP_DIR=$(mktemp -d); trap 'rm -rf "$TMP_DIR"' EXIT

while read -r _scenario; do
    "scenario_${_scenario//-/_}"
done < <(scenario_selected)

echo
echo "Results: $pass passed, $fail failed"
if [[ "$pass" -eq 0 && "$fail" -eq 0 ]]; then
    echo "FAIL: no assertion ran"
    exit 1
fi
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    printf '  %s\n' "${failures[@]}"
    exit 1
fi
exit 0
