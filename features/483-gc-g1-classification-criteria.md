# #483 — Success and failure classification criteria for the G1 GC log formats

Issue #483 (success/failure classification criteria for the Java G1 GC log format).
Mechanism: `features/453-success-failure-classification-event-ledger.md` (per-entry
field-targeted criteria, any-of across, all-of within; a line matching both outcomes
is a failure, D4; a line matching neither is unclassified). Owning area:
`features/382-gc-log-g1-format-coverage.md` (the tagged G1 entry) and
`features/656-gc-log-tagless-decorations.md` (the four tag-less entries). Grouped
under #732 (GC log analysis).

Status: specification, 2026-10-16.

## What this is for

The G1 entries are event ledgers that decline to classify (D9 of the classification
record), so the reliability figure and the other consumers of classification have
nothing to read on a GC log. The criteria let an analyst see, per bucket, the pauses
in which the collector failed, against those that completed.

## Decisions

### D1 — failure from the JVM's failure statements, success from the standard GC operation messages, every other line unclassified (architect, 2026-10-16)

- **Failure** is classified from the statements the JVM itself writes when a
  collection fails, enumerated from the HotSpot source, not inferred from the
  lines a corpus happens to hold.
- **Success** is classified from the standard GC operation messages: the lines
  recording a collection that ran.
- **Unclassified**: every other line a G1 entry matches, the CPU load lines of #667
  (match the CPU load lines of the G1 GC formats, so user-defined metrics can read
  them) among them.

Applied the same day by the architect to conditions raised from the corpus: a
missed pause-time goal (`MMU target violated`) is a target not met, not a failure;
a full collection (`Pause Full`) is not a failure.

## Findings

### F1 — the failure statements on record

From the HotSpot source survey in `features/382-gc-log-g1-format-coverage.md`
(F1 and F4):

| Failure | Written as | Collector | Held in the corpus |
|---|---|---|---|
| Evacuation failure, JDK 17 | `GC(n) To-space exhausted`, its own line | G1 | 37 and 11 in two time-only sets, 5 tagged |
| Evacuation failure, JDK 21 | ` (Evacuation Failure)` appended to the pause line | G1 | 3,703 time-only, 1,359 tagged |
| Evacuation failure, current master | ` (Evacuation Failure: Allocation)` or `: Pinned)` on the pause line | G1 | none |
| GC overhead limit | `GC Overhead Limit exceeded too often (N).` | G1, Parallel | none |
| Failed young-generation expansion | `Failed to expand young-gen by N bytes` | Serial | none |
| Out of memory | `Out Of Memory (<thread>)` | ZGC | none |
| Failed allocation | `Failed to allocate ...` | Shenandoah | none |
| Cancelled collection | `Cancelling GC: <cause>` | Shenandoah | none |
| Aborted collection | `<name> (<cause>) Aborted` | ZGC | none |

Whether G1 writes an out-of-memory condition to the GC log is not established by
that survey.

### F2 — the JDK 17 evacuation failure is written before its pause line

In the JDK 17 time-only logs, `To-space exhausted` is written inside the pause's
segment of lines, after its start line and before the pause line, carrying the
same `GC(n)`:

```
GC(521) Pause Young (Prepare Mixed) (G1 Preventive Collection)
GC(521) Using 2 workers of 2 for evacuation
GC(521) To-space exhausted
GC(521)   Pre Evacuate Collection Set: 0.1ms
...
```

The record before the marker is therefore the previous cycle's last pause, not
the pause it belongs to.

### F3 — `Concurrent Mark Abort` follows a full collection

All 54 `Concurrent Mark Abort` lines in the time-only sets come directly after a
`Pause Full`: 12 after `G1 Compaction Pause` on JDK 21, 42 after `System.gc()` in
the set with no version written. It is a concurrent-cycle line, not read by any
G1 entry (D41 of the G1 record).

### F4 — what precedes a full compaction

Of the 15 `Pause Full (G1 Compaction Pause)` on JDK 21, 12 come directly after a
young pause carrying ` (Evacuation Failure)`; every one is preceded by `Attempting
full compaction`, three of them `... clearing soft references`. No line of the GC
corpus, tagged or time-only, carries an overhead-limit or out-of-memory statement.
