# 747: no harness check passes on a run that failed, and no harness stops before its summary

Issue: #747 (a harness check passes, or the harness stops early, when the
`ltl` run it reads failed). Parent: #729 (process, tests and build).

Status: specification revised 2026-10-24 after the architect's first review:
D1 and D2 locked, the check kinds completed, the criteria made to hold for
read-path and the screenshot harness, drop 1 given its start-of-work steps,
and everything that could interrupt the run settled in the plan, so it runs
from drop 1 to close-out without asking. No harness has been read under this
issue yet; the issue is in the backlog.

## Resuming

The requirements, the acceptance criteria and the delivery plan below were
agreed by the architect on 2026-10-24. Work starts, when the architect directs
it, on branch
`747-harness-checks-on-a-failed-run` off `release/0.20.0` with drop 1
(§ Delivery plan). From drop 1 this document is carried on the issue branch:
each drop's commit updates § Per-harness record and the status line, and the
document reaches the release branch with the PR, as the work merged by PR #754
did with its own.

## What it is for

The completion gate (`docs/process/workflow.md` § 3 (b)) and the developer's
own `--scenario` runs read a harness's summary as evidence that the behaviour
it names was checked. That reading holds only when every check counted as
passed was made against output the run produced, and when the harness reaches
its summary. Where a check passes on a run that failed, a broken `ltl` shows
up as a smaller failure count than it should, or as checks marked passed
against nothing; where a harness stops partway, the scenarios after it are
never reported at all.

## The contract today

`tests/HARNESS-DESIGN.md` holds the rules this work applies. They were written
under #726 (negative `-n` / `-gc` accepted), when the shapes were first found:

- **§ Trap 12 (a failure counted inside `$( )` is lost):** "A helper that can
  count a failure is called directly, never inside `$( )`; it hands back a
  path through a variable, or the caller derives the path. A capture helper
  that runs inside `$( )` records the exit code beside the capture
  (`<capture>.rc`), and the caller checks it in the main shell before reading
  the capture, as it checks `<capture>.stderr`."
- **§ Trap 13 (a check that holds when the run did not happen):** "Each one is
  preceded by a check that the run produced what it reads: exit 0 and a
  non-empty capture before a comparison or an absence check, and a lookup of
  the specific row or key the run writes (its date, its value) rather than any
  line of the right shape. When that check fails, the checks that read the
  capture are skipped, so the pass count holds only checks made against a real
  output; an absence or width check on an empty capture is itself a failure. A
  refusal is asserted by its exit code **and** its message, never the exit
  code alone, since any failure exits non-zero."
- **§ Trap 13, on stopping:** "A lookup inside `$( )` that finds nothing
  (`grep` with no match, a pipeline fed by a failed `ltl` under `pipefail`)
  stops a `set -e` harness mid-run, so every later scenario goes unreported.
  Such an assignment carries `|| var=""` and the empty value is then asserted
  on."
- **§ Trap 13, on finding them:** "These shapes are found by reading the
  harness: every comparison, absence check, width check and lookup assignment
  is traced back to the run it reads."
- **§ Runtime-warning cleanliness:** "When a capture helper is invoked via
  command substitution (`out=$(run_xxx ...)`), the check must run at the call
  site in the main shell — counters incremented inside the substituted
  function are lost with the subshell."
- **§ Harnesses must fail on missing anchors:** "A harness that greps for a
  section header, key name, or other anchor and finds zero matches MUST exit
  non-zero."
- **§ Proving a new assertion can fail:** every new assertion, and every one
  whose anchor or logic changes, is shown to fail on an input that violates it
  before it is trusted to pass.

The issue's *Done when*: when `ltl` fails or emits nothing, no harness counts a
check as passed unless it reads docs or source, and no harness stops before its
summary.

## What is in place (as found, 2026-10-24)

Counted on `release/0.20.0` at `d10e9972`, by grep. These are counts of
candidate lines to size the work, not findings: whether a line is a case is
decided by reading it.

- `tests/` holds 53 `validate-*.sh` harnesses, 39.8k lines. Every one sets
  `-e` and `pipefail`, so the stopping shape is possible in each.
- `validate-scenario-selector.sh` never runs `ltl`; it is out of scope.
- Six harnesses were changed for these shapes under #726, for the cases found
  then (commits 2312706, 5e9efd1 and d62b4f3): `validate-statistics-demand.sh`,
  `validate-duration-display.sh`, `validate-filter-summary.sh`,
  `validate-format-detection.sh`, `validate-explain.sh`,
  `validate-index-read-back.sh`, together 9.2k lines. Only
  `validate-explain.sh` was read whole for them (d62b4f3). The issue says the
  pattern was found in seven harnesses; the commits it cites change six, and
  #726's thread names no seventh. `validate-option-resolution.sh` was also
  changed under #726 (71358919), to assert the new refusal by its message and
  its exit code, not to fix one of these shapes.
- The 46 remaining harnesses that run `ltl` hold 30.3k lines.
- `tests/lib/notices.sh` already guards its own reads: `notice_total`,
  `notice_kind_count`, `notice_field` and `notice_lines` print
  `MISSING-SECTION` when the capture has no `-V notices` section, so a notice
  absence check made through them does not read 0 from a failed run. The 24
  harnesses that source it still need their call sites read.
- No helper under `tests/lib/` increments a harness's `fail` counter, so Trap
  12 cannot arise inside the library; it arises where a harness's own helper
  runs inside `$( )`.
- 51 harnesses take `LTL` from the environment, and so does the shared CSV
  cache (`tests/lib/csv-cache.sh`). The override entered them all in one
  commit, aca4b7d7, for the release gate's second pass on the generated read
  path (621 D3), not for worktrees: a harness finds its own checkout's `ltl`
  through `REPO_DIR`, derived from the harness's location, so a worktree runs
  its own `ltl` with `LTL` unset. One harness (`validate-notices.sh`) runs
  `perl "$LTL"`; the rest run `"$LTL"` directly, so a stub written in Perl
  serves both.
- `validate-read-path.sh` sets `LTL="$REPO_DIR/ltl"` unconditionally, on
  purpose: its comment reads "Always the script itself, never an override",
  and 621's drop 4 record says it "stays on the script in both passes" of the
  release gate. Its `paths-by-size` scenario checks the default threshold
  (`2097152 (default)`) and a small file on the standard path at that default,
  which a copy of `ltl` with the threshold at 0 contradicts. D1 changes it.
- `validate-screenshot-capture.sh` runs most of its checks through
  `process/capture-screenshots.pl`, which runs `ltl` from its own repository
  root (`my $ltl = File::Spec->catfile( $repo_root, 'ltl' )`) and reads no
  `LTL`. A stub set through `LTL` never reaches those runs. D1 keeps it so.
- `ltl`'s source is read through `$LTL` by design (621 D3: a copy rather than
  a wrapper, because the source readers then read the same source). Under a
  stub those reads read the stub. Harnesses seen reading source through `$LTL`:
  bucket-size-units, classification-states, help-content, notices,
  runtime-config, timestamp-precision. Some compare a count to 0
  (`grep -c ... "$LTL" || true`), which a stub satisfies.
- `assert_no_runtime_warnings` (`tests/lib/runtime-warnings.sh`) returns
  success for an existing empty stderr capture, which is what both stubs
  leave. It counts nothing itself; `validate-histogram-colours.sh` counts a
  PASS on its success, once per run.
- The CSV cache's signature is a digest of the file `$LTL` names, so a stub run
  re-captures rather than reading a real capture, and fails. It also expires
  the real captures: the next real run of csv-output or statistics captures
  again, about 8.5 minutes (`tests/HARNESS-DESIGN.md` § Cached capture
  artifacts expire).
- `validate-explain.sh` reads the pager default from `"$LTL/../ltl"` with
  stderr discarded. A file path followed by `/..` resolves to nothing, so that
  read never succeeds and the fallback to `$REPO_DIR/ltl` always runs.
- The summary line contains `Results: $pass passed, $fail failed` in 44
  harnesses (its `skipped` and `warning(s)` variants included); nine print
  another form: category-names, csv-output, histogram-ticks,
  log-level-vocabulary, message-control-characters, message-truncation,
  statistics-demand, summary-contribution-bar and statistics.
- The harnesses share one scratch directory, the corpus and the `CI=1` cache,
  and two runs at once corrupt each other (`docs/toolchain-guidance.md` § 5,
  harness runs are not concurrent).
- The first form of Trap 13 (5e9efd1) said the shapes were found by running
  each scenario against an `ltl` that always exits 1, and that the suite had
  been swept that way. d62b4f3 replaced it with the reading rule quoted above.
  The issue gives the reason: a stub run is slow, and shows only cases whose
  scenario already fails some other way, so it can at most confirm a fix.

## Records found

`./process/find-records.sh --issues 'Trap 12' 'Trap 13' 'missing anchor' 'command substitution' 'empty capture' 'pipefail' 'always fails' 'sabotage' 'runtime-warning check'`

| Record | Disposition |
|---|---|
| `tests/HARNESS-DESIGN.md` § Traps 1–13, § Harnesses must fail on missing anchors, § Proving a new assertion can fail, § Runtime-warning cleanliness, § The scenario selector | read: the contract this work applies (§ The contract today) |
| #238 (sweep every harness for the missing-anchor-as-pass anti-pattern) | read: the precedent sweep, over 11 harnesses in 0.14.6; it wrote Traps 1–10 and fixed a `set -e` + `pipefail` + `diff` stop in `validate-regression.sh` (`releases/v0.15.0.md`) |
| #341 (harnesses ignore Perl runtime warnings on `ltl` stderr) | read: the sweep that put every harness under the runtime-warning check, whose call-site rule under `$( )` is part of the contract |
| `features/412-notice-surfaces.md` § the harnesses of the notice migration | read: every notice absence check also reads the record count under Trap 13; the place a notice check is read in this work |
| `features/545-harness-scenario-selector.md` § sabotage table | read: a handler run under command substitution was a stage 1 bug, and a `grep -q` pipeline under `pipefail` read SIGPIPE as a result |
| `features/674-scenario-selector-several-names.md` § sabotage proof | read: the same SIGPIPE trap in the static check; `validate-scenario-selector.sh` sweeps every harness, a precedent for a suite-wide check |
| `docs/test-driven-development.md`, `docs/process/workflow.md` §§ 1–3 | read: how the criteria and the gate are shaped |
| `features/621-generated-read-loop-body.md` D3 and drop 4, `docs/process/workflow.md` § 5 step 4 | read: why `LTL` is overridable, why source is read through it, why read-path is pinned; the procedure D1 amends |
| `features/598-screenshot-capture.md`, `docs/process/screenshots.md` | read, searched for `LTL` and overrides: no record says why the screenshot tool runs the repository's `ltl`; D1 is now that record |
| `docs/toolchain-guidance.md` § 5 (harness runs are not concurrent) | read: the reason for § Constraints, one harness run at a time |
| `features/254-validate-distribution-shape.md`, `features/475-log-level-vocabulary-completion.md`, `features/58-format-registry-staged-detection.md`, `features/638-udm-non-numeric-capture.md`, #387 | dismissed: each matched in the account of its own harness's missing-anchor guard or sabotage proof, or of an empty extraction capture in `ltl`; none governs how a harness reads a failed run |
| 31 other feature docs and `docs/usage.md` | dismissed: matched only `sabotage`, `runtime-warning check` or `empty capture` in the same kind of account; the command above lists them |

## Decisions

- **D1** (locked by the architect 2026-10-24). `validate-read-path.sh` takes
  `LTL` from the environment like every other harness, and the release gate's
  second pass (`docs/process/workflow.md` § 5, step 4) leaves it out: it runs
  in the first pass and compares both read paths itself, and today its
  second-pass run ignores `LTL` and repeats the first.
  `process/capture-screenshots.pl` keeps running the repository's `ltl` and
  never honours `LTL`, so no stub and no variant of `ltl` reaches a
  documentation screenshot; no record said so before this one, and drop 1
  adds a comment beside the tool's `my $ltl` saying why. No separate mechanism
  for running a harness against a broken `ltl` is built: the two uses of `LTL`,
  a variant of `ltl` (the second pass) and a broken one (this work), collide
  only in read-path, the one harness that checks the default read-path
  threshold. Amends the procedure of 621 D3, where the amendment is recorded.
  Chosen over a mechanism kept apart from `LTL` (a change through the 502
  lines in 53 files that name `$LTL`, for a collision in one harness) and over
  leaving read-path out of the stub runs.
- **D2** (the architect, 2026-10-24). All of this work is done under this
  issue; no other issue is filed for any part of it.

## Constraints

- **Worktrees.** A harness may run from a worktree whose `logs` is a symlink
  to the main checkout's corpus, and `validate-regression.sh` and
  `tests/capture-regression.sh` move into the corpus's parent directory when
  `LTL_LOGS_DIR` is set, which is then the main checkout. No change under this
  issue finds `ltl` from the working directory, from `$LOGS_DIR`, or from the
  directory of `$LTL`; every stub is named by an absolute path. Each drop runs
  its changed scenarios once from a worktree under the scratchpad carrying the
  `logs` symlink, with `LTL` unset and with each stub, and they report what
  the main checkout reports.
- **One harness run at a time.** Stub runs and real runs are sequential, never
  in the background beside another harness run. At the gate the stub runs
  follow the real suite, then `./tests/cleanup-test-artifacts.sh`.

## Requirements

- **R1. Every harness that runs `ltl` is read for the shapes.** Each of the 52
  harnesses, including the six changed under #726, is read whole. For each
  one, every comparison, absence check, width check, refusal check, count
  compared to 0, presence check and lookup assignment is traced back to the
  run it reads, and every helper that counts a failure is checked for a call
  inside `$( )`. The shapes are those of Trap 12 and Trap 13 as quoted in
  § The contract today, including these forms of them:
  - a presence check that rows seeded by a fixture, or output left by an
    earlier run, satisfy;
  - a count compared to 0, on a capture or on source read through `$LTL`
    (a stub has none of what is counted);
  - the runtime-warning check counted as a pass with no evidence that the run
    it reads happened;
  - a path derived from the location of `$LTL`.

  Source read through `$LTL` stays so (621 D3); under a stub a presence check
  on it fails, as it should, and is recorded as such per harness.
- **R2. Each case found is fixed** to the form Trap 12 and Trap 13 give, and
  recorded in § Per-harness record: the scenario, the check, the shape, and
  what the fix reads.
- **R3. The shared helpers are read too.** Every capture or lookup helper
  under `tests/lib/` that a harness reads `ltl` output through is read for the
  same shapes, once, before the harnesses that source it, among them
  `assert_no_runtime_warnings`, whose success on an empty stderr is the
  runtime-warning form of R1.
- **R4. The method is recorded** in `tests/HARNESS-DESIGN.md`, beside Trap 12
  and Trap 13, as the reading a harness gets: what to trace, from where, and
  a table of each shape and its fix, so the next harness written is checked
  the same way. Each shape carries a review-gate grep, as Trap 11 does, that
  points at the candidate lines; reading decides whether a line is a case.
- **R5. A stub run confirms a fix; it does not find one.** Each harness is run,
  once it is read and fixed, against an `ltl` that fails and an `ltl` that
  emits nothing, to confirm the *Done when*. Every harness that runs `ltl`
  accepts the stub through `LTL`, `validate-read-path.sh` included (D1). The
  runs `process/capture-screenshots.pl` makes stay on the repository's `ltl`
  (D1), so the checks reading them are confirmed by doctored captures instead.

Out of scope: changing what a scenario asserts about a healthy run; the
invocation shape of each run (`tests/HARNESS-DESIGN.md` § Invocation
coherence, whose audit of every harness was #399); `ltl` itself.

## Acceptance criteria

Two stubs, each a two-line Perl script made in a temporary directory and named
by its absolute path: the **failing stub** prints nothing and exits 1; the
**silent stub** prints nothing and exits 0. A **run-free check** is one whose
input no run of `ltl` produced: a file under `docs/` or `features/`, a fixture,
an artifact the harness writes itself, or `ltl`'s source text. Source read
through `$LTL` is the stub's under a stub run, so such a check is run-free and
still fails there; it is recorded as failing against the stubs.

- [ ] **AC1. Against the failing stub, every harness reaches its summary.**
      `LTL=<failing stub> ./tests/validate-<name>.sh`, for each harness that
      runs `ltl`. Pass when: the output ends with the harness's summary line
      and the exit status is non-zero. *Assertable*: the run and its captured
      output.
- [ ] **AC2. Against the failing stub, only run-free checks pass.** Pass
      when: every check the run counts as passed is one named for that harness
      in § Per-harness record as run-free, and the run's PASS lines number as
      many as its passed count; a harness with none reports 0 passed. One
      exception, by D1: in `validate-screenshot-capture.sh`, a check reading
      the output of `process/capture-screenshots.pl` passes, since the tool
      ran the repository's `ltl`; each is named in the record as such.
      *Assertable*: the run's PASS lines against the list, through the
      capture checker of drop 1.
- [ ] **AC3. The silent stub, the same.** AC1 and AC2 hold with the silent
      stub, which exits 0 and so reaches the checks that read the capture
      rather than the exit code. *Assertable*: as AC1 and AC2.
- [ ] **AC4. A healthy run loses no check.** Against the real `ltl`, every
      harness exits 0, and its passed count equals the count before this work
      plus the checks this work adds, each named in § Per-harness record.
      *Assertable*: the summary counts of drop 1's baseline run of the full
      suite on the base commit, against the gate's run, on the same machine.
- [ ] **AC5. Every harness takes the stub.** Every harness that runs `ltl`
      reads it from `LTL` when set, `validate-read-path.sh` included (D1).
      *Assertable*: AC1 runs on every such harness.
- [ ] **AC6. Each fix can fail.** A check this work adds or changes is shown
      to fail on the stub run or on a doctored capture before it is trusted
      (`tests/HARNESS-DESIGN.md` § Proving a new assertion can fail).
      *Assertable*: the run is recorded with the fix.
- [ ] **AC7. The method is written down.** `tests/HARNESS-DESIGN.md` carries
      the reading of R4: a row and a review-gate grep for every shape R1
      names and every shape the drops added. *Assertable*: at the gate the
      greps run over every harness, and each line they list is accounted for
      in § Per-harness record, as a case fixed or as read and not a case.
- [ ] **AC8. The release procedure and read-path agree (D1).** The second
      pass in `docs/process/workflow.md` § 5, step 4 leaves
      `validate-read-path.sh` out and says why, and the screenshot tool's
      `my $ltl` carries the comment D1 asks for. *Assertable* by reading the
      two files at the gate.

## Delivery plan

Each drop from 2 on reads its harnesses whole with drop 1's candidate list
beside it, fixes each case to the method's table, shows each check it adds or
changes failing on a stub or a doctored capture (AC6), records it in
§ Per-harness record, runs the scenarios it changed (each named with
`--scenario`) against both stubs and the real `ltl`, and once from a worktree
(§ Constraints), and ends with a commit and a push on the issue branch that
carries this document's record. Groups are by size, smallest first, so the
method is settled on short harnesses before the long ones.

**Drop 1, in this order, one run at a time:**

1. Branch `747-harness-checks-on-a-failed-run` off `release/0.20.0`;
   `./process/issue-status.sh set 747 "in progress"`.
2. On the base commit: the `747-before` benchmark
   (`single-day-access-log-standard`, from the main checkout), which the scope
   table of `docs/process/workflow.md` § 3 requires for a diff touching
   `tests/validate-*.sh`; then, in one command the Bash guard asks about once,
   the full suite on the real `ltl` (a measurement for AC4, not the gate)
   followed by every harness against each stub. Each harness's summary
   line, passed count, its stub runs' passed counts and whether they reached
   the summary, and each run's time go into § Per-harness record.
3. `$version_number` stamped `0.20.0-747`.
4. D1: `validate-read-path.sh` takes `LTL` and its comment says why; the second
   pass in `docs/process/workflow.md` § 5, step 4 leaves read-path out and says
   why; the comment beside `my $ltl` in `process/capture-screenshots.pl`.
5. The method in `tests/HARNESS-DESIGN.md` (R4): the shape and fix table and
   a review-gate grep per shape. The greps run over every harness into a
   candidate list per harness, kept in the scratchpad and made again from the
   committed greps in a later session.
6. The helpers under `tests/lib/` (R3).
7. The capture checker, committed under `process/` because the work spans
   sessions and the scratchpad does not survive them. It reads a harness
   capture and never runs one, so every harness run stays a direct command the
   Bash guard sees. It reports whether the summary was reached, the exit
   status, the passed count, the number of PASS lines against it (a mismatch
   is a counter advanced without a check, Trap 6), and every PASS line, to be
   compared with the harness's run-free checks in § Per-harness record.

| Drop | What | Harnesses | Lines |
|---|---|---|---|
| 1 | The steps above | — | — |
| 2 | verbose-content-shape, message-grouping-notices, profile-render, numeric-criteria-notices, outcome-criteria, memory-usage, distribution-shape, profile, doc-examples, classification-states, histogram-colours, category-names, help-layout, regression, csv-output, message-truncation, message-control-characters | 17 | 6.1k |
| 3 | read-path, aggregate-export, bucket-size-units, byte-units, histogram-ticks, classification-percentages, statistics, csv-input, option-resolution, recursive-file-selection, value-display | 11 | 6.1k |
| 4 | progress-line, heatmap-palette, udm-counting, screenshot-capture, format-registry, message-mask, message-grouping, notices | 8 | 6.2k |
| 5 | summary-contribution-bar, section-layout, timestamp-precision, message-expose, log-level-vocabulary, runtime-config | 6 | 6.4k |
| 6 | message-discard, help-content, histogram-bin-counters, udm-specs | 4 | 5.6k |
| 7 | The six changed under #726, read whole: statistics-demand, duration-display, filter-summary, format-detection, explain, index-read-back | 6 | 9.2k |

**Run to the end.** Once the plan is agreed, drop 1 through the gate, the PR,
the merge and the close-out run in sequence without asking. What could
otherwise interrupt them is settled here:

- **A case of a shape the method's table lacks** is fixed to the nearest form
  Trap 12 or Trap 13 gives, and the shape is added to the table and its
  review-gate grep in the same drop's commit. The method grows as the drops
  teach it; drop 2 revises it with what the 17 shortest harnesses taught.
- **A fix never changes what a check asserts about a healthy run.** It adds
  the check that the run produced what the check reads, and skips the check
  when that fails (Trap 13), so AC4 holds by construction.
- **A defect in `ltl` found by reading** is recorded in this document as an
  observation, with the scenario, the input and what was read, and named in
  the completion comment. `ltl` is out of scope, so the work goes on.
- **The stub runs stay a confirmation**, as the issue sets them: the method
  in `tests/HARNESS-DESIGN.md` is how the next harness is checked, and no
  harness is added to sweep the suite with the stubs.

One stop remains, since the gate could not pass without it: a harness that
fails on the real `ltl` at drop 1's baseline, and still fails run alone (a
concurrent run explains a failure first, § Constraints). It is reported then,
before any drop starts.

Then the completion gate: `$version_number` restored to `0.20.0`, the `after`
benchmark, the full suite on the real `ltl` (AC4), every harness against each
stub (AC1, AC2, AC3), AC8 read, then `./tests/cleanup-test-artifacts.sh`. The
PR and the close-out follow.

Estimate, from the #726 fixes (six harnesses, 9.2k lines, about four hours
by their commit times, so about 2.3k lines an hour read, fixed and proved):
drops 2 to 6 about 13 hours, drop 7 about 2, drop 1 about 2 (its baseline
suite alone about 21 minutes), the stub confirmations 1 to 2, the gate about
40 minutes (the full suite took 21 minutes on the architect's macOS host,
2026-10-24). About 19 hours in all, 14.5 to 24. The time a harness takes
against a stub is not yet measured; the issue calls it slow, and drop 1's
baseline measures it.

## Per-harness record

Drop 1 fills the baseline columns for every harness; each later drop fills
the rest for its own. Stub columns read `passed / summary reached`, before the
work and after it.

| Harness | Drop | Summary line | Passed on real `ltl` | Failing stub | Silent stub | Cases found: check, shape, fix | Run-free checks |
|---|---|---|---|---|---|---|---|
| (baseline not yet taken) | | | | | | | |
