# Revalidation report — #189 bin-counter primitives under the #426 proposed representation

This document is the step-2 revalidation mandated in `features/426-per-message-statistics-store.md` § *Next step — revalidating the bin-counter primitives (#189) before implementation* (architect's decision, 2026-08-24): the primitives designed in #187 and validated in #189 (`prototype/189-bin-counter-primitives-validation-report.md`, aspects V1–V5) are taken through every #189 aspect again, against the three representations the #426 proposals P8–P10 describe, in #189's approach — production primitives verbatim as the baseline arm, parity digests before any timing, medians with min–max ranges, the `calculate_statistics` exact-percentile oracle. Nothing here is locked; the per-aspect evidence and the cross-aspect tables are the architect's input for step 3 (`Dxx` decisions in the #426 record; explicit amendments in the #187 record where a locked decision changes).

Arms (`prototype/426-revalidate-lib.pm`, package `Revalidate426`):

- **T — today.** Production primitives copied verbatim from `ltl` (`partition_new`, `partition_extend`, `partition_rebin`, `bin_assign`, `counter_update`, `percentile`, `merge_bin_counter_entries`); keyed hash of `{partition, bins (dense from 0), overflow, underflow}`; per-key partition seeded ±2.5 decades around the first sample, HdrHistogram doubling with geometric-midpoint remap.
- **S — span-only columnar, verbatim geometry (P8+P9).** Same arithmetic as T; partition fields as per-row columns and `bins[row] = [base_index, c0, c1, …]` over the occupied span. Must be digest-identical to T.
- **G — shared log-spaced grid, span-only (P10).** One grid per store, `index = floor(bpd × log10(value))`, boundaries `10^(i/bpd)`; per-key storage is the occupied span; no seed, no rebin, no overflow/underflow; merge = index-wise add; percentile = the #187 Decision 1 walk verbatim over grid boundaries.

The precision lever is the same number in every arm: one bin is `10^(1/bpd) − 1` wide (4.44% at bpd 53, 2.02% at 115, 0.90% at 256, 0.37% at 616).

Companion prototypes: `prototype/426-revalidate-v{1,2,3,4,5}.pl` (+ drivers `.sh`, `-run.sh`, `-tables.pl`, `-probe.pl`, `-memvar.sh`). Per-aspect results: `prototype/426-results/revalidate-vN.md`; every captured run under `prototype/426-results/revalidate-vN-*`. Each completed aspect was independently verified against its captured files; the verifier's verdict and open issues are recorded at the end of each aspect section.

Contract references: `features/187-histogram-bin-counter-percentiles.md` § *Locked decisions from research* (F1, D1/D1A, D2, D3, D4, D5, D7, D8); `features/189-histogram-bin-counter-primitives.md` § R1–R12.

## Validation aspects

| Aspect | What is being revalidated | Status |
|---|---|---|
| V1 | In-bin formula edge cases on G; R2 closed-form vs boundary cross-check on the grid; #189 R5 determinism, insertion order, merge commutativity | **complete** — verifier: confirmed (2 medium, 2 low issues, recorded below) |
| V2 | Per-key fan-out at scale (51,469 keys), per-line fill cost, merge and `-g` fold cost, memory projection to 10⁵ keys | **complete** — verifier: confirmed (3 low issues, recorded below) |
| V3 | Seeding heuristic, span growth, overflow/underflow audit, non-positive and extreme inputs | **complete** — verifier: confirmed (7 low issues) |
| V4 | `-V histogram-bin-counters` (Decision 8) section rendered from each arm against real ltl, six #189 V4 scenarios mapped onto today's #293 lever | **complete** — verifier: confirmed (4 low issues) |
| V5 | Accuracy vs the `calculate_statistics` oracle per key, on small-N keys, after one merge and after seven merges, at bpd 53/115/256/616 | **complete** — verifier: confirmed (5 low issues) |
| V6 | Display-geometry-bound consumers (heatmap and histogram; the #187 D5 F2/F3 stream→finalize contract; #189 R12 `partition_rebin` as the finalize step) under all three arms, at the five streaming resolutions those surfaces resolve to | **complete** (2026-08-25) |
| V7 | The bucket-stats surface — the fourth `%TIER_BPD` surface: bounded partition cardinality with large per-partition N, `percentile` read directly off the streaming partition, and the `[min,max]` clamp | **complete** (2026-08-25) |
| V8 | Merge shapes beyond consecutive pairs and the `-g` fold: rollup into one target, maximally disjoint spans, merge depth 1/3/7/15, order permutations | **complete** (2026-08-25) |
| V9 | The re-bless enumeration against the committed statistics-drift baselines, the accuracy decomposition by key shape, and the store cost measured at the motivating scale | **complete** (2026-08-25) |

Two aspects were extended in place rather than given their own numbers: the **native span merge for S** re-measures V2's merge and fold numbers and is folded into V2 as an addendum; the **`-V` audit aggregation scope and the Decision 8 field census** extend V4 and are folded into V4 as an addendum.

The primary surface is the one #189 used: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (277 MB, 1,430,678 lines, 857,480 positive durations, 573,198 zeros excluded, 4,153 keys, 328 with N ≥ 100). V4 uses the 2.6 MB iteration file (635 keys); V2's fan-out file is the 67 MB 2026-01-14 log (51,469 keys). The 2026-08-25 aspects add three further surfaces: the DPM ScriptLog (`logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log`, 122,808 lines, 122,798 positive durations, 3,419 keys — and the `/tmp/ltl-426-fixtures/bin-dpm-full.log` copy of the same corpus), the 148 MB Tomcat access log (`logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt`, 761,698 lines, 575,800 positive durations, 3,074 keys), and the fan-out fixture `/tmp/ltl-426-fixtures/bin-twxdur-full.log` (288,025 lines, **286,659 distinct keys**, only 148 with N ≥ 2).

---

## V1 — In-bin edge cases, R2 cross-check, determinism

Results: `prototype/426-results/revalidate-v1.md`. Captures: `revalidate-v1-partA.txt`, `revalidate-v1-partBC-2025-05-05.txt` (+ `.time.txt`), `revalidate-v1-r2-offenders.tsv`, `revalidate-v1-determinism.tsv`.

### Hypothesis

The Decision 1/1A walk is arithmetic over `(lower, upper, rank_in_bin, count)` and does not care where the boundaries come from, so every #189 V1 edge case should hold on G with the same value/audit semantics, except those that exist only because T has per-key partition state (`lower = upper`, zero-count partition, overflow/underflow), which become vacuous. The R2 cross-check should reproduce #189's zero disagreements except at exact powers of ten (closed form one ULP low on a grid boundary). #189 R5 should hold for both arms; G should additionally be order-independent and merge-commutative.

### Method

Part A (bpd 53 and 616): the eight #189 V1 scenarios re-read for G (A1 `bin_count=1`, A2 `lower=upper`, A3 single observation, A4 `fraction=0`, A5 zero-count, A6/A7 all-overflow/all-underflow — direct entry as #189 did, plus through the store with T under the prototype's `max_rebins=0` cap and the same inputs fed to G), A8 exact powers of ten, A9 values exactly at `10**(i/bpd)`, A10 tiny/huge values (1e-3, 1e-6, 1e12; separately and in one key), A11 value 0 and −5 under a 5 s alarm, A12 identical value × N (1, 2, 1000); 7 quantiles, both rank conventions; every scenario asserts the T↔S digest. Part B (277 MB file read once): for every distinct value, G closed-form index vs boundary-checked index at bpd 53/115/256/616; T/S/G full-file digests at 53 and 616. Part C: the first 200 keys with N ≥ 20 fed in file order, reversed and `srand(426)`-shuffled (per-key canonical, geometry, 7 percentiles compared across orderings), then `merge(a,b)` vs `merge(b,a)` for 200 consecutive-key pairs. No timing (no timed hypothesis).

### Result

Part A: 92 PASS / 0 FAIL at both bpd (`revalidate-v1-partA.txt`).

| # | scenario | T (verbatim) | G (grid) |
|---|---|---|---|
| A1 | `bin_count=1`, q 0.5/0.99 | returns `upper`, audit none | returns grid `upper`, audit none; span 1 |
| A2 | `lower=upper` | synthetic partition returns the value as #189; unreachable through `partition_new` (min 0.00316 < max 316.2 for v0=1) | cannot occur: `10**(i/bpd) < 10**((i+1)/bpd)` verified for i ∈ [−2000, 2000] |
| A3 | single observation (42) | `upper`: +2.196% @53, +0.0000% @616 | `upper`: +4.294% @53, +0.029% @616 |
| A4 | `fraction=0` | unreachable (`target_rank <= cum`) | same walk, same property |
| A5 | zero-count | `(undef,'none')` | `(undef,'none')`; no partition state exists to be zero-count |
| A6 | all-overflow (seed 1, then 5 × 1e6) | under cap 0: overflow=5, q=0.9 → `boundary[B]` = 316.23, audit high — 3.5 decades below the true value (185.5 bins @53 / 2,156 @616) | span 318, q=0.9 → 1,000,000, audit none, rel err 0 |
| A7 | all-underflow (seed 1, then 5 × 1e-6) | under cap 0: q=0.1 → `boundary[0]` = 0.00316, audit low | span 319, q=0.1 → 1.0087e-6, audit none (0.87%, within one bin) |
| A10 | one key {1e-6, 1e-3, 1, 1e12} | 3 rebins, bin_count 1,192 @53 / 13,859 @616; max error at q=0.5 **0.96 bins @53, 1.38 bins @616** | span 954 / 11,088 slots; every quantile ≤ 1.00 bins |
| A11 | value 0 | `partition_new` dies `Illegal division by zero`; on an existing partition `partition_extend` divides `new_min` 130 times to 0 then dies | dies `Can't take log of 0` |
| A11 | value −5 | **unbounded loop, alarm fired** (first sample and existing partition) | dies `Can't take log of -5` |
| A12 | 250 × N (1, 2, 1000) | one occupied bin; max rel err 2.196% (0.49 bins) @53; ≤ 0.99 bins @616 | span 1; 4.029% (0.91 bins) @53, 0.325% (0.87 bins) @616 |

A8/A9: 4 of 8 exact powers of ten (1000, 1e5, 1e6, 1e9) and 3 (@53) / 5 (@616) of 8 exact grid boundaries land one index low in G's closed form; in every such case the value is the closed bin's *upper* boundary and the single-add percentile returns it exactly (+0.0000%). T's closed form has the same ULP property (a power-of-ten sample seeded at the partition centre lands in bin 1539 of 3080 @616, `int(1540 − ε)`).

Part B (`revalidate-v1-partBC-2025-05-05.txt`): 985 distinct values, 857,480 observations; disagreements 1 value / 38 observations at every bpd — the value 1000 (closed 158 → checked 159 @53; 344→345, 767→768, 1847→1848). No other near-boundary case occurred. Full-file digests: T = S at bpd 53 (`3962d9c2…`) and 616 (`8bb68875…`), 4,153 keys; T rebin telemetry 7 events, max 1 (= #189 V3). G span p50/p95/p99/max = 1/26/78/175 @53 (index range [0, 302]), 1/294/907/2,028 @616 ([0, 3517]). Devel::Size T / S / G: 10.04 / 3.61 / 2.08 MB @53; 59.9 / 8.38 / 6.85 MB @616. Whole run 17.2 s, 174 MB max RSS.

Part C (`revalidate-v1-determinism.tsv`):

| bpd | arm | orderings: keys canonical-different / percentiles different | max diff (rel / bins) | merge pairs: canonical different / bins+geometry different / percentiles different |
|---|---|---|---|---|
| 53 | T | 105 / 105 of 200 | 3.877% / 0.873 | 2 / 0 / 0 of 200 |
| 53 | G | 0 / 0 | 0 | 0 / 0 / 0 |
| 616 | T | 105 / 105 | 0.369% / 0.985 | 2 / 0 / 0 |
| 616 | G | 0 / 0 | 0 | 0 / 0 / 0 |

T's two merge canonical differences (pairs 130/131 and 131/132) are the `rebins` telemetry field, which `partition_rebin` resets on the rebinned side only; bins, boundaries and percentiles are identical in both directions.

### Surprises

- Negative values hang the verbatim `partition_extend` (A11): `partition_new(−5)` yields min > max and the doubling loop never terminates; 0 dies after 130 doublings. Production never passes either (ltl guards `> 0` before `counter_update`); the primitive has no guard. G dies immediately on both.
- T's remap breaks the one-bin bound on a wide-range key through `partition_extend` alone (A10 @616: 1.38 bins after three doublings); G stays ≤ 1.00 bins.
- T is order-dependent at the digest and percentile level (105 of 200 keys; up to 0.87–0.99 bins) because the seed is the first sample; #189 R5 promises only fixed-sequence determinism, which holds. G: 0 of 200 keys, 0 of 200 pairs.
- The only real-data R2 disagreement is the value 1000 (38 occurrences) — the ULP of `log(1000)/log(10)`, not a grid defect; the boundary-checked index restores the bound on every value.

### Findings and actions

1. **Decision 1/1A hold on G unchanged** (A1, A3, A4, A12): same value/audit semantics on the grid as on the partition; the formula is grid-agnostic.
2. **Decision 1's `lower = upper` guidance case is vacuous on both geometries** (A2): `partition_new` cannot produce it and the grid cannot by construction; #189 V1 tested it on a synthetic partition only.
3. **Decision 4 and #189 R6 become vacuous under G** (A5–A7): no partition edge, no over/under terms in `total_N`, audit always `none`. With T's cap inputs G answers exactly. The T numbers in A6/A7 are produced under the prototype's `max_rebins=0` cap, which production does not have (ltl's own comment: "only reachable when a future growth cap is added — none today"); uncapped T would extend and answer within one bin.
4. **#189 R2 closed-form vs boundary agreement holds on real data except at exact powers of ten** (1 of 985 values, 38 of 857,480 observations, identical at four bpd): one index low, zero attribution error, bound not violated. A convention for G's grid index (closed form as-is, or boundary-checked at ~2 extra `**` per add) must be recorded; the digest baseline depends on it.
5. **Both representations need the same `v > 0` guard** (A11): T loops forever on a negative, dies on 0; G dies on both. The caller-side guard is load-bearing for every arm; #189 R4's "positive-only substrate" note should say the primitive is undefined, not merely unused, for v ≤ 0.
6. **#189 R5 holds for both arms for a fixed sequence; G is additionally order-independent and merge-commutative** (0/200 keys, 0/200 pairs); T's merge is commutative on bins and boundaries but not on the `rebins` telemetry field (2/200).
7. **T↔S parity holds on the Tomcat access log** at bpd 53 and 616 on 4,153 keys and in every Part A scenario including the cap and the 0/−5 failure modes; P8+P9 carry #189 V1 by construction.
8. **G's span is proportional to the key's value range, not capped by the seed** (A10: 954 / 11,088 slots for 18 decades, 9.3 KB / 96 KB vs T's 11.3 KB / 112 KB dense partition); on real data span p99 = 78 @53 / 907 @616 against T's fixed 265 / 3,080.

### Verifier

Verdict **confirmed**. Issues: (medium) the aspect's `.md` and its structured result quote T's all-overflow error as "22–267 bins" / "6 decades" — those figures are relative error ÷ bin width, not a bin distance; the true distance is 3.5 decades (185.5 bins @53 / 2,156 @616) and the underflow case is the same 3.5 decades. Corrected above; conclusions unaffected. (medium) The A6/A7 T-vs-G comparison runs T under the synthetic `max_rebins=0` cap; the `.md` Surprise "All-overflow on T is a 22–267 bin error" reads as a T defect but is cap-induced. Stated above. (low) Structured-result F8 quotes T memory 11,298 / 112,370 B; the captured file says 11,362 / 112,434 B (the rounded 11.3 KB / 112 KB used above is consistent with the capture). (low) F4's explanation of why #189 V1 saw zero disagreements is a supposition; the operative difference is that G's boundaries sit at exact powers of ten, which integer-millisecond data hits, whereas T's seeded boundaries generally are not hit by integer samples.

### Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
perl prototype/426-revalidate-v1.pl --part A > prototype/426-results/revalidate-v1-partA.txt 2>&1
/usr/bin/time -l perl prototype/426-revalidate-v1.pl --part BC \
    --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
    > prototype/426-results/revalidate-v1-partBC-2025-05-05.txt \
    2> prototype/426-results/revalidate-v1-partBC-2025-05-05.time.txt
# side files: revalidate-v1-r2-offenders.tsv, revalidate-v1-determinism.tsv
perl prototype/426-revalidate-v1.pl --help
```

---

## V2 — Per-key fan-out at scale, per-line, merge and fold cost

Results: `prototype/426-results/revalidate-v2.md`. Captures: `revalidate-v2-parity-{T,S}-bpd{53,616}.txt`, `revalidate-v2-{T,S,G}-bpd{53,616}.txt`, `revalidate-v2.tsv`, `revalidate-v2-postcheck.txt`, `revalidate-v2-driver.txt`. Fixture: the #189 fan-out file `logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-0.2026-01-14.txt` (67 MB, 343,143 lines, 339,832 positive durations, 3,311 zeros excluded, **51,469 keys with a positive duration** = #189 V2's 51,469 partitions).

### Hypothesis

T must reproduce #189 V2 on this file (51,469 partitions, 116.86 MB, 2,381 B/partition, 227 MB projected at 10⁵ keys, +12.3% over #187 D2's ~212 MB, 6 rebin events, 1.63 s closed-form fill with parsing included). S, digest-identical by construction, should cost a fraction of T's memory (a key's occupied span, p50 = 1 bin, instead of a dense array) and G less again (no partition fields); S's and G's memory should scale with bpd only through span width while T's scales with `bin_count`. Fill should be cheapest on G (one `floor(bpd·log10 v)`, no range check, no seed) and so should merge and fold (index-wise add, no union remap). S runs the verbatim `merge_bin_counter_entries` through dense views of both rows, so S's merge is expected to be no faster than T's — how much slower is the measurement.

### Method

Phases 0–7 of `426-revalidate-v2.pl`, one arm and one bpd per process (`--arm T|S|G --bpd N --runs 3`). Phase 0 parses once into `(key, duration)` arrays so every timed section measures the store, not the regex (parse wall-clock reported separately, 1.25–1.30 s, Perl v5.42.2). Phase 1 is the parity gate: T and S run `--parity-only` at both bpd and the driver asserts equal `fill_digest` and key count before any timed run. Then: 3 timed fills into a fresh store (phase 2); `Devel::Size::total_size` of the store plus the phase-1 RSS delta, per key and projected to 10⁵ keys, with the verbatim `snapshot_counter_telemetry` for T/S and span/index telemetry for G (phase 3); occupied-span, `bin_count` and T dense-array-length distributions (phase 4); all keys × 7 quantiles under the `ceil` convention with a `pct_digest` (phase 5); 725 disjoint consecutive-key pairs with N ≥ 2 merged with `drop_source`, remap accounting from the untouched store, N conservation (phase 6); the `-g` fold shape — every other key merged into the first, 51,468 merges — with the accumulator's final geometry, digest and 7 percentiles (phase 7). Medians of 3 with min–max throughout; `caffeinate -s` around every run. Driver step 3 post-checks `fill_digest`, `pct_digest`, `merge_digest`, `fold_digest`, key counts and `fold_percentiles` equal between T and S at both bpd, and N = 339,832 for all three arms: `ALL PASS` (`revalidate-v2-postcheck.txt`).

### Result

Parity (`revalidate-v2-parity-*`): `PASS bpd=53 T==S fill digest c87c9822… keys=51469`, `PASS bpd=616 … a0ac7c4c… keys=51469`.

Fill and memory (phases 1–3):

| bpd | arm | fill s median (min–max) | ns/sample | Devel::Size MB | B/key (Devel) | B/key (RSS) | 10⁵ keys (Devel) | 10⁵ keys (RSS) |
|---|---|---|---|---|---|---|---|---|
| 53 | T | 0.500 (0.481–0.518) | 1,471 | **116.86** | **2,381** | 2,428 | **227.1** (+12.3% vs D2's 212 MB) | 231.5 |
| 53 | S | 0.349 (0.335–0.364) | 1,026 | 46.90 | 955 | 598 | 91.1 | 57.0 |
| 53 | G | 0.216 (0.214–0.223) | 635 | 29.46 | 600 | 198 | 57.2 | 18.9 |
| 616 | T | 0.552 (0.529–0.572) | 1,623 | 673.92 | 13,730 | 15,761 | 1,309.4 | 1,503.1 |
| 616 | S | 0.362 (0.334–0.394) | 1,065 | 57.57 | 1,173 | 833 | 111.9 | 79.4 |
| 616 | G | 0.210 (0.210–0.212) | 619 | 40.09 | 817 | 452 | 77.9 | 43.1 |

T reproduces #189 V2 exactly, including `total_rebin_events=6`, rebins p50/p95/p99/max 0/0/0/1, `max_partition_bins=397`, no overflow/underflow; S's telemetry is identical. #189's 1.63 s closed-form (parse included) corresponds to 1.29 + 0.50 = 1.79 s here. From bpd 53 to 616 T's memory grows 5.77×, S 1.23×, G 1.36×.

Distributions (phase 4): occupied span p50/p95/p99/max/mean = 1/1/44/210/2.07 @53 and 1/1/503/2,436/13.49 @616, identical for T, S and G (G's max is 2,437 at 616); `bin_count` p50 = 265 / 3,080, max 397 / 4,619; T's dense `bins` array p50 = 133 / 1,540, mean 133.64 / 1,547.42, max 300 / 3,488. G's index range after fill: [0, 286] / [0, 3327].

Percentile pass, 360,283 evaluations (phase 5): T 7.470 s (20.73 µs/eval) / S 0.952 (2.64) / G 0.787 (2.19) at 53; T 75.190 (208.70) / S 1.271 (3.53) / G 1.024 (2.84) at 616. `pct_digest` S = T at both bpd. T's cost is 78 ns (@53) / 68 ns (@616) per `bin_count` slot — the walk over the full partition.

Merge, 725 consecutive pairs (phase 6): T 89.17 µs/merge / S 121.07 / G 5.81 at 53; T 753.75 / S 1,047.15 / G 29.23 at 616. `merge_digest` S = T; N conserved at 339,832 in every arm. T/S remapped 725 of 725 pairs (100.0%) at both bpd (723 targets / 722 sources at 53, 725/725 at 616) against G's 0; max partition after the pairs grows 397 → 499 (4,619 → 5,803).

`-g` fold, 51,468 merges (phase 7): T 3.280 s (63.74 µs/merge, 6.6× its fill) / S 5.872 (114.10, 16.8×) / G 0.0927 (1.80, 0.43×) at 53; T 33.222 (645.49, 60.2×) / S 60.475 (1,175.01, 167.1×) / G 0.1166 (2.27, 0.55×) at 616. `fold_digest` and `fold_percentiles` S = T; N conserved; accumulator geometry 531 bins / 288-slot span at 53 and 6,174 / 3,328 at 616 over min 0.00316228, max 3.34095e7, 10.024 decades. T-vs-G fold quantiles differ by at most 0.61 bins at every quantile (G−T in bins: +0.45, −0.56, +0.11, +0.03, +0.23, +0.15, −0.11 at 53; +0.61, −0.25, +0.45, −0.15, −0.12, +0.26, −0.11 at 616); the T accumulator's bin width is 4.443% at 53 (grid 4.4403%) and 0.3745% at both at 616, with a different phase (T's bins start at the accumulator's min).

### Surprises

- **S's merge and fold are slower than T's** (1.36–1.39× on pairs, 1.79–1.82× on the fold) although its fill and percentile are faster. `Store::S::merge` calls `entry()` on both rows, which builds a dense array plus a partition hash per side (`_dense_view`), hands them to the verbatim `merge_bin_counter_entries`, then `_span_from_dense` scans the union from index 0 and copies the span back — and in the fold the accumulator is the target of all 51,468 merges, so its dense view (419 / 4,867 slots) is materialised and re-trimmed each time. The arithmetic matches: S's extra 530 µs at 616 ≈ 3,328 view + 6,174 scan + 3,328 copy at ~41 ns/slot; the extra 50 µs at 53 ≈ 288 + 531 + 288 at ~46 ns. This is the dense-view harness, not the span representation.
- **T's dense array is half the partition, not the partition.** `counter_update` seeds `bins => []` and writes `$bins->[$idx]++`, so a single-sample key at the seed centre allocates 133 slots at 53 (index 132 of 265) and 1,540 at 616 (1,539 of 3,080), all NULL but one — 1,069 B / 12,379 B per key at the mean length. That is the whole of T's bpd sensitivity while the occupied span p50 stays 1. `partition_extend` also returns a sparse array; only `partition_rebin` zero-fills to `bin_count`, hence `dense_len_max` 300 < `bin_count_max` 397 after the fill and `fold_dense_len` = `bin_count` after the fold.
- **T's percentile walks the full partition** (`0 .. bin_count − 1` with `// 0` on every slot) for keys whose median span is one bin.
- **Every one of the 725 pairs needs a remap in T/S**: consecutive keys seed on different first samples, so the union geometry matches neither side and the pair cost is always the double rebin.
- **The fold reports `fold_rebins=0`** on an accumulator re-geometried from 265 to 531 bins (3,080 → 6,174): `partition_rebin` returns `rebins => 0`, so `-V` rebin telemetry does not count merge-driven rebins even on T (V1 saw the same field property on the commutativity test).
- **RSS delta undercuts Devel::Size for S and G** (598 vs 955 B/key at 53; 198 vs 600) but not for T (2,428 vs 2,381): S and G allocate less than the arena slack the parse phase's freed temporaries leave (RSS after parse 96–98 MB in every process), so RSS is a lower bound and Devel::Size — which also counts the key column's scalars — an upper one. Both projections are reported.

### Findings and actions

1. **T reproduces #189 V2 to the byte** (51,469 partitions, 116.86 MB, 2,381 B/partition, 227.1 MB at 10⁵, +12.3%, 6 rebins, max 397 bins); parse + fill 1.79 s against #189's 1.63 s parse-included figure.
2. **S vs T (P8+P9)**: digest-identical at fill, percentile, merge and fold at both bpd; 2.49× / 11.7× less memory by Devel::Size (4.06× / 18.9× by RSS delta); fill 0.70× / 0.66× of T's time; percentile pass 7.8× / 59× faster; merge 1.36× / 1.39× and fold 1.79× / 1.82× **slower**. The merge/fold cost is the dense-view harness. **P9's merge must be written natively over the span array before S's merge/fold numbers mean anything**; the fill, memory and percentile numbers stand.
3. **G vs S (P10 vs P8+P9)**: G is cheaper on every axis — memory 600 vs 955 B/key at 53 and 817 vs 1,173 at 616; fill 635 vs 1,026 ns/sample (619 vs 1,065); percentile 2.19 vs 2.64 µs (2.84 vs 3.53); merge 5.8 vs 121 µs (29 vs 1,047); fold 1.80 vs 114 µs (2.27 vs 1,175). The merge/fold gap (21–36× pairs, 63–518× fold) is structural; the fill/percentile gap (1.2–1.7×) is the per-key partition state S carries.
4. **#187 D2's ~212 MB projection describes T's layout only.** Under S the same 10⁵ keys project to 91 MB (Devel::Size) / 57 MB (RSS) at bpd 53, under G to 57 MB / 19 MB — 2.3–11× below the guidance — and the bpd dependence changes shape (T 5.77×, S 1.23×, G 1.36×). The "(B+2) counters × 8 bytes" model and #189 finding 4's +11–12% Perl-overhead note need replacing by a span-based model (per-key fixed overhead + 8 B × occupied span) if P9 or P10 is adopted.
5. **What the `-g` fold costs**: under T/S it is the dominant per-run cost at this cardinality and scales with `bin_count` (645 µs/merge at 616 ≈ 15.4k slot operations at ~42 ns); under G it scales with the source span and stays below the fill. Any P8/P9 implementation that keeps `merge_bin_counter_entries`' rebin-on-every-merge inherits 3–60 s folds here.
6. **G's merge cost is bounded by the source's occupied span, not by bpd**: 5.03× from 53 to 616 on the pairs (spans of N ≥ 2 keys widen 6.5×) but only 1.26× on the fold, whose sources are mostly single-bin keys.
7. **Rebin telemetry is unchanged on S and vacuous on G**; V2 adds that the merge-driven rebin in the fold is invisible to that telemetry even on T (`fold_rebins=0`).

### Verifier

Verdict **confirmed**. Issues (all low): the structured finding on the S merge mechanism cites "`entry()`/`_dense_view` (956–963)" in `prototype/426-revalidate-lib.pm` — `_dense_view` is at 956–963 but `Store::S::entry()` is at 1041–1047, a mis-citation only (the mechanism is verified correct in the source). The structured finding on the fold quantiles reports the T-vs-G differences as unsigned magnitudes; three of seven at 53 and four of seven at 616 are negative (the `.md` table and the table above carry the signs; the ≤ 0.61-bin claim is unaffected). `revalidate-v2-driver.txt` is truncated after launching arm T bpd 53, so the driver log does not itself attest to the provenance of the six timed captures, `revalidate-v2.tsv` or `revalidate-v2-postcheck.txt` — disclosed in the Reproduction section below; each capture is self-describing (arm, bpd, file, runs, Perl version) and mutually consistent (identical parse counts across all six; identical T/S fill, pct, merge and fold digests).

### Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
F=logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-0.2026-01-14.txt
O=prototype/426-results

# driver (parity pass -> timed pass -> post-check; exits non-zero on any T/S divergence)
prototype/426-revalidate-v2.sh --file $F --bpds "53 616" --arms "T S G" --runs 3

# the per-arm commands that produced the captured files (run one process at a time)
for bpd in 53 616; do for arm in T S; do
  caffeinate -s perl prototype/426-revalidate-v2.pl --file $F --arm $arm --bpd $bpd --parity-only \
    > $O/revalidate-v2-parity-$arm-bpd$bpd.txt 2>&1
done; done
for bpd in 53 616; do for arm in T S G; do
  caffeinate -s perl prototype/426-revalidate-v2.pl --file $F --arm $arm --bpd $bpd --runs 3 \
    > $O/revalidate-v2-$arm-bpd$bpd.txt 2>&1
done; done
# revalidate-v2.tsv = header + `grep '^TSV' | cut -f2-` over the six timed captures;
# revalidate-v2-postcheck.txt = the driver's step-3 comparison over the same six files.
perl prototype/426-revalidate-v2.pl --help
```

The captured driver log shows the parity pass (both PASS) and the launch of the first timed arm; that invocation was cut off, and the six timed captures were produced by the per-arm commands above, then collected and post-checked with the driver's step-2/step-3 logic.

### V2 addendum — the native span merge for S (arm S2)

Captures: `prototype/426-results/native-span-merge/` — `parity-edge-bpd{53,616}.txt`, `parity-dpm-bpd{53,616}.txt`, `parity-fanout-50000-bpd{53,616}.txt`, `pairs-fanout-bpd{53,616}.txt`, `timing-fanout-full-bpd{53,616}.txt`, `span-invariant.txt`. Instruments: `prototype/426-native-span-merge.pl` (`--mode parity|timing`), `-pairs.pl`, `-invariant.pl`, `.sh`.

V2 finding 2 recorded that **P9's merge must be written natively over the span array before S's merge/fold numbers mean anything**. It now has been. Arm **S2** (`Revalidate426::Store::S2`, `@ISA = Revalidate426::Store::S`) inherits `add`/`_extend`/`percentile`/`entry`/`geometry`/`canonical`/`telemetry`/`memory_bytes` from S unchanged and overrides **only `merge`**, so any divergence between S and S2 is attributable to the merge alone. `_remap_span` walks only the occupied span, computing each destination index with the same expression in the same order the shipped `partition_rebin` uses (`midpoint = sqrt(bin_boundary(i)·bin_boundary(i+1))`, then `int(new_bin_count · log(midpoint/new_min) / new_log_ratio)`, clamped), never allocating `new_bin_count` slots; the add loop grows the target span leftwards by exactly the overhang and adds only the source's occupied slots. The shipped control flow is reproduced exactly: union geometry → rebin the target if its geometry differs → align the source if its geometry differs → index-wise add → sum overflow/underflow.

The shipped `merge_bin_counter_entries` **rebins both sides** into a union geometry (`my $union_bin_count = int($bpd * $union_decades);` followed by two conditional `partition_rebin` calls) — not "extend the narrower side" as #287 R2.3's prose says. S2 is built against the shipped mechanism, which is why it reaches bit-identical digests.

**Parity, before any timing.** 155 IDENTICAL assertions across six captures, comparing whole-store MD5 digests across T, S and S2:

| scope | bpd | cases | result |
|---|---|---|---|
| hand-built edge cases A1–A20 | 53, 616 | 20 each | **T = S = S2 on all 20, both bpd** |
| A21 aliasing probe | 53, 616 | 1 each | T differs; **S2 = S** |
| DPM fixture: 725 consecutive-pair merges | 53, 616 | digest + N | **IDENTICAL**, N = 122,798 conserved |
| DPM fixture: 3,418-merge `-g` fold | 53, 616 | digest + 7 percentiles + geometry | **IDENTICAL** |
| fan-out fixture (50k lines): 5,000 pair merges | 53, 616 | digest + N | **IDENTICAL**, N = 50,000 conserved |
| fan-out fixture (50k lines): 49,842-merge fold | 53, 616 | digest + 7 percentiles + geometry | **IDENTICAL** |
| fan-out fixture (full, 286,659 keys): 5,000 pairs | 53, 616 | digest | **IDENTICAL** (`93d28ae5…` / `a300ba83…`) |

The edge cases cover empty target (A1), empty source (A2), both empty (A3), disjoint spans (A5, A11), one span entirely inside the other (A6, A7), unions that force a rebin (A8, A9, A14, A15, A17, A18), identical geometry (A4), single samples (A10), 500 identical values (A12), `drop_source` (A13), all-one-bin (A16), merge-then-extend (A19) and a 20-key chained fold (A20). Parity is proved at the representation level too, not only through the digest projection: `span-invariant.txt` compares S's and S2's **raw** span arrays element for element after the full DPM fold — `bpd=53 bin_count=544 span_len=281 base=131 RAW-SPAN IDENTICAL`, `bpd=616 bin_count=6324 span_len=3245 base=1539 RAW-SPAN IDENTICAL`, no `undef` inside the span, base within `[0, bin_count)`, no leading or trailing zero.

**Timing** — fan-out fixture (288,025 lines, 286,659 distinct keys), Perl v5.42.2, `caffeinate -s`, medians of 3 with min–max, one untimed warmup.

Merge pairs, 5,000 consecutive pairs, fill **outside** the timed region (`pairs-fanout-bpd{53,616}.txt`):

| bpd | arm | median s | min–max s | µs/merge | vs S | vs T |
|---|---|---|---|---|---|---|
| 53 | T | 0.3590 | 0.3378–0.3706 | 71.80 | — | 1.00× |
| 53 | S (dense view) | 0.4590 | 0.4542–0.4597 | 91.80 | 1.00× | 0.78× |
| 53 | **S2 (native)** | **0.0727** | 0.0709–0.0732 | **14.55** | **6.3×** | **4.9×** |
| 616 | T | 3.5195 | 3.4746–3.5352 | 703.90 | — | 1.00× |
| 616 | S (dense view) | 4.5105 | 4.4060–4.5600 | 902.10 | 1.00× | 0.78× |
| 616 | **S2 (native)** | **0.2682** | 0.2647–0.2752 | **53.64** | **16.8×** | **13.1×** |

`-g` fold, 286,658 merges into one accumulator (`timing-fanout-full-bpd{53,616}.txt`, fill-subtracted):

| bpd | arm | median s | min–max s | µs/merge | vs S | vs T |
|---|---|---|---|---|---|---|
| 53 | T | 18.2006 | 18.1471–18.2060 | 63.49 | — | 1.00× |
| 53 | S (dense view) | 34.3621 | 34.2508–34.4488 | 119.87 | 1.00× | 0.53× |
| 53 | **S2 (native)** | **3.6454** | 3.6336–3.6642 | **12.72** | **9.4×** | **5.0×** |
| 616 | T | 199.5215 | 197.9879–201.0986 | 696.03 | — | 1.00× |
| 616 | S (dense view) | 414.1805 | 410.9016–414.7124 | 1444.86 | 1.00× | 0.48× |
| 616 | **S2 (native)** | **16.1192** | 16.0283–16.3002 | **56.23** | **25.7×** | **12.4×** |

The scaling exponent is the structural proof, not just the constant. Fold cost from bpd 53 to 616: **T ×10.96, S ×12.05, S2 ×4.42**. T and S track `bin_count` (544 → 6,324, ×11.6) because both walk the full partition width; S2 tracks the source spans, which in a fold are overwhelmingly single-bin keys.

**Findings (addendum).**

8. **The native span merge is digest-identical to the dense-view S and therefore to T, in every scope measured** — bit-identical, not approximately equal, because `_remap_span` evaluates the same double expression in the same order as `partition_rebin`.
9. **S's merge disadvantage was entirely the dense-view harness, and the native merge removes it and then some.** The V2 conclusion "S's merge and fold are slower than T's" no longer stands. Across V2 and this addendum S is now faster than T on every axis measured: fill (0.70× / 0.66× of T), memory (2.49× / 11.7× less by Devel::Size), percentile (7.8× / 59× faster), merge (4.9× / 13.1× faster) and fold (5.0× / 12.4× faster). The remaining S-vs-T questions are semantic, not cost: the aliasing difference (item 10) and the accuracy properties S inherits from T's remap (V5 finding 2 — S2 inherits those unchanged, since it reproduces the same projection bit-for-bit).
10. **The native merge does not preserve the verbatim adopt-by-reference aliasing, and cannot.** The shipped `merge_bin_counter_entries` adopts the source's `partition` hashref and `bins` arrayref by reference when the target is empty; S2 copies the span, exactly as S already does — a columnar row cannot share an arrayref with another row without the two corrupting each other on the next `add()` and on `_bump_offset_dense`'s splice. Probe A21 (adopt into an empty target, then `add` to **both** keys) makes it observable at bpd 53: T `c6f0afcb055c…`, TGT p50/p99 30.2783 / 50.9973; S and S2 both `b782feea4cb2…`, 20.4796 / 50.9973. **S2 introduces nothing here — it is byte-identical to S at both bpd.** The state is unreachable under the store contract as used (`drop_source`, or no post-merge add to either key), which is why all 155 real assertions are identical. Whether ltl's adopt path should itself become a copy is the architect's call; the feature doc's F40 records that `merge_log_message_entry_into_cluster` deletes the source counter slot immediately after the adopt, leaving a single live owner.
11. **S2 changes the cost model of the fold from "scales with bpd" to "scales with occupied span"** (×4.42 against T's ×10.96 and S's ×12.05). It does not close the gap to G (V2's fold: 0.093 s / 0.117 s at 51,469 keys) but it removes the order-of-magnitude penalty that made S the worst arm on this axis.
12. **The V2 merge-pair numbers were inflated by fill-subtraction noise.** V2 reported T 89.17 / S 121.07 µs/merge at bpd 53 on the 2026-01-14 fan-out file by subtracting a fill baseline; measuring the merge loop alone on the 286,659-key fixture with a fresh untimed store per run gives T 71.80 / S 91.80 — S is 1.28× T, not 1.36×. Note the two figures are on different fixtures as well as different methods, so they are not a like-for-like pair; the fill-subtracted variant is retained in `timing-fanout-full-bpd*.txt` for continuity with V2, and its T row there carries a visibly wider min–max (0.33–0.57 s) than the clean measurement (0.338–0.371). **The fold numbers above remain fill-subtracted.**

**Not covered by the addendum.** No memory measurement of S2 (it stores exactly what S stores, verified element-for-element, but `Devel::Size`/RSS was not re-run, and the transient buffer inside `_remap_span` — sized to the destination span rather than to `new_bin_count` — was not measured, so the peak-RSS benefit is unquantified). Full-fixture `-g` fold **parity** was not run at 286,659 keys: fold parity is proved at 3,418 merges (DPM, both bpd) and 49,842 merges (fan-out 50k lines, both bpd), and the 286,658-merge fold was timed but its digest was not compared across arms; the 5,000-pair digest parity **was** asserted on the full fixture at both bpd. `percentile`, `add` and the extend path are inherited from S untouched and were not re-measured. Only bpd 53 and 616, one fixture family for timing; the DPM log was used for parity at both bpd but not timed, and the Tomcat access log was not used at all. No `ltl` invocation.

---

## V3 — Seeding heuristic, span growth, overflow/underflow audit

Results: `prototype/426-results/revalidate-v3.md`. Captures: `revalidate-v3-driver.txt`, `revalidate-v3-partA-arm{T,S,G}-bpd{53,616}.txt`, `revalidate-v3-partA-all-bpd{53,616}.txt`, `revalidate-v3-partA-perkey-bpd{53,616}.tsv`, `revalidate-v3-partB.txt`, `revalidate-v3-partC.txt`.

### Hypothesis

T reproduces #189 V3 Part A (4,153 partitions, 7 rebin events, p99 0, max 1) and S is digest-identical. Under G a key's storage is its occupied span and on real data that span is below T's seeded 265 (@53) / 3,080 (@616) bins for every key. #189 V3 Part B: T with the cap at 0 fires `high`/`low` where Decision 4 says; T without the cap contains every outlier by doubling; G is `none` everywhere by construction and within one bin of the oracle. G needs no growth cap (bounded by `bpd × decades-of-data + 1`). No arm guards non-positive values.

### Method

Part A: the 277 MB file into each arm; one arm per process for timing (one warmup + 3 timed builds, median with min–max) and memory (Devel::Size of the store, RSS delta around the first build); `--arm all` in one process for the T/S digest assertion and the per-key T-vs-G comparison; bpd 53 and 616. Part B: the three #189 V3 scenarios (warmup 1,000 values `v0·(0.5 + j/1000)`, deterministic instead of #189's `rand()`, then the outliers), each built five ways — T cap 0, S cap 0, T no cap, S no cap, G — with `S canonical == T canonical` asserted in both cap states; R4 at q 0.001/0.5/0.999 with audit and error vs the exact nearest-rank oracle; plus a 12-decade key in three insertion orders and the 1..1e9 worst case. Part C: `grid_index` and every arm's `add` on 0, −1, 1e-320, 1e308, fresh key and after `add(100)`, under a 5 s alarm.

### Result

Part A, per-arm processes:

| bpd | arm | build median (min–max) s | Devel::Size | RSS delta | telemetry |
|---|---|---|---|---|---|
| 53 | T | 5.644 (5.572–5.649) | 9.28 MB | 11.45 MB | partitions 4153, rebin events 7, partitions_with_rebins 7 (0.1686%), max bins 397, rebins p50/p95/p99/max 0/0/0/1, overflow 0, underflow 0 |
| 53 | S | 5.388 (5.312–5.388) | 3.83 MB | 6.45 MB | 12 fields identical to T |
| 53 | G | 5.180 (5.161–5.184) | 2.37 MB | 3.80 MB | partitions 4153, span slots p50/p95/p99/max 1/26/78/175, index range [0, 302] (5.72 decades) |
| 616 | T | 5.761 (5.732–5.792) | 56.72 MB | 65.58 MB | rebin events 7, max bins 4619, rebins 0/0/0/1 |
| 616 | S | 5.389 (5.374–5.393) | 8.38 MB | 11.22 MB | identical to T |
| 616 | G | 5.139 (5.108–5.193) | 6.92 MB | 8.58 MB | span 1/294/907/2028, index range [0, 3517] |

T and S digests identical: `3962d9c26ac17c07388d8a02149c3fb0` (@53), `8bb68875349ae9f8b67aade39c51e907` (@616). Per-key G span vs T (`revalidate-v3-partA-all-bpd*.txt`): G span > T bin_count on **0** keys, > T seed on 0 keys at both bpd; Σ T bin_count 1,101,469 vs Σ G span 29,442 (ratio 0.0267; 0.0517 against T's actual array lengths, 569,388) @53; 12,802,013 vs 304,466 (0.0238 / 0.0462) @616. Six of T's seven rebins are downward to a 1 ms sample (G `lo=0`), one upward (`GetShiftSummaryReportData`, lo 89 hi 241 @53).

Part B (`revalidate-v3-partB.txt`), bpd 53 (616 identical in counters and audit):

| scenario | T cap 0: over/under; audit q0.001 / q0.5 / q0.999 | T no cap: bin_count, rebins; audit; error | G: span (lo..hi), occupied; audit; error |
|---|---|---|---|
| extreme high (v0=100; 1e6, 1e7, 1e8) | 3 / 0; none / none / **high** (q0.999 = 15,811 vs 1e7) | 530, 2; none ×3; +2.40% | 335 (90..424), 29; none ×3; q0.999 = 1e7 exact |
| extreme low (v0=10000; 0.5, 0.1, 0.01) | 0 / 3; **low** / none / none (q0.001 = 15.81 vs 0.1) | 530, 2; none ×3; +2.40% | 328 (−106..221), 29; none ×3; +4.44% |
| mixed (v0=1000; 50 × 1e-3, 50 × 1e8) | 50 / 50; **low** / none / **high** | 794, 2; none ×3; −1.27 / −2.12 / +1.66% | 584 (−159..424), 28; none ×3; +0.17 / −0.10 / +4.35% |

`S canonical == T canonical` in every scenario, both cap states, both bpd (30 PASS). 12-decade key (1,013 samples): G span 636 (@53) / 7,392 (@616) in all three insertion orders with identical percentiles (q0.5 = 100.189); T 662–794 bins (3–4 rebins) and q0.5 = 98.85 / 100.10 / 100.01 by order. G bytes for the same 636-slot span: 12,851 / 6,995 / 21,347 B by order (@616: 143,203 / 73,867 / 243,907). Worst case 1..1e9 fully occupied: G 477 slots (= 9×53+1), 16,235 B vs T 662 bins, 36,380–37,260 B (@53); 5,544 vs 7,700, 178,379–181,331 B vs 405,644–416,028 B (@616) — 0.72× the slots, 0.43–0.45× the bytes. Endpoints only (1 and 1e9) @616: G 45,371 B when 1 comes first, 178,379 B when 1e9 comes first.

Part C (`revalidate-v3-partC.txt`): value 0 → T/S `Illegal division by zero`, G `Can't take log of 0`; −1 → T/S **HANG** (fresh key and after `add(100)`), G dies; 1e-320 → G index −16,961 accepted, T/S accept then `bin_count = Inf` (`Non-finite repeat count` warning in S); 1e308 → G index 16,324 accepted, T/S max = Inf, p50 = NaN.

### Surprises

1. A negative value hangs T and S rather than dying (`while ($value < $new_min) { $new_min /= $factor }` with negative min); the caller guard is what prevents it today.
2. G's memory for a given span depends on insertion order (3× between the 12-decade orders; 4× on the endpoints case): downward growth splices real `0` scalars, upward growth leaves `undef` slots. Same `(0) x $shift` splice in S's `_bump_offset_dense`. Digests and percentiles unaffected.
3. Six of T's seven real-data rebins are downward to 1 ms, not upward outliers.
4. T's `bins` array length is well below `bin_count` on every key (Σ 569,388 vs 1,101,469 @53): the verbatim store never zero-fills to `bin_count`, so G's honest advantage is against the array length (0.0517), not `bin_count` (0.0267).

### Findings and actions

1. **#189 V3 Part A reproduced; S parity-identical to T** (digests, 12 telemetry fields, 30/30 canonical matches). D4 and D5 apply to S verbatim.
2. **Under G, Decision 5 (seed, doubling, rebin telemetry) becomes vacuous, not violated**: no seed, no `partition_extend`, no rebin count; `total_rebin_events`, `max_partition_bins`, `rebins_per_partition` have no G equivalent. The tuning signal D5 asked for (p99 rebins in [0, 2]) is replaced by span telemetry (p50/p95/p99/max 1/26/78/175 @53; 1/294/907/2028 @616; global range 5.7 decades).
3. **Under G, Decision 4 and `out_of_range_bounded` are structurally `none`**: any positive double gets an index (1e-320 and 1e308 accepted); the R4 `low`/`high` branches are unreachable; the four overflow/underflow aggregates are identically 0. #189's "`--max-rebins 0` to test R6" guidance has no G counterpart.
4. **G needs no growth cap**: span ≤ `bpd × log10(max/min) + 1` (+1 more in the wrap case) of the key's own data; 0.72× T's doubled partition and 0.43–0.45× its bytes on the 1..1e9 worst case; 0 of 4,153 real keys exceed T's seed. T has no cap today either.
5. **The `> 0` guard must stay at the caller or move into the store's `add`, under every arm**: G dies on 0 and negatives; T/S die on 0 and loop forever on negatives. ltl call sites are gated `> 0` (`counter_update` at 10775/10889/11029/11143; histogram sites at 11184–11207 likewise — verifier).
6. **Span arrays should grow with `undef`, not `0`, when extending downward** (S and G alike); `bins_pairs`, `percentile` and canonical already treat `undef` as 0. Not changed in the lib for this aspect.
7. **Accuracy at the audited quantiles**: T no cap within 2.40% (@53) / 0.21% (@616); G within one bin (4.44% / 0.37%) and exact at q0.999 of the high-outlier case; T cap 0 returns the partition edge (D4's contracted behaviour, −99.84% / +15,711%). G's percentiles are insertion-order-independent; T's shift with order.

### Verifier

Verdict **confirmed**. Issues (all low): the driver runs the per-arm timed processes before the `--arm all` parity process (parity passed in the same driver run; V3 makes no timing finding, but the sequence inverts protocol item 1); no explicit G digest is captured for the three insertion orders (identical span/occupied/percentiles are printed; the "digests unaffected" clause is inferred); the structured result's F3 evidence string lists the extreme-high audit in the wrong column order (the `.md` table and the table above are right); the `ltl` call-site enumeration omits the eight histogram sites, which are also gated `> 0`; the closed form `bpd × decades + 1` is exact only when `bpd·log10(max/min)` is an integer (general bound is one slot more); `bytes(S columns)` in the worst-case rows re-ran 128 B lower (Devel::Size of the S column set is not byte-stable); the phrase "seeded from a first sample in the hundreds of ms" for the six downward rebins is not traceable to a captured number (the `lo=0` / `rebins=1` facts are).

### Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
caffeinate -s bash prototype/426-revalidate-v3.sh > prototype/426-results/revalidate-v3-driver.txt 2>&1   # ~4 min, all captures
perl prototype/426-revalidate-v3.pl --part A --arm T --bpd 53 --runs 3 \
    --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt   # likewise --arm S|G, --bpd 616
perl prototype/426-revalidate-v3.pl --part A --arm all --bpd 53 --runs 0 \
    --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
    --per-key prototype/426-results/revalidate-v3-partA-perkey.tsv
perl prototype/426-revalidate-v3.pl --part B --bpd 53,616 > prototype/426-results/revalidate-v3-partB.txt
perl prototype/426-revalidate-v3.pl --part C --bpd 53 > prototype/426-results/revalidate-v3-partC.txt
perl prototype/426-revalidate-v3.pl --help
```

---

## V4 — `-V histogram-bin-counters` (Decision 8) output under the proposed representation

Results: `prototype/426-results/revalidate-v4.md`. Captures: `revalidate-v4-ltl-real{,-dmp7,-dmp9,-raw,-memvar}.txt`, `revalidate-v4-all.txt`, `revalidate-v4-diff.txt`, `revalidate-v4-timing-{T,S,G}.txt`, `revalidate-v4-timing.tsv`. Fixture: `logs/AccessLogs/localhost_access_log.2025-03-21.txt` (22,264 lines, 14,062 positive durations, 635 keys).

### Hypothesis

The Decision 8 section as ltl renders it today (`emit_bin_counter_mode_verbose`, ltl:4625–4776, the #293 form) renders field-for-field and value-for-value from S with only `counter_memory_bytes` differing, and from G with five Decision 5 / Decision 4 fields structurally constant. Decision 2 (precision lever) and Decision 7 (opt-out) do not depend on the representation.

### Method

Real ltl captured once per scenario the current lever can express (`-mdm bin` tier 5; `-dmp 7`; `-dmp 9`; `-mdm raw`). The six #189 V4 scenarios mapped onto today's ltl — #293 dissolved `-pbpd` and `--percentile-precision` (0 occurrences of either string, or of `--exact-percentiles`, in `ltl`): (1) default → bpd 53; (2) tier 7 → bpd 115; (3) `-pbpd 100` **unreachable**, substituted by `-dmp 9` → bpd 616; (4) two-flag conflict **unreachable**, not rendered; (5) overflow audit under the prototype's `max_rebins=0` hook (no ltl flag) for T/S, G rendered without a cap; (6) opt-out → `-mdm raw`. Per scenario the T/S digest is printed before any block (exit non-zero on divergence); each arm's section is rendered through one renderer copying the emitter's lines (including `// 0` defaulting); for G a second, labelled **proposed** block. `revalidate-v4-diff.txt` diffs the real section against T and S (`counter_memory_bytes` masked) and the field names / values against G. Timing after parity: one arm per process, scenarios 1 and 3, one warmup + 3 timed runs of telemetry + audit + render; Devel::Size and RSS delta of the store build.

### Result

Parity (`revalidate-v4-all.txt` lines 4, 173, 342, 520; `ALL PARITY PASS` line 782): T = S at bpd 53 (`fefe624f…`), 115 (`6e55c317…`), 616 (`bb067777…`) and under the cap (`ee54df46…`); G `08d50bed…` / `36ce32c7…` / `12d69796…`, and under the cap unchanged from scenario 1 (`08d50bed…`).

Real ltl vs prototype (`revalidate-v4-diff.txt`): with `counter_memory_bytes` masked, T and S sections are byte-identical to real ltl in scenarios 1, 2, 3 and 6 (`IDENTICAL` ×8); G's field names identical in every scenario (`FIELD NAMES IDENTICAL` ×4), values differing exactly on the five inert lines.

| scenario | field | real ltl | T | S | G (locked set) |
|---|---|---|---|---|---|
| 1 (bpd 53) | partition_count | 635 | 635 | 635 | 635 |
| | total_rebin_events / max_partition_bins | 1 / 397 | 1 / 397 | 1 / 397 | 0 / 0 (`// 0`) |
| | partitions_with_overflow/underflow_count | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| | rebins_per_partition | p50=0 p95=0 p99=0 max=1 | same | same | all 0 |
| | out_of_range_bounded | all none | all none | all none | all none |
| | counter_memory_bytes | 1,522,959 | 1,598,689 | 650,952 | 445,386 |
| 2 (bpd 115) | max_partition_bins; counter_memory_bytes | 862; 2,353,215 | 862; 2,451,241 | 862; 793,600 | 0; 587,274 |
| 3 (bpd 616) | max_partition_bins; counter_memory_bytes | 4,619; 9,180,903 | 4,619; 9,336,673 | 4,619; 1,938,664 | 0; 1,728,466 |
| 5 (cap 0, bpd 53) | overflow audit | — (no ltl cap) | 1 partition, overflow_total 6, p1..p75=none p90..p99999=high | identical to T | overflow 0, all none |
| 6 (`-mdm raw`) | summary_table block | `path: user_opt_out` only | identical | identical | identical |

G proposed block (`revalidate-v4-all.txt` lines 139–152, 308–321, 477–490): `grid_bpd`, `grid_index_range` 0..231 / 0..503 / 0..2695, `span_slots` p50/p95/p99/max 1/51/80/191 · 1/110/173/412 · 1/588/923/2202, `counter_slots_total` 6,536 / 13,439 / 69,272 at bpd 53 / 115 / 616.

Timing and memory (`revalidate-v4-timing.tsv`; one arm per process; median of 3, min–max):

| arm | bpd | telemetry + audit + render | Devel::Size (post-audit for S/G — verifier) | RSS delta of store build |
|---|---|---|---|---|
| T | 53 | 0.1805 s (0.1803–0.1846) | 1,521,689 | 1,456 kB |
| S | 53 | 0.0225 s (0.0220–0.0226) | 708,808 | 512 kB |
| G | 53 | 0.0190 s (0.0186–0.0190) | 503,490 | 208 kB |
| T | 616 | 1.9239 s (1.9119–1.9288) | 9,235,513 | 9,264 kB |
| S | 616 | 0.0826 s (0.0817–0.0835) | 2,756,960 | 1,168 kB |
| G | 616 | 0.0694 s (0.0690–0.0697) | 2,554,858 | 1,168 kB |

The audit walk (12 quantiles × 635 keys) dominates; T's `percentile` sums the dense bins array per call, S/G walk only the span (the #426 F19 shape).

### Surprises

1. `counter_memory_bytes` is not reproducible across processes even in real ltl (three identical runs: 1,522,959 / 1,482,319 / 1,482,319; `revalidate-v4-ltl-real-memvar.txt`), nor in the prototype's T store (1,598,689 vs 1,521,689): Devel::Size of a hash follows the seed-randomised bucket array. G's value was identical across three processes and S moved by 32 B (verifier) — the row hash is still a hash.
2. Two of the six #189 V4 scenarios are unreachable in today's ltl (the `-pbpd` forms); Decision 8's `; overridden` annotation, `n/a (-pbpd N)` rendering and `buckets_per_decade:` line no longer exist.
3. The opt-out path never touches a store: under `-mdm raw` `finalize_message_stats_unified` returns on an empty `%log_messages_counters`; all three arms print the identical block. Today's emitter has no `opt_out_active` / `opt_out_notice` header lines and no `--exact-percentiles` flag — pre-existing drift between the Decision 7/8 text and the shipped emitter, not caused by #426.

### Findings and actions

1. **Every Decision 8 field survives unchanged under S**: byte-identical to real ltl (memory masked) at bpd 53/115/616 and under `-mdm raw`; identical audit lines under the cap. `counter_memory_bytes` is 2.4–4.8× smaller — a value change the Decision 8 stability contract permits.
2. **Five Decision 8 fields are inert under G** (`total_rebin_events`, `max_partition_bins`, `partitions_with_overflow_count`, `partitions_with_underflow_count`, `rebins_per_partition`) plus the Decision 4 audit line is a constant `none`. Names still parse; the lines carry no information. A field-name amendment entry is required by Decision 8's own rule if P10 is locked.
3. **Minimal amendment rendered, not locked**: keep `path`, `partition_keying`, `partition_count`, `counter_memory_bytes`, `percentiles_emitted`; replace the five inert lines with `grid_bpd`, `grid_index_range`, `span_slots: p50= p95= p99= max=`, `counter_slots_total`; keep `out_of_range_bounded` as a constant or drop it.
4. **Decision 2 is representation-independent**: bpd resolves before any store exists (`bpd_for_surface`, ltl:1268); T/S digests identical at every tier; G's digest changes with bpd; the `data_model_precision:` line has no store input (ltl:4637). Real `-dmp 7` / `-dmp 9` sections match the prototype byte-for-byte (memory masked).
5. **Decision 7 is representation-independent**: `-mdm raw` builds no store; the block is identical from every arm and from real ltl.
6. **`counter_memory_bytes` should not be a regression assertion in any arm**; `counter_slots_total` (G) or a span-length sum (S) is the deterministic alternative.

### Verifier

Verdict **confirmed**. Issues (all low): the timing table's Devel::Size for S and G is a post-audit value (~9–13% above the store-build footprint: one `percentile` walk over every key grows the S/G containers by ~58 KB, T unaffected; RSS deltas unaffected) — labelled above; F6's "not reproducible in any arm" over-reaches for G (identical across three processes); no explicit G self-consistency check in this aspect (G's digest is printed per scenario and scenario 5 == scenario 1; order-independence is V1's); the G timing closure renders `slots_total=0` and single-arm timing runs print `ALL PARITY PASS` without a parity check in that process (parity was established in the all-arm run first).

### Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
bash prototype/426-revalidate-v4.sh   # real ltl captures (4), all-arm all-scenario run, diff vs real, per-arm timing runs
perl prototype/426-revalidate-v4.pl --file logs/AccessLogs/localhost_access_log.2025-03-21.txt > prototype/426-results/revalidate-v4-all.txt
perl prototype/426-revalidate-v4.pl --file logs/AccessLogs/localhost_access_log.2025-03-21.txt --arm T --scenario 1,3 --timing 3   # repeat for S, G
bash prototype/426-revalidate-v4-memvar.sh > prototype/426-results/revalidate-v4-ltl-real-memvar.txt
perl prototype/426-revalidate-v4.pl --help
```

### V4 addendum — the `-V` audit aggregation scope and the Decision 8 field census

Captures: `prototype/426-results/n7-audit-census/` (22 files). Instruments: `prototype/426-n7-audit-census.pl` (reproduces ltl's two distinct aggregation scopes separately), `prototype/426-n7-audit-cap.pl` (drives the same aggregation on a store that actually carries overflow/underflow, via the lib's `max_rebins` hook), `prototype/426-n7-field-census.pl` (probes each arm's **live store** for a populable source per D8 field rather than asserting from the doc). Fixtures: a 10k-line DPM slice, `bin-dpm-full.log` (3,418 ltl keys), `bin-twxdur-full.log` (286,621 ltl keys).

V4's open item was that the prototype aggregates `out_of_range_bounded` over every key while ltl aggregates only the keys its statistics pass walks. This addendum reproduces both scopes and settles it.

**Parity, before any other claim.** T and S produce byte-identical store digests on every fixture and every cap setting — `6dc4b8fab6637786c70793de6567ac4d` (dpm-10k, uncapped), `bd0bf5677f6f65a9d55c56141a87eff7` (dpm-10k, cap 0). The cap sweep (`cap-sweep.out`, caps 0/1/2) reports `T vs S store digest: IDENTICAL` and `T vs S out_of_range_bounded: IDENTICAL` at every point; three repeat runs of arm T give the identical digest and telemetry (`repeat3-T.out`). G differs by construction (`57fb79a3c5e8056bb095cfefef4f3d6c`).

**Reproduced against real ltl**, oracle invocation shaped to the assertion (coarse buckets — bucket count is not read; no heatmap/histogram/CSV; smallest fixture carrying the signal):

```
./ltl --disable-progress -ni -mdm bin -bs 1440 -V histogram-bin-counters <file>
```

| field | ltl (dpm-10k) | T | S | ltl (dpm-full) | T | S | ltl (twxdur-full) | T | S |
|---|---|---|---|---|---|---|---|---|---|
| `partition_count` | 2514 | **2514** | **2514** | 3418 | 3419 | 3419 | 286621 | 286659 | 286659 |
| `total_rebin_events` | 15 | **15** | **15** | 116 | **116** | **116** | 2 | **2** | **2** |
| `max_partition_bins` | 397 | **397** | **397** | 397 | **397** | **397** | 397 | **397** | **397** |
| `partitions_with_overflow_count` | 0 | **0** | **0** | 0 | **0** | **0** | 0 | **0** | **0** |
| `partitions_with_underflow_count` | 0 | **0** | **0** | 0 | **0** | **0** | 0 | **0** | **0** |
| `rebins_per_partition` | p50=0 p95=0 p99=0 max=1 | **same** | **same** | p50=0 p95=0 p99=1 max=1 | **same** | **same** | p50=0 p95=0 p99=0 max=1 | **same** | **same** |
| `out_of_range_bounded` | all `none` | **all `none`** | **all `none`** | all `none` | **all `none`** | **all `none`** | all `none` | **all `none`** | **all `none`** |
| `counter_memory_bytes` | 6149748 | 6358381 | 3164956 | 9506828 | 9782874 | 5692544 | 660040094 | 676177146 | 213259371 |

On the smallest fixture every Decision 8 field except `counter_memory_bytes` is exactly identical, `partition_count` included. On the two larger fixtures every field except `partition_count` and `counter_memory_bytes` is exactly identical. Both residuals are explained and neither is an aggregation difference: `counter_memory_bytes` is not reproducible **within ltl itself** (three identical invocations gave 5,988,852 / 6,149,748 / 5,988,852 — a 2.7% spread on byte-identical input, `ltl-repeat-3.out`; calling the verbatim `counter_update` + `snapshot_counter_telemetry` primitives directly on the same fixture gives 6,258,181, in the same band); the `partition_count` drift (3419 vs 3418; 286,659 vs 286,621, 0.013%) is a keying difference in the **prototype lib's** `parse_twx_line`, proved against ltl's own MESSAGES CSV (`keyset-diff.out`, parsed with `python3 csv`) — the message-key sets are 1:1 with zero lib-only and zero ltl-only messages, and the extra ltl CSV rows are keys whose every duration is 0, correctly absent from both stores.

**The aggregation scope, demonstrated.** Same store, same verbatim primitives, only the walked key set differs (`audit-cap0-dpm10k.out` vs `audit-cap0-dpm10k-allkeys.out`):

| scope | keys walked | `out_of_range_bounded` |
|---|---|---|
| display slots (top 10 × 2 categories) | 20 | `p1=none … p99999=none` (all twelve `none`) |
| every key in the store | 2514 | `p1=low p5=low p10=low p25=low p50=low p75=high p90=high p95=high p99=high p999=high p9999=high p99999=high` |

Both rows carry `partitions_with_overflow_count: 8`, `partitions_with_underflow_count: 7`, `overflow_total: 8`, `underflow_total: 10` — identical stores. The 15 out-of-range partitions are all low-occurrence keys that never win a display slot. A replacement validated by walking the store would report twelve non-`none` codes where ltl reports twelve `none`, and the diff would be a scope artefact, not a defect. T and S agree at both scopes.

**Field census** (D8's locked `path: unified` field set, read from `features/187-histogram-bin-counter-percentiles.md` § Decision 8 and probed per arm on a live store, `field-census-dpm10k.out`). G's inertness is confirmed structurally, not by assertion: `Revalidate426::Store::G` holds only `{row, key, bins}` — no partition record, no `rebins`, no `overflow`/`underflow` — and its `percentile` ends in `die "unreachable"`, so no out-of-range exit exists.

| D8 field | T | S | G | honest replacement under G |
|---|---|---|---|---|
| `partition_keying` | yes | yes | yes | — consumer-level constant, never read from the store |
| `partition_count` | yes | yes | yes | — same meaning (distinct keys) |
| `total_rebin_events` | yes | yes | **no** | none needed — the grid never rebins; `grid_bpd` (a run constant) is the geometry disclosure this replaced |
| `max_partition_bins` | yes | yes | **no** | `span_max` (widest per-key occupied span, in grid slots) |
| `partitions_with_overflow_count` | yes | yes | **no** | structurally zero — the span grows on either side on demand |
| `partitions_with_underflow_count` | yes | yes | **no** | structurally zero — same reason |
| `counter_memory_bytes` | populable | populable | populable | **not assertable on any arm** |
| `rebins_per_partition` | yes | yes | **no** | `span_p50 / span_p95 / span_p99 / span_max` — the same shape (a per-key distribution), reporting slot occupancy instead of resize events |
| `percentiles_emitted` | yes | yes | yes | — static table |
| `out_of_range_bounded` | populable | populable | **no** | constant `none` by construction; drop the line or document it as invariant |

Measured G replacement telemetry (dpm-10k / twxdur-full): `span_p50` 4 / 1, `span_p95` 103 / 1, `span_p99` 129 / 1, `span_max` 149 / 153, `index_min` 0 / 0, `index_max` 279 / 237.

**Findings (addendum).**

7. **The audit aggregation is reproduced exactly, and the scope is the finding.** ltl aggregates the Decision 8 partition-shape fields over the whole counter store (`snapshot_counter_telemetry` walks `values %$store`) and `out_of_range_bounded` over only the display-slot keys. Reproducing one scope with the other produces twelve non-`none` codes against ltl's twelve `none` on an identical store.
8. **`out_of_range_bounded` is unreachable in shipped ltl on every arm, T included.** `counter_update`'s own header states the over/underflow counters are "only reachable when a future growth cap is added — none today": the extend-then-reassign path always succeeds, so `percentile` never takes its `low`/`high` exits from a streaming store. Every ltl run captured — default sort, `-so p99`, and `-o` (which activates `csv_output`) — emits twelve `none`. The only reachable non-`none` source is `merge_bin_counter_entries` propagating already-set counters under `-g`. **The aggregation rule this item was written to protect is dead code in production**, and forcing it required the lib's `max_rebins` hook.
9. **`percentiles_emitted` is a static table, independent of the ladder actually derived.** `emit_bin_counter_mode_verbose` reads a hardcoded per-consumer list; `calculate_statistics_bin` derives a demand-narrowed ladder (terminal_core alone when `csv_body` and `extended` are both off). ltl printed the full twelve in every run, including runs where only four quantiles were computed. A replacement must reproduce the **static** list, not the derived one.
10. **Six fields go inert under G, not five.** V4 finding 2 names five and handles `out_of_range_bounded` in prose; a validation harness needs it as an entry, not a footnote — it is the sixth field a G-arm diff will flag, for the same structural reason. Adding `counter_memory_bytes`, inert as an *assertion* on all three arms, brings the un-diffable total under G to seven of ten.
11. **Four of the ten fields have no discriminating power as parity assertions under T or S either**, because they are constant under uncapped ltl: `partitions_with_overflow_count`, `partitions_with_underflow_count`, `out_of_range_bounded` (finding 8) and `counter_memory_bytes` (finding in V4 Surprise 1). **The fields that actually discriminate are `partition_count`, `total_rebin_events`, `max_partition_bins` and `rebins_per_partition`** — all four exact for T and S here.

**Not covered by the addendum.** Only the `summary_table` consumer: `csv_output` was observed sharing its telemetry by reference, but `time_bucket_stats`, `heatmap_markers`, `heatmap_cells`, `histogram_view` and `histogram_bins` were `feature_not_active` or `user_opt_out` in every run, so the `%bucket_stats_audit` and `metric_global`/`time_bucket` keyings are not reproduced. Only the default sort path: the calculated-statistic sort branch (`-so p99`) runs a second `calculate_statistics_bin` per key over the entire population (the population walk), so its audit scope is the whole store rather than the top N — read from the code, not proved by a differing observation, because finding 8 makes the field unreachable either way. Only the ThingWorx format (both fixtures are ScriptLog). `out_of_range_bounded`'s `low`/`high` agreement between T and S is validated against each other, never against ltl — there is no ltl oracle for that state. No merge coverage (`-g` never exercised). No timing. The `partition_count` residual is explained but its exact line-level cause was traced only for the single dpm-full key, not for the 38 on twxdur-full.

---

## V5 — Accuracy vs the `calculate_statistics` oracle, per key and after merge

Results: `prototype/426-results/revalidate-v5.md`. Captures: `revalidate-v5-bpd{53,115,256,616}.txt`, `revalidate-v5-{key,small,pair,fold}-bpdNN.tsv`, `revalidate-v5-summary.tsv`, `revalidate-v5-tables.txt`, `revalidate-v5-probe.txt`.

### Hypothesis

Per #187 R4 and Decision 1, every required percentile must sit within `10^(1/bpd) − 1` of the exact nearest-rank value (`$sorted[int(N·q)]`, ltl:12716). #189 V5 showed this for T per key at four tiers; #426 V8 claimed on the DPM log at bpd 53 that G holds the bound per key and, unlike T, after merges. Does each claim hold on the #189 primary surface at every tier, per key, on small-N keys, after one merge and after seven sequential merges (the `-g` fold shape)?

### Method

The 277 MB file; bpd ∈ {53, 115, 256, 616}; quantiles P1 P50 P75 P90 P95 P99 P999; dual reporting as #189 V5 (`binning_*` = the walk forced to the oracle's rank, `raw_*` = native `ceil(q·N)`); pass criterion `binning_max ≤ 10^(1/bpd) − 1`. Scopes: **[key]** 328 keys N ≥ 100; **[small]** 2,517 keys N ≥ 2; **[pair]** 1,258 disjoint pairs of consecutive keys merged (T: `merge_bin_counter_entries` verbatim; G: index-wise add) vs the oracle over the union; **[fold]** 314 groups of 8 folded sequentially (7 merges), error after every step. T↔S whole-store digest at bpd 53 before any table (exit 2 on divergence); S is not tabulated separately.

### Result

Parity: `PASS parity bpd=53: T digest=3962d9c26ac17c07388d8a02149c3fb0 S digest=3962d9c2… keys T=4153 S=4153`; T telemetry = #189 V5 (`partition_count=4153 total_rebin_events=7 max_partition_bins=397`). Store memory (Devel::Size): T 9.99 / S 3.61 / G 2.08 MB @53; T 59.7 / G 6.85 MB @616.

[key] N ≥ 100 (`revalidate-v5-tables.txt` § A):

| bpd | bound | arm | binning_max (over 7 q) | binning_p50 | raw_max | raw − binning gap | pass |
|---|---|---|---|---|---|---|---|
| 53 | 4.44% | T | 3.44–4.44% | 0.05–2.20% | 3.44–4.44% | none | PASS |
| 53 | 4.44% | G | 4.16–4.44% | 0.06–4.22% | 4.16–4.44% | none | PASS |
| 115 | 2.02% | T | 1.56–2.01% | 0.02–1.20% | 1.56–2.01% | none | PASS |
| 115 | 2.02% | G | 1.81–2.02% | 0.03–1.92% | 1.81–2.02% | none | PASS |
| 256 | 0.90% | T | 0.83–**0.93%** | 0.01–0.86% | 0.83–1.76% | +0.85% | **FAIL** (1 row) |
| 256 | 0.90% | G | 0.83–0.90% | 0.01–0.86% | 0.83–1.90% | +1.00% | PASS |
| 616 | 0.37% | T | 0.33–0.37% | 0.01–0.37% | 0.37–1.87% | +1.54% | PASS |
| 616 | 0.37% | G | 0.36–0.37% | 0.01–0.36% | 0.36–1.95% | +1.57% | PASS |

T's ranges are #189 V5's to the digit, including the 0.93% at bpd 256 that #189 tabulated and marked pass against a 0.90% bound. The row (`revalidate-v5-key-bpd256.tsv`, ordinal 75, P75, oracle 1 ms, T +0.9336%, G +0.7930%) is `[200] GET /Thingworx/Runtime/index.html`, N=413, 353 samples of exactly 1 ms; probe 2 shows the partition widened once (576 ms at position 174), `bin_count` became 1,919, and the remap moved the 143 pre-widening counts of value 1 into bin 640 `[1.00300, 1.01207)` — a bin that does not contain the value. G's 353 counts sit in one bin `[1, 1.00904)`.

Per quantile (§ B, § F): at bpd 53 G's `binning_p50` is 3.3–4.2% at P75–P99 vs T's 1.1–2.2%; mean signed bias G +2.1…+2.7% vs T +0.9…+1.6%. 159 of 328 keys have P99 exactly 1/10/100 ms; a power of ten is the *lower* boundary of a G bin, so a spike of identical values fills a bin from the bottom and the walk returns up to `upper` for late ranks (median = full bin width on those keys; 0.7–1.1% on the others). T shows the same when `int(5·bpd)` is even (bpd 256: identical T/G medians) and looks better at 616 only because float rounding lands the first sample at the top of bin 1539 (`upper = 0.99999999999999911`, spike error −0.0037%). Rank convention: `raw_max` exceeds `binning_max` from bpd 256 (T +0.43/+0.85/+0.59 pts at P90/P95/P99; G +0.58/+1.00/+0.61) and at 616 (T 1.87/1.72/1.30% — #189's numbers; G 1.95/1.80/1.46%) — the crossover sits at bpd ≈ 256 for both arms.

[small] 2,517 keys (§ C): binning within one bin **100.00%** for G at every bpd and quantile; T likewise except bpd 256 P50 (99.96%, max 1.31%) and P75 (99.96%, max 0.93%) — same widening mechanism, one key each. Raw within-one-bin at P50 89.7% (T) / 90.4% (G) @53, 85.5% / 85.5% @616 — the rank convention on 2–4-sample keys, as #426 V8 found.

[pair] 1,258 merged pairs (§ D; T needed a union remap on 920 = 73.1%):

| bpd | bound | T binning_max (worst q) / in bins | T within one bin (P95 / P99 / P999) | G binning_max / in bins | G within |
|---|---|---|---|---|---|
| 53 | 4.44% | 6.03% (P999) / 1.35 | 96.58 / 96.42 / 96.42% | 4.44% / 1.00 | 100% at every q |
| 115 | 2.02% | 2.86% (P50) / 1.41 | 99.05 / 98.09 / 97.77% | 2.02% / 1.00 | 100% |
| 256 | 0.90% | 1.34% (P1/P50/P75) / 1.48 | 93.16 / 97.62 / 99.52% | 0.90% / 1.00 | 100% |
| 616 | 0.37% | 0.55% (P99) / 1.46 | 99.44 / 99.60 / 99.52% | 0.37% / 1.00 | 100% |

[fold] 314 groups of 8, 7 merges (§ E; T remapped on 1,934 of 2,198 = 88.0%):

| bpd | T within one bin after 7 merges (P50 / P90 / P95 / P99 / P999) | T step-7 max (worst q) / in bins | G within (all q, all steps) | G step-7 max |
|---|---|---|---|---|
| 53 | 99.4 / 97.5 / 94.9 / 93.0 / 90.8% | 7.27% (P99) / 1.64 | 100.0% | 4.44% |
| 115 | 99.4 / 97.1 / 98.1 / 93.9 / 93.9% | 2.75% (P95) / 1.36 | 100.0% | 2.02% |
| 256 | 85.4 / 78.0 / 80.3 / 92.4 / 97.1% | 1.87% (P75) / 2.06 | 100.0% | 0.90% |
| 616 | 93.0 / 95.9 / 97.5 / 98.4 / 97.5% | 0.66% (P75) / 1.75 | 100.0% | 0.37% |

T's within-one-bin share decays with merge depth (bpd 53 P999: 95.9 → 90.8% over steps 1..7; bpd 256 P90: 90.1 → 78.0%); G stays 100.0% at every step and its maximum equals the bound to four decimals.

### Surprises

- #189 V5's pass at bpd 256 covered a real exceedance: one key whose widening remap put counts of a value into a bin that does not contain it. Per-key widenings are rare (7 in 4,153), so the effect is one row; after merges the same projection runs on 73–88% of operations and the bound fails on 0.4–22% of them.
- G's larger median error at the tails on this file is a property of integer-millisecond data (spike values at powers of ten sit on G's lower bin edge), not of the grid; neither arm violates the bound.
- The rank-convention crossover reproduces for G at the same tier (bpd ≈ 256): a property of `ceil` vs `int` on tied tails.
- `grid_index(1000)` is 158 @53 (checked 159): the value is counted at the top of the bin below (spike error −0.0434%); within the bound; V1's item.

### Findings and actions

1. **G holds the one-bin structural bound on the #189 primary surface at every tier in every scope** — per key (328 × 7 q × 4 bpd), small-N (2,517 × 7 × 4), after one merge (1,258 pairs), after seven merges (314 × 7 steps); within-one-bin 100.00% throughout. The #426 V8 claim holds on the Tomcat surface at 53, 115, 256 and 616.
2. **T holds the bound per key at 53, 115 and 616 and fails it on one key at 256** (0.9336% vs 0.9035%); it fails it after merges at every tier (worst 1.35–1.48 bins after one merge, 1.36–2.06 after seven; within-one-bin down to 78.0% at bpd 256 P90). Mechanism in both cases: the geometric-midpoint remap (`partition_extend`; `partition_rebin` via `merge_bin_counter_entries`). S inherits this exactly.
3. **Decision 1 is unchanged by the representation**: G runs it verbatim over grid boundaries with the same error envelope where no remap is involved and the same crossover.
4. **#187 R4's "structural" accuracy contract is not met by today's primitives once a partition has been remapped** (widening or merge); under G it is literally structural — no count ever moves. Evidence for the architect's D5 decision, not a decision.
5. **#189 V5 finding 1 needs a correction**: "within the bound across all 4,153 partitions × 7 quantiles × 4 precision levels" held for 327 of 328 N ≥ 100 keys at bpd 256; its own table showed 0.93% > 0.90%.
6. Interpretation guidance for whichever ticket documents R4: on integer-millisecond data the error inside the bound concentrates at the bin edge for power-of-ten spike values (G always; T when `int(5·bpd)` is even); mean signed bias is positive in both arms (G +2.65%, T +1.55% at P95, bpd 53 — § B).

### Verifier

Verdict **confirmed**. Issues (all low): S parity is captured only as the bpd 53 whole-store digest; the verifier closed the gap (full-file T↔S PASS at bpd 256 `845a56fc…` and 616 `8bb68875…`; on the 2.6 MB file all 166 pair merges and 41 × 7 fold steps canonical-identical with 0 percentile differences under both rank conventions — `scratchpad/v5/smerge.pl`, not under `prototype/426-results/`). Prose slips in the `.md`, not carried above: the [pair] sentence on T vs G medians holds only at P99 and bpd 115; "[small] raw outliers identical to within 0.1 pt" is 0.4–0.8 pt at P50; fold step-7 "in bins" 1.62 → 1.64 (@53) and 1.76 → 1.75 (@616); bias "+2.5 / +1.5" → +2.65 / +1.55; the bpd 115 raw/binning equality is "raw never above binning", not exact equality. `errstats` median is nearest-rank (upper-middle for even n), the oracle's convention.

### Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
sh prototype/426-revalidate-v5-run.sh   # four tiers; exit 1 expected (bpd 256 T key-scope FAIL)
perl prototype/426-revalidate-v5.pl --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
    --bpd 256 --arm T,G --parity-bpd 53 --min-N 100 --fold-size 8 --tsv-prefix prototype/426-results/revalidate-v5
perl prototype/426-revalidate-v5-tables.pl prototype/426-results/revalidate-v5 > prototype/426-results/revalidate-v5-tables.txt
perl prototype/426-revalidate-v5-probe.pl --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
    --bpd 256 --ordinal 75 --q 0.75 > prototype/426-results/revalidate-v5-probe.txt
perl prototype/426-revalidate-v5.pl --help
```

---

## V6 — Display-geometry-bound consumers (heatmap, histogram; the F2/F3 finalize contract)

Results and captures: `prototype/426-results/v6-{dpm,tomcat}-{53,80,115,256,616}/{run.txt,revalidate-v6.tsv}` (10 directories), consolidated in `prototype/426-results/v6-all.tsv` (90 rows). Instruments: `prototype/426-revalidate-v6.pl` (+ driver `.sh`), follow-up probe `prototype/426-v6-boundary-straddle-probe.pl` (capture: `prototype/426-results/v6-probe/boundary-straddle.txt`).

### Hypothesis

V1–V5 cover the per-key percentile surface. They do not cover the two surfaces whose counters finalize into **display geometry**: #187 Decision 5's F2/F3 stream→finalize contract, executed in ltl by `finalize_heatmap_unified()` and `finalize_histogram_unified()` through #189 R12's `partition_rebin()`. If S is a pure re-containering of T's arithmetic, its finalized display cells must be identical to T's in every cell, at every resolution, on both geometries — the same way V1–V5 showed digest identity on the percentile surface. G, having no per-key seed and no out-of-range state, should place mass by value where T and S fold streamed over/underflow into the edge cells.

### Method

Both canonical files at the five streaming resolutions the display surfaces can resolve to under #293's tier table (heatmap and histogram resolve to `[53, 80, 115, 256, 616, 616, 616, 616, 616]`, so the distinct rungs are 53, 80, 115, 256 and 616; the default tier resolves both to 616). Both display geometries use ltl's own target shapes: heatmap `bin_count = $heatmap_width` (52) over the observed `[min, max]`; histogram `bin_count = calculate_histogram_bucket_count(min,max) = int(decades·8 + 0.5)`, minimum 5 — 42 cells on DPM, 36 on Tomcat. **Part A** is the parity gate: T vs S finalized display bins must be identical, every cell. **Part B** measures each arm's finalized display against the **exact** display (every observation placed in the cell holding its value), using #201's own measures: mass retention, peak retention, peak X-offset in cells, empty-cell count, per-cell total absolute deviation. **Part C** separates the overflow/underflow fold (T/S fold streamed out-of-range mass into the edge cells; G has no out-of-range state). **Part D** repeats the whole thing on the heatmap's real per-time-bucket keying — 25 buckets × 5,000 lines (DPM) / 24 buckets × 24,000 lines (Tomcat) into one shared 52-cell display — which is #201 Dimension B.

### Result

**Part A — the parity gate passed on every row.** Across all 90 rows of `v6-all.tsv` (two files × three geometries `heatmap`/`histogram`/`heatmap-keyed` × five resolutions × three arms), **T and S never differ in a single cell**; the per-run logs read `PART A  T vs S finalized display bins: IDENTICAL (all 52 cells)` / `(all 42 cells)` / `(all 36 cells)` and `PART D  T vs S per-bucket finalized cells: IDENTICAL across every bucket`. Mass retention is `1.000000` and peak X-offset is `0` for **every arm on every row**, G included.

Fidelity against the exact display, per-cell total absolute deviation as a percentage of mass (`v6-all.tsv`, columns `abs_dev_pct` and `max_cell_dev`):

| file | bpd | heatmap T/S | heatmap G | histogram T/S | histogram G |
|---|---|---|---|---|---|
| DPM | 53 | 1.3779% (max cell 332) | 1.6352% (250) | 0.9414% (158) | 2.9398% (703) |
| DPM | 80 | 33.1406% (19,926) | 33.2432% (19,926) | 1.8127% (484) | 1.4365% (480) |
| DPM | 115 | 0.3958% (57) | 1.0358% (174) | 0.7720% (208) | 1.3909% (480) |
| DPM | 256 | 0.2883% (94) | 0.3257% (132) | 0.1889% (34) | 0.1922% (97) |
| DPM | 616 | 0.2948% (143) | 0.2915% (132) | 0.0700% (16) | 0.0961% (34) |
| Tomcat | 53 | 5.2008% (5,875) | 3.1278% (5,180) | 9.7701% (25,155) | 9.9785% (25,155) |
| Tomcat | 80 | 3.5443% (4,553) | 1.9788% (1,838) | 7.6131% (20,837) | 1.1080% (2,045) |
| Tomcat | 115 | 1.5033% (2,229) | 0.0618% (176) | 8.6770% (24,382) | 0.4988% (925) |
| Tomcat | 256 | 0.7676% (1,583) | 0.3856% (674) | 0.0302% (83) | 0.0115% (33) |
| Tomcat | 616 | 0.0337% (89) | 0.0806% (211) | 0.0740% (126) | **0.0003%** (1) |

Neither arm dominates: on DPM T/S is ahead on the heatmap at bpd 53/115/256 and G ahead at 616 and on the histogram at 80; on Tomcat G is ahead on 7 of 10 cells and by more than an order of magnitude on the histogram at 115 (0.4988% vs 8.6770%) and at 616 (0.0003% vs 0.0740%).

**Part D — the per-time-bucket keying**, where #201's Dimension B lives. On both files T and S seed each bucket's partition around that bucket's own first value, producing **13 distinct range anchors across 24 (Tomcat) / 25 (DPM) buckets**; G is globally anchored by construction. Per-bucket deviation from that bucket's own exact display, as a percentage of its mass:

| file | bpd | arm | median | p95 | max | mean |
|---|---|---|---|---|---|---|
| Tomcat | 616 | T = S | 0.2667% | 0.4333% | 0.4583% | 0.2234% |
| Tomcat | 616 | **G** | **0.0667%** | **0.1750%** | **0.2333%** | **0.0806%** |
| Tomcat | 53 | T = S | 3.4417% | 6.2417% | 7.2250% | 3.9612% |
| Tomcat | 53 | G | 3.5750% | 5.2333% | 5.2750% | 3.1315% |
| DPM | 616 | T = S | 0.2800% | 0.6000% | 0.6800% | 0.3049% |
| DPM | 616 | G | 0.2800% | 0.6000% | 0.6800% | 0.2905% |
| DPM | 80 | T = S | 1.4000% | 36.1200% | 38.4560% | 8.9990% |
| DPM | 80 | G | 33.3200% | 39.6000% | 61.0800% | 33.5421% |

At the resolution the display surfaces actually run at (616) on the Tomcat file the global anchor is 4× better on the median and ~2× on the max; on DPM at 616 the three arms are statistically identical.

**Part D also records two mass-retention misses on T/S alone**, both at coarse resolutions on DPM: peak retention 0.999928 at bpd 53 (27,894 against the exact 27,896) and 0.999068 at bpd 80 (27,870 against 27,896). G is 1.000000 on both.

**The large coarse-resolution deviations are a boundary straddle, not a representation defect.** The 33% figures at DPM bpd 80 are one bin's whole mass landing one cell over. `426-v6-boundary-straddle-probe.pl` (capture `v6-probe/boundary-straddle.txt`):

```
bpd=80  cell  2: exact=  19926  T=      0  diff= -19926   cell range [1.594, 2.013)
        cell  3: exact=      0  T=  19926  diff= +19926   cell range [2.013, 2.542)
        total abs dev 40696 of 122798 (33.1406%)
        G: total abs dev 40822 (33.2432%);  cell2 exact=19926 G=0  cell3 exact=0 G=19926
bpd=616 total abs dev 362 of 122798 (0.2948%)
        G: total abs dev 358 (0.2915%);  cell2 exact=19926 G=19926  cell3 exact=0 G=0
```

The DPM durations are small integers (most common: 3 ×24,220, 7 ×23,388, **2 ×19,926**, 4 ×10,572, 6 ×9,415), and at bpd 80 the source bin holding the value `2` — 19,926 observations, 16.2% of the file — has its geometric midpoint just across the display-cell boundary at 2.013, so that bin's whole mass moves one cell. **T and G do this identically** (both cell 3 at bpd 80, both cell 2 at 616). It is a property of the two-stage projection at coarse streaming resolution, and an independent rediscovery of why #201 locked the display surfaces' streaming bpd at 616.

### Surprises

- The deviation curve is **non-monotonic in resolution**: DPM heatmap runs 1.38% (53) → 33.14% (80) → 0.40% (115) → 0.29% (256) → 0.29% (616). The 80 rung is the straddle, not a resolution effect.
- On Tomcat's histogram at bpd 616 G's deviation is 0.0003% (one cell, one observation) against T/S's 0.0740% (126) — the largest single-cell margin either way in the table.
- Part D's two peak-retention misses belong to T/S only, and both are at coarse rungs; at 616 every arm retains the peak exactly.

### Findings and actions

1. **S is display-cell-identical to T on both display geometries, at every resolution and every time bucket** — 90 rows, three geometries, five rungs, two files, zero differing cells; mass retention 1.000000 and peak X-offset 0 for every arm. **P8+P9 inherit #201's validation on the display surfaces the same way they inherit #189's on the percentile surface.**
2. **On the heatmap's real per-time-bucket keying the global anchor is measurably better at the shipping resolution.** 13 distinct T/S range anchors across 24–25 buckets — #201 Dimension B, the mismatch behind its four rejected Phase 3 strategies. Tomcat at 616: G median 0.0667% / max 0.2333% against T 0.2667% / 0.4583%. On DPM at 616 the arms are statistically identical (median 0.2800% each).
3. **Neither arm dominates the aggregate display fidelity**; the ranking flips by file, geometry and rung (table above). No claim of general G superiority on the display surfaces is supported by this evidence.
4. **The coarse-resolution outliers are a boundary straddle both arms share**, not a defect of either representation; it is the mechanism #201's 616 lock already addresses.
5. **#189 R12's `partition_rebin` as the finalize step is exercised and carries S unchanged** — Part A is a direct test of the finalize projection, and it is identical cell-for-cell in all 90 rows.

### Not covered by V6

The heatmap/histogram *settings, geometry and rendering* are out of question by the architect's 2026-08-25 framing; V6 measures only what the store hands the finalize step. Time buckets in Part D are contiguous runs of fixed line count, not `-b`-derived wall-clock buckets, so bucket-N *skew* is untested. No `ltl` invocation: every number is the library's verbatim primitive ports finalizing through the reproduced contract.

### Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
prototype/426-revalidate-v6.sh                     # 10 runs (2 files x 5 rungs), builds v6-all.tsv
perl prototype/426-revalidate-v6.pl --file logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log \
    --bpd 616 --bucket-lines 5000 --out prototype/426-results/v6-dpm-616
perl prototype/426-revalidate-v6.pl --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt \
    --bpd 616 --bucket-lines 24000 --out prototype/426-results/v6-tomcat-616
for b in 80 616; do perl prototype/426-v6-boundary-straddle-probe.pl $b; done \
    > prototype/426-results/v6-probe/boundary-straddle.txt 2>&1
```

---

## V7 — The bucket-stats surface (the fourth `%TIER_BPD` surface)

Results and captures: `prototype/426-results/v7/` (41 files; `{dpm,tomcat}-bpd{16,32,53,115,616}-{all,T,S,G}.txt`, consolidated in `v7-summary.tsv`, plus `v7-clamp-magnitude.txt`). Instruments: `prototype/426-revalidate-v7.pl` (+ driver `.sh`), follow-up probe `prototype/426-v7-clamp-magnitude.pl`.

### Hypothesis

V1–V5 cover per-key percentiles and V6 the display finalize; neither covers **bucket-stats**, whose shape is the opposite of the per-message surface — bounded partition cardinality (tens of buckets) with very large per-partition N. Verified in `ltl` before building: `%TIER_BPD{'bucket-stats'} = [16, 32, 53, 53, 53, 115, 616, 616, 616]` (`ltl:618-623`), 53 at the default tier 5 and 616 only from tier 7 — distinct from `message-stats` `[4,8,16,32,53,80,115,256,616]` and from the display surfaces' ladder; capture site `ltl:11029` (`counter_update(\%bucket_stats_counters, $bucket, $duration, $bucket_stats_buckets_per_decade)`, keyed by time bucket); consumer `calculate_statistics_bin()` (`ltl:12808`) calls `percentile($counter_entry, $q)` **directly against the streaming partition** — no `partition_rebin` anywhere on this path, unlike V6's finalize. If S's memory advantage is per-row overhead amortised across many rows, it should shrink or invert here. The `[min,max]` clamp (`ltl:12902`) is reproduced verbatim in all three arms, clamping to the **sidecar** min/max, which ltl populates per-sample from the raw duration.

### Method

Time buckets are contiguous runs of the chronological input (`iterate_durations` exposes no timestamp), sized to reproduce the surface's defining property: DPM `bin-dpm-full.log` at bucket-size 2,000 → **62 buckets**, N per bucket 798 / 2,000 / 2,000 (min/p50/max); Tomcat 148 MB at bucket-size 20,000 → **29 buckets**, N 15,800 / 20,000 / 20,000. Ladder p1, p5, p10, p25, p50, p75, p90, p95, p99, p999, p9999. bpd ∈ {16, 32, 53, 115, 616} — the whole bucket-stats rung set. Oracle comparison uses the `int` rank convention, so the residual is binning error alone. One process per (file, bpd, arm) so each RSS delta measures a single live store, plus an `--arm all` pass per (file, bpd) for the parity gate and the cross-arm tables. Medians of 3 with min–max.

### Result

**Parity, before any timing.** All 10 (file × bpd) configurations: `dpm-bpd{16,32,53,115,616}` and `tomcat-bpd{16,32,53,115,616}` each report `PARITY: PASS | N-conservation PASS (0 keys disagree)`. Per-key canonical digests identical for every bucket key and whole-store MD5 identical in all 10 runs. Independently, **T and S produce bit-identical accuracy figures** (`max_rel_err`, `within_1bin`, `mean_rel_err`) in all 10 configurations — a second, independent confirmation that S is a pure re-containering of T's arithmetic on this surface. G is a different geometry by construction and is not a parity target; its N-conservation passes everywhere.

Accuracy — 682 comparisons on DPM (62 buckets × 11 q) and 319 on Tomcat (29 × 11), zero-valued oracle answers excluded:

| file | bpd | bin width | T/S max rel err | T/S mean | G max rel err | G mean | within 1 bin (T/S · G) |
|---|---|---|---|---|---|---|---|
| dpm | 16 | 15.478% | 0.17774 | 0.03797 | 0.15137 | 0.03644 | 99.71% · 100.00% |
| dpm | 32 | 7.461% | 0.07460 | 0.01820 | 0.07145 | 0.01937 | 100% · 100% |
| dpm | **53** | 4.440% | 0.04390 | 0.01088 | 0.04321 | 0.01299 | 100% · 100% |
| dpm | 115 | 2.022% | 0.01971 | 0.00563 | 0.02022 | 0.00555 | 100% · 100% |
| dpm | 616 | 0.375% | 0.00373 | 0.00119 | 0.00374 | 0.00110 | 100% · 100% |
| tomcat | 16 | 15.478% | 0.14718 | 0.02532 | 0.15440 | 0.04242 | 100% · 100% |
| tomcat | 32 | 7.461% | 0.06705 | 0.01089 | 0.07443 | 0.02108 | 100% · 100% |
| tomcat | **53** | 4.440% | 0.04126 | 0.00749 | 0.04430 | 0.01292 | 100% · 100% |
| tomcat | 115 | 2.022% | 0.01751 | 0.00377 | 0.02018 | 0.00622 | 100% · 100% |
| tomcat | 616 | 0.375% | 0.00452 | 0.00076 | 0.00374 | 0.00104 | 99.69% · 100% |

Maximum relative error tracks the bin width almost exactly at every bpd in every arm — the error is binning error and nothing else. Only 4 of 3,005 arm-comparisons exceed one bin width, all T/S, all integer-quantisation artefacts (`dpm-bpd16 bucket00022/p90 got=73.330 want=73`; `tomcat-bpd616 bucket00006/p5 got=2.355 want=2`). G is competitive with T/S on max error at every bpd and slightly worse on mean error at low bpd on Tomcat (0.042 vs 0.025 at bpd 16), converging by bpd 115. Reported honestly: at DPM's bucket size (N≈2,000) p999 and p9999 have oracle index `int(n·q) = n−1`, so the oracle answer *is* the observed max and the clamp forces exact agreement — the prototype flags those rows as `degen%` per quantile. Tomcat's N≈20,000 makes p999 non-degenerate; p9999 remains degenerate there.

**The clamp does real, structural work, and it is asymmetric between the arms.** Clamp rate = share of (bucket, quantile) pairs where the *raw* interpolated value fell outside the observed `[min,max]`, at bpd 53:

| quantile | T/S hi/lo (dpm) | G hi/lo (dpm) | T/S hi/lo (tomcat) | G hi/lo (tomcat) |
|---|---|---|---|---|
| p1 | 0.00% / 17.74% | 0.00% / 20.97% | 0.00% / **100.00%** | 0.00% / **0.00%** |
| p5 | 0.00% / 9.68% | 0.00% / 20.97% | 0.00% / 93.10% | 0.00% / 0.00% |
| p10 | 0.00% / 3.23% | 0.00% / 16.13% | 0.00% / 93.10% | 0.00% / 0.00% |
| p25 | 0.00% / 0.00% | 0.00% / 0.00% | 0.00% / 27.59% | 0.00% / 0.00% |
| p50–p95 | 0.00% / 0.00% | 0.00% / 0.00% | 0.00% / 0.00% | ≤ 17.24% / 0.00% |
| p99 | 0.00% / 0.00% | 0.00% / 0.00% | 24.14% / 0.00% | 34.48% / 0.00% |
| p999 | 1.61% / 0.00% | 3.23% / 0.00% | 34.48% / 0.00% | 34.48% / 0.00% |
| p9999 | 100.00% / 0.00% | 100.00% / 0.00% | 41.38% / 0.00% | 37.93% / 0.00% |
| **all** | **9.24% / 2.79%** | **9.38% / 5.28%** | **9.09% / 28.53%** | **11.29% / 0.00%** |

The clamp fires on ~12% of all (bucket, quantile) pairs on DPM and up to 44% on Tomcat — removing it would break #224's Layer-2 invariant on this surface at scale. The T-vs-G difference is directional, not overall: **G eliminates low clamps entirely on Tomcat** (0.00% at every bpd against T/S's 28–32%), because Tomcat's observed min is exactly `1`, which sits on a grid boundary (`10^0`), so `grid_lower` for the bin holding the minimum *is* the minimum and interpolation cannot fall below it — while T seeds from the first observed value (55 in bucket 0) and produces boundaries at 0.9896, below the true min, so p1 lands under min on 100% of buckets. But **G does not eliminate low clamps in general**: on DPM G's low-clamp rate is *higher* than T/S (5.28% vs 2.79% at bpd 53), because DPM's observed min is `2`, which is not on a grid boundary (`grid_lower(grid_index(2)) = 1.91875` at bpd 53). High clamps are essentially identical across all three arms (9.2% vs 9.4% on DPM; 9.1% vs 11.3% on Tomcat).

**Every clamp excursion is bounded by one bin width, in all three arms** (`v7-clamp-magnitude.txt`; multiplicative gap outside `[min,max]`):

| file | bpd | bin width | T/S lo max · med | T/S hi max · med | G lo max · med | G hi max · med |
|---|---|---|---|---|---|---|
| dpm | 16 | 1.154782 | 1.145155 · 1.071333 | 1.152896 · 1.065130 | 1.117270 · 1.083744 | 1.147144 · 1.074760 |
| dpm | 53 | 1.044403 | 1.037030 · 1.014983 | 1.045830 · 1.019195 | 1.040265 · 1.026194 | 1.042968 · 1.022267 |
| dpm | 616 | 1.003745 | 1.002423 · 1.000875 | 1.003983 · 1.001462 | 1.001453 · 1.001244 | 1.003728 · 1.001589 |
| tomcat | 16 | 1.154782 | 1.13638 · 1.07162 | 1.14756 · 1.08013 | — (none) | 1.15236 · 1.12845 |
| tomcat | 53 | 1.044403 | 1.03794 · 1.01356 | 1.04053 · 1.02654 | — (none) | 1.04229 · 1.03583 |
| tomcat | 616 | 1.003745 | 1.00343 · 1.00173 | 1.00274 · 1.00085 | — (none) | 1.00174 · 1.00166 |

No excursion in any arm at any bpd exceeds one bin width. T's seed range is arbitrary (bucket 0's partition spans `[0.174, 17392]` from a first value of 55), but that does not translate into large excursions: the interpolation is confined to the *populated* bin, whose boundaries are within a bin width of the observed extreme by construction. The clamp repairs a sub-bin-width discrepancy, frequently but never severely, and its cost scales down directly with bpd.

**Memory — at bounded cardinality S loses its advantage over T, and can be worse.** RSS delta from single-arm processes, `Devel::Size` alongside:

| file | bpd | T RSS kB · bytes | S RSS kB · bytes | G RSS kB · bytes |
|---|---|---|---|---|
| dpm (62 buckets) | 16 | 208 · 194,786 | 224 · 168,348 | **128** · 136,422 |
| dpm | **53** | 416 · 398,378 | 512 · **412,692** | **352** · 341,054 |
| dpm | 115 | 688 · 674,890 | 912 · **791,212** | **672** · 645,686 |
| dpm | 616 | 3,120 · 2,531,282 | 4,256 · **3,588,988** | **2,912** · 2,714,054 |
| tomcat (29 buckets) | 16 | 112 · 82,909 | 80 · 68,335 | **64** · 54,209 |
| tomcat | **53** | 240 · 167,093 | 224 · 168,247 | **176** · 141,193 |
| tomcat | 115 | 288 · 285,805 | **480** · 329,503 | 336 · 271,649 |
| tomcat | 616 | 1,200 · 1,030,629 | **2,000** · 1,504,815 | 1,264 · 1,143,857 |

**S is worse than T at bpd ≥ 115 on both fixtures** (+67% RSS on Tomcat at 616, +36% on DPM). This inverts the per-key-surface result and is the expected consequence of the surface's shape: S's saving is per-row column overhead amortised across many rows, and this surface has 29–62 rows. G is the smallest or joint-smallest arm in 6 of 8 cells, and its advantage also narrows at high bpd. Absolute magnitudes are ≤ 4 MB throughout.

**Timing** (medians of 3, [min, max]). Build:

| file | bpd | T | S | G |
|---|---|---|---|---|
| dpm | 53 | 0.1120 [0.1118, 0.1122] | 0.0779 [0.0778, 0.0790] | **0.0544** [0.0542, 0.0548] |
| dpm | 616 | 0.1265 [0.1253, 0.1277] | 0.0999 [0.0995, 0.1002] | **0.0562** [0.0558, 0.0562] |
| tomcat | 53 | 0.5331 [0.5319, 0.5336] | 0.3646 [0.3641, 0.3658] | **0.2592** [0.2588, 0.2595] |
| tomcat | 616 | 0.5458 [0.5442, 0.5473] | 0.3733 [0.3732, 0.3735] | **0.2621** [0.2613, 0.2626] |

Build cost is flat in bpd for all arms; G ≈ 0.48× T, S ≈ 0.68× T, consistently. Ladder (the full 11-quantile ltl ladder plus clamp across all buckets, native `ceil` convention):

| file | bpd | T | S | G |
|---|---|---|---|---|
| dpm | 16 | 0.00793 [0.00775, 0.00812] | 0.00508 [0.00490, 0.00518] | **0.00433** [0.00430, 0.00443] |
| dpm | 53 | 0.02349 [0.02348, 0.02358] | 0.01239 [0.01236, 0.01252] | **0.01143** [0.01125, 0.01144] |
| dpm | 616 | 0.28252 [0.28159, 0.28534] | 0.12720 [0.12690, 0.12729] | **0.10931** [0.10923, 0.11000] |
| tomcat | 53 | 0.00908 [0.00908, 0.00908] | 0.00468 [0.00467, 0.00471] | **0.00416** [0.00416, 0.00416] |
| tomcat | 616 | 0.11126 [0.11095, 0.11178] | 0.04463 [0.04454, 0.04499] | **0.03939** [0.03939, 0.03941] |

Ladder cost scales ~linearly with bpd (T: 35× from bpd 16 to 616, for a 38.5× bpd increase) and is nearly independent of N — normalised per bucket per quantile the two fixtures agree closely (dpm 34.4 µs vs tomcat 28.5 µs at bpd 53; 414 µs vs 349 µs at 616). Mechanism, measured directly: `percentile()` walks all `bin_count` bins per quantile regardless of occupancy. On DPM, T's mean allocated `bin_count` is 117.8 (bpd 16) → 392.8 (53) → **4,569.4** (616) while mean *occupied* bins are 47.0 → 96.6 → **257.7**, an occupancy of 39.9% → 24.6% → **5.6%**; G's mean span is 69.7 / 229.1 / 2,655.1 against S's dense-view 98.3 / 326.8 / 3,796.6. At bpd 616 T walks ~18× more bins than are occupied.

### Surprises

- **S is the largest arm at bpd ≥ 115 on this surface** — the per-key-surface memory ranking does not transfer to a bounded-cardinality store.
- **G removes 100% of Tomcat's low clamps and adds low clamps on DPM.** The determining fact is whether the observed minimum sits on a grid boundary (Tomcat min = 1 does; DPM min = 2 does not), which is a data property, not a representation property.
- T's arbitrary seed range does *not* produce large clamp excursions; every excursion in every arm stays inside one bin width.
- At tier 5 (bpd 53, the shipping default for this surface) the whole ladder costs 9–23 ms. The O(`bin_count`) walk only becomes visible at tier 7+ (bpd 616), where T reaches 0.11–0.28 s.

### Findings and actions

1. **S is digest-identical to T on the bucket-stats surface** at all five bucket-stats rungs on both fixtures, and produces bit-identical accuracy figures independently of the digest.
2. **All three arms are inside one bin width essentially always** (4 of 3,005 comparisons outside, all T/S integer-quantisation artefacts); maximum error tracks the bin width at every rung in every arm.
3. **The `[min,max]` clamp is load-bearing on this surface and must be kept by any representation** — 9–44% of (bucket, quantile) pairs — and its excursions are bounded by one bin width in every arm, so it is a precision correction, not a defect repair.
4. **S's memory advantage is a per-key-surface property, not a general one.** At 29–62 rows S is 1.0–1.67× *larger* than T at bpd ≥ 115. Any memory claim for P9 must name the surface it is about.
5. **The percentile ladder is O(`bin_count`) and that is where the arms separate**: S roughly halves T's ladder cost and G takes a further 10–14%, both by walking a shorter array rather than by doing different arithmetic.

### Not covered by V7

Real ltl time buckets (buckets here are contiguous runs of fixed sample count; real buckets have unequal N and can be empty, so anything sensitive to N *skew* is untested). `%bucket_stats_counters_hl` (the highlight subset, `ltl:845`) is not exercised. No merge path — `calculate_statistics_bin` reads the streaming partition directly, so V7 exercises add + percentile only. The rest of `calculate_statistics_bin` (mean, std_dev/cv, skewness/kurtosis/BC from the Welford–Pébay sidecars, and the `$demand` gating) is not measured; the sidecars are arm-independent by construction, but that is an argument, not a measurement. p9999 is degenerate on DPM and **p99999 was not evaluated at all** — at every N reachable here it collapses onto the same sample as p9999. RSS deltas are 16 kB-quantised and small in absolute terms; differences under ~50 kB should not be over-read. `ltl` was not run: the prototype's ladder was not cross-checked against live `ltl -V` output on the same input.

### Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
prototype/426-revalidate-v7.sh        # 10 x (--arm all) + 30 single-arm processes, bpd 16/32/53/115/616
perl prototype/426-revalidate-v7.pl --file /tmp/ltl-426-fixtures/bin-dpm-full.log \
    --bpd 53 --bucket-size 2000 --arm all
perl prototype/426-revalidate-v7.pl --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt \
    --bpd 53 --bucket-size 20000 --arm T          # likewise S, G — one store per process for the RSS delta
perl prototype/426-v7-clamp-magnitude.pl > prototype/426-results/v7/v7-clamp-magnitude.txt
```

---

## V8 — Merge shapes beyond consecutive pairs and the `-g` fold

Results and captures: `prototype/426-results/n5-merge-shapes/` — `{T,S,G}-bpd{53,616}-{fanout,dpm}.txt` (12 runs, one arm per process), `driver.txt` (parity + N-conservation gate), `timings.tsv`, `verify.txt`, `verify-order.txt`. Instruments: `prototype/426-n5-merge-shapes.pl` (+ driver `.sh`), independent cross-check `prototype/426-n5-verify.pl`.

### Hypothesis

V2 and V5 measured two merge shapes: 725/1,258 disjoint consecutive-key pairs and one long `-g` fold. The shapes ltl actually runs also include `merge_bin_state`'s bucket→global **rollup**, merges between keys with **disjoint value ranges**, and — because a fold is a chain — accumulation **depth**. If T's remap is the mechanism that breaks the R4 one-bin bound (V5 finding 4), the bound should degrade with *depth* rather than with the disjointness of any single merge; and if G's merge is an index-wise add on a shared grid, its bound should hold under every shape.

### Method

Four sections, each measured per arm per bpd per fixture in one process (parse once into per-key value lists; every timed section measures the store, not the regex). **R — rollup**: 2,000 source keys merged into one accumulating target, `drop_source => 1`, fresh store per run; rolled-up percentiles checked against the oracle over the union of all 2,000 keys' values. **D — disjoint spans**: 200 pairs selected greedily so `min(hi) > max(lo)`, partner chosen to *maximise* the gap (widest union geometry, most remapping). **P — merge depth**: 200 groups of 16 keys; one target accumulates 1, 3, 7, 15 successive merges, scored against a *running* oracle at each depth (1,000 evaluations per depth per cell). **O — order dependence**: 25 groups of 8 keys, each merged into a **neutral** target (so the target key is not itself part of the ordering — a true set merge) in 4 orders (as-is, reversed, two seeded shuffles). Fixtures: `bin-twxdur-full.log` (288,025 samples, 286,659 keys, only 148 with N ≥ 2, so sections D/P/O run there with `--min-n 1`) and `bin-dpm-full.log` (122,798 samples, 3,419 keys, 3,310 with N ≥ 2, `--min-n 2`). Perl v5.42.2, `caffeinate -s`, medians of 3 with min–max. Error metric `bins_err = |log10(est/exact)| × bpd`, so 1.0 is one bin width of that arm's bpd; because `%.4f` rounding cannot distinguish "exactly at the bound" from "just over it", every distribution also reports `_maxraw` (`%.12g`) and `_gt1eps` (count strictly above `1 + 1e-9`). Oracle rank convention `int`, the same for all arms.

### Result

**Parity, before any timing** (`driver.txt`, gate run before the tables were read):

| fixture/bpd | rollup_digest | disjoint_digest | rollup/depth15/disjoint max err | order_groups_differing |
|---|---|---|---|---|
| fanout/53 | PASS | PASS | PASS | PASS (24) |
| fanout/616 | PASS | PASS | PASS | PASS (23) |
| dpm/53 | PASS | PASS | PASS | PASS (17) |
| dpm/616 | PASS | PASS | PASS | PASS (21) |

`PARITY_OK=1  RUNS_FAILED=0`. N conservation: `rollup_n_after == rollup_values` in all 12 runs (78,612 dpm / 2,754 fanout), and `disjoint_n_conserved_pairs = 200/200` in every cell.

**Rollup** — many keys into one target:

| bpd | fixture | arm | rollup s median (min–max) | µs/merge | err p50 | err max (raw) | > 1 bin |
|---|---|---|---|---|---|---|---|
| 53 | fanout | T | 0.1116 (0.1115–0.1116) | 53.8 | 0.4671 | **1.4116** | 1/5 |
| 53 | fanout | S | 0.1926 (0.1924–0.1930) | 93.7 | 0.4671 | **1.4116** | 1/5 |
| 53 | fanout | G | 0.00197 (0.00197–0.00198) | **0.96** | 0.1131 | 0.6596 | 0 |
| 53 | dpm | T | 0.1380 (0.1380–0.1381) | 67.9 | 0.0907 | 0.5223 | 0 |
| 53 | dpm | S | 0.2629 (0.2628–0.2636) | 128.9 | 0.0907 | 0.5223 | 0 |
| 53 | dpm | G | 0.00467 (0.00466–0.00468) | **2.26** | 0.0801 | 0.9924 | 0 |
| 616 | fanout | T | 1.1958 (1.1725–1.2172) | 589.7 | 0.3621 | 0.5476 | 0 |
| 616 | fanout | S | 2.0123 (1.9556–2.0210) | 983.9 | 0.3621 | 0.5476 | 0 |
| 616 | fanout | G | 0.00255 (0.00254–0.00255) | **1.24** | 0.0622 | 0.5954 | 0 |
| 616 | dpm | T | 1.4614 (1.4592–1.4616) | 703.4 | 0.2048 | **1.0219** | 1/5 |
| 616 | dpm | S | 2.6997 (2.6691–2.7123) | 1365.2 | 0.2048 | **1.0219** | 1/5 |
| 616 | dpm | G | 0.02803 (0.02795–0.02807) | **14.03** | 0.1126 | 0.9924 | 0 |

G is 50–475× faster per rollup merge than T and 2.9–4.6× faster than S's pairwise cost; S is consistently 1.7–2.0× slower than T on rollup, from the dense-view round trip that V2's addendum removes with S2. Rollup geometry never rebinned on either fixture (`rollup_rebins=0`); T's union `bin_count` reaches 461–6,324 slots, G's occupied span 197–3,245.

**Disjoint spans** — 200 pairs per cell; gap between the two ranges fanout p50 3.436 / max 4.477 decades, dpm p50 2.626 / max 4.841 decades:

| bpd | fixture | arm | µs/merge | err p50 | err p95 | err max (raw) | > 1 bin | union geometry (max) |
|---|---|---|---|---|---|---|---|---|
| 53 | fanout | T | 84.9 | 0.4244 | 0.6604 | 0.7859 | 0 | bin_count 502 |
| 53 | fanout | S | 119.8 | 0.4244 | 0.6604 | 0.7859 | 0 | bin_count 502 |
| 53 | fanout | G | **1.05** | 0.7202 | 0.8062 | 1.000000 | **0** | span 238 |
| 53 | dpm | T | 89.2 | 0.3103 | 0.8174 | **1.0008** | **1**/1000 | bin_count 522 |
| 53 | dpm | S | 124.2 | 0.3103 | 0.8174 | **1.0008** | **1**/1000 | bin_count 522 |
| 53 | dpm | G | **2.76** | 0.2351 | 0.9015 | 0.9897 | 0 | span 270 |
| 616 | fanout | T | 931.9 | 0.0947 | 0.2729 | 0.2729 | 0 | bin_count 5,837 |
| 616 | fanout | S | 1273.6 | 0.0947 | 0.2729 | 0.2729 | 0 | bin_count 5,837 |
| 616 | fanout | G | **1.25** | 0.2003 | 0.6966 | 1.000000 | **0** | span 2,758 |
| 616 | dpm | T | 893.8 | 0.3582 | 0.8032 | 0.9859 | 0 | bin_count 6,068 |
| 616 | dpm | S | 1248.4 | 0.3582 | 0.8032 | 0.9859 | 0 | bin_count 6,068 |
| 616 | dpm | G | **15.14** | 0.2913 | 0.8793 | 0.9947 | 0 | span 3,133 |

Every G `max = 1.000000` has `_gt1eps = 0` — the bound is attained exactly and never exceeded. T's single dpm/53 case at 1.0008 is a genuine, marginal breach. **A single disjoint merge is not what breaks T's bound**: despite gaps to 4.84 decades and union geometries to 6,068 bins, T's worst single-merge error over 4,000 evaluations is 1.0008 bins.

**Merge depth** — 1,000 evaluations per depth per cell (200 groups × 5 quantiles). S is omitted (digest-identical to T in every cell, `driver.txt` PASS):

| bpd | fixture | depth | T p50 | T p95 | T max (raw) | **T > 1 bin** | G p50 | G p95 | G max (raw) | **G > 1 bin** |
|---|---|---|---|---|---|---|---|---|---|---|
| 53 | fanout | 1 | 0.3390 | 0.8367 | 0.9914 | **0** | 0.4479 | 0.9284 | 0.9996 | 0 |
| 53 | fanout | 3 | 0.3468 | 0.8579 | 1.3331 | **5** | 0.4601 | 0.9491 | 0.9996 | 0 |
| 53 | fanout | 7 | 0.3683 | 0.8678 | 1.4234 | **19** | 0.4834 | 0.9588 | 1.000000 | 0 |
| 53 | fanout | 15 | 0.3875 | 0.8606 | 1.3715 | **14** | 0.4237 | 0.9509 | 1.000000 | 0 |
| 53 | dpm | 1 | 0.3426 | 0.9990 | 1.2502 | **48** | 0.3042 | 0.9239 | 1.000000 | 0 |
| 53 | dpm | 3 | 0.3246 | 1.0660 | 1.4046 | **66** | 0.2763 | 0.8989 | 1.000000 | 0 |
| 53 | dpm | 7 | 0.3083 | 1.1223 | 1.5125 | **78** | 0.2593 | 0.9239 | 1.000000 | 0 |
| 53 | dpm | 15 | 0.2785 | **1.2259** | **2.1026** | **98** | 0.2343 | 0.9414 | 1.000000 | 0 |
| 616 | fanout | 1 | 0.2531 | 0.4477 | 0.4925 | **0** | 0.4827 | 0.9523 | 0.9990 | 0 |
| 616 | fanout | 3 | 0.2447 | 0.4625 | 1.1296 | **1** | 0.4691 | 0.9619 | 0.9990 | 0 |
| 616 | fanout | 7 | 0.2116 | 0.4639 | 1.2855 | **3** | 0.4812 | 0.9619 | 1.000000 | 0 |
| 616 | fanout | 15 | 0.2198 | 0.5390 | 1.3069 | **6** | 0.4886 | 0.9357 | 1.000000 | 0 |
| 616 | dpm | 1 | 0.3859 | 0.9903 | 1.4860 | **46** | 0.3632 | 0.9453 | 1.000000 | 0 |
| 616 | dpm | 3 | 0.3828 | 1.0776 | 1.7021 | **64** | 0.3341 | 0.9302 | 1.000000 | 0 |
| 616 | dpm | 7 | 0.3795 | 0.9565 | 1.6769 | **36** | 0.3321 | 0.9302 | 1.000000 | 0 |
| 616 | dpm | 15 | 0.4014 | 0.9883 | 2.0637 | **47** | 0.3201 | 0.9249 | 1.000000 | 0 |

**G: 0 breaches in 16,000 depth evaluations** across every depth, bpd and fixture; its maximum is exactly 1.000000, never above. **T's worst-case error grows monotonically with depth in all four cells** (53/fanout 0.99→1.33→1.42; 53/dpm 1.25→1.40→1.51→**2.10**; 616/fanout 0.49→1.13→1.29→1.31; 616/dpm 1.49→1.70→1.68→**2.06**), and on the fanout fixture the breach *count* grows monotonically too (0→5→19). On dpm/53 the p95 itself crosses one bin by depth 3 and reaches 1.2259 by depth 15 — the breach is no longer a tail case. Raising bpd does not rescue T: at 616 the worst error is still 2.06 bins, because the error is proportional to bin count, not to bin width.

**Order dependence** — 25 groups × 8 keys × 4 orders into a neutral target; spread = `|log10(max/min)| × bpd` across the four orders, per quantile:

| bpd | fixture | arm | groups differing | % | spread p95 | spread max (raw) | spread > 1 bin |
|---|---|---|---|---|---|---|---|
| 53 | fanout | T = S | **24/25** | **96.0** | 1.0005 | **2.0006** | 10 |
| 53 | fanout | G | **0/25** | **0.0** | 0.0000 | **0** | 0 |
| 53 | dpm | T = S | **17/25** | **68.0** | 1.0002 | **2.0003** | 9 |
| 53 | dpm | G | **0/25** | **0.0** | 0.0000 | **0** | 0 |
| 616 | fanout | T = S | **23/25** | **92.0** | 1.0001 | 1.0003 | 19 |
| 616 | fanout | G | **0/25** | **0.0** | 0.0000 | **0** | 0 |
| 616 | dpm | T = S | **21/25** | **84.0** | 1.0000 | 1.0002 | 12 |
| 616 | dpm | G | **0/25** | **0.0** | 0.0000 | **0** | 0 |

G's spread is exactly 0 in every cell: the canonical strings are byte-identical across all orderings, so the percentiles are too. An independent cross-check (`verify-order.txt`, a separate script, 6 disjoint 8-key groups, 4 orders each, bpd 53, dpm) finds T and S producing **3–4 distinct canonical states** from the same set for 5 of 6 groups and G producing **exactly 1** for all 6; `verify.txt` also confirms N conservation (461) at depth 15 on a hand-built chain.

### Surprises

- **Disjointness is not the breaker; depth is.** The shape designed to maximise remapping (gaps to 4.84 decades) produces one breach in 4,000 evaluations; four successive merges of ordinary keys produce dozens.
- **Rollup into a neutral target amplifies T's order dependence** well past what V1 measured on pairwise/fold shapes: 68–96% of groups against V1's 105/200 (52.5%), and per-quantile spread to **2.00 bins** against V1's 0.99. V1's spread figure was a lower bound for the shapes it tested.
- **Under the rollup shape G is both faster and more accurate than T** (p50 error 0.08–0.11 bins against 0.09–0.47, max 0.60–0.99 against 0.52–1.41) — on that shape it is not a speed/accuracy trade at all.
- The fan-out fixture is singleton-dominated (286,659 keys, only **148** with N ≥ 2), which is what a bucket→global rollup over a high-cardinality key space actually does; DPM (3,310 keys with N ≥ 2, 78,612 values rolled up) covers the dense case.

### Findings and actions

1. **T ≡ S on every merge shape.** Rollup, disjoint, depth and order digests identical at both bpd on both fixtures, including the order-dependence counts and every error distribution. P8+P9 carry the production merge semantics exactly in shapes V2 and V5 never tested. S's only divergence from T is cost: 1.4–2.0× slower per merge in every cell, from the dense-view round trip — which V2's addendum removes.
2. **The one-bin breach is a merge-depth effect, confirming and sharpening V5 finding 2/4.** A single maximally disjoint merge stays within one bin on 3,999 of 4,000 evaluations (worst 1.0008); successive merges break it, because each remap re-projects already-remapped counts by geometric midpoint and the displacement compounds — monotonically, to 2.10 bins at depth 15.
3. **G's one-bin bound holds exactly under every merge shape tested** — 0 breaches in 16,000 depth + 4,000 disjoint + 20 rollup evaluations, with every apparent ">1" being exactly 1.000000 (`_gt1eps = 0`). Structural: the merge is an index-wise add on a shared grid, so no count is ever re-projected.
4. **G is merge-commutative and order-independent under set merges; T and S are not**, on 68–96% of groups with spread to 2.00 bins, reproduced by an independent script. S reproducing T's order dependence exactly is itself part of the parity proof.
5. **G's merge-cost advantage widens with union width**, 56× to 475× on rollup and 81× to 745× on disjoint pairs; T's per-merge cost scales with the union `bin_count` (461 → 5,358 slots from bpd 53 to 616 gives 53.8 → 589.7 µs), G's with the occupied span.

### Not covered by V8

No ltl-side measurement: the real `merge_bin_state` also merges Welford–Pébay M2/M3/M4 sidecars and `merge_consolidation_stats` merges min/max/sums/UDMs, none of which is in any timing here, so a real ltl consolidation's merge cost is strictly larger and the bin-counter share of it is not established. No `-g` fuzzy-consolidation call structure (the real sites attach/detach `bin_entry` and delete hash slots per merge; that overhead is excluded). T's adopt-by-reference path is untested for aliasing here — every merge used `drop_source => 1` and no key was re-added (V2's addendum covers it directly). Two bpd values and two fixtures only; no Tomcat access log. Depth measured to 15, so the monotone growth is established over 1→15 but the asymptote is not — a `-g` fold over thousands of keys goes far deeper. Order dependence measured over 4 orderings of 8 keys, so `order_groups_differing` is a lower bound on how many distinct states T can reach (8! = 40,320 orderings exist per group; the independent check found 4 distinct states from just 4 samples). Only 25 order groups per cell. Error measured against the oracle's `int` rank convention; under ltl's native `ceil` the absolute errors would differ, though the arm-to-arm comparison is convention-independent.

### Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
prototype/426-n5-merge-shapes.sh            # 12 runs (3 arms x 2 bpd x 2 fixtures) + parity gate
perl prototype/426-n5-merge-shapes.pl --arm T --bpd 53 --file /tmp/ltl-426-fixtures/bin-dpm-full.log \
    --runs 3 --rollup-keys 2000 --disjoint-pairs 200 --depth-groups 200 --order-keys 200 --order-perms 4 --min-n 2
perl prototype/426-n5-merge-shapes.pl --arm G --bpd 616 --file /tmp/ltl-426-fixtures/bin-twxdur-full.log \
    --runs 3 --rollup-keys 2000 --disjoint-pairs 200 --depth-groups 200 --order-keys 200 --order-perms 4 --min-n 1
perl prototype/426-n5-verify.pl > prototype/426-results/n5-merge-shapes/verify.txt
```

---

## V9 — The re-bless enumeration, the accuracy decomposition, and the store at the motivating scale

Results and captures: `prototype/426-results/v8-rebless/{run-bpd53.txt, rebless-bpd53.tsv}`, `prototype/426-results/accuracy-by-key-shape/{dpm-ladder.txt, tomcat-ladder.txt, tomcat-bpd53.txt, fanout-bpd53.txt}`, `prototype/426-results/message-stats-scale/fanout.txt`. Instruments: `prototype/426-revalidate-v8-rebless.pl`, `prototype/426-accuracy-by-key-shape.pl`, `prototype/426-message-stats-scale.pl`.

### Hypothesis

Three questions the earlier aspects leave open. **(a)** `tests/validate-statistics.sh` compares ltl's CSV output against committed baselines at full precision and `compare-statistics-drift.pl` classifies any per-cell deviation above 1% as T3, which blocks; five of the eighteen scenarios run the bin data model, so those five are the re-bless surface for any representation change. How large is the shift? **(b)** V5's per-quantile tables and the re-bless classification both report *magnitudes*, not *direction* — a cell that classifies T3 has moved more than 1%, which says nothing about whether it moved toward or away from the true value. Decomposed by key shape, is there a systematic structure? **(c)** The locked objective is "replace the container, and measure what the container change does to the cardinality constraint that holds the per-message surface at a coarser resolution". What does it do, measured at the scale the constraint is about?

### Method

**(a)** The scenario list is read from `tests/statistics-drift/scenarios.tsv` so it cannot drift from the harness; for each scenario's logfile the per-key percentile computation is reproduced under arms T (today) and G at the message-stats bpd the scenario resolves to (53 at the default tier), and the per-quantile deviation distribution against T is classified with `compare-statistics-drift.pl`'s own tiers. The exact oracle is carried as a third column so a cell that moves can be seen moving *toward* or *away from* the true value. `ltl` is not modified. **(b)** Keys are banded by observation count (`N<10 / N<100 / N<1000 / N>=1000`) × value spread in decades (`<0.1 / <1 / >=1`), and T's and G's mean error against the exact oracle is reported per band, per bpd, over the full tier ladder on DPM (16/32/53/80/115/256/616), three rungs on Tomcat (16/115/616 plus the 53 detail) and one rung on the fan-out fixture. **(c)** All three arms are built over the real message-stats keying (`$category\x1f$log_key`, as `counter_update` is called in `read_and_process_logs`) at the full fan-out fixture — **built at size, not projected** — and the statistics pass is timed: build once, then evaluate percentiles across every key. Medians of 3 with min–max.

### Result

**(a) The re-bless enumeration** (`v8-rebless/run-bpd53.txt`, message-stats bpd 53):

| scenario | file | keys | cells | T1 | T2 | **T3 (blocking)** | worst deviation | G closer / further / tie |
|---|---|---|---|---|---|---|---|---|
| apache-bin-data-model | ApacheHTTP2Server access log | 55 | 605 | 51.07% | 27.11% | **21.82%** | 3.8923% at p1 | 142 (23.47%) / 154 (25.45%) / 309 |
| tomcat-bin-data-model | Tomcat 2025-05-07 | 3,074 | 33,814 | 73.33% | 10.79% | **15.88%** | 4.1625% at p75 | 1,907 (5.64%) / 7,111 (21.03%) / 24,796 |
| tomcat-heatmap-bin | Tomcat 2025-05-07 | 3,074 | 33,814 | 73.33% | 10.79% | **15.88%** | 4.1625% at p75 | 1,907 (5.64%) / 7,111 (21.03%) / 24,796 |
| thingworx-bin-data-model | DPM ScriptLog | 3,419 | 37,609 | 43.82% | 24.52% | **31.67%** | 4.5191% at p95 | 8,959 (23.82%) / 12,170 (32.36%) / 16,480 |
| codebeamer-bin-data-model | — | — | — | — | — | — | — | **NOT COVERED** |

The T3 rate is concentrated in the middle of the ladder and vanishes at the tails: on `thingworx-bin-data-model` it runs p1 18.22% → p25 57.39% → p50 58.79% → p75 60.34% → p95 38.23% → p99 2.16% → p999 0.00% → p9999 0.00%; on `tomcat-bin-data-model` p1 16.07% → p25 34.52% → p50 34.09% → p90 12.85% → p999 2.15% → p9999 0.00%; on `apache-bin-data-model` p10 41.82% is the peak and p99/p999/p9999 are 0.00%. **`codebeamer-bin-data-model` is reported NOT COVERED, not skipped**: the library's two verbatim parsers do not read that log's bracketed `[293ms]` duration, which ltl reads through the format registry. It is a limitation of the prototype's parsers, not an ltl finding.

**(b) The accuracy decomposition by key shape.** The aggregate "G lands further from the oracle more often than closer" in (a) is a composition effect. On DPM across the full ladder (`accuracy-by-key-shape/dpm-ladder.txt`, mean error against the exact oracle):

| band | bpd 16 T / G | bpd 53 T / G | bpd 115 T / G | bpd 616 T / G |
|---|---|---|---|---|
| N<10 / spread<0.1dec (2,054 cells) | 1.3219% / **1.0239%** | **0.4799%** / 0.5207% | 0.2986% / **0.2832%** | **0.0710%** / 0.0814% |
| N<100 / spread<1dec (2,120) | 4.3649% / **3.7655%** | **1.1983%** / 1.3806% | 0.6170% / **0.6151%** | 0.1335% / **0.1176%** |
| N<100 / spread>=1dec (1,338) | 6.0624% / **4.7997%** | 1.6294% / **1.6243%** | **0.8041%** / 0.8651% | 0.1609% / **0.1344%** |
| N<1000 / spread>=1dec (186) | 6.7845% / **3.5972%** | 1.6682% / **1.0591%** | **0.7313%** / 0.8793% | 0.1373% / **0.1254%** |

On Tomcat (`tomcat-ladder.txt`, `tomcat-bpd53.txt`) the direction is more consistent: at bpd 16 G is ahead on every band with N ≥ 100 (e.g. `N>=1000 / spread<1dec` 9.3206% against 9.6489%); at 53 T is ahead on almost every band (`N>=1000 / spread<1dec` 0.9531% against 2.7706%); **from bpd 115 up T is ahead on Tomcat and stays ahead at 616** (`N>=1000 / spread<1dec` 0.0210% against 0.2385%). Both arms are sub-1% on every band at bpd 616 on both files. Mechanism: T seeds each key's partition around that key's own first value (#187 D5), so its bins are adaptive to that key's data — an advantage that **grows** with resolution, because the seeded range concentrates bins where the key has values; G never wastes resolution on a seeded range the key does not occupy, which dominates when bins are **scarce**.

At the fan-out cardinality the whole question is nearly moot (`fanout-bpd53.txt`): **573,026 of 573,318 compared cells are exact for both arms** — the high-cardinality population is dominated by single-observation keys, where every representation returns that observation. Of the 292 non-degenerate cells G is closer on every band (`N<10/spread<1dec` 0.8754% against 0.9372%; `N<100/spread>=1dec` 1.0149% against 1.4606%; `N<1000/spread>=1dec` 0.2594% against 0.3516%).

**(c) The store at the motivating scale** (`message-stats-scale/fanout.txt`; 286,659 distinct keys, 288,025 observations; build once then evaluate percentiles across every key; medians of 3):

| bpd | arm | build | percentiles (286,659 keys × 3 q) | memory | B/key |
|---|---|---|---|---|---|
| 53 | T | 1.518 s [1.401, 1.628] | 17.634 s [17.616, 17.640] | 662.3 MB | 2,423 |
| 53 | **S** | 1.233 s [1.220, 1.243] | **2.112 s** [2.111, 2.118] | **291.7 MB** | 1,067 |
| 53 | G | 0.697 s [0.693, 0.702] | 1.616 s [1.609, 1.617] | 194.7 MB | 712 |
| 616 | T | 2.966 s [2.899, 3.024] | **181.348 s** [181.257, 181.921] | **3,722.4 MB** | 13,616 |
| 616 | **S** | 1.294 s [1.286, 1.307] | **2.281 s** [2.260, 2.287] | **293.9 MB** | 1,075 |
| 616 | G | 0.738 s [0.731, 0.752] | 1.731 s [1.697, 1.733] | 196.9 MB | 720 |

At the default tier's message-stats resolution S is **8.4× on percentile evaluation and 2.2× on memory**; at bpd 616 it is **79.5× and 12.7×**. The load-bearing half is the growth shape: **across the ladder T grows 10.3× in time and 5.6× in memory; S grows 1.08× and 1.008×.**

### Surprises

- The T-vs-G accuracy difference **reverses across the tier ladder**, and in opposite directions on the two files. It is not a fixed property of either representation.
- At the cardinality #426 exists for, the representation choice is **accuracy-neutral**: 99.95% of cells are exact for both arms.
- T's dense seeded array — sized by the partition, not by the data — is what makes per-message resolution expensive. A span-only container removes that coupling almost entirely (S's percentile pass moves 2.112 → 2.281 s across a ladder over which T's moves 17.634 → 181.348 s).

### Findings and actions

1. **A shared grid on the message-stats surface is a large re-bless**: 15.9–31.7% of per-key percentile cells classify T3 (blocking) at bpd 53 on the three scenarios the prototype's parsers can read, with worst deviations 3.89–4.52%. The shift is concentrated at p10–p95 and is zero at p999/p9999.
2. **The T3 classification carries no direction, and the direction is mixed**: on `tomcat-bin-data-model` G is further on 21.03% of cells and closer on 5.64%; on `thingworx-bin-data-model` 32.36% further and 23.82% closer. A re-bless decision needs both columns.
3. **The T-vs-G accuracy trade is resolution-dependent and reverses across the ladder** — at bpd 16 G is better on both files (and by a wide margin on wide-spread keys: DPM `N<1000 / spread>=1dec` 3.5972% against 6.7845%); at 53 mixed on DPM and T ahead on Tomcat; from 115 up T is ahead on Tomcat and stays ahead at 616. Both arms are sub-1% on every band at 616.
4. **The surface #426 exists for is accuracy-neutral**: at 287k keys 573,026 of 573,318 cells are exact for both arms, and of the 292 non-degenerate cells G is closer on every band. The trade in finding 3 lives entirely in the moderate-cardinality, multi-observation population.
5. **The container change's effect on the constraint grows with resolution**, measured at size rather than projected: S is 8.4× / 2.2× at bpd 53 and 79.5× / 12.7× at 616 on percentile time and memory, because T grows 10.3× / 5.6× across the ladder while S grows 1.08× / 1.008×. **This is evidence about what the per-message row could afford; it is not a proposal to change `%TIER_BPD`, which is locked.**

### Not covered by V9

`codebeamer-bin-data-model` (see above — NOT COVERED, not skipped). The re-bless enumeration is at bpd 53 only, and it reproduces the per-key percentile computation rather than running ltl's CSV pipeline, so it enumerates the shift `compare-statistics-drift.pl` would classify without producing the classified diff itself. The decomposition covers the full ladder on DPM but only 16/53/115/616 on Tomcat and only 53 on the fan-out fixture. The scale measurement is arm S, not arm S2, so it does not carry the native merge; and it times build + percentile evaluation, not a merge or a consolidation.

### Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
perl prototype/426-revalidate-v8-rebless.pl --bpd 53 --out prototype/426-results/v8-rebless \
    > prototype/426-results/v8-rebless/run-bpd53.txt 2>&1
for b in 16 32 53 80 115 256 616; do echo "=== bpd $b ==="; \
    perl prototype/426-accuracy-by-key-shape.pl $b; done \
    > prototype/426-results/accuracy-by-key-shape/dpm-ladder.txt 2>&1
LTL_FILE=logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt \
    perl prototype/426-accuracy-by-key-shape.pl 53 > prototype/426-results/accuracy-by-key-shape/tomcat-bpd53.txt
LTL_FILE=/tmp/ltl-426-fixtures/bin-twxdur-full.log \
    perl prototype/426-accuracy-by-key-shape.pl 53 > prototype/426-results/accuracy-by-key-shape/fanout-bpd53.txt
for b in 53 616; do echo "=== bpd $b ==="; \
    caffeinate -s perl prototype/426-message-stats-scale.pl $b /tmp/ltl-426-fixtures/bin-twxdur-full.log; done \
    > prototype/426-results/message-stats-scale/fanout.txt 2>&1
```

---

## Cross-aspect findings (consolidated)

### Status of the step-2 mandate

All five #189 aspects (V1, V2, V3, V4, V5) were taken through T, S and G and independently verified as confirmed; four further aspects (V6 display-geometry consumers, V7 the bucket-stats surface, V8 merge shapes, V9 the re-bless enumeration and the scale measurement) and two in-place addenda (the native span merge for S; the `-V` audit scope and the D8 field census) were added on 2026-08-25.

**S is digest-identical to T on every surface tested.** That is the load-bearing parity result, and it now covers far more than the percentile surface it started on: the 277 MB Tomcat file at bpd 53/616 (V1, V3, V5); the 2.6 MB file at 53/115/616 and under the cap (V4); the 67 MB fan-out file at 53/616 (V2); the DPM ScriptLog and the 148 MB Tomcat file at 53/616 (V9's N3 re-runs) and the 286,659-key fan-out fixture at both bpd; every V1/V3 hand-built scenario including the 0/−5 failure modes (30/30 canonical matches); all ten (file × bpd) configurations of the bucket-stats surface at bpd 16/32/53/115/616, where T and S additionally produce bit-identical accuracy figures independently of the digest (V7); all 90 rows of the display-finalize comparison, where T and S never differ in a single display cell on either geometry at any of the five streaming rungs (V6); every merge shape — rollup, maximally disjoint pairs, depth 1/3/7/15, order permutations — at both bpd on both fixtures (V8); and the native span merge S2, which is bit-identical to S and T across 155 assertions including element-for-element equality of the raw span arrays (V2 addendum). The single divergence anywhere is the deliberate aliasing probe, in which S2 equals S exactly and both differ from T on a state ltl does not reach. **P8+P9 inherit #189's validation on the percentile surface and #201's on the display surfaces by construction.**

Under **G** (P10) no locked decision is contradicted by the primitives' arithmetic; three become vacuous (D4, D5, R6) and one is met more strictly than today (R4's structural bound, now proved under every merge shape and to depth 15); two require an explicit amendment entry if P10 is locked (D4/D5's replacement; D8's field set — six inert fields, not five); one #189 report finding needs correcting regardless of P10 (V5 finding 1). V2 adds a third amendment candidate independent of the representation chosen: D2's memory-footprint *guidance* (~2.1 KB per partition, ~212 MB at 10⁵ keys) describes T's dense layout only and does not survive either span-only arm. What the 2026-08-25 aspects add to that picture is that G is **not** uniformly better: it is a large re-bless on the committed statistics-drift baselines (15.9–31.7% blocking cells at bpd 53), its accuracy advantage over T reverses across the tier ladder, S is *larger* than T on the bounded-cardinality bucket-stats surface, and the display-fidelity ranking flips by file, geometry and rung. The architect decides.

### Decisive evidence per locked decision and requirement

| Decision / requirement | under S (span-only, verbatim geometry) | under G (shared grid) | evidence |
|---|---|---|---|
| **F1** analyst's-lever framing (bpd is the query-time lever; `rank_in_bin`) | unchanged | unchanged — bpd is the one number G consumes; `rank_in_bin` used verbatim | V4 F4 (digests per tier); V5 § A |
| **D1** Prometheus in-bin walk, `ceil(q·N)` | unchanged (digest-identical) | holds unchanged: same value/audit semantics on every reachable edge case; same error envelope where no remap; same rank crossover at bpd ≈ 256 | V1 A1/A3/A4/A12; V5 § A–B |
| **D1A** `rank_in_bin` as fraction | unchanged | unchanged | V1 A12; V5 |
| **D1 guidance `lower = upper`** | vacuous (`partition_new` cannot produce it) | vacuous (impossible by construction) | V1 A2 |
| **D2** precision lever (bpd; per-surface tiers) | lever unchanged; `data_model_precision:` line has no store input. **Its memory guidance does not carry**: 955 B/key at 53 and 1,173 at 616 against T's 2,381 / 13,730; 91 MB (Devel) / 57 MB (RSS) at 10⁵ keys vs the 212 MB figure, and bpd sensitivity 1.23× vs T's 5.77× | lever unchanged; one grid per bpd; G digest changes with bpd. Memory guidance likewise: 600 / 817 B/key, 57 MB / 19 MB at 10⁵ keys, 1.36× across the tiers | V4 F4, `revalidate-v4-ltl-real-dmp{7,9}.txt`; V2 F1/F4, `revalidate-v2-{T,S,G}-bpd{53,616}.txt` |
| **D3** no per-bin guard | unchanged | holds: `bin_count=1` returns `upper`, no special-casing | V1 A1, A3 |
| **D4** overflow/underflow, `out_of_range_bounded` | unchanged: fires identically to T under the cap (p90..p99999=high; #189 V3 audit table reproduced). **But it is dead code in shipped ltl on T and S alike** — `counter_update` always extends, so `percentile` never takes its `low`/`high` exits from a streaming store; every ltl run captured (default sort, `-so p99`, `-o`) emits twelve `none`, and forcing the audit required the lib's `max_rebins` hook | **vacuous**: an index exists for every positive value (1e-320..1e308 accepted); counters identically 0; audit constant `none`; R4 `low`/`high` branches unreachable. G's `percentile` ends in `die "unreachable"` — proved structurally, not asserted | V1 A5–A7; V3 Part B/C; V4 scenario 5 + addendum findings 8/11, `n7-audit-census/oracle-*.out` |
| **D5** per-key seeded partition, HdrHistogram doubling, rebin telemetry | unchanged: 7 rebins / 4,153 keys, p99 0, max 1 reproduced; 6 rebins / 51,469 keys at fan-out, max 397 bins; 2 rebins / 286,659 keys (0.0007%), p99 0, no over/underflow at 5.6× the previously tested cardinality; rebin telemetry identical. Its *costs* are now measured across every merge shape: 100% of 725 pair merges remap both sides; the `-g` fold costs 3.28 s (@53) / 33.2 s (@616) on T and 5.87 / 60.5 s on S at 51,469 keys, 18.20 / 199.52 s (T) and 34.36 / 414.18 s (S) at 286,658 merges; the rollup 53.8–703.4 µs/merge on T. The **native span merge (S2)** removes the S penalty entirely — 3.65 / 16.12 s on the same fold, 4.9–13.1× faster than T on pairs — without changing a bit of the arithmetic. On the **display surfaces** the per-key seed shows as #201 Dimension B: 13 distinct range anchors across 24–25 time buckets | **vacuous**: no seed, no extend, no rebin; span telemetry replaces it (p50/p95/p99/max 1/26/78/175 @53, 1/294/907/2028 @616 on 4,153 keys; 1/1/44/210 and 1/1/503/2,436 on 51,469; 0 of 4,153 keys exceed T's seed; no growth cap needed; `span_p50/p95/p99/max` 4/103/129/149 on dpm-10k). No remap: the fold costs 0.093 / 0.117 s and the rollup 0.96–14.03 µs/merge. The doubling remap is the sole mechanism by which the R4 bound is exceeded (V5, V8) and by which T is insertion-order-dependent (V1, V3, V8). Against the per-bucket exact display at bpd 616 on Tomcat the global anchor is better (median 0.0667% / max 0.2333% against T's 0.2667% / 0.4583%); on DPM at 616 the arms are statistically identical | V3 Part A/B; V1 Part C, A10; V5 § A, D, E; V2 F5/F6 + addendum; V6 F2; V8 §§ 1–4; V9 F5 |
| **D7** opt-out | unchanged (`-mdm raw` builds no store) | unchanged | V4 F5; pre-existing drift: no `--exact-percentiles` / `opt_out_*` lines in today's emitter |
| **D8** `-V` section and field set | unchanged: byte-identical to real ltl (memory masked) at 53/115/616 and `-mdm raw`; `counter_memory_bytes` 2.4–4.8× smaller. The addendum reproduces ltl's **two distinct aggregation scopes** and matches every field exactly on the smallest fixture, and every field but `partition_count` (a prototype-parser difference, proved 1:1 against ltl's own MESSAGES CSV) and `counter_memory_bytes` on the larger two. Of the ten fields only four discriminate as parity assertions — `partition_count`, `total_rebin_events`, `max_partition_bins`, `rebins_per_partition` — all four exact for S | **six** fields inert, not five (`total_rebin_events`, `max_partition_bins`, `partitions_with_{over,under}flow_count`, `rebins_per_partition`, **and `out_of_range_bounded`**, which a harness needs as an entry rather than a footnote), plus `counter_memory_bytes` inert as an assertion on every arm — seven of ten un-diffable. Confirmed structurally: `Store::G` holds only `{row, key, bins}`. Names still parse; amendment entry required by D8's own rule if P10 locks. **A plain `-V` diff against ltl is a valid gate for S and is not one for G** | V4 F1–F3 + addendum findings 7–11, `revalidate-v4-diff.txt`, `n7-audit-census/field-census-dpm10k.out` |
| **R1** partition primitive, lazy per-key lifecycle | unchanged | replaced by a grid with no per-key partition object; a row exists only after its first add | V3; V1 A5 |
| **R2** bin assignment matches the locked boundary computation | unchanged | holds except exact powers of ten (1 of 985 values, 38 of 857,480 obs; one index low, value = closed bin's upper boundary, zero attribution error); convention to be recorded | V1 Part B, A8/A9 |
| **R2 "positive-only substrate"** (R4 note) | primitive undefined for v ≤ 0: infinite loop on negative, die on 0 | undefined: dies on both | V1 A11; V3 Part C |
| **R3** counter update, parameterised keying | unchanged (columns keyed by row) | unchanged (span keyed by row; index-wise) | V3 Part A; V4 |
| **R4** percentile primitive; structural accuracy bound | inherits T: bound holds per key at 53/115/616, fails 1 key at 256 (0.9336% > 0.9035%); fails after merges at every tier (1.35–2.06 bins). **The depth ladder now dates the failure**: a single maximally disjoint merge stays within one bin on 3,999 of 4,000 evaluations (worst 1.0008), while successive merges break it monotonically — 1.25 → 1.40 → 1.51 → **2.10** bins at depths 1/3/7/15 (bpd 53, DPM), with the breach *count* rising 48 → 66 → 78 → 98 of 1,000 and the **p95 itself** crossing one bin by depth 3. Raising bpd does not rescue it (2.06 bins at 616). A third breach site is the *unmerged* per-key scope on the 2025-05-07 Tomcat file at bpd 616: one key (N = 26,238, oracle P1 = 1001) at 0.3966% against a 0.3745% bound. On the **bucket-stats** surface the bound holds in 3,001 of 3,005 comparisons, the four exceptions being integer-quantisation artefacts | **met in every scope at every tier and every merge shape**: 100.00% within one bin per key, small-N, 1 and 7 merges (V5); 0 breaches in 16,000 depth + 4,000 disjoint + 20 rollup evaluations, every apparent ">1" being exactly 1.000000 with `_gt1eps = 0` (V8); 100% within one bin in every scope on the DPM and 2025-05-07 Tomcat surfaces at both bpd; on the same Tomcat P1 key G returns 1000.009 (0.0990%) against T's 997.03, 4× more accurate on exactly the case that breaks T | V5 § A–E; V8 §§ 2–3; V7 F1; V9 (N3) F4 |
| **R5** determinism | fixed-sequence: holds | fixed-sequence: holds; additionally order-independent and merge-commutative. Per key across file / reversed / shuffled orderings: G 0/200 against T's 105/200 (2025-05-05 Tomcat), 105/200 (2025-05-07 Tomcat) and 187/200 (DPM) — T is order-dependent on 52–94% of keys, always bounded below one bin. Under **set merges into a neutral target** (V8) T and S differ on 68–96% of groups with spread to **2.00 bins**, while G's spread is exactly 0.0000 in every cell, byte-identical canonical strings across all orderings, reproduced by an independent script | V1 Part C; V3 12-decade key; V8 § 4; V9 (N3) F3 |
| **R6** overflow/underflow counters | unchanged (contract confirmed under the cap; S parity) | vacuous — nothing to count | V1 A6/A7; V3 Part B |
| **R7** partition independence across consumers / keys | unchanged. The shipped merge's **adopt-by-reference** path (target empty → adopt the source's `partition` and `bins` refs) cannot be reproduced by any columnar row and is not: S and S2 copy the span. The divergence is observable only after adding to *both* keys post-adopt, a state ltl does not reach (it deletes the source counter slot immediately after the adopt) | the grid is shared, the counts are not: rows remain independent; merge = index-wise add without touching either source | V1 Part C merges; V5 [pair]; V2 addendum finding 10 |
| **R8** memory lifecycle (per-key freeable; reallocation on extend) | per-row columns; widening runs verbatim `partition_extend` through a dense view. **The advantage is surface-dependent, not universal**: at unbounded per-message cardinality S is 2.2× (bpd 53) / 12.7× (616) smaller than T at 286,659 keys, and the growth across the ladder is 1.008× against T's 5.6×; on the **bounded-cardinality bucket-stats surface** (29–62 rows) S is *larger* than T at bpd ≥ 115 — up to +67% RSS on Tomcat at 616. The native merge's transient buffer is sized to the destination span rather than `new_bin_count`, but was not measured | span grows by splice; no reallocation of a partition; memory for a given span is insertion-order-dependent (`0` vs `undef` fill, 3–4×) until the downward fill is `undef`. G is the smallest or joint-smallest arm in 6 of 8 bucket-stats cells, its advantage narrowing at high bpd; 712 / 720 B/key at 286,659 keys | V3 Part B, Surprise 2; V7 F4; V9 (c) |
| **R9** telemetry surface for `-V` | unchanged | rebin / overflow telemetry has nothing to report; `grid_bpd`, `grid_index_range`, `span_slots`, `counter_slots_total` rendered as the proposed replacement; the field census names the arm-native substitute per inert field (`span_max` for `max_partition_bins`; `span_p50/p95/p99/max` for `rebins_per_partition`; `grid_bpd` as the geometry disclosure `total_rebin_events` replaced) | V4 F2–F3 + addendum, `revalidate-v4-all.txt` 139–152, `n7-audit-census/field-census-dpm10k.out` |
| **R10** pre-migration coexistence | unchanged | unchanged (`-mdm raw` path identical from every arm) | V4 F5 |
| **R11** boundaries with other features | unchanged | unchanged | — |
| **R12** `partition_rebin` finalize wrapper (#201) | unchanged in code; it is the merge remap whose accuracy cost V5 and V8 measure and whose time cost V2 measures (89–754 µs/merge on T, 121–1,047 on S through dense views; `rebins` reset to 0 so merge-driven rebins are invisible to `-V`). **As the finalize step it is now exercised directly**: V6 runs it as the stream→finalize projection into both display geometries and S's finalized cells are identical to T's in all 90 rows, so P8+P9 carry R12's contract as well as its code. `_remap_span` (S2) reproduces the same projection over the occupied span only, bit-for-bit | not used by G's merge (index-wise add: 0.96–29 µs/merge across pairs, rollup and disjoint shapes); G's finalize places mass by value where T/S fold streamed over/underflow into the edge cells, with the fidelity ranking flipping by file, geometry and rung (V6). The **bucket-stats** surface calls `percentile` directly on the streaming partition and never invokes R12 at all | V5 § D–E; V2 F5/F7 + addendum; V6 Parts A–D; V7 method; V8 §§ 1–3 |

### Consolidated findings

**Finding A — S is digest-identical to T everywhere it was exercised; P8+P9 inherit #189's validation by construction.** Full-file digests equal at bpd 53 (`3962d9c2…`) and 616 (`8bb68875…`) on 4,153 keys (V1, V3, V5), at 53/115/616 and under the cap on the 635-key file (V4), at 53 and 616 on 51,469 keys (V2 parity), and in every V1/V3 hand-built scenario including `max_rebins=0` and the 0/−5 failure modes (30/30 canonical matches in V3 Part B). The `-V` section renders byte-identically to real ltl with `counter_memory_bytes` masked. The only S deltas are memory: Devel::Size 3.61 vs 9.99 MB (@53) and 8.38 vs 59.9 MB (@616) on the 277 MB file; 650,952 vs 1,598,689 B on the 635-key file.

**Finding B — The Decision 1 walk is grid-agnostic; no edge case or accuracy property of the formula changes under G.** 92/92 Part A scenarios pass at both bpd (V1); the same `bin_count=1` → `upper`, unreachable `fraction=0`, identical-value-spike behaviour; the same error envelope where T does not remap and the same `ceil` vs `int` crossover at bpd ≈ 256 (V5 § B: T +0.43/+0.85/+0.59 pts vs G +0.58/+1.00/+0.61 at 256; 1.87/1.72/1.30% vs 1.95/1.80/1.46% at 616).

**Finding C — The geometric-midpoint remap is the one mechanism by which today's primitives exceed the R4 bound, and G has no remap.** Per key: T fails on one N ≥ 100 key at bpd 256 (0.9336% vs 0.9035%; 143 counts of 1 ms moved into `[1.00300, 1.01207)` by `partition_extend`), a wide-range key reaches 1.38 bins at bpd 616 after three doublings (V1 A10). After merges: T needed a union remap on 73.1% of 1,258 pairs and 88.0% of 2,198 fold steps; worst error 1.35–1.48 bins after one merge, 1.36–2.06 after seven; within-one-bin down to 78.0% (bpd 256 P90) and decaying with depth. G: `binning_max` equals the bound to four decimals and within-one-bin is 100.00% in every scope at 53/115/256/616. #189 V5 finding 1 is corrected accordingly (327 of 328 at bpd 256).

**Finding D — Under G, Decisions 4 and 5 and requirement R6 are vacuous, not violated.** No positive value is out of range (indices −16,961 for 1e-320 and 16,324 for 1e308); counters identically 0; `out_of_range_bounded` constant `none`; no seed, no doubling, no rebin count. With T's cap inputs G answers exactly (1e6 at q=0.9 vs T's `boundary[B]` = 316.23 under the synthetic cap — 3.5 decades). The tunable-seed telemetry D5 asked for is replaced by span telemetry: p50/p95/p99/max 1/26/78/175 @53 and 1/294/907/2028 @616 on 4,153 keys, global range 5.7 decades, 0 keys above T's seed; Σ slots 2.4–2.7% of T's Σ `bin_count` (4.6–5.2% of T's actual array lengths).

**Finding E — G is insertion-order-independent and merge-commutative; T is neither.** Across file / reversed / shuffled orderings T's canonical string and percentiles differ on 105 of 200 keys (up to 0.87 bins @53, 0.985 @616) because the seed is the first sample; G differs on 0. `merge(a,b)` vs `merge(b,a)`: T identical on bins and boundaries, different on the `rebins` telemetry field for 2/200 pairs; G 0/200. On the 12-decade key T's q0.5 reads 98.85 / 100.10 / 100.01 by order, G's 100.189 in every order. #189 R5 (fixed-sequence determinism) holds for both.

**Finding F — The `v > 0` guard is load-bearing for every representation.** The verbatim `partition_extend` never terminates on a negative value (first sample or existing partition) and dies `Illegal division by zero` on 0 after 130 doublings; G dies immediately (`Can't take log of 0/-5`). Every ltl call site is gated `> 0` (`counter_update` at 10775/10889/11029/11143, histogram sites 11184–11207); the P8–P10 store's add path must carry the same guard. 1e-320 and 1e308 break T's geometry (`bin_count = Inf`, `p50 = NaN`) but not G's — unreachable from parsed durations.

**Finding G — G's closed-form index is one low at exact powers of ten; a convention must be recorded.** On 985 distinct integer-millisecond values the boundary-checked index disagrees with `floor(bpd × log10 v)` only for 1000 (38 of 857,480 observations), identically at bpd 53/115/256/616; 4 of 8 powers of ten and 3–5 of 8 exact grid boundaries in synthetic tests. In every case the value is the closed bin's upper boundary, so a percentile attributed to it returns the value exactly and the one-bin bound holds; in V5 it shows as a −0.04% spike error at bpd 53. T's own closed form has the same ULP property on its seeded boundaries. Choosing closed-form as-is or the boundary-checked form (~2 extra `**` per add) fixes the digest baseline.

**Finding H — Decision 8 survives S unchanged and carries five inert lines under G.** With `counter_memory_bytes` masked, S renders byte-identically to real ltl in scenarios 1/2/3/6; under G `total_rebin_events`, `max_partition_bins` (printed 0 via `// 0`), the two overflow/underflow counts, `rebins_per_partition` and the audit line are constants. A proposed replacement block (`grid_bpd`, `grid_index_range`, `span_slots`, `counter_slots_total`) was rendered (6,536 / 13,439 / 69,272 slots at bpd 53/115/616), not locked. Two of #189 V4's six scenarios (`-pbpd` forms) are unreachable since #293; the emitter has no `--exact-percentiles` or `opt_out_*` lines (pre-existing drift). `counter_memory_bytes` varies run-to-run in real ltl (1,522,959 / 1,482,319 / 1,482,319) — not a regression assertion in any arm.

**Finding I — Span-array memory depends on fill direction until the downward fill is `undef`.** The same 636-slot G span costs 6,995 / 12,851 / 21,347 B depending on insertion order (@616: 73,867 / 143,203 / 243,907); endpoints-only 1..1e9 @616 costs 45,371 B when 1 comes first and 178,379 B when 1e9 comes first. S's `_bump_offset_dense` has the same `(0) x $shift` splice. Digests and percentiles are unaffected; an implementation note for P9/P10, not a contract point.

**Finding J — Cost on the primary surface (V4, V3; medians of 3 with ranges).** Telemetry + audit + render over 635 keys × 12 quantiles: T 0.1805 s / S 0.0225 / G 0.0190 at bpd 53; 1.9239 / 0.0826 / 0.0694 at 616 (T's `percentile` sums the dense array per call). Build of the 277 MB file: T 5.644 / S 5.388 / G 5.180 s at 53, dominated by parsing. Store RSS delta on the 277 MB file: T 11.45 / S 6.45 / G 3.80 MB at 53; 65.58 / 11.22 / 8.58 MB at 616. At fan-out cardinality (V2, 51,469 keys) T reproduces #189 V2's own numbers: 51,469 partitions, 116.86 MB, 2,381 B/partition, 6 rebin events, max 397 bins, and 1.29 s parse + 0.500 s store fill against #189's 1.63 s parse-included figure. Finding K carries the per-arm comparison.

**Finding K — At fan-out cardinality the span-only arms cost a fraction of T's memory and percentile time, but only G is cheaper on merge and fold (V2, 51,469 keys, medians of 3).** Memory per key, Devel::Size / RSS delta: T 2,381 / 2,428 B at bpd 53 and 13,730 / 15,761 at 616; S 955 / 598 and 1,173 / 833; G 600 / 198 and 817 / 452 — projecting to 10⁵ keys at 227.1 / 231.5 MB (T; +12.3% over #187 D2's ~212 MB, exactly #189 V2's figure), 91.1 / 57.0 MB (S) and 57.2 / 18.9 MB (G) at 53, and 1,309 / 1,503, 111.9 / 79.4, 77.9 / 43.1 MB at 616. The bpd sensitivity is T's dense array, not the data: T grows 5.77× from 53 to 616 because a single-sample key allocates to the seed centre (133 / 1,540 NULL-but-one slots, mean 133.64 / 1,547.42), while the occupied span p50 is 1 at both bpd and S grows 1.23×, G 1.36×. Fill: 1,471 / 1,623 ns/sample (T), 1,026 / 1,065 (S), 635 / 619 (G). Percentile pass over 360,283 evaluations: 20.73 / 208.70 µs/eval (T — the walk over the full `bin_count`, 78 / 68 ns per slot), 2.64 / 3.53 (S), 2.19 / 2.84 (G); S's values are digest-identical to T's. Merge and fold invert the ranking for S: on 725 consecutive pairs S is 1.36× / 1.39× slower than T (121.07 vs 89.17 µs, 1,047 vs 754) and on the 51,468-merge `-g` fold 1.79× / 1.82× slower (5.87 s vs 3.28, 60.5 s vs 33.2) — not the span representation but the harness, since `Store::S::merge` materialises a dense view of both rows, runs the verbatim `merge_bin_counter_entries`, then rescans and copies the span back, on an accumulator that is the target of every merge (the extra ~530 µs at 616 accounts as 3,328 view + 6,174 scan + 3,328 copy at ~41 ns/slot). A native span-array merge is O(occupied span), which is the shape G's merge already has: 5.81 / 29.23 µs on the pairs and 1.80 / 2.27 µs on the fold, making the fold 0.43× / 0.55× of G's own fill where it is 6.6× / 60× of T's and 17× / 167× of S's. All three arms conserve N = 339,832 and T = S on the fill, percentile, merge and fold digests; T and G disagree on the folded accumulator's quantiles by at most 0.61 bins after 51,468 merges. Under T/S every one of the 725 pairs needs a remap of both sides at both bpd (100.0%; G 0.0%), and the fold's own re-geometry of the accumulator (265 → 531 bins; 3,080 → 6,174) reports `fold_rebins=0` because `partition_rebin` resets the field — merge-driven rebins are invisible to `-V` rebin telemetry even on T.

**Finding L — S is display-cell-identical to T on both display geometries, at every resolution and every time bucket.** 90 rows (two canonical files × three geometries × the five streaming rungs the display surfaces resolve to × three arms): T and S never differ in a single finalized cell, mass retention is `1.000000` and peak X-offset is `0` for every arm. P8+P9 inherit #201's validation the same way Finding A shows they inherit #189's. On the heatmap's real per-time-bucket keying T and S seed 13 distinct range anchors across 24–25 buckets — #201 Dimension B — where G is globally anchored; at the shipping resolution (616) on the 148 MB Tomcat file that is worth median 0.0667% / max 0.2333% against T's 0.2667% / 0.4583%, while on DPM at 616 the arms are statistically identical (median 0.2800% each). Aggregate display fidelity has **no general winner**: T/S is ahead on DPM's heatmap at 53/115/256, G on DPM's histogram at 80 and on 7 of 10 Tomcat cells including 0.4988% against 8.6770% (histogram, 115) and 0.0003% against 0.0740% (histogram, 616). The large coarse-resolution deviations (33% at DPM bpd 80) are a **boundary straddle both arms share**: the source bin holding the value `2` — 19,926 observations, 16.2% of the file — has its geometric midpoint at 2.013, just across a display-cell boundary, so its whole mass lands one cell over in T and G alike (both cell 3 at bpd 80; both cell 2 at 616). An independent rediscovery of why #201 locked the display surfaces' streaming bpd at 616.

**Finding M — the bucket-stats surface inverts S's memory result and confirms its accuracy result.** On the fourth `%TIER_BPD` surface (`[16, 32, 53, 53, 53, 115, 616, 616, 616]`, keyed by time bucket, `percentile` read directly off the streaming partition with no `partition_rebin` on the path), S is digest-identical to T in all ten (file × bpd) configurations *and* produces bit-identical accuracy figures independently of the digest — but it is **larger** than T at bpd ≥ 115 (up to +67% RSS on Tomcat at 616, +36% on DPM), because its saving is per-row column overhead amortised across many rows and this surface has 29–62 rows. All three arms sit inside one bin width essentially always (4 of 3,005 comparisons outside, all T/S integer-quantisation artefacts), with maximum error tracking the bin width at every rung. The ladder is O(`bin_count`): at bpd 616 T walks ~18× more bins than are occupied (mean allocated 4,569.4 against mean occupied 257.7 on DPM), so S halves T's ladder cost and G takes a further 10–14% — by walking a shorter array, not by different arithmetic. At tier 5 (bpd 53) the whole ladder costs 9–23 ms; the walk only becomes visible at tier 7+ where T reaches 0.11–0.28 s.

**Finding N — the `[min,max]` clamp is load-bearing on the bucket-stats surface, and every arm needs it.** It fires on ~12% of (bucket, quantile) pairs on DPM and up to 44% on Tomcat; removing it would break #224's Layer-2 invariant at scale. Its excursions are bounded by one bin width in **all three arms at every bpd** (worst 1.046× against a 1.044× bin width at bpd 53), so it is a precision correction, not a defect repair, and its cost scales down with bpd. The T-vs-G difference is directional, not overall: G eliminates Tomcat's low clamps entirely (0.00% against T/S's 28–32%) because Tomcat's observed min is exactly `1`, which sits on a grid boundary; G *adds* low clamps on DPM (5.28% against 2.79% at bpd 53) because DPM's min of `2` does not (`grid_lower(grid_index(2)) = 1.91875`). High clamps are essentially identical across the arms.

**Finding O — the native span merge removes S's only cost regression against T, and the fold's scaling shape is the proof.** Arm S2 overrides `merge` alone and is bit-identical to S and T across 155 assertions — 20 hand-built edge cases at two bpd, 725 DPM pair merges, a 3,418-merge DPM fold, 5,000 and 49,842 fan-out merges, 5,000 pairs on the full 286,659-key fixture — plus element-for-element equality of the raw span arrays. On the 286,658-merge fold it is **5.0× faster than T and 9.4× than S at bpd 53** (3.65 s against 18.20 / 34.36) and **12.4× / 25.7× at 616** (16.12 s against 199.52 / 414.18); on pair merges 4.9× / 13.1× against T. Fold cost from bpd 53 to 616 grows ×10.96 (T), ×12.05 (S) and **×4.42** (S2): T and S track `bin_count`, S2 tracks the occupied span. V2 finding 2's condition — "P9's merge must be written natively before S's merge/fold numbers mean anything" — is discharged, and **the only recorded cost reason to prefer T over S is gone**. The shipped merge rebins *both* sides into a union geometry, not "extend the narrower side" as #287 R2.3's prose says; S2 is built against the shipped mechanism, which is why it reaches bit-identical digests.

**Finding P — the R4 breach is a merge-DEPTH effect, and the depth ladder dates it.** A *single* merge of two maximally disjoint keys (gaps to 4.84 decades, union geometry to 6,068 bins) stays within one bin on 3,999 of 4,000 evaluations, worst 1.0008. It is *successive* merges that break the bound: T's worst error rises monotonically with depth in all four cells — 1.2502 → 1.4046 → 1.5125 → **2.1026** bins at depths 1/3/7/15 (bpd 53, DPM), breach count 48 → 66 → 78 → 98 of 1,000, and the **p95 itself** crossing one bin by depth 3. Raising bpd does not rescue it (2.06 bins at 616), because the error is proportional to bin count, not bin width. Each remap re-projects already-remapped counts by geometric midpoint and the displacement compounds. G: **0 breaches in 16,000 depth + 4,000 disjoint + 20 rollup evaluations**, every apparent ">1" being exactly 1.000000 (`_gt1eps = 0`) — the bound is attained at bin boundaries and never exceeded, structurally, because no count is ever re-projected.

**Finding Q — T's order dependence is larger under set merges than Finding E measured, and G's is still exactly zero.** Merging the same 8-key set into a *neutral* target in four orders, T and S land on different state on **68–96% of groups** (against Finding E's 105/200 = 52.5% on pairwise/fold shapes) with per-quantile spread to **2.00 bins** (against 0.99), and an independent script finds T and S reaching 3–4 distinct canonical states from four samples of a group's 40,320 possible orderings. G's spread is 0.0000 in every cell. Finding E's spread figure was a lower bound for the shapes it tested. On a third and fourth surface the per-key ordering result reproduces: T order-dependent on 187/200 keys (DPM) and 105/200 (2025-05-07 Tomcat), G on 0/200 everywhere.

**Finding R — a shared grid on the message-stats surface is a large re-bless, and the T3 classification does not say which way the cells moved.** Against the committed `tests/statistics-drift` baselines at bpd 53, per-key percentile cells classify T3 (> 1%, blocking) on **21.82% (apache), 15.88% (tomcat and tomcat-heatmap-bin) and 31.67% (thingworx)**, worst deviations 3.89–4.52%, concentrated at p10–p95 and zero at p999/p9999. Direction is mixed and must be read separately: on tomcat G is further on 21.03% of cells and closer on 5.64%; on thingworx 32.36% further and 23.82% closer. `codebeamer-bin-data-model` is **NOT COVERED** — the prototype's verbatim parsers do not read that log's bracketed `[293ms]` duration, which ltl reads through the format registry; that is a prototype limitation, not an ltl finding.

**Finding S — the T-vs-G accuracy difference is resolution-dependent and reverses across the tier ladder; at the cardinality #426 exists for it is moot.** Decomposed by key shape (observation count × spread in decades), at **bpd 16 G is better on both files** and by a wide margin on wide-spread keys (DPM `N<1000 / spread>=1dec`: 3.5972% against T's 6.7845%); at **bpd 53** the two are mixed on DPM and T is ahead on Tomcat; **from bpd 115 up T is ahead on Tomcat** and stays ahead at 616 (0.0210% against 0.2385% on its most populous band). Both arms are sub-1% on every band at 616 on both files. Mechanism: T's per-key seed makes its bins adaptive to that key's data, an advantage that *grows* with resolution; G never wastes resolution on a seeded range the key does not occupy, which dominates when bins are *scarce*. At the 287k-key fan-out the question is nearly moot — **573,026 of 573,318 cells are exact for both arms**, the population being dominated by single-observation keys — and of the 292 non-degenerate cells G is closer on every band. The trade lives entirely in the moderate-cardinality, multi-observation population.

**Finding T — the container change's effect on the cardinality constraint, measured at the motivating scale rather than projected, grows with resolution.** All three arms built over the real message-stats keying at 286,659 distinct keys / 288,025 observations, timing what the statistics pass does (build once, then evaluate percentiles across every key), medians of 3: at bpd 53 T 1.518 s build / 17.634 s percentiles / 662.3 MB against S 1.233 / **2.112** / **291.7** and G 0.697 / 1.616 / 194.7; at bpd 616 T 2.966 / **181.348** / **3,722.4** against S 1.294 / **2.281** / **293.9** and G 0.738 / 1.731 / 196.9. S is **8.4× on percentile evaluation and 2.2× on memory at bpd 53, and 79.5× and 12.7× at 616**. The load-bearing half is the growth shape: **across the ladder T grows 10.3× in time and 5.6× in memory; S grows 1.08× and 1.008×.** Today's dense seeded array is sized by the partition, not by the data, so per-message resolution is expensive for reasons that have nothing to do with the statistics; a span-only container removes that coupling almost entirely. This is evidence about what the per-message row could afford — **not** a proposal to change `%TIER_BPD`, which is locked.

**Finding U — the memory measure itself has two failure modes, and both were hit.** (a) At 51,469 keys the span-only arms' RSS delta read *below* their own `Devel::Size` (S −357 B/key, G −402) because their stores fit inside memory the interpreter had already mapped; at 286,659 keys the gap is firmly positive for every arm (T +532, S +328, G +248). The consequence is counter-intuitive: the **`Devel::Size` projections from 51,469 keys held at fan-out (−12% to +19%) while the RSS projections failed badly (+68% to +385%)**. Both rules survive together only stated precisely — RSS is the measure of record, but only measured at the scale being claimed, one arm per process, never projected from a smaller store. (b) A multi-arm process cannot yield valid per-arm RSS: in one process building all three arms S reads 262.7 MB and G 139.3 MB against 382.8 MB and 263.9 MB in their own processes, an error up to 47%. Separately, RSS exceeds `Devel::Size` on every arm, surface and bpd measured, by 12.6–40.6%, and the gap fraction is **largest where the store is smallest** (Tomcat bpd 53: S 40.6%, G 39.3%; fan-out bpd 53: T 18.4%) — so `Devel::Size` understates a compact store's real footprint more than a large one's, which cuts *against* the compact arms and is why both columns are reported side by side. G's advantage over T at bpd 53 fan-out is 3.32× by `Devel::Size` and 3.02× by RSS.

**Finding V — the power-of-ten index offset is a property of the value 1000, not of any dataset.** Finding G's single real-data offender reproduces on all three surfaces at all four check-bpd despite 719–5,997 distinct values each: Tomcat 2025-05-05 `1000` ×38, DPM `1000` ×38, Tomcat 2025-05-07 `1000` ×17, in every case closed form 158 → boundary-checked 159 at bpd 53. The bound `10^(i/bpd) ≤ v < 10^((i+1)/bpd)` holds on every distinct value on every surface after the single correcting step. The spike's *frequency* varies with how often 1000 occurs; never with the number of values. G never allocates more slots than T on any key of any surface, but the size of that win is a data-shape property spanning 35× — Σ G span / Σ T `bin_count` at bpd 53 is 0.0039 (fan-out, span p50 = 1), 0.0286 (Tomcat 2025-05-07) and 0.1395 (DPM, span p50 = 17). Quoting a single "G is N× smaller" figure from one file is not safe.

### Proposed amendments (NOT locked — for the architect)

Each row is grounded in a captured aspect; none takes effect until the architect records it as a `Dxx` in the #426 record and, where a #187 decision changes, as an amendment entry there. Rows marked *P10 only* are moot if P10 is not adopted.

| # | decision | proposed text | grounding |
|---|---|---|---|
| A1 | #187 D5 (per-key seeded partition, HdrHistogram doubling) — *P10 only* | For F1 consumers the partition lifecycle is replaced by one log-spaced grid per store (`index = floor(bpd × log10 v)`), per-key storage over the occupied span; no seed, no extension, no remap; the `-V` tuning surface is the span distribution, not rebin counts. | **Strengthened.** V3 F2/F4/F7; V1 Part C; V5 F2/F4 (remap is the sole bound-breaker; G order-independent; 0/4,153 keys above the seed) — now also V8 (0 breaches under every merge shape; T order-dependent on 68–96% of set merges), V9 (N3) F5 (2 rebins / 286,659 keys, so T's seeding heuristic itself is healthy at 5.6× the previously tested cardinality — the amendment's case is the remap's *consequences*, not seed failure) and V6 F2 (13 distinct anchors per 24–25 time buckets on the display surfaces). **Weakened on one axis**: V9 finding 3 shows T's per-key seed is an accuracy *advantage* at bpd ≥ 115 on Tomcat, so "no seed" is not a free improvement at high resolution |
| A2 | #187 D4 (overflow/underflow, `out_of_range_bounded`) — *P10 only* | The shared grid has no out-of-range state: every positive value has an index; the overflow/underflow counters and the `low`/`high` audit branches do not exist for F1 consumers; `out_of_range_bounded` is either dropped or documented as constant `none`. | **Re-grounded and broadened.** V1 A5–A7; V3 Part B/C; V4 scenario 5 — the V4 addendum adds that the branches are already dead code in shipped ltl on **T and S** (every captured run emits twelve `none`; forcing the audit required the lib's `max_rebins` hook), so this is a documentation change for today's tool as much as a P10 amendment. `Store::G`'s `percentile` ends in `die "unreachable"`, proving the absence structurally |
| A3 | #187 D8 field set — *P10 only* | Replace `total_rebin_events`, `max_partition_bins`, `partitions_with_overflow_count`, `partitions_with_underflow_count`, `rebins_per_partition` **and `out_of_range_bounded`** with `grid_bpd`, `grid_index_range: lo..hi`, `span_slots: p50= p95= p99= max=`, `counter_slots_total`; keep `path`, `partition_keying`, `partition_count`, `counter_memory_bytes`, `percentiles_emitted`. `percentiles_emitted` must be reproduced as the **static** per-consumer table, not the demand-narrowed ladder. | **Corrected from five fields to six.** V4 F2/F3 (rendered block, `revalidate-v4-all.txt` 139–152) + addendum findings 9/10/11 — `out_of_range_bounded` is the sixth field a G-arm diff flags and needs an entry, not a footnote; the field census (`n7-audit-census/field-census-dpm10k.out`) names the arm-native substitute per inert field and confirms `counter_memory_bytes` is un-assertable on all three arms |
| A4 | #187 R4 accuracy contract wording — regardless of P10 | State that the structural bound holds per partition only while no remap has occurred; a widening (D5) or a merge (R12 `partition_rebin`) may exceed it. **The excess is a function of merge depth**: one merge stays within one bin on 3,999 of 4,000 evaluations even between maximally disjoint keys (worst 1.0008), while successive merges rise monotonically to ~2.1 bins by depth 15, with the p95 itself crossing one bin by depth 3. Raising bpd does not help. Under P10 the sentence "structural, derived from geometry" holds without exception. | **Now has direct depth-ladder evidence.** V5 F2/F4, § D–E; V1 A10 — and V8 § 3 (200 groups × 16 keys, depths 1/3/7/15, two fixtures, two bpd: T max 1.2502 → 1.4046 → 1.5125 → 2.1026 bins and breach count 48 → 66 → 78 → 98 of 1,000 at bpd 53 on DPM; 1.4860 → 2.0637 at 616; G 0 breaches in 16,000 evaluations with max exactly 1.000000). V8 § 2 separately rules out disjointness as the mechanism. V9 (N3) F4 adds a third breach site on an *unmerged* per-key scope (2025-05-07 Tomcat, bpd 616, one key at 0.3966% against a 0.3745% bound) |
| A5 | #189 V5 finding 1 (report correction) — regardless of P10 | "Within the bound across all 4,153 partitions × 7 quantiles × 4 precision levels" → within the bound for 327 of 328 N ≥ 100 keys at bpd 256 (0.93% vs 0.90%, one widening remap); all other tiers as stated. | V5 F3, `revalidate-v5-key-bpd256.tsv` ordinal 75 |
| A6 | #189 R4 note "positive-only substrate" / R2 guidance — regardless of P10 | The primitives are undefined for v ≤ 0 (T/S: infinite loop on negative, die on 0; G: die on both); the caller-side `> 0` guard is part of the contract and must precede every `add` in the P8–P10 store. | V1 A11; V3 Part C |
| A7 | #189 R2 guidance — G index convention — *P10 only* | Record whether the grid index is the closed form `floor(bpd × log10 v)` (one low at exact powers of ten; zero attribution error) or the boundary-checked form; the bin-mode digest baseline is defined by that choice. | V1 Part B, A8/A9; V5 probe 1 |
| A8 | #189 R8 / #426 P9 implementation note — S and G | Downward span growth extends with `undef`, not `0`, so a span's memory is insertion-order-independent. | V3 Surprise 2 / F6 |
| A9 | #187 D1 implementation guidance — regardless of P10 | Mark the `lower = upper` case as unreachable on both geometries (no code path needs it). | V1 A2 |
| A10 | #187 D7/D8 text vs shipped emitter — regardless of #426 | Record the pre-existing drift: no `--exact-percentiles` / `-ep` flag, no `opt_out_active` / `opt_out_notice` lines in today's `emit_bin_counter_mode_verbose`; the opt-out is `-mdm raw` and surfaces as `path: user_opt_out`. | V4 F5, `revalidate-v4-ltl-real-raw.txt` |
| A11 | #187 D2 memory-footprint guidance (~2.1 KB per partition, ~212 MB at 10⁵ keys) and #189 V2 finding 4's +11–12% Perl-overhead note — if P9 or P10 is adopted | Both describe T's dense per-key array only. Replace the "(B+2) counters × 8 bytes" model with a span-based one — per-key fixed overhead + 8 B × occupied span — and state that the footprint's bpd sensitivity is a property of the dense layout (T 5.77× from bpd 53 to 616) rather than of the precision lever (S 1.23×, G 1.36×). | V2 F1/F4 (reproduced T at 227.1 MB / +12.3%; S 91 MB Devel / 57 MB RSS; G 57 / 19 MB at 10⁵ keys, bpd 53), `revalidate-v2-{T,S,G}-bpd{53,616}.txt` |

### What the evidence does not cover yet — in scope, next to prototype

Every item below is part of the step-2 mandate, not outside it (architect, 2026-08-24). The ordered plan for closing them (N1–N8: display-geometry-bound consumers under S/G first, then the native span merge for S, a second log surface, real ltl end-to-end under G, further merge shapes, ≥ 10⁵-key fan-out, `-V` audit scope, memory measure) and the resumption notes are in `features/426-per-message-statistics-store.md` § *Not yet covered — IN SCOPE*. This section shrinks as each lands.

**Re-framed 2026-08-25.** The architect locked the objective as *replace the container, and measure what the container change does to the cardinality constraint that holds the per-message surface at a coarser resolution than heatmap and histogram* — evidence handed to him, never a proposal to change the locked `%TIER_BPD` table, and with the display surfaces' settings, geometry and rendering out of question. The work is **not scheduled**. N1 as written above was drafted while the heatmap/histogram counter stores were wrongly believed out of scope; its build is re-derived from the surface-and-decision audit mandated in the feature doc § *Do this first, next session* before any code is written.

- **A native span-array merge for P9.** S's merge and fold numbers (V2) are the cost of running the verbatim `merge_bin_counter_entries` through dense views of both rows; the mechanism is accounted for slot-by-slot, but no native O(occupied span) merge over S's span array was written or measured. Until it is, P9's merge and fold cost is unknown — the fill, memory and percentile numbers are the ones that stand, and the 3–60 s folds measured on T/S are what the D5 remap costs, not what P9 must cost.
- **Fan-out beyond 51,469 keys.** V2's projections to 10⁵ keys are per-key figures × 10⁵ on a store of 51,469; no store of that size was built, and the projection assumes the per-key cost is flat in cardinality.
- **Merge shapes other than consecutive-key pairs and the `-g` fold.** V2 measures 725 disjoint pairs of adjacent keys and one 51,468-merge accumulation; the time-bucket and global rollups, and merges between keys with disjoint value ranges, were not timed.
- **Display-geometry-bound consumers (F2 heatmap, F3 histogram; D5's F2/F3 contract; R12 as a finalize re-bin).** Every aspect keys by `(category, log_key)`; the time-bucket and global partitions, and `partition_rebin` as a render-time projection, were not exercised under G.
- **A second log surface for V1/V3/V5.** All three run on the 2025-05-05 Tomcat file (integer milliseconds); the DPM ScriptLog (the #426 V8 fixture) was not re-run through these aspects, so the power-of-ten spike behaviour (V5 § F) is characterised on one data shape.
- **Real ltl end-to-end under G.** V4 renders the section from the prototype's arms; no `ltl` build carries the grid, so byte-level baselines (`tests/validate-*.sh`) for bin mode under P10 were not produced. The percentile shift the architect would re-bless is bounded by the tables in V5 but not enumerated per baseline.
- **Timing on the parse-dominated build path.** V3's build medians differ by < 10% between arms and include parsing; the per-line cost of the store alone is V2's measurement.
- **The `-V` audit aggregation scope.** The prototype aggregates `out_of_range_bounded` over every key; ltl aggregates only the keys its statistics pass walks. Identical on the fixtures used (all `none`); not shown to be identical where the audit fires.
- **Devel::Size as a memory measure.** `counter_memory_bytes` is seed-dependent for hash-backed stores (V4 Surprise 1), S column bytes moved 128 B on re-run (V3 verifier), and S/G Devel::Size grows ~58 KB after one percentile walk (V4 verifier). RSS deltas per arm-process are the memory numbers of record.

### Reproduction recipe (full revalidation suite)

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store

# V1 (edge cases, R2 cross-check, determinism)
perl prototype/426-revalidate-v1.pl --part A > prototype/426-results/revalidate-v1-partA.txt 2>&1
/usr/bin/time -l perl prototype/426-revalidate-v1.pl --part BC \
    --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
    > prototype/426-results/revalidate-v1-partBC-2025-05-05.txt \
    2> prototype/426-results/revalidate-v1-partBC-2025-05-05.time.txt

# V2 (fan-out at scale: memory, fill, percentile, merge pairs, -g fold) — one arm per process
F2=logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-0.2026-01-14.txt
prototype/426-revalidate-v2.sh --file $F2 --bpds "53 616" --arms "T S G" --runs 3
# or, as the captures were actually produced, one process at a time:
for bpd in 53 616; do for arm in T S; do
  caffeinate -s perl prototype/426-revalidate-v2.pl --file $F2 --arm $arm --bpd $bpd --parity-only \
    > prototype/426-results/revalidate-v2-parity-$arm-bpd$bpd.txt 2>&1
done; done
for bpd in 53 616; do for arm in T S G; do
  caffeinate -s perl prototype/426-revalidate-v2.pl --file $F2 --arm $arm --bpd $bpd --runs 3 \
    > prototype/426-results/revalidate-v2-$arm-bpd$bpd.txt 2>&1
done; done
# revalidate-v2.tsv and revalidate-v2-postcheck.txt: the driver's step-2/step-3 logic over those six captures

# V3 (seeding, span growth, overflow/underflow audit, non-positive inputs) — ~4 min
caffeinate -s bash prototype/426-revalidate-v3.sh > prototype/426-results/revalidate-v3-driver.txt 2>&1

# V4 (-V section from each arm vs real ltl; timing per arm)
bash prototype/426-revalidate-v4.sh
bash prototype/426-revalidate-v4-memvar.sh > prototype/426-results/revalidate-v4-ltl-real-memvar.txt

# V5 (accuracy vs oracle at four tiers; exit 1 expected — bpd 256 T key-scope FAIL)
sh prototype/426-revalidate-v5-run.sh
perl prototype/426-revalidate-v5-tables.pl prototype/426-results/revalidate-v5 > prototype/426-results/revalidate-v5-tables.txt
perl prototype/426-revalidate-v5-probe.pl --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
    --bpd 256 --ordinal 75 --q 0.75 > prototype/426-results/revalidate-v5-probe.txt
```

Every script prints usage with `--help`; every driver exits non-zero on a T↔S digest divergence.
