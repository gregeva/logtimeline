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

**D3: each section's start and row count are measured as it prints, and reported
after the last section** (architect, 2026-09-24, replacing the earlier D3, under
which every count was determined before rendering). The screenshot capture runs
`ltl` twice, a `-V` probe run and then the capture run (#598), so no count is needed
ahead of the output. Each section marks its start as it opens. A count of the rows
printed to standard output, leaving out `-V` output wherever it prints, gives each
section's start and length. `-V section-layout` prints after the run's last row. The
printers are not restructured for it: knowing every height in advance would have
meant splitting five printers into a build and a print, which was done and reverted.

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

The timeline takes the other form of the same pass (architect, 2026-09-24): its
printer prints each row piece by piece across some forty `print` statements,
interleaved with collecting the row's CSV values, so gating each print would touch
the whole loop. A hidden timeline under `-o` runs its printer once with its
standard output sent to a null handle, and the pause option is off for that run.
The loop, the STATS CSV and the rest of the printer are unchanged. The messages
tables keep the gate inside the loop: each row is built into one string and
printed once.

**D17: the thread-pool summary is `threadpools`** (architect, 2026-09-24), alias
`tp`, with the hidden parts `threadpools-highlighted` and `threadpools-overall`,
following `messages` (D7, D11).

**D18: withdrawn** (architect, 2026-09-24). It fixed the summary's memory rows when
the counts were taken in advance. With counts measured as the summary prints (D3),
the rows reported are the rows printed.

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
- **`-V` output prints in three places.** `print_verbose_output()` prints most
  sections between progress and the timeline. `print_histograms()` prints
  `histogram-percentile-ticks` directly after the histogram, and
  `write_aggregate_export()` prints `aggregate-export` after the summary. The row
  count leaves out every `-V` range wherever it prints, so a section below the
  histogram starts on the same row with the histogram's `-V` output on or off (D3,
  D6).
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

## Implementation progress

**Step 1, spacing (D5, D12, D14).** Every printer starts with `open_section()`,
which prints the one blank row before every rendered section but the first; no
printer prints a leading or trailing blank row. What this settles for the row
counts of step 2:

- The title is four rows: the colour reset that used to open a fifth blank-looking
  row now closes the last rule. The help views keep the title as they had it.
- When shown, progress is its own section, opened after the title and ending its
  own last row after the normalisation step. Under `--disable-progress` it prints
  nothing at all.
- The options section is absent when there is neither an environment nor a
  command-line options row.
- The messages and thread-pool sections each keep one blank row between their two
  tables, inside the section, and none after the last.
- `-V` prints no blank row outside its delimiters. Checked on four option sets over
  a synthetic access log: with every `-V` range removed, each run prints exactly
  the rows of the same run without `-V`.
- The date/time warning goes through the deferred-notice path to standard error.
- The 74 regression goldens were re-captured. Against the committed ones, `diff -B`
  reports no difference in any file: 148 blank rows removed, two per file.

**Step 2, rows measured as they print (D3, D6, D13, D14).** Under
`-V section-layout`, `start_row_counting()` pushes `LTL::RowCounter`, a layer on
standard output that counts rows and leaves out every `=== name ===` ...
`=== END name ===` range wherever it prints. The title's rows, printed before the
options were read, start the count. `open_section()` records where each section
starts and closes the one before it. `open_part()` / `close_part()` mark the
highlighted and overall tables inside the messages and thread-pool printers, and
`record_side_part()` gives the summary's two columns their row counts from the
arrays the printer prints. `print_section_layout()` prints the report after the
run's closing row. Without `-V section-layout` nothing is counted, and standard
output has no layer.

The printers are not restructured. The earlier version of this step computed every
height before rendering by splitting five printers into a build and a print; it
was reverted when D3 was replaced.

`tests/validate-section-layout.sh` (12 scenarios, 63 assertions, through
`tests/section-layout/check-section-layout.pl`) checks the accounting (every row
placed, D14), static text at offsets from reported starts (D4), states, the
`-V`-stripped run against the plain run, progress shown, the date/time warning on
standard error, and that the histogram, options, messages and summary report the
same rows with the histogram's `-V` sections on and off. Shown to fail:
- the accounting check, on five doctored captures (a row removed, an extra blank
  row, the closing row removed, a report one row too long, a stray row) and on a
  copy of `ltl` whose counter also counts `-V` rows;
- the on/off comparison, on that same copy;
- the anchor check, on a wrong offset.

The shared soft-wrap check (`assert_no_soft_wrap`) measures a row by all its bytes,
so a progress row painted over in place reads as hundreds of columns wide; the
progress scenario skips it. The options row echoes every option given, so a long
`-V` list wraps it (#497); the on/off scenario uses `-V all`.

**Step 3, `--hide` / `--show` (D1, D2, D8-D11, D16, D17, D19, D20).** The options
push `[hide|show, value]` in the order given into `@section_visibility_ops`, and so
do `--disable-progress` and `-osum`, as hiding progress and the summary.
`apply_section_visibility()` resolves each name through `resolve_section_name()`
(sections, parts, and the aliases in `%section_aliases`; an unknown name exits 1
naming the public sections and their aliases). A name covers its parts, and the
later mention wins. `$disable_progress` and `$omit_summary` are then read from the
result. The options are also read early, with `pass_through` beside
`--terminal-width`, so a hidden title is known before the title prints. The title
now prints from `adapt_to_command_line_options()`, still before any informational
output or option error.

`open_section()` and `open_part()` do nothing for a hidden name. The call sites in
`pipeline_render()` skip a hidden histogram, options row, thread-pool summary or
summary. A hidden timeline under `-o` runs through `run_with_output_discarded()`
(D16, timeline form). The messages printer skips a hidden table unless `-o` needs
its CSV rows, and then prints nothing of it. A hidden summary column leaves the
other where it stands.

The harness grows to 19 scenarios and 129 assertions. Where it compares two runs,
the options row is hidden in both with `--hide options`, and the time and memory
rows, which differ between any two runs, are dropped by `drop_run_figure_rows()`
in `tests/lib/nondeterministic.sh`. That library now holds the one list of those
rows: `strip_nondeterministic()`, which `tests/validate-regression.sh` and
`tests/capture-regression.sh` each carried an identical copy of, moved there.
Re-capturing the 74 references through it reproduces the committed ones byte for
byte. Every other row must match exactly, and standard error byte for byte. Shown to fail, one change to `ltl` at a time:
- the STATS CSV check, with the discarded-output run removed;
- the no-rows check, with a hidden table's header printed;
- the progress equivalence, with `$disable_progress` not set from the section;
- the `--show` checks, with `--show` hiding.

Found while building the harness: under macOS's `/bin/bash` 3.2, a script that dies
on an unbound variable exits 0 when an `EXIT` trap is set, and the trap sees a
status of 0. Every harness that cleans up through `trap ... EXIT` can report a
crash as a pass.

## Open questions

None.

## Acceptance criteria

All assertable. Every run pins `--terminal-width`; standard error is captured
separately from standard output (D12).

- [x] `-hi timeline` prints no timeline rows and `section-layout` reports `timeline`
      `hidden`; likewise for each section and each hidden part (D7), one at a time.
- [x] `-hi messages` prints no messages table and the MESSAGES CSV is still written
      (D2, the difference from `-n 0`).
- [x] `-hi progress` produces byte-identical output to `--disable-progress` on the
      same input (D9).
- [x] For every rendered section, known static text is found at a fixed row and
      column offset from the start row `section-layout` reports (D4): for example
      the log-formats legend title in the file list, the fiftieth-percentile marker
      in the histogram legend. Checked under each section's variability: many
      files, a highlight splitting the messages table, a non-default histogram
      height, the memory option.
- [x] Every two rendered sections are separated by exactly one blank row, owned by
      neither (D5).
- [x] A `-V` run with every `-V` range removed prints exactly the rows of the same
      run without `-V` (D6, D14).
- [x] A date/time option the tool cannot handle prints its warning on standard
      error, and standard output passes the accounting check below (D12).
- [x] On every run above, total rows minus `-V` rows minus reported section rows,
      separators and declared fixed spacing equals zero (D14).
- [x] `-hi tl,hg` and `-hi tl -hi hg` hide the same sections, and every alias
      resolves to its section (D8, D11).
- [ ] With output redirected, `-th 30` gives the bucket size and histogram height
      that a detected 30-row terminal gives, and `-th 90` those of a 90-row one (D15).
- [x] `-hi timeline -o` and `-hi messages -o` write STATS and MESSAGES CSV files
      byte-identical to the same run without `-hi` (D16).
- [x] With `-tpas`, `threadpools` and its two parts are reported and hideable, and
      `tp` resolves to `threadpools` (D17).
- [x] Under the memory option, the summary's rendered rows equal the count
      `section-layout` reports (D3).
- [x] With a histogram shown, the messages and summary sections start on the same
      rows with the histogram's `-V` sections requested and not requested, and on
      the rows the same run prints without `-V` (D3, D6, D14).
- [x] `-hi summary -sh summary-files` renders only the file list, and
      `-sh summary -hi summary` hides the summary; a `--hide` in `LTL_CONFIG` is
      undone by `--show` on the command line (D19).
- [x] `-osum` and `-hi summary` produce byte-identical output (D20).
- [x] `--help` and `docs/usage.md` carry the `-hi` and `-sh` rows and agree
      (`tests/validate-help-content.sh`).
