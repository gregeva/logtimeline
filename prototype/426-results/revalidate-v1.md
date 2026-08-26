# V1 — In-bin edge cases, R2 cross-check, determinism (#426 revalidation of #189 V1)

Prototype: `prototype/426-revalidate-v1.pl` (library `prototype/426-revalidate-lib.pm`, unchanged).
Captured runs: `revalidate-v1-partA.txt`, `revalidate-v1-partBC-2025-05-05.txt` (+ `.time.txt`),
`revalidate-v1-r2-offenders.tsv`, `revalidate-v1-determinism.tsv` — all in `prototype/426-results/`.
Arms: **T** production primitives verbatim; **S** span-only columnar, verbatim geometry (P8+P9);
**G** shared log-spaced grid, span-only (P10). Every Part A scenario also asserts the T↔S digest.

## Hypothesis

The #187 Decision 1/1A walk is arithmetic over `(lower, upper, rank_in_bin, count)` and does not
care where the bin boundaries come from, so every #189 V1 edge case should hold on G with the
same value/audit semantics — except the ones that exist only because T has per-key partition
state (`lower = upper`, zero-count partition, overflow/underflow), which become vacuous.
The R2 cross-check should reproduce #189's zero disagreements, with the known exception of
exact powers of ten (the closed form `floor(bpd·log10 v)` lands one ULP low on a grid boundary).
#189 R5 (determinism for a fixed sequence) should hold for both arms; G should additionally be
order-independent and merge-commutative because it has no seed and no remap.

## Method

**Part A** (`--part A`, bpd 53 and 616): the eight #189 V1 scenarios re-read for G (A1 `bin_count=1`,
A2 `lower=upper`, A3 single observation, A4 `fraction=0`, A5 zero-count, A6/A7 all-overflow /
all-underflow — direct entry as #189 did, plus through the store under `max_rebins=0` with the same
inputs fed to G), A8 exact powers of ten, A9 values exactly at `10**(i/bpd)`, A10 tiny/huge values
(1e-3, 1e-6, 1e12, separately and in one key), A11 value 0 and −5 under a 5 s alarm, first-sample and
on an existing partition, for T, S and G, A12 identical value × N (1, 2, 1000), 7 quantiles, both
rank conventions.

**Part B** (`--part BC`, 277 MB `localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`,
read once — 1,430,678 lines, 857,480 positive durations, 4,153 keys, 985 distinct values): for every
distinct value (weighted by occurrences) G closed-form index vs boundary-checked index at bpd 53,
115, 256, 616; T vs S full-file digests at bpd 53 and 616.

**Part C** (same run): the first 200 keys (sorted key order) with N ≥ 20 (764 eligible; N 20..137,670),
fed in file order, reversed, and `srand(426)` shuffle; per-key canonical string, geometry and 7
percentiles (`ceil`) compared across orderings for T and G. Then merge(a,b) vs merge(b,a) with
`drop_source` for 200 consecutive-key pairs (keys 0..200), comparing the canonical string, the
bins+geometry (T: absolute boundary→count pairs, so the comparison is independent of the
partition-relative index), and the 7 percentiles.

No timing (V1 has no timed hypothesis); memory reported as `Devel::Size` + RSS delta in Part B.

## Result

### Part A — 92 PASS, 0 FAIL, both bpd (`revalidate-v1-partA.txt`)

| # | scenario | T (verbatim) | G (grid) | S |
|---|---|---|---|---|
| A1 | `bin_count=1` (one sample =100), q 0.5/0.99 | returns upper of bin 132, audit none (102.196 @53) | returns grid upper of index 106, audit none (104.440 @53); span=1 | digest = T |
| A2 | `lower=upper` | synthetic partition (min=max=1, bins [3]) returns 1 for q 0.1..0.99 as #189; **unreachable through `partition_new`** (min 0.00316 < max 316.2 for v0=1) | **cannot occur**: `10**(i/bpd) < 10**((i+1)/bpd)` verified for i ∈ [−2000, 2000] at both bpd — vacuous | — |
| A3 | single observation (42) | upper of bin 132: 42.922 (+2.196%) @53; 42.000 (+0.0000%) @616 | grid upper of index 86: 43.804 (+4.294%) @53; index 999: 42.012 (+0.029%) @616 | digest = T |
| A4 | `fraction=0` | unreachable (`target_rank <= cum`) | same walk, same property | — |
| A5 | zero-count | entry with empty bins → `(undef,'none')`; unknown key → `(undef,'none')` | unknown key → `(undef,'none')`; **no partition state exists to be zero-count** — a G row exists only after its first add | same |
| A6 | all-overflow | direct entry (overflow=5) q=0.9 → boundary[B]=316.23, audit high; store cap=0, seed 1 + 5×1e6 → overflow=5, rebins=0, q=0.9 → 316.23 audit high — **22.5 bins (@53) / 266.9 bins (@616) below the true value** | same inputs: span 318 [0..317] @53 (3696 @616), q=0.9 → 1,000,000 audit none, rel err 0 | digest = T under the cap |
| A7 | all-underflow | direct entry q=0.1 → boundary[0]=0.00316 audit low; store cap=0, seed 1 + 5×1e-6 → underflow=5, q=0.1 → 0.00316 audit low (rel err 3.16e3) | span 319 [−318..0], q=0.1 → 1.0087e-6 audit none (0.87%, within one bin) | digest = T |
| A10 | 1e-3, 1e-6, 1e12 alone | seeded partitions min..max around each; q=0.5 within one bin | indices −159/−318/635 @53, −1848/−3696/7391 @616; within one bin | digest = T |
| A10 | one key {1e-6, 1e-3, 1, 1e12} | 3 rebins, bin_count 1192 @53 / 13,859 @616; 'int' errors vs oracle: max **0.96 bins @53, 1.38 bins @616** (q=0.5 after three remaps) | span 954 slots @53 / 11,088 @616; every quantile ≤ 1.00 bins (single-count bins return upper) | digest = T |
| A11 | value 0 | first sample: `partition_new` dies `Illegal division by zero` (lib line 243, `log(max/min)` = log(0/0)); on an existing partition: `partition_extend` divides `new_min` by 10^2.5 130 times until it underflows to 0, then dies `Illegal division by zero` at `log(new_max/new_min)` (lib line 274) | `add` dies `Can't take log of 0` (lib line 1161) at both points | S first-sample dies at line 923 (its `log(pmax/pmin)`), existing → same line 274 |
| A11 | value −5 | **unbounded loop, alarm fired** at both points: first-sample `partition_new(−5)` gives min=−0.0158 > max=−1581, `bin_assign` says UNDERFLOW, the extend loop multiplies `new_max` (negative) forever; existing partition: `new_min` reaches 0 after 130 steps and `−5 < 0` stays true forever | dies `Can't take log of -5` | same loop as T |
| A12 | 250 × N (1, 2, 1000) | 1 occupied bin; max rel err 2.196% (0.49 bins) @53; 0.00 / 0.50 / 0.99 bins @616 for N=1/2/1000 | span 1; max rel err 4.029% (0.91 bins) @53, 0.325% (0.87 bins) @616 | digest = T |

A8 — exact powers of ten (`grid_index` closed form vs boundary check; both bpd give the same pattern):

| value | closed i @53 | checked @53 | closed i @616 | checked @616 | v in closed bin? | G q=0.5 (single add) | T bin / q=0.5 |
|---|---|---|---|---|---|---|---|
| 1, 10, 100, 1e4 | 0, 53, 106, 212 | same | 0, 616, 1232, 2464 | same | yes | upper: +4.4403% @53, +0.3745% @616 | bin 132 / +2.196% @53; bin 1539 / +0.0000% @616 |
| 1000, 1e5, 1e6, 1e9 | 158, 264, 317, 476 | 159, 265, 318, 477 | 1847, 3079, 3695, 5543 | +1 each | **no** (v == upper of the closed bin) | +0.0000% (returns upper = v exactly) | same as above |

4 of 8 powers of ten land one index low in the closed form; the single-add G percentile for those
returns `upper` = the value itself, so the attribution error is 0, not one bin.

A9 — values `v = 10**(i/bpd)` exactly: @53 closed form == i for i ∈ {7, 53, 100, 106, 200}, one low
for {1, 159, 265}; @616 == i for {1, 616, 1232}, one low for {7, 1000, 1848, 3000, 3080}. In every
one-low case the G percentile returns `upper` = v (0.0000%); in every exact case it returns one bin
above. T's own closed form shows the same ULP behaviour: a single power-of-ten sample seeded at the
partition centre lands in bin 132 of 265 @53 (`int(132.5)`) and in bin 1539 of 3080 @616
(`int(1540 − ε)`), whose upper is the value itself (+0.0000%).

### Part B — R2 cross-check and full-file parity (`revalidate-v1-partBC-2025-05-05.txt`)

| bpd | distinct values | observations | disagreements (values / obs) | offending values | bound holds after check |
|---|---|---|---|---|---|
| 53 | 985 | 857,480 | 1 / 38 | 1000 (closed 158 → checked 159, exact power of ten) | yes |
| 115 | 985 | 857,480 | 1 / 38 | 1000 (344 → 345) | yes |
| 256 | 985 | 857,480 | 1 / 38 | 1000 (767 → 768) | yes |
| 616 | 985 | 857,480 | 1 / 38 | 1000 (1847 → 1848) | yes |

No floating-point near-boundary case other than the exact power of ten occurred on 985 distinct
integer-millisecond values (`revalidate-v1-r2-offenders.tsv`).

| bpd | T digest | S digest | G digest | keys | T rebins | T max bins | G span p50/p95/p99/max | G index range | Devel::Size T / S / G | RSS delta (T+S+G) |
|---|---|---|---|---|---|---|---|---|---|---|
| 53 | 3962d9c2… | 3962d9c2… (= T) | 8d5853ad… | 4,153 | 7 events, max 1 | 397 | 1 / 26 / 78 / 175 | [0, 302] | 10,041,750 / 3,609,728 / 2,079,602 B | 14,656 kB |
| 616 | 8bb68875… | 8bb68875… (= T) | 6244c86c… | 4,153 | 7 events, max 1 | 4,619 | 1 / 294 / 907 / 2,028 | [0, 3517] | 59,894,726 / 8,379,432 / 6,849,386 B | 69,424 kB |

T rebin telemetry (7 events, p99 = 0, max = 1 across 4,153 partitions) equals #189 V3's figures on
the same file. Whole run: 17.2 s wall, 174 MB max RSS (`.time.txt`).

### Part C — determinism (`revalidate-v1-determinism.tsv`)

| bpd | arm | orderings: keys canonical-different | percentiles different | max diff (rel / bins) | geometry different | merge pairs: canonical different | bins+geometry different | percentiles different |
|---|---|---|---|---|---|---|---|---|
| 53 | T | 105 / 200 | 105 | 3.877% / 0.873 | 105 (1 key rebinned in some ordering) | 2 / 200 | 0 | 0 |
| 53 | G | 0 / 200 | 0 | 0 | — | 0 / 200 | 0 | 0 |
| 616 | T | 105 / 200 | 105 | 0.369% / 0.985 | 105 | 2 / 200 | 0 | 0 |
| 616 | G | 0 / 200 | 0 | 0 | — | 0 / 200 | 0 | 0 |

T's two canonical-string merge differences are pairs (130,131) and (131,132): the canonical string
carries `rebins`, which `partition_rebin` resets to 0 on the rebinned side but leaves on a target
whose geometry already matches the union; bins and boundaries are identical in both directions.

## Surprises

- **Negative values hang the verbatim `partition_extend`** (A11): `partition_new` on a negative v0
  produces min > max (both negative); the doubling loop then never terminates. Value 0 terminates
  by dying (`Illegal division by zero`) after 130 doublings. Production never passes either
  (ltl guards `> 0` before `counter_update`), but the primitive itself has no guard. G dies
  immediately on both (`log` of a non-positive).
- **All-overflow on T is a 22–267 bin error** (A6): with the growth cap at 0, five samples at 1e6
  after a seed at 1 make T report q=0.9 as 316.2 (`boundary[B]`, audit high) — Decision 4's
  "at least this large" semantics is exact but the value is off by 6 decades; G with the same
  inputs answers 1e6 exactly with a 318-slot span.
- **T's remap breaks the one-bin bound on a wide-range key** (A10 @616): three doublings accumulate
  to 1.38 bins at q=0.5 for {1e-6, 1e-3, 1, 1e12}; G stays at ≤ 1.00 bins — the same mechanism
  #426 V8 measured after merges, seen here through `partition_extend` alone.
- **T is order-dependent at the digest and percentile level** (C1): 105 of 200 keys change
  canonical string and percentiles when the same samples arrive reversed or shuffled (the seed is
  the first sample), by up to 0.87–0.99 bins. #189 R5 only promises determinism for a fixed
  sequence, which still holds; the cross-ordering variance is a property Decision 5 has and G does
  not (0 of 200 keys, 0 of 200 pairs).
- The R2 cross-check's only disagreement on real data is the value 1000 (38 occurrences), the same
  case the library self-test flagged. It is an ULP effect of `log(1000)/log(10)` in the closed
  form, not a grid defect; the boundary-checked index restores the bound on every value.

## Findings and actions

1. **#187 Decision 1/1A hold on G unchanged.** Every reachable hand-computable case (A1, A3, A4,
   A12) produces the same value/audit semantics on the grid as on the partition: `bin_count=1` and
   single observation return `upper`, `fraction=0` is unreachable, N identical values stay within
   one bin for every quantile and both rank conventions (A12: G 0.91 bins @53, 0.87 @616). The
   formula is grid-agnostic. No amendment.
2. **Decision 1's `lower = upper` implementation-guidance case is vacuous on both geometries** (A2):
   `partition_new` cannot produce it (min < max for any v0 > 0) and the grid cannot by construction.
   #189 V1 tested it on a synthetic partition only. Action: record it as unreachable in the
   guidance; no code path needs it.
3. **Decision 4 (overflow/underflow, audit `high|low`) and #189 R6 become vacuous under G** (A5–A7):
   the grid has no partition edge, so no value is ever out of range, `total_N` has no over/under
   terms, and the audit is always `none`. Under P10 the `-V` fields
   `partitions_with_overflow_count / underflow_count`, `overflow_total / underflow_total` and the
   per-quantile `out_of_range_bounded` have nothing to report. What G does with T's cap inputs is
   answer exactly (A6/A7). Decision 4 needs an explicit amendment if P10 is adopted; the Decision 8
   `-V` field set is a consequence (V4's aspect).
4. **#189 R2's closed-form-vs-boundary agreement holds on real data except at exact powers of ten**
   (Part B: 1 of 985 distinct values, 38 of 857,480 observations, identical at bpd 53/115/256/616;
   Part A: 4 of 8 powers of ten, 3–5 of 8 exact grid boundaries). The disagreement is one index low
   and the affected value sits on the closed bin's upper boundary, so a percentile attributed to it
   returns exactly the value (0 error); the one-bin bound is not violated. T's own closed form has
   the same ULP property (A8: a power-of-ten sample at the partition centre lands in bin 1539 of
   3080 @616 instead of 1540). #189 V1 found zero disagreements because it compared three R2
   algorithms against the same computed boundary array, not against the analytic boundary. Action:
   choose one convention for the G grid index (closed form as-is, or the boundary-checked form at
   ~2 extra `**` per add) and record it; the digest baseline depends on the choice.
5. **Both representations need the same input guard** (A11): T loops forever on a negative value
   and dies on 0 after 130 doublings; G dies on both. ltl's existing `> 0` guard before
   `counter_update` is what protects T today; it must stay in front of any G `add`. Action: keep
   the guard at the caller (as today) or add `die unless $value > 0` in the primitive; #189 R2's
   "positive-only substrate" statement should say the primitive is undefined, not merely unused,
   for v ≤ 0.
6. **#189 R5 holds for both arms for a fixed sequence; G is additionally order-independent and
   merge-commutative** (Part C: 0/200 keys, 0/200 pairs at both bpd), whereas T's per-key state
   differs for 105/200 keys across orderings (up to 0.87–0.99 bins) and its merge is commutative on
   bins and boundaries (0/200) but not on the `rebins` telemetry field (2/200). Action: none for
   R5; under P10 the `-g` fold order stops mattering to the bin-mode baselines, and the "rebins"
   telemetry has no G counterpart (V3/V4 aspects).
7. **T↔S parity holds on the Tomcat access log** (Part B: digests identical at bpd 53 and 616 on
   4,153 keys; every Part A scenario including the `max_rebins=0` cap and the 0/−5 failure
   modes). P8+P9 carry #189 V1 by construction.
8. **The wide-range key shows the cost side of G's span-only bins** (A10): four samples spanning 18
   decades take a 954-slot span @53 (11,088 @616) — 9.3 KB / 96 KB by `Devel::Size` versus T's
   11.3 KB / 112 KB for its 1192 / 13,859-bin dense partition; comparable here, but G's span is
   proportional to the key's value range rather than capped by the seed. Part B on real data shows
   span p99 = 78 @53 and 907 @616 against T's fixed 265 / 3080 bins. Fan-out at scale is V2's
   aspect.

## Reproduction

```
cd /Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store
perl prototype/426-revalidate-v1.pl --part A > prototype/426-results/revalidate-v1-partA.txt 2>&1
/usr/bin/time -l perl prototype/426-revalidate-v1.pl --part BC \
    --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
    > prototype/426-results/revalidate-v1-partBC-2025-05-05.txt \
    2> prototype/426-results/revalidate-v1-partBC-2025-05-05.time.txt
# side files written by --part BC: revalidate-v1-r2-offenders.tsv, revalidate-v1-determinism.tsv
# options: --bpd 53,616  --check-bpd 53,115,256,616  --keys 200  --min-n 20  --seed 426  --arm T,S,G
```
