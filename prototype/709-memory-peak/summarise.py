#!/usr/bin/env python3
"""#709 P1: summarise run-arms.sh's timed runs.

Per input and arm, medians over the rounds with [min-max]: the run's wall
clock from time -l, and its difference from the floor's (ltl as tracked, no
-mem); the read and grouping stages. The wall clock, not -V benchmark-data's
TIMING total, is the cost: that total sums the stages, so it leaves out the
phase-boundary walks, which run between them. Then the walks inside grouping and at the
phase boundaries, and their seconds; the operating system's resident peak.
Then, per input, each grouping store of 1 MB or more whose high-water mark an
arm captures at less than 95 % of the every-call arm's.

  usage: summarise.py <run dir> [runs.tsv]   (the second writes one row per run)
"""
import collections
import os
import re
import statistics
import sys

GROUPING_PREFIXES = ("consolidation_", "log_messages")
INSIDE = ("grouping_checkpoint", "grouping_final_pass")
ARM_ORDER = ["tracked", "every", "boundaries", "grouponly", "transient", "cond-either-0"]
MB = 1e6


def read_run(out_path, err_path):
    run = dict(timing={}, memory={}, walks={}, rss=0)
    for line in open(out_path, errors="replace"):
        f = line.rstrip("\n").split("\t")
        if len(f) == 3 and f[0] == "TIMING":
            run["timing"][f[1]] = float(f[2])
        elif len(f) == 3 and f[0] == "MEMORY":
            run["memory"][f[1]] = int(f[2])
    for line in open(err_path, errors="replace"):
        f = line.rstrip("\n").split("\t")
        if f[0] == "P1WALK":
            run["walks"][f[1]] = (int(f[2]), float(f[3]))
        m = re.match(r"\s*(\d+)\s+maximum resident set size", line)
        if m:
            run["rss"] = int(m.group(1))
        m = re.match(r"\s*([\d.]+) real\s+([\d.]+) user", line)
        if m:
            run["wall"] = float(m.group(1))
    run["warnings"] = sum(1 for line in open(err_path, errors="replace") if re.search(r" at \S+ line \d+", line))
    return run


def med(values, fmt):
    if not values:
        return "-"
    return f"{fmt(statistics.median(values))} [{fmt(min(values))}-{fmt(max(values))}]"


def main():
    root = sys.argv[1]
    runs = collections.defaultdict(lambda: collections.defaultdict(list))
    inputs = []
    for rnd in sorted(d for d in os.listdir(root) if re.fullmatch(r"r\d+", d)):
        for inp in sorted(os.listdir(os.path.join(root, rnd))):
            if inp not in inputs:
                inputs.append(inp)
            for fn in os.listdir(os.path.join(root, rnd, inp)):
                if fn.endswith(".out"):
                    arm = fn[:-4]
                    base = os.path.join(root, rnd, inp, arm)
                    run = read_run(base + ".out", base + ".err")
                    run["round"] = rnd
                    runs[inp][arm].append(run)
    if len(sys.argv) > 2:
        with open(sys.argv[2], "w") as tsv:
            tsv.write("round\tinput\tarm\twall_s\tread_s\tgroup_s\tstages_total_s\treadings_s\t"
                      "walks_inside\twalks_inside_s\twalks_boundary\twalks_boundary_s\tpeak_rss\n")
            for inp in sorted(runs):
                for arm in sorted(runs[inp]):
                    for r in sorted(runs[inp][arm], key=lambda r: r["round"]):
                        w = r["walks"]
                        tsv.write("\t".join(str(x) for x in (
                            r["round"], inp, arm, r["wall"], r["timing"].get("parse/read_files", 0),
                            r["timing"].get("finalize/group_similar", 0), r["timing"].get("total", 0),
                            r["timing"].get("memory/readings", 0),
                            sum(w.get(s, (0, 0))[0] for s in INSIDE), round(sum(w.get(s, (0, 0))[1] for s in INSIDE), 6),
                            w.get("phase_boundary", (0, 0))[0], w.get("phase_boundary", (0, 0))[1], r["rss"])) + "\n")
    order = ["tc-mask-d1", "tc-mask-d7", "tc-mask-d15", "tc-g-d1", "tc-g-d7", "tc-g-d15", "wc-access-xqs", "appl"]
    inputs = [i for i in order if i in inputs] + [i for i in inputs if i not in order]
    s2 = lambda v: f"{v:.2f}"
    s1 = lambda v: f"{v:.1f}"
    warnings = 0
    for inp in inputs:
        arms = [a for a in ARM_ORDER if a in runs[inp]]
        floor = statistics.median(r["wall"] for r in runs[inp]["tracked"]) if "tracked" in runs[inp] else None
        print(f"== {inp} ({len(runs[inp][arms[0]])} rounds)")
        print(f"   {'arm':14s} {'wall s':22s} {'vs floor':>15s} {'read s':22s} {'group s':22s} {'walks in':>8s} {'in s':20s} {'bound s':20s} {'peak MB':24s}")
        for arm in arms:
            rs = runs[inp][arm]
            warnings += sum(r["warnings"] for r in rs)
            tot = [r["wall"] for r in rs]
            mt = statistics.median(tot)
            delta = f"{mt - floor:+.2f} {100 * (mt - floor) / floor:+.1f}%" if floor else "-"
            ins = [sum(r["walks"].get(s, (0, 0))[1] for s in INSIDE) for r in rs]
            inn = [sum(r["walks"].get(s, (0, 0))[0] for s in INSIDE) for r in rs]
            bd = [r["walks"].get("phase_boundary", (0, 0))[1] for r in rs]
            print(f"   {arm:14s} {med(tot, s2):22s} {delta:>15s} {med([r['timing'].get('parse/read_files', 0) for r in rs], s2):22s} "
                  f"{med([r['timing'].get('finalize/group_similar', 0) for r in rs], s2):22s} {statistics.median(inn):8.0f} "
                  f"{med(ins, s2) if arm != 'tracked' else '-':20s} {med(bd, s2) if arm != 'tracked' else '-':20s} {med([r['rss'] / MB for r in rs], s1):24s}")
        if "every" in runs[inp]:
            ref = collections.defaultdict(int)
            for r in runs[inp]["every"]:
                for k, v in r["memory"].items():
                    if k.startswith(GROUPING_PREFIXES):
                        ref[k] = max(ref[k], v)
            for arm in arms:
                if arm in ("tracked", "every"):
                    continue
                got = collections.defaultdict(int)
                for r in runs[inp][arm]:
                    for k, v in r["memory"].items():
                        got[k] = max(got[k], v)
                short = [f"{k.replace('consolidation_', 'c_')} {ref[k] / MB:.1f}->{got[k] / MB:.1f}"
                         for k in sorted(ref, key=lambda k: -ref[k]) if ref[k] >= MB and got[k] < 0.95 * ref[k]]
                print(f"   {arm:14s} captured short: {'; '.join(short) or '-'}")
    print(f"\nruns whose stderr carries ' at <file> line <N>': {warnings}")


if __name__ == "__main__":
    main()
