# Fuzzy Message Consolidation — Requirements

**GitHub Issue:** #96
**Status:** Requirements Definition
**Blocks:** #97 (hierarchical message roll-up grouping)

## Problem Statement

### Current Behavior

ltl stores each unique log message as a separate entry in `%log_messages{$category}{$log_key}`. The `$log_key` is built by concatenating metadata (log level, thread, object) with the message text, truncated to screen width or a hardcoded limit for CSV output. Messages are grouped only when their keys are character-for-character identical.

### Why This Is a Problem

Log messages frequently contain variable parameters — user IDs, UUIDs, session tokens, IP addresses, endpoint paths, locale prefixes, query strings, entity names, order references, device identifiers, and more. Two messages that represent the same operation with different parameters produce different keys:

```
[200] [http-thread-1] [UserService] User alice logged in from 10.0.0.1
[200] [http-thread-2] [UserService] User bob logged in from 10.0.0.2
[200] [http-thread-1] [UserService] User alexandrina logged in from 192.168.1.50
```

These create 3 separate entries in `%log_messages` despite being the same message pattern. In large log files with thousands of users, endpoints, or sessions, this produces thousands of unique keys that are really variations of a handful of patterns.

Consequences:
- **Memory**: each unique key carries its own statistics, duration arrays, and hash overhead
- **Noisy output**: the summary table is dominated by repetitive variations rather than showing true top-N patterns
- **Misleading statistics**: the impact of a pattern is fragmented across hundreds of entries rather than aggregated

### Existing Mitigation

The codebase has `$mask_uuid` (line 87) — a temporary flag to replace UUIDs with hash characters. This is a primitive, single-pattern version of the capability needed. It demonstrates the need but doesn't generalize.

## Goals

1. **Detect similar messages** using n-gram based similarity scoring, producing a 0.0–1.0 similarity score
2. **Consolidate similar messages** by merging their entries into a single canonical form with aggregated statistics
3. **Tunable threshold** — a single user-facing parameter controlling consolidation aggressiveness
4. **Batch processing** — consolidation runs in triggered passes, not on every incoming log line
5. **Multi-pass capable** — patterns can become more general as new data arrives; earlier groupings may be re-consolidated
6. **Bounded resource usage** — message length cap for n-gram indexing; consolidation reduces memory pressure rather than adding to it
7. **Backwards-compatible** — when consolidation is not active, behavior is identical to today
8. **Foundation for #97** — the similarity engine, canonical form generation, and stats merging must be reusable for hierarchical grouping

## Non-Goals

- **Per-line similarity checking** — checking every incoming line against existing patterns during ingestion is not the approach; consolidation is batch-based
- **Hierarchical display** — that is #97; this issue focuses on the engine and flat consolidation
- **Regex-based pattern extraction** — while complementary (and `$mask_uuid` exists), this feature is about fuzzy similarity, not predefined substitution rules
- **Guaranteed perfect grouping** — fuzzy matching is inherently approximate; the threshold gives users control over the trade-off

## Design Decisions

### DD-01: N-gram Indexing for Candidate Matching

**Decision:** Use trigram (3-character chunk) indexing per category to identify candidate matches for similarity scoring.

**Rationale:** Binary search is not applicable to string similarity (similarity is not orderable). Naive O(n) comparison against every known pattern is too slow. N-gram indexing provides sub-linear candidate identification:

1. Break message into overlapping 3-character chunks
2. Look up each chunk in the category-level index to find clusters sharing that chunk
3. Candidates sharing the most chunks are scored for actual similarity
4. Only a small number of candidates need full similarity calculation

**Trade-offs:**
- Index memory grows with cluster count and message length — bounded by message length cap
- Trigrams balance granularity (bigrams too common, 4-grams too sparse for short messages)

### DD-02: Batch Consolidation with Threshold Trigger

**Decision:** Consolidation runs as a batch pass when unique message count within a category exceeds a configurable threshold, not on each incoming log line.

**Rationale:**
- A single log line has 0% known similarity to anything — checking on arrival is wasteful
- Batch processing amortizes the cost across many messages
- Allows the similarity landscape to develop before making grouping decisions
- Trigger threshold can be internal/dynamic (based on message count or memory pressure)

**Multi-pass behavior:** After a consolidation pass reduces unique count, accumulation continues. If count exceeds threshold again, another pass runs. Each pass may discover new similarities as the dataset grows and patterns that were initially constant (e.g., a single user name) become variable.

### DD-03: One-Way Generalization

**Decision:** Consolidation only generalizes, never specializes. Groups merge but never split.

**Rationale:** As more data arrives, patterns can only become more variable, not less. A message field that appeared constant may become variable when new data introduces variation. There is no scenario where a generalized pattern should become more specific.

### DD-04: Canonical Form with Wildcards

**Decision:** Consolidated messages display a canonical form where variable parts are replaced with `*` wildcards. An optional mode preserves parameter length using `#` characters (e.g., `#####` for a 5-character parameter).

**Default:** `*` (single wildcard regardless of original length), since variable-length parameters are the common case and `*` produces cleaner, more readable output.

**Optional:** Length-preserving `#` mode for cases where parameter length carries diagnostic meaning.

### DD-05: Message Length Cap for Indexing

**Decision:** N-gram indexing operates on a truncated message, capped at a few hundred characters.

**Rationale:** Log lines can be arbitrarily long (stack traces, serialized objects, large payloads). Indexing beyond the meaningful prefix wastes memory and CPU without improving similarity detection. The existing `$log_key` truncation provides a natural model — similarity detection operates on the same truncated form used for display.

### DD-06: Stats Merging at Consolidation Time

**Decision:** When entries are merged, statistics accumulate cleanly:
- `occurrences`: sum
- `total_duration`, `total_bytes`: sum
- `min`: min of the two mins
- `max`: max of the two maxes
- `durations` array: concatenate
- `count_sum`, `count_occurrences`: sum
- `count_min`: min of the two mins
- `count_max`: max of the two maxes
- UDM fields: same pattern (sum sums, min mins, max maxes, sum occurrences)

**Rationale:** During `read_and_process_logs()`, ltl accumulates raw data only — sums, min/max, and duration arrays. Percentile and derived statistics are calculated later in `calculate_all_statistics()`. Merging at the raw data level preserves full accuracy with no information loss.

## Data Structure

### Cluster Model

Extends `%log_messages{$category}` with a cluster concept:

```
%log_messages{$category}{$cluster_key} = {
    canonical      => "User * logged in from *",    # generalized display form
    ngram_index    => { ... },                       # trigram → frequency mapping
    occurrences    => 5000,                          # aggregate count
    total_duration => ...,                           # aggregate
    total_bytes    => ...,                           # aggregate
    durations      => [...],                         # concatenated raw values
    min            => ...,                           # min across all merged entries
    max            => ...,                           # max across all merged entries
    # ... other existing fields ...
    children       => {                              # optional, for #97 compatibility
        $original_key_1 => { ... },
        $original_key_2 => { ... },
    }
};
```

**Category-level index:**

```
%ngram_index{$category} = {
    "Use" => { $cluster_key_1 => 1, $cluster_key_3 => 1 },
    "ser" => { $cluster_key_1 => 1 },
    " al" => { $cluster_key_1 => 1 },
    ...
};
```

### Backwards Compatibility

When consolidation has not been triggered:
- Each message is its own cluster
- `$cluster_key` equals `$log_key`
- `canonical` is not set (or equals the key)
- `children` is empty or absent
- All existing code paths work unchanged

### Two-Level Consolidation

1. **Within a cluster (children):** When child count within a cluster grows excessive, children can be consolidated — aggregate their stats into the parent and discard individual child entries. This is the memory relief mechanism.

2. **Across clusters (parents):** During a batch consolidation pass, existing cluster canonical forms are compared for similarity. Similar clusters merge — stats aggregate, canonical form generalizes further, n-gram index updates.

## Configuration

| Option | Type | Description |
|--------|------|-------------|
| `--group-similar` | Flag | Required to enable feature. Activates n-gram similarity consolidation. Will become default behavior once feature is hardened and proven. |
| Similarity threshold | Float 0.0–1.0 | User-facing. Controls how similar messages must be to consolidate. Higher = stricter matching, fewer merges. Lower = more aggressive grouping. |
| Consolidation trigger | Integer | Internal/dynamic. Number of unique messages within a category before consolidation pass runs. May adapt based on memory pressure. |
| Length-preserving wildcards | Boolean | Optional. Use `###` instead of `*` for variable parts. |

Additional CLI option names TBD during implementation planning.

## Processing Flow

1. Log lines arrive and are processed as today — `$log_key` built, stored in `%log_messages`
2. Unique message count per category is tracked
3. When count exceeds consolidation trigger threshold:
   a. Build/update n-gram index for the category
   b. Score pairwise similarity between candidate clusters (using n-gram candidate narrowing)
   c. Merge clusters exceeding similarity threshold — aggregate stats, generalize canonical form
   d. Update n-gram index to reflect merged clusters
   e. Reset unique count tracking
4. Continue processing — repeat consolidation if threshold exceeded again
5. `calculate_all_statistics()` operates on the consolidated entries as normal

## Open Questions

1. **Similarity algorithm details**: Exact scoring formula from n-gram overlap (Jaccard coefficient? Dice coefficient? Custom?) — to be determined during prototyping
2. **Canonical form generation**: Algorithm for identifying which parts of two similar strings are variable vs constant — to be determined during prototyping
3. **CLI option naming**: Exact flag names for threshold and options
4. **Interaction with existing $mask_uuid**: Replace, complement, or leave independent?
5. **Performance benchmarks**: Consolidation pass timing on real log files with 5K, 10K, 50K unique messages
