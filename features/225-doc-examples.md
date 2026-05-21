# Doc Examples Verification (Issue #234)

## Overview

Sub-task of #225 (umbrella for high-priority test-harness coverage gaps). Adds an
automated check that the `ltl` command-line examples shown in user-facing
documentation actually parse and execute successfully. These have drifted before
(option renames, sample-file moves, hidden-flag changes) and the wiki sync at
release-step 15 has no gate that would catch broken examples before they ship
to `https://github.com/gregeva/logtimeline/wiki`.

## Status

**Research / scoping** — no implementation yet. This document is the input to
implementation on #234.

## Framework dependency

Weak dependency on #226 (`-V` selectivity). A few examples in `docs/usage.md`
invoke `-V` (e.g. `usage.md:205`), but the vast majority do not. The harness can
ship before #226 lands; the `-V` examples can be temporarily skipped or run as
exit-code-only checks.

---

## 1. Documentation Surface Inventory

Sources verified by reading each file end-to-end. Code-fence counts and
representative `ltl` invocations follow.

| File | Lines | Fenced blocks (approx.) | Blocks containing `ltl` | Notes |
|------|-------|-------------------------|--------------------------|-------|
| `README.md` | 85 | 5 | 2 (one structural, one comment-only build script) | Synopsis line + build instructions only |
| `docs/usage.md` | 329 | ~14 | 13 | Canonical wiki source — the bulk of examples live here |
| `docs/purpose.md` | 87 | 0 | 0 | Pure prose; inline `-flag` references but no fenced commands |
| `docs/test-logs.md` | 215 | ~6 | 1 large block with 10 `./ltl` invocations (lines 174-201) | "Quick Test Commands" section |
| `docs/perl-performance-optimization.md` | 198 | ~8 | 0 | Perl snippets + one `nytprofhtml` block; no `ltl` invocations |
| `docs/regex-best-practices.md` | 143 | several | 0 | Perl-only |
| `docs/similarity-engine-best-practices.md` | 168 | several | 0 | Perl-only |
| `docs/staged-processing-pipeline.md` | 147 | a few | 0 | Tables + prose |
| `docs/fuzzy-consolidation-lessons-learned.md` | 182 | a few | 0 | Prose retrospective |
| `CLAUDE.md` | 192 | many | 1 structural (line 105-107) | Release-process and dev-workflow shell commands (build/git/gh) — not `ltl` examples |
| `demo-use-cases.md` | 84 | 1 | 1 (line 67-69, real invocation with file paths) | Use-case scenarios |

### Top doc to cover: `docs/usage.md`

Concrete `ltl` example blocks (file is canonical for the wiki):

- `docs/usage.md:11-15` — Files section (3 examples, two are pure glob/path forms)
- `docs/usage.md:37-44` — Time & Buckets (3 examples)
- `docs/usage.md:66-73` — Filtering (3 examples)
- `docs/usage.md:92-99` — Recording & Processing (3 examples)
- `docs/usage.md:117-124` — Message Grouping (3 examples)
- `docs/usage.md:149-158` — Display & Output (4 examples)
- `docs/usage.md:169-176` — Sorting (3 examples)
- `docs/usage.md:194-209` — Percentile mode (5 examples, one with `-V | grep`)
- `docs/usage.md:220-227` — Heatmap (3 examples)
- `docs/usage.md:242-251` — Histogram (4 examples)
- `docs/usage.md:272-279` — User-Defined Metrics (3 examples)
- `docs/usage.md:290-297` — Thread Pool Activity (3 examples)

Approximate total: **~40 distinct `ltl` invocation lines across `docs/usage.md`**.

### Other relevant blocks

- `docs/test-logs.md:174-201` — 10 `./ltl …` invocations, all referencing real
  ship-in-repo files such as `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`.
- `demo-use-cases.md:67-69` — single concrete `ltl` invocation referencing
  `./logs/GC/...` paths that may or may not exist in the repo.

---

## 2. Categorization by Executability

Bucket definitions:

- **EX (directly executable)** — log argument is a path that exists in this
  repo's `logs/` tree (or no log path is needed and stdin works).
- **PH (placeholder-substitutable)** — references generic names like
  `access.log`, `app.log`, `error.log`, `logs/*/access.log`. Needs a
  substitution policy to be runnable.
- **ST (structural)** — synopsis like `ltl [options] <logfile(s)>`. Cannot and
  should not be executed; documents grammar.
- **EXT (external dependency)** — `gh`, `docker`, `cpanm`, `brew`,
  `nytprofhtml`, `perl -d:NYTProf`. Out of scope for this harness.

| File | EX | PH | ST | EXT |
|------|----|----|----|-----|
| `README.md` | 0 | 0 | 1 (l. 21) | 4 (build/install/setup-hooks blocks) |
| `docs/usage.md` | 0 | ~36 | 2 (`l. 4`, default in synopsis sections) | 0 |
| `docs/test-logs.md` | 10 | 0 | 0 | 0 |
| `docs/perl-performance-optimization.md` | 0 | 0 | 0 | 1 (`nytprofhtml`) |
| `demo-use-cases.md` | 1 (path-dependent, see open Q) | 0 | 0 | 0 |
| `CLAUDE.md` | 0 | 0 | 1 (l. 105-107) | many |

Net: ~36 PH and ~11 EX examples are the realistic harness target. Everything in
`docs/usage.md` is PH because the canonical doc uses generic filenames
(`access.log`, `app.log`) on purpose — those names render cleanly on the wiki
and don't tie the doc to a private logs tree.

---

## 3. Placeholder Substitution Policy

`docs/usage.md` uses generic names by design. Three options:

**Option A — Implicit substitution table by filename.**
Hardcode a mapping in the harness: `access.log` → a known repo file,
`app.log` → another, etc. The mapping is invisible in the doc.

**Option B — In-doc opt-in annotation.**
Markdown comment immediately before the fence:
```
<!-- ltl-test: substitute access.log=logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log -->
```bash
ltl -i "POST" -e healthcheck access.log
```
```
Per-example control. Requires touching ~40 examples in `docs/usage.md`.

**Option C — Skip PH category entirely** and only test the ~11 EX examples in
`docs/test-logs.md` plus any new examples that are added with real paths.

### Recommendation: **Option A**, with one substitution table maintained in the
harness.

Rationale:
- The doc stays clean for end users — generic filenames are easier to read.
- The table lives in one place (`tests/validate-doc-examples.sh` or a sibling
  `.tsv`), making the policy auditable and explicit.
- Substitution candidates per MEMORY.md guidance (do NOT use
  `logs/AccessLogs/localhost_access_log.2025-03-21.txt` due to corrupt lines):
  - `access.log` → `logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log`
    (658 KB, ships in repo, clean, both duration+bytes)
  - `app.log` → `logs/ThingworxLogs/ApplicationLog.log` (5.8 MB, ships in repo)
  - `error.log` → `logs/ThingworxLogs/ErrorLog.log` (3.7 MB)
  - `logs/*/access.log` → glob substituted to the single Apache file above
  - GC paths in `demo-use-cases.md:68` — likely don't exist in repo; either
    add a fixture or mark the block as skip.

---

## 4. Stub Output Strategy

Two extremes:

**Exit-code-only.** Run the command, assert exit 0 (or expected non-zero for
help/version), discard stdout. Easy to maintain, catches gross failures (option
removed, file unreadable, regex syntax error in example), misses output drift.

**Captured-output diff.** Like `tests/validate-regression.sh` does today
(`tests/reference-output/`). Catches more, but doc examples produce variable
output (timestamps, color, terminal width). Requires per-example normalization
and regeneration discipline that gets stale fast.

### Recommendation: **exit-code-only**, with two refinements.

1. Also require `stdout` to be non-empty (catches silent no-ops where the
   example produces no rows because the substituted file doesn't contain
   matching lines).
2. For examples with embedded shell pipelines (e.g. `ltl -V access.log | grep
   -A 5 'BIN-COUNTER MODE'` at `usage.md:205`), pass-through the exit code of
   the whole pipeline (i.e. `set -o pipefail`).

This is the lowest-cost gate that catches the documentation-drift bugs we've
historically seen: renamed options, removed flags, restructured output sections
that break a `-V | grep` example. It does not catch silent output regressions —
those are already covered by `validate-regression.sh`.

---

## 5. Markdown Parsing Approach

Three styles:

**Auto-detect every fenced block.** Run anything in ` ```bash ` / ` ```shell `.
False positives: git/gh/build commands in `CLAUDE.md` and `README.md`.

**First-word filter.** Run only fences whose first non-whitespace line starts
with `ltl ` or `./ltl `. Cheap, conservative, no false positives. Misses
multi-line examples where `ltl` is on line 2+ — but a quick scan shows all
existing examples have `ltl` on the first command line of the block.

**Opt-in annotation.** ` ```bash {test} ` or HTML comment. Highest precision,
highest maintenance overhead, requires editing every existing example.

### Recommendation: **first-word filter (`ltl ` or `./ltl ` as the first
command in the fence)**.

Rationale: matches the natural pattern in `docs/usage.md` (every example block
is a series of `ltl …` lines, often with `#` comments interleaved), excludes
non-ltl fences automatically, requires no doc edits. A literal-comment escape
hatch like `# ltl-test: skip` on the line above the fence handles the
known-bad cases (the GC example in `demo-use-cases.md` referencing paths that
don't exist in the public repo).

---

## 6. Failure Semantics

A failing doc example is a **documentation bug** — the option was renamed, the
flag changed semantics, or the example was wrong from the start. CLAUDE.md's
"Sweep all user-facing doc surfaces in one pass when closing a ticket" rule
explicitly calls out `docs/usage.md`, `README.md`, `print_help()`, `CLAUDE.md`
as having to move together. This harness becomes the *automation* for that
rule. If it warns rather than fails, the rule keeps being violated quietly.

### Recommendation: **fail the build / fail the release-gate** when any doc
example fails.

Failure must include: the file path, the line number of the opening fence,
the substituted command actually executed, the exit code, and the first few
lines of stderr. That's what makes the bug fix obvious from CI output alone.

---

## 7. Wiki Sync Interaction

CLAUDE.md release step 15 clones `logtimeline.wiki`, copies `docs/usage.md` →
`Home.md` and `docs/purpose.md` → `Purpose-and-Design-Philosophy.md`, commits
and pushes. There is currently nothing between "release branch ready" and
"wiki overwritten with possibly-broken examples".

### Recommendation: **run `tests/validate-doc-examples.sh` before step 15.**

Concretely, slot it into the release process as **step 8b** (after the version
bump in step 7, immediately before the benchmark run in step 8). Failure
aborts the release. It does not belong inside the benchmark step — it's much
cheaper (seconds to minutes vs. an hour) and a different failure class.

It should also be wired into the GitHub Actions workflow used by
`.github/workflows/release-build.yml` so PRs that touch `docs/usage.md`,
`README.md`, or the `ltl` script itself are gated.

---

## 8. Application-Observability Gaps

Does `ltl` need new output to support this? Almost certainly **no**.

Exit-code-only validation needs no new ltl support. Existing examples already
emit a render to stdout, and a non-empty assertion plus a clean exit is
sufficient. A `-V doc-example` mode (deterministic output) would let us
graduate from exit-code-only to diff-based validation later, but introducing
it now is premature optimization — wait until exit-code-only proves
insufficient.

### Recommendation: **no ltl changes for the initial version of this harness.**

Revisit if the first generation of the harness exposes a class of
documentation drift that exit codes cannot detect.

---

## 9. Concrete Walk-Through: 5 Examples

Walking the harness through five real examples from the docs as a design
validation:

**Example 1 — `docs/usage.md:67-68`**
```
ltl -i "POST" -e healthcheck access.log
```
- Substitute `access.log` → `logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log`.
- Inject `--disable-progress --terminal-width 120` to suppress progress and
  stabilize layout.
- Execute: `./ltl --disable-progress --terminal-width 120 -i "POST" -e healthcheck logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log`
- Assert: exit 0, stdout non-empty.

**Example 2 — `docs/usage.md:42-43`**
```
ltl -ms -bs 100 -st "2025-05-05 08:15:00.000" -et "2025-05-05 08:20:00.000" app.log
```
- Substitute `app.log` → `logs/ThingworxLogs/ApplicationLog.log`. Time range
  may not match — the harness should treat exit 0 with zero buckets as
  acceptable (because the assertion is *the command parsed and ran*).
- Note: this is a case where exit-code-only is the right choice — the example
  is illustrative, the time-range obviously isn't tied to the substituted file.

**Example 3 — `docs/usage.md:205`**
```
ltl -V access.log | grep -A 5 'BIN-COUNTER MODE'
```
- Substitute `access.log` as above.
- Run under `bash -o pipefail`.
- Assert: pipeline exit 0. This catches the case where the `BIN-COUNTER MODE`
  section is renamed/removed by an unrelated refactor.

**Example 4 — `docs/test-logs.md:191`**
```
./ltl -n 10 logs/AccessLogs/localhost_access_log.2025-03-21.txt
```
- No substitution — direct execution.
- BUT: MEMORY.md says don't use this file for new tests. The harness should
  warn (not fail) on this and the user should update `docs/test-logs.md` to
  reference a cleaner file. Out of scope for #234 but a finding to surface.

**Example 5 — `demo-use-cases.md:68`**
```
ltl -st "2025-05-14 09:07" -et "2025-05-14 09:28" -oe -hg -hm ./logs/GC/logs-gc/gc-twx01-twx-thingworx-1.out.4 ...
```
- Paths `./logs/GC/logs-gc/*` may not ship in the repo.
- First harness pass: mark this fence with `# ltl-test: skip` until a
  decision is made about whether to add GC log fixtures.

---

## 10. ltl Code Changes Required

**None expected.** Verified by walking 5 representative examples above. The
harness drives ltl through its existing CLI surface and uses already-existing
flags (`--disable-progress`, `--terminal-width`) to stabilize output.

One follow-on observation surfaces from the walk-through: the small access
log used in `docs/test-logs.md:191` and elsewhere is flagged as corrupt in
MEMORY.md. That's a docs fix, not an ltl fix.

---

## 11. Harness Shape Proposal

Sketch only — not implementation.

**File:** `tests/validate-doc-examples.sh` (bash driver, matching the existing
`validate-*.sh` family in `tests/`).
**Helper:** `tests/extract-doc-examples.pl` (Perl extractor — same language as
ltl, no new deps).

**Driver flow:**
1. Resolve repo root from `$0` like the other validate scripts.
2. Declare the doc inventory:
   ```
   DOCS=( docs/usage.md docs/test-logs.md demo-use-cases.md README.md )
   ```
3. Declare the substitution table:
   ```
   SUBST="access.log=logs/AccessLogs/ApacheHTTP2Server-access_log-...
          app.log=logs/ThingworxLogs/ApplicationLog.log
          error.log=logs/ThingworxLogs/ErrorLog.log"
   ```
4. For each doc, invoke `extract-doc-examples.pl` to emit one JSON or TSV row
   per testable fence: `(file, opening-fence-line, command-string)`.
5. Apply substitutions and inject `--disable-progress --terminal-width 120`.
6. Honor `# ltl-test: skip` annotation on the line above the fence.
7. Execute each command under `bash -o pipefail`, redirecting stdout/stderr
   to a per-test temp file.
8. Assert exit 0 AND stdout non-empty.
9. On failure, print: doc file + line, substituted command, exit code, first
   20 lines of stderr.
10. Print a summary: `N examples, M passed, K skipped, F failed.` Exit
    non-zero if any failed.

**Extractor (`extract-doc-examples.pl`):**
- Streams the markdown line-by-line.
- Tracks fence open/close (` ``` `).
- For each fence, decide if testable: language must be `bash`/`sh`/`shell` or
  empty, and the first non-comment line must start with `ltl ` or `./ltl `.
- Honor the `# ltl-test: skip` magic comment immediately before the opening
  fence.
- Emit one TSV row per `ltl …` line inside qualifying fences.

**Run target:** Add to `tests/validate-regression.sh`-equivalent CI step, and
slot in as release-process step 8b.

---

## 12. Open Questions for Human Review

1. **Substitution policy** — confirm Option A (hardcoded table in harness)
   vs. Option B (per-example annotations in docs)? Memory comment on
   "documentation sweep discipline" might favor B because it keeps the
   per-example contract in the doc itself.

2. **`demo-use-cases.md` scope** — is this file part of the user-facing doc
   surface (it's at the repo root, not under `docs/`)? The GC paths it
   references don't appear to ship in the repo. Skip the whole file, fix it,
   or add GC fixtures?

3. **`docs/test-logs.md:191`** — the example uses
   `logs/AccessLogs/localhost_access_log.2025-03-21.txt` which MEMORY.md says
   is corrupt and should not be used for new tests. Update the doc as part
   of this work, or leave as a separate ticket?

4. **CI integration** — should the harness run on every PR that touches
   `docs/**` or `ltl`, or only as a release gate? Per-PR is safer but adds
   ~30s-1min to every PR build.

5. **`-V` examples** — `usage.md:205` invokes `-V`. If #226 (`-V` selectivity)
   changes the `BIN-COUNTER MODE` section name or output, the example breaks.
   Skip `-V` examples until #226 settles, or pin to current behavior?

---

## 13. Effort Estimate

**Overall: low.**

- Extractor (`extract-doc-examples.pl`): ~80 lines of Perl, ~2 hours.
- Driver (`validate-doc-examples.sh`): ~120 lines of bash, ~2 hours.
- Substitution table + initial pass over `docs/usage.md` (resolving each
  example to a known-good file, flagging bad ones): ~3 hours.
- CI wiring + release-process update in CLAUDE.md: ~1 hour.
- Buffer for the first round of doc fixes the harness reveals: ~2 hours.

**Timeline: 1-1.5 dev days.** Most of the time is in the substitution audit,
not the code.

---

## Related

- Umbrella issue #225 (test-harness coverage gaps)
- Weak dependency: #226 (`-V` selectivity)
- Release-process step 15 (`CLAUDE.md`) — wiki sync this harness gates
- Existing sibling harnesses: `tests/validate-regression.sh`,
  `tests/validate-help-layout.sh`, `tests/validate-histogram-ticks.sh`,
  `tests/validate-percentile-mode.sh`, `tests/validate-index-readback.sh`
