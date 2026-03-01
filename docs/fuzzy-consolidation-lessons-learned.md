# Fuzzy Consolidation Lessons Learned

What didn't work, wrong assumptions, dead ends, and things to avoid. Extracted from the #96 Fuzzy Message Consolidation implementation (26 prototype findings, 5 months of development).

## Architectural Mistakes

### Load-All-Then-Process Was Fundamentally Wrong

**What we did:** The initial prototype loaded all log lines into memory, then ran consolidation over the entire key set at once.

**Why it failed:**
- Performance numbers were meaningless — there were no batch boundaries, so S1 inline match and S3 checkpoint match never had any work to do
- Memory grew proportionally with file size — no opportunity to free intermediate data
- On diverse data (480K lines): 12.3s, 192 MB — over 4× slower and 6.8× more memory than ltl baseline (3.0s, 28 MB)

**What replaced it:** Checkpoint-based processing that moves consolidation INTO the parsing loop. Consolidation fires at periodic checkpoints, trigram data is built and freed per checkpoint, and S1 inline matching prevents 98-99% of keys from ever being stored.

**Result:** Same diverse data: 2.06s, 157 MB. The architecture change alone delivered 6× speedup.

**Lesson:** When your processing model doesn't match the data flow, no amount of optimization within the wrong model will help. The right question wasn't "how do we make load-all faster?" but "should we be loading all at all?"

### Batched Discovery Destroyed Power-Law Performance

**What we did:** Accumulated 10 pattern discoveries before running a single combined re-scan (PF-17). The idea was fewer scan passes = less work.

**Why it failed:** In power-law data, the first discovered pattern absorbs 99%+ of keys via re-scan. Without immediate re-scan after pattern 1, patterns 2-10 each discovered against the full 286K unmatched set. This caused 500 pattern discoveries in pass 1 (was 2 before).

**Result:** Phase 4 regressed from 2.9s to 64.25s — a **22× regression**.

**What replaced it:** Interleaved discovery + re-scan, with key partitioning to reduce per-scan scope. Discover one pattern, immediately scan remaining keys, absorb matches, then discover the next pattern from the reduced set.

**Lesson:** For power-law distributions, the cascading reduction from immediate absorption IS the core performance mechanism. Any optimization that defers absorption to batch it up will destroy this mechanism. The "fewer passes" savings from batching was negligible compared to the expanded discovery cost.

### Hard Pattern Cap Caused Multi-Hour Runtimes

**What we did:** Set a hard cap of 50 patterns per category (PF-05), reasoning that merge-first generalization would keep patterns general enough.

**Why it failed:** At production scale (7.9 GB, 45K+ unique URLs per access log file), 50 patterns couldn't cover the URL diversity. Hundreds of unproductive checkpoints fired, each re-scanning 5000 keys against patterns that couldn't match. Server-0 alone took 3+ hours (vs 77s baseline).

**What replaced it:** Removed the hard cap. Patterns grow naturally until stall detection (2 consecutive unproductive checkpoints) stops discovery. More patterns = more S1 absorption = less memory.

**Lesson:** Hard caps are brittle. They work for the data you tested with and fail on data you didn't. Stall detection adapts to the data's actual diversity.

## Wrong Assumptions

### Worked Examples Lied About the Threshold

**What we assumed:** The DD-01 worked example used short messages with small variable parts and predicted 85% as the right Dice threshold.

**What happened:** Real messages with UUIDs (36 chars of random hex) scored 74-82% Dice. The 85% threshold blocked consolidation of the primary test data entirely.

**Iterations:** 85% (design) → 75% (PF-01, too low after merge-first) → 80% (PF-08, correct balance).

**Lesson:** Worked examples test the algorithm, not the threshold. Real data has proportionally larger variable regions (UUIDs, session tokens, entity names) than toy examples. Always validate defaults against real production data.

### Small-File Memory Benchmarks Reversed at Scale

**What we measured:** On a 97 MB file, the prototype used 238 MB RSS vs ltl's 172 MB — 39% MORE memory. We concluded that the 30% memory reduction target (DD-12) was unachievable.

**What actually happened:** On 3.3 GB of production data, the prototype used 151 MB vs ltl's 256 MB — 40% LESS memory. On 7.9 GB: 437 MB vs 3,661 MB — **88% less memory**.

**Why it reversed:** Trigram overhead is fixed per checkpoint batch (~200 MB). ltl's `%log_messages` grows proportionally with unique keys. At small scale, trigram overhead dominates. At production scale, S1 prevention of millions of hash entries dominates.

**Lesson:** Performance at the wrong scale gives the wrong answer. If the production use case is multi-GB files, small-file benchmarks are misleading for memory conclusions. Test at the scale that matters.

### We Assumed the Bottleneck Was the Algorithm

**What we assumed:** The trigram-based pairwise similarity was too expensive and we should research alternatives (MinHash, Drain-style token grouping, locality-sensitive hashing).

**What was actually wrong:** The prototype was applying the expensive pairwise comparison to ALL accumulated keys instead of gating them first. The ceiling filter, pattern matching gate, and checkpoint architecture were described in the design (DD-02) but not implemented in the prototype.

**Result:** After implementing the gates correctly, the same algorithm that seemed unacceptably expensive (310% time overhead, 580% memory overhead) became faster than baseline (-28% time at small scale, -46% at production scale).

**Lesson:** Before concluding an algorithm is too expensive, verify it's being applied to the right input set. Scope reduction (fewer keys entering the expensive path) often matters more than algorithmic improvement.

### We Assumed Inline::C Was Necessary

**What we measured:** Inline::C gave 100× per-call speedup on `compute_mask` (1.35ms → 0.013ms). We concluded it was essential for production.

**What changed:** The checkpoint architecture reduced `compute_mask` calls from thousands to dozens per batch. The 100× speedup applied to a cost that was now <1% of total runtime.

**End-to-end impact:** 3.67s (pure Perl) vs 2.29s (Inline::C) — only 1.6× difference. And Inline::C introduced platform-specific crash bugs (bus errors on macOS).

**Lesson:** Micro-optimization results measured in the old architecture don't predict value in the new architecture. When the architecture eliminates the hotspot, the micro-optimization targeting that hotspot becomes irrelevant.

### Defaults Tuned on One Log Format Failed on Another

**What we tuned:** Final pass defaults (threshold 95%, ceiling 100, off by default) optimized for ThingWorx application logs.

**What happened on access logs:** Access log keys are shorter with smaller variable regions, producing Dice scores of 85-87% (below the 95% threshold). High-value targets had 10,000+ occurrences (above ceiling 100). The final pass was completely ineffective.

**New defaults:** Threshold 80%, ceiling 1M, on by default. These work across both log formats.

**Lesson:** Validate configuration defaults across all supported input formats. What works for one format can be useless for another. When in doubt, choose the more permissive setting — it does slightly more work but doesn't miss targets.

## Algorithmic Dead Ends

### Token-Based Splitting

**What we tried:** Splitting on whitespace and delimiters (`/`, `-`, `_`) to identify variable tokens.

**Why it failed:** Variable parts don't respect token boundaries. `PersistentSession2affb-ee87-0cac` has the constant part and variable part within one token. `ABC1234-76C` has constant prefix, variable middle, and constant suffix. No delimiter set works universally.

**What works:** Character-level alignment (banded edit distance or LCS) that compares character-by-character and produces a mask of keep/variable positions.

### XS Modules for Inner Loop Acceleration

**What we tried:** `Algorithm::Diff::XS` — a C-accelerated LCS module.

**Why it failed:** The XS module accelerates the core LCS computation in C, but the bottleneck was Perl-side: `split //` to create character arrays and per-match callback dispatch. Both happen in Perl regardless of whether the core is XS or pure Perl. Result: zero speedup.

**What works:** Full Inline::C that moves the ENTIRE operation (including string access and loop control) into C. But this was ultimately unnecessary due to architectural changes.

### Banded Edit Distance in Pure Perl

**What we tried:** Banded DP (theoretically O(nk) vs O(mn) for full DP) to speed up alignment.

**Why it failed:** The band-clamping logic (`max`/`min` per iteration, out-of-band sentinel fills) added more Perl interpreter overhead than the reduced cell count saved. Pure Perl banded was 0.8× slower than unbanded (1.65ms vs 1.35ms).

**Note:** After the architecture change reduced `compute_mask` calls to dozens per batch, the pure Perl banded implementation was adopted anyway — at this call volume, the 0.8× difference is unmeasurable. The lesson is about the gap between theoretical and actual complexity in Perl.

### Alternation Regex for Multi-Pattern Matching

**What we tried:** Combining 50+ patterns into a single `qr/(?:p1)|(?:p2)|...|(?:pN)/` for a single-pass match.

**Why it failed:**
- No faster than a simple Perl loop (1.1× at best, sometimes slower)
- Fragile — reconstructing pattern source from `qr//` stringification is Perl-version-dependent
- Hard to debug — which branch matched?

**What works:** Simple loop with hot-sorting (bubble matched pattern up by one position after each hit).

## Process Lessons

### The Performance Assessment Whiplash

The #96 development had a dramatic performance narrative:

| Phase | Conclusion |
|-------|-----------|
| Initial prototype | "35% time overhead, 213% memory overhead — unacceptable" |
| Root cause analysis | "The algorithm is fine, the scope is wrong" |
| Checkpoint rebuild | "28% faster and 31% less memory than baseline on small files" |
| Production scale | "46% faster and 40% less memory at 3.3 GB" |
| ltl integration | "21% slower but 88% less memory at 7.9 GB" |

The same core algorithms went from "unacceptable" to "faster than baseline" by changing the processing architecture. And the final integration numbers differ from the prototype numbers because ltl's existing parsing overhead is the dominant cost at small scale.

**Lesson:** Don't abandon an algorithm based on performance in the wrong architecture. Diagnose whether the problem is the algorithm or how it's being applied.

### Measure Before and After Every Change

The #96 feature document records 26 prototype findings (PF-01 through PF-26), each with before/after measurements. This made it possible to:
- Identify when an "optimization" was actually a regression (batched discovery: 22×)
- Know exactly which change delivered which improvement
- Make informed decisions about what to keep vs discard

Without disciplined measurement, the batched discovery regression might have been blamed on something else.

### Prototyping Outside the Main Codebase Was Essential

The standalone prototype (`prototype/96-fuzzy-consolidation.pl`) allowed:
- Rapid iteration without risk to the production tool
- NYTProf profiling without ltl's parsing overhead masking the results
- Architecture experimentation (load-all → checkpoint) without touching ltl's code structure
- Clean integration — once the prototype was validated, porting to ltl was mechanical

The prototype went through 5+ major architectural iterations. Doing this inside ltl's 2,500-line codebase would have been much slower and riskier.

### Don't Optimize What You Haven't Scoped

The initial performance assessment (35% time, 213% memory overhead) triggered research into alternative algorithms — MinHash, Drain-style token grouping, locality-sensitive hashing. None of this research was necessary. The problem wasn't the algorithm; it was applying the algorithm to the wrong set of keys.

Before researching alternatives, exhaust the design's own capabilities. DD-02 described the ceiling filter and pattern matching gate. Implementing what was already designed solved the problem without algorithm changes.

## Related Documentation

- `docs/similarity-engine-best-practices.md` — What to do (algorithm choices, configuration)
- `docs/staged-processing-pipeline.md` — The architecture that made it work
- `docs/perl-performance-optimization.md` — Profiling and Perl-specific traps
- `docs/regex-best-practices.md` — Pattern construction and regex performance
- `features/fuzzy-message-consolidation.md` — Full #96 feature document with all PF findings
