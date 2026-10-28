# #709 P1: grouping's structure walks under `-mem`

**Question.** At grouping's two reading sites, each checkpoint
(`run_consolidation_checkpoint()`) and each final-pass window
(`process_final_pass_window()`), should `-mem` walk the named-structure map,
given what the walks cost against the high-water marks only they capture?
Record: `features/memory-tracking-improvements.md` § Prototype plan, § P1
before the timed runs, § P1 qualification of inputs and options.

## Method

- **Arms**, generated from `ltl` at `3e4cbf91` by `make-arms.pl`, every one
  but the floor carrying the 38 stores of § Store inventory in the map:
  - *floor* (`tracked`): `ltl` as tracked, without `-mem`;
  - *every call* (`every`): a walk at every checkpoint and window, as today;
  - *boundaries only* (`boundaries`): no reading inside grouping;
  - *grouping's stores only* (`grouponly`): inside grouping, a walk of the 17
    stores grouping writes, the message store among them;
  - *either count, +0 %* (`cond-either-0`): a reading inside grouping only when
    the keys held or the clusters have grown past their value at the last such
    reading.
- **Inputs**, qualified at the walk sites and approved (`candidates.txt`):
  one server's web application access logs at 1, 7 and 15 days, grouped with
  the UUID mask (`-bs 1440 -g -m uuid`) and without it (`-bs 1440 -g`); a PLM
  web server access log of one day with the query string kept
  (`-du us -g -xqs`); the general application log of 85 MB (`-g`).
- **Runs** (`run-arms.sh`): three rounds, the arm order rotated each round,
  every run under `/usr/bin/time -l` with `--disable-progress -V
  benchmark-data,memory-usage`, `-mem` on every arm but the floor. macOS,
  2026-10-28, 120 runs in 41 minutes, every one exiting 0; no run's stderr
  carries ` at <file> line <N>`.
- **Cost is the wall clock.** `-V benchmark-data`'s `TIMING total` sums the
  stages, so it leaves out the phase-boundary walks, which run between them.
  On 15 unmasked days the floor's total is 49.6 s and its wall clock 51.1 s;
  every call's 60.5 and 67.0 s.

Per-run figures: `results/p1-runs.tsv`; medians, ranges and capture per arm:
`results/p1-summary.txt`.

## Results

**Wall clock, median of three, and its difference from the floor's:**

| Input | Floor | Every call | Boundaries only | Grouping's stores only | Either count, +0 % |
|---|---|---|---|---|---|
| masked, 1 day | 2.18 s [2.15–2.56] | +6.9 % | −4.6 % | +6.4 % | +2.3 % |
| masked, 7 days | 15.79 s [15.62–16.23] | +6.2 % | +0.6 % | +8.3 % | +2.7 % |
| masked, 15 days | 39.94 s [39.25–40.23] | +7.7 % | +1.2 % | +6.4 % | +4.8 % |
| unmasked, 1 day | 3.90 s [3.88–3.93] | +19.7 % | +5.4 % | +24.1 % | +6.7 % |
| unmasked, 7 days | 20.86 s [20.51–24.88] | +31.0 % | +8.7 % | +23.2 % | +15.1 % |
| unmasked, 15 days | 51.06 s [50.64–51.82] | +31.3 % | +8.2 % | +31.7 % | +14.9 % |
| PLM access log, `-xqs` | 7.59 s [7.56–8.30] | +23.6 % | +9.0 % | +21.6 % | +18.7 % |
| general application log | 5.87 s [5.82–6.15] | +6.8 % | −3.7 % | +5.5 % | +2.6 % |

On the 1-day inputs, a few tenths of a second, the ranges are as wide as the
differences.

**Walks inside grouping, their seconds, and what each arm captures** against
the every-call arm's high-water marks, for every grouping store of 1 MB or
more:

| Input | Every call | Grouping's stores only | Either count, +0 % | Boundaries only captures |
|---|---|---|---|---|
| masked, 15 days | 39 walks, 2.84 s | 39, 2.01 s; all | 15, 1.29 s; all | clusters 102.8 → 59.1 MB, ID index 52.0 → 0.0, trigrams 27.6 → 0.5 |
| unmasked, 15 days | 32, 11.78 s | 32, 11.35 s; all | 8, 4.33 s; all | ID index 80.5 → 0.0, trigrams 40.7 → 0.1 |
| PLM access log, `-xqs` | 9, 0.83 s | 9, 0.78 s; all | 4, 0.45 s; all | ID index 209.0 → 0.0, trigrams 96.7 → 0.1 |
| general application log | 15, 0.31 s | 15, 0.32 s; all | 7, 0.12 s; ID index 111.0 → 59.4, trigrams 57.1 → 33.0 | ID index 111.0 → 0.0, trigrams 57.1 → 33.0 |

The other four inputs read the same way at smaller sizes (`results/p1-summary.txt`).
The either-count arm took exactly the readings `simulate.py` replayed for it
on all eight inputs, and missed exactly what the replay said: the replay is
confirmed as an instrument.

**The peak resident set** does not depend on the arm: on 15 unmasked days the
four `-mem` arms read 1,415.5 to 1,415.6 MB, the floor 1,401.2 MB.

## Mechanism

- **The cost is the message store, walked inside grouping.** Without the UUID
  mask, or with `-xqs`, nearly every key stays its own row, and every walk
  covers the message store: 795.8 MB of the 934.8 MB walk at 15 unmasked days.
  A walk there takes 0.37 s; 32 of them, 11.8 s.
- **Grouping's stores only saves nothing where the cost is.** The message
  store is one of the stores grouping writes, so the arm still walks it: 11.35
  against 11.78 s at 15 unmasked days. It saves only the time-bucket store,
  2.01 against 2.84 s at 15 masked days.
- **The stores that peak inside grouping are the transient ones.** The ID
  index, the key trigrams and the clusters, with the per-key maps, peak at a
  checkpoint or a window and are freed before the next boundary. The message
  store's high-water mark is caught by the boundary walks on all eight inputs.
  On the 16 qualification candidates it peaked inside grouping on three, at
  4.6 MB at most.
- **No count follows the ID index.** Its size follows the trigrams of the
  keys held, not their number: on the general application log a checkpoint
  holding 5,605 keys built a 4.0 MB index and the next, holding 5,406, a
  111.0 MB one.
- **The boundary walks are a cost of their own,** in every `-mem` arm: 4.32 s
  at 15 unmasked days. The boundaries-only arm, which walks only there, runs
  5.4 to 9.0 % above the floor on the unmasked and `-xqs` inputs.
- **The floor takes readings too.** Without `-mem`, `ltl` as tracked still
  reads the process memory at every boundary, checkpoint and window: 0.10 to
  0.47 s of `ps` launches per run (`TIMING memory/readings`). Delivery plan
  drop 3 removes them.

## Not measured

**A walk inside grouping of only the transient stores**: the `consolidation_*`
stores, leaving the message store to the boundary walks. It is the arm the
mechanism points at: it would walk the stores that peak inside grouping and
skip the one that makes the walks costly. Its cost is not known; a size ratio
from the traces would not give it, since a walk's time follows the number of
values it visits, not their bytes.
