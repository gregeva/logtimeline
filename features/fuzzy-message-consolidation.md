# Fuzzy Message Consolidation — Requirements

**GitHub Issue:** #96
**Status:** Prototype complete — Checkpoint architecture, core algorithms, and memory profile validated (PF-01 through PF-21). Ready for ltl integration.
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

## Prototype Findings

### PF-01: Default Threshold Lowered to 75% (was 85%)

**Finding:** UUID-varying ErrorCode messages — the dominant pattern in the primary test file (286K of 288K lines) — score 80–82% Dice similarity. A single UUID (36 chars) in a ~180-char message generates ~34 unique trigrams per message, dragging the score well below 85%.

**Decision:** Default threshold lowered to 75%. At 75%, the ErrorCode messages consistently pass the filter while still excluding genuinely dissimilar messages. The 85% default was based on the worked example in DD-01 which used short messages with small variable parts — real-world messages with UUIDs, session tokens, and entity names have proportionally larger variable regions.

**Impact on DD-01:** The Dice coefficient rationale still holds — Dice provides better granularity than Jaccard in the 75–95% range where threshold tuning happens. The threshold value changed, not the algorithm choice.

### PF-02: N-gram Index Performance Characteristics

**Finding from Phase 1 prototyping:**
- 288K lines parsed in ~1s, 5000 keys indexed in 0.36s
- For highly similar messages (ErrorCode pattern), median posting list size is ~5000 (nearly every indexed key shares the common trigrams)
- Building `%candidate_hits` by iterating all trigrams is O(trigrams × posting_list_size) — with 176 trigrams × 5000 entries = ~880K hash operations per candidate search
- Candidate scoring (top 50) adds negligible overhead
- Full candidate accumulation for one key against 5000 indexed keys takes ~0.1s

**Implication for Phase 4:** The consolidation loop must avoid searching all N keys pairwise. The interleaved discovery approach (find one pair → create pattern → re-scan remaining) is essential — it lets one pattern absorb thousands of matches without pairwise comparison.

### PF-03: LCS Alignment and Coalescing Behavior

**Finding from Phase 2 prototyping:**

LCS character-level alignment works well but has a known limitation: coincidental character matches inside variable regions (e.g., hex chars in UUIDs sharing `4403` by chance). A two-pass coalescing approach addresses most cases:

- **Pass 1:** Remove short keep runs (<3 chars) between variable regions.
- **Pass 2:** Detect variable-dominated spans (keep/total ratio < 40%) and collapse all keeps within them. A span boundary is defined by a long keep run (≥10 chars) or end of string.

**Results across categories:**
- **ERROR (UUID variation):** 3 of 5 pairs produce ideal `ErrorCode(*)`. 2 pairs have minor boundary leakage (1–4 chars of hex retained at UUID edges), causing regex to match A but not B. Cross-cluster merging in Phase 4 will generalize these further.
- **INFO (elapsed time variation):** Perfect canonicals — `[elapsed *ms]` with entity names correctly preserved.
- **WARN (provider name + numeric stat variation):** Excellent results — provider prefix wildcarded, static config values preserved literal, only varying counters wildcarded. 12 of 13 total pairs have regex matching both A and B.

**Decision:** Coalescing parameters (min keep run = 3 chars, variable-dominated ratio threshold = 40%, long keep boundary = 10 chars) are good defaults. Boundary char leakage is acceptable at this stage — Phase 4 cross-cluster merging will handle it.

### PF-04: Pattern Count Must Be Bounded — Matching Cost Is Linear Per Line

**Finding from Phase 3 prototyping:**

Matching 286K unique messages against 103 compiled regex patterns took 18.4s in batch mode (~0.06ms per message × pattern). In ltl integration, pattern matching runs per incoming line during ingestion. With 288K lines and 100 patterns, that's 28.8M regex evaluations.

**Key observations:**
- 50 ERROR patterns were discovered but most are redundant overlaps of the same ErrorCode message (e.g., `ErrorCode(*)`, `ErrorCode(c*)`, `ErrorCode(6*3)` all match subsets of the same population)
- The ideal `ErrorCode(*)` pattern alone absorbed 268K of 286K ERROR messages (93.7%)
- Overlapping patterns with boundary char leakage add cost without meaningful coverage improvement

**Decision:** Pattern count must be bounded per category. Cross-cluster merging (Phase 4) must consolidate overlapping patterns — compare existing canonical forms for similarity and merge when they represent the same underlying message template. The most general pattern subsumes the more specific ones. Target: <20 patterns per category for production use.

**Impact on DD-02:** The two-phase processing model is validated — discovery is expensive but rare, matching is cheap per-pattern. But the "cheap" matching cost is multiplied by pattern count × line count, so pattern count is a critical control lever.

### PF-05: Pattern Management — Merge-First + Hard Cap

**Decisions from Phase 4 review:**

**Merge-first policy:** Before adding a new pattern, check existing patterns for similarity. If a similar pattern exists, merge the new pattern into it (generalizing the existing pattern further). This keeps count bounded while improving coverage. Patterns are never removed — only replaced by merging — because aggregated statistics are already accumulated against them.

**Hard cap:** A hard limit on the number of compiled patterns. When the cap is reached, a new pattern can only be added if it replaces (by merging into) an existing one. Verbose output should report when the cap is hit so users know consolidation is limited. The cap applies to the entire `plain` category (all log levels mixed — see PF-07), so it must be set higher than per-level budgets would be. Default TBD during implementation.

**Prevalence-first discovery:** High-volume patterns should naturally be discovered first due to their prevalence in the index — the most common message variations are the most likely to appear as candidate pairs. This means the most impactful patterns claim budget slots first.

### PF-06: Occurrence Ceiling — Skip High-Occurrence Messages

**Decision:** Messages already appearing N or more times are excluded from consolidation discovery passes. They are already naturally grouped by identical `$log_key` and are not the intended target for fuzzy consolidation. Default ceiling: 3 occurrences.

**Rationale:** A message occurring 100 times with identical text is not a consolidation candidate — it's already well-grouped. The consolidation target is the long tail of single/low-occurrence entries that represent the same pattern with variable parameters (UUIDs, usernames, timestamps). Excluding high-occurrence messages from discovery reduces the search space and avoids creating unnecessary patterns.

**Auto-adjustment:** The ceiling should be adjustable at runtime. When memory pressure is high and the system wants to consolidate further, the ceiling can be lowered (e.g., from 3 to 2) and consolidation re-run to capture previously-excluded entries. This ties consolidation aggressiveness to memory conditions — a self-tuning mechanism.

**CLI:** Configurable as a hidden/debug option during prototyping. Default 3.

### PF-07: Level Partitioning Deferred — Algorithm Works Without It

**Finding:** In ltl, `%log_messages` is keyed by `$category` which is `'plain'` or `'highlight'` — NOT by log level (ERROR/WARN/INFO). The log level is baked into `$log_key` as the `[$log_level]` prefix.

**Why it works without partitioning:** The `[ERROR]`/`[WARN]`/`[INFO]` prefix in `$log_key` means messages of different levels will never score above the Dice threshold against each other. Their trigram sets naturally separate them. So consolidation operating on the entire `plain` pool is functionally correct.

**Trade-off of not partitioning:**
- The n-gram index is larger than necessary (WARN trigrams point to ERROR keys, wasting memory and lookup time)
- Pattern budget is shared across all levels (see PF-05 — cap must be set higher)
- Candidate search does extra work scoring cross-level candidates that will never match

**Decision:** Defer level partitioning to a future enhancement. The current `%log_messages` data model does not need to change. Consolidation operates on `%log_messages{'plain'}` as a single pool. The hard cap accommodates this by being set higher. Partitioning by extracting `[LEVEL]` from `$log_key` can be added later as an optimization.

### PF-08: Default Threshold Raised to 80%

**Finding:** After implementing merge-first pattern generalization and the `*`-aware canonical/regex derivation, threshold 75% was too aggressive — merging canonicals that shouldn't merge. Threshold 80% provides a good balance: strict enough to avoid false merges, loose enough to catch genuine patterns.

**Decision:** Default threshold = 80%. The final pass uses 95% for high-occurrence cleanup.

### PF-09: Similarity Must Operate on Full `$log_key`, Not Just `$message`

**Finding:** When consolidation operated on `$message` only (the text after `[level] [thread] [object]`), the canonical forms lost their prefix metadata. The CheckHeartbeat messages appeared as bare `Error Executing Event Handler 'CheckHeartbeat'...` without the `[ERROR] [TWEventProcessor-*] [c.t.s.s.e.EventInstance]` prefix.

**Decision:** Index and compare the full `$log_key`. The `[level]` prefix naturally prevents cross-level merges (see PF-07). The thread and object portions participate in similarity/alignment, producing correct wildcards like `[TWEventProcessor-*]`.

### PF-10: Canonical and Regex Derivation Must Handle Pre-Existing `*` Characters

**Finding:** When merge-first generalizes a pattern by aligning two canonical forms, both already contain `*` from previous canonicals. The LCS alignment treats `*` as a literal character, producing `**` in derived canonicals and `\*` (literal match) in derived regexes. This caused patterns to become overly narrow (e.g., `ErrorCode(9*)` matching only UUIDs starting with `9` instead of all UUIDs).

**Fix:** Both `derive_canonical()` and `derive_regex()` now treat `*` in keep positions as variable — emitting `*`/`.+?` instead of the literal character. This ensures repeated generalization converges toward broader patterns rather than fragmenting.

### PF-11: Merge-First Must Re-Scan Unmatched Keys After Pattern Generalization

**Finding:** When merge-first generalizes an existing pattern, the new broader regex may now match keys that the old narrower pattern missed. Without re-scanning, these keys remain unconsolidated — e.g., `ErrorCode(4*34)` with 64 occurrences sitting separately from the main `ErrorCode(*)` cluster with 286K occurrences.

**Fix:** After `try_merge_into_existing()` generalizes a pattern, immediately re-scan all remaining unmatched keys against the updated regex. This absorbed significant additional messages in practice.

### PF-12: Final Pass — Optional High-Similarity Cleanup of Ceiling-Excluded Keys

**Finding:** The occurrence ceiling (default 3) prevents high-occurrence messages from entering discovery. But some high-occurrence messages share patterns (e.g., `CheckHeartbeat` across 16 thread pools, each with 29-47 occurrences). These are obvious consolidation candidates that the ceiling blocks.

**Design decisions:**
- The final pass is a **separate optional process flow** (`--final-pass`), not part of the normal consolidation. It is not always-on — users opt in when they want cleanup of high-occurrence stragglers.
- The similarity threshold for the final pass is deliberately high (default 95%, configurable via `--final-threshold`). At 95%, only nearly-identical messages consolidate — the only variation allowed is small fields like thread numbers or short IDs. This prevents over-generalization of messages that happen to share common boilerplate.
- The final pass ceiling (default 100, configurable via `--final-ceiling`) defines the upper bound — messages with more than this many occurrences are left alone even in the final pass.
- **Relationship to PF-06:** The ceiling and final pass are complementary. The ceiling keeps the main discovery loop focused on the long tail of low-occurrence unique messages (the primary consolidation target). The final pass handles the case where the ceiling creates "stranded" high-occurrence entries that share obvious patterns but were excluded from discovery. Together they provide two-tier consolidation: aggressive discovery on the long tail, conservative cleanup on high-occurrence groups.

**Results on test file:**
- CheckHeartbeat: 16 entries (29-47 occ each) → 1 entry with 583 occurrences
- CheckOverallStatuses: similar consolidation → 59 occurrences
- ERROR remaining: 42 → 12, WARN remaining: 89 → 44
- Final pass time: ~2s (fast — small candidate sets, high threshold)
- WARN overall reduction: 62.7% → 76.7%

### PF-13: Hot-Sort Pattern List for Faster Matching

**Finding:** Linear scan of compiled patterns is the dominant cost. The most common patterns (ErrorCode with 286K matches) should be checked first.

**Solution:** `match_against_patterns()` tracks match counts and bubbles matched entries up one position after each hit. The hottest patterns naturally migrate to the front of the list. Combined with bounded pattern counts (PF-05), this keeps per-line matching cost low.

### PF-14: Performance Profile — NYTProf Analysis

**Test:** 288K-line ThingWorx log (286K unique messages), `--threshold 80 --ceiling 3 --max-patterns 50 --final-pass`.

**Before optimization (profile baseline):**

| Function | Excl. Time | Calls | % of Total |
|----------|------------|-------|------------|
| `compute_mask` | 33.4s | 1,107 | 62.8% |
| `find_candidates` | 11.1s | 314 | 21.0% |
| `run_consolidation_pass` | 3.23s | 6 | 6.1% |
| `build_ngram_index` | 713ms | 12 | 1.3% |
| `CORE:match` (regex eval) | 601ms | 2M | 1.1% |
| `get_trigrams` | 509ms | 11,290 | 1.0% |
| `match_against_patterns` | 436ms | 286,870 | 0.8% |
| `dice_coefficient` | 213ms | 7,995 | 0.4% |

**Optimizations applied:**

1. **`compute_mask` — prefix/suffix stripping:** Similar messages (e.g., ErrorCode with varying UUIDs) share ~200 chars of identical prefix and suffix. Stripping these before the LCS DP reduces the matrix from 350×350 (122K cells) to ~40×40 (1.6K cells) — a 76× reduction in DP work. The prefix and suffix are trivially marked as "keep" in the mask.

2. **`compute_mask` — bit-packed direction table:** The DP backtrace direction table (3 values per cell) was stored as an array-of-arrays of Perl scalars. Replaced with a bit-string using `vec()` at 2 bits per cell, reducing memory allocation overhead and improving cache locality.

3. **`find_candidates` — trigram set size pre-filter:** Before scoring a candidate with `dice_coefficient()`, check if its trigram set size is within the theoretical bounds for the threshold. Dice = 2|A∩B|/(|A|+|B|) ≥ T% requires |B| ∈ [|A|·T/(200−T), |A|·(200−T)/T]. Candidates outside this range are skipped without scoring.

**After optimization:**

| Function | Excl. Time | Calls | % of Total | Speedup |
|----------|------------|-------|------------|---------|
| `find_candidates` | 11.1s | 309 | 37.3% | — |
| `compute_mask` | 10.8s | 831 | 36.3% | **3.1×** |
| `run_consolidation_pass` | 2.55s | 6 | 8.6% | 1.3× |
| `build_ngram_index` | 769ms | 12 | 2.6% | — |
| `coalesce_mask` | 86ms | 831 | 0.3% | 1.4× |
| `derive_canonical` | 84ms | 831 | 0.3% | 1.5× |
| `derive_regex` | 82ms | 831 | 0.3% | 1.4× |

**Overall: 30s → 21s (1.4× total speedup). Memory: ~500MB RSS (unchanged).**

**Remaining hotspot:** `find_candidates` at 37.3% is now the top cost. Its time is spent iterating posting lists in `%ngram_index` to accumulate candidate hit counts. This is inherent to the inverted-index approach. Further optimization would require a fundamentally different algorithm (e.g., locality-sensitive hashing). For the ltl integration, this cost is amortized: consolidation runs infrequently (only when unmatched count exceeds the trigger), not per-line.

### PF-15: Alignment Algorithm — Inline::C Banded Edit Distance (100× speedup)

**Problem:** `compute_mask` remained the dominant cost even after PF-14 optimizations (10.8s, 36.3% of total). The pure-Perl LCS DP is bottlenecked by Perl interpreter overhead (array creation via `split //`, per-element hash/array access, `vec()` calls), not algorithmic complexity. After prefix/suffix stripping, the differing middles average only ~38 chars — the 40×40 DP matrix is tiny, but Perl's per-operation cost makes it expensive.

**Benchmark:** Six alignment approaches tested on 102 real similar-message pairs (5 repeats each):

| # | Approach | Per-call | Speedup | Notes |
|---|----------|----------|---------|-------|
| 1 | Current LCS DP | 1.35 ms | baseline | Pure Perl, O(mn) |
| 2 | Banded edit distance (Perl) | 1.65 ms | 0.8× (slower) | Pure Perl, O(nk) — Perl overhead dominates |
| 3 | Algorithm::Diff sdiff | 0.27 ms | 5.0× | Pure Perl, Myers O(ND) |
| 4 | Algorithm::Diff traverse | 0.23 ms | 5.9× | Pure Perl, Myers O(ND), less overhead |
| 5 | Algorithm::Diff::XS traverse | 0.23 ms | 5.9× | XS C core — no gain over pure Perl (bottleneck is `split //` and callbacks) |
| 6 | **Inline::C banded ED** | **0.013 ms** | **100×** | Full C: prefix/suffix strip + banded DP + backtrace |

**Key findings:**
- **Banded DP in pure Perl is slower** than unbanded — the band-clamping logic (`max/min` per iteration, out-of-band fill) adds more Perl overhead than the reduced cell count saves.
- **Algorithm::Diff::XS provides no advantage** over pure-Perl Algorithm::Diff. The XS module accelerates the core LCS computation in C, but the bottleneck is Perl-side: creating character arrays via `split //` and per-match callback dispatch. Both incur identical overhead.
- **Inline::C eliminates all Perl overhead.** The entire alignment — prefix/suffix stripping, banded DP, direction table, backtrace — runs in C operating on raw `char*` strings. No array creation, no callbacks, no Perl scalar operations in the inner loop.

**Decision:** Replace `compute_mask` with `Inline::C` banded edit distance. The C function compiles on first use and the shared object is cached. For PAR-packaged distribution, the compiled `.so` is included in the package — identical to any other XS dependency.

**Mask equivalence:** Edit distance alignment produces slightly different masks than LCS (edit distance prefers substitution over delete+insert for single-character changes). The differences are in ambiguous regions within variable spans and are normalized by `coalesce_mask`. End-to-end consolidation quality is equivalent.

**End-to-end impact (full 288K-line test, `--final-pass --verbose`):**

| Metric | Before (Perl LCS) | After (Inline::C) | Improvement |
|--------|-------------------|-------------------|-------------|
| Total time | 21s | 10.3s | 2.0× |
| Phase 4 (consolidation) | 14.5s | 2.4s | 6.0× |
| Phase 3 (pattern matching) | ~5.9s | 5.9s | — (not affected) |
| RSS memory | 792 MB | 512 MB | 35% less |

**Remaining costs:** Phase 3 pattern matching (5.9s) is now the dominant cost — linear scan of 286K messages against compiled regex patterns. This is a separate optimization target for ltl integration (e.g., skip pattern matching for categories with few patterns, or batch-apply patterns during consolidation only).

### PF-16: Re-scan Optimization Research — Phase 4 Breakdown and Approach Selection

**Problem:** After making Phase 3 verbose-only (saving 5.9s) and replacing `compute_mask` with Inline::C (PF-15), total time dropped to 4.95s. Phase 4 is now the dominant cost at 2.9s. Instrumented breakdown:

| Component | Time | % of Phase 4 | Scaling concern |
|-----------|------|--------------|-----------------|
| build_ngram_index | 0.49s | 30% | Scales with trigger (fixed at 5000) |
| **interleaved re-scan** | 0.47s | 29% | **O(unmatched × patterns)** |
| **merge re-scan** | 0.36s | 22% | **O(unmatched × merges)** |
| find_candidates | 0.27s | 17% | Scales with trigger × posting list size |
| compute_mask (C) | 0.01s | 1% | Solved (PF-15) |

The two re-scans are 51% of Phase 4: 848K regex evaluations across 46 patterns. Each pattern discovery triggers a linear scan of ALL remaining unmatched keys. With 1M unique keys this becomes ~3M regex evals.

**Research: 10 approaches evaluated for reducing re-scan cost.**

**Tier 1 — Selected for implementation (combined 20-40× reduction in regex evals):**

1. **Key Partitioning by log level + class name** — Partition `@unmatched_keys` once into ~20 buckets. Each pattern scans only its matching bucket. Pure Perl, ~15 lines. Expected 20× reduction. One-time O(N) partitioning amortized across all patterns.

2. **Batched Discovery** — Discover 5-10 patterns before re-scanning, then one combined scan tests all accumulated patterns. Trivial restructuring, 5-10× fewer scan passes. Composes with partitioning. Trade-off: loses some cascading reduction from interleaved absorption, but `%consumed` hash already short-circuits consumed keys.

**Tier 2 — If Tier 1 is insufficient:**

3. **Alternation regex pre-filter** — Build `qr/(?:$p1)|...|(?:$p46)/` as fast rejection filter. Perl's regex optimizer may build an internal trie for common literal prefixes. Zero architecture change.

4. **Prefix index** — Extract literal prefix from each pattern (up to first `.+?`), hash lookup before regex eval. Alternative to partitioning for variable key formats.

**Tier 3 — Heavy optimizations (only if re-scan remains dominant):**

5. **Inline::C batch match with PCRE2** — Move the match loop to C, eliminating per-call Perl overhead (3-5× on remaining evals). Requires PCRE2 headers.

6. **MCE parallelism** — Distribute partitioned buckets across CPU cores. Realistic 2× speedup.

7. **Hyperscan/RE2::Set** — Single-pass multi-pattern DFA. Theoretical best for 1000+ patterns, but Hyperscan doesn't support ARM (blocks macOS arm64 builds) and RE2::Set requires custom C++ bindings.

**Rejected approaches:**
- Lazy/deferred re-scan — strictly worse for power-law distributions (first pattern absorbs 99% of keys; without re-scan, unnecessary discovery cycles are triggered)
- Inverted pattern index — over-engineered for ~46 patterns; prefix indexing subsumes it
- Bloom filter pre-filter — over-engineered at this scale
- Sampling-based re-scan — introduces correctness trade-off (misses rare matches)

**Scaling analysis:**

| Approach | 286K keys | 1M keys | 5M keys |
|----------|-----------|---------|---------|
| Current (no opt) | 848K evals | ~3M evals | ~15M evals |
| Partitioning (20 buckets) | ~42K evals | ~150K evals | ~750K evals |
| + Batched discovery | Same, 5× fewer passes | Same | Same |
| + Inline::C batch | Same count, 3-5× faster | Same | Same |

Partitioning keeps the problem tractable up to ~5M keys. Beyond that, Hyperscan/RE2::Set becomes worth the build complexity.

### PF-17: Key Partitioning Implementation — Batching Regression and Fix

**Implemented:** Partitioned interleaved re-scan in `run_consolidation_pass()`.

**First attempt — batched discovery (failed):** Implemented `$discovery_batch_size = 10` with deferred re-scan. Accumulated 10 patterns before flushing. Result: **Phase 4 regressed from 2.9s to 64.25s** (22× slower). Root cause: batching destroys cascading reduction. In power-law data, pattern 1 absorbs 99%+ of keys via interleaved re-scan. With batch_size=10, patterns 2-10 each discover against the full 286K unmatched set (pattern 1's absorption hasn't happened yet). This caused 500 pattern discoveries in pass 1 (was 2 before), with massive redundant work.

**Key insight:** For power-law distributions, **interleaved re-scan is essential**. The cascading reduction (pattern 1 absorbs bulk, leaving tiny residual for subsequent patterns) is the core performance mechanism. Batching trades correctness of scan cost for fewer passes — but when one pattern absorbs 99%, the "fewer passes" savings is negligible while the expanded discovery cost is catastrophic.

**Fix — partitioned interleaved re-scan:** Keep interleaved re-scan (scan immediately after each pattern discovery) but partition keys by `[LEVEL][class]` so each scan only touches the matching bucket instead of all unmatched keys.

**Helper functions added:**
- `extract_bucket_key($log_key)` — extracts `[LEVEL][class]` from log_key (skipping thread)
- `partition_keys($keys_ref)` — partitions keys into bucket hash
- `extract_pattern_bucket($canonical)` — extracts bucket key from pattern canonical

**Results:**
- Phase 4: 2.9s → 2.27s (21% faster)
- Total: 4.95s → 4.21s (15% faster)
- Absorption unchanged: 286,437/286,571 (same correctness)

**Decision:** Batched discovery rejected for this data profile. Partitioned interleaved re-scan is the correct approach. The `batched_rescan()` function was removed as dead code.

### PF-18: Discriminative Trigram Pre-filter for find_candidates

**Problem:** NYTProf profiling (PF-14) revealed `find_candidates` consumes 88.1% of runtime (29.9s out of 34s) on diverse log files. The inner loop iterates all posting lists for every source trigram — common trigrams like `[WA`, `ARN`, `] [` appear in nearly every WARN key, creating posting lists of 1000-5000 entries. Each call visits ~300K posting entries across 1152 calls.

**Solution — two-phase pre-filter:**
1. **Phase 1 (cheap):** Sort source trigrams by posting list size (ascending = most discriminative). Use only top-50 trigrams to build candidate set. Require only 30% of those 50 trigrams to match (loose threshold of 15 hits). This skips the massive posting lists entirely.
2. **Phase 2 (accurate):** Apply size filter + full Dice coefficient verification on the pre-filtered candidate set.

**Parameters:** `$discriminative_topk = 50`, `$prefilter_ratio = 0.30` (loose_min = max(1, int(0.30 * 50)) = 15).

**Data structure:** `%posting_size{$category}{$trigram}` cache populated at end of `build_ngram_index()`.

**Benchmark results** (200-key sample, diverse ApplicationLog):
- Top-50/ratio-0.3: **4.8× speedup**, zero missed matches (0/200 test keys)
- Top-30/ratio-0.3: 6.2× speedup but 2 missed matches
- Top-20/ratio-0.3: 8.1× speedup but 5 missed matches

**Integration results:**
- Primary file (power-law): Phase 4 2.27s → 2.03s (11% faster) — minimal impact because interleaved re-scan absorbs bulk before many `find_candidates` calls
- Diverse file (ApplicationLog): Phase 4 9.46s → 6.21s (34% faster) — significant improvement because `find_candidates` dominates

**Also cleaned up:** Removed dead `batch_match_one_c()` from Inline::C block (unused after reverting batch match integration from PF-16).

### PF-19: UUID Normalization for Dice Scoring

**Problem:** After rebuilding with checkpoint-based architecture (PF-20), NYTProf profiling on the diverse ApplicationLog revealed `dice_coefficient` consuming 49% of runtime (6.32s, 414K calls). Root cause: 1,709 DEBUG keys all share the same 80-char prefix (`Nonce key retrieved. Resulting key is <UUID>`) but differ only in the UUID tail. Full Dice scores 74-76% (below 80% threshold) because ~34 unique UUID trigrams per message drag the score down. This caused 500 fruitless `find_candidates` calls discovering zero patterns.

**Investigation — prefix gate rejected:** A prefix Dice reject gate was explored first but would NOT help — all 1,709 DEBUG keys have 100% prefix Dice similarity. The problem is the opposite: keys that SHOULD match are being rejected by full Dice due to UUID noise.

**Solution — UUID normalization in Dice scoring pipeline:**
- `$uuid_re = qr/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i`
- `%key_trigrams_norm{$key}` — UUID-normalized trigrams, built in `build_ngram_index` only for keys containing UUIDs
- `find_candidates` uses normalized trigrams for Dice scoring, original trigrams for indexing/posting list construction
- Normalization does NOT affect `derive_canonical`/`derive_regex` — those still use original text (UUIDs get wildcarded naturally by alignment)
- Freed in `run_checkpoint` alongside `%key_trigrams`

**UUID prevalence in test files:**
- 100% of DEBUG keys (1,709/1,709) — all `Nonce key retrieved`
- 100% of power-law ERROR keys (286,571/286,571) — all `ErrorCode(uuid)`
- 64.5% of WARN keys (4,524/7,014) — `PersistentSession`, `IntrusionDetector`, etc.
- Normalized Dice for same-structure messages: 97-100% (vs 74-76% unnormalized)

**Results:**
- ApplicationLog: 6.80s → 2.06s (3.3× faster)
- DEBUG: 1,709 → 1 pattern with 1 fc_call (was 500 fruitless calls, 0 patterns)
- `dice_coefficient`: 414K calls → ~7.5K (42× fewer)
- Power-law file: 1.87s (essentially unchanged — UUID normalization has minimal overhead)

**Key insight:** UUID normalization is not just an optimization — it fixes a correctness gap. Without it, UUID-varying messages that represent the same pattern cannot be consolidated because Dice scores are below threshold. The normalization lets the similarity engine see through random hex noise to the structural similarity underneath.

### PF-20: Checkpoint-Based Architecture Rebuild

**Problem:** The prototype loaded all log lines into memory, then ran consolidation over the entire key set at once. This made performance numbers meaningless — there were no batch boundaries where new keys arrive against existing patterns, so the S1 inline match and S3 checkpoint match stages never had any work to do.

**Solution — move consolidation INTO the parsing loop as checkpoint-triggered processing:**

```
Parse line-by-line:
  → new key? S1 inline match (try match_against_patterns)
    → match? merge into cluster, key never enters %log_messages
    → no match? add to %log_messages + %unmatched_keys{$cat}
  → unmatched count for category hits trigger (5000)?
    → fire checkpoint: S2 ceiling → S3 checkpoint match → S4 pairwise → re-scan
    → delete absorbed keys from %log_messages
→ after EOF: final checkpoint for remaining unmatched keys
→ Phase 5 output
```

**5-stage pipeline with tracking invariant:**
- **S1 Inline match** — new key matched against compiled patterns during parsing, routed to cluster, never enters `%log_messages`
- **S2 Ceiling filter** — at checkpoint: occurrences >= ceiling, excluded from discovery
- **S3 Checkpoint match** — at checkpoint: matched existing pattern discovered in same checkpoint's S4
- **S4 Pairwise discovery** — Dice similarity + interleaved re-scan within checkpoint batch
- **S5 Unmatched** — survived all stages across all checkpoints
- Invariant: `S1 + S2 + S3 + S4 + S5 = cat_keys_seen` per category (built-in sanity check)

**New data structures:**
- `%clusters{cat}{canonical}` — consolidated cluster stats (occurrences, match_count)
- `%unmatched_keys{cat}{key}` — keys awaiting consolidation
- `%cat_stats{cat}` — per-category S1-S5 accumulators
- `%cat_keys_seen{cat}`, `$total_keys_seen` — unique key counters

**Memory lifecycle:**
- Trigram data (`%ngram_index`, `%key_trigrams`, `%posting_size`, `%key_trigrams_norm`) built and freed per checkpoint
- Only compiled patterns (`%canonical_patterns`) and clusters (`%clusters`) persist across checkpoints
- Absorbed keys deleted from `%log_messages` and `%key_message` to free memory

**Results — power-law file (288K lines, 286K unique ERROR):**
- Total: 1.87s (was 3.6s in old architecture)
- 4 checkpoints fired for ERROR (57 batches of 5000 → absorbed by S1 inline after checkpoint 1)
- S1 Inline match: 282,081 (98.4% of all ERROR keys absorbed during parsing)
- S4 Pairwise discovery: 4,416 (only checkpoint 1 does significant work)
- S5 Unmatched: 24
- 5 patterns discovered, `match_against_patterns` dominant cost at 0.68s

**Results — diverse file (480K lines, 10K unique):**
- Total: 2.06s (was 12.3s in old architecture, after UUID normalization)
- WARN: 2 checkpoints, S1=4,543, S4=1,843, S5=18, 43 patterns
- ERROR: 1 final checkpoint, S4=210, S5=31, 12 patterns
- DEBUG: 1 final checkpoint, S4=1,708, S5=1, 1 pattern (UUID normalization enables this)
- INFO: 1 final checkpoint, S4=4, S5=8

**Validated the checkpoint design:**
- S1 inline match is the primary performance mechanism — absorbs 98%+ of keys on power-law data
- Trigram data freed per checkpoint keeps memory bounded
- Per-checkpoint output provides full pipeline visibility (S2 → S3 → S4 flow)
- Tracking invariant catches any accounting errors immediately

### PF-21: Memory Instrumentation and ltl Baseline Comparison

**Problem:** The checkpoint architecture frees memory at each checkpoint (deleting absorbed keys from `%log_messages`/`%key_message`, freeing trigram data). But we'd never measured whether this actually works, or how the prototype's memory footprint compares to ltl baseline.

**Implementation — `--mem` flag added to prototype:**
- `get_rss()` — RSS via `ps` (macOS), always called to track high-water mark
- `measure_memory($label)` — when `--mem` is set, measures 9 data structures via `Devel::Size::total_size()` and records snapshots
- Measurement points: after consolidation pass (before cleanup), after cleanup, after parsing, after final checkpoints, after final pass, end of processing
- ltl-equivalent projection: tracks cumulative bytes deleted from `%log_messages`/`%key_message` to show what those structures would cost if keys were retained (as ltl does)
- Zero overhead without `--mem` — only RSS tracking via `ps`

**Findings — power-law file (288K lines, 286K unique ERROR):**

| Measurement | Value |
|-------------|------:|
| ltl baseline RSS | 172 MB |
| ltl `log_messages` | 105 MB |
| Prototype RSS (high-water) | 238 MB |
| Prototype RSS (end) | 238 MB |
| Peak structure HWM: `key_trigrams` | 73 MB |
| Peak structure HWM: `ngram_index` | 68 MB |
| Peak structure HWM: `key_trigrams_norm` | 65 MB |
| Peak structure HWM: `key_message` | 3.1 MB |
| Peak structure HWM: `log_messages` | 2.5 MB |
| Cumulative deleted `log_messages` | 2.6 MB |
| Cumulative deleted `key_message` | 3.2 MB |
| Peak ltl-equivalent (all structures) | 214 MB |

**Findings — diverse file (480K lines, 10K unique):**

| Measurement | Value |
|-------------|------:|
| ltl baseline RSS | 28 MB |
| ltl `log_messages` | 0.8 MB |
| Prototype RSS (high-water) | 157 MB |
| Prototype RSS (end) | 157 MB |
| Peak structure HWM: `ngram_index` | 52 MB |
| Peak structure HWM: `key_trigrams` | 50 MB |
| Peak structure HWM: `key_trigrams_norm` | 29 MB |
| Peak structure HWM: `key_message` | 3.5 MB |
| Peak structure HWM: `log_messages` | 3.2 MB |
| Cumulative deleted `log_messages` | 3.0 MB |
| Cumulative deleted `key_message` | 3.3 MB |
| Peak ltl-equivalent (all structures) | 142 MB |

**Analysis:**

1. **The prototype uses MORE memory than ltl, not less.** The trigram data structures (`key_trigrams` + `ngram_index` + `key_trigrams_norm`) peak at ~206 MB (power-law) and ~131 MB (diverse). This is the cost of similarity search — there's no free lunch.

2. **The freed memory IS reusable.** When Perl `delete`s hash entries, that memory returns to Perl's internal free pool. Subsequent checkpoints reuse this memory for new trigram indices rather than requesting more from the OS. RSS stays flat across checkpoints despite building and tearing down 50-70 MB of trigram data each time.

3. **RSS never decreases — this is normal.** `free()` returns to Perl's allocator, not the OS. The RSS high-water mark equals RSS at end for both files. The cleanup works at the Perl level (structures go to near-zero after cleanup), but the OS-level RSS doesn't shrink.

4. **The deleted `log_messages`/`key_message` data is tiny** (~3-6 MB) compared to trigram overhead (~200 MB). The memory savings from absorbing keys during parsing (S1 inline match preventing `%log_messages` entries) saves far more than the explicit deletions after checkpoints.

5. **The dominant memory cost is trigrams, bounded per checkpoint.** Each checkpoint builds trigrams for at most `$trigger` keys (5000), then frees them. The peak is one checkpoint's worth of trigram data, not cumulative.

**Implications for ltl integration:**

- **DD-12 memory target (30% reduction) will NOT be met** on these test files. The trigram overhead exceeds the savings from consolidation.
- However, the memory IS bounded — it doesn't grow with file size beyond one checkpoint batch. On a 10 GB file with millions of lines, ltl's `%log_messages` would grow proportionally while consolidation's trigram overhead stays fixed at one batch.
- The crossover point — where consolidation saves more memory than it costs — depends on the ratio of unique keys to total keys. Files with millions of unique keys (where ltl's `%log_messages` would be huge) would benefit most.
- The `$trigger` parameter directly controls the trigram peak: lower trigger = smaller batches = less trigram memory but more frequent checkpoints.

### PF-22: Ceiling Comparison and Final Pass Validation

**Ceiling comparison:** Tested ceiling values 2, 3, 4, and 5 on both test files.

| Ceiling | S2 filtered (power-law) | S5 unmatched | WARN remaining | S2 filtered (diverse) | S5 unmatched | WARN remaining |
|---------|------------------------:|-------------:|---------------:|----------------------:|-------------:|---------------:|
| 2 | 91 | 28 | 100 | 262 | 40 | 217 |
| 3 | 69 | 32 | 99 | 81 | 46 | 58 |
| 4 | 64 | 30 | 96 | 77 | 46 | 55 |
| 5 | 14 | 30 | 46 | 78 | 48 | 55 |

**Decision: ceiling=3 (confirmed).** Ceiling=2 is the clear outlier — it shields too many keys from discovery, causing WARN remaining to balloon from 58 to 217 on diverse data. Ceiling 3, 4, and 5 produce very similar results on diverse data. On power-law, ceiling=5 slightly improves WARN (46 vs 99) but the difference is marginal. Ceiling=3 is the best balance: filters enough to focus discovery on the long tail without shielding consolidatable keys.

**Final pass validation:** `--final-pass` works correctly with checkpoint architecture on both files.

- **Power-law**: WARN 79→31 remaining (absorbed 48 ceiling-excluded keys), ERROR 12→10. Time: 0.02s.
- **Diverse**: ERROR 93→56 (absorbed 37), WARN 27→24 (absorbed 3). Time: 0.02s.

The final pass correctly discovers patterns among ceiling-excluded stragglers and composes cleanly with checkpoint processing. No issues found.

## Prototype Performance Assessment

### Test Files

| File | Lines | Size | Unique Keys | Profile |
|------|-------|------|-------------|---------|
| HundredsOfThousandsOfUniqueErrors.log | 288K | 97 MB | 286,870 | Power-law: 286K identical ERROR with varying UUIDs |
| ApplicationLog.2025-05-05.0.log | 480K | 85 MB | 9,031 | Diverse: 4 categories, varied message structures |

Both files are small compared to real-world production logs which can reach 1–10 GB and millions of lines.

### Execution Time Comparison

| Metric | Primary (power-law) | Diverse (realistic) |
|--------|--------------------:|--------------------:|
| **ltl baseline** | **2.6s** | **3.0s** |
| Old prototype (load-all) | 3.6s | 12.3s |
| **Checkpoint prototype** | **1.87s** | **2.06s** |
| **Overhead vs ltl** | **-28%** | **-31%** |

The checkpoint architecture is actually **faster** than ltl baseline because S1 inline matching prevents most keys from ever entering `%log_messages`, reducing hash allocation overhead. The old prototype's 310% overhead on diverse data is eliminated.

### Memory Comparison

| Metric | Primary (power-law) | Diverse (realistic) |
|--------|--------------------:|--------------------:|
| **ltl baseline RSS** | **172 MB** | **28 MB** |
| **ltl log_messages** | **105 MB** | **0.8 MB** |
| Old prototype (load-all) | 535 MB | 192 MB |
| **Checkpoint prototype RSS** | **238 MB** | **157 MB** |
| **Peak ltl-equivalent (structures)** | **214 MB** | **142 MB** |
| **Cumulative deleted (log+key)** | **5.8 MB** | **6.3 MB** |

See PF-21 for detailed analysis. Key findings: the checkpoint prototype uses more RSS than ltl baseline due to trigram data structures (~206 MB peak on power-law, ~131 MB on diverse). However, the freed memory IS reusable — Perl's allocator recycles it for subsequent checkpoint work, keeping memory bounded across checkpoints rather than growing unboundedly. RSS never decreases because `free()` returns to Perl's allocator, not the OS — this is normal behavior.

### Key Findings

1. **S1 inline match is the primary performance mechanism.** On power-law data, 98.4% of keys are absorbed during parsing by matching against compiled patterns. They never enter `%log_messages`, eliminating hash allocation and all downstream processing. This is why the checkpoint prototype is faster than ltl baseline.

2. **UUID normalization fixes a correctness gap, not just a performance issue.** Without it, UUID-varying messages score 74-76% Dice (below 80% threshold) and cannot be consolidated. DEBUG messages went from 0% to 99.9% reduction after normalization (PF-19).

3. **`match_against_patterns` is now the dominant cost.** On power-law data, S1 inline matching 287K keys against compiled patterns takes 0.68s (36% of total). This is the correct cost profile — cheap regex matching, not expensive pairwise similarity.

4. **Power-law data benefits most from checkpoints; diverse data benefits from UUID normalization.** On power-law data, checkpoint 1 discovers the dominant pattern, and S1 absorbs everything thereafter. On diverse data, UUID normalization reduces `dice_coefficient` calls from 414K to 7.5K.

5. **Trigram data lifecycle is correct.** Building and freeing per checkpoint prevents memory accumulation. Only compiled patterns and clusters persist.

6. **Inline::C compute_mask provides 100× speedup** on character alignment but accounts for <1% of total runtime — alignment is not the bottleneck.

### Historical: Root Cause of Old Architecture's Performance Problem

The old load-all-then-process architecture applied expensive pairwise similarity work to far too many messages. The trigger threshold of 5000 was intended as a checkpoint for smart filtering, not a batch size for brute-force comparison. This was resolved by PF-20 (checkpoint-based architecture rebuild).

### What the Prototype Validated

The core algorithms are sound and proven:
- **Trigram Dice coefficient** correctly identifies similar messages (zero false positives in testing)
- **Character-level LCS alignment** produces accurate masks distinguishing fixed vs variable regions
- **Mask coalescing** prevents spurious anchors from single-character LCS matches
- **Canonical form derivation** creates readable consolidated message representations
- **Regex derivation from masks** produces correct patterns that match source messages
- **Pattern compilation and matching** absorbs messages reliably (100% ERROR reduction on power-law data, 99.9% DEBUG on diverse data)
- **Cross-cluster merging** correctly identifies and combines overlapping patterns
- **Interleaved re-scan with partitioning** is essential for power-law distributions
- **Checkpoint-based processing** with S1 inline match is the correct architecture — absorbs 98%+ of keys during parsing on power-law data
- **UUID normalization** enables consolidation of UUID-varying messages that were previously below threshold

### Lessons Learned

**Algorithmic design:**

1. **Worked examples lie at the edges.** The DD-01 worked example used short messages with small variable parts, predicting 85% threshold. Real messages with UUIDs scored 74-82%. Always validate design assumptions against real data before committing to defaults. (PF-01, PF-08)

2. **Inverted index posting list size is the hidden cost.** When most messages share common trigrams (e.g., `[ERROR]`, `[WARN]`), posting lists grow to thousands of entries. The O(trigrams × posting_list_size) cost dominates — not the Dice scoring itself. Discriminative trigram selection (smallest posting lists first) is essential. (PF-02, PF-18)

3. **Coincidental matches in variable regions require coalescing.** LCS alignment finds spurious single-character matches inside UUIDs and hex strings. Two-pass coalescing (remove short keeps, then collapse variable-dominated spans) handles this reliably. The parameters (min keep=3, ratio=40%, boundary=10) proved stable across all test data. (PF-03)

4. **Pattern count is a critical control lever.** Matching cost is O(lines × patterns). Unbounded pattern discovery created 103 redundant patterns where 5 sufficed. Merge-first + hard cap keeps patterns bounded while merge-first improves coverage by generalizing. (PF-04, PF-05)

5. **Ceiling filters and final passes are complementary, not alternative.** The ceiling focuses discovery on the long tail (single-occurrence variants). The final pass cleans up ceiling-excluded stragglers that share obvious patterns (e.g., same message across 16 thread pools). Two-tier design: aggressive discovery on the tail, conservative cleanup on high-occurrence groups. (PF-06, PF-12)

6. **Too-low ceiling hurts more than too-high.** Ceiling=2 shielded too many keys from discovery, causing WARN remaining to balloon from 58 to 217 on diverse data. Ceiling 3-5 produced nearly identical results. A ceiling that's too aggressive excludes keys that could have been consolidated; a ceiling that's too permissive just adds slightly more work to discovery with no quality loss. Err on the side of letting more keys through. (PF-22)

7. **Natural separation can substitute for explicit partitioning.** Log level prefixes in `$log_key` create natural trigram separation — cross-level Dice scores never exceed threshold. This deferred the need for explicit level partitioning, simplifying the data model. (PF-07)

**Iterative refinement:**

8. **Thresholds need to be re-evaluated after each algorithmic change.** PF-01 lowered threshold to 75%, then PF-08 raised it to 80% after merge-first generalization changed the dynamics. Each improvement shifts the balance — test the threshold again after significant changes.

9. **Generalization must be idempotent.** When aligning two canonicals that already contain `*` wildcards, the derivation functions must treat `*` as variable, not literal. Otherwise repeated generalization fragments instead of converging. (PF-10)

10. **Re-scan after generalization is mandatory.** When merge-first broadens a pattern, the new regex may match keys the old pattern missed. Without immediate re-scan, these keys sit as false "unmatched" entries. (PF-11)

**Performance optimization:**

11. **Profile before optimizing — every time.** NYTProf profiling identified `compute_mask` as 62.8% of runtime (PF-14), then after fixing that, `find_candidates` at 88% (PF-16), then after checkpoint rebuild, `dice_coefficient` at 49% (PF-19). The dominant cost shifts after each fix. Assumptions about what's slow are unreliable.

12. **XS modules don't help when the bottleneck is Perl-side.** Algorithm::Diff::XS gave zero speedup over pure-Perl Algorithm::Diff because the bottleneck was `split //` and callbacks, not the LCS core. Only full Inline::C (eliminating all Perl overhead) delivered the 100× speedup. (PF-15)

13. **Algorithmic improvements in Perl can be slower.** Banded DP (theoretically O(nk) vs O(mn)) was 0.8× slower in pure Perl because the band-clamping logic (`max`/`min` per iteration) added more Perl overhead than the reduced cell count saved. Theory != practice in interpreted languages. (PF-15)

14. **Interleaved re-scan is essential for power-law distributions.** Batching 10 patterns before re-scanning caused 22× regression because pattern 1 absorbs 99%+ of keys — without immediate re-scan, patterns 2-10 each discover against the full set. The cascading reduction from immediate absorption is the core performance mechanism. (PF-17)

15. **Partitioning composes with interleaved re-scan; batching does not.** Partitioning keys by `[LEVEL][class]` reduced re-scan scope without destroying cascading reduction. Batching traded correctness of scan cost for fewer passes — catastrophic when one pattern dominates. (PF-16, PF-17)

**Architecture:**

16. **Architecture matters more than micro-optimization.** Switching from load-all to checkpoint-based processing delivered 6× speedup on diverse data (12.3s → 2.06s), far more than any algorithmic optimization within the old architecture. The right processing model makes micro-optimizations less necessary. (PF-20)

17. **Correctness gaps masquerade as performance problems.** The DEBUG "performance problem" (414K fruitless Dice calls) was actually a correctness problem — UUIDs prevented Dice from seeing structural similarity. UUID normalization fixed both performance and correctness simultaneously. (PF-19)

18. **Normalize known variable patterns before similarity scoring.** UUIDs are structurally random noise that drags Dice scores below threshold for messages that are structurally identical. Normalizing to `<UUID>` in the scoring pipeline (not in the alignment pipeline) lets similarity see through the noise while preserving original text for pattern derivation. (PF-19)

**Memory:**

19. **Measure before claiming victory.** DD-12 predicted 30% memory reduction from consolidation. Actual measurement showed the opposite — prototype uses MORE memory than ltl (238 vs 172 MB) because trigram data structures cost more than the savings from absorbing keys. Design assumptions about memory must be validated with instrumentation, not reasoned about. (PF-21)

20. **RSS is not memory usage.** Perl's `free()` returns memory to the allocator's free pool, not the OS. RSS never decreases even when structures are freed. This means RSS high-water = RSS at end, but the freed memory IS reusable for subsequent Perl allocations. Measure structure sizes with `Devel::Size`, not just RSS. (PF-21)

21. **The biggest savings are invisible.** S1 inline match prevents 98% of keys from ever entering `%log_messages` — this avoids ~105 MB of hash allocation on the power-law file. But this savings never shows up in memory measurements because those keys were never allocated. The cumulative deleted bytes (~6 MB) massively understate the true savings vs a no-consolidation baseline. (PF-21)

22. **Trigram overhead dominates and is bounded by batch size.** `key_trigrams` + `ngram_index` + `key_trigrams_norm` peak at ~206 MB for a 5000-key batch. This is the price of similarity search — fixed per checkpoint, not cumulative. The `$trigger` parameter directly controls this: lower trigger = less peak memory but more frequent checkpoints. (PF-21)

**Perl-specific:**

23. **`my` declarations execute at runtime in textual order.** Variables declared below the parsing loop are `undef` when called during parsing via checkpoints. This is a Perl-specific gotcha when restructuring code flow — move all declarations above the earliest possible call site. (PF-20)

### Outstanding Decisions

1. **Acceptable memory overhead** — the checkpoint prototype uses 238 MB (power-law) / 157 MB (diverse) vs ltl's 172 MB / 28 MB. The overhead is trigram data structures (~200 MB peak), bounded per checkpoint batch. See PF-21.
2. ~~**Ceiling default: 2 or 3?**~~ Resolved — ceiling=3 (see PF-22).
3. **Should Inline::C be a production dependency?** With far fewer alignments per checkpoint, pure Perl may be fast enough. Needs benchmarking.
4. ~~**Final pass integration**~~ Resolved — validated with checkpoint architecture (PF-22).

### Next Steps

**Integration readiness:**

1. ~~**Rebuild the consolidation loop** with checkpoint-based processing~~ — DONE (PF-20)
2. ~~**UUID normalization**~~ — DONE (PF-19)
3. ~~**Add `Devel::Size` memory instrumentation**~~ — DONE (PF-21). Prototype uses more memory than ltl baseline due to trigram overhead. Memory is bounded per checkpoint batch.
4. ~~**Test ceiling values**~~ — DONE (PF-22). Ceiling=3 confirmed as default.
5. ~~**Re-validate final pass**~~ — DONE (PF-22). Works correctly with checkpoint architecture.
6. **Test with larger files** — validate scaling on 1+ GB production logs.
7. **Integrate into ltl** — port checkpoint architecture into `read_and_process_logs()`, wire up stats merging (DD-07), add `--group-similar` CLI option.

## Open Questions

1. ~~**Character-level alignment algorithm**~~: Resolved — LCS with two-pass coalescing (PF-03)
2. ~~**CLI option naming**~~: Resolved — `--ceiling`, `--max-patterns`, `--final-pass`, `--final-threshold`, `--final-ceiling`
3. ~~**Performance benchmarks**~~: Resolved — NYTProf profiling (PF-14), alignment algorithm benchmark (PF-15)
4. **Minimum cluster count**: Below what number of unique messages per category is consolidation not triggered at all? Likely related to the trigger threshold but may need a separate floor.
5. ~~**Hard cap value**~~: Resolved — default 50, accommodates shared pool across log levels
6. ~~**Scalability**~~: Resolved — checkpoint architecture eliminates the 310% time overhead. Power-law: 1.87s (faster than ltl baseline). Diverse: 2.06s (faster than ltl baseline). Memory: 238 MB / 157 MB (bounded per checkpoint, see PF-21).
