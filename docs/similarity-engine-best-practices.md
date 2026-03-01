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

### UUID Normalization Before Scoring

UUIDs are structurally random noise that drags Dice scores below threshold for messages that are structurally identical. A single UUID (36 chars) in a ~180-char message generates ~34 unique trigrams, dragging scores to 74-76% (below the 80% threshold).

**Solution:** Normalize UUIDs to a placeholder (`<UUID>`) in the trigrams used for Dice scoring only. Do not normalize in the alignment pipeline — UUIDs get wildcarded naturally by character-level alignment.

```perl
my $uuid_re = qr/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i;
# Build normalized trigrams only for keys containing UUIDs
if ($key =~ $uuid_re) {
    my $normalized = $key;
    $normalized =~ s/$uuid_re/<UUID>/g;
    $key_trigrams_norm{$key} = get_trigrams($normalized);
}
```

This fixes both a correctness gap (UUID-varying messages can now be consolidated) and a performance problem (414K fruitless Dice calls → 7.5K on diverse data).

### Default Threshold: 80%

The 80% Dice threshold was arrived at iteratively:
- **85%** (initial design) — too high. Real messages with UUIDs scored 80-82% even after normalization.
- **75%** (first prototype fix) — too low. Caused false merges after merge-first generalization was added.
- **80%** (final) — correct balance. Strict enough to avoid false merges, loose enough to catch genuine patterns.

**Key lesson:** Thresholds must be re-evaluated after each algorithmic change. Each improvement shifts the scoring dynamics.

### Size Filter Before Expensive Comparison

Before computing Dice coefficient, filter candidates by trigram set size. If source has S trigrams and threshold is T%, candidates must have between `S * T / (200 - T)` and `S * (200 - T) / T` trigrams. This rejects impossible matches without any set intersection work.

### Discriminative Trigram Pre-filter

When posting lists are large (common trigrams like `[WA`, `ARN`, `] [` appear in thousands of keys), use only the most discriminative trigrams for candidate search:

1. Sort source trigrams by posting list size (ascending = most discriminative)
2. Use only top-K trigrams (K=50) to build candidate set
3. Require a loose minimum hit count (30% of K) for candidates
4. Apply full Dice verification on the pre-filtered set

This gave 4.8× speedup with zero missed matches at K=50, ratio=0.30. Lower K values (20, 30) caused missed matches.

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

### Final Pass (on by default, threshold 80%, ceiling 1M)

A separate pass after main processing that consolidates ceiling-excluded stragglers sharing obvious patterns (e.g., same message across 16 thread pools). Uses the same threshold as main discovery (80%), not a higher one — access log keys are shorter with smaller variable regions, producing Dice scores of 85-87% that the original 95% threshold missed entirely.

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
- **Group-similar display**: looser grouping, standard 80% threshold, visual consolidation of output

The grouping key pattern — exact-match on metadata, fuzzy on message body — naturally supports both use cases.

## Related Documentation

- `docs/regex-best-practices.md` — Pattern construction and regex performance
- `docs/staged-processing-pipeline.md` — The S1-S5 pipeline architecture
- `docs/perl-performance-optimization.md` — Profiling and Perl-specific optimization
- `docs/fuzzy-consolidation-lessons-learned.md` — What didn't work and why
- `features/fuzzy-message-consolidation.md` — Full #96 feature document with all PF findings and DD decisions
