# Feature Requirements: Log Format Registry

## Status

- **Release re-cut (2026-08-23, D59): 0.17.0 ships now, without #387 and #60.** Architect decision: the value already merged (registry #58, variant groups #384, WGM format #395, Drop 0, bug fixes) ships immediately; #387 (Drop 1.75) and #60 (Drop 2) are design-heavy and unstarted, and the architect wants real-world exposure with the built parts before designing on top of them. They move to the 0.18.0 merge train unchanged in order and gating (#387 → #60, `#60 blocked_by #387` stands). Next: cut v0.17.0 per the release process, then #387 opens 0.18.0.
- **Train re-sequenced (2026-08-23): #387 slotted as Drop 1.75 ahead of Drop 2.** User YAML format definitions require a home configuration directory and file convention for `ltl` (location, naming, discovery order), which does not exist yet; #60's configuration cascade has a registry/user-configuration layer that must wire to that directory rather than invent it. Native edges: #387's dead `blocked_by #58` dropped; `#60 blocked_by #387` recorded. Train order: #58 ✅ → #388 ✅ → #384 ✅ (Drop 1.5) → #387 (Drop 1.75) → #60 (Drop 2). Next: #387. **Same day: native sub-issue tree built under #23** — sub-issues had never been used in this repo (the phase issues predate native-linkage adoption; "Parent: #23" existed as prose only); #180, #58, #388, #384, #387, #60 (0.17.0 train), #57, #59, #61, #55 (Phase 2+4 release), and #386 (follow-up) are now native children of #23 in that order. Extended later the same day with the consumer arc: #17 (unit sampling half), #154 → #155 (timezone chain), #401, #372, #218 (derived/paired-metric consumers of Phase 4) — 17 children total; sequencing carried by the native `blocked_by` graph. #57/#55 statuses trued up to `on hold` (the D21 deferral that already governs #59/#61).
- **Drop 1.5 (#384) planned (2026-08-22):** filename provenance evidence and variant groups specified in this document (§ "Drop 1.5 — #384" below; #384 has no feature file of its own — this umbrella is its record). Architect decisions D44–D52 and implementation decisions I1–I8 locked through interview (I1–I8 proposed and locked the same day). #60 (Drop 2) re-gated on #384. #388 (detection-window N sizing) becomes a native prerequisite and carries the constraints it must settle; #385 (Integration Runtime `yyyy-dd-MM`) lands as the first variant group. Train order: #58 ✅ → #388 → #384 (Drop 1.5) → #60 (Drop 2). Next: #388's N sizing, then #384's research → prototype phase (the variant-group scan-sub selection and the probe costs are hot-path-adjacent and must be measured, per the mandatory workflow). **Later the same day (#388 kickoff): D53 locked** — a multi-spot sampling pass (a few kilobytes at the front, middle and end of the file by byte offset; fully decorrelated from the production read) replaces the front window as the evidence source, the #58 held-line window becomes the fallback for non-seekable input, and D48 and the constraints handed to #388 are amended to match; #388 re-titled to "Design and size the detection evidence sampling pass".
- **Drop 1 (#58) implemented and gate-closed (2026-08-21):** the per-line match-type cascade is replaced by the format registry — declarative specs (pattern, field map, transforms, three-part time contract, duration unit + ambiguity flag, guards, head_class, samples with expected records) compiled at startup into a single generated scan sub per MTF order (D39/D40: eager precompilation, order-signature cache, pinned-closure recency promotion), validated by the D24 gates on every run. Byte parity proven (shadow mode 241 runs / 0 divergences; post-swap full-output diffs); every 1m fixture family net faster (pure-access −13.1%, concat-pair −11.0%, interleave −6.0%); #369's access read-phase regression removed as a class (read_files −13.6% vs v0.16.0). Scan telemetry shipped in `-V format-detection / scan`; format-carried units + the D18 unit-ambiguity note shipped (R5). Follow-ups filed: #386 (analysis precision), #387 (user YAML formats — the D37 re-sequenced R4 surface), #388 (detection-window N sizing, D38). Full record: `features/58-format-registry-staged-detection.md`. Next: Drop 2 (#60).
- **Drop 1 (#58) research + prototype phase complete (2026-08-20):** the mandatory pre-implementation cycle ran end to end on branch `58-format-registry-staged-detection` — research F1–F8, application audit A1–A11, prototype findings P1–P9, decisions D24–D34 locked. Full record in `features/58-format-registry-staged-detection.md`; umbrella summary in the Decision Log entry below. Q2 (pattern priority) resolved by D26; Q3 (inheritance) and Q5 (strict mode) deferred to #58 implementation planning. Backlog side-findings: #382 (GC pause-form gap), #383 (timestamp-cache growth). Next: #58 implementation planning against the locked decisions.
- **Drop 1 (#58) implementation planning complete (2026-08-20):** Q3 resolved as sparse-override (D35), Q5 resolved as no-strict-mode (D36), R4's user-facing YAML surface re-scoped to a follow-up issue with YAML::PP as a hard dependency when it lands (D37 — see the D12 true-up in the Decision Log), detection-window N-sizing split to a follow-up prototyping issue (D38). Full record in `features/58-format-registry-staged-detection.md`; staged implementation underway on branch `58-format-registry-staged-detection`.
- **Drop 0 shipped (2026-08-20):** #180 (named pipeline stages) merged into `release/0.17.0` via PR #380 and closed — five `pipeline_*()` entry points with documented role contracts; stage-coherent `stage/step` timing nomenclature (decision recorded in `features/180-named-pipeline-stages.md`). #379 (spaced input paths failed to open — csh `glob()` whitespace splitting) found while gating and fixed via PR #381. Next: Drop 1 (#58), opening with its mandatory research → prototype phase; hand-forward notes for #58/#60 on their issue threads (2026-08-20).
- **Last reviewed:** 2026-08-20
- **Scope re-cut (2026-07-15, later same session — D21):** Phase 2 moves out of 0.17.0 as well: its motivating consumer is Phase 4's inter-line derived metrics, so **Phases 2 and 4 ship together in a later release** (with #57 and #55). 0.17.0 = Drops 0/1/2: #180 → #58 → #60. Account-at-read-time locked as the universal time-attribution semantic; temporal interpolation not planned, spec'd for the record in #370 (D22).
- **True-up (2026-07-15):** Implementation scheduled for release 0.17.0 as a merge train of section drops on `release/0.17.0` (~~Phases 1–3~~ re-cut by D21 above; Phase 4 deferred to a later release). Prerequisite graph collapsed since 2026-05-09: #34/#41/#51 closed (superseded/resolved by the #187/#189 unified bin-counter contract), #179 shipped with a narrowed role (detect-stage hints only), #181 reframed as architecture guidance rather than a deliverable. Memory design target reframed: eliminate waste and stay bounded/accountable — do not minimize to the floor; available memory is spent on fidelity. See Decision Log entry for 2026-07-15 (D15–D19).
- **Sequencing change (2026-05-09):** Pre-requisite "staging primitive" work lands on separate branches against today's architecture *before* #23 implementation begins. This shrinks the rewrite's surface area. New prerequisite issues filed: #179 (index read-back), #180 (named pipeline stages), #181 (buffered read pipeline). Existing issues #41, #34, #51 updated with Phase 2 alignment requirements and re-classified as Phase 2 prerequisites. See "Decision Log" entry for 2026-05-09 below.

## Overview

Refactor the core parsing architecture from an implicit match-type conditional chain to a data-driven format registry. This enables format-aware features, user-extensible format definitions, and improved processing performance.

## Background / Problem Statement

### Current Architecture (as of 2026-05-09)

The main parsing loop in `read_and_process_logs()` (`ltl:3590-4407`) uses a numbered match-type system:
- **13 conditional branches** confirmed at `ltl:3689-3840`, each with a regex pattern
- Match type is determined implicitly by which regex matches first
- Format metadata (like duration unit) is not captured
- The `$is_access_log` flag is a boolean that loses format-specific information

```perl
# Current approach (simplified)
if ($_ =~ /ThingWorx pattern/) {
    $match_type = 1;
    # extract fields positionally
}
elsif ($_ =~ /Access log pattern/) {
    $match_type = 3;
    $is_access_log = 1;
    # extract fields positionally
}
# ... 11 more patterns through match_type 13
```

#### Adjacent state worth noting (added 2026-05-09)

- **#46 Index file (`ltl-index.csv`)** — `write_index_file()` at `ltl:524-668` *writes* per-file metadata (line/match counts, first/last timestamps, duration/bytes/count min/max/avg, ts_precision) on every run. **No code path reads it back today.** Issue #179 will add read-back so prior-run metadata can pre-seed bound discovery.
- **#22 UDM (custom metrics + units + simple delta)** — shipped at `ltl:3905-3955`. Includes a *global, last-value-only* `delta()`/`idelta()` (`ltl:3933-3946`, state in `%udm_last_value` `ltl:157`). Phase 4 of this issue replaces it with the per-message-identity engine (decision D10, 2026-05-09).
- **#96 Fuzzy message consolidation** — shipped v0.13.0. Established the S1-S5 staged pipeline pattern, the architectural template Phase 2 reuses (see "Architectural Template" section below). State in `%consolidation_*` persists across the entire run.
- **Implicit pipeline order** — the call sequence in `## MAIN ##` (`ltl:7677`) is: `read_and_process_logs` → `initialize_empty_time_windows` → `group_similar_messages` → `calculate_all_statistics` → `calculate_heatmap_buckets` → `calculate_histogram_buckets` → `normalize_data_for_output` → `print_bar_graph` → `print_histograms` → `write_index_file`. Issue #180 will name these stages explicitly (detect / parse / accumulate / finalize / render).

### Problems with Current Approach

1. **No format metadata**: Cannot associate duration units, field names, or other properties with formats
2. **Pattern duplication risk**: If format patterns need to be used elsewhere (e.g., detection), they must be duplicated and may drift
3. **Hard to extend**: Adding a new format requires modifying Perl source code
4. **Implicit knowledge**: The code "knows" match_type 3 is an access log, but this isn't declared anywhere
5. **Performance**: Every line evaluates the full conditional chain until a match is found; for large files matching a pattern late in the chain, this is expensive
6. **No user extensibility**: Users cannot add their own log formats without modifying source

## Motivation

### 1. Performance at Scale

The current chained conditional regex logic is evaluated per line. As the list of supported log formats grows, this becomes exponentially expensive for files that match patterns later in the chain. For a 277MB access log with millions of lines, repeatedly evaluating 12+ regex patterns per line when only the last pattern matches is wasteful.

**Goal**: Once the format is detected for a file, subsequent lines should only run the known pattern's extraction logic, not re-evaluate all patterns for every line.

### 2. User Extensibility

Users have log formats specific to their environments that are not built into the tool. Currently, they cannot add support for their own formats without modifying the Perl source code.

**Goal**: Allow users to define custom log formats via external configuration files, extending the tool's capabilities without code changes.

### 3. Staged Detection with Known Conditions

Detection and processing should happen in stages:
1. **Format Detection**: Identify which log format is being processed
2. **Format-Specific Processing**: Apply format-specific knowledge (field positions, duration unit, etc.)

This staged approach allows using knowns to guide automated determinations. Once we know the format, we can apply all the format-specific rules confidently rather than guessing.

### 4. Duration Unit Autodetection (Issue #17)

The duration unit autodetection feature exposed these architectural limitations. The initial implementation attempted a separate file scan with simplified patterns, which was rejected because:

- **Knowing the field doesn't mean knowing the unit**: Just because we can identify that field 8 contains a duration value doesn't tell us the unit. The same `%D` directive means milliseconds in Tomcat 9 but microseconds in Apache HTTP Server.

- **Similar fields with different semantics**: Nginx access logs may contain `$request_time`, `$upstream_response_time`, `$upstream_connect_time`, and `$time_to_first_byte` - all are durations but with different meanings.

- **Format identification must come first**: Before we can interpret any field, we must know which log format we're dealing with. Detection must happen in stages: first identify the format, then apply format-specific knowledge.

While duration autodetection alone would not justify this refactor, it highlighted the broader architectural issues that affect performance, extensibility, and maintainability.

### 5. Maintainability

Having a single source of truth for format definitions:
- Eliminates pattern drift between detection and processing
- Makes adding new formats straightforward
- Enables format-level testing
- Documents format specifications in a structured way

## Goals

1. **Centralized format definitions**: Each log format defined once with all its properties
2. **Format-aware field extraction**: Once format is identified, use format-specific knowledge for field interpretation
3. **Staged detection**: Detect format first (once per file), then apply format-specific rules for all lines
4. **User extensibility**: Allow users to define custom log formats via external configuration files
5. **Performance optimization**: Once format is detected for a file, skip re-detection for subsequent lines
6. **Duration unit autodetection**: Enable proper autodetection by tying unit knowledge to format definitions
7. **Maintainability**: Single source of truth for format patterns and metadata
8. **Deferred-per-bucket processing**: Redesign the core processing pipeline from streaming single-pass to a model where raw data is collected per time bucket, processed when the bucket closes, then freed
9. **Derived metrics**: Support user-defined metrics computed from raw fields (intra-line arithmetic) and from stateful functions across time (inter-line deltas, rates)
10. **Metric visibility control**: Allow each metric (raw or derived) to declare where and how it is used — graph columns, CSV output, internal-only, time-bucket rows, message-level stats
11. **Sliding window memory model**: Hold raw data only for active buckets, freeing memory as buckets are finalized, with visibility into per-pattern memory usage
12. **Unit system**: Every metric carries a declared unit type with normalization and display formatting, building on existing conversion functions

## Architectural Template: Staged Pipeline (added 2026-05-09)

The S1-S5 staged pipeline shipped in #96 (v0.13.0, fuzzy message consolidation) is the canonical architectural template for the engine rewrite. See `docs/staged-processing-pipeline.md` for the full pattern. Phase 2 (#59) and Phase 4 (#61) must reuse the following patterns rather than reinventing them:

### Patterns to reuse from #96

- **Checkpoint-based batched processing.** Work happens in named checkpoints rather than per-line. Memory is bounded per checkpoint; transient data structures are built and freed within each checkpoint. Phase 2's per-bucket finalization is the same shape — open bucket, accumulate, close bucket, finalize, free.
- **Deterministic ordering via `sort keys %hash`.** Perl's hash iteration is randomized per process. Any ordering-sensitive loop must use `sort keys` to produce reproducible results. Violated → PF-23 in #96 produced different consolidations per run. Phase 4's per-message-identity state tracking has the same risk.
- **Hot-sort for hot-path lookups.** Frequently-matched entries bubble up by one position per hit (`match_consolidation_patterns()` in #96). Phase 1's format-detection cache and Phase 4's per-identity state cache should adopt this.
- **Profile-ready counter contract.** Every staged function emits a per-run counter visible in `-V` output (e.g., `S1=282081, S4=4416, S5=24`). The tracking invariant `S1 + S2 + S3 + S4 + S5 = keys_seen` is a built-in sanity check. Phase 2's per-bucket lifecycle and Phase 4's derived-metric calculations must emit equivalent counters.
- **Per-checkpoint memory release.** `%key_trigrams`, `%ngram_index`, `%key_trigrams_norm` are freed at each checkpoint boundary (`run_checkpoint()` in #96). Phase 2's sliding window does the same for raw bucket data once stats are computed.

### Specific subroutines from #96 that Phase 4 will reuse

The similarity engine that powers fuzzy consolidation also serves Phase 4's per-message-identity grouping (already noted in Section 9 — RESOLVED). Phase 4 should call these existing subs directly rather than reimplement:

- `find_candidates($source_key)` — trigram pre-filter + Dice verification, returns candidate keys above threshold.
- `dice_coefficient(@a, @b, $threshold)` — numeric similarity 0–1.
- `compute_mask($string_a, $string_b)` — character-position keep/variable mask.
- `derive_canonical(@mask, $reference)` — generalized display string with `*` wildcards.
- `derive_regex(@mask, $reference)` — compiled `qr//` pattern.
- `try_consolidation_merge_into_existing($new, \%patterns)` — merge-first generalization.
- `consolidation_process_key($log_key, $category, $capped_msg)` — S1 inline match gate.
- `run_consolidation_checkpoint($category, $grouping_key)` — orchestrates S2→S3→S4 pipeline.

These are production-tested at 7.9 GB / 40.6M lines (488s, 88% less memory than baseline). Phase 4 imports them; it does not reimplement.

## Requirements

### Functional Requirements

#### 1. Format Definition Properties

Each log format definition must include:
- **Pattern**: Regex to match log lines
- **Field mapping**: Which capture groups correspond to which fields (timestamp, message, duration, bytes, etc.)
- **Timestamp format**: How to parse the timestamp
- **Duration field**: Which field contains duration (if any)
- **Duration unit**: The unit for duration values (ns, us, ms, s) - this is format-specific knowledge
- **Access log flag**: Whether this is an access log format
- **Format name/description**: Human-readable identifier
- **Examples**: Sample log lines for documentation and testing

#### 2. Detection Behavior

- Format detection should happen once per file (or until a definitive match is found)
- Once detected, the format should be cached for that file
- Subsequent lines should use the cached format directly, avoiding re-evaluation of all patterns
- Detection should support confidence levels (exact match vs. probable match)

#### 3. User-Defined Formats

- Users should be able to define custom log formats via external configuration file(s)
- User formats should be loaded at startup
- User formats can extend or override built-in formats
- Format validation should catch errors in user definitions

#### 4. Duration Unit Handling

With format registry in place:
- Duration unit is a property of the format definition
- Autodetection works by: identify format → look up format's duration unit → apply conversion
- Manual `-du` override still takes precedence over format-defined unit
- Formats with ambiguous units (same pattern, different units across servers) need disambiguation strategy

#### 5. Ambiguous Format Handling

Some formats have identical patterns but different semantics:
- Tomcat 9 `%D` = milliseconds
- Tomcat 10.1+ `%D` = microseconds
- Apache HTTP Server `%D` = microseconds

The system needs a strategy for disambiguation:
- Filename/path hints
- User specification via command line
- Statistical analysis of values as a fallback
- Clear warning when ambiguity cannot be resolved

#### 6. Processing Model Redesign

The core processing pipeline must change from a streaming single-pass model to a deferred-per-bucket model:

**Current model:** Read line → match → extract → count into bucket → discard line. Raw data is lost immediately after counting.

**New model:** Read line → parse minimally (extract timestamp, raw fields) → store in time bucket → once bucket is "closed" (reading has advanced sufficiently past it) → run grouping, derivation, delta calculations, statistics, and heatmap computations on that bucket's collected data → produce final counts/stats → free raw data.

**Why (reframed 2026-07-15, D15):** The purpose of the deferred-per-bucket model is to **unlock calculated metrics over a complete time bucket** — computations that need the full picture of a bucket's data before they can run (per-bucket statistics finalization, message-identity grouping within a bucket, and eventually Phase 4's inter-line derived metrics and transaction correlation). It is *not* a memory-reduction play. The sliding window's memory contribution is **waste elimination** — raw data whose consumers have all run is freed instead of persisting to end-of-run — and **structural boundedness**, not a lower peak than today's model.

Key implications:
- **Statistics and heatmaps computed inline**: These currently run as a batch after all reading is complete. In the new model, they must be computed per-bucket as each bucket is finalized, since the raw data will be freed afterward.
- **Sliding window**: Only the current bucket and a small number of trailing buckets are held in memory. Once a bucket is finalized and its raw data is no longer needed for inter-line calculations, it is freed.
- **Decoupled phases**: Reading/parsing is decoupled from calculation/statistics. This separation enables derived metrics that require the full picture of a bucket before processing.
- **Memory posture (per D15)**: The per-bucket raw holding is transient working state — bounded by the window's shape, freed at bucket close, and visible in `-V`/`-mem` accounting. Success is "no waste, bounded, accountable," not "peak memory reduced vs baseline." Persistent per-key representation choices (raw array vs bin-counter partition, head/body split) are a separate concern owned by the #2 memory-ceiling umbrella and are **not** a dependency of this pipeline redesign — the pipeline feeds whatever message-stats data model is in effect, identically.

#### 7. Derived Metrics

Derived metrics are metrics that do not exist in the raw log data but are calculated from it. Two types:

##### 7a. Intra-line Derived Metrics

Computed from fields on a single log line using arithmetic expressions.

**Example:** Given `time_to_first_byte=0.43` and `backend_response_time=0.781` on the same line:
```
backend_transfer_time = backend_response_time - time_to_first_byte
```

Requirements:
- Expressions support standard arithmetic: `+`, `-`, `*`, `/`
- Expressions can reference raw fields and other derived metrics
- **Dependency ordering**: Derived metrics that depend on other derived metrics must have a resolved calculation order (dependency graph). The system must detect circular dependencies and report errors.
- Multiple intra-line derived metrics can be defined per format

##### 7b. Inter-line Derived Metrics (Stateful Functions)

Computed across log lines over time, requiring state from previous observations. Modeled after monitoring platforms (Prometheus, Dynatrace).

**Example:** Given three lines with `tcp_errors=528149`, `tcp_errors=528151`, `tcp_errors=528153`:
```
delta(tcp_errors)     → 2, 2  (difference from previous value)
idelta(tcp_errors)    → 2, 2  (difference, but only when incrementing; discards counter resets)
rate(tcp_errors) * 60 → tcp_errors per minute
```

Requirements:
- Functions include at minimum: `delta()`, `idelta()` (increment-only delta, discards counter resets)
- Additional functions like `rate()`, `irate()` should follow Prometheus semantics where applicable
- Function results can be used in arithmetic expressions (e.g., `rate(tcp_errors) * 60`)
- Inter-line functions can feed into intra-line expressions and vice versa, respecting dependency ordering
- **Per-message-identity state**: State must be tracked per message identity within a time bucket, not globally. State holds the last observed value **and its exact timestamp** — the timestamp is required so `delta()`/`rate()` divide by true elapsed time and report magnitude-correct rates. See section 9 (Fuzzy Matching) for how identity is determined.
- **Time attribution — account-at-read-time (LOCKED 2026-07-15, D22)**: A delta's full contribution is accounted in the bucket of the observation that completes it, consistent with ltl's universal semantic (a line's contribution lands in the bucket of the line's timestamp — exactly as a one-hour access-log request lands in its completion bucket). ~~Temporal interpolation (linear distribution of the delta across intervening buckets) was previously specified as mandatory here~~ — **not planned**, by architectural decision: it is the sole consumer requiring finalized buckets to be reopenable, it fabricates smoothness the data doesn't contain, and it splits the tool's time semantics. Full spec and rationale recorded in #370 (open, labeled not planned). If ever revisited: per-metric opt-in, never a default change.
- **Counter reset handling**: `idelta()` discards negative deltas (counter resets). `delta()` reports them as-is.
- **Staleness/max-gap**: TODO - determine whether a maximum time gap should exist beyond which a delta is considered stale and discarded rather than interpolated.
- **Paired start/end events**: a metric defined across two matched lines (start retained per declared key, consumed at the end line; `duration` = end − start, other values from either side) is an inter-line derived metric with a one-shot lifecycle — same substrate, see D58 and #372.

##### 7c. Reusable Metric Definitions

Derived metrics may be applicable to multiple match patterns. The configuration model must support defining a derived metric once and assigning it to multiple format/pattern definitions, avoiding duplication.

#### 8. Metric Visibility and Purpose

Each metric — whether raw or derived — must declare its purpose and visibility. This controls where the metric appears in output and whether it is held in memory.

Visibility flags (one or more per metric):
- **Graph column**: Display in the bar graph visualization
- **CSV output**: Include in CSV export (`-o` mode)
- **Internal only**: Used solely as input for other derived metrics; not displayed or exported
- **Time-bucket rows**: Show in the time-bucket aggregated view
- **Message-level stats**: Show in the per-message statistics

This decouples "what we collect" → "what we calculate" → "how we calculate" → "where this is used."

Benefits:
- Memory savings: metrics flagged as internal-only can be discarded after dependent calculations complete
- User customization: users control what appears in their output without affecting the calculation pipeline
- Scope boundaries apply to all metrics (raw and derived), configured at the match pattern level (details TBD)

#### 9. Fuzzy Matching for Message Identity

Inter-line derived metrics require grouping log lines by message identity within time buckets. This is needed because different logical sources (e.g., different APIs) may produce lines matching the same format pattern but with independent counter values.

**Example problem:**
```
10:00:01 MyFabulousAPI executed totalExecutions=123456, durationMs=234
10:00:01 JinsSuperFastAPI executed totalExecutions=5643, durationMs=12
10:00:02 MyFabulousAPI executed totalExecutions=123458, durationMs=198
```

If `idelta(totalExecutions)` is calculated globally across all lines matching this pattern, the interleaving produces nonsensical deltas. The delta must be computed per-API — per message identity.

Requirements:
- A fuzzy matching engine groups lines within a time bucket by message identity before inter-line functions are applied
- The matching engine must be configurable to control grouping granularity
- This engine should be shared with/reused by the existing "group-similar" feature
- When derived metrics produce anomalous results due to grouping issues, the user is expected to refine their filtering to isolate the relevant messages

**RESOLVED**: Fuzzy matching algorithms researched and implemented in #96 (Fuzzy Message Consolidation, shipped v0.13.0). See `docs/similarity-engine-best-practices.md` for algorithm choices and `docs/staged-processing-pipeline.md` for architecture. The same engine serves both message identity and group-similar display — the difference is configuration (grouping key granularity and similarity threshold), not algorithm.

#### 10. Memory Tracking for State

Inter-line derived metrics require per-message-identity state to be maintained across bucket boundaries (the previous value for delta calculations). This state scales with the number of unique message identities multiplied by the number of inter-line metrics configured.

Requirements:
- Per-pattern state memory usage must be included in ltl's memory tracking and reporting
- Users must be able to see which patterns and metrics are consuming memory, so they can adjust their configuration if needed
- State should be documented clearly so users understand the memory implications of their derived metric configurations

#### 11. Unit System

Every metric — raw or derived — carries a unit type. The system must know how to accept user-specified units, normalize values to a canonical internal form, and format values for display.

**Scope boundary (2026-07-15, D18):** Unit *auto-detection* — statistical determination of a unit by sampling values — and speculative unit tracking are **not** part of the #23 rewrite. The rewrite's contribution to the unit problem is declarative only: a detected format carries its known units as registry metadata (e.g., Tomcat 9 `%D` = milliseconds), which for unambiguous formats makes auto-detection unnecessary. Statistical sampling remains #17's separate, simpler follow-on for ambiguous format variants. Unit knowledge sources, in precedence order: (1) explicit `-du` override → (2) format-carried unit from the registry (this rewrite) → (3) prior-run knowledge via index read-back (#179) → (4) sample-based auto-detection (#17, follow-on; its ~100-line sampling window is the same buffered detection window described in #181).

##### Unit Types

Three fundamental unit categories, plus raw:

| Category | Internal baseline | Existing functions |
|----------|------------------|--------------------|
| Time/Duration | milliseconds | `convert_duration_to_ms()`, `format_time()` |
| Bytes | bytes | `convert_bytes()`, `format_bytes()` |
| Count | raw number | `format_number()` |
| Percent | raw (0-100) | none |
| Raw (unitless) | as-is | none |

##### Requirements

- **Unit declaration**: Users must specify the unit when defining a custom metric. No auto-detection.
- **Unit normalization**: Values are converted to the internal baseline unit on extraction. All downstream processing (statistics, derived metrics, display) works with normalized values.
- **Unit-aware display formatting**: Output functions select appropriate display units based on magnitude (e.g., 1,073,741,824 bytes → "1.0 GB", 0.045 ms → "45 us").
- **Unit propagation in derived metrics**: When a derived metric is computed from fields with units, the result's unit must be explicitly declared. The system does not infer units from arithmetic (subtracting two durations could be a duration, but dividing bytes by duration is a rate — the user must state the result unit).
- **Format registry integration**: Format definitions declare units for their fields (e.g., "field 8 is duration in microseconds"). This replaces the current `-du` command-line approach with declarative, per-format knowledge.

##### Existing Code Foundation

The following functions already exist in `ltl` and provide a solid base:
- `convert_duration_to_ms()` (line ~559) — handles s, ms, us, ns
- `convert_bytes()` (line ~726) — handles B, kB, KB, MB, GB, TB; accepts "100 MB" string format
- `format_time()` (line ~894) — display formatting with short/medium/long styles, handles us through days
- `format_bytes()` (line ~757) — display formatting with automatic unit promotion
- `format_number()` (line ~864) — SI-style abbreviations (k, Mil, Bil, Tril)
- `format_heatmap_value()` (line ~2902) — routes to appropriate formatter by metric type

##### TODOs for Issue #22

- [ ] Audit existing conversion functions for gaps and edge cases
- [ ] Known issue: `format_bytes()` uses string length comparison instead of numeric thresholds for unit promotion (line ~779)
- [ ] Determine if percent formatting function is needed
- [ ] Ensure conversion functions handle edge cases (negative values, zero, very large values)
- [ ] Verify that all conversion functions can be called uniformly (consistent interface for any unit type)

### Non-Functional Requirements

1. **Backward Compatibility**: Existing command-line behavior must be preserved
2. **Performance**: Format matching should be faster than current approach for large files
3. **Extensibility**: Adding new built-in formats should be straightforward
4. **Testability**: Format definitions should be testable in isolation
5. **Error Handling**: Clear error messages for malformed user-defined formats

## Current State

- Manual duration unit override (`-du`) is implemented and available (Issue #17)
- Autodetection is deferred pending this refactor
- All format patterns are hardcoded in the main parsing loop

## Dependencies

- Blocks: Duration unit autodetection completion (Issue #17)

## Open Questions

### Format Registry
1. ~~What file format should user-defined formats use?~~ **RESOLVED 2026-05-09 (D12): YAML.** Ecosystem standard for monitoring tools (Prometheus, Datadog). Adds YAML::PP or YAML::Tiny dependency. Best fit for nested structures (derived metrics, dependency graphs).
2. ~~How should format priority/ordering work when multiple patterns could match?~~ **RESOLVED 2026-08-20 (D26): pinned-closure MTF — specific-before-general constraints derived at load from sample cross-testing; the winner promotes with its ancestor closure.** See `features/58-format-registry-staged-detection.md` § P3.
3. ~~Should format definitions support inheritance (e.g., "like tomcat9 but with microseconds")?~~ **RESOLVED 2026-08-20 (D35): no inheritance mechanism — sparse-override.** A user entry naming a built-in starts from its spec and overrides only stated fields (same-pattern variants cannot coexist under the D26 scan, so the µs case is inherently an override); a different pattern is a new format. See `features/58-format-registry-staged-detection.md` § D35.
4. ~~How to handle logs that switch formats mid-file?~~ **RESOLVED 2026-05-09 (D13): Detect once, fall back to per-line on low-confidence. Skipped/non-matching lines must be re-testable.** This requires the buffered-read architecture filed as #181 — the file reader pushes lines into a bounded buffer; the processor pulls and may push lines back for re-testing against alternate patterns.
5. ~~Should there be a "strict mode" that fails on unrecognized formats vs. current permissive behavior?~~ **RESOLVED 2026-08-20 (D36): no strict mode in Drop 1** — permissive behavior stays byte-identical; unmatched-line visibility comes from the `-V format-detection` scan telemetry. Available as a small follow-on if ever wanted.

### Processing Model
6. ~~How many trailing buckets should the sliding window retain?~~ **RESOLVED 2026-05-09 (D14): Auto-adjust at runtime; power-user CLI override.** "Sliding window" tracks transaction-spanning events (e.g., start in bucket 1, end 20 minutes later in bucket 5), not clock skew. Window auto-sizes based on observed transaction span; CLI flag exposes manual override for power users.
7. How does the deferred-per-bucket model interact with the existing `-st`/`-et` time range filters? *— Phase 2 (#59) design decision.*

### Derived Metrics
8. What is the configuration syntax for derived metric expressions? *— Owned by #55 (expression parser research).*
9. Should there be a maximum staleness/time-gap for inter-line functions beyond which a delta is discarded rather than interpolated? *— Phase 4 (#61) design decision.*
10. How should temporal interpolation handle non-uniform bucket boundaries or partial buckets at the start/end of a file? *— Phase 4 (#61) design decision.*
11. What is the full set of inter-line functions to support? (Minimum: `delta`, `idelta`. Candidates: `rate`, `irate`, `increase`, others from Prometheus.) *— Phase 4 (#61) design decision.*

### Metric Visibility
12. How are visibility flags configured — per metric in the format definition, or as a separate overlay/profile? *— Phase 3 (#60) design decision.*
13. Should there be default visibility presets (e.g., "full", "minimal", "csv-only")? *— Phase 3 (#60) design decision.*

## Research Areas

### ~~1. Fuzzy Matching Algorithms~~ — RESOLVED (#54/#96)
Message identity grouping (section 9) is a core dependency for inter-line derived metrics. Research completed and engine implemented:
- **Algorithm**: Trigram indexing with Dice coefficient for candidate identification, character-level banded edit distance for alignment. Token-based splitting was prototyped and failed (variable parts don't respect token boundaries).
- **Monitoring platforms**: Exact-match metadata grouping key + fuzzy message body scoring — same approach as Datadog's log pattern detection.
- **Same algorithm for both**: Yes. The grouping key controls granularity — tight identity uses more metadata fields + higher threshold; loose grouping uses fewer fields + standard 80% threshold.
- **Performance at scale**: S1 inline matching absorbs 98-99.9% of keys during parsing. 7.9 GB / 40.6M lines: 489s, 88% less memory than baseline.
- See: `docs/similarity-engine-best-practices.md`, `docs/staged-processing-pipeline.md`, `features/fuzzy-message-consolidation.md`

### 2. Expression Engine Design
The derived metric expression syntax needs to support arithmetic, function calls, and field references. Research needed:
- Existing Perl expression parsers / math evaluators (avoid building from scratch)
- How to represent the dependency graph and resolve calculation order (topological sort)
- Whether to use a simple infix notation (`a - b`), a functional notation (`subtract(a, b)`), or something closer to spreadsheet formulas
- How Prometheus PromQL and Dynatrace metric expressions handle similar composition — what can we learn from their syntax and semantics

### 3. Temporal Interpolation Correctness
Spreading deltas across buckets sounds simple but has edge cases:
- What happens at file boundaries (first bucket, last bucket)?
- What about gaps in the log data (no lines for 30 minutes, then a counter reading)?
- How do other tools handle this? (RRDtool, Prometheus staleness, Graphite's `transformNull`)
- Interaction with `-st`/`-et` time filters — if we're only processing a time window, do we still need prior state for delta calculations?

### 4. Sliding Window Bucket Lifecycle
The deferred-per-bucket model requires clear rules for when a bucket is "closed":
- How far ahead must reading advance before a bucket can be finalized? (Clock skew in logs, out-of-order timestamps)
- How does this interact with multiple input files that may cover overlapping time ranges?
- What happens when reading reaches EOF — how are trailing buckets finalized?

## Risks

### 1. Regression Risk — HIGH
This redesign replaces the entire core processing pipeline. Every existing feature (bar graphs, statistics, heatmaps, CSV output, filtering, memory tracking) must produce identical output after the refactor. The risk of subtle behavioral differences is very high.
- **Mitigation**: Build a comprehensive regression test suite from existing test logs *before* starting implementation. Capture current output as golden files. Run before/after comparisons on every change.
- **Mitigation**: Consider a phased approach where the old and new pipelines can run in parallel during development.

### 2. Memory Model Uncertainty — MEDIUM (reframed 2026-07-15, D15)
~~The sliding window is expected to reduce peak memory, but this is unproven.~~ Peak-memory reduction is no longer the target (D15). The residual risk is that the per-bucket transient holding is **unbounded or invisible**: buckets with many unique message identities and many extracted fields could hold large raw volumes while open, and if that consumer is not bounded and not reported, it masks regressions and defeats accountability.
- **Mitigation**: The window is structurally bounded (bucket count) and reported in `-V`/`-mem` alongside existing consumers. #57's prototype quantifies per-bucket transient cost using the per-entry cost constants already measured in the #323/#306 investigations (partition floor ~2,524 B, raw +32 B/value, singleton stats-hash ~2,327 B, per-sample hash-field update ~1.0–1.2 µs) rather than re-deriving them.

### 3. Temporal Interpolation Correctness — RETIRED (2026-07-15, D22)
~~Linear interpolation of counter deltas across buckets is an approximation…~~ Resolved by removal: account-at-read-time is locked as the universal semantic and interpolation is not planned (#370 records the spec and rationale). The risk this entry anticipated — smoothing hiding real patterns — was one of the grounds for rejecting interpolation outright.

### 4. Fuzzy Matching is a Hard Problem — ~~HIGH~~ MITIGATED
Getting message identity right is critical for inter-line metrics to produce meaningful results. Too loose: different counters get mixed. Too tight: the same logical counter doesn't match itself across lines due to minor variations.
- **Mitigation**: This is a research-first item. Prototype and test against real log data before integrating. Make the matching configurable so users can tune it. Accept that some cases will require user filtering.
- **Status**: Research and implementation completed in #96 (shipped v0.13.0). Trigram Dice coefficient with character-level alignment, checkpoint-based architecture, exact-match metadata grouping key + fuzzy message body scoring. Validated at production scale (7.9 GB, 40.6M lines). The engine is configurable via threshold (default 80%) and grouping key granularity. See `docs/similarity-engine-best-practices.md` and `docs/fuzzy-consolidation-lessons-learned.md`.

### 5. Scope Creep — HIGH
This issue now encompasses: format registry, staged detection, user extensibility, processing model redesign, derived metrics (two types), expression engine, fuzzy matching, metric visibility, memory model changes, and memory tracking enhancements. The risk of this becoming an unbounded rewrite is real.
- **Mitigation**: Strict phasing. Define clear phase boundaries with independent deliverables. Each phase must be usable on its own. Resist adding new requirements mid-phase.

### 6. Performance Regression — MEDIUM
The new model stores raw data per bucket before processing, which adds overhead compared to the current fire-and-forget streaming model. For simple use cases (no derived metrics), the new pipeline may be slower.
- **Mitigation**: Benchmark the new pipeline against the current one for simple cases (no derived metrics configured). If overhead is significant, consider a fast path that skips bucket accumulation when no features require it.

### 7. Expression Engine Security — LOW but non-trivial
If derived metric expressions are user-defined (via configuration files), and we evaluate them in Perl, there's a risk of code injection through crafted expressions.
- **Mitigation**: The expression engine must parse and evaluate a restricted grammar, never `eval()` raw user input. Use a proper parser.

### 8. Index Drift Correctness — MEDIUM (added 2026-05-09)
Once #179 (index read-back) ships, ltl pre-seeds heatmap/histogram boundary structures from `ltl-index.csv` when fresh. If live values exceed the index bounds and the index isn't refreshed at end-of-run, the *next* run will silently compute boundaries against incorrect ranges and produce visualizations that omit out-of-range values.
- **Mitigation**: #179's hard requirement is end-of-run drift detection and refresh — compare live captured min/max/timestamps to the pre-seeded values, and atomically update the index entry on any drift. Documented and tested before this issue's Phase 1 begins.

### 9. Buffered-Read Memory Accounting — MEDIUM (added 2026-05-09)
The buffered read pipeline (#181) introduces a new memory consumer between file I/O and the processor. If unbounded or invisible to memory tracking, it could mask regressions.
- **Mitigation**: #181 requires the buffer to be bounded with documented spillover behavior, sized via auto-adjust + power-user CLI override, and reported in `-V` output alongside existing memory consumers.

### 10. #22 Delta Semantics Change — LOW (added 2026-05-09)
Phase 4 silently replaces #22's global last-value-only `delta()`/`idelta()` (`ltl:3933-3946`) with per-message-identity delta. Same syntax, different (correct) results. Some users may have built monitoring scripts around the current incorrect-on-interleaved-messages behavior.
- **Mitigation**: Release notes for the version that ships Phase 4 must call this out as a behavior fix. Old behavior was undocumented for interleaved-message cases (only "no per-message-identity tracking" was noted as a limitation), so the surface area of impacted users should be small.

## Architectural Challenges (Consult Experienced Architects)

### 1. Bucket Finalization Ordering
When statistics, heatmaps, and derived metrics all need to run on a closing bucket, what is the correct order? Derived metrics may produce values that feed into statistics. Statistics may need to be computed before the bucket's memory is freed. This ordering needs to be defined carefully and may itself need a dependency graph.

### 2. Multi-file Time Interleaving
ltl processes multiple files. If two files cover the same time range, their lines interleave into the same buckets. With the current streaming model this "just works" because counters are incremented. With the deferred model, we need to handle multiple files contributing to the same bucket, potentially with different formats and different derived metric configurations.

### 3. Backward-Compatible Output
The current output (bar graphs, summary tables, CSV) is well-established. The new pipeline must produce byte-identical output for all existing functionality when no new features (derived metrics, visibility flags) are configured. Defining "byte-identical" and verifying it across all output modes is an architectural challenge in itself.

### 4. Configuration Model Complexity
Format definitions, derived metrics, visibility flags, fuzzy matching configuration, and reusable metric definitions all need to coexist in a coherent configuration model. This model must be approachable for simple cases (user just wants to add one custom log format) while supporting the full complexity (derived metrics with inter-line functions, dependency ordering, visibility flags). Getting this layering right is a design challenge that warrants external review.

### 5. State Management Across Bucket Boundaries
Inter-line functions need state that persists across bucket boundaries (the last known counter value for each message identity). But the sliding window frees bucket data. This means inter-line state lives *outside* the bucket lifecycle — it's a separate, long-lived data structure. The interaction between bucket lifecycle, inter-line state lifecycle, and memory tracking needs careful design.

### 6. One Line Pattern, Many Emitting Applications — Divergent Data Consistency and Quality (added 2026-08-21)

The registry's model assumes a declared line pattern identifies a *format*. In practice a pattern identifies a *line shape*, and a line shape can be emitted by several unrelated applications — most commonly because they share a logging framework and a default encoder configuration. Those applications are independent codebases with independent defects, so the **consistency and quality of the data inside an identical line shape can differ between them**. The registry currently has no way to express that, no way to detect it, and no way to adapt to it.

This is not hypothetical. ThingWorx Integration Runtime and ThingWorx Connection Server both emit:

```
2024-25-04 09:00:10.004 [vert.x-eventloop-thread-0] INFO  c.t.i.Entrypoint - Shutting Down
```

Byte-identical shape — both Vert.x, same logback encoder, same thread naming, same `LEVEL logger - message` tail — so one pattern matches both. But Integration Runtime's encoder is `yyyy-dd-MM` where Connection Server's is `yyyy-MM-dd`. The same captured field means two different things depending on which application wrote the line. Flipping the pattern to suit one breaks the other.

Three properties make this a general problem rather than a one-off fix:

1. **The discriminator is not in the line.** Only about a quarter of the Integration Runtime file's lines carry an application-specific logger prefix; the rest come from Apache Camel and a shared client library that the other product also uses. No per-line signal separates the producers, so recognition alone cannot resolve it — provenance evidence must come from outside the line (#384's filename patterns being the first such channel).
2. **The defect is invisible to the pattern that matched.** Recognition succeeds; extraction succeeds; the value is simply interpreted wrongly. There is no failed match to observe, and in the majority of cases no runtime error either — the failure is silent and plausible.
3. **Detection has a hard ceiling.** Aggregate probes (out-of-range field values, monotonicity of timestamps against file order) catch the loud cases, but a date on or before the 12th of the month is valid under both orderings, so a file whose whole span sits in days 1–12 offers no contradiction at all. Absence of contradiction is not evidence of correctness, and the design must treat it that way.

What the registry needs from this, to be settled as the mechanism is designed:

- **Expression** — a way to declare that two producer variants share a line pattern but differ in how a field is interpreted, without a second scan entry costing every line a failed match (#384 scope item 2).
- **Detection** — corroboration probes over a sample of the file that can *confirm* or *contradict* declared provenance, with an explicit contract that silence is inconclusive.
- **Adaptation** — a defined behavior when provenance is unknown, weak, or contradicted by content: which reading is taken, what is reported, and whether `ltl` may refuse to guess rather than produce a plausible wrong answer.
- **Confidence proportional to consequence** — evidence strong enough to select a duration unit is not necessarily strong enough to select a date field order; the latter silently relocates events by up to eleven months.

Drivers: #385 (the Integration Runtime case, `on hold` pending the mechanism), #384 (filename provenance evidence, which owns the first channel), #17 (the Tomcat/httpd `%D` unit case, the same problem in its milder metadata-only form).

**Resolution (2026-08-22):** the four needs above are answered by Drop 1.5 — *expression* by variant groups (D47), *detection* by the staged evidence model and content probes (D44, D52), *adaptation* by the visible-or-good-enough principle with the format pin as the correction path (D44, D49), *confidence proportional to consequence* by the detection window replaying held lines under the final decision so a date-layout flip costs nothing inside the window (D48). See § "Drop 1.5 — #384" below.

## Drop 1.5 — #384: filename provenance evidence and variant groups

### Status

- **Issue:** #384 — Drop 1.5 of the 0.17.0 merge train (parent #23; after #58, before #60). **No feature file of its own** — this section is the repo-side record; the issue body is its snapshot.
- **Planned:** 2026-08-22 interview session (architect + Claude). Decisions D44–D52 and implementation decisions I1–I8 locked as written.
- **Blocks:** #60 (Drop 2) — native `blocked_by` #384 recorded 2026-08-22 (architect: Drop 2 waits for Drop 1.5).
- **Prerequisites (native `blocked_by`):** #388 — detection evidence sampling pass (D53), which now carries the constraints in § "Constraints handed to #388".
- **Unblocks:** #385 (Integration Runtime `yyyy-dd-MM` dates — first variant group; its `timegm()` guard and once-per-file diagnostic ship here), the Tomcat/httpd `%D` unit split (#17's declarative half completes), and #387's user-defined variants (the group contract is designed to be extended from YAML).
- **Mandatory research → prototype phase before implementation:** the per-file scan-sub selection (D47) touches the generated scan sub and its signature cache; the content probes (D52) add a one-time cost over the sample (D53) and a sampled cost in the steady loop. Both are hot-path-adjacent — measure against the #58 S9 blessing battery before writing production code. *Completed 2026-08-23 (F1–F9 below).*
- **Implemented 2026-08-23** on branch `384-filename-provenance-evidence-variant-groups` in stages S0–S6 (record → registry schema → evidence and selection → steady-loop probes → pin → console/`-V`/note → fixtures and harness); findings in § "Implementation findings (2026-08-23)".

### The problem this drop solves

A registry pattern identifies a line *shape*; several producers can emit one shape with different semantics (Architectural Challenge 6). Two live cases:

| Shape | Producers | What differs | Consequence of the wrong choice |
|---|---|---|---|
| `mt10` (`connection_server_standard`) | ThingWorx Connection Server; ThingWorx Integration Runtime | date layout: `yyyy-MM-dd` vs `yyyy-dd-MM` (#385) | events relocated by up to eleven months; fatal on day > 12 |
| `mt3` (`tomcat_access_with_duration`) | Tomcat 6–9; Apache HTTP Server 2.x, Tomcat 10.1+ | `%D` unit: ms vs µs (#17) | durations wrong by 1000× |

No per-line discriminator exists for either pair. The discriminator that does exist is file-level provenance — first among its channels, the file's name — plus content corroboration that can confirm or contradict a choice but, by the ≤12-day ceiling, cannot always decide one.

### Naming evidence available (audit of producer conventions, 2026-08-22)

From the original-named specimens held locally under `logs/` (the directory is gitignored; many files there were renamed by the analyst — only the rows below are producer-true):

| Producer | Producer-true name | Stem | Date | Rotation | Ext |
|---|---|---|---|---|---|
| ThingWorx platform | `ApplicationLog.log`, `ApplicationLog.2025-05-05.0.log`, `ErrorLog.2025-05-05.1.log`, `ScriptErrorLog…`, `ScriptLog…`, `CommunicationLog…`, `AkkaCommunicationLog.log`, `AuthLog…`, `ConfigurationLog…`, `DatabaseLog…`, `SecurityLog…` | `<Name>Log` (OR set) | `.YYYY-MM-DD` | `.N` (logback) | `.log` |
| Tomcat access | `localhost_access_log.2025-03-21.txt` | `localhost_access_log` | `.YYYY-MM-DD` | — | **`.txt`** (Tomcat default suffix) |
| Apache httpd access | `access.log-20260609` | `access` | `-YYYYMMDD` *after* the extension | — | `.log` |
| HotSpot GC | `gc-….out.3` | `gc` | — | `.N` after the extension | `.out` |
| Connection Server | `cxserver.1-16.log` | `cxserver` | — | `.1-16` (replica/index form) | `.log` |
| Integration Runtime | `IntegrationRuntime-46b44bb3-….log` (logback `logs.uniqueId` is the uuid; `maxIndex 5` ⇒ rolled siblings exist) | `IntegrationRuntime-<uuid>` | — | unknown suffix form | `.log` |

Observations that shaped the decisions: Tomcat's `.txt` versus httpd's `.log` is a genuine discriminator in exactly the `%D` case, so the extension carries weight of its own; rotation suffixes land on either side of the extension depending on the producer, so the entry declares components and the resolver composes the matcher; neither `cxserver` nor `IntegrationRuntime` carries a date, so the filename-date probe serves date-rolled producers, not the motivating pair. `alwayson-cxserver` was recalled but could not be confirmed from any specimen and is **not** declared.

### Locked decisions (architect, 2026-08-22)

- **D44 — Detection is a staged accumulation of signals; confidence moves, is never 100%, and a wrong choice is visible-or-good-enough.** Signals arrive in the order they become available: the filename (before any line is read), each line's shape match, content probes over the lines read. Every signal raises or lowers the confidence of the candidates; the current best candidate is what the file is read with; the choice may flip as lines accumulate. ltl never claims certainty — the claim is *matched*. A variant chosen wrongly becomes clear to the analyst (dates that do not line up pages later, magnitudes that do not fit) or it was good enough; in both cases the console names the formats that were used so the analyst can pin and re-run (D49). This is the adaptation contract Challenge 6 asked for: no refusal path, a correction path.
- **D45 — Filename evidence is declared per entry as four optional components plus executable samples.** `stem` (a pattern over the name stem; OR-able so one entry covers a producer's family, e.g. the ThingWorx `<Name>Log` set), `date` (a layout from a small fixed vocabulary — the filename's own date is *declared*, never guessed), `index` (rotation index form), `ext` (expected extension). Any absent component is simply no signal. The resolver composes the full-name matcher from the components (rotation tolerance is composed, not hand-written per entry); compression suffixes (`.gz`, `.bz2`, …) are stripped by the resolver as a constant, never declared by a producer. The extension *contributes* certainty: a matching extension raises confidence, a missing or different one (renamed file) withholds that signal and leaves confidence lower — it never contradicts. Each entry declaring filename evidence carries filename samples that must match at load (D24 extended). Pattern sources are retained; no `qr//` stringification.
- **D46 — Evidence weights are fixed per evidence class in source code, never part of the registry schema.** An entry declares *what* its evidence is; how much each class counts (content shape match, stem, extension, filename date, rotation form, each probe) is one table in `ltl`, the same for every format including future user formats. Rationale: weights are a property of the detection engine, and letting definitions set their own would let one format out-shout another.
- **D47 — Variant groups: a variant is a full registry entry; one member per identical pattern enters the scan per file.** Same-shape producers are modelled as separate entries (own slug, time contract, unit, filename evidence, samples, expected records) tied by a `variant_group` key, with one member declared the group default — today's entry, so behaviour without evidence is unchanged. The generated scan sub contains exactly one member per *identical pattern* within a group, selected per file from the accumulated evidence, so no line ever pays a second attempt for a shape it already matched; the D40 order-signature cache gains the selected members as part of its key, so a flip is a cache lookup. Members whose patterns *differ* (extra columns, reordered columns — the shape #387's user variants will take) are distinguishable by content and enter the scan as ordinary entries; they belong to the group for lineage and evidence, and the same confidence applies. D24 gates run per member (the Integration Runtime member's samples carry `yyyy-dd-MM` expectations and are the executable proof the layout works); the cross-shadow gate treats *in-group* identical-pattern overlap as expected. The `unit_ambiguous` flag is retired: the ambiguity note fires when a group member was selected by default with no deciding evidence. The Tomcat/httpd `%D` pair becomes a group (`tomcat_access_with_duration` default; a new httpd member declares µs, stem `access`, ext `.log`); the Connection Server/Integration Runtime pair becomes a group (`connection_server_standard` default; a new Integration Runtime member declares `yyyy-dd-MM`, stem `IntegrationRuntime-<uuid>`). Shape B (one entry with a `variants:` override list) was rejected: variants need their own samples, slugs and generated blocks regardless, so B is A with the bookkeeping hidden. *Amended 2026-08-23 (F1): the group — not the member — is the unit of scan ordering; ordering constraints are declared and derived between groups, and the selected member fills its group's slot.*
- **D48 — The first decision is made before line 1 is processed (D53); a late flip past it is accepted and reported.** Evidence from the sampling pass (or, on non-seekable input, from the held-line window replayed under the decision) selects the variant before any line's extraction lands in the time axis, so a date-layout choice mis-tags nothing (three lines read `yyyy-dd-MM` before a correction would otherwise stretch the time axis by months through `initialize_empty_time_windows()`). Content probes run in full on the sample and sampled in the steady loop. #388 delivers the sampling pass and the contract in § "Constraints handed to #388" before this drop implements. *Amended 2026-08-22 with D53; the original wording made the D30 held-line window the replay mechanism for the first decision.*
- **D49 — A run-level format pin tops the precedence chain.** A CLI option (`-lf` / `--log-format <slug>`, name a proposal below) names the format to use for every file in the run, overriding any classification; an unknown slug is a usage error listing the known slugs. Precedence, top first: **pin → `-du` (unit only) → evidence-selected variant → group default → index read-back hints (#179) → sample-based auto-detection (#17, follow-on)**. The pin is the analyst's escape hatch when evidence is absent or wrong; no separate "disable filename evidence" switch exists — the pin covers it. Industry precedent F5 (explicit pinning outranks detection).
- **D50 — The console summary names the formats used; confidence stays in `-V`.** In the per-file list of the summary block, each file name is followed by `[n]` or `[n,m,…]` — every format found in that file, numbered against a single-line legend printed once below the list (`1 thingworx_standard  2 tomcat_access_with_duration`, numbered in order of first detection across the run). The file name is truncated through `shorten_filename()` with the bracket width reserved (width derived from the widest bracket in the run), so a long path never pushes the bracket off the line; a no-match file shows `[-]`. The legend and brackets speak the slug vocabulary — one identity surface shared with `-V format-detection` and the pin. Confidence, evidence and flips appear only in `-V format-detection`.
- **D51 — Detection scenarios run on committed fixtures staged under producer-true names.** `logs/` is gitignored, so assertions that depend on it run only where those files happen to exist. New fixtures live under `tests/fixtures/format-detection/` as `.txt`, each with a manifest row naming the producer-true name the harness stages it under in `$TMP_DIR` before invoking `ltl` (the committed name is never fed to the tool). Slices are cut from real specimens and scrubbed, source recorded in the manifest — the Integration Runtime specimen is the only known true positive for the date transposition, and a synthesized one would prove the synthesizer. Existing `logs/`-dependent scenarios remain; new scenarios are committed-fixture only.
- **D52 — Content corroboration probes: impossibility is hard evidence; silence is inconclusive.** Three probes feed confidence: (a) an out-of-range date component under the current layout (month token > 12) — decisive against that layout; (b) monotonicity of parsed timestamps against file order — violations lower confidence in the current layout; (c) the filename-date cross-check — the first (and last) parsed timestamp against the date declared in the filename, which **breaks the ≤12-day ceiling for date-rolled files**: `ApplicationLog.2025-05-06.0.log` with content `2025-05-06` is May 6 under `yyyy-MM-dd` and June 5 under `yyyy-dd-MM`, so any day ≠ month resolves the ordering at zero per-line cost. A probe that proves an impossibility outranks name evidence. Absence of contradiction proves nothing and is recorded as such. The `timegm()` guard and #385's once-per-file stderr diagnostic (file, line, offending value; never an ` at … line` suffix) are the out-of-range probe's user-visible half and ship with this drop.
- **D53 — Evidence is gathered by a multi-spot sampling pass; the held-line window is the fallback for non-seekable input.** Before the first line of a file is processed, the detect stage takes a separate, read-only look at the file: it divides the file's byte size into a few parts (front, middle, end), reads a few kilobytes at each, resynchronises to line boundaries, and the first decision (variant, unit) is made on that evidence. The sample operates in bytes — "the last line of the file" is not addressable, a byte offset is — and how many lines land in a spot is incidental. **The sample is completely decorrelated from the production read**: its own file handle, its own counters, no holding or replaying of lines, no effect on the scan order, on `scan_attempts:`, or on any existing telemetry; it exists only for detection signals and confidence building. **This is a dual process — a primary methodology and a fallback mechanism — and both ship.** Where the input cannot be repositioned (a pipe, a compressed stream — neither read today), the detect stage falls back to the #58 two-phase-store window (D30, `features/58-format-registry-staged-detection.md` D30/D38/P7): hold the first N lines, decide, replay. **The fallback ships with a number: N = 1,000** (architect's estimate, 2026-08-22; parity at that N already proven in #58 S4/S5) — it is never left at 0 on the assumption the primary path always runs. Probes consume a list of sample lines, never a file position, so the two sources are interchangeable to the decision logic. Because the sample knows the file's byte size and observes the average line length, it is also the natural basis for a **percentage-based progress indicator** (bytes consumed ÷ file size, or lines read × average line length) — an implementation note the code must carry at the sampling pass, not a deliverable of #388. Rationale: a front-only window of any size cannot see the far end of a file, and the date-layout case is usually decided by the span between the first and last timestamps (a file spanning days under one layout spans months, runs backwards, or hits an impossible month under the other), not by a single line; one specimen's decision line (571 of 5,416 in the Integration Runtime file) says nothing about the next file's. Confidence is progressive: the sample yields the best assumption available without hard indications, and the steady-loop probes correct it when hard evidence arrives. Locked 2026-08-22.

### Implementation decisions I1–I8 (proposed 2026-08-22; LOCKED by the architect the same day)

1. **Evidence classes and weights (one table in source, D46) — values locked 2026-08-23 from the prototype (F7).** Every signal is additive and independent of every other — no signal is gated on another, so a renamed stem still leaves the extension counting and vice versa. Content shape match is necessary and earns every group member 1.0; filename stem 3.0; extension 1.0; filename date agreeing with the content 0.5; rotation suffix present 0.25. The group default holds a standing credit of 1.0 — equal to the extension — so an extension alone produces a tie, and ties stay on the default: detection never moves off the default on an extension by itself (the explicit pin `-lf` and `-du` are the overrides for that case). Probe (a) (impossible date component) and a filename-date mismatch eliminate a member; probe (b) is a graded, comparative penalty (F4). Confidence = selected member's score ÷ the sum of the live members' scores, reported only in `-V`. Verified against the D51 cases: Tomcat content as `whatever.log` → Tomcat by default at 0.50; as `renamed.txt` → Tomcat by default at 0.75; httpd content as `access.log-20260609` → httpd at 0.71, as `access_log` → httpd at 0.67; IR/Connection Server content decided by probe (a) at 1.00 either way.
2. **Steady-loop probes live in the generated block's timestamp memo-miss branch** — amended 2026-08-23 from 1-in-N loop sampling on the prototype's measurements (F3/F4): (a) the out-of-range month test and (b) monotonicity over distinct timestamps both run only when a line's timestamp string differs from the previous line's (the last-seen memo misses; under #383's date-keyed cache there is no per-second cache behind the memo) — (b) only in variant-group members' blocks (IF2b, 2026-08-23) (once per change of timestamp between consecutive lines, never once per line on dense streams), measured at +0.003–0.016 s/M against +0.05–0.06 s/M for 1-in-256 sampling, and (b) observes every distinct timestamp instead of a 1-in-N subset. (b) is graded and comparative — violations per distinct timestamp under this layout vs the alternative — because completion-ordered and multi-threaded logs violate strict monotonicity benignly. The no-match-timing idiom is not used for probes. (c) is head/tail only.
3. **Option name:** `-lf <slug>` / `--log-format <slug>` (both forms free today); `--help` and `docs/usage.md` updated in the same commit.
4. **Filename `date` layout vocabulary:** `iso` (`YYYY-MM-DD`), `compact` (`YYYYMMDD`), extensible; `index` forms: `dot_n` (`.N`), `dash_n_n` (`.N-N`), `dot_n_dash_n` (either — added at implementation for the Connection Server's `.1` / `.1-16` pair); each entry also declares the suffix `placement` — `before` (`stem[.date][.index]ext`, logback/Tomcat) or `after` (`stem ext[-date][.index]`, httpd logrotate/HotSpot GC). **Locked 2026-08-23 (F8):** the index form is declared so the resolver knows what to consume to reach the date and the extension; it never discriminates between formats — seventeen producer-true names showed zero cross-entry collisions with or without forms — so `index` contributes its present/absent credit (0.25) only.
5. **`-V format-detection` per-file additions** (section-contract keys, owned here per HARNESS-DESIGN): `filename_evidence: stem=<entry|-> ext=<match|absent|other> date=<match|mismatch|-> index=<…>`; `candidates: slug=score,…`; `selected: slug`; `selection_basis: pin|evidence|default`; `confidence: 0.NN`; `flips: N`; `probes: out_of_range=N monotonic_violations=N filename_date=match|mismatch|-`; `formats: slug,slug` (the bracket's content). Run-level: `format_pin: -|slug`. Existing keys byte-preserved.
6. **Ambiguity note rewording** (replaces the S7 text, harness scenario updated in the same commit): fires for a default-selected group member; names the group's consequence class (unit or date layout) and points at `-lf` as well as `-du`.
7. **Fixture provenance for the Integration Runtime slice:** a scrubbed ~300-line slice of the real specimen is committed (uuid, hosts, session ids replaced; logger names kept — they are part of the shape); source recorded in the manifest. Confirmed by the architect 2026-08-22.
8. **`-V` legend numbering** also emitted as `legend: 1=slug,2=slug` so the harness can assert bracket↔legend consistency without parsing the rendered summary.

### 2026-08-23 kickoff interview — prototype retained; scope and testing discipline

- **Branch:** `384-filename-provenance-evidence-variant-groups`, cut 2026-08-23 from `release/0.17.0` (post-#388).
- **Priority/precedence of pattern matching is not a gap.** Raised by the architect as a possible missing concept (specific-before-generic ordering of the registry patterns). Resolved against the record: ordering is the D26 pinned-closure MTF with constraints derived at every startup by the D24 cross-shadow test of each entry's `samples` against every other pattern (`derive_format_constraints()`, gate 4 fails the build when the derived pinned-ancestor sets disagree with `expect_ancestors`); user formats that overlap a built-in fail loudly unless they declare a priority (#387). No new issue; nothing added to this drop.
- **Prototype retained.** A waiver (as granted for #388) was considered and withdrawn once it was made explicit that I1 (weight values) and I4 (rotation `index` form) are deferred *to* the prototype. The prototype has exactly four jobs, confirmed as the full list: (1) D47 per-file member selection cost — generated scan sub + D40 cache keyed by selected members, a flip must cost a cache lookup; (2) D52 probe costs — full over the D53 sample, 1-in-N in the steady loop, against the #58 S9 battery; (3) I1 weights set from the D51 fixture outcomes (IR and httpd resolve on stem alone; must not resolve on extension alone); (4) I4 — whether any producer pair needs a declared rotation form or present/absent suffices.
- **Testing discipline during development** (architect, 2026-08-23): measurements run against the application code, but iteration uses small, targeted, single-scenario tests; the broad batteries (#58 S9 blessing set, the full `tests/validate-*.sh` suite) are stage gates run before moving to the next stage, not development tools.

### #384 prototype findings (2026-08-23) — `prototype/384-variant-selection-mini.pl`

The prototype evals `ltl`'s own source up to `## MAIN ##` together with its driver, so it drives the production `build_format_registry()`, `compile_format_scan_sub()` and `sample_file_for_detection()` unchanged (no copy, per the #58 F9 lesson). Variant members are injected by wrapping `format_registry_specs()` (an httpd `%D`-µs member `mt3us` sharing `mt3`'s pattern; an Integration Runtime `yyyy-dd-MM` member `mt10ir` sharing `mt10`'s pattern, with real specimen lines whose day token is 28 as its executable samples); the `yyyy-dd-MM` time parse is produced by swapping the day/month `substr` reads in the generated block. Fixtures: the #58 families regenerated by `prototype/58-generate-fixtures.sh`; specimens under `logs/`. Medians of 3 with ranges, local disk under `caffeinate`.

**F1 — The group is the unit of ordering (locked by the architect 2026-08-23; amends D47).** Swapping `mt10` → `mt10ir` made D24 gate 4 fail at once: `mt2`'s declared `expect_ancestors => [mt1std, mt10, mt1gen]` no longer matched the derived `[mt1std, mt10ir, mt1gen]` — the declaration named a member that had been swapped out. Decision: a variant group occupies **one position** in the scan order, and ordering constraints are declared and derived **between groups**, never between members; an entry with no variants is a group of one. The member selected for a file is the concrete entry filling its group's slot, so it inherits the group's position (Connection Server *group* ahead of RAC ⇒ the Integration Runtime member is ahead of RAC when selected), and gate 4 compares group against group, so the slot's occupant can change without touching the constraints. The prototype approximates this by rewriting member names in the declarations to the selected member at spec time.

**F2 — D47 member selection is a cache lookup; steady-loop cost is zero.** Groups present (default members) vs today's registry, scan-only loop through the live generated sub:

| Fixture | base | groups-default | Δ |
|---|---|---|---|
| pure-access 1m | 3.287 s [3.286–3.290] | 3.297 s [3.296–3.303] | +0.3% |
| concat-pair 1m | 3.406 s [3.402–3.407] | 3.395 s [3.393–3.398] | −0.3% |
| twx-blend 1m | 2.456 s [2.452–2.458] | 2.452 s [2.451–2.457] | −0.2% |
| cxserver.1-16 (1.0m lines) | 2.004 s [2.003–2.005] | 2.003 s [1.994–2.004] | −0.0% |

Expected by construction — one member per identical pattern means the generated sub has the same block count — and confirmed. Flip costs, measured on the production mechanism: a **cold** flip (a (scan order, selected members) signature not yet compiled) is one `compile_format_scan_sub()` = **2.54 ms [2.53–2.57]**; a **warm** flip is one hash lookup = **52 ns**. A full `build_format_registry()` (the upper bound the design never pays per file) is 59 ms. The D40 cache key becomes order signature + selected-member signature; the eager startup precompile covers the default members only — a variant member's orders compile on first selection (≤2.5 ms per new order, once per run). The IR member reads the whole 5,416-line specimen under `yyyy-dd-MM` with no fatal (2,205 matched; the rest are stack-trace continuation lines).

**F3 — Probe (a) (out-of-range month) costs nothing when it lives in the generated block's cache-miss branch.** The block already branches on "timestamp string not seen before" (`%timestamp_cache` miss — once per distinct second, not once per line); a `substr(...) > 12` test there measured +0.007 s/M [pure-access 1m] and +0.003 s/M [twx-blend 1m] — inside run-to-run range. This is also where #385's `timegm()` guard belongs: the same test prevents the croak.

**F4 — Probe (b) (monotonicity) belongs in the same miss branch, not 1-in-N in the read loop.** I2 as locked proposed 1-in-N sampling on the no-match-timing idiom. Measured:

| Arm | pure-access 1m Δ | twx-blend 1m Δ | violations seen |
|---|---|---|---|
| every line, in the loop | +0.102 s/M | +0.085 s/M | 0 / 2 |
| 1-in-256, in the loop | +0.060 s/M | +0.050 s/M | 0 / 2 |
| (a)+(b) 1-in-256 | +0.046 s/M | +0.047 s/M | 0 / 2 |
| **(a)+(b) in the miss branch** | **+0.005 s/M** | **+0.016 s/M** | 6 / 14 |

Sampling barely halves the cost because the counter and mask test still run per line; the miss branch runs only when a new distinct timestamp appears and compares it with the previous distinct one — ten times cheaper and it observes every distinct timestamp instead of 1-in-256 (6 vs 0 violations on the access log; 14 vs 2 on twx-blend). Those violations are real and benign: access logs are written in completion order, platform logs across threads — so (b) is *graded and comparative* (violations per distinct timestamp, under this layout vs the alternative), never absolute. **I2 amended accordingly by the architect, 2026-08-23** (text above).

**F5 — Full probes over the D53 sample are sub-millisecond per file; the many-small-files case is ~0.2 s per 200 files.** Probes (a)/(b)/(c) under both layouts over the 3×8 KB sample: IR specimen 305 µs (164 lines), cxserver 427 µs (233 lines), httpd 11 µs (147 lines, no ISO timestamps so nothing to probe), ApplicationLog 233 µs (58 lines); with the sample read itself (194–784 µs, #388) that is 0.9–1.1 ms per file → 85–212 ms per 200 files. Retained per file: the conclusions hash, 1,112 bytes (`Devel::Size`); no lines.

**F6 — The sample decides the date layout on its own for both real specimens — in both directions.** IR specimen: 53 of 164 sampled lines have an impossible month under `yyyy-MM-dd`, 0 under `yyyy-dd-MM` (span 807.6 d under the right layout — the file covers 2023-11 → 2025-01). cxserver specimen: 39 impossible under `yyyy-dd-MM`, 0 under `yyyy-MM-dd` (spans 2.8 d vs 31.1 d). So for this group, any file whose sample contains a day > 12 is decided by probe (a) before line 1 regardless of its name: `app.log` with cxserver content selects the default by *evidence*, not by default. The D51 table row "same IR slice as `app.log` → no evidence → default; probe contradiction reported" is corrected: it selects `integration_runtime_standard` from the sample with basis `evidence` (the I1 run shows it). The name matters for the ≤12-day case, and there probe (c)'s filename date is the only other discriminator — neither motivating producer carries a date in its name, so a short-span, day≤12 Connection Server/IR file with no name evidence is the one case that stays on the default with the ambiguity note, as D44 accepts.

**F7 — I1 weights (locked 2026-08-23; all D51 cases resolve as required).** A first candidate gated the extension on a stem match; the architect rejected it — every signal must count independently (a renamed stem must not silence the extension). Final table: `shape 1.0`, `stem 3.0`, `ext 1.0` (always counted), `filename-date match 0.5`, `index present 0.25`, `group default 1.0` standing credit so an extension alone ties and ties stay on the default; probe (a) or a filename-date mismatch eliminates the member; probe (b) −0.5 per violation capped at −1.0, comparative per F4. Confidence = selected score ÷ sum of live members' scores. Outcomes (name → member, basis, confidence): `cxserver.1.log` → cs 1.00 evidence (probe a); IR-named → IR 1.00 evidence; `app.log`+IR content → IR 1.00 evidence (probe a); `app.log`+cxserver content → cs 1.00 evidence (probe a); `localhost_access_log.2025-05-05.txt` → tomcat 0.86 evidence; `access.log-20260609` → httpd 0.71 evidence; `access_log` → httpd 0.67 evidence (stem alone); `renamed.txt` → tomcat 0.75 default; `whatever.log` + Tomcat content → tomcat 0.50 default (tie on extension alone — the extension shows in the confidence, never in the selection).

**F8 — I4: the rotation index needs no declared form for discrimination; the form is needed only to compose the matcher.** Seventeen producer-true names (incl. `.gz`) decomposed through the D45 component matcher with `placement` (`before`: `stem[.date][.index]ext`, logback/Tomcat; `after`: `stem ext[-date][.index]`, httpd logrotate/GC): zero cross-entry collisions with declared forms **and** zero with index as present/absent-only. Answer: `index` is declared as a form (`dot_n`, `dash_n_n`) because the resolver must know what to consume to reach the extension, but it carries present/absent weight only (0.25) — no producer pair is separated by its index form. Decomposition results: `ApplicationLog.2025-05-05.0.log.gz` → stem ThingWorx, date 2025-05-05, index 0, ext match; `cxserver.1-16.log` → index 1-16; `access.log-20260609` → httpd, date 20260609, ext match; `access_log` → httpd stem, ext absent.

**F9 — Fixture provenance correction for D51.** The µs-`%D` httpd content in `logs/` is `AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` (analyst-renamed; `%D` as a trailing integer, e.g. `... 200 209 173542`). `AccessLogs/access.log-20260609` is a *different* shape (nginx-style `rt="59.865"` fields) and is not the `%D` specimen. The D51 httpd slice is cut from the Windchill file and staged under the httpd name convention (`access.log-20260609` or `access_log`).

**Decisions from the prototype:** locked 2026-08-23 — I2 amended per F4 (both probes in the generated block's cache-miss branch; no 1-in-N sampling), I1 values per F7, I4 per F8. F1 locked 2026-08-23 (the group is the unit of ordering; amends D47). D51 table rows corrected per F6 and F9 (locked 2026-08-23). Every prototype-derived decision is now locked.

### Implementation notes N1–N10 (2026-08-23; mechanism-level, below the Dxx/Ixx decisions — strike or lock)

Mechanism choices the locked decisions leave to the implementer, recorded here before any production code. N5 and N9 were settled in dialog with the architect on 2026-08-23; the rest were approved with the implementation plan the same day and are implemented as written (N6 merged into N5). Two additions found during implementation: the `index` vocabulary gains `dot_n_dash_n` (`.N` or `.N-N`, the Connection Server's `cxserver.1.log` / `cxserver.1-16.log` pair); the fallback-window prefill classifies held lines under the previous occupant, so probe signals raised during prefill only count until the held lines are scored (the selection that follows sees the same evidence).

- **N1 — Group as a registry field.** Every entry carries `FR_GROUP` (an entry without variants is a group of one keyed by its own name). Spec keys: `variant_group => '<group>'`, `variant_default => 1` on the default member. Ancestor sets (`FR_ANC_SET`, `expect_ancestors`, `derive_format_constraints()`, gate 4) are keyed by **group** (F1); `derive_format_constraints()` treats a same-group first match as the owner (in-group identical-pattern overlap is expected, D47). `@format_registry` / `@format_scan_order` hold **one occupant per group slot** (the default member at build); all members live in `%format_registry_entry`. The D40 cache signature stays `join ',', FR_NAME` — the occupant's name changes on selection, so "selected members in the key" (D47) falls out of the existing signature with no second key. The eager precompile covers default occupants only (F2).
- **N2 — Per-file selection is an in-place slot swap.** `select_format_variants($path, \@sample_lines)` runs at the sampling attach point in `read_and_process_logs()`, returns per group `{selected, basis, confidence, candidates, probes, evidence}`; for each group whose selection differs from the current occupant, the occupant is replaced at its position in `@format_scan_order` (F1) and `$format_scan_sub` is taken from the cache or compiled once.
- **N3 — Timestamp cache invalidation.** `%timestamp_date_cache` (#383: one midnight epoch per distinct date, capped at `TIMESTAMP_DATE_CACHE_MAX` = 100 entries with oldest-insertion eviction; time of day added arithmetically) is keyed by the date string alone and the two date layouts disagree on the epoch for the same string, so any occupant change (per-file or mid-file) clears the cache and its insertion stamps (`timestamp_date_cache_clear()`) and resets the last-seen memo (`$format_last_ts_str` / `$format_last_ts_epoch`). Output-neutral for same-layout runs (the cache is a memo); cost is one `timegm()` per distinct day after a swap.
- **N4 — Fallback-window path.** When no sample was taken, the held lines are the evidence: `select_format_variants()` runs on them after prefill and before replay; each held `[line, entry]` whose group changed occupant is remapped to the new occupant (same pattern ⇒ the classification stands; the extraction closure differs).
- **N5 — One selection mechanism, continuously re-evaluated (architect, 2026-08-23).** Per group, every signal updates candidate scores; the best live candidate is the selected member; a change of best is a flip. The steady-loop probes are signal sources feeding that same mechanism — there is no separate flip rule or threshold. The generated block's timestamp memo-miss branch (ISO layouts only, I2) calls a cold sub on the rare events: an **impossible month** eliminates the current member (score 0); a **monotonicity violation** over distinct timestamps applies the I1 penalty (−0.5 per violation, capped at −1.0) to the current member. The group then re-selects; if the best changed → swap occupant (N2), invalidate the cache (N3), `flips++`, and the block returns `$format_scan_sub->($_[0])` so the triggering line is re-scanned under the new member (no recursion: a group with no better live member does not flip). An impossible month with no alternative left → the once-per-file #385 stderr diagnostic (file, line number, offending value; never an ` at … line` suffix) and the epoch falls back to the previous distinct epoch (`// 0`) — this is the `timegm()` guard. Per-file counts and the live confidence are reported in `-V`.
- **N6 — (merged into N5).**
- **N7 — `formats:` per file at zero per-line cost.** Every entry's `FR_MATCHES` is snapshotted at file start; the file's format set is the entries whose count grew (plus `csv` when confirmed). Legend numbering = first-detection order across the run (D50).
- **N8 — `entries:` keeps meaning occupants in the scan sub** (13 today). New keys in the contract: run-level `format_pin:`, `legend:`; sub-section `variant_groups:`.
- **N9 — Pin semantics (`-lf <format-name>`, architect 2026-08-23).** The pin overrides automatic detection for every file in the run (the industry-standard override, #388 R1). The operand is a user-facing format name and resolves to **every registry entry carrying that name** — `thingworx_standard` names both its strict and generic entries, and choosing it is still choosing something more specific than detection; a group has no user-facing name and is never pinnable. The scan for the run is restricted to the resolved entries (one compiled sub, no evidence pass, no selection, no probes, no MTF alternation); lines not matching are unmatched as usual; `-du` still governs the unit. An unknown name is a usage error listing the known names. `-V`: `format_pin: <name>`; per-file `selection_basis: pin`, `confidence: 1.00`.
- **N10 — New time layout `iso_ms_ddmm`** (same `frac fixed3`), emitted by `format_entry_block_src()` and `compile_format_time_parser()` from the layout declaration (day/month `substr` offsets 5/8 swapped) — never by patching generated source as the prototype did.

### Implementation findings (2026-08-23)

- **IF1 — Gate 4 fires on member names the moment a variant exists (F1 confirmed in production).** The first build with `mt10ir` in place died on `mt2`'s `expect_ancestors => [mt1std, mt10, mt1gen]` vs the derived `[mt1std, connection_server, mt1gen]`; the declarations on `mt2` and `mt8` now name the group. Ancestor sets, promotion closures and the eager precompile compare `FR_GROUP`, never `FR_NAME`; the D40 signature still joins `FR_NAME`, so the selected member is part of the cache key for free (N1).
- **IF2 — Steady-loop cost (S3 gate).** `TIMING parse/read_files`, median-of-3 [range], local disk under `caffeinate`, `release/0.17.0` HEAD vs the S3 tree: pure-access-1m 12.138 s [12.071–12.185] → 12.050 s [11.985–12.106]; twx-blend-1m 6.984 s [6.812–7.023] → 6.878 s [6.836–6.953]; pure-scriptlog-1m 10.156 s [9.959–10.198] → 10.001 s [9.802–10.208]. Both probes in the ISO cache-miss branch cost nothing measurable (F3/F4 confirmed).
- **IF2b — Blessing battery (S7 gate) and the one out-of-range family.** Total time, median-of-3 [range], `release/0.17.0` HEAD vs this tree: pure-access-1m 12.455 [12.331–12.545] → 12.357 [12.328–12.409]; concat-pair-1m 10.687 [10.571–10.711] → 10.539 [10.464–10.630]; interleave-100-1m 10.934 [10.788–11.072] → 10.885 [10.885–10.990]; pure-scriptlog-1m 10.417 [10.371–10.578] → 10.460 [10.396–10.491]; twx-blend-1m 6.975 [6.959–7.116] → 7.031 [7.003–7.061]; **pure-gc-1m 13.822 [13.743–13.872] → 13.991 [13.970–13.991] (+1.2%, ranges disjoint)**. Attribution: GC logs are the sparse-timestamp class (P8) — nearly every line misses the timestamp cache, so the miss branch, and both probes with it, runs about once per line there. Resolution (amends I2/N5): the monotonicity probe is emitted only into variant-group members' blocks — it exists to move a selection, and a group of one has nothing to select; every entry keeps the impossible-date guard (#385). Re-measured with alternating arms: pure-gc-1m base 13.681 [13.563–13.704] / 13.583 [13.485–13.670] vs new 13.650 [13.527–13.682] / 13.620 [13.586–13.762] — inside range. Net: no family regresses.
- **IF3 — Interleaved-run parity.** Per-file daily buckets are identical between single-file runs and IR → cxserver → IR sequences (occupant swap-back and timestamp-memo invalidation, N2/N3).
- **IF4 — The fallback window on Integration Runtime content** (sample disabled in a sabotage copy; pipes are not readable input today, so the primary path always runs on real input): prefill hits month 24 under the default occupant, the signal counts, the held-line selection picks the IR member, held classifications are remapped, 2,205 lines read with no fatal — the D53 dual process holds.
- **IF5 — Late flip.** A synthetic file whose three sampled spots hold only day ≤ 12 lines with a day > 12 block between them selects the default from the sample and flips to `integration_runtime_standard` at the first impossible month (`flips: 1`, `out_of_range: 1`); the triggering line is re-scanned under the new member (N5).
- **IF6 — All nine F7 outcomes reproduce** on staged specimens through `-V format-detection` (IR 1.00 evidence by stem and, as `app.log`, by probe; `app.log` with cxserver content 1.00 by probe; httpd 0.71 / 0.67; Tomcat 0.86; `renamed.txt` 0.75 default; `whatever.log` 0.50 tie-on-default).
- **IF7 — Sabotage proofs.** Build gates: in-group filename overlap, a filename sample failing its matcher, a variant member declared before its default — each fails the build with its diagnostic. Harness: a copy with the stem weight zeroed and probe (a) disabled is caught by the selection/basis/confidence/candidates/absence assertions of five scenarios; a copy with the bracket, legend, `formats:` and `format_pin:` suppressed is caught by their four assertions.
- **IF8 — Pre-existing, not this drop's:** `ltl /dev/stdin < file` reports 0 matched lines since #388 (the sample's own handle on a redirected regular file shares the offset with the main read). Pipes are refused before reading. Neither is a path this drop changes; noted for the umbrella's non-seekable-input work.

### Constraints handed to #388 (must be settled and landed before this drop implements)

Rewritten 2026-08-22 under D53 (the original six constraints were framed around sizing a front-only held-line window).

1. **Sample shape, in bytes.** The file's byte size is divided into a few parts — front, middle, end — and a few kilobytes are read at each, resynchronised to line boundaries; the number of parts and the bytes per part are what #388 sizes. How many lines land in a part is incidental. (The architect's "anything under a thousand lines is not worth considering" applied to reading from the top only — a hundred lines from the head is not representative; a few kilobytes at each of several points across the file is a different regime and is not bound by that floor — clarified 2026-08-22.) Measured across the fixture families and the D51 fixtures by what each candidate shape *sees* — recognised lines, formats present, date span under each layout, duration values — not by whether it reaches a particular line of a particular specimen.
2. **Probe cost on the sample.** Full probes (D52 a/b/c) run on every sampled line; #388 reports the one-time per-file cost of the sample (repositioning, resync, reading, recognition) and of the probes over it, with the many-small-files case — where the sample is paid once per file — measured explicitly.
3. **Decorrelation.** Output with the sampling pass on is byte-identical to output with it off — the pass reads through its own handle, keeps its own counters, holds and replays nothing, and leaves the scan order, `scan_attempts:`, and all existing telemetry untouched; files smaller than the sample are read whole as the sample. The fallback window's side-effect-ordering parity (proven at N=1000 during #58 S4/S5) is re-proven at whatever N the fallback ships with.
4. **Memory.** What the pass retains from the sample — the probes' conclusions, not the lines — stated as a number; the fallback window's per-held-line bound (P7: ~310–575 B) restated at its N, single window at a time (files are sequential).
5. **#17's unit sampling** rides the same sample; the bytes per part must give it enough duration values to work from (the prototype reports how many it sees).
6. **Deliverable shape — dual process:** the sampling pass is the primary path for seekable input; the #58 fallback window ships with **default N = 1,000** (D53), engaged only when the primary path cannot run, and keeps its hidden `--detection-window` override; `window_size:` telemetry stays and gains sibling keys describing the sample (parts, bytes per part, lines seen), named in #388's `-V format-detection` contract addition. Telemetry for "decision stabilised at line L" is this drop's, not #388's.

### #388 — detection evidence sampling pass: research findings (2026-08-22)

Findings R1–R3 ground the design in R4. **Prototype waived by the architect (2026-08-22):** the sampling pass is a per-file, few-kilobyte read off the hot path, so the measurements in R5 are produced by the implementation's own `-V format-detection` telemetry on the real specimens rather than by a separate prototype; the next step is scope validation, then implementation.

#### R1 — Prior art: sniffers read a bounded head; unbiased estimators sample across the file

Verified from primary sources (docs or source) by a research pass on 2026-08-22:

| Tool | Placement | Sample size (default; configurable) | Partial-line handling | Rationale stated |
|---|---|---|---|---|
| lnav | head only | 15,000 lines; `/tuning/logfile/max-unrecognized-lines` | none (streams from byte 0) | bounds detection cost |
| ClickHouse schema inference | head only | 25,000 rows or 32 MiB; both settings | none | more rows → slower but more likely correct |
| Elastic find-structure | head only | 1,000 lines; `lines_to_sample` | none | documents the failure mode: a homogeneous first 1,000 lines overfits |
| Splunk sourcetype | head only | "first few thousand lines"; no knob found | none | — |
| Python `csv.Sniffer` / pandas | head only | caller-supplied (1 KiB example / first valid row) | none | — |
| file(1)/libmagic | head only | 1 MiB max; 64 KiB for charset | none | — |
| DuckDB `read_csv` sniffer | **multi-position on seekable files, head-only on `.gz`/stdin** (docs-verified; the `main` sniffer source read looked sequential) | 20,480 rows; `sample_size`, `-1` = whole file | seek to an offset, resync forward to the next valid row start (quote-aware) | sniffing ≈ 4% of load time on 1.7 GB; keep the sample "reasonable" |
| Apache Spark JSON/CSV | random across the dataset | `samplingRatio` 1.0 (all) | n/a (record-level) | — |
| PostgreSQL ANALYZE | **random blocks across the table, then reservoir rows** | 300 × statistics target (30,000 rows) | n/a (block-aligned) | explicit: head-of-table sampling "put too much credence in the row density near the start" |

Synthesis: format *recognition* is a head-prefix problem everywhere (thousands of lines, configurable); tools that need an *unbiased estimate of content* sample across the file, and the two that document why (PostgreSQL, Elastic) name exactly the failure D53 targets — the start of a file is not representative of it. DuckDB is the direct precedent for D53's shape: multi-position on seekable input, head-only fallback on streams, resync to the next record boundary after a seek. Sample sizes in the 1,000–25,000-line range are the norm; none of the head-only tools documents a basis for its number beyond cost.

#### R2 — Code audit: what the read path gives the pass, and what the pass would disturb

- **A1 — Seeking is exact.** `read_and_process_logs()` opens each file with a bare `'<'` (no encoding layer), so `seek`/`tell` are byte-accurate and `-s` gives the size. CSV's lazy detection (#107) reads lines 1–2 of the main read; the pass precedes the main loop and returns the handle to byte 0, so CSV is untouched.
- **A2 — The production scan sub is not usable for the sample.** The generated scan sub (`compile_format_scan_sub()`) inlines guard, match, and field extraction, writes the file-scoped record lexicals, and a non-front winner calls `format_registry_promote()` (reorders `@format_scan_order`, increments `promotions:`) — every call has production side effects, and `tests/validate-format-detection.sh` pins exact `scan_attempts:` values. The decorrelated sample therefore recognises lines by matching the registry entries' compiled patterns directly (same patterns, one resolution surface; no extraction, no promotion, no shared counters) — cheap at a few dozen lines per part.
- **A3 — Line geometry of real specimens.** Average line length 105 B (cxserver) – 405 B (ScriptLog); max 37 KB (an ApplicationLog stack trace). A 1,000-line spot is ~100–400 KB; resyncing after a seek discards at most one long line. The end spot is found by seeking to `size − (lines × avg × margin)` with the average taken from the head spot, reading to EOF, keeping the last `lines`; a short estimate seeks back further.
- **A4 — The sample's cost is per file, not per line.** A few kilobytes per part is a fixed cost paid once per file regardless of size, so the many-small-files case (hundreds of rotated files) is where it shows; a file smaller than the whole sample is read once, whole. Constraint 2 prices this case explicitly.
- **A5 — Prior-run overlap.** The #179 index already records per-file first/last timestamp and `ts_precision`; the head/end spots reproduce these facts fresh, and D49 already ranks evidence above index hints — no precedence change, just agreement.
- **A6 — The fallback window is untouched.** The D30 prefill (`@window_held`) is the non-seekable fallback only; the sample does not hold or replay lines and shares no code path with it. Its parity at N=1000 is proven (#58 S4/S5) and is re-proven at whatever N it ships with.

#### R3 — Specimens and fixtures available to the prototype

The #58 fixture families (`prototype/58-generate-fixtures.sh`: pure-access, pure-scriptlog, pure-scriptlog-dense, pure-gc, twx-blend, concat-pair, interleave-100 at 1k/10k/100k/1m) regenerate deterministically into `/tmp/ltl-58-fixtures/`. Real specimens in `logs/`: Integration Runtime (5,416 lines, decision line 571), Connection Server (`cxserver.1-*.log`, ~1M lines each), Tomcat access (1.43M lines), httpd `access.log-20260609` (220k lines, µs `%D`), `ApplicationLog.2025-05-06.0.log` (23.6k lines, date-rolled name). The D51 fixtures are #384's and do not exist yet; the prototype measures on the above and #384 re-runs the battery on its fixtures at its own prototype phase.

#### R4 — Candidate designs for the prototype

One design (D53, architect 2026-08-22), parameterised — there are no competing mechanisms to prototype:

- Divide the file's byte size into **K parts** (front, middle, end; K ∈ {3, 4, 6}) and at each part read **B bytes** (B ∈ {2 KB, 8 KB, 32 KB, 128 KB}), resynchronising to the next line boundary after the seek (the front part starts at byte 0; the end part is positioned so that the read ends at EOF).
- Recognise each sampled line against the registry patterns directly (A2); feed the lines to the probes; retain conclusions, not lines.
- A file smaller than K × B is read once, whole, as the sample.
- Non-seekable input (future): the D30 fallback window at N = 1,000 — the second half of the dual process, shipped alongside the primary; the prototype re-proves its parity at that N.
- The prototype's sampler records file size and observed average line length per part; the production code carries a comment at the sampling pass that these are the inputs for a percentage-based progress indicator (D53).

The battery's two axes are K and B; the tables in R5 show, per specimen, what each (K, B) pair sees and costs, and the recommendation is the smallest pair past which the signals stop improving.

#### R5 — What the prototype measures (maps to the six constraints)

1. **Sample shape → what it sees** (constraint 1): per specimen and per (K, B) pair — lines landed per part, recognised-line share, formats seen, first/last timestamp per part under each date layout and the resulting file span, count of day-tokens > 12, number of duration values seen (for #17); exact counts, reported as a table.
2. **Cost** (constraint 2): seek + resync + read + recognise per part and per file, in µs per file, on files at 1k/10k/100k/1m lines and on a many-small-files set (e.g. 200 × 5k lines); probe cost stand-in = the date-layout span check and a duration tally per sampled line (the real D52 probes are #384's). Medians with ranges over ≥5 runs.
3. **Decorrelation** (constraint 3): byte-identical `ltl` output with the pass on/off across the fixture families, including files smaller than the sample; fallback parity re-proved at the shipped N.
4. **Memory** (constraint 4): retained evidence in bytes (Devel::Size) at the largest (K, B); held-window bytes per line restated.

#### #388 scope (validated by the architect 2026-08-22)

In scope:

1. The sampling pass in the detect stage, once per file before the main read: K parts by byte offset (front, middle, end), B bytes each, resync to a line boundary, recognition against the registry patterns with no side effects, own handle and counters; a file smaller than K × B is read once, whole.
2. What it hands forward: the sample lines plus per-part observations (byte size, average line length, lines seen, formats recognised, first/last timestamp), ready for #384's probes and #17's unit detection; in this issue the only consumer is the telemetry.
3. The fallback window at default N = 1,000, engaged only when the pass cannot run; the hidden `--detection-window` override stays so the fallback remains exercisable by the harness; parity at 1,000 re-proved.
4. `-V format-detection` telemetry for the sample — an observability surface — with its section contract recorded here and scenarios in `tests/validate-format-detection.sh`. No on/off switch: the regression harness's pre-existing reference outputs are the proof that output is unchanged.
5. Measurements (R5) taken through that telemetry on the real specimens and recorded here; K and B then fixed as the default constants.
6. A code comment at the pass naming #397 (percentage-based progress) as a future consumer of the size and average-line-length observations.
7. One release-notes bullet (`-V` output changes are user-observable); no `--help`/`docs/usage.md` change.

Out of scope: the content probes and variant selection (#384), unit detection (#17), the progress percentage (#397), any change to line recognition or extraction in the main read.

#### #388 findings (2026-08-22) — measured through the implementation's telemetry

Implementation: `sample_file_for_detection()` in `ltl` (FORMAT REGISTRY section), wired at the top of the per-file loop in `read_and_process_logs()`; telemetry emitted by `emit_format_detection_sample_verbose()`; key contract in `features/58-format-registry-staged-detection.md` § `-V format-detection` section-contract; harness `tests/validate-format-detection.sh` (32 assertions added, each proven to fail under a sabotaged 2 KB shape).

**F1 — What each shape sees (constraint 1).** Sweep of K ∈ {3, 4, 6} parts × B ∈ {2, 8, 32, 128} KB per part over seven real specimens (codebeamer 85 KB; Tomcat-5k 1 MB; ApplicationLog 6.9 MB with stack traces; httpd 45 MB; ScriptLog 102 MB, 405-byte lines; cxserver 105 MB; a G1 GC log with ~29 % never-matching lines). Selected rows (lines seen / recognised across all parts):

| specimen | K=3, 2 KB | K=3, 8 KB | K=4, 8 KB | K=3, 32 KB | K=3, 128 KB |
|---|---|---|---|---|---|
| codebeamer 85 KB | 56 / 56 | 230 / 230 | 308 / 308 | whole file | whole file |
| Tomcat-5k 1 MB | 28 / 28 | 113 / 113 | 155 / 155 | 471 / 471 | 1,892 / 1,892 |
| ApplicationLog 6.9 MB | 19 / 19 | 58 / 58 | 109 / 109 | 198 / 198 | 920 / 920 |
| httpd 45 MB | 29 / 29 | 119 / 119 | 158 / 158 | 481 / 481 | 1,930 / 1,930 |
| ScriptLog 102 MB | 14 / 14 | 59 / 59 | 78 / 78 | 240 / 240 | 966 / 966 |
| cxserver 105 MB | 57 / 28 | 233 / 117 | 310 / 156 | 935 / 467 | 3,741 / 1,871 |
| GC log | 58 / 41 | 230 / 170 | 307 / 224 | 928 / 669 | 3,714 / 2,663 |

The **first/last-timestamp span** — the signal that decides the date-layout case — is identical at every B on every specimen: 2 KB already reaches the file's first and last lines, and more bytes never change it. No part of any shape landed with 0 whole lines (the 37 KB ApplicationLog stack-trace line did not defeat an 8 KB part). What grows with B is the number of recognised lines available to #17: at 2 KB the access logs yield 28–29 duration-bearing lines; at 8 KB 113–119 (K=3) or 155–158 (K=4) — the ~100-line intent of #17 is met at 8 KB. cxserver recognises ~half its sampled lines (multi-line payloads) at every shape, so a consumer must reason from recognised lines, not lines seen.

**Integration Runtime (the motivating case, #385).** The specimen still dies in the production time parser (`Month '24' out of range`, fixed by #384's `timegm()` guard), so its telemetry cannot be emitted end-to-end yet; replicating the K=3 / 8 KB offsets (0, 343,282, 686,564 of 694,756 bytes) offline: the front part sees 38 lines and **0** with a day token > 12; the middle part 72 lines, **17** with day > 12; the end part 55 lines, **36** with day > 12. The sample decides the case from 24 KB that a 1,000-line front window (decision line 571) would not.

**F2 — Cost (constraint 2).** `sample_us` per file, medians over 5 runs (ranges ≤ 5 % except first-touch outliers on cold 100 MB files): K=3 / 2 KB 0.11–0.23 ms; **K=3 / 8 KB 0.22–0.68 ms (GC log 1.1 ms)**; K=4 / 8 KB 0.33–0.88 ms (GC 1.4 ms); K=3 / 32 KB 0.6–2.5 ms (GC 5.2 ms); K=3 / 128 KB 2.5–9.8 ms (GC 16.7 ms). Cost is linear in bytes read: ~3 µs per recognised line, ~4.4 µs per line on the no-match-heavy GC log (every pattern attempted); seek, resync and the reads themselves are negligible (the 2 KB column is the floor). Many-small-files: 200 × 1 MB Tomcat files, medians of 3, baseline 12.84 s vs 13.18 s with the sample — **+0.34 s, ≈ 1.7 ms per file (+2.6 %)**, of which ~0.7 ms is the recognition of ~113 sampled lines; the remainder is not attributed further. The probes themselves (D52) are #384's to measure on the same sample.

**F3 — Decorrelation (constraint 3).** `tests/validate-regression.sh` 46/46 unchanged reference outputs with the sample in; `tests/validate-format-detection.sh` 58/58 pre-existing assertions untouched (`scan_attempts`, `promotions`, `match_counts`, `final_order` identical). Fallback parity at N = 1,000: 15 runs (5 specimens incl. a 32-line file entirely held × default, `-hm duration`, `-o`) with and without `--detection-window=1000` differ only in the echoed command line and the timing/memory block. No runtime warnings on any stderr capture.

**F4 — Memory (constraint 4).** Retained per file after the sample lines are dropped: **3.9 KB at K=3** (5.5 KB at K=6; Devel::Size of the observation structure). Fallback window at N = 1,000: 310–575 B per held line (P7) → 0.3–0.6 MB while engaged, single window at a time.

**Decision — defaults fixed at K = 3 parts, B = 8,192 bytes (FORMAT_SAMPLE_PARTS / FORMAT_SAMPLE_BYTES); fallback N = 1,000 (FORMAT_DETECTION_WINDOW_FALLBACK).** 8 KB is the smallest shape past which no signal improves for the date-layout case (saturated at 2 KB) while meeting #17's ~100-recognised-line intent on access logs; three parts are the front/middle/end the principle asks for, and a fourth buys 35 % more lines for 30 % more cost without changing any decision. Cost ≈ 0.2–1.1 ms per file at the default; a few milliseconds even at 32 KB if a consumer later needs more.

### Section contracts owned by this drop

- `-V format-detection`: the owning contract is § "`-V format-detection` section-contract" below (consumer: `tests/validate-format-detection.sh`); the #384 keys (I5, I8, N8) are drafted there and lock at implementation.
- Console summary (D50, rendering settled by the architect 2026-08-23): each file line ends with ` [n,m]` / ` [-]` — brackets in the file-list white, the numbers in the new color-map entry `periwinkle` (`38;5;111`); the bracket width is reserved before `shorten_filename()`. Below the list, after a blank line, the title **Log Formats** in the file-list heading style (`white-underline`), a blank line, then one legend line `1 <name>  2 <name> …` (numbers periwinkle, names white) in first-detection order across the run. Consumed by `validate-regression.sh` references (re-blessed in this drop) and asserted by `validate-format-detection.sh` scenario `variant-mixed-legend`.
- stderr — two intentional diagnostics, never an ` at … line` suffix, both asserted by `validate-format-detection.sh`:
  - **Variant ambiguity note (I6)**, once per run, first file binding a variant-group member whose selection basis is `default`; suppressed under `-lf`, and for unit groups under `-du`: `Note: the detected log format (<name>) is written by more than one producer and the duration unit differs between them (assumed ms); nothing in the file names or content decided which - use -du <unit> or -lf <other member> if the files come from the other producer` (date-layout groups: `… and the date layout differs between them; … use -lf <other member> …`).
  - **Impossible-date diagnostic (D52/#385)**, once per file, when a month > 12 or day > 31 is met under the selected (or pinned) layout and no live alternative remains: `Note: <file> line <N>: timestamp '<ts>' has an impossible date component under the <name> format's date layout; such lines are kept at the previous line's time - use -lf to pin the correct log format`.

### Fixtures (D51) — `tests/fixtures/format-detection/`

| Fixture (committed `.txt`) | Staged as | Proves |
|---|---|---|
| `connection-server.txt` (cxserver.1-16.log, first 300 lines) | `cxserver.1.log` | group default + stem evidence (basis `evidence`, 1.00; IR member eliminated by probe a) |
| `integration-runtime.txt` (specimen lines 520–820: day tokens > 12 and ≤ 12 in file order; uuids replaced) | `IntegrationRuntime-46b44bb3-….log` | stem → `yyyy-dd-MM`; 124 matched lines, no fatal, no note |
| same | `app.log` | no name evidence → probe (a) over the sample eliminates the default; basis `evidence` (F6) |
| `tomcat-access.txt` (Tomcat 5k file, first 300 lines; IPs, customer names scrubbed) | `localhost_access_log.2025-05-05.txt` | stem + `.txt` → ms, 0.86, no note |
| same | `whatever.log` | extension alone ties the default (0.50) + note (I1 invariant) |
| `httpd-access.txt` (Windchill httpd file, first 300 lines; IPs, hosts scrubbed — F9) | `access.log-20260609` | stem + ext → µs member, 0.71; output identical to `-du us` |
| same | `renamed.txt` | ext absent → default, 0.75 + note |
| `thingworx-application-log.txt` (ApplicationLog.2025-05-06.0.log, first 300 lines; session ids, customer domains scrubbed) | `ApplicationLog.2025-05-06.0.log` | stem/date/index/ext decomposition; filename-date cross-check `match` |
| `mixed.txt` (connection-server + tomcat-access) | `mixed.log` | `formats:`, `legend:`, console `[1,2]`, title and legend line |
| `integration-runtime.txt` | with `-lf` | pin outranks stem and probes; basis `pin`; `entries: 1`; `thingworx_standard` pins two entries; impossible-date diagnostic; unknown name usage error |
| sabotage (authoring-time, per D37's coverage note) | — | in-group filename overlap, a filename sample failing its matcher, a member declared before its default — each fails the build (IF7) |

`manifest.tsv` records fixture → staged name → source → what it proves; the harness's `stage_fixture()` copies each into a per-scenario directory so the committed name is never fed to the tool. Every scenario runs `-bs 1440 -oe` (HARNESS-DESIGN § Invocation coherence): the slices span months and the assertions never read a bucket.

### Out of scope (unchanged from the issue)

Statistical unit sampling (#17's remaining half); content fingerprinting beyond the declared pattern; directory/path heuristics beyond the file's own name; file-property performance heuristics (#44); any change to line recognition or extraction (#58's parity stands).

### Merge gate

- [x] Research → prototype phase: scan-sub member selection cost (D47) and probe costs (D52) measured against the #58 S9 battery; weights (proposal 1) set from fixture outcomes; decisions recorded here before implementation. *(F1–F9, 2026-08-23.)*
- [x] #388 closed with the six constraints above satisfied. *(PR #398, 2026-08-22.)*
- [x] All D51 fixtures committed and their scenarios green in `validate-format-detection.sh` (159 assertions); full `tests/validate-*.sh` suite exits 0; runtime-warning-clean. *(S6; full-suite run recorded under S7 below.)*
- [x] Success criteria from the issue: Tomcat-named and httpd-named identical-shape files resolve to different units with no `-du` (IF6); IR-named file reads `yyyy-dd-MM` with no fatal (IF4/IF6); pin wins (S4); unnamed file behaves as today plus the note (IF6: `whatever.log`, `renamed.txt`); sabotage fails at load (IF7); no read-phase regression outside noise (IF2).
- [x] `--help`, `docs/usage.md`, `docs/staged-processing-pipeline.md` (detect-stage contract), this section, and the `-V` contract updated in the same change; release-notes bullet (user-observable). *(Release-notes bullet at merge, per-feature workflow step 6.)*
- [ ] #385 closed by this drop; #17's declarative half noted complete on #17. *(At merge.)*

## #413 — lazy scan-sub compilation (elevation by election)

### Status

- **Design locked (architect, 2026-08-24): D60–D64 below.** Audit + prototype findings below. Branch `413-eager-scan-order-precompile` (cut from the #415 branch — #415's drift re-measure is the downstream discriminator, native `blocked_by` recorded on #415).

### The problem (measured, current tree)

Every run pays a fixed ~20 MB peak RSS and ~0.1 s (`TIMING detect/registry_build`) compiling scan-order subs it may never use: 2-line probe, v0.16.0 24.7 MB vs 0.17.0 44.5 MB / 0.101 s. `-lf` saves nothing — `apply_format_pin()` runs after the full build; even an invalid `-lf` operand pays the full cost before erroring.

### Audit finding: three compile sources at startup, not one

1. **D40 eager loop** in `build_format_registry()` — the static order plus one first-promotion order per scanned entry.
2. **Gate 5 validation** — `format_registry_set_occupant()` swaps compile per variant member, and the sample stream *promotes* entries mid-validation, compiling deeper recency orders ("warming").
3. **`apply_format_pin()`** — clears the cache and compiles the single-entry order on top of everything above.

Instrumented split (env-gated scratch copy, 2-line probe): full = **28 compiles / 44.8 MB peak**; eager loop off = **17 compiles / 37.9 MB** (gate 5 alone mints 16 subs ≈ 10 MB); both off = **2 compiles / 28.4 MB** (static + the parallel default-configuration validation compile). Removing only the eager loop recovers barely half the regression.

### Memory cost constants (prototype, 2026-08-24 — the gap in the original #58 implementation, which measured compile *time* but never sub *size*)

| measure | per compiled sub |
|---|---|
| generated source | ~29 KB |
| `Devel::Size::total_size` of the closure | 354 KB |
| actual RSS delta per compile | ~610–980 KB, median ~620 KB |

- `Devel::Size` reaches only ~55% of the real cost (op-tree and pad storage are invisible to it). A `-mem` category for `%format_scan_sub_cache` must pair the measured `Devel::Size` value with a compiled-sub count (readable against the ~0.6 MB/sub calibrated constant); measurement alone under-reports ~2x.
- Every sub is the same size (one block per scanned group), so cache memory is linear: ~0.6 MB x orders-compiled.
- Time constants already on record (#384 prototype F-findings): cold compile 2.54 ms, warm cache hit 52 ns.

### Locked decisions (architect, 2026-08-24)

- **D60 — Elevation by election: zero codegen at startup; a format's scan sub is compiled when detection elects it.** `build_format_registry()` compiles nothing (the D40 eager loop, gate 5's warming, and the parallel default-configuration scan compile are all removed from startup). Compile points: (1) per-file election — the sampling pass elects, occupants are seated, and the winner-front order compiles through the existing promotion machinery (`//=` cache); (2) mid-file flips — the existing probe → promote → lazy compile path, untouched; (3) `apply_format_pin()` compiles its single-entry sub at pin time (an invalid `-lf` operand now errors before any codegen); (4) fallback — a file with no election compiles the static order before line 1. Invariant: the hot loop always holds a compiled sub for the current order; there is NO interpreted per-line extraction path (a second implementation of the extraction semantics would reopen the parity surface #58 closed with 241 shadow runs). Detection/evidence remains fully interpreted (`sample_file_for_detection()`, `format_sample_probes()` — plain per-entry `qr//`); startup sample classification and the sampling pass share one interpreted classifier (one resolution surface). *Amends D40, which is superseded: "pay the compile cost before the loop" bought ~20 MB resident and ~0.1 s on every run for orders mostly never used; a ~2.5 ms once-per-signature compile at election is the better trade.*
- **D61 — Gate restructure: gates 1–4 stay at startup (none needs the scan sub — gate 2's extraction parity runs per-entry `compile_format_extractor()` closures); gate 5 splits.** Startup: every sample classifies to its owning entry via the shared interpreted classifier. Compile time: every sample of every entry present in a freshly compiled sub runs through it and its owner must win (classification-only; extraction is gate-2-proven; D26's pinned-ancestor closures make owner-wins valid under any reachable order). Per-compile validation runs under a promotion-suppression flag — `format_registry_promote()` returns early (no reorder, no compile) while validating, since winner capture precedes promotion in the generated code. Recorded trade: a variant member's generated block is proven the first time it is compiled into any sub (when actually elected), not eagerly for formats the run never sees; its spec is still startup-proven interpretively.
- **D62 — `-mem` category `format_scan_subs`: value = accumulated compile-boundary RSS delta, plus the compiled-sub count. No `Devel::Size` field.** The measurement technique fits the structure being measured, not the table's dominant methodology: closures' op-tree and pad storage are invisible to structure walkers (~55% blind, prototype-measured), and RSS delta at the compile boundary is the only accurate instrument (compiles allocate nothing else concurrently). Capture is armed at option-parse time whenever any memory-reporting surface is requested (`-mem`, or a `-V` section emitting `MEMORY` rows, benchmark-data included); plain runs pay zero.
- **D63 — New `-V format-registry` section (registered after `format-detection`) closes the registry-observability miss: the registry itself had no surface.** Contents: inventory (one line per entry — name, slug, group, variant-default, scanned/CSV role); structure (variant groups with occupants, static scan order, derived ancestor constraints); compile state (`scan_subs_compiled`, `scan_sub_cache_hits`, `scan_subs_rss_bytes`, compiled order signatures). The compile counters are computed once at their block boundaries in registry machinery and re-emitted by `benchmark-data` as `COUNTS`/`MEMORY` rows from the same variables (one source, two surfaces per tests/HARNESS-DESIGN.md). New consuming harness `tests/validate-format-registry.sh` (name tracks the section) with self-documenting assertions, including election invariants: single-format file ⇒ `scan_subs_compiled` ≤ 2; `-lf` ⇒ exactly 1. Per-file detection telemetry stays in `format-detection / scan`.
- **D64 — Timing rows: `TIMING detect/registry_build` keeps its name and meaning** (build without codegen, ~14 ms expected); a new accumulator row `detect/scan_sub_compile` sums all `compile_format_scan_sub()` calls wherever they fire (election pre-line-1, mid-read promotion) — one boundary pair inside the compile sub, ~2 timer calls per compile.

### Validation plan (locked with the design)

1. Byte parity: full-output diff, current tree vs branch, across the format fixture families (`tests/fixtures/format-detection/`, #58 S9 battery, multi-format interleave) — election changes when subs compile, never what any line produces. Invocation-coherent shapes (`-bs 1440 -oe`, smallest carrying fixture).
2. Gains measured: 2-line RSS/timing probe on the branch (expect ~28 MB / ~14 ms vs 44.5 MB / 101 ms), plus `-lf` and invalid-`-lf` probes.
3. No new hot-loop cost: read-phase timing parity, median-of-3, one 1m fixture.
4. Gate equivalence by sabotage (scratch copy): a broken sample dies at startup via the interpreted gate; sabotaged codegen dies at first compile via per-compile validation.
5. Edge paths: unknown-format fallback, non-seekable stdin, mid-file flip fixture, `-lf` exactly-one-compile.
6. Harnesses during work: `validate-format-detection.sh` (159 assertions untouched) and the new `validate-format-registry.sh` only; the full suite is the release gate.

### Implementation plan (approved by the architect, 2026-08-24) — branch `413-eager-scan-order-precompile`

Each stage is its own commit with its verification run before the next begins. Consumer harnesses during work: `validate-format-detection.sh` + the new `validate-format-registry.sh` ONLY; the full suite is the release gate.

- **S1 — Shared interpreted classifier.** Factor the classification walk (guard + `qr//` first-match over a given order) into one named sub; `sample_file_for_detection()` and the startup gate both call it (one resolution surface). No behavior change; verify byte parity + `validate-format-detection.sh`.
- **S2 — Remove startup codegen.** Delete the D40 eager loop; gate 5's sample classification moves to the interpreted classifier; the default-config scan compile and gate-5 warming removed. Interim state: the run still compiles the static sub before line 1, so every fixture stays green mid-train.
- **S3 — Compile points + per-compile validation (D60/D61).** Promotion-suppressed per-compile sample validation inside `compile_format_scan_sub()`; election compiles the winner-front order pre-line-1; static-order fallback; `apply_format_pin()` compile-at-pin with early error on unknown operand. Compiles drop to 1–2 per typical run here.
- **S4 — D62 memory measurement.** Compile-boundary RSS-delta capture (armed at option parse only when a memory-reporting surface is requested), compiled-sub count, `format_scan_subs` `-mem` category.
- **S5 — D63 observability.** `-V format-registry` emitter (inventory / structure / compile state), `benchmark-data` re-emission from the same variables (one source, two surfaces), section contract added to this doc, new `tests/validate-format-registry.sh` with self-documenting assertions (election invariants: single-format ≤ 2 compiles, `-lf` = exactly 1).
- **S6 — D64 timing + doc sweep.** `TIMING detect/scan_sub_compile` accumulator; user-facing doc surfaces that enumerate `-V` sections updated in the same commit.
- **S7 — Validation plan F1–F6** (§ Validation plan above): byte-parity battery, gain probes (expect ~28 MB / ~14 ms vs 44.5 MB / 101 ms), hot-loop parity median-of-3, sabotage proofs, edge paths (unknown-format fallback, non-seekable stdin, mid-file flip, `-lf`).

Then the per-feature workflow (PR into `release/0.17.0` when the architect directs). #415's re-measure is downstream and NOT this issue's scope.

### Implementation progress (as of 2026-08-24) — S1–S5 delivered, resume at S6

Branch `413-eager-scan-order-precompile`. S1–S5 are committed; the tree stands at S5. **Work resumes at S6.**

| Stage | Commit | State |
|---|---|---|
| S1 — shared interpreted classifier | `001a00b` | delivered |
| S2 — no codegen at startup | `beba4b1` | delivered |
| S3 — compile points + per-compile validation | `d8576c6` | delivered |
| S4 — `format_scan_subs` memory category | `7f33d97` | delivered |
| S5 — `-V format-registry` + its harness | `9566cc4` | delivered |
| S6 — D64 timing + doc sweep | — | **next** |
| S7 — validation plan F1–F6 | — | not started |

**Gains measured at S5** (2-line probe, median of 3, against the pre-branch tree): peak RSS 42.2 → 26.2 MiB; `TIMING detect/registry_build` 0.101 → 0.008 s. Both beat D60's expectation (~28 MB / ~14 ms). Compiles per run: single-format 1, `-lf` exactly 1, invalid `-lf` 0, mixed-format fixture 3.

**Verification standing at S5:** byte parity across `tests/fixtures/format-detection/` (all eight fixtures, `-bs 1440 -oe`) with one deliberate exception, `validate-format-detection.sh` 192/192, `validate-format-registry.sh` 22/22, `validate-help-content.sh` 11/11.

#### Findings carried forward

- **F10 — `promotions:` legitimately drops from 1 to 0 for a single-format file.** Election fronts the elected group before line 1, so the first match already sits at an optimal position and emits no promotion code. The `format-detection` scan-telemetry assertion was updated to `^promotions: 0$` with the stronger invariant in its `asserts` text. Any future reading of promotion telemetry must account for election having already done the first reorder.
- **F11 — per-compile validation must disturb NOTHING of the run's state, because compiles now happen mid-run.** D61's per-compile gate was originally written to reset the record lexicals, the timestamp memo and the date cache the way the startup gates do. That is correct only when validation runs exclusively before line 1. Under D60 a compile also fires at election and at mid-read promotion, and resetting there cleared the timestamp memo mid-file: the next real line re-parsed its timestamp, the cache miss fired the steady-loop probes, and the mixed fixture's variant scores changed *and* its included line count dropped from 450 to 448. The fix, and the contract for any future work inside `compile_format_scan_sub()`: suppress `format_probe_signal()` alongside `format_registry_promote()`, and snapshot/restore (never reset) the record lexicals, `$format_last_ts_str`/`$format_last_ts_epoch` and the date cache. The date cache is keyed by date string alone and two layouts disagree on its epoch (N3), so a sample parsed under one entry's layout must never be left behind for the run to read.
- **F12 — the D62 RSS instrument distorts the D64 timing row if both boundaries coincide.** Measured while starting S6: with `TIMING detect/scan_sub_compile` bracketing the whole of `compile_format_scan_sub()`, the mixed fixture reported 0.032 s for 3 compiles (~10.7 ms each) against a codegen+validation cost of 3.4 ms each (codegen 3.1 ms, per-compile validation 0.3 ms — the latter measured, and cheap). The gap is `get_memory_usage()`, which shells out to `ps` on macOS and is called twice per compile when D62 measurement is armed. **S6 must place the D64 timing boundary so it excludes the D62 RSS readings** — otherwise the timing row reports the cost of measuring memory rather than the cost of compiling, and only on armed runs, which is exactly where a reader would compare the two. Note also that this makes the row's value depend on whether measurement was armed; the S6 contract text should say which it measures.
- **F13 — `TIMING detect/scan_sub_compile` is an accumulator, not a pipeline stage.** Compiles fire inside other stages (election before a file's first line, promotion mid-read), so the row attributes cost *within* those stages and must NOT be added to `$elapsed_total`, which sums disjoint stage timings.

#### S6 scope reminders

- The D64 boundary placement per F12 above.
- Doc sweep: `docs/usage.md`'s `-V` prose and `tests/HARNESS-DESIGN.md`'s reserved-names list already carry `format-registry` (landed with S5). S6's sweep covers whatever the timing row adds — the `benchmark-data` contract and any surface enumerating `TIMING` rows.

## `-V format-detection` section-contract

This section is the owning contract for the `format-detection` `-V` section and its `format-detection / scan` sub-section, both emitted by `emit_format_detection_verbose()` and consumed by `tests/validate-format-detection.sh`. All pre-existing keys of the parent section (per-file `format:`, `match_type:`, `is_access_log:`, `matched_lines:`, `unmatched_lines:`, `first_match_line:`; run-level `duration_unit_override:`, `files:`) are byte-preserved from their pre-registry shapes; everything below is additive. Renames and removals are breaking per `tests/HARNESS-DESIGN.md` § Stability contract.

**Per-file keys (inside each `file:` block, two-space indent):**

- `scan_attempts: N` — registry scan-sub invocations for this file. Counts one per line entering the scan, **including** detection-window prefill classifications; **excluding** confirmed-CSV fast-path lines (outside the scan, D32) and held-window replay lines (their classification was already counted at prefill; the replay runs only the entry's extraction). A file the scan never touches (all-CSV after confirmation, empty file) reports 0.
- `scan_failed_attempts: N` — the subset of `scan_attempts` that matched no entry (the no-match scan — the structural worst case, every entry attempted). Increments on the streaming no-match branch and on prefill classifications returning no entry. A fully-matched file reports 0; `matched_lines + scan_failed_attempts = scan_attempts` holds for non-CSV files with no window.

Detection-evidence keys (umbrella D53, #388; emitted by `emit_format_detection_sample_verbose()` after the keys above, for every file block including the no-bind-attempts form):

- `window: N` — the two-phase-store window size engaged **for this file**: the `--detection-window` override when given; otherwise `window_fallback` when the file could not be sampled; otherwise 0. This is the dual process's "which path served the file" indicator read together with `sample:`.
- `sample: yes|no` — whether the read-only evidence sample was taken (`no` only when the path is not a plain file; such a file gets the fallback window). When `no`, no further `sample_*` keys follow.
- `sample_file_bytes: N` — the file's byte size at sampling time.
- `sample_whole_file: yes|no` — `yes` when the file is no larger than `sample_parts × sample_bytes_per_part` and was read once, whole, as a single part.
- `sample_lines: N` / `sample_matched_lines: N` — whole lines seen across all parts, and how many of them matched a registry entry (first match in static cascade order; no extraction, no promotion — these never feed `scan_attempts` or `match_counts`).
- `sample_formats: name=N,...` — per-entry counts across the sample, static registry order, entry names (not slugs); `-` when nothing matched.
- `sample_part: i offset=O bytes=B lines=L avg_line=A matched=M first_ts="…" last_ts="…"` — one line per part, `i` from 1. `offset` is the byte offset seeked to (part 1 is 0; the last part ends at EOF); `bytes` the bytes read; `lines` the whole lines kept after discarding the partial line at either edge; `avg_line` the integer mean line length over those lines (0 when none); `first_ts`/`last_ts` the **raw** timestamp capture of the first and last matched line in the part (never parsed — interpreting it under a layout is the consumers' job), `-` when no line matched. A part shorter than one line (a stack-trace line longer than the part) legitimately reports `lines=0`.
- `sample_us: X.X` — wall microseconds for the whole sample (open, seeks, reads, recognition), one decimal. **Nondeterministic** — harnesses assert its shape, never its value.

**Sub-section `=== format-detection / scan ===` (run-level, one per run, emitted inside the parent section before its END marker; closed by `=== END format-detection / scan ===`):**

- `entries: N` — count of scanned registry entries compiled into the scan sub (15 since #395 added `mt16` and #396 `mt17`; `csv` is outside the scan array by design, D32). Changes only when a scanned format is added/removed — same commit updates this contract and the harness.
- `guarded: name,...` — registry entry names (FR_NAME, e.g. `mt12`) carrying a D28 cheap-superset guard, static registry order; `-` if none. Currently `mt12,mt4,mt9`.
- `window_size: N` — the `--detection-window` override value (hidden; D30/D38); 0 when not given. It is not the size engaged per file — that is the per-file `window:` key, which resolves to `window_fallback` for unsampled files.
- `window_fallback: N` — `FORMAT_DETECTION_WINDOW_FALLBACK`, the window size engaged for a file that could not be sampled (umbrella D53; 1000).
- `sample_parts: K` / `sample_bytes_per_part: B` — `FORMAT_SAMPLE_PARTS` and `FORMAT_SAMPLE_BYTES`, the evidence sample's shape (umbrella D53; values set by #388's measurements — see `features/log-format-registry.md` § "#388 — detection evidence sampling pass"). Changing either changes every `sample_*` per-file value in the harness in the same commit.
- `final_order: name,...` — the MTF scan order (`@format_scan_order`) at emission time, front first. Proves promotion end-state: a single-format run shows that format's pinned-ancestor closure + itself at the front, tail in recency order.
- `promotions: N` — count of actual reorders through `format_registry_promote()`. Increments only when a winner at a non-optimal generated position promotes; steady-state front matches emit no promotion code and do not count. Reset to 0 at the end of `build_format_registry()` so D24 gate-5 sample classification (which promotes) is excluded — the counter reports run promotions only.
- `match_counts: name=N,...` — per-entry matched-line totals across the run, **static registry order** (comparable across runs regardless of promotion history). Keyed by entry name, not slug: two entries can share a slug (mt1std/mt1gen → `thingworx_standard`) and the scan attributes per entry. CSV-matched lines are not listed (csv is not a scan entry).
- `nomatch_scan_samples: N` — number of sampled no-match scan timings. Sampling is 1 in `FORMAT_SCAN_NOMATCH_SAMPLE_EVERY` (= 256) no-match lines per file: the sampled line is **re-scanned under a timer** on the already-expensive no-match path. The re-scan is side-effect-safe (no match ⇒ no promotion; failed attempts' empty-capture writes repeat the first scan's end state). Per-line timer pairs around every scan were considered and rejected as an anti-pattern — the clock calls would cost more than many scans they measure.
- `nomatch_scan_avg_us: X.X` — mean elapsed microseconds across those samples, one decimal; the literal `-` when zero samples. **Nondeterministic when samples exist** — harnesses assert its shape (`[0-9]+\.[0-9]`), never its value, and it must be stripped by any golden-output capture that enables this section.

Vocabulary note: entry names (`mt1std`, `mt3`, …) are the registry's internal scan identity and appear only in this diagnostic sub-section; the user-facing format identity remains the slug vocabulary locked by `%match_type_to_slug`.

**#384 additions (Drop 1.5; locked at implementation 2026-08-23 — I5, I8, N8). Emitted by `emit_format_detection_evidence_verbose()` after the `sample_*` keys (after `sample: no` for an unsampled file):**

Per-file keys:

- `formats: name,...` — every user-facing format name that matched at least one line of the file, the first-bound format first then static member order (the bracket's content, N7); `-` for a no-match file. Always emitted.
- Under `-lf` the only further keys are `selection_basis: pin` and `confidence: 1.00`.
- `filename_evidence: stem=<entry|-> ext=match|absent|other|- date=match|mismatch|present|- index=present|-` — the D45 decomposition of the file's basename (compression suffix stripped) against every entry declaring filename evidence; `stem=` names the first entry (static member order) whose stem matched, and `ext`/`date`/`index` are that entry's decomposition (`ext=other`: an undeclared extension; `-` when no stem matched). `date=` is the cross-check of the filename's date against the first ISO content timestamp read as `yyyy-MM-dd` when it could run, else `present`.
- Then, per variant group whose shape appeared in the sample (slot order), one block:
  - `variant_group: <group>`
  - `candidates: name=score,...` — every member's score after all signals (I1 weights, `%.2f`), member order as declared; an eliminated member shows `0.00`.
  - `selected: name` — the entry occupying the group's slot for this file at emission time (entry name; the user-facing name is `format:`/`formats:`).
  - `selection_basis: evidence|default` — `evidence` when a non-default signal decided (stem, filename date, an elimination, a steady-loop flip); `default` when the standing credit or a tie held the default.
  - `confidence: 0.NN` — selected member's score ÷ the sum of the live members' scores at emission time; `0.00` when no member survived (default holds).
  - `flips: N` — occupant changes after the first decision (N5).
  - `probes: sample_out_of_range=N sample_monotonic_violations=N out_of_range=N monotonic_violations=N filename_date=match|mismatch|-` — the sample's counts under the selected member's layout, the steady-loop counts for the file (distinct timestamps, selected layout), and the sample's filename-date cross-check under that layout.

Run-level keys (parent section, after `format_pin:`):

- `format_pin: -|<name>` — the `-lf` value (emitted after `duration_unit_override:`).
- `legend: 1=<name>,2=<name>|-` — the console legend, numbered in first-detection order across the run (I8).

Sub-section `format-detection / scan` additions:

- `match_counts:` and per-file `sample_formats:` list every scanned **member** (spec order, non-occupant variants included), so a variant member's matches are attributable.
- `variant_groups: group=occupant,...|-` — each variant group with ≥ 2 members and the entry occupying its slot at emission time (slot order); `-` for the occupant when the pin excluded the group.
- `entries: N` keeps its meaning — occupants compiled into the scan sub (one per group slot; 15), not members.

## `-V format-registry` section-contract

This section is the owning contract for the `format-registry` `-V` section, emitted by `emit_format_registry_verbose()` and consumed by `tests/validate-format-registry.sh`. It closes the registry-observability gap #58 left: `format-detection` reports what each *file* bound and how the scan behaved per line, but nothing reported what the registry **is** or what codegen a run paid for. Renames and removals are breaking per `tests/HARNESS-DESIGN.md` § Stability contract.

Entry names (`mt1std`, `mt3us`, …) throughout, never slugs — the registry orders and compiles entries, and two entries can share a slug (mt1std/mt1gen → `thingworx_standard`), the same vocabulary rule the `format-detection / scan` sub-section follows.

**Inventory** — what was compiled from the declarative specs:

- `entries: N` — every entry in `format_registry_specs()`, scanned and stateful alike (18: 17 scanned + `csv`).
- `scanned_entries: N` — entries the scan can recognise, variant members included (17). Changes only when a scanned format is added or removed — same commit updates this contract and the harness.
- `scan_slots: N` — slots in the live scan array (15). One per variant group, since only one member of a group is seated at a time (D47), so `scan_slots ≤ scanned_entries`. Equals `entries: N` in `format-detection / scan`, which counts the same slots. Under `-lf` this narrows to the pinned format's member count.
- `  entry: <name> slug=<slug> group=<group> default=yes|no role=scanned|stateful` — one line per entry, static spec order. `group` is the entry's `variant_group` or its own name; `default=yes` marks the member holding the group's slot by default; `role=stateful` marks an entry outside the generated scan (`csv` alone today, D32).

**Structure** — how the scan is organised and what constrains its ordering:

- `variant_groups: group=occupant,...|-` — each variant group with ≥ 2 members and the entry occupying its slot at emission time (slot order). Same key and semantics as the `format-detection / scan` line of the same name; here it heads the per-group detail below.
- `  group: <group> slot=N default=<name> members=<name>,...` — one line per variant group: its position in the scan array, its default member, and every member in declaration order.
- `static_order: name,...` — the declaration order of the group slots: the order every run starts from and that promotion permutes. It is **not** the run's end-state order — that is `final_order:` in `format-detection / scan`.
- `  ancestors: <group> <- <group>,...|-` — the derived pinned-ancestor set per scan slot, static order: the groups whose patterns shadow this one, which promotion may never move it behind (D26). `-` means nothing shadows the group, so it may promote to the very front. Derived by `derive_format_constraints()` and cross-checked against each entry's declared `expect_ancestors` by D24 gate 4, so a drift fails the build before it reaches this line.

**Compile state** — what codegen the run actually paid for. Under D60 nothing is generated at startup, so these are the run's real registry cost:

- `scan_subs_compiled: N` — generated scan subs minted this run, counted at the codegen boundary in `compile_format_scan_sub()`. The election invariants: a single-format file ⇒ ≤ 2; `-lf` ⇒ exactly 1; an invalid `-lf` ⇒ 0 (the operand is validated before any codegen). A multi-format file compiles one sub per distinct recency order its stream visits, never one per registry entry.
- `scan_sub_cache_hits: N` — resolves served from the order-signature cache (`format_scan_sub_resolve()` found the order already compiled). A run that revisits an order it has scanned with before pays a cache hit (~52 ns), not a compile (~2.5 ms).
- `scan_subs_rss_bytes: N` — the accumulated compile-boundary RSS delta (D62), bytes. **Nondeterministic** — harnesses assert its shape, never its value. Read against `scan_subs_compiled` it gives the per-sub cost, which calibrates at ~0.6 MB. `0` when measurement was not armed.
- `scan_sub_rss_measured: yes|no` — whether the D62 measurement was armed at option parse (a memory-reporting surface was requested: `-mem`, `-V benchmark-data`, or this section). `no` is why `scan_subs_rss_bytes` reads 0 on a plain run; the two keys are read together so a zero is never mistaken for a measurement.
- `compiled_orders: sig;...|-` — every compiled order's signature (joined entry names), sorted. The compile count read against which orders the run actually needed.

**Re-emission (one source, two surfaces per `tests/HARNESS-DESIGN.md`):** `benchmark-data` emits `COUNTS format_scan_subs_compiled` and `COUNTS format_scan_sub_cache_hits` from the same variables this section reads, and `MEMORY format_scan_subs` from the same accumulator — never an independent recount. The `MEMORY` row is emitted whenever measurement was armed, including without `-mem`: it is a compile-boundary RSS delta, not a structure walk, so it does not depend on the `Devel::Size` pass the other `MEMORY` rows are gated on. Under `-mem` the category rides `%memory_high_water_marks` (appearing in the `-mem` terminal breakdown) and the standalone row stands down, so exactly one row is emitted either way.

## TODOs

- [x] Research fuzzy matching algorithms for message identity grouping (section 9) — completed via #96/#54, see `docs/similarity-engine-best-practices.md`
- [ ] Define the expression/function syntax for derived metrics
- [ ] Research existing Perl expression parsing libraries
- [ ] Map out the full dependency between existing processing steps and the new deferred-per-bucket model
- [ ] Inventory all current data structures that would be affected by the sliding window approach
- [ ] Profile memory usage of current model to establish baseline for comparison
- [ ] Research how Prometheus, RRDtool, and Graphite handle temporal interpolation and counter staleness
- [ ] Build regression test suite capturing current output as golden files before implementation begins
- [ ] Define phasing plan with independent deliverables per phase
- [ ] Prototype bucket data structure and measure memory for representative log files

## Implementation Phasing

This refactor is staged into phases with independent deliverables. Each phase builds on the previous and can be validated independently. Prerequisites must be completed before Phase 1 begins.

### Prerequisites (trued up 2026-07-15)
| Issue | Title | Status / Purpose |
|-------|-------|------------------|
| #53 | Automated test suite with golden files | **COMPLETE** (delivered with #56, v0.14.2) |
| #54 | Fuzzy matching engine research | **COMPLETE** — implemented in #96 (v0.13.0). See `docs/similarity-engine-best-practices.md` |
| #56 | Memory baseline profiling | **COMPLETE** (v0.14.2) |
| #179 | Index read-back with drift detection and refresh | **COMPLETE** (shipped v0.15.x), with a **narrowed role** under the #187 contract: partitions auto-resize online, so the index is no longer load-bearing for histogram/heatmap bound pre-seed. Remaining value to this rewrite: timestamp-range / `ts_precision` hints to the `detect` stage, and prior-run unit knowledge (see D18 precedence order). |
| #180 | Name the implicit pipeline stages (detect/parse/accumulate/finalize/render) | **COMPLETE — shipped 2026-08-20** (PR #380 into `release/0.17.0`). Phase 1 inserts the registry into the `detect` stage (`pipeline_detect()`/`pipeline_parse()` now exist); Phase 2 adds per-bucket lifecycle inside `finalize`. |
| #181 | Decouple file I/O from processing via a buffered read pipeline | **REFRAMED (2026-07-10 / 2026-07-15, D17) — architecture guidance, not a deliverable.** Perf testing showed file I/O is not a bottleneck. Phase 1 needs only a minimal detection window (hold the first ~N lines during format detection, per-line re-detect on cache-miss); that window is also the future substrate for #17's unit sampling. No full reader/processor decoupling is built. |
| ~~#41~~ | ~~Heatmap/histogram unified binning~~ | **CLOSED — superseded by #187/#189**: heatmap and histogram run the same unified bin-counter primitives at the same precision. |
| ~~#34~~ | ~~Memory-optimized two-pass streaming~~ | **CLOSED — resolved by #187/#189**: reframed as the consumer migration onto the unified primitive contract and delivered there. |
| ~~#51~~ | ~~Highlight-data memory optimization~~ | **CLOSED — resolved under the #187/#189 contract** (highlight-subset consumer migration). |
| #55 | Expression parser research & build | **OPEN — Phase 4 prerequisite; out of 0.17.0 scope** (deferred with Phase 4). Standalone component for derived metric arithmetic. |
| #57 | Bucket data structure prototype | **OPEN — Phase 2 gate (Drop 2a), rescoped 2026-07-15.** Per-entry cost constants are already measured (#323/#306); the prototype's remaining question is the per-bucket *transient* holding cost and window shape under the sliding window. See D15. |

### Phases (re-cut 2026-07-15, D21 — 0.17.0 merge train)
| Issue | Phase | Drop | Title | Depends On | 0.17.0 |
|-------|-------|------|-------|------------|--------|
| #180 | — | 0 | Named pipeline stages (zero behavioral change) | — | **In — MERGED 2026-08-20 (PR #380)** |
| #58 | 1 | 1 | Format registry and staged detection (fixes #369; unblocks #17's declarative path) | #180 | **In — MERGED 2026-08-21 (PR #389)** |
| #388 | — | — | Design and size the detection evidence sampling pass (prototyping; D53, delivers the D48 contract) | #58 | **In — prerequisite of Drop 1.5 (added 2026-08-22)** |
| #384 | 1 | 1.5 | Filename provenance evidence and variant groups (fixes #385; completes #17's declarative half) | #388 | **In (added 2026-08-20; planned 2026-08-22)** |
| #387 | 1 | 1.75 | User YAML format definitions + home configuration directory/file convention (D37 re-sequenced R4 surface) | #58 | **Out — 0.18.0 (D59)** |
| #60 | 3 | 2 | Configurable metric visibility and purpose | #387 (re-cut 2026-08-23; was #384, before that #58) | **Out — 0.18.0 (D59)** |
| #57 | — | — | Bucket data structure prototype (go/no-go gate for Phase 2) | #58 (design context) | **Out — Phase 2+4 release (D21)** |
| #59 | 2 | — | Sliding-window deferred-per-bucket processing (motivating consumer: Phase 4 inter-line derived metrics) | #58, #57 | **Out — Phase 2+4 release (D21)** |
| #61 | 4 | — | Derived metrics (intra-line and inter-line) | #60, #55, #59 in practice (#54 already COMPLETE) | **Out — Phase 2+4 release (D16/D21)** |

Phase 2's deferred-per-bucket machinery exists *for* Phase 4's inter-line functions (2026-02-06 decision 2); shipping it a release ahead of its consumer would build holding machinery nothing uses, while streaming bin-mode accumulation (v0.15.x–v0.16.0) has already absorbed part of its secondary justification. Hence: one coherent "bucketed computation + derived metrics" release after 0.17.0.

Each drop lands on its own branch off `release/0.17.0`, merges back via PR through the full regression gate (byte-identical golden files + complete `tests/validate-*.sh` suite + targeted timing/memory probes sized to the drop). The XL benchmark `all` tier runs once, at release-gate time.

### Phasing Principles
- Each phase must produce identical output for existing functionality (golden file comparison)
- No phase should be started before its prerequisites are complete
- Requirements will continue to be refined through design conversations — future sessions should revisit phasing as understanding deepens
- Resist adding new requirements mid-phase; capture them for the next phase or as new prerequisites

## GitHub Issue

[Issue #23: Log Format Registry - Refactor core parsing architecture](https://github.com/gregeva/logtimeline/issues/23)

## Design Decisions Log

### 2026-08-24: #413 — lazy scan-sub compilation (elevation by election), D60–D64

Architect-locked after audit + prototype (see the #413 section above): D60 elevation by election supersedes D40's eager precompile (three startup compile sources measured: eager loop, gate-5 warming, pin — 28 compiles / +20 MB / ~0.1 s); D61 gate restructure (gates 1–4 startup-unchanged, gate 5 split into interpreted startup classification + per-compile validation under promotion suppression); D62 `format_scan_subs` -mem category measured by compile-boundary RSS delta (technique fits the structure — Devel::Size is ~55% blind to closures); D63 new `-V format-registry` section + `tests/validate-format-registry.sh` (registry-level observability was a #58 miss); D64 `detect/scan_sub_compile` timing accumulator. #415's drift re-measure is downstream (`blocked_by` this issue) and explicitly NOT in scope here.

### 2026-08-23: Release re-cut — D59

**D59 — 0.17.0 ships without Drops 1.75/2; #387 and #60 open the 0.18.0 train.** The merged drops (0, 1, 1.5 plus #395 and fixes) are individually gate-closed with byte-parity proofs and carry the release-worthy value on their own: the registry perf win (#369 regression removed as a class), format-carried units, variant disambiguation (#385 fixed), a new format. Nothing user-facing is half-built — user YAML (#387) is purely additive on the shipped substrate, and #60's merge gate is default parity regardless of which release it rides. Rationale: the next two drops are design-heavy (config-directory convention; the generalized demand map) and benefit from real-world operating experience with the registry before their designs are locked. Order and gating are unchanged — #387 → #60, native `#60 blocked_by #387` stands; only the release boundary moves.

### 2026-08-22: Drop 1.5 (#384) planning interview — D44–D52

Filename provenance evidence and variant groups specified through an architect interview; full text in § "Drop 1.5 — #384" above. Summary of the locked calls:

1. **D44 — Staged signal accumulation; never 100%; visible-or-good-enough.** Filename first, then line matches, then content probes; the current best candidate reads the file and may flip; a wrong variant becomes visible to the analyst or was good enough, and the console names what was used so the analyst can pin.
2. **D45 — Four optional filename components per entry** (stem, date, rotation index, extension) plus executable filename samples; the resolver composes the matcher; extension adds certainty, its absence withholds it, never contradicts.
3. **D46 — Weights fixed per evidence class in source**, never in the schema.
4. **D47 — Variant groups as full entries**, one member per identical pattern in the scan per file (selected by evidence, default member = today's behaviour); different-pattern members scan normally — the shape #387's user variants extend. Tomcat/httpd and Connection Server/Integration Runtime become the first two groups; `unit_ambiguous` retires in favour of "default-selected without deciding evidence".
5. **D48 — First decision made before line 1 from sampled evidence (D53); late flips accepted and reported**; #388 is a native prerequisite and receives six constraints.
6. **D53 — Multi-spot sampling pass is the evidence source; the held-line window is the fallback for non-seekable input** (pipes, compressed streams); probes are fed lines, never file positions. Locked 2026-08-22, amending D48 and the #388 constraints.
6. **D49 — Run-level format pin** tops the chain: pin → `-du` → evidence → group default → index hints → #17 sampling.
7. **D50 — Console summary brackets `[n,m]` + numbered legend**, slug vocabulary; confidence only in `-V`.
8. **D51 — Committed fixtures staged under producer-true names**; `logs/` is gitignored and is not a test substrate.
9. **D52 — Content probes**: out-of-range component (decisive), monotonicity (graded), filename-date cross-check (breaks the ≤12-day ceiling for date-rolled files); silence is inconclusive; #385's guard and diagnostic ship here.

Process: #384 had been left `on hold` with a prose-only "blocked by #58" after #58 closed — recorded in CLAUDE.md (2026-08-22 observation; per-feature workflow step 9). Recorded directly on `release/0.17.0` (planning artifact; architect instruction 2026-08-22).

### 2026-08-21: #385 — same line shape, divergent data quality; fix deferred to the provenance mechanism

Investigation of #385 (fatal `Month out of range` on Integration Runtime logs) established that the line is recognized correctly and the *data* is malformed at the producer: the Integration Runtime's logback encoder is `yyyy-dd-MM`, systematically, across all ten runtime sessions in the committed fixture. The winning entry is `mt10` / `connection_server_standard`, whose dates are correct ISO — the two products emit byte-identical line shapes.

Architect decisions:

1. **No warning-plus-guard mitigation ships.** The run is left to die. Guarding `timegm()` would stop the crash on the 40.7% of lines carrying a day > 12 while leaving the remaining 59.3% silently transposed by up to eleven months — trading a loud failure for a quiet wrong answer. The stderr diagnostic for non-ISO-compatible dates remains part of the complete fix, not a standalone release.
2. **The fix is two producer-specific formats, gated on file-level provenance.** #385 is `blocked_by` #384 and `status: on hold`. Once filename provenance evidence exists, the ambiguous entry splits into a Connection Server format (`yyyy-MM-dd`) and an Integration Runtime format (`yyyy-dd-MM`).
3. **The general problem is umbrella-level, not #385's.** One declared pattern can serve multiple applications whose data consistency and quality differ; the registry needs expression, detection, and adaptation for that class. Recorded as Architectural Challenge 6 above, together with the detectability ceiling (dates ≤ the 12th are valid under both orderings, so contradiction is unavailable for a large share of real files).
4. **Confidence must scale with consequence.** #384's open question on filename-evidence confidence is sharpened: provenance that changes how a field is *interpreted* demands more than provenance that selects carried metadata. Recorded on #384.

### 2026-08-21: Drop 1 (#58) implementation — D39–D40 (scan-sub codegen and ordering, architect-locked mid-drop)

Two decisions were locked during S5 implementation when measurement invalidated the planned per-entry-closure shape (finding F9: the P2 prototype's baseline was itself a sub, hiding the closure machinery's real cost) and promotion-driven regex recompilation surfaced (+79% on interleaved streams). Full statements, evidence, and the two rejected interim variants in `features/58-format-registry-staged-detection.md`:

1. **D39 — Single generated scan sub.** All entries' guards, literal patterns, extraction bodies, and inline timestamp handling are spliced into ONE eval'd sub per scan order — zero per-line sub calls, write-direct into file-scoped record lexicals. Promotion code is emitted only into blocks whose generation-time position is not already optimal, so steady state runs no promotion logic at all.
2. **D40 — All orders precompiled up front; order-signature cache; true recency ordering.** Every pattern sub is generated at startup (~tens of ms, paid once before the loop — never inside it); the static order plus all 13 first-promotion orders are eagerly compiled, and deeper recency permutations compile once on first occurrence keyed by an order signature. Ordering is true most-recently-used with pinned-ancestor closures (D26 upheld): files alternating between two or three formats scan only those formats. Two interim variants (regeneration throttle; per-front canonical order with static tail) were rejected — the second violated D26's locked recency semantics and is recorded with the process lesson attached.

### 2026-08-20: Drop 1 (#58) implementation planning — D35–D38, D12 true-up

Implementation planning against the locked prototype decisions closed the three remaining in-drop questions and re-cut R4's user-facing surface. Full decision text in `features/58-format-registry-staged-detection.md` §§ D35–D38; umbrella-level summary:

1. **D35 — Q3 resolved: no inheritance mechanism; sparse-override.** A user entry naming a built-in starts from its spec, overrides only stated fields, and revalidates through the D24 gates. Same-pattern variants cannot coexist under the D26 constrained scan, so "like tomcat9 but µs" is inherently an override; a different pattern is a new format. Formats carry default configuration only — the R5 runtime precedence chain sits above.
2. **D36 — Q5 resolved: no strict mode in Drop 1.** Permissive behavior byte-identical; visibility via scan telemetry.
3. **D37 — R4 re-scoped; D12 true-up.** D12's "users get custom formats via YAML" intent stands but is re-sequenced: Drop 1 lands the registry schema, data model, and D24 validation machinery in code (exercised by built-ins at every startup); the YAML loader, config folder/file convention, CLI surface, and dependency move to a follow-up issue natively blocked by #58. When that feature lands, YAML::PP is a **hard** dependency (`use`, not lazy) — the capability and the module ship together. Rationale: users have no custom-format access today and do not need it immediately; getting the core mechanisms active and tested outranks configuration access, and the config-file mechanism deserves its own design rather than an ad-hoc option.
4. **D38 — Detection-window sizing split out.** The D30 two-phase-store structure ships in Drop 1 at window size 0 (hidden test flag for N>0; side-effect parity at N=1000 proven in-drop); deriving the appropriate N is a follow-up prototyping issue enhancing the P7 battery — closing the gap that the prototype measured the window mechanism but never derived its value.

### 2026-08-20: Drop 1 (#58) research + prototype phase complete — D24–D34

The mandatory research → prototype → decide cycle for Drop 1 ran to completion: internet research (F1–F8), application-code audit (A1–A11), and nine measured prototype findings (P1–P9), all recorded in full in `features/58-format-registry-staged-detection.md` — the owning record for the detail; this entry is the umbrella-level summary. All measurements ramped 1k → 10k → 100k → 1m fixtures with medians and ranges; correctness criterion throughout was per-line classification/extraction parity with today's cascade.

Decisions locked 2026-08-20 (full statements and evidence tables in the #58 feature doc):

1. **D24 — User-pattern anchoring + load-time validation**: auto-`^`-anchor, mandatory executable samples, lint pass, cross-shadowing test.
2. **D25 — Message-metric probes as registry-declared, closure-compiled data**; probe *scoping* is #60's.
3. **D26 — Detection ordering refines D20 to pinned-closure MTF**: unconstrained MTF measurably misclassifies (one stray catch-all-shaped line flips whole streams); the winner promotes together with its ancestor closure, constraints *derived at load* from sample cross-testing. Tier-MTF rejected. The scan loop must stay as lean as today's.
4. **D27 — Extraction dispatch: load-time codegen closures, fixed-order list-return** (+0.12–0.17 s/M-line tax); generic interpreter (+2.2–2.7 s/M) and hashref records rejected.
5. **D28 — Cheap superset guards are per-entry, opt-in, measured data**: shipped on the three access-family siblings (−1.29 s/M access lines, −31%); blanket guards are a measured net loss; atomic heads subsumed.
6. **D29 — Registry container: array-of-arrayrefs with constant indices**; build 161–188 µs, 73–82 KB — startup non-factors.
7. **D30 — Detection window (D17): two-phase-store** — free at scale (≤ +54 ns/line), sized by detection needs not throughput.
8. **D31 — Time contract compiled to per-layout parse closures** with exact parity; per-second `%timestamp_cache` semantics unchanged this drop (sparse-stream unbounded growth — 100.7 MB/1M GC lines — filed as #383).
9. **D32 — CSV stays a per-file stage outside the scan array** with a non-scanned `csv` registry entry (the matcher-kind-in-array shape is structurally inexpressible under pinned promotion).
10. **D33 — Probes: per-probe `index()` guards behind one `=` superset gate**, closure-compiled; fusion into the recognition regex rejected on measurement (+1.09 s/M miss path).
11. **D34 — No no-match pre-filter in Drop 1** (resolves D20's open pre-filter point): the no-match population is the *cheapest* class, not the most expensive.

Composed effect on the #369 workload (classification, 1m access fixture): 4.32 s/M static → 2.94 s/M under D26+D28 (−32%), the failed-attempt cost class removed structurally. Final proof remains the merge-gate `TIMING parse/read_files` probe. Side discoveries filed to backlog during the phase: #382 (GC Pause Remark/Cleanup unmatched), #383 (timestamp-cache growth).

### 2026-07-15: 0.17.0 scheduling session — true-up and target reframe

Implementation scheduled for release 0.17.0 as a merge train of section drops on `release/0.17.0`, each merged back through the full regression gate. Decisions reached:

1. **D15 — Memory design target reframed.** The rewrite does not pursue minimal memory footprint. Two distinct obligations replace it: (a) **eliminate waste** — never store what has no remaining consumer (aligned with the shipped demand registry #305 and the #349 demand contract); (b) **spend available memory on fidelity** — raw values are exact, a histogram only ever approximates, so representation degradation is purely a memory-policy decision. Persistent per-key representation policy (raw vs partition, head/body split, promotion thresholds) is owned by the **#2 memory-ceiling umbrella and is NOT a dependency of this rewrite** — the pipeline feeds whatever message-stats data model is in effect. Phase 2's per-bucket holding is transient working state: structurally bounded, freed at bucket close, visible in `-V`/`-mem`. Grounding: the #323 investigation record in `features/189-histogram-bin-counter-primitives.md` (both directions).
2. **D16 — Phase 4 (#61) out of 0.17.0.** The 0.17.0 scope is Phases 1–3 (#180 → #58 → #57 → #59 → #60). Derived metrics and the expression parser (#55) are a release-sized feature sitting on top of the rewritten engine, deferred to a later release.
3. **D17 — #181 reframed to architecture guidance.** Perf evidence (2026-07-10 note on #181) shows file I/O is not a bottleneck; no full reader/processor decoupling is built. Phase 1's D13 detect-fallback needs only a minimal detection window: hold the first ~N lines during format detection, per-line re-detect on cache-miss. That same window is the future substrate for #17's unit-detection sampling (~100 lines) when no prior-run knowledge exists — the design tie recorded on #181 and #17 (2026-07-15 comments).
4. **D18 — Unit scope boundary.** No unit auto-detection and no speculative unit tracking inside the rewrite. The registry's contribution is declarative: format definitions carry known units as metadata. Knowledge precedence: `-du` override → format-carried unit → index read-back (#179) → sample-based auto-detection (#17, follow-on).
5. **D19 — #187/#189 outcome absorbed.** #34, #41, #51 are closed (superseded/resolved under the unified bin-counter contract); Phase 2 inherits one already-unified binning/memory model instead of reconciling three. #179 shipped with a narrowed role (detect-stage hints; no longer load-bearing for bounds pre-seed).

6. **D21 — Phase 2 out of 0.17.0; Phases 2+4 ship together (added same session, drop-walkthrough dialog).** Phase 2's deferred-per-bucket model exists *for* Phase 4's inter-line derived metrics (2026-02-06 decision 2: "the streaming single-pass model cannot support inter-line derived metrics"). With Phase 4 deferred (D16), shipping Phase 2 alone would build holding machinery a release ahead of its only consumer — while v0.15.x–v0.16.0's streaming bin-mode accumulation has already absorbed part of its secondary justification (inline stats finalization). Re-cut: **0.17.0 = #180 → #58 → #60** (Drops 0/1/2); **#57, #59, #61, #55 form the next release** as one coherent bucketed-computation + derived-metrics line. Native dependencies re-cut accordingly (#60 now blocked by #58, not #59).
7. **D22 — Account-at-read-time locked; temporal interpolation not planned (added same session).** The universal time-attribution semantic is: a line's contribution lands in the bucket of the line's timestamp — for UDM deltas exactly as for durations (a one-hour request lands in its completion bucket). Inter-line state retains last value + **exact timestamp** per (metric × log key), so `rate()` divides by true elapsed time and magnitudes stay correct; placement is the read bucket. Interpolation (linear spreading across intervening buckets) rejected as a planned capability — it fabricates smoothness, splits the tool's time semantics, and is the sole consumer forcing finalized buckets to be reopenable (collapsing that requirement radically simplifies Phase 2's window: buckets close aggressively and permanently). Spec'd for the record as a **general capability across all metrics** (counters *and* durations — any index of elapsed activity), not UDM-specific, in **#370, open and labeled not planned**. If ever revisited: per-metric opt-in (linear / last-bucket-only / none), never a default change. Section 7b and Risk 3 updated to match.
8. **D20 — Move-to-front detection scan (added same session, drop-walkthrough dialog).** Phase 1's detection structure is an ordered array of compiled `qr//` patterns (one per registry entry) scanned front-to-back per line, with the matching entry **moved to the front**. Detection is a change-point workload (one format for millions of consecutive lines, changing at file boundaries), so MTF converges in one match per change point and delivers the original "detect once per file" intent globally with no per-file reset bookkeeping; steady-state per-line cost is one successful compiled match at index 0. Bubble-up-one (the `docs/regex-best-practices.md` sketch, proven in `match_consolidation_patterns()`) was argued and rejected for this use: its noise-damping pays off at high pattern counts with genuinely interleaved traffic (the consolidation problem), not ~13 patterns over near-constant streams. Stray-line worst case under MTF is one failed match on the next line. Lines matching nothing (continuation lines) pay the full scan under any ordering — a possible pre-filter is an in-drop design point, independent of ordering policy. The matched entry IS the registry entry: extraction runs from its definition, replacing the `match_type` integer. Supersedes the "detect once per file, cache the format" wording (2026-02) in earlier issue drafts.

7. **D23 — Two-tier declarative paired-event detection; synthetic-record contract; registry time contract (2026-07-16, follow-on session).** A widespread log pattern emits separate start/end lines whose duration exists on no single line (#218 WGM is the motivating consumer). Decisions: (a) pairing is NOT a format-wide property — a format entry carries an *optional* array of pair declarations, and only lines matching a declaration's sub-determination (declarative, never heuristic; `index()` literal pre-check first) enter the pair path; all other lines take the zero-overhead single-line path, so memory scales with concurrently-outstanding starts, never log size. (b) A pair declaration = two independent patterns (asymmetry inherent) + correlation binding by capture name + log-key composition template over both sides' captures + metric mapping onto canonical fields. (c) **Synthetic-record contract:** the merged result is a standard parse-stage record (completion-bucket timestamp per D22) — the pair machinery is a second producer of parse-stage records and nothing downstream ever special-cases it. (d) #58 reserves and load-validates the `event_pairs` schema slot without consuming it; the capability itself is #372 (Phase 2+4 release, blocked by #58 and #59; #218 blocked by #372 and #58). *Specification home and current dependency graph: D58 (2026-08-23).* (e) The registry entry's **time contract** is three-part and declarative: layout, precision (s/ms/µs), and timezone semantics (offset present → honor; absent-UTC → pin UTC; absent-local → pin local, resolved through the configuration cascade) — consumers #155 (UTC normalization) and #154 (rendering offset).

Branch: `23-log-format-registry` (documentation true-up; issue walkthrough and enhancement in the same session). D23 recorded directly on `release/0.17.0` (architect-granted exception for planning documents, 2026-07-16).

### 2026-08-23: Paired-event metrics — specification home and consumer chain

1. **D58 — Paired-event metrics are an extension of the metric model, specified on #60/#61.** (a) The pairing capability (#372) broadens the existing metric structures — the registry's per-format `message_metrics` and the `-udm` command line — so that a metric may be defined across a matched start/end line pair; it introduces neither a separate metric vocabulary nor a separate state store. (b) Research, requirements and design live with Phase 4 (#61 — the inter-line state substrate: declared grouping key, a one-shot consume-at-end lifecycle beside the rolling delta state, max-gap policy, canonical-field targeting and its disclosure obligation, all already required there by #401) and Phase 3 (#60 — derived/paired metrics as demand participants; per-format scoping of message metrics, handed to #60 by D25). #372 links to both and carries the pairing deliverable; #218 links to #372. (c) #218's order of work: first ensure the generic structures cover the WGM requirement; then the WGM pair metrics are configuration only, in the metrics section of the `windchill_workgroup_manager` entry. The WGM line format itself was delivered by #395 (2026-08-23). (d) D23 stands for its detection mechanics (declarative sub-determination with an `index()` pre-check, the synthetic-record contract, completion-bucket timestamp per D22); its "metric mapping onto canonical fields" is realised through the message-metrics vocabulary rather than a mapping of its own. Open for #61's research: whether a pair metric is a kind of message-metric declaration, and whether `-udm` can express the same.

Dependency graph after this session: #372 ← #61 (added), #372 ← #59 (kept; #61 ← #59 already), #218 ← #372 (kept); the closed-#58 edges on #372 and #218 dropped.

### 2026-05-09: Pre-rewrite planning session — staging primitives and sequencing

After ~4 months gap, picked up #23 to refresh requirements and structure work breakdown. Significant work shipped in the interim (#46 index file, #22 UDM with simple delta, #96 fuzzy consolidation S1-S5 pipeline) materially changes the planning picture. Decisions reached:

1. **D5 — Sequencing.** Pre-requisite "staging primitives" land on separate branches against today's architecture *before* #23 implementation begins. Shrinks the rewrite's surface area; when the engine rewrite begins, it migrates between named primitives rather than inventing them. New issues: #179 (index read-back), #180 (named pipeline stages), #181 (buffered read pipeline). Existing issues #41/#34/#51 updated with Phase 2 alignment requirements.
2. **D6/D7 — Index read-back (#179).** Read silently when entry is fresh (file_size + mtime match). Pre-seed heatmap/histogram bounds and timestamp range. **At end of execution, compare live values to index; on drift, refresh the index entry atomically.** No new CLI flag in v1. Drift detection is a hard requirement — without it, next-run boundaries are silently wrong.
3. **D8 — Named pipeline stages (#180).** Coarse 5-stage shape: detect / parse / accumulate / finalize / render. Light-touch refactor that names the implicit pipeline; no intra-stage restructuring. Phase 1 (#58) inserts the format registry into `detect`; Phase 2 (#59) adds per-bucket lifecycle hooks inside `finalize`.
4. **D9 — Heatmap/histogram pre-work (#41/#34/#51).** Land independently before Phase 2. Each existing issue updated with a "Phase 2 Alignment Requirements" comment specifying: reusable binning subroutine, bounds as parameters, structures live inside the named stages from #180, structures compose across the three issues. When Phase 2 begins, it inherits a coherent memory model — not three competing ones.
5. **D10 — #22 simple delta migration.** Phase 4 silently replaces the global last-value-only `delta()`/`idelta()` (`ltl:3933-3946`) with per-message-identity delta. Same `-udm` syntax, correct results on interleaved messages. Documented as a behavior fix in release notes.
6. **D11 — Architectural template.** New section in this file ("Architectural Template: Staged Pipeline") references `docs/staged-processing-pipeline.md` as the canonical pattern Phase 2 must reuse. Lists specific subs from #96 that Phase 4 will import directly (similarity engine for message identity).
7. **D12 — YAML for the format-registry config file** (Open Question 1 resolved).
8. **D13 — Multi-format files** (Open Question 4 resolved): detect once, fall back to per-line on low-confidence; skipped/non-matching lines must be re-testable. Requires the buffered-read substrate from #181.
9. **D14 — Sliding-window meaning** (Open Question 6 resolved): tracks transaction-spanning events (start in bucket 1, end in bucket 5+), not clock skew. Window auto-adjusts at runtime; power-user CLI override for tuning.

Branch: `23-format-registry-prep`. Documentation-and-issue-tracking only — no code changes.

### 2026-02-06: Derived Metrics and Processing Model

Discussion established that derived metrics require a fundamental change to the processing pipeline. Key decisions:

1. **Two types of derived metrics**: Intra-line (arithmetic on same-line fields) and inter-line (stateful functions like `delta()`, `idelta()` across time). Both must support dependency ordering.
2. **Processing model shifts to deferred-per-bucket**: The streaming single-pass model cannot support inter-line derived metrics because they need the full picture of a bucket (all messages grouped by identity) before calculations can run. This changes the core pipeline for everything, not just derived metrics.
3. **Sliding window memory model**: Raw data is held only for active buckets. Statistics, heatmaps, and derived metrics are computed inline as each bucket is finalized, then raw data is freed. This should reduce peak memory vs. current model.
4. **Temporal interpolation for sparse counters**: When counter readings are infrequent relative to bucket size, deltas are spread evenly across intervening buckets rather than creating spikes.
5. **Metric visibility flags apply to all metrics** (raw and derived), not just derived. This decouples collection from display.
6. **Fuzzy matching engine needed**: Inter-line metrics must operate on lines grouped by message identity within buckets, not globally. This engine should be shared with the "group-similar" feature.
7. **Reusable metric definitions**: Derived metrics can be defined once and assigned to multiple match patterns.
8. **Unit system is a cross-cutting requirement**: Every metric (raw or derived) must carry a declared unit type. No auto-detection — users specify units explicitly. Existing conversion/formatting functions (`convert_duration_to_ms`, `convert_bytes`, `format_time`, `format_bytes`, `format_number`) provide a solid foundation but need auditing for gaps.
9. **Issue #22 (user-defined metrics) sequences before #23**: It provides a lighter-weight proving ground for custom metric extraction, unit handling, and data model integration using the existing architecture, while following patterns compatible with the future registry design. Issue #22 also includes a simple `delta()`/`idelta()` implementation (last-value-only, no per-message-identity tracking, no temporal interpolation) that serves as a precursor to Phase 4's full inter-line engine. The known limitations of #22's delta (interleaved messages produce incorrect deltas, no look-back window) are explicitly what Phase 4 solves.

## Related

### Prerequisites (status as of 2026-07-15)
- **Issue #179**: Index read-back — **COMPLETE** (shipped v0.15.x); narrowed role: detect-stage hints + unit knowledge precedence, not bounds pre-seed
- **Issue #180**: Name the implicit pipeline stages — **COMPLETE** (merged 2026-08-20, PR #380), Drop 0 of the 0.17.0 merge train
- **Issue #181**: Buffered read pipeline — **REFRAMED (D17)**: architecture guidance only; minimal detection window replaces full decoupling
- **Issue #41**: Align heatmap with histogram binning — **CLOSED**, superseded by #187/#189
- **Issue #34**: Two-pass streaming memory mode — **CLOSED**, resolved as consumer migration under #187/#189
- **Issue #51**: Highlight-data memory optimization — **CLOSED**, resolved under #187/#189

### Already-shipped foundations
- Issue #46: Index file (`ltl-index.csv`) — provides the data #179 will consume
- Issue #22: User-defined metrics with simple delta — Phase 4 replaces its global delta with per-identity
- Issue #54: Fuzzy matching engine research — **COMPLETE**, resolved by #96
- Issue #96: Fuzzy message consolidation — **SHIPPED** (v0.13.0), provides the similarity engine for Phase 4 message identity and the architectural template (S1-S5 pipeline) for Phase 2
- Issues #187/#189: Unified histogram bin-counter primitives — **SHIPPED** (v0.15.x/v0.16.0), the single binning/percentile substrate Phase 2 inherits; closed #34/#41/#51
- Issue #305: Statistics demand registry — **SHIPPED** (v0.16.0), demand-gated capture/compute/storage; the proving ground Phase 3 (#60) generalizes (see also #349 demand contract)

### Other related
- Issue #17: Duration unit autodetection — the declarative path (format-carried units) ships with Phase 1; the sampling fallback stays #17's own follow-on (D18)
- Issue #369: Access-log read-phase regression (v0.16.0) — fixed by Phase 1's staged detection (removes the per-line sequential pattern cascade)
- Issue #2: Memory ceiling umbrella — owns persistent storage/representation policy; explicitly NOT a dependency of this rewrite (D15)
- Issue #44: Source file heuristics — depends on #179 (index read-back)
- Issue #48: Performance profiling (provided evidence for processing model changes)

### Per-drop feature docs (0.17.0 merge train — repo-side source of truth per drop)
- features/180-named-pipeline-stages.md — Drop 0 (#180)
- features/58-format-registry-staged-detection.md — Drop 1 (#58)
- *(no file)* — Drop 1.5 (#384) is recorded in this document, § "Drop 1.5 — #384"
- features/395-wgm-client-log-format.md — #395: first format added on the Drop 1.5 registry (single entry with a multi-stem filename family; msgtype → category mapping; D54–D56)
- features/60-metric-visibility-demand-map.md — Drop 2 (#60)
- features/396-windchill-method-server-log4j-format.md — Windchill Method Server log4j entry (`mt17`, #396): first entry declaring filename evidence on the Drop 1.5 mechanism after its landing; adds the `date_n` index form (D55)

### Documentation
- features/duration-unit-autodetection.md
- features/fuzzy-message-consolidation.md
- features/index-file.md
- features/user-defined-metrics.md
- docs/similarity-engine-best-practices.md
- docs/staged-processing-pipeline.md
- docs/fuzzy-consolidation-lessons-learned.md
- docs/perl-performance-optimization.md
- docs/regex-best-practices.md
