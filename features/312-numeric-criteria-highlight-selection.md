# Numeric Criteria as Highlight/Selection (Issue #312)

## Status
- **Issue**: #312
- **Branch**: `312-numeric-criteria-highlight-selection`
- **Target release**: v0.16.0
- **Phase**: Implemented on the feature branch — all harnesses green, manual verification complete; not yet merged

## Overview

Today the numeric threshold options (`-dmin`/`-dmax`, `-bmin`/`-bmax`, `-cmin`/`-cmax`) only hard-filter: records outside the range are dropped from the analysis entirely. This feature adds a parallel set of *highlight* options that keep the full population in view while visually selecting the subset matching numeric criteria — the same treatment the regex highlight (`-h`/`-hf`) provides for text matches. A pattern within the broader population can then be observed in context rather than by filtering everything else out.

## Requirements

1. Highlight (not drop) records whose duration, bytes, or count values fall inside a user-given inclusive range.
2. Every output surface that renders the regex-highlight subset must render the numeric-highlight subset identically: occurrences legend, proportional bar prefix, summary `HIGHLIGHTED` row, TOP HIGHLIGHTED MESSAGES block, histogram overlay, heatmap overlay.
3. Numeric highlight must compose with the existing hard filters (e.g. trim noise with `-dmin 100` while highlighting the slow tail with `-hdmin 1000` in one run).
4. Numeric highlight must compose with the regex highlight (see decisions).
5. Runs without numeric highlight options must pay essentially zero additional per-line cost.
6. The per-file highlight indicator in the file legend must reflect numeric-only highlight matches identically to regex matches, so the reader can tell whether highlighted results came from one file or all.

## Decisions (locked 2026-07-06, user-approved)

| Decision | Outcome | Rationale |
|----------|---------|-----------|
| Option surface | Six h-prefixed mirrors: `-hdmin/--highlight-duration-min`, `-hdmax/--highlight-duration-max`, `-hbmin/--highlight-bytes-min`, `-hbmax/--highlight-bytes-max`, `-hcmin/--highlight-count-min`, `-hcmax/--highlight-count-max` (all integer-typed, matching the filter options) | Mirrors the existing filter naming 1:1; fully composable with the hard filters in one run; requires no index-cache signature changes (highlight options are not filters, same as `-h` today) |
| Within-metric semantics | Inclusive min AND max band — `min <= value <= max`. No "outside/outlier" mode. | Matches how filtering works today; range-exclusion was considered and rejected as an unproven need |
| Across metrics | AND — each given criterion is an independent constraint that must all pass | Mirrors how the hard numeric filters compose |
| Regex highlight × numeric | AND (intersection): a record is highlighted iff the text matcher matches (any of its OR'd patterns/file lines) AND all numeric criteria are satisfied. Either family alone decides when the other is absent. | Cross-family *filters* already compose with AND (`-i "api" -dmin 100`); enables "requests to endpoint X slower than 1s", which regex alone cannot express |
| Undefined metric | A record missing the metric never satisfies a criterion on it — renders plain | Highlight analog of the existing filter behavior (records with undefined metrics are dropped when the corresponding filter is set) |
| Boundary normalization (in scope) | `-dmin`/`-dmax` change from boundary-exclusive to **inclusive**, matching `-bmin`/`-bmax`/`-cmin`/`-cmax`. All six filters and all six highlight options use the closed-interval convention: kept/highlighted iff `defined(metric) && metric >= MIN && metric <= MAX` (each bound only when given). | Pre-existing inconsistency; fixing it here keeps filter and highlight semantics identical. Behavior change to `-dmin`/`-dmax` (records exactly at the threshold are now kept) — requires its own release-note bullet. |
| CSV exposure of highlight | Out of scope | No highlight representation exists in the STATS CSV today; adding one is a new surface — proposed as a follow-up issue. Distinct from the MESSAGES CSV `category` column (`plain`/`highlight`), which already exists, is populated automatically through the tag point, and serves as the primary test substrate (see Test strategy) |
| Inverted range (`min > max`, both bounds given) | Out of scope here — #322 (inverted numeric range, silent empty output) is extended to cover all twelve range options: the six filters and these six highlight options, warning that the range is unsatisfiable | One implementation addresses the whole inverted-range problem at once; #322 carries the scope note |
| Per-file highlight indicator | In scope: a numeric-only highlight match sets the per-file highlighted state at the tag point (`$in_files_matched{$in_file} = 2`), so the file legend marks which files contained highlighted lines | The indicator answers "where did the highlighted results come from" and must not silently depend on a regex being present |

## Design

### Core mechanism

All rendering machinery for "highlighted subset within a bucket" already exists and keys off two things set at a single tag point in `read_and_process_logs` (the `-HL` suffix on `$category_bucket`, and `$category = 'highlight'`). The feature is a numeric predicate evaluated at that tag point, combined per the AND decision with the existing `match_filter()` text result. Everything downstream flows automatically: `%log_occurrences` `-HL` keys, `%log_analysis` `-HL` sums, scaled bar prefixes, `%log_messages{'highlight'}`, histogram `*_hl` structures, heatmap `*_hl` structures.

- New globals beside the filter variables: `$highlight_duration_min/max`, `$highlight_bytes_min/max`, `$highlight_count_min/max`, plus a precomputed `$numeric_highlight_active` boolean and a unified `$highlight_active` (regex OR numeric active), resolved in `adapt_to_command_line_options` after `build_filter_matcher`.
- Six new `GetOptions` entries beside the filter options, `=i` typed.
- Boundary normalization: the duration filter comparisons flip from `<=`/`>=` to `<`/`>` in the hard-drop guards, making them identical to bytes/count.
- Hot-loop discipline: the numeric predicate is evaluated only when `$numeric_highlight_active`; runs without these options pay one falsy check per line.
- The restructured tag-point condition must keep the per-file highlight state update (`$in_files_matched{$in_file} = 2`, feeding the file-legend indicator) inside the unified highlight branch, so numeric-only matches mark their file identically to regex matches.

### The `defined $highlight_regex` gate sweep

Several render surfaces gate on `defined $highlight_regex` and would silently skip numeric-only highlighting. Each must switch to the unified `$highlight_active`. Sites found during planning (line numbers approximate as of v0.15.1; re-grep `highlight_regex` at implementation time — this is the primary correctness risk):

- Histogram HL percentile stats (~ltl:8885) and bin-counter HL projection (~ltl:9036)
- Heatmap HL cell render (~ltl:10733, ~10752)
- Histogram HL display buckets (~ltl:11360)
- Summary table `HIGHLIGHTED` row (~ltl:12065)
- The `-V runtime-config` "highlight (merged)" line (~ltl:1673) stays regex-only — correct as-is
- Message-summary header text "TOP HIGHLIGHTED MESSAGES (highlighted based on RegEx pattern match)" (~ltl:12190) — reword to cover numeric criteria (user-facing text, no internals)

### Index cache

No signature change: `has_active_filters()` and `serialize_filters()` are untouched — highlight options do not alter the selected population, exactly like `-h` today. The boundary fix, however, changes which records a committed `-dmin` selection matches: `tests/fixtures/ltl-index-readback.csv` carries `-dmin` selection rows and must be regenerated via `tests/fixtures/regenerate-index-readback-fixtures.sh`.

### `-V runtime-config`

The six new options join the resolved-values registry. This modifies a `-V` section's content keys: **read `tests/HARNESS-DESIGN.md` first**, `grep -r runtime-config tests/` for consumers, and update all consumers in the same commit.

### TODO hygiene

Script-header TODO sketching this feature (`-hdmin` idea, ~ltl:17) is resolved and removed. The separate highlight-counters TODO (~ltl:15) remains open and untouched.

## Documentation sweep (same effort; help and docs/usage.md in the same commit per CLAUDE.md alignment rule)

- `print_help()`: six new entries in the Filtering subsection; inclusive-bounds wording on the six existing filter entries; extend the "filters affect all computed statistics" note to state that highlight criteria do NOT alter the population — they only partition it.
- `docs/usage.md`: Filtering prose and options table (~:51-80); a runnable example (doc examples are executed by `validate-doc-examples.sh`).
- `README.md`: filtering prose only if wording implies highlight is regex-only.
- `--explain` histogram/heatmap texts referencing "Highlight overlays (`-h regex`)" and their mirrors in `docs/explain/histogram.md` — widen to cover numeric criteria.
- `docs/usage.md` UDM-counting paragraph (~:355, added by #313): "Highlighting (`-h`) works as it does for the sessions column…" — widen to cover numeric criteria.
- `releases/v0.16.0.md`: one bullet for the feature, one for the `-dmin`/`-dmax` boundary change.

## Test strategy (placement decided 2026-07-08 after a full HARNESS-DESIGN.md read)

- **Read `tests/HARNESS-DESIGN.md` before touching or creating any harness** (mandatory trigger).
- **Data-partition coverage (primary) — `validate-csv-output.sh`.** The MESSAGES CSV `category` column (`plain`/`highlight`) is already a contracted surface of this harness (`tests/csv-output/rules/messages-columns.tsv` types it `enum:plain,highlight`) and is populated directly from the tag point via `%log_messages` — asserting on it verifies the highlight partitioning at the data layer. Add a small crafted fixture with known durations/bytes/counts placed exactly at and around the boundaries, plus per-scenario expected-category assertions. This extends the validator — today it checks structure only — so the harness charter widens from "structural" to "structural + categorical content" (header comment updated accordingly; self-documenting `asserts`/`produced_by`/`contract` fields on every new assertion). Enumerated cases, each asserting which message keys land in `highlight` vs `plain` rows:
  1. Numeric-only highlight, one scenario per family (duration, bytes, count)
  2. Boundary inclusivity at min AND max for each family — a record exactly at the bound is highlighted (locks the `-dmin`/`-dmax` fix, freezes the already-inclusive bytes/count behavior)
  3. Undefined metric never highlights (e.g. `-hbmin` against lines lacking bytes)
  4. Cross-metric AND (`-hdmin` + `-hbmin`)
  5. Regex × numeric AND (`-h` + `-hdmin`)
  6. Regex-only regression (partitioning unchanged with no numeric criteria)
- **Rendering coverage — `validate-regression.sh` / `capture-regression.sh`.** The swept gates are render gates; the CSV cannot see them (a missed gate leaves the CSV correct while the terminal silently renders nothing). New snapshot scenarios at pinned `--terminal-width`s: regex-only (baseline), numeric-only, and combined highlight, across the bar graph with `HIGHLIGHTED` summary row, heatmap (`-hm`), and histogram (`-hg`). Captured references are checked against the manual-verification list below at capture time, then guard every future gate regression. Specific files and commands are pinned in the fixture table below.
- **No cross-feature test with #313 counting UDM.** The chain is numeric predicate → single `-HL` tag point → all consumers. `validate-udm-counting.sh` already proves the consumer link (with `-h`); the CSV cases above prove the predicate link; there is no code unique to the combination. A combined test could only fail if an already-tested link fails, and would couple the UDM harness to this feature's options. The cross-feature note below stays as documentation only; `validate-udm-counting.sh` is untouched.
- Regenerate index-read-back fixture (boundary fix); run `validate-index-read-back.sh` and confirm assertions match (exit 0 is insufficient). Given the changes in this area, expect previously stored test artifacts to surface failing assertions; repairing those in the test infrastructure is in scope for this feature.
- `validate-statistics.sh` / `validate-csv-output.sh`: committed baselines verified unaffected (no scenario uses numeric filters) — run as gates anyway.
- `validate-help-content.sh` / `validate-help-layout.sh` after help edits (help-content enforces help/usage.md option parity).

### Fixture selection (log inventory characterized 2026-07-08; exact distributions computed from raw lines)

File shorthand used below:
- **APACHE** = `logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` — 677 lines, duration (µs, needs `-du us`) on every line, bytes numeric on 669 (8 are `-`), no count. Duration median 47 ms / p99 5,262 ms. Already the regression harness's `APACHE_LOG`.
- **CODEBEAMER** = `logs/Codebeamber/codebeamer_access_log.2025-10-29.txt` — 741 lines, duration (ms) on every line (median 5 / p99 1,921), bytes on 733, **no ` count=` token ever** (count stays undefined for the whole file).
- **PLOTLOG** = `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log` — 2,992 lines, mixed metric presence: `durationMS=` on only 220 lines (median 17,070 ms / max 153,921), count (first ` count=N` token — matches both `result count=` and `events to be processed count=N`) on 220 lines, `result bytes=` on 73 (median 1.7 MB).
- **DPM5K** = `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean-5k.log` — 5,000 lines, `durationMS=` on every line (median 5 / p90 963 / max 92,452 ms); bytes/count too sparse to use (n=5). Deterministic slice; also an index-read-back fixture.

Note: count *extraction* is on by default (`-oc` disables it); `-ic` only makes the count column visible. `-hcmin`/`-hcmax` therefore work without `-ic`, but scenarios include `-ic` so the highlighted count is visible in the rendered output.

| Test case | File(s) | Options (all with `--disable-progress`) | Expected split |
|---|---|---|---|
| Regex-only baseline (snapshot) | APACHE | `-du us -h "BomTransformation"` | 34/677 lines highlighted |
| Numeric-only duration (snapshot + CSV) | APACHE | `-du us -hdmin 100` | 154/677 = 22.7% |
| Numeric-only bytes (snapshot + CSV) | APACHE | `-du us -hbmin 5000` | 113/677 = 16.7%; the 8 bytes-`-` lines must stay plain |
| Regex × numeric AND (snapshot + CSV) | APACHE | `-du us -h "BomTransformation" -hdmin 100` | 19 of the 34 pattern-matched lines |
| Numeric-only count (snapshot + CSV) | PLOTLOG | `-ic -hcmin 45000` | ~15 lines of the 220 count-carrying |
| Min+max band (CSV) | CODEBEAMER | `-hdmin 32 -hdmax 300` | 55/741 = 7.4% |
| Cross-metric AND (CSV) | APACHE | `-du us -hdmin 100 -hbmin 5000` | intersection of the two subsets above |
| Undefined metric, mixed presence (CSV) | PLOTLOG | `-hdmin 20000` | 44 highlighted; all 2,772 duration-less lines stay plain |
| Undefined metric, absent from format (CSV) | CODEBEAMER | `-ic -hcmin 1` | zero highlighted rows — count never extracted from this format |
| Heatmap HL overlay (snapshot) | DPM5K | `-dm raw -hm duration -hdmin 963` | ≈10% highlighted |
| Histogram HL overlay (snapshot) | APACHE | `-dm raw -du us -hg duration -hdmin 100` | 22.7% highlighted |
| File-legend indicator, two files (snapshot) | DPM5K + PLOTLOG | `-hdmin 100000` | only PLOTLOG (max 153,921 ms) carries the highlight indicator; DPM5K max is 92,452 ms |

Boundary-inclusivity cases are NOT run against these real logs — no real file guarantees records exactly at a chosen bound; they run against the crafted fixture described above.

- Manual verification (all `--disable-progress`; primary log `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt` — 517,684 lines, duration median 35 ms / p99 3,720 ms, bytes median 378 / heavy file-download tail, session IDs present, no count metric in this format):
  1. Regex-only regression: `-h "POST"` — surfaces unchanged
  2. Numeric-only: `-hdmin 1000` — HIGHLIGHTED row, bar prefixes, TOP HIGHLIGHTED MESSAGES all appear with no `-h` (18,878 lines = 3.65%)
  3. AND composition: `-h "/Thingworx/Subsystems/RemoteAccessSubsystem" -hdmin 1000` — pattern matches 11,080 lines, 68% of them ≥ 1000 ms, so the highlight visibly shrinks when the numeric criterion is added
  4. Filter + highlight: `-dmin 100 -hdmin 1000`
  5. Boundary: `-dmin 0` includes exact-0 durations (INCLUDED count rises vs pre-change)
  6. Overlays: `-hg duration -hdmin 1000` and `-hm duration -hdmin 1000`
  7. Index signature: `-V runtime-config,index-read-back -hdmin 1000` — index CSV contains no highlight options
  8. Bytes variant: `-hbmin 100000` (32,483 lines = 6.41%). Count variant on PLOTLOG (this format has no count): `-ic -hcmin 45000`
  9. File legend: DPM5K + PLOTLOG with `-hdmin 100000` — only PLOTLOG carries the highlight indicator

## Cross-feature note (with #313)

Because numeric highlighting feeds the same `-HL` tag as regex highlighting, it drives the #313 counting-aggregation highlight behavior with zero integration code. Canonical example: line `userId=123 ... bytes=15024` under `-udm "userId::distinct" -hbmin 10000` → tagged `-HL` → `123` counts in the bucket's total distinct set AND its highlight distinct set; the distinct column renders total with the highlighted-distinct bright prefix. This integration is documented behavior, not a test surface — see Test strategy (no combined test).

## Risks

- **Gate sweep completeness** — a missed `defined $highlight_regex` gate makes numeric-only highlighting silently partial. Mitigation: mechanical grep sweep plus verification steps 2 and 6.
- **Boundary fix blast radius** — only `-dmin`/`-dmax` behavior changes; only committed artifact affected is the index-read-back fixture (regenerable). Statistics baselines verified unaffected.
- **Hot-loop cost** — predicate gated behind one precomputed boolean.
- **`-od/-ob/-oc` interaction** — with extraction omitted the metric is undefined, so nothing highlights (mirrors filter behavior). Document, don't redesign.

## Related findings (tracked separately, not in this feature's scope)

Three pre-existing inconsistencies discovered during planning were filed as separate issues: #320 (ineffective `-HL$` exclusion alternative in the `$total_occurrences` accumulation regex), #321 (numeric filters silently drop records lacking the filtered metric entirely), and #322 (silent empty result from an inverted range, e.g. `-dmin 500 -dmax 100`). #322's scope is extended to cover the six highlight options introduced here, so the inverted-range warning lands once for all twelve range options.

Resolution of #322: as scoped here, the inverted-range warning landed once for all twelve range options — the six filters warn "no log entries can match", the six highlight options warn "no log entries can be highlighted"; the run proceeds in both cases (a filter user may still want the empty render as confirmation, and highlights never change the analyzed population). Equal bounds stay silent (inclusive bounds make min == max a valid single-value band). Validation happens once at option-resolution time in `adapt_to_command_line_options()`. Locked by the inverted-range scenarios in `tests/validate-numeric-criteria-notices.sh`.

Resolution of #321: the drop-when-metric-missing behavior was kept — it is the filter-side mirror of this feature's locked highlight semantics ("a line missing a metric never satisfies a numeric criterion on that metric"), and keeping metric-less lines would silently pollute threshold-filtered statistics. What changed is visibility: the guards now count lines dropped solely for lacking the filtered metric, a post-processing note reports the per-metric counts, and the semantics are documented in `--help` and `docs/usage.md`. Locked by `tests/validate-numeric-criteria-notices.sh` (exact counts against the boundary fixture's one metric-less line per metric, plus silence when the metric is universal or no filter is set).

Resolution of #320: investigation confirmed the runtime behavior was already correct — plain and `-HL` keys partition each bucket (the highlight tag point replaces the key), so summing both is the documented "total number of log entries matched" (`docs/usage.md` metric-naming section). The dead `-HL$` alternative was removed and the exclusion anchored to exactly the derived rows (`err-rate`, `msg-rate`, `empty`); the partition invariant is now stated in a comment at the accumulation site. No behavior change; verified empirically (STATS CSV `occurrences` equals the sum of all level columns including `-HL` across 174 buckets with highlights active).

## Lessons Learned

- The gate sweep was exactly the six render sites the plan predicted (plus the declaration, the matcher resolution, and the regex-only runtime-config line). Grep-counting `highlight_regex` before touching anything made the sweep mechanical and verifiable (`grep` after: three intentional survivors).
- The single-tag-point design held: no per-surface integration code was needed. Every downstream surface (bars, summary row, message table, overlays, per-file indicator, UDM highlight arithmetic) lit up from the one predicate.
- The csv-output family-consistency rules assume messages with multiple occurrences and full metric coverage. Single-occurrence messages (impact populated while std_dev/cv/skewness/kurtosis/bimodality_coef are empty) and messages lacking a metric (duration/duration_nice populated with zeros while min/mean/max are empty) trip the shape and duration family checks. These are pre-existing emission traits first exercised by this feature's fixture; the scenarios initially declared only the families that hold (bytes, count, level). Resolved under Issue #330: metric-less messages now emit blank duration totals, `impact` moved to the `duration` family (it populates whenever `mean` does), `std_dev`/`cv` split into a `dispersion` family (populate at n≥2, vs n≥4 for the shape moments per the locked `--explain` compute contracts), and this feature's scenarios declare the full family set again.
- The regression-harness strip filter missed three timing rows (HEATMAP STATISTICS, HISTOGRAM STATISTICS, GROUP SIMILAR MESSAGES) because no prior scenario captured the summary table. Keeping the summary in a capture surfaces every timing row; the filter now covers all of them.
- `tests/fixtures/ltl-index-readback.csv` is generated on demand and gitignored (`*.csv`), not committed as planned text assumed. Regeneration was still required for the inclusive `-dmin` boundary (match counts 889→891 / 1102→1103, min durations now exactly 50) but produced no repo diff.
- The per-file highlight indicator is a color-only distinction (green √ vs green √ on green background); ANSI-stripped snapshots cannot lock it. It was verified against raw output at capture time; the snapshot locks the layout and the `-HL` category legend rows around it.
- Crafted log fixtures must not use a `.log` extension — the repo gitignores `*.log`; the `.txt` convention of `udm-counting-tokens.txt` is what makes fixtures committable.
