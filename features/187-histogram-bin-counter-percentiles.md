# Feature: Bin-counter-based percentile calculation with dual-mode accuracy (multi-phase rollout)

## Overview

This is **a foundational architectural research effort** to identify the right primitives, data structures, and lifecycle patterns to standardize across **all percentile and histogram-related use cases in ltl** — both today's shipped consumers and tomorrow's planned ones. Its output is a **unified primitive contract** that every percentile-computing path in ltl will adopt over a staged rollout.

The motivating observation is that ltl reads raw values from log files at *analysis time*, not at recording time — which means ltl can make design choices that pre-aggregated metric systems (Prometheus, OTEL, HdrHistogram-as-shipped, DDSketch) genuinely cannot. The research catalogued in this feature file determines what those choices are, anchored on cited industry practice where it applies and explicitly documenting where ltl's case requires divergence.

The unified primitive contract that emerges from this research applies to every consumer of percentile or histogram-binned data in ltl:

- The **summary table** per-message latency percentiles (today: `log_messages{$category}{$log_key}{durations}` retained as raw arrays at `ltl:4591`, sorted at `calculate_statistics` `ltl:5488`).
- The **CSV output** (`-o`) — same per-message statistics surface, sharing `calculate_statistics`.
- The **per-time-bucket duration percentile statistics** rendered inline on heatmap rows (today: `log_analysis{$bucket}{durations}` at `ltl:4634`).
- The **heatmap** percentile markers (P50/P95/P99/P99.9) and the heatmap **cell colors** themselves (today: `%heatmap_raw` retained per time bucket and binned at end-of-parse in `calculate_histogram_buckets` at `ltl:4908`).
- The **histogram view** (`-hg`) global percentile indicators and the histogram bin counts (today: `histogram_values{$metric}` retained as raw arrays and binned at end-of-parse).
- **Future planned consumers** including but not limited to: highlight-data subsets (#51), per-API hover-to-redraw renders, any new percentile-computing feature.

The research scope **explicitly includes shipped behavior in its catalogue** — the heatmap and histogram features today retain raw value arrays during the parse and finalize their partitions at end-of-parse from global `min`/`max`, which does not align with the unified contract this research produces. The shipped heatmap and histogram consumers are catalogued in R12 as equally first-class consumers of the contract. Migrating them is *not* part of #187's scope; the implementation tickets that own those consumers (e.g., #34) will use this file's locked contract as their authoritative reference when planning their own migration work. R9 below provides consumer-grouping guidance for those implementation tickets.

The substrate ltl already uses — **HdrHistogram-style log-spaced bin counters** with `boundary[i] = min · (max/min)^(i/N)` (`ltl:4961-4966`), `buckets_per_decade` precision (`ltl:286`), and binary-search bin-find (`ltl:4889-4905`) — is the structural foundation. The research locks in (a) the in-bin percentile-derivation rule (Decision 1, verified against Prometheus `histogram_quantile()`), (b) the precision parameter as an analyst-tunable lever rather than a fixed system constant (Decision 2, anchored on OTEP-149's Scale-4 worked example), (c) out-of-range handling (Decision 4, Prometheus `+Inf` convention with symmetric underflow), and (d) the partition lifecycle (Decision 5, HdrHistogram-style auto-resize per partition, applied uniformly across all consumers in the fan-out).

There is no runtime dual-mode gate in the unified contract. The pre-migration sort-based computation survives per-consumer through that consumer's R9 migration phase as a regression-validation reference (R11), and may persist as a user-facing opt-out surface (practical decision 7) after the phase validates. There is no runtime selection between "approximate" and "exact" paths at the start of a run — each consumer runs the unified contract path unconditionally once its phase has validated. The previous Decision 6 question ("when does approximate mode fire vs. exact at runtime") was dissolved by the locked decisions; full rationale recorded in *Locked decisions from research* § Decision 6.

## GitHub Issue

[#187](https://github.com/gregeva/logtimeline/issues/187)

## Motivation

For multi-GB runs every percentile-or-histogram-related consumer in ltl today retains raw value arrays in memory at substantial scale: per-message duration arrays under `log_messages`, per-time-bucket duration arrays under `log_analysis`, per-metric value arrays under `%heatmap_raw` and `histogram_values`. These arrays are the dominant memory consumers in the analysis pipeline. Each one independently re-implements the "collect raw values, sort or bin at finalization, free arrays" pattern. The patterns differ across consumers in incidental ways that make them not interchangeable, even though they are structurally solving the same problem.

The research that this feature file documents was undertaken to answer: **what is the right primitive contract for all of these consumers to share?**

### What the substrate already settles

ltl ships log-spaced bin counters with `boundary[i] = min · (max/min)^(i/N)` (`ltl:4961-4966`), a `buckets_per_decade` precision knob (`ltl:286`, default 8 in shipped heatmap/histogram code), and binary-search bin-find (`ltl:4889-4905`). The code comments name this the "HdrHistogram approach" (`ltl:285`, `ltl:4867`, `ltl:4956`). The fundamental data-structure choice is therefore not under debate; what was open at the start of this research was *how to derive percentiles from those counters when raw values are not retained*, *what precision parameter to default to*, *what to do about out-of-range values*, and *how to size the partition online*. Those are the questions D1-D5 address.

### What the research locks (summary)

The locked decisions in this file (see *Locked decisions from research* for the authoritative entries) constitute the unified primitive contract. In summary:

- **F1 — Design philosophy**: ltl is the query-time analyzer; precision is a user-tunable lever; rank-in-bin information is used because ltl has it (pre-aggregated systems don't).
- **Decision 1 + 1A — In-bin interpolation**: Prometheus native-exponential `histogram_quantile()` formula, verified verbatim against `promql/quantile.go` lines 331–353.
- **Decision 2 — Precision lever**: `buckets_per_decade` default 53 (OTEP-149 Scale-4 analog); two CLI flags exposing the lever (`-pbpd` numeric, `--percentile-precision 1..9` tiered); valid range 4-616; `-pbpd` wins on conflict.
- **Decision 4 — Out-of-range handling**: Prometheus `+Inf` convention adopted verbatim for high end; symmetric `-Inf`-equivalent for low end; separate counters; overflow/underflow contribute to total N; R4 returns the partition's edge boundary if target rank lands in overflow/underflow; `out_of_range_bounded: high|low|none` audit field per quantile in `-V`.
- **Decision 5 — Partition lifecycle**: HdrHistogram-style auto-resize per partition (per-key for the summary table; per-time-bucket for the heatmap; global for the histogram view); seeded with full-default-span centered on first value; HdrHistogram-convention doubling on rebin. No precedent run or `#179` index dependency for partition sizing. Per-partition rebin telemetry exposed in `-V` so the seeding heuristic is empirically tunable.

These decisions are *contract-level*: they apply uniformly to every consumer of the primitive, not just to one path. Decision 5 in particular says that the lifecycle is HdrHistogram-style auto-resize *for every partition in ltl that builds bin counters from raw values during a parse pass* — which includes the per-time-bucket heatmap partitions and the global histogram partition, not just the per-message-key partitions of the summary table.

### Migration of shipped behavior

Because the locked contract differs from what shipped heatmap and histogram code currently does (end-of-parse partition sizing from retained raw arrays), implementation tickets that migrate those shipped consumers will be changing user-visible behavior. The contract is designed so those changes surface as quality improvements rather than regressions: the new precision default (53 bpd, Decision 2) is higher than today's shipped 8 bpd, so percentile markers and bin counts become *more* accurate; display geometry remains unchanged because Decision 5 supports render-time re-projection.

The audit (R12) catalogues every consumer the contract serves. R12 is the complete list as best we can establish at the time of writing; future consumers introduced after this feature lands inherit the contract by construction.

## Delivery sequence

This feature is one of three co-developed issues (#34, #187, #189) that jointly produce the unified primitive contract and migrate ltl's percentile-and-histogram consumers onto it. The work is performed in parallel against `release/0.14.5` and subsequent release branches; each issue's feature branches merge back periodically. The contract is owned by this file (#187); the primitive implementation is owned by #189; the heatmap/histogram consumer migration is owned by #34. None of the three is "primary"; they are interlocking deliverables of one architectural transition.

| Step | Work | Owner | Why this position |
|---|---|---|---|
| 1 | **Audit** — catalogue every percentile-and-histogram consumer in ltl (shipped and planned); produce consumer-side primitive requirements | **#34 R12** + **#187 R12**; outputs land in **#189** *Audit findings* and *Consumer-side requirements* sections | The unified contract has to be designed knowing every shape it must serve. Without this first, primitives risk being designed for some consumers and reworked when later ones land. |
| 2 | **Research** — literature-grounded study of the substrate's behavior; decision-support memo; the decision conversation that produces the locked contract entries (F1, D1, D1A, D2, D4, D5) | **#187 D1–D5 (D4 conditional)** | The contract entries determine #189's primitive implementations and constrain every consumer migration. Performed after audit so the contract serves real shapes. |
| 3 | **Deliver #189** — implement unified primitive helpers per the locked contract | **#189** | The contract is settled; the primitives implement it. |
| 4 | **Migrate shipped heatmap and histogram consumers** — heatmap and histogram code transition from end-of-parse retained-array partitioning to per-partition auto-resize per the locked contract | **#34 (separate implementation ticket)** | The implementation ticket consuming the contract for these shipped consumers. Corresponds to R9 Phase 3's grouping recommendation (per-time-bucket and global histogram consumers). |
| 5 | **Migrate per-message consumers** — summary-table and CSV output percentiles move to the unified contract | **Separate implementation ticket (not #187)** | Per-`(category, log_key)` partition shape. Corresponds to R9 Phase 2's grouping recommendation (per-message consumers). |
| 6+ | **Migrate remaining consumers** — highlight-data subsets (Phase 4, coordinates with #51); any future percentile consumer (Phase 5) | **Their respective implementation tickets** | Each consumer's migration is owned by its implementation ticket; R9 below provides grouping guidance. |

### Steps 1-3 are owned by #187; steps 4+ are owned by separate implementation tickets

Steps 1 (audit), 2 (research), and 3 (primitive delivery via #189) are the foundation work this file documents. Steps 4 and onward are *consumers of this foundation* — they are migrations owned by the implementation tickets for each consumer group, with this file's locked contract as their authoritative reference.

### Parallelism

Steps 1 and 2 may proceed in parallel once the audit has produced enough consumer-side requirements for the research to evaluate the substrate against. Step 3 (#189 implementation) cannot complete until step 2 locks the contract. Steps 4+ (consumer migrations) gate on #189's primitives being complete; their internal planning, validation strategy, and release sequencing are owned by the respective implementation tickets.

## Terminology

Throughout this document:

- **Unified primitive contract** — the set of locked decisions (F1, D1, D1A, D2, D4, D5) that govern how every percentile-and-histogram consumer in ltl works. The contract is contract-level, not consumer-specific.
- **Histogram bin counters** — the underlying data structure (log-spaced bin geometry, counter per bin, no retention of raw values). Built from primitives owned by #189 R1-R4; used by every consumer per the unified contract.
- **Consumer** — any code path in ltl that needs percentile values or histogram bin counts derived from a stream of observed values. Examples: summary-table, CSV output, per-time-bucket statistics, heatmap cells and markers, histogram view, future hover-to-redraw renders, future highlight subsets.
- **Partition** — one instance of the bin counter structure with its own `[min, max]` boundaries, owned by one consumer for one keying dimension (per-(category, log_key) for the summary table, per-time-bucket for the heatmap, global for the histogram view, etc.).
- **Auto-resize** — the partition lifecycle defined in Decision 5: partition is constructed lazily on first observation, sized at the locked default span centered on that first value, and extended via HdrHistogram-convention doubling on rebin events.

The architectural posture is: one contract, one primitive set, many consumers — each consumer parameterizes the primitives for its own keying and rendering but does not invent its own variant of the partition lifecycle, in-bin rule, precision parameter, or out-of-range handling.

## Requirements

### R1 — Unified primitive contract is the single percentile-computation path

Every consumer of percentile values or histogram bin counts in ltl (per the R12 audit) computes percentiles via the unified primitive contract locked in the *Locked decisions from research* section: the log-spaced bin-counter substrate (Decision 5 lifecycle, Decision 2 precision lever), Decision 1's in-bin interpolation formula, Decision 4's out-of-range handling, Decision 3's no-per-bin-guard posture. There is no parallel computation path under the unified contract.

The pre-migration sort-based computation (`calculate_statistics` at `ltl:5488` and the end-of-parse retained-arrays pattern in `calculate_histogram_buckets` at `ltl:4908`) survives **per consumer, through that consumer's R9 migration phase**, as a regression-validation reference (see R11, R13a). After a consumer's phase validates clean against the baseline harness, that consumer's pre-migration code may be retired or retained per practical decision 7 (user opt-out preference).

### R2 — No runtime gate; phase-validation is the only switching mechanism

There is no runtime gate that decides between an "approximate path" and an "exact path" within a consumer. Each consumer migrates onto the unified contract through its R9 phase; the migration is validated against the baseline-regression harness in exact mode (the pre-migration code) for byte-identity per R11. Once the phase validates, that consumer runs the unified-contract path unconditionally for subsequent runs.

The only opt-back-out mechanism available to users is whatever practical decision 7 produces (e.g., a `--exact-percentiles` flag). That mechanism is a user-facing preference, not a runtime gate. R10 lists the surviving reason codes.

The previously specified gating criteria (R2.1 index pre-seed, R2.2 tier match, R2.3 input criteria) are dissolved per *Locked decisions from research* § Decision 6:

- **R2.1** — Decision 5's auto-resize lifecycle removed the upfront `[min, max]` requirement, so #179's index is no longer load-bearing for partition sizing.
- **R2.2** — Tier-correctness for filtered runs persists as an audit/observability concern (see R7 Layer 2 below) but does not gate the unified contract.
- **R2.3** — Input criteria are not used to switch modes at runtime under the unified contract.

### R3 — Required percentile values

The unified contract must produce all percentile values required by the catalogued consumers (R12):

- **Path A and Path A'** (summary table, CSV output): P1, P50, P75, P90, P95, P99, P99.9.
- **Path B** (per-time-bucket statistics): P1, P50, P75, P90, P95, P99, P99.9.
- **Path C1** (histogram-mode global): P1, P10, P25, P50, P75, P90, P95, P99, P99.9, P99.99 (ten values, the widest set required).
- **Path C2** (heatmap markers): P50, P95, P99, P99.9.
- **Path C2-cells, Path C1-bins**: bin counts (not percentile values).

#189 R4 (Decision 1's locked formula) must accept any quantile in `(0, 1)`; consumers select which percentiles they emit.

### R4 — Documented accuracy contract

The unified contract's accuracy is governed by:

- **Bin-resolution error** — bounded uniformly by partition geometry. At Decision 2's locked default `buckets_per_decade = 53`, per-bin width is ~1.044× (~2.2% width, ~1.1% midpoint error). The bound applies uniformly across quantiles. Tighter precision available via Decision 2's CLI lever (`--percentile-precision` 1..9 maps to bpd 4..616; `-pbpd N` for direct numeric override).
- **Out-of-range bounding** — when a target rank lands in the overflow or underflow counter (Decision 4), R4 returns `boundary[B]` or `boundary[0]` respectively. The `-V` audit field `out_of_range_bounded: high|low|none` per quantile makes this visible.

The accuracy contract is **structural** (derived from partition geometry and the Decision 1 formula), not empirical. It applies to every consumer running the unified contract. R7 reports the active precision parameter and the per-quantile out-of-range audit field.

The acceptance criterion is that for any input in the D2 representative-dataset set, every required quantile from the unified contract falls within the bin-resolution bound around the pre-migration exact-mode value. This is the baseline-regression validation that each R9 phase runs against `tests/baseline/`.

### R5 — Degenerate-input behavior

The unified contract handles the following inputs without crashing and without producing nonsensical values:

- **Zero matched values** — percentiles emit `-` (today's behavior preserved). No partition is constructed; no R4 invocation occurs.
- **All-same value** — single bin is populated; every percentile equals that value (the Decision 1 formula returns `upper` for any quantile that lands in the single bin via fraction = 1.0, and `lower = upper` for an all-same input by partition geometry).
- **Single value** — partition is constructed with a single observation; the partition's single populated bin contains that observation; every percentile equals that value.
- **Small N** — Decision 1's formula computes for any positive `bin_count`. Decision 3 locked the posture of no per-bin guard. Small-N inputs produce well-defined output; rank-support concerns are not surfaced as warnings in `-V` (Decision 3).

### R6 — Determinism

The unified contract is deterministic for a given input. The Decision 1 formula is purely arithmetic; the Decision 5 lifecycle is deterministic (auto-resize triggers are deterministic functions of the value sequence); no randomization is used. Same input file, filters, and CLI flags produce the same percentile values across runs.

### R7 — `-V` observability

A dedicated `=== BIN-COUNTER MODE ===` section reports the unified contract's state. The full format, field names, consumer-name strings, and structural conventions are locked in *Locked decisions from research* § Decision 8. R7 is the requirements-section anchor; Decision 8 is authoritative.

The contract surface includes (full detail in Decision 8):

- **Run-level header**: `opt_out_active`, `opt_out_notice` (when active), `percentile_precision` (resolved tier with source), `buckets_per_decade` (resolved numeric value with source).
- **Per-consumer blocks** (one per consumer catalogued in R12): `consumer:` opener, `path:` (R10 code), and when on the unified path, the locked per-consumer field set (`partition_keying`, `partition_count`, rebin telemetry from Decision 5, overflow/underflow audit aggregates and per-quantile audit from Decision 4, `percentiles_emitted`, `out_of_range_bounded:` inline per-quantile).
- **Shared-partition consumers**: `shares_partitions_with:` short-form blocks.
- **Section presence**: always emitted under `-V`; reports `consumers_active: none` when no consumer is computing.

The section name (`=== BIN-COUNTER MODE ===`), all field names, and all consumer-name strings are part of the locked feature contract per Decision 8. Field-name changes require a new locked-decision entry.
- **Rebin telemetry (per-consumer using the unified path)**: `total_rebin_events`, `rebins_per_key { p50, p95, p99, max }`, `max_partition_bins` (Decision 5 lock; intended to support empirical seed-heuristic tuning).
- **Tier-correctness for filtered runs**: if a run includes a filter, `-V` reports the filter context so an analyst can audit whether the result is appropriate (R2.2 reframed as audit concern, not gate).
- **Pre-migration consumers (any still running the sort-based path during phased migration)**: `n` (the value count consumed) and `sorted: yes` line, matching R11's byte-identical contract.

Section name (`=== BIN-COUNTER MODE ===`) and the core field labels are part of the feature contract. Practical decision 8 settles cosmetic and verbosity details.

### R8 — Coupling to the unified primitive contract

The unified contract operates on **histogram bin counters** built from primitives owned by #189 (R1: partition with Decision 5's auto-resize lifecycle; R2: assignment via binary search; R3: counter update keyed per consumer per R12; R4: percentile derivation via Decision 1's locked formula). No consumer maintains a parallel data structure; no consumer introduces an independent estimator.

This is contract-level: heatmap, histogram view, summary table, CSV output, per-time-bucket statistics, future hover-to-redraw, future highlight subsets all consume the same primitive set with their consumer-specific keying.

### R9 — Consumer-grouping guidance for the per-consumer implementation tickets

R9 is **guidance for the implementation tickets** that consume this research deliverable's unified contract. It is *not* part of #187's scope to ship migrations, define release cadence, or specify activation policies — those decisions belong to the per-consumer implementation tickets (e.g., the Path A migration ticket, #34's heatmap/histogram migration, #51's highlight migration). R9 groups the consumers catalogued in R12 into coherent migration phases so that the implementation tickets can be planned with awareness of cross-consumer dependencies and natural co-shipping pairs.

Each phase below names a group of consumers that the implementation tickets are encouraged to migrate together (or in sequence), with the rationale for the grouping. The phases are *recommendations* informed by the locked contract and the R12 audit, not binding milestones.

**Phase grouping recommendations**:

- **Phase 0 — Foundation (this feature file).** The locked unified contract (F1, D1, D1A, D2, D3, D4, D5, D7, D8). The R12 audit. The R9 grouping guidance. The downstream-implications catalogue. **Output of this issue.** Implementation tickets reference this file's locked decisions as their authoritative contract.

- **Phase 1 — Research (D1–D5).** Industry-grounding study, dataset cross-reference, decision-support memo, and (if triggered) prototype. **Output of this issue.** Implementation tickets do not re-do this research.

- **Phase 2 — Per-message percentile consumers (Path A and Path A' grouped).** The summary-table per-message percentiles and the CSV output share `calculate_statistics` and `%log_stats`; migrating one without the other would be incoherent. The implementation ticket for this group should plan them as a single migration. **Grouping rationale**: shared code path (`ltl:5488`); shared output values (`%log_stats`); independent validation harness for percentile-value accuracy. Incidental Path C1 (histogram-mode global percentile *indicators*) may be folded in if the implementation ticket finds it natural; the bin counts themselves are Path C1-bins and are part of Phase 3's grouping.

- **Phase 3 — Per-time-bucket consumers (Path B + C2 + C2-cells + C1-bins grouped).** The per-time-bucket statistics row, the heatmap percentile markers, the heatmap cells, and the histogram view's bin counts all currently use the end-of-parse-from-retained-arrays pattern in or near `calculate_histogram_buckets` (`ltl:4908`). Migrating any of them requires changes to that area of code. **Grouping rationale**: shared accumulation code (`%heatmap_raw`, `histogram_values`, `log_analysis{durations}`); shared end-of-parse finalization step; display-time re-projection is a common new code surface. The implementation ticket for this group plans the auto-resize partition lifecycle for these consumers and the render-time re-projection logic together.

- **Phase 4 — Highlight-data consumers.** When #51 lands, the highlight-subset consumer adopts the unified contract. **Grouping rationale**: depends on #51's design; coordinated through #51's implementation ticket.

- **Phase 5 — Future consumers.** Any new percentile-or-histogram-related feature inherits the contract by construction. The grouping for future consumers is whatever their implementation ticket establishes; this entry exists to make the contract's perpetual applicability explicit.

**What the phase grouping does *not* prescribe**: shipping cadence, default-on-vs-default-off policy, release-roadmap timing, per-phase code-review standards, validation-harness specifics beyond what's specified in R11/R11a, communication to users, or any other release-engineering concern. Those decisions belong to the implementation tickets.

**What the phase grouping does *recommend*** to the implementation tickets:

- Migrate consumers within a phase together rather than splitting them across releases. Splitting C2 and C2-cells, for example, would leave the heatmap rendering code in an inconsistent partial-migration state.
- Validate within a phase before starting the next phase's implementation. Each phase's outputs (counter-store layout, render-time re-projection logic, etc.) inform the next phase's design choices.
- Reference this file's locked decisions as the contract; do not re-decide locked questions within an implementation ticket. If a locked decision proves wrong at implementation time, file a follow-up issue against #187 to record the revision rather than diverging silently.

### R10 — Per-consumer path-reporting codes

`-V` reports, per consumer, which computation path is running this run. The vocabulary:

- `unified` — the consumer has been migrated and is running the unified contract path.
- `pre_migration` — the consumer's R9 phase has not yet validated, so the pre-migration sort-based code is running. Used during the phased rollout described in R9.
- `user_opt_out` — the consumer was migrated but the user explicitly opted out via the practical decision 7 mechanism (e.g., `--exact-percentiles` flag).
- `feature_not_active` — no values were matched; no percentile computation occurred. The partition is not constructed.

The previous reason codes from the dissolved R2 gate (`no_index`, `tier_mismatch`, `input_criteria_failed`, `approximate_eligible`, `exact_default`) are removed. They corresponded to the runtime mode-selection gate that no longer exists.

Practical decision 7 may introduce a `--exact-percentiles` flag; if so, `user_opt_out` is its surface in `-V`. Practical decision 8 settles the exact label format for these codes.

### R11 — Baseline-regression byte-identity during phased migration

For each consumer migrating onto the unified contract (per R9 phases), the migration's acceptance includes byte-identical regression validation against the pre-migration output. The mechanism:

- The pre-migration code (sort-based, retained-arrays end-of-parse binning, etc.) is preserved per-consumer through that consumer's R9 phase.
- During the phase's validation, ltl runs with the pre-migration code path (the "exact reference") and the unified-contract code path, and compares output via the existing baseline-regression harness (`tests/baseline/`, per CLAUDE.md).
- The unified-contract output is not expected to be byte-identical to the pre-migration output for percentile values (the unified path computes interpolated values; the pre-migration path returns retained-array indices). Byte-identity applies to: (a) bin-count display values in heatmap and histogram features when running the pre-migration path; (b) percentile values when the user has opted out via practical decision 7. The validation criterion is "does the unified-contract output sit within the documented bin-resolution bound (R4) around the pre-migration output for every required quantile."
- After phase validation passes, the pre-migration code may be retired per-consumer or retained as a user-opt-out surface (per practical decision 7).

### R11a — Existing exact-mode behavior preserved as user opt-out

Where practical decision 7 introduces a user-facing `--exact-percentiles` (or equivalent) opt-out, opting out runs the pre-migration code path and produces byte-identical output to the pre-feature implementation. The existing regression suite must continue to pass byte-identically under the opt-out path.

### R12 — Consumer audit (every percentile and histogram consumer in ltl)

Phase 0 of R9 includes an audit of every consumer of percentile values or histogram bin counts in ltl, shipped or planned. The audit is the complete catalogue that the unified primitive contract must serve. No consumer is "primary"; the contract is designed to serve them all uniformly.

Consumers catalogued (full per-site catalogue in the *Consumer audit* section below):

- **Summary-table per-message latency percentiles** (Path A) — rendered in the summary table; shipped.
- **CSV output per-message statistics** (Path A') — written via `-o`; shares `calculate_statistics` with the summary table; shipped.
- **Per-time-bucket duration percentile statistics** (Path B) — rendered inline on the heatmap bar row; shipped.
- **Heatmap percentile markers** (Path C2) — P50/P95/P99/P99.9 column-position markers on each heatmap row; shipped.
- **Heatmap cells** (Path C2-cells) — the color-coded cells themselves; today computed from `%heatmap_raw` at end-of-parse; shipped.
- **Histogram-mode global percentiles** (Path C1) — rendered in the histogram legend and on x-axis ticks; shipped.
- **Histogram-mode bin counts** (Path C1-bins) — the bar heights themselves; today computed from `histogram_values{$metric}` at end-of-parse; shipped.
- **Highlight-data percentiles** (Phase 4) — planned, coordinates with #51.
- **Per-API hover-to-redraw renders** (planned future) — re-projection of per-key partition counts onto the heatmap/histogram global display boundaries at render time, on demand. Decision 5 records the first-cut scope (histogram-only, heatmap deferred).
- **Any future percentile or histogram consumer** — inherits the contract by construction.

For each consumer, the audit records:

- Today's data structure (array shape, key dimensions) if shipped, or planned shape if not.
- Today's computation method (sort-and-index, end-of-parse binning, etc.) if shipped.
- The migration target (which R9 phase carries the consumer onto the contract; what shape the consumer needs from #189's primitives).
- Compatibility constraints — what must not change in #189's primitive design to support this consumer.

The audit lives in this feature file (*Consumer audit* section below) and feeds the consumer-side requirements in `features/189-histogram-bin-counter-primitives.md`.

The audit is a required Phase 0 output. Without it, the unified contract risks being designed for a subset of consumers and reworked when later ones land.

### R13 — Heatmap and histogram migrations are in scope and staged through R9

The unified primitive contract applies to every consumer including the heatmap (`-hm`) and histogram (`-hg`) features. The shipped end-of-parse-from-retained-arrays pattern in `calculate_histogram_buckets` (`ltl:4908`) and `%heatmap_raw` accumulation does *not* match Decision 5's locked auto-resize lifecycle, and is therefore on the migration path — not exempt from it.

Migration of these shipped features is staged through R9's phase mechanism:

- **R9 Phase 3** — per-time-bucket consumers (Path B in R12 + heatmap cells + heatmap percentile markers + per-time-bucket statistics row). The per-time-bucket partitions migrate to per-bucket auto-resize during the parse; the heatmap display geometry (W columns from `-hmw`) is preserved by re-projecting per-bucket counts onto the display column grid at render time.
- **R9 Phase 2 or 3 (timing decided per implementation risk)** — the histogram view (`-hg`) global partition migrates from end-of-parse retained-arrays to a single auto-resize partition built during the parse; display column boundaries are derived from the partition's final `[min, max]` at render time.

Phase boundaries serve as consumer-grouping guidance for the implementation tickets (see R9): consumers within a phase share enough code structure that migrating them together is recommended. The validation harness, ship cadence, and release-process integration for each phase's migration are the implementation ticket's concerns. The contract guarantees that byte-identical pre-feature output is available via Decision 7's opt-out (R11a), and that the unified-path output falls within the bin-resolution bound (R4) around the pre-migration output — those are the contract surfaces the implementation tickets validate against.

Display geometry is unchanged by the migration. Internal precision improves. Percentile markers and cell colors become more accurate; the visual surface stays the same.

### R13a — Exact-mode fallback during migration

Each shipped-consumer migration retains an exact-mode fallback through its validation phase. Exact mode runs the pre-migration implementation (retained arrays, sort-and-index or end-of-parse-binning as appropriate) and produces byte-identical output to the pre-feature implementation per R11. The fallback exists to support phase-by-phase regression validation; after each consumer's phase validates clean against the baseline harness, the consumer-specific exact-mode fallback may be retired if no remaining reason to keep it exists.

A run may therefore have approximate mode active for some consumers and exact mode active for others, depending on which phase-gates have validated. R7's `-V` output makes this per-consumer state explicit.

### R14 — Boundaries with related features

This feature owns the **unified primitive contract** (the locked decisions in *Locked decisions from research*) and the **rollout plan** (R9) for migrating ltl's consumers onto it.

This feature does NOT own:

- **The primitive implementation** (helper functions, data-structure code) — owned by #189. #189 implements R1 (auto-resize partition per Decision 5), R2 (assignment), R3 (counter update keyed per consumer), R4 (Decision 1's locked formula), R5/R6 (Decision 4's overflow/underflow counters). #189's implementation must match the contract locked here.
- **Per-consumer migrations** — each consumer (summary table, CSV output, heatmap, histogram view, per-time-bucket statistics, highlight subsets, future hover-to-redraw) is migrated by its owning issue against the contract. #34 owns the heatmap/histogram migrations (R9 Phase 3). #51 owns the highlight-data migration (R9 Phase 4). New consumers introduced after the unified contract lands inherit the contract by construction.
- **Index read-back, drift refresh** — owned by #179. The role of #179 has been substantially reshaped by Decision 5 (the index is no longer load-bearing for partition sizing); see *Downstream implications for related issues* for the catalogue of what survives in #179's scope.
- **Within-run pre-pass / sampling-based bound discovery** — not needed under Decision 5's auto-resize lifecycle.

The contract is authoritative; the per-issue implementations conform to it. When an implementation question surfaces about how a consumer's migration interacts with the contract, the question is answered by reading the locked decisions in this file. When a question surfaces about how to *implement* the contract in #189's primitives, it's filed against #189. When a question surfaces about how a *specific consumer* uses the contract, it's filed against that consumer's owning issue.

## Consumer audit

The audit is part of Phase 0's deliverables (R12). It identifies every consumer of percentile values or histogram bin counts in `ltl` (shipped or planned), the migration target for each, and the compatibility constraints each places on #189's primitive design.

**Status: catalogued; phase mapping per R9.** The audit was performed jointly with #34 R12 against `release/0.14.5` HEAD. The full per-site catalogue (line-precise, with primitive mappings and data-structure references) lives in `features/189-histogram-bin-counter-primitives.md` § *Audit findings*. This section summarizes the consumer entries and their migration targets.

### Path A — Summary-table per-message latency percentiles (R9 Phase 2 target)

- **Today's data structure**: `log_messages{$category}{$log_key}{durations}` — a per-message duration array, pushed during the parse loop at `ltl:4591`.
- **Today's computation**: `calculate_all_statistics` (`ltl:5178`) aggregates per `log_key`, delegating to `calculate_statistics` (`ltl:5488`) which sorts and indexes by integer rank (`int($n * fraction)`).
- **Percentiles emitted**: P1, P50, P75, P90, P95, P99, P99.9 (`ltl:5374–5379`); rendered in the summary table at `ltl:7900–7916`.
- **Migration target (Phase 2)**: replace the raw `durations` array with a histogram bin-counter store keyed by `(category, log_key)` per #189 R3. Replace the sort-and-index core of `calculate_statistics` with #189 R4 invocations against the per-message counter store. R4's in-bin interpolation strategy and `buckets_per_decade` default for this path are decided by D3.
- **Compatibility constraints on #189**:
  - R3 must accept `key = (category, log_key)` (or `key = ()` per active aggregator if the aggregation happens before counter update — implementer's choice).
  - R4 must support the seven percentiles listed above with an accuracy contract sufficient for SRE latency reporting; specifics in D3.
  - R4 must handle the "single-message" degenerate case gracefully (very small count per `log_key` is common for one-off log messages).
- **#34 R15 verified**: this raw array is structurally separate from `%heatmap_raw` and `%histogram_values` (distinct keys, distinct lifetimes, distinct allocation sites). The #34 implementation does not entangle with this consumer.

### Path A' — CSV output per-message statistics (R9 Phase 2 target — shares migration with Path A)

- **Today's data structure**: same `log_messages{$category}{$log_key}{durations}` arrays as Path A; same `calculate_statistics` (`ltl:5488`) percentile derivation.
- **Today's computation**: identical to Path A. The CSV writer (invoked via `-o`) consumes the same `%log_stats` percentile values that the summary table renders. Sort-and-index on the raw arrays produces both outputs.
- **Percentiles emitted**: same set as Path A (P1, P50, P75, P90, P95, P99, P99.9).
- **Migration target (R9 Phase 2)**: Path A' migrates *jointly* with Path A — both consume `%log_stats`, so a partial migration is incoherent. The unified contract applies to the percentile-value derivation; CSV rendering of those values is unchanged downstream.
- **Compatibility constraints on #189**: none beyond Path A's. The CSV writer is a downstream consumer of the same percentile values.
- **Phase 2 acceptance includes CSV output validation**: regression testing must compare CSV output before and after Phase 2 in exact mode for byte-identity per R11.

### Path B — Per-time-bucket duration percentile statistics (R9 Phase 3 target)

- **Today's data structure**: `log_analysis{$bucket}{durations}` — a per-time-bucket duration array, pushed during the parse loop at `ltl:4634` **gated by `unless $heatmap_enabled`**. Freed inside `calculate_all_statistics` at `ltl:5213–5214` after aggregation.
- **Today's computation**: same `calculate_statistics` engine (`ltl:5488`) as Path A, applied per time bucket. Outputs `log_stats{$bucket}{p1..p999}` at `ltl:5220, 5236–5242, 5273`.
- **Percentiles emitted**: P1, P50, P75, P90, P95, P99, P99.9; rendered inline on the time-bucket bar row at `ltl:6843–6846`.
- **Migration target (Phase 3)**: read #34's heatmap bin-counter store (keyed by `time_bucket`) directly via #189 R4 — no separate counter store needed when heatmap is active. When heatmap is **not** active, Phase 3 must populate its own per-`time_bucket` counter store (R3 with `key = time_bucket`) since no parallel structure exists.
- **Compatibility constraints on #189**:
  - R6 (independence of partitions across consumers) must allow Phase 3 to share the heatmap partition when bucket counts agree, or to compute its own partition when they differ.
  - R4 must produce acceptable accuracy at small per-bucket N (many log files have time buckets with <100 entries); D3 must evaluate this regime explicitly.
  - R3's per-key lifecycle (#189 R8) must support per-time-bucket counter freeing — Phase 3 can free a bucket's counter store once its row is rendered.
- **Pre-existing entanglement noted**: the `unless $heatmap_enabled` gate at `ltl:4634` is a load-bearing condition today (heatmap takes ownership of duration values when active). Under bin-counter mode this gate becomes natural rather than incidental — the heatmap counter store **is** the natural source. The gate may be removable when Phase 3 lands. This is recorded for resolution at Phase 3 implementation time, not at audit.

### Path C — Other percentile-reporting code paths

Two additional paths were catalogued during the audit:

#### C1 — Histogram-mode global percentiles (incidental Phase 2 consumer)

- **Today's data structure**: `histogram_stats{$metric}{p1..p9999}` — computed inside `calculate_histogram_buckets` at `ltl:4926–4940` (base) and `ltl:4995–5004` (highlight) from sorted `histogram_values{$metric}` arrays in the same routine that builds the bin counters.
- **Today's computation**: sort-and-index, identical pattern to Paths A/B but interleaved with R1+R2+R3 in raw-value mode.
- **Percentiles emitted**: P1, P10, P25, P50, P75, P90, P95, P99, P99.9, P99.99 (ten values — wider set than Paths A/B). Rendered in the histogram legend via `select_histogram_percentiles` (`ltl:7375`) and `calculate_histogram_percentile_ticks` (`ltl:7430`).
- **Migration target**: incidental Phase 2. When R4 lands, these can be derived from the bin counters #34 already populates — eliminating the raw-array sort at this site.
- **Compatibility constraints on #189**: R4 must support all ten percentile values; otherwise the rendered legend regresses. The legend consumer (`select_histogram_percentiles`) needs no API change — it reads `histogram_stats{$metric}{p*}` regardless of how those values were derived.
- **Coupling to #34**: because the raw-array sort and the bin-counter population happen in the same routine, #34's bin-counter mode and #187's Path C migration are best landed together (or #34 must keep the sort in bin-counter mode purely for `histogram_stats{p*}`, which defeats the memory win). The audit recommends Phase 2 absorb C1 as a side benefit.

#### C2 — Heatmap percentile markers (R9 Phase 3 target; R4 consumer)

- **Today's data structure**: `%heatmap_percentiles{$bucket} = { p50, p95, p99, p999 }` — stored as **bin indices, not values**. Derived at `ltl:4823–4834` by sorting `%heatmap_raw{$bucket}`, indexing P50/P95/P99/P99.9, then mapping each value to a bin via `find_heatmap_bucket`.
- **Today's computation**: sort-and-index, then bin lookup. Output is a column position on the heatmap row, not a numeric percentile value.
- **Migration target (R9 Phase 3) — superseded 2026-05-20 via #201**: streaming auto-resize partition during parse → end-of-parse finalize re-bin into display-bound partition (`bin_count = $heatmap_width`, boundaries from `[d_min, d_max]`). R4 invoked against the finalized partition. Render reads finalized partition directly — no render-time re-projection. See `features/201-display-geometry-bound-consumers.md` § Recommendation.
- **Symmetric resolution for the histogram consumer — superseded 2026-05-20 via #201**: same two-stage stream → finalize-rebin pattern, with `bin_count = $bar_area_width` at finalize (knowable after active-metric count `n` is determined). Numeric percentile value derived from the finalized partition via R4.

#### C2-cells — Heatmap cells themselves (R9 Phase 3 target; cell colors)

- **Today's data structure**: `%heatmap_raw{$bucket}` — per-time-bucket raw value array, accumulated during the parse. End-of-parse `calculate_histogram_buckets`-area logic computes global `[min, max]`, derives the W-column display boundaries, then bins each per-bucket value to color the cells.
- **Today's computation**: full retention of per-bucket raw values for the duration of the parse; end-of-parse global partition derivation and per-cell counting.
- **Migration target (R9 Phase 3) — superseded 2026-05-20 via #201**: streaming auto-resize partition per `time_bucket` during the parse (using the unmodified F1 #189 primitives). At end-of-parse, each per-`time_bucket` partition is **re-binned via geometric-midpoint projection** into a display-bound partition with `bin_count = $heatmap_width` and boundaries log-spaced over the global `[d_min, d_max]`. The heatmap reads finalized partitions directly per row — no render-time re-projection. See `features/201-display-geometry-bound-consumers.md` § Recommendation for the locked F2 contract and `prototype/201-projection-comparison-report.md` for empirical validation.
- **Compatibility constraints on #189**: R1 unchanged; R3 supports per-`time_bucket` keying (already in the contract); R4 unchanged. The finalize re-bin step is a new caller-side composition that reuses `partition_extend`'s remap loop at `ltl:613-622` — see `features/189-histogram-bin-counter-primitives.md` for the optional `partition_rebin` wrapper.
- **Display geometry unchanged**: W columns, color scheme, layout all preserved. Internal precision improves because Decision 2's locked default (53 bpd) is higher than today's shipped 8 bpd default for the heatmap partition.

#### C1 (revised) — Histogram-mode global percentiles (R9 Phase 2 or 3 target)

(Original C1 entry above retained; this entry expands its scope to include both the percentile indicators AND the histogram bin counts themselves, since they share the same end-of-parse-from-retained-arrays pattern.)

#### C1-bins — Histogram-mode bin counts themselves (R9 Phase 2 or 3 target; bar heights)

- **Today's data structure**: `histogram_values{$metric}` — global per-metric raw value array, accumulated during the parse. End-of-parse `calculate_histogram_buckets` (`ltl:4908`) computes global `[min, max]`, derives boundaries, bins each value, frees the array.
- **Today's computation**: sort-and-index for percentile derivation interleaved with bin counting. Memory cost is full retention of all observed values for the duration of the parse.
- **Migration target (R9 Phase 2 or 3, timing decided per implementation risk) — superseded 2026-05-20 via #201**: streaming auto-resize partition per metric (using the unmodified F1 #189 primitives). At end-of-parse, after `n` (active-metric count) and `$bar_area_width` are known, the streaming partition is **re-binned via geometric-midpoint projection** into a display-bound partition with `bin_count = $bar_area_width` and boundaries log-spaced over `[d_min, d_max]`. Histogram bar rendering reads finalized partition directly. Note: shipped F3 today renders "wide bars" by duplicating partition counts across display columns — preservation of that convention is a UX decision deferred to the histogram migration ticket. See `features/201-display-geometry-bound-consumers.md` § Open question.
- **Compatibility constraints on #189**: R1 must support a single global auto-resize partition with per-metric keying; R3 supports `key = ()` per metric; R4 unchanged. Display geometry handled by the consumer.
- **Display geometry unchanged**: column count, layout, percentile-tick rendering all preserved. Internal precision improves because Decision 2's locked default (53 bpd) is higher than today's shipped 8 bpd histogram default.

### Currently no bin-derived percentile interpolation in `ltl`

A finding worth recording: **none** of the four percentile paths today (A, B, C1, C2) uses bin-derived interpolation. All four use sort-and-index over raw arrays. This means #189 R4 is a **new abstraction**, not a refactor of an existing helper. The algorithm choice (D3) and the accuracy contract (R4 in this feature) are inputs to a primitive that has no precedent in the codebase.

### Forward-compatibility statement (consumer-side requirements for #189)

For Phases 2–5 to consume the unified primitives without primitive-level redesign:

- **R1 (partition)** accepts arbitrary `num_buckets` per consumer. Bucket-count sources today vary across consumers: CLI-fixed (heatmap, `-hmw`), data-driven (histogram, `calculate_histogram_bucket_count`), Phase-2-implementer-chosen (per-message percentile partition shape, decided by D3). R1 must support all.
- **R3 (counter keying)** is parameterizable across all distinct shapes catalogued: `()` (Path A in some implementer choices, Path C1), `(category, log_key)` (Path A in other implementer choices), `time_bucket` (Path B, heatmap), `(time_bucket, highlight_subset)` (Path C in future / #51), and any compound key Phase 4 or Phase 5 introduces.
- **R4 (percentile interpolation)** accepts a target quantile and a counter map, returns the interpolated value, exposes its accuracy guarantee in a form that #187 R4 / R7 can report. Must handle:
  - Wide percentile sets: at minimum the ten-value set from Path C1 (P1, P10, P25, P50, P75, P90, P95, P99, P99.9, P99.99).
  - Small-N degenerate inputs: Path B at narrow time buckets, Path A at single-occurrence log keys, Path C2 at sparse heatmap rows.
  - Reporting alongside #34 R5 / R6 out-of-range tallies — overflow counts must be accessible to the interpolation primitive (or the consumer adjusts the partition to fold overflow into edge bins; R4 must specify which).
- **Accuracy guarantee per quantile is parameterizable by partition shape.** Per-time-bucket and global partitions have different N regimes; D3 must produce a bound that applies to both.
- **Memory lifecycle**: counter structures freeable per key independently of the partition. R4 carries no state of its own — it derives from the counter map at invocation time.

This list is the consumer-side input to #189's primitive design.

### Cross-reference

- Full per-site `ltl:line` catalogue with primitive mappings: `features/189-histogram-bin-counter-primitives.md` § Audit findings.
- Per-feature consumer-side requirements (combined #34 + #187): `features/189-histogram-bin-counter-primitives.md` § Consumer-side requirements.
- Cross-cutting constraints discovered during audit: `features/189-histogram-bin-counter-primitives.md` § Cross-cutting compatibility constraints discovered during audit.
- Boundary with #34's heatmap and histogram consumers: `features/34-histogram-bin-counter-mode.md` § Harmonization audit (this feature ships the percentile-interpolation algorithm and progressive consumer migration; #34 ships the heatmap/histogram bin-counter substrate the percentile work consumes).

## Considerations for implementation

The algorithm substrate is fixed (HdrHistogram-style log-spaced bin counters, per Motivation). The items below are the remaining mechanism questions that the research deliverables (and the grounding pass in `features/187-histogram-industry-grounding.md`) address.

- **R4 percentile-derivation formula.** Given a partition and a counter map for one key, what does `(target_quantile) → value` compute? This decomposes into a cumulative-count walk (mechanical) plus a per-bin return value (open; see D3 § Decision 1 for source-grounded options).
- **`buckets_per_decade` for the per-message path.** Open; see D3 § Decision 2. The consulted libraries express precision in their own native units; default values across worked examples span ~53 (OTEP 149 Scale 4) to ~616 (HdrHistogram README 3-significant-digit example). ltl's existing histogram default is 8.
- **Tail-bin behavior.** Bin-counter accuracy is bounded by partition geometry *uniformly* across quantiles. The separate question — rank under-support at the tail — is a property of any percentile estimator; the consulted libraries do not document a per-bin sample-count fall-through (D3 § Decision 3 records this gap).
- **Accuracy-reporting unit.** Value-relative error. DDSketch publishes this contract as α; OTEL and HdrHistogram express the same property in their native parameter units. The conversion arithmetic is in `features/187-histogram-industry-grounding.md` § Decision 2.
- **Memory behavior across modes.** The approximate-mode bin-counter store replaces the exact-mode value array. Mixed-mode behavior is well-defined per R13; lifecycle composes with #23 Phase 2's named-stage memory model.
- **Highlight subsets.** Phase 4 coordination with #51.
- **State lifecycle and reset.** Counter store freed when no longer needed; lifecycle composes with #23 Phase 2.

## Edge cases

| Case | Required behavior |
|---|---|
| No matched messages | Percentiles emit `-`; no partition is constructed; `-V` reports `feature_not_active` per R10. |
| All matched values are identical | Partition has a single populated bin; every percentile equals that value (Decision 1's formula returns that value uniformly when all observations land in one bin). |
| Single matched value | Same as above — single observation, single bin, every percentile equals that value. |
| Very small N | Decision 1's formula computes for any positive `bin_count`; no per-bin guard (Decision 3); no rank-support warning (Decision 3). Output is well-defined for any N ≥ 1. |
| Per-key partition rebins mid-parse | Expected behavior per Decision 5's auto-resize lifecycle. Each rebin is recorded in the Decision 5 `-V` telemetry counters (`total_rebin_events`, `rebins_per_key {p50, p95, p99, max}`). |
| Per-key value falls outside partition's current [min, max] | Triggers a rebin (Decision 5 doubling). If the value falls outside the rebinned partition for any reason (e.g., extreme outlier past the doubled extent), it is counted in the overflow or underflow counter per Decision 4. The per-quantile `out_of_range_bounded: high\|low` audit field reflects this on subsequent percentile queries. |
| Filtered run | The unified contract runs unconditionally. The filter context is reported in `-V` for analyst audit per R7. Filter-context audit is not a gate. |
| User opts out via `--exact-percentiles` (if practical decision 7 ships this) | The consumer's pre-migration code path runs; output is byte-identical to the pre-feature implementation per R11a. `-V` reports `user_opt_out` per R10. |
| Consumer not yet migrated (during the phased rollout) | The consumer runs its pre-migration code path; `-V` reports `pre_migration` per R10. |
| Highlight pattern present (pre-Phase 4) | Highlight-subset percentiles use the pre-migration code path until #51 lands; `-V` reports `pre_migration` for the highlight consumer. Migration covered by R9 Phase 4. |
| Concurrent ltl processes | Inherited from #179; out of this feature's concern. |

## Acceptance criteria

### Phase 0 — Foundation (this file)

- [ ] R1–R14 align with the locked decisions in *Locked decisions from research*.
- [ ] Consumer audit (R12) lists every percentile-and-histogram consumer in ltl, shipped or planned.
- [ ] Unified primitive contract is locked: F1, Decisions 1, 1A, 2, 3, 4, 5. Decision 6 dissolved with explicit rationale.
- [ ] Downstream implications for related issues (#34, #179, #189, #41, #51, #23) catalogued.
- [ ] Consumer-side primitive requirements landed in `features/189-histogram-bin-counter-primitives.md` for #189's implementation.

### Phase 1 — Research (this file)

- [ ] D1 grounded against industry sources in `features/187-histogram-industry-grounding.md`.
- [ ] D2 cross-references the existing D2 dataset inventory.
- [ ] D3 decisions all closed (locked, dissolved, or marked as practical-decision territory).
- [ ] Practical decisions 7, 8, 9, 10 closed before any consumer migration begins.

### Contract surfaces that per-consumer migration tickets satisfy

These are not acceptance criteria for #187; #187 defines them as contract surfaces that any consumer migration must satisfy. The implementation tickets that own each consumer's migration have their own acceptance criteria built around these surfaces.

- The consumer's pre-migration code path is preserved by the implementation ticket through the migration for regression-validation purposes (R11).
- The unified-contract code path is implemented per the locked decisions (F1, Decisions 1, 1A, 2, 3, 4, 5).
- The unified-contract output for each required percentile (per R3 per consumer) falls within the bin-resolution bound (R4) around the pre-migration output across the D2 dataset set.
- `-V` emits the contract surface defined in R7 and Decision 8: per-consumer path (R10), per-partition state, per-quantile `out_of_range_bounded`, rebin telemetry per Decision 5.
- User opt-out (R11a) under `--exact-percentiles` preserves byte-identical pre-feature output for the consumer.

### Cross-consumer

- Each implementation ticket references this feature file as the authoritative source of the unified contract.
- Any contract change discovered during a consumer's migration (e.g., revisiting Decision 5's seeding heuristic from real `-V` telemetry per the locked telemetry contract) is filed as a follow-up issue against #187 and recorded as a new locked-decision entry, not silently applied within the implementation ticket.

## Validation

This section defines the **contract-surface validation scenarios** that any consumer migration must exercise. The implementation tickets that own each consumer's migration design their own per-consumer validation harnesses around these scenarios; #187 specifies *what* must be testable, not *how* the harness is structured per ticket.

### Existing baseline regression (contract surface)

`tests/baseline/` is ltl's existing baseline-regression harness. Consumer migration tickets integrate their own validation against this harness per CLAUDE.md's release process. Validates R11 / R11a for that consumer.

### Contract-level scenario suite

Run ltl with `-V`, assert against the `=== BIN-COUNTER MODE ===` section. These scenarios validate the unified contract surface (R7, R10) independently of any specific consumer's migration progress.

| Scenario | Setup | Action | Assertions |
|---|---|---|---|
| `unified-default` | Consumer has migrated to unified contract; no CLI override. | `ltl <F> -V`. | Per-consumer line reports `unified`. Per-partition fields populated: `buckets_per_decade: 53` (default), `bin_count`, `state_budget_bytes`. Per-quantile `out_of_range_bounded` present. Rebin telemetry per Decision 5 present. |
| `unified-pbpd-override` | Consumer migrated; user runs `ltl -pbpd 32 <F> -V`. | `ltl -pbpd 32 <F> -V`. | `buckets_per_decade: 32 (-pbpd 32)` reported. |
| `unified-precision-tier` | Consumer migrated; user runs `--percentile-precision 7`. | `ltl --percentile-precision 7 <F> -V`. | `buckets_per_decade: 115 (--percentile-precision 7)` reported. |
| `unified-flag-conflict` | Consumer migrated; both flags specified. | `ltl --percentile-precision 4 -pbpd 100 <F> -V`. | `-pbpd` wins per Decision 2 lock. `buckets_per_decade: 100 (-pbpd 100; --percentile-precision 4 overridden)`. |
| `pre-migration-consumer` | Run on a consumer whose phase has not yet validated. | `ltl <F> -V`. | Per-consumer line reports `pre_migration`. R11 byte-identity holds against pre-feature output for that consumer. |
| `user-opt-out` (if practical decision 7 ships this) | Consumer migrated; user runs with opt-out flag. | `ltl --exact-percentiles <F> -V`. | Per-consumer line reports `user_opt_out`. R11a byte-identity holds. |
| `zero-values` | No values matched. | `ltl -i nonexistent <F> -V`. | Percentiles emit `-`; `reason: feature_not_active`. No partition constructed. No crash. |
| `all-same` | All matched values identical. | Crafted log file. | All percentiles equal that value. |
| `single-value` | Single matched value. | Crafted log file. | All percentiles equal that value. |
| `out-of-range-bounded` | Crafted log file where some percentile target ranks land in overflow or underflow. | `ltl <F> -V`. | Affected quantiles report `out_of_range_bounded: high` or `low`; R4 returned boundary value (not interpolated). |
| `accuracy-within-bin-resolution` | Representative D2 dataset; consumer migrated. | Run twice — once with pre-migration code (forced via opt-out flag if available, else via build-time fallback), once unified. | Per-quantile errors fall within the bin-resolution bound (R4) for the active `buckets_per_decade`. |
| `state-budget-reported` | Migrated consumer; any run. | `ltl <F> -V`. | `state_budget_bytes` matches actual counter-store memory; rebin telemetry totals match observed rebin events. |

### Accuracy-comparison test harness

A dedicated harness compares unified-contract output against pre-migration output across the D2 dataset set. For each dataset:

1. Run ltl twice (once with the pre-migration code path via the appropriate opt-out, once with the unified contract).
2. Compute per-quantile absolute and relative error.
3. Assert each error within the bin-resolution bound (R4) for the active `buckets_per_decade`.

The harness is part of this feature's deliverable. Per R9, each migration phase invokes this harness on the consumer migrated by that phase, with appropriate consumer-specific assertions.

## Research deliverables

Production implementation does not commence until the following deliverables are complete and recorded. The deliverables are requirements on the *work*, not prescriptions of the *mechanism*.

### Research conduct — mandatory before resuming this work

This was scoped as a research-heavy task. A prior pass through D1/D3 reasoned from first principles and produced invented options for the decision conversation rather than anchoring on established industry practice. That work is not trustworthy and the decisions captured in **Locked decisions from research** must be treated as *provisional* until re-grounded against the literature catalogued below. When this task is resumed, the following protocol is mandatory and non-negotiable.

#### Required sources for grounding

For every decision currently in D3 and every new decision surfaced, the work must consult — at minimum — the following industry-standard references. None of these may be skipped on the basis of "I can reason this out" or "the answer is obvious."

| Source | Why it matters |
|---|---|
| **HdrHistogram** — Gil Tene's reference implementation, FAQ, and accompanying papers. The Java/C source defines `lowestEquivalentValue`, `highestEquivalentValue`, `medianEquivalentValue`, `valueAtPercentile`, and `getValueAtPercentile` with documented conventions. | The substrate ltl already names "HdrHistogram approach" in its code comments. Decisions about in-bin reporting, sub-bucket precision, value-equivalence semantics, and percentile-recovery rules are settled practice here. |
| **Prometheus client library + `histogram_quantile()` (PromQL)** — the documented linear-interpolation rule, `+Inf` bucket handling, and the rules for what `histogram_quantile()` returns when a quantile lands in or above the `+Inf` bucket. The Prometheus documentation explicitly addresses the case the user raised. | The `+Inf` semantics — count contributes to denominator, no value reportable when target rank lands above the last deterministic bin — is the canonical answer to Decision 4 and is shaped by years of operational practice. |
| **OpenTelemetry exponential histogram specification** — `Scale`, `ZeroCount`, positive/negative buckets, exemplars, collapse and merge semantics. | The modern (2022+) standardization of log-spaced bin counters; published with rationale for every design choice including precision parameter selection and overflow handling. |
| **DDSketch** — Masson, Rim, Lee (VLDB 2019). The paper proves a value-relative-error guarantee for a log-spaced partition with rate `1+α` and documents the partition's mathematical relationship to `buckets_per_decade`. | The accuracy contract this feature commits to in R4 should be grounded in DDSketch's published bound — α relative error in value space — which transfers directly to the substrate ltl uses. |
| **OpenMetrics specification** — the formal metric exposition standard that subsumes Prometheus histograms, including the explicit rules for cumulative-count semantics and the `+Inf` bucket. | The canonical statement of histogram-metric conventions. |
| **Gil Tene's writings on coordinated omission, percentile starvation, and "we are not who we measure"** — published talks and the HdrHistogram FAQ on when P99.9 and P99.99 are meaningful vs. manufactured. | The "sample-count starvation" framing in D1 must be grounded in Tene's published guidance, not invented locally. |
| **Apache DataSketches** (KLL, REQ, theta-sketch documentation) — only where genuinely relevant to comparative substrate analysis. | KLL is *not* the substrate ltl ships, but DataSketches' documentation of in-bin reporting and rank-error vs. value-error semantics is a useful reference for how the substrate's accuracy contract should be exposed. |

#### Conduct rules

1. **No first-principles reasoning before consulting the sources.** If a decision concerns "how does R4 turn a target rank into a returned value," the work first reads HdrHistogram's `valueAtPercentile` and Prometheus's `histogram_quantile()` source and documentation. The decision options presented are then derived from what those references do, with citations.

2. **Each decision option presented must cite at least one industry source.** "(d) Linear-in-log within the bin" is not an acceptable option entry. "(d) Linear-in-log within the bin, as Prometheus `histogram_quantile()` documents and implements (citation: <Prometheus docs URL or source file>)" is acceptable.

3. **Where ltl's case genuinely differs from the industry-standard case, the divergence is documented explicitly.** The default position is "do what HdrHistogram / Prometheus / OTel do unless there is a stated reason ltl cannot."

4. **The decision conversation does not present invented options.** If a candidate answer to a decision cannot be sourced from at least one of the references above, it is not presented. The user is not asked to choose between "what HdrHistogram does" and "an option Claude made up."

5. **Each locked decision records its grounding.** The **Locked decisions from research** section records, for each decision, the industry-standard reference(s) the decision is grounded in. A decision that cannot record this is not locked.

#### Resumption protocol

When this task is picked up next:

1. Spawn a research agent (or take equivalent time) to read the references above and produce a grounding document covering at least the six analytical decisions in D3 (in-bin interpolation, `buckets_per_decade` default, fall-through threshold, out-of-range handling, partition lifecycle, gating thresholds) plus the practical decisions (7-10).
2. The grounding document records, per decision, what the industry-standard practice is, with citations.
3. The current locked decisions in **Locked decisions from research** are re-evaluated against that document. A decision that aligns with industry practice is re-locked with citation. A decision that diverges is re-opened, with the divergence justified or the decision reversed.
4. Only after step 3 does the decision conversation continue (for any decisions that remain genuinely open after grounding).

The user has explicitly stated they should not be presented with invented options. The conduct rules above exist to prevent that.

### D1 — Extension study (literature-grounded)

D1 characterizes the **HdrHistogram-style log-spaced bin-counter substrate** (the substrate already shipped in `-hm` and `-hg`) against the four percentile-computing use cases catalogued in R12, identifies what the existing implementations already answer, and isolates the questions that extending the substrate to those use cases leaves open. It is literature-grounded; measurement is conditional on D4 (see below).

D1 does **not** open a multi-algorithm comparison. The substrate choice is settled by prior art in this codebase:

- `ltl:285-287, 4867-4905, 4956-4975` — log-spaced bin geometry, `buckets_per_decade` precision knob (default 8 → ~5% bin width), binary-search bin-find.
- `features/heatmap.md` and `features/histogram-charts.md` — design decisions, color/render integration, and the `-hgbpd` CLI knob.
- `features/34-histogram-bin-counter-mode.md` R4-bis — heatmap markers and histogram indicators both derive from `#189` R4 under bin-counter mode.
- `features/189-histogram-bin-counter-primitives.md` R1–R4 — partition, assignment, counter-update, and percentile-interpolation primitives.

The study presents the substrate's known properties for each use case and lists the open questions that the decision conversation must close before Phase 2 implementation. The decision is made by the user against D3's synthesis.

**The study covers:**

- The substrate's properties as already shipped (bin geometry, precision knob, bin-find).
- How those properties map to each of Paths A, B, C1, C2 (the existing implementations already cover C1 and C2 with raw-array sort for percentile derivation; A and B are the migration targets).
- What changes when raw values are *not* retained (the per-message migration target): how percentiles are derived directly from bin counters via #189 R4.
- The accuracy story decomposed into two sources: bin-resolution error (industry-documented; α / Scale / significant-digits contracts in DDSketch / OTEL / HdrHistogram) and rank under-support at the tail (a property of every percentile estimator including the current sorted-array code; the community attribution of this framing to Gil Tene was not verifiable in primary sources reached this pass).
- Open questions for D3 that the existing features do not answer.

#### D1 study — use-case demand profile

Drawn from the R12 audit (above). The demands a percentile primitive must satisfy across the four paths:

| Demand | Path A (summary-table per-message) | Path B (per-time-bucket) | Path C1 (histogram-mode global) | Path C2 (heatmap markers) |
|---|---|---|---|---|
| Percentile set | 7-value: P1, P50, P75, P90, P95, P99, P99.9 | 7-value: P1, P50, P75, P90, P95, P99, P99.9 | **10-value**: P1, P10, P25, P50, P75, P90, P95, P99, P99.9, **P99.99** | 4-marker: P50, P95, P99, P99.9 |
| Output form | Numeric value (rendered as duration) | Numeric value (rendered inline on bar row) | Numeric value (legend + x-axis ticks) | **Bin index** (column position on heatmap row) |
| Partition shape | Per-`(category, log_key)` — many independent partitions, one per distinct log key | Per-`time_bucket` — one partition per visible row | Single global partition per metric | Per-`time_bucket` — one partition per heatmap row (same partition as #34's bin counters) |
| N regime | Highly variable: many keys with N=1–10; some keys with N=10⁴–10⁶ on heavy-traffic endpoints | Variable: typically 10²–10⁴ per bucket at default bucket size; can drop to <10 at narrow `-b` or low-traffic windows | Single large N: typically 10⁵–10⁷ for the full dataset | Same as Path B (per-time-bucket) |
| Update pattern | Streaming during parse loop; finalize per-key after parse | Streaming during parse loop; finalize per-bucket after parse | Streaming during parse loop; finalize once | Streaming during parse loop; finalize per-bucket after parse |
| Tail-quantile importance | High (P99.9 is operationally critical for SRE latency) | High (P99 / P99.9 markers shown alongside time-bucket bar) | Very high (P99.99 included — extreme tail) | High (P99.9 marker shown on every heatmap row) |
| Memory pressure sensitivity | **Highest** — many keys × value array is the dominant summary-path memory consumer on multi-GB runs | Moderate — bucket count ~hundreds; per-bucket array can be large | Moderate — single partition but full-dataset N | Already addressed by #34's bin counters; percentile derivation must not reintroduce raw arrays |
| Determinism requirement | Byte-identical across runs (R6) | Byte-identical across runs (R6) | Byte-identical across runs (R6) | Bin-index stability across runs (R6, plus R11 byte-identical when exact mode runs) |

**Cross-cutting demands** (not path-specific):

- **Per-quantile accuracy bound (R4)**: reported in `-V` per quantile. With log-spaced bins the bound is uniform across quantiles for the *bin-resolution* component; the *sample-count starvation* component is reported separately per R7's `tail_sample_count_warning`.
- **Degenerate inputs (R5)**: zero, one, or all-same values must produce correct output without crashing.
- **Wide percentile set support**: `#189` R4 must handle all percentiles required by any consumer; the 10-value set from Path C1 is the worst case.
- **Out-of-range tallies (#34 R5/R6)**: under bin-counter mode, values below the partition's low edge or above its high edge are counted but not placed in interior bins. Handling is a `#189` R4 design question — D3 Decision 4 picks fold-into-edge-bins vs. separate-population.

#### D1 study — the substrate as already shipped

The HdrHistogram-style log-spaced bin-counter substrate is implemented and in production. The characterization below summarizes its properties as they apply to all four percentile-computing paths.

##### Bin geometry

**Partition**: `boundary[i] = min · (max/min)^(i/B)` where B is the bin count. Number of bins is `decades · buckets_per_decade` rounded to integer, with a minimum of 5 (`calculate_histogram_bucket_count` at `ltl:4867-4887`). Per-bin width ratio is `10^(1/buckets_per_decade)` — independent of position in the partition, by construction.

**Precision knob**: `buckets_per_decade`. The values shipped in `histogram-charts.md` correspond to:

| `buckets_per_decade` | Per-bin width ratio | Max relative error (bin midpoint) |
|---|---|---|
| 4 | 1.78× | ~28% |
| 8 (default) | 1.33× | ~14% |
| 16 | 1.155× | ~7% |
| 32 | 1.075× | ~3.6% |

These error bounds apply *uniformly* across quantiles — P50 and P99.9 inherit the same bound from the partition. The headline numbers in `histogram-charts.md` (10%, 5%, 2.5%, 1%) report the per-bin width fraction; the worst-case midpoint error is roughly half the bin width.

**Bin-find**: binary search over the boundary array (`find_histogram_bucket_index` at `ltl:4889-4905`). Closed-form `floor(B · log(v/min) / log(max/min))` is an alternative the consumer can choose at `#189` R2 implementation time.

##### Memory profile per partition

`B + 1` integer counters per partition. For B = 40 (default 5 decades × 8 buckets/decade), that is ~320 bytes per partition at 8 bytes per counter. Asymptotically independent of N.

For Path A (per-`(category, log_key)` partitions) at 10⁵ keys × ~320 bytes = ~30 MB total counter storage. Compares against today's `durations` arrays which scale with `sum_over_keys(occurrences_per_key) · 8 bytes` — typically hundreds of MB to GB on multi-GB runs.

For Path B (per-`time_bucket` partitions) when heatmap is active, the existing heatmap counter store is the source — zero additional state. When heatmap is not active, Phase 3 introduces a per-bucket counter store with the same shape.

##### CPU profile per partition

Per-update: O(log B) for binary-search bin-find, or O(1) for closed-form. No additional cost beyond counter increment.

Per-finalize: O(B) cumulative-count walk to locate the target bin, plus O(1) interpolation. For ten quantiles (Path C1's demand), O(10·B). B is typically 30–60, so per-finalize is trivial.

##### Determinism

Fully deterministic. Output is a function of bin counters only. R6 satisfied trivially.

##### Fit against each percentile-computing path

**Path A — summary-table per-message percentiles (Phase 2 target).** Per-`(category, log_key)` partition. Each `log_messages` entry already tracks its own `min` and `max` online (`ltl:5369-5371`) — the partition can be sized from those. Bin counter store replaces the raw `durations` array at `ltl:4591`. Percentile derivation (`calculate_statistics` at `ltl:5488`) replaces sort-and-index with `#189` R4 against the counter store. Counter footprint per key is small (B integers, ~320 bytes at B=40); the win at heavy-traffic keys (N=10⁴–10⁶) is large; the loss at single-occurrence keys is bounded.

**Path B — per-time-bucket duration percentiles (Phase 3 target).** Per-`time_bucket` partition. When heatmap is active, the heatmap counter store *is* the partition — Path B reads it via `#189` R4. When heatmap is not active, Phase 3 introduces an equivalent per-bucket counter store. The raw `durations` array at `ltl:4634` is removed.

**Path C1 — histogram-mode global percentiles (incidental Phase 2 consumer).** Single partition per metric. Histogram already builds the bin counters (`ltl:4961-4975`); today's code redundantly sorts the raw values for percentile derivation (`ltl:4926-4940`). The migration removes the redundant sort: percentiles derive from the bin counters via `#189` R4.

**Path C2 — heatmap percentile markers.** Per-`time_bucket` partition. Today's code sorts raw values to find bin indices (`ltl:4823-4834`). Under `#34` bin-counter mode, markers derive from `#189` R4 against the counter store, with the numeric return mapped back to a bin index via `#189` R2. Already documented as the migration target in `features/34-…md` R4-bis.

##### Accuracy story — two error sources, grounded

Tail-quantile accuracy (P99.9, P99.99) decomposes into two sources. Source 1 is documented in the consulted literature; source 2 is widely-attributed in the community but the grounding pass could not verify the canonical attributions in primary sources, so its framing is recorded honestly rather than as established prior art.

**Source 1 — Bin-resolution error (industry-documented).** Bounded uniformly by partition geometry. DDSketch publishes this contract explicitly as relative-error α; the relationship α ↔ γ ↔ buckets-per-decade is in the sketches-java implementation (the paper PDF could not be fetched). OTEL exponential histogram exposes the same property via the Scale → base relationship. HdrHistogram exposes it via "significant value digits." The bound applies *uniformly* across quantiles — by construction of the log-spaced partition, P50 and P99.9 inherit the same bin-resolution bound.

| `buckets_per_decade` | Per-bin width ratio | Source-defined contract analog |
|---|---|---|
| 4 | ~1.78× (~28% width) | — |
| 8 (ltl heatmap default) | ~1.33× (~14% width) | — |
| 16 | ~1.155× (~7% width) | DDSketch α ≈ 0.07 |
| 32 | ~1.075× (~3.6% width) | DDSketch α ≈ 0.036 |
| 53 (OTEP 149 Scale 4) | ~1.044× (~2.2% width) | OTEL Scale 4 "most interesting range" |
| 115 (DDSketch quick-start) | ~1.020× (~1% width) | DDSketch α = 0.01 README example |
| 616 (HdrHistogram 3-sig-digit) | ~1.0038× (~0.4% width) | HdrHistogram 3-significant-digit README example |

The within-bin return value (Decision 1) sits on top of this bound; the choices that use `rank_in_bin` (Prometheus convention) can in principle narrow the error inside the bin, while the choices that don't (HdrHistogram / DDSketch / OTEP 149 convention) leave the bin-resolution bound as the achieved accuracy.

**Source 2 — Rank under-support at the tail (community-attributed; primary-source attribution unverified).** P99.9 of 1,000 samples is the single highest value; P99.9 of 50 samples is widely regarded as not meaningful. Today's ltl sorted-array code (`ltl:5519-5525`) silently returns `sorted[int(N · 0.999)]` regardless of whether N supports that rank — a 50-occurrence message reports `sorted[0]` (the minimum) as its "P99.9". This is silently inaccurate.

The grounding pass attempted to locate primary-source attribution for the framings "percentile starvation" and "we are not who we measure" (commonly cited as Gil Tene's terminology). The mailing-list post on coordinated omission and the SlideShare deck of "How NOT to Measure Latency" were reached and read but **did not contain those phrases verbatim**. They are recorded in `features/187-histogram-industry-grounding.md` as **unverified attribution**. The conceptual point (rank under-support at the tail is a property of all estimators, not just bin-based ones) is well-defined and operational on its own terms; it is not asserted here as Tene-sourced canon.

The bin-counter approach inherits this limitation (no estimator can manufacture rank precision the data does not contain). Whether ltl exposes it as a `-V` warning is a *practical* design question (decision item 8); the literature consulted does not contain a documented per-quantile warning convention. Prometheus's structural NaN returns (no `+Inf`, zero observations) are the nearest analog, but they are partition-shape guards, not data-sufficiency guards.

**Operational consequence.** For high-volume per-key partitions and time buckets — the regime where P99.9 is operationally meaningful — bin-resolution error at the source-grounded precision values (Decision 2) is well within SRE tolerances. For low-volume partitions, no estimator (bin-based or sorted-array) gives a trustworthy P99.9; how loudly ltl chooses to signal this is the practical choice the decision conversation makes.

#### D1 study — open questions for D3

These are the questions the existing heatmap, histogram, `#34`, and `#189` documents do not answer, and that the decision conversation that follows D3 must close before Phase 2 implementation. Each links to the corresponding D3 subsection where the source-grounded options are presented; the candidate behaviors listed here are *enumerated for navigation*, with the cited primary sources in D3 (see `features/187-histogram-industry-grounding.md` for the full grounding extracts).

1. **In-bin interpolation strategy for `#189` R4.** Once the cumulative-count walk locates the target bin, what value does R4 return? The consulted bin-based libraries diverge: HdrHistogram returns the bin upper edge; DDSketch returns `lower · (1+α)`; Prometheus classic uses linear-in-value rank-in-bin interpolation; OTEP 149 recommends the log-scale midpoint `sqrt(lower · upper)`. The axis of divergence is whether to use `rank_in_bin` at all (Decision 1A surfaces this explicitly). See D3 § Decision 1.
2. **`buckets_per_decade` default for the per-message percentile path (Path A).** No primary source consulted publishes a single normative default; worked-example defaults across libraries span ~53 (OTEP 149 Scale 4) to ~616 (HdrHistogram README 3-significant-digit example) bins/decade. ltl's existing heatmap/histogram default is 8. See D3 § Decision 2.
3. **Per-bin sample-count behavior.** The consulted libraries (HdrHistogram, Prometheus, OTEL, DDSketch) implement no per-bin fall-through threshold — they return their per-bin value regardless of bin count. Whether ltl introduces one is an open divergence-from-industry-practice question. See D3 § Decision 3.
4. **R2.3 trigger threshold — when does exact mode fire.** The consulted libraries are silent on numeric gating thresholds between exact and approximate modes. The structural failure path (no index, no `+Inf`-equivalent, zero observations) has analogs in Prometheus's NaN returns. See D3 § Decision 6.
5. **Out-of-range tally handling.** `#34` R5/R6 tracks values outside the partition's `[min, max]` range. Industry practice converges on "never silently discard" but diverges on mechanism: Prometheus uses an `+Inf` bucket (no quantile interpolation inside it); HdrHistogram extends the partition; DDSketch uses ZeroCount + collapsing/unbounded store. See D3 § Decision 4.
6. **Path A partition lifecycle when the per-`(category, log_key)` `min`/`max` is only known partway through the parse.** Industry practice converges on online adaptation: HdrHistogram auto-resize, OTEL Scale downshift, DDSketch unbounded growth or collapse. Two-pass is *not* the field convention. The grounding doc records a gap: the per-key fan-out scenario is not directly mirrored in the consulted literature (gap 8 in `features/187-histogram-industry-grounding.md`). See D3 § Decision 5.

These six questions are the input to D3's memo. Source-grounded options for each are in the corresponding D3 subsection; the decision conversation closes them with explicit citations or with documented divergence rationale where ltl's case has no industry analog.

### D2 — Representative-dataset cross-reference

The representative data already exists in the `logs/` tree (see `docs/test-logs.md`). D2 is a cross-reference, not a curation effort — its job is to identify which existing log files exercise which use-case regime, so D1's analysis and any later D4 measurement have a known correspondence between dataset and use case.

D2 records, for each of the following regimes, the existing log file(s) that exercise it:

- Heavy-tailed access log (Tomcat / Apache style).
- ThingWorx mixed-traffic log.
- High-cardinality DEBUG-heavy log.
- Small-N case (a few hundred values per `log_key` or per `time_bucket`).
- Degenerate cases (all-same values, single value, zero matched values) — may be reproduced from existing logs via filters, no new files needed.
- Any pathological case relevant to ltl users (extreme outliers, etc.), drawn from existing logs.
- Per-time-bucket sub-samples for Phase 3 readiness — identifying which existing logs naturally produce small N per time bucket.

If a regime is not covered by an existing log file, D2 records the gap explicitly rather than fabricating data; the gap becomes a research input that D1 and D3 weigh.

#### D2 cross-reference

Populated against the inventory in `docs/test-logs.md` at `release/0.14.5` HEAD. Sizes shown for orientation only; relevance is determined by the regime, not the size.

| Regime | Why it matters to this research | Existing log file(s) | Notes |
|---|---|---|---|
| Heavy-tailed access log (Tomcat / Apache) | The dominant Phase 2 use case (Path A) and a Phase 3 driver (Path B). Tomcat/Apache access logs have right-skewed duration distributions — most responses fast, a long tail of slow ones. Tail-quantile (P99, P99.9) accuracy under this shape is the primary stress test for any candidate algorithm. | `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (277 MB Tomcat 9, ms latency); `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-06.txt` (220 MB); `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` (148 MB); `logs/AccessLogs/localhost_access_log.2025-03-21.txt` (2.6 MB, fast iteration); `logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` (658 KB, Apache HTTP2 with microsecond latency — distinct unit regime) | The four Tomcat files form a graduated size series for the same workload — useful for any analysis that wants to vary N without changing distribution shape. |
| ThingWorx mixed-traffic log | Path A and Path B coverage on a structurally different log family. ThingWorx CustomThingworxLogs carry `durationMS=` fields, enabling per-message latency percentiles on a non-access-log distribution shape (service-call latencies rather than HTTP response latencies). | `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log` (29 MB, canonical heatmap file per CLAUDE.md); `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.1.log` through `.4.log` (72–98 MB each, same workload graduated); `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-10.0.log` (98 MB); `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.log` (54 MB) | The clean variant has duration, bytes, and count metrics simultaneously — useful for cross-metric percentile coherence checks. |
| High-cardinality DEBUG/ERROR-heavy log | Path A under the regime where the per-`log_key` distribution flattens (many distinct log keys, few values each). Stresses the small-per-key-N behavior of any algorithm chosen for Path A. Also relevant to Path C1 if histogram mode is engaged on the same file. | `logs/ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log` (101.7 MB; 288K lines, ~286K unique keys — per consolidation memory); `logs/ThingworxLogs/ApplicationLog.2025-05-05.0.log` (85 MB, broader L:DEBUG/INFO/WARN/ERROR mix); `logs/ThingworxLogs/ApplicationLog.2025-05-06.0.log` (6.5 MB); `logs/ThingworxLogs/ApplicationLog.2025-12-12.282-Windows.log` (10 MB, Windows variant) | These files do not carry per-message duration values (no `durationMS=`). They are relevant to Path C1 (histogram-mode global, when `-hg` is run) and to count-based percentile regimes; per-message duration percentiles (Path A) do not apply to these files unless paired with a metric source. Documented as a constraint, not a gap. |
| Small-N case (a few hundred values per `log_key` or per `time_bucket`) | Path B at typical bucket sizes routinely produces small N per bucket. Path A at one-off log messages produces single-occurrence keys. The substrate's behavior here is the focus of D3 Decision 3 (tail-bin fall-through) and Decision 6 (small-N gating into exact mode). | `logs/Codebeamber/codebeamer_access_log.2025-10-29.txt` (83 KB, naturally small); `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log` (739 KB, single-service slice); `logs/ThingworxLogs/AuthLog.2025-05-06.0.log` (257 KB); `logs/ThingworxLogs/DatabaseLog.2025-05-05.0.log` (700 KB); `logs/ThingworxLogs/DatabaseLog.log` (29 KB, very small) | Small-N per *time bucket* can also be induced on any larger file by narrowing the bucket size (`-b 0.1` for 6-second buckets, `-ms` for millisecond precision). The cross-reference notes that this is reachable from existing files via CLI flags rather than requiring a dedicated file. |
| Degenerate — all-same values | Edge case R5; trivially handled by exact mode; approximate mode must agree. | Reproducible by filtering any existing file to a single repeated message (`-if <pattern>` selecting one log_key) where every value is the same — common for health-check endpoints. Health-check filter pattern files exist (`patterns/probes`, `patterns/metrics`). | No dedicated file. |
| Degenerate — single value | Edge case R5. | Reproducible by filtering any existing file to a one-occurrence message. | No dedicated file. |
| Degenerate — zero matched values | Edge case R5. | Reproducible on any file with `-if nonexistent-pattern`. | No dedicated file. |
| Pathological — extreme outliers in heavy-tailed data | Captures the regime where a few values are orders of magnitude above the bulk. Stresses tail-quantile (P99.9) accuracy specifically; the question is whether the algorithm represents the outlier as a distinct rank or absorbs it into a neighboring bin/centroid. | The Tomcat access logs listed under "Heavy-tailed" already exhibit this naturally — occasional multi-second requests in millisecond-dominated traffic. `logs/AccessLogs/really-big/*` (8.5 GB Tomcat 10, 4 servers × 28 days) is the production-scale variant if outlier density at scale is part of D1's analysis. | The `really-big/*` set is large enough to stress production-scale considerations but is not required for D1's literature work. |
| Per-time-bucket sub-samples (Phase 3 readiness) | Phase 3 (Path B) reads percentiles per `time_bucket`. The N per bucket varies with file size, traffic density, and bucket width. D1 must consider candidate algorithms' behavior across the resulting N regime (tens to thousands of values per bucket on typical files; extremes possible). | Achievable from any heavy-tailed access log by varying `-b` (e.g., `-b 0.1` on the 2.6 MB file produces narrow buckets with low per-bucket N; `-b 60` on the 277 MB file produces wide buckets with high per-bucket N). The extreme small cases are `logs/ThingworxLogs/ApplicationLog-improperlyRead.log` (468 B) and `logs/ThingworxLogs/CommunicationLog.2025-05-06.0.log` (190 B) where the entire file is a few lines. | No dedicated per-bucket sub-sample file; the regime is reached by CLI flag variation on the heavy-tailed files. |

#### Gaps recorded

- **No log with externally-labeled ground-truth percentile values.** All ground truth for accuracy comparison is derived by running ltl in exact mode on the same file. This is acceptable for D1 (literature analysis does not need empirical ground truth) and for D4 if triggered (exact-mode output is the reference). Recorded so the gap is explicit if D3 later argues for an empirical confirmation step.
- **No synthetic log with controlled distribution parameters** (e.g., Pareto with specified α, log-normal with specified σ). The heavy-tailed access logs are heavy-tailed *in fact* but the tail parameters are not labeled. D1's literature analysis can reference theoretical results for parameterized distributions independently; D3 weighs whether the absence of synthetic controls is a material gap.
- **No log isolating a single percentile-extreme regime.** Real-world logs mix regimes; isolating "small-N only" or "outlier-dominated only" requires CLI filtering of an existing file rather than a dedicated dataset. Recorded as a constraint on how D1 frames its examples (regime descriptions reference CLI invocations on listed files, not standalone synthetic inputs).
- **UDM CSV inputs** (`logs/UDM/*`) are outside the Phase 2/3 scope (those features carry user-defined metrics, not per-message latency for the summary table or per-time-bucket duration for the heatmap). Listed here only to record that they were considered and excluded.

### D3 — Decision-support memo

D3 is the central deliverable of Phase 1. It synthesizes D1's analysis into a memo whose purpose is to put the user in a position to **make the decisions that define the unified primitive contract** (F1, D1, D1A, D2, D4, D5). These decisions apply to every consumer of percentile values or histogram bin counts in ltl — they are contract-level, not consumer-specific. D3 presents options for each decision with trade-offs and source-grounding, not a pre-committed recommendation.

D3 does **not** lock the implementation. The decision conversation between user and Claude is what locks it; D3 is the input to that conversation, and the locked entries live in *Locked decisions from research*.

> **Status as of 2026-05-19: GROUNDED + F1, Decisions 1, 1A, 2, 3, 4, 5, 7, 8, 10 locked; Decisions 6, 9 DISSOLVED. All decision-conversation work complete.** The D3 content has been rebuilt from `features/187-histogram-industry-grounding.md` (industry-practice research pass) with primary-source citations. Locked: **F1** (design-philosophy framing: ltl as query-time analyzer, `buckets_per_decade` as the analyst's lever, rank-in-bin information used); **Decision 1** (R4 uses the Prometheus native-exponential in-bucket interpolation formula, verified verbatim against `promql/quantile.go` lines 331–353); **Decision 1A** (use rank-in-bin); **Decision 2** (`buckets_per_decade` default 53 / OTEP-149 Scale-4 analog; two CLI flags — numeric `-pbpd` and tiered `--percentile-precision 1..9`; valid range 4 ≤ N ≤ 616; `-pbpd` always wins on conflict); **Decision 3** (no per-bin sample-count guard in R4; no partition-level rank-support signal in `-V`; follows strict industry convention); **Decision 4** (Prometheus `+Inf` overflow convention adopted verbatim for high end; symmetric `-Inf`-equivalent underflow convention for low end; separate counters; overflow/underflow contribute to N; R4 returns `boundary[B]` or `boundary[0]` if target rank lands in overflow/underflow; per-quantile `-V` audit field `out_of_range_bounded: high|low|none`); **Decision 5** (HdrHistogram-style auto-resize per partition across all consumers; partition seeded with full-default-span centered on first value; HdrHistogram-convention doubling on rebin; no precedent run or #179 index dependency for partition sizing; per-partition rebin telemetry exposed in `-V` for empirical seed-heuristic tuning); **Decision 7** (visible `--exact-percentiles` flag with deprecation notice; global scope; available one release cycle past each consumer's migration validation per implementation-ticket choice; `-V` reports top-level banner AND per-consumer `user_opt_out` line per R10); **Decision 8** (`-V` `=== BIN-COUNTER MODE ===` section with run-level header + per-consumer blocks; locked consumer-name strings; field names and section/consumer/field naming all locked; format mirrors existing `=== INDEX READ-BACK ===` convention; primary purpose is testability and AI-agent debugging); **Decision 10** (prototype validation scope — five mandatory aspects #189 must validate empirically before production code begins: in-bin formula on real data, auto-resize lifecycle on per-key fan-out at scale, initial seed heuristic + overflow/underflow on edge cases, end-to-end `-V` output sample, calculation accuracy vs. current array-of-values approach; hard prerequisite for #189 production code). **Decision 6** dissolved — no runtime gate in the unified contract. **Decision 9** dissolved — activation policy and release-engineering decisions are out of scope for #187; they belong to the per-consumer implementation tickets that consume this contract.

#### D3 memo — the six decisions

For each open question from D1, D3 presents the candidate answers with their consequences, the dependencies between decisions, and the D4-trigger condition that fires if literature is insufficient to choose.

#### Design philosophy framing — the analyst's lever

This framing was settled in the decision conversation on 2026-05-19 and anchors Decisions 1 and 2 below. Recording it explicitly so subsequent decision-making derives from a coherent design intent rather than re-debating it per decision.

**The structural position ltl occupies (different from pre-aggregated metric systems).** Prometheus, OpenTelemetry, DDSketch, and HdrHistogram are all *recording-time* substrates: the producer fixes the partition (Scale / bucket boundaries / α / significant digits) when the data is created, and every downstream consumer reads percentiles within whatever resolution the producer chose. Once a Prometheus native histogram is scraped at Scale 2 (~13 bins/decade), no later consumer can recover sharper precision — the higher-resolution information was discarded at recording time.

ltl is in a fundamentally different position. **The raw values still exist in the log file.** ltl builds the bin counters at *analysis time*, not at recording time. This means the precision parameter is a query-time choice, not a recording-time choice. An analyst can re-run ltl with `-pbpd 32`, `-pbpd 64`, or higher and get tighter tail-percentile accuracy on the same input. The memory cost is paid once, during a foreground analysis run while the analyst waits — not as a 24×7 scrape-and-store cost in a metrics backend.

**Architectural consequence: `buckets_per_decade` is the analyst's lever.** It is not a system-default-and-forget knob (the way OTEL Scale and DDSketch α typically are in their production deployments). It is the parameter the analyst tunes to the precision regime appropriate for the investigation: a quick triage at low precision, an SRE-grade tail-percentile investigation at higher precision, a forensic deep-dive at the highest precision the log file's value distribution can support.

**What this argues for in Decisions 1 and 2.**

For Decision 1 (in-bin rule): the rank-in-bin information is *available* to ltl in a way it typically is not in pre-aggregated systems (the bin counters are built fresh from raw values during the parse, so per-bin counts reflect the actual within-bin distribution at the precision currently configured). Following the Prometheus convention — which is also the convention New Relic adopts for explicit-bucket → exponential translation — uses that information rather than discarding it.

For Decision 2 (`buckets_per_decade`): default is set for a reasonable analyst working interactively at the terminal on real log files, with documented levers to push higher when the precision regime demands it. The high-precision regime is *achievable in ltl in a way it is not achievable from pre-captured metrics*, and this is part of ltl's value proposition: logs contain information that pre-aggregated metrics have already thrown away.

**Distinction from "industry standard" claim.** The grounding pass found that the four production bin-based libraries (HdrHistogram, Prometheus, OTEL/OTEP, DDSketch) do *not* converge on a single in-bin rule. Prometheus and New Relic share linear-in-value rank-in-bin interpolation; HdrHistogram (bin upper edge) and DDSketch (`lower · (1+α)`) ignore rank-in-bin entirely. The framing above does not assert "Prometheus is the industry standard." It asserts that **Prometheus's convention is the most widely-deployed *query-time analyzer* convention** (because Prometheus + Grafana is the dominant query-time stack), and that ltl's analyst use-case has more in common with the query-time analyzer role than with the recording-side library role.

##### Decision 1 — In-bin interpolation strategy for `#189` R4 — **READY-TO-LOCK (2026-05-19); formula verified against Prometheus source**

**Framing settled**: per the **Design philosophy — analyst's lever** section above, ltl's role is the query-time analyzer (consuming raw values from log files at analysis time, exposing precision as a user-tunable parameter), not a recording-side library. The corresponding in-bin convention is the one used by **Prometheus native exponential `histogram_quantile()`** — log-scale-aware rank-in-bin interpolation — which is also the convention New Relic adopts for its explicit-bucket → exponential translation. This is the candidate the decision conversation now centers on; the other source-grounded options below are retained for the record but not the leading candidate.

**Why this convention specifically.** The rank-in-bin information is genuinely available to ltl (counters are built fresh from raw values during the parse), and discarding it would be giving up information that pre-aggregated systems lack but ltl has. The log-spaced refinement (vs. Prometheus's classic linear-in-value) matches ltl's log-spaced substrate (`ltl:4961-4966`).

**Implementation form** — verified verbatim against Prometheus `promql/quantile.go` lines 331–353 (commit `main` HEAD as of 2026-05-19):

Prometheus source (exponential-histogram path, positive bucket):
```go
// The fraction of how far we are into the current bucket.
fraction := rank / bucket.Count

// ... custom-bucket and zero-bucket fallback elided ...

// For exponential buckets, we interpolate on a logarithmic scale. On a
// logarithmic scale, the exponential bucket boundaries (for any schema)
// become linear (every bucket has the same width). Therefore, after
// taking the logarithm of both bucket boundaries, we can use the
// calculated fraction in the same way as for linear interpolation (see
// above). Finally, we return to the normal scale by applying the
// exponential function to the result.
logLower := math.Log2(math.Abs(bucket.Lower))
logUpper := math.Log2(math.Abs(bucket.Upper))
if bucket.Lower > 0 { // Positive bucket.
    return math.Exp2(logLower + (logUpper-logLower)*fraction), annos
}
```

R4 in pseudocode, matching the Prometheus exponential-bucket path:
```
R4(partition, counter_map, q):
  total_N      = sum of counter_map
  target_rank  = ceil(q * total_N)
  walk counter_map to find bin_i containing target_rank
  rank_in_bin  = target_rank - (cumulative count before bin_i)
  bin_count    = counter_map[bin_i]
  lower        = partition.boundary[bin_i]
  upper        = partition.boundary[bin_i + 1]
  fraction     = rank_in_bin / bin_count

  # Verbatim Prometheus exponential-bucket formula:
  log_lower = log2(lower)
  log_upper = log2(upper)
  return 2 ** (log_lower + (log_upper - log_lower) * fraction)
```

The Prometheus formula `Exp2(log2(lower) + (log2(upper) - log2(lower)) * fraction)` is algebraically identical to `lower * (upper / lower) ** fraction` — log-base cancellation makes the formula independent of which logarithm is used. ltl's implementation should match Prometheus's `log2 / exp2` convention so reproducibility against Prometheus reference output is exact at the floating-point level (different log bases will produce ULP-level differences).

**Prometheus's own rationale** (verbatim from the source-code comment) — recording this because it is the same argument that anchors ltl's F1 framing:
> "For exponential buckets, we interpolate on a logarithmic scale. On a logarithmic scale, the exponential bucket boundaries (for any schema) become linear (every bucket has the same width). Therefore, after taking the logarithm of both bucket boundaries, we can use the calculated fraction in the same way as for linear interpolation."

**Special cases in the Prometheus source that do not apply to ltl** (recorded for completeness):
- **Custom-bucket and zero-bucket fallback** (`promql/quantile.go` line 336–338): if the histogram uses custom (non-exponential) buckets, or if the target bucket spans zero (`bucket.Lower <= 0 && bucket.Upper >= 0`), Prometheus falls back to linear-in-value interpolation. **ltl's substrate is purely log-spaced over positive duration values** (`ltl:4961-4966`); ltl has no custom-bucket mode and no bucket spans zero. This fallback case does not apply.
- **Negative-bucket mirror** (`promql/quantile.go` line 353): Prometheus supports negative-value buckets via a mirrored formula. **ltl's durations are positive; no negative-bucket handling is needed.**

**Status**: Decision 1 formula is now source-verified. Decision 1 moves from FRAMING SETTLED to ready-to-lock. The lock entry in *Locked decisions from research* below should record the verified formula and the Prometheus source citation.

**Source-grounded options retained for the record.** The four primary sources for bin-based percentile estimation **do not converge**, and the convention chosen above (Prometheus native exponential) is one of two camps. Recorded here so the choice is auditable:

| Source-grounded option | What the source does | Citation | Match to ltl's case |
|---|---|---|---|
| (a) **Bin upper edge** (per-bin fixed) | HdrHistogram `getValueAtPercentile` returns `highestEquivalentValue(valueFromIndex(i))` for any non-zero percentile (and `lowestEquivalentValue(...)` only for percentile 0); rank-in-bin is unused. | `AbstractHistogram.java` `getValueAtPercentile`; raw source at HdrHistogram/HdrHistogram/master | ltl substrate is log-spaced like HdrHistogram's. Direct analog. |
| (b) **Linear-in-value rank-in-bin interpolation** | Prometheus classic `histogram_quantile()`: `quantile = bucketStart + (bucketEnd − bucketStart) · (rank / count)` — "it assumes a uniform distribution of observations within the bucket (also called _linear interpolation_)." | PromQL docs, `promql/quantile.go` `bucketQuantile` | Source's assumption is linear-spaced buckets; ltl's are log-spaced. Geometry mismatch is documented in the grounding doc. |
| (c) **Log-scale-aware refinement** (rank-in-bin in the geometric-resolution sense) | Prometheus native exponential `histogram_quantile()`: "the interpolation is done under the assumption that the samples within the bucket are distributed in a way that they would uniformly populate the buckets in a hypothetical histogram with higher resolution." | PromQL docs (native histograms section) | Structural analog: log-spaced bins. The exact formula was not directly quoted in the grounding fetch; the docs describe the assumption in prose. |
| (d) **Log-scale midpoint of the bin** (per-bin fixed; geometric midpoint `sqrt(lower · upper)`) | OTEP 149 (exponential-histogram **proposal**, preserved-as-reference; not adopted into the OTEL specification): "To minimize relative error, percentile calculation usually returns log scale mid point of a bucket." | OTEP 149 (`oteps/text/0149-exponential-histogram.md`) | **Important caveat**: the OTEL data-model spec, SDK spec, and Prometheus/OpenMetrics compatibility doc are deliberately silent on quantile estimation — by design, OTEL owns the representation and leaves estimation to consumers. OTEP 149 is proposal text, not normative spec; the OTEP repository carries the header "OTEPs have been moved to the Specification repository. This repository has been preserved for reference purposes." The "log-scale midpoint" guidance has *not* been adopted into the OTEL specification. Citing OTEP 149 as a source-grounded option means citing "what one OTEL proposal advocates" not "what OTEL officially specifies." |
| (e) **Scaled lower bound** (per-bin fixed at `lower · (1 + α)`) | DDSketch `LogLikeIndexMapping.value(int)`: `return lowerBound(index) * (1 + relativeAccuracy);` and `DDSketch.getValueAtQuantile` returns that representative unconditionally for whichever bin contains the rank. | `LogLikeIndexMapping.java`, `DDSketch.java` (DataDog/sketches-java) | Direct analog: DDSketch's substrate is log-spaced with relative-error α. The representative is chosen so any true value in the bin is within α of the returned value. |

**Axis of divergence** (per grounding doc § Decision 1 convergence/divergence summary): whether to use `rank_in_bin` at all. HdrHistogram, OTEP-149, and DDSketch ignore `rank_in_bin` (single per-bin answer). Prometheus uses it. All four sources agree that the bin's identity, not its interior, is the dominant accuracy term — the bin is sized small enough (by precision parameter choice in Decision 2) that any in-bin convention satisfies the library's stated accuracy contract.

**Options not retained**: bin lower boundary (`boundary[i]`), bin arithmetic midpoint (`(lower+upper)/2`), and linear-in-log rank-in-bin interpolation (`lower · (upper/lower)^(rank_in_bin / bin_count)`) were listed in the prior provisional D3 but are **not the documented behavior of any source consulted**. The prior provisional Decision 1 selected linear-in-log rank-in-bin interpolation; the grounding pass did not find this in HdrHistogram, Prometheus, OTEL, or DDSketch source/docs. Linear-in-log interpolation is therefore not on the source-grounded option list above.

**D4-trigger**: candidate. The decision conversation may decide to prototype the source-grounded options (a, d, e in particular — the per-bin fixed-value family) against the D2 datasets to verify empirically that the per-bin choice within ltl's data is dominated by the precision-parameter choice (Decision 2), as the grounding doc states the libraries assume.

##### Decision 1A — Whether to interpolate at all using `rank_in_bin` — **FRAMING SETTLED (2026-05-19)**

Surfaced explicitly by the grounding pass. The four sources divide on this axis:

| Position | Source(s) |
|---|---|
| **Do not use `rank_in_bin`** — return a fixed per-bin representative value | HdrHistogram (upper edge), OTEP 149 (log-scale midpoint), DDSketch (`lower · (1+α)`) |
| **Use `rank_in_bin`** — interpolate within the bin | Prometheus classic (linear-in-value), Prometheus native exponential (log-aware refinement), New Relic NrSketch (explicit-bucket → exponential translation) |

**Framing-settled answer**: ltl uses `rank_in_bin`. Per the design-philosophy framing above, the rank-in-bin information is available to ltl at analysis time (the counters are built fresh from raw values during the parse), and discarding it would forfeit information that pre-aggregated systems lack but ltl has. Following the Prometheus / New Relic camp on this axis is consistent with the analyst's-lever framing. The HdrHistogram / DDSketch convention is recorded as legitimate industry practice but is the recording-side library posture, not the query-time analyzer posture.

##### Decision 2 — `buckets_per_decade` — **LOCKED (2026-05-19)**

**Locked (2026-05-19)**: per F1 (analyst's-lever framing), `buckets_per_decade` is the user-tunable precision lever, exposed by two CLI flags (numeric `-pbpd` for development/testing/research; tiered `--percentile-precision 1..9` for day-to-day analyst use). Default `buckets_per_decade = 53` (OTEP-149 Scale-4 analog, ~1.1% midpoint error); valid range 4 ≤ N ≤ 616; `-pbpd` always wins when both flags are specified. Full lock recorded in *Locked decisions from research* § Decision 2 below — that entry is authoritative.

The remainder of this subsection records the source-grounded analysis the lock was derived from.

The primary sources do not publish a single normative default; each library expresses precision in its own native units (significant digits / Scale / α / γ) and presents defaults via worked examples. Grounding extracted from `features/187-histogram-industry-grounding.md` § Decision 2 (with the α↔γ↔bpd conversions taken from the DDSketch implementation since the VLDB paper PDF could not be fetched):

| Source | Native precision unit | Worked-example value | Buckets per decade (computed) |
|---|---|---|---|
| **HdrHistogram README** (worked example for "response time tracking") | `numberOfSignificantValueDigits` | 3 | ~616 bins/decade (subBucketCount=2048 per doubling; 2048/log₂(10)) |
| **OTEP 149** ("most interesting range of baseScale is around -4") | `Scale` (signed) | Scale 4 → 16 bins per doubling | ~53 bins/decade (16 · log₂(10)) |
| **OTEL data-model worked Scale 5 row** | `Scale` | 5 → 32 bins per doubling | ~106 bins/decade |
| **DDSketch sketches-java README** quick-start | `relativeAccuracy` (α) | 0.01 (1%) | ~115 bins/decade (γ=(1+α)/(1−α); ln(10)/ln(γ)) |
| **DDSketch worked α=0.02** | α | 0.02 (2%) | ~57 bins/decade |
| **DDSketch worked α=0.05** | α | 0.05 (5%) | ~23 bins/decade |
| **ltl heatmap/histogram existing** | `buckets_per_decade` | 8 | 8 bins/decade (~7% per-bin width per `histogram-charts.md`) |

The worked-example defaults span roughly an order of magnitude — from OTEP-149's Scale-4 (~53 bpd) to HdrHistogram's 3-significant-digit example (~616 bpd). None of HdrHistogram README, OTEL data-model spec, Prometheus practices doc, or DDSketch README pins a normative default through primary documentation; defaults live in client libraries and worked examples.

**ltl context (preserved from prior D3 for memory-cost framing, not for the value choice):** at 5 decades range,

| `buckets_per_decade` | Bins per partition | Bytes per partition (8 B/counter) | Total at 10⁵ keys (Path A scale) |
|---|---|---|---|
| 8 (existing histogram default) | 40 | 320 B | ~32 MB |
| 16 | 80 | 640 B | ~64 MB |
| 32 | 160 | 1280 B | ~128 MB |
| 53 (OTEP-149 Scale-4 analog) | 265 | 2120 B | ~212 MB |
| 115 (DDSketch α=0.01 analog) | 575 | 4600 B | ~460 MB |
| 616 (HdrHistogram 3-sig-digit analog) | 3080 | 24,640 B | ~2.5 GB |

Memory becomes a binding constraint at the higher source-grounded defaults. Whether that constraint matters depends on Decision 5 (lifecycle) — DDSketch's collapsing store and OTEL's Scale-downshift convention exist precisely to bound the per-stream cost; ltl's per-`(category, log_key)` fan-out does not have a direct analog in the consulted literature (recorded as gap 8 in `features/187-histogram-industry-grounding.md`).

**Source-grounded candidate defaults for the decision conversation**:
- **`buckets_per_decade = 8`** — current ltl heatmap/histogram default; smallest memory; no source matches this value but ltl's own precedent (`ltl:286`, `histogram-charts.md`) is consistent.
- **`buckets_per_decade ≈ 53`** — OTEP-149's "most interesting" range (Scale 4); ~2.2% bin-width error.
- **`buckets_per_decade ≈ 115`** — DDSketch quick-start (α=0.01); ~1% relative-error contract.
- **`buckets_per_decade ≈ 616`** — HdrHistogram README's 3-significant-digit example; ~0.16% relative error.

**Framing implication for the default choice.** Given the analyst's-lever framing, the default is set for a reasonable interactive triage on real log files — not for a fixed recording-time deployment. Two characteristics of ltl's situation argue for choosing the default closer to "high-precision query-time analyzer" than to "low-precision recording-side default":

1. The cost is paid once per analysis run, foreground, while the analyst waits — not continuously across a metrics deployment.
2. The information is recoverable: an analyst who finds the default too coarse can re-run with a higher lever setting on the same file. An analyst who finds the default too high can re-run lower. This bidirectional knob is a property pre-aggregated metric systems do not have.

The CLI flag exposing this lever is part of the choice. Carrying forward the prior `--percentile-buckets-per-decade` / `-pbpd` naming as a candidate; alternative names (e.g., `-pbpd`, `-pbd`, `-prec`) are practical-decision territory. The flag must be independent of `-hgbpd` (which governs the heatmap/histogram visualization path; visualization precision is a separate concern from percentile precision).

**D4-trigger**: candidate. The decision conversation may decide to prototype on D2 datasets to confirm bin counts vs. memory cost on real per-key fan-out before locking the default. Particularly relevant if a high-bpd source-grounded default (≥53) is under serious consideration, since the per-key fan-out cost is not addressed by the consulted literature.

##### Decision 3 — Per-bin sample-count guard and partition-level rank-support signalling — **LOCKED (2026-05-19)**

**Locked (2026-05-19)**: ltl follows the strict industry convention — no per-bin sample-count guard in R4, no partition-level rank-support signal in `-V`. R4 returns the Prometheus formula's output regardless of bin_count or total partition count. Full lock recorded in *Locked decisions from research* § Decision 3 below — that entry is authoritative.

The remainder of this subsection records the source-grounded analysis the lock was derived from.

The prior D3 framed this as "at what `bin_count` value do we abandon the linear-in-log formula and return the geometric midpoint instead?" That framing was tied to the linear-in-log invented rule which was discarded when Decision 1 locked the Prometheus formula. Under the Prometheus formula, the question dissolves: at `bin_count = 1, rank_in_bin = 1`, the formula returns `lower · (upper/lower)^1 = upper`, which is exactly what HdrHistogram does as its main convention. The formula is mathematically well-defined for any positive bin_count and behaviorally sensible without special-case logic.

The grounding pass found **no primary source consulted implements a per-bin sample-count fall-through**:

- **HdrHistogram** `getValueAtPercentile` returns `highestEquivalentValue(valueAtIndex)` regardless of bin count — 1 sample or 1,000,000 samples take the same path. (`AbstractHistogram.java`, source quoted in `features/187-histogram-industry-grounding.md` § Decision 1.)
- **Prometheus** `bucketQuantile` has structural NaN guards (fewer than 2 buckets, no `+Inf` bucket, zero observations) but no per-bin sample-count guard. (PromQL docs; `promql/quantile.go`.)
- **OpenTelemetry exponential histogram** spec and OTEP 149 do not specify quantile-estimation procedure at all, and therefore no fall-through. (OTEL data-model and OTEP 149.)
- **DDSketch** `getValueAtQuantile` returns the per-bin representative `lowerBound(index) · (1 + α)` unconditionally; the relative-error guarantee α holds for any non-empty bin regardless of bin count. (`DDSketch.java`, `LogLikeIndexMapping.java`.)
- **Apache DataSketches KLL** exposes rank error as a uniform ε across the rank space; no per-bin threshold (KLL is not bin-based, so a per-bin threshold has no direct analog).
- **Gil Tene** on coordinated omission addresses *recording-time* correction (`recordValueWithExpectedInterval`), not estimation-time per-bin guards. The "percentile starvation" / "we are not who we measure" attributions were **not located verbatim** in any primary source reached this pass.

**The shared assumption in the consulted libraries**: the bin's identity (determined deterministically by the cumulative walk) is sufficient. Accuracy is governed by the precision-parameter choice (Decision 2), not by bin sample count. Library authors do not add per-bin guards because the bin is — by construction of the precision parameter — small enough that the bin-resolution bound is acceptable for any rank within it.

**Implication for ltl**: a per-bin fall-through threshold (the prior provisional T=5 rule) **does not exist in industry practice**. If ltl introduces one, it is a divergence from industry practice and the conduct rules require that divergence be documented explicitly with rationale.

**Options for the decision conversation**:

| Option | Source(s) | Behavior |
|---|---|---|
| **(A) No per-bin fall-through** — follow industry convention | HdrHistogram, Prometheus, OTEL, DDSketch all behave this way | R4 returns its chosen per-bin value (per Decision 1) for any non-empty bin regardless of count. |
| **(B) Introduce a per-bin fall-through** — divergence from industry practice | None | R4 switches to a different value (e.g., geometric midpoint) when `bin_count < T`. Requires written justification per the conduct rules. ltl-specific rationale (e.g., per-`(category, log_key)` partitions with many keys at small N — gap 8 in the grounding doc — may or may not justify this divergence). |

**Related but distinct concern** that the libraries *do* address indirectly via warning conventions:

- The case of **total partition count too low for the target rank** (e.g., requesting P99.9 of a 50-count partition) is a *data sufficiency* question, not a per-bin question. Prometheus addresses related structural failures by returning `NaN` (no `+Inf` bucket, zero observations). The grounding doc records that no consulted source has an explicit "rank starvation" warning, but the existence of structural-NaN paths in Prometheus shows the field's pattern: surface unreliable answers as a distinct return value, not as a silently-modified estimation.

**`-V` reporting implication**: R7 currently calls for `tail_sample_count_warning` and `tail_sample_count_starved` as per-quantile warnings. The library practice doesn't define `tail_sample_count_warning` (the per-bin variant) but does (in Prometheus) have an analog for structural failure. The `tail_sample_count_starved` variant (total partition count too low) has no direct source-grounded contract but is a defensible local-honesty addition; it should be marked as ltl-specific rather than claimed as industry practice.

**D4-trigger**: candidate. Whether option (A) is adequate for ltl's per-key fan-out scenarios — particularly Path A keys with N in the 10–100 range — is the question the decision conversation must close. Could be answered by D2-dataset measurement comparing per-quantile error from option (A) against exact-mode output on small-N keys.

##### Decision 4 — Out-of-range tally handling — **LOCKED (2026-05-19)**

**Locked (2026-05-19)**: ltl adopts the Prometheus `+Inf` overflow convention verbatim, with a symmetric `-Inf`-equivalent underflow convention for the low end. Full lock recorded in *Locked decisions from research* § Decision 4 below — that entry is authoritative.

The remainder of this subsection records the source-grounded analysis the lock was derived from.

`#34` R5/R6 produces overflow counts at the low and high ends of the partition (values outside `[min, max]` when the partition was sized before those values were seen — possible under widening strategies for Path A). `#189` R4 must specify what to do with them.

The consulted sources **converge on "never silently discard out-of-range counts" but diverge on mechanism**. Grounding extracted from `features/187-histogram-industry-grounding.md` § Decision 4:

| Source | Mechanism | Quantile-time behavior |
|---|---|---|
| **Prometheus / OpenMetrics** | Explicit `+Inf` overflow bucket (OpenMetrics spec: "Histogram MetricPoints MUST have one bucket with an `+Inf` threshold"). Cumulative-count semantics include the `+Inf` count in the denominator. | Quoted from PromQL docs / `bucketQuantile`: "If a quantile is located in the highest bucket, the upper bound of the second highest bucket is returned." Prometheus does *not* interpolate inside the unbounded `+Inf` bucket; it returns a finite value at the boundary of the last finite bucket. |
| **OpenTelemetry exponential histogram** | `zero_count` for values whose magnitude ≤ `zero_threshold`. For values too large to map: producers SHOULD ensure index range stays within signed 32-bit. No explicit upper overflow bucket; Scale downshift is the convention when range grows. | Spec does not define a quantile-time treatment for out-of-range values; the convention is to keep the partition wide enough to contain them. |
| **HdrHistogram** | `highestTrackableValue` set at construction; values above throw `ArrayIndexOutOfBoundsException` unless `autoResize` is enabled, in which case `handleRecordException` calls `resize(value)` and extends the partition. | No quantile-time overflow handling because the partition is always extended to contain observed values; out-of-range is a *recording-time* error, not an estimation-time concern. |
| **DDSketch** | `zeroCount` field absorbs values within `[−minIndexedValue, minIndexedValue]`. For values exceeding bin-array capacity: collapsing store discards bins from one end (e.g., `CollapsingLowestDenseStore` discards low-indexed bins to make room at the high end); unbounded store grows. | Quantile-time treatment follows from collapsing/growth: values that fit map to bins normally; values that fell out via collapse are no longer recoverable as distinct rank positions but their counts still contribute to N. |

**The Prometheus `+Inf` convention is the only consulted source that addresses out-of-range *at quantile-estimation time* with a documented, citeable rule.** The user has previously identified this as the canonical answer ("the infinity bucket is not used for determining timing because we do not know what the timing for anything that is over the last deterministically sized bucket is"). The grounding pass confirms this is exactly what Prometheus `histogram_quantile()` does.

**Source-grounded options for R4**:

| Option | Source | Behavior under R4 |
|---|---|---|
| **(A) Prometheus `+Inf` convention** — distinguish overflow counts from interior counts; do not interpolate inside the overflow bucket | Prometheus PromQL docs; `promql/quantile.go`; OpenMetrics spec | If the target rank lands in the high-overflow bucket, R4 returns the upper boundary of the last finite bin (i.e., the partition's `max`) rather than attempting to manufacture a value. Overflow counts contribute to total N for denominator correctness. |
| **(B) Auto-extend the partition** | HdrHistogram `autoResize` | If a recorded value falls outside, expand the partition in place. R4 then never sees overflow because it never exists at quantile time. Requires Decision 5 to choose this lifecycle. |
| **(C) Collapse/downshift the partition** | DDSketch `CollapsingLowest/HighestDenseStore`; OTEL Scale downshift | If a recorded value falls outside the bounded store, absorb it by collapsing/downshifting other bins. R4 sees a deformed partition but no separate overflow population. Tied to Decision 5. |

**Option previously framed ("fold into edge bins" as a third option)** — this is *not* what any consulted source does. Prometheus explicitly refuses to interpolate inside the unbounded bucket; HdrHistogram and DDSketch handle the recording-time question by extending or collapsing rather than folding. The "fold into edge bins" framing was a first-principles option from the prior pass and is removed from the candidate set.

**D4-trigger**: none. The decision is between three source-grounded options. Tied closely to Decision 5 (lifecycle): if (B) or (C) is chosen, the overflow question dissolves into the lifecycle mechanism; if (A) is chosen, the partition is fixed and the overflow path is structural.

##### Decision 5 — Path A partition lifecycle when per-key `min`/`max` is discovered online — **LOCKED (2026-05-19)**

**Locked (2026-05-19)**: ltl adopts the **HdrHistogram-style per-key auto-resize** lifecycle (option B from the trade-off analysis below). Each `(category, log_key)` partition is constructed lazily on first observation, sized at the locked default span centered on the first value, and extended via HdrHistogram-convention doubling when subsequent values fall outside the current `[min, max]`. No precedent run, no #179 index dependency for Path A partition sizing, no end-of-parse retention of raw values. Full lock recorded in *Locked decisions from research* § Decision 5 below — that entry is authoritative.

The remainder of this subsection records the source-grounded analysis the lock was derived from.

Heatmap and histogram finalize their partitions *after* the parse (`calculate_histogram_buckets` at `ltl:4908`), using global `min`/`max`. For Path A's per-`(category, log_key)` partitions, the partition must be sized from per-key `min`/`max` — which are tracked online (`ltl:5369-5371`) but only complete at end of parse.

The consulted sources **converge on online adaptation, not two-pass**. Grounding extracted from `features/187-histogram-industry-grounding.md` § Decision 5:

| Source | Mechanism | Citation |
|---|---|---|
| **HdrHistogram** | `autoResize` (opt-in): on out-of-range record, `handleRecordException` calls `resize(value)` and grows the bucket array in place. Existing counts retain their indices (the bucketing function is index-monotonic — extension only adds bins at the high end). | `AbstractHistogram.java` auto-resize path |
| **OpenTelemetry exponential histogram** | Scale downshift via "perfect subsetting": two adjacent buckets at Scale `s` merge into one bucket at Scale `s−1`. When range grows beyond bucket-index bounds, the producer downshifts Scale (rebin in place by pairwise merging) without loss beyond what Scale-`s−1` already implies. | OTEL data-model spec ("perfect subsetting" section) |
| **OTEP 149** prose on the trade-off | "facing the choice between reduced histogram resolution and blowing up application memory, shrinking is the obvious choice." | OTEP 149 |
| **DDSketch** | Unbounded store grows the bin array as needed (one bin per observed index). Collapsing store has a fixed max bin count; on overflow it discards from one end (`CollapsingLowestDenseStore` discards low-indexed bins). Adapts online; no two-pass requirement. | sketches-java `DDSketch.java`, collapsing-store classes |
| **Prometheus classic** | Fixed bucket boundaries declared at metric creation; **no online adaptation** — applies to pre-defined bucket layouts only. | PromQL practices doc |
| **Prometheus native** | Inherits OTEL-style exponential structure + Scale-downshift pattern. | PromQL native-histogram docs |

**None of the consulted sources documents two-pass (parse twice — first for range, then for counters) as the default field convention.** The shared field philosophy: amortize a one-time rebin cost (extend / downshift-merge / collapse) rather than parse the data twice. Two-pass is achievable in user code but is not how the libraries are structured.

**Source-grounded options for ltl Path A**:

| Option | Source | Behavior for ltl per-`(category, log_key)` partitions |
|---|---|---|
| **(A) Auto-extend in place** | HdrHistogram `autoResize` | First value for a key seeds the partition; subsequent out-of-range values extend the partition's `max`. Existing counts unchanged because the bucketing function is index-monotonic in the extension direction. Memory: per-key bin count grows; bounded by the per-key value range. |
| **(B) Scale downshift / pairwise merge** | OTEL exponential, OTEP 149 | First value seeds at the highest Scale fitting some default range; when range exceeds current Scale's index budget, downshift Scale (merge adjacent bins pairwise). Resolution halves per doubling event but no data loss in counts. |
| **(C) Bounded store with collapse** | DDSketch collapsing variants | Per-key partition has a fixed bin-count budget; on growth that exceeds the budget, collapse bins from one end. Memory cost is hard-bounded; resolution at the collapsed end is lost. |
| **(D) Unbounded growth** | DDSketch unbounded variant | Per-key partition has no bin-count cap; bins added as needed. Memory unbounded in worst case. |
| **(E) Fixed global partition over all keys** | None (ltl's heatmap/histogram already does this at *global* metric scope, not at per-key scope; no source consulted addresses the per-key fan-out scenario directly) | All keys share one log-spaced partition over a single global range. Sparse keys have many empty bins. The grounding doc records this as gap 8: "No source explicitly addresses ltl's case of per-key, per-time-bucket online partition discovery with very small per-key N." |

**Two-pass option** — the prior provisional D3 listed two-pass as option (a). The grounding doc states explicitly: "None of the fetched sources documents a two-pass... lifecycle as their default. Two-pass is achievable but is not the field convention." Two-pass remains technically available to ltl but is a divergence from industry practice and would need rationale.

**Gap recorded**: the per-`(category, log_key)` fan-out scenario (many keys × small per-key N) is not directly mirrored in the consulted literature — each library handles either single large-N streams (HdrHistogram, DDSketch) or pre-defined bucket layouts (Prometheus classic). Whether the libraries' single-stream lifecycle conventions transfer to ltl's per-key fan-out is an open question for the decision conversation.

**D4-trigger**: candidate. Memory cost per per-key partition under options (A), (B), (C), (E) varies sharply with the per-key value range distribution in real logs. If the decision conversation chooses between these based on suspected memory waste, prototype on the D2 heavy-tailed access logs (where per-key value ranges naturally cluster but the global range spans multiple decades) to measure actual memory cost per option.

##### Decision 6 — Runtime gating of approximate vs. exact mode — **DISSOLVED (2026-05-19): no runtime gate in the unified contract**

**Dissolved (2026-05-19)**: The original framing — "when does approximate mode fire vs. exact mode at runtime?" — was a runtime-gate question that has dissolved under the locked decisions. Decision 5 locked auto-resize per partition (no upfront `[min, max]` needed); R13a defined exact mode as a phase-validation regression fallback rather than a runtime gate; Decision 1 locked the Prometheus formula which computes for any positive bin_count. There is no runtime scenario in the unified contract where the system needs to decide between an "approximate path" and an "exact path." Each consumer migrates onto the unified contract through its R9 phase; once the migration is validated, that consumer runs the unified path unconditionally. Full lock recorded in *Locked decisions from research* § Decision 6 below — that entry is authoritative.

The remainder of this subsection records the source-grounded analysis the prior framing was derived from, for the record.

The original framing presumed a dual-mode gate (R2) with concrete thresholds. The grounding pass found the literature is **silent on a numeric gating threshold** between exact (retain-raw) and approximate (histogram/sketch) modes. Per `features/187-histogram-industry-grounding.md` § Decision 6:

- **HdrHistogram README** describes the data structure's purpose ("memory footprint is fixed regardless of the number of data value samples recorded") as a statement of when the data structure is *useful*, not a small-N threshold. Accuracy contract is structural; does not weaken at small N.
- **Prometheus practices doc** advises mechanism-vs-mechanism choices (summaries vs. histograms based on aggregation needs), not exact-vs-approximate. No small-N rule.
- **DDSketch README** states the relative-error guarantee α holds for any non-empty sketch. No small-N threshold.
- **DataSketches KLL** rank-error contract is uniform across the rank space at the parameter K. No small-N threshold.
- **Gil Tene's coordinated-omission post and "How NOT to Measure Latency"** deck (in the content fetched) do not prescribe a minimum-N threshold below which percentile reporting becomes meaningless.

**The libraries position their structures as universally applicable once the user has decided to use them. The decision of *when* to switch is implicitly an engineering / memory-budget call left to the user.** This is exactly the gap ltl's R2.3 needs to fill — and the literature does not supply a value.

**Source-grounded gate components** (the ones the libraries *do* reflect indirectly):

| Component | Source posture | ltl mapping |
|---|---|---|
| **Structural failure guards** (no index, no `+Inf` bucket, zero observations) | Prometheus `bucketQuantile` returns NaN for these | R2.1 (no index) and R2.2 (tier mismatch) inherited from #179 |
| **User choice of data structure** | All libraries treat this as an engineering/configuration choice, not an automatic gate | Practical decision item 7: user-facing `--exact-percentiles` / `--approximate-percentiles` flag |
| **Numeric N threshold** | No source consulted defines one | **Gap. Any value ltl picks for "small-N opt-out per key" is ltl-specific and must be justified in ltl-specific terms.** |

**ltl-specific framing** (not source-grounded, but mechanically derivable from ltl's substrate; flagged as ltl-divergence-from-industry-silence rather than source-grounded option):

- **CPU cross-over point**: at bin count B, counter-store walk costs O(B), sorted-array index costs O(N log N). The two are equal at N ≈ B / log B ≈ B / 4 for B in the 50–600 range. For `buckets_per_decade=16` → B=80 → cross-over at N ≈ 20. For `buckets_per_decade=53` → B=265 → cross-over at N ≈ 65. This is a mechanical calculation, not industry guidance.
- **Memory cross-over point**: counter store = `B · 8 bytes` independent of N; raw array = `N · 8 bytes`. They are equal at N = B.

Whichever framing ltl picks, the decision conversation must record that the value is *not* sourced from industry practice. The conduct rules require this divergence be documented.

**D4-trigger**: candidate. Whether to gate by CPU cross-over (~B/log B), memory cross-over (~B), or some other criterion can be measured by prototyping against D2 datasets. Required only if the decision conversation cannot resolve from mechanical reasoning + library convention (user-choice) alone.

#### D3 memo — additional decisions surfaced for the conversation

Beyond the six analytical decisions above, the decision conversation must resolve four practical questions before Phase 2 implementation begins. The literature consulted in `features/187-histogram-industry-grounding.md` does not document conventions for any of these (the libraries leave configuration, observability format, activation policy, and prototyping triggers to the consumer); they are recorded here as ltl-specific decisions, distinct from the analytical decisions 1–6 above.

7. **User-facing opt-out from the unified path** — **LOCKED (2026-05-19)**: visible `--exact-percentiles` flag with deprecation notice on every invocation, global scope, available one release cycle past each consumer's R9 migration. `-V` reports both a top-level banner and the per-consumer `user_opt_out` line per R10. Full lock recorded in *Locked decisions from research* § Decision 7 below.
8. **`-V` reporting verbosity and format** — **LOCKED (2026-05-19)**: `=== BIN-COUNTER MODE ===` section with run-level header + per-consumer blocks, mirroring the existing `=== INDEX READ-BACK ===` block convention in ltl. Consumer names lowercase-with-underscores; `out_of_range_bounded:` reported inline per-quantile (Option A). Full lock recorded in *Locked decisions from research* § Decision 8 below.
9. **Phase 2 default activation policy** — **DISSOLVED (2026-05-19)**: this question is out of scope for #187, which is a research-and-architecture-foundation deliverable. Activation policy, shipping cadence, default-on-vs-default-off, and per-release ramp decisions belong to the per-consumer implementation tickets that consume this contract, not to #187. Full dissolution rationale recorded in *Locked decisions from research* § Decision 9 below.
10. **Prototype validation scope — what #189 must validate before production code** — **LOCKED (2026-05-19)**: #187 specifies the aspects of the locked architecture that must be validated empirically through prototyping before #189 begins production implementation. Five aspects are in scope: (a) the in-bin interpolation formula's behavior on real data; (b) the auto-resize partition lifecycle's behavior on per-key fan-out at scale; (c) the initial partition seeding heuristic and overflow/underflow handling on edge-case data; (d) an end-to-end verbose output sample for downstream comparison; (e) calculation accuracy compared to the array-of-values approach currently in use. The prototype is a hard prerequisite for #189's production code; #189 owns where the prototype lives and how it's structured. Full lock recorded in *Locked decisions from research* § Decision 10 below.

#### D3 memo — what D3 does *not* do

This memo is decision-support, not decision. It does not:

- Lock the in-bin interpolation strategy.
- Lock `buckets_per_decade` for Path A.
- Lock the gating thresholds.
- Commit to D4 work.

All of those are decided in the conversation that consumes this memo. The memo's job is to make that conversation possible without the participants having to re-derive D1's analysis.

### D4 — Prototype (conditional)

D4 is **conditional**. It is produced only if a D3 decision (Decision 1, 2, or 5 per the memo) cannot be resolved from D1's analysis alone and the decision conversation flags it as needing measurement. The scope of D4 is bounded by the specific decision being measured — it is not a flat "exercise the substrate" prototype.

When D4 is triggered, it produces a working prototype in `prototype/187-percentile-binderived.pl` (or similar) that:

- Implements the bin-counter primitive plus the in-bin interpolation strategies under question.
- Runs against the D2 cross-referenced log files relevant to the open decision.
- Produces measurement output (per-quantile error against exact-mode reference, state size, CPU cost) appropriate to the decision being resolved.
- Is runnable independently of ltl proper so the primitive can be exercised without touching production code.
- Mocks `#189` R1–R4 sufficiently to exercise the decision under question.

D4's output feeds back into D3, which is updated to reflect the resolved decision. The user-and-Claude decision conversation then proceeds against the updated D3.

If D3's analysis resolves all decisions from literature alone, D4 is not produced and Phase 1 concludes at D3.

### D5 — Production gate

Production implementation of any consumer migration (R9 Phase 2 onward) references the locked decisions in *Locked decisions from research* as the authoritative contract. D1, D2, D3 are the research-phase deliverables that produced those locks; D4 is conditional per its clause above. Each consumer's migration phase invokes the validation harness in the **Validation** section against the consumer's pre-migration output for the baseline regression, per R11.

## Related issues

- **#34** — histogram bin-counter accumulation (sibling; provides the counter data structure for bin-derived interpolation; consumer of #189).
- **#179** — index read-back (scope substantially reshaped by Decision 5 / Decision 6 dissolution; see *Downstream implications for related issues*).
- **#189** — unified histogram bin-counter primitives (provides the helper-function contract; R8 and R12 depend on it).
- **#51** — highlight-data accumulation (Phase 4 coordination).
- **#41** — unified binning (D1 evaluates bin-derived interpolation, which composes with #41 if it lands).
- **#23 Phase 2 (#59)** — adopts this feature's memory model.
- **#180** — named pipeline stages.
- **#46** — index file (closed; foundation that #179 reads back).

## Locked decisions from research

This section records the binding values produced by the decision conversation that consumes D3. Each entry is a single decision, locked, with one-line rationale and at least one source citation per the conduct rules above. Phase 2 implementation references this section as authoritative.

> **Status as of 2026-05-19.** The prior three "locked" decisions (linear-in-log rank-in-bin interpolation with T=5 fall-through; `buckets_per_decade = 16`; per-bin fall-through warning vocabulary) were reverted on the grounding pass because none of them was source-grounded — see `features/187-histogram-industry-grounding.md` for details. Subsequent decision-conversation work has settled the **design-philosophy framing** that anchors Decisions 1 and 2 (see D3 § "Design philosophy framing — the analyst's lever"). The framing is recorded as locked below. Numeric defaults, CLI flag names, and the remaining open decisions are still **OPEN** pending the decision conversation against the grounded options in D3.

### F1 — Design-philosophy framing — **LOCKED (2026-05-19)**

#### Contract

ltl occupies the **query-time analyzer** role, not the recording-side library role. The raw values live in the log file and are read by ltl at analysis time, which means the precision parameter is a query-time choice exposed to the analyst, not a fixed recording-time choice the way Prometheus Scale, DDSketch α, and HdrHistogram significant-digits typically are in their production deployments. `buckets_per_decade` is the analyst's lever; the in-bin rule uses `rank_in_bin` because that information is available to ltl in a way it is not to consumers of pre-aggregated metrics.

**Source basis**: derived from the cross-library divergence captured in `features/187-histogram-industry-grounding.md` (Decisions 1 and 2): production bin-based libraries split into two camps on in-bin rule and span an order of magnitude on precision-default worked examples — the right anchor for ltl is the use-case role, not any single library's recording convention.

**Implications**:
- Decision 1 adopts the Prometheus-native-exponential convention (log-scale-aware rank-in-bin interpolation).
- Decision 1A is settled: ltl uses `rank_in_bin`.
- Decision 2's framing: `buckets_per_decade` is a user-tunable CLI lever, not a system constant.

#### Implementation guidance for #189

None at the framing level. F1 is purely contract; the implementation consequences flow through Decisions 1, 2, etc.

### Decision 1 — In-bin interpolation strategy for #189 R4 — **LOCKED (2026-05-19)**

#### Contract

R4 uses the **Prometheus native-exponential `HistogramQuantile` in-bucket interpolation formula**. Given a partition, a counter map, and a target quantile `q`, R4:

1. Computes `total_N` = sum of counter map (including the overflow and underflow counters per Decision 4).
2. Computes `target_rank = ceil(q · total_N)`.
3. Walks the counter map (low to high) to locate the bin `bin_i` containing `target_rank`.
4. If `target_rank` lies in the overflow counter, returns `partition.boundary[B]` (Decision 4). If it lies in the underflow counter, returns `partition.boundary[0]` (Decision 4).
5. Otherwise computes `rank_in_bin = target_rank − (cumulative count up to but not including bin_i)` and `fraction = rank_in_bin / counter_map[bin_i]`, then returns the in-bin interpolated value via the Prometheus formula:

```
returned_value = exp( log(lower) + (log(upper) − log(lower)) · fraction )
```

where `lower = partition.boundary[bin_i]` and `upper = partition.boundary[bin_i + 1]`. The formula is mathematically equivalent to `lower · (upper / lower) ^ fraction`. Either form is contract-conformant.

**Source citation**: Prometheus `promql/quantile.go`, function `HistogramQuantile`, lines 331–353 (commit `main` HEAD as of 2026-05-19): https://github.com/prometheus/prometheus/blob/main/promql/quantile.go. Verbatim source quoted in D3 § Decision 1 above.

**Rationale**: locked-by-implication of F1 (analyst's-lever framing — ltl occupies the query-time analyzer role) and verified against Prometheus's source code. Prometheus's own comment in the source establishes the same geometric rationale that anchors F1: "On a logarithmic scale, the exponential bucket boundaries (for any schema) become linear (every bucket has the same width). Therefore... we can use the calculated fraction in the same way as for linear interpolation." The log-spaced refinement matches ltl's log-spaced substrate (`ltl:4961-4966`).

**Special cases from Prometheus source that do not apply to ltl** (recorded so any future port of these special cases is explicit):
- ltl substrate is positive-only duration data; no negative-bucket mirroring is needed.
- ltl substrate is purely log-spaced; the custom-bucket / zero-spanning-bucket linear-interpolation fallback in `promql/quantile.go` line 336–338 does not apply.

#### Decision 1A — Use of `rank_in_bin` — also locked under this entry

R4 uses `rank_in_bin` as the `fraction` parameter. Aligns with Prometheus and New Relic NrSketch; diverges from HdrHistogram and DDSketch (which is the recording-side library posture, not ltl's analyst-tool role).

#### Implementation guidance for #189

Non-binding guidance for #189's implementation — the contract above is what must hold; the specifics below are starting points #189 may refine within the contract.

- **Log base**: Prometheus's source uses `math.Log2` and `math.Exp2`. ltl should match Prometheus's `log2 / exp2` convention for exact floating-point reproducibility against Prometheus reference output if a regression test is set up against Prometheus's output; otherwise natural log (`log` / `exp`) is mathematically equivalent and Perl-idiomatic. #189 picks based on its testing strategy.
- **Edge case `bin_count = 1`**: `fraction = 1.0`; formula returns `upper`. No special-case logic needed.
- **Edge case `lower = upper`** (degenerate single-value partition): formula returns `lower`. No special-case logic needed.
- **Numerical robustness**: for ltl's value range (microseconds to hours), the log and exp evaluations are well within IEEE 754 double precision. No guards needed against overflow or denormal underflow.

### Decision 2 — `buckets_per_decade`, default value, CLI flags, valid range — **LOCKED (2026-05-19)**

#### Contract

`buckets_per_decade` is the analyst's lever (per F1). The lever is exposed via two CLI flags — a numeric lever for development/testing/research, and a tiered lever for user-friendly day-to-day analyst use.

**Default value**: `buckets_per_decade = 53` (OTEP-149 Scale-4 analog; ~1.1% midpoint error; ~2.2% bin width).

**Source citation**: OTEP 149 prose — "the most interesting range of baseScale is around -4", which in OTEL Scale convention corresponds to Scale 4, 16 bins per doubling, 16 · log₂(10) ≈ 53 bins per decade. Note: OTEP is proposal text, not adopted OTEL spec (see D3 § Decision 1 caveat); the 53 value is grounded in the OTEP's "most interesting range" prose as the SRE-grade analog within the source-grounded option set.

**Rationale**: derived from F1 (analyst's-lever framing) and the source-grounded options in D3 § Decision 2. At ~1.1% midpoint error, distinguishes a 5% real regression from bin noise — the SRE-grade single-point-reporting and run-to-run regression-detection sweet spot. Below OTEP-149 the bin-resolution error is coarse for that use; above OTEP-149 the memory cost grows substantially without proportionate analyst benefit in typical interactive triage. The two-level CLI lever exposes those higher-precision regimes for analysts who want them.

**CLI flag surface (contract)**:

1. **Numeric lever** (development/testing/research):
   - Long form: `--percentile-buckets-per-decade N`
   - Short form: `-pbpd N`
   - Valid range: **4 ≤ N ≤ 616**. Lower bound prevents degenerate accuracy (~28% bin width). Upper bound covers the HdrHistogram 3-sig-digit precision-research regime.
   - Default: 53.

2. **Tiered lever** (user-friendly day-to-day analyst use):
   - Long form: `--percentile-precision LEVEL`
   - Short form: `-pp LEVEL` (added 2026-05-19 per project requirement that every CLI option exposes both short and long forms; supersedes the prior "no short form" lock).
   - Valid range: **1 ≤ LEVEL ≤ 9**.
   - Default: LEVEL 5 (maps to bpd = 53).
   - Internally maps to `buckets_per_decade` per the locked table below.

**Locked LEVEL → `buckets_per_decade` mapping**:

| LEVEL | `buckets_per_decade` | Midpoint error | Anchoring |
|---|---|---|---|
| 1 | 4 | ~14% | Lower bound — degenerate-accuracy floor |
| 2 | 8 | ~7% | ltl heatmap/histogram precedent (`ltl:286`) |
| 3 | 16 | ~3.5% | Light SRE-screening regime |
| 4 | 32 | ~1.8% | Mid SRE regime |
| 5 | **53** | **~1.1%** | **DEFAULT** — OTEP-149 Scale-4 analog |
| 6 | 80 | ~0.7% | Above OTEP-149, below DDSketch |
| 7 | 115 | ~0.5% | DDSketch sketches-java README quick-start (α=0.01) |
| 8 | 256 | ~0.2% | Approaching HdrHistogram 3-sig-digit |
| 9 | 616 | ~0.08% | HdrHistogram 3-sig-digit "response time tracking" example; top of valid range |

The mapping is part of the locked feature contract; changes to the table require a new locked-decision entry.

**Flag interaction contract**:

- Both flags may appear on the command line without error.
- `-pbpd` always wins when both are specified (regardless of argument order). `--percentile-precision` is silently overridden.
- `-V` must report the resolved `buckets_per_decade` value with its source (default / which flag specified). Exact field naming is practical decision 8.

**Source citations**:
- Upper-bound value (616): HdrHistogram README (https://github.com/HdrHistogram/HdrHistogram/blob/master/README.md), 3-significant-digit "response time tracking" example.
- Mapping anchors at levels 7 (~115) and 9 (~616): DDSketch sketches-java README (https://github.com/DataDog/sketches-java/blob/master/README.md) and HdrHistogram README, respectively.
- Mapping anchors at levels 2 (8) and 5 (53): ltl precedent (`ltl:286`) and OTEP 149, respectively.
- F1 framing: this feature file § "Design philosophy framing — the analyst's lever".

#### Implementation guidance for #189

Non-binding guidance — the contract above is what must hold; the specifics below are starting points #189 may refine.

- **Memory footprint at locked default**: 265 bins per partition over 5 decades; ~2.1 KB per partition at 8 B/counter; ~212 MB total across 10⁵ keys (Path A scale). **Measured overhead** (prototype evidence, PR #194; `prototype/189-bin-counter-primitives-validation-report.md` § V2 Part A): on real Tomcat data at 51,469 partitions, actual per-partition cost under Perl is 2,381 B (vs. the theoretical 2,136 B floor), and projected total at 10⁵ partitions is 227 MB (+12.3% over the 212 MB guidance). The delta is Perl hash-and-scalar overhead vs. the theoretical `(B+2) × 8` byte counter array; the closed-form R2 path assumption holds. Analysts comparing observed `counter_memory_bytes` in `-V` output against this guidance should expect the small positive offset.
- **Memory at other levels** (informational, for sizing tests):
  - L1 (bpd=4): 160 B/partition; ~16 MB at 10⁵ keys.
  - L2 (bpd=8): 320 B/partition; ~32 MB.
  - L3 (bpd=16): 640 B/partition; ~64 MB.
  - L4 (bpd=32): 1.3 KB/partition; ~128 MB.
  - L5 (bpd=53, default): 2.1 KB/partition; ~212 MB.
  - L6 (bpd=80): 3.2 KB/partition; ~320 MB.
  - L7 (bpd=115): 4.6 KB/partition; ~460 MB.
  - L8 (bpd=256): 10 KB/partition; ~1.0 GB.
  - L9 (bpd=616): 25 KB/partition; ~2.5 GB.
  At higher levels memory becomes a binding constraint at large key counts; the user picks consciously.
- **`-V` field naming** (suggestion, settled by practical decision 8):
  - `buckets_per_decade: 53 (default)` — neither flag specified.
  - `buckets_per_decade: 32 (--percentile-precision 4)` — only `--percentile-precision` specified.
  - `buckets_per_decade: 100 (-pbpd 100)` — only `-pbpd` specified.
  - `buckets_per_decade: 100 (-pbpd 100; --percentile-precision 4 overridden)` — both specified; `-pbpd` wins.
- **Out-of-range CLI input** (`--percentile-precision 0` or `10`, `-pbpd 2` or `1000`): error consistent with ltl's existing CLI input validation. Per CLAUDE.md, validation messages must be informative.
- **CLI documentation requirements** (CLAUDE.md):
  - `print_help()` in `ltl` — both flags documented with the LEVEL → bpd mapping shown for `--percentile-precision`.
  - `README.md` options reference — both flags listed in the precision-control family (alongside `-hgbpd`).
  - `docs/usage.md` — analyst-facing explanation of when to use each flag.

### Decision 4 — Out-of-range tally handling — **LOCKED (2026-05-19)**

#### Contract

ltl adopts the Prometheus `histogram_quantile()` `+Inf` overflow convention verbatim for the high end, with a symmetric `-Inf`-equivalent underflow convention for the low end. R4's behavior in the cumulative walk:

**High-end overflow** (values strictly greater than `partition.max`):
- A separate overflow counter (the `+Inf`-equivalent) tallies these values. Structurally distinct from the highest finite bin — not folded into `boundary[B]`.
- Overflow counts contribute to `total_N` for rank computation.
- When `target_rank` lies in the overflow counter, R4 returns `partition.boundary[B]`. No interpolation inside overflow. Semantic: "this quantile is at least this large; the bin-counter approach cannot say more."

**Low-end underflow** (values where `0 < value < partition.min`):
- A separate underflow counter (the `-Inf`-equivalent) tallies these values. Structurally distinct from the lowest finite bin.
- Underflow counts contribute to `total_N`.
- When `target_rank` lies in the underflow counter, R4 returns `partition.boundary[0]`. No interpolation inside underflow. Semantic: "this quantile is at most this small; the bin-counter approach cannot say more."

**Audit signal**: `-V` Layer 2 must surface, per quantile, whether the returned value came from interpolation or from an overflow/underflow boundary. The field name is `out_of_range_bounded` with three-value enum:

- `high`: target rank landed in the overflow counter; R4 returned `partition.boundary[B]`.
- `low`: target rank landed in the underflow counter; R4 returned `partition.boundary[0]`.
- `none`: target rank landed in a finite bin; R4 interpolated via Decision 1's formula.

A single run's `-V` output may show different `out_of_range_bounded` values for different quantiles (e.g., P50 `none`, P99.9 `high`). The field name and the three-value enum are part of the locked feature contract.

**Source citations**:
- Prometheus `promql/quantile.go` — `BucketQuantile` function (classic histograms with `+Inf` bucket), lines 130–152 of commit `main` HEAD as of 2026-05-19. URL: https://github.com/prometheus/prometheus/blob/main/promql/quantile.go. Key lines verified verbatim:
  - Line 130–133: `+Inf` bucket is structurally required; absence returns `NaN`.
  - Line 144: `observations := buckets[len(buckets)-1].Count` — overflow contributes to total N.
  - Line 152: `case b == len(buckets)-1: quantile = buckets[len(buckets)-2].UpperBound` — return upper bound of last finite bucket when target rank lands in overflow.
- PromQL `histogram_quantile()` docs — published statement: "If a quantile is located in the highest bucket, the upper bound of the second highest bucket is returned." URL: https://prometheus.io/docs/prometheus/latest/querying/functions/#histogram_quantile.
- OpenMetrics specification — `+Inf` bucket requirement: "Histogram MetricPoints MUST have one bucket with an `+Inf` threshold." URL: https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md.

**Divergence from Prometheus, documented**: ltl's `-Inf`-equivalent underflow handling has no direct Prometheus analog (Prometheus's negative-bucket handling is for distributions with genuinely negative values, not for positive-values-below-min). The ltl underflow convention is a symmetric extension of the Prometheus `+Inf` convention applied at the low end. Rationale: positive durations may be smaller than the partition's `min` early in the parse, before auto-resize (Decision 5) has had the chance to extend the low end. Conduct rule satisfied: where ltl's case differs from the industry-standard case, the divergence is documented explicitly.

**Tied to Decision 5**: under Decision 5's locked auto-resize lifecycle, overflow and underflow are expected to be rare in practice — the partition adapts to contain observed values. Decision 4's mechanisms function primarily as a safety net rather than the primary handling path. The contract still holds; the practical hit rate is small.

**#34 contract surface**: `#34` R5/R6 already requires tracking values above and below the partition. Decision 4 consumes `#34` R5/R6 as-is — no new contract obligations on `#34`'s data structure. The primitive interface between #189 R4 and the counter store must expose the overflow/underflow counts; that interface design is `#189`'s concern.

#### Implementation guidance for #189

Non-binding — the contract above is what must hold.

- **Data-structure layout**: two extra counter slots per partition (one underflow, one overflow), parallel to the in-range bin counters. Conceptually a partition has `B + 2` counters: `underflow`, `boundary[0..B−1]`, `overflow`.
- **Cumulative walk implementation**: the walk visits underflow first (if non-zero), then `boundary[0]` through `boundary[B−1]`, then overflow. When the running cumulative count exceeds `target_rank`, the active position is the bin to use. If the active position is `underflow` or `overflow`, R4 returns the corresponding boundary without entering Decision 1's interpolation formula.
- **`total_N` computation**: `underflow + sum(boundary counters) + overflow`. Cached on every counter-update to avoid repeated summation at R4 invocation time, or recomputed on demand — implementer's choice.
- **Auditability**: when R4 returns a boundary value due to overflow or underflow, the consumer (or R4 itself) must record this for the `-V` audit field. Implementation may pass back a `(value, bounded_flag)` tuple from R4 or have R4 set a per-quantile result field — implementer's choice.
- **No special handling for `total_N = 0`** at R4 invocation (R5 edge case `zero matched values` prevents this from being reached).

### Decision 5 — Partition lifecycle (per consumer family) — **LOCKED (2026-05-19); per-family scope clarified 2026-05-20 via #201**

#### Scope clarification (added 2026-05-20)

When Decision 5 was first locked (2026-05-19), the "every consumer of the unified primitive contract" phrasing reflected the framing then in scope: per-key fan-out percentile calculation. The keying enumeration immediately after (per-`(category, log_key)`, per-`time_bucket`, per-metric global) presupposed different consumer needs without writing them down.

Investigation #201 surfaced that display-geometry-bound consumers (heatmap, histogram) have lifecycle needs the original Decision 5 framing did not address. Per-consumer differentiation was always intended; this scope clarification writes it down. Decision 5's contract for **per-key fan-out, precision-bound consumers** (F1 in the #201 taxonomy) is unchanged. Display-geometry-bound consumers (F2 heatmap, F3 histogram) follow the streaming + finalize-rebin lifecycle locked in #201 § Recommendation, which composes the same #189 primitives with a finalize-time re-bin step.

See `features/201-display-geometry-bound-consumers.md` for the full investigation, fidelity bounds, and prototype evidence.

#### Contract — F1 (per-key fan-out, precision-bound)

Applies to: `summary_table`, `csv_output`, `time_bucket_stats`, and any future per-key fan-out percentile consumer whose bins serve as internal precision (never rendered directly).

ltl adopts **HdrHistogram-style auto-resize as the partition lifecycle** for F1 consumers of the unified primitive contract. Each partition (per-`(category, log_key)` for the summary table and CSV output; per-`time_bucket` for time-bucket statistics; whatever keying future F1 consumers introduce):

- Is constructed lazily on first observation for that key.
- Has its initial `[min, max]` range derived from the first value, sized at the locked default span (ltl's existing 5-decade convention per `ltl:4908`-area code), centered geometrically on the first value.
- Is extended via HdrHistogram-convention doubling when a subsequent value falls outside the current `[min, max]`.
- Preserves existing bin counts across rebin events (the boundary geometry is index-monotonic in the extension direction; rebin appends bins at the affected end with zero counts).
- Has amortized O(N) total rebin cost across all values (HdrHistogram's amortized guarantee).

The lock applies uniformly across F1 consumers catalogued in R12. F2 (heatmap) and F3 (histogram) follow the streaming + finalize-rebin lifecycle below.

#### Contract — F2/F3 (display-geometry-bound consumers) — added 2026-05-20 via #201

Applies to: `heatmap_cells`, `heatmap_markers` (F2, per-`time_bucket` keying); `histogram_view`, `histogram_bins` (F3, per-metric global keying).

ltl adopts a **two-stage stream → finalize-rebin lifecycle** for display-geometry-bound consumers. Each partition:

- Is constructed lazily on first observation per the same #189 primitive surface (`partition_new` with locked defaults `bpd=53`, `seed_decades=5`) — streaming phase.
- Accumulates counts via `counter_update` with auto-resize during the parse — bounded memory throughout, no raw-value retention.
- At end-of-parse, is **re-binned into a display-bound partition** via geometric-midpoint projection (the same remap loop used by `partition_extend`). The display-bound partition has:
  - `bin_count = display_width` (for F2: `$heatmap_width`; for F3: `$bar_area_width`, knowable at end-of-parse after active-metric count `n` is determined).
  - Boundaries log-spaced over `[d_min, d_max]` (observed data extents — the same anchor ltl's pre-migration code uses).
- Display reads the finalized partition directly — no projection step at render time. (For F3, an optional bar-widening render step preserving the shipped "wide bars" visual is a follow-on UX decision in the histogram migration ticket; see `features/201-*.md` § Open question.)

The streaming partition is discarded after re-bin; only the finalized partition is retained for display.

**Why this lifecycle (not F1's auto-resize at display time):**
1. Display column count is a hard constraint (`$heatmap_width = -hmw`; `$bar_area_width` derived from terminal width and active-metric count). Auto-resize cannot guarantee partition geometry matches display geometry at the moment display happens.
2. The Phase 3 investigation (`features/201-*.md` § Phase 3 evidence catalogue) empirically demonstrated that render-time projection from an auto-resize partition to a display grid introduces fidelity loss bounded by the partition-vs-display range mismatch (Dimension B in #201's framing). The finalize re-bin avoids that mismatch by reconstructing the partition with display-anchored boundaries.
3. F2 (heatmap) has no projection step in shipped code (partition geometry IS display geometry). The finalize re-bin preserves this invariant by reconstructing a display-geometry partition before render. F1's auto-resize at display time would *introduce* a projection step, breaking the F2 invariant.
4. F3 (histogram) Dimension C ($bar_area_width unknown until end-of-parse) is resolved structurally — the finalize step has all inputs available at the moment it runs.

**Why the same #189 primitives:**
The geometric-midpoint re-bin already exists at `ltl:613–622` (`partition_extend`'s remap loop). F2/F3 finalize re-bin reuses it via a new wrapper (`partition_rebin($src_partition, $src_bins, $new_min, $new_max, $new_bin_count)`) — see `features/189-histogram-bin-counter-primitives.md`. F1's auto-resize lifecycle is unchanged; the new wrapper composes existing pieces.

**Empirical validation:** Prototype V6 (heatmap) and V7 (histogram) on the canonical 148 MB Tomcat dataset showed 100% mass retention, 100% peak retention, and 0-column peak X-offset. Algebraic worst-case X-offset bound at locked defaults is ≤1 column. Full evidence at `prototype/201-projection-comparison-report.md`.

**Source of the F2/F3 contract**: `features/201-display-geometry-bound-consumers.md` § Recommendation, locked 2026-05-20.

#### F1 contract continued — Why this lifecycle (not fixed global partition)

**Why this lifecycle (not fixed global partition)**:

1. **No precedent run or #179 index dependency.** Fixed-global-partition requires the global `[min, max]` upfront — either from #179's pre-seeded index (requires a prior run) or from end-of-parse retention of raw values (defeats #187's memory motivation) or from hardcoded conservative defaults (forces Decision 4 overflow/underflow to be the primary path). Auto-resize avoids all three: a fresh `ltl` invocation on months of historical data gets percentiles, heatmap, and histogram on the *first* run, in a single pass, in memory-safe form.

2. **Tighter per-key resolution.** Each per-key partition adapts to the values that key actually has, so its full bin budget (~265 bins at locked 53 bpd × 5 decades) is applied to the per-key value range rather than to a wider global range with most bins empty for narrow-range keys.

3. **Decision 4 overflow/underflow becomes a safety net rather than the primary path.** With auto-resize, the partition extends to contain observed values, so values landing in overflow/underflow are rare.

**Accepted trade-off**: per-key partition boundaries are *not* aligned with the heatmap/histogram global boundaries. The future hover-to-redraw feature (if built) will need to re-bin per-key counts onto the heatmap/histogram global boundary array at render time — an O(bin count) operation paid per-render, per-API, on user demand. Cross-time-bucket heatmap re-projection (rather than just the histogram) is deferred — first-cut hover targets the histogram only.

**`-V` rebin telemetry — contract surface**: because the initial seed and rebin behavior are conservative engineering choices that may need tuning from real-world telemetry, `-V` must expose rebin telemetry that lets an analyst observe how often partitions rebin, how widely the per-key partition counts spread, and how much total memory the counter store consumes. The telemetry must cover, at minimum:

- Aggregate rebin-event count for the run.
- Per-partition rebin-count distribution (some summary across partitions — a percentile breakdown is suggested).
- The largest partition's bin count (high-water-mark).
- Aggregate counter-store memory footprint (matches R7's `state_budget_bytes`).

The presence and semantic of these telemetry signals is contract; exact field names are practical decision 8.

**The seeding heuristic and doubling-rebin growth strategy are part of the locked contract** as design choices (full-default-span centered on first value; HdrHistogram-convention doubling on rebin). The specific arithmetic implementing them is implementation guidance — see below. **The seed heuristic is revisitable from telemetry**; if real-world data shows the seed is materially too narrow (high rebin rates) or too wide (large memory waste on narrow-range keys), a future locked decision may refine it. The auto-resize lifecycle itself is not revisitable.

**Source citations**:
- HdrHistogram `AbstractHistogram.java` `resize(value)` path, invoked by `handleRecordException` when `autoResize` is enabled. URL: https://github.com/HdrHistogram/HdrHistogram/blob/master/src/main/java/org/HdrHistogram/AbstractHistogram.java. Quoted in `features/187-histogram-industry-grounding.md` § Decision 5.
- OTEL Scale-downshift (alternative not chosen): the OTEL data-model spec's "perfect subsetting" mechanism (Scale-`s-1` is a strict aggregation of Scale-`s`) provides a way to *shrink* resolution under memory pressure. ltl chose extension over downshift because ltl's per-key memory budget is generous (foreground analysis tool) and resolution preservation matters for SRE-grade tail percentiles.
- DDSketch unbounded grow (alternative not chosen): `DDSketch.java` unbounded store grows the bin array as needed. Structurally similar to HdrHistogram auto-resize but DDSketch's collapsing-store variant introduces resolution loss at the collapsed end; ltl preferred HdrHistogram's purer extension semantics.

**Divergence from industry-standard single-stream lifecycle, documented**: per the grounding doc gap 8, no consulted source documents per-`(category, log_key)` fan-out lifecycle. ltl's choice is to apply HdrHistogram's *single-stream* auto-resize convention *per stream* in the fan-out, with each partition managed independently. The single-stream conventions of all consulted libraries assume one large-N partition, not many small-N partitions; ltl's adaptation is structurally novel. Conduct rule satisfied: divergence is explicit.

**Implications for related issues** (catalogued in *Downstream implications for related issues* above):
- #179: index is no longer load-bearing for partition sizing under any consumer.
- Decision 4: overflow/underflow become rare-in-practice safety nets rather than primary paths.
- Future hover-to-redraw: per-key partition boundaries differ from heatmap/histogram global boundaries; re-binning at render time is the design pattern; first-cut targets histogram only.

#### Implementation guidance for #189

Non-binding — the contract above is what must hold; specifics below are starting points #189 may refine.

- **Initial seed arithmetic**: when the first value `v_0` for a new partition is observed, construct the partition with `min = v_0 / sqrt(10^decades_default)` and `max = v_0 · sqrt(10^decades_default)`, where `decades_default = 5` (matches ltl's existing heatmap/histogram convention at `ltl:4908`-area code). For 5 decades and locked Decision 2 default `buckets_per_decade = 53`, the partition opens with ~265 bins, centered geometrically on `v_0`.
- **Rebin doubling arithmetic**: when a value exceeds `max`, extend the high end so that the new `max` is at least `current_max · 10^(decades_default / 2)` (effectively doubling the span at the affected end on a log-scale). Symmetric for values below `min`. Adding bins on the high end is conceptually `append`; on the low end is `prepend`. Both are O(bin count) per rebin.
- **Suggested `-V` field names** (settled finally by practical decision 8):
  - `total_rebin_events: N` — aggregate count, Layer 2.
  - `rebins_per_partition: { p50, p95, p99, max }` — per-partition distribution, available under verbose flag.
  - `max_partition_bins: N` — high-water-mark bin count, Layer 2.
  - `counter_memory_bytes: N` — aggregate counter-store memory, Layer 2 (matches R7's `state_budget_bytes`).
- **Healthy-seed signal**: with the suggested seed (5 decades centered on first value), `rebins_per_partition.p99` should be in the 0–2 range on typical latency data. Higher values suggest tuning the seed wider or the doubling factor more aggressive.
- **Counter storage layout**: a partition can be represented as `{ min, max, bin_count, bin_edges_or_log_offset, counts[B+2] }` where `counts` includes the underflow and overflow slots from Decision 4. Bin edges may be stored explicitly (one array of length B+1) or derived on demand from `min, max, B` using the log-spaced boundary formula (`boundary[i] = min · (max/min)^(i/B)`) — implementer's choice. Storing edges explicitly is faster at the cost of memory; deriving them is the opposite. Likely the right call at default precision is to derive on demand (B is small) but #189 measures.
- **Rebin implementation strategy**: rebin can be done in-place (allocate new larger counts array, copy old counts to their preserved positions, replace the partition's counts pointer) or copy-on-resize. In-place avoids per-rebin allocation churn.
- **Decades-default exposure**: `decades_default = 5` is currently a hardcoded value in `ltl:4908`-area code. The unified contract preserves this. Whether to expose `decades_default` as a CLI knob in the future is out of scope for #187.

### Decision 3 — Per-bin sample-count guard and partition-level rank-support signalling — **LOCKED (2026-05-19)**

#### Contract

1. **No per-bin sample-count guard in R4.** R4 returns Decision 1's formula output regardless of `bin_count` or the position of the target rank within the bin. At `bin_count = 1`, the formula returns the bin's upper edge naturally (`fraction = 1.0`).
2. **No partition-level rank-support signal in `-V`.** R4 returns its computed value whether or not the partition's total count is large enough to meaningfully support the target rank. The contract does not include a `rank_support` audit field.
3. The audit surface for R4-related observability is the locked set from Decisions 4 (`out_of_range_bounded` per quantile) and 5 (per-partition rebin telemetry). No additional R4-related `-V` audit fields beyond those.

**Source basis**: industry convention across all four consulted bin-based libraries (HdrHistogram, Prometheus, OpenTelemetry exponential, DDSketch). None implements a per-bin guard; none surfaces a partition-level rank-support signal. Quoted from `features/187-histogram-industry-grounding.md` § Decision 3:

- HdrHistogram `getValueAtPercentile` does not branch on bin count; returns `highestEquivalentValue(valueAtIndex)` regardless. Source: `AbstractHistogram.java`.
- Prometheus `bucketQuantile` has structural NaN guards (no `+Inf` bucket, fewer than 2 buckets, zero observations) but no per-bin sample-count guard. Source: `promql/quantile.go`.
- OpenTelemetry exponential specification and OTEP 149 do not specify any quantile-estimation guard.
- DDSketch `getValueAtQuantile` returns the per-bin representative `indexMapping.value(bin.getIndex())` unconditionally; relative-error guarantee α holds for any non-empty bin. Source: `DDSketch.java`.
- Apache DataSketches KLL (comparative): rank-error contract uniform across rank space; no per-bin threshold.

**Rationale**: per-bin guard rejected because the original motivation (rank-in-bin meaningless at small counts) was tied to the discarded linear-in-log invented rule. Under the locked Prometheus formula, the `bin_count = 1` case collapses gracefully to "return bin upper edge," itself an industry-standard convention. Partition-level rank-support signal rejected because no consulted source has an analog and ltl's existing exact-mode behavior (`ltl:5519-5525`) is preserved.

**What stays in the contract from prior provisional D3**: nothing. The prior provisional T = 5 fall-through rule and the `tail_sample_count_warning` / `tail_sample_count_starved` per-quantile warnings are not in the unified contract.

**Divergence from existing ltl behavior**: this is consistent with how exact mode behaves today — `calculate_statistics` (`ltl:5488`) does not emit any per-quantile rank-support warning. The locked contract preserves that posture under approximate mode. No new warnings under approximate mode that don't exist under exact mode.

#### Implementation guidance for #189

Non-binding.

- **Observability path for analysts** (informational, not new contract): an analyst who wants to verify rank confidence for a specific quantile reads the `-V` output and uses (a) the partition's bin count from Decision 5's rebin telemetry (`max_partition_bins` aggregate), (b) the `out_of_range_bounded` per-quantile field from Decision 4, and (c) the aggregate `state_budget_bytes`. ltl does not pre-compute trust signals; the analyst inspects the underlying data themselves if they want to verify partition-level rank support.
- **No code surface required by this decision**: R4's implementation does not need special-case branching for small bin_count or small total_N. The Decision 1 formula computes correctly for any positive bin_count; the Decision 4 boundary-return path handles overflow/underflow. No additional code paths.

### Decision 6 — Runtime gating of approximate vs. exact mode — **DISSOLVED (2026-05-19): no runtime gate in the unified contract**

#### Contract (dissolution)

The question was structurally dissolved by the locked Decisions 1, 5, and the reframing recorded in R13a. There is no runtime gate in the unified contract between an "approximate path" and an "exact path" — each consumer runs the unified contract path unconditionally once its R9 phase has validated. Exact mode survives only as a configurable opt-back-out (practical decision 7 territory) and as the per-consumer regression-validation reference during each migration phase. The original R2.3 "input criteria failed" branch is no longer needed.

**Why the dissolution**:

1. **Decision 1 (Prometheus formula)** computes for any positive bin_count. No structural failure mode at small N that would require a runtime fallback.
2. **Decision 5 (auto-resize per partition)** removed the upfront `[min, max]` requirement that the original gate was meant to guard against absence-of. There is no scenario where the partition cannot be sized.
3. **Decision 5 also removed the index dependency** for partition lifecycle. R2.1 (no index) is no longer a runtime gate for the lifecycle; #179's index concerns relate to other features (drift, tier-correctness) that don't gate the unified contract.
4. **R13a defined exact mode as a regression-validation fallback** rather than a runtime mode-switch. Each consumer migration validates byte-identically against the pre-migration exact-mode output; once validated, the consumer runs the unified path. The exact-mode code may be retained per-consumer or retired per-consumer based on whether a continued reason exists (e.g., a user opt-out preference per practical decision 7).
5. **The Prometheus and HdrHistogram libraries do not have runtime gates of this shape.** They are unconditional bin-counter substrates. ltl's unified contract aligns with the library posture rather than maintaining a parallel mode-switching machinery.

**What this means for previously specified requirements:**

- **R2** ("Mode-selection gate") was previously the central runtime gate. Under the dissolution, R2 is reframed: there is no runtime mode-selection gate. The contract runs unconditionally per-consumer once migrated. R2 in the requirements section should be updated to reflect that approximate mode is the unified path post-migration, and that any opt-back-out is a user-facing preference (practical decision 7).
- **R2.1** (index pre-seed) was previously a load-bearing gate. Under Decision 5's lock, the index is not required for partition sizing. R2.1's intent — ensuring that the lifecycle has the bounds it needs — is satisfied by auto-resize regardless of index availability.
- **R2.2** (tier match) was previously a runtime gate. Tier-correctness concerns persist but they relate to whether index-based bounds are correct for filtered runs, which is no longer load-bearing for the lifecycle. R2.2 is reframed as an audit concern (filter context should be reported in `-V` for correctness review), not a runtime gate.
- **R2.3** (input criteria failed) — dissolved entirely.
- **R10** (reason codes for why exact mode runs) — most of the codes (`no_index`, `tier_mismatch`, `input_criteria_failed`) become irrelevant under the dissolution. `user_forced_exact` remains relevant under practical decision 7 if a user-facing opt-out is implemented. `feature_not_active` (no values matched) remains relevant as a structural condition.

**What stays in the contract from prior provisional D3**: nothing. The CPU-cross-over-point, memory-headroom-gating, and small-N opt-out framings from prior provisional D3 are all moot.

**Source basis for the dissolution**: industry convention across all four consulted bin-based libraries. HdrHistogram and DDSketch run unconditionally — they don't have a runtime gate to "fall back to retaining raw values." Prometheus's `histogram_quantile()` runs unconditionally on whatever histogram is presented to it. The unified contract aligning with this posture is the source-grounded position.

**Requirements alignment**: R1-R14 have been rewritten in the *Requirements* section above to reflect the dissolution. R2's dual-mode-gate language is removed; R10's reason codes are reduced to the set that survives (`unified`, `pre_migration`, `user_opt_out`, `feature_not_active`).

#### Implementation guidance for #189

Non-binding.

- **No mode-dispatch code paths**: #189's primitives are invoked unconditionally by consumers using the unified contract. Consumers that have not yet migrated (during the phased rollout) use their pre-migration code paths directly — they don't invoke #189's primitives at all. There is no "select primitive vs. fallback" branch at runtime within a migrated consumer.
- **No gate-evaluation logic**: #189 does not implement gate-evaluation helpers (`is_eligible_for_approximate()`, `check_input_criteria()`, etc.) — these would have served the dissolved R2 gate. They are not part of the primitive set.
- **No `mode` field on partition state**: a partition under the unified contract is unconditionally an auto-resize bin-counter partition (Decision 5). There is no `mode: bin_counter | raw_array` discriminator on the partition.
- **Pre-migration code lives in consumer code**: the pre-migration sort-based code paths (e.g., the existing `calculate_statistics` at `ltl:5488`) live in the consumer's code, not in #189's primitive code. They are invoked by consumers whose migration phase has not yet validated, or by migrated consumers when the user-opt-out preference is active (per practical decision 7).

### Decision 7 — User-facing opt-out flag — **LOCKED (2026-05-19)**

#### Contract

ltl exposes a global user-facing opt-out flag that reverts all migrated consumers to their pre-migration code paths for the current run. The flag is **visible** in `--help` but carries a **deprecation notice** on every invocation, signalling that it is a transitional surface.

**Flag**:
- Long form: `--exact-percentiles`
- Short form: `-ep` (added 2026-05-19 per project requirement that every CLI option exposes both short and long forms; supersedes the prior "no short form" lock).
- Boolean flag (no argument).
- Default: not set (unified path runs for all migrated consumers).

**Scope**: global. When set, every migrated consumer reverts to its pre-migration code path for this run. There is no per-consumer scoping; the flag is all-or-nothing.

**Deprecation notice contract**: when `--exact-percentiles` is set, ltl emits a deprecation notice on stderr at the start of the run, before any output is produced. The notice's content must convey:
- That `--exact-percentiles` is a transitional opt-out for the unified contract migration.
- That the flag will be removed one release cycle past the validation of the last R9 migration phase that affects the currently-active consumers in this run.
- A pointer to documentation (`docs/usage.md` and/or the issue tracker) for migration guidance.

**Retirement timeline**: `--exact-percentiles` is available for one release cycle past each affected consumer's R9 phase validation. Concretely, if a consumer's phase validates in release X.Y, the opt-out for that consumer remains available through X.(Y+1) and is removed in X.(Y+2). The flag itself is removed entirely when the last consumer's opt-out window expires.

A separate locked decision (or release note) sets the retirement release for the flag once the last consumer's migration window is known. The retirement is not part of this lock; this lock fixes the *retirement policy* and *one-release-cycle window*, not the specific release number.

**Audit signal contract**: `-V` must surface that the opt-out is active in two places:

1. **Top-level run banner** at the top of `-V` output:
   - Content: a clearly visible warning that `--exact-percentiles` is active and that output may differ from current ltl defaults.
   - Format: practical decision 8 settles the exact wording and formatting, but the banner must be at the top of `-V`, before any consumer-specific sections, and must be the first thing an analyst sees in `-V` output for the run.
2. **Per-consumer line per R10**: each migrated consumer reports `user_opt_out` in its `-V` block (matching the R10 reason-code lock).

Both surfaces are part of the locked feature contract.

**Source basis**: no industry-standard reference for this decision; literature is silent on opt-out flags for histogram libraries (per `features/187-histogram-industry-grounding.md` § Decision 6 — the consulted libraries treat data-structure choice as user configuration rather than auto-gating; opt-out flags from one alternative path to another don't arise because none of them ships two alternative paths). This is an ltl-specific decision documented as such per the conduct rules.

**Rationale**:
- **Visible** rather than hidden: analysts who want byte-identical pre-feature output need to be able to find the flag without engineering documentation. Hiding it would create a knowledge gap that defeats its transitional purpose.
- **Deprecated immediately** rather than permanent: the unified path is the architectural direction; keeping the opt-out as a first-class permanent surface would signal that ltl supports two paths long-term, which contradicts the migration's "the migration completes eventually" property.
- **Global** rather than per-consumer: simplest CLI surface during a transitional period; if a real workflow surfaces that needs per-consumer scoping, this lock can be re-opened (the conduct rule for adding scope is "concrete need documented"). For the foreseeable transition, all-or-nothing is sufficient.
- **One release cycle past phase validation**: gives users time to migrate workflows that depend on byte-identical output without keeping two paths forever.
- **Banner + per-consumer line audit**: ensures analysts copying output (e.g., into bug reports or tickets) carry the opt-out signal with them; ensures programmatic tests can assert the path independently.

#### Implementation guidance for #189

Non-binding.

- **No #189 surface for the opt-out**: `--exact-percentiles` is a consumer-level concern, not a primitive-level concern. #189's primitives are not invoked when the flag is active; the consumer's pre-migration code path runs instead. #189 does not need an "opt-out mode" or any equivalent.
- **CLI parsing convention**: `--exact-percentiles` is a boolean flag handled in the same family as ltl's existing CLI flags (per CLAUDE.md's existing CLI conventions). Consistent with how ltl handles other boolean flags like `--ms`, `--hg`, `-hm`.
- **Banner format suggestion** (practical decision 8 finalizes): something like:
  ```
  === BIN-COUNTER MODE ===
  WARNING: --exact-percentiles is active. Output reflects the pre-#187 sort-based
  computation path. This flag is deprecated and will be removed in a future release.
  See docs/usage.md for the unified-path defaults.
  ```
  The exact phrasing, severity marker (`WARNING`/`NOTICE`/etc.), and any color/emphasis are practical decision 8.
- **Deprecation-notice emission**: emit to stderr (not stdout) so it doesn't pollute structured output that downstream tools might consume. Emit once per run, at the start.
- **CLI documentation requirements** (CLAUDE.md):
  - `print_help()` in `ltl` — `--exact-percentiles` documented with deprecation notice in the help text.
  - `README.md` options reference — listed with deprecation notice.
  - `docs/usage.md` — analyst-facing explanation of when to use the flag, what it does, and the migration path (use Decision 2's precision lever, or use an older ltl release if the analyst genuinely needs byte-identical pre-feature output).
- **Retirement mechanism**: when the flag is removed in a future release, the removal is itself a release-process item — bump the major or minor version per ltl's release conventions, document the removal in release notes, ensure the deprecation notice appeared in the prior release.

### Decision 8 — `-V` reporting verbosity and format — **LOCKED (2026-05-19); section name amended 2026-05-20**

> **Amendment 2026-05-20 (#34 Phase 2)**: section name changed from `=== PERCENTILE MODE ===` to `=== BIN-COUNTER MODE ===`. The substrate is HdrHistogram-style histogram bin counters; percentiles are one of three derivations from it, alongside bin counts (`histogram_bins`) and cell colors (`heatmap_cells`), which are not percentiles. The original name described the output of one consumer family; the amended name describes the substrate the entire contract is built on. Function name in code amended from `emit_percentile_mode_verbose` to `emit_bin_counter_mode_verbose` for the same reason. The user-facing `--exact-percentiles` / `-ep` flag is unchanged — it correctly names the user's choice rather than the substrate. All field names, consumer-name strings, and per-consumer field-name lockings within Decision 8 remain in effect verbatim.

#### Contract

`-V` output for percentile and histogram bin-counter state lives in a dedicated section named `=== BIN-COUNTER MODE ===`. The section is **always present** under `-V`, regardless of which consumers are active; if no consumer is computing percentiles or bin counts in the current run, the section reports `consumers_active: none` after the run-level header.

The section's primary purpose is **testability and AI-agent debugging**. Field names are stable across releases; cosmetic changes to formatting that affect field-name greps require a new locked-decision entry. Reader-friendliness is secondary to grep-stability and coverage of the research-locked observability signals.

**Conventions** (matching ltl's existing `=== INDEX READ-BACK ===` block, `ltl:836`):
- Section header: `=== BIN-COUNTER MODE ===`.
- Top-level lines: `key: value` with lowercase-with-underscores keys.
- Nested blocks: `block_opener: <name>` followed by two-space-indented `key: value` lines.
- Inline multi-value lines: space-separated `key=value` pairs (used for the per-quantile `out_of_range_bounded:` audit, see below).

**Run-level header** (always present, appears immediately after the section title):

- `opt_out_active: yes | no` — whether `--exact-percentiles` is set this run (Decision 7).
- `opt_out_notice: <message>` — present only when `opt_out_active: yes`. The line carries the deprecation-notice content (the stderr emission per Decision 7 is the human-facing notice; this line is the testable assertion that the deprecation surfaced in `-V`).
- `percentile_precision: <LEVEL> (<source>)` — the resolved tier from Decision 2's `--percentile-precision` semantics, with source annotation (`default`, `--percentile-precision N`, `--percentile-precision N; overridden` when `-pbpd` also specified). When `opt_out_active: yes`, append `; not in effect this run` to the source annotation. When `-pbpd N` is the active source and `N` does not correspond to any of the nine LEVELs in Decision 2's locked tier table, render as `percentile_precision: n/a (-pbpd N specified)`. The literal string `n/a` is part of the locked stability contract for this field; alternative renderings require a new locked-decision entry.
- `buckets_per_decade: <N> (<source>)` — the resolved numeric bpd value with source annotation (`default`, `-pbpd N`, `--percentile-precision N`, `-pbpd N; --percentile-precision N overridden`). When `opt_out_active: yes`, append `; not in effect this run` to the source annotation.

**Per-consumer blocks** (one block per consumer catalogued in R12; ordered as below):

Block opener: `consumer: <name>` where `<name>` is one of the locked consumer-name strings (see below).

Block field set, in order:
- `path: unified | pre_migration | user_opt_out | feature_not_active` — the locked R10 code identifying which path this consumer is running.

When `path: unified`, the following fields appear (in order):
- `partition_keying: <description>` — human-readable description of the keying dimension (e.g., `(category, log_key)`, `time_bucket`, `metric_global`).
- `partition_count: <N>` — number of distinct partitions managed by this consumer this run.
- `total_rebin_events: <N>` — sum of rebin events across all partitions for this consumer (Decision 5 telemetry).
- `max_partition_bins: <N>` — high-water-mark bin count across all partitions for this consumer (Decision 5 telemetry).
- `partitions_with_overflow_count: <N>` — number of partitions for this consumer with at least one overflow tally (Decision 4 audit aggregate).
- `partitions_with_underflow_count: <N>` — number of partitions for this consumer with at least one underflow tally (Decision 4 audit aggregate).
- `counter_memory_bytes: <N>` — aggregate counter-store memory for this consumer's partitions (Decision 5 telemetry; matches R7's `state_budget_bytes` requirement applied per consumer).
- `rebins_per_partition: p50=<N> p95=<N> p99=<N> max=<N>` — distribution of per-partition rebin counts across this consumer's partitions (Decision 5 telemetry). Format is space-separated `key=value` pairs.
- `percentiles_emitted: <space-separated list>` — the quantile set this consumer requested per R3 (e.g., `p1 p50 p75 p90 p95 p99 p999`).
- `out_of_range_bounded: <inline per-quantile>` — per-quantile audit per Decision 4. **Format: Option A inline**, e.g., `out_of_range_bounded: p1=none p50=none p75=none p90=none p95=none p99=high p999=high`. Space-separated `quantile_name=audit_value` pairs. The three-value enum `none | high | low` is locked verbatim from Decision 4.

When `path: pre_migration` or `path: user_opt_out` or `path: feature_not_active`, no further fields appear in the block — the path line alone is the per-consumer report. The pre-migration code path's own observability (if any) is not extended by this lock.

**Special case: shared-partition consumers**: when one consumer is a downstream rendering of another consumer's partitions (e.g., `csv_output` shares `%log_stats` with `summary_table`), the downstream consumer's block uses `shares_partitions_with: <upstream-consumer-name>` instead of repeating the partition-state fields. The block then carries only:
- `path: unified` (or other R10 code).
- `shares_partitions_with: summary_table` (the upstream consumer's name).
- `percentiles_emitted: <space-separated list>` (may differ from the upstream consumer's set).
- `out_of_range_bounded: <inline per-quantile>` (per-quantile audit specific to this consumer's percentile set).

**Locked consumer-name strings** (the canonical names used in `-V` output; the R12 audit's Path A / Path B / Path C nomenclature stays as internal spec-document convention):

| `-V` consumer name | R12 audit path | What it covers |
|---|---|---|
| `summary_table` | Path A | Per-message latency percentiles rendered in the summary table |
| `csv_output` | Path A' | Same percentiles via `-o` CSV writer |
| `time_bucket_stats` | Path B | Per-time-bucket duration percentile statistics row |
| `heatmap_markers` | Path C2 | P50/P95/P99/P99.9 column-position markers on heatmap rows |
| `heatmap_cells` | Path C2-cells | Heatmap cell colors themselves |
| `histogram_view` | Path C1 | Histogram-mode global percentile indicators |
| `histogram_bins` | Path C1-bins | Histogram-mode bin counts (bar heights) |

The consumer-name strings are part of the locked feature contract. Future consumers (highlight subsets per Phase 4; future hover-to-redraw renders per Phase 5) get their canonical names when their migration phase locks them.

**Section presence**: always emitted when `-V` is active. When no consumer is computing percentiles or bin counts (e.g., `ltl -ll <file> -V` with no percentile-relevant features enabled), the section consists of the run-level header followed by:

```
consumers_active: none
```

No per-consumer blocks in that case.

**Display order of consumer blocks**: in the order listed in the consumer-name table above (`summary_table` first, then `csv_output`, then `time_bucket_stats`, then `heatmap_markers`, then `heatmap_cells`, then `histogram_view`, then `histogram_bins`). Deterministic ordering is required for regression testability; later-added consumers append to the end of this order.

**Stability contract**: the section name, all top-level field names, all consumer-name strings, and all per-consumer field names are part of the locked feature contract. Changing any of them requires a new locked-decision entry. Field *values* may evolve with the data; field *names* may not change without an explicit decision update.

**Examples** (illustrative, showing the format):

Default run with all consumers migrated:

```
=== BIN-COUNTER MODE ===
opt_out_active: no
percentile_precision: 5 (default)
buckets_per_decade: 53 (default)

consumer: summary_table
  path: unified
  partition_keying: (category, log_key)
  partition_count: 1247
  total_rebin_events: 14
  max_partition_bins: 318
  partitions_with_overflow_count: 0
  partitions_with_underflow_count: 0
  counter_memory_bytes: 2643456
  rebins_per_partition: p50=0 p95=0 p99=1 max=2
  percentiles_emitted: p1 p50 p75 p90 p95 p99 p999
  out_of_range_bounded: p1=none p50=none p75=none p90=none p95=none p99=none p999=none

consumer: csv_output
  path: unified
  shares_partitions_with: summary_table
  percentiles_emitted: p1 p50 p75 p90 p95 p99 p999
  out_of_range_bounded: p1=none p50=none p75=none p90=none p95=none p99=none p999=none

consumer: time_bucket_stats
  path: pre_migration

consumer: heatmap_markers
  path: pre_migration

consumer: heatmap_cells
  path: pre_migration

consumer: histogram_view
  path: pre_migration

consumer: histogram_bins
  path: pre_migration
```

Opt-out active:

```
=== BIN-COUNTER MODE ===
opt_out_active: yes
opt_out_notice: --exact-percentiles is set; all migrated consumers reverted to pre-#187 sort-based computation. This flag is deprecated and will be removed in a future release.
percentile_precision: 5 (default; not in effect this run)
buckets_per_decade: 53 (default; not in effect this run)

consumer: summary_table
  path: user_opt_out

consumer: csv_output
  path: user_opt_out

[... remaining consumers reporting path: user_opt_out or pre_migration as appropriate ...]
```

Precision override with conflict:

```
=== BIN-COUNTER MODE ===
opt_out_active: no
percentile_precision: 4 (--percentile-precision 4; overridden)
buckets_per_decade: 100 (-pbpd 100; --percentile-precision 4 overridden)

[... per-consumer blocks ...]
```

Tail-quantile overflow audit (pathological data):

```
consumer: summary_table
  path: unified
  partition_keying: (category, log_key)
  partition_count: 1247
  total_rebin_events: 14
  max_partition_bins: 318
  partitions_with_overflow_count: 3
  partitions_with_underflow_count: 0
  counter_memory_bytes: 2643456
  rebins_per_partition: p50=0 p95=0 p99=1 max=2
  percentiles_emitted: p1 p50 p75 p90 p95 p99 p999
  out_of_range_bounded: p1=none p50=none p75=none p90=none p95=none p99=high p999=high
```

No consumers active:

```
=== BIN-COUNTER MODE ===
opt_out_active: no
percentile_precision: 5 (default)
buckets_per_decade: 53 (default)
consumers_active: none
```

**Source basis**: no industry-standard reference. The format mirrors ltl's existing `=== INDEX READ-BACK ===` block (`ltl:836` and following), which is the established convention for verbose observability sections in this codebase. ltl-specific decision per the conduct rules; documented as such.

**Rationale**:
- **Mirror existing `=== INDEX READ-BACK ===` style** so that the regression-test corpus stays internally consistent and the AI agent's pattern-matching against `-V` output transfers across sections.
- **Per-consumer blocks** rather than flat key-value list because there are multiple consumers and per-consumer state needs to be cleanly attributable; flat with consumer-prefix fields would be ugly and brittle.
- **Inline `out_of_range_bounded:`** (Option A) for grep-friendliness — a test can grep `"out_of_range_bounded.*high"` to detect any quantile-overflow condition with a single regex.
- **Always present under `-V`** for consistency — tests and AI agents always know where to look; the `consumers_active: none` case handles the no-percentile-feature scenario.
- **Locked consumer-name strings** so consumer-name changes require explicit decision updates; this protects regression tests from cosmetic-name churn.
- **Stability contract** is the load-bearing property for the testability purpose — field names locked, field values free to evolve.

#### Implementation guidance for #189

Non-binding.

- **Section emission point**: emit the `=== BIN-COUNTER MODE ===` block at the appropriate point in `@verbose_output` so it appears in the standard `-V` output order alongside `=== INDEX READ-BACK ===` and `=== Verbose ===`. Exact ordering relative to those other sections is implementation discretion; tests should not depend on inter-section ordering.
- **Per-consumer iteration order**: emit per-consumer blocks in the order listed in the locked consumer-name table. This is part of the contract — tests grep for consumer blocks in this order.
- **Field-value formatting**:
  - Integer counts: bare decimal (`1247`, not `1,247`).
  - Byte counts (`counter_memory_bytes`): bare decimal bytes (`2643456`); do not format as KB/MB.
  - Percentile labels in inline lines: lowercase `p1`, `p50`, `p75`, `p90`, `p95`, `p99`, `p999`, `p9999` (no period).
- **`shares_partitions_with:`** is set by the implementer when the consumer reuses another consumer's `%log_stats` (or equivalent). For Phase 2's locked migrations, `csv_output` shares with `summary_table` (both consume `%log_stats` via the same `calculate_statistics` invocation today). Other shared-partition relationships should be declared explicitly in #189's audit findings or in the consumer's migration spec.
- **`opt_out_notice:` content**: when `--exact-percentiles` is active, the notice content in `-V` should match (or paraphrase) the stderr deprecation notice. Recommended phrasing in the contract example above; minor variants acceptable provided the test surface (grep for `opt_out_active: yes`, then assert `opt_out_notice:` line present and non-empty) is preserved.
- **`partition_keying:` description**: the human-readable string is free-form per consumer, but should be stable across runs for a given consumer. Suggested strings in the example above; consumer migrations may refine. The string should match what's in the spec's R12 audit for that consumer where possible.
- **Empty `partition_count: 0`** edge case: when a consumer is on the `unified` path but no data triggered partition construction (e.g., zero matched values), the consumer's `path:` should be `feature_not_active`, not `unified`. Don't emit zero-partition blocks under `unified`.
- **Tests for this section** in the `tests/baseline/` harness should be added per CLAUDE.md release process: at minimum a scenario asserting the section header and run-level fields exist; per migration phase, additional scenarios assert the migrated consumer's block appears with the expected `path:` value.

### Decision 9 — Phase 2 default activation policy — **DISSOLVED (2026-05-19): out of scope for #187**

#### Contract (dissolution)

The question of activation policy — when a consumer's migration ships, whether the unified path is default-on or default-off at ship, what the per-release ramp looks like, what release-engineering gates apply — is **out of scope for #187**. #187 is a research-and-architecture-foundation deliverable; it does not ship code, does not own consumer migrations, and does not specify release cadence. Activation policy belongs to the per-consumer implementation tickets that consume this contract.

The original D3 framing of Decision 9 ("Phase 2 ships with default gating; the decision conversation confirms whether Phase 2 ships as opt-in only, or with auto-activation once D2-equivalent harness validates the accuracy bound") was a holdover from the pre-reframing scope when #187 was framed as the per-message percentile migration ticket itself. Under the current reframing, #187 owns the unified contract; the per-message migration is a separate implementation ticket that will make its own activation decisions.

**Why dissolution is the right call** (and not "lock with a policy"):

1. **Different consumers have different risk profiles.** Heatmap cell colors are a visual surface — a regression there looks different from a regression in per-message percentile numbers. The release-engineering decision for each consumer's migration ticket should be made in the context of that consumer's surface, not pre-committed in a research deliverable.
2. **Activation policy depends on factors out of scope for #187.** Release cadence, user-base concerns, communication channels, deprecation timelines for the opt-out flag (Decision 7) — these depend on ltl's release process and the implementation ticket's specific context, not on the contract.
3. **The contract already provides what the activation policy needs to consume.** R11 byte-identity under opt-out; R11a opt-out preserves pre-feature output; R4 accuracy bound for validation; Decision 7's opt-out as the user-facing safety net; Decision 8's `-V` audit surface for testability. The implementation ticket has everything it needs to make its activation call.
4. **Locking a default-activation policy here would over-reach.** It would commit #34, the per-message migration ticket, #51, and any future consumer migration to a single release pattern decided in research isolation. That violates the principle that each implementation ticket owns its release decisions.

**What this dissolution preserves in the contract**:

- R9's consumer-grouping recommendations remain. Implementation tickets are recommended to migrate consumers within a phase together; that's architectural guidance, not release-engineering prescription.
- R11 and R11a preserve the byte-identity and opt-out contracts that any activation policy must satisfy. Those are contract surfaces, not activation policies.
- Decision 7's deprecation notice and timeline guidance ("one release cycle past each consumer's R9 phase validation") is *guidance for the implementation ticket*, not a binding ship date. The implementation ticket sets the actual retirement release.
- Decision 8's testability contract on `-V` output is satisfied whether the activation policy is default-on or default-off; the implementation ticket exercises the same audit surface regardless.

**Source basis**: ltl-specific scope decision. No industry-standard reference applies to whether a research deliverable should specify release policy for its consumers; the conduct rule "where ltl's case differs from the industry-standard case, the divergence is documented explicitly" doesn't apply because there is no industry case to compare against here. This is a project-scope judgment, locked as a dissolution.

#### Implementation guidance for implementation tickets (not #189 directly)

Non-binding; addressed to the per-consumer migration tickets that consume this contract.

- **Default-on vs. default-off**: each implementation ticket decides based on its consumer's surface and risk profile. The contract supports both: R11a guarantees byte-identical pre-feature output under `--exact-percentiles` opt-out; the unified path produces output within the R4 bin-resolution bound around the pre-migration output.
- **Validation harness**: each implementation ticket implements its own validation against the contract: byte-identity under opt-out (R11a); per-quantile error within R4 around pre-migration values on D2 datasets. The harness lives in `tests/baseline/` per CLAUDE.md, scoped to that consumer.
- **Communication to users**: each implementation ticket plans its release-note coverage. The unified path produces different numeric values for percentiles (interpolated bin-derived vs. sorted-array-indexed) but more accurate ones; communication should frame this as a quality improvement, not a regression.
- **Coordination with Decision 7's deprecation timeline**: each implementation ticket's release determines when `--exact-percentiles` may be retired for that consumer. The contract is "available one release cycle past phase validation" (Decision 7); the actual release number is set by the implementation ticket's release process.
- **Coordination with R9 grouping**: implementation tickets are recommended to migrate consumers within a phase together (e.g., Phase 2's `summary_table` and `csv_output` ship together; Phase 3's heatmap-and-histogram-area consumers ship together). Splitting consumers within a phase across releases leaves the codebase in an inconsistent partial-migration state for users.

### Decision 10 — Prototype validation scope (what #189 must validate empirically before production code) — **LOCKED (2026-05-19)**

#### Contract

Before #189 begins production implementation of the unified primitive helpers, the architectural choices locked in this file must be validated empirically through prototyping. #187 specifies *what* must be validated. #189 owns *where* the prototype lives, *how* it's structured, and *how* the validation is executed.

**Mandatory validation aspects** (#189's prototype must cover each):

1. **In-bin interpolation formula behavior on real data.** The Prometheus log-scale interpolation formula (the math that takes a partition + bin + rank-in-bin and returns a percentile value, locked as `2^(log2(lower) + (log2(upper) − log2(lower)) · fraction)`) must be exercised against representative D2 log files. The validation confirms the formula's Perl implementation matches the math and that the accuracy contract holds on real distributions, not just in theory. Edge cases (single-bin partitions, partitions with `bin_count = 1` at the target rank, partitions where `lower = upper`) must be exercised explicitly.

2. **Auto-resize partition lifecycle on per-key fan-out at scale.** The HdrHistogram-style auto-resize behavior must be exercised when many distinct partitions are managed simultaneously — the per-`(category, log_key)` fan-out scenario where the literature explicitly does not provide guidance (grounding doc gap 8). Measurements required:
   - Rebin event counts per partition across the partition population (`rebins_per_partition` distribution per Decision 5's locked telemetry).
   - Per-key memory consumption in practice.
   - Total counter-store memory at realistic key cardinality (tens to hundreds of thousands of partitions).
   - Comparison of actual memory against the projected ~212 MB at 10⁵ keys (locked default 53 bpd).
   - Validation that the amortized O(N) rebin cost claim holds on real per-key value-range distributions.

3. **Initial partition seeding heuristic and overflow/underflow handling on edge-case data.** Two related validations:
   - The locked seed (partition opens at 5 decades centered on the first value seen) must be validated against real latency data to confirm p99 rebin counts fall in the expected 0–2 range. Surface any keys that rebin pathologically; document if the seed needs tuning before #189's production implementation locks in the heuristic.
   - The Decision 4 overflow/underflow handling (separate counters at the partition boundaries; R4 returns `boundary[B]` or `boundary[0]` when target rank lands in overflow/underflow) must be exercised against pathological inputs constructed from D2 datasets — extreme outliers, very narrow distributions, mixed scale regimes. Confirm the `out_of_range_bounded: high|low|none` audit field per Decision 8 fires correctly per quantile, and document the hit rate in normal vs. pathological scenarios.

4. **End-to-end `-V` output sample for downstream comparison.** The prototype must produce a real `=== BIN-COUNTER MODE ===` verbose output block, per the locked Decision 8 format, against real log files. The output sample becomes a reference for downstream work: implementation tickets compare their migrated consumers' actual output against this prototype output to spot deviations; tests can grep against known-good output. The sample must exercise enough scenarios (default precision, `--percentile-precision` override, `-pbpd` override, flag conflict, overflow audit firing, opt-out active) to cover the format's locked surface.

5. **Calculation accuracy compared to the array-of-values approach currently in use.** Direct comparison between the unified contract's output (Decision 1 formula over auto-resize partitions per Decision 5) and ltl's *existing* `calculate_statistics` retained-array sort-and-index approach (`ltl:5488`). For every required percentile per consumer (per R3) across D2 datasets, the prototype must show that the unified output sits within the bin-resolution bound (per R4, ~1.1% midpoint error at locked default 53 bpd) of today's exact output. This is the operational accuracy validation — confirming that the locked architecture produces output users will accept as a quality improvement over the current implementation, not a regression.

**Hard prerequisite contract**:

- #189 production implementation does not begin until all five aspects above have been validated, results documented, and lessons identified for #189's design.
- Implementation tickets that depend on #189 (e.g., the per-consumer migration tickets) wait for #189; #189 waits for the prototype completion.
- If prototype validation surfaces a result that contradicts a locked decision in this file (e.g., real-world rebin rates are pathologically high under the locked seed heuristic), a follow-up issue is filed against #187 to record the contract revision and re-lock the affected decision. #189 does not silently diverge from the contract; the contract is re-opened explicitly.

**What this lock does *not* specify**:

- Where the prototype code lives (e.g., `prototype/187-*.pl`, `prototype/189-*.pl`, or some other layout). #189's discretion.
- How the prototype is structured (single script, per-aspect scripts, scenario-based subcommands). #189's discretion.
- How the results are documented (markdown file, structured data, both). #189's discretion.
- The CPU performance / runtime cost of the prototype itself. Not relevant to validation.
- Whether the prototype code becomes the basis for #189's production code, or is discarded after lessons are extracted. #189's discretion.

**Source basis**: ltl-specific project-scope decision. No industry-standard reference applies to research-deliverable-to-implementation handoff conventions; the conduct rule doesn't apply because there is no comparable industry case. The decision is grounded in ltl's existing prototype-before-production-implementation pattern (see `prototype/96-fuzzy-consolidation.pl` and the issue #96 work that informed production consolidation code).

#### Implementation guidance for #189

Non-binding; addressed to the agent or developer who builds the prototype as #189's first step.

- **Reference workflow**: the `prototype/96-fuzzy-consolidation.pl` work is the precedent. That prototype validated multiple algorithm choices and architectural assumptions against real D2 datasets before issue #96's production consolidation code was written. The lessons surfaced in that prototype shaped the production implementation directly. Decision 10 establishes the same pattern for #187's contract.
- **D2 dataset coverage**: the existing D2 cross-reference (in this file) identifies which existing log files exercise which use-case regime. The prototype should cover at minimum: heavy-tailed access log (Tomcat), ThingWorx mixed-traffic, high-cardinality DEBUG-heavy, small-N case, and the pathological-outlier case for overflow/underflow testing.
- **Results document structure**: per validation aspect, document (a) what was measured, (b) the measurement methodology (which D2 file, which command-line invocation), (c) the result, (d) whether the result confirms the locked contract or surfaces a concern, (e) the lesson for #189's production design.
- **Tooling**: the prototype runs ltl-shape data (parses log files, extracts numeric values, builds counter stores). It does *not* need to integrate with ltl's full pipeline; standalone Perl scripts that read the D2 files directly are sufficient.
- **Telemetry collection in the prototype**: the prototype emits the Decision 8 `-V` format. Decision 5's rebin telemetry is what the validation aspect 2 (auto-resize lifecycle on per-key fan-out at scale) needs to measure — the prototype is its own first consumer.
- **Concurrent validation**: validation aspects can be exercised in a single end-to-end prototype run on a representative D2 file, with each aspect's measurements captured from that single run. This may be more informative than isolated per-aspect tests, since real workloads exercise all aspects in combination.
- **Failure modes**: if the prototype reveals a locked decision is wrong on real data, do *not* silently proceed with #189 implementation against a known-wrong contract. Stop, file the follow-up issue against #187, and wait for the contract to be re-locked. This is the discipline that makes the research-deliverable-to-implementation handoff trustworthy.

## Downstream implications for related issues

The unified primitive contract locked in this file dissolves or reshapes scope in several related issues. The implications are recorded here as authoritative input to the re-scoping of those tickets; the actual scope changes are made in those tickets themselves.

### #34 — Heatmap and histogram bin-counter consumer

**Previous framing**: introduce a "bin-counter mode" alongside the existing raw-array mode, with a runtime gate (and R5/R6 overflow tracking under that mode).

**Reframed**: the heatmap and histogram consumers migrate to the unified contract unconditionally in R9 Phase 3. There is no "bin-counter mode" to switch on/off — the partition lifecycle is auto-resize per Decision 5, the in-bin rule is the Prometheus formula per Decision 1, the overflow handling is the Prometheus `+Inf` convention per Decision 4. The R5/R6 overflow tracking from #34's prior framing becomes the implementation of Decision 4's separate-counter contract for the heatmap and histogram partitions.

**Scope changes needed in #34**:
- Remove the dual-mode language and runtime gate.
- Reframe as straight migration of `%heatmap_raw` and `histogram_values` accumulation onto per-partition auto-resize during the parse.
- R12 cross-reference becomes "per the unified contract in #187."
- R4-bis (heatmap markers consume R4) stays; consumes Decision 1's locked formula.
- Validation surface is baseline-regression against shipped heatmap/histogram output. Display-output stability is the acceptance criterion.

### #179 — Index pre-seed (CLOSED 2026-05-10)

**Status**: closed and shipped. The index read-back capability exists in the codebase per #179's acceptance criteria. It is not being changed or reopened by #187.

**Relationship to #187's contract**: under Decision 5's auto-resize lifecycle, partitions adapt online to whatever values they observe; no upfront `[min, max]` is required from the index for partition sizing. The portion of #179's shipped work that pre-seeds heatmap/histogram boundary structures from cached index data therefore becomes **redundant** for any consumer that adopts the unified contract — those consumers do not need the pre-seed; they construct partitions lazily on first observation.

**Redundant ≠ broken**. The shipped index read-back, freshness check, drift detection, and end-of-run refresh remain correct for what they were designed to do. They are simply no longer load-bearing for the consumers that migrate to the unified contract. The implementation tickets that perform those consumer migrations may, at their discretion, leave the pre-seed code in place (no harm — the partition is auto-resized after construction regardless of the seed), bypass it for unified-path consumers (cleanest separation), or remove the pre-seed feed entirely if no remaining consumer needs it. That's a migration-ticket choice, not an action #187 imposes.

**No action required from #187 against #179.** #179 is referenced in #187's `-V` audit field (`index_used: yes|no` per the existing observability), and any tier-correctness or drift-correction audit value that the index provides is independent of the unified contract. The index file (#46) and its read-back (#179) continue to exist as ltl features; they simply no longer participate in partition lifecycle decisions for unified-contract consumers.

### #189 — Unified primitives

**Previous framing**: deliver R1-R4 primitives that consumers call under bin-counter mode, with R4's algorithm choice deferred to #187's D3.

**Reframed**: primitives are unconditionally what all consumers use. R4 is locked to the Prometheus formula (Decision 1). R1 implements auto-resize per Decision 5. The keying flexibility (R3) is straightforward across the consumer shapes catalogued in R12.

**Scope changes needed in #189**:
- R1 must implement auto-resize per Decision 5 (full-default-span seed, HdrHistogram-convention doubling).
- R3 must support the keying shapes catalogued in R12: per-(category, log_key), per-time_bucket, per-metric global, and future shapes.
- R4 is locked to the Prometheus formula (verbatim Decision 1).
- R5/R6 implement Decision 4's overflow/underflow contract.
- "Mode-gate hooks" or "approximate-mode dispatch" surfaces from prior framing are removed — primitives run unconditionally.

### #41 — Unified binning

**Previous framing**: future feature for unifying binning concerns across heatmap, histogram, and percentile consumers.

**Reframed**: the unification *is* the unified contract that #187+#189 produce. #41's prior scope is largely satisfied. Any residual concerns (e.g., user-facing CLI flag harmonization for the various `-hgbpd` / `-pbpd` / `--percentile-precision` knobs) should be re-evaluated against the now-locked contract.

**Scope changes needed in #41**: re-evaluate whether the issue is still needed as a separate ticket or whether its concerns are absorbed by #187+#189+#34.

### #51 — Highlight-data accumulation

**Previous framing**: highlight subset becomes a separate accumulation path requiring its own partition.

**Reframed**: highlight subsets are consumers of the unified contract. R9 Phase 4. The highlight partition has the same lifecycle (auto-resize), the same in-bin rule (Prometheus formula), the same overflow handling (Decision 4) as every other consumer. The only consumer-specific concern is the keying (highlight subset filter context determines which observations populate the partition).

**Scope changes needed in #51**: align with the unified contract; partition is one of the consumers in R12. The internals don't change; the partition mechanism does.

### #23 — Engine rewrite

**Previous framing**: engine rewrite blocked on #179/#180/#181 plus alignment-updated #41/#34/#51.

**Reframed**: the dependency on #179 may dissolve or shrink as described above. #34's reframing is captured here. #41's status may change. The engine rewrite's prerequisites should be re-evaluated against the locked unified contract.

**Scope changes needed in #23**: re-evaluate the prerequisite list. May allow earlier start than previously planned, depending on what survives the #179 reframe.

### Common implication across all related issues

Every related issue that was previously coupled to a runtime dual-mode gate, an index dependency for partition sizing, or an "introduce bin-counter mode" framing should be re-evaluated against the locked unified contract. The user is the architect of those tickets; this section provides the authoritative basis for the re-scoping. The actual ticket edits are not made by this research deliverable.

### How decisions get locked from here

A decision moves from OPEN to LOCKED in this section when:

1. The user has chosen between the source-grounded options presented in the relevant D3 subsection (or against the F1 framing for derived decisions).
2. The choice is either (a) one of the source-grounded options, in which case the citation accompanies the lock; (b) derived from the F1 framing, in which case the framing link accompanies the lock; or (c) an ltl-specific divergence from industry practice, in which case the divergence rationale is recorded explicitly.
3. The locked entry records: the chosen option, the citation(s) and/or framing link, and the one-line rationale.

Current state: **F1**, **Decision 1**, **Decision 1A**, **Decision 2**, **Decision 3**, **Decision 4**, **Decision 5**, **Decision 7**, **Decision 8**, **Decision 10** locked; **Decision 6 dissolved** (no runtime gate in the unified contract); **Decision 9 dissolved** (release-engineering out of scope for #187). All decision-conversation work complete.

## Spec stability

The behavior contract (R1–R14, R9 multi-phase plan, edge cases, `-V` format) is intended to be stable across implementation. The research deliverables (D1–D5) are expected to grow as research lands; their outputs become the bound values for R4, R7, R10. **Locked decisions from research** records those values as the decision conversation closes them.

Phase boundaries in R9 are part of the spec contract. Crossing a phase boundary requires explicit revalidation against the accuracy bound for the new consumer.
