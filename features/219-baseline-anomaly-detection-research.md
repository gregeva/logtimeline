# Baseline-driven anomaly detection — research notes (#219)

## Status

In-progress research notes. Not a design, not a plan, not a frozen record. The questions in this file are open. Anything written here is intended to inform a future investigation, not to constrain it.

A prior version of this file proposed a four-goals framing and five recommendations (R1–R5) that were not grounded in cited sources or in actual ltl behavior. That content has been removed; see the retracted comment on #219 for the record.

---

## Problem statement

Given two `-o` outputs from the same system at two different points in time, surface the log-keys whose per-key performance distribution has meaningfully shifted between the earlier (baseline) run and the later (current) run. The output is intended to point an analyst toward where to look — not to explain what changed upstream.

The unit of comparison is per-run, per-key. ltl does not store time-bucketed per-key percentiles, and no plan to do so is in scope for this ticket.

---

## What `-o` actually emits today

For each log-key, MESSAGES rows in `-o` carry:

- `occurrences` — count for the whole run
- `min`, `mean`, `max`, `std_dev`
- Percentiles: `p1`, `p25`, `p50`, `p75`, `p90`, `p95`, `p99`, `p999`, `p9999`
- Shape columns added under #222: `iqr` (= p75 − p25), `skewness`, `kurtosis` (excess), `bimodality_coef` (Sarle's BC)

These are computed in `calculate_statistics` from the sorted observation array for the key. Two MESSAGES CSVs from two runs of the same system therefore expose the same column set on the same per-key partition; the comparison shape is symmetric.

STATS rows are per-bucket and aggregated across keys — they do not provide a per-key partition and are therefore not the input for this work.

---

## Literature and practice grounding (sources)

The table below records sources surveyed for relevance to this problem. The "what it suggests" column captures what the source itself says, framed as input to future investigation — not as a decision.

| Source | What it suggests for #219 investigation |
|---|---|
| **HdrHistogram** (Gil Tene) — *How NOT to Measure Latency*, Strange Loop 2015; HdrHistogram design rationale | Tene's canonical points: percentiles cannot be averaged across time windows ("you can't average percentiles. Period."), and the analyst's job is to "look deeper" than a single anchor percentile. HdrHistogram is designed to capture an accurate *number of nines*. Implication for investigation: a comparator that compares only one anchor percentile (e.g., p99) discards information that the deeper nines (p999, p9999) carry independently — this is a defensible inference from Tene's work, not a direct quote of his. |
| **Google SRE Book, Ch. 6** ("Monitoring Distributed Systems") | SLOs are commonly stated as pairs of a body and a tail target (e.g. "p50 < X and p99 < Y"). Implication for investigation: a useful comparator likely needs to reflect this body-vs-tail distinction rather than treat all percentiles as one homogeneous vector. |
| **USE method** (Brendan Gregg) / **RED method** (Tom Wilkie) | Both pair latency with a load axis (saturation in USE; rate in RED). Implication for investigation: latency change in isolation is harder to interpret than latency change paired with traffic-volume change. For #219 the corresponding load signal available per-key is `occurrences`. |
| **OpenTelemetry exponential histograms; Prometheus native histograms** | Convergent design across modern observability systems: carry bin counts as the primitive, derive percentiles as projections. ltl's `%heatmap_data` already carries bin counters per bucket. Implication: not directly used in #219, but documents that the field has moved toward bin-level primitives where exact percentiles matter. |
| **DDSketch** (Masson, Rim, Lee, VLDB 2019; Datadog) | Provides a configurable relative-error guarantee α on quantile estimates; α is picked at sketch construction. Common production deployments use α in the 0.5%–2% range. Implication for investigation: a relative-error formulation in the tail has precedent in production observability tooling, but the magnitude is a deployment choice, not a universal default. |
| **Honeycomb BubbleUp** (product documentation) | UX pattern: user selects a region of interest, system compares it to a reference region and ranks dimensions that explain the difference. The shape (selection-vs-reference with a ranked output) is the closest extant pattern to what #219 is trying to do, though BubbleUp operates on traces, not log-key latency distributions. |
| **Sarle's bimodality coefficient** | Formula: `BC = (g² + 1) / (k + 3(n-1)²/((n-2)(n-3)))`, where g is skewness and k is excess kurtosis. The literature heuristic is `BC > 5/9 ≈ 0.555` flags suspect multimodality. Implication: ltl already emits this per-row, so a comparator can use *change in BC* as one signal. The threshold is heuristic, not exact. |
| **Hartigan's dip test** (Hartigan & Hartigan, 1985) | A formal nonparametric test for unimodality vs. multimodality. Computationally heavier than BC (requires either a lookup table of critical values or bootstrap simulation). Known properties of the two relative to each other: BC is O(1) given moments ltl already computes, but has documented failure modes — it can flag highly-skewed unimodal distributions as multimodal (false positives), and can miss multimodality when modes are close together (false negatives). Dip test is more powerful but more expensive. Implication for investigation: BC is the natural first-line screen given it's already emitted; whether its failure modes are problematic on real ltl-analyzed logs is an empirical question. |
| **Order-statistic quantile CI** (binomial method; Conover, *Practical Nonparametric Statistics*) | The rank position of the q-th sample quantile in an ordered sample of n observations is binomially distributed Bin(n, q). The normal-approximation 95% CI half-width on the *rank* is `±1.96 × √(n × q × (1−q))`. This is a rank CI, not a value CI — converting to a value CI requires reading back the empirical distribution at the ranks. Implication for investigation: gives a defensible basis for sample-size gating, with the caveat that the rank-to-value conversion is what an analyst actually sees move. |

---

## Open methodological questions

These mirror the open questions in the rewritten #219 ticket body; this section captures what the literature above suggests might be relevant to each, *without proposing answers*.

**Q1. What constitutes a meaningful shift in a per-key distribution?**

Candidate signal axes already present in the MESSAGES CSV: center (mean, p50), spread (std_dev, iqr), tail (p90, p95, p99, p999, p9999), shape (skewness, kurtosis, bimodality_coef), volume (occurrences). The literature suggests these are not equivalent — body and tail behave differently (SRE Book; HdrHistogram); shape change can occur with percentile values unchanged (BC, dip test); and volume change can confound latency interpretation (USE/RED). Investigation is needed to determine which axes actually carry signal in practice on real ltl-analyzed logs, which are redundant, and how to present per-axis findings without overwhelming an analyst.

**Q2. How should sample-size asymmetry be handled?**

The order-statistic CI in the literature table establishes the principle. Applied to specific quantiles, with the working convention that the rank CI half-width should be no more than ±6 ranks at the target quantile:

- p99 (q=0.99): half-width ≈ 0.195 × √n. ±6 ranks needs n ≈ 1,000.
- p999 (q=0.999): half-width ≈ 0.062 × √n. ±6 ranks needs n ≈ 10,000.
- p9999 (q=0.9999): half-width ≈ 0.0196 × √n. ±6 ranks needs n ≈ 100,000.

These thresholds are conventional, not authoritative — a different tolerance (e.g., ±3 ranks or ±10 ranks) shifts them up or down. The investigation needs to determine: what gating policy is workable in practice (per-percentile, per-key, or both); what tolerance an analyst can interpret; how to communicate "n too low to compare" to the analyst without burying real findings; and how to handle the asymmetric case where one side has enough n and the other does not.

**Q3. How should keys present in only one run be handled?**

No literature directly addresses this in the comparator context; it is a design question. Options that need investigation: surface separately as new/disappeared lists; include in the main output with an explicit marker; threshold by occurrences before surfacing at all. The implications of each for analyst workflow are not yet known.

**Q4. What threshold grammar can an analyst actually reason about?**

Absolute (e.g., "shifted by ≥ 50ms"), relative (e.g., "shifted by ≥ 20%"), and sigma-based (e.g., "shifted by ≥ 2σ from baseline variance") all have precedent. DDSketch's relative-error grammar suggests relative formulations are workable in the tail. The investigation question is which grammar (or combination) an analyst can specify and predict the behavior of — not just which is statistically well-founded.

**Q5. What is the right output shape?**

Filtering (show only changed keys), ranking (order by deviance magnitude), per-row annotation (mark each row with which signals moved), and named-pattern matching (match against a scenario ruleset — sibling ticket) are all candidates. The choice is downstream of Q1 and Q4 and likely should not be fixed until both have been investigated.

**Q6. How does this interact with the sibling scenario-detection ruleset (#258)?**

Generic deviance detection (this ticket) flags "something is different here." Scenario detection (#258) flags "this matches a known degradation pattern." Both consume the same input data. The relationship between the two — sequencing, overlap, shared infrastructure, output integration — is itself an open question that should be revisited as both lines of work progress.

---

## What this file is not

- Not an implementation plan.
- Not a commitment to any specific column set, threshold scheme, output format, or CLI shape.
- Not a frozen record. It will be revised as investigation proceeds.

---

## Cross-references

- **#219** (this ticket) — the home for baseline-driven anomaly detection investigation.
- **#222** (delivered) — added the shape-moment columns (`iqr`, `skewness`, `kurtosis`, `bimodality_coef`) that any per-key distribution comparison will consume.
- **#258** — scenario detection ruleset with predictive scoring (sibling ticket). Detects named degradation patterns rather than generic deviance.
