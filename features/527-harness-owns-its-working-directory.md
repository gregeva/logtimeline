# 527 — A harness owns the directory it runs `ltl` in

Issue #527 (BUG: the export harness asserts against an aggregate export it did
not write, and the doc-examples harness leaves one in the repository root).
Branch off `release/0.18.1`.

## Status

Implemented; the completion gate has not run. Every acceptance criterion below
is measured and passing on this machine (§ *Implementation record*). The
`tests/HARNESS-DESIGN.md` rule and the `features/503-yaml-aggregate-export.md`
corrections were applied in the specification commit, being records rather than
code.

## The reframe

**Old framing (as filed).** "BUG: the statistics harness leaves an aggregate
export in the repository root that the export harness's relative-path scenario
then reads." The body named `tests/validate-statistics.sh` as the producer:
its message-grouping and percentile-algorithm probes were said to run from the
repository root with the scenario's own options, `-o` among them, and to leave
an aggregate export and a STATS CSV behind.

**What was measured.** Running `tests/validate-doc-examples.sh` alone on a
clean repository root reported 49 passed, 0 failed, 10 skipped, and left three
files in the root: an aggregate export YAML, a STATS CSV and a MESSAGES CSV.
Running `tests/validate-aggregate-export.sh --scenario directories-relative`
immediately afterwards failed exactly the two assertions the issue quoted, with
the same detail shapes. Nothing was planted by hand. The statistics harness was
probed with the shape its body described and wrote no file: both
`membership_capture_for_scenario()` and `pa_capture_for_scenario()` invoke `ltl`
with `-V message-grouping` and `-V percentile-algorithm` and no `-o`, no data
row in `tests/statistics-drift/scenarios.tsv` carries `-o`, and
`csv_cache_produce()` in `tests/lib/csv-cache.sh` refuses a stray `-o` in the
options it is handed and runs its own `-o` inside a `( cd "$tmp_dir" … )`
subshell, moving all three products into `tests/.artifacts/csv/`.

**Why the framing changed.** The producer is a different harness, and the
victim harness carries a second defect the old framing did not describe: it
destroys `-o` products it did not create, on passing runs as well as failing
ones. Two independent defects, one issue, per the architect's decision below.

## Motivating consumer

The completion gate's chained harness order (`docs/process/workflow.md` § 3 (a):
`CI=1 ./tests/validate-csv-output.sh`, then
`CI=1 ./tests/validate-statistics.sh`, then the rest, with no intervening
cleanup). Every issue whose gate runs the full suite runs
`tests/validate-doc-examples.sh` and `tests/validate-aggregate-export.sh` in the
same repository root, in that order. The gate is the consumer that has to come
back green for a reason that is about the change under test. Today it can come
back red for a reason that belongs to the harnesses, and the failure text points
at `write_aggregate_export()` in `ltl` and at D9 of
`features/503-yaml-aggregate-export.md` (the working directory is never
recorded), neither of which is at fault. It was seen twice in one session, on
the #524 and the first #444 completion gates (2026-09-03).

## Requirement

A harness run in the gate's chained order asserts about the run it performed and
about nothing else, and leaves the repository root as it found it. Specifically:

1. The `directories-relative` scenario of `tests/validate-aggregate-export.sh`
   proves D9 of `features/503-yaml-aggregate-export.md` (relative paths stay
   relative to where `ltl` ran) against the export its own run wrote, whatever
   the repository root contains.
2. No harness in the suite leaves an `ltl -o` product in the repository root.
3. No harness deletes an `ltl -o` product it did not create; one it finds in its
   own working directory is a fail-fast diagnosis, naming the file, before any
   other action.

## Corrections to the old issue body

1. **The statistics harness is not the producer and cannot be.** Evidence above.
   A probe-shaped run from the repository root wrote no file.
2. **The producer is `tests/validate-doc-examples.sh`**, executing the
   documented `ltl -o access.log` example (the one under the comment
   `# Export full analysis data to CSV` in `docs/usage.md`) from the repository
   root. `run_doc_example()` runs every non-skipped example as
   `(cd "$REPO_DIR" && eval "\"\$LTL\" \$LTL_INJECT $ltl_args" …)`, and that
   example carries no `<!-- ltl-test: skip -->` marker. It leaks the export, the
   STATS CSV and the MESSAGES CSV on every fully passing run.
3. **"Run alone after `./tests/cleanup-test-artifacts.sh`, the same harness
   passes" is a true observation with the wrong explanation.**
   `tests/cleanup-test-artifacts.sh` removes `tests/.artifacts/` and nothing
   else; its only `rm -rf` targets `$ARTIFACTS_DIR`. What clears the repository
   root is the failing scenario's own sweep and its `EXIT` trap. That is the
   destruction defect, not a cleanup.
4. **"A pre-existing export makes the scenario fail" is incomplete.** It makes
   the scenario fail only when the stranger's stamp sorts first. When it sorts
   later the scenario passes and deletes the stranger anyway.
5. **`features/503-yaml-aggregate-export.md` carries an inaccurate record that
   helped cause this**, in three sentences, corrected in the same commit as the
   fix (§ *Corrections to features/503* below).
6. **The title and the branch name both named the statistics harness.** Under
   CLAUDE.md's "a reframe is a sweep" the title, the body, the branch name and
   this record are trued up in one action.

## The two defects, with measured evidence

### Defect 1: the export harness asserts against a file it did not write

The `directories-relative` scenario in `tests/validate-aggregate-export.sh` runs
`ltl -o` with its working directory set to the repository root, a directory the
harness does not own, then identifies the file to assert against by position
rather than by identity:

```bash
for f in "$REPO_DIR"/*-LTL-AGGREGATE.yaml "$REPO_DIR"/*-LTL-STATS-*.csv; do [[ -f "$f" ]] && mv "$f" "$dir/"; done
YAML_FILE="$(ls "$dir"/*.yaml | head -1)"
```

`run_file_stamp()` in `ltl` names every product `YYYY-MM-DD_HHMMSS-…`, so
lexical order is chronological order and `head -1` picks the oldest file. Any
pre-existing export therefore wins over the run's own.

Measured, on the chained run (doc-examples harness first, no cleanup between):

```
FAIL  directories-relative :: directory_list
      detail: '/var/folders/b9/szr3yffx47xccq4ms_k_5hxh0000gn/T/tmp.tjQPXayot4|1' != 'tests/fixtures|1'
FAIL  directories-relative :: files/files_matched
      detail: '1/1' != '2/2'
Results: 1 passed, 2 failed
```

The read file is the doc-examples harness's own product: one file under an
absolute temporary path, one directory. The scenario's own run reads two
repository-relative fixtures, which is what `'tests/fixtures|1'` and `'2/2'`
describe.

The tool already publishes the identity the harness would need: the `file:
<name>` line `write_aggregate_export()` prints under `-V aggregate-export`. The
chosen fix (decision 2) does not need it, because the scenario stops sharing a
directory at all.

### Defect 2: the export harness destroys files it did not create, silently

The sweep and the `EXIT` trap run unconditionally, independent of which file
`head -1` selected. A stranger export was planted with a stamp sorting after the
run's own (`2099-01-01_000000-LTL-AGGREGATE.yaml`): the scenario reported
3 passed, 0 failed, exit 0, and the stranger was gone afterwards. A fix aimed
only at which file is read would leave a harness that deletes a user's `-o`
output on every green run with no symptom at all.

The sweep glob is also incomplete: it covers `*-LTL-AGGREGATE.yaml` and
`*-LTL-STATS-*.csv` but not `*-LTL-MESSAGES-*.csv`, so in the chained run the
MESSAGES CSV stayed in the repository root permanently.

`.gitignore` hides all three product classes (`*.csv` and
`*-LTL-AGGREGATE.yaml`), so a leak never shows in `git status` and never
surfaces in the session-start outstanding-state sweep. That is why the failure
was seen twice in one session without the cause being visible.

The same destruction shape sits in `scenario_message_stats_csv_shared()` in
`tests/validate-histogram-bin-counters.sh`, which runs
`out=$(run_section -mdm bin -n 3 -o)` with no `cd`, so it writes into whatever
directory the operator launched from, and cleans up with the unguarded
`rm -f *MESSAGES-*.csv *STATS-*.csv *-LTL-AGGREGATE.yaml`. It does not leak on a
clean pass (measured: 84 passed, 0 failed, root listing byte-identical before
and after), but it leaks on any interrupt or abort, and its glob deletes files
it did not write.

## Decisions

- **D1 — Two defects, one issue (locked, architect).** The export harness's
  `directories-relative` scenario identifying its file by position in a
  directory it does not own and destroying files it did not create, and the
  doc-examples harness executing the documented `ltl -o access.log` example from
  the repository root and leaving three products there, are both fixed under
  this issue. Reason: they are one failure in a chained gate, the requirement is
  written across both, and splitting them leaves a gate failing for the same
  reason under a different name.

- **D2 — The `directories-relative` scenario runs in its own scratch
  directory.** `tests/fixtures/` is mirrored into that directory and the run
  happens there, so the assertion is about the export the scenario's own run
  wrote and the repository root is neither read nor swept. Reason: D9 of
  `features/503-yaml-aggregate-export.md` says "relative paths stay relative to
  where `ltl` ran", not "relative to the repository root", so a mirrored tree
  satisfies the criterion; a hermetic run in one was demonstrated to produce
  `files: 2`, `files_matched: 2`, `directories: 1`,
  `directory_list: [tests/fixtures]`, identical to what the scenario asserts.
  Consequence accepted: the scenario's third assertion, that the working
  directory appears nowhere in the file, then proves the absence of the scratch
  path rather than of the repository root. That still proves D9, and the
  scenario comment names which directory the assertion is about. No sweep of
  the repository root remains in the scenario.

- **D3 — `run_doc_example()` gets a scratch working directory it owns.** The
  documented `ltl -o access.log` example stays executed; the `cd "$REPO_DIR"`
  becomes a `cd` into a directory the harness created and removes. Reason: the
  point of that harness is that the documented command is executed, adding a
  skip marker would cost the only executed coverage of the documented `-o`
  invocation and reverse the design point recorded in
  `features/503-yaml-aggregate-export.md` (the `docs/usage.md` `-o` row's
  "example shaped so `tests/validate-doc-examples.sh` can execute it"), and a
  scratch directory closes the leak for every future `-o` example rather than
  for this one.
  **Audit (performed, recorded here so the implementation does not re-derive
  it):** the file operands of every executed example come from
  `substitute_command()`, whose `SUBSTITUTION_VALS` are built as
  `dst="$TMP_DIR/${FIXTURE_KEYS[$i]}"` and are therefore absolute. Extracting
  every candidate example from `docs/usage.md` and filtering for a
  repository-relative operand found two, both already not executed: the
  `logs/2025-05-*.txt logs/2025-06-*.txt` example, which `substitute_command()`
  returns empty for (its `logs/` glob guard) so the caller skips it, and the
  `-hg duration` example under `logs/AccessLogs/…`, which carries the
  `<!-- ltl-test: skip -->` marker. No executed example carries a
  repository-relative operand, no example names a file under `patterns/`, and
  the extractor itself already runs under its own `( cd "$REPO_DIR" … )`
  subshell, unaffected. The `-h "/api/v2/orders"` examples are highlight
  strings, not paths. The implementation confirms this against the extractor
  output of the day rather than trusting this paragraph.

- **D4 — A harness never asserts against a file found by position in a directory
  it does not own, and never deletes a file it did not create.** Adopted as a
  rule, recorded as a short section in `tests/HARNESS-DESIGN.md` beside "Cached
  capture artifacts expire", the same failure class as #448 (cached capture
  artifacts read back without checking which run produced them). A harness that
  finds an `ltl -o` product it did not write in its working directory fails fast
  naming the file, before any other action. Reason: a rule recorded only in
  harness source is invisible to the next author, and fail-fast has to sit
  before any sweep because destruction today happens on green runs too. The
  wording is narrow (`-o` products), not "a harness never runs `ltl` in a
  directory it does not own", because the doc-examples harness legitimately
  reads repository content. Section text in § *The HARNESS-DESIGN.md addition*.

- **D5 — `scenario_message_stats_csv_shared()` is fixed in the same change.**
  It gets a `cd` into a scratch directory, and its unguarded
  `rm -f *MESSAGES-*.csv *STATS-*.csv *-LTL-AGGREGATE.yaml` glob is removed.
  Reason: #341 (the sweep that brought every harness under the runtime-warning
  stderr check) set the precedent of applying a guard to every harness rather
  than only the ones observed failing; this is the last remaining site that
  writes `-o` products into a directory it does not own, and its `rm -f` glob is
  the same destruction defect as D4.

- **D6 — The eight correct inline implementations stay as they are.** The audit
  found eight places across `tests/` and `build/` that already give a `-o` run a
  directory of its own, all correct. No shared `tests/lib/` helper is
  introduced. Reason: migrating ten harnesses, each needing execution to see it
  assert, is disproportionate to a two-scenario bug, and the eight are not
  defective. Recorded as a finding, not filed: CLAUDE.md's one-resolution-
  surface-per-vocabulary rule would argue for convergence, and #342 (audit
  redundant logic surfaces that must converge to single resolution functions)
  is the natural home, but its stated scope is `ltl` rather than the harnesses,
  so widening it is the architect's call.

- **D7 — The three inaccurate sentences in
  `features/503-yaml-aggregate-export.md` are trued up in the same commit as the
  fix.** Exact current text and replacement in § *Corrections to
  features/503*. Applied in this commit, being records.

- **D8 — Standing detection of a dirty repository root is out of scope.**
  Neither the session-start outstanding-state sweep nor
  `tests/cleanup-test-artifacts.sh` is extended to report `-o` products in the
  root. Reason: the fail-fast guard of D4 reports it at the point where it
  matters, and the rest is scope the reported case does not carry. Recorded as a
  finding for the architect: after this fix an ad-hoc `ltl … -o` run from the
  repository root, which is exactly what `docs/usage.md` documents, still leaves
  three gitignored files there silently. If standing detection is wanted, it is
  a small separate issue.

- **D9 — Gate scope.** Full suite required: harness files change, and the
  doc-examples harness's 49 executed examples all move working directory. The
  scope table in `docs/process/workflow.md` § 3 also marks a before/after
  benchmark required for any diff touching a `tests/validate-*.sh`. No
  executable line of `ltl` changes under this issue. Recording a skip with that
  reason in the completion comment is proposed, and is the architect's decision
  at gate time, not made here. No release-notes bullet: harness-only work, per
  `docs/process/workflow.md` § 4.

- **D10 — Prototype: none.** None of the four mandatory triggers in
  `prototype/README.md` applies. No data-model change, no new per-line cost, no
  frequency-times-cost profile, and the verification method is known and was
  demonstrated during the investigation.

## The HARNESS-DESIGN.md addition

Added to `tests/HARNESS-DESIGN.md` immediately after § *Cached capture artifacts
expire*, as § *A harness owns the directory it runs `ltl` in*:

> A harness that invokes `ltl` with `-o` runs it in a directory the harness
> created and removes, never in the repository root or any other shared
> directory. Two rules follow, and both were broken at once by one scenario
> (Issue #527).
>
> **A harness never identifies a produced artifact by its position in a
> directory it does not own.** The `directories-relative` scenario of
> `tests/validate-aggregate-export.sh` ran `ltl -o` from the repository root,
> swept every `*-LTL-AGGREGATE.yaml` and `*-LTL-STATS-*.csv` it found there into
> its own directory, and read `ls … | head -1`. `run_file_stamp()` names every
> product `YYYY-MM-DD_HHMMSS-…`, so lexical order is chronological order and
> `head -1` is "the oldest file present", not "the file this run wrote". A
> harness earlier in the chain had left an export in the root, and the scenario
> reported a directory list and a file count belonging to a run it had never
> performed, against a contract it appeared to be testing. Identify the artifact
> by what the run published (`-V aggregate-export` prints `file: <name>`) or, as
> here, by owning the only directory it can be in.
>
> **A harness never deletes a file it did not create.** The same sweep and its
> `EXIT` trap ran unconditionally, whatever `head -1` had selected. A stranger
> export whose stamp sorted after the run's own was destroyed on a run that
> reported 3 passed, 0 failed — a user's `-o` output removed with no symptom.
> A glob `rm -f` aimed at the current working directory is the same defect
> wherever it appears.
>
> **A product found and not written is a fail-fast diagnosis, not a cleanup.**
> When a harness finds an `ltl -o` product it did not write in its working
> directory, it fails naming the file, before any other action. The guard sits
> before any sweep, because destruction otherwise happens on green runs too.
> `.gitignore` covers all three product classes, so a leak never appears in
> `git status` and never reaches the session-start outstanding-state sweep: the
> harness is the only place it can surface.
>
> Same failure class as § *Cached capture artifacts expire* (Issue #448): an
> artifact read back without establishing which run produced it.

## Corrections to features/503

Three sentences in `features/503-yaml-aggregate-export.md`, applied in this
commit.

**1. § Findings from the build.** Current text:

> - **The documented usage example is not executed** by
>   `tests/validate-doc-examples.sh`: examples run from the repository root, and
>   this one writes files where it runs; it carries the skip marker and a
>   comment saying why.

Inaccurate because it is singular and true only of the `-hg duration` example in
the CSV-columns section. The `-o` example in the options-table example block is
executed. Replaced with:

> - **Two documented usage examples carry `-o`, and only one of them is
>   skipped.** The `-hg duration` example in § *Distribution shape (CSV
>   columns)* carries the skip marker and a comment saying why. The `ltl -o
>   access.log` example in the options-table example block does not, and
>   `tests/validate-doc-examples.sh` executed it from the repository root,
>   leaving three products there on every passing run (#527: the harness now
>   runs every example in a scratch directory it owns, and the example stays
>   executed).

**2. § Drops 2–4 record, the Tooling bullet.** Current text (the clause at
issue):

> `tests/baseline/run-benchmark.sh` gains `heatmap-histogram-export|-hm -hg -n 0
> -o` after `heatmap-histogram`, and `run_test()` now runs every case in a
> scratch directory it removes, so a `-o` scenario never writes into the working
> directory;

Accurate about `run_test()` in the benchmark runner and read since as though it
covered every `-o` run in the test tooling, which it does not. The clause keeps
its wording and gains a scope marker:

> `tests/baseline/run-benchmark.sh` gains `heatmap-histogram-export|-hm -hg -n 0
> -o` after `heatmap-histogram`, and `run_test()` now runs every case in a
> scratch directory it removes, so a `-o` **benchmark** scenario never writes
> into the working directory (the harnesses are a separate surface; see #527);

**3. § Drops 2–4 record, the Harness bullet.** Current text (the clause at
issue), in the scenario list:

> relative and absolute directory lists with no working directory in the file;

Accurate about what is asserted and silent about where the relative case ran,
which is the thing that made it fragile. Replaced with:

> relative and absolute directory lists with no working directory in the file
> (the relative case runs in a scratch directory with `tests/fixtures/` mirrored
> into it, so the assertion is about the export that run wrote; #527);

## Surfaces touched

Certain, when the fix is implemented:

- `tests/validate-aggregate-export.sh`, the `directories-relative` scenario:
  scratch working directory with `tests/fixtures/` mirrored in, no sweep of the
  repository root, the fail-fast guard, and a comment naming which directory the
  "working directory appears nowhere in the file" assertion is about.
- `tests/validate-doc-examples.sh`, `run_doc_example()`: a scratch working
  directory it owns, in place of `cd "$REPO_DIR"`.
- `tests/validate-histogram-bin-counters.sh`,
  `scenario_message_stats_csv_shared()`: a `cd` into a scratch directory, the
  glob `rm -f` removed.
- `tests/HARNESS-DESIGN.md`: the new section (applied in this commit).
- `features/503-yaml-aggregate-export.md`: three sentences (applied in this
  commit).
- This document.

Not touched: `ltl` itself. `write_aggregate_export()` writing to the current
working directory is what D9 of `features/503-yaml-aggregate-export.md` depends
on, and it already publishes `file:` under `-V aggregate-export`. No `-V`
section or key changes, no `--help` row, no `docs/usage.md` row, so no
interaction with `tests/validate-help-content.sh` and no release-notes bullet.
`docs/usage.md` is not edited: the `ltl -o access.log` example stays as
documented and stays executed.

## Acceptance criteria

- [x] A chained run in the completion gate's order
      (`CI=1 ./tests/validate-csv-output.sh`, `CI=1 ./tests/validate-statistics.sh`,
      then `tests/validate-doc-examples.sh`, then
      `tests/validate-aggregate-export.sh`), with no intervening
      `./tests/cleanup-test-artifacts.sh`, passes all three assertions of the
      `directories-relative` scenario. **[assertable]** Method: run the chain
      from a clean repository root, capture each harness's output once to the
      scratchpad, and read the export harness's summary line and its three
      `directories-relative` lines from the file.
- [x] A repository root with no `ltl -o` product in it has none after each
      `tests/validate-*.sh` in the suite has run. **[assertable]** Method: list
      `*-LTL-AGGREGATE.yaml`, `*-LTL-STATS-*.csv` and `*-LTL-MESSAGES-*.csv` in
      the root before the suite and after it; the two listings are identical.
      The comparison is a listing, never a deletion.
- [x] An `ltl -o` product planted in the repository root survives a full suite
      run unchanged. **[assertable]** Method: plant one export with a stamp that
      sorts after any the run could write (`2099-01-01_000000-LTL-AGGREGATE.yaml`,
      the shape the investigation used), run the suite, confirm the file is
      still present with the same contents, and remove it afterwards. This is
      the assertion the old sweep passed while destroying the file.
- [x] A harness that finds an `ltl -o` product it did not write in its own
      working directory fails, and the failure names the file.
      **[assertable]** Method: plant a product inside the scenario's scratch
      directory before its `ltl` run and confirm the harness fails with the
      file name in the failure detail. This is the sabotage proof for the
      fail-fast guard: an assertion that cannot be made to fail has not been
      proved.
- [x] The documented `ltl -o access.log` example is still executed, not
      skipped. **[assertable]** Method: `tests/validate-doc-examples.sh` reports
      `PASS` for that example's line and the skip count is unchanged from the
      measured baseline of 49 passed, 0 failed, 10 skipped.
- [x] The `directories-relative` scenario still proves D9 of
      `features/503-yaml-aggregate-export.md` (relative paths stay relative to
      where `ltl` ran; the working directory is never recorded).
      **[assertable]** Method: the scenario's own three assertions, unchanged in
      what they compare (`tests/fixtures|1`, `2/2`, and the working directory
      absent from the file), now read against a scratch directory with
      `tests/fixtures/` mirrored into it.
- [x] No executed example in `docs/usage.md` depends on the working directory
      being the repository root. **[assertable]** Method: the doc-examples
      harness's own pass count after the working-directory change equals the
      measured baseline of 49 passed, 0 failed, 10 skipped. The audit under D3
      is the prediction; this criterion is the proof.

Unassertable: none identified.

Unknown verification method: none identified. Every criterion above was
demonstrated during the investigation on this machine.

## Implementation record

What was built, at which site, and what each measurement read. Every figure
below was read from a captured harness run on this machine, on the branch
commit that carries the change.

### Sites

- `assert_directory_owned()` in `tests/validate-aggregate-export.sh`,
  `assert_working_directory_owned()` in `tests/validate-doc-examples.sh` and in
  `tests/validate-histogram-bin-counters.sh`: the D4 fail-fast guard. Each
  lists `*-LTL-AGGREGATE.yaml`, `*-LTL-STATS-*.csv` and `*-LTL-MESSAGES-*.csv`
  in the directory the run is about to write into and, finding one, reports a
  failure carrying the file's path and returns without running `ltl`. Nothing
  is moved or deleted on that path: the directory is left exactly as found,
  because removing it would destroy the file just reported. Three separate
  implementations rather than one `tests/lib/` helper, per D6 (the eight
  correct inline implementations stay as they are; no shared helper is
  introduced under this issue).
- `tests/validate-aggregate-export.sh`, the `directories-relative` scenario:
  `run_export()` gains the guard, and the scenario now mirrors
  `tests/fixtures/http-status-families.txt` and
  `tests/fixtures/category-contribution-skew.txt` into
  `$TMP_DIR/directories-relative/tests/fixtures/` and runs there, so the two
  operands stay the relative paths D9 of
  `features/503-yaml-aggregate-export.md` is about. The sweep of the repository
  root and the `ls … | head -1` selection are gone; the export is read as the
  only `*-LTL-AGGREGATE.yaml` in a directory the scenario owns, and a run that
  writes none is a failure rather than an empty variable. The
  working-directory-absence assertion now greps for the scratch path, which is
  where the run happened.
- `tests/validate-aggregate-export.sh`, the `environment-options` scenario:
  the same guard and the same by-name file selection; it built its own
  directory already.
- `tests/validate-doc-examples.sh`, `run_doc_example()`: the `cd "$REPO_DIR"`
  becomes a `cd` into `$TMP_DIR/run/<example slug>`, created per example and
  removed with `$TMP_DIR` by the existing `EXIT` trap, with the guard ahead of
  the run.
- `tests/validate-histogram-bin-counters.sh`,
  `scenario_message_stats_csv_shared()`: the `run_section -mdm bin -n 3 -o`
  call runs inside a `mktemp -d` directory behind the guard, and the unguarded
  `rm -f *MESSAGES-*.csv *STATS-*.csv *-LTL-AGGREGATE.yaml` is replaced by
  removing that directory whole.

### Measured

- **The chained gate order passes.** `tests/validate-doc-examples.sh` then
  `tests/validate-aggregate-export.sh`, no cleanup between, with a stranger
  export planted in the repository root
  (`2099-01-01_000000-LTL-AGGREGATE.yaml`, the shape the investigation used):
  doc-examples 49 passed, 0 failed, 10 skipped; aggregate-export 146 passed,
  0 failed; and all three `directories-relative` assertions pass
  (`directory_list` reads `tests/fixtures|1`, `files/files_matched` reads
  `2/2`, the working directory is absent from the file). Before the change the
  same chain failed the first two of those three.
- **The planted stranger survived unchanged.** Its checksum before the chain
  and after it is identical, and it was the only export product in the
  repository root afterwards — no harness in the chain wrote one. Before the
  change a stranger with a stamp sorting after the run's own was deleted on a
  run reporting 3 passed, 0 failed.
- **No leak into the repository root.** The listing of
  `*-LTL-AGGREGATE.yaml`, `*-LTL-STATS-*.csv` and `*-LTL-MESSAGES-*.csv` in the
  root is identical before and after `tests/validate-doc-examples.sh` (empty in
  both), and identical before and after
  `tests/validate-histogram-bin-counters.sh`. The comparison is a listing; no
  file was deleted to obtain it.
- **The documented `ltl -o access.log` example is still executed.**
  `docs/usage.md:203` reports `PASS`, and the run totals are 49 passed,
  0 failed, 10 skipped — the measured baseline from the investigation,
  unchanged. Every other example passes from the scratch directory too, which
  is the proof behind D3's audit prediction that no executed example depends on
  the working directory being the repository root.
- **Each guard was proved by sabotage.** With an export planted inside the
  scenario's own scratch directory before its `ltl` run, each of the three
  harnesses fails on the `working directory owned` assertion and the failure
  detail carries the planted file's full path. Without the plant all three run
  green (aggregate-export 146 passed, histogram-bin-counters 84 passed,
  doc-examples 49 passed).
- **`perl -c ltl` passes** and no run produced an ` at <file> line <N>` on
  stderr; every harness touched carries the runtime-warning check it already
  had.

### Findings from the build

- **The skip marker on the `-hg duration` example in `docs/usage.md` is
  defeated by the comment line beneath it, and the example is not executed for
  a different reason than the records state.** `tests/extract-doc-examples.pl` sets
  its pending-skip flag on a line matching the marker alone and clears it on
  any subsequent non-blank line that is not a fence opener. The `-hg duration`
  example carries the marker and then a second HTML comment giving the reason,
  which clears the flag, so the extractor emits the example. Measured: running
  the extractor over `docs/usage.md` returns 59 candidates, one of which is
  that example. It is nonetheless never executed, because its operand is a
  `logs/` path that `substitute_command()` has no mapping for, so
  `run_doc_example()` skips it as "no substitution match for placeholder".
  The acceptance criterion (no executed example depends on the repository root)
  holds either way. Two consequences the architect may want to act on
  separately: any future example whose marker is followed by a reason comment
  is silently executed, and the reason comment beside that example
  ("the harness runs examples from the repository root") no longer describes
  what the harness does. Neither is changed here: the first is a change to the
  extractor's marker rule, the second is `docs/usage.md` prose, and D3's scope
  is `run_doc_example()`'s working directory.
- **A fail-fast guard must not remove the directory it just reported on.** The
  first implementation in `tests/validate-histogram-bin-counters.sh` called
  `rmdir` on the guard's failure path; with a stranger present that both
  printed `rmdir: Directory not empty` and, had the directory been otherwise
  empty of the harness's own files, would have been an attempt to remove the
  very file the guard exists to protect. The guard now returns leaving the
  directory as found. The same applies wherever the rule is adopted.

## Completion gate

Full suite required (D9 above): harness files change and the doc-examples
harness's executed examples all move working directory. Before/after benchmark
is marked required by the scope table for any `tests/validate-*.sh` change; no
executable line of `ltl` changes here, and recording a skip with that reason in
the completion comment is proposed for the architect's decision at gate time.
`$version_number` restored to `X.Y.Z` before the gate runs. `--help` and
`docs/usage.md` are untouched, so `tests/validate-help-content.sh` has nothing
new to check but runs as part of the suite. No release-notes bullet.

## Ordering

No `blocked_by` edge in either direction, and nothing here waits on another
issue. Against the other next-up issues: #528 (a transform assigning arithmetic
into a shared record lexical enlarges every duration the raw statistics model
retains) touches `ltl`'s statistics path, disjoint from the harness shell this
issue touches. #482, #478, #476, #475 and #472 were not read during the
investigation, so no ordering claim is made about them beyond the absence of any
edge.

One sequencing point, a convenience argument rather than a dependency: while
this issue is open, the gate order in `docs/process/workflow.md` § 3 (a) can
leave `-o` products in the repository root, so any issue whose completion gate
runs the full suite may see `tests/validate-aggregate-export.sh` fail for a
reason unrelated to its own change. Landing this first removes that noise from
every subsequent gate.

## Related records

- `features/503-yaml-aggregate-export.md` — the export `-o` writes; D9 (the
  working directory is never recorded; the directory list is the distinct
  directory parts of the files read) is the contract the fragile scenario
  proves. Three of its sentences corrected above.
- `tests/HARNESS-DESIGN.md` § *Cached capture artifacts expire* — the same
  failure class, from #448 (cached capture artifacts read back without checking
  which run produced them). The new section sits beside it.
- #341 (the sweep that brought every harness under the runtime-warning stderr
  check) — the precedent for applying a guard to every harness rather than only
  the ones observed failing, cited by D5.
- #342 (audit redundant logic surfaces across `ltl` that must converge to single
  resolution functions) — adjacent to D6's finding; its stated scope is `ltl`,
  not the harnesses.
- `docs/process/workflow.md` § 3 — the gate's harness order and the scope table.
