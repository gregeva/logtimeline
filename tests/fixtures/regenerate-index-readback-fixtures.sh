#!/usr/bin/env bash
# regenerate-index-readback-fixtures.sh — Rebuild the index-read-back test
# fixtures from real log files in logs/.
#
# This script is the single source of truth for how the index-read-back
# fixtures are derived. Run it whenever:
#   - The underlying real log files in logs/ change
#   - The index-write schema in ltl changes such that the prebuilt
#     ltl-index.csv fixture becomes incompatible
#   - You need to refresh the fixtures for any other reason
#
# It is intentional that the fixtures (sample logs + prebuilt index CSV)
# are checked into git, so test runs do not need to rebuild them.
#
# Produces:
#   - logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt
#   - logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean-5k.log
#   - tests/fixtures/ltl-index-readback.csv
#
# The two sample logs are 5000-line slices taken from the middle of the
# corresponding production logs in logs/. The middle is chosen rather
# than head/tail to avoid systematic bias (e.g., warmup behavior, log
# rotation boundaries).
#
# The prebuilt ltl-index.csv contains one file row + one unfiltered
# selection row + one filtered selection row (-dmin=50) for each of the
# two sample logs. Scenarios in tests/validate-index-read-back.sh copy
# this file into their cwd and manipulate it (delete rows, edit bounds,
# corrupt the file, age entries) to drive specific read-back code paths.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LTL="$REPO_DIR/ltl"

# --- Source logs (production data in logs/) ---
TOMCAT_SOURCE="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt"
SCRIPT_SOURCE="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log"

# --- Sample-log targets ---
TOMCAT_SAMPLE="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"
SCRIPT_SAMPLE="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean-5k.log"

# --- Prebuilt index target ---
INDEX_FIXTURE="$SCRIPT_DIR/ltl-index-readback.csv"

# --- 1. Verify source logs exist ---
for f in "$TOMCAT_SOURCE" "$SCRIPT_SOURCE"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: source log missing: $f" >&2
        exit 1
    fi
done

# --- 2. Trim 5000-line samples from the middle of each source log ---
trim_middle() {
    local source="$1"
    local target="$2"
    local lines="$3"
    local total
    total=$(wc -l < "$source" | tr -d ' ')
    local start=$(( (total / 2) - (lines / 2) ))
    [[ $start -lt 1 ]] && start=1
    echo "  Trimming $lines lines from line $start of $(basename "$source")"
    sed -n "${start},$((start + lines - 1))p" "$source" > "$target"
    local got
    got=$(wc -l < "$target" | tr -d ' ')
    if [[ "$got" -ne "$lines" ]]; then
        echo "ERROR: expected $lines lines, got $got in $target" >&2
        exit 1
    fi
}

echo "Step 1: trim 5k samples from real logs"
trim_middle "$TOMCAT_SOURCE" "$TOMCAT_SAMPLE" 5000
trim_middle "$SCRIPT_SOURCE" "$SCRIPT_SAMPLE" 5000

# --- 3. Build the prebuilt ltl-index.csv ---
# Each ltl invocation contributes both a file row and a selection row.
# Running with no filter populates filters=- selection rows; running
# with -dmin=50 populates the corresponding filtered selection rows.
# Both invocations against both files merge into a single ltl-index.csv
# in the build directory.
echo "Step 2: build prebuilt ltl-index.csv against sample logs"
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

(
    cd "$BUILD_DIR"
    # Unfiltered runs for both files (writes file rows + filters=- selection rows)
    "$LTL" --disable-progress -osum -n 1 "$TOMCAT_SAMPLE" > /dev/null
    "$LTL" --disable-progress -osum -n 1 "$SCRIPT_SAMPLE" > /dev/null
    # Filtered runs for both files (writes filters=-dmin=50 selection rows)
    "$LTL" --disable-progress -osum -n 1 -dmin 50 "$TOMCAT_SAMPLE" > /dev/null
    "$LTL" --disable-progress -osum -n 1 -dmin 50 "$SCRIPT_SAMPLE" > /dev/null
)

if [[ ! -f "$BUILD_DIR/ltl-index.csv" ]]; then
    echo "ERROR: ltl did not produce ltl-index.csv in $BUILD_DIR" >&2
    exit 1
fi

cp "$BUILD_DIR/ltl-index.csv" "$INDEX_FIXTURE"
echo "  Wrote $INDEX_FIXTURE"

# --- 4. Sanity-check the fixture has the expected shape ---
file_rows=$(grep -c '^file,' "$INDEX_FIXTURE" || true)
selection_rows=$(grep -c '^selection,' "$INDEX_FIXTURE" || true)
if [[ "$file_rows" -lt 2 || "$selection_rows" -lt 4 ]]; then
    echo "ERROR: fixture has unexpected shape — file_rows=$file_rows selection_rows=$selection_rows" >&2
    echo "       expected at least 2 file rows and 4 selection rows" >&2
    exit 1
fi

echo ""
echo "Done. Fixtures written:"
echo "  $TOMCAT_SAMPLE"
echo "  $SCRIPT_SAMPLE"
echo "  $INDEX_FIXTURE  ($file_rows file rows, $selection_rows selection rows)"
