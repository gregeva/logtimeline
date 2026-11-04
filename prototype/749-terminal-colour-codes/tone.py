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
- grey  the set's grey, the architect's (feature doc § 12.8): #797c81 on
        dark, #747474 on light. e-palette.py writes it in place of s8 and
        f244, and for the heatmap's scale line and percentile markers and the
        histogram's gridlines: one grey for every line and all secondary text.

The heatmap gradients (g<name>): each column's 8 steps for dark and for light,
24-bit, every step in the column's own hue (its plain fill's: today's 256-colour
gradients wander off it, through pinks for red, cyan for blue, red-orange for
yellow), each keeping the saturation today's step has (its chroma as a share of
the most its hue holds at its lightness), the faintest as far from the
background as today's dark yellow's faintest is from Clear Dark, the densest at
today's lightness, the steps between evenly spaced in lightness.

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

def gradients():
    """each column's heatmap gradients from ltl: name -> (gradient, gradient_light), 8 codes each"""
    src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "ltl"), encoding="utf-8").read()
    block = src[src.index("my @column_colors = ("):]
    block = block[:block.index("\n);")]
    out = {}
    for m in re.finditer(r"name => '(\w+)'.*?gradient\s+=> \[([\d, ]+)\],\s+gradient_light => \[([\d, ]+)\]", block, re.S):
        out[m.group(1)] = tuple([int(x) for x in g.split(",")] for g in (m.group(2), m.group(3)))
    assert len(out) == 10, out
    return out

GRADIENTS = gradients()
# The reference: today's dark yellow gradient (the duration heatmap on a dark
# background). Its faintest step's distance from Clear Dark (OKLab, which
# counts hue and chroma as well as lightness: a heatmap cell is seen by its
# colour) is the floor every gradient's faintest step reaches on its
# background, and its closest two neighbouring steps set how close any two
# neighbouring steps may lie.
def _drawn_bg(profile):
    return re.search(r"#[0-9a-f]{6}", open(f"results/terminal-app/profile-{profile}.txt").readline()).group(0)
G_FLOOR = okdist(x256(GRADIENTS["yellow"][0][0]), _drawn_bg("Clear-Dark"))
G_STEP = min(abs(lch(x256(p))[0] - lch(x256(q))[0]) for p, q in zip(GRADIENTS["yellow"][0], GRADIENTS["yellow"][0][1:]))

def cmax(L, H):
    """the most chroma sRGB holds at this OKLCH lightness and hue"""
    lo, hi = 0.0, 0.4
    for _ in range(30):
        mid = (lo + hi) / 2
        if lch(from_lch(L, mid, H))[1] >= mid - 0.002: lo = mid
        else: hi = mid
    return lo

YELLOW = lch(x256(next(c[1] for c in COLUMNS if c[0] == "yellow")))
AMBER = lch(x256(94))      # #875f00, the amber step of today's dark yellow gradient

def warm(hue, L):
    """a yellow darker than the yellow column's fill turns toward amber (today's 94),
    reached at lightness 0.65, as today's yellow gradients do with their amber and
    gold steps: darkened, a lemon yellow turns olive; every other hue is kept"""
    if not 95 <= hue <= 120 or L >= YELLOW[0]: return hue
    t = min(1.0, (YELLOW[0] - L) / (YELLOW[0] - 0.65))
    return hue + (AMBER[2] - hue) * t

def gradient(codes, bg, hue):
    """today's 8 steps in the column's own hue (its plain fill's), each keeping its
    saturation (its chroma as a share of the most its hue holds at its lightness):
    the faintest step moved in lightness until it lies G_FLOOR from bg, the densest
    at today's lightness unless the two lie closer than 7 * G_STEP, and the steps
    between evenly spaced in lightness"""
    steps = [lch(x256(n)) for n in codes]
    share = [min(1.0, C / cmax(L, H)) if cmax(L, H) > 0 else 0 for L, C, H in steps]
    def at(i, L):
        h = warm(hue, L)
        return from_lch(L, share[i] * cmax(L, h), h)
    toward = 1 if lum(bg) < 0.18 else -1              # denser is lighter on dark, darker on light
    L0 = steps[0][0]
    while okdist(at(0, L0), bg) < G_FLOOR and 0 < L0 < 1:
        L0 += 0.002 * toward
    L7 = steps[-1][0]
    if (L7 - L0) * toward < 7 * G_STEP:
        L7 = L0 + toward * 7 * G_STEP
    return [at(i, L0 + (L7 - L0) * i / 7) for i in range(8)]

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
GREY = ("#797c81", "#747474")  # the set's grey on dark and on light, chosen by the architect (feature doc § 12.8)
print("role, today on the profile -> the set, contrast today -> set, lightness moved")
for cls, (out, bg) in sets.items():
    print(f"== {cls} (background {bg})")
    for k, (t, v) in out.items():
        h = hexof(v)
        print(f"  {k:5} {(meta.get(k, ['', ''])[1] or '')[:44]:44} {t} -> {str(v):>7}  {cr(t, bg):5.2f} -> {cr(h, bg):5.2f}  {lch(h)[0]-lch(t)[0]:+.3f}")

for k, (name, v, plain) in FILLS.items():
    print(f"  {k}: the {name} column's highlighted fill -> {v} {x256(v)} (the histogram's highlight), "
          f"apart from its plain fill {plain} {okdist(x256(plain), x256(v)):.3f} against yellow's {SEP:.3f}")

NEWG = {}
print(f"heatmap gradients: faintest step {G_FLOOR:.3f} or more from the background (OKLab), neighbouring steps {G_STEP:.3f} apart or more in lightness")
for name, (gd, gl) in GRADIENTS.items():
    hue = lch(x256(next(c[1] for c in COLUMNS if c[0] == name)))[2]
    NEWG[name] = (gradient(gd, sets["dark"][1], hue), gradient(gl, sets["light"][1], hue))
    for cls, today, new, bg in (("dark", gd, NEWG[name][0], sets["dark"][1]), ("light", gl, NEWG[name][1], sets["light"][1])):
        print(f"  {name:8} {cls:5} today " + " ".join(f"{okdist(x256(n), bg):5.3f}" for n in today))
        print(f"  {'':8} {'':5} set   " + " ".join(f"{okdist(h, bg):5.3f}" for h in new) + "   " + " ".join(new))

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
        f.write(f"grey\tthe set's grey\tevery line and secondary text, in place of s8 and f244 (§ 12.8)\t"
                f"{GREY[0]}\t{GREY[0]}\t{cr(GREY[0], dbg):.2f}\t{GREY[1]}\t{GREY[1]}\t{cr(GREY[1], lbg):.2f}\n")
        for name, (gd, gl) in GRADIENTS.items():
            nd, nl = NEWG[name]
            f.write(f"g{name}\t{','.join(map(str, gd))}|{','.join(map(str, gl))}\t{name} heatmap gradient (today's dark|light)\t"
                    f"{','.join(nd)}\t-\t{cr(nd[0], dbg):.2f}\t{','.join(nl)}\t-\t{cr(nl[0], lbg):.2f}\n")
