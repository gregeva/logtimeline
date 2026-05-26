# Feature: Per-message-key statistics — bin-counter data model end-to-end

## Overview

This feature ships the bin-counter data model end-to-end on the **per-message-key statistics surface** (surface 3 in #266's selector matrix; `summary_table` + `csv_output` consumers per #187 R12 / Decision 8). It is the implementation ticket for #187 R9 Phase 2 — the F1 sibling of #34 (which shipped Phase 3 for F2/F3, the heatmap and histogram consumers).

Today, `-mdm bin` is accepted, validated, reported in `-V runtime-config`, and resolved at the dispatch site in `calculate_all_statistics` (`ltl:8622`), but the dispatch silently falls through to the raw-array reduction in `calculate_statistics` (`ltl:8749`). This feature makes the dispatch real: under `-mdm bin`, the parse loop accumulates each duration sample into a `(category, log_key)`-keyed bin-counter partition plus sidecar moment accumulators rather than pushing onto `%log_messages{$cat}{$key}{durations}`; the consumer derives the full statistic set (percentile ladder via #189 R4; min/mean/max/std_dev/cv/moments from sidecars) without retaining or sorting any raw-value array.

Under `-mdm raw` (and under `-mdm` unset → existing internal default), output is byte-identical to today. There is no runtime mode-selection gate; the data model is chosen at flag-parse time per #266's resolution chain and consumed at the single dispatch site for the run.

## GitHub Issue

[#287](https://github.com/gregeva/logtimeline/issues/287)

## Motivation

For multi-GB runs at high `(category, log_key)` cardinality, the per-message duration arrays (`%log_messages{$cat}{$key}{durations}`) are the dominant memory consumer on the per-message-key statistics surface. The raw-array data model retains every duration sample until end-of-parse so `calculate_statistics` can sort and index-select. At 10⁵ keys with hundreds of samples each, that is hundreds of megabytes of retained sample data on the surface that the summary table and CSV writer consume.

Under the bin-counter data model, per-key memory becomes bounded by the partition shape (~265 bins per partition at #187 Decision 2's locked default `buckets_per_decade = 53` × 5 decades initial span) plus a small fixed number of sidecar scalar accumulators. Per-key memory no longer scales with sample count.

The user-observable effects:

- `-mdm bin` no longer silently falls back to raw. The summary table, MESSAGES CSV, and the per-key terminal statistics columns are computed end-to-end via the bin-counter data model.
- Under `-mdm raw` (and at default), output is byte-identical to today.
- Percentile values under `-mdm bin` are derived via Prometheus-style exponential interpolation within bucket (#187 Decision 1, #272's locked algorithm pair); under `-mdm raw` they remain nearest-rank. Per-quantile values differ between the two models by design — this is exactly the divergence the #224 Layer 4 cross-model agreement check measures.
- The `*-bin-data-model` scenario family in `tests/statistics-drift/scenarios.tsv` becomes meaningful for the MESSAGES surface (today these scenarios silently fall back to raw and Layer 4 reports `T1=OK` as a wiring sanity check per #224 Decision 9; once #287 ships, Layer 4 begins reporting real cross-model deviation against the populated `cross-model-tolerances.tsv` envelope).
- A new `-V histogram-bin-counters` block reports `path: unified` for `summary_table` and `csv_output` (the latter as `shares_partitions_with: summary_table` per #189 R7), with the locked Decision 8 telemetry fields populated from real partition state.

## Delivery sequence

This feature consumes the locked contract from #187, the primitives from #189, and follows the consumer-migration pattern established by #34. It is the F1-half of the migration; the F2/F3 half shipped via #34. A separate sibling implementation ticket (out of scope here) carries the per-time-bucket statistics surface (surface 4, `time_bucket_stats` consumer).

| Step | Work | Owner | Status |
|---|---|---|---|
| 1 | Unified contract locked (F1, D1, D1A, D2, D3, D4, D5, D7, D8, D10) | #187 | Shipped |
| 2 | Primitives (`partition_new`, `counter_update`, `partition_extend`, `partition_quantile`, `partition_rebin`) | #189 | Shipped via #34 |
| 3 | Heatmap + histogram consumer migrations (F2/F3) | #34 | Shipped |
| 4 | Data-model selector `-mdm`, dispatch stub at the call site, `-V` foundations | #266, #280 | Shipped |
| 5 | **Per-message-key statistics migration (F1, Path A + A')** | **#287 — this ticket** | This feature |
| 6 | Per-time-bucket statistics migration (F1, Path B) | Separate sibling ticket | Out of scope |
| 7 | Highlight-subset migration | #51 | Out of scope |

### Parallelism

Steps 1-4 are sequential prerequisites; all are shipped. Step 5 (this feature) can begin immediately. Step 6 is independent of step 5 and may begin in parallel — they touch distinct producer call sites (per-message at `ltl:7466–7517`, per-bucket at `ltl:7529–7585`) and distinct consumer branches in `calculate_all_statistics`.

### Integration

Work lands on the issue branch `287-message-stats-bin-counter-data-model` per CLAUDE.md's development workflow. Release-branch integration is decided at the implementation-ticket level.

## Terminology

This feature uses the terminology locked in #187. One additional internal term:

- **Sidecar accumulator** — a producer-maintained scalar that holds an exact-value statistic (or the running input for one) alongside the bin-counter partition. Sidecars survive the migration because the bin counters are lossless on count-rank statistics (percentiles) but lossy on exact-value statistics (min, max, mean, std_dev, centered moments). Industry-standard HDR-style implementations (HdrHistogram, Datadog DDSketch, Prometheus native histograms) keep these exact-value statistics as sidecars; this feature does the same.

The sidecars are *not* a parallel data structure in the #187 R1 sense (which forbids parallel computation paths). They are the same running totals the raw-array producer already maintains (`occurrences`, `total_duration`, `sum_of_squares` — present in the code today at `ltl:7466–7506`), extended with three additional accumulators (`min`, `max`, `m3_sum`/`m4_sum` via Welford-Pébay online update). The bin partition is the percentile-ladder data structure; the sidecars are the exact-value-statistic data structure. They co-exist by design, not by parallel implementation.

## Locked decisions this feature consumes

This feature does **not** lock new decisions. It consumes the locked unified contract from #187 and applies it to surface 3. Each row below is a one-line restatement of how #287 applies the cited locked decision; the decision itself is authoritative in its owning file.

| Locked decision | Owner | How #287 applies it |
|---|---|---|
| F1 — Design philosophy | #187 | Per-key partition + sidecars; rank-in-bin information used because ltl has it. |
| D1 — In-bin interpolation formula | #187 | `partition_quantile` (#189 R4) applied per `(category, log_key)`; emitted ladder is P1, P5, P10, P25, P50, P75, P90, P95, P99, P999, P9999, P99999. |
| D2 — Precision lever | #187 | `buckets_per_decade` default 53 for this surface. **NOT** 616 — bpd=616 is the F2/F3 streaming default per #34 R5 because F2/F3 partition counts are bounded ~70 (per-`time_bucket` or per-metric); F1 partition counts scale with `(category, log_key)` cardinality (unbounded), so bpd=616 would multiply per-partition memory by ~12× and exceed the memory budget the migration is supposed to bound. Tunable via `-pbpd N` / `--percentile-precision 1..9` on the run as a whole, applied uniformly. |
| D4 — Overflow/underflow handling | #187 | Per-partition underflow/overflow counters per #189 R6; counted toward total N; per-quantile `out_of_range_bounded: high\|low\|none` audit in `-V`. |
| D5 — Partition lifecycle | #187 | HdrHistogram-style auto-resize per partition. Lazy construct on first observation per `(category, log_key)`; seeded at 5 decades centered on first value; HdrHistogram-convention doubling on rebin. **No finalize re-bin** — surface 3 has no display geometry to anchor against (the summary table and CSV writer consume scalar percentile values, not partition bins), so #189 R12 `partition_rebin` is not used on this surface. |
| D7 — User opt-out | #187 | `--exact-percentiles` continues to force `raw` on this surface via the resolution chain in `choose_data_model` (`ltl:1394`). `-mdm bin` wins over `--exact-percentiles` when both are passed (per #266's resolution chain: per-surface flag > omnibus > internal logic, where `-ep` is consulted). `-V` reports `user_opt_out` on the `summary_table` and `csv_output` blocks when the resolved data model is `raw` and `-ep` was the reason. |
| D8 — `-V` output format | #187 | `summary_table` and `csv_output` are added to `%migrated` (`ltl:2092`); per-consumer block emits the locked Decision 8 fields populated from real partition state. `csv_output` is a `shares_partitions_with: summary_table` short-form block per #189 R7. |
| D10 — Prototype validation | #187 | Already discharged by #189's V1–V8 validation work; no additional prototype required for this surface (the primitive contract is unchanged and the producer call site is structurally simple). |
| Percentile algorithm grounding | #272 | Raw → nearest-rank, bin → exponential-interpolation-within-bucket. Already wired in `emit_percentile_algorithm_verbose` (`ltl:1910`); this feature removes the "follow-up" note from the `message-stats` block by extending `effective_track` from `pinned_raw` to `matches_data_model`. |

## Requirements

### R1 — `-mdm bin` honored end-to-end on the message-stats surface

Under `-mdm bin` (resolved per #266's chain: per-surface flag > omnibus `-dm` > internal default `raw`), the per-message-key statistics surface runs the bin-counter data model end-to-end: producer accumulates each duration sample into a `(category, log_key)`-keyed bin-counter partition plus sidecar moment accumulators at parse time; consumer derives the full statistic set from the captured state at end-of-parse without sorting, indexing, or iterating any raw-value array.

The dispatch site is `ltl:8622` (the existing `choose_data_model('message-stats')` call in the per-key branch of `calculate_all_statistics`). The `$dm` variable resolved there today is the dispatch lever; this feature makes the `'bin'` branch real.

### R2 — Producer-side data model under `-mdm bin`

#### R2.1 — Per-key bin-counter partition replaces `durations[]`

Under `-mdm bin`, the parse-loop accumulation at `ltl:7466–7517` is modified so that for each observed `(duration, category, log_key)` triple:

- The raw-array push `push @{$log_messages{$cat}{$key}{durations}}, $duration` is **not executed**.
- Instead, the duration sample is fed into a `(category, log_key)`-keyed partition via the #189 R3 counter-update primitive. The store is `%log_messages{$cat}{$key}{bin_partition}` (lazily constructed via #189 R1 on first observation for the key; auto-resized via doubling rebin per #187 Decision 5 when subsequent values fall outside the partition's current `[min, max]`).
- The lazy hash-entry initializer at `ltl:7466` is extended to allocate `bin_partition: undef` (the partition itself is allocated by #189 R1 on first counter_update for the key, not at hash-entry initialization).

The two other producer-side write sites for `%log_messages{$cat}{$key}{durations}` follow the same pattern:

- **Consolidation s1-matched stats_source initializer** at `ltl:7449–7453`. Under `-mdm bin`, the `stats_source->{durations} = [$duration]` initialization is replaced by a single `counter_update` invocation against a freshly-constructed partition.
- **Cluster reinject** at `ltl:4582–4583`. Under `-mdm bin`, `entry->{durations} = $cluster->{durations} // []` is replaced by `entry->{bin_partition} = $cluster->{bin_partition}` (the cluster has already accumulated its partition during consolidation via R2.3 below).

#### R2.2 — Sidecar accumulators on the per-key hash

Under `-mdm bin`, every per-key entry in `%log_messages` maintains the following sidecar fields alongside `bin_partition`:

| Field | Purpose | Existing today? |
|---|---|---|
| `occurrences` | Sample count for the key | Yes (`ltl:7479`) |
| `total_duration` | Σ duration (running sum) | Yes (`ltl:7501`) |
| `sum_of_squares` | Σ duration² (running) | Yes (`ltl:7505`) |
| `min`, `max` | Running min and max of observed durations for the key | **New** under `-mdm bin` |
| `m2_sum`, `m3_sum`, `m4_sum` | Welford-Pébay online centered-moment accumulators (see Algorithm appendix) | **New** under `-mdm bin` |

The existing accumulators (`occurrences`, `total_duration`, `sum_of_squares`) are already maintained today regardless of data model. The new accumulators (`min`, `max`, `m2_sum`, `m3_sum`, `m4_sum`) are populated only under `-mdm bin`; under `-mdm raw` they remain unset (and the consumer derives min/max from the sorted array and moments from a sample iteration at `ltl:8795–8816`, as today).

The reason `m2_sum` is tracked even though `sum_of_squares` is already present: numerical stability. The Welford-Pébay update is numerically stable; the `Σx² − n·μ²` formula at `ltl:8766` is fine for `std_dev` on typical data but loses precision on near-constant inputs (a guard at `ltl:8767` already clamps the cancellation). The bin path tracks both — `sum_of_squares` to remain compatible with the existing std_dev formula (so `-mdm bin` and `-mdm raw` produce identical std_dev on inputs where the cancellation is not pathological), `m2_sum` to feed the m3/m4 update formulas. The Algorithm appendix specifies which formulas use which accumulator.

#### R2.3 — Consolidation merge under `-mdm bin`

`merge_consolidation_stats` (`ltl:5003–5020`) merges two `(category, log_key)` clusters during fuzzy consolidation. Under `-mdm raw` it appends `durations[]` arrays and sums `sum_of_squares` / `total_duration` / `occurrences`. Under `-mdm bin`, the same sub must:

- Per-bin add the two partitions' bin counts (and the underflow/overflow counters). When one cluster's partition is wider than the other's, the narrower partition is extended via #189's auto-resize primitive (`partition_extend`) before the per-bin add so the indices align. The geometric-midpoint remap is the existing #189 mechanism; no new primitive surface.
- Merge the moment sidecars via the Chan-Welford-Pébay parallel-merge formulas (Algorithm appendix). `sum_of_squares` and `total_duration` add directly (they are linear); `min`/`max` take elementwise min/max; `m2_sum`/`m3_sum`/`m4_sum` use the locked merge formulas.

The merge produces a single combined cluster whose state is observationally identical (up to the bin-resolution bound on percentiles, and numerically identical on the sidecar-derived statistics) to what would have been produced by feeding every sample of both clusters into a single partition from scratch.

#### R2.4 — `-mdm raw` producer path unchanged

Under `-mdm raw` (and under `-mdm` unset → internal default raw), every producer-side write at `ltl:7466–7517`, `ltl:7449–7453`, `ltl:4582–4583`, and `ltl:5003–5020` runs identically to today. No bin-partition allocation, no sidecar moment accumulators, no behavior change. This is the byte-identity contract per R12.

### R3 — Consumer-side data model under `-mdm bin`

#### R3.1 — Dispatch site

At `ltl:8616–8651`, the existing dispatch resolves `$dm = choose_data_model('message-stats') // 'raw'`. Under `dm = 'bin'`, the call to `calculate_statistics($aggregated_data)` (`ltl:8623`) is replaced by a call to a sibling sub `calculate_statistics_bin($entry)` where `$entry` is `$log_messages{$category}{$log_key}` itself (no aggregation needed — the partition and sidecars are already keyed on the same `(category, log_key)` pair). The 22-tuple return shape is preserved verbatim so the downstream `$log_messages{$category}{$log_key}{...} = ...` writes at `ltl:8628–8648` are unchanged.

The sibling-sub structure mirrors the `_exact` / `_unified` split #34 used for the heatmap and histogram migrations. Preserving the pre-migration sub verbatim is part of the byte-identity contract (R12) and the `--exact-percentiles` opt-out surface (per #187 Decision 7).

#### R3.2 — Per-statistic derivation

Under `-mdm bin`, `calculate_statistics_bin` produces the same 22-tuple as `calculate_statistics` does under `-mdm raw`. The derivation rule per statistic is locked in the issue body and restated here:

| Statistic | Derivation under `-mdm bin` |
|---|---|
| `min` | Producer sidecar (R2.2). Not derivable from bin counts alone. |
| `max` | Producer sidecar (R2.2). |
| `mean` | `total_duration / occurrences` from existing accumulators. |
| `std_dev` | `sqrt((sum_of_squares − n·mean²) / (n − 1))` from existing accumulators, with the same numerical-cancellation guard as the raw path (`ltl:8767`). |
| `cv` | `std_dev / mean` (cascades). |
| `p1, p5, p10, p25, p50, p75, p90, p95, p99, p999, p9999, p99999` | #189 R4 (`partition_quantile`) invoked once per quantile against the partition. Each invocation returns a numeric value plus a per-quantile `out_of_range_bounded: high\|low\|none` audit code per #187 Decision 4. |
| `iqr` | `p75 − p25` (cascades from the percentile-ladder derivation). |
| `skewness` | From `m3_sum`, `m2_sum`, `n` via the bias-corrected sample skewness formula at `ltl:8811` (verbatim with the raw path; only the input source differs). |
| `kurtosis` | From `m4_sum`, `m2_sum`, `n` via the bias-corrected excess-kurtosis formula at `ltl:8812` (verbatim). |
| `bimodality_coef` | From `skewness`, `kurtosis`, `n` via Sarle's formula at `ltl:8813–8814` (verbatim). |

The skewness/kurtosis/BC formulas in the raw path consume `m2`, `m3`, `m4` (central moments scaled by `1/n`); the bin path's `m2_sum`/`m3_sum`/`m4_sum` are the running sums of `Σ(x − μ)^k` (i.e. central moments scaled by `n`). The conversion is `m_k = M_k_sum / n`. The downstream formulas at `ltl:8811–8814` apply unchanged.

#### R3.3 — `-mdm raw` consumer path unchanged

`calculate_statistics` at `ltl:8749–8822` is preserved verbatim. Under `-mdm raw` (and under defaulted-to-raw), the existing sort-and-index path runs unchanged.

### R4 — Locked algorithm pair per #272

This feature does **not** redecide the percentile algorithm. Per #272's locked decision pair:

- Under `-mdm raw`: nearest-rank (`$sorted[int($n * q)]`), the status quo at `ltl:8775–8786`.
- Under `-mdm bin`: exponential interpolation within bucket (#187 Decision 1's locked Prometheus formula), via `partition_quantile` (#189 R4).

The `=== percentile-algorithm ===` `-V` section (`ltl:1910–2007`) already declares both algorithms with verbatim formulas and source citations; the #224 Layer 3 oracle reads this section to pick its reference computation. This feature requires removing the `effective_track => 'pinned_raw'` override for `message-stats` (`ltl:1958`) and replacing it with `'matches_data_model'` so `effective_algorithm` tracks `data_model` correctly under the bin path. The `effective_algorithm_note:` line emitted today (`ltl:1984–1988`) is removed.

### R5 — `buckets_per_decade` = 53 for this surface

`buckets_per_decade` for the message-stats surface is locked at #187 Decision 2's default value of 53 (Level 5, OTEP-149 Scale-4 analog). It is **not** 616 (Level 9).

The reason is the F1 / F2-F3 split codified in #34 R5 (revised 2026-05-20 per #201): F2 (heatmap) and F3 (histogram) partition counts are bounded by display geometry (~70 partitions total), so bpd=616 streaming is safe (~1.75 MB total). F1 (message-stats and bucket-stats) partition counts scale with `(category, log_key)` cardinality and have no upper bound; bpd=616 would multiply per-partition memory by ~12× and exceed the memory budget the migration is supposed to bound.

The user-tunable lever (`--percentile-precision 1..9` / `-pbpd N`) applies uniformly across consumers per #187 Decision 2. A user who explicitly passes `-pbpd 616` gets bpd=616 across all surfaces; this is an explicit choice, not the default.

### R6 — Lifecycle: auto-resize per #187 Decision 5; no finalize re-bin

Per-`(category, log_key)` partitions follow #187 Decision 5's locked auto-resize lifecycle:

- Constructed lazily on first observation for the key (via #189 R1).
- Seeded at 5 decades centered on the first observed value (`min = v_0 / sqrt(10^5)`, `max = v_0 · sqrt(10^5)`).
- Extended via HdrHistogram-convention doubling when subsequent values fall outside `[min, max]` (via #189's `partition_extend`).

**No finalize re-bin** is performed. The surface 3 consumers (summary table cells, CSV scalars) consume scalar percentile values via #189 R4, not partition bins. There is no display geometry to project onto. The `partition_rebin` wrapper added by #189 R12 (for F2/F3 display-geometry-bound consumers per #201) is not used on this surface.

### R7 — Overflow / underflow per #187 Decision 4

Each partition maintains separate underflow and overflow counters per #189 R6. Both are included in `total_N` for R4's rank computation. When a target rank lands in either, R4 returns the appropriate boundary (`partition.boundary[0]` for underflow, `partition.boundary[B]` for overflow) per #187 Decision 4 and the per-quantile `out_of_range_bounded` audit code is set accordingly.

Under #187 Decision 5's auto-resize lifecycle, overflow and underflow are expected to be rare in practice — the partition extends to contain observed values. The counters function as a safety net for extreme outliers beyond what the doubling-rebin extends to in a reasonable number of rebins.

### R8 — `-V` observability surface

#### R8.1 — `=== histogram-bin-counters ===` per #187 Decision 8

The `summary_table` and `csv_output` consumers are added to the `%migrated` set at `ltl:2092`. The `%partition_keying`, `%percentile_set`, and `%shares_with` hashes at `ltl:2095–2112` are extended:

```
%shares_with = (
    heatmap_markers => 'heatmap_cells',
    histogram_bins  => 'histogram_view',
    csv_output      => 'summary_table',      # new
);

%percentile_set = (
    heatmap_markers => [qw(p50 p95 p99 p999)],
    histogram_view  => [qw(p1 p10 p25 p50 p75 p90 p95 p99 p999 p9999)],
    summary_table   => [qw(p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999)],   # new
    csv_output      => [qw(p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999)],   # new (inherits from summary_table)
);

%partition_keying = (
    heatmap_cells   => 'time_bucket',
    heatmap_markers => 'time_bucket',
    histogram_view  => 'metric_global',
    histogram_bins  => 'metric_global',
    summary_table   => '(category, log_key)',    # new
);
```

The `summary_table` block emits the locked Decision 8 per-consumer fields populated from real partition state via `%bin_counter_telemetry{summary_table}` (the telemetry hash is already declared at `ltl:2149`; the migration populates it at end-of-parse from the partitions in `%log_messages`):

```
consumer: summary_table
  path: unified
  partition_keying: (category, log_key)
  partition_count: <N>
  total_rebin_events: <N>
  max_partition_bins: <N>
  partitions_with_overflow_count: <N>
  partitions_with_underflow_count: <N>
  counter_memory_bytes: <N>
  rebins_per_partition: p50=<N> p95=<N> p99=<N> max=<N>
  percentiles_emitted: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999
  out_of_range_bounded: p1=<none|low|high> ... p99999=<none|low|high>
```

The `csv_output` block emits the shared-partition short form per #189 R7:

```
consumer: csv_output
  path: unified
  shares_partitions_with: summary_table
  percentiles_emitted: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999
  out_of_range_bounded: p1=<none|low|high> ... p99999=<none|low|high>
```

Under `-mdm raw` (or `-ep`), both consumers report `path: pre_migration` or `path: user_opt_out` respectively, with no telemetry block (matching today's behavior for any pre-migration consumer).

#### R8.2 — `=== percentile-algorithm / message-stats ===` updated

The `emit_percentile_algorithm_verbose` sub (`ltl:1910–2007`) is updated:

- The `message-stats` surface entry (`ltl:1956–1959`) changes `effective_track` from `'pinned_raw'` to `'matches_data_model'`.
- The override block (`ltl:1978–1988`) no longer fires for `message-stats`; the standard `$effective_alg = $dm_to_algorithm{$dm}` mapping (`ltl:1991`) produces the correct algorithm name.
- The `effective_algorithm_note:` line referencing "the bin reduction is a follow-up to #266" is no longer emitted for this surface (the divergence the note documents no longer exists).

The `bucket-stats` surface entry continues to use `'pinned_raw'` until its own sibling implementation ticket lands.

#### R8.3 — `=== runtime-config ===` unchanged

The `-mdm` row in `%resolved_values` (`ltl:1592`) is unchanged. The runtime-config section records explicit user configuration; it does not reflect resolved-data-model state for surfaces where the user passed nothing. This matches #266's locked behavior.

### R9 — Test harness contract — #224 Layer 4 cross-model agreement

#### R9.1 — Re-baselining of `*-bin-data-model` MESSAGES baselines

Today, `tests/statistics-drift/baselines/{apache,tomcat,thingworx,codebeamer}-bin-data-model/messages.csv` are byte-identical to the `*-default/messages.csv` baselines (the Day-one Layer 4 sanity check per #224 Decision 9). When #287 ships, the bin path begins producing real bin-counter percentile values; the MESSAGES CSV baselines for the four `*-bin-data-model` scenarios must be re-captured.

The implementation commit captures the new baselines via `./tests/validate-statistics.sh --capture-baselines` (or the equivalent harness command) and commits them. The STATS CSV baselines for these scenarios remain byte-identical to `*-default/stats.csv` because the bucket-stats migration (surface 4) is out of scope here — `-bdm bin` still silently falls back to raw until the sibling ticket lands.

#### R9.2 — `cross-model-tolerances.tsv` per-column envelopes

`tests/statistics-drift/cross-model-tolerances.tsv` is populated with per-column tolerance overrides for the per-message-key percentile columns. Per #224 Decision 9's tier ladder:

- Exact-value statistics (`min`, `max`, `mean`, `std_dev`, `cv`, `skewness`, `kurtosis`, `bimodality_coef`): default ladder (`0% / 1% / 4% / >4%`). The bin path derives these from sidecars whose accumulation is mathematically identical to the raw path's accumulators, so cross-model deviation should sit at `T1` (bitwise) modulo numerical rounding from the moment-sum order of operations.
- Percentile ladder (`p1`...`p99999`, `iqr`): per-percentile envelopes matching the bin-resolution bound at `buckets_per_decade=53` (#187 R4 specifies ~2.2% width / ~1.1% midpoint error at the locked default). Initial envelope: T2 at 1%, T3 at 4% (matching the default ladder; the bin path's structural error sits comfortably inside this on canonical datasets). Per-scenario tightening may follow empirical observation on the four canonical datasets.

The exact tolerance values are settled at implementation time based on Layer 4 measurement against the four canonical datasets; the contract here is *that* the envelopes are populated, not the specific numbers.

#### R9.3 — Layer 3 oracle dispatch already in place

#280's `-V percentile-algorithm` section already declares the effective algorithm per surface; the Layer 3 oracle in `tests/statistics-drift/oracle/calculate-reference.py` dispatches on this section to choose `nearest_rank` vs `exponential_interpolation_within_bucket` for its reference computation. When R8.2 updates the `message-stats` surface to report the resolved algorithm correctly, the oracle's dispatch becomes automatically correct for the bin scenarios without code change.

### R10 — Memory contract

Per-key memory under `-mdm bin` is bounded by `O(partition_size)` rather than `O(sample_count_per_key)`. At #187 Decision 2's locked default `buckets_per_decade = 53` × 5 decades initial span, a partition holds ~265 in-range bins plus 2 out-of-range counters plus the partition's `[min, max]` and `bin_count` scalars — approximately 2 KB per partition (8 bytes per counter × 267 counters + scalar overhead) per #189's V2 closed-form-no-boundary-array implementation.

The five sidecar scalars (`min`, `max`, `m2_sum`, `m3_sum`, `m4_sum`) add 40 bytes per key. The existing accumulators (`occurrences`, `total_duration`, `sum_of_squares`) add another 24 bytes (already paid in the raw path).

Total per-key overhead under `-mdm bin`: ~2 KB. Per-key overhead under `-mdm raw` is `8 bytes × sample_count` for the `durations[]` array (Perl scalar array element size is dominated by the SV header; the 8-byte figure is a lower bound). The cross-over is around 256 samples per key — at higher sample counts per key, the bin path is more memory-efficient.

For runs at 10⁵ keys × 1000 samples per key: raw path retains ~800 MB of duration samples; bin path holds ~200 MB of partitions (matches #189 V2's empirical projection at 10⁵ partitions / locked default bpd).

### R11 — Determinism

The bin path is deterministic for a given input per #187 R6. Same input file, filters, and CLI flags produce the same partitions (same lifecycle events in the same order), the same sidecar accumulator state (same arithmetic on the same operands in the same order), and therefore the same statistic values.

The cross-model `T1` (bitwise) tier reported by #224 Layer 4 may not hold for percentile values (the bin path produces interpolated values, the raw path produces sample-indexed values — different outputs by design per #272). Exact-value statistics produced via sidecars *should* hold `T1` modulo the order-of-operations rounding difference between `(((x1−μ1)² + (x2−μ2)²) + …)` (raw path's array-reduction order at `ltl:8800`) and the Welford-Pébay incremental update sequence (bin path's order). When this rounding difference exceeds the `T1` threshold on a real dataset, the `T2` advisory tier (#224 Decision 9) covers it; persistent `T3+` divergence is an algorithmic bug.

### R12 — `-mdm raw` byte-identity contract

Under `-mdm raw` (and under `-mdm` unset → default raw), every output surface — summary table cell values, MESSAGES CSV cell values, `-V` runtime-config rows, `-V percentile-algorithm` block, `-V histogram-bin-counters` blocks for surfaces other than `summary_table`/`csv_output` — is byte-identical to the pre-#287 output.

The `summary_table` and `csv_output` blocks in `-V histogram-bin-counters` change from `path: pre_migration` to `path: pre_migration` (unchanged — they only flip to `unified` under `-mdm bin`) or `path: user_opt_out` (when `-ep` is set). The block structure itself is unchanged.

### R13 — Boundaries with other features

This feature owns:

- The producer-side bin-path accumulation (R2) for surface 3.
- The consumer-side bin-path derivation (R3) for surface 3.
- The consolidation merge under bin for surface 3 (R2.3).
- The `-V` output updates that surface the migration (R8).
- The test-harness re-baselining for the four `*-bin-data-model` MESSAGES scenarios (R9.1).

This feature does NOT own:

- The unified primitive contract — owned by **#187**. This ticket consumes the locked contract; no contract changes.
- The primitive implementations — owned by **#189** (shipped via #34). No primitive surface changes.
- Per-time-bucket statistics migration (surface 4, `time_bucket_stats`) — owned by its own sibling implementation ticket.
- Heatmap and histogram migrations — owned by **#34** (shipped).
- Highlight-subset migration (surface 5+) — owned by **#51**.
- Removal of `--exact-percentiles` — separate follow-up; deprecation only here.
- Removal of the raw-array path or `durations[]` data structure — both remain as the `-mdm raw` and `-ep` opt-out paths per #187 Decision 7.
- Whether `-mdm bin` becomes the default on this surface, and when — implementation-ticket call per #187 Decision 9's dissolution; this feature ships the path on opt-in only.

## Code touch points

| File:line (release/0.14.6 HEAD) | What changes |
|---|---|
| `ltl:7466–7477` (per-key lazy initializer) | Extend the `//= { ... }` initializer to allocate `bin_partition: undef` and the new sidecar fields when the resolved data model is `bin`. (Under raw, structure unchanged.) |
| `ltl:7449–7453` (consolidation s1-matched stats_source) | Branch on resolved data model: under bin, replace `durations: [$duration]` with a `counter_update` against a freshly-constructed partition; update sidecars. |
| `ltl:7500–7513` (parse-loop duration update) | Branch on resolved data model: under bin, replace the `push @{ ... {durations}}, $duration` at `ltl:7506` with a `counter_update`; update min/max sidecars; feed the Welford-Pébay online moment update. |
| `ltl:4582–4583` (cluster reinject into `%log_messages`) | Under bin: copy `bin_partition` and sidecars from the consolidated cluster instead of `durations[]`. |
| `ltl:5003–5020` (`merge_consolidation_stats`) | Add the bin-merge branch per R2.3: per-bin add the two partitions (extending the narrower if needed); merge sidecars via Chan-Welford-Pébay formulas. |
| `ltl:8616–8651` (per-key dispatch in `calculate_all_statistics`) | Under `dm = 'bin'`, call the new `calculate_statistics_bin($entry)` and store the return tuple. Under raw, the existing `calculate_statistics($aggregated_data)` runs unchanged. |
| `ltl` (new sub, alongside `calculate_statistics`) | `calculate_statistics_bin($entry)` — returns the 22-tuple per R3.2. |
| `ltl:1956–2007` (`emit_percentile_algorithm_verbose`) | Change `message-stats` entry's `effective_track` from `'pinned_raw'` to `'matches_data_model'`; remove the override block's effect on `message-stats` (R8.2). |
| `ltl:2068–2165` (`emit_bin_counter_mode_verbose`) | Add `summary_table` + `csv_output` to `%migrated`; extend `%shares_with`, `%percentile_set`, `%partition_keying`; populate `%bin_counter_telemetry{summary_table}` at end-of-parse from the partition state (R8.1). |
| `tests/statistics-drift/baselines/{apache,tomcat,thingworx,codebeamer}-bin-data-model/messages.csv` | Re-capture against the new bin path (R9.1). |
| `tests/statistics-drift/cross-model-tolerances.tsv` | Populate per-column envelopes for the four `*-bin-data-model` MESSAGES scenarios (R9.2). |
| `docs/usage.md` (the `-mdm` entry) | Update the description: remove "selector resolved but currently only the raw reduction is implemented for this surface; `bin` lands in a follow-up". |
| `print_help()` | Same update for the `-mdm` help line at `ltl:3773`. |
| `releases/v0.14.7.md` (or active release) | One bullet referencing #287 per CLAUDE.md release process. |
| `CLAUDE.md` | No change unless a release-process surface mentions the surface-3 fallback; sweep to confirm. |

## Algorithm appendix

### Welford-Pébay online update for centered-moment accumulators (per-sample)

For each new observation `x`, the running accumulators `(n, mean, M2, M3, M4)` are updated as follows (Pébay 2008, "Formulas for Robust, One-Pass Parallel Computation of Covariances and Arbitrary-Order Statistical Moments", Sandia Report SAND2008-6212):

```
n_old = n
n     = n + 1
delta = x - mean
delta_n = delta / n
delta_n2 = delta_n * delta_n
term1 = delta * delta_n * n_old

mean  = mean + delta_n
M4    = M4 + term1 * delta_n2 * (n*n - 3*n + 3)
            + 6 * delta_n2 * M2
            - 4 * delta_n  * M3
M3    = M3 + term1 * delta_n * (n - 2)
            - 3 * delta_n * M2
M2    = M2 + term1
```

The `M_k` accumulators (`m2_sum`, `m3_sum`, `m4_sum` in the R2.2 sidecar set) are the running sums of `Σ(x − μ_n)^k` evaluated at the current running mean — i.e. `n` times the central moment `m_k`. The conversion at consumer time is `m_k = M_k / n`.

The downstream skewness/kurtosis/BC formulas at `ltl:8811–8814` consume `m2 = M2/n`, `m3 = M3/n`, `m4 = M4/n` and apply unchanged. The bias-corrected sample formulas remain authoritative; the bin path changes only the source of `m2`/`m3`/`m4`, not the formulas.

### Chan-Welford-Pébay parallel-merge for consolidation

When two clusters A and B are merged in `merge_consolidation_stats` (R2.3), the moment accumulators combine as follows:

```
n_AB    = n_A + n_B
delta   = mean_B - mean_A
mean_AB = mean_A + delta * n_B / n_AB

M2_AB   = M2_A + M2_B
        + delta^2 * n_A * n_B / n_AB

M3_AB   = M3_A + M3_B
        + delta^3 * n_A * n_B * (n_A - n_B) / (n_AB ^ 2)
        + 3 * delta * (n_A * M2_B - n_B * M2_A) / n_AB

M4_AB   = M4_A + M4_B
        + delta^4 * n_A * n_B * (n_A^2 - n_A*n_B + n_B^2) / (n_AB ^ 3)
        + 6 * delta^2 * (n_A^2 * M2_B + n_B^2 * M2_A) / (n_AB ^ 2)
        + 4 * delta   * (n_A * M3_B - n_B * M3_A) / n_AB
```

`occurrences` (= `n`), `total_duration` (= `Σx`), `sum_of_squares` (= `Σx²`) are linear and add directly. `min` and `max` take elementwise min/max. The bin partitions per-bin-add after aligning their geometries via #189's `partition_extend` (the narrower of the two is extended to the wider; existing counts retain their indices per #187 Decision 5's lifecycle).

### Bin-counter merge

The bin partitions of clusters A and B are merged via #189's existing primitives:

- If `A.partition.[min, max] ⊇ B.partition.[min, max]`, then `partition_extend(B, A.min, A.max)` brings B onto A's geometry; per-bin add.
- If `B.partition.[min, max] ⊇ A.partition.[min, max]`, symmetric.
- Otherwise (overlapping but neither contains the other), extend whichever is narrower in each direction.

Overflow and underflow counters add directly. No new primitive surface is required; this is the existing #189 `partition_extend` composition pattern.

## Edge cases

| Case | Required behavior |
|---|---|
| `-mdm` unset, no `-dm`, no `-ep` | `choose_data_model('message-stats')` returns `undef` → caller defaults to raw → raw path runs end-to-end. Output byte-identical to today. |
| `-mdm raw` | Raw path runs; output byte-identical. |
| `-mdm bin` | Bin path runs end-to-end. R1–R8 apply. |
| `-mdm bin -ep` (both set) | `-mdm bin` wins per #266's resolution chain (per-surface flag > omnibus > internal logic; `-ep` is only consulted at the internal-logic step, which `-mdm bin` short-circuits). Bin path runs. `summary_table` and `csv_output` `-V` blocks report `path: unified`. |
| `-ep` only (no `-mdm`) | `-ep` forces raw via `choose_data_model`'s fallback at `ltl:1398`. Raw path runs. `-V` blocks report `path: user_opt_out`. |
| `-dm bin -mdm raw` | Per-surface flag wins per #266; raw runs. |
| First duration sample for a new `(category, log_key)` | Partition lazily constructed centered on the sample (5 decades, #189 R1). Sidecars initialized: `min = max = sample`; `M2 = M3 = M4 = 0`; `total_duration = sample`; `sum_of_squares = sample²`. |
| Subsequent value outside partition `[min, max]` | Partition extends via doubling rebin per #189 R1. Existing bin counts preserved. Rebin event tallied in `%bin_counter_telemetry{summary_table}`. Sidecar `min`/`max` updated; Welford-Pébay update proceeds normally. |
| Value beyond partition after doubling cap | Counted in underflow or overflow counter per #189 R6. Per-quantile `out_of_range_bounded` audit field reflects this for any quantile whose target rank lands in the out-of-range counter. |
| All-same value (degenerate per-key distribution) | Partition has one populated bin; every percentile equals that value (Decision 1 formula returns `upper` for `bin_count = 1`). `std_dev = 0`, `cv` undef (mean != 0 guard at `ltl:8770`). Moments undef (`m2 > 0` guard at `ltl:8808`). Matches raw path output. |
| Single observation per key | Partition has one populated bin; all percentiles equal that value. `std_dev`, `cv`, `skewness`, `kurtosis`, `bimodality_coef` all undef (n < 4 guard at `ltl:8795` + (n < 2) guard at `ltl:8765`). Matches raw path. |
| Per-key `occurrences = 0` | `calculate_statistics_bin` returns undef (matches `calculate_statistics`'s early return at `ltl:8752`). |
| `--omit-durations` set | No duration accumulation at producer side (existing gate at `ltl:7500`); no partition is allocated for any key; consumer skips the dispatch entirely (gate at `ltl:8616`). Output unchanged. |
| Fuzzy consolidation merging two clusters | R2.3 applies. Sidecars merge via Chan-Welford-Pébay; partitions per-bin-add after geometry alignment via `partition_extend`. |
| Cluster reinject after consolidation | R2.1 cluster-reinject site at `ltl:4582–4583` copies `bin_partition` and sidecars; no `durations[]` array. |
| `-pbpd N` or `--percentile-precision M` (precision lever) | Applied uniformly per #187 Decision 2. The active bpd shapes every partition's bin count. `-V` reports the active bpd and source per Decision 8. |

## Acceptance criteria

### Producer side

- [ ] Under `-mdm bin`, no per-key `durations[]` array is allocated at `ltl:7466`, `ltl:7506`, `ltl:7453`, or `ltl:4583`.
- [ ] Per-key bin-counter partition is lazily constructed on first observation; auto-resizes via doubling-rebin per #187 Decision 5.
- [ ] Sidecar accumulators (`min`, `max`, `m2_sum`, `m3_sum`, `m4_sum`) are maintained per-key under `-mdm bin`.
- [ ] `merge_consolidation_stats` correctly merges two clusters' partitions and sidecars under `-mdm bin`.
- [ ] Under `-mdm raw` (or unset), every producer write site runs identically to pre-#287 code.

### Consumer side

- [ ] `calculate_all_statistics` dispatch at `ltl:8622` correctly calls `calculate_statistics_bin` under `dm = 'bin'`.
- [ ] `calculate_statistics_bin` returns the 22-tuple per R3.2 with each statistic derived per the table.
- [ ] `calculate_statistics` is preserved verbatim; `-mdm raw` and `-ep` output is byte-identical.

### `-V` output

- [ ] `=== histogram-bin-counters ===` `summary_table` block reports `path: unified` under `-mdm bin`; `path: pre_migration` under raw/default; `path: user_opt_out` under `-ep`.
- [ ] `=== histogram-bin-counters ===` `csv_output` block emits `shares_partitions_with: summary_table` short form per #189 R7.
- [ ] `summary_table` block fields populated from real partition state via `%bin_counter_telemetry`.
- [ ] `=== percentile-algorithm / message-stats ===` reports `effective_algorithm: exponential_interpolation_within_bucket` under `-mdm bin`; `nearest_rank` otherwise. No `effective_algorithm_note:` line emitted for this surface.

### Test harness

- [ ] Four `*-bin-data-model/messages.csv` baselines re-captured under `tests/statistics-drift/baselines/`.
- [ ] `cross-model-tolerances.tsv` populated with per-column envelopes for the per-message percentile columns.
- [ ] `tests/validate-statistics.sh` exits 0 against fresh baselines (no T3/T4 across L1/L2/L3/L4).
- [ ] `tests/validate-regression.sh` continues to pass (raw path output unchanged).
- [ ] `tests/validate-csv-output.sh` continues to pass (CSV column structure unchanged).
- [ ] `tests/validate-runtime-config.sh` continues to pass (`-mdm` row format unchanged).

### Docs

- [ ] `docs/usage.md` `-mdm` row description updated to drop the "falls back" note.
- [ ] `print_help()` `-mdm` line at `ltl:3773` updated similarly.
- [ ] Release notes bullet added.

## Validation

This feature's correctness is validated through the #224 statistics-drift harness; no new harness is introduced. The harness's four layers each apply:

- **Layer 1 (drift)** — fresh CSVs vs committed baselines. Re-baselining is part of the implementation commit (R9.1); post-baseline, Layer 1 reports `T1` on every cell.
- **Layer 2 (intra-row arithmetic)** — `mean == duration / occurrences`, `iqr == p75 − p25`, percentile monotonicity. All apply to bin-path output unchanged.
- **Layer 3 (external NumPy/SciPy oracle)** — dispatches on `-V percentile-algorithm` (#280); R8.2's update makes the oracle's dispatch automatically correct for bin scenarios. The oracle computes `exponential_interpolation_within_bucket` for `-mdm bin` MESSAGES rows and `nearest_rank` for `-mdm raw` MESSAGES rows.
- **Layer 4 (cross-model agreement)** — pairs `*-default ↔ *-bin-data-model` MESSAGES CSVs and reports per-cell deviation. Pre-#287, this pairing is a wiring sanity check (`T1` on every cell because both runs execute the raw path). Post-#287, it measures real bin-vs-raw deviation against `cross-model-tolerances.tsv` envelopes.

Additionally:

- `tests/validate-regression.sh` — must continue to pass (raw path is unchanged).
- `tests/validate-csv-output.sh` — must continue to pass (CSV structure is unchanged; only cell values change under `-mdm bin`).
- `tests/validate-runtime-config.sh` — must continue to pass.
- Manual `-V` inspection — confirm `=== histogram-bin-counters ===` blocks for `summary_table` and `csv_output` emit the locked Decision 8 contract fields with populated telemetry, on a representative input run under `-mdm bin`.

## Out of scope

- The unified primitive contract — owned by #187. No contract changes.
- Primitive implementations — owned by #189. No primitive surface changes.
- Per-time-bucket statistics migration (surface 4, `time_bucket_stats`) — owned by its own sibling implementation ticket.
- Whether `-mdm bin` becomes the default on this surface — implementation-ticket call per #187 Decision 9's dissolution. This ticket ships the path on explicit opt-in only.
- Removal of `--exact-percentiles` — separate follow-up.
- Removal of the raw-array path — preserved as the `-mdm raw` and `-ep` opt-out per #187 Decision 7.
- Changes to existing percentile values under `-mdm raw` — none.
- Changes to existing `-V runtime-config`, `-V csv-output`, or other already-shipped `-V` sections — none, beyond the two `-V` sections explicitly named in R8.

## Related issues

- **#187** — owns the locked unified primitive contract. Authoritative reference. `features/187-histogram-bin-counter-percentiles.md`.
- **#189** — primitive implementations (shipped via #34). `features/189-histogram-bin-counter-primitives.md`.
- **#34** — sibling F2/F3 migration (shipped). Pattern precedent for this feature's structure and the sibling-sub split.
- **#266** — `-mdm` selector wiring (shipped). This feature consumes the resolved selector at `ltl:8622`.
- **#272** — locked percentile-algorithm pair (raw nearest-rank, bin exponential-interpolation). This feature applies the pair to surface 3.
- **#280** — `-V percentile-algorithm` section (shipped). This feature updates the `message-stats` surface entry per R8.2.
- **#224** — statistics-drift test harness (shipped). Validates this feature's output via Layers 1–4.
- **Sibling ticket (not yet filed)** — per-time-bucket statistics migration (surface 4). Independent of this feature.
- **#51** — highlight-subset migration (Phase 4 per #187 R9). Independent.

## Spec stability

The contract surface (R1–R13) tracks #187's locked unified contract. Changes to the locked contract in #187 cascade here; this feature does not lock decisions independently of #187.

The code touch points table is the technical inventory at the time of writing against `release/0.14.6` HEAD. Line numbers may shift; subroutine names (`calculate_all_statistics`, `calculate_statistics`, `merge_consolidation_stats`, `emit_bin_counter_mode_verbose`, `emit_percentile_algorithm_verbose`, `choose_data_model`) and global identifiers (`%log_messages`, `%bin_counter_telemetry`, `$data_model_message`, `$exact_percentiles_optout`) are the stable anchors.
