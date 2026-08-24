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

The primary surface is the one #189 used: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (277 MB, 1,430,678 lines, 857,480 positive durations, 573,198 zeros excluded, 4,153 keys, 328 with N ≥ 100). V4 uses the 2.6 MB iteration file (635 keys); V2's fan-out file is the 67 MB 2026-01-14 log (51,469 keys).

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

## Cross-aspect findings (consolidated)

### Status of the step-2 mandate

All five #189 aspects (V1, V2, V3, V4, V5) were taken through T, S and G and independently verified as confirmed. Under **S** (P8+P9) every locked decision and requirement holds verbatim: S is digest-identical to T on every fixture and scenario exercised (Tomcat 277 MB at bpd 53/616; 2.6 MB at 53/115/616 and under the cap; the fan-out file at 53/616; every V1/V3 hand-built scenario including the 0/−5 failure modes), so #189's validation carries over by construction. Under **G** (P10) no locked decision is contradicted by the primitives' arithmetic; three become vacuous (D4, D5, R6) and one is met more strictly than today (R4's structural bound); two require an explicit amendment entry if P10 is locked (D4/D5's replacement; D8's field set); one #189 report finding needs correcting regardless of P10 (V5 finding 1). V2 adds a third amendment candidate that is independent of which representation is chosen: D2's memory-footprint *guidance* (~2.1 KB per partition, ~212 MB at 10⁵ keys) describes T's dense layout only and does not survive either span-only arm. The architect decides.

### Decisive evidence per locked decision and requirement

| Decision / requirement | under S (span-only, verbatim geometry) | under G (shared grid) | evidence |
|---|---|---|---|
| **F1** analyst's-lever framing (bpd is the query-time lever; `rank_in_bin`) | unchanged | unchanged — bpd is the one number G consumes; `rank_in_bin` used verbatim | V4 F4 (digests per tier); V5 § A |
| **D1** Prometheus in-bin walk, `ceil(q·N)` | unchanged (digest-identical) | holds unchanged: same value/audit semantics on every reachable edge case; same error envelope where no remap; same rank crossover at bpd ≈ 256 | V1 A1/A3/A4/A12; V5 § A–B |
| **D1A** `rank_in_bin` as fraction | unchanged | unchanged | V1 A12; V5 |
| **D1 guidance `lower = upper`** | vacuous (`partition_new` cannot produce it) | vacuous (impossible by construction) | V1 A2 |
| **D2** precision lever (bpd; per-surface tiers) | lever unchanged; `data_model_precision:` line has no store input. **Its memory guidance does not carry**: 955 B/key at 53 and 1,173 at 616 against T's 2,381 / 13,730; 91 MB (Devel) / 57 MB (RSS) at 10⁵ keys vs the 212 MB figure, and bpd sensitivity 1.23× vs T's 5.77× | lever unchanged; one grid per bpd; G digest changes with bpd. Memory guidance likewise: 600 / 817 B/key, 57 MB / 19 MB at 10⁵ keys, 1.36× across the tiers | V4 F4, `revalidate-v4-ltl-real-dmp{7,9}.txt`; V2 F1/F4, `revalidate-v2-{T,S,G}-bpd{53,616}.txt` |
| **D3** no per-bin guard | unchanged | holds: `bin_count=1` returns `upper`, no special-casing | V1 A1, A3 |
| **D4** overflow/underflow, `out_of_range_bounded` | unchanged: fires identically to T under the cap (p90..p99999=high; #189 V3 audit table reproduced) | **vacuous**: an index exists for every positive value (1e-320..1e308 accepted); counters identically 0; audit constant `none`; R4 `low`/`high` branches unreachable | V1 A5–A7; V3 Part B/C; V4 scenario 5 |
| **D5** per-key seeded partition, HdrHistogram doubling, rebin telemetry | unchanged: 7 rebins / 4,153 keys, p99 0, max 1 reproduced; 6 rebins / 51,469 keys at fan-out, max 397 bins; rebin telemetry identical. Its *costs* are now measured: 100% of 725 pair merges remap both sides, and the `-g` fold costs 3.28 s (@53) / 33.2 s (@616) on T and 5.87 / 60.5 s on S | **vacuous**: no seed, no extend, no rebin; span telemetry replaces it (p50/p95/p99/max 1/26/78/175 @53, 1/294/907/2028 @616 on 4,153 keys; 1/1/44/210 and 1/1/503/2,436 on 51,469; 0 of 4,153 keys exceed T's seed; no growth cap needed). No remap: the same fold costs 0.093 / 0.117 s. The doubling remap is the sole mechanism by which the R4 bound is exceeded (V5) and by which T is insertion-order-dependent (V1, V3) | V3 Part A/B; V1 Part C, A10; V5 § A, D, E; V2 F5/F6, `revalidate-v2.tsv` |
| **D7** opt-out | unchanged (`-mdm raw` builds no store) | unchanged | V4 F5; pre-existing drift: no `--exact-percentiles` / `opt_out_*` lines in today's emitter |
| **D8** `-V` section and field set | unchanged: byte-identical to real ltl (memory masked) at 53/115/616 and `-mdm raw`; `counter_memory_bytes` 2.4–4.8× smaller | five fields inert (`total_rebin_events`, `max_partition_bins`, `partitions_with_{over,under}flow_count`, `rebins_per_partition`) + audit constant; names still parse; amendment entry required by D8's own rule if P10 locks | V4 F1–F3, `revalidate-v4-diff.txt` |
| **R1** partition primitive, lazy per-key lifecycle | unchanged | replaced by a grid with no per-key partition object; a row exists only after its first add | V3; V1 A5 |
| **R2** bin assignment matches the locked boundary computation | unchanged | holds except exact powers of ten (1 of 985 values, 38 of 857,480 obs; one index low, value = closed bin's upper boundary, zero attribution error); convention to be recorded | V1 Part B, A8/A9 |
| **R2 "positive-only substrate"** (R4 note) | primitive undefined for v ≤ 0: infinite loop on negative, die on 0 | undefined: dies on both | V1 A11; V3 Part C |
| **R3** counter update, parameterised keying | unchanged (columns keyed by row) | unchanged (span keyed by row; index-wise) | V3 Part A; V4 |
| **R4** percentile primitive; structural accuracy bound | inherits T: bound holds per key at 53/115/616, fails 1 key at 256 (0.9336% > 0.9035%); fails after merges at every tier (1.35–2.06 bins) | **met in every scope at every tier** (100.00% within one bin per key, small-N, 1 and 7 merges) | V5 § A–E |
| **R5** determinism | fixed-sequence: holds | fixed-sequence: holds; additionally order-independent (0/200 keys) and merge-commutative (0/200 pairs) vs T's 105/200 and 2/200 (`rebins` field) | V1 Part C; V3 12-decade key |
| **R6** overflow/underflow counters | unchanged (contract confirmed under the cap; S parity) | vacuous — nothing to count | V1 A6/A7; V3 Part B |
| **R7** partition independence across consumers / keys | unchanged | the grid is shared, the counts are not: rows remain independent; merge = index-wise add without touching either source | V1 Part C merges; V5 [pair] |
| **R8** memory lifecycle (per-key freeable; reallocation on extend) | per-row columns; widening runs verbatim `partition_extend` through a dense view | span grows by splice; no reallocation of a partition; memory for a given span is insertion-order-dependent (`0` vs `undef` fill, 3–4×) until the downward fill is `undef` | V3 Part B, Surprise 2 |
| **R9** telemetry surface for `-V` | unchanged | rebin / overflow telemetry has nothing to report; `grid_bpd`, `grid_index_range`, `span_slots`, `counter_slots_total` rendered as the proposed replacement | V4 F2–F3, `revalidate-v4-all.txt` 139–152 |
| **R10** pre-migration coexistence | unchanged | unchanged (`-mdm raw` path identical from every arm) | V4 F5 |
| **R11** boundaries with other features | unchanged | unchanged | — |
| **R12** `partition_rebin` finalize wrapper (#201) | unchanged in code; it is the merge remap whose accuracy cost V5 measures and whose time cost V2 measures (89–754 µs/merge on T, 121–1,047 on S through dense views; `rebins` reset to 0 so merge-driven rebins are invisible to `-V`) | not used by G's merge (index-wise add: 5.8–29 µs/merge); display-geometry consumers (F2/F3) not exercised here | V5 § D–E; V2 F5/F7; § *not covered* |

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

### Proposed amendments (NOT locked — for the architect)

Each row is grounded in a captured aspect; none takes effect until the architect records it as a `Dxx` in the #426 record and, where a #187 decision changes, as an amendment entry there. Rows marked *P10 only* are moot if P10 is not adopted.

| # | decision | proposed text | grounding |
|---|---|---|---|
| A1 | #187 D5 (per-key seeded partition, HdrHistogram doubling) — *P10 only* | For F1 consumers the partition lifecycle is replaced by one log-spaced grid per store (`index = floor(bpd × log10 v)`), per-key storage over the occupied span; no seed, no extension, no remap; the `-V` tuning surface is the span distribution, not rebin counts. | V3 F2/F4/F7; V1 Part C; V5 F2/F4 (remap is the sole bound-breaker; G order-independent; 0/4,153 keys above the seed) |
| A2 | #187 D4 (overflow/underflow, `out_of_range_bounded`) — *P10 only* | The shared grid has no out-of-range state: every positive value has an index; the overflow/underflow counters and the `low`/`high` audit branches do not exist for F1 consumers; `out_of_range_bounded` is either dropped or documented as constant `none`. | V1 A5–A7; V3 Part B/C; V4 scenario 5 |
| A3 | #187 D8 field set — *P10 only* | Replace `total_rebin_events`, `max_partition_bins`, `partitions_with_overflow_count`, `partitions_with_underflow_count`, `rebins_per_partition` with `grid_bpd`, `grid_index_range: lo..hi`, `span_slots: p50= p95= p99= max=`, `counter_slots_total`; keep `path`, `partition_keying`, `partition_count`, `counter_memory_bytes`, `percentiles_emitted`; decide `out_of_range_bounded` per A2. | V4 F2/F3 (rendered block, `revalidate-v4-all.txt` 139–152) |
| A4 | #187 R4 accuracy contract wording — regardless of P10 | State that the structural bound holds per partition only while no remap has occurred; a widening (D5) or a merge (R12 `partition_rebin`) may exceed it by up to ~2 bins on this surface. Under P10 the sentence "structural, derived from geometry" holds without exception. | V5 F2/F4, § D–E; V1 A10 |
| A5 | #189 V5 finding 1 (report correction) — regardless of P10 | "Within the bound across all 4,153 partitions × 7 quantiles × 4 precision levels" → within the bound for 327 of 328 N ≥ 100 keys at bpd 256 (0.93% vs 0.90%, one widening remap); all other tiers as stated. | V5 F3, `revalidate-v5-key-bpd256.tsv` ordinal 75 |
| A6 | #189 R4 note "positive-only substrate" / R2 guidance — regardless of P10 | The primitives are undefined for v ≤ 0 (T/S: infinite loop on negative, die on 0; G: die on both); the caller-side `> 0` guard is part of the contract and must precede every `add` in the P8–P10 store. | V1 A11; V3 Part C |
| A7 | #189 R2 guidance — G index convention — *P10 only* | Record whether the grid index is the closed form `floor(bpd × log10 v)` (one low at exact powers of ten; zero attribution error) or the boundary-checked form; the bin-mode digest baseline is defined by that choice. | V1 Part B, A8/A9; V5 probe 1 |
| A8 | #189 R8 / #426 P9 implementation note — S and G | Downward span growth extends with `undef`, not `0`, so a span's memory is insertion-order-independent. | V3 Surprise 2 / F6 |
| A9 | #187 D1 implementation guidance — regardless of P10 | Mark the `lower = upper` case as unreachable on both geometries (no code path needs it). | V1 A2 |
| A10 | #187 D7/D8 text vs shipped emitter — regardless of #426 | Record the pre-existing drift: no `--exact-percentiles` / `-ep` flag, no `opt_out_active` / `opt_out_notice` lines in today's `emit_bin_counter_mode_verbose`; the opt-out is `-mdm raw` and surfaces as `path: user_opt_out`. | V4 F5, `revalidate-v4-ltl-real-raw.txt` |
| A11 | #187 D2 memory-footprint guidance (~2.1 KB per partition, ~212 MB at 10⁵ keys) and #189 V2 finding 4's +11–12% Perl-overhead note — if P9 or P10 is adopted | Both describe T's dense per-key array only. Replace the "(B+2) counters × 8 bytes" model with a span-based one — per-key fixed overhead + 8 B × occupied span — and state that the footprint's bpd sensitivity is a property of the dense layout (T 5.77× from bpd 53 to 616) rather than of the precision lever (S 1.23×, G 1.36×). | V2 F1/F4 (reproduced T at 227.1 MB / +12.3%; S 91 MB Devel / 57 MB RSS; G 57 / 19 MB at 10⁵ keys, bpd 53), `revalidate-v2-{T,S,G}-bpd{53,616}.txt` |

### What the evidence does not cover

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
