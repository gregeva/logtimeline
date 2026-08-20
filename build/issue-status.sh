#!/usr/bin/env bash
# Issue lifecycle status: the single writer for the "status: *" label set.
#
# Status is tracked ONLY through these labels, and ONLY on open issues. Exactly
# one status label may be present at a time; this script is what makes that true.
# Closed issues carry no status label — their terminal state is native
# (closed as completed / closed as not planned).
#
# Blocking is a separate axis, tracked through GitHub's native blocked_by
# dependencies. This script neither reads nor reports it.
#
# Usage:
#   ./build/issue-status.sh set <issue> <status>   set status (swaps in one call)
#   ./build/issue-status.sh show <issue>           print one issue's status
#   ./build/issue-status.sh list                   list open issues with status
#   ./build/issue-status.sh sweep                  report and repair drift

set -euo pipefail

# The vocabulary. Order is the lifecycle order; "on hold" is the deliberate pause.
STATUSES=("backlog" "in progress" "in review" "on hold")

LABEL_PREFIX="status: "

die() { echo "[error] $*" >&2; exit 1; }

usage() {
    cat >&2 <<USAGE
Usage: ./build/issue-status.sh <command> [args]

  set <issue> <status>   Set an open issue's status. Valid: ${STATUSES[*]/#/}
                         Accepts the bare name ("in review") or the full label
                         ("status: in review").
  show <issue>           Print one issue's current status.
  list                   List open issues with their status.
  sweep                  Strip status labels from closed issues; report open
                         issues carrying none or more than one.
USAGE
    exit 1
}

# Single resolution surface for status operands: normalises whatever the caller
# typed into the canonical label name, or fails. Every command routes through
# this — the vocabulary is never restated elsewhere.
resolve_status_label() {
    local operand="$1" candidate
    operand="${operand#"$LABEL_PREFIX"}"
    operand="$(printf '%s' "$operand" | tr '[:upper:]' '[:lower:]')"
    for candidate in "${STATUSES[@]}"; do
        if [ "$operand" = "$candidate" ]; then
            printf '%s%s' "$LABEL_PREFIX" "$candidate"
            return 0
        fi
    done
    die "unknown status '$1' — valid statuses are: $(printf '%s, ' "${STATUSES[@]}" | sed 's/, $//')"
}

require_repo_root() {
    [ -f ltl ] && [ -d build ] || die "run from the repository root"
    command -v gh >/dev/null 2>&1 || die "gh CLI not found on PATH"
}

# Echoes the issue's status labels, one per line (empty output = none).
issue_status_labels() {
    gh issue view "$1" --json labels \
        --jq "[.labels[].name | select(startswith(\"$LABEL_PREFIX\"))] | .[]"
}

cmd_set() {
    [ $# -eq 2 ] || usage
    local issue="$1" label state current remove_args=() existing

    label="$(resolve_status_label "$2")"

    state="$(gh issue view "$issue" --json state --jq '.state')" \
        || die "issue #$issue not found"
    if [ "$state" != "OPEN" ]; then
        die "issue #$issue is $state — status is tracked on open issues only; its terminal state is the close reason"
    fi

    current="$(issue_status_labels "$issue")"
    if [ "$current" = "$label" ]; then
        echo "[ok] #$issue already '$label'"
        return 0
    fi

    # Every other status label is removed in the SAME call that adds the new one,
    # so the issue is never transiently statusless or double-statused.
    while IFS= read -r existing; do
        [ -n "$existing" ] || continue
        [ "$existing" = "$label" ] && continue
        remove_args+=(--remove-label "$existing")
    done <<< "$current"

    gh issue edit "$issue" --add-label "$label" "${remove_args[@]}" >/dev/null
    echo "[ok] #$issue -> '$label'${current:+ (was: $(printf '%s' "$current" | paste -sd, -))}"
}

cmd_show() {
    [ $# -eq 1 ] || usage
    local current
    current="$(issue_status_labels "$1")" || die "issue #$1 not found"
    if [ -z "$current" ]; then
        echo "#$1: (no status)"
    else
        printf '#%s: %s\n' "$1" "$(printf '%s' "$current" | paste -sd', ' -)"
    fi
}

cmd_list() {
    [ $# -eq 0 ] || usage
    gh issue list --state open --limit 200 --json number,title,labels \
        --jq "sort_by(.number) | reverse | .[]
              | [.number,
                 ([.labels[].name | select(startswith(\"$LABEL_PREFIX\")) | ltrimstr(\"$LABEL_PREFIX\")] | join(\",\") | if . == \"\" then \"(none)\" else . end),
                 (.title[0:64])]
              | @tsv" \
        | awk -F'\t' '{ printf "%-6s %-14s %s\n", "#"$1, $2, $3 }'
}

cmd_sweep() {
    [ $# -eq 0 ] || usage
    local stripped=0 missing=0 multiple=0 number labels label remove_args

    # Closed issues must carry no status label — strip whatever is there.
    while IFS=$'\t' read -r number labels; do
        [ -n "$number" ] || continue
        remove_args=()
        while IFS= read -r label; do
            [ -n "$label" ] || continue
            remove_args+=(--remove-label "$label")
        done <<< "$(printf '%s' "$labels" | tr ',' '\n')"
        gh issue edit "$number" "${remove_args[@]}" >/dev/null
        echo "[fixed] #$number closed — stripped: $labels"
        stripped=$((stripped + 1))
    done < <(gh issue list --state closed --limit 500 --json number,labels \
        --jq "[.[] | {number, s: [.labels[].name | select(startswith(\"$LABEL_PREFIX\"))]} | select(.s | length > 0)]
              | .[] | [.number, (.s | join(\",\"))] | @tsv")

    # Open issues must carry exactly one. Report, never guess.
    while IFS=$'\t' read -r number labels; do
        [ -n "$number" ] || continue
        if [ -z "$labels" ]; then
            echo "[warn] #$number open with no status — set one with: ./build/issue-status.sh set $number <status>"
            missing=$((missing + 1))
        else
            echo "[warn] #$number open with multiple statuses ($labels) — resolve with: ./build/issue-status.sh set $number <status>"
            multiple=$((multiple + 1))
        fi
    done < <(gh issue list --state open --limit 500 --json number,labels \
        --jq "[.[] | {number, s: [.labels[].name | select(startswith(\"$LABEL_PREFIX\"))]} | select(.s | length != 1)]
              | .[] | [.number, (.s | join(\",\"))] | @tsv")

    echo "[ok] sweep complete — $stripped closed issue(s) stripped, $missing open without status, $multiple open with multiple"
    [ "$missing" -eq 0 ] && [ "$multiple" -eq 0 ]
}

main() {
    [ $# -ge 1 ] || usage
    require_repo_root
    local command="$1"; shift
    case "$command" in
        set)   cmd_set   "$@" ;;
        show)  cmd_show  "$@" ;;
        list)  cmd_list  "$@" ;;
        sweep) cmd_sweep "$@" ;;
        *)     usage ;;
    esac
}

main "$@"
