#!/bin/sh
# Driver for prototype/426-revalidate-v5.pl — one process per bpd level, each
# capture to prototype/426-results/revalidate-v5-bpd<NN>.txt with the TSVs
# alongside. Parity (T<->S digest) is asserted in the bpd 53 process.
#
#   sh prototype/426-revalidate-v5-run.sh [file] [bpd list...]
#   sh prototype/426-revalidate-v5-run.sh logs/AccessLogs/localhost_access_log.2025-03-21.txt 53   # smoke
#
set -u
cd "$(dirname "$0")/.." || exit 1
FILE="${1:-logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt}"
shift 2>/dev/null
OUT=prototype/426-results
PREFIX="${PREFIX:-$OUT/revalidate-v5}"
if [ $# -eq 0 ]; then set -- 53 115 256 616; fi
rm -f "$PREFIX-summary.tsv"
rc=0
for bpd in "$@"; do
    echo "--- bpd=$bpd -> $PREFIX-bpd$bpd.txt"
    perl prototype/426-revalidate-v5.pl --file "$FILE" --bpd "$bpd" --parity-bpd 53 --tsv-prefix "$PREFIX" > "$PREFIX-bpd$bpd.txt" 2>&1
    r=$?
    echo "exit=$r"
    [ $r -ne 0 ] && rc=$r
done
exit $rc
