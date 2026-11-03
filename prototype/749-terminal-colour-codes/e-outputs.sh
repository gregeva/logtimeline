#!/usr/bin/env bash
# e-outputs.sh <out-dir> <palette.tsv>
#
# Writes what a 190-column terminal shows of the runs that together show
# every surface in scope (features/749-terminal-colour-codes.md § 10), in
# the three palettes of D1. The runs read the corpus under logs/ (the
# outage day's web access log and method server logs of one node, and a CSV
# of custom system metrics):
#
#   access-heatmap  the access log, failures highlighted, duration heatmap and both histograms
#   access-latency  the same, without the heatmap (the latency column) and with -sm
#   levels          the method server logs of the same node and morning: log levels
#   udm             seven user-defined metrics and one matching nothing: every column colour, a notice panel
#   help            --help (FORCE_COLOR)
#   explain         --explain contribution-highlighting (FORCE_COLOR)
#   error           a usage error (FORCE_COLOR)
#   progress-pause  the progress lines and the pause prompt, printed from ltl's own codes for them
#
# ltl runs once per run into <out-dir>/base/<run>/ (basic.raw as it writes
# for a dark background, basic-light.raw with -lbg; the runs that read logs
# also captured with bare -V). Each palette then gets
# <out-dir>/<palette>/<run>/ with basic.ans (the fallback), dark.ans and
# light.ans (through e-palette.py), basic-light.ans (the light set's base)
# and frame.json. Each file gets a first line of its own carrying the marker
# blocks and calibration cell read-output.py finds the grid by, and loses
# its final newline. The rewrites are checked against their base: every
# character and attribute kept, the histogram and heatmap cells unchanged.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
top=$(mkdir -p "$1" && cd "$1" && pwd)
palette=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
cols=190
cd "$root"

A=logs/Sets/windchill-jdk21-balancer-outage/node2/apachelogs/access.log_2026-08-21_00_00_00
D=logs/Sets/windchill-jdk21-balancer-outage/node2/logs
day=(-st 04:00 -et 13:00 -bs 30m -n 4 -hf --terminal-width $cols)
run() {  # run <name> <flags> : ltl's output for that run
    local name=$1 flags=$2
    case $name in
        access-heatmap) perl ./ltl --disable-progress $flags -du us "${day[@]}" -hm duration -hg $A ;;
        access-latency) perl ./ltl --disable-progress $flags -du us "${day[@]}" -sm $A ;;
        levels) perl ./ltl --disable-progress $flags -st 04:00 -et 12:30 -bs 30m -n 4 -hf --terminal-width $cols \
                    $D/MethodServer-2608090416-8780-log4j.log $D/MethodServer-2608211150-2679531-log4j.log.2026-08-21_1 \
                    $D/MethodServer-2608211150-2679531-log4j.log.2026-08-21_2 ;;
        udm) perl ./ltl --disable-progress $flags -bs 10 -n 4 --terminal-width $cols \
                 -udm system_cpu_total::max -udm tcp_inuse::max -udm tcp_established::max -udm ctx_switches::max \
                 -udm tcp_timewait::max -udm system_mem_percent::max -udm java_mem_rss::max -udm no_such_column::max \
                 logs/UDM/connection-server-custom-metrics.csv ;;
        help) FORCE_COLOR=1 perl ./ltl --disable-progress $flags --terminal-width $cols --help ;;
        explain) FORCE_COLOR=1 perl ./ltl --disable-progress $flags --terminal-width $cols --explain contribution-highlighting ;;
        error) FORCE_COLOR=1 perl ./ltl --disable-progress $flags --terminal-width $cols --bogus-option $A 2>&1 || true ;;
        progress-pause)
            # ltl's own codes: $colors{'bright-green'} before each stage's
            # "... completed." line, and pause_for_keypress's "\033[0;44m$prompt\033[0m"
            local green prompt
            green=$(perl -ne "print \$1 if /'bright-green'\s*=>\s*\"([^\"]+)\"/" ltl | head -1)
            prompt=$(perl -ne 'print $1 if /\$prompt = "([^"]+)" unless defined \$prompt/' ltl | head -1)
            for stage in "Processing" "Calculating heatmap buckets" "Consolidating similar messages"; do
                printf '%b%s completed.\033[0m\n' "$green" "$stage"
            done
            [[ -n $prompt ]] || { echo "pause_for_keypress's prompt not found in ltl" >&2; exit 1; }
            printf '\n\033[0;44m%s\033[0m\n' "$prompt" ;;
    esac
}
runs=(access-heatmap access-latency levels udm help explain error progress-pause)

for r in "${runs[@]}"; do
    b=$top/base/$r
    mkdir -p "$b"
    if [[ ! -s $b/basic.raw ]]; then
        run "$r" -dbg > "$b/basic.raw" 2>&1
        run "$r" -lbg > "$b/basic-light.raw" 2>&1
        case $r in access-*|levels|udm) run "$r" "-V -dbg" > "$b/basic.V.txt" 2>&1 ;; esac
    fi
done
if grep -l ' at .* line [0-9]' "$top"/base/*/basic.V.txt; then echo "runtime warnings in the -V captures" >&2; exit 1; fi

name=$(basename "${palette%.tsv}")
for r in "${runs[@]}"; do
    out=$top/$name/$r
    mkdir -p "$out"
    cp "$top/base/$r/basic.raw" "$top/base/$r/basic-light.raw" "$out/"
    python3 "$here/e-palette.py" "$palette" dark < "$out/basic.raw" > "$out/dark.raw" 2>"$out/dark.counts"
    python3 "$here/e-palette.py" "$palette" light < "$out/basic-light.raw" > "$out/light.raw" 2>"$out/light.counts"
    HERE=$here python3 - "$out" "$cols" <<'PY'
import importlib.util, json, os, sys
out, cols = sys.argv[1], int(sys.argv[2])
def module(name, file):
    spec = importlib.util.spec_from_file_location(name, os.path.join(os.environ["HERE"], file))
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m
ro, ep = module("ro", "read-output.py"), module("ep", "e-palette.py")
M, C = "\x1b[38;2;254;0;129m█\x1b[0m", "\x1b[48;2;129;0;254m \x1b[0m"
marker = M + " " * 49 + C + " " * (cols - 52) + M + "\x1b[0m"
texts, rows = {}, None
for name in ("basic", "basic-light", "dark", "light"):
    t = open(f"{out}/{name}.raw", encoding="utf-8").read()
    texts[name] = marker + "\n" + (t[:-1] if t.endswith("\n") else t)
    open(f"{out}/{name}.ans", "w", encoding="utf-8").write(texts[name])
    n = len(texts[name].split("\n"))
    assert rows in (None, n), f"{out}: the palettes differ in length"
    rows = n
for name, base in (("dark", "basic"), ("light", "basic-light")):
    keep = ep.masks(texts[base])
    b = {(r, c): (g, st) for r, c, g, st in ro.parse(texts[base])}
    got = ro.parse(texts[name])
    bad = []
    for r, c, g, st in got:
        bg, bst = b.get((r, c), (None, None))
        if bst is None or g != bg or any(st[k] != bst[k] for k in ("bold", "faint", "ul", "rev")): bad.append((r, c, "character or attribute"))
        elif keep(r, c) and (st["fg"], st["bg"]) != (bst["fg"], bst["bg"]): bad.append((r, c, "histogram or heatmap cell changed"))
    assert not bad and len(b) == len(got), f"{out} {name}: {len(bad)} cells off, first {bad[:3]}"
sw = [dict(id="marker-a", kind="marker", row=0, col=0, len=1), dict(id="calib", kind="calib", row=0, col=50, len=1),
      dict(id="marker-b", kind="marker", row=0, col=cols-1, len=1)]
json.dump(dict(cols=cols, rows=rows, swatches=sw), open(f"{out}/frame.json", "w"), indent=1)
print(f"{os.path.basename(out)}: {rows} lines; every character and attribute kept, histogram and heatmap untouched")
PY
done
