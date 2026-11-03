#!/usr/bin/env python3
"""Reads a terminal window's captures of ltl output, cell by cell.

  read-output.py <pages-dir> <shown.ans> <frame.json> <window-rows> <profile> <condition> <background> <palette> <base.ans> <run>  > read.json
  read-output.py --table <read.json>
  read-output.py --summary <read.json>...
  read-output.py --compare <read.json>...

<pages-dir> holds page-0.png, page-1.png, ...: the window after each page of
<shown.ans> (the exact file printed) was printed, <window-rows> lines a
page, page k ending at line min((k+1)R, total) and so showing the R lines
before it. The grid comes from page 0's marker blocks (column pitch) and
calibration cell (its top and height: a background fills the whole cell),
and holds for every page, the same window. Each line is read on the page
that printed it. Every cell of
<shown.ans> is parsed for its character and the codes in force (foreground,
background, bold); a line the top capture shows is read there, the rest in
the bottom capture. Each cell holding a glyph is read:
- its background: the window's background (the median of blank cells with no
  background code) for a cell with none, otherwise the cell's most frequent
  pixel, which is its fill;
- its ink: the pixel farthest from that background, the colour the glyph is
  drawn in, and that pixel's WCAG 2 contrast with the background.
Cells are grouped by (role, foreground, bold, background, kind): the role is
the foreground <base.ans> (today's ltl, the same layout) writes in that cell,
so a surface is followed from today's code to the code a set gives it; kind
is text, or graphic for box drawing, block and geometric glyphs. A group's
colour is the ink at the 90th percentile of distance from the background
across its cells (thin glyphs do not reach the full colour), its contrast
that colour's, and its low the 10th percentile of the cells' own contrasts.
"""
import importlib.util, json, os, re, shutil, struct, subprocess, sys, tempfile, unicodedata
from statistics import median
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from analyse import dist, contrast, hexc, SRGB

def load_np(png):
    """the capture as an sRGB array (height, width, 3): on macOS through sips
    (to sRGB, as a BMP); elsewhere (a Windows capture, already in the
    screen's pixels) decoded by analyse.py's PNG reader"""
    if not shutil.which("sips"):
        from analyse import read_png
        w, h, bpp, rows = read_png(png)
        return np.frombuffer(b"".join(bytes(r) for r in rows), np.uint8).reshape(h, w, bpp)[:, :, :3]
    bmp = os.path.join(tempfile.mkdtemp(), "c.bmp")
    cmd = ["sips"] + (["-m", SRGB] if os.path.exists(SRGB) else []) + ["-s", "format", "bmp", png, "--out", bmp]
    subprocess.run(cmd, check=True, capture_output=True)
    d = open(bmp, "rb").read()
    off, = struct.unpack_from("<I", d, 10)
    w, h, _, bpp = struct.unpack_from("<iiHH", d, 18)
    stride = (w * bpp // 8 + 3) & ~3
    a = np.frombuffer(d, np.uint8, count=stride * abs(h), offset=off).reshape(abs(h), stride)[:, :w * bpp // 8]
    a = a.reshape(abs(h), w, bpp // 8)[:, :, 2::-1]
    shutil.rmtree(os.path.dirname(bmp))
    return a[::-1] if h > 0 else a

def parse(text):
    st = dict(fg="def", bg="def", bold=False, faint=False, ul=False, rev=False)
    cells = []
    for row, line in enumerate(text.split("\n")):
        col, i = 0, 0
        while i < len(line):
            if line[i] == "\x1b":
                m = re.match(r"\x1b\[([0-9;]*)m", line[i:])
                if m:
                    apply(st, m.group(1)); i += m.end(); continue
                raise SystemExit(f"row {row}: an escape other than SGR")
            ch = line[i]
            w = 2 if unicodedata.east_asian_width(ch) in "WF" else 1
            cells.append((row, col, ch, dict(st)))
            col += w; i += 1
    return cells

def apply(st, code):
    p = [int(v) if v else 0 for v in code.split(";")] if code else [0]
    while p:
        v = p.pop(0)
        if v == 0: st.update(fg="def", bg="def", bold=False, faint=False, ul=False, rev=False)
        elif v == 1: st["bold"] = True
        elif v == 2: st["faint"] = True
        elif v == 22: st["bold"] = st["faint"] = False
        elif v == 4: st["ul"] = True
        elif v == 24: st["ul"] = False
        elif v == 7: st["rev"] = True
        elif v == 27: st["rev"] = False
        elif 30 <= v <= 37 or 90 <= v <= 97: st["fg"] = str(v)
        elif v == 39: st["fg"] = "def"
        elif 40 <= v <= 47 or 100 <= v <= 107: st["bg"] = str(v)
        elif v == 49: st["bg"] = "def"
        elif v in (38, 48) and p[:1] == [5]:
            st["fg" if v == 38 else "bg"] = f"{v};5;{p[1]}"; del p[:2]
        elif v in (38, 48) and p[:1] == [2]:
            st["fg" if v == 38 else "bg"] = f"{v};2;" + ";".join(map(str, p[1:4])); del p[:4]

def graphic(ch):
    o = ord(ch)
    return 0x2500 <= o <= 0x25FF or 0x2800 <= o <= 0x28FF

def scheme(code):
    if code == "def": return False
    p = code.split(";")
    return len(p) == 1 or (p[1] == "5" and int(p[2]) < 16)

def geometry(img, man):
    top = img[:120].astype(int)
    def near(c): return np.argwhere(np.sqrt(((top - np.array(c)) ** 2).sum(axis=2)) < 40)
    mk, cal = near((254, 0, 129)), near((129, 0, 254))
    w = img.shape[1]
    left, right = mk[mk[:, 1] < w / 2], mk[mk[:, 1] >= w / 2]
    cw = (right[:, 1].min() - left[:, 1].min()) / (man["cols"] - 1)
    col = [s["col"] for s in man["swatches"] if s["id"] == "calib"][0]
    return cal[:, 1].min() - col * cw, int(cal[:, 0].min()), cw, int(cal[:, 0].max() - cal[:, 0].min() + 1)

def read(pages, shown, frame, wrows, profile, cond, background, palette, base, run):
    man, R = json.load(open(frame)), int(wrows)
    total = man["rows"]
    n = -(-total // R)
    imgs = [load_np(os.path.join(pages, f"page-{k}.png")).astype(int) for k in range(n)]
    x0, y0, cw, ch = geometry(imgs[0], man)
    start = [0] + [max(0, min((k + 1) * R, total) - R) for k in range(1, n)]
    cells = parse(open(shown, encoding="utf-8").read())
    # each later page's first line, found from the capture: the offset near
    # the expected one whose rows carry ink where the lines carry glyphs
    glyphs = {r for r, c, g, st in cells if g != " " or st["bg"] != "def"}
    wb = imgs[0][int(y0) + int(ch) // 2, 2].astype(int)
    def inked(im, row):
        ya = int(round(y0 + row * ch)); band = im[ya + 2:ya + int(ch) - 2, int(x0):int(x0 + man["cols"] * cw)]
        return bool((np.sqrt(((band - wb) ** 2).sum(axis=2)) > 60).any())
    for k in range(1, n):
        rows_ink = [inked(imgs[k], row) for row in range(R)]
        score = lambda off: sum(rows_ink[row] == ((off + row) in glyphs) for row in range(R))
        start[k] = max(range(max(0, start[k] - 3), min(total - R, start[k] + 3) + 1), key=score)
    def box(r, c):
        k = min(r // R, n - 1); rr = r - start[k]
        return imgs[k], int(round(y0 + rr * ch)), int(round(y0 + (rr + 1) * ch)), int(round(x0 + c * cw)), int(round(x0 + (c + 1) * cw))
    btext = open(base, encoding="utf-8").read()
    role = {(r, c): st["fg"] for r, c, g, st in parse(btext)}
    spec = importlib.util.spec_from_file_location("ep", os.path.join(os.path.dirname(os.path.abspath(__file__)), "e-palette.py"))
    ep = importlib.util.module_from_spec(spec); spec.loader.exec_module(ep)
    chart = ep.masks(btext)
    samples = []
    for r, c, g, st in [x for x in cells if x[2] == " " and x[3]["bg"] == "def" and 0 < x[0] < R][::7][:400]:
        im, ya, yb, xa, xb = box(r, c)
        samples.append(tuple(im[(ya + yb) // 2, (xa + xb) // 2]))
    wbg = tuple(int(median(s[i] for s in samples)) for i in range(3))
    groups = {}
    for r, c, g, st in cells:
        if g == " " or r == 0:
            continue
        im, ya, yb, xa, xb = box(r, c)
        pix = im[ya:yb, xa:xb].reshape(-1, 3)
        if st["bg"] == "def":
            bg = np.array(wbg)
        else:
            vals, counts = np.unique(pix, axis=0, return_counts=True)
            bg = vals[counts.argmax()]
        d = np.sqrt(((pix - bg) ** 2).sum(axis=1))
        ink = tuple(int(v) for v in pix[d.argmax()]); bgt = tuple(int(v) for v in bg)
        k = (role.get((r, c), "def"), st["fg"], st["bold"], st["bg"], "graphic" if graphic(g) else "text", "chart" if chart(r, c) else "surface")
        e = groups.setdefault(k, dict(cells=[], text=""))
        e["cells"].append((float(d.max()), ink, bgt, contrast(ink, bgt)))
        if len(e["text"]) < 28: e["text"] += g
    out = []
    for (rl, fg, bold, bgc, kind, region), e in groups.items():
        cs = sorted(e["cells"], key=lambda t: t[0])
        d, ink, bg, _ = cs[int(0.9 * (len(cs) - 1))]
        lows = sorted(t[3] for t in cs)
        out.append(dict(role=rl, fg=fg, bold=bold, bg=bgc, kind=kind, region=region, n=len(cs), colour=hexc(ink), bg_colour=hexc(bg),
                        contrast=round(contrast(ink, bg), 2), low=round(lows[int(0.1 * (len(lows) - 1))], 2), sample=e["text"]))
    return dict(run=run, profile=profile, condition=cond, background=background, palette=palette, pages=n, window_bg=hexc(wbg),
                grid=dict(x0=round(float(x0), 1), y0=y0, cell_w=round(float(cw), 3), cell_h=ch, page_starts=start), groups=out)

def label(g):
    return ("1;" if g["bold"] else "") + g["fg"] + ("" if g["bg"] == "def" else " on " + g["bg"])

def table(path):
    d = json.load(open(path))
    print(f"== {d['run']}: {d['profile']} ({d['background']}), background {d['condition']}: {d['palette']} palette  (window background {d['window_bg']})")
    print(f"   {'kind':8} {'today':9} {'code':28} {'cells':>5} {'drawn':8} {'on':8} {'contrast':>8} {'low':>6}  sample")
    for g in sorted(d["groups"], key=lambda g: (g["kind"], g["contrast"])):
        print(f"   {g['kind']:8} {g['role']:9} {label(g):28} {g['n']:5d} {g['colour']:8} {g['bg_colour']:8} {g['contrast']:8.2f} {g['low']:6.2f}  {g['sample'].strip()[:28]}")

def summary(paths):
    print("D1 across Terminal.app configurations: each window's weakest text (contrast of the drawn colour with the cell's background)")
    print(f"{'run':12} {'profile':15} {'bg':5} {'condition':9} {'palette':7} {'window':8} {'text codes':>10} {'<4.5':>4} {'<3':>3}  weakest three text codes")
    for p in paths:
        d = json.load(open(p))
        t = sorted((g for g in d["groups"] if g["kind"] == "text" and g.get("region") != "chart"), key=lambda g: g["contrast"])
        weak = "; ".join(f"{label(g)} {g['contrast']:.2f} '{g['sample'].strip()[:14]}'" for g in t[:3])
        print(f"{d['run'][:12]:12} {d['profile']:15} {d['background']:5} {d['condition']:9} {d['palette']:7} {d['window_bg']:8} {len(t):10d} "
              f"{sum(g['contrast'] < 4.5 for g in t):4d} {sum(g['contrast'] < 3 for g in t):3d}  {weak}")

def compare(paths):
    """Text by the code today's ltl writes there: its contrast with the
    background unknown (the fallback, today's colours), then known (the set)."""
    reads = [json.load(open(p)) for p in paths]
    profiles = list(dict.fromkeys(d["profile"] for d in reads))
    bgs = {d["profile"]: d["background"] for d in reads}
    rows = {}
    for d in reads:
        for g in d["groups"]:
            if g["kind"] != "text" or g.get("region") == "chart": continue
            # a fill is a 256-colour code, the same in every palette
            k = (g["bg"] != "def", not scheme(g["role"]), d["run"], g["role"], g["bold"], g["bg"])
            e = rows.setdefault(k, dict(sample=g["sample"].strip()[:22], cells={}))
            c = e["cells"].setdefault(d["profile"], {})
            c[d["condition"]] = min(c.get(d["condition"], 99), g["contrast"])
    print("Text by the code today's ltl writes there: contrast with the background unknown (fallback), then known (the set); WCAG 2, 4.5:1 for text")
    print("background: " + ", ".join(f"{p} {bgs[p]}" for p in profiles))
    for title, fill, fixed in (("Scheme colours on the window's background (what the sets replace)", False, False),
                               ("ltl's own 256-colour codes on the window's background (not replaced)", False, True),
                               ("Text on a fill", True, None)):
        print(f"\n{title}")
        print(f"{'run':10} {'today':18} {'sample':22} " + " ".join(f"{p[:11]:>11}" for p in profiles))
        for k, e in sorted(rows.items(), key=lambda kv: kv[0][2:]):
            if k[0] != fill or (fixed is not None and k[1] != fixed): continue
            name = f"{k[2][:10]:10} " + ("1;" if k[4] else "") + k[3] + (f" on {k[5]}" if k[5] != "def" else "")
            def cell(p):
                c = e["cells"].get(p)
                if not c: return " " * 11
                f = lambda v: f"{v:5.2f}" if v is not None else "  -  "
                return f"{f(c.get('unknown'))}>{f(c.get('known'))}"
            print(f"{name[:29]:29} {e['sample']:22} " + " ".join(cell(p) for p in profiles))

if __name__ == "__main__":
    if sys.argv[1] == "--table":
        table(sys.argv[2])
    elif sys.argv[1] == "--summary":
        summary(sys.argv[2:])
    elif sys.argv[1] == "--compare":
        compare(sys.argv[2:])
    else:
        print(json.dumps(read(*sys.argv[1:11]), indent=1))
