#!/usr/bin/env python3
"""#709 criterion 11: grouping's walks under -mem (D3) meet the bounds P1 set.

  capture  on each input, every grouping store whose every-call reference mark
           (results/p1-every-call-hwm.tsv) is 1 MB or more reports a MEMORY
           row within 5 % of it
  cost     on 15 unmasked days (tc-g-d15), the median wall clock with -mem is
           at most 12 % above the median without it (P1 measured +9.1 %)

Reads run-arms.sh output trees: the capture tree's <arm>.out of its first
round, and the cost tree's three rounds of the floor (tracked) and <arm>.

  usage: check-criterion-11.py <capture dir> <cost dir> <arm> [before arm]
"""
import collections
import os
import re
import statistics
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REFERENCE = os.path.join(HERE, "results", "p1-every-call-hwm.tsv")
MB = 1e6
CAPTURE_FLOOR = 0.95  # criterion 11: within 5 % of the reference
COST_CEILING = 0.12   # criterion 11: at most 12 % above the floor


def memory_rows(path):
    rows = {}
    for line in open(path, errors="replace"):
        f = line.rstrip("\n").split("\t")
        if len(f) == 3 and f[0] == "MEMORY":
            rows[f[1]] = int(f[2])
    return rows


def wall(path):
    for line in open(path, errors="replace"):
        m = re.match(r"\s*([\d.]+) real\s", line)
        if m:
            return float(m.group(1))
    return None


def main():
    capture_dir, cost_dir, arm = sys.argv[1:4]
    before = sys.argv[4] if len(sys.argv) > 4 else None
    ref = collections.defaultdict(dict)
    for line in open(REFERENCE):
        if line.startswith("#") or line.startswith("input\t"):
            continue
        inp, store, v = line.rstrip("\n").split("\t")
        ref[inp][store] = int(v)
    ok = True
    first = sorted(d for d in os.listdir(capture_dir) if re.fullmatch(r"r\d+", d))[0]
    print(f"capture ({arm}, against the every-call reference; stores of 1 MB or more):")
    for inp in sorted(os.listdir(os.path.join(capture_dir, first))):
        got = memory_rows(os.path.join(capture_dir, first, inp, f"{arm}.out"))
        short = []
        for store, want in sorted(ref[inp].items(), key=lambda kv: -kv[1]):
            if want < MB:
                continue
            if got.get(store, 0) < CAPTURE_FLOOR * want:
                short.append(f"{store} {want / MB:.1f} -> {got.get(store, 0) / MB:.1f} MB")
        checked = sum(1 for v in ref[inp].values() if v >= MB)
        print(f"  {inp:16s} {checked} stores: " + ("; ".join(short) if short else "all within 5 %"))
        ok &= not short
    rounds = sorted(d for d in os.listdir(cost_dir) if re.fullmatch(r"r\d+", d))
    print(f"cost (tc-g-d15, wall clock, median [range] of {len(rounds)} rounds):")
    med = {}
    for a in ["tracked"] + ([before] if before else []) + [arm]:
        w = [wall(os.path.join(cost_dir, r, "tc-g-d15", f"{a}.err")) for r in rounds]
        w = [x for x in w if x is not None]
        med[a] = statistics.median(w)
        print(f"  {a:8s} {med[a]:.2f} s [{min(w):.2f}-{max(w):.2f}]"
              + (f"  {100 * (med[a] / med['tracked'] - 1):+.1f} % against the floor" if a != "tracked" else ""))
    over = med[arm] / med["tracked"] - 1
    ok &= over <= COST_CEILING
    print(f"criterion 11: {'met' if ok else 'NOT met'}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
