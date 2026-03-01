# Perl Performance Optimization

Lessons learned from profiling and optimizing the #96 Fuzzy Message Consolidation engine and ltl. These apply broadly to performance-sensitive Perl code.

## Profiling

### Always Profile with Real Data

NYTProf profiling identified the dominant cost as:
- `compute_mask` at 62.8% of runtime (PF-14) — after fixing that →
- `find_candidates` at 88% (PF-16) — after fixing that →
- `dice_coefficient` at 49% (PF-19)

The dominant cost shifts after each fix. Assumptions about what's slow are unreliable. Profile after every significant change.

### Use NYTProf for Perl

`Devel::NYTProf` provides per-function exclusive time, call counts, and percentage of total — exactly what's needed to identify hotspots. Run with:

```bash
perl -d:NYTProf script.pl [args]
nytprofhtml --open
```

### Profile at Production Scale

Small-file benchmarks can reverse at larger data sizes. PF-21 showed the prototype using MORE memory than ltl on 97 MB files. PF-24 showed 40% LESS on 3.3 GB files. The relationship reversed because S1 savings (which grow linearly with file size) eventually dominate trigram overhead (which is fixed per checkpoint batch).

Always validate performance conclusions at the scale where the code will actually run.

## Perl-Specific Traps

### Hash Iteration Order Is Non-Deterministic

Perl randomizes hash key order per process. Any algorithm that iterates hash keys and where iteration order affects outcomes will produce different results per run.

```perl
# NON-DETERMINISTIC — different results every run
for my $key (keys %unmatched_keys) {
    # pairwise comparison order varies
}

# DETERMINISTIC — consistent results
for my $key (sort keys %unmatched_keys) {
    # always same order
}
```

**Fix:** Sort keys at the entry point to any ordering-sensitive algorithm. Also add tiebreakers to result sorting (e.g., `$a->{key} cmp $b->{key}` when scores are equal).

### `my` Declarations Execute at Runtime in Textual Order

Variables declared with `my` below the parsing loop are `undef` when called during parsing via callbacks or checkpoints:

```perl
# BUG: $threshold is undef during parsing
while (<FILE>) {
    process_line($_);  # may call run_checkpoint() which uses $threshold
}
my $threshold = 50;  # declared too late

# FIX: declare before the loop
my $threshold = 50;
while (<FILE>) {
    process_line($_);
}
```

This is a Perl-specific gotcha when restructuring code to move processing into the parsing loop (as the checkpoint architecture does).

### Perl Interpreter Overhead Dominates Small Operations

For tight inner loops operating on short strings (~40 chars after prefix/suffix stripping):
- Array creation via `split //` is expensive relative to the work
- Per-element hash/array access has high overhead
- `vec()` bit packing helps but doesn't eliminate the overhead
- Callback dispatch (e.g., `Algorithm::Diff` traversal callbacks) adds per-call cost

The bottleneck is often Perl's per-operation interpreter cost, not algorithmic complexity. A 40×40 DP matrix is tiny computationally but expensive in Perl operations.

### `free()` Returns to Perl's Allocator, Not the OS

When Perl `delete`s hash entries, memory returns to Perl's internal free pool, not the OS. RSS never decreases even when structures are freed. This means:

- RSS high-water mark equals RSS at end of run
- Freed memory IS reusable for subsequent Perl allocations
- Subsequent checkpoints reuse freed memory without requesting more from the OS
- Measure structure sizes with `Devel::Size::total_size()`, not just RSS, to see actual usage

```perl
use Devel::Size qw(total_size);
printf "log_messages: %.1f MB\n", total_size(\%log_messages) / 1048576;
```

### Perl Hash Overhead Is ~100 Bytes Per Entry

Each hash entry in Perl carries significant overhead beyond the key and value. For data structures with many small entries (e.g., trigram posting lists), the overhead can exceed the payload. A hash with 298 entries per key × 5000 keys = 1.49M entries × ~100 bytes = ~149 MB of overhead alone.

Consider whether a different data structure (array of pairs, packed string) would be more memory-efficient for high-entry-count use cases.

## XS and Inline::C

### XS Modules Don't Help When the Bottleneck Is Perl-Side

`Algorithm::Diff::XS` gave zero speedup over pure-Perl `Algorithm::Diff` because the bottleneck was `split //` (creating character arrays) and per-match callback dispatch — both happen in Perl, not in the XS core.

**Lesson:** XS accelerates the C portion of a module. If the caller-side Perl code (argument marshalling, callbacks, result processing) dominates, XS provides no benefit.

### Inline::C: 100× Per-Call, But Measure End-to-End

Moving the entire alignment operation to C (prefix/suffix strip + banded DP + backtrace, operating directly on `char*`) gave 100× per-call speedup (1.35ms → 0.013ms). But:

- After the checkpoint architecture reduced `compute_mask` calls from thousands to dozens per batch, the 100× speedup on a tiny total cost was irrelevant
- End-to-end improvement was only 1.2-1.6× (3.67s vs 2.29s)
- Inline::C introduced platform-specific crash bugs (bus errors on macOS)
- It adds a C compiler as a build dependency

**Decision:** Inline::C was rejected for production. The architectural change (checkpoint processing) eliminated the need for micro-optimization of alignment.

### Algorithmic Improvements Can Be Slower in Perl

Banded edit distance is theoretically O(nk) vs O(mn) for unbanded — but in pure Perl, banded was 0.8× slower (1.65ms vs 1.35ms). The band-clamping logic (`max`/`min` per iteration, out-of-band fill) added more Perl interpreter overhead than the reduced cell count saved.

**Lesson:** Theoretical complexity improvements don't always translate to real speedups in interpreted languages. The constant factors from Perl operations can dominate. Benchmark before committing to a "better" algorithm.

## Optimization Strategy

### Architecture Before Algorithms Before Micro-optimization

The optimization journey for #96:

| Change | Type | Impact |
|--------|------|--------|
| Checkpoint architecture (PF-20) | Architecture | 6× speedup on diverse data |
| UUID normalization (PF-19) | Algorithm/correctness | 3.3× speedup on diverse data |
| Discriminative trigram pre-filter (PF-18) | Algorithm | 4.8× on candidate search |
| Prefix/suffix stripping (PF-14) | Algorithm | 3.1× on alignment |
| Inline::C alignment (PF-15) | Micro-optimization | 100× per-call, 1.6× end-to-end |
| Key partitioning (PF-17) | Algorithm | 1.2× on re-scan |

The architectural change delivered more than all algorithmic and micro-optimizations combined. And after the architectural change, the micro-optimization (Inline::C) became unnecessary.

### Correctness Gaps Masquerade as Performance Problems

The DEBUG "performance problem" (414K fruitless Dice calls) was actually a correctness problem — UUIDs prevented Dice from seeing structural similarity. UUID normalization fixed both performance (3.3× faster) and correctness (0 patterns → 1 pattern consolidating 1,709 keys) simultaneously.

When profiling reveals a function doing enormous work with no useful output, ask whether it's a performance problem or a correctness problem in the input.

### Inline Functions on Hot Paths

Function call overhead in Perl is measurable on hot paths. `build_grouping_key()` was called 463K times (once per line) and inlining it saved ~400ms. But only inline when profiling confirms the function is a hotspot — premature inlining reduces readability for no gain.

### Bound the Expensive Work, Don't Optimize It

Instead of making S4 pairwise discovery faster, the checkpoint architecture made it run on fewer keys. Instead of making `find_candidates` iterate posting lists faster, discriminative trigram pre-filtering made it iterate fewer lists. Instead of making `compute_mask` faster with Inline::C, the architecture reduced how many times it's called.

Reducing the amount of work is almost always more effective than making each unit of work faster.

## Memory Optimization

### Measure Before Claiming Victory

DD-12 predicted 30% memory reduction from consolidation. Actual measurement (PF-21) showed the opposite on small files — prototype used MORE memory (238 vs 172 MB) because trigram overhead exceeded savings. Only at production scale (3.3 GB) did the relationship reverse (151 vs 256 MB).

Design assumptions about memory must be validated with instrumentation. Use `Devel::Size::total_size()` on individual structures, not just RSS.

### Trigram Structures Are the Dominant Memory Cost

For a 5000-key batch: `key_trigrams` + `ngram_index` + `key_trigrams_norm` peak at ~206 MB. This is the price of similarity search. It's bounded per checkpoint (build and free per batch), not cumulative.

The `$trigger` parameter directly controls the peak: lower trigger = smaller batches = less trigram memory but more frequent checkpoints.

### Prevention Is Cheaper Than Cleanup

S1 inline match preventing 98% of keys from entering the main data store avoids ~105 MB of hash allocation. The cumulative bytes explicitly deleted from the store after checkpoints (~6 MB) massively understate the true savings. Preventing allocation is far cheaper than allocating and then freeing.

## Benchmarking Pitfalls

### Small Files Can Give Opposite Conclusions

| Scale | Memory comparison |
|-------|-------------------|
| 97 MB (small) | Prototype uses 39% MORE memory than baseline |
| 3.3 GB (production) | Prototype uses 40% LESS memory than baseline |

The trigram overhead that dominated at small scale became negligible relative to S1 savings at production scale. Always benchmark at the scale that matters.

### Sandbox Environments Kill Long-Running Processes

Claude Code's sandbox kills processes with SIGTRAP (exit code 133) on long-running operations. Add `$| = 1` (STDOUT autoflush) to ensure output is visible during long runs, and test at scale outside the sandbox.

## Related Documentation

- `docs/similarity-engine-best-practices.md` — Algorithm choices and configuration
- `docs/staged-processing-pipeline.md` — The S1-S5 pipeline architecture
- `docs/fuzzy-consolidation-lessons-learned.md` — What didn't work and why
- `docs/regex-best-practices.md` — Pattern construction and regex performance
- `features/fuzzy-message-consolidation.md` — Full #96 feature document with NYTProf profiles
