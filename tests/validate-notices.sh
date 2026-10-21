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
# reached through the calls a producer makes.
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
    ( cd "$TMP_DIR" && perl "$ltl" --disable-progress "$@" ) > "$TMP_DIR/$tag.out" 2> "$TMP_DIR/$tag.err" || rc=$?
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
        "decision_taken_for_you|read_path_fall_back|parse|deferred|yes|none|no|-" \
        'The fallback is a decision taken for the analyst, raised by read_path_fall_back during the read, deferred, visible, drawn by no surface yet, with no choice' \
        'read_path_fall_back() and notice() in ltl' "$C_PRODUCER"
    check "the statement" "$(list fallback statement)" \
        "the faster read path could not be prepared, so large files are read with the standard path, which is slower" \
        'The statement is the notice text, without its prefix' 'read_path_fall_back() in ltl' "$C_PRODUCER"
    check "still printed on standard error" "$(grep -c '^Note: the faster read path could not be prepared' "$TMP_DIR/fallback.err" || true)" "1" \
        'Until the panel draws deferred notices, the fallback still prints once on standard error' 'flush_deferred_notices() in ltl' "$DOC § Delivery plan, drop 1"
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
    check "immediacy and shown" "$(field fields immediacy | sort -u | paste -sd, -)|$(field fields shown | sort -u | paste -sd, -)" "deferred|none" \
        'A deferred notice is drawn by no surface at the call' 'notice() in ltl' "$C_STORE"
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
        "$(cat "$TMP_DIR/refused.rc")|$(grep -c "^--notice-fixture: 'no-such-set' is not a fixture set; the sets are record-fields$" "$TMP_DIR/refused.err" || true)" "1|1" \
        'An unknown fixture set exits 1 with a message naming the sets' '_validate_notice_fixture() in ltl' "$C_FIXTURE"
}

scenario_register registered \
                  clean-run \
                  read-path-fallback \
                  record-fields \
                  kind-stable \
                  shape \
                  fixture-refused
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
