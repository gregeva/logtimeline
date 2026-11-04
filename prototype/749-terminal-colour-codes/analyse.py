#!/usr/bin/env python3
"""Reads a terminal window's capture of pattern.ans against pattern.json.

Usage: analyse.py <capture.png> <pattern.json> [out.json]

On macOS the capture is first converted to sRGB with sips (screencapture
writes the display's colour space); elsewhere (a Windows capture) its pixels
are read as written. Then:
- the cell grid comes from the row-0 background cell (a cell's true top,
  height and width) and the marker blocks (column pitch, row pitch);
- a block swatch reads as the median colour of each cell's inner half;
- a text swatch reads as its ink: the pixels at least 48 (Euclidean, sRGB
  0-255) from the background beside it, their count, and the extreme pixel
  (farthest from the background), which is the colour the glyph is drawn in.
"""
import json, os, shutil, struct, subprocess, sys, tempfile, zlib
from statistics import median

SRGB = "/System/Library/ColorSync/Profiles/sRGB Profile.icc"

def read_png(path):
    """Decodes an 8-bit, non-interlaced RGB or RGBA PNG: (width, height,
    bytes per pixel, rows of raw pixel bytes)."""
    d = open(path, "rb").read()
    assert d[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos, idat = 8, b""
    while pos < len(d):
        n, kind = struct.unpack_from(">I4s", d, pos)
        body = d[pos + 8:pos + 8 + n]
        if kind == b"IHDR":
            w, h, depth, ctype, _, _, interlace = struct.unpack(">IIBBBBB", body)
            assert depth == 8 and ctype in (2, 6) and interlace == 0, (depth, ctype, interlace)
            bpp = 3 if ctype == 2 else 4
        elif kind == b"IDAT":
            idat += body
        pos += 12 + n
    raw, stride, rows, prev = zlib.decompress(idat), w * bpp, [], bytearray(w * bpp)
    for y in range(h):
        f, line = raw[y * (stride + 1)], bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            if f == 1:   line[i] = (line[i] + a) & 255
            elif f == 2: line[i] = (line[i] + b) & 255
            elif f == 3: line[i] = (line[i] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(line)
        prev = line
    return w, h, bpp, rows

def load(png):
    if shutil.which("sips") and os.path.exists(SRGB):
        srgb = os.path.join(tempfile.mkdtemp(), "s.png")
        subprocess.run(["sips", "-m", SRGB, png, "--out", srgb], check=True, capture_output=True)
        png = srgb
    w, h, bpp, rows = read_png(png)
    def px(x, y):
        r, i = rows[y], x * bpp
        return (r[i], r[i + 1], r[i + 2])
    return w, h, px

def dist(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5

def lum(c):
    def ch(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(v) for v in c)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

def hexc(c):
    return "#%02x%02x%02x" % c

def main():
    png, man = sys.argv[1], json.load(open(sys.argv[2]))
    w, h, px = load(png)
    mark = (254, 0, 129)
    # locate marker blocks: bounding boxes of near-magenta pixels, split by x
    pts = [(x, y) for y in range(h) for x in range(w) if dist(px(x, y), mark) < 40]
    if not pts:
        sys.exit("no marker found")
    ys = sorted(set(y for _, y in pts))
    top = [p for p in pts if p[1] <= ys[0] + 40]
    left = [p for p in top if p[0] < w / 2]
    right = [p for p in top if p[0] >= w / 2]
    lx0, lx1 = min(x for x, _ in left), max(x for x, _ in left)
    ly0, ly1 = min(y for _, y in left), max(y for _, y in left)
    rx0 = min(x for x, _ in right)
    marker_b_col = man["cols"] - 1
    cw = (rx0 - lx0) / marker_b_col
    ch = ly1 - ly0 + 1
    x0, y0 = lx0, ly0
    # the last marker (marker-c) gives the row pitch
    last_row = max(s["row"] for s in man["swatches"] if s["id"] == "marker-c")
    bottom = [p for p in pts if p[1] > ys[0] + 40]
    if bottom:
        by0 = min(y for _, y in bottom)
        ch = (by0 - y0) / last_row
    # the calibration cell (a cyan background space at row 0, column 50)
    # gives the cell's true top, height and width: a background fills the
    # whole cell, a block glyph does not
    cal = (129, 0, 254)
    cpts = [(x, y) for y in range(h) for x in range(w) if dist(px(x, y), cal) < 40]
    cx0, cx1 = min(x for x, _ in cpts), max(x for x, _ in cpts)
    cy0, cy1 = min(y for _, y in cpts), max(y for _, y in cpts)
    cal_col = [s for s in man["swatches"] if s["id"] == "calib"][0]["col"]
    x0 = cx0 - cal_col * cw
    y0 = cy0
    cell_line_h = cy1 - cy0 + 1
    geo = dict(calib_box=[cx0, cy0, cx1, cy1], cell_line_h=cell_line_h, cell_w=round(cw, 3), cell_h=round(ch, 3), x0=x0, y0=y0, img=[w, h],
               marker_block_h=ly1 - ly0 + 1, marker_block_w=lx1 - lx0 + 1)

    def cell_box(row, col, n=1):
        xa = x0 + col * cw
        ya = y0 + row * ch
        return xa, ya, xa + n * cw, ya + ch

    def bg_near(row, col, n):
        # background: the median of the cell just left of the swatch's label gap
        samples = []
        for c in (col - 1, col + n):
            xa, ya, xb, yb = cell_box(row, c)
            for y in range(int(ya + 2), int(yb - 2)):
                for x in range(int(xa + 1), int(xb - 1)):
                    samples.append(px(x, y))
        return tuple(int(median(s[i] for s in samples)) for i in range(3))

    out = []
    for s in man["swatches"]:
        if s["kind"] in ("marker", "calib"):
            continue
        row, col, n = s["row"], s["col"], s["len"]
        rec = dict(id=s["id"], sgr=s["sgr"], kind=s["kind"])
        if s["kind"] == "block":
            cols = []
            for k in range(n):
                xa, ya, xb, yb = cell_box(row, col + k)
                for y in range(int(ya + ch * 0.3), int(yb - ch * 0.3)):
                    for x in range(int(xa + cw * 0.3), int(xb - cw * 0.3)):
                        cols.append(px(x, y))
            c = tuple(int(median(p[i] for p in cols)) for i in range(3))
            bg = bg_near(row, col, n)
            rec.update(colour=hexc(c), rgb=c, bg=hexc(bg), contrast=round(contrast(c, bg), 2))
        else:
            if s["kind"] == "filltext":
                # the fill is the swatch's own background: read it from the
                # padding cell at each end of " word "
                xa, ya, xb, yb = cell_box(row, col)
                samples = [px(x, y) for y in range(int(ya + 2), int(yb - 2)) for x in range(int(xa + 1), int(xb - 1))]
                bg = tuple(int(median(p[i] for p in samples)) for i in range(3))
                col, n = col + 1, n - 2
            else:
                bg = bg_near(row, col, n)
            xa, ya, xb, yb = cell_box(row, col, n)
            ink, extreme, far = 0, bg, 0.0
            weighted = 0.0
            for y in range(int(ya), int(yb)):
                for x in range(int(xa), int(xb)):
                    p = px(x, y)
                    dd = dist(p, bg)
                    if dd >= 48:
                        ink += 1
                        weighted += dd
                    if dd > far:
                        far, extreme = dd, p
            rec.update(bg=hexc(bg), ink=ink, ink_weighted=round(weighted), extreme=hexc(extreme),
                       extreme_rgb=extreme, contrast=round(contrast(extreme, bg), 2))
        out.append(rec)
    res = dict(capture=os.path.basename(png), geometry=geo, swatches=out)
    if len(sys.argv) > 3:
        json.dump(res, open(sys.argv[3], "w"), indent=1)
    return res

if __name__ == "__main__":
    r = main()
    print(json.dumps(r["geometry"]))
