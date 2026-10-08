#!/usr/bin/env bash
#
# wholerun.sh - whole-run comparisons of features/615-csv-registry-entry.md
# § 8: ltl (arm A) against the patched copy written by patch-ltl.pl (arm B).
#
#   parity  every correctness fixture run -bs 1 -o -V by both, in its own
#           directory: every file the run writes (the -o files, and
#           ltl-index.csv where -ni is not given) and the -V filter-summary
#           and format-detection sections are compared.
#   timing  TIMING parse/read_files of -V benchmark-data at 1M rows per
#           family and density, and on the corpus's network-latency CSV,
#           both arms alternating, RUNS runs each.
#
# Usage: wholerun.sh parity FIXTURE_DIR WORK_DIR > parity-wholerun.tsv
#        wholerun.sh timing FIXTURE_DIR WORK_DIR [RUNS] > timing-wholerun.tsv
#
# LTL_A and LTL_B name other arms: at delivery, the base commit's ltl and the
# branch's, with no patched copy written.

set -u
MODE="${1:?parity|timing}"
FIX="$(cd "${2:?fixture directory}" && pwd)"
WORK="${3:?work directory}"
RUNS="${4:-5}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
mkdir -p "$WORK"
LTL_A="${LTL_A:-$REPO/ltl}"
if [[ -z ${LTL_B:-} ]]; then
    LTL_B="$WORK/ltl-615b"
    perl "$HERE/patch-ltl.pl" "$LTL_B" 2>/dev/null || { echo "patch failed" >&2; exit 1; }
fi

section() {   # name file -> the section's body
    awk -v n="$1" '$0 == "=== " n " ===" {on=1; next} $0 == "=== END " n " ===" {on=0} on' "$2"
}

if [[ $MODE == parity ]]; then
    printf 'fixture\toptions\tSTATS\tMESSAGES\tAGGREGATE\tindex\tfilter_summary\tformat_detection\n'
    norm() {   # kind file -> the file with what varies between two runs of the same input removed
        case "$1" in
            AGGREGATE) grep -v -E '^\s*(total_time|max_memory_used|generated_at):' "$2" ;;
            index)     awk -F, -v OFS=, '{ $2 = ""; $23 = ""; $24 = ""; $25 = ""; print }' "$2" ;;
            *)         cat "$2" ;;
        esac
    }
    while IFS='|' read -r f opts; do
        [[ -z $f ]] && continue
        for arm in A B; do
            d="$WORK/run-$arm"; rm -rf "$d"; mkdir -p "$d"
            ltl="$LTL_A"; [[ $arm == B ]] && ltl="$LTL_B"
            # shellcheck disable=SC2086
            ( cd "$d" && "$ltl" --disable-progress -bs 1 -o -V $opts "$FIX/$f" > stdout.txt 2> stderr.txt )
        done
        res=()
        for k in STATS MESSAGES AGGREGATE index; do
            pat="*-LTL-$k*"; [[ $k == index ]] && pat='ltl-index.csv'
            a=$(ls "$WORK"/run-A/$pat 2>/dev/null | head -1); b=$(ls "$WORK"/run-B/$pat 2>/dev/null | head -1)
            if [[ -z $a && -z $b ]]; then res+=( "-" ); continue; fi
            [[ -z $a || -z $b ]] && { res+=( "missing" ); continue; }
            n=$(diff <(norm $k "$a") <(norm $k "$b") | grep -c '^<')
            if (( n == 0 )); then res+=( same ); else
                res+=( "$n lines" )
                { echo "== $f $opts :: $k"; diff <(norm $k "$a") <(norm $k "$b") | head -6; } >&2
            fi
        done
        fs=same; section filter-summary "$WORK/run-A/stdout.txt" > "$WORK/fsA"; section filter-summary "$WORK/run-B/stdout.txt" > "$WORK/fsB"
        cmp -s "$WORK/fsA" "$WORK/fsB" || fs=differs
        fd=same; section format-detection "$WORK/run-A/stdout.txt" | grep -v -i -E 'elapsed|_us|_ms|time' > "$WORK/fdA"
        section format-detection "$WORK/run-B/stdout.txt" | grep -v -i -E 'elapsed|_us|_ms|time' > "$WORK/fdB"
        cmp -s "$WORK/fdA" "$WORK/fdB" || fd=differs
        [[ -s $WORK/fsA ]] || fs=missing
        [[ -s $WORK/fdA ]] || fd=missing
        grep -l -E ' at [^ ]+ line [0-9]+' "$WORK"/run-*/stderr.txt >&2 && fs="$fs+warnings"
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$f" "$opts" "${res[@]}" "$fs" "$fd"
    done <<'CASES'
c-iso-nofrac.csv|-udm cpu_total -ni
c-iso-frac3.csv|-udm cpu_user -udm cpu_total -udm conn_active -ni
c-iso-frac6.csv|-udm cpu_total -ni
c-iso-frac9.csv|-udm cpu_total -ni
c-iso-T.csv|-udm cpu_total -ni
c-epoch-whole.csv|-udm latency_ms -ni
c-epoch-frac6.csv|-udm latency_ms -udm request_size -udm response_size -ni
c-epoch-frac9.csv|-udm latency_ms -ni
c-epoch-ms.csv|-udm latency_ms -du ms -ni
c-iso-badrows.csv|-udm cpu_user -udm cpu_total -udm conn_active -udm cpu_total::delta -ni
c-epoch-badrows.csv|-udm latency_ms -udm latency_ms::delta -ni
c-iso-frac3.csv|-udm cpu_total -udm no_such_column -ni
c-iso-semicolon.csv|-udm cpu_total -ucm namespace -ni
c-iso-frac9.csv|-udm cpu_total -tp ns -ni
c-epoch-frac9.csv|-udm latency_ms -tp ns -ni
c-epoch-frac6.csv|-udm latency_ms -tp ns -ni
c-iso-frac3.csv|-udm cpu_total
c-epoch-frac6.csv|-udm latency_ms
c-iso-frac9.csv|-udm cpu_total -tp ns
CASES
    exit 0
fi

if [[ $MODE == timing ]]; then
    printf 'fixture\tarm\trun\tparse_read_files_s\n'
    LATENCY="$REPO/logs/UDM/results_data_idonly-timestampMs.csv"
    cases=( "$FIX/perf-epoch-one-1m.csv|-udm latency_ms"
            "$FIX/perf-epoch-several-1m.csv|-udm latency_ms"
            "$FIX/perf-iso-one-1m.csv|-udm cpu_total"
            "$FIX/perf-iso-several-1m.csv|-udm cpu_total" )
    [[ -f $LATENCY ]] && cases+=( "$LATENCY|-udm latency_ms" )
    for c in "${cases[@]}"; do
        f="${c%%|*}"; opts="${c#*|}"
        for ((r = 1; r <= RUNS; r++)); do
            order=(A B); (( r % 2 == 0 )) && order=(B A)
            for arm in "${order[@]}"; do
                ltl="$LTL_A"; [[ $arm == B ]] && ltl="$LTL_B"
                # shellcheck disable=SC2086
                t=$("$ltl" --disable-progress $opts -bs 1440 -oe -n 1 -ni -V "$f" 2>/dev/null \
                    | awk -F'\t' '$1 == "TIMING" && $2 == "parse/read_files" {print $3}')
                printf '%s\t%s\t%s\t%s\n' "$(basename "$f")" "$arm" "$r" "${t:-missing}"
            done
        done
    done
    exit 0
fi
echo "unknown mode $MODE" >&2; exit 1
