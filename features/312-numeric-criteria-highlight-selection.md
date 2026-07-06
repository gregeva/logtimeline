# Numeric Criteria as Highlight/Selection (Issue #312)

## Status
- **Issue**: #312
- **Branch**: `312-numeric-criteria-highlight-selection`
- **Target release**: v0.16.0
- **Phase**: Planned — decisions locked, implementation not started

## Overview

Today the numeric threshold options (`-dmin`/`-dmax`, `-bmin`/`-bmax`, `-cmin`/`-cmax`) only hard-filter: records outside the range are dropped from the analysis entirely. This feature adds a parallel set of *highlight* options that keep the full population in view while visually selecting the subset matching numeric criteria — the same treatment the regex highlight (`-h`/`-hf`) provides for text matches. A pattern within the broader population can then be observed in context rather than by filtering everything else out.

## Requirements

1. Highlight (not drop) records whose duration, bytes, or count values fall inside a user-given inclusive range.
2. Every output surface that renders the regex-highlight subset must render the numeric-highlight subset identically: occurrences legend, proportional bar prefix, summary `HIGHLIGHTED` row, TOP HIGHLIGHTED MESSAGES block, histogram overlay, heatmap overlay.
3. Numeric highlight must compose with the existing hard filters (e.g. trim noise with `-dmin 100` while highlighting the slow tail with `-hdmin 1000` in one run).
4. Numeric highlight must compose with the regex highlight (see decisions).
5. Runs without numeric highlight options must pay essentially zero additional per-line cost.

## Decisions (locked 2026-07-06, user-approved)

| Decision | Outcome | Rationale |
|----------|---------|-----------|
| Option surface | Six h-prefixed mirrors: `-hdmin/--highlight-duration-min`, `-hdmax/--highlight-duration-max`, `-hbmin/--highlight-bytes-min`, `-hbmax/--highlight-bytes-max`, `-hcmin/--highlight-count-min`, `-hcmax/--highlight-count-max` (all integer-typed, matching the filter options) | Mirrors the existing filter naming 1:1; fully composable with the hard filters in one run; requires no index-cache signature changes (highlight options are not filters, same as `-h` today) |
| Within-metric semantics | Inclusive min AND max band — `min <= value <= max`. No "outside/outlier" mode. | Matches how filtering works today; range-exclusion was considered and rejected as an unproven need |
| Across metrics | AND — each given criterion is an independent constraint that must all pass | Mirrors how the hard numeric filters compose |
| Regex highlight × numeric | AND (intersection): a record is highlighted iff the text matcher matches (any of its OR'd patterns/file lines) AND all numeric criteria are satisfied. Either family alone decides when the other is absent. | Cross-family *filters* already compose with AND (`-i "api" -dmin 100`); enables "requests to endpoint X slower than 1s", which regex alone cannot express |
| Undefined metric | A record missing the metric never satisfies a criterion on it — renders plain | Highlight analog of the existing filter behavior (records with undefined metrics are dropped when the corresponding filter is set) |
| Boundary normalization (in scope) | `-dmin`/`-dmax` change from boundary-exclusive to **inclusive**, matching `-bmin`/`-bmax`/`-cmin`/`-cmax`. All six filters and all six highlight options use the closed-interval convention: kept/highlighted iff `defined(metric) && metric >= MIN && metric <= MAX` (each bound only when given). | Pre-existing inconsistency; fixing it here keeps filter and highlight semantics identical. Behavior change to `-dmin`/`-dmax` (records exactly at the threshold are now kept) — requires its own release-note bullet. |
| CSV exposure of highlight | Out of scope | No highlight representation exists in `-o` CSV outputs today; adding one is a new surface — proposed as a follow-up issue |

## Design

### Core mechanism

All rendering machinery for "highlighted subset within a bucket" already exists and keys off two things set at a single tag point in `read_and_process_logs` (the `-HL` suffix on `$category_bucket`, and `$category = 'highlight'`). The feature is a numeric predicate evaluated at that tag point, combined per the AND decision with the existing `match_filter()` text result. Everything downstream flows automatically: `%log_occurrences` `-HL` keys, `%log_analysis` `-HL` sums, scaled bar prefixes, `%log_messages{'highlight'}`, histogram `*_hl` structures, heatmap `*_hl` structures.

- New globals beside the filter variables: `$highlight_duration_min/max`, `$highlight_bytes_min/max`, `$highlight_count_min/max`, plus a precomputed `$numeric_highlight_active` boolean and a unified `$highlight_active` (regex OR numeric active), resolved in `adapt_to_command_line_options` after `build_filter_matcher`.
- Six new `GetOptions` entries beside the filter options, `=i` typed.
- Boundary normalization: the duration filter comparisons flip from `<=`/`>=` to `<`/`>` in the hard-drop guards, making them identical to bytes/count.
- Hot-loop discipline: the numeric predicate is evaluated only when `$numeric_highlight_active`; runs without these options pay one falsy check per line.

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
- `releases/v0.16.0.md`: one bullet for the feature, one for the `-dmin`/`-dmax` boundary change.

## Test strategy

- **Read `tests/HARNESS-DESIGN.md` before touching or creating any harness** (mandatory trigger).
- Regenerate index-read-back fixture (boundary fix); run `validate-index-read-back.sh` and confirm assertions match (exit 0 is insufficient).
- `validate-statistics.sh` / `validate-csv-output.sh`: committed baselines verified unaffected (no scenario uses numeric filters) — run as gates anyway.
- `validate-help-content.sh` / `validate-help-layout.sh` after help edits (help-content enforces help/usage.md option parity).
- New coverage: prefer extending an existing harness with a numeric-only highlight scenario (asserts the `HIGHLIGHTED` summary row appears without `-h`) and a boundary-inclusivity check on a crafted fixture; decide final placement after the HARNESS-DESIGN read.
- Manual verification (all `--disable-progress`, log `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt`):
  1. Regex-only regression: `-h "POST"` — surfaces unchanged
  2. Numeric-only: `-hdmin 1000` — HIGHLIGHTED row, bar prefixes, TOP HIGHLIGHTED MESSAGES all appear with no `-h`
  3. AND composition: `-h "/Thingworx/Things" -hdmin 1000`
  4. Filter + highlight: `-dmin 100 -hdmin 1000`
  5. Boundary: `-dmin 0` includes exact-0 durations (INCLUDED count rises vs pre-change)
  6. Overlays: `-hg duration -hdmin 1000` and `-hm duration -hdmin 1000`
  7. Index signature: `-V runtime-config,index-read-back -hdmin 1000` — index CSV contains no highlight options
  8. Bytes/count variants: `-hbmin 100000`; `-ic -hcmin 5`

## Cross-feature note (with #313)

Because numeric highlighting feeds the same `-HL` tag as regex highlighting, it drives the #313 counting-aggregation highlight behavior with zero integration code. Canonical example: line `userId=123 ... bytes=15024` under `-udm "userId::distinct" -hbmin 10000` → tagged `-HL` → `123` counts in the bucket's total distinct set AND its highlight distinct set; the distinct column renders total with the highlighted-distinct bright prefix.

## Risks

- **Gate sweep completeness** — a missed `defined $highlight_regex` gate makes numeric-only highlighting silently partial. Mitigation: mechanical grep sweep plus verification steps 2 and 6.
- **Boundary fix blast radius** — only `-dmin`/`-dmax` behavior changes; only committed artifact affected is the index-read-back fixture (regenerable). Statistics baselines verified unaffected.
- **Hot-loop cost** — predicate gated behind one precomputed boolean.
- **`-od/-ob/-oc` interaction** — with extraction omitted the metric is undefined, so nothing highlights (mirrors filter behavior). Document, don't redesign.

## Related findings (tracked separately, not in this feature's scope)

Three pre-existing inconsistencies discovered during planning are being filed as separate issues: the ineffective `-HL$` exclusion alternative in the `$total_occurrences` accumulation regex; the undocumented dropping of records lacking the filtered metric entirely; the silent empty result from an inverted range (`-dmin 500 -dmax 100`).

## Lessons Learned

*(to be filled during implementation)*
