# 766: CLAUDE.md carries direction, search terms and pointers; the detail lives in the owning file

**Status:** complete. Branch `766-claude-md-pointers` off `release/0.20.0`;
`CLAUDE.md` at 250 lines and 16,141 characters. Gate on d86fcd89: benchmark
pair `766-before`/`766-after` on byte-identical `ltl` (every delta is host
noise; total 10.9 s to 10.2 s, calculate_statistics 82 ms to 284 ms on one
run each), then the full suite through `tests/run-suite.sh`, 54 harnesses, 54
passed, 0 failed, every summary counting assertions run.

## Requirement

`CLAUDE.md` had grown to 38,000 characters and 578 lines, against Claude Code's
guidance of about 200 lines per instruction file, by carrying each procedure
beside its check; the procedures were already in `docs/process/workflow.md`,
`docs/process/issues.md`, a `.claude/rules/*.md` file or a hook. The agent's
replies grew long and it stopped following the direction the file gives. The
standard pattern, stated and applied: the detail lives in the owning process
doc or rule, and `CLAUDE.md` holds only extremely concise direction, the search
terms and the pointer; the agent reads the file the pointer names.

## Decisions

- **D1 (locked).** Budget: 250 lines and 20,000 characters, enforced by
  `process/check-claude-md.sh`, run by `process/claude-hooks/guard-write.sh`
  on the content a write would leave and by `.githooks/pre-commit` on the
  staged file.
- **D2 (locked).** The pattern is an entry of `docs/architecture-patterns.md`
  (§ Instruction files), whose introduction now covers the development process
  as well as `ltl`; `CLAUDE.md` states the rule in its header and in
  § Keeping this file current.
- **D3 (locked).** `docs/architecture-patterns.md` is named in the header of
  `CLAUDE.md` and opens its § Architecture, with every pattern's name listed,
  kept in sync by the commit that adds an entry.
- **D4 (locked).** Investigation practice (finding the owning records, the
  divergence rule, measuring a premise, capture once) gets
  `docs/process/investigation.md`: it is practice for any view, not a
  lifecycle step, so neither `workflow.md` nor `issues.md` owns it.
- **D5 (locked).** The rule for scripts whose output a person reads becomes
  `.claude/rules/scripts.md`, scoped to `process/`, `build/`, `tests/` and
  `prototype/`.
- **D6 (locked).** The architecture map moves to `docs/architecture.md`; the
  build and package commands to `docs/development-environment.md`.

## Mapping

Of the 94 checkpoint items, about 60 restated a line already in an owning file
and were cut to a pointer; about 25 stayed as one-line judgement checks; the
facts that existed only in `CLAUDE.md` moved as follows.

| Fact | Now in |
|---|---|
| The reply to a failed environment check: host only, no issue or branch named | `docs/development-environment.md` § The environment check |
| The open release branch is the base; reading the session-start sweep; `in review` with a merged PR | `docs/process/workflow.md` § 1 |
| What a drop and a stage are, and what ends each | `docs/process/workflow.md` § 2, Drops and stages |
| The first message on a new issue states each surface's contract | `docs/process/workflow.md` § 2 step 1 |
| Before the completion gate: name the behaviour the change could have altered | `docs/process/workflow.md` § 3 |
| The parent issue's close-out; removing the worktree and its `logs` symlink | `docs/process/workflow.md` § 4 steps 10 and 11 |
| Finding the owning records with `find-records.sh`; re-search when a decision adds a surface; the divergence rule; capture once; bare `-V`; a failing child run directly | `docs/process/investigation.md` |
| Invariant criteria validated on every enumerated path | `docs/test-driven-development.md` § A criterion is only as strong as its validation |
| The code before the change via `git show <base>:ltl`, both captured with `-V` | `docs/test-driven-development.md` § Testing while developing |
| Claude's own leftovers deleted without asking | `docs/toolchain-guidance.md` § Running `ltl` from an agent session |
| The 1.9% worktree penalty; `-mem` high-water marks as the source of size claims | `tests/baseline/README.md` § Same-machine comparability, § Reading memory from a benchmark record |
| Scripts whose output a person reads follow `docs/terminal-output.md` | `.claude/rules/scripts.md` |
| Section markers, processing flow, format recognition, read path, key structures, column layout, platform, heatmap, hidden options, the record per area | `docs/architecture.md` |
| Package builds and the release build workflow | `docs/development-environment.md` § Building the binaries |
| Where a working rule for the agent lives | `docs/process/issues.md` § Where things are recorded |

## Acceptance criteria

- [x] `CLAUDE.md` is at most 250 lines and 20,000 characters:
      `process/check-claude-md.sh CLAUDE.md` exits 0. Validated: 250 lines,
      16,141 characters, exit 0.
- [x] A write that would take `CLAUDE.md` over either limit is refused by
      `guard-write.sh`, and a staged `CLAUDE.md` over either is refused by the
      pre-commit. Validated: the checker on a copy 300 lines over exits 1; the
      hook fed a Write call and an Edit call carrying such content exits 2 with
      both limits named; the 255-line draft of this change was refused by the
      hook before it was trimmed.
- [x] Every row of § Mapping is found in its destination by a search for its
      terms. Validated: each destination section written in this change and
      read back.
- [x] No tracked file points at a `CLAUDE.md` section that no longer exists.
      Validated: every `CLAUDE.md` reference outside `features/`, `releases/`
      and the analysis records under `tests/profile/results/` names a section
      the file has, or was moved to the rule or doc that now holds the line
      (four harness contract sets, `tests/HARNESS-DESIGN.md`,
      `docs/architecture-patterns.md`, `docs/percentage-presentation.md`,
      `process/find-records.sh`).
- [x] `process/check-architecture-patterns.sh docs/architecture-patterns.md`
      exits 0 with the new entry. Validated against the base version, as the
      pre-commit runs it: three entries over 60 lines before this change are
      unchanged and pass by the no-growth rule.
- [x] Every sub, marker, structure and option `docs/architecture.md` names
      exists in `ltl`. Validated by grep; `--debug-layout` and
      `--validate-layout`, named by the old `CLAUDE.md`, do not exist and were
      not carried over.

## Gate

The diff touches `CLAUDE.md`, `docs/`, `features/`, `.claude/rules/`,
`process/`, `.githooks/` and, by the architect's decision to true up the
harness contract strings that named the cut section, four
`tests/validate-*.sh`; `ltl` only through the version stamp, restored before
the gate. The harness row of the scope table put the full gate in force: the
before/after benchmark pair, then the full suite, both recorded in the Status
line above. The four harnesses each ran one scenario and their scenarios of
`tests/validate-harness-failed-run.sh` (60 checks) before the strings were
committed.
