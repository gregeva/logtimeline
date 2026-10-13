#!/usr/bin/env python3
# #621: per file selection, each candidate's median and range of TIMING total
# and peak resident size, and its per-round delta against the base (median,
# range, rounds faster), from run-curve.sh / run-files.sh TSVs.
#   usage: summarise-pairs.py <tsv>...
import csv, sys, statistics as st
rows = [r for p in sys.argv[1:] for r in csv.DictReader(open(p), delimiter='\t') if r['timing_total']]
files = list(dict.fromkeys(r['file'] for r in rows))
for f in files:
    t, m = {}, {}
    for r in rows:
        if r['file'] == f:
            t[(r['candidate'], r['round'])] = float(r['timing_total']); m[(r['candidate'], r['round'])] = float(r['rss_peak'])
    cands = list(dict.fromkeys(c for c, _ in t))
    rounds = sorted({rd for _, rd in t}, key=int)
    print(f"## {f}\n\n| candidate | median s | range s | rss median MB | per-round delta vs base, median (range) | faster in |\n|---|---|---|---|---|---|")
    for c in cands:
        v = [t[(c, rd)] for rd in rounds if (c, rd) in t]
        mm = st.median([m[(c, rd)] for rd in rounds if (c, rd) in m]) / 1048576
        if c == 'base':
            print(f"| {c} | {st.median(v):.3f} | {min(v):.3f} to {max(v):.3f} | {mm:.1f} | | |"); continue
        d = [(t[(c, rd)] / t[('base', rd)] - 1) * 100 for rd in rounds if (c, rd) in t and ('base', rd) in t]
        print(f"| {c} | {st.median(v):.3f} | {min(v):.3f} to {max(v):.3f} | {mm:.1f} | {st.median(d):+.2f} % ({min(d):+.2f} to {max(d):+.2f}) | {sum(x < 0 for x in d)} of {len(d)} |")
    print()
