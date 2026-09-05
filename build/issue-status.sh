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
#   ./build/issue-status.sh sweep                  integrity check + advisory proposals

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
  sweep                  Integrity + advisory pass. Strips status from closed issues,
                         reports open issues carrying several, and proposes a status
                         (with reasoning) where one is missing or looks understated.
                         Proposals are printed, never applied.
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
    local issue="$1" label state current existing
    local -a remove_args=()

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

    gh issue edit "$issue" --add-label "$label" ${remove_args[@]+"${remove_args[@]}"} >/dev/null
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
    local stripped=0 multiple=0 proposed=0 number labels label
    local -a remove_args

    # --- Integrity: closed issues carry no status. One correct answer, so fix it. ---
    while IFS=$'\t' read -r number labels; do
        [ -n "$number" ] || continue
        remove_args=()
        while IFS= read -r label; do
            [ -n "$label" ] || continue
            remove_args+=(--remove-label "$label")
        done <<< "$(printf '%s' "$labels" | tr ',' '\n')"
        gh issue edit "$number" ${remove_args[@]+"${remove_args[@]}"} >/dev/null
        echo "[fixed] #$number closed — stripped: $labels"
        stripped=$((stripped + 1))
    done < <(gh issue list --state closed --limit 500 --json number,labels \
        --jq "[.[] | {number, s: [.labels[].name | select(startswith(\"$LABEL_PREFIX\"))]} | select(.s | length > 0)]
              | .[] | [.number, (.s | join(\",\"))] | @tsv")

    # --- Integrity: exactly one status per open issue. Which one is a judgement call. ---
    while IFS=$'\t' read -r number labels; do
        [ -n "$number" ] || continue
        echo "[conflict] #$number carries several statuses ($labels) — pick one:"
        echo "           ./build/issue-status.sh set $number <status>"
        multiple=$((multiple + 1))
    done < <(gh issue list --state open --limit 500 --json number,labels \
        --jq "[.[] | {number, s: [.labels[].name | select(startswith(\"$LABEL_PREFIX\"))]} | select(.s | length > 1)]
              | .[] | [.number, (.s | join(\",\"))] | @tsv")

    # --- Advisory: propose, never apply. ---
    #
    # Status is a deliberate decision. These signals cannot see the decisions that
    # live in comments, closed PRs and feature docs, so they never overrule a
    # recorded status — they only speak where the state is absent or is the weakest
    # one (`backlog`), and where a mechanical signal says otherwise. `on hold` and
    # `in progress` are left alone: both record a judgement no signal can second-guess.
    local branches prs current proposal reason
    branches="$(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)"
    prs="$(gh pr list --state open --limit 200 --json number,headRefName,body \
           --jq '.[] | [.number, .headRefName, (.body // "" | gsub("\n"; " "))] | @tsv' 2>/dev/null)"

    while IFS=$'\t' read -r number current; do
        [ -n "$number" ] || continue
        # Only the absent and the weakest state invite a proposal. Every other
        # status records a judgement no mechanical signal can second-guess.
        case "$current" in
            ""|backlog) ;;
            *) continue ;;
        esac

        proposal=""; reason=""

        # An open PR for the issue is unambiguous and outranks the rest.
        local pr_num
        pr_num="$(printf '%s\n' "$prs" | awk -F'\t' -v n="$number" \
            '$2 ~ "^"n"-" || tolower($3) ~ ("(close[sd]?|fix(e[sd])?|resolve[sd]?)[ ]*#"n"([^0-9]|$)") { print $1; exit }')"
        if [ -n "$pr_num" ]; then
            proposal="in review"
            reason="PR #$pr_num is open for this issue"
        fi

        # A live branch means work is underway now.
        if [ -z "$proposal" ]; then
            local branch
            branch="$(printf '%s\n' "$branches" | grep -E "^${number}-" | head -1 || true)"
            if [ -n "$branch" ]; then
                proposal="in progress"
                reason="branch '$branch' exists — work is underway"
            fi
        fi

        # Blocking is NOT a status signal. docs/process/issues.md § Issue status: "Status is
        # orthogonal to blocking. An issue can be `blocked_by` an open issue AND
        # be `in progress` at the same time." An open dependency therefore says
        # nothing about which status an issue should carry, and `on hold` in
        # particular records "deliberately paused by an explicit decision" — a
        # judgement no mechanical signal can make. No proposal is derived from a
        # dependency edge.

        # Nothing else to go on.
        if [ -z "$proposal" ] && [ -z "$current" ]; then
            proposal="backlog"
            reason="no branch and no open PR — nothing indicates work has started"
        fi

        if [ -n "$proposal" ]; then
            echo "[propose] #$number  ${current:-(no status)} -> $proposal"
            echo "          why:   $reason"
            echo "          apply: ./build/issue-status.sh set $number \"$proposal\""
            proposed=$((proposed + 1))
        fi
    done < <(gh issue list --state open --limit 500 --json number,labels \
        --jq "[.[] | {number, s: [.labels[].name | select(startswith(\"$LABEL_PREFIX\")) | ltrimstr(\"$LABEL_PREFIX\")]} | select(.s | length <= 1)]
              | .[] | [.number, (.s | join(\"\"))] | @tsv")

    echo "[ok] sweep complete — $stripped closed stripped, $multiple conflicting, $proposed proposal(s) for review"
    echo "     Proposals are advisory. Status is a deliberate decision; nothing above was applied."
    [ "$multiple" -eq 0 ]
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
