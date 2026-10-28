#!/usr/bin/env python3
"""#709 P1: what each qualification candidate exercises at grouping's two
reading sites, from qualify.sh's census and trace runs.

Per candidate, three tables' worth of columns:
  control flow (census): keys grouping saw, groups, checkpoints fired, how many
    of them walked (the rest took the fast path that evicts without a pass),
    final-pass windows, groups whose final pass was skipped;
  cost (trace): walks inside grouping and their seconds, the boundary walks'
    seconds, the run's total, the walks' share of it, the most bytes one walk
    inside grouping covered and the largest store in it;
  capture (trace): each grouping store of 1 MB or more whose high-water mark
    falls inside grouping, against the most the phase-boundary walks see.

  usage: qualify-summary.py <qualify dir> [name ...]
"""
import collections
import glob
import os
import re
import sys

INSIDE = ("grouping_checkpoint", "grouping_final_pass")
MB = 1e6


def census(path):
    out = dict(keys=0, groups=0, checkpoints=0, windows=0, skipped=0, rows=0, absorbed_pct=[])
    phase = None
    for line in open(path, errors="replace"):
        line = line.rstrip("\n")
        if line.startswith("category: "):
            out["groups"] += 1
            phase = None
        elif line.startswith("  final_pass_skipped: yes"):
            out["skipped"] += 1
        elif line.startswith("  reduction_rows: "):
            out["rows"] += int(line.split(": ")[1])
        elif line.startswith("  phase: "):
            phase = line.split(": ")[1]
        elif phase == "streaming" and line.startswith("    keys_seen: "):
            out["keys"] += int(line.split(": ")[1])
        elif phase == "streaming" and line.startswith("    checkpoints: "):
            out["checkpoints"] += int(line.split(": ")[1])
        elif phase == "final_pass" and line.startswith("    pass1_windows: "):
            out["windows"] += int(line.split(": ")[1])
        elif line.startswith("=== message-grouping / grand-totals") or line.startswith("=== END message-grouping"):
            phase = None
    return out


def timing(path):
    t = {}
    for line in open(path, errors="replace"):
        f = line.rstrip("\n").split("\t")
        if len(f) == 3 and f[0] == "TIMING":
            t[f[1]] = float(f[2])
    return t


def walks(path):
    w = collections.defaultdict(lambda: [0, 0.0])
    rss = 0
    for line in open(path, errors="replace"):
        f = line.rstrip("\n").split("\t")
        if f[0] == "P1WALK":
            w[f[1]] = [int(f[2]), float(f[3])]
        m = re.match(r"\s*(\d+)\s+maximum resident set size", line)
        if m:
            rss = int(m.group(1))
    return w, rss


def trace(path):
    readings, sizes = {}, collections.defaultdict(dict)
    for line in open(path):
        f = line.rstrip("\n").split("\t")
        if f[0] == "reading":
            readings[int(f[1])] = f[2]
        else:
            sizes[int(f[1])][f[2]] = int(f[3])
    return [(readings[s], sizes[s]) for s in sorted(readings)]


def main():
    qdir = sys.argv[1]
    names = sys.argv[2:] or [os.path.basename(p)[7:-4] for p in sorted(glob.glob(os.path.join(qdir, "census-*.out")))]
    cost_rows, capture_rows = [], []
    print(f"{'candidate':16s} {'keys':>8s} {'groups':>6s} {'cp_fired':>8s} {'cp_walked':>9s} {'windows':>7s} {'fp_skip':>7s} {'rows':>7s}"
          f"  {'in_walks':>8s} {'in_s':>6s} {'bd_s':>6s} {'total_s':>7s} {'share':>6s} {'max_walk_MB':>11s} {'largest store in it':28s} {'peak_MB':>7s}")
    for name in names:
        c = census(os.path.join(qdir, f"census-{name}.out"))
        w, rss = walks(os.path.join(qdir, f"trace-{name}.err"))
        t = timing(os.path.join(qdir, f"trace-{name}.out"))
        tr = trace(os.path.join(qdir, f"trace-{name}.tsv")) if os.path.exists(os.path.join(qdir, f"trace-{name}.tsv")) else []
        in_n = w["grouping_checkpoint"][0] + w["grouping_final_pass"][0]
        in_s = w["grouping_checkpoint"][1] + w["grouping_final_pass"][1]
        bd_s = w["phase_boundary"][1]
        total = t.get("total", 0)
        inside = [s for site, s in tr if site in INSIDE]
        boundary = [s for site, s in tr if site not in INSIDE]
        biggest = max(inside, key=lambda s: sum(s.values()), default={})
        top = max(biggest, key=biggest.get, default="-")
        print(f"{name:16s} {c['keys']:8d} {c['groups']:6d} {c['checkpoints']:8d} {w['grouping_checkpoint'][0]:9d} {c['windows']:7d} {c['skipped']:7d} {c['rows']:7d}"
              f"  {in_n:8d} {in_s:6.2f} {bd_s:6.2f} {total:7.2f} {100 * (in_s + bd_s) / total if total else 0:5.1f}% "
              f"{sum(biggest.values()) / MB:11.1f} {top + ' ' + format(biggest.get(top, 0) / MB, '.1f'):28s} {rss / MB:7.1f}")
        if w["grouping_final_pass"][0] != c["windows"]:
            print(f"  ! final-pass walks {w['grouping_final_pass'][0]} != census windows {c['windows']}")
        peak_in = collections.defaultdict(int)
        peak_bd = collections.defaultdict(int)
        for s in inside:
            for k, v in s.items():
                peak_in[k] = max(peak_in[k], v)
        for s in boundary:
            for k, v in s.items():
                peak_bd[k] = max(peak_bd[k], v)
        missed = [(k, peak_in[k], peak_bd[k]) for k in peak_in if peak_in[k] >= MB and peak_in[k] > 1.05 * peak_bd[k]]
        missed.sort(key=lambda x: -x[1])
        capture_rows.append((name, missed))
    print()
    print("stores whose high-water mark falls inside grouping, MB inside -> most at the phase boundaries")
    for name, missed in capture_rows:
        print(f"  {name:16s} " + ("; ".join(f"{k.replace('consolidation_', 'c_')} {a / MB:.1f}->{b / MB:.1f}" for k, a, b in missed) or "-"))


if __name__ == "__main__":
    main()
