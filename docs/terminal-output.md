# Terminal output

What every program of this repository that writes to a terminal does on each
platform, so that what was designed on one terminal reads the same on the
others: the encoding, the escape sequences, the glyphs and their width, the
commands a script may call, and how output is checked on a platform the
harnesses do not run on. It applies to `ltl` and to every script under
`prototype/`, `process/` and `tests/` whose output a person reads in a
terminal. `docs/design-language.md` (how a surface looks) and
`docs/terminal-interaction.md` (how a surface behaves) build on it. This is a
developer document and is not part of the wiki.

**Status.** Written 2026-10-20 from the Windows validation round of #412
(notice surfaces: presenting notices and capturing the analyst's choices), on
Windows 11 with Windows Terminal and the classic console host, Strawberry
Perl. Each Windows fact below says how it was measured. Linux is not yet
validated; macOS is the platform every surface was designed on.

---

## The terminals

| platform | terminal | role |
|---|---|---|
| macOS | Terminal, iTerm2 | where surfaces are designed and reviewed |
| Linux | a VT terminal emulator | validated per surface; harnesses run here |
| Windows | Windows Terminal | the Windows target: validated per surface |
| Windows | the classic console host (`conhost.exe`), what a console program opens in when Windows Terminal is not the default | must stay readable; not a design target |

The harnesses run on macOS and Linux only (`docs/toolchain-guidance.md`
§ Windows development host).

---

## Encoding

**Rule.** Output is UTF-8 on every platform. On Windows a program that writes
anything outside ASCII sets the console's output code page to UTF-8 (65001)
before its first byte of output, as `ltl` does at startup
(`system("chcp 65001 > nul")`, above `## GLOBALS ##`). A program whose
terminal code lives in a shared module sets it when the module loads, so no
entry point can forget it. Marking the handle UTF-8 (`binmode STDOUT,
':encoding(UTF-8)'`) is needed as well; it does not change the console's
code page.

**Measured.** A new Windows Terminal tab starts on code page 437 (`chcp` in a
fresh window). The prototypes of #412 marked their output UTF-8 and did not
set the code page: every non-ASCII character came out as the bytes of its
UTF-8 form read under 437 (`│` as `Γöé`, `·` as `┬╖`, `─` as `ΓöÇ`), each one
taking two or three cells, so a framed panel's rule wrapped onto three rows.
Under 65001 the same panel rendered as on macOS.

**The change outlives the program.** The code page belongs to the console, not
to the process: set from Perl, it stays 65001 in the shell after the program
exits (measured: `chcp 437`, a Perl `system('chcp 65001 > nul')`, then `chcp`
in the parent reports 65001). `ltl` leaves it so today.

**An agent's shell hides the fault.** The shell Claude Code runs commands in
was already on 65001, so output that is garbled for an analyst in a fresh
window reads correctly there. A check of Windows output is made in a fresh
window (§ Checking output on Windows).

---

## Escape sequences

**Rule.** Colour, emphasis and cursor control are written as VT escape
sequences, the one form every target terminal reads. On Windows a program
that writes them enables virtual terminal processing on its output handle
first (`SetConsoleMode` with `ENABLE_VIRTUAL_TERMINAL_PROCESSING`, 0x0004),
and writes no escape sequence when the console refuses the flag
(`features/412-notice-surfaces-research.md` § 4.2 gives the call from Perl
through Win32::Console or Win32::API).

**Measured.**

| terminal | without `SetConsoleMode` |
|---|---|
| Windows Terminal | bold, dim, underline, reverse, 16-colour and 256-colour SGR all render |
| classic console host | every sequence printed as text: `[1mbold [0m`, `[93myellow` |

`ltl` does not call `SetConsoleMode` today (research § 1.8), so its colours
reach a classic console window as text. That is an observation for `ltl`, not
yet an issue.

**Detecting Windows Terminal.** `WT_SESSION` is not proof of it: a classic
console window started from a process inside Windows Terminal inherits the
variable (measured: set in a `conhost.exe` window opened from a shell running
in Windows Terminal). `TERM` is unset in both. The reliable test is whether
`SetConsoleMode` accepts the flag.

---

## Glyphs and width

**Rule.** Every glyph a surface draws occupies exactly one cell on every
target terminal. A glyph enters `docs/design-language.md` only after it has
been seen one cell wide in a terminal of each platform, and the table below
holds the result.

**Measured on Windows** (each glyph printed between `[` and `|]`, under code
page 65001):

| glyph | in | Windows Terminal | classic console host |
|---|---|---|---|
| `⚠` U+26A0, `⚙` U+2699, `⏱` U+23F1 | the category sheet | drawn as colour emoji two cells wide, covering the next cell | monochrome, still covering the next cell |
| `≈` U+2248, `➤` U+27A4 | the category sheet | one cell | one cell |
| `↻` U+21BB | the category sheet | one cell | one cell in plain text; a missing-glyph box in the panel's bold, coloured heading |
| `╶` U+2576, `·` U+00B7, `→ ← ↑ ↓` | the notice bullet, key bars, remedies | one cell | one cell |
| `╭ ╮ ╰ ╯ ─ │`, `┌ ┬ ┐ ━ ┃ ┏`, `▁ … █`, `■ ▪ •` | frames, axes, bars | one cell, joined | one cell, joined |
| `▲` U+25B2, `△` U+25B3, `✱` U+2731, `≡` U+2261 | candidates for the category sheet | one cell | one cell |
| `◬` U+25EC, `⧋` U+29CB, `⚑` U+2691, `⊘` U+2298, `⌘` U+2318, `◷` U+25F7, `◴` U+25F4, `⧖` U+29D6, `⧗` U+29D7, `◔` U+25D4 | candidates | one cell | a missing-glyph box, one cell |
| `⛭` U+26ED, `⌥` U+2325 | candidates | covering the next cell | `⛭` one cell; `⌥` a missing-glyph box |

The text-presentation selector (U+FE0E after the glyph) does not help: Windows
Terminal still draws the emoji, and the classic console host gives the
selector a cell of its own. A program's width arithmetic counts these glyphs
as one cell, so the row stays aligned while the glyph overdraws the space
after it (seen in the notices panel in both terminals: `⚠DATA ANOMALY`).

**Choosing a glyph.** The three that overdraw in Windows Terminal are the
three of the category sheet with Unicode's `Emoji` property; none of the
glyphs drawn in one cell has it. A candidate therefore lacks `Emoji`
(`/\p{Emoji}/` in Perl) and is not East Asian `Wide`; that is necessary, not
sufficient (`⛭` and `⌥` lack both and still overdraw), so the candidate is then
seen in each terminal.

Bar characters differ by platform for another reason: `ltl` draws bars with
`■` on Windows (research § 1.8; `features/windows-character-rendering.md`).

---

## Commands and devices

**Rule.** No program calls a Unix-only command or device to manage the
terminal: no `stty`, `tput`, `infocmp`, `/dev/tty`. Terminal modes go through
Term::ReadKey (`ReadMode`, `ReadKey`, `GetTerminalSize`), which works on
Windows through the console API and ships in every binary.

**Measured.** The review runner of #412 called `system('stty', 'sane')` after
each view; on Windows it printed `'stty' is not recognized as an internal or
external command` into the review.

---

## Input

**Line endings.** A line read from the console arrives with CR LF on Windows.
Perl's default `:crlf` layer stays under `:encoding(UTF-8)`, so `chomp`
leaves the bare text (measured: `q` CR LF read through `binmode STDIN,
':encoding(UTF-8)'` gives `q`). A program does not push `:raw` on standard
input.

**Keys.** Raw key reading, the arrow keys, Shift-Tab and the cursor position
report (CSI 6n) on Windows are not yet validated.

---

## Checking output on Windows

- Run the program in a **new** Windows Terminal window started from the Start
  menu or `wt.exe`, never in a shell that has already run `chcp 65001`, so the
  code page is the one an analyst starts with.
- Look again in a classic console window (`conhost.exe cmd`) for anything that
  writes escape sequences.
- A program checked by script is started in its own window
  (`wt.exe -w new --title <name> cmd /k <command>`) and the screen captured;
  keystrokes are never typed into a window a person is using.

---

## Owning records

- `features/412-notice-surfaces.md` § Prototyping: the platform validation of
  the selected components; `prototype/412-notice-surfaces/findings.md`
  § Windows validation round: what was seen.
- `features/412-notice-surfaces-research.md` § 1.8 (`ltl`'s Windows console
  state) and § 4.2 (enabling VT processing from Perl).
- `features/windows-character-rendering.md`: block glyphs in the classic
  console host against Windows Terminal.
- `docs/toolchain-guidance.md` § Windows development host: why the harnesses
  do not run on Windows.
