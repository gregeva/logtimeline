# Feature: `--explain` technique topics

## Overview

`--explain` today answers *what does this number mean*. Every topic it carries —
the statistics, the two charts, the classification methodology — explains a thing
the tool prints. An analyst mid-investigation has a different question: *how do I
go and find it*. This work adds that second kind of content to the same surface:
named analysis techniques, each one an investigative move the tool already
supports, written down where the analyst already is.

Two capabilities the techniques rest on are implemented but documented nowhere an
engineer could follow them. Writing them down is a deliverable of this work, not a
by-product.

## GitHub Issue

- #504 (FEATURE: `--explain` technique topics — named analysis techniques as a
  second topic family) — the requirement, including the six groups and the
  sixteen techniques.

## Audit findings

Findings from the documentation and code-surface audit that opened the planning
walkthrough. Each is stated as what was read, in what, and what a reader would
observe.

### F1 — `--explain` already carries three categories, not one

`@explain_groups` in `ltl` tags each group with a category — `statistics`
(five groups: Range, Central tendency, Spread, Percentiles, Distribution shape),
`visualizations` (heatmap, histogram) and `methodology` (classification) — and
`print_explain_registry()` emits a top-level section heading at every category
transition, from `%explain_category_heading`. The issue's premise still holds:
every existing topic explains what a thing means. But the registry change this
work makes is a **fourth** category, not a second, and the issue's "second topic
family" names the kind of content, not the count.

`$_explain_stats_group_count = 5` slices `@explain_groups` for
`ltl --help statistics`, which takes only the leading statistics groups. New
groups are appended after the existing ones or that constant stops describing the
slice it names.

### F2 — the per-topic intro sentence is already false for three topics

`print_explain_topic()` prefixes every topic, whatever its category, with one
fixed sentence: *"Long-form documentation for one of the statistics ltl computes
for every message entry — usable to rank the top-messages table via `-so` and
exported in full with `-o` CSV…"*. Running `ltl --explain classification`,
`--explain heatmap` or `--explain histogram` prints that sentence above content
that is not a per-message statistic and cannot rank anything. Pre-existing defect;
this work cannot add a fourth category without resolving it.

### F3 — file attribution under filter and highlight is undocumented

The run summary's file list prints a per-file marker ahead of each filename, from
`@match_char` and `%in_files_matched`: red `χ` when the file contributed no
included line, green `√` when it contributed included lines, and bright green `√`
when it contributed a line the highlight matched. Under `-i`/`-e` and `-h` this
answers *which of these files is the signal actually in*, over any number of input
files, without a separate run per file. `docs/usage.md` does not mention the
marker in any form.

### F4 — counts beside normalised rates across bucket resolutions is undocumented

The legend's right part carries the message rate over the error rate, each
normalised to `-ru` (default per minute) in `read_and_process_logs()`
(`msg-rate`, `err-rate`), standing beside the bucket's raw category counts, which
scale with `-bs`. The pairing is what makes two runs at different bucket widths
comparable: the counts change, the normalised rate does not. `docs/usage.md`
carries the bare `-ru` option row and nothing about the relationship.

### F5 — the outcome surface is wider than errRate

Classification (#453, #455, #452) is delivered into `release/0.18.0` and gives
Outcome Isolation a full surface. A line is a success, a failure, a classification
conflict or unclassified; a message row whose lines are not all of one state is
mixed. The analyst-facing surfaces are:

| Surface | What it shows |
|---|---|
| `-if` / `-ef`, `-is` / `-es` | Include or drop failures and successes; `-ef -es` leaves the unclassified remainder |
| `-hf` / `-hs` | Highlight failures or successes within the full population, filtering nothing |
| Top Messages table | Per-message indicator: the marker position carries the row's state as a colour (green success, red failure, violet conflict, terracotta mixed, no mark when unclassified) |
| Timeline success % / failure % columns | Per time bucket, over the bucket's classified lines. Default on event-ledger formats, hidden with `-hcl`, enabled on a classifying non-ledger format with `-scl` |
| Run summary | `SUCCESS CLASSIFIED`, `FAILURE CLASSIFIED`, `UNCLASSIFIED`, `CLASSIFICATION CONFLICT`, `MIXED` rows with their shares |

The success and failure percentage columns are the intended read of outcome over
time. `errRate` is the older, coarser signal and is not the technique's subject.

### F6 — rendered signal shapes are bounded at 80 columns

`render_pre()` returns its text verbatim, so an ANSI/ASCII signal shape renders
unchanged and is never reflowed. Nothing measures escape-sequence width, and
`help_wrap_width()` returns `max(80, --terminal-width)`. Every rendered shape is
therefore authored to fit 80 columns, and its visible width is counted excluding
escape sequences.

### F7 — the analyst's path crosses groups; the groups are not a sequence

From the interview (architect, 2026-09-04). Where an investigation enters depends
on the signal that started it: a named day or time, or a known error time to work
outwards from. From there the move is usually to broaden rather than narrow — what
was happening before the error, whether the same thing happens daily at the same
time, how one day compares with another and one week with another. Only after that
broad look does the analyst narrow the window and raise the resolution.

Two consequences for the content. First, Window Narrowing is bidirectional: setting
`-st`/`-et` around a known error time to see what preceded it is the same move as
cutting down to a spike, and the topic covers both. Second, the population question
comes before the time zoom — the analyst first establishes whether one API or
pattern accounts for the occurrences or whether they are spread across the
population, and only then zooms. So the Time and Population groups interleave in
practice, and each group page's *See also* names the group the analyst typically
reaches for next rather than presenting the six groups as an ordered pipeline.

### F8 — Traffic Load Profiling and Period-over-Period Comparison share `-pr` and differ by intent

From the interview (architect, 2026-09-04). Both techniques drive the profile
folding modes (`-pr day`, `week`, `workweek`, …); the line between them is what the
analyst is asking, not which option they type.

**Traffic Load Profiling** reads the shape of the load itself: what it looks like
hour to hour and day to day, where the high and low days fall across a week, where
the peak-load periods and excessive concurrency sit, and whether errors occur in
consistent groupings or some other pattern. The architect names it the most
important technique in the Time group.

**Period-over-Period Comparison** puts the same folding to two different uses.
First, normalisation: the week in question may be a poor example of representative
behaviour — a spike on one day from activity that would not normally occur — so
folding several periods together broadens the observed sample into a more diverse
population, smooths the peaks and yields a normalised trend. It is not good for
finding specific things; it is what to reach for when the question is what the
profile generically looks like. Second, before and after: a baseline captured after
a go-live or a benchmarking exercise, against current behaviour once users have
complained. Merging both corpora into one run and folding by period aligns them on
the same times, so the analyst can see whether the periods of high load or errors
line up between the two, or amplify the totals.

### F9 — no way to highlight a specific input file, so before/after is roundabout

Stated by the architect in the same interview. The before/after use of
Period-over-Period Comparison wants the population cut in two along the boundary
between the baseline corpus and the current one. `ltl` has no option that
highlights lines by the file they came from: `-h` and the pattern files match line
content, and the per-file evidence that exists (F3's `χ`/`√` marker) is a summary
indicator, not a highlight series. The analyst therefore reaches the comparison
over a couple of executions rather than one, and the Period-over-Period topic has
to teach that roundabout form.
Filed as #534 (highlight the lines contributed by a specific input file).
Informational, not a gate: this work is specified and implemented in full against
the multi-run form that works today, and the Period-over-Period Comparison topic
gains a pointer once #534 lands.

## Locked decisions

### D1 — Flat table of contents; group pages are leaves, not indexes (architect, 2026-09-04)

`ltl --explain` with no argument stays a table of contents: category headings,
group headings, one line per topic. There is no nested index and no drill-down
level. Each of the six technique groups is itself a topic — `ltl --explain time`
prints the page explaining the Time grouping and the use cases it serves — but it
is a leaf page like any other, not a listing of its techniques. The sixteen
techniques are leaf topics beside it. Twenty-two technique-family topics in all.

### D2 — Topic names are the distinctive words, kebab-cased (architect, 2026-09-04)

A technique is reached by the distinctive words of its name in kebab case —
`ltl --explain tail-excursion`, `ltl --explain window-narrowing` — while the full
name (`Tail Excursion vs. Distribution Shift`) is what the page heading and the
table of contents show. The existing statistics topics keep their snake_case names
(`std_dev`, `bimodality_coef`), so the registry carries both styles; the technique
family is internally consistent and the two styles never collide.

### D3 — Page anatomy: technique pages and group pages (architect, 2026-09-04)

A technique page uses the existing block vocabulary, dropping the statistics
family's *How ltl computes this* section — a technique is not computed:

| Section | Block | Content |
|---|---|---|
| heading | `heading` | The full name, uppercased |
| — | `paragraph` | The question the technique answers, one sentence |
| The signal | `pre` | The shape rendered in ANSI/ASCII, at most 80 visible columns (F6) |
| How to read it | `paragraph` | The reading, and what would falsify it |
| Command | `pre` | The worked command |
| See also | `paragraph` | Related techniques and the options the technique uses |

A group page is the same skeleton, with its techniques listed:

| Section | Block | Content |
|---|---|---|
| heading | `heading` | The group name, uppercased |
| — | `paragraph` | What the grouping is |
| When to use it | `paragraph` | The use cases the grouping serves |
| Techniques | `table` | Each technique in the group: its topic name and its one-line question |
| See also | `paragraph` | The other groups, and `ltl --explain` for the table of contents |

The group page lists its techniques so an analyst who does not yet know a
technique's name has a usable entry point. It stays a leaf page under D1: the
listing is content, not a drill-down level, and `ltl --explain` remains the only
index.

## Planning walkthrough

1. **Anatomy contract** — the fixed shape of a technique topic and of a group
   page, and the registry changes each needs.
2. **Interview, group by group** — six passes pulling the techniques, their use
   cases, and the signal each one reads.
3. **Content spec** — the topics written out, one at a time, against the anatomy.
4. **Acceptance criteria and harness plan** — what `tests/validate-help-content.sh`
   asserts, and the `docs/explain/` mirror.
5. **Delivery shape** — whether twenty-two topics ship in one drop or several.
