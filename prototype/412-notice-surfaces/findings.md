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
- Category order and glyphs are Claude's proposal too: data anomaly `⚠`, figure
  caveat `≈`, your options `⚙`, decision taken for you `↻`, runtime condition
  `⏱`, guidance `➤` (what bears on trusting the figures first, the next step
  last); `--glyphs emoji|ascii` swaps the set.
- `notices/sets.pl` holds the fixed notice sets: *minimal* (one deprecation)
  and *typical* (seven notices over five categories), worded after the shipped
  producers, each split into statement, evidence and remedy.

## P1: deferred notices by category, before the timeline (`p1-deferred-notices.pl`)

Question: how the notices raised during the run read when they are presented
together, by category, once the data work has finished and before the
timeline is drawn.

A mock-up inside a real run: ltl's own title, a simulated progress line
finishing with ltl's completion rows, the notice surface, then the real
timeline, tables and summary of ltl run on the log given (by default the
synthetic Tomcat access fixture in `tests/fixtures/`). Three forms, each in
both visual languages:

- `lines`: one notice to a line, led by its category's glyph and name;
- `boxes`: one framed block per category, the heading and how to read it in
  the top edge;
- `sections`: a heading and rule per category, notices as bullets, the way
  ltl's messages tables are headed and listed.

```
perl p1-deferred-notices.pl                               # sections, ltl look, typical set
perl p1-deferred-notices.pl --form boxes --style new
perl p1-deferred-notices.pl --form lines --set minimal    # the two-line deprecation
perl p1-deferred-notices.pl --all                         # every form and style, no backdrop
perl p1-deferred-notices.pl --bg light --glyphs emoji --log <any log>
```

Claude's own runs (2026-10-18): every form and style at 120 and 160 columns
to a file (exit 0, nothing on stderr); boxes in the new style under a pty
replayed through Term::VT102: the progress frames are overwritten by the
completion rows and the surface sits between them and the timeline.

Architect's feedback: pending.
