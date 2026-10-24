# 747: no harness check passes on a run that failed, and no harness stops before its summary

Issue: #747 (a harness check passes, or the harness stops early, when the
`ltl` run it reads failed). Parent: #729 (process, tests and build).

Status: specification drafted 2026-10-24 for the architect's review. No
harness has been read under this issue yet; the issue is in the backlog.

## Resuming

The requirements, the acceptance criteria and the delivery plan below are a
draft for review. Once they are agreed, work starts on an issue branch off
`release/0.20.0` with drop 1 (§ Delivery plan). This document stays on the
release branch; each drop records what it found per harness in § Per-harness
record.

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
- 51 harnesses take `LTL` from the environment. `validate-read-path.sh` sets
  `LTL="$REPO_DIR/ltl"` unconditionally, so it cannot be pointed at a stub
  without a change. One harness (`validate-notices.sh`) runs `perl "$LTL"`;
  the rest run `"$LTL"` directly, so a stub written in Perl serves both.
- The summary line is `Results: $pass passed, $fail failed` in 45 harnesses,
  with a `skipped` or `warning(s)` count in three more; the rest are read per
  harness in their drop.
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
| `features/254-validate-distribution-shape.md`, `features/475-log-level-vocabulary-completion.md`, `features/58-format-registry-staged-detection.md`, `features/638-udm-non-numeric-capture.md`, #387 | dismissed: each matched in the account of its own harness's missing-anchor guard or sabotage proof, or of an empty extraction capture in `ltl`; none governs how a harness reads a failed run |
| 31 other feature docs and `docs/usage.md` | dismissed: matched only `sabotage`, `runtime-warning check` or `empty capture` in the same kind of account; the command above lists them |

## Requirements

- **R1. Every harness that runs `ltl` is read for the shapes.** Each of the 52
  harnesses, including the six changed under #726, is read whole. For each
  one, every comparison, absence check, width check, refusal check and lookup
  assignment is traced back to the run it reads, and every helper that counts
  a failure is checked for a call inside `$( )`. The shapes are those of
  Trap 12 and Trap 13 as quoted in § The contract today.
- **R2. Each case found is fixed** to the form Trap 12 and Trap 13 give, and
  recorded in § Per-harness record: the scenario, the check, the shape, and
  what the fix reads.
- **R3. The shared helpers are read too.** Every capture or lookup helper
  under `tests/lib/` that a harness reads `ltl` output through is read for the
  same shapes, once, before the harnesses that source it.
- **R4. The method is recorded** in `tests/HARNESS-DESIGN.md`, beside Trap 12
  and Trap 13, as the reading a harness gets: what to trace, from where, and
  what each shape's fix is, so the next harness written is checked the same
  way.
- **R5. A stub run confirms a fix; it does not find one.** Each harness is run,
  once it is read and fixed, against an `ltl` that fails and an `ltl` that
  emits nothing, to confirm the *Done when*. Every harness that runs `ltl`
  accepts the stub through `LTL`.

Out of scope: changing what a scenario asserts about a healthy run; the
invocation shape of each run (`tests/HARNESS-DESIGN.md` § Invocation
coherence, whose audit of every harness was #399); `ltl` itself.

## Acceptance criteria

Two stubs, each a two-line Perl script made in a temporary directory: the
**failing stub** prints nothing and exits 1; the **silent stub** prints
nothing and exits 0. A **docs-or-source check** is one whose input is a file
under `docs/`, `features/`, `ltl`'s source text or the harness's own fixtures,
never a capture of a run.

- [ ] **AC1. Against the failing stub, every harness reaches its summary.**
      `LTL=<failing stub> ./tests/validate-<name>.sh`, for each harness that
      runs `ltl`. Pass when: the output ends with the harness's summary line
      and the exit status is non-zero. *Assertable*: the run and its captured
      output.
- [ ] **AC2. Against the failing stub, only docs-or-source checks pass.** Pass
      when: every check the run counts as passed is one named for that harness
      in § Per-harness record as a docs-or-source check; a harness with none
      reports 0 passed. *Assertable*: the run's PASS lines against the list.
- [ ] **AC3. The silent stub, the same.** AC1 and AC2 hold with the silent
      stub, which exits 0 and so reaches the checks that read the capture
      rather than the exit code. *Assertable*: as AC1 and AC2.
- [ ] **AC4. A healthy run loses no check.** Against the real `ltl`, every
      harness exits 0, and its passed count equals the count before this work
      plus the checks this work adds, each named in § Per-harness record.
      *Assertable*: the summary counts of the full suite before and after.
- [ ] **AC5. Every harness takes the stub.** Every harness that runs `ltl`
      reads it from `LTL` when set (`validate-read-path.sh` does not today).
      *Assertable*: AC1 runs on every such harness.
- [ ] **AC6. Each fix can fail.** A check this work adds or changes is shown
      to fail on the stub run or on a doctored capture before it is trusted
      (`tests/HARNESS-DESIGN.md` § Proving a new assertion can fail).
      *Assertable*: the run is recorded with the fix.
- [ ] **AC7. The method is written down.** `tests/HARNESS-DESIGN.md` carries
      the reading of R4. *Assertable* by the architect's review only.

## Delivery plan

Each drop reads its harnesses whole, fixes each case found, records it in
§ Per-harness record, confirms the fixes with the two stubs on the scenarios
it changed, runs those scenarios against the real `ltl`, and ends with a
commit and a push on the issue branch. Groups are by size, smallest first, so
the method is settled on short harnesses before the long ones.

| Drop | What | Harnesses | Lines |
|---|---|---|---|
| 1 | The method in `tests/HARNESS-DESIGN.md` (R4); the helpers under `tests/lib/` (R3); `validate-read-path.sh` takes `LTL` (AC5); the baseline: each harness's passed count on the real `ltl`, and its run against both stubs, captured once | — | — |
| 2 | verbose-content-shape, message-grouping-notices, profile-render, numeric-criteria-notices, outcome-criteria, memory-usage, distribution-shape, profile, doc-examples, classification-states, histogram-colours, category-names, help-layout, regression, csv-output, message-truncation, message-control-characters | 17 | 6.1k |
| 3 | read-path, aggregate-export, bucket-size-units, byte-units, histogram-ticks, classification-percentages, statistics, csv-input, option-resolution, recursive-file-selection, value-display | 11 | 6.1k |
| 4 | progress-line, heatmap-palette, udm-counting, screenshot-capture, format-registry, message-mask, message-grouping, notices | 8 | 6.2k |
| 5 | summary-contribution-bar, section-layout, timestamp-precision, message-expose, log-level-vocabulary, runtime-config | 6 | 6.4k |
| 6 | message-discard, help-content, histogram-bin-counters, udm-specs | 4 | 5.6k |
| 7 | The six changed under #726, read whole: statistics-demand, duration-display, filter-summary, format-detection, explain, index-read-back | 6 | 9.2k |

Then the completion gate: the `after` benchmark, the full suite on the real
`ltl` (AC4), and every harness against both stubs (AC1, AC2, AC3).

Estimate, from the #726 fixes (six harnesses, 9.2k lines, about four hours
by their commit times, so about 2.3k lines an hour read, fixed and proved):
drops 2 to 6 about 13 hours, drop 7 about 2, drop 1 about 1, the stub
confirmations 1 to 2, the gate about 40 minutes (the full suite took 21
minutes on the architect's macOS host, 2026-10-24). About 18 hours in all,
13.5 to 23. The time a harness takes against a stub is not yet measured; the
issue calls it slow, and drop 1's baseline measures it.

## Per-harness record

Filled in by each drop: the checks found, the shape, the fix, and the
docs-or-source checks that pass against the stubs.

| Harness | Drop | Read | Cases found | Docs-or-source checks |
|---|---|---|---|---|
| (none read yet) | | | | |
