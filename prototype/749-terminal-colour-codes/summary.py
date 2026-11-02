#!/usr/bin/env python3
"""summary.py <analysis.json>... : one line per profile for each question."""
import json, sys
def d(a, b): return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5
R = []
for f in sys.argv[1:]:
    r = json.load(open(f)); s = {(x["id"], x["kind"]): x for x in r["swatches"]}
    R.append((r["capture"].replace(".png", ""), s))
basic = [str(n) for n in range(30, 38)] + [str(n) for n in range(90, 98)]

print("1. Bold (1;code) on the basic codes and the default foreground")
print(f"{'profile':15} {'bg':8} | {'basic: colour changed':22} | {'ink ratio':10} | default fg plain -> bold (contrast)")
for name, s in R:
    changed = [c for c in basic if d(s[(f"A:{c}:plain","block")]["rgb"], s[(f"A:{c}:other","block")]["rgb"]) >= 8]
    ratios = [s[(f"A:{c}:other","text")]["ink"] / max(s[(f"A:{c}:plain","text")]["ink"], 1) for c in basic if s[(f"A:{c}:plain","text")]["ink"] > 20]
    p, b = s[("A:39:plain","block")], s[("A:39:other","block")]
    print(f"{name:15} {p['bg']} | {(','.join(changed) or 'none'):22} | {min(ratios):.2f}-{max(ratios):.2f} | {p['colour']} -> {b['colour']} ({p['contrast']} -> {b['contrast']})")

print("\n2. Palette index 0-15 (38;5;N) against the basic code; index 16 against 30")
for name, s in R:
    diff = []
    for n in range(16):
        a = s[(f"B:38;5;{n}","block")]
        b = [x for k, x in s.items() if k[0].startswith("B:") and k[0].endswith(f":vs{n}")][0]
        if d(a["rgb"], b["rgb"]) >= 8: diff.append(f"{n}:{a['colour']}/{b['colour']}")
    i16, b30 = s[("B:38;5;16","block")], [x for k, x in s.items() if k[0] == "B:30:vs16"][0]
    print(f"{name:15} differ: {len(diff):2d}/16 {' '.join(diff[:4])}{' ...' if len(diff)>4 else ''} | 38;5;16 {i16['colour']} vs 30 {b30['colour']}")

print("\n3. Bold over index 16-255: colour changed?   4. Faint: plain -> faint contrast   5. 24-bit equals 256 of same RGB")
for name, s in R:
    c3 = [n for n in ["16","184","34","160","226","208","244","111"] if d(s[(f"C:{n}:plain","block")]["rgb"], s[(f"C:{n}:other","block")]["rgb"]) >= 8]
    fa = []
    for c in ["39", "33", "i184"]:
        p, q = s[(f"D:{c}:plain","text")], s[(f"D:{c}:other","text")]
        fa.append(f"{c} {p['contrast']}->{q['contrast']}")
    e = all(d(s[(f"E:{rgb}","block")]["rgb"], s[(f"E:{idx}:vs{rgb}","block")]["rgb"]) < 8 for rgb, idx in
            [("38;2;215;215;0","38;5;184"),("38;2;215;0;0","38;5;160"),("38;2;128;128;128","38;5;244"),("38;2;0;175;0","38;5;34")])
    print(f"{name:15} {(','.join(c3) or 'none'):8} | {' '.join(fa):40} | {'yes' if e else 'NO'}")

print("\n6. Contrast with the background of the codes ltl writes (block colour vs background)")
cols = [("93","duration"),("32","bytes"),("36","count"),("34","blue"),("35","magenta"),("31","red"),("33","WARN"),("90","rules"),("37","white")]
print(f"{'profile':15} " + " ".join(f"{c+' '+n:>11}" for c, n in cols))
for name, s in R:
    print(f"{name:15} " + " ".join(f"{s[(f'A:{c}:plain','block')]['contrast']:11.2f}" for c, _ in cols))
fixed = ["226","184","34","160","208","244","111","16"]
print(f"\n{'profile':15} " + " ".join(f"{'38;5;'+n:>9}" for n in fixed) + "   (fixed 256-colour codes, same RGB everywhere)")
for name, s in R:
    print(f"{name:15} " + " ".join(f"{s[(f'C:{n}:plain','block')]['contrast']:9.2f}" for n in fixed))

print("\n7. Text over a fill (contrast of the glyph with the fill): 38;5;0 | 30 | 38;5;16")
for name, s in R:
    parts = []
    for fill in ("184","34","20"):
        parts.append(" ".join(f"{s[(f'F:{fill}:{fg}','filltext')]['contrast']:5.2f}" for fg in ("38;5;0","30","38;5;16")))
    print(f"{name:15} on 184: {parts[0]} | on 34: {parts[1]} | on 20: {parts[2]}")
