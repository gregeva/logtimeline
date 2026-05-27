# Feature: Distribution-shape numerical-correctness harness (#254)

## Overview

`tests/validate-distribution-shape.sh` validates that the distribution-shape statistics ltl emits to its MESSAGES CSV — `skewness`, `kurtosis`, `bimodality_coef` — are numerically correct, by feeding ltl synthetic inputs whose analytic shape is known a priori and asserting the emitted values land in fixed tolerance bands.

## GitHub Issue

- #254 — Validate distribution-shape statistics against known-shape synthetic inputs
- Depends on #222 (the columns being validated), merged into `release/0.15.0`.

## Status

Implemented on `254-validate-distribution-shape-statistics`.

## Why this harness exists

The shape moments are the only statistics ltl emits whose values are not human-checkable at a glance: an SRE reading `p99 = 224ms` can sanity-check it against the bar graph, but `kurtosis = 3.42` carries no such intuition. A regression in the moment math could ship undetected. This harness is the dedicated guard.

It does not overlap with the two sibling harnesses:

- **#223** (`validate-csv-output.sh`) owns *structure* — column presence, ordering, types, decimal rules. It never checks whether a value is numerically right.
- **#224** (`validate-statistics.sh`) owns *drift and agreement* — its Layer 3 confirms ltl agrees with a NumPy/SciPy oracle computing the same statistics over the same **real** log samples. That catches drift, but cannot catch a bug where ltl and the oracle would compute the same wrong thing, and it does not anchor the operational meaning of the 0.555 bimodality cutoff.

#254 closes that gap: it checks ltl against **distribution theory** on inputs whose shape is fixed, not against another implementation on shared data.

## How an anchor reaches the shape columns

`tests/distribution-shape/generate-anchor.py` (seeded NumPy RNG) emits a Tomcat access log (ltl match_type 3) whose trailing `%D` service-time field is one draw per line. Every line carries the same request URL, so ltl collapses all draws into a single message key — one MESSAGES-CSV row whose shape columns characterize the whole distribution. The fixed seed makes each anchor byte-identical per run, which is what lets the harness assert against fixed bands rather than re-deriving expectations: a band failure is then a real regression in the moment computation, not sampling noise.

## The three anchors

| Anchor | Generation | n | Asserted |
|---|---|---|---|
| normal | N(100, 10) | 10000 | skewness ≈ 0 (±0.1), excess kurtosis ≈ 0 (±0.2), BC < 0.555 |
| exponential | Exp(1) × 100 | 200000 | skewness ≈ 2.0 (±0.2), excess kurtosis ≈ 6.0 (±1.0) |
| bimodal | N(50, 5) ∪ N(500, 50), 1000 each | 2000 | BC > 0.555, skewness and kurtosis pinned from the seeded sample |

Shape moments are scale-invariant, so the exponential is scaled ×100 (mean ≈ 100ms) to read like a realistic latency log without changing its analytic skewness/kurtosis. Its n is raised to 200000 because the third and fourth sample moments of an exponential are noisy at n=10000 (skew sd ≈ 0.11, excess-kurtosis sd ≈ 1.0); at 200000 they tighten onto the analytic values so the issue's ±0.2/±1.0 bands hold with wide margin.

## Why the exponential anchor does not assert bimodality_coef

A true exponential's bimodality coefficient sits right on Sarle's 0.555 cutoff — the cutoff is near the BC of high-skew distributions, and across seeds the exponential's BC straddles 0.555 in both directions. Asserting `BC < 0.555` there would be testing a value on the threshold, which is inherently fragile and carries no signal about correctness. The unimodal-side evidence comes from the **normal** anchor (BC well below 0.555); the **bimodal** anchor supplies BC well above it. Normal and bimodal bracket the cutoff cleanly; the exponential contributes its robust skewness and kurtosis only.

## Scope

- **Raw-array data model only** — the default per-message-key surface, computed by `calculate_statistics()`. Shape moments under the bin-counter data model (Welford-Pébay running moments) are a separate correctness surface, not covered here.
- **Shape moments only.** The body/tail percentiles added alongside the shape moments in #222 (`p25`, `iqr`, `p9999`) are percentile-family values, validated numerically by #224; this harness does not re-assert them.

## Failure behavior

Every assertion carries `asserts` / `produced_by` / `contract` per `tests/HARNESS-DESIGN.md` and surfaces all four documentation fields on failure. A missing MESSAGES CSV, a missing column, a wrong data-row count, a non-numeric value, and an out-of-band value are all hard failures — never a silent pass. The CSV is parsed with a real CSV reader (the message column contains commas).

## Dependencies

Python 3 + NumPy (the anchor generator). The harness fails fast with an install hint if either is missing; it does not silently skip. SciPy is not required (no oracle — bands are fixed against analytic values).
