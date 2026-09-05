# Feature: Shortened log level category totals in the legend column

## Overview

The legend column sits to the left of the occurrences bar graph. Its left part —
the *values* section — lists each log level category found in the bucket with its
total (`INFO: 1204853`); its right part carries the message rate over the error
rate. This work changes the left part only.

Those totals print as raw numbers today. On a log carrying hundreds of thousands
or millions of messages at a level, the totals grow long, and because the legend
sizes itself to its widest bucket the whole column grows with them, taking width
from everything to its right. Rendering the totals through the tool's shared
number formatter keeps the magnitude of a large count visible while leaving a
small count exact — `52` errors beside `1.2M` info messages — and stops the
column widening as volumes grow.

## GitHub Issue

- #501 (FEATURE: shorten log level category totals in the legend column using the
  count metric's number formatting) — the requirement, as amended with the
  `--precise-values` opt-out.

## Requirements

- **R1** — The legend's category totals render through the shared number
  formatter rather than as raw counts.
- **R2** — The abbreviation is the single-letter engineering prefix (`k`, `M`,
  `B`, `T`), not the longer form the shared formatter produces today.
- **R3** — The highlight twins (the `-HL` counterpart of a category) get the same
  treatment as their parent category, shortened or not shortened together.
- **R4** — `-pv`, `--precise-values` restores today's raw, unshortened totals.
- **R5** — No surface's output changes except as R7 requires. Every existing
  caller of the shared number formatter is otherwise unaffected.
- **R7** — Insignificant trailing zeros are not displayed. A shortened value of
  exactly one unit reads `1k`, not `1.0k`.
- **R6** — The legend column continues to size itself to its content, as it does
  today. The width the column reserves is the width the shortened totals actually
  occupy — so the column narrows as the shortening takes effect, and the totals
  stay aligned within it.

## Locked decisions

### D1 — The tier is a parameter on `format_number`, following `format_time` (architect, 2026-08-30)

`format_number` gains a `$format` parameter selecting the unit vocabulary, in the
same position and with the same tier names `format_time` uses. `format_time`'s
second parameter is an *input* scale — it declares whether the incoming value is
in seconds or minutes — and `format_number` takes a bare count, so there is no
input scale to declare and that parameter has no counterpart. Dropping it is the
pattern correctly applied, not a deviation from it.

```perl
sub format_number { my ($value, $format, $space, $decimals) = @_; ... }
```

| | `format_time` | `format_number` |
|---|---|---|
| 1 | `$value` | `$value` |
| 2 | `$unit` — input scale | — (no input scale: bare number) |
| 3 | `$format` | `$format` |
| 4 | `$space` | `$space` |
| 5 | — | `$decimals` |

### D2 — Three tiers, all defined, even where nothing calls one (architect, 2026-08-30)

| tier | 1,200,000 renders as |
|---|---|
| `short` | `1.2M` |
| `medium` | `1.2Mil` — today's output |
| `long` | `1.2 million` |

`long` has no caller. It is built anyway: the tier scale is standardised so that
no future reader has to guess what the third tier would be or whether it exists.

### D3 — Existing call sites state their tier explicitly; they do not rely on the default (architect, 2026-08-30)

All existing `format_number` call sites pass `'medium'` explicitly — including
those currently passing only a value, which a default would have covered. The
sweep is expected: changing the subroutine's signature means its callers change
with it, and an explicit tier at every site means the rendered vocabulary is
readable at the call rather than inferred from a default.

The two functions' *defaults* need not agree; only their parameter shape does.

### D5 — Trailing fractional zeros are a defect, fixed here (architect, 2026-08-30)

`format_number` appended the unit before stripping trailing zeros, and the strip
only fired before whitespace or end of string — so a unit suffix immediately
after the zero blocked it and `1000` rendered `1.0k`. Zeros to the right of the
decimal point are insignificant and wrong to display.

The strip now runs on the number, before the unit is appended. This changes
existing output wherever a round value is shortened (`1.0k` becomes `1k`), so
R5's byte-identity holds everywhere except this correction.

### D4 — `--precise-values` is scoped exactly as `--omit-values` is (architect, 2026-08-30)

`-pv`, `--precise-values` names the legend's values section and nothing else,
the same surface `-ov`, `--omit-values` names. It does not reach the rates beside
them, the count metric column, the summary table, or any other shortened number.

## Acceptance criteria

- **AC1** (R1, R2) — With a bucket whose category total exceeds a million, the
  legend prints the single-letter form (`1.2M`), not the raw count and not the
  `Mil` form. *Assertable* — read from rendered output on a fixture.
- **AC2** (R1) — A small total is unchanged: a category with 52 occurrences
  prints `52`. *Assertable.*
- **AC3** (R3) — A highlighted category's twin shortens with its parent; neither
  shortens while the other does not. *Assertable* — requires a fixture producing
  a highlight twin with a large count.
- **AC4** (R4) — Under `-pv`, the same bucket prints the raw totals it prints
  today. *Assertable* — before/after comparison against current output.
- **AC5** (R4, D4) — Under `-pv`, the rates on the right of the legend and the
  count metric column are unchanged from their non-`-pv` rendering. *Assertable.*
- **AC8** (R7) — A value of exactly one unit renders without a fractional zero:
  `1000` reads `1k`, `1000000` reads `1M`. *Assertable.*
- **AC6** (R5) — Every surface that formats numbers today renders byte-identical
  output after the signature change. *Assertable* — the existing harness suite
  is the instrument; a diff of full rendered output on a fixture before and after
  the change is the direct check.
- **AC7** (R6) — On a large-volume log the legend column is narrower than it is
  today, and the rows remain aligned: the width reserved matches the width the
  shortened totals occupy. *Assertable* — a rendered-output check on real data;
  a disagreement between the two sites surfaces as misalignment or as padding
  that does not shrink.

## Implementation notes

R6 is delivered by two sites, not one. The legend's category totals are built
twice: once by the width pass, in the block that calculates the maximum character
length of log level titles and counts, which measures the strings to size the
column; and once by the render pass, in the row-rendering loop's legend branch.
Both build the same string shapes today (`"$category_bucket: $occurrences "`,
and `"$occurrences "` for the twins), and both must route through the same
formatting. Changing only the render pass leaves the column reserving the width
of the unshortened numbers — the totals would shorten and the column would not,
delivering none of the width this issue exists to reclaim.

The rate values in the same legend already call `format_number`; they keep the
`medium` vocabulary they use today (D4), so the two halves of the legend will
abbreviate differently by design.

## Surfaces to update in the same change

- `print_help()` row for `-pv, --precise-values`
- `docs/usage.md` options reference row (parity enforced by
  `tests/validate-help-content.sh`)
