#!/usr/bin/env python3
"""Writes the #749 measurement pattern (pattern.ans) and its manifest
(pattern.json): every swatch's row, column, length, kind and SGR.

A block swatch is a run of full blocks, read for its colour. A text swatch is
a word, read for its ink (weight) and its extreme pixel (colour). Row 0 holds
two 24-bit marker blocks and a 24-bit background cell, and the last row a third
marker, which the analyser locates the cell grid from.

The pattern writes the sixteen basic colours on purpose: they are what is
measured."""
import json, sys

COLS = 100
WORD = "Hamburg"
rows = []          # list of list of (col, text, sgr, kind, id)
manifest = []

def row():
    rows.append([])
    return len(rows) - 1

def put(r, col, text, sgr, kind=None, sid=None):
    rows[r].append((col, text, sgr))
    if kind:
        manifest.append(dict(id=sid, row=r, col=col, len=len(text), kind=kind, sgr=sgr))

def label(r, col, text):
    put(r, col, text, "0")

MARK = "38;2;254;0;129"
r = row()
put(r, 0, "█", MARK, "marker", "marker-a")
label(r, 2, "749 measurement pattern")
put(r, COLS - 1, "█", MARK, "marker", "marker-b")
put(r, 50, " ", "48;2;129;0;254", "calib", "calib")

def swatch_pair(r, col, name, plain, other, tag):
    """label, plain blocks, other blocks, plain word, other word"""
    label(r, col, name.ljust(6))
    put(r, col + 6, "█" * 4, plain, "block", f"{tag}:{name}:plain")
    put(r, col + 11, "█" * 4, other, "block", f"{tag}:{name}:other")
    put(r, col + 16, WORD, plain, "text", f"{tag}:{name}:plain")
    put(r, col + 24, WORD, other, "text", f"{tag}:{name}:other")

# A. bold on the basic colours and the default foreground (plain | bold)
r = row(); label(r, 0, "A  bold on basic codes: plain | bold")
basic = ["39"] + [str(n) for n in range(30, 38)] + [str(n) for n in range(90, 98)]
for i in range(0, len(basic), 2):
    r = row()
    for j, code in enumerate(basic[i:i + 2]):
        swatch_pair(r, j * 50, code, code, "1;" + code, "A")

# B. palette index 0-15 beside the basic code; index 16 and 244 beside 30 and 90
r = row(); label(r, 0, "B  38;5;N | basic code")
pairs = [(f"38;5;{n}", str(30 + n) if n < 8 else str(82 + n)) for n in range(16)]
pairs += [("38;5;16", "30"), ("38;5;244", "90"), ("38;5;231", "97"), ("38;5;232", "30")]
for i in range(0, len(pairs), 4):
    r = row()
    for j, (idx, code) in enumerate(pairs[i:i + 4]):
        col = j * 25
        name = idx.split(";")[2]
        label(r, col, name.rjust(3))
        put(r, col + 4, "█" * 4, idx, "block", f"B:{idx}")
        put(r, col + 9, "█" * 4, code, "block", f"B:{code}:vs{name}")

# C. bold over index 16-255 (plain | bold)
r = row(); label(r, 0, "C  bold over 38;5;N: plain | bold")
c_idx = ["16", "184", "34", "160", "226", "208", "244", "111"]
for i in range(0, len(c_idx), 2):
    r = row()
    for j, n in enumerate(c_idx[i:i + 2]):
        swatch_pair(r, j * 50, n, f"38;5;{n}", f"1;38;5;{n}", "C")

# D. faint (plain | faint)
r = row(); label(r, 0, "D  faint: plain | faint")
d_codes = ["39", "37", "33", "30", "38;5;184", "38;5;16"]
for i in range(0, len(d_codes), 2):
    r = row()
    for j, code in enumerate(d_codes[i:i + 2]):
        swatch_pair(r, j * 50, code.replace("38;5;", "i"), code, "2;" + code, "D")

# E. 24-bit beside the 256-colour index of the same RGB
r = row(); label(r, 0, "E  38;2 | 38;5 of the same RGB")
e_pairs = [("38;2;215;215;0", "38;5;184"), ("38;2;215;0;0", "38;5;160"),
           ("38;2;128;128;128", "38;5;244"), ("38;2;0;175;0", "38;5;34")]
r = row()
for j, (rgb, idx) in enumerate(e_pairs):
    col = j * 25
    label(r, col, idx.split(";")[2].rjust(3))
    put(r, col + 4, "█" * 4, rgb, "block", f"E:{rgb}")
    put(r, col + 9, "█" * 4, idx, "block", f"E:{idx}:vs{rgb}")

# F. text over a 256-colour fill, as ltl's bars write it
r = row(); label(r, 0, "F  text over fill 48;5;184 / 48;5;34 / 48;5;20")
r = row()
col = 0
for fill in ("184", "34", "20"):
    for fg in ("38;5;0", "30", "38;5;16"):
        put(r, col, f" {WORD} ", f"48;5;{fill};{fg}", "filltext", f"F:{fill}:{fg}")
        col += len(WORD) + 3
r = row()
put(r, 0, "█", MARK, "marker", "marker-c")

out = []
for cells in rows:
    line, pos = "", 0
    for col, text, sgr in sorted(cells):
        line += " " * (col - pos) + f"\033[{sgr}m{text}\033[0m"
        pos = col + len(text)
    out.append(line)
open("pattern.ans", "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
json.dump(dict(cols=COLS, rows=len(rows), swatches=manifest), open("pattern.json", "w"), indent=1)
print(len(rows), "rows,", len(manifest), "swatches")
