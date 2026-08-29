# Feature: Time-axis folding — `-pr`/`--profile` (#256)

## Overview

Add `-pr`/`--profile <mode>`, which folds the time axis onto a fixed period so that all dates in a multi-day or multi-week log overlay onto a single representative day or week. Instead of a flat chronological timeline six weeks wide, the user sees a **profile view** — "what does a typical Tuesday at 09:15 look like across six weeks of logs" — at the granularity set by the existing `-b` bucket size.

## GitHub Issue

- #256 — Add `-pr`/`--profile` option to overlay log data onto a single day or week (time-axis folding)
- Branched off `release/0.15.0`.

## Status

In progress on branch `256-time-axis-folding`. Landed: core fold (CLI, `fold_epoch`, bucket remap, labels); the weekday token rendered bold + upper-cased on day-boundary rows; time-of-day `-st`/`-et` windowing for any input; the synthetic month-long fixture generator (`tests/profile/generate-profile-log.py`, varied durations so shape stats populate); the `-V profile` observability section; the STATS CSV carrying the full folded timestamp on every row (terminal-only weekday blanking excluded); the state-observability harness (`tests/validate-profile.sh`); the render-invariant harness (`tests/validate-profile-render.sh` + `tests/profile/check-profile-labels.pl`); CSV-coherence coverage in `tests/validate-csv-output.sh` (profile-week / profile-day scenarios on the generated fixture, folded-timestamp validation); and the user-facing doc sweep (`print_help()`, `docs/usage.md` option entry + worked examples; README delegates to the wiki, synced from `docs/usage.md` at release). Remaining: issue close.

## Problem

A flat timeline dilutes per-bucket sample counts over long spans and obscures recurring diurnal and weekly structure. Folding overlays every matching date onto one period, which both tightens per-bucket statistics (more samples per bucket) and surfaces load profiles — workday vs weekend, morning vs evening — that the chronological view hides.

## The seven modes

| Mode | Days included | Collapse axis | Week start | X-axis label |
|---|---|---|---|---|
| `day` | all 7 | 24h time-of-day | — | `09:15` |
| `week` | all 7 | 7-day week | Monday→Sunday (default) | `Mon 09:15` |
| `week-alt` | all 7 | 7-day week | Sunday→Saturday | `Sun 09:15` |
| `workweek` | Mon–Fri | 5-day week | Monday | `Mon 09:15` |
| `workweek-alt` | Sun–Thu | 5-day week | Sunday | `Sun 09:15` |
| `workday` | Mon–Fri | 24h time-of-day | — | `09:15` |
| `workday-alt` | Sun–Thu | 24h time-of-day | — | `09:15` |

There is no `day-alt`: a pure time-of-day fold has no week-calendar or work-week concept to vary.

#451 adds the `weekday*` and `weekend*` vocabularies (eight further modes); `features/451-weekday-weekend-profile-modes.md` carries the full table and its decisions, and `--help profile` is the user-facing mode reference.

### Defaults and `-alt`

The non-alt modes follow the ISO convention — week starts Monday, work week is Mon–Fri. The `-alt` variants flip to the Sunday-anchored convention: `week-alt` starts the week on Sunday; `workweek-alt`/`workday-alt` treat Sun–Thu as the work days (dropping Fri+Sat). The pair Mon–Fri / Sun–Thu is the only supported work-day distinction; arbitrary user-defined work-day sets are out of scope.

## Behavior

- **Excluded days are dropped entirely** before folding. Under `workweek`/`workday`, Saturday and Sunday do not contribute samples; under the `-alt` variants, Friday and Saturday do not contribute. Sample counts reflect only the included days.
- **`day`/`workday`** discard the calendar date — the x-axis shows time only (`09:15`).
- **`week`/`workweek`** retain weekday identity — the date generalizes to its weekday name (`2026-04-21` → `Monday`). The weekday label appears **once at each day boundary** (the first bucket of each weekday); subsequent buckets within that day show time only, acting as a date-change marker.
- **Summary-table first/last seen** columns show the **folded position** within the period (e.g. `Mon 08:30` / `Fri 17:45`), not the original calendar date range.
- **Composes with `-b`** — bucket size sets granularity within the folded period — and with `-st`/`-et`, `-include`/`-exclude`, `-hm`.
- **Filter ordering:** `-st`/`-et` and pattern filters apply to the **original** timestamps, before folding (date-range select first, then overlay).

## Open design areas (to resolve during implementation)

- Where folding sits in the processing flow relative to `read_and_process_logs()` and bucket assignment.
- How the x-axis label engine renders the once-per-day weekday marker within `@x_bucket_labels`.
- How the folded period interacts with the layout engine at narrow terminal widths (week modes at small `-b` produce many buckets).
- `-V` / harness contract: which validatable invariants the fold introduces (see Test strategy).

## Test strategy

The feature's correctness splits along the two harness categories `tests/HARNESS-DESIGN.md` defines, so it needs coverage of each. Both kinds of harness are built *with* the implementation, not before it.

### State-observability — excluded-day sample dropping (`-V`)

The core correctness claim that has no visual proxy is that excluded days contribute **zero** samples: under `workweek`/`workday` (and the `weekdays`/`weekday` forms #451 adds), no Saturday/Sunday sample lands in any bucket; under the `-alt` variants, no Friday/Saturday sample does; under the weekend modes, only those two days contribute and the other five are dropped. This is computed state and must be asserted through a dedicated, named `-V` section (never by grepping the graph) — the implementation must expose folded bucket membership / per-mode included-vs-dropped sample counts in `-V`. The harness feeds a fixture with known per-weekday sample counts and asserts the dropped-day count equals the days the mode excludes and the surviving buckets sum to the rest. Tracking invariant: `included + dropped = total_matched` — which the weekend modes are the first to satisfy with `dropped` exceeding `included`. The section's `profile_window_seconds` field reports the rendered window length (kept days × 86400) — see `features/451-weekday-weekend-profile-modes.md` D3, which corrected it from the internal fold modulus.

### Render-invariant — timeline x-axis + summary-table first/last seen

Properties of the rendered terminal surface itself (reference: `tests/validate-duration-display.sh`). Run `ltl` at a pinned `--terminal-width`, strip ANSI, and assert:

- **Singular modes** (`day`, `workday`, and the `weekday`/`weekend` forms #451 adds): x-axis labels are time-only (`09:15`); **no weekday token** (`Mon`, `Sun`, …) appears anywhere on the axis.
- **Plural modes** (`week`, `workweek`, `weekdays`, `weekends`): each weekday name appears **exactly once**, at its day boundary (first bucket of the day); subsequent buckets within that day are time-only.
- **Week start:** the leftmost weekday label is the mode's first kept day — `Mon` for `week`/`workweek`, `Sun` for their `-alt` forms, `Sat` for `weekends`, `Fri` for `weekends-alt` (#451 D2).
- **Excluded days:** no mode renders a label for a day it drops — `workweek`/`workday`/`weekdays`/`weekday` render no `Sat`/`Sun`, their `-alt` forms no `Fri`/`Sat`, and the weekend modes render only their own two days.
- **Summary-table first/last seen:** render as folded positions (`Mon 08:30`), not calendar dates.

These assert *invariants*, not frozen output, so they do not duplicate `validate-regression.sh`.

### Fixtures

Like `tests/distribution-shape/generate-anchor.py` (#254), a small seeded synthetic generator emits a log whose timestamps are placed on **known weekdays and hours spanning multiple calendar weeks**, so the expected folded buckets, dropped-day counts, and rendered labels are known a priori. Deterministic generation is what lets the harness assert fixed expectations rather than re-deriving them.

Heatmap-under-fold (`-hm` composed with `-pr`) is expected to work (folding precedes heatmap binning) but is not a required test surface for this issue.

## Out of scope

- Other fold periods (month, year, custom day-boundary hour).
- Multi-period overlays / side-by-side comparison views.
- A group-by-message-field feature — `--profile` is reserved for time-axis folding only.
- Arbitrary user-defined work-day sets beyond Mon–Fri / Sun–Thu.
