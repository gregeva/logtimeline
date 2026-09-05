# Hypothesis — #432 bytes parity capture, hot-loop cost

Written before profiling, per `features/nytprof-profiling-workflow.md` § Pre-Profiling
Checklist. Companion feature doc: `features/432-metric-aggregate-naming-parity.md`.

## What changes

Locked decision D5 gives bytes the full basic aggregate family —
`bytes_occurrences`, `bytes_min`, `bytes_mean`, `bytes_max` — on **both** CSV
surfaces. `bytes_mean` is derived, not accumulated, so the per-line work is three
additions at each of two scopes in `read_and_process_logs()`:

**Per message**, inside the existing message-key block, alongside the count family
that already does exactly this:

```perl
$log_messages{$category}{$log_key}{total_bytes} += $bytes if defined $bytes;
```

**Per bucket**, inside the existing bytes guard:

```perl
if( defined $bytes && $bytes ) {
    $log_analysis{$bucket}{total_bytes} += $bytes;
    $log_analysis{$bucket}{'total_bytes-HL'} += $bytes if $category_bucket =~ /-HL$/;
}
```

Both run **once per matched line carrying a bytes value**. On the reference access
log that is essentially every matched line, so ~1.43M times per scope.

The added work per scope is one counter increment and two compare-and-maybe-assign
operations of the shape already used by `count_min` / `count_max` and by the per-file
index accumulator.

## What is already known

**The guard question is settled differently here than in #447.** #447's cost was
dominated by work that could be *skipped* — a `tr` scan proved almost every message
clean, so the guard avoided two rewrites. There is no equivalent skip available for a
min/max: every observation must be compared against the running extremum. The
comparisons cannot be guarded away, only made cheap.

**The per-bucket scope has a smaller key space than the per-message scope.** Buckets
number in the hundreds or thousands; message keys in the tens of thousands to
hundreds of thousands. Both are hash lookups on the hot path, but the per-message
block already performs several, so the marginal cost of three more field accesses on
an entry already in hand should be lower there than the naive per-operation estimate.

**The `-HL` sibling doubles the per-bucket write set** when highlighting is active,
since the existing bytes block maintains a `total_bytes-HL` twin. Whether the new
fields need `-HL` twins is a design question the measurement should inform, not
assume.

## Hypothesis

1. **The dominant cost is hash element access, not the comparison itself.** A Perl
   numeric compare is cheap; `$h->{k}` on a nested hash is not. Therefore the shape
   that caches the entry reference once and writes through it should measurably beat
   the shape that re-resolves `$log_messages{$category}{$log_key}{...}` per field —
   which is what the shipped `count` block does, four times in four lines.

2. **The `!defined` test in the standard min/max idiom is a per-line cost that can be
   paid once instead.** The idiom
   `$e->{min} = $v if !defined $e->{min} || $v < $e->{min}` evaluates a definedness
   test on every line for the life of the key, to handle only the first. Seeding both
   extrema at the point the entry is created removes it from the steady state.

3. **Per-message and per-bucket costs are not equal and should not be assumed so.**
   Prediction: per-bucket is cheaper per line, because the bucket entry is already
   being written to by the adjacent `total_bytes` line and the key space is small
   enough to stay cache-resident.

4. **Total end-to-end cost lands below #447's rejected arm and near its shipped one.**
   Order-of-magnitude prediction: **under +1.5%** for both scopes together, against
   #447's +4.36% (rejected) and +0.80% (shipped). Stated so it can be wrong.

## What would falsify it

- The entry-reference shape measuring no better than the repeated-lookup shape,
  which would refute H1 and make the shipped `count` idiom the right template to copy
  verbatim.
- Seeding at entry creation measuring no better than the `!defined` idiom (H2) —
  possible if Perl's `defined` on an existing hash slot is cheaper than the extra
  work at creation time, which happens once per key rather than once per line.
- Per-bucket measuring *more* expensive per line than per-message (H3), which would
  point at the `-HL` twin or at bucket-key construction rather than at the field
  writes.
- Either scope alone exceeding +1.5% (H4).

## Method

Per `tests/profile/results/447-control-char-normalisation/analysis.md` § Method, whose
lesson 1 governs: **order-balance any A/B whose effect is smaller than its within-arm
spread.** #447 measured the same code at +0.44% and +1.99% under single-order
interleaving.

- **Order-balanced ABBA, ≥8 pairs**, medians with ranges.
- Baseline arm is the **production code path extracted verbatim** (#58 F9,
  CLAUDE.md 2026-08-21) — not wrapped in a convenience sub, which would measure the
  wrapper.
- Constants and code sliced from `ltl` rather than restated from memory
  (CLAUDE.md 2026-08-27); any value that must be restated names its source symbol.
- Reference input: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`
  (1,430,678 lines) — the same corpus as #447, so the figures are directly comparable.
- Arms measured separately per scope, then together, so H3 is answerable.

Lesson 2 from #447 applies to the correctness check that accompanies this: **a probe
that reports zero must be shown capable of reporting non-zero.** The parity fixture
must contain matched lines that carry no bytes value, or the F1 divisor fix cannot be
observed to change anything.
