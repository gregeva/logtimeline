#!/usr/bin/env bash
# validate-format-registry.sh — Validate the `format-registry` `-V` section:
# the compiled registry's inventory and structure, and the scan-sub compile
# state under elevation by election.
# Usage: ./tests/validate-format-registry.sh
#
# The registry itself had no observability surface before issue #413 —
# `-V format-detection` reports what each FILE bound, never what the
# registry IS or what codegen the run paid for. This harness consumes the
# section that closes that gap: entry inventory (name, slug, group,
# variant-default, role), structure (variant groups with occupants, static
# scan order, derived pinned-ancestor constraints), and compile state
# (subs compiled, cache hits, accumulated compile-boundary RSS delta).
#
# The election invariants are the load-bearing assertions: under D60 no
# codegen happens at startup, so a single-format file compiles at most two
# subs, `-lf` compiles exactly one, and an invalid `-lf` compiles none —
# it errors before any codegen. A regression that restored eager
# precompilation would put ~28 compiles and ~20 MB back on every run and
# these assertions are what catches it.
#
# Implements the self-documenting-assertion design from
# tests/HARNESS-DESIGN.md. Reference: tests/validate-format-detection.sh.
#
# Issue #413.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"
FIXTURES="$REPO_DIR/tests/fixtures/format-detection"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited; issue #438).
neutralize_colour_env

# Temp dir for captured outputs; cleaned up on EXIT per HARNESS-DESIGN.md Trap 10.
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi

pass=0
fail=0
failures=()
current_scenario=""

# Self-documenting assertion: a line matching `pattern` must be present.
# Required fields: pattern, asserts, produced_by, contract.
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

# Bounded-value assertion: the integer carried by the single line matching
# `key` must satisfy `max` (and `min`, when given). Used for the election
# invariants, which are ceilings rather than frozen values — a run may
# legitimately compile fewer subs, never more. A missing or duplicated
# anchor is a hard failure, never a pass (HARNESS-DESIGN.md: a grep that
# matches nothing is a failure).
assert_int_le() {
    local outfile="$1"
    shift
    local key max min asserts produced_by contract
    min=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            key)         key="$2";         shift 2 ;;
            max)         max="$2";         shift 2 ;;
            min)         min="$2";         shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_int_le: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${key:?assert_int_le requires key}"
    : "${max:?assert_int_le requires max}"
    : "${asserts:?assert_int_le requires asserts}"
    : "${produced_by:?assert_int_le requires produced_by}"
    : "${contract:?assert_int_le requires contract}"

    local matches
    matches=$(grep -cE "^${key}: [0-9]+\$" "$outfile" || true)
    if [[ "$matches" -ne 1 ]]; then
        echo "  FAIL  $current_scenario"
        echo "        anchor:      ^${key}: <int>\$ matched $matches lines (expected exactly 1)"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: anchor $key matched $matches lines")
        return
    fi
    local value
    value=$(grep -E "^${key}: [0-9]+\$" "$outfile" | sed -E "s/^${key}: //")
    if [[ "$value" -le "$max" && "$value" -ge "$min" ]]; then
        echo "  PASS  $current_scenario :: $key=$value (in [$min,$max])"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        $key:        $value (expected within [$min,$max])"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $key=$value outside [$min,$max]")
    fi
}

# Runtime-warning cleanliness for a capture (its stderr lives beside the
# captured stdout as <capture>.stderr). Runs in the main shell so the fail
# counters persist. HARNESS-DESIGN.md section Runtime-warning cleanliness.
check_capture_warnings() {
    local capture="$1"
    if ! assert_no_runtime_warnings "$capture.stderr" "$current_scenario"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: perl-runtime-warnings-on-stderr")
    fi
}

# Helper: run ltl -V format-registry against $1 (log path), forwarding any
# extra args. Echoes the capture path.
#
# Invocation shape (HARNESS-DESIGN.md section Invocation coherence): every
# assertion here reads the -V format-registry section — what the registry
# compiled to and how many scan subs the run minted — which is identical at
# any bucket size and needs no rendered table. So the run takes the coarsest
# bucket with no empty buckets and the smallest table (`-bs 1440 -oe -n 1
# -osum`), on the smallest fixture carrying the format under assertion.
#
# HARNESS-DESIGN.md Trap 1: preserve stderr, check exit code.
run_format_registry() {
    local log="$1"
    shift
    local outfile
    outfile="$TMP_DIR/$(basename "$log" | tr -c 'A-Za-z0-9._-' '_')$$.out"
    set +e
    "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 -osum -V format-registry "$@" "$log" > "$outfile" 2>"$outfile.stderr"
    local ec=$?
    set -e
    if [[ "$ec" -ne 0 ]]; then
        echo "FAIL: ltl exited $ec for $log; stderr:" >&2
        sed 's/^/    /' "$outfile.stderr" >&2
        exit 1
    fi
    if [[ ! -s "$outfile" ]]; then
        echo "FAIL: empty capture for $log" >&2
        exit 1
    fi
    # HARNESS-DESIGN.md Trap 3: confirm the section header is present before
    # returning the path, so a renamed or removed section fails loudly here
    # rather than as a wall of not-found assertions.
    if ! grep -qE '^=== format-registry ===$' "$outfile"; then
        echo "FAIL: format-registry section header not found in capture for $log" >&2
        echo "       capture: $outfile" >&2
        exit 1
    fi
    if ! grep -qE '^=== END format-registry ===$' "$outfile"; then
        echo "FAIL: format-registry END marker not found in capture for $log" >&2
        echo "       capture: $outfile" >&2
        exit 1
    fi
    echo "$outfile"
}

# ---------------------------------------------------------------------------
# Scenario: inventory — the registry's entry list and slot arithmetic.
# ---------------------------------------------------------------------------
scenario_inventory() {
    current_scenario="inventory"
    echo "[$current_scenario]"
    local out
    out=$(run_format_registry "$FIXTURES/tomcat-access.txt")
    check_capture_warnings "$out"

    assert_line "$out" \
        pattern     '^scanned_entries: 21$' \
        asserts     'The registry compiles 17 scanned entries (every format the scan can recognise, variant members included); csv is stateful and outside the scan array' \
        produced_by 'emit_format_registry_verbose() in ltl, reading @format_registry_members built by build_format_registry()' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - changes only when a scanned format is added or removed, in the same commit as this assertion'

    assert_line "$out" \
        pattern     '^family: access=mt3ts,mt3tsus,mt12,mt9,mt19,mt20,mt3,mt3us,mt4$' \
        asserts     'the access family lists its nine members in static order: thread-session (ms, us), bracketed, jboss, combined-duration, combined, common-duration (ms, us), common (#444 D4/D5)' \
        produced_by 'emit_format_registry_verbose() in ltl (family line)' \
        contract    'features/444-access-log-format-family-and-user-surface.md D5; features/log-format-registry.md section -V format-registry section-contract'
    assert_line "$out" \
        pattern     '^  ancestors: mt19 <- mt9$' \
        asserts     'access_combined_duration stays behind jboss_access, whose samples its generic pattern also matches (#444 D4)' \
        produced_by 'derive_format_constraints() in ltl' \
        contract    'features/444-access-log-format-family-and-user-surface.md D4'
    assert_line "$out" \
        pattern     '^scan_slots: 18$' \
        asserts     'The 17 scanned entries occupy 15 scan slots: one slot per variant group, since only one member of a group is seated at a time (D47)' \
        produced_by 'emit_format_registry_verbose() in ltl, reading @format_registry (one entry per group slot)' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - agrees with entries: N in format-detection / scan, which counts the same slots'

    assert_line "$out" \
        pattern     '^  entry: csv slug=csv group=csv default=yes role=stateful$' \
        asserts     'CSV is a registry entry but carries the stateful role, marking it as the per-file path outside the generated scan (D32)' \
        produced_by 'emit_format_registry_verbose() in ltl (role from FR_SCANNED)' \
        contract    'features/log-format-registry.md section -V format-registry section-contract'

    assert_line "$out" \
        pattern     '^  entry: mt3us slug=access_common_duration_us group=access_common_duration default=no role=scanned$' \
        asserts     'A non-default variant member reports its group and default=no - the evidence pass can seat it, but it does not hold the slot by default' \
        produced_by 'emit_format_registry_verbose() in ltl (group and FR_GROUP_DEFAULT per entry)' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - variant groups are D47/F1'

    assert_line "$out" \
        pattern     '^  entry: mt1std slug=thingworx_standard .*$' \
        asserts     'Two entries may share one user-facing slug (mt1std and mt1gen both map to thingworx_standard), which is why the section keys on entry names throughout' \
        produced_by 'emit_format_registry_verbose() in ltl (FR_NAME and FR_SLUG per entry)' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - vocabulary note: entry names are the registry scan identity, slugs the user-facing identity'
}

# ---------------------------------------------------------------------------
# Scenario: structure — variant groups, static order, ancestor constraints.
# ---------------------------------------------------------------------------
scenario_structure() {
    current_scenario="structure"
    echo "[$current_scenario]"
    local out
    out=$(run_format_registry "$FIXTURES/tomcat-access.txt")
    check_capture_warnings "$out"

    assert_line "$out" \
        pattern     '^  group: access_with_duration slot=8 default=mt3 members=mt3,mt3us$' \
        asserts     'The access_with_duration group declares its slot position, its default member and its full member list - Tomcat and httpd share a line shape but differ in duration unit' \
        produced_by 'emit_format_registry_verbose() in ltl, reading %format_variant_groups built by build_format_registry()' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - group membership is declared by variant_group/variant_default in format_registry_specs()'

    assert_line "$out" \
        pattern     '^static_order: mt1std,mt10,mt16,mt1gen,mt2,mt12,mt4,mt9,mt3,mt5,mt6,mt7,mt8,mt17,mt11$' \
        asserts     'The static scan order is the declaration order of the group slots - the order every run starts from and the baseline promotion permutes' \
        produced_by 'emit_format_registry_verbose() in ltl, reading @format_registry' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - changes only when a format is added, removed or re-sequenced in format_registry_specs()'

    assert_line "$out" \
        pattern     '^  ancestors: access_with_duration <- mt12,mt4,mt9$' \
        asserts     'The derived pinned-ancestor set records that three earlier groups shadow access_with_duration, so promotion may never move it ahead of them (D26)' \
        produced_by 'derive_format_constraints() in ltl; emitted by emit_format_registry_verbose()' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - the derived set is cross-checked against each entry expect_ancestors by D24 gate 4, so a drift fails the build before this assertion'

    assert_line "$out" \
        pattern     '^  ancestors: mt12 <- -$' \
        asserts     'A group no other pattern shadows reports an empty ancestor set, and is therefore free to promote to the very front' \
        produced_by 'derive_format_constraints() in ltl; emitted by emit_format_registry_verbose()' \
        contract    'features/log-format-registry.md section -V format-registry section-contract'

    assert_line "$out" \
        pattern     '^variant_groups: connection_server=mt10,access_with_duration=mt3$' \
        asserts     'Each variant group reports the member actually seated in its slot for this run - here both defaults, since the tomcat fixture gives no evidence for either alternative' \
        produced_by 'emit_format_registry_verbose() in ltl (occupant read from @format_scan_order)' \
        contract    'features/log-format-registry.md section -V format-registry section-contract'
}

# ---------------------------------------------------------------------------
# Scenario: election invariant — a single-format file compiles at most two
# scan subs. This is the assertion that fails if eager precompilation is
# ever restored.
# ---------------------------------------------------------------------------
scenario_election_single_format() {
    current_scenario="election-single-format"
    echo "[$current_scenario]"
    local out
    out=$(run_format_registry "$FIXTURES/tomcat-access.txt")
    check_capture_warnings "$out"

    assert_int_le "$out" \
        key         'scan_subs_compiled' \
        max         2 \
        min         1 \
        asserts     'A single-format file compiles at most two scan subs: nothing is generated at startup, and election fronts the format the evidence named before line 1' \
        produced_by 'compile_format_scan_sub() in ltl increments the counter; election is format_elect_scan_front(), resolution format_scan_sub_resolve()' \
        contract    'features/log-format-registry.md D60 elevation by election - a regression to eager precompilation (D40) puts ~28 compiles and ~20 MB back on every run, and this ceiling is what catches it'

    assert_line "$out" \
        pattern     '^scan_sub_rss_measured: yes$' \
        asserts     'Requesting -V format-registry arms the compile-boundary RSS measurement, so the reported byte total is a real measurement rather than a silent zero' \
        produced_by 'adapt_to_command_line_options() in ltl sets the arming flag; read by compile_format_scan_sub()' \
        contract    'features/log-format-registry.md D62 - measurement is armed only when a memory-reporting surface was requested; a plain run pays nothing'

    assert_line "$out" \
        pattern     '^scan_subs_rss_bytes: [1-9][0-9]*$' \
        asserts     'With measurement armed, the accumulated compile-boundary RSS delta is a positive byte count (nondeterministic: shape asserted, never the value; ~0.6 MB per compiled sub)' \
        produced_by 'compile_format_scan_sub() in ltl (RSS delta across the eval); emitted by emit_format_registry_verbose()' \
        contract    'features/log-format-registry.md D62 - Devel::Size reaches only ~55% of a closure cost, so RSS delta at the compile boundary is the instrument'
}

# ---------------------------------------------------------------------------
# Scenario: election invariant under a mixed-format file — more formats in
# the stream means more orders, but still nothing speculative.
# ---------------------------------------------------------------------------
scenario_election_mixed_format() {
    current_scenario="election-mixed-format"
    echo "[$current_scenario]"
    local out
    out=$(run_format_registry "$FIXTURES/mixed.txt")
    check_capture_warnings "$out"

    assert_int_le "$out" \
        key         'scan_subs_compiled' \
        max         4 \
        min         1 \
        asserts     'A file interleaving two formats compiles only the handful of recency orders its stream actually visits - one per distinct order, never one per registry entry' \
        produced_by 'compile_format_scan_sub() in ltl; orders reached via format_elect_scan_front() and format_registry_promote()' \
        contract    'features/log-format-registry.md D60 - alternation cycles through a tiny set of orders, each compiled at most once per run and cached by signature'

    assert_line "$out" \
        pattern     '^compiled_orders: .+$' \
        asserts     'Every compiled order is reported by its signature, so the compile count can be read against which orders the run actually needed' \
        produced_by 'emit_format_registry_verbose() in ltl, reading the keys of %format_scan_sub_cache' \
        contract    'features/log-format-registry.md section -V format-registry section-contract'
}

# ---------------------------------------------------------------------------
# Scenario: -lf compiles exactly one sub, and an invalid -lf compiles none.
# ---------------------------------------------------------------------------
scenario_election_pinned() {
    current_scenario="election-pinned"
    echo "[$current_scenario]"
    local out
    out=$(run_format_registry "$FIXTURES/tomcat-access.txt" -lf access_common_duration_ms)
    check_capture_warnings "$out"

    assert_line "$out" \
        pattern     '^scan_subs_compiled: 1$' \
        asserts     'A pinned run compiles exactly one scan sub: the pin restricts the scan to a single entry, and that one order is the only codegen the run pays for' \
        produced_by 'apply_format_pin() in ltl calls format_scan_sub_resolve() once; counter incremented in compile_format_scan_sub()' \
        contract    'features/log-format-registry.md D60 compile point 3 - before #413 the pin compiled its sub on top of a fully precompiled registry, saving nothing'

    assert_line "$out" \
        pattern     '^scan_slots: 1$' \
        asserts     'The pin narrows the live scan array to the pinned format alone, so the registry reports a single slot' \
        produced_by 'apply_format_pin() in ltl rebuilds @format_registry from the matching members' \
        contract    'features/log-format-registry.md D49/N9 - the pin bypasses detection, the evidence pass and variant selection'
}

# ---------------------------------------------------------------------------
# Scenario: an invalid -lf operand errors before any codegen. Asserted on
# the compile counter reported by a benchmark-data run, since the failing
# invocation itself exits non-zero and emits no sections.
# ---------------------------------------------------------------------------
scenario_invalid_pin_no_codegen() {
    current_scenario="invalid-pin-no-codegen"
    echo "[$current_scenario]"
    local outfile="$TMP_DIR/invalid-pin.out"
    set +e
    "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 -osum -lf nonsense \
        "$FIXTURES/tomcat-access.txt" > "$outfile" 2>"$outfile.stderr"
    local ec=$?
    set -e

    if [[ "$ec" -eq 0 ]]; then
        echo "  FAIL  $current_scenario"
        echo "        asserts:     An unknown -lf operand is a usage error"
        echo "        produced_by: apply_format_pin() in ltl"
        echo "        contract:    features/log-format-registry.md D49/N9"
        echo "        (ltl exited 0 for -lf nonsense)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: unknown -lf exited 0")
    else
        echo "  PASS  $current_scenario :: unknown -lf exits non-zero ($ec)"
        pass=$((pass + 1))
    fi

    assert_line "$outfile.stderr" \
        pattern     "^Error: Unknown log format 'nonsense' for -lf\. Known formats: " \
        asserts     'An unknown -lf operand is reported as a usage error naming the known formats, and the run stops there' \
        produced_by 'apply_format_pin() in ltl' \
        contract    'features/log-format-registry.md D60 compile point 3 - the pin validates its operand before compiling anything, so a typo costs no codegen at all'

    check_capture_warnings "$outfile"
}

# ---------------------------------------------------------------------------
# Scenario: one source, two surfaces — benchmark-data re-emits the same
# compile counters the section reports, never an independent recount.
# ---------------------------------------------------------------------------
scenario_benchmark_data_reemission() {
    current_scenario="benchmark-data-reemission"
    echo "[$current_scenario]"
    local outfile="$TMP_DIR/bench.out"
    set +e
    "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 -osum -V format-registry,benchmark-data \
        "$FIXTURES/mixed.txt" > "$outfile" 2>"$outfile.stderr"
    local ec=$?
    set -e
    if [[ "$ec" -ne 0 ]]; then
        echo "FAIL: ltl exited $ec; stderr:" >&2
        sed 's/^/    /' "$outfile.stderr" >&2
        exit 1
    fi
    check_capture_warnings "$outfile"

    local section_value bench_value
    section_value=$(grep -E '^scan_subs_compiled: [0-9]+$' "$outfile" | sed -E 's/^scan_subs_compiled: //')
    bench_value=$(grep -E '^COUNTS\tformat_scan_subs_compiled\t[0-9]+$' "$outfile" | cut -f3)

    if [[ -z "$section_value" || -z "$bench_value" ]]; then
        echo "  FAIL  $current_scenario"
        echo "        anchor:      scan_subs_compiled (section) / COUNTS format_scan_subs_compiled (benchmark-data)"
        echo "        asserts:     Both surfaces report the compile count"
        echo "        produced_by: emit_format_registry_verbose() and print_verbose_output() in ltl"
        echo "        contract:    tests/HARNESS-DESIGN.md section Counters serving benchmark attribution"
        echo "        (section='$section_value' benchmark-data='$bench_value')"
        fail=$((fail + 1))
        failures+=("$current_scenario :: a compile-count anchor was missing")
    elif [[ "$section_value" == "$bench_value" ]]; then
        echo "  PASS  $current_scenario :: compile count agrees across both surfaces ($section_value)"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        section:     scan_subs_compiled=$section_value"
        echo "        benchmark:   COUNTS format_scan_subs_compiled=$bench_value"
        echo "        asserts:     The two surfaces read one variable and cannot disagree"
        echo "        produced_by: emit_format_registry_verbose() and print_verbose_output() in ltl, both reading \$format_scan_subs_compiled"
        echo "        contract:    tests/HARNESS-DESIGN.md section Counters serving benchmark attribution - one computation site, two surfaces"
        fail=$((fail + 1))
        failures+=("$current_scenario :: compile count disagrees between surfaces")
    fi

    assert_line "$outfile" \
        pattern     '^MEMORY\tformat_scan_subs\t[1-9][0-9]*$' \
        asserts     'The scan-sub memory category reaches the benchmark TSV as a MEMORY row, so a release comparison can attribute registry codegen cost' \
        produced_by 'print_verbose_output() in ltl, reading the same accumulator compile_format_scan_sub() fills' \
        contract    'features/log-format-registry.md D62 - the category is measured by compile-boundary RSS delta, not a structure walk'
}

# ---------------------------------------------------------------------------
# Scenario: a plain run takes no RSS reading. Arming is the whole reason
# the measurement is affordable, so its absence is a contracted invariant.
# ---------------------------------------------------------------------------
scenario_unarmed_run() {
    current_scenario="unarmed-measurement"
    echo "[$current_scenario]"
    local outfile="$TMP_DIR/unarmed.out"
    set +e
    "$LTL" --disable-progress -ni -bs 1440 -oe -n 1 -osum -V format-detection \
        "$FIXTURES/tomcat-access.txt" > "$outfile" 2>"$outfile.stderr"
    local ec=$?
    set -e
    if [[ "$ec" -ne 0 ]]; then
        echo "FAIL: ltl exited $ec; stderr:" >&2
        sed 's/^/    /' "$outfile.stderr" >&2
        exit 1
    fi
    check_capture_warnings "$outfile"

    if grep -qE '^MEMORY\tformat_scan_subs\t' "$outfile"; then
        echo "  FAIL  $current_scenario"
        echo "        pattern:     MEMORY format_scan_subs (contracted ABSENT, but found)"
        echo "        asserts:     A run that requested no memory-reporting surface emits no scan-sub memory row"
        echo "        produced_by: print_verbose_output() in ltl, gated on the arming flag"
        echo "        contract:    features/log-format-registry.md D62 - measurement is armed at option parse; a plain run pays nothing"
        fail=$((fail + 1))
        failures+=("$current_scenario :: memory row emitted on an unarmed run")
    else
        echo "  PASS  $current_scenario :: absent: MEMORY format_scan_subs on an unarmed run"
        pass=$((pass + 1))
    fi
}

echo "=== validate-format-registry.sh ==="
echo ""

scenario_inventory;                 echo ""
scenario_structure;                 echo ""
scenario_election_single_format;    echo ""
scenario_election_mixed_format;     echo ""
scenario_election_pinned;           echo ""
scenario_invalid_pin_no_codegen;    echo ""
scenario_benchmark_data_reemission; echo ""
scenario_unarmed_run

echo ""
echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "ALL FORMAT-REGISTRY TESTS PASSED"
exit 0
