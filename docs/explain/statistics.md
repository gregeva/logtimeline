# LogTimeLine Statistics Reference

This page is the canonical reference for the statistics ltl emits in the summary table and the `-o` CSV outputs. Each section below mirrors the content of `ltl --explain <topic>` for the same statistic.

For a one-line index of all statistics, use `ltl --help statistics`. For the long-form per-statistic explanation directly from the terminal, use `ltl --explain <topic>`.

The CLI surface and this Wiki page are kept in sync: the heredoc strings in `ltl` and the prose below are siblings of the same content. If they drift, the test harness `tests/validate-explain.sh` should be extended to catch the drift.

---

## Range

### min

The smallest observed value of the metric across all log entries in scope. For latency analysis, `min` answers "what's the fastest this operation ever ran?" — the unloaded, cache-warm, fast-path response time. It's the floor below which no observation has ever fallen.

**Operational use.** The `min` is the most outlier-sensitive statistic ltl emits, but it's outlier-sensitive in the *opposite* direction from `max`: a single artificially-fast measurement (clock skew, cache effect, partial response) drags `min` toward zero. Read `min` alongside `p1` — if they diverge sharply, `min` is reporting a one-off floor and `p1` is reporting the real fast-path baseline. For SLO work, `p1` is almost always the better lower-bound signal than `min`.

**Example.**

```text
ltl -so min -n 20 access.log
```

**How ltl computes this.** First element of the sorted duration array per time bucket (or per message key when consolidating). One pass through the data; no approximation.

**See also.** `p1`, `p5`, `mean`, `max`, `percentiles`.

---

### max

The largest observed value of the metric across all log entries in scope. For latency analysis, `max` is the worst single response time — the slowest request, the longest GC pause, the most extreme outlier. It's the ceiling above which no observation has ever risen.

**Operational use.** The `max` is highly outlier-sensitive: one runaway request from any cause (lock contention, GC pause, retry storm, network anomaly) sets the value. Read `max` alongside `p999` and `p9999`: if `max` is far above `p9999`, the worst-case is a one-off event; if `max` is close to `p9999`, the heavy tail is consistent. For SLO ceilings, `p999` or `p9999` are usually the right tail-bound statistic, not `max` — but `max` answers the audit question "what's the worst that ever happened?" which `p9999` does not.

**Example.**

```text
ltl -so max -n 20 access.log
```

**How ltl computes this.** Last element of the sorted duration array per time bucket (or per message key when consolidating). One pass through the data; no approximation.

**See also.** `p99`, `p999`, `p9999`, `p99999`, `mean`, `percentiles`.

---

## Central tendency

### mean

The arithmetic average of all observed values: sum of values divided by count. For latency, `mean` answers "on average, how long does this operation take?" — the typical experience weighted equally across every request.

**Aliases.** `avg`

**Interpretation.**

| Comparison | Implication |
|---|---|
| `mean ≈ p50` | Distribution is roughly symmetric |
| `mean ≫ p50` | Right-skewed; mean inflated by tail outliers — prefer `p50` for typical value |
| `mean ≪ p50` | Left-skewed (unusual); check for hidden cap or timeout |
| `mean × count = total duration` | Use total duration (`-so duration`) for capacity-planning, not mean |

**Operational use.** The `mean` is highly sensitive to tail behavior: a single 10-second request mixed into 10,000 fast requests pulls the mean up significantly. This makes `mean` *misleading* for skewed distributions (which is most production latency data). Prefer `p50` (the median) when you want a "typical" value robust to outliers. Use `mean` when you specifically want a measure of *total work performed* — mean × count = total duration, which is the right signal for capacity-planning and impact-ranking analysis. ltl's `-so mean` ranks messages by average latency; `-so duration` ranks by total duration (= mean × count). The two answer different operational questions.

**Example.**

```text
ltl -so mean -n 20 access.log         # rank by average latency
ltl -so duration -n 20 access.log     # rank by total work (mean × count)
```

**How ltl computes this.** `total_duration / count` per time bucket (or per message key when consolidating). One pass through the data; exact.

**See also.** `p50`, `std_dev`, `cv`, `percentiles`, `impact`.

---

## Spread

### std_dev

Standard deviation measures *absolute spread* around the mean: how far observed values typically deviate from the average, in the same units as the original data. A latency stream with mean=100ms and std_dev=5ms is tightly clustered; one with mean=100ms and std_dev=50ms is highly variable. The square root of variance.

**Aliases.** `stddev`

**Interpretation.**

| Comparison | Implication |
|---|---|
| `std_dev < mean / 5` | Very tight distribution; predictable latency |
| `std_dev ≈ mean / 3` | Typical for well-behaved services |
| `std_dev ≈ mean` | High variance; investigate tail |
| `std_dev > mean` (i.e. `cv > 1`) | Long tail; mean is misleading — prefer `p50` / `iqr` |

**Operational use.** `std_dev` is the conventional spread statistic but has two limitations: (1) it scales with the absolute magnitude — a service with mean=10s and std_dev=1s and a service with mean=10ms and std_dev=1ms have *very different* operational characteristics but the same shape; (2) it assumes a roughly normal-shaped distribution, which latency data rarely is (latency is typically right-skewed with heavy tails). For relative spread that's scale-independent, use `cv` (= `std_dev / mean`). For robust spread that ignores tail outliers, use `iqr` (= `p75 - p25`). For raw spread in absolute units to combine with `mean`, `std_dev` is the right choice.

**Example.**

```text
ltl -so std_dev -n 20 access.log      # highest absolute spread
ltl -so cv -n 20 access.log           # highest relative spread
```

**How ltl computes this.** Computed as the sample standard deviation (the same convention as pandas `.std()`, R `sd()`, and Excel `STDEV.S`): square root of the sum of squared deviations from the mean, divided by `n − 1`. Requires `n ≥ 2`; emitted blank for single-observation buckets. Single-pass O(n) via a sum-of-squares accumulator; a floor at zero guards floating-point underflow on near-constant data.

**See also.** `mean`, `cv`, `iqr`, `skewness`, `kurtosis`.

---

### cv (Coefficient of Variation)

`cv = std_dev / mean`. CV measures *relative* spread: a service with CV=0.05 has values clustered within ~5% of the mean; a service with CV=2.0 has values varying by 200% of the mean. Because CV normalizes by the mean, it's scale-independent — a microsecond-latency service and a multi-second-latency service can be compared directly.

**Interpretation.**

| CV value | Distribution character | Operational meaning |
|---|---|---|
| `< 0.1` | Very tight | Predictable; CV alone is unlikely to surface anomalies |
| `0.1 – 0.3` | Tight | Healthy operational variation |
| `0.3 – 1.0` | Moderate | Some tail; check `kurtosis` for heavy outliers |
| `1.0 – 3.0` | High | Right-skewed with long tail; check `p99` / `p999` |
| `> 3.0` | Very high | Investigate: outliers dominate; possible bimodality (check `bimodality_coef`) |

**Operational use.** CV is the SRE workhorse statistic for "how predictable is this latency?" CV < 0.3 generally indicates a tight, predictable distribution. CV > 1 indicates substantial variation — the standard deviation is larger than the mean, which only happens when the distribution has a long tail (since mean and std_dev share units, `std_dev > mean` implies values must extend far beyond mean to push `std_dev` that high). CV is dimensionless, so it's the right metric for ranking and comparing services with different absolute speeds. ltl's `-so cv` surfaces the most variable APIs — frequently the right starting point for tail-latency investigations.

**Example.**

```text
ltl -so cv -n 20 access.log           # surface most variable APIs
```

**How ltl computes this.** Derived from already-computed `std_dev` and `mean`: `cv = std_dev / mean`. Undefined when `mean == 0`. Displayed with adaptive precision (2 decimals when < 10; 1 decimal when 10..100; integer when ≥ 100) so the column stays narrow on stable services and stays readable on chaotic ones.

**See also.** `mean`, `std_dev`, `iqr`, `kurtosis`, `bimodality_coef`.

---

### iqr (Interquartile Range)

`iqr = p75 − p25`. IQR captures the spread of the *middle 50%* of observations — the range between the lower quartile and the upper quartile. Half of all values fall inside this band; one quarter are slower, one quarter are faster.

**Interpretation.**

| Comparison | Implication |
|---|---|
| `iqr ≪ std_dev` | Tails are inflating `std_dev`; the body is actually tight |
| `iqr ≈ std_dev` | Distribution is roughly normal-shaped |
| `iqr ≫ (p99 − p75)` | Body is wider than the right tail; unusual |
| `(p99 − p75) ≫ iqr` | Right tail dominates the body; classic latency shape |

**Operational use.** IQR is the *robust* spread statistic: by construction it ignores the bottom 25% and top 25%, which contain all the outliers, fast-path edge cases, and pathological-tail events. This makes IQR resistant to the failure modes that compromise `std_dev` (single 10-second outlier dominates) and `cv` (right-skew inflates `std_dev`). For SRE work where you want "what's the typical operational range this API behaves in", IQR is usually the right answer — `mean ± std_dev` assumes a normal distribution which production latency violates. IQR pairs well with `p50` (median) as a robust center: the trio `p25 / p50 / p75` describes the body of the distribution without being skewed by tails.

**Example.**

```text
ltl -so iqr -n 20 access.log          # find APIs with the noisiest middle range
```

**How ltl computes this.** Derived from already-computed percentiles: `iqr = p75 − p25`. Inherits the data model and algorithm of the underlying percentiles — exact relative to observed samples in the raw values data model, or subject to bin-width interpolation in the bin counter data model (default ~1.3% relative bin width).

**See also.** `p25`, `p50`, `p75`, `std_dev`, `cv`.

---

## Percentiles

### percentiles

Percentiles answer the question "what value is faster than (or equal to) N% of all observations?" The N-th percentile `pN` is the value at which N percent of observed durations fall at or below. `p50` is the median; `p99` is the value that 99% of requests beat; `p999` is the value that 99.9% of requests beat. Where `mean` collapses a distribution to a single average, percentiles describe its *shape* — by reading off the values at many different points along the cumulative distribution.

**Aliases.** `p1`, `p5`, `p10`, `p25`, `p50`, `p75`, `p90`, `p95`, `p99`, `p999`, `p9999`, `p99999` — each individual percentile slug resolves to this shared topic via `ltl --explain pNN`.

**Available percentiles.**

| Slug | Quantile | Tail interpretation | Min sample size |
|---|---|---|---|
| `p1` | 1% | 1 in 100 requests is at or below this value | ~100 |
| `p5` | 5% | Fast-path representative; cache-warm baseline | ~200 |
| `p10` | 10% | Lower body; unloaded steady-state behavior | ~100 |
| `p25` | 25% | Lower quartile (paired with `p75` for `iqr`) | ~40 |
| `p50` | 50% | Median; the "typical" value robust to outliers | ~40 |
| `p75` | 75% | Upper quartile (paired with `p25` for `iqr`) | ~40 |
| `p90` | 90% | Common SLO point; "90% of users see this or better" | ~100 |
| `p95` | 95% | Common SLO point; tighter than `p90` | ~200 |
| `p99` | 99% | 1 in 100 requests is slower than this | ~1,000 |
| `p999` | 99.9% | 1 in 1,000 requests is slower than this | ~10,000 |
| `p9999` | 99.99% | 1 in 10,000 requests is slower; high-volume tail | ~100,000 |
| `p99999` | 99.999% | 1 in 100,000 requests is slower; very-high-volume tail | ~1,000,000 |

**Operational use.** Percentiles are the primary SRE latency-investigation tool. Each percentile answers a different operational question: `p50` (median) is the "typical" experience; `p90` and `p95` are commonly-used SLO target points; `p99`, `p999`, and higher tail percentiles describe the user-visible worst-case latencies that drive outage and complaint patterns; `p1`, `p5`, `p10` are the lower-body percentiles useful for fast-path analysis (cache effectiveness, what does the system look like when not loaded). The progression of nines — `p99`, `p999`, `p9999`, `p99999` — describes *how heavy* the tail is: in a benign distribution these values converge quickly; in a pathological one (GC pauses, lock contention, retry storms) they diverge sharply.

**Sample size and meaningfulness.** Higher percentiles require larger samples to be statistically meaningful. The general rule: `pN` needs at least `10/(1-N/100)` observations to be informative — `p99` needs ~1,000, `p999` needs ~10,000, `p9999` needs ~100,000, `p99999` needs ~1 million. Below these thresholds the percentile collapses toward `max` and carries no signal independent of `max`. ltl emits every percentile column regardless of sample size, so check the `occurrences` column when interpreting high-nines values.

**Example.**

```text
ltl -so p999 -n 20 access.log         # find APIs with the worst p999 tail latency
ltl -so p9999 -n 20 access.log        # tail-of-tail analysis; needs many samples
ltl -dmp 7 access.log                 # tighten precision (slower; more memory)
```

**How ltl computes this.** ltl computes percentiles from one of two data models, each using its own algorithm. The two models answer slightly different questions about the same data and produce different values, especially at the tail percentiles. Neither is "the truth" relative to the other — both are valid; the right one depends on what you're trying to learn.

**Raw values data model** — every observation is held in memory; the percentile is selected by **nearest-rank**, i.e. an actually-observed sample at the computed rank in the sorted array. The returned `p99` is a real request that happened. No interpolation, no synthesised values.

**Bin counter data model** — observations are accumulated into log-spaced bins; the percentile is computed by **exponential interpolation within the bucket**, a synthesised value placed inside the bin that contains the target rank on the log scale spanning the bin's lower and upper edges. The returned value is generally not an observed sample. Bin resolution determines how tight the interpolation is; it is governed by the precision lever (`--data-model-precision`).

**Why the values differ.** Nearest-rank returns a real sample; within-bucket interpolation returns a synthesised value inside the matching log-spaced bin. On the same input the two algorithms will report different `p99` (and other percentile) values, particularly in the tail. This is the data model, not a precision deviation. If you switch a surface between models, expect the percentile column to move.

**Selecting the data model.** The choice comes down to memory budget, returned-value semantics, and what you're going to do with the result.

**Choose the raw values data model when:** sample counts are bounded (a single message's per-bucket samples, a filtered analysis, a small log) and the per-observation memory cost is acceptable; you need the reported `p99` to map back to a specific log line you can go read; you're reproducing or comparing against another tool that returns observed samples.

**Choose the bin counter data model when:** sample counts are large, unbounded, or unknown in advance (high-volume access logs, multi-gigabyte captures, long real-time runs) and a fixed per-partition memory cost is more predictable than a per-sample one; you're comparing against histogram-based tools that use a within-bucket interpolation algorithm; you only need the percentile *value*, not a mapping back to an individual observation.

**Resource cost comparison.** The raw values data model scales with observation count: every sample occupies its own slot until the run completes. The bin counter data model scales with bin count: one partition per logical series, with a fixed bin footprint per partition regardless of how many observations stream through it. On small inputs the two are comparable; as sample counts grow the raw cost climbs linearly while the bin cost stays flat per partition. The crossover depends on how many distinct partitions you have — many low-volume series favour the raw values data model; few high-volume series favour the bin counter data model.

**Flags.** Surfaces use sensible internal defaults (see the data-model selectors in `--help`); `--data-model raw` and `--data-model bin` pin every surface to one model. Per-surface selectors (`--histogram-data-model`, `--heatmap-data-model`, `--message-stats-data-model`, `--bucket-stats-data-model`) override the global setting. Bin resolution is tuned with `--data-model-precision` (tier 1..9, default 5).

**See also.** `min`, `max`, `iqr`, `skewness`, `kurtosis`, `bimodality_coef`. Flags: `--data-model-precision`, `--data-model`.

---

## Distribution shape

### skewness

Skewness measures the *asymmetry* of a distribution — how lopsided it is around its mean. Whether the values tend to bunch up on one side with a tail extending toward the other. For latency, skewness answers "is the tail leaning one way?" — positive skew means the right tail is heavier (most fast, occasionally slow); negative skew means the left tail is heavier (unusual for latency; common when something caps execution at a ceiling).

**Interpretation.**

| Value | Shape | Latency interpretation |
|---|---|---|
| `0` | Symmetric | Bell-curve-like; fast and slow excursions equally likely |
| `0` to `+1` | Mildly right-skewed | Healthy latency shape; small fast-path bias |
| `+1` to `+3` | Strongly right-skewed | Long-tail behavior; classic occasional-slow-request shape |
| `> +3` | Severely right-skewed | Pathological tail; most fast, but a long heavy reach into slow territory |
| `< 0` | Left-skewed | Unusual for latency; often indicates a hard timeout or cap clipping the right tail |
| `≈ 0` with high `kurtosis` | Symmetric, heavy-tailed | Sometimes bimodal — check `bimodality_coef` |

**Operational use.** Skewness has three concrete operational uses. First, *detecting clipped or timed-out distributions*: if you expect right-skew (the natural latency shape) but see near-zero or negative skewness on a slow API, you may have a hidden cap — requests that should be 10s are getting killed at 5s and piling up there. Second, *spotting "bimodal" patterns before `bimodality_coef` fires*: skewness near zero combined with high kurtosis is the signature of "fast and slow modes coexisting" — the means cancel out, but the tails are fat on both sides. Third, skewness is a *structural prerequisite for `bimodality_coef`*: Sarle's BC formula is `(skewness² + 1) / kurtosis_adjusted`, so without skewness the multimodal screening doesn't work.

**Example.**

```text
ltl -so skewness -n 20 access.log     # most asymmetric distributions
ltl -so skewness -sa -n 20 access.log # most negatively-skewed (timeout candidates)
```

**How ltl computes this.** Sample-corrected standardized third moment (the same convention as pandas `.skew()` and R `e1071::skewness(type = 2)`): bias-adjusted so the expected value on a normal distribution is zero regardless of sample size. Requires `n ≥ 4` and a non-degenerate distribution (emitted blank otherwise). Single-pass O(n) accumulator on the sorted-values pass; the same pass produces `kurtosis`, so the marginal cost of skewness is negligible.

**See also.** `kurtosis`, `bimodality_coef`, `std_dev`, `percentiles`.

---

### kurtosis

Kurtosis measures the *tail-heaviness* (and concentration around the mean) of a distribution: how prone the distribution is to producing extreme outliers compared to a normal bell curve. For latency, kurtosis answers "how often do rare, extreme values show up?" — low kurtosis means values cluster predictably and tails are thin; high kurtosis means most values cluster near the mean *but* the tails are heavy — the "occasionally horrible" pattern. It's not about spread (that's `std_dev` / `cv`) and not about asymmetry (that's `skewness`). Kurtosis specifically captures the shape of the tails.

**Interpretation.**

| Value | Distribution shape | Operational meaning |
|---|---|---|
| `0` | Normal (Gaussian) | Tails behave like a bell curve |
| `< 0` | Platykurtic — flatter, thinner tails | Bounded behavior; extreme outliers unlikely |
| `0` to `~3` | Roughly normal | Typical for healthy latency distributions |
| `3` to `~10` | Leptokurtic — peaked with heavier tails | Outliers getting common enough to matter |
| `> 10` | Very heavy tails | A few extreme outliers dominate the tail; pathological-latency signature (GC, locks, retries) |
| `> 30` | Extreme | Almost certainly indicates something is wrong |

**Operational use.** Kurtosis separates "this API is reliably slow" from "this API is mostly fine but occasionally catastrophic." These look similar in `p50`/`p90` but diverge sharply in tails. **High kurtosis with normal `p50`/`p90`** means most requests are fine but you have invisible outliers being suffered by a small population of users; `p99`/`p999` will show them, but kurtosis tells you they're *concentrated* at the tail rather than spread out. **Low kurtosis with slow `p50`** means uniform slowness affecting everyone — different problem, different fix. Kurtosis is one of three shape moments (with `skewness` and `bimodality_coef`) that let SREs characterize *distribution shape* from the CSV alone, without re-running ltl.

**Example.**

```text
ltl -so kurtosis -n 20 access.log     # heaviest tails
```

**How ltl computes this.** Sample-corrected excess kurtosis (the same convention as pandas `.kurt()` and R `e1071::kurtosis(type = 2)`): a normal distribution reads zero regardless of sample size; positive values indicate heavier-than-normal tails, negative values indicate lighter tails. Requires `n ≥ 4` and a non-degenerate distribution (emitted blank otherwise). Single-pass O(n) accumulator on the sorted-values pass; the same pass produces `skewness` and feeds `bimodality_coef`.

**See also.** `skewness`, `bimodality_coef`, `std_dev`, `cv`, `percentiles`.

---

### bimodality_coef (Sarle's BC)

Sarle's bimodality coefficient screens for whether a distribution likely has *two (or more) modes* — two distinct populations of values mashed into the same dataset, each with its own peak. The classic case: 80% of requests hit a cache and return in 5ms, the other 20% miss and take 200ms. The mean (45ms) is in a valley where almost no requests actually land; the distribution has two modes but every summary statistic pretends it has one. `bimodality_coef` is the single number designed to flag exactly that case.

**Interpretation.**

| BC value | Interpretation |
|---|---|
| `< 0.555` (5/9) | Likely unimodal — one peak |
| `> 0.555` | **Suspect bimodal or multimodal — investigate** |
| Approaching `1.0` | Strongly bimodal |
| `= 0.555` | BC of a uniform distribution — the canonical screening threshold |

**Operational use.** This is the cheapest, most actionable multimodality screening statistic available — specifically useful for catching cache-hit-vs-miss patterns. `std_dev` and `cv` tell you "values are spread out" but not *why*; `bimodality_coef` distinguishes uniformly-noisy from bimodal. The threshold `> 5/9 ≈ 0.555` flags suspect multimodal; values approaching 1.0 indicate strongly bimodal with equal-mass modes. The 0.555 cutoff is canonical from the bimodality-detection literature (it is the BC of a uniform distribution — anything more spread-out-looking than uniform is suspect bimodal). `-so bimodality_coef` ranks every message in the log by likelihood of multimodality.

**Common triggers.** (1) *Cache effectiveness investigations* — a bimodal API is often a caching layer working partially; modes are "served from cache" vs "fell through to backend"; if BC drops over time without changes, your cache is degrading. (2) *Hidden two-population effects* — authenticated vs unauthenticated, read-from-replica vs read-from-primary, or other internal branching producing two distinct latency profiles. (3) *Queueing detection* — queued vs unqueued requests are bimodal by construction; high BC on an API that shouldn't have queues signals contention. (4) *Distribution-shape fingerprinting* — `skewness + kurtosis + bimodality_coef` together form a 3-column shape signature that's diagnostic without needing the heatmap.

**Caveats (screening, not testing).** Sarle's BC is a *screen*, not a test. Two important caveats: **small-sample false positives** — at `n < 100` random noise alone produces BC > 0.555, so high BC on a low-traffic API is a hint not a verdict; and **skewed-bimodal blind spots** — if the two modes are very unequal (99% fast / 1% slow), the dominant mode's mass overwhelms the skewness-squared term and BC may stay below threshold even though the distribution is technically bimodal. The case where BC works best is comparable mode populations (say 30/70 to 50/50). For verification when BC flags a candidate, Hartigan's dip test is the gold-standard follow-up (computationally expensive; not shipped in ltl).

**Example.**

```text
ltl -so bimodality_coef -n 20 access.log     # most likely multimodal APIs
```

**How ltl computes this.** Sarle's formula with sample-size correction: `BC = (skewness² + 1) / (kurtosis + 3 × (n−1)² / ((n−2)(n−3)))`. The denominator's sample-size adjustment is what distinguishes Sarle's BC from the unadjusted moment-based version — it prevents small-sample false positives from being even worse. Requires `n ≥ 4` and non-zero `std_dev`; emitted blank otherwise. Total cost: three arithmetic operations on numbers (`skewness`, `kurtosis`, `n`) already computed for the other shape moments.

**See also.** `skewness`, `kurtosis`, `cv`, `std_dev`.
