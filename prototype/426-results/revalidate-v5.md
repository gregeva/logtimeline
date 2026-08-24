# #426 revalidation — V5: accuracy vs the `calculate_statistics` oracle, per key and after merge

Mirror of #189 V5 (`prototype/189-bin-counter-primitives-validation-report.md` § V5) on the same
primary surface, extended with the merge scope of #426 V8. Arms: **T** (production primitives
verbatim), **G** (shared log-spaced grid, span-only; P10). **S** (span-only columnar, verbatim
geometry; P8+P9) is asserted digest-identical to T on the full file and is not tabulated
separately: it inherits every T number below by construction.

Instrument: `prototype/426-revalidate-v5.pl` (driver `prototype/426-revalidate-v5-run.sh`, one
process per bpd, file parsed once per process); condensed tables
`prototype/426-revalidate-v5-tables.pl` → `revalidate-v5-tables.txt`; mechanism probes
`prototype/426-revalidate-v5-probe.pl` → `revalidate-v5-probe.txt`. Raw per-comparison rows in
`revalidate-v5-{key,small,pair,fold}-bpdNN.tsv`, aggregates in `revalidate-v5-summary.tsv`.

## Hypothesis

Per #187 R4 (structural accuracy contract) and Decision 1 (Prometheus `histogram_quantile`
walk, `ceil(q·N)`), every required percentile must sit within the bin-resolution bound
`10^(1/bpd) − 1` of the exact nearest-rank value (`$sorted[int(N·q)]`, ltl:12716). #189 V5
showed this for T per key at bpd 53/115/256/616. #426 V8 claimed, on the DPM ScriptLog at bpd 53
only, that G holds the same bound per key and — unlike T — after merges. This aspect asks
whether both claims hold on the #189 primary surface at every tier, per key, on small-N keys,
after one merge, and after seven sequential merges (the `-g` fold shape); and where the
`ceil(q·N)` vs `int(q·N)` rank convention becomes the dominant error.

## Method

File: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` — 1,430,678
lines, 857,480 positive durations (573,198 zeros excluded before any arm), 4,153 keys with
positive durations, **328 keys with N ≥ 100** (#189's count), 2,517 with N ≥ 2. Keys are ltl's
`(category, log_key)` via the verbatim #189 parser (`revalidate-v5-bpd53.txt` line 4–5).

Per bpd ∈ {53, 115, 256, 616}, quantiles P1 P50 P75 P90 P95 P99 P999, dual reporting as #189 V5:
`binning_*` = the arm's walk forced to the oracle's rank (`int(q·N)+1`, 1-based — the bin
holding the oracle's own sample; binning error alone); `raw_*` = native `ceil(q·N)` (binning +
rank convention). Pass criterion: `binning_max ≤ 10^(1/bpd) − 1`.

Scopes: **[key]** N ≥ 100 (the #189 V5 table); **[small]** every key with N ≥ 2
(informational); **[pair]** 1,258 disjoint pairs of consecutive keys in sorted order, both
N ≥ 2, merged (T: fresh entries per pair, `merge_bin_counter_entries` verbatim; G: index-wise
add) vs the oracle over the union of samples; **[fold]** 314 groups of 8 consecutive keys folded
sequentially into the first (7 merges), error vs the oracle over the cumulative union after
every step. Parity: T↔S whole-store digest at bpd 53 before any table (exit 2 on divergence).

## Result

### Parity (before any accuracy table)

`revalidate-v5-bpd53.txt` line 13: `PASS parity bpd=53: T digest=3962d9c26ac17c07388d8a02149c3fb0
S digest=3962d9c26ac17c07388d8a02149c3fb0 keys T=4153 S=4153`. T telemetry reproduces #189 V5
exactly: `partition_count=4153 total_rebin_events=7 max_partition_bins=397 … rebins p50=0 p95=0
p99=0 max=1`, overflow/underflow 0 (line 11). Store memory (`Devel::Size`, single build):
T 9.99 MB / S 3.61 MB / G 2.08 MB at bpd 53; T 59.7 MB / G 6.85 MB at bpd 616 (lines 8–10 of
each capture).

### [key] N ≥ 100 — the #189 V5 table, per arm (`revalidate-v5-tables.txt` § A)

| bpd | bound | arm | binning_max (range over 7 q) | binning_p50 (range) | raw_max (range) | raw − binning gap | pass |
|---|---|---|---|---|---|---|---|
| 53 | 4.44% | T | 3.44%–4.44% | 0.05%–2.20% | 3.44%–4.44% | none | PASS |
| 53 | 4.44% | G | 4.16%–4.44% | 0.06%–4.22% | 4.16%–4.44% | none | PASS |
| 115 | 2.02% | T | 1.56%–2.01% | 0.02%–1.20% | 1.56%–2.01% | none | PASS |
| 115 | 2.02% | G | 1.81%–2.02% | 0.03%–1.92% | 1.81%–2.02% | none | PASS |
| 256 | 0.90% | T | 0.83%–**0.93%** | 0.01%–0.86% | 0.83%–1.76% | +0.85% | **FAIL** (1 row) |
| 256 | 0.90% | G | 0.83%–0.90% | 0.01%–0.86% | 0.83%–1.90% | +1.00% | PASS |
| 616 | 0.37% | T | 0.33%–0.37% | 0.01%–0.37% | 0.37%–1.87% | +1.54% | PASS |
| 616 | 0.37% | G | 0.36%–0.37% | 0.01%–0.36% | 0.36%–1.95% | +1.57% | PASS |

T's ranges are #189 V5's ranges to the digit (53: 3.44–4.44 / 0.05–2.20; 115: 1.56–2.01 /
0.02–1.20; 256: 0.83–0.93 / 0.01–0.86; 616: 0.35–0.37 / 0.01–0.37 — this run 0.33–0.37 at 616),
including the **0.93% at bpd 256 that #189 tabulated and marked ✅ against a 0.90% bound**. The
row (`revalidate-v5-key-bpd256.tsv`: key ordinal 75, P75, oracle 1, T err +0.9336%; G +0.7930%)
is `[200] GET /Thingworx/Runtime/index.html`, N=413, 353 samples of exactly 1 ms. Probe 2
(`revalidate-v5-probe.txt` lines 37–48): the partition widened once (576 ms arrived at position
174 of 413), `bin_count` became `int(256 × 7.5) = 1919` (bin width 0.9040%), and the widening
remap moved the 143 pre-widening counts of value 1 into bin 640 `[1.00300, 1.01207)` — a bin
that does not contain the value — while the 210 later samples of the same value went to bin 639.
The rank walk then interpolates inside a bin the oracle's sample is not in. G has no widening:
its 353 counts sit in one bin `[1, 1.00904)` and the bound holds.

Per quantile (§ B): at bpd 53 G's `binning_p50` is 3.3–4.2% at P75–P99 against T's 1.1–2.2%,
and G's mean signed error is +2.1…+2.7% against T's +0.9…+1.6%. § F splits the keys by whether
the oracle value is an exact power of ten (1, 10, 100, 1000 ms — 159 of 328 keys at P99, 190 at
P95, 222 at P1): on those keys G's median error is the full bin width at P90–P999 (4.00–4.44% at
bpd 53; 155 of 159 P99 keys within 0.1% of the bound), on the other keys 0.7–1.1%; T on the same
keys 1.8–2.2%. Mechanism (probe 1, `revalidate-v5-probe.txt` lines 19–35): on G a power of ten
is exactly the *lower* boundary of its grid bin, so a spike of identical values fills a bin from
the bottom and the Decision 1 walk (`lower × (upper/lower)^(rank_in_bin/c)`) returns up to
`upper` for ranks late in the spike (`+4.3949%` at bpd 53 for a 100-sample spike at P99). T's
seed partition puts the first sample at boundary `bin_count/2` only when `int(5·bpd)` is even:
at 53/115 it is inside a bin (`+2.15%` / `+0.99%` for the same spike); at 256 at the bottom
(`+0.894%`, same as G — § F shows identical T/G medians at 256); at 616 float rounding lands it
at the *top* of bin 1539 (`upper = 0.99999999999999911`, spike error `−0.0037%`) — which is why
T's `binning_p50` at P90–P99 is 0.01–0.04% at bpd 616 and G's is 0.32–0.36%. Both are within
the bound; the difference is where a spike value sits inside its bin, not the formula.

Rank convention (§ B, `raw_max` vs `binning_max`): identical at bpd 53 and 115 for both arms
(gap `none` at every quantile); at 256 `raw_max` exceeds `binning_max` at P90/P95/P99 (T +0.43 /
+0.85 / +0.59 pts; G +0.58 / +1.00 / +0.61); at 616 T 1.87 / 1.72 / 1.30% vs binning 0.33 / 0.37
/ 0.36% (#189's exact numbers), G 1.95 / 1.80 / 1.46%. The crossover sits at bpd ≈ 256 for G as
it did for T.

### [small] every key with N ≥ 2 (§ C; 2,517 keys)

Binning convention: within one bin **100.00%** for G at every bpd and quantile, and for T at
every bpd/quantile except bpd 256 P50 (99.96%, max 1.31%) and P75 (99.96%, max 0.93%) — the same
widening-remap mechanism, one key each. Raw convention: within one bin at P50 89.7% (T) / 90.4%
(G) at bpd 53, 85.5% / 85.5% at 616; P75 97.5% / 97.7%; P90 99.4% / 99.5%; P99–P999 100% both.
The raw outliers (max 90.6% at P50) are identical between arms to within 0.1 pt: the rank
convention on keys with 2–4 samples, as #426 V8 found.

### [pair] 1,258 merged pairs (§ D; T needed a union remap on 920 = 73.1%)

| bpd | bound | T binning_max (worst q) / in bins | T within one bin (P95 / P99 / P999) | G binning_max / in bins | G within |
|---|---|---|---|---|---|
| 53 | 4.44% | 6.03% (P999) / 1.35 | 96.58% / 96.42% / 96.42% | 4.44% / 1.00 | 100% at every q |
| 115 | 2.02% | 2.86% (P50) / 1.41 | 99.05% / 98.09% / 97.77% | 2.02% / 1.00 | 100% |
| 256 | 0.90% | 1.34% (P1/P50/P75) / 1.48 | 93.16% / 97.62% / 99.52% | 0.90% / 1.00 | 100% |
| 616 | 0.37% | 0.55% (P99) / 1.46 | 99.44% / 99.60% / 99.52% | 0.37% / 1.00 | 100% |

T's medians after one merge are lower than G's at bpd 53 (P95 1.98% vs 1.96%, P99 1.92% vs
2.03%) and 115; its tail is not bounded. G's `binning_max` equals the bound to four decimals at
every bpd.

### [fold] 314 groups of 8, 7 sequential merges (§ E; T remapped on 1,934 of 2,198 = 88.0%)

| bpd | T within one bin after 7 merges (P50 / P90 / P95 / P99 / P999) | T step-7 max (worst q) / in bins | G within (all q, all 7 steps) | G step-7 max |
|---|---|---|---|---|
| 53 | 99.4 / 97.5 / 94.9 / 93.0 / 90.8% | 7.27% (P99) / 1.62 | 100.0% | 4.44% |
| 115 | 99.4 / 97.1 / 98.1 / 93.9 / 93.9% | 2.75% (P95) / 1.36 | 100.0% | 2.02% |
| 256 | 85.4 / 78.0 / 80.3 / 92.4 / 97.1% | 1.87% (P75) / 2.06 | 100.0% | 0.90% |
| 616 | 93.0 / 95.9 / 97.5 / 98.4 / 97.5% | 0.66% (P75) / 1.76 | 100.0% | 0.37% |

T's within-one-bin share decays with merge depth (bpd 53 P999: 95.9 → 93.6 → 92.7 → 92.0 → 91.4
→ 90.8 → 90.8% over steps 1..7; bpd 256 P90: 90.1 → 78.0%). G's stays 100.0% at every step, and
its maximum never exceeds the bound (all 4 bpd × 7 q × 7 steps).

## Surprises

- **#189 V5's ✅ at bpd 256 covered a real exceedance.** The 0.93% `binning_max` it tabulated
  against a 0.90% bound is one key whose widening remap (geometric-midpoint projection,
  `partition_extend`) put counts of a value into a bin that does not contain it. Per-key
  widenings are rare here (7 in 4,153 keys), so the effect is one row; after merges the same
  projection runs on 73–88% of operations and the bound fails on 0.4–22% of them (pairs at bpd 616 P99: 99.60% within; fold step 7 at bpd 256 P90: 78.0%).
- **G's larger median error at the tails on this file is a property of integer-millisecond data,
  not of the grid**: 159 of the 328 keys have P99 exactly 1, 10 or 100 ms, and a power of ten is
  the lower boundary of a G bin. T has the same behaviour whenever its seed puts the first sample
  on a boundary (bpd 256), and looks *better* at bpd 616 only because float rounding lands the
  first sample at the top of a bin. Neither arm violates the bound; the error distribution
  inside the bound is data-shaped.
- The rank-convention crossover reproduces for G at the same tier as for T (bpd ≈ 256): the
  effect is a property of `ceil` vs `int` on tied tails, not of the geometry.
- `grid_index(1000)` is 158 at bpd 53 (checked 159): the value 1000 is counted in bin
  `[957.5, 1000)`, at the *top* of a bin it is not in (probe 1: spike error `−0.0434%`). Within
  the bound; owned by V1.

## Findings and actions

1. **G holds the one-bin structural bound on the #189 primary surface at every tier, per key
   (328 keys × 7 q × 4 bpd), on every small-N key (2,517 × 7 × 4), after one merge (1,258 pairs)
   and after seven merges (314 groups × 7 steps)** — `binning_max` ≤ `10^(1/bpd) − 1` in every
   scope with within-one-bin = 100.00% throughout. The #426 V8 claim (DPM log, bpd 53) holds on
   the Tomcat surface at 53, 115, 256 and 616.
2. **T holds the bound per key at 53, 115 and 616 and fails it on one key at 256** (0.9336% vs
   0.9035%); it fails it after merges at every tier (worst 1.35–1.48 bins after one merge,
   1.36–2.06 bins after seven; within-one-bin down to 78% at bpd 256 P90). The mechanism in
   both cases is the remap of counts by geometric midpoint into a geometry whose boundaries do
   not contain the original values (`partition_extend`, `partition_rebin` via
   `merge_bin_counter_entries`). S inherits this exactly (digest parity).
3. **#187 Decision 1 (the walk, `ceil(q·N)`, `rank_in_bin`, exponential in-bin interpolation)
   is unchanged by the representation**: G runs it verbatim over grid boundaries and produces
   the same error envelope as T where no remap is involved, and the same rank-convention
   crossover at bpd ≈ 256. No amendment to Decision 1 is indicated by this aspect.
4. **#187 R4's accuracy contract ("structural, derived from partition geometry and the Decision 1
   formula") is not met by today's primitives once a partition has been remapped** — by
   widening (Decision 5) or by merge (#189 R12 / #201 `partition_rebin`). Under G the contract
   is literally structural: no count ever moves, so the bound is a property of the grid alone
   and holds after any number of merges. Evidence for the architect's #187 D5 decision, which
   this aspect does not make.
5. **#189 V5 finding 1 ("R4 within the structural bound across all 4,153 partitions × 7
   quantiles × 4 precision levels") needs a correction**: it held for 327 of 328 N ≥ 100 keys at
   bpd 256, and its own table showed the 0.93% > 0.90%.
6. Interpretation guidance carried to whichever ticket documents R4: on integer-millisecond data
   the error inside the bound concentrates at the bin edge for spike values that are powers of
   ten (G always; T when `int(5·bpd)` is even). Mean signed bias is positive in both arms
   (G +2.5%, T +1.5% at P95, bpd 53) — percentiles from bins are biased upward toward the bin's
   upper boundary for tied tails.

## Reproduction

```
# all four tiers, one process each (≈ 20–40 s per tier; parity asserted in the bpd 53 run):
sh prototype/426-revalidate-v5-run.sh
#   -> prototype/426-results/revalidate-v5-bpd{53,115,256,616}.txt + the TSVs + revalidate-v5-summary.tsv
# a single tier / options:
perl prototype/426-revalidate-v5.pl --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
     --bpd 256 --arm T,G --parity-bpd 53 --min-N 100 --fold-size 8 --tsv-prefix prototype/426-results/revalidate-v5
# condensed tables (§ A–F quoted above):
perl prototype/426-revalidate-v5-tables.pl prototype/426-results/revalidate-v5 > prototype/426-results/revalidate-v5-tables.txt
# mechanism probes (boundary placement; the bpd 256 exceedance row):
perl prototype/426-revalidate-v5-probe.pl --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
     --bpd 256 --ordinal 75 --q 0.75 > prototype/426-results/revalidate-v5-probe.txt
```

Exit status of the driver is 1 because the bpd 256 process reports the T key-scope FAIL (finding
2); every other process exits 0.
