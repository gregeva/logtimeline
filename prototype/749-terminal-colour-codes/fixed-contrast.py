#!/usr/bin/env python3
"""fixed-contrast.py <analysis.json>...: for the to256.pl mapping, the contrast of
each fixed index with each profile's measured background; then, for the two
Clear profiles, the best single index per hue (highest of the lower of its two
contrasts) and the ceiling any colour can reach on both."""
import colorsys, json, sys
def lum(c):
    f = lambda v: (v/255)/12.92 if v/255 <= 0.04045 else ((v/255+0.055)/1.055)**2.4
    r, g, b = map(f, c); return 0.2126*r + 0.7152*g + 0.0722*b
def cr(a, b):
    x, y = sorted((lum(a), lum(b)), reverse=True); return (x+0.05)/(y+0.05)
def rgb(n):
    if n >= 232: g = 8 + 10*(n-232); return (g, g, g)
    n -= 16; lv = (0, 95, 135, 175, 215, 255); return (lv[n//36], lv[n//6 % 6], lv[n % 6])
bgs = {}
for f in sys.argv[1:]:
    r = json.load(open(f)); s = {(x["id"], x["kind"]): x for x in r["swatches"]}
    h = s[("A:39:plain", "block")]["bg"]; bgs[r["capture"][:-4]] = tuple(int(h[i:i+2], 16) for i in (1, 3, 5))
mapping = [("93 duration", 226), ("32 bytes", 40), ("36 count", 44), ("34 blue", 21), ("35 magenta", 164),
           ("31 red", 160), ("33 WARN", 184), ("90 rules", 244), ("37 white", 254), ("38;5;0 fill text", 16)]
print("Contrast of the fixed index (to256.pl mapping) with each profile's background")
print(f"{'profile':15} " + " ".join(f"{m[0]+'>'+str(m[1]):>18}" for m in mapping))
for p, bg in bgs.items():
    print(f"{p:15} " + " ".join(f"{cr(rgb(n), bg):18.2f}" for _, n in mapping))
d, l = bgs["Clear-Dark"], bgs["Clear-Light"]
# ceiling: a grey whose luminance balances the two contrasts
lo, hi = lum(d), lum(l); L = ((hi+0.05)*(lo+0.05))**0.5 - 0.05
print(f"\nCeiling on both Clear backgrounds ({'#%02x%02x%02x' % d}, {'#%02x%02x%02x' % l}): {(hi+0.05)/(L+0.05):.2f}:1 for any colour")
hues = {"yellow": (40, 70), "green": (90, 160), "cyan": (170, 200), "blue": (210, 250), "magenta": (280, 320), "red": (345, 15), "orange": (20, 40)}
print("Best single index per hue on both Clear backgrounds (min of the two contrasts):")
for name, (a, b) in hues.items():
    best = None
    for n in range(16, 232):
        c = rgb(n); h, s_, v = colorsys.rgb_to_hsv(*(x/255 for x in c)); h *= 360
        if s_ < 0.5: continue
        inside = (a <= h <= b) if a < b else (h >= a or h <= b)
        if not inside: continue
        m = min(cr(c, d), cr(c, l))
        if best is None or m > best[0]: best = (m, n, c, cr(c, d), cr(c, l))
    m, n, c, cd, cl = best
    print(f"  {name:8} 38;5;{n:<3} #{c[0]:02x}{c[1]:02x}{c[2]:02x}  dark {cd:.2f}  light {cl:.2f}")
