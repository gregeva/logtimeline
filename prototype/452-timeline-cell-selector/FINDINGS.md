# Timeline-cell selector — findings (#452, trigger (d))

The question: can AC3 (bar-less coloured value), AC5 (centred value) and AC6
(following columns' colours unchanged) be asserted per timeline **column**, when
the decoding library (`tests/lib/rendered-output.pl`) has cell predicates but no
way to say which cells belong to which column?

**Answer: yes — demonstrated.** The `--debug-layout` table the layout engine
already prints carries each visible column's width and before/after spacing, and
accumulating them exactly as the engine spends width yields per-column cell
offsets that locate every column correctly on real rendered output.

## Method

`selector.pl`: parse the debug table into ordered `{id, start, width}` for the
visible columns; slice a decoded row (`decode_line()`) to one column's cells;
`centred_report()` states the AC5 rule (odd remainder leaves the extra space on
the left). Missing debug table, missing column id, or a slice past the row end
are hard failures, never empty results.

## Measured result

Input: `tests/fixtures/tomcat-access-duration-spread.txt`, default view,
`--terminal-width 160` and `120` (auto-hide active at 120). Driver: `check.pl`.

| Arm | What it shows | 160 | 120 |
|---|---|---|---|
| A | every visible column's header word falls inside its computed slice | 6/6 | 5/5 |
| B | bytes column: fill from its own table (256:46/34), inversion holds, extent within width | 3/3 | 3/3 |
| C | offsets sabotaged +2: slice content and fill facts change, or the selector dies loudly past the row end | 2/2 | 2/2 (loud) |
| D | #448 classes in a column slice — S5 lost colour, S6 twin shades flattened, S4 one-cell overdraw — each reads differently from the correct slice | 3/3 | 2/2 + 1 skip |
| E | centring predicate: even and left-heavy odd padding pass; right-heavy and left-aligned are flagged | 4/4 | 4/4 |

18 of 18 at width 160; 16 of 16 plus one premise-skip at 120.

## Lessons

- **`text_colour()` reads only the unfilled portion of a slice.** On a row where
  the fill covers the whole value there is nothing for the S5 arm to strip (the
  skip at width 120). For the #452 columns the premise always holds — they render
  no fill — so `text_colour()` is exactly the AC3 predicate: expected the named
  dark-green/dark-red definitions, `fill_extent() == 0`.
- **A wrong offset fails loudly.** Shifted offsets either change what the slice
  reads (detected by comparison) or run past the row end (hard die). No silent
  wrong-column read was produced in any arm.
- **The offsets track auto-hide.** The same parse locates the columns at 160 and
  at 120 with different widths and a hidden latency panel — AC6's before/after
  colour comparison and AC7-adjacent width sweeps can use one mechanism.
- AC6's discriminating form is a comparison of each following column's
  `fill_colour()`/`text_colour()` between a base-commit capture and the change,
  per column id — not a palette-index grep.

## Cost to productionise

Move `parse_debug_layout()`/`column_slice()`/`centred_report()` into
`tests/lib/rendered-output.pl` (≈70 lines, written), expose a
`render_column_report` wrapper in `tests/lib/rendered-output.sh` in the shape of
the existing `render_row_report`, and consume it from the #452 harness. Small —
the decoding and the predicates already ship; this adds only the selection.

## Exit

Trigger-(d) exit condition met: a demonstrated assertion method distinguishing
known-good from known-bad on an existing column, validated against the #448
defect classes that apply to a timeline column. AC3, AC5 and AC6 move from
*Unknown* to *Assertable* in `features/452-success-failure-percentage-columns.md`.
