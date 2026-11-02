# 766: CLAUDE.md carries direction, search terms and pointers; the detail lives in the owning file

**Status:** in progress, on branch `766-claude-md-pointers` off `release/0.20.0`.

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

- [ ] `CLAUDE.md` is at most 250 lines and 20,000 characters:
      `process/check-claude-md.sh CLAUDE.md` exits 0. Assertable, by the script.
- [ ] A write that would take `CLAUDE.md` over either limit is refused by
      `guard-write.sh`, and a staged `CLAUDE.md` over either is refused by the
      pre-commit. Assertable: the checker on a copy one line over the limit,
      and the hook fed a Write call carrying that content.
- [ ] Every row of § Mapping is found in its destination by a search for its
      terms. Assertable: one grep per row.
- [ ] No tracked file points at a `CLAUDE.md` section that no longer exists.
      Assertable: every `CLAUDE.md` reference outside `features/` names a
      section the file has.
- [ ] `process/check-architecture-patterns.sh docs/architecture-patterns.md`
      exits 0 with the new entry.
- [ ] Every sub, marker, structure and option `docs/architecture.md` names
      exists in `ltl`. Assertable: one grep per name.

## Gate

The diff touches `CLAUDE.md`, `docs/`, `features/`, `.claude/rules/`,
`process/` and `.githooks/`: nothing that asserts against `ltl`, and `ltl`
itself only through the version stamp, restored before the PR. The completion
gate is skipped under the scope table and the skip recorded in the completion
comment; `perl -c` on the changed hook, `bash -n` on the pre-commit, and the
hand tests above stand in.
