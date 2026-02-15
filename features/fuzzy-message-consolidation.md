# Fuzzy Message Consolidation — Requirements

**GitHub Issue:** #96
**Status:** Requirements Definition
**Blocks:** #97 (hierarchical message roll-up grouping)

## Problem Statement

### Current Behavior

ltl stores each unique log message as a separate entry in `%log_messages{$category}{$log_key}`. The `$log_key` is built by concatenating metadata (log level, thread, object) with the `$message` string, truncated to screen width or a hardcoded limit for CSV output. Messages are grouped only when their keys are character-for-character identical.

### Why This Is a Problem

Log messages frequently contain variable parameters — user IDs, UUIDs, session tokens, IP addresses, endpoint paths, locale prefixes, query strings, entity names, order references, device identifiers, and more. Two messages that represent the same operation with different parameters produce different keys:

```
[200] [http-thread-1] [UserService] User alice logged in from 10.0.0.1
[200] [http-thread-2] [UserService] User bob logged in from 10.0.0.2
[200] [http-thread-1] [UserService] User alexandrina logged in from 192.168.1.50
```

These create 3 separate entries in `%log_messages` despite being the same message pattern. In large log files with thousands of users, endpoints, or sessions, this produces thousands of unique keys that are really variations of a handful of patterns.

The variable parts do not respect token boundaries. Real-world examples include:
- `PersistentSession2affb-ee87-0cac` — hex suffix varies but "PersistentSession" is constant
- `/Thingworx/Things/ABC1234-76C/Services/GetPropertyTime` — "ABC" is constant but "1234" varies
- `SUCCEEDED - WC_986556-0000 durationMs=?` — "WC_" is constant, numeric ID varies
- `/en-us/store/index.html` vs `/fr-fr/store/index.html` — locale prefix varies, path is constant

Previous prototyping attempts using token-based splitting (on spaces, `/`, `-`, etc.) failed because variable parts can appear within tokens. Character-level analysis is required.

Consequences:
- **Memory**: each unique key carries its own statistics, duration arrays, and hash overhead
- **Noisy output**: the summary table is dominated by repetitive variations rather than showing true top-N patterns
- **Misleading statistics**: the impact of a pattern is fragmented across hundreds of entries rather than aggregated

### Existing Mitigation

The codebase has `$mask_uuid` (line 87) — a temporary flag to replace UUIDs with hash characters. This is a primitive, single-pattern version of the capability needed. It demonstrates the need but doesn't generalize.

## Goals

1. **Detect similar messages** using n-gram based similarity scoring with Dice coefficient, producing a 0–100% similarity score
2. **Consolidate similar messages** by merging their entries into a single canonical form with aggregated statistics
3. **Tunable threshold** — a single user-facing parameter controlling consolidation aggressiveness (default 85%)
4. **Two-phase processing** — expensive pattern discovery runs in triggered batch passes; cheap pattern matching runs continuously on incoming messages
5. **Multi-pass capable** — patterns can become more general as new data arrives; earlier groupings may be re-consolidated
6. **Bounded resource usage** — message length cap for n-gram indexing; consolidation reduces memory pressure rather than adding to it
7. **Backwards-compatible** — when `--group-similar` is not specified, behavior is identical to today
8. **Foundation for #97** — the similarity engine, canonical form generation, and stats merging must be reusable for hierarchical grouping

## Non-Goals

- **Token-based splitting** — previous prototyping proved that splitting on delimiters (spaces, `/`, `-`) fails because variable parts don't respect token boundaries. This feature uses character-level analysis.
- **Hierarchical display** — that is #97; this issue focuses on the engine and flat consolidation
- **Regex-based pattern extraction** — while complementary (and `$mask_uuid` exists), this feature is about fuzzy similarity, not predefined substitution rules
- **Guaranteed perfect grouping** — fuzzy matching is inherently approximate; the threshold gives users control over the trade-off

## Design Decisions

### DD-01: N-gram Indexing with Dice Coefficient for Similarity Scoring

**Decision:** Use trigram (3-character chunk) indexing per category to identify candidate matches, scored using the Dice coefficient.

**N-gram indexing rationale:** Binary search is not applicable to string similarity (similarity is not orderable). Naive O(n) comparison against every known pattern is too slow. N-gram indexing provides sub-linear candidate identification:

1. Break message into overlapping 3-character chunks
2. Look up each chunk in the category-level index to find clusters sharing that chunk
3. Candidates sharing the most chunks are scored for actual similarity
4. Only a small number of candidates need full similarity calculation

**Dice coefficient:** The similarity score between two messages is calculated as:

```
Dice(A, B) = (2 * |A ∩ B|) / (|A| + |B|)
```

Where A and B are the trigram sets of each message, producing a score from 0.0 (no shared trigrams) to 1.0 (identical trigram sets). Displayed to users as 0–100%.

**Why Dice over Jaccard:** Both correctly distinguish similar from dissimilar messages. The difference is in score distribution at the top of the scale. For messages that are very similar (the consolidation use case), Dice provides finer granularity — spreading values between 85–100% where the interesting threshold decisions happen. Jaccard compresses this range. Since users will tune the threshold to control consolidation aggressiveness among highly similar messages, Dice gives more meaningful control in the relevant range.

**Worked example:**
```
A: "/Thingworx/Things/ABC1234-76C/Services/GetPropertyTime"
B: "/Thingworx/Things/ABC5678-76C/Services/GetPropertyTime"
```
~52 trigrams each, 48 shared, 4 unique per message.
- Dice: (2 * 48) / (52 + 52) = **92.3%**
- Jaccard: 48 / 56 = **85.7%**

Both high, but Dice gives more headroom above this score to distinguish "very similar" from "almost identical."

**Trade-offs:**
- Index memory grows with cluster count and message length — bounded by message length cap
- Trigrams balance granularity (bigrams too common, 4-grams too sparse for short messages)
- Very short messages (2-3 characters) produce minimal trigrams — acceptable as these are extremely rare in practice

### DD-02: Two-Phase Processing — Discovery and Matching

**Decision:** Pattern processing operates in two distinct phases with fundamentally different cost profiles.

**Phase 1 — Pattern Discovery (expensive, rare):**
Batch consolidation runs when unique unmatched message count within a category exceeds a configurable threshold (default 5000). During a consolidation pass:
1. N-gram index identifies candidate pairs
2. Candidate pairs are scored for Dice similarity
3. Pairs exceeding threshold undergo character-level diff-style alignment to identify variable vs constant regions
4. A mask is produced marking each character position as keep or variable
5. Canonical form and compiled regex are derived from the mask
6. Existing unconsolidated messages are scanned against new patterns — cheap matching absorbs additional entries

This is computationally expensive but only runs when discovering *new* patterns.

**Phase 2 — Pattern Matching (cheap, continuous):**
Once canonical patterns exist, incoming messages are checked against known compiled patterns at line processing time. This is a simple regex match, not a pairwise similarity comparison — fundamentally different cost from discovery. Messages matching a known pattern are immediately added to the existing cluster.

**Rationale:** The key insight is that pattern discovery and pattern matching are fundamentally different operations. Discovery requires expensive pairwise comparison and alignment. Matching against a known compiled pattern is cheap. As patterns accumulate, fewer incoming messages need the expensive discovery path — the system gets faster as it learns.

**Multi-pass behavior:** After a consolidation pass discovers patterns and reduces unique count, accumulation continues. If unmatched unique count exceeds threshold again, another discovery pass runs. Each pass may discover new similarities as the dataset grows — patterns that were initially constant (e.g., a single user name) become variable when new data introduces variation.

**Adaptive trigger threshold:** The consolidation trigger adapts based on consolidation yield — the percentage of messages consolidated in each pass. High yield (data is highly repetitive) raises the trigger, allowing more to accumulate since known patterns catch most incoming messages via cheap matching. Low yield (data is genuinely diverse) lowers the trigger, running discovery more frequently to catch new patterns before the unmatched set grows too large. Default starting threshold is 5000, configurable as a hidden/debug option for tuning during prototyping.

**Consolidation focus:** Multi-pass consolidation may prioritize messages with low occurrence counts (e.g., single-occurrence entries) in early passes, as these represent pure uniqueness that is most likely to benefit from grouping. Messages with higher occurrence counts that haven't matched any pattern are more likely to be genuinely distinct. This priority is configurable — a threshold for minimum occurrences below which consolidation is attempted more aggressively.

### DD-03: One-Way Generalization

**Decision:** Consolidation only generalizes, never specializes. Groups merge but never split.

**Rationale:** As more data arrives, patterns can only become more variable, not less. A message field that appeared constant may become variable when new data introduces variation. There is no scenario where a generalized pattern should become more specific.

When merging clusters: if cluster A+B already exists and a future pass determines it is similar to cluster C, then C merges into the existing A+B group. The canonical form generalizes further to accommodate C.

### DD-04: Canonical Form with Wildcards

**Decision:** Consolidated messages display a canonical form where variable parts are replaced with `*` wildcards. An optional mode preserves parameter length using `#` characters (e.g., `#####` for a 5-character parameter).

**Default:** `*` (single wildcard regardless of original length), since variable-length parameters are the common case and `*` produces cleaner, more readable output.

**Optional:** Length-preserving `#` mode for cases where parameter length carries diagnostic meaning.

### DD-05: Diff-Style Character-Level Alignment with Mask

**Decision:** When two similar messages are identified for merging, the alignment is performed using a diff-style character-level algorithm that produces a mask — an array of keep/variable flags per character position. The mask is the source of truth; all other representations are derived from it.

**Rationale:** Variable parts in log messages do not respect token boundaries. Examples:
- `ABC1234` vs `ABC5678` — "ABC" is constant, numeric suffix varies. Token splitting would treat the whole thing as different or the same.
- `PersistentSession2affb-ee87-0cac` — "PersistentSession" is constant, hex portion varies within what any delimiter-based tokenizer would consider part of the same token.

Character-level alignment correctly identifies "ABC" as constant and produces `ABC*`, while token-level approaches either miss the commonality or over-generalize.

**Mask as source of truth:** The alignment produces a mask (array/bitfield of keep/variable per character position). Three artifacts are derived from the mask:

1. **Canonical display string** — keep positions retain original characters, variable regions replaced with `*` (or `#` per character in length-preserving mode). Used as the hash key and in summary table output.
2. **Compiled regex** — keep positions become literal characters (escaped with `\Q...\E` for regex metacharacters), variable regions become `.+?` (non-greedy). Anchored with `^...$` to prevent partial matches. Used for cheap Phase 2 incoming message matching.
3. **The mask itself** — stored on the cluster for re-derivation if the canonical form changes during re-consolidation.

This separation means that `*` or `#` appearing in the original message text causes no ambiguity — the mask knows those positions are "keep" not "variable." The display string is a rendering convenience; the mask and compiled regex are the operational artifacts.

**Similarity-informed aggressiveness:** The Dice similarity score from the n-gram phase informs how aggressively the alignment generalizes. At high similarity (e.g., 95%), only the few differing characters are wildcarded. At lower similarity (e.g., 70%), larger contiguous differing regions are wildcarded. This naturally adapts to the degree of variation between messages.

### DD-06: Message Length Cap for Indexing

**Decision:** N-gram indexing operates on a truncated message, capped at a few hundred characters.

**Rationale:** Log lines can be arbitrarily long (stack traces, serialized objects, large payloads). Indexing beyond the meaningful prefix wastes memory and CPU without improving similarity detection. The existing `$log_key` truncation provides a natural model — similarity detection operates on the same truncated form used for display.

### DD-07: Stats Merging at Consolidation Time

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

### DD-08: Similarity Operates on $message Content

**Decision:** Similarity detection and consolidation operate on the `$message` string and all of its contents. The metadata prefix in `$log_key` (log level, thread name, object) is not part of the similarity comparison — it is part of the category/grouping structure that already exists.

**Rationale:** Thread names vary naturally (`http-thread-1` vs `http-thread-2`) and would introduce noise into similarity scoring. The `$message` string contains the semantically meaningful content where variable parameters appear. The metadata prefix serves as pre-existing categorization, not as content to be deduplicated.

### DD-09: Hash Key Management During Consolidation

**Decision:** When messages are consolidated, the original `$log_key` entries are removed from `%log_messages{$category}` and replaced by a new entry keyed by the canonical form. The canonical form *is* the new hash key.

**Rationale:** The `$log_key` serves as both hash key and display string. After consolidation, the canonical form becomes the display string, so it should also be the hash key. When a canonical form becomes more general on a subsequent pass (e.g., `User alice logged in from *` generalizes to `User * logged in from *`), the old key is removed and a new one created with the merged statistics.

This means consolidation is a destructive operation on the hash — original keys cease to exist. This is intentional for memory relief. For #97 (hierarchical grouping), original keys are preserved in the `children` hash within the cluster.

### DD-10: Observability and User Feedback

**Decision:** When `--group-similar` is active, the system provides feedback about consolidation activity.

**Consolidated message indicator:** Each consolidated message displays a visual indicator (character prefix) in the summary table output to distinguish it from unconsolidated messages. The same indicator is represented as a boolean field in CSV output.

**Verbose output (`-V`):** When verbose mode is active, consolidation statistics are included:
- Number of consolidation passes triggered
- Number of unique messages before/after consolidation per category
- Number of canonical patterns discovered
- Dice similarity scores for merged pairs (for threshold tuning)
- Adaptive trigger threshold adjustments and yield percentages
- Additional debugging information for development and testing

**Rationale:** Without observability, users cannot understand why results differ from unconsolidated output, cannot tune the similarity threshold effectively, and developers cannot troubleshoot the consolidation logic.

### DD-11: $mask_uuid Processing Order

**Decision:** The existing `$mask_uuid` feature is left intact for backwards compatibility. It runs before consolidation — UUID masking is applied during `$log_key` construction, before the message enters the consolidation pipeline.

**Rationale:** `$mask_uuid` replaces UUIDs with `#` characters during key construction. This means UUID-only variations are already collapsed into identical keys before consolidation ever sees them, reducing the number of unique messages and making consolidation's job easier. The two features complement each other: `$mask_uuid` handles the specific UUID case with zero overhead; consolidation handles the general case with its discovery/matching machinery.

### DD-12: Performance Targets

**Decision:** Consolidation must meet the following performance targets on files with high message uniqueness:

- **Wall clock time**: total ltl runtime with `--group-similar` no more than 10–15% slower than without
- **Peak memory**: reduced by at least 30% compared to without `--group-similar`

**Rationale:** Consolidation adds work during ingestion (n-gram indexing, discovery passes, pattern matching) but reduces work downstream (fewer entries for statistics calculation, less data to sort and render). The net wall clock impact should be modest. The memory target reflects that consolidation's primary value on high-uniqueness files is replacing thousands of individual hash entries (each with their own statistics, duration arrays, and hash overhead) with a smaller number of canonical clusters.

The memory target means the n-gram index, canonical pattern list, and mask structures must cost less than the memory freed by consolidation. This will be validated during prototyping with real log files.

### DD-13: Memory Observability

**Decision:** All new data structures introduced by consolidation — the n-gram index, canonical pattern list, and mask storage — are included in the `-mem` memory summary output and `-V` verbose output.

**Rationale:** To validate the 30% memory reduction target (DD-12) and to allow users to understand the memory profile of consolidation, all new structures must be visible in the same memory tracking infrastructure used by existing structures (`%log_messages`, `%log_analysis`, etc.).

## Data Structure

### Cluster Model

Extends `%log_messages{$category}` with a cluster concept:

```
%log_messages{$category}{$cluster_key} = {
    canonical       => "User * logged in from *",    # generalized display form (also used as $cluster_key)
    mask            => [1,1,1,1,0,0,0,1,1,1,...],    # source of truth: 1=keep, 0=variable per char position
    pattern         => qr/^\QUser \E.+?\Q logged in from \E.+?$/,  # compiled regex derived from mask
    is_consolidated => 1,                             # boolean: this entry is a consolidated group
    occurrences     => 5000,                          # aggregate count
    total_duration  => ...,                           # aggregate
    total_bytes     => ...,                           # aggregate
    durations       => [...],                         # concatenated raw values
    min             => ...,                           # min across all merged entries
    max             => ...,                           # max across all merged entries
    # ... other existing fields ...
    children        => {                              # optional, for #97 compatibility
        $original_key_1 => { ... },
        $original_key_2 => { ... },
    }
};
```

**Category-level n-gram index:**

```
%ngram_index{$category} = {
    "Use" => { $cluster_key_1 => 1, $cluster_key_3 => 1 },
    "ser" => { $cluster_key_1 => 1 },
    " al" => { $cluster_key_1 => 1 },
    ...
};
```

**Category-level pattern list** (for cheap incoming matching):

```
@canonical_patterns{$category} = [
    { pattern => qr/.../, cluster_key => $cluster_key_1 },
    { pattern => qr/.../, cluster_key => $cluster_key_2 },
    ...
];
```

### Backwards Compatibility

When `--group-similar` is not specified:
- No n-gram index is built
- No canonical patterns are created
- No consolidation passes run
- `%log_messages` behaves exactly as today
- All existing code paths work unchanged

When `--group-similar` is active but no consolidation has been triggered yet:
- Each message is its own cluster
- `$cluster_key` equals `$log_key`
- `is_consolidated` is not set
- `canonical`, `mask`, and `pattern` are not set
- `children` is empty or absent

### Two-Level Consolidation

1. **Within a cluster (children):** When child count within a cluster grows excessive, children can be consolidated — aggregate their stats into the parent and discard individual child entries. This is the memory relief mechanism.

2. **Across clusters (parents):** During a batch consolidation pass, existing cluster canonical forms are compared for similarity. Similar clusters merge — stats aggregate, canonical form generalizes further, mask updates, compiled pattern regenerates, n-gram index updates.

## Configuration

| Option | Type | Description |
|--------|------|-------------|
| `--group-similar` | Flag / Integer 0–100 | Enables feature. Without a value, uses default threshold of 85%. With a value (e.g., `--group-similar 90`), sets the similarity threshold. Accepts optional `%` suffix (e.g., `85%`). If a decimal like `0.85` is provided, it is detected and converted automatically. Will become default behavior once feature is hardened and proven. |
| Consolidation trigger | Integer | Hidden/debug option. Starting number of unique unmatched messages within a category before a discovery pass runs. Default 5000. Adapts dynamically based on consolidation yield: high yield raises the trigger, low yield lowers it. |
| Occurrence threshold | Integer | Optional. Consolidation passes prioritize messages below this occurrence count. Focuses early passes on single/low-occurrence entries (pure uniqueness grouping) while leaving frequently-occurring distinct messages alone until later passes. |
| Length-preserving wildcards | Boolean | Optional. Use `###` instead of `*` for variable parts. |

Additional CLI option names TBD during implementation planning.

## Processing Flow

### Initialization
1. If `--group-similar` is specified, initialize per-category n-gram index and canonical pattern list structures

### Line Processing (hot path)
1. Log line arrives, `$message` is extracted as today
2. `$mask_uuid` processing runs if active (before consolidation)
3. `$log_key` is built from metadata + `$message` as today
4. **Pattern match check:** If canonical patterns exist for this category, check `$message` against known compiled patterns
   - If match found: add stats directly to the matching cluster (cheap regex operation)
   - If no match: store as new entry in `%log_messages` as today (unconsolidated)
5. Track unconsolidated unique message count per category

### Consolidation Pass (triggered)
6. When unconsolidated unique count exceeds trigger threshold:
   a. Build/update n-gram index for unconsolidated entries in the category
   b. Score pairwise Dice similarity between candidate clusters (using n-gram candidate narrowing)
   c. For pairs exceeding similarity threshold: run diff-style character-level alignment to produce mask
   d. Derive canonical form and compiled regex from mask
   e. Merge matched entries — aggregate stats, remove original keys, insert canonical key
   f. **Re-scan pass:** Check remaining unconsolidated messages against newly discovered patterns — absorb additional matches cheaply
   g. Update n-gram index to reflect merged/removed clusters
   h. Calculate consolidation yield; adjust trigger threshold for next pass
   i. Reset unconsolidated count tracking
7. Continue line processing — subsequent consolidation passes trigger as needed

### Post-Processing
8. `calculate_all_statistics()` operates on the consolidated entries as normal — no awareness of consolidation needed
9. Summary table output displays canonical forms with consolidation indicator where applicable
10. CSV output includes `is_consolidated` boolean field

## Interaction with Existing Features

### Top N (`-n`)
Unchanged. `-n 20` shows the top 20 entries, which may now be consolidated groups rather than individual messages. This is the intended behavior — consolidated groups accumulate higher occurrence counts and naturally rise to the top, replacing the fragmented individual entries.

### Sorting
Unchanged. All existing sort options work on the consolidated entries' aggregate statistics.

### Filtering (`-include`, `-exclude`, pattern files)
No interaction. Filtering operates on raw log lines before message storage. Consolidation operates on stored messages after filtering.

### CSV Output (`-o`)
CSV output represents the same consolidated view as the summary table. Canonical forms replace individual message keys. An `is_consolidated` boolean column indicates whether a row is a consolidated group.

### Verbose (`-V`)
Enhanced with consolidation statistics (see DD-10).

### Memory Summary (`-mem`)
Enhanced with new data structure sizes (see DD-13).

## Test Files

The following log files should be used throughout prototyping, development, and testing:

| File | Type | Size | Purpose |
|------|------|------|---------|
| `logs/ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log` | ThingWorx ApplicationLog | 101.7MB | **Primary test file.** Hundreds of thousands of unique error messages — ideal for exercising similarity detection, consolidation passes, memory reduction, and adaptive trigger behavior. |
| `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` | Tomcat access log | 148MB | **Secondary test file.** Large access log with duration/bytes metrics — validates consolidation with full statistics merging on URI-based message patterns. |

## Open Questions

1. **Character-level alignment algorithm**: Exact diff-style algorithm variant for producing the keep/variable mask — to be determined during prototyping
2. **CLI option naming**: Exact flag names for occurrence threshold and length-preserving wildcards
3. **Performance benchmarks**: Consolidation pass timing on the test files above — wall clock and memory profiling with and without `--group-similar`
4. **Minimum cluster count**: Below what number of unique messages per category is consolidation not triggered at all? Likely related to the trigger threshold but may need a separate floor.
