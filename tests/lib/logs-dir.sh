#!/usr/bin/env bash
# logs-dir.sh — resolve the log corpus every harness reads from.
#
# The corpus is logs/ under the repo root unless LTL_LOGS_DIR names another
# one. Harnesses hardcoding the repo-root path cannot run at all from a
# checkout that has no corpus of its own — a second clone, or a git
# worktree, where logs/ is gitignored and exists only in the original
# checkout. The override points such a checkout at the real logs (#436).
#
# One resolution surface: every harness sources this and reads $LOGS_DIR
# rather than composing "$REPO_DIR/logs" itself, so the corpus location is
# defined once and an override cannot reach some harnesses but not others.
#
# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: logs-dir.sh is a library; source it, do not execute it." >&2
    exit 2
fi

_LOGS_DIR_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LOGS_DIR_REPO_DIR="$(cd "$_LOGS_DIR_LIB_DIR/../.." && pwd)"

if [[ -n "${LTL_LOGS_DIR:-}" ]]; then
    if [[ ! -d "$LTL_LOGS_DIR" ]]; then
        echo "ERROR: LTL_LOGS_DIR is not a directory: $LTL_LOGS_DIR" >&2
        exit 1
    fi
    LOGS_DIR="$(cd "$LTL_LOGS_DIR" && pwd)"
else
    LOGS_DIR="$_LOGS_DIR_REPO_DIR/logs"
fi

# resolve_log_path PATH
#   Echoes the absolute location of a logfile named the way scenario tables
#   and harness variables name them. An absolute path is returned unchanged;
#   a logs/-prefixed path resolves against the corpus, so LTL_LOGS_DIR
#   redirects it; any other relative path stays repo-relative.
#
#   One resolution surface: callers must not re-implement this test, or an
#   override reaches some of them and not others — which shows up as a
#   harness that still passes while silently skipping the work it gates
#   (the L3 oracle skipped every scenario when only one of two copies of
#   this logic had been updated).
resolve_log_path() {
    local logfile="$1"
    case "$logfile" in
        /*)      printf '%s' "$logfile" ;;
        logs/*)  printf '%s' "$LOGS_DIR/${logfile#logs/}" ;;
        *)       printf '%s' "$_LOGS_DIR_REPO_DIR/$logfile" ;;
    esac
}
