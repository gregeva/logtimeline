#!/usr/bin/env bash
# e-measure.sh <work-dir> <palette-dir> [profile...]
#
# D1 across terminal configurations, for every run e-outputs.sh wrote into
# <palette-dir>. For each Terminal.app profile (every shipped one but Solid
# Colors, whose background changes with each window, by default) and each
# condition:
#
#   known    the background is known: the set for the profile's background,
#            light or dark by ltl's rule (detect_terminal: BT.709 luma of the
#            background above one half), from the background measured in
#            results/terminal-app/
#   unknown  the background is not known: the fallback, today's colours
#
# a 190 by 59 window prints the run's file a page at a time (e-show.sh), is
# captured after each page and closed. read-output.py reads the pages.
# Tables go to results/e-prototype/<palette>/; the captures stay in
# <work-dir> and out of the repository (window titles carry the user's name).
#
# RUNS="<run> ..." and CONDITIONS="known" narrow a pass. macOS only;
# Terminal needs Screen Recording permission for screencapture.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
here=$(cd "$(dirname "$0")" && pwd)
work=$(mkdir -p "$1" && cd "$1" && pwd)
lo=$(cd "$2" && pwd)
shift 2
profiles=("$@")
[[ ${#profiles[@]} -gt 0 ]] || profiles=("Clear Dark" "Clear Light" "Basic" "Pro" "Homebrew" "Man Page" "Novel" "Silver Aerogel" "Grass" "Ocean" "Red Sands")
runs=(${RUNS:-$(cd "$lo" && ls -d */ | tr -d /)})
results="$here/results/e-prototype/$(basename "$lo")"
stamp=$(date +%H%M%S)
mkdir -p "$work/run" "$results"
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
        for r in "${runs[@]}"; do
            tag="$r--${p// /-}--$cond"
            sig="$work/run/$tag-$stamp"
            shots="$work/shots/$tag"
            mkdir -p "$shots"
            title="D1 test: $(basename "$lo"), $r, $p, background $cond ($bg) - $palette palette"
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
  do script "bash '$here/e-show.sh' '$lo/$r/$palette.ans' $rows '$sig' '$title'" in t
  return wid
end tell
OSA
)
            k=0
            while :; do
                for _ in $(seq 400); do [[ -e $sig.page-$k || -e $sig.end ]] && break; sleep 0.05; done
                [[ -e $sig.page-$k ]] || break
                sleep 0.4
                screencapture -x -o -l "$wid" "$shots/page-$k.png"
                touch "$sig.page-$k.taken"
                k=$((k + 1))
            done
            [[ -e $sig.end ]] || { echo "$tag: the window did not finish" >&2; exit 1; }
            osascript -e "tell application \"Terminal\" to close (every window whose id is $wid)" >/dev/null 2>&1 || true
            base=$lo/$r/basic.ans
            [[ $palette == light ]] && base=$lo/$r/basic-light.ans
            python3 "$here/read-output.py" "$shots" "$lo/$r/$palette.ans" "$lo/$r/frame.json" "$rows" \
                "$p" "$cond" "$bg" "$palette" "$base" "$r" > "$shots/read.json"
            python3 "$here/read-output.py" --table "$shots/read.json" > "$results/$tag.txt"
            reads+=("$shots/read.json")
        done
    done
done
python3 "$here/read-output.py" --summary "${reads[@]}" > "$results/summary.txt"
python3 "$here/read-output.py" --compare "${reads[@]}" > "$results/compare.txt"
echo "results: $results"
