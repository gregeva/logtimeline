# Asserting a rendered terminal surface — findings

Prototype under `prototype/README.md` trigger (d): a key requirement whose
verification method was not known. The requirement class is *"the output looks
right"* — colour, fill, alignment — which no existing harness could assert, and
which produced ten escaped defect classes across #448 and #446 — the tenth, soft wrapping, applies to every line the tool prints.

**This is a findings report. Nothing here is built into the harnesses. The
recommendation and its cost are below for the architect to decide on.**

## The question

Nine defects reached the architect from real runs, and a tenth class was named by him while this research was under way. Every one passed the
harnesses, with assertions genuinely running — `validate-summary-contribution-bar.sh`
passed 23 assertions against five simultaneous #448 defects. The question is
what a harness must read in order to catch them.

## The specimens

The validation set. A proposed method earns its cost by detecting these; one
that detects none of them is the existing approach with extra steps.

| | Defect | Shape |
|---|---|---|
| S1 | Message-table header gained a background it never had | colour |
| S2 | The bar did not invert — foreground and background at once | colour |
| S3 | Trailing zeros in the share (`20.0%`) | text |
| S4 | A 0.034 % category drawn one character wide (~2.4 % of the row) | geometry |
| S5 | A row with no bar lost its colour entirely | colour |
| S6 | Highlighted twin and plain row filled in the same shade | colour |
| S7 | A notice printed into the progress line's row | text |
| S8 | An empty file collapsed the line to one percentage | text |
| S9 | An over-long label produced 45- and 50-character rows against a 41-character budget | geometry |
| S10 | Output lines exceed the terminal width and soft-wrap, displacing every column below | geometry |

### S10 — soft wrapping (added after the specimen set was first drawn up)

**The most important one, and it was missing.** The application's entire output
model rests on known character placement. A line longer than the terminal
soft-wraps onto the next row, every line below it shifts, and every column the
reader relies on is displaced. It is a rendering failure whatever the content
says, and it applies to *every* line the application prints — not just the
surfaces a feature happens to touch.

Running the check found real defects in the shipped tool:

| Terminal width | Lines that wrap (default view) |
|---|---|
| 100 (the supported floor) | 4 |
| 110 | 2 |
| 115 | 1 |
| 120 and above | 0 |

**That table is the default view only, and measuring one view was itself the
mistake.** With `-hm` the heatmap emits 144 columns at width 90, 154 at 100,
**174 at 120**, and exactly 160 at 160 — so it overflows at every width measured
and happens to fit precisely at the width every golden is captured at. Any claim
about rendering must name the view it was measured on, and the check must run
across the views the tool can produce.

Three distinct causes:

1. **Messages-table rows overflow by 1–7 columns** at every width from 100 to
   115 — a layout miscalculation, small in size and total in effect.
2. **The heatmap** emits rules and rows far wider than the terminal at every
   width measured, by up to 54 columns: 154 at width 100, 174 at 120, and
   exactly 160 at 160 — which is why every golden shows it fitting.

   This second cause is a **width-allocation choice, not a rendering fault**. The
   heatmap width is settable (`-hmw`, default 52) and the overflow tracks it
   one-for-one: at terminal width 100, `-hmw 52` gives 154, `-hmw 40` gives 142,
   `-hmw 30` gives 103. Deriving the heatmap width from the terminal instead of
   defaulting to a constant removes it outright, and at `-hmw 20` the only lines
   still over budget are the messages-table rows. The architect has further
   width-allocation work in mind — column hiding and shrinking adapted for the
   timeline graph, and a narrower value section — which is expected to absorb
   more of this. The durable defect is the messages-table row width.

(The banner also ignores `--terminal-width` and renders at a fixed 94 columns,
but that is below the supported floor and so out of scope.)

Neither was caught by anything: the regression goldens are all captured at width
160, where the output is clean, and the hidden `--validate-layout` option emits
no layout report.

Filed as #497, at low priority: recorded because it was found, not because it
blocks anything. The value of the finding is the measurement and the method. A third defect found in the same investigation — the
messages-table headings degrade to unreadable stubs (`O.`, `.`, `.`) and stop
aligning with their columns, visible even at width 160 — is filed separately as
#498, since the heading line fits and so is not a wrapping failure.

The architect has set the **minimum supported terminal width at 100 columns**
(2026-08-30; first stated as 90 and raised the same day, to keep the defect
count manageable). That is what makes this assertable: the check runs from 100
upward. It takes the banner out of scope — it renders at a fixed 94 columns, so
it only wraps below the supported range — and leaves both remaining causes
in scope unchanged.

The check itself is `no-soft-wrap.pl`.

**Measurement traps, each of which gave a wrong answer while this was written:**
UTF-8 must be decoded before measuring (the box-drawing rules are multi-byte, so
counting bytes reports a 160-column rule as 480 and manufactures phantom
failures); SGR, OSC and other CSI escapes occupy no columns; C0 control
characters occupy no column. My first run reported 19 of 40 lines overflowing at
width 80 and every one was an artefact of counting bytes.

## Why escape-code assertions cannot see them

The existing approach greps the raw output for a sequence — `grep -q 'ESC\[48;5;196m'`.
That confirms *some* code was emitted somewhere on the line. It cannot express:

- **which cell** carries the attribute, so S4 (extent) and S9 (width) are invisible;
- **the combination** of foreground and background on one cell, so S2 (inversion) and S5 (lost colour) pass as long as any escape is present;
- **a comparison between two rows**, so S6 (identical shades) has nothing to compare;
- **the absence** of an attribute that should not be there, so S1 passes.

Worse, the grep is written *from the implementation*: when I built the bar from
the wrong colour vocabulary, I wrote assertions for the codes that vocabulary
emits. They passed. That is the failure `docs/test-driven-development.md` exists
to prevent, and no amount of escape-code grepping fixes it.

## The method: decode to cells, assert on requirements

Parse the rendered line into **one record per character cell**, each carrying the
character and its resolved foreground and background — what a terminal would
actually display. The unit an assertion reads becomes a cell, not an escape.

```
  2 '2' fg=256:0      bg=256:46
  3 'x' fg=256:0      bg=256:46
```

Predicates are then written in the architect's own words rather than in escape
codes:

| Predicate | The requirement it states |
|---|---|
| `bar_inverts()` | inside the bar the colour is the background and the text is black; outside it the colour is the foreground and there is no background |
| `fill_extent()` | how many cells the bar covers |
| `fill_colour()` | which shade fills it (and whether it is uniform) |
| `text_colour()` | what colour the unfilled text is |
| `row_width_ok()` | the row never exceeds its budget |

Files: `render-grid.pl` (decoder and predicates), `check.pl` (row-isolating
driver).

## Measured result against the specimens

Each defect was reintroduced into `ltl` and the predicates run. Correct output
first, sabotaged output second:

| | Correct reading | Sabotaged reading | Caught |
|---|---|---|---|
| S2 | `extent=41 fill=256:46` | `extent=0 fill=none` + *"unfilled cell has no colour"* | ✅ |
| S4 | `5xx extent=0` | `5xx extent=1 fill=256:124` | ✅ |
| S5 | `text=ansi:31` | `text=none` + *"unfilled cell has no colour"* | ✅ |
| S6 | plain row `fill=256:34` | plain row `fill=256:46` (same as its twin) | ✅ |
| S9 | `actual=41 OK` | `actual=45 OVERFLOW` | ✅ |
| S1 | header's cell attributes read directly | same mechanism as S5 | ✅ (not run) |
| S3, S7, S8 | — | — | text-shaped; already assertable |

| S10 | `width 120 OK` | `width 100 FAIL — 4 lines wrap` | ✅ |

**Seven of ten caught by measurement of the rendered output; the remaining three
(S3, S7, S8) are text-shaped and already assertable with plain-text checks — S7
and S8 are covered in `validate-progress-line.sh` today.** So the classes
together cover the whole specimen set.

S10 is the one that pays for itself immediately: it is a single check applicable
to *every* run of the tool at any width, it needs no per-feature assertions, and
it found live defects the moment it was written.

Two properties worth noting, because they are what make the reports usable:

- **The violation names the requirement**, not the escape: *"col 2: unfilled cell
  has no colour"*, *"filled cell text is ansi:32, expected black"*. A reader can
  act on that without decoding anything.
- **A single readable value replaces a pattern match.** `fill=256:34` versus
  `fill=256:46` is the S6 defect in one comparison — the defect the architect
  spotted in a screenshot, reduced to two values that differ.

## Two traps found while building this

Both cost time here and would cost it again:

1. **Row isolation is mandatory.** The file-details pane is printed on the same
   physical line as the summary table. Decoding the whole line pulls its colours
   into the row's attribute set and produces phantom violations. The row must be
   sliced to its budget before decoding.
2. **Label matching must be exact.** `2xx Success` prefix-matches
   `2xx Success (HL)`, so a naive match reads the wrong row and reports the
   twin's colours. Anchor on the label followed by whitespace and a digit.

The second is the same bug I shipped in the harness itself, twice.

## Cost, and the recommendation

**What exists now:** ~120 lines of Perl, written and validated against the
specimens. No dependencies, no new tooling, no change to how harnesses run.

**What productionising costs:** move `render-grid.pl` into `tests/lib/`, give it
the self-documenting assertion wrapper the other harnesses use
(`asserts` / `produced_by` / `contract`), and adopt it in the harnesses that
assert visual output. Estimated small — the decoder is done and the predicates
are the part that carries the meaning.

**Recommendation: adopt the soft-wrap check globally and immediately** — it is one check, it applies to every line of every run, it requires no per-feature work, and it is already finding defects. Then adopt the cell decoder **for the surfaces that have already failed** — the
category bar and any future bar-like rendering — and leave the rest alone until
a requirement needs it. The method is worth its cost where a requirement is
about *what the reader sees*; it is not worth retrofitting to surfaces whose
requirements are about text, which plain-text assertions already serve.

**Proportionality caveat, stated because it is the architect's call and not
mine:** some visual requirements are obvious to any tester on a single run and do
not justify machinery at all. This method is for the ones that are not — where a
defect is invisible without decoding (S6 is two greens that differ by one
palette index) or where a regression would otherwise be caught only by someone
looking at a screenshot.

## What this does not solve

- **It asserts what was rendered, not whether it is legible.** Contrast, and how
  a colour reads on a light versus dark terminal, are outside it. That was the
  reasoning behind the inversion requirement in the first place, and it remains
  a human judgement.
- **It does not replace looking at the output.** Every one of these nine defects
  was obvious in a screenshot. The method makes them *catchable in CI*; it does
  not make the screenshot unnecessary.
