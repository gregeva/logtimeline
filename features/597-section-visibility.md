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
| thread-pool summary | | present only with the thread-pool summary option |
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

## Open questions

- **Standard error.** Notices printed to standard error during render are not part
  of standard output; confirm they are excluded from the count.
- **The pause option.** Whether `-p` prompts count as lines, or the report is
  defined for runs without it.
- **The `-V` section name** and its keys.

## Acceptance criteria

To be derived from the requirements and D4 once the open questions above are
settled.
