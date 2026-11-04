#!/usr/bin/env bash
# wt-measure.sh <work-dir> [<ltl-output-dir>]
#
# The Windows counterpart of measure.sh: draws the measurement pattern in
# Windows Terminal in every colour scheme the installed Windows Terminal
# ships (the schemes of its defaults.json; Campbell, its default dark
# scheme, and One Half Light first, the pair fixed-contrast.py reads), reads
# each capture, and writes the tables to results/windows-terminal/ beside
# this script: one profile-<scheme>.txt per scheme, summary.txt,
# fixed-contrast.txt, and schemes.txt, each scheme's measured background
# classed light or dark by ltl's rule (detect_terminal: BT.709 luma of the
# background above one half). With <ltl-output-dir> holding the .ans files
# ltl-outputs.sh writes (ltl's output as written and as rewritten to fixed
# codes), also draws each in every scheme into <work-dir>/shots, for looking
# at; the captures stay out of the repository.
#
# Windows, from Git Bash. The pattern is drawn in a 102 by 34 window; ltl's
# output full screen, which holds its 55 lines on a 1080-pixel display where
# a 58-row window does not fit. Windows open on screen for about three
# seconds each. The tables are written with LF endings, as on macOS.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
# Python reads and writes UTF-8, as ltl does, also where the locale does not (Windows: cp1252)
export PYTHONUTF8=1
here=$(cd "$(dirname "$0")" && pwd)
work=$(mkdir -p "$1" && cd "$1" && pwd)
ltl_out=${2:-}
results="$here/results/windows-terminal"
mkdir -p "$work/pattern" "$results"

install=$(powershell.exe -NoProfile -Command '(Get-AppxPackage Microsoft.WindowsTerminal).InstallLocation' | tr -d '\r')
mapfile -t schemes < <(python3 - "$install\defaults.json" <<'PY' | tr -d '\r'
import json, re, sys
t = open(sys.argv[1], encoding="utf-8-sig").read()
t = re.sub(r",(\s*[}\]])", r"\1", re.sub(r"^\s*//.*$", "", t, flags=re.M))
names = [s["name"] for s in json.loads(t)["schemes"]]
first = [n for n in ("Campbell", "One Half Light") if n in names]
assert len(first) == 2, "Campbell or One Half Light is not among the shipped schemes"
print("\n".join(first + [n for n in names if n not in first]))
PY
)
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
python3 - "$results" "${schemes[@]}" <<'PY' | tr -d '\r' > "$results/schemes.txt"
import re, sys
results = sys.argv[1]
print("Each shipped scheme's background, measured beside the pattern, classed by ltl's rule")
print("(detect_terminal: BT.709 luma of the background above one half is light)")
print(f"{'scheme':20} {'background':10} {'luma':>6}  class")
for s in sys.argv[2:]:
    h = re.search(r"#([0-9a-f]{6})", open(f"{results}/profile-{s.replace(' ', '-')}.txt").readline()).group(1)
    r, g, b = (int(h[i:i+2], 16) / 255 for i in (0, 2, 4))
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    print(f"{s:20} #{h:9} {y:6.3f}  {'light' if y > 0.5 else 'dark'}")
PY

if [[ -n "$ltl_out" ]]; then
    mkdir -p "$work/shots"
    for s in "${schemes[@]}"; do
        for f in "$ltl_out"/*.ans; do
            capture -Scheme "$s" -File "$f" -Out "$work/shots/${s// /-}--$(basename "${f%.ans}").png" -Fullscreen >/dev/null
        done
    done
fi
echo "results: $results"
