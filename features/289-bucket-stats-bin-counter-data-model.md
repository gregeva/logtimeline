# Issue #289 — Per-time-bucket statistics: bin-counter data model end-to-end (`-bdm bin`)

Sibling of #287 (per-message-key, `-mdm bin`, shipped via PR #290). This issue does the
equivalent end-to-end producer + consumer migration for the **per-time-bucket statistics**
surface (`time_bucket_stats` consumer): the statistics row rendered inline on the bar-graph
time-bucket row, and the STATS CSV via `-o`.

The `-bdm` selector already parses, resolves, and is recorded in `-V runtime-config` (#266);
today the consumer ignores the resolved model and always runs the raw-array reduction. This
issue makes the `bin` branch real.

## Design

### What the user observes

- Under `-bdm bin`, the per-time-bucket statistics (STATS CSV + inline bar-graph stats row)
  are computed via the bin-counter data model (Prometheus-style exponential interpolation for
  percentiles; Welford-Pébay sidecars for the exact-value and shape statistics).
- Under `-bdm raw` (the default), output is **byte-identical** to today.
- `-dm bin` (omnibus) now engages bin counters on **all four** surfaces; pre-this-issue it
  silently fell back on bucket-stats.
- The `-V percentile-algorithm / bucket-stats` block's `effective_algorithm` tracks the
  resolved model; the "bin reduction is a follow-up to #266" note disappears.
- The `time_bucket_stats` consumer in `-V histogram-bin-counters` moves from
  `path: pre_migration` to `path: unified` (under `-bdm bin`) or `path: user_opt_out`
  (under `-bdm raw`), with the locked Decision 8 telemetry fields.

### Two divergences from the issue body (confirmed with the architect 2026-05-27)

The issue body locks two design points that code inspection proved incorrect. Both were
re-decided before planning. **The issue body must be amended to match before close.**

1. **`_HL` highlight overlay — bin path at parity with raw, no new overlay.**
   The issue says to "migrate the `_HL` overlay together." But the per-time-bucket statistics
   surface has **no** highlight statistics today: `%log_stats` carries highlight *totals*
   (`duration-HL`, `bytes-HL`, `count-HL`) only; there is no `min-HL`/`p50-HL`/`std_dev-HL`
   anywhere, no `sum_of_squares-HL`, and no `durations-HL` array — the raw producer never
   split duration samples by highlight. Inventing a parallel HL statistics set would change
   raw output (new columns) and break the byte-identical contract. **Decision:** migrate only
   what exists. A true HL statistics overlay is a separate ticket.

2. **Dedicated store, not shared with heatmap.**
   The issue locks "single shared store: rename `%heatmap_counters` → `%time_bucket_counters`,
   both consumers read it." This is incorrect: the heatmap store observes `$heatmap_value`,
   which equals `$duration` **only** under `-hm duration`; under `-hm bytes`/`-hm count` it
   holds the wrong samples, and it is not populated at all when heatmap is off (the default).
   Sharing would give wrong or absent bucket-stats data in the common cases. **Decision:** add
   a dedicated `%bucket_stats_counters` (+ `_hl`) keyed by `time_bucket`, observing `$duration`.
   A **follow-up issue** inverts the sharing in the correct direction — have the heatmap reuse
   the bucket-stats time-bucket store when its metric is duration — so the memory-convergence
   optimization the issue wanted lands where it is actually correct. (See "Follow-up" below.)

### Producer (parse-time accumulation)

Resolve `$bucket_stats_capture_mode = choose_data_model('bucket-stats') // 'raw'` once before
the parse loop (alongside the existing heatmap/histogram/message-stats capture modes).

In the per-bucket duration block (today: `$log_analysis{$bucket}{...}` accumulation, with the
raw `push @{...{durations}}, $duration unless $heatmap_enabled`), under
`$bucket_stats_capture_mode eq 'bin'`:

- `counter_update(\%bucket_stats_counters, $bucket, $duration)` when `$duration > 0`
  (log-spaced partitions cannot bin zero — mirrors the message-stats and heatmap producers).
- Maintain per-bucket sidecars on `%log_analysis{$bucket}`, fed on **every** duration sample
  including 0 (so the exact-value statistics match raw byte-for-byte): `min`, `max`,
  `duration_count`, `_running_mean`, and the Welford-Pébay `m2_sum`/`m3_sum`/`m4_sum`.
  `total_duration` and `sum_of_squares` already accumulate today.
- The `_hl` variant (`%bucket_stats_counters_hl`) is populated in parallel when the bucket is
  highlighted — populated for store parity with the heatmap pattern, **but no HL statistics are
  derived from it** in this issue (divergence 1).

The `unless $heatmap_enabled` gate on the raw `durations[]` push stays as-is for the raw path.
Under bin mode the `durations[]` push is additionally bypassed (the bin store + sidecars carry
equivalent information), mirroring #287 Commit 5.

### Consumer (statistics derivation)

At the bucket-stats dispatch site, branch on the resolved model. Under `bin`, derive the
22-tuple from the per-bucket bin partition + sidecars, mirroring #287's
`calculate_statistics_bin()`:

| Statistic | Derived under `-bdm bin` |
|---|---|
| `min`, `max` | producer sidecar |
| `mean` | `total_duration / duration_count` |
| `std_dev`, `cv` | `sum_of_squares` accumulator (same cancellation guard as raw) |
| `p1`..`p99999` | `percentile($counter_entry, $q)` (#189 R4 exponential interpolation), clamped to `[min,max]` |
| `iqr` | `p75 − p25` |
| `skewness`, `kurtosis`, `bimodality_coef` | Welford-Pébay `m2_sum`/`m3_sum`/`m4_sum` sidecars (bias-corrected formulas, identical to raw) |

Per-quantile `out_of_range_bounded` audit codes returned by `percentile()` aggregate into a
`%bucket_stats_audit` hash (worst-of `high`>`low`>`none`), drained into telemetry at finalize.

The raw consumer path (`calculate_statistics()`) is preserved unchanged under `-bdm raw`.

### Observability (`-V`) — lands with the code that produces the state

Per HARNESS-DESIGN.md, the harness asserts only against `-V` sections, never rendered output.
The two relevant sections already exist; this issue extends their content (non-breaking
additions — no section/key renames, so no reserved-names-list change):

- **`percentile-algorithm / bucket-stats`**: change `effective_track` from `pinned_raw` to
  `matches_data_model` so `effective_algorithm` reports `exponential_interpolation_within_bucket`
  under bin and `nearest_rank` under raw. The follow-up-to-#266 note stops firing.
- **`histogram-bin-counters` / `time_bucket_stats` consumer**: add to `%migrated`; add
  `%partition_keying{time_bucket_stats} = 'time_bucket'`; add `%percentile_set{time_bucket_stats}`
  = the 12-quantile STATS ladder; add `%consumer_opted_out_to_raw{time_bucket_stats}` driven by
  `$bucket_stats_capture_mode`. Add `finalize_bucket_stats_unified()` (mirrors
  `finalize_message_stats_unified()`) to populate `$bin_counter_telemetry{time_bucket_stats}`
  via `snapshot_counter_telemetry(\%bucket_stats_counters)` and drain the audit aggregation.

## Test strategy

Validation rides the #224 statistics-drift harness, which already loops `messages` and `stats`
through all four layers with full kind-parameterization. The STATS surface infrastructure is
pre-staged (scenarios carry `-bdm bin`; the oracle emits per-time-bucket `rows_stats`; the
engine keys STATS rows by `timestamp` and joins the oracle by `bucket`; `stats-columns.tsv`
covers every percentile/shape column). What this issue must do:

- **L1 (drift):** re-capture the four `*-bin-data-model/stats.csv` baselines (Apache/Tomcat/
  ThingWorx/Codebeamer) — currently byte-identical to `*-default`, they diverge once the bin
  path is real. Baselines are deliverables; capture via `--capture-baselines` with the prompt.
- **L2 (intra-row):** confirm the bin-derived STATS rows satisfy percentile monotonicity,
  `min ≤ p1`, `p99999 ≤ max`, `iqr == p75 − p25`, `mean == duration / occurrences` — these now
  validate real bin values, not raw fallback.
- **L3 (oracle):** the oracle dispatches `exponential_interpolation_within_bucket` for the
  `bucket-stats` surface automatically once `effective_algorithm` flips. Correct the stale
  comment in `validate-statistics.sh` that claims exp-interp has no oracle reference (false
  since #287). No oracle code change.
- **L4 (cross-model):** measure default↔bin STATS deviation against `cross-model-tolerances.tsv`;
  add per-column override rows only if a STATS column empirically exceeds the default T3 envelope.

New observability assertions (the gap #287 left for this issue):

- **`tests/validate-histogram-bin-counters.sh`**: add `time_bucket_stats` consumer scenarios
  mirroring #287's 7a/7b/7c — `-bdm bin` (path unified, `partition_keying: time_bucket`,
  populated telemetry, percentile ladder, audit codes), `-bdm raw` (path user_opt_out, no
  telemetry block). Self-documenting assertions per the reference harness.
- **`tests/validate-runtime-config.sh`**: add a `-bdm bin` selector-row assertion (mirrors the
  `-mdm bin` row #287 added).
- **`tests/validate-explain.sh`**: extend bucket-stats prose coverage if `--explain` text
  changes for the STATS surface.

Regression guards that must continue to pass: `validate-csv-output.sh` (structure unchanged),
`validate-regression.sh` (raw path byte-identical).

## Follow-up (separate issue, to be filed)

Invert the store-sharing in the correct direction: when the heatmap metric resolves to
`duration` and both surfaces are in bin mode, have the heatmap consumer reuse the bucket-stats
`time_bucket`-keyed store rather than allocating its own `%heatmap_counters`. This realizes the
single-allocation memory convergence the #289 issue body wanted, but keyed off the surface that
always observes `$duration` (bucket-stats) instead of the surface whose samples vary by
`-hm metric` (heatmap).

## Out of scope

- The unified contract (#187), primitives (#189) — unchanged.
- Per-message-key migration (#287, shipped); heatmap/histogram cell/marker migrations (#34, shipped).
- A true `_HL` statistics overlay for the bucket-stats surface (divergence 1 — separate ticket).
- Removal of `--exact-percentiles` (already removed in #287).
- Whether/when `-bdm bin` becomes the default on this surface.

## Delivery sequence

Each step is independently verifiable; observability lands with the code it observes, and the
harness assertions land immediately after the state they assert exists.

1. Producer: `$bucket_stats_capture_mode`, `%bucket_stats_counters` (+ `_hl`), per-bucket
   sidecars + `counter_update`, bypass raw `durations[]` push under bin.
2. Consumer: bin branch deriving the 22-tuple (`calculate_statistics_bin`-style), `_HL` totals
   unchanged.
3. `-V` percentile-algorithm: bucket-stats → `matches_data_model`.
4. `-V` histogram-bin-counters: `time_bucket_stats` into `%migrated` + keying/percentile-set/
   opt-out maps + `finalize_bucket_stats_unified()`.
5. Harness: `validate-histogram-bin-counters.sh` time_bucket_stats assertions; re-run to confirm
   it asserts (not just exits 0).
6. Docs: `print_help()` `-bdm` text (drop "lands in a follow-up"); `docs/explain` /
   `docs/usage.md` surface-default prose; `--explain` topic prose if changed.
7. Re-capture STATS baselines; run `validate-csv-output.sh` then `validate-statistics.sh`
   (both `CI=1`); measure L4, add tolerance rows only if empirically required.
8. `validate-runtime-config.sh` `-bdm bin` row; `validate-explain.sh` coverage.
9. `validate-regression.sh` green (raw byte-identical).
