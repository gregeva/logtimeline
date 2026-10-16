# #667 — Read the per-pause detail lines of the G1 GC formats

Issue #667 (read the per-pause CPU time, heap and region detail, and phase timing
lines of the GC formats). Owning area: `features/382-gc-log-g1-format-coverage.md`
(the tagged G1 entry, `java_gc_g1`) and `features/656-gc-log-tagless-decorations.md`
(the four tag-less G1 entries); registry mechanics in `features/log-format-registry.md`.
Grouped under #732 (GC log analysis) with #483 (success/failure classification
criteria for the G1 GC format).

Status: specification. Findings measured on release/0.20.0 (`891fe91`), 2026-10-16;
the architect's interview follows and its decisions are recorded here as they are made.

## What this is for

An analyst correlating a slowdown with garbage collection reads the JVM's GC log on
the same time axis as the application's own logs. Today `ltl` gives them, per
bucket, the pause count by kind, the summed pause time and the heap reclaimed. It
does not tell them why a pause took the time it did: whether the collector's threads
had the CPU they needed (CPU against wall clock), how the heap's regions moved
(eden reclaimed, survivors, promotion into old, humongous growth), and which phase
of the pause took the time. The JVM writes all three, on lines `ltl` counts as
unmatched.

## Requirement

From the issue, in its terms: read the detail lines a unified GC log writes about
each pause, for every GC format the tool covers (the tagged G1 entry and the four
tag-less entries): the CPU time per pause, the heap and region detail, and the phase
timing. The lines belong to the pause they describe (the same `GC(n)` number), so
they are read as attributes of that pause, not as events of their own that would
inflate the pause count. The analyst sees, per bucket, besides the pause time: CPU
against wall clock, how the regions moved, and which phase took the time.

## Surfaces and the records that govern them

| Surface | Contract today | Record line |
|---|---|---|
| The five G1 entries in `format_registry_specs()` | The record is the line carrying the heap transition and pause time; no other line about the same event is a record, the CPU line named among them | `features/656-gc-log-tagless-decorations.md` D5 |
| The same entries' ledger posture | One line per pause; the entry declines to classify | `features/453-success-failure-classification-event-ledger.md` D9 |
| Concurrent-cycle lines | Deliberately not recognised; their span is never counted as pause time | `features/382-gc-log-g1-format-coverage.md` D41 |
| Decoration brackets | Matched and not kept | `features/656-gc-log-tagless-decorations.md` D9 |
| The tagged entry's pattern | Not widened beyond the padded level bracket (scoped to #656) | `features/656-gc-log-tagless-decorations.md` D1 |
| Time attribution | A line's contribution lands in the bucket of its own timestamp | `features/log-format-registry.md` D22 |
| State carried across lines | Merging lines that share a correlation key into one logical event is #372's capability (on hold, blocked by #61 and #59). It is declared per format as an optional sub-determination, so a format without declarations pays nothing; its state is #61's inter-line store, with a one-shot consume-at-end lifecycle, not a store of its own; the merged event is a standard parse-stage record in the completion bucket. #372 leaves nested pairing and one-start-to-many-ends fan-out to a future specification when a consumer demands it | `features/log-format-registry.md` D23 (a) (c), D58 (a); #372 § Out of scope |
| Metrics a format declares | `message_metrics` probes fill the canonical fields (duration, bytes) from the matched line's message | `format_registry_specs()`, entry `mt1std` |
| User-defined metrics | Read from lines a format matched, never from unmatched lines | F10 below |

## Findings

Measured over the three sets of time-only G1 logs held in the corpus, named as in
`features/656-gc-log-tagless-decorations.md` F9: deployment A (JDK 17.0.13, 40 files,
2,173,895 lines), deployment B (JDK 21.0.11, 10 files, 1,003,220 lines), deployment C
(version not written, 18 files, 1,398,038 lines). Every file carries `-Xlog:gc*` at
info. The scratch measuring script reads each line's `GC(n)` and kind and tracks each
pause from its first detail line to its CPU line.

### F1 — what one pause writes

A young pause on deployment A, one line each, in the order written:

```
GC(2) Pause Young (Concurrent Start) (Metadata GC Threshold)          start, no figure
GC(2) Using 2 workers of 2 for evacuation
GC(2)   Pre Evacuate Collection Set: 0.1ms                            phases (indented)
GC(2)   Merge Heap Roots: 0.1ms
GC(2)   Evacuate Collection Set: 24.1ms
GC(2)   Post Evacuate Collection Set: 1.2ms
GC(2)   Other: 0.2ms
GC(2) Eden regions: 19->0(71)                                          regions: before->after(target)
GC(2) Survivor regions: 4->5(10)
GC(2) Old regions: 0->0
GC(2) Archive regions: 0->0                                            JDK 17 only
GC(2) Humongous regions: 3->3
GC(2) Metaspace: 35938K(36288K)->35938K(36288K) NonClass: ... Class: ...
GC(2) Pause Young (Concurrent Start) (Metadata GC Threshold) 195M->62M(12288M) 25.882ms   the record
GC(2) User=0.05s Sys=0.01s Real=0.03s                                  CPU, after the record
```

`Pause Remark` and `Pause Cleanup` write the start line, the record and the CPU line,
nothing else. `Pause Full` writes the start, a workers line, each full-collection
phase twice (a start line without a figure and an end line with its milliseconds),
the region and metaspace lines, the record and the CPU line. `To-space exhausted`
and `Using G1` write nothing further.

### F2 — counts per line kind

| Line kind | A | B | C |
|---|---:|---:|---:|
| Pause records (Young / Full / Remark / Cleanup) | 107,644 / 0 / 23,996 / 23,996 | 35,381 / 15 / 21,987 / 21,987 | 44,826 / 35,750 / 6,730 / 6,711 |
| CPU (`User= Sys= Real=`) | 155,636 | 79,370 | 94,017 |
| Young-pause phase lines (5 per pause on A and B, 4 on C) | 538,220 | 176,905 | 179,300 |
| Region and metaspace lines (6 per pause on A, 5 on B and C) | 645,864 | 176,980 | 402,876 |
| `Using N workers of N for evacuation / full compaction` | 107,644 | 35,396 | 80,575 |
| Full-collection phase lines (start and end) | 0 | 150 | 286,000 |
| `MMU target violated` | 752 | 706 | 10,035 |

One CPU line per pause record on every set. Region and metaspace lines follow young
and full pauses, never Remark or Cleanup.

### F3 — association needs the `GC(n)` number, not adjacency

Phase, region and metaspace lines precede the record; the CPU line follows it. On
deployment B, 21,036 of 79,370 CPU lines are not the line after their record: when a
young pause starts a concurrent cycle, the next `GC(n)`'s concurrent-cycle lines are
written between the record and its CPU line:

```
GC(62) Pause Young (Concurrent Start) (System.gc()) 3501M->1413M(5888M) 34.602ms
GC(63) Concurrent Mark Cycle
GC(62) User=0.07s Sys=0.00s Real=0.03s
```

On deployments A and C every CPU line was the line after its record. On deployment B
a concurrent cycle's lines (`GC(1661) Concurrent Mark From Roots`, `... Abort`) are
also written after the full pause numbered `GC(1662)` completes.

### F4 — the CPU line's precision, and what it adds to the pause time

The CPU line states seconds to two decimals, so it resolves 10 ms. `Real=0.00s` on
26,429 of 155,636 CPU lines (A), 22,075 of 79,370 (B) and 9,402 of 94,017 (C).

Summed over each set, `Real` over the summed pause time is 1.0021 (A), 1.0018 (B) and
1.0004 (C): the wall clock the CPU line reports is the pause time already read, at
coarser resolution. `User + Sys` over the summed pause time is 1.97 (A), 1.79 (B)
and 1.91 (C), with `Using 2 workers of 2 for evacuation` on all 187,850 evacuation
lines across the three sets: the collector's threads ran close to fully parallel.

### F5 — the top-level phases account for the young pause

Young pause time minus the sum of its top-level phases: median 0.12 ms (A), 0.25 ms
(B), 0.12 ms (C); 99th percentile 0.28, 0.41 and 0.27 ms; maximum 1.7, 355.5 and
9.2 ms.

### F6 — the phase and region vocabulary differs by JDK

- Young-pause phases: A and B write `Pre Evacuate Collection Set`, `Merge Heap
  Roots`, `Evacuate Collection Set`, `Post Evacuate Collection Set`, `Other`, plus
  `Merge Optional Heap Roots` and `Evacuate Optional Collection Set` on 2 pauses (A)
  and 197 (B). C writes four, without `Merge Heap Roots`. Milliseconds to one
  decimal on A and C, two on B.
- Full-collection phases: B writes five (`Mark live objects`, `Prepare compaction`,
  `Adjust pointers`, `Compact heap`, `Reset Metadata`); C writes four, the second
  named `Prepare for compaction`.
- Regions: `Archive regions` on A only.
- Metaspace: `used(committed)->used(committed)` for the whole, then `NonClass:` and
  `Class:` the same way, on all three sets.

### F7 — region counts are counts; the region size is in the start banner

`Heap Region Size: 8M` on A's method servers and `4M` on B's. 4 of the 68 files
carry no banner: a JVM's log that continues after a rotation starts without one.

### F8 — bucket placement of a pause's lines

Lines of one pause that fall in a different minute from the pause's first detail
line: 63 (A), 26 (B), 464 (C). The full-collection phases on C span up to about a
second before the record.

### F9 — the tagged form

All 4,943,052 lines of the tagged G1 corpus are `[info][gc]`: the tagged corpus
carries no detail line. The tagged fixtures cut from the JVM runs of
`features/656-gc-log-tagless-decorations.md` F14 carry them under their own tag sets:
`gc,cpu`, `gc,heap`, `gc,metaspace`, `gc,phases`, `gc,task`, `gc,start`.

### F10 — not reachable through `-udm` today

On deployment A's method-server log (325,914 lines, 22,951 records),
`-udm 'gc_user:s:sum:/User=([\d.]+)s/'` and `-udm 'eden_before::sum:/Eden regions: (\d+)->/'`
each report `no metrics produced from matching lines`: a user-defined metric reads
only lines a format matched, and these lines match none.

### F11 — read cost today

The same file, `-ni -bs 1440 -oe -V`, three runs: `parse/read_files` 2.003, 3.833
and 2.081 s, about 6.2 µs a line on the two consistent runs. 302,963 of its 325,914
lines are unmatched and pay the full scan.

## Citation corrections

- The issue says the tagged collection carries these lines; it does not (F9). Only
  the JVM-generated tagged fixtures do.
- The issue's metaspace example (`Metaspace: 120M->120M(1100M)`) is not the shape on
  any held log; JDK 17 and 21 write used and committed, then `NonClass:` and `Class:`
  (F6).
- "The lines belong to the pause they describe" holds by `GC(n)` number, not by
  position: the CPU line follows the record, sometimes after another pause number's
  lines (F3).
