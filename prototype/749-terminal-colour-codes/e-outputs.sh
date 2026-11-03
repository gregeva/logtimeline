#!/usr/bin/env bash
# e-outputs.sh <out-dir> <access-log> <palette.tsv>
#
# Writes what a 190-column terminal shows of one realistic ltl run, the run
# the architect validated on 2026-11-03: a web application access log
# carrying execution time in microseconds, nine hours of one day holding an
# outage, in 30-minute buckets, with failures highlighted, the duration
# heatmap, and the duration and bytes histograms. ltl runs once into
# <out-dir>/base (as it writes today, for a dark background and with -lbg for
# a light one, each also captured with bare -V); each palette file then gets
# <out-dir>/<palette>/ with one file per palette of D1:
#
#   basic.ans  the fallback, background unknown: ltl as it writes today, for
#              a dark background (its default)
#   dark.ans   background known dark: the dark run through e-palette.py dark
#   light.ans  background known light: the -lbg run through e-palette.py light
#   basic-light.ans  the -lbg run as ltl writes it, the light set's base
#
# Each file's first line (blank in ltl's output) carries the marker blocks
# and the calibration cell read-output.py finds the grid by, followed by that
# line's own colour codes (the next line inherits them), and the final
# newline is dropped so the window does not scroll past the last line.
# frame.json is their manifest. Each set is checked cell by cell against its
# base: every character and attribute kept, every colour as e-palette.py's
# mapping says; any difference stops the run.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
top=$(mkdir -p "$1" && cd "$1" && pwd)
log=$2
palette=$(cd "$(dirname "$3")" && pwd)/$(basename "$3")
base=$top/base
out=$top/$(basename "${palette%.tsv}")
mkdir -p "$base" "$out"
opts=(-du us -st 04:00 -et 13:00 -bs 30m -n 4 -hf -hm duration -hg --terminal-width 190)
cols=190
cd "$root"

if [[ ! -s $base/basic.raw || ! -s $base/basic-light.raw ]]; then
    perl ./ltl --disable-progress -dbg "${opts[@]}" "$log" > "$base/basic.raw"
    perl ./ltl --disable-progress -lbg "${opts[@]}" "$log" > "$base/basic-light.raw"
    perl ./ltl --disable-progress -V -dbg "${opts[@]}" "$log" > "$base/basic.V.txt"
    perl ./ltl --disable-progress -V -lbg "${opts[@]}" "$log" > "$base/basic-light.V.txt"
    if grep -l ' at .* line [0-9]' "$base"/*.V.txt; then echo "runtime warnings in the -V captures" >&2; exit 1; fi
fi
cp "$base/basic.raw" "$base/basic-light.raw" "$out/"
python3 "$here/e-palette.py" "$palette" dark < "$base/basic.raw" > "$out/dark.raw"
python3 "$here/e-palette.py" "$palette" light < "$base/basic-light.raw" > "$out/light.raw"

HERE=$here PALETTE=$palette python3 - "$out" "$cols" <<'PY'
import importlib.util, json, os, re, sys
out, cols = sys.argv[1], int(sys.argv[2])
spec = importlib.util.spec_from_file_location("ro", os.path.join(os.environ["HERE"], "read-output.py"))
ro = importlib.util.module_from_spec(spec); spec.loader.exec_module(ro)
M, C = "\x1b[38;2;254;0;129m█\x1b[0m", "\x1b[48;2;129;0;254m \x1b[0m"

def rgb(n):
    if n < 16: return None
    if n >= 232: g = 8 + 10*(n-232); return (g, g, g)
    n -= 16; lv = (0, 95, 135, 175, 215, 255); return (lv[n//36], lv[n//6 % 6], lv[n % 6])

spec = importlib.util.spec_from_file_location("ep", os.path.join(os.environ["HERE"], "e-palette.py"))
ep = importlib.util.module_from_spec(spec); spec.loader.exec_module(ep)
from collections import Counter

rows, texts = None, {}
for name in ("basic", "basic-light", "dark", "light"):
    lines = open(f"{out}/{name}.raw", encoding="utf-8").read().split("\n")
    if lines and lines[-1] == "": lines.pop()
    assert re.sub(r"\x1b\[[0-9;]*m", "", lines[0]).strip() == "", f"{name}: first line not blank"
    for n in {int(m) for m in re.findall(r"[34]8;5;(\d+)", "\n".join(lines))}:
        c = rgb(n)
        for mk in ((254, 0, 129), (129, 0, 254)):
            assert not c or sum((a-b)**2 for a, b in zip(c, mk)) ** 0.5 > 60, f"{name}: index {n} is near a marker colour"
    # the marker row ends with the first line's own codes, so the colours it
    # leaves in force for the next line are the ones ltl left
    lines[0] = M + " " * 49 + C + " " * (cols - 52) + M + "".join(re.findall(r"\x1b\[[0-9;]*m", lines[0]))
    texts[name] = "\n".join(lines)
    open(f"{out}/{name}.ans", "w", encoding="utf-8").write(texts[name])
    assert rows in (None, len(lines)), "the runs differ in length"
    rows = len(lines)

for name, base in (("dark", "basic"), ("light", "basic-light")):
    scheme, fixed = ep.load(os.environ["PALETTE"], name)
    want = {(r, c): (g, ep.remap(st, scheme, fixed, Counter(), g)) for r, c, g, st in ro.parse(texts[base])}
    got = {(r, c): (g, st) for r, c, g, st in ro.parse(texts[name])}
    bad = [k for k in want if k[0] > 0 and got.get(k) != want[k]] + [k for k in got if k not in want]
    assert not bad, f"{name}: {len(bad)} cells off, first {[(k, want.get(k), got.get(k)) for k in bad[:2]]}"
    print(f"{name}: every cell as its base and the palette say")

sw = [dict(id="marker-a", kind="marker", row=0, col=0, len=1, sgr="38;2;254;0;129"),
      dict(id="calib", kind="calib", row=0, col=50, len=1, sgr="48;2;129;0;254"),
      dict(id="marker-b", kind="marker", row=0, col=cols-1, len=1, sgr="38;2;254;0;129")]
json.dump(dict(cols=cols, rows=rows, swatches=sw), open(f"{out}/frame.json", "w"), indent=1)
print(f"{rows} lines by {cols} columns: basic.ans dark.ans light.ans (basic-light.ans) frame.json")
PY
