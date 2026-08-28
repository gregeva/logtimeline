# Issue #457 — Move the summary section to the end of the output

Branch: `457-summary-section-at-end-of-output` (off `release/0.18.0`)

## Requirement

The summary reports on the run — the span analysed, the files read, category
totals, timing and memory — rather than on log content. Printed between the
timeline bar graph and the message tables it separates two bodies of analysis
content the analyst wants to read together, and the only way to close the gap
was to switch the summary off entirely (`-osum`).

The summary is therefore printed last, after every analysis section. Placement
only: nothing in what the summary contains, or how it is rendered, changes.

## What moved

`print_summary_table()` in `pipeline_render()` now runs after
`print_message_summary()` and `print_threadpool_summary()`, immediately before
the post-output memory measurement and `write_index_file()`.

The echoed options lines did **not** move. They were printed by
`print_summary_table()` ahead of its `-osum` early return; they are now
`print_run_options()`, called from `pipeline_render()` at the position the
summary render used to occupy — directly under the bar graph and any
histograms — so the bytes at that point in the output are unchanged.

Rendered order on the terminal:

| | before | after |
|---|---|---|
| 1 | `-V` sections (`print_verbose_output()`) | `-V` sections |
| 2 | bar graph / heatmap | bar graph / heatmap |
| 3 | histograms (`-hg`) | histograms (`-hg`) |
| 4 | echoed environment / command-line options | echoed environment / command-line options |
| 5 | **run summary** | top-messages tables |
| 6 | top-messages tables | thread-pool tables (`-tpa`/`-tpas`) |
| 7 | thread-pool tables (`-tpa`/`-tpas`) | **run summary** |

## What printed after the summary before the change

Terminal output: the highlighted and overall top-messages tables
(`print_message_summary()`), then the highlighted and overall thread-pool
tables (`print_threadpool_summary()`, only under `-tpa`/`-tpas`), then a
trailing newline. Non-terminal: the MESSAGES CSV header and rows, and the
persistent index file. Nothing else.

## Run-report content that is not part of the summary

| Output | Stream / stage | Disposition |
|---|---|---|
| `-t` per-stage timing rows | rows of the summary's own table | Moved with the summary; no separate handling |
| Echoed `environment options:` / `command-line options:` lines | stdout, their own `print_run_options()` stage | Stay directly under the bar graph, where they were (D1) |
| `-r` unreadable-directory report | stderr, tail of `read_and_process_logs()` | Left where it is. It is a diagnostic about reading the input, on the other stream and in an earlier stage; moving it would relocate it across both |
| Format-ambiguity note, numeric-filter "no metric" note, UDM zero-match notices, bin-consolidation notice | stderr, parse and finalize stages | Unchanged, for the same reason |

## Decisions

**D1 — only the summary table moves; the echoed options stay directly under
the timeline bar graph.** They are extracted into `print_run_options()` and
called from the position the summary render used to hold, so that stretch of
output is byte-for-byte what it was before this issue. Two reasons: the
options belong to the view above them — `docs/purpose.md` states that each view
can be screenshot with the command-line options displayed for reproducibility,
which only holds while the options sit with the timeline they describe — and
under `-osum` moving them would have ended the run on a dangling options line
with nothing under it.
*Consequence:* the run report is no longer one contiguous block. The options
echo is a caption on the timeline; the summary is the closing section, and
`-osum` suppresses that section alone.

**D2 — the peak-memory measurement moves with the summary.** The
`measure_memory_structures()` call that feeds `MAXIMUM MEMORY USED` sits
immediately before the summary render, so the measurement instant is now after
every analysis section has been printed — the message and thread-pool tables
included — rather than before them.
*Consequence:* the reported peak covers more of the run than before and can
read marginally higher on the same input. Measured: 26.9 → 27.0 MiB on the
434-line fixture, no change on the 5k-line access log. It was already
documented as covering "everything up to this point"; the point moved.

**D3 — the regression harness's output filter is bounded, not removed.**
`strip_nondeterministic()` in `tests/capture-regression.sh` and
`tests/validate-regression.sh` dropped everything from the `TOP OVERALL`
heading to end of output. With the summary now below that heading, the same
rule would have silently dropped the summary out of the asserted surface — the
category totals, the `HIGHLIGHTED` row, the file legend and the format legend,
which the highlight scenarios exist to assert. The skip ends on the summary's
first line: the rule above the `Category` header, matched by its shape (two
spaces of indent, box-drawing rule, right padding) rather than by a hard-coded
width, so the wider rules inside the skipped message tables do not close it.
*Consequence:* the asserted surface is unchanged from before this issue; the
`TOP OVERALL` block stays excluded.

**D5 — the bounded skip fails loudly when its closing anchor is absent,
except where no summary is printed.** Ending the skip on a content line makes
the filter silent about a run that never prints one: it would drop the whole
tail and hand back a smaller surface that still compares clean.
`tests/HARNESS-DESIGN.md` § "a grep that matches nothing is a failure" governs
exactly this, so the filter exits 3 when it reaches end of input with the skip
still open, and both harnesses check that status alongside `ltl`'s own. A run
passing `-osum` prints no summary, so for it the skip legitimately runs to end
of output; the filter recognises this from the echoed options line, which
under D1 sits above the skipped block and names the option.
*Consequence:* a truncated surface aborts the capture or fails the scenario
instead of quietly narrowing what is asserted, while the sixty-one `-osum`
scenarios keep the pre-existing skip-to-end behaviour.

**D4 — `docs/usage.md` § Display & Output no longer calls two different things
"the summary table".** The paragraph claimed `-osum` suppressed the
top-messages table, which it never did. The `-n` row now says "top-messages
table" and `-osum` says "run summary", on both surfaces (`print_help()` and
`docs/usage.md`).
*Consequence:* one wording change to a `--help` row that this issue did not
strictly have to touch, made so the section does not use one name for two
tables while restating the ordering.

## Surfaces changed

- `ltl` — `pipeline_render()` call order and its stage comment; the echoed
  options extracted from `print_summary_table()` into `print_run_options()`
  and called from the summary's former position (D1); the `-n` and `-osum`
  rows of `print_help()`.
- `docs/usage.md` — § Display & Output paragraph, the `-n` and `-osum` rows,
  and the `-osum` example comment.
- `tests/capture-regression.sh`, `tests/validate-regression.sh` —
  `strip_nondeterministic()` (D3) and the filter-status check that guards its
  closing anchor (D5); the two copies of the filter remain byte-identical.
- `tests/reference-output/*.txt` — re-blessed, see below.
- `features/180-named-pipeline-stages.md` — stage-10 membership row reordered
  to match the render order.

## Reference re-bless

Re-blessed with the sanctioned procedure, `./tests/capture-regression.sh`; no
golden was hand-edited. Ten of the seventy-one references changed — every
scenario that keeps the summary (the `hl-*` highlight scenarios; the rest pass
`-osum`, and their references are byte-identical to the release branch). Each
changed file was checked against the release branch's version of the same file
and is a pure reordering: sorted, the two are identical, so only placement
moved — the summary block travels below the top-messages table and nothing
else, including the echoed options line, changes position or content.

## Verification

| Check | Result |
|---|---|
| `tests/validate-regression.sh` before the re-bless | 61 passed, 10 failed — every failure a block move of the summary below the message tables, no content difference |
| `tests/validate-regression.sh` after the re-bless | 71 passed, 0 failed, 0 skipped |
| Sabotage proof that the summary is still asserted | One digit changed in the `LINES READ` row of a copied reference: 70 passed, 1 failed, and the failing scenario is the doctored one |
| `tests/validate-help-content.sh` | 11 passed, 0 failed |
| `tests/validate-duration-display.sh` | 21 passed, 0 failed |
| `tests/validate-format-detection.sh` | 192 passed, 0 failed |
| `tests/validate-log-level-vocabulary.sh` | 8 passed, 0 failed |
| `tests/validate-message-control-characters.sh` | 11 passed, 0 failed |
| CSV output (`-o`) | STATS and MESSAGES files byte-identical to the pre-change build on the same input |
| `-V` section sequence | Identical to the pre-change build; no section is emitted by `print_summary_table()`, and the verbose surface flushes before the bar graph |
| `-osum` | Still suppresses the summary; the echoed options print under the bar graph and the output ends with the top-messages table |
| `-t` timing rows | Render inside the summary, at the end |
| Anchor guard (D5) | Filter status probed through the harness's own pipeline shape: summary present → 0, summary absent → 3, `-osum` in the echoed options → 0 |
| Echoed options position (D1) | Byte-identical to the release branch: the ten re-blessed references sort equal to their release-branch versions, and the sixty-one `-osum` references are unchanged |

## Completion gate

Run on `2d3d7de` (`#457: restore release version for the completion gate`), the
commit being merged, after rebasing onto `origin/release/0.18.0` (`b94a75e`,
the #445 quoted-`-r` release-notes commit). The rebase was clean — no
conflicts. `$version_number` reads `0.18.0`.

### Harness suite — 27 of 27 exit 0

| Harness | Summary line |
|---|---|
| `validate-csv-output.sh` | CSV output integrity: 21 scenarios, 21 pass, 0 fail |
| `validate-statistics.sh` | Statistics drift: 21 scenarios, 21 pass, 0 fail |
| `validate-csv-input.sh` | CSV input robustness: 4 pass, 0 fail |
| `validate-distribution-shape.sh` | 8 passed, 0 failed |
| `validate-doc-examples.sh` | 46 passed, 0 failed, 9 skipped |
| `validate-duration-display.sh` | 21 passed, 0 failed |
| `validate-explain.sh` | 148 passed, 0 failed |
| `validate-format-detection.sh` | 192 passed, 0 failed |
| `validate-format-registry.sh` | 22 passed, 0 failed |
| `validate-heatmap-palette.sh` | 85 passed, 0 failed |
| `validate-help-content.sh` | 11 passed, 0 failed |
| `validate-help-layout.sh` | 6 passed, 0 failed |
| `validate-histogram-bin-counters.sh` | 84 passed, 0 failed |
| `validate-histogram-ticks.sh` | Total: 21 \| Passed: 21 \| Failed: 0 |
| `validate-index-read-back.sh` | 59 passed, 0 failed |
| `validate-log-level-vocabulary.sh` | PASS: 8, FAIL: 0 |
| `validate-message-control-characters.sh` | PASS: 11, FAIL: 0 |
| `validate-message-grouping-notices.sh` | 4 passed, 0 failed |
| `validate-numeric-criteria-notices.sh` | 10 passed, 0 failed |
| `validate-profile-render.sh` | 22 passed, 0 failed |
| `validate-profile.sh` | 50 passed, 0 failed |
| `validate-recursive-file-selection.sh` | 22 passed, 0 failed |
| `validate-regression.sh` | 71 passed, 0 failed, 0 skipped |
| `validate-runtime-config.sh` | 36 passed, 0 failed |
| `validate-statistics-demand.sh` | 75 passed, 0 failed |
| `validate-udm-counting.sh` | 28 passed, 0 failed |
| `validate-udm-specs.sh` | 43 passed, 0 failed |

`validate-statistics.sh` tiers: zero T4 and zero T3 on every layer — the drift
check against the committed baselines, the intra-row arithmetic invariants, and
the NumPy/SciPy oracle. 943 T2 advisories, all on the oracle layer and all
pre-existing (they are the tolerance band between `ltl`'s bin-model percentiles
and the oracle's exact ones, not a difference this branch introduced). 31 oracle
cells are registered known failures for #469 (bin-model percentile projection
onto the shared geometry) in `tests/statistics-drift/known-failures.tsv`.

`./tests/cleanup-test-artifacts.sh` run afterwards; the tree is clean.

### Before/after benchmark

`single-day-access-log-standard` (761,698 lines), run back-to-back on this
machine: *before* from a worktree of `origin/release/0.18.0`, *after* from this
branch's gated tip. No metric worse by more than 5%.

| Metric | Before | After | Delta | Change |
|---|---|---|---|---|
| `TIMING/total` | 10 s | 10.0 s | −77 ms | −0.8% |
| `parse/read_files` | 9.9 s | 9.8 s | −80 ms | −0.8% |
| `finalize/calculate_statistics` | 151 ms | 155 ms | +4 ms | +2.6% |
| `finalize/calculate_statistics/bucket_stats` | 100 ms | 104 ms | +4 ms | +4.0% |
| `finalize/calculate_statistics/group_calc` | 46 ms | 45 ms | −1 ms | −2.2% |
| `finalize/calculate_statistics/sort_selection` | 6 ms | 6 ms | 0 ms | 0.0% |
| `detect/registry_build` | 9 ms | 8 ms | −1 ms | −11.1% |
| `render/normalize_data` | 1 ms | 1 ms | 0 ms | 0.0% |
| `MEMORY/rss_peak` | 142.1 MB | 142.3 MB | +144 KB | +0.1% |

The change is a render-order change with no per-line or per-key work added, so
the timing movements are run-to-run noise on a single pair of runs, not
attribution. The +144 KB on peak RSS is the direction D2 predicts — the
measurement instant now sits after the message and thread-pool tables have been
rendered — and it is 0.1%, an order of magnitude inside the 5% threshold.

Both benchmark TSVs were deleted afterwards and the base worktree removed; they
are instruments, not deliverables.
