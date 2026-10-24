# 747: no harness check passes on a run that failed, and no harness stops before its summary

Issue: #747 (a harness check passes, or the harness stops early, when the
`ltl` run it reads failed). Parent: #729 (process, tests and build).

Status: drop 1 done 2026-10-24 (cdbc1205, pushed). Drop 2 done 2026-10-24
(bf390713): twelve of its seventeen harnesses fixed, the method revised.
Drop 3 done 2026-10-24 (848b26d8): ten of its eleven harnesses fixed, shape
15 added. Drop 4 done 2026-10-24 (222eff02): six of its eight harnesses
fixed (§ Drop 4). D4 done 2026-10-24 (51a95f55): the four selection defects
fixed (§ D4: the selection defects). Drop 5 done 2026-10-24 (9ebc1bf1): five
of its six harnesses fixed (§ Drop 5). Drop 6 done 2026-10-24 (ffd7a142):
three of its four harnesses fixed (§ Drop 6). Drop 7 done 2026-10-24
(8d2db3cd): five of its six harnesses fixed (§ Drop 7). Drop 8 done
2026-10-24 (b59c637d): the failed-run checker (§ Drop 8). Completion gate
passed 2026-10-24 on e3bfbccc (§ Completion gate). Merged into
`release/0.20.0` by PR #755 as 4c8d1fae; issue closed 2026-10-24. Stage 2
(§ Stage 2: the observations) started 2026-10-24 on the architect's word: #747
reopened, branch `747-harness-checks-on-a-failed-run-2` off `release/0.20.0`
at cd4c3639, the `747-before` benchmark captured there. Drop S2-1 done
2026-10-24 (67a60617): the noise-stub baseline, the method's third question, and the
recorded observations S1 to S7 fixed (§ Drop S2-1). D6 (the architect):
the two observations drop S2-1 found are fixed in their harnesses' drops.
Next: drop S2-2.
Drops 5 and 6 were read during the baseline run; their cases are in
§ Per-harness record and their fix designs in § Fix designs read ahead. D3
(the architect, during drop 1) adds drop 8, a final stage after drop 7.

## Resuming

The requirements, the acceptance criteria and the delivery plan below were
agreed by the architect on 2026-10-24, and work started that day on branch
`747-harness-checks-on-a-failed-run` off `release/0.20.0`. This document is
carried on the issue branch: each drop's commit updates § Per-harness record
and the status line, and the document reaches the release branch with the PR,
as the work merged by PR #754 did with its own. Drops 1 to 7, D4 (the four
selection defects), drop 8 (D3: the failed-run checker,
`tests/validate-harness-failed-run.sh`), the completion gate (§ Completion
gate), the PR (#755), the merge and the close-out are done. § Stage 2: the
observations, planned 2026-10-24 at the architect's request, is under way on
branch `747-harness-checks-on-a-failed-run-2`: eight drops and a gate, as its
Delivery says (D5: every harness read again against a run that prints
something unrelated); its status line says which drop is next. The scratchpad worktree
and stubs do not survive the session: a new session makes them again as
§ Drop 2 describes (stubs: `failing` prints nothing and exits 1, `silent`
prints nothing and exits 0, each a two-line Perl script).

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
- **D4** (the architect, 2026-10-24, after drop 4). The four selection defects
  of § Observations (A selection that leaves a scenario out) are fixed under
  this issue, though outside its condition: in
  `validate-category-names.sh`, `validate-message-control-characters.sh` and
  `validate-summary-contribution-bar.sh` the summary and its exit move after
  the last scenario's block, so a `--scenario` naming any other scenario
  prints the summary and exits non-zero after a FAIL; in
  `validate-message-grouping.sh` `DOWNLOAD_KEYS` and `out_downloads_75` are set
  where both scenarios that read them can, so `--scenario signed-downloads-75`
  or `--scenario signed-downloads-75-repeat` alone runs. Each fix is proven by
  running a scenario other than the last alone, on the committed harness and
  the fixed one, with a failure (a stub run). Done in one commit of its own
  before drop 5 (§ D4: the selection defects).
- **D5** (the architect, 2026-10-24, after the close-out). Stage 2 (§ Stage
  2: the observations) also takes, across every harness, the condition two of
  its observations point at: a run of `ltl` that exits 0 having printed one
  line unrelated to what it was asked for. Every harness is read again for a
  check that holds on such a run, and the failed-run checker runs each
  harness against that stub (the **noise stub**) as it does against the
  failing and silent ones. A check that reads a capture holds only on
  evidence that the run wrote the section, table, row or file it reads:
  exit 0 and a non-empty capture are not that evidence. Chosen over keeping
  stage 2 to the recorded observations and filing the condition as an issue
  of its own.
- **D6** (the architect, 2026-10-24, after drop S2-1). The two observations
  drop S2-1 found (§ Observations: captures left behind beyond S5's two, and
  two comments that cite a record no longer kept) are fixed under stage 2,
  each in the drop that reads its harness whole: help-layout, csv-output and
  doc-examples in S2-2; histogram-ticks and statistics in S2-3; help-content
  in S2-6; index-read-back and statistics-demand in S2-7. S2-AC5 widens to
  every harness (no run leaves a file outside its own directory), S2-AC3 to
  every comment (none cites a record not kept). Chosen over fixing all of
  them in one follow-up of drop S2-1, which would run those harnesses twice,
  and over leaving them recorded only, which leaves every run of
  index-read-back and statistics-demand adding files to `$TMPDIR`.

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

- [x] **AC1. Against the failing stub, every harness reaches its summary.**
      `LTL=<failing stub> ./tests/validate-<name>.sh`, for each harness that
      runs `ltl`. Pass when: the output ends with the harness's summary line
      and the exit status is non-zero. *Assertable*: the run and its captured
      output.
- [x] **AC2. Against the failing stub, only run-free checks pass.** Pass
      when: every check the run counts as passed is one named for that harness
      in § Per-harness record as run-free, and the run's PASS lines number as
      many as its passed count; a harness with none reports 0 passed. One
      exception, by D1: in `validate-screenshot-capture.sh`, a check reading
      the output of `process/capture-screenshots.pl` passes, since the tool
      ran the repository's `ltl`; each is named in the record as such.
      *Assertable*: the run's PASS lines against the list, through the
      capture checker of drop 1.
- [x] **AC3. The silent stub, the same.** AC1 and AC2 hold with the silent
      stub, which exits 0 and so reaches the checks that read the capture
      rather than the exit code. *Assertable*: as AC1 and AC2.
- [x] **AC4. A healthy run loses no check.** Against the real `ltl`, every
      harness exits 0, and its passed count equals the count before this work
      plus the checks this work adds, each named in § Per-harness record.
      *Assertable*: the summary counts of drop 1's baseline run of the full
      suite on the base commit, against the gate's run, on the same machine.
- [x] **AC5. Every harness takes the stub.** Every harness that runs `ltl`
      reads it from `LTL` when set, `validate-read-path.sh` included (D1).
      *Assertable*: AC1 runs on every such harness.
- [x] **AC6. Each fix can fail.** A check this work adds or changes is shown
      to fail on the stub run or on a doctored capture before it is trusted
      (`tests/HARNESS-DESIGN.md` § Proving a new assertion can fail).
      *Assertable*: the run is recorded with the fix.
- [x] **AC7. The method is written down.** `tests/HARNESS-DESIGN.md` carries
      the reading of R4: a row and a review-gate grep for every shape R1
      names and every shape the drops added. *Assertable*: at the gate the
      greps run over every harness, and each line they list is accounted for
      in § Per-harness record, as a case fixed or as read and not a case.
- [x] **AC8. The release procedure and read-path agree (D1).** The second
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
drop, while the baseline ran. The noise-stub column is stage 2's baseline
(drop S2-1, base `cd4c3639`, every scenario named, run from a scratchpad
worktree): `passed (U unmarked) / summary reached (time)`, U being the PASS
lines not marked run-free, the candidate list for drops S2-2 to S2-7. On it,
18 harnesses print 377 PASS lines not marked run-free, and one of them,
index-read-back, also stops before its summary, at its
`index-heatmap-bytes-preseed` scenario.

| Harness | Drop | Summary line | Passed on real `ltl` | Failing stub | Silent stub | Noise stub | Cases found: check, shape, fix | Run-free checks |
|---|---|---|---|---|---|---|---|---|
| aggregate-export | 3 | `Results: N passed, M failed` | 163 (14 s) → 163 | 0 / no (0 s) → 0 / yes | 0 / yes (2 s) → 0 / yes | 0 / yes (1 s) | fixed in drop 3: run_export and two inline runs exit the harness on a failed run (stop); once fixed, run_export returns before resetting YAML_FILE, so the next check would read the previous scenario's export (5) | none |
| bucket-size-units | 3 | `Results: N passed, M failed` | 64 (57 s) → 64 | 0 / no (4 s) → 0 / yes | 18 / yes (3 s) → 0 / yes | 17 (17 unmarked) / yes (4 s) | fixed in drop 3: 22 equivalence rows compare two empty timelines (2); a bare number is never rejected: exit code alone (acceptance); the -ru w run's subshell exits under the inherited set -e (11) | none |
| byte-units | 3 | `Results: N passed, M failed` | 48 (7 s) → 48 | 5 / yes (0 s) → 0 / yes | 6 / yes (1 s) → 0 / yes | 0 / yes (0 s) | fixed in drop 3: five no-private-table checks: absence over a stub's source (7); the GC run exits 0: exit code alone (acceptance) | none |
| category-names | 2 | `PASS: N FAIL: M` | 26 (2 s) → 26 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 8 (8 unmarked) / yes (0 s) | fixed in drop 2: capture_render and the CSV run exit the harness on a failed run (stop); the summary inside the last scenario's block, fixed under D4 | none |
| classification-percentages | 3 | `Results: N passed, M failed` | 43 (3 s) → 43 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 1 (1 unmarked) / yes (1 s) | fixed in drop 3: ten captures exit the harness before the scenarios parse (stop); ten runtime-warning PASSes would follow (8); the leakage run unchecked (8); XFAIL counts a pass and XPASS counts one without a PASS line, 43 against 42 on the base (12) | none |
| classification-states | 2 | `Results: N passed, M failed` | 56 (4 s) → 56 | 4 / yes (0 s) → 1 / yes | 5 / yes (0 s) → 1 / yes | 1 / yes (0 s) | fixed in drop 2: --help formats omits the format: absence on an empty capture (3); a clean run prints neither row: absence, exit unchecked (3); no -n 0 branch and the short-circuit retired: absence over a stub's source (7); per-bucket cell lookups and the CSV column and row lookups stop the harness when they find nothing (10) | producer/fixture-tracked |
| csv-input | 3 | `Results: N passed, M failed` | 43 (9 s) → 43 | 0 / no (0 s) → 0 / yes | 0 / no (1 s) → 0 / yes | 0 / yes (1 s) | fixed in drop 3: mixed glob exits 0: exit code alone (acceptance); no timestamp message: absence on an empty stderr (3); the index line count lookup stops the harness (10); `assert_command` evaluated each command in the harness's own shell, where a notices sentinel read as a number is an unbound-variable error under `set -u` (15, found by the silent-stub run) | none |
| csv-output | 2 | `=== CSV output integrity: S scenarios, N pass, M fail ===` | 44 (16 s) → 8 on 2 scenarios | 0 / no (2 s) → 0 / yes | 0 / no (3 s) → 0 / yes | 0 / yes (2 s) | fixed in drop 2: cache-validity exits the harness when its first capture fails (stop) | none |
| distribution-shape | 2 | `Results: N passed, M failed` | 8 (3 s) → 8 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 0 / yes (0 s) | fixed in drop 2: generate_and_run exits inside `$( )` on a failed run: harness stops, failure uncounted (1, 10) | none |
| doc-examples | 2 | `Results: N passed, M failed, K skipped` | 51 (13 s) | 0 / yes (2 s) | 0 / yes (1 s) | 51 (51 unmarked) / yes (2 s) | none |  |
| duration-display | 7 | `Results: N passed, M failed` | 41 (5 s) | 0 / yes (0 s) | 0 / yes (0 s) | 1 (1 unmarked) / yes (0 s) | none (read in drop 7: every capture is checked for its exit and content before a check reads it, and the cell checker fails on a render with no cell) |  |
| explain | 7 | `Results: N passed, M failed` | 728 (36 s) → 728 | 65 / yes (4 s) → 61 / yes → 59 / yes | 107 / yes (5 s) → 61 / yes → 59 / yes | 261 (200 unmarked) / yes (5 s) | fixed in drop 7: 46 exits 0 by exit code alone (14); four refusals by exit code alone, each beside a separate check of its message (6) | the 59 a stub run passes: the technique mirror (27: a section per topic, two no-internals absences), the wiki sync map and the release procedure that applies it (15), the mirrors' link form (5), the load-over-time mirror and user-guide checks (10), and the ANSI-strip probe the harness writes (2); the pager default and `strip_ansi`'s presence were marked too (61) until drop S2-1 read them through `$LTL` (S6) |
| filter-summary | 7 | `Results: N passed, M failed` | 146 (6 s) → 146 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 0 / yes (0 s) | fixed in drop 7: run_sections and summary-table-unchanged exit the harness on a failed run (stop); the summary table's no-new-row absence on an empty capture (3); each bad-bound refusal by exit code alone (6), with two absences on empty captures (3) | none |
| format-detection | 7 | `Results: N passed, M failed` | 472 (33 s) → 472 | 0 / no (0 s) → 3 / yes | 0 / no (0 s) → 3 / yes | 5 (2 unmarked) / yes (5 s) | fixed in drop 7: run_format_detection, run_classification_csv and run_byte_notation exit inside `$( )` on a failed run, and the assignment ends the harness (1, 13); four bare runs (11); two summary-row absences on empty captures (3); assert_command evaluates in the harness's own shell (15) | the CRLF fixture check and the two padded-level fixture checks (committed fixtures), the 3 a stub run passes |
| format-registry | 4 | `Results: N passed, M failed` | 59 (4 s) → 59 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 0 / yes (0 s) | fixed in drop 4: `out=$(run_format_registry)` exits inside `$( )` (1, 10); unknown -lf exits non-zero: exit code alone (6); two inline runs exit (stop); unarmed measurement: absence on an empty capture (3) | none |
| heatmap-palette | 4 | `Results: N passed, M failed` | 120 (6 s) → 120 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 2 (2 unmarked) / yes (0 s) | fixed in drop 4: `out=$(run_section)` exits inside `$( )`: stop, failure uncounted (1, 10); run_udm exits (stop); two exits 0 by exit code alone once fixed (acceptance) | none |
| help-content | 6 | `Results: N passed, M failed[, W warning(s)]` | 114 (5 s) → 114 | 0 / no (0 s) → 32 / yes | 0 / no (0 s) → 32 / yes | 34 (2 unmarked) / yes (1 s) | fixed in drop 6: three top-level exits before any scenario, which also ended `--list` on a stub (stop); description quality and no branch per topic: absence over a stub's source (7); no -uuid row and no long byte word: absence on an empty capture (3); four comparisons of two empty lookups (2) | B (GetOptions read from the source against docs/usage.md; skipped on a stub, whose source declares no options); the docs/usage.md halves of G, H, I, K, L and M, 32 checks (G 2, H 3, I 2, K 3, L 12, M 10), the 32 a stub run passes. J's docs/usage.md rows interpolate the lists the runs print, so they are not run-free |
| help-layout | 2 | `Results: N passed, M failed` | 6 (0 s) → 6 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 0 / yes (0 s) | fixed in drop 2: the layout constants missing from the source exit the harness (stop); the --help run unchecked, so the two inspectors pass on an empty capture (4); each inspector's non-zero exit, a misaligned row's included, ended the harness under `set -e` (11) | none |
| histogram-bin-counters | 6 | `Results: N passed, M failed` | 148 (7 s) → 148 | 5 / yes (1 s) → 0 / yes | 5 / yes (1 s) → 0 / yes | 0 / yes (1 s) | fixed in drop 6: four assert_no_line absences on an unchecked capture (3); heatmap_cells_highlighted carries no percentile field: absence on an empty block (3); assert_command evaluates its command in the harness's own shell (15) |  |
| histogram-colours | 2 | `Results: N passed, M failed` | 21 (2 s) → 21 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 10 (10 unmarked) / yes (0 s) | fixed in drop 2: capture_run and the layout-table check exit the harness on a failed run (stop); the run exits 0 asserted by exit code alone (acceptance) | none |
| histogram-ticks | 3 | `Total: T \| Passed: N \| Failed: M` | 21 (5 s) → 21 | 9 / yes (4 s) → 0 / yes | 9 / yes (3 s) → 0 / yes | 0 / yes (3 s) | fixed in drop 3: no tick outside the axis and tick colour parity pass on an empty capture, per width and on the multi-histogram run (3); a tick check not applicable counts a PASS (12) | none |
| index-read-back | 7 | `Results: N passed, M failed` | 107 (21 s) → 107 | 0 / no (1 s) → 6 / yes | 0 / no (2 s) → 6 / yes | 8 PASS lines (2 unmarked) / no (4 s) | fixed in drop 7: run_ltl records no exit status (1); six absences on an empty capture or an index no run touched (3); three comparisons of two empty lookups (2); no stray string comparison: absence over a stub's source (7); index lookups, the STATS CSV lookup and index edits after a run that wrote no index stop the harness (10, 11); assert_command evaluates in the harness's own shell (15) | the six helper self-tests (the harness's own edits of the committed index fixture), the 6 a stub run passes |
| log-level-vocabulary | 5 | `PASS: N FAIL: M` | 58 (3 s) → 58 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 0 / yes (0 s) | fixed in drop 5: seven scenario runs exit the harness on a failed or empty run, at nine exits (stop) |  |
| memory-usage | 2 | `Results: N passed, M failed` | 23 (4 s) → 23 | 8 / yes (0 s) → 1 / yes | 8 / yes (0 s) → 1 / yes | 1 / yes (1 s) | fixed in drop 2: absence on an empty capture: no grouping callers, no section, no debug sub-section, nothing on stderr (3); two readings per compile compares 0 with 0 (2); record shape and sample shape hold over no record (4) | debug-samples: input lines (a file the harness writes) |
| message-control-characters | 2 | `PASS: N FAIL: M` | 11 (1 s) → 11 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 2 (2 unmarked) / yes (0 s) | fixed in drop 2: six exits on a failed, empty or CSV-less run (stop); the summary inside the last scenario's block, fixed under D4 | none |
| message-discard | 6 | `Results: N passed, M failed` | 82 (18 s) | 0 / yes (1 s) | 0 / yes (0 s) | 0 / yes (0 s) | none (read again in drop 6 with the widened greps) |  |
| message-expose | 5 | `Results: N passed, M failed` | 62 (13 s) | 0 / yes (0 s) | 0 / yes (1 s) | 0 / yes (1 s) | none (read again in drop 5 with the widened greps) |  |
| message-grouping | 4 | `Results: N passed, M failed` | 51 (19 s) | 0 / yes (0 s) | 0 / yes (0 s) | 0 / yes (0 s) | none under this issue's condition (read again with drop 3's greps); a selection defect, § Observations, fixed under D4 |  |
| message-grouping-notices | 2 | `Results: N passed, M failed` | 4 (2 s) | 0 / yes (0 s) | 0 / yes (0 s) | 0 / yes (0 s) | none |  |
| message-mask | 4 | `Results: N passed, M failed` | 27 (15 s) | 0 / yes (1 s) | 0 / yes (0 s) | 0 / yes (0 s) | none (read again with drop 3's greps) |  |
| message-truncation | 2 | `PASS: N FAIL: M` | 27 (5 s) → 27 | 1 / yes (0 s) → 0 / yes | 1 / yes (1 s) → 0 / yes | 0 / yes (1 s) | fixed in drop 2: no ellipsis under the right cut: absence on an empty render and a missing CSV (3) | none |
| notices | 4 | `Results: N passed, M failed` | 188 (97 s) → 188 | 0 / no (64 s) → 1 / yes | 0 / no (63 s) → 1 / yes | 3 (2 unmarked) / yes (89 s) | fixed in drop 4: buttons-only, ASCII only, standard output only, nothing on standard error: absence on a failed run (3); no kind outside the inventory and every stderr site named: absence over a stub's source (7); the screen given back: absence on a pane that never drew (3); an answered choice locked: two identical empty panes (2); the title-row lookup in preread stops the harness (10; found by the stub run) | registered: reserved in the harness design |
| numeric-criteria-notices | 2 | `Results: N passed, M failed` | 10 (2 s) | 0 / yes (0 s) | 0 / yes (0 s) | 0 / yes (1 s) | none |  |
| option-resolution | 3 | `Results: N passed, M failed` | 187 (30 s) → 187 | 0 / no (1 s) → 0 / yes | 0 / no (1 s) → 0 / yes | 0 / yes (0 s) | fixed in drop 3: three source checks: absence over a stub's source (7); exit 0 asserted alone (acceptance); eight unit-counts-as-bare checks compare `/` with `/` (2); the printed-spellings source reader dies on a stub (11) | none |
| outcome-criteria | 2 | `Results: N passed, M failed` | 26 (4 s) → 26 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 14 (14 unmarked) / yes (1 s) | fixed in drop 2: capture() exits the harness on a failed run, before scenario_parse_args (stop, 11); two missing classification lookups compare equal in inert-outcomes (2); 14 runtime-warning PASSes on empty stderr (8); the retired names refused by exit code alone (6); the renamed forms accepted by exit code alone (acceptance) | none |
| profile | 2 | `Results: N passed, M failed` | 106 (5 s) → 15 on 3 scenarios | 0 / yes (0 s) → 0 / yes | 0 / yes (0 s) → 0 / yes | 0 / yes (0 s) | fixed in drop 2: the `samples_included` and `samples_dropped` lookups stop the harness when the section lacks them (10; listed by grep 10 after reading passed over them) | none |
| profile-render | 2 | `Results: N passed, M failed` | 50 (5 s) | 0 / yes (0 s) | 0 / yes (0 s) | 0 / yes (1 s) | none |  |
| progress-line | 4 | `Results: N passed, M failed` | 27 (3 s) → 27 | 0 / no (0 s) → 0 / yes | 0 / no (1 s) → 0 / yes | 8 (8 unmarked) / yes (0 s) | fixed in drop 4: capture_frames and the collision run exit the harness on a failed run, uncounted (stop); the frame pipelines' `grep -v` stopped the harness on empty input (found by the failing-stub run) | none |
| read-path | 3 | `Results: N passed, M failed` | 28 (65 s) → 28 | 28 / yes (65 s) (LTL pinned before D1) → 1 / yes | 28 / yes (64 s) (LTL pinned before D1) → 1 / yes | 1 / yes (3 s) | fixed in drop 3: mixed sizes, fallback, and a die exits alike: comparisons of two failed runs (2); N option shapes equal counted with no shape compared (12); altered_ltl, the probe-line lookup and the --help lookup stop the harness (10, 11); the threshold hidden: absence on an empty --help (3); the die lookups `g=` and `s=`, built from two substitutions, stop the harness on an `ltl` whose loop never reaches the probe (10, found by running it; grep 10 now lists a quoted value) | help-rows: -D in docs/usage.md |
| recursive-file-selection | 3 | `Results: N passed, M failed` | 36 (7 s) → 36 | 2 / yes (2 s) → 0 / yes | 2 / yes (3 s) → 0 / yes | 0 / yes (2 s) | fixed in drop 3: two no-quoting-guidance checks: absence on an empty stderr, one with only `[ -f ]` as evidence (3) | none |
| regression | 2 | `Results: N passed, M failed, K skipped` | 74 (28 s) → 4 on 4 scenarios | 0 / yes (4 s) → 0 / yes | 0 / yes (5 s) → 0 / yes | 0 / yes (6 s) | fixed in drop 2: the empty-capture check moved ahead of the width check; on the silent stub an empty run had reported its known wrap as XPASS, "remove its entry" (4) | none |
| runtime-config | 5 | `Results: N passed, M failed` | 119 (14 s) → 119 | 17 / yes (1 s) → 0 / yes | 19 / yes (1 s) → 0 / yes | 5 (5 unmarked) / yes (1 s) | fixed in drop 5: assert_exit counts a PASS by exit code alone: refusals (6) and acceptances (14); three assert_no_line absences on an empty capture (3); the five pushback runs' "says nothing on stderr" absences (3); "-V keeps no path test": absence over a stub's source (7) |  |
| scenario-selector | - | `Results: N passed, M failed` | 39 (141 s) | not run (runs no ltl) | not run (runs no ltl) | not run (runs no ltl) |  |  |
| screenshot-capture | 4 | `Results: N passed, M failed` | 44 (78 s) → 44 | 0 / no (3 s) → 29 / yes | 31 / yes (75 s) → 29 / yes | 29 / yes (76 s) | fixed in drop 4: capture_ltl, the palette run and the index seed run are bare and stop the harness (11); the panel colours compared with an empty capture pass (2; the helper guard is in place); `capture_ltl` returned 1 to bare calls on a trace without a capture run (11) | by D1, every check reading only the output of process/capture-screenshots.pl |
| section-layout | 5 | `Results: N passed, M failed` | 186 (32 s) → 186 | 0 / yes (1 s) → 0 / yes | 0 / yes (1 s) → 0 / yes | 45 (45 unmarked) / yes (5 s) | fixed in drop 5: -hi changes the render: an inequality against a baseline run that may have failed (2) |  |
| statistics | 3 | `=== Statistics drift: S scenarios, N pass, M fail ===` | 25 (299 s) | 0 / yes (1 s) | 0 / yes (1 s) | 0 / yes (1 s) | none (read again with drop 3's greps) |  |
| statistics-demand | 7 | `=== validate-statistics-demand: N passed, M failed ===` | 167 (23 s) → 167 | 3 / yes (2 s) → 1 / yes | 3 / yes (1 s) → 1 / yes | 1 / yes (2 s) | fixed in drop 7: no messages-table header and no MESSAGES CSV: absences on a run that printed nothing (3); assert_command evaluates in the harness's own shell (15) | scenario 13's fixture line count (a committed fixture), the 1 a stub run passes |
| summary-contribution-bar | 5 | `PASS: N FAIL: M` | 39 (3 s) → 39 | 0 / no (0 s) → 0 / yes | 0 / no (1 s) → 0 / yes | 0 / yes (0 s) | fixed in drop 5: capture_render exits the harness on a failed run (stop); the summary inside the last scenario's block, fixed under D4 |  |
| timestamp-precision | 5 | `Results: N passed, M failed` | 94 (20 s) → 94 | 0 / no (1 s) → 0 / yes | 0 / no (1 s) → 0 / yes | 0 / yes (2 s) | fixed in drop 5: labels() lookups stop the harness at seven assignments (10); the two STATS CSV lookups (`ls` of a glob that matches nothing) stop it (10, listed by grep 10 and found by the failing-stub run); no four-digit fraction: absence on a failed run (3); no bucket-key site reads -s or -ms: absence over a stub's source (7) |  |
| udm-counting | 4 | `Results: N passed, M failed` | 44 (6 s) → 44 | 0 / no (1 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 0 / yes (1 s) | fixed in drop 4: two bare -xu runs stop the harness (11); `assert_command` evaluated each command in the harness's own shell, where the users-in-CSV check's `exit 1` ended it (15; the stop the stub runs met) | none |
| udm-specs | 6 | `Results: N passed, M failed` | 250 (22 s) → 250 | 0 / no (0 s) → 0 / yes | 0 / no (1 s) → 0 / yes | 0 / yes (2 s) | fixed in drop 6: thirteen assert_absent checks pass on an empty capture or a missing notices section (3); "the run exits 0 where it previously died" reads an exit status `run_collision` records in a global inside `$( )`, always its initial 0 (1); five STATS, export and MESSAGES CSV lookups (`ls` of a glob that matches nothing) stop the harness (10); two STATS CSV header checks and the shorthand-names comparison compare two empty lookups (2); twenty runs report one unit compares 20 empty results (2); nine prints-no-warning checks: absence on an empty stderr (3); four exits 0 by exit code alone (14); assert_command evaluates its command in the harness's own shell (15) |  |
| value-display | 3 | `Results: N passed, M failed` | 60 (17 s) → 60 | 0 / no (0 s) → 0 / yes | 0 / no (0 s) → 0 / yes | 5 (5 unmarked) / yes (3 s) | fixed in drop 3: the resolved-unit lookup in zero-duration stops the harness (10; found by the stub run, missed by reading); the cv-agreement `csv=` lookup (10) | none |
| verbose-content-shape | 2 | `Results: N passed, M failed` | 1 (1 s) | 0 / yes (0 s) | 0 / yes (0 s) | 0 / yes (0 s) | none |  |

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

### Drop 4

Confirmations and proofs as in drop 3. Six harnesses changed; message-mask and
message-grouping, read again, have no case under this issue's condition. The
six, run from the scratchpad worktree with `LTL` unset and with each stub,
report the same summary, exit and passed count as from the main checkout, 18
runs. What drop 4 adds to the method: a bare pipeline whose `grep` matches
nothing stops the harness under `pipefail` as a bare command does (shape 11,
found by progress-line's failing-stub run).

| Harness | Change | Real | Failing / silent stub | Proof (AC6) |
|---|---|---|---|---|
| progress-line | `capture_frames` and the notice-collision run record their outcome (`<frames>.rc`) and count one FAIL (`run_failed`) where they exited; every check names the frames it reads (`reads`) and is skipped when that run failed; the frame pipelines' `grep -v '^$'` cannot stop the harness on empty input (found when the collision run's pipeline stopped the failing-stub run) | 27 on all seven scenarios (unchanged) | failing: 0 passed, 10 failed; silent: the same | the base commit stopped at the first capture on both stubs (no summary); now both reach it with nothing passed |
| heatmap-palette | `run_section` is called directly where it ran inside `$( )` (its `exit 1` stopped the harness with the FAIL uncounted, Trap 12), hands its capture back in `SECTION_OUT`, and counts one FAIL in the main shell on a non-zero exit or an empty capture, its caller returning; `run_udm` counts one FAIL on an empty capture where it exited, and its six callers return; the two "exits 0" checks are thereby skipped on a run that printed nothing | 120 on all scenarios (unchanged) | failing: 0 passed, 18 failed; silent: the same | the base commit stopped at the first section run on both stubs (no summary); now both reach it with nothing passed |
| udm-counting | `assert_command` evaluates each command in a subshell (shape 15): the users-in-CSV check's command holds an `exit 1`, which in the harness's own shell ended it silently on a failed run; the two bare `-xu` runs record their exit (`\|\| rc=$?`), and "-xu appends the user" also needs both runs to exit 0 and the run without `-xu` to print, since its absence half held on a failed run | 44 on all scenarios (unchanged) | failing: 0 passed, 44 failed; silent: the same | the base commit stopped on both stubs right after the users-column render check, at the CSV check's `exit 1` (the reading had named the `-xu` runs); now both reach the summary with nothing passed |
| screenshot-capture | `capture_ltl`, the harness's own run of `ltl` on the command the tool traced, records its outcome (`<capture>.rc`) and counts one FAIL on a non-zero exit, an empty capture or a trace without a capture run, where it stopped the harness or returned 1 to a bare call; the nine checks that read a `.ltl` capture (two through the rows `cells.ltl` gives the crop checks) name it (`reads`) and are skipped when it failed; the palette and index-seed runs carry `\|\| true` (the heatmap check reads `heat.ltl` too, and a failed seed leaves no index, which its check fails) | 44 on all scenarios (unchanged) | failing: 29 passed, 10 failed; silent: the same; the 29 are the D1 checks of § Per-harness record, each reading only the tool's output | the base commit stopped on the failing stub and passed 31 on the silent one, two of them over an empty capture ("every full block ... fills its own columns" and "every colour of the panel, faint and full, drawn consistently"); now both stubs pass the 29 D1 checks and nothing else |
| format-registry | `run_format_registry` is called directly at its twelve call sites where it ran inside `$( )` (its `exit 1` stopped the harness with the FAIL uncounted, Trap 12), hands its capture back in `REGISTRY_OUT`, and counts one FAIL (`run_failed`) in the main shell, its caller returning; "unknown -lf exits non-zero" also needs the unknown-format error on stderr; the re-emission and unarmed runs count one FAIL where they exited; the unarmed absence needs the run's format-detection section first | 59 on all scenarios (unchanged) | failing: 0 passed, 14 failed; silent: the same | the base commit stopped at the first run on both stubs; run alone, its invalid-pin scenario passed "unknown -lf exits non-zero (1)" on the failing stub and its unarmed scenario passed the absence on the silent stub; the fixed harness fails both |
| message-mask | none: read again with the widened greps | not run (unchanged, 27 at the baseline) | 0 passed at the baseline on both stubs, summary reached | — |
| message-grouping | none under this issue's condition: read again with the widened greps; the selection defect (`DOWNLOAD_KEYS`, `out_downloads_75`) is in § Observations, fixed under D4 | not run (unchanged, 51 at the baseline) | 0 passed at the baseline on both stubs, summary reached | — |
| notices | `ran <tag>` (exit 0 and output) and `skipped` added; each absence or zero count needs its evidence first and is skipped without it: "buttons only" the record's block, "ASCII only" a non-empty section, "on standard output only" and "nothing on standard error" their run, "no kind outside the inventory" kinds found in the source, "every standard error site" sites found, "the screen is given back" the modal's box drawn, "an answered choice is locked" the answered marker; the `title_row=` lookup carries `\|\| title_row=""` | 188 on all scenarios (unchanged) | failing: 1 passed, 218 failed; silent: 1 passed, 179 failed; the PASS is "reserved in the harness design" (run-free, reads `tests/HARNESS-DESIGN.md`) | the base commit passed eight on each stub (the seven absences and the run-free check) and stopped at the `title_row` lookup; now only the run-free check passes and both reach the summary |

### D4: the selection defects

Each fix was proven by running a scenario other than the last alone, from the
scratchpad worktree at the committed head (a8b7dcfe) and from the main
checkout with the fix; the PASS lines of the same scenario on real `ltl` are
identical on both sides (category-names 17, message-control-characters 5,
summary-contribution-bar 4), and only the summary differs. These proof runs
went through a wrapper script in the scratchpad, against the note that no
wrapper runs a harness; they ran one at a time, each scenario named.

| Harness | Change | Proof |
|---|---|---|
| category-names | the summary and its exit move after the last scenario's block | `--scenario http-status-families` on the failing stub: committed, 1 FAIL, no summary, exit 0; fixed, `PASS: 0 FAIL: 1`, exit 1 |
| message-control-characters | the same | `--scenario control-character-normalisation` on the failing stub: committed, 1 FAIL, no summary, exit 0; fixed, `PASS: 0 FAIL: 1`, exit 1 |
| summary-contribution-bar | the same | `--scenario summary-bar-off`. On the failing stub both sides stop at `capture_render`'s `exit 1` before any summary (its own case, drop 5), so the proof used the noise stub (one unrelated line, exit 0): committed, 4 FAILs, no summary, exit 0; fixed, `PASS: 0 FAIL: 4`, exit 1 |
| message-grouping | `DOWNLOAD_KEYS` and `out_downloads_75` are set after the explicit-final-threshold block and before signed-downloads-75's, where every scenario reaches them; signed-downloads-75-repeat prints a SKIP naming signed-downloads-75, and counts nothing, when there is no capture of it to compare (not named with it, or its run failed), where it printed nothing | on real `ltl`: committed, `--scenario signed-downloads-75` alone and `--scenario signed-downloads-75-repeat` alone each stop on an unbound variable (`DOWNLOAD_KEYS`, `out_downloads_75`), and both named together stop on `DOWNLOAD_KEYS`; fixed, signed-downloads-75 alone 1 passed, the repeat alone 0 passed with its SKIP, both together 2 passed, exit 0 each. On the failing and silent stubs with both named: 0 passed, 1 failed, the repeat's SKIP, exit 1 |

### Drop 5

Confirmations as in drop 3. The committed side of each proof is the
baseline's stub run, the six harnesses being unchanged from the base commit to
a8b7dcfe, or a run of the committed harness from the scratchpad worktree.
Five harnesses changed; message-expose, read again, has no case: every run is
checked where it is made (exit, MESSAGES and STATS CSVs) and every scenario
returns before reading a failed one. The five, run from the scratchpad
worktree with `LTL` unset and with each stub, report the same summary, exit
and passed count as from the main checkout, 15 runs.

| Harness | Change | Real | Failing / silent stub | Proof (AC6) |
|---|---|---|---|---|
| summary-contribution-bar | `capture_render` counts one FAIL (with the three fields) and returns 1 where it was `exit 1`; each scenario's checks run inside `if capture_render ...; then`, a scenario of several captures chaining them with `&&`, the form drop 2 gave category-names | 39 on all ten scenarios (unchanged) | failing: 0 passed, 11 failed; silent: the same (ten captures and the source-read colour check) | the committed harness stops at the first capture on both stubs with no summary (baseline); now both reach it |
| section-layout | the two plain renders of hide-each-column record whether they ran; a column's checks that read its log's plain render (the heading present there, or the render differing from it) are skipped when that run failed, which `run_ltl` counted | 186 on all scenarios (unchanged) | failing: 0 passed, 73 failed; silent: the same | an `ltl` that fails only the plain numeric render: the committed harness passes "-hi values changes the render" and "-hi rate changes the render" (and fails the seven heading checks on it); the fixed one counts the run's FAIL once and skips the nine |
| timestamp-precision | `labels` never fails (`{ grep ... \|\| true; }`), and the ten-buckets filter inside its pipeline the same, so the seven assignments that read it assert on what they got; the two STATS CSV lookups carry `\|\| var=""`; "no four-digit fraction" is skipped when its run failed (counted by `run_in`) and fails when the heading, the export or the index holds no timestamp to read; "no bucket-key site reads -s or -ms" needs `read_and_process_logs()` in the source first | 94 on all scenarios (unchanged) | failing: 0 passed, 178 failed, the four-digit absence skipped; silent: 0 passed, 94 failed | the committed harness passes the four-digit absence on both stubs and stops (baseline: at the STATS CSV lookup); run alone, keyscale/microsecond stops at the `labels` lookup, and keyscale/structure passes on the failing stub with exit 0; the fixed one reaches the summary and fails both |
| log-level-vocabulary | the nine `exit 1` (a non-zero exit, or an empty render, of seven runs) become one counted FAIL each (`run_failed`, the form drop 2 gave message-control-characters), and the checks that read that run's capture are skipped (`skip_checks`); the checks that make runs of their own (the error rate, the failure count, the non-failure arm, the 1,800-line report) stay outside the guard and fail on their own anchors | 58 on all seven scenarios (unchanged) | failing: 0 passed, 11 failed; silent: 0 passed, 43 failed | the committed harness stops at its first scenario on both stubs, no summary (baseline); now both reach it |
| runtime-config | `assert_exit` takes `evidence <pattern> in <file>`, required, and passes only on the exit code and a line the run writes: each refusal's message, which the scenario also asserts, and for each acceptance a line every run of its shape prints (the runtime-config or format-detection section, `LINES READ`, `Version:`, `USAGE`, the `sz` panel); `assert_no_line` takes a required `evidence` (and `in`) and fails when it is absent; the two pushback "says nothing on stderr" checks need the run's runtime-config section; "-V keeps no path test" needs `adapt_to_command_line_options()` in the source | 119 on all scenarios (unchanged) | failing: 0 passed, 119 failed; silent: the same | the committed harness passes 17 on the failing stub (eight refusals by exit code, five "says nothing", the source absence, three absences) and 19 on the silent one (ten acceptances by exit code, five, one, three) (baseline); now none |

What drop 5 adds to the method: nothing new in the table. Grep 10 listed the
two STATS CSV lookups (`v=$(ls <glob> 2>/dev/null \| head -1)`), and reading
passed over them as harmless; the failing-stub run stopped there. A scenario
list taken from `--list` reads the names after its `Scenarios:` line only:
runtime-config prints a banner line (`  ltl: <path>`) above it, which a
pattern over every indented line takes for a scenario name, and the harness
then refuses the selection having run nothing.

### Drop 6

Confirmations as in drop 3. The committed side of each proof is the
baseline's stub run (the four harnesses are unchanged from the base commit to
9ebc1bf1) or a run of the committed harness from the scratchpad worktree.
Three harnesses changed; message-discard, read again, has no case: every run
is checked where it is made (exit, MESSAGES and STATS CSVs), every scenario
returns before reading a failed one, and each absence follows a checked run.
The three, run from the scratchpad worktree with `LTL` unset and with each
stub, report the same summary, exit and passed count as from the main
checkout, 9 runs.

| Harness | Change | Real | Failing / silent stub | Proof (AC6) |
|---|---|---|---|---|
| help-content | the selector is parsed first, so `--list` and an unknown name run nothing; the three setup steps (the `$version_number` literal and the GetOptions entries read from the source, the `--help` capture) each count one FAIL where they exited, and the scenarios that need what a step failed to obtain are skipped whole (`needs`: A and C the options and the help text, B the options, D and E the version); `assert_equal` fails on an empty actual, so two lookups that found nothing no longer agree; "the four messages print one time-unit list" needs the `-du` list first; "no -uuid row" and "no long byte word" read their help capture through `help_count`, which names a capture whose run failed or printed nothing instead of counting 0 in it; "no placeholder tokens" needs `print_help()` in the source, "no branch per topic" `dispatch_informational_options()` | 114 on all thirteen scenarios (unchanged) | failing: 32 passed, 70 failed; silent: the same; the 32 are the docs/usage.md checks of G, H, I, K, L and M (run-free) | the committed harness stops at setup on both stubs, `--list` included (baseline); against a copy of the tool whose source reads as the real one but whose every run except the setup's `--help` exits 1 printing nothing, it passes "no -uuid row", "the four messages print one time-unit list", the three name-list equalities and "no long byte word"; the fixed one fails all six |
| histogram-bin-counters | `assert_no_line` fails when the capture holds no `-V histogram-bin-counters` section; "heatmap_cells_highlighted carries neither percentile field" needs that consumer's block first; `assert_command` evaluates its command in a subshell | 148 on all scenarios (unchanged) | failing: 0 passed, 148 failed; silent: the same | the committed harness passes the four absences and the empty-block check on both stubs (baseline, five each); now none |
| udm-specs | `run_collision` records its exit status beside the capture (`<capture>.rc`), since its callers run it inside `$( )`, and the division-by-zero check reads it with the section's end marker; `assert_absent` fails when the run's capture holds no `-V udm-specs` section or its notices file holds MISSING-SECTION; the five CSV lookups carry `\|\| var=""` (the MESSAGES one inside its helper, `{ ls ... \|\| true; }`); the two STATS CSV header checks need the CSV, and the shorthand comparison a name on the shorthand side; the twenty-runs check needs every line to carry its unit, value and column; the nine "prints no notice or warning" checks need the run's `read_as` line; the milliseconds and columnar exits need the section's end marker and the messages table; `assert_command` evaluates in a subshell | 250 on all scenarios (unchanged) | failing: 0 passed, 250 failed; silent: the same | the committed harness stops on both stubs (baseline); run on the scenarios before its stops, on the silent stub it passes 14 (the two milliseconds exits, three absences, the division-by-zero exit, the shorthand comparison, the columnar exit and six stderr absences), and on the failing stub "the run exits 0 where it previously died" passes on a run that exited 1; the fixed one passes none |

What drop 6 adds to the method: shape 1 now covers a status a helper records
for its caller, an exit code in a global, inside `$( )`: the caller reads the
global's earlier value, often its initial 0, and a grep for the globals a
helper sets (`^\s+[A-Z_]+=`) lists the candidates. help-content ran its setup,
three runs of the tool, before the selector, so a stub run of `--list`
stopped; the selector is parsed first now, as drop 3 did for
classification-percentages.

### Drop 7

The six harnesses changed under #726, read whole after the greps. Confirmations
as in drop 3. The committed side of each proof is the baseline's stub run (the
six harnesses are unchanged from the base commit to ffd7a142) or a run of the
committed harness from the scratchpad worktree. Five harnesses changed;
duration-display has no case: `capture_render` checks the exit code and a
non-empty render before any check reads it, the resolved-unit probe checks its
exit and fails an empty lookup, and the cell checker exits 1 on a render with
no duration cell. The five, run from the scratchpad worktree with `LTL` unset
and with each stub, report the same summary, exit and passed count as from the
main checkout, 15 runs.

| Harness | Change | Real | Failing / silent stub | Proof (AC6) |
|---|---|---|---|---|
| statistics-demand | "neither messages-table header is rendered" needs the timeline's column header row first, and "no MESSAGES CSV file is created" the STATS CSV; `assert_command` evaluates in a subshell | 167 on all eighteen scenarios (unchanged) | failing: 1 passed, 188 failed; silent: 1 passed, 94 failed; the 1 is scenario 13's fixture line count (run-free) | the committed harness passes both absences on both stubs (baseline, 3 each with the fixture check); now neither |
| filter-summary | `run_sections` counts one FAIL (with the three fields) and returns 1 where it exited on a non-zero exit or a missing section, names the scenario among the failed runs, and every check that reads the capture is skipped (`run_ok`); summary-table-unchanged does the same, its checks needing the summary table's `LINES READ` row; each bad-bound refusal checks its message first, and its exit code and two absences only when the message is there | 146 on all fourteen scenarios (unchanged) | failing: 0 passed, 21 failed; silent: the same | the committed harness stops at its first run on both stubs (baseline); against a tool that runs the real one for the section runs and exits 1 printing nothing for the four bound refusals, it passes 12 checks over refusals that did not happen (four exit codes, eight absences), 33 passed against the fixed one's 21; on the silent stub, summary-table-unchanged passes its absence alone |
| format-detection | the run helpers record their outcome beside the capture (`<capture>.rc`: the exit code, `empty` or `no-section`) rather than exiting inside `$( )`; `check_run`, called in the main shell after every run, counts a failed run once and otherwise checks its standard error for runtime warnings; `assert_line` and `assert_absent` skip a capture, or its notices file, whose run failed, and `assert_command` names the captures it reads (`reads`); the four bare runs (the three summary-row renders, the mixed-legend render) record their exit the same way; the consolidation reconciliation is skipped when either of its runs failed; `assert_command` evaluates in a subshell | 472 on all 74 scenarios (unchanged) | failing: 3 passed, 135 failed; silent: 3 passed, 178 failed; the 3 are the CRLF and padded-level fixture checks (run-free) | the committed harness stops at its first run on both stubs (baseline); against a tool that runs the real one for every run carrying `-V` and exits 1 printing nothing for a render, it stops at the first bare render while the fixed one reaches its summary; on the silent stub, classification-summary-rows passes both summary-row absences, the fixed one neither |
| index-read-back | `run_ltl` records its outcome beside the capture (`<capture>.rc`: the exit code, `empty`, or `no-section` for a run asked for the section); `check_run` counts a failed run once; `assert_line` and `assert_no_line` skip a failed run's capture, and every `assert_command` that reads a run's capture or the index it wrote names that run (`reads`); the index and CSV lookups carry `\|\| var=""`, and after a run that writes the index the edits and reads that follow are skipped when it failed; the three comparisons of two lookups need a non-empty side; "no stray string comparison" needs `read_index_file()` and `detect_index_drift()` in the source; `assert_command` evaluates in a subshell | 107 on all 29 scenarios (unchanged) | failing: 6 passed, 56 failed; silent: the same; the 6 are the helper self-tests (run-free) | the committed harness stops on both stubs (baseline: at stale-size's edit of an index its run never wrote); run on the eight scenarios whose checks pass on an empty run, on the silent stub it passes 9 besides the helpers (six absences, two comparisons, the source scan), the fixed one none; index-bytes-counted alone stops at its index lookup, and the fixed one reaches its summary |
| explain | `assert_exit` takes `evidence <pattern> in <file>`, required, and passes only on the exit code and the line the run writes on that outcome: a topic's See also, the registry's and the statistics index's `STATISTICS` heading, `USAGE`, the reflowed topic's heading, and each refusal's own message | 728 on all 29 scenarios (unchanged) | failing: 61 passed, 606 failed; silent: the same; the 61 are the mirror, wiki, user-guide and source checks (run-free) | the committed harness passes 65 on the failing stub (the 61, and four refusals by exit code) and 107 on the silent one (the 61, and 46 successes by exit code) (baseline); now 61 on each |

What drop 7 adds to the method: an exit-code check of a refusal counts a pass
of its own even when the next check reads the message (explain, the
filter-summary bad bounds), so shape 6 now asks for both in one check, the
message as the exit check's evidence. A check whose first argument is its
capture can skip that capture by the `.rc` its run recorded, so a harness of
several hundred checks per run needs no per-check field; and the steps that
edit what a run wrote besides its capture (index-read-back's index) are
skipped with its checks. Both are in the fix forms of `tests/HARNESS-DESIGN.md`.

### Drop 8

D3, built to the shape recorded with it. Its conditions are written in
`tests/HARNESS-DESIGN.md` § The failed-run checker as what is expected and
what fails; the rule that a harness change passes the checker is a bullet of
`.claude/rules/harnesses.md` and part of the CLAUDE.md checkpoint "Any harness
change".

- **`tests/validate-harness-failed-run.sh`**, one harness in the suite, with a
  scenario per harness that runs `ltl` (52; scenario-selector names no `LTL`
  and is not checked). Each scenario makes eleven checks: the three source
  rules, then a run of every scenario the harness registers against each stub,
  failing on a summary not reached, an exit of 0, PASS lines that differ from
  the passed count, or a PASS line not marked run-free. Its whole run is the
  sweep of every harness against the stubs the gate calls for (AC1 to AC3).
- **`process/check-harness-source.pl`**, the source rules: a counting helper
  run inside `$( )`, `<( )` or backticks (counted-in-subshell), a summary
  inside any block but a top-level `if` that does not test the scenario
  selection (summary-in-scenario), and a `grep` or `ls` lookup assigned with
  no `||` (lookup-no-fallback). It reads the harness through bash's own parser
  (the harness wrapped in a function and printed back by `declare -f`), so
  nesting is bash's, and continued lines, comments and here-document bodies
  do not mislead it.
- **`process/check-harness-capture.pl`** counts the PASS lines not marked
  run-free, a seventh column of `--brief`.
- **The run-free mark**, `[run-free: <what it read>]` at the end of a PASS
  line, given through the assertion helper (a `run_free` field, or a seventh
  argument to `check`). It goes on a check whose input does not depend on
  `$LTL`: docs, a fixture, what the harness writes, the checkout's source read
  through `REPO_DIR`, or the screenshot tool's output, the tool running the
  repository's `ltl` (D1). Source read through `$LTL` fails under a stub and
  carries none. 136 PASS lines in ten harnesses carry it: explain 61,
  help-content 32, screenshot-capture 29, index-read-back 6, format-detection
  3, and one each in statistics-demand, classification-states, memory-usage,
  notices and read-path, the run-free checks § Per-harness record names.
- **Eleven lookups given a fallback.** Over the 52 harnesses the source rules
  found no counting helper inside `$( )` and no summary inside a scenario's
  block, the drops having fixed both, and eleven `grep` or `ls` lookups with
  no `||`: aggregate-export, byte-units (two), duration-display, explain,
  format-detection, format-registry (three), runtime-config and section-layout.
  Each was read in its drop as unable to stop the harness where it stands (a
  helper called where `set -e` does not apply, or a value that is always
  there); each now carries `|| var=""`, and the value is asserted on as
  before, so the rule holds without an exception.

Proof (AC6): in the scratchpad worktree at drop 7, with the checker and its
two tools copied in, the checker fails each condition on a harness that
breaks it. The summary inside a scenario's block fails category-names as it
was before D4 (a8b7dcfe). A counting helper inside `$( )` fails
statistics-demand as it was at 422f2d4e, whose `extract_section` counted
inside `body=$( )`. Lookups with no fallback fail explain and runtime-config
at drop 7, and read-path at the base commit. A summary not reached fails
filter-summary at drop 6. An exit of 0 fails read-path at the base commit,
which ran its own `ltl` whatever `LTL` named. A PASS count off the passed
count fails classification-states doctored to count two per pass. Unmarked
passes fail explain and statistics-demand at drop 7, read-path at the base
commit and the doctored classification-states.

The checker's run over all 52 harnesses, from the scratchpad worktree at the
drop's commit: 572 passed, 0 failed (eleven checks for each), in 461 s. The
sixteen harnesses drop 8 changed keep their passed
counts on the real `ltl` and exit 0 (aggregate-export 163, byte-units 48,
duration-display 41, explain 728, format-detection 472, format-registry 59,
runtime-config 119, section-layout 186, classification-states 56, memory-usage
23, notices 188, read-path 28, help-content 114, statistics-demand 167,
index-read-back 107, screenshot-capture 44), 136 of their PASS lines marked;
run from the scratchpad worktree they report the same summary, exit, passed
count and marked lines, 16 runs.
A stub run of
csv-output or statistics captures the shared CSV cache again, its signature
being a digest of the file `LTL` names (§ What is in place), so the next real
run of either captures again.

The checker's first run over all 52 failed regression on both stubs, by its
own reading of `--list`: regression prints a note under its scenario names
("A positional argument names an alternative reference directory."), and the
reading took its first word for a name, which regression refused. The names
are now the one-word lines directly after `Scenarios:`; read that way, only
regression's list changes, and its scenario passes all eleven checks.

What drop 8 adds to the method: the review-gate greps stay the reader's
candidate list, and the checker is the subset certain without reading, run
on every change. "Confirming a fix" in the method now names the checker's
scenario.

### Completion gate

Run 2026-10-24 on e3bfbccc, `$version_number` restored to `0.20.0`; `ltl` is
byte-identical to the base commit (c0fa5283).

- **Benchmark** (`single-day-access-log-standard`, both sides from the main
  checkout): `747-before` against `747-after`, total 5.0 s against 5.0 s
  (+0.6%), rss_peak +0.8%. With the code identical the difference is the
  machine's, and two more `after` runs measured it: total +4.0% and +2.3%,
  rss_peak −0.1% and +1.7%, unattributed memory −0.2% and +3.4%, each run as
  far from the next as from `before`.
- **The full suite**, csv-output and statistics first under `CI=1`, the
  checker last: every one of the 54 harnesses exits 0, in 28 minutes
  (1,686 s). Each harness of drop 1's baseline reports the passed count it
  reported there (AC4), 5,246 passed in all with the checker's 572.
  csv-output's 112 PASS lines against its 44 passed are as drop 1 recorded
  them (a PASS line per CSV file, the summary counting scenarios).
- **AC1 to AC3, and AC5**: the checker's run, 572 passed and 0 failed. Each of
  the 52 harnesses that run `ltl` reaches its summary against both stubs,
  exits non-zero, prints as many PASS lines as it counts, and passes only
  checks marked run-free; a harness that ignored `LTL` would pass unmarked
  checks there, as read-path at the base commit did.
- **AC7**: the greps of `tests/HARNESS-DESIGN.md` run over every harness list
  3,263 lines. Each harness was read whole with them in its drop, and its row
  above records the cases fixed, or none. The lines of greps added after a
  harness's drop: grep 10 as widened by drop 3 lists no further stop in drop
  2's harnesses (§ Drop 3); grep 15 lists one line, summary-contribution-bar's
  Perl `eval` of the colour tables inside a `perl` program, not a shell
  `eval`, so not a case; grep 1b lists 85, and a scan of every harness for a
  helper that sets a variable it does not declare local and runs inside
  `$( )` finds none whose variable a caller reads, the same scan finding
  `run_collision` in udm-specs as it was before drop 6.
- **AC8**, read: `docs/process/workflow.md` § 5 step 4 leaves
  `validate-read-path.sh` out of the second pass and says why, and
  `process/capture-screenshots.pl` carries the D1 comment beside `my $ltl`.
  The same pass now also leaves out `validate-harness-failed-run.sh`, which
  runs every harness against stubs of its own whatever `LTL` names.
- `./tests/cleanup-test-artifacts.sh` ran after the suite.

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

- **A selection that leaves a scenario out** (fixed under D4, § D4: the selection defects).
  `validate-category-names.sh`,
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
- **Absences that hold when the section they read is missing** (found in
  drop 7). `notice_lines` writes `MISSING-SECTION` for a capture with no
  notices section, and no forbidden pattern matches it, so seven notice
  absences pass on a run that prints the section asked for but no notices
  section: filter-summary's impossible-date "no note per line or per file",
  and format-detection's variant-ambiguity-note (three: with `-lf`, on a
  format outside any group, under the producer-true name),
  variant-integration-runtime-named, unit-tomcat-named and unit-httpd-named.
  drop 6 gave udm-specs' `assert_absent` the guard these lack. In
  duration-display's no-duration scenario, "no timeline latency column"
  counts a pass when the anchor check before it (the occurrences and
  messages tables present) fails. Each needs a run that exits 0 and prints
  part of what it was asked for, outside this issue's condition; with a run
  that prints nothing all of them are skipped or fail.
- **Captures left behind, beyond S5's two** (found in drop S2-1). Four more
  harnesses write captures with a bare `mktemp`, outside their own directory,
  and never remove them: index-read-back's `run_ltl` (each capture with its
  `.rc` and `.stderr`), statistics-demand's two capture helpers and its
  `rep_out`, `num_out` and `spell_out`, and csv-output's `cache_refresh_err`.
  Three remove theirs on a normal exit only, none through an `EXIT` trap:
  histogram-ticks' two run captures, help-layout's `HELP_OUT` and `STRIPPED`,
  statistics' `tmp` (Trap 10). On 2026-10-24 `$TMPDIR` held 10,927 `tmp.*`
  entries, all written that day. Fixed under D6, each in its harness's drop.
- **Two comments that cite a record no longer kept** (found in drop S2-1).
  `validate-doc-examples.sh` (the fixture table) and
  `validate-help-content.sh` (its `TEST_LOG`) give "repo memory
  (feedback_test_logs.md)" as the reason the corrupt 2025-03-21 access log
  is avoided. The file was removed; `docs/test-logs.md` carries the reason
  (its AccessLogs table marks the file "CORRUPT — do not use for
  clean-output testing"). S3 covers only help-layout's contract. Fixed
  under D6, each in its harness's drop.

## Stage 2: the observations

Asked by the architect on 2026-10-24, after the close-out: "fix the issues
under this issue", planned here as a next stage because the context window is
cleared first. Its scope is § Observations as it stands, the selection
defects there being fixed already under D4, and the dead source read of
§ What is in place (`validate-explain.sh` reading `"$LTL/../ltl"`). By D5
(the architect's choice once the plan was shown) it also reads every harness
again for the condition two of those observations point at: a run that exits
0 having printed one line unrelated to what it was asked for. It starts on
the architect's word.

### Scope

| # | What | Where | Fix | Proof (as AC6) |
|---|---|---|---|---|
| S1 | `ltl`'s standard error discarded, so no runtime-warning check reads it | log-level-vocabulary `check_failure_count_rises_with_added_severities` (two runs, `2>/dev/null`) and `check_error_rate_counts_fatal` (two runs, `>/dev/null 2>&1`); udm-specs collision-operands' control run (`2>/dev/null`) | each run's standard error to a file beside its capture, read by the runtime-warning check in the harness's own shell after the check: the two log-level-vocabulary functions run inside `assert_command`'s eval, a subshell, where a count would be lost (Trap 12) | a copy of `ltl` that prints ` at ltl line 1.` on standard error for those runs and is the real tool otherwise: the committed harness passes them, the fixed one fails |
| S2 | A stale known failure | `tests/rendered-output/soft-wrap-known-failures.tsv`, the line for `classification-percentages-w120-access-120` (#497, open) | confirm the XPASS on the release branch; find the change that made the capture fit (the line's reason is the run options echo); remove the line; say on #497 which capture no longer wraps, and why | the scenario's soft-wrap check reports a plain PASS, no XPASS |
| S3 | A contract naming a removed record | help-layout `assert_pair`'s contract, "MEMORY.md feedback_short_forms_required" | the rule where it lives: CLAUDE.md § Before writing or changing code, a new option has a short form, a long form, a `print_help()` row and a `docs/usage.md` row | read |
| S4 | doc-examples passes on any output | its pass condition, exit 0 and a non-empty standard output | each example also needs a line every run of its shape prints, chosen per shape when the extracted examples are read (the run summary's `LINES READ` row, `--help`'s `USAGE`, a section header), and named in the check | against a stub that exits 0 printing one unrelated line, the committed harness passes 51, the fixed one none; on the real `ltl` 51 still |
| S5 | Captures left behind | heatmap-palette `run_section` (`mktemp`, never removed); histogram-bin-counters `run_section` (removed per scenario, not on an interrupted run) | captures under the harness's own `TMP_DIR`, removed by its `EXIT` trap (Trap 9, Trap 10) | the files under `$TMPDIR` before and after a run: none added |
| S6 | A source read that never resolves | explain's pager default read from `"$LTL/../ltl"` (a file followed by `/..`), so its fallback, the checkout's `ltl`, is always read; `strip_ansi`'s presence read from the checkout's `ltl` | both read `"$LTL"`, as 621 D3 has every source check do; they then fail under a stub like any source check, and lose their run-free marks | the checker's explain scenario passes with 59 marked passes on each stub, not 61; the real `ltl` keeps 728 |
| S7 | Absences that hold when the section they read is missing | filter-summary (one notice absence), format-detection (six), duration-display (the no-duration latency absence) | `assert_absent` fails on a notices file holding `MISSING-SECTION`, the form drop 6 gave udm-specs; duration-display's absence carries its anchor in the same check | a copy of `ltl` that is the real tool with its notices section removed from standard output: the committed harnesses pass the seven, the fixed ones fail them; for duration-display, one whose no-duration render lacks the two tables |
| S8 | Every check that holds on a run that exits 0 having printed something other than what it reads (D5) | all 52 harnesses that run `ltl`, read again whole in stage 1's drop groups | the check needs the section, table, row or file it reads, present, before it is made; a capture helper records a run that printed none of what was asked as failed, as `no-section` does in format-detection | each harness against the noise stub: the base commit's passes are listed per harness in drop S2-1, the fixed harness passes only checks marked run-free |

### Delivery

Eight drops, then the completion gate, as stage 1 ran. A drop is the reading,
the fixes, each shown failing before it is trusted, the runs, the record, a
commit and a push on the branch, and a comment pointing here.

1. **Start.** #747 reopened (`gh issue reopen 747`), `./process/issue-status.sh
   set 747 "in progress"`, a comment pointing here. Branch
   `747-harness-checks-on-a-failed-run-2` off `release/0.20.0`, synced (a
   second branch for an issue takes a numeric suffix,
   `docs/process/workflow.md` § 1); `$version_number`
   stamped `0.20.0-747`; the `747-before` benchmark
   (`single-day-access-log-standard`) on the base commit from the main
   checkout, the diff touching harnesses (`docs/process/workflow.md` § 3).
2. **Drop S2-1, the method and the recorded observations.** The noise stub is
   a two-line Perl script, `print "an unrelated line\n";`, exiting 0. Every
   harness that runs `ltl` is run against it on the base commit, every
   scenario named. That run is the candidate list, as drop 1's baseline was.
   Its passed count and whether its summary was reached go into a new
   noise-stub column of § Per-harness record. `tests/HARNESS-DESIGN.md`
   § Reading a harness for a run that did not happen gains the third
   question: had the run exited 0 having printed one line unrelated to what
   it was asked for, would the check pass? Shapes 2, 3 and 4 then ask for the
   section or row the check reads, not a non-empty capture. S1 to S7 are
   fixed.
3. **Drops S2-2 to S2-7, the noise reading.** Each takes the harnesses of
   stage 1's drop of the same number (§ Delivery plan): S2-2 drop 2's
   seventeen, S2-3 drop 3's eleven, S2-4 drop 4's eight, S2-5 drop 5's six,
   S2-6 drop 6's four, S2-7 drop 7's six. Each harness is read whole for the
   third question, with the review-gate greps of shapes 2, 3, 4 and 14 as
   its candidate list beside the noise-stub baseline. Each case is fixed to
   the section or row it reads. By D6 the drop also fixes, in its own
   harnesses, the captures left in `$TMPDIR` (under the harness's `TMP_DIR`,
   removed by its `EXIT` trap, as S5) and the comments citing a removed
   record (`docs/test-logs.md` named instead, as S3).
   - **Proof:** each fix is shown on the noise stub, the committed harness
     beside the fixed one.
   - **Runs:** each changed harness runs on the real `ltl` and against the
     failing, silent and noise stubs, every scenario named. Its passed count
     on the real `ltl` is unchanged.
   - **Checker:** it passes its scenario of
     `tests/validate-harness-failed-run.sh`.
   - **Worktree:** the same runs once from a scratchpad worktree with the
     `logs` symlink.
4. **Drop S2-8, the checker.** `tests/validate-harness-failed-run.sh` runs
   each harness against the noise stub as it does the other two, with the
   same four conditions: fifteen checks per harness. § The failed-run
   checker of `tests/HARNESS-DESIGN.md`, `.claude/rules/harnesses.md` and the
   CLAUDE.md checkpoint name the third stub. The checker's whole run passes
   from the worktree.
5. **The gate** (`docs/process/workflow.md` § 3), as at stage 1:
   - `$version_number` restored, then the `after` benchmark;
   - the full suite: csv-output and statistics first under `CI=1`, then the
     rest, the checker last;
   - `./tests/cleanup-test-artifacts.sh`.

   Then the PR into `release/0.20.0`, the merge, and the close-out: #747
   closed again with its completion comment; the branch, the TSVs and the
   worktree deleted.

Size: the 52 harnesses read again, about 39.6k lines, stage 1's drops 2 to 7.
Each is read for one question rather than fifteen shapes, each having been
read once already.

Scenario names for a run are the one-word lines after `Scenarios:` in a
harness's `--list` (§ Drop 8); the checker makes its own stubs.

### Acceptance criteria (stage 2)

- [x] **S2-AC1.** No `ltl` run in log-level-vocabulary or udm-specs discards
      its standard error; a runtime warning on any of the five runs is a
      counted failure. *Assertable*: S1's proof.
- [x] **S2-AC2.** The soft-wrap known failures carry no entry their check
      passes; #497 says which capture stopped wrapping and why.
      *Assertable*: S2's proof and the comment.
- [ ] **S2-AC3.** No contract or comment in a harness names a record that is
      not kept in the repository (D6 widened it from contracts).
      *Assertable*: a grep for `MEMORY.md`, `repo memory` and `feedback_`
      over `tests/` finds nothing (the contract fixed in drop S2-1, the two
      comments in drops S2-2 and S2-6).
- [x] **S2-AC4.** doc-examples passes no example on a run whose output is
      not `ltl`'s. *Assertable*: S4's proof.
- [ ] **S2-AC5.** No harness run leaves a file outside its own directory
      (D6 widened it from heatmap-palette and histogram-bin-counters).
      *Assertable*: S5's proof; for the seven harnesses of D6, the entries a
      real run adds to `$TMPDIR`, counted in each one's drop: none; for the
      rest, `$TMPDIR` listed before and after the gate's full suite: no entry
      added by a harness.
- [x] **S2-AC6.** explain reads `ltl`'s source through `$LTL` only.
      *Assertable*: S6's proof, and no `"$LTL/../` in `tests/`.
- [x] **S2-AC7.** The seven notice absences and duration-display's latency
      absence fail on a run that lacks what they read. *Assertable*: S7's
      proof.
- [ ] **S2-AC8.** Against the noise stub every harness that runs `ltl`
      reaches its summary, exits non-zero, prints as many PASS lines as it
      counts, and passes only checks marked run-free (D5). *Assertable*: the
      checker's run, its noise-stub checks.
- [ ] **S2-AC9.** The method asks the third question, and the checker runs
      the noise stub on every harness. *Assertable*: `tests/HARNESS-DESIGN.md`
      read, and the checker's fifteen checks per harness.
- [ ] **S2-AC10.** The gate: every harness exits 0 at its passed count, and
      the checker passes every scenario. *Assertable*: the gate's run.

### Drop S2-1

The stubs are in the session scratchpad (`stubs/{failing,silent,noise}/ltl`;
noise prints `an unrelated line` and exits 0), and two doctored copies of the
real tool beside them: `doctored/warn/ltl` prints `Use of uninitialized value
in a doctored copy at ltl line 1.` on standard error from a `BEGIN` block, and
`doctored/nonotices/ltl` has `emit_notices_verbose()` return at once, so its
standard output carries no `-V notices` section. The committed harness of
each proof is run from the scratchpad worktree at the base commit, the fixed
one from the main checkout, on the same `ltl`.

- **The baseline**: every harness that runs `ltl` against the noise stub on
  the base commit, every scenario named, in § Per-harness record.
- **The method** (`tests/HARNESS-DESIGN.md`): § Reading a harness for a run
  that did not happen asks the third question; shapes 2, 3 and 4 ask for the
  section, table or row the check reads, and say a non-empty capture is not
  that evidence; Trap 13's sentence on what precedes a comparison or an
  absence says the same; the capture-helper fix form names a `no-section`
  outcome beside a non-zero exit and an empty capture.

| # | Harness | Change | Proof (as AC6) |
|---|---|---|---|
| S1 | log-level-vocabulary, udm-specs | the four runs of `check_failure_count_rises_with_added_severities` and `check_error_rate_counts_fatal` write their standard error to files beside their captures, read after each check by `check_run_warnings` in the harness's own shell (the functions run inside `assert_command`'s eval, a subshell); collision-operands' control run writes `<capture>.stderr`, checked at once | on the warning copy, method-server-levels and extended-severity-vocabulary: the committed harness counts 3 warning failures, the fixed one 7, the four runs that discarded theirs; collision-operands: 1, then 2 (the control run) |
| S2 | the soft-wrap known failures | the line for `classification-percentages-w120-access-120` removed | on the base commit the soft-wrap scenario reports it XPASS; now its three checks pass and no XPASS prints; regression's `errrate-diagnostics-highlighted-failure-w160` stays XFAIL on the entry that remains. Why the capture fits: run with its harness's invocation (`--terminal-width 120 -ni -bs 60 -n 1 --debug-layout -V notices -lf access_common_duration` over the access classification fixture), `ltl` before 59d469a8 prints one line over 120 columns, the options row at 131, echoing `--disable-progress --terminal-width 120` and `-V notices`; from 59d469a8 (the row leaves out the options that stand in for the terminal, 598 D17) it reads `command-line options: -ni -bs 60 -n 1 --debug-layout -lf access_common_duration`, and no line exceeds 120. The row is still printed unfitted, so a longer command line still wraps |
| S3 | help-layout | `assert_pair`'s contract names the rule where it lives, CLAUDE.md § Before writing or changing code; its asserts text drops the pointer to the same removed note | read; `grep -r MEMORY.md tests/` finds nothing |
| S4 | doc-examples | each example also needs the options row led by the options the harness injects (`EXAMPLE_EVIDENCE`, `command-line options: -ni -bs 1440 -oe`), which `print_run_options()` prints for every runnable example; the row is matched over the whole stream, so the pipe cannot fail on SIGPIPE | on the noise stub the committed harness passes 51, the fixed one none (51 "doc example printed no options row"); on the real `ltl` 51 |
| S5 | heatmap-palette, histogram-bin-counters | every capture under the harness's own `TMP_DIR`, removed by its `EXIT` trap; heatmap-palette's `UDM_TMP` is inside it, since a second `EXIT` trap would have replaced the first; histogram-bin-counters' two `-o` scenarios keep their run directory where `mktemp -d` makes it, removed by the scenario and left only when the ownership guard names a file the scenario did not write | entries added to `$TMPDIR` by a real run, every scenario named: committed heatmap-palette 28, histogram-bin-counters 1 (a `.notices` file its per-scenario cleanup missed); fixed 0 and 0 |
| S6 | explain | the pager default (its read and its fallback) and `strip_ansi`'s presence read `"$LTL"`, and lose their run-free marks | the checker's explain scenario: 59 marked passes on each stub, where there were 61; the real `ltl` 728 |
| S7 | filter-summary, format-detection, duration-display | `assert_absent` fails on a notices file holding `MISSING-SECTION`; duration-display's latency absence carries the occurrences-and-messages anchor in its own command | on the no-notices copy, filter-summary's impossible-date absence and format-detection's six (variant-ambiguity-note's three, variant-integration-runtime-named, unit-tomcat-named, unit-httpd-named) pass on the committed harnesses and fail on the fixed ones, each naming the missing section; duration-display on the noise stub: the committed harness passes the latency absence, the fixed one fails it |

Runs, every scenario named, from the main checkout: the ten changed
harnesses keep their passed counts on the real `ltl` (doc-examples 51,
duration-display 41, explain 728, filter-summary 146, format-detection 472,
heatmap-palette 120, help-layout 6, histogram-bin-counters 148,
log-level-vocabulary 58, udm-specs 250), and every run against the failing,
silent and noise stubs reaches its summary and exits 1. On the failing and
silent stubs they pass only run-free checks (explain 59, format-detection 3).
On the noise stub, explain still passes 200 unmarked checks, format-detection
2 and heatmap-palette 2, each left to its harness's drop. The checker passes
the ten harnesses' scenarios, 110 checks. classification-percentages' soft-wrap
and regression's `errrate-diagnostics-highlighted-failure-w160` read the
known failures as above. The same 42 runs from the scratchpad worktree at
67a60617 (its `logs` a symlink to the main checkout's corpus) report the same
summary, exit status, passed and failed counts as the main checkout. #497 is
told which capture stopped wrapping and why.
