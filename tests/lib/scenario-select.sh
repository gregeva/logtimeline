#!/usr/bin/env bash
# scenario-select.sh — shared scenario selector for test harnesses
# (tests/HARNESS-DESIGN.md § The scenario selector, issue #545).
#
# A harness given a scenario name it does not know, or a flag it does not
# parse, must say so and run nothing. The failure this prevents is not a wrong
# assertion but a misread run: a harness that ignores the selector reports its
# full assertion set as the single scenario the operator believes they asked
# for, and a harness that accepts an unknown name and matches nothing reports
# `0 passed, 0 failed` as a pass. Both were observed across the suite before
# this library existed (#545).
#
# Every harness names its units of work "scenarios" and stores the running one
# in `current_scenario`. The word is uniform across the suite so that a
# selector token means the same thing in every harness.
#
# Public interface:
#
#   scenario_register NAME [NAME...]
#       Declare scenarios, in run order. Call before scenario_parse_args.
#       Registering the same name twice is a harness defect and exits 2.
#
#   scenario_parse_args "$@"
#       Parse the harness command line. Handles --scenario NAME, --list,
#       -h/--help; rejects an unknown flag and an unknown scenario name with a
#       diagnostic and exit 2, before any assertion runs. A harness with its
#       own extra flags passes a handler via SCENARIO_EXTRA_ARG_HANDLER (see
#       below) rather than parsing around this function.
#
#   scenario_selected
#       Echoes the scenarios to run, in registration order: every registered
#       scenario, or just the selected one.
#
#   scenario_wanted NAME
#       True when NAME should run. For harnesses that gate blocks inline
#       rather than dispatching from a list.
#
#   scenario_usage
#       Prints usage and the registered scenario names.
#
# Optional hooks, set by the harness before scenario_parse_args:
#   SCENARIO_USAGE_NOTE   one line printed under the scenario list (e.g. the
#                         contract the scenario names come from)
#   SCENARIO_EXTRA_ARG_HANDLER
#                         name of a function called with the remaining
#                         arguments when an argument is not one this library
#                         knows. It sets SCENARIO_ARGS_CONSUMED to the number
#                         of arguments it claimed (0 means "not mine", and the
#                         argument is then an error). This keeps unknown-flag
#                         rejection in one place while a harness keeps its own
#                         options. The handler is called in the current shell,
#                         not a subshell, so the flags it sets are visible to
#                         the harness; it reports through a variable rather
#                         than stdout for exactly that reason.
#
# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: scenario-select.sh is a library; source it, do not execute it." >&2
    exit 2
fi

# shellcheck source=require-bash.sh
source "$(dirname "${BASH_SOURCE[0]}")/require-bash.sh"

SCENARIO_REGISTRY=()
SCENARIO_ONLY=""
SCENARIO_USAGE_NOTE="${SCENARIO_USAGE_NOTE:-}"
SCENARIO_EXTRA_ARG_HANDLER="${SCENARIO_EXTRA_ARG_HANDLER:-}"
SCENARIO_ARGS_CONSUMED=0

scenario_register() {
    local name existing
    for name in "$@"; do
        for existing in ${SCENARIO_REGISTRY[@]+"${SCENARIO_REGISTRY[@]}"}; do
            if [[ "$existing" == "$name" ]]; then
                echo "ERROR: scenario '$name' registered twice in $(basename "$0")" >&2
                exit 2
            fi
        done
        SCENARIO_REGISTRY+=("$name")
    done
}

scenario_usage() {
    echo "Usage: $0 [--scenario NAME] [--list]"
    if [[ ${#SCENARIO_REGISTRY[@]} -eq 0 ]]; then
        echo "  (this harness registers no scenarios)"
        return 0
    fi
    echo "Scenarios:"
    printf '  %s\n' "${SCENARIO_REGISTRY[@]}"
    [[ -n "$SCENARIO_USAGE_NOTE" ]] && printf '%b\n' "$SCENARIO_USAGE_NOTE"
    return 0
}

scenario_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --scenario)
                if [[ $# -lt 2 || -z "${2:-}" ]]; then
                    echo "ERROR: --scenario needs a scenario name" >&2
                    scenario_usage >&2
                    exit 2
                fi
                SCENARIO_ONLY="$2"
                shift 2
                ;;
            --scenario=*)
                SCENARIO_ONLY="${1#--scenario=}"
                if [[ -z "$SCENARIO_ONLY" ]]; then
                    echo "ERROR: --scenario needs a scenario name" >&2
                    scenario_usage >&2
                    exit 2
                fi
                shift
                ;;
            --list)
                scenario_usage
                exit 0
                ;;
            -h|--help)
                scenario_usage
                exit 0
                ;;
            *)
                if [[ -n "$SCENARIO_EXTRA_ARG_HANDLER" ]]; then
                    SCENARIO_ARGS_CONSUMED=0
                    "$SCENARIO_EXTRA_ARG_HANDLER" "$@"
                    if [[ "$SCENARIO_ARGS_CONSUMED" =~ ^[1-9][0-9]*$ ]]; then
                        shift "$SCENARIO_ARGS_CONSUMED"
                        continue
                    fi
                fi
                echo "ERROR: unknown argument '$1'" >&2
                scenario_usage >&2
                exit 2
                ;;
        esac
    done

    # An unknown scenario name matches nothing, so it must be refused here:
    # letting it through means every gate evaluates false and the harness
    # reports a full pass over zero assertions (#545).
    if [[ -n "$SCENARIO_ONLY" ]]; then
        local s found=0
        for s in ${SCENARIO_REGISTRY[@]+"${SCENARIO_REGISTRY[@]}"}; do
            [[ "$s" == "$SCENARIO_ONLY" ]] && found=1 && break
        done
        if [[ "$found" -ne 1 ]]; then
            echo "ERROR: unknown scenario '$SCENARIO_ONLY'" >&2
            scenario_usage >&2
            exit 2
        fi
    fi
    return 0
}

scenario_selected() {
    if [[ -n "$SCENARIO_ONLY" ]]; then
        echo "$SCENARIO_ONLY"
    else
        printf '%s\n' ${SCENARIO_REGISTRY[@]+"${SCENARIO_REGISTRY[@]}"}
    fi
}

scenario_wanted() {
    [[ -z "$SCENARIO_ONLY" || "$SCENARIO_ONLY" == "$1" ]]
}
