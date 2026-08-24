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

Prior art in this repo: `prototype/58-entry-struct-mini.pl` already compares
`aoh` / `hoh` / `aoa` / **`soa` (parallel arrays indexed by entry id)** across build,
memory and scan phases, asserting classification parity per shape before any timing. It
is the direct template. `features/58-format-registry-staged-detection.md` records the
closest methodological precedent for the ordinal idea itself: name→ordinal resolved once
at load, integers on the hot path.

## Open questions (the prototype's exit criteria)

Numbered so the later locked decisions map one-for-one. **None is answered here.**

| id | question | blocked on |
|---|---|---|
| **Q1** | Does a columnar store actually realise the L2 traversal gain, or does L2 measure something (fresh contiguous hashes) that SoA does not reproduce? | D vs A at 100k/1M |
| **Q2** | What does the ordinal scheme cost on the write side, per line, at 1M lines? | D/E vs A build metric |
| **Q3** | Are column arrays allocated by demand at option-resolution time, or lazily on first write? What does an undemanded column cost in each case? | D/E memory metric |
| **Q4** | How is deletion represented — tombstones, compaction pass, or restructuring consolidation to avoid deletion? What is the memory and time cost of each under `-g` churn? (F3) | dedicated deletion metric |
| **Q5** | Does `merge_consolidation_stats` receive a materialized hashref row view, or is the merge surface rewritten? (F4) | parity + one-shot cost |
| **Q6** | How is F7's arbitrary runtime key set written into a fixed column layout? | D/E design |
| **Q7** | Is `%log_messages_counters` re-keyed by ordinal, or does it keep its `\x1f` composite key? | Q4's answer; `snapshot_counter_telemetry` walks it wholesale |
| **Q8** | Do the four variants (F2) get four column sets, or one superset with unallocated columns? | Q3 |
| **Q9** | Does the two-valued category (F1) fold into the ordinal space, or stay a separate dimension? | D/E design |
| **Q10** | Do B/C alone close enough of the gap that D/E are not justified? | B+C vs D at 100k/1M |
| **Q11** | What happens to `MEMORY log_messages` attribution, which #2 consumes as a controller signal — is per-column attribution preserved? | #2's requirement |
| **Q12** | ~~How much of the 465 B/key is the key string, and therefore untouched?~~ **Answered 2026-08-24**: inner entry hash 213.0 B (45.8%); keys + outer hash overhead 251.6 B (54.2%), keys cap-saturated at the terminal width. Remaining sub-question: does the compact store's own per-field array overhead eat into the 45.8%? | measured; residual on D/E memory metric |

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
  Source of the per-entry byte figures.
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

For the **prototype stage** (not started): Q1…Q12 answered with medians and ranges;
`Dxx` locked; findings report delivered before any disposition question.

For **implementation** (not started): full `tests/validate-*.sh` suite exits 0;
runtime-warning-clean stderr; benchmark regression check against the last released
baseline; F16 rewritten; `compare-results.sh` `tmap` updated in the same commit if any
`TIMING`/`MEMORY` label changes.
