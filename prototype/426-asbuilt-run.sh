#!/bin/bash
#
# 426-asbuilt-run.sh — run 426-asbuilt-probe.pl inside a throwaway copy of
# ltl against a log file, on the store exactly as the production read loop
# built it. The probe is injected before the `calculate_all_statistics();`
# call (the #415 bisect technique); the copy is deleted afterwards.
#
# Usage: ./prototype/426-asbuilt-run.sh <ltl> <logfile> <out-file> [extra ltl args]
#   default ltl args: --disable-progress -ni --terminal-width 200 -so p99
#                     -V benchmark-data -mem
# The out-file receives the probe's `### 426` rows plus ltl's TIMING/MEMORY/
# COUNTS rows for the same process (cross-validation of the denominator).

set -euo pipefail
LTL="$1"; LOG="$2"; OUTF="$3"; shift 3
HERE="$(cd "$(dirname "$0")" && pwd)"
PROBE="$HERE/426-asbuilt-probe.pl"
TMP="$(mktemp -t ltl-426-asbuilt.XXXXXX)"
cp "$LTL" "$TMP"
perl -pi -e 'BEGIN { open my $h, "<", shift or die; local $/; $inj = <$h> } if (!$done && /^\s*calculate_all_statistics\(\);/) { print $inj; $done = 1 }' "$PROBE" "$TMP"
grep -q '### 426' "$TMP" || { echo "INJECT-FAIL: calculate_all_statistics(); call site not found" >&2; rm -f "$TMP"; exit 2; }
/opt/homebrew/bin/perl "$TMP" --disable-progress -ni --terminal-width 200 -so p99 -V benchmark-data -mem "$@" "$LOG" \
  2>&1 | grep -aE '^### 426|TIMING.*calculate_statistics|MEMORY.*log_messages|COUNTS.*log_messages|at .* line [0-9]+' > "$OUTF" || true
rm -f "$TMP"
cat "$OUTF"
