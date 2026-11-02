#!/usr/bin/env python3
"""report.py <analysis.json>... : the measurement tables, per capture."""
import json, sys

def d(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5

for f in sys.argv[1:]:
    r = json.load(open(f))
    s = {(x["id"], x["kind"]): x for x in r["swatches"]}
    print(f"== {r['capture']}  (background beside group A: {s[('A:39:plain','block')]['bg']})")

    def pair(group, codes, title):
        print(f"{title}\n  {'code':>8} {'plain':>8} {'other':>8} {'colour':>9} | ink plain other ratio | contrast plain other")
        for name in codes:
            pb, ob = s[(f"{group}:{name}:plain", "block")], s[(f"{group}:{name}:other", "block")]
            pt, ot = s[(f"{group}:{name}:plain", "text")], s[(f"{group}:{name}:other", "text")]
            dd = d(pb["rgb"], ob["rgb"])
            same = "same" if dd < 8 else "DIFF %.0f" % dd
            print(f"  {name:>8} {pb['colour']} {ob['colour']} {same:>9} | {pt['ink']:4d} {ot['ink']:4d} {ot['ink']/max(pt['ink'],1):5.2f} | "
                  f"{pb['contrast']:5.2f} {ob['contrast']:5.2f}")

    basic = ["39"] + [str(n) for n in range(30, 38)] + [str(n) for n in range(90, 98)]
    pair("A", basic, "A  bold on basic codes and the default foreground (other = 1;code)")

    print("B  palette index beside basic code (block colours)")
    for n in list(range(16)) + [16, 244, 231, 232]:
        idx = f"38;5;{n}"
        a = s[(f"B:{idx}", "block")]
        b = [x for k, x in s.items() if k[0].startswith("B:") and k[0].endswith(f":vs{n}")][0]
        dd = d(a["rgb"], b["rgb"])
        print(f"  {idx:>9} {a['colour']}  {b['sgr']:>3} {b['colour']}  {'same' if dd < 8 else 'DIFF %.0f' % dd}  contrast {a['contrast']:5.2f} / {b['contrast']:5.2f}")

    pair("C", ["16", "184", "34", "160", "226", "208", "244", "111"], "C  bold over index 16-255 (other = 1;38;5;N)")
    pair("D", ["39", "37", "33", "30", "i184", "i16"], "D  faint (other = 2;code)")

    print("E  24-bit beside the 256-colour index of the same RGB")
    for rgb, idx in [("38;2;215;215;0", "38;5;184"), ("38;2;215;0;0", "38;5;160"),
                     ("38;2;128;128;128", "38;5;244"), ("38;2;0;175;0", "38;5;34")]:
        a, b = s[(f"E:{rgb}", "block")], s[(f"E:{idx}:vs{rgb}", "block")]
        dd = d(a["rgb"], b["rgb"])
        print(f"  {rgb:>17} {a['colour']}  {idx:>9} {b['colour']}  {'same' if dd < 8 else 'DIFF %.0f' % dd}")

    print("F  text over a fill: extreme ink pixel and its contrast with the fill")
    for fill in ("184", "34", "20"):
        row = []
        for fg in ("38;5;0", "30", "38;5;16"):
            x = s[(f"F:{fill}:{fg}", "filltext")]
            row.append(f"{fg:>8} {x['extreme']} on {x['bg']} {x['contrast']:5.2f}")
        print("  " + " | ".join(row))
    print()
