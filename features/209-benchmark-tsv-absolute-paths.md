# Issue #209 — Portable file paths in recorded test-harness output

Branch: `209-benchmark-tsv-absolute-paths` (off `release/0.17.0`)

## Scope

Two committed test artifacts recorded the absolute paths of the machine that
produced them, tying them to a single checkout:

- `tests/baseline/results/*.tsv` — the `FILES` rows of the benchmark TSV.
- `tests/reference-output/*.txt` — the rendered file legend in 8 of the 46
  regression references.

Both are addressed here. The contract adopted is that **`ltl` records input
paths exactly as the caller supplied them**, and the harnesses supply
repo-relative paths from the repo root — so a recorded path reads as if the
current working directory were the repo root.

Not in scope: rewriting the historical baselines (`v0.14.x`–`v0.16.0`), which
stand as captures of what was measured at the time.

## Findings

### F1. There is no single root cause — the two surfaces are independent bugs

The issue thread (2026-08-21 scope note) states that `ltl` "absolutizes input
file paths and renders them in the file legend", making the benchmark TSV and
the regression legend two surfaces of one root cause. **This is incorrect**,
and it matters because it implies the `ltl` fix resolves both.

`abs_path()` had exactly one caller in `ltl`: the `FILES` row of the
`benchmark-data` `-V` section (`print_verbose_output`). The file legend
(`print_summary_table`, the `foreach my $in_file (@files_processed)` loop that
emits `[%s] %-${filename_max_length}s`) has never called it — it renders
`@files_processed`, which holds whatever the caller passed.

So the absolute paths in the regression references came from
`capture-regression.sh` itself, which built its log paths as
`"$REPO_DIR/logs/..."`. The two bugs share a symptom, not a cause:

| Surface | Absolutized by | Needs `ltl` change |
|---|---|---|
| Benchmark TSV `FILES` row | `ltl` (`abs_path`) | Yes |
| Regression file legend | `capture-regression.sh` (`$REPO_DIR/...`) | No |

Consequence: the legend half is a pure harness fix. Only the TSV half required
touching production code.

### F2. Only the 8 `hl-*` references carry a path

`COMMON` (38 scenarios) passes `-osum`, which suppresses the summary table and
with it the file legend. `HL_COMMON` (the 8 numeric-highlight scenarios from
#312) deliberately omits `-osum` so the HIGHLIGHTED row is part of the captured
surface — and the legend comes with it. `grep -l` for the absolute path across
`tests/reference-output/` returns those 8 and nothing else.

`ACCESS_LOG` is a `mktemp` path that varies per run, but it appears only in
`-osum` scenarios, so it never reaches a captured legend.

### F3. The rebaseline changes more than the path text

`shorten_filename()` truncates to a computed width, so the two forms differ in
rendering, not just content — the absolute form is elided in the middle, the
relative form fits whole and is padded:

```
-  4xx    4   [√] /Users/gregeva/Documents/GitHub/logtimeline/logs...rver-access_log-Windchill_Navigate.2026-01-25.log [1]
+  4xx    4   [√] logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log                       [1]
```

A rebaseline was therefore required, not a search-and-replace of the path
string.

### F4. `-V` is the extraction surface for path assertions, not the legend

Reading paths out of the rendered summary block is unsound: the legend is
ANSI-coloured, contains non-ASCII (`√`, which silently flips `grep` to binary
mode), is column-padded, and is truncated by `shorten_filename()` — it can only
ever confirm the first and last ~50 characters of a path.

`-V format-detection` emits the untruncated value as a plain key:

```
file: logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log
```

Verification of this fix asserts on `-V benchmark-data`'s `FILES` row and
`-V format-detection`'s `file:` key. `file:` (`format-detection`) and
`drift_file:` (`index-read-back`) already echoed the caller's path verbatim and
inherit the fix with no change.

## Fix

1. **`ltl`** — `FILES` emits `join(';', @files_processed)`; `abs_path()` and its
   sole-purpose `use Cwd` import removed.
2. **`tests/baseline/run-benchmark.sh`** — `cd "$REPO_DIR"`, `LOGS_DIR="logs"`.
   `$LTL`/`$RESULTS_DIR` stay absolute and are unaffected by the `cd`; neither
   is recorded in output.
3. **`tests/capture-regression.sh`** / **`tests/validate-regression.sh`** —
   `cd "$REPO_DIR"` and repo-relative log vars, applied in lockstep so captured
   and validated invocations match. The "known acceptable failure" header note
   in `validate-regression.sh` is removed: any diff is now a regression.
4. **`tests/reference-output/`** — the 8 `hl-*` references rebaselined.

## Contract

`ltl` reports the paths it was given. It has no notion of a repo root, and
acquiring one would be wrong for a tool whose users analyse logs anywhere on
disk. Portability of recorded output is therefore the caller's responsibility:
harnesses that commit their output run from the repo root and pass
repo-relative paths.

Any harness added later whose captured output includes a file path — the
rendered legend, a `FILES` row, or a `-V` `file:` key — follows the same rule.

## Verification

| Check | Result |
|---|---|
| `FILES` row, relative path in | `logs/AccessLogs/...` |
| `FILES` row, absolute path in | absolute preserved (caller's choice) |
| Benchmark TSV from repo root | `logs/AccessLogs/...` |
| Benchmark TSV invoked from `/tmp` | identical — CWD-independent |
| Rebaseline scope | exactly the 8 predicted files; all 18 changed lines are legend lines |
| `validate-regression.sh` from repo root | 46 passed, 0 failed |
| `validate-regression.sh` from `/tmp` | 46 passed, 0 failed |

The suite was run from a worktree whose path differs from the checkout where
the references were originally captured, so portability is demonstrated across
both a foreign CWD and a foreign checkout.

Completion gate: all 23 `tests/validate-*.sh` exit 0 with assertions confirmed
executed; `validate-statistics.sh` reports 0 T3/T4 on all three layers.
Benchmark `single-day-access-log-standard` against `v0.16.0` shows no metric
worse by more than 5% (sole `REGRESS` is +0.2% on a rollup of items below the
noise floor).
