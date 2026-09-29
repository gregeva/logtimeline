# Feature: G1 GC log format coverage (Issue #382)

## Status

Implemented on `382-gc-log-format-misses-pause-remark-cleanup`, targeting release 0.17.0.

## Overview

The Java GC registry entry (`mt6`) recognized only one shape: a pause name
followed by a parenthesized cause clause, a heap transition, and a duration.
G1 writes several pause and event forms that do not carry a cause clause, and
those lines never matched — their pause durations and heap deltas were
invisible to statistics, heatmaps, and histograms.

This drop widens the entry to the full set of G1 `[info][gc]` forms that carry
either a stop-the-world pause or a state marker, and deliberately excludes the
concurrent-cycle forms.

## Requirements

### R1 — Recognize every cause-less G1 pause form

`Pause Remark` and `Pause Cleanup` carry a heap transition and a pause duration
but no cause clause. They are stop-the-world pauses and belong in the duration
statistics alongside `Pause Young` and `Pause Full`.

### R2 — Surface the G1 state markers

`To-space exhausted` (evacuation failure) and `Using G1` (collector selection
at JVM start) carry neither heap nor duration. They are counted and rendered as
their own categories; `Using G1` doubles as a JVM restart count.

### R3 — Extraction parity for the forms already recognized

Every field the previous pattern produced must be reproduced byte-identically.
Verified in D42 below.

### R4 — G1 named explicitly, other collectors reserved

The entry is scoped to G1 and named for it, leaving room for sibling entries
covering Serial, Parallel, Shenandoah and ZGC without a further rename.

## Locked decisions

### D41 — Concurrent-cycle lines are deliberately not recognized (LOCKED 2026-08-21)

`Concurrent Mark Cycle`, `Concurrent Cycle` and `Concurrent Undo Cycle` are
excluded, and the event name in the pattern is a closed alternation rather than
an open `(.+?)` so they cannot be admitted by accident.

Each appears twice per cycle: once bare (start) and once with an elapsed figure
(end). That elapsed figure is a wall-clock envelope containing the `Pause
Remark` and `Pause Cleanup` pauses this same entry now captures:

```
11:18:07.399  Concurrent Mark Cycle              <- start
11:18:07.412  Pause Remark   78M->78M(320M)  4.654ms
11:18:07.413  Pause Cleanup  78M->78M(320M)  0.266ms
11:18:07.416  Concurrent Mark Cycle  17.057ms   <- end, spans both pauses above
```

Admitting it would count concurrent (non-stop-the-world) time as pause time and
double-count the two pauses. The rejection is also cheaper than the previous
pattern's: measured at −31 ns/line on this class, because an explicit name list
fails sooner than the previous backtracking prefix.

### D42 — Level stays event identity, not severity (LOCKED 2026-08-21)

`Pause Remark`, `Pause Cleanup`, `To-space exhausted` and `Using G1` each become
their own entry in the log-level vocabulary, following the existing treatment of
`Pause Young` and `Pause Full`. A severity mapping (evacuation failure to ERROR,
collector banner to INFO) was considered and rejected: it does not survive the
JDK-version divergence recorded in F1 below, and level in this tool already
means identity rather than severity.

### D43 — G1-scoped naming (LOCKED 2026-08-21)

Slug renamed `java_gc_log` -> `java_gc_g1`. Accepted as a breaking change to the
slug stability contract; all consuming surfaces updated in the same commit.

## Research findings (2026-08-21)

Sourced from HotSpot itself: every `[info][gc]` line originates in a
`GCTraceTime(Info, gc)` or `log_info(gc)` call, so the vocabulary is finite and
enumerable from the source rather than inferred from samples.

### F1 — `To-space exhausted` is a legacy form; modern JDKs encode the same failure as a cause suffix

`log_info(gc)("To-space exhausted")` is present at JDK 17
(`g1CollectedHeap.cpp`) and absent from current master. It was replaced by a
suffix appended to the pause name itself, built in
`G1YoungGCTraceTime::update_young_gc_name()` (`g1YoungCollector.cpp`):

```c
"Pause Young (%s) (%s)%s"   /* trailing %s = " (Evacuation Failure: Allocation / Pinned)" */
```

The same failure therefore appears two different ways depending on JVM version.
Both are now captured — the legacy form as its own category, the modern form as
a cause clause on the pause line, where it was already being captured and simply
carried no distinct marking.

### F2 — Both conventions are present in the committed fixture corpus, in disjoint files

Across `logs/GC/logs-gc/` (4,943,052 lines, 33 distinct shapes):

| | `To-space exhausted` | `(Evacuation Failure)` suffix |
|---|---|---|
| `gc-twx01-twx-thingworx-0.out.3` | 5 | 0 |
| 7 other files | 0 | 1,359 |

No file carries both. This is a concrete instance of the umbrella concern in
#385 (same line shape, divergent data quality as a registry-level problem).

### F3 — The legacy marker is attached to the following pause, not an independent event

It shares the `GC(n)` identifier and the millisecond timestamp of the pause it
describes, and that pause carries no `(Evacuation Failure)` suffix of its own:

```
[2024-10-16T05:27:56.233+0000] GC(144521) To-space exhausted
[2024-10-16T05:27:56.233+0000] GC(144521) Pause Young (Prepare Mixed) (G1 Evacuation Pause) 49138M->30591M(49152M) 148.622ms
```

### F4 — Wider `[info][gc]` vocabulary, recorded but not implemented

Not implemented in this drop (G1 only, per D43), recorded so a future collector
entry starts from the enumeration rather than repeating the research:

- Error-grade: `GC Overhead Limit exceeded too often (N).` (G1, Parallel) ·
  `Failed to expand young-gen by N bytes` (Serial) · `Out Of Memory (<thread>)`
  (ZGC) · `Failed to allocate ...` (Shenandoah) · `Cancelling GC: <cause>`
  (Shenandoah) · `<name> (<cause>) Aborted` (ZGC)
- Informational: `Using <collector>` for Serial / Parallel / Shenandoah /
  The Z Garbage Collector / Epsilon (`universe.cpp`, same statement as
  `Using G1`) · `Soft Max Heap Size: ...`, `Trigger: ...`,
  `Heuristics ergonomically sets -XX:...` (Shenandoah)

The cause clause itself draws from a closed 35-entry table
(`GCCause::to_string`, `gcCause.cpp`).

## Measurements (2026-08-21)

Against the full committed corpus, 4,943,052 lines.

### Correctness

| | |
|---|---|
| Lines matched before | 2,791,575 |
| Lines matched after | 3,865,527 (**+1,073,952**) |
| Divergent fields on previously-matching lines | **0** |
| Still unmatched | 1,077,525 — exactly the three concurrent-cycle forms (D41) |

Newly captured: `Pause Remark` 536,951 · `Pause Cleanup` 536,950 ·
`Using G1` 46 · `To-space exhausted` 5.

On a 20-minute single-server slice, measured GC pause time rises from 3.276 s to
4.680 s — a 43% increase in observed stop-the-world time that was previously
absent from every duration statistic.

### Cost

Medians of 7 runs, 400k lines per class, attributed by line class:

| Line class | Corpus share | Delta |
|---|---|---|
| Matched before and after (like-for-like) | 56.5% | +205 ns/line (+14%) |
| Newly captured | 21.7% | +548 ns/line (work not previously performed) |
| Rejected before and after (concurrent) | 21.8% | **−31 ns/line (−5%)** |

Net on a 1.5M-line mixed natural-order stream: 1.533 s -> 1.832 s, about
+199 ns/line on the recognition step, in exchange for 38% more of the file being
captured.

A branch-reset variant (`(?|...)`) placing the hot pause shape in its own branch
was built and measured: it halved the like-for-like cost (+92 ns/line) but lost
more than it gained on the rejection path (+234 ns/line), netting 1.924 s on the
same stream — worse than the shipped form and considerably harder to read. The
simple nested-optional form is the shipped design.

## Defect found and fixed in the same change

`gc_heap_delta` called `convert_bytes($heap_from)` unguarded, and
`convert_bytes()` pattern-matches its argument with no `defined` test. The two
payload-less forms have no heap transition, so the transform emitted
uninitialized-value warnings on every such line. The transform is now gated on
both heap operands being defined.

The summary-table category loop computed a label into a variable that was never
read, padding it to a fixed 14 characters. `To-space exhausted` is 18 characters,
producing a negative repeat count warning. The dead assignment is removed.

## Open items

- Records with no message (`Pause Remark`, `Pause Cleanup`, `To-space
  exhausted`, `Using G1`) are excluded from the top-messages table, so they
  receive no per-message percentiles. Their durations and counts do reach the
  bucket statistics, the graph legend, and the category totals. Whether these
  forms should carry a synthesized message to gain per-message statistics is
  undecided.
