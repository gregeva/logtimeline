#!/usr/bin/env bash
# run-dir.sh — one fresh directory per ltl run, for harnesses that find the
# products of a run by searching the directory it ran in
# (tests/HARNESS-DESIGN.md § A harness owns the directory it runs `ltl` in).
#
# A run directory named from a label is shared by any two runs whose labels
# name the same directory. On a case-insensitive file system (the macOS
# default) that includes labels differing only in case, such as
# dur-durationMS and dur-durationMs: the second run writes beside the first,
# and a search for "the MESSAGES CSV" may return the first run's file.
#
# Public function:
#   claim_run_dir DIR
#       Creates DIR, which must not exist yet; its parent is created as needed.
#       Returns 0 when DIR was created by this call. Prints a failure line
#       naming the directory to stdout and returns 1 when DIR already exists,
#       under this spelling or another the file system treats as the same.
#       The CALLER records the failure in its own accounting.
#
# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: run-dir.sh is a library; source it, do not execute it." >&2
    exit 2
fi

claim_run_dir() {
    local dir="$1"
    mkdir -p "$(dirname "$dir")"
    if ! mkdir "$dir" 2>/dev/null; then
        echo "  FAIL  run directory already exists: $dir"
        echo "        asserts:     each ltl run writes into a directory no other run has written into, so the products found there are its own"
        echo "        produced_by: the invoking harness (run label)"
        echo "        contract:    tests/HARNESS-DESIGN.md section A harness owns the directory it runs ltl in"
        return 1
    fi
    return 0
}
