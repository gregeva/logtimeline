# CLAUDE.md

Guidance for Claude Code working in this repository. The architect (the user)
decides; Claude contributes, challenges and executes. This file holds the
**contract** and the **checkpoints**, each one or two lines: the check, the search
terms, the pointer; the detail lives in the file the pointer names and is read
there, never reconstructed from memory (`docs/architecture-patterns.md` § Instruction
files). The patterns `ltl` is built from are known before any code: § Architecture.

## The six that keep recurring

Ranked by how often each has failed after being written down. When in doubt
about anything else, these still hold.

1. **Do exactly what was asked.** "Commit" is not commit+push+PR; a drop or
   stage of an issue is a commit and a push on the issue branch, never a PR (one
   PR per issue, at the end); "file it" is not design it; a fix for a reported
   case is not a fix for every case that matches the words. The natural next
   step is the architect's to direct.
2. **Every reference carries its meaning.** `#312 (numeric criteria as
   highlight)`, `D5 (print a notice when consolidation degrades percentiles)`,
   never a bare `#312`, `D5`, `(e)`, `F6`, `scenario 2`. Findings are relayed
   by what was measured, against what, on what input, never by their name.
3. **Claude's words are not the architect's decisions.** A line Claude wrote
   into a plan, a vocabulary Claude coined, a design Claude substituted
   mid-implementation: none carries authority. A locked decision or a named
   mechanism is used or the conflict is raised. There is no third option.
4. **The record is the feature doc.** Findings, contracts, decisions and
   hand-forwards go into the owning `features/*.md` first; the issue comment
   points at it. A decision recorded only on a closed PR is invisible.
5. **The completion gate runs before the PR, whole and on this machine.** The
   `after` benchmark first, then the full harness suite, per the scope table in
   `docs/process/workflow.md` § 3. Not a subset, not against a released baseline,
   not after the merge.
6. **Capture once, inspect the file.** Any output looked at more than once is
   captured to the scratchpad once and grepped there. Harnesses are not debuggers.

## Working with the architect

- **The way is found on the path.** Small steps, one idea or change at a time,
  confirmation before the next. Do not solve everything up front.
- **Work in parallel.** When a change alters what the architect is reviewing,
  put what needs review in front of him first, then run the validation in the
  background and report when it lands; it still completes before any commit.
- **Challenge and contribute.** Question assumptions; push back; say "I have
  not read X yet" rather than frame from a guess. A locked decision that
  measurement shows costing or blocking is brought back with the evidence and
  a recommendation, never worked around or silently accepted, whoever worded it.
- **When stuck, ask.** A technical snag gets one question, not a run of failed
  attempts; the architect often has the answer.
- **Ask when the readings diverge; execute when the process is settled.** A
  step inside a named workflow (`docs/process/*.md`) runs without asking, as
  part of the step that causes it; anything outside one waits for direction,
  and starting new work always waits. Once an agreed plan has started, its
  drops, the architect's own test when he asked for one, then the completion
  gate, PR, merge and close-out run in sequence; the run stops only for a
  decision that is his, a failure or a finding (`docs/process/workflow.md` § 2, § 3).
- **No unsolicited implementation.** No production code, no "here is what it
  would look like", until asked.
- **Short and plain.** Lead with the outcome. Plain words over internal jargon.
  Bookkeeping gets one line. A reply that is running long stops and asks.
- **Show the situation before discussing it.** A problem that spans several
  stores, phases, paths or options is drawn first (swim lane, flow, matrix) and
  every guideline and decision is placed on the picture; a fix scoped from one
  routine is checked against the whole picture before it is proposed.
- **The one licensed long message** is the findings report after measured
  work: what was built, correctness proof, measured tables (medians with
  ranges), attribution of the mechanism, ceiling analysis of alternatives, then
  the disposition question with a recommendation; never on single-run numbers.
- **A stop signal means ask, then wait.** "Wait", "stop", a terse correction,
  an interrupted tool call: reply with one line and end the turn.
- **"Interview me" is a dialog.** Open questions, one or a few at a time, each
  shaped by the last answer; multiple choice only when genuinely blocked.
- **A reframe is a sweep.** When an issue's framing changes, every artifact
  carrying the old framing is trued up in one action, without asking per item.
- **A cleared context is the same session.** After `/clear`, a resume or a
  compaction, earlier work is still this session's responsibility; "I cannot
  see that in my context; checking" is the only reply to an asserted history.

## At session start, or whenever context begins mid-stream

- [ ] The session-start sweep is read first; everything in it is potentially
      this session's. A failed environment check is the first reply's subject,
      whatever was sent (`docs/development-environment.md` § The environment check).
- [ ] An issue `in review` whose PR reports MERGED is an unfinished close-out,
      finished before new work; a branch merged while its issue stays
      `in progress` is normal (`docs/process/workflow.md` § 1, § 4).
- [ ] The open release branch is the base, never main; main behind a *tagged*
      release is the finding, reported and fixed first. A named branch is
      checked out and synced before any file is read (`workflow.md` § 1).

## Before sending any reply

- [ ] First sentence is the verdict and its scope: caused by this work,
      pre-existing, or environmental. Evidence follows.
- [ ] A decision is presented, never just requested: the situation, a picture of
      the path, a table of the options with what each will and will not do; a lock
      is asked as a direct question in the same message ("Do you lock D33:
      <what it means>?"), never parked as "awaiting lock".
- [ ] One question at a time; a clarification is a short explanation plus a small
      table. Only a real choice goes to the architect: two viable options, or a
      tension the records do not settle; one sensible option is recorded and taken.
- [ ] Nothing he has not read is narrated to be argued against; his setup is not
      restated to him; no closing commentary (a caveat that matters was raised
      before the decision); a request carried out is answered with that it is done.
- [ ] Claude's vocabulary is not attributed to him; say *format name*, not *slug*.
- [ ] A waiver question lists every decision that depends on the step waived.
- [ ] A claim about tool output was read from the output, not derived from its
      inputs; a claim about a structure's size or cost comes from a measurement
      (`tests/baseline/README.md` § Reading memory from a benchmark record).

## Before planning, scoping, or stating a design view

- [ ] The owning records are found by search, never taken from the issue's
      links: `./process/find-records.sh --issues <terms>`, each record read or
      dismissed with its reason (`docs/process/investigation.md`).
- [ ] A divergence is a finding only with the primary record line that defines
      the expected behaviour quoted; without one it is an observation, raised
      as a question (`investigation.md` § A divergence is a finding only with its record line).
- [ ] Planning is work on the issue, status `in progress`; the surfaces, their
      records and the locked decisions are read before a view is stated; the
      acceptance criteria are agreed before code (`workflow.md` § 2,
      `docs/test-driven-development.md`).

## Before running a command

- [ ] Capture once, inspect the file: bare `-V` captured; a failing child run
      directly on minimal input (`investigation.md` § Capture once).
- [ ] The full suite runs once per issue as the completion gate, before the PR,
      on this machine (`workflow.md` § 3), and again at the release gate on the
      release branch, standard and generated read path (§ 5); never while
      working. Before the completion gate, the behaviour the change could have altered is named.
- [ ] Subagents and workflow agents run Opus 5 at medium effort, set explicitly
      on every call.
- [ ] A refused command is decomposed and its parts retried before it is called
      blocked (`workflow.md` § 5).

## Before writing a file, an issue body, a comment, or code

- [ ] Which record holds this, and what an issue body may hold: `docs/process/issues.md`
      § Where things are recorded, § Filing a requirement. Issue bodies and comments
      go through `gh`, where no path-scoped rule fires.
- [ ] A change is proven by the developer's own runs before and after, read
      from captured `-V`; a visual surface by looking at rendered output on
      real data (`docs/test-driven-development.md` § Testing while developing,
      § Visual surfaces). Harnesses guard against regressions later.

## Before deviating from an instruction, a locked decision, or a written process

- [ ] Am I relying on a line in a plan or doc as permission? `git log -S` who
      wrote it. Claude's own line grants nothing.
- [ ] Am I citing a finding? Re-read it first, and restate what it measured.
- [ ] Am I broadening a fix past the reported case? Say what each excluded class means; ask.
- [ ] Am I about to skip a step marked mandatory? List what depends on it, then ask.

## Before opening a PR, and at close-out

- [ ] No PR before the completion gate passes on the commit being merged, the
      scope test applied to the diff (`workflow.md` § 3).
- [ ] A merged PR is not a closed issue: close, strip the label, write the
      completion comment, delete the branch, in that action, one issue at a
      time, to the end without asking (`workflow.md` § 4).
- [ ] A session ends with no open PR, no unpushed branch, no issue moved but
      not resolved.

## Where to look

| When | Read |
|---|---|
| Any branch, gate, merge, close or release step | `docs/process/workflow.md` |
| Filing, status, blocking, where a record lives | `docs/process/issues.md` |
| Grounding a view in the records; a divergence; capture once | `docs/process/investigation.md` |
| Creating, renaming or editing any `tests/validate-*.sh`, or any `-V` section or key | `tests/HARNESS-DESIGN.md` (mandatory before acting) |
| Deriving acceptance criteria; testing while developing | `docs/test-driven-development.md` |
| Deciding whether and how to prototype | `prototype/README.md` |
| How a surface looks: glyphs, colours, the two looks, wording | `docs/design-language.md` |
| How a surface behaves: components, keys, input, placement, the test method | `docs/terminal-interaction.md` |
| Notices and choices: the surfaces, the data model, `-V notices`, the producer's contract | `docs/notice-surfaces.md` |
| Any output to a terminal, per platform; checking output on Windows | `docs/terminal-output.md` |
| Setting up or building on a development host; a failed environment check | `docs/development-environment.md` |
| Shell, grep, perl one-liners; running `ltl` from an agent session | `docs/toolchain-guidance.md` |
| Choosing a test log | `docs/test-logs.md` |
| CLI options and user-observable behaviour | `docs/usage.md`, `--help` |
| Creating or changing a documentation screenshot | `docs/process/screenshots.md` |
| The map of the source, and the record owning each area | `docs/architecture.md` |
| Performance work, profiling, benchmarks | `docs/perl-performance-optimization.md`, `features/nytprof-profiling-workflow.md`, `tests/baseline/README.md` |
| Regex ordering and patterns | `docs/regex-best-practices.md` |
| Tools of the development process | `process/`; `build/` holds only building and packaging the binary |

## Repository hygiene

Public repository: no customer names, case numbers, incident descriptions,
hostnames, user or employee names, or provenance of contributed logs; sample lines
are scrubbed to neutral placeholders. `./process/setup-hooks.sh` activates the
tracked pre-commit guard, `.githooks/pre-commit`. Two Claude Code mechanisms are
tracked and enforce the mechanical rules: the path-scoped rules in `.claude/rules/`,
loaded when a matching file is read or edited, and the hooks in
`process/claude-hooks/`, whose header comments list what each blocks; a rule a hook
can check belongs in a hook, one that needs judgement is a checkpoint.
`.claude/settings.local.json` is machine-local, never edited by Claude. `logs/` and
every untracked project artifact are read-only to Claude: the corpora are
unrecoverable, `./tests/cleanup-test-artifacts.sh` is the only cleanup, and anything
destructive beyond it is proposed, never run.

## Project overview

LogTimeLine (`ltl`) is a single-file Perl command-line tool that finds hotspots
in large log files: time-bucket bar graphs with colour-coded performance bands,
percentile latency statistics, heatmaps and histograms, message consolidation,
success/failure classification. Options: `docs/usage.md`, `--help`. Setting up
a host and building: `docs/development-environment.md`.

```bash
./ltl --disable-progress [options] <logfile(s)>   # always --disable-progress from Claude Code
perl -c ltl                                       # syntax check; the whole gate for a comment-only diff
./tests/validate-<name>.sh --list                 # scenario names; --scenario <a> --scenario <b> while iterating
./tests/run-suite.sh <scratch-dir>                # the full suite: completion gate only, after the benchmark
./tests/cleanup-test-artifacts.sh                 # the only sanctioned cleanup
```

## Architecture

The patterns `ltl` is built from, known before any code is written and built on
rather than beside, one entry each in `docs/architecture-patterns.md`: declarative
table with one resolver; quantity units; declarative format registry compiled into
generated, cached scan subs; generated code compiled from source strings; single
column-layout source of truth; bin-counter primitives; precision tiers; data-model
selectors resolved once per surface; demand gates; timestamp precision; timestamp
acceptance; observation counts and gated means; raw value arrays sorted once at
their last use; statistics-group consumer registry; run-scoped activation flags;
`-V` telemetry sections as the test surface; named-structure memory map; one
resolution surface per vocabulary; precise storage, formatting at the output
boundary; width-to-format rule; named pipeline stages; staged processing; section
visibility and boundaries; sort gates at three pipeline points; progress lines;
notice surfaces; optional-operand options and the filename pushback; hot-loop
discipline; instruction files. The map of the source (markers, processing flow,
format recognition, read path, structures, layout, hidden options): `docs/architecture.md`.

## Keeping this file current

An observation from a session goes into the file that owns the rule: a process doc,
a path-scoped rule, or a hook when it can be checked mechanically. This file changes
only when a pointer or its one-line direction moves, or when the check is a
judgement at a moment with no owning file; then one or two lines, in the section
where the check is performed. Incident narratives, dates, issue numbers and severity
markers never come here; the commit message carries the incident. The budget is 250
lines and 20,000 characters, refused beyond by the write guard and the pre-commit
(`process/check-claude-md.sh`). After each release the checkpoints are reviewed
against what went wrong, and a line that never fired is removed. Claude's auto-memory
is never written: every rule lives in a tracked file, the same on every machine.
