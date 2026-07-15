# Feature Requirements: Log Format Registry

## Status

- **Last reviewed:** 2026-07-15
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
2. How should format priority/ordering work when multiple patterns could match? *— Phase 1 (#58) design decision.*
3. Should format definitions support inheritance (e.g., "like tomcat9 but with microseconds")? *— Phase 1 (#58) design decision.*
4. ~~How to handle logs that switch formats mid-file?~~ **RESOLVED 2026-05-09 (D13): Detect once, fall back to per-line on low-confidence. Skipped/non-matching lines must be re-testable.** This requires the buffered-read architecture filed as #181 — the file reader pushes lines into a bounded buffer; the processor pulls and may push lines back for re-testing against alternate patterns.
5. Should there be a "strict mode" that fails on unrecognized formats vs. current permissive behavior? *— Phase 1 (#58) design decision.*

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
| #180 | Name the implicit pipeline stages (detect/parse/accumulate/finalize/render) | **OPEN — Drop 0 of the 0.17.0 merge train.** Phase 1 inserts the registry into the `detect` stage; Phase 2 adds per-bucket lifecycle inside `finalize`. |
| #181 | Decouple file I/O from processing via a buffered read pipeline | **REFRAMED (2026-07-10 / 2026-07-15, D17) — architecture guidance, not a deliverable.** Perf testing showed file I/O is not a bottleneck. Phase 1 needs only a minimal detection window (hold the first ~N lines during format detection, per-line re-detect on cache-miss); that window is also the future substrate for #17's unit sampling. No full reader/processor decoupling is built. |
| ~~#41~~ | ~~Heatmap/histogram unified binning~~ | **CLOSED — superseded by #187/#189**: heatmap and histogram run the same unified bin-counter primitives at the same precision. |
| ~~#34~~ | ~~Memory-optimized two-pass streaming~~ | **CLOSED — resolved by #187/#189**: reframed as the consumer migration onto the unified primitive contract and delivered there. |
| ~~#51~~ | ~~Highlight-data memory optimization~~ | **CLOSED — resolved under the #187/#189 contract** (highlight-subset consumer migration). |
| #55 | Expression parser research & build | **OPEN — Phase 4 prerequisite; out of 0.17.0 scope** (deferred with Phase 4). Standalone component for derived metric arithmetic. |
| #57 | Bucket data structure prototype | **OPEN — Phase 2 gate (Drop 2a), rescoped 2026-07-15.** Per-entry cost constants are already measured (#323/#306); the prototype's remaining question is the per-bucket *transient* holding cost and window shape under the sliding window. See D15. |

### Phases (re-cut 2026-07-15, D21 — 0.17.0 merge train)
| Issue | Phase | Drop | Title | Depends On | 0.17.0 |
|-------|-------|------|-------|------------|--------|
| #180 | — | 0 | Named pipeline stages (zero behavioral change) | — | **In** |
| #58 | 1 | 1 | Format registry and staged detection (fixes #369; unblocks #17's declarative path) | #180 | **In** |
| #60 | 3 | 2 | Configurable metric visibility and purpose | #58 | **In** |
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

Branch: `23-log-format-registry` (documentation true-up; issue walkthrough and enhancement in the same session).

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
- **Issue #180**: Name the implicit pipeline stages — **OPEN**, Drop 0 of the 0.17.0 merge train
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
