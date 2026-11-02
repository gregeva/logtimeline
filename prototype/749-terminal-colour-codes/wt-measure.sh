#!/usr/bin/env bash
# wt-measure.sh <work-dir> [<ltl-output-dir>]
#
# The Windows counterpart of measure.sh: draws the measurement pattern in
# Windows Terminal on Campbell (its default dark scheme) and One Half Light,
# reads each capture, and writes the tables to results/windows-terminal/
# beside this script. With <ltl-output-dir> holding the .ans files
# ltl-outputs.sh writes (ltl's output as written and as rewritten to fixed
# codes), also draws each on both schemes into <work-dir>/shots, for looking
# at; the captures stay out of the repository.
#
# Windows, from Git Bash. The pattern is drawn in a 102 by 34 window; ltl's
# output full screen, which holds its 55 lines on a 1080-pixel display where
# a 58-row window does not fit. Windows open on screen for about three
# seconds each. The tables are written with LF endings, as on macOS.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
work=$(mkdir -p "$1" && cd "$1" && pwd)
ltl_out=${2:-}
results="$here/results/windows-terminal"
mkdir -p "$work/pattern" "$results"

schemes=("Campbell" "One Half Light")
capture() { powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$here/wt-capture.ps1" "$@"; }

cd "$work"
python3 "$here/pattern.py"
analyses=()
for s in "${schemes[@]}"; do
    f="$work/pattern/${s// /-}"
    capture -Scheme "$s" -File "$work/pattern.ans" -Out "$f.png" -Cols 102 -Rows 34
    python3 "$here/analyse.py" "$f.png" "$work/pattern.json" "$f.json"
    python3 "$here/report.py" "$f.json" | tr -d '\r' > "$results/profile-${s// /-}.txt"
    analyses+=("$f.json")
done
python3 "$here/summary.py" "${analyses[@]}" | tr -d '\r' > "$results/summary.txt"
python3 "$here/fixed-contrast.py" "${analyses[@]}" | tr -d '\r' > "$results/fixed-contrast.txt"

if [[ -n "$ltl_out" ]]; then
    mkdir -p "$work/shots"
    for s in "${schemes[@]}"; do
        for f in "$ltl_out"/*.ans; do
            capture -Scheme "$s" -File "$f" -Out "$work/shots/${s// /-}--$(basename "${f%.ans}").png" -Fullscreen >/dev/null
        done
    done
fi
echo "results: $results"
