# #656 — Read unified G1 GC logs written without the level-and-tags decoration

Issue #656 (Read unified GC logs decorated with the time only). Owning area:
`features/382-gc-log-g1-format-coverage.md` (the G1 garbage-collection registry
entry, `java_gc_g1`); registry mechanics in `features/log-format-registry.md`.
Target: the 0.18.6 patch release, forward-ported to release/0.19.0 afterwards.

Status: specification in progress. The decisions below are locked; the
requirements per decoration shape, the entry names, the detection and
self-validation sample lines and the acceptance criteria are written after the
architect's logs for each shape are in the corpus and have been reviewed.

## What this is for

An analyst chasing a slowdown in an application server's access log checks
garbage collection first: did stop-the-world pause time rise in the same buckets
the response times did? `ltl` answers that by reading the JVM's GC log on the same
time axis as the access log, with each pause's duration in the duration column
(summed per bucket), its kind as the category and its cause as the message. A GC
log whose lines `ltl` does not recognise forces the analyst to total pauses
outside the tool, which is what happened on the case that produced this issue
(pause time turned out flat at 0.1 to 0.2% of wall clock, ruling GC out).

The JVM's unified logging lets the operator choose which decorations prefix each
line. The G1 entry reads `[time][level][tags]` with anything between the time and
the level. Application servers commonly configure the time decoration alone, or
other sets without the tags, and `ltl` reads none of those lines.

## Requirement

From the issue, in its terms: a unified-logging G1 GC log whose lines carry only
the time decoration is read as the G1 garbage-collection format, producing the
same records the G1 entry produces today from the same events written with level
and tags. Widened by the architect (D3 below) to every decoration set the JVM
writes without the tags.

## Findings

Measured on release/0.18.6 (`c56ae7b`), 2026-10-03.

### F1 — what the G1 entry requires

`format_registry_specs()`, entry `mt6` (`java_gc_g1`): after the ISO time and its
offset the pattern requires `.*?\[info\]\[gc\s*\] `, that is the `info` level and
exactly the `gc` tag set (space padding tolerated). Decorations between the time
and the level (uptime, pid) are tolerated. Measured on two-line synthetic files
with `-V format-detection`: `[time][uptime][info][gc]` binds `java_gc_g1` with both
lines matched; `[time][uptime]` (no level, no tags) and the JVM's default
`[uptime][info][gc]` (no wall-clock time) both bind nothing. The time-only
decoration fails at the same point: nothing follows the time but a space.

### F2 — reproduction

The corpus holds one time-only G1 log: a Java application server's method-server
GC log, JDK 21, G1, every `gc` tag set at info (phases, heap regions, metaspace,
cpu and init lines present), written on Windows with CRLF line endings, 1,127
lines. `ltl -n 3 -V` on it: `lines_unmatched: 1127`, every one of the 19 scanned
entries at 0 in `match_counts:`, and the console line `Read 1127 lines, however no
lines matched any of the patterns within the timeframe.` No other entry claims any
of its lines, so nothing shadows a new pattern. The set this log belongs to is not
listed in `docs/test-logs.md`; the entry is added when the logs for the other
shapes arrive.

### F3 — without tags, a pause appears twice

With all `gc` tag sets enabled, HotSpot writes a pause twice: the start (tag set
`gc,start`, name and cause only) and the end (tag set `gc`, name, cause, heap
transition and duration). The tagged form tells them apart by tag, and the G1
entry reads only the end. A tag-less form drops the tag, so the two lines differ
only by whether the heap-and-duration figure is present. Line shapes in the
specimen:

| Shape (time-only) | Lines | Today's tagged equivalent |
|---|---|---|
| `Pause Young (cause) (cause)` with no figure | 65 | `gc,start`, not read |
| `Pause Young (cause) (cause) NM->NM(NM) N.NNNms` | 65 | `gc`, read |
| `Pause Remark` / `Pause Cleanup` with no figure | 8 / 8 | `gc,start`, not read |
| `Pause Remark` / `Pause Cleanup` with the figure | 8 / 8 | `gc`, read |
| `Using G1` | 1 | `gc`, read |
| `Concurrent Mark Cycle`, start and end | 8 / 8 | `gc`, not read (D41 of the G1 record: concurrent-cycle lines are deliberately not recognised) |
| phase, region, metaspace, cpu, worker, banner lines | 948 | other tag sets, not read |

A scratch probe counted what two candidate rules admit on the specimen, line
endings stripped as `read_and_process_logs()` strips them:

| Rule for the time-only form | Lines admitted | Pause Young | Remark | Cleanup | Using G1 | Pause time summed |
|---|---|---|---|---|---|---|
| the G1 alternation with the figure optional, as today | 163 | 130 (65 without a duration) | 16 | 16 | 1 | 8,558.580 ms |
| a pause line must carry the figure; `Using G1` and `To-space exhausted` need none | 82 | 65 | 8 | 8 | 1 | 8,558.580 ms |

The summed pause time is the same either way; the counts are not. Admitting start
lines doubles every pause-kind count and breaks the event-ledger property the G1
entry carries (D9 of the classification record: the G1 log is an event ledger, one
line per pause), which `docs/explain/classification.md` states as "every operation
of that kind produces exactly one line".

### F4 — the tagged twin is the oracle

A twin of the specimen was built in the scratchpad with `[info][gc]` restored on
pause-end, `Using G1` and concurrent-cycle lines, `[info][gc,start]` on pause-start
lines and a non-`gc` tag on the rest. The shipped tool on the twin (`-V`,
captured): `format: java_gc_g1`, `match_type: 6`, `matched_lines: 82`,
`unmatched_lines: 1045`, `lines_included: 82`, `event_ledger: yes`,
`metrics_observed: yes`, `unregistered_levels: -`. Rendered at width 180: one
2-hour bucket, legend `Pause Young: 65 Pause Remark: 8 Pause Cleanup: 8 Using G1: 1`,
duration column 8.6 s, P50 81 ms, P95 271 ms, P99 511 ms; top message
`[Pause Young] (Normal) (G1 Evacuation Pause)` with 50 occurrences totalling
6.7 s; category table 65 / 8 / 8 / 1. These are the values the time-only specimen
must produce.

### F5 — the tagged corpus is untouched by the figure rule

Over the tagged G1 corpus (4,943,052 lines, every file in the GC collection), the
shipped pattern matches 3,865,527 lines (the figure the G1 record recorded).
Requiring the figure on pause lines in the tagged form as well matches the same
3,865,527 lines with the same kinds and the same summed durations: no tagged
pause-kind line in the corpus lacks the figure, since HotSpot writes the
figure-less start under `gc,start`. Neither time-only rule admits any tagged line.

### F6 — CRLF

The specimen's lines end in CRLF. The read loop strips `[\r\n]+$` and
`sample_file_for_detection()` strips `\r$`, so a `$`-anchored pattern sees the
line without the carriage return. No new handling is needed; a fixture keeping
CRLF proves it on this path.

### F7 — the decoration is not JDK-specific

The issue names JDK 17; the specimen is JDK 21. The time decoration's shape
(`yyyy-MM-ddTHH:mm:ss.SSS±hhmm` in brackets) is the same from JDK 9 on, and the
`utctime` decoration produces the same shape with `+0000`. JDK 17 writes
evacuation failure as a separate `To-space exhausted` line, which a JDK 17
time-only log would carry as `[time] GC(n) To-space exhausted`; no time-only
JDK 17 specimen is held yet.

### F8 — the record's surroundings

On release/0.19.0 the G1 entry additionally declares `byte_notation => 'iec'`
(heap sizes read in powers of 1024), so heap-delta values there are 1.048576
times those on 0.18.6; new entries' expected sample values are re-derived on the
forward-port. The registry counts the harnesses assert (`scanned_entries`,
`scan_slots`, `static_order`, `entries`) move by the number of entries added.

### Citation corrections

- The reproduction files the issue names are not in the corpus; the only
  time-only G1 log held is the JDK 21 specimen of F2, on which the same message
  prints with 1,127 lines.
- The title's "JDK 17" is the case's JDK, not a property of the decoration (F7).
- In the specimen the first line is `CardTable entry size: 512`, not `Using G1`;
  a JDK 21 difference that does not matter to the reading.

## Locked decisions (architect, 2026-10-03)

### D1 — additional registry entries, never the existing one widened

The tag-less decorations are read by additional entries beside `java_gc_g1`. The
tagged entry's pattern, which 3.87 million tagged corpus lines run through, is not
edited, so its parity holds by construction.

### D2 — one child entry per decoration shape that differs

The registry exists to define child entries that fit similar but different
needs. Where two decoration sets produce lines a single pattern reads without
widening, they share an entry; where they differ, each has its own. The number of
entries follows from the logs.

### D3 — the whole scope is covered in this issue

Time alone, UTC time, time with uptime, time with level, time with process id,
and whichever further tag-less sets the provided logs show, are all addressed
here. Nothing waits for a later specimen.

### D4 — each entry is a format in its own right on every surface

Its own name in the timeline legend, in `--help formats`, under `-lf` and in the
`format:` key of the detection report.

### D5 — the figure-less pause start is not read

A pause line is read only when it carries the heap transition and the duration,
so each pause is one record, as in the tagged form (F3). `Using G1` and
`To-space exhausted` carry no figure and are read as today.

### D6 — no GC-specific benchmark

The completion gate is the standard one: the full harness suite and the
`single-day-access-log-standard` before/after.

### D7 — real logs are a prerequisite

The architect provides a log for each decoration shape. The specification resumes
with a review of those logs, from which the remaining requirements are recorded
before any code.

## Standing decisions that govern the surface

- D41 of the G1 record: concurrent-cycle lines are deliberately not recognised;
  their wall-clock span is never counted as pause time.
- D43 of the G1 record: naming is G1-scoped.
- D9 of the classification record: the G1 log is an event ledger that declines to
  classify; new entries carry the same posture.
- D47 of the registry record: a variant group fills one scan slot and exists for
  shapes nothing on the line distinguishes. A decoration is visible on every line,
  so the new entries are not variants of the tagged entry.

## To be written after the log review

- The decoration shapes present, one row per shape, with a scrubbed sample line
  each.
- The entry names and which shapes each entry reads (D2).
- Contracts: parity with the tagged form's records (F4) per entry; the tagged
  form unchanged (F5); CRLF (F6).
- Acceptance criteria with their harness scenarios in
  `tests/validate-format-detection.sh` (binding, one record per pause, parity
  with the tagged twin, the format pin), the count assertions in
  `tests/validate-format-registry.sh`, the `--help formats` assertion in
  `tests/validate-log-level-vocabulary.sh`, and the rendered check on the
  specimen (F4's values).
- The `docs/test-logs.md` entries for the provided logs.

## Implementation

Not started.
