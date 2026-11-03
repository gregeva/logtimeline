#!/usr/bin/env python3
"""design.py [--out palettes/<name>.tsv] [options]

Designs candidate dark and light sets of D1 for every surface in scope
(features/749-terminal-colour-codes.md § 10) from the measured backgrounds
and colours, and writes them as a palette file e-palette.py applies. The
histogram and the heatmap keep their colours and are not designed here.

Roles, each designed for the dark and the light class:
- s<i>  the sixteen scheme colours as text on the window's background;
- f<N>  ltl's own fixed 256-colour text codes on the window's background
        where they fail the floor in a class: the one standing for a scheme
        colour takes that colour's code (success with green, failure with
        red, the users count and format number with blue, the notice cyan
        with cyan); the others (the user-defined columns' orange, pink, teal
        and purple, the classification states) are designed on their own hue;
- b<N>  the fills of the bars, plain and highlighted, per column colour of
        @column_colors (sliced from ltl);
- t<N>  the text over each fill: black or white, the same on a column's
        plain and highlighted fills;
- e     bold over the default foreground (help and explain headings, the
        error line).

For text on the window's background (s, f):
- target: what the class's default Terminal.app profile draws for it today
  (Clear Dark; Clear Light), or a fixed code's own colour;
- floor: 4.5:1 against every hard background of the class; the soft ones
  count as a penalty;
- kind: a chromatic role keeps its hue (OKLCH, within --hue-tol degrees of
  the target's) at a chroma of 0.06 or more; the greys stay grey;
- choice: nearest the target in OKLCH, hue weighted --wh, chroma --wc,
  lightness --wl, duller than the target costing three times more vivid;
- distinctness between roles shown together (the legend's categories, the
  classification states) and between neighbouring metric columns, and the
  greys' order.

For fills (b, t):
- a fill stays visible as a bar: --fill-floor (3:1) against every hard
  background of the class, plain and highlighted;
- it keeps its hue, nearer its own column's than any other column's: within
  --fill-hue-tol of the scheme colour of the same
  name as the class's default profile draws it (yellow, green, cyan, blue,
  magenta, red), so fills and text share a family; within --hue-tol of
  today's fill for orange, pink, teal and purple;
- a column's highlighted fill stands out from its plain one: at least
  --pair-sep apart in OKLab, and further from the background in contrast or
  more vivid;
- text over a column's fills reads at 4.5:1 in black or white, the same on
  both where any pair allows it, otherwise each fill's own;
- the plain fills of different columns stay --sep apart, and so do the
  highlighted ones;
- choice: nearest today's fills, keeping today's where they already pass.
"""
import itertools, math, os, re, sys
from functools import lru_cache

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.dirname(os.path.dirname(here))
arg = lambda k, d: type(d)(sys.argv[sys.argv.index(k) + 1]) if k in sys.argv else d
HUE_TOL, SEP, SOFT = arg("--hue-tol", 25.0), arg("--sep", 0.08), arg("--soft", 0.25)
W_L, W_C, W_H = arg("--wl", 0.5), arg("--wc", 1.0), arg("--wh", 2.0)
FILL_FLOOR, PAIR_SEP, GREY_GAP = arg("--fill-floor", 3.0), arg("--pair-sep", 0.10), arg("--grey-gap", 0.10)
FILL_HUE_TOL = arg("--fill-hue-tol", 30.0)
# a column's fills take their hue from the scheme colour of the same name,
# as the class's default profile draws it; the others keep today's fill hue
FILL_SIBLING = {"yellow": 3, "green": 2, "cyan": 6, "blue": 4, "magenta": 5, "red": 1}
OUT = arg("--out", os.path.join(here, "palettes", "candidate.tsv"))

src = open(os.path.join(root, "ltl")).read()
xterm16 = [tuple(map(int, t)) for t in re.findall(r"\[\s*(\d+),\s*(\d+),\s*(\d+)\s*\]",
           re.search(r"my @notice_xterm16 = \((.*?)\);", src, re.S).group(1))]
column_colors = [(m.group(1), int(m.group(3)), int(m.group(2))) for m in re.finditer(
    r"name => '(\w+)',\s+highlighted_bg => \"\\033\[48;5;(\d+)m.*?plain_bg => \"\\033\[48;5;(\d+)m", src)]
assert len(column_colors) == 10, column_colors

@lru_cache(maxsize=None)
def rgb(n):
    if n < 16: return xterm16[n]
    if n >= 232: g = 8 + 10*(n-232); return (g, g, g)
    n -= 16; lv = (0, 95, 135, 175, 215, 255); return (lv[n//36], lv[n//6 % 6], lv[n % 6])
def lin(v):
    v /= 255; return v/12.92 if v <= 0.04045 else ((v+0.055)/1.055)**2.4
@lru_cache(maxsize=None)
def lum(c):
    r, g, b = map(lin, c); return 0.2126*r + 0.7152*g + 0.0722*b
def cr(a, b):
    x, y = sorted((lum(a), lum(b)), reverse=True); return (x+0.05)/(y+0.05)
@lru_cache(maxsize=None)
def oklab(c):
    r, g, b = map(lin, c)
    l = (0.4122214708*r + 0.5363325363*g + 0.0514459929*b) ** (1/3)
    m = (0.2119034982*r + 0.6806995451*g + 0.1073969566*b) ** (1/3)
    s = (0.0883024619*r + 0.2817188376*g + 0.6299787005*b) ** (1/3)
    return (0.2104542553*l + 0.7936177850*m - 0.0040720468*s,
            1.9779984951*l - 2.4285922050*m + 0.4505937099*s,
            0.0259040371*l + 0.7827717662*m - 0.8086757660*s)
def de(p, q): return math.dist(p, q)
def lch_of_lab(p):
    L, a, b = p; return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360
def lch(c): return lch_of_lab(oklab(c))
def hexc(c): return "#%02x%02x%02x" % c
def hue_gap(h1, h2):
    d = abs(h1 - h2); return min(d, 360 - d)

def weighted(x, target):
    L1, C1, H1 = lch(x); L2, C2, H2 = lch_of_lab(target)
    dh = 2 * math.sqrt(max(C1 * C2, 0)) * math.sin(math.radians(((H1 - H2 + 180) % 360 - 180) / 2))
    dc = (C1 - C2) if C1 < C2 else (C1 - C2) / 3
    return math.sqrt((W_L * (L1 - L2)) ** 2 + (W_C * dc) ** 2 + (W_H * dh) ** 2)

def table(name):
    return open(os.path.join(here, "results", "terminal-app", f"profile-{name}.txt")).read()
def background(name):
    h = re.search(r"#([0-9a-f]{6})", table(name).splitlines()[0]).group(1)
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
def drawn(name):
    out = {}
    for m in re.finditer(r"^\s+38;5;(\d+) #([0-9a-f]{6})\s+\d+ #", table(name), re.M):
        n = int(m.group(1))
        if n < 16: out[n] = tuple(int(m.group(2)[i:i+2], 16) for i in (0, 2, 4))
    return out

CLASSES = {
    "dark": dict(defaults=["Clear-Dark"], hard=["Clear-Dark", "Basic", "Pro", "Homebrew"], soft=[]),
    "light": dict(defaults=["Clear-Light"], hard=["Clear-Light"], soft=["Man-Page", "Novel"]),
}
NAMES = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white", "bright black", "bright red", "bright green",
         "bright yellow", "bright blue", "bright magenta", "bright cyan", "bright white"]
USE = {1: "5xx, ERROR, FATAL, P999", 2: "bytes, 2xx, file marks", 3: "4xx, WARN, P95", 4: "users column, file index, pause prompt fill",
       5: "3xx", 6: "count column, P50", 7: "file details, notice text", 8: "rules, headings, options line, notice frame",
       9: "per-minute failure rates", 10: "progress lines", 11: "duration values, P99, table titles", 14: "message-table titles",
       15: "notice pick"}
GREYS = {0, 7, 8, 15}
# ltl's fixed text codes on the window's background: what they draw, and the
# scheme colour they stand for (None: designed on their own hue)
FIXED = {34: ("success %, success state", "s2"), 160: ("failure %, failure state", "s1"), 111: ("users count, format number", "s4"),
         44: ("notice category cyan", "s6"), 178: ("classification state (amber)", None), 135: ("classification state (violet)", None),
         208: ("orange column values", None), 213: ("pink column values", None), 43: ("teal column values", None),
         93: ("purple column values", None)}
# colours shown together: every pair within a group, and the metric columns
# with their neighbours (in @column_colors order)
GROUPS = [("legend categories", ["s1", "s2", "s3", "s5", "s6"]), ("classification", ["f34", "f160", "f178", "f135"])]
CHAIN = ["s11", "s2", "s6", "s4", "s5", "s1", "f208", "f213", "f43", "f93"]

def text_candidates(cls, target, ident, grey):
    c = CLASSES[cls]
    hard = [background(p) for p in c["hard"]]; soft = [background(p) for p in c["soft"]]
    L0, C0, H0 = lch_of_lab(target) if lch_of_lab(target)[1] >= 0.03 else lch(ident)
    out = []
    for n in range(16, 256):
        x = rgb(n); L, C, H = lch(x)
        if grey or C0 < 0.03:
            if C > 0.02: continue
        elif hue_gap(H, H0) > HUE_TOL or C < 0.06: continue
        if min(cr(x, b) for b in hard) < 4.5: continue
        pen = sum(max(0.0, 4.5 - cr(x, b)) for b in soft)
        out.append(((abs(L - L0) if grey else weighted(x, target)) + SOFT * pen / 10, n))
    return sorted(out)

def design_text(cls):
    c = CLASSES[cls]
    hard = [background(p) for p in c["hard"]]
    roles = {}
    for i in range(1, 16):
        roles[f"s{i}"] = dict(target=oklab(drawn(c["defaults"][0])[i]), ident=xterm16[i], grey=i in GREYS)
    for n, (use, sib) in FIXED.items():
        if sib: continue
        # a fixed code that reads is kept; it still joins the distinctness check
        if min(cr(rgb(n), b) for b in hard) >= 4.5:
            roles[f"f{n}"] = dict(target=oklab(rgb(n)), ident=rgb(n), grey=False, cands=[(0.0, n)])
        else:
            roles[f"f{n}"] = dict(target=oklab(rgb(n)), ident=rgb(n), grey=False)
    for k, r in roles.items():
        if "cands" not in r:
            r["cands"] = text_candidates(cls, r["target"], r["ident"], r["grey"])[:8]
        if not r["cands"]: raise SystemExit(f"{cls} {k}: no candidate")
    pairs = [(a, b) for _, g in GROUPS for a, b in itertools.combinations(g, 2) if a in roles and b in roles]
    pairs += [(a, b) for a, b in zip(CHAIN, CHAIN[1:]) if a in roles and b in roles]
    bgL = sum(lch(b)[0] for b in hard) / len(hard)
    def ok(pick):
        for a, b in pairs:
            if a in pick and b in pick and de(oklab(rgb(pick[a])), oklab(rgb(pick[b]))) < SEP: return False
        if "s8" in pick and "s7" in pick:
            if not abs(lch(rgb(pick["s8"]))[0] - bgL) + GREY_GAP <= abs(lch(rgb(pick["s7"]))[0] - bgL): return False
        return True
    bound = sorted({x for p in pairs for x in p} | {"s7", "s8"}, key=lambda k: len(roles[k]["cands"]))
    pick = {k: roles[k]["cands"][0][1] for k in roles if k not in bound}
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
    if best[0] is None: raise SystemExit(f"{cls}: no text set meets distinctness and grey order")
    out = {k: n for k, n in best[0].items() if not (k.startswith("f") and n == int(k[1:]))}
    for n, (use, sib) in FIXED.items():
        if sib and min(cr(rgb(n), b) for b in hard) < 4.5: out[f"f{n}"] = out[sib]
    return out

def design_fills(cls):
    c = CLASSES[cls]
    hard = [background(p) for p in c["hard"]]
    def fill_ok(n): return min(cr(rgb(n), b) for b in hard) >= FILL_FLOOR
    # each column's identity hue; a candidate belongs to the column whose
    # identity hue is nearest its own, so orange does not slide into red
    ident = {}
    for name, p0, h0 in column_colors:
        sib = FILL_SIBLING.get(name)
        ident[name] = lch(drawn(c["defaults"][0])[sib])[2] if sib else lch(rgb(p0))[2]
    def cands(today, name, nearest=True):
        H0 = ident[name]
        tol = FILL_HUE_TOL if name in FILL_SIBLING else HUE_TOL
        out = []
        for n in range(16, 256):
            L, C, H = lch(rgb(n))
            if hue_gap(H, H0) > tol or C < 0.06 or not fill_ok(n): continue
            if nearest and min(ident, key=lambda k: hue_gap(H, ident[k])) != name: continue
            out.append((0.0 if n == today else weighted(rgb(n), oklab(rgb(today))), n))
        out = sorted(out)[:12]
        # a column whose hue sits close to another's (teal by cyan) may have
        # nothing nearer its own: then the tolerance alone decides
        return out if out or not nearest else cands(today, name, False)
    def text_for(p, h):
        best = max((16, 231), key=lambda t: min(cr(rgb(t), rgb(p)), cr(rgb(t), rgb(h))))
        return best, min(cr(rgb(best), rgb(p)), cr(rgb(best), rgb(h)))
    def own_text(n):
        return max((16, 231), key=lambda t: cr(rgb(t), rgb(n)))
    options = {}
    def pairs_for(name, p0, h0, nearest):
        opts, split = [], []
        for (dp, p), (dh, h) in itertools.product(cands(p0, name, nearest), cands(h0, name, nearest)):
            if p == h or de(oklab(rgb(p)), oklab(rgb(h))) < PAIR_SEP: continue
            # the highlighted fill stands out: more contrast with the background, or more vivid
            if min(cr(rgb(h), b) for b in hard) <= min(cr(rgb(p), b) for b in hard) and lch(rgb(h))[1] <= lch(rgb(p))[1] + 0.02: continue
            t, tc = text_for(p, h)
            if tc >= 4.5: opts.append((dp + dh, p, h, t, t))
            else: split.append((dp + dh, p, h, own_text(p), own_text(h)))
        # no pair shares a text colour: each fill takes its own black or white
        return opts or split
    for name, p0, h0 in column_colors:
        # a column whose hue sits close to another's (teal by cyan) may have no
        # pair nearer its own hue: then the tolerance alone decides
        opts = pairs_for(name, p0, h0, True) or pairs_for(name, p0, h0, False)
        if not opts: raise SystemExit(f"{cls} {name}: no fill pair")
        options[name] = sorted(opts)[:8]
    names = [n for n, _, _ in column_colors]
    best = [None, 1e9]
    def search(i, pick, cost):
        if cost >= best[1]: return
        if i == len(names): best[:] = [dict(pick), cost]; return
        for o in options[names[i]]:
            if all(de(oklab(rgb(o[1])), oklab(rgb(q[1]))) >= SEP and de(oklab(rgb(o[2])), oklab(rgb(q[2]))) >= SEP for q in pick.values()):
                pick[names[i]] = o; search(i + 1, pick, cost + o[0]); del pick[names[i]]
    search(0, {}, 0.0)
    if best[0] is None: raise SystemExit(f"{cls}: no fill set keeps the columns apart")
    out = {}
    for name, p0, h0 in column_colors:
        _, p, h, tp, th = best[0][name]
        out[f"b{p0}"], out[f"b{h0}"] = p, h
        out[f"t{p0}"], out[f"t{h0}"] = tp, th
    return out

if __name__ == "__main__":
    sets = {cls: {**design_text(cls), **design_fills(cls), "e": 231 if cls == "dark" else 16} for cls in CLASSES}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        f.write(f"# D1 candidate sets by design.py (every surface): hue tolerance {HUE_TOL}, separation {SEP}, soft {SOFT}, "
                f"weights L {W_L} C {W_C} H {W_H}, fill floor {FILL_FLOOR}, pair separation {PAIR_SEP}, grey gap {GREY_GAP}\n")
        for cls, c in CLASSES.items():
            f.write(f"# {cls}: targets from {', '.join(c['defaults'])}; floors on {', '.join(c['hard'])}; penalty on {', '.join(c['soft']) or 'none'}\n")
        f.write("# source\tname\tuse\tdark\tdark_rgb\tdark_min\tlight\tlight_rgb\tlight_min\n")
        rows = [("s0", "black", "text over a fill: see t")] + [(f"s{i}", NAMES[i], USE.get(i, "")) for i in range(1, 16)]
        rows += [(f"f{n}", f"38;5;{n}", u + (f" (as {s})" if s else "")) for n, (u, s) in FIXED.items()]
        for name, p0, h0 in column_colors:
            rows += [(f"b{p0}", f"48;5;{p0}", f"{name} plain fill"), (f"b{h0}", f"48;5;{h0}", f"{name} highlighted fill"),
                     (f"t{p0}", "text", f"over the {name} plain fill"), (f"t{h0}", "text", f"over the {name} highlighted fill")]
        rows += [("e", "bold", "bold over the default foreground")]
        seen = set()
        for k, name, use in rows:
            if k in seen: continue
            seen.add(k)
            cells = []
            for cls in CLASSES:
                hard = [background(p) for p in CLASSES[cls]["hard"]]
                n = 16 if k == "s0" else sets[cls].get(k)
                if n is None: cells += ["-", "", ""]; continue
                cells += [str(n), hexc(rgb(n)), f"{min(cr(rgb(n), b) for b in hard):.2f}"]
            if cells[0] == "-" and cells[3] == "-": continue
            f.write("\t".join([k, name, use] + cells) + "\n")
    print(open(OUT).read(), end="")
