# 747: no harness check passes on a run that failed, and no harness stops before its summary

Issue: #747 (a harness check passes, or the harness stops early, when the
`ltl` run it reads failed). Parent: #729 (process, tests and build).

Status: drop 1 done 2026-10-24 (cdbc1205, pushed). Drop 2 done 2026-10-24
(bf390713): twelve of its seventeen harnesses fixed, the method revised.
Drop 3 done 2026-10-24: ten of its eleven harnesses fixed, shape 15 added
(§ Drop 3). Drops 4 to 6 were read during the baseline run; their cases are
in § Per-harness record and their fix designs in § Fix designs read ahead. Drop 7 is not yet
read. D3 (the architect, during drop 1) adds a final stage after drop 7.

## Resuming

The requirements, the acceptance criteria and the delivery plan below were
agreed by the architect on 2026-10-24, and work started that day on branch
`747-harness-checks-on-a-failed-run` off `release/0.20.0`. This document is
carried on the issue branch: each drop's commit updates § Per-harness record
and the status line, and the document reaches the release branch with the PR,
as the work merged by PR #754 did with its own. The next step is drop 4, to
the designs in § Fix designs read ahead, with the greps of
`tests/HARNESS-DESIGN.md` run over each harness first (grep 15 lists
format-detection, histogram-bin-counters, index-read-back, statistics-demand,
udm-counting and udm-specs, each in its own drop).

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
- Measured at drop 1's baseline on base `c0fa5283` (macOS host, one run each,
  one harness at a time): the 53 harnesses take 1,240 s on the real `ltl`,
  every one exiting 0; the 52 that run `ltl` take 166 s in all against the
  failing stub and 243 s against the silent stub. A stub run is not slow: what
  the issue calls slow does not hold on this host. The other half of its reason
  does hold, and the baseline shows it: 27 harnesses stop before their summary
  against the failing stub and 24 against the silent one, so the scenarios after
  the stop are never reached; and the stub runs found two cases (in
  value-display and notices) that the reading had missed, both lookups of the
  shape the review-gate grep for shape 10 lists.

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
- **D3** (the architect, 2026-10-24, during drop 1). After drop 7 and before
  the completion gate, a final stage builds the safeguard that keeps what the
  drops fix from coming back: an official checker of the harnesses; every
  condition it checks written in `tests/HARNESS-DESIGN.md` as an expectation, a
  rule, and what counts as a failure; and a rule that a harness change passes
  the checker on everything before it is committed. The checker combines the
  shapes the drops found. It is a stage added at the end, not a change to any
  drop, and it retires the plan line "no harness is added to sweep the suite
  with the stubs". Its shape, as recommended when the architect gave it and
  not countered: rules read from the harness source for what is certain there
  (a failure counted inside `$( )`, a summary inside a scenario's block, a
  lookup assignment with no fallback), and a run of each harness against both
  stubs for the rest, failing on a summary not reached, an exit of 0, PASS
  lines that differ from the passed count, or a PASS line not marked run-free;
  one harness in the suite. Measured at drop 1: the stub runs of all 52
  harnesses take about 7 minutes together.

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
| 8 | D3: the checker, its conditions in `tests/HARNESS-DESIGN.md`, the rule that a harness change passes it (`.claude/rules/harnesses.md`, a CLAUDE.md checkpoint), every run-free PASS line marked | all | — |

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
- **The stub runs stay a confirmation** while the drops run, as the issue sets
  them: reading finds the cases, and the method in `tests/HARNESS-DESIGN.md`
  is how the next harness is read. Drop 8 (D3) then makes the stub run part
  of the checker every harness change passes.

One stop remains, since the gate could not pass without it: a harness that
fails on the real `ltl` at drop 1's baseline, and still fails run alone (a
concurrent run explains a failure first, § Constraints). It is reported then,
before any drop starts.

Then drop 8 (D3), and the completion gate: `$version_number` restored to `0.20.0`, the `after`
benchmark, the full suite on the real `ltl` (AC4), every harness against each
stub (AC1, AC2, AC3), AC8 read, then `./tests/cleanup-test-artifacts.sh`. The
PR and the close-out follow.

Estimate, from the #726 fixes (six harnesses, 9.2k lines, about four hours
by their commit times, so about 2.3k lines an hour read, fixed and proved):
drops 2 to 6 about 13 hours, drop 7 about 2, drop 1 about 2 (its baseline
suite alone about 21 minutes), the stub confirmations 1 to 2, the gate about
40 minutes (the full suite took 21 minutes on the architect's macOS host,
2026-10-24). About 19 hours in all, 14.5 to 24. Drop 1's baseline measured
the stub runs: 166 s for all 52 harnesses against the failing stub, 243 s
against the silent one (§ What is in place).

## Per-harness record

Drop 1 filled the baseline columns for every harness on base `c0fa5283`; each
later drop fills the rest for its own and adds its after figures. The real
column is the passed count and the run's time; the stub columns read
`passed / summary reached (time)`. The shape numbers in the cases column are
those of `tests/HARNESS-DESIGN.md` § Reading a harness for a run that did not
happen; `stop` is a harness that ends before its summary (shape 13 when the
cause is an `exit`), `acceptance` a run's success asserted by its exit code
alone (shape 14; both added to the table by drop 2). After drop 2 the real and
stub columns read `before → after`.
Cases listed as "found by reading, not yet fixed" were read ahead of their
drop, while the baseline ran.

| Harness | Drop | Summary line | Passed on real `ltl` | Failing stub | Silent stub | Cases found: check, shape, fix | Run-free checks |
|---|---|---|---|---|---|---|---|
| aggregate-export | 3 | `Results: N passed, M failed` | 163 (14 s) → 163 | 0 / no (0 s) → 0 / yes | 0 / yes (2 s) → 0 / yes | fixed in drop 3: run_export and two inline runs exit the harness on a failed run (stop); once fixed, run_export returns before resetting YAML_FILE, so the next check would read the previous scenario's export (5) | none |
| bucket-size-units | 3 | `Results: N passed, M failed` | 64 (57 s) → 64 | 0 / no (4 s) → 0 / yes | 18 / yes (3 s) → 0 / yes | fixed in drop 3: 22 equivalence rows compare two empty timelines (2); a bare number is never rejected: exit code alone (acceptance); the -ru w run's subshell exits under the inherited set -e (11) | none |
| byte-units | 3 | `Results: N passed, M failed` | 48 (7 s) → 48 | 5 / yes (0 s) → 0 / yes | 6 / yes (1 s) → 0 / yes | fixed in drop 3: five no-private-table checks: absence over a stub's source (7); the GC run exits 0: exit code alone (acceptance) | none |
| category-names | 2 | `PASS: N FAIL: M` | 26 (2 s) → 26 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | fixed in drop 2: capture_render and the CSV run exit the harness on a failed run (stop) | none |
| classification-percentages | 3 | `Results: N passed, M failed` | 43 (3 s) → 43 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | fixed in drop 3: ten captures exit the harness before the scenarios parse (stop); ten runtime-warning PASSes would follow (8); the leakage run unchecked (8); XFAIL counts a pass and XPASS counts one without a PASS line, 43 against 42 on the base (12) | none |
| classification-states | 2 | `Results: N passed, M failed` | 56 (4 s) → 56 | 4 / yes (0 s) → 1 / yes | 5 / yes (0 s) → 1 / yes | fixed in drop 2: --help formats omits the format: absence on an empty capture (3); a clean run prints neither row: absence, exit unchecked (3); no -n 0 branch and the short-circuit retired: absence over a stub's source (7); per-bucket cell lookups and the CSV column and row lookups stop the harness when they find nothing (10) | producer/fixture-tracked |
| csv-input | 3 | `Results: N passed, M failed` | 43 (9 s) → 43 | 0 / no (0 s) → 0 / yes | 0 / no (1 s) → 0 / yes | fixed in drop 3: mixed glob exits 0: exit code alone (acceptance); no timestamp message: absence on an empty stderr (3); the index line count lookup stops the harness (10); `assert_command` evaluated each command in the harness's own shell, where a notices sentinel read as a number is an unbound-variable error under `set -u` (15, found by the silent-stub run) | none |
| csv-output | 2 | `=== CSV output integrity: S scenarios, N pass, M fail ===` | 44 (16 s) → 8 on 2 scenarios | 0 / no (2 s) → 0 / yes | 0 / no (3 s) → 0 / yes | fixed in drop 2: cache-validity exits the harness when its first capture fails (stop) | none |
| distribution-shape | 2 | `Results: N passed, M failed` | 8 (3 s) → 8 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | fixed in drop 2: generate_and_run exits inside `$( )` on a failed run: harness stops, failure uncounted (1, 10) | none |
| doc-examples | 2 | `Results: N passed, M failed, K skipped` | 51 (13 s) | 0 / yes (2 s) | 0 / yes (1 s) | none |  |
| duration-display | 7 | `Results: N passed, M failed` | 41 (5 s) | 0 / yes (0 s) | 0 / yes (0 s) |  |  |
| explain | 7 | `Results: N passed, M failed` | 728 (36 s) | 65 / yes (4 s) | 107 / yes (5 s) |  |  |
| filter-summary | 7 | `Results: N passed, M failed` | 146 (6 s) | 0 / no (0 s) | 0 / no (0 s) |  |  |
| format-detection | 7 | `Results: N passed, M failed` | 472 (33 s) | 0 / no (0 s) | 0 / no (0 s) |  |  |
| format-registry | 4 | `Results: N passed, M failed` | 59 (4 s) | 0 / no (0 s) | 0 / no (0 s) | found by reading, not yet fixed: `out=$(run_format_registry)` exits inside `$( )` (1, 10); unknown -lf exits non-zero: exit code alone (6); two inline runs exit (stop); unarmed measurement: absence on an empty capture (3) |  |
| heatmap-palette | 4 | `Results: N passed, M failed` | 120 (6 s) | 0 / no (0 s) | 0 / no (0 s) | found by reading, not yet fixed: `out=$(run_section)` exits inside `$( )`: stop, failure uncounted (1, 10); run_udm exits (stop); two exits 0 by exit code alone once fixed (acceptance) |  |
| help-content | 6 | `Results: N passed, M failed[, W warning(s)]` | 114 (5 s) | 0 / no (0 s) | 0 / no (0 s) | found by reading, not yet fixed: three top-level exits before any scenario (stop); description quality and no branch per topic: absence over a stub's source (7); no -uuid row and no long byte word: absence on an empty capture (3); four comparisons of two empty lookups (2) | B (GetOptions read from the source against docs/usage.md); the docs/usage.md halves of H, I, J, K, L, M |
| help-layout | 2 | `Results: N passed, M failed` | 6 (0 s) → 6 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | fixed in drop 2: the layout constants missing from the source exit the harness (stop); the --help run unchecked, so the two inspectors pass on an empty capture (4); each inspector's non-zero exit, a misaligned row's included, ended the harness under `set -e` (11) | none |
| histogram-bin-counters | 6 | `Results: N passed, M failed` | 148 (7 s) | 5 / yes (1 s) | 5 / yes (1 s) | found by reading, not yet fixed: four assert_no_line absences on an unchecked capture (3); heatmap_cells_highlighted carries no percentile field: absence on an empty block (3) |  |
| histogram-colours | 2 | `Results: N passed, M failed` | 21 (2 s) → 21 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | fixed in drop 2: capture_run and the layout-table check exit the harness on a failed run (stop); the run exits 0 asserted by exit code alone (acceptance) | none |
| histogram-ticks | 3 | `Total: T \| Passed: N \| Failed: M` | 21 (5 s) → 21 | 9 / yes (4 s) → 0 / yes | 9 / yes (3 s) → 0 / yes | fixed in drop 3: no tick outside the axis and tick colour parity pass on an empty capture, per width and on the multi-histogram run (3); a tick check not applicable counts a PASS (12) | none |
| index-read-back | 7 | `Results: N passed, M failed` | 107 (21 s) | 0 / no (1 s) | 0 / no (2 s) |  |  |
| log-level-vocabulary | 5 | `PASS: N FAIL: M` | 58 (3 s) | 0 / no (0 s) | 0 / no (0 s) | found by reading, not yet fixed: seven scenario runs exit the harness on a failed or empty run (stop) |  |
| memory-usage | 2 | `Results: N passed, M failed` | 23 (4 s) → 23 | 8 / yes (0 s) → 1 / yes | 8 / yes (0 s) → 1 / yes | fixed in drop 2: absence on an empty capture: no grouping callers, no section, no debug sub-section, nothing on stderr (3); two readings per compile compares 0 with 0 (2); record shape and sample shape hold over no record (4) | debug-samples: input lines (a file the harness writes) |
| message-control-characters | 2 | `PASS: N FAIL: M` | 11 (1 s) → 11 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | fixed in drop 2: six exits on a failed, empty or CSV-less run (stop) | none |
| message-discard | 6 | `Results: N passed, M failed` | 82 (18 s) | 0 / yes (1 s) | 0 / yes (0 s) | none |  |
| message-expose | 5 | `Results: N passed, M failed` | 62 (13 s) | 0 / yes (0 s) | 0 / yes (1 s) | none |  |
| message-grouping | 4 | `Results: N passed, M failed` | 51 (19 s) | 0 / yes (0 s) | 0 / yes (0 s) | found by reading, not yet fixed: none (two selection-only defects under § Observations) |  |
| message-grouping-notices | 2 | `Results: N passed, M failed` | 4 (2 s) | 0 / yes (0 s) | 0 / yes (0 s) | none |  |
| message-mask | 4 | `Results: N passed, M failed` | 27 (15 s) | 0 / yes (1 s) | 0 / yes (0 s) | none |  |
| message-truncation | 2 | `PASS: N FAIL: M` | 27 (5 s) → 27 | 1 / yes (0 s) → 0 / yes | 1 / yes (1 s) → 0 / yes | fixed in drop 2: no ellipsis under the right cut: absence on an empty render and a missing CSV (3) | none |
| notices | 4 | `Results: N passed, M failed` | 188 (97 s) | 0 / no (64 s) | 0 / no (63 s) | found by reading, not yet fixed: buttons-only, ASCII only, standard output only, nothing on standard error: absence on a failed run (3); no kind outside the inventory and every stderr site named: absence over a stub's source (7); the screen given back: absence on a pane that never drew (3); an answered choice locked: two identical empty panes (2); the title-row lookup in preread stops the harness (10; found by the stub run) | registered: reserved in the harness design |
| numeric-criteria-notices | 2 | `Results: N passed, M failed` | 10 (2 s) | 0 / yes (0 s) | 0 / yes (0 s) | none |  |
| option-resolution | 3 | `Results: N passed, M failed` | 187 (30 s) → 187 | 0 / no (1 s) → 0 / yes | 0 / no (1 s) → 0 / yes | fixed in drop 3: three source checks: absence over a stub's source (7); exit 0 asserted alone (acceptance); eight unit-counts-as-bare checks compare `/` with `/` (2); the printed-spellings source reader dies on a stub (11) | none |
| outcome-criteria | 2 | `Results: N passed, M failed` | 26 (4 s) → 26 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | fixed in drop 2: capture() exits the harness on a failed run, before scenario_parse_args (stop, 11); two missing classification lookups compare equal in inert-outcomes (2); 14 runtime-warning PASSes on empty stderr (8); the retired names refused by exit code alone (6); the renamed forms accepted by exit code alone (acceptance) | none |
| profile | 2 | `Results: N passed, M failed` | 106 (5 s) → 15 on 3 scenarios | 0 / yes (0 s) → 0 / yes | 0 / yes (0 s) → 0 / yes | fixed in drop 2: the `samples_included` and `samples_dropped` lookups stop the harness when the section lacks them (10; listed by grep 10 after reading passed over them) | none |
| profile-render | 2 | `Results: N passed, M failed` | 50 (5 s) | 0 / yes (0 s) | 0 / yes (0 s) | none |  |
| progress-line | 4 | `Results: N passed, M failed` | 27 (3 s) | 0 / no (0 s) | 0 / no (1 s) | found by reading, not yet fixed: capture_frames and the collision run exit the harness on a failed run, uncounted (stop) |  |
| read-path | 3 | `Results: N passed, M failed` | 28 (65 s) → 28 | 28 / yes (65 s) (LTL pinned before D1) → 1 / yes | 28 / yes (64 s) (LTL pinned before D1) → 1 / yes | fixed in drop 3: mixed sizes, fallback, and a die exits alike: comparisons of two failed runs (2); N option shapes equal counted with no shape compared (12); altered_ltl, the probe-line lookup and the --help lookup stop the harness (10, 11); the threshold hidden: absence on an empty --help (3); the die lookups `g=` and `s=`, built from two substitutions, stop the harness on an `ltl` whose loop never reaches the probe (10, found by running it; grep 10 now lists a quoted value) | help-rows: -D in docs/usage.md |
| recursive-file-selection | 3 | `Results: N passed, M failed` | 36 (7 s) → 36 | 2 / yes (2 s) → 0 / yes | 2 / yes (3 s) → 0 / yes | fixed in drop 3: two no-quoting-guidance checks: absence on an empty stderr, one with only `[ -f ]` as evidence (3) | none |
| regression | 2 | `Results: N passed, M failed, K skipped` | 74 (28 s) → 4 on 4 scenarios | 0 / yes (4 s) → 0 / yes | 0 / yes (5 s) → 0 / yes | fixed in drop 2: the empty-capture check moved ahead of the width check; on the silent stub an empty run had reported its known wrap as XPASS, "remove its entry" (4) | none |
| runtime-config | 5 | `Results: N passed, M failed` | 119 (14 s) | 17 / yes (1 s) | 19 / yes (1 s) | found by reading, not yet fixed: assert_exit counts a PASS by exit code alone: refusals (6) and acceptances; three assert_no_line absences on an empty capture (3) |  |
| scenario-selector | - | `Results: N passed, M failed` | 39 (141 s) | not run (runs no ltl) | not run (runs no ltl) |  |  |
| screenshot-capture | 4 | `Results: N passed, M failed` | 44 (78 s) | 0 / no (3 s) | 31 / yes (75 s) | found by reading, not yet fixed: capture_ltl, the palette run and the index seed run are bare and stop the harness (11); the panel colours compared with an empty capture pass (2; the helper guard is in place) | by D1, every check reading only the output of process/capture-screenshots.pl |
| section-layout | 5 | `Results: N passed, M failed` | 186 (32 s) | 0 / yes (1 s) | 0 / yes (1 s) | found by reading, not yet fixed: -hi changes the render: an inequality against a baseline run that may have failed (2) |  |
| statistics | 3 | `=== Statistics drift: S scenarios, N pass, M fail ===` | 25 (299 s) | 0 / yes (1 s) | 0 / yes (1 s) | none (read again with drop 3's greps) |  |
| statistics-demand | 7 | `=== validate-statistics-demand: N passed, M failed ===` | 167 (23 s) | 3 / yes (2 s) | 3 / yes (1 s) |  |  |
| summary-contribution-bar | 5 | `PASS: N FAIL: M` | 39 (3 s) | 0 / no (0 s) | 0 / no (1 s) | found by reading, not yet fixed: capture_render exits the harness on a failed run (stop) |  |
| timestamp-precision | 5 | `Results: N passed, M failed` | 94 (20 s) | 0 / no (1 s) | 0 / no (1 s) | found by reading, not yet fixed: labels() lookups stop the harness at seven assignments (10); no four-digit fraction: absence on a failed run (3); no bucket-key site reads -s or -ms: absence over a stub's source (7) |  |
| udm-counting | 4 | `Results: N passed, M failed` | 44 (6 s) | 0 / no (1 s) | 0 / no (0 s) | found by reading, not yet fixed: two bare -xu runs stop the harness (11) |  |
| udm-specs | 6 | `Results: N passed, M failed` | 250 (22 s) | 0 / no (0 s) | 0 / no (1 s) | found by reading, not yet fixed: about 14 assert_absent checks pass on an empty capture or a missing notices section (3); twenty runs report one unit compares 20 empty results (2); nine prints-no-warning checks: absence on an empty stderr (3); four exits 0 by exit code alone (acceptance) |  |
| value-display | 3 | `Results: N passed, M failed` | 60 (17 s) → 60 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | fixed in drop 3: the resolved-unit lookup in zero-duration stops the harness (10; found by the stub run, missed by reading); the cv-agreement `csv=` lookup (10) | none |
| verbose-content-shape | 2 | `Results: N passed, M failed` | 1 (1 s) | 0 / yes (0 s) | 0 / yes (0 s) | none |  |

### Drop 1

- **D1.** `tests/validate-read-path.sh` takes `LTL` (a run of its
  `threshold-values` scenario against the failing stub fails its five checks,
  where the baseline's ran the repository's `ltl`); the release gate's second
  pass in `docs/process/workflow.md` § 5 step 4 leaves it out and says why; the
  comment beside `my $ltl` in `process/capture-screenshots.pl` says why the tool
  never reads `LTL`.
- **The method** (R4) is in `tests/HARNESS-DESIGN.md` § Reading a harness for a
  run that did not happen: what is traced and from where, a table of twelve
  shapes and their fixes, a review-gate grep per shape, and the confirming stub
  run read by `process/check-harness-capture.pl`.
- **The helpers** (R3), each read for the shapes:

  | Helper | Read | Change |
  |---|---|---|
  | `assert_no_soft_wrap` (`rendered-output.sh`) | passed an existing empty capture (shape 4) | fails an empty capture; shown failing on an empty file and passing on a one-line one |
  | `render_row_report`, `timeline_cell_report` (`rendered-output.sh`) | exit non-zero when the row is not found, which stops a harness that assigns them without a fallback | none: the fallback belongs at the call site (shape 10) |
  | `assert_no_runtime_warnings` (`runtime-warnings.sh`) | succeeds on an empty stderr; counts nothing itself | header states that a success says nothing about whether the run happened (shape 8 is at the call site) |
  | `notice_*` (`notices.sh`) | print `MISSING-SECTION` without the section, so a count compared with 0 fails; `notice_lines` against a pattern's absence, and `without_notice_boxes` in a comparison, still pass on a failed run | none: the call sites carry shapes 2 and 3 |
  | `strip_nondeterministic`, `drop_run_figure_rows` (`nondeterministic.sh`) | turn empty input into empty output, exit 0 | none: comparisons are guarded at the call site (shape 2) |
  | `csv_cache_produce` (`csv-cache.sh`) | returns non-zero on a failed run or missing products; counts nothing | none |
  | `screenshot-cells.pl` | a mode compared the image with a capture that held nothing in the crop and could pass | fails when the crop of the capture holds no character (not in `png` mode, which reads none); shown failing on an empty capture and passing on one with text |
  | `surface-capture.pl` | `no-trace` passes on two empty captures; `panes`, `unmoved` and `plain` need what they measure | none: no harness calls `no-trace` |
  | `verbose-content-shape.pl` | passes with an empty `--registered` list | none: its one caller refuses an empty registry first |
  | `logs-dir.sh`, `fixtures.sh`, `run-dir.sh`, `colour-env.sh`, `require-bash.sh`, `scenario-select.sh`, `rendered-output.pl` | read no `ltl` output, or decode only | none |
- **The capture checker** is `process/check-harness-capture.pl`: it reads a
  harness capture (its exit status from `<capture>.rc`) and reports the summary
  reached, the passed and failed counts, the PASS lines against the passed
  count, and every PASS line. On the baseline it reports two count mismatches:
  `validate-classification-percentages.sh` (43 passed, 42 PASS lines: an XPASS
  counted without a PASS line) and `validate-csv-output.sh` (44 against 112:
  its validator prints a PASS line per CSV file where the summary counts
  scenarios, by design).
- Runs: `validate-read-path.sh` paths-by-size and threshold-values (12 passed),
  `validate-explain.sh` wiki-sync-map (15), and on the consumers of the two
  helper changes `validate-histogram-colours.sh` legend-text-default,
  `validate-regression.sh` access-w120, `validate-classification-percentages.sh`
  soft-wrap, `validate-section-layout.sh` layout-baseline and
  `validate-screenshot-capture.sh` crop-cells, colours and faint: all pass on
  the real `ltl`.

### Drop 2

Every confirmation below names all of the harness's scenarios (or those
listed) with `--scenario`, against the real `ltl`, the failing stub and the
silent stub, one run at a time, captures read by
`process/check-harness-capture.pl`. The stubs are in the session scratchpad
(`baseline/stubs/{failing,silent,noise}/ltl`): failing prints nothing and exits
1, silent prints nothing and exits 0, and noise prints one unrelated line and
exits 0 (the doctored input that proves an evidence guard fails when a run
succeeds without writing what the check reads).

Twelve harnesses changed; the five where reading found no case
(verbose-content-shape, message-grouping-notices, profile-render,
numeric-criteria-notices, doc-examples) are unchanged.

| Harness | Change | Real | Failing / silent stub | Proof (AC6) |
|---|---|---|---|---|
| outcome-criteria | captures moved after `scenario_parse_args`, each records `<capture>.rc` and counts one FAIL on a non-zero exit or an empty capture (no more `exit`); `captured()`; `assert_command` gains a `reads "CAPTURE ..."` field and prints SKIP, counting nothing, when a capture it reads failed; `cls_key` sentinels name the capture (`MISSING-...-IN-<file>`); the retired names asserted by exit and message through `refused_as_unknown()` (message `unknown option '--<name>'`); the renamed forms need `LINES READ 15` | 26 passed (unchanged) | summary reached, 0 passed, 17 failed, 23 SKIP, exit 1 | the refusal and the acceptance checks fail on the stubs; two doctored captures without the block give different sentinels |
| memory-usage | `run_ltl` writes `<tag>.rc` and counts a FAIL on an empty output too; `produced <tag> <pattern> <label>` skips a check whose run failed and fails it when the run lacks the evidence; the seven checks wrapped (no grouping callers: `^site: `; two readings per compile: `^scan_subs_compiled: [0-9]`; no section: `^=== benchmark-data ===$`; no debug sub-section and nothing on stderr: `^=== memory-usage ===$`; record shape: a `decomposition` record; sample shape: a `sample` record) | 23 (unchanged) | 1 passed (run-free: debug-samples input lines), 27 failed | the noise stub fails all seven |
| distribution-shape | `generate_and_run` returns 1 instead of `exit 1` (it runs inside `$( )`); `anchor_failed()` counts the failure in the main shell at the three call sites | 8 (unchanged) | 0 passed, 3 failed | the failure is now counted where the harness used to stop with 0 |
| profile | `incl=` and `drop=` lookups carry `\|\| var=""` (a case the review-gate grep found after the reading missed it) | 15 on workweek, weekends, profile-off | 0 passed, 3 failed | a doctored section without the keys: the old line stops under `set -euo pipefail`, the new one goes on |
| classification-states | `--help formats` absence needs `^Log formats ltl recognises`; the clean-run absence needs exit 0 and a `SUCCESS CLASSIFIED` row; the two source absences need `^sub resolve_message_classification_states` and `^sub format_classification_src` in the source read, with a detail line; `gs=`, `gf=`, `col=`, `row=` lookups carry `\|\| var=""` | 56 (unchanged) | 1 passed (run-free: producer/fixture-tracked), 46 failed | the four absences fail on the stubs |
| histogram-colours | `capture_run` counts a FAIL and returns 1 (callers `\|\| return 0` or `if capture_run ...`); a missing layout table is a FAIL, not an exit; "the run exits 0" also needs `^=== section-layout ===$` in the capture | 21 (unchanged) | 0 passed, 8 failed | "the run exits 0" fails on the silent stub |
| category-names | `capture_render` counts a FAIL and returns 1; the three render scenarios and the CSV scenario run their checks only after a good capture (bodies left at column 0, as the file's scenario bodies are, which keeps the here-document terminators valid) | 26 (unchanged) | 0 passed, 4 failed | the stub runs reach the summary |
| help-layout | a missing layout constant and a failed or empty `--help` run each count one FAIL (`emit_fail`) instead of exiting; `needs SCENARIO layout\|help` skips the scenarios that read what is missing; each alignment inspector exits 4 when it checked no row (the option-row one also when no continuation row), counted as a FAIL; each inspector's exit is read with `\|\| rc=$?`, since under `set -e` any non-zero exit, a misaligned row's 2 included, ended the harness before its summary | 6 (unchanged; 110 option rows, 253 continuation rows, 105 short+long rows checked) | 0 passed, 2 failed, 4 SKIP | a doctored `ltl` whose source holds the three constants and whose `--help` prints one unrelated line: 3 passed on the committed harness, 4 failed now; one whose `--help` holds a misaligned row: the committed harness exits 2 with no summary, now 1 FAIL and the next scenario runs |
| regression | the empty-capture check moves ahead of the soft-wrap check in `run_test` (drop 1's `assert_no_soft_wrap` now fails an empty capture, which would have named the width as the cause) | 4 on access-w80, access-w120, hg-duration-w160, errrate-diagnostics-highlighted-failure-w160 (unchanged; the last still XFAIL on its known wrap) | failing: 4 failed, each "ltl exited 1"; silent: 4 failed, each "captured output is empty" | on the silent stub the base commit printed "XPASS errrate-diagnostics-highlighted-failure-w160 :: no longer exceeds its terminal width — remove its entry" for an empty run; now that run is one FAIL naming the empty capture |
| csv-output | the cache-validity block's first `csv_cache_produce` failure is one counted FAIL (`cache_assert`) and the five staleness and refresh checks are skipped with a SKIP line, where it was `exit 1` before the summary | 8 on gc-g1-categories, key-cut-csv (with the five cache checks; unchanged) | failing: 0 passed, 3 failed; silent: 0 passed, 4 failed; both reach the summary, where the base commit stopped at the cache block on both | the counted FAIL and the summary on both stubs |
| message-truncation | "no ellipsis under the right cut" first needs the messages table in the `-mt right` render and a non-empty messages CSV, each missing one named in the failure; the `grep` it negates was given an empty file name on a run without a CSV, and its error exit, negated, passed | 27 on all five scenarios (unchanged) | failing: 0 passed, 47 failed; silent: 0 passed, 27 failed (1 passed each at the base commit, this check) | a doctored `ltl` that prints the table heading and a row but writes no CSV: the committed harness passes the check, now it fails with "no messages CSV under -mt right" |
| message-control-characters | the six `exit 1` (a non-zero exit or an empty render in each of the first two scenarios, a non-zero exit in the third, no messages CSV in the first) become one counted FAIL through `run_failed`, and the scenario's checks are skipped with a SKIP line (`scenario_ok`) | 11 on all three scenarios (unchanged) | failing: 0 passed, 3 failed (one per scenario); silent: 0 passed, 5 failed (two empty renders, and the third scenario's three checks fail on their own anchors); both reach the summary, where the base commit stopped at the first scenario | the counted FAILs and the summary on both stubs |

The steps, in order:

1. ~~Confirm help-layout~~ (done, in the table above).
2. ~~regression~~ (done, in the table above).
3. ~~csv-output~~ (done, in the table above).
4. ~~message-truncation~~ (done, in the table above).
5. ~~message-control-characters~~ (done, in the table above).
6. ~~Greps and the no-case harnesses~~ (done): the review-gate greps over
   the twelve changed harnesses list no remaining `exit` but environment and
   fixture checks made before any run, exits inside a Perl inspector or an
   `eval` subshell, and the summary's own; every shape-10 lookup left either
   cannot fail (`sed -n`, `awk`, `find`, `\|\| var=""`) or runs inside a
   subshell with `set -e` off. The five no-case harnesses (verbose-content-shape,
   message-grouping-notices, profile-render, numeric-criteria-notices,
   doc-examples) are unchanged and call no helper drop 1 changed; the
   baseline's stub runs stand (each reached its summary with 0 passed on both
   stubs). Against the noise stub, the first four fail every check (1, 4, 50,
   10); doc-examples passes all 51 (§ Observations).
7. ~~The method, the record, the worktree check~~ (done): the method revised
   as below; § Per-harness record filled for drop 2; the twelve changed
   harnesses run from the scratchpad worktree (its `logs` a symlink to the
   main checkout's corpus), with `LTL` unset and with each stub, report the
   same summary, exit and passed count as from the main checkout, 36 runs.
   After it, the run-failure lines of category-names, memory-usage and
   message-control-characters gained the `asserts`, `produced_by` and
   `contract` lines the other harnesses' carry; rerun from the main checkout
   on the real `ltl` and both stubs, with the same counts.

What the reading of drops 2 to 6 added to the method (step 7, now in
`tests/HARNESS-DESIGN.md`: shapes 13 and 14, a status-read grep under 11,
shapes 2 and 4 widened, the fix forms, and the note that the greps are run):

- **A helper or a check that ends the harness on a failed run with `exit`**
  (most of the stops found): the run is one counted FAIL and the checks that
  read it are skipped.
- **Success asserted by its exit code alone** ("the run exits 0", `assert_exit
  0`, `[ $rc = 0 ]`): the silent stub satisfies it; the fix adds a line the run
  always writes.
- **Two lookups that fail alike compare equal**: two `MISSING-...` sentinels
  of the same text, two empty strings, `"/"` against `"/"`, `"||"` against
  `"||"`, 20 identical empty result lines; the fix names the capture in the
  sentinel, or requires the lookup non-empty first.
- **An inequality against a run that may have failed** (`! cmp -s A B`): holds
  when one side is empty.
- **A shape check over every record holds over none**: belongs with shape 4.
- **The patterns the fixes use**: `reads` on `assert_command`, a `produced`
  guard, `needs`, `captured()`; a skipped check prints SKIP and counts nothing.
- **Grep coverage**: the shape-10 grep must be run, not only read past: the two
  cases the reading missed (value-display, notices) and the one in profile
  were all `x=$(grep ... | ...)` assignments it lists.

Working notes for whoever resumes:

- The agent shell is zsh: an unquoted `$SC` holding several `--scenario`
  arguments is one word; use `${=SC}` or spell the arguments out.
- `process/claude-hooks/guard-bash.sh` reads an unquoted assignment of a path
  ending in `/ltl` (`STUB=.../failing/ltl`) as a run of `ltl` without
  `--disable-progress` and blocks it; quote the value
  (`LTL="$SD/failing/ltl"`).
- Every harness run is a direct command naming `tests/validate-<name>.sh`, so
  the Bash guard sees it; no wrapper script runs harnesses.
- A worktree for the drop checks exists under the scratchpad at `wt747`
  (detached at cdbc1205, with a `logs` symlink); move it to each drop's commit
  with `git -C <wt> checkout --detach <commit>`, and remove it at close-out with
  `git worktree remove`.

### Drop 3

Confirmations as in drop 2: each harness's scenarios named with `--scenario`,
on the real `ltl` and both stubs, one run at a time, read by
`process/check-harness-capture.pl`; the committed version of each harness is
run on the same input from the scratchpad worktree for the proof.

| Harness | Change | Real | Failing / silent stub | Proof (AC6) |
|---|---|---|---|---|
| read-path | `completed <run dir>...` (each run exited 0 and wrote its read-path section) guards the two output comparisons, which fail naming the run that did not complete; the identity whole passes only when all 54 shapes were compared, else SKIP; `altered_ltl` ends its `perl` with `\|\| return 1` (inside the caller's `\|\|`, `set -e` is off) and `no_altered_ltl` counts one FAIL and skips the scenario; "a die exits alike" needs the probe's die in both runs; the `line=`, `help=` and the two die lookups (`g=`, `s=`, built from two substitutions) carry `\|\| var=""` or `\|\| true`; "the threshold hidden" needs the `-D` row in `--help` first, else SKIP | 28 on all eight scenarios (unchanged) | failing: 1 passed, 74 failed; silent: 1 passed, 74 failed; the PASS is "-D in docs/usage.md" (run-free) | on the silent stub the committed harness passes "mixed sizes" and "54 option shapes" and stops at the fallback scenario, exit 255, no summary; on an `ltl` whose loop never reaches the probe it stops at the die lookup, and with that stop removed passes "a die exits alike (0\|)" and "the threshold hidden (0\|0)"; the fixed harness fails the first and skips the second |
| aggregate-export | `run_export` clears `YAML_FILE`, `STATS_CSV`, `MSG_CSV` and `OUT` first, so a check never reads an earlier scenario's export, and a non-zero exit is one FAIL with a SKIP (`no_export`) where it was `exit 1`; the directories-relative and environment-options runs the same; the `env_line=`, `col=`, `bd_*=`, `tv=` and `opt_line=` lookups and the `section_value` helper, read in the written-export branches, cannot stop the harness on a run that wrote its export but lacks a line (not reached by either stub, the same shape); "duration.mean is the in-memory value", an inequality, needs the CSV's value first | 163 on all thirteen scenarios (unchanged) | failing: 0 passed, 39 failed; silent: 0 passed, 39 failed (14 runs, 25 oracle-chain rows) | an `ltl` that fails only under `-pr`: the committed harness passes no-surfaces then stops at profile-week-heading with no summary; now that run is one FAIL and a SKIP, and the summary follows |
| bucket-size-units | the equivalence rows' timeline comparison is skipped when a run failed (counted by "run exits 0") and fails when a run printed nothing; "a bare number is never rejected" also needs the fixture's first timeline row (`2025-05-07 10:00`); the `-ru w` run is made under `set +e`, since its subshell inherited errexit and a failed run ended the harness | 64 on all scenarios (unchanged) | failing: 0 passed, 119 failed; silent: 0 passed, 64 failed (17 timelines reported as printing nothing) | the base commit's silent-stub run passed 18 (17 "timeline byte-identical" and the bare number) and its failing-stub run stopped at the `-ru w` run; now neither passes anything and both reach the summary |
| byte-units | the five source absences (no private byte table, byte tokens and multipliers only in the ladder, no unit-keyed decimals table, no prefix-letter table) are skipped when the source read holds no `@byte_unit_ladder`, which `one-ladder` counts; the GC run's "exits 0" also needs the STATS CSV it writes | 48 on all scenarios (unchanged) | failing: 0 passed, 43 failed; silent: 0 passed, 43 failed | the base commit's silent-stub run passed six (the five absences over the stub's source and the GC exit); now none |
| histogram-ticks | each run records its exit (`\|\| rc=$?` where it was `\|\| true`), and `run_unusable` counts one FAIL and skips the run's checks when it exited non-zero or wrote no `-V histogram-percentile-ticks` section; a SKIP verdict of the tick-position inspector prints SKIP and counts nothing, where it counted a pass (Trap 6; never reached on the real run, so the count is unchanged) | 21 on all five scenarios (unchanged) | failing: 0 passed, 5 failed; silent: 0 passed, 5 failed | the base commit passed nine on each stub ("no tick characters outside axis lines" and "tick chars match axis frame colour" at four widths, and the multi-histogram's out-of-axis check, all over an empty capture); now none |
| classification-percentages | as outcome-criteria: the ten captures run after `scenario_parse_args` (an unknown scenario name now exits 2 having run nothing), each records `<capture>.rc`, and a non-zero exit, an empty capture or a missing debug-layout table is one counted FAIL (`capture_failed`) where it was `exit 1`; every check names the captures it reads (`reads`) and is skipped when one failed, the nine runtime-warning checks included; the leakage run is recorded the same way; the soft-wrap check is skipped on a failed capture, an XFAIL counts nothing (as regression) and an XPASS prints its PASS line beside the count it already made | 43 on all fourteen scenarios (unchanged), and 43 PASS lines where there were 42 | failing: 0 passed, 11 failed, 43 SKIP; silent: the same | the base commit stopped at the first capture on both stubs (no summary); now both reach it with nothing passed |
| statistics | none: read again with the widened greps; every lookup that can fail runs under `set +e`, and every exit is an environment check made before any run | not run (unchanged, 25 at the baseline) | 0 passed at the baseline on both stubs, summary reached | — |
| csv-input | "mixed glob exits 0" and the stderr absence beside it need the run's format-detection block to name `stats.csv`; the `index_lines` lookup carries `\|\| index_lines=0`; `assert_command` evaluates each command in a subshell, since in the harness's own shell a notices sentinel read as a number (`[[ MISSING-SECTION -eq 1 ]]`) is an unbound-variable error under `set -u` that ended the harness (shape 15, found by the silent-stub run) | 43 on all scenarios (unchanged) | failing: 0 passed, 43 failed; silent: 0 passed, 43 failed; both reach the summary | the base commit passed the stderr absence on the failing stub and both quoted-timestamp checks on the silent stub, and stopped on both (at the index lookup, and in the unbound-metric-note scenario); now neither passes anything and both reach the summary |
| option-resolution | the three source absences (bound scalars and bound names only in the declaration, one number-unit split) are skipped when the source read holds no `@quantity_options`, which `one-declaration` counts; bare-unchanged's "exit" also needs the option-resolution section; "-X v counts as -X bare" needs `excluded_numeric` in both runs, since two runs without it compared `/` with `/`; the printed-spellings reader carries `\|\| true`, so its existing empty-list check counts the failure instead of the harness stopping | 187 on all scenarios (unchanged) | failing: 0 passed, 102 failed; silent: the same | the base commit passed eleven on the failing stub and twelve on the silent one (the three absences, the eight unit-equivalent comparisons of `/` with `/`, and the exit), and stopped on both at the spellings reader ("no @time_unit_ladder"); now none, and both reach the summary |
| recursive-file-selection | "the same failure without -r carries no quoting guidance" first needs the could-not-open-any-files refusal in that run's stderr; "a -r run that selected files carries no quoting guidance" needs that run's selection lines (`silent.sel` non-empty) where it took the stderr file's existence, which a failed run also leaves | 36 on all thirteen scenarios (unchanged) | failing: 0 passed, 27 failed; silent: 0 passed, 28 failed | the base commit passed both guidance absences on each stub; now neither |
| value-display | the zero-duration `unit=` lookup carries `\|\| unit=""` (its existing empty check then counts the failure) and the cv-agreement `csv=` lookup `\|\| csv=""` | 60 on all scenarios (unchanged) | failing: 0 passed, 14 failed; silent: the same | the base commit stopped on both stubs at the `unit=` lookup (no summary); now both reach it |

Ten harnesses changed; statistics, read again, has no case. The ten,
run from the scratchpad worktree (its `logs` a symlink to the main
checkout's corpus) with `LTL` unset and with each stub, report the same
summary, exit and passed count as from the main checkout, 30 runs.

The histogram-ticks row of § Per-harness record lacked its two stub columns
from drop 1 on (the `|` in its summary cell split the row); they are restored
from the baseline's index (9 passed on each stub, summary reached).

What drop 3 adds to the method: grep 10 also lists an assignment whose value
is quoted (`g="$(...)"`), which it missed before; read-path's die lookups
were found by running it, not by the grep. Over the drop 2 harnesses the
widened grep lists no further stop.

Shape 15 (drop 3): a check's command `eval`ed in the harness's own shell
stops it under `set -u` or on an `exit`; grep 15 lists format-detection,
histogram-bin-counters, index-read-back, statistics-demand, udm-counting and
udm-specs, each fixed in its own drop.

### Fix designs read ahead (drops 3 to 6)

The cases are in § Per-harness record; the fix each one takes, where it is
more than the method's table gives:

- **read-path**: the comparisons need both runs' `threshold_bytes` (or, for the
  die, both captures naming the probe); "N option shapes equal" counts the
  shapes compared and passes only when every shape was; `altered_ltl` ends its
  perl with `\|\| return 1` (inside `\|\|` the caller's `set -e` is off) and the
  callers fail and return; `line=` and `help=` lookups carry `\|\| var=""`;
  "the threshold hidden" needs the `-D, --debug` row in the capture first.
- **aggregate-export**: `run_export` resets `YAML_FILE`, `STATS_CSV`, `MSG_CSV`
  and `OUT` first, then counts a FAIL and returns 1 on a failed run; the two
  inline runs the same.
- **bucket-size-units**: an equivalence row compares timelines only when both
  runs exited 0 and printed (a failed run is already counted; an empty one
  fails); "a bare number is never rejected" needs a timeline row; the `-ru w`
  run moves inside `set +e` with its exit read from the subshell.
- **byte-units**: the five source absences are gated on the ladder
  declaration found (`$source_ok`); the GC "exits 0" needs its STATS CSV.
- **histogram-ticks**: record each run's exit and output, count one FAIL and
  skip the run's checks; a SKIP verdict prints SKIP and counts nothing.
- **classification-percentages**: as outcome-criteria (captures after the
  selector, `reads`); XFAIL counts nothing, as in regression; XPASS prints its
  PASS line too.
- **csv-input**: the mixed-glob exit and the no-message absence need the run's
  format-detection section naming `stats.csv`; `index_lines` carries
  `\|\| index_lines=0`.
- **option-resolution**: the three source absences gated on the declaration;
  "exit" needs the option-resolution section; the unit-equivalence checks need
  `excluded_numeric` on both runs; the printed-spellings reader carries
  `\|\| true` and its existing empty-list check fails it.
- **recursive-file-selection**: the without-`-r` guidance absence needs the
  refusal message first; the `-r` one needs `silent.sel` non-empty.
- **value-display**: `unit=` carries `\|\| unit=""`.
- **progress-line, log-level-vocabulary, summary-contribution-bar,
  message-control-characters, category-names**: the capture or scenario `exit`
  becomes a counted FAIL with the scenario's checks skipped.
- **heatmap-palette, format-registry**: the run helper is called directly and
  hands its capture path back through a variable, counting its failure in the
  main shell; format-registry's unknown `-lf` check needs its message; its
  unarmed-measurement absence needs the format-detection section.
- **udm-counting**: the two bare `-xu` runs carry `\|\| true`.
- **screenshot-capture**: `capture_ltl`, the palette run and the index seed run
  record their exit and output, count a FAIL and skip the checks reading them
  (the `screenshot-cells.pl` guard of drop 1 already fails the colours check
  on an empty capture).
- **notices**: a `ran <tag>` guard (exit 0 and output) before the four
  absences; the two source absences need the scan non-empty; the two tmux
  checks need the box drawn in the `up` capture and the answered marker in
  the `chosen` capture; `title_row=` carries `\|\| title_row=""`.
- **section-layout**: remember which column baselines succeeded and skip a
  log's checks when its baseline failed.
- **timestamp-precision**: `labels()` never fails (`{ grep ... \|\| true; }`);
  the four-digit-fraction absence needs the heading's last bound first;
  keyscale/structure needs `^sub read_and_process_logs` first.
- **runtime-config**: `assert_exit` takes the evidence line the run writes
  (its message, or a line every run of its shape prints); `assert_no_line`
  needs an evidence pattern present first.
- **help-content**: the three top-level exits become counted FAILs with a
  `needs`-style skip; the description-quality and no-branch-per-topic source
  absences need the scanned rows present; the `-uuid` and long-byte-word
  absences need the capture's exit 0 and content; `assert_equal` fails on an
  empty actual (check every caller first).
- **histogram-bin-counters**: `assert_no_line` needs the section header;
  the `heatmap_cells_highlighted` absence needs the block present.
- **udm-specs**: `assert_absent` fails on an empty file or a `MISSING-SECTION`
  notices file; the twenty-runs check needs every result line's three fields;
  the nine no-warning checks need the run's `read_as` line; the four exits 0
  need the section (or `TOP OVERALL MESSAGES`).

## Observations

Found while reading, outside this issue's condition (a failed or silent
`ltl`); recorded here and named in the completion comment.

- **A selection that leaves a scenario out.** `validate-category-names.sh`,
  `validate-message-control-characters.sh` and
  `validate-summary-contribution-bar.sh` print their summary and exit inside
  their last scenario's `if` block, so `--scenario` naming any other scenario
  prints no summary and exits 0 even after a FAIL.
  `validate-message-grouping.sh` sets `DOWNLOAD_KEYS` and `out_downloads_75`
  inside other scenarios' blocks, so `--scenario signed-downloads-75` or
  `--scenario signed-downloads-75-repeat` alone stops on an unbound variable.
- **Standard error discarded.** `validate-log-level-vocabulary.sh`
  (`check_failure_count_rises_with_added_severities`,
  `check_error_rate_counts_fatal`) and `validate-udm-specs.sh`
  (collision-operands' control run) send `ltl`'s standard error to
  `/dev/null`, so the runtime-warning check never reads it (§ Runtime-warning
  cleanliness).
- **A stale known failure.** `tests/rendered-output/soft-wrap-known-failures.tsv`
  carries `classification-percentages-w120-access-120` (#497), and
  `validate-classification-percentages.sh` reports it XPASS on the base commit:
  the capture no longer exceeds its width.
- **A contract that names a record no longer kept.**
  `validate-help-layout.sh` `assert_pair` gives as its contract
  "MEMORY.md feedback_short_forms_required", a machine-local memory file that
  was removed; the rule it cites is CLAUDE.md's "a new option has a short
  form, a long form, a `print_help()` row and a `docs/usage.md` row".
- **A run that prints something unrelated and exits 0.**
  `validate-doc-examples.sh` passes all 51 of its checks against a stub that
  prints one unrelated line and exits 0: its stated contract is "exit code 0
  AND non-empty stdout for each runnable example" (the header of the
  harness), so any output satisfies it. It fails every check on the failing
  and the silent stub, which are this issue's condition (§ Acceptance
  criteria); a run that exits 0 with output that is not `ltl`'s is outside it.
- **Captures left behind.** `validate-heatmap-palette.sh` `run_section` and
  `validate-histogram-bin-counters.sh` `run_section` write their captures with
  `mktemp` outside the harness's own directory; the second removes them per
  scenario, the first never does (Trap 10).

