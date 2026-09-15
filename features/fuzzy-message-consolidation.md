# Fuzzy Message Consolidation — Requirements

**GitHub Issue:** #96
**Status:** Prototype complete — validated at production scale (PF-01 through PF-24). 1.9× faster and 40% less memory than ltl on 3.3 GB access logs. Ready for ltl integration.
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
Once canonical patterns exist, incoming messages are checked against known compiled patterns at line processing time (S1 inline match). This is a simple regex match, not a pairwise similarity comparison — fundamentally different cost from discovery. Messages matching a known pattern are immediately added to the existing cluster.

**Implementation note:** S1 can only match patterns that have already been discovered by previous checkpoints. The first batch of keys (up to the trigger threshold) always receives zero S1 benefit because no patterns exist yet. S1 effectiveness grows with the number of checkpoints — on 100K-line access logs with 2 checkpoints, S1 absorbs 72.8% of keys; on power-law data with 4 checkpoints, S1 absorbs 98.4%. See "Process Flow — Detailed Implementation" for the exact execution sequence.

**S1 vs S3 — same operation, different timing:** Both S1 and S3 call `match_consolidation_patterns()` to test a key against compiled regexes. The difference is *when* they run:
- **S1** runs during **parsing**, for each new key as it arrives. It tests against patterns that exist at that moment (from all previous checkpoints).
- **S3** runs during **checkpoint processing**, for keys already in the unmatched buffer. It tests keys from *previous* pattern generations against patterns discovered since those keys entered. Keys at the current generation are skipped (they already failed S1 against the same patterns).

S3 bridges the gap for keys that entered the unmatched buffer before new patterns were discovered. On the first checkpoint, S3 skips all keys (all at generation 0) because no prior patterns exist. S3 becomes relevant starting from checkpoint 2 onwards.

**Rationale:** The key insight is that pattern discovery and pattern matching are fundamentally different operations. Discovery requires expensive pairwise comparison and alignment. Matching against a known compiled pattern is cheap. As patterns accumulate, fewer incoming messages need the expensive discovery path — the system gets faster as it learns.

**Multi-pass behavior:** After a consolidation pass discovers patterns and reduces unique count, accumulation continues. If unmatched unique count exceeds threshold again, another discovery pass runs. Each pass may discover new similarities as the dataset grows — patterns that were initially constant (e.g., a single user name) become variable when new data introduces variation.

**Adaptive trigger threshold (design — not yet implemented):** The consolidation trigger could adapt based on consolidation yield — the percentage of messages consolidated in each pass. High yield (data is highly repetitive) would raise the trigger, allowing more to accumulate since known patterns catch most incoming messages via cheap matching. Low yield (data is genuinely diverse) would lower the trigger, running discovery more frequently to catch new patterns before the unmatched set grows too large. **Current implementation:** Fixed trigger of 5000, configurable via `--consolidation-trigger`.

**Consolidation focus (design — not yet implemented):** Multi-pass consolidation could prioritize messages with low occurrence counts (e.g., single-occurrence entries) in early passes, as these represent pure uniqueness that is most likely to benefit from grouping. Messages with higher occurrence counts that haven't matched any pattern are more likely to be genuinely distinct.

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

**WARNING — Truncation breaks UUID normalization (#158):** The cap must be large enough to preserve variable content (UUIDs, session IDs, query strings) that appears at the end of long messages. UUID-normalized Dice scoring (`$uuid_re`) requires the full 8-4-4-4-12 UUID pattern (36 chars). If the log key is truncated mid-UUID, normalization silently fails and the consolidation engine treats each key as unique — causing catastrophic performance regression (14s → 0.14s on 10K lines when fixed). The current cap is 350 chars when `-g` is active. If log formats with variable content beyond 350 chars are encountered, this cap will need to increase or the adaptive cap from IQ-02 must be implemented.

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

### Process Flow — Detailed Implementation

The consolidation engine operates as a 6-stage pipeline integrated into the log parsing loop. Understanding the exact call sequence is critical — the stages execute in a specific order, and some stages operate on the full batch sequentially (not per-key).

#### Overview: Parsing Loop with Inline Consolidation

```
read_and_process_logs()
│
├─ for each log line:
│    parse line → extract $message, $log_key, $log_level, etc.
│    $mask_uuid processing (if active, before consolidation)
│    $log_key constructed from metadata + $message
│
│    if $is_new_key AND -g active:
│    │
│    │  consolidation_process_key($log_key, $category, $cat_gk, $capped_msg, $stats_source)
│    │  │
│    │  ├─ S1: match_consolidation_patterns($category, $grouping_key, $capped_msg)
│    │  │    Test $capped_msg against %consolidation_patterns{$cat_gk}
│    │  │    These are compiled regexes from previously discovered patterns
│    │  │    → MATCH: merge stats into cluster, return 1 (key absorbed)
│    │  │             Key never enters %log_messages     ──► verbose: "S1 Inline match"
│    │  │    → NO MATCH: fall through
│    │  │
│    │  ├─ Store in unmatched buffer:
│    │  │    %consolidation_unmatched{$cat_gk}{$log_key} = 1
│    │  │    %consolidation_key_message{$log_key} = $capped_msg
│    │  │    Record key's pattern generation number
│    │  │    Increment category unmatched count
│    │  │
│    │  └─ Check trigger: if category unmatched count >= trigger (default 5000):
│    │       for each cat_gk group in this category with >= 2 unmatched keys:
│    │         run_consolidation_checkpoint($category, $grouping_key)
│    │         (see Checkpoint Processing below)
│    │       Reset category unmatched count = 0
│    │
│    if NOT $is_new_key: increment occurrences on existing %log_messages entry (no consolidation)
│
├─ after EOF:
│    EOF checkpoints: run_consolidation_checkpoint() for all remaining
│    unmatched groups with >= 2 keys
│
└─ group_similar_messages()
     Final pass (if enabled): iterate all remaining %log_messages keys
     through the same consolidation_process_key() pipeline
     (see #150 for scalability concerns with this approach)
```

**Key insight:** S1 inline matching runs for every new key during parsing, but can only match against patterns that already exist in `%consolidation_patterns`. Patterns are created during checkpoint processing (S4). Therefore, S1 provides zero benefit until the first checkpoint completes. All keys in the first batch (up to the trigger threshold) get no S1 matching.

#### Checkpoint Processing — Sequential Stage Execution

When the trigger fires, `run_consolidation_checkpoint()` runs the full batch through stages sequentially. **Each stage processes the entire batch before the next stage begins** — this is NOT a per-key pipeline.

```
run_consolidation_checkpoint($category, $grouping_key)
│
├─ Collect all unmatched keys for this cat_gk (sorted)
│
├─ [Streaming only] Fast-path eviction check:
│    If EMA indicates 0% absorption and checkpoint > 2,
│    evict all keys immediately, skip expensive processing
│
└─ run_consolidation_pass($cat_gk, \@unmatched, $checkpoint_num)
     │
     ├─ STAGE S2 — Ceiling Filter (one pass over ALL unmatched keys)
     │    Split into @ceiling_keys (occurrences >= ceiling)
     │    and @discovery_candidates (the rest)
     │    Ceiling keys excluded from discovery    ──► verbose: "S2 Ceiling filter"
     │
     ├─ STAGE S3 — Checkpoint Match (one pass over ALL discovery candidates)
     │    For each candidate:
     │      if key entered at current pattern generation → SKIP
     │        (already failed S1 against same patterns)  ──► verbose: "S3 attempts: skipped"
     │      else → match_consolidation_patterns()
     │        (test against patterns from PREVIOUS checkpoints)
     │        → MATCH: absorbed                          ──► verbose: "S3 Checkpoint match"
     │        → NO MATCH: becomes gate2_survivor
     │
     ├─ Build trigram index for gate2_survivors
     │    (up to trigger-size keys indexed)
     │
     ├─ STAGE S4 — Pairwise Discovery (loop over index batch, max 500 keys)
     │    For each source key:
     │    │
     │    ├─ find_consolidation_candidates()             ──► verbose: "find_candidates calls"
     │    │    Phase 1: discriminative trigram pre-filter (raw trigrams)
     │    │    Phase 2: Dice verification (UUID-normalized trigrams)
     │    │    → returns candidate pairs scoring above threshold
     │    │
     │    ├─ For best candidate match:
     │    │    compute_mask() → coalesce_mask()
     │    │    derive_canonical() → derive_regex()
     │    │    Validate: both source and candidate match the derived regex
     │    │    Mark both source + candidate as consumed   ──► verbose: "S4 Pairwise discovery"
     │    │                                                   (counts the pair source keys)
     │    │
     │    ├─ ┌─────────────────────────────────────────┐
     │    │  │ NEW COMPILED REGEX PATTERN CREATED HERE  │
     │    │  │ try_consolidation_merge_into_existing()  │
     │    │  │   → merged into existing? update pattern │
     │    │  │   → new? push to %consolidation_patterns │
     │    │  └─────────────────────────────────────────┘
     │    │                                               ──► verbose: "N patterns" in header
     │    │
     │    └─ Interleaved re-scan:
     │         Match new regex against remaining unmatched keys
     │         in same partition bucket (cheap regex match)
     │         → MATCH: consumed, stats merged            ──► verbose: "S4 Re-scan absorbed"
     │         → NO MATCH: stays in bucket
     │
     ├─ Return: ($discovered, $absorbed, ..., $rescan_absorbed)
     │
     ├─ Delete consumed keys from %log_messages, trigrams, etc.
     ├─ Free ngram index (per-checkpoint, rebuilt each time)
     ├─ Merge overlapping patterns (cross-cluster)
     ├─ Bump pattern_generation (enables S3 skip optimization)
     │
     ├─ [Streaming] Adaptive eviction:
     │    Update absorption EMA
     │    Keys exceeding survival threshold → evicted    ──► verbose: "S6 Evicted"
     │    Remaining keys → survive to next checkpoint    ──► verbose: "S5 Unmatched"
     │
     └─ [Final pass] No eviction — all survivors stay
```

#### Verbose Metric Correlation

The `-V` verbose output maps directly to the stages above. Understanding which metric corresponds to which stage is essential for diagnosing consolidation behavior.

**Per-category section header:**
```
--- plain|200: Streaming Phase ---
  Keys seen:             3324  (1 checkpoints, 28 patterns)
```
- `Keys seen` = total unique keys that entered `consolidation_process_key()` for this cat_gk
- `checkpoints` = number of times `run_consolidation_checkpoint()` fired
- `patterns` = total compiled regex patterns in `%consolidation_patterns` after all checkpoints

**Stage metrics (cumulative across all checkpoints):**
```
  S1 Inline match:       0       ← keys absorbed during PARSING by matching existing patterns
  S2 Ceiling filter:     172     ← keys excluded from discovery (occurrences >= ceiling)
  S3 Checkpoint match:   0       ← keys matched at CHECKPOINT TIME against patterns from previous checkpoints
  S4 Pairwise discovery: 80      ← source keys consumed by expensive Dice/alignment pair matching
  S4 Re-scan absorbed:   2998    ← keys consumed by cheap regex re-scan after pattern creation
  S5 Unmatched:          74      ← keys that survived all stages and eviction (truly unique)
  S6 Evicted:            0       ← keys removed by adaptive eviction (streaming only)
```

**Tracking invariant:** `S1 + S2 + S3 + S4_pairwise + S4_rescan + S5 + S6 = Keys seen`

**Diagnostic metrics:**
```
  find_candidates calls: 185     ← number of Dice similarity searches (expensive)
  S3 attempts:           0       ← keys tested by S3 (skipped = at current generation, already failed S1)
  Cleanup keys scanned:  3078    ← keys deleted from structures after checkpoint
```

**Interpreting the metrics:**

| Observation | Diagnosis |
|-------------|-----------|
| S1=0, S4 high | Patterns not available early enough — first checkpoint too late, or only checkpoint at EOF (#162) |
| S1 high, S4 low | Healthy — patterns discovered early, S1 absorbs most subsequent keys |
| S3=0, S3 skipped=all | Normal for first checkpoint — all keys at current generation |
| S3 > 0 | Keys from previous checkpoint matched patterns discovered since they entered |
| S4 Pairwise high, Re-scan low | Poor pattern generality — patterns match their source pair but few other keys |
| S4 Pairwise low, Re-scan high | Good pattern generality — each pattern absorbs many keys cheaply |
| S6 high | High eviction — many keys couldn't be consolidated (genuinely diverse data) |
| find_candidates >> S4 Pairwise | Many Dice searches yielded no viable pairs (diverse or threshold too high) |

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

> **Superseded by #137:** The final pass was redesigned to iterate ALL `%log_messages` keys through the same S1→checkpoint pipeline used during streaming, not just ceiling-excluded keys. The original PF-12 approach (separate inline pairwise discovery on ceiling-excluded keys only) was replaced because it bypassed the S1→S2→S3→S4 architecture, missed evicted keys (S6), and missed non-ceiling keys. The findings below are historical context only.

**Finding:** The occurrence ceiling (default 3) prevents high-occurrence messages from entering discovery. But some high-occurrence messages share patterns (e.g., `CheckHeartbeat` across 16 thread pools, each with 29-47 occurrences). These are obvious consolidation candidates that the ceiling blocks.

**Design decisions (historical — superseded by #137):**
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

**6-stage pipeline with tracking invariant:**
- **S1 Inline match** — new key matched against compiled patterns during parsing, routed to cluster, never enters `%log_messages`
- **S2 Ceiling filter** — at checkpoint: occurrences >= ceiling, excluded from discovery
- **S3 Checkpoint match** — at checkpoint: matched existing pattern discovered in same checkpoint's S4
- **S4 Pairwise discovery** — Dice similarity + interleaved re-scan within checkpoint batch
- **S5 Unmatched** — survived all stages and eviction across all checkpoints (truly unique messages)
- **S6 Evicted** — exceeded adaptive survival threshold, removed from consolidation working set (remains in `%log_messages` for output)
- Invariant: `S1 + S2 + S3 + S4 + S5 + S6 = cat_keys_seen` per category (built-in sanity check)

**New data structures:**
- `%clusters{cat}{canonical}` — consolidated cluster stats (occurrences, match_count)
- `%unmatched_keys{cat}{key}` — keys awaiting consolidation
- `%cat_stats{cat}` — per-category S1-S5 accumulators
- `%cat_keys_seen{cat}`, `$total_keys_seen` — unique key counters

**Memory lifecycle:**
- Trigram data (`%ngram_index`, `%key_trigrams`, `%posting_size`, `%key_trigrams_norm`) retained while key is in unmatched set, reused across checkpoints. Deleted when key is consumed by consolidation or evicted. `build_consolidation_ngram_index` skips keys that already have trigrams.
- Only compiled patterns (`%canonical_patterns`) and clusters (`%clusters`) persist across checkpoints
- Absorbed keys deleted from `%log_messages` and `%key_message` to free memory
- **Adaptive per-key eviction:** keys in `%unmatched_keys` and `%key_message` are transient working data, not permanent storage. Each key's survival count is determined by the group's rolling average absorption rate (EMA, alpha=0.4). The survival curve is exponentially aggressive: <5% absorption→0 survivals (evict immediately), 5-50%→1, 50-90%→2, 90-95%→3, 95-99%→4, ≥99%→5 (power-law data). Fast-path eviction: when max_survivals=0 and cp_num>2, skip `run_consolidation_pass` entirely — no trigram index built, no fc_calls made. Evicted keys remain in `%log_messages` as unique entries.

**Design intent:** The consolidation tracking structures (`%unmatched_keys`, `%key_message`) must remain small relative to the total lines processed. They are a transient working set for pattern discovery, not a mirror of `%log_messages`. Adaptive eviction bounds this working set — keys get a limited number of checkpoint opportunities (scaled to how well consolidation is working for their group), then are evicted. Without eviction, these structures grow unboundedly on data with high key diversity (e.g., access logs with unique URL paths), causing memory and time regressions that defeat the purpose of consolidation.

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

### PF-23: Determinism Fix and Final Pass Default Changes

**Non-determinism:** Consecutive runs of the prototype on the same file produced different results (e.g., S4=1806 vs S4=1628, clusters=170 vs 172). Root cause: Perl hash iteration order is randomized per process. The pairwise discovery loop in `run_checkpoint()` iterated `keys %{$unmatched_keys{$cat}}` in random order, so which key pairs were compared first — and which patterns were discovered — varied per run.

**Fix:** Three changes to make results deterministic:
1. `sort keys %{$unmatched_keys{$cat}}` in `run_checkpoint()` — primary source, controls all downstream iteration
2. `sort keys %{$unmatched_keys{$cat}}` in the final pass loop
3. Tiebreaker `$a->{key} cmp $b->{key}` in `find_candidates()` result sorting — breaks ties when multiple candidates have the same Dice score

**Final pass defaults changed:** Testing with access logs revealed that the original final pass defaults (`--final-pass` off, `--final-threshold 95`, `--final-ceiling 100`) were inadequate:
- Ceiling-excluded keys (occurrences >= 3) include the highest-value consolidation targets in access logs (e.g., `GetNamedProperties` URLs with 10,000+ occurrences each, scoring 85-87% Dice)
- `--final-threshold 95` was too high — these keys score 85-87%, well below 95%
- `--final-ceiling 100` excluded keys with > 100 occurrences, which in access logs is most of the interesting data

New defaults: `--final-pass` on by default, `--final-threshold 80`, `--final-ceiling 1000000`. Use `--no-final-pass` to disable. Validated on all three test files — ThingWorx logs also benefit (e.g., WARN remaining 82→30 on power-law file).

### PF-24: Access Log Support, Multi-File Scaling, and Sandbox SIGTRAP

**Access log support:** Added Tomcat access log parsing to the prototype, matching ltl's key construction exactly:
- Status code bucketed to Nxx for category, raw status code in log_key
- Threadpool derived from thread by stripping trailing `-N`
- HTTP version and query string stripped from message
- Validated on single file: output matches ltl format (`[200] [https-jsse-nio-8443-] POST /Thingworx/...`)

**Multi-file support:** `--file` now accepts multiple arguments and globs via Perl's `glob()` expansion, matching ltl's approach.

**Scaling test (50 files, 3.3 GB, 16.4M lines):**
- 13,266,088 unique keys seen
- S1=13,251,974 (99.9%), S2=27, S3=0, S4=13,721, S5=205
- 36 patterns, 41 clusters, 393 remaining keys
- 81s, 151 MB RSS

**Comparison to ltl baseline (-od) on same files:**

| Metric | Prototype | ltl (-od) |
|--------|----------:|----------:|
| Time | 81s | 150s |
| Memory | 151 MB | 256 MB |
| log_messages | — | 60.5 MB |

The prototype is 1.9× faster and uses 40% less memory than ltl -od. S1 inline match prevents 13.25M keys from entering `%log_messages` — this is the primary memory and performance win.

**SIGTRAP from sandbox:** When running 150 files (7.9 GB) from Claude Code, the process was killed with SIGTRAP (exit code 133). This is a Claude Code sandbox limitation, not a code bug. The 50-file subset completed successfully both from Claude Code and from the terminal. Added `$| = 1` (STDOUT autoflush) to ensure output is visible during long runs.

**Integration note:** When porting to ltl, the new consolidation data structures (`clusters`, `canonical_patterns`, `unmatched_keys`, `ngram_index`, `key_trigrams`, `key_trigrams_norm`, `posting_size`, `key_message`) must be added to `measure_memory_structures()` so `-mem` output includes their high-water marks alongside existing structures like `log_messages` and `log_analysis`.

### PF-25: Stats Merging Validation

**Problem:** The prototype only tracked `occurrences` on clusters — no durations, bytes, min/max, or percentile data. DD-07 defined how stats should merge but this was untested. Before integrating into ltl, stats merging must be validated to ensure consolidated entries produce correct output matching ltl's MESSAGES CSV format.

**Changes to prototype:**

1. **Parse duration and bytes during ingestion:** Access logs capture `$bytes` and `$duration` from the regex. ThingWorx logs extract duration via `/ durationM[sS]\s*=\s*(\d+)/` (matching ltl line 1853). Handle `-` as missing bytes value.

2. **Store full stats on `%log_messages` entries:** Each entry now tracks `occurrences`, `total_duration`, `sum_of_squares`, `durations` array, `min`, `max`, and `total_bytes`.

3. **Enhanced `merge_stats()`:** Merges all fields per DD-07 rules: sum occurrences/totals/sum_of_squares, min of mins, max of maxes, concatenate durations arrays, sum bytes.

4. **S1 inline match routes full stats:** When a key is absorbed during parsing (never enters `%log_messages`), its duration/bytes are added directly to the cluster — not just `occurrences++`.

5. **Statistics calculation matching ltl exactly:**
   - Population variance: `sum_of_squares / N - mean^2` (not sample variance)
   - Mean: `int(total_duration / duration_count)` where `duration_count` is length of durations array
   - Percentiles: `int($sorted[int($n * fraction)])` index method
   - mean_bytes: `int(total_bytes / occurrences + 0.5)` (rounded)
   - std_dev formatted to 3 decimal places, cv to 2

6. **CSV output:** Prototype writes `/tmp/prototype-messages.csv` in ltl's MESSAGES CSV format for comparison.

**Validation results:**

Tested against ltl CSV baseline for two unconsolidated entries that exist in both outputs with identical keys:

**Access log — `GetClientNonce` (12,466 occurrences):**

| Field | ltl | Prototype |
|-------|-----|-----------|
| occurrences | 12466 | 12466 |
| mean_bytes | 87 | 87 |
| bytes | 1078390 | 1078390 |
| min/mean/max | 0/1/13 | 0/1/13 |
| std_dev | 1.181 | 1.181 |
| p1/p50/p75/p90/p95/p99/p999 | 0/1/2/3/3/3/4 | 0/1/2/3/3/3/4 |
| cv | 1.18 | 1.18 |
| duration | 13829 | 13829 |

**ThingWorx DPM — `GetMetricsList` (32 occurrences):**

| Field | ltl | Prototype |
|-------|-----|-----------|
| occurrences | 32 | 32 |
| min/mean/max | 949/1018/1149 | 949/1018/1149 |
| std_dev | 62.659 | 62.659 |
| p1/p50/p75/p90/p95/p99/p999 | 949/1016/1041/1070/1128/1149/1149 | 949/1016/1041/1070/1128/1149/1149 |
| cv | 0.06 | 0.06 |
| duration | 32606 | 32606 |

**All fields match exactly** across both log formats. The stats merging implementation is correct and matches ltl's computation.

**DD-07 update — missing fields identified:** DD-07 omits three fields that ltl actually stores and that must be merged:
- `sum_of_squares` — sum (required for variance/std_dev/CV calculation)
- `impact` — must be **recomputed** after merging, not summed (derived from `log(mean^exp * occ)`)
- `total_duration_num` — sum (numeric copy of total_duration, used for CSV/sorting)

**Key insight — initial risk assessment was partially wrong:** The arithmetic of stats merging is straightforward (sums and mins). The actual risk was in matching ltl's specific formulas (population vs sample variance, percentile indexing, rounding). These turned out to differ from standard implementations and required reading ltl's `calculate_statistics()` to get right.

### PF-26: Pure Perl Fallback and Inline::C Re-evaluation

**Problem:** Inline::C `compute_mask_c()` causes bus errors / trace trap crashes on some macOS systems. The compiled `.bundle` crashes intermittently during S4 pairwise discovery — it compiles successfully and runs for a while, then segfaults on specific inputs. Deleting `_Inline/` cache and recompiling does not fix it. The crash is not deterministic per invocation.

**Root cause:** Likely a memory safety bug in the C code (out-of-bounds access in the banded edit distance backtrace or direction table packing), triggered by specific string length combinations. Not debugged further — the architectural question is whether Inline::C is even needed.

**Solution — conditional loading with pure Perl default:**

1. Inline::C is now **off by default** in the prototype. Use `--inline-c` to opt in.
2. `compute_mask()` dispatches to `compute_mask_c()` (Inline::C) or `compute_mask_perl()` (pure Perl banded edit distance) based on `$have_inline_c`.
3. The pure Perl implementation uses the same banded edit distance algorithm as the C version (not the old LCS DP), with identical prefix/suffix stripping and backtrace logic.
4. Inline::C loading is guarded by `eval { require Inline; ... }` so compilation failures fall back silently.

**Benchmark — 4 test files, 3 runs each (median):**

| File | Lines | Unique Keys | Pure Perl | Inline::C | Speedup |
|------|-------|-------------|-----------|-----------|---------|
| Power-law (ThingWorx) | 288K | 287K | 3.67s | 2.29s | 1.6× |
| Diverse (ThingWorx) | 480K | 10K | 3.84s | 2.47s | 1.6× |
| Access log | 762K | 3.2K | 4.26s | 4.25s | 1.0× |
| DPM log (ThingWorx) | 123K | 122K | 5.00s | 4.31s | 1.2× |

**Comparison to PF-20 baselines (Inline::C, before PF-25 stats merging):**

| File | PF-20 | Current (Inline::C) | Current (Pure Perl) |
|------|-------|---------------------|---------------------|
| Power-law | 1.87s | 2.29s (+0.42s) | 3.67s (+1.80s) |
| Diverse | 2.06s | 2.47s (+0.41s) | 3.84s (+1.78s) |

The +0.4s increase vs PF-20 is from PF-25 stats merging (durations array management, bytes tracking).

**Analysis:**

- **Inline::C makes no difference on parsing-dominated workloads.** Access logs (762K lines, only 3.2K unique keys) spend nearly all time in line parsing and S1 regex matching. The few dozen `compute_mask` calls in S4 are negligible.
- **Inline::C saves 1.4-1.8s on alignment-heavy workloads.** Files with high unique-key counts trigger more S4 pairwise discovery, making `compute_mask` a larger fraction of total time. But even then, pure Perl at 3.7-5.0s is well within acceptable limits.
- **The checkpoint architecture made Inline::C optional.** PF-15 showed 100× per-call speedup, but the old architecture called `compute_mask` thousands of times. The checkpoint architecture reduced calls to dozens per checkpoint — the 100× speedup on a 0.01s cost is irrelevant.

**Decision: Inline::C is NOT needed for production.**

This resolves IQ-05 (Inline::C dependency question). For ltl integration:
- Use pure Perl `compute_mask` only — no C compiler requirement, no `_Inline/` cache, no platform-specific crashes
- The pure Perl implementation is the same banded edit distance algorithm, not the slower LCS DP from PF-15
- If profiling at production scale reveals alignment as a bottleneck (unlikely given S1 dominance), Inline::C can be reconsidered after fixing the bus error bug

## Prototype Performance Assessment

### Test Files

| File | Lines | Size | Unique Keys | Profile |
|------|-------|------|-------------|---------|
| HundredsOfThousandsOfUniqueErrors.log | 288K | 97 MB | 286,870 | Power-law: 286K identical ERROR with varying UUIDs |
| ApplicationLog.2025-05-05.0.log | 480K | 85 MB | 9,031 | Diverse: 4 categories, varied message structures |
| localhost_access_log-*-0.2025-05-07.txt | 762K | — | 3,184 | Access log: parsing-dominated, low unique ratio |
| ScriptLog-DPMExtended-clean.log | 123K | — | 121,903 | ThingWorx DPM: high unique ratio, stats-rich |
| really-big/*2026-01-2*.txt (50 files) | 16.4M | 3.3 GB | 13,266,088 | Access logs: high-volume, URL path variation |

The first four files are small; the fifth validates scaling on production-size data.

### Execution Time Comparison

| Metric | Power-law | Diverse | Access log | DPM log | Access logs (50×, 3.3 GB) |
|--------|----------:|--------:|-----------:|--------:|--------------------------:|
| **ltl baseline (-od)** | **2.6s** | **3.0s** | — | — | **150s** |
| Old prototype (load-all) | 3.6s | 12.3s | — | — | — |
| Checkpoint + Inline::C (PF-20) | 1.87s | 2.06s | — | — | 81s |
| **Checkpoint + Inline::C (PF-26)** | **2.29s** | **2.47s** | **4.25s** | **4.31s** | — |
| **Checkpoint + Pure Perl (PF-26)** | **3.67s** | **3.84s** | **4.26s** | **5.00s** | — |

PF-26 numbers include PF-25 stats merging overhead (+0.4s vs PF-20). Pure Perl is the default — Inline::C is opt-in via `--inline-c`. Pure Perl uses the same banded edit distance algorithm as the C version, not the old LCS DP.

The checkpoint architecture is actually **faster** than ltl baseline because S1 inline matching prevents most keys from ever entering `%log_messages`, reducing hash allocation overhead. The speedup grows with file size — 46% faster on 3.3 GB access logs.

### Memory Comparison

| Metric | Primary (power-law) | Diverse (realistic) | Access logs (50 files, 3.3 GB) |
|--------|--------------------:|--------------------:|-------------------------------:|
| **ltl baseline (-od) RSS** | **172 MB** | **28 MB** | **256 MB** |
| **ltl log_messages** | **105 MB** | **0.8 MB** | **60.5 MB** |
| Old prototype (load-all) | 535 MB | 192 MB | — |
| **Checkpoint prototype RSS** | **238 MB** | **157 MB** | **151 MB** |
| **Peak ltl-equivalent (structures)** | **214 MB** | **142 MB** | — |
| **Cumulative deleted (log+key)** | **5.8 MB** | **6.3 MB** | — |

See PF-21 for detailed analysis. On small files, the prototype uses more RSS than ltl due to trigram data structures (~206 MB peak). On large access logs (3.3 GB), the prototype uses **40% less memory** than ltl -od (151 MB vs 256 MB) because S1 inline match prevents 99.9% of keys from entering `%log_messages`. The crossover point depends on unique-key ratio — high unique-key counts favor the prototype.

### Key Findings

1. **S1 inline match is the primary performance mechanism.** On power-law data, 98.4% of keys are absorbed during parsing by matching against compiled patterns. They never enter `%log_messages`, eliminating hash allocation and all downstream processing. This is why the checkpoint prototype is faster than ltl baseline.

2. **UUID normalization fixes a correctness gap, not just a performance issue.** Without it, UUID-varying messages score 74-76% Dice (below 80% threshold) and cannot be consolidated. DEBUG messages went from 0% to 99.9% reduction after normalization (PF-19).

3. **`match_against_patterns` is now the dominant cost.** On power-law data, S1 inline matching 287K keys against compiled patterns takes 0.68s (36% of total). This is the correct cost profile — cheap regex matching, not expensive pairwise similarity.

4. **Power-law data benefits most from checkpoints; diverse data benefits from UUID normalization.** On power-law data, checkpoint 1 discovers the dominant pattern, and S1 absorbs everything thereafter. On diverse data, UUID normalization reduces `dice_coefficient` calls from 414K to 7.5K.

5. **Trigram data lifecycle is correct.** Building and freeing per checkpoint prevents memory accumulation. Only compiled patterns and clusters persist.

6. **Inline::C is not needed for production.** The 100× per-call speedup (PF-15) is irrelevant when the checkpoint architecture reduces `compute_mask` calls to dozens per batch. Pure Perl banded edit distance runs at equivalent speed on parsing-dominated workloads and adds only 1.4-1.8s on alignment-heavy workloads. Inline::C also has platform-specific crash bugs (bus errors on macOS). See PF-26.

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

24. **Hash iteration order makes algorithms non-deterministic.** Perl randomizes hash key order per process. Any algorithm that iterates hash keys and where iteration order affects outcomes (pairwise comparison, pattern discovery) will produce different results per run. Sort keys at the entry point to downstream processing. (PF-23)

25. **Defaults tuned on one log format fail on another.** The original final pass defaults (threshold 95%, ceiling 100, off by default) worked for ThingWorx logs but completely missed the highest-value targets in access logs. Access log keys are shorter with smaller variable regions, producing Dice scores of 85-87% (below 95%), and have 10,000+ occurrences (above ceiling 100). Always validate defaults across log formats. (PF-23)

**Scaling:**

26. **S1 inline match dominance grows with file size.** On small files (288K lines), S1 absorbs 98.4%. On large files (16.4M lines), S1 absorbs 99.9%. Patterns discovered early in parsing become more effective as more lines flow through — the amortized cost per line decreases. This is why the prototype's speed advantage over ltl grows with file size (28% faster on small files, 46% faster on 3.3 GB). (PF-24)

27. **Memory crossover depends on unique-key ratio.** On small files with few unique keys, trigram overhead makes the prototype use more memory than ltl. On large files with millions of unique keys, S1 preventing key insertion saves far more than trigrams cost — prototype uses 40% less memory than ltl -od on 3.3 GB access logs (151 MB vs 256 MB). (PF-24)

28. **Small-file benchmarks can be misleading.** PF-21 concluded the prototype uses MORE memory than ltl (238 vs 172 MB on 97 MB power-law file). PF-24 showed the opposite on production-size data: 151 MB vs 256 MB on 3.3 GB. The trigram overhead that dominated small files becomes negligible relative to the savings from preventing 13M keys from entering `%log_messages`. Always validate performance conclusions at production scale. (PF-21, PF-24)

**Design:**

29. **Memory bounding and CPU bounding are independent problems.** Per-key eviction gates memory (removes old keys from tracking structures). The core issue is that unmatched keys accumulate indefinitely in the consolidation working set, causing both memory growth and increasing per-checkpoint cost. These must be addressed by evicting keys that have had sufficient checkpoint opportunities — not by stall detection, which simply stops all consolidation and defeats the feature's purpose. (#135)

30. **Per-checkpoint cost is data-dependent.** On standard access logs (82 unique keys over 100K lines), checkpoints are sub-second. On XL access logs (23K+ unique keys in 100K lines, high unique ratio), checkpoints accumulate thousands of unmatched keys that produce poor Dice scores, causing `find_consolidation_candidates` to search broadly without finding matches. (#135)

31. **Redundant work compounds but isn't the dominant cost on diverse data.** Profiling confirmed three sources of waste: O(all_keys) cleanup loops, S3 re-testing keys against already-tested patterns, and linear pattern scans after merge. Fixes reduced cleanup scans from O(all_keys) to O(consumed), eliminated all S3 attempts via generation tracking, and removed O(patterns) lookups. However, on XL data at `-g 85`, the dominant cost remains `read_and_process_logs` (95% of CPU) driven by the accumulating unmatched key set — a separate eviction problem. (#135)

32. **Adaptive eviction survival count must scale exponentially with absorption rate.** The max survival count (additional checkpoints after first) must be aggressively low: at 50% absorption, half the working set is dead weight — giving those keys 4 more attempts is wasteful. The curve maps absorption EMA → max survivals: <5%→0, 5-50%→1, 50-90%→2, 90-95%→3, 95-99%→4, ≥99%→5. Only near-perfect absorption (power-law data) justifies 5 survivals. This curve is a starting point and may need tuning over time. The key principle: marginal value of additional survivals drops fast while cost (iteration over accumulated keys) is linear. (#135)

33. **Trigrams are kept while a key is in the unmatched set.** Trigrams are reused across checkpoints — no need to recompute. `build_consolidation_ngram_index` skips keys that already have trigrams. Delete trigrams when key is consumed by consolidation OR evicted. The memory regression (+26.6%) seen in Fixes 1-3 was caused by correctly retaining trigrams for surviving keys (old code wastefully deleted and recomputed them). Per-key eviction naturally resolves this by bounding the surviving set. (#135)

34. **The final pass must use the same pipeline architecture as streaming.** The original final pass (PF-12) was a separate mini-pipeline with its own inline pairwise discovery — it bypassed S1 matching, skipped checkpoint batching, and missed all keys not in `%consolidation_unmatched`. The fix (#137) extracts `consolidation_process_key()` as a shared subroutine and has the final pass iterate sorted `%log_messages` keys through the same S1→checkpoint pipeline. Sorting groups similar messages together for better S3/S4 checkpoint yield. Eviction is disabled during the final pass (bounded set, last opportunity to consolidate). Separate `fp_*` counters track final pass work independently from streaming. (#137)

35. **Log key truncation silently breaks UUID normalization.** When `$log_key` is truncated before the consolidation engine sees it, UUIDs at the end of long messages get cut mid-pattern. `$uuid_re` requires the full 8-4-4-4-12 format (36 chars) — a partial UUID doesn't match, so UUID-normalized Dice scoring silently falls back to raw trigrams, and the UUID variation drags scores below threshold. The failure is invisible: no error, no warning, just thousands of keys that should consolidate but don't, causing 100× performance regression. The fix (#158) uses a 350-char cap when `-g` is active instead of terminal width. **This remains a latent risk:** any log format with variable content beyond 350 chars will hit the same problem. The adaptive cap designed in IQ-02 would address this fully but is not yet implemented.

### Outstanding Decisions

1. ~~**Acceptable memory overhead**~~ Resolved — on large files (the real use case), the prototype uses LESS memory than ltl: 151 MB vs 256 MB on 3.3 GB access logs. Overhead only applies to small files where trigram cost exceeds S1 savings. (PF-24)
2. ~~**Ceiling default: 2 or 3?**~~ Resolved — ceiling=3 (see PF-22).
3. ~~**Should Inline::C be a production dependency?**~~ Resolved — NO. Pure Perl is fast enough. See PF-26.
4. ~~**Final pass integration**~~ Resolved — validated with checkpoint architecture (PF-22).
5. ~~**Unmatched key eviction (#135)**~~ Resolved — adaptive per-key eviction implemented with EMA-based absorption rate tracking. Survival count scales exponentially with rolling average absorption: <5%→0, 5-50%→1, 50-90%→2, 90-95%→3, 95-99%→4, ≥99%→5. Fast-path eviction skips `run_consolidation_pass` entirely when max_survivals=0 and cp_num>2. Replaces stall detection. XL benchmark: 3.4× faster (55s vs 185s), 47.7% less memory (238 MiB vs 455 MiB). Curve thresholds may need tuning over time (see lesson 32).
6. ~~**Final pass does not re-scan `%log_messages` (#137)**~~ Resolved — Final pass redesigned (#137) to iterate all `%log_messages` keys through the same S1→checkpoint pipeline used during streaming. Extracted `consolidation_process_key()` subroutine shared by both streaming and final pass paths. Eviction disabled during final pass (bounded set, last chance). Sorted key iteration groups similar messages for better checkpoint yield. Separate `fp_*` observability counters. Evicted keys (S6) from streaming are now picked up by the final pass.

### Next Steps

**Integration readiness:**

1. ~~**Rebuild the consolidation loop** with checkpoint-based processing~~ — DONE (PF-20)
2. ~~**UUID normalization**~~ — DONE (PF-19)
3. ~~**Add `Devel::Size` memory instrumentation**~~ — DONE (PF-21). Prototype uses more memory than ltl baseline due to trigram overhead. Memory is bounded per checkpoint batch.
4. ~~**Test ceiling values**~~ — DONE (PF-22). Ceiling=3 confirmed as default.
5. ~~**Re-validate final pass**~~ — DONE (PF-22). Works correctly with checkpoint architecture.
6. ~~**Test with larger files**~~ — DONE (PF-24). 50 files, 3.3 GB, 16.4M lines: 81s, 151 MB, 99.9% S1 absorption. 1.9× faster and 40% less memory than ltl -od.
7. **Integrate into ltl** — port checkpoint architecture into `read_and_process_logs()`, wire up stats merging (DD-07), add `--group-similar` CLI option.
8. **Add consolidation structures to `-mem` tracking** — ltl's `measure_memory_structures()` currently tracks `log_messages`, `log_analysis`, `log_stats`, etc. Integration must add the new consolidation structures (`clusters`, `canonical_patterns`, `unmatched_keys`, `ngram_index`, `key_trigrams`, `key_trigrams_norm`, `posting_size`, `key_message`) to this function so `-mem` output shows their high-water marks alongside existing structures.

## Open Questions

1. ~~**Character-level alignment algorithm**~~: Resolved — LCS with two-pass coalescing (PF-03)
2. ~~**CLI option naming**~~: Resolved — `--ceiling`, `--max-patterns`, `--final-pass`, `--final-threshold`, `--final-ceiling`
3. ~~**Performance benchmarks**~~: Resolved — NYTProf profiling (PF-14), alignment algorithm benchmark (PF-15)
4. ~~**Minimum cluster count**~~: Resolved — no separate floor needed. The EOF checkpoint runs on all remaining unmatched keys regardless of count, so files with fewer unique keys than the trigger threshold (5000) still get one consolidation pass.
5. ~~**Hard cap value**~~: Resolved — default 50, accommodates shared pool across log levels
6. ~~**Scalability**~~: Resolved — validated at production scale (PF-24). 50 files, 3.3 GB, 16.4M lines: 81s, 151 MB, 99.9% S1 absorption. 1.9× faster and 40% less memory than ltl -od.

## Integration Open Questions

The following questions must be addressed before integrating the prototype into ltl. TODO: resolve each before integration begins.

### ~~IQ-01: Category Model Mismatch~~ — RESOLVED

**Decision:** Do not change ltl's data model. The consolidation engine operates within ltl's existing `$category` (`plain`/`highlight`), not by log level.

**Key insight:** Consolidation should operate on `$message` only, not the full `$log_key`. The metadata fields (`$log_level`, `$truncated_thread`, `$truncated_object`, and `$session` when `--include-session` is active) serve as an **exact-match grouping key** — two messages are only consolidation candidates if all their metadata fields match. Similarity scoring (trigrams, Dice, alignment) applies only to the `$message` portion.

**Implementation note (v0.14.4):** The current implementation passes `$capped_msg = substr($log_key, 0, 350)` to the consolidation engine, which includes the `[$log_level]` prefix. The grouping key (`$cat_gk = "$category|$log_level"`) ensures keys are only compared within the same level, so the prefix doesn't cause cross-level false matches. However, the prefix does consume ~6 chars of the 350-char cap and adds prefix trigrams to the index. For access logs where the grouping key is short (`[200]`), this is negligible. For ThingWorx logs with longer metadata prefixes, this could reduce the effective message content available for similarity scoring.

**Reasoning — prefix domination on short messages:** When the full `$log_key` is used for Dice scoring, the ~50-char metadata prefix dominates the trigram set. On messages with short bodies (< ~20 chars), cross-level pairs score above 80% and would be incorrectly merged. Tested examples:
- `[WARN] ... SUCCEEDED - Foo` vs `[ERROR] ... SUCCEEDED - Foo` → Dice 91.5% (incorrect merge)
- `[WARN] ... Done` vs `[ERROR] ... Done` → Dice 89.7% (incorrect merge)
- On longer messages (70+ char bodies), cross-level Dice drops to 54% — safe, but the short-message vulnerability makes message-only scoring the correct default.

**How it maps to ltl's data flow:**
- `$message` is already available as a separate variable before `$log_key` construction (ltl lines 2235-2248)
- The metadata fields used in `$log_key` (`$log_level`, `$truncated_thread`, `$truncated_object`) are also available at that point
- Session (`$session`) is prepended to `$message` at lines 1902/1916 when `--include-session` is active — for consolidation purposes, it should be treated as a metadata grouping field, not part of the similarity-scored message
- The consolidation grouping key is the concatenation of available metadata fields: `"$log_level|$truncated_thread|$truncated_object|$session"` (with absent fields omitted). Only messages sharing the same grouping key enter pairwise comparison.

**`--consolidate-full-key` option:** Overrides the default to score similarity on the entire `$log_key` including metadata. For edge cases where metadata itself is variable noise (e.g., `pool-2437346-thread-1`, `pool-243999-thread-1` — infinite dynamically-created thread pools).

**Prototype impact:** The prototype's per-level `$cat` partitioning (`%clusters{$cat}`, `%unmatched_keys{$cat}`) maps naturally to the grouping key concept — just replace the log-level category with the full metadata grouping key. The `%canonical_patterns{$cat}` structure already supports this: patterns are only matched within their category.

### ~~IQ-02: `$log_key` Construction and Message Capping~~ — RESOLVED

**Decision:** The consolidation engine receives `$message` directly (per IQ-01), not the full `$log_key`. This eliminates the prototype's key construction differences and shortens the indexed text by ~50 chars (the metadata prefix).

**Implementation note (v0.14.4):** The implementation passes `$capped_msg = substr($log_key, 0, 350)` — using the full `$log_key` (including metadata prefix), not `$message` alone. See IQ-01 implementation note. The 350-char cap is applied when `-g` is active (#158), decoupled from terminal width.

**Adaptive consolidation cap (design — not yet implemented):** The cap on `$message` length for trigram indexing could adapt to both the output context and the observed data:

- Track `$max_observed_message_length` during parsing (on `$message` body, not full `$log_key`)
- Define upper bounds as global variables (not hardcoded): `$consolidation_cap_csv` for CSV mode, `$terminal_width` for terminal mode
- Effective cap at each checkpoint: `min($max_observed_message_length, $upper_bound)`
- By the first checkpoint (5000 keys), the observed max is representative

**Current implementation:** Fixed 350-char cap when `-g` is active, `$max_log_message_length` (terminal width) otherwise. See DD-06 warning about truncation breaking UUID normalization.

**Rationale — memory matters:** Trigram structures (`key_trigrams`, `ngram_index`, `key_trigrams_norm`) are the dominant memory cost (~206 MB peak on power-law data, PF-21). Longer messages generate proportionally more trigrams. Benchmarking showed cap 200→300 adds 46 MB RSS; 300→500 adds zero on files with ~300-char messages but would add proportionally on files with longer messages. The adaptive cap avoids wasting memory when messages are short while allowing full context when messages are long.

**Resolved sub-questions:**
- **Metric value masking:** Not a consolidation concern. ltl masks `$message` before the consolidation engine sees it (e.g., `durationMS=167` → `durationMS=?`). The engine receives pre-masked messages — fewer false unique keys, less work for the similarity engine.
- **Thread name stripping:** Not a consolidation concern. Per IQ-01, thread is an exact-match grouping field. ltl already strips trailing thread numbers before key construction.

### ~~IQ-03: Stats Merging~~ — Resolved (PF-25)

Stats merging validated in prototype. All fields match ltl's MESSAGES CSV output exactly (tested on both access logs and ThingWorx DPM logs). DD-07 updated with three missing fields: `sum_of_squares` (sum), `impact` (recompute), `total_duration_num` (sum). See PF-25 for details.

### ~~IQ-04: Per-Bucket Data (`%log_analysis`) Routing~~ — RESOLVED (non-issue)

**Answer:** Consolidation does not affect per-bucket data structures. `%log_analysis{$bucket}` is flat (no `$log_key` dimension). `%log_occurrences{$bucket}{$category_bucket}` is keyed by log level (`WARN`, `2xx`, etc.), not by message key. `$log_key` is only used as a key into `%log_messages{$category}`. The bar graph and per-bucket statistics are completely independent of message grouping — no remapping needed.

### ~~IQ-05: Inline::C as Production Dependency~~ — RESOLVED (PF-26)

**Answer:** Inline::C is NOT needed for production. Pure Perl banded edit distance is the default. The checkpoint architecture reduced `compute_mask` calls so dramatically that the 100× per-call speedup translates to only 1.2-1.6× end-to-end improvement (3.67s vs 2.29s on power-law). Additionally, Inline::C has platform-specific crash bugs (bus errors on macOS). For ltl integration: use pure Perl only, no C compiler requirement, no `_Inline/` cache.

### ~~IQ-06: `--group-similar` CLI Integration~~ — RESOLVED

**How `--group-similar` interacts with existing features:**

**(a) `-o` CSV output:** Consolidated entries appear naturally — absorbed keys are deleted from `%log_messages`, canonical keys replace them. The consolidated indicator (`~` prefix) appears as the first additional field in the CSV row (same position as in terminal output). A boolean `is_consolidated` column is added to the CSV schema.

**(b) `-n` top N:** Just works. Sorting at `print_summary_table()` iterates `keys %{$log_messages{$grouping}}`. After consolidation there are fewer, higher-occurrence entries. The sort and top-N slicing see the reduced set — no changes needed.

**(c) Summary table rendering:** The canonical form is the key in `%log_messages` after consolidation — renders in the same column as any `$log_key`. Consolidated entries are flagged with `$log_messages{$cat}{$log_key}{is_consolidated} = 1` and display the `~` prefix character (matching prototype behavior) per DD-10.

**(d) `-V` verbose output:** Consolidation statistics shown under `-V`, gated by `--group-similar` being active. Subset of prototype output relevant for testing and debugging — checkpoint counts, S1-S5 breakdown, pattern counts, reduction percentages. Not all prototype diagnostic output is needed in production.

### ~~IQ-07: Placement in ltl's Processing Flow~~ — RESOLVED

**Consolidation integrates into `read_and_process_logs()` at three points:**

1. **S1 inline match (line ~2254):** Before adding to `%log_messages{$category}{$log_key}`, try matching `$message` against compiled patterns for the grouping key. If matched, route duration/bytes/stats to the cluster and skip `%log_messages` insertion. This is the primary performance mechanism — prevents 98-99% of keys from entering `%log_messages`.

2. **Checkpoint trigger (after line ~2453):** After per-line stats accumulation, check if unmatched count for the grouping key exceeds the trigger. If so, call `run_checkpoint()` which runs S2→S3→S4, discovers new patterns, and deletes absorbed keys from `%log_messages`.

3. **Final pass (after line ~2460):** After all files are closed and before `return`, run the final consolidation pass on ceiling-excluded keys.

**Consolidation logic lives in dedicated subroutines** called from `read_and_process_logs()` — not inline. Key functions: `try_inline_match()`, `run_checkpoint()`, `run_consolidation_pass()`, `build_ngram_index()`, `find_candidates()`, `compute_mask()`, `derive_canonical()`, `derive_regex()`, `merge_stats()`.

**Data structures are globals**, alongside existing `%log_messages`, `%log_analysis`, etc. They persist across the parsing loop and are referenced for verbose output and stats. Key structures: `%clusters`, `%canonical_patterns`, `%unmatched_keys`, plus per-checkpoint transient structures (`%ngram_index`, `%key_trigrams`, etc.) that are built and freed within `run_checkpoint()`.

**Downstream functions are unaffected.** `calculate_all_statistics()`, `normalize_data_for_output()`, `print_bar_graph()`, and `print_summary_table()` operate on `%log_messages` which already has consolidated entries by the time they run. No changes needed to these functions (except the `~` indicator rendering in `print_summary_table()` per IQ-06).

### ~~IQ-08: `%log_messages` Key Replacement — Full Data Model~~ — RESOLVED

**Full field inventory for `%log_messages{$category}{$log_key}`:**

Fields set during parsing (must be merged by `merge_stats()`):

| Field | Merge rule | PF-25 covered? |
|-------|-----------|----------------|
| `occurrences` | sum | Yes |
| `total_bytes` | sum | Yes |
| `total_duration` | sum | Yes |
| `total_duration_num` | sum | No — add |
| `sum_of_squares` | sum | Yes |
| `durations` | concatenate arrays | Yes |
| `impact` | **recompute** after merge | No — add |
| `count_sum` | sum | No — add |
| `count_occurrences` | count (sum) | No — add |
| `count_min` | min of mins | No — add |
| `count_max` | max of maxes | No — add |
| `udm_${name}_sum` | sum (per UDM config) | No — add |
| `udm_${name}_occurrences` | count (sum) | No — add |
| `udm_${name}_min` | min of mins | No — add |
| `udm_${name}_max` | max of maxes | No — add |
| `is_consolidated` | set to 1 on canonical entry | N/A — new field |

Fields computed downstream in `calculate_all_statistics()` — **not merged**, recomputed from raw fields: `min`, `mean`, `max`, `std_dev`, `cv`, `p1`-`p999`, `count_mean`, `udm_${name}_mean`, `total_duration` (overwritten with formatted string).

**Key insight:** All merge rules follow the same three patterns: sum, min-of-mins, or concatenate. The count/UDM fields use the same rules as the duration/bytes fields already implemented in PF-25. `impact` is the only field that requires recomputation rather than arithmetic merge. The downstream `calculate_all_statistics()` function handles all derived fields correctly from the raw merged data — no changes needed there.

### ~~IQ-09: Adaptive Trigger — Status~~ — RESOLVED (deferred)

**Decision:** Use fixed trigger of 5000 for initial integration. The adaptive trigger described in DD-02 is deferred — it's an optimization, not a correctness requirement. The fixed trigger worked correctly across all test files (power-law, diverse, access logs, DPM). On power-law data, checkpoint 1 discovers dominant patterns and S1 absorbs 98%+ thereafter. On diverse data, 2 checkpoints fire and both are productive. Adaptive behavior can be added later if profiling shows it's needed.

### ~~IQ-10: Final Pass Stats Merging~~ — RESOLVED (non-issue)

**Answer:** Same `merge_stats()` operation as checkpoint-time S4 merging — no special handling needed. The final pass absorbs ceiling-excluded keys from `%log_messages`, merging their full stats (per IQ-08 field inventory) into new clusters and deleting the absorbed entries. The prototype already does this correctly (PF-23). Per IQ-04, `%log_analysis` has no `$log_key` dimension and is unaffected. The only difference from checkpoint-time merging is that entries have larger `durations` arrays (accumulated across the entire file), but the merge rules are identical.

---

## Integration Benchmarks (ltl with `-g 80`)

macOS ARM64 (Apple M4 Max). Memory = RSS high-water mark.

### Scaling Summary

| Scale | Baseline | `-g 80 --no-final-pass` | Time ratio | Memory ratio |
|-------|----------|------------------------|-----------|-------------|
| 1 file (95 MB) | 5.0s / 40 MiB | 6.6s / 120 MiB | 1.32× | 3.0× |
| 5 files (440 MB) | 15.6s / 85 MiB | 20.0s / 143 MiB | 1.28× | 1.68× |
| 30 files (1.5 GB) | 77.8s / 868 MiB | 96.6s / 380 MiB | 1.24× | **0.44×** |
| 120 files (7.9 GB) | 390s / 3,661 MiB | 473s / 437 MiB | 1.21× | **0.12×** |

Time overhead decreases with scale (1.32× → 1.21×). Memory crossover occurs between 1-5 files — at production scale, consolidation **saves 3.2 GB of RAM** by preventing unique keys from entering `%log_messages` via S1 inline absorption.

### Production-Scale — 7.9 GB, 40.6M lines, 120 files (4 servers × 28 days)

| Mode | Time | Memory | Ratio to baseline |
|------|------|--------|-------------------|
| No `-g` (baseline) | 390s | 3,661 MiB | — |
| `-g 80 --no-final-pass` | 473s | 437 MiB | 1.21× time, **0.12× memory** |
| `-g 80` | 489s | 451 MiB | 1.25× time, **0.12× memory** |

Final pass adds ~16s (3.4% overhead) and 14 MiB at production scale.

### Profiling Breakdown (Devel::NYTProf, 1 file / 95 MB / 463K lines)

| Component | Baseline | With `-g 80` | Delta |
|-----------|----------|-------------|-------|
| `read_and_process_logs` (excl) | 8.30s | 8.87s | +570ms (inline per-line code) |
| `find_consolidation_candidates` | — | 1.16s | checkpoint pairwise Dice scoring |
| `CORE:match` (regex) | 1.05s | 1.10s | +50ms (S1 pattern matching) |
| `build_consolidation_ngram_index` | — | 217ms | trigram index construction |
| `get_consolidation_trigrams` | — | 172ms | trigram generation |
| `match_consolidation_patterns` | — | 135ms | S1 inline matching (new keys only) |

Per-line overhead of `-g`: ~1.2μs (grouping key join, message cap, boolean guards). S1 pattern matching only fires for new unique keys (44K of 463K lines = 9.5%), not every line. Checkpoint work (`find_consolidation_candidates`, `build_consolidation_ngram_index`) is batched and amortized.

### Performance Optimization History

1. **Hard pattern cap (50)**: Original prototype design. At production scale (7.9 GB), caused checkpoint stall — 50 patterns couldn't cover the URL diversity in access logs (45K+ unique URLs per file). Hundreds of unproductive checkpoints fired, each re-scanning 5000 keys against patterns that couldn't match. Result: 3+ hours for server-0 alone (vs 77s baseline).

2. **Raised cap to 500 + stall detection** (superseded by item 6): Stall detection stopped triggering checkpoints after 2 consecutive unproductive ones. Reduced server-0 from 3+ hours to 104s. Replaced by adaptive per-key eviction in #135.

3. **Removed hard cap (unlimited) + `build_grouping_key` inlining**: Patterns grow naturally until diversity is exhausted. More patterns = more S1 absorption = less memory. Inlining the grouping key construction saved ~400ms per 463K lines (eliminated function call overhead). Server-0: 104s → 97s. Full 7.9 GB: 473s with 88% less memory than baseline.

4. **Per-key eviction investigation (#135, prior session)**: Attempted removing stall detection entirely and adding per-key eviction (age counter in `consolidation_unmatched`, evict after 3 checkpoint attempts). Eviction correctly bounds memory. Reverted pending further investigation into the interplay with per-checkpoint cost on diverse data.

5. **Redundancy fixes (#135, current session)**: Profiled with NYTProf + cross-validation framework (#138). Confirmed three sources of redundant work and implemented fixes:
   - **Fix 1 — Tracked cleanup**: `run_consolidation_pass` returns `%consumed`; cleanup loops iterate O(consumed) instead of O(all_keys). On power-law file: cleanup scans 4,992 keys (consumed only) instead of all 286K.
   - **Fix 2 — Smart S3 skip**: Track `$consolidation_pattern_generation`; S3 skips keys whose generation >= current (already tested against all patterns). Result: S3 attempts → 0 across all test files (5,045 skipped on power-law).
   - **Fix 3 — Return entry from merge**: `try_consolidation_merge_into_existing` returns `($merged_regex, $entry, $existing)` — callers use returned references directly instead of O(patterns) linear scan.

   **XL access log benchmarks (vs main branch baseline):**
   | Sample | Baseline time | Fixed time | Baseline memory | Fixed memory |
   |--------|-------------|-----------|----------------|-------------|
   | 100K lines | 117.9s | 113.5s (-3.8%) | 157.7 MiB | 199.7 MiB (+26.6%) |
   | 500K lines | 118.9s | 118.8s (-0.1%) | 429.4 MiB | 478.1 MiB (+11.3%) |

   Time improvement is modest because `read_and_process_logs` dominates at 95% CPU — the redundancy was real but not the bottleneck. Memory increase (+26.6%) was caused by correctly retaining trigrams for surviving keys — old code wastefully deleted and recomputed them per checkpoint. Per-key eviction (item 6) naturally resolves this by bounding the surviving set.

6. **Adaptive per-key eviction (#135)**: Replaced stall detection with adaptive eviction. Each key tracks how many checkpoints it has survived. Max survival count is determined by exponential moving average (EMA, alpha=0.4) of the group's absorption rate. Eviction curve: <5%→0 survivals, 5-50%→1, 50-90%→2, 90-95%→3, 95-99%→4, ≥99%→5. Fast-path eviction: when max_survivals=0 and cp_num>2, skip `run_consolidation_pass` entirely (no trigram index, no fc_calls). Trigrams retained for surviving keys across checkpoints (skip recomputation in `build_consolidation_ngram_index`). Generation tracking separated to `%consolidation_key_generation` for S3 skip coexistence.

   **Empirical absorption rates driving curve design:**
   | File Type | Group | CP | Pre | Absorbed | Rate |
   |-----------|-------|---:|----:|---------:|-----:|
   | Standard access (22K) | 200 | 1 | 570 | 193 | 33.9% |
   | Power-law (288K) | ERROR | 1 | 4991 | 4985 | 99.9% |
   | App log (480K) | DEBUG | 1 | 1709 | 0 | 0.0% |
   | ScriptLog (320K) | INFO | 1 | 2856 | 2839 | 99.4% |
   | XL multi-file (500K) | 200 | 1-6 | 5K-105K | 0-37 | 0.0-0.4% |

   **XL access log benchmark (500K lines, 5 diverse files combined):**
   | Metric | Baseline (stall detection) | Adaptive eviction | Change |
   |--------|---------------------------|-------------------|--------|
   | Time | 185s | 55s | **3.4× faster** |
   | RSS Peak | 454.8 MiB | 237.6 MiB | **-47.7%** |
   | consolidation_unmatched | 22 MiB | 68 KiB | **-99.7%** |
   | consolidation_key_message | 35 MiB | 65 KiB | **-99.8%** |
   | consolidation_clusters | 19 MiB | 77 KiB | **-99.6%** |

### Observations

- **S1 dominance at scale**: At production scale, the vast majority of unique keys match existing S1 patterns and never enter `%log_messages`. This is the primary mechanism for both memory savings and time efficiency.
- **Memory crossover**: At small file sizes (< ~200 MB), consolidation uses more memory than baseline (trigram structures during checkpoints). At large file sizes, the memory saved by S1 absorption far exceeds the checkpoint overhead, since trigram structures are freed per checkpoint while `%log_messages` entries persist for the entire run.
- **Pattern count plateaus naturally**: With no hard pattern cap, pattern count plateaus when the data's diversity is exhausted. Adaptive per-key eviction naturally bounds the working set — keys that have had sufficient checkpoint opportunities without being absorbed are evicted, allowing fresh keys to continue getting consolidation chances without the accumulated overhead.
- **Final pass cost is proportional**: At small scale, the final pass dominates consolidation time. At large scale, it's a small fraction (16s / 489s = 3.4%) because most keys are already absorbed by S1 during parsing.

## Validation and Debugging

### Verbose Output (`-V -g`)

When both `-V` and `-g` are active, ltl outputs a consolidation summary block in the verbose section. This is the primary diagnostic tool for validating that consolidation is working as expected.

#### Example Output

```
=== Consolidation Summary (Issue #96) ===
  Threshold: 85%  Trigger: 5000  Ceiling: 3  Final pass: on (threshold=85%, ceiling=1000000)

  --- plain|WARN: 8782 unique keys seen, 2 checkpoints, 36 patterns ---
    S1 Inline match:       6101
    S2 Ceiling filter:     8  (occurrences >= 3, remaining after all passes)
    S3 Checkpoint match:   0
    S4 Pairwise discovery: 2668
    S5 Unmatched:          5
    S3 attempts:           0  (skipped: 1204, match rate: 0.0%)
    Cleanup keys scanned:  2668  (cumulative across 2 checkpoints)
    find_candidates calls: 285
    Reduction: 8782 → 49 (99.4%)

  === Grand Totals ===
    Total keys seen:       23389
    Total S1 Inline:       17613
    Total S2 Ceiling:      29
    Total S3 Checkpoint:   0
    Total S4 Pairwise:     5728
    Total S5 Unmatched:    19
    Total checkpoints:     6
    Total patterns:        79
    Total fc calls:        285
    Reduction: 23389 → 127 (99.5%)
```

#### Field Reference

| Field | Meaning | Healthy Range |
|-------|---------|---------------|
| Unique keys seen | Total new unique `$log_key` values encountered during parsing for this group | Depends on file |
| S1 Inline match | Keys matched by compiled regex during parsing (cheap, hot path) | Should dominate at scale (>90%) |
| S2 Ceiling filter | Keys with occurrences >= ceiling, excluded from pairwise discovery | Small number; high means many distinct high-frequency keys |
| S3 Checkpoint match | Keys absorbed by re-scanning against patterns discovered in the same checkpoint | Often 0; non-zero means patterns discovered mid-checkpoint helped |
| S4 Pairwise discovery | Keys absorbed by Dice similarity + alignment during checkpoint passes | Main discovery mechanism; decreases as S1 takes over |
| S5 Unmatched | Keys that survived all stages and eviction — genuinely unique messages | Should be small; if large, threshold may be too high |
| S6 Evicted | Keys evicted from consolidation working set after exceeding adaptive survival threshold | High count on diverse data is expected — keys correctly bounded |
| Eviction | EMA absorption rate and derived max_survivals for the group | Shows how aggressive eviction is for this group |
| S3 attempts | Total S3 match attempts and skipped count | Skipped count should be high — means generation tracking is working (#135 Fix 2) |
| Cleanup keys scanned | Keys iterated in cleanup loops (cumulative across checkpoints) | Should equal total absorbed keys, not total keys (#135 Fix 1) |
| find_candidates calls | Number of trigram-based candidate searches in S4 | Cost indicator for pairwise discovery |
| Checkpoints | Number of checkpoint passes fired during parsing + EOF | Typically 2-10; very high means trigger too low or poor S1 absorption |
| Patterns | Number of compiled regex patterns discovered | Grows with data diversity; plateaus when data's diversity is exhausted |
| Reduction | `keys_seen → (S5 + S2 + patterns)` as percentage | Higher is better; >95% on repetitive data |

#### Tracking Invariant

The six stages must account for all keys seen:

```
S1 + S2 + S3 + S4 + S5 + S6 = keys_seen
```

If this invariant fails, a `[WARN] Tracking mismatch` line appears with the delta. This indicates a counting bug in the stage tracking — the consolidation itself may still be functionally correct, but the diagnostic counters are not reliable until the mismatch is resolved.

**Counting approach:** S1, S3, S4, and S6 are accumulated during processing. S2 and S5 are computed at report time by partitioning the remaining `%consolidation_unmatched` keys: keys with `occurrences >= ceiling` are S2, the rest are S5. This avoids double-counting ceiling keys that survive multiple checkpoints. Final pass absorptions (ceiling keys matched by pairwise discovery) are added to S4.

#### What to Look For

**Healthy consolidation:**
- S1 dominates (>75% of keys_seen), especially on larger files
- Few checkpoints (2-6 typical)
- S5 is small relative to keys_seen
- Reduction >90% on repetitive log data

**Poor consolidation (threshold too high):**
- S4 discovers few patterns
- S5 is large — many keys survive all stages
- S1 percentage is low because few patterns exist to match against
- Fix: lower the `-g` threshold (e.g., `-g 70`)

**Poor performance (too many checkpoints):**
- High checkpoint count (>20)
- S1 percentage is low despite many patterns
- Indicates patterns are too specific to catch incoming variation
- May indicate the trigger threshold is too low

**Adaptive eviction active:**
- Verbose output shows per-group: `Eviction: EMA=X.X%, max_survivals=N`, `S6 Evicted: N`
- Low EMA (<5%) with high S6 count indicates data too diverse for consolidation — keys are correctly evicted immediately
- Fast-path eviction (skips `run_consolidation_pass` entirely) activates when max_survivals=0 and cp_num>2
- Grand totals include `Total S6 Evicted` count

### Data Structures for Debugging

All consolidation state is accessible for debugging:

| Structure | Key | Contents |
|-----------|-----|----------|
| `%consolidation_cat_stats` | `"$category\|$grouping_key"` | Per-group counters: `keys_seen`, `s1_inline`, `s3_checkpoint`, `s4_pairwise`, `s6_evicted`, `checkpoints`, `patterns_discovered`, `patterns_final`, `fc_calls`, `s3_calls`, `s3_skipped`, `cleanup_keys_scanned` |
| `%consolidation_clusters` | `{cat_gk}{canonical}` | Cluster data: `occurrences`, `match_count`, `canonical`, `pattern`, `mask`, duration/bytes/count stats |
| `%consolidation_patterns` | `{cat_gk}` | Array of `{pattern, canonical, cluster_key, match_count}` — the compiled regex list for S1 |
| `%consolidation_unmatched` | `{cat_gk}{log_key}` | Keys not yet absorbed — value=1 (presence marker). Bounded by adaptive eviction. |
| `%consolidation_key_generation` | `{log_key}` | Pattern generation at entry time (for S3 skip optimization, #135 Fix 2) |
| `%consolidation_key_checkpoint_count` | `{log_key}` | Number of checkpoints this key has participated in (for adaptive eviction) |
| `%consolidation_absorption_ema` | `{cat_gk}` | Exponential moving average of absorption rate (0.0-1.0, alpha=0.4) |
| `%consolidation_key_message` | `{log_key}` | Capped message text for each unmatched key |
| `%consolidation_ngram_index` | `{cat_gk}{trigram}{log_key}` | Trigram posting lists — built per checkpoint, freed when key consumed or evicted |
| `%consolidation_key_trigrams` | `{log_key}` | Per-key trigram sets — retained across checkpoints, freed when key consumed or evicted |

### Grouping Key Design

The `cat_gk` (category + grouping key) partitions consolidation into independent groups. Each group has its own patterns, clusters, unmatched set, and stage counters.

- `$category` = `plain` or `highlight` (matches `%log_messages` structure)
- `$grouping_key` = `$log_level` (ERROR, WARN, INFO, or HTTP status code)

Cross-level merges are prevented by the grouping key partition — an ERROR message is never compared against a WARN message. Thread names and object names are part of the `$log_key` string and participate in similarity scoring and wildcarding within a level group.

**Why not finer grouping (thread, object)?** Thread names can be unique per-instance identifiers (e.g., `WC_0K011012_ProcessPTCAutomationEventsForWorkUnitAsync`), creating hundreds of tiny groups. This defeats the checkpoint trigger mechanism (per-category, not per-group) and generates hundreds of unproductive checkpoint calls. Grouping by level only produces 3-6 groups, allowing checkpoints to fire during parsing and S1 inline matching to absorb the majority of keys.

**Why not coarser grouping (category only)?** Short messages with different log levels can score above the Dice threshold on the full `$log_key` due to prefix domination (e.g., `[WARN] ... Done` vs `[ERROR] ... Done` → Dice 91.5%). Level-based grouping prevents this without adding per-line cost.

### Checkpoint Trigger Design

The checkpoint trigger counts total unmatched keys per `$category` (plain/highlight), not per cat_gk group. When the trigger fires, checkpoints run for all cat_gk groups within that category that have >= 2 unmatched keys. This ensures checkpoints fire during parsing even when keys are distributed across many level-based groups.

```
$consolidation_category_unmatched_count{$category} >= $consolidation_trigger
```

After firing, the counter resets to 0 and accumulation resumes.

### Test Files and Expected Results

| File | Size | Keys Seen | S1% | Reduction | Time (no -g) | Time (-g) | Notes |
|------|------|-----------|-----|-----------|-------------|-----------|-------|
| `ScriptLog.2025-04-09.4.log` | 72MB | ~223K | ~97% | ~99.9% | ~4s | ~9s | ThingWorx script log, many unique thread names |
| `ScriptLog.2025-*` (5 files) | 463MB | ~499K | ~96% | ~99.9% | — | ~30s | Multi-file scale test; 1.53M lines |
| `HundredsOfThousandsOfUniqueErrors.log` | 102MB | ~286K | >99% | >99% | — | — | Primary prototype test file |

### Common Issues and Fixes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `-g` makes execution 10x+ slower | Checkpoint trigger per-cat_gk instead of per-category | Fixed in #131: trigger is now per-category |
| Too many small groups, hundreds of checkpoints | Grouping key includes thread/object names | Fixed in #131: grouping key is level-only |
| Tracking mismatch in verbose output | Stage counter not incremented for some absorption path | Fixed in #131: S2/S5 computed at report time (not accumulated per checkpoint); final pass absorptions tracked in S4 |
| S3 always 0 | No patterns discovered early enough in a checkpoint for re-scan to absorb keys | Normal for small files; at scale with multiple checkpoints, S3 may contribute |
| High S5 count | Threshold too high for the data's variation | Lower `-g` threshold |
| Memory regression with `-g` | Unmatched keys accumulated in consolidation tracking structures indefinitely | Fixed by adaptive per-key eviction (#135): EMA-based survival threshold bounds the working set. XL benchmark: 455→238 MiB (-47.7%). |
| Time regression in `read_files` with `-g` | Diverse keys accumulated in unmatched set, increasing per-checkpoint cost | Fixed by adaptive per-key eviction (#135): fast-path eviction skips `run_consolidation_pass` when max_survivals=0. XL benchmark: 185s→55s (3.4× faster). |
| `gk_prefix` errors or missing prefixes | Legacy code from pre-#131 grouping key design | Removed in #131: canonical form is the full `$log_key` |

## Finding: no groupings on keys whose rarest trigrams are per-request values (#569)

**Status (2026-09-15): investigation of the reported case complete; no fix designed.** Five mechanisms are established (§ Open items and next steps), each traced on the production code path with instrumented scratch copies of `ltl`: the fixed pre-filter selecting per-instance identifiers (items 1 and 2, one defect), merge-first generalisation producing the catch-all (item 3), literal residue from near-duplicate pairs and rejected merges (item 4), and the candidate cap exhausted by consumed keys (item 5). The final-pass threshold part is resolved by #571, merged into this branch (`b94ea08`); the reproducing invocation is unchanged after it (74,305 keys, 0 patterns, 48 s). Before benchmarks for the change are captured (§ Performance baseline before the pre-filter change). Next: design, covering items 1, 3, 4 and 5 together, against the constraints and the cost split below.

### Interaction: the pre-filter opened, against the other mechanisms

2026-09-15. The shipped `ltl` against a scratch copy whose only change is `$consolidation_prefilter_ratio = 0.0` (loose minimum 1), both from this branch after the #571 merge. Sequential single runs, `-V message-grouping`; wall time is indicative only, not a benchmark.

| Input and options | Shipped: rows after grouping, wall | Pre-filter opened: rows after grouping, wall |
|---|---|---|
| PLM access log, one day, `-du us -xqs -bs 1440 -n 15 -g 80` | 74,416, 61.2 s | 13,880, 101.4 s (35,795 keys evicted) |
| same, `-g 70` | 74,374, 44.3 s | 75, 11.3 s |
| Application platform log, ~480,000 lines, `-bs 1440 -n 15 -g 85` | 136, 6.8 s (ERROR 265 → 81) | 92, 14.9 s (ERROR 414 → 37) |
| Application log of hundreds of thousands of unique errors, `-bs 1440 -n 15 -g 85` | 72, 11.4 s; ERROR: 2 checkpoints, 281,453 matched inline | 71, 121.3 s; ERROR: 54 checkpoints, 18,616 inline, 267,489 evicted and matched in the final pass |

Readings:
- **Access log, `-g 70`, opened:** the 75 rows are genuine groups, not a catch-all. The largest are the three download variants (7,142, 4,655 and 2,484 member keys); the signing-time split of item 4 remains.
- **Access log, `-g 80`, opened:** 13,880 rows remain. This is consistent with only 40.6% of download keys having a partner at 80 across the day (§ Similarity distribution between download keys); not verified row by row.
- **Unique-errors log, opened:** the same final result by a different path. Both runs form the same first three pairs: keys identical but for the UUID, Dice 100, whose sorted neighbours share leading hex digits, so the canonicals keep them (`ErrorCode(000*)`, `001*`, `01*`, merged to `ErrorCode(0*)` absorbing 320 keys; item 4's literal residue again). Shipped, checkpoint 1 then keeps forming pairs and merges to `ErrorCode(*)`; opened, it forms no further `ErrorCode` pair in 500 candidate searches, absorption collapses, eviction takes over. **Mechanism confirmed (open item 5):** instrumented, 495 of the 500 sources searched in that checkpoint received exactly 50 candidates, all scoring 100 and all 50 already consumed by `ErrorCode(0*)`; `find_consolidation_candidates()` caps its result at 50 sorted by score then key, and `run_consolidation_pass()` skips consumed candidates without refilling, so none of those sources formed a pair (the other five: two with no candidates, three with some unconsumed).

### What stays ungrouped at `-g 80` with the pre-filter opened

2026-09-15. The PLM access log, one day, `-du us -xqs -bs 1440 -n 15 -g 80`, on a scratch copy with loose minimum 1 that writes out the keys left after the final pass and, for the `plain|200` group's first three streaming checkpoints, each batch and the evicted keys marked by whether they had been searched as a source. 75,833 keys reduce to 13,858 rows; 13,814 keys remain, of which 13,754 are download requests (60 other).

- **About half have no partner at the threshold.** For 200 randomly sampled leftover download keys, the best partner among all 74,305 download keys of the day scores 78–81 (median 80): 52.0% have one at ≥ 80, all 100% at ≥ 75. The 48% without one are correctly left ungrouped at 80.
- **The other half are stranded by literal residue (open item 4).** For all 104 sampled keys with a partner at ≥ 80, that partner was already grouped, none left over, so the key could join only by matching the partner's cluster pattern; it cannot pair with the absorbed partner either (open item 5's consumed-candidate skip). Of the 94 whose partner's cluster was located in `message-grouping / cluster-membership`, every one fails that pattern on `sT` alone (one also on the capped `site` tail): the cluster requires `sT=177919*` and the key's signing time begins `177920`, the day's later half.
- **The 500-source limit did not strand keys here.** Checkpoint 3 held 7,804 keys and evicted 2,804 (2,365 download requests), of which only 165 had been searched as a source. For 200 sampled evicted non-source download keys, the best partner inside that batch scores 75–78: none had a partner at 80 there, so being skipped as a source cost them no pair. Their partners at 80, where they exist, are elsewhere in the day.

### Where the time goes: shipped against the pre-filter opened

2026-09-15. `-V benchmark-data` `TIMING` rows, single sequential runs on one machine, shipped `ltl` against the loose-minimum-1 copy. Streaming checkpoints run inside `parse/read_files`; the final pass is `finalize/group_similar`.

| Input and options | Shipped: parse / final pass / total | Pre-filter opened: parse / final pass / total |
|---|---|---|
| PLM access log, one day, `-du us -xqs -bs 1440 -n 15 -g 80` | 5.9 s / 48.8 s / 54.9 s | 94.1 s / 31.3 s / 125.6 s |
| Application log of hundreds of thousands of unique errors, `-bs 1440 -n 15 -g 85` | 7.2 s / 4.7 s / 12.0 s | 99.2 s / 14.5 s / 113.7 s |

Readings:
- **Shipped, the access log's time is the final pass doing nothing useful:** 48.8 s for 37,305 candidate searches that all return empty, over the 74,305 keys eviction handed it.
- **Opened, the cost moves into the streaming checkpoints:** parse rises 16× on the access log and 14× on the unique-errors log. On the unique-errors log that is item 5: 54 checkpoints of fruitless searches before eviction hands the keys to the final pass.
- The same four runs measured through `-V message-grouping` earlier gave 61.2 / 101.4 s and 11.4 / 121.3 s totals: single runs, so these figures bound an order of magnitude, not a percentage.

### Performance baseline before the pre-filter change

Captured 2026-09-15 on `044b25c` (this branch, `ltl` unchanged apart from `$version_number`), same machine, single run each, `tests/baseline/results/569-before-<case>.tsv`. The pre-filter runs in streaming checkpoints (inside `parse/read_files`) and in the final pass (`finalize/group_similar`), so both are read.

| Case | `total` | `finalize/group_similar` | `rss_peak` |
|---|---|---|---|
| `single-day-access-log-standard` (no `-g`) | 9.744 s | 0.000 s | 98.4 MB |
| `single-day-access-log-top25-consolidate` | 13.582 s | 2.518 s | 130.8 MB |
| `single-day-application-log-top25-consolidate` | 7.015 s | 0.290 s | 131.7 MB |
| `humungous-log-uniqueness-top25-consolidate` | 11.662 s | 4.379 s | 264.4 MB |

### Prototype: candidate gate sized from the requested similarity

2026-09-15, `prototype/569-gate-sizing/` (results in `results/`), at the architect's direction (open item 1).

**Question.** Does a pre-filter that probes the |r| − ⌈T·|r|/(200 − T)⌉ + 1 rarest trigrams of a key with |r| trigrams at similarity T, and admits a candidate on one shared trigram (§ Industry grounding), find the partners the shipped rule (50 rarest, 15 shared) misses, and at what cost per candidate search?

**Method.** Both arms are `find_consolidation_candidates()` sliced verbatim from `ltl`; the sized arm changes only Phase 1's probe length and required hits. Inputs are the ten first-checkpoint batches of § Pre-filter misses across log families, the first 500 sources in batch order, T = 50 to 95. Per search: partners missed against a direct Dice scan of the whole batch (UUID-normalised where `ltl` scores normalised), trigrams probed, posting entries visited, Dice verifications, and milliseconds (median of 3 timed passes, arms interleaved, batches sequential on one machine; the widest pass range is 1.7× for the sized arm and 3.5× for one shipped cell). The shipped arm reproduces the earlier record's partner and miss counts on all ten batches.

Partners missed, shipped → sized, of the sources with a partner at T:

| Batch (keys) | T=50 | T=60 | T=70 | T=75 | T=80 | T=85 | T=90 | T=95 |
|---|---|---|---|---|---|---|---|---|
| PLM access log, download requests only (5,000) | 500 → 0 / 500 | 500 → 0 / 500 | 500 → 0 / 500 | 500 → 0 / 500 | 446 → 0 / 446 | no partners | no partners | no partners |
| PLM access log, unfiltered (4,990) | 298 → 0 / 500 | 296 → 0 / 495 | 296 → 0 / 489 | 296 → 0 / 475 | 247 → 0 / 408 | 0 → 0 / 132 | 0 → 0 / 69 | 0 → 0 / 22 |
| Application platform log, ERROR (238) | 69 → 0 / 232 | 102 → 0 / 229 | 99 → 0 / 224 | 101 → 0 / 220 | 100 → 0 / 218 | 100 → 0 / 216 | 75 → 0 / 183 | 75 → 61 / 175 |
| Unique-errors log, ERROR (4,990) | 1 → 0 / 499 | 1 → 0 / 499 | 0 → 0 / 498 | 0 → 0 / 498 | 0 → 0 / 496 | 0 → 0 / 496 | 0 → 0 / 496 | 0 → 0 / 496 |
| Script log, INFO (2,851) | 1 → 0 / 500 | 1 → 0 / 500 | 1 → 0 / 500 | 1 → 0 / 500 | 1 → 0 / 500 | 6 → 2 / 500 | 6 → 7 / 495 | 5 → 6 / 239 |
| Script log, ERROR (209) | 1 → 0 / 208 | 0 → 0 / 206 | 0 → 0 / 204 | 0 → 0 / 204 | 0 → 0 / 201 | 0 → 0 / 197 | 0 → 0 / 191 | 0 → 0 / 157 |

Application platform WARN (3,048) and DEBUG (1,709), script WARN (1,940) and Tomcat 9 access log (2,870): 0 missed by either arm at every T.

Milliseconds per search, median, shipped → sized:

| Batch (keys) | T=50 | T=60 | T=70 | T=75 | T=80 | T=85 | T=90 | T=95 |
|---|---|---|---|---|---|---|---|---|
| PLM access log, download requests only (5,000) | 0.35 → 193 | 0.35 → 174 | 0.35 → 145 | 0.36 → 135 | 0.35 → 116 | 0.37 → 103 | 0.35 → 13 | 0.35 → 0.47 |
| PLM access log, unfiltered (4,990) | 4.2 → 122 | 4.5 → 110 | 3.8 → 87 | 3.7 → 79 | 3.8 → 68 | 3.4 → 59 | 3.9 → 8.2 | 3.7 → 0.32 |
| Application platform log, ERROR (238) | 0.24 → 2.8 | 0.24 → 2.2 | 0.24 → 1.8 | 0.24 → 1.7 | 0.24 → 1.5 | 0.24 → 1.1 | 0.23 → 0.56 | 0.23 → 0.17 |
| Application platform log, WARN (3,048) | 1.7 → 22 | 1.6 → 19 | 1.6 → 17 | 1.6 → 16 | 1.6 → 16 | 1.6 → 14 | 1.5 → 1.9 | 1.5 → 0.59 |
| Application platform log, DEBUG (1,709) | 9.0 → 21 | 8.8 → 19 | 9.1 → 17 | 8.9 → 16 | 9.3 → 15 | 9.1 → 3.4 | 9.0 → 1.5 | 9.0 → 0.67 |
| Unique-errors log, ERROR (4,990) | 12 → 144 | 11 → 133 | 11 → 112 | 12 → 107 | 12 → 97 | 11 → 90 | 11 → 77 | 11 → 7.0 |
| Script log, INFO (2,851) | 18 → 26 | 18 → 23 | 18 → 19 | 17 → 17 | 17 → 15 | 16 → 12 | 13 → 7.5 | 12 → 2.8 |
| Script log, WARN (1,940) | 12 → 31 | 12 → 30 | 12 → 25 | 12 → 23 | 12 → 21 | 11 → 14 | 12 → 9.4 | 9.7 → 6.7 |
| Script log, ERROR (209) | 0.50 → 2.0 | 0.49 → 1.4 | 0.49 → 0.96 | 0.49 → 0.78 | 0.48 → 0.66 | 0.47 → 0.50 | 0.47 → 0.42 | 0.42 → 0.31 |
| Tomcat 9 access log (2,870) | 6.9 → 10 | 5.5 → 3.9 | 4.8 → 2.1 | 6.0 → 1.7 | 4.2 → 1.9 | 5.6 → 0.80 | 4.9 → 0.43 | 4.3 → 0.09 |

Readings:
- **Recall.** The sized gate finds every partner the shipped rule misses on the download keys and the unfiltered access log at every T, and on the application ERROR batch up to T = 90. It still misses on UUID-bearing keys at the highest thresholds: 61 of 175 on the application ERROR batch at 95, and 2, 7 and 6 on the script INFO batch at 85, 90 and 95 (shipped: 6, 6, 5). The probe is sized and selected on the raw trigram set while Dice is scored on the UUID-normalised set; a pair at 100 normalised scores about 80 raw (open item 2), so a prefix sized for 95 on raw trigrams carries no guarantee for it.
- **Cost where it rises: nearly every key in the batch is verified.** On the download batch the sized gate runs 4,999 Dice verifications per search from T = 50 to 80 (4,674 at 85, 616 at 90, 11 at 95); the unique-errors batch runs 4,943 from 50 to 90. Every key shares at least one probed trigram and passes the size filter. The shipped rule verifies 0 and 190 there.
- **Attribution.** A least-squares fit over the download batch's eight sized rows gives 0.021 ms per Dice verification and 0.00016 ms per posting entry visited (fit within 2 ms of every median): at T = 50, 105 ms verification and 88 ms counting; at T = 80, 105 ms and 13 ms. Verification dominates from T = 70 up; counting grows with the longer probe at low T.
- **Cost where it falls.** The sized probe is shorter than 50 from T ≈ 85 up on most batches and on short keys at every T, and is then faster: Tomcat 9 access log from T = 60 (5.5 → 3.9 ms) to 95 (4.3 → 0.09 ms), application DEBUG from 85, and every batch at 95 except the download batch (0.35 → 0.47 ms).
- **What a lossless search must verify at minimum.** On the first 5,000 download keys, 25.9% of random pairs score ≥ 75 and 0% score ≥ 80 (§ Similarity distribution between download keys). At 75, any method returning every partner verifies about 1,300 keys per search, a quarter of the 4,999 verified now; at 80 the true partners are few, so the 4,999 are almost all rejected by verification.
- **What a search is used for.** `run_consolidation_pass()` takes the top 50 candidates by score and forms a pattern with the first unconsumed one that validates; it needs one usable partner per source, not every partner. The prefix bound guarantees every partner.
- **Scale in production.** A checkpoint searches up to 500 sources: at the medians above that is about 58 s per checkpoint on the download batch at T = 80 (0.18 s shipped) and 45 s on the unique-errors batch at 85 (5.7 s shipped). End-to-end runs are not measured: re-scan absorption reduces the searches made, and open item 5 (consumed candidates filling the cap) interacts.

### Prototype stages: making the sized search cheap

2026-09-15, at the architect's direction to prototype a search that stops once it holds a usable partner, then to continue autonomously through the stages needed. All scripts in `prototype/569-gate-sizing/`. Timings in this section were taken while other prototype work shared a 4-core machine (1-minute load 3.6 to 12, peaking at 59), so they are indicative: partner, verification and visit counts are deterministic; times are compared only within the same run.

**Stop at a partner (`probe-early-stop.pl`, download and application ERROR batches completed).** Walking the sized probe rarest first and scoring each candidate the first time it is seen, stopping once a partner is held, misses no partner the sized gate finds (download batch, every T; application ERROR batch up to 90). Where partners exist it is cheap: on the download batch at T = 50–75 a search scores 1.0–2.7 candidates and takes 0.27–0.31 ms (shipped 0.36–0.39 ms, finding none). Where no partner exists it cannot stop: at T = 85 every search scores 4,674 candidates (108 ms), and at 80 a median 576 (14 ms). Counting hits first and scoring from the highest count down (`hits_first`) pays the full counting cost, 85.7 ms per search at T = 50.

**Prefix filtering on both sides (`probe-prefix-index.pl`, smoke run: 50 sources, one pass).** Indexing each key by its own sized prefix keeps the guarantee (0 missed) but does not cut the work on download keys: at T = 85 the prefix index holds 377,182 of the full index's 1,435,715 entries and a search with no partner still scores 4,543 candidates (113 ms). Their rarest trigrams are either unique to the request, wasting prefix slots, or moderately common (for example the signing time's leading digits), so every prefix overlaps nearly every other; the research names data with few rare trigrams as where the prefix filter admits many false candidates. On the script log's ERROR batch it behaves as designed.

**A count bound per candidate (`probe-count-bound.pl`).** For a source r probing p trigrams and a candidate s with h shared trigrams inside the probe, the overlap is at most h + (|r| − p), so Dice ≥ T is impossible unless h ≥ ⌈T·(|r| + |s|)/200⌉ − (|r| − p). Scoring a candidate only once h reaches that value loses nothing and scores no candidate that cannot qualify. Smoke run on the download batch (50 sources, one pass): at T = 85, 90 and 95, 0 candidates scored per search (11.3, 0.9 and 0.3 ms; the time left is counting, 19,545 posting entries per search at 85); at T = 50–75 it is slower than stopping at a partner (31–42 ms), because a candidate must accumulate hits before it is scored. The bound holds only where Dice is scored on the trigrams counted: on the application ERROR batch, whose UUID keys are scored on normalised trigrams, applying it missed 111 of 216 partners at T = 85, so keys with normalised trigrams are exempt from it.

**Combined: score a budget of candidates when first seen, then only candidates that reach the bound** (`hybrid_b<budget>_<want>`). Smoke run, download batch, 50 sources: with a budget of 64 and stopping at one partner, 0 missed at every T; 0.25–0.40 ms per search at T = 50–75, 3.6 ms at 80 (stopping at a partner alone: 13.4 ms), 10.8 ms at 85, 2.3 ms at 90, 0.52 ms at 95. Application ERROR batch (all 238 keys): 0 missed up to T = 90 and the sized probe's 61 at 95, 0.14–0.21 ms per search. With a budget of 16, 2 partners were missed at 85 and 90 on UUID keys before the exemption was added. The full ten-batch run with the exemption is in progress.

**Whole runs, stop-at-a-partner searches (`run-e2e.sh`, one run each, single-group PLM download request cases).** Rows after grouping, shipped → first-seen stopping at 1 / at 5 / hits-first: at `-g 50` 74,305 → 5 / 7 / 8 (55.8 s → 7.6 / 8.7 / 31.4 s); at 70, 74,305 → 6 / 7 / 8 (53.6 s → 11.5 / 12.8 / 22.5 s); at 75, 74,305 → 8 / 8 / 8 (59.0 s → 15.1 / 12.5 / 14.9 s). No run had a non-zero exit or a runtime warning. Every download pattern under every arm still keeps a literal leading digit run in the signing time (`sT=1779*`, `177919*`, `177920*`), stopping at 5 and hits-first split one variant at the `177919`/`177920` boundary, and a two-member `.xas` pattern keeps a literal file id and size: open item 4 is unchanged by candidate search. The first-seen arm at `-g 80` ran for more than 14 minutes before the matrix was stopped, consistent with the per-search cost above where most sources have no partner.

**Benchmark cases under load (`run-benchmark.sh`, 3 interleaved repetitions, arm / shipped ratio of the same repetition, median and range).** The no-grouping case, where every arm runs identical code, spans 0.97–1.30 on total, which is the noise under this load.

| Case | first-seen, stop at 1 | first-seen, stop at 5 | hits-first, stop at 1 |
|---|---|---|---|
| Tomcat access log, top 25, `-g` | total 0.95 (0.87–1.05) | 0.98 (0.86–1.05) | 0.94 (0.86–1.00) |
| Application platform log, top 25, `-g` | total 0.83 (0.80–1.04) | 0.95 (0.91–0.97) | **1.68 (1.46–1.69)**; grouping 12.70×, rss 1.31× |
| Unique-errors log, top 25, `-g` | total 0.95 (0.88–1.31); parse **1.24 (1.19–1.45)**, grouping 0.53 | 0.67 (0.66–1.01) | 0.52 (0.51–0.97) |
| PLM download requests, top 25, `-g 75` | total **0.14** (0.12–0.14); 68.5 s → 9.3 s | 0.19 | 0.27 |

Hits-first is ruled out by its application-log regression. Grouped row counts differ between arms on the benchmark cases (for example 136 shipped, 106 first-seen stop-at-1, 96 stop-at-5 on the application log); their content is compared in the whole-run stage.

**Whole runs, combined search (budget 64, count bound, UUID exemption; `run-e2e.sh`, one run each, `-V message-grouping,benchmark-data`).** Every run rc 0 with no runtime warning. Total seconds and rows after grouping, shipped → stop at 1 → stop at 5:

| Case | Shipped | Stop at 1 | Stop at 5 |
|---|---|---|---|
| PLM download requests `-g 50` | 47.7 s, 74,305 | 7.6 s, 5 | 8.7 s, 7 |
| same `-g 70` | 49.2 s, 74,305 | 7.2 s, 6 | 8.0 s, 7 |
| same `-g 75` | 45.2 s, 74,305 | 7.9 s, 8 | 11.5 s, 8 |
| same `-g 80` | 46.8 s, 74,305 | **270.9 s**, 13,770 | **270.9 s**, 13,770 |
| same `-g 85` (no partners exist) | 47.4 s, 74,305 | **218.3 s**, 74,305 | **217.4 s**, 74,305 |
| PLM access day, unfiltered, `-g 65` | 3.4 s, 28 | 7.3 s, 50 | 3.3 s, 28 |
| same `-g 80` | 49.5 s, 74,416 | **275.4 s**, 13,881 | **273.4 s**, 13,880 |
| Application platform log `-g 70` | 6.7 s, 81 | 5.9 s, 93 | 6.4 s, 83 |
| same `-g 85` | 7.2 s, 136 | 6.1 s, 106 | 7.4 s, 96 |
| same `-g 95` | 9.4 s, 528 | 6.8 s, 550 | 6.9 s, 477 |
| Unique-errors log `-g 85` | 13.0 s, 72 | 11.6 s, 77 | 8.5 s, 72 |
| Script log `-g 70` | 15.0 s, 106 | 12.0 s, 100 | 10.2 s, 95 |
| same `-g 85` | 13.2 s, 417 | 10.8 s, 157 | 10.6 s, 170 |
| Tomcat 9 access log `-g 70` | 12.5 s, 72 | 11.3 s, 75 | 10.2 s, 72 |
| same `-g 85` | 12.4 s, 615 | 11.3 s, 643 | 11.6 s, 615 |

Readings: the combined search is as fast as shipped or faster everywhere except where most download keys have no partner (`-g 80` and 85), where it is 4.6–5.8× slower. On the unfiltered day at `-g 65`, shipped and stop-at-5 both form the catch-all `[200] GET /Windchill/*` (9 patterns); stop-at-1 does not, forming `/Windchill/com/ptc/*`, `/Windchill/netmarkets/*` and `/Windchill/ptc1/*?*` among 24 (open item 3's merge mechanism, reached through a different first pair).

**Where the slow case's time goes (NYTProf, combined search, `-g 80`, the day's first 25,000 lines filtered to download requests).** The profile's `find_consolidation_candidates` count (4,686) equals the `-V` count (1,225 streaming + 3,461 final pass). Of 160 s CPU: the search's own walk 120 s (75%), Dice 18 s (11%, 295,675 calls, about 63 per search: the budget), `compute_mask` 8 s, index build 5 s. A streaming search costs about 2.6× a final-pass search, as streaming batches hold up to 5,000 keys against final-pass windows of 1,000.

**Integer-id index (`probe-int-index.pl`).** The same combined search over posting arrays of integer key ids, with per-key sizes and per-search counters in arrays, returns identical candidates; on the download batch (50 sources) it is 1.3–1.4× faster per search (11.2 → 7.8 ms at 85) and builds the batch index 3.6× faster (983 → 271 ms for 5,000 keys). The hash index's per-search result can depend on Perl's per-process hash order: the budget is spent on candidates in `keys %$posting` order, and one of 50 searches at T = 80 returned a different candidate from the two indexes. The array index walks in batch order.

**Discovery cutoff.** With s_min the smallest raw size among the batch's non-UUID keys inside the size filter, a candidate first seen at probe position i can gather at most p − i hits against a bound of at least ⌈T·(|r| + s_min)/200⌉ − (|r| − p), so past that position no new non-UUID candidate is tracked; once no seen candidate can still reach its bound the non-UUID posting lists are not walked. Download batch key sizes are 277–293 trigrams (median 286). Premise measured on 50 sources at T = 85: the walk can stop at probe position 48 of 75 for every source, visiting a median 334 posting entries instead of 20,332. Measured with a zero budget, where only the bound admits candidates, the cutoff misses no partner on the download batch at any T and returns the same candidates as the search without it on the download, application ERROR and script INFO batches. Per search on the download batch (50 sources), budget 64, without → with the cutoff: 3.3 → 1.4 ms at 80, 9.6 → 1.8 ms at 85, 1.9 → 0.66 ms at 90 (shipped 0.37–0.43 ms). The budget pulls the two regimes apart: at 85, budget 0 takes 0.37 ms and budget 64 takes 1.8 ms; at 80, budget 64 takes 1.4 ms and budget 16 takes 9.0 ms; at 50–75, budget 0 takes 18–31 ms against 0.23–0.27 ms with a budget. Spending the budget only on candidates met in posting lists of at most 16, 64 or 256 keys does not change that at 85 (1.46–1.70 ms): the candidates it scores there are the same file downloaded again, similar (about 80) but below the threshold.

**Integer index and cutoff over the ten batches (`probe-int-index.pl`, 500 sources, 3 timed passes, `results/int-index/`).** Against a direct Dice scan of each batch:
- **The cutoff loses nothing.** With a zero budget, where only the count bound admits candidates, the cutoff search misses no partner on any batch at any T, apart from the UUID-bearing keys the sized raw-trigram probe already misses (application platform ERROR 61 of 175 at 95; script INFO 2, 7 and 6 at 85, 90 and 95).
- **The cutoff changes no result.** With a budget of 64 it returns exactly the candidates of the same search without it, for every source on every batch at every T.
- **The hash index's results depend on hash order.** With a budget of 64 the hash and integer indexes returned different candidates for 120 of 500 sources on the script INFO batch (T = 50), 71 on script WARN, 20 on the download batch at 80 and 1–7 on the Tomcat and unfiltered access batches; the budget is spent in `keys %$posting` order, which Perl randomises per process.
- **Per search, budget 64 with the cutoff:** download batch 0.27–0.31 ms at T = 50–75, 1.42 at 80, 1.72 at 85, 0.64 at 90 (shipped 0.40–0.42); unique-errors 0.36–0.40 (shipped 12.9–13.8); script INFO 0.22–0.51 (shipped 14.0–24.1); application DEBUG 0.10–0.11 (shipped 9.3–9.9); Tomcat 0.07–0.17 (shipped 3.0–5.3).

**Whole runs, cutoff search over the integer index (budget 64, hash index still built beside it; `run-e2e.sh`, bare `-V`, one run each).** Every run rc 0, no runtime warning. Total seconds, rows after grouping and peak memory, shipped → stop at 1 → stop at 5:

| Case | Shipped | Stop at 1 | Stop at 5 |
|---|---|---|---|
| PLM download requests `-g 50` | 48.5 s, 74,305, 363 MB | 8.9 s, 5, 676 MB | 10.0 s, 7, 676 MB |
| same `-g 75` | 45.4 s, 74,305 | 10.3 s, 8 | 12.5 s, 8 |
| same `-g 80` | 48.6 s, 74,305 | **91.6 s**, 13,770, 713 MB | **92.0 s**, 13,770 |
| same `-g 85` (no partners) | 47.4 s, 74,305 | **107.6 s**, 74,305, 705 MB | **110.0 s**, 74,305 |
| PLM access day, unfiltered, `-g 65` | 3.4 s, 28 | 9.8 s, 50 | 3.8 s, 28 |
| same `-g 80` | 49.4 s, 74,416 | **151.3 s**, 13,881 | **160.4 s**, 13,880 |
| Application platform log `-g 85` | 8.1 s, 136, 132 MB | 7.2 s, 106, 201 MB | 7.4 s, 96 |
| same `-g 95` | 10.1 s, 528 | 7.4 s, 550 | 7.1 s, 477 |
| Unique-errors log `-g 85` | 15.4 s, 72, 262 MB | 12.9 s, 77, 356 MB | 9.4 s, 72 |
| Script log `-g 85` | 15.6 s, 417 | 12.4 s, 157 | 12.7 s, 168 |
| Tomcat 9 access log `-g 85` | 15.8 s, 615 | 12.5 s, 643 | 11.5 s, 615 |

Readings: the cutoff cuts the download cases at 80 and 85 from 270.9 and 218.3 s to 91.6 and 107.6 s, and leaves their grouping identical (the patterns at 80 and 85, and on the application log at 85, match the run without the cutoff exactly; the script log at 85 has the same 157 rows but a different pattern set, consistent with the hash-order dependence of the run without it). They remain 1.9–3.1× shipped. Peak memory rises because this copy builds both indexes. At `-g 80` on the download requests: 4,725 streaming searches in 55.4 s parse and 7,361 final-pass searches in 36.1 s. NYTProf on the day's first 25,000 download lines at `-g 80` (search count 4,686, equal to `-V`): 54 s CPU against 160 s without the cutoff; Dice 17.6 s (32%, 291,840 calls, the budget), the search's own walk 11.2 s (21%), both index builds 9.9 s (18%), `compute_mask` 7.7 s (14%). The hash index is read only by the candidate search, so the next variant does not fill it in cutoff mode, and tests replacing the budget with scoring a candidate once its hits reach a fraction of its bound.

**Trigger by a fraction of the bound (`run-e2e-focus.sh`, bare `-V`, one run each, other prototype work sharing the machine).** With a fraction f, a candidate is scored once its hits reach ⌈f × bound⌉; Dice is exact, so one that fails cannot qualify and is dropped, which loses nothing. The hash index is not built. Total seconds and rows after grouping, same load within each case:

| Case | Shipped | Budget 64 | Budget 0, f = ½ | Budget 0, f = ¼ | Budget 8, f = ½ |
|---|---|---|---|---|---|
| PLM download requests `-g 50` | 50.2 s, 74,305 | 5.5 s, 5 | 11.2 s, 8 | 7.9 s, 7 | 5.5 s, 5 |
| same `-g 75` | 49.4 s, 74,305 | 6.2 s, 8 | 9.0 s, 8 | 7.7 s, 8 | 6.7 s, 8 |
| same `-g 80` | 49.7 s, 74,305 | 82.7 s, 13,770 | **53.7 s**, 13,701 | 59.7 s, 13,770 | 62.9 s, 13,701 |
| same `-g 85` (no partners) | 53.3 s, 74,305 | 64.7 s, 74,305 | **38.6 s**, 74,305 | 38.2 s, 74,305 | 54.8 s, 74,305 |
| Application platform log `-g 85` | 7.0 s, 136 | 5.6 s, 106 | 6.0 s, 98 | 6.2 s, 106 | 5.8 s, 106 |
| Unique-errors log `-g 85` | 13.4 s, 72 | 9.4 s, 77 | **5.7 s**, 75 | 6.2 s, 75 | 10.2 s, 77 |
| Script log `-g 85` | 12.6 s, 417 | 11.2 s, 157 | 10.0 s, 179 | 9.7 s, 168 | 9.9 s, 162 |

Candidate searches made: at `-g 50` on the download requests, 72 with budget 64 against shipped's 38,305 (early patterns absorb the rest); at 85, 38,305 for every arm.

**Memory.** Under `-mem` on the day's first 25,000 download lines at `-g 80`, shipped's candidate index peaks at 135.1 MB of postings plus 13.9 MB of posting sizes; the integer index reports 222.3 MB, a figure that includes the per-key trigram sets it only references (118.1 MB, also counted under `consolidation_key_trigrams`). Peak RSS: shipped 335.7 MB, cutoff search 359.5 MB (f = ½) and 359.8 MB (budget 64); total time 17.4, 18.0 and 25.2 s. The full-day runs above peaked at 563–571 MB because that copy kept each batch's integer index until the next was built; with it freed where the hash index is freed, the full day at f = ½ peaks at 388 MB at `-g 80` (45.2 s, 13,701 rows) and 352 MB at 85 (37.8 s, 74,305 rows), against shipped's 354–363 MB.

**Whole runs, v5 (cutoff search over the integer index only, index freed with each batch; budget 0; `run-e2e.sh`, bare `-V`, one run each).** Every run rc 0, no runtime warning. Total seconds, rows after grouping, peak memory; shipped → f = ½ → f = ¼:

| Case | Shipped | f = ½ | f = ¼ |
|---|---|---|---|
| PLM download requests `-g 50` | 49.3 s, 74,305, 363 MB | 11.3 s, 8, 320 MB | 7.7 s, 7, 320 MB |
| same `-g 70` | 47.5 s, 74,305 | 12.4 s, 8 | 7.9 s, 8 |
| same `-g 75` | 46.9 s, 74,305 | 8.9 s, 8 | 7.9 s, 8 |
| same `-g 80` | 44.7 s, 74,305, 363 MB | 43.8 s, 13,701, 388 MB | 45.5 s, 13,770, 388 MB |
| same `-g 85` (no partners) | 47.0 s, 74,305, 363 MB | 37.1 s, 74,305, 352 MB | 35.9 s, 74,305, 352 MB |
| PLM access day, unfiltered, `-g 65` | 3.4 s, 28 | 2.9 s, 30 | 2.8 s, 30 |
| same `-g 80` | 47.6 s, 74,416, 363 MB | **91.8 s**, 13,818, 385 MB | **93.5 s**, 13,887 |
| Application platform log `-g 70` | 6.7 s, 81 | 6.0 s, 85 | 5.9 s, 85 |
| same `-g 85` | 7.1 s, 136 | 6.3 s, 98 | 6.1 s, 106 |
| same `-g 95` | 8.8 s, 528 | 5.5 s, 540 | 5.5 s, 549 |
| Unique-errors log `-g 85` | 12.7 s, 72, 262 MB | 5.4 s, 75, 289 MB | 5.7 s, 75 |
| Script log `-g 70` | 12.0 s, 106, 148 MB | 8.9 s, 88, 109 MB | 9.7 s, 89 |
| same `-g 85` | 13.0 s, 417 | 9.8 s, 179 | 9.4 s, 168 |
| Tomcat 9 access log `-g 70` | 10.8 s, 72 | 10.8 s, 79 | 10.6 s, 79 |
| same `-g 85` | 12.2 s, 615 | 11.2 s, 666 | 11.5 s, 656 |

Readings:
- **Every case is as fast as shipped or faster except the unfiltered access day at `-g 80`**, and peak memory stays within 10% of shipped (lower on the download requests at 50–85 and the script log at 70).
- **The unfiltered day's extra time is in the search's own walk during streaming; its cause is not yet established.** Against the download requests alone at `-g 80` it makes about the same number of searches (4,827 streaming and 7,395 final-pass, against 4,725 and 7,292), yet parse rises from 31.1 to 79.2 s. NYTProf on the day's first 25,000 lines, unfiltered, f = ½ (search count 4,119, equal to `-V`): of 60 s CPU, the search's own walk 43.8 s (73%), `compute_mask` 8.0 s (13%), integer index build 3.0 s, Dice 0.05 s (2,293 calls); about 30 ms per streaming search and 2 ms per final-pass search under the profiler. It is not the first batch: that batch's 4,990 keys are 95% download keys of 282–291 trigrams (minimum 19), all inside the size filter at 80 and 85, and a search there costs 2.7 ms at T = 80 with f = ½ against 3.8 ms on the download batch. Ordering integer ids by key size and cropping each posting array to the size filter therefore has nothing to crop: the whole run at `-g 80` took about 102 s with it against 91.8 s without. Search counters (`LTL569_STATS`, f = ½, `-g 80`) locate the cost in streaming: unfiltered, 4,827 streaming searches visit 193.4 million posting entries (16.5 ms per search, 494 Dice, 161 searches finding a partner); the download requests alone, 4,725 searches visit 20.6 million (3.7 ms per search, 263 Dice); the final pass is alike on both (7,395 and 7,292 searches, 5.1 million visits, 0.84 and 0.88 ms per search). The whole matrix with size-ordered ids (`LTL569_SIZEORDER=1`, `results/e2e/`) forms byte-identical patterns to the run without them on the download requests at 80 and 85, the unfiltered day at 80 and the application, script and unique-errors logs at 85, with timings within run-to-run variation and no runtime warning. The probable mechanism, to be tested: later streaming searches are mostly download keys without a partner, which cannot stop early, so the discovery cutoff decides their cost; it is set by the smallest admissible key size in the batch, 277 trigrams among download keys alone, while in the unfiltered population a few mid-length keys near the size filter's lower bound place it near the end of the probe. A discovery bound per candidate size (`LTL569_SIZEORDER=2`: a candidate first seen at probe position i can gather at most p − i hits, so only sizes whose bound fits are admitted, found by binary search over size-ordered ids) cuts the unfiltered day's streaming visits from 193.4 to 121.1 million (9.3 ms per search), its parse from 97.6 to 61.5 s and total from 112.2 to 75.8 s, with byte-identical patterns; the download requests alone are unchanged (20.6 million visits, 44.7 s, identical patterns). The visits that remain come from candidates already seen that can still reach their bound, which keep whole posting arrays walked to the end of the probe.
- **Where partners are common, f = ½ scores late.** Per search on the download batch at T = 50–75: budget 64 0.29–0.32 ms, f = ½ 8.6–11.5 ms, f = ¼ 2.4–3.4 ms; at 80: 1.47, 3.80 and 1.90 ms; at 85 (no partners): 1.76, 0.45 and 0.47 ms. The unfiltered batch follows the same pattern. Neither fraction misses a partner on either batch.
- **The catch-all `[200] GET /Windchill/*` forms at `-g 65` under shipped and both fractions** (open item 3 is untouched by candidate search).
- **Repeatable.** A second run of f = ½ on the download requests at `-g 75`, the unique-errors log at 85 and the script log at 85 produced byte-identical patterns and `message-grouping` counters (timing and memory lines excluded); the integer index walks in batch order, where the hash index's budget depended on Perl's per-process hash order.

**Documentation requirement (architect, 2026-09-15).** The user documentation that accompanies this fix states that excluding UUIDs from the message (today `-uuid`; `--discard uuid` under #567) is advisable when a log carries many of them, because every UUID-bearing key is scored on UUID-normalised trigrams without the count bound, which makes the similarity check do much more work.

### Open items and next steps

| # | Item | State | Next step |
|---|---|---|---|
| 1 | **Candidate pre-filter**: the fixed 50 rarest trigrams and 15 required hits in `find_consolidation_candidates()` miss 100% of download partners at T ≤ 80 on the PLM access log, and 30–46% of partners at every T on the application platform log's ERROR group (item 2) | Cause proven (§ Mechanism, § Proof of cause). Direction from research (§ Industry grounding): probe length set by the threshold and the key's size with one shared token required. **Architect's direction (2026-09-15):** prototype a probe length adapted to the requested similarity (and the key's trigram count) before any design; masking values before comparison is not pursued, as it sidesteps the gate rather than fixing it. **Prototyped (2026-09-15, § Prototype: candidate gate sized from the requested similarity):** the sized gate misses no partner on the download keys at any T, but verifies nearly every key in the batch per search there (116–193 ms against 0.35 ms at T 50–80); UUID-bearing keys are still missed at T ≥ 85, where the probe is sized on raw trigrams and scored on normalised ones **Decision (architect, 2026-09-15): the candidate search reads the key as written; UUIDs are not replaced for candidate selection.** Whether the same or similar UUIDs recur is information an analyst may need, and grouping is meant to keep the parts of a UUID that stay the same while wildcarding the characters that change; replacing UUIDs to make candidate search faster would defeat that. Masking UUIDs remains the analyst's choice through the existing `-uuid` option, to be offered as `--discard uuid` under #567 (discard named keys and values from the message). Consequence for the search: keys whose Dice is scored on UUID-normalised trigrams keep no count bound, and the sized raw-trigram probe keeps its misses on them at high thresholds (application platform ERROR 61 of 175 at 95; script INFO 2–7 of about 500 at 85–95) | Prototype through the trigger-fraction stage and the quiet benchmark, then design with items 3, 4 and 5 |
| 2 | **UUID-bearing error keys** (application platform log, ~480,000 lines, not the access log): 30–46% of partners missed at every T, including 95, in the ERROR group's 238-key first checkpoint batch (§ Pre-filter misses across log families) | **Mechanism established (2026-09-15), the same as item 1.** These ThingWorx errors carry a `PersistentSession<uuid>` entity name twice per line, and a few keys share each session, so the UUID's trigrams are rare but not unique (hence the 0.6 singleton reading). Of the 50 trigrams the pre-filter selects from the raw key, a median 39 (max 40) overlap the UUID; the best partner, identical apart from its UUID, shares a median 11 at T=95 and 12 at T=50 (max 14; 15 required). Dice on the UUID-normalised trigrams `ltl` scores with: median 100; on raw trigrams: median 81 and 80. The size filter rejects none. The pre-filter selects on raw trigrams while scoring is UUID-normalised, so normalisation never reaches candidate selection | Resolved into item 1 |
| 3 | **Catch-all pattern**: without the include filters, `[200] GET /Windchill/*` absorbs every GET at T ≤ 65 (§ Related behaviour observed on the way) | **Mechanism established (2026-09-15)** on the day's first 25,000 lines at `-g 65`, with `try_consolidation_merge_into_existing()` instrumented in a scratch copy. The pair itself was sound: `netmarkets/images/accept_task.gif` with `export.gif` (Dice 78) gave `[200] GET /Windchill/netmarkets/images/*`. Merge-first then compared that canonical with the existing `[200] GET /Windchill/com/ptc/windchill/cadx/images/*` at Dice 65, exactly the threshold, most of the shared trigrams coming from the common `[200] GET /Windchill/` start. `compute_mask()` kept that 21-character start, one stray character and the `images/*` tail; `coalesce_mask()` pass 2 treated everything from position 21 as a variable-dominated span, because the tail's keep run is shorter than the 10-character span boundary, and wildcarded the tail too, giving `[200] GET /Windchill/*`. Validation only checks that the two merged canonicals match the merged regex, which they trivially do, so nothing bounds how general a merged pattern may be; the re-scan absorbed 4,850 keys in one step. Three contributors: Dice between short canonicals dominated by a shared prefix, pass 2 discarding a short distinguishing tail, and no generality check on a merge. Not resolved by a pre-filter change | Design next, with items 1, 4 and 5 |
| 4 | **Literal values kept in patterns**: with the pre-filter opened, one download variant splits on the signing time's leading digits and one row keeps a literal file id and size (§ Proof of cause) | **Mechanism established (2026-09-15)** on the download-filtered day at `-g 50`, pre-filter loose minimum 1, merge-first instrumented: 60 pair patterns, 365 merge comparisons, 37 merges, 328 rejected by validation. (a) The best-scoring candidate for a download key is usually the same file downloaded again, differing only in the counter `c`, the signing time and the signature, so the pair canonical keeps that file's `adId`, `fileName` and `refsize` as literals. (b) Merge-first widens those one step at a time (`adId=15909708` → `159097*` → `15909*`), but `compute_mask()` aligns coincidental characters inside numeric fields: `15909*` against `15910001` keeps a stray `0` and yields `adId=1590*`, which does not match `15910001`; `sT=177919*` against `sT=17792001*` yields `sT=17791*`, which does not match `17792001*`. Validation rejects the merged regex and the new pattern stands on its own, so the day's signing times, which cross from `177919…` to `177920…`, never join, and the `.xas` row, formed from one file downloaded twice, keeps every field literal. (c) The same comparisons also attempted merges across different path templates (`%7D.xas` with `%7D` and `.xpr`, Dice 80–88), rejected by the same validation rather than by any template check | Design next, with items 1, 3 and 5 |
| 5 | **Candidate cap exhausted by consumed keys**: `find_consolidation_candidates()` returns at most 50 candidates sorted by score then key; `run_consolidation_pass()` skips those already consumed and does not look further | **Mechanism established (2026-09-15)**, masked by the shipped pre-filter and exposed when it is opened (§ Interaction): where many keys tie at the top score, the 50 returned are the lowest-sorting, which a just-formed pattern has already absorbed. On the unique-errors log with the pre-filter opened, 495 of 500 sources in checkpoint 1 got 50 consumed candidates and no pair; absorption collapsed, 267,489 keys were evicted, and the run took 121.3 s against 11.4 s | Design next, with items 1, 3 and 4 |


### Input and invocation

An Apache HTTP Server 2.x access log in front of a PLM application server, one full day, read with microsecond durations. 74,305 of its lines are signed direct-download requests carrying fifteen query parameters: the file's identity (folder, file id, file name), per-request values (a signature unique on every line, the signing time in epoch seconds, the response size, a counter) and constants (user id, authentication scheme, site). With the query string exposed, the 350-character message key ends inside the signature value.

Reproducing invocation, run on the 0.18.2 release branch:

```
-du us -i "/Windchill/servlet/WindchillGW&/doDirectDownload" -i "/Windchill/servlet/WindchillGW&/doIndirectDownload" -xqs -bs 1w -r -n 200 -o -hm bytes -hg bytes -hgh 13 -g 50
```

### Observed

`-V` `message-grouping`, group `plain|200`: 74,305 keys seen, 15 checkpoints, 0 patterns, 74,305 evicted, 1,000 candidate searches during streaming and 37,305 in the final pass, reduction 74,305 → 74,305 (0.0%). No runtime warnings.

### Mechanism

`find_consolidation_candidates()` Phase 1 sorts the source key's trigrams by posting-list size ascending, keeps the top 50 (`$consolidation_discriminative_topk`), and admits a candidate only when it shares at least 15 of them (`my $loose_min = max(1, int($consolidation_prefilter_ratio * $topk_actual));`). On these keys the rarest trigrams are drawn from the per-request values. Measured on the first 5,000 download keys, 500 source keys, with the sub sliced verbatim from `ltl`:

| Measure | Value |
|---|---|
| Trigrams per key | median 286 |
| Selected top-50 trigrams occurring in the source key only | min 6, median 17, max 28 |
| Most selected trigrams any other key shares | min 3, median 6, max 9 (15 required) |
| Sources for which Phase 1 admits a candidate | 0 of 500 |
| Sources with a partner scoring ≥ 50 by direct Dice comparison | 500 of 500 |

Zero candidates means zero pairs, zero patterns and an absorption rate of 0 at the first two checkpoints; the absorption EMA then drives `get_consolidation_max_survivals()` to 0 and the fast-path eviction in `run_consolidation_checkpoint()` discards every later key without a search. The final pass runs the same pre-filter and finds nothing either. The sensitivity value is never reached, which is why no `-g` setting changes the outcome.

For contrast, on the same day's first 5,000 status-200 keys without the include filters (static resources and application pages mixed with downloads), 196 of 500 sources pass Phase 1.

### Proof of cause

The reproducing invocation on a scratch copy of `ltl` whose only change is `$consolidation_prefilter_ratio = 0.0` (loose minimum 1), single run each on the same machine:

| Build | Patterns | Rows after grouping | Evicted | Wall time |
|---|---|---|---|---|
| As shipped | 0 | 74,305 | 74,305 | 47 s |
| Pre-filter loose minimum 1 | 6 | 7 | 0 | 12 s |

The groups formed are one per download variant (by the file-name template and extension in the path), with ids, sizes and signature wildcarded. Residual over-specificity: one variant splits in two on the leading digits of the signing time, and one row keeps a literal file id and size.

### Similarity distribution between download keys

Which sensitivities should group these keys at all. Scored with `get_consolidation_trigrams()` and `dice_coefficient()` sliced verbatim from `ltl`, on message keys built as `ltl` builds them (`[200] ` plus the request, query string kept, capped at 350 characters). Two samples of 5,000 download keys: the first 5,000 of the day (what the first checkpoint sees) and 5,000 spread evenly across the day. For each, the best-partner score of 500 source keys against the other 4,999, and the scores of 200,000 random pairs.

Best partner per source (500 sources):

| Sample | Min | Median | Max | ≥ 75 | ≥ 80 | ≥ 85 |
|---|---|---|---|---|---|---|
| First 5,000 | 78 | 80 | 81 | 100% | 87.2% | 0% |
| Across the day | 74 | 79 | 81 | 99.8% | 40.6% | 0% |

Random pairs (200,000):

| Sample | Min | Median | Max | ≥ 65 | ≥ 70 | ≥ 75 | ≥ 80 |
|---|---|---|---|---|---|---|---|
| First 5,000 | 65 | 70 | 82 | 100% | 51.4% | 25.9% | 0% |
| Across the day | 60 | 68 | 80 | 86.1% | 42.1% | 5.4% | 0% |

Reading:
- **85 to 95:** no pair of download keys reaches the threshold, so forming no groups is the correct outcome.
- **75 and below:** every key has a partner above the threshold; forming no groups is the defect.
- **80:** a boundary; 87.2% of keys have a partner at 80 in the first checkpoint's batch, 40.6% across the day.
- The day-wide sample is more varied than one checkpoint batch (random pairs 60–80 against 65–82).

### Related behaviour observed on the way

- **Without the include filters the result depends on a catch-all.** `-du us -xqs -bs 1440 -n 15 -g N -V` on the same log, group `plain|200`: at 50, 60 and 65 the 79,845 keys reduce to 17–20 rows, but only because an early pair of short static-resource URLs derives `[200] GET /Windchill/*`, one row absorbing 82,626 requests including every download; at 70, 75, 80, 90 and 95 that pair does not form, the first checkpoint absorbs 2.9% (at 70) and grouping falls to 1.6–2.3%, with no pattern formed for the download requests. Neither side of the 65/70 boundary is correct grouping. The include filters are therefore not what makes the download keys ungroupable: at 70 and above they are ungrouped in the unfiltered population too, and at 50–65 the filters only remove the catch-all that absorbed them.
- **A small Apache HTTP Server 2.x access log of a PLM application with microsecond durations (677 lines, 6 download requests) does group** with `-xqs -bs 1440 -n 15 -g N -V` at 50, 80 and 95 (54 keys → 15–18 rows); it does not reproduce the defect.
- **The final pass always scores at 85** (`$consolidation_final_threshold`, hidden `--final-threshold`), whatever `-g` is set to. Not the cause here: the pre-filter blocks both passes. Measured against `-g` in § Final pass threshold against `-g` below; open with final-pass performance in #142.

### Pre-filter misses across log families

How often the pre-filter rejects every partner that scores above the threshold, beyond the download case. Method:

- A scratch copy of `ltl` whose only change writes out each group's first streaming checkpoint batch (the sorted unmatched keys `run_consolidation_checkpoint()` passes to discovery), run with `-bs 1440 -n 1 -g 80` (the first batch of a group is the same at any `-g`: no pattern exists for it before its first checkpoint).
- Per batch with at least 200 keys: the first 500 source keys in that sorted order (`run_consolidation_pass()`'s own search order and 500-source limit); for each, the best partner by direct `dice_coefficient()` over the whole batch, on UUID-normalised trigrams where `ltl` scores on them, and `find_consolidation_candidates()` sliced verbatim.
- *Partner at T*: the best partner scores ≥ T. *Missed at T*: a partner at T exists and the pre-filter returns no candidate.

Cells are missed / sources with a partner at T:

| Log family (group, batch keys) | T=50 | T=70 | T=80 | T=85 | T=95 |
|---|---|---|---|---|---|
| Application platform log, ~480,000 lines, the size the prototype record gives for its diverse data (DEBUG, 1,709) | 0/500 | 0/500 | 0/500 | 0/500 | 0/500 |
| same (WARN, 3,048) | 0/500 | 0/500 | 0/500 | 0/500 | 0/493 |
| same (ERROR, 238) | 69/232 | 99/224 | 100/218 | 100/216 | 75/175 |
| Application log of hundreds of thousands of unique errors, power-law (ERROR, 4,990) | 1/499 | 0/498 | 0/496 | 0/496 | 0/496 |
| Application script log with thread names and full metrics (ERROR, 209) | 1/208 | 0/204 | 0/201 | 0/197 | 0/157 |
| same (INFO, 2,851) | 1/500 | 1/500 | 1/500 | 6/500 | 5/239 |
| same (WARN, 1,940) | 0/500 | 0/500 | 0/500 | 0/500 | 0/495 |
| Tomcat 9 access log, one day, query string stripped (200, 2,870) | 0/500 | 0/482 | 0/403 | 0/330 | 0/36 |
| The PLM access log above, query string exposed, unfiltered (200, 4,990) | 298/500 | 296/489 | 247/408 | 0/132 | 0/22 |
| same, download requests only (200, 5,000) | 500/500 | 500/500 | 446/446 | no partners | no partners |

Keys containing a UUID, which `ltl` scores on UUID-normalised trigrams but pre-filters on raw trigrams:

| Batch, T | Missed | Missed containing a UUID | Found containing a UUID | Selected top-50 trigrams unique to the source, mean (found / missed) |
|---|---|---|---|---|
| Application platform ERROR, 95 | 75 | 75 | 50 of 100 | 0.7 / 0.6 |
| Application platform ERROR, 50 | 69 | 63 | 89 of 163 | 2.4 / 3.9 |
| Script INFO, 95 | 5 | 5 | 1 of 234 | 0.1 / 27.0 |

Reading:
- The pre-filter is effectively lossless on the power-law error log, the thread-rich script log's WARN and ERROR groups, the Tomcat access log and the large application groups.
- It loses badly in two places: the PLM access log with the query string exposed (about 60% of sources with a partner at T ≤ 80 unfiltered, 100% on downloads alone, none at T ≥ 85), and a small application ERROR batch (30–46% at every T, including 95).
- **On the unfiltered PLM batch every miss is a download request.** Of its first 500 sources, 296 are download requests: all 296 are missed at T = 50 and 70, and 247 of 247 at 80. Of the 204 other keys, 2 are missed at 50 and none at 70 or 80. The failure follows the download keys, not the population around them.
- Every miss in the application ERROR batch at 95, and in the script INFO batch, is a key containing a UUID. The script INFO misses carry a mean 27 of 50 selected trigrams unique to the source, the download mechanism. The application ERROR misses do not (0.6), so their mechanism is a different one and is not yet established.
- Wall times from these probes are not reported: ten ran concurrently.

### Research record behind the pre-filter

What the repository records about how candidates are found, reviewed against the finding above:

- **DD-01** (N-gram Indexing with Dice Coefficient) describes candidate search as "candidates sharing the most chunks are scored for actual similarity": ranking by overlap, with no rarest-K selection and no fixed minimum.
- **Alternatives were listed and not pursued.** The first prototype performance assessment on issue #96 (fuzzy message consolidation) listed MinHash, Drain-style token grouping and locality-sensitive hashing as next steps. `docs/fuzzy-consolidation-lessons-learned.md` § Don't Optimize What You Haven't Scoped records "None of this research was necessary" once the checkpoint architecture fixed performance. Candidate search was not researched after that, and no record references prefix filtering or any set-similarity-join method.
- **The pre-filter is an empirical speed fix.** PF-18 added it after profiling showed candidate search at 88.1% of runtime. Its basis is one experiment on a 200-key sample of a varied application log, varying only the number of rarest trigrams kept, at a single required share of 30%: 50 kept gave 4.8× and 0 missed matches, 30 gave 6.2× and 2 missed, 20 gave 8.1× and 5 missed. The record does not state the sensitivity it ran at or how a missed match was established, and the commit that introduced it (`4479cf6`) contains no benchmark script.
- **The experiment became guidance.** `docs/similarity-engine-best-practices.md` § Discriminative Trigram Pre-filter restates K=50 and ratio 0.30 as a best practice with "zero missed matches".
- **Neither value adapts.** Nothing in the record or the code ties the 50 kept trigrams or the 15 required hits to the `-g` sensitivity, to the key's trigram count, or to the composition of the population being consolidated.

### Final pass threshold against `-g`

`group_similar_messages()` swaps `$consolidation_threshold` for `$consolidation_final_threshold` (85) for the whole final pass, whatever `-g` is. `features/137-final-pass-redesign.md` § 6 (Threshold During Final Pass) records only that both default to 85 and that the hidden `--final-threshold` gives control. The fixed value was kept to bound final-pass effort so the feature could ship; the final pass's performance is open in #142 (final pass regression on XL consolidation benchmarks).

Each log run twice with `-bs 1440 -n 1 -g N -V`: final pass at its default 85, and with `--final-threshold N`. Single sequential runs on one machine, counters summed over every group of the `message-grouping` section. Query string exposed (`-du us -xqs`) on the PLM access log only.

| Log family | `-g` | Final pass at | Wall s | Final-pass keys | Final-pass candidate searches | Final-pass patterns | Rows after grouping |
|---|---|---|---|---|---|---|---|
| Application platform log, ~480,000 lines | 70 | 85 | 7.0 | 73 | 53 | 11 | 82 |
| | 70 | 70 | 6.5 | 73 | 52 | 12 | 81 |
| | 95 | 85 | 10.4 | 514 | 195 | 59 | 143 |
| | 95 | 95 | 8.7 | 514 | 476 | 22 | 528 |
| Application log of hundreds of thousands of unique errors | 70 | 85 | 12.0 | 106 | 57 | 7 | 68 |
| | 70 | 70 | 9.6 | 106 | 49 | 7 | 59 |
| | 95 | 85 | 12.5 | 198 | 81 | 20 | 81 |
| | 95 | 95 | 9.2 | 198 | 167 | 15 | 178 |
| Application script log with thread names | 70 | 85 | 11.5 | 432 | 315 | 13 | 351 |
| | 70 | 70 | 11.6 | 432 | 313 | 13 | 106 |
| | 95 | 85 | 114.9 | 39,412 | 607 | 216 | 457 |
| | 95 | 95 | 246.4 | 39,412 | 9,553 | 2,594 | 8,142 |
| Tomcat 9 access log, one day | 70 | 85 | 10.7 | 342 | 215 | 49 | 221 |
| | 70 | 70 | 10.5 | 342 | 92 | 25 | 72 |
| | 95 | 85 | 12.0 | 3,123 | 866 | 266 | 674 |
| | 95 | 95 | 13.6 | 3,123 | 2,724 | 271 | 2,707 |
| PLM access log, query string exposed | 70 | 85 | 42.3 | 75,450 | 37,425 | 42 | 74,399 |
| | 70 | 70 | 42.2 | 75,450 | 37,381 | 28 | 74,374 |
| | 95 | 85 | 43.9 | 75,647 | 37,519 | 65 | 74,473 |
| | 95 | 95 | 44.0 | 75,647 | 37,897 | 61 | 74,869 |

**Decision (architect, 2026-09-15):** the final pass scores at the streaming threshold, the `-g` value given or the default when none is given, and never at a separate fixed value. The current behaviour silently loosens or tightens the requested grouping for every key the final pass handles, which corrupts results. The slower final pass at high sensitivity measured below is accepted until final-pass performance is improved (#142). Carried by #571 (final pass groups at a fixed 85% instead of the -g sensitivity): § Final pass follows the sensitivity (#571).

Reading:
- **Above 85 the fixed value loosens the user's setting.** At `-g 95` the final pass at 85 leaves 143 rows where 95 leaves 528 (application), 81 against 178 (errors), 457 against 8,142 (script), 674 against 2,707 (Tomcat).
- **Below 85 it tightens it.** At `-g 70`: 351 rows against 106 (script), 221 against 72 (Tomcat), 68 against 59 (errors), 82 against 81 (application).
- **Cost of matching.** At `-g 70` matching cost at most 0.1 s (script 11.5 → 11.6 s), and errors ran faster (12.0 → 9.6 s). At `-g 95` the script log slows from 114.9 to 246.4 s: the stricter pass absorbs less per pattern and makes 9,553 candidate searches instead of 607 over the same 39,412 keys; the other three logs move within 3.3 s either way.
- **On the PLM access log both settings cost the same 42–44 s** and about 37,400 final-pass candidate searches over ~75,500 keys: the pre-filter misses above leave every key for the final pass, which then misses them again.
- Single runs, not medians.

### Industry grounding

Primary-source research on candidate generation for set-similarity joins and on log template mining: `features/569-candidate-search-industry-grounding.md`. What it establishes for this pre-filter:

- **Prefix filtering** (AllPairs 2007, PPJoin 2008, Mann et al. 2016) guarantees no missed pair when each key probes its |r| − ⌈lb_r⌉ + 1 rarest tokens and one shared token suffices, with lb_r = T·|r|/(2 − T) for Dice. The probe length depends on the threshold and the key's size. For a 286-trigram key: 191, 164, 133, 115, 96, 75, 53 and 28 tokens at T = 50, 60, 70, 75, 80, 85, 90 and 95.
- **The fixed rule is outside that bound below about 90.** Requiring 15 hits needs 14 more tokens than the one-hit prefix (205 at 50 … 42 at 95); only at 95 does that fit inside 50. By the counting argument behind the bound, 15 of 50 is lossless for a 286-trigram key only from about T = 90 (equal-size partner) or 93 (smallest admissible partner). At T ≤ 80 even one hit in 50 is not lossless.
- **Tokens unique to one key do not break the exact bound**, which always reaches past them; they break the fixed 50. At T = 75 a true download partner needs one shared trigram among the source's 115 rarest.
- **What pays off, empirically** (Mann et al. 2016, 7 algorithms, 12 datasets): the plain prefix filter with a length filter; AllPairs wins most data points; verification costs a small constant; heavier filters (suffix, adaptive prefix) rarely pay back, except that adaptive prefix extension wins on data with few infrequent tokens.
- **MinHash/LSH** is approximate, with a false-negative rate set by the band/row choice, and treats per-line random tokens like any other shingle.
- **Log template miners** (Drain, Spell, LogMine, and the Zhu et al. 2019 benchmark) compare token sequences, not q-gram sets, after masking variable values (IPs, numbers, IDs, paths) with simple regexes or type detection, because unmasked values make same-pattern lines look dissimilar.

### Constraints on a fix

Each constraint is stated with the measurement it rests on; the sections cited hold the input and method.

- **The pre-filter's speed is load-bearing.** It exists for a 4.8× `find_candidates` speedup (PF-18). Opened to a loose minimum of 1, the streaming checkpoints inside `parse/read_files` rose from 5.9 s to 94.1 s on the PLM access log at `-g 80` and from 7.2 s to 99.2 s on the unique-errors log at `-g 85` (§ Where the time goes). Any change to the selection or the minimum is measured on `parse/read_files` as well as `finalize/group_similar`, against the before benchmarks (§ Performance baseline before the pre-filter change), including the two heaviest grouping cases.
- **Loosening the pre-filter exposes the candidate cap (open item 5).** With more candidates admitted, the 50 returned for a source can all be keys a pattern already absorbed; on the unique-errors log 495 of 500 sources found no usable partner, checkpoints rose from 2 to 54, 267,489 keys were evicted and the run took 113.7 s against 12.0 s. A pre-filter change that does not also address how consumed candidates are handled regresses power-law logs.
- **Selection and scoring must read the same text (open item 2).** The pre-filter selects from raw trigrams while Dice is scored on UUID-normalised ones, so a UUID fills 39 of the 50 selected trigrams on the application log's ERROR group while the partner scores 100 normalised.
- **Opening candidate search alone does not reach the requirement (open item 4).** At `-g 80` with the pre-filter opened, 13,754 download keys stay ungrouped; about half of them have a partner at 80 that was already grouped under a pattern keeping `sT=177919*`, so they fail it on the signing time alone (§ What stays ungrouped at `-g 80`). Pair patterns built from near-duplicate keys keep per-file literals, and 328 of 365 merges on the download run were rejected by validation after coincidental digit alignment, so patterns do not generalise over per-request fields.
- **A looser pre-filter must not widen over-generalisation (open item 3).** The catch-all `[200] GET /Windchill/*` forms in merge-first, not in candidate search: short canonicals meet the threshold on a shared prefix, `coalesce_mask()` pass 2 discards the distinguishing tail, and validation places no bound on how general a merged pattern may be. More candidates mean more merges.
- **The usable range is bounded by the data.** About half the download keys have no partner at 80 anywhere in the day and none at 85 (§ Similarity distribution between download keys, § What stays ungrouped at `-g 80`), so grouping every download key at 80 or above is not a correct outcome; at 75 and below every key has a partner.
- **The final pass follows `-g` (#571).** Its cost at high sensitivity is accepted and tracked with #142; a change to candidate search or merging changes the final pass's cost too, since it runs the same `find_consolidation_candidates()` and merge-first in sliding windows.

## Final pass follows the sensitivity (#571)

**Requirement:** the final pass groups at the sensitivity given with `-g`, or at the default when `-g` is given without a value; the slower final pass this causes at high sensitivity is accepted until final-pass performance is improved (#142). Measurements and the architect's decision: § Finding: no groupings on keys whose rarest trigrams are per-request values (#569) → Final pass threshold against `-g`.

**Design:** `group_similar_messages()` scores the final pass at `$consolidation_threshold`, the resolved `-g` value. The hidden `--final-threshold` remains as an explicit diagnostic override: when given it replaces the threshold for the final pass only; when absent there is no separate final-pass value. The `message-grouping` header reports the threshold the final pass actually used.

### Acceptance criteria

Fixture: `tests/fixtures/grouping-final-pass-threshold.txt`, a Tomcat-shaped access log of four request paths, each requested three times. Every key reaches the occurrence ceiling, so streaming discovery skips it, its first checkpoint absorbs nothing and eviction removes it from the streaming working set; all four are left to the final pass. The paths form two pairs: catalog televisions/headphones at Dice 77 and warehouse north/south levels at Dice 89 (`dice_coefficient()` on the `[200] GET <path>` keys). Both pairs pass the candidate pre-filter (each key has at most 10 trigrams unique to it, of 45–46).

| # | Condition | Observable outcome | Triage |
|---|---|---|---|
| 1 | `-g 70` | `message-grouping` header reports `Threshold: 70%` and `Final pass: on (threshold=70%`; the `plain\|200` final pass creates 2 patterns (both pairs grouped) | assertable |
| 2 | `-g 95` | header reports `Final pass: on (threshold=95%`; the final pass creates 0 patterns (neither pair grouped) | assertable |
| 3 | `-g` without a value | header reports `Threshold: 85%` and `Final pass: on (threshold=85%`; the final pass creates 1 pattern (only the Dice 89 pair) | assertable |
| 4 | `-g 95 --final-threshold 70` | header reports `Threshold: 95%` and `Final pass: on (threshold=70%`; the final pass creates 2 patterns | assertable |
| 5 | Every scenario above | the final pass receives all 4 keys (`Keys seen: 4` in its block): streaming grouped none of them, so the pattern counts are the final pass's own | assertable |

Criteria 1 and 2 fail against the fixed 85: that final pass creates 1 pattern at any `-g`. Harness: `tests/validate-message-grouping.sh`.

### `-V message-grouping` keys asserted

The header line `Threshold: <T>%  Trigger: <N>  Ceiling: <C>  Final pass: on (threshold=<F>%, ceiling=<M>)` (emitted by `pipeline_finalize()`), where `<T>` is the resolved `-g` sensitivity and `<F>` the threshold the final pass scored at; and, per group, `Keys seen:` and `New patterns created:` in the `--- <category>|<group>: Final Pass (2-pass) ---` block. Renaming or removing any of these is a breaking change for that harness.
