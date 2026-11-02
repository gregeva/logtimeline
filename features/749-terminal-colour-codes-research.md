# Terminal colour codes: research (#749)

Starting point for the prototype of #749 (research whether `ltl`'s colours
and bold should move to 256-colour codes). It sets what `ltl` writes today
beside what terminals do with each kind of colour code, so the prototype
knows what to measure. The measurements it led to are in the issue's feature
doc, `features/749-terminal-colour-codes.md` § 5. This is research, not a
decision record: it states what was found and where. Where a source
recommends something, it is written as that source's recommendation, with
its reason; nothing here is decided.

Gathered 2026-11-02 from two passes: a reading of `ltl` on `release/0.20.0`
(commit `c0e369a1`), with two runs on a slice of a web application access log
tallied for the codes actually written; and a web survey of terminal
documentation, terminal source code and issue trackers, each statement
verified against its source by a second pass. Where the second pass corrected
a statement, the corrected wording is used. Nothing here is a measurement.
The facts already measured in Windows Terminal ("One Half Light" scheme) are
in `docs/terminal-output.md` § Colour and emphasis; they are pointed at as
*measured (terminal-output)*, not restated. "(inferred)" marks a statement
whose source implies it without saying it. "Not established" means no
verified source covers it.

Abbreviations, used in the tables: "basic codes" = SGR `30`-`37`, `90`-`97`
and their backgrounds `40`-`47`, `100`-`107`; "index 0-15" = `38;5;0` to
`38;5;15`; "index 16-255" = `38;5;16` to `38;5;255`.

Source key (each statement about a terminal or tool carries one):

| key | source | version or date |
|---|---|---|
| `[WT-schemes]` | https://learn.microsoft.com/en-us/windows/terminal/customize-settings/color-schemes | page updated 2025-08-21 |
| `[WT-appear]` | https://learn.microsoft.com/windows/terminal/customize-settings/profile-appearance | page updated 2025-08-21 |
| `[WT-schema]` | https://raw.githubusercontent.com/microsoft/terminal/main/doc/cascadia/profiles.schema.json | main branch, fetched 2026-11-02 |
| `[MS-vt]` | https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences | page updated 2025-08-05 |
| `[MS-24bit]` | https://devblogs.microsoft.com/commandline/24-bit-color-in-the-windows-console/ | 2016-09-22, Windows 10 build 14931 |
| `[linux-cc]` | https://man7.org/linux/man-pages/man4/console_codes.4.html | Linux man-pages 6.19, 2026-07-29 |
| `[linux-cc-arch]` | https://man.archlinux.org/man/console_codes.4.en | Linux man-pages 6.20, 2026-07-29 |
| `[apple-term]` | https://support.apple.com/guide/terminal/trmltxt/mac | version not labelled on the page |
| `[wiki-tahoe]` | https://en.wikipedia.org/wiki/MacOS_Tahoe | macOS 26, 2025-09-15 |
| `[iterm-colors]` | https://iterm2.com/documentation-preferences-profiles-colors.html | |
| `[iterm-text]` | https://iterm2.com/documentation-preferences-profiles-text.html | |
| `[iterm-faq]` | https://iterm2.com/faq.html | |
| `[vte-colors]` | https://www.valadoc.org/vte-2.91/Vte.Terminal.set_colors.html | VTE 2.91 API |
| `[vte-bold]` | https://valadoc.org/vte-2.91/Vte.Terminal.bold_is_bright.html | since VTE 0.52 |
| `[vte-242]` | https://gitlab.gnome.org/GNOME/vte/-/issues/242 | |
| `[gnome-colors]` | https://help.gnome.org/gnome-terminal/app-colors.html | no software version given |
| `[konsole-2010]` | https://mail.kde.org/pipermail/konsole-devel/2010-June/014900.html | 2010-06-01 |
| `[konsole-2012]` | https://mail.kde.org/pipermail/konsole-devel/2012-April/019392.html | 2012-04-15 |
| `[konsole-src]` | https://invent.kde.org/utilities/konsole/-/raw/master/src/profile/Profile.cpp | master branch, fetched 2026-11-02 |
| `[xterm-ctlseqs]` | https://invisible-island.net/xterm/ctlseqs/ctlseqs.html | |
| `[xterm-faq]` | https://invisible-island.net/xterm/xterm.faq.html#color_by_number | |
| `[xterm-man]` | https://invisible-island.net/xterm/manpage/xterm.html | xterm patch 411, 2026-08-24 |
| `[tmux-man]` | https://man.openbsd.org/tmux | |
| `[tmux-faq]` | https://github.com/tmux/tmux/wiki/FAQ | |
| `[lwn-screen]` | https://lwn.net/Articles/987700 | GNU screen 5.0.0, 2024-08-29 |
| `[vsc-appear]` | https://code.visualstudio.com/docs/terminal/appearance | |
| `[vsc-config]` | https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/contrib/terminal/common/terminalConfiguration.ts | main branch, fetched 2026-11-02 |
| `[vsc-146406]` | https://github.com/microsoft/vscode/issues/146406 | VS Code 1.66, 2022 |
| `[xtermjs-opts]` | https://xtermjs.org/docs/api/terminal/interfaces/iterminaloptions/ | |
| `[xtermjs-4262]` | https://github.com/xtermjs/xterm.js/issues/4262 | closed 2023-08-13, milestone 5.3.0 |
| `[alacritty-conf]` | https://alacritty.org/config-alacritty.html | |
| `[alacritty-man]` | https://man.archlinux.org/man/alacritty.5.en | Alacritty 0.17.0 |
| `[kitty-conf]` | https://sw.kovidgoyal.net/kitty/conf/ | |
| `[wez-appear]` | https://wezterm.org/config/appearance.html | |
| `[wez-bold]` | https://wezterm.org/config/lua/config/bold_brightens_ansi_colors.html | |
| `[ghostty-conf]` | https://ghostty.org/docs/config/reference | |
| `[wiki-ansi]` | https://en.wikipedia.org/wiki/ANSI_escape_code#Colors | |
| `[termstd]` | https://github.com/termstandard/colors | |
| `[gh-blog]` | https://github.blog/engineering/user-experience/building-a-more-accessible-github-cli/ | 2025-05-02, updated 2025-05-12; gh 2.72.0 |
| `[gh-changelog]` | https://github.blog/changelog/2025-05-01-improved-accessibility-features-in-github-cli | 2025-05-01; gh 2.72.0 |
| `[gh-env]` | https://cli.github.com/manual/gh_help_environment | |
| `[go-gh-color]` | https://pkg.go.dev/github.com/cli/go-gh/v2@v2.12.0/pkg/x/color | go-gh 2.12.0 |
| `[bat-readme]` | https://github.com/sharkdp/bat/blob/master/README.md | |
| `[bat-490]` | https://github.com/sharkdp/bat/issues/490 | comments of 2019 |
| `[fzf-man]` | https://man.archlinux.org/man/fzf.1 | fzf 0.74.5 |
| `[git-config]` | https://git-scm.com/docs/git-config | git 2.56.0 |
| `[git-color]` | https://github.com/git/git/blob/master/color.c | master, fetched 2026-11-02 |
| `[dircolors]` | https://github.com/coreutils/coreutils/blob/master/src/dircolors.hin | master, fetched 2026-11-02 |
| `[nvim-theme]` | https://neovim.io/doc/user/dev_theme/ | |
| `[nvim-010]` | https://neovim.io/doc/user/news-0.10/ | Neovim 0.10 |
| `[ripgrep]` | https://raw.githubusercontent.com/BurntSushi/ripgrep/master/crates/core/flags/defs.rs | master, fetched 2026-11-02 |
| `[eza]` | https://www.mankier.com/5/eza_colors | |
| `[delta]` | https://dandavison.github.io/delta/tips-and-tricks/24-bit-color-truecolor.html | |
| `[supports-color]` | https://github.com/chalk/supports-color/blob/main/readme.md | |
| `[chalk]` | https://github.com/chalk/chalk | |
| `[no-color]` | https://no-color.org/ | |
| `[colours-blog]` | https://jvns.ca/blog/2024/10/01/terminal-colours/ | 2024-10-01 |

---

## 1. What `ltl` writes today

Read from `ltl` on `release/0.20.0`; code is referenced by sub or by the
global's declaration. The codes in the generated `-HL` twins are the strings
`ltl` builds, evaluated outside `ltl`.

### 1.1 Code classes

| class | codes |
|---|---|
| basic fg | `30`-`37`, also written `0;3N` (reset, then colour) |
| basic bg | `40`-`47`; only the pause prompt writes one |
| bright | `90`-`97` fg; no bright background (`100`-`107`) is written |
| index 0-15 | `38;5;N` / `48;5;N`, N 0-15: the terminal scheme's own sixteen |
| index 16-255 | `38;5;N` / `48;5;N`, N 16-255: xterm cube and grey ramp |
| 24-bit | `38;2;R;G;B` / `48;2;R;G;B` |
| attribute | `0` reset, `1` bold, `2` faint, `4` underline, `7` reverse, `22`, `24`, `49` default background |
| non-standard | `109`, in no defined SGR range; terminals ignore it |

### 1.2 The two source tables

**`@column_colors`** (grep `my @column_colors = (`): the metric colours.

| name | `fg` | `plain_bg` | `highlighted_bg` | `*_bg_num` (plain / highlighted) | gradient dark / light |
|---|---|---|---|---|---|
| yellow | `0` + `93` bright | `48;5;184` + `38;5;0` | `48;5;226` + `38;5;0` | 184 / 226 | 58..226 / 230..202 |
| green | `0` + `32` basic | `48;5;34` + `38;5;0` | `48;5;46` + `38;5;0` | 34 / 46 | 22..154 / 194..35 |
| cyan | `0` + `36` basic | `48;5;30` | `48;5;36` | 30 / 51 | 23..123 / 195..30 |
| blue | `0` + `34` basic | `48;5;20` | `48;5;21` | 20 / 27 | 17..39 / 189..27 |
| magenta | `0` + `35` basic | `48;5;127` | `48;5;201` | 127 / 207 | 53..207 / 225..93 |
| red | `0` + `31` basic | `48;5;124` | `48;5;196` | 124 / 196 | 52..209 / 224..124 |
| orange | `0` + `38;5;208` | `48;5;166` | `48;5;208` | 166 / 208 | 94..215 / 223..166 |
| pink | `0` + `38;5;213` | `48;5;169` | `48;5;213` | 169 / 213 | 132..219 / 225..169 |
| teal | `0` + `38;5;43` | `48;5;29` | `48;5;43` | 29 / 43 | 23..50 / 158..29 |
| purple | `0` + `38;5;93` | `48;5;55` | `48;5;93` | 55 / 93 | 54..171 / 189..55 |

Every `plain_bg` and `highlighted_bg` string carries `38;5;0`, index 0 (the
scheme's black), as the text over the fill. For cyan, blue and magenta the
`highlighted_bg_num` used by histograms (51, 27, 207) differs from the
`highlighted_bg` string used by the timeline and summary (36, 21, 201).
`%heatmap_special_gradients` (`white`, 238..255, light 255..238) is all
index 16-255.

**`%colors`** (grep `my %colors = (`): categories and named colours.

| keys | code | class |
|---|---|---|
| log levels, HTTP families, GC phases, lifecycle words | `0;31` to `0;36` | basic fg |
| red, green, yellow, blue | `0;31` to `0;34` | basic fg |
| black, magenta, cyan | `30`, `35`, `36`, each + `49` | basic fg + attribute |
| white | `36` then `37` (the `36` is overridden at once) | basic fg |
| err-rate, bright-red, bright-black, bright-green, bright-blue, bright-magenta, bright-white | `91`, `90`, `92`, `94`, `95`, `97`, each + `109` | bright + non-standard |
| bright-yellow, bright-cyan | `93`, `96` | bright |
| msg-rate, NC | `0` | attribute |
| kelly-green, rosso-corsa, gold, amethyst, periwinkle | `38;5;34`, `38;5;160`, `38;5;178`, `38;5;135`, `38;5;111` | index 16-255 |
| `*-underline` | `4;30` to `4;37` | attribute + basic fg |

The `-HL` twin (grep `foreach my $key (keys %colors)`) strips the first
escape and matches the rest against the exact strings `0;31`, `0;33`, `0;32`,
`0;34`, `0;35`. Only those keys get a background: `48;5;196`, `48;5;226`,
`48;5;46`, `48;5;21`, `48;5;201` respectively. Every other key (AUDIT,
CREATE, cyan, the bright keys, the 256-colour shades, the underline keys)
gets its own code + `49` and no background, so `bright-yellow-HL` is
`93`+`49` (seen in the run as the messages-table header).

### 1.3 By surface

| surface | element | codes | class | sub | light variant | emphasis |
|---|---|---|---|---|---|---|
| timeline header | rules, column names, footer rule, separator `│` | `90`+`109` | bright, non-standard | `print_bar_graph`, `print_heatmap_footer_scale` | none | none |
| timeline header | week fold weekday | `1` ... `0` (`print "\033[1m" . uc($1)`) | attribute | `print_bar_graph` | none | bold over the default foreground |
| timeline legend | `CAT: n` | category code, e.g. `0;33` | basic | `print_bar_graph` | none | none |
| timeline legend | highlighted count | twin, e.g. `0;33`+`48;5;226` | basic fg over index 16-255 bg | `print_bar_graph` | none | none |
| timeline legend | `err:` rate; `msg/unit` rate | `91`+`109`; `0`, unit and `:` in `90`+`109` | bright, attribute | `print_bar_graph` | none | none |
| occurrences bar | blocks | category code or its twin (the full block shows the fg) | basic | `print_bar_graph` | none | none |
| metric columns | bar body, highlighted / plain | `highlighted_bg` / `plain_bg`, each with `38;5;0` | index 16-255 bg, index 0 fg | `print_bar_graph` | none | none |
| metric columns | value text past the bar | `fg`: `93`, `32`, `36`, `34`, `35`, `31`, or `38;5;208/213/43/93` | bright / basic / index 16-255 | `print_bar_graph` | none | none |
| success / failure % | cells | `38;5;34`, `38;5;160` | index 16-255 | `print_bar_graph` (`value_color` from `build_column_layout`) | none | none |
| latency column | P50, P95, P99, P999 | `36`+`49`, `0;33`, `93`, `0;31` | basic, bright | `print_bar_graph` | none | none |
| latency column | CV below 20 / 20 or above | `4;37` / `0;33`+`48;5;226` | underline + basic / basic over index 16-255 | `print_bar_graph` | none | underline |
| heatmap | cell | `38;5;N` from the metric's 8-step gradient | index 16-255 | `print_heatmap_row` | **yes**: `gradient_light` | none |
| heatmap | highlighted cell | `48;5;<plain_bg_num>` + `38;5;N` | index 16-255 | `print_heatmap_row` | fg only | none |
| heatmap | percentile marker, scale footer | `90`+`109` | bright | `print_heatmap_row`, `print_heatmap_footer_scale` | none | none |
| histogram | full, partial and highlighted bins | `38;5;B;48;5;B`, `38;5;B`, split cells `38;5;H;48;5;B` | index 16-255 | `render_histogram_row` | none (the gradient is off) | none |
| histogram | gridline `─` | `38;5;8` (`$histogram_gridline_color = 8`) | index 0-15 | `render_histogram_row` | none | none |
| histogram | highlighted percentile band | `48;5;H` + `38;5;0` (`my $fg_color = 0;`) | index 16-255 bg, index 0 fg | `render_histogram_legend` | none: the same black on every background, by #653 (histogram highlight row on a light background) | none |
| run summary | category row text | `fg` of the matched bar entry (`93` for every `0;33` category, `32`, `36`, `34`, `35`, `31`) | bright / basic | `summary_category_row` via `summary_bar_color` | none | none |
| run summary | contribution bar fill | `plain_bg` / `highlighted_bg` with `38;5;0`; `7` under `-sm` | index 16-255 bg, index 0 fg; reverse | `summary_category_row` | none | reverse under `-sm` |
| run summary | classification rows | `38;5;34`, `38;5;160`, `38;5;178`, `38;5;135` | index 16-255 | `print_summary_table` via `summary_colour` | none | none |
| run summary | file-details and `Log Formats` headings | `4;37` | underline + basic | `print_summary_table` | none | underline over `37` |
| run summary | file marks, file line, format number, run options | `0;31`, `0;32`, `0;32`+`48;5;46`; `36`+`37`; `38;5;111`; `90`+`109` | basic, index 16-255, bright | `print_summary_table`, `print_run_options` | none | none |
| messages and thread-pool tables | header rows and rules | `93`+`49`, `96`+`49`, `95`+`109`+`49` | bright | `print_message_summary`, `print_threadpool_summary` | none | none |
| messages table | classification marker | `38;5;34/160/135/178` | index 16-255 | `print_message_summary` | none | none |
| title banner | banner | `0;37` (one space), then `90`+`109`, `0` | basic, bright, non-standard | `get_title_string` | none | none |
| help and explain | headings, table bold cells | `1` ... `22` | attribute | `bs_bold` in `help_heading`, `render_table` | none | bold over the default foreground |
| help and explain | sub-headings | `4` ... `24` | attribute | `bs_underline` | none | underline |
| explain examples | heatmap, histogram, timeline, summary twins, histogram shape | as the run: index 16-255 cells, `90` marker, basic category codes | as the run | `print_explain_topic`, `explain_timeline_rows`, `explain_histogram_shape` | none | none |
| explain examples | message block title | `36`+`49` then `bs_bold(...)` | basic | `explain_message_rows` | none | bold over basic `36` |
| error line | `Error: ...` on stderr | `1` ... `22` | attribute | `print_usage_error` | none | bold over the default foreground |
| pause prompt | prompt; `Exiting program.` | `0;44`; `0;35` | basic bg (the only one); basic fg | `pause_for_keypress` | none | none |
| progress | stage `... completed.` lines | `92`+`109` | bright, non-standard | `read_and_process_logs` and the other stage subs | none | none |

A WARN row reads `0;33` in the timeline legend and `93` in the summary,
because the summary re-routes the hue through `@column_colors`.

Bold and underline in help follow `help_ansi_enabled` (`FORCE_COLOR`,
`NO_COLOR`, TTY). The rest of the output, including the `%colors` and
`@column_colors` codes, does not consult `NO_COLOR`.

### 1.4 The notice surfaces

The notice panel, ask modal and browser of #412 (notice surfaces) build their
codes once per run in `notice_style`, for the background returned by
`notice_background` (the `-lbg`/`-dbg`/heatmap result, else
`detect_terminal()->{background}`, which is `dark` when the terminal does
not answer).

| key | dark | class | light | class |
|---|---|---|---|---|
| frame | `90` | bright | `38;5;244` | index 16-255 |
| text | `37` | basic | `38;5;16` | index 16-255 |
| dim | `2` | attribute | `38;5;244` | index 16-255 |
| bold | `1` | attribute | `1` | attribute |
| pick | `1;97` | bold + bright | `1;38;5;16` | bold + index 16-255 |
| category fg, orange and teal | `38;5;208`, `38;5;43` | index 16-255 | 166, 29 (last of `gradient_light`) | index 16-255 |
| category fg, magenta, cyan, blue, green | 170, 44, 33, 40 (`@notice_category_sheet`) | index 16-255 | 93, 30, 27, 35 | index 16-255 |

Emphasis over a basic or bright code on these surfaces: the notice focus in
`notice_rows` is `bold` + `text` (dark: bold over `37`); the options heading
row and the selected option in `notice_options_rows`, and the browser's All
tab in `notice_browser`, are `pick` (dark: bold over `97`). Other bold sits
over index 16-255 (category headings in `notice_heading`, selected buttons in
`notice_button_row`, selected browser category tabs).

The layer under a pop-up, in `notice_dim_row`: on dark, every code is kept
with `1`/`2`/`22` removed (`notice_sgr_without_weight`) and `2` appended, so
faint goes over basic, bright and 256-colour codes alike. On light,
`notice_light_dimmed_sgr` rewrites each colour as 24-bit half way to white,
`0` and `39` become `38;5;244`, and bold and faint are dropped. It resolves
basic and bright codes through a hard-coded xterm table
(`my @notice_xterm16 = ( [ 0, 0, 0 ], [ 205, 0, 0 ], ...`) and index 16-255
through the xterm cube (`notice_rgb_of_index`). It is `ltl`'s only 24-bit
writer, and it assumes the xterm defaults for the sixteen, not the
terminal's scheme.

### 1.5 Light-background coverage

Two surfaces switch codes on a light background: the heatmap cell gradient
(`print_heatmap_row`) and the notice surfaces (`notice_style`,
`notice_dim_row`). Every other surface writes the same codes on both,
including all basic and bright foregrounds, the `38;5;0` text over fills
and the bright-black rules.

### 1.6 The screenshot renderer

`process/capture-screenshots.pl` (spec `features/598-screenshot-capture.md`,
screenshot capture) builds one 256-entry table per background in
`palette_for`: indices 0-15 are the sixteen ANSI colours of the macOS
Terminal.app profiles "Clear Dark" and "Clear Light" (`%profiles`; dark
index 0 is a slate `#35424c`, not black); 16-231 the xterm cube; 232-255
the grey ramp. `build_grid` maps basic codes and `38;5;0-15` alike to the
profile colours, index 16-255 to the cube, and `38;2` to the literal RGB.
Bold with an explicit colour keeps that colour and is drawn bold (no bright
shift); faint is the foreground half way to the background (`faint_of`);
`109` is ignored. So in the images, the `38;5;0` fill text and the
`38;5;8` gridline take the profile's slate and grey, and every basic and
bright code takes the profile's colours.

### 1.7 Harnesses that read specific codes

| file | what it reads |
|---|---|
| `tests/lib/rendered-output.pl` (`decode_line`) | decodes basic and bright codes to `ansi:<code>`, `38;5`/`48;5` to `256:<n>`, `7`, bold and faint. No case for `38;2`/`48;2`: `38` falls through, `2` sets faint, R;G;B are read as parameters. Used by the harnesses below and by `tests/lib/screenshot-cells.pl`, `tests/lib/surface-capture.pl` |
| `tests/validate-notices.sh` | `ansi:90` frame and title, `ansi:37` focus text (dark); named 256 indices for categories; light `256:244`, `256:16` and light category indices; bold and dim flags |
| `tests/validate-summary-contribution-bar.sh` | fills `48;5;124`, `48;5;46`, `48;5;34`; no-fill row `ESC[31m`; `38;5;0` in every fill; `7` under `-sm`; evals `summary_bar_color`, which matches `/(?:^|\D)[349](\d)m/`, so a category code moved off `3N`/`9N` returns no bar |
| `tests/validate-classification-percentages.sh` | `38;5;34`, `38;5;160`, `38;5;178` before the classification labels; their absence under `-sm` |
| `tests/validate-classification-states.sh` | markers `256:34`, `256:160`, `256:135`, `256:178` |
| `tests/validate-histogram-colours.sh` | percentile band `fill=256:<highlighted_bg_num> text=256:0` |
| `tests/validate-heatmap-palette.sh` | literal gradient arrays and a mirrored `PLAIN_BG_NUM` table |
| `tests/validate-screenshot-capture.sh` | each image cell's colour equals `ltl`'s code mapped through the renderer's table |
| `tests/validate-explain.sh` | `\x1b[1m` / `\x1b[4m` under `FORCE_COLOR`, their absence otherwise |

Harnesses that only strip `\e\[[0-9;]*m` are unaffected by a change of code.

### 1.8 Where the code and the documents differ

Observations from the reading, not findings: no record was searched for one
that makes the behaviour deliberate beyond the two documents quoted.

- `docs/terminal-output.md` § Colour and emphasis: "Bold is applied only over
  a 256-colour or 24-bit foreground." The code also writes bold over the
  default foreground (`bs_bold`, the week fold), over `37` (notice focus),
  over `97` (`pick` on dark) and over `36` (`explain_message_rows`). The
  same section marks the help-text case "not yet measured" and defers it to
  #749 (this research).
- The same section: "`%colors` writes basic codes throughout". `%colors` also
  holds the five index 16-255 shades (kelly-green to periwinkle), and
  `pause_for_keypress` writes the one basic background `0;44`.
- The same section's measured table compares `30` with `38;5;16`. `ltl`'s
  fill text and histogram band text are `38;5;0`, index 0, the scheme's
  black, not the fixed index 16; the gridline is index 8.
- `docs/design-language.md` § Emphasis: bold and underline "appear only in
  help and explain text". Underline is also written by `white-underline`
  (`4;37`) on summary headings and the CV cell, and by `notice_lettered`.
- `docs/terminal-output.md`: "Faint (SGR 2) is used only where the background
  is known to be dark". `notice_background` falls back to a `dark` default
  (`%terminal = ( name => 'unknown', background => 'dark' );`), so faint is
  written when no reply came. The same document's table of what is found at
  start reads the background as "dark when no reply comes", so the code
  follows that line; the difference is with the word "known".

---

## 2. How terminals draw each kind of colour code

### 2.1 Matrix

| terminal | basic codes repainted by the scheme | index 0-15 repainted | index 16-255: fixed or redefinable | 24-bit |
|---|---|---|---|---|
| macOS Terminal.app | yes: profiles carry sixteen ANSI colours (the screenshot renderer reads "Clear Dark" and "Clear Light", § 1.6) | not established | not established | yes since macOS 26 (Tahoe, 2025-09-15) [termstd, wiki-tahoe]; earlier versions lacked it (inferred) [wiki-tahoe] |
| iTerm2 | yes: the profile defines the sixteen, ships presets, may hold separate light and dark colours [iterm-colors] | not established | not established | yes since v3, colon and semicolon forms [termstd] |
| GNOME Terminal and other VTE terminals | yes: the `set_colors` palette starts with 8 standard and 8 bright [vte-colors] | yes (inferred) [vte-colors] | accepts 0, 8, 16, 232 or 256 entries, omitted entries hard-coded [vte-colors]; a VTE issue proposes deprecating setting colours above 16 [vte-242] | yes since VTE 0.36 [termstd]; sets `COLORTERM=truecolor` [termstd] |
| Konsole | not established | not established | not established | yes, colon and semicolon [termstd]; sets `COLORTERM=truecolor` [termstd] |
| xterm | yes: 0-7 ANSI, 8-15 bright, set by resources [xterm-ctlseqs, xterm-faq] | yes: 0-15 are the same table [xterm-ctlseqs] | default 16-231 cube, 232-255 grey ramp [xterm-faq]; every entry changeable by OSC 4, reset by OSC 104 [xterm-ctlseqs]; resources past 16 a compile-time option since patch 129 [xterm-faq] | direct colour from version 331 with `directColor`; without it, the nearest palette entry [xterm-ctlseqs, termstd] |
| tmux | not established | not established | style colours accept `colour0`..`colour255` or hex RGB [tmux-man] | yes since 2.2 [termstd], only when told the outer terminal has RGB (`terminal-features` RGB from 3.2, `terminal-overrides` Tc in any version) [tmux-man, tmux-faq]; 256 colours need `default-terminal` `screen-256color`/`tmux-256color` and a 256-colour `TERM` outside, or `-2` [tmux-man, tmux-faq] |
| GNU screen | not established | not established | not established | `truecolor on/off` command since 5.0.0 (2024-08-29) [termstd, lwn-screen] |
| Windows Terminal | yes: schemes in settings.json hold the sixteen named colours (that they hold only these is inferred) [WT-schemes]; measured (terminal-output) | not established (the measurement used index 16, not index 0) | not established; index 16 measured (terminal-output) | yes, semicolon form [termstd] |
| Windows console host (conhost) | yes: SGR colours use the console colour table, changeable by `SetConsoleScreenBufferInfoEx`; OSC 4 sets an entry [MS-vt] | not established | internal 88/256 tables based on xterm, not modifiable [MS-vt] | contradicted: Microsoft Learn (updated 2025-08-05) says nearest of 16 for `38;5` and `38;2` [MS-vt]; 24-bit announced in build 14931 (2016-09-22) [MS-24bit]; termstandard lists it as fully supporting [termstd] |
| Linux virtual console | yes: entries 0-15 set by `ESC ] P`, reset by `ESC ] R` [linux-cc] | yes: `38;5` 0-15 are the basic colours [linux-cc] | cube and ramp defined [linux-cc], but since Linux 3.16 256-colour and 24-bit foregrounds are reduced to 16 colours and backgrounds to 8; before 3.16 SGR 38 set underscore [linux-cc, termstd, linux-cc-arch] | partial: parsed, reduced to 16 fg / 8 bg [linux-cc, termstd] |
| VS Code integrated terminal (xterm.js) | yes: from the colour theme, overridable by `workbench.colorCustomizations` [vsc-appear] | not established | not established | yes, xterm.js 3.13 (4.3 for WebGL) [termstd, vsc-appear] |
| Alacritty | yes: configurable normal and bright tables, default black #181818 [alacritty-conf] | yes, from the normal and bright tables (inferred from `indexed_colors` covering 16 up) [alacritty-conf] | `indexed_colors` sets 16-255, empty by default, filled with defaults [alacritty-conf] | yes, colon and semicolon [termstd] |
| kitty | yes: `color0`..`color15`, default `color0` #000000 [kitty-conf] | yes: the first 16 are `color0`..`color15` [kitty-conf] | `color16`..`color255` settable [kitty-conf] | yes, colon and semicolon [termstd] |
| WezTerm | yes: over 700 shipped schemes; `color_scheme` overrides `colors` [wez-appear] | not established | `colors.indexed` sets 16-255 [wez-appear] | yes, colon and semicolon [termstd] |
| Ghostty | yes: a theme, built-in or custom, with separate light and dark [ghostty-conf] | yes: `palette` covers 0-255 [ghostty-conf] | `palette` sets 0-255; `palette-generate` (since 1.3.0, default off) derives 16-255 from the base 16; the same page also says 16-255 are generated by default, contradicting itself [ghostty-conf] | yes, semicolon [termstd] |

### 2.2 Notes

- **No shipped scheme found redefines index 16-255.** No source names one.
  The only redefinition found is the base16-shell script, which sets 16-21
  [colours-blog]. termstandard states every 256-palette entry is separately
  reprogrammable [termstd]; 8-bit values vary between implementations because
  no palette is specified, the 16-231 cube in particular [wiki-ansi].
- **The scheme repaints the sixteen basic colours** wherever a source covers
  it, not only in Windows Terminal: Terminal.app (§ 1.6), iTerm2
  [iterm-colors], VTE [vte-colors], xterm [xterm-ctlseqs, xterm-faq], VS Code
  [vsc-appear], Alacritty [alacritty-conf], kitty [kitty-conf], WezTerm
  [wez-appear], Ghostty [ghostty-conf], conhost [MS-vt] and the Linux
  console [linux-cc]. No standard fixes their values, and terminals choose
  them inconsistently [wiki-ansi, colours-blog]. For Konsole, tmux and GNU
  screen it is not established.
- **Index 16-255 are the xterm cube and ramp by default** [xterm-faq,
  linux-cc]. The user can redefine them in xterm [xterm-ctlseqs, xterm-faq],
  VTE [vte-colors], kitty [kitty-conf], Alacritty [alacritty-conf], WezTerm
  [wez-appear] and Ghostty [ghostty-conf], but no shipped scheme found does.
  Index 16 is measured holding its value in Windows Terminal (terminal-output).
  Exceptions: base16-shell overwrites 16-21 [colours-blog]; Ghostty can
  derive 16-255 from the base 16 when `palette-generate` is on (off by
  default, since 1.3.0) [ghostty-conf]; implementations differ on the cube
  [wiki-ansi].
- **Index 0-15 written as `38;5;N` are the scheme's colours** wherever a
  source covers it: xterm [xterm-ctlseqs], the Linux console [linux-cc],
  kitty [kitty-conf], VTE (inferred) [vte-colors]. Moving to `38;5;N` fixes a
  colour only for N of 16 or more.
- **Where 256-colour codes are reduced to 16:** the Linux console since 3.16
  [linux-cc]. The Microsoft Learn page says conhost does the same [MS-vt],
  which is contradicted [MS-24bit, termstd]. xterm without direct colour maps
  24-bit to the nearest palette entry [xterm-ctlseqs]. tmux passes 256-colour
  and 24-bit codes only when configured [tmux-faq]. Where codes are reduced,
  the result is again a scheme colour.

---

## 3. Bold and faint

### 3.1 Per terminal

| terminal | bold on a basic colour or the default foreground | bold over index 16-255 | faint |
|---|---|---|---|
| macOS Terminal.app | settings "Use bold fonts" and "Use bright colors for bold text", plus a "Bold Text" colour well; no default and no version given [apple-term] | not established | not established |
| iTerm2 | "Draw bold text in bold font" (bold face, or double strike) [iterm-text]; the FAQ also names "Draw bold text in bright colors", which the current documentation does not list [iterm-faq]; a Bold colour setting [iterm-colors]; defaults not established | not established | "Faint text opacity", floor 0.1: faint by opacity (inferred) [iterm-colors] |
| GNOME Terminal and other VTE terminals | `bold_is_bright` since VTE 0.52, default not on the API page [vte-bold]; GNOME Terminal "Show bold text in bright colors": off is the new default, on is for backward compatibility [gnome-colors] | brightening applies to the first 8 palette colours; others not brightened (inferred) [vte-bold] | not established |
| Konsole | per-profile `BoldIntense`, default true (inferred from source) [konsole-src], enabling or disabling boldness [konsole-2012]; KDE3 made the colour bright without changing weight [konsole-2010]; whether current Konsole also brightens is not established | not established | not established |
| xterm | both by default: `boldColors` (default true) maps 0-7 to 8-15; `boldMode` (default true) overstrikes when the bold font equals the normal one; `colorBDMode` (default false) can show bold as a colour instead [xterm-man]; the default foreground is not named | brightening named only for 0-7 [xterm-man] | the RGB of the current colour scaled, absolutely by default, relative to the background with `faintIsRelative` (default false) [xterm-man] |
| tmux, GNU screen | not established | not established | not established |
| Windows Terminal | `intenseTextStyle` none/bold/bright/all, default `bright` (bright, not bold) [WT-appear, WT-schema]; measured: bright variant, normal weight (terminal-output) | measured: bold weight, colour kept (terminal-output) | measured: darker (terminal-output) |
| Windows console host (conhost) | SGR 1 sets a brightness/intensity flag on the foreground; no setting [MS-vt]; VT sequences only with `ENABLE_VIRTUAL_TERMINAL_PROCESSING` [MS-vt] | if mapped to the nearest of 16, bold acts on a 16-colour entry (inferred) [MS-vt] | not established |
| Linux virtual console | SGR 1 "set bold"; `90`-`97` bright [linux-cc-arch]; rendering not established | n/a: the colour is reduced to 16 [linux-cc] | half-bright simulated with a colour; a private sequence sets the dim colour [linux-cc, linux-cc-arch] |
| VS Code integrated terminal | both by default: `drawBoldTextInBrightColors` default true [vsc-appear, vsc-config, xtermjs-opts], `fontWeightBold` default `bold` [vsc-config] | not established | not established; dim text gets half the minimum contrast ratio since xterm.js 5.3.0 [xtermjs-4262] |
| Alacritty | bright only with `draw_bold_text_with_bright_colors`, default false (0.17.0) [alacritty-conf, alacritty-man]; weight not stated | not established | dim colours computed from the normal colours when not set [alacritty-conf, alacritty-man]; for 16-255 not established |
| kitty | no bold-is-bright option; bold by font face (inferred) [kitty-conf] | not established | `dim_opacity`, default 0.4 [kitty-conf] |
| WezTerm | `bold_brightens_ansi_colors` default true = BrightAndBold (bright palette plus bold font); BrightOnly since 20230320 [wez-bold]; not applied to the default foreground [wez-bold] | brightens 0-7 only (inferred) [wez-bold] | not established |
| Ghostty | `bold-color = bright` uses the bright palette, since 1.2.0, replacing `bold-is-bright`; a specific `bold-color` is used for default bold text [ghostty-conf]; default not established | not established | `faint-opacity`, 0 to 1 [ghostty-conf]; default not established |

### 3.2 Bold on a basic colour, grouped by default

| bold on a basic colour | terminals (default, version) |
|---|---|
| bright variant, normal weight, by default | Windows Terminal (`intenseTextStyle` = `bright`) [WT-appear]; conhost (intensity flag) [MS-vt] |
| bright variant and heavier weight, by default | VS Code [vsc-config]; xterm [xterm-man]; WezTerm, but not on the default foreground [wez-bold] |
| heavier weight only, by default | GNOME Terminal (bright is off in the new default) [gnome-colors]; Alacritty (bright off, 0.17.0) [alacritty-man]; kitty (no bright option, inferred) [kitty-conf] |
| has a setting, default not established | Terminal.app [apple-term]; iTerm2 [iterm-text, iterm-faq]; Ghostty [ghostty-conf]; Konsole (`BoldIntense` true is about weight, inferred) [konsole-2012, konsole-src] |

So "bright variant in normal weight" is Windows Terminal's default and
conhost's only behaviour. On macOS, Terminal.app and iTerm2 both expose a
bright-for-bold option, but no source states its default. Whether the
measured effect happens on macOS with a non-default scheme is therefore not
established from sources and has to be measured (§ 7.3, point 1). "Lighter
on a light scheme" follows from the scheme's bright colours being lighter
than its normal ones; that is inferred from the Windows Terminal measurement,
and no source states it for other schemes.

### 3.3 Bold and faint over index 16-255

- **Bold over index 16-255 is weight, not brightness.** Every source that
  describes bold brightening limits it to palette 0-7: xterm [xterm-man],
  VTE [vte-bold], WezTerm [wez-bold], all three inferred as to what is
  excluded. Windows Terminal is measured drawing it bold in its colour
  (terminal-output). For Terminal.app, iTerm2 and Ghostty it is not
  established.
- **Faint** is measured darker in Windows Terminal, including over
  `38;5;184` (terminal-output). xterm also derives faint by scaling RGB down,
  absolutely by default [xterm-man], which by that description darkens on
  any background (inferred). iTerm2 (inferred) [iterm-colors], kitty
  [kitty-conf] and Ghostty [ghostty-conf] use opacity. The Linux console
  simulates faint with a colour [linux-cc, linux-cc-arch]. Faint over index
  16-255 elsewhere is not established per index class.

---

## 4. Automatic contrast adjustment

| terminal | setting and default | scope over 256-colour and 24-bit codes |
|---|---|---|
| iTerm2 | Minimum Contrast shifts text (never the background) toward black or white; at 100 all text is black or white [iterm-colors]; default not established | it shifts "text colours" without exempting any (not stated) [iterm-colors] |
| Windows Terminal | `adjustIndistinguishableColors`: `indexed` adjusts only scheme colours, `always` all, `never` none [WT-appear]; the main-branch schema (2026-11-02) adds `automatic` as the default: `indexed` under Windows high contrast, `never` otherwise [WT-schema]; the shipped release's default is not established | `indexed` leaves 256-colour and 24-bit codes alone; `always` adjusts them [WT-appear] |
| VS Code integrated terminal | `minimumContrastRatio`, default 4.5 since VS Code 1.66, changes each cell's foreground, may desaturate; 1 disables [vsc-appear, vsc-config, vsc-146406]; the xterm.js library default is 1 [xtermjs-opts] | per cell, so 256-colour and 24-bit foregrounds are included (stated as "each cell") [vsc-config] |
| kitty | `text_fg_override_threshold`, default 0: no overriding [kitty-conf] | n/a by default |
| Ghostty | `minimum-contrast`, a WCAG 2.0 ratio from 1 to 21 [ghostty-conf]; default not established | not established |
| Terminal.app, VTE, Konsole, xterm, tmux, GNU screen, conhost, Linux console, Alacritty, WezTerm | not established | not established |

A user objected to VS Code's default that the terminal no longer shows the
colours the program asked for [vsc-146406]. Under such adjustment a
256-colour or 24-bit code does not hold its value either.

---

## 5. What other tools do

| tool | what it writes | stated reason |
|---|---|---|
| gh | an accessible palette on the sixteen 4-bit colours, a public preview behind `GH_ACCESSIBLE_COLORS` (2.72.0, May 2025), not gh's default [gh-blog, gh-changelog, gh-env, go-gh-color]; label colours as RGB hex only on opt-in `GH_COLOR_LABELS` [gh-env] | most terminals let users change only the sixteen, so users can customise gh's colours; serves low-vision and colour-blind users [gh-blog, gh-changelog]; based on GitHub's Primer accessibility foundations [gh-blog] |
| bat | an `ansi` theme in the eight 3-bit colours; `base16` in 4-bit; `base16-256` only for tinted-shell; Monokai chosen by detected background; 24-bit only with `COLORTERM` [bat-readme] | the `ansi` theme "looks decent on any terminal" [bat-readme]; the program cannot know the user's colours [bat-490] |
| fzf 0.74.5 | `dark` scheme on 256-colour terminals, `base16` otherwise, `bw` under `NO_COLOR`; accepts -1, 0-15, 16-255, `#rrggbb` [fzf-man] | not stated |
| git 2.56.0 | named colours as `30`-`37`/`90`-`97`, rewrites 0-15 to them, `38;5;N` and `38;2` when asked [git-config, git-color] | basic and aixterm codes are "more portable" (inferred from a code comment) [git-color] |
| GNU dircolors | default database in 8-colour codes; 256 permitted [dircolors] | not stated |
| Neovim 0.10 | a true-colour default scheme when detected, a minimal 16-colour fallback using the terminal's foreground and background [nvim-theme, nvim-010] | accessibility: contrast 7 (4.5 in common cases), palettes swapped for light and dark [nvim-theme, nvim-010] |
| ripgrep, eza | eight named colours by default; 256-colour and 24-bit when configured [ripgrep, eza] | not stated |
| delta | 24-bit with `COLORTERM` or `--true-color=always`, else the nearest colour [delta] | not stated |
| chalk, supports-color | levels 16 / 256 / truecolor, downsampling to what is supported; at level 1 chalk downsamples 256-colour and RGB to bright red `91` [supports-color, chalk] | terminal capability |

Neovim's 16-colour fallback picks slots 1-6 on light backgrounds and 9-14 on
dark [nvim-theme]. On the question of a fallback, termstandard advises
falling back to 8-bit when truecolor is not advertised [termstd], while gh,
bat, git and dircolors treat the sixteen as the portable, user-customisable
choice [gh-blog, bat-readme, git-color, dircolors]. gh speaks of user
preferences and termstandard of escape-sequence reprogramming [gh-blog,
termstd], so both can hold. `NO_COLOR` as a convention: [no-color].

---

## 6. What a move to 256-colour or 24-bit codes would give up or change

- **Following the user's scheme.** Basic colours change with the scheme;
  index 16-255 do not, in every scheme found (§ 2.2). gh aligned its
  accessible palette to the sixteen so that users can customise its colours
  [gh-blog], for low-vision and colour-blind users [gh-blog, gh-changelog].
  A fixed 256-colour code takes that adjustment away from the user. How
  Windows high contrast mode treats SGR colours: nothing found. The only
  related item is Windows Terminal's `automatic` default acting as `indexed`
  (scheme colours only) under high contrast [WT-schema].
- **Who owns contrast.** The background is the user's, set in the terminal;
  an application must take it into account to keep contrast [gh-blog]. gh's
  earlier palette ignored it and gave low contrast [gh-blog]. A fixed
  256-colour code puts contrast on `ltl` for both backgrounds. A 2024 survey
  of terminal colours reports fd's 256-colour entry 48 reading poorly on its
  author's scheme, and blue on black among the top complaints
  [colours-blog]. The program does not know what the user's colours look
  like [bat-490]; one ANSI theme flipping cleanly between light and dark was
  called impossible in 2019 [bat-490], though bat now ships a single `ansi`
  theme described as decent on any terminal [bat-readme]. `ltl` switches
  codes on a light background on only two surfaces (§ 1.5), so a
  fixed-colour move would make every other surface's contrast `ltl`'s
  responsibility on both backgrounds.
- **Terminals and multiplexers without the support.** The Linux console
  reduces 256-colour and 24-bit codes to 16 fg / 8 bg, and before 3.16 SGR
  38 meant underscore [linux-cc, termstd]. tmux needs the 256-colour `TERM`
  and RGB flags [tmux-faq]. GNU screen needs `truecolor on` (5.0.0)
  [lwn-screen]. Terminal.app has 24-bit only from macOS 26 [termstd,
  wiki-tahoe]. xterm without direct colour picks the nearest palette entry
  [xterm-ctlseqs]. conhost's handling is contradicted [MS-vt, MS-24bit].
  Detection: `COLORTERM` is set by VTE, Konsole and iTerm2, is not forwarded
  by sudo or ssh, and termstandard advises falling back to 8-bit when
  truecolor is not advertised [termstd]. `ltl`'s one 24-bit writer,
  `notice_light_dimmed_sgr`, assumes xterm defaults for the sixteen, not the
  scheme (§ 1.4). For 256 colours, `ltl` already writes index 16-255 for
  every background and most fills (§ 1.3).
- **Terminals that adjust colours anyway.** VS Code changes each cell's
  foreground to 4.5:1 by default, so a 256-colour or 24-bit code does not
  hold its value there either; Windows Terminal's `indexed` mode would leave
  them untouched, with its shipped default not established; iTerm2 shifts
  text with no default established; kitty does not adjust by default (§ 4).
- **The index 0-15 codes `ltl` already writes.** Every `plain_bg` and
  `highlighted_bg` carries `38;5;0` as the text over the fill, the
  histogram's highlighted percentile band writes `38;5;0`, and its gridline
  writes `38;5;8` (§ 1.2, § 1.3). These are scheme colours [xterm-ctlseqs,
  linux-cc, kitty-conf]: the codes the rule in `docs/terminal-output.md`
  calls "the terminal scheme's to repaint", not a fixed black. The measured
  table there used index 16, not index 0.
- **The help text's bold.** `bs_bold` (`1` ... `22`) is bold over the
  default foreground in help headings, table bold cells and the `Error:`
  line (§ 1.3). Windows Terminal draws it as the bright variant at normal
  weight (terminal-output). WezTerm does not brighten the default foreground
  [wez-bold]. For Terminal.app and iTerm2 it is not established. Other bold
  over basic or bright codes: the notice focus `1`+`37`, the dark `pick`
  `1;97`, the explain message title over `36`, and the week fold `1` (§ 1.3,
  § 1.4). Bold and underline in help obey `help_ansi_enabled`; the rest of
  the output does not consult `NO_COLOR` (§ 1.3).
- **The screenshot renderer.** It draws neither the bright-for-bold nor the
  darkening faint measured in Windows Terminal (§ 1.6). A move off basic
  codes would change which colours follow the profile in the images.
- **Harnesses that read codes** (§ 1.7). `decode_line` would mis-read 24-bit
  codes. `validate-summary-contribution-bar.sh` depends on
  `summary_bar_color` matching `[349]N m`, so a category moved off `3N`/`9N`
  returns no bar. `validate-notices.sh` reads `ansi:90` and `ansi:37`; the
  classification, histogram-colour, heatmap-palette and screenshot-capture
  harnesses assert specific codes.

---

## 7. Points to measure in the prototype

### 7.1 Contradictions between sources

| subject | one side | other side | standing |
|---|---|---|---|
| conhost beyond 16 colours | Microsoft Learn (updated 2025-08-05): nearest of 16 for `38;5` and `38;2` [MS-vt] | full 24-bit since build 14931 [MS-24bit, termstd] | unresolved |
| Ghostty index 16-255 | the `palette` entry: generated by default [ghostty-conf] | `palette-generate` defaults to off [ghostty-conf] | unresolved |
| Windows Terminal `adjustIndistinguishableColors` default | the Learn page gives no default and no `automatic` value [WT-appear] | the main-branch schema makes `automatic` the default [WT-schema] | likely a version difference; the shipped default is unknown |
| iTerm2 "Draw bold text in bright colors" | in the FAQ [iterm-faq] | absent from the current text settings page [iterm-text] | unresolved |
| fallback practice | 8-bit per termstandard [termstd] | the sixteen per gh, bat, git, dircolors [gh-blog, bat-readme, git-color, dircolors] | both can hold (§ 5) |
| gh default; bat on one ANSI theme | gh palette described as aligned [gh-blog]; one theme for light and dark called impossible in 2019 [bat-490] | gh palette is opt-in [gh-changelog, gh-env]; bat now ships `ansi` [bat-readme] | explained by scope and date |

### 7.2 Not established

- Terminal.app and iTerm2 defaults for bright-for-bold, bold weight and the
  bold colour, and whether Terminal.app's Bold Text colour applies to
  coloured bold or only to default-foreground bold [apple-term, iterm-text,
  iterm-faq, iterm-colors].
- Bold over an index 16-255 foreground in Terminal.app, iTerm2, VS Code,
  Alacritty, kitty and Ghostty.
- Faint rendering in Terminal.app, Konsole, VTE, WezTerm and conhost, and
  iTerm2's faint-opacity default.
- iTerm2's Minimum Contrast default and Ghostty's `minimum-contrast` default.
- Whether index 0-15 via `38;5;N` are repainted in Terminal.app, iTerm2,
  Windows Terminal, WezTerm and VS Code.
- Any shipped scheme that redefines index 16-255, and what Ghostty uses for
  16-255 with generation off.
- What Terminal.app before macOS 26 did with `38;2`. Whether tmux
  approximates colours to the outer terminal's capability.
- How Windows high contrast mode treats SGR colours.
- Konsole's scheme handling and colour brightening under `BoldIntense`.
  tmux and GNU screen handling of bold.
- Three of the survey's questions on bold, faint and contrast adjustment
  were recorded as unanswered without their text.

### 7.3 Measurements

Method as in `docs/terminal-output.md` § Colour and emphasis: the darkest
pixel of a run of text and its weight, read from a screenshot.

| # | terminal and scheme | sequence | reading that settles it |
|---|---|---|---|
| 1 | Terminal.app and iTerm2, default profile light and dark (Terminal.app "Clear Light/Dark"; iTerm2 a light and a dark preset), settings untouched | `30`, `1;30`, `1` on the default fg, `33`, `1;33`, `37`, `1;37` | bold pixel lighter than plain at the same weight: bright-for-bold is on by default, as in Windows Terminal; same colour, heavier: weight only. Record the bold settings' state (Terminal.app "Use bright colors for bold text", iTerm2 bold options) beside the reading |
| 2 | the same four, plus Windows Terminal One Half Light and Campbell | `38;5;0` beside `30` beside `38;5;16`; `38;5;8` beside `90` | `38;5;0` equal to `30`: the fill text and histogram band text follow the scheme; equal to `38;5;16`: fixed black. The same test for the gridline `38;5;8` |
| 3 | Terminal.app and iTerm2, light and dark | `1;38;5;16`, `1;38;5;184`, `1;38;5;34` | colour unchanged and heavier: bold over index 16-255 is weight only, as measured in Windows Terminal |
| 4 | Windows Terminal Campbell (dark) and One Half Light; Terminal.app and iTerm2, light and dark | `ltl --help` heading (`1` ... `22`), the `Error:` line, notice focus `1;37`, dark `pick` `1;97`, explain message title `36` then `1` | whether help bold reads heavier, lighter or the same against plain text on each scheme; settles the help-text case `docs/terminal-output.md` defers to this issue |
| 5 | Terminal.app and iTerm2, light and dark | `2` on the default fg, `2;38;5;184`, `2;37` | pixel toward the background: opacity-style dim; toward black: darkening as in Windows Terminal; equal: no faint |
| 6 | iTerm2, light preset | `38;5;226` and `33` on the light background, Minimum Contrast at its shipped value | the shipped Minimum Contrast value, and whether a 256-colour yellow is shifted |
| 7 | Windows Terminal One Half Light, as installed (record the version) | `38;5;226`, `38;5;184` and `33` on the light background | read the effective `adjustIndistinguishableColors` value in the settings UI or JSON; `38;5;226` shifted: `always`; only `33` shifted: `indexed`; neither: `never`, or `automatic` outside high contrast |
| 8 | Terminal.app on macOS 26, light and dark | the light notice dimmed layer (`38;2;R;G;B`) and an `ltl -hm` heatmap | 24-bit pixel equal to the RGB written: true colour; and whether the dimmed layer's xterm-default assumption for the sixteen matches the profile's colours |
| 9 | Terminal.app and iTerm2, with tmux at its default configuration inside | `38;5;184`, `38;2;215;215;0`, `1;33` | pixel equal to outside tmux: passed through; changed: tmux reduces or drops it without the RGB/256 settings [tmux-faq] |
| 10 | Windows Terminal One Half Light; Terminal.app "Clear Light" | an `ltl` timeline row with `93` value text, `32`, `36`, `34`, `35`, `31` and the legend `0;33` | contrast of each basic foreground on a light scheme against its `@column_colors` 256-colour shade; supplies the "basic foregrounds across schemes" reading `docs/terminal-output.md` marks not yet measured |
