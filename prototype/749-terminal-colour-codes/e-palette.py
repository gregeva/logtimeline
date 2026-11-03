#!/usr/bin/env python3
"""e-palette.py <palette.tsv> dark|light < ltl-output.ans > rewritten.ans

D1's rewrite of ltl's output for a known background, cell by cell: a cell's
scheme colour (a basic code, or palette index 0-15, foreground or background)
takes the set's code for it, except text over a fill, which takes black or
white, whichever reads on that fill (FILLTEXT=keep leaves it to the set); a
text cell whose foreground is one of ltl's fixed codes the palette remaps
(source f<N>), with no fill behind it, takes the set's code; every other
code, every attribute and every character is kept. Fills, bar glyphs and
the glyphs drawn over fills (the timeline's bars, the histograms) are left
as ltl writes them. The output is written cell by cell with its own codes,
which draws the same; the non-standard 109 is not written.
On standard error: how many cells each mapping changed.
"""
import importlib.util, os, sys
from collections import Counter
here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("ro", os.path.join(here, "read-output.py"))
ro = importlib.util.module_from_spec(spec); spec.loader.exec_module(ro)

def load(path, cls):
    scheme, fixed = {}, {}
    col = 3 if cls == "dark" else 6
    for line in open(path):
        if line.startswith("#"): continue
        f = line.rstrip("\n").split("\t")
        if f[col] in ("-", ""): continue
        (scheme if f[0][0] == "s" else fixed)[int(f[0][1:])] = int(f[col])
    return scheme, fixed

def index(code):
    p = code.split(";")
    if len(p) == 1:
        v = int(p[0]); return v - 30 if v < 38 else v - 40 if v < 48 else v - 90 + 8 if v < 98 else v - 100 + 8
    return int(p[2])

FILLTEXT = os.environ.get("FILLTEXT", "contrast")

def rgb(n):
    if n >= 232: g = 8 + 10*(n-232); return (g, g, g)
    n -= 16; lv = (0, 95, 135, 175, 215, 255); return (lv[n//36], lv[n//6 % 6], lv[n % 6])
def lum(c):
    f = lambda v: (v/255)/12.92 if v/255 <= 0.04045 else ((v/255+0.055)/1.055)**2.4
    r, g, b = map(f, c); return 0.2126*r + 0.7152*g + 0.0722*b
def cr(a, b):
    x, y = sorted((lum(a), lum(b)), reverse=True); return (x+0.05)/(y+0.05)

def remap(st, scheme, fixed, count, glyph=" "):
    st = dict(st)
    fill = st["bg"].startswith("48;5;") and int(st["bg"][5:]) >= 16
    if FILLTEXT == "contrast" and fill and ro.scheme(st["fg"]) and not ro.graphic(glyph):
        # text in a scheme colour over a fill reads on the fill, not the
        # window: black or white, whichever has more contrast with it
        f = rgb(int(st["bg"][5:]))
        st["fg"] = "38;5;16" if cr((0, 0, 0), f) >= cr((255, 255, 255), f) else "38;5;231"
        count["fill text"] += 1
    elif ro.scheme(st["fg"]):
        i = index(st["fg"]); st["fg"] = f"38;5;{scheme[i]}"; count[f"s{i}"] += 1
    elif st["fg"].startswith("38;5;") and st["bg"] == "def" and int(st["fg"][5:]) in fixed and not ro.graphic(glyph):
        n = int(st["fg"][5:]); st["fg"] = f"38;5;{fixed[n]}"; count[f"f{n}"] += 1
    if ro.scheme(st["bg"]):
        i = index(st["bg"]); st["bg"] = f"48;5;{scheme[i]}"; count[f"bg s{i}"] += 1
    return st

def sgr(st):
    p = [k for k, on in (("1", st["bold"]), ("2", st["faint"]), ("4", st["ul"]), ("7", st["rev"])) if on]
    if st["fg"] != "def": p.append(st["fg"] if ";" in st["fg"] else st["fg"])
    if st["bg"] != "def": p.append(st["bg"])
    return "\x1b[0m" + ("\x1b[" + ";".join(p) + "m" if p else "")

def rewrite(text, scheme, fixed, count):
    rows = {}
    for r, c, g, st in ro.parse(text):
        rows.setdefault(r, []).append((g, remap(st, scheme, fixed, count, g)))
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
    scheme, fixed = load(sys.argv[1], sys.argv[2])
    count = Counter()
    sys.stdout.write(rewrite(sys.stdin.read(), scheme, fixed, count))
    sys.stderr.write(f"e-palette.py {sys.argv[2]}: " + " ".join(f"{k}:{v}" for k, v in sorted(count.items())) + "\n")
