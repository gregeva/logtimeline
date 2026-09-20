#!/usr/bin/env bash
# validate-scenario-selector.sh — the scenario selector contract
# (tests/HARNESS-DESIGN.md § The scenario selector, issue #545).
#
# Asserts the contract every harness in the suite depends on: a scenario name
# the harness knows runs that scenario and no other; a name it does not know,
# and an argument it does not parse, are refused with a non-zero exit and no
# assertion run.
#
# Two subjects, because the contract has two halves:
#
#   1. tests/lib/scenario-select.sh directly, through purpose-built probe
#      harnesses under a temporary directory. A probe registers known
#      scenarios and reports which ran, so "ran nothing" and "ran everything"
#      are distinguishable — which is exactly what the defect behind #545
#      could not be.
#
#   2. Every tests/validate-*.sh in the suite, for the two refusals. This is
#      the half that regresses: a harness added later, or rewritten, loses the
#      selector silently, and the suite's own green run says nothing about it.
#      Same reasoning as the runtime-warning and colour-environment sweeps —
#      a guard applied to most harnesses leaves the next one to be found by an
#      investigation rather than by a test.
#
# Usage: ./tests/validate-scenario-selector.sh [--scenario NAME] [--list]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB="$SCRIPT_DIR/lib/scenario-select.sh"
PERL="${PERL:-/opt/homebrew/bin/perl}"
command -v "$PERL" >/dev/null 2>&1 || PERL=perl

# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

neutralize_colour_env

[[ -f "$LIB" ]] || { echo "ERROR: required file missing: $LIB" >&2; exit 1; }

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0
failures=()
current_scenario=""

CONTRACT='tests/HARNESS-DESIGN.md section The scenario selector - a selector that matches nothing is an unasserted run; an unknown scenario name and an unknown argument are refused with a non-zero exit and no assertion run (issue #545)'

fail_with() {   # label, asserts, produced_by, contract, detail
    echo "  FAIL  $current_scenario :: $1"
    echo "        asserts:     $2"
    echo "        produced_by: $3"
    echo "        contract:    $4"
    [[ -n "${5:-}" ]] && echo "        detail:      $5"
    fail=$((fail + 1)); failures+=("$current_scenario :: $1")
    return 0
}
pass_with() { echo "  PASS  $current_scenario :: $1"; pass=$((pass + 1)); }

# assert_equal label actual expected asserts .. produced_by .. contract ..
assert_equal() {
    local label="$1" actual="$2" expected="$3"; shift 3
    local asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_equal: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${asserts:?}" "${produced_by:?}" "${contract:?}"
    if [[ "$actual" == "$expected" ]]; then
        pass_with "$label ('$actual')"
    else
        fail_with "$label" "$asserts" "$produced_by" "$contract" "expected '$expected', got '$actual'"
    fi
}

# A probe harness: registers three scenarios and prints one line per scenario
# that runs, so a run that asserts nothing is visible as such.
write_probe() {
    local path="$1"; shift
    {
        echo '#!/usr/bin/env bash'
        echo 'set -euo pipefail'
        echo "source '$LIB'"
        echo 'scenario_register alpha beta gamma'
        printf '%s\n' "$@"
        echo 'scenario_parse_args "$@"'
        echo 'while read -r s; do echo "RAN:$s"; done < <(scenario_selected)'
    } > "$path"
    chmod +x "$path"
}

# run_probe PROBE ARGS... -> sets probe_rc, probe_out
run_probe() {
    local probe="$1"; shift
    set +e
    probe_out=$("$probe" "$@" 2>&1)
    probe_rc=$?
    set -e
}

PROBE="$TMP_DIR/probe.sh"
write_probe "$PROBE"

# ---------------------------------------------------------------------------
# Scenarios
# ---------------------------------------------------------------------------

scenario_selects_one() {
    current_scenario="selects-one"
    echo "[$current_scenario]"

    run_probe "$PROBE" --scenario beta
    assert_equal "a known name exits zero" "$probe_rc" 0 \
        asserts     'Naming a scenario the harness knows is not an error' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
    assert_equal "that scenario runs, and no other" "$(echo "$probe_out" | grep -c '^RAN:')" 1 \
        asserts     'Explicitly stating a scenario restricts the run to that scenario and nothing else' \
        produced_by 'scenario_selected() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
    assert_equal "the scenario that ran is the one named" "$(echo "$probe_out" | grep '^RAN:')" "RAN:beta" \
        asserts     'The scenario that runs is the one the operator named, not a neighbour' \
        produced_by 'scenario_selected() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"

    run_probe "$PROBE" --scenario=gamma
    assert_equal "the --scenario=NAME spelling selects too" "$(echo "$probe_out" | grep '^RAN:')" "RAN:gamma" \
        asserts     'The selector accepts both --scenario NAME and --scenario=NAME' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
}

scenario_bare_run_is_every_scenario() {
    current_scenario="bare-run-is-every-scenario"
    echo "[$current_scenario]"

    run_probe "$PROBE"
    assert_equal "a bare invocation exits zero" "$probe_rc" 0 \
        asserts     'A harness invoked with no arguments runs normally; this is how the suite runs it' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
    assert_equal "every registered scenario runs" "$(echo "$probe_out" | grep -c '^RAN:')" 3 \
        asserts     'A bare invocation runs every registered scenario, so strict parsing never narrows the completion gate' \
        produced_by 'scenario_selected() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
}

scenario_unknown_name_refused() {
    current_scenario="unknown-name-refused"
    echo "[$current_scenario]"

    run_probe "$PROBE" --scenario no-such-scenario
    assert_equal "exit code is non-zero" "$probe_rc" 2 \
        asserts     'A scenario name the harness does not know is an error, not a silent full run and not a silent empty one' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh (membership check)' \
        contract    "$CONTRACT"
    assert_equal "no scenario runs" "$(echo "$probe_out" | grep -c '^RAN:')" 0 \
        asserts     'An unknown scenario name runs no assertion at all — the failure #545 was filed for is a harness reporting a pass over zero assertions' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh (membership check)' \
        contract    "$CONTRACT"
    if echo "$probe_out" | grep -q "unknown scenario 'no-such-scenario'"; then
        pass_with "the diagnostic names the unknown scenario"
    else
        fail_with "the diagnostic names the unknown scenario" \
            'The error states the name that was not recognised, so the operator can see their own typo' \
            'scenario_parse_args() in tests/lib/scenario-select.sh' "$CONTRACT" "$probe_out"
    fi
    if echo "$probe_out" | grep -q '^  alpha$'; then
        pass_with "the diagnostic lists the scenarios that do exist"
    else
        fail_with "the diagnostic lists the scenarios that do exist" \
            'The error prints the registered scenario names, so the operator can correct the selector without reading the harness' \
            'scenario_usage() in tests/lib/scenario-select.sh' "$CONTRACT" "$probe_out"
    fi
}

scenario_unknown_flag_refused() {
    current_scenario="unknown-flag-refused"
    echo "[$current_scenario]"

    run_probe "$PROBE" --no-such-flag
    assert_equal "exit code is non-zero" "$probe_rc" 2 \
        asserts     'An unrecognised flag is an error, not something silently ignored' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
    assert_equal "no scenario runs" "$(echo "$probe_out" | grep -c '^RAN:')" 0 \
        asserts     'An unrecognised flag runs no assertion: a harness that ran its full set under a flag it ignored is what made two investigations read a full run as one scenario' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"

    run_probe "$PROBE" --scenario
    assert_equal "a selector with no name is refused" "$probe_rc" 2 \
        asserts     '--scenario without a name is an error rather than an empty selection that matches everything' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
}

scenario_harness_keeps_its_own_flags() {
    current_scenario="harness-keeps-its-own-flags"
    echo "[$current_scenario]"

    local probe="$TMP_DIR/probe-extra.sh"
    write_probe "$probe" \
        'FLAG=0' \
        'extra() { case "$1" in --mine) FLAG=1; SCENARIO_ARGS_CONSUMED=1 ;; --pair) FLAG=2; SCENARIO_ARGS_CONSUMED=2 ;; *) SCENARIO_ARGS_CONSUMED=0 ;; esac; }' \
        'SCENARIO_EXTRA_ARG_HANDLER=extra' \
        'trap '"'"'echo "FLAG:$FLAG"'"'"' EXIT'

    run_probe "$probe" --mine --scenario alpha
    assert_equal "the harness's own flag is claimed" "$(echo "$probe_out" | grep '^FLAG:')" "FLAG:1" \
        asserts     'A handler runs in the current shell, so a flag it sets is visible to the harness. Invoked under command substitution it would set the flag in a subshell and the harness would never see it.' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh (SCENARIO_EXTRA_ARG_HANDLER dispatch)' \
        contract    "$CONTRACT"
    assert_equal "the selector still applies alongside it" "$(echo "$probe_out" | grep '^RAN:')" "RAN:alpha" \
        asserts     'A harness with flags of its own still honours the scenario selector' \
        produced_by 'scenario_selected() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"

    run_probe "$probe" --pair value --scenario alpha
    assert_equal "a handler consuming two arguments is honoured" "$(echo "$probe_out" | grep '^FLAG:')" "FLAG:2" \
        asserts     'The handler states how many arguments it claimed, so an option that takes a value does not leave its value to be read as an unknown argument' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"

    run_probe "$probe" --not-mine
    assert_equal "a flag the handler declines is still refused" "$probe_rc" 2 \
        asserts     'A handler that declines an argument does not make it acceptable: unknown-argument rejection stays in one place' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
}

scenario_duplicate_registration_refused() {
    current_scenario="duplicate-registration-refused"
    echo "[$current_scenario]"

    local probe="$TMP_DIR/probe-dup.sh"
    {
        echo '#!/usr/bin/env bash'
        echo 'set -euo pipefail'
        echo "source '$LIB'"
        echo 'scenario_register alpha beta alpha'
        echo 'echo "REACHED"'
    } > "$probe"
    chmod +x "$probe"

    run_probe "$probe"
    assert_equal "exit code is non-zero" "$probe_rc" 2 \
        asserts     'Registering one scenario name twice is a harness defect: one of the two is unreachable by name while both run in the full pass' \
        produced_by 'scenario_register() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
    assert_equal "the harness does not proceed" "$(echo "$probe_out" | grep -c '^REACHED')" 0 \
        asserts     'A duplicate registration stops the harness rather than leaving it to run with an ambiguous registry' \
        produced_by 'scenario_register() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
}

scenario_named_scenario_runs() {
    current_scenario="named-scenario-runs"
    echo "[$current_scenario]"

    # Refusing what it does not know is half the contract; the other half is
    # that a name it does know runs. A selector bolted onto a harness can gate
    # a block so that a statement the block needs — a contract string, a
    # fixture path — is left inside the scenario before it, and selecting that
    # scenario alone then dies on an unbound variable while the full pass stays
    # green. Nothing else in the suite looks at a harness under selection, so
    # this is where that shows up.
    #
    # Two checks, because running all 504 registered scenarios as live ltl
    # invocations is a completion gate of its own, not an assertion inside one.
    #
    # First, statically: a harness that gates its blocks where they stand can
    # swallow a statement written between two scenarios — a contract string, a
    # fixture path — into whichever block the gate closed after. Every scenario
    # still runs in a bare invocation, so the full pass stays green, and only
    # the later scenario selected alone dies on an unbound variable. That is
    # the run this contract exists to make trustworthy. The check reads the
    # gating and reports any variable assigned inside one block and read inside
    # another.
    #
    # Then, dynamically: the first scenario each harness registers is actually
    # run, which proves the gating executes and the harness survives being
    # restricted. One run per harness, not one per scenario.
    local broken=0 checked=0 crossblock=0 broken_list="" crossblock_list=""
    local h name first out

    crossblock_list=$("$PERL" -e '
        use strict; use warnings;
        my @reports;
        for my $file (@ARGV) {
            open my $fh, "<", $file or next;
            my @lines = <$fh>; close $fh;
            my (@blocks, $start);
            for my $i (0 .. $#lines) {
                if ($lines[$i] =~ /^if scenario_wanted /) { $start = $i }
                elsif (defined $start && $lines[$i] =~ /^fi\s*$/) {
                    push @blocks, [$start, $i]; undef $start;
                }
            }
            next unless @blocks;
            my $block_of = sub {
                my $i = shift;
                for my $k (0 .. $#blocks) {
                    return $k if $blocks[$k][0] < $i && $i < $blocks[$k][1];
                }
                return undef;
            };
            my %home;
            for my $i (0 .. $#lines) {
                next unless $lines[$i] =~ /^([A-Z][A-Z0-9_]*)=/;
                my $b = $block_of->($i);
                $home{$1} //= $b if defined $b;
            }
            for my $name (sort keys %home) {
                for my $i (0 .. $#lines) {
                    my $b = $block_of->($i);
                    next unless defined $b && $b != $home{$name};
                    next unless $lines[$i] =~ /\$\{?\Q$name\E\b/;
                    my $base = $file; $base =~ s{.*/}{};
                    push @reports, "$base:\$$name";
                    last;
                }
            }
        }
        print join(" ", @reports);
    ' "$SCRIPT_DIR"/validate-*.sh)
    [[ -n "$crossblock_list" ]] && crossblock=$(printf '%s' "$crossblock_list" | wc -w | tr -d ' ')

    assert_equal "no scenario depends on a variable another scenario sets" "$crossblock" 0 \
        asserts     'A variable assigned inside one scenario block and read inside another makes the second unselectable: it dies on an unbound variable while the full pass, which runs both, stays green.' \
        produced_by 'the block gating in each harness, against scenario_wanted() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
    if [[ -n "$crossblock_list" ]]; then
        echo "        found:      $crossblock_list"
    fi

    for h in "$SCRIPT_DIR"/validate-*.sh; do
        name=$(basename "$h")
        [[ "$name" == "$(basename "$0")" ]] && continue
        # The statistics and csv-output harnesses drive the shared capture
        # cache; running a scenario of each here would race the gate's own runs
        # of them (tests/HARNESS-DESIGN.md section Cached capture artifacts
        # expire).
        case "$name" in validate-statistics.sh|validate-csv-output.sh) continue ;; esac

        first=$("$h" --list 2>/dev/null | sed -n '/^Scenarios:$/,$p' \
                | sed -n 's/^  \([A-Za-z0-9][A-Za-z0-9:+._-]*\)$/\1/p' | head -1)
        [[ -n "$first" ]] || continue
        checked=$((checked + 1))

        set +e
        out=$("$h" --scenario "$first" 2>&1)
        set -e
        if printf '%s' "$out" | grep -qE 'unbound variable|syntax error near|: command not found'; then
            broken=$((broken + 1))
            broken_list="$broken_list $name:$first"
        fi
    done

    if [[ "$checked" -lt 2 ]]; then
        fail_with "the sweep found harnesses to check" \
            'The sweep reads the suite from disk; finding none means it is looking in the wrong place' \
            'this harness (the validate-*.sh glob)' "$CONTRACT" "checked=$checked"
        return 0
    fi
    pass_with "ran one named scenario in each of $checked harnesses"

    assert_equal "a named scenario runs without shell breakage" "$broken" 0 \
        asserts     'Selecting a scenario a harness declares runs it, rather than dying in the gating that was added around it' \
        produced_by 'the gating in each harness, against scenario_wanted() in tests/lib/scenario-select.sh' \
        contract    "$CONTRACT"
    if [[ -n "$broken_list" ]]; then
        echo "        harnesses:  $broken_list"
    fi
}

scenario_every_harness_refuses() {
    current_scenario="every-harness-refuses"
    echo "[$current_scenario]"

    local bad_name=0 bad_flag=0 no_listing=0 checked=0
    local bad_name_list="" bad_flag_list="" no_listing_list=""
    local h rc

    for h in "$SCRIPT_DIR"/validate-*.sh; do
        [[ "$(basename "$h")" == "$(basename "$0")" ]] && continue
        checked=$((checked + 1))

        set +e
        "$h" --scenario definitely-not-a-registered-scenario >/dev/null 2>&1
        rc=$?
        set -e
        [[ "$rc" -eq 0 ]] && { bad_name=$((bad_name + 1)); bad_name_list="$bad_name_list $(basename "$h")"; }

        set +e
        "$h" --definitely-not-a-flag >/dev/null 2>&1
        rc=$?
        set -e
        [[ "$rc" -eq 0 ]] && { bad_flag=$((bad_flag + 1)); bad_flag_list="$bad_flag_list $(basename "$h")"; }

        # Capture first, then match. `--list | grep -q` closes the pipe as
        # soon as it matches, and the harness still writing is killed by
        # SIGPIPE — so the pipeline's status reports the harness's death
        # rather than whether the listing was found (HARNESS-DESIGN.md
        # Trap 1: a harness never reads a status that is not the one it means).
        local listing
        set +e
        listing=$("$h" --list 2>/dev/null)
        set -e
        if ! printf '%s\n' "$listing" | grep -q '^Scenarios:$'; then
            no_listing=$((no_listing + 1)); no_listing_list="$no_listing_list $(basename "$h")"
        fi
    done

    if [[ "$checked" -lt 2 ]]; then
        fail_with "the sweep found harnesses to check" \
            'The sweep reads the suite from disk; finding none means it is looking in the wrong place, not that the suite is compliant' \
            'this harness (the validate-*.sh glob)' "$CONTRACT" "checked=$checked"
        return 0
    fi
    pass_with "swept $checked harnesses"

    assert_equal "none accepts an unknown scenario name" "$bad_name" 0 \
        asserts     'Every harness in the suite refuses a scenario name it does not know. A harness added or rewritten without the selector is found here rather than by an investigation that misread a full run as one scenario.' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh, called by each harness' \
        contract    "$CONTRACT"
    if [[ -n "$bad_name_list" ]]; then
        echo "        harnesses:  $bad_name_list"
    fi

    assert_equal "none accepts an unknown flag" "$bad_flag" 0 \
        asserts     'Every harness in the suite refuses an argument it does not parse' \
        produced_by 'scenario_parse_args() in tests/lib/scenario-select.sh, called by each harness' \
        contract    "$CONTRACT"
    if [[ -n "$bad_flag_list" ]]; then
        echo "        harnesses:  $bad_flag_list"
    fi

    assert_equal "every harness lists its scenarios" "$no_listing" 0 \
        asserts     'Every harness declares its scenarios under --list, so the names an operator may select are discoverable without reading the harness source' \
        produced_by 'scenario_usage() in tests/lib/scenario-select.sh, called by each harness' \
        contract    "$CONTRACT"
    if [[ -n "$no_listing_list" ]]; then
        echo "        harnesses:  $no_listing_list"
    fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

SCENARIO_USAGE_NOTE="  (the library's own contract, then the suite-wide sweep)"
scenario_register selects-one \
                  bare-run-is-every-scenario \
                  unknown-name-refused \
                  unknown-flag-refused \
                  harness-keeps-its-own-flags \
                  duplicate-registration-refused \
                  named-scenario-runs \
                  every-harness-refuses
scenario_parse_args "$@"

echo "Validating the scenario selector (issue #545)"
echo "  library:   $LIB"
echo ""

while read -r _scenario; do
    case "$_scenario" in
        selects-one)                   scenario_selects_one ;;
        bare-run-is-every-scenario)    scenario_bare_run_is_every_scenario ;;
        unknown-name-refused)          scenario_unknown_name_refused ;;
        unknown-flag-refused)          scenario_unknown_flag_refused ;;
        harness-keeps-its-own-flags)   scenario_harness_keeps_its_own_flags ;;
        duplicate-registration-refused) scenario_duplicate_registration_refused ;;
        named-scenario-runs)           scenario_named_scenario_runs ;;
        every-harness-refuses)         scenario_every_harness_refuses ;;
    esac
    echo ""
done < <(scenario_selected)

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    printf '  - %s\n' "${failures[@]}"
    exit 1
fi
echo "ALL SCENARIO-SELECTOR TESTS PASSED"
exit 0
