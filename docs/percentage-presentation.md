# Percentage Presentation

One convention for every percentage `ltl` prints. Decided 2026-08-29 while scoping #446 (overall progress), #448 (category share) and #452 (reliability column), when three independent presentations were found to be in flight at once.

## The convention

A percentage is not one number format. It is **one formatter with per-surface parameters** — precision, significance and width — that **degrades to fit** the space it is given. Every surface names its parameters in its owning feature doc; no surface renders a percentage with its own inline `sprintf`.

The formatter takes:

| Parameter | Meaning |
|---|---|
| `mode` | `significant` — a target number of significant digits (`98.2%`, `1.11%`, `0.107%`); `decimals` — a fixed number of decimals (`99.95%`); `integer` — whole percent |
| `digits` | the count for the chosen mode |
| `width` | the characters available; the formatter never exceeds it |
| `floor` | whether the value is floored (a progress figure must never read ahead of the work) or rounded (a share) |

**A trailing zero is never printed.** `digits` is a target, not a padding instruction: zeros at the right-hand end of the decimals carry no information, and a reader takes a printed digit as a measured one, so `20.0%` claims a precision the value does not have. Zeros are trimmed from the right, and when trimming removes the last of them the decimal point goes too — `20.0%` is `20%`, `0.3400%` is `0.34%`, `99.950%` is `99.95%`. Digits that are not trailing are untouched: `0.034%` and `0.002%` keep every digit they carry, because those zeros are inside the number. This is ordinary numeric formatting and applies in every mode, on every surface.

Degradation, when the formatted value does not fit `width`: drop decimals one at a time, never below a whole percent; the `%` sign is always retained. What happens when even the whole percent does not fit is the surface's decision (the category rows drop the percentage and keep the count; a layout column truncates like any other column).

## The surfaces

| Surface | Mode | Width | Floor | Degrades by |
|---|---|---|---|---|
| Category share rows (#448) and `SUCCESS/FAILURE CLASSIFIED` rows (#453) | 3 significant digits | the row's slack after the label and count | round | decimals, then the percentage; the count never |
| Reliability column (#452) | 3 decimals — the nines matter (`99.95%` vs `99.995%`), so significance is the wrong rule | the column's budget | round | rounds then truncates with the layout engine, `%` kept at every width |
| Progress line (#446): per-file and overall | integer | 3 characters, fixed | floor | — |
| Memory breakdown rows (`-mem`) | integer with a `<1%` floor | 5 characters, fixed, parenthesised | round | — (unchanged; it fits its space) |

## Why one sub

Two percentage renderers had already diverged before this convention existed (the memory rows' `(<1%)` field and #453's three-significant-digit row value), and two more were specified without reference to either. One resolution surface per value class is a standing rule of this repository (CLAUDE.md, 2026-07-09): the formatter is one named sub, and adding a percentage anywhere means calling it with parameters, never writing a new one.

## Migration of the existing sites

Decided 2026-08-29. No separate issue; each site moves as part of the drop that touches it.

| Site | Today | Moves under |
|---|---|---|
| `SUCCESS/FAILURE CLASSIFIED` rows (`print_summary_table()`) | 3 significant digits, fit-to-row | #448 — **done**: the logic became `format_percentage()`, and the row calls it through `share_row_text()` |
| Memory breakdown rows (`print_summary_table()`) | integer, `(<1%)` floor, 5 characters | #448 — **done**: a call-site swap, output byte-identical |
| Per-file progress percentage (`read_and_process_logs()`) | integer, clamped | #446 — replaced by the reshaped line, which calls the formatter |
| Histogram y-axis ticks and `0%` baseline corner | integer, 3 characters | already conforms in shape; swapped to the formatter at the next touch of that renderer |

The formatter shipped under #448 as `format_percentage( $value, %params )`, where `$value` is the percentage itself. Beyond the four parameters above it takes `parens` (wrap the figure in brackets), `floor_at` with `floor_text` (below `floor_at`, the marker replaces the figure — the memory rows' `<1%` is a threshold on the raw value, not a rounds-to-zero test), and `pad` (right-align within `width`, inside the brackets where they are in use, which is what keeps `( 3%)` aligned with `(97%)`).

Outside the convention by design: `-V` diagnostic fields carrying percentages (`unclassified_pct`, consolidation reduction and eviction lines) are stability-contracted machine-read values, not presentation, and keep their shape.
