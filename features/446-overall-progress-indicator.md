# Feature: Overall progress indicator across all files (#446)

## Overview

The progress line reports the file in flight — its line count and, since #397 (percentage-based progress per file), its byte-position percentage. A run over many files (`-r` can select thousands) gives no sense of where the run as a whole stands. This drop adds an overall percentage and a file counter to the same line, and reshapes the line so its numbers stay put while the filename changes.

## GitHub Issue

- #446 — Add overall percentage progress indicator to read and process logs
- Extends #397 (per-file percentage progress) and follows #420 (`-r`/`--recursive` file selection).

## Status

Scoped 2026-08-29; decisions D1–D7 locked. Implemented 2026-08-29 on
`446-overall-progress-indicator`, all seven decisions as written.

## Research

`docs/progress-indication-best-practices.md` — the survey of how rsync, APT, dnf, git, the Windows shell copy engine, curl, rclone, restic, 7-Zip and others weight file count against bytes, refresh their display, and reach 100 %. The decisions below apply it.

## Requirements

- **R1.** With two or more files selected, the progress line shows the run's overall completion as a percentage, and the position of the current file in the list (`file i/N`).
- **R2.** The overall percentage is **bytes-based**: bytes consumed across the whole selected set over the total size of the selected set. The file count is a companion counter; it never enters the percentage.
- **R3.** 100 % means finished: every byte of every file has been consumed and no reading remains. The figure is floored, never rounded, so it cannot appear before that is true. It need not ever be printed — `Processing completed.` replaces the line — but if it appears, reading is over.
- **R4.** With one file the run behaves exactly as today: no size sweep, no overall figure, no counter. Two identical percentages side by side say nothing.
- **R5.** Post-read phases (consolidation, statistics, heatmap, normalisation) are outside the indicator, as today.

## Locked decisions

**D1 — Bytes own the percentage; the file counter is shown beside it, unweighted.** The dominant industry pattern (rsync `progress2`, dnf, rclone, restic, PowerShell, 7-Zip, curl `--parallel`); no blend, no per-file weighting constant, nothing to calibrate. The counter is what keeps a many-tiny-files run honest while the percentage stays true for a few huge files. Rationale and the rejected alternatives (APT's 80/20 blend, the Windows points model, runtime-calibrated overhead): `docs/progress-indication-best-practices.md` § *The candidate algorithms*.

**D2 — The total is taken once, before the first file is opened, only when the list has two or more entries.** The selected list is already final at the end of `adapt_to_command_line_options()` (after `-f` filtering and `-r` de-duplication), so one `stat` sweep over it yields N and Σ size exactly. No change to the traversal itself: sizing during `expand_recursive_pattern()` would put it in two places (the `-r` path and the glob path), against the one-resolution-surface rule. Numerator: sizes of completed files plus the live `tell` offset of the file in flight; a file's contribution rolls from `tell` to its stat size when it closes, so the figure is monotonic.

**D3 — A skipped file is credited its full size at the moment it is skipped** — unreadable, empty, or otherwise not read. The denominator counts every selected file; a run that skips files must still reach 100 % (rsync's documented asymmetry is the trap). The figure is clamped at 100 (a file can grow while being read); a zero total prints no percentage rather than dividing.

**D4 — The repaint gate is time-based: 500 ms, a named code constant, no option.** Today's gate (`$total_lines_read % 4999 == 0`) repaints on work, not time: fast input hammers the terminal, slow input looks frozen, and a small file can pass with no repaint at all (the #31 symptom, half-fixed by moving the modulo to the run total). Every surveyed tool throttles on time (rsync 1000 ms, curl/APT/rclone 500 ms, dnf 300 ms). The clock is consulted at a cheap per-line modulo (a few hundred lines), not every line — `Time::HiRes::time()` per line is a real cost at 150k lines/sec — and the repaint happens when ≥ 500 ms have elapsed since the last one. A final frame or the completion line is emitted unconditionally outside the throttle.

**D5 — The line is reshaped: fixed-width numerics first, the filename last.** The filename is the only element whose length changes from file to file, so it goes at the end where it cannot shift anything; percentages are rendered by the shared percentage formatter (`docs/percentage-presentation.md`; this surface's parameters: integer, 3 characters fixed, floored) and the file index is padded to the width of N; every count goes through `format_number()`, as today's total and rate already do. The verb stays: the line reports the work presently underway.

Multi-file:

```
Processing 63%/37% (file 12/340) line 412.0k, 1.2Mil total, 148.2k lines/sec: access.2025-05-07.log
```

Single file:

```
Processing 63% line 412.0k, 148.2k lines/sec: access.2025-05-07.log
```

Reading: file percentage over overall percentage; `line` is the position in the current file; `total` is lines read across the run (replacing today's "overall", which now names the percentage). The filename is shortened to fit the terminal (existing `shorten_filename()` budget), and if even the shortened name cannot fit, the rate segment is dropped before the name.

**D6 — Suppression is `--disable-progress` only.** The indicator is a progress surface; it rides the existing gate and gets no option of its own.

**D7 — No prototype.** No new data model; the per-line cost is one modulo check, which the existing tick already pays. The gate is time-based, so the change touches the hot path: the before/after benchmark (per-feature step 1b) is mandatory and is the instrument for D4's check cadence.

## In-drop obligations

- Sizes are already taken in up to three other places (the per-file `-s` at open, `read_index_file()`'s `stat`, the `-V benchmark-data` FILES row recompute). Reuse the D2 sweep where a consumer runs after it and the value is identical; do not change what the index record or the FILES row emit — both are harness-asserted.
- No harness asserts the progress line today (all run `--disable-progress`). A dedicated scenario that runs *without* it against a small multi-file fixture and asserts the line shape, the final frame, and the absence of progress text under `--disable-progress` closes the gap.
- The line clear (`" " x ($terminal_width - 1)`) must cover the longest form of the new line.
- `docs/toolchain-guidance.md` describes progress output as including an ETA and a spinner; neither exists. Correct the sentence while the surface is being edited.
- `features/log-format-registry.md` (D53 and the #388 deliverables list) still names the detection sample as the source of a progress percentage; the shipped per-file percentage reads the handle position, and so does this one. Correct the record.

## Implementation (2026-08-29)

The size sweep is `size_selected_files_for_progress()`, called from the end of `adapt_to_command_line_options()` where the selected list is final. It returns without doing anything under `--disable-progress` or below two files, so `$progress_file_count` staying 0 is what every downstream site reads as "no overall figure this run". The line is rendered by `progress_line_text()`, which both paint sites call; the percentages go through `format_percentage()` with `mode => 'integer', width => 3, floor => 1` and the counts through `format_number()`.

**Reuse of the sweep.** `$progress_file_size` at the top of the per-file loop was a second `-s` over the same file; it now reads the sweep's cached size where the sweep ran. The other two size sites are untouched, as the obligation requires: `read_index_file()` needs the full `stat` for the mtime as well, so it saves nothing, and the `-V benchmark-data` FILES row sums `@files_processed` — the files actually read — which is a different set from the selected list and is harness-asserted as it stands.

**The opening frame.** D4 requires a frame outside the throttle. It is painted once per file, just before the read loop, rather than only at end of run: with a 500 ms gate alone, a run that finishes inside one interval reports nothing at all, which is exactly the small-file symptom of #31 that D4 names the work-based gate as having half-fixed. The completion line still closes the run, so nothing is left parked below 100 %.

**The line clear.** `progress_line_text()` fits the line to `$terminal_width - 1` characters — the prefix plus whatever the filename can have — which is precisely what the existing clear writes, so no widening was needed. One guard was: `shorten_filename()` declines to shorten below ten characters and returns the name whole, so the line truncates outright at that point rather than overrunning.

**Notices are held until the read ends.** The progress line owns the terminal row for the whole read pass, so a notice printed at the moment it is discovered lands mid-row and reads as a continuation of the progress text. This is long-standing expected behaviour for the tool, and the two notices at the end of `read_and_process_logs()` (the numeric-filter and unreadable-directory counts) already followed it. Three did not, because their condition is discovered mid-read: the impossible-date signal, the variant-ambiguity note, and the classification-rule-change note. They now call `defer_notice()`, and `flush_deferred_notices()` empties the queue once the read is over, in the order the notices were raised. The rule for anything added later: a notice whose condition is known during the read is deferred; one whose condition is only known afterwards prints directly, being already past the progress line. Suppression is unaffected either way — a behavioural notice always prints, `--disable-progress` or not.

**Why the harness did not catch the collision.** `tests/validate-progress-line.sh` runs with the progress line on — that is its subject — but every scenario pinned the format with `-lf`, which keeps the run deterministic *and* suppresses the unit-ambiguity note, the only notice this fixture can raise. It also captured stdout and stderr to separate files. Both choices are right for asserting the line's shape and wrong for asserting that nothing writes over it: the collision exists only when a mid-read notice is raised and the two streams share a row. The `notice-not-in-progress-row` scenario closes it — no `-lf`, streams interleaved — with an anchor asserting the notice is actually raised, so the scenario fails rather than passes silently if a future format change makes this fixture unambiguous. The general lesson for this surface: a scenario that pins away the conditions that make a run interesting can only assert the quiet path.

### Findings

- **F1 — D4's clock check is not measurable.** Read pass over the 762k-line single-day access log with the progress line painting, three runs each: before 2.76 / 2.60 / 2.53 s, after 2.50 / 2.51 / 2.51 s. The new gate is if anything marginally cheaper than the every-4,999-lines gate it replaces, and well inside run-to-run variance either way. The stride is what buys this: at 512 lines the clock is consulted about 1,500 times over a 762k-line file, so `Time::HiRes::time()` never approaches the per-line path.
- **F2 — the release benchmark cannot see D4 at all, and this is worth knowing before it is read as evidence.** `run-benchmark.sh` invokes `ltl --disable-progress`, so the progress block is short-circuited on both sides of the comparison. Two before/after pairs of `single-day-access-log-standard` ran -3.1 % and then +2.6 % on total time, with the four absolute figures interleaving (before 9.9 / 9.4 s, after 9.6 / 9.8 s): variance on a ten-second run, not attribution. The gate passes — no metric worse than 5 % in either pair — but the instrument for D4 is F1's progress-on measurement, not this one.

## Merge gate

Touches `ltl` and adds a harness scenario: the full `tests/validate-*.sh` suite plus the before/after benchmark on this machine (CLAUDE.md per-feature step 1), the benchmark being load-bearing here (D4).

Run 2026-08-29 on the merged commit: 30 harnesses, 1,354 assertions passed, 3 failed. All three failures are `validate-regression.sh` scenarios (`errrate-access-unhighlighted-w160`, `errrate-access-highlighted-failure-w160`, `errrate-diagnostics-highlighted-failure-w160`) and are pre-existing and unrelated: the committed references carry an absolute path from another worktree (`/Users/gregeva/Documents/GitHub/ltl-448/tests/fixtures/...`) where the run correctly produces the repo-relative path, which is the condition #209 removed. The same three fail identically on the branch-point commit with this drop's code absent.

## Related

- #397 (per-file percentage progress) — the predecessor; its line is what D5 reshapes.
- #420 (`-r`/`--recursive`) and #445 (unquoted glob consumed by the shell) — produce the long lists; the denominator is the *selected* set, never the tree.
- #181 (buffered read pipeline, on hold) — would change what "bytes consumed" means; D2 states the numerator as bytes processed, which survives it.
- #412 (notices surface) — progress lines are transient and self-clearing; notices are persistent. No overlap.
