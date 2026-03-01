# Staged Processing Pipeline

Architectural best practices for batch-triggered, multi-stage data processing, extracted from the #96 Fuzzy Message Consolidation implementation.

## Core Principle: Separate Expensive Discovery from Cheap Matching

The fundamental insight is that pattern discovery and pattern matching are different operations with different cost profiles, and they must be separated:

| | Discovery | Matching |
|---|---|---|
| **What it does** | Finds new patterns via pairwise similarity comparison and alignment | Tests incoming data against known compiled patterns |
| **Cost per operation** | Expensive — trigram indexing, Dice scoring, character-level alignment | Cheap — single regex match |
| **When it runs** | Rarely — only when unmatched count exceeds trigger threshold | Continuously — every new unique key |
| **Scaling** | O(batch² × trigrams) worst case, amortized by batch size limit | O(keys × patterns), but patterns are few and hot-sorted |

As patterns accumulate, fewer incoming items need the expensive discovery path. The system gets faster as it learns.

## The S1-S5 Pipeline

Each checkpoint processes data through five stages with fundamentally different cost characteristics:

### S1: Inline Match (during parsing, cheap, continuous)

New keys are matched against compiled patterns during parsing. Matched keys are routed directly to the appropriate cluster — they never enter the main data store. This is the primary performance and memory mechanism.

**Why it matters:** On power-law data, S1 absorbs 98.4% of keys. On production-scale data (16.4M lines), S1 absorbs 99.9%. These keys never allocate hash entries, never accumulate statistics individually, never participate in sorting or rendering. The cost that doesn't exist is the cheapest cost.

**S1 dominance grows with scale:** Patterns discovered early become more effective as more data flows through. On small files (288K lines), S1 absorbs 98.4%. On large files (16.4M lines), 99.9%. The amortized cost per line decreases with file size — the opposite of naive approaches that get slower with more data.

### S2: Ceiling Filter (at checkpoint, cheap)

Keys with accumulated occurrences above a ceiling are excluded from discovery. They are already well-counted and are not the target for fuzzy grouping. This focuses expensive discovery work on the long tail of low-occurrence variants.

**Key detail:** The ceiling checks total accumulated occurrences across all checkpoints, not just the current batch. A message appearing once in each of three prior batches already has 3 occurrences and is filtered. The filter becomes more effective as processing progresses.

### S3: Checkpoint Match (at checkpoint, cheap)

Surviving keys are re-checked against patterns discovered in the same checkpoint's S4 phase. This catches keys that arrived before a pattern was discovered but match it now.

### S4: Pairwise Discovery (at checkpoint, expensive)

The expensive work: trigram indexing, candidate identification, Dice scoring, character-level alignment, pattern derivation. Only runs on keys that survived S1, S2, and S3 — typically a small fraction of the original data.

**Interleaved re-scan within S4:** After each new pattern is discovered, immediately re-scan remaining unmatched keys against it. This is essential for power-law distributions where the first pattern absorbs 99%+ of remaining keys, preventing subsequent discovery calls from operating on the full set.

### S5: Unmatched (survivors)

Keys that survived all stages across all checkpoints. These represent genuinely unique messages that don't match any discovered pattern.

### Tracking Invariant

`S1 + S2 + S3 + S4 + S5 = total_keys_seen` per category. This is a built-in sanity check — if the equation doesn't balance, there's a routing bug. Implement this from day one.

## Checkpoint Trigger and Lifecycle

### Trigger Mechanism

A checkpoint fires when the count of unmatched keys in any category exceeds a threshold (default 5000). This bounds the expensive work per checkpoint — S4 pairwise discovery operates on at most `trigger` keys.

### Memory Lifecycle

Transient data structures (trigram indices, posting lists, normalized trigram caches) are built and freed per checkpoint. Only compiled patterns and cluster metadata persist across checkpoints.

```
Checkpoint lifecycle:
  1. Build trigram index for unmatched keys (allocates ~200 MB for 5000 keys)
  2. Run S2 → S3 → S4 pipeline
  3. Delete absorbed keys from main data store
  4. Free all trigram data structures (memory returns to Perl allocator's free pool)
  5. Only compiled patterns + cluster stats survive
```

This means memory is bounded per checkpoint batch, not cumulative. The peak is one checkpoint's worth of trigram data regardless of file size.

### End-of-File Checkpoint

After parsing completes, run a final checkpoint on all remaining unmatched keys regardless of count. This ensures files with fewer unique keys than the trigger threshold still get one discovery pass.

### Final Pass

An optional separate pass after the main processing that operates on ceiling-excluded keys (the ones S2 filtered out). Uses the same discovery pipeline but with different parameters — typically a higher ceiling to include previously-excluded high-occurrence entries.

## Interleaved Re-scan: Why Order Matters

The most important architectural decision in S4 is whether to discover patterns in batches or interleave discovery with re-scanning.

### Interleaved (correct for power-law data)

```
Discover pattern 1 → re-scan all remaining keys → absorbed 99%
Discover pattern 2 → re-scan remaining 1% → absorbed a few more
...
```

Pattern 1 absorbs the bulk. Subsequent patterns operate on a tiny residual. Total work is dominated by the first re-scan.

### Batched (catastrophic for power-law data)

```
Discover patterns 1-10 → then re-scan once with all 10
```

Without pattern 1's re-scan happening immediately, patterns 2-10 each discover against the full unmatched set. This caused a **22× regression** (2.9s → 64s) because it destroyed cascading reduction.

### Partitioning Composes with Interleaving

To reduce re-scan cost without destroying interleaving, partition keys by a cheap grouping key (e.g., `[LEVEL][class]`). Each pattern's re-scan only touches its matching partition instead of all keys. This gave 21% speedup while preserving cascading reduction.

## Key Architectural Lessons

### Architecture > Micro-optimization

Switching from load-all to checkpoint-based processing delivered 6× speedup on diverse data (12.3s → 2.06s). No amount of algorithmic optimization within the old architecture could have achieved this. The right processing model makes micro-optimizations less necessary.

### The Biggest Savings Are Invisible

S1 inline match prevents 98% of keys from ever being allocated. This avoids ~105 MB of hash allocation on a 288K-line file. But this savings never shows up in memory measurements because those keys were never allocated. The cumulative deleted bytes (~6 MB) massively understate the true savings vs a no-consolidation baseline.

### Stall Detection as Natural Bound

With no hard pattern cap, pattern count plateaus naturally when the data's diversity is exhausted. Stall detection (2 consecutive unproductive checkpoints) prevents wasted work. This replaced a hard cap of 50 that caused 3+ hour runtimes at production scale because it couldn't cover URL diversity in access logs.

### Fixed Trigger Is Fine

The adaptive trigger described in initial design (DD-02) was deferred. A fixed trigger of 5000 worked correctly across all test files. Adaptive behavior can be added later if profiling shows it's needed — don't add complexity before proving it's necessary.

## Applicability Beyond Fuzzy Consolidation

The staged pipeline pattern applies to any problem where:

1. **Most incoming items match known patterns** — the S1 inline match concept
2. **Pattern discovery is expensive but rare** — trigram indexing, pairwise comparison, alignment
3. **Pattern matching is cheap and continuous** — compiled regex, hash lookup
4. **Data exhibits power-law distributions** — a few patterns cover most of the data
5. **Memory must be bounded** — transient structures freed per batch

Examples beyond log consolidation:
- Log format auto-detection (discover format patterns, then match incoming lines)
- Anomaly detection (discover normal patterns, flag non-matching lines)
- Message identity for derived metrics (#54 — same engine, different configuration)

## Related Documentation

- `docs/similarity-engine-best-practices.md` — Algorithm choices and configuration
- `docs/perl-performance-optimization.md` — Profiling and Perl-specific optimization
- `docs/fuzzy-consolidation-lessons-learned.md` — What didn't work and why
- `features/fuzzy-message-consolidation.md` — Full #96 feature document (PF-20 for checkpoint architecture details)
