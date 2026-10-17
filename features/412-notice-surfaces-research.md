# Notice surfaces: research for the prototypes (#412)

Starting point for the agents building the notice-surface prototypes of #412
(notice surfaces: terminal interfaces that present notices to the analyst and
may capture a choice). The framing it serves is
`features/412-notice-surfaces.md`. This is research, not a decision record:
it states what was found and where. Where a survey recommended something, it
is written as "the survey's candidate", with its reason; nothing here is
decided.

Gathered 2026-10-17 from three passes: a reading of `ltl` and its tooling on
`release/0.20.0`; a web survey of terminal surface kinds and prompt practice;
a survey of Perl terminal libraries (MetaCPAN metadata and POD, distribution
sources, CPAN Testers summaries, the Strawberry Perl build configuration,
Microsoft console documentation). No library was installed or run; nothing
here is a measurement. Statements the passes could not confirm are left out,
except where section 6 lists them as points to verify.

Library source key (each claim in section 4 carries one):

| key | URL |
|---|---|
| `[meta:<Dist>]` | `https://fastapi.metacpan.org/v1/release/<Dist>` (version, date, licence, dependencies) |
| `[pod:<Module>]` | `https://metacpan.org/pod/<Module>` |
| `[ct:<Dist>]` | `https://api.cpantesters.org/v3/summary/<Dist>` (counts across all versions) |
| `[SP]` | Strawberry Perl 5.42.3.1 build config, https://github.com/StrawberryPerl/Perl-Dist-Strawberry/blob/master/share/64bit-5.42.3.1.pp |
| `[MS-mode]` | https://learn.microsoft.com/en-us/windows/console/setconsolemode |
| `[MS-vt]` | https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences |
| `[pp]` | https://metacpan.org/pod/pp |

---

## 1. What `ltl` has today that the surfaces build on or must fit

Read from the repository files named; code is referenced by sub.

### 1.1 Modules and packaging

- Loaded at compile time, among others: **`Term::ReadKey`** (`GetTerminalSize`,
  `ReadMode`, `ReadKey`) and **`Term::ANSIColor`**. Both are already in
  `build/cpanfile` and `build/cpanfile.windows`, so both are in every shipped
  binary.
- Loaded at run time: `PerlIO::via` in `start_row_counting()` (only under
  `-V section-layout`); `Win32::API` in `get_memory_usage()`, only on
  `MSWin32`, inside `eval` (kernel32 `GetCurrentProcess`,
  `K32GetProcessMemoryInfo`). This is the only Win32 module in the program.
- Absent: `Win32::Console`, `Win32::Console::ANSI`, `IO::Pty`, `IO::Select`,
  `Curses`, `Term::ReadLine`, `Term::Cap`, `Term::Screen`.
- `build/generate-cpanfile.sh` scans `ltl` for `use`/`require Module` lines
  (indented `require` included) and writes both cpanfiles. A module a
  prototype adopts enters both on regeneration; a Windows-only module is added
  to `WINDOWS_ONLY_MODULES`, a Unix-only one to `UNIX_ONLY_MODULES` (empty
  today).
- PAR::Packer is called with no `-M`, `-l`, `-x` or `-a` flag on any platform
  (`build/macos-package.sh`, `build/ubuntu-package.sh` in Docker,
  `build/windows-package.sh` under Wine with Strawberry Perl portable x64,
  `cpanm --notest`, verified with `--version` and `build/verify-read-path.sh`).
  Bundling rests on Module::ScanDeps' static scan. Windows ARM64 is not built.

### 1.2 Terminal size

- Read once, at global scope: `GetTerminalSize()` inside `eval` with STDERR
  sent to the null device; on failure `(120, 24)` and
  `$terminal_height_detected = 0`. `COLUMNS`/`LINES` are not read. No
  `$SIG{WINCH}` handler exists.
- Hidden `--terminal-width|-tw` and `--terminal-height|-th` set the size; the
  height goes through `set_terminal_height()`, which marks the height as
  detected so derived defaults follow it when output is redirected.
  `adapt_to_terminal_settings()` falls back to 80x24 and derives the bucket
  size from the height.

### 1.3 TTY checks

Only three `-t` tests exist:

| sub | test | used for |
|---|---|---|
| `help_ansi_enabled()` | `FORCE_COLOR` (non-empty, not `0`) on; `NO_COLOR` off; else `-t STDOUT` | bold and underline in `--help` / `--explain` only |
| `pipe_to_pager()` | `! -t STDOUT` prints directly | pager |
| `detect_light_terminal_background()` | `-t STDIN && -t STDOUT` | OSC 11 query |

The main report and the progress line are not gated on any TTY test: SGR
codes and progress `\r` frames go to STDOUT whether or not it is a terminal
(`tests/validate-progress-line.sh` captures progress from a redirected stdout).

### 1.4 Light background detection: the timed raw-read precedent

`detect_light_terminal_background()`, called from
`adapt_to_command_line_options()` only when neither `-lbg` nor `-dbg` settled
it and the heatmap is on; skipped on Windows. It saves `stty -g`, sets
`stty -icanon -echo min 0 time 1`, prints `\e]11;?\a`, polls STDIN with
`select()` in 10 ms steps up to 100 ms, `sysread`s byte by byte to BEL or ST,
restores the tty, and reads BT.709 luma above 0.5 as light. It uses shell
`stty`, not `ReadMode`, and is Unix only.

### 1.5 Single-key input: `pause_for_keypress()`

The only keyboard input point (`-p, --pause`, "Wait for a keypress between
pages of output" in `docs/usage.md`). It prints a blue `\033[0;44m` prompt to
STDOUT, `ReadMode 4`, blocking `ReadKey(0)`, `ReadMode 0`; `q`/`Q` exits 0
with "Exiting program."; any other key erases the prompt with `\r` + spaces +
`\r`. Called from the timeline row loop every `terminal_height - 1` rows.
There is no TTY check. `run_with_output_discarded()` turns pause off for
hidden sections; the screenshot tool refuses `-p`. `ltl` reads no file data
from STDIN.

### 1.6 Escape sequences emitted today

- SGR colour throughout; SGR 1/22/4/24 in help; a non-standard `109` in the
  title (ignored by terminals and by the screenshot renderer).
- `\r` for every progress frame and phase line.
- Line clearing by spaces, never `\e[K`: `"\r" . " " x ($terminal_width - 1) . "\r"`.
- `\e]11;?\a` in background detection.
- None of: cursor movement, save/restore, erase (`\e[K`, `\e[J`), cursor
  visibility, alternate screen, scroll region.
- `strip_ansi()` removes SGR and backspace-overstrike pairs.

### 1.7 The progress line and its stream

- **Stream: STDOUT**, `$| = 1`. Notices go to STDERR.
- `progress_line_text()` builds a frame fitted to `terminal_width - 1`
  (filename shortened, rate dropped before the name); `paint_progress_line()`
  writes `"\r$text"` padded with spaces to that width, so the row carries no
  residue. One frame at the start of each file, then at most one repaint per
  500 ms (`PROGRESS_REPAINT_SECONDS`), the clock checked every 512 lines
  (`PROGRESS_LINE_STRIDE`) in the read loop, and in the generated read loop
  body through the `#@and !$disable_progress` gate marker.
- On each file's close `read_and_process_logs()` blanks the row; then
  `Processing completed.` in bright green and `\n`. Post-read phases
  ("Calculating ...", "Consolidating ...", "Scaling ...", "Initializing ...")
  each rewrite their own line with `\r` and a "... completed." replacement.
- The rate shown comes from a trailing window of the last 50 samples
  (`@progress_history`).
- Suppression: `--disable-progress` pushes `hide progress`;
  `$disable_progress = section_hidden('progress')`; main calls
  `open_section('progress') unless $disable_progress`, so progress rows are a
  section in `-V section-layout`.
- Mid-read notices are queued by `defer_notice()` and printed to STDERR by
  `flush_deferred_notices()` after the read ends. The collision of a mid-read
  notice with the progress row was a real defect; the
  `notice-not-in-progress-row` scenario of `tests/validate-progress-line.sh`
  asserts it no longer happens. A prompt during the read would be the first
  deliberate exception (the framing: erase the progress row, show the message
  and input point, resume cleanly).
- `progress-row-check.py residue` / `width` replay raw stdout through a
  terminal model; usable to check an erase-prompt-resume sequence.
- `docs/progress-indication-best-practices.md` and
  `features/446-overall-progress-indicator.md` record the one-line,
  space-padded, unconditionally completed progress line; neither covers
  interrupting it for input.

### 1.8 Windows console state

- At startup `system("chcp 65001 > nul")`; nothing else. No `SetConsoleMode`,
  no `ENABLE_VIRTUAL_TERMINAL_PROCESSING`, no Win32::Console::ANSI.
- `$default_chart_block` is U+25A0 instead of the full block;
  `pipe_to_pager()` uses `more` and strips ANSI;
  `detect_light_terminal_background()` returns 0.
- `docs/explain/heatmap.md` and `histogram.md` say legacy CMD with `more`
  shows monochrome; `features/windows-character-rendering.md` records conhost
  versus Windows Terminal (`$ENV{WT_SESSION}`) for block glyphs.
- No Windows-specific progress code; the same `\r` path runs everywhere.

### 1.9 `@output_sections` and `-V section-layout`

- `@output_sections`, print order: `title progress timeline histogram options
  messages messages-highlighted messages-overall threadpools
  threadpools-highlighted threadpools-overall summary summary-values
  summary-files`; aliases in `%section_aliases`. `open_section()` prints
  exactly one blank row between rendered sections; `open_part()` /
  `close_part()` for stacked parts; `record_side_part()` for side-by-side
  columns. A section added to `@output_sections` gets `--hide`/`--show`
  through `section_hidden()`.
- `print_section_layout()` prints `=== section-layout ===`, a tab-separated
  header `name state start rows`, one row per section (`rendered`, `hidden`,
  `absent`), and `=== END section-layout ===`. Rows are counted by the
  `LTL::RowCounter` PerlIO layer on STDOUT (`start_row_counting()`): `\n`
  only, excluding every `=== name === ... === END name ===` range so positions
  match a run without `-V`.
- Consequences read from that: only STDOUT rows are counted, so notices on
  STDERR are invisible to the layout; a `\r`-rewritten line counts as one row.

### 1.10 The screenshot tool (`process/capture-screenshots.pl`, spec `features/598-screenshot-capture.md`)

- Runs `ltl` twice under `$^X`: a probe with `-V section-layout`, then the
  capture; both with `--terminal-width W --terminal-height H` (default
  211x53), `-dbg` or `-lbg`, `--disable-progress`. Deletes `LTL_CONFIG`,
  `FORCE_COLOR`, `NO_COLOR` from the environment. Probe and capture must print
  the same number of rows.
- `run_redirected()` sends STDOUT and STDERR to files. **Only STDOUT is
  drawn.** STDERR fails the run only on a Perl warning (` at <file> line <N>`);
  a non-zero exit fails too.
- Refused `ltl` options: `-tw`, `-th`, `-lbg`, `-dbg`, `-V`, `-p` ("it waits
  for a key").
- **Accepted characters.** The grid parser,
  `/\G(?:\e\[([0-9;]*)m|(\e[^\n]{0,8})|(\n)|([\x00-\x1f\x7f])|(.))/`, accepts
  SGR only (16 colours, 90-97 and 100-107, 38/48;5 and ;2, bold, underline,
  reverse, resets; unknown SGR such as 109 ignored). **Any other escape
  sequence is a hard error**, and **any C0 control other than `\n`, including
  `\r`, `\t` and BEL, is a hard error.** Rows longer than the width are
  clipped.
- Crops are sections plus offsets from `-V section-layout`, so a notice
  section must be reported there to be croppable; anything printed between
  sections is part of a crop unless hidden with `--hide`. The options row
  echoes the command line, so an answers-ahead option would appear in it.
  Sections that may carry file names or message text get a review notice.
- Rendering: SVG text per cell, 12 px, cells 7.2x15, Terminal.app "Clear
  Dark"/"Clear Light" colours; PNG via a Swift WebKit helper
  (`process/capture-png.swift`), macOS only. The tool runs on macOS and Linux,
  not Windows.

### 1.11 Harness exposure

- `tests/HARNESS-DESIGN.md`: every harness captures stderr and fails on
  ` at .+ line [0-9]+` (`tests/lib/runtime-warnings.sh`); discarding stderr is
  prohibited. Moving a message between streams obliges re-pointing every
  assertion that greps for it, in the same change. Harnesses call
  `neutralize_colour_env` (`tests/lib/colour-env.sh`).
- `tests/validate-regression.sh` diffs **stdout only** against 74 files in
  `tests/reference-output/`; none contains `Note:` or `Warning:`.
- 52 `tests/validate-*.sh` harnesses; 19 contain `Note:` or `Warning:` text
  (93 lines): byte-units, classification-percentages, csv-input,
  filter-summary, format-detection, help-content, heatmap-palette,
  message-grouping-notices, option-resolution, message-discard,
  numeric-criteria-notices, progress-line, recursive-file-selection,
  runtime-config, read-path, statistics-demand, udm-counting,
  timestamp-precision, udm-specs. 48 capture stderr; 16 grep for
  `Note`/`Warning`/`notice` directly.
- `ltl` has 67 `print STDERR`/`printf STDERR` and 8 `warn` sites, about 30
  `"Note:` and 24 `Warning:` literals, plus the `defer_notice()` queue.
- The framing records that the designed surface is on stdout and that a `-V`
  section will expose the deferred notices to the harnesses.

---

## 2. Catalogue of surface kinds

Sequences referenced below, all from the xterm control sequences reference
https://invisible-island.net/xterm/ctlseqs/ctlseqs.html and terminfo(5)
https://man7.org/linux/man-pages/man5/terminfo.5.html:

| mechanism | sequence |
|---|---|
| Erase in line | `CSI Ps K` (0 to right, 1 to left, 2 whole line) |
| Save / restore cursor | `ESC 7` / `ESC 8`; terminfo `sc` / `rc` |
| Scroll region | `CSI top ; bottom r` (DECSTBM); terminfo `csr` |
| Alternate screen | `CSI ? 1049 h` saves the cursor and switches to a cleared alternate buffer; `CSI ? 1049 l` restores; older `?47`, `?1047`; "may be disabled by the titeInhibit resource"; terminfo `smcup`/`rmcup` |
| Hide cursor | `CSI ? 25 l` |
| Cursor position report | `CSI 6 n` answered `CSI r ; c R` |
| Text area size report | `CSI 18 t` answered `CSI 8 ; h ; w t` |
| Background query | `OSC 11 ; ? BEL`, answered on stdin or never, so read with a short timeout; `COLORFGBG` a weaker fallback. https://rubydoc.info/gems/tuile/Tuile/TerminalBackground ; https://github.com/dalance/termbg ; https://docs.rs/terminal-light/ |

All of these are also documented for the Windows console once virtual
terminal processing is on [MS-vt]; Microsoft describes alternate buffer and
scroll margins as added in the Windows 10 Anniversary Update [MS-vt].

### 2.1 Summary

| kind | suited to | mechanism | scrollback after | with a progress line | tested unattended by |
|---|---|---|---|---|---|
| Plain prefixed line(s) | deprecation, advice, caveat, next step | text, optional SGR, prefix word | stays as written | clear the row, print, redraw beneath | grep the capture; prefix as anchor |
| Boxed block | caveat on figures, decisions taken | box glyphs, SGR, width-aware wrap | stays as written | as above | grep content lines; pin the width; or emulator rows |
| Transient status line | progress, countdown | CR + EL in place | final frame stays unless cleared | is the progress line | off when not a TTY; or an emulator collapses frames |
| Pinned status row | progress kept at the bottom while notices scroll above | DECSTBM + save/restore + move to last row | see section 6 | progress lives on the pinned row | Term::VT102 or pyte on the raw capture; tmux |
| Inline y/N prompt, timed default | one decision mid-run | prompt line, cbreak read with timeout, redrawn countdown | final prompt line, ideally rewritten to the answer taken | suspend progress, prompt, redraw | pty + keystrokes; answers given ahead; exit code |
| Inline selector below the cursor | one of several, multi-stage | reserved rows below the cursor, redrawn | see section 6 | progress stops | pty + keys + emulator snapshot; golden files |
| Modal dialog | blocking decision with explanation | full-screen drawing, box and buttons, alternate screen optional | painted screen remains unless alternate screen | progress stops | exit codes; preseeding; tmux capture-pane |
| Full-screen list / pager | browsing many notices with detail | alternate screen, raw keys, redraw | nothing (screen restored) unless alternate screen inhibited | progress stops | tmux `capture-pane -a -e -p`; VHS `.txt`; not Term::VT102 |
| Spinner around a step | waiting on one step | CR + EL animation | final frame unless cleared | is a progress line | text fallback, off when not a TTY |

### 2.2 Plain prefixed line(s)

- git's `advise()` prints each line on stderr with a `hint:` prefix,
  optionally coloured, and by default says how to silence it; each hint is
  gated by an `advice.<name>` key and `GIT_ADVICE=0` silences all for tools
  running git. https://git-scm.com/docs/git-config ;
  https://code.googlesource.com/git/+/refs/tags/v2.30.0/advice.c
- Homebrew prints caveats under `==> Caveats`
  (https://docs.brew.sh/Formula-Cookbook) and environment hints suppressible
  with `HOMEBREW_NO_ENV_HINTS` (https://docs.brew.sh/Manpage).
- Terraform's `TF_IN_AUTOMATION` makes it "avoid suggesting specific commands
  to run next".
  https://developer.hashicorp.com/terraform/cli/config/environment-variables
- clig.dev: suggest next commands, put "the most important information at the
  end of the output", no level labels (`ERR`, `WARN`) outside verbose mode.
  https://clig.dev/
- With a progress line: clear it, print, redraw beneath, as indicatif's
  `println` ("Print a log line above the progress bar") and `suspend` ("Hide
  the progress bar temporarily, execute f, then redraw").
  https://docs.rs/indicatif/latest/indicatif/struct.ProgressBar.html
- Narrow: wraps naturally. No colour: the meaning must survive in the prefix
  word (git's `hint:` is a word).

### 2.3 Boxed block

- lipgloss: border styles (rounded and others), per-side toggles, `Wrap`
  preserving ANSI styles across lines, `MaxWidth`/`MaxHeight`; downsamples
  colour to the available profile and strips ANSI "entirely when output is not
  a TTY"; light/dark colours via `HasDarkBackground` and `LightDark`.
  https://github.com/charmbracelet/lipgloss ; `gum style`
  https://github.com/charmbracelet/gum
- Narrow: wrap inside the box or degrade to unboxed lines. ASCII fallbacks:
  dialog `--ascii-lines` draws `+`/`-`
  (https://invisible-island.net/dialog/manpage/dialog.html); cargo's
  `term.unicode` forbids non-ASCII
  (https://doc.rust-lang.org/cargo/reference/config.html).
- Tests must pin the width, since the box follows it.

### 2.4 Transient status line

- cargo `term.progress.when` auto/always/never and `term.progress.width`
  (https://doc.rust-lang.org/cargo/reference/config.html); indicatif draws to
  stderr at most 20 refreshes per second, `finish_and_clear` "completely
  clears it" (https://docs.rs/indicatif/latest/indicatif/struct.ProgressBar.html);
  rich Live `transient=True` makes it "disappear on exit"
  (https://rich.readthedocs.io/en/stable/live.html); gh `GH_SPINNER_DISABLED`
  replaces animation with text (https://cli.github.com/manual/gh_help_environment);
  apt `-q` gives "output suitable for logging, omitting progress indicators"
  (https://manpages.debian.org/bookworm/apt/apt-get.8.en.html).
- clig.dev: no animations when stdout is not a TTY. https://clig.dev/
- A raw capture holds every frame separated by CR; an emulator collapses them
  to the final screen.

### 2.5 Pinned status row (scroll region)

- APT's dpkg progress bar, as read from `install-progress.cc`: print a
  newline, save cursor, set the scroll region to all rows but the last (which
  homes the cursor), restore cursor, move up one. Drawing: save, move to the
  last row, write, restore. Cleanup: reset the region to full screen, clear the
  last row, restore the cursor. Resize is not covered.
  https://mdk.fr/blog/how-apt-does-its-fancy-progress-bar.html
- The pinned row keeps its last content unless cleared on exit. Every exit
  path, signals included, must reset the region. A short height leaves little
  scroll area.
- Term::VT102 and pyte both implement DECSTBM, save/restore and EL (section 5).

### 2.6 Inline prompt, single line

- Capital letter marks the default (`[Y/n]` default yes, `[y/N]` default no);
  answers matched case-insensitively (apt's locale regex `^[+1yY]`).
  https://til.hashrocket.com/posts/5eae55bc9d-capitalized-letter-is-the-default ;
  https://codesynthesis.com/pipermail/odb-users/2023-May/004858.html
- Scrollback keeps the final prompt line and anything echoed; gum's
  `--show-output` prints the prompt and the action taken.
  https://github.com/charmbracelet/gum
- With a progress line: suspend, prompt, redraw (indicatif `suspend`, above).
- dialog's `--pause` shows a meter of seconds remaining.
  https://invisible-island.net/dialog/manpage/dialog.html
- The visible countdown designed by the architect is in section 3.2.

### 2.7 Inline selector below the cursor

- fzf `--height HEIGHT[%]` "will start below the cursor with the given
  height"; `~` for a maximum height, negative for relative to the screen;
  `--popup` in tmux 3.3+ / Zellij.
  https://github.com/junegunn/fzf/blob/master/README.md
- gum `choose`, `filter`. https://github.com/charmbracelet/gum
- Bubble Tea's default inline mode; `Println`/`Printf` output "will persist
  across renders" above the program. Its test package teatest runs a model
  with `WithInitialTermSize`, `Send`, `WaitFor`, `FinalOutput`, and golden
  files updated with `-update`.
  https://pkg.go.dev/github.com/charmbracelet/bubbletea ;
  https://pkg.go.dev/github.com/charmbracelet/x/exp/teatest
- Term::Choose renders inline below the current output by default, capped by
  `max_height` (section 4).

### 2.8 Modal dialog

- dialog / whiptail: `--yesno`, `--msgbox`, `--infobox` (exits at once,
  message left on screen), `--menu`, `--checklist`, `--gauge`; `--defaultno`;
  `--timeout` (normally injects ESC; with `DIALOG_TIMEOUT` set, exits, e.g.
  status 5); exit 0 Yes/OK, 1 No/Cancel, 255 ESC. Output on stderr by default
  because curses draws on stdout; `--stdout` "attempts to reopen the
  terminal"; `--keep-tite` uses the alternate-screen strings in xterm;
  `--ascii-lines`, `--no-lines`, `--no-shadow`.
  https://invisible-island.net/dialog/manpage/dialog.html ;
  https://linux.die.net/man/1/dialog
- debconf's `dialog` frontend uses whiptail/dialog; its `readline` frontend
  gives plain prompts.
  https://manpages.debian.org/bookworm/debconf-doc/debconf.7.en.html
- lazygit confirmation popups (`confirmOnQuit`, per-warning `skip...Warning`)
  https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md ; k9s
  delete confirmation "(TAB and ENTER to confirm)" https://k9scli.io/topics/commands/
- Scrollback: without the alternate screen the painted screen remains; with
  it nothing remains (tmux: on the alternate screen "the history is not
  accessible", https://man7.org/linux/man-pages/man1/tmux.1.html).

### 2.9 Full-screen navigable list / pager

- less: `-X` disables the init/deinit strings, `-F` quits if one screen, `-R`
  passes colour, `-S` chops, `--header`
  (https://man7.org/linux/man-pages/man1/less.1.html); clig.dev recommends
  `less -FIRX` and a pager only when stdin or stdout is a TTY
  (https://clig.dev/).
- htop: header meters, F-key bar, F3 search, F4 filter, `-C/--no-color`.
  https://man7.org/linux/man-pages/man1/htop.1.html
- k9s: `:` command, `/` regex filter, `<esc>` to leave.
  https://k9scli.io/topics/commands/
- lazygit: light/dark theme with `colorScheme: auto` asking the terminal;
  borders rounded/single/double/hidden; portrait layout when width is at most
  84 and height at least 46.
  https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
- Bubble Tea `WithAltScreen`; `Println` output is not printed on the
  alternate screen. https://pkg.go.dev/github.com/charmbracelet/bubbletea ;
  rich Live `screen=True` https://rich.readthedocs.io/en/stable/live.html
- Scrollback: nothing, the original screen is restored, unless the alternate
  screen is inhibited (xterm `titeInhibit`, less `-X`), when the last screen
  stays.

### 2.10 Spinner

gum `spin` "Display a spinner while running a script or command"; gh can
replace spinners with text. Same mechanism as 2.4.
https://github.com/charmbracelet/gum ; https://cli.github.com/manual/gh_help_environment

### 2.11 Width, height, colour and background across kinds

- Width: Term::ReadKey `GetTerminalSize` (Windows needs an output handle,
  [pod:Term::ReadKey]); `CSI 18 t`; gh `GH_FORCE_TTY` forces terminal output
  when redirected, a number sets the width
  (https://cli.github.com/manual/gh_help_environment).
- Short heights: lazygit switches layout on size thresholds; fzf takes a
  height relative to the screen (sources above).
- Colour gates: `NO_COLOR` non-empty "prevents the addition of ANSI color",
  config and flags "should override" it (https://no-color.org/); clig.dev
  disables colour when the stream is not a TTY, `NO_COLOR` is set,
  `TERM=dumb` or `--no-color`, with `FORCE_COLOR` overriding
  (https://clig.dev/); `CLICOLOR=0`, `CLICOLOR_FORCE` (gh); Homebrew
  `HOMEBREW_NO_COLOR` defaults to `$NO_COLOR`, `HOMEBREW_COLOR` forces
  (https://docs.brew.sh/Manpage); cargo `term.color`, env over config, flags
  over env (https://doc.rust-lang.org/cargo/reference/config.html); git
  `color.* = auto` colours only a terminal (https://git-scm.com/docs/git-config).
- Accessibility: gh `GH_ACCESSIBLE_PROMPTER` for screen readers,
  `GH_ACCESSIBLE_COLORS` 4-bit palette.
  https://cli.github.com/manual/gh_help_environment
- Light background: OSC 11 with a timeout, `COLORFGBG` fallback, lipgloss
  `HasDarkBackground`, lazygit `lightTheme`. The OSC 11 reply arrives on
  stdin, so it is read before any other stdin consumer.
  https://rubydoc.info/gems/tuile/Tuile/TerminalBackground

---

## 3. Input: prompt practice

### 3.1 What tools do

| practice | evidence |
|---|---|
| Prompt only when stdin is a TTY; offer `--no-input` | clig.dev https://clig.dev/ ; Perl `-t FH` is true when the handle "is opened to a tty", bare `-t` tests STDIN https://perldoc.perl.org/perlfunc#-X |
| Switch to disable prompts | gh `GH_PROMPT_DISABLED`, `gh config set prompt disabled` https://cli.github.com/manual/gh_help_environment , https://cli.github.com/manual/gh_config ; Terraform `TF_INPUT=0` equals `-input=false` https://developer.hashicorp.com/terraform/cli/config/environment-variables |
| Assume yes / assume no | apt-get `-y/--yes/--assume-yes` ("run non-interactively", still aborts on held, unauthenticated or essential cases), `--assume-no`, `APT::Get::Assume-Yes`, `-qq` implies `-y` https://manpages.debian.org/bookworm/apt/apt-get.8.en.html ; npx `--yes`/`--no` https://docs.npmjs.com/cli/v10/commands/npx |
| Dangerous action: typed confirmation, or `--confirm=<name>` to stay scriptable | https://clig.dev/ |
| Non-interactive frontend takes the defaults | debconf `DEBIAN_FRONTEND=noninteractive` "makes the default answers be used for all questions" https://manpages.debian.org/bookworm/debconf-doc/debconf.7.en.html |
| Answers given ahead of time | debconf preseeding (`DEBCONF_DB_FALLBACK`, `DEBCONF_DB_OVERRIDE`, `dpkg-preconfigure`), `DEBIAN_PRIORITY` filters which questions are asked (same source); rustup-init takes answers as arguments via `sh -s -- ...` https://rust-lang.github.io/rustup/installation/other.html |
| Answers on redirected stdin | bash `read` reads whatever stdin is; its `-p` prompt shows only when input is a terminal https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html |
| Default visible in the prompt | `[Y/n]` / `[y/N]` (section 2.6); dialog `--defaultno`, `--default-item` https://linux.die.net/man/1/dialog ; gum `--default` |
| Timeout falls to the default | gum confirm `--timeout` "until confirm returns selected value or default if provided" https://raw.githubusercontent.com/charmbracelet/gum/main/confirm/options.go ; dialog `--timeout` (ESC or exit 5); bash `read -t`, fractional seconds, status above 128 on timeout, `-n` returns after N characters (bash manual above) |
| Reporting the answer taken | gum `--show-output` prints prompt and chosen action; gum exits 0 yes / 1 no; dialog encodes the answer in its exit code (0/1/255/5) |
| Silencing advice for machine readers | `GIT_ADVICE=0`, `TF_IN_AUTOMATION`, `HOMEBREW_NO_ENV_HINTS` (section 2.2) |

How `ltl` takes the analyst's input at a choice point, with a default and
answers given ahead of time, is #748 (taking the analyst's input at choice
points); the surfaces are designed with it in mind. The first concrete choice
point named in the framing is #44 (source file heuristics: a pre-read
confirmation when the run's estimated memory exceeds 1 GB).

### 3.2 The visible countdown (the architect's design, not a finding)

A timed default shows a visible countdown: the question is printed with its
yes/no block, followed in brackets by the seconds remaining until the default
is taken. The line is redrawn every second while a single-character
`Term::ReadKey` read accepts Y or N.

What the passes found that bears on building it:

- `ReadMode 3` (cbreak) or `4` (raw) with `ReadKey($t)`, `$t > 0` a timed
  read in fractional seconds, `-1` non-blocking, `0` blocking
  [pod:Term::ReadKey]. A one-second `ReadKey(1)` per redraw is one loop shape.
- On Windows the timed read is `WaitForSingleObject(whnd, delay * 1000)` then
  `PeekConsoleInput`/`ReadConsoleInput` (`Win32PeekChar` in
  https://metacpan.org/release/JSTOWE/TermReadKey-2.38/source/ReadKey.xs), so
  it does not rely on `select()`, which on Windows is "only implemented on
  sockets" (https://perldoc.perl.org/perlport#select).
- Open Win32 bug: `ReadKey` tests its argument for truth, not definedness
  (https://github.com/jonathanstowe/TermReadKey/issues/41).
- `ltl`'s precedent is `pause_for_keypress()` (section 1.5): blocking, no TTY
  check, prompt erased with spaces.

---

## 4. Perl libraries

Surfaces: **S1** decorated inline blocks; **S2** yes/no with timed default,
including one raised over the progress line; **S3** single key; **S4** modal;
**S5** navigable list with detail.

### 4.1 What Strawberry Perl (the Windows build base) ships [SP]

| module / library | shipped? |
|---|---|
| Term::ReadKey | yes (`ignore_testfailure`) |
| Win32::Console | yes |
| Win32::API | yes (`ignore_testfailure`) |
| Term::ReadLine::Perl | yes |
| Win32::Console::ANSI | **no**: commented out, "fails tests under UCRT 5.39.10 - but patched now" |
| any curses library | **no** (readline 8.2 and termcap 1.3.1 are bundled) |

### 4.2 Candidates

**Term::ReadKey** (dist TermReadKey). `ReadMode`, `ReadKey`, `GetTerminalSize`;
S2 and S3 directly, S1/S4/S5 need escape sequences on top. Since 2.30.01 on
Win32 the arrows, page up/down, home/end, insert/delete "emit
xterm-compatible sequences", so one key decoder serves all platforms
[pod:Term::ReadKey]. Documented Windows limits: `ReadLine` with a timeout "is
currently not available under Windows"; mode 5 equals mode 4; non-blocking
reads "may fail when reading repeating keys from more then one console";
`GetTerminalSize` "must be called with an output filehandle, such as STDOUT"
[pod:Term::ReadKey]. Open Win32 bugs: height off by one
(https://github.com/jonathanstowe/TermReadKey/issues/32), truthiness of the
timeout argument (issue 41 above). XS, no native library. 2.38, 2019-01-05
[meta:TermReadKey]; repo last pushed 2022-11-30, 7 open issues including "Is
this project still active?" (https://github.com/jonathanstowe/TermReadKey/issues/42).
Licence: unlimited distribution with the notice kept, or Artistic
(https://metacpan.org/release/JSTOWE/TermReadKey-2.38/source/README); a
licence-clarity issue is open (https://github.com/jonathanstowe/TermReadKey/issues/36).
Already in every `ltl` binary.

**IO::Select** (core). `can_read($timeout)` on STDIN gives a timed wait on
Unix with a raw tty mode [pod:IO::Select]. Unusable for console input on
Windows (perlport, above). Relevant only for waiting on STDIN and another
handle at once on Unix.

**Term::ReadLine family.** Core stub 1.14 (2013) [meta:Term-ReadLine];
Term::ReadLine::Gnu 1.47 (2025-07-06), XS over GNU readline
[meta:Term-ReadLine-Gnu], MSWin32 10 pass / 64 fail [ct:Term-ReadLine-Gnu],
needs `libreadline` bundled with `pp -l`; Term::ReadLine::Perl 1.0303 (2009)
[meta:Term-ReadLine-Perl]; Term::ReadLine::Perl5 1.45 (2017)
[meta:Term-ReadLine-Perl5]. Line editing with history; a timed yes/no is one
key, not a line. The survey set the family aside.

**Curses** 1.46 (2026-02-27) [meta:Curses], XS over the system curses
library [pod:Curses]. Full-screen model. Windows: INSTALL says PDCurses
"almost works", with four manual header edits and "`perl demo` fails"
(https://metacpan.org/release/GIRAFFED/Curses-1.46/source/INSTALL); MSWin32
2 pass / 27 fail / 337 unknown [ct:Curses]; no curses library in Strawberry.
GPL v1+ or Artistic (https://metacpan.org/release/GIRAFFED/Curses-1.46/source/README).
PAR::Packer packs the XS part but not the shared library; `-l ncurses` adds
it [pp]. **Curses::UI** 0.9609 (2011-09-02) [meta:Curses-UI], widgets on
Curses, requires Curses and Term::ReadKey; MSWin32 10 pass / 3 fail [ct:Curses-UI].

**Tickit** 0.77 (2026-06-01) [meta:Tickit]: full-screen toolkit with
attributes, mouse, modified keys via libtermkey [pod:Tickit], scroll box
widget [pod:Tickit::Widget::ScrollBox]. Needs libtickit via pkg-config or
`Alien::libtickit` 0.16 (2026-02-12)
(https://metacpan.org/release/PEVANS/Tickit-0.77/source/Build.PL,
[meta:Alien-libtickit]). CPAN Testers: no MSWin32 pass (71 na, 22 unknown),
no darwin pass (11 fail, 217 na, 490 unknown), Linux 4414 pass [ct:Tickit].
**Term::TermKey** 0.19 (2025-03-01) [meta:Term-TermKey]: its POD says
libtermkey "is deprecated ... uses of this module should also be considered
deprecated" [pod:Term::TermKey]; libtermkey's page: "Use of this library for
new programs is discouraged" (https://www.leonerd.org.uk/code/libtermkey/);
MSWin32 0 pass [ct:Term-TermKey]. Perl 5 licence [meta:Tickit].

**Term::Screen** 1.06 (2016-12-04) [meta:Term-Screen]: "A Simple all perl
Term::Cap based screen positioning module", `at`, `clrscr`, `getch`,
`key_pressed`, "set up for Unix using stty's" [pod:Term::Screen]. Pure Perl
on Term::Cap. MSWin32 50 pass / 21 fail [ct:Term-Screen].

**Term::ANSIScreen** 1.50 (2012-01-08) [meta:Term-ANSIScreen]: Term::ANSIColor
plus cursor (`locate`, `savepos`, `loadpos`, `up`/`down`) and screen (`cls`,
`clline`) helpers; on Win32 its OO `new` "simply returns a geniune
Win32::Console object" [pod:Term::ANSIScreen]. Pure Perl, CC0. MSWin32 183
pass / 1 fail [ct:Term-ANSIScreen]. Output only: strings `ltl` could emit
itself.

**Term::Cap** 1.18 (2023-02-10) [meta:Term-Cap], core: reads termcap from
`$TERMCAP`, `~/.termcap`, `/etc/termcap`, `/usr/share/misc/termcap`
[pod:Term::Cap], falling back to running `infocmp -C`
(https://metacpan.org/release/JSTOWE/Term-Cap-1.18/source/Cap.pm, `Tgetent`).
On the development Mac neither termcap file exists and `/usr/bin/infocmp`
does, so it would always shell out. No Windows meaning. **Term::Terminfo**
0.09 (2019) [meta:Term-Terminfo], XS over unibilium or ncurses
(https://metacpan.org/release/PEVANS/Term-Terminfo-0.09/source/Build.PL),
MSWin32 0 pass [ct:Term-Terminfo]. Term::Choose itself hardcodes ANSI on
MSWin32 and offers `TC_ANSI_ESCAPES` to do so elsewhere [pod:Term::Choose].

**Term::Choose** 1.782 (2026-04-09), Perl 5 licence, 1 open issue, repo pushed
2026-04-09 [meta:Term-Choose], https://github.com/kuerbis/Term-Choose.
`choose(\@items, \%opt)`: scalar context one choice, list context
multi-select, paging past the screen; options include `prompt`, `info`,
`footer`, `default`, `max_height`, `layout`, `search`, `mouse`,
`clear_screen` (off by default) [pod:Term::Choose]. Renders inline below the
output, capped by `max_height`. No documented timeout, so no timed default.
Per platform (https://metacpan.org/release/KUERBIS/Term-Choose-1.782/source/lib/Term/Choose.pm):
on MSWin32 it `require`s Win32::Console::ANSI and Term::Choose::Win32, which
reads through `Win32::Console->Input` and uses
Win32::Console::PatchForRT33513; elsewhere Term::Choose::Linux uses
`Term::ReadKey` `ReadKey`/`ReadMode`, falling back to `stty` only without it.
Escape strings come from `qx(tput ...)` unless MSWin32 or `TC_ANSI_ESCAPES`
(`.../lib/Term/Choose/Screen.pm`). Pure Perl; `Term::Choose::LineFold::XS`
is added by `Makefile.PL` only if already installed and listed as optional
(https://metacpan.org/release/KUERBIS/Term-Choose-1.782/source/Makefile.PL,
[pod:Term::Choose]). On MSWin32 `Makefile.PL` adds Encode, Encode::Locale,
Win32::Console, Win32::Console::ANSI, Win32::Console::PatchForRT33513;
Win32::Console::ANSI requires Win32::Pipe and Win32::Process
[meta:Win32-Console-ANSI]. Term::Choose::Win32 is a module inside the
Term-Choose distribution (https://fastapi.metacpan.org/v1/module/Term::Choose::Win32).
`pp -M Term::Choose::**` or `-x` forces inclusion [pp].
**Term::Form** 0.563 (2026-04-10) [meta:Term-Form], form fields on
Term::Choose, MSWin32 681 pass [ct:Term-Form]. **Term::TablePrint** 0.182
(2026-05-22) [meta:Term-TablePrint]: scrollable table, select a row to see its
detail; requires Perl 5.16 and declares `Term::Choose::LineFold::XS` as a
runtime requirement [meta:Term-TablePrint]. The closest ready-made match to
"list, select, see detail".

**Win32::Console** 0.10 (2013-11-28), Perl 5 licence [meta:Win32-Console],
in Strawberry [SP]: `Mode`, `Input` (key-down, repeat count, virtual key,
char), `InputChar`, `PeekInput`, `GetEvents`, `FlushInput`, `Cursor`, `Size`,
`Window`, `ReadRect`/`WriteRect` [pod:Win32::Console]. `Mode($flags)` passes
the integer to `SetConsoleMode`
(https://metacpan.org/release/JDB/Win32-Console-0.10/source/Console.pm,
`sub Mode`; `_SetConsoleMode` in `.../source/Console.xs`), so
`ENABLE_VIRTUAL_TERMINAL_PROCESSING` (0x0004) can be passed as a number.
`ReadRect`/`WriteRect` can save and restore the region under a modal.

**Win32::Console::ANSI** 1.11 (2017-10-24) [meta:Win32-Console-ANSI]:
emulates ANSI sequences on consoles without them (written for "Windows
NT/2000/XP"), converts code page to OEM [pod:Win32::Console::ANSI]. Not in
Strawberry [SP]; MSWin32 74 fail / 322 pass [ct:Win32-Console-ANSI].

**Library-free route: VT sequences plus Term::ReadKey.** CR + `ESC[2K` to
clear the progress row, prompt, read, erase, resume; `ESC 7`/`ESC 8`;
`ESC[<n>A/B`; `ESC[?25l/h`; `ESC[t;br`; `ESC[?1049h/l`. All documented for
the Windows console [MS-vt]. On Windows VT output is parsed only "if the
ENABLE_VIRTUAL_TERMINAL_PROCESSING flag is set on the screen buffer handle"
(0x0004, with `ENABLE_PROCESSED_OUTPUT` set); Microsoft's pattern is get the
mode, OR the flag in, set it, and treat `ERROR_INVALID_PARAMETER` as a
down-level system [MS-mode], [MS-vt]. From Perl: `Win32::Console->new(STD_OUTPUT_HANDLE)`
then `$c->Mode($c->Mode | 0x0004)`, or Win32::API calling kernel32
`GetStdHandle`/`GetConsoleMode`/`SetConsoleMode` (already loaded by
`get_memory_usage()`). Input on Windows: `ReadMode 4` + `ReadKey($t)`, or
Win32::Console `Input`; `ENABLE_VIRTUAL_TERMINAL_INPUT` (0x0200) makes arrows
arrive as `ESC [ A` [MS-mode], [MS-vt]. No new dependency; `ltl` owns the
drawing, paging, key decoding, resize and tty restore on die or Ctrl-C.

**Others.**

| module | found | survey's note |
|---|---|---|
| IO::Prompter 0.005004 (2025-09-05) [meta:IO-Prompter] | `-single`, `-timeout=>N` returns `-default`, `-menu`; POD: "Several features of this module are known to have problems under Windows"; depends on Contextual::Return, match::smart [pod:IO::Prompter] | shows the shape of a timed-default API; the Windows caveat |
| Term::UI 0.50 (2021) [meta:Term-UI] | over Term::ReadLine; in Strawberry [SP] | |
| Term::Menus 3.041 (2024) [meta:Term-Menus] | menu selection; **AGPL-3** | licence |
| Term::Clui 1.76 (2019) [meta:Term-Clui] | pure Perl | older, smaller community than Term::Choose |
| Prima 1.78 (2026) [meta:Prima] | GUI toolkit | not a terminal library |

### 4.3 Comparison

Y provided, P partial or built on top, N no.

| candidate | S1 | S2 timed | S3 key | S4 modal | S5 list | macOS | Linux | Windows | pure Perl / XS | native lib | last release | licence | PAR::Packer / Wine-Strawberry risk |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| VT sequences + Term::ReadKey | Y | Y | Y | P (own code) | P (own code) | Y | Y | Y (VT on Win10+) | XS (ReadKey) | none | 2019 | Artistic or unlimited | lowest: already shipped |
| Term::ReadKey alone | N | Y | Y | N | N | Y | Y | Y | XS | none | 2019-01-05 | Artistic or unlimited | lowest |
| IO::Select | N | P (Unix) | P (Unix) | N | N | Y | Y | N (sockets only) | core | none | core | Perl | none |
| Term::Choose (+TablePrint, Form) | N | N (no timeout) | P | N | Y | Y | Y | Y via Win32::Console[::ANSI] | pure Perl (XS optional) | none | 2026-04/05 | Perl 5 | moderate: Win32::Console::ANSI not in Strawberry |
| Win32::Console | P | P | Y | P (ReadRect/WriteRect) | N | N | N | Y | XS | none | 2013-11-28 | Perl 5 | low: in Strawberry |
| Win32::Console::ANSI | P | N | N | N | N | N | N | legacy consoles | XS | none | 2017-10-24 | Perl 5 | moderate: UCRT test failures |
| Term::ANSIScreen | Y | N | N | P | N | Y | Y | Y | pure Perl | none | 2012-01-08 | CC0 | low |
| Term::Screen | P | P | Y | P | N | Y | Y | 50 pass / 21 fail | pure Perl | termcap db | 2016-12-04 | Perl 5 | low |
| Term::Cap / Term::Terminfo | P | N | N | N | N | Y | Y | N | pure / XS | infocmp / unibilium or ncurses | 2023 / 2019 | Perl 5 | none / high |
| Term::ReadLine::* | N | N | N | N | N | Y | Y | Gnu poor | mixed | libreadline (Gnu) | 2025 (Gnu) | Perl 5 | moderate |
| Curses | P | Y | Y | Y | Y | Y | Y | 2 pass / 27 fail | XS | ncurses / PDCurses | 2026-02-27 | GPL or Artistic | highest |
| Curses::UI | N | P | Y | Y | Y | Y | Y | as Curses | pure Perl on Curses | as Curses | 2011-09-02 | Perl 5 | highest |
| Tickit / Term::TermKey | N | P | Y | Y | Y | no passes | Y | N | XS | libtickit / libtermkey (deprecated) | 2026-06 / 2025-03 | Perl 5 | excluded by the survey |

### 4.4 The survey's candidates for the first macOS prototypes

- **VT sequences + Term::ReadKey, no new dependency**, for S1, S2 (including
  erase-progress-prompt-resume), S3 and a first S4. Reason: Term::ReadKey is
  in every binary; its timed read works on Windows through console input
  records; the same sequences are documented for the Windows console once VT
  processing is on, and enabling it needs only Win32::Console or Win32::API,
  both in Strawberry. The survey uses it as the baseline others are measured
  against.
- **Term::Choose, with Term::TablePrint for list then detail**, for S5, in a
  separate prototype compared against a hand-written list on the same data.
  Reason: maintained (2026 releases), pure Perl, inline with `max_height`,
  paging, search; same author covers forms and tables; good MSWin32 record
  for Term::Form. Set `TC_ANSI_ESCAPES` to avoid `tput` subprocesses. Not an
  S2 vehicle (no timeout).
- Set aside by the survey for the first round: Curses and Curses::UI
  (full-screen model against inline output, PDCurses build on Windows), Tickit
  and Term::TermKey (no Windows, deprecated key library), IO::Prompter
  (Windows caveat), Term::Menus (AGPL).
- Portability risk as the survey ranked it: Curses / Curses::UI; then Tickit,
  Term::TermKey, Term::Terminfo; then Term::Choose on Windows
  (Win32::Console::ANSI, whose runtime correctness shows only on real Windows,
  not under the `--notest` Wine build); the VT route's risk is behavioural
  (down-level consoles, legacy-console mode) and needs a plain-text fallback
  when `SetConsoleMode` refuses the flag, plus Term::ReadKey's two open Win32
  bugs.

---

## 5. Testing and capturing surfaces unattended

The three unattended readers are the harnesses, Claude during development and
the screenshot tool. A raw redirect of a surface using CR, EL or DECSTBM
carries every frame and control sequence, so a reader either gets a surface
that does not engage when the stream is not a TTY (clig.dev's rule) and prints
plain lines, or replays the bytes through an emulator to get the final screen.

| tool | what it gives | limits | source |
|---|---|---|---|
| Term::VT102 (Perl) | "emulation of most of the functions of a DEC VT102", default 80x24; `process($string)`; `row_plaintext`, `row_text`, `row_attr` + `attr_unpack` (fg, bg, bold, underline, reverse); cursor `x()`/`y()`; `OUTPUT` callback to answer host queries; DECSC/DECRC, `CSI s/u`, ED, EL, SGR, DSR, DA, DECSTBM | ignores charset sequences; of private modes only `CSI ? 25`; no documented alternate screen, so a full-screen surface overwrites its one screen | https://metacpan.org/pod/Term::VT102 |
| pyte (Python) | "an in memory VTXXX-compatible terminal emulator"; `Screen(80,24)`, `Stream(screen).feed(...)`, `screen.display`; `set_margins`, save/restore cursor, private modes; `screen.buffer` of `Char(data, fg, bg, bold, italics, underscore, strikethrough, reverse, blink)`; `HistoryScreen` keeps scrollback | | https://pyte.readthedocs.io/en/latest/tutorial.html ; https://github.com/selectel/pyte/blob/master/pyte/screens.py ; https://pyte.readthedocs.io/en/latest/ |
| tmux | `new-session -d -x W -y H`, `send-keys`, `capture-pane -p` (stdout), `-e` (attributes as escapes), `-J` (join wrapped lines), `-S/-E` (negative is history), `-a` (alternate screen) | a real terminal, alternate screen included; on it history is not accessible | https://man7.org/linux/man-pages/man1/tmux.1.html |
| Expect.pm | `spawn` on a pty, `expect` with timeout and patterns, `send`, `raw_pty(1)` (no echo, no CR translation), `slave->clone_winsize_from`, `log_file` | | https://metacpan.org/pod/Expect |
| pexpect | pty child, `expect(..., timeout=)`, `sendline` | output has `\r\n` endings | https://pexpect.readthedocs.io/en/stable/overview.html |
| asciicast v2 | header with width, height, env; events `[time, code, data]`: `o` output, `i` input, `m` marker, `r` resize `COLSxROWS`; the `o` stream replays into an emulator at any marker | | https://docs.asciinema.org/manual/asciicast/v2/ |
| VHS | `.tape` scripts (`Set Width/Height/FontSize/Theme`, `Type`, `Enter`, `Sleep`, `Screenshot`); GIF/MP4/WebM/PNG, and `.txt`/`.ascii` "to generate golden files" | | https://github.com/charmbracelet/vhs |
| freeze | PNG/SVG/WebP of terminal output; `--execute` captures a command's ANSI output | | https://github.com/charmbracelet/freeze |
| termtosvg | SVG animations or stills | archived June 2020 | https://github.com/nbedos/termtosvg |
| teatest | model driven with size, keys, `WaitFor`, `FinalOutput`, golden files | Go, Bubble Tea only | https://pkg.go.dev/github.com/charmbracelet/x/exp/teatest |

Already in the repository: `progress-row-check.py residue` / `width` replay
raw stdout through a terminal model (section 1.7).

### What the screenshot tool would need to learn

From section 1.10, set against the surfaces in section 2:

- **Characters.** Today any non-SGR escape and any C0 other than `\n`
  (including `\r`) stops the tool. A surface that uses CR, EL, cursor
  movement, a scroll region or the alternate screen either prints plain SGR
  rows in the captured run, or the grid parser becomes an emulator pass
  (Term::VT102 is in-language and covers all but the alternate screen) that
  draws the final screen, as freeze and VHS effectively do. Either is a change
  to the tool's specification in `features/598-screenshot-capture.md`.
- **Input.** `-p` is refused because it waits for a key; a choice point needs
  the same treatment, or an answers-ahead option passed by the tool, which
  then appears in the captured options row.
- **Moment.** A surface shown mid-read or as a modal is not a section in
  `-V section-layout`; to be croppable it needs a section (or another
  position report) the probe and capture runs agree on, with the same row
  count in both.
- **Streams.** Only stdout is drawn; a surface on stderr cannot be
  screenshotted.
- **Environment.** The tool deletes `FORCE_COLOR` and `NO_COLOR`; a surface
  that gates on a TTY behaves as non-interactive in the capture.

---

## 6. Open points to verify during prototyping

1. Whether `ReadKey(0)` in `pause_for_keypress()` reads a byte from a redirected STDIN or returns undef at EOF.
2. Whether `run_redirected()` in the screenshot tool leaves STDIN inherited, so a prompt would read the developer's terminal.
3. Whether a pause for a timed choice during the read depresses the rate shown from `@progress_history`.
4. Whether Module::ScanDeps finds a module loaded by computed name or string `eval`, and Term::Choose's `$^O`-branched `require`s, without `-M`.
5. Whether colour already works in Windows Terminal, and in conhost without a `SetConsoleMode` call, on the Windows versions targeted.
6. Whether Windows Terminal has VT processing on by default, and whether Win32::Console::ANSI interferes with native VT handling.
7. Whether Term::ReadKey's timed read behaves the same in Windows Terminal as in conhost.
8. Whether `GetTerminalSize()` without a filehandle, as `ltl` calls it, works on Windows (the POD requires an output handle).
9. Whether a line longer than the width smears on CR redraw, as is widely observed; and how the countdown line behaves at narrow widths.
10. Whether lines scrolled above a DECSTBM pinned row reach scrollback in each target terminal, and how the region recovers on resize (SIGWINCH).
11. The exact sequences an inline selector uses (fzf, gum, Term::Choose) and what it leaves in scrollback.
12. How dialog-style modals behave when the terminal is too small.
13. Whether full-screen tools redraw on SIGWINCH; `ltl` reads its size once.
14. Which SGR colours read poorly on a light background (bright yellow is the commonly named casualty).
15. Whether Curses wraps `halfdelay`/`timeout`, and inline use via `newterm`/`filter()`; the run-time terminfo path of a bundled ncurses.
16. Whether Term::Screen's console input works on Windows.
17. Whether `Term::Choose::LineFold::XS` is a hard or optional requirement of Term::TablePrint.
18. Term::UI's and Term::Clui's actual feature sets (timeout, line or key based).
19. Whether a one-line "assuming yes" echo of an answer given ahead of time is established practice, and rustup's `-y`.
20. How npx behaves when stdin is not a TTY.
21. Whether a modal that clears itself, or a cursor-up redraw, leaves `-V section-layout` row counts differing from the screen.
22. How glyphs and emoji render across the target terminals and the screenshot tool's font list.
