#!/usr/bin/env python3
"""e-swatch.py <palette.tsv> <out-dir>

Writes a palette's swatch card, every role on one screen, as three files the
viewer (wt-e-view.sh) shows like a run: basic.ans with the codes ltl writes
today, dark.ans and light.ans with the set's. Each line is one role: its
name, what ltl writes in it, and a sample drawn in its code. A fill is shown
plain and highlighted with a sample value over it; today's line shows the
fill alone, since the text ltl writes over a fill today depends on the
surface (the runs show it).
"""
import os, sys

palette, out = sys.argv[1], sys.argv[2]
rows = [l.rstrip("\n").split("\t") for l in open(palette, encoding="utf-8") if not l.startswith("#")]
role = {r[0]: r for r in rows}
os.makedirs(out, exist_ok=True)
TEXT = "──── 503 ERROR 1,234.5 ms ■■■■ ████"

def today(k):
    if k.startswith("s"):
        i = int(k[1:]); return f"3{i}" if i < 8 else f"9{i-8}"
    if k.startswith("f"): return f"38;5;{k[1:]}"
    if k.startswith("b"): return f"48;5;{k[1:]}"
    return None

def code(k, cls):
    r = role.get(k)
    n = r[3] if cls == "dark" else r[6]
    if n in ("-", ""): return today(k)
    return f"{'48' if k.startswith('b') else '38'};5;{n}"

def label(k, name, use):
    return f"  {k:<7} {name:<16} {use[:52]:<52} "

def card(cls):
    out = [f"  Swatch card: {os.path.basename(palette)}, "
           + ("today's codes (the scheme's basic colours)" if cls is None else f"the {cls} set"), ""]
    for k, name, use, *_ in rows:
        if k == "s0" or k.startswith(("b", "t")) or k == "e": continue
        c = today(k) if cls is None else code(k, cls)
        out.append(label(k, name, use) + f"\033[{c}m{TEXT}\033[0m")
    out.append("")
    seen = set()
    for k, name, use, *_ in rows:
        if not k.startswith("b") or k in seen: continue
        # a column's plain fill row is followed by its highlighted fill row
        ks = [x for x in role if x.startswith("b")]
        i = ks.index(k); p, h = ks[i], ks[i + 1]
        seen |= {p, h}
        col = use.replace(" plain fill", "")
        line = label(f"{p[1:]}/{h[1:]}", col, "fills: plain, highlighted")
        for b in (p, h):
            if cls is None:
                line += f"\033[{today(b)}m{' ' * 13}\033[0m  "
            else:
                t = role["t" + b[1:]][3 if cls == "dark" else 6]
                line += f"\033[{code(b, cls)};38;5;{t}m   1,234.5   \033[0m  "
        out.append(line)
    out.append("")
    e = "1" if cls is None else f"1;38;5;{role['e'][3 if cls == 'dark' else 6]}"
    out.append(label("e", "bold", "help and explain headings, beside body text")
               + f"\033[{e}mOPTIONS AND HEADINGS\033[0m  body text in the default colour")
    return "\n".join(out) + "\n"

for name, cls in (("basic", None), ("dark", "dark"), ("light", "light")):
    with open(os.path.join(out, f"{name}.ans"), "w", encoding="utf-8", newline="\n") as f:
        f.write(card(cls))
