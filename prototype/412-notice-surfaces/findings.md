# Notice surfaces, prototyping stage 1: findings (#412)

Stage 1 of the prototyping in `features/412-notice-surfaces.md` § Prototyping:
macOS, fixed example notices, both visual languages. Each prototype is run
live by the architect; his feedback and what Claude's own runs observed are
recorded here as they land, and the stage's findings report is written into
the feature doc from this file.

Run from this directory with Homebrew Perl. Every prototype takes
`--bg dark|light` and `--width N`.

## Shared pieces

- `lib/NoticeProto.pm` reads ltl's box glyphs (`%histogram_box_sets`), colour
  table (`@column_colors`) and title banner (`get_title_string()`) from the
  `ltl` source at run time, so the *ltl* look follows the tool. It restores the
  tty mode and shows the cursor on normal exit, `die`, Ctrl-C and TERM.
- Category colours are Claude's proposal: data anomaly orange, your options
  cyan, decision taken for you blue, figure caveat magenta, guidance green,
  runtime condition teal. On a light background each takes the darkest step of
  its `gradient_light`.

## P0: glyph sheet (`p0-glyph-sheet.pl`)

Question: which glyph, if any, heads each category, and does it render at the
width a renderer would place it at.

Shows, per category, an ASCII mark, text-presentation symbols and emoji, each
with its width from Unicode's properties (`u`) and, in a terminal, the width
the terminal actually drew (`t`, from a cursor position report after printing
it). A mismatch is shown in reverse video. Then each glyph as a category
heading in both languages: the right edge of each heading is placed by the
Unicode width, so a glyph the terminal draws differently pushes the edge out of
line.

```
perl p0-glyph-sheet.pl                       # both styles, dark background
perl p0-glyph-sheet.pl --bg light
perl p0-glyph-sheet.pl --style new --width 80
```

Claude's own runs (2026-10-18):

- Not a terminal (stdout to a file): renders, exit 0, no measurement, no
  warning on stderr.
- Under a pty with nothing answering (`script` with stdin from `/dev/null`):
  the position report goes unanswered, the 0.3 s timeout falls back to Unicode
  widths, exit 0, no hang.
- Unicode gives width 1 to two of the emoji candidates, U+1F6E0 (hammer and
  wrench) and U+1F5A5 (desktop computer), because their default presentation is
  text; terminals commonly draw them two wide. The measured column in a real
  terminal is what settles it.
- Replaying the pty capture through Term::VT102 0.91 needs the bytes decoded
  as UTF-8 first; decoded, it holds one character per cell, so a wide glyph
  occupies one cell in its model. Bearing on the unattended-capture question,
  not on P0.

Architect's feedback: pending.
