# #426 revalidation — V3: seeding heuristic, span growth, overflow/underflow audit

Mirror of #189 V3 (`prototype/189-bin-counter-primitives-validation-report.md` § V3) against the three arms of `prototype/426-revalidate-lib.pm`: **T** (production primitives verbatim), **S** (span-only columnar, verbatim geometry, P8+P9), **G** (shared log-spaced grid, span-only, P10). Under G there is no seed, no rebin and no overflow/underflow — an index exists for every positive value — so the aspect is re-read as the span-growth and out-of-range story. Script: `prototype/426-revalidate-v3.pl`; driver: `prototype/426-revalidate-v3.sh`. Every number below is in a `prototype/426-results/revalidate-v3-*.txt|tsv` file named per table.

## Hypothesis

1. T reproduces #189 V3 Part A on the 277 MB Tomcat file (4,153 partitions, 7 rebin events, p99 0, max 1) and S is digest-identical to T at bpd 53 and 616.
2. Under G a key's storage is its occupied span, `hi_index − lo_index + 1` slots; on real data that span is smaller than T's seeded 265 (bpd 53) / 3,080 (bpd 616) bins for every key, and the total slots stored are a small fraction of T's.
3. #189 V3 Part B: T with the rebin cap at 0 still fires `high`/`low` at the expected quantiles (#187 D4); T without the cap contains every outlier by doubling (D5); G returns audit `none` everywhere by construction and its values stay within one bin of the exact oracle, so the D4 contract has nothing to bound.
4. G needs no growth cap: its worst case is bounded arithmetically by `bpd × decades-of-data + 1`, which is smaller than T's doubled partition for the same data.
5. Non-positive values are rejected by no arm; the caller guard (`$duration > 0` at every `counter_update` call site in `ltl`) is what keeps them out, in every arm.

## Method

- **Part A** (`--part A`): stream `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (1,430,678 lines, 857,480 positive durations, 573,198 zeros excluded, 4,153 keys with a positive duration) into each arm. One arm per process for timing (one untimed warmup + 3 timed builds, median with min–max) and memory (`Devel::Size::total_size` of the store and process RSS delta around the first build); `--arm all` in one process for the T/S digest assertion and the per-key T-vs-G comparison (per-key TSV written). bpd 53 and 616.
- **Part B** (`--part B`): the three #189 V3 scenarios (warmup 1,000 values at `v0·(0.5 + j/1000)`, deterministic instead of #189's `rand()`, then the outliers), each built five ways — T cap 0, S cap 0, T no cap, S no cap, G — with `S canonical == T canonical` asserted in both cap states; R4 at q 0.001/0.5/0.999 with audit and relative error against the exact nearest-rank oracle; bytes = `Devel::Size` of the T entry / the S or G column set. Plus a 12-decade key (1,000 near 100 + one sample per decade 1e-3…1e9, three insertion orders) and the 1..1e9 worst case (one value per grid bin, three first-values; endpoints-only variants). bpd 53 and 616.
- **Part C** (`--part C`): `grid_index` and every arm's `add` on 0, −1, 1e-320 and 1e308, fresh key and after a healthy `add(100)`, under a 5 s alarm.

## Result

### Part A — real data (277 MB Tomcat), per-arm processes

Source: `revalidate-v3-partA-arm{T,S,G}-bpd{53,616}.txt`; digests and per-key comparison from `revalidate-v3-partA-all-bpd{53,616}.txt`.

| bpd | arm | build median (min–max) s | Devel::Size | RSS delta | telemetry |
|---|---|---|---|---|---|
| 53 | T | 5.644 (5.572–5.649) | 9.28 MB | 11.45 MB | partitions 4153, rebin events 7, partitions_with_rebins 7 (0.1686%), max bins 397, rebins p50/p95/p99/max 0/0/0/1, overflow 0, underflow 0 |
| 53 | S | 5.388 (5.312–5.388) | 3.83 MB | 6.45 MB | identical 12 fields to T |
| 53 | G | 5.180 (5.161–5.184) | 2.37 MB | 3.80 MB | partitions 4153, span slots p50/p95/p99/max 1/26/78/175, index range [0,302] (5.72 decades) |
| 616 | T | 5.761 (5.732–5.792) | 56.72 MB | 65.58 MB | partitions 4153, rebin events 7, max bins 4619, rebins p50/p95/p99/max 0/0/0/1, overflow 0, underflow 0 |
| 616 | S | 5.389 (5.374–5.393) | 8.38 MB | 11.22 MB | identical 12 fields to T |
| 616 | G | 5.139 (5.108–5.193) | 6.92 MB | 8.58 MB | span slots p50/p95/p99/max 1/294/907/2028, index range [0,3517] (5.71 decades) |

- #189 V3 Part A reproduced exactly: `partitions_total: 4153 / partitions_with_rebins: 7 (0.1686%) / total_rebin_events: 7 / p50=0 p95=0 p99=0 max=1`, healthy-seed signal PASS.
- T and S digests identical: bpd 53 `3962d9c26ac17c07388d8a02149c3fb0`, bpd 616 `8bb68875349ae9f8b67aade39c51e907`; telemetry fields identical (excluding `counter_memory_bytes`).

Per-key G span vs T bin_count (`revalidate-v3-partA-all-bpd*.txt`; rows in `revalidate-v3-partA-perkey-bpd*.tsv`):

| bpd | keys | T at seed size / grown | G span > T bin_count | G span > T bins array length | G span > seed | span/bin_count p50 / p95 / p99 / max | Σ T bin_count | Σ T bins array length | Σ G span slots | Σ G occupied bins | G/T slots |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 53 | 4153 | 4146 / 7 | **0** | 0 | 0 | 0.0038 / 0.0981 / 0.2943 / 0.5811 | 1,101,469 | 569,388 | 29,442 | 8,738 | 0.0267 (0.0517 vs array length) |
| 616 | 4153 | 4146 / 7 | **0** | 0 | 0 | 0.0003 / 0.0955 / 0.2945 / 0.5789 | 12,802,013 | 6,593,714 | 304,466 | 11,207 | 0.0238 (0.0462 vs array length) |

The widest G span (175 slots at bpd 53, 2,028 at 616 — 3.3 decades) belongs to `[200] POST …PTCDTS.ScorecardImpl.Manager/Services/GetMetricsList` (n=23), a key T also rebinned to 397/4,619 bins. Six of the seven keys T rebinned have G `lo=0` (a 1 ms sample; T seeded from a first sample in the hundreds of ms, so min ≈ 3 ms could not hold it); the seventh (`GetShiftSummaryReportData`) grew upward (lo 89, hi 241 at bpd 53). G's per-key cost tracks the data's own range (median 1 slot: 2,000+ keys have a single distinct bin), T's tracks the seed.

### Part B — pathological scenarios (`revalidate-v3-partB.txt`)

Audit and counters, bpd 53 (bpd 616 identical in audit/counters; values differ only in bin width):

| scenario | T cap 0: over / under; audit q0.001 / q0.5 / q0.999 | T no cap: bin_count, rebins, bytes; audit | G: span slots (lo..hi), occupied, bytes; audit |
|---|---|---|---|
| extreme high (v0=100; 1e6,1e7,1e8) | 3 / 0; none / none / **high** (q0.999 = 15811.4, −99.84% vs exact 1e7) | 530, 2, 7,820 B; none ×3 (q0.999 = 1.02398e7, +2.40%) | 335 (90..424), 29, 4,731 B; none ×3 (q0.999 = 1e7, +0.00%) |
| extreme low (v0=10000; 0.5,0.1,0.01) | 0 / 3; **low** / none / none (q0.001 = 15.81 vs exact 0.1) | 530, 2, 6,892 B; none ×3 (q0.001 = 0.1024, +2.40%) | 328 (−106..221), 29, 11,907 B; none ×3 (q0.001 = 0.1044, +4.44%) |
| mixed (v0=1000; 50×1e-3, 50×1e8) | 50 / 50; **low** / none / **high** | 794, 2, 9,380 B; none ×3 (q0.001 −1.27%, q0.5 −2.12%, q0.999 +1.66%) | 584 (−159..424), 28, 14,067 B; none ×3 (+0.17% / −0.10% / +4.35%) |

- #189 V3 Part B's table (3/0 high·none·none; 0/3 none·none·low; 50/50 high·none·low) reproduces under T cap 0 at both bpd; `S canonical == T canonical` in every scenario, both cap states, both bpd (30 PASS lines).
- Under T no cap every outlier is contained by doubling (2 rebins) and every audit is `none`; under G every audit is `none` structurally. G's worst error at the audited quantiles is one bin width (4.44% at bpd 53; 0.37% at 616), T no cap's is 2.40% at 53 / 0.21% at 616 — both inside the bound; T cap 0 returns the partition edge (−99.84% / +15,711%), which is what D4 specifies.

12-decade key (1,013 samples), bpd 53 / 616:

| insertion order | T no cap bin_count (rebins), bytes | T cap 0 over / under | G span (lo..hi), occupied, bytes |
|---|---|---|---|
| 1,000 near 100, then 1e-3..1e9 ascending | 662 (3), 10,212 B / 7,700 (3), 86,732 B | 5 / 3 | 636 (−159..476), 38, **12,851** B / 7,392 (−1848..5543), 307, 143,203 B |
| 1e-3..1e9 ascending, then near-100 | 794 (4), 10,292 B / 9,239 (4), 100,764 B | 1010 / 0 | 636, 38, **6,995** B / 7,392, 307, 73,867 B |
| 1e9 first, descending, then near-100 | 794 (4), 10,292 B / 9,239 (4), 86,668 B | 0 / 1010 | 636, 38, **21,347** B / 7,392, 307, 243,907 B |

G's span is order-independent (636 = 12 decades × 53; 7,392 = 12 × 616) and its percentiles are identical across the three orders (q0.001 0.010444, q0.5 100.189, q0.999 1.0444e8 at bpd 53). T's geometry is order-dependent (662 vs 794 bins; 12.5 vs 15 decades) and so are its percentile values (q0.5 98.85 / 100.10 / 100.01). G's **bytes** are order-dependent: 6,995 → 12,851 → 21,347 B for the same 636-slot span, because growth downward (`splice … (0) x n`) materialises real zero scalars while growth upward leaves `undef` slots.

Worst case, integer ms 1..1e9 (one value per grid bin, `revalidate-v3-partB.txt` "worst case"):

| bpd | closed form G max span | first value | T bin_count (rebins), decades, bins array length, entry bytes | S column bytes | G span, bytes | G/T slots, bytes |
|---|---|---|---|---|---|---|
| 53 | 477 (= 9×53+1) | 1 / 1000 / 1e9 | 662 (1) / 662 (2) / 662 (1), 12.50, len 610 / 583 / 530, 37,228 / 37,260 / 36,380 B | 18,233 / 18,489 / 18,233 | 477, 16,235 / 16,483 / 16,235 B | 0.721, 0.436–0.446 |
| 616 | 5,544 (= 9×616+1) | 1 / 1000 / 1e9 | 7,700 (1) / 7,700 (2) / 7,700 (1), 12.50, len 7,085 / 6,777 / 6,160, 415,628 / 416,028 / 405,644 B | 180,409 / 183,361 / 180,345 | 5,544, 178,379 / 181,331 / 178,379 B | 0.720, 0.429–0.440 |

Endpoints only (1 and 1e9, two samples): bpd 616 T 7,700 bins (1 rebin), 60,732 B (1 first) / 50,876 B (1e9 first); G 5,544 slots, 45,371 B when 1 comes first (upward growth, undef slots) but **178,379 B when 1e9 comes first** (downward growth, zero-filled) — the same as the fully occupied span.

### Part C — non-positive and extreme values (`revalidate-v3-partC.txt`, bpd 53)

| value | `grid_index` | T / S add (fresh key) | G add (fresh key) | T / S add after add(100) | G add after add(100) |
|---|---|---|---|---|---|
| 0 | dies `Can't take log of 0` | dies `Illegal division by zero` (partition_new: `log(max/min)` with min=max=0) | dies `Can't take log of 0` | dies `Illegal division by zero` (partition_extend: `new_min /= factor` until min underflows to 0, then `log(max/min)`) | dies `Can't take log of 0` |
| −1 | dies `Can't take log of -1` | **HANGS** (infinite loop in `partition_extend`: `new_min /= factor` with a negative min never falls below −1) | dies `Can't take log of -1` | **HANGS** (same loop) | dies |
| 1e-320 (denormal) | −16961 | accepted; then add(100) dies `Can't take log of 0` (partition_extend remap, `log(midpoint/new_min)` with an underflowed midpoint) | accepted, span 1; then add(100) accepted (span 17,068) | accepted, rebins 1, **bin_count = Inf** (`Non-finite repeat count` warning in S) | accepted, span 17,068 |
| 1e308 | 16324 | accepted with max = Inf, p50 = NaN; add(100) accepted | accepted, p50 1.0444e308; add(100) accepted | accepted, max = Inf, bin_count = Inf | accepted, span 16,219 |

Every `counter_update` call in `ltl` (lines 10775, 10889, 11029/11030, 11143/11144) is gated `> 0` by its caller; the primitives themselves have no guard in any arm.

## Surprises

1. **A negative value hangs T and S, it does not die.** `partition_extend`'s `while ($value < $new_min) { $new_min /= $double_factor }` runs forever when min is negative (min → 0⁻, never ≤ −1). Today the caller guard prevents it; G fails loudly (`log` dies) instead of looping.
2. **G's memory for a given span depends on insertion order** (3× between the two 12-decade orders; 4× on the endpoints-only worst case): downward growth splices real `0` scalars, upward growth leaves `undef` slots that Perl stores as NULL pointers. S has the same `(0) x $shift` splice in `_bump_offset_dense` but its spans are narrow on real data. Not a correctness issue (digests/percentiles unaffected); a memory-implementation detail for the P9/P10 span array.
3. **Six of T's seven rebins on the 277 MB file are downward to 1 ms**, not upward outliers: the first sample of those keys sat in the hundreds of ms, the seed's lower edge (v0/316) excluded a later 1 ms sample. G's grid index 0 (value 1) covers it without any state change.
4. T's `bins` array length is well below `bin_count` on every key (Σ 569,388 vs 1,101,469 at bpd 53): the verbatim store never zero-fills up to `bin_count`, so #189's `counter_memory_bytes` already reflects a partially sparse array, and G's advantage measured against the array length (0.0517) is the honest one, not the ratio against `bin_count` (0.0267).

## Findings and actions

1. **#189 V3 Part A reproduced; S is parity-identical to T** (digests `3962d9c2…` / `8bb68875…`, 12 telemetry fields equal, 30/30 canonical matches in Part B). S changes nothing in this aspect — #187 D4 and D5 apply to S verbatim, including the rebin telemetry and the audit.
2. **Under G, #187 Decision 5 (seed, HdrHistogram doubling, rebin telemetry) becomes vacuous, not violated.** There is no first-value seed, no `partition_extend`, no rebin count; `total_rebin_events`, `max_partition_bins`, `rebins_per_partition` and `partition_keying`'s partition geometry have no G equivalent. The evidence that motivated D5's tunable seed (p99 rebins in [0,2]) is replaced by span telemetry: p50/p95/p99/max slots 1/26/78/175 at bpd 53, 1/294/907/2028 at 616, global index range 5.7 decades. If G is adopted, D5 needs an explicit amendment naming what replaces it (span-only storage on a shared grid) and what the `-V` telemetry reports instead (span distribution, index range, occupied bins).
3. **Under G, #187 Decision 4 (overflow/underflow contract) and the `out_of_range_bounded` audit are structurally `none`.** No value is out of range (Part C: any positive double gets an index; 1e-320 and 1e308 both accepted). The R4 branches that return `boundary[0]`/`boundary[B]` with `low`/`high` are unreachable; `partitions_with_overflow_count` / `partitions_with_underflow_count` / `overflow_total` / `underflow_total` are identically 0. The audit field can stay in the `-V` format as a constant `none` (as #34's consumers already fall back to) or D4 can be amended to say the shared grid has no out-of-range state; either way #189's "use `--max-rebins 0` to test R6" guidance has no G counterpart because there is no R6 path to test.
4. **G needs no growth cap.** Its span is bounded by `bpd × log10(max/min) + 1` of the key's own data: 477 slots at bpd 53 / 5,544 at 616 for 1..1e9, which is 0.72× T's doubled partition (662 / 7,700 bins, 12.5 decades for 9 decades of data) and 0.43–0.45× its bytes. On real data no key's span exceeds T's seed (0 of 4,153 at both bpd) and the total slots stored are 2.4–2.7% of T's `bin_count` sum (4.6–5.2% of its actual array lengths). A cap would be a memory policy for adversarial keys, not a correctness need — and T has none today either (its comment: "only reachable when a future growth cap is added — none today").
5. **The non-positive guard must stay at the caller (or move into the store's `add`) under every arm.** G dies on 0 and negatives (`log`), T/S die on 0 and **loop forever on negatives**. The lib arms assume the guard as ltl's call sites do (`if ($duration > 0)` at ltl 10768/10887/11029/11128); the P8–P10 store's write path must carry the same guard. Extreme doubles (1e-320, 1e308) break T's geometry (`bin_count = Inf`, `p50 = NaN`) but not G's; not reachable from parsed durations, recorded for completeness.
6. **Span-array memory should grow with `undef`, not `0`, when extending downward** (Surprise 2): the same 636-slot span costs 6,995 B or 21,347 B depending only on order. Applies to both S (`_bump_offset_dense`) and G (`add`/`merge`); `bins_pairs`, `percentile` and canonical already treat `undef` as 0. Not changed in the lib for this aspect (would alter S/G memory numbers other aspects captured).
7. **Accuracy at the audited quantiles**: T no cap within 2.40% (bpd 53) / 0.21% (616) of the exact value on the outlier scenarios; G within one bin width (4.44% / 0.37%) and exact at q0.999 of the high-outlier case; T cap 0 returns the partition edge (D4's contracted behaviour). G's percentiles are insertion-order-independent; T's shift with order (q0.5 98.85 vs 100.10 on the 12-decade key).

## Reproduction

```
bash prototype/426-revalidate-v3.sh            # everything below; ~4 min; writes prototype/426-results/revalidate-v3-*.txt|tsv
# individually:
perl prototype/426-revalidate-v3.pl --part A --arm T --bpd 53 --runs 3 \
    --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt   # also --arm S / G, --bpd 616
perl prototype/426-revalidate-v3.pl --part A --arm all --bpd 53 --runs 0 \
    --file logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
    --per-key prototype/426-results/revalidate-v3-partA-perkey.tsv                       # digest assertion + per-key T vs G
perl prototype/426-revalidate-v3.pl --part B --bpd 53,616
perl prototype/426-revalidate-v3.pl --part C --bpd 53
```

Exit status is non-zero on any T/S divergence or failed audit expectation; every capture ends `ALL PASS`, driver `exit=0` (`revalidate-v3-driver.txt`).
