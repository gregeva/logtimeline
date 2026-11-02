#!/usr/bin/env bash
# measure.sh <work-dir> [<ltl-output-dir>]
#
# Draws the measurement pattern in every shipped Terminal.app profile, reads
# each capture, and writes the tables to results/ beside this script. Asks
# Terminal.app for its background (OSC 11) in Clear Light and Clear Dark.
# With <ltl-output-dir> holding the .ans files ltl-outputs.sh writes (ltl's
# output as written and as rewritten to fixed codes), also draws each in four
# profiles into <work-dir>/shots, for looking at; the captures stay out of the
# repository.
#
# macOS only. Terminal (or whatever runs this) needs Screen Recording
# permission for screencapture. Windows open on screen for about two seconds
# each.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
work=$(mkdir -p "$1" && cd "$1" && pwd)
ltl_out=${2:-}
results="$here/results/terminal-app"
mkdir -p "$work/pattern" "$results"

profiles=("Clear Dark" "Clear Light" "Basic" "Grass" "Homebrew" "Man Page" "Novel" "Ocean" "Pro" "Red Sands" "Silver Aerogel" "Solid Colors")

cd "$work"
python3 "$here/pattern.py"
analyses=()
for p in "${profiles[@]}"; do
    f="$work/pattern/${p// /-}"
    "$here/open-capture.sh" "$p" "$work/pattern.ans" "$f.png" 102 34 >/dev/null
    python3 "$here/analyse.py" "$f.png" "$work/pattern.json" "$f.json" >/dev/null
    python3 "$here/report.py" "$f.json" > "$results/profile-${p// /-}.txt"
    analyses+=("$f.json")
done
python3 "$here/summary.py" "${analyses[@]}" > "$results/summary.txt"
python3 "$here/fixed-contrast.py" "${analyses[@]}" > "$results/fixed-contrast.txt"

: > "$results/osc11.txt"
for p in "Clear Light" "Clear Dark"; do
    reply="$work/osc11-${p// /-}.txt"
    : > "$reply"
    osascript >/dev/null <<OSA
tell application "Terminal"
  set t to do script "perl '$here/osc11.pl' '$reply'; exit"
  set current settings of t to settings set "$p"
  delay 3
  try
    close (first window whose tabs contains t)
  end try
end tell
OSA
    echo "$p: $(cat "$reply" 2>/dev/null || echo '(no file)')" >> "$results/osc11.txt"
done

if [[ -n "$ltl_out" ]]; then
    mkdir -p "$work/shots"
    for p in "Clear Dark" "Clear Light" "Man Page" "Basic"; do
        for f in "$ltl_out"/*.ans; do
            "$here/open-capture.sh" "$p" "$f" "$work/shots/${p// /-}--$(basename "${f%.ans}").png" 120 56 >/dev/null
        done
    done
fi
echo "results: $results"
