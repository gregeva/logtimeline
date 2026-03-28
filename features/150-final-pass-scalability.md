# Issue #150: Final Pass Scalability Redesign

**GitHub Issue:** #150
**Status:** Investigation phase — root cause analysis in progress
**Related:** #137 (final pass pipeline redesign), #144 (auto-disable workaround), #135 (eviction mechanics), #96 (consolidation engine)

## Problem

The final consolidation pass causes catastrophic performance regression on large files. On 7.7M lines, `group_similar` goes from 484ms (v0.14.2) to 64.5 minutes (v0.14.3) — a 799,371% regression. A 2M-line auto-disable workaround (#144) currently prevents the final pass from running on large files, meaning large-file users get no final pass benefit.

## Investigation Findings

### Test Setup

- Sample: 100K lines from XL access log dataset (`localhost_access_log-twx01-twx-thingworx-0.2026-01-07.txt`)
- Command: `./ltl -g 85 -V --disable-progress --terminal-width 200`
- Comparison: same command with `-uuid` to mask UUIDs

### Key Observations

#### 1. UUID-containing keys are not consolidating (CRITICAL — likely root cause)

With `-uuid` (UUIDs masked): `group_similar` = 0.4s, streaming S1 absorbs 10,433/15,763 keys (66%)
Without `-uuid` (real UUIDs): `group_similar` = 115.8s, streaming S1 absorbs 75/17,798 keys (0.4%)

The output shows hundreds of `FileRepositories` entries with occurrence=1, each with a unique UUID, **none consolidated** despite being nearly identical:
```
[200] GET /Thingworx/FileRepositories/RD.RS.MRD.FileRepository/MRD/CobasLink/SCL202553_COBASLINK/71ba24a5-48cb-4d9b-a709
[200] GET /Thingworx/FileRepositories/RD.RS.MRD.FileRepository/MRD/CobasLink/SCL290141_COBASLINK/0f21fd02-982b-4d49-a02c
```

These keys share a long common prefix and differ in two variable regions (device ID + UUID). UUID-normalized trigrams for Dice scoring ARE present in the code (lines 1721-1724, 1772-1773, 1788 in ltl), but consolidation is not occurring. **This is a separate issue tracked as #156** and may be the most consequential problem — it affects both streaming and final pass.

#### 2. Unbounded working set accumulation in final pass

During streaming, eviction removes stale keys from the working set after each checkpoint, keeping it bounded. The final pass correctly disables eviction (it's the last chance to consolidate), but provides no alternative bounding mechanism.

**What happens:**
- All remaining `%log_messages` keys feed through `consolidation_process_key()` one by one
- Keys that fail S1 accumulate in `%consolidation_unmatched`
- Checkpoints fire every 5000 unmatched keys per category
- Survivors stay in `%consolidation_unmatched` indefinitely
- After N checkpoints, the unmatched set contains ~N×4500 keys (assuming ~10% absorption per checkpoint)

**Consequences:**
- S3 gate (lines 2245-2267) tests ALL unmatched keys against patterns — cost grows linearly with each checkpoint
- Bucket partitioning (lines 2291-2295) scans ALL unmatched keys — grows linearly
- `%consolidation_key_trigrams` holds per-key trigram hashes for ALL survivors — memory grows linearly
- On 700K+ keys, this produces hundreds of checkpoints with a massive accumulated working set

**Contrast with streaming:** Streaming uses adaptive eviction (#135) to bound the working set. After 2-3 unproductive checkpoints, EMA drops to 0% and all keys are evicted. The working set stays at roughly one trigger batch (5000 keys). The final pass has no equivalent mechanism.

#### 3. Sort order groups by status code, not by message similarity

The final pass sorts keys with `sort keys %{$log_messages{$category}}` (line 1580). Since log keys are prefixed with `[grouping_key]` (e.g., `[200]`, `[404]`), sorting groups all 200s together, all 404s together, etc.

This is counterproductive for consolidation. The consolidation candidates are messages with similar API paths regardless of status code. Sorting by the message body (stripping the grouping key prefix) would cluster similar API calls together, maximizing within-batch S3/S4 yield.

Similarly, `%consolidation_unmatched` should be sorted by message content between checkpoints so that subsequent rounds benefit from message proximity.

#### 4. Final pass ceiling effectively disabled

`$consolidation_final_ceiling = 1,000,000` means virtually all keys pass the S2 ceiling filter into `@discovery_candidates`. During streaming, `$consolidation_occurrence_ceiling = 3` excludes high-occurrence keys from expensive S4 pairwise discovery. The final pass loses this gating.

#### 5. Trigram lifecycle during final pass

- `%consolidation_ngram_index` (posting-list index): correctly rebuilt fresh per checkpoint (deleted at line 2279, rebuilt at 2280, deleted at 2528)
- `%consolidation_key_trigrams` (per-key trigram hashes): preserved across checkpoints for reuse (line 1716-1717), which is the intended design for efficiency
- Problem: without eviction, the per-key trigrams accumulate without bound. During streaming, eviction cleans these up (line 2573). During the final pass, nothing cleans them up for keys that are definitively unmatched.

### Verbose Counter Data (100K lines, no -uuid)

**plain|200 Streaming Phase:**
- Keys seen: 17,798 (4 checkpoints, 4 patterns)
- S1 Inline match: 75
- S4 Pairwise discovery: 20
- S6 Evicted: 17,703

**plain|200 Final Pass:**
- Keys seen: 17,703 (4 checkpoints, 5 new patterns)
- S1 Inline match: 0
- S4 Pairwise discovery: 3
- S5 Unmatched: 17,700
- find_candidates calls: 2,000

S1=0 on 17,703 keys is the smoking gun — the patterns discovered during streaming catch none of the evicted keys when they re-enter the final pass.

## Open Questions

1. **Why does UUID-normalized Dice scoring fail to consolidate UUID-containing messages?** The code has `%consolidation_key_trigrams_norm` with UUID→`<UUID>` normalization at lines 1721-1724, and `find_consolidation_candidates` uses it at lines 1772-1773, 1788. Yet consolidation doesn't occur. This needs investigation — tracked as #156.

2. **What is the right bounding mechanism for the final pass?** Options discussed:
   - **Bounded batches**: Process keys in fixed-size batches with full cleanup between batches. Patterns accumulate across batches (S1 benefit compounds), but working set resets per batch.
   - **Multi-pass with threshold tiers**: Raise/lower ceiling progressively. Likely flawed — would double-process keys that remain across threshold changes.
   - The bounded batch approach seems most promising but needs detailed design.

3. **How should keys be sorted for the final pass?** Sorting by message body (stripping grouping key prefix) would cluster similar API calls together. Need to validate this improves consolidation yield. Same principle should apply to sorting `%consolidation_unmatched` between checkpoints.

4. **Should surviving keys get a second chance?** After a batch closes, should survivors be carried forward to one more batch before being left as-is? Or should batch boundaries be hard?

5. **What is the interaction between #156 (UUID consolidation failure) and #150?** If UUID consolidation is fixed, streaming may absorb most UUID keys via S1, dramatically reducing the number of keys entering the final pass. The final pass scalability problem may become much less severe — but still needs fixing for correctness.

## Design Direction (preliminary — not yet validated)

The final pass should behave like bounded batch processing:
1. Sort remaining `%log_messages` keys by message body (not full log key)
2. Process in fixed-size batches through the full S1→S2→S3→S4 pipeline
3. Patterns discovered in batch N are available for S1 matching in batch N+1
4. Trigram structures and working set are cleaned up per batch
5. Batch survivors get definitive disposition — left in `%log_messages` as unique entries

This preserves the same pipeline architecture as streaming (addressing the original #137 concern) while maintaining bounded resource usage.

## References

- #137 — Final pass redesign (current implementation)
- #144 — Auto-disable workaround for large files
- #135 — Eviction mechanics
- #156 — UUID-normalized Dice scoring not producing matches (root cause investigation)
- `features/137-final-pass-redesign.md` — Design document for current implementation
- `features/fuzzy-message-consolidation.md` — Full consolidation engine documentation
- PF-19 — UUID normalization for Dice scoring (prototype)
- Benchmark evidence in #150 issue body
