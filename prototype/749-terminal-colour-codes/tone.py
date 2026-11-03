#!/usr/bin/env python3
"""tone.py --out <palette.tsv> [--base palettes/s2-c4.tsv]

The sets of D1 with tone governing. Every text colour starts from what ltl
draws today in the class's default Terminal.app profile (Clear Dark, Clear
Light) and keeps it: same hue, same chroma, same lightness, written as a
24-bit code. A colour below 4.5:1 on that profile's background moves in
lightness only, toward contrast, until it reaches 4.5:1 or has moved as far
as the profile itself moves that hue between its normal and bright colour
(0.05 to 0.12 in OKLCH lightness; 0.08 for greys and ltl's fixed codes).

- s<i>  the sixteen scheme colours as the profile draws them. On light,
        white and bright white start from the profile's own text and bold
        text, as ltl's light notice panel writes black where its dark one
        writes white.
- f<N>  ltl's fixed 256-colour text codes: kept as they are when they read
        at 4.5:1, otherwise moved as above.
- e     bold over the default foreground: the profile's bold text colour.

The fills keep today's 256-colour codes, sliced from ltl's @column_colors,
except where a column's highlighted fill stands less far from its plain fill
than yellow's pair does (OKLab distance): that column's highlight takes the
code ltl's histogram already highlights the column with (highlighted_bg_num).
e-palette.py writes the text over each fill in black or white, whichever
reads better on it (the expected behaviour of #683).

A value in the palette is a 256-colour index (N) or a 24-bit colour (#rrggbb).
"""
import argparse, math, os, re

ap = argparse.ArgumentParser()
ap.add_argument("--out")
ap.add_argument("--base", default="palettes/s2-c4.tsv", help="names and uses of the roles")
ap.add_argument("--grey-cap", type=float, default=0.08)
a = ap.parse_args()
FLOOR = 4.5

def lin(v):
    v /= 255; return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
def gam(v): return 12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055
def rgb(h): return tuple(int(h[i:i+2], 16) for i in (1, 3, 5))
def lum(h): r, g, b = map(lin, rgb(h)); return 0.2126 * r + 0.7152 * g + 0.0722 * b
def cr(x, y): p, q = sorted((lum(x), lum(y)), reverse=True); return (p + 0.05) / (q + 0.05)
def lch(h):
    r, g, b = map(lin, rgb(h))
    l = (0.4122214708*r + 0.5363325363*g + 0.0514459929*b) ** (1/3)
    m = (0.2119034982*r + 0.6806995451*g + 0.1073969566*b) ** (1/3)
    s = (0.0883024619*r + 0.2817188376*g + 0.6299787005*b) ** (1/3)
    L = 0.2104542553*l + 0.7936177850*m - 0.0040720468*s
    A = 1.9779984951*l - 2.4285922050*m + 0.4505937099*s
    B = 0.0259040371*l + 0.7827717662*m - 0.8086757660*s
    return L, math.hypot(A, B), math.degrees(math.atan2(B, A)) % 360
def from_lch(L, C, H):
    """OKLCH to #rrggbb, chroma reduced until the colour is in sRGB"""
    while True:
        A, B = C * math.cos(math.radians(H)), C * math.sin(math.radians(H))
        l = (L + 0.3963377774*A + 0.2158037573*B) ** 3
        m = (L - 0.1055613458*A - 0.0638541728*B) ** 3
        s = (L - 0.0894841775*A - 1.2914855480*B) ** 3
        v = (4.0767416621*l - 3.3077115913*m + 0.2309699292*s,
             -1.2684380046*l + 2.6097574011*m - 0.3413193965*s,
             -0.0041960863*l - 0.7034186147*m + 1.7076147010*s)
        if all(-1e-4 <= x <= 1 + 1e-4 for x in v) or C <= 0:
            return "#" + "".join("%02x" % round(255 * gam(min(1, max(0, x)))) for x in v)
        C -= 0.002
def x256(n):
    if n >= 232: g = 8 + 10 * (n - 232); return "#%02x%02x%02x" % (g, g, g)
    n -= 16; lv = (0, 95, 135, 175, 215, 255); return "#%02x%02x%02x" % (lv[n // 36], lv[n // 6 % 6], lv[n % 6])

def drawn(profile):
    """index 0-15 as the profile draws them, its text and bold text colours, its background"""
    d, fg = {}, None
    path = f"results/terminal-app/profile-{profile}.txt"
    for line in open(path):
        m = re.match(r"\s+38;5;(\d+) (#[0-9a-f]{6})", line)
        if m and int(m.group(1)) < 16: d[int(m.group(1))] = m.group(2)
        m = re.match(r"\s+39 (#[0-9a-f]{6}) (#[0-9a-f]{6})", line)
        if m and fg is None: fg = m.groups()
    bg = re.search(r"#[0-9a-f]{6}", open(path).readline()).group(0)
    return d, fg, bg

def move(target, bg, cap):
    """the target, or the least lightness move toward 4.5:1, no further than cap"""
    if cr(target, bg) >= FLOOR: return target
    L, C, H = lch(target)
    toward = 1 if lum(bg) < 0.18 else -1
    best = target
    for i in range(1, 201):
        best = from_lch(L + toward * cap * i / 200, C, H)
        if cr(best, bg) >= FLOOR: break
    return best

def okdist(x, y):
    p, q = lch(x), lch(y)
    pa = (p[0], p[1] * math.cos(math.radians(p[2])), p[1] * math.sin(math.radians(p[2])))
    qa = (q[0], q[1] * math.cos(math.radians(q[2])), q[1] * math.sin(math.radians(q[2])))
    return math.dist(pa, qa)

def column_colors():
    """@column_colors from ltl: name, plain fill, highlighted fill, the histogram's highlight"""
    src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "ltl"), encoding="utf-8").read()
    block = src[src.index("my @column_colors = ("):]
    block = block[:block.index("\n);")]
    out = []
    for m in re.finditer(r"name => '(\w+)',\s+highlighted_bg => \"\\033\[48;5;(\d+)m.*?plain_bg => \"\\033\[48;5;(\d+)m.*?highlighted_bg_num => (\d+)", block, re.S):
        out.append((m.group(1), int(m.group(3)), int(m.group(2)), int(m.group(4))))
    assert len(out) == 10, out
    return out

COLUMNS = column_colors()
yellow = next(c for c in COLUMNS if c[0] == "yellow")
SEP = okdist(x256(yellow[1]), x256(yellow[2]))
FILLS = {}
for name, plain, high, hist in COLUMNS:
    if okdist(x256(plain), x256(high)) < SEP - 0.005 and okdist(x256(plain), x256(hist)) >= SEP:
        FILLS[f"b{high}"] = (name, hist, plain)

rows = [l.rstrip("\n").split("\t") for l in open(a.base) if not l.startswith("#")]
meta = {r[0]: r[1:3] for r in rows}
sets = {}
for cls, profile in (("dark", "Clear-Dark"), ("light", "Clear-Light")):
    d, fg, bg = drawn(profile)
    caps = {i: abs(lch(d[i + 8])[0] - lch(d[i])[0]) for i in range(1, 7)}
    out = {}
    for i in range(1, 16):
        t = d[i]
        if cls == "light" and i == 7: t = fg[0]
        if cls == "light" and i == 15: t = fg[1]
        out[f"s{i}"] = (t, move(t, bg, caps.get(i if i < 8 else i - 8, a.grey_cap)))
    for k in meta:
        if k.startswith("f"):
            t = x256(int(k[1:])); m = move(t, bg, a.grey_cap)
            out[k] = (t, int(k[1:]) if m == t else m)
    out["e"] = (fg[1], fg[1])
    sets[cls] = (out, bg)

def hexof(v): return v if isinstance(v, str) else x256(v)
print("role, today on the profile -> the set, contrast today -> set, lightness moved")
for cls, (out, bg) in sets.items():
    print(f"== {cls} (background {bg})")
    for k, (t, v) in out.items():
        h = hexof(v)
        print(f"  {k:5} {(meta.get(k, ['', ''])[1] or '')[:44]:44} {t} -> {str(v):>7}  {cr(t, bg):5.2f} -> {cr(h, bg):5.2f}  {lch(h)[0]-lch(t)[0]:+.3f}")

for k, (name, v, plain) in FILLS.items():
    print(f"  {k}: the {name} column's highlighted fill -> {v} {x256(v)} (the histogram's highlight), "
          f"apart from its plain fill {plain} {okdist(x256(plain), x256(v)):.3f} against yellow's {SEP:.3f}")

if a.out:
    with open(a.out, "w", encoding="utf-8", newline="\n") as f:
        f.write("# D1 candidate sets by tone.py: tone governs; today's colours as Clear Dark and Clear Light draw them, 24-bit,\n")
        f.write("# moved in lightness only toward 4.5:1, by no more than the profile's own step from that colour to its bright twin\n")
        f.write("# fills as today but a highlight too near its plain fill, which takes the histogram's; the text over a fill black or white, whichever reads better\n")
        f.write("# source\tname\tuse\tdark\tdark_rgb\tdark_min\tlight\tlight_rgb\tlight_min\n")
        dk, dbg = sets["dark"]; lt, lbg = sets["light"]
        for k in dk:
            name, use = meta.get(k, ("bold", "bold over the default foreground"))
            vd, vl = dk[k][1], lt[k][1]
            f.write(f"{k}\t{name}\t{use}\t{vd}\t{hexof(vd)}\t{cr(hexof(vd), dbg):.2f}\t{vl}\t{hexof(vl)}\t{cr(hexof(vl), lbg):.2f}\n")
        for k, (name, v, plain) in FILLS.items():
            f.write(f"{k}\t48;5;{k[1:]}\t{name} highlighted fill\t{v}\t{x256(v)}\t{cr(x256(v), dbg):.2f}\t{v}\t{x256(v)}\t{cr(x256(v), lbg):.2f}\n")
