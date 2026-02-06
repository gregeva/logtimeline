# Feature Requirements: Log Format Registry

## Overview

Refactor the core parsing architecture from an implicit match-type conditional chain to a data-driven format registry. This enables format-aware features, user-extensible format definitions, and improved processing performance.

## Background / Problem Statement

### Current Architecture

The main parsing loop in `read_and_process_logs()` uses a numbered match-type system:
- 12+ conditional branches, each with a regex pattern
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
# ... 10+ more patterns
```

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

Key implications:
- **Statistics and heatmaps computed inline**: These currently run as a batch after all reading is complete. In the new model, they must be computed per-bucket as each bucket is finalized, since the raw data will be freed afterward.
- **Sliding window**: Only the current bucket and a small number of trailing buckets are held in memory. Once a bucket is finalized and its raw data is no longer needed for inter-line calculations, it is freed.
- **Decoupled phases**: Reading/parsing is decoupled from calculation/statistics. This separation enables derived metrics that require the full picture of a bucket before processing.
- **Memory savings**: Despite holding raw data temporarily, the sliding window approach should reduce peak memory compared to today's model where all aggregated data structures persist until the end.

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
- **Per-message-identity state**: State must be tracked per message identity within a time bucket, not globally. See section 9 (Fuzzy Matching) for how identity is determined.
- **Temporal interpolation**: When counter readings are sparse relative to bucket size, deltas must be linearly interpolated across intervening buckets. For example, if a counter is reported every 5 minutes but buckets are 1 minute wide, the delta observed at the 5-minute mark is divided evenly across the 5 one-minute buckets, avoiding artificial spikes. Overlapping bucket boundaries must not cause double-counting.
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

**TODO**: Research fuzzy matching algorithms suitable for this use case and document options.

#### 10. Memory Tracking for State

Inter-line derived metrics require per-message-identity state to be maintained across bucket boundaries (the previous value for delta calculations). This state scales with the number of unique message identities multiplied by the number of inter-line metrics configured.

Requirements:
- Per-pattern state memory usage must be included in ltl's memory tracking and reporting
- Users must be able to see which patterns and metrics are consuming memory, so they can adjust their configuration if needed
- State should be documented clearly so users understand the memory implications of their derived metric configurations

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
1. What file format should user-defined formats use? (YAML, JSON, custom DSL)
2. How should format priority/ordering work when multiple patterns could match?
3. Should format definitions support inheritance (e.g., "like tomcat9 but with microseconds")?
4. How to handle logs that switch formats mid-file?
5. Should there be a "strict mode" that fails on unrecognized formats vs. current permissive behavior?

### Processing Model
6. How many trailing buckets should the sliding window retain? (Minimum needed for inter-line calculations, likely 1-2, but may depend on data sparsity)
7. How does the deferred-per-bucket model interact with the existing `-st`/`-et` time range filters?

### Derived Metrics
8. What is the configuration syntax for derived metric expressions? (Must support arithmetic with named fields, function calls like `delta()`, and dependency ordering)
9. Should there be a maximum staleness/time-gap for inter-line functions beyond which a delta is discarded rather than interpolated?
10. How should temporal interpolation handle non-uniform bucket boundaries or partial buckets at the start/end of a file?
11. What is the full set of inter-line functions to support? (Minimum: `delta`, `idelta`. Candidates: `rate`, `irate`, `increase`, others from Prometheus)

### Metric Visibility
12. How are visibility flags configured — per metric in the format definition, or as a separate overlay/profile?
13. Should there be default visibility presets (e.g., "full", "minimal", "csv-only")?

## Research Areas

### 1. Fuzzy Matching Algorithms
Message identity grouping (section 9) is a core dependency for inter-line derived metrics. We need to research:
- Existing algorithms for fuzzy string grouping (edit distance, token-based, n-gram)
- How monitoring platforms (Prometheus, Datadog, Splunk) handle metric identity in semi-structured logs
- Whether the same algorithm can serve both derived metric identity and the "group-similar" display feature, or whether these have conflicting requirements (one wants tight identity, the other wants loose grouping)
- Performance characteristics at scale — this runs per-line within each bucket

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

### 2. Memory Model Uncertainty — HIGH
The sliding window is expected to reduce peak memory, but this is unproven. If buckets contain many unique message identities with many metrics, the per-bucket raw data plus inter-line state could exceed current memory usage for certain workloads.
- **Mitigation**: Profile current memory usage to establish a baseline. Build a prototype of the bucket data structure and measure memory for representative log files before committing to the full implementation.

### 3. Temporal Interpolation Correctness — MEDIUM
Linear interpolation of counter deltas across buckets is an approximation. For bursty workloads, this smoothing may hide real patterns (a spike that happened in one minute gets spread across five). Users coming from Prometheus may expect different behavior.
- **Mitigation**: Research how other tools handle this and document the trade-offs. Consider making the interpolation strategy configurable (linear, last-bucket-only, none).

### 4. Fuzzy Matching is a Hard Problem — HIGH
Getting message identity right is critical for inter-line metrics to produce meaningful results. Too loose: different counters get mixed. Too tight: the same logical counter doesn't match itself across lines due to minor variations.
- **Mitigation**: This is a research-first item. Prototype and test against real log data before integrating. Make the matching configurable so users can tune it. Accept that some cases will require user filtering.

### 5. Scope Creep — HIGH
This issue now encompasses: format registry, staged detection, user extensibility, processing model redesign, derived metrics (two types), expression engine, fuzzy matching, metric visibility, memory model changes, and memory tracking enhancements. The risk of this becoming an unbounded rewrite is real.
- **Mitigation**: Strict phasing. Define clear phase boundaries with independent deliverables. Each phase must be usable on its own. Resist adding new requirements mid-phase.

### 6. Performance Regression — MEDIUM
The new model stores raw data per bucket before processing, which adds overhead compared to the current fire-and-forget streaming model. For simple use cases (no derived metrics), the new pipeline may be slower.
- **Mitigation**: Benchmark the new pipeline against the current one for simple cases (no derived metrics configured). If overhead is significant, consider a fast path that skips bucket accumulation when no features require it.

### 7. Expression Engine Security — LOW but non-trivial
If derived metric expressions are user-defined (via configuration files), and we evaluate them in Perl, there's a risk of code injection through crafted expressions.
- **Mitigation**: The expression engine must parse and evaluate a restricted grammar, never `eval()` raw user input. Use a proper parser.

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

- [ ] Research fuzzy matching algorithms for message identity grouping (section 9)
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

### Prerequisites
| Issue | Title | Purpose |
|-------|-------|---------|
| #53 | Automated test suite with golden files | Regression detection and performance tracking |
| #54 | Fuzzy matching engine research & prototype | Standalone component for message identity (needed by Phase 4) |
| #55 | Expression parser research & build | Standalone component for derived metric arithmetic (needed by Phase 4) |
| #56 | Memory baseline profiling | Establish current memory usage for comparison |
| #57 | Bucket data structure prototype | Validate sliding window feasibility (needed by Phase 2) |

### Phases
| Issue | Phase | Title | Depends On |
|-------|-------|-------|------------|
| #58 | 1 | Format registry and staged detection | #53 |
| #59 | 2 | Sliding window deferred-per-bucket processing | #58, #56, #57 |
| #60 | 3 | Configurable metric visibility and purpose | #59 |
| #61 | 4 | Derived metrics (intra-line and inter-line) | #60, #54, #55 |

### Phasing Principles
- Each phase must produce identical output for existing functionality (golden file comparison)
- No phase should be started before its prerequisites are complete
- Requirements will continue to be refined through design conversations — future sessions should revisit phasing as understanding deepens
- Resist adding new requirements mid-phase; capture them for the next phase or as new prerequisites

## GitHub Issue

[Issue #23: Log Format Registry - Refactor core parsing architecture](https://github.com/gregeva/logtimeline/issues/23)

## Design Decisions Log

### 2026-02-06: Derived Metrics and Processing Model

Discussion established that derived metrics require a fundamental change to the processing pipeline. Key decisions:

1. **Two types of derived metrics**: Intra-line (arithmetic on same-line fields) and inter-line (stateful functions like `delta()`, `idelta()` across time). Both must support dependency ordering.
2. **Processing model shifts to deferred-per-bucket**: The streaming single-pass model cannot support inter-line derived metrics because they need the full picture of a bucket (all messages grouped by identity) before calculations can run. This changes the core pipeline for everything, not just derived metrics.
3. **Sliding window memory model**: Raw data is held only for active buckets. Statistics, heatmaps, and derived metrics are computed inline as each bucket is finalized, then raw data is freed. This should reduce peak memory vs. current model.
4. **Temporal interpolation for sparse counters**: When counter readings are infrequent relative to bucket size, deltas are spread evenly across intervening buckets rather than creating spikes.
5. **Metric visibility flags apply to all metrics** (raw and derived), not just derived. This decouples collection from display.
6. **Fuzzy matching engine needed**: Inter-line metrics must operate on lines grouped by message identity within buckets, not globally. This engine should be shared with the "group-similar" feature.
7. **Reusable metric definitions**: Derived metrics can be defined once and assigned to multiple match patterns.

## Related

- Issue #17: Duration unit autodetection (blocked by this refactor)
- Issue #48: Performance profiling (provided evidence for processing model changes)
- features/duration-unit-autodetection.md
