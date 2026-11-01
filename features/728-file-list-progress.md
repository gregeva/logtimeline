# Feature: Progress indication while the file list is built (#728)

## What it is for

A user who points `ltl` at the wrong place (`-r` run from the wrong directory,
or a glob over a folder holding tens of thousands of files) sees the title and
then a blank screen until the list of files to read is built. Nothing says the
tool is working or what it is doing. The indicator shows the listing under way,
so the user can see the mistake and stop the run.

## GitHub Issue

#728 — Enhancement: Show a progress indicator while the file list is built.
Reframed by the architect on 2026-11-01 from the `-r` sweep alone to every
file-list build.

## Status

Planning, started 2026-11-01 on `release/0.20.0`. The surfaces and their
contracts are confirmed by the architect; D1 to D11 are locked and the
acceptance criteria agreed.

## Requirements (architect, 2026-11-01)

- **R1.** While the file list is built, with or without `-r`, a status line
  states "Building file list..." beside a moving spinner.
- **R2.** `-r` makes the case more dangerous but is not its only cause: tens of
  thousands of files matching a glob in one folder leave the screen as blank as
  hundreds of nested folders do.
- **R3.** The spinner is catalogued in `docs/architecture-patterns.md`.

## Locked decisions

**D1 — Every file-list build, with or without `-r`** (architect, 2026-11-01):
"this should actually exist for all file listing aspects with or without -r,
even if that option makes this more dangerous. The point is that there is no
progress indication while the file listing is taken and files are added to the
array."

**D2 — The spinner is the six-dot braille cycle, with the text "Building file
list..."** (architect, 2026-11-01). Frames, in order:
`⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏`, drawn as `⠹ Building file list...`. Chosen over the
8-dot cycle with one gap (`⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷`) and the six-frame dot-to-star
cycle (`· ✢ ✳ ✶ ✻ ✽`). `ltl` has no spinner today
(`features/446-overall-progress-indicator.md` § In-drop obligations: the
toolchain guidance "describes progress output as including an ETA and a
spinner; neither exists"), so this is a new mechanism.

**D3 — A plain pattern's folder is read one entry at a time, as `-r` reads
each folder** (architect, 2026-11-01). Chosen over keeping `bsd_glob`, which
reads the folder in one call and would leave the spinner still for most of the
wait (F2). The filename part is matched by the `-r` matcher
(`basename_matches_glob()`), and the names are put in `bsd_glob`'s order, case
ignored, so the order files are read in does not change. What a plain pattern
selects, and in what order, stays as shipped; it is proven by comparing
selections before and after on the same fixtures. This amends 420 D3 (without
`-r`, behaviour exactly as shipped and the plain path not refactored through
the `-r` expansion) for the plain path's matching. Cost: F4.

**D4 — The line shows the files found so far, the folders read so far, and the
folder being read, last** (architect, 2026-11-01):

```
⠹ Building file list... 12,408 files, 3,210 folders: logs/archive/2026-08
```

The folder path is the quickest sign of a wrong directory, and the counts show
the scale. The path goes last and is shortened in the middle, as the
"Processing" line renders its path (446 D5, 532 D1). Chosen over the spinner
and text alone, and over the counts without the path.

**D5 — The whole line, spinner included, repaints at the "Processing" line's
pace: at most every 500 ms** (architect, 2026-11-01). One pace for every
progress display in `ltl` (446 D4, `PROGRESS_REPAINT_SECONDS`;
`docs/progress-indication-best-practices.md` item 5), so the spinner steps
twice a second. Chosen over stepping the spinner every 100 ms, with or without
the numbers. The spinner moves only between file entries: a single folder read
that blocks, on a slow network drive for example, holds it still until the read
returns.

**D6 — The line first appears once the listing has taken 500 ms**
(architect, 2026-11-01). A listing that finishes inside that time shows
nothing, so a normal run looks and captures exactly as it does today. This
adopts the startup delay `docs/progress-indication-best-practices.md` item 9
records as available (git hides its bar for the first second). First locked at
1 second, then lowered to 500 ms by the architect to make the line easier to
test (D10); the first frame and the repaint pace (D5) are then the same
interval. Chosen over drawing the line as soon as the listing starts.

**D7 — When the list is built, the line is erased and leaves nothing behind**
(architect, 2026-11-01). The row is blanked in place and the next output takes
it, so a slow listing leaves the screen as a quick one does and adds no row
before the progress section, as the `-p` pause prompt does
(`features/597-section-visibility.md` § Finding: the pause option adds no
rows). The file count is already reported by the "Processing" line
(`file i/N`) and the Processed files table. Chosen over a lasting
"Building file list completed: ..." row.

**D8 — The listing takes each file's metadata from its own file check; the
separate size pass goes** (architect's proposal, locked 2026-11-01). As the
listing adds a file, the `-f` check that admits it also yields its size
(`-s _`, no second file-system call; F5), which replaces
`size_selected_files_for_progress()`. While the run index is on (`-idx`), the
same check also yields the modification time the index needs; while it is off,
it is not taken. The later steps that read this metadata again, the stat in
`read_index_file()` and the read loop's stat for the index record
(`my @file_stat = stat($in_file);`), take it from the listing instead. The run
index stays supported until it is removed. Amends 446 D2, whose rejection of
sizing during the walk existed only because `bsd_glob` was a separate step
(architect: "446 D2 did that because of the bsd_glob is its separate process;
that's all"). With no separate pass left after the listing, the line covers the
listing alone.

**D9 — The braille spinner is used on every platform, Windows included, and is
checked on the Windows development host in both consoles before the work is
accepted** (architect, 2026-11-01). The classic console (conhost, behind cmd
and PowerShell 5) uses Consolas by default and does not borrow missing glyphs
from other fonts, so it may draw boxes; Windows Terminal is told apart by
`$ENV{WT_SESSION}` (`features/windows-character-rendering.md` § Detection
Methods). A console that draws boxes is brought back to the architect with
screenshots, with braille in Windows Terminal and `| / - \` in the classic
console as the candidate. Chosen over `| / - \` on all of Windows, and over
splitting by console up front.

**D10 — No automated test for this work: it is validated on a synthetically
generated folder structure** (architect, 2026-11-01): "There is no automated
test for this. You validate on a synthenically generated folder structure
only." No harness scenario and no hidden option are added. The existing
harnesses that already read the paths this work changes run at the completion
gate as they always do. Chosen over a hidden option that zeroes the delay and
the pace for a test, and over a tree of tens of thousands of folders built
during a test.

**D11 — The shared name matcher is made to agree with `bsd_glob`, and `-r`
changes where it disagreed** (architect, 2026-11-01). `basename_matches_glob()`
serves both paths (D3), so the four disagreements that lie in it (F6 rows 1 to
4) are closed for both: `^` is a literal inside a set and only `!` negates; an
escaped `]` belongs to a set; a reversed range such as `[z-a]` matches nothing
instead of stopping the run with a Perl error; and where File::Glob ignores
case (its default flags carry `GLOB_NOCASE`, as on Windows), the matcher
ignores it too. `-r` changes in exactly those four cases, towards the contract
420 N2 records for it ("Agreement with `bsd_glob` is the contract"). Chosen
over leaving the `-r` matcher as it is and giving the plain path a second,
exact copy of `bsd_glob`'s matching.

## Acceptance criteria (agreed with the architect, 2026-11-01)

Every criterion is validated during development on a synthetically generated
folder structure under the scratchpad (D10), with the code before the change
run beside it on the same structure where the criterion says "unchanged". The
structure carries what each criterion needs: a folder of tens of thousands of
files, a tree of thousands of nested folders (both large enough for the listing
to pass 500 ms), mixed-case names, hidden files, names that need escaping, and
an unreadable folder.

| # | Criterion | Paths it covers |
|---|---|---|
| 1 | A listing over 500 ms shows `⠋ Building file list... N files, M folders: <folder>`, the spinner stepping through D2's frames in order, repainted at most every 500 ms | plain pattern, `-r` |
| 2 | A listing under 500 ms prints nothing extra: standard output byte-identical to the code before, apart from the version string | plain pattern, `-r` |
| 3 | When the list is built the line is erased: replaying the raw output through a terminal leaves no character of it, and `-V section-layout` reports the same rows as the same run under `--disable-progress` | plain pattern, `-r`; a run that then raises an option notice |
| 4 | `--disable-progress` and `--hide progress` show no listing line, however long the listing | both spellings, plain pattern and `-r` |
| 5 | At a narrow width the folder is shortened in the middle by `shorten_filename()`, and the line never exceeds `terminal_width - 1` | `--terminal-width` 60 and 140 |
| 6 | A plain pattern selects the same files, in the same order, as `bsd_glob` did: `*`, `?`, `[...]`, `[!...]`, `{a,b}`, escapes, a literal name, mixed case, hidden files, a wildcard in the folder part, `~`; a bare directory and a pattern matching nothing still stop the run with the same error | `-V format-detection` `file:` lines, before against after |
| 7 | `-r` selects the same files in the same order, and still reports an unreadable folder once at the end, except in D11's four cases, where its selection now equals `bsd_glob`'s at the top level | `-V format-detection` `file:` lines and the end-of-run note, before against after; D11's four cases against `bsd_glob` |
| 8 | Sizes taken by the listing give the same figures as the size pass did: the "Processing" line's overall and per-file percentages | multi-file and single-file runs; an empty file |
| 9 | With `-idx`, the index read-back reaches the same freshness verdicts and the index records the same size and modification time; without `-idx`, no modification time is taken | `read_index_file()`, `write_index_file()`; `-V index-read-back`, before against after |
| 10 | The listing is no slower than before | the F1 and F4 fixtures, three runs each, before against after |
| 11 | The braille spinner displays in the classic Windows console and in Windows Terminal (D9) | by eye on the Windows development host, with screenshots |

## Surfaces and their contracts (confirmed by the architect, 2026-11-01)

| # | Surface | Contract | Record |
|---|---|---|---|
| 1 | File arguments | Each argument is expanded through `bsd_glob`, or `expand_recursive_pattern()` under `-r`, and only files are kept; an argument that selects no file stops the run. The indicator changes no file selected and no order; D3 changes how a plain pattern's folder is read, not what it selects. | 420 governing statement ("`-r` replaces one-level matching with all-depth matching ... Nothing else changes"), 420 D3 (without `-r`, behaviour exactly as shipped; amended by D3 here for how the folder is read), 614 D1 point 2 (file resolution), 639 D1 (ltl's own files are ordinary input; no exclusion step) |
| 2 | Progress line | One row rewritten in place, repainted at most every 500 ms, each frame padded to the full row width | 446 D4, D5, D8; 532 D1 |
| 3 | Spinner | None exists; D2 adds it | 446 § In-drop obligations |
| 4 | Suppression | `--disable-progress`, the same as `--hide progress`, is the only switch for a progress surface; behavioural notices always print | 446 D6, 597 D9 |
| 5 | Row accounting | A row drawn and erased in place adds no rows (the `-p` pause prompt does this) | `features/597-section-visibility.md` § Finding: the pause option adds no rows |
| 6 | Notices | Nothing prints into a row a progress display holds; option-phase notices are drawn after the listing returns | 412, the architect's framing; 420 D8 for unreadable directories |
| 7 | Progress reference | Every new progress display follows the survey, which records hiding the indicator for the first second as available and not yet adopted | `docs/progress-indication-best-practices.md` item 9 |
| 8 | Patterns catalogue | A new mechanism, or a new consumption site, gets an entry in the same commit | `docs/architecture-patterns.md`, introduction |

## The silent span today

Code audit of `release/0.20.0`. Everything between the title and the first
progress frame, in order:

```
adapt_to_command_line_options()
 ├─ print_title()                            title on screen
 ├─ apply_output_visibility(0)               $disable_progress settled; $terminal_width known
 ├─ per argument: bsd_glob(), or             plain: one call reads the folder
 │     expand_recursive_pattern() under -r   -r: opendir/readdir, one directory at a time
 ├─ grep { -f $_ }                           one stat per entry returned
 ├─ -r de-duplication; no-file and selected-nothing usage errors
 └─ size_selected_files_for_progress()       one stat per selected file (2+ files, progress on)
adapt_to_terminal_settings(); start_row_counting()
ask_about_option_notices()                   notices raised while reading options are drawn
open_section('progress')
pipeline_detect()                            registry build; run index read under -idx
pipeline_parse()                             first "Processing ..." frame (paint_progress_line())
```

Format detection samples each file inside the read loop, after its first
progress frame, so it is already covered by the progress line.

## Findings

**F1 — On a warm local disk the listing is quick; the cases that hurt are
slower storage and larger trees.** Scratch fixtures: one folder of 50,000 empty
files, and a tree of 8,421 folders holding 16,000 files. Three runs each,
median (range), macOS, local SSD, warm cache. A pattern that matches nothing
makes `ltl` stop right after the listing, so its run time is start-up plus
listing:

| Run | Seconds | Listing alone |
|---|---|---|
| `ltl` start-up, no files selected | 0.181 (0.179–0.214) | — |
| 50,000-file folder, plain glob, no match | 0.217 (0.208–0.228) | +0.04 |
| same folder, `-r`, no match | 0.378 (0.365–0.381) | +0.20 |
| 8,421 folders, `-r`, no match | 0.436 (0.435–0.443) | +0.26 |
| 50,000 matches: `bsd_glob` then `-f` check (the mechanism alone) | 0.188 (0.184–0.194) | |
| 50,000 selected files: the size sweep's `stat` | 0.104 (0.104–0.108) | |

Each figure is a per-entry cost times a count. A cold cache, a network share,
or an endpoint security tool inspecting each access raises the per-entry cost,
and a home directory or a volume root raises the count; neither is reproducible
on a fixture. The indicator therefore has to turn wherever per-entry work is
done, whatever its speed.

**F2 — A plain glob reads its folder in one call, and nothing can repaint
inside it.** In the 50,000-file folder, `bsd_glob` takes 0.118 s
(0.117–0.314) of the listing and the `-f` check after it 0.066 s
(0.064–0.066). A timer cannot repaint during the call: a `Time::HiRes::ualarm`
due 10 ms in ran its handler at 125 ms, when `bsd_glob` returned. Perl runs a
signal handler between operations, and the call is one operation.

**F3 — Observation: `bsd_glob` and the `-r` matcher order names differently.**
In a folder holding `a.888`, `B.888` and `C.888`, `bsd_glob` returns
`a, B, C` (case ignored) and the `sort` in `expand_recursive_pattern()` gives
`B, C, a` (character code). 420 D5 says "alphanumeric within each level"
without saying which. It bears on any design that moves the plain path onto the
`-r` matcher.

**F4 — Reading the folder one entry at a time costs no more than `bsd_glob`.**
D3's shape (`opendir`/`readdir`, the `-r` matcher sliced verbatim from `ltl`,
the case-ignoring sort, `-f` on the matches only) against today's
`grep { -f $_ } bsd_glob(...)`, on the 50,000-file folder, three runs each,
median (range):

| Pattern | Files selected | Today (s) | D3's shape (s) |
|---|---|---|---|
| `*.888` (all match) | 50,000 | 0.184 (0.181–0.187) | 0.152 (0.151–0.152) |
| `f4*.888` (one in five) | 10,000 | 0.052 (0.047–0.054) | 0.065 (0.064–0.066) |
| `*.zzz` (none) | 0 | 0.019 (0.019–0.020) | 0.042 (0.042–0.042) |

At most 0.023 s per 50,000 entries either way. On the mixed-case folder of F3,
the case-ignoring sort returns the same list as `bsd_glob`.

**F5 — The size can be read from the listing's own file check, at a tenth of
the separate sweep's cost.** The architect's proposal (2026-11-01): collect
each file's size as the listing adds it, instead of in
`size_selected_files_for_progress()` afterwards. The listing already checks
every entry with `-f`, and Perl's `-s _` reads the size from that same check
without asking the file system again. Over the 50,000 files of the flat folder,
three runs:

| Shape | Seconds |
|---|---|
| Today: `-f` check in the listing, then the separate sweep (`-f` and `-s` per file) | 0.066–0.067 + 0.114–0.115 = 0.180–0.182 |
| Size taken from the listing's own `-f` check (`-s _`) | 0.075–0.078 |

446 D2 rejected sizing during the walk because it "would put it in two places
(the `-r` path and the glob path), against the one-resolution-surface rule".
D3 makes the plain path read its folder the way `-r` does, so one listing
routine can take the size in one place.

**F6 — The `-r` matcher and `bsd_glob` disagree in eight cases; D3 has to
close them for the plain path's selection to stay as shipped.** 420 N2 states
the matcher's contract: "Agreement with `bsd_glob` is the contract — 'the same
filename pattern' means the pattern a user writes selects the same names at
depth that it selects at the top level". Method: one folder of awkward names,
each pattern run through `bsd_glob` (what the plain path does today) and
through `readdir` plus `basename_matches_glob()` sliced verbatim from `ltl`,
with `bsd_glob`'s dot rule and order (`728-measure/matcher-diff.pl` in the
session scratchpad), macOS, 2026-11-01. Rules read from Perl's
`ext/File-Glob/bsd_glob.c` (v5.42.0) and `File/Glob.pm` 1.44.

| # | Pattern | `bsd_glob` (plain path today) | `-r` matcher | Where the difference lies |
|---|---|---|---|---|
| 1 | `[^a]*.888` | names starting `^` or `a`: `^` is a literal in a set | names not starting `a`: `^` read as negation | matcher |
| 2 | `[\]]*.888` | `]x.888`: an escaped `]` belongs to the set | nothing | matcher |
| 3 | `[z-a]*.888` | nothing | Perl dies: `ltl -r "[z-a]*.888"` exits 25 with `Invalid [] range "z-a" in regex ... at ltl line 26529` on stderr | matcher (a shipped crash) |
| 4 | Windows, any pattern | case ignored: File::Glob adds `GLOB_NOCASE` on `MSWin32` | case observed: `qr/\A$expr\z/`, no `/i` | matcher (from the source; not yet run on Windows) |
| 5 | `{c,a}.888` | `c.888 a.888`: each brace alternative is globbed and sorted on its own, in brace order | `a.888 c.888` | brace handling |
| 6 | `*.{888,txt}` | every `.888` name, then `b.txt` | all names in one sorted list | brace handling |
| 7 | `{a,a}.888` | `a.888` twice, so the plain path reads it twice | once | brace handling |
| 8 | `a{b.888` | nothing: an unbalanced brace makes `bsd_glob` glob only the text before it (`globexp2()`, "Non matching braces; just glob the pattern") | `ab.888` | brace handling |

A literal name typed in another case (`A.888` beside `a.888` on a
case-insensitive disk) is selected by `bsd_glob` as typed, because a literal
segment is checked, not matched against the folder; the matcher, reading the
folder, misses it. D3's routine leaves a literal final segment to `bsd_glob`,
as a literal costs one check and no folder read.

Rows 5 to 8 are closed for the plain path by expanding braces first, exactly as
`bsd_glob` does, globbing each alternative on its own and sorting each
alternative's matches with `bsd_glob`'s comparison (`ci_compare()`: case folded,
then byte order); `-r` keeps its own brace handling, so `-r` is unchanged there.
Rows 1 to 4 are in the matcher itself, which `-r` shares.

## Records searched

`./process/find-records.sh --issues -r --recursive --disable-progress
expand_recursive_pattern size_selected_files_for_progress progress_line_text
paint_progress_line "recursive file selection" spinner`, 2026-11-01. Read and
used above: `features/420-recursive-file-selection.md`,
`features/446-overall-progress-indicator.md`,
`features/532-progress-line-file-path.md`,
`features/597-section-visibility.md`, `features/412-notice-surfaces.md`,
`features/614-operand-settlement.md`,
`features/639-own-artifacts-as-input.md`,
`docs/progress-indication-best-practices.md`,
`docs/architecture-patterns.md`. Read and set aside:

| Record | Why it is set aside |
|---|---|
| `features/445-unquoted-glob-consumed-by-shell-before-r.md` | The quoting guidance for `-r`; it changes no selection and rides only on the no-files failure |
| `features/503-yaml-aggregate-export.md` | Records paths as supplied (F11 there); the indicator changes no path |
| `features/412-notice-surfaces-research.md` | Lists "spinner around a step" as a kind of progress line, from other tools; no `ltl` spinner |
| About forty records naming `--disable-progress` | Name it only as the way they invoke `ltl` |
