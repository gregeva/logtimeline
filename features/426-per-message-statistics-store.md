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

Scope note: this is the store for *per-message-key* statistics. The bucket-scoped store
(`%log_analysis` / `%log_stats`) is a different structure with a different cardinality
profile and is out of scope.

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

**Not covered**: display-geometry-bound consumers (F2 heatmap / F3 histogram, D5's
F2/F3 contract, R12 as a finalize re-bin) under G; a second log surface for V1/V3/V5
(all on the Tomcat file; DPM not re-run); real ltl end-to-end under G (no baseline
re-bless enumerated); a native span-array merge for S (the harness shape was
measured); fan-out beyond 51,469 keys.

**Step 3 is the architect's.** Nothing above is a `Dxx`; P1–P10 remain proposals.

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

- **Out of scope**: the bucket-scoped stores (`%log_analysis`, `%log_stats`); the
  heatmap/histogram counter stores; the `mean_bytes` / `count_mean` sort-key bug (F8,
  filed as #428); #273's `total_duration` collapse (adjacent, not folded in).
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
