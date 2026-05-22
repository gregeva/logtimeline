# Feature: Extended heatmap/histogram rendering coverage in validate-regression.sh (#235)

## Overview

This research deliverable scopes the work for issue **#235** — extending
`tests/validate-regression.sh` with heatmap and histogram fixture combinations
that the current regression harness does not exercise. #235 is a sub-task of
**#225** (umbrella for high-priority test-harness coverage gaps).

The harness in question uses byte-identical rendered-output diff against
fixture files under `tests/reference-output/`. It is **independent of #226**
(which is about `-V` selectivity); no `-V` assertions are involved here.

## GitHub Issue

[#235](https://github.com/gregeva/logtimeline/issues/235) (parent: #225)

---

## 1. Existing coverage audit

Read from `tests/validate-regression.sh` and `tests/capture-regression.sh`
(both files mirror each other line-for-line in `run_test` invocations).

`COMMON = --disable-progress -osum -n 1` is applied to every test below.

### Access-log baseline (`tests/validate-regression.sh:69-74`)

| Fixture | ltl options | Intent |
|---|---|---|
| `access-w80` | `--terminal-width 80 -os -od -ov` | Narrow width with manual column hides; baseline for narrow access-log render |
| `access-w120` | `--terminal-width 120` | Mid-width access-log layout |
| `access-w160` | `--terminal-width 160` | Standard-width access-log layout |
| `access-w200` | `--terminal-width 200` | Wide access-log layout |

### ScriptLog baseline (`validate-regression.sh:77-81`)

| Fixture | ltl options | Intent |
|---|---|---|
| `scriptlog-w100` | `--terminal-width 100 -os -ov` | Narrow ScriptLog with manual column hides |
| `scriptlog-w160` | `--terminal-width 160` | Standard ScriptLog layout |
| `scriptlog-w200` | `--terminal-width 200` | Wide ScriptLog layout |

### Heatmap (`validate-regression.sh:83-92`)

| Fixture | ltl options | Intent |
|---|---|---|
| `heatmap-duration-w160` | `--exact-percentiles --terminal-width 160 -hm duration` | Duration heatmap palette + cell rendering |
| `heatmap-bytes-w160` | `--exact-percentiles --terminal-width 160 -hm bytes` | Bytes palette |
| `heatmap-count-w160` | `--exact-percentiles --terminal-width 160 -hm count` | Count palette |

### Omit-flag column suppression (`validate-regression.sh:94-98`)

| Fixture | ltl options | Intent |
|---|---|---|
| `omit-ov-w160` | `--terminal-width 160 -ov` | Hide overall column |
| `omit-or-w160` | `--terminal-width 160 -or` | Hide rate column |
| `omit-os-w160` | `--terminal-width 160 -os` | Hide stats column |
| `omit-ov-or-w160` | `--terminal-width 160 -ov -or` | Hide overall + rate together |

### Auto-hide / no-auto-hide (`validate-regression.sh:100-104`, issue #73)

| Fixture | ltl options | Intent |
|---|---|---|
| `autohide-w80` | `--terminal-width 80` | Auto-hide engaged on access log at 80 |
| `autohide-w100` | `--terminal-width 100` | Auto-hide engaged at 100 |
| `noautohide-w80` | `--terminal-width 80 --no-auto-hide` | Force-off comparison at 80 |
| `autohide-hm-w120` | `--exact-percentiles --terminal-width 120 -hm duration` | Heatmap + auto-hide interaction at 120 |

### Millisecond precision (`validate-regression.sh:106-107`)

| Fixture | ltl options | Intent |
|---|---|---|
| `ms-w160` | `--terminal-width 160 -ms -bs 1000 -st 00:00 -et 00:05` | ms bucket scale + time-range filter |

**Total existing fixtures: 19.** Histogram coverage in this harness is zero;
histograms are exercised only by `tests/validate-histogram-ticks.sh` which is
a separate semantic-assertion harness (tick-vs-legend invariants), not a
byte-identical diff harness, and operates exclusively against the corrupt
`localhost_access_log.2025-03-21.txt`.

---

## 2. Combination space enumeration

Read from `ltl --help` and the source dispatch at `ltl:5630-5635`,
`ltl:4154-4158`, `ltl:251-252`.

| Axis | Values | Notes |
|---|---|---|
| Heatmap metric (`-hm`) | `duration`, `bytes`, `count` | 3 modes, each maps to its own palette (yellow/green/cyan per `features/heatmap.md`) |
| Heatmap width (`-hmw`) | int >= ~10, default 52 | Affects cell count; rendering-layer parameter |
| Terminal width (`--terminal-width`) | 80, 100, 120, 160, 200 (project convention) | Drives auto-hide cascade |
| Light background (`-lbg`) | flag (on/off) | Switches gradient direction; `$heatmap_light_bg` at `ltl:251` |
| Histogram metric (`-hg`) | `duration`, `bytes`, `count` (+ UDM names) | Single or comma-list |
| Multi-histogram (`-hg a,b[,c]`) | combos of the above | Independent panels stacked |
| Histogram width (`-hgw`) | percent of terminal, default 95 | Layout |
| Histogram height (`-hgh`) | rows, default 8, min 3 | Layout |
| Histogram bpd (`-hgbpd`) | default 8 | Bin precision (covered elsewhere by `validate-percentile-mode.sh`) |
| `--exact-percentiles` | flag | Forces sort-based percentile path; required for stability — see §5 |

Full combinatorial expansion is on the order of 3 (metric) × 5 (term-width) ×
2 (`-lbg`) × 3 (`-hmw` representatives) × 3 (histogram metric) × 4 (multi
combos) × 3 (`-hgw` representatives) ≈ 1500+. Most of that is redundant; see §3.

---

## 3. Reduction to equivalence classes

Independent code paths that must each be represented at least once:

1. **Heatmap cell renderer × terminal width**. Auto-hide rebalances columns
   around the heatmap strip. Representative narrow values are 80, 100, 120.
   One metric (duration) is sufficient — the palette differs, but the cell
   layout / autohide interaction is identical across metrics.
2. **Heatmap palette per metric**. duration / bytes / count each select a
   different gradient (`features/heatmap.md`). Width 160 already covers this
   trio. No need to fan it out across every width.
3. **`-hmw` custom width**. Two representative values bracketing the default
   (52): a small one (30) and a large one (80). Single metric, single width.
4. **`-lbg` light background**. Switches the colour table; rendering path is
   identical. One representative heatmap fixture covers it. ANSI is stripped
   by `strip_nondeterministic`, so colour codes do **not** survive into the
   fixture — but the *character set* (block density indicators) does change
   between dark and light palettes in some bands, so the fixture is still
   meaningful. (Worth verifying experimentally during capture; if the
   stripped output is byte-identical to the non-`-lbg` baseline, drop the
   `-lbg` fixture and file the observation.)
5. **Histogram single-metric × terminal width**. The histogram is rendered
   by a path distinct from the heatmap. Cover three widths: 80 (narrow,
   tests histogram suppression / squeeze), 120 (mid), 160 (standard).
   Duration is the natural single-metric representative.
6. **Histogram per metric**. bytes and count exercise different axis
   formatters (KiB/MiB labels, integer labels). One fixture each, at 160.
7. **Multi-histogram (`-hg duration,bytes` and `duration,bytes,count`)**.
   Stacked-panel layout. Two fixtures cover (a) two-panel and (b) three-panel
   stacking.
8. **`-hgw` custom width**. Two representative values: 50 (squeeze) and 30
   (very narrow histogram inside wide terminal).
9. **`-hgh` custom height**. One representative (e.g. 4 rows).
10. **Heatmap + histogram together** is a follow-on combination; the bar
    graph + heatmap row + histogram strip composition is a distinct render
    path. One fixture at width 160.

Combining classes intelligently: 17 new fixtures (§4). Sub-25, well above the
~3 we have today.

---

## 4. Proposed fixture list

All heatmap fixtures use `--exact-percentiles` (see §5). Heatmap fixtures use
`ScriptLog-DPMExtended-clean.log` (the canonical "all three metrics" file per
`docs/test-logs.md`). Access-log scenarios use the
`ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` (microsecond
durations, clean fixture). All command lines include `$COMMON`
(= `--disable-progress -osum -n 1`).

| # | Fixture name | ltl options (after `$COMMON`) | Log | Covers / why not redundant |
|---|---|---|---|---|
| 1 | `heatmap-duration-w80` | `--exact-percentiles --terminal-width 80 -hm duration` | ScriptLog-DPMExtended-clean | Heatmap cell layout at narrowest auto-hide tier; complements existing w120/w160 |
| 2 | `heatmap-duration-w100` | `--exact-percentiles --terminal-width 100 -hm duration` | ScriptLog-DPMExtended-clean | Mid-narrow rung between 80 and 120 |
| 3 | `heatmap-bytes-w120` | `--exact-percentiles --terminal-width 120 -hm bytes` | ScriptLog-DPMExtended-clean | Bytes palette at non-default width (existing w160 only covers w160) |
| 4 | `heatmap-count-w100` | `--exact-percentiles --terminal-width 100 -hm count` | ScriptLog-DPMExtended-clean | Count palette under autohide; ensures count path doesn't render differently than duration at narrow width |
| 5 | `heatmap-lbg-duration-w160` | `--exact-percentiles --light-background --terminal-width 160 -hm duration` | ScriptLog-DPMExtended-clean | Light-background gradient code path (`$heatmap_light_bg`, `ltl:251`) |
| 6 | `heatmap-hmw30-duration-w160` | `--exact-percentiles --terminal-width 160 -hm duration -hmw 30` | ScriptLog-DPMExtended-clean | Custom heatmap width below default 52 |
| 7 | `heatmap-hmw80-duration-w160` | `--exact-percentiles --terminal-width 160 -hm duration -hmw 80` | ScriptLog-DPMExtended-clean | Custom heatmap width above default 52 |
| 8 | `hg-duration-w80` | `--exact-percentiles --terminal-width 80 -hg duration` | ApacheHTTP2 | Histogram panel at narrow width (suppression / squeeze behaviour) |
| 9 | `hg-duration-w120` | `--exact-percentiles --terminal-width 120 -hg duration` | ApacheHTTP2 | Histogram at mid width |
| 10 | `hg-duration-w160` | `--exact-percentiles --terminal-width 160 -hg duration` | ApacheHTTP2 | Histogram at standard width |
| 11 | `hg-bytes-w160` | `--exact-percentiles --terminal-width 160 -hg bytes` | ApacheHTTP2 | Bytes axis formatter (KiB/MiB labels) |
| 12 | `hg-count-w160` | `--exact-percentiles --terminal-width 160 -hg count` | ScriptLog-DPMExtended-clean | Count axis formatter |
| 13 | `hg-multi-duration-bytes-w160` | `--exact-percentiles --terminal-width 160 -hg duration,bytes` | ApacheHTTP2 | Two-panel stacked histogram |
| 14 | `hg-multi-all-w160` | `--exact-percentiles --terminal-width 160 -hg duration,bytes,count` | ScriptLog-DPMExtended-clean | Three-panel stacked histogram |
| 15 | `hg-hgw30-duration-w160` | `--exact-percentiles --terminal-width 160 -hg duration -hgw 30` | ApacheHTTP2 | Custom histogram width (much narrower than default 95%) |
| 16 | `hg-hgw50-multi-w160` | `--exact-percentiles --terminal-width 160 -hg duration,bytes -hgw 50` | ApacheHTTP2 | Custom histogram width combined with multi-metric |
| 17 | `hg-hgh4-duration-w160` | `--exact-percentiles --terminal-width 160 -hg duration -hgh 4` | ApacheHTTP2 | Custom histogram height (4 rows; default is 8, min is 3 — `ltl:4231-4233`) |
| 18 | `heatmap-hg-duration-w160` | `--exact-percentiles --terminal-width 160 -hm duration -hg duration` | ScriptLog-DPMExtended-clean | Heatmap + histogram in the same invocation (composition test) |

**18 new fixtures**, bringing the harness from 19 → 37 fixtures. Within the
"~15-25 fixtures" target.

---

## 5. `--exact-percentiles` policy for new fixtures

`validate-regression.sh:84-92` documents the policy for heatmap fixtures:
pin to the sort-based percentile path so the reference stays byte-stable
while precision work (#34/#187/#201) lands. The unified bin-counter path is
approximate within bin-resolution bound — fine for production, fragile for
byte-identical diffs.

**Histograms go through the same dispatch.** `calculate_histogram_buckets()`
at `ltl:5630-5635`:

```
return $exact_percentiles_optout
    ? calculate_histogram_buckets_exact()
    : finalize_histogram_unified();
```

Same opt-out flag, same two-path structure. The histogram's percentile
indicators (P50/P95/P99/P99.9 displayed on the histogram x-axis) and the
bin counts themselves both shift between paths.

**Recommendation: every new heatmap *and* histogram fixture uses
`--exact-percentiles`.** This is consistent with the existing heatmap policy
and avoids fixture churn when bin-counter precision is tuned.

A future audit (separate issue) should re-capture all fixtures without
`--exact-percentiles` once the unified path is locked, and migrate the
harness off the deprecated flag.

---

## 6. Test log selection per fixture

Constraint from `MEMORY.md` / `feedback_test_logs.md`: **do not use
`logs/AccessLogs/localhost_access_log.2025-03-21.txt`** for new tests (corrupt
lines). The existing harness uses it; new fixtures must not.

Candidate logs from `docs/test-logs.md`:

- **ScriptLog-DPMExtended-clean.log** (29 MB, ThingWorx CustomThingworxLogs):
  "ideal for all heatmap types", carries duration, bytes, and count metrics.
  Used for all heatmap fixtures and for histogram-count and three-panel
  histogram fixtures.
- **ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log** (658 KB,
  Apache HTTP2, microsecond `%D` durations): clean Apache combined-log format
  with duration + bytes. Used for access-log-flavoured histogram fixtures.

Per-fixture assignment is in the §4 table. Two log files cover all 18
fixtures.

These two log files must be added as new variables to both
`capture-regression.sh` and `validate-regression.sh` (see §8).

---

## 7. strip_nondeterministic considerations

Current `strip_nondeterministic` (`validate-regression.sh:24-27`,
`capture-regression.sh:35-38`):

```
perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g; s/\e\[\d*m//g;
          s/log timeline \[[0-9.]+\]/log timeline [VERSION]/'
| perl -ne 'BEGIN{$skip=0} $skip=1 if /TOP OVERALL/;
            print unless $skip
                     || /PROCESSING TIME|TOTAL TIME|MAXIMUM MEMORY
                        |INITIALIZE EMPTY|CALCULATE STATISTICS|SCALE DATA/i'
```

Coverage today: ANSI escapes, version banner, top-overall section, timing
and memory lines.

**Non-determinism risk audit for new fixtures:**

- **Heatmap header**: contains palette name only, no run-time data.
  Deterministic.
- **Histogram percentile values**: under `--exact-percentiles`, derived from
  sorted raw arrays — deterministic for a given log file.
- **Histogram axis labels**: derived from data min/max + log-scale boundaries
  — deterministic.
- **`-lbg` mode**: ANSI colour codes differ but get stripped; the *character
  set* (block density characters) may differ. Both outcomes are
  deterministic.
- **Auto-detect**: `$heatmap_light_bg_auto` defaults to 1 (`ltl:252`) but is
  skipped on Windows and gated through a terminal-query path at
  `ltl:4212`. **Risk**: a TTY-attached run might detect a light background
  on one developer's terminal and not on another's, perturbing the fixture.
  Capture is via shell redirection (not a TTY) so the auto-detect path
  should be inert, but this should be confirmed empirically when capturing
  the `-lbg` fixture and the non-`-lbg` heatmap fixtures, and a
  `NO_COLOR=1`-style environment override considered if any drift is
  observed.

**Conclusion**: no new strip patterns are required for fixture stability.
File one observation for the implementer: re-run each new fixture twice
on capture and diff before committing, to confirm idempotency. If any
fixture proves non-deterministic, extend `strip_nondeterministic` then —
not pre-emptively.

---

## 8. Capture script extension

`tests/capture-regression.sh` is the mirror of `validate-regression.sh`.
Both files need the same set of `run_test` calls; both files need the same
two new log-file variables.

Minimum diff to each script:

1. Two new variables alongside `ACCESS_LOG` / `SCRIPT_LOG`
   (`capture-regression.sh:23-24`):
   ```
   APACHE_LOG="$REPO_DIR/logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log"
   DPM_LOG="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log"
   ```
   (Note: `SCRIPT_LOG` already points at this same DPM file by path. Either
   reuse `SCRIPT_LOG` or rename. Recommend renaming to `DPM_LOG` in both
   scripts for clarity, since existing heatmap fixtures already use it.)
2. Add the file-existence check for `APACHE_LOG` in
   `capture-regression.sh:27-32`.
3. Append 18 new `run_test` lines (grouped by section: new heatmap, new
   histogram, composition) to both scripts in lockstep.

No structural changes. No new helper functions. No changes to
`strip_nondeterministic`.

---

## 9. Application-observability gaps

This harness is rendering-output diff, so observability gaps are minor.
However, when a fixture diff fails in CI the implementer will want to
inspect:

- Which heatmap bin a cell landed in (currently visible only via colour, and
  colour is stripped from the fixture).
- Which histogram percentile maps to which axis column (currently visible
  only via the legend and the tick character).
- For multi-histogram, whether the panel ordering is stable across runs
  (it should be: insertion order into `@histogram_udm_configs` is
  deterministic).

**Recommended (not required for #235)**: extend the `-V` output with a
"render snapshot" block exposing heatmap-cell `(bucket,bin)` indices and
histogram `(metric, column→percentile)` mapping. This belongs in #226's
selectivity work, not here. File as a follow-on.

---

## 10. ltl code changes required

**None.** Every option in §4 is shipped today. The work is harness +
fixtures only.

---

## 11. Implementation steps proposal

1. Rename `SCRIPT_LOG` to `DPM_LOG` and add `APACHE_LOG` variable in
   `tests/validate-regression.sh` and `tests/capture-regression.sh`
   (existing references move with the rename).
2. Add 18 new `run_test` invocations (§4) to both scripts, grouped under
   new section comments (`# --- Heatmap at narrow widths ---`,
   `# --- Light-background heatmap ---`, `# --- Custom heatmap width ---`,
   `# --- Histogram single-metric ---`, `# --- Multi-histogram ---`,
   `# --- Custom histogram dimensions ---`, `# --- Composition ---`).
3. Run `./tests/capture-regression.sh` to generate the 18 new fixture files.
4. Visually inspect each new fixture for sanity (rendering looks correct,
   no obvious truncation, percentile lines present, etc.). This is the
   load-bearing manual step.
5. Run `./tests/capture-regression.sh` a second time; `diff -r` the two
   output directories to confirm idempotency. Investigate any
   non-deterministic differences.
6. Run `./tests/validate-regression.sh` and confirm 37/37 pass
   (self-consistency check).
7. Commit harness changes and fixtures together in one commit so the
   harness and reference stay in sync.

---

## 12. Open questions for human review

1. **`-lbg` capture environment.** Auto-detect may or may not engage when
   stdout is piped to `strip_nondeterministic` (`ltl:4212`, `ltl:2305-2307`).
   Should the capture script export `NO_COLOR=1` or similar to lock the
   environment, or rely on the non-TTY pipe to disable auto-detect? Needs
   a one-line empirical test.
2. **Histogram with `-hgw` smaller than terminal histogram-suppression
   threshold.** At `--terminal-width 80 -hgw 30` the histogram width is 24
   columns; does ltl suppress the histogram at that width, render it
   truncated, or render a tiny panel? Verify before committing fixture #15
   (alternative: drop fixture #15 if the panel is suppressed and the
   fixture would only test a "no panel" code path that's covered
   elsewhere).
3. **Whether to migrate the existing harness off
   `localhost_access_log.2025-03-21.txt`.** The existing 19 fixtures all
   use the corrupt file. New fixtures will not. Inconsistency is a smell;
   a separate ticket should migrate the existing fixtures too, or this
   research should expand to include re-capturing them on a clean log.
4. **Fixture-name convention for combined heatmap+histogram.** Proposed
   `heatmap-hg-duration-w160` (§4 row 18). Alternatives include
   `combo-duration-w160` or `hm-hg-duration-w160`. Confirm or amend.
5. **Whether to add a `-hgh` low-height fixture only, or also a high-height
   (e.g. 16 rows) one.** §4 has only one `-hgh` fixture. If layout drift is
   asymmetric between shrinking and growing the histogram, two are needed.

---

## 13. Effort estimate

**Overall: low-medium.**

| Activity | Estimate |
|---|---|
| Edit `validate-regression.sh` + `capture-regression.sh` (18 lines each, plus rename) | 30 min |
| Run capture, produce 18 fixture files | 5 min wall-clock |
| Visual review of each fixture | 60–90 min (this is the bulk of the work) |
| Idempotency re-capture + diff | 10 min |
| Investigate `-lbg` env determinism + open-question resolutions | 30 min |
| Commit + push | 5 min |

**Total**: half a day of focused effort, dominated by the visual review of
fixtures. No new code, no tricky refactors, no test-of-test infrastructure.
The work is mechanical; the cognitive load is the sanity-check pass.
