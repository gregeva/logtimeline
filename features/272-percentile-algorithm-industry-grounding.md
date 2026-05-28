# Industry-practice grounding for issue #272 (raw-array percentile algorithm)

## Purpose

This document records what industry-standard references do when computing percentiles from a **raw sample array** — i.e. when the full set of observations is materialised in memory and no histogram or sketch is used. It is the sibling of `features/187-histogram-industry-grounding.md`, which covers the bin-counter (histogram) data-model case. Together the two files cover the two data models on which `ltl` computes percentiles.

This is a *facts-from-the-literature* document. It does not propose recommendations for `ltl`, does not pick winners, and does not invent options. Where a source is silent on the algorithm, the silence is recorded. Where a fetch failed and the content could not be quoted from a primary source, the failure is recorded rather than papered over.

All quotations below were obtained by direct fetches of the source URLs listed in the "Sources consulted" section.

## Sources consulted

Fetched successfully (text reachable, key passages quoted):

- **numpy.percentile documentation** — `method` parameter default, full list of 13 supported methods, Hyndman & Fan citation. URL: https://numpy.org/doc/stable/reference/generated/numpy.percentile.html
- **pandas.DataFrame.quantile documentation** — `interpolation` parameter default and method list. URL: https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.quantile.html
- **R `quantile()` documentation** (stat.ethz.ch) — `type` parameter default, Hyndman & Fan citation, Type 7 formula, H&F authors' Type 8 recommendation. URL: https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html
- **Prometheus `histogram_quantile()` documentation** — bucket interpolation rule for classic and native histograms. URL: https://prometheus.io/docs/prometheus/latest/querying/functions/
- **OTEP 149** (OpenTelemetry exponential histogram **proposal**, preserved-as-reference, **not adopted into OTEL spec**) — "percentile calculation usually returns log scale mid point of a bucket". URL: https://github.com/open-telemetry/oteps/blob/main/text/0149-exponential-histogram.md
- **Datadog DDSketch engineering blog** — confirms DDSketch is the algorithm behind Datadog distributions; relative-error guarantee. URL: https://www.datadoghq.com/blog/engineering/computing-accurate-percentiles-with-ddsketch/
- **New Relic NRQL percentile improvements doc** — proprietary log-scale equal-width histogram algorithm, relative-error contract, `relativeError` field. URL: https://docs.newrelic.com/docs/nrql/using-nrql/improvements-nrql-percentile/
- **Elastic percentile aggregation documentation** — T-Digest default, HDR Histogram opt-in, accuracy properties, non-determinism caveat. URL: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-percentile-aggregation.html
- **AWS CloudWatch statistics definitions** — semantic definition of `p95`, requirement for raw data points, algorithm not documented. URL: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Statistics-definitions.html
- **Google SRE Book — Monitoring Distributed Systems chapter** — explicit recommendation for histogram-bucketed collection over raw latencies; silent on percentile algorithm. URL: https://sre.google/sre-book/monitoring-distributed-systems/
- **Google SRE Book — Service Level Objectives chapter** — discusses high-order percentiles; silent on percentile algorithm. URL: https://sre.google/sre-book/service-level-objectives/

Fetches that failed or returned no usable content (recorded as gaps, not paraphrased from memory):

- **Splunk percentile documentation** (`https://docs.splunk.com/Documentation/Splunk/latest/SearchReference/CommonStatsFunctions`) and **Splunk community thread** (`https://community.splunk.com/t5/Splunk-Search/Percentile-Implementation/m-p/106641`) — both returned HTTP 403. Splunk's algorithm (nearest-rank for small distinct-value counts, digest above a threshold, opt-in interpolated mode) is widely cited in secondary sources but could not be verified by direct fetch in this pass. Recorded as a gap.
- **Hyndman & Fan 1996** ("Sample Quantiles in Statistical Packages", *The American Statistician* 50(4):361-365, doi 10.1080/00031305.1996.10473566) — publisher page (`https://www.tandfonline.com/doi/abs/10.1080/00031305.1996.10473566`) returned HTTP 403. The paper is cited verbatim by **both** the numpy documentation and the R `quantile()` documentation (see quotations below), which establishes the citation as authentic without requiring a direct fetch of the paper itself. The paper's nine-type taxonomy of sample quantile definitions is the canonical reference for this material.

## What the algorithms are

Before the per-tool findings, the two algorithms that bear on `ltl`'s raw-array path are named precisely.

### Nearest-rank

For a sorted sample array of length `n` and a percentile `p` in `[0, 1]`, nearest-rank picks an actually observed sample at a computed index. The exact index formula varies by definition (Hyndman & Fan's Types 1–3 are the discontinuous variants), but the property in common is: **the returned value is one of the observations** — never a synthesised value between observations. `ltl`'s `calculate_statistics` raw-array path uses `$sorted[int($duration_count * $p)]`, an index-into-sorted-array selection.

### Linear interpolation (Hyndman & Fan Type 7)

For a sorted sample array of length `n` and a percentile `p` in `[0, 1]`, Type 7 places `p` at index `1 + (n - 1) * p` (1-based) and linearly interpolates between the two adjacent observations when the index is non-integer. R's `quantile()` documentation states the formula verbatim:

> "Type 7: `m = 1-p`. `p_k = (k - 1) / (n - 1)`. In this case, `p_k = mode[F(x_k)]`. This is used by S."

pandas' documentation states the operational form:

> "i + (j - i) * fraction, where fraction is the fractional part of the index surrounded by i and j."

The returned value is generally **not** an observed sample. It is a synthesised value on the line segment between two adjacent observations.

## Per-tool findings — raw-sample path

### numpy.percentile

- Default `method` parameter: `'linear'`.
- The documentation lists 13 methods total: nine "standard methods sorted by R type per H&F paper" (`inverted_cdf`, `averaged_inverted_cdf`, `closest_observation`, `interpolated_inverted_cdf`, `hazen`, `weibull`, `linear` (default), `median_unbiased`, `normal_unbiased`) and four "discontinuous variations of `linear`" (`lower`, `higher`, `midpoint`, `nearest`).
- Verbatim citation in the numpy docs: "R. J. Hyndman and Y. Fan, *Sample quantiles in statistical packages*, The American Statistician, 50(4), pp. 361-365, 1996" (cited as the source summarising R types for the first nine methods).
- Note: numpy's own documentation classifies `'nearest'` as a "discontinuous variation of `linear`". `ltl`'s existing raw-array index selection (`int(n * p)`) is closest in spirit to `method='nearest'` (with off-by-one details that fall inside the H&F taxonomy as Type 1 / Type 3 variants).

### pandas.DataFrame.quantile

- Default `interpolation` parameter: `'linear'`.
- Supported interpolation methods: `linear`, `lower`, `higher`, `nearest`, `midpoint`.
- `'linear'` operational definition (verbatim): "i + (j - i) * fraction, where fraction is the fractional part of the index surrounded by i and j."

### R `quantile()`

- Default `type` parameter: `type = 7`.
- Hyndman & Fan citation (verbatim): "Hyndman R. J., Fan Y. (1996). *Sample Quantiles in Statistical Packages*. The American Statistician, 50(4), 361–365."
- Verbatim from the R docs: "Further details are provided in Hyndman and Fan (1996) who recommended type 8."
- The R default is Type 7 — kept for compatibility with S — even though the H&F authors themselves recommended Type 8.

### Splunk percentile functions (`perc99`, etc.)

- Primary sources (Splunk docs, Splunk community thread) **returned HTTP 403** on direct fetch and could not be quoted.
- Recorded as a gap. Secondary sources widely cite Splunk's behaviour as: nearest-rank for distinct-value counts below ~1000, digest above that threshold, with an opt-in `perc_method=interpolated` mode in `limits.conf`. Not verified by direct primary-source fetch in this pass.

### AWS CloudWatch `p99` / `p95`

- The CloudWatch statistics definitions page documents the **semantics** of a percentile statistic — "**p95** is the 95th percentile and means that 95 percent of the data within the period is lower than this value and 5 percent of the data is higher than this value" — but **does not specify the algorithm** (nearest-rank, interpolation, sketch type, or anything else).
- The page does confirm that percentile statistics require raw data points: "CloudWatch needs raw data points to calculate the following statistics: Percentiles, Trimmed mean, Interquartile mean, Winsorized mean, Trimmed sum, Trimmed count, Percentile rank."
- Algorithm not documented; recorded as unspecified.

### Honeycomb P99 / P95

- No fetched primary source on the algorithm Honeycomb uses for P99/P95. Recorded as a gap; not paraphrased from memory.

## Per-tool findings — histogram and sketch paths (for context)

The observability industry has largely moved off the raw-sample question entirely, in favour of histogram or sketch data models. These tools do not answer the raw-array question this issue is about — they are quoted here for completeness, so a reader understands why the "what does the industry do" question doesn't reduce cleanly to one answer.

### Prometheus `histogram_quantile()`

Histogram-based, not raw-sample. Verbatim from the Prometheus docs:

> "For classic histograms and certain native histogram scenarios, the function 'assumes a uniform distribution of observations within the bucket (also called *linear interpolation*).' For non-zero buckets of native histograms with standard exponential schemas, a different method applies: 'the interpolation is done under the assumption that the samples within the bucket are distributed in a way that they would uniformly populate the buckets in a hypothetical histogram with higher resolution. (This is also called *exponential interpolation*.)'"

Linear interpolation here is between **bucket boundaries**, not between samples.

### OpenTelemetry exponential histograms

The OpenTelemetry specification itself is silent on quantile-from-bucket estimation (see `features/187-histogram-industry-grounding.md` for the second-pass verification of that silence). OTEP 149 — a **proposal document, not adopted into the spec** — states:

> "percentiles/quantiles can be computed from exponential buckets with constant relative error across the full range"

> "To minimize relative error, percentile calculation usually returns log scale mid point of a bucket. So returned percentile values won't be on 10, 100, 1000, etc., even if the histogram is base10."

The "log scale mid point of a bucket" rule is the OTEP-149 informational recommendation, not a specification mandate.

### Datadog distributions

Sketch-based, not raw-sample. Verbatim from the Datadog engineering blog:

> "As we developed distribution metrics at Datadog to compute percentiles, we started using a sketch algorithm"

> "We now use DDSketch at scale at Datadog."

> "A relative-error guarantee of 2 percent means that if the actual 95th percentile is 1 second, the value returned by the sketch will be between 0.98 and 1.02 seconds."

### New Relic NRQL `percentile()`

Histogram-based, proprietary. Verbatim from the New Relic docs:

> "uses a proprietary algorithm in what is known as the logarithmic scale equal-width histogram family"

> "The typical relative error of the new method for most datasets is about 3%"

> "the reported value is guaranteed to be within 3% of the actual value"

A `relativeError` field is returned in JSON results so callers can see the precision margin per query.

### Elastic / Kibana percentile aggregation

Sketch-based by default. Verbatim from the Elastic docs:

> "The algorithm used by the `percentile` metric is called TDigest (introduced by Ted Dunning..."

> "Accuracy is proportional to `q(1-q)`. This means that extreme percentiles (e.g. 99%) are more accurate than less extreme percentiles..."

> "Percentile aggregations are also non-deterministic. This means you can get slightly different results using the same data."

HDR Histogram is available as an opt-in via the `hdr` parameter.

## Authoritative SRE specifications

### Google SRE Book — Monitoring Distributed Systems chapter

The chapter explicitly recommends histogram-bucketed collection over raw latencies. Verbatim:

> "The simplest way to differentiate between a slow average and a very slow 'tail' of requests is to collect request counts bucketed by latencies (suitable for rendering a histogram), rather than actual latencies"

The chapter is **silent on the percentile-from-bucket or percentile-from-array algorithm**. The recommendation is about the *collection format* (histogram buckets), not the *quantile-estimation algorithm* applied to them.

### Google SRE Book — Service Level Objectives chapter

The chapter discusses "a high-order percentile, such as the 99th or 99.9th" and emphasises that "using percentiles for indicators allows you to consider the shape of the distribution and its differing attributes" — but is **silent on the computation algorithm** (nearest-rank, linear interpolation, Type 7, sketch, etc.). The chapter focuses on *why* percentiles matter, not *how* they are computed.

### RED / USE / other SRE-discipline writeups

No authoritative SRE source located in this pass specifies a sample-quantile algorithm. Recorded as a gap, not paraphrased from secondary commentary.

## Hyndman & Fan 1996 — canonical reference

The paper Hyndman, R. J. and Fan, Y. (1996), "Sample Quantiles in Statistical Packages", *The American Statistician* 50(4):361-365, doi 10.1080/00031305.1996.10473566, defines a taxonomy of nine sample-quantile definitions (Types 1–9). The publisher page returned HTTP 403 on direct fetch in this pass, so the paper text itself was not quoted. However the paper is cited verbatim by both the numpy documentation and the R `quantile()` documentation (quoted in the per-tool findings above), which establishes that:

- Both stats-package defaults (`numpy.percentile` `method='linear'` and R `quantile()` `type=7`) trace to this taxonomy.
- The paper's authors recommended Type 8 — a fact R's docs surface verbatim and numpy's docs surface implicitly by listing it (`median_unbiased`).
- Type 7 is the inherited default in both packages for compatibility, not because H&F endorsed it.

## Cross-file relationship

This file documents the raw-array (full-observation) data model. Its sibling, `features/187-histogram-industry-grounding.md`, documents the histogram-bin-counter data model. The two files together cover the two data models on which `ltl` computes percentiles. They are paired: the same statistic, two algorithms, two data models, two evidence bases.

`ltl`'s algorithm choices, recorded in issue #272:

- Raw-array data model → nearest-rank (status quo).
- Bin-counter data model → exponential interpolation within bucket (status quo; implemented in #187). The interpolation is in log space — `value = lower * (upper/lower)^fraction` — which is the rule Prometheus's `histogram_quantile()` uses for native exponential histograms (quoted above). It is *not* the linear-interpolation rule Prometheus applies to classic fixed-boundary histograms; the two rules are distinct.

Both choices are defensible against the evidence in these two files. Neither is "the SRE-standard algorithm" — no such standard exists in the references surveyed. The choice in each case is driven by what the data model can faithfully express.
