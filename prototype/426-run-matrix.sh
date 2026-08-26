#!/bin/bash
#
# 426-run-matrix.sh — run 426-store-mini.pl over an arms × fixtures matrix,
# one process per cell (fresh heap per arm), collect the TSV rows, and
# assert parity across arms per fixture from the PARITY digests.
#
# Usage:
#   ./prototype/426-run-matrix.sh <out-dir> <runs> "<arms>" <fixture> [...]
#   e.g. ./prototype/426-run-matrix.sh /tmp/ltl-426-results 5 "A B C D" \
#            /tmp/ltl-426-fixtures/twx-unique-100k.log
#
# Output: <out-dir>/results.tsv (appended), <out-dir>/parity.txt (appended),
# <out-dir>/log/<fixture>-<arm>.err (per-cell stderr). Exit 1 on any parity
# divergence.

set -uo pipefail

OUT="$1"; RUNS="$2"; ARMS="$3"; shift 3
# MINI=<script> selects the mini (default: the raw-mode 426-store-mini.pl;
# 426-bin-store-mini.pl for the -mdm bin arms K1..K4).
MINI="${MINI:-$(cd "$(dirname "$0")" && pwd)/426-store-mini.pl}"
mkdir -p "$OUT/log"
RESULTS="$OUT/results.tsv"
PARITY="$OUT/parity.txt"
[ -s "$RESULTS" ] || printf 'candidate\tfixture\tlines\tmetric\tmedian\tmin\tmax\n' > "$RESULTS"

status=0
for fixture in "$@"; do
  base=$(basename "$fixture" .log)
  for arm in $ARMS; do
    echo "== $base arm $arm" >&2
    if ! perl "$MINI" --arm "$arm" --runs "$RUNS" --no-header "$fixture" \
         >> "$RESULTS" 2> "$OUT/log/$base-$arm.err"; then
      echo "   FAILED (see $OUT/log/$base-$arm.err)" >&2
      status=1
      continue
    fi
    grep -a '^PARITY' "$OUT/log/$base-$arm.err" >> "$PARITY"
    grep -av '^PARITY' "$OUT/log/$base-$arm.err" | sed 's/^/   stderr: /' >&2
  done
  # Parity: every arm must agree on every digest field for this fixture.
  for field in store avail fill churn churn_fill; do
    n=$(grep -a "^PARITY	$base.log	" "$PARITY" | grep -aoE "(^|[[:space:]])$field=[0-9a-f]+" | sed 's/^[[:space:]]//' | sort -u | wc -l | tr -d ' ')
    if [ "$n" -gt 1 ]; then
      echo "   PARITY FAILURE on $field for $base:" >&2
      grep -a "^PARITY	$base.log	" "$PARITY" | grep -aE "(^|[[:space:]])$field=" >&2
      status=1
    fi
  done
done
exit $status
