# #667 — Match the CPU load lines of the G1 GC formats, so user-defined metrics can read them

Issue #667 (match the CPU load lines of the G1 GC formats, so user-defined metrics
can read them). Owning area: `features/382-gc-log-g1-format-coverage.md` (the tagged
G1 entry, `java_gc_g1`) and `features/656-gc-log-tagless-decorations.md` (the four
tag-less G1 entries); registry mechanics in `features/log-format-registry.md`. Grouped
under #732 (GC log analysis). Reading the whole of each pause's segment of lines is
#742 (read the multi-line pause segments of the G1 GC log formats, in their variants),
whose record `features/742-gc-multiline-pause-segments.md` holds the measurement of
every line kind the segments carry.

Status: specification, 2026-10-16.

## What this is for

An analyst correlating a slowdown with garbage collection wants to know whether the
collector's threads had the CPU they needed during the pauses: CPU time against wall
clock, per bucket. The JVM writes it on one line per pause,
`GC(n) User=0.05s Sys=0.01s Real=0.03s`, which no format matches, so no user-defined
metric can read it.

## Requirement

From the architect, in his terms: adapt the regular expressions of the GC format
matching patterns to also match the lines containing the CPU load. Once those lines
are matched, an analyst is able to use user-defined metrics to parse them out.

## Decisions

### D1 — the scope is the CPU load lines (architect, 2026-10-16)

The issue's scope is reduced from every detail line of a pause to the CPU load line.
Reading the whole segment, every variant, is #742, blocked by #741 (read log formats
whose entry is a known multi-line structure). This issue does not depend on either:
it makes the CPU load lines matched lines, and the values are read by `-udm`.

## Surfaces and the records that govern them

| Surface | Contract today | Record line |
|---|---|---|
| The five G1 entries in `format_registry_specs()` | "No other line about the same event is a record: not the start line written without the figure, not the phase or region lines at debug or trace, not the CPU line." | `features/656-gc-log-tagless-decorations.md` D5 |
| The same entries' ledger posture | One line per pause; the entry declines to classify | `features/453-success-failure-classification-event-ledger.md` D9 |
| The tagged entry's pattern | Reads the `gc` tag set only, the level bracket padded or not | `features/656-gc-log-tagless-decorations.md` D1 |
| User-defined metrics | Tried only on lines that matched a format | `features/637-udm-continuation-lines.md` D1 |
| Time attribution | A line's contribution lands in the bucket of its own timestamp | `features/log-format-registry.md` D22 |

## The CPU load line

From the measurement over the three time-only log sets in
`features/742-gc-multiline-pause-segments.md` (deployment A, JDK 17, 40 files;
B, JDK 21, 10 files; C, version not written, 18 files):

- **One per pause record**, Young, Full, Remark and Cleanup alike: 155,636 (A),
  79,370 (B), 94,017 (C). It carries the pause's `GC(n)` number and nothing naming
  the pause kind or cause.
- **After its record.** On A and C always the next line; on B 21,036 of 79,370 come
  after up to six concurrent-cycle lines of the next `GC(n)`.
- **Timestamped with its record.** Every CPU line follows a record of its number.
  Its timestamp equals the record's on 146,984 of 155,636 (A), 74,780 of 79,370 (B)
  and 85,652 of 94,017 (C); it falls in a different minute from its record once,
  on B.
- **Precision.** Seconds to two decimals. `Real=0.00s` on 26,429 (A), 22,075 (B)
  and 9,402 (C) lines. Summed, `Real` over the summed pause time is 1.0021, 1.0018
  and 1.0004; `User + Sys` over the summed pause time is 1.97, 1.79 and 1.91, with
  2 evacuation workers on every pause.
- **Tagged form.** No tagged log in the corpus carries it; the JVM-generated tagged
  fixtures write it under the `gc,cpu` tag set.
- **Today.** On deployment A's method-server log (325,914 lines, 22,951 records),
  `-udm 'gc_user:s:sum:/User=([\d.]+)s/'` reports `no metrics produced from matching
  lines`.
