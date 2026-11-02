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

On Windows (Windows Terminal): `measure.sh` and `open-capture.sh` drive
Terminal.app and do not apply. `pattern.py`, `ltl-outputs.sh`, `to256.pl`,
`analyse.py`, `report.py`, `summary.py` and `fixed-contrast.py` run from Git
Bash as they are: `analyse.py` reads a PNG itself when `sips` is absent. The
steps, and what the Windows capture must provide, are the handover in
`features/749-terminal-colour-codes.md` § 6. Its results go to
`results/windows-terminal/`.

## Results

`results/terminal-app/`: `summary.txt`, `fixed-contrast.txt`, `osc11.txt` and
one `profile-*.txt` per profile, from Terminal.app 2.15 on macOS 26.6.2 with
every profile as shipped. Solid Colors draws each new window on a different
background, so its readings belong to the run that made them.
