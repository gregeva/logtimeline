# Feature: section visibility and section start lines (#597)

## GitHub Issue

[#597](https://github.com/gregeva/logtimeline/issues/597): Enhancement: section
visibility for the timeline and top messages, and a `-V` section reporting section
start lines.

Blocks [#598](https://github.com/gregeva/logtimeline/issues/598) (programmatic console
screenshot capture for documentation), specified alongside it in
`features/598-screenshot-capture.md`.

## Motivating consumer

The screenshot capture tool of #598. It crops terminal output by cell position,
anchored on the line at which a section starts. It needs two things from `ltl`: a way
to remove sections so the target sits inside the terminal's height, and a report of
where each rendered section starts, read from a `-V` probe run and applied to a
clean render run. A crop anchored on a reported start line survives any change to the
output above it.

## Requirements

1. **Hide the timeline.** A first-class option, replacing the workaround of an
   extreme bucket size that bounds the timeline to one row.
2. **Hide the top messages.** A first-class option.
3. **Report section start lines on `-V`.** A new `-V` section, following the
   `=== name ===` / `=== END name ===` convention, giving the output line at which
   each rendered section starts and ends. A hidden section is reported as absent.
   For each section the report gives where it starts, how long it is, and the blank
   rows padding its beginning and its end (architect, 2026-09-24).
4. **Override the terminal height** (architect, 2026-09-24), as `--terminal-width`
   overrides the width, so a run whose output is redirected (the #598 capture)
   behaves as it would at a given terminal height (D15).

## Decisions

**D1: sections are hidden and shown with the verbs `hide` and `show`** (architect,
2026-09-24). The verbs the column options already use (`-hl, --hide-legend`,
`-scl, --show-classification`) extend to whole sections. `omit` is not used for
visibility: it also names the options that stop a metric being extracted
(`-od, --omit-durations`).

**D2: hiding the top messages is a display control only** (architect, 2026-09-24).
The table is not printed, the same visible outcome as `-n 0`. Unlike `-n 0`, messages
are still retained, so the MESSAGES CSV, grouping (`-g`) and ranking (`-so`) keep
working. The two are parallel paths to the same screen.

**D3: every section's row count is determined before rendering** (architect,
2026-09-24). Counts are computed after read, parse and statistics (where
classification, category fill and the memory structures are settled) and before
the first rendered line, so the report is emitted with the other `-V` sections at
their usual point, before the rendered output. Every section's height is known by
then:

| Section | What sets its height |
|---|---|
| Timeline | the number of time buckets, fixed once the read is complete |
| Histogram | its calculated height, including any height given on the command line |
| Top messages | message count, header, underline, spacing; a second table when a highlight splits it |
| Thread-pool summary | the ranked pool count |
| Summary table, left column | categories (including highlighted rows), the success / failure / unclassified / unknown rows, memory structures when the memory option is on |
| Summary table, right column | the fixed rows plus the file list |

Today only the timeline counts its rows (for the pause option, `-p`); the counting
for every other section is new.

**D4: the acceptance tests anchor on static text** (architect, 2026-09-24). A test
reads a section's reported start line from `-V`, then finds known static text at a
row and column offset from it in the rendered output: for example the log-formats
legend title in the summary's file list, or the fiftieth-percentile marker in the
histogram legend. Fixtures exercise each section's variability: many files for a
long file list, a highlight to split the top-messages table, a non-default histogram
height, the memory option. Every run pins `--terminal-width` so column offsets are
deterministic.

**D5: no section owns the spacing around it** (architect, 2026-09-24). The blank
rows between sections are printed between sections, not by them: exactly one blank
row separates two rendered sections. The trailing blank row the messages tables
print and the blank row left by the statistics progress line under
`--disable-progress` are removed. Blank rows inside a section (the histogram's row
before its percentiles, the row between the two messages tables) are part of that
section and count in its length. The report gives each section's first content row
and its length. Visible consequence: the double blank row after the messages and the
extra blank row above the timeline disappear.

**D6: rows are counted from the first row the run prints** (architect, 2026-09-24).
Row 1 is the top of the title block. Positions are those of the same run without
`-V`, so a position read from a `-V` probe run applies unchanged to the capture run.

**D7: the sections, and the parts that can be hidden separately** (architect,
2026-09-24). In print order:

| Section | Parts, hideable separately through hidden values | Contents |
|---|---|---|
| `title` | | the banner block |
| `progress` | | the progress indicators (D9) |
| `timeline` | | rule, header, bucket rows, closing rule; the statistics or heatmap column is part of it |
| `histogram` | | every histogram, rendered side by side on the same rows |
| `options` | | the command-line options row, and the environment options row when present |
| `messages` | `messages-highlighted`, `messages-overall` | the highlighted-messages table (present only under a highlight) and the overall table |
| `threadpools` (D17) | `threadpools-highlighted`, `threadpools-overall` | the highlighted and overall thread-pool tables; present only with the thread-pool summary option |
| `summary` | `summary-values`, `summary-files` | the left column (categories, counters, timing, memory) and the right column (file list and log-formats legend) |

`messages` and `summary` are the public names. The messages part names follow the
table titles the tool prints (`TOP HIGHLIGHTED MESSAGES`, `TOP OVERALL MESSAGES`). The part names are hidden values:
they exist so that output can be cut to a strict minimum, for example
`--hide summary-files` so a long file list does not push the values table out of a
screenshot. The `-V` report lists the parts as separate entries so each can be
targeted on its own.

**D8: one `--hide <section>` and one `--show <section>` option** (architect,
2026-09-24). Each takes a section or part name from D7, accepts a comma-separated
list, and is additive when repeated, the way `-m` is. The per-column options
(`--hide-legend`, `--hide-stats`, and the rest) are unchanged.

**D9: `--hide progress` is exactly `--disable-progress`** (architect, 2026-09-24),
so that `--disable-progress` can one day be deprecated. Audit of what
`--disable-progress` does today: it suppresses every progress print, and it skips
the up-front size sweep of the selected files (`size_selected_files_for_progress()`,
`return if $disable_progress`), whose only consumer is the overall progress figure.
`--hide progress` does both. Differences that remain:
`--disable-progress` is a hidden option while `progress` becomes a public section
name; the stray blank row it leaves today is removed by D5.

**D10: short forms `-hi` and `-sh`** (architect, 2026-09-24):
`-hi, --hide <section>` and `-sh, --show <section>`. The option takes the section
as its value, so its short form names the verb only. Both are free, and the
parser's case-insensitive matching rules out `-H` and `-S`, which would resolve to
`-h` (highlight) and `-s` (seconds).

**D11: fixed aliases for the public section names** (architect, 2026-09-24),
following the named-alias convention metric values already use (`size` for
`bytes`, `avg` for `mean`), never prefix matching: `timeline` `tl`, `histogram`
`hg`, `messages` `msg`, `summary` `sum`, `options` `opt`, `progress` `prog`.
`title` and the hidden parts have no alias.

**D12: rows are counted on standard output only** (architect, 2026-09-24). The
one notice printed to standard output today ("Warning: unhandled date/time format -
option not taken into account", printed while options are read, so it lands between
the title and the timeline) moves to standard error with every other notice. The
"no lines matched" message printed in place of the timeline stays on standard output
as part of the timeline section. Test fixtures capture standard error separately
from standard output.

**D13: the `-V section-layout` section, tab-separated** (architect, 2026-09-24).
A header row, then one row per section and per part (D7) in print order, each with
the same four tab-separated fields:

| Field | Value |
|---|---|
| `name` | the section or part name from D7 |
| `state` | `rendered`; `hidden` (turned off by `--hide`); `absent` (the run produced nothing for it, such as highlighted messages without a highlight) |
| `start` | the first content row (D5, D6); empty unless `rendered` |
| `rows` | the row count, blank rows inside the section included; empty unless `rendered` |

A part's row follows its section's row. Side-by-side parts (`summary-values`,
`summary-files`) share a start row. Example (fields separated by tabs, which do not
align visually):

```
=== section-layout ===
name	state	start	rows
title	rendered	1	4
timeline	rendered	6	5
messages-highlighted	absent		
progress	hidden		
=== END section-layout ===
```

**D14: every row on standard output is accounted for** (architect, 2026-09-24).
There is no `verbose` entry in `section-layout`: a `-V` section can print outside
the main verbose block (`histogram-percentile-ticks` prints after the histogram,
`aggregate-export` after the summary), so no single block length is true. Instead
the harness removes every `=== name ===` ... `=== END name ===` range from standard
output wherever it printed, and requires:

    total rows - `-V` rows - reported section rows - separators - expected fixed spacing = 0

Expected fixed spacing is spacing that belongs to no section but is normal, such as
the blank row at the end of the run; the harness declares each such row by what it
is, and the assertion is on deviation from that expectation. Any other remainder is
a failure that names the rows it could not place. `-V` output prints no rows outside
its delimiters, blank padding included, so a `-V` run with its ranges removed is
identical to the same run without `-V` (D6).

**D15: a hidden `-th, --terminal-height <N>` option** (architect, 2026-09-24),
mirroring the hidden `-tw, --terminal-width`. With output redirected, `ltl` cannot
detect the terminal size, yet the height sets two defaults: the bucket size when
`-bs` is not given (120, 90, 60, 30 or 10 minutes for up to 30, 45, 65, 85 and
over 85 rows) and the histogram height when `-hgh` is not given (5, 7, 9, 11, 14
or 16 rows for under 50, 65, 80, 100, 120 and 120 or more rows; the configured
default when the height is not detected). The override makes both follow the given height, as a detected
terminal of that height would. It is here because this issue owns what the #598
capture needs from `ltl`.

**D16: a hidden section that writes a file still makes one pass over its data**
(architect, 2026-09-24). The timeline loop writes the STATS CSV rows and the
messages loop writes the MESSAGES CSV rows while they render. Each stays a single
loop that iterates once. Inside it, building and printing the terminal row is gated
on the section being visible, and the CSV write is gated on `-o`, as today. Hidden
without `-o`: the loop does not run. Hidden with `-o`: it runs and writes only the
CSV. Visible: unchanged. This is how D2 holds.

**D17: the thread-pool summary is `threadpools`** (architect, 2026-09-24), alias
`tp`, with the hidden parts `threadpools-highlighted` and `threadpools-overall`,
following `messages` (D7, D11).

**D18: the memory rows of the summary are fixed when the row counts are taken**
(architect, 2026-09-24). Under the memory option the summary lists each data
structure whose peak size is 1 KiB or more. A measurement runs when the counts are
computed (D3), and the list of structures shown is fixed then. The measurement just
before the summary prints still updates their values. A structure that first
crosses 1 KiB during rendering is not listed; its bytes stay in the unattributed row.

**D19: when `--hide` and `--show` name the same section, the later one wins**
(architect, 2026-09-24). Both options apply in the order given, `LTL_CONFIG` first,
then the command line, so a command-line `--show` undoes a `--hide` from the
environment. A section name covers its parts: `--hide summary --show summary-files`
renders only the file list.

**D20: `-osum, --omit-summary` is exactly `--hide summary`** (architect,
2026-09-24), as D9 makes `--hide progress` exactly `--disable-progress`. Both set
one flag; `section-layout` reports the summary as `hidden` under either.

## Finding: the render code the decisions act on

Read on `release/0.18.4` on 2026-09-24, before implementation.

- **Two printers also write the CSV files.** `print_bar_graph()` writes each STATS
  CSV row inside its bucket loop, and `print_message_summary()` writes each
  MESSAGES CSV row inside its message loop. Skipping a hidden printer would have
  dropped those rows (D16).
- **Only the timeline counts its rows today**, and only under `-p`: the counter in
  `print_bar_graph()` advances only when the pause option is on.
- **Every other height is settled before rendering, with two exceptions.** The
  histogram layout (`calculate_histogram_layout()`) is computed inside
  `print_histograms()` from settled data, so it can run earlier. Under the memory
  option, the summary's memory rows depend on `measure_memory_structures()`, which
  runs right before `print_summary_table()` (D18).
- **The title prints before the options are read.** `print_title()` runs in
  `## MAIN ##` before `adapt_to_command_line_options()`. `--hide title` therefore
  needs the section options read before the title prints. They are pre-read the way
  `--terminal-width` already is, so the banner still comes before `-V list` output
  and option errors.
- **Blank rows beyond those in the section-position table above.**
  `group_similar_messages()` prints an unconditional newline under
  `--disable-progress`, as `calculate_all_statistics()` does. The thread-pool
  tables end with the same trailing blank row as the messages tables. The `-V`
  output pushes blank rows around the `message-grouping` block outside its
  delimiters, against D14. The summary's leading blank row is embedded in its
  first cell.
- **Two rows are never wrapped by `ltl`:** the command-line options row and the
  log-formats legend. Where they are wider than the terminal they soft-wrap, and
  the physical rows exceed the reported count. That is #497 (output lines exceed
  the terminal width and soft-wrap); harness runs pin a width at which they fit.
- **Every regression golden changes with D5.** All 74 captures in
  `tests/reference-output/` carry three blank rows between the title and the
  timeline. They are re-captured with the spacing change, and the proof that
  nothing else moved is that old and new differ only in blank rows.

## Finding: where each section starts and ends today

Measured 2026-09-24 on `release/0.18.4` by rendering two small access-log fixtures
(a combined access log carrying a duration field, and a common access log carrying
duration, thread and session) at `--terminal-width 160` with
`-ni -hg duration -h ' 500 ' -n 3`, escape sequences stripped, and tracing which
sub printed each blank line. Sections carry no title of their own except where
noted, so a section's first row is whatever its first content happens to be.

| Rows | Content | Printed by |
|---|---|---|
| 1-5 | title block: a coloured space row, rule, banner, rule, a reset row that reads blank | `print_title()` |
| 6 | blank: the newline ending the statistics progress line, printed even under `--disable-progress` | `calculate_all_statistics()` |
| | *the `-V` block, when requested, is inserted here* | `print_verbose_output()` |
| 7 | blank, leading | `print_bar_graph()` |
| 8-12 | timeline: rule, column header, rule, one row per bucket, rule | `print_bar_graph()` |
| 13 | blank, leading | `print_histograms()` |
| 14-28 | histogram: chart title, axis label, bars, axis, tick labels, a blank row, one percentile row per population (two when a highlight splits it) | `print_histograms()` |
| 29 | blank, leading | `print_run_options()` |
| 30 | the command-line options row (an environment options row above it when a configuration is set) | `print_run_options()` |
| 31 | blank, leading | `print_message_summary()` |
| 32-36 | highlighted messages table: header, rule, rows, blank, trailing | `print_message_summary()` |
| 37-40 | overall messages table: header, rule, rows, blank, trailing | `print_message_summary()` |
| 41 | blank, leading | `print_summary_table()` |
| 42-56 | summary: rule, header, rule, category and counter rows beside the file list and the log-formats legend, rule | `print_summary_table()` |
| 57 | blank | end of `## MAIN ##` |

What this shows:

- **Every section brings its own leading blank row**; the messages tables also end
  with a trailing one, so two blank rows sit between the messages and the summary.
- **Blank rows also occur inside sections**: the histogram's row between tick labels
  and percentiles; the blank row between the two messages tables.
- **Row 6 belongs to no section**: it is the end of a progress line that is not
  printed.
- **The `-V` block sits between rows 6 and 7**, so every rendered row after it moves
  by the block's length. The same run with `-V -n 2 -osum` printed 362 rows.
- With `-hm duration` in place of statistics, the timeline's row count is unchanged;
  two histograms (`-hg duration -hg bytes`) render side by side on the same rows.

## Finding: the pause option adds no rows

`pause_for_keypress()` prints its prompt without a newline and erases it in place
with a carriage return and spaces when a key is pressed, so a run under `-p` prints
the same rows as one without it. The report needs no rule for `-p`.

## Open questions

None.

## Acceptance criteria

All assertable. Every run pins `--terminal-width`; standard error is captured
separately from standard output (D12).

- [ ] `-hi timeline` prints no timeline rows and `section-layout` reports `timeline`
      `hidden`; likewise for each section and each hidden part (D7), one at a time.
- [ ] `-hi messages` prints no messages table and the MESSAGES CSV is still written
      (D2, the difference from `-n 0`).
- [ ] `-hi progress` produces byte-identical output to `--disable-progress` on the
      same input (D9).
- [ ] For every rendered section, known static text is found at a fixed row and
      column offset from the start row `section-layout` reports (D4): for example
      the log-formats legend title in the file list, the fiftieth-percentile marker
      in the histogram legend. Checked under each section's variability: many
      files, a highlight splitting the messages table, a non-default histogram
      height, the memory option.
- [ ] Every two rendered sections are separated by exactly one blank row, owned by
      neither (D5).
- [ ] A `-V` run with every `-V` range removed prints exactly the rows of the same
      run without `-V` (D6, D14).
- [ ] A date/time option the tool cannot handle prints its warning on standard
      error, and standard output passes the accounting check below (D12).
- [ ] On every run above, total rows minus `-V` rows minus reported section rows,
      separators and declared fixed spacing equals zero (D14).
- [ ] `-hi tl,hg` and `-hi tl -hi hg` hide the same sections, and every alias
      resolves to its section (D8, D11).
- [ ] With output redirected, `-th 30` gives the bucket size and histogram height
      that a detected 30-row terminal gives, and `-th 90` those of a 90-row one (D15).
- [ ] `-hi timeline -o` and `-hi messages -o` write STATS and MESSAGES CSV files
      byte-identical to the same run without `-hi` (D16).
- [ ] With `-tpas`, `threadpools` and its two parts are reported and hideable, and
      `tp` resolves to `threadpools` (D17).
- [ ] Under the memory option, the summary's rendered rows equal the count
      `section-layout` reports (D18).
- [ ] `-hi summary -sh summary-files` renders only the file list, and
      `-sh summary -hi summary` hides the summary; a `--hide` in `LTL_CONFIG` is
      undone by `--show` on the command line (D19).
- [ ] `-osum` and `-hi summary` produce byte-identical output (D20).
- [ ] `--help` and `docs/usage.md` carry the `-hi` and `-sh` rows and agree
      (`tests/validate-help-content.sh`).
