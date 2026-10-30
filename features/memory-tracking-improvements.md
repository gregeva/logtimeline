# Feature: Memory Tracking Improvements

**Issue:** #45
**Branch:** `45-memory-tracking-improvements`
**Status:** Complete

## Overview

Improve memory tracking to provide accurate, low-overhead measurements with structural breakdown showing where memory is consumed.

## Implementation Summary

### Default Behavior
- RSS (Resident Set Size) high-water mark is always captured and displayed as MAXIMUM MEMORY USED in the summary table
- Measurement occurs after each major processing phase using `measure_memory_structures()`

### With `-mem` Flag
- Additionally displays structural breakdown showing memory usage by data structure
- Uses `Devel::Size` to measure individual structures
- Shows percentage breakdown relative to total measured structures

### Key Changes
1. Replaced scattered `get_memory_usage()` calls with centralized `measure_memory_structures()` function
2. High-water mark tracking ensures peak values are captured even when structures are later cleared
3. Measurement points after: `read_and_process_logs()`, `initialize_empty_time_windows()`, `calculate_all_statistics()`, `calculate_heatmap_buckets()`, `calculate_histogram_buckets()`

### Data Structures Tracked
- `%log_occurrences` - Count tallies across time buckets
- `%log_analysis` - Time bucket statistics (including durations array)
- `%log_messages` - Message groupings
- `%log_stats` - Statistical calculations
- `%log_threadpools` - Threadpool data
- `%threadpool_activity` - Threadpool activity
- `%log_userdefinedmetrics` - User-defined metrics
- `%heatmap_data` / `%heatmap_data_hl` - Heatmap bucket counts
- `%heatmap_raw` / `%heatmap_raw_hl` - Raw heatmap values (when heatmap enabled)
- `%histogram_values` - Histogram values

## Output Format

### Default (no flags)
```
  TOTAL TIME                        2.1 sec
  MAXIMUM MEMORY USED               83.0 MB
  ─────────────────────────────────────────
```

### With `-mem` flag
```
  TOTAL TIME                        2.1 sec
  MAXIMUM MEMORY USED               83.0 MB
    log_messages         (15%)      12.2 MB
    log_analysis         (10%)       8.5 MB
    log_stats            (<1%)       5.4 kB
    log_occurrences      (<1%)       2.4 kB
    unattributed         (75%)      62.3 MB
  ─────────────────────────────────────────
```

**Notes:**
- Only structures with >= 1KB are displayed (empty structures are hidden); the `unattributed` row is always shown
- Percentages are shares of MAXIMUM MEMORY USED (peak RSS), so the displayed rows plus `unattributed` reconcile to the peak (Issue #356)
- `unattributed` = peak RSS minus the sum of ALL structure high-water marks (including hidden sub-1KB ones), floored at zero; it aggregates interpreter baseline, allocator-retained transients, and allocation slack — see the Memory Diagnostic Method section for why this cannot be attributed per structure
- Each structure's high-water mark may be captured at different measurement points, which is why the subtraction is floored rather than exact

## Performance Results

### Before Implementation
**Test file: `localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (277MB, 1,430,678 lines)**

| Mode | Total Time | CALCULATE STATISTICS | SCALE DATA TO TERMINAL |
|------|------------|---------------------|------------------------|
| Without `-mem` | 16.5 sec | 465 msec | 655 usec |
| With `-mem` | 17.1 sec | 712 msec | 140 msec |

Overhead: ~600ms (3.6% of total runtime)

### After Implementation

| Mode | Total Time | CALCULATE STATISTICS | SCALE DATA TO TERMINAL |
|------|------------|---------------------|------------------------|
| Without `-mem` | 16.3 sec | 455 msec | 619 usec |
| With `-mem` | 16.3 sec | 457 msec | 587 usec |

Overhead: **~0ms** (within measurement noise)

**Improvement:** ~600ms overhead eliminated

## Files Modified

- `ltl` - Main implementation
  - Added `%memory_high_water_marks` global hash
  - Added `measure_memory_structures()` function
  - Updated `print_summary_table()` for structural breakdown output
  - Renamed `$track_memory` to `$show_memory`
- `build/generate-cpanfile.sh` - Devel::Size dependency auto-detected

## Progress

- [x] Benchmark current implementation
- [x] Prototype Devel::Size approach
- [x] Implementation
  - [x] Add `%memory_high_water_marks` global hash
  - [x] Add `measure_memory_structures()` function with high-water mark tracking
  - [x] Add measurement calls after key subroutines in MAIN
  - [x] Remove scattered `get_memory_usage()` calls from loops
  - [x] Add structural breakdown to summary table output
  - [x] Always display RSS, structural breakdown only with `-mem`
- [x] Testing
- [x] Documentation

## References

- [Devel::Size on CPAN](https://metacpan.org/pod/Devel::Size)

## Issue #356 Specification — Peak-RSS Coherence

**Status: Implemented** (branch `356-mem-untracked-rss-residual`).

The #356 investigation decomposed the untracked peak-RSS residual into named categories (findings comment on the issue). The dominant term — an O(`-n`) transient range-list burst in the output subs — is a behavioral defect fixed separately under #362. This specification covers the remaining remedy: making every user-facing memory surface coherent against peak RSS.

### S1. Final measurement point after the output phase

`measure_memory_structures()` is additionally called (a) at the entry to the summary-table rendering, so the displayed MAXIMUM MEMORY USED includes the normalize/bar-graph/CSV phase, and (b) after the output stages (`print_message_summary()` / `print_threadpool_summary()`, before exit), which keeps the recorded peak honest for the full process lifetime and surfaces through the `-mem debug` end-of-run line. The displayed value structurally cannot include allocations made by the output stages that print after it; with the #362 clamp in place that blind spot is the message/threadpool row rendering only (~KBs at dev scale). Before this change the last measurement preceded the entire output phase and MAXIMUM MEMORY USED under-reported the true process peak by 34% at dev scale (316 MB reported vs 478 MB actual).

### S2. `%message_key_order` joins the named-structure map

Added to `named_structure_sizes()`. It is O(total keys × key length) under large `-n` (9.0 MB at 43,820 keys) and was the only named store above 1 MB missing from the map.

### S3. The `-mem` terminal breakdown becomes a full account of MAXIMUM MEMORY USED

- Percentages become relative to `rss_peak` (previously: relative to the total of measured structures).
- A final `unattributed` row is displayed: `max(0, rss_peak − Σ per-structure HWMs)` with its percentage, so the displayed rows plus `unattributed` reconcile to MAXIMUM MEMORY USED.
- Documented semantics: Σ of high-water marks is a sum of maxima captured at different instants, so the row is a visibility surface — it aggregates interpreter baseline, allocator-retained transients, and allocation slack — not a precise gauge. `-mem debug` (S4) is the per-instant instrument.
- The `benchmark-data` `-V` section gains a `MEMORY	unattributed` row. HARNESS-DESIGN obligations apply: `benchmark-data` is owned by `features/memory-baseline-profiling.md`, whose section contract must be updated in the same commit, and the `tests/baseline/` consumers must be verified tolerant of the additive row.

### S4. `-mem debug` diagnostic mode

- Grammar: `-mem` takes an optional literal operand `debug`; bare `-mem` is unchanged. Only the literal `debug` is recognized — any other following token must remain a file argument (`ltl -mem access.log` keeps meaning `-mem` plus a file; the operand must not swallow it).
- Behavior: everything `-mem` does, plus TSV diagnostic lines on STDERR:
  - a full decomposition line (`rss`, `named_sum`, `unattributed`, top structures) at each phase boundary — startup, after read, after bucket initialization, after grouping, after statistics, after heatmap/histogram, after normalize, after each output stage, end;
  - RSS-only samples inside the hot loops: read loop every 75,000 lines; per-message-key statistics and output loops every 10,000 keys. Cadence is deliberately coarse for Windows, where each RSS read is a syscall (see the #143 history) — a debug run must not multiply that cost.
- `Devel::Size` walks happen only at phase boundaries (bounded count per run), never inside loops.
- Help/docs parity: `print_help()` and `docs/usage.md` updated in the same commit.

### S5. Single resolution surface

`named_structure_sizes()` (extracted during the investigation) is the only place the named map is defined; `measure_memory_structures()` and the `-mem debug` sampler both consume it. The `MEMORY_FINAL` emission in the benchmark block still lists structures ad hoc — converge it onto the same surface when touched. Converged under #709 drop 4: `MEMORY_FINAL` carries one row per store of the map, and the map itself is `named_structures()`, a name and a reference per store, which `named_structure_sizes()` walks.

### Non-goals

- Per-structure attribution of allocator-retained churn: impossible from an in-process structure walk; quantified as ~76 B/line (bin-vs-raw delta, consistent from 240k to 8M lines).
- The O(`-n`) slice fix — #362.

## Issue #709: unmeasured stores and a peak that misses working memory

**Status:** in progress since 2026-10-27. The specification and prototype
stages are complete (2026-10-28), and delivery plan drops 4 and 5 are
delivered on the issue branch, ahead of drops 2 and 3 by the architect's
order. #757 (a Linux-specific variant of the cpanfile), which blocked
delivery plan drop 2, is delivered (PR #763, merged as 9cd76712 on
2026-10-30): `BSD::Resource` goes to the macOS cpanfile alone, and #709 keeps
the reading and its fallback (the architect, 2026-10-28). The issue branch is
rebased onto `release/0.20.0` at 6dadde32, which carries #757's commits
(2026-10-30, § Resuming). Filed 2026-10-12,
found while reading the third `all`-tier benchmark round of 0.19.0.
- Locked (§ Decisions): D1, the reported peak is the operating system's kept
  high-water mark; D2, macOS reads it from `getrusage` through
  `BSD::Resource`; D3, under `-mem` grouping's checkpoints and windows walk
  only the `consolidation_*` stores.
- The prototype stage is complete (2026-10-28).
- The acceptance criteria are agreed, criterion 11's bounds written from P1,
  and the delivery plan confirmed.

### Resuming

**Done, the specification stage (2026-10-27 to 2026-10-28):**
- the contracts, confirmed;
- the records sweep;
- the premise re-measured on the release branch;
- the store inventory, with the 38 candidates listed;
- the peak each platform keeps, with the `BSD::Resource` probe;
- D1 and D2;
- the acceptance criteria;
- the prototype plan;
- the delivery plan and its edges.

**Done, the prototype stage (2026-10-28):** the issue branch, the version
stamp and the `before` benchmark; P1's instruments and its trace runs (§ P1
before the timed runs); the qualification of its inputs; its timed runs and
the transient-stores arm (§ P1 results); D3; criterion 11's bounds.

**Done, delivery plan drops 4 and 5 (2026-10-28),** on the issue branch, no
PR yet: the 38 inventory stores in the map and `MEMORY_FINAL` converged
(§ Drop 4, `5f6c9f9c`); grouping's walks per D3 (§ Drop 5, `3eda9545`);
criterion 11 checked under one pinned hash seed (`637a1280`), after the
finding that the message store's size follows the per-process hash seed.

**Done, the rebase (2026-10-30).** The issue branch was rebased from
`b24b8589` onto `release/0.20.0` at 6dadde32, which carries #757's commits
(the generator that routes `BSD::Resource` to `build/cpanfile.macos` alone)
and #759's (the duration precision rendering). No conflict; each of the 11
commits carries the same patch as before. This record cites the rebased
commits; the issue's comments before the rebase cite the earlier ones:

| Commit | Before the rebase | After |
|---|---|---|
| version stamp `0.20.0-709` | `3e4cbf91` | `41e80935` |
| P1 instruments | `33bec43f` | `8d249340` |
| P1 qualification | `e77d7581` | `a1aa5356` |
| P1 timed runner | `5806fe33` | `0234bf29` |
| P1 timed runs: results and findings | `c80a55b0` | `9d886aeb` |
| P1 transient-stores arm | `d4929677` | `75f66efb` |
| P1 transient-stores arm: results and findings | `47376618` | `bbf5990b` |
| P1 every-call reference | `1122a104` | `2c678ab6` |
| drop 4 | `bb4511ac` | `5f6c9f9c` |
| drop 5 | `68385228` | `3eda9545` |
| criterion 11 under one pinned hash seed | `8cba52b3` | `637a1280` |

P1, drops 4 and 5 and criterion 11 were measured on code based on
`b24b8589`.

The `before` benchmark was captured again on the new base, because `ltl`
changed by 10 commits between the two bases: the four tests of criterion 13,
six rounds from the release worktree, the machine's load average near 2
throughout and no other `ltl` running. Against the fastest round (5), the
reading stage ran +29.2 %, +4.1 %, +7.2 %, +1.2 % and +4.6 % in rounds 1 to
4 and 6. Only rounds 4 and 5 are as close as the first base's three rounds,
which came within 1.2 % of each other. A median over these six would sit
about 4 % above the quiet rounds, enough to hide a regression of that size,
so they are not used as the `before`. Against the first base, round 5
differed by −1.5 % to +0.2 % per test, within run-to-run variation, as
#759's own gate measured on the standard case.

**The `before` is captured again at 6dadde32 once the machine is quiet**
(the architect, 2026-10-30, who says when it is): the four tests of
criterion 13, three rounds, from a worktree checked out at 6dadde32 beside
the issue worktree. Drop 2 onward proceed meanwhile, and no other `ltl` runs
while it is captured. The `after` at drop 6 is compared with it.

**Captured 2026-10-30,** on the architect's word that the machine was quiet:
`709-before-6dadde32-quiet-1.tsv` to `-3.tsv`, from
`.claude/worktrees/709-base-6dadde32`, interleaved rounds, the load average
1.2 to 1.8, no other `ltl` running. Each test's total, median and range:

| Test | Median | Range |
|---|---|---|
| `single-day-access-log-standard` | 5.105 s | 5.088 to 5.194 s |
| `single-day-access-log-top25-consolidate` | 6.723 s | 6.623 to 6.806 s |
| `single-day-access-log-heatmap-histogram-consolidate` | 9.355 s | 9.159 to 9.625 s |
| `humungous-log-uniqueness-top25-consolidate` | 3.550 s | 3.409 to 3.878 s |

The rounds' reading stages came within 3.1 % of each other; round 1 of the
last test alone ran 9 % above its median.

**Done, delivery plan drop 2 (2026-10-30),** on the issue branch
(§ Drop 2, `83f88bce`): the kept peak at each reporting moment, the macOS
fallback and its notice, `build/cpanfile.macos` requiring `BSD::Resource`;
criteria 3, 4, 6, 12 and 14 met, and criterion 1 on macOS.

**Next:**
- Drop 2's runs that cannot be made on this host (§ Drop 2, *Not run on this
  host*): criterion 1 on the Windows development host and on Linux, and
  criterion 7's other half, the packaged macOS binary reporting the kept
  peak. How each runs is the architect's to direct.
- Drop 3, readings between steps only under `-mem`.
- After drop 3, which changes `measure_memory_structures()` (drop 2 left it
  unchanged), re-run criterion 11:
  `prototype/709-memory-peak/criterion-11.sh check ltl <work dir>`, from the
  issue worktree. Its reference marks (`results/criterion-11-reference.tsv`)
  were made with this host's Perl 5.44. On another Perl, regenerate them first
  with `criterion-11.sh reference`, from drop 4's code (`git show
  5f6c9f9c:ltl`).
- Then drop 6:
  - restore `$version_number` to `0.20.0`;
  - run the `after` benchmark (criterion 13) from the issue worktree, three
    interleaved rounds on a quiet machine, against the `before` captured at
    6dadde32 (§ Done, the rebase);
  - run the completion gate;
  - open the one PR.

**Kept outside the repository, on the first macOS development host:**
- `tests/baseline/results/709-before-1.tsv` to `-3.tsv` (at `b24b8589`, the
  first base) and `709-before-6dadde32-1.tsv` to `-6.tsv` (at 6dadde32),
  untracked, in the `release/0.20.0` worktree
  (`.claude/worktrees/release-0.20.0`): the evidence of § Done, the rebase,
  superseded by the capture at 6dadde32 on a quiet machine, and deleted at
  close-out.
- The `before`: `tests/baseline/results/709-before-6dadde32-quiet-1.tsv` to
  `-3.tsv`, untracked, in `.claude/worktrees/709-base-6dadde32`, a detached
  worktree at 6dadde32 kept until close-out.
- The issue worktree, `.claude/worktrees/709-memory-peak-and-unmeasured-stores`.

**Where it can block or move hosts:**
- Criterion 1 in drop 2 also runs on the Windows development host and in a
  Linux container.

**The specification stage kept nothing outside the repository.** Its scratch
copies of `ltl`, and the scratch library `BSD::Resource` was built into, were
session scratch. P1 builds its copies from the 38 stores listed under § Store
inventory.

### Contract of the surfaces touched (confirmed by the architect, 2026-10-27)

What the work serves: the analyst reads MAXIMUM MEMORY USED to know what a
run needed; the developer reads the `-mem` breakdown and the benchmark's
memory rows to attribute a memory change to the store that made it.

| Surface | Contract | Record |
|---|---|---|
| MAXIMUM MEMORY USED, the run summary | "RSS (Resident Set Size) high-water mark is always captured and displayed as MAXIMUM MEMORY USED in the summary table", on every run, with or without `-mem` | § Default Behavior; restated in the direction below: "the one memory figure every run reports" |
| The `-mem` breakdown | A row per named store of at least 1 KB, as a share of the peak, then an `unattributed` row: the peak less the sum of every store's high-water mark, floored at zero, so the rows reconcile to the peak | § Output Format, the notes; § Issue #356 Specification, S3 |
| `-V benchmark-data`, `MEMORY` rows | `rss_peak` whenever `-V` is active; under `-mem` a row per store's high-water mark, then `MEMORY unattributed`, a reserved name in the row namespace | `features/memory-baseline-profiling.md` DD-03 |
| `-V benchmark-data`, `MEMORY_FINAL` rows | Under `-mem`, one row per store of the map, measured through `named_structure_sizes()` as the block prints, in name order, under the `MEMORY` rows' names (#709 drop 4) | § Issue #356 Specification, S5 |
| `-V memory-usage` | A `site` line per caller of the memory reading, with its count and time; a new reading site joins the list in its fixed order | § `-V memory-usage` section contract |
| The aggregate export, `max_memory_used` | The MAXIMUM MEMORY USED string, as the run summary prints it | `features/503-yaml-aggregate-export.md` D19 |
| The run index, `memory_used` | "Peak memory during processing (bytes)" on a selection entry; the index itself is removed by #710 (remove the run index) | `features/index-file.md` |
| `-mem` in `--help` and `docs/usage.md` | "Display memory consumption statistics after processing completes, including memory that cannot be attributed to any tracked structure" | `docs/usage.md`, the `-mem` row |
| `-mem release`, hidden (added from the records sweep) | "by default the message rows keep their data; the release is behind a hidden `-mem release`": each message row's durations are freed after their last use. Being `-mem`, it also turns on the structure walks | `features/680-statistics-duration-copies.md` § 5.0 |

### Records sweep (2026-10-27)

`./process/find-records.sh --issues` over `-mem`, `-mem debug`, `MAXIMUM
MEMORY USED`, `rss_peak`, `unattributed`, `memory-usage`, `benchmark-data`,
`get_memory_usage`, `measure_memory_structures`, `named_structure_sizes`,
`histogram_values_hl`, `max_memory_used` and `memory_used` listed 95 records
and 41 issues. Every matching passage was read.

**Records that bear on this work:**

| Record | What it settles or constrains |
|---|---|
| `features/680-statistics-duration-copies.md` § 5.0 | A hidden third `-mem` operand, `release`, frees each message row's durations after its last use. Like any `-mem`, it also turns on the structure walks. It is a surface of `-mem` that the contract table above does not list. § 4.8 had already measured the peak gap: "`-mem`'s own `rss_peak` samples between steps and misses the spike inside statistics (969 MB against 1,124 MB on the same base run)". |
| `features/180-named-pipeline-stages.md` | "Hard constraint: the `measure_memory_structures()` / `memory_debug_decomposition()` instrumentation checkpoints woven between steps keep their positions — their labels are observable `-mem`/debug output." Any decision that moves a reading meets this line. |
| `features/457-summary-section-at-end-of-output.md` D2 | The reading that feeds MAXIMUM MEMORY USED sits immediately before the summary render. |
| `features/616-gated-mean-derivation.md`, *The peak memory the run reports* | `$reported_max_memory_usage` is taken once, after the reading before the summary. The summary row, its memory shares and the aggregate export read it; "the index row and `-V benchmark-data` keep the lifetime peak". This is why the run index and the summary read different variables, by the architect's direction. |
| `features/memory-baseline-profiling.md` DD-03a | `benchmark-data` reads the reading counters when its block prints, during the render, so it can trail the section's totals. Its `rss_peak` is read at the same moment, before the render's last two readings. |
| `features/520-inert-sort-bytes-aggregate-demand.md` | "the structure walk raises RSS": memory there was measured from a separate `-mem` run per arm, apart from the timing. An earlier observation that `-mem` itself moves the peak. |
| `features/472-highlight-bin-counter-telemetry.md` | `-mem` reports high-water marks, not live residency. |
| `features/fuzzy-message-consolidation.md`, the decision on memory visibility | "All new data structures introduced by consolidation … are included in the `-mem` memory summary output". A rule of store coverage, kept by the consolidation stores in the map. #171 (transient consolidation structures tracked) and #346 (the message-statistics counter store missing from the map) are earlier cases of a store missing from the map. |
| `features/2-memory-ceiling-progressive-eviction.md` E3; #2 (memory ceiling, open) | The planned ceiling controller steers on RSS read during the run, and RSS exceeds `Devel::Size` by 12.6 to 40.6 % per store. It would consume whatever in-run reading this work settles. No gate either way: each can reach a clean implementation without the other. |
| `features/log-format-registry.md` D62 | `format_scan_subs` is a compile-boundary RSS delta, not a structure walk. It joins the high-water marks as a running total. |
| `features/621-generated-read-loop-body.md` | The read loop's `-mem debug` sample carries a `#@when` gate marker. The packaged runtime adds 14 to 15 MB of unattributed memory. |
| `features/614-operand-settlement.md` § 4.5 | `-mem` settles its operands (`debug`, the hidden `release`) through `settle_optional_operand()`. Any other word is a file argument. |
| `features/412-notice-surfaces.md` | `get_memory_usage()` raises the `memory-unreadable` notice once per run on Windows. |
| `docs/architecture-patterns.md` | Consumption sites of the run-scoped activation flag (`$memory_readings_active`), the `-V` telemetry sections (`emit_memory_usage_verbose`), the raw-store release table (`-mem release`) and the named pipeline stages. A new reading site or flag is recorded there. |
| `features/189-bin-counter-primitives-implementation-readiness-audit.md` B13 | Catalogues `%histogram_values_hl` as a highlight twin to migrate with its base array. It does not note its absence from the `-mem` map. |
| `features/528-record-lexical-retained-representation.md` D5; `features/561-retained-durations-as-numbers.md` | Harness assertions read the exact `MEMORY` rows of `-V benchmark-data`, `tests/validate-format-registry.sh` among them. Any row added or renamed reaches them. |
| #354 (large message rows move to the bin data model, open); #372 (paired-event correlation, open); `features/60-metric-visibility-demand-map.md` (open) | Use `-mem` as their measuring instrument. None sets a contract on it. |

**Dismissed, with the reason:**

- *They use the memory rows as evidence of their own change and set no
  contract on them:* `features/` 34, 189-histogram-bin-counter-primitives,
  213, 225, 273, 303, 305, 342 (both docs), 358, 395, 412-notice-surfaces-research,
  417, 420, the three 426 docs, 444, 445, 446, 453, 458, 459, 460, 476, 478, 524,
  525, 564, 567, 580, 605, 609, 615, 619, 620, 640, 665, 674, 747, 750,
  `bin-counter-accuracy-and-observability.md`, `duration-statistics.md`,
  `user-defined-metrics.md`, `nytprof-profiling-workflow.md`; `features/` 58,
  179 and 209 (other `benchmark-data` rows).
- *They set how the memory rows are formatted, which this work does not
  change:* `features/608-byte-unit-ladder.md`,
  `features/617-width-to-format-rule.md`, `docs/percentage-presentation.md`,
  `features/269-output-ordering-audit.md` F11 (the tie order of the breakdown,
  now broken by name).
- *They hold process or images:* `docs/process/workflow.md`,
  `docs/process/screenshots.md`, `features/598-screenshot-capture.md`,
  `docs/toolchain-guidance.md`.
- *They record the run index's `memory_used` as read by nothing:*
  `features/708-run-index-deprecation.md`.
- *Release notes,* which are history: v0.10.2, v0.10.4, v0.13.0, v0.14.3, v0.14.4,
  v0.15.0, v0.16.0, v0.17.0, v0.20.0.
- *Closed issues,* whose record is a feature doc above or whose fix shipped:
  #46, #50, #51, #131, #146, #171, #172, #180, #226, #289 (its highlight
  counter store was retired under #472), #346, #356, #358, #362, #400, #413,
  #415, #416, #417, #453, #455 (its record has no memory passage), #472, #503,
  #561, #614, #680. #729 (process, tests and build, open) mentions `-mem` in
  passing.

### The architect's direction (2026-10-12)

- **The aim is a correct peak, not full attribution.** Attributing a routine's
  working memory to a named store is not a goal.
- **No measurement with an iterative cost.** Nothing is read per line, per row
  or per call of a routine that runs many times. A reading taken once per run,
  or a few times, costs nothing that matters.
- **Two aims, two expectations.** The size of each store matters only under
  `-mem`. The overall peak RSS is the one memory figure every run reports, with
  or without `-mem`. So where a routine holds a very large local variable, a
  reading inside it at the right moment is relevant to every run. No single
  condition covers both cases.
- **Where the reading goes.** A reading just before a routine returns is too
  late, because deletions usually happen at a routine's end. The high-water
  reading is taken before a deletion. A deletion made one item at a time inside
  a loop cannot be read there, so the reading goes in front of the loop.
- **Inside a loop, at most once.** One option raised: a single conditional
  reading at the moment of highest pressure. The evaluation of that condition
  runs on every pass and is not free, so it is placed with care and its
  overhead is measured with a before/after benchmark. Another option raised: a
  compiled routine that includes the condition or omits it, chosen by the
  run's parameters, noted as possibly over-complicated.
- **Prototype first.** A prototype compares the options on timing overhead,
  complexity, simplicity and readability before anything is built
  (`prototype/README.md`). The focus is the cases where a local copy is known
  to grow very large, read while it exists.

### Findings

All measured on macOS, one run per case unless stated. The step-by-step
figures come from a scratch copy of `ltl` that adds `-mem debug` decomposition
samples inside `group_similar_messages()` and `calculate_all_statistics()` and
adds every input-sized global store to the named map; the tracked `ltl` was
not changed.

**The highlighted raw histogram values are not measured.** On a one-day web
application access log carrying execution time in the duration field (148 MB,
761,698 lines), with `-V benchmark-data -mem`:

| Options | Histogram raw values | Highlighted raw values (scratch copy) | Unattributed, as shipped | Unattributed, scratch copy |
|---|---|---|---|---|
| `-hg -hgdm raw` | 68.1 MB | 0 | 76.8 MB | 77.1 MB |
| `-hg -hgdm raw -h HTTP` (every line highlighted) | 68.1 MB | 68.1 MB | 132.6 MB | 73.4 MB |
| `-hg -hgdm raw -h POST` | 68.1 MB | 59.0 MB | 123.0 MB | 69.9 MB |
| `-hg -h HTTP` (default data model) | 0 | 0 | 51.0 MB | 48.7 MB |

The highlighted copy costs about 94 bytes a value, as the unhighlighted one
does, and grows with the highlighted population, which can be the whole input.
It has been missing from the named map since at least 0.18.0.

**No other global store is a meaningful gap.** Across the eleven benchmark
scenarios on one month of one server's web application access logs (1.5 GB,
28 files, `-bs 1440`), no unmeasured global store reached 256 KB. That covers
the per-message maps that streaming consolidation keeps, plus the per-group,
per-file, index, verbose-output and telemetry stores.

**Working memory held inside a routine is the larger gap.** Same input and
scenarios. These are the steps where RSS rose while no measured store grew:

| Step | Scenarios | RSS rise outside every measured store |
|---|---|---|
| Reading the files | every scenario with a message table | +106 to +147 MB (+12 and +13 MB with `-n 0`) |
| Time-bucket statistics | every scenario without a heatmap | RSS +23 to +59 MB while the 242 MB time-bucket store is freed |
| Ranking every message row on an available value | standard, top25, histogram | +89 MB |
| | heatmap, heatmap-histogram | +145 MB |
| The walk over every row to rank on a calculated statistic | sort-p99 | +109 MB |
| | sort-skewness | +42 MB |
| Selecting the displayed rows after that walk | sort-p99 | +49 MB |
| Statistics of the displayed rows | top25-consolidate | +197 MB |
| | heatmap-histogram-consolidate | +223 MB |

The displayed rows' rise is the sorted copy of each row's durations, the
behaviour accepted under #680 (statistics over raw values copy each array;
`features/680-statistics-duration-copies.md` § 5.0). In the grouped runs the
largest displayed row is a consolidated group of 3,751,230 durations. Copying
and sorting that many integer values costs 144 MB in a standalone Perl
measurement.

**Message grouping's own working memory is measured.** The final grouping pass
raises RSS by about 80 MB. Its window index (50 MB high-water) and trigram cache
(26 MB) are named stores, measured inside each window before they are freed,
so their high-water marks already cover that rise. Its skip decision and full
key sort add about 1 MB.

**The reported peak missed the true peak by 95 MB in one scenario.** In
heatmap-histogram-consolidate, RSS read 733 MB at the end of the displayed
rows' statistics, inside the routine. After the routine returned it read
638 MB, which is the peak `-mem` would report; `time -l` reports 733 MB. In the
other ten scenarios the reported peak was within 1 MB of the operating
system's: the allocator kept the pages, so the peak was right and only its
attribution was missing. On the one-day log, with every line highlighted, the
reported peak was 252.7 MB against 276.3 MB from the operating system.

**Where measurement happens today.** Only the grouping checkpoint
(`run_consolidation_checkpoint()`) and the final pass's window
(`process_final_pass_window()`) call `measure_memory_structures()` from inside,
before freeing their working structures. Every other reading is taken in the
pipeline steps after the work routine has returned (`pipeline_parse`,
`pipeline_accumulate`, `pipeline_finalize`, `pipeline_render`). No reading
follows `group_similar_messages()`: the next is after statistics.

**Routines that free large amounts of memory while they run:**

| Routine | What it frees | Where the direction above would place the reading |
|---|---|---|
| `calculate_all_statistics()` | each time bucket's durations, one bucket at a time (the store fell from 244 MB to under 4 MB); per-bucket sessions and thread pools; each displayed row's sorted copy; its local ranking lists when each category's pass ends | in front of the bucket loop (also the missing after-grouping point); before the ranking lists go out of scope |
| `group_similar_messages()` | the streaming consolidation maps, cleared at the start of the final pass; the key-sort maps; rows absorbed into groups, deleted one at a time | before the clear; before the key-sort maps are freed; in front of the absorbing loop |

A copy allocated and freed inside a loop, such as each displayed row's sorted
durations, is neither a deletion before a loop nor one at a routine's end, so
neither placement reads it. The largest row and the largest bucket are known
before their loops start, from each one's observation count.

**"Unattributed" mixes instants.** It is peak RSS minus the sum of every named
store's high-water mark, and those marks come from different moments. The
time-bucket store (242 MB) peaks during reading and is freed during statistics,
before the run's peak, yet it is still subtracted. On the one-server month
top25-consolidate case the figure read 348, 43 and 196 MB across three
benchmark rounds of the same code; three identical runs peaked at 932, 936 and
969 MB, each equal to `time -l`.

**An RSS reading against a size walk.** A standalone Perl script copied and
sorted 3,751,230 non-integer values. Reading the process's RSS the way `ltl`
does on macOS (launching `ps`) took 8.8 ms (mean of 20); the process grew
276 MB. `Devel::Size::total_size` of the copy took 198 ms and reported 229 MB:
22 times the cost, and 47 MB short of what the copy cost the process. The Linux
reading is a file read and was not measured.

**The structure walks under `-mem` are an iterative cost (handed forward from
#146, 2026-10-15).** Each grouping checkpoint and each final-pass window calls
`measure_memory_structures()`, which under `-mem` walks every named store with
`Devel::Size`; the checkpoints multiply with the input and each walk grows with
the stores. On one server's web application access log (one day, 33 MB, and
three days, 65 MB; `-g -V benchmark-data`, Windows, three runs), `-mem` added
8% and then 17% to the run, all of it in the reading and grouping stages, and a
scratch probe put the walks there: 14 checkpoint walks of 0.77 to 0.81 s and 6
final-pass walks of 0.61 to 0.64 s at one day, 17 of 1.66 s and 6 of 2.05 s at
three days. The process-memory readings over the same runs cost 26 to 28 ms.
Measured in § Issue #146 › Drop 2. This conflicts with the direction above (no
measurement with an iterative cost) and belongs with the placement it sets.

### Premise re-measured on the release branch (2026-10-27)

The code has moved since the findings above. #146 changed the reading and
added `-V memory-usage`, so the issue's cases were run again on
`release/0.20.0` at `6290d95a`, on macOS, one run each, one after another.
Each ran from a scratch directory with the benchmark's own options
(`--disable-progress -V benchmark-data,memory-usage --terminal-width 200`, and
`-mem` where stated) under `/usr/bin/time -l` for the operating system's peak.
The benchmark's `-V benchmark-data` is used rather than bare `-V`, which makes
grouping keep member keys (§ Memory Diagnostic Method).

**The highlighted raw histogram values are still unmeasured.** On the one-day
web application access log carrying execution time in the duration field
(148 MB, 761,698 lines), with `-mem`:

| Options | `histogram_values` | `unattributed` | `rss_peak` | OS peak |
|---|---|---|---|---|
| `-hg -hgdm raw` | 71.4 MB | 83.4 MB | 209.5 MB | 209.6 MB |
| `-hg -hgdm raw -h HTTP` (every line highlighted) | 71.4 MB | 143.1 MB | 269.0 MB | 293.7 MB |
| `-hg -hgdm raw -h POST` | 71.4 MB | 132.3 MB | 258.2 MB | 278.8 MB |
| `-hg -h HTTP` (default data model) | 0 | 52.8 MB | 107.6 MB | 107.8 MB |

With every line highlighted, `unattributed` rises by 59.7 MB over the
unhighlighted run. `-mem` has no row for the highlighted copy, and
`%histogram_values_hl` is still missing from `named_structure_sizes()`.

**The reported peak falls short of the operating system's in three of the six
cases, with `-mem` and without it:**

| Input and options | With `-mem`: `rss_peak` / OS peak | Short by | Without `-mem`: `rss_peak` / OS peak | Short by |
|---|---|---|---|---|
| one-day log, `-hg -hgdm raw -h HTTP` | 269.0 / 293.7 MB | 24.7 MB | 264.4 / 291.6 MB | 27.2 MB |
| one month of one server's web application access logs (1.5 GB, 28 files), `-bs 1440 -n 25 -g -m uuid` | 860.8 / 1,019.2 MB | 158.4 MB | 852.8 / 1,011.2 MB | 158.4 MB |
| the same month, `-bs 1440 -hm -hg -g -m uuid` | 670.5 / 769.7 MB | 99.3 MB | 764.6 / 764.6 MB | 0 |

- **The structure walks do not cause the gap.** It is the same with `-mem`
  and without it on the first two cases.
- **Where the reclaim falls varies from run to run.** On the third case the
  reading after statistics caught the peak in one run and missed it by 99 MB
  in the other, as § Findings describes.
- **The `-n 25 -g -m uuid` case is new.** In the 0.19.0 rounds its three
  identical runs peaked at 932, 936 and 969 MB, each equal to `time -l`. On
  the release branch the OS peak is 1,011 to 1,019 MB, and the reported peak is
  158 MB below it in both runs.
- **Reading counts are the same with and without `-mem`.** The one-day log
  took 8 readings: 6 at phase boundaries and 2 around the scan-sub compiles.
  The month took 67 and 69: 5 and 7 at phase boundaries, 43 at grouping
  checkpoints, 15 at final-pass windows and 4 around the scan-sub compiles.
- **On macOS each reading launches `ps`.** The 58 grouping readings on the
  month took 0.46 to 0.55 s, and every reading together 0.56 to 0.64 s of a
  90 to 120 s run. The grouping readings grow in number with the input.
- **No run's stderr carries ` at <file> line <N>`.**

**Where the missed peak falls.** Each of the two cases that fell short in both
runs was run once more with `-mem debug`, and its `memory-usage / debug`
records were read:

| Case | OS peak | Highest reading | Readings on either side of the miss | Step between them |
|---|---|---|---|---|
| one-day log, `-hg -hgdm raw -h HTTP` | 293.2 MB | 268.5 MB, after statistics | 268.5 MB after statistics, 266.0 MB after the histogram | `calculate_histogram_buckets()`, with no reading inside it |
| the month, `-bs 1440 -n 25 -g -m uuid` | 1,017.4 MB | 859.0 MB, after statistics | 717.9 MB after the read (its 103 in-loop samples reach 642.7 MB), 793.5 MB after grouping, 859.0 MB after statistics | the final grouping pass or `calculate_all_statistics()` |

On the month, the final pass's window readings stayed at or below 859.0 MB.
No `-mem debug` sample falls inside either step, because the per-key samples
come every 10,000 keys and `-n 25` gives statistics 25 rows. Placing the peak
in one of the two steps needs a step probe on a scratch copy (§ Memory
Diagnostic Method).

### Store inventory (2026-10-27)

**Method.** `ltl` has 255 file-scope hashes and arrays. A scan of every
assignment, increment and push after the declarations found 185 that are
written while the tool runs; 23 of those are in `named_structure_sizes()`.
Most of the rest are option settings, registries, display tables or other
per-run constants. The 38 that could grow with lines, keys, buckets or files
were added to the map of a scratch copy (rows prefixed `x_`). The copy ran
with `-mem --terminal-width 200` under option families the eleven benchmark
scenarios do not reach:
- on the one-day log: bare `-V -n 25 -g -m uuid`;
  `-V benchmark-data -hg -hgdm raw -hm -hmdm raw -mdm raw -h HTTP`;
  `-V benchmark-data -idx`, run twice so the index is written and then read
  back; `-V benchmark-data -n 25 -g -m uuid`;
- on the month: `-V benchmark-data -bs 1440 -n 25 -g -m uuid`.

No run's stderr carries ` at <file> line <N>`.

**The 38 candidates.** These are the scratch copy's stores, by variable. Each
joins `named_structure_sizes()` under its own name (§ Decisions), and
criterion 9 checks for them.
- *Histogram and heatmap:* `%histogram_values_hl`, `%histogram_buckets`,
  `%histogram_buckets_hl`, `%histogram_stats`, `%histogram_stats_hl`,
  `%histogram_boundaries`, `%heatmap_percentiles`.
- *Streaming grouping:* `%consolidation_cat_stats`,
  `%consolidation_category_unmatched_count`,
  `%consolidation_pattern_generation`, `%consolidation_key_generation`,
  `%consolidation_key_checkpoint_count`, `%consolidation_absorption_ema`,
  `%consolidation_streaming_absorbed`, `%consolidation_final_pass_skipped`,
  `%consolidation_cliff_edge`.
- *Files, the run index and format detection:* `@files_processed`,
  `%in_files_matched`, `%index_file_data`, `%index_preseed`,
  `%index_aggregated`, `%format_detection`, `%format_detection_evidence`,
  `%format_detection_sample`, `%timestamp_date_cache`, `%unregistered_levels`,
  `%unregistered_levels_by_file`.
- *Output, telemetry and records:* `@verbose_output`,
  `%verbose_section_buffer`, `%section_rows`, `%category_totals`,
  `@progress_history`, `@notice_records`, `@memory_debug_records`,
  `%bin_counter_telemetry`, `%stats_demand_telemetry`, `%udm_skipped_lines`,
  `%numeric_filter_no_metric`.

**Unmeasured stores of 64 KB or more:**

| Store | Grows with | Filled under | High-water mark |
|---|---|---|---|
| `%histogram_values_hl` | highlighted lines | `-hg` on the raw data model with a highlight | 69.8 MB, the day with every line highlighted |
| `%consolidation_key_generation`, `%consolidation_key_checkpoint_count` | distinct message keys | `-g` | 559 KB each on the day, with or without bare `-V`; 1.28 MB each on the month |
| `@verbose_output` | the verbose sections printed | bare `-V` | 513 KB, the day grouped |
| `%format_detection_evidence`, `%format_detection_sample` | files read | every run | 195 KB and 111 KB, the month's 28 files |
| `%index_file_data` | files read | every run | 69 KB, the month's 28 files |

The other 31 candidates stayed under 64 KB in every run: the other streaming
grouping maps, the per-file and index-read stores, the per-bucket heatmap
percentiles, the histogram's buckets, boundaries and statistics with their
highlight twins, the telemetry and demand stores, the timestamp date cache,
the `-mem debug` records and the notice records. The mapped twin
`heatmap_raw_hl` reads 41.7 MB on the same highlighted run, beside
`heatmap_raw` at 41.7 MB.

Out of the scan's reach:
- *Stores holding compiled code* (`%format_scan_sub_cache`,
  `@format_registry`). A `Devel::Size` walk of these segfaults (§ Memory
  Diagnostic Method), and the `format_scan_subs` compile-boundary figure stands
  for them.
- *Stores declared after `named_structure_sizes()`.* Those are the notice and
  terminal stores, each per notice or per run.

**An observation against finding 5.** § Findings states that no unmeasured
global store reached 256 KB on the month. The two per-key grouping maps reach
1.28 MB each here. The scratch copy's store list behind that finding is not
recorded. Both maps join the named map under this work (§ Decisions), so the
difference no longer bears on it.

**The same case caught its peak in this run.** On the month's
`-n 25 -g -m uuid`, the scratch copy reported 1,018.1 MB against the OS's
1,018.2 MB. The unmodified `ltl` fell 158 MB short in each of its three runs.
The copy's only difference is 38 more structure walks at each reading, which
change when a reading falls against the allocator handing memory back.

### The peak each platform keeps for the process (2026-10-27)

Each operating system keeps the process's own high-water mark. Read once, it
gives the true peak up to the moment of the reading, whatever was freed
before it. For each platform:

| Platform | The kept peak | Its measure | Reached from Perl | One reading | Measured here |
|---|---|---|---|---|---|
| Linux | `VmHWM` in `/proc/self/status` | resident set size, the measure read today | a file read, as `get_memory_usage()` reads `/proc/self/statm` | not measured | no; no Linux host in this stage |
| Windows | `PeakWorkingSetSize`, offset 8 of the `PROCESS_MEMORY_COUNTERS` that `get_memory_usage()` already fills | working set, the measure read today | the same call, another offset | that call: 0.15 to 0.25 ms after the run's first (§ Issue #146, Drop 2) | the field's value is in § Issue #146 › Findings |
| macOS | `ru_maxrss` from `getrusage` | resident set size, the measure read today | not through Homebrew Perl 5.44's own functions: `syscall` is not implemented (`d_syscall='undef'`). Through `BSD::Resource`, a compiled CPAN module not in the project's dependencies: version 1.2911 builds and passes its tests against Perl 5.44, installed into a scratch library only | 1.0 to 1.2 µs | yes, below |
| macOS | `phys_footprint_peak`, printed by `footprint -p <pid>` | physical footprint, not resident set size | launching `footprint` and parsing its output, as the current reading launches `ps` | 25 to 38 ms | yes, below |
| macOS | "Physical footprint (peak)", printed by `vmmap --summary <pid>` | physical footprint | launching `vmmap` | 570 to 590 ms | in a standalone script only |

`ps` on macOS offers `%mem`, `pmem`, `rss` and `vsz`, with no peak. In a
standalone script, memory freed with `undef` stayed resident (`ps` read
481 MB after a 500 MB string was freed), so a toy process cannot show a peak
above the current reading. The `footprint` reading was therefore probed in
`ltl` itself: a scratch copy that calls `footprint -p` once, after the run's
last reading in `pipeline_render()`. It ran under `time -l` on the three cases
that had fallen short, one run each:

| Case | `time -l` maximum resident set size | `time -l` peak memory footprint | `phys_footprint_peak` at the end of the run | `rss_peak`, the phase-boundary readings | `footprint` call |
|---|---|---|---|---|---|
| one-day log, `-hg -hgdm raw -h HTTP` | 291.0 MB | 288.1 MB | 275 MiB (288.4 MB) | 263.8 MB | 25.2 ms |
| the month, `-bs 1440 -n 25 -g -m uuid` | 1,011.5 MB | 1,008.9 MB | 962 MiB (1,008.7 MB) | 1,011.4 MB | 38.3 ms |
| the month, `-bs 1440 -hm -hg -g -m uuid` | 766.3 MB | 763.7 MB | 728 MiB (763.4 MB) | 666.8 MB | 36.0 ms |

- **A single end-of-run reading gives the operating system's own footprint
  peak.** `footprint` prints mebibytes under the label `MB`. Converted, its
  peak matches `time -l`'s peak memory footprint to the mebibyte in all three
  cases.
- **The footprint peak is a different measure from the resident peak.** It
  sat 0.3 to 1.0 % below the resident peak in these runs.
- **The month `-n 25 -g -m uuid` case caught its peak in this run.** It read
  1,011.4 MB against 1,011.5 MB, where the unmodified `ltl` fell 158 MB short
  in each of three runs. The copy differs only after the last reading. So
  whether a phase-boundary reading lands before the memory is handed back
  varies between identical runs.

The resident peak was probed the same way: a scratch copy that, at the same
point, reads `getrusage` through `BSD::Resource` and times 1,000 calls, with
the module loaded from the scratch library. One run each:

| Case | `time -l` maximum resident set size | `ru_maxrss` at the end of the run | `rss_peak`, the phase-boundary readings | `getrusage` call |
|---|---|---|---|---|
| one-day log, `-hg -hgdm raw -h HTTP` | 291,160,064 bytes | 291,160,064 bytes | 263.9 MB | 1.16 µs |
| the month, `-bs 1440 -hm -hg -g -m uuid` | 762,920,960 bytes | 762,920,960 bytes | 762.7 MB | 1.01 µs |

- **`ru_maxrss` read once at the end equals the operating system's resident
  peak to the byte** in both cases, including the one-day case, where the
  phase-boundary readings fell 27.2 MB short.
- **The month case caught its peak in this run** (762.7 against 762.9 MB),
  where it fell 99 MB short in one of the two premise runs.
- **Neither run's stderr carries ` at <file> line <N>`.**

### Decisions

- **D1 (locked 2026-10-27): the reported peak is the high-water mark the
  operating system keeps for the process.** It is read wherever a peak is
  reported (`-V benchmark-data`'s `rss_peak`, MAXIMUM MEMORY USED and the
  aggregate export, the end of the run), in place of the highest of the
  readings taken between steps. It is the only way to the done-when's "true
  peak at no iterative cost" by construction: a peak freed inside a step,
  such as the one inside `calculate_histogram_buckets()` on the one-day log,
  is caught whatever the allocator does before the next reading, and so is the
  month `-n 25 -g -m uuid` case, which fell 158 MB short in three runs and
  caught its peak in two. The alternative, readings placed before deletions
  and in front of loops with one conditional reading inside a loop, cannot be
  shown to catch every peak and adds a test to every pass of each loop it
  instruments; its remaining value would be attribution, which the issue sets
  as a non-goal. Linux reads `VmHWM` and Windows `PeakWorkingSetSize`, the
  same measure as today's reading; how macOS reads it is D2.
  The `-mem` rows still come from the readings between steps.
- **D2 (locked 2026-10-27): macOS reads its peak as the resident high-water
  mark from `getrusage`, through `BSD::Resource`.** The module is loaded on
  macOS only, as `Win32::API` is on Windows only. Declaring it for macOS,
  installing it in macOS setup and carrying it in the macOS binary belong to
  #757 (a Linux-specific variant of the cpanfile; the architect, 2026-10-28). A run
  without the module falls back to the readings' peak and prints the
  `memory-unreadable` notice, as `get_memory_usage()` does today when the
  Windows reading fails. All three platforms then report the same measure,
  and § Default Behavior's "RSS high-water mark" holds. The reading equalled
  `time -l`'s resident peak to the byte in both probe runs, at about 1 µs.
  The alternative, launching `footprint -p`, reports the physical footprint
  (0.3 to 1.0 % below the resident peak in three runs) and takes 25 to 38 ms
  per call, by parsing another tool's text output.
- **D3 (locked 2026-10-28): under `-mem`, each grouping checkpoint and
  final-pass window walks only grouping's 15 `consolidation_*` stores, and the
  phase-boundary walks cover every store.** The checkpoint walk sits in
  `run_consolidation_checkpoint()` and the window walk in
  `process_final_pass_window()`, where they are today; only what they walk
  changes. Chosen from P1 (§ P1 results):
  - *It captures every grouping store* of 1 MB or more within 5 % of a walk
    of every store at every site, on the eight qualified inputs. The stores
    that peak inside grouping are the transient ones: the ID index (up to
    209.0 MB), the key trigrams (up to 96.7 MB), the clusters (up to
    102.8 MB) and the per-key maps. The message store's high-water mark falls
    at a boundary on all eight.
  - *It removes the walks' cost inside grouping.* That cost was the message
    store: on 15 days of one server's access logs grouped without the UUID
    mask, the walks inside grouping took 13.67 s with every store, 0.13 s
    with the transient stores. The run was 39.2 % above the floor with every
    store, 9.1 % with the transient stores.
  - *The alternatives measured:*
    - a walk of grouping's 17 stores, the message store among them, saves
      nothing where the cost is (+31.7 %);
    - a walk only when the keys held or the clusters have grown misses the
      general application log's ID index (111.0 MB read as 59.4 MB);
    - boundary walks alone miss every transient store.

  Before P1, the architect judged a walk at each of the month's 43
  checkpoints acceptable, and left a walk at every window to the prototype.
  What was at stake, measured before P1 on the month `-bs 1440 -n 25 -g -m uuid` (`-mem debug`,
  one run): grouping's stores peak where only the walks inside grouping see
  them. The consolidation clusters reach 221.0 MB against 140.5 MB at the
  after-read walk, the ID index 52.0 MB against under 1 MiB, the key trigrams
  27.6 MB against 1.7 MB. On the two month cases, final grouping took 4.72 s
  and 3.50 s with `-mem` against 1.68 s and 1.45 s without (macOS, one run
  each); the reading stage's difference was within run-to-run variation.
  § Issue #356 Specification S4 already keeps `-mem debug`'s walks out of
  loops.
- **Following from D1 and D2: without `-mem`, no reading is taken between
  steps.** Those readings served only the peak. The phase-boundary readings
  (5 to 7 a run) and the grouping readings (58 on the month, 0.46 to 0.55 s
  of `ps` launches on macOS) are skipped, unless the kept peak cannot be read
  and the run falls back to the readings' peak (D2).
- **Settled by the records, recorded and taken (2026-10-27):**
  - *Every store the inventory found growing with the input joins
    `named_structure_sizes()`*, the 38 candidates, `%histogram_values_hl`
    (69.8 MB on the day with every line highlighted) foremost. The done-when
    names every such store. The breakdown's rule, a row per store of at least
    1 KB (§ Issue #356 Specification S3), shows them: 6 to 12 more rows on the
    inventory's runs. `-V benchmark-data` gains a `MEMORY` row per store.
  - *`unattributed` keeps its definition* (S3): the peak less the sum of every
    store's high-water mark, floored at zero, so the rows still reconcile to
    MAXIMUM MEMORY USED. With D1's peak it now also carries the working memory
    a step frees before the next reading: 24.7 to 158.4 MB on the premise
    cases.
  - *`MEMORY_FINAL` converges onto `named_structure_sizes()`*, per S5
    ("converge it onto the same surface when touched"): this work changes the
    map the hand-kept list would otherwise drift further from.

### Acceptance criteria

Drafted 2026-10-27; agreed by the architect on 2026-10-28. The paths each
invariant covers were enumerated from the code on `release/0.20.0`. Coverage of every
store that grows with the input is not a criterion: the architect set it as
development and troubleshooting guidance, applied with judgement, since no
check covers every store all of the time (2026-10-27). It is recorded in
`docs/architecture-patterns.md` § Named-structure memory map.

- *The peak's consumers:* `print_verbose_output()` (`MEMORY rss_peak`,
  `MEMORY unattributed`), `print_summary_table()` (MAXIMUM MEMORY USED, the
  breakdown's shares and `unattributed`), `write_aggregate_export()`
  (`max_memory_used`), `write_index_file()` (`memory_used`, until #710
  removes the run index).
- *The reading sites,* each a caller of `get_memory_usage()`: `phase_boundary`
  (the pipeline steps), `grouping_checkpoint` (`run_consolidation_checkpoint()`),
  `grouping_final_pass` (`process_final_pass_window()`), `format_scan_compile`,
  `csv_block_compile`, `debug_decomposition`, `debug_sample`, and the new
  kept-peak reading.
- *The stores:* the 38 of § Store inventory.
- *The consumers of the memory output:* `tests/validate-memory-usage.sh`,
  `tests/validate-verbose-content-shape.sh`, `tests/validate-format-registry.sh`
  (`MEMORY format_scan_subs`), `tests/validate-statistics-demand.sh`
  (`MEMORY log_analysis`), `tests/validate-byte-units.sh` (MAXIMUM MEMORY USED
  under `-mem`), `tests/validate-read-path.sh` (its `-mem debug` option set),
  `tests/validate-summary-contribution-bar.sh`,
  `tests/validate-timestamp-precision.sh`, `tests/baseline/compare-results.sh`.
- *The benchmark:* every benchmark run passes `-mem -V benchmark-data`, so the
  kept peak and the walks reach every test.

| # | Condition and observable outcome | Triage | Validation |
|---|---|---|---|
| 1 | On every run, with or without `-mem`, `MEMORY rss_peak` and MAXIMUM MEMORY USED are not above the operating system's peak for the process, and within 1 % below it, including the cases where the readings between steps fell short | assertable | macOS: the three premise cases (the one-day log `-hg -hgdm raw -h HTTP`; the month `-bs 1440 -n 25 -g -m uuid` and `-bs 1440 -hm -hg -g -m uuid`) under `/usr/bin/time -l`, with and without `-mem`. Windows x64: the one-day case, sampled for `PeakWorkingSet64` as in § Issue #146, on the Windows development host. Linux: the one-day case under `/usr/bin/time -v` in a container with the corpus mounted, at the cost of a container run, since no Linux host is at hand. Recorded under Results |
| 2 | The 32-bit Windows branch reads `PeakWorkingSetSize` at offset 8, four bytes wide | unassertable | Strawberry Perl is x64 only; the offset follows from the structure layout (`cb` 4 + `PageFaultCount` 4). Recorded gap |
| 3 | Each consumer of the peak reports the kept peak at its moment: MAXIMUM MEMORY USED and the export's `max_memory_used` carry the same value, `rss_peak` and the index's `memory_used` the lifetime peak, and the breakdown's shares and `unattributed` are computed against it | assertable | A harness scenario reading the four consumers above on one fixture run with `-mem -V benchmark-data -o`, the index written; criterion 1's runs read them at scale |
| 4 | The reported peak is never below a reading the run took: under `-mem debug`, every `rss` in the `memory-usage / debug` records is at or below `rss_peak` | assertable | `tests/validate-memory-usage.sh`, a `-mem debug` scenario; holds on every platform |
| 5 | Without `-mem`, no reading is taken between steps: `-V memory-usage` lists the kept-peak site, once per reporting moment, and under `-V benchmark-data` the compile sites; no `phase_boundary`, `grouping_checkpoint` or `grouping_final_pass` reading | assertable | `tests/validate-memory-usage.sh`, runs without `-mem`: plain, `-g` (checkpoints and windows), a CSV input |
| 6 | On macOS without `BSD::Resource`, the run prints the `memory-unreadable` notice once, reports the readings' peak, and takes the readings between steps | assertable | `tests/validate-memory-usage.sh`, a macOS-only scenario that hides the module through an `@INC` hook given at invocation |
| 7 | Moved to #757 (a Linux-specific variant of the cpanfile) by the architect, 2026-10-28: the packaged macOS binary carries `BSD::Resource` and reports the kept peak. Carrying it is met by #757 (PR #763, its criterion 6). Reporting the kept peak reads this issue's reading and comes back with it | assertable | The macOS binary built from the issue branch with drop 2 in reports the kept peak, without the `memory-unreadable` notice of D2's fallback |
| 8 | Moved to #757 by the architect, 2026-10-28: `build/generate-cpanfile.sh` names `BSD::Resource` for macOS only, in no Linux or Windows cpanfile. Met by #757 (PR #763, its criterion 4) | — | #757 |
| 9 | Every store of § Store inventory is in `named_structure_sizes()`: under `-mem`, `-V benchmark-data` carries a `MEMORY` row for each of the 38, and on the one-day log with `-hg -hgdm raw -h HTTP` the highlighted raw values' row reads about 70 MB | assertable | The row names of one `-mem -V benchmark-data` run against the 38; the premise case for the size |
| 10 | `unattributed` equals the peak less the sum of every store's `MEMORY` row, floored at zero, in both surfaces; `MEMORY_FINAL` carries one row per store of the map, under the `MEMORY` rows' names | assertable | A harness scenario on one `-mem -V benchmark-data` run |
| 11 | Under `-mem`, each grouping checkpoint and final-pass window walks only the 15 `consolidation_*` stores (D3): every grouping store of 1 MB or more reports a `MEMORY` row within 5 % of the every-call reference, and the run on 15 unmasked days is at most 12 % slower in wall clock than the same run without `-mem` (P1: +9.1 %) | assertable (bounds from P1, 2026-10-28) | `prototype/709-memory-peak/criterion-11.sh check <ltl>`: the eight P1 inputs (`candidates.txt`) with `-mem -V benchmark-data`, their rows against `results/criterion-11-reference.tsv`; 15 unmasked days (`-bs 1440 -g`) with and without `-mem`, three runs each under `/usr/bin/time -l`, medians. Every run, and the reference, hashes under one pinned `PERL_HASH_SEED` (the architect, 2026-10-28), since the message store's size follows the hash seed (§ Drop 5, the finding); the checker refuses a run that does not show it |
| 12 | `-V memory-usage` keeps its section contract, with the kept-peak site in its fixed order, and every consumer of the memory output still asserts | assertable | Each consumer listed above |
| 13 | No benchmark test runs slower beyond run-to-run variation | assertable (a measurement, recorded under Results) | Before and after, three runs each, medians with ranges: `single-day-access-log-standard`, and the tests that reach grouping's walks, `single-day-access-log-top25-consolidate`, `single-day-access-log-heatmap-histogram-consolidate` and `humungous-log-uniqueness-top25-consolidate` (the most checkpoints) |
| 14 | No ` at <file> line <N>` on stderr in any run above | assertable | Captured stderr grepped |

### Prototype plan

One question is open after the decisions. It is answered on the issue
branch, under `prototype/709-memory-peak/`, with scratch copies of `ltl` patched
per arm, so each arm keeps the production call structure. Prototype code is not
promoted; its output is a locked decision here and a findings report beside it.

**P1. Grouping's structure walks under `-mem`** (trigger (c), execution
frequency × cost: a walk of every store, once per checkpoint or window; and
criterion 11's bounds, unknown until measured). The arms:

| Arm | What it does |
|---|---|
| floor | `ltl` as tracked, without `-mem` |
| every call | `ltl` as tracked, with `-mem`: a walk at every checkpoint and every final-pass window |
| conditional | A walk at a checkpoint or window only when a cheap count of grouping's stores has grown past its value at the last such walk by a margin. Timed: either count (the keys held or the clusters) at +0 %. The keys held and the clusters alone, at +0 % to +200 %, are replayed over the traces, not timed (§ P1 qualification of inputs and options) |
| boundaries only | No walk inside grouping; the phase-boundary walks only |
| grouping's stores only | A walk at every checkpoint and window that covers only the stores `run_consolidation_checkpoint()` and `process_final_pass_window()` write (the `consolidation_*` stores, including the per-key maps the inventory adds, `log_messages`, and `log_messages_counters`, which a merge deletes from); every store at the phase boundaries |
| transient stores only | Grouping's stores only, without the message store and its counters: a walk at every checkpoint and window of the 15 `consolidation_*` stores; every store at the phase boundaries |

Each arm also times its walks per routine, as § Issue #146's scratch probe did,
so a combination (every checkpoint, the windows conditional or not walked)
is read from the same runs without an arm of its own. A walk inside grouping
covers the whole of `named_structure_sizes()` today, 29 stores, so every arm's
copy carries the 38 stores of § Store inventory in the map, as delivered: the
map's size sets each walk's cost. The grouping's-stores-only arm was added on
2026-10-28, while laying out the delivery plan, when this came to light. The
transient-stores-only arm was added the same day, on the architect's approval,
from § P1 results. It ran in a second set of three rounds, beside the floor and
the every-call arm.

- *Inputs, approved by the architect on 2026-10-28 from § P1 qualification of
  inputs and options,* each for a behaviour at the walk sites:
  - the premise's server of the month folder, from 2026-01-02, at 1, 7 and
    15 days (34.4, 327.2 and 801.9 MB), `-bs 1440 -g -m uuid`: the most walks,
    and the clusters' peak in the final pass;
  - the same days, `-bs 1440 -g`: the walks' cost, the checkpoints' fast path
    and the final-pass skip;
  - the PLM web server access log of one day, `-du us -g -xqs`: the cost on
    another access-log family, with the largest index;
  - the general application log of 85 MB, `-g`: a family carrying no
    duration, where the index peaks while neither count is at a high.

  `prototype/709-memory-peak/candidates.txt` names their files and options.
  Every arm runs with `--disable-progress -V benchmark-data,memory-usage`, and
  `-mem` on every arm but the floor. Bare `-V` is not used: it turns on the
  grouping section, which keeps member keys in every cluster and so changes
  the stores the walks measure. `-n` and `--terminal-width` do not reach
  grouping and are left at their defaults.
- *Measured, three runs per arm and input, interleaved, medians with ranges:*
  total time and the `parse/read_files` and `finalize/group_similar` stages;
  walks per routine and their time; each grouping store's high-water mark
  against the every-call arm's; `time -l`'s resident peak, since the walk
  itself raises it.
- *Weighed with them:* the lines each arm adds, and where its condition lives.
- *Exit:* the arm chosen per routine, locked as a decision here with its
  measured justification; criterion 11's bounds written from it.

**The packaged macOS binary carrying `BSD::Resource` is not a prototype of
#709.** Packaging belongs to #757 (a Linux-specific variant of the cpanfile),
on which #709 depends (the architect, 2026-10-28). Nothing was built or packed
for it.

P1 is on this host. Its timed runs take about 40 minutes in the
background. The architect confirmed this plan on 2026-10-28, and its timed matrix after the qualification of inputs the same day.

### P1 before the timed runs (2026-10-28)

**Started.** The branch `709-memory-peak-and-unmeasured-stores` was cut from
`release/0.20.0` at `b24b8589`, in its own worktree, with `$version_number`
set to `0.20.0-709` (`41e80935` since the rebase). The `before` benchmark ran at `b24b8589`
from the release worktree: the four tests of criterion 13, three interleaved
rounds, in 80 s.

**The instruments,** in `prototype/709-memory-peak/` on the issue branch
(`8d249340`):
- `make-arms.pl` generates every arm from `ltl` by substitutions it counts, so
  a moved base fails. Every arm but the floor carries the 38 stores of
  § Store inventory in the map, and times each walk per reading site.
- `trace.sh` runs a trace arm once per input. At every reading it records the
  site, the keys held for grouping, the clusters, the RSS, the walk's time and
  every store's size.
- `simulate.py` replays the conditional arms over those records. A walk
  changes no store, so which readings an arm takes, and the high-water marks
  they capture, follow exactly from one trace. Only the time needs the timed
  arms.
- Under D1 a reading inside grouping serves only its walk, so an arm that skips
  the walk skips the whole `measure_memory_structures()` call.

**The plan's inputs do not carry the cost handed forward from #146.** One
trace run per input, macOS, every reading walked over the map with the 38
stores:

| Input | Options | Walks inside grouping | Their time | Phase-boundary walks | Run total | Peak RSS |
|---|---|---|---|---|---|---|
| 1 day of the month server | `-bs 1440 -n 25 -g -m uuid` | 16 | 0.09 s | 0.02 s | 2.07 s | 128.5 MB |
| 3 days | same | 16 | 0.14 s | 0.04 s | 3.94 s | 132.7 MB |
| 7 days | same | 23 | 0.78 s | 0.17 s | 16.35 s | 255.2 MB |
| 15 days | same | 39 | 2.86 s | 0.42 s | 42.82 s | 447.6 MB |
| the application log of 286K unique messages | `-bs 60 -n 25 -g -m uuid` | 6 | 0.005 s | 0.002 s | 3.52 s | 58.0 MB |
| 1 day of the month server | `-ni -g`, as #146 measured | 20 | 0.55 s | 0.20 s | 4.33 s | 187.3 MB |
| 3 days | same | 23 | 1.56 s | 0.72 s | 8.10 s | 297.0 MB |
| 7 days | same | 25 | 3.29 s | 1.73 s | 22.93 s | 636.9 MB |

- **#146's case is grouping without the UUID mask.** Its day is the same file
  (168,981 lines). Almost no keys group there, so the message store keeps
  nearly every distinct request: 43.8 MB at 1 day, 319.5 MB at 7 days. Every
  walk covers it.
- **With the mask, the walks cost 0.2 to 8 % of the run.** Without it they
  cost 17 to 28 %. The plan's inputs, the benchmark's `top25-consolidate`
  options, are all masked.
- **The walks inside grouping see stores no boundary walk sees.** On 15
  masked days, the clusters reach 102.8 MB at the last final-pass window and
  read 0.7 MB at the next boundary. The ID index reaches 52.0 to 80.5 MB and
  the key trigrams 27.6 to 40.7 MB at a checkpoint holding about 5,000 keys,
  on every access-log input. At the boundaries both read 0.1 MB or less, apart from the trigrams at
  0.5 to 1.7 MB on the masked days.

**Which readings each conditional count takes, replayed over the eight
traces.** A store counts as captured within 5 % of the every-call arm's
high-water mark, for each grouping store of 1 MB or more:

| Count, margin | Masked inputs | Unmasked inputs |
|---|---|---|
| keys held, +0 % to +200 % | misses the clusters on every access-log input (102.8 → 59.1 MB at 15 days), and the ID index on the unique-messages log (5.9 → 0.6 MB) | captures every store at +0 %, with 2 walks; from +10 %, the ID index 80.5 → 75.9 MB |
| clusters, +0 % and +10 % | captures every store, with 4 to 14 walks | captures every store, with 3 to 5 walks |
| clusters, +25 % and up | misses on some inputs and not others: +25 % misses the clusters on 7 days (41.0 → 16.4 MB) and +50 % does not | misses the ID index (80.5 → 0.6 to 3.2 MB) and the trigrams |
| either count, +0 % | captures every store, with 5 to 15 walks: 1.28 s of 2.86 s at 15 days | captures every store, 1.18 s of 3.29 s at 7 days |
| either count, +10 % | captures every store, with 4 to 6 walks: 0.37 s of 2.86 s at 15 days | captures every store, 0.83 s of 3.29 s at 7 days |

The keys held follow the ID index and trigrams, which peak at a checkpoint.
The clusters grow in the final pass, after the held keys have fallen. Neither
count alone covers both families; either count, firing when one of the two has
grown past its value at the last reading, covers them on these inputs. On the
application logs it does not (§ P1 qualification of inputs and options).

### P1 qualification of inputs and options (2026-10-28)

The inputs above were taken from the plan without checking what they
exercise at the two walk sites; the architect directed that they be
qualified. The walk sites are reached as follows (`ltl` at `b24b8589`):

- **A checkpoint fires** when a category holds 5,000 keys no pattern matched
  (`consolidation_fire_checkpoints()`, `$consolidation_trigger`), for every
  group of the category holding two or more.
- **It walks only if it runs its pass.** From its third checkpoint, a group
  whose absorption average says every survivor would be evicted takes the
  fast path in `run_consolidation_checkpoint()`, which returns before the walk.
- **The final pass walks once per window** of up to 1,000 keys
  (`process_final_pass_window()`). A group handing forward 20,000 keys or more
  after streaming absorbed 5 % of its keys or less is skipped
  (`$consolidation_skip_min_keys`, `$consolidation_skip_absorption`): it has
  no windows.
- **A walk covers every store in the map at that moment,** not only
  grouping's: during the read, the time-bucket store's durations and any
  heatmap or histogram store too.
- **`-n` and `--terminal-width` do not reach grouping:** its only reference
  to the width is the progress line, and `-g` cuts every key at 350
  characters.

**The method.** `prototype/709-memory-peak/qualify.sh` (`a1aa5356`) runs each
candidate of `candidates.txt` twice, untimed, on macOS:
- *a census run:* `ltl` as tracked, without `-mem`, under `-V
  message-grouping`, for the checkpoints each group fired, its final-pass
  windows and whether its final pass was skipped. The section adds member
  keys and accounting, never a decision, so its counts are the run's control
  flow;
- *a trace run:* the trace arm, under `-mem -V benchmark-data,memory-usage`.

In every run the final-pass walks equal the census windows. No run's stderr
carries ` at <file> line <N>`.

| Candidate | Options | Keys grouping saw | Checkpoints fired / walked | Windows | Groups skipped | Walks inside grouping, time | Walks' share of the run | Largest walk |
|---|---|---|---|---|---|---|---|---|
| month server, 1 day | `-bs 1440 -g -m uuid` | 34,675 | 9 / 9 | 7 | 0 | 16, 0.10 s | 5.5 % | 92.8 MB |
| 7 days | same | 288,151 | 15 / 15 | 8 | 0 | 23, 1.00 s | 6.9 % | 143.5 MB |
| 15 days | same | 1,265,282 | 29 / 27 | 12 | 0 | 39, 2.98 s | 8.1 % | 277.3 MB |
| 7 days, heatmap and histogram | `-bs 1440 -hm -hg -g -m uuid` | 288,151 | 15 / 15 | 8 | 0 | 23, 0.55 s | 3.2 % | 92.5 MB |
| month server, 1 day | `-bs 1440 -g` | 37,643 | 23 / 14 | 6 | 1 | 20, 0.52 s | 17.6 % | 139.7 MB |
| 7 days | same | 280,593 | 117 / 18 | 7 | 1 | 25, 3.36 s | 22.4 % | 395.5 MB |
| 15 days | same | 663,238 | 272 / 23 | 9 | 2 | 32, 11.32 s | 26.5 % | 934.8 MB |
| PLM web server access log, 1 day | `-du us -g` | 284 | 5 / 5 | 5 | 0 | 10, 0.01 s | 2.1 % | 11.3 MB |
| same | `-du us -g -xqs` | 75,700 | 20 / 6 | 3 | 1 | 9, 0.86 s | 17.7 % | 331.9 MB |
| 286K unique error messages | `-g` | 286,775 | 6 / 6 | 3 | 0 | 9, 0.10 s | 2.2 % | 237.4 MB |
| same | `-g -m uuid` | 333 | 3 / 3 | 3 | 0 | 6, 0.01 s | 0.2 % | 11.6 MB |
| security log, near-identical rejections | `-g` | 2,230 | 2 / 2 | 3 | 0 | 5, 0.05 s | 1.8 % | 72.3 MB |
| large error log | `-g` | 543 | 1 / 1 | 1 | 0 | 2, 0.01 s | 0.6 % | 19.8 MB |
| general application log, 85 MB | `-g` | 7,846 | 6 / 6 | 9 | 0 | 15, 0.30 s | 5.8 % | 182.7 MB |
| script log with duration, bytes and count | `-g` | 6,102 | 2 / 2 | 3 | 0 | 5, 0.05 s | 1.0 % | 49.9 MB |
| method server, one node, 12 rotations | `-g` | 7,266 | 6 / 6 | 3 | 0 | 9, 0.12 s | 1.0 % | 107.9 MB |

The share counts the boundary walks too. The month server is the one of
§ P1 before the timed runs; the PLM access log is the query-string specimen of
`docs/test-logs.md`.

- **The cost is where keys do not group.** Without the UUID mask, and with
  `-xqs`, nearly every key stays its own row. The message store reaches
  795.8 MB at 15 days, and each walk covers it. The walks take 17.6 to 26.5 %
  of the run, rising with the input. Most checkpoints there take the fast path
  (249 of 272 at 15 days), so the walks grow in size, not in number.
- **The most walks are where keys do group.** With the mask, nearly every
  checkpoint runs its pass: 16 to 39 walks. Only there do the clusters peak in
  the final pass (102.8 MB at 15 days, 59.1 MB at the boundaries).
- **The ID index and the trigrams peak at a checkpoint on every family,** and
  at the boundaries read at most 33.0 MB against up to 209.0 MB inside
  grouping. They are the largest transient stores on most candidates.
- **The plan's application-log input exercises almost nothing.** The 286K
  unique messages fire 6 checkpoints, and under the benchmark's mask, which
  collapses them to 333 keys, 3. The plan's line calling it the most
  checkpoint-heavy file is not borne out at the walk sites.
- **The heatmap and histogram make the walks cheaper,** 0.55 against 1.00 s
  on 7 masked days, with the same control flow. Under the heatmap the
  time-bucket store does not hold its durations in the walked map: its
  largest walk is 92.5 MB against 143.5 MB.

**No conditional count captures on every family,** replayed over the 16
traces with `simulate.py`:
- *Either count, at +0 % and +10 %,* misses on the general application log
  (ID index 111.0 → 59.4 MB, trigrams 57.1 → 33.0 MB) and on the security log
  (ID index 44.4 → 6.8 MB). On the other 14 it captures every grouping store
  of 1 MB or more.
- *Keys held* misses on 11 of the 16 at +0 %, every masked month input among
  them, and on 14 at +10 %.
- *Clusters* takes no reading at all on the security log.

The ID index and the trigrams grow with the trigrams of the keys held, not
with their number: on the general application log a checkpoint holding 5,605
keys built a 4.0 MB index, and the next, holding 5,406, a 111.0 MB one.

### P1 results (2026-10-28)

The approved matrix ran: eight inputs, five arms, three rounds, 120 runs in
41 minutes on macOS. Every run exited 0, and no run's stderr carries ` at
<file> line <N>`. The findings report, with the per-run figures, is
`prototype/709-memory-peak/findings.md` on the issue branch (`9d886aeb`).

**Cost is read from the wall clock.** `-V benchmark-data`'s `TIMING total`
sums the stages, so it leaves out the phase-boundary walks, which run between
them. On 15 unmasked days the floor's total is 49.6 s and its wall clock
51.1 s; every call's are 60.5 s and 67.0 s.

Wall clock, median of three, and its difference from the floor's (`ltl` as
tracked, without `-mem`):

| Input | Floor | Every call | Boundaries only | Grouping's stores only | Either count, +0 % |
|---|---|---|---|---|---|
| month server, `-bs 1440 -g -m uuid`, 1 day | 2.18 s [2.15–2.56] | +6.9 % | −4.6 % | +6.4 % | +2.3 % |
| 7 days | 15.79 s [15.62–16.23] | +6.2 % | +0.6 % | +8.3 % | +2.7 % |
| 15 days | 39.94 s [39.25–40.23] | +7.7 % | +1.2 % | +6.4 % | +4.8 % |
| month server, `-bs 1440 -g`, 1 day | 3.90 s [3.88–3.93] | +19.7 % | +5.4 % | +24.1 % | +6.7 % |
| 7 days | 20.86 s [20.51–24.88] | +31.0 % | +8.7 % | +23.2 % | +15.1 % |
| 15 days | 51.06 s [50.64–51.82] | +31.3 % | +8.2 % | +31.7 % | +14.9 % |
| PLM access log, `-du us -g -xqs` | 7.59 s [7.56–8.30] | +23.6 % | +9.0 % | +21.6 % | +18.7 % |
| general application log, `-g` | 5.87 s [5.82–6.15] | +6.8 % | −3.7 % | +5.5 % | +2.6 % |

On the 1-day inputs the ranges are as wide as the differences.

**What each arm captures,** against the every-call arm's high-water marks:
- *Grouping's stores only* captures every grouping store of 1 MB or more on
  all eight inputs.
- *Either count* captures every one on seven. On the general application log
  it captures the ID index at 59.4 MB against 111.0 MB and the trigrams at
  33.0 MB against 57.1 MB. It took exactly the readings `simulate.py` replayed
  for it on all eight, and missed exactly what the replay said.
- *Boundaries only* misses every transient store on all eight: the ID index
  (up to 209.0 MB, read as 0.0), the trigrams (up to 96.7 MB, read as at most
  33.0), and the clusters on the masked days (102.8 MB, read as 59.1).
- The peak resident set does not depend on the arm: 1,415.5 to 1,415.6 MB
  across the four `-mem` arms on 15 unmasked days, 1,401.2 MB for the floor.

**The mechanism:**
- *The cost is the message store, walked inside grouping.* On 15 unmasked
  days it is 795.8 MB of a 934.8 MB walk. Each walk there takes 0.37 s, and
  the 32 walks take 11.8 s.
- *Walking only grouping's stores saves nothing where the cost is,* since the
  message store is one of them: 11.35 s against 11.78 s on 15 unmasked days.
- *The stores that peak inside grouping are the transient ones:* the ID
  index, the key trigrams, the clusters and the per-key maps. The boundary
  walks catch the message store's high-water mark on all eight inputs. On the
  16 qualification candidates it peaked inside grouping on three, at 4.6 MB
  at most.
- *The boundary walks are a cost of their own:* 4.32 s on 15 unmasked days.
  The boundaries-only arm runs 5.4 to 9.0 % above the floor on the unmasked
  and `-xqs` inputs.
- *The floor takes readings too.* `ltl` as tracked, without `-mem`, spends
  0.10 to 0.47 s per run launching `ps` at every boundary, checkpoint and
  window. Delivery plan drop 3 removes these readings.

**The transient-stores-only arm, measured on the architect's approval.**
Inside grouping, each checkpoint and window walks only the 15
`consolidation_*` stores; the boundary walks cover every store. It ran in a
second set of three rounds beside the floor and the every-call arm: 72 runs
in 25 minutes, every one exiting 0, with no ` at <file> line <N>` on stderr.
The set ran noisier than the first (the floor's range on 15 masked days was
39.5 to 49.0 s), so its arms are compared with each other only
(`prototype/709-memory-peak/findings.md`, at `bbf5990b` on the issue branch).

| Input | Floor | Every call | Transient stores only | Walks inside grouping: every call → transient |
|---|---|---|---|---|
| month server, `-bs 1440 -g -m uuid`, 1 day | 2.24 s [2.12–2.64] | +9.4 % | +4.0 % | 0.09 → 0.05 s |
| 7 days | 15.84 s [15.84–22.34] | +6.2 % | +3.2 % | 0.80 → 0.27 s |
| 15 days | 43.45 s [39.48–49.00] | +6.8 % | +1.0 % | 2.97 → 0.97 s |
| month server, `-bs 1440 -g`, 1 day | 4.32 s [4.20–5.66] | +26.6 % | +11.3 % | 0.66 → 0.11 s |
| 7 days | 20.62 s [19.71–21.52] | +34.4 % | +19.9 % | 3.55 → 0.12 s |
| 15 days | 51.08 s [48.17–51.29] | +39.2 % | +9.1 % | 13.67 → 0.13 s |
| PLM access log, `-du us -g -xqs` | 8.32 s [7.41–10.24] | +17.2 % | +10.9 % | 0.82 → 0.34 s |
| general application log, `-g` | 6.23 s [5.69–10.15] | +4.5 % | +3.2 % | 0.35 → 0.31 s |

- *It captures every grouping store* of 1 MB or more within 5 % of the
  every-call arm's high-water mark on all eight inputs. That includes the
  message store, which the boundary walks catch.
- *What remains of `-mem`'s cost is the boundary walks:* 4.28 s of the 4.65 s
  above the floor on 15 unmasked days. The walks inside grouping take 0.13 s.
- *One residual is unexplained.* On 7 unmasked days the arm runs 4.1 s above
  the floor, while its walks take 2.0 s. Its range (23.40 to 25.27 s) does not
  reach the floor's (19.71 to 21.52 s).

### Drop 4: the inventory stores join the map (2026-10-28)

Delivered at `5f6c9f9c` on the issue branch: `named_structures()` maps 67
stores by name to a reference, the 29 the map had and the 38 of § Store
inventory; `named_structure_sizes()` walks it whole or for the names given;
`MEMORY_FINAL` carries one row per store of the map.

**Proven against the code before the change,** both captured with `-V`, on
macOS:

| Input | `MEMORY` rows | `MEMORY_FINAL` rows | New rows of 64 KB or more | `unattributed` |
|---|---|---|---|---|
| one-day web application access log, `-mem -V benchmark-data -hg -hgdm raw -h HTTP` | 32 → 70 | 8 → 67 | `histogram_values_hl` 71.4 MB | 142.4 → 79.3 MB |
| the month server's first day, `-mem -V benchmark-data -bs 1440 -n 25 -g -m uuid` | 32 → 70 | 8 → 67 | `consolidation_key_checkpoint_count`, `consolidation_key_generation`, 1.1 MB each | 28.4 → 26.3 MB |
| the network-latency CSV, `-mem -V benchmark-data -udm latency_ms` | 32 → 70 | 8 → 67 | none | 44.4 → 44.4 MB |

- *The rows already mapped* moved by less than 1 %.
- *Without `-mem`* the output is unchanged, with the figures masked.
- *Under `-mem debug`* the decomposition records keep their shape, and their
  `named_sum` now covers the 67 stores.
- *No run's stderr carries* ` at <file> line <N>`.
- *Criterion 9's size:* the highlighted raw values read 71.4 MB, against
  "about 70 MB".

**Asserted** by the `memory-map` scenario of `tests/validate-memory-usage.sh`
(criteria 9 and 10):
- every inventory store has a `MEMORY` row;
- `MEMORY unattributed` is `rss_peak` less every other row, exactly;
- `MEMORY_FINAL` carries the map's stores;
- the breakdown lists only stores of the map, then `unattributed`, which is
  MAXIMUM MEMORY USED less every store within the precision of the rendered
  figures and the stores under 1 KB it hides.

The breakdown prints after the benchmark block and after further walks, so
its high-water marks can exceed the block's rows. It is checked against its own
figures, not the block's. The two inventory checks fail on the code before the
change, and the two `unattributed` checks each fail on a copy whose sum is
sabotaged.

Every other harness scenario that runs `-mem` or reads a `MEMORY` row passes:
`validate-memory-usage.sh` whole (28), and the memory scenarios of
`validate-byte-units.sh`, `validate-format-registry.sh`,
`validate-histogram-bin-counters.sh`, `validate-read-path.sh`,
`validate-runtime-config.sh`, `validate-statistics-demand.sh`,
`validate-udm-counting.sh` and `validate-section-layout.sh`, and
`validate-verbose-content-shape.sh`.

### Drop 5: grouping's walks per D3 (2026-10-28)

Delivered at `3eda9545` on the issue branch. Under `-mem`,
`measure_memory_structures()` walks `grouping_structure_names()`, the 15
`consolidation_*` stores of the map, at the `grouping_checkpoint` and
`grouping_final_pass` sites, and every store at the phase boundaries. The two
grouping call sites are unchanged.

**Criterion 11 met under one pinned hash seed** (the architect, 2026-10-28;
`prototype/709-memory-peak/criterion-11.sh`, at `637a1280` on the issue
branch, output in `results/criterion-11-d5.txt`, macOS):
- *Capture:* on the eight P1 inputs every grouping store of 1 MB or more is
  within 5 % of the reference, the message store included.
  - 57 of the 60 stores are byte-equal.
  - The other three are the message store, short by 240 bytes on 7 and
    15 unmasked days and by 2,872 bytes on the general application log, the
    little it peaks inside grouping.
- *Cost:* on 15 days of one server's access logs grouped without the UUID
  mask, the wall clock was 54.30 s [54.04–55.71] with `-mem` against
  49.83 s [49.24–49.97] without, +9.0 % (bound 12 %). Unpinned, drop 4's code
  took +32.9 % on the same input (`results/d5-criterion-11.txt`).

**The check is shown to discriminate** (`results/criterion-11-proof.txt`):
- *Reference marks:* `results/criterion-11-reference.tsv` is regenerated
  from drop 4's code, which walks every store at every site, under the pinned
  seed.
- *Known-good:* that same code, checked against its own reference, is
  byte-equal on every store of every input, so pinned runs reproduce to the
  byte.
- *Known-bad:* P1's boundaries-only arm fails on all eight inputs.
- *Refusal:* the checker refuses any run whose stderr does not show the
  pinned seed.

No run's stderr carries ` at <file> line <N>`, and
`tests/validate-memory-usage.sh` passes whole (28).

**Finding: the message store's size differs between identical runs.** Across
every run of P1 and of drop 5, by input. Every arm with `-mem` reports
`MEMORY_FINAL log_messages`, the store's size as the benchmark block prints;
the floor reports none:

| Input | Runs | Final message-store size |
|---|---|---|
| one server's access logs, 1 day, `-bs 1440 -g` | 19 | 43.8 MB ×14, 41.4 MB ×5 |
| 7 days | 19 | 337.3 MB ×16, 319.4 MB ×3 |
| 15 days | 25 | 794.0 MB ×22, 751.8 MB ×3 |
| PLM web server access log, `-du us -g -xqs` | 19 | 101.0 MB ×14, 96.1 MB ×5 |
| the same server, `-bs 1440 -g -m uuid`, 1, 7 and 15 days | 19 each | one size; on 7 days 52.7 and 52.6 MB |
| general application log, `-g` | 19 | one size |

- *Two sizes, 4.9 to 5.5 % apart,* on every input whose keys do not group.
- *It is not the walks.* The smaller size appears under the every-call arm, the
  grouping's-stores-only arm and drop 5 alike.
- *It is not the data.* The store holds the same elements in both states:
  - On one unmasked day (`-bs 1440 -g`), 12 identical runs under
    `-mem -V benchmark-data,message-grouping` ended at 43.8 MB ten times and
    41.4 MB twice.
  - The `message-grouping` section matched across the two states: every
    group's keys, rows and counters, and all 37,664 records of its
    `accounting` sub-section, which give each category and grouping key at
    every stage, and each reported row, its occurrences, durations counted,
    durations retained and bytes.
  - On 15 unmasked days, the two sizes come with the same line, file and
    message-row counts in `-V benchmark-data`.
- *Another variation, separate from this one:* the one line of the section that
  differs is `similarity_cliff_edge_pct`, reported for the group whose final
  pass is skipped. It read 70 to 75 % across the 12 runs, and differs between
  runs in the same size state.
- *The cause is the per-process hash seed.* Perl draws a random 256-bit hash
  seed per run (`HASH_FUNCTION = SBOX32_WITH_SIPHASH_1_3`, printed under
  `PERL_HASH_SEED_DEBUG=1`). Replaying a captured seed with `PERL_HASH_SEED`
  reproduced its run's size to the byte: on one unmasked day, the smaller
  state's seed gave 41,427,803 bytes twice and the larger state's seed
  43,832,795. Key-order perturbation plays no part: with
  `PERL_PERTURB_KEYS=0` and the seed left random, the smaller state appeared in
  3 of 12 runs. Fixed seeds of 64 bits or less fill only part of the seed;
  42 such runs all gave the larger state.
- *The difference is 64 bytes per message entry.* 2,404,992 bytes is exactly
  64 × 37,578, of the 37,597 entries. Sixty-four bytes is eight pointers, a
  small hash's bucket array doubling from 8 to 16 buckets. Since Perl 5.18 a
  hash splits only when an insert collides, which depends on the seed, and
  every entry has the same field names inserted in the same order, so in one
  run either every entry splits or none does. This mechanism is read from
  the arithmetic and the seed's determinism; a single entry's bucket count
  was not inspected.
- *`Devel::Size` measures it exactly.* It sums the memory each structure has
  allocated: each scalar's head and body, each string buffer at its allocated
  length, each array's allocated slots, each hash's bucket array and entries.
  It leaves out the allocator's own overhead. The two states are memory the
  process really holds, not imprecision in the walk.
- *It meets criterion 11's 5 % capture bound.* A run in the smaller state reports
  the message store at 94.7 % of the reference (754.4 against 796.8 MB on
  15 unmasked days). Drop 5's capture run fell in the larger state on all
  eight inputs.

### Drop 2: the kept peak (2026-10-30)

Delivered at `83f88bce` on the issue branch, rebased onto 6dadde32.

**What it does.** `read_run_peak_memory()` reads the peak the operating
system keeps for the process, through `get_kept_peak_memory()`, once at each
moment a peak is reported:
- in `print_verbose_output()`, before `benchmark-data`'s memory rows:
  `rss_peak`, and `unattributed` against it;
- in `pipeline_render()`, before the summary: `$reported_max_memory_usage`,
  read by MAXIMUM MEMORY USED, the breakdown's shares and `unattributed`, and
  the export's `max_memory_used`;
- in `write_index_file()`, once for every selection row's `memory_used`.

`$max_memory_usage` takes each reading, so a later reading between steps
above it still raises it until the next moment reads the kept peak again.

| Platform | Reading | Notes |
|---|---|---|
| macOS | `ru_maxrss` from `BSD::Resource::getrusage()` | in bytes: 6,291,456 at a script's start against `ps`'s 6,144 KB |
| Linux | `VmHWM` in `/proc/self/status`, in kB | not run in this drop (below) |
| Windows | `PeakWorkingSetSize` at offset 8 of `PROCESS_MEMORY_COUNTERS` | the call is now `windows_working_set()`, shared with the current reading; not run in this drop |

- `-V memory-usage` lists the readings under `kept_peak`, first in the
  section's order (§ -V memory-usage section contract).
- `build/cpanfile.macos`, regenerated with `./build/generate-cpanfile.sh ltl
  all` from the repository root, requires `BSD::Resource`. The Linux and
  Windows files are unchanged.
- `resolve_kept_peak_reading()` settles whether the peak is readable once,
  from `pipeline_detect()`. On macOS it loads `BSD::Resource`. Without it the
  run raises `memory-unreadable` once, with the evidence "the BSD::Resource
  module, which reads the peak macOS keeps for the process, is not installed",
  and reports the readings' peak.

Recorded with the drop, the one sensible option: the readability is settled
as the pipeline starts, not with the options as first written. A notice
raised while the options are read is put to the analyst by
`ask_about_option_notices()` as "the options given raised notices before the
read", with a choice to stop and correct them. A missing module is not a
matter of the options. Raised at `detect`, the notice is drawn in the panel,
and the fallback scenario asserts that.

**What it costs.** Loading `BSD::Resource` took 5.7 to 7.1 ms in three
standalone runs, once at the start of each macOS run. The first `getrusage`
call took 0.1 to 0.3 ms, later ones 1 to 2 µs. Under `-V memory-usage` on the
access-log fixture, one `kept_peak` reading took 312 to 327 µs in three runs.

**Criterion 1 on macOS** (`/usr/bin/time -l`, maximum resident set size,
one run each, no ` at <file> line <N>` on any run's stderr):

| Input and options | `-mem` | Code | `rss_peak` | `time -l` | Below it |
|---|---|---|---|---|---|
| one day of a web application access log, `-hg -hgdm raw -h HTTP` | no | before the drop (`ee9c79bf`) | 263,847,936 | 291,061,760 | 9.35 % |
| | yes | before the drop | 276,889,600 | 293,240,832 | 5.58 % |
| | no | drop 2 | 291,454,976 | 291,454,976 | 0 |
| | yes | drop 2 | 293,896,192 | 293,896,192 | 0 |
| one server's month of that log, 28 files, `-bs 1440 -n 25 -g -m uuid` | no | drop 2 | 1,011,318,784 | 1,011,351,552 | 0.003 % (32 KB) |
| | yes | drop 2 | 1,019,871,232 | 1,019,871,232 | 0 |
| the same month, `-bs 1440 -hm -hg -g -m uuid` | no | drop 2 | 766,623,744 | 766,623,744 | 0 |
| | yes | drop 2 | 770,408,448 | 770,408,448 | 0 |

MAXIMUM MEMORY USED rendered the same peak at its moment (291.5 MB and
293.9 MB on the day; 1 GB, 766.6 MB and 770.4 MB on the month). The 32 KB is
memory the render allocated after `benchmark-data` printed. Each run read
`kept_peak` twice: `benchmark-data` and the summary; no index was written.
The month cases were measured on drop 2 alone; the premise runs (§ Issue
#709) measured the readings falling up to 158 MB short on them.

**Criterion 4, as asserted.** `benchmark-data` prints during the render,
before the timeline, so a reading taken after it can be above the peak it
read. The check therefore compares `rss_peak` with the readings taken before
it, through the `after_normalize` decomposition. It also compares the
index's `memory_used`, read after the last diagnostic reading, with every
reading. Against the code before the drop, the `after_normalize` reading was
45,383,680 bytes, above an `rss_peak` of 45,318,144.

**The harness.** `tests/validate-memory-usage.sh` gains three scenarios:

| Scenario | Criteria | What it asserts |
|---|---|---|
| `peak-consumers` | 3, and 5's count for this drop | MAXIMUM MEMORY USED and the export's `max_memory_used` carry one string; the index's `memory_used` is at or above `rss_peak`; `kept_peak` reads 3 times (`benchmark-data`, the summary, the index), or none with the notice |
| `peak-not-below-readings` | 4, 12 | no reading before `rss_peak` is above it; no reading is above the index's `memory_used`; the site lines follow the contract's order |
| `peak-fallback` | 6 | macOS only: with `BSD::Resource` refused by an `@INC` hook given through `PERL5OPT`, one `memory-unreadable` notice naming the module, raised at `detect` and drawn in the panel; no `kept_peak` reading; five `phase_boundary` readings; a non-zero `rss_peak` |

Each check was shown to fail on a build that breaks what it asserts:

| Build | What fails |
|---|---|
| the code before the drop | the `kept_peak` count; no reading above `rss_peak`; the notice |
| `kept_peak` moved last in the site order | the order |
| the kept peak halved | both comparisons with the readings |
| the export's peak raised by 9 MB | the summary and export string |
| the index's peak lowered by 9 MB | the index against `rss_peak` and against every reading |
| the fallback reporting 0 | the readings' peak |
| the readability settled with the options | the notice's stage and surface (`options` and `ask`) |

Drop 4's `memory-map` scenario failed the failed-run checker's lookup rule:
its breakdown filter assigned a `grep` with no fallback. That filter is now
an `awk`, and `./tests/validate-harness-failed-run.sh --scenario
memory-usage` passes, 15 checks. The whole harness passes, 36 checks.

Every consumer of the memory output still asserts (criterion 12), each named
scenario run: `validate-verbose-content-shape` `every-section`,
`validate-format-registry` `benchmark-data-reemission` and
`unarmed-measurement`, `validate-statistics-demand` scenarios 13 and 14,
`validate-byte-units` `one-notation-reach`, `validate-read-path`
`identity`, `validate-summary-contribution-bar` `summary-mono`,
`validate-timestamp-precision` `option/equivalence`, and the
`benchmark-rows` scenario for `compare-results.sh`.
`validate-notices` `migration-categories` reads `memory-unreadable` as a
runtime condition at both of its producers, and `stderr-sites` passes.
`features/412-notice-surfaces.md` § Inventory of current notices names the
two producers (rows 35 and 36); `docs/architecture-patterns.md` § Run-scoped
activation flags names the new flag's consumption site.

**Not run on this host**, for drop 2's remaining criteria:
- Criterion 1 on Windows: the Windows development host.
- Criterion 1 on Linux: no container runtime starts on the first macOS
  development host, a virtual machine without hypervisor support
  (`kern.hv_support` 0; `features/757-linux-cpanfile.md` § Acceptance
  criteria), so the container run the criterion names cannot be made here.
- Criterion 7's other half, the packaged macOS binary reporting the kept
  peak: PAR::Packer is not installed for this host's Perl 5.44, since its
  dependency's download is blocked by a network proxy (same record,
  § Completion gate). #757 packed its binary on GitHub's `macos-latest`
  runner.

Observation, raised with the drop: `docs/perl-performance-optimization.md`
§ `free()` Returns to Perl's Allocator, Not the OS states "RSS high-water mark
equals RSS at end of run" and "RSS never decreases even when structures are
freed". This issue measured macOS returning memory before the next reading:
733 MB inside the displayed rows' statistics, 638 MB at the next reading
(§ Issue #709 › Findings, the heatmap-histogram-consolidate case). It is left for the architect.

### Delivery plan

Drafted 2026-10-28. The stage starts only on the architect's direction. Each
drop is committed and pushed on the issue branch before the next one starts.
The issue's one PR follows the completion gate.

**Order (the architect, 2026-10-28):** drops 4 and 5 are delivered first,
since neither depends on #757; drops 2 and 3 follow once #757 is delivered,
then drop 6.

**Start.**
- The branch `709-memory-peak-and-unmeasured-stores` is cut from
  `release/0.20.0`, in its own worktree beside the release worktree, so both
  sides of the benchmark run from the same kind of checkout.
- `$version_number` is set to `0.20.0-709`.
- The `before` benchmark runs on the base commit: the four tests of criterion
  13, three runs each. It runs before P1, never alongside it, because both are
  timings.

1. **The prototype, P1.**
   - The findings report goes beside it.
   - The architect locks the choice of grouping's walks, and criterion 11's
     bounds are written from it.
2. **The kept peak (D1, D2).**
   - Each platform reads the kept peak at its own `-V memory-usage` site, and
     the four consumers of the peak read it.
   - On macOS, the fallback and its `memory-unreadable` notice.
   - The cpanfiles regenerated with the `require BSD::Resource` this drop
     adds. #757 (a Linux-specific variant of the cpanfile) routes the module to
     `build/cpanfile.macos` alone, so the macOS setup installs it and no Linux
     or Windows path requires it; `pp` packs it into the macOS binary, shown on
     a scratch copy of `ltl` (`features/757-linux-cpanfile.md` § Delivery plan
     › Progress, drop 3).
   - Criteria 1 to 4, 6, 12 and 14, and criterion 7's other half, on this
     drop's surfaces. Criterion 1's
     Windows run is on the Windows development host, and its Linux run in a
     container.
3. **Readings between steps only under `-mem`, or in the fallback**
   (criterion 5). This drop follows 2, so that no run is left without a peak.
4. **The 38 stores join `named_structure_sizes()`, and `MEMORY_FINAL`
   converges onto the map** (criteria 9 and 10). The consumption sites in
   `docs/architecture-patterns.md` § Named-structure memory map are trued up.
   This drop comes before 5 because the map's size sets a walk's cost.
5. **Grouping's walks, per D3** (criterion 11).
6. **The `after` benchmark** (criterion 13), with the findings report under
   Results. Then the completion gate per `docs/process/workflow.md` § 3, then
   the PR.

**Edges (the dependency-first test, 2026-10-28).** None blocks since #757's
delivery (2026-10-30).
- **#757 (a Linux-specific variant of the cpanfile) blocked #709** until its
  delivery (PR #763, 2026-10-30), a native edge, now removed, filed at the
  architect's direction as a sub-issue of #729 (process, tests and build).
  #709 could not reach a clean implementation before it. `build/cpanfile`
  then served macOS and Linux, so declaring `BSD::Resource` there would have
  had three effects on Linux, all for a module it never loads:
  - `build/linux-setup.sh` stops until the module's package is named
    (`features/750-interpreter-resolution.md` § `build/linux-setup.sh`);
  - the environment check's condition 3, the Perl loads every runtime module
    of the cpanfile, fails until the package is installed (same record,
    § Phase 4: the expected conditions);
  - the Linux release binary's container build, `build/ubuntu-package.sh`,
    installs it.

  The prototype stage did not depend on #757; drop 2 did.
- **#710 (remove the run index).** Each of the two reaches a clean
  implementation without the other. The index's `memory_used` is one of the
  peak's four consumers. Whichever issue lands second either moves it to the
  kept peak or removes it with the index.
- **#354 (the message-statistics store under `-mdm bin`, on hold behind #2).**
  It uses `-mem` as its instrument. Its two stores, `log_messages` and
  `log_messages_counters`, are already in the map, and its peak comparison can
  be read from the operating system's peak meanwhile.
- **#2 (memory ceiling).** As recorded in § Records sweep. With no reading
  between steps without `-mem` (following D1 and D2), the controller brings its
  own reading cadence.

## Issue #146: Windows process memory, validated before the old dependency goes

**Status:** in progress, branch `146-windows-process-memory`.

#146 was to be the point where the Windows process-memory reading introduced
under #143 (a direct `K32GetProcessMemoryInfo` call through `Win32::API`, in
place of the WMI-based `Win32::Process::Info`) was validated before the old
module left the build.

### Contract of the surfaces touched

- **Peak memory.** "RSS (Resident Set Size) high-water mark is always captured
  and displayed as MAXIMUM MEMORY USED in the summary table" (§ Default
  Behavior above). The #709 direction restates it: "The overall peak RSS is the
  one memory figure every run reports, with or without `-mem`."
- **Windows exception.** `releases/v0.14.3.md`: "disabled by default on Windows
  until validated — opt in with `-mem`". `get_memory_usage()` returns 0 on
  Windows unless `-mem` is given.
- **Windows build dependencies.** `build/cpanfile.windows` is generated by
  `build/generate-cpanfile.sh` from the modules `ltl` loads with `use` or
  `require`, minus the Unix-only list.

### Findings

**The module already left the build, unvalidated.** Once `ltl` stopped loading
`Win32::Process::Info`, the next regeneration of `build/cpanfile.windows`
dropped it, on the day of the #143 change. Every release since, through
v0.19.0, built its Windows executable without it. Restoring the cpanfile line
alone would not restore the old reading: `ltl` no longer calls the module.

**The Windows reading takes the wrong counter.** `get_memory_usage()` reads 8
bytes at offset 24 of `PROCESS_MEMORY_COUNTERS` on 64-bit Perl. Offset 24 is
`QuotaPeakPagedPoolUsage`; `WorkingSetSize` is at offset 16 (`cb` 4 +
`PageFaultCount` 4 + `PeakWorkingSetSize` 8). The 32-bit branch reads 16 where
`WorkingSetSize` is at 12. Every field read from one Strawberry Perl 5.42 x64
process on a Windows 11 ARM64 host:

| Offset | Field | Bytes |
|---|---|---|
| 8 | PeakWorkingSetSize | 20,967,424 |
| 16 | WorkingSetSize | 20,967,424 (`tasklist`: 22,384 K) |
| 24 | QuotaPeakPagedPoolUsage (read today) | 167,528 |
| 32 | QuotaPagedPoolUsage | 167,528 |
| 56 | PagefileUsage | 13,246,464 |

On a twelve-line combined-format access log fixture, `-mem debug` printed
`rss=172496` at all nine phase boundaries and the summary read
`MAXIMUM MEMORY USED 172.2 kB`. Without `-mem` the summary reads `0 B`. The
`single-day-access-log-standard` benchmark on the same host (a one-day web
application access log carrying execution time in the duration field, 148 MB,
761,698 lines) recorded `MEMORY rss_peak 172664`.

**What the wrong counter reaches.** Windows with `-mem` only: MAXIMUM MEMORY
USED, the `unattributed` row, every breakdown percentage (its denominator), the
`format_scan_subs` row (a compile-boundary process-memory delta), `-V
benchmark-data` `MEMORY rss_peak`, the aggregate export's peak memory, the run
index's memory column, and the `-mem debug` `rss=` lines. Each named structure's
size comes from `Devel::Size` and is unaffected.

### Decisions

- **D1 (locked 2026-10-15): the offset is fixed within #146.** `WorkingSetSize`
  is read at offset 16 on 64-bit Perl and 12 on 32-bit, so the validation #146
  exists for is completed by the same change.
- **D2 (locked 2026-10-15): Windows reads process memory on every run.** The
  `-mem` gate in `get_memory_usage()` goes. v0.14.3 disabled the reading until
  it was validated; #146 is that validation, after which Windows meets the
  § Default Behavior contract as macOS and Linux do. One reading costs about
  52 µs (three runs of 1,000 calls: 52.0, 52.2, 52.5 µs).
- **D3 (locked 2026-10-15): the cpanfile drift is fixed within #146.** See
  Scope 3.
- **D4 (locked 2026-10-15): memory readings are observable in a new
  `-V memory-usage` section.** Every call of `get_memory_usage()` is counted
  and timed per caller, and `benchmark-data` repeats the totals (one source,
  two surfaces, `tests/HARNESS-DESIGN.md`). The context: v0.14.3 took the
  Windows reading out of default runs because the WMI call it then used was so
  slow it degraded the whole run; the count and cost of the replacement are
  measured through a very large run before the gate.
- **D5 (locked 2026-10-15): the `-mem debug` output moves into the
  `memory-usage / debug` sub-section.** Its diagnostic lines no longer go to
  stderr.
- **D6 (locked 2026-10-15): `-mem debug` stays the switch and requests the
  section.** `ltl -mem debug <file>` prints `memory-usage` with its `debug`
  sub-section at the end of the run without `-V` being named. Plain `-V` and
  `-V memory-usage` carry the reading counts only, so the structure walks at
  each phase boundary run only when `-mem debug` asks for them. The lines no
  longer stream while the run goes; they arrive together at its end.

### Scope

1. `get_memory_usage()`: the offsets (D1) and the gate (D2).
2. References to modules `ltl` no longer loads (`Win32::Process::Info`,
   `Proc::ProcessTable`): the exclusion lists in `build/generate-cpanfile.sh`,
   the comments in `ltl`, `CLAUDE.md` § Platform, `features/windows-automated-build.md`,
   `build/packaging-notes`. Historical records (`releases/`, the redundant-logic
   audit report, `prototype/memory-benchmark.pl`) stay as written.
3. The cpanfiles are generated inputs, never the source of truth (architect,
   2026-10-15). Found while regenerating them for criterion 5:
   - The committed files lacked `Scalar::Util`, which `ltl` loads, and the
     generator emitted the `integer` pragma as a CPAN requirement. `integer`
     joins the generator's pragma list; both files are regenerated (D3, locked
     2026-10-15).
   - `build/windows-setup.ps1` installed from the committed
     `build/cpanfile.windows` without generating it first, so a setup after
     `ltl` gained a module installed from a stale list. It now runs the
     generator first.
   - The generator's output depended on the caller: under Windows Perl it wrote
     CR LF once no `grep` stripped them, and launched from PowerShell its
     `sort` followed the locale (`PerlIO::via` before `POSIX`, `YAML::PP` after
     its submodules). It writes LF and sorts in byte order.
4. The `-V memory-usage` section and its `debug` sub-section (D4 to D6), their
   consumers and records: `get_memory_usage()` and its callers, the `-mem debug`
   emitters, `print_help()` and `docs/usage.md` for `-mem`,
   `tests/HARNESS-DESIGN.md` § Reserved section names, the `benchmark-data`
   contract (`features/memory-baseline-profiling.md`), the comparison's
   within-parent rule in `tests/baseline/compare-results.sh`, the `memory-debug`
   option set of `tests/validate-read-path.sh`, and a new
   `tests/validate-memory-usage.sh`.

### `-V memory-usage` section contract

Printed once, after the run's last reading (`pipeline_render()` returns), when
`-V` selects the section or `-mem debug` is given (D6). A count is of calls of
the system interface: a reading the platform branch skips before calling it is
not counted.

Built on the established patterns (`docs/architecture-patterns.md`), each
consumption site recorded there in the same commit:

- **`-V` telemetry sections as the test surface.** `memory-usage` is registered
  in `%verbose_section_registry` and `@verbose_section_order`, emitted by
  `emit_memory_usage_verbose()` gated on `section_requested('memory-usage')`,
  in the content shape. Like `section-layout` and `aggregate-export` it prints
  at its own site, after the run's last reading, rather than through
  `print_verbose_output()`, which flushes before the render's readings.
- **Run-scoped activation flags resolved once.** Whether readings are counted
  is one flag settled with the options (the section requested, which `-mem
  debug` does); each reading tests that flag and nothing else. With the flag
  off, no counting or timing code runs.
- **Hot-loop discipline.** No counting code is in the per-line loop: readings
  happen at phase boundaries, grouping checkpoints and windows, compiles and
  the debug samples. The read loop's debug sample keeps its existing
  `#@when $show_memory_debug` gate marker, so a generated read body without
  `-mem debug` carries none of it.

```
=== memory-usage ===
readings: <N>
readings_us: <N>
site: <name> readings=<N> elapsed_us=<N>
...
=== memory-usage / debug ===
kind	elapsed_s	tag	rss	named_sum	unattributed	structure	bytes
...
=== END memory-usage / debug ===
=== END memory-usage ===
```

- `readings` and `readings_us`: every call of `get_memory_usage()` and
  `get_kept_peak_memory()` in the run and the wall time spent inside them, in
  whole microseconds. They equal the sums of the `site` lines.
- `site` lines, one per caller that read at least once, in this order:
  `kept_peak` (the peak the operating system keeps, `get_kept_peak_memory()`,
  read by `read_run_peak_memory()` once at each moment a peak is reported:
  `benchmark-data`, before the summary, the run index; #709 D1; none on macOS
  without `BSD::Resource`, D2),
  `phase_boundary` (the pipeline steps' `measure_memory_structures()`),
  `grouping_checkpoint` (`run_consolidation_checkpoint()`),
  `grouping_final_pass` (`process_final_pass_window()`),
  `format_scan_compile` (`compile_format_scan_sub()`), `csv_block_compile`
  (`compile_csv_block()`), `debug_decomposition`, `debug_sample`.
- The `debug` sub-section is present only under `-mem debug`: one record per
  diagnostic reading in the order taken, eight columns. `kind` is
  `decomposition` (a phase boundary: `rss`, `named_sum`, `unattributed`),
  `sample` (inside a loop: `rss` only), or `structure` (each structure of
  1 MiB or more at the decomposition before it: `structure` and `bytes`); a
  column a kind does not carry is `-`. `elapsed_s` is seconds since the first
  diagnostic reading, three decimals; `rss`, `named_sum`, `unattributed` and
  `bytes` are bytes. The `structure` records carry what `-mem debug` printed
  as its third line form; the contract first agreed omitted them.
- When the section is armed, `benchmark-data` repeats the totals as `COUNTS memory_readings` and
  `TIMING memory/readings` (seconds), read from the same counters at the moment
  `benchmark-data` prints, during the render, after the `kept_peak` reading its
  `MEMORY rss_peak` reports. They
  can therefore be lower than the section's totals by the readings taken after
  that point. `memory/readings` is time spent within the stages, so the
  comparison marks it within parent and leaves it out of the stage sum.

### Acceptance criteria

The target is `ltl` run by Strawberry Perl on a Windows development host; a
packaged executable carries the same interpreter and modules and is not
validated separately.

| # | Condition and observable outcome | Triage | Validation |
|---|---|---|---|
| 1 | On Windows x64 Perl, on every run, with or without `-mem`, `-V benchmark-data` `MEMORY rss_peak` on the one-day web application access log (148 MB) is not above the operating system's peak working set for that process and is within 5% below it | assertable | PowerShell launches each run and samples the process's `PeakWorkingSet64` until exit; compared with `rss_peak` |
| 2 | Under `-mem debug`, the `rss` readings follow the run: they rise from startup on the 148 MB log rather than staying constant | assertable | Held on stderr before D5 (Results); after it, the `memory-usage / debug` records on the same log |
| 3 | The 32-bit branch reads `WorkingSetSize` at offset 12 | unassertable | Strawberry Perl is x64 only; the offset is derived from the structure layout (`cb` 4 + `PageFaultCount` 4 + `PeakWorkingSetSize` 4). Recorded gap |
| 4 | macOS and Linux readings unchanged | assertable | The diff changes no line of the `darwin` or `linux` branch of `get_memory_usage()`; the counting (D4) wraps the branches and changes no value they return |
| 5 | Neither cpanfile names `Win32::Process::Info`, and `build/generate-cpanfile.sh` regenerates both byte-identical to the committed files | assertable | Regenerate, `git diff --exit-code build/` |
| 6 | `git grep` finds `Win32::Process::Info` and `Proc::ProcessTable` only in the historical records named in Scope and in this section | assertable | `git grep` |
| 7 | No ` at <file> line <N>` on stderr in any run above | assertable | Captured stderr grepped |
| 8 | Every call of `get_memory_usage()` is counted under its caller, and `readings` / `readings_us` equal the sums of the `site` lines | assertable | `tests/validate-memory-usage.sh`, one scenario per site on the smallest fixture that reaches it: phase boundaries on any run, grouping checkpoint and final pass under `-g`, format-scan compile under `-V benchmark-data`, CSV block compile on a CSV input, both debug kinds under `-mem debug` |
| 9 | Without `-mem debug` there is no `debug` sub-section, no structure walk at a phase boundary, and no `debug_*` site | assertable | Same harness, a plain `-V memory-usage` run |
| 10 | `ltl -mem debug <file>`, with no `-V`, prints `memory-usage` with its `debug` sub-section after the run's output, and nothing of it on stderr | assertable | Same harness; stderr captured separately |
| 11 | The `debug` sub-section holds one `decomposition` record per phase boundary the run reached, from `startup` to `end`, and a `sample` record every 75,000 lines read | assertable | Same harness, on a fixture or log with more than 75,000 lines for the sample |
| 12 | `benchmark-data` carries `COUNTS memory_readings` and `TIMING memory/readings`, not above the section's totals; the comparison reports `memory/readings` within parent | assertable | Same harness; `compare-results.sh summary` on two captures |
| 13 | The read-path comparison still holds under `-mem debug`: the generated read body and the standard loop give the same output | assertable | `tests/validate-read-path.sh --scenario` for its `-mem debug` option set, its consumer updated to the sub-section |
| 14 | `--help` and `docs/usage.md` describe `-mem debug` as printing the `memory-usage` section at the end of the run | assertable | `tests/validate-help-content.sh` |
| 15 | The new section meets the content shape | assertable | `tests/validate-verbose-content-shape.sh` |
| 16 | The cost of the readings is measured and recorded, before and after the fix: the number of readings and the time spent in them per caller, the total time spent reading memory, and that total against the run's total time | assertable (a measurement, recorded under Results) | One server of the thirty-day, five-server access-log folder, the common-plus-duration shape, ramped 1, 3, 7 and 15 days (2026-01-02 onward; 33 MB, 65 MB, 327 MB, 852 MB), `-g -V benchmark-data`. Six variants: before and after the fix, each without `-mem`, with `-mem`, and with `-mem -V memory-usage`. Three runs per point, medians with ranges |
| 17 | The counters cost nothing unless the section is selected (the activation-flag and hot-loop patterns above): no counting or timing code runs, and the generated read body carries none of it | assertable | Code review of the flag, `-V read-path` gate-marker lines on a run without the section, and criterion 16's variants without the section |

### Delivery plan

Each drop is committed and pushed on the issue branch before the next starts.

1. **Observability on the code before the fix.** The fix's two `ltl` changes
   (the offset, D1, and the gate, D2) are backed out, so the section first
   measures the reading as it shipped. Then the `-V memory-usage` section, its
   `debug` sub-section, the `benchmark-data` rows, the comparison's
   within-parent rule, the harness and its consumers (criteria 8 to 15, 17).
   The counters run only when the section is selected; a reading the Windows
   gate skips is not a call of the system interface and is not counted.
2. **Before benchmarks.** Criterion 16's three `before` variants at each ramp
   point, starting at one day and stepping up only once the previous point
   reads sensibly.
3. **The fix.** D1 and D2 re-applied.
4. **After benchmarks.** The three `after` variants at the same points.
5. **Analysis.** The findings report under Results; then the completion gate.

### Results

The one-day web application access log (148 MB, 761,698 lines),
`-V benchmark-data`, Strawberry Perl 5.42 x64 on a Windows 11 ARM64 host, one
run each. The operating system's peak is the process's `PeakWorkingSet64`,
sampled every 100 ms until exit.

| Code | Options | OS peak working set | `rss_peak` | `rss_peak` / OS peak |
|---|---|---|---|---|
| before | (none) | 126,742,528 | 0 | 0% |
| before | `-mem` | 128,450,560 | 184,936 | 0.14% |
| after | (none) | 128,688,128 | 125,067,264 | 97.19% |
| after | `-mem` | 128,421,888 | 125,943,808 | 98.07% |
| after | `-mem debug` | 127,750,144 | 125,272,064 | 98.06% |

Criterion 1 holds: 1.9 to 2.8% below the operating system's peak, never above.
Criterion 2 holds: the `-mem debug` phase readings were 58,949,632 at startup,
122,404,864 after reading, 125,251,584 after statistics and 125,313,024 at the
end. Criterion 7 holds: no run's stderr carries ` at <file> line <N>`.

Criterion 6 leaves one mention outside the historical records: the macOS branch
of `get_memory_usage()` explains that it launches `ps` to avoid the
`Proc::ProcessTable` crashes. That is the reason for the current design, and
criterion 4 keeps the macOS branch untouched.

### Drop 2: before the fix, 1 and 3 days (criterion 16)

One server of the thirty-day, five-server access-log folder, the
common-plus-duration shape, from 2026-01-02: 1 day (33 MB, 168,981 lines) and
3 days (65 MB), `-ni -g -V benchmark-data`, Strawberry Perl 5.42 x64 on a
Windows 11 ARM64 host, main checkout, the code of drop 1 (offset and gate as
shipped). Three runs per variant, interleaved; medians with ranges. The ramp
stopped at 3 days on the architect's direction once a gap between variants
appeared; the 7-day runs were stopped before they finished.

| Stage | 1 day, no `-mem` | 1 day, `-mem` | Δ | 3 days, no `-mem` | 3 days, `-mem` | Δ |
|---|---|---|---|---|---|---|
| `parse/read_files` | 10.31 s [10.05–11.27] | 10.95 s [10.94–11.07] | +0.64 s | 18.06 s [17.89–18.10] | 19.63 s [19.33–19.99] | +1.57 s |
| `finalize/group_similar` | 3.55 s [3.48–3.60] | 4.14 s [3.96–4.23] | +0.59 s | 5.51 s [5.37–5.60] | 7.63 s [7.48–8.00] | +2.12 s |
| every other stage | ~0.5 s | ~0.5 s | ≈ 0 | ~0.8 s | ~0.8 s | ≈ 0 |
| total | 14.14 s [13.79–15.14] | 15.33 s [15.15–15.54] | +1.19 s (+8%) | 23.99 s [23.95–24.31] | 28.03 s [27.47–28.24] | +4.04 s (+17%) |

With `-mem -V memory-usage` the totals were 15.26 s [15.18–16.56] and 27.36 s
[25.34–27.87], within the `-mem` ranges: the counting costs nothing measurable.

The readings themselves: 27 at 1 day (5 phase boundaries, 14 grouping
checkpoints, 6 final-pass windows, 2 around the scan-sub compile), 26.3 to
27.6 ms in all; 30 at 3 days (17 checkpoints), 27.7 to 28.0 ms. The first
reading of a run costs about 22 ms, loading `Win32::API` and binding the
kernel32 calls; every later one 0.15 to 0.25 ms.

**The `-mem` gap is the structure walks, not the reading.** A scratch copy of
`ltl` timing the `named_structure_sizes()` walk inside
`measure_memory_structures()` per caller (`-g -mem -V benchmark-data`; tracked
`ltl` unchanged):

| Caller | 1 day (3 runs) | 3 days (1 run) |
|---|---|---|
| grouping checkpoints, inside `parse/read_files` | 14 walks, 0.77–0.81 s | 17 walks, 1.66 s |
| final-pass windows, inside `finalize/group_similar` | 6 walks, 0.61–0.64 s | 6 walks, 2.05 s |
| phase boundaries, between the stages | 5 walks, 0.49–0.52 s | 5 walks, 1.56 s |

The checkpoint walks match the reading stage's gap and the final-pass walks the
grouping stage's, at both sizes. Each walk grows with the stores it measures:
about 56 ms a checkpoint walk at 1 day and 98 ms at 3 days, 103 ms and 342 ms a
final-pass walk. The walks run under `-mem` on every platform, whatever the
reading costs; on this host the reading is 0.5 to 2% of the `-mem` overhead.
Handed forward to #709 (§ Issue #709, *The structure walks under `-mem` are an
iterative cost*).

### Drops 4 and 5: after the fix, and the analysis (criterion 16)

The same runs on the code of drop 3 (the offset fixed, the gate removed): same
host, checkout, files and options, three runs per variant, interleaved.
Medians with ranges.

| Size | Variant | Before: total | After: total | Before: `rss_peak` | After: `rss_peak` | Readings (time in them) |
|---|---|---|---|---|---|---|
| 1 day | no `-mem` | 14.14 s [13.79–15.14] | 13.46 s [13.43–13.80] | 0 | 183.0 MB [181.7–184.3] | before none; after the same 27 as below |
| 1 day | `-mem` | 15.33 s [15.15–15.54] | 14.32 s [14.21–15.19] | 0.2 MB | 184.4 MB [182.4–185.2] | |
| 1 day | `-mem -V memory-usage` | 15.26 s [15.18–16.56] | 15.35 s [14.44–15.38] | 0.2 MB | 182.9 MB [181.7–185.2] | 27 (before 27.6 ms [26.3–27.6], after 28.2 ms [28.2–30.6]) |
| 3 days | no `-mem` | 23.99 s [23.95–24.31] | 23.42 s [22.97–23.65] | 0 | 281.6 MB [280.8–288.0] | before none; after the same 30 as below |
| 3 days | `-mem` | 28.03 s [27.47–28.24] | 27.12 s [26.77–27.13] | 0.2 MB | 287.8 MB [287.6–288.2] | |
| 3 days | `-mem -V memory-usage` | 27.36 s [25.34–27.87] | 28.18 s [27.02–29.71] | 0.2 MB | 286.4 MB [282.2–288.5] | 30 (before 28.0 ms [27.7–28.0], after 30.2 ms [27.6–30.3]) |

- **Correct.** Before the fix a run reported 0 without `-mem` and 0.2 MB (the
  paged-pool quota) with it. After, it reports 183 MB at one day and 282 to
  288 MB at three days, with and without `-mem`. On the one-day file the
  reported peak was 99.9% of the operating system's peak working set without
  `-mem` and 98.8% under `-mem debug` (drop 3's runs).
- **The reading costs 28 to 30 ms a run.** The readings are the same calls with
  and without `-mem` (the phase boundaries, the grouping checkpoints and
  windows, and the compile pair `-V benchmark-data` arms): 27 at one day, 30 at
  three. About 22 to 25 ms of it is the first reading, which loads `Win32::API`
  and binds the kernel32 calls; each later reading costs 0.15 to 0.25 ms. Over a
  run that is 0.2% at one day and 0.1% at three, below the spread of three runs
  of any variant (0.4 s and more). Removing the gate (D2) adds that to every
  Windows run; the totals without `-mem` measured 13.46 s against 14.14 s and
  23.42 s against 23.99 s, the difference inside the noise.
- **The counting costs nothing measurable.** `-mem -V memory-usage` against
  `-mem` overlaps at both sizes, before and after.
- **What `-mem` costs is the structure walks** (Drop 2), unchanged by the fix:
  0.86 s at one day and 3.70 s at three after the fix, against 1.19 s and
  4.04 s before.
- **Ceiling of the alternative.** The WMI reading #143 replaced took 15 to 20 s a
  call (#143's change record); at 27 to 30 readings a run that would be 7 to 10
  minutes, which is the degradation v0.14.3 avoided by turning the reading off.
  The reading in place now costs four orders of magnitude less, so the reason
  for the Windows exception no longer holds.

### Completion gate

- **Benchmark,** `single-day-access-log-standard`, one run each, on this
  Windows 11 ARM64 host, main checkout: before on the base (7746f41), after on
  the version-restored commit (16133b5). Total 27.6 s before, 24.7 s after,
  inside the spread of repeated runs measured above. `rss_peak` 168.6 KB
  before, 117.7 MB after: the fix itself, a peak that was not being read.
- **Full harness suite: skipped, by the architect's decision.** It ran once on
  this Windows host (91cf248): 32 of 52 harnesses passed. Each of the 20
  failures came from the host, not from this change: Perl writing CR LF, Git
  Bash rewriting arguments that start with `/` into Windows paths, the system
  code page altering non-ASCII text on command lines, `ltl`'s Windows bar
  character against references captured on macOS, and `chmod` not making a
  directory unreadable. The harnesses do not run on Windows
  (`docs/toolchain-guidance.md` § Windows development host), and the gate was
  not re-run on macOS. The commit after the run (23cd2e2) changes only
  `docs/toolchain-guidance.md`.
- **Full harness suite, run after the merge on macOS** (2026-10-16, on
  `release/0.20.0` at 891fe91, the merge and its release-notes commits): 50 of
  52 harnesses passed. `tests/validate-memory-usage.sh`, created on the Windows
  host, had been committed as mode 100644, so it and
  `tests/validate-scenario-selector.sh`, which runs every harness, exited 126
  ("Permission denied"). The bit was set by PR #743 (dbc5bcc, merged as
  f4f1e8d), which also records the trap in `docs/toolchain-guidance.md`
  § Windows development host. On that commit both pass: 23 and 39 assertions,
  none failed.

## Memory Diagnostic Method (from the #356 investigation)

Recorded for future memory investigations; the temporary #356 instrumentation is not retained beyond what S4 specifies.

- **Three-level decomposition.** RSS (`get_memory_usage()`) ⊇ live Perl heap (Devel::MAT dump) ⊇ named structures (`named_structure_sizes()`). RSS − live heap = allocator-retained "dark" memory; live heap − named structures = interpreter + unnamed live data.
- **RSS is a ratchet.** Freed memory below the allocator's trim threshold never returns to the OS. Measuring structures after a phase cannot see a transient burst — only in-phase RSS sampling can localize one (this is what isolated the #362 burst to a single statement).
- **Undef probe.** At exit: measure RSS, `undef` every named structure, re-measure. The amount that does not drop is retained-freed memory (at dev scale: freeing 244 MB of structures released zero pages).
- **Devel::MAT recipe.** `cpanm --notest Devel::MAT`; call `Devel::MAT::Dumper::dump($path)` at the phase of interest; `pmat-counts $path` gives live-heap totals by SV kind. Devel::SizeMe does not build on perl 5.42.
- **Probe gotcha.** Constant ranges (`0..1999999`) are folded at compile time; a standalone probe of range-list cost must use a runtime-variable bound or it will silently measure nothing.
- **Step probes on a scratch copy.** Copy `ltl` to the scratchpad and insert
  `memory_debug_decomposition("<tag>")` at the points of interest inside a
  routine; compare each sample's RSS with its named sum, and read a rise in
  RSS with no rise in the named sum as untracked working memory. Run the
  benchmark's own `-V benchmark-data`: bare `-V` makes grouping keep member
  keys, which enlarges the clusters (211 MB against 239 MB on the one-server
  month).
- **Size-walk gotcha.** `Devel::Size::total_size` on a store holding compiled
  code (the scan-sub cache, the format registry) segfaults the process, exit
  139. Leave those stores to the compile-boundary RSS figure.
- **Churn-rate technique.** Compute the unattributed residual per line at two workload scales; a matching B/line rate attributes the residual to per-line transient allocation (76.2 B/line dev vs 77.5 B/line production for the bin-vs-raw delta).
