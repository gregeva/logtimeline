#!/usr/bin/env bash
# fixtures.sh — shared derived-fixture helpers for test harnesses.
#
# Harnesses that need a clean, representative Tomcat access-log fixture
# derive it deterministically from the full-day corpus file instead of
# keeping a near-duplicate slice on disk. One derivation surface: every
# consumer (capture + validate) calls the same function, so the fixture
# a reference file was captured against is byte-identical to the fixture
# the validator replays.
#
# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: fixtures.sh is a library; source it, do not execute it." >&2
    exit 2
fi

_FIXTURES_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_FIXTURES_REPO_DIR="$(cd "$_FIXTURES_LIB_DIR/../.." && pwd)"

# derive_sampled_access_log DEST
#   Writes the deterministic sampled Tomcat 9 access-log fixture to DEST:
#   every 30th line of the full-day 2025-05-07 corpus file (~25k lines,
#   00:00:00 → 14:27 coverage, bytes + %D millisecond duration on every
#   line — including the 00:00–00:05 window the -ms regression scenario
#   filters to). The corpus file is clean (no corrupt/concatenated lines).
#   Hard-fails if the corpus file is missing or the derivation is empty.
derive_sampled_access_log() {
    local dest="$1"
    local src="$_FIXTURES_REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt"
    if [[ ! -f "$src" ]]; then
        echo "ERROR: fixture corpus file missing: $src" >&2
        return 1
    fi
    awk 'NR % 30 == 1' "$src" > "$dest"
    if [[ ! -s "$dest" ]]; then
        echo "ERROR: derived access-log fixture is empty: $dest (from $src)" >&2
        return 1
    fi
    return 0
}
