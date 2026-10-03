# #656 — Read unified G1 GC logs written without the level-and-tags decoration

Issue #656 (Read unified GC logs decorated with the time only). Owning area:
`features/382-gc-log-g1-format-coverage.md` (the G1 garbage-collection registry
entry, `java_gc_g1`); registry mechanics in `features/log-format-registry.md`.
Target: the 0.18.6 patch release, forward-ported to release/0.19.0 afterwards.

Status: implemented on branch `656-gc-tagless-decorations` (see *Implementation*);
the completion gate is pending. The logs this specification was measured on are a
temporary set in the local corpus, provided for this work and removed once it
ships; they are not listed in `docs/test-logs.md` and no harness names them.

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
listed in `docs/test-logs.md`.

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

### F9 — the provided logs (log review, 2026-10-03)

68 GC logs from three deployments of the same application-server family, plus the
F2 specimen: every line of every file carries the time decoration only.

| Set | Files | Lines | JDK | Endings |
|---|---|---|---|---|
| Deployment A | 40 | 2,173,895 | 17.0.13 | LF |
| Deployment B | 10 | 1,003,220 | 21.0.11 | LF |
| Deployment C (set aside by the architect) | 18 | 1,398,038 | no version banner | LF |
| F2 specimen | 1 | 1,127 | 21.0.8 | CRLF |

The shipped tool over all 68 files in one run: `Read 4575153 lines, however no
lines matched any of the patterns within the timeframe.`, `format: -` on all 68.
The issue's reproduction file is among them: 76,956 lines, printing the issue's
message verbatim. Every other GC log in the corpus (46 files, 4,943,052 lines)
carries the tagged form `[time][info][gc]`. No other decoration shape exists
anywhere in the corpus: the leading bracket groups of every line of all 115 files
carrying unified GC lines were classified.

Every pause kind appears twice, with and without the heap-and-duration figure, in
equal numbers: deployment A 107,644 Young, 23,996 Remark, 23,996 Cleanup each way;
deployment B 35,381 Young, 15 Full, 21,987 Remark, 21,987 Cleanup each way. JDK 17
writes the `To-space exhausted` marker as its own line (37 on A); JDK 21 instead
appends ` (Evacuation Failure)` to 3,703 end lines whose start lines lack it. JDK
17 files start with `Using G1`, JDK 21 files with `CardTable entry size: 512`.
Deployment B carries five warning-level lines (`Retried waiting for GCLocker too
often`), the only non-info lines in the review.

### F10 — parity targets from tagged twins

Tagged twins of four time-only files, read by the shipped tool with one 30-day
bucket (`-V -bs 43200 -o`):

| File | Matched lines | Pause time | P50 / P95 / P99 |
|---|---:|---:|---|
| the issue's JDK 17 file | 6,070 | 39,526 ms | 5 / 20 / 24 ms |
| a JDK 17 file with To-space exhausted | 1,020 | 11,113 ms | 8 / 27 / 96 ms |
| a JDK 21 file with Pause Full | 6,619 | 191,382 ms | 19 / 100 / 216 ms |
| the CRLF specimen | 82 | 8,559 ms | 81 / 271 / 511 ms |

A scratch rule for the time-only form, run on each original, produces the same
(timestamp, kind, cause, heap from, heap to, heap size, duration) tuple stream as
the shipped pattern on its twin, byte for byte, CRLF included. Over whole
deployments the rule admits exactly the figure-bearing pauses plus markers
(A 155,713, B 79,380) and 0 of the 4,943,052 tagged lines; the shipped pattern
admits 0 of the 4,575,153 time-only lines.

### F11 — the other tag-less shapes, from the JVM itself

No log anywhere carries a tag-less shape other than time-only. A JDK 21 on this
machine wrote one run of a small allocating program to several outputs at once:
tagged, time, UTC time, time with uptime, time with level, time with process id,
time with thread id, and combinations. The tagged output is the oracle: the shipped
tool reads 183 records from it and 0 from each tag-less output, and a scratch rule
per shape reproduces the 183 tuples exactly, admitting 0 lines of every other
shape. What the outputs show:

- The JVM pads every decoration to the widest value written so far on that output:
  `[gc     ]`, `[info ]` after a debug line, `[9987 ]` for a thread id.
- UTC time is the time shape with `+0000`.
- The decoration order is fixed by the JVM whatever order the option lists.
- The pause record line (kind, cause, heap before and after, pause time) is written
  once per pause, at the info level, whichever other levels are on. Debug and trace
  add phase and region lines with different text; they never repeat the record.

### F12 — a pre-existing defect in the tagged entry

The tagged entry requires an unpadded `[info]`. On a tagged JDK 21 output with one
tag set at debug, the shipped tool reads 0 of 472 lines although 18 pause and marker
lines are present; a warning line pads the level the same way, and deployment B's
logs carry five. Fixed in this issue (D1 as amended).

### F13 — what a GC log carries that no entry reads

On deployment A, 1.8 million of 2.17 million lines are detail lines: CPU time per
pause (`User= Sys= Real=`), heap and region detail (Eden, survivor, old, humongous
region counts, metaspace), phase timing (pre-evacuate, evacuate, post-evacuate),
concurrent-cycle lines (D41 of the G1 record), banners and the exit summary. The
tagged entry reads none of them today, and the new entries keep parity. Reading the
CPU time, the region detail and the phase timing is #667 (read the per-pause CPU
time, heap and region detail, and phase timing lines of the GC formats), blocked by
this issue.

### F14 — the JDK 17 run of the generator, against the JDK 21 run (2026-10-03)

D7's prerequisite, run before any fixture was cut. The same program as F11 (an
allocator of 16 KB arrays, keeping about a third, one `System.gc()` midway) ran
once on OpenJDK 17.0.20.1 with `-Xms48m -Xmx48m -XX:+UseG1GC` and one
`-Xlog:gc*:file=…:<decorations>` output per decoration set: time, level and tags;
UTC time, level and tags; time only; UTC time only; time and uptime; time and
level; time and process id; time and thread id; and, with `gc+heap=debug` added on
the output, time and level, and time, level and tags. The JDK 21 run was repeated
with the same settings. Every output of one run has the same line count (JDK 17
4,623 lines, 7,384 with the debug tag set; JDK 21 2,835) and the same events.

- **No decoration shape differs between the two JDKs.** The leading bracket groups
  of every line of every output were classified: the time with its numeric
  offset, UTC time at `+0000`, uptime `[N.NNNs]`, level `[info]`, process and
  thread id as bare integers, and the same padding rule (the level reads
  `[info ]` once a debug line has been written; a thread id reads `[9731 ]` after
  a wider one; tags are padded).
- **When the padding starts differs.** JDK 17 writes a debug line (`Minimum heap
  …`) first, so every info line of its debug-enabled output reads `[info ]`; JDK 21
  writes `CardTable entry size: 512` at info first, so its first line is unpadded.
- **The line bodies differ as F7 and F9 found on the provided logs.** JDK 17 writes
  evacuation failure as its own `GC(n) To-space exhausted` line (30 in the run) and
  starts with `Using G1`; JDK 21 appends ` (Evacuation Failure)` to the end line
  (70 in the run). The JDK 17 run also carries the `G1 Preventive Collection` cause
  (211 records). Concurrent phase names differ (`Concurrent Rebuild Remembered
  Sets` against `… and Scrub Regions`); those lines are read by no entry.
- **Records.** JDK 17: 340 per output (Young 269, Full 7, Remark 17, Cleanup 16,
  To-space exhausted 30, Using G1 1). JDK 21: 183 per output (Young 155, Full 20,
  Remark 5, Cleanup 2, Using G1 1). With the entries built, every tag-less output
  of each run binds its own entry and reads exactly the record count of the same
  run's tagged output (the thread-id output through the process-id entry), and the
  tagged debug-enabled output reads all 340 through the padded level.

### Citation corrections, after the log review

- The issue's reproduction file is held: 76,956 lines, the issue's message verbatim.
- "JDK 17" is the case's JDK; the decoration is the same from JDK 9 on, and JDK 21
  logs of the same shape are held too.
- The earlier correction that the first line is `CardTable entry size: 512` holds
  for JDK 21 only; JDK 17 files start with `Using G1`.

## Locked decisions (architect, 2026-10-03)

### D1 — additional registry entries; the tagged entry edited for level padding only

The tag-less decorations are read by additional entries beside `java_gc_g1`. The
tagged entry's pattern is not widened. **Amended the same day:** the tagged entry is
edited for one thing, tolerating a padded level bracket (F12), and the tagged corpus
parity (3,865,527 of 4,943,052 lines, same kinds, same sums) is re-measured to prove
nothing else moved.

### D2 — one child entry per decoration shape that differs

The registry exists to define child entries that fit similar but different needs.
Where two decoration sets produce lines a single pattern reads without widening,
they share an entry; where they differ, each has its own.

### D3 — the whole scope is covered in this issue

Every tag-less decoration set the JVM writes is addressed here (D8 names the
entries). Nothing waits for a later specimen.

### D4 — each entry is a format in its own right on every surface

Its own name in the timeline legend, in `--help formats`, under `-lf` and in the
`format:` key of the detection report. No family key.

### D5 — the record is the line that carries the measurement

For each GC event the JVM writes exactly one line carrying the measurement: the
pause kind, the cause, the heap before and after, the pause time. That line is the
record. No other line about the same event is a record: not the start line written
without the figure, not the phase or region lines at debug or trace, not the CPU
line. The rule holds across levels and decorations because the figure is in the
message, not in the decoration, and it is what the tagged entry already does.
`Using G1` and `To-space exhausted` carry no figure and are read as markers, as
today.

### D6 — no GC-specific benchmark

The completion gate is the standard one.

### D7 — the prerequisite is a corpus to test against

Field logs were the only record while an application's source was out of reach.
Where the producer can be run, as the JVM can, its output under known settings is a
corpus with an oracle attached and satisfies the same intent. The JVM-generated
outputs (F11) stand as the specimens for time with uptime, time with level and
time with process id, and for UTC time. A JDK 17 run of the same generator is made
before the fixtures are cut; OpenJDK 17 was installed through Homebrew for it.

### D8 — four entries

| Entry name | Reads lines decorated with | Specimen |
|---|---|---|
| `java_gc_g1_time` | the timestamp alone, local or UTC | the provided logs (JDK 17 and 21), the CRLF specimen, the JVM run |
| `java_gc_g1_time_uptime` | the timestamp, then the uptime bracket | the JVM run |
| `java_gc_g1_time_level` | the timestamp, then the level bracket, padded or not | the JVM run |
| `java_gc_g1_time_pid` | the timestamp, then a process id or thread id bracket, padded or not | the JVM run |

The JVM can combine these brackets further (timestamp, uptime and process id
together, for instance); no log anywhere carries such a combination, and each is
added as its own entry when a log of it arrives.

### D9 — decoration brackets are matched and not kept

Uptime, level, process id and thread id are line shape, not data: none is kept as
a field, as locked for the connector format (#655 D4). No thread, so no
thread-pool rows and no per-thread split of the message keys.

### D10 — the detail lines stay unread here

The CPU, region and phase lines (F13) are #667's; this issue keeps parity with the
tagged entry.

## Standing decisions that govern the surface

- D41 of the G1 record: concurrent-cycle lines are deliberately not recognised;
  their wall-clock span is never counted as pause time.
- D43 of the G1 record: naming is G1-scoped.
- D9 of the classification record: the G1 log is an event ledger that declines to
  classify; the new entries carry the same posture.
- D47 of the registry record: a variant group fills one scan slot and exists for
  shapes nothing on the line distinguishes. A decoration is visible on every line,
  so the new entries are not variants of the tagged entry.
- D51 of the registry record: new detection scenarios run on committed fixtures.

## Entries

Fields on every entry, as the tagged entry: timestamp (ISO, offset in the line,
millisecond fraction); category = pause kind; message = cause clause (none on
Remark, Cleanup and the markers); bytes = heap before minus heap after through the
existing heap-delta transform; duration = pause time in ms; event ledger;
classification declines; the six categories declared (Pause Young, Pause Full,
Pause Remark, Pause Cleanup, To-space exhausted, Using G1); no filename evidence;
no ancestors. On release/0.19.0 the entries carry `byte_notation => 'iec'` and
re-derived expected bytes, as the tagged entry does there.

Self-validation samples, scrubbed from the provided logs and the JVM run, cover
each entry's kinds: a Young pause with a cause, a Young pause with the JDK 21
`(Evacuation Failure)` suffix, Remark, Cleanup, Full, `To-space exhausted`,
`Using G1`, and for the level and pid entries one padded bracket.

## Contracts

- **C1.** A tag-less G1 log binds its entry by content alone under the entry's own
  name on every surface (D4).
- **C2.** One record per pause, the line carrying the measurement (D5); the
  figure-less start line is unmatched.
- **C3.** Parity: an entry's fixture and its tagged twin give identical STATS and
  MESSAGES CSV; the F10 figures are reproduced on the real files.
- **C4.** The tagged entry reads every line it read before, plus pause and marker
  lines whose level bracket is padded (D1); the tagged corpus parity holds.
- **C5.** UTC time and local time read through the same entry; a padded decoration
  reads as an unpadded one.
- **C6.** CRLF files read as LF files.
- **C7.** Nothing else moves except the registry inventory counts and order.

## Acceptance criteria

Owning harnesses: `tests/validate-format-detection.sh`,
`tests/validate-format-registry.sh`, `tests/validate-log-level-vocabulary.sh`.
Fixtures committed under `tests/fixtures/format-detection/` as `.txt`: a scrubbed
JDK 17 slice and a JDK 21 slice for the time entry, the CRLF specimen's slice with
CRLF kept, and for each other entry the JVM run's output with its tagged twin from
the same run (JDK 21 and JDK 17).

- [x] **AC1 (C1).** Each entry's samples, as a file, bind that entry: `format:` its
      name, every line matched, `event_ledger: yes`. *Assertable:* one scenario per
      entry through `assert_registry_sample_scenario`.
- [x] **AC2 (C2, D5).** On the JDK 17 slice, `matched_lines` equals its
      figure-bearing pause lines plus markers, every start line in
      `unmatched_lines`. *Assertable:* scenario in the detection harness.
- [x] **AC3 (C3).** Per entry, STATS and MESSAGES CSV under `-o -bs 1440` identical
      between the fixture and its tagged twin, the twin binding `java_gc_g1`.
      *Assertable:* scenario run in the harness's own scratch directory.
- [x] **AC4 (C6).** The CRLF fixture binds the time entry and meets AC3.
      *Assertable:* scenario in the detection harness.
- [x] **AC5 (C5).** The UTC fixture binds the time entry and meets AC3; the padded
      level fixture reads every pause and meets AC3. *Assertable:* two scenarios.
- [x] **AC6 (C1, D4).** Tagged and time-only fixtures together give
      `legend: 1=java_gc_g1,2=java_gc_g1_time`; `-lf java_gc_g1_time` pins with
      `selection_basis: pin`; `-lf java_gc_g1` on the time-only fixture matches
      nothing; a mistyped `-lf` lists all five G1 names; `--help formats` states
      each new name as an event ledger that declines, with six categories.
      *Assertable:* `gc-tagless-legend`, `format-pin` extended, and one
      `check_help_states_levels` per name in the vocabulary harness.
- [x] **AC7 (C7).** `entries`, `scanned_entries`, `scan_slots`, `static_order` and
      the scan sub-section's `entries` move by four, each new entry with no
      ancestors; the registry record's section contracts move in the same commit.
      *Assertable:* `inventory`, `structure`, `scan-telemetry`.
- [x] **AC8 (C4, D1).** The `java-gc-g1` scenario passes; a tagged fixture with a
      padded `[info ]` on its pause lines reads every pause; the tagged corpus
      measurement (3,865,527 of 4,943,052 lines, same kinds and sums) is re-run at
      the gate and recorded under *Implementation*. *Assertable:* scenario plus
      recorded run.
- [x] **AC9.** No ` at <file> line <N>` on stderr in any scenario. *Assertable:*
      `tests/lib/runtime-warnings.sh`.
- [x] **AC10 (C3).** Rendered on the provided files: the issue's 76,956-line file,
      the JDK 21 file with Pause Full and the CRLF specimen give the F10 figures
      (lines included 6,070; Young 2,039, Remark 2,015, Cleanup 2,015, Using G1 1;
      39.5 s) with `java_gc_g1_time` in the legend; the whole provided set reads
      155,713 records on deployment A and 79,380 on B. *Unassertable, visual:*
      looked at once, recorded under *Implementation* without paths.

## Gate

The scan sub gains four slots, which a line of no known format also tries; a new
entry costs above the scan floor only on lines carrying its own decoration
(scratch micro-measure: 629 ns on a time-only phase line against a 227 ns floor).
Full harness suite plus the `single-day-access-log-standard` before/after
benchmark, the before captured on the base commit (D6: nothing GC-specific). No
`-V` section or key changes. Release note: *Read G1 GC logs written without the
level-and-tags decoration: time only, with uptime, with level, with process id.*

## Implementation

Built on branch `656-gc-tagless-decorations`, on release/0.18.6 at `62128de`
(which carries #655, read Apache mod_jk connector logs).

### What was built

- **`format_registry_specs()` in `ltl`.** Four entries declared directly after
  `java_gc_g1` (D8): `mt6t` `java_gc_g1_time` (match type 29), `mt6tu`
  `java_gc_g1_time_uptime` (30), `mt6tl` `java_gc_g1_time_level` (31), `mt6tp`
  `java_gc_g1_time_pid` (32); 23 to 28 are held by the connector-format entries
  of #655 (read Apache mod_jk connector logs) on the same release. Each pattern
  is the time bracket, the entry's own bracket (`\[\d+\.\d{3}s *\]`,
  `\[info *\]`, `\[\d+ *\]`, or none), a space, an
  optional `GC(n) `, then a branch-reset group: a pause kind with an optional cause
  and the mandatory heap transition and pause time, or `To-space exhausted` or
  `Using G1` with nothing after. The branch reset keeps the tagged entry's seven
  captures in its order, so the field map, the `gc_heap_delta` transform, the
  time contract, the six declared categories, `event_ledger => 1` and
  `classification => 'none'` are the tagged entry's. No filename evidence, no
  family, no ancestors (D4, D9).
- **Self-validation samples.** Seven per entry (eight for the process-id entry),
  from the JVM runs of F11 and F14: a Young pause with a cause, a Young pause with
  the JDK 21 ` (Evacuation Failure)` suffix, Remark, Cleanup, Full (compaction, or
  `System.gc()`), `To-space exhausted` (a real JDK 17 line), `Using G1`; UTC lines
  in the time entry; three padded `[info ]` lines in the level entry, all real
  JDK 17 lines; the thread-id form in the process-id entry. A thread id padded on a
  record line was not produced by either run (the JVM thread writing records holds
  the widest id), so the process-id entry's padded sample applies the JVM's padding
  rule to a real line: the one composed sample.
- **The tagged entry (D1 as amended).** `\[info\]` became `\[info\s*\]`, as the
  tag bracket already was, with a seventh sample: a real JDK 17 `[info ][gc ...]`
  Full pause. Nothing else in the entry moved.
- **User documentation.** `docs/usage.md` § Log formats and classification names
  the five G1 formats and the one-record-per-pause reading. `--help formats` lists
  the four new names from the registry.
- **Records trued up.** `features/log-format-registry.md`: the `-V format-registry`
  and `-V format-detection / scan` section contracts carry the new counts, and a
  section records the four entries. `features/382-gc-log-g1-format-coverage.md`
  points here.

### Fixtures

Sixteen `.txt` files under `tests/fixtures/format-detection/`, listed with their
source and purpose in `manifest.tsv`, every one cut from the JVM runs of F14
(JDK 17 lines 1-150 and 840-905; JDK 21 lines 1-100 and 150-262; the debug-enabled
JDK 17 outputs' first 240 lines). Each tag-less slice has the tagged slice of the
same run and line range as its twin. The acceptance criteria's fixture list named
a scrubbed JDK 17 slice and a slice of the CRLF specimen, both from field logs; no
field log is committed. The JDK 17 time-only fixture is the JVM's JDK 17 output, and
the CRLF fixture is the JDK 21 time-only slice with CR LF line endings, as the JVM
writes them on Windows, pinned byte for byte by `.gitattributes`. The real JDK 17
field file and the real CRLF specimen are read in the rendered check (AC10).

### Acceptance criteria, as verified

Each scenario was run alone with `--scenario` on this branch; every capture was
clean of runtime warnings.

- **AC1.** `validate-format-detection.sh` scenarios `java-gc-g1-time`,
  `java-gc-g1-time-uptime`, `java-gc-g1-time-level`, `java-gc-g1-time-pid`: each
  feeds the entry's samples and asserts `format:` its name, its match type, every
  line matched (7, 7, 7, 8), the whole-file sample matched, `event_ledger: yes`.
  7 passed each.
- **AC2.** Scenario `gc-tagless-start-lines`: the harness counts the JDK 17 slice
  independently (14 pause lines with the figure, 3 markers, 15 start lines, 216
  lines) and asserts `matched_lines: 17` and `unmatched_lines: 199`. 3 passed.
  Proven to fail by making the figure optional in a scratch copy: both counts
  failed, and the parity scenario failed on the two time-only pairs.
- **AC3.** Scenario `gc-tagless-parity`: nine pairs (time, uptime, level, process
  id, thread id on JDK 17; time, uptime, level, process id on JDK 21), each run
  with `-o -bs 1440` in a directory the scenario owns. Per pair: the fixture binds
  its entry, the twin binds `java_gc_g1`, STATS and MESSAGES CSV are byte-identical,
  and the MESSAGES CSV carries pause rows. 45 passed.
- **AC4.** Scenario `gc-tagless-crlf`: the fixture's every line ends in CR LF (the
  check failed on an LF copy), it binds `java_gc_g1_time`, and its CSV equals the
  JDK 21 tagged twin's. 6 passed.
- **AC5.** Scenario `gc-tagless-utc`: the UTC fixture binds `java_gc_g1_time` and
  matches its UTC tagged twin, 5 passed. Scenario `gc-tagless-level-padded`: the
  fixture carries `[info ]` pause lines, reads all 10 records and markers, and
  matches its padded tagged twin, 7 passed.
- **AC6.** Scenario `gc-tagless-legend`: the JDK 21 tagged slice then the JDK 17
  time-only slice give `legend: 1=java_gc_g1,2=java_gc_g1_time`. Scenario
  `format-pin`, extended: `-lf java_gc_g1_time` binds with `selection_basis: pin`;
  `-lf java_gc_g1` on the time-only slice gives `matched_lines: 0`; `-lf
  java_gc_g1_tim` exits non-zero listing `java_gc_g1, java_gc_g1_time,
  java_gc_g1_time_level, java_gc_g1_time_pid, java_gc_g1_time_uptime`. 21 passed
  (the connector pins included).
  `validate-log-level-vocabulary.sh` scenario `declared-levels-in-help`: per new
  name, the row states the six pause kinds and begins `event ledger. declines to
  classify`. 19 passed (the connector rows included); the row check failed when a scratch copy declared the
  process-id entry not a ledger.
- **AC7.** `validate-format-registry.sh` scenario `inventory`: `entries: 31`,
  `scanned_entries: 29`, `scan_slots: 28` (the six connector entries of #655
  included), and one `entry:` line per new entry in its own group, 18 passed.
  Scenario `structure`: the `static_order` with the four new slots after `mt6` and
  an empty ancestor set for `mt6` and the four new slots, 16 passed. Detection
  scenario `scan-telemetry`: `entries: 28`, 22 passed.
- **AC8.** Scenario `java-gc-g1` (now seven samples, the padded one included), 7
  passed. Scenario `gc-tagged-padded-level`: the padded tagged slice binds
  `java_gc_g1` and reads all 10 records and markers, 3 passed; it failed against a
  scratch copy with the level bracket unpadded. On the base commit the same slice
  reads 0 lines, as does F12's 472-line output, which now reads its 18. Tagged
  corpus, measured on this branch: the 46 tagged G1 files bind `java_gc_g1` and
  read 3,865,527 of 4,943,052 lines, the figure of F5; a scratch pass of the old and
  new tagged patterns over the same files writes byte-identical (timestamp, kind,
  cause, heap from, heap to, heap size, duration) tuple streams, so kinds and sums
  are unchanged (Young 2,791,229, Remark 536,951, Cleanup 536,950, Full 346,
  To-space exhausted 5, Using G1 46; 41,356,228 ms). The measured list holds 50
  files: the 46 tagged files, the CRLF specimen and three files carrying no unified
  G1 line. Over it the uptime, level and process-id rules admit 0 lines and the
  time rule admits only the CRLF specimen's 82 records. To be re-run at the gate.
- **AC9.** Every scenario above runs the runtime-warning check on each capture;
  none reported a warning.
- **AC10.** Rendered at width 200 with one 30-day bucket on the provided field
  logs, and compared with the tagged twins of the specification phase under
  `-o -bs 43200`: the issue's 76,956-line JDK 17 file reads 6,070 lines included,
  Pause Young 2,039, Pause Remark 2,015, Pause Cleanup 2,015, Using G1 1, 39.5 s,
  P50 / P95 / P99 5 / 20 / 24 ms, legend `1 java_gc_g1_time`; the JDK 21 file with
  a Full pause reads 6,619 lines, Young 2,803, Full 1, Remark 1,907, Cleanup 1,907,
  Using G1 1, 3.2 minutes; the CRLF specimen reads 82 lines, Young 65, Remark 8,
  Cleanup 8, Using G1 1, 8.6 s, 81 / 271 / 511 ms; the JDK 17 file with
  `To-space exhausted` reads 1,020. All four give STATS and MESSAGES CSV
  byte-identical to their twins'. The whole provided set read in one run per
  deployment: deployment A 155,713 records over 40 files, deployment B 79,380 over
  10, every file `java_gc_g1_time`.

### Harness changes

`tests/validate-format-detection.sh`: scenarios `java-gc-g1-time`,
`java-gc-g1-time-uptime`, `java-gc-g1-time-level`, `java-gc-g1-time-pid`,
`gc-tagless-start-lines`, `gc-tagless-parity`, `gc-tagless-crlf`,
`gc-tagless-utc`, `gc-tagless-level-padded`, `gc-tagged-padded-level`,
`gc-tagless-legend`; `java-gc-g1` gains the padded sample; `format-pin` gains the
G1 pins; `scan-telemetry` asserts 28 slots. `tests/validate-format-registry.sh`:
`inventory` and `structure` carry the new counts, entries, order and ancestors.
`tests/validate-log-level-vocabulary.sh`: `declared-levels-in-help` states each new
name's categories and posture, through a new row check. No `-V` section or key
changed.
