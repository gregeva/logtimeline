#!/usr/bin/env python3
"""notice-design.py [--out palettes/n1.tsv]

The notice surfaces' colours in the dark and light sets (feature doc § 12.7),
for the notice prototype's style_for (../412-notice-surfaces, show.pl --set).
Run from this directory.

- frame and secondary text: the set's grey, #797c81 on dark and #747474 on
  light (the architect, § 12.8);
- text and the pick: dark, the set's white and bright white (t4 s7, s15);
  light, 256-colour black 16, as the light notice style writes today;
- the layer dimmed under a pop-up keeps today's mechanism (faint over every
  code on dark; each colour half way to white on light), its uncoloured text
  in the set's grey on light, where today it takes 244;
- category colours on dark: today's (notice_category_sheet's dark codes and
  the orange and teal column colours), each moved in OKLCH lightness only
  toward 4.5:1 on Clear Dark, by no more than 0.08 (tone.py's rule for ltl's
  fixed codes); only magenta 170 and blue 33 fall short;
- category colours on light, two candidates:
    tone      today's colour (the last step of the column's 256-colour
              gradient_light), moved as above on Clear Light: t4's f rows;
    gradient  the last step of the column's light gradient in t4, which is
              what docs/design-language.md § The category sheet derives the
              light category colour from.
"""
import argparse, math, re

ap = argparse.ArgumentParser()
ap.add_argument("--out")
a = ap.parse_args()
FLOOR, CAP = 4.5, 0.08          # tone.py: FLOOR, --grey-cap (the fixed codes' cap)

# From tone.py: sRGB, WCAG 2 contrast, OKLCH, the lightness move.
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
def move(target, bg, cap):
    if cr(target, bg) >= FLOOR: return target
    L, C, H = lch(target)
    toward = 1 if lum(bg) < 0.18 else -1
    best = target
    for i in range(1, 201):
        best = from_lch(L + toward * cap * i / 200, C, H)
        if cr(best, bg) >= FLOOR: break
    return best

def background(profile):
    return re.search(r"#[0-9a-f]{6}", open(f"results/terminal-app/profile-{profile}.txt").readline()).group(0)
DBG, LBG = background("Clear-Dark"), background("Clear-Light")

t4 = {}
for row in open("palettes/t4.tsv"):
    if row.startswith("#"): continue
    f = row.rstrip("\n").split("\t")
    t4[f[0]] = (f[3], f[6])
def hexof(v): return x256(int(v)) if re.fullmatch(r"\d+", v) else v

# The categories: (ltl's name, column colour, today's dark code, today's light code).
# Dark: notice_category_sheet's `dark` codes, else the column's fg (orange 208,
# teal 43); light: the column's gradient_light[-1] (@column_colors).
CATS = [("data anomaly", "orange", 208, 166), ("figure caveat", "magenta", 170, 93),
        ("your options", "cyan", 44, 30), ("decision taken for you", "blue", 33, 27),
        ("runtime condition", "teal", 43, 29), ("guidance", "green", 40, 35)]

rows = [  # key, dark, light, light (gradient candidate)
    ("frame", "#797c81", "#747474", "#747474"),
    ("dim", "#797c81", "#747474", "#747474"),
    ("dimtext", "-", "#747474", "#747474"),
    ("text", hexof(t4["s7"][0]), "16", "16"),
    ("pick", hexof(t4["s15"][0]), "16", "16"),
]
print(f"Clear Dark {DBG}, Clear Light {LBG}; categories, contrast today -> set")
print(f"{'category':24} {'dark today':>17} -> {'dark set':17} | {'light today':>17} -> {'tone':17} | {'gradient':17}")
for name, col, d, l in CATS:
    dk = move(x256(d), DBG, CAP)
    lt = move(x256(l), LBG, CAP)
    lg = hexof(t4["g" + col][1].split(",")[-1])
    rows.append(("cat:" + name, dk if dk != x256(d) else str(d), lt if lt != x256(l) else str(l), lg))
    print(f"{name:24} {x256(d)} {cr(x256(d), DBG):5.2f}"
          f" -> {dk} {cr(dk, DBG):5.2f} {lch(dk)[0]-lch(x256(d))[0]:+.3f}"
          f" | {x256(l)} {cr(x256(l), LBG):5.2f} -> {lt} {cr(lt, LBG):5.2f}"
          f" | {lg} {cr(lg, LBG):5.2f} hue {lch(lg)[2]-lch(x256(l))[2]:+4.0f}")

if a.out:
    with open(a.out, "w", encoding="utf-8", newline="\n") as f:
        f.write("# The notice surfaces' roles in the dark and light sets, by notice-design.py (feature doc § 12.7).\n")
        f.write("# A value is a 256-colour index or #rrggbb; light_gradient is the light category candidate from t4's gradients.\n")
        f.write("# key\tdark\tlight\tlight_gradient\n")
        for r in rows: f.write("\t".join(r) + "\n")
    print("wrote", a.out)
