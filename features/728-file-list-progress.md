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
contracts are confirmed by the architect; D1 to D6 are locked.

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

**D6 — The line first appears once the listing has taken 1 second**
(architect, 2026-11-01). A listing that finishes inside the second shows
nothing, so a normal run looks and captures exactly as it does today. This
adopts the startup delay `docs/progress-indication-best-practices.md` item 9
records as available (git hides its bar for the first second). Chosen over
drawing the line as soon as the listing starts.

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
