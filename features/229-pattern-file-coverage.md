# Feature Requirements: Pattern File Regression Harness (#229)

## GitHub Issues
- [#229 — Validate `patterns/` files via test harness](https://github.com/gregeva/logtimeline/issues/229) (this work)
- Parent: [#225 — Umbrella for high-priority test-harness coverage gaps]
- Depends on: [#226 — `-V` section/category selectivity]

## Overview
Today nothing in CI verifies that the regex/literal entries in `patterns/` still match
the log lines they were authored to filter. A broken entry (typo, deleted character,
moved log format) would silently filter the wrong set and produce misleading reports.
This document scopes a regression harness that asserts each `patterns/` file still
produces the expected hit count against committed fixture logs.

It is a research/scoping deliverable. No harness or production code is written here.

## 1. Pattern File Inventory

All files live in `patterns/`. Entries are loaded literally — `read_pattern_file()`
returns lines as-is (line 1906–1913 of `ltl`), and `build_filter_matcher()` then wraps
them with `quotemeta(...)` (line 2016). So every pattern is a **literal substring**,
not a regex. This shapes the harness: each line is a substring-match probe, not a
compiled regex.

| File | Lines | Purpose | Target log family |
|---|---:|---|---|
| `patterns/probes` | 2 | Health/readiness probe URLs to exclude | Tomcat access log (ThingWorx) |
| `patterns/metrics` | 3 | Metrics-scraping endpoints to exclude | Tomcat access log (ThingWorx) |
| `patterns/thingworx` | 2 | ThingWorx core service endpoints | Tomcat access log (ThingWorx) |
| `patterns/persistence-provider` | 6 (5 non-empty + trailing blank) | DB/connection-pool message substrings | ThingWorx ApplicationLog |
| `patterns/intrustion-detector` | 5 | OWASP ESAPI intrusion markers | ThingWorx ApplicationLog/ErrorLog |
| `patterns/navigate-app-calls` | 74 | Windchill Navigate API endpoints | Windchill Apache access log |

Note: `intrustion-detector` is the file's actual on-disk name (typo). The harness
should preserve the existing name; renaming is out of scope.

Also note: `persistence-provider` has a trailing blank line, exercised by the
empty-line skip at `ltl:1909`. The harness should treat the file as 6 patterns
expected, with 5 effective post-load.

## 2. Authoritative Match Examples

Verified fixture coverage via grep against `logs/`:

| Pattern file | Should-match fixture (in repo) | Most-important entry hits |
|---|---|---|
| `probes` | `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` | `/Thingworx/ready` + `/Thingworx/health` together: **11,520** |
| `metrics` | same as above | `/Thingworx/Metrics\|MetricsHC\|/metrics`: **7,059** |
| `thingworx` | same as above | `/Thingworx/Things` + `/Services/GetNamedProperties`: **881,625** |
| `persistence-provider` | `logs/ThingworxLogs/ApplicationLog.2025-05-05.0.log` | `ThingworxPersistenceProvider`: 240; `database\|connections\|Connections`: 243 total. **`c3p0` and `C3P0` hit zero in this file** — first committed file with `c3p0` is `ApplicationLog.2025-05-06.0.log`. |
| `intrustion-detector` | `logs/ThingworxLogs/ApplicationLog.2025-05-05.0.log` | `SECURITY FAILURE`, `/ExampleApplication/`: present. **`IntrusionException` only found in untracked `logs/ThingworxLogs/archives/`**. **`Anonymous\:@unknown` (literal, backslash-escape preserved by quotemeta) matches zero files** under `logs/`. |
| `navigate-app-calls` | `logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` | `…/doDirectDownload`: 6; `…/servlet/odata` (substring of many entries): 637. Most of the 74 entries have not been spot-verified — likely partial coverage. |

A should-NOT-match fixture for every file: any line from
`logs/ThingworxLogs/ScriptLog.log` (pure scripting output, none of these substrings
appear).

**Fixture gaps that must be filled before the harness is useful:**
1. `intrustion-detector` — three of five patterns have no committed fixture (one
   tracked file with `IntrusionException`; one with `Anonymous\:@unknown`).
2. `persistence-provider` — `c3p0`/`C3P0` need a tracked fixture; currently the
   05-05 ApplicationLog covers only 3 of 6 entries.
3. `navigate-app-calls` — only 3 of 74 entries have been spot-verified. Per-pattern
   mode (see §6) would require finding or synthesising lines for the rest.

## 3. Observable Surface Today

What is computed and emitted regarding filter outcomes:

| Signal | Source | Visible? |
|---|---|---|
| File-status indicator (`!` empty, `!!` error) appended to filename in command-line echo | `get_pattern_file_indicator()`, `ltl:2068`; printed at `ltl:8466–8484` | Always (echoed in the command-line block) |
| Pattern count per loaded file | `%pattern_file_status{filter_type}{file}{count}`, `ltl:1928` | Stored but **never printed** |
| Merged include/exclude/highlight regex string | Pushed to `@verbose_output` at `ltl:4295–4297` | Only under `-V` |
| Per-pattern hit counts | — | **Not computed anywhere** |
| Lines excluded / included / highlighted (running totals) | — | **Not computed anywhere** |

Filter application sites are `ltl:4991` (exclude), `ltl:4992` (include), `ltl:5030`
(highlight) — pure `match_filter()` predicates with no counter increment alongside.

So today the harness has nothing to assert against beyond "ltl exits 0 and the
overall row count in the output changes." That is too coarse for catching a single
broken pattern.

## 4. Application-Observability Gaps — Proposed `-V` Content

Depends on #226's section selectivity. New named section: **`filter-summary`**.

Proposed content for `ltl -V filter-summary -if patterns/probes <log>`:

```
=== FILTER SUMMARY ===
input_lines_read: 1234567
input_lines_filterable: 1230000        # post timestamp-parse, pre-filter
included: 11520                         # only set when -if/--include* active
excluded: 0
highlighted: 0
include_files:
  patterns/probes: status=ok loaded=2 hit_total=11520
    /Thingworx/ready: 5760
    /Thingworx/health: 5760
exclude_files: (none)
highlight_files: (none)
dead_patterns: (none)                   # patterns that loaded but hit 0 lines
```

Key contract points:
- `hit_total` is the count of *post-pattern-match* lines, not lines per OR-branch
  match (a single line that contains both substrings is counted once for the file).
- Per-pattern counters (`/Thingworx/ready: 5760`) require running each pattern as
  an independent regex during filter application, OR matching against the merged
  regex with capture groups. See §7 for the implementation trade-off.
- `dead_patterns` is the high-value catch — it surfaces entries that no longer
  match anything in the corpus.
- Section name `filter-summary` is consistent with §215/#226 lower-case kebab
  convention (matching existing `=== INDEX READ-BACK ===`, `=== BIN-COUNTER MODE
  ===`, `=== Verbose ===`).
- When `-V filter-summary` is requested but no filter is active, emit
  `filter_active: no` and nothing else.

## 5. Negative-Case Fixtures

The harness must also assert that a broken pattern file fails detectably. Concrete
corruption types per file (description only — these files are NOT created here):

| File | Corruption | Expected harness behaviour |
|---|---|---|
| `probes` | Drop the leading `/` from `/Thingworx/ready` | Per-pattern hit drops from 5760 to 0; harness flags dead pattern |
| `metrics` | Replace `/Thingworx/Metrics` with `/Thingworx/Metric` (one char short) | Hit count drops below threshold |
| `thingworx` | Delete `/Services/GetNamedProperties` entirely | File loaded with N-1 patterns; harness asserts loaded count |
| `persistence-provider` | Insert null byte at byte 0 | `read_pattern_file()` already rejects as binary (`ltl:1892`); harness asserts stderr warning + `status=error` |
| `intrustion-detector` | Mangle `Anonymous\:@unknown` to `Anonymous:@unknown` | Per-pattern hit count differs; both versions probably hit zero in the current corpus — see §2 gap |
| `navigate-app-calls` | Truncate to 0 bytes | `read_pattern_file()` flags empty (`ltl:1916`); harness asserts `!` indicator + `status=empty` |

**Strategy:** keep production `patterns/*` pristine. Place broken variants under
`tests/pattern-fixtures/corrupted/` with descriptive suffixes
(`probes.missing-slash`, `metrics.truncated`, etc.). The harness runs ltl against
each corrupted file and asserts on the expected failure mode (specific stderr
warning, specific `-V filter-summary` value, or a specific exit-code/row-count
delta versus the pristine baseline).

## 6. Per-Pattern vs Whole-File Assertions

**Whole-file** assertion: run ltl once with `-if patterns/X`, assert total included
count equals a baselined number. Cheap. Catches catastrophic damage. **Misses
single-line breakage** if other patterns in the file pick up the slack (e.g.
losing `/Thingworx/ready` looks fine if the test fixture also matches
`/Thingworx/health`, because included-total drops by only 50%).

**Per-pattern** assertion: assert each entry's hit count. Catches dead patterns
and one-line drift. Requires either (a) running ltl 6+74+... times — slow, or
(b) `filter-summary` exposing per-pattern counts.

**Recommendation:** per-pattern, single ltl run per file, using the `filter-summary`
output. The `navigate-app-calls` per-line maintenance cost is real but tolerable
because we use a *threshold* rather than an exact equality:
`hit >= 1` (alive) vs `hit == 0` (dead). For a handful of high-value entries
(`probes/*`, `metrics/*`, the top-3 thingworx entries) the harness can additionally
assert exact-equality against a baseline. Per-line exact-equality across all 74
navigate entries should be opt-in (`--strict`), not the default.

## 7. ltl Code Changes Required

- [ ] **Add `-V filter-summary` section** — depends on #226 landing first. Wire
  `filter_summary` into the section registry, gated behind `$verbose &&
  section_enabled('filter-summary')`. Effort: **low** (boilerplate once #226 is
  in).
- [ ] **Per-pattern hit counting** — does not exist today. Two implementation
  options:
  - (a) Keep the merged-regex fast path; only when `-V filter-summary` is active
    AND per-pattern detail requested, run each pattern as an independent
    `index($line, $literal) >= 0` check on lines that already matched the merged
    regex. Avoids slowing the hot path. Effort: **med**.
  - (b) Always loop per-pattern, dropping the merged-regex optimisation. Simpler
    code, measurable perf regression on large logs. **Not recommended.**
  Recommend (a).
- [ ] **Stable identifier per pattern file** — already present:
  `%pattern_file_status{filter_type}{filename}`. Reuse this hash as the
  identifier in `filter-summary` output. Effort: **none**.
- [ ] **Lines-read / lines-included / lines-excluded totals** — counters
  alongside `ltl:4991`, `ltl:4992`, `ltl:5030`. Effort: **low**.
- [ ] **Empty/error indicators reachable from `-V`** — already in
  `%pattern_file_status{...}{status}`. Effort: **none**.
- [ ] **Help text + `docs/usage.md` updates** for new `-V` section. Effort: **low**.

Total ltl-side effort: **low–med**, contingent on #226.

## 8. Harness Shape Proposal

File: `tests/validate-pattern-files.sh` (matching the existing
`tests/validate-*.sh` pattern).

Sketch — numbered steps, no bash code:

1. Define a baseline table mapping `(pattern_file, filter_type, fixture_log)` to
   expected per-pattern hit counts (alive/threshold) and total counts (exact).
2. For each pattern file in `patterns/`:
   a. Run `ltl --disable-progress -V filter-summary -<if|ef|hf> patterns/<file>
      <fixture_log>` capturing stdout.
   b. Parse the `=== FILTER SUMMARY ===` block.
   c. Assert `status=ok` and `loaded=<expected count>`.
   d. Assert per-pattern `hit > 0` for every line in the pattern file (alive).
   e. For high-value entries, assert exact `hit` equals baseline.
   f. Assert `dead_patterns: (none)`.
3. For each corrupted fixture under `tests/pattern-fixtures/corrupted/`:
   a. Run ltl with that pattern file, capturing stderr and the filter-summary.
   b. Assert the expected failure mode (specific stderr token, specific
      `status=empty|error`, or specific delta vs baseline).
4. Emit a TAP-style summary; exit non-zero on any assertion failure.
5. Reuse `tests/validate-regression.sh`'s helper conventions for
   width/locale isolation.

Out of scope for the harness itself: synthesising fixture logs (must be done
manually as part of resolving §2 gaps).

## 9. Open Questions for Human Review

1. **Fixture-gap policy.** Three pattern files have entries with no tracked
   fixture (intrusion-detector × 2, persistence-provider × 2, navigate-app-calls
   × ~71 unverified). Do we (a) commit hand-crafted fixture files specifically
   for the harness, (b) accept partial coverage and only assert on entries with
   matches, or (c) defer #229 until fixture gaps are closed?
2. **Strictness default.** Should the harness default to "alive" (hit ≥ 1) per
   entry, with exact-equality opt-in via `--strict`? Or default to strict for
   small files (`probes`, `metrics`, `thingworx`) and alive-only for
   `navigate-app-calls`?
3. **Section name and scope.** Is `filter-summary` the right name, or should
   this be folded into an existing section (e.g. extend the current `===
   Verbose ===` block in-place rather than adding a new named section)? #226
   may already prescribe a naming convention we should match.
4. **Per-pattern counting cost.** Acceptable to do the extra
   `index($line,$literal)` pass only when `-V filter-summary` is on, OR is the
   user happy to always pay it for the dead-pattern observability?
5. **Untracked archive logs.** Should `logs/ThingworxLogs/archives/` be brought
   under git (and LFS if needed) so harness fixtures are deterministic, or
   should the harness use only currently-tracked logs?

## 10. Effort Estimate

- ltl changes (assuming #226 landed): **0.5 day** — counters + section emission.
- Fixture gap resolution: **0.5–1 day** depending on how many entries need
  hand-crafted lines vs found in existing logs.
- Harness script (`validate-pattern-files.sh`): **0.5 day**.
- Negative-case fixtures and assertions: **0.5 day**.

**Overall: medium effort, ~2–3 days of focused work, blocked on #226.**
