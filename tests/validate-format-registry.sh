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
# it errors before any codegen. A CSV file adds the block generated from its
# header, counted by the same counters, one alive at a time
# (features/615-csv-registry-entry.md D11): a run pinned to csv compiles its
# scan sub and one block; a second file of the same header shape is a cache
# hit; one of another shape is one more compile, and replaces the first. A regression that restored eager
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
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

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
        pattern     '^scanned_entries: 29$' \
        asserts     'The registry compiles 29 scanned entries (every format the scan can recognise, variant members included: the six Apache mod_jk connector shapes and the four tag-less G1 decorations among them); csv is stateful and mtvfy pin-only, both outside the scan array' \
        produced_by 'emit_format_registry_verbose() in ltl, reading @format_registry_members built by build_format_registry()' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - changes only when a scanned format is added or removed, in the same commit as this assertion'

    assert_line "$out" \
        pattern     '^entries: 31$' \
        asserts     'The registry holds 31 entries in all: the 29 scanned entries, the pin-only mtvfy and the stateful csv' \
        produced_by 'emit_format_registry_verbose() in ltl, reading every spec of format_registry_specs()' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - changes when any entry is added or removed, in the same commit as this assertion'

    # The Apache mod_jk connector writes one line shape per stamp fraction
    # and request-id bracket (features/655-apache-mod-jk-connector-format.md
    # D1): each is its own scanned entry under its own name.
    local jk
    for jk in 'mtjk apache_mod_jk' 'mtjkus apache_mod_jk_microseconds' 'mtjks apache_mod_jk_seconds' \
              'mtjkni apache_mod_jk_no_request_id' 'mtjkusni apache_mod_jk_microseconds_no_request_id' \
              'mtjksni apache_mod_jk_seconds_no_request_id'; do
        assert_line "$out" \
            pattern     "^  entry: ${jk% *} slug=${jk#* } group=${jk% *} default=yes role=scanned\$" \
            asserts     "The connector shape ${jk#* } is a scanned entry of its own, a group of one, named by how its line differs from the base shape" \
            produced_by 'emit_format_registry_verbose() in ltl (FR_NAME, FR_SLUG, group and role per entry)' \
            contract    'features/655-apache-mod-jk-connector-format.md D1 (one entry per line shape the connector can write); features/log-format-registry.md section -V format-registry section-contract'
    done

    assert_line "$out" \
        pattern     '^family: access=mt3ts,mt12,mt9,mt19,mt20,mt3,mt4$' \
        asserts     'the access family lists its seven members in static order: thread-session, bracketed, jboss, combined-duration, combined, common-duration, common (#444 D4/D5)' \
        produced_by 'emit_format_registry_verbose() in ltl (family line)' \
        contract    'features/444-access-log-format-family-and-user-surface.md D5; features/log-format-registry.md section -V format-registry section-contract'
    assert_line "$out" \
        pattern     '^  ancestors: mt19 <- mt9$' \
        asserts     'access_combined_duration stays behind jboss_access, whose samples its generic pattern also matches (#444 D4)' \
        produced_by 'derive_format_constraints() in ltl' \
        contract    'features/444-access-log-format-family-and-user-surface.md D4'
    assert_line "$out" \
        pattern     '^scan_slots: 28$' \
        asserts     'The 29 scanned entries occupy 28 scan slots: one slot per variant group, since only one member of a group is seated at a time (D47); each connector shape and each tag-less G1 decoration is a group of one' \
        produced_by 'emit_format_registry_verbose() in ltl, reading @format_registry (one entry per group slot)' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - agrees with entries: N in format-detection / scan, which counts the same slots'

    assert_line "$out" \
        pattern     '^  entry: csv slug=csv group=csv default=yes role=stateful$' \
        asserts     'CSV is a registry entry but carries the stateful role: it is not scanned (D32); its block is compiled per header shape, one alive at a time (#615 D11)' \
        produced_by 'emit_format_registry_verbose() in ltl (role from FR_SCANNED)' \
        contract    'features/log-format-registry.md section -V format-registry section-contract'

    assert_line "$out" \
        pattern     '^  entry: mt3 slug=access_common_duration group=mt3 default=yes role=scanned$' \
        asserts     'A non-default variant member reports its group and default=no - the evidence pass can seat it, but it does not hold the slot by default' \
        produced_by 'emit_format_registry_verbose() in ltl (group and FR_GROUP_DEFAULT per entry)' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - variant groups are D47/F1'

    local gc_entry
    for gc_entry in 'mt6t slug=java_gc_g1_time' 'mt6tu slug=java_gc_g1_time_uptime' 'mt6tl slug=java_gc_g1_time_level' 'mt6tp slug=java_gc_g1_time_pid'; do
        assert_line "$out" \
            pattern     "^  entry: $gc_entry group=${gc_entry%% *} default=yes role=scanned\$" \
            asserts     'Each tag-less G1 decoration is its own scanned entry in its own group, not a variant of the tagged entry: the decoration is visible on every line (features/656-gc-log-tagless-decorations.md D2, D4)' \
            produced_by 'emit_format_registry_verbose() in ltl (FR_NAME, FR_SLUG and group per entry)' \
            contract    'features/656-gc-log-tagless-decorations.md D8; features/log-format-registry.md section -V format-registry section-contract'
    done

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
        pattern     '^  group: connection_server slot=1 default=mt10 members=mt10,mt10ir$' \
        asserts     'A variant group declares its slot position, its default member and its full member list; the access shapes form none, since a unit no line carries cannot make a variant (#444 D3 as revised)' \
        produced_by 'emit_format_registry_verbose() in ltl, reading %format_variant_groups built by build_format_registry()' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - group membership is declared by variant_group/variant_default in format_registry_specs()'

    assert_line "$out" \
        pattern     '^static_order: mt1std,mt10,mt16,mt1gen,mt2,mt3ts,mt12,mt9,mt19,mt20,mt3,mt4,mt5,mt6,mt6t,mt6tu,mt6tl,mt6tp,mt7,mt8,mt17,mt11,mtjk,mtjkus,mtjks,mtjkni,mtjkusni,mtjksni$' \
        asserts     'The static scan order is the declaration order of the group slots - the order every run starts from and the baseline promotion permutes' \
        produced_by 'emit_format_registry_verbose() in ltl, reading @format_registry' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - changes only when a format is added, removed or re-sequenced in format_registry_specs()'

    assert_line "$out" \
        pattern     '^  ancestors: mt3 <- -$' \
        asserts     'With every family pattern anchored at both ends (#444 D4) no earlier group shadows the common-plus-duration shape: its derived pinned-ancestor set is empty (D26)' \
        produced_by 'derive_format_constraints() in ltl; emitted by emit_format_registry_verbose()' \
        contract    'features/log-format-registry.md section -V format-registry section-contract - the derived set is cross-checked against each entry expect_ancestors by D24 gate 4, so a drift fails the build before this assertion'

    local gc_slot
    for gc_slot in mt6 mt6t mt6tu mt6tl mt6tp; do
        assert_line "$out" \
            pattern     "^  ancestors: $gc_slot <- -\$" \
            asserts     'No G1 entry shadows another: each decoration shape is distinct on every line, so none has a pinned ancestor (features/656-gc-log-tagless-decorations.md D2)' \
            produced_by 'derive_format_constraints() in ltl; emitted by emit_format_registry_verbose()' \
            contract    'features/656-gc-log-tagless-decorations.md AC7; features/log-format-registry.md section -V format-registry section-contract'
    done

    assert_line "$out" \
        pattern     '^  ancestors: mt12 <- -$' \
        asserts     'A group no other pattern shadows reports an empty ancestor set, and is therefore free to promote to the very front' \
        produced_by 'derive_format_constraints() in ltl; emitted by emit_format_registry_verbose()' \
        contract    'features/log-format-registry.md section -V format-registry section-contract'

    local jk
    for jk in mtjk mtjkus mtjks mtjkni mtjkusni mtjksni; do
        assert_line "$out" \
            pattern     "^  ancestors: $jk <- -\$" \
            asserts     "No other pattern matches a sample of the connector shape $jk and its pattern matches no other entry sample: its slot has no pinned ancestors and adds none to any other slot" \
            produced_by 'derive_format_constraints() in ltl; emitted by emit_format_registry_verbose()' \
            contract    'features/655-apache-mod-jk-connector-format.md AC9; features/log-format-registry.md section -V format-registry section-contract (cross-checked against expect_ancestors by D24 gate 4)'
    done

    assert_line "$out" \
        pattern     '^variant_groups: connection_server=mt10$' \
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
        asserts     'A single-format scanned file compiles at most two subs (it has no CSV block): nothing is generated at startup, and election fronts the format the evidence named before line 1' \
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
    out=$(run_format_registry "$FIXTURES/tomcat-access.txt" -lf access_common_duration)
    check_capture_warnings "$out"

    assert_line "$out" \
        pattern     '^scan_subs_compiled: 1$' \
        asserts     'A run pinned to a scanned format compiles exactly one sub: the pin restricts the scan to a single entry, and that one order is the only codegen the run pays for' \
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

# ---------------------------------------------------------------------------
# Scenarios: the CSV block (features/615-csv-registry-entry.md D11, AC5, AC6
# (d), AC7). Two-row CSV fixtures generated inline; the counts are read from
# runs of one file and of two.
# ---------------------------------------------------------------------------
CONTRACT_615='features/615-csv-registry-entry.md D11 (at most one CSV block alive; the existing compile and cache-hit counters count it) and section 5.7; features/log-format-registry.md section -V format-registry section-contract'
write_csv_fixtures() {
    printf 'timestamp,latency,size\n2026-06-01 10:00:05,12,100\n2026-06-01 10:01:05,34,200\n' > "$TMP_DIR/a-first.csv"
    printf 'timestamp,latency,size\n2026-06-01 11:00:05,56,300\n2026-06-01 11:01:05,78,400\n' > "$TMP_DIR/b-same.csv"
    printf 'size,timestamp,latency\n100,2026-06-01 10:00:05,12\n200,2026-06-01 10:01:05,34\n' > "$TMP_DIR/b-reordered.csv"
    printf 'timestamp,latency\n2025-13-01 10:00:05,12\n2025-14-01 10:01:05,34\n' > "$TMP_DIR/day-first.csv"
}

scenario_csv_pinned() {
    current_scenario="csv-pinned"
    echo "[$current_scenario]"
    write_csv_fixtures
    local out
    out=$(run_format_registry "$TMP_DIR/a-first.csv" -lf csv -udm latency)
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     '^scan_subs_compiled: 2$' \
        asserts     'A run pinned to csv compiles its scan sub (the pin leaves no scanned entry in it) and one CSV block, generated from the header at CSV confirmation' \
        produced_by 'apply_format_pin() and compile_format_scan_sub() for the scan sub; csv_block_for_file() and compile_csv_block() for the block' \
        contract    "$CONTRACT_615; AC7"
    assert_line "$out" \
        pattern     '^compiled_orders: ;csv:csv:sep=comma:ts=0:udm=1:msg=-$' \
        asserts     'The cache lists the CSV block by its signature (layout, separator, timestamp column, each -udm column, the -ucm columns) after the empty scan order the pin leaves, whose signature is empty' \
        produced_by 'csv_block_shape() in ltl; emitted by emit_format_registry_verbose() from the keys of %format_scan_sub_cache' \
        contract    "$CONTRACT_615; section 5.4 (the signature)"
}

scenario_csv_same_shape() {
    current_scenario="csv-same-shape"
    echo "[$current_scenario]"
    write_csv_fixtures
    local one two
    one=$(run_format_registry "$TMP_DIR/a-first.csv" -udm latency)
    check_capture_warnings "$one"
    two=$(run_format_registry "$TMP_DIR/b-same.csv" -udm latency "$TMP_DIR/a-first.csv")
    check_capture_warnings "$two"
    assert_line "$one" \
        pattern     '^scan_subs_compiled: 2$' \
        asserts     'One CSV file compiles the scan sub its first line is scanned with and one CSV block' \
        produced_by 'format_scan_sub_resolve() and compile_csv_block() in ltl' \
        contract    "$CONTRACT_615; AC7"
    assert_line "$two" \
        pattern     '^scan_subs_compiled: 2$' \
        asserts     'A second CSV file of the same header shape compiles nothing: the live block, validated on its sampled rows, serves it' \
        produced_by 'csv_block_for_file() in ltl (the live block validated first)' \
        contract    "$CONTRACT_615; AC7"
    assert_line "$two" \
        pattern     '^scan_sub_cache_hits: 2$' \
        asserts     'The second file adds two cache hits: its scan order, resolved again before its first line, and the live CSV block that serves it' \
        produced_by 'format_scan_sub_resolve() and csv_block_for_file() in ltl, both counting $format_scan_sub_cache_hits' \
        contract    "$CONTRACT_615; AC7"
}

scenario_csv_different_shape() {
    current_scenario="csv-different-shape"
    echo "[$current_scenario]"
    write_csv_fixtures
    local out
    out=$(run_format_registry "$TMP_DIR/b-reordered.csv" -udm latency "$TMP_DIR/a-first.csv")
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     '^scan_subs_compiled: 3$' \
        asserts     'Two CSV files with the same columns in another order compile two blocks: the header builds the routine, so its column positions are part of the block' \
        produced_by 'csv_block_shape() and compile_csv_block() in ltl' \
        contract    "$CONTRACT_615; D10 (the header builds the routine); AC5, AC7"
    assert_line "$out" \
        pattern     '^scan_sub_cache_hits: 1$' \
        asserts     'The second file adds one cache hit, its scan order; the CSV block it needs is not in the cache' \
        produced_by 'format_scan_sub_resolve() and csv_block_for_file() in ltl' \
        contract    "$CONTRACT_615; AC7"
    assert_line "$out" \
        pattern     '^compiled_orders: csv:csv:sep=comma:ts=1:udm=2:msg=-;[^;]+$' \
        asserts     'The cache holds one CSV signature, the second file one (timestamp in column 1, the metric in column 2): the first block was deleted when the second was generated' \
        produced_by 'compile_csv_block() and csv_block_evict() in ltl' \
        contract    "$CONTRACT_615; AC7"
}

scenario_csv_day_first() {
    current_scenario="csv-day-first"
    echo "[$current_scenario]"
    write_csv_fixtures
    local out
    out=$(run_format_registry "$TMP_DIR/day-first.csv" -udm latency)
    check_capture_warnings "$out"
    assert_line "$out" \
        pattern     '^compiled_orders: csv:csv_ddmm:sep=comma:ts=0:udm=1:msg=-;[^;]+$' \
        asserts     'A CSV file whose sampled dates are real only read day first is served by the day-first block, the one CSV signature in the cache' \
        produced_by 'csv_block_for_file() in ltl (the day-first retry after the month-first block fails validation)' \
        contract    'features/615-csv-registry-entry.md D9 (validation on the sampled rows with the day-first retry), D15, AC6 (d)'
    assert_line "$out" \
        pattern     '^scan_subs_compiled: 3$' \
        asserts     'The day-first retry is a compile of its own: the scan sub, the month-first block that failed, then the day-first block' \
        produced_by 'csv_block_for_file() and compile_csv_block() in ltl' \
        contract    "$CONTRACT_615; section 5.7 (every generation is counted)"
    cp "$TMP_DIR/day-first.csv" "$TMP_DIR/day-first-2.csv"
    local pair
    pair=$(run_format_registry "$TMP_DIR/day-first-2.csv" -udm latency "$TMP_DIR/day-first.csv")
    check_capture_warnings "$pair"
    assert_line "$pair" \
        pattern     '^scan_subs_compiled: 5$' \
        asserts     'A second day-first file is settled month first again: its month-first block fails and its day-first block is generated anew, two compiles more than one file' \
        produced_by 'csv_block_for_file() in ltl (month first tried first, whatever file came before)' \
        contract    'features/615-csv-registry-entry.md D18 (every CSV file date order is settled starting month first, whatever file came before it; the cost is these two compiles)'
}

echo "=== validate-format-registry.sh ==="
echo ""

scenario_register inventory \
                  structure \
                  election-single-format \
                  election-mixed-format \
                  election-pinned \
                  invalid-pin-no-codegen \
                  benchmark-data-reemission \
                  unarmed-measurement \
                  csv-pinned \
                  csv-same-shape \
                  csv-different-shape \
                  csv-day-first
scenario_parse_args "$@"

while read -r _scenario; do
    case "$_scenario" in
        inventory                ) scenario_inventory ;;
        structure                ) scenario_structure ;;
        election-single-format   ) scenario_election_single_format ;;
        election-mixed-format    ) scenario_election_mixed_format ;;
        election-pinned          ) scenario_election_pinned ;;
        invalid-pin-no-codegen   ) scenario_invalid_pin_no_codegen ;;
        benchmark-data-reemission) scenario_benchmark_data_reemission ;;
        unarmed-measurement      ) scenario_unarmed_run ;;
        csv-pinned               ) scenario_csv_pinned ;;
        csv-same-shape           ) scenario_csv_same_shape ;;
        csv-different-shape      ) scenario_csv_different_shape ;;
        csv-day-first            ) scenario_csv_day_first ;;
    esac
    echo ""
done < <(scenario_selected)

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
