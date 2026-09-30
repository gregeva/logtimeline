#!/usr/bin/env bash
# #616 drop 2: behaviour proof for the observation-count probes. Every probe
# runs every case; each case's STATS and MESSAGES CSVs, YAML export and
# terminal output (with the run's own timing and memory rows removed) are
# compared byte for byte with the reference probe's.
#
#   usage: prove.sh <probe dir> <out dir> <reference probe> <case>...
#     case: <label>=<options>@<absolute path to the log file>
#   env: CANDIDATES="cached full nocount oneref" (default)
set -euo pipefail
PROBES="$1"; OUT="$2"; REF="$3"; shift 3
CANDIDATES="${CANDIDATES:-cached full nocount oneref}"
mkdir -p "$OUT"
normalise() { sed -E 's/\x1b\[[0-9;]*m//g' | grep -vE 'TOTAL TIME|MAXIMUM MEMORY USED|max_memory_used|total_time|generated_at|^ *\[[^]]*\] [a-z_]+ +[0-9.]+ (kB|MB|B)' ; }
fails=0
for sel in "$@"; do
    label="${sel%%=*}"; rest="${sel#*=}"; opts="${rest%@*}"; file="${rest##*@}"
    for c in $CANDIDATES; do
        dir="$OUT/$label/$c"; rm -rf "$dir"; mkdir -p "$dir"
        # shellcheck disable=SC2086
        (cd "$dir" && "$PROBES/ltl-$c" --disable-progress -ni --terminal-width 200 $opts "$file" > stdout.raw 2> stderr.txt) \
            || { echo "FAIL $label $c: exit" >&2; fails=$((fails+1)); continue; }
        if grep -qE ' at .+ line [0-9]+' "$dir/stderr.txt"; then echo "FAIL $label $c: runtime warning" >&2; fails=$((fails+1)); fi
        normalise < "$dir/stdout.raw" > "$dir/stdout.txt"
        for kind in MESSAGES STATS AGGREGATE; do
            f=$(ls "$dir"/*-LTL-"$kind"* 2>/dev/null | head -1 || true)
            if [[ -n "$f" ]]; then normalise < "$f" > "$dir/$kind.out"; rm -f "$f"; fi
        done
    done
    for c in $CANDIDATES; do
        [[ "$c" == "$REF" ]] && continue
        for f in stdout.txt MESSAGES.out STATS.out AGGREGATE.out; do
            a="$OUT/$label/$REF/$f"; b="$OUT/$label/$c/$f"
            [[ -e "$a" || -e "$b" ]] || continue
            if ! cmp -s "$a" "$b"; then echo "DIFF $label $c $f" ; fails=$((fails+1)); fi
        done
    done
    echo "checked $label" >&2
done
echo "differences: $fails"
