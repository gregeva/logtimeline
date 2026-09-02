# Development Workflow

The lifecycle of one issue, from branch to close, and the release that ships it.
`CLAUDE.md` holds the checkpoints; this file holds the procedure behind each one.
Every step here is settled process: it is executed as part of the step that
causes it, never offered for confirmation.

## 1. Starting work on an issue

### Named branch sync — first, always

When the architect names a branch, it is checked out and synced from origin
before any file is read, any question answered, or any plan made:

```bash
git fetch origin --prune
git checkout {branch} 2>/dev/null || git checkout -b {branch} origin/{branch}
git pull --ff-only origin {branch}
git branch --show-current && git status --short
```

A dirty tree or a non-fast-forward pull is raised, not improvised around.
Reasoning from a stale or wrong branch produces confidently false conclusions
that are invisible until they have propagated through a plan.

### Branch naming

`{issue-number}-{slug-from-issue-title}`, the slug kebab-cased from the GitHub
issue **title**, never from the activity being performed on the branch.

- `224-percentile-value-harness`, `225-test-harness-coverage-gaps` — correct
- `225-research`, `225-scaffolding`, `225-cleanup`, `225-fix-it`, a bare number — wrong

A second branch for the same issue takes a numeric suffix (`-2`), not an activity name.

### Version stamping

`$version_number` in `ltl` identifies the branch that produced a build and is set
when the branch is created:

| branch | `$version_number` |
|---|---|
| `release/X.Y.Z` | `X.Y.Z`, in the first commit on the branch |
| `{issue}-{slug}` off `release/X.Y.Z` | `X.Y.Z-{issue}` (e.g. `0.18.0-462`) |
| `main` | whatever the last merged release set |

Every artifact the tool emits (`-v`, `--help`, `-V benchmark-data`) stamps this
string, so two development builds can be told apart from their output. It is
restored to `X.Y.Z` **before** the completion gate runs, as part of that gate,
so the gate runs on exactly the code being merged. Nothing hardcodes a version:
`tests/validate-help-content.sh` reads it from the source and
`tests/validate-regression.sh` normalises it, so changing it never re-blesses a golden.

### Before the first line of code

```bash
git branch --show-current                          # issue number + title slug
./build/issue-status.sh set {number} "in progress"
# set $version_number = "X.Y.Z-{issue}" in ltl
```

Then, when the work touches the hot path or anything executed per line or per
key at high cardinality, capture the performance baseline on the **base commit,
on this machine** (a worktree of the release branch serves if the branch already
has commits):

```bash
./tests/baseline/run-benchmark.sh single-day-access-log-standard --label {issue}-before
```

## 2. Feature lifecycle

Phase 1 begins only on explicit instruction. Filing a requirement
(`docs/process/issues.md` § Filing a requirement) is not planning.

1. **Planning.** The owning feature doc in `features/` is the primary planning
   artifact: requirements, locked decisions (Dxx) with rationale, open items, `-V`
   section contracts, merge gate. The issue body is a snapshot of it, never the
   sole record. Planning walkthroughs are piece by piece: an overall framing
   first (every phase or drop, one line each), then one section at a time with
   confirmation. Before forming a view: identify the surfaces the work touches,
   the feature docs and research that own them, and the locked decisions that
   govern them, and read them. Verify every sub name, path and artifact the issue
   cites actually exists, and audit the current code the plan touches, because
   issue bodies snapshot the tree at writing time. Lead infrastructure work with
   the consumer it exists for. Record ordering between issues as native
   `blocked_by` edges in the same step that establishes them, and re-audit the
   whole cluster's edges after every re-plan.
1a. **Acceptance criteria — part of planning, never after the code.** The
   feature doc gains an `## Acceptance criteria` section derived from the
   requirements: each a condition and an observable outcome, covering the
   requirements whose failure would mean the feature was not delivered. Each is
   triaged *assertable* (method known), *unassertable* (recorded gap; architect
   decides whether the requirement stands) or *unknown* (method not yet known,
   which becomes prototyping scope). Where a requirement names an existing
   mechanism to reuse, the criterion names it too, so it cannot pass against a
   substitute. A criterion that turns out unbuildable mid-implementation is a
   stop-and-raise. Full rule: `docs/test-driven-development.md`.
2. **Prototyping** in `prototype/` — see `prototype/README.md`. Mandatory, not a
   judgement call, for (a) a new or changed data model, (b) a new per-line
   hot-path cost, (c) anything impactful by execution frequency × per-execution
   cost, (d) a key requirement whose verification method is unknown. Research
   grounds the prototype; the prototype compares candidates at staged scale
   against the current code as baseline; exit requires measured justification
   (medians with ranges) and decisions recorded as Dxx before implementation.
   Prototype rules that have cost time when broken: the baseline arm reproduces
   the production call structure verbatim, not a convenience wrapper around its
   logic; every constant is sliced out of `ltl` (pattern:
   `prototype/459-order-independence/extract-subs.sh`) or names its source symbol
   beside it. Before implementing a performance issue's prescribed fix, measure
   the premise's core constants at development scale, mandatory when the code
   has changed since the issue was written.
3. **Scheduling.** Explicit approval before implementation.
4. **Implementation.** Feature doc progress updated as work proceeds. A locked
   decision stands until the architect changes it; a problem discovered
   mid-implementation is brought with candidate designs, never resolved by
   substitution. Changes agreed as "one at a time, each measured" are delivered
   one at a time.
5. **Testing.** Sample files per `docs/test-logs.md`. A visual surface is
   verified by looking at the rendered output on real data, never by grepping
   escape sequences.
6. **Documentation.** `--help` and `docs/usage.md` in the same commit; CLAUDE.md
   if the architecture map changed.

## 3. Completion gate — before the PR

The work is not done, and no PR is opened, until the gate passes **on the
commit being merged**. A gate run that predates the last amend does not count,
and an added commit re-applies the scope test.

### Scope test, applied to the diff

| The diff touches | Full harness suite | Before/after benchmark |
|---|---|---|
| Any executable line of `ltl` | required | required |
| `ltl` comments or whitespace only (`git diff -w` shows only comment lines) | skip; run `perl -c ltl`; say "comment-only" in the commit message | skip |
| Any `tests/validate-*.sh`, `tests/lib/`, or a fixture or expectation a harness reads | required (what "passing" means changed) | required |
| Only `tests/baseline/`, `build/`, `features/`, `docs/`, `releases/`, `patterns/`, `CLAUDE.md` | skip, and record the skip in the completion comment | skip |
| An exempt path **and** any required path, same commit | required | required |

The test is about what could change behaviour or an assertion, never about how
significant the change feels. "The harnesses this change touches" is not a
row in this table.

### (a) The complete harness suite

Every `tests/validate-*.sh` exits 0, and each summary line shows assertions
actually ran. Run `CI=1 ./tests/validate-csv-output.sh` before
`CI=1 ./tests/validate-statistics.sh` (shared cache), then the rest. Capture
each harness's output once to a scratch file and inspect the file.

While working a single harness, the check is that harness. The full suite runs
once, here.

### (b) Before/after benchmark on this machine

```bash
# version restored to X.Y.Z first
./tests/baseline/run-benchmark.sh single-day-access-log-standard --label {issue}-after
./tests/baseline/compare-results.sh summary \
    tests/baseline/results/{issue}-before.tsv tests/baseline/results/{issue}-after.tsv
```

The only valid comparison is before-vs-after, same machine, same case, same
session. A released baseline TSV (`vX.Y.Z.tsv`) was captured on another
machine for the release stage and proves nothing about a change. Any metric
worse by more than 5% is stop-and-investigate (one run is not a median of 3).
Delete both TSVs afterwards. The `full`, `xl` and `all` tiers and the XL file
selections are release instruments and are never run during issue work.

## 4. Merge and close

1. Commit to the feature branch. Commit only when told; "results returned" and
   "commit" are separate instructions.
2. `git push origin {feature-branch}`
3. `gh pr create --base release/X.Y.Z --head {feature-branch}` and immediately
   `./build/issue-status.sh set {number} "in review"`
4. `gh pr merge {PR#} --merge`
5. `git log origin/release/X.Y.Z --oneline -3` to confirm the merge landed.
6. **Release notes.** `releases/v{version}.md` gets one bullet with a `(#NNN)`
   reference if the issue changed what a user of `ltl` observes: the tool, its
   CLI, its output, its user-facing docs. Concise, reflects the change not every
   detail, never describes pre-existing behaviour. Work confined to `build/`,
   `tests/`, `features/`, CLAUDE.md or process gets no bullet. Commit and push
   directly to the release branch.
7. **Completion comment** on the issue: commit hash, branch, PR number, merge
   commit, what shipped. Record a skipped gate (and why) and a withheld
   release-notes bullet, so each omission is a decision, not a gap.
8. `gh issue close {number} --reason completed` and
   `gh issue edit {number} --remove-label "status: in review"` in the same step.
9. **Release the dependents.**
   `gh api repos/{owner}/{repo}/issues/{number}/dependencies/blocking --jq '[.[].number]'`
   and `gh issue list --search "blocked by #{number}"` for prose-only ones. For
   each: drop the closed `blocked_by` edge, true up the body prose, and
   re-decide its status with a comment. An `on hold` that existed only for this
   blocker becomes `in progress` if any work has started, `backlog` only if none has.

### Direct commits to the release branch

The PR gates changes to the tool. Work that cannot change what `ltl` does goes
directly to the release branch: `releases/v{version}.md`, `docs/`, `README.md`,
CLAUDE.md, `features/*.md`. Code, tests and build scripts always go through a
branch and a PR. **The architect's instruction overrides this list in both
directions**: "commit directly" means commit directly whatever the content, and
"open a PR" means open a PR. An apparent conflict is raised before acting.

## 5. Release

### Creating the release branch

The first commit on `release/X.Y.Z` sets `$version_number` to `X.Y.Z`, before
any feature branch is cut from it.

### Cutting the release

Every issue has already been closed under § 4 and `releases/v{version}.md`
already carries every bullet. Never `git merge` anywhere in this sequence.

1. `git checkout release/X.Y.Z && git pull origin release/X.Y.Z`
2. Verify `$version_number` reads `X.Y.Z` (no branch left its `-{issue}` marker). If wrong, fix it here and note which branch.
3. Run every `tests/validate-*.sh`, `CI=1 ./tests/validate-csv-output.sh` first, then `CI=1 ./tests/validate-statistics.sh`, then the rest; capture once, inspect the files. The gate is the complete suite.
4. For `validate-statistics.sh`: T3/T4 failures on any layer (L1 drift, L2 invariants, L3 NumPy/SciPy oracle) block; T1/T2 advisories are reviewed for intentional drift. Then `./tests/cleanup-test-artifacts.sh`.
5. `caffeinate -s ./tests/baseline/run-benchmark.sh all --label vX.Y.Z` (≈2.5 h; `all` is required, `full` is not sufficient).
6. `./tests/baseline/compare-results.sh --save tests/baseline/results/vPREV.tsv tests/baseline/results/vX.Y.Z.tsv`
7. Finalize `releases/v{version}.md`: every user-observable issue has its bullet, benchmark comparison table appended. No usage examples, file lists, "Breaking Changes: None", "Known Issues" or root-cause analysis. Template: `releases/TEMPLATE.md`.
8. `git commit -am "Release vX.Y.Z"`
9. `git push -u origin release/X.Y.Z`
10. `git tag vX.Y.Z && git push origin vX.Y.Z`
11. `gh release create vX.Y.Z --notes-file releases/vX.Y.Z.md`

### Post-release

12. `gh pr create --base main --head release/X.Y.Z --title "Release vX.Y.Z"` then `gh pr merge {PR#} --merge` — never `--delete-branch`, release branches are preserved.
13. **The release is finished only when** `gh pr view {PR#} --json state` reports `MERGED` and `git log --oneline main..release/X.Y.Z` is empty. An open release PR is an unfinished release. Any session that finds main behind a release branch reports that first and fixes it before anything else; it never rebases new work onto the release branch to route around it.
14. Sync the wiki:
    ```bash
    git clone https://github.com/gregeva/logtimeline.wiki.git /tmp/ltl-wiki && cp docs/usage.md /tmp/ltl-wiki/Home.md && cp docs/purpose.md /tmp/ltl-wiki/Purpose-and-Design-Philosophy.md && cp docs/explain/statistics.md /tmp/ltl-wiki/Statistics-Reference.md && cp docs/explain/heatmap.md /tmp/ltl-wiki/Heatmap-Reference.md && cp docs/explain/histogram.md /tmp/ltl-wiki/Histogram-Reference.md && cp docs/explain/classification.md /tmp/ltl-wiki/Classification-Reference.md && cd /tmp/ltl-wiki && git add Home.md Purpose-and-Design-Philosophy.md Statistics-Reference.md Heatmap-Reference.md Histogram-Reference.md Classification-Reference.md && git commit -m "Sync wiki docs from vX.Y.Z" && git push && rm -rf /tmp/ltl-wiki
    ```
    The `docs/` files are the source of truth; the wiki is overwritten each release.
15. Delete merged feature branches: `git branch -d {branch} && git push origin --delete {branch}` — never the release branch.
