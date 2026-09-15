#!/usr/bin/env bash
# Stage 2. Whole runs of the variant ltl (make-ltl-variant.sh) on real logs, one
# at a time, per search strategy: rows after grouping, patterns, evictions, the
# patterns formed, parse / final-pass / total time and peak memory.
#   usage: run-e2e.sh <variant ltl> <logs dir> <output dir> <arm>...
#   arm: <search>[:<want>[:<budget>]], e.g. shipped incremental:1 hybrid:1:64
set -uo pipefail
bin="$1"; logs="$2"; out="$3"; shift 3
arms=("$@")
mkdir -p "$out"
DAY="$logs/AccessLogs/access.log_2026-05-19_00_00_00"
APP="$logs/ThingworxLogs/ApplicationLog.2025-05-05.0.log"
HUM="$logs/ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log"
SCRIPT="$logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.4.log"
TOMCAT="$logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt"
DL=(-i "/Windchill/servlet/WindchillGW&/doDirectDownload" -i "/Windchill/servlet/WindchillGW&/doIndirectDownload")

summary="$out/summary.tsv"
[[ -f "$summary" ]] || printf 'case\tarm\trc\twarnings\ttotal_s\tparse_s\tgroup_similar_s\trss_peak_mb\trows_after\tpatterns\tevicted\n' > "$summary"

run() {
    local case_name="$1"; shift
    local arm search want budget name
    for arm in "${arms[@]}"; do
        IFS=: read -r search want budget <<< "$arm"
        want="${want:-1}"; budget="${budget:-64}"
        name="$case_name--${arm//:/-}"
        echo "$(date +%H:%M:%S) $name" >> "$out/progress.txt"
        ( cd "$out" && LTL569_SEARCH="$search" LTL569_WANT="$want" LTL569_BUDGET="$budget" \
            "$bin" --disable-progress -ni "$@" -V > "$name.out" 2> "$name.err" )
        local rc=$?
        grep '^  cluster: ' "$out/$name.out" > "$out/$name.clusters"
        awk -F'\t' -v c="$case_name" -v a="$arm" -v rc="$rc" -v w="$(grep -c ' at .* line [0-9]' "$out/$name.err")" '
            $1=="TIMING" && $2=="total" {t=$3}
            $1=="TIMING" && $2=="parse/read_files" {p=$3}
            $1=="TIMING" && $2=="finalize/group_similar" {g=$3}
            $1=="MEMORY" && $2=="rss_peak" {m=$3/1048576}
            /^    Reduction: / {split($0, f, " "); rows+=f[4]}
            /^    Keys seen: .*checkpoints, [0-9]+ patterns\)/ {match($0, /[0-9]+ patterns\)/); pat+=substr($0, RSTART, RLENGTH)+0}
            /^    S6 Evicted: / {split($0, f, ":"); ev+=f[2]+0}
            END {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%.1f\t%d\t%d\t%d\n", c, a, rc, w, t, p, g, m, rows, pat, ev}
        ' "$out/$name.out" >> "$summary"
    done
}

for g in 50 70 75 80 85; do run "download-g$g" -du us "${DL[@]}" -xqs -bs 1440 -n 15 -g $g "$DAY"; done
for g in 65 80; do run "access-day-g$g" -du us -xqs -bs 1440 -n 15 -g $g "$DAY"; done
for g in 70 85 95; do run "application-g$g" -bs 1440 -n 15 -g $g "$APP"; done
run "unique-errors-g85" -bs 1440 -n 15 -g 85 "$HUM"
for g in 70 85; do run "script-g$g" -bs 1440 -n 15 -g $g "$SCRIPT"; done
for g in 70 85; do run "tomcat-g$g" -bs 1440 -n 15 -g $g "$TOMCAT"; done
echo "$(date +%H:%M:%S) ALL_DONE" >> "$out/progress.txt"
