# Feature: Category summary table — share percentage and contribution bar (#448)

## Overview

The category rows of the run summary show an absolute count and nothing else. This drop adds each category's share of the lines included, as a percentage beside the count, and a horizontal contribution bar drawn over the row's own text in the category's colour — so the distribution reads at a glance.

## GitHub Issue

- #448 — Category summary table: relative percentage and contribution bar per category
- Builds on #463 (friendly category names — the rows' labels and the 30-character label cell), #457 (summary section at the end of the output — the rows' placement and the regression-filter anchor) and #453 (success/failure classification — the `count (pct%)` convention the share adopts).

## Status

Scoped 2026-08-29; decisions D1–D8 locked. Implemented 2026-08-29 on branch
`448-category-summary-share-and-bar`, every decision as locked.

## Scope

The category rows of the summary table only — the rows above the separator. Every other row (highlighted, lines included, classified, lines read, timings, memory) is unchanged.

## Requirements

The issue body's R1–R14 stand, amended as follows by the scoping session:

- **R3 is replaced.** The share is presented as the `SUCCESS CLASSIFIED` / `FAILURE CLASSIFIED` rows present theirs (#453), not as the memory breakdown rows do — see D1.
- **R6 is refined.** The bar is proportional to the category's share *relative to the largest category* by default — see D3.
- **R10–R14 are replaced.** The controls are five visible options under one root — see D5. Nothing is hidden.

## Locked decisions

**D1 — The share follows the #453 `count (pct%)` convention.** The value is `count (pct%)`, right-aligned to the table boundary, three significant digits (`98.2%`, `1.11%`, `0.107%`), allowed to run left into the label column's slack, precision reduced only when the row would not fit — decimals first, the percentage last, the count never. The denominator is `LINES INCLUDED`. Example:

```
  Category                            Total
  5xx Server error                2 (20.0%)
  1xx Informational, highlighted  2 (20.0%)
```

A label that fills its 30-character cell leaves 10 characters for the value; on such a row a large count loses decimals first. The bar still carries the share. The row formatter shipped inside `print_summary_table()` for the classified rows (the `$emit` closure) is lifted into the shared percentage formatter that both the classified rows and the category rows call — `docs/percentage-presentation.md` (parameters for this surface: 3 significant digits, row slack, rounded; degrades decimals then the percentage).

**D2 — The bar uses the timeline's overdraw technique, and the fill colour is derived from the category's foreground.** The row's own text is drawn over a background fill, with the text colour switching at the fill edge so it stays legible inside and outside the fill (the proportional-column branch of `print_bar_graph()`; the loop is extracted, not re-implemented). Category colours are foreground-only, so the background is **derived from the foreground by one rule for every colour** — no explicit per-category fill table (which #476, per-format level declarations, would otherwise inherit as a fifth global surface). The same derivation closes an existing gap: today only the five basic foreground codes get a background for their `-HL` highlighted twin, so cyan (`CREATE`) and any 256-colour category have no highlighted background at all. **Every category colour gets a highlighted twin.** Each `-HL` row is its own category (#463 D2) with its own share and its own bar.

**D3 — Default bar length is normalised to the largest category.** The largest row always spans the full width; every other bar is relative to it. Rationale: with the table width as 100 %, a largest contributor at 60 % leaves 40 % of the width unused and the small contributors squeezed into a few characters. Normalising gives every row the full width to work in — the fidelity the small rows need — while the printed percentage carries the absolute share, so nothing is lost. Consequence accepted: a category with 100 % of the lines and one with 30 % that happens to be the largest render the same bar; the number resolves it. Log scaling (D5) applies on top of the same largest-is-full-width reference.

**D4 — The bar spans the row's content.** It can begin at the first character of the category name and extend to the last character of the row's content, inside the summary table's width; the colour is reset before the padding so the fill never bleeds into the file-details pane printed on the same physical line. The rule line above the `Category` header — the regression filter's closing anchor (#457 D3/D5) — acquires no colour or width change.

**D5 — Five visible options, one root, short and long forms, combinable.**

| Short | Long | Effect |
|---|---|---|
| `-sbo` | `--summary-bar-off` | no bar |
| `-sbm` | `--summary-bar-mono` | bar in plain foreground/background, so it can be judged apart from the category colours |
| `-sba` | `--summary-bar-absolute` | table width = 100 % of lines included, instead of largest-row-full-width |
| `-sbl` | `--summary-bar-log` | logarithmic length scaling — the only thing that gives the tail rows a visible length when INFO is 98 % and FATAL 0.01 % |
| `-sbr` | `--summary-bar-reverse` | bar drawn right-to-left |

All are visible: `--help` rows, `docs/usage.md` rows, `-V runtime-config` provenance, release-note bullet. These are analyst experiments — the intent is to observe them on real data and deprecate the variants that do not earn their keep. The default direction (left-to-right unless observation says otherwise) is settled during that observation.

**D6 — The percentage and the bar are on by default** (R12). Non-terminal output follows what the tool does today: the ANSI escapes are emitted regardless of TTY (only the help renderer gates on colour).

**D7 — Monochrome (`-sbm`) affects the category rows only.** It is a rendering choice for the bar, not a second "should colour be emitted" convention.

**D8 — No prototype.** Everything is computed once per displayed row from `%category_totals` and `$total_lines_included`, both already accumulated; no per-line cost, no new data model.

## In-drop obligations

- The five options: `GetOptions` specs, `print_help()` rows, `docs/usage.md` rows, `_classify_argv_provenance()` and `emit_runtime_config_verbose()` entries — same commit (`tests/validate-help-content.sh`, `tests/validate-runtime-config.sh`).
- `tests/validate-category-names.sh` reads label and total at exact column offsets; its row regexes are updated for the `count (pct%)` value. Both it and the vocabulary harness now anchor the label at the row's left edge and the value at the row boundary, which is the geometry that actually keeps the table aligned — a fixed total column stopped being one when the value gained the right to run into the label's slack.
- `tests/validate-log-level-vocabulary.sh` reconciles category totals against `LINES INCLUDED` by parsing the rows; it must still find the count.
- Thirteen regression references carry the category rows and are re-blessed (`tests/capture-regression.sh`) — the ten `hl-*` plus the three `errrate-*`. They strip ANSI, so **no golden can assert the bar**: `tests/validate-summary-contribution-bar.sh` (under `tests/lib/colour-env.sh`, identical counts with `FORCE_COLOR=3`, with `NO_COLOR=1` and with neither) asserts the fill, its extent and contiguity, its colour, its reset before the pane, and each of the five options.
- The derived-background rule and the closed `-HL` gap get their own assertion (every entry in the category colour table has a highlighted twin with a background). It slices the colour table, `derive_background_color()` and the twin-construction loop out of `ltl` and runs them, so it checks what the tool builds rather than a second implementation of the rule.
- `docs/usage.md` § Display & Output describes the run summary; the paragraph gains the share and the bar.

## Implementation notes

**N1 — The shared formatter is `format_percentage( $value, %params )`.** `$value` is the percentage itself, not a fraction. Parameters, all optional: `mode` (`significant` — the default — / `decimals` / `integer`), `digits`, `width` (parentheses and the `%` sign included), `floor` (round down rather than to nearest), `parens`, `floor_at` + `floor_text` (below `floor_at` the marker is shown in place of a figure), and `pad` (right-align within `width`, inside the parentheses where they are in use). It returns the rendered string and never exceeds `width`, dropping decimals one at a time and never below a whole percent. What a surface does when even the whole percent will not fit is the surface's own decision — the caller inspects the returned length. This is the signature #446 (progress line) and #452 (reliability column) call.

**N2 — The two migrated sites are byte-identical.** The classified rows and the memory breakdown rows were checked against their previous implementations over 100 000 percentage values and 984 label/count/width combinations before the swap, and the memory rows' existing goldens confirm it. Two properties of the memory field that a rounds-to-zero reading would have lost: its `<1%` marker is a threshold on the raw value (a share of 0.6 % is `(<1%)`, not `(1%)`), and its padding sits *inside* the brackets (`( 3%)`), which is why `pad` pads the figure rather than the wrapped string.

**N3 — `share_row_text()` composes the row.** It is the single builder for a summary row carrying a count and, where a denominator is given, that count's share — used by both the classified rows and the category rows. It returns the row text without the table's outer padding, so the bar renderer knows exactly which characters are the row's own.

**N4 — The row geometry is one source.** `$summary_category_column_width` (30), `$summary_occurrences_column_width` (10) and the derived `$summary_row_width` (41) are file-scoped, because the row builder and the table renderer both need them and a second copy would drift.

**N5 — The logarithmic scale runs one decade below the smallest count.** The obvious formula — spreading `log10(count/reference)` over `log10(reference)` decades — maps a single-line category to exactly zero, so the one case `-sbl` exists for rendered as the one-character stub the linear scale already gave it. The span is therefore `log10(reference) + 1`. Caught by the new harness, not by inspection: on the fixture the smallest category goes from 1 to 16 of 41 characters.

**N6 — The `-HL` derivation is additive.** `derive_background_color()` replaced a five-branch ladder over foreground codes. The five backgrounds it produced are reproduced exactly and 23 further colours gain one; no colour lost a background. Where a foreground sets the colour more than once (`white` is `\033[36m\033[37m`), the last code wins, as the terminal itself resolves it. `msg-rate` is a reset and names no colour, so it derives none — it is not a category row.

## Merge gate

Touches `ltl`, harnesses and goldens: the full `tests/validate-*.sh` suite and the before/after benchmark on this machine (CLAUDE.md per-feature step 1).

## Related

- #463 (friendly category names) — its § Out of scope anticipated this drop: "whichever lands second inherits the other's shape". #448 inherits the 30-character exact-fit labels and the `, highlighted` twin rows.
- #457 (summary at the end) — the regression-filter anchor constraint in D4.
- #453 (success/failure classification) — the share convention in D1; merged 2026-08-29.
- #452 (reliability percentage column) — a third percentage surface; not a dependency. All percentage surfaces share one formatter with per-surface parameters: `docs/percentage-presentation.md`.
- #475 / #476 (missing severity levels; per-format level declarations) — add rows; D2's derivation rule means they inherit the fill and the highlighted twin with no new table.
