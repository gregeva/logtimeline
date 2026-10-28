#!/usr/bin/env python3
"""#709 criterion 11: grouping's walks under -mem (D3) meet the bounds P1 set.

  capture  on each input, every grouping store (consolidation_* and the message
           store) whose reference mark is 1 MB or more reports a MEMORY row
           within 5 % of it
  cost     on 15 unmasked days (tc-g-d15), the median wall clock with -mem is
           at most 12 % above the median without it (P1 measured +9.1 %)

Every run compared is made under one pinned hash seed (criterion-11.sh): the
message store's size follows Perl's per-process hash seed by 64 bytes an entry
(features/memory-tracking-improvements.md § Drop 5, the finding). A run whose
stderr does not show the pinned seed is refused.

  usage: check-criterion-11.py reference <run dir> <arm> <seed>       > reference.tsv
         check-criterion-11.py check <capture dir> <cost dir> <arm> <seed> <reference.tsv>
"""
import os
import re
import statistics
import sys

MB = 1e6
CAPTURE_FLOOR = 0.95  # criterion 11: within 5 % of the reference
COST_CEILING = 0.12   # criterion 11: at most 12 % above the floor
GROUPING = re.compile(r"^(consolidation_|log_messages)")


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


def seeded(err_path, seed):
    """The run's stderr shows it hashed under the pinned seed."""
    for line in open(err_path, errors="replace"):
        m = re.search(r"HASH_SEED = (0x[0-9a-f]+)", line)
        if m:
            return m.group(1) == seed.lower()
    return False


def rounds(d):
    return sorted(x for x in os.listdir(d) if re.fullmatch(r"r\d+", x))


def runs_of(d, rnd, arm, seed):
    """{input: .out path} for one round and arm, every run checked for the seed."""
    out = {}
    for inp in sorted(os.listdir(os.path.join(d, rnd))):
        base = os.path.join(d, rnd, inp, arm)
        if not seeded(base + ".err", seed):
            sys.exit(f"refused: {base}.err does not show HASH_SEED = {seed}")
        out[inp] = base + ".out"
    return out


def reference(run_dir, arm, seed):
    print(f"# #709 criterion 11 reference: a walk of every store at every site, under PERL_HASH_SEED={seed}")
    print("input\tstore\thwm_bytes")
    for inp, path in runs_of(run_dir, rounds(run_dir)[0], arm, seed).items():
        for store, v in sorted(memory_rows(path).items()):
            if GROUPING.match(store):
                print(f"{inp}\t{store}\t{v}")


def check(capture_dir, cost_dir, arm, seed, ref_path):
    ref = {}
    for line in open(ref_path):
        if line.startswith("#"):
            if f"PERL_HASH_SEED={seed}" not in line:
                sys.exit(f"refused: {ref_path} was not made under PERL_HASH_SEED={seed}")
            continue
        if line.startswith("input\t"):
            continue
        inp, store, v = line.rstrip("\n").split("\t")
        ref.setdefault(inp, {})[store] = int(v)
    ok = True
    print(f"capture ({arm}, under PERL_HASH_SEED={seed[:10]}..., grouping stores of 1 MB or more):")
    for inp, path in runs_of(capture_dir, rounds(capture_dir)[0], arm, seed).items():
        got = memory_rows(path)
        big = [(s, w) for s, w in sorted(ref[inp].items(), key=lambda kv: -kv[1]) if w >= MB]
        short = [f"{s} {w / MB:.1f} -> {got.get(s, 0) / MB:.1f} MB" for s, w in big if got.get(s, 0) < CAPTURE_FLOOR * w]
        exact = sum(1 for s, w in big if got.get(s) == w)
        print(f"  {inp:16s} {len(big)} stores, {exact} byte-equal: " + ("; ".join(short) if short else "all within 5 %"))
        ok &= not short
    rs = rounds(cost_dir)
    print(f"cost (tc-g-d15, wall clock, median [range] of {len(rs)} rounds):")
    med = {}
    for a in ("tracked", arm):
        w = []
        for r in rs:
            base = os.path.join(cost_dir, r, "tc-g-d15", a)
            if not seeded(base + ".err", seed):
                sys.exit(f"refused: {base}.err does not show HASH_SEED = {seed}")
            w.append(wall(base + ".err"))
        med[a] = statistics.median(w)
        print(f"  {a:8s} {med[a]:.2f} s [{min(w):.2f}-{max(w):.2f}]"
              + (f"  {100 * (med[a] / med['tracked'] - 1):+.1f} % against the floor" if a != "tracked" else ""))
    ok &= med[arm] / med["tracked"] - 1 <= COST_CEILING
    print(f"criterion 11: {'met' if ok else 'NOT met'}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    if sys.argv[1:2] == ["reference"] and len(sys.argv) == 5:
        reference(*sys.argv[2:5])
    elif sys.argv[1:2] == ["check"] and len(sys.argv) == 7:
        check(*sys.argv[2:7])
    else:
        sys.exit(__doc__)
