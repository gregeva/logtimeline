# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Collaboration Model

**This is a co-authoring relationship.** The user is the architect and decision-maker. Claude is an active collaborator who contributes ideas, challenges assumptions, and helps discover the right path through dialog.

### Core Principles

1. **The way is found on the path.** We discover the right approach through iteration. Don't try to solve everything upfront. Take small steps, learn from each one.
2. **Challenge and contribute.** Bring ideas to the table. Question assumptions. Push back when something seems wrong.
3. **Ask, don't assume.** When uncertain about approach, scope, or priority - ask.
4. **Small steps with confirmation.** Present one idea or change at a time. Wait for confirmation before proceeding.
5. **No unsolicited implementation.** Do not write production code until explicitly asked.
6. **Dialog over monologue.** Keep responses concise. If writing more than a few paragraphs, stop and ask a clarifying question instead.
7. **Do exactly what was asked — no more.** Treat every instruction as literal scope, not as a hint toward a larger goal. "Commit" means commit, not commit+push+PR. "Push" means push, not push+open-PR. "Create the branch" means create the branch, not branch+commit+push. "File the issue" means file the issue, not file+cross-link+update-related. When the next step seems obvious, ask — don't take it. The user is the architect; inferring "what they really wanted" is overreach, even when the inference is correct.
8. **Reference IDs always carry context.** When referring to any ledger reference ID in communication with the user — issue ID, task ID, decision ID, test case ID, PR number, commit hash, etc. — ALWAYS append a short parenthesized description expressing the semantic context of the referenced entry. Example: `#312 (numeric criteria as highlight, not just filter)`, never a bare `#312`. The user should never have to look up what an ID refers to.

### Anti-patterns to Avoid

- Writing code "to show what it would look like" without being asked
- Making architectural decisions independently then defending them
- Lengthy explanations when a question would suffice
- Trying to solve everything in one pass instead of iterating
- Extending an instruction past its literal scope (e.g., committing → also pushing → also opening a PR when only "commit" was asked)
- Treating "the natural next step" as implicit permission. The natural next step is for the user to direct, not for Claude to take.
- Acting on the inferred larger goal when only a specific narrow step was requested. If the user asks for step 3 of a 10-step plan, do step 3 and stop — even if step 4 looks trivial.

### Continuous Improvement

Track observations for process improvement. After releases, review what worked and what caused friction. Update CLAUDE.md with agreed changes.

**Observations log:**
- 2026-02-02: CRITICAL - Always use `--disable-progress` when running ltl from Claude Code. Progress output wastes massive tokens/cost. This was discovered after months of wasteful execution.
- 2026-02-03: CRITICAL - Release workflow - Feature branches need PRs before merging to release branch. Release branch needs PR before merging to main. Never use `--delete-branch` when merging release PRs - release branches must be preserved.
- 2026-02-07: CRITICAL - REPEATED VIOLATION - Direct merge of release/0.11.0 to main instead of PR. Root cause: step 12 in release process itself said `git merge`. Fixed step 12 to use `gh pr create`. NEVER run `git merge` or `git checkout main && git merge` during a release.
- 2026-02-06: CRITICAL - DO NOT directly merge feature branches to release branch with `git merge`. ALWAYS create a PR first using `gh pr create --base release/X.Y.Z --head feature-branch`. This was forgotten again during v0.10.4 release.
- 2026-02-03: After tagging a release, always create the GitHub release with `gh release create <tag> --notes-file releases/<version>.md` to attach release notes.
- 2026-02-03: When stuck on technical issues (e.g., floating-point precision), ask the user rather than iterating through failed attempts. The user often has quick answers.
- 2026-02-03: For sub-second time buckets in Perl, use integer milliseconds for hash keys to avoid floating-point precision issues (e.g., `.099` instead of `.100`).
- 2026-03-08: CRITICAL - Output files (benchmark results, analysis reports, comparisons) are DELIVERABLES, not temp files. NEVER overwrite them for testing/debugging. Always use a separate label or temp copy. Back up before any destructive operation.
- 2026-02-05: When updating issues with fix completion, always include the commit hash and branch name.
- 2026-02-07: When adding or modifying CLI options, update `print_help()` in ltl and the options reference in README.md.
- 2026-05-22: CRITICAL - REPEATED VIOLATION - Do NOT embed change history in code, comments, or script headers. NEVER write "renamed from X to Y under Issue #N", "filename was previously X", "section was originally called X then Y then Z", "this used to be X", or any equivalent narrative explaining what something *was* before the current state. Comments describe the *current* state of the code: what it does, why it does it, what contract it asserts against. Change history belongs in git: commit messages, `git blame`, `git log`, the PR description, and the GitHub issue. A reader running `git blame` on a renamed file or a renamed identifier already sees the rename in the commit history. Embedding the rename in a code comment duplicates that information, ages immediately (the comment outlives the relevance of the rename), and clutters the file. This applies to: script header comments, sub/function header comments, inline comments next to changed code, and reserved-name registries. Violated repeatedly during #226 (2026-05-22) — embedded rename narratives in `ltl`, `tests/validate-histogram-bin-counters.sh`, `tests/validate-index-read-back.sh`, and HARNESS-DESIGN.md.
- 2026-05-23: CRITICAL - Do NOT leak internal implementation details into user-facing documentation. User-facing text (`--help`, `--explain` topic prose, `docs/usage.md`, `docs/explain/*.md`, Wiki pages, error messages, CSV column descriptions) must describe what the user observes and what it means to them — never the internal mechanism. Forbidden in user prose: Perl identifiers (hash names like `%column_colors`, sub names, global variables), GitHub issue numbers (`#187`, `#220`, `#222`, etc.), internal jargon (`bin-counter substrate`, `Decision 8`, `locked-decision`, `HARNESS-DESIGN`), and references to external tool internals (`OpenTelemetry's Scale-4 analog`, etc.) unless they have direct operational value to the reader. Implementation details belong in source-code comments, feature docs (`features/*.md`), issue bodies, and PR descriptions — places future developers look, not places users look. Violated during #261 phase 2 in five `--explain` topic paragraphs (iqr, percentiles, kurtosis, bimodality_coef, histogram) and four `docs/explain/statistics.md` sections; user caught it in the heatmap topic, sweep applied to the rest.
- 2026-05-26: CRITICAL — CAPTURE-ONCE GATE. Before running ANY test/harness/command whose output you will inspect more than once, ask: "will I look at this output more than once?" If yes (almost always): run it ONCE with `> /tmp/<tag>.out 2>&1`, then `grep`/`head`/`tail`/`sed`/`diff`/`python3` against THAT FILE as many times as needed. NEVER re-run the same command for a different output slice ("next line", "other scenario", "what the failure was", "another column") — that information is already in the file. The checklist:
  1. Capture full output to `/tmp/<tag>.out` ONCE.
  2. Inspect by grepping the FILE — repeat freely, zero extra runs.
  3. Failing subprocess (oracle/helper/child) → invoke it DIRECTLY on minimal input (ms/iteration), not via the parent harness (min/iteration).
  4. Iterating a harness → use `--scenario <name>` / single-test selectors.
  5. Re-run the FULL harness only as the final go/no-go gate.
  6. Generating CSVs to inspect → generate ONCE into a temp dir; parse with `python3 csv` (never naive `split /,/` on quoted CSV — it misaligns columns and fabricates phantom "bugs").
  Runtimes that make re-running expensive: `validate-statistics.sh` ~3 min, `validate-histogram-bin-counters.sh` ~2 min, `validate-doc-examples.sh` ~40s. Long-running harnesses are NOT debuggers. Violated repeatedly in #287 (ran `validate-statistics.sh` ~8× in one debug cycle = ~25 min for ~80s of fix work) AND again throughout #289 (re-ran `validate-histogram-bin-counters.sh` 3×, re-ran `ltl` CSV generation many× with one-off greps) despite this entry already existing — loading the rule is not consulting it; treat it as a mechanical pre-Bash gate.
- 2026-07-09: BUG TRIAGE — CONTRACT FIRST. Before changing behavior to fix a reported bug, establish the intended contract from the written sources (docs/usage.md, feature docs, locked decisions in features/*.md) and verify what the code actually does against it. In the 2026-07-09 session, half the bugs (#320, #321) turned out to be correct behavior whose contract was undocumented or contradicted by dead code — the right fix was documentation + visibility (a note/warning + doc sweep), not a behavior change. Changing behavior first would have broken the documented contract.
- 2026-07-09: DEFERRAL POINTERS MUST POINT AT COMMITTED ARTIFACTS. When deferring work with "restorable from branch history" / "recoverable from X", verify X actually contains the artifact before writing the deferral — commit the draft (on the branch, or paste it into the issue) before deleting it. #324's issue claimed the drafted udm-numeric scenario was restorable from the #313 branch; it was never committed anywhere and had to be recreated from scratch.
- 2026-07-09: ISSUE BODIES REFERENCE CODE BY FUNCTION NAME + SNIPPET, NOT LINE NUMBER. All four bug issues fixed on 2026-07-09 cited `ltl:NNNN` line numbers that had drifted by the time they were worked (one moved twice in a single day as sibling fixes landed). Line numbers may be included as hints, but the durable reference is the enclosing function name plus a distinctive code snippet to grep for — same rule the harness `produced_by` field already follows.
- 2026-07-09: GATE ON OBSERVATION COUNTS, NOT DEFINED-NESS. When a metric accumulator is 0-initialized (`total => 0`, `sum => 0`), `defined $total` is true for keys that never observed the metric, so emission and arithmetic gated on it produce zeros indistinguishable from measured zeros — and divisions by never-set sibling fields. The rule when writing or reviewing any aggregate: (a) track an observation count (or list) alongside every accumulator and gate all derived output on `count > 0`; (b) when "no data" must be distinguishable downstream, clear or never-set the accumulator instead of emitting its initializer; (c) treat any `defined $x` gate over a 0-initialized field as a review defect. (#326 counting-UDM division, #330 zero duration totals.)
- 2026-07-09: RUNTIME WARNINGS ARE BUGS, AND HARNESSES MUST PROVE THEIR ABSENCE. Any ` at <file> line <N>`-suffixed line on ltl's stderr is an unguarded data path — fix it, never dismiss it as noise, even when the visible output looks correct. Every harness that invokes ltl must include the stderr runtime-warning check per `tests/HARNESS-DESIGN.md` § Runtime-warning cleanliness (reference implementation: `tests/validate-csv-output.sh`); when touching any harness that lacks it, add the check in the same change (#341 tracks the sweep of existing harnesses).
- 2026-07-09: CRITICAL — ONE RESOLUTION SURFACE PER VOCABULARY; DUPLICATED LOGIC IS A DEFECT. Before writing any parsing, resolution, validation, matching, or formatting logic, search for an existing sub that already handles the same vocabulary or value class and call it — never re-implement locally, not even a "small" variant. When work surfaces existing near-duplicates (two options parsing the same operand set, two sites formatting the same value class, two copies of a lookup), converge them into one named sub IN THE SAME CHANGE — fixing only your copy leaves the divergence to re-emerge. The mechanical gate before writing such code: grep for the domain nouns (`grep -n 'duration|bytes|count' ltl`-style) and read what already resolves them; any new `elsif` ladder restating names, units, or aliases defined elsewhere is a review defect. Incident: `-hm`/`-hg` each parsed metric-name operands independently and diverged twice — #327 (`-hg` lowercased UDM names) and, found during convergence, `-hm` matched built-ins case-sensitively in contradiction of the documented contract — until both were routed through `builtin_metric_name()`/`resolve_metric_operand()`/`available_metric_names()`.
- 2026-07-06: CRITICAL — DOCUMENTATION MUST STAY ALIGNED. The `--help` output (`print_help()` in `ltl`) and the options reference in `docs/usage.md` are parallel user-facing surfaces documenting the SAME options. Whenever an option is added, removed, or its description is edited on one surface, apply the equivalent change to the other in the SAME commit — they must always agree on which options exist AND carry consistent (not necessarily identical) descriptions. A description must not restate what the row indicator already shows (e.g. an `--explain` row's text should not say "--explain …"). `tests/validate-help-content.sh` enforces that every non-hidden long option appears in both `--help` and `docs/usage.md`. When only one surface is updated, the two drift and the docs mislead; changing the help wording without mirroring it in `docs/usage.md` is an incomplete change.
- 2026-07-13: FINDINGS BEFORE DISPOSITION. After deep implementation-plus-measurement work, deliver an observation-based, attributed findings analysis — what was built, correctness proof, measured tables (medians with ranges), where the cost/benefit manifests, mechanism, ceiling analysis — BEFORE asking any disposition question. A bare multiple-choice "keep or revert?" without the analysis is not collaboration and destroys trust in the recommendation. Violated during #306 (2026-07-13): came to the architect with a revert question backed by single-run numbers and no attribution.
- 2026-07-13: VALIDATE THE PREMISE BEFORE IMPLEMENTING PERFORMANCE FIXES. Before implementing a perf issue's prescribed fix, spend a short dev-scale probe measuring the premise's core constants (e.g. per-element cost of the proposed mechanism vs the code it replaces) — MANDATORY when the codebase has changed since the issue was written. #306's fused-moment fix was fully implemented, validated, and baseline-re-blessed before a 30-minute measurement would have rejected it: the issue predated #305, which had already removed the regression it targeted, and the fused update measured 7–8× the per-element cost of the pass it replaced (see features/305-shape-moment-extended-percentile-demand.md § #306 investigation).
- 2026-07-13: ISSUE-CITED ARTIFACTS ARE VERIFIED AT WORK-START. Extends the 2026-07-09 function-name rule: every sub name, baseline/artifact filename, and path an issue body cites is verified to exist before planning against it, and corrections are noted on the issue. #306 cited `combine_stats_sidecars` (never existed; the real sub is `merge_bin_state`) and `v0.15.0-second.tsv` (never existed; the artifact is `v0.15.0.tsv`).
- 2026-07-13: "INTERVIEW" MEANS CONVERSATIONAL DIALOG, NOT A MULTIPLE-CHOICE QUESTIONNAIRE. When the user asks to be interviewed (to close gaps, gather requirements, or explore a design), conduct an actual interview: open-ended questions asked conversationally, one or a few at a time, with each follow-up shaped by the previous answer. Do NOT present batches of multiple-choice option lists — pre-framed options constrain the answer space to what Claude already thought of, which defeats the purpose of interviewing the architect. Multiple-choice prompts remain acceptable only when Claude is genuinely blocked on a decision among known alternatives — never as a substitute for a requested interview. Violated during #303 (2026-07-13): three rounds of multiple-choice questionnaires were presented in place of the requested interview.
- 2026-07-16: ISSUES ARE POINTERS, NOT ARTIFACTS. Before planning from any issue: (a) read the feature files and docs/* it references — investigation issues record findings in their feature file, not the issue thread (#323's findings live in features/189-histogram-bin-counter-primitives.md; reading only the thread missed them); (b) audit the current code the plan touches — issue bodies snapshot the tree at writing time, and two releases of drift invalidated a stage inventory this session (#180: demand registry #305, unified finalize #187/#189, data-model dispatch #266 all absent from the 2026-05 snapshot). A design question already answered in a referenced doc (docs/regex-best-practices.md ordering policies) must not be re-derived or presented as novel.
- 2026-07-16: FEATURE DOC IS THE PRIMARY PLANNING ARTIFACT. Planning walkthroughs produce/update the owning feature doc (requirements, locked decisions with rationale, in-drop open items, `-V` section-contract stubs, merge gate); the GitHub issue body is a snapshot of it, never the sole record. Violated for #180/#58/#60 — all three feature docs had to be retrofitted after the fact.
- 2026-07-16: MOTIVATING CONSUMER FIRST. When scoping infrastructure work, identify and lead with the consumer it exists FOR — "what is this for" precedes "what does it do." Phase 2's founding motivation (inter-line derived metrics, 2026-02-06 decision 2) surfaced late and forced a release re-cut (D21): infrastructure whose motivating consumer is deferred gets deferred with it.
- 2026-07-16: NATIVE DEPENDENCIES ARE SET AT PLANNING TIME, NOT PROSE-ONLY. When a planning conversation establishes ordering or gating between issues, record the native `blocked_by` links as part of that same step — prose "depends on" lines in bodies and feature docs are not dependencies GitHub understands (the mandate already in "Issue Blocking Relationships" applies during planning, not just issue filing). Violated this session: the entire 0.17.0 merge-train order existed in words only until called out.
- 2026-07-16: DEPENDENCY-FIRST TEST BEFORE WRITING ANY CROSS-ISSUE NOTE. Before posting a comment or body line connecting two issues, apply the test: "can this issue proceed to a clean implementation before the other lands?" If no → it is a dependency: native `blocked_by` + agreeing body prose, never a comment. If yes → an informational relationship note is acceptable, and it should state explicitly why it is NOT a gate. The structural dependency graph is how we understand which aspects of the software rely on which — notes scattered on issues do not build it. Caught twice in one session: #155←#58 was written as a "relationship note" when D23 had just made it a real gate, and #155's own body carried a prose-only "Depends on #154".
- 2026-07-16: RE-AUDIT THE DEPENDENCY GRAPH AFTER EVERY RE-PLAN. Native `blocked_by` links and body prose are maintained through plan changes, not just at creation — after any re-cut, verify both across the whole cluster. The D21 re-cut left three stale/missing edges (#61←#59, #59←#60, #369 gated on the umbrella #23 instead of the fixing drop #58).
- 2026-07-16: PLANNING WALKTHROUGHS ARE PIECE-BY-PIECE. Start with an overall framing that lays out the shape of everything to be covered (all phases/drops, one line each), then walk sections one at a time with confirmation before moving on. Never dump multiple full issue-body drafts or batched question lists in one message.
- 2026-07-13: XL BENCHMARK SUITES ARE RELEASE-GATE INSTRUMENTS ONLY. The bundled performance suites (`run-benchmark.sh` full/xl/all and the XL file selections like month-single-server / month-many-servers) exist to measure release-level performance and catch regressions BEFORE a release ships — they are NOT development tools and are not run while iterating on an issue. Issue-level performance work uses its own specific, targeted, singular test cases (small fixtures, single files, single named scenarios) sized to the question being asked. Violated during #305 (ran the month-single-server XL selection mid-development).

## Repository Hygiene

This is a public repository. After cloning, run `./build/setup-hooks.sh` once to activate the tracked pre-commit guard at `.githooks/pre-commit`. The guard blocks commits that stage `.claude/`, `.env*`, `*.pem`/`*.key`/`*.p12`/`*.pfx`/`*.kdbx`, `id_rsa*`/`id_ed25519*`, `.netrc`, `.npmrc`, `secrets/`, `credentials*`, or content matching common token patterns (AWS, GitHub, OpenAI, Slack, PEM private keys). `.gitignore` is the primary defense; the hook is a backstop. If you genuinely need to override, use `git commit --no-verify` and explain in the commit message.

## Test harness contract — MANDATORY

**Before performing any of the following actions, you MUST first read `tests/HARNESS-DESIGN.md`.** That document defines the rules; this section is the trigger.

The following actions require a HARNESS-DESIGN.md consultation:

- Renaming or removing a `-V` section or sub-section header
- Renaming, removing, or modifying the format of any content key inside any `-V` section
- Adding a new `-V` section to the registry in `ltl`
- Creating any file under `tests/validate-*.sh`
- Renaming any file under `tests/validate-*.sh`
- Modifying assertion behavior in any harness (the regex itself, the helper functions, or the failure output)

Hard rules that have already cost time in this repository when violated:

- **Harness file names track the section they validate.** A harness for the `histogram-bin-counters` section lives in `tests/validate-histogram-bin-counters.sh`. When a section is renamed, the harness file is `git mv`'d to match **in the same commit**. Verify spelling matches the section's CLI name exactly (e.g., `index-read-back` not `index-readback`).
- **`-V` section and key renames are breaking changes.** Discover every consumer with `grep -r "=== name ===" tests/` (or the equivalent for content keys). Update every consumer in the same commit. Then **execute each affected harness and confirm it still asserts** — exit code 0 is insufficient; assertion lines must actually match.
- **Harness assertions must self-document.** Every assertion declares `asserts` (the application invariant), `produced_by` (where in `ltl` it is produced — function name, not line number), and `contract` (the stability source). All three are surfaced on failure. Reference implementation: `tests/validate-histogram-bin-counters.sh`.
- **A grep that matches nothing is a failure, not a pass.** Every harness must treat a zero-match anchor lookup as a hard failure.
- **Every `-V` diagnostic is documented in its owning feature doc.** Each `-V` section has an owning feature doc (`features/*.md`) with a section-contract heading that records the locked line shapes AND the semantics of every counter/key emitted: what it counts, when it increments, what its edge cases mean. Adding, renaming, or changing any `-V` line or counter updates that feature-doc contract in the SAME commit, so the verbose output, the feature doc, and the consuming harness always cross-reference. A counter whose full semantics live only in the code is an observability gap: a counter with an undocumented eligibility gate (n≥4) was nearly used as a before/after instrument it could not serve (#303/#305).

If any of these rules conflict with what you're about to do, stop and read HARNESS-DESIGN.md before continuing. Do not improvise.

## Project Overview

LogTimeLine (ltl) is a Perl-based command-line log analysis tool that identifies hotspots in large log files through statistical analysis and time-bucket visualization. It displays horizontal bar graphs with color-coded performance bands and calculates percentile latency statistics (P1 through P99.9).

The repository contains one tool:
- **ltl** - Main analysis tool (single Perl script, ~2,500 lines)

## Build Commands

### Install Dependencies
```bash
# macOS (uses Homebrew Perl — do NOT use macOS system Perl)
./build/macos-setup.sh

# Ubuntu/Linux
sudo apt-get install build-essential perl perl-base perl-modules libperl-dev cpanminus
cpanm PAR::Packer
cd build && ./generate-cpanfile.sh && cpanm --notest --installdeps .
```

### Build Static Binaries
```bash
./build/macos-package.sh arm64|x86_64    # macOS
./build/ubuntu-package.sh amd64|arm64    # Linux (requires Docker)
./build/windows-package.sh               # Windows (requires Docker + Wine)
```

### CI/CD
GitHub Actions builds all platforms on version tags (`v*`). See `.github/workflows/release-build.yml`.

## Release Process

**CRITICAL: Follow these steps exactly. Do not skip steps or change the order.**

### Per-feature workflow (every feature/bugfix branch — MANDATORY post-merge)

When a feature/bugfix branch lands via PR into the release branch, complete the following in order. **Do not skip steps.** These are per-feature obligations, not release-cutting tasks:

1. Commit all changes to feature branch
2. Push feature branch: `git push origin {feature-branch}`
3. Create PR into the active release branch: `gh pr create --base release/X.Y.Z --head {feature-branch}`
4. Merge the PR: `gh pr merge {PR#} --merge`
5. Verify the release branch picked up the merge: `git log origin/release/X.Y.Z --oneline -3`
6. Update `releases/v{version}.md` directly on the release branch: add ONE bullet per merged issue with `(#NNN)` reference. No prose, no metacommentary. Commit + push directly to the release branch (this is the canonical exception to "no direct commits" — release-notes maintenance is release-process work, not issue work).
7. Add a completion comment to the GitHub issue: commit hash, branch name, PR #, merge commit, summary of what shipped.
8. Close the issue: `gh issue close {number} --reason completed`. The issue is addressed when it makes it into a release branch — it does not need to wait for the release to ship.

### Cutting the release

By the time you cut the release, every feature/bugfix issue has already been comment-and-closed under the per-feature workflow above, and `releases/v{version}.md` already contains all the bullets. This phase finalizes versioning, benchmarks, tagging, and the merge back to main.

9. Switch to the release branch: `git checkout release/X.Y.Z && git pull origin release/X.Y.Z`
10. Update version in `ltl` (`$version_number` near top of GLOBALS section)
11. **Run ALL validation harnesses**: every `tests/validate-*.sh` must exit 0 before proceeding — the release gate is the complete suite, not a subset. Run `CI=1 ./tests/validate-csv-output.sh` before `CI=1 ./tests/validate-statistics.sh` (the `CI=1` cache is shared between them), then every other `tests/validate-*.sh`. Capture each harness's output once to a file and inspect the file (capture-once rule).
12. **Review advisories and clean up**: for `validate-statistics.sh`, T3/T4 failures on any of the three layers (L1 drift against committed baselines, L2 intra-row arithmetic invariants, L3 algorithm-aware NumPy/SciPy oracle) block the release; T1/T2 advisories are non-blocking — review to confirm any drift is intentional. After all harnesses pass, run `./tests/cleanup-test-artifacts.sh` to remove the shared scratch directory.
13. **Run benchmarks**: `./tests/baseline/run-benchmark.sh all --label vX.Y.Z` — captures the release baseline across ALL file selections including XL (≈2.5 h; run under `caffeinate -s`). The `all` tier is required for release validation; `full` is not sufficient.
14. **Compare benchmarks** (if previous baseline exists): `./tests/baseline/compare-results.sh --save tests/baseline/results/vPREV.tsv tests/baseline/results/vX.Y.Z.tsv` — saves full report to `tests/baseline/results/`.
15. Finalize `releases/v{version}.md` — verify all per-feature bullets are present, append benchmark comparison table (from step 14) if available. No usage examples, no file lists, no "Breaking Changes: None", no "Known Issues", no root cause analysis. See `releases/TEMPLATE.md`.
16. Commit: `git commit -am "Release vX.Y.Z"`
17. Push release branch: `git push -u origin release/X.Y.Z`
18. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`

### Post-release
19. **Merge to main via PR (NEVER direct merge):** `gh pr create --base main --head release/X.Y.Z --title "Release vX.Y.Z"` then `gh pr merge {PR#} --merge` (do NOT use `--delete-branch` — release branches must be preserved)
20. **Sync Wiki:** `git clone https://github.com/gregeva/logtimeline.wiki.git /tmp/ltl-wiki && cp docs/usage.md /tmp/ltl-wiki/Home.md && cp docs/purpose.md /tmp/ltl-wiki/Purpose-and-Design-Philosophy.md && cp docs/explain/statistics.md /tmp/ltl-wiki/Statistics-Reference.md && cp docs/explain/heatmap.md /tmp/ltl-wiki/Heatmap-Reference.md && cp docs/explain/histogram.md /tmp/ltl-wiki/Histogram-Reference.md && cd /tmp/ltl-wiki && git add Home.md Purpose-and-Design-Philosophy.md Statistics-Reference.md Heatmap-Reference.md Histogram-Reference.md && git commit -m "Sync wiki docs from vX.Y.Z" && git push && rm -rf /tmp/ltl-wiki` — `docs/usage.md`, `docs/purpose.md`, `docs/explain/statistics.md`, `docs/explain/heatmap.md`, and `docs/explain/histogram.md` are the single sources of truth; the wiki is overwritten on each release.
21. **Delete all merged feature branches**: `git branch -d {branch} && git push origin --delete {branch}` (repeat for each, NOT the release branch)

### Run Directly
```bash
./ltl [options] <logfile(s)>
```

Key options: `-n N` (top N messages), `-b N` (bucket size minutes), `-o` (CSV output), `-dmin/-dmax` (duration filters), `-include/-exclude` (pattern filters), `-if/-ef/-hf` (pattern files), `-du` (duration unit), `-hm` (heatmap), `-hg` (histogram), `-ms` (millisecond precision), `-st/-et` (time range filters, supports milliseconds), `-hs` (hide sessions column), `-g N` (fuzzy message consolidation at N% similarity), `--help` (full help)

**Hidden options:** `--disable-progress` (ALWAYS use this flag when running ltl from Claude Code — suppresses progress output that wastes tokens), `--terminal-width N` (control terminal width in piped/non-TTY contexts), `--debug-layout`, `--validate-layout`.

## Architecture

### Code Structure (ltl)
Search for these section markers in the file — line numbers shift as the codebase grows:
- **`## GLOBALS ##`**: Version (`$version_number`), configuration, data structures, command-line options
- **`## SUBS ##`**: All processing and output subroutines
- **`## MAIN ##`**: Execution flow

### Key Data Structures
- `%log_occurrences` - Count tallies across time buckets
- `%log_analysis` - Time bucket statistics
- `%log_messages` - Message groupings
- `%log_stats` - Statistical calculations (min/max/avg/stddev/percentiles)
- `%heatmap_data` - Histogram bucket counts per time bucket
- `@heatmap_boundaries` - Logarithmic bucket boundaries (N+1 elements for N columns)

### Output Column Layout
`@column_layout` is the single source of truth for all column rendering — widths, spacing, visibility, colors. Dynamic columns (threadpools, sessions, user-defined metrics) are inserted via `add_dynamic_column()`. The layout engine handles auto-hiding columns at narrow terminal widths. `@column_colors` carries ANSI color definitions per column. For detailed technical documentation, see `features/column-layout-refactor.md` (issue #33).

Hidden CLI options: `--disable-progress` (ALWAYS use from Claude Code), `--terminal-width N`, `--debug-layout`, `--validate-layout`.

### Core Processing Flow
1. `adapt_to_command_line_options()` - Parse command line
2. `read_and_process_logs()` - Stream log files, extract timestamps/messages
3. `calculate_all_statistics()` - Compute statistics per bucket
4. `normalize_data_for_output()` - Prepare display data
5. `print_bar_graph()` - Render time-bucket visualization
6. `print_summary_table()` - Output statistics

### Platform-Specific Code
- Unix: Uses `Proc::ProcessTable` for memory tracking
- Windows: Uses `Win32::Process::Info` instead
- Platform detection via `$^O eq 'MSWin32'`

## Development Workflow

### Branch Naming (MANDATORY)

Each issue gets its own branch named `{issue-number}-{semantic-slug-from-issue-title}`. The slug MUST be derived from the GitHub issue's title (kebab-cased, semantically tight) — **never** from the activity being performed on the branch.

**Why this matters:** Branches outlive their initial purpose. A branch named after the current activity becomes misleading once it grows into other work. A branch named after the issue stays accurate through the whole lifecycle.

**Examples:**
- Issue #224 "Percentile-value regression test harness with tiered tolerance" → `224-percentile-value-harness` ✓
- Issue #225 "Test-harness coverage gaps: high-priority additions..." → `225-test-harness-coverage-gaps` ✓

**Anti-patterns — DO NOT use:**
- `225-research` / `225-research-deliverables` — activity name, not issue title
- `225-scaffolding` / `225-grounding` / `225-cleanup` — activity names
- `225-fix-it` — vague activity description
- Issue number without any slug — ambiguous

If multiple branches are genuinely needed for one issue (rare), differentiate with a numeric suffix like `225-test-harness-coverage-gaps-2`, **not** with an activity name.

### Branch Verification (MANDATORY FIRST STEP)
```bash
git branch --show-current  # Must start with the issue number AND match the issue's semantic title
```

**CRITICAL:** Verify branch before making code changes. Do not write production code until implementation plan is approved.

### GitHub Issue Updates (MANDATORY)
Update issues throughout development: when starting, during investigation, on design decisions, and when complete. Close with `gh issue close <number> --reason completed`.

The **`not planned` label** marks an **open** issue retained as a decision/spec record (e.g. #370, temporal interpolation): the capability is specified for the record but not planned for implementation. Do not close such issues — "label as not planned" and "close as not planned" are different dispositions.

### Issue Blocking Relationships (MANDATORY)

Blocking is tracked ONLY through GitHub's native issue-dependency mechanism — never a `blocked` label, a "Blocked by #N" line in the body, or a comment. Those are prose that GitHub does not understand as a dependency; the label was removed from this repo for exactly this reason. When an issue cannot proceed until another open issue lands, record it as a native `blocked_by` dependency (which automatically surfaces the reciprocal `blocking` on the other issue).

Rules:
- **The blocker must be an OPEN issue.** A closed issue is no longer a block — resolve or drop the dependency instead.
- **State the dependency in the body prose too**, as a human-readable `Blocked by #N (short context)` line, but the prose NEVER stands in for the native dependency — both must exist and agree.
- **Both directions are maintained by the one API call**: setting `blocked_by` on the dependent issue makes GitHub show `blocking` on the blocker automatically. Do not add anything by hand on the blocker side.

GraphQL does not yet expose these fields; use the REST endpoints (`issue_id` is the blocker's numeric `id`, passed as an integer via `-F`, not its issue number):

```bash
# Add: "#DEPENDENT is blocked by #BLOCKER"
BLOCKER_ID=$(gh api repos/{owner}/{repo}/issues/BLOCKER --jq '.id')
gh api --method POST repos/{owner}/{repo}/issues/DEPENDENT/dependencies/blocked_by -F issue_id="$BLOCKER_ID"

# Inspect
gh api repos/{owner}/{repo}/issues/DEPENDENT/dependencies/blocked_by --jq '[.[].number]'
gh api repos/{owner}/{repo}/issues/BLOCKER/dependencies/blocking --jq '[.[].number]'
```

### Development Phases
1. **Planning**: Create feature doc in `features/`, review existing TO-DOs, create implementation plan
2. **Prototyping** (non-trivial features): Validate approach in `prototype/` directory first. **MANDATORY — not a judgment call — when the work introduces (a) a new or changed data model, (b) a new per-line hot-path cost, or (c) any feature/fix deemed impactful by its cost profile — execution frequency × per-execution cost (a cheap operation run tens of millions of times, or an expensive one run per key at high cardinality).** The workflow is research → prototype → validate → refine design → record decisions (as Dxx in the owning feature doc) → implement. Research precedes and grounds the prototype (candidate representations, applicable measured constants, prior findings); the prototype compares implementation candidates at staged scale (1k → 10k → 100k → millions) against the current code as baseline; exit requires measured justification (medians with ranges) and lessons learned recorded BEFORE implementation begins. Precedent: #187 Decision 10; applied to #58 (registry data model) and #372 (pair-correlation store + sub-determination) on 2026-07-16. Data models are far more expensive to change after they ship than to validate up front.
3. **Scheduling**: Get explicit user approval before implementation
4. **Implementation**: Update feature doc progress as you work
5. **Testing**: Use sample files in `logs/` directory (see `docs/test-logs.md`)
6. **Documentation**: Update help text, CLAUDE.md if architecture changed, close GitHub issue

## Pattern Files

The `patterns/` directory contains filter patterns for `-if`, `-ef`, and `-hf` options:
- `metrics` - ThingWorx metrics endpoints
- `navigate-app-calls` - Windchill Navigate API calls
- `probes` - Health check endpoints
- `thingworx` - ThingWorx-specific patterns

## Test Log Files

See `docs/test-logs.md` for the documentation of available test files and which to use per use case. It is the single source of truth — do not cite specific log files here.

## Heatmap Feature

Heatmap mode (`-hm duration|bytes|count`) replaces latency statistics with color-intensity histogram visualization.

**Options**: `-hm [metric]`, `-hmw <width>` (default 52), `-lbg` (light background)

**Color gradients**: yellow (duration), green (bytes), cyan (count). Uses logarithmic bucket boundaries for better resolution at low values.

For implementation details, see `features/heatmap.md`.
