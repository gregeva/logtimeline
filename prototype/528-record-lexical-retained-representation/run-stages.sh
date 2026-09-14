#!/usr/bin/env bash
# Run the #528 prototype (a transform that assigns arithmetic into a shared
# record lexical enlarges every duration the raw statistics model retains for
# the rest of the run) at every planned scale, both arms, five runs each.
#
# The staged ladder is
# features/528-record-lexical-retained-representation.md § The corpus:
#
#   5k     logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt
#   100k   a head of the 05-07 file, cut in the scratchpad
#   762k   logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt, whole
#
# The 22,264-line file is deliberately not used: it is the corrupt specimen
# (docs/test-logs.md), and its concatenated records make duration captures
# fragments of the following record.
#
# Each stage runs five timed runs per arm with NO instrumentation, then one
# probed run per arm as a separate third build whose figures are reported on
# their own. § The arms records why the two must not be mixed: instrumentation
# that reads a scalar's size is itself an allocation.
#
# Usage: run-stages.sh <output-directory> [runs]
set -euo pipefail
cd "$(dirname "$0")/../.."

OUT="${1:?usage: run-stages.sh <output-directory> [runs]}"
RUNS="${2:-5}"
mkdir -p "$OUT"

SITES="$OUT/sites.pl"
./prototype/528-record-lexical-retained-representation/extract-sites.sh "$SITES" > "$OUT/extract-sites.out"
export LTL528_SITES="$SITES"

PROTO=./prototype/528-record-lexical-retained-representation/retained-representation.pl

CORPUS_5K=logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt
CORPUS_762K=logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt
CORPUS_100K="$OUT/access-100k.txt"
# The fractional-millisecond specimen, a correctness-only arm per
# § The risk to check: fractional durations are where a retained value that
# becomes numeric could change a rendered spelling.
CORPUS_FRAC=logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt

if [[ ! -f "$CORPUS_100K" ]]; then
    head -100000 "$CORPUS_762K" > "$CORPUS_100K"
fi

stage () {
    local label="$1" file="$2" lines="$3"
    echo "### stage $label ($lines lines, $file)"
    for arm in baseline normalised; do
        for run in $(seq 1 "$RUNS"); do
            perl "$PROTO" --arm "$arm" --lines "$lines" --file "$file" \
                | sed "s/^/$label\t$arm\t$run\t/"
        done
    done
    # The probed third build, one run per arm.
    for arm in baseline normalised; do
        perl "$PROTO" --arm "$arm" --lines "$lines" --file "$file" --probe \
            | grep '^PROBE' | sed "s/^/$label\t$arm\tprobe\t/"
    done
}

{
    echo "# prototype 528, $(date -u +%Y-%m-%dT%H:%M:%SZ), $RUNS timed runs per arm per stage"
    echo "# perl: $(perl -e 'print $^V')"
    stage 5k    "$CORPUS_5K"    5000
    stage 100k  "$CORPUS_100K"  100000
    stage 762k  "$CORPUS_762K"  761698
} | tee "$OUT/stages.tsv"

# The correctness-only arm: full retained-value dumps on the fractional
# specimen, diffed between the arms. No timing is taken from it. The specimen
# writes the thread-session shape, so it binds the other access-family pattern.
echo "### correctness: fractional-millisecond specimen, 200000 lines"
for arm in baseline normalised; do
    perl "$PROTO" --arm "$arm" --shape access_common_duration_thread_session \
        --lines 200000 --file "$CORPUS_FRAC" \
        --emit-values "$OUT/values-frac-$arm.txt" > "$OUT/result-frac-$arm.txt"
done
# Its memory figures too, as a probed third build: the fractional shape is the
# one where the baseline's retained scalar carries a double as well.
for arm in baseline normalised; do
    perl "$PROTO" --arm "$arm" --shape access_common_duration_thread_session \
        --lines 200000 --file "$CORPUS_FRAC" --probe \
        | grep '^PROBE' | sed "s/^/frac\t$arm\tprobe\t/"
done | tee "$OUT/frac-probe.tsv"
# And on the integer specimen at full scale.
for arm in baseline normalised; do
    perl "$PROTO" --arm "$arm" --lines 761698 --file "$CORPUS_762K" \
        --emit-values "$OUT/values-762k-$arm.txt" > "$OUT/result-762k-$arm.txt"
done

for set in frac 762k; do
    if diff -q "$OUT/values-$set-baseline.txt" "$OUT/values-$set-normalised.txt" >/dev/null; then
        echo "CORRECTNESS	$set	identical	$(wc -l < "$OUT/values-$set-baseline.txt") retained-value lines"
    else
        echo "CORRECTNESS	$set	DIFFERS"
        diff "$OUT/values-$set-baseline.txt" "$OUT/values-$set-normalised.txt" | head -40
    fi
done | tee "$OUT/correctness.tsv"

echo "wrote $OUT/stages.tsv and $OUT/correctness.tsv"
