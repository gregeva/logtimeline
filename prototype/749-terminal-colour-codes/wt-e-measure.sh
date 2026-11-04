#!/usr/bin/env bash
# wt-e-measure.sh <work-dir> <palette-dir> [scheme...]
#
# The Windows counterpart of e-measure.sh: D1 across Windows Terminal's
# colour schemes, for every run e-outputs.sh wrote into <palette-dir>. For
# each scheme (by default every one wt-measure.sh measured, in
# results/windows-terminal/schemes.txt) and each condition:
#
#   known    the background is known: the set for the scheme's background,
#            light or dark by ltl's rule (detect_terminal: BT.709 luma of the
#            background above one half), as schemes.txt classes it
#   unknown  the background is not known: the fallback, today's colours
#            (native ltl on Windows never asks the terminal)
#
# a Windows Terminal window of 190 columns by 51 rows prints the run's file
# a page at a time and is captured after each page (wt-e-capture.ps1,
# wt-e-show.sh), then closes. 51 rows is the most a window of 190 columns
# holds above the taskbar on a 1920 by 1080 display at 100% scale; ROWS=
# sets another. Every window is captured first, then read-output.py reads
# the pages, so the screen is free while the reading runs. Tables go to
# results/windows-terminal/e-prototype/<palette>/ with LF endings; the
# captures stay in <work-dir> and out of the repository.
#
# RUNS="<run> ..." and CONDITIONS="known" narrow a pass; CAPTURE=no reads
# the captures already in <work-dir> again without opening a window. Also
# writes tally.txt (tally.py). Windows, from Git Bash; windows open on screen
# for about a second per page, and the screen is captured as drawn, so
# nothing else should cover the top left corner.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
# Python reads and writes UTF-8, as ltl does, also where the locale does not (Windows: cp1252)
export PYTHONUTF8=1
here=$(cd "$(dirname "$0")" && pwd)
work=$(mkdir -p "$1" && cd "$1" && pwd)
lo=$(cd "$2" && pwd)
shift 2
classes=$here/results/windows-terminal/schemes.txt
names() { awk 'NR > 3 { n = substr($0, 1, 20); sub(/ +$/, "", n); print n }' "$classes"; }
class() { awk -v s="$1" 'NR > 3 { n = substr($0, 1, 20); sub(/ +$/, "", n); if (n == s) print $NF }' "$classes"; }
schemes=("$@")
[[ ${#schemes[@]} -gt 0 ]] || mapfile -t schemes < <(names)
runs=(${RUNS:-$(cd "$lo" && ls -d */ | tr -d /)})
results="$here/results/windows-terminal/e-prototype/$(basename "$lo")"
stamp=$(date +%H%M%S)
cols=190 rows=${ROWS:-51}
mkdir -p "$work/run" "$results"
capture() { powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$here/wt-e-capture.ps1" "$@" | tr -d '\r'; }

windows=()
for s in "${schemes[@]}"; do
    bg=$(class "$s")
    [[ -n $bg ]] || { echo "$s: not in $classes" >&2; exit 1; }
    for cond in ${CONDITIONS:-known unknown}; do
        if [[ $cond == known ]]; then palette=$bg; else palette=basic; fi
        for r in "${runs[@]}"; do
            tag="$r--${s// /-}--$cond"
            shots="$work/shots/$tag"
            windows+=("$s|$cond|$bg|$palette|$r")
            [[ ${CAPTURE:-yes} == no ]] && continue
            rm -rf "$shots"; mkdir -p "$shots"
            capture -Scheme "$s" -File "$(cygpath -m "$lo/$r/$palette.ans")" -Signal "$(cygpath -m "$work/run/$tag-$stamp")" \
                -OutDir "$(cygpath -m "$shots")" -Cols $cols -Rows $rows > "$shots/window.txt"
            echo "$tag: $(cat "$shots/window.txt")"
        done
    done
done
sizes=$(cut -d' ' -f1 "$work"/shots/*/window.txt | sort -u)
[[ $(wc -l <<< "$sizes") -eq 1 ]] || { echo "the windows differ in size: $sizes" >&2; exit 1; }

reads=()
for w in "${windows[@]}"; do
    IFS='|' read -r s cond bg palette r <<< "$w"
    tag="$r--${s// /-}--$cond"
    shots="$work/shots/$tag"
    base=$lo/$r/basic.ans
    [[ $palette == light ]] && base=$lo/$r/basic-light.ans
    python3 "$here/read-output.py" "$shots" "$lo/$r/$palette.ans" "$lo/$r/frame.json" "$rows" \
        "$s" "$cond" "$bg" "$palette" "$base" "$r" > "$shots/read.json"
    python3 "$here/read-output.py" --table "$shots/read.json" | tr -d '\r' > "$results/$tag.txt"
    reads+=("$tag/read.json")
done
# paths relative to the captures, so every window's stays inside Windows' command-line limit
cd "$work/shots"
python3 "$here/read-output.py" --summary "${reads[@]}" | tr -d '\r' > "$results/summary.txt"
python3 "$here/read-output.py" --compare "${reads[@]}" | tr -d '\r' > "$results/compare.txt"
python3 "$here/tally.py" "${reads[@]}" | tr -d '\r' > "$results/tally.txt"
echo "windows: $sizes; results: $results"
