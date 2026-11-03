# Two 24-bit colour sets, for a dark and a light background (Issue #749)

## Status

**In progress, reframed by the architect on 2026-11-03 from research to
implementation: two 24-bit colour sets, one for a dark and one for a light
background, validated (§ 12). Research done, macOS and Windows Terminal
measured and read together (§ 8); D1 locked (2026-11-03); the D1 prototype's first stage
on macOS (§ 9); a macOS candidate across every surface (§ 10.1), read in
every shipped Windows Terminal scheme (§ 11); D1 amended: tone governs and
the sets are 24-bit (§ 12); the tone-led sets accepted by the architect, the
fill pairs checked on every column (§ 12.4); the heatmap and the
histogram brought into scope (§ 12.5); the sets and the heatmap gradients
validated by the architect (§ 12.6); the histogram inherits the columns'
fills.**
Contracts in § 2 confirmed by the architect on 2026-11-02. The research is
`features/749-terminal-colour-codes-research.md`. The macOS (§ 5) and Windows
Terminal (§ 6) measurements were made on 2026-11-02 with the instruments in
`prototype/749-terminal-colour-codes/` on branch `749-24-bit-colour-sets`.
Nothing in `ltl` has changed yet.

- **Issue:** #749 (two 24-bit colour sets, for a dark and a light
  background).
- **Outcome wanted:** `ltl` writes its colours from the two validated sets
  when the background is known, and today's colours when it is not.

---

## What it is for

`docs/terminal-output.md` § Colour and emphasis sets the rule for anything
that has to hold its colour: a 256-colour or 24-bit code, never one of the
sixteen basic colours, and bold only over a 256-colour or 24-bit foreground.
The rule came from Windows Terminal's "One Half Light" scheme, where the
basic colours are repainted and bold turns them lighter at normal weight.
`ltl` itself still writes basic codes for its first six column colours, every
category colour and its help text's bold. This issue measured, on `ltl`'s own
output, what that costs today and what a move would give up (§ 4 to § 11),
and prototyped the move until the architect validated two sets (§ 12). It now
implements them: `ltl` follows its own rule wherever it knows the background.

## 1. Requirement (issue body)

Reframed by the architect on 2026-11-03: "Originally, this was a request for
research on the topic … we have gone way farther than just simply research.
And we are going to implement this … this will be essentially implementation
of two distinct 24-bit color sets for light and dark backgrounds."

Implement two distinct 24-bit colour sets in `ltl`, one for a dark background
and one for a light background. When the background is known, `ltl` writes
its colours from the set for that background; when it is not, it keeps
today's colours. The sets are those validated in § 12: every colour today's,
written as a 24-bit code and moved slightly in lightness only where it does
not read; a value over a bar black or white, whichever reads; each column's
highlighted fill apart from its plain fill; each column's heatmap gradient in
the column's own colour; the histogram taking the columns' fills; ten column
colours. Done when `ltl` writes its colours from the two validated sets when
the background is known, and today's colours when it is not. Open: the
validated sets have been read on macOS only (§ 11 read an earlier candidate).

The research requirement this replaces (whether to move, what it would give
up, for the architect to decide) is met by § 4 to § 12.

## 2. Contracts (confirmed by the architect, 2026-11-02)

| Surface | What it does today | Record |
|---|---|---|
| The repository's colour rule | A colour that has to hold its value is a 256-colour or 24-bit code, never one of the sixteen basic colours. Bold only over a 256-colour or 24-bit foreground. `ltl`'s own basic codes stay as they are until this research decides | `docs/terminal-output.md` § Colour and emphasis: "Whether `ltl` should move to 256-colour codes at all is to be researched and prototyped before anything changes" |
| Column colour table | Duration yellow (`93`), bytes green (`32`), count cyan (`36`), then blue (`34`), magenta (`35`), red (`31`), all basic. Orange, pink, teal, purple, every background and every gradient are 256-colour. A column's colour belongs to its column definition | `docs/design-language.md` § The colour table; `features/column-layout-refactor.md` § Color Scheme Requirements |
| Category colours (log levels, HTTP status classes, GC events) | One global table, all basic codes; "`ERROR` is red whoever emitted it"; every category gets a highlighted twin derived from its foreground | `features/476-per-format-log-level-declarations.md` ("Colour stays global"); `features/448-category-summary-share-and-bar.md` D2 (the bar's fill is derived from the category's foreground) |
| Success/failure colours | Named 256-colour definitions (34, 160, 178, 135), never an index into the column colour table | `features/452-success-failure-percentage-columns.md` D14 (colour by named definition, never by index) |
| Bold and underline | Only in help and explain text, plus the timeline's bold week fold; written only when `FORCE_COLOR`, `NO_COLOR` or a terminal on standard output allows it | `docs/design-language.md` § Emphasis |
| Background | Dark by default; `-lbg` or the terminal's reply selects light, `-dbg` wins over both; on light every colour takes its light-gradient steps; the terminal is asked only when something reads the answer (today the heatmap) | `docs/design-language.md` § Backgrounds; `features/665-background-setting-global.md` § 2 |
| Notice panel, ask pop-up, notice browser | On light: secondary text grey (`38;5;244`), body text black (`38;5;16`). On dark: secondary text faint, the analyst's pick bold bright white | `features/412-notice-surfaces.md` D10 (on a light background, secondary text is an explicit grey, not faint); `docs/design-language.md` § The new style |
| Documentation screenshots | The renderer takes the sixteen basic colours from Terminal.app's Clear Dark and Clear Light palettes, indices 16-255 from the xterm formula | `features/598-screenshot-capture.md` |

## Decisions

- **D1 (locked by the architect, 2026-11-03): when the background is known,
  `ltl` writes its text colours from a dark set or a light set of 256-colour
  codes; when it is not, it keeps today's basic colours.** Why (§ 8): of
  the options measured, it is the only one under which no scheme reads worse
  than today, and it reaches 4.5:1 in every hue wherever the background is
  known. The one straight 256-colour set lowers the light schemes further
  (§ 8.1). One set for both backgrounds never reaches 4.5:1 (§ 8.3). Two sets
  with the dark set for an unknown background put tmux, piped output and
  Windows' classic console on a light scheme below today. What it brings with
  it:
  - The background setting has to record whether the terminal answered;
    `%terminal` does not today (§ 8.2).
  - Windows gains only once `ltl` asks there (§ 7, Windows never asks the
    background).
  - Three palettes are kept: basic, dark and light.
  - Where the background is known, the user's scheme no longer sets these
    colours.
  - The rest of research § 1.7 follows: `summary_bar_color`, `decode_line`,
    the `-HL` twins, and the screenshot renderer's palette.
  - Bold over the default foreground (the help and explain headings): not
    covered by D1 as first locked (§ 8.4); the validated sets give it the
    profile's bold text colour (§ 12.2).
- **D1 amended (architect, 2026-11-03): tone governs, and the sets are
  written as 24-bit codes.** Each colour stays today's colour as the class's
  default Terminal.app profile draws it, moved only slightly in lightness
  where it falls short of 4.5:1 ("the results should be very close, where
  the tweak is slight"). 256-colour codes cannot hold those colours (§ 12.1),
  so the sets are 24-bit. The architect, on the tone-led sets drawn (`t2`,
  the agreed run and the ten-column run of § 12.4): "I like your new
  proposals for the color. High contrast, stays in the same tones, works
  both on dark background and light background", and on carrying them to
  the heatmap: "the work that you did here with the 24-bit color … would go
  a long way". What it changes from D1 as first locked:
  - The sets no longer reach 4.5:1 in every hue: on light, yellow, cyan and
    green stay short (§ 12.3).
  - On the schemes that darken their own colours for light (One Half Light,
    Solarized Light, Man Page, Novel), a few colours read lower with the set
    than the scheme draws them today (§ 12.3).
  - Terminal.app before macOS 26, and tmux without its RGB setting, reduce
    24-bit codes to the nearest 256-colour code (research § 6), which draws
    the drift of § 12.1.

## 3. Records found by search

Searched with `./process/find-records.sh --issues` for `@column_colors`,
`%colors`, `bs_bold`, `bs_underline`, `help_ansi_enabled`, `-lbg`,
`--light-background`, `-dbg`, `--dark-background`,
`detect_light_terminal_background`, `NO_COLOR`, `FORCE_COLOR`, `256-colour`,
`256-color`, `gradient_light`, `bright-black`, `SGR`.

**Read, and used:** `docs/terminal-output.md` (§ Colour and emphasis, the
start-up table), `docs/design-language.md` (§ The colour table, § Emphasis,
§ Backgrounds, § The new style), `features/412-notice-surfaces.md` (D6, D10),
`features/412-notice-surfaces-research.md` (the register this issue's research
follows), `features/665-background-setting-global.md` § 2,
`features/598-screenshot-capture.md` (the renderer's palette),
`features/452-success-failure-percentage-columns.md` D14,
`features/448-category-summary-share-and-bar.md` (D2, N7),
`features/column-layout-refactor.md` § Color Scheme Requirements,
`features/476-per-format-log-level-declarations.md`,
`features/653-histogram-highlight-row-light-background.md` (the percentile
band's text set to index 0 on every background),
`features/histogram-charts.md` (Criterion 21 and its log line: the highlighted
percentile row's text is "black (index 0)" on every background),
`features/heatmap.md` (the 256-colour gradients and their light steps),
`docs/architecture-patterns.md` § Run-scoped activation flags resolved once
(the background flag). Issues: #683 (a value drawn over a bar keeps a fixed
foreground colour, unreadable on dark bars), open, which § 5.5 measures;
#666 (the histogram's count highlight 51 differs from the timeline's 36),
open, which § 7 extends.

**Dismissed:**

| Record | Why |
|---|---|
| `features/463-friendly-log-level-category-names.md`, `features/475-log-level-vocabulary-completion.md`, `features/456-per-message-success-failure-indicator.md`, `features/447-message-control-character-normalisation.md`, `features/395-wgm-client-log-format.md` | Consumers of `%colors` choosing a category's colour; the table's contract is `features/476-per-format-log-level-declarations.md` |
| `features/269-output-ordering-audit.md` | The `-HL` twin loop's hash order only |
| `features/heatmap-implementation-plan.md` | The heatmap's original plan ("These use 256-color ANSI codes"); its record is `features/heatmap.md` |
| `features/504-explain-technique-topics.md`, `features/678-heatmap-udm-without-column.md` | Take a column's colour from the tool's own table or by position; no rule on colour codes |
| `features/pattern-match-file.md`, `features/21-ltl-config.md`, `features/652-load-over-time-reading.md` | Choose `bright-black` for one line of output; no rule |
| `features/225-test-harness-coverage-gaps.md` | The light-background auto-detection under a pipe, for harness fixtures |
| `features/342-redundant-logic-surfaces.md` | Notes `-lbg`/`-dbg` are booleans; the setting's contract is `features/665-background-setting-global.md` |
| `features/747-harness-checks-on-a-failed-run.md`, `features/567-discard-named-values-from-message.md` | Harness mechanics around `NO_COLOR`/`FORCE_COLOR` |
| `docs/usage.md`, `docs/explain/heatmap.md` | User text for `-lbg`/`-dbg`; same contract as `features/665-background-setting-global.md` |
| `docs/process/screenshots.md` | Screenshot entries pick `-dbg`/`-lbg`; the palette is `features/598-screenshot-capture.md`'s |
| `docs/architecture.md` | Pointers only |
| `releases/v0.9.0.md`, `v0.10.0`, `v0.12.0`, `v0.15.0`, `v0.18.6`, `v0.19.0` | Release bullets. One still describes the code: v0.9.0 skips the background query on Windows, and `detect_terminal` returns before the query when `$^O eq 'MSWin32'` (§ 7) |
| Issues #21, #225, #250, #261, #308, #438, #622 (closed) | #250 (a `-dbg` flag) is superseded by `features/665-background-setting-global.md`; #261 (the `--explain` surface) and #308 (option errors that stand out) added the bold now inventoried in the research § 1.3; the rest touch the terms in passing |

## 4. Research

`features/749-terminal-colour-codes-research.md`: what `ltl` writes, by
surface and code class (§ 1); what terminals do with each class (§ 2), with
bold and faint (§ 3) and automatic contrast (§ 4); what other tools do (§ 5);
what a move would give up (§ 6); and the points to measure (§ 7.3). Every
statement about a terminal or tool is quoted from a source and was re-checked
against it by a second pass.

## 5. Measurements: macOS Terminal.app

### 5.1 Method

- **Where:** Terminal.app 2.15 on macOS 26.6.2, every shipped profile as
  shipped. No profile sets "Use bright colours for bold text"
  (`UseBrightBold`) or "Use bold fonts" (`UseBoldFonts`), so both are at
  Terminal's defaults. The shipped default profile is Clear Dark. The system
  appearance was Dark, so Basic draws on its dark background.
- **What was drawn:** a pattern of swatches, each a run of full blocks (read
  for colour) and a word (read for ink, i.e. weight), plain beside its
  variant: bold on each basic code and on the default foreground; `38;5;N`
  for N 0-15 beside the basic code; bold over index 16-255; faint; `38;2`
  beside the 256-colour index of the same RGB; a word over a 256-colour fill.
  Four profiles also drew `ltl`'s own output, today's and rewritten (§ 5.6).
- **How it was read:** each window captured with `screencapture`, converted
  to sRGB. A block's colour is the median of its cells' inner half. A word's
  ink is the count of its pixels at least 48 (sRGB distance) from the
  background beside it. Contrast is the WCAG 2 ratio against that
  background.
- **Instruments:** `prototype/749-terminal-colour-codes/` (README there). The
  per-profile tables are in its `results/terminal-app/`.

### 5.2 What Terminal.app does with each kind of code

| Question (research § 7.3) | Measured, 12 profiles | Against Windows Terminal (`docs/terminal-output.md`) |
|---|---|---|
| Bold on a basic code | Colour unchanged on every one of the 16 codes in every profile; the word is heavier (1.12 to 1.75 times the ink) | There: the bright variant at normal weight, lighter on a light scheme |
| Bold on the default foreground (help headings, `Error:`, the week fold) | Heavier, in the profile's "Bold Text" colour: Clear Dark 10.76 to 11.78:1, Clear Light 9.12 to 10.91:1. It loses contrast where that colour does: Silver Aerogel draws bold text white on grey, 8.83 to 2.38:1; Novel 8.56 to 5.25:1; Grass 4.89 to 3.09:1 | There: lighter at normal weight |
| Bold over index 16-255 | Colour unchanged, heavier, in every profile | The same |
| `38;5;0`-`38;5;15` against the basic codes | Identical in Clear Dark and Clear Light, which define their own sixteen. In the other ten, which do not, all or 13 of the 16 differ: `38;5;N` is Terminal's built-in palette (`38;5;1` #990000), while the basic code is drawn in a colour that changes with the profile (`31` #d6492e on Basic, #bd311b on Man Page, #750000 on Ocean) | Identical on Campbell and One Half Light (§ 6.2) |
| `38;5;0` | The scheme's colour 0: slate #35424c on Clear Dark, #2d3840 on Clear Light; #000000 in the other ten | — |
| Faint | Towards the background in every profile: default text on Clear Light 9.12 to 1.77:1, on Clear Dark 10.76 to 3.21:1; `2;37` on Clear Light disappears (no pixel 48 from the background) | There: darker on both |
| `38;2;R;G;B` | Drawn exactly: equal to the 256-colour index of the same RGB, in every profile | — |
| Background query (OSC 11) | Answered: `rgb:ffff/ffff/ffff` on Clear Light, `rgb:213d/2743/33e7` on Clear Dark, so `ltl` reads Clear Light as light and writes no faint there | — |

The difference between the basic codes and `38;5;0`-`38;5;15` in ten
profiles lines up with the profile setting "Dynamic foreground colours"
(`DynamicANSIForegroundColors`): the two Clear profiles switch it off, the
others leave it at its default. That the setting is the cause is inferred;
it was not tested by switching it. Its effect is not a contrast guarantee:
on Man Page's light background it lowers `31` from 7.9 to 5.2:1 and `33`
from 2.7 to 2.3:1.

### 5.3 Contrast of the colours `ltl` writes, by profile

Each code's colour against the profile's background (WCAG 2; 4.5:1 is the
usual floor for text, 3:1 for large text):

| profile (background) | `93` duration | `32` bytes | `36` count | `34` | `35` | `31` | `33` WARN | `90` rules | `37` |
|---|---|---|---|---|---|---|---|---|---|
| Clear Dark (#292f3b) | 8.21 | 4.88 | 7.21 | 4.27 | 4.40 | 2.79 | 6.03 | 1.93 | 10.56 |
| Clear Light (#fbfbfb) | 1.58 | 2.66 | 1.93 | 3.82 | 3.80 | 4.65 | 2.15 | 5.88 | 1.64 |
| Basic, dark (#1e1e1e) | 13.52 | 7.50 | 7.97 | 2.96 | 5.11 | 3.85 | 7.82 | 5.22 | 10.92 |
| Pro (#000000) | 16.58 | 8.37 | 9.09 | 2.87 | 5.40 | 3.89 | 8.83 | 5.46 | 13.08 |
| Man Page (#fef49c) | 1.26 | 2.44 | 2.27 | 6.88 | 3.76 | 5.15 | 2.32 | 3.70 | 1.58 |
| Novel (#dfdbc3) | 1.30 | 2.39 | 2.22 | 6.17 | 3.59 | 4.79 | 2.26 | 3.50 | 1.57 |
| Silver Aerogel (#a8a8a8) | 2.15 | 2.52 | 1.75 | 4.98 | 3.21 | 4.18 | 1.72 | 3.50 | 1.98 |

Solid Colors is left out of the contrast tables: it draws each new window
on a different background (#cd4b93 in one run, #fdb813 in the next), so its
ratios belong to the window, not the profile. Every other profile gave the
same readings in two runs.

The same colours as fixed codes, each basic colour replaced by the index
16-255 nearest xterm's default for it (`93` to 226, `32` to 40, `36` to 44,
`34` to 21, `35` to 164, `31` to 160, `33` to 184, `90` to 244, `37` to
254), are the same RGB in every profile:

| profile | 226 | 40 | 44 | 21 | 164 | 160 | 184 | 244 | 254 |
|---|---|---|---|---|---|---|---|---|---|
| Clear Dark | 12.50 | 6.85 | 7.48 | 1.56 | 3.11 | 2.49 | 8.70 | 3.40 | 10.56 |
| Clear Light | 1.04 | 1.89 | 1.73 | 8.30 | 4.17 | 5.22 | 1.49 | 3.82 | 1.23 |
| Basic, dark | 15.52 | 8.51 | 9.29 | 1.94 | 3.87 | 3.09 | 10.80 | 4.22 | 13.11 |
| Man Page | 1.05 | 1.74 | 1.59 | 7.62 | 3.83 | 4.79 | 1.37 | 3.50 | 1.13 |
| Novel | 1.30 | 1.40 | 1.29 | 6.16 | 3.09 | 3.87 | 1.11 | 2.83 | 1.10 |

Read together: on every light profile, `ltl`'s duration, bytes, count and
WARN colours are below 3:1 today, and the same colours as fixed codes are
lower still (duration 1.58 to 1.04:1 on Clear Light). On dark profiles the
basic codes mostly read; the exceptions are the rules and separators (`90`,
1.93:1 on Clear Dark) and red (2.79:1). A fixed code improves the rules
(3.40:1) and makes blue unreadable (1.56:1).

### 5.4 One fixed colour for both backgrounds

No colour reaches 4.5:1 against both Clear Dark's and Clear Light's
backgrounds: the best any colour can do on both is 3.60:1, a grey whose
luminance sits between them. The best single index per hue, taking the lower
of its two ratios: yellow 100 (#878700) 3.51, green 28 (#008700) 2.86, cyan
31 (#0087af) 3.25, blue 68 (#5f87d7) 3.42, magenta 134 (#af5fd7) 3.48, red 167
(#d75f5f) 3.57, orange 166 (#d75f00) 3.53. So a move to fixed codes that
reads on both backgrounds needs two sets, one per background, as the heatmap's
`gradient_light` already does; one set serves both only at about 3.5:1.

### 5.5 Text over a fill

Contrast of a word with the fill it is written on (`ltl`'s bars write
`38;5;0` over `48;5;N`):

| fill | `38;5;0` Clear Dark | `38;5;0` Clear Light | `38;5;0` other ten | `38;5;16` everywhere |
|---|---|---|---|---|
| `48;5;184` (yellow) | 6.69 | 7.77 | 13.61 | 13.61 |
| `48;5;34` (green) | 3.50 | 4.07 | 7.13 | 7.13 |
| `48;5;20` (blue) | 1.03 | 1.13 | 1.98 | 1.98 |

`features/histogram-charts.md` and `features/653-histogram-highlight-row-light-background.md`
set this text to "black (index 0)". In the two Clear profiles index 0 is the
scheme's slate, not black, which halves the contrast on every fill. On the
blue fill (the users column, the first user-defined metric column) even true
black reads 1.98:1, which is #683 (a value drawn over a bar keeps a fixed
foreground colour, unreadable on dark bars): a foreground chosen from the
fill's luminance, as #683 asks, would be white there.

### 5.6 `ltl`'s own output

Captured in Clear Dark, Clear Light, Man Page and Basic, from the runs
`prototype/749-terminal-colour-codes/ltl-outputs.sh` makes on committed
fixtures so every host draws the same ones: a timeline of a web application
access log (duration and bytes columns, the HTTP status families in the
legend, one path highlighted), a timeline of a ThingWorx script log
(duration, bytes, count and users columns, in `93`, `32`, `36`, `34`; one
message family highlighted), the top of `ltl --help` and `ltl --explain
contribution-highlighting` under `FORCE_COLOR`. Each is drawn as written today
and as rewritten to fixed codes by `to256.pl`. The same views were first
captured on two corpus logs and read the same way. What the captures show
matches § 5.2 and § 5.3:

- **Clear Light, today:** the duration values (`93`), the count values
  (`36`), the explain page's message-table titles (bold `36`) and the run
  summary's file details (`37`) are faint against white; the help headings
  are heavier and darker than the text, and read.
- **Clear Light, fixed codes:** the duration values and the occurrence bars'
  yellow (1.58 to 1.04:1), bytes (2.66 to 1.89:1) and the rules (5.88 to
  3.82:1) get paler; the red ERROR legend reads slightly better (4.65 to
  5.22:1).
- **Clear Dark, today:** the rules, separators and the command-line options
  line (`90`) are dim; the users column's values over the blue fill are
  unreadable.
- **Clear Dark, fixed codes:** the rules read; the ERROR legend gets darker
  and harder to read (2.79 to 2.49:1); the users column's values turn black
  on blue (1.03 to 1.98:1), still unreadable.

In the fixed-code views, `to256.pl` drew every `90` and `91` that `ltl`
follows with its non-standard `109` in the default foreground, not in 244
and 196. Those are the rules, separators, column headings and options line,
and the per-minute rates. So what the bullets above say about the rules in
the fixed-code views comes from the pattern's readings (§ 5.3), not from the
views. `to256.pl` is corrected on the issue branch.

The captures stay out of the repository (their window titles carry the
user's name); `ltl-outputs.sh` and `measure.sh` remake them.

### 5.7 The issue's open item: non-default schemes on macOS

Yes, on Terminal.app's shipped schemes. On its light ones (Clear Light, Man
Page, Novel, Silver Aerogel), `ltl`'s duration colour reads 1.26 to 2.15:1,
count 1.75 to 2.27:1 and bytes 2.39 to 2.66:1. The cause is not bold, which
Terminal.app does not brighten: the scheme's own yellow, cyan and green are
pale against a light background, and the fixed-code versions of the same
hues are paler still. Linux terminals were not measured.

## 6. Measurements: Windows Terminal

Measured on 2026-11-02 by a Claude session on the Windows development host,
as the architect assigned, from the brief this section held (git history of
this file, e4d0e49b).

### 6.1 Method

- **Where:** Windows Terminal 1.24.12741.0 (ARM64) on Windows 11 25H2, build
  26200.9711; display 1920 by 1080 at 100% scale (96 DPI). Each window opened
  from the default profile (Windows PowerShell) with its command replaced by
  the capture's, and its colour scheme set for that window with
  `wt --colorScheme`, so the settings file was left as it is. It sets no font
  face or size (Windows Terminal's defaults apply; the measured cell is 9 by
  19 pixels), and neither `intenseTextStyle` nor
  `adjustIndistinguishableColors` (absent: the defaults apply, research § 3.1
  and § 4). Schemes as shipped: Campbell, the default (background #0c0c0c),
  and One Half Light (#fafafa).
- **What was drawn:** the pattern of § 5.1 in a 102 by 34 window, and the
  four `ltl` runs of § 5.6, made by the host's own `ltl` from the committed
  fixtures, as written and rewritten to fixed codes, on both schemes. `ltl`'s
  output was drawn full screen (56 rows): a 120 by 58 window does not fit on
  this display, and every output is 55 lines or fewer, so nothing scrolled.
  Native `ltl` on Windows does not ask the terminal for its background (§ 7),
  so every run is drawn for dark on both schemes, which is what a user
  without `-lbg` sees.
- **How it was read:** as § 5.1, from the screen's own pixels
  (`Graphics.CopyFromScreen`, no colour conversion). Two runs gave identical
  readings on every one of the 181 swatches on both schemes. The readings
  reproduce the One Half Light table in `docs/terminal-output.md` § Colour
  and emphasis: bold default text #4f525d (79,82,93), faint #1c1d21
  (28,29,33), `2;38;5;184` #6b6b00 (107,107,0).
- **Instruments:** `wt-measure.sh`, `wt-capture.ps1` and `wt-show.sh` in
  `prototype/749-terminal-colour-codes/` on branch `749-24-bit-colour-sets`
  (4deb31bf); the tables are in its `results/windows-terminal/`.

### 6.2 What Windows Terminal does with each kind of code

| Question (research § 7.3) | Campbell | One Half Light | Terminal.app (§ 5.2) |
|---|---|---|---|
| Bold on a basic code | `30`-`37` drawn in their bright variant (`1;31` is `91`'s #e74856) at the same weight (ink 1.00 to 1.02 times); `90`-`97` unchanged. The bright variant has more contrast here: `31` 3.23 to 5.09, `34` 2.38 to 4.95 | The same, ink 0.97 to 1.00 times; the bright variant has less contrast here: `33` 3.09 to 1.66, `32` 3.07 to 1.93, `34` 4.00 to 2.26, `35` 5.86 to 2.85, `36` 3.30 to 2.29 | Colour unchanged, heavier (1.12 to 1.75 times) |
| Bold on the default foreground | #cccccc to #f2f2f2, 12.18 to 17.47:1, same weight (1.02) | #383a42 to #4f525d, 10.86 to 7.46:1, same weight (1.00) | Heavier, in the profile's Bold Text colour |
| Bold over index 16-255 | Colour unchanged, heavier (1.12 to 1.13 times) | The same | The same |
| `38;5;0`-`38;5;15` against the basic codes | Identical on all 16 | Identical on all 16 | Identical in Clear Dark and Clear Light; 13 or 16 differ in the other ten |
| `38;5;0` | #0c0c0c, the scheme's black, which is its background | #383a42, the scheme's black, which is its text colour | Clear: slate; the other ten: #000000 |
| `37` and `97` | #cccccc, #f2f2f2 | #fafafa, the background itself (1.00:1); #ffffff (1.04:1) | — |
| Faint | Towards the background: default text 12.18 to 3.41:1, `33` 7.47 to 2.41, `38;5;184` 12.68 to 3.47 | Darker: default text 10.86 to 16.13:1, `33` 3.09 to 8.93, `38;5;184` 1.48 to 5.40; `2;37` turns invisible text into #7d7d7d (3.94:1) | Towards the background in every profile |
| `38;2;R;G;B` | Drawn exactly: equal to the index 16-255 of the same RGB | The same | The same |
| Contrast adjustment | — | None: `37` stays #fafafa on #fafafa, `33` is the scheme's #c18301, `38;5;226` #ffff00 (1.03:1), `38;5;184` #d7d700. So the effective `adjustIndistinguishableColors` is `never`, or `automatic` outside high contrast (research § 7.3, point 7) | — |
| Background query (OSC 11) | Not measured: native `ltl` does not ask on Windows (§ 7) | Not measured | Answered |

### 6.3 Contrast of the colours `ltl` writes, by scheme

Each code's colour against the scheme's background (WCAG 2; 4.5:1 for text,
3:1 for large text), with § 5.3's Clear profiles beside them:

| scheme (background) | `93` duration | `32` bytes | `36` count | `34` | `35` | `31` | `33` WARN | `90` rules | `37` |
|---|---|---|---|---|---|---|---|---|---|
| Campbell (#0c0c0c) | 16.91 | 5.71 | 6.14 | 2.38 | 2.44 | 3.23 | 7.47 | 4.31 | 12.18 |
| One Half Light (#fafafa) | 1.66 | 3.07 | 3.30 | 4.00 | 5.86 | 3.51 | 3.09 | 7.46 | 1.00 |
| Clear Dark (#292f3b) | 8.21 | 4.88 | 7.21 | 4.27 | 4.40 | 2.79 | 6.03 | 1.93 | 10.56 |
| Clear Light (#fbfbfb) | 1.58 | 2.66 | 1.93 | 3.82 | 3.80 | 4.65 | 2.15 | 5.88 | 1.64 |

The same colours as the fixed codes of § 5.3:

| scheme | 226 | 40 | 44 | 21 | 164 | 160 | 184 | 244 | 254 |
|---|---|---|---|---|---|---|---|---|---|
| Campbell | 18.22 | 9.99 | 10.90 | 2.28 | 4.54 | 3.62 | 12.68 | 4.95 | 15.39 |
| One Half Light | 1.03 | 1.88 | 1.72 | 8.23 | 4.13 | 5.17 | 1.48 | 3.78 | 1.22 |

Read together: on One Half Light, `ltl`'s duration colour reads 1.66:1, its
bytes, count and WARN colours about 3:1, and `37` does not show at all; the
fixed codes lower yellow, green and cyan further (226 at 1.03:1), lift `37`
only to 1.22:1, and raise blue and red (21 at 8.23:1, 160 at 5.17:1). On
Campbell the basic codes read except blue (2.38:1), magenta (2.44:1) and red
(3.23:1); the fixed codes raise magenta, red and the rules, and leave blue at
2.28:1.

### 6.4 One fixed colour for both schemes

No colour reaches 4.5:1 against both Campbell's and One Half Light's
backgrounds: the most any colour reaches on both is 4.33:1, against 3.60:1
for the Clear pair, because these two backgrounds are further apart. The
best single index per hue, taking the lower of its two ratios: yellow 100
(#878700) 3.66, green 28 (#008700) 4.16, cyan 30 (#008787) 4.18, blue 63
(#5f5fff) 4.25, magenta 163 (#d700af) 4.20, red 196 (#ff0000) 3.83, orange 130
(#af5f00) 4.15. For cyan, blue, magenta, red and orange the best index
differs from the Clear pair's (§ 5.4): which single colour serves both
depends on the pair of backgrounds, not only on the hue.

### 6.5 Text over a fill

| fill | `38;5;0` Campbell | `38;5;0` One Half Light | `38;5;16` both |
|---|---|---|---|
| `48;5;184` (yellow) | 12.68 | 7.35 | 13.61 |
| `48;5;34` (green) | 6.64 | 3.85 | 7.13 |
| `48;5;20` (blue) | 1.85 | 1.07 | 1.98 |

As in Terminal.app's Clear profiles, index 0 follows the scheme: on One Half
Light it is the scheme's #383a42, which roughly halves the contrast on every
fill; on Campbell it is #0c0c0c, close to black. On the blue fill no black
reads on either scheme (#683, a value drawn over a bar keeps a fixed
foreground colour, unreadable on dark bars).

### 6.6 `ltl`'s own output

Read by eye in the captures; the captures stay out of the repository and
`wt-measure.sh` remakes them. The codes named are the ones in the captured
runs.

- **One Half Light, today:** the run summary's file details and its
  `Log Formats` heading and list (`37`, `4;37`) do not show: only the
  marker's fill and the blue index numbers remain. The duration values
  outside their bar, the highlighted-messages title and the 4xx category
  entry (`93`, 1.66:1) are pale, the 4xx legend entries (`33`, 3.09:1) less
  so. The help headings (bold over the default
  foreground) are drawn lighter than the text around them at the same
  weight, so they recede; the explain page's message-table titles (bold
  `36`) turn the paler bright cyan (#56b5c1, 2.29:1). The users column's
  values over its blue fill do not read (1.07:1).
- **One Half Light, fixed codes:** the file details show, barely (254,
  1.22:1); the yellow, green and cyan text gets paler (226 at 1.03:1); the
  explain titles turn heavier but stay pale cyan; the 5xx legend and
  category entries read better (`31` to 160, 3.51 to 5.17:1). The help headings do not change: they are
  bold over the default foreground in both.
- **Campbell, today:** the rules, separators and the command-line options
  line (`90`, 4.31:1) are dimmer than the text but read; the 3xx legend and
  category entries (`35`, 2.44:1) are dark; the users column's values over
  the blue fill are close to invisible (1.85:1). The help and explain
  headings stand out by brightness (#f2f2f2 against #cccccc), not by weight.
- **Campbell, fixed codes:** the rules and the options line are brighter
  (244, 4.95:1); the explain titles turn heavier; the users column's values
  stay unreadable (1.98:1).

As in § 5.6, the fixed-code views drew the `90` rules and options line and
the `91` rates in the default foreground (`to256.pl` reset them after `ltl`'s
`109`). The 244 reading above is the pattern's (§ 6.3), not the views'.

## 7. Observations from the code reading

Observations, not findings: each is a difference between the code and a
record, or between two records, raised as a question before anything is
called a defect.

- **Bold over basic codes.** `docs/terminal-output.md`: "Bold is applied only
  over a 256-colour or 24-bit foreground." The code writes bold over the
  default foreground (`bs_bold`, the week fold, `print_usage_error`), over
  `37` (the notice focus), `97` (the dark `pick`) and `36` (the explain
  message titles). The same section defers the help-text case to this issue.
- **Underline outside help.** `docs/design-language.md` § Emphasis: bold and
  underline "appear only in help and explain text". The run summary's file
  details and `Log Formats` headings and the latency column's CV cell write
  `4;37`.
- **`NO_COLOR`** turns off only the help text's bold and underline
  (`help_ansi_enabled`); the run's colours ignore it.
- **The light dimmed layer** (`notice_light_dimmed_sgr`) blends each colour
  half way to white from xterm's default for the sixteen (`@notice_xterm16`),
  not the scheme's: in Clear Light, `33` is drawn #c4ac62 but blended from
  #cdcd00.
- **Windows never asks the background.** `docs/terminal-output.md`'s start-up
  table: "Windows Terminal answers"; `detect_terminal` returns before the
  query when `$^O eq 'MSWin32'`, so native `ltl` on Windows reads dark unless
  `-lbg` is given, and writes faint on a light scheme.
- **Highlight numbers and strings.** For cyan, blue and magenta the
  histogram's `highlighted_bg_num` (51, 27, 207) differs from the
  `highlighted_bg` string the timeline writes (36, 21, 201). #666 (the
  histogram's count highlight 51 differs from the timeline's 36) covers cyan
  only.
- **`-HL` twins.** The twin loop gives a highlight background only to
  `0;31`-`0;35`; `AUDIT`/`CREATE` (`0;36`) and every bright key get `49`.
- **A move's knock-on.** `summary_bar_color` finds a category's bar colour
  from the last digit of a `3N`/`9N` code, so a category moved off basic
  codes draws no bar; `tests/lib/rendered-output.pl` (`decode_line`) has no
  case for `38;2`. Both are research § 1.7.
- **SGR `109`** is written after every bright code; it is in no defined SGR
  range.

## 8. The two terminals read together

### 8.1 Today against a straight move

Each colour `ltl` writes, against the default dark and the light scheme of
each terminal (§ 5.3, § 6.3), as written today and as the fixed code of the
same name (`to256.pl`):

| colour | Clear Dark | Campbell | Clear Light | One Half Light |
|---|---|---|---|---|
| `93` duration, as 226 | 8.21, 12.50 | 16.91, 18.22 | **1.58, 1.04** | **1.66, 1.03** |
| `32` bytes, as 40 | 4.88, 6.85 | 5.71, 9.99 | **2.66, 1.89** | 3.07, **1.88** |
| `36` count, as 44 | 7.21, 7.48 | 6.14, 10.90 | **1.93, 1.73** | 3.30, **1.72** |
| `34` blue, as 21 | 4.27, **1.56** | **2.38, 2.28** | 3.82, 8.30 | 4.00, 8.23 |
| `35` magenta, as 164 | 4.40, 3.11 | **2.44**, 4.54 | 3.80, 4.17 | 5.86, 4.13 |
| `31` red, ERROR, as 160 | **2.79, 2.49** | 3.23, 3.62 | 4.65, 5.22 | 3.51, 5.17 |
| `33` WARN, as 184 | 6.03, 8.70 | 7.47, 12.68 | **2.15, 1.49** | 3.09, **1.48** |
| `90` rules, as 244 | **1.93**, 3.40 | 4.31, 4.95 | 5.88, 3.82 | 7.46, 3.78 |
| `37` file details, as 254 | 10.56, 10.56 | 12.18, 15.39 | **1.64, 1.23** | **1.00, 1.22** |

Bold: below 3:1. Below 3:1, today 11 of the 36, fixed 13: on the two dark
schemes 4 become 3, on the two light schemes 7 become 10. Below 4.5:1, today
22, fixed 20. A straight move helps the dark schemes, except blue, and makes
the light schemes worse in yellow, green, cyan and WARN, the colours of the
duration, bytes and count columns. On a light scheme the basic colours fail,
and the same hues as fixed codes fail by more.

### 8.2 What the background setting reaches today

The background is settled by `-lbg` or `-dbg`. Without either, the terminal is asked
(`detect_terminal`, OSC 11) only when the heatmap is on
(`adapt_to_command_line_options`), never on Windows, and never with no
terminal on standard input and output. A terminal that does not answer reads
dark, and `%terminal` does not record whether an answer came. The setting is
read by the heatmap's gradients and by `notice_style`. It is not read by the
column colours, the category colours, the rules or the run summary: the two
timelines of § 5.6 written with `-lbg` and with `-dbg` are identical but for
the `-V` record (`light_bg`, timings). Asking costs 35 to 49 ms in Windows
Terminal and the classic console host (`docs/terminal-output.md`, the
start-up table).

### 8.3 What a colour set chosen per background can reach

The best index 16-231 per hue: the one whose lowest contrast across the
backgrounds named is highest. Computed by `two-sets.py` from the measured
backgrounds; table in `results/two-sets.txt` (the xterm colours are drawn
exactly by both terminals, § 5.2, § 6.2):

| hue | dark: Clear Dark, Campbell, Basic, Pro | light: Clear Light, One Half Light | light, with Man Page and Novel | one set for all four of § 8.1 |
|---|---|---|---|---|
| yellow | 227 #ffff5f 12.61 (11 of 15 reach 4.5) | 58 #5f5f00 6.44 (2: 58, 94) | 58 4.82 (1) | 100 #878700 3.51 |
| green | 155 #afff5f 11.06 (19 of 21) | 22 #005f00 7.63 (2: 22, 28) | 22 5.71 (1) | 28 #008700 2.86 |
| cyan | 87 #5fffff 11.02 (11 of 15) | 23 #005f5f 7.18 (2: 23, 24) | 23 5.37 (2) | 31 #0087af 3.25 |
| blue | 75 #5fafff 5.79 (1 of 12) | 17 #00005f 17.27 (8) | 12.92 (5) | 68 #5f87d7 3.39 |
| magenta | 207 #ff5fff 5.33 (2 of 21) | 53 #5f005f 12.18 (9) | 9.12 (6) | 134 #af5fd7 3.48 |
| red | 209 #ff875f 5.68 (3 of 9) | 52 #5f0000 13.53 (4) | 10.13 (3) | 167 #d75f5f 3.53 |
| orange | 215 #ffaf5f 7.38 (5 of 8) | 130 #af5f00 4.51 (1) | 3.38 (0) | 166 #d75f00 3.53 |
| grey | 247-255 | 232-242 | 232-240 | none |

So a set chosen for dark backgrounds reaches 4.5:1 in every hue on both
terminals' dark schemes, though only one blue does (75, not the straight
move's 21). A set chosen for light backgrounds reaches it in every hue on
both terminals' light schemes, narrowly: yellow, green and cyan only as dark
shades (olive, dark green, dark teal), so on light the duration column is no
longer yellow to the eye. One set for both never reaches 4.5:1, at 2.86 to
3.53 at best.

### 8.4 Bold

Bold over a basic code: Windows Terminal draws the bright variant at the same
weight (§ 6.2); Terminal.app keeps the colour and adds weight (§ 5.2). Bold
over an index 16-255 adds weight in its colour in both. Bold over the
default foreground (the help and explain headings) is heavier in
Terminal.app, brighter on Campbell, and lighter on One Half Light (10.86 to
7.46:1), where the headings recede. A fixed code can replace the default
foreground only once the background is known.

## 9. The prototype of D1 on macOS: first stage

This stage covered only text on the window's background in one timeline
run. The architect's review widened the scope (§ 10).

### 9.1 What it shows, and how

The architect's direction (2026-11-03): the three palettes of D1, each in
the terminal conditions it is meant for and the fallback, shown on real
`ltl` output, cycled through the terminal configurations automatically,
iterated until the colours hold, and only the selection presented.

- **The run** (validated by the architect in a live window): a whole-day
  web application access log carrying execution time in microseconds, the
  day of an outage, `-du us -st 04:00 -et 13:00 -bs 30m -n 4 -hf -hm
  duration -hg` at 190 columns. Every colour class `ltl` writes is in it:
  the metric columns, the HTTP families in the legend and the category
  summary, highlighted fills, the heatmap, both histograms, the rules, the
  run summary.
- **The configurations:** each shipped Terminal.app profile but Solid Colors
  (its background changes with each window), in two conditions:
  background known, which shows the set for the profile's background (light
  or dark by `ltl`'s own rule in `detect_terminal`, BT.709 luma above one
  half, applied to the measured background), and background unknown, which
  shows the fallback, today's colours. Nothing is detected at run time: the
  condition is set, so the fallback is exercised too.
- **The windows:** 190 by 59; the output is printed as a terminal shows
  `ltl`'s (the top, then the rest, ending scrolled to the bottom), captured
  at both ends and closed.
- **The reading:** every glyph's drawn colour is read in the captures and
  its WCAG 2 contrast taken with the cell's own background (the window's,
  or the fill behind it), grouped by the code today's `ltl` writes in that
  cell.
- **The rewrite** is checked cell by cell against `ltl`'s output: every
  character and attribute kept, every colour as the palette says.
- **Instruments:** `design.py`, `e-outputs.sh`, `e-palette.py`,
  `e-measure.sh`, `e-show.sh`, `read-output.py` in
  `prototype/749-terminal-colour-codes/` (README there); iterations in its
  `palettes/`, the selection's readings in `results/e-prototype/c6/`.

### 9.2 How a set is chosen

`design.py`, from the measured backgrounds and colours of § 5:

- **What a set covers:** every colour `ltl` writes as text on the window's
  background. That is the sixteen scheme colours, and `ltl`'s own fixed
  256-colour text codes where they fail on that background. A fixed code
  takes the code of the colour it belongs with: success with green, failure
  with red, the users count with blue, the percentile lines with the
  duration yellow. Fills, bars, histograms and the heatmap stay as `ltl`
  draws them.
- **Text over a fill** takes black or white, whichever reads on that fill.
  It does not take the set's colour, which was chosen for the window
  background.
- **Target:** what the background's default profile draws for that colour
  today (Clear Dark; Clear Light).
- **Floor:** 4.5:1 on every background of the class. Dark is Clear Dark,
  Basic, Pro and Homebrew. Light is Clear Light; Man Page and Novel count
  as a penalty below the floor.
- **Kind:** a colour keeps its hue (OKLCH, within 25 degrees of the
  target's). Black, white, bright black and bright white stay grey.
- **Choice:** the 256-colour index of its kind that reaches the floor,
  nearest the target in OKLCH. Hue is weighted twice chroma and lightness
  half, because the floor already sets lightness. Being duller than the
  target costs three times as much as being more vivid.
- **Distinctness:** colours shown side by side stay apart. These are the
  legend's categories, the metric columns, and success with failure.
- **Grey order:** the rules stay visibly lighter or darker than the file
  details.

### 9.3 The iterations

| Candidate | What its readings or renders showed | What changed next |
|---|---|---|
| c1 | Every scheme colour at 4.5:1 on its own backgrounds. Text over fills got worse: the legend's highlighted 5xx count fell to 1.43:1. The histogram bars on light came out half bright yellow, half olive. Light yellow was olive; dark red terracotta, dark yellow khaki | Text over a fill: black or white by the fill. Fixed codes remapped in text only, never in bar glyphs. Hue anchored to the profile's own colour; hue weighted over lightness |
| c2 | Bright black came out blue on both backgrounds, following Clear Dark's slate tint. Red came out rose, light green near-black | The four greys held grey. Duller than the target costs more than more vivid. Fixed codes take their sibling's code |
| c3 | The 5xx red and the per-minute failure rate were pushed apart by a constraint with no reason behind it | Constraint removed |
| c4 | First set to hold on every designed background. Light greys for file details and rules only 0.072 apart in OKLab | Larger grey gap |
| c5 | Variant with Man Page and Novel as hard constraints: the light set turns olive and near-black green to reach Novel | Not taken; c4's light set kept |
| c6 | The selection (§ 9.4, § 9.5) | — |

### 9.4 The selection (`palettes/c6.tsv`)

Contrast is the lowest on the class's designed backgrounds.

| Colour, and what `ltl` writes in it | Dark set | Light set |
|---|---|---|
| red (`31`, `91`): 5xx, ERROR, per-minute failure rates; and the failure % (`160`) on dark | 203 #ff5f5f, 4.51 | 160 #d70000, 5.22 |
| green (`32`): bytes, 2xx; and the success % (`34`) on light | 71 #5faf5f, 4.98 | 28 #008700, 4.54 |
| yellow (`33`): 4xx, WARN | 178 #d7af00, 6.41 | 94 #875f00, 5.53 |
| bright yellow (`93`): duration values; and the percentile lines (`184`) on light | 221 #ffd75f, 9.68 | 94 #875f00, 5.53 |
| blue (`34`): users column, file index; and the users count (`111`) on light | 74 #5fafd7, 5.50 | 25 #005faf, 6.23 |
| magenta (`35`): 3xx | 176 #d787d7, 5.33 | 128 #af00d7, 5.33 |
| cyan (`36`, `96`): count column, message-table titles | 80 #5fd7d7, 7.79 (`96`: 116 #87d7d7) | 23 #005f5f, 7.24 |
| white (`37`): run summary's file details | 254 #e4e4e4, 10.56 | 238 #444444, 9.41 |
| bright black (`90`, index 8): rules, column headings, options line | 247 #9e9e9e, 5.01 | 241 #626262, 5.89 |
| bright white (`97`) | 231 #ffffff | 242 #6c6c6c |
| black (index 0) and every scheme colour over a fill | black or white by the fill | the same |

### 9.5 Measured

Text colours reading below 4.5:1 in each window (23 text colours read in
each), today (background unknown) against the set (background known);
`results/e-prototype/c6/summary.txt` and `compare.txt`:

| Profile (background) | Today: below 4.5:1, below 3:1 | Set: below 4.5:1, below 3:1 |
|---|---|---|
| Clear Dark (dark) | 12, 8 | 0, 0 |
| Basic, Pro, Homebrew (dark) | 7, 5 | 0, 0 |
| Clear Light (light) | 17, 12 | 0, 0 |
| Man Page (light) | 16, 12 | 2, 0 (green 28 at 4.17) |
| Novel (light) | 17, 12 | 8, 0 (3.37 to 4.37) |
| Silver Aerogel (light, mid grey) | 17, 14 | 11, 9 |
| Grass, Ocean, Red Sands (dark, coloured) | 15 or 16, 11 | 10 or 11, 7 |

Text over a fill reads as low as 1.03:1 today (the users count on its blue
fill, Clear Dark) and 1.20:1 (the legend's highlighted 5xx count, red on its
red fill); with the sets every text-over-fill pair reads 5.25:1 or more in
every profile.

### 9.6 What the sets do not reach

- **Mid-tone and coloured backgrounds.** Silver Aerogel (#a8a8a8), Grass,
  Ocean and Red Sands leave too little room for coloured text: on Grass only
  near-white text reaches 4.5:1, and `ltl`'s default text reads 3.88:1 on
  Red Sands. The sets improve every one of them, but no set of colours
  reaches 4.5:1 there.
- **Man Page and Novel.** Designing the light set for them as well (c5)
  turns it olive and near-black green, so it is designed for Clear Light.
  On Novel, eight colours read 3.37 to 4.37:1, against 1.11 to 3.87 today.
- **Bars, histograms, fills and the heatmap on light.** They are outside
  the sets and stay as `ltl` draws them. The duration histogram's bars are
  `226` yellow on white (1.04:1), and the heatmap's light gradient starts
  at `230`, near white.
- **Text over a fill.** Black or white by the fill is #683's ask (a value
  drawn over a bar keeps a fixed foreground colour, unreadable on dark bars),
  applied here to every scheme colour over a fill. In the legend, the
  highlighted counts stop being drawn in their category's colour.

## 10. The sets across every surface (the architect's scope, 2026-11-03)

§ 9 was a first stage. It covered only the text on the window's background
in one timeline run, and left fills and bars as `ltl` draws them. On
reviewing it, the architect set the scope. Nothing is locked: the sets are
settled over several stages, with capture and validation on Windows too.

- **Every surface** in research § 1.3 and § 1.4: the timeline's header,
  rules, legend, occurrence bars, metric columns, success and failure, and
  latency column; the run summary; the message and thread-pool tables; the
  banner; help and explain; the error line; the pause prompt; the progress
  lines; and the notice surfaces.
- **Text over a fill is important:** it is designed with the fills, not
  settled by a rule.
- **Bars and lines are in scope:** the occurrence bars, the metric columns'
  bar bodies (`plain_bg`, `highlighted_bg`), the summary's contribution
  bars, and the rules and separators.
- **The histogram and heatmap colours stay as they are,** having been chosen
  already: the histogram's bins and percentile band, and the heatmap's
  gradients. Brought into scope by the architect on 2026-11-03 (§ 12.5):
  they inherit from the column colours, which the sets now change.

The stages:
1. On macOS, a set of real runs that together show every surface in scope.
2. Every colour role designed in both sets, the fills with the text over
   them.
3. Iterating across the Terminal.app configurations until the readings and
   renders hold.
4. The same capture and validation on Windows.
5. The selection, for the architect.

### 10.1 The macOS candidate, s2-c4

`palettes/s2-c4.tsv` was rendered on the issue branch (4535c4c5). It
covers all eight runs, the 11 profiles, and the background known (the set)
and unknown (today's colours). Readings are in
`results/e-prototype/s2-c4/`. The histogram's and the heatmap's cells are
left out.

Groups of cells with one code that fall below the floor (4.5:1 for text,
3:1 for bars and lines), today against s2-c4:

| Profile | Text on the background (70 groups) | Text over a fill (32) | Bars and lines (29) |
|---|---|---|---|
| Clear Dark | 24, 1 | 29, 0 | 11, 4 |
| Basic, Pro, Homebrew | 8, 0 | 19, 0 | 5, 4 |
| Clear Light | 46, 1 | 29, 0 | 17, 4 |
| Man Page | 52, 10 (none below 3) | 20, 0 | 24, 4 |
| Novel | 56, 43 (1 below 3) | 20, 0 | 17, 4 |
| Silver Aerogel, Grass, Ocean, Red Sands | 56 to 62, 59 or 60 | 19 or 20, 0 | 12 to 24, 16 to 25 |

On the designed backgrounds, two kinds of reading remain, neither a colour
failure:
- **The one text reading** on Clear Dark and on Clear Light is the notice
  panel's thin `——` rule. Its antialiased pixels never reach the full
  colour; its codes read 7.48:1 (44 on Clear Dark) and 7.24:1 (23 on
  Clear Light).
- **The four bar readings** compare a bar's `█` with its own fill behind it.
  That is how a bar is drawn, not text to read.

Text over a fill now reads at 4.5:1 in every profile.

Open in the candidate, for the architect's eye and Windows' feedback:
- On light, the yellow fills are olive (58, 100) and light teal's
  highlighted fill is dark green (22). The light set's yellow text is amber
  (94).
- On dark, the purple column and the violet classification state share
  141.
- The light set is designed for Clear Light: Man Page and Novel fall short
  in places.
- On the mid-tone and coloured backgrounds, no set reaches the floors.

## 11. Windows: the sets across every surface

Measured on 2026-11-03 by a Claude session on the Windows development host,
as the architect assigned, from the brief this section held (git history of
this file, 65356b4b). It is the fourth stage of § 10: Windows' inputs and
its readings of candidate s2-c4. Nothing is selected here.

### 11.1 Method

- **Where:** as § 6.1. Windows Terminal 1.24.12741.0 (ARM64) on Windows 11
  25H2, build 26200.9711; display 1920 by 1080 at 100% scale (96 DPI). The
  settings file sets no font face or size (Windows Terminal's defaults; the
  measured cell is 9 by 19 pixels), and neither `intenseTextStyle` nor
  `adjustIndistinguishableColors` (absent). Each window's scheme was set
  with `wt --colorScheme`, the settings file untouched.
- **Inputs:** the pattern of § 5.1 drawn and read in all 14 colour schemes
  the installed Windows Terminal ships. Campbell's and One Half Light's
  tables came out unchanged from § 6's run.
- **Runs:** the eight runs of § 10, written by the host's own `ltl` with
  `palettes/s2-c4.tsv`. Here `ltl` draws its bars with `■`, kept as the
  Windows rendering under test.
- **Capture:** each run in a window of 190 by 51, the most rows a
  190-column window holds above the taskbar on this display. Each window
  printed its run a page at a time, was captured after each page and
  closed. That is 14 schemes, background known (the set for the scheme's
  class) and unknown (today's colours), 224 windows. As in Terminal.app,
  the last page shows one line short of the file (its final empty line);
  `read-output.py` finds each page's first line from the capture.
- **Reading:** `read-output.py` as on macOS. `tally.py` makes § 10.1's
  count: over the committed macOS tables it gives § 10.1's figures in
  every profile. The two hosts' tallies are the same count, with the same
  70 groups of text on the background, 32 over a fill and 29 bars and
  lines.
- **Instruments and results:** `prototype/749-terminal-colour-codes/` on
  branch `749-24-bit-colour-sets` (then named `749-terminal-colour-codes`;
  d87fa95e). The schemes are in
  `results/windows-terminal/`, the runs in
  `results/windows-terminal/e-prototype/s2-c4/`.

### 11.2 Each scheme's background and class

By `ltl`'s rule (BT.709 luma of the measured background above one half):

| Scheme | Background | Luma | Class |
|---|---|---|---|
| Campbell (the default) | #0c0c0c | 0.047 | dark |
| Campbell Powershell | #012456 | 0.126 | dark |
| Dimidium | #141414 | 0.078 | dark |
| Ottosson, Vintage, Tango Dark, CGA, IBM 5153 | #000000 | 0 | dark |
| One Half Dark | #282c34 | 0.171 | dark |
| Solarized Dark | #002b36 | 0.136 | dark |
| Dark+ | #1e1e1e | 0.118 | dark |
| One Half Light | #fafafa | 0.980 | light |
| Solarized Light | #fdf6e3 | 0.965 | light |
| Tango Light | #ffffff | 1.000 | light |

Every scheme classes as its name says, none near one half. Windows ships no
mid-tone or coloured background like macOS's Silver Aerogel, Grass, Ocean
or Red Sands; the nearest is Campbell Powershell's navy.

### 11.3 The tallies

Groups of cells with one code that fall below the floor (4.5:1 for text,
3:1 for bars and lines), today against s2-c4, as § 10.1:

| Scheme | Text on the background (70 groups) | of which below 3:1 today | Text over a fill (32) | Bars and lines (29) |
|---|---|---|---|---|
| Campbell | 18, 0 | 4 | 21, 0 | 5, 4 |
| Campbell Powershell | 28, 0 | 11 | 21, 0 | 5, 4 |
| Dimidium | 8, 0 | 0 | 20, 0 | 4, 4 |
| Ottosson | 8, 0 | 1 | 20, 0 | 5, 4 |
| Vintage | 18, 0 | 7 | 19, 0 | 5, 4 |
| One Half Dark | 19, 0 | 11 | 26, 0 | 11, 4 |
| Solarized Dark | 27, 0 | 12 | 26, 0 | 11, 4 |
| Tango Dark, Dark+ | 18, 0 | 7 | 20, 0 | 11, 4 |
| CGA | 21, 0 | 11 | 17, 0 | 12, 4 |
| IBM 5153 | 18, 0 | 11 | 19, 0 | 12, 4 |
| One Half Light | 46, 0 | 27 | 29, 0 | 12, 4 |
| Solarized Light | 57, 17 (none below 3) | 33 | 26, 0 | 14, 4 |
| Tango Light | 42, 0 | 30 | 20, 0 | 12, 4 |

With the light set, the light schemes count 72 text groups. Their runs are
`ltl`'s output for a light background, whose notice panel writes five
codes where the dark output writes three (§ 2).

- **Text:** in 13 of the 14 schemes the set leaves no text below 4.5:1,
  on the background or over a fill. The exception is Solarized Light
  (§ 11.4).
- **Bars and lines:** the four readings left in every scheme are bar
  glyphs over their own fill (§ 11.5).
- **macOS's one text reading does not appear here.** On Clear Dark and
  Clear Light, the notice panel's thin `——` rule stayed below its full
  colour (§ 10.1). Here it reads at 4.5:1 or more.

### 11.4 Where the candidate falls short on Windows

- **Solarized Light** (background #fdf6e3, a cream) has 17 text groups
  below 4.5:1 with the set, none below 3:1:
  - **7 are the scheme's own text colour** (#657b83, 4.13:1 on its
    background), one group per run of ordinary text. No set changes it.
  - **10 are the light set's green and orange.** Green 28 reads 4.36:1
    there: bytes, 2xx, `INFO`, success, the progress lines. Orange 130
    reads 4.37:1: the orange column's values. Both read 4.51:1 on One Half
    Light and 4.70 on Tango Light. The design put them at 4.54 and 4.55 on
    Clear Light (#fbfbfb), which leaves no margin for a darker light
    background.
  - **As bars, two light fills fall to the 3:1 the design holds fills to**
    on Clear Light. The magenta plain fill (170) reads 2.99:1 against
    Solarized Light's background and orange's tan plain fill (137) 3.02.
    On One Half Light they read 3.09 and 3.12.
- **One Half Light holds.** It repaints the sixteen (§ 6.2), but with the
  set no text falls below 4.5:1. The set writes none of the sixteen, so the
  repainting no longer reaches these colours. Today 46 of its 70 text
  groups fall below 4.5:1, 27 of them below 3.
- **No scheme's background classes against intuition** (§ 11.2).

### 11.5 What Windows draws differently

- **Bold**, from the pattern in all 14 schemes (`summary.txt`, items 1 and
  3; `profile-*.txt`, group C):
  - Bold over a basic code takes the code's bright variant in every
    scheme (One Half Dark changes only `30`; Dark+ all but `37`), at the
    same weight: ink 1.00 to 1.05 times. Larger ratios, up to 2.69, occur
    only where the plain colour is within 1.92:1 of the background, and
    the ink count (pixels at least 48 from the background) misses it.
  - Bold over index 16-255 keeps its colour and draws 1.12 to 1.13 times
    heavier.

  In the runs:
  - **Help and explain headings** (bold over the default foreground).
    Today they take each scheme's bold colour. On One Half Light that is
    lighter than the body (7.46:1 against 10.86). On Solarized Dark (4.75),
    Solarized Light (4.13), Tango Light, One Half Dark and Dark+ it is the
    body's own colour, so the headings stand out by nothing. With the set
    (231 on dark, 16 on light) they read 14.0 to 21.0:1, and heavier.
  - **The explain page's message-table titles** (bold `36`). Today they
    read 1.60:1 on Tango Light, 2.29 on One Half Light and 2.48 on
    Solarized Light. With the set (bold 80 on dark, 23 on light) they
    read 6.95 to 12.19 in every scheme.
  - **The notice panel's pick** (bold `37`). Today it does not show on the
    light schemes (1.00 to 1.16:1). With the background known as light,
    `ltl` writes it bold black (16): 19.47 to 21.0.
- **`■` bars.** `■` is a square smaller than the cell:
  - **Bars over a fill** (the metric columns' bodies) draw the glyph in
    the fill's colour, so they read solid.
  - **The occurrence bars** have no fill, so they read as a row of
    squares, today and with the set.
  - **The occurrences column's failure bar** in the highlighted-failure
    runs draws `■` in red (`31`) over a red fill (196). On macOS `█` hides
    the fill. Here the fill shows around each square: today's darker red
    (Campbell's #c50f1f) draws dark squares on the bar (1.52:1 between the
    two), and the set's lighter red (203) draws pale ones (1.34:1). Three
    of the four bar readings in every scheme are this bar, one per run that
    draws it. The fourth is the explain page's own example bar, written
    with `█` on every host, over its green fill.
- **The notice panel.** On a dark background, `ltl` writes the panel's
  secondary text faint (§ 2), and the set leaves faint as it is. Windows
  Terminal draws faint toward the background. In the custom-metrics run's
  279 faint cells, with the set and today alike, it reads:
  - 1.65:1 on Solarized Dark;
  - 2.63 to 3.41 on Campbell Powershell, Dimidium, One Half Dark, CGA,
    IBM 5153, Dark+, Ottosson, Vintage and Campbell;
  - 3.90 on Tango Dark.

  These equal the pattern's faint default text in each scheme
  (`summary.txt`, item 4). On the light schemes faint is drawn darker
  (10.36 to 16.13:1 today), and with the light set `ltl` writes its grey
  instead. Neither host's tallies see faint text: `read-output.py` groups
  it with the plain text of the same code, and reads a group's colour at
  its 90th percentile. The panel's frame, title and categories read at
  4.5:1 or more (text) and 3:1 or more (lines) with the set in every
  scheme.

### 11.6 The open points of § 10.1, read on Windows

- **The light set's olive yellow fills (58, 100) and dark green teal
  highlight (22).** Windows Terminal draws index 16-255 at the same values
  as Terminal.app (§ 6.2), so these fills are the same colours on both
  hosts; only the background behind them changes. As bars on the three
  light schemes they read:
  - 58: 6.23 to 6.72:1;
  - 100: 3.54 to 3.82;
  - 22: 7.38 to 7.96.

  Whether olive and dark green will do is for the architect's eye.
  `wt-e-measure.sh` remakes the captures.
- **Man Page's and Novel's shortfalls.** Solarized Light is the Windows
  scheme nearest them. Its background's relative luminance (0.92) lies
  between Clear Light's (0.97) and Man Page's (0.88). It falls short in
  Man Page's way, by less. The light set's green 28 reads 4.36:1 on
  Solarized Light; computed from the measured backgrounds, it reads 4.17
  on Man Page and 3.37 on Novel. The magenta plain fill reads 2.99, 2.86
  and 2.31.

### 11.7 The light set designed for every light background (s2-c5)

The architect's direction (2026-11-03), on § 11.4: one more design round,
with the light set clearing its floors on the light backgrounds of both
hosts. `design.py` with Clear Light, One Half Light, Solarized Light and
Tango Light all hard (Man Page and Novel still a penalty) gives
`palettes/s2-c5.tsv` (issue branch, 9677725d). With the defaults it still
gives s2-c4 exactly. The dark set is unchanged. Only Solarized Light
binds: s2-c4 already clears One Half Light and Tango Light.

What moves in the light set, contrast on Clear Light and on Solarized
Light, computed from the measured backgrounds:

| Role | s2-c4 | s2-c5 |
|---|---|---|
| green: bytes, 2xx, `INFO`, success, the progress lines, the notice green | 28 #008700: 4.54, 4.36 | 22 #005f00: 7.70, 7.38 |
| the orange column's values | 130 #af5f00: 4.55, 4.37 | 94 #875f00: 5.53, 5.31 |
| the notice category orange | 130 #af5f00 | 124 #af0000, a red: 7.19, 6.90 |
| the magenta fills, plain and highlighted, as bars | 170 #d75fd7, 201 #ff00ff: 3.12, 2.99 and 3.03, 2.91; black text | 90 #870087, 127 #af00af: 8.53, 8.18 and 5.90, 5.66; white text |
| the pink fills | 200 plain, 169 highlighted | the two swapped |

- **The 256-colour codes have no green between 28 and 22.** The cube's
  green steps from 135 to 95, so the next green that clears Solarized
  Light is 22, at OKLCH lightness 0.42 against 28's 0.54. It reads 7.70:1
  on Clear Light, where 4.5 is the floor. This is the near-black green of
  c5 (§ 9.3), here for Solarized Light instead of Novel.
- **The orange column takes the light set's yellow.** No orange code
  between 130 and the yellow 94 clears Solarized Light within the hue
  tolerance. The orange column's values would draw in the same colour as
  the duration values, 4xx and `WARN`. `design.py` keeps only neighbouring
  metric columns apart, and duration and orange are not neighbours.
- **The notice categories lose a colour.** The notice green takes 22,
  which the notice teal already has (s2-c4), so green and teal notices
  draw alike. The notice orange turns red.
- **The magenta fills turn dark purple** to raise the plain fill on
  Solarized Light from 2.99 to 3:1.
- **A 24-bit code would clear it with no visible move.** `38;2;0;132;0`
  (#008400) reads 4.53:1 on Solarized Light, 0.009 from 28 in OKLab;
  `38;2;172;93;0` (#ac5d00) reads 4.51, 0.008 from 130. Terminal.app and
  Windows Terminal draw `38;2` exactly (§ 5.2, § 6.2). D1 sets the sets in
  256-colour codes.

Not rendered: the design alone shows two pairs of roles drawn alike.

**The architect's call (2026-11-03): s2-c4's light set is kept.**
Solarized Light's green and orange, at 4.36 and 4.37:1, are a shortfall
recorded as Man Page's is (§ 9.6, § 11.4). s2-c5 does not go forward. The
architect has not yet seen the sets drawn: the selection waits on that.

## 12. Tone governs (the architect's direction, 2026-11-03)

The architect saw s2-c4 drawn for the first time, on the agreed run (the
outage day's web access log, `-du us -st 04:00 -et 13:00 -bs 30m -n 4 -hf
-hm duration -hg`), beside today's colours: "the fallback options are far
better … your choices of colors just don't work. It doesn't even appear that
you tried to keep it in the same hues and tones." Direction: a proposal where
tone governs, visually consistent with the current colours; "the results
should be very close, where the tweak is slight, not complete changes".

### 12.1 Why s2-c4 moved the colours

Measured against today's colours as Clear Dark and Clear Light draw them
(OKLCH):

| Set | Role | Today | s2-c4 |
|---|---|---|---|
| Dark | blue plain fill | #0000d7 | 111 #87afff, lightness +0.36 |
| Dark | purple plain fill | #5f00af | 141 #af87ff, +0.30 |
| Dark | red plain fill | #af0000 | 210 #ff8787, +0.28 |
| Dark | rules and headings | #465c6d | 247 #9e9e9e, +0.24 |
| Light | duration values | #e5c872 | 94 #875f00, −0.33 |
| Light | count column | #69c6c9 | 23 #005f5f, −0.33 |
| Light | yellow fills | #d7d700, #ffff00 | 58, 100 (olive), −0.38, −0.36 |
| Light | teal highlighted fill | #00d7af | 22 #005f00, −0.36, hue −30° |

Three of `design.py`'s rules did it: contrast was a hard floor while
lightness cost a quarter of hue (`--wl 0.5`, `--wh 2.0`), so every colour
short of the floor moved in tone first; a duller colour cost three times a
more vivid one, so the cube's saturated codes won; and a column's two fills
shared one text colour, black on dark, so the dark plain fills turned light
to carry it.

The 256-colour cube cannot hold today's colours either. The nearest code
that reads no worse than today lies 0.04 to 0.09 from it in OKLab, with hue
moved by up to 16°: Clear Dark's brick red #b45648 becomes rose (131
#af5f5f), Clear Light's gold #c4ac62 olive (143 #afaf5f), its blue #5685a8
grey (243 #767676). Terminal.app on macOS 26 and Windows Terminal draw
24-bit codes exactly (§ 5.2, § 6.2).

### 12.2 The tone-led sets (`palettes/t1.tsv`, then `t2.tsv`)

`tone.py` (issue branch):
- **Text:** every scheme colour starts from what the class's default
  profile draws today, written as a 24-bit code. A colour below 4.5:1 on
  that profile's background moves in OKLCH lightness only, hue and chroma
  held, until it reaches 4.5:1 or has moved as far as the profile itself
  moves that hue from its normal to its bright colour (0.05 to 0.12; 0.08
  for greys and for `ltl`'s fixed 256-colour codes, which start from their
  own colour).
- **White on light:** white and bright white start from the profile's text
  and bold text colours, as `ltl`'s light notice panel already writes black
  where its dark one writes white (§ 2).
- **Bold** over the default foreground: the profile's bold text colour.
- **Fills:** today's 256-colour codes, sliced from `@column_colors`.
- **Text over a fill:** black or white, whichever reads better on it, the
  expected behaviour of #683 (a value drawn over a bar keeps a fixed
  foreground colour, unreadable on dark bars).

What moves on dark (Clear Dark draws it): red #b45648 to #d57464 (2.79 to
4.16:1), the rules and headings #465c6d to #5c7385 (1.93 to 2.71), the
failure code 160 to #f53629 (2.49 to 3.48), the purple column's values 93
to #9758fe (2.22 to 3.29), the violet classification state 135 to #b776ff
(3.77 to 4.51); blue, magenta and bright red by under 0.03. The rest keep
today's colour. On light (Clear Light), the colours below 4.5:1 darken by up
to 0.12, most by 0.04 to 0.09: for example duration values #e5c872 to
#c8ab55 (1.58 to 2.16:1) and the count column #69c6c9 to #4fadb0 (1.93 to
2.56). Red, the failure code, the purple column, the rules and the text
colours keep today's.

Before it was shown, all eight runs were captured in Clear Dark and Clear
Light, set and today, and compared by eye: nothing changes character.

### 12.3 Measured

Captured in Clear Dark and Clear Light, the eight runs of § 10 (t1;
`results/e-prototype/t1/`), groups below the floor, today against the set:

| Profile | Text on the background | Text over a fill | Bars and lines | Text below 3:1 |
|---|---|---|---|---|
| Clear Dark | 24/70, 15/70 | 29/32, 1/32 | 11/29, 11/29 | 14, 7 |
| Clear Light | 46/70, 31/72 | 29/32, 1/32 | 17/29, 12/29 | 37, 19 |

The one group over a fill is the pause prompt: the default foreground over
the set's blue, as today. The bars and lines include the rules, which stay
dim (2.71:1 on Clear Dark).

Computed for every measured profile and scheme from its drawn colours (one
count per colour role, s1 to s15 and `ltl`'s fixed codes), roles below
4.5:1 today against the set:
- **Dark:** fewer in every one: Clear Dark 12 to 6, Campbell 9 to 1, One
  Half Dark 10 to 6, Solarized Dark 15 to 3. The roles that read lower than
  today stay above 4.5:1, except the rules on Campbell (4.31 to 3.96),
  Campbell Powershell (3.33 to 3.06), Dimidium (4.58 to 3.72), Ottosson and
  Vintage (5.32 to 4.25).
- **Light:** Clear Light 26 to 16, Tango Light 23 to 16, One Half Light 26
  to 22, Solarized Light 26 to 25; Man Page 23 to 25 and Novel 27 to 28.
  Below 3:1, fewer in every one. Lower than the scheme draws it today:
  One Half Light's cyan 3.30 to 2.53, magenta 5.86 to 4.48; Solarized
  Light's bright green 4.99 to 2.55 and bright yellow 4.13 to 2.07; Man
  Page's blue 11.29 to 4.14.

### 12.4 The fill pairs

The architect, on t1: "the highlight background color for the users metric
is not differentiated enough from the normal bar color … Your tests will
need to use a maximum of metrics columns, each with highlight active on a
portion of the data." The ninth run, `fills`, reads the custom-metrics CSV
with ten user-defined metrics, which take the ten column colours in order,
and highlights every odd minute (`-h ' [0-9][0-9]:[0-5][13579]:[0-9][0-9],'`,
`-bs 10 -n 0`): each column's plain and highlighted fill side by side.

Distance between each column's plain and highlighted fill (OKLab), against
yellow's and green's, which the architect read as distinct:

| Column | Plain, highlighted | Distance |
|---|---|---|
| yellow | 184, 226 | 0.120 |
| green | 34, 46 | 0.225 |
| cyan | 30, 36 | 0.123 (36 is a sea green, hue −26°) |
| **blue** | **20, 21** | **0.066** |
| magenta | 127, 201 | 0.190 |
| red | 124, 196 | 0.167 |
| orange | 166, 208 | 0.120 |
| pink | 169, 213 | 0.149 |
| teal | 29, 43 | 0.235 |
| purple | 55, 93 | 0.146 |

Only blue falls below yellow. In t2 its highlight takes 27 (#005fff), the
code `ltl`'s histogram already highlights blue with (`highlighted_bg_num`):
0.156 from the plain fill, in both sets. The other pairs keep today's codes.
With t2, over the access-log and `fills` runs, no text over a fill falls
below 4.5:1 in either profile (`results/e-prototype/t2/`).

### 12.5 The heatmap and the histogram (the architect's scope, 2026-11-03)

The architect, having seen `t2`: "The methodology that you use here now
needs to be tested against the histograms and the heat map … as you've
changed those column colors, you need to adapt the colors for the heat map
metrics and the histogram metrics, as these are standard gradient color
palettes which are inherited from the column colors themselves."

Where their colours come from today (`ltl`):

| Surface | Drawn | Colour | Record |
|---|---|---|---|
| Heatmap cells | `█` in one of 8 steps by density | the column's `gradient` (dark) or `gradient_light` (light), 256-colour codes | `features/heatmap.md`: "Base color matches metric column color"; § 7, light gradients "fade from light/pale shades to bright saturated colors" |
| Heatmap highlighted cells | the cell over a background | the column's plain fill (`plain_bg_num`) | `features/heatmap.md` § 4: highlight uses the bar graph's `plain_bg` |
| Heatmap percentile markers | `\|` | bright black (`90`) | `features/heatmap.md` |
| Histogram bars | flat (`$histogram_color_gradient_enabled = 0`) | the column's plain fill code as a foreground | `features/histogram-charts.md`: "Base colors match bar graph plain_bg" |
| Histogram highlighted part | stacked at the bottom | `highlighted_bg_num` (226, 46, 51, 27, 207, …); count's 51 is not the timeline's 36 (#666, open) | `features/histogram-charts.md`: "Highlight colors match bar graph highlight_bg" |
| Histogram percentile rows | population row; highlighted row | the plain fill as text; black on a band of the highlight | `features/histogram-charts.md` (#653): "a light-background highlight palette is a separate decision … chosen from rendered candidates, after #665" |
| Notice categories on light | text | the column's `gradient_light` last step | § 2 |

Today's gradients, each step's contrast with Clear Dark (`gradient`) and
Clear Light (`gradient_light`), lightest-density step first:

| Column | Dark | Light |
|---|---|---|
| yellow | 2.00 … 12.50 | 1.01, 1.01, 1.02, 1.03, 1.36, 1.78, 2.33, 2.95 |
| green | 1.69 … 10.95 | 1.06 … 2.78 |
| cyan | 1.79 … 11.37, step 6 dimmer than step 5 (7.79 after 10.71) | 1.03 … 4.21 |
| blue | 1.34, 1.16, 1.04, 1.27, 1.56, 2.61, 3.78, 5.48 | 1.35 … 4.97 |
| magenta | 1.06 … 5.33 | 1.24 … 5.84 |
| red | 1.05 … 5.68 | 1.27 … 7.19 |
| orange | 2.34 … 7.38 | 1.30 … 3.67 |
| pink | 3.08 … 8.20 | 1.24 … 3.30 |
| teal | 1.79 … 10.41 | 1.12 … 4.38 |
| purple | 1.17 … 4.46 | 1.35 … 9.64 |

On light, the low-density steps of six gradients are all but the page's
own colour; on dark, blue's first five steps and the first step of
magenta, red and purple barely leave the background. Adjacent steps lie as
close as 0.005 in OKLCH lightness (orange, both backgrounds).

The method put to the architect and confirmed ("yes, start with the heatmap
gradients"): the gradients in 24-bit codes, each step's lightness spaced
evenly, the faintest at least as visible as dark yellow's is today; the
histogram's bars and highlighted part following the timeline's fills; the
histogram on a light background from rendered candidates afterwards.

### 12.6 The heatmap gradients (`palettes/t4.tsv`)

**The first round (`t3`, not kept).** Each step kept the hue today's
256-colour gradient gives it. The light gradients wander off their column's
hue (red's through pinks and magentas, 218 to 200; blue's through cyan, 45;
yellow's to red-orange, 202), and with the faint end made visible the
detours showed. The architect: "your red thing there, man, it's fucking
horrible … the 24-bit colors should be adapted to the gradients that heat
maps use today, which are based in the color from the associated metrics
column", and the runs were to show the metric columns, plain and
highlighted, beside each heatmap.

**The rule (`tone.py`, `t4`).** For each column, dark and light:
- every step is in the column's own hue, its plain fill's;
- each step keeps today's step's saturation: its chroma as a share of the
  most that hue holds at its lightness;
- the faintest step lies at least 0.207 from the background in OKLab, the
  distance of today's dark yellow faintest step from Clear Dark. A cell is
  seen by its colour; at 2.0:1 against white, a yellow can only be olive or
  mustard. The densest step is at today's lightness, and the steps between
  are evenly spaced in lightness, at least 0.036 apart (today's dark
  yellow's closest pair);
- a yellow darker than the yellow fill turns toward amber (today's 94),
  reached at lightness 0.65, as today's yellow gradients turn through amber
  and gold: darkened, a lemon yellow is olive.

On dark the gradients stay near today's, the faint steps of blue, magenta,
red and purple now visible; on light, red runs salmon to dark red and blue
stays blue.

**The runs.** `heat-<colour>`, one per column colour, read a synthetic log
(`synth-metrics.py`): five hours of a log4j-style line every three seconds,
ten log-normal metrics named after the column colours in the order
user-defined metrics take them, a steady volume per bucket, and a third of
the lines from 06:00 to 07:30 carrying a highlight token. Each run shows
all ten metric columns, plain and highlighted, beside the heatmap of one.
The real logs could not: the outage bucket dwarfs every sum, and a counting
metric turns the heatmap off.

**The architect (2026-11-03), on `t4` drawn in Clear Dark and Clear Light:
"yes - thats perfect. I validate both sets. It not only looks beautiful".**
The validated sets are `t4`: the text colours of § 12.2, the fills with
blue's highlight at 27 (§ 12.4), and these gradients. The column colours stay
the ten of `@column_colors`; asked whether more should be added so that an
eleventh column or metric no longer wraps to yellow, the architect: "No, I
don't want any more than what you just showed. That is already ample."

**The histogram needs no work of its own (architect, 2026-11-03):** "We
don't need to do the histogram … they are the same colors for highlight and
standard from the columns. We have already tested and set those." Its bars
take the column's plain fill and its highlighted part the column's
highlight (`plain_bg_num`, `highlighted_bg_num`); blue's is 27, the
highlight the set gives the timeline. Count's histogram highlight (51)
still differs from the timeline's (36), as #666 records.

## Resuming

- Done: research (§ 4); macOS (§ 5) and Windows Terminal (§ 6) measured
  and read together (§ 8); D1 locked, then amended: tone governs and the
  sets are 24-bit (§ Decisions); the every-surface stage on macOS (§ 10)
  and on Windows (§ 11); the tone-led sets (§ 12), validated by the
  architect with the heatmap gradients (§ 12.6, `palettes/t4.tsv`).
- Instruments on branch `749-24-bit-colour-sets`,
  `prototype/749-terminal-colour-codes/`: `tone.py` designs the sets,
  `e-outputs.sh` writes the runs (§ 10's eight, `fills`, and the ten
  `heat-<colour>` runs), `e-palette.py` rewrites them, `e-measure.sh`
  captures them (conditions `known`, `unknown`, and `today`: the background
  known, as `ltl` writes for it today), `read-output.py` and `tally.py` read
  them.
- The histogram takes the columns' fills and needs no work of its own
  (architect, § 12.6).
- Not yet done: the validated sets (`t4`) have been read only on macOS;
  Windows read the earlier candidate `s2-c4` (§ 11).
- Next: the implementation, from § 1. Before code, this doc gains its
  acceptance criteria, agreed with the architect.
- State outside the repository: none needed; the captures are remade by the
  instruments.
