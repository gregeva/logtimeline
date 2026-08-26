# Feature: Compact per-message statistics store

## Overview

Every distinct message's statistics live in their own small Perl hash:
`$log_messages{$category}{$log_key} = { occurrences => N, durations => [...], ... }`.
Each such entry is six separately allocated pieces (head, body, bucket array, hash
entry, key, value), created at the moment the message is first seen — interleaved with
whatever else the read loop allocates and frees for that line. At high cardinality every
later pass over the population — statistics, sorting, memory measurement — chases
pointers through memory laid down in read-loop order.

This document specifies the replacement of that store with a compact representation, and
records the investigation that grounds it. **Nothing here is locked.** The candidate
designs (§ Candidate representations) and the questions they must answer (§ Open
questions) are the input to a mandatory prototype; the prototype's measurements are what
convert open questions Q1…Q12 into locked `Dxx` decisions. No implementation begins
before that.

**Prototype stage completed 2026-08-24** — measurements and per-aspect analysis in
`prototype/426-per-message-store-validation-report.md`; answers and proposed decisions
in § Prototype findings below. The decisions there are *proposed*, awaiting the
architect's lock.

Scope note: the *motivating* store is the one for per-message-key statistics — that is
where the memory is. But this is a data-model redesign, and a data-model redesign is
analysed across **all** of the data structures that hold observations (architect,
2026-08-25): the bucket-scoped stores (`%log_analysis` / `%log_stats`), the heatmap and
histogram counter stores, and the per-message store alike. They differ in cardinality
profile, lifecycle and consumer, and those differences are findings of the analysis —
not grounds for excluding a structure from it.

The four bin-counter surfaces are **already one shared substrate**, not four independent
stores: `%TIER_BPD` in `ltl` resolves `histogram`, `heatmap`, `bucket-stats` and
`message-stats` from a single precision tier (`--data-model-precision` / `-dmp`,
default 5) through `bpd_for_surface()`, and #187 states that algorithm, lifecycle,
in-bin rule and out-of-range handling are uniform across them — resolution is the one
thing legitimately per-surface (#187 Decision 2 as amended by #289 and #293). The
per-message row sits at 53 at the default tier while heatmap and histogram sit at 616,
and the reason is cardinality, not preference: per-message partition count is unbounded,
and #187's memory table puts today's dense layout at ~212 MB per 10^5 keys at 53 against
~2.5 GB at 616. Any store proposal is therefore a proposal about that shared substrate's
container, and its consequences are read across all four rows of the table.

## GitHub Issue

[#426 — PERFORMANCE: per-message statistics store is one hash per message; as-built heap layout costs 5× on population traversal](https://github.com/gregeva/logtimeline/issues/426)

## Motivation

### The measurement

`tests/profile/results/415-statsdrift-new/analysis.md` § "Locality ladder" (100k-key
sample, best-of-5 per level, two ABAB rounds). Each level rebuilds one more layer into
freshly allocated memory while keeping the rest; `lookup` is the comparator-shaped loop,
`walk` is the population-walk shape:

| level | what is fresh | lookup (v0.16.0 / 0.17.0) | walk (v0.16.0 / 0.17.0) |
|---|---|---|---|
| L0 as built | nothing | 0.0387 / 0.0445 | 0.0565 / 0.0573 |
| L1 | outer hash entries + value RVs | 0.0280 / 0.0320 | 0.0455 / 0.0345 |
| L2 | L1 + inner entry hashes rebuilt | **0.0080 / 0.0078** | 0.0253 / 0.0272 |
| L3 | L2 + key strings re-copied | 0.0110 / 0.0115 | 0.0271 / 0.0269 |

**As-built entry layout costs ~5× on keyed traversal and ~2× on the population walk, in
both versions.** The cost survives rebuilding the outer hash (L1) and vanishes when the
inner entry hashes are rebuilt (L2), so hashing, key strings and the outer bucket array
are exonerated — confirmed independently by `Devel::Peek` (both arms: `OOK,SHAREKEYS`,
`MAX = 262143`, `KEYS = 99487`, shared-HEK COW key SVs, identical entry-hash shape).

This is a **data-model cost, not a version regression**. #415's +15% drift (bisected to
`bd8a972`, #58 S5) is a worsening of an already scattered layout: the generated scan sub
changed the read loop's per-line allocation/free sequence, so consecutive entries land in
a different free-list order. Nothing in the statistics code changed.

### Confirmed on the current tree

`release/0.17.0` @ `09262f7`, `humungous-log-uniqueness` construct
(`-so p99 -ni -mem`, `--terminal-width 200`), single confirmation run:

```
TIMING  finalize/calculate_statistics                   0.569
TIMING  finalize/calculate_statistics/population_walk   0.270   (47%)
TIMING  finalize/calculate_statistics/sort_selection    0.287   (50%)
TIMING  finalize/calculate_statistics/bucket_stats      0.000
TIMING  finalize/calculate_statistics/group_calc        0.000
TIMING  finalize/calculate_statistics/threadpool_stats  0.000
MEMORY  log_messages                              133,188,237
COUNTS  log_messages_entries                          286,659
COUNTS  log_messages_population                        286,659
```

97% of the phase sits in exactly the two blocks that traverse `%log_messages`; every
sub-stage that does per-key *computation* is 0.000. `MEMORY log_messages` is
byte-identical to the figure in the #415 analysis.

### Memory decomposition (measured, answers Q12 ahead of the prototype)

133,188,237 B / 286,659 keys ≈ **465 bytes per key**. A `Devel::Size` probe on the live
store (5,000-entry sample of the `plain` category, same construct) decomposes it:

| component | bytes/key | share | reachable by a columnar store? |
|---|---|---|---|
| Inner per-message entry hash | 213.0 | **45.8%** | yes — this is what SoA replaces |
| Key strings + outer hash entry/HEK/RV | 251.6 | **54.2%** | no |

Average key length is **200.0 chars — exactly the cap**, because
`$max_log_message_length` is set to the terminal width. A controlled re-run at
`--terminal-width 120` confirms the split: the store falls 133.2 MB → 110.2 MB (−17%)
while `avg_entry_total` stays **213.0 B unchanged**. Key storage is real, cap-driven, and
untouched by any arm in this specification.

**Consequence for the ceiling:** the memory upper bound for replacing the entry hash is
~46% of this store, not 100% — and only if the replacement's per-field arrays cost
nothing, which they will not. The *traversal* case (the 5×) remains the primary
justification; the memory case is secondary and smaller than the raw per-key figure
suggests. #2's per-entry arithmetic (F10) must be re-derived against this split.

### Two limits on the 5×, both load-bearing

1. **The 5× is an upper bound measured on the existing representation.** L2/L3 compacted
   *hashes* into fresh memory. No columnar candidate has ever been measured. The ladder
   says "a denser layout of this data is 5× faster to traverse"; it does not say
   struct-of-arrays achieves that, nor at what write-side cost.
2. **Part of the cost is reachable without replacing the data model** (F5, F6 below).
   A specification that omits the cheap arms risks buying a 167-site rewrite for a
   benefit a Schwartzian transform would have delivered.

## Findings from the investigation (2026-08-24)

Established by direct reading of `ltl` @ `09262f7`. Counts are mechanically derived, not
estimated. Sub names and code snippets are the durable anchors; line numbers are hints
that drift.

- **F1 — `$category` is two-valued.** Only `'highlight'` or `'plain'`, assigned in
  `read_and_process_logs` (`$category = 'highlight';` / `= 'plain';`). The outer level is
  a fixed pair, not an open-ended hash — an ordinal scheme does not need to generalise
  over categories.

- **F2 — There is no single schema; there are four cross-cutting variants.**
  {raw, bin} × {access-log, non-access-log}, further multiplied by the #305 demand groups
  and by `@udm_configs` cardinality. The lazy initializer (`$log_messages{...}{...} //=`
  in `read_and_process_logs`) already branches on `$message_stats_capture_mode`, and
  `$message_stats_demand_shape` gates `m2_sum`/`m3_sum`/`m4_sum`. The non-access-log
  branch (`else { ...{occurrences}++ }`) creates entries carrying **one** field. The
  store must therefore be **allocated after option processing**, not statically declared.

- **F3 — Deletion is the hardest consumer, and neither the issue nor F16 addresses it.**
  Four whole-entry deletes, all on the `-g` path: `group_similar_messages` (Pass 1 S3
  absorption; Pass 2 cleanup sweep), `process_final_pass_window` (consumed-key sweep),
  `run_consolidation_checkpoint` (consumed-key sweep). Deleting a hash key frees the
  entry; clearing an ordinal slot does not compact the arrays. Under `-g` most of the
  population is deleted. Also one field-level delete (`delete
  ...{$log_key}{total_duration}`, #330 — distinguishes "no duration observed" from
  "measured zero") and one counter-store delete in
  `merge_log_message_entry_into_cluster`. **This is the single biggest design risk.**

- **F4 — Entries escape as hashrefs into a generic, field-name-driven merge surface.**
  `merge_consolidation_stats($target, $source)` is fed from three source kinds: cluster
  hashrefs, the transient `$stats_source` built inline in the read loop, and live
  `%log_messages` entries via `merge_log_message_entry_into_cluster` (seven call sites).
  It walks field *names*, including `"udm_${name}_*"`, and delegates to
  `merge_bin_state`. `calculate_statistics_bin($sidecar_entry, $counter_entry, ...)`
  likewise receives the live entry (read-only). Consolidation is not the hot path, so a
  materialized row view at this boundary is viable — but it is a decision, not a given.

- **F5 — The calculated-statistic sort path already uses the columnar idiom.** Its
  defined block sorts a flat transient `%sort_value` map, not `%log_messages`. Its *fill*
  block still performs two two-level lookups per comparison — and on the measured
  construct the fill block is the **entire** population (`sort_selection: statistic=p99
  defined=0 fill=286659`, zero keys reaching the n≥4 eligibility floor).

- **F6 — Repeated full-path resolution.** The read loop re-resolves
  `$log_messages{$category}{$log_key}{field}` dozens of times per line rather than
  hoisting `my $entry` once — it *does* hoist for the bin-mode sidecar block, but not for
  the surrounding occurrences/bytes/count/UDM/duration writes. The available-value sort
  comparator does two two-level lookups per comparison, as does the fill-block
  comparator.

- **F7 — An arbitrary runtime-determined key set is written in one statement.**
  `@{ $log_messages{$category}{$log_key} }{ keys %$stats } = values %$stats` in
  `calculate_all_statistics` writes whichever of the 21 statistic fields the #305 demand
  resolution produced. This is the most awkward site to port to a fixed column set.

- **F8 — Latent bug, out of scope here — filed as #428.** `mean_bytes` is an accepted
  `-so` operand (`$sort_key = "mean_bytes"` in `adapt_to_command_line_options`) but is
  **never written** to the entry — it is computed as a local in `print_message_summary`
  for rendering only. The comparator's `// 0` therefore makes every key tie, and the
  `$a cmp $b` tiebreaker alone decides the displayed order. `count_mean` has the same
  shape: it is derived in the group-calc loop, which runs *after* the sort in the same
  sub. Confirmed by observation — with `-so mean_bytes` the ascending run returns keys in
  plain lexicographic order, and with `-so count_mean` ascending and descending produce
  byte-identical output. Not folded into this work; a compact store that validates sort
  keys against a declared column set would surface this class mechanically.

- **F9 — `features/2-memory-ceiling-progressive-eviction.md` is deliberately absent.**
  Issue #2's 2026-08-24 comment states it will be created *starting from the #426 store*.
  The issue body's citation of that path is corrected to cite **issue #2** itself. The
  only existing written design for the columnar direction is one bullet — **F16** in
  `features/log-format-registry.md` — which self-declares provisional ("the scan sub's
  entry-creation contract is rewritten against that store when #426 lands").

- **F10 — #2's memory arithmetic is invalidated by this work and must be re-derived.**
  #2/#354 record 2,327 B per bin entry and 2,402 B per raw entry, of which `durations` is
  only ~75 B (3%) and ~2,252 B is "the per-message sidecar hash … and Perl hash
  overhead". That overhead is precisely what a compact store changes, so #2 cannot size
  its levers until this lands — which is why #2 is blocked by this issue.

- **F11 — Dead code adjacent to the store.** Four self-assignments of the form
  `$log_messages{...}{count_min} = $log_messages{...}{count_min} if defined ...`
  (`count_occurrences`, `count_min`, `count_max`, `count_sum`) in the group-calc loop are
  no-ops; the `count_mean` line between them is a real derivation. Two commented-out
  `undef`/`delete` lines for `durations` carry a 2026-01-04 TO DO. A rewrite removes the
  no-ops; they are noted so their disappearance is not mistaken for a behaviour change.

## Field census (mechanically derived, `09262f7`)

**36 field names reachable by full path**, plus **5 reachable only through the `$entry`
alias** (`_running_mean`, `m2_sum`, `m3_sum`, `m4_sum`, and the transient `bin_entry`).

| class | fields |
|---|---|
| Universal | `occurrences` |
| Aggregates | `total_bytes`, `total_duration`, `total_duration_num`, `sum_of_squares`, `impact` |
| Raw-mode sample store | `durations` (arrayref; **absent entirely under `-mdm bin`**) |
| Bin-mode sidecars | `duration_count`, `_running_mean`, `min`, `max`, and under shape demand `m2_sum`, `m3_sum`, `m4_sum` |
| Count family | `count_sum`, `count_occurrences`, `count_min`, `count_max`, `count_mean` |
| Statistics (21, demand-gated) | `min` `p50` `p95` `p99` `p999` `cv` · `mean` `max` `p1` `p75` `p90` `std_dev` · `p5` `p10` `p25` `p9999` `p99999` `iqr` · `skewness` `kurtosis` `bimodality_coef` |
| Marker | `is_consolidated` |
| Transient (never persisted) | `bin_entry` — attached from `%log_messages_counters` and detached inside `merge_log_message_entry_into_cluster` |
| Dynamic (per `@udm_configs` entry) | `udm_${name}_sum`, `_occurrences`, `_min`, `_max`, `_mean` |

Notes that matter for a fixed column layout:

- **`min` and `max` carry two provenances** — bin-mode producer sidecars *and* raw-mode
  calculated-statistics outputs. Same name, different writer.
- **`total_duration` is dual-typed**: numeric during accumulation, then overwritten with
  a *formatted string* by `format_time(...)` in the group-calc loop. (Issue #273 proposes
  collapsing this with `total_duration_num`; a compact store makes that collapse
  cheaper — see § Related issues.)
- **`udm_*_distinct` is NOT a field of this store.** Distinct-value tracking for counting
  aggregations lives in the bucket-scoped `%udm_distinct`. Verified — the `distinct`
  suffix appears in UDM name construction elsewhere and must not be mistaken for a
  per-message column.
- The `-so` operand vocabulary is **not** a subset of the stored columns (F8).

## `%log_messages_counters` — the coupled store

Flat, keyed `"$category\x1f$log_key"` — a flattened form of the two-level key. Values are
#189-shape bin entries `{partition, bins[], overflow, underflow}`. Populated only under
`-mdm bin`, and only for samples where `$duration > 0` (log-spaced partitions cannot
represent zero). Written by `counter_update` in the read loop and by cluster injection in
`group_similar_messages`; read by the population walk and the group-calc loop; deleted in
`merge_log_message_entry_into_cluster`; emptiness-tested and snapshotted by
`finalize_message_stats_unified`; sized in `named_structure_sizes`.

The two stores must stay key-synchronised through consolidation, and
`merge_log_message_entry_into_cluster` is the **only** place maintaining that invariant.
Any ordinal scheme must decide whether this store is re-keyed by ordinal too (Q7).

## Access-pattern classes

The inventory reconciles to **167** `log_messages` references in `ltl` at `09262f7`.

| class | where | volume | why it matters |
|---|---|---|---|
| **Per-line hot path** | `read_and_process_logs`: existence probe, lazy init, `occurrences`/`total_bytes`/count/UDM/duration writes, the aliased bin-sidecar block, `counter_update` | O(lines) | Sets the heap layout every later pass pays for. Any change here is measured before it is believed. |
| **Population walk** | `calculate_all_statistics` eligibility walk; `group_similar_messages` Pass 1/Pass 2; `run_consolidation_pass`; `print_verbose_output` entry count; the consolidation `-V` tally | O(distinct keys), several full passes | 47% of the statistics phase on the measured construct. |
| **Comparator** | available-value branch (stage-1 sort, cut-val read, tie extension, stage-2 sort); fill-block equivalents | O(n log n) field reads | 50% of the phase. Two two-level lookups per comparison. |
| **One-shot** | cluster injection; group-calc loop over top-N; `print_message_summary` render + MESSAGES CSV (~32 sequential per-key reads, none aliased); `named_structure_sizes`; telemetry | O(clusters) or O(top N) | Widest field surface; not performance-critical, but every field must remain reachable. |

## Demand and mode gating (inherited contract)

Two layers, both binding on any replacement.

**Store-level (#349)** — `$message_duration_stats_demand`, resolved once in
`adapt_to_command_line_options`: true when durations are produced (`!$omit_durations`)
**and** at least one consumer is active (messages-table statistics variant, or MESSAGES
CSV). `-hst` is display-only and does not suppress capture; `-V` creates no demand.

**Group-level (#305)** — `%STAT_GROUP_FIELDS` defines four groups over 21 fields
(`terminal_core`, `csv_body`, `extended_percentiles`, `shape_moments`); three cached
booleans gate the hot path. Both statistics primitives return **a hashref of only the
computed fields**, and the store site merges it, so undemanded fields are never written.

**The contract the replacement must preserve:** *undemanded fields are never written, and
absent fields read as `undef` with identical downstream semantics under `defined` / `//`
guards.* In a hash store this costs nothing. In a columnar store, an unwritten column
costs nothing only if its array is never instantiated — which argues for gating array
*existence* at option-resolution time rather than gating writes per line (Q3).

## Candidate representations

Specified for measurement, not chosen. Every arm is parity-asserted against arm A before
any timing. Per the 2026-08-21 baseline rule, **arm A is extracted from the production
code path verbatim** — call shape, variable scoping and data movement included; a
baseline wrapped in a convenience sub would measure the wrapper.

| arm | mechanism | rationale | what would falsify it |
|---|---|---|---|
| **A — baseline** | current store, production code verbatim | the reference | n/a |
| **B — comparator hoist** | precompute sort values into a flat array (Schwartzian); store unchanged | F5/F6 — attacks the 50% `sort_selection` block directly, ~20 lines, no data-model change | fails to close the comparator gap, or the extraction pass costs more than the lookups it saves |
| **C — entry aliasing** | hoist `my $entry` across the read loop's write block; store unchanged | F6 — removes repeated full-path resolution per line | no measurable read-phase gain; or it perturbs allocation order and moves the stats phase |
| **B+C** | both cheap fixes | the "is a new data model needed at all?" arm | closes most of the gap → D/E are not worth 167 touch points |
| **D — columnar (SoA)** | message→ordinal hash + per-field arrays | the issue's proposal; L2 says a denser layout is ~5× on traversal | write-side cost exceeds the traversal saving; or F3 deletion forces tombstones whose memory cost negates the win |
| **E — hybrid** | ordinal + packed hot numeric fields, hash for the cold/rare tail | mitigates F2's four variants and F7's arbitrary key set; keeps a hashref view cheap for F4 | complexity without a measurable advantage over D |

Two further columnar variants were added during the prototype: **D2** (one hash
operation per line — `//=` insert — and the ordinal→key column built with `keys` +
slices) and **D3** (D2 with the ordinal→key column written at insert time, a second
copy of every key string). E was folded into D: the lazy per-ordinal cold hash for
rare fields is never written on the fixtures, so D and E measure identically.

Prior art in this repo: `prototype/58-entry-struct-mini.pl` already compares
`aoh` / `hoh` / `aoa` / **`soa` (parallel arrays indexed by entry id)** across build,
memory and scan phases, asserting classification parity per shape before any timing. It
is the direct template. `features/58-format-registry-staged-detection.md` records the
closest methodological precedent for the ordinal idea itself: name→ordinal resolved once
at load, integers on the hot path.

## Open questions (the prototype's exit criteria)

Numbered so the later locked decisions map one-for-one. Status after the prototype
(2026-08-24; report section in parentheses):

| id | question | status |
|---|---|---|
| **Q1** | Does a columnar store actually realise the L2 traversal gain, or does L2 measure something (fresh contiguous hashes) that SoA does not reproduce? | **Answered (V1)** — yes, and beyond it: on the real as-built store, walk 5.7× and sort 10× faster than L0, 3× and 4.4× faster than L2. |
| **Q2** | What does the ordinal scheme cost on the write side, per line, at 1M lines? | **Answered (V2)** — indistinguishable from A on the single-field path (±3%, inside A's own spread); −14%/line on the multi-field access path, all of it aliasing. |
| **Q3** | Are column arrays allocated by demand at option-resolution time, or lazily on first write? What does an undemanded column cost in each case? | **Answered (V3)** — per family/demand at option-resolution time; an undemanded column that is never instantiated costs nothing and nothing is tested per line. |
| **Q4** | How is deletion represented — tombstones, compaction pass, or restructuring consolidation to avoid deletion? What is the memory and time cost of each under `-g` churn? (F3) | **Answered (V4)** — tombstones (cheaper than hash deletes, 0.23 vs 0.30 s at 287k) plus one 0.064 s compaction after the `-g` final pass; compacted store smaller than the hash's. |
| **Q5** | Does `merge_consolidation_stats` receive a materialized hashref row view, or is the merge surface rewritten? (F4) | **Deferred to implementation planning** — not a measurement question; consolidation is off the hot path. |
| **Q6** | How is F7's arbitrary runtime key set written into a fixed column layout? | **Deferred** — the lazy per-ordinal cold hash (E policy, folded into D) takes a hash-slice write unchanged; not exercised by the fixtures. |
| **Q7** | Is `%log_messages_counters` re-keyed by ordinal, or does it keep its `\x1f` composite key? | **Answered (V7)** — neither: it stops being a separate store. Partition state, overflow/underflow and the bins become columns on the record's row; the composite key and the two-store sync invariant go away. Measured output-identical (K2–K4). |
| **Q8** | Do the four variants (F2) get four column sets, or one superset with unallocated columns? | **Answered by Q3** — one superset of column *names*; only the demanded ones are instantiated. |
| **Q9** | Does the two-valued category (F1) fold into the ordinal space, or stay a separate dimension? | **Measured in one shape only** — separate per-category stores, the handle selected in the branch that assigns `$category` (zero per-line cost); folding was not measured. |
| **Q10** | Do B/C alone close enough of the gap that D/E are not justified? | **Answered (V5)** — no: B is *slower* than A at 287k keys; C is a write-side gain only. |
| **Q11** | What happens to `MEMORY log_messages` attribution, which #2 consumes as a controller signal — is per-column attribution preserved? | **Deferred** — `Devel::Size` per column is trivially available but overcounts the HEK-sharing key column (V3); the attribution rule is #2's to specify. |
| **Q12** | ~~How much of the 465 B/key is the key string, and therefore untouched?~~ Answered at spec stage: inner entry hash 213.0 B (45.8%); keys + outer hash 251.6 B (54.2%). Residual: does the compact store's own per-field array overhead eat into the 45.8%? | **Residual answered (V3)** — yes, ≈ 80 B/key; realised saving −25% RSS at 287k keys (≈ 62% of the ceiling). |

## Measurement protocol (for the prototype stage)

- **Scaffold**: reuse `prototype/58-measure.pm` verbatim — one untimed warmup pass, then
  N timed runs; report **median with min–max range**; TSV
  `candidate / fixture / lines / metric / median / min / max`; `Devel::Size::total_size`
  and RSS delta as their own metric rows.
- **Staging**: 1k → 10k → 100k → 1M, per the CLAUDE.md prototype rule.
- **Fixture**: high-cardinality, derived from the `humungous-log-uniqueness` source
  (`ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log`, 286,659 distinct keys) —
  deterministic slices, no sampling, in the shape of `prototype/58-generate-fixtures.sh`.
- **Parity before timing**: every arm reproduces arm A's records field-for-field; die on
  first divergence with a formatted diff.
- **Metrics**: build cost (`ns_per_line`), population-walk cost, comparator cost,
  `Devel::Size`, RSS delta, and **deletion cost under `-g`-like churn as its own metric**
  (Q4).
- **Reporting**: `prototype/426-*-validation-report.md` in the per-aspect shape of
  `prototype/189-bin-counter-primitives-validation-report.md` (Hypothesis / Method /
  Result / Surprises / Findings and actions / Reproduction).
- **Exit**: medians with ranges for every arm; Q1…Q12 answered or explicitly deferred;
  `Dxx` locked only where a measurement grounds them. Findings are delivered as an
  attributed analysis **before** any keep/revert or scope question.

## Prototype findings (2026-08-24)

Report: `prototype/426-per-message-store-validation-report.md` (per-aspect V1–V6,
medians with ranges, reproduction commands). Instruments: `prototype/426-store-mini.pl`
(arms A/B/C/D/D2/D3, one arm and one fixture per process, cross-arm parity digests),
`prototype/426-asbuilt-probe.pl` (injected into a throwaway `ltl` before
`calculate_all_statistics();` — measures the real as-built store), fixtures from
`prototype/426-generate-fixtures.sh`. Results: `prototype/426-results/`.

- **F12 — The columnar shape beats the ladder's floor on the real heap.** Inside `ltl`
  on the 286,659-key construct: walk L0 0.260 s / L2 0.135 s / columnar 0.046 s; fill
  sort 0.236 / 0.101 / 0.023 s. The probe's L0 shapes match ltl's own `population_walk`
  0.254 and `sort_selection` 0.245 from the same process within 3%.
- **F13 — Write side is neutral where it matters and −14% on multi-field entries.**
  Non-access path: D/D2/D3 within ±3% of A at 100k and full (A's own min–max spread is
  ±5–8%). Access path: C, D, D2, D3 all −13…−15% per line at 10k/100k/1M — the gain is
  the single resolution of the entry per line (F6), available to any store shape.
- **F14 — Memory −24% RSS at 287k keys** (146–149 → 111.4 MB); D's own per-key overhead
  ≈ 80 B (ordinal column + HEK-sharing key column). `Devel::Size` overcounts the key
  column (79 MB reported, ≈ 14 MB real) — RSS is the truth for this store.
- **F15 — The comparator hoist (arm B) is falsified.** Within run-to-run noise of A
  at 287k keys (−8% / +3% in the final matrix, +19% / +44% in the previous) against
  the columnar store's 15×: the extraction pass dereferences every scattered entry
  once — the cost the ladder measured — and adds list/array construction on top. B
  wins only where the keys are not all tied and the sort does O(n log n)
  comparisons (0.41× at 10k).
- **F16 — Deletion: tombstones are cheaper than hash deletes** (0.23 vs 0.30 s for
  258k deletes + 2.9k injects); compaction 0.064 s at 287k; the compacted store is
  smaller than the hash's post-delete store; tombstoned traversals are still 1.6×/9×
  faster than the hash's.
- **F17 — The ordinal→key column is the columnar store's one real overhead**: 0.13 s
  at 287k keys to materialise the hash's keys once (450 ns/key — the same cost A pays
  inside `foreach (keys %{…})`). Writing it at insert time instead (D3) costs +29% RSS
  (+80 MB) and makes the tiebreaker sorts 2.4× slower. Total columnar traversal on the
  construct: 0.040 + 0.130 + 0.023 = 0.19 s vs A's 0.54 s.
- **F18 — D2's single hash operation per line is not measurably faster than D's two**;
  it is the cleaner hot-path shape, not a performance decision.
- **F19 — Bin mode: the counter store is the dominant per-message cost, and its bins
  array is the lever** (report V7). Today, at 287k keys with durations: record 344 MB
  (1,200 B/key), counters 683 MB (2,383 B/key — #354's figure reproduced), 1.13 GB
  RSS, 23 s for the `-so p99` population pass. Counters keyed by row as columns on
  the record store with span-only bins (`[base_index, counts…]`): 455 MB RSS, 2.15 s,
  output-identical; on the real DPM log 17.4 → 11.0 MB and 0.350 → 0.073 s. The read
  loop is 25% cheaper per line (the composite key string and the primitive call
  shape are on the per-line path today).
- **F20 — `count_*` is a hot column family on ScriptLog data** (every line carries
  `count=`), so P7's cold-hash policy must not cover it: columns are instantiated when
  the count producer is active (`!$omit_count` and a format with count in its
  message). Found because the first bin-mode fixture keying missed production's
  `count=` mask and thread-pool reduction; both are now reproduced exactly.
- **F21 — Shared log-spaced grid** (report V8): against the exact percentiles on the
  DPM log, at least as accurate per message as today's per-key partitions (lower
  median error at every quantile; the one-bin bound held at p95–p999 where today's
  widenings break it at p95) and strictly better after merging (one-bin bound held on
  100% of merged pairs vs 94.5% — today's union remap costs up to 1.5 bins at p99).
  82% of merges needed a remap. Adaptivity is preserved (no range up front; span grows
  on demand; counts never move). Reopens #187 D5 — architect's decision.
- **F22 — Columnar tombstoning is slower than hash deletion in bin mode** (1.3–1.6 vs
  1.0 s for 258k deletes): `undef` into 26 columns per row. A dead-row bitmap instead
  of per-column undef is the obvious fix; not measured.

### Proposed decisions (NOT locked — for the architect)

Each is grounded in a report section; none takes effect until locked as `Dxx`.

| # | proposal | grounded by |
|---|---|---|
| P1 | Replace the per-message entry hash with per-category ordinal stores: `message → ordinal` hash + one array per demanded field. | V1, V2, V3 |
| P2 | Columns are instantiated per family and demand group at option-resolution time (one column on the non-access path; seven on the raw access path; bin sidecars as further columns); no per-line existence tests. | V3 (Q3/Q8) |
| P3 | Deletion is a tombstone (undef the ordinal's occurrences slot, delete the hash entry); one compaction pass (in-place column slices + in-place renumbering of the ordinal hash) runs at the end of the `-g` final pass. Field-level `delete` (#330) becomes an `undef` of the slot. | V4 (Q4) |
| P4 | The ordinal→key column is built after the read loop from the hash's own keys (HEK-sharing scalars), lazily on first consumer need, per category; never written at insert time. | V6 |
| P5 | The category dimension stays a separate store per category; the store handle is selected in the branch that assigns `$category` (zero per-line cost). | V2 (Q9, one shape) |
| P6 | Arm B (comparator hoist) is rejected; the aliasing of arm C is adopted by construction in the columnar write block. | V5 (Q10) |
| P7 | Rare and arbitrary fields (udm_*, the 21 statistics outputs on top-N keys, `is_consolidated`) go to a lazily created per-ordinal cold hash — the E policy — so F7's hash-slice write stays a hash-slice write. `count_*` is excluded: it is a hot column family, instantiated when the count producer is active (F20). | design; not exercised by the fixtures (Q6) |
| P8 | Under `-mdm bin` the counter store is not a separate keyed hash: partition state, overflow/underflow and the bins are columns on the same row as the record (Q7). `%log_messages_counters`, its composite key, and the `bin_entry` attach/detach in `merge_log_message_entry_into_cluster` disappear. | V7 |
| P9 | Bins are stored span-only — `[base_index, c0, c1, …]` covering the occupied indices — with the verbatim geometry and percentile arithmetic. | V7 (K4: output-identical, 4.8–10.6× on the population pass, 2.5–4.9× less counter memory) |
| P10 | **Proposal requiring #187 D5 to be reopened**: one log-spaced grid per store (`index = floor(bpd × log10(value))`), shared by every message and time bucket; per-key storage is the occupied span; merge is an index-wise add; no per-key partition state, no widening remap. | V8 (fidelity ≥ today per key, strictly better after merge) |

Not covered by the prototype and carried to implementation planning: Q5 (merge
surface), Q11 (per-column memory attribution for #2), the dead-row bitmap (F22), and
the time-bucket stores under P10 (same shape, bounded cardinality — not measured).

## Next step — revalidating the bin-counter primitives (#189) before implementation

**The tension.** The histogram bin-counter primitives (`partition_new`, `bin_assign`,
`partition_extend`, `partition_rebin`, `bin_boundary`, `counter_update`, `percentile`,
`merge_bin_counter_entries`) were designed under #187 (locked decisions in
`features/187-histogram-bin-counter-percentiles.md`, D5 in particular: per-key
partitions seeded on the first sample, HdrHistogram doubling on out-of-range) and
validated under #189 through `prototype/189-bin-counter-primitives.pl` and its report
`prototype/189-bin-counter-primitives-validation-report.md`, across five aspects:
calculation accuracy against the `calculate_statistics` oracle (its V5), in-bin
formula edge cases with the R2 cross-check (V1), the seeding heuristic and the
overflow/underflow audit (V3), per-key fan-out at scale with the R2 algorithm benchmark
(V2), and the `-V` percentile-mode output (V4). Those results attach to the primitives
*as they operate on today's containers and geometry*.

This prototype's bin-mode arms (K2–K4, report V7) re-container those primitives
without changing their arithmetic and are digest-identical to production, so the #189
validation carries over to them by construction. **P10 (the shared grid) does not**: it
is a different geometry, and this prototype's fidelity probe (report V8) covers only
the accuracy-against-exact aspect, on one log. The other #189 aspects — edge cases,
seeding/overflow audit, fan-out at scale, `-V` output — have not been exercised against
a shared grid, and the #187 decisions that the shared grid would replace have not been
re-examined.

**Decision (architect, 2026-08-24).** Implementation of the store proposed here is not
blessed until the bin-counter primitives have been revalidated for the proposed
representation:

1. Read `prototype/189-bin-counter-primitives.pl`, its report, and the #187 decision
   record; list every validation aspect and every locked decision the columnar /
   span-only / shared-grid representation touches.
2. Build the prototypes for those aspects against the proposed representation, in the
   approach used here (production primitives verbatim as the baseline arm; parity
   digests before any timing; medians with ranges; the exact-percentile oracle), and
   go through **all** of them, not the accuracy aspect alone.
3. Adjust the primitives where the prototypes say to; record the outcome as `Dxx`
   decisions here and, where a #187 decision changes, as an explicit amendment there.
4. Only then: the blessing to try the implementation of P1–P10.

The raw-mode decisions (P1–P7) do not depend on the primitives, but the
implementation is one change to one store; it waits for step 4 rather than shipping a
store the bin path then has to be retrofitted onto.

### Step 2 delivered — revalidation findings (2026-08-24)

Report: `prototype/426-bin-primitives-revalidation-report.md` (the step-2 artifact;
per-aspect V1–V5 sections mirroring #189's report, a per-decision table for every
#187 lock and #189 requirement under S and G, consolidated findings A–K, proposed
amendments A1–A11, what the evidence does not cover, full reproduction recipe).
Instruments: `prototype/426-revalidate-lib.pm` (arms T / S / G behind one store
interface, production primitives verbatim, ltl-exact parsers, oracle, digests),
`prototype/426-revalidate-v{1..5}.pl` with drivers; captures under
`prototype/426-results/revalidate-*`. Every aspect was independently verified against
its captured files (verdict recorded per section); the large per-row TSVs
(`revalidate-v5-{key,small,pair,fold}-*.tsv`, `revalidate-v3-partA-perkey-*.tsv`) are
regenerated by the reproduction commands and are not committed. Cross-references:
`features/189-histogram-bin-counter-primitives.md` § Revalidation under #426.

Arms: **T** today (verbatim); **S** = P8+P9 (span-only columns, verbatim geometry);
**G** = P10 (shared log-spaced grid, span-only). Surfaces: the #189 primary file
(277 MB Tomcat, 4,153 keys), the #189 fan-out file (51,469 keys), the 2.6 MB
iteration file (635 keys).

- **F23 — S is digest-identical to T everywhere exercised** (fill, percentile, merge,
  fold digests at bpd 53 and 616 on 4,153 and 51,469 keys; every hand-built V1/V3
  scenario including the growth cap and the 0 / −5 failure modes; the `-V` section
  byte-identical to real ltl with `counter_memory_bytes` masked). **P8+P9 inherit #189's
  validation by construction**; every #187 lock and #189 requirement holds under S
  verbatim.
- **F24 — The Decision 1 walk is grid-agnostic.** 92/92 edge cases at both bpd on G;
  same `bin_count=1 → upper`, unreachable `fraction=0`, same rank-convention
  crossover at bpd ≈ 256 as #189 found. D1/D1A/D3 unchanged under G.
- **F25 — The geometric-midpoint remap is the only mechanism by which today's
  primitives exceed the R4 one-bin bound, and G has none.** Per key T fails one
  N ≥ 100 key at bpd 256 (0.934% vs 0.904% — a row #189 V5 tabulated and marked
  pass); after merges T needed a remap on 73% of 1,258 pairs / 88% of 2,198 fold
  steps, worst 1.35–2.06 bins, within-one-bin down to 78%. G: `binning_max` equals
  the bound to four decimals, 100.00% within one bin per key, small-N, after 1 and
  after 7 merges, at 53/115/256/616. #426 V8's claim holds on the #189 surface.
- **F26 — Under G, D4 (overflow/underflow, audit), D5 (seed, doubling, rebin
  telemetry) and R6 are vacuous, not violated**: every positive value has an index
  (1e-320..1e308); counters identically 0; audit constant `none`. Span telemetry
  replaces rebin telemetry: p50/p95/p99/max 1/26/78/175 @53, 1/294/907/2028 @616 on
  4,153 keys; 0 keys exceed T's seed; Σ slots 2.4–2.7% of T's Σ `bin_count`. No growth
  cap is needed (span ≤ bpd × decades-of-data + 1; worst case 1..1e9 is 0.72× T's
  doubled partition and 0.43× its bytes).
- **F27 — G is insertion-order-independent and merge-commutative; T is neither**
  (T differs on 105/200 keys across orderings, up to 0.99 bins; G 0/200). #189 R5
  (fixed-sequence determinism) holds for both.
- **F28 — The `v > 0` guard is load-bearing for every representation.** The verbatim
  `partition_extend` never terminates on a negative value and dies on 0 after 130
  doublings; G dies immediately. Every ltl call site is gated `> 0`; the P8–P10 store's
  add path must carry the guard.
- **F29 — G's closed form `floor(bpd × log10 v)` is one index low at exact powers of
  ten** (1 of 985 values, 38 of 857,480 observations, identical at four bpd); the value
  is the closed bin's upper boundary so attribution error is zero. A convention
  (closed form vs boundary-checked) defines the bin-mode digest baseline.
- **F30 — D8 survives S unchanged; five fields are inert under G** (`total_rebin_events`,
  `max_partition_bins`, `partitions_with_{over,under}flow_count`,
  `rebins_per_partition`) plus a constant audit line. A replacement block (`grid_bpd`,
  `grid_index_range`, `span_slots`, `counter_slots_total`) is rendered as a proposal.
  Pre-existing drift found: no `--exact-percentiles` / `opt_out_*` in today's emitter;
  two #189 V4 scenarios unreachable since #293.
- **F31 — Fan-out cost (51,469 keys, medians of 3).** Memory per key Devel::Size / RSS:
  T 2,381 / 2,428 B @53 (reproduces #189 V2 exactly: 116.86 MB, 227 MB at 10⁵ keys),
  13,730 / 15,761 @616; S 955 / 598 and 1,173 / 833; G 600 / 198 and 817 / 452. T's
  5.8× growth from 53 to 616 is its dense array seeded to the partition centre
  (133 / 1,540 NULL-but-one slots per single-sample key), not the data (span p50 = 1
  at both bpd). Fill ns/sample T 1,471 / S 1,026 / G 635; percentile µs/eval
  20.7 / 2.64 / 2.19 @53, 209 / 3.53 / 2.84 @616. The `-g` fold (51,468 merges):
  T 3.28 / 33.2 s, S 5.87 / 60.5 s, G 0.093 / 0.117 s — S is slower than T because the
  prototype's S merge materialises dense views to run the verbatim
  `merge_bin_counter_entries` (a harness shape; a native span merge is O(occupied
  span), the shape G already has). T and G's folded quantiles differ ≤ 0.61 bins after
  51,468 merges. #187 D2's ~212 MB guidance and #189 V2's Perl-overhead note describe
  T's layout only.
- **F32 — Span-array memory depends on fill direction** (3–4× for the same span) until
  downward growth extends with `undef`, not `0` — an implementation note for P9/P10.

**Proposed amendments (NOT locked — for the architect).** The report's
§ Proposed amendments lists A1–A11 with grounding: A1 D5 → shared grid (P10 only);
A2 D4 vacuous (P10 only); A3 D8 field set (P10 only); A4 R4 wording — the structural
bound holds only while no remap has occurred (regardless of P10); A5 #189 V5 finding 1
correction (327 of 328 at bpd 256); A6 the `> 0` guard is contract; A7 G index
convention; A8 `undef` downward fill; A9 `lower = upper` unreachable; A10 D7/D8 vs
shipped emitter drift; A11 D2 memory guidance is T-layout-specific.

### Framing correction and the locked objective (2026-08-25)

Three false premises were carried into the 2026-08-25 session and corrected against the
corpus. They are recorded because each one, left standing, points the work at the wrong
question:

1. **The heatmap and histogram counter stores are NOT out of scope.** An earlier revision
   of this document said they were, in two places. That was drafting text written while
   specifying (commit `eb53b3c`), never an architect's decision, and it was withdrawn
   2026-08-25: a data-model redesign is analysed across all of the data structures.
2. **A shared substrate does not need to be invented — it already ships.** All four
   bin-counter surfaces run one algorithm, one lifecycle, one in-bin rule and one
   out-of-range handling; `%TIER_BPD` and `bpd_for_surface()` resolve every surface's
   resolution from the single `--data-model-precision` / `-dmp` lever. Resolution is the
   only thing #187 permits to differ per surface (Decision 2 as amended by #289 and #293).
3. **`buckets_per_decade` 616 is not a tunable knob.** It is HdrHistogram's
   3-significant-digit latency-tracking reference (2048 sub-buckets per doubling ÷
   log2(10)), the top rung of a tier ladder whose rungs are external standards — 53 is the
   OpenTelemetry Scale-4 analog, 115 is DDSketch at 1% relative accuracy. It was arrived at
   through hard-won work on preserving visible modality and edge distinction in the
   rendered display (architect, 2026-08-25). Changing it would require an enormous set of
   retesting and rework and is **out of scope for this issue**, which retains the same
   operation, functionality and settings. The corpus for all of this is
   `features/187-histogram-industry-grounding.md` (the literature pass) and
   `features/187-histogram-bin-counter-percentiles.md` (the decisions it grounds); both are
   read before any statement about resolution is made.

**Locked objective (architect, 2026-08-25): replace the container, and measure what the
container change does to the constraint.** The per-message row sits at a coarser
resolution than heatmap and histogram for one stated reason — cardinality. #187's memory
model puts today's dense layout at ~2.1 KB per partition and ~212 MB per 10^5 keys at
bpd 53, against ~25 KB and ~2.5 GB at bpd 616, and the per-message surface has unbounded
partition count while the display surfaces have ~70 between them. The candidate
containers attack exactly that: F31 measured per-key cost falling from 2,381 B (T) to
955 B (S) and 600 B (G) at bpd 53, and — the load-bearing part — growth across the tier
ladder of 5.8× for today's dense array against 1.2× (S) and 1.4× (G).

So the work is: prove the replacement gives the same answers at the same settings across
all four surfaces, **and** report what the per-message row could afford once the container
is cheap. The second half is evidence handed to the architect, **not** a proposal to change
`%TIER_BPD` — that table is locked and the decision is his alone. Nothing about the
display surfaces' settings, geometry or rendering is in question.

**Not scheduled.** The architect locked the objective on 2026-08-25 and deferred the work
to a later session. Nothing below is started.

### Do this first, next session

Before any prototype code, run the audit that should have preceded this session's framing
(the mechanical gate now recorded in CLAUDE.md § observations, 2026-08-25):

1. **Enumerate the impacted surfaces from the code** — for each row of `%TIER_BPD`
   (`histogram`, `heatmap`, `bucket-stats`, `message-stats`): the globals holding its
   counters, the capture site, the finalize/consume site, its partition keying, its
   cardinality profile, and whether it finalizes into display geometry.
2. **Map each surface to its governing research and locked decisions** — at minimum
   `features/187-histogram-bin-counter-percentiles.md` (+ the industry-grounding companion),
   `features/189-histogram-bin-counter-primitives.md`,
   `features/201-display-geometry-bound-consumers.md`,
   `features/293-precision-lever-unification.md`, `features/289-*`, `features/34-*`,
   `features/349-*`. Record decision identifier + what it decides in plain language.
3. **Enumerate the blast radius of a container change** — the primitives, every caller, the
   `-V` emitters and telemetry snapshot, any serialization, and every `tests/validate-*.sh`
   that asserts on bin-counter output (with what each asserts).
4. **Extract the invariants any replacement must preserve** verbatim — mass conservation,
   peak preservation, determinism, the #201 fidelity invariant (no cross-bin mass
   splitting at any stage; geometric-midpoint projection only), out-of-range semantics,
   the #187 Decision 8 `-V` field-name stability contract, and merge semantics.

Only then design the measurement. The N1–N8 table below predates this framing: it is the
list of uncovered aspects, still valid as gaps, but N1's build must be re-derived from the
audit rather than taken as written (it was drafted while the heatmap/histogram surfaces
were wrongly believed to be out of scope).

**Not yet covered — IN SCOPE, the next prototype work (architect, 2026-08-24).** The
report's § *What the evidence does not cover* is not a boundary; every item in it is
part of step 2 and is prototyped and analysed before step 3 begins. Nothing is skipped.
The resumption plan, in the order to take them:

| # | gap | what to build / measure | surfaces |
|---|---|---|---|
| N1 | **Display-geometry-bound consumers under S and G** — F2 heatmap (`heatmap_cells`, `heatmap_markers`, per-`time_bucket` keying), F3 histogram (`histogram_view`, `histogram_bins`, per-metric global keying); #187 D5's F2/F3 stream → finalize-rebin contract; #189 R12 `partition_rebin` as the finalize step | A V6 aspect: the same three arms keyed by time bucket and globally; the F2/F3 finalize re-bin (`partition_rebin` to display geometry) from T/S, and its G equivalent (grid span → display bins); parity of finalized cells/markers/bins T↔S; fidelity of G's finalized display against T's and against the exact values (mass retention, peak retention, peak X-offset — the #201 measures); `-hm` / `-hg` `-V` sections from each arm vs real ltl. Reads `features/201-display-geometry-bound-consumers.md` and `prototype/201-projection-comparison-report.md` first. | 148 MB Tomcat (#201's canonical), 2.6 MB iteration file |
| N2 | **Native span-array merge for S** (P9) | Write the O(occupied span) merge (remap source span into target span directly; no dense view, zero-fill, or full-width add) and re-run V2's merge-pair and `-g` fold measurements for S; T↔S digest parity on merge/fold must still hold | fan-out file (51,469 keys), bpd 53 / 616 |
| N3 | **Second log surface for V1 / V3 / V5** | Re-run the three aspects on the DPM ScriptLog (the #426 V7/V8 fixture; ThingWorx keying, real durations, 3,421 keys) and on the 148 MB Tomcat file; the power-of-ten spike behaviour (V5 § F) and the R2 disagreement set (V1 Part B) characterised on more than one data shape | DPM ScriptLog, 148 MB Tomcat |
| N4 | **Real ltl end-to-end under G** | A throwaway `ltl` carrying the grid on the summary-table path (probe-injection as `426-asbuilt-probe.pl` did), enumerating the per-baseline percentile shift in `tests/validate-*.sh` bin-mode baselines — the re-bless the architect would sign | the harness fixtures |
| N5 | **Merge shapes beyond consecutive pairs and the `-g` fold** — time-bucket and global rollups; keys with disjoint value ranges | Add to V2/V6: rollup merges keyed by bucket → global; pairs chosen for disjoint spans; time and accuracy per arm | fan-out file, 148 MB Tomcat |
| N6 | **Fan-out beyond 51,469 keys** | Build a ≥ 10⁵-key store per arm (the synthetic `bin-twxdur` fixture from `426-generate-fixtures.sh` has 286,659 keys with durations) and measure directly instead of projecting | `bin-twxdur-full` |
| N7 | **`-V` audit aggregation scope** | Aggregate `out_of_range_bounded` over the keys the statistics pass walks (as ltl does), not every key, under the growth cap where the audit fires; show identical to ltl | 2.6 MB file |
| N8 | **Memory measure** | RSS delta per arm-process is the number of record; report Devel::Size only alongside it, and note its seed dependence for hash-backed stores | all |

**Resumption notes for the next session.** Start here, not from the issue thread.
Branch `426-per-message-statistics-store`; the work lives in
`prototype/426-revalidate-lib.pm` (add arms/keying there — one interface for T/S/G;
read its header for the API and gotchas), new aspects as
`prototype/426-revalidate-v6.pl`… with a `.sh` driver each, captures under
`prototype/426-results/revalidate-vN-*`, results markdown per aspect, then fold into
`prototype/426-bin-primitives-revalidation-report.md` (new aspect sections, the
per-decision table, findings, § not covered shrinks). Protocol unchanged: production
subs verbatim as arm T, parity before timing, medians of 3 with ranges, oracle,
independent verification of every aspect against its captured files, every number
traceable to a capture. `logs/` is a symlink to the shared corpus in the main checkout
(recreate with `ln -s ../../../logs logs` from the worktree; never commit it). The
large per-row TSVs are regenerable and stay uncommitted. Subagents run on Opus 5 at
medium effort. When N1–N8 are shipped, the findings (F23–F32 and the new ones) are
iterated on with the architect before any step-3 decision is asked for.

**Step 3 is the architect's**, after N1–N8. Nothing above is a `Dxx`; P1–P10 remain
proposals.

## Pre-prototype audit (2026-08-25)

Produced in four parts per § *Do this first, next session*, then reconciled. Every claim is
anchored to a file + sub name + grep-able snippet; line numbers are omitted deliberately
(they drift). Contradictions between the four independently-produced parts were verified
against the tree at branch `426-per-message-statistics-store` and are resolved in-line,
not papered over.

### Reconciliation of contradictions between the four parts

| # | Disagreement | Resolved fact (verified) | Which part was wrong |
|---|---|---|---|
| R1 | Part 1 lists **8** histogram `counter_update` sites; Part 3 says **7** | **8** — `duration`, `bytes`, `count`, UDM, each ×(main, `_hl`). Anchor: `counter_update(\%histogram_counters, 'duration', $duration, $histogram_stream_bpd);` and its seven siblings in `read_and_process_logs()`. Total across all surfaces: **14** (1 message + 1 consolidation `%tmp` + 2 bucket + 2 heatmap + 8 histogram) | Part 3 (miscount) |
| R2 | Part 3 "breaks LOUDLY #4": histogram golden renders are **not** pinned to raw, so a bin-geometry change fails `validate-regression.sh` byte-compare | **False.** Every `hg-*`, `hl-histogram-*` and `heatmap-*` scenario in `tests/validate-regression.sh` carries `-dm raw` (e.g. `run_test "hg-duration-w160" "$LTL" $COMMON -dm raw --terminal-width 160 -hg duration "$APACHE_LOG"`). The whole render-regression suite is fenced off the bin path. This **moves the item from "breaks loudly" to "breaks silently"** — and makes the *bin* histogram render as uncovered as the bin heatmap render | Part 3 |
| R3 | Part 4 flags `=== BIN-COUNTER MODE ===` vs shipped `=== histogram-bin-counters ===` as un-amended D8 drift; Part 2 treats D8's section-name lock as satisfied by the 2026-05-20 amendment | **Part 4 is right.** `grep -n '=== BIN-COUNTER MODE ===' features/187-*.md` returns 8 hits including the amendment text itself ("section name changed from `=== PERCENTILE MODE ===` to `=== BIN-COUNTER MODE ===` … All field names … remain in effect verbatim"). `ltl` emits `push @verbose_output, "=== histogram-bin-counters ===";`. A **second, later rename shipped and was never recorded in D8** | Part 2 (understated) |
| R4 | Part 2 A9: cites V1 finding 2 as grounding for "`lower = upper` unreachable" | Neither `lower = upper` nor `fraction = 0` nor `rank_in_bin = 0` appears in `prototype/189-bin-counter-primitives-validation-report.md` (`grep` returns nothing). **The A9 grounding pointer cannot be located in the cited report at all** — weaker than Part 2's "points at a different finding". A9 must be re-grounded before consideration | Part 2 (charitable); the citation is not merely mismatched, it is absent |
| R5 | Part 2 lists `features/349-*`, `354-*`, `323-*` as expected docs | Confirmed absent: `ls features/ \| grep -E '^(349\|354\|323)'` returns nothing. #349's contract survives only inside `features/305-*.md` § *Store-level demand*. **Step 2 of the audit brief cites a `features/349-*` that does not exist** | Neither part wrong; the brief is |
| R6 | Part 3 says the clamp is documented in #289 and absent from #287 R3.2; Part 4 says the same | **Confirmed and it is worse than either states.** `grep -in clamp` over the three docs: #289 has `clamped to [min,max]`; #187 has **zero** hits; #287's only `clamp` hit is about std_dev cancellation, unrelated. So the `[min,max]` percentile clamp in `calculate_statistics_bin` (`# Clamp interpolated percentile values to the observed [min, max].`) is documented **only** on the bucket-stats surface, and is undocumented on the message-stats surface #426 replaces | Both correct, jointly under-stated |
| R7 | Part 1: message-stats capture is the only site omitting `$bpd_override` | **Verified.** `counter_update(\%log_messages_counters, "$category\x1f$log_key", $duration);` — three args. Every other site passes a bpd. Also verified the consolidation site is likewise three-arg: `counter_update(\%tmp, '_single', $duration);` — so **two** sites rely on the default, not one | Part 1 (minor: "only" → "one of two") |
| R8 | Part 2 records `%bucket_stats_counters_hl` as store-parity-only; Part 1 says write-only | **Both correct, same fact.** Exactly three references in `ltl`: the declaration, `counter_update(\%bucket_stats_counters_hl, …)`, and `bucket_stats_counters_hl => Devel::Size::total_size(\%bucket_stats_counters_hl)` in `named_structure_sizes()`. No consuming read | — |

---

### Verification table — load-bearing claims spot-checked against source

| # | Claim | Verified? | Evidence |
|---|---|---|---|
| V1 | `%TIER_BPD` has exactly four surfaces with the stated rows | ✅ | `ltl`, GLOBALS: `'message-stats' => [ 4,  8,  16,  32,  53,  80, 115, 256, 616],` — four keys, values exactly as Part 1 reports |
| V2 | `bpd_for_surface()` has exactly four callers, all in `adapt_to_command_line_options()` | ✅ | `grep -n bpd_for_surface ltl` → declaration + `$percentile_buckets_per_decade = bpd_for_surface('message-stats');` and three siblings, contiguous |
| V3 | message-stats and bucket-stats default to `raw`; heatmap/histogram to `bin` | ✅ | `$message_stats_capture_mode = choose_data_model('message-stats') // 'raw';` vs `$heatmap_capture_mode = choose_data_model('heatmap') // 'bin';`. Mirrored at the surface-registry site (`data_model => choose_data_model('histogram') // 'bin',`) |
| V4 | `partition_rebin` has six call sites: 2 merge, 2 heatmap finalize, 2 histogram finalize | ✅ | `grep -n 'partition_rebin(' ltl` → 6 hits: two in `merge_bin_counter_entries`, two in `finalize_heatmap_unified`, two in `finalize_histogram_unified` |
| V5 | `merge_bin_counter_entries` rebins **both** sides into a union geometry (not #287 R2.3's "extend the narrower") | ✅ | `my $union_bin_count = int($bpd * $union_decades);` then two guarded `partition_rebin(...)` calls, then `for my $i (0 .. $union_bin_count - 1)`. Sole caller: `merge_bin_counter_entries($target->{bin_entry}, $source->{bin_entry});` inside `merge_bin_state` |
| V6 | `sub percentile` clamps `$target_rank` to `[1, total_N]` — undocumented | ✅ | `my $target_rank = POSIX::ceil($q * $total_N);` immediately followed by `$target_rank = 1 if $target_rank < 1;` / `$target_rank = $total_N if $target_rank > $total_N;`. No doc hit |
| V7 | The `-V` section shipped name is `histogram-bin-counters`, not D8's `BIN-COUNTER MODE` | ✅ | `ltl`: `push @verbose_output, "=== histogram-bin-counters ===";`; `features/187-*.md` § D8: "Section header: `=== BIN-COUNTER MODE ===`" |
| V8 | `--exact-percentiles` / `opt_out_active` / `opt_out_notice` / `consumers_active` have **no emission site** | ✅ | `grep -n 'consumers_active\|opt_out_active\|opt_out_notice\|exact-percentiles' ltl` → **zero hits**. All four are locked D7/D8 clauses with no implementation |
| V9 | `validate-regression.sh` pins **all** heatmap AND histogram scenarios to `-dm raw` | ✅ | 22 `run_test` lines carry `-dm raw`, covering `heatmap-*`, `hg-*`, `hm-hg-*`, `hl-heatmap-*`, `hl-histogram-*`. Comment: "`-dm raw` pins these to the sort-and-index path so the reference…" |
| V10 | No bin/partition/counter state is serialized anywhere | ✅ | `tests/validate-index-read-back.sh` contains zero `bins` references; `write_index_file()` columns are scalar aggregates only |
| V11 | `named_structure_sizes()` names all seven counter stores individually | ✅ | `heatmap_counters`, `heatmap_counters_hl`, `bucket_stats_counters`, `bucket_stats_counters_hl`, `histogram_counters`, `histogram_counters_hl` — plus `log_messages_counters` |
| V12 | `validate-distribution-shape.sh` is raw-only by declared scope | ✅ | Header: "Scope (per #254): raw-array data model only (the default per-message-key…" |
| V13 | `features/349-*`, `354-*`, `323-*` do not exist | ✅ | `ls features/ \| grep -E '^(349\|354\|323)'` → empty |
| V14 | A9's grounding (`lower = upper` / `fraction = 0` / `rank_in_bin = 0`) is not in the #189 validation report | ✅ | `grep -n` for all three strings over `prototype/189-bin-counter-primitives-validation-report.md` → zero hits |

---

### Part 1 — Impacted surfaces

Four surfaces, one per `%TIER_BPD` row. All capture in `read_and_process_logs()`.

| Surface | Counter globals | Capture gating | Consume sub | Partition key | Cardinality bound | rebin at finalize? | Display-geometry-bound? | Default model |
|---|---|---|---|---|---|---|---|---|
| **histogram** | `%histogram_counters`, `%histogram_counters_hl`, `%histogram_data_min/_max` → `%histogram_stats`, `%histogram_boundaries`, `%histogram_buckets` (+`_hl`) | `$histogram_enabled` × mode `bin` × per-metric `defined && > 0 && !$omit_*` | `finalize_histogram_unified` (via `calculate_histogram_buckets`) | metric name literal | **3 + #UDMs** (`for my $metric (qw(duration bytes count), map { $_->{name} } @histogram_udm_configs)`) | **Yes**, ×2/metric | **Yes** — `calculate_histogram_bucket_count($min,$max)` | `bin` |
| **heatmap** | `%heatmap_counters`, `%heatmap_counters_hl` → `%heatmap_data{,_hl}`, `%heatmap_percentiles`, `@heatmap_boundaries` | mode `bin`; `_hl` on `$category_bucket =~ /-HL$/`; **not value-gated at this site** | `finalize_heatmap_unified` (via `calculate_heatmap_buckets`); frees with `delete $heatmap_counters{$bucket};` | `$bucket` (time bucket) | **#time buckets** (span ÷ `-bs`) | **Yes**, ×2/bucket | **Yes** — `my $W = $heatmap_width;`, markers → columns via `find_heatmap_bucket($v, $W)` | `bin` |
| **bucket-stats** | `%bucket_stats_counters`, `%bucket_stats_counters_hl` (**write-only**), `%bucket_stats_audit`; sidecars on `%log_analysis{$bucket}` | `$bucket_duration_stats_demand` × mode `bin` × `$duration > 0` | `calculate_statistics_bin` from `calculate_all_statistics`; telemetry `finalize_bucket_stats_unified` | `$bucket` | **#time buckets** (`scalar keys %log_analysis`) | **No** | **No** — scalars only | `raw` |
| **message-stats** | `%log_messages_counters` (**flat**), `%message_stats_audit`; sidecars on `%log_messages{$cat}{$key}`; **no `_hl` store** | mode `bin` × `$duration > 0`; **three-arg `counter_update`** (bpd defaults to `$percentile_buckets_per_decade`) | `calculate_statistics_bin` (2 sites); telemetry `finalize_message_stats_unified` | `"$category\x1f$log_key"` | **UNBOUNDED.** `$top_n_messages` bounds display only; reduced solely by `-g N` consolidation | **Indirect** — `merge_bin_counter_entries` → `partition_rebin` ×2 per non-congruent merge | **No** | `raw` |

**Primitive set** — nine subs inside `# HISTOGRAM BIN-COUNTER PRIMITIVES (R1-R6 per Issue #189)` …
`# END HISTOGRAM BIN-COUNTER PRIMITIVES`: `bin_boundary`, `partition_new`, `partition_extend`,
`partition_rebin`, `snapshot_counter_telemetry`, `bin_assign`, `bpd_for_surface`,
`counter_update`, `percentile`. **`merge_bin_counter_entries` is a tenth member located
outside the marker** (it sits beside `merge_bin_state` in the consolidation region).

**The container contract is two nested shapes, not one:**
entry `{ partition, bins, overflow, underflow }` and partition
`{ min, max, bpd, decades, bin_count, log_ratio, rebins }`. Both are addressed by field
name in all ten subs.

Findings carried forward:

1. **message-stats is the only surface whose partition count is unbounded by anything structural.** This is the whole memory profile #426 exists for.
2. The two display-geometry surfaces are exactly the two that rebin at finalize and the two that default to `bin`. The two scalar-statistics surfaces default to `raw` and never rebin at finalize.
3. `%bucket_stats_counters_hl` is pure cost — three references, none consuming.
4. **Capture is unconditional; consume is top-N.** Most message partitions built are never read for a percentile — only walked by `snapshot_counter_telemetry`.

---

### Part 2 — Governing research and locked decisions

#### The register (surfaces bound / later amendment)

| ID | Decides | Surfaces bound | Amendment |
|---|---|---|---|
| **#187 F1** | ltl is a query-time analyzer; precision is the analyst's run-time lever; `rank_in_bin` legitimate | Anchors D1's formula and D2's existence | none |
| **#187 D1 / D1A** | The Prometheus `HistogramQuantile` walk verbatim (`ceil(q·N)`, low→high, `rank_in_bin/count`, log-interpolation), using `rank_in_bin` as the fraction | `percentile`; every quantile consumer | none. #426 F24: grid-agnostic (92/92 edge cases) |
| **#187 D2** | bpd default 53, range 4..616, tier ladder | All bin surfaces' resolution + memory budget | **Twice, in place.** #289: 53 is a floor, per-surface upward tuning sanctioned. #293: single `-dmp` lever, `-pbpd`/`-bsbpd`/`-hgbpd` deleted |
| **#187 D3** | No per-bin sample guard; no `rank_support` field | `percentile`; the `-V` field set | none |
| **#187 D4** | Structurally distinct overflow/underflow, both in `total_N`, boundary-return with no interpolation; `out_of_range_bounded: high\|low\|none` **per quantile** | Partition layout (B+2); `percentile`'s return tuple; three `-V` fields | none locked. **Vacuous under a shared grid** (proposed A2) |
| **#187 D5** | HdrHistogram auto-resize: lazy construct, 5-decade seed on `v_0`, doubling, counts preserved, rebin telemetry mandatory. Seed heuristic revisitable; **the auto-resize lifecycle itself is not** | `partition_new`/`partition_extend`; per-key memory; `-V` telemetry | **#201, 2026-05-20**: scope narrowed to F1; F2/F3 get the separate stream-616 → finalize-rebin contract |
| **#187 D6, D9** | Dissolved (no runtime gate; activation policy out of scope) | — | — |
| **#187 D7** | Visible-but-deprecated `--exact-percentiles`/`-ep`, stderr notice, `-V` banner + per-consumer `user_opt_out` | CLI; `-V` header | **Never amended; contradicted by shipped code** (V8: zero hits). #287 re-reads it as `-mdm raw` via `choose_data_model` without amending D7 |
| **#187 D8** | Section name, run-level fields, ordered per-consumer field set, seven locked consumer names, deterministic block order. **Stability contract: names may not change without a new locked entry** | `emit_bin_counter_mode_verbose`; every harness greping the section | **Twice in place** (#34 rename to `BIN-COUNTER MODE`; #293 `data_model_precision:` + removal of run-level `buckets_per_decade:`). **A third rename shipped un-recorded** — see R3 |
| **#187 D10** | Prototype validation mandatory before production bin code | Gate on all bin work | Discharged for message-stats by #287; re-opened in practice by `prototype/426-*` |
| **#187 R4** | **The accuracy contract**: bin-resolution error bounded uniformly by geometry, "**structural … not empirical**" | The one-bin bound every harness and the L3 oracle assert | Not amended. **Contradicted by #426 F25** — proposed correction A4 |
| **#187 R5** | Degenerate inputs: zero → `-`, no partition; all-same → single bin, `lower = upper` **by geometry** (a reachable, specified case) | `percentile` | none — and it is why A9 overreaches |
| **#187 R6** | Determinism for a given input (fixed-sequence) | All primitives | none. #426 F27 shows order-independence is **not** claimed and T does not have it |
| **#189 R1–R12** | The primitive contracts. **R3 explicitly leaves store shape implementation-defined** ("the contract is the operation, not the data structure") — this is what permits a container change. **R7 partition independence is a hard requirement.** **R12** adds `partition_rebin` (geometric-midpoint, F2/F3 only) | The primitives; store representation | R12 *is* the #201 amendment; R1 narrowed to F1 alongside |
| **#201 three-dimension framing** | The mismatch is A bin-count, **B range-anchor**, C unknown display width. Raising bpd made fidelity *worse* — the failure is B, not A | Why F2/F3 need a different lifecycle | — |
| **#201 F1/F2/F3 taxonomy** | F1 precision-bound per-key fan-out; F2 display-direct; F3 linear-index-projected | The vocabulary all later docs use | — |
| **#201 Recommendation (e_coarse)**, locked 2026-05-20 | Two-stage stream → finalize-rebin → legacy display projection. Naive "rebin straight to display width" **empirically rejected** by V8 | `calculate_heatmap_buckets`, `calculate_histogram_buckets` | Adopted verbatim into D5 and #34 R5/R8 |
| **#201 per-family bpd contract** | Streaming bpd 616 **for F2/F3 only**; F1 stays at 53 (unbounded partition count) | `$histogram_stream_bpd`, `$heatmap_stream_bpd` | **#293** lets tiers 1–4 coarsen the display surfaces below 616 — flagged in #293 as new behavior |
| **#201 fidelity invariant** | No cross-bin mass splitting at any stage; geometric-midpoint only; visual validation mandatory; "memory savings are not worth fidelity loss" | Any rebin/merge/projection touching counts | Mirrored verbatim into #34 R5 |
| **#293** | One lever `-dmp` 1..9 default 5; the four-row tier table is source of truth; `percentile_precision:` → `data_model_precision:` is a breaking `-V` key rename | Every surface's `effective_bpd`; five harnesses | Amends #187 D2 and D8, and #201's fixed-616 pinning |
| **#289** | 53 is a global floor with per-surface upward tuning sanctioned; STATS CSV is a render surface independent of `-hm`; documents the `[min,max]` clamp and the `high>low>none` cross-key audit aggregation | Bucket-stats | Amends #187 D2 |
| **#287 R2.1–R2.3, R5, R6, R10, R12** | The per-message store's shape: bin entry + five sidecars; bpd **53 not 616** because cardinality is unbounded; **no finalize rebin**; ~2 KB/key, crossover ≈256 samples/key; `-mdm raw` byte-identical | **The exact structure #426 replaces** | R2.3's merge mechanism is stale vs code — see Part 4 |
| **#305 / #349** | Statistics-group demand gating; store-level demand booleans | Whether the message store is built at all | #349 has **no feature doc** — recorded only in `features/305-*.md` |

#### Decisions that go vacuous or need amendment under a shared-grid representation

Source: `prototype/426-bin-primitives-revalidation-report.md` § *Proposed amendments*. **None is
locked.** `features/189-*.md` § *Revalidation under #426* states it directly: P10 "makes D4,
D5 and R6 vacuous (no out-of-range state, no seed, no rebin) … D8's rebin/overflow fields
become inert", while P8+P9 (span-only, verbatim geometry) leave R1–R12 holding verbatim.

Citation cross-check, corrected:

| # | Cited decision | Accurate? | Note |
|---|---|---|---|
| A1 | #187 D5 (P10 only) | ✅ | But **understated**: D5 declares the auto-resize lifecycle *not revisitable* (only the seed is). A1 overrides a non-revisitable clause — architect-level, not pre-authorized tuning |
| A2 | #187 D4 (P10 only) | ✅ | Under a grid the `low`/`high` branches are unreachable; enum collapses to constant `none` |
| A3 | #187 D8 five fields (P10 only) | ✅ | But **silent on D8's locked field *order***, part of the same stability contract |
| A4 | #187 R4 wording, regardless of P10 | ✅ | **The one correction that applies to shipped code today.** R4 says "structural … not empirical" with no remap exception; `partition_extend`, `partition_rebin` and `merge_bin_counter_entries` all remap |
| A5 | #189 V5 finding 1 | ✅ | V5's own table shows `binning_max` 0.83–0.93% against a 0.90% bound, marked ✅ — the report contradicts itself |
| A6 | `v ≤ 0` undefined | ✅ | Genuine gap: neither #187 D1 nor #189 R2/R4 states behavior; caller-side `> 0` guard is de-facto contract |
| A7 | #189 R2 grid index convention (P10 only) | ✅ | Correctly asks for a *new* convention rather than claiming R2 settles it |
| A8 | #189 R8 `undef` vs `0` fill | ✅ | New implementation note under R8's umbrella, correctly labelled |
| A9 | #187 D1 `lower = upper` unreachable | ❌ **REJECT AS WRITTEN** | Two defects. (a) **The cited grounding does not exist**: none of `lower = upper`, `fraction = 0`, `rank_in_bin = 0` appears anywhere in `prototype/189-bin-counter-primitives-validation-report.md` (V14). (b) It would contradict **#187 R5**, which specifies `lower = upper` as a *reachable, contractually-specified* degenerate outcome. A9 must be re-grounded against a real capture and re-scoped against R5 before it is considered |
| A10 | #187 D7/D8 vs shipped emitter | ✅ | Verified: zero hits for all four strings (V8). Pre-dates #426 entirely |
| A11 | #187 D2 memory guidance is dense-layout-specific | ✅ | D2's ~2.1 KB/partition and ~212 MB/10⁵ keys derive from a dense `(B+2)×8` array; #426 F31 measured T at 2,381 B reproducing #189 V2 exactly, vs S 955 and G 600 |

---

### Part 3 — Blast radius of a container change

#### Call graph, by phase

**Hot path** (`read_and_process_logs`) — **14** `counter_update` sites across three cardinality
regimes on one substrate: ~5 keys (histogram), O(buckets) (heatmap, bucket-stats),
O(10⁵⁺) (message-stats). Two sites are three-arg and rely on the default bpd:
`counter_update(\%log_messages_counters, "$category\x1f$log_key", $duration);` and
`counter_update(\%tmp, '_single', $duration);`.

**Consolidation path** (`group_similar_messages`) —
`merge_log_message_entry_into_cluster` → `merge_consolidation_stats` → `merge_bin_state` →
`merge_bin_counter_entries` → `partition_rebin` ×2. **The most exposed site**: it assumes both
operands expose `{partition}{min,max,bpd,bin_count}` and a directly-indexable `{bins}` arrayref.

**Finalize**, in MAIN order: `finalize_message_stats_unified` (snapshot only) →
`finalize_bucket_stats_unified` (snapshot only) → `finalize_heatmap_unified` (rebin +
4 percentiles + `delete`) → `finalize_histogram_unified` (rebin + 12 percentiles +
`bin_boundary` over `0 .. $bucket_count`) → `emit_bin_counter_mode_verbose`.

`calculate_statistics_bin` is the **read-side hot spot** — three call sites in
`calculate_all_statistics`, two of them per message key. Key coupling for #426: the message
sites pass **two containers** joined by the string key `"$category\x1f$log_key"` — the
`%log_messages` sidecar entry and the `%log_messages_counters` entry. A compact store must
decide whether those stay two keyed structures or fuse.

#### `-V` emitters carrying counter state

| Section | Emitter | Bin-relevant content |
|---|---|---|
| `histogram-bin-counters` | `emit_bin_counter_mode_verbose` | `data_model_precision:`; per-consumer `path`, `partition_keying`, `partition_count`, `total_rebin_events`, `max_partition_bins`, `partitions_with_{over,under}flow_count`, `counter_memory_bytes`, `rebins_per_partition`, `percentiles_emitted`, `out_of_range_bounded`, `shares_partitions_with`. **Every numeric field is produced by `snapshot_counter_telemetry` reading container field names directly**; `counter_memory_bytes` is `Devel::Size::total_size($store)` and therefore moves by construction on any container change |
| `histogram-bin-counters / dimensions` | `finalize_histogram_unified` (buffered) | `format_histogram_dimensions_line` |
| `percentile-algorithm` | `emit_percentile_algorithm_verbose` | Per surface: `data_model`, `effective_algorithm`, `effective_bpd`, `formula`. **Machine-read by the `validate-statistics.sh` L3 oracle** |
| `statistics-demand` | `emit_statistics_demand_verbose` | `stats_calls`, `group_calc … computed/skipped_demand/ineligible`, `moment_source: sidecar` |
| `benchmark-data` | `print_verbose_output` | `MEMORY\t<struct>` rows from `named_structure_sizes()` — all seven counter stores named individually (V11), plus `MEMORY\tunattributed` |
| `runtime-config` | `emit_runtime_config_verbose` | The selector rows |

#### Serialization — **none**

No bin, partition or counter state reaches disk. `write_index_file()`'s columns are scalar
aggregates; CSV writes derived percentile values, not counters; index-read-back fixtures
contain zero `bins` references (V10). **A container change has zero on-disk migration
surface.** This is the single biggest de-risking fact in the audit.

#### Harnesses

| Harness | Nature | What moves it |
|---|---|---|
| `validate-histogram-bin-counters.sh` | **Structural, value-insensitive.** ~40 anchored patterns; `partition_count: [1-9][0-9]*` requires ≥1; `percentiles_emitted` exact ladder + order; `assert_surface_bpd` 16 exact cells across tiers 1/5/7/9 | Any field/consumer/section rename; `partition_count` reaching 0; any `%TIER_BPD` edit |
| `validate-statistics.sh` | **VALUE-EXACT.** 5 committed bin-model baseline dirs (`{apache,codebeamer,thingworx,tomcat}-bin-data-model`, `tomcat-heatmap-bin`) holding full-precision floats. T1/T2 advisory ≤1%; **T3 blocking >1%**; L2 invariants T4; L3 oracle reads `effective_bpd`, blocking >2.5% on bin columns | Any percentile shift >1%; any break of `min ≤ p1 … p99999 ≤ max` |
| `validate-statistics-demand.sh` | Structural, **call-count-sensitive** | Any change to how many keys reach `calculate_statistics_bin` |
| `validate-duration-display.sh` | Render invariants across **both** models (`-dm bin` and `-dm raw`) | A shift that inverts P50/P95/P99 ordering |
| `validate-regression.sh` | Value-exact golden renders — **but fenced entirely off the bin path** (V9, R2) | Nothing on the bin path |
| `validate-csv-output.sh` | Structural typing only | Nothing numeric |
| `validate-distribution-shape.sh` | Value-exact, **raw-only by declared scope** | Nothing on the bin path |
| `validate-histogram-ticks.sh` | Self-consistency (ltl vs itself) | Desync of boundaries from percentile values, not a uniform geometry change |
| `validate-runtime-config.sh` | Selector rows only | `-dmp` / selector surface |
| All harnesses | `assert_no_runtime_warnings` | Any autovivification or `//`-guard slip — **fires before anything else** |

#### Ranked

**Breaks LOUDLY**

1. Renaming any `-V histogram-bin-counters` field, consumer, or `path:` value — also a D8 locked-decision breach requiring an architect-approved entry and a `tests/HARNESS-DESIGN.md` consultation.
2. Any percentile value moving >1% — `validate-statistics.sh` L1 T3, blocking, against 5 committed bin baselines; L3 oracle a second blocking layer.
3. Breaking `min ≤ p1 … p99999 ≤ max` — L2 T4. The clamp in `calculate_statistics_bin` exists solely to hold this.
4. `partition_count` reaching zero for a migrated consumer.
5. Editing `%TIER_BPD` or `bpd_for_surface`.
6. Changing how many keys reach `calculate_statistics_bin`.
7. Any Perl runtime warning.

**Breaks SILENTLY** — *promoted item: the bin histogram render joins the bin heatmap render as
wholly uncovered (R2)*

1. Percentile shifts ≤1% — T2 advisory, visible only under `--show-all`. Exactly the magnitude a reshaped container produces.
2. `counter_memory_bytes` — asserted only as `[0-9]+`, and it is the designed memory instrument.
3. `MEMORY\t*_counters` rows vanishing from `-V benchmark-data` if a store is renamed or removed in `named_structure_sizes()` — a metric present on one side only is *news* per CLAUDE.md, but nothing detects it automatically.
4. **`MEMORY\tunattributed` absorbing the delta** if the substrate moves somewhere `Devel::Size` cannot walk (packed string, closure, buffer). In-tree precedent: `format_scan_subs` needed a dedicated RSS-delta path for exactly this. **A compact container is highly likely to hit it.**
5. `total_rebin_events` / `max_partition_bins` / `rebins_per_partition` drifting — shape-only assertions.
6. `out_of_range_bounded` flipping `none` → `low`/`high`.
7. Bin-path shape moments drifting — no absolute-correctness anchor exists (`validate-distribution-shape.sh` is raw-only).
8. **Bin heatmap AND bin histogram renders** — zero golden coverage (R2).
9. **Consolidation merge fidelity under `-mdm bin`** — every `*-consolidated` statistics-drift scenario is raw-model; there is **no `*-bin-consolidated` scenario**. The `-g 90 × -mdm bin` path through `merge_bin_counter_entries` is entirely unasserted. **Highest-risk uncovered path.**
10. Doc prose going stale (below).

#### User-facing documentation to update

| File | Section | Commitment |
|---|---|---|
| `docs/usage.md` | "Percentile data model and algorithm" + selector table | "Scales with partition count rather than observation count"; per-selector bin description |
| `docs/usage.md` | "Tuning precision" | `-dmp` tiers; pointers to the two `-V` sections |
| `docs/explain/statistics.md` | "percentiles" | **"one partition per logical series, with a fixed bin footprint per partition regardless of how many observations stream through it"** — a direct statement about container shape |
| `docs/explain/statistics.md` | "iqr" / "min" / "max" | "~1.3% relative bin width"; "running min sidecar alongside the bin partition" |
| `docs/explain/histogram.md` | "Precision and tuning" | Bin resolution tied to `-dmp` |
| `ltl` `--explain` strings | `$explain_percentiles_compute`, `$explain_{min,max,iqr,skewness,kurtosis}_compute` | Same claims, second surface; nothing enforces agreement between the two |

Per CLAUDE.md's 2026-05-23 rule none of this may name internal identifiers, so a *rename*
does not propagate here — but a change to bin width, per-partition footprint, sidecar
mechanism, or "scales with partition count" does.

---

### Part 4 — Invariants a replacement must preserve

Legend: **C** = locked contract; **O** = observed behavior with no contract statement.

| # | Invariant | Status | Verbatim source | Code anchor |
|---|---|---|---|---|
| 1 | **Mass conservation** | **C** for `partition_rebin`; **O** for capture and merge | #189 R12 *Invariants preserved*: "Sum of counts in `$finalized_bins` equals sum of counts in `$src_bins` plus optional source-side overflow/underflow folded in" | `$new_bins[$new_i] = ($new_bins[$new_i] // 0) + $count;` with clamps `$new_i = 0` / `= $new_bin_count - 1` making it total. `counter_update`: every observation lands in exactly one of bin/overflow/underflow |
| 2 | **Peak preservation** = 1.0 always | **C** (mechanism); numbers **O** | #201: "For a spike entirely within one source bin, the spike count goes entirely to one target column. `peak_retention = 1.0` [always — no count splitting]. **Y-axis is exact.**" | geometric-midpoint loop, both `partition_extend` and `partition_rebin` |
| 3 | **Peak X-offset** ≤ `ceil(B_d × (R_s/B_s) / R_d)` | **C** (algebraic) | #201 § *Algebraic fidelity bounds*; V6/V7 measured 0 columns, 100.0000% mass and peak retention | — |
| 4 | **#201 fidelity invariant** — no cross-bin mass splitting at any stage; geometric-midpoint only; visual validation mandatory before merge; "memory savings are not worth fidelity loss" | **C** | #201 § *Fidelity invariant — DO NOT smooth the data*, mirrored verbatim in #34 R5. Review vocabulary: *distributive, smear, split, interpolate* applied to **bin counts** is suspect | `my $midpoint = sqrt($lower * $upper);` in exactly two subs — plus a **third context #201 never contemplated**: `merge_bin_counter_entries` calls `partition_rebin` twice |
| 5 | **Determinism** (fixed-sequence) | **C** | #187 R6, #189 R5, #189 R12, #287 R11 | `percentile` walks `0 .. bin_count-1` by index; `merge_bin_counter_entries` iterates `0 .. $union_bin_count-1`; `snapshot_counter_telemetry` sorts before reporting |
| 5b | **Insertion-order independence** | **explicitly NOT claimed** | #426 F27: "G is insertion-order-independent and merge-commutative; T is neither (T differs on 105/200 keys, up to 0.99 bins; G 0/200)" | — |
| 6 | **Out-of-range semantics** — distinct counters, both in `total_N`, `boundary[0]`/`boundary[B]` with no interpolation, `out_of_range_bounded` **per quantile** | **C** (#187 D4, #189 R6) | D4 verbatim; #189 R6: "a partition with `partitions_with_overflow_count > 0` may still report `audit = none` for some quantiles … Consumer tests must not assert `high` for every quantile" | `sub percentile` matches exactly. **Note**: `counter_update`'s own header says the counters are structurally unreachable under today's uncapped auto-resize — they are reachable only via `merge_bin_counter_entries` propagation |
| 7 | **#187 D8 `-V` name stability** | **C** | "the section name, all top-level field names, all consumer-name strings, and all per-consumer field names are part of the locked feature contract" | See divergences below |
| 8 | **In-bin interpolation rule** | **C** — doc and code **AGREE, no drift** | D1 steps 1–5 | `POSIX::ceil($q * $total_N)`; `$rank_in_bin = $target_rank - ($cum - $c)`; `$fraction = $rank_in_bin / $c`; `$lower * (($upper / $lower) ** $fraction)` — the doc's explicitly-permitted equivalent form. Natural-log `bin_boundary` is the permitted alternative to log2/exp2 |
| 9 | **Rank-convention divergence is deliberate** — raw uses `int` (nearest-rank), bin uses `ceil` (Prometheus) | **C** (#272 pair, restated #287 R4) | The two paths are **not** expected to agree; cross-model equality is never a valid assertion | `$sorted[int($duration_count * 0.5)]` vs `POSIX::ceil($q * $total_N)`. `emit_percentile_algorithm_verbose` declares both; the L3 oracle dispatches on it |
| 10 | **R4 accuracy bound** — "structural … not empirical", uniform across quantiles | **C as written; measured false** | #187 R4 verbatim | **#189 § Revalidation under #426**: "R4's 'structural' bound is not met once a partition has been remapped by widening or by `merge_bin_counter_entries` (up to ~2 bins after merges)". #426 F25: T needed a remap on 73% of 1,258 pairs / 88% of 2,198 fold steps, worst 1.35–2.06 bins, within-one-bin down to **78%**; G holds **100.00%** at 53/115/256/616. **Correction PROPOSED, NOT APPLIED — R4 as written still stands** |
| 11 | **No per-bin sample-count guard**, ever | **C** (#187 D3) | "R4 returns Decision 1's formula output regardless of `bin_count` or the position of the target rank"; no `rank_support` field | A replacement must not add one |
| 12 | **Render-stage duplication is preserved, not fixed** | **C** by #201's `e_coarse` | #201 V7: shipped display sum 1,647,292 vs true raw 575,800 (~2.86× inflation) via `display[i] = partition[int(i / cols_per_bucket)]` — duplication, not splitting; deliberately kept | A replacement must preserve the duplication convention or bar widths change |

#### Merge semantics

| Aspect | Status |
|---|---|
| **Merge-fidelity guarantee** | **C** (#287 R2.3): merged ≡ from-scratch, "up to the bin-resolution bound on percentiles, and numerically identical on the sidecar-derived statistics" |
| **Mechanism** | **#287 R2.3 is STALE.** It says extend the narrower via `partition_extend`; code computes a **union geometry and rebins both sides** (V5). The code comment justifies it: "`partition_extend`'s doubling history can leave the two partitions with non-congruent (min, max) … so we cannot just per-bin add directly". The code is the better mechanism; R2.3 was never updated. R2.3 also names `merge_consolidation_stats` as the site; the bin merge actually lives in `merge_bin_state` |
| **Commutativity** | **NOT claimed; measured false** (F27). Asymmetry in code: `$union_bin_count = int($bpd * $union_decades)` uses the **target's** `$bpd`, and the target-empty branch adopts the source wholesale without rebinning |
| **Associativity** | **NOT claimed, not measured** anywhere in the corpus |
| **Target-empty aliasing** | `$target->{partition} = $source->{partition};` — **by reference**. Two entries then alias one partition hashref. **Undocumented anywhere.** A replacement must preserve or deliberately fix |
| **Merge rebins invisible to telemetry** | `partition_rebin` returns `rebins => 0`; `total_rebin_events` and `rebins_per_partition` **undercount on every consolidated run**. Recorded as a proposed correction, **not applied** |

#### Doc/code divergences found

| # | Divergence | Doc | Code | Severity |
|---|---|---|---|---|
| D-a | `-V` section name | D8: `=== BIN-COUNTER MODE ===` (both amendments say the rest holds "verbatim") | `=== histogram-bin-counters ===` | **Rename real, shipped, harness-asserted; D8 never amended.** A replacement preserves the *shipped* name |
| D-b | `consumers_active: none` | D8 contract clause | no emission site (V8) | clause unimplemented |
| D-c | `opt_out_active` / `opt_out_notice` / `--exact-percentiles` | D7 + D8 contract | zero hits (V8); superseded in practice by `-mdm`/`-bdm`/`-dm` (#266) | clause unimplemented, un-amended |
| D-d | merge geometry alignment | #287 R2.3 | union rebin of both sides | code correct, R2.3 stale |
| D-e | merge-driven rebin telemetry | D8 counts them | `rebins => 0` | proposed correction, not applied |
| D-f | **`[min,max]` percentile clamp** | #289 documents it; **#187 D1 zero mentions; #287 has none** (R6) | `calculate_statistics_bin` clamps unconditionally | **Drift on the exact surface #426 replaces.** The harness (L2 T4, #224 D4) enforces the bound; no #187-level statement authorises the clamp |
| D-g | `$target_rank` clamped to `[1, total_N]` | not stated anywhere | `sub percentile` clamps (V6) | code-only, benign |
| D-h | target-empty merge aliases the partition | not stated anywhere | by-reference assignment | code-only, undocumented |
| D-i | R4 "structural, uniform" | #187 R4 | false after any remap/merge | correction proposed, not applied |

#### Not found / uncertain

- No document states mass conservation as an invariant for the **streaming capture path** or for **`merge_bin_counter_entries`**. It holds in code; it is contract only for `partition_rebin` via #189 R12.
- No **associativity** claim for merge anywhere.
- No accuracy bound scoped "after N merges" other than #426 F25, which is a finding, not a locked contract.
- The `high > low > none` cross-key audit aggregation rule is documented **only** in #289 § *Observability* — not in #187 D4 or D8.
- `features/349-*`, `features/354-*`, `features/323-*` **do not exist** (V13). #349's contract lives inside `features/305-*.md`; #323's findings are in `features/189-*.md` but not under a `#323` heading. **Step 2 of the audit brief cites a doc that was never created.**

---

### What this audit changes about the N1–N8 plan

**N1 as written already names the display surfaces** — it was drafted *after* the scope
correction, not before it, and covers F2 heatmap and F3 histogram, the `partition_rebin`
finalize step, T↔S parity of finalized cells/markers/bins, and the #201 measures. The
audit does **not** find N1's surface coverage deficient. What it finds is that N1's *build*
is under-specified in five concrete ways that the audit now settles:

1. **N1 must cover `bucket-stats`, which it does not name at all.** N1 names F2 and F3;
   the audit's Part 1 shows **four** `%TIER_BPD` rows, and `bucket-stats` is a per-time-bucket
   store on the same substrate with a **different bpd ladder** (`[16,32,53,53,53,115,616,616,616]`
   — 616 arrives at tier 7, not tier 5) and **no finalize rebin**. It is neither an F1
   fan-out surface nor an F2/F3 display surface. Under S and G it is a third shape: bounded
   cardinality, scalar-only consumption, `percentile()` invoked directly against the
   streaming partition. **N1 (or a new N1b) must add a bucket-keyed, no-rebin arm.**

2. **N1 must exercise the `merge` path on the display arms, and it currently cannot.**
   N1's parity target is "finalized cells/markers/bins". But `partition_rebin` has **six**
   call sites, and **two are in `merge_bin_counter_entries`** — a context #201 never
   contemplated when it locked the geometric-midpoint contract. The heatmap/histogram
   arms never merge, so N1 as scoped tests four of the six. N2 covers merge for S on the
   message surface only. **The union-rebin path needs an arm in N1 or an explicit statement
   that it is N2's alone.**

3. **N1's "`-hm` / `-hg` `-V` sections from each arm vs real ltl" must include the five
   fields the audit shows go inert.** Under P10 (grid), `total_rebin_events`,
   `max_partition_bins`, `partitions_with_overflow_count`,
   `partitions_with_underflow_count` and `rebins_per_partition` are all structurally
   meaningless, and A2/A3 propose amending D8. N1 must therefore report **which D8 fields
   each arm can still populate**, per surface, not just whether the section matches — a
   pure diff-vs-ltl will show five failures on G that are the *expected* consequence of
   the representation, not defects.

4. **N1 must measure with RSS, not `Devel::Size`, on the display arms too.** Blast-radius
   item 4: if a compact container moves the substrate somewhere `Devel::Size` cannot walk,
   the bytes silently reappear in `MEMORY\tunattributed`. N8 already sets RSS as the number
   of record — **that rule must apply from N1 forward, not be deferred to N8**, or N1's
   memory numbers on the display arms will be unusable and have to be re-run.

5. **N1's fidelity comparison must state which R4 bound it is testing against.** Post-#426
   F25 the "structural" bound is known false after remap, and every N1 finalize step *is*
   a remap. N1 reports **within-one-bin percentage**, not "within the structural bound".

**Re-derivation needed in N2–N8:**

- **N2 (native span merge for S)** — unchanged in intent, but must now target the **union**
  geometry the shipped `merge_bin_counter_entries` computes, not #287 R2.3's stale "extend
  the narrower". Building against R2.3's prose would validate a mechanism ltl does not use.
  Also: it must decide whether the **target-empty by-reference aliasing** (D-h) is preserved
  or fixed, and say which.
- **N4 (real ltl end-to-end under G)** — **expand.** N4 says "the summary-table path". The
  audit shows the harness exposure is not confined there: `validate-statistics.sh` carries
  five committed **bin-model** baseline directories including `tomcat-heatmap-bin`, and
  `validate-histogram-bin-counters.sh` asserts 16 exact bpd cells across four tiers.
  N4's re-bless enumeration must cover **all five bin baselines and the tier assertions**,
  not the summary table alone.
- **N7 (`-V` audit aggregation scope)** — **partly moot under G.** If `out_of_range_bounded`
  collapses to constant `none` (A2), N7's question has no content on the G arm. N7 must
  either be scoped to T and S, or restated as "show that the audit is constant under G
  and say what should replace it".
- **N3, N5, N6, N8** — no re-derivation. N3's second surface, N5's merge shapes, N6's
  ≥10⁵-key fan-out and N8's RSS measure are all unaffected by anything the audit found,
  beyond N8's rule being promoted forward into N1 (point 4).

**Two coverage gaps the audit found that no N-item currently addresses**, both of which
make it impossible to *prove* a container change is safe from the harness suite alone:

- **No `*-bin-consolidated` statistics-drift scenario exists.** Every `*-consolidated`
  scenario is raw-model. The `-g 90 × -mdm bin` path — the one that goes through
  `merge_bin_counter_entries` → `partition_rebin` ×2 — is asserted by nothing.
- **No golden render exists for either bin display surface.** `validate-regression.sh`
  pins all 22 heatmap and histogram scenarios to `-dm raw` (V9). The `bin` histogram render,
  which is the **default**, has no byte-level coverage at all.

Both are pre-existing gaps, not #426's creation — but a container change lands on
precisely them. **Filed as #450** (2026-08-25) and kept out of #426's scope, so a
data-model change does not absorb independent test-coverage work.

---

### Open questions raised by the audit

1. **D8's section name.** `ltl` emits `=== histogram-bin-counters ===`; #187 D8 still locks
   `=== BIN-COUNTER MODE ===`, and both recorded amendments say the rest holds "verbatim".
   The rename shipped and is asserted by the harness. Should D8 be amended retroactively to
   record the name that shipped, or is a different resolution intended?

2. **D7 and the three unimplemented D8 clauses.** `--exact-percentiles`, `opt_out_active`,
   `opt_out_notice` and `consumers_active` are locked contract with **zero emission sites**.
   #287 re-read the opt-out as `-mdm raw` without amending D7. Should D7 be dissolved (as
   D6 and D9 were) and D8's run-level header trimmed, before #426 touches the emitter?

3. **The `[min,max]` percentile clamp on the message-stats surface.** It ships
   unconditionally in `calculate_statistics_bin`, is documented only for bucket-stats
   (#289), and appears in neither #187 D1 nor #287. The #224 L2 T4 invariant depends on it.
   Is the clamp a locked part of the message-stats contract that #426 must preserve, or an
   undocumented implementation detail open to redesign?

4. **A4 — the R4 accuracy contract.** The correction (the bound is not met after remap or
   merge) applies to **today's shipped code regardless of #426**. Should it be locked as a
   #187 amendment now, independently of any representation decision, so the corpus stops
   asserting something measured false?

5. **A9.** Its grounding citation cannot be located in the #189 validation report at all
   (V14), and its proposed text would contradict #187 R5, which specifies `lower = upper`
   as a reachable degenerate case. Withdraw A9, or re-ground and re-scope it?

6. **`%bucket_stats_counters_hl`.** Written on the hot path, read only by `Devel::Size`,
   its own comment concedes "store parity only". Is it in scope for #426 to remove, or does
   store parity have a purpose the code does not record?

7. **Bucket-stats' place in the F1/F2/F3 taxonomy.** #201's taxonomy puts
   `time_bucket_stats` in F1 (precision-bound per-key fan-out), but its cardinality is
   bounded by time buckets like F2/F3, and it never finalizes. Is it F1 by lineage only,
   and should N1 treat it as a fourth shape?

8. **The two uncovered paths.** Should a `*-bin-consolidated` statistics-drift scenario and
   a bin-model golden render be added **before** the prototype work, so #426 has a harness
   that can detect what it changes — or is that a separate issue?

9. **Merge associativity.** No document claims it and nothing measures it. Under `-g N`
   folds, entries are merged in sequence. Is associativity a property a replacement must
   demonstrate, or is fixed-sequence determinism (#187 R6) sufficient?

10. **`features/349-*`.** Step 2 of the audit brief names it; it does not exist, and #349's
    store-level demand contract lives inside `features/305-*.md`. Should #349 get its own
    feature doc, or is the pointer in #305 the intended record?

---

### Process error — framing drift in the 2026-08-25/26 analysis (recorded 2026-08-26)

**The measurements below are sound and unaffected. The analysis written on top of them was
not, and the error is recorded here because it would otherwise be invisible: it corrupted
only the interpretive layer, and every capture, table and finding would pass an audit.**

**What happened.** Across roughly ten progress summaries, the three-arm comparison stopped
being symmetric. A different evaluation question came to be applied to each arm, and the
incumbent stopped being evaluated at all:

| arm | the question it was actually being judged by |
|---|---|
| S | "does anything observable change?" — nothing does, so: clean, safe |
| G | "what would adoption cost?" — a re-bless plus contract amendments, so: expensive, risky |
| T | *none* — treated as the reference against which the others were measured |

Those are three different questions. Asking one of each guarantees the conclusion before any
data is consulted, because "changes nothing observable" is a test only a
conservative-by-construction arm can pass — and it was never the objective. The locked
objective (2026-08-25) was **"replace the container, and measure what the container change
does to the constraint"**, and this issue exists because the as-built layout costs 5x on
traversal. **P10/arm G is the candidate that attacks that at the root.** By the final
summaries it had been reframed as a risk annex to a P8+P9 recommendation.

**The most damaging part is the omission, not the asymmetry.** Because T was never asked its
own adoption cost, T's *measured* properties — order-dependent results on 68-92% of merge
groups (F45), accuracy degrading with merge depth past its own R4 bound (F46) — read as
background conditions of reality rather than as costs carried by one candidate. Those numbers
were in the tables the whole time. The prose did not carry them into the comparison.

**Second-order effect on prominence.** F55 — the compact container is **42% larger** than T on
a bounded-cardinality surface — is a dimension where the emerging front-runner *loses*. It was
recorded accurately and then placed in a subordinate position, while every dimension where S
won was placed in a summary table. Demotion of contrary evidence is the detectable signature of
this failure.

**Corrective actions.**

1. The comparison is rebuilt symmetrically: the same question asked of all three arms, T
   included as the candidate "keep today's representation" and carrying its own adoption cost.
2. The evaluation dimensions are **derived from the specification corpus** (#187, #189, #201,
   #287, #289, #34, #293, #305, #266, #224) rather than from recollection — the list used
   during the drift was assembled from memory and was incomplete.
3. Weightings are grounded in what those specifications treat as load-bearing per feature area,
   and are used **only to direct where analytical effort is spent** — explicitly not to select a
   direction (architect, 2026-08-26: the quantitative view "is not sufficient to decide on the
   direction, but can be used to influence where you spend the most time looking").
4. A problem report with reproduction guidance was written for the tool vendor. It is kept
   outside this repository (it concerns the development tool, not this project).

**The rule this establishes for this issue's remaining work:** an arm's property is never
promoted to a criterion the other arms must meet. "S is digest-identical to T" is a finding
about S. It is not the standard by which G is judged, and it is not evidence that T is correct.

### Session findings (2026-08-25) — N1, N4 and the aliasing question

Recorded here as they were produced; the per-aspect reports carry the tables.

- **F33 — S is display-cell-identical to T on both display geometries, at every
  resolution and every time bucket.** V6 (`prototype/426-revalidate-v6.pl`) finalizes all
  three arms through the F2/F3 contract and compares against an exact display that places
  every observation in the cell holding its value. Across 90 rows — two canonical files,
  three geometries, the five streaming resolutions the display surfaces can resolve to —
  mass retention is `1.000000` and peak X-offset is `0` for every arm, and T and S never
  differ in a single cell. **P8+P9 inherit #201's validation on the display surfaces the
  same way F23 showed they inherit #189's on the percentile surface.**

- **F34 — on the heatmap's real per-time-bucket keying, the global anchor is measurably
  better.** T and S seed each bucket's partition around that bucket's own first value,
  producing **13 distinct range anchors across 24 buckets** — #201 Dimension B, the
  mismatch it identified as the actual failure mode behind its four rejected Phase 3
  strategies. G's grid is globally anchored by construction. Per-bucket deviation from
  that bucket's exact display, 148 MB Tomcat, bpd 616: **G median 0.0667% / max 0.2333%
  against T 0.2667% / 0.4583%.** On the DPM file the three arms are statistically
  identical (median 0.2800% each).

- **F35 — large coarse-resolution deviations are a boundary straddle, not a
  representation defect.** The V6 sweep produces deviations up to 33% at bpd 80,
  non-monotonic in resolution. `prototype/426-v6-boundary-straddle-probe.pl`: the DPM
  durations are small integers, and the source bin holding the value `2` — 19,926
  observations, 16% of the file — has its geometric midpoint at 2.013, just across a
  display-cell boundary, so that bin's whole mass lands one cell over. **T and G do this
  identically** (both cell 3 at bpd 80, both cell 2 at 616). A property of the two-stage
  projection at coarse streaming resolution — and an independent rediscovery of why #201
  locked the display surfaces' streaming bpd at 616.

- **F36 — a shared grid on the message-stats surface is a large re-bless.** N4
  (`prototype/426-revalidate-v8-rebless.pl`, scenario list read from
  `tests/statistics-drift/scenarios.tsv` so it cannot drift from the harness) classifies
  every per-key percentile with `compare-statistics-drift.pl`'s own tiers, where T3
  (> 1%) blocks. At bpd 53: **apache 21.8% T3, tomcat 15.9%, thingworx 31.7%**, worst
  deviations 3.9–4.5%. `codebeamer-bin-data-model` is reported NOT COVERED, not skipped —
  the library's two verbatim parsers do not read that log's bracketed `[293ms]` duration;
  ltl reads it through the format registry.

- **F37 — the T-vs-G accuracy difference is resolution-dependent and reverses across the
  tier ladder.** The aggregate "G lands further from the oracle more often than closer"
  is a composition effect. Decomposed by key shape
  (`prototype/426-accuracy-by-key-shape.pl`, observation count × spread in decades): at
  **bpd 16 G is better on both files** and the margin is large on wide-spread keys (DPM
  `N<1000 / spread>=1dec`: G 3.60% against T 6.78%); at **bpd 53** the two are mixed on
  DPM and T is ahead on Tomcat; **from bpd 115 up T is ahead on Tomcat** and stays ahead
  at 616 (0.021% against 0.239% on its most populous band). Mechanism: T seeds each key's
  partition around that key's own first value (#187 D5), so its bins are adaptive to that
  key's data — an advantage that **grows** with resolution because the seeded range
  concentrates bins where the key has values; G never wastes resolution on a seeded range
  the key does not occupy, which dominates when bins are **scarce**. Both arms are sub-1%
  on every band at bpd 616 on both files.

- **F38 — the surface #426 exists for is accuracy-neutral.** At the 287k-key fan-out,
  **573,026 of 573,318 compared cells are exact for both arms** — the high-cardinality
  population is dominated by single-observation keys, where every representation returns
  that observation. Of the 292 non-degenerate cells, G is closer on every band. The
  T-vs-G accuracy trade of F37 lives entirely in the moderate-cardinality,
  multi-observation population.

- **F39 — the `[min,max]` clamp only ever repairs sub-one-bin overshoots.** When
  `calculate_statistics_bin`'s clamp fires, the raw interpolated value was outside the
  observed range by at most **1.046×** against a bin width of **1.044×** at bpd 53, for
  all three arms (`prototype/426-v7-clamp-magnitude.pl`). The clamp is bounded by the bin
  geometry; it is not repairing arbitrary seed artefacts. It fires on 9.2% of
  bucket-stats cells, so it is doing real work, and any representation must keep it.

- **F43 — the container change's effect on the constraint, measured at the motivating
  scale, and it grows with resolution.** `prototype/426-message-stats-scale.pl` builds all
  three arms over the real message-stats keying at the full fan-out fixture (286,659
  distinct keys, 288,025 observations) and times what the statistics pass does — build
  once, then evaluate percentiles across every key. Built at size, not projected. Medians
  of 3:

  | bpd | arm | build | percentiles (286,659 keys × 3 q) | memory | B/key |
  |---|---|---|---|---|---|
  | 53 | T | 1.518 s | 17.634 s | 662.3 MB | 2,423 |
  | 53 | **S** | 1.233 s | **2.112 s** | **291.7 MB** | 1,067 |
  | 53 | G | 0.697 s | 1.616 s | 194.7 MB | 712 |
  | 616 | T | 2.966 s | **181.348 s** | **3,722.4 MB** | 13,616 |
  | 616 | **S** | 1.294 s | **2.281 s** | **293.9 MB** | 1,075 |
  | 616 | G | 0.738 s | 1.731 s | 196.9 MB | 720 |

  At the default tier's message-stats resolution S is **8.4× on percentile evaluation and
  2.2× on memory**; at bpd 616 it is **79.5× and 12.7×**. The reason is the growth shape,
  and it is the load-bearing half of the locked objective: **across the ladder T grows
  10.3× in time and 5.6× in memory, S grows 1.08× and 1.008×.** Today's dense seeded array
  is what makes per-message resolution expensive — the array is sized by the partition,
  not by the data — so the per-message row's coarse rung exists to pay for the container,
  not for the statistics. A span-only container removes that coupling almost entirely.
  This is evidence handed to the architect about what the row *could* afford; it is **not**
  a proposal to change `%TIER_BPD`, which is locked and his alone.

- **F41 — the native span merge removes S's only regression against T.** S's merge ran
  the verbatim arithmetic through dense views, which cost O(partition width) per merge and
  made it *slower* than T on the `-g` fold. A native O(occupied span) merge (arm S2,
  `prototype/426-native-span-merge.pl`) is digest-identical to T and S on 20 of 21 merge
  edge cases, on consecutive-pair merges and on the full fold, and turns the fold from a
  loss into a win: at 286,658 merges, bpd 53, **T 18.20 s / S 34.36 s / S2 3.65 s** —
  S2 is 5.0× faster than T where S was 1.9× slower. The 21st case is the aliasing probe
  (F40), which exercises a state ltl does not reach.

- **F55 — the compact store's memory advantage INVERTS on a bounded-cardinality surface.**
  On bucket-stats at bpd 616 (62 partitions, DPM), `Devel::Size` reads **T 2,531,282 B
  against S 3,590,876 B — S is 42% larger**, and G 2,714,054 B is also above T. This is
  the opposite of the fan-out result (T 13,616 B/key against S 1,075 at the same bpd) and
  it is not a contradiction: the span-only layout trades a dense array for per-row
  bookkeeping plus an occupied span, which wins when partitions are numerous and sparsely
  occupied and loses when they are few and densely occupied. A bucket-stats partition
  holding ~2,000 observations over a wide value range occupies most of its span, so S pays
  the bookkeeping without recovering it.

  **Consequence for any claim about this store: the advantage is a property of unbounded
  per-key cardinality, not of the container in general.** The per-message surface (millions
  of partitions, most holding one observation) is where it applies; the three
  bounded-cardinality surfaces are where it does not, and on those the honest reading is
  that S costs slightly more memory and buys back time (V7's ladder timings still favour S
  1.9×). Any replacement that switches all four surfaces to one representation must state
  this trade per surface rather than quoting the fan-out figure.

- **F52 — the prior stage's small-scale RSS figures measured allocator slack, and the
  sign inverts with scale.** RSS minus `Devel::Size`, bytes per key: at 51,469 keys the
  span-only arms read **negative** (S −357, G −402) — their stores fit inside memory the
  interpreter had already mapped, so the RSS delta was measuring slack rather than the
  store. At 286,659 keys the gap is firmly positive for every arm (T +532, S +328,
  G +248). Consequence: **the `Devel::Size` projections from 51,469 keys held at fan-out
  (−12% to +19%) while the RSS projections failed badly (+68% to +385%)** — the opposite
  of what the "RSS is the measure of record" rule would suggest in isolation. Both rules
  survive together only when stated precisely: **RSS is the measure of record, but only
  measured at the scale being claimed, one arm per process** — never projected from a
  smaller store, and never read from a process that built more than one arm (F53).

- **F53 — a multi-arm process cannot yield valid per-arm RSS.** In one process building
  all three arms, S's RSS delta reads 262.7 MB and G's 139.3 MB against 382.8 MB and
  263.9 MB in their own processes: the second and third arms reuse pages the first one
  freed. Only one-arm-per-process RSS deltas are valid, and any table mixing them is
  wrong by up to 47%.

- **F54 — RSS exceeds `Devel::Size` on every arm, surface and bpd measured, by 12.6–40.6%,
  and the gap fraction is largest where the store is smallest** (Tomcat bpd 53: S 40.6%,
  G 39.3%; fan-out bpd 53: T 18.4%). So `Devel::Size` systematically understates a
  compact store's real footprint more than it understates a large one — which cuts
  *against* the compact arms in the honest accounting, and is why both columns are
  reported side by side rather than either alone.

- **F47 — the merge parity extends to every merge shape, and S's only divergence from T
  is cost.** Rollup (many keys into one target), maximally disjoint pairs, merge depth and
  order permutations: T and S digests are identical at both bpd on both fixtures,
  including the order-dependence counts and every error distribution. P8+P9 carry the
  production merge semantics exactly in shapes the prior stage never tested; the dense-view
  round trip made S 1.4–2.0× slower per merge, which is what the native span merge (F41)
  removes.

- **F48 — the one-bin breach is a merge-DEPTH effect, not a disjointness effect.** A
  *single* merge of two maximally disjoint keys (gaps to 4.84 decades, union geometry to
  6,068 bins) stays within one bin on 3,999 of 4,000 evaluations (worst 1.0008). It is
  *successive* merges that break the bound, because each remap re-projects
  already-remapped counts by geometric midpoint and the displacement compounds. This
  sharpens the attribution behind proposed amendment A4.

- **F49 — G's merge-cost advantage widens with union width, to three orders of
  magnitude.** Per merge, G against T: 0.96 vs 53.8 µs (56×) at bpd 53 on the fan-out
  fixture; 1.24 vs 589.7 µs (**475×**) at bpd 616; on disjoint pairs 81× to **745×**.
  T's per-merge cost scales with the union `bin_count` (461 → 5,358 slots from bpd 53 to
  616 gives 53.8 → 589.7 µs); G's scales with occupied span, which is far smaller and
  grows sub-linearly. Under the rollup shape G is also *more accurate* than T (p50 error
  0.08–0.11 bins against 0.09–0.47, max 0.60–0.99 against 0.52–1.41), so on that shape
  it is not a speed/accuracy trade at all.

- **F50 — several locked `-V` fields have no discriminating power as parity assertions,
  because they are constant in shipped ltl.** `counter_update`'s own header records that
  the over/underflow counters are unreachable without a growth cap — the extend-and-reassign
  path always succeeds — so `percentile` never takes its `'low'`/`'high'` exits from a
  streaming store. Every ltl run captured (default sort, `-so p99`, and `-o`) emits twelve
  `none`. Forcing the audit at all required the library's `max_rebins` hook. So
  `partitions_with_overflow_count`, `partitions_with_underflow_count` and
  `out_of_range_bounded` pass trivially for T *and* S; **the fields that actually
  discriminate are `partition_count`, `total_rebin_events`, `max_partition_bins` and
  `rebins_per_partition`** — all four exact for S. A harness asserting only on the
  constant fields would be asserting on invariants, not on agreement.

- **F51 — `percentiles_emitted` is a static table and must be reproduced as one.**
  `emit_bin_counter_mode_verbose` reads a hardcoded per-consumer list, while
  `calculate_statistics_bin` derives a demand-narrowed ladder (terminal_core alone when
  `csv_body` and `extended` are both off). ltl printed the full twelve in every run,
  including runs where only four quantiles were actually computed. A replacement must emit
  the **static** list, not the derived one, or it will diverge on a field that never
  depended on the store.

- **F45 — today's shipped merge is order-dependent, and the dependence is the common
  case, not the corner case.** Merging the same key set in different orders
  (`prototype/426-results/n5-merge-shapes/`, 25 groups × 8 keys × 4 permutations):
  **T and S land on different state on 68% of groups at bpd 53 on the DPM file, and on
  92% at bpd 616 on the fan-out fixture**, with a per-quantile spread up to **2.00 bins**.
  **G is exactly order-independent — 0% of groups, 0.0000 bins, at every setting
  measured.** S reproducing T's order-dependence exactly is itself the parity proof: S is
  not introducing or removing the behaviour, it is the same arithmetic in a different
  container. The consequence for today's tool is that a `-g` consolidation's percentiles
  depend on the order in which keys happened to be merged — which the harness cannot see,
  because the order is deterministic for a given input.

- **F46 — T's accuracy degrades monotonically with merge depth and breaches the R4
  one-bin bound; G holds the bound exactly.** Per-quantile error against the exact oracle
  after 1, 3, 7 and 15 successive merges (200 groups × 16 keys, bpd 53, DPM):

  | depth | T max error | T cells > 1 bin (of 1000) | G max error | G cells > 1 bin |
  |---|---|---|---|---|
  | 1 | 1.2502 bins | 48 | **1.0000** | **0** |
  | 3 | 1.4046 bins | 66 | **1.0000** | **0** |
  | 7 | 1.5125 bins | 78 | **1.0000** | **0** |
  | 15 | 2.1026 bins | 98 | **1.0000** | **0** |

  This confirms and sharpens F25, and is the direct grounding for **proposed amendment
  A4**: #189's R4 bound holds only while no remap has occurred, and every merge is a
  remap. The correction applies to **today's shipped code regardless of which
  representation is adopted** — G's exact adherence is a property of having no remap at
  all, not a benefit that must be bought.

- **F44 — `counter_memory_bytes` is not deterministic across runs of real ltl, while
  every other locked D8 field is.** Three identical invocations of ltl on the same file
  emit identical `partition_count` (2,514), `total_rebin_events` (15),
  `max_partition_bins` (397) and `rebins_per_partition`, but `counter_memory_bytes` moved
  between **5,988,852 and 6,149,748 — a 2.7% spread on byte-identical input**. The field
  is `Devel::Size::total_size($store)` over a hash-backed store, and Perl's per-process
  hash seed changes the bucket allocation. Two consequences: **(a)** a `-V` diff against
  ltl must mask that one field (the prototype already does, and the prior stage's
  byte-identical claims were made with it masked — F44 confirms the masking is necessary,
  not merely convenient); **(b)** it independently justifies the audit's rule that **RSS
  is the memory measure of record and `Devel::Size` is reported only alongside it**.

- **F42 — S populates every locked Decision 8 `-V` field identically to T; six go inert
  under G.** Probed rather than asserted (`prototype/426-n7-field-census.pl` asks each
  arm's own store for a populable source per field, on a live store). S: all ten fields
  YES, same values as T. G: `total_rebin_events`, `max_partition_bins`,
  `partitions_with_overflow_count`, `partitions_with_underflow_count`,
  `rebins_per_partition` and `out_of_range_bounded` have no source, because the
  representation has no rebin, no bounded partition and no out-of-range state — the
  consequence #187 D4/D5 make structural, not a defect. So **a plain diff of the `-V`
  section against ltl is a valid gate for S and is not one for G**, which needs the
  amendment A2/A3 propose before it can be diffed at all.

- **F40 — the merge aliasing path is reachable in ltl but safe as ltl uses it.** The
  verbatim `merge_bin_counter_entries` adopts `$source->{partition}` and
  `$source->{bins}` **by reference** when the target is empty, and
  `merge_log_message_entry_into_cluster` creates exactly that empty target
  (`$target->{bin_entry} //= { partition => undef, ... }` in `merge_bin_state`). So the
  adopt path runs in production. But the same wrapper **deletes the source counter slot
  immediately afterwards** (`delete $log_messages_counters{$key};`), leaving the aliased
  structures with a single live owner. The N2 probe's A21 divergence (T diverging from
  S/S2 after adding to *both* keys post-adopt) exercises a state ltl never reaches.
  **A replacement must preserve the delete, not the aliasing** — and a columnar store that
  copies instead of aliasing is therefore free to do so.

## Verification instrument

The before/after instrument is the #417 sub-stage timing, which attributes 97% of the
statistics phase to the two `%log_messages` traversal blocks:

```bash
./ltl --disable-progress -ni -V benchmark-data -mem --terminal-width 200 -so p99 \
      logs/ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log > /tmp/426-<arm>.out 2>&1
grep -aE 'TIMING.*calculate_statistics|COUNTS.*log_messages|MEMORY.*log_messages' /tmp/426-<arm>.out
```

Denominators cross-validate against `COUNTS log_messages_entries` (final structure state,
computed by walking the store at emission time) and `COUNTS log_messages_population`
(block-boundary walk-time population). Per `tests/HARNESS-DESIGN.md` these are **distinct
quantities and are not silently converged**; a compact store changes how the first is
computed, and that distinction is re-recorded here when it does.

## Boundaries

- **In scope — every observation-holding structure.** A data-model redesign is analysed
  across all of them (architect, 2026-08-25): the per-message store (the motivating
  case), the bucket-scoped stores (`%log_analysis`, `%log_stats`), and the heatmap and
  histogram counter stores. An earlier revision of this document declared the latter two
  groups out of scope; that was drafting text, never an architect's decision, and it is
  withdrawn. Where a structure turns out not to need changing, that is a *conclusion of
  the analysis*, recorded with its grounds.
- **Out of scope**: the `mean_bytes` / `count_mean` sort-key bug (F8, filed as #428);
  #273's `total_duration` collapse (adjacent, not folded in).
- **This document does not lock decisions.** `Dxx` entries appear only after the
  prototype that grounds them.

## Related issues

- **#2 — memory ceiling / adaptive controller.** Blocked by this issue: its levers
  (promotion, eviction) operate on this store, and its per-entry arithmetic is
  invalidated by any change to entry overhead (F10). Its feature doc is deliberately
  unwritten and starts from the store this issue delivers (F9).
- **#415 — statistics-phase drift** (closed). Origin of the finding; record at
  `tests/profile/results/415-statsdrift-new/analysis.md`.
- **#354 — `-mdm bin` uses more message-stats memory than raw** (on hold, behind #2).
  Source of the per-entry byte figures — reproduced by this prototype (F19: 2,383 B of
  counter entry per message at 287k keys) and addressed by P8/P9.
- **#189 — unified histogram bin-counter primitives** (closed) and **#187 — primitive
  contract for percentile and histogram consumers** (closed). The primitives this
  store's bin path calls; their validation record
  (`prototype/189-bin-counter-primitives-validation-report.md`) and locked decisions
  (`features/187-histogram-bin-counter-percentiles.md`) are what § Next step
  revalidates against the proposed representation. #201
  (`features/201-display-geometry-bound-consumers.md`) owns `partition_rebin`, which
  the shared grid (P10) would retire; #287
  (`features/287-message-stats-bin-counter-data-model.md`) owns the per-message bin
  data model this store replaces.
- **#323 — dynamic bins-per-decade** (on hold). Same distribution evidence.
- **Defects found by this investigation and filed separately (2026-08-26).** All four describe
  shipped behaviour, are independent of which representation is adopted, and are kept out of this
  issue's scope so a data-model change does not absorb independent bug work:
  - **#459** — `-g` consolidation under `-mdm bin` gives different percentiles depending on merge
    order; the merge arithmetic is not commutative (68–92% of groups, up to 2.0 bin widths).
    Distinct from #284, which fixed *which key seeds a cluster*; this is the arithmetic below it.
  - **#460** — the one-bin percentile accuracy guarantee is documented as structural but is breached
    after any re-binning (2.10 bin widths at merge depth 15; also two unmerged cases). Resolvable by
    amending the contract (drafted as A4) or by changing the mechanism. **Broadened after filing** to
    carry two further corrections owed to the same contract document, so one amendment pass fixes all
    three: the out-of-range counters are documented as live but never fire under the current growth
    policy (leaving three verbose fields constant, and therefore useless as parity assertions), and the
    documented merge description says "extend the narrower side" where the shipped code re-projects
    both sides into a spanning range — the code being correct and the description wrong.
  - **#461** — `counter_memory_bytes` varies 2.7% between runs on identical input, while every other
    locked field in the same block is stable.
  - **#462** — re-binning caused by merges is invisible in the telemetry, so the counters read as
    "geometry is stable" during exactly the runs where it is least stable.
- **#458 — `-n 0` retains and computes nothing per message.** Removes the per-message store by
  construction rather than making it cheaper, and the per-message surface is the only one on which
  this issue's container change earns its headline figures. The two address the same pressure by
  opposite means and are complements, not alternatives: #458 serves runs that decline per-message
  output; #426 serves runs that want it, which still pay T's ×10.3 ladder growth, still breach
  #187 R4 after any merge, and still carry order-dependence. `-n 0` does nothing for the bounded
  surfaces, where the compact arms are neutral-to-worse. Analysed in
  `features/426-three-arm-comparison.md` § 1.0 and § 7.0.
- **#450 — the shipped bin-model display renders and the `-g` × `-mdm bin` merge path
  are asserted by nothing.** Found by this issue's pre-prototype audit; pre-existing and
  out of scope here, but they are the two harness gaps a container change lands on.
- **#428 — `-so mean_bytes` / `-so count_mean` rank nothing** (F8). Found during this
  survey; independent of the store's representation. A compact store with a declared
  column set would surface this defect class mechanically.
- **#418 — sort-on-statistic pays full population cost when no key is eligible.**
  Operates on the same `sort_selection` block; strong interaction with arm B.
- **#273 — collapse `total_duration` / `total_duration_num`.** A compact store makes this
  cheaper; kept separate.
- **#58 / #23 — format registry.** The generated scan sub is this store's producer; F16
  in `features/log-format-registry.md` is rewritten against the new store when this lands.
- **#349 / #305 — demand contract.** The gating this store must preserve; recorded in
  `features/305-shape-moment-extended-percentile-demand.md`.

## Acceptance criteria / merge gate

For **this specification stage**:

- [x] Producer/consumer inventory reconciles to the 167 `log_messages` references at
      `09262f7`, classified by access pattern, anchored by sub name.
- [x] Field census mechanically derived, including alias-only and transient fields, with
      the two-provenance and dual-typed cases called out.
- [x] Demand/mode gating contract recorded as a constraint on any replacement.
- [x] Candidate representations specified with falsification criteria, including the
      cheap non-data-model arms.
- [x] Open questions Q1…Q12 registered as the prototype's exit criteria.
- [x] Measurement protocol specified (scaffold, staging, fixture, parity, metrics).
- [x] Issue-cited artifacts verified; corrections recorded (F9).
- [x] Verification instrument confirmed present on the current tree.

For the **prototype stage** (measurements complete 2026-08-24):

- [x] Q1–Q4, Q8, Q10, Q12 answered with medians and ranges (report V1–V6).
- [x] Q5, Q6, Q7, Q9 (one shape measured), Q11 explicitly deferred with the reason.
- [x] Findings report delivered before any disposition question.
- [x] Bin-mode stores measured (V7) and shared-grid fidelity measured (V8).
- [ ] Bin-counter primitives revalidated against the proposed representation through
      every #189 validation aspect (§ Next step) — **gate for implementation**.
- [ ] `Dxx` locked by the architect from § Proposed decisions.

For **implementation** (not started; gated on the #189 revalidation above): full
`tests/validate-*.sh` suite exits 0;
runtime-warning-clean stderr; benchmark regression check against the last released
baseline; F16 rewritten; `compare-results.sh` `tmap` updated in the same commit if any
`TIMING`/`MEMORY` label changes.
