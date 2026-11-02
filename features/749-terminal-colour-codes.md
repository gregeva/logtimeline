# Should ltl's colours and bold move to 256-colour codes? (Issue #749)

## Status

**In progress: research done, macOS measured; Windows Terminal handed over
to a session on the Windows host (§ 6, assigned by the architect
2026-11-02).** Contracts in § 2 confirmed by the architect on 2026-11-02. The
research is `features/749-terminal-colour-codes-research.md`. The macOS
measurements (§ 5) were made on 2026-11-02 with the instruments in
`prototype/749-terminal-colour-codes/` on branch `749-terminal-colour-codes`.
No decision has been taken; nothing in `ltl` has changed.

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
| `38;5;0`-`38;5;15` against the basic codes | Identical in Clear Dark and Clear Light, which define their own sixteen. In the other ten, which do not, all or 13 of the 16 differ: `38;5;N` is Terminal's built-in palette (`38;5;1` #990000), while the basic code is drawn in a colour that changes with the profile (`31` #d6492e on Basic, #bd311b on Man Page, #750000 on Ocean) | Index 0-15 not measured there |
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

The captures stay out of the repository (their window titles carry the
user's name); `ltl-outputs.sh` and `measure.sh` remake them.

### 5.7 The issue's open item: non-default schemes on macOS

Yes, on Terminal.app's shipped schemes. On its light ones (Clear Light, Man
Page, Novel, Silver Aerogel), `ltl`'s duration colour reads 1.26 to 2.15:1,
count 1.75 to 2.27:1 and bytes 2.39 to 2.66:1. The cause is not bold, which
Terminal.app does not brighten: the scheme's own yellow, cyan and green are
pale against a light background, and the fixed-code versions of the same
hues are paler still. Linux terminals were not measured.

## 6. Windows Terminal: handover to the Windows host

The architect assigned this measurement on 2026-11-02 to a Claude session on
the Windows development host, handed over through the repository. This
section is that session's brief. The One Half Light table in
`docs/terminal-output.md` covers bold and faint on a few codes, not `ltl`'s
output and not a dark scheme.

**Goal.** The measurements of § 5, in Windows Terminal, on its default dark
scheme (Campbell) and on One Half Light, so the architect decides with both
platforms measured. The session measures and records; it decides nothing.

**Setup.**
- The host as `docs/toolchain-guidance.md` § Windows development host sets it
  up; every command from Git Bash.
- Branch `749-terminal-colour-codes` (the instruments) checked out and synced
  as `docs/process/workflow.md` § 1 says; this doc is on `release/0.20.0`.
- Recorded beside the readings: Windows build; Windows Terminal version
  (`Get-AppxPackage Microsoft.WindowsTerminal`); the profile used, its font
  face and size; the display scale; and, for that profile in
  `settings.json`, `intenseTextStyle` and `adjustIndistinguishableColors` as
  written, or "absent" when the default applies (research § 3.1 and § 4 give
  the documented defaults).

**Inputs**, from `prototype/749-terminal-colour-codes/`:
- `python3 pattern.py`, run in a work directory, writes `pattern.ans` and
  `pattern.json`.
- `./ltl-outputs.sh <dir>` writes `ltl`'s output from committed fixtures, as
  written and rewritten to fixed codes, with the host's own `ltl`: its output
  is what is measured. Native `ltl` on Windows does not ask the terminal for
  its background (§ 7), so these runs are drawn for dark on both schemes,
  which is what a user without `-lbg` sees.

**Drawing and capturing.** `open-capture.sh` drives Terminal.app, so the
session writes its own capture script beside it (PowerShell or Git Bash),
committed with the results. For each file and scheme:
- a new Windows Terminal window, not the agent's shell, set to that scheme
  for that window (`wt new-tab --colorScheme <name>` where the installed
  version accepts it, else a profile per scheme), with the UTF-8 code page as
  `docs/terminal-output.md` requires, showing the file with `cat` and nothing
  after it;
- the window sized so nothing scrolls: at least 102 columns by 34 rows for
  the pattern, 120 by 58 for `ltl`'s output. The reader finds the cell grid
  from the pattern's first and last rows;
- the window alone captured as an 8-bit RGB or RGBA PNG (what
  `System.Drawing`'s `Bitmap.Save` writes), at the display's own scale.
- Before reading, `analyse.py` prints the grid it found (`cell_w`, `cell_h`):
  "no marker found", or a cell size that does not match the font, means the
  window scrolled or the 24-bit markers were not drawn.

**Reading**, in `prototype/749-terminal-colour-codes/`:

```bash
python3 analyse.py <capture.png> <work>/pattern.json <work>/<scheme>.json
python3 report.py <work>/<scheme>.json > results/windows-terminal/profile-<scheme>.txt
python3 summary.py <work>/Campbell.json <work>/One-Half-Light.json > results/windows-terminal/summary.txt
python3 fixed-contrast.py <work>/Campbell.json <work>/One-Half-Light.json > results/windows-terminal/fixed-contrast.txt   # dark first
```

**What the readings settle** (research § 7.3, the Windows Terminal points):
- bold on the basic codes and on the default foreground, on both schemes,
  against the One Half Light table (bright variant, normal weight); on
  Campbell it is not yet measured;
- `38;5;0`-`38;5;15` against the basic codes, and `38;5;0` against
  `38;5;16`: whether the text over `ltl`'s fills follows the scheme there, as
  in Terminal.app's Clear profiles;
- faint on both schemes;
- `38;5;226` and `38;5;184` on One Half Light against their RGB (255,255,0
  and 215,215,0): a shifted colour means `adjustIndistinguishableColors`
  reaches 256-colour codes;
- the contrast of `ltl`'s colours on both schemes, today and as fixed codes
  (the tables of § 5.3), and the most one colour reaches on both (§ 5.4);
- the help headings and the explain page, by eye in the captures.

**Recording.** The findings go into this section in the form of § 5 (setup,
a table against Terminal.app, the contrast tables), committed directly to
`release/0.20.0`. The capture script and `results/windows-terminal/` are
committed to `749-terminal-colour-codes`. Both are pushed, then the
stage-boundary comment goes on the issue (`docs/process/issues.md` § Issue
updates). Captures stay out of the repository.

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

## Resuming

- Done: research (§ 4); macOS Terminal.app measured (§ 5), instruments on
  branch `749-terminal-colour-codes`.
- Next: Windows Terminal, Campbell and One Half Light, on the Windows
  development host. Start at § 6, which is the whole brief.
- Then: the architect's decision, with § 5 and § 6 in front of him.
- State outside the repository: none needed; the captures are remade by the
  instruments.
