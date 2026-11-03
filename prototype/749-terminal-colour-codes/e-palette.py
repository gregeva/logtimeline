#!/usr/bin/env python3
"""e-palette.py <palette.tsv> dark|light < ltl-output.ans > rewritten.ans

D1's rewrite of ltl's output for a known background, cell by cell, by the
roles of a palette file design.py writes:
- the histogram block (from its "Distribution" title to its percentile
  lines) keeps every code ltl writes;
- in the heatmap's columns (right of the timeline's last separator, from the
  header to the scale footer), a cell drawn in a step of the heatmap's
  gradient takes the set's colour for that step (g<name>); every other code
  there, the highlight's background and the percentile markers, is kept;
- a fill (b<N>) takes the set's fill; a scheme background (0;44, the pause
  prompt) takes the set's code for that colour;
- a bar glyph drawn in a fill's colour (the bar's own glyph, a half block
  between two fills) follows that fill;
- text over a fill takes the fill's text colour (t<N>), or black or white,
  whichever reads, on a fill the palette has no text colour for;
- a scheme colour on the window's background takes the set's code (s<i>);
- one of ltl's fixed text codes the palette remaps takes its code (f<N>);
- bold over the default foreground takes the emphasis colour (e).
A palette value is a 256-colour index or a 24-bit #rrggbb.
Every character and attribute is kept. The output is written cell by cell
with its own codes, which draws the same; the non-standard 109 is not
written. On standard error: how many cells each role changed.
"""
import importlib.util, os, re, sys
from collections import Counter
here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("ro", os.path.join(here, "read-output.py"))
ro = importlib.util.module_from_spec(spec); spec.loader.exec_module(ro)

def load(path, cls):
    """a palette file's column for this class: role -> value; a heatmap gradient
    (g<name>) -> {today's code: the set's colour}"""
    col = 3 if cls == "dark" else 6
    pal = {}
    for line in open(path):
        if line.startswith("#"): continue
        f = line.rstrip("\n").split("\t")
        if len(f) <= col or f[col] in ("-", ""): continue
        if f[0].startswith("g"):        # a heatmap gradient: today's codes for this class -> the set's 8 colours
            today = [int(x) for x in f[1].split("|")[0 if cls == "dark" else 1].split(",")]
            pal[f[0]] = dict(zip(today, f[col].split(",")))
        else:
            pal[f[0]] = f[col] if f[col].startswith("#") else int(f[col])
    return pal

def rgb(n):
    if n >= 232: g = 8 + 10*(n-232); return (g, g, g)
    n -= 16; lv = (0, 95, 135, 175, 215, 255); return (lv[n//36], lv[n//6 % 6], lv[n % 6])
def lum(c):
    f = lambda v: (v/255)/12.92 if v/255 <= 0.04045 else ((v/255+0.055)/1.055)**2.4
    r, g, b = map(f, c); return 0.2126*r + 0.7152*g + 0.0722*b
def cr(a, b):
    x, y = sorted((lum(a), lum(b)), reverse=True); return (x+0.05)/(y+0.05)

def code(prefix, v):
    """the SGR parameters for a palette value: a 256-colour index or a 24-bit #rrggbb"""
    if isinstance(v, str): return "%s;2;%d;%d;%d" % (prefix, int(v[1:3], 16), int(v[3:5], 16), int(v[5:7], 16))
    return "%s;5;%d" % (prefix, v)

def index(code):
    p = code.split(";")
    if len(p) == 1:
        v = int(p[0]); return v - 30 if v < 38 else v - 40 if v < 48 else v - 90 + 8 if v < 98 else v - 100 + 8
    return int(p[2])
def num(code, prefix):
    return int(code[5:]) if code.startswith(prefix + ";5;") else None

def regions(text):
    """the histogram block's rows and the heatmap's cells, as two predicates"""
    lines = [re.sub(r"\x1b\[[0-9;]*m", "", l) for l in text.split("\n")]
    out = set()
    for i, l in enumerate(lines):
        if "Distribution" in l:
            j = i
            while j + 1 < len(lines) and not re.search(r"P50:", lines[j]): j += 1
            while j + 1 < len(lines) and re.search(r"P50:", lines[j + 1]): j += 1
            out |= {(r, None) for r in range(i, j + 1)}
        if "heatmap [" in l:
            foot = next((k for k in range(i + 1, len(lines)) if "┴" in lines[k]), None)
            if foot is None: continue
            sep = lines[foot].index("┴")
            out |= {(r, c) for r in range(i, foot + 1) for c in range(sep + 1, len(lines[r]) + 2)}
    rows = {r for r, c in out if c is None}
    cells = {(r, c) for r, c in out if c is not None}
    return (lambda r, c: r in rows), (lambda r, c: (r, c) in cells)

def masks(text):
    """the cells whose codes stay as ltl writes them: the histogram block, and the
    heatmap's columns when the palette carries no heatmap gradients"""
    hist, heat = regions(text)
    return lambda r, c: hist(r, c) or heat(r, c)

def heatmap_map(cells, pal):
    """the gradient the heatmap draws in (the one holding most of its cells' codes):
    today's code -> the set's colour, or {} when the palette has none"""
    seen = Counter(num(st["fg"], "38") for g, st in cells if ro.graphic(g))
    best = max((k for k in pal if k.startswith("g")), key=lambda k: sum(n for c, n in seen.items() if c in pal[k]), default=None)
    return pal[best] if best else {}

def remap(st, glyph, pal, count):
    st = dict(st)
    fg, bg = st["fg"], st["bg"]
    graphic = ro.graphic(glyph)
    fill, ink = num(bg, "48"), num(fg, "38")
    if ro.scheme(bg) and f"s{index(bg)}" in pal:
        st["bg"] = code("48", pal[f"s{index(bg)}"]); count["scheme background"] += 1
    elif fill is not None and f"b{fill}" in pal:
        st["bg"] = code("48", pal[f"b{fill}"]); count["fill"] += 1
    newfill = num(st["bg"], "48")
    if graphic and ink is not None and f"b{ink}" in pal:
        st["fg"] = code("38", pal[f"b{ink}"]); count["bar glyph"] += 1
    elif newfill is not None and newfill >= 16 and not graphic:
        t = pal.get(f"t{fill}") if fill is not None and f"b{fill}" in pal else None
        if t is None:
            f = rgb(newfill); t = 16 if cr((0, 0, 0), f) >= cr((255, 255, 255), f) else 231
        st["fg"] = code("38", t); count["text over a fill"] += 1
    elif ro.scheme(fg) and f"s{index(fg)}" in pal:
        st["fg"] = code("38", pal[f"s{index(fg)}"]); count[f"s{index(fg)}"] += 1
    elif ink is not None and f"f{ink}" in pal:
        st["fg"] = code("38", pal[f"f{ink}"]); count[f"f{ink}"] += 1
    elif fg == "def" and st["bold"] and "e" in pal:
        st["fg"] = code("38", pal["e"]); count["emphasis"] += 1
    return st

def sgr(st):
    p = [k for k, on in (("1", st["bold"]), ("2", st["faint"]), ("4", st["ul"]), ("7", st["rev"])) if on]
    if st["fg"] != "def": p.append(st["fg"])
    if st["bg"] != "def": p.append(st["bg"])
    return "\x1b[0m" + ("\x1b[" + ";".join(p) + "m" if p else "")

def rewrite(text, pal, count):
    hist, heat = regions(text)
    cells = ro.parse(text)
    gmap = heatmap_map([(g, st) for r, c, g, st in cells if heat(r, c)], pal)
    rows = {}
    for r, c, g, st in cells:
        if hist(r, c): new = st
        elif heat(r, c):
            new = dict(st)
            ink = num(st["fg"], "38")
            if gmap and ro.graphic(g) and ink in gmap:
                new["fg"] = code("38", gmap[ink]); count["heatmap cell"] += 1
        else: new = remap(st, g, pal, count)
        rows.setdefault(r, []).append((g, new))
    out = []
    for r in range(len(text.split("\n"))):
        line, prev = [], None
        for g, st in rows.get(r, []):
            key = tuple(sorted(st.items()))
            if key != prev:
                line.append(sgr(st)); prev = key
            line.append(g)
        if prev is not None: line.append("\x1b[0m")
        out.append("".join(line))
    return "\n".join(out)

if __name__ == "__main__":
    pal = load(sys.argv[1], sys.argv[2])
    count = Counter()
    sys.stdout.write(rewrite(sys.stdin.read(), pal, count))
    sys.stderr.write(f"e-palette.py {sys.argv[2]}: " + " ".join(f"{k}:{v}" for k, v in sorted(count.items())) + "\n")
