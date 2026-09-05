# CLAUDE.md

Guidance for Claude Code working in this repository. The architect (the user)
decides; Claude contributes, challenges and executes. This file holds the
**contract** and the **checkpoints**, the checks run at the moment they apply.
Procedure lives in the files under *Where to look* and is read when a
checkpoint names it, never reconstructed from memory.

## The six that keep recurring

Ranked by how often each has failed after being written down. When in doubt
about anything else, these still hold.

1. **Do exactly what was asked.** "Commit" is not commit+push+PR; a drop or
   stage of an issue is a commit and a push on the issue branch, never a PR (one
   PR per issue, at the end); "file it" is not design it; a fix for a reported case is not a fix for every case that
   matches the words. The natural next step is the architect's to direct.
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
   full harness suite plus a before/after benchmark, per the scope table in
   `docs/process/workflow.md` § 3. Not a subset, not against a released baseline,
   not after the merge.
6. **Capture once, inspect the file.** Any output looked at more than once is
   captured to the scratchpad once and grepped there. Harnesses are not debuggers.

## Working with the architect

- **The way is found on the path.** Small steps, one idea or change at a time,
  confirmation before the next. Do not solve everything up front.
- **Challenge and contribute.** Question assumptions; push back when something
  seems wrong; say "I have not read X yet" rather than frame from a guess.
- **When stuck, ask.** A technical snag (precision, a toolchain trap, an
  unexpected result) gets one question, not a run of failed attempts; the
  architect often has the answer.
- **Ask when the readings diverge; execute when the process is settled.** A
  step inside a named workflow (`docs/process/*.md`) runs without asking, as
  part of the step that causes it. Anything outside a named workflow waits for
  direction. Starting new work always waits.
- **No unsolicited implementation.** No production code, no "here is what it
  would look like", until asked.
- **Short and plain.** Lead with the outcome. Plain words over internal jargon.
  Bookkeeping gets one line. A reply that is running long stops and asks.
- **The one licensed long message** is the findings report after measured
  work: what was built, correctness proof, measured tables (medians with
  ranges), attribution of the mechanism, ceiling analysis of alternatives, and
  only then the disposition question with a recommendation. Never a bare
  "keep or revert?" on single-run numbers.
- **A stop signal means ask, then wait.** "Wait", "stop", "we're not done", a
  terse correction, an interrupted tool call: reply with one line and end the
  turn. No investigating to guess the intent.
- **"Interview me" is a dialog.** Open questions, one or a few at a time, each
  shaped by the last answer. Structured multiple choice only when genuinely
  blocked among known alternatives.
- **A reframe is a sweep.** When an issue's framing changes, every artifact
  carrying the old framing is trued up in one action, without asking per item.
- **A cleared context is the same session.** After `/clear`, a resume or a
  compaction, earlier work is still this session's responsibility. "I cannot see
  that in my context; checking" is the only reply to a history the architect
  asserts, followed by evidence.

## Checkpoints

### At session start, or whenever context begins mid-stream

- [ ] Reconstruct outstanding state before anything else: `gh pr list --state open`,
      `git branch -a --no-merged main`, `./build/issue-status.sh list`, uncommitted
      or unpushed work in every worktree. Everything found is potentially this
      session's.
- [ ] Main behind a release branch is the finding: report it first, fix it first,
      never route around it.
- [ ] A named branch is checked out and synced from origin before any file is
      read (`docs/process/workflow.md` § 1).
- [ ] Before the first line of code: branch name matches the issue title, status
      set to `in progress`, `$version_number` stamped, and a `before` benchmark
      captured on the base commit if the hot path is in scope.

### Before sending any reply

- [ ] Scan for identifiers: `#NNN`, `D`/`R`/`F`/`P` plus digits, option letters,
      stage numbers, scenario and harness names. Each carries its meaning in the
      same sentence, or is rewritten to name the thing.
- [ ] First sentence is the verdict and its scope: caused by this work,
      pre-existing, or environmental. Evidence follows.
- [ ] A decision being asked for is stated in what it means: what the tool will
      do, will not do, and the consequence. The sentence stands without its IDs.
- [ ] Nothing the architect has not read is narrated in order to be argued
      against. No retracted framings, no self-orienting context.
- [ ] One question at a time. A clarification gets a short explanation plus a
      small table, not a discourse.
- [ ] No closing commentary ("worth keeping in mind", "one caveat"). A caveat
      that matters was raised before the decision.
- [ ] His setup is not restated to him (gitignore, layout, what is generated).
- [ ] Claude's vocabulary is not attributed to him; say *format name*, not *slug*.
- [ ] A waiver question lists every decision that depends on the step being waived.
- [ ] A claim about tool output was read from the tool's output, not derived
      from its inputs.

### Before planning, scoping, or stating a design view

- [ ] Name the surfaces the work touches, the feature docs and research that own
      them, and the locked decisions that govern them. Read them. Then speak.
- [ ] Read every feature file and doc the issue references; investigation
      findings live there, not in the thread.
- [ ] Verify every sub name, path and artifact the issue cites exists; note
      corrections on the issue. Audit the current code the plan touches.
- [ ] Lead with the motivating consumer: what this is *for* precedes what it does.
- [ ] Acceptance criteria are derived from the requirements and agreed in the
      feature doc before code (`docs/test-driven-development.md`). An "unknown"
      verification method is prototyping scope, proposed with its cost.
- [ ] Prototype triggers (`prototype/README.md`): new or changed data model,
      new per-line cost, high frequency × cost, unknown verification method.
- [ ] A performance fix measures its premise's constants first, mandatory when
      the code has moved since the issue was written.
- [ ] Ordering between issues is a native `blocked_by` edge, recorded in the
      same step; the whole cluster is re-audited after any re-plan.
- [ ] Walkthroughs are piece by piece: framing first, one line per phase, then
      one section at a time with confirmation.

### Before running a command

- [ ] `ltl` always gets `--disable-progress`.
- [ ] Will I look at this output more than once? Capture once to the scratchpad,
      then grep, sed, diff, python3 against the file.
- [ ] A failing child process is invoked directly on minimal input, not through
      the parent harness. A harness under iteration uses `--scenario` or a
      single-test selector.
- [ ] Only the harness under discussion runs while working it. The full suite
      runs once, as the completion gate. Before launching any gate: name the
      behaviour this change could have altered; if none, there is nothing to prove.
- [ ] Every `ltl` invocation in a test is shaped to the assertion that reads it:
      smallest fixture carrying the signal, everything unread switched off via
      documented options (`-bs 1440 -oe` for detection and selection assertions).
      See `tests/HARNESS-DESIGN.md` § Invocation coherence.
- [ ] The `full`, `xl` and `all` benchmark tiers are release instruments, never
      development tools.
- [ ] Benchmark results, analysis reports and comparisons under `tests/` are
      deliverables: never overwritten for a test or a debug run. Use a separate
      label or a scratch copy.
- [ ] Nothing destructive touches `logs/`, its symlink, or any untracked project
      artifact: no `rm`, `mv`, `git clean`, `git checkout -- .`, truncating
      redirect. `./tests/cleanup-test-artifacts.sh` is the only cleanup. A corpus
      that looks missing is a finding to report, never a state to repair.
- [ ] Subagents and workflow agents run Opus 5 at medium effort, set explicitly
      on every call.
- [ ] Read `docs/toolchain-guidance.md` before ad-hoc shell one-liners against this repo.

### Before writing a file, an issue body, or a comment

- [ ] Is this an artifact of the software, or of working on it? Problem
      reports, tool feedback, transcripts and scratch go to the scratchpad or
      `/tmp`, never into the repository.
- [ ] This is a public repository. No customer names, case numbers, incident
      descriptions, hostnames, user names, employee names, or provenance of
      contributed logs. Sample lines are scrubbed to neutral placeholders.
- [ ] No change history in code, comments or headers ("renamed from", "used to
      be"). Comments describe the current state; git holds the history.
- [ ] No internals in user-facing prose (`--help`, `--explain`, `docs/usage.md`,
      `docs/explain/`, wiki, error messages): no Perl identifiers, issue numbers,
      decision labels, or other tools' internals.
- [ ] Issue body at filing: am I describing HOW? Then it does not belong. No
      line numbers; code is referenced by function name plus snippet.
      Full rule: `docs/process/issues.md` § Filing a requirement.
- [ ] A finding, contract, constraint or status change goes into the owning
      feature doc in the same action; the comment points at it.
- [ ] A decision made anywhere else is transcribed onto the open issue now.
- [ ] A deferral pointer names a committed artifact, verified to contain the thing.
- [ ] A cross-issue note passes the dependency-first test
      (`docs/process/issues.md` § Blocking relationships).
- [ ] A release-notes bullet reflects the change concisely, never pre-existing
      behaviour, and only for user-observable change.
- [ ] Committed fixtures are named `.txt` (`*.log` and `*.csv` are gitignored);
      `git ls-files` confirms tracking before a fixture is planned around.

### Before writing or changing code

- [ ] Grep for the domain nouns first. One resolution surface per vocabulary:
      parsing, matching, validation and formatting of a value class call the
      existing sub. Near-duplicates found on the way are converged in the same change.
- [ ] Every accumulator tracks an observation count; derived output is gated on
      `count > 0`, never on `defined` over a zero-initialised field.
- [ ] Any ` at <file> line <N>` on `ltl`'s stderr is a bug. Every harness that
      invokes `ltl` includes the runtime-warning check (`tests/lib/runtime-warnings.sh`).
- [ ] A new option has a short form, a long form, a `print_help()` row and a
      `docs/usage.md` row in the same commit. A description never restates the
      row indicator.
- [ ] Behavioural notices (auto-disable, fallback, limit hit) always print;
      `--disable-progress` suppresses progress indicators only.
- [ ] Any harness change: the file name tracks the `-V` section it validates;
      every assertion declares `asserts`, `produced_by` (function name, not line)
      and `contract`; a lookup that matches nothing is a failure, never a pass.
- [ ] Any `-V` section or key change: read `tests/HARNESS-DESIGN.md` first,
      update every consumer and the owning feature doc's section contract in the
      same commit, and execute each affected harness to see it assert.
- [ ] A visual surface is verified by looking at rendered output on real data.

### Before deviating from an instruction, a locked decision, or a written process

- [ ] Did the architect name the mechanism? Then it is the decision; use it or ask.
- [ ] Does this conflict with a locked Dxx? Bring the problem and candidate
      designs; never substitute and proceed.
- [ ] Am I relying on a line in a plan or doc as permission? `git log -S` who
      wrote it. Claude's own line grants nothing.
- [ ] Am I citing a finding? Re-read it first, and restate what it measured.
- [ ] Was this agreed as "one at a time, each measured"? Then one at a time.
- [ ] Am I broadening a fix past the reported case? Say what each newly
      excluded class means and ask.
- [ ] Am I about to skip a step marked mandatory? List what depends on it, then ask.

### Before opening a PR

- [ ] Scope test applied to the diff (`docs/process/workflow.md` § 3): full suite
      and before/after benchmark, or a recorded skip.
- [ ] `$version_number` restored to `X.Y.Z` before the gate ran.
- [ ] The gate ran on the commit being merged; an amend re-runs it.
- [ ] `--help` and `docs/usage.md` agree (`tests/validate-help-content.sh`).
- [ ] Commit trailer is model-agnostic: `Co-Authored-By: Claude <noreply@anthropic.com>`.

### At close-out

- [ ] **Issue:** release-notes decision, completion comment (with any recorded
      skip), close with label stripped, dependents released
      (`docs/process/workflow.md` § 4).
- [ ] **Release:** `gh pr view` reports `MERGED` and `git log main..release/X.Y.Z`
      is empty. Otherwise the release is not finished.
- [ ] **Session:** no open PRs, no unpushed branches, no issue moved but not resolved.

## Where to look

| When | Read |
|---|---|
| Any branch, gate, merge, close or release step | `docs/process/workflow.md` |
| Filing, status, blocking, where a record lives | `docs/process/issues.md` |
| Creating, renaming or editing any `tests/validate-*.sh`, or any `-V` section or key | `tests/HARNESS-DESIGN.md` (mandatory before acting) |
| Deriving acceptance criteria | `docs/test-driven-development.md` |
| Deciding whether and how to prototype | `prototype/README.md` |
| Shell, grep, perl one-liners against this repo | `docs/toolchain-guidance.md` |
| Choosing a test log | `docs/test-logs.md` (single source of truth; never cite files elsewhere) |
| CLI options and user-observable behaviour | `docs/usage.md`, `--help` |
| Format detection, extraction, classification | `features/log-format-registry.md` (system of record), `features/453-success-failure-classification-event-ledger.md` |
| Column rendering | `features/column-layout-refactor.md` |
| Heatmap and histogram | `features/heatmap.md`, `features/histogram-charts.md`, `docs/explain/` |
| Bin-counter substrate and precision tiers | `features/189-histogram-bin-counter-primitives.md`, `features/293-precision-lever-unification.md` |
| Performance work and profiling | `docs/perl-performance-optimization.md`, `features/nytprof-profiling-workflow.md`, `tests/baseline/README.md` |
| Regex ordering and patterns | `docs/regex-best-practices.md` |
| What is enforced automatically, and how | `.claude/rules/`, `build/claude-hooks/` |

## Repository hygiene

Public repository. `./build/setup-hooks.sh` activates the tracked pre-commit
guard at `.githooks/pre-commit`, which blocks staging anything under `.claude/`
except the two shared, reviewed files named below, plus `.env*`, key and
credential files, and common token patterns; `.gitignore` is the primary
defense. Overriding needs `--no-verify` and an explanation in the commit message.

Two mechanisms of the Claude Code harness are tracked so that the mechanical
rules in this file are enforced rather than advised:

- `.claude/rules/*.md`: path-scoped rules loaded when a file matching their
  `paths` is read or edited (harnesses, `ltl`, user docs, feature docs,
  prototypes, release notes, benchmark tooling).
- `.claude/settings.json`: hooks. At session start, resume, clear and compaction
  `build/claude-hooks/session-start.sh` prints the outstanding-state sweep into
  context. Before every Bash call `build/claude-hooks/guard-bash.sh` blocks
  destructive operations against `logs/`, `ltl` without `--disable-progress`,
  `git merge`, pushes to main, `--delete-branch`, and model-versioned commit
  trailers, and asks before release-only benchmark tiers or `--no-verify`.
  Before every file write `build/claude-hooks/guard-write.sh` blocks writes
  under `logs/`, to released baseline TSVs, and of problem reports into the repo.

A rule that a hook can check belongs in a hook; a rule that needs judgement
belongs in a checkpoint. `.claude/settings.local.json` stays machine-local and
is never edited by Claude.

`logs/` and every untracked project artifact are read-only to Claude. The
corpora are gathered from real systems, gitignored and unrecoverable; anything
destructive outside `./tests/cleanup-test-artifacts.sh` is proposed to the
architect and run only on his say-so.

## Project overview

LogTimeLine (`ltl`) is a single-file Perl command-line tool that finds hotspots
in large log files: time-bucket bar graphs with colour-coded performance bands,
percentile latency statistics (P1 to P99.9), heatmaps and histograms, message
consolidation, success/failure classification.

```bash
./ltl --disable-progress [options] <logfile(s)>     # always --disable-progress from Claude Code
```

Key options: `-n N`, `-b N` (bucket minutes), `-o` (CSV), `-ni` (no index),
`-dmin/-dmax`, `-include/-exclude`, `-ipf/-epf/-hpf` (pattern files under
`patterns/`: `metrics`, `navigate-app-calls`, `probes`, `thingworx`), `-du`,
`-hm`, `-hg`, `-ms`, `-st/-et`, `-hses`, `-g N`, `--help`.
Hidden: `--disable-progress`, `--terminal-width N`, `--debug-layout`,
`--validate-layout`, `--detection-window=N`.

### Build

```bash
./build/macos-setup.sh                      # macOS: Homebrew Perl, never system Perl
sudo apt-get install build-essential perl perl-base perl-modules libperl-dev cpanminus \
  && cpanm PAR::Packer && cd build && ./generate-cpanfile.sh && cpanm --notest --installdeps .
./build/macos-package.sh arm64|x86_64       # static binaries
./build/ubuntu-package.sh amd64|arm64       # Docker
./build/windows-package.sh                  # Docker + Wine
```

GitHub Actions builds all platforms on `v*` tags (`.github/workflows/release-build.yml`).

## Architecture

`ltl` has three section markers; search for them rather than relying on line
numbers: `## GLOBALS ##` (`$version_number`, configuration, data structures,
options), `## SUBS ##`, `## MAIN ##`.

**Processing flow:** `adapt_to_command_line_options()` →
`read_and_process_logs()` → `calculate_all_statistics()` →
`normalize_data_for_output()` → `print_bar_graph()` → `print_summary_table()`.

**Format recognition** runs through the format registry (marker
`## FORMAT REGISTRY`): declarative per-format specs in `format_registry_specs()`
are built by `build_format_registry()` into a live registry; one generated scan
sub per most-recently-used order is compiled on demand and cached by order
signature. Every run self-validates against each entry's sample lines. Detection
evidence comes from a read-only sample (`sample_file_for_detection()`: front,
middle and end parts) before a file's first line; variant groups share a line
shape and are scored by `select_format_variants()`; `-lf` pins a format. Each
spec declares its success/failure `classification` and `event_ledger` flag,
compiled into the scan block. Adding or changing a format means editing its
spec, never hot-loop code. Records: `features/log-format-registry.md`,
`features/453-success-failure-classification-event-ledger.md`; user surfaces
`--help formats`, `--explain classification`.

**Key structures:** `@format_registry` / `@format_scan_order` /
`$format_scan_sub`; `%log_occurrences` (tallies per bucket); `%log_analysis`
(bucket statistics); `%log_messages`; `%log_stats`; `%heatmap_data`;
`@heatmap_boundaries` (N+1 boundaries for N columns).

**Column layout:** `@column_layout` is the single source of truth for widths,
spacing, visibility and colours; dynamic columns via `add_dynamic_column()`;
auto-hides at narrow widths. `@column_colors` holds per-column ANSI definitions.

**Platform:** `Proc::ProcessTable` on Unix, `Win32::Process::Info` on Windows,
detected via `$^O eq 'MSWin32'`.

**Heatmap** (`-hm duration|bytes|count`, `-hmw <width>`, `-lbg`): logarithmic
bucket boundaries, gradients yellow/green/cyan by metric.

## Keeping this file current

An observation from a session is recorded by editing the checkpoint or
principle it belongs to, in one or two lines, in the section where the check is
performed; a rule that can be checked mechanically goes into a hook under
`build/claude-hooks/` or a path-scoped rule under `.claude/rules/` instead. Incident narratives, dates, issue numbers and severity markers do
not go here; the commit message that makes the edit carries the incident.
After each release, the checkpoints are reviewed against what actually went
wrong, and anything that never fired is removed.
