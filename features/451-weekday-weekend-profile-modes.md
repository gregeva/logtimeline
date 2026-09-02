# Feature: Weekday and weekend profile modes — `-pr`/`--profile` (#451)

## Overview

Extends time-axis folding (`features/256-time-axis-folding.md`) with eight modes: the **weekday** vocabulary (`weekday`, `weekday-alt`, `weekdays`, `weekdays-alt`) and the **weekend** vocabulary (`weekend`, `weekend-alt`, `weekends`, `weekends-alt`). The weekend modes are new capability — nothing today can profile the weekend on its own. The weekday modes are an independent vocabulary that, by default, keeps the same days as the work-week modes.

## GitHub Issue

- #451 — Enhancement: add weekday and weekend profile modes to `-pr`/`--profile`
- Extends #256 (time-axis folding), delivered in v0.15.0.

## Status

Scoped 2026-08-29; decisions D1–D5 locked. Implemented on branch
`451-weekday-weekend-profile-modes`: the eight modes, the contiguous plural
weekend axes, the `profile_window_seconds` rename with its value correction,
`--help profile`, and the harness sweep across all five mode-table sites.

## Requirements

The issue body is the requirement. In summary:

| Mode | Days kept | Profile window | Axis |
|---|---|---|---|
| `weekday` | Mon–Fri | 24 h | time-only |
| `weekday-alt` | Sun–Thu | 24 h | time-only |
| `weekdays` | Mon–Fri | 5 days, Mon→Fri | weekday + time |
| `weekdays-alt` | Sun–Thu | 5 days, Sun→Thu | weekday + time |
| `weekend` | Sat+Sun | 24 h | time-only |
| `weekend-alt` | Fri+Sat | 24 h | time-only |
| `weekends` | Sat+Sun | 2 days, Sat→Sun | weekday + time |
| `weekends-alt` | Fri+Sat | 2 days, Fri→Sat | weekday + time |

Singular folds onto one 24-hour period; plural keeps each day's identity on the axis — the same distinction that separates `workday` from `workweek`. Every `-alt` variant applies the Sunday-anchored calendar, exactly as the existing `-alt` modes do (`features/256-time-axis-folding.md` § *Defaults and `-alt`*).

**The modes are independent.** `weekday` and `workday` are two vocabularies, not one mode with two names: a weekday is a calendar notion, a work week is a regional convention, and a user may need either. That they keep the same days by default is a coincidence of the ISO calendar, not a definition, and each vocabulary carries its own `-alt` because the calendar itself starts on a different day in different regions.

## Locked decisions

**D1 — Every new mode is its own entry in the mode table; `-V profile` `mode:` echoes the name the user typed.**
`-pr weekday` reports `mode: weekday`, never `workday`. The `weekday*` entries carry the same geometry as their `work*` counterparts, but they are entries, not parse-time rewrites. Rationale: the issue exists because the word a user reaches for should work — the tool answering back in a different word undercuts that, and the existing harness assertion ("`mode` matches the `--profile` argument") stays true unchanged.

**D2 — The plural weekend axes are contiguous.**
`weekends` renders Sat→Sun; `weekends-alt` renders Fri→Sat. Both fall out of the existing fold mechanism with no new concept: under the Monday anchor Sat/Sun are days 5 and 6 of the fold window, under the Sunday anchor Fri/Sat are. The alternative (forcing the weekend days into their positions inside a full Mon–Sun frame) would render five empty days between the two kept days.

Consequence for the render invariant: the rule "leftmost weekday label is Mon for default modes, Sun for `-alt`" (`features/256-time-axis-folding.md` § *Render-invariant*) becomes **per-mode: the leftmost weekday label is the mode's first kept day.** `tests/validate-profile-render.sh` and `tests/profile/check-profile-labels.pl` are restated accordingly in the same commit as the new modes.

**D3 — `-V profile` reports the profile window, not the fold modulus. The field is renamed `profile_window_seconds`.**
The shipped `period_seconds` echoed the internal 7-day fold modulus (`fold_epoch()`'s `$cfg->{period}`), so `workweek` — a Mon→Fri window — reported 604800. That value was wrong: the field's meaning is the length of the rendered profile window, from its first kept day's 00:00 to its last kept day's 24:00. Definition: **`profile_window_seconds` = number of kept days × 86400** (kept days are always contiguous under D2). Values:

| Modes | `profile_window_seconds` |
|---|---|
| `day`, `workday*`, `weekday*`, `weekend*` | 86400 |
| `weekends*` | 172800 |
| `workweek*`, `weekdays*` | 432000 (corrected from 604800) |
| `week*` | 604800 |

The fold modulus stays internal and is no longer exposed. This is a rename of a stability-contracted `-V` key plus a value correction on two existing modes: `tests/HARNESS-DESIGN.md` is consulted before the change, and the harness (`tests/validate-profile.sh`), the reserved-names list in HARNESS-DESIGN.md, and the `-V profile` contract below are updated in the same commit.

**D4 — `--help profile` is the mode reference; the main `--help` row stays concise.**
`--help profile` (a third topic on the existing `--help <topic>` surface, beside `statistics` and `formats`) documents every mode: kept days, window, axis, and what its `-alt` variant changes. The `-pr` row in `print_help()` and the matching `docs/usage.md` row name the base modes, state that each has an `-alt` variant, and point to `--help profile` to choose. The invalid-mode error message points to `--help profile` rather than listing all fifteen names. Not `--explain`: the mode list is operational detail, not method documentation.

**D5 — No prototype.** Table rows in the existing `%profile_modes` structure; no new data model, no new per-line cost (`fold_epoch()` already does one hash lookup and one weekday-set test per matched line).

## In-drop obligations (implementation-time, no lock needed)

- The mode table exists in five places and each gains the eight modes in the same commit: `%profile_modes` in `ltl`; `expected_weekdays()` / `expected_period()` / `ALL_MODES` in `tests/validate-profile.sh`; `%MODE` in `tests/profile/check-profile-labels.pl`; the `expected.<mode>` manifest block in `tests/profile/generate-profile-log.py`; and the week-shape test in `tests/csv-output/validate-csv-output.pl`.
- **Defect to fix on the way:** `tests/csv-output/validate-csv-output.pl` decides "week-shaped" by name prefix (`/^(week|workweek)/`), which would classify `weekday` and `weekend` — time-only modes — as week-shaped. The test becomes table-driven (the mode's format carries `%a`, the same shape `print_bar_graph()` already uses).
- The summary-table fold heading interpolates the raw mode name ("folded onto a single `weekends` profile") and reads badly for the plurals; give each mode a display phrase or reword the sentence.
- The fixture generator already computes Sat+Sun and Fri+Sat totals for a month where they differ (16 vs 18 lines), so the weekend modes' `included`/`dropped` expectations are those numbers swapped — no new fixture. The state-observability invariant `included + dropped = total_matched` must hold for every new mode; the weekend modes are the first where `dropped` exceeds `included`.
- Every new harness scenario is shaped to what it asserts (`tests/HARNESS-DESIGN.md` § *Invocation coherence*): `-bs 1440 -oe` for state checks, the pinned `-bs 60 -oe --terminal-width` the render harness already uses.
- `docs/usage.md`: the `-pr` option row mirrors the `print_help()` row (same commit), and the worked examples gain a weekend example — weekend isolation is the new capability.

## `-V profile` section contract

Section name `profile`. Fields, in order:

| Field | Meaning |
|---|---|
| `profile_active` | `yes` / `no` |
| `mode` | the `--profile` argument as typed (D1) |
| `profile_window_seconds` | kept days × 86400 (D3) |
| `included_weekdays` | the kept days, comma-joined, in the mode's axis order (first kept day first) |
| `samples_included` | matched lines on kept days |
| `samples_dropped` | matched lines on excluded days; `included + dropped = total_matched` |

Both derived fields are computed from the mode's own geometry rather than stored
per mode: `profile_window_seconds()` returns 86400 for any mode whose label
format is time-only and kept-days × 86400 otherwise, and
`profile_included_weekdays()` walks the week from the mode's first kept day.
Adding a mode therefore cannot leave either field stale.

## Implementation notes

**N1 — the fold modulus stays 604800 for every plural mode.** `fold_epoch()`
uses `$cfg->{period}` only to choose between the time-of-day branch and the
day-offset branch, so a plural mode keeps 604800 whatever its window length;
D3's window is a separate derived quantity and the modulus is no longer emitted
anywhere.

**N2 — the plural weekend anchors are the modes' own first kept day** (Saturday
172800 for `weekends`, Friday 86400 for `weekends-alt`), which places the two
kept days at day offsets 0 and 1.

**N3 — what actually asserts D2.** The failure D2 guards against is a weekend
window that *wraps*: anchoring `weekends` on Sunday puts Sat at offset 6 and Sun
at offset 0, so the axis renders all seven weekday labels with five empty days
between them. That is caught by the existing `first-weekday` and `no-excluded`
render assertions (verified by sabotage: the leftmost label becomes `Sun` and
excluded days render). A *non-wrapping* anchor change — anchoring `weekends` on
Monday, giving offsets 5 and 6 — is not observable at all: the kept days are
still adjacent, the empty backfill runs only between the folded min and max, and
the rendered output is byte-identical. No assertion was added for it, because
there is no behaviour to assert.

**N4 — the run-summary fold heading** takes its wording from
`profile_fold_phrase()`, so a plural mode reads "folded onto a single Sat-Sun
profile" rather than "a single weekends profile".

## Merge gate

The change touches `ltl` and four harness-side files: the full `tests/validate-*.sh` suite and the before/after benchmark on this machine apply (docs/process/workflow.md § Completion gate).

## Related

- #256 (time-axis folding) — the feature this extends; its doc is amended to point here for the full mode table and the corrected `-V` field.
- #454 (notice that statistics describe a filtered subset) — would want the profile drop count as an input; weekend modes drop 5 of 7 days. Relationship only, not a gate.
