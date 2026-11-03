#!/usr/bin/env python3
"""design.py [--hue-tol D] [--sep E] [--soft W] [--out palettes/<name>.tsv]

Designs D1's dark and light sets from the measured backgrounds and colours,
and writes them as a palette file e-palette.pl applies.

Roles. Every colour ltl writes as text on the window's background: the
sixteen scheme colours (basic codes and index 0-15), and ltl's own fixed
256-colour text foregrounds where they fail the floor on a background class,
which take the code of the scheme colour they belong with (success with
green, failure with red, the users count with blue, the percentile lines
with the duration yellow). A fixed code that reads stays as ltl writes it;
one in the class's active heatmap gradient is never remapped. Bars,
histograms and fills stay as ltl draws them.

For each role and class (dark, light):
- target: what the class's default Terminal.app profile draws for it today
  (Clear Dark; Clear Light), read from the profile tables in
  results/terminal-app/; a fixed code's own colour for a fixed role;
- floor: 4.5:1 for a role with text, 3:1 for one drawn only as bars, against
  every hard background of the class; the soft backgrounds (other shipped
  schemes of the class) count as a penalty below the floor;
- kind: a chromatic role keeps its hue (OKLCH hue within --hue-tol degrees of
  the target's) at a chroma of 0.06 or more; the greys (black, white, bright
  black, bright white) stay grey whatever tint the profile gives them, nearest
  the target's lightness;
- choice: the index 16-255 of its kind that reaches the floor, nearest the
  target in OKLCH with lightness, chroma and hue weighted --wl, --wc, --wh
  (the floor sets lightness, so hue is held hardest), plus the soft penalty.
Then distinctness: roles shown side by side (the legend's categories, the
metric columns, success and failure, the greys) are kept at least --sep apart
in OKLab, and the greys keep their order (secondary text further from the
background than nothing, closer than the file details), by searching each
role's best candidates.
"""
import colorsys, itertools, json, math, os, re, sys

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.dirname(os.path.dirname(here))
arg = lambda k, d: type(d)(sys.argv[sys.argv.index(k) + 1]) if k in sys.argv else d
HUE_TOL, SEP, SOFT = arg("--hue-tol", 25.0), arg("--sep", 0.08), arg("--soft", 0.25)
OUT = arg("--out", os.path.join(here, "palettes", "candidate.tsv"))

src = open(os.path.join(root, "ltl")).read()
xterm16 = [tuple(map(int, t)) for t in re.findall(r"\[\s*(\d+),\s*(\d+),\s*(\d+)\s*\]",
           re.search(r"my @notice_xterm16 = \((.*?)\);", src, re.S).group(1))]

def rgb(n):
    if n < 16: return xterm16[n]
    if n >= 232: g = 8 + 10*(n-232); return (g, g, g)
    n -= 16; lv = (0, 95, 135, 175, 215, 255); return (lv[n//36], lv[n//6 % 6], lv[n % 6])
def lin(v):
    v /= 255; return v/12.92 if v <= 0.04045 else ((v+0.055)/1.055)**2.4
def lum(c):
    r, g, b = map(lin, c); return 0.2126*r + 0.7152*g + 0.0722*b
def cr(a, b):
    x, y = sorted((lum(a), lum(b)), reverse=True); return (x+0.05)/(y+0.05)
def oklab(c):
    r, g, b = map(lin, c)
    l = (0.4122214708*r + 0.5363325363*g + 0.0514459929*b) ** (1/3)
    m = (0.2119034982*r + 0.6806995451*g + 0.1073969566*b) ** (1/3)
    s = (0.0883024619*r + 0.2817188376*g + 0.6299787005*b) ** (1/3)
    return (0.2104542553*l + 0.7936177850*m - 0.0040720468*s,
            1.9779984951*l - 2.4285922050*m + 0.4505937099*s,
            0.0259040371*l + 0.7827717662*m - 0.8086757660*s)
def de(p, q): return math.dist(p, q)
from functools import lru_cache
oklab = lru_cache(maxsize=None)(oklab)
lum = lru_cache(maxsize=None)(lum)
def lch(c):
    L, a, b = oklab(c); return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360
def hexc(c): return "#%02x%02x%02x" % c

def table(name):
    return open(os.path.join(here, "results", "terminal-app", f"profile-{name}.txt")).read()
def background(name):
    h = re.search(r"#([0-9a-f]{6})", table(name).splitlines()[0]).group(1)
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
def drawn(name):
    """the colour each scheme index 0-15 is drawn in (group B of the table)"""
    out = {}
    for m in re.finditer(r"^\s+38;5;(\d+) #([0-9a-f]{6})\s+\d+ #", table(name), re.M):
        n = int(m.group(1))
        if n < 16: out[n] = tuple(int(m.group(2)[i:i+2], 16) for i in (0, 2, 4))
    return out

CLASSES = {
    "dark": dict(defaults=["Clear-Dark"], hard=["Clear-Dark", "Basic", "Pro", "Homebrew"], soft=[],
                 gradient={58, 94, 136, 142, 178, 184, 220, 226}),
    "light": dict(defaults=["Clear-Light"], hard=["Clear-Light"] + (["Man-Page", "Novel"] if "--light-all" in sys.argv else []),
                  soft=[] if "--light-all" in sys.argv else ["Man-Page", "Novel"],
                  gradient={230, 229, 228, 227, 220, 214, 208, 202}),
}
NAMES = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white", "bright black", "bright red", "bright green",
         "bright yellow", "bright blue", "bright magenta", "bright cyan", "bright white"]
USE = {1: "5xx, ERROR", 2: "bytes, 2xx", 3: "4xx, WARN", 4: "users column, file index", 5: "3xx", 6: "count column",
       7: "file details", 8: "rules, headings, options line", 9: "per-minute rates", 11: "duration values",
       14: "message-table titles", 15: "notice pick"}
# ltl's fixed foregrounds on the window's background, and what they draw
# each with the scheme colour it belongs with, whose code it takes in a set
FIXED = {34: ("success %", "text", "s2"), 111: ("users count", "text", "s4"),
         160: ("failure %", "text", "s1"), 184: ("percentile lines", "text", "s11")}
GREYS = {0, 7, 8, 15}
GROUPS = [("legend categories", ["s1", "s2", "s3", "s5", "s6"]), ("metric columns", ["s11", "s2", "s6", "s4"]),
          ("success, failure", ["f34", "f160"])]

W_L, W_C, W_H = arg("--wl", 0.5), arg("--wc", 1.0), arg("--wh", 2.0)
def lch_of_lab(p):
    L, a, b = p; return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360
def weighted(x, target):
    """distance in OKLCH with lightness, chroma and hue weighted: the floor
    sets lightness, so hue is held hardest"""
    L1, C1, H1 = lch(x); L2, C2, H2 = lch_of_lab(target)
    dh = 2 * math.sqrt(max(C1 * C2, 0)) * math.sin(math.radians(((H1 - H2 + 180) % 360 - 180) / 2))
    # duller than the target costs fully, more vivid a third: a set should
    # not be muddier than the scheme it replaces
    dc = (C1 - C2) if C1 < C2 else (C1 - C2) / 3
    return math.sqrt((W_L * (L1 - L2)) ** 2 + (W_C * dc) ** 2 + (W_H * dh) ** 2)
def candidates(role, cls, target, ident, floor, grey=False):
    c = CLASSES[cls]
    hard = [background(p) for p in c["hard"]]
    soft = [background(p) for p in c["soft"]]
    L0, C0, H0 = lch_of_lab(target) if lch_of_lab(target)[1] >= 0.03 else lch(ident)
    out = []
    for n in range(16, 256):
        x = rgb(n); L, C, H = lch(x)
        if grey or C0 < 0.03:
            if C > 0.02: continue
        else:
            dh = abs(H - H0); dh = min(dh, 360 - dh)
            if dh > HUE_TOL or C < 0.06: continue
        if min(cr(x, b) for b in hard) < floor: continue
        pen = sum(max(0.0, floor - cr(x, b)) for b in soft)
        out.append(((abs(L - L0) if grey else weighted(x, target)) + SOFT * pen / 10, n))
    return sorted(out)

def design(cls):
    c = CLASSES[cls]
    hard = [background(p) for p in c["hard"]]
    roles = {}
    for i in range(1, 16):
        cols = [drawn(p)[i] for p in c["defaults"]]
        target = tuple(sum(oklab(x)[k] for x in cols) / len(cols) for k in range(3))
        roles[f"s{i}"] = dict(target=target, ident=xterm16[i], floor=4.5, use=USE.get(i, ""), name=NAMES[i], grey=i in GREYS)
    for k, r in roles.items():
        r["cands"] = candidates(k, cls, r["target"], r["ident"], r["floor"], r["grey"])[:8]
        if not r["cands"]: raise SystemExit(f"{cls} {k}: no candidate")
    # distinctness and grey order: search the best candidates, cheapest first
    keys = list(roles)
    pairs = [(a, b) for _, g in GROUPS for a, b in itertools.combinations(g, 2) if a in roles and b in roles]
    def ok(pick):
        for a, b in pairs:
            if a in pick and b in pick and de(oklab(rgb(pick[a])), oklab(rgb(pick[b]))) < SEP: return False
        if all(k in pick for k in ("s8", "s7")):
            bgL = sum(lch(b)[0] for b in hard) / len(hard)
            d8, d7 = abs(lch(rgb(pick["s8"]))[0] - bgL), abs(lch(rgb(pick["s7"]))[0] - bgL)
            if not d8 + 0.10 <= d7: return False
        return True
    # only roles that share a constraint are searched; the rest take their best
    bound = sorted({x for p in pairs for x in p} | ({"s7", "s8"} & set(roles)), key=lambda k: len(roles[k]["cands"]))
    pick = {k: roles[k]["cands"][0][1] for k in keys if k not in bound}
    best = [None, 1e9]
    def search(i, cost):
        if cost >= best[1]: return
        if i == len(bound): best[:] = [dict(pick), cost]; return
        k = bound[i]
        for d, n in roles[k]["cands"][:6]:
            pick[k] = n
            if ok(pick): search(i + 1, cost + d)
            del pick[k]
    search(0, 0.0)
    if best[0] is None: raise SystemExit(f"{cls}: no set meets the distinctness and grey order")
    for k, n in best[0].items():
        roles[k]["code"] = n
    # a fixed code that fails the floor takes its sibling's code
    for n, (use, kind, sib) in FIXED.items():
        if n in c["gradient"] or min(cr(rgb(n), b) for b in hard) >= 4.5: continue
        roles[f"f{n}"] = dict(code=roles[sib]["code"], use=use, name=f"38;5;{n}")
    return roles

sets = {cls: design(cls) for cls in CLASSES}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    f.write(f"# D1 sets by design.py: hue tolerance {HUE_TOL}, separation {SEP}, soft weight {SOFT}, weights L {W_L} C {W_C} H {W_H}\n")
    for cls, c in CLASSES.items():
        f.write(f"# {cls}: targets from {', '.join(c['defaults'])}; floor on {', '.join(c['hard'])}; penalty on {', '.join(c['soft']) or 'none'}\n")
    f.write("# source\tname\tuse\tdark\tdark_rgb\tdark_min\tlight\tlight_rgb\tlight_min\n")
    rows = ["s0"] + [f"s{i}" for i in range(1, 16)] + [f"f{n}" for n in FIXED]
    for k in rows:
        cells = []
        for cls in CLASSES:
            hard = [background(p) for p in CLASSES[cls]["hard"]]
            if k == "s0": n = 16
            elif k in sets[cls]: n = sets[cls][k]["code"]
            else: cells += ["-", "", ""]; continue
            cells += [str(n), hexc(rgb(n)), f"{min(cr(rgb(n), b) for b in hard):.2f}"]
        if k.startswith("f") and cells[0] == "-" and cells[3] == "-": continue
        name = "black (fill text)" if k == "s0" else (NAMES[int(k[1:])] if k.startswith("s") else f"38;5;{k[1:]}")
        use = "text over a fill" if k == "s0" else (USE.get(int(k[1:]), "") if k.startswith("s") else FIXED[int(k[1:])][0] + f" (as {FIXED[int(k[1:])][2]})")
        f.write("\t".join([k, name, use] + cells) + "\n")
print(open(OUT).read(), end="")
