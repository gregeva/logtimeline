#!/usr/bin/env python3
"""two-sets.py <name>=<profile.txt>[,<profile.txt>...] ...

For each named set of measured backgrounds (read from the header line of the
profile-*.txt tables report.py writes), the best index 16-231 per hue: the one
whose lowest contrast across the set's backgrounds is highest, how many of the
hue's indexes reach 4.5:1 on every background in the set, and what the fixed
code for that hue (to256.pl's) reaches; then which greys of the ramp reach
4.5:1 on all. A set of only dark backgrounds, or only light ones, is what a colour
set chosen per background would face; a set of both is what one set for every
background faces.
"""
import colorsys, re, sys

def lum(c):
    f = lambda v: (v/255)/12.92 if v/255 <= 0.04045 else ((v/255+0.055)/1.055)**2.4
    r, g, b = map(f, c); return 0.2126*r + 0.7152*g + 0.0722*b

def cr(a, b):
    x, y = sorted((lum(a), lum(b)), reverse=True); return (x+0.05)/(y+0.05)

def rgb(n):
    if n >= 232: g = 8 + 10*(n-232); return (g, g, g)
    n -= 16; lv = (0, 95, 135, 175, 215, 255); return (lv[n//36], lv[n//6 % 6], lv[n % 6])

def background(path):
    m = re.search(r"background beside group A: #([0-9a-f]{6})", open(path).readline())
    h = m.group(1); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

# the hue bands and saturation floor are fixed-contrast.py's
hues = {"yellow": (40, 70), "green": (90, 160), "cyan": (170, 200), "blue": (210, 250),
        "magenta": (280, 320), "red": (345, 15), "orange": (20, 40)}
# the fixed code per hue: to256.pl's @fixed for the basic code ltl writes in
# that hue (93, 32, 36, 34, 35, 31); orange is ltl's own 38;5;208
# (@column_colors), already a fixed code
fixed = {"yellow": 226, "green": 40, "cyan": 44, "blue": 21, "magenta": 164, "red": 160, "orange": 208}

for arg in sys.argv[1:]:
    name, files = arg.split("=", 1)
    files = files.split(",")
    bgs = [background(f) for f in files]
    label = ", ".join(re.sub(r"^profile-|\.txt$", "", f.rsplit("/", 1)[-1]) for f in files)
    print(f"== {name}: {label}")
    for hue, (a, b) in hues.items():
        cands = []
        for n in range(16, 232):
            c = rgb(n); h, s, _ = colorsys.rgb_to_hsv(*(x/255 for x in c)); h *= 360
            if s < 0.5 or not ((a <= h <= b) if a < b else (h >= a or h <= b)): continue
            cands.append((min(cr(c, bg) for bg in bgs), n, c))
        cands.sort(reverse=True)
        ok = [x for x in cands if x[0] >= 4.5]
        m, n, c = cands[0]
        pick = min(cr(rgb(fixed[hue]), bg) for bg in bgs)
        eg = (" (" + ", ".join(str(x[1]) for x in ok[:6]) + ")") if ok else ""
        print(f"  {hue:8} best 38;5;{n:<3} #{c[0]:02x}{c[1]:02x}{c[2]:02x} {m:5.2f} | reaching 4.5 on all: {len(ok):2d} of {len(cands):2d}{eg}"
              f" | fixed code {fixed[hue]}: {pick:.2f}")
    print(f"  greys reaching 4.5 on all: {[n for n in range(232, 256) if min(cr(rgb(n), bg) for bg in bgs) >= 4.5] or 'none'}")
