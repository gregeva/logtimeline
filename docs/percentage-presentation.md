# Percentage Presentation

One convention for every percentage `ltl` prints. Decided 2026-08-29 while scoping #446 (overall progress), #448 (category share) and #452 (reliability column), when three independent presentations were found to be in flight at once.

## The convention

A percentage is not one number format. It is **one formatter with per-surface parameters** — precision, significance and width — that **degrades to fit** the space it is given. Every surface names its parameters in its owning feature doc; no surface renders a percentage with its own inline `sprintf`.

The formatter takes:

| Parameter | Meaning |
|---|---|
| `mode` | `significant` — a target number of significant digits (`98.2%`, `1.11%`, `0.107%`); `decimals` — a fixed number of decimals (`99.950%`); `integer` — whole percent |
| `digits` | the count for the chosen mode |
| `width` | the characters available; the formatter never exceeds it |
| `floor` | whether the value is floored (a progress figure must never read ahead of the work) or rounded (a share) |

Degradation, when the formatted value does not fit `width`: drop decimals one at a time, never below a whole percent; the `%` sign is always retained. What happens when even the whole percent does not fit is the surface's decision (the category rows drop the percentage and keep the count; a layout column truncates like any other column).

## The surfaces

| Surface | Mode | Width | Floor | Degrades by |
|---|---|---|---|---|
| Category share rows (#448) and `SUCCESS/FAILURE CLASSIFIED` rows (#453) | 3 significant digits | the row's slack after the label and count | round | decimals, then the percentage; the count never |
| Reliability column (#452) | 3 decimals — the nines matter (`99.950%` vs `99.995%`), so significance is the wrong rule | the column's budget | round | rounds then truncates with the layout engine, `%` kept at every width |
| Progress line (#446): per-file and overall | integer | 3 characters, fixed | floor | — |
| Memory breakdown rows (`-mem`) | integer with a `<1%` floor | 5 characters, fixed, parenthesised | round | — (unchanged; it fits its space) |

## Why one sub

Two percentage renderers had already diverged before this convention existed (the memory rows' `(<1%)` field and #453's three-significant-digit row value), and two more were specified without reference to either. One resolution surface per value class is a standing rule of this repository (CLAUDE.md, 2026-07-09): the formatter is one named sub, and adding a percentage anywhere means calling it with parameters, never writing a new one.
