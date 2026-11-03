# Should ltl's colours and bold move to 256-colour codes? (Issue #749)

## Status

**In progress: research done, macOS and Windows Terminal measured and read
together (§ 8); D1 locked (2026-11-03); the D1 prototype's first stage
on macOS (§ 9); the sets across every surface next (§ 10).**
Contracts in § 2 confirmed by the architect on 2026-11-02. The research is
`features/749-terminal-colour-codes-research.md`. The macOS (§ 5) and Windows
Terminal (§ 6) measurements were made on 2026-11-02 with the instruments in
`prototype/749-terminal-colour-codes/` on branch `749-terminal-colour-codes`.
Nothing in `ltl` has changed.

- **Issue:** #749 (research whether ltl's colours and bold should move to
  256-colour codes).
- **Outcome wanted:** a finding for the architect to decide on, not a change.

---

## What it is for

`docs/terminal-output.md` § Colour and emphasis sets the rule for anything
that has to hold its colour: a 256-colour or 24-bit code, never one of the
sixteen basic colours, and bold only over a 256-colour or 24-bit foreground.
The rule came from Windows Terminal's "One Half Light" scheme, where the
basic colours are repainted and bold turns them lighter at normal weight.
`ltl` itself still writes basic codes for its first six column colours, every
category colour and its help text's bold. This issue measures, on `ltl`'s own
output, what that costs today and what a move would give up, so the architect
can decide whether `ltl` follows its own rule.

## 1. Requirement (issue body)

Research and a prototype of whether `ltl` should write its colours and bold as
256-colour codes (`38;5;N`) or 24-bit codes (`38;2;R;G;B`) instead of the
sixteen basic colours. Done when findings show, on `ltl`'s own output (help
and explain text included), how the basic colours render today and how
256-colour codes would, in Windows Terminal on a light and a dark scheme and
on macOS; what moving would give up or change; and the architect has
decided. Open in the issue: whether basic colours are a problem on
macOS/Linux terminals with non-default schemes too.

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
  - Bold over the default foreground (the help and explain headings) is not
    covered (§ 8.4).

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
  `prototype/749-terminal-colour-codes/` on branch `749-terminal-colour-codes`
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
  gradients.

The stages:
1. On macOS, a set of real runs that together show every surface in scope.
2. Every colour role designed in both sets, the fills with the text over
   them.
3. Iterating across the Terminal.app configurations until the readings and
   renders hold.
4. The same capture and validation on Windows.
5. The selection, for the architect.

## Resuming

- Done: research (§ 4); macOS Terminal.app measured (§ 5); Windows Terminal
  measured on Campbell and One Half Light (§ 6); the two read together
  (§ 8); D1 locked; the first stage of the D1 prototype on macOS (§ 9).
  Instruments on branch `749-terminal-colour-codes`.
- In progress, § 10 on macOS: producing candidate sets, not a selection.
  Nothing is chosen until Windows has given its inputs and feedback
  (architect, 2026-11-03).
  - **Runs:** seven real runs together show every surface in scope. All are
    at `--terminal-width 190`, and those that read logs use
    `-st 04:00 -et 13:00 -bs 30m -n 4 -hf`.
    1. The outage day's web access log with `-du us -hm duration -hg`.
    2. The same log with `-du us -sm`: the latency column, and the summary
       without colour.
    3. The method server logs of the same node and morning
       (`-et 12:30`): log levels and their highlighted variants.
    4. The custom-metrics CSV with seven `-udm` metrics and one that matches
       nothing (`-bs 10`): every user-defined column colour, and a notice
       panel.
    5. `--help` under `FORCE_COLOR=1`.
    6. `--explain contribution-highlighting` under `FORCE_COLOR=1`.
    7. A usage error.

    The progress lines (`92`) and the pause prompt (`0;44`) cannot come
    from a run here, so they are printed from `ltl`'s own codes for them.
  - **Designer:** `design.py` on the issue branch now designs every role.
    These are text on the background, `ltl`'s fixed text codes, the bar
    fills (plain and highlighted per column colour), the text over each
    fill, and bold over the default foreground. The first candidate,
    `palettes/s2-c1.tsv`, has faults to iterate on. The light yellow
    highlighted fill drifts to olive-green (64), and the light orange one
    to red (196). On dark, the purple column and the violet classification
    state share 141.
  - **Still to build:** `e-palette.py` must remap by these roles. It must
    leave the histogram block and the heatmap columns untouched; recolour
    a bar glyph drawn over its fill (`█`, `▀`, `▄`) with the fill; and give
    text over a fill the `t` colour of that fill. `e-outputs.sh` must cover
    the seven runs. `e-show.sh` and `read-output.py` must capture and read
    output of any length, page by page.
- After macOS: the same capture and validation on Windows, then the
  architect's choice.
- State outside the repository: none needed; the captures are remade by the
  instruments.
