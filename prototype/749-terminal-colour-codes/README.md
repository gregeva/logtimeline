# Terminal colour codes: measurement instruments (#749)

**Question.** How does a terminal draw each kind of colour code `ltl` writes
(the sixteen basic colours, palette index 0-15, index 16-255, 24-bit) and
each emphasis (bold, faint), and what would `ltl`'s output look like with
fixed 256-colour codes instead of the basic ones? The findings and what they
mean for the decision are in `features/749-terminal-colour-codes.md` § 5;
this folder holds what produced them.

## Method

1. `ltl-outputs.sh` writes `ltl`'s output from committed fixtures (two
   timelines, the top of `--help`, one `--explain` page), as written and as
   rewritten by `to256.pl`, so every host draws the same runs.
2. `pattern.py` writes a pattern of swatches (`pattern.ans`) and a manifest of
   where each sits (`pattern.json`). Each swatch is a run of full blocks, read
   for its colour, and a word, read for its weight, drawn plain beside a
   variant: bold on each basic code and the default foreground; `38;5;N` for
   N 0-15 beside the basic code; bold over index 16-255; faint; `38;2`
   beside the 256-colour index of the same RGB; a word over a 256-colour
   fill.
3. `open-capture.sh` opens a Terminal.app window in a given profile, prints
   a file in it, captures the window with `screencapture` and closes it.
4. `analyse.py` converts a capture to sRGB, finds the cell grid from the
   pattern's marker cells, and reads each swatch: a block's median colour, a
   word's ink (pixels at least 48 from the background beside it) and its
   contrast with that background (WCAG 2).
5. `report.py` (per profile), `summary.py` (across profiles) and
   `fixed-contrast.py` (the fixed-code contrasts, and the best one colour can
   do on both Clear backgrounds) write the tables in `results/`.
6. `osc11.pl` asks the terminal for its background, as `ltl`'s
   `detect_terminal` does.
7. `to256.pl` rewrites captured `ltl` output so every colour of the sixteen,
   whether written as a basic code or as index 0-15, becomes the index 16-255
   nearest xterm's default for it (`perl to256.pl --table` prints the
   mapping). It is the "what a move would look like" arm, with no design: one
   fixed code per colour, the same on every background.
8. `profile-colours.py` decodes a Terminal.app profile's stored colours
   (background, text, bold text, the sixteen), for reading a profile's
   settings beside its captures.
9. `two-sets.py` reads the measured backgrounds from the `profile-*.txt`
   tables of both terminals and finds, per hue, the best fixed code for a set
   of dark backgrounds, a set of light ones, and one set for both: what a
   colour set chosen per background could reach.

## Running it

On macOS (Terminal.app):

```bash
./ltl-outputs.sh <ltl-output-dir>              # ltl's output from committed fixtures, as written and as fixed codes
./measure.sh <work-dir>                        # the pattern in all 12 shipped profiles; tables to results/terminal-app/
./measure.sh <work-dir> <ltl-output-dir>       # also draws ltl's output in four profiles, for looking at
```

The terminal running it needs Screen Recording permission. Captures stay in
the work directory and out of the repository (window titles carry the
user's name).

On Windows (Windows Terminal), from Git Bash:

```bash
./ltl-outputs.sh <ltl-output-dir>              # as on macOS, with the host's own ltl
./wt-measure.sh <work-dir>                     # the pattern in every shipped scheme; tables to results/windows-terminal/
./wt-measure.sh <work-dir> <ltl-output-dir>    # also draws ltl's output in every scheme, for looking at
```

`wt-measure.sh` is `measure.sh`'s counterpart. It takes the shipped schemes
from the installed Windows Terminal's `defaults.json`, and classes each
measured background light or dark by `ltl`'s rule in `schemes.txt`. `wt-capture.ps1` opens a new
Windows Terminal window in a given scheme (`wt --colorScheme`, the settings
file untouched), in which `wt-show.sh` sets the UTF-8 code page and prints
the file with `cat`; it captures the window from the screen at the display's
own scale and closes it. The pattern is drawn in a 102 by 34 window; `ltl`'s
output full screen, which holds its 55 lines where a 58-row window does not
fit on a 1080-pixel display. The other scripts run as they are: `analyse.py`
reads a PNG itself when `sips` is absent.

## Results

`results/terminal-app/`: `summary.txt`, `fixed-contrast.txt`, `osc11.txt` and
one `profile-*.txt` per profile, from Terminal.app 2.15 on macOS 26.6.2 with
every profile as shipped. Solid Colors draws each new window on a different
background, so its readings belong to the run that made them.

`results/windows-terminal/`: `summary.txt`, `fixed-contrast.txt`,
`schemes.txt` and one `profile-*.txt` per scheme, from Windows Terminal
1.24.12741.0 on Windows 11 build 26200.9711, its 14 shipped schemes as
shipped, the settings file setting neither `intenseTextStyle` nor
`adjustIndistinguishableColors`. `fixed-contrast.txt`'s best single colour
is for its first two schemes, Campbell and One Half Light.

`results/two-sets.txt`: `two-sets.py` over both terminals' backgrounds,
made with:

```bash
t=results/terminal-app; w=results/windows-terminal
./two-sets.py \
  "dark, both terminals=$t/profile-Clear-Dark.txt,$w/profile-Campbell.txt,$t/profile-Basic.txt,$t/profile-Pro.txt" \
  "light, both terminals=$t/profile-Clear-Light.txt,$w/profile-One-Half-Light.txt,$t/profile-Man-Page.txt,$t/profile-Novel.txt" \
  "light, the two defaults' light partners=$t/profile-Clear-Light.txt,$w/profile-One-Half-Light.txt" \
  "one set for all four=$t/profile-Clear-Dark.txt,$w/profile-Campbell.txt,$t/profile-Clear-Light.txt,$w/profile-One-Half-Light.txt" \
  > results/two-sets.txt
```

## The prototype of D1: a dark and a light set (macOS)

D1 (`features/749-terminal-colour-codes.md` § Decisions): when the background
is known, `ltl` writes its text colours from a dark set or a light set of
256-colour codes; when it is not, today's basic colours. These scripts design
the two sets and show them, on a realistic run, in every Terminal.app
configuration; the findings are in the feature doc § 9.

1. `design.py` designs both sets from the measured backgrounds and colours in
   `results/terminal-app/` and writes a palette file to `palettes/` (its
   docstring gives the rule). `palettes/c1.tsv` to `c6.tsv` are the
   iterations; `c6.tsv` is the selection.
2. `e-outputs.sh <out> <access-log> <palette.tsv>` runs `ltl` once on the run
   the architect validated (nine hours of one day of a web application
   access log holding an outage, 30-minute buckets, failures highlighted,
   the duration heatmap and both histograms, 190 columns) and writes the
   three palettes of D1: `basic.ans` (the fallback), `dark.ans`,
   `light.ans`, each through `e-palette.py`, checked cell by cell against
   `ltl`'s own output.
3. `e-measure.sh <work> <out>/<palette>` cycles the configurations: each
   profile with its background known (the set for that background, light or
   dark by `ltl`'s own rule from the measured background) and unknown (the
   fallback). Each window (`e-show.sh`) prints the file as a terminal shows
   `ltl`'s output, is captured at both ends and closes.
4. `read-output.py` reads every glyph's drawn colour in the captures and its
   contrast with the cell's background, grouped by the code today's `ltl`
   writes there; `--summary` and `--compare` tabulate across windows.

```bash
./design.py --out palettes/c6.tsv
./e-outputs.sh <out> <access-log> palettes/c6.tsv
./e-measure.sh <work> <out>/c6                  # CONDITIONS=known skips the fallback windows
```

`results/e-prototype/c6/`: one table per window, `summary.txt` and
`compare.txt`, Terminal.app 2.15 on macOS 26.6.2, the 11 shipped profiles but
Solid Colors.

## The sets across every surface on Windows

The fourth stage of the feature doc § 10, briefed in § 11: a candidate's
eight runs (`e-outputs.sh`, every surface in scope) in every shipped Windows
Terminal scheme, with the background known and unknown, read as on macOS.

1. `wt-measure.sh` measures every shipped scheme first. Its `schemes.txt`
   gives each scheme's background and class, which selects the set for the
   known condition.
2. `e-outputs.sh <out> <palette.tsv>` writes the eight runs with the host's
   own `ltl`. On Windows, `ltl` draws its bars and heatmap cells with `■`.
3. `wt-e-measure.sh <work> <out>/<palette>` cycles every scheme and
   condition. In each, a 190 by 51 window (`wt-e-capture.ps1`, `wt-e-show.sh`)
   prints a run a page at a time, is captured after each page and closes.
   51 rows is the most a 190-column window holds above the taskbar on a
   1920 by 1080 display at 100%. All windows are captured first, then
   `read-output.py` reads every page as on macOS.
4. `tally.py` counts, per scheme, the groups of cells below the floor, today
   against the set: text on the background and text over a fill against
   4.5:1, bars and lines against 3:1, leaving out the histogram and the
   heatmap. It is the count the feature doc § 10.1 reports: made over the
   committed macOS tables, it gives § 10.1's figures in every profile.

```bash
./wt-measure.sh <work>
./e-outputs.sh <out> palettes/s2-c4.tsv
./wt-e-measure.sh <work> <out>/s2-c4            # RUNS=, CONDITIONS= and scheme names narrow a pass; CAPTURE=no re-reads
```

`results/windows-terminal/e-prototype/s2-c4/`: one table per window,
`summary.txt`, `compare.txt` and `tally.txt`, from Windows Terminal
1.24.12741.0 on Windows 11 build 26200.9711, the 14 shipped schemes.

`design.py --light-hard` names the light backgrounds the light set must
clear, a profile measured here as `windows-terminal/<scheme>`.
`palettes/s2-c5.tsv` is the light set designed for every light background of
both hosts (the feature doc § 11.7):

```bash
./design.py --light-hard Clear-Light,windows-terminal/One-Half-Light,windows-terminal/Solarized-Light,windows-terminal/Tango-Light --out palettes/s2-c5.tsv
```
