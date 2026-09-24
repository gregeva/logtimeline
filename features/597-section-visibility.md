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

## Open questions

- **Short forms.** `-h` and most `-h…` short forms are taken by highlight (`-h`,
  `-hpf`, `-hf`, `-hs`), heatmap (`-hm`) and the column hides. The new options need
  short forms checked against every existing one.
- **Line numbering origin.** The title prints first, then the `-V` block, then the
  rendered sections. Does the report count lines as the run prints them without
  `-V` (the capture run), and does line 1 start at the title?
- **The section set.** Which units are reported: the run-options line, the
  thread-pool summary, the summary table as one section or its two columns
  separately, the two top-messages tables when a highlight splits them.
- **Standard error.** Notices printed to standard error during render are not part
  of standard output; confirm they are excluded from the count.
- **The pause option.** Whether `-p` prompts count as lines, or the report is
  defined for runs without it.
- **The `-V` section name** and its keys.

## Acceptance criteria

To be derived from the requirements and D4 once the open questions above are
settled.
