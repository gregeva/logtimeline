#!/usr/bin/env python3
"""#709 P1: replay the reading arms over the trace arm's records.

A walk changes no store, so skipping one leaves every later count and size as
it was: which readings a conditional arm takes, and the high-water marks they
capture, follow exactly from one trace of every reading. Only the walk's time
needs the timed arms; here it is the trace run's own walk time, summed.

For each input and arm: the readings taken inside grouping, the seconds their
walks took, and each grouping store whose high-water mark the arm captures at
less than the every-call arm's, by how much.

  usage: simulate.py <trace dir> [margin percent ...]    (default 0 10 25 50 100 200)
"""
import collections
import glob
import os
import sys

# make-arms.pl @grouping_stores
GROUPING = ["log_messages", "log_messages_counters", "consolidation_clusters",
            "consolidation_patterns", "consolidation_key_message", "consolidation_unmatched",
            "consolidation_id_index", "consolidation_key_trigrams", "consolidation_cat_stats",
            "consolidation_category_unmatched_count", "consolidation_pattern_generation",
            "consolidation_key_generation", "consolidation_key_checkpoint_count",
            "consolidation_absorption_ema", "consolidation_streaming_absorbed",
            "consolidation_final_pass_skipped", "consolidation_cliff_edge"]
INSIDE = ("grouping_checkpoint", "grouping_final_pass")
MB = 1e6


def load(path):
    readings, sizes = {}, collections.defaultdict(dict)
    for line in open(path):
        f = line.rstrip("\n").split("\t")
        if f[0] == "reading":
            readings[int(f[1])] = dict(site=f[2], held=int(f[3]), clusters=int(f[4]),
                                       rss=int(f[5]), walk=float(f[6]))
        else:
            sizes[int(f[1])][f[2]] = int(f[3])
    return [dict(readings[s], seq=s, sizes=sizes[s]) for s in sorted(readings)]


def taken(trace, arm):
    """The readings an arm takes, in order."""
    if arm == "every":
        return trace
    if arm == "boundaries":
        return [r for r in trace if r["site"] not in INSIDE]
    count, margin = arm
    counts = ("held", "clusters") if count == "either" else (count,)
    high, out = dict.fromkeys(counts, 0), []
    for r in trace:
        if r["site"] in INSIDE:
            if not any(r[c] > high[c] * (1 + margin / 100) for c in counts):
                continue
            for c in counts:
                high[c] = max(high[c], r[c])
        out.append(r)
    return out


def hwm(readings):
    marks = collections.defaultdict(int)
    for r in readings:
        for store, size in r["sizes"].items():
            marks[store] = max(marks[store], size)
    return marks


def main():
    tdir = sys.argv[1]
    margins = [int(m) for m in sys.argv[2:]] or [0, 10, 25, 50, 100, 200]
    arms = ["every", "boundaries"] + [(c, m) for c in ("held", "clusters", "either") for m in margins]
    for path in sorted(glob.glob(os.path.join(tdir, "trace-*.tsv"))):
        name = os.path.basename(path)[6:-4]
        trace = load(path)
        full = hwm(trace)
        inside_total = sum(1 for r in trace if r["site"] in INSIDE)
        print(f"== {name}: {inside_total} readings inside grouping; grouping stores' every-call "
              f"high-water marks of 1 MB or more: "
              + ", ".join(f"{s} {full[s]/MB:.1f}" for s in GROUPING if full[s] >= MB))
        print(f"   {'arm':22s} {'inside':>6s} {'walk_s':>7s}  grouping stores captured short (MB, every-call -> arm)")
        for arm in arms:
            got = taken(trace, arm)
            inside = [r for r in got if r["site"] in INSIDE]
            walk = sum(r["walk"] for r in inside)
            marks = hwm(got)
            short = [f"{s} {full[s]/MB:.1f}->{marks[s]/MB:.1f}" for s in GROUPING
                     if full[s] >= MB and marks[s] < 0.95 * full[s]]
            label = arm if isinstance(arm, str) else f"{arm[0]} +{arm[1]}%"
            print(f"   {label:22s} {len(inside):6d} {walk:7.3f}  {'; '.join(short) or '-'}")


if __name__ == "__main__":
    main()
