# Similarity Engine Best Practices

Best practices for fuzzy string similarity in log analysis, extracted from the #96 Fuzzy Message Consolidation implementation. Primary reference for #54 (Fuzzy Matching Engine for Message Identity).

## Algorithm Selection

### Trigram Indexing with Dice Coefficient

Trigram (3-character chunk) indexing with Dice coefficient scoring is the proven approach for log message similarity. The combination provides sub-linear candidate identification followed by accurate scoring.

**Why trigrams:** Bigrams are too common (high false-positive rate in candidate search). 4-grams are too sparse for short messages. Trigrams balance discriminative power with coverage.

**Why Dice over Jaccard:** Both correctly distinguish similar from dissimilar messages. The difference is score distribution at the top of the scale. For messages that are very similar (the consolidation use case), Dice provides finer granularity — spreading values between 80-100% where threshold tuning happens. Jaccard compresses this range. Since users tune the threshold among highly similar messages, Dice gives more meaningful control.

```
Dice(A, B) = (2 * |A ∩ B|) / (|A| + |B|)
```

### Character-Level Alignment, Not Token-Level

Variable parts in log messages do not respect token boundaries:
- `ABC1234` vs `ABC5678` — "ABC" is constant, numeric suffix varies
- `PersistentSession2affb-ee87-0cac` — "PersistentSession" constant, hex varies within one token
- `/en-us/store/index.html` vs `/fr-fr/store/index.html` — locale varies mid-path

Token-based splitting (on spaces, `/`, `-`) was prototyped and failed. Character-level alignment (banded edit distance or LCS) correctly identifies constant vs variable regions at sub-token granularity.

### Mask as Source of Truth

The alignment produces a mask — an array of keep/variable flags per character position. Three artifacts are derived from the mask:

1. **Canonical display string** — keep positions retain original characters, variable regions replaced with `*`
2. **Compiled regex** — keep positions become `\Q...\E` literals, variable regions become `.+?`, anchored with `^...$`
3. **The mask itself** — stored for re-derivation during re-consolidation

This separation means `*` or regex metacharacters in the original text cause no ambiguity — the mask knows those positions are "keep."

### Coalescing Parameters

LCS/edit-distance alignment finds spurious single-character matches inside variable regions (e.g., coincidental hex character matches in UUIDs). Two-pass coalescing handles this:

- **Pass 1:** Remove short keep runs (< 3 chars) between variable regions
- **Pass 2:** Detect variable-dominated spans (keep/total ratio < 40%) and collapse all keeps within them. Span boundary defined by long keep run (>= 10 chars) or end of string.

These parameters (min keep=3, ratio=40%, boundary=10) proved stable across all test data — ThingWorx application logs, access logs, and DPM logs.

## Similarity Scoring

### Separate Similarity Scope from Storage Scope

Similarity scoring should operate on the **message content only**, not the full storage key. Metadata fields (log level, thread, object) should serve as exact-match grouping keys — two messages are only consolidation candidates if all their metadata fields match.

**Why:** When the full key (including `[ERROR] [http-thread-1] [ClassName]` prefix) is used for Dice scoring, the ~50-char metadata prefix dominates the trigram set. On messages with short bodies (< ~20 chars), cross-level pairs score above 80% and would be incorrectly merged:
- `[WARN] ... SUCCEEDED - Foo` vs `[ERROR] ... SUCCEEDED - Foo` → Dice 91.5% (incorrect merge)

**Grouping key pattern:** `"$log_level|$thread|$object"` — only messages sharing the same grouping key enter pairwise comparison.

### Score the Message as Written; Masking Is the Analyst's Step

Similarity is scored on the message text as written, by every stage that reads it: candidate search, Dice scoring and alignment. Do not replace values (UUIDs, numbers, IDs) with placeholders inside the scorer:

- **It hides information the analyst needs.** Whether the same identifiers recur, or change in only a few characters, is visible in a pattern that keeps the constant characters of an identifier and wildcards the ones that vary. A placeholder makes every identifier score alike.
- **It splits what the stages read.** A candidate search whose bounds are computed on the raw text cannot guarantee anything about a score computed on normalised text; partners the scorer would accept are passed over.

Masking values is an explicit step the analyst chooses, applied before consolidation (`--mask uuid`). It has a real effect on cost and grouping: a single UUID (36 chars) in a ~180-char message contributes ~34 trigrams no partner shares, holding Dice for otherwise identical messages at 74-76%. Where a log carries many UUIDs, masking them avoids a large amount of fruitless candidate scoring.

### Default Threshold: 85%

`-g` without a value uses 85%. In ltl, 90% ran 2-3× slower on the benchmarks because fewer keys matched discovered patterns inline, and 85% is the default that balances that cost against grouping.

The prototype's own iteration on its test data:
- **85%** (initial design) — too high for that data. Real messages carrying UUIDs scored 80-82% with the UUIDs replaced by a placeholder.
- **75%** (first prototype fix) — too low. Caused false merges after merge-first generalization was added.
- **80%** — the prototype's balance between false merges and missed patterns.

**Key lesson:** Thresholds must be re-evaluated after each algorithmic change. Each improvement shifts the scoring dynamics.

### Size Filter Before Expensive Comparison

Before computing Dice coefficient, filter candidates by trigram set size. If source has S trigrams and threshold is T%, candidates must have between `S * T / (200 - T)` and `S * (200 - T) / T` trigrams. This rejects impossible matches without any set intersection work.

### Candidate Search Sized From the Threshold (Prefix Filtering)

When posting lists are large (common trigrams like `[WA`, `ARN`, `] [` appear in thousands of keys), candidate search must not walk them all, but every trigram it skips has to be justified by the requested similarity. Prefix filtering, the standard candidate generation for set-similarity joins, gives that justification for Dice: a key with |r| distinct trigrams can reach similarity T only with a partner sharing at least one of its p = |r| − ⌈T·|r|/(200 − T)⌉ + 1 rarest trigrams. The probe shrinks as T rises: for a 286-trigram key it is 191 trigrams at T=50, 96 at 80 and 28 at 95.

1. **Index keys by integer id in size order.** Each batch gives its keys ids ordered by trigram count; each trigram maps to an ascending array of ids, so a range of sizes is a range of ids.
2. **Probe sized from T.** Sort the source's trigrams by posting length (ties by trigram) and keep the first p.
3. **Size filter as an id range.** The size bounds of § Size Filter Before Expensive Comparison become one id range, found by binary search; each posting array is walked from its first id in range.
4. **Discovery bound by size.** At probe position i a candidate not yet seen can gather at most p − i hits, so only sizes s whose required hit count ⌈T·(|r| + s)/200⌉ − (|r| − p) is at most p − i are admitted.
5. **Count bound, scored early.** Score a candidate with exact Dice once it holds a quarter of its required hits; drop it if Dice fails, or once the remaining probe positions cannot bring it to its requirement.
6. **Skip consumed keys.** Keys the pass has already absorbed into a pattern are not discovered, so they cannot crowd out usable candidates.
7. **Stop early.** Stop after the posting array that yields a partner, or once no seen candidate can still reach its requirement and no new size is admissible.

Every bound follows from T and the two key sizes, so a key with a partner scoring at or above T always gets a candidate. The quarter is a cost choice, not a recall choice: on a batch of signed download requests, scoring at half the requirement cost 8.6-11.5 ms per search against 2.4-3.4 ms at a quarter, and neither lost a partner the bound finds.

**Why a fixed filter fails.** Keeping a fixed number of rarest trigrams (50) and requiring a fixed number of them to be shared (15) ignores T and the key's size. It measured 4.8× faster with zero missed matches on one 200-key sample of a varied application log, and is nearly lossless on many logs, but for a 286-trigram key it is lossless only from about T=90. On keys whose rarest trigrams are per-request values (signatures and signing times in signed download URLs), those values fill the 50 with trigrams no other key shares, and every true partner falls short of 15: on a batch of such requests it passed over every partner at T ≤ 80. Any speed-motivated candidate filter needs a recall check against direct Dice scoring on real batches from several log families, at several thresholds. Measurements: `features/fuzzy-message-consolidation.md` § Pre-filter misses across log families and § Design: candidate search that finds every partner (#569).

## Pattern Management

### Merge-First + Stall Detection

Before adding a new pattern, check existing patterns for similarity. If a similar pattern exists, merge the new one into it (generalizing the existing pattern further). This keeps pattern count bounded while improving coverage.

Pattern growth stops naturally via stall detection: when 2 consecutive checkpoints produce no new patterns, stop triggering discovery. This replaces a hard cap, which caused problems at production scale (50 patterns couldn't cover URL diversity in access logs with 45K+ unique URLs).

### Generalization Must Be Idempotent

When aligning two canonical forms that already contain `*` wildcards, the derivation functions must treat `*` in keep positions as variable — emitting `*`/`.+?` instead of the literal character. Otherwise repeated generalization fragments instead of converging:

```
ErrorCode(9*) + ErrorCode(c*) → ErrorCode(**) → wrong
ErrorCode(9*) + ErrorCode(c*) → ErrorCode(*)  → correct (treat * as variable)
```

### Re-scan After Generalization Is Mandatory

When merge-first broadens a pattern, the new regex may match keys the old pattern missed. Without immediate re-scan, these keys sit as false "unmatched" entries. Example: `ErrorCode(4*34)` with 64 occurrences sitting separately from `ErrorCode(*)` with 286K occurrences.

### Hot-Sort Pattern List

Track match counts per pattern and bubble matched entries up one position after each hit. The hottest patterns migrate to the front. In power-law distributions, the top pattern matches 99%+ of messages — checking it first dramatically reduces average scan depth.

## Configuration Knobs

### Occurrence Ceiling (default: 3)

Messages already appearing N or more times are excluded from discovery. They are already naturally grouped by identical key and are not the target for fuzzy consolidation. The consolidation target is the long tail of single/low-occurrence entries.

**Ceiling=2 is too aggressive** — it shields too many keys from discovery, causing remaining count to balloon (58 → 217 on diverse data). Ceiling 3-5 produce nearly identical results. Err on the side of letting more keys through.

### Final Pass (on by default, threshold follows `-g`, ceiling 1M)

A separate pass after main processing that consolidates ceiling-excluded stragglers sharing obvious patterns (e.g., same message across 16 thread pools). A 95% threshold missed access-log targets entirely: their keys are shorter with smaller variable regions and score 85-87%.

The final pass scores at the same threshold as main discovery: the `-g` value, or its default. A separate final-pass threshold silently loosens or tightens the requested grouping for every key the final pass handles. The hidden `--final-threshold` remains as an explicit diagnostic override. At high sensitivity the final pass absorbs less per pattern and makes more candidate searches, so it is slower; that cost is accepted and tracked with final-pass performance in #142. Measurements: `features/fuzzy-message-consolidation.md` § Final pass follows the sensitivity (#571).

### Message Length Cap

Cap message length before trigram indexing. Trigram structures are the dominant memory cost (~206 MB peak for a 5000-key batch). Longer messages generate proportionally more trigrams. An adaptive cap — `min($max_observed_length, $upper_bound)` — avoids wasting memory on short messages while allowing full context on long ones.

## Applicability to Message Identity (#54)

The #96 similarity engine directly addresses #54's research areas:

| #54 Research Area | #96 Finding |
|---|---|
| Algorithms for fuzzy string grouping | Trigram Dice coefficient with character-level alignment (not token-based) |
| How monitoring platforms handle metric identity | Exact-match metadata grouping key + fuzzy message body scoring |
| Same algorithm for identity and group-similar? | Yes — the grouping key controls granularity. Tight identity uses more metadata fields; loose grouping uses fewer. |
| Performance at scale | S1 inline matching absorbs 98-99.9% of keys during parsing. 81s for 16.4M lines at 151 MB. |
| Perl libraries | No external libraries needed. Dice coefficient, banded edit distance, mask coalescing all implemented in pure Perl. |

### Shared vs Separate Engine

The same engine serves both derived metric identity and group-similar display. The difference is configuration, not algorithm:

- **Message identity** (for `idelta()` etc.): tight grouping key including all metadata fields, higher similarity threshold
- **Group-similar display**: looser grouping, default 85% threshold, visual consolidation of output

The grouping key pattern — exact-match on metadata, fuzzy on message body — naturally supports both use cases.

## Related Documentation

- `docs/regex-best-practices.md` — Pattern construction and regex performance
- `docs/staged-processing-pipeline.md` — The S1-S5 pipeline architecture
- `docs/perl-performance-optimization.md` — Profiling and Perl-specific optimization
- `docs/fuzzy-consolidation-lessons-learned.md` — What didn't work and why
- `features/fuzzy-message-consolidation.md` — Full #96 feature document with all PF findings and DD decisions
