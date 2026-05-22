# Baseline-driven anomaly detection — research foundation (#219)

## Purpose

Capture the research findings that bear on **#219 (baseline-driven anomaly detection)** and on the related but distinct goal of **per-API inflection-point detection**. The research was conducted while scoping #222 (SRE-grade distribution-analysis CSV columns); the shape-moment and tail columns landed under #222 are referenced here as the *upstream substrate* that future #219 work will consume.

This file is a frozen research record. Implementation discussions for #219 belong in a separate planning document at the time #219 is scheduled.

---

## What #222 delivered (substrate)

For each per-key (MESSAGES) row and each per-bucket (STATS) row, ltl now emits in the `-o` CSV:

- **Body percentile fill:** `p25`, `iqr` (= `p75 − p25`)
- **High-volume tail:** `p9999`
- **Shape moments:** `skewness`, `kurtosis` (excess; normal = 0)
- **Multimodality screening:** `bimodality_coef` (Sarle's BC; > 5/9 ≈ 0.555 → suspect multimodal)

These columns are O(n) to compute on the existing sorted array inside `calculate_statistics`. They provide a **three-column shape fingerprint** (skewness + kurtosis + BC) at every row, which any downstream consumer — including the future #219 baseline comparator — can use to detect *distribution-shape change* in addition to *percentile-value change*.

The unused `z_score` column was removed from STATS in the same commit; it was a rolling-window z-score on the bucket mean that no display path or internal logic consumed.

---

## Four SRE analysis goals the research surveyed

1. **Load-shape mode characterization** — per API, identifying unimodal/bimodal/heavy-tail/bounded distributions; distinguishing populations within a single key (e.g. cache-hit vs cache-miss).
2. **Mode evolution over time** — detecting that a key's shape is changing across time buckets (e.g. previously unimodal becoming bimodal; tail expansion while body stays stable).
3. **Per-API inflection-point detection** — identifying the load level at which a key's latency knee occurs; the load-vs-latency curve.
4. **Per-API certainty** — bounding the confidence of any "API X has degraded" assertion based on sample size and tail-quantile stability.

Goals 1, 2, and 4 are addressable from MESSAGES (per-key totals) or STATS (per-bucket totals) with column additions — that's what #222 delivered. **Goal 3 is structurally unsolvable from those two CSV shapes** — and that finding is the focus of this document.

---

## The goal-3 structural gap

| Existing CSV | Per-key partition? | Per-bucket time axis? | Sufficient for inflection? |
|---|---|---|---|
| MESSAGES | ✓ | ✗ (totals over the whole run) | No |
| STATS | ✗ (totals across all keys) | ✓ | No |

Per-API inflection-point detection requires *all three axes at once*:
- A **per-key partition** (so the per-API curve is isolable)
- A **per-bucket time axis** (so load varies)
- A **load metric** alongside latency in the same row (so the curve is fittable)

Neither MESSAGES nor STATS carries all three. MESSAGES has the per-key partition but no time; STATS has time but no per-key partition. **Adding columns to either cannot close the gap** — the missing dimension is in the CSV's row shape, not its column list.

This is why the original #222 research recommended splitting goal 3 into a follow-up issue. #219 (baseline-driven anomaly detection) is the closest existing ticket; the recommendation is that #219's design conversation pick up the structural finding rather than #222 dragging it in.

---

## Literature/practice grounding (sources)

The full source list is in the research report at `/tmp/222-research.md` (working copy; the substantive citations of interest to #219 are reproduced below):

| Source | Relevance to #219 |
|---|---|
| **HdrHistogram** (Gil Tene) | "Progression of nines" argument: high nines (p99.9, p99.99) cannot be recomputed from lower nines, must be emitted explicitly. #222's `p9999` honors this; #219's baseline comparator should treat each nine as an independent dimension, not just compare p99. |
| **Google SRE Book Ch. 6** | "Multi-grade SLO" framing: body+tail percentile pairing is the SLO grammar. A meaningful "is API X degraded vs baseline?" comparison should track *both* a body percentile and a tail percentile, not collapse to one anchor. |
| **USE/RED methods** (Brendan Gregg, Tom Wilkie) | USE adds *saturation* as a first-class signal. Goal-3 inflection detection cannot proceed without a load axis paired with the latency axis — RED dashboards always pair `rate` with `duration` at the same bucket. |
| **OpenTelemetry exponential histograms** | The convergent design across OTel/Prometheus/DDSketch is **carry bins, derive quantiles** — bins are the truth, percentiles are a projection. ltl's existing bin-counter primitive (`%heatmap_data`, ~53 bpd default) is structurally aligned with this design. A future per-key × per-bucket emission could expose per-key bin counts at low cost. |
| **DDSketch** (Datadog) | Relative-error guarantee in the tail (~2% typical). The right shape for "how much did this API's p99 move?" is a per-quantile relative-error bound, not an absolute-value bound. |
| **Honeycomb BubbleUp** | The closest extant pattern for goal 3 baseline anomaly detection: compare in-selection distribution vs surrounding-baseline distribution, rank dimensions that explain the difference. The shape — selection vs reference, with a ranked output — is what #219 should aim for. |
| **Sarle's bimodality coefficient** | `BC = (g² + 1) / (k + 3(n-1)²/((n-2)(n-3)))`. Cheapest multimodality screen available; flags shape changes (uni → bi) that no percentile movement can capture. #222 emits this per-row; #219's comparator can use *change in BC* as a signal independent of percentile drift. |
| **Hartigan's dip test** | Expensive lookup-based test; Sarle BC captures ~80–90% of the screening signal at ~0% added cost. Recommendation for #219: do not adopt dip test unless BC false-positive rate is shown problematic in practice. |
| **Bootstrap percentile sample-size literature** | For percentile p_q from n observations, 95% CI half-width on rank ≈ ±1.96 × √(n × q × (1−q)). p99.9 needs n ≥ ~10,000 for any meaning; p99.99 needs n ≥ ~100,000. #219 must suppress comparisons where one side has insufficient n. |

---

## Recommendations for a future #219 design pass

These are **research findings**, not approved design decisions. They are written to seed the #219 planning conversation.

### R1 — Add a third CSV shape: per-key × per-bucket

The minimal data shape for goal 3 (inflection) and a strong baseline comparator (goal 4) is:

```
timestamp, category, message, occurrences,
<load_metric>,
min, mean, max, std_dev,
p1, p25, p50, p75, iqr, p90, p95, p99, p999, p9999,
cv, skewness, kurtosis, bimodality_coef
```

One row per `(time_bucket, key)` pair. The MESSAGES shape collapses time; the STATS shape collapses key; this third file (working name: **PERMSG-STATS**) collapses neither.

The load metric column is the critical addition: `sessions` (concurrent count proxy) is the natural choice given ltl already auto-detects it; alternatives are `msg-rate` per bucket per key, or `count` per bucket per key. The choice affects which inflection curve is fittable.

CLI shape suggestion: `-ops` / `--output-per-key-stats` to emit alongside existing MESSAGES + STATS.

Risk: row explosion. A 24-hour log with 5-minute buckets and 1,000 unique keys produces 288,000 rows. Mitigation: only emit rows where `occurrences > 0` for the key in the bucket (which is the natural sparseness — most keys don't fire in most buckets).

### R2 — Baseline comparator (the headline #219 idea)

Given the post-#222 shape, the **per-row signal vector** for comparing baseline vs current is roughly:

```
{ p50, p95, p99, p999, p9999, skewness, kurtosis, bimodality_coef }
```

Eight dimensions per key. A row-level "deviance" score is then a weighted distance over those dimensions, with per-dimension tolerance bands derived from baseline sample size (n-aware certainty).

Three modes per #219 issue body:
- **Filter in** — show only keys whose vector-distance exceeds threshold
- **Filter out** — hide keys whose vector-distance is within tolerance
- **Highlight** — render all keys, visually flag deviant rows

For **bimodality_coef specifically**, the signal isn't "BC moved by X" — it's "BC crossed the 0.555 threshold *in one direction*". A key that went from BC=0.4 (unimodal) to BC=0.7 (multimodal) is a regime change, not a continuous drift. The comparator should treat threshold crossings as distinct events.

### R3 — Sample-size gating

For each percentile column compared, suppress the comparison if `n < n_min(q)`:
- p99 needs `n ≥ ~1,000`
- p999 needs `n ≥ ~10,000`
- p9999 needs `n ≥ ~100,000`
- skewness/kurtosis/BC need `n ≥ 4` (already enforced by #222 — emitted blank otherwise) but for *meaningful* comparison `n ≥ ~100`

A key with 50 occurrences in baseline and 50 occurrences in current cannot meaningfully report a p999 change. Surface as "n too low to compare" rather than treating absence as zero.

### R4 — Threshold expression

#219 issue body asks "absolute (ms), relative (%), or sigma-style?" The literature converges on **relative-error in the tail, absolute-or-sigma in the body**:
- p1 / p25 / p50 / p75 → absolute or sigma (the body is typically tight; relative thresholds blow up near zero)
- p90 / p95 / p99 / p999 / p9999 → relative-error (DDSketch grammar; tail movement is naturally multiplicative)
- skewness / kurtosis → absolute delta with a min-magnitude floor
- bimodality_coef → threshold-crossing, not delta

A single threshold-shape switch (`--threshold-relative` / `--threshold-absolute`) would underserve the analysis. The default should be per-column-class.

### R5 — New keys, disappeared keys

#219 issue body asks how to handle messages present in one run but not the other. Recommendation:
- **New key in current** — list separately as "newly observed in current", flag if occurrences > meaningful-N floor
- **Disappeared key in baseline** — list separately as "absent from current", flag if baseline occurrences > meaningful-N floor (suggests dropped traffic, not natural decay)

Not "synthesize zero values for missing keys" — that distorts the deviance computation.

---

## What this file is NOT

- An implementation plan for #219. That belongs in a future planning doc when #219 is scheduled.
- A binding commitment to any specific column set, threshold, or CSV shape. The recommendations above are research-grounded but not approved.
- A statement that #178 (inflection detection) is the same as #219. They're related — both need a per-key × per-bucket data shape — but #178 is curve-fitting (USL-style), and #219 is distribution comparison. They share the same upstream substrate (R1).

---

## Cross-references

- **#222** (delivered) — added the shape-moment + body/tail percentile columns referenced as R2's signal vector
- **#219** (the home for the next iteration) — this file's R2/R3/R4/R5 inform that conversation
- **#178** (planned) — per-API inflection-point detection; shares R1's per-key × per-bucket substrate
- **#187** — unified percentile contract; the bin-counter primitive that R1's load-metric-aware extension could exploit
- **#224** (planned) — percentile-value regression harness; once #224 + #219 both exist, they form a tiered observability gate (drift detection in 224, structural anomaly in 219)
- Research source notes at `/tmp/222-research.md` (working copy; survives this session for cross-checking but is not committed)
