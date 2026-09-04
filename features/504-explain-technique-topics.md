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
  sixteen techniques it named. The roster is now nineteen (D4); the issue body
  carries the updated table.

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
included line, green `√` when it contributed included lines, and a green `√` on a
bright-green background when it contributed a line the highlight matched (verified
on a 5,000-line Tomcat access log under `-hf`: the marker rendered with the
background fill). Under `-i`/`-e` and `-h` this
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

### F10 — Resolution Zoom is a ladder of aperture and bucket width, alternated

From the interview (architect, 2026-09-04). The default bucket is 60 minutes, so a
day of logs reads as 24 rows and every absolute value is a one-hour total. That
view locates the area to zoom into, and nothing more: a spike at 12:00 says nothing
about what happens inside that hour. The move then alternates two adjustments, and
the alternation is the technique:

1. Close the aperture with `-st`/`-et` around the spike, dropping everything else.
2. Narrow the bucket for what remains — the hour at 60-minute width becomes 60 rows
   at one-minute width.
3. Read the result. Still localised to a particular minute means an anomalous
   occurrence, and the ladder continues. Flat across the hour means something
   occurring over a long span, and the answer is already in hand.
4. Continuing: tighten `-st`/`-et` again (12:32 to 12:38), then drop below the
   minute — five-second buckets, and more rows again.
5. Tighten once more (12:33:32) and change the timestamp precision, so the smallest
   unit goes minute, then second (`-s`), then millisecond (`-ms`).
6. At the finest grain: millisecond precision on the timestamp with 250ms buckets,
   giving four rows inside each second, which answers whether executions are spread
   evenly across the second or all land exactly on the second transition.

The precondition on the last step is the data: it only works if the log's own
timestamps carry millisecond precision.

### F11 — reported: normalised rates lose meaning at fine bucket widths (unverified)

Reported by the architect in the same interview; not observed in tool output during
this audit, and stated here as a claim to be tested, not a measured finding. As the
zoom tightens the absolute per-bucket counters shrink, because each bucket covers a
smaller period, while the message and error rates are normalised per `-ru` and so
ought to hold steady. From a one-hour bucket down to a five-minute bucket they
appear to. At a five-second bucket the normalised figures seem wrong: their
bucket-to-bucket variance becomes very large.

The architect's reading is that the arithmetic is right and the algorithm is simply
not adapted to the data present, or to what the feature is for at that resolution.
The aperture and the bucket width are separate causes and only the second is at
issue here: closing `-st`/`-et` around a spike drops the quiet periods and raises
the rate legitimately, because the remaining lines really are denser.

Filed as #535 (research: normalised message and error rates diverge at fine bucket
widths). Informational, not a gate: the Resolution Zoom topic teaches the rates as
the pair to watch across a zoom, and carries what that research concludes once it
settles.

### F12 — the Population moves run discovery through highlight, not through filtering

From the interview (architect, 2026-09-04), with the tool behaviour verified on a
5,000-line Tomcat access log slice.

The analyst arrives thinking about performance stability, and the question shifts
quickly. A high number of errors over time shows first as the size and length of
the category bars across the time buckets; the top-messages table, sorted by
occurrences by default, names the top contributors. Re-sorting with `-so` surfaces
different aspects of the same population: when something is taking excessively long
and getting slower, ranking on total duration gives the total time contribution per
message — per API.

The diagnostic move is what the table does *not* show. A high error count with no
error category among the top ten by occurrences means the errors come from many
patterns rather than one, so ranking by occurrences will never surface them: the
successful traffic crowds them out.

`-hf` resolves that without discarding the population. Verified output on the
access-log slice, where failures are 17 of 5,000 lines (0.34%): the top-N table
splits into `TOP HIGHLIGHTED MESSAGES (lines matching the highlight criteria)` and
`TOP OVERALL MESSAGES`, side by side. The three failing endpoints appear with their
status codes, occurrence counts and duration statistics, none of which a top-N by
occurrences would have shown; the run summary gains a `HIGHLIGHTED` count and the
category rows gain their `(HL)` twins.

That yields a name. With the name in hand the analyst switches the highlight from
failures to that message's string pattern, and the timeline then shows that one
API's contribution across time inside the full population — whether it failed
throughout, or succeeded in some periods and failed only in others. The population
is never cut away; the highlight is what moves.

### F13 — file attribution is a Population move, and the marker is its output

From the interview (architect, 2026-09-04). With seven or eight input files the
analyst does not know whether a pattern is present in all of them or only some.
Running the highlight over the whole set answers it from the summary's file list:
the green `√` marks a file that contributed matched lines, the red `χ` a file that
contributed none — either because it holds no such line or because filtering
removed them. That pinpoints one file out of the group, which is then something to
open directly or grep against.

This is the consumer that makes F3's undocumented marker worth writing down: the
marker is not a decoration on the file list, it is the output of the technique.

### F14 — API Isolation is include, then expose what consolidation masked

From the same interview. Once a pattern is in hand, troubleshooting starts with
`-i` to eliminate everything but the message in question, which gives the shape of
the contributions from messages matching that pattern, clear of the rest.

The second half of the move is what isolation makes affordable. Over a large
population the analyst wants general characteristics, so ltl masks, truncates and
consolidates away the varying parts of a message. Honing in reverses that: with one
API isolated, `-xqs` surfaces the query string, `-xu` the user name, `-xs` the
session, each separating what had been one consolidated row so that the aggregation
happens per query string, per user or per session. That answers whether one
particular user is contributing the errors, the volume or the slow requests.
Without isolating the API first there is too much noise in the view for it to be
read.

### F15 — exclusion is the inverse move, and it rescales what is left

From the same interview, with the effect verified on the 5,000-line access-log
slice. Having identified an API whose callers are anomalous, or a problem already
understood and being addressed, the analyst excludes it and reassesses: is the
remaining workload healthy, does it carry other areas of impact, is something else
being affected by that error.

Removing a dominant contributor also rescales the timeline. Measured, at one-minute
buckets over the slice: with everything included, the 09:48 and 09:49 buckets both
draw a 22-block bar and are indistinguishable; excluding the single endpoint that
accounts for 2,017 of the 5,000 lines leaves 09:48 at 17 blocks against 09:49 at
13, and the difference in the remaining traffic becomes readable. The dominant
message had been setting the scale and flattening everything measured against it.

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

### D4 — Population gains Remainder Analysis, Attribute Surfacing and File Attribution (architect, 2026-09-04)

Three techniques the interview surfaced have no home in the issue's original list
and are added to the Population group, taking the roster from sixteen techniques to
nineteen and the technique-family topic count to twenty-five (nineteen techniques
plus the six group pages of D1).

| Topic | `ltl --explain …` | The question it answers |
|---|---|---|
| Remainder Analysis | `remainder` | With the known problem taken out, is what is left healthy — and what shape does it have once it is no longer scaled against the thing that was removed? |
| Attribute Surfacing | `attribute-surfacing` | Which user, session or query string inside this one API is producing the errors, the volume or the slow requests? |
| File Attribution | `file-attribution` | Of these files, which ones contain the pattern — so which one is worth opening? |

Remainder Analysis is not the second half of API Isolation: isolation asks what
this looks like, subtraction asks what everything else looks like without it, and
its signal is the rescaling measured in F15, which the isolation page cannot render
at the same time.

Attribute Surfacing covers `-xqs`, `-xu` and `-xs` on one page because the move,
the reading and the precondition are the same for all three (F14). Session Isolation
keeps its own page for the different move: cutting to one session and reading that
journey through.

File Attribution sits in Population rather than Correlation because it is an
attribution question — which part of the input carries this — of the same shape as
which API carries this. Correlation relates two different logs on a shared axis,
which this does not.

## Technique roster

Nineteen techniques in six groups, each group also a topic of its own (D1).
Bold marks a technique added after the issue was filed.

| Group | Techniques |
|---|---|
| Time | Window Narrowing · Resolution Zoom · Traffic Load Profiling |
| Population | Contribution Highlighting · API Isolation · Session Isolation · Rank then Isolate · Outcome Isolation · **Remainder Analysis** · **Attribute Surfacing** · **File Attribution** |
| Shape | Tail Excursion vs. Distribution Shift · Bimodal Split · Variety vs. Volume · Timeout Clustering |
| Comparison | Period-over-Period Comparison · Status Composition Over Time |
| Concurrency | Thread Pool Utilisation |
| Correlation | Cross-Log Correlation |

## Planning walkthrough

1. **Anatomy contract** — the fixed shape of a technique topic and of a group
   page, and the registry changes each needs.
2. **Interview, group by group** — six passes pulling the techniques, their use
   cases, and the signal each one reads.
3. **Content spec** — the topics written out, one at a time, against the anatomy.
4. **Acceptance criteria and harness plan** — what `tests/validate-help-content.sh`
   asserts, and the `docs/explain/` mirror.
5. **Delivery shape** — whether twenty-two topics ship in one drop or several.
