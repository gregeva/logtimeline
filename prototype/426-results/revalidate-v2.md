# V2 — Per-key fan-out at scale, per-line fill cost, merge and `-g` fold cost (#426 revalidation of #189 V2)

Prototype: `prototype/426-revalidate-v2.pl` + driver `prototype/426-revalidate-v2.sh` (library
`prototype/426-revalidate-lib.pm`, unchanged).
Captured runs (all in `prototype/426-results/`): parity `revalidate-v2-parity-{T,S}-bpd{53,616}.txt`;
timed `revalidate-v2-{T,S,G}-bpd{53,616}.txt`; collected timings `revalidate-v2.tsv`; T↔S post-check
`revalidate-v2-postcheck.txt`; driver log `revalidate-v2-driver.txt`.
Arms: **T** production primitives verbatim; **S** span-only columnar, verbatim geometry (P8+P9);
**G** shared log-spaced grid, span-only (P10). File: the #189 V2 fan-out file
`logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-0.2026-01-14.txt` (67 MB).

## Hypothesis

#189 V2 measured Decision 5's per-key fan-out on this file with T only: 51,469 partitions, 116.86 MB
(2,381 B/partition), 227 MB projected at 10⁵ partitions (+12.3% over #187 D2's ~212 MB guidance),
6 rebin events, closed-form fill 1.63 s (parse included). T here must reproduce those figures. S,
digest-identical to T by construction (P8+P9), should cost a fraction of T's memory because a key's
occupied span (p50 = 1 bin in #426 V7) is stored instead of a dense array; G should cost less again
(no partition fields) and its memory should scale with bpd only through span width, whereas T's
dense array scales with bin_count. Per-line fill should be cheapest on G (one `floor(bpd·log10 v)`,
no range check, no seed), and merge/fold cheapest on G (index-wise add, no union remap). S runs the
verbatim `merge_bin_counter_entries` through dense views of both rows, so S's merge is expected to
be no faster than T's; how much slower is the measurement.

## Method

Phases 0–7 of `426-revalidate-v2.pl`, **one arm per process** (`--arm T|S|G --bpd N --runs 3`), so
the arm being timed is the only store in the process:

- **Parse once per process** (phase 0): `iterate_durations` pushes `(key, duration)` into two
  arrays; every later phase reads those arrays, so timed sections measure the store, not the regex.
  Parse wall-clock is reported once and is **not** part of any timed metric. **The T fill here is
  the store only; #189's 1.63 s included parsing** — compare 1.63 s to parse + fill (1.29 + 0.50 s),
  not to fill alone.
- **Parity before timing** (phase 1, driver step 1): T and S run with `--parity-only` at both bpd;
  the driver asserts equal `fill_digest` and key count before any timed run and exits non-zero
  otherwise (`revalidate-v2-driver.txt`: PASS at 53 and 616). Phase 1 also brackets the untimed
  warmup fill with `rss_kb` (RSS delta).
- **Fill timing** (phase 2): 3 timed fills into a fresh store each (after the phase-1 warmup);
  ns/sample = median / 339,832 positive samples.
- **Memory** (phase 3): `Devel::Size::total_size` of the store (T: the keyed entry hash; S/G: the
  key→row hash, the row→key array and every column) and the phase-1 RSS delta; both divided by
  keys and projected to 10⁵ keys; T/S telemetry via the verbatim `snapshot_counter_telemetry`
  (S computes the same 12 fields from its columns), G its own span/index telemetry.
- **Spans** (phase 4): occupied span = hi − lo + 1 over nonzero bins per key, p50/p95/p99/max/mean;
  T/S also `bin_count`; T also the length of the dense `bins` array actually allocated.
- **Percentile pass** (phase 5): all keys × 7 quantiles (0.01, 0.5, 0.75, 0.9, 0.95, 0.99, 0.999),
  `ceil` convention, one warmup + 3 timed passes; `pct_digest` = MD5 over `value|audit`.
- **Merge pairs** (phase 6): consecutive keys in sorted order with N ≥ 2, paired disjointly (725 pairs
  from 1,450 keys — the #426 V8 shape); a fresh filled store per run (untimed setup), the 725 merges
  timed with `drop_source`; remap accounting from the union geometry computed on the untouched
  filled store; N conservation after the merges. **S's merge is the verbatim
  `merge_bin_counter_entries` run over `entry()` dense views of both rows, written back as a span**
  (`Store::S::merge`, lib lines 1054–1068); T's is the verbatim sub over the live entries; G's is the
  index-wise add.
- **Fold** (phase 7): merge every other key into the first key in sorted order — 51,468 merges, the
  `-g` fold shape; fresh store per run (untimed setup); **`fold_us_per_merge` = median fold seconds
  / 51,468**; final geometry, digest and 7 percentiles of the accumulator.
- Medians of 3 with min–max throughout (`median_min_max`); `caffeinate -s` around every run.
- **Post-check** (driver step 3): `fill_digest`, `pct_digest`, `merge_digest`, `fold_digest`, key
  counts, `fold_percentiles` equal between T and S at both bpd, and `merge_n_total_after` /
  `fold_n_total` = 339,832 for all three arms. Result: `ALL PASS` (`revalidate-v2-postcheck.txt`).

Parse (identical in every process, `revalidate-v2-*-bpd*.txt`): 343,143 lines, 343,143 matched,
339,832 positive durations, 3,311 zero (excluded), 0 negative, 51,508 keys with any duration,
**51,469 keys with a positive duration** (= #189 V2's 51,469 partitions); parse 1.25–1.30 s;
Perl v5.42.2.

## Result

### Fill and memory (`revalidate-v2-{T,S,G}-bpd{53,616}.txt`, phases 1–3)

| bpd | arm | fill s median (min–max) | ns/sample | Devel::Size MB | B/key (Devel) | RSS delta B | B/key (RSS) | 10⁵ keys (Devel) | 10⁵ keys (RSS) | vs D2 212 MB (Devel) |
|---|---|---|---|---|---|---|---|---|---|---|
| 53 | T | 0.500 (0.481–0.518) | 1,471 | **116.86** | **2,381** | 124,944,384 | 2,428 | **227.1** | 231.5 | **+12.3%** |
| 53 | S | 0.349 (0.335–0.364) | 1,026 | 46.90 | 955 | 30,785,536 | 598 | 91.1 | 57.0 | −54.9% |
| 53 | G | 0.216 (0.214–0.223) | 635 | 29.46 | 600 | 10,190,848 | 198 | 57.2 | 18.9 | −71.7% |
| 616 | T | 0.552 (0.529–0.572) | 1,623 | 673.92 | 13,730 | 811,220,992 | 15,761 | 1,309.4 | 1,503.1 | — |
| 616 | S | 0.362 (0.334–0.394) | 1,065 | 57.57 | 1,173 | 42,876,928 | 833 | 111.9 | 79.4 | — |
| 616 | G | 0.210 (0.210–0.212) | 619 | 40.09 | 817 | 23,265,280 | 452 | 77.9 | 43.1 | — |

T reproduces #189 V2 exactly: 51,469 partitions, 116.86 MB, 2,381 B/partition, 227.1 MB at 10⁵,
+12.3% vs 212 MB, `total_rebin_events=6`, `rebins p50/p95/p99/max = 0/0/0/1`,
`max_partition_bins=397`, no overflow/underflow. S telemetry is identical (same six rebins, same
397 max bins). #189's closed-form 1.63 s (parse + fill) corresponds to 1.29 + 0.50 = 1.79 s here.

Ratios at 53 / 616: fill S/T 0.70 / 0.66, G/T 0.43 / 0.38; Devel::Size T/S 2.49 / 11.7, T/G
3.97 / 16.8; RSS delta T/S 4.06 / 18.9, T/G 12.3 / 34.9. From bpd 53 to 616, T's memory grows
5.77× (Devel::Size), S 1.23×, G 1.36×.

### Span, bin_count and dense-array distributions (`revalidate-v2-{T,S,G}-bpd{53,616}.txt`, phase 4)

| bpd | metric | p50 | p95 | p99 | max | mean |
|---|---|---|---|---|---|---|
| 53 | occupied span, T = S | 1 | 1 | 44 | 210 | 2.07 |
| 53 | occupied span, G | 1 | 1 | 44 | 210 | 2.07 |
| 53 | bin_count, T = S | 265 | 265 | 265 | 397 | — |
| 53 | T dense `bins` length | 133 | 133 | 158 | 300 | 133.64 |
| 616 | occupied span, T = S | 1 | 1 | 503 | 2,436 | 13.49 |
| 616 | occupied span, G | 1 | 1 | 503 | 2,437 | 13.49 |
| 616 | bin_count, T = S | 3,080 | 3,080 | 3,080 | 4,619 | — |
| 616 | T dense `bins` length | 1,540 | 1,540 | 1,834 | 3,488 | 1,547.42 |

G's grid index range after fill: [0, 286] at 53, [0, 3327] at 616 (`telemetry_index_min/max`).

### Percentile pass — 360,283 evaluations (`revalidate-v2-{T,S,G}-bpd{53,616}.txt`, phase 5)

| bpd | arm | pass s median (min–max) | µs/eval | pct_digest |
|---|---|---|---|---|
| 53 | T | 7.470 (7.460–7.470) | 20.73 | 0f0971ac… |
| 53 | S | 0.952 (0.951–0.960) | 2.64 | 0f0971ac… (= T) |
| 53 | G | 0.787 (0.784–0.788) | 2.19 | dc27bba1… |
| 616 | T | 75.190 (75.167–75.588) | 208.70 | f1016f0f… |
| 616 | S | 1.271 (1.268–1.283) | 3.53 | f1016f0f… (= T) |
| 616 | G | 1.024 (1.019–1.027) | 2.84 | 65094c26… |

T/S = 7.8× at 53, 59.2× at 616; T/G = 9.5× / 73.4×. T's per-evaluation cost is 78 ns per
`bin_count` slot at 53 (20.73 µs / 265) and 68 ns at 616 (208.70 µs / 3,080) — it is the walk over
the full partition.

### Merge, 725 consecutive pairs (`revalidate-v2-{T,S,G}-bpd{53,616}.txt`, phase 6)

| bpd | arm | merge s median (min–max) | µs/merge | pairs remapped (target / source / any) | remap % | keys after | max bins after | merge_digest |
|---|---|---|---|---|---|---|---|---|
| 53 | T | 0.0646 (0.0646–0.0681) | 89.17 | 723 / 722 / 725 | 100.0 | 50,744 | 499 | 521fd6bb… |
| 53 | S | 0.0878 (0.0850–0.0892) | 121.07 | 723 / 722 / 725 | 100.0 | 50,744 | 499 | 521fd6bb… (= T) |
| 53 | G | 0.0042 (0.0037–0.0045) | 5.81 | 0 / 0 / 0 | 0.0 | 50,744 | — | 075008a8… |
| 616 | T | 0.5465 (0.5463–0.5564) | 753.75 | 725 / 725 / 725 | 100.0 | 50,744 | 5,803 | 79cb4aa8… |
| 616 | S | 0.7592 (0.7431–0.7756) | 1,047.15 | 725 / 725 / 725 | 100.0 | 50,744 | 5,803 | 79cb4aa8… (= T) |
| 616 | G | 0.0212 (0.0205–0.0220) | 29.23 | 0 / 0 / 0 | 0.0 | 50,744 | — | f274d94e… |

`merge_n_total_after` = 339,832 for every arm at both bpd. S/T = 1.36× (53), 1.39× (616); T/G =
15.3× / 25.8×; S/G = 20.8× / 35.8×; G at 616 costs 5.03× G at 53.

### `-g` fold, 51,468 merges into one accumulator (`revalidate-v2-{T,S,G}-bpd{53,616}.txt`, phase 7)

| bpd | arm | fold s median (min–max) | µs/merge | fold / fill | final span (occupied) | nonzero bins | bin_count | dense len | min / max / decades | fold_digest |
|---|---|---|---|---|---|---|---|---|---|---|
| 53 | T | 3.280 (3.267–3.297) | 63.74 | 6.6× | 288 | 208 | 531 | 531 | 0.00316228 / 3.34095e7 / 10.024 | 162a349a… |
| 53 | S | 5.872 (5.858–5.888) | 114.10 | 16.8× | 288 | 208 | 531 | 419 | same | 162a349a… (= T) |
| 53 | G | 0.0927 (0.0886–0.0950) | 1.80 | 0.43× | 287 (index 0..286) | 191 | — | — | — | 43e5a70a… |
| 616 | T | 33.222 (33.196–33.495) | 645.49 | 60.2× | 3,328 | 1,675 | 6,174 | 6,174 | same | cba03dcd… |
| 616 | S | 60.475 (60.447–60.502) | 1,175.01 | 167.1× | 3,328 | 1,675 | 6,174 | 4,867 | same | cba03dcd… (= T) |
| 616 | G | 0.1166 (0.1081–0.1201) | 2.27 | 0.55× | 3,328 (index 0..3327) | 1,468 | — | — | — | 38d1dede… |

`fold_n_total` = 339,832 in every arm; `fold_rebins` = 0, `fold_overflow` = `fold_underflow` = 0
(T/S). S/T = 1.79× (53), 1.82× (616); T/G = 35× / 284×; S/G = 63× / 518×. The "dense len" column is
`fold_dense_len`: T's is the accumulator's live `bins` array, S's is the length of the dense view
`entry()` builds (base + span, i.e. up to the last occupied partition index).

Fold percentiles, T (= S) vs G (`fold_percentiles` lines; differences computed from them). The T
accumulator's bin width is `(max/min)^(1/bin_count) − 1` = 10^(10.024/531) − 1 = **4.443%** at 53
(grid: 4.4403%) and 10^(10.024/6174) − 1 = 0.3745% at 616 (grid: 0.3745%); T's bins start at
0.00316228 (the accumulator's min) and are not aligned to the 10^(i/bpd) grid, so the two geometries
have the same width but a different phase. "Bins" below is `ln(G/T) / ln(1 + width)` at that bpd.

| q | T @53 | G @53 | G−T @53 (bins) | T @616 | G @616 | G−T @616 (bins) | T @53 vs T @616 | G @53 vs G @616 |
|---|---|---|---|---|---|---|---|---|
| 0.01 | 1.01124 | 1.03101 | +1.96% (0.45) | 1.00033 | 1.00263 | +0.23% (0.61) | +1.09% | +2.83% |
| 0.5 | 19.505 | 19.039 | −2.39% (0.56) | 19.0258 | 19.0077 | −0.10% (0.25) | +2.52% | +0.16% |
| 0.75 | 47.8848 | 48.1164 | +0.48% (0.11) | 47.8617 | 47.9423 | +0.17% (0.45) | +0.05% | +0.36% |
| 0.9 | 228.262 | 228.518 | +0.11% (0.03) | 228.779 | 228.647 | −0.06% (0.15) | −0.23% | −0.06% |
| 0.95 | 779.785 | 787.456 | +0.98% (0.23) | 786.061 | 785.705 | −0.05% (0.12) | −0.80% | +0.22% |
| 0.99 | 4688.36 | 4719.34 | +0.66% (0.15) | 4705.2 | 4709.83 | +0.10% (0.26) | −0.36% | +0.20% |
| 0.999 | 100161 | 99704.9 | −0.46% (0.11) | 99823.1 | 99780.4 | −0.04% (0.11) | +0.34% | −0.08% |

Every T↔G difference is below one bin at its bpd. No oracle in this aspect (V5's); the table only
shows the two geometries disagreeing by a fraction of a bin after 51,468 merges.

## Surprises

- **S's merge and fold are slower than T's (1.36–1.39× on pairs, 1.79–1.82× on the fold)**, although
  S's fill and percentile are faster. The code says why: `Store::S::merge` calls `entry()` on both
  rows, and `entry` builds a fresh dense array (`_dense_view`: `$d[$base + $_] = …`, an array of
  hi_index + 1 slots) plus a partition hash for each side, hands them to the verbatim
  `merge_bin_counter_entries` (which, per remapped side, walks `0 .. bin_count − 1` in
  `partition_rebin`, zero-fills `new_bin_count` slots, then adds over `0 .. union_bin_count − 1`),
  and finally `_span_from_dense` scans the union result from index 0 to find the first/last nonzero
  and copies the span back. In the fold the accumulator is the target of every one of 51,468 merges,
  so its dense view (419 slots at 53, 4,867 at 616 — `fold_dense_len`) is materialised and re-trimmed
  on every merge; T never does that (its dense array stays in place and, once its geometry equals
  the union, only the source is rebinned). The arithmetic matches the measurement: T's 645 µs/merge
  at 616 ≈ 6,174 zero-fill + 3,080 source walk + 6,174 add = 15,428 slot operations at ~42 ns each;
  S's extra 530 µs (1,175 − 645) ≈ 3,328 (accumulator view) + 6,174 (trim scan) + 3,328 (span copy)
  ≈ 12.8k slot operations at the same ~41 ns; at 53 the extra 50 µs (114.1 − 63.7) ≈ 288 + 531 + 288
  ≈ 1.1k operations at ~46 ns. A native P9 merge would remap the source's occupied span directly
  into the target's span array (the remap loop already skips zero bins, so it is O(occupied);
  `_bump_offset_dense` already does the base shift), never allocate a dense view, and drop the
  zero-fill, the trim scan and the `0 .. union_bin_count` add loop — leaving a walk over the source
  span, which is what G's merge already is (1.8–2.3 µs/merge).
- **T's dense array is half the partition, not the partition.** `counter_update` seeds `bins => []`
  and writes `$bins->[$idx]++`, so the array extends to the highest index touched: a single-sample
  key at the seed centre (index 132 of 265 at 53; 1,539 of 3,080 at 616) holds 133 / 1,540 slots
  (`dense_len_50`), all but one of them NULL pointers — 1,069 B / 12,379 B per key at the mean
  length (133.64 / 1,547.42 slots × 8 B). That is the whole of T's bpd sensitivity (2,381 → 13,730
  B/key, 5.77×) while the occupied span p50 stays 1 at both bpd. `partition_extend` returns a
  remapped array that is likewise sparse (it grows to the highest remapped index); only
  `partition_rebin` zero-fills to `bin_count` — hence `dense_len_max` 300 < `bin_count_max` 397 after
  the fill (6 extends, no rebins) and `fold_dense_len` = `bin_count` = 531 / 6,174 after the fold
  (the accumulator went through `partition_rebin` inside the merge).
- **T's percentile walks the full partition**, `for my $i (0 .. bin_count − 1)` with `// 0` on every
  slot: 20.7 µs at 53 and 208.7 µs at 616 for keys whose median span is one bin; S and G walk the
  span (2.6–3.5 µs) and are within 1.3× of each other.
- **Every one of the 725 pairs needs a remap in T/S** (100% at both bpd; 723 targets and 722
  sources at 53, 725/725 at 616): consecutive keys seed on different first samples, so the union
  geometry matches neither side. The pair-merge cost is therefore always the double rebin, and the
  max partition after 725 pair merges grows from 397 to 499 bins (4,619 → 5,803 at 616).
- **The fold reports `fold_rebins=0`** on an accumulator that was re-geometried from 265 to 531 bins
  (3,080 → 6,174): `partition_rebin` returns a partition with `rebins => 0`, so `-V` rebin telemetry
  does not count merge-driven rebins (V1 saw the same field property on the commutativity test).
- **RSS delta undercuts Devel::Size for S and G** (598 vs 955 B/key; 198 vs 600) but not for T
  (2,428 vs 2,381). S and G allocate less than the arena slack left by the parse phase's freed
  temporaries (RSS after parse is 96–98 MB in every process), so their RSS delta is a lower bound;
  Devel::Size for S/G counts the key column's scalars on top of the hash keys. The truth is between
  the two columns; both projections are reported.
- G's occupied span max is 2,437 at 616 against T/S's 2,436, and G's fold accumulator has 191 /
  1,468 nonzero bins against T's 208 / 1,675: the two grids are offset (T's bins start at each
  key's `min`), so the same samples straddle bin edges differently; T's remap also splits mass
  across neighbouring bins that G's index-wise add keeps together.

## Findings and actions

1. **T reproduces #189 V2 to the byte** (51,469 partitions, 116.86 MB, 2,381 B/partition, 227.1 MB
   at 10⁵, +12.3%, 6 rebins, max 397 bins); parse + fill = 1.79 s against #189's 1.63 s
   parse-included figure. The baseline arm is the production code under the #189 conditions.
2. **S vs T, memory and time (P8+P9).** Digest-identical at fill, percentile, merge and fold at both
   bpd (`revalidate-v2-postcheck.txt`, ALL PASS). Memory: 955 vs 2,381 B/key at 53 (Devel::Size,
   2.49×), 1,173 vs 13,730 at 616 (11.7×); RSS delta 4.06× / 18.9×. Fill 0.70× / 0.66× of T's
   time; percentile pass 7.8× / 59× faster. Merge pairs 1.36× / 1.39× **slower**, fold 1.79× / 1.82×
   **slower** — a cost of running the verbatim merge through dense views, not of the span
   representation (see Surprises; the extra time is accounted for by the view, scan and copy loops).
   Action: P9's merge must be written natively over the span array before S's merge/fold numbers
   mean anything; the fill, memory and percentile numbers stand.
3. **G vs S (P10 vs P8+P9).** G is cheaper on every axis: memory 600 vs 955 B/key at 53 and 817 vs
   1,173 at 616 (RSS: 198 vs 598, 452 vs 833); fill 635 vs 1,026 ns/sample (619 vs 1,065 at 616);
   percentile 2.19 vs 2.64 µs (2.84 vs 3.53); merge 5.8 vs 121 µs (29 vs 1,047); fold 1.80 vs
   114 µs (2.27 vs 1,175). The merge and fold gap (21–36× on pairs, 63–518× on the fold) is
   structural — no union geometry, no remap — whereas the fill/percentile gap (1.2–1.7×) is the
   per-key partition state S carries and G does not.
4. **#187 D2's ~212 MB projection needs amendment under S and G.** It holds for T only (+12.3%).
   Under S the same 10⁵ keys project to 91 MB (Devel::Size) / 57 MB (RSS) at bpd 53, under G to
   57 MB / 19 MB — 2.3–11× below the guidance — and the bpd dependence changes shape: T grows 5.8×
   from 53 to 616 (1.3–1.5 GB at 10⁵ keys) because its dense array holds NULL slots up to the seed
   centre; S grows 1.23× (112 / 79 MB) and G 1.36× (78 / 43 MB) because only the occupied span
   (p99 44 → 503 bins, p50 1 → 1) widens. Action: replace the "(B+2) counters × 8 bytes" model with
   a span-based one (per-key fixed overhead + 8 B × occupied span), and record that the
   `counter_memory_bytes` figure and the +11–12% Perl-overhead note in #189 finding 4 describe T's
   layout only.
5. **What the `-g` fold costs per arm** (51,468 merges on 51,469 keys): T 3.28 s at 53 (6.6× its
   0.50 s fill) and 33.2 s at 616 (60× fill); S 5.87 s / 60.5 s (17× / 167× fill); G 0.093 s /
   0.117 s (0.43× / 0.55× fill). Under T/S the fold is the dominant per-run cost at this
   cardinality and scales with `bin_count` (645 µs/merge at 616 ≈ 15.4k slot operations); under G it
   scales with the source span (mean 2.07 → 13.49 slots) and stays below the fill. All three arms
   conserve N (339,832) and T = S on the fold digest and percentiles; T and G differ by ≤ 0.61 bins
   at every quantile. Action: the `merge_bin_counter_entries` rebin-on-every-merge design is what
   #187 D5 costs on `-g`; any P8/P9 implementation that keeps it inherits 3–60 s folds here.
6. **G's merge cost at 616 vs 53**: 29.2 vs 5.8 µs/merge on pairs (5.0×) but 2.27 vs 1.80 µs on the
   fold (1.26×). Pairs are N ≥ 2 keys whose spans scale with bpd (mean span 6.5× wider at 616), and
   the index-wise add plus the `splice` base shift are O(span); the fold's sources are mostly
   single-bin keys, so its cost is nearly bpd-independent. G's merge cost is bounded by the source's
   occupied span, not by bpd.
7. **Rebin telemetry is unchanged on S and vacuous on G**: S reports the same 6 events / max 1 / 397
   max bins as T (same primitives), G has no rebins, overflow or underflow to report (index range
   [0, 286] / [0, 3327] and span percentiles instead — `telemetry_*` lines). Decision 8's `-V`
   field set under P10 is V4's aspect; V2 adds that the merge-driven rebin in the fold is invisible
   to that telemetry even on T (`fold_rebins=0`).

## Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
F=logs/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-0.2026-01-14.txt
O=prototype/426-results

# driver (parity pass -> timed pass -> post-check; exits non-zero on any T/S divergence)
prototype/426-revalidate-v2.sh --file $F --bpds "53 616" --arms "T S G" --runs 3

# the per-arm commands the driver runs (what produced the captured files):
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
```

The captured driver log (`revalidate-v2-driver.txt`) shows the parity pass (both PASS) and the
launch of the first timed arm; that driver invocation was cut off after launching T bpd 53, and
the six timed captures were produced by the per-arm command above one process at a time, then
collected and post-checked with the driver's step-2/step-3 logic (`revalidate-v2.tsv`,
`revalidate-v2-postcheck.txt`: ALL PASS).
