#!/usr/bin/env python3
"""tally.py <read.json>...

Per profile or scheme, the groups of cells that fall below the floor, with
the background unknown (the fallback, today's colours) and known (the set):
the tallies of features/749-terminal-colour-codes.md § 10.1. A group is
read-output.py's, counted once per run: the cells of one run with one code
today, one code drawn, bold or not, one background code and one kind; the
histogram's and the heatmap's cells are left out. Three kinds, each with
its floor (WCAG 2 contrast of the group's drawn colour with the cell's
background):

  text on the background   text with no background code    4.5:1 (and how many fall below 3:1)
  text over a fill         text with a background code     4.5:1
  bars and lines           box drawing, block and geometric glyphs, on the background or a fill   3:1

Each cell reads <below the floor>/<groups>, today then the set.
"""
import json, sys
from collections import defaultdict

KINDS = (("text on the background", lambda g: g["kind"] == "text" and g["bg"] == "def", 4.5),
         ("text over a fill", lambda g: g["kind"] == "text" and g["bg"] != "def", 4.5),
         ("bars and lines", lambda g: g["kind"] == "graphic", 3.0))

reads = [json.load(open(p, encoding="utf-8")) for p in sys.argv[1:]]
profiles = list(dict.fromkeys(d["profile"] for d in reads))
info = {d["profile"]: (d["background"], d["window_bg"]) for d in reads}
cells = defaultdict(lambda: defaultdict(list))
for d in reads:
    for g in d["groups"]:
        if g.get("region") == "chart": continue
        for name, test, floor in KINDS:
            if test(g): cells[(d["profile"], d["condition"])][name].append(g["contrast"])
runs = sorted({d["run"] for d in reads})
print(f"Groups below the floor, background unknown (today's colours) > known (the set), over {len(runs)} runs: {', '.join(runs)}")
print(f"{'profile':20} {'class':5} {'window':8}  " + "  ".join(f"{n + ' (' + str(f) + ')':>28}" for n, _, f in KINDS) + "  text below 3")
for p in profiles:
    out = []
    for name, _, floor in KINDS:
        u, k = cells[(p, "unknown")][name], cells[(p, "known")][name]
        out.append(f"{sum(c < floor for c in u):>3}/{len(u):<3} > {sum(c < floor for c in k):>3}/{len(k):<3}".rjust(28))
    t = [sum(c < 3 for c in cells[(p, cond)][KINDS[0][0]]) for cond in ("unknown", "known")]
    print(f"{p:20} {info[p][0]:5} {info[p][1]:8}  " + "  ".join(out) + f"  {t[0]:>3} > {t[1]:<3}")
