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

### Anti-patterns to Avoid

- Writing code "to show what it would look like" without being asked
- Making architectural decisions independently then defending them
- Lengthy explanations when a question would suffice
- Trying to solve everything in one pass instead of iterating

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

If any of these rules conflict with what you're about to do, stop and read HARNESS-DESIGN.md before continuing. Do not improvise.

## Project Overview

LogTimeLine (ltl) is a Perl-based command-line log analysis tool that identifies hotspots in large log files through statistical analysis and time-bucket visualization. It displays horizontal bar graphs with color-coded performance bands and calculates percentile latency statistics (P1 through P99.9).

The repository contains three tools:
- **ltl** - Main analysis tool (single Perl script, ~2,500 lines)
- **cleanlogs** - Bash helper that removes stack traces, partial lines, and health probes
- **twxsummarize** - ThingWorx-specific log summarizer

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
11. **Run benchmarks**: `./tests/baseline/run-benchmark.sh full --label vX.Y.Z` — captures baseline for this release
12. **Compare benchmarks** (if previous baseline exists): `./tests/baseline/compare-results.sh --save tests/baseline/results/vPREV.tsv tests/baseline/results/vX.Y.Z.tsv` — saves full report to `tests/baseline/results/`.
13. Finalize `releases/v{version}.md` — verify all per-feature bullets are present, append benchmark comparison table (from step 12) if available. No usage examples, no file lists, no "Breaking Changes: None", no "Known Issues", no root cause analysis. See `releases/TEMPLATE.md`.
14. Commit: `git commit -am "Release vX.Y.Z"`
15. Push release branch: `git push -u origin release/X.Y.Z`
16. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`

### Post-release
17. **Merge to main via PR (NEVER direct merge):** `gh pr create --base main --head release/X.Y.Z --title "Release vX.Y.Z"` then `gh pr merge {PR#} --merge` (do NOT use `--delete-branch` — release branches must be preserved)
18. **Sync Wiki:** `git clone https://github.com/gregeva/logtimeline.wiki.git /tmp/ltl-wiki && cp docs/usage.md /tmp/ltl-wiki/Home.md && cp docs/purpose.md /tmp/ltl-wiki/Purpose-and-Design-Philosophy.md && cd /tmp/ltl-wiki && git add Home.md Purpose-and-Design-Philosophy.md && git commit -m "Sync wiki docs from vX.Y.Z" && git push && rm -rf /tmp/ltl-wiki` — `docs/usage.md` and `docs/purpose.md` are the single sources of truth; the wiki is overwritten on each release.
19. **Delete all merged feature branches**: `git branch -d {branch} && git push origin --delete {branch}` (repeat for each, NOT the release branch)

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

### Development Phases
1. **Planning**: Create feature doc in `features/`, review existing TO-DOs, create implementation plan
2. **Prototyping** (non-trivial features): Validate approach in `prototype/` directory first
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

See `docs/test-logs.md` for detailed documentation of available test files.

**Quick reference:**
- **Quick tests**: `logs/AccessLogs/localhost_access_log.2025-03-21.txt` (2.6MB)
- **Heatmap tests**: `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log`
- **Large file tests**: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (277MB)

## Heatmap Feature

Heatmap mode (`-hm duration|bytes|count`) replaces latency statistics with color-intensity histogram visualization.

**Options**: `-hm [metric]`, `-hmw <width>` (default 52), `-lbg` (light background)

**Color gradients**: yellow (duration), green (bytes), cyan (count). Uses logarithmic bucket boundaries for better resolution at low values.

For implementation details, see `features/heatmap.md`.
