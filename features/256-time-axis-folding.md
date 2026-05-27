# Feature: Time-axis folding — `-pr`/`--profile` (#256)

## Overview

Add `-pr`/`--profile <mode>`, which folds the time axis onto a fixed period so that all dates in a multi-day or multi-week log overlay onto a single representative day or week. Instead of a flat chronological timeline six weeks wide, the user sees a **profile view** — "what does a typical Tuesday at 09:15 look like across six weeks of logs" — at the granularity set by the existing `-b` bucket size.

## GitHub Issue

- #256 — Add `-pr`/`--profile` option to overlay log data onto a single day or week (time-axis folding)
- Branched off `release/0.14.6`.

## Status

Design locked; not yet implemented. Branch `256-time-axis-folding`.

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
- `-V` / harness contract: which validatable invariants the fold introduces.

## Out of scope

- Other fold periods (month, year, custom day-boundary hour).
- Multi-period overlays / side-by-side comparison views.
- A group-by-message-field feature — `--profile` is reserved for time-axis folding only.
- Arbitrary user-defined work-day sets beyond Mon–Fri / Sun–Thu.
