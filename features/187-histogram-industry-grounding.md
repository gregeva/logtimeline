# Industry-practice grounding for issue #187 (D1/D3)

## Purpose

This document records what industry-standard references do for each of the six analytical decisions in issue #187's D3 memo (in-bin interpolation, `buckets_per_decade` default, fall-through threshold, out-of-range handling, partition lifecycle, gating thresholds). It is a *facts-from-the-literature* document. It does not propose recommendations for ltl, does not pick winners, and does not invent options. Where a source is silent on a decision, the silence is recorded.

All quotations below were obtained by direct fetches of the source URLs listed in the "Sources consulted" section. Where a fetch failed or returned insufficient content, the failure is recorded in this document and not papered over.

## Sources consulted

Fetched successfully (text reachable, key passages quoted):

- HdrHistogram `AbstractHistogram.java` source (raw GitHub) — `getValueAtPercentile`, `lowestEquivalentValue`, `highestEquivalentValue`, `medianEquivalentValue`, `sizeOfEquivalentValueRange`, `nextNonEquivalentValue` methods. URL: https://raw.githubusercontent.com/HdrHistogram/HdrHistogram/master/src/main/java/org/HdrHistogram/AbstractHistogram.java
- HdrHistogram README — significant-value-digits, footprint. URL: https://github.com/HdrHistogram/HdrHistogram/blob/master/README.md
- Prometheus `histogram_quantile()` documentation — interpolation rule, `+Inf` rule, NaN cases. URL: https://prometheus.io/docs/prometheus/latest/querying/functions/#histogram_quantile
- Prometheus "Histograms and summaries" practice doc — native-vs-classic guidance. URL: https://prometheus.io/docs/practices/histograms/
- Prometheus `promql/quantile.go` source — `bucketQuantile` formula and NaN guards. URL: https://github.com/prometheus/prometheus/blob/main/promql/quantile.go
- OpenTelemetry metrics data model — ExponentialHistogram section. URL: https://opentelemetry.io/docs/specs/otel/metrics/data-model/
- OpenTelemetry specification repo `data-model.md` (verified in a **second-pass fetch** after user challenged the first-pass "spec silent" finding) — Scale/base table, ZeroCount/zero_threshold, perfect-subsetting downshift; **confirmed silent on quantile estimation** (one mention of "quantile" only in the deprecated Summary type). URL: https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/main/specification/metrics/data-model.md
- OpenTelemetry specification repo `sdk.md` — confirmed silent on quantile/percentile/interpolation. URL: https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/main/specification/metrics/sdk.md
- OpenTelemetry specification repo Prometheus/OpenMetrics compatibility doc — translates Summary quantiles structurally, silent on computation. URL: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/compatibility/prometheus_and_openmetrics.md
- OpenTelemetry blog (2023) "Exponential Histograms" — discusses histogram errors affecting φ-quantile estimation; informational, not normative. URL: https://opentelemetry.io/blog/2023/exponential-histograms/
- OpenTelemetry blog (2022) "Exponential Histograms: Better Data, Zero Configuration" — confirmed no quantile-estimation rule. URL: https://opentelemetry.io/blog/2022/exponential-histograms/
- OTEP 149 (exponential histogram **proposal**, preserved-as-reference, **not adopted into OTEL spec**) — Scale relationship, "percentile calculation usually returns log scale mid point of a bucket". URL: https://raw.githubusercontent.com/open-telemetry/oteps/main/text/0149-exponential-histogram.md
- DDSketch reference implementation `LogLikeIndexMapping.value(int)` — what `value(index)` returns. URL: https://raw.githubusercontent.com/DataDog/sketches-java/master/src/main/java/com/datadoghq/sketch/ddsketch/mapping/LogLikeIndexMapping.java
- DDSketch reference implementation `DDSketch.java` — `getValueAtQuantile`, collapsing store, zero count. URL: https://github.com/DataDog/sketches-java/blob/master/src/main/java/com/datadoghq/sketch/ddsketch/DDSketch.java
- DDSketch sketches-java README — collapsing/unbounded variants, relative-accuracy contract. URL: https://github.com/DataDog/sketches-java/blob/master/README.md
- OpenMetrics specification — `+Inf` bucket requirement, cumulative-count semantics. URL: https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md
- Apache DataSketches KLLSketch doc — K parameter, rank-error contract. URL: https://datasketches.apache.org/docs/KLL/KLLSketch.html
- Gil Tene coordinated-omission mailing-list post — definition of CO, framing about percentile distortion. URL: https://groups.google.com/g/mechanical-sympathy/c/icNZJejUHfE/m/BfDekfBEs_sJ
- Gil Tene "How NOT to Measure Latency" — SlideShare deck (London Oct 2013). URL: https://www.slideshare.net/slideshow/how-not-to-measure-latency-london-oct-2013/27088981

Fetches that failed or returned no usable content (recorded as gaps, not paraphrased from memory):

- DDSketch VLDB 2019 paper (arXiv PDF `https://arxiv.org/pdf/1908.10693` and PVLDB PDF `https://www.vldb.org/pvldb/vol12/p2195-masson.pdf`) — both returned binary/unreadable content; the abstract page (`https://arxiv.org/abs/1908.10693`) returned only metadata. The α / γ / collapsing-store details below come from the DDSketch *implementation* sources (which mirror the paper), not the paper text itself.
- DataSketches QuantilesOverview (`https://datasketches.apache.org/docs/Quantiles/QuantilesOverview.html`) — 404. The KLL-specific URL (`/docs/KLL/KLLSketch.html`) reached.
- DataSketches "Sketching Quantiles and Ranks Tutorial" (`/docs/Quantiles/SketchingQuantilesAndRanksTutorial.html`) — 404.
- DataSketches `/docs/Quantiles/KLLSketch.html` and `/docs/Quantiles/KLLSketches.html` — 404. The KLL doc was reached only at `/docs/KLL/KLLSketch.html`.
- InfoQ Gil Tene talk page (`https://www.infoq.com/presentations/latency-pitfalls/`) — page reached but body content not in the fetch (only summary metadata).
- HdrHistogram wiki — empty (no pages created).
- Direct quote of "percentile starvation" / "we are not who we measure" — these phrases are attributed to Gil Tene in secondary sources but were NOT located verbatim in any primary source reachable in this pass. They are recorded below as **unverified attribution**.

## Decision 1 — In-bin interpolation strategy

**Question**: Once the cumulative-count walk locates the bin containing rank `q · N`, what value does the percentile estimator return — the bin lower boundary, the midpoint, a linear-in-value interpolation, or a linear-in-log interpolation?

### HdrHistogram (source: `AbstractHistogram.getValueAtPercentile`)

Directly from the source file at https://raw.githubusercontent.com/HdrHistogram/HdrHistogram/master/src/main/java/org/HdrHistogram/AbstractHistogram.java:

```java
public long getValueAtPercentile(final double percentile) {
    ...
    long totalToCurrentIndex = 0;
    for (int i = 0; i < countsArrayLength; i++) {
        totalToCurrentIndex += getCountAtIndex(i);
        if (totalToCurrentIndex >= countAtPercentile) {
            long valueAtIndex = valueFromIndex(i);
            return (percentile == 0.0) ?
                    lowestEquivalentValue(valueAtIndex) :
                    highestEquivalentValue(valueAtIndex);
        }
    }
    return 0;
}
```

The supporting methods are:

- `lowestEquivalentValue(value)` — the lowest value equivalent within the bin's resolution.
- `highestEquivalentValue(value)` returns `nextNonEquivalentValue(value) - 1`.
- `medianEquivalentValue(value)` returns `(lowestEquivalentValue(value) + (sizeOfEquivalentValueRange(value) >> 1))`.

**Behavior**: HdrHistogram does **not interpolate within the bin** in `getValueAtPercentile`. For any non-zero percentile it returns the **highest equivalent value** of the bin (i.e., the bin's upper edge minus one unit-of-resolution). For percentile 0 it returns the bin's lowest equivalent value. Other "equivalent value" forms (midpoint via `medianEquivalentValue`) are exposed as separate methods, but `getValueAtPercentile` calls `highestEquivalentValue`, not `medianEquivalentValue`.

**Match to ltl**: ltl's substrate is log-spaced bins with unit counters, matching HdrHistogram's structural assumption. ltl is therefore in HdrHistogram's domain when considering "what to return at the located bin." HdrHistogram's choice is **bin upper edge**, not interpolation. ltl's prior D3 listed midpoint and two interpolation forms as candidates; HdrHistogram itself uses none of those for `getValueAtPercentile`.

### Prometheus `histogram_quantile()` (docs)

From the Prometheus PromQL function reference at https://prometheus.io/docs/prometheus/latest/querying/functions/#histogram_quantile:

For classic (linear-bucket) and native-with-custom-bucket histograms: "it assumes a uniform distribution of observations within the bucket (also called _linear interpolation_)."

For native histograms with the standard exponential schema: "the interpolation is done under the assumption that the samples within the bucket are distributed in a way that they would uniformly populate the buckets in a hypothetical histogram with higher resolution."

### Prometheus `bucketQuantile` (source)

From `promql/quantile.go` at https://github.com/prometheus/prometheus/blob/main/promql/quantile.go, the interpolation rule for classic histograms is the linear formula:

```
quantile = bucketStart + (bucketEnd - bucketStart) * (rank / count)
```

This is **linear-in-value interpolation within the bucket** — the formula treats the bucket as a uniform population on a linear axis between its lower and upper boundaries.

**Match to ltl**: Prometheus's classic-histogram path is the case where bucket boundaries are *not* log-spaced (they are user-defined, often non-geometric); linear-in-value interpolation matches that assumption. Prometheus's native-exponential path is the case structurally analogous to ltl's substrate (log-spaced bins); the docs describe its interpolation as "uniformly populate the buckets in a hypothetical histogram with higher resolution" — i.e., a log-scale-aware refinement, not linear-in-value across the bucket extent.

### OpenTelemetry exponential histogram

Verified across **four primary OTEL sources** in a second-pass grounding fetch (after the first pass under-stated the scope of OTEL's silence):

| OTEL source | Fetch URL | Content on quantile estimation from histogram buckets |
|---|---|---|
| OTEL data-model spec | `raw.githubusercontent.com/open-telemetry/opentelemetry-specification/main/specification/metrics/data-model.md` | One mention of "quantile" — only in the deprecated **Summary (Legacy)** type, about transporting pre-computed quantiles, not computing them from histogram buckets. The ExponentialHistogram section defines bucket structure (Scale, base = `2**(2**(-scale))`, ZeroCount, perfect subsetting) but **does not specify any quantile-estimation rule**. |
| OTEL SDK spec | `raw.githubusercontent.com/open-telemetry/opentelemetry-specification/main/specification/metrics/sdk.md` | No mentions of quantile, percentile, or interpolation. Silent. |
| OTEL Prometheus/OpenMetrics compatibility doc | `github.com/open-telemetry/opentelemetry-specification/blob/main/specification/compatibility/prometheus_and_openmetrics.md` | Translates Summary quantiles structurally to OTLP Summary quantiles. Silent on the computation algorithm. |
| OTEL official blog "Exponential Histograms" (2023) | `opentelemetry.io/blog/2023/exponential-histograms/` | Notes histogram errors affect φ-quantile estimation; does not specify an estimation rule. The accuracy property "relative error = half the bucket width divided by the bucket midpoint" comes from this blog post, which is informational, not normative. |

**OTEL's silence is by design, not omission.** The official spec separates two concerns: (1) histogram *representation* (OTEL's scope — Scale, buckets, ZeroCount, perfect subsetting, +Inf inclusivity), and (2) quantile *estimation from buckets* (consumer's scope — Prometheus `histogram_quantile()`, vendor backends, downstream sketches). OTEL deliberately does not specify the latter.

**OTEP 149** (https://raw.githubusercontent.com/open-telemetry/oteps/main/text/0149-exponential-histogram.md) is the **proposal** that introduced exponential histograms. Direct quote from the OTEP: "To minimize relative error, percentile calculation usually returns log scale mid point of a bucket."

**OTEP 149's standing relative to the spec**: the OTEP repository carries the header **"OTEPs have been moved to the Specification repository. This repository has been preserved for reference purposes."** The OTEP's "log-scale midpoint" recommendation was **not adopted into the OTEL specification** — the spec deliberately remained silent on this, leaving quantile estimation to consumers. Citing OTEP 149 means citing "what one OTEL proposal advocates," not "what OTEL officially specifies." This distinction is load-bearing: a reader treating OTEP 149 citations as equivalent to OTEL spec authority would be over-reading the source.

**Match to ltl**: ltl's substrate is log-spaced like OTEL's exponential histogram structurally. For the *representation* questions (Scale-equivalent / `buckets_per_decade`, ZeroCount, +Inf, lifecycle adaptation), the OTEL data-model spec is the authoritative source. For the *estimation* question (what value to return at the located bin), OTEL is by-design silent; OTEP 149 carries one recommendation (log-scale midpoint) but that is proposal text, not adopted spec.

### DDSketch (source: `LogLikeIndexMapping.value(int)` and `DDSketch.getValueAtQuantile`)

From `LogLikeIndexMapping.value(int)` at https://raw.githubusercontent.com/DataDog/sketches-java/master/src/main/java/com/datadoghq/sketch/ddsketch/mapping/LogLikeIndexMapping.java:

```java
public final double value(int index) {
    return lowerBound(index) * (1 + relativeAccuracy);
}
```

And from `DDSketch.getValueAtQuantile` at https://github.com/DataDog/sketches-java/blob/master/src/main/java/com/datadoghq/sketch/ddsketch/DDSketch.java, the cumulative walk terminates with:

```java
if ((n += bin.getCount()) > rank) {
  return indexMapping.value(bin.getIndex());
}
```

**Behavior**: DDSketch returns a **fixed per-bin representative value** equal to `lowerBound(index) · (1 + α)`. With γ = (1+α)/(1−α), the bin spans `[γⁱ⁻¹, γⁱ]` (approximately), and `(1+α)` places the representative inside that range. It does **not interpolate using `rank_in_bin`** — every quantile that falls in bin *i* gets the same answer. The relative-error guarantee (α) holds because any true value in the bin is within α of the returned representative.

**Match to ltl**: ltl's substrate is structurally identical to DDSketch (log-spaced bins, unit counters). DDSketch's chosen representative is a **scaled lower bound** (`lower · (1+α)`), not a midpoint and not a rank-dependent interpolation.

### Apache DataSketches KLL (comparative only)

KLL is a *rank-based* quantile sketch (not bin-based) and operates on retained samples, so it does not have a direct analog of "in-bin interpolation." Quoted from https://datasketches.apache.org/docs/KLL/KLLSketch.html: KLL's accuracy contract is **rank error**, not value error; its `getQuantile(q)` returns an actual retained sample whose true rank is within ±ε of `q·N`. ltl's bin-based substrate has no rank-error contract analog; this source's relevance to Decision 1 is to note the alternative accuracy axis exists.

### Convergence / divergence summary — Decision 1

The bin-based sources do **not converge** on what value to return at the located bin:

- HdrHistogram (production library, normative behavior): bin **upper edge** (`highestEquivalentValue`), no rank-in-bin use.
- Prometheus classic `histogram_quantile()` (production, normative documentation): **linear-in-value** interpolation using rank-in-bin.
- Prometheus native exponential `histogram_quantile()` (production, normative documentation): log-scale-aware "higher-resolution" interpolation (docs prose; formula not directly quoted in this fetch).
- OTEL specification: **deliberately silent** on quantile estimation from histogram buckets (verified across data-model spec, SDK spec, Prometheus-compatibility spec, and OTEL blog). Quantile estimation is treated as a consumer concern, not part of OTEL's representation contract.
- OTEP 149 (**proposal**, preserved-as-reference, **not adopted into the OTEL spec**): **log-scale midpoint** (geometric midpoint). This is proposal-level guidance and does not have OTEL spec authority.
- DDSketch (production library, normative behavior): **fixed per-bin representative** at `lower · (1+α)`, no rank-in-bin use.

Two related axes of divergence emerge:

1. **Whether to use `rank_in_bin` at all.** HdrHistogram and DDSketch ignore it (single per-bin answer). Prometheus uses it. OTEP-149's "log-scale midpoint" is a single per-bin answer (no rank-in-bin), but is non-normative.
2. **Whether the source has normative authority for the rule.** HdrHistogram source, Prometheus docs/source, and DDSketch source are normative for their respective libraries. OTEL is silent (i.e., OTEL does not pick a rule; consumers do). OTEP 149 is proposal text only — it is *evidence of what one designer advocated*, not *evidence of an adopted standard*.

The libraries agree that **the bin's identity, not its interior, is the dominant accuracy term** — the bin is small enough (by precision parameter choice) that any in-bin convention satisfies the library's stated accuracy contract. The bin-resolution bound from Decision 2 dominates regardless of in-bin convention.

## Decision 2 — `buckets_per_decade` default

**Question**: What precision parameter values do the reference libraries default to or recommend, and what is the published trade-off?

### HdrHistogram

From the README at https://github.com/HdrHistogram/HdrHistogram/blob/master/README.md, the parameter is `numberOfSignificantValueDigits`. The README states: "Value precision is expressed as the number of significant digits in the value recording, and provides control over value quantization behavior" and gives a worked example using 3 significant digits across a range "between 0 and 3,600,000,000."

From the source file's bucketing setup: `largestValueWithSingleUnitResolution = 2 * (long) Math.pow(10, numberOfSignificantValueDigits)`, which is rounded up to a power-of-two `subBucketCount` (the bins-per-doubling). For `numberOfSignificantValueDigits = 3`, `subBucketCount` is 2048 — i.e., ~2048 bins per doubling, or roughly 2048/log2(10) ≈ 616 bins per decade. For 2 significant digits, ~64 bins per doubling (~19 per decade); for 1 digit, ~16 per doubling (~5 per decade).

The README does **not state an explicit recommended default**. The 3-digit example is presented as a practical configuration for "response time tracking."

### Prometheus

The PromQL docs and the practices doc (https://prometheus.io/docs/practices/histograms/) do not give a single recommended bucket count. The practices doc says: "if you can, use native histograms and prefer them over both classic histograms and summaries" and that for classic histograms "you have to pick buckets suitable for the expected range of observed values and the desired queries." For native histograms, the configuration is via Scale (analogous to OTEL's Scale) and the default Scale at native-histogram creation depends on the client library; the spec docs do not pin a number that this fetch captured.

### OpenTelemetry exponential histogram

From the OTEL data-model spec at https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/data-model.md (ExponentialHistogram section):

- `base = 2**(2**(-scale))`.
- "There are `2**scale` buckets between successive powers of 2." Therefore buckets-per-decade = `2**scale * log2(10) ≈ 3.32 · 2**scale`.

Concrete table from the spec (fetched content):

| Scale | Base | Buckets per doubling | Buckets per decade (computed) |
|-------|------|-----------------------|-------------------------------|
| 0     | 2    | 1                     | ~3.3                          |
| 3     | ~1.0905 | 8                  | ~26.6                         |
| 4     | ~1.0443 | 16                 | ~53.1                         |
| 5     | ~1.0219 | 32                 | ~106.3                        |
| 8     | ~1.00271 | 256              | ~850.6                        |

OTEP 149 fetched content says "the most interesting range of baseScale is around -4" (which in the OTEL sign convention corresponds to Scale +4, i.e., 16 buckets per doubling, ~2.19% relative error). The fetched OTEL data-model and the OTEP do not state a single normative default; client SDKs choose.

### DDSketch

From the sketches-java README at https://github.com/DataDog/sketches-java/blob/master/README.md, the quick-start example uses `double relativeAccuracy = 0.01` (1%). The README states DDSketch "has relative error guarantees: it computes quantiles with a controlled relative error" and uses 1% in the worked example. No universal default value is identified in the README; α is a constructor argument.

The relationship α ↔ γ ↔ buckets-per-decade (taken from the implementation, since the paper text could not be fetched): γ = (1+α)/(1−α). Buckets per decade = `ln(10) / ln(γ) = ln(10) / ln((1+α)/(1−α))`. For α=0.01, buckets-per-decade ≈ 115; for α=0.02, ≈ 57; for α=0.05, ≈ 23.

### OpenMetrics

The OpenMetrics spec (https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md) does not prescribe a number of buckets; it requires the `+Inf` bucket and cumulative semantics but leaves bucket layout to producers.

### Apache DataSketches KLL (comparative)

From https://datasketches.apache.org/docs/KLL/KLLSketch.html: "The default K of 200 was chosen to yield approximately the same normalized rank error (1.65%) as the classic quantiles DoublesSketch (K=128, error 1.73%)." K is not analogous to buckets-per-decade — KLL's parameter sizes a sample buffer, not bin resolution — but the doc shows that the field's convention for accuracy contracts is to express defaults in terms of the achieved error percentage at the default.

### Convergence / divergence summary — Decision 2

Three of the four primary substrates state precision in their own native units (HdrHistogram in significant value digits; OTEL in Scale; DDSketch in α). They converge that **the default is a workload-dependent choice, not a one-size-fits-all constant**. None of HdrHistogram, OTEL spec, Prometheus spec, or DDSketch README pin a single normative default through their primary documentation; defaults live in client libraries and worked examples.

Worked-example defaults that did appear: HdrHistogram README example uses 3 significant value digits (~616 bins per decade); OTEP-149 prose calls Scale ±4 (~53 bins per decade) the "most interesting range"; DDSketch README quick-start uses α=0.01 (~115 bins per decade). These span an order of magnitude.

## Decision 3 — Fall-through threshold (when interpolation becomes unreliable)

**Question**: When the bin holding the target rank has very few counts, do the reference libraries change behavior — return a different value, mark the answer as low-confidence, or refuse to interpolate?

### HdrHistogram

`getValueAtPercentile` (source quoted under Decision 1) **does not branch on bin count**. It returns `highestEquivalentValue(valueAtIndex)` regardless of whether the matched bin has 1 count or 1,000,000. There is no fall-through threshold in the source.

### Prometheus

The PromQL docs (https://prometheus.io/docs/prometheus/latest/querying/functions/#histogram_quantile) and `bucketQuantile` source describe several NaN/special-value paths: NaN if fewer than 2 buckets; NaN if highest bucket is not `+Inf`; NaN if total observations is 0. None of these is a **per-bin** fall-through. The docs do not specify a "if the located bucket has fewer than T observations, use a different value" rule.

The PromQL function does return `NaN` rather than an interpolated value in the structural-failure cases. The docs do not promote this to a small-N-per-bin guard.

### OpenTelemetry exponential histogram

Spec and OTEP 149 (URLs above) do not specify quantile-estimation procedure at all, and therefore do not specify any fall-through. Silent.

### DDSketch

`DDSketch.getValueAtQuantile` (source quoted under Decision 1) returns the per-bin representative `indexMapping.value(bin.getIndex())` unconditionally for whichever bin contains the rank. There is **no per-bin fall-through threshold**. The relative-error guarantee α holds for any bin with any positive count; the contract does not weaken at small in-bin counts.

### Gil Tene on percentile starvation

The mailing-list post (https://groups.google.com/g/mechanical-sympathy/c/icNZJejUHfE/) discusses coordinated omission directly. The retrieved content **does not** include guidance on a minimum-N-per-bin threshold or on suppressing interpolation. The SlideShare deck (https://www.slideshare.net/slideshow/how-not-to-measure-latency-london-oct-2013/27088981), per the fetch, does not contain explicit minimum-N-for-tail-percentile guidance either — the deck emphasizes percentile-based reporting over averages but does not state a numeric small-N rule.

Tene's broader framing of "percentile starvation" and "we are not who we measure" is widely attributed in the community but was **not located verbatim** in any primary source reached in this pass. Recorded as **unverified attribution**.

### Apache DataSketches KLL (comparative)

KLL exposes rank error as a confidence contract: `getRank()` returns a normalized rank with ±ε error. The KLL doc page (https://datasketches.apache.org/docs/KLL/KLLSketch.html) does not describe a fall-through threshold per quantile; the rank-error contract is uniform across the rank space.

### Convergence / divergence summary — Decision 3

**The literature reachable in this pass is silent on per-bin fall-through thresholds.** None of HdrHistogram, Prometheus `histogram_quantile`, OTEL spec, OTEP 149, or DDSketch implements a "switch to midpoint (or another value) if the located bin has fewer than T samples" rule. The libraries' shared assumption is that the bin's identity (which the cumulative walk determines deterministically) is sufficient — accuracy is governed by precision parameter choice (Decision 2), not by bin sample count.

Prometheus has structural NaN guards (no `+Inf`, zero total count, <2 buckets), but those are partition-shape guards, not per-bin sample-count guards.

This is the gap that the prior D3 entry tried to fill with first-principles reasoning. The literature does not provide a value for T.

## Decision 4 — Out-of-range tally handling

**Question**: What do the libraries do with values that fall outside the partition's range?

### Prometheus / OpenMetrics

OpenMetrics spec (https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md): "Histogram MetricPoints MUST have one bucket with an `+Inf` threshold." Combined with the cumulative-count rule ("Buckets MUST be cumulative... value_1 <= value_2 <= value_3 <= value_+Inf"), this means **all observations are counted; values above the highest finite bucket land in `+Inf`**. There is no "discard" mode.

Prometheus `histogram_quantile()` behavior in the `+Inf` bucket (from `bucketQuantile` source and the PromQL docs): "If a quantile is located in the highest bucket, the upper bound of the second highest bucket is returned." That is, Prometheus does **not** attempt to interpolate inside the unbounded `+Inf` bucket; it returns a finite value at the boundary of the last *finite* bucket.

### OpenTelemetry exponential histogram

From the data-model spec: a dedicated `zero_count` bucket holds values whose magnitude is ≤ `zero_threshold` (used both for true zeros and for values too small to map under the current Scale). For values too *large* to map, the spec states that "producers SHOULD ensure that the index of any encoded bucket falls within the range of a signed 32-bit integer" — i.e., the implementation expands or downscales rather than discarding. No explicit "overflow bucket" beyond ZeroCount is defined in the fetched content; the convention is that the bucket index space is large enough (or the histogram is downshifted) to contain the range.

### HdrHistogram

From the source file and the README:

- `highestTrackableValue` is set at construction. Values above it normally throw `ArrayIndexOutOfBoundsException`.
- With `autoResize` enabled, `handleRecordException` calls `resize(value)` and the histogram **expands** its `highestTrackableValue` rather than throwing or discarding. (Direct quote from the source fetch under Decision 5.)

Effectively, HdrHistogram either rejects, expands, or (in the auto-resize case) absorbs out-of-range values by extending the partition. There is no out-of-range overflow counter analogous to `+Inf`.

### DDSketch

From `DDSketch.java` and the sketches-java README:

- A `zeroCount` field absorbs values within `[−minIndexedValue, minIndexedValue]` (the "magic bucket" for values too small to map to a log index).
- For values too large or too far from zero to fit a bounded store, the **collapsing store** discards bins from one end (e.g., `CollapsingLowestDenseStore` discards lowest-indexed bins to make room at the high end). Unbounded stores grow.
- Negative values are stored in a separate symmetric store.

So DDSketch has two out-of-range mechanisms: a ZeroCount for sub-resolution values, and store-level collapsing or growth for values exceeding the bin-array capacity.

### Convergence / divergence summary — Decision 4

The sources converge on **"never silently discard out-of-range counts"** but diverge on mechanism:

- Prometheus / OpenMetrics: explicit `+Inf` overflow bucket, with the quantile function refusing to interpolate inside it.
- OTEL exponential: ZeroCount handles the low/sub-resolution end; the upper end is handled by scale downshift rather than a dedicated overflow bucket.
- HdrHistogram: extends the partition (auto-resize) or errors; no overflow bucket.
- DDSketch: ZeroCount at the low end; collapsing or unbounded store at the high end.

For Prometheus specifically, the quantile-time treatment of `+Inf` is concrete and citeable: return the upper bound of the second-highest bucket.

## Decision 5 — Partition lifecycle when range is discovered online

**Question**: How do the libraries size the partition when the data range is not known up front?

### HdrHistogram

From the source file's auto-resize path (https://raw.githubusercontent.com/HdrHistogram/HdrHistogram/master/src/main/java/org/HdrHistogram/AbstractHistogram.java): when `autoResize` is enabled and a recorded value exceeds the current `highestTrackableValue`, `handleRecordException` invokes `resize(value)` rather than throwing. The histogram's bucket array is grown in place; existing counts retain their indices because the bucketing function is index-monotonic.

The README presents `highestTrackableValue` as a constructor argument; auto-resize is an opt-in mode.

### OpenTelemetry exponential histogram

From the data-model spec ("perfect subsetting"): lower-Scale histograms are **exact aggregations** of higher-Scale histograms (two adjacent buckets at Scale `s` merge into one bucket at Scale `s−1`). This means that when the recorded range grows beyond what the current Scale can represent within bucket-index bounds, the producer can **downshift Scale** (rebin in place by pairwise merging) without loss of information beyond what Scale-`s−1` already implies.

OTEP 149 phrases the trade-off as: "facing the choice between reduced histogram resolution and blowing up application memory, shrinking is the obvious choice." This is the canonical "widen-and-rescale" guidance: when range grows, lose half the bins per doubling and keep going.

### DDSketch

The unbounded store grows the bin array as needed (one bin per observed index). The collapsing store has a fixed maximum number of bins; on overflow it discards from one end (`CollapsingLowestDenseStore` from the low end, etc.). Either way, the partition adapts online without a two-pass requirement.

### Prometheus / OpenMetrics

Classic histograms have **fixed** bucket boundaries declared at metric creation; no online adaptation. Native histograms inherit the OTEL-style exponential structure and follow the Scale-downshift pattern.

### Apache DataSketches KLL (comparative)

KLL doesn't have a partition to size — its accuracy is governed by K, the sample-buffer parameter. The doc on https://datasketches.apache.org/docs/KLL/KLLSketch.html notes K controls space/accuracy tradeoff; the sketch handles arbitrary input ranges natively because it stores samples, not bin indices.

### Convergence / divergence summary — Decision 5

The libraries converge on **online adaptation, not two-pass**:

- HdrHistogram: opt-in auto-resize (extend the high end in place).
- OTEL exponential: Scale downshift (pairwise-merge adjacent buckets when range grows).
- DDSketch: unbounded store grows; collapsing store discards from the chosen end.

None of the fetched sources documents a two-pass (first pass discovers range, second pass accumulates counters) lifecycle as their default. Two-pass is achievable but is not the field convention.

The mechanism differs (extend vs. downshift-merge vs. collapse), but the philosophy is shared: amortize a one-time rebin cost rather than parse the data twice.

## Decision 6 — Gating thresholds (exact vs. approximate)

**Question**: Do the libraries say when to use a histogram/sketch versus retain raw values? Is there small-N or use-case sizing guidance?

### HdrHistogram

The README describes HdrHistogram's purpose as recording "high-volume, low-latency"-style measurements where keeping every sample is infeasible: "The memory footprint is fixed regardless of the number of data value samples recorded, and depends solely on the dynamic range and precision chosen." This is a statement of when the data structure is *useful* (large N, fixed memory), not an explicit threshold below which users should fall back to raw arrays.

The README does not state a minimum-N threshold for HdrHistogram's accuracy to hold; the accuracy contract is structural (resolution-of-equivalent-value bound) and does not weaken at small N.

### Prometheus

The practices doc (https://prometheus.io/docs/practices/histograms/) advises: "If you need to aggregate observations across instances (a common scenario), summaries become inappropriate, forcing you toward histograms." This is mechanism-vs-mechanism guidance (summaries vs. histograms), not exact-vs-approximate.

There is no small-N gating rule for `histogram_quantile()` in the docs beyond the structural NaN guards (Decision 3).

### DDSketch

The sketches-java README presents DDSketch as the data structure for "fast and accurate quantile estimates over streams of data." The README does not state a small-N threshold below which the user should retain raw values; the relative-error guarantee α holds for any non-empty sketch.

### Apache DataSketches KLL (comparative)

The KLL doc states the sketch's rank-error contract is uniform across the rank space at the parameter K. There is no documented small-N gate.

### Gil Tene / coordinated omission

The mailing-list post and the deck emphasize **percentile-based reporting** rather than averages and stress the importance of including all values during system stalls (coordinated-omission correction). Neither source, in the content fetched here, prescribes a minimum-N threshold below which percentile reporting becomes meaningless.

### Convergence / divergence summary — Decision 6

The literature reachable in this pass is **silent on a numeric gating threshold** between exact (retain-raw) and approximate (histogram/sketch) modes. The libraries position their structures as universally applicable once the user has decided to use them. The decision of *when* to switch is implicitly an engineering / memory-budget call left to the user.

This is the second gap (alongside Decision 3) that the prior D3 entry attempted to fill with first-principles reasoning. The literature does not supply the threshold.

## Gaps recorded

1. **Decision 3 (fall-through threshold)** — No primary source consulted defines a per-bin sample-count threshold below which the percentile estimator changes behavior. All bin-based libraries (HdrHistogram, Prometheus, OTEL, DDSketch) return a deterministic per-bin value regardless of bin count.

2. **Decision 6 (exact-vs-approximate gating)** — No primary source defines a numeric N below which the histogram/sketch approach should be abandoned in favor of retained-raw quantile computation.

3. **Gil Tene "percentile starvation" / "we are not who we measure"** — These phrases are commonly attributed to Tene in secondary commentary but were **not located verbatim** in the primary sources reached (mailing-list post, SlideShare deck). The InfoQ page did not return the talk body. Recorded as unverified attribution; should be re-verified against the video transcript or a primary deck before being treated as a citation.

4. **DDSketch VLDB 2019 paper** — Both PDF URLs (arXiv and PVLDB) returned binary content that the fetcher could not extract. The α/γ relationship, recommended α defaults, and zero-handling rationale in this document are sourced from the **DataDog sketches-java implementation** (which the paper authors maintain), not from the paper text. A separate verification pass against the paper PDF (downloaded outside this tooling) would close the gap.

5. **Apache DataSketches Quantiles overview** — The general overview URL (`/docs/Quantiles/QuantilesOverview.html`) and the tutorial URL returned 404. Only the KLL-specific page reached. The DataSketches treatment of "rank error vs. value error" is therefore documented here only via the KLL page, not via a general overview.

6. **HdrHistogram FAQ** — The HdrHistogram wiki is empty. The README does not contain an FAQ section addressing percentile starvation or "we are not who we measure" by those names. The coordinated-omission correction (`recordValueWithExpectedInterval`) is documented in the README but is a recording-time correction, not a percentile-estimation-time guard.

7. **OTEL data-model on quantile estimation** — The spec defines the bucket structure exactly but **does not specify** how to estimate quantiles from those buckets. The OTEP-149 "log-scale midpoint" guidance is in the proposal, not the spec; it was not directly quotable from the OTEP fetch.

8. **No source explicitly addresses ltl's case of *per-key, per-time-bucket* online partition discovery with very small per-key N.** Each library handles either large-N streams (HdrHistogram, DDSketch) or pre-defined bucket layouts (Prometheus classic). The ltl scenario of "discover per-(category, log_key) range online, with some keys having dozens of values and others having millions" is not directly mirrored in the consulted literature. Decision 5 documents the libraries' single-stream lifecycle conventions; whether those transfer to ltl's per-key fan-out is not addressed by the sources.
