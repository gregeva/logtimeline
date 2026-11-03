#!/usr/bin/env bash
# e-measure.sh <work-dir> <palette-dir> [profile...]
#
# D1 across terminal configurations. For each Terminal.app profile (every
# shipped one but Solid Colors, whose background changes with each window, by
# default) two windows, one per condition:
#
#   known    the background is known: the set for the profile's background,
#            light or dark by ltl's rule (detect_terminal: BT.709 luma of the
#            background above one half), from the background measured in
#            results/terminal-app/
#   unknown  the background is not known: the fallback, today's basic colours
#
# Each window is 190 by 59, shows the palette's file from <palette-dir>
# (written by e-outputs.sh) as a terminal shows ltl's output, is captured at
# both ends and closed. read-output.py reads both captures. Tables go to
# results/e-prototype/<palette>/; the captures stay in <work-dir> and out of
# the repository (window titles carry the user's name).
#
# CONDITIONS="known" renders only the known-background windows (the fallback
# is the same for every palette). macOS only; Terminal needs Screen Recording
# permission for screencapture.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
here=$(cd "$(dirname "$0")" && pwd)
work=$(mkdir -p "$1" && cd "$1" && pwd)
lo=$(cd "$2" && pwd)
shift 2
profiles=("$@")
[[ ${#profiles[@]} -gt 0 ]] || profiles=("Clear Dark" "Clear Light" "Basic" "Pro" "Homebrew" "Man Page" "Novel" "Silver Aerogel" "Grass" "Ocean" "Red Sands")
results="$here/results/e-prototype/$(basename "$lo")"
stamp=$(date +%H%M%S)
mkdir -p "$work/shots" "$work/run" "$results"
cols=190 rows=59

background() {
    python3 - "$here/results/terminal-app/profile-${1// /-}.txt" <<'PY'
import re, sys
h = re.search(r"#([0-9a-f]{6})", open(sys.argv[1]).readline()).group(1)
r, g, b = (int(h[i:i+2], 16) / 255 for i in (0, 2, 4))
print("light" if 0.2126 * r + 0.7152 * g + 0.0722 * b > 0.5 else "dark")
PY
}

reads=()
for p in "${profiles[@]}"; do
    bg=$(background "$p")
    for cond in ${CONDITIONS:-known unknown}; do
        if [[ $cond == known ]]; then palette=$bg; else palette=basic; fi
        tag="${p// /-}--$cond"
        sig="$work/run/$tag-$stamp"
        title="D1 test: $(basename "$lo"), $p, background $cond ($bg) - $palette palette"
        wid=$(osascript <<OSA
tell application "Terminal"
  set t to do script ""
  set current settings of t to settings set "$p"
  set w to first window whose tabs contains t
  set position of w to {0, 0}
  set number of columns of t to $cols
  set number of rows of t to $rows
  set index of w to 1
  set wid to id of w
  do script "bash '$here/e-show.sh' '$lo/$palette.ans' $rows '$sig' '$title'" in t
  return wid
end tell
OSA
)
        for stage in top bottom; do
            for _ in $(seq 200); do [[ -e $sig.$stage ]] && break; sleep 0.1; done
            [[ -e $sig.$stage ]] || { echo "$p $cond: the $stage was not shown" >&2; exit 1; }
            sleep 0.5
            screencapture -x -o -l "$wid" "$work/shots/$tag-$stage.png"
            touch "$sig.$stage.taken"
        done
        osascript -e "tell application \"Terminal\" to close (every window whose id is $wid)" >/dev/null 2>&1 || true
        base=$lo/basic.ans
        [[ $palette == light ]] && base=$lo/basic-light.ans
        python3 "$here/read-output.py" "$work/shots/$tag-top.png" "$work/shots/$tag-bottom.png" "$lo/$palette.ans" "$lo/frame.json" \
            "$rows" "$p" "$cond" "$bg" "$palette" "$base" > "$work/shots/$tag.json"
        python3 "$here/read-output.py" --table "$work/shots/$tag.json" > "$results/$tag.txt"
        reads+=("$work/shots/$tag.json")
    done
done
python3 "$here/read-output.py" --summary "${reads[@]}" > "$results/summary.txt"
python3 "$here/read-output.py" --compare "${reads[@]}" > "$results/compare.txt"
echo "results: $results"
