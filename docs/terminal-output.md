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
sequences, the one form every target terminal reads. On Windows, VT
processing is on before the first sequence is written. `ltl` gets it from its
startup `system("chcp 65001 > nul")`, and every other program does it the
same way, so there is one mechanism to reason about; `SetConsoleMode` with
`ENABLE_VIRTUAL_TERMINAL_PROCESSING` (0x0004) is the explicit form, should it
ever be needed (`features/412-notice-surfaces-research.md` § 4.2).

**Measured.**

| terminal | VT processing |
|---|---|
| Windows Terminal | on without asking: bold, dim, underline, reverse, 16-colour and 256-colour SGR all render |
| classic console host | off for a program that never starts a subprocess (console mode 0x0003): every sequence printed as text, `[93myellow` |
| classic console host, after the program has run `cmd.exe` | on (console mode 0x0007): `cmd.exe` sets the flag and leaves it set |

`ltl` renders its colours in a classic console window (seen: the run of
`ltl -n 3 -hg` on an access log fixture, every colour in place). It never calls
`SetConsoleMode`; its startup `system("chcp 65001 > nul")` runs `cmd.exe`,
which turns VT processing on as a side effect. `SetConsoleMode` gives the
same state explicitly.

**Detecting Windows Terminal.** `WT_SESSION` is not proof of it: a classic
console window started from a process inside Windows Terminal inherits the
variable (measured: set in a `conhost.exe` window opened from a shell running
in Windows Terminal). `TERM` is unset in both, and both accept the VT flag.
Nothing measured here tells the two apart, so a Windows choice holds in both.

---

## Colour and emphasis

**Rule.** A colour that has to hold its value is written as a 256-colour code
(`38;5;N`, `48;5;N`) or a 24-bit one (`38;2;R;G;B`), never as one of the
sixteen basic colours (`30` to `37`, `90` to `97`, and their backgrounds): the
basic colours are the terminal scheme's to repaint, and Windows Terminal
changes them again under bold. Bold is applied only over a 256-colour or
24-bit foreground. Faint (SGR 2) is used only where the background is known
to be dark; on a light background secondary text is an explicit grey
(`38;5;244`, D10 of `features/412-notice-surfaces.md`). A layer dimmed under
a pop-up keeps its colours: faint over them on a dark background, each
blended half way to white on a light one.

**Measured** in Windows Terminal on its "One Half Light" scheme (foreground
#383A42), the darkest pixel of a run of text:

| sequence | darkest pixel | weight |
|---|---|---|
| none, or `30` | 56,58,66 | normal |
| bold `1`, or `1;30` | 79,82,93: lighter | normal |
| faint `2` | 28,29,33: darker | normal |
| `38;5;16` | 0,0,0 | normal |
| `1;38;5;16` | 0,0,0 | bold |
| `38;5;244` | 128,128,128 | normal |
| `38;5;184`, then with faint `2;38;5;184` | 215,215,0, then 107,107,0: darker | normal |

What the table shows:

- **The scheme repaints the basic colours.** `30`, "black", is the scheme's
  56,58,66; `38;5;16` is 0,0,0 whatever the scheme.
- **Bold on a basic colour, or on the default, becomes the bright variant in
  the normal weight:** lighter on a light scheme, and never heavier. Bold
  over a 256-colour code is drawn bold, in its colour.
- **Faint darkens the colour.** On a dark scheme that reads as dim; on a
  light one it pushes text towards black.

On a dark scheme the last two read as designed, which is why the macOS rounds
did not show them.

**Beyond the notice surfaces.** `ltl`'s `@column_colors` writes the
foreground of its first six colours (yellow, green, cyan, blue, magenta, red)
as basic codes (`93`, `32`, `36`, `34`, `35`, `31`), and `%colors` writes
basic codes throughout, while the other column colours and every background
are 256-colour codes. How those basic foregrounds render across schemes, and
under `bs_bold()` in help text, is not yet measured: an observation for
`ltl`, not yet an issue.

---

## Glyphs and width

**Rule.** Every glyph a surface draws occupies exactly one cell on every
target terminal. A glyph enters `docs/design-language.md` only after it has
been seen one cell wide in a terminal of each platform, and the table below
holds the result.

**Measured on Windows.** Every non-ASCII character in the source of the #412
prototypes and of `ltl` (outside comments), 74 in all, each printed between
`[` and `|]` plain and in bold colour, under code page 65001. Anything not
named below is one cell in its colour in every column.

| glyph | used by | Windows Terminal | classic console host |
|---|---|---|---|
| `⚠` U+26A0, `⚙` U+2699, `⏱` U+23F1 | the category sheet | colour emoji in its own colours, covering the next cell | monochrome, covering the next cell |
| `➤` U+27A4 | the category sheet | reaching into the next cell, over the space after it (seen by the architect in the panel) | one cell |
| `↻` U+21BB, `⛭` U+26ED | the category sheet | one cell, reaching its right edge | `⛭` one cell; `↻` varies |
| `►` U+25BA, `▸` U+25B8, `›` U+203A | candidates for guidance | one cell | one cell |
| `▹` U+25B9, `▻` U+25BB, `❯` U+276F, `▷` U+25B7, `⊳` U+22B3 | candidates for guidance | one cell | a missing-glyph box |
| `⇒` U+21D2, `⇨` U+21E8, `➜` U+279C, `➔` U+2794, `➢` U+27A2, `⮞` U+2B9E | candidates for guidance | reaching into the next cell | varies |
| `↳` U+21B3, `⎯` U+23AF, `▶` U+25B6, `⧖` U+29D6, `▁ ▂ ▃ ▅ ▆ ▇` | prototypes; the blocks also `ltl`'s histograms | one cell | varies |

"Varies": the same glyph was drawn in some classic console windows and shown
as a missing-glyph box (the placeholder rectangle a terminal draws when its
font has no shape for a character) in others. Which setting decides it is not
isolated: neither the code page nor VT processing alone explains every
window measured.

Replacements tried for the three emoji glyphs, printed in the category's
colour and bold:

| glyph | Windows Terminal | classic console |
|---|---|---|
| `▲` U+25B2, `△` U+25B3, `✱` U+2731, `≡` U+2261 | one cell | one cell |
| `◬` U+25EC, `⧋` U+29CB, `⚑` U+2691, `⊘` U+2298, `⌘` U+2318, `◷` U+25F7, `◴` U+25F4, `⧗` U+29D7, `◔` U+25D4 | one cell | a missing-glyph box |
| `⌥` U+2325 | covering the next cell | a missing-glyph box |

The text-presentation selector (U+FE0E after the glyph) does not help: Windows
Terminal still draws the emoji, and the classic console host gives the
selector a cell of its own. A program's width arithmetic counts these glyphs
as one cell, so the row stays aligned while the glyph overdraws the space
after it (seen in the notices panel in both terminals: `⚠DATA ANOMALY`).

**Choosing a glyph.** The three that overdraw in Windows Terminal are the
three of the category sheet with Unicode's `Emoji` property; none of the
glyphs drawn in one cell has it. A candidate therefore lacks `Emoji`
(`/\p{Emoji}/` in Perl) and is not East Asian `Wide`; that is necessary, not
sufficient (`⌥` lacks both and still overdraws), so the candidate is then seen
in each terminal, in the category's colour and in bold, as a heading draws it.
The emoji glyphs also ignore the colour codes in Windows Terminal: `⚙` is drawn
grey beside a cyan heading. The Windows column of the category sheet in
`docs/design-language.md` is the outcome.

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

**The terminal's answers.** **Rule.** On Windows a program that reads an
answer from the terminal, such as the cursor position report (CSI 6n), sets
`ENABLE_VIRTUAL_TERMINAL_INPUT` (0x0200) on its console input handle while it
reads keys. **Measured** in Windows Terminal through Term::ReadKey in cbreak
mode: without the flag the report reads as one byte, `00`; with it, the whole
answer, `1B 5B 32 3B 31 52` (ESC [ 2 ; 1 R). Without it the prototypes placed
the dimmed copy of the run under a modal on the bottom row, 3 to 4 rows below
the run in a window it did not fill. `ReadMode('restore')` puts the input
mode back.

**Keys.** In Windows Terminal, with and without that flag, Term::ReadKey
delivers the arrow keys, Tab, Shift-Tab, Esc, Enter, digits and letters as
the prototypes' key reader expects (`read_key()` in
`prototype/412-notice-surfaces/lib/NoticeProto.pm`), every view of the
Windows round driven by script (`prototype/412-notice-surfaces/findings.md`
§ Keys, a first pass by script).

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
