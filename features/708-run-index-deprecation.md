# Feature: Deprecate the run index (`ltl-index.csv`)

## GitHub Issue

[#708](https://github.com/gregeva/logtimeline/issues/708)

## What this is for

Every default run pays for the run index: about a fifth of the run time on a
day of web-server access log (`features/index-file.md` § Run shape and
measured cost). This research looks for whoever gets something back for that
cost, inside the tool, outside it, and in the open issues. The deprecation is
specified from what it finds.

The research below was done on `release/0.19.0` at the commit that closes the
read-loop run-constant work (#620), the code the cost was measured on.

## Findings in brief

- **Nothing outside the tool reads the index.** The only external consumers in
  the repository are machinery that removes it, reports it, or keeps it out of
  test runs.
- **Inside the tool, one thing changes output: the heatmap's range.** A fresh
  index entry seeds the heatmap's minimum and maximum before the read. When the
  stored bounds equal what the run would find, the seed changes nothing. When
  they differ, the heatmap is drawn on the wrong range. Two such cases are
  reproduced below, both on an unchanged file. The seed saves no work: the
  read still tracks the minimum and maximum on every value.
- **Every other read-back result goes only to the `-V` read-back section and
  its drift check.** Line counts, match counts, means, read rate, memory and
  processing time are written on every run and read by nothing.
- **No open issue needs the index as it is.** The issues that name it ask
  for a cold probe of the files (in the architect's own requirements), live
  measurement, or knowledge the index does not hold (units).
- **One locked decision names the index:** the unit-knowledge precedence of
  the format registry places "index read-back" third. The index has never
  recorded a unit, so that rung is empty today.

## 1. Actual use

### Inside the tool

What `read_index_file()` produces, and where each part goes:

| Read back | Consumer | Effect on what the user sees |
|---|---|---|
| Duration, bytes and count minimum and maximum, aggregated across files | `$heatmap_min` / `$heatmap_max`, only under `-hm duration\|bytes\|count`, only when every input file has a fresh entry at the same tier, and for a filtered run only from an entry with the same filters | The heatmap's column boundaries and axis labels (`calculate_heatmap_buckets()` and the display-anchored boundary calculation, both at finalize). None when the stored bounds equal the live ones; a wrong axis when they do not (§ 3) |
| The same bounds, plus first and last timestamp and their precision | `detect_index_drift()` | Only the `drift_detected` lines of `-V` |
| Lookup tier, freshness, matched row date, every seed value | `emit_index_readback_verbose()` | Only the `=== INDEX READ-BACK ===` section of `-V` |
| `line_count`, `match_count`, the three means, `read_rate`, `memory_used`, `processing_time` | nothing | none |

`heatmap_value_observed()` reads `defined $heatmap_min`, so a seeded run also
reports the heatmap's metric as observed before any line is read.

The seed does not speed anything up. The per-value minimum and maximum
comparison in the read loop runs whether or not it was seeded, and the
histogram and heatmap partitions resize online, so no structure is sized from
the seed. The index read-back's own record states this as a non-goal
(`features/179-index-read-back.md` § Explicit non-goals). The release note that
shipped the read-back says the opposite ("Re-running ltl against files it has
already analyzed is now faster … skipping the initial bound-discovery scan",
v0.14.5). No scan is skipped.

The population-selection signature (`serialize_filters()`) is shared with the
aggregate export's provenance (`features/503-yaml-aggregate-export.md` R4),
which calls it directly. The export does not read the index.

### Outside the tool

Every reference in the repository outside `ltl`, by what it does with the index:

| Reader | What it does with the index |
|---|---|
| `tests/validate-index-read-back.sh`, `tests/fixtures/regenerate-index-readback-fixtures.sh` | Test the read-back itself, from a generated index fixture |
| `tests/validate-csv-input.sh`, `validate-timestamp-precision.sh`, `validate-outcome-criteria.sh`, `validate-option-resolution.sh`, `validate-screenshot-capture.sh` | Assert what the index file contains, or that it is created or removed |
| 46 of 49 harnesses (274 occurrences of `-ni`) | Switch it off: without `-ni` a run reads and rewrites the working directory's index, which on a developer's checkout was the dominant cost of a small run (about 0.4 s a run against a 2,000-row index, `tests/HARNESS-DESIGN.md` § Invocation coherence) and adds a row nobody asked for |
| `build/capture-screenshots.pl` | Removes an index the recipe runs created in a named folder |
| `build/check-root-clean.sh`, `tests/cleanup-test-artifacts.sh`, `.gitignore` | Report, delete or ignore the index left in the repository root |
| `docs/usage.md`, `--help` | The `-ni, --no-index` row |

No reader uses its contents. A person opening the file to see "their log files
at a glance" (one of the motivations the index's original record gives) cannot
be confirmed or ruled out from the repository; it is the one use that would
stop silently.

The index also has costs beyond run time, each with its own record:

- It is written into whatever directory the tool runs in, so it lands in
  repositories and screenshot folders (`features/547-standing-detection-of-a-dirty-repository-root.md`,
  `features/598-screenshot-capture.md`).
- A glob such as `ltl *` reads it back as an input log. The decision there was to
  accept this, with the architect's words: "the index has no bearing on the
  overall performance of ltl" (`features/639-own-artifacts-as-input.md` D1).
  One reported user-defined-metric warning came only from the index being read
  as CSV input (`features/629-udm-custom-regex-defects.md`).
- When the working directory is not writable, it goes to the system temp
  directory with absolute paths, one index shared by every directory.

## 2. What the current implementation requires

Without the index, a run differs from today's in these ways, and no others:

| Surface | With the index | Without it |
|---|---|---|
| Heatmap range on a repeat run | Seeded from the last run's stored bounds | Always the range of this run's values, as on a first run today |
| `ltl-index.csv` in the working directory | Created or rewritten on every run | Not written |
| `-V` | Carries `=== INDEX READ-BACK ===` | Section gone |
| `-ni, --no-index` | Switches the above off | No effect; subject to the deprecated-option removal (#630, remove deprecated options once each notice has carried a release) |
| Run time | The per-line accumulation, twice per matched line, about a fifth of a default access-log run | Same as `-ni` today |

Nothing else in the tool reads `%index_file_data`, `%index_preseed` or
`%index_aggregated`.

## 3. Defects found in the read-back

Both were reproduced on 2026-10-12 against the committed synthetic Tomcat
access fixture of eight requests over six minutes (sizes 512 and 513, one `-`
size, one zero-byte response; durations 0 to 100 ms), copied into an empty
directory as `f.txt`, run from that directory with
`ltl --disable-progress -V -bs 1 …`.

**The bytes heatmap's range changes on the second run of an unchanged file.**
The index counts a zero-byte response as a bytes observation, so its bytes
minimum is 0. The heatmap only takes values above zero. The seeded 0 is
raised to 1 at finalize, below the smallest value the heatmap holds.

| Run | `heatmap_preseed_min` | Heatmap axis |
|---|---|---|
| `-hm bytes`, no index in the directory | 64 (live) | `64 B … 103.5 B … 174.1 B … 292.9 B … 513 B` |
| `-hm bytes` again, same file, same options | 0 (seeded) | `1 B … 4.2 B … 20.1 B … 95.6 B … 513 B` |

The same mechanism applies to `-hm duration` on any log whose duration minimum
is 0 but whose smallest positive duration is above 1. On this fixture the
smallest positive duration is 1 ms, so its duration axis does not move.

**An option outside the filter signature carries one run's range into the
next.** The signature holds only the filters. `-du` (and anything else that
changes the parsed values without filtering) is not in it, so a run after a
run with different units is seeded with the other run's bounds. Drift
detection only reports bounds the live values *exceed*, so it stays silent.

| Run | Heatmap axis |
|---|---|
| `-hm duration -du us` in a directory with no index | `1us … 3us … 9us … 29us … 100us` |
| `-hm duration -du us` after a `-hm duration` run in the same directory | `1ms … 2.9ms … 9.2ms … 28.9ms … 100ms`, `drift_detected: no` |

**The whole-file entry is not refreshed while the file is unchanged.**
`write_index_file()` keeps the existing `file` row as it is when the file's
modification time is unchanged, so a whole-file entry keeps the bounds of
whichever run first wrote it, with that run's options, until it expires after
90 days. The read-back's record says drift at the whole-file level is refreshed
by the end-of-run write (`features/179-index-read-back.md` § Drift refresh). For
an unchanged file it is not. An unfiltered run reads the unfiltered `selection`
row first (rewritten on every run), not the `file` row the read-back record
calls its canonical tier, which is why this rarely shows.

## 4. What future issues require

| Issue | What it names the index for | What it actually needs | Needs the index? |
|---|---|---|---|
| #2 (maximum memory ceiling and default auto-detection) | Named as built on the index in `features/index-file.md` § Related Issues | A live budget tracked as the run consumes memory; its body and feature doc name no index input | No |
| #44 (source-file heuristics for automatic memory and time optimisations) | "Depends on #179 — heuristics need readable index data", added to the body on 2026-05-10, during the read-back specification | The architect's stated requirements (2026-02-02) ask for a function that investigates the input files: count, sizes, time ranges from first and last line, an estimated line count, a read-speed test. A cold probe, which the detection sample (`sample_file_for_detection()`: front, middle and end of each file) already partly reads | No. A cache of a probe's result is an optimisation the issue can choose later, on a probe whose cost is measured |
| #23 (core parsing architecture on the format registry) | Index read-back's "remaining value": timestamp-range and precision hints to detection, and prior-run unit knowledge | Detection now samples each file before its first line; precision is resolved per run. Units come from `-du` or the format; the index stores no unit | No |
| #658 (record whether a format's timestamp marks a request's start or end) | "Record the result per file in the index and the export" | A per-file result in the export; the index is one of two named places | No; the export is the other named place |
| #618 (one declaration per CSV column) | Lists the index's writer and reader as consumers of the declaration | Nothing from the index; the index is one of the surfaces it would cover | No; its scope shrinks |
| #386 (default analysis precision per format) | Lists "index bounds" among the consumers of the sub-second value | Nothing from the index | No; one consumer fewer |

The three issues the read-back record names as consumers of the seed
(#34 two-pass streaming, #41 heatmap and histogram binning alignment, #51
highlight-data memory) are closed, superseded by the online-resizing bin
counters.

## 5. Records a deprecation trues up

- `features/log-format-registry.md` **D18** (unit scope boundary, locked):
  knowledge precedence "`-du` override → format-carried unit → index read-back
  (#179) → sample-based auto-detection (#17)". A deprecation removes the third
  rung. That rung has never held a value.
- `features/log-format-registry.md` § risk 8 (index drift correctness) and the
  #179 row of its dependency table.
- `features/index-file.md` § Related Issues (names #2, #34, #41, #44 as
  built on it).
- `features/179-index-read-back.md` § Related issues and § Drift refresh.
- `features/639-own-artifacts-as-input.md` D1 (the index read back as input
  is accepted).
- The bodies of #23 and #44 (the read-back as a dependency).
- `tests/HARNESS-DESIGN.md` § Invocation coherence (`-ni` on every harness).

## 6. Why the index existed

The architect's account (2026-10-12): the index was built for the heatmap and
the histogram, to establish the boundaries of the bin-counter bucket sizes up
front on a read, without having to process all the lines first. The histograms
as now implemented do not need this: the counts are captured without the
boundaries known up front, and the minimum and maximum are captured during the
read so they are known before drawing. The goal that drove the index turned out
not to be necessary.

What brings the deprecation forward is the measured cost of the per-file
structures the index needs (about a fifth of a default access-log run), paid on
every run for something no one uses, and the index files it leaves in every
directory the tool runs in.

## Decisions

Made by the architect on 2026-10-12, from the findings above.

- **D1 — The deprecation is silent at run time.** No notice, warning or other
  indication is printed. The index works under the covers; the user is not
  aware of it and does not need to be.
- **D2 — The index is off by default.** A default run behaves as a `-ni` run
  does today: it neither reads nor writes `ltl-index.csv`, and does none of the
  per-line work that feeds it.
- **D3 — A new command-line option turns the index on.** No option to do so
  exists today. It restores today's default behaviour: read the index at
  startup, accumulate, write it at the end. It is `-idx, --index`.
- **D7 — The file heuristics issue (#44) no longer depends on the index.** Its
  file investigation is superseded, for the most part, by the per-file pre-read
  sampling pass (`sample_file_for_detection()`), the scaffolding for determining
  such things from the outset rather than on a second execution.
- **D8 — `-ni, --no-index` stays accepted as a silent no-op.** It changes
  nothing and prints nothing, so a run with it is a default run. It is removed
  with the index (#710). A consequence: `-idx -ni` is an `-idx` run. Nothing
  about how `-ni` is handled changes: what it did explicitly, a default run now
  does implicitly, and the options line under the timeline still echoes it as
  typed.
- **D9 — `-ni` is hidden.** It is no longer listed in `--help` or
  `docs/usage.md`; it is still accepted (D8).

## Acceptance criteria

Agreed by the architect on 2026-10-12. A default run of this build is today's `-ni`
run; `-idx` is today's default run.

| # | Condition and observable outcome | State | Verified by |
|---|---|---|---|
| AC1 | A default run in a directory without an index leaves no `ltl-index.csv` and no `.ltl-index.*.tmp` behind | assertable | `tests/validate-index-read-back.sh`, new scenario |
| AC2 | A default run in a directory holding an index leaves it byte-identical with its modification time unchanged, and `-V index-read-back` reports `index_used: no` and `lookup: none` for every file | assertable | `tests/validate-index-read-back.sh`, new scenario |
| AC3 | A default run's output equals a `-ni` run of the base build: terminal output, STATS and MESSAGES CSVs, the aggregate export, and every `-V` section except timing and memory | assertable | diff of base and branch builds on a filtered and an unfiltered run, during development and at the gate |
| AC4 | A default run does none of the per-line index work: its time on the access-log benchmark is within noise of the base build's `-ni` run, and faster than the base build's default run | assertable | before/after benchmark, `single-day-access-log-standard` |
| AC5 | `-idx`/`--index` reads and writes the index as the base build's default run does: every existing read-back scenario passes with `-idx` added, and the index it writes equals the base build's | assertable | `tests/validate-index-read-back.sh`, existing scenarios with `-idx`; the other harnesses that read an index file get `-idx` |
| AC6 | `-ni` is a no-op: a `-ni` run equals a default run (output apart from the echoed command-line options line, which repeats `-ni` as typed; stderr; files left behind), and an `-idx -ni` run equals an `-idx` run | assertable | `tests/validate-index-read-back.sh`, new scenario |
| AC7 | Nothing about the index is printed at run time: stderr of a default run and of a `-ni` run in a directory holding an index carries no line about it | assertable | the scenarios of AC2 and AC6 |
| AC8 | `--help` and `docs/usage.md` carry an `-idx, --index` row and no `-ni` row, and agree | assertable | `tests/validate-help-content.sh` |
| AC9 | The release notes carry the two bullets of D4 and nothing else about the index | unassertable by a harness | read at the release-note step |
- **D4 — The release notes carry the deprecation.** One bullet states that the
  index is deprecated; one states that it is now off by default and is turned
  on with the new option (by both its forms). These are the only user-facing
  statements of the deprecation.
- **D5 — Removal is a separate issue, labelled `not planned`.** It removes the
  index code from the tool and completes the deprecation. It is blocked by
  this issue.
- **D6 — The parsing-architecture issue (#23) no longer counts on the index.**
  Its relationship to the index read-back is trued up to say the index is not
  used.

## Records searched

`./process/find-records.sh --issues -ni --no-index -idx --index ltl-index.csv
read_index_file write_index_file index-read-back`, run 2026-10-12 on
`release/0.19.0` at `af8a002`. Each record found, and what was done with it:

| Records | Disposition |
|---|---|
| `features/index-file.md`, `features/179-index-read-back.md`, `features/log-format-registry.md` | Read; trued up (status line, related issues, D18, D49, risk 8) |
| `features/547-standing-detection-of-a-dirty-repository-root.md`, `598-screenshot-capture.md`, `629-udm-custom-regex-defects.md`, `639-own-artifacts-as-input.md`, `620-read-loop-run-constant-hoisting.md` | Read where they name the index; they describe it as written on every run. A note at the head of each points here |
| `features/616-gated-mean-derivation.md` | Read where it names the index (D17, D24: zero-byte responses counted; bytes heatmap pre-seeded). A note at its head records that this applies only under `-idx`, and the repeat-run axis defect of § 3 |
| `docs/usage.md`, `docs/process/screenshots.md`, `tests/HARNESS-DESIGN.md` | Read; trued up |
| `releases/v0.19.0.md` | Read: six bullets about the index in this unreleased version (lines naming #616, #525 and #620). Raised with the architect at the release-notes step |
| `releases/v0.14.0.md`, `v0.14.5.md`, `v0.15.0.md`, `v0.17.0.md`, `v0.18.0.md` | Dismissed: released notes, not edited |
| `features/503-yaml-aggregate-export.md` | Read: the export takes the filter signature from `serialize_filters()`, not from the index; unaffected |
| `features/273`, `342` (both), `432`, `447`, `455`, `525`, `561`, `615`, `640`; `docs/architecture-patterns.md` | Dismissed: they record the index's columns, formatting or code as it was audited; the code is unchanged under `-idx` |
| `features/180`, `58`, `446`, `457` | Dismissed: they place `read_index_file()` / `write_index_file()` in the pipeline; the calls remain, gated |
| `features/187`, `395`, `396`, `418`, `426`, `444`, `445`, `456`, `458`, `463`, `472`, `520`, `545`, `546`, `566`, `567`, `580`, `597`, `605`, `608`, `609`, `611`, `613`, `617`, `619`, `638`, `653`, `656`, `user-defined-metrics.md`, `209`, `312`; `docs/test-logs.md` | Dismissed: they pass `-ni` in recorded invocations, cite read-back harness counts, or name `index-read-back` among `-V` sections; `-ni` still runs (D8) |
| Issues #23, #44 | Read; trued up (D6, D7) |
| Issues #386 (default analysis precision per format), #642 (`-udm` number parsing), #678 (all-zero user-defined-metric heatmap) | Read: #386 lists the index bounds as a consumer of the sub-second value, one fewer under the deprecation; #642 and #678 pass `-ni` in their reproductions, which still runs |
| Issues #97, #115, #218, #258, #370, #372, #387, #426, #469, #60, #618, #622, #648, #658, #687, #709 | Dismissed: their bodies hold none of the terms as written; the finder matched them loosely |

## Implementation record

- `ltl`: a new `$index_enabled`, set by `-idx, --index`, gates the read
  (`read_index_file()`), the per-line capture (`$index_capture_demand`) and the
  write (`write_index_file()`). `-ni, --no-index` keeps its GetOptions entry and
  its `$no_index` scalar, read by nothing, and is marked hidden. The `--help`
  and `docs/usage.md` rows are replaced by the `-idx, --index` row.
- `tests/validate-index-read-back.sh`: every existing scenario runs with `-idx`
  (AC5); three scenarios are new: `default-writes-no-index` (AC1),
  `default-leaves-index-untouched` (AC2, AC7) and `no-index-is-noop` (AC6,
  AC7). Against the base build the assertions that separate the two builds
  fail: the index written, the index rewritten, the index read
  (`index_used: yes`), `-idx` unknown.
- The harnesses that read an index file pass `-idx` on the runs whose index
  they read (`validate-csv-input.sh`, `validate-timestamp-precision.sh`,
  `validate-outcome-criteria.sh`, `validate-option-resolution.sh`,
  `validate-screenshot-capture.sh`), as does
  `tests/fixtures/regenerate-index-readback-fixtures.sh`.
- AC3, measured 2026-10-12 on the 5,000-line Tomcat access-log slice with
  `-o -V -hm -hg`, unfiltered and with `-dmin 50 -i GET`: the base build with
  `-ni` against this build's default run. The STATS and MESSAGES CSVs are
  identical; the terminal output, `-V` and the aggregate export differ only in
  timing, memory, the output file names, and `-ni` where the base run was given
  it (the `no_index` runtime-config line and the echoed options).
- AC4, measured 2026-10-12, one run each, `single-day-access-log-standard`
  (761,698 lines), both builds from worktrees side by side:

  | Comparison | Total | Change |
  |---|---|---|
  | base default → this build's default | 7.8 s → 6.1 s | −22.8 % |
  | base with `-ni` → this build's default | 6.1 s → 6.1 s | +0.1 % (+4 ms) |
  | `single-day-access-log-heatmap`, base default → this build's default | 9.0 s → 7.0 s | −22.6 % |

  Peak memory moved by less than 1 % in each comparison.
