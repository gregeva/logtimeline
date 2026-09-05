# Feature: Descriptive names for log categories in the category summary table

## Overview

The category summary table printed after the timeline lists every log level or
event class found in the input, with its total. A category is named by whatever
the log format declares — `INFO`, `Pause Full`, `4xx`. Where that name does not
tell a reader what the category *is*, the table now shows a descriptive name in
its place.

The motivating case is the HTTP status families. `4xx` and `5xx` are sufficient
to a reader who already knows them and say nothing to a reader who does not —
and the category table is exactly where a reader who is not steeped in the
format is trying to work out what they are looking at.

## GitHub Issue

- #463 (FEATURE: friendly descriptive names for log level categories in the
  summary table) — the requirement.

## Requirements

- **R1** — A lookup from a category name to a descriptive name. Where an entry
  exists, the category summary table shows the descriptive name.
- **R2** — Where no entry exists, the table shows the category's own name,
  unchanged. Formats whose category vocabulary already reads plainly need no
  entries and are unaffected.
- **R3** — The HTTP status families get entries under their conventional family
  names.
- **R4** — A highlighted category (the `-HL` twin of a category) gets the same
  treatment, with the highlight indicated at a position that suits the
  descriptive text rather than mechanically appended by code.

## Locked decisions

### D1 — One global lookup, shared by every format (architect, 2026-08-26)

The mapping is global: one table, not a per-format declaration in the format
registry. A category name means the same thing whichever producer emitted it,
and the HTTP status families are common to every access-log format, so
declaring them per format would duplicate the same five rows across every
access entry and let them drift.

The shipped entries, all of them HTTP status families:

| Category | Displayed as |
|---|---|
| `1xx` | `1xx Informational` |
| `2xx` | `2xx Success` |
| `3xx` | `3xx Redirection` |
| `4xx` | `4xx Client error` |
| `5xx` | `5xx Server error` |

The numeric family is kept at the front of the descriptive name rather than
replaced by it: a reader who already knows the shorthand loses nothing, and a
reader who does not gains the meaning without having to map one to the other.
No other category has an entry — the log-level vocabulary (`INFO`, `ERROR`,
`WARN`, …), the GC pause kinds and the Workgroup Manager lifecycle categories
all name themselves.

Placement: `%category_display_names` sits in the GLOBALS section immediately
after `@log_levels` / `%log_level_set`, beside the category vocabulary and the
category colours (`%colors`) it parallels — the existing global per-category
surfaces — rather than inside any format registry entry. `features/395-wgm-client-log-format.md`
§ *Log-category consistency* lists the three surfaces a category already lives
on; this is a fourth, and the only optional one.

### D2 — The highlighted twin is its own entry, with the indicator trailing

Each category with a descriptive name carries a second entry for its `-HL`
twin, exactly as the requirement asks: the descriptive text is longer and
differently shaped than the raw name, so where the highlight indicator belongs
is a judgement about that phrase, not something code can append correctly in
general.

The shape chosen for the five families is a trailing `, highlighted`:

```
  5xx Server error, highlighted           1
  5xx Server error                        1
```

Two reasons. It keeps the family name at the left edge of a left-aligned
column, so the highlighted row and the plain row directly beneath it line up
and read as a pair — a leading `Highlighted ` breaks that alignment on the one
axis the eye uses to scan the table. And it matches the vocabulary the rendered
surface already uses for the same idea: the table's own `HIGHLIGHTED` total row
and the `TOP HIGHLIGHTED MESSAGES` heading.

A parenthetical form (`5xx Server error (highlighted)`) was rejected on width:
`1xx Informational (highlighted)` is 31 characters against a 30-character
column, so D4 would cut it to `1xx Informational (highlighted` and the closing
bracket would be lost.

### D3 — The legend and the CSV keep the raw category name

Only the category summary table changes.

- **The per-bucket legend** beside the timeline keeps `4xx: 12`. The legend is
  repeated on every bucket row and its width is a budget shared with the bar
  graph, which is derived from the summed lengths of every category's
  `name: count` entry; descriptive names would multiply it and take the space
  the timeline exists to show.
- **The CSV (`-o`)** keeps `4xx` and `4xx-HL` as column names. The header is a
  machine-readable contract addressed by name by external tooling and by the
  column-rules validator (`tests/csv-output/rules/stats-columns.tsv`).

### D4 — The name fits the column, and a longer one is cut to it

`print_summary_table()` renders the category cell at a fixed
`$category_column_width` of 30 with the total right-aligned beside it, so the
totals align down the whole table and the file-details pane rendered to its
right stays put. Every shipped name fits: the longest,
`1xx Informational, highlighted`, is exactly 30. A label longer than the column
is truncated to it at render, so no future entry can misalign the surface.

### D5 — The lookup stays in GLOBALS, beside the category vocabulary it parallels (architect's delegate, 2026-08-28)

`%category_display_names` is declared in GLOBALS immediately after
`@log_levels` and `%log_level_set`, and above `%colors`, and it stays there.

A category already lives on three global surfaces: the ordered `@log_levels`
list that fixes the row order of the summary table, the `%log_level_set`
membership map, and the `%colors` table that gives it its colour (whose `-HL`
twin is generated from the plain entry). The descriptive name is a fourth
surface of exactly the same kind — keyed by category name, global, and shared
by every format — and it is the only optional one. Keeping it in that
neighbourhood means adding a category is one edit region rather than four
scattered ones, and the omission of an entry is visible right beside the three
surfaces that do carry it.

The alternatives were both declined: a per-format declaration inside the format
registry, already declined by D1 [one global lookup shared by every format]
because the HTTP families would be duplicated across every access entry and
drift; and a separate configuration surface, which belongs to the open question
below rather than to this drop.

### D6 — `2xx Success` stands as the display text (architect's delegate, 2026-08-28)

The five shipped names read as a set: `1xx Informational`, `2xx Success`,
`3xx Redirection`, `4xx Client error`, `5xx Server error`. `2xx Success` is
kept as it is — it is the family's conventional name, it is what a reader
scanning the column recognises immediately, and it holds the same short
noun-phrase shape as its four siblings, which is what lets the column be read
down rather than row by row.

### D7 — A category with no entry keeps its raw name, `-HL` suffix included (architect's delegate, 2026-08-28)

The requirement is that where no entry exists, the category's own name is
displayed unchanged. For a highlighted twin with no entry, its own name is the
raw key — suffix and all. The behaviour is therefore as specified, and it is
not changed here.

The visible consequence, in a table covering more than one format, is a mixed
convention. Rendering an access log and a Windchill method-server log together
(`-h orders -h 'Error level'`) gives:

```
  FATAL                                   1
  ERROR-HL                                1
  WARN                                    1
  ...
  5xx Server error, highlighted           1
  5xx Server error                        1
```

`ERROR-HL` and `5xx Server error, highlighted` say the same thing two different
ways, three rows apart. Resolving it would mean either entries for every
remaining category vocabulary, or a rendered highlight indicator that the code
appends — and appending a marker is precisely what the requirement declines,
because where the indicator reads naturally is a judgement about each phrase.
Both are a decision for whoever picks it up; this drop leaves the specified
behaviour in place and records the observation as a possible follow-up.

## Open question — not decided in this drop

Of the two open questions the requirement carries, the first — global lookup or
per-format declaration — is decided by D1 [one global lookup shared by every
format]. The second stays open: whether a user can supply or override entries,
or whether the set ships with the tool. **This drop ships the set with the
tool: there is no user override**, and the question stays open on #463 for a
later decision.

## Affected surfaces

| Surface | Change |
|---|---|
| `%category_display_names` in `ltl` (GLOBALS) | New: the global lookup, ten entries (five families and their highlighted twins) |
| `category_display_name()` in `ltl` | New: the one resolution surface — descriptive name where defined, the category's own name otherwise |
| `print_summary_table()` in `ltl` | Renders the resolved label, truncated to the category column width |
| `docs/usage.md` § Display & Output | Describes the Category table, the family names, and the `, highlighted` row |
| `docs/test-logs.md` § AccessLogs | Documents the new fixture |
| `tests/reference-output/hl-*.txt` (6 files) | Re-blessed: the snapshot harness freezes the rendered table, which now shows the descriptive names |

No CLI option was added, so `print_help()` is unchanged; `docs/usage.md` gained
prose only, with no option row on either surface to keep in step.

## Test coverage

`tests/validate-category-names.sh` — a render-invariant harness
(`tests/HARNESS-DESIGN.md` § Render-invariant harnesses): the rendered category
table is the surface under test, not a proxy for internal state. 26 assertions
across four scenarios, all `-bs 1440 -oe -n 1` on ten-line fixtures spanning
seconds, with `-lf tomcat_access_with_duration` pinning the format so the run
does not depend on filename evidence.

- **`http-status-families`** — `tests/fixtures/http-status-families.txt`
  (two lines per family; `-h orders` highlights one 2xx, one 4xx and one 5xx
  line so three families show both rows). Asserts each family's descriptive
  name and each highlighted twin, reading the label and total at their exact
  column offsets so the assertion covers the geometry as well as the text;
  asserts that no row is still labelled with a raw family name (the descriptive
  name replaces it, it is not shown alongside); asserts the legend still shows
  `5xx: <count>`.
- **`longest-name-fills-the-column`** — the same fixture with the highlight on
  its 1xx line, the only way the 30-character `1xx Informational, highlighted`
  reaches the render; the other scenario's highlight never produces it, so the
  exact-fit boundary the cell width turns on would otherwise go unrendered by
  any test. Asserts that row and its plain twin at their exact column offsets.
- **`csv-keeps-raw-category-names`** — the same run with `-o`; asserts the stats
  CSV header carries `1xx 2xx 2xx-HL 3xx 4xx 4xx-HL 5xx 5xx-HL` and no
  descriptive text.
- **`unmapped-categories-keep-their-own-name`** —
  `tests/fixtures/log-level-vocabulary.txt`; asserts `FATAL ERROR WARN INFO
  DEBUG TRACE` each label a row under their own name.

**Proof the assertions can fail** (`tests/HARNESS-DESIGN.md` § Proving a new
assertion can fail), 2026-08-28:

- Bypassing the lookup in `category_display_name()` so it returns the raw name:
  16 of the assertions fail — every family row, every highlighted twin and
  every raw-name-replaced check — while the legend, CSV and unmapped-level
  assertions still pass, which is the correct partition.
- Feeding each checker a doctored input directly: a render whose 30-character
  highlighted row has its total displaced one column right, a name that labels
  no row, a raw name still labelling a row, a legend carrying the descriptive
  text, and a stats CSV header carrying it. All five fail with the expected
  diagnostic.
- Cutting the label one character shorter than the column: exactly the one
  boundary assertion fails (`1xx Informational, highlighted` no longer labels a
  row), 25 of 26 still pass. The cell-width boundary is therefore under test
  and nothing else depends on it.

**Colour-environment parity** (`tests/HARNESS-DESIGN.md` § Colour rendering is
controlled): `FORCE_COLOR=3 CI=1` and `env -u FORCE_COLOR -u NO_COLOR CI=1` both
report 26 passed, 0 failed.

**Neighbouring harnesses over the same surface**, run on the finished change:
`tests/validate-log-level-vocabulary.sh` 8/0 (it reads the same category table
for the unmapped levels), `tests/validate-duration-display.sh` 21/0,
`tests/validate-regression.sh` 71/0 after the six re-blessed references.

The six re-blessed references were identified by capturing a full reference set
into a temporary directory and diffing it against the committed set: exactly
six files differed, and every differing line was a category row acquiring its
descriptive name. Only those six were copied over, so no unrelated drift was
blessed along with them.

## Completion gate

Run on `43df560` (`#463: restore release version for the completion gate`), the
commit being merged — the branch rebased onto `release/0.18.0` at `58842fa`
(release notes for #457, the run summary printed last) with `$version_number`
restored to `0.18.0`.

**No benchmark was run.** The architect has ruled that performance benchmarks
are not part of feature work; `tests/baseline/run-benchmark.sh` was not invoked
and no `463-*.tsv` result was produced.

### Rebase

One conflict, in `ltl`. #457 (the run summary printed at the end of the output)
split `print_summary_table()`, lifting its command-and-arguments block out into
a new `print_run_options()` and adding `return if $omit_summary;` to what
remained — so the release branch's new sub landed on the same lines as this
branch's new `category_display_name()` and its edit to the summary table's
header. Resolved by keeping the release branch's split intact and placing
`category_display_name()` immediately above `print_run_options()`; the label
lookup inside the category loop merged cleanly into the retained
`print_summary_table()`. `perl -c` clean, and the whole-file diff against
`release/0.18.0` is exactly this branch's four changes: the
`%category_display_names` table in GLOBALS, `category_display_name()`, the
truncating label lookup in the category loop, and the version line.

The six re-blessed regression references and `docs/usage.md` merged
automatically and were verified rather than assumed: each reference differs from
its `release/0.18.0` version only in the category rows acquiring their
descriptive names, with #457's relocation of the summary block preserved, and
`tests/validate-regression.sh` passes 71/0 against them.

### Harness suite — 28 of 28 pass

Every harness exited 0 and its summary line reports checks actually run —
1 155 passing, 0 failing, across the whole suite.

| Harness | Summary |
|---|---|
| `validate-csv-output` | 21 scenarios, 21 pass, 0 fail |
| `validate-statistics` | 21 scenarios, 21 pass, 0 fail |
| `validate-category-names` | PASS 26, FAIL 0 |
| `validate-csv-input` | 4 pass, 0 fail |
| `validate-distribution-shape` | 8 passed, 0 failed |
| `validate-doc-examples` | 46 passed, 0 failed, 9 skipped |
| `validate-duration-display` | 21 passed, 0 failed |
| `validate-explain` | 148 passed, 0 failed |
| `validate-format-detection` | 192 passed, 0 failed |
| `validate-format-registry` | 22 passed, 0 failed |
| `validate-heatmap-palette` | 85 passed, 0 failed |
| `validate-help-content` | 11 passed, 0 failed |
| `validate-help-layout` | 6 passed, 0 failed |
| `validate-histogram-bin-counters` | 84 passed, 0 failed |
| `validate-histogram-ticks` | 21 passed, 0 failed |
| `validate-index-read-back` | 59 passed, 0 failed |
| `validate-log-level-vocabulary` | PASS 8, FAIL 0 |
| `validate-message-control-characters` | PASS 11, FAIL 0 |
| `validate-message-grouping-notices` | 4 passed, 0 failed |
| `validate-numeric-criteria-notices` | 10 passed, 0 failed |
| `validate-profile-render` | 22 passed, 0 failed |
| `validate-profile` | 50 passed, 0 failed |
| `validate-recursive-file-selection` | 22 passed, 0 failed |
| `validate-regression` | 71 passed, 0 failed, 0 skipped |
| `validate-runtime-config` | 36 passed, 0 failed |
| `validate-statistics-demand` | 75 passed, 0 failed |
| `validate-udm-counting` | 28 passed, 0 failed |
| `validate-udm-specs` | 43 passed, 0 failed |

`validate-csv-output` was run first so `validate-statistics` shared its `CI=1`
cache. `./tests/cleanup-test-artifacts.sh` was run afterwards.

### Statistics-drift advisories

No T3 or T4 failure on any of the three layers, so nothing blocks. The advisory
counts are 943 T2 cells, all on the algorithm-aware oracle layer, and 28
registered known failures — every one of them the single projection onto the
shared bin geometry already tracked as #469 (bin-model percentile projection
error), listed in `tests/statistics-drift/known-failures.tsv`. None is
attributable to this change: it adds a render-time label lookup and touches no
statistic, and the CSV column names are unchanged by D3 [the legend and the CSV
keep the raw category name].

## Out of scope

- User-supplied or user-overridden entries (the open question above).
- Descriptive names for any vocabulary other than the HTTP status families.
- The mixed convention a multi-format table shows between a raw `-HL` row and a
  descriptive `, highlighted` row — behaviour as specified, recorded as a
  possible follow-up in D7 [a category with no entry keeps its raw name].
- The legend and the CSV (D3).
- The category table's row shape — #448 (relative percentage and contribution
  bar per category) changes the same rows; whichever lands second inherits the
  other's shape, and its R7 (the bar may begin at the first character of the
  category name) now meets a name whose length varies by category.
