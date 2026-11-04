#!/usr/bin/env python3
"""notice-roles.py: each colour role of the notice surfaces (notice_style in ltl)
read against Clear Dark and Clear Light, as written today and as t4 writes it.
Run from this directory; feature doc § 12.7."""
import re, sys, csv
P = sys.argv[1] if len(sys.argv) > 1 else "."
def lin(v):
    v /= 255; return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
def rgb(h): return tuple(int(h[i:i+2], 16) for i in (1, 3, 5))
def lum(h): r, g, b = map(lin, rgb(h)); return 0.2126*r + 0.7152*g + 0.0722*b
def cr(x, y): p, q = sorted((lum(x), lum(y)), reverse=True); return (p + .05) / (q + .05)
def x256(n):
    if n >= 232: g = 8 + 10*(n-232); return "#%02x%02x%02x" % (g, g, g)
    n -= 16; lv = (0, 95, 135, 175, 215, 255); return "#%02x%02x%02x" % (lv[n//36], lv[n//6 % 6], lv[n % 6])
def drawn(profile):
    d = {}; path = f"{P}/results/terminal-app/profile-{profile}.txt"
    for line in open(path):
        m = re.match(r"\s+38;5;(\d+) (#[0-9a-f]{6})", line)
        if m and int(m.group(1)) < 16: d[int(m.group(1))] = m.group(2)
    bg = re.search(r"#[0-9a-f]{6}", open(path).readline()).group(0)
    return d, bg
t4 = {}
for row in open(f"{P}/palettes/t4.tsv"):
    if row.startswith('#'): continue
    f = row.rstrip('\n').split('\t')
    t4[f[0]] = (f[3], f[6])
def val(v): return x256(int(v)) if re.fullmatch(r'\d+', v) else v
D, dbg = drawn('Clear-Dark'); L, lbg = drawn('Clear-Light')
print(f"Clear Dark bg {dbg}   Clear Light bg {lbg}")
g = lambda k, i: val(t4[k][i])
glast = lambda k, i: val(t4[k][i].split(',')[-1]) if k in t4 else None
rows = [
 # role, floor, dark today, dark t4, light today, light t4(text f-row), light t4 (new gradient's darkest step)
 ('frame (box lines)', 3.0, D[8], g('s8',0), x256(244), g('f244',1), None),
 ('text: statement, labels, list rows', 4.5, D[7], g('s7',0), x256(16), g('s7',1), None),
 ('pick (bold): chosen option, All tab', 4.5, D[15], g('s15',0), x256(16), g('s15',1), None),
 ('secondary: evidence, counts, title, how-to-read, countdown', 4.5, 'faint', 'faint', x256(244), g('f244',1), None),
]
cats = [('data anomaly, orange',208,166,'f208','f166','gorange'), ('figure caveat, magenta',170,93,None,'f93','gmagenta'),
        ('your options, cyan',44,30,'f44','f30','gcyan'), ('decision taken, blue',33,27,None,None,'gblue'),
        ('runtime condition, teal',43,29,'f43','f29','gteal'), ('guidance, green',40,35,None,'f35','ggreen')]
for name, d, l, fd, fl, gk in cats:
    rows.append((f'category {name}', 4.5, x256(d), g(fd,0) if fd else x256(d), x256(l), g(fl,1) if fl else x256(l), glast(gk,1)))
print(f"{'role':58} floor | dark today  -> t4          | light today -> t4 text     | light, new gradient's darkest")
for r, fl, dt, d4, lt, l4, lg in rows:
    def c(x, bg): return 'measured' if x == 'faint' else f"{x} {cr(x,bg):5.2f}"
    print(f"{r:58} {fl:3} | {c(dt,dbg):14} -> {c(d4,dbg):14} | {c(lt,lbg):14} -> {c(l4,lbg):14} | {c(lg,lbg) if lg else '':14}")
