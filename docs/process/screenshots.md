# Documentation screenshots

How a screenshot of `ltl`'s output is made for the documentation, from a
description of what it should show to an entry that regenerates it at every
release. Written for the agent doing the work. Specification and decisions:
`features/598-screenshot-capture.md` (the Dxx numbers below are its decisions).

**Every screenshot in the documentation is generated.** It is an entry in
`build/screenshots.yaml`, rendered by `build/capture-screenshots.pl` into
`images/screenshots/`. Nothing is captured from a terminal window by hand, and no
image under `images/screenshots/` is edited: a change is a change to its entry,
then a regeneration. A request for a new screenshot is a new entry.

## How the tool sees `ltl`'s output

`ltl` is run with a fixed terminal size (211 columns by 53 rows unless told
otherwise), and its output is a grid of cells: rows counted from 1 at the top,
columns counted from 0 at the left. An image is a rectangle of that grid drawn as
SVG in the Terminal.app colours, with a margin around it.

The tool runs `ltl` twice, in the repository root:

1. a **probe run** with `-V section-layout`, which reports the first row and the
   row count of every section `ltl` printed;
2. a **capture run** with the same options, whose output is drawn.

Rows are chosen by **section**, so a screenshot keeps showing the same thing when
output above it grows or shrinks. Columns are chosen by **position**, counted at the
fixed width: `ltl` does not report where a section's columns are.

## Resolution: the terminal size

The terminal size is the picture's **resolution**: the number of character cells
`ltl` has to draw with. The SVG itself has no pixel resolution and stays sharp at
any zoom; what decides how much a picture can show is how many columns and rows
`ltl` was given. `ltl` scales every timeline column to the width it has and hides
the columns it cannot fit, without saying so on its output. A busy chart drawn
with too few cells is scrunched: with many wide columns sharing the width, some
become too narrow to tell their values apart, and the picture shows nothing of
them. On 5,000 lines of
an application server's access log with `-hm duration`, all columns show at 211
columns; at 120, the success and failure percentages, duration, bytes and the
heatmap itself are gone.

Terminal sizes measured in real use (macOS Terminal.app):

| Columns x rows | What it is |
|---|---|
| 158 x 40 | a window zoomed in: too small to see a full timeline's detail |
| 211 x 53 | how a full timeline is typically read: **the default** |
| 237 x 62 | higher resolution and fidelity: for a busy chart |

- Start at 211 x 53. Use 237 x 62 (`width: 237`, `height: 62`) when the chart is
  busy: many time buckets, a heatmap beside several metric columns, several
  histograms side by side. Never go below the default to make an image smaller;
  cut its columns instead.
- **Width** is the number of columns every part of a row shares.
- **Height** changes what `ltl` prints, not only how tall the image is: it sets the
  default bucket size (120, 90, 60, 30 or 10 minutes for up to 30, 45, 65, 85 and
  more rows) and the default histogram height (5 to 16 rows). When the picture
  depends on either, state it in the `ltl` string (`-bs`, `-hgh`) so it does not
  move with the size.
- **Check that nothing was hidden.** Run the capture command yourself with
  `--debug-layout`, which lists every timeline column on standard error and marks
  the ones hidden for lack of width:

  ```bash
  ./ltl --terminal-width 211 --terminal-height 53 -dbg --disable-progress --debug-layout \
      <ltl options> <log> > /dev/null 2> <scratch>/layout.txt
  grep 'auto-hidden' <scratch>/layout.txt
  ```

  Any line is a column the picture has lost: use one of the two remedies below.
  `--debug-layout` is for this check only; it does not go into the entry.
- **When a chart is too busy for its width**, there are two remedies, and they
  combine:
  1. **More cells to draw with**: the larger size, 237 x 62.
  2. **Fewer columns competing for the width**: remove the columns the picture
     does not need, so the ones it is about get their room. Columns are removed
     with their own `--hide-<column>` options; `--hide <section>` takes section
     names only and refuses a column name:

     | Option | Removes |
     |---|---|
     | `-hl`, `--hide-legend` | the legend (category breakdowns and rates) |
     | `-ho`, `--hide-occurrences` | the occurrences bar graph |
     | `-hd`, `--hide-duration` | the duration bar graph |
     | `-hb`, `--hide-bytes` | the bytes bar graph |
     | `-hc`, `--hide-count` | the count bar graph |
     | `-hcl`, `--hide-classification` | the success and failure percentages |
     | `-hst`, `--hide-stats` | the latency statistics or heatmap column |
     | `-hses`, `--hide-session` | the sessions column |
     | `-hu`, `--hide-user` | the users column |
     | `-ov`, `--omit-values` | the numbers printed on the bars |
     | `-or`, `--omit-rate` | the rate in the legend |

     `-hmw N` sets the heatmap's width when it is the subject. `docs/usage.md`
     describes each.
- An image's size on a page is separate from its resolution. A full-width image is
  about 1,550 units wide and a page shrinks it to its column, so the text gets
  smaller; cutting only the columns the picture needs keeps it readable, where
  lowering the terminal width would lose detail.

## Sections and parts

The names a crop uses, in print order. A part is a piece of a section that is
reported, and can be hidden, on its own.

| Name | What it holds | Present when |
|---|---|---|
| `title` | the banner block | always |
| `progress` | progress lines | never in a capture: the tool turns progress off |
| `timeline` | the rule, column headings, one row per time bucket, closing rule; the heatmap or statistics column is part of it | a run that matched lines |
| `histogram` | every histogram, side by side on the same rows | `-hg` |
| `options` | the options the run was given (the tool's own options are left out) | the run was given options |
| `messages` | both message tables | always, unless hidden |
| `messages-highlighted` | the top highlighted messages | `-h` or `-hpf` |
| `messages-overall` | the top overall messages | always, unless hidden |
| `threadpools` | both thread-pool tables | `-tpas` |
| `threadpools-highlighted`, `threadpools-overall` | each table on its own | `-tpas`, the first also a highlight |
| `summary` | the run summary | always, unless hidden |
| `summary-values` | the left column: categories, counters, timing, memory | as `summary` |
| `summary-files` | the right column: the file list and the log-format legend | as `summary` |

`summary-values` and `summary-files` print **side by side**: they share a start row,
and each occupies its own columns. So do the histograms of a run with more than
one metric (`-hg duration,bytes`).

## From a description to an entry

### 1. Decide what `ltl` has to print

Find the options that produce what the description asks for in `docs/usage.md` or
`./ltl --help` (its EXAMPLES block is a good start), and a log whose content shows
it in `docs/test-logs.md`. Input paths are written relative to the repository root
(`logs/...`), so the entry resolves on every development machine.

Keep the run to what the picture needs: bound the time range (`-st`, `-et`) or the
bucket size (`-bs`) so the timeline is not taller than the story needs, and remove
sections that would sit inside the crop with `--hide` (for example `--hide options`
to show the timeline and the messages without the row between them).

Choose the resolution for how busy the chart is, 211 x 53 or 237 x 62, and check
with `--debug-layout` that no column was hidden (*Resolution: the terminal size*).

### 2. Look at the whole output first

Run the tool with no crop and `--trace`, into a scratch directory:

```bash
build/capture-screenshots.pl --name look --trace --out-dir <scratch> -- <ltl options> <log>
```

`look.svg` is the whole output; the trace prints both `ltl` command lines and the
rows covered. To see the rows each section occupies, and to measure columns, run
the capture command the tool printed yourself, with `-V section-layout`, and keep
its output in a file:

```bash
./ltl --terminal-width 211 --terminal-height 53 -dbg --disable-progress -V section-layout <ltl options> <log> > <scratch>/out.txt
sed -n '/=== section-layout ===/,/=== END section-layout ===/p' <scratch>/out.txt
```

The report lists every section and part with its state (`rendered`, `hidden`,
`absent`), its first row and its row count.

### 3. Choose the rows

A crop names one section or several, in print order, and offsets:

| Key | Meaning | Example |
|---|---|---|
| `sections` | one section or part, or several in print order; the crop runs from the first one's first row to the last row of whichever named section ends last, blank rows between them included | `timeline`, `timeline,histogram` |
| `start` | rows from the first section's first row: negative reaches above it, positive skips into it | `start: 3` skips the timeline's top rule, its headings and the rule under them |
| `end` | rows from that last row, same signs; 0 by default | `end: -1` drops the closing rule |

A crop without `sections` is the whole output. Anything printed between two named
sections is in the crop; to leave it out, hide it in the `ltl` options.

### 4. Choose the columns, when one part of the width is wanted

The worked example below follows this step end to end on two side-by-side
histograms.

`cols: L,R` cuts columns. `L` counts from the left edge, which is 0. `R` counts
from the right edge when it is 0 or negative (`150,0` is column 150 to the edge;
`100,-25` is column 100 up to 25 before the edge), and is a **width** when positive
(`12,90` is 90 columns starting at column 12).

Columns are measured in the captured output, at the entry's width. Print where
each run of text starts and ends on the rows of the section:

```bash
perl -CSD -ne 's/\e\[[0-9;]*m//g; chomp; next unless $. >= FIRST && $. <= LAST;
  while (/(\S+(?: \S+)*)/g) { printf "row %d col %3d-%3d: %s\n", $., $-[1], $+[1]-1, $1 }' <scratch>/out.txt
```

and, to find the gap between two side-by-side panels, the columns that are blank on
every row of the section:

```bash
perl -CSD -ne 's/\e\[[0-9;]*m//g; chomp; next unless $. >= FIRST && $. <= LAST;
  my @c = split //; $used[$_] ||= $c[$_] ne " " for 0..$#c;
  END { print join(" ", grep { !$used[$_] } 0..$#used), "\n" }' <scratch>/out.txt
```

The gap between two panels is the run of consecutive blank columns between them
(102 to 108 for the two histograms below); single blank columns inside a panel are
also listed. FIRST and LAST are the section's first and last rows from the report. The report
prints after the output's last row, so the file's line numbers are the report's
rows.

Examples measured at 211 columns:

- Two histograms (`-hg` on a log with durations and bytes, `-hgh 8`): duration in
  columns 12 to 101, bytes in 109 to 198, 102 to 108 blank. Crops `cols: 12,90` and
  `cols: 109,90`.
- The heatmap of a timeline with `-hm duration`: its scale starts at column 159
  and it runs to the edge. Crop `cols: 159,0`.
- The summary's file list: it starts at column 49. Crop `sections: summary-files`,
  `cols: 49,0`.

**Hiding a side-by-side part does not move the other one.** `--hide summary-values`
leaves the file list at column 49 with blank columns to its left: to show the file
list alone, cut its columns. Hiding is for removing whole sections from inside a
row span, not for isolating a part.

Column positions hold only at the entry's width and while `ltl`'s layout for that
output is unchanged. Record the measured columns in the entry's comment, so a
reader can see what they were and re-measure when an image comes out wrong.

### 5. Name it

The image names compose in layers: the entry's `name`, then the sections joined
with `+`, then the crop's optional `label`:

| Crop | Image |
|---|---|
| none, or no `sections` | `NAME.svg` |
| `sections: timeline` | `NAME-timeline.svg` |
| `sections: timeline,histogram` | `NAME-timeline+histogram.svg` |
| `sections: histogram`, `label: bytes` | `NAME-histogram-bytes.svg` |

Two crops that compose the same name are an error: give one a label. Names and
labels use letters, digits, `.`, `_` and `-`. Nothing is numbered, so reordering
crops renames nothing.

### 6. Several images from one run

One entry can carry several crops: they are all cut from the same capture, which
is how a narrative points at one area of the output, then another ("the whole
timeline, then its heatmap"). Every crop of an entry is checked before any image
is written: one bad crop writes none of the entry's images.

### 7. Add the entry and regenerate it

```yaml
  # What the screenshot is for, and anything measured to build it
  # (for example the columns a crop cuts).
  - name: heatmap-5min
    ltl: -hm duration -bs 5 -st 09:00 -et 11:00 logs/AccessLogs/<log>
    background: dark
    crops:
      - sections: timeline
      - sections: timeline
        cols: 159,0
        label: heatmap
```

```bash
build/capture-screenshots.pl --manifest build/screenshots.yaml --only heatmap-5min
```

then look at every image it wrote before it is committed (*Looking at an image*
below).

## Worked example: one image per histogram

The request: *"the duration histogram and the bytes histogram of a day of
web-server traffic, as two separate screenshots."* This is how the manifest's
`access` entry was built, with the tools above; the same steps isolate any part
printed beside another (the summary's file list, a heatmap beside the timeline's
columns).

**1. The command.** A log with durations and bytes, read in microseconds, with
both histograms at a height of 8 rows (`docs/usage.md`: `-du us`, `-hg`, `-hgh`),
and the heatmap narrowed so it does not crowd the timeline (`-hm -hmw 60 -ov`).
The whole output, to see what it prints:

```bash
build/capture-screenshots.pl --name look --trace --out-dir <scratch> -- \
    -du us logs/AccessLogs/<log> -hm -hmw 60 -ov -hg -hgh 8
```

`look.svg` shows two histograms side by side under the timeline: one image
would hold both, so each needs its columns cut.

**2. The rows.** The capture command the tool printed, run with
`-V section-layout` into a file:

```bash
./ltl --terminal-width 211 --terminal-height 53 -dbg --disable-progress -V section-layout \
    -du us logs/AccessLogs/<log> -hm -hmw 60 -ov -hg -hgh 8 > <scratch>/out.txt
sed -n '/=== section-layout ===/,/=== END section-layout ===/p' <scratch>/out.txt | grep -E 'timeline|histogram'
```
```
timeline	rendered	6	28
histogram	rendered	35	14
```

The histogram section is rows 35 to 48. Both crops name `sections: histogram`:
the rows come from the report, whatever prints above.

**3. What is on those rows, and where.** The first one-liner of step 4 above, on
rows 35 to 48:

```
row 35 col  46- 66: Duration Distribution
row 35 col 144-161: Bytes Distribution
row 36 col  12- 16: Count
row 36 col  99- 99: %
row 36 col 109-113: Count
row 36 col 196-196: %
```

Two titles and two sets of axis labels: two panels, the first ending around
column 99, the second starting around 109.

**4. The exact edges.** The second one-liner, on the same rows, lists the columns
blank on every row:

```
0 1 2 3 4 5 6 7 8 9 10 11 17 97 102 103 104 105 106 107 108 114 194
```

The run 102 to 108 is the gap between the panels. The leading run 0 to 11 is blank
margin. So the duration panel is columns 12 to 101 and the bytes panel 109 to 198:
90 columns each. Step 3's output agrees: the first panel's text starts at column
12, the second's at 109.

**5. The crops.** The same section twice, each panel by its start column and its
width (a positive `R` is a width), each with a label so the two names differ:

```yaml
  # Duration and bytes histograms of a day of web-server traffic with
  # microsecond durations, one image each: the two panels print side by side
  # in the histogram section, duration in columns 12 to 101, bytes in 109 to 198.
  - name: access
    ltl: -du us logs/AccessLogs/<log> -hm -hmw 60 -ov -hg -hgh 8
    background: dark
    crops:
      - sections: histogram
        cols: 12,90
        label: duration
      - sections: histogram
        cols: 109,90
        label: bytes
```

**6. Run it and look.** `--manifest build/screenshots.yaml --only access` printed

```
<repository>/images/screenshots/access-histogram-duration.svg  rows 35-48 (histogram)  cols 12-101
<repository>/images/screenshots/access-histogram-bytes.svg  rows 35-48 (histogram)  cols 109-198
```

and each image, looked at (next section), holds one whole panel: its title, both
axes with their labels, the bars, the ticks and the percentile line, and nothing
of the other panel.

## Looking at an image

An image is checked by eye before it is committed. A person opens the SVG in a
browser. An agent turns it into a PNG and reads that, with Quick Look, which is part
of macOS and draws with the same engine as Safari:

```bash
qlmanage -t -s 1600 -o <scratch> <image>.svg      # writes <scratch>/<image>.svg.png
```

Quick Look lays an SVG out 768 units wide and cuts off the rest, and an image of
the whole 211-column width is 1,548 units wide. Scale a copy to 768 first, keeping
its proportions:

```bash
perl -pe 's/<svg ([^>]*)width="([\d.]+)" height="([\d.]+)"/($2 > 768) ? sprintf("<svg %swidth=\"768\" height=\"%.1f\"", $1, 768 * $3 \/ $2) : $&/e' \
    <image>.svg > <scratch>/view.svg
qlmanage -t -s 1600 -o <scratch> <scratch>/view.svg
```

The PNG is square, with the image at the top and white below it. For detail at the
right-hand end of a wide image, cut its columns in the recipe itself (a crop with
`cols`) rather than zooming.

## The manifest

`build/screenshots.yaml` is a mapping with one key, `screenshots`, a list of
entries. The comment above each entry says what the screenshot is for.

| Key | Required | Meaning |
|---|---|---|
| `name` | yes | the first layer of every image name; unique in the manifest |
| `ltl` | yes | the `ltl` options and input files, as one string, split as a shell splits it: `-h "POST /api"` is one argument |
| `background` | no | `dark` (default) or `light`; stating it is good practice. The tool runs `ltl` with `-dbg` or `-lbg` and draws the image on that background |
| `width`, `height` | no | the terminal size: the picture's resolution (*Resolution: the terminal size*). 211 and 53 by default; 237 by 62 for a busy chart |
| `pad` | no | the margin around each image, as CSS writes it: `1` all round, `1,2` (default) one row top and bottom and two columns left and right, `1,2,3` top, sides, bottom, `1,4,1,2` top, right, bottom, left |
| `crops` | no | a list of crops, each with `sections`, `start`, `end`, `cols`, `label`; none means the whole output |

The tool's own `--width`, `--height` and `--pad` override every entry for one run.

```bash
build/capture-screenshots.pl --manifest build/screenshots.yaml             # every entry
build/capture-screenshots.pl --manifest build/screenshots.yaml --only NAME # one entry
```

Images are written to `images/screenshots/`. A failing entry is reported and the
others still run; the run exits non-zero naming the failures.

## What the tool does with `ltl`

- It sets the terminal size, the background and `--disable-progress` itself. The
  entry's `ltl` string must not contain `-tw`, `-th`, `-lbg`, `-dbg`, `-V` or `-p`;
  the tool refuses them.
- `ltl`'s options row leaves out those options, so an image showing it shows the
  command a reader would type.
- `-o` is allowed. The files it writes are deleted after each run: at the top of
  the repository root, the files matching `*LTL-*STATS*.csv`,
  `*LTL-*MESSAGES*.csv` and `*LTL-*AGGREGATE.yaml`. That includes an earlier
  `ltl -o` export of your own left there, so keep exports elsewhere.
- `LTL_CONFIG` is ignored, so settings on the machine running the tool never change
  an image.

## Sensitive content

The repository and its documentation are public. Everything `ltl` draws is metrics
and counters except the **messages** (the text of log lines: host names, user
names, paths, identifiers, customer names) and the **file list** in the summary.
The tool prints a notice beside every image whose rows include either. Such an
image is checked before it is committed; when anything identifying shows, hide the
section, crop it out, or choose another log.

## At release

The release procedure regenerates every entry **before** the wiki is synced
(`docs/process/workflow.md` § 5), and the images are committed before any
documentation that references them. Images showing the summary's `TOTAL TIME` or
`MAXIMUM MEMORY USED` change at every regeneration; that is expected.

## When it fails

| Message | Meaning and fix |
|---|---|
| `section 'X' is absent, not rendered` | the run printed nothing for X: add the option that produces it (`-hg`, `-tpas`, `-h`) |
| `section 'X' is hidden, not rendered` | the `ltl` string hides X: remove the `--hide` |
| `unknown section 'X' (...)` | a name not in the list; the message lists the valid ones |
| `sections are named in print order` | reorder `sections` as the report lists them |
| `rows A to B fall outside the output` | an offset reaches past the first or last row |
| `... reach past the right edge` or `... at or before the left position` | `cols` does not fit the width: re-measure |
| `both write NAME.svg; a label tells them apart` | two crops compose the same image name |
| `the capture run printed N rows and the probe run M` | the two runs printed different output, so the positions do not apply: report it, it is a defect in `ltl` |
| `'-X' is not accepted on the ltl command line` | an option the tool sets itself; remove it from the entry |
