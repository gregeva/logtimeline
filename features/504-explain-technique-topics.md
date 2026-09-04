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

### F6 — rendered examples are generated in code at a fixed cell width

The explain surface reflows to the actual terminal width: measured on
`--explain kurtosis`, the widest rendered line is 100 characters at
`--terminal-width 100`, 140 at 140 and 200 at 200. The 80 in `help_wrap_width()`
is a floor for narrower terminals, not a cap. The banner is a fixed 94-character
rule that does not respond to width at all; `tests/validate-explain.sh` excludes it
from the width assertion by design, recording that it carries its own width contract
independent of `--explain` content.

`render_pre()` returns its text verbatim, so a `pre` block is the one thing that
does not reflow — and the established practice for a rendered example is not to
hand-draw one. Both existing visual topics generate theirs in code at a fixed cell
width, sourcing their colours from the tool's own definitions so the example matches
what the tool actually draws: the heatmap example is built at 80 cells from the
`@column_colors` yellow gradient, the histogram example at a 60-cell bar area with
its tick marks placed against that width. The width is a property of the chart being
drawn, chosen where the example is built, and is comfortably inside any terminal
that renders the rest of the page.

The technique topics' signal shapes follow that practice rather than introducing a
new one.

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

### F16 — the technique is attribute isolation, and the session is only one attribute

From the interview (architect, 2026-09-04). Session Isolation as the issue named it
is a special case of a general move: the analyst holds an attribute of the activity
and wants to isolate on it, highlight it, or exclude it. The attribute may be the
session, a thread, a user, a remote host, a query string, or a value inside the
message itself — a filename requested from a download API, a user name executing a
particular set of calls, a thread name recurring across a string of errors. The
move, the reading and the surfaces are the same whichever it is; only the field
changes.

Two attributes the move applies to cannot be exposed today, and the architect
identified both during the interview: the thread name, and the remote host in
access logs. Grouping, filtering or highlighting on either would be useful and each
needs an exposure surface of its own. Filed as #536 (expose the thread name as an
attribute) and #537 (expose the access-log remote host as an attribute).
Informational, not gates: the Attribute Isolation topic is written against the
attributes that exist today and gains these two once they land.

### F17 — the Shape techniques enter through the ranked message table, not the timeline

From the interview (architect, 2026-09-04). The framing the group needs correcting
first: the timeline *is* the distribution across time. It says a great deal visually
about a population, and the heatmap adds a per-bucket histogram, so an analyst can
see between time buckets whether the distribution is evolving or holding steady.

What it cannot do is show modality. Across a whole population of hundreds of
thousands of requests the gaps fill in; something may peek out, but there is no way
to tell from that view whether it belongs to one API or is a general pattern of
those time ranges.

So the shape statistics are reached, today, through the top-messages table.
Ranking on a shape metric — sorting or reverse-sorting according to what the
technique calls for — turns the table into a list of candidates. The analyst then
includes, excludes or highlights one of them, which isolates it, and reads its own
heatmap and histogram: how the distribution evolves for that message alone, and
what its modality actually looks like.

Two consequences. The Shape techniques all enter through Rank then Isolate, which
sits in the Population group, so each Shape topic names it as the way in — the same
cross-group interleaving F7 records for Time and Population. And the group page for
Shape says plainly that modality is not readable off the whole-population views, so
an analyst does not go looking for it there.

### F18 — three Shape techniques derive from the shipped shape-statistic content (locked)

Drafted by Claude from `docs/explain/statistics.md` § Distribution shape and the
matching `--explain` topics, on the architect's direction that the shape metrics
already document their own uses, plus his answer that kurtosis is what he reaches
for to detect a very long tail. Locked as written by the architect, 2026-09-04.

**Tail Excursion vs. Distribution Shift.** Rank on `kurtosis` to build the
candidate list, then isolate and read the candidate's percentiles against its
kurtosis. High kurtosis with an unremarkable `p50` and `p90` is a tail excursion:
most requests are fine and a small population is suffering outliers concentrated in
the tail, which `p99` and `p999` expose. Low kurtosis with a slow `p50` is a
distribution shift: uniform slowness affecting everyone. The two look alike in
`p50`/`p90` alone, which is why the shape metric is what separates them.

**Timeout Clustering.** Rank on `skewness` ascending (`-sa`) to surface the
negatively-skewed candidates. Latency is naturally right-skewed, so near-zero or
negative skewness on a slow call is the signature of a hidden cap: requests that
should run long are being killed at a ceiling and piling up there. Isolating the
candidate and reading its histogram shows the pile at the cap. This is the manual
form of the move; #193 (timeout auto-detection, on hold) would automate it.

**Bimodal Split.** Rank on `bimodality_coef`; above 0.555 is suspect multimodal,
approaching 1.0 strongly so. Isolate the candidate and read its histogram for two
peaks with a valley where the mean sits. The falsifiers are documented with the
statistic and belong on the technique page: below about 100 observations random
noise alone clears the threshold, so a high value on a low-traffic call is a hint
and not a verdict; and very unequal modes (99% fast, 1% slow) can leave the
coefficient under threshold on a distribution that is genuinely bimodal.

The fourth Shape technique is not a shape-statistic move at all; see F19.

### F19 — the fourth Shape technique compares one thing's shape against the population's

`Variety vs. Volume` was Claude's coinage in the session that filed #504 and carries
no authority; the architect does not use the term. What he described in its place
(interview, 2026-09-04): variety meaning the types against the volume, how closely
grouped various things are — answered with the heatmap and the histogram coupled
with highlighting, comparing visually the shape of one thing to the shape of the
population.

Verified on the 5,000-line access-log slice. `-hg duration` with a highlight on one
endpoint draws both series in the same chart and prints two percentile rows: the
population at `P50 2ms`, `P95 308.6ms`, `P99 1s`, and beneath it the highlighted
endpoint at `P50 1ms`, `P95 2ms`, `P99 3ms`. The highlighted call renders as one
tight column near 1ms while the population spreads across three decades. The
comparison is both visual and numeric in a single view, with no second run and
without cutting the population away.

### F20 — Status Composition Over Time is read down the column, and the highlight splits it

From the interview (architect, 2026-09-04), with the highlight behaviour verified on
the 5,000-line access-log slice.

The technique is the mix moving while the volume holds: 2xx giving way to 4xx at
constant volume is a different event from 5xx appearing on top of unchanged 2xx, and
a single failure percentage collapses both into one number.

Three things make the column readable, and the topic has to teach all three.

**The shortened totals are what make rows comparable.** Comparing absolute values
down a column works while the numbers are small. Once they are large it stops
working, which is why the category totals carry engineering suffixes: `1.5k` beside
`1.5k` is close enough, and the reader does not need to know whether the difference
was 1,525 against 1,582. At `40` against `20` the difference matters and the
unshortened figures are there to be read.

**The percentages answer the coherent question and the counts answer the next one.**
Reading straight down the success and failure percentage columns answers whether
the traffic in each bucket succeeded and in what proportion; the absolute count
columns beside them answer how many.

**The highlight splits the composition per bucket.** Verified: with a highlight on
one API, each bucket's legend carries that API's own per-status counts beside the
population's. On the slice, the 09:48 bucket reads `5xx(HL) 1 · 4xx 5 · 3xx 1 ·
2xx(HL) 379 · 2xx 891` — the highlighted API accounts for every 5xx in the bucket,
which no population-level figure would have shown. That is what answers whether one
API is driving the success percentage down or is the source of all or most of the
errors. The highlighted twin renders as a bare number whose identity is carried by
its colour rather than a repeated label, so the technique page says how to read it.

### F21 — the Concurrency technique is load over time, and thread pools are one instance of it

From the interview (architect, 2026-09-04), with the log shape verified in the
Windchill method-server corpus.

The architect's correction: the technique is a visual comparison over time using the
timeline's chart columns. A column can carry a bar chart of the number of distinct
text values in each bucket, or of a numeric value under an aggregation function.
Concurrency is one reading of that column, not the technique itself — "the technique
as an indication of load over time is really the purpose".

What the concurrency reading gives: the number of threads active in a pool over a
period, set against the request count, which says whether the pool is sized right —
constantly at its ceiling and circulating — and exposes a bottleneck when the thread
count reaches its maximum and everything then comes to a halt.

The same column, the same reading, over other attributes. Distinct sessions per
bucket is a load measure: how many separate user sessions were live in that period.
Distinct users per bucket gives concurrent users and how that evolves. Both appear
on their own when the log carries the field; the thread-pool form is switched on
with `-tpa` for a named pool or `-tpas` for all of them.

`-udm` extends the same surface to anything else the line carries: an analyst
defines one or many custom metrics, each with its own aggregation function, and each
is drawn as a bar-chart column beside the others. The worked case is a queue depth
read over time. The method-server corpus carries queue-watcher notification lines
whose payload is a run of `Name=Value` pairs, among them the queue's total entry
count, its waiting-ready count and its average entry execution time; extracting the
entry count per queue and graphing it per time bucket turns those lines into a queue
observation over time. (Corpus content is not reproduced here: the lines carry host
and queue names.)

### F22 — Cross-Log Correlation is the same file-marker read, driven by any criterion

From the interview (architect, 2026-09-04), with the marker behaviour verified on two
access logs.

What the architect correlates is different logs from the same system — separated by
physical node, by application instance, or by date — each writing its lines to its
own file. The question is which of those files surfaces a pattern or satisfies a
condition, and the answer is the yes/no marker in the summary's file list: the check
where a file matched, the highlight marker where it matched the highlight criteria.

The criteria are not limited to text patterns: every include, exclude and highlight
criterion drives the file list. `-hdmin 60000` answers which log files carried
requests over sixty seconds; `-if` reduces the run to the files that contain
failures. With `-r` the same read extends across a directory tree, so the markers
give correlation across files *and* folders — which node's directory, which day's
rotation, which instance's subtree carries the condition. Verified over a two-file run: with `-hdmin 1000` both files take the
highlight marker; raising the threshold to a deliberately extreme value leaves one
file with the highlight marker and drops the other back to the plain check. The
marker therefore discriminates between files on numeric and outcome criteria exactly
as it does on a highlight pattern (F3).

This collided with File Attribution (D4) — the same mechanism, surface and signal,
differing only in framing. Resolved by D8: the two are one technique.

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
| The signal | `pre` | The shape rendered in ANSI/ASCII, generated in code at a fixed cell width from the tool's own colour definitions, per the existing practice (F6) |
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
plus the six group pages of D1). D7 later takes it to twenty and twenty-six.

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
the reading and the precondition are the same for all three (F14). Attribute Isolation
(D5) keeps its own page for the different move: acting on one known attribute
value — isolating, highlighting or excluding it.

File Attribution sits in Population rather than Correlation because it is an
attribution question — which part of the input carries this — of the same shape as
which API carries this. Correlation relates two different logs on a shared axis,
which this does not.

### D5 — Session Isolation becomes Attribute Isolation (architect, 2026-09-04)

The architect's framing: the technique "is actually about attribute isolation,
highlighting, or exclusion. Whether we are talking about a session or a thread or a
user or an IP address or a query string." Session Isolation is renamed **Attribute
Isolation** (`ltl --explain attribute-isolation`) and written generically, with the
session as one worked attribute among several. It pairs with Attribute Surfacing
(D4): surfacing separates the population by an attribute so its values can be seen;
isolation acts on one value once it is known.

### D6 — Shape Comparison replaces Variety vs. Volume (architect, 2026-09-04)

The fourth Shape technique is **Shape Comparison**
(`ltl --explain shape-comparison`), answering *does this one thing have the same
shape as the population, or its own?* It is read off the histogram's two overlaid
series and its two percentile rows under a highlight (F19), and off the heatmap for
whether that relationship holds or changes across time buckets. It is the only
Shape technique that does not enter through a ranked shape statistic: the candidate
is already in hand and the question is how it sits against everything else.

### D7 — the Concurrency group becomes Load, with two techniques (architect, 2026-09-04)

Following F21, the group and its single technique are both renamed and a second
technique is added.

| | Was | Is |
|---|---|---|
| Group | Concurrency | **Load** — concurrency is one reading of the column, not the whole of it |
| Technique | Thread Pool Utilisation | **Load Over Time** (`load-over-time`) — the distinct-count column read as a load indicator: sessions and users appearing on their own when the log carries them, thread pools switched on with `-tpa` or `-tpas`; read for pool sizing when the count sits at its ceiling and circulates, and for the bottleneck where it reaches maximum and throughput stops |
| Technique | — | **Custom Metric Tracking** (`custom-metric`) — `-udm` placing any token or value the line carries onto the same bar-chart surface under its own aggregation function, worked as queue depth over time |

Two pages rather than one because the preconditions differ: Load Over Time reads
what the tool derives by itself, Custom Metric Tracking requires the analyst to
define the extraction before there is anything to draw, and each has its own signal
to render.

The roster is twenty techniques and twenty-six topics.

### D8 — File Attribution merges into Cross-Log Correlation (architect, 2026-09-04)

File Attribution (D4) and Cross-Log Correlation are one read of one surface, and are
merged into a single technique, **Cross-Log Correlation**, in the Correlation group.
File Attribution is dropped from the Population group; the rest of D4 stands.

The page's question is *which of these logs exhibits this condition?* — where the
logs are the same system separated by physical node, application instance or date.
Its criteria are every include, exclude and highlight criterion the tool has: text
patterns, the numeric thresholds, and the outcome filters. Its signal is the marker
column in the summary's file list. Under `-r` the same read covers a directory tree,
so the answer names a folder as readily as a file. The "which file do I go and open"
use falls out of the same page rather than needing one of its own.

The roster returns to nineteen techniques and twenty-five topics.

## Technique roster

Nineteen techniques in six groups, each group also a topic of its own (D1).
Bold marks a technique added after the issue was filed.

| Group | Techniques |
|---|---|
| Time | Window Narrowing · Resolution Zoom · Traffic Load Profiling |
| Population | Contribution Highlighting · API Isolation · Attribute Isolation *(was Session Isolation, D5)* · Rank then Isolate · Outcome Isolation · **Remainder Analysis** · **Attribute Surfacing** |
| Shape | Tail Excursion vs. Distribution Shift · Bimodal Split · Shape Comparison *(was Variety vs. Volume, D6)* · Timeout Clustering |
| Comparison | Period-over-Period Comparison · Status Composition Over Time |
| Load *(was Concurrency, D7)* | Load Over Time *(was Thread Pool Utilisation, D7)* · **Custom Metric Tracking** |
| Correlation | Cross-Log Correlation *(absorbs File Attribution, D8)* |

## Requirements

Derived from #504 and from the interview findings above. Each is what the analyst or
the reader observes, not how it is built.

- **R1** — `--explain` carries a fourth category alongside `statistics`,
  `visualizations` and `methodology`, holding the six technique groups. It is
  appended after the existing groups so the leading-statistics slice that
  `--help statistics` takes continues to describe what it names (F1).
- **R2** — Twenty-five topics are reachable and listed: nineteen techniques and six
  group pages (D1, D4, D5, D6, D7, D8), each addressed by the distinctive words of
  its name in kebab case, with the full name shown as the page heading and in the
  table of contents (D2).
- **R3** — A group page explains what the grouping is, when to use it, and lists its
  own techniques with their one-line questions (D1, D3).
- **R4** — A technique page answers, in this order: the question it answers, what
  the signal looks like, how to read it including what would falsify the reading,
  and the worked command (D3). It carries no *How ltl computes this* section — a
  technique is not computed.
- **R5** — The signal is rendered, not described: the page shows the shape the
  analyst will see, built the way the heatmap and histogram examples are built —
  in code, at a fixed cell width, from the tool's own colour definitions (F6).
- **R6** — No topic is introduced by prose that misdescribes it. The single fixed
  sentence that today tells every reader they are looking at a per-message statistic
  ranked by `-so` is wrong for the four existing non-statistic topics and for all
  twenty-five new ones (F2).
- **R7** — `--help statistics` continues to index the statistics only, as it already
  excludes the visualization topics (F1).
- **R8** — Two capabilities that work today and are documented nowhere are written
  down: which input files carry a pattern or satisfy a criterion, read off the
  summary's file-list markers under every include, exclude and highlight criterion
  and across directories under `-r` (F3, F22); and the normalised message and error
  rates standing beside absolute counts that change with the bucket width (F4).
- **R9** — Every technique-family topic's content is mirrored under `docs/explain/`,
  as the statistics, heatmap, histogram and classification topics are.
- **R10** — The content carries no internals: no Perl identifiers, issue numbers or
  decision labels, in either the terminal pages or the mirror.
- **R11** — A group page's *See also* names the group an analyst typically reaches
  for next; the six groups are not presented as an ordered pipeline (F7).

## Acceptance criteria

Triaged before implementation. *Assertable* means the verification method is known;
*unassertable* records a gap and its reason. The owning harness is
`tests/validate-explain.sh`, which already carries the scenario vocabulary these
extend.

### Assertable

- [x] **AC1 (R1, R2)** — `ltl --explain` with no argument emits the technique
      category's top-level section heading, the six group subheadings beneath it,
      and all twenty-five topic names each with a one-line summary. Extends
      `scenario_registry`, which already asserts a heading per category transition
      and a listing per topic.
- [x] **AC2 (R2)** — For each of the twenty-five names, `ltl --explain <name>` exits
      0, renders at least twenty lines, opens with an uppercase heading and carries
      a *See also* near the end. This is `scenario_all_topics_render` unchanged in
      shape, with the new names added to its topic list.
- [x] **AC3 (R4)** — Every technique page renders, in order, a paragraph, a *The
      signal* subheading followed by a `pre` block, a *How to read it* subheading,
      a *Command* subheading followed by a `pre` block, and *See also*; and no
      technique page carries a *How ltl computes this* subheading.
- [x] **AC4 (R3)** — Every group page renders a paragraph, a *When to use it*
      subheading, a table, and *See also*; the table's row count equals the number
      of techniques the roster gives that group.
- [x] **AC5 (R5)** — At `--terminal-width` 80, 120 and 200, no rendered content line
      of any new page exceeds the width. This is `assert_max_line_width` as it
      stands: it already excludes the title banner and exempts verbatim `pre`
      blocks, so a signal block at its fixed cell width passes by the same rule the
      heatmap and histogram examples pass under today.
- [x] **AC6 (R5)** — Each technique page's signal survives to raw output with its
      ANSI escape sequences intact, asserted the way `scenario_visualization_charts`
      asserts the heatmap and histogram examples: a CSI count over the page's raw
      bytes, so accidental stripping at authoring time fails the harness.
- [x] **AC7 (R6)** — No technique or group page carries the statistics intro
      sentence, and no existing topic loses an introduction: every page's intro
      describes the kind of topic it actually is.
- [x] **AC8 (R7)** — `ltl --help statistics` lists none of the twenty-five
      technique-family topic names, asserted the way the same scenario already
      excludes `heatmap` and `histogram`.
- [x] **AC9 (R8)** — The Cross-Log Correlation page names all three file-list marker
      states and says that every include, exclude and highlight criterion drives
      them; the Resolution Zoom page states that absolute counts change with the
      bucket width while the normalised rates do not.
- [x] **AC10 (R10)** — No rendered page, and no mirror file, contains a Perl
      identifier, an issue number or a decision label.
- [x] **AC11 (R9)** — Every technique-family topic has mirrored content under
      `docs/explain/`.

### Unassertable

`[~]` marks a criterion met by its compensating practice rather than by an
assertion.

- [~] **AC12 (R5)** — *That a signal faithfully depicts what `ltl` draws for that
      technique.* AC6 proves a signal is present and its bytes survive; nothing
      mechanical proves the shape is the one the tool would actually produce on that
      data. `docs/test-driven-development.md` records that the general method for
      asserting a rendered terminal surface is an open question in this repository
      and scopes it as prototyping research. Compensating practice, per the same
      document: each signal is verified by running the technique's own worked
      command against a real log and comparing the rendered output to the page.
      Disposition in D9: that practice stands as the verification.

### D9 — AC12 stands on the compensating practice (architect delegated, 2026-09-04)

The architect delegated the choice. AC12 — that a signal faithfully depicts what
`ltl` draws — stays a recorded gap rather than becoming prototyping scope on this
issue. The verification is the one `docs/test-driven-development.md` already
prescribes for a visual surface: every signal is produced by running that technique's
own worked command against a real log and matching the page to what came back, and
the worked command on the page is the same command. AC6 keeps the mechanical guard
that the signal is present and its bytes survive. Deriving a general method for
asserting a rendered terminal surface remains the repository-wide open question that
document already records, and is not carried by this issue.

### D10 — one mirror file for the whole technique family (architect delegated, 2026-09-04)

`docs/explain/` mirrors a family in one file (`statistics.md` holds all thirteen
statistics) and a standalone topic in its own (`heatmap.md`, `histogram.md`,
`classification.md`). The technique family follows the family precedent: a single
`docs/explain/techniques.md` carrying all twenty-five pages, in roster order, group
page before its techniques. One file keeps the cross-references between techniques
navigable in the wiki, which is where the analyst follows them.

### D11 — three drops (architect, 2026-09-04)

| Drop | Contents |
|---|---|
| 1 | The fourth category and its registry entries; the six group pages; the intro fix of R6; and Cross-Log Correlation end to end as the worked technique |
| 2 | Time (3 techniques) and Population (7) |
| 3 | Shape (4), Comparison (2) and Load (2) |

Cross-Log Correlation is the worked technique of drop 1 because it exercises the
hardest part of the anatomy — a generated signal drawn from the tool's own colour
definitions — and because it delivers half of R8, the file-list attribution that is
implemented today and documented nowhere.

## Content specification

One block per topic: the question the page answers, the signal it renders, what the
reading is and what falsifies it, and the worked command. The finished prose is
written during implementation against these; the finding each rests on is named.

### Time — group page `time`

The grouping: locating behaviour in time. Where an investigation enters depends on
the signal that started it — a named day, a known error time to work outwards from,
or nothing but a suspicion — and the first move is more often to broaden than to
narrow (F7). *See also* points at Population, which is where the question usually
goes next.

**Window Narrowing** — `window-narrowing`. *Question:* what was happening around this
moment? *Signal:* the timeline with the aperture open, then closed around the point
of interest. *Reading:* the move runs both ways — widening around a known error time
to see what preceded it is the same move as cutting down to a spike (F7).
*Falsifier:* narrowing changes the population, so a rate that rises after the cut has
not necessarily risen in the system — the quiet periods were simply dropped (F11).
*Command:* `-st` and `-et`.

**Resolution Zoom** — `resolution-zoom`. *Question:* what is inside that bar?
*Signal:* one hour drawn at 60-minute width, then at one-minute width, then below the
minute. *Reading:* the ladder alternates aperture and bucket width; still localised
to a single minute means an anomaly worth another rung, flat across the hour means a
condition that ran for the hour and the answer is already in hand (F10). The counts
shrink as the buckets narrow while the normalised rates hold, which is what makes two
rungs comparable (F4). *Falsifier:* at very fine widths the normalised rates lose
meaning through bucket-to-bucket variance (F11), and the millisecond rung needs
millisecond timestamps in the log. *Command:* `-st`/`-et` with `-bs`, then `-s`, then
`-ms` with sub-second `-bs`.

**Traffic Load Profiling** — `traffic-load-profiling`. *Question:* what does the load
look like hour to hour and day to day? *Signal:* the timeline folded onto one
representative period. *Reading:* where the high and low days fall across a week,
where peak load and excessive concurrency sit, and whether errors recur in consistent
groupings (F8). *Falsifier:* folding a single unrepresentative period reproduces its
one-off spikes as if they were the rhythm — that is what Period-over-Period
Comparison's normalising use exists for. *Command:* `-pr day`, `-pr week`,
`-pr workweek`.

### Population — group page `population`

The grouping: attributing a signal to a part of the traffic. This is where an
investigation usually turns, and the population question generally precedes the time
zoom (F7, F12). *See also* points at Shape and at Time.

**Contribution Highlighting** — `contribution-highlighting`. *Question:* how much of
this is that? *Signal:* the highlight bar beside the main bar, the `(HL)` twins in the
legend, and the `TOP HIGHLIGHTED MESSAGES` table beside `TOP OVERALL MESSAGES`.
*Reading:* the share a pattern contributes across time without discarding anything;
the message table surfaces the matched rows even when they are a fraction of a
percent of the population (F12). *Falsifier:* none of the population is removed, so
the totals stay honest — but the highlight matches line content, not the file a line
came from (F9, #534). *Command:* `-h <regex>`.

**API Isolation** — `api-isolation`. *Question:* what does this call look like on its
own? *Signal:* the timeline containing only the matching lines. *Reading:* the shape
of one call's contribution, clear of everything else, which is what makes the
attribute exposures readable afterwards (F14). *Falsifier:* every rate, scale and
total now describes the isolated subset, not the system. *Command:* `-i <regex>`.

**Attribute Isolation** — `attribute-isolation`. *Question:* what is this one session,
thread, user, caller or query string doing? *Signal:* the timeline cut to, or
highlighting, one attribute value. *Reading:* an attribute of the activity is held
and the population is isolated on it, highlighted by it, or has it removed — the move
is the same whichever attribute it is (F16). *Falsifier:* the attribute has to be on
the line; the thread name and the access-log remote host cannot be addressed this way
yet (#536, #537). *Command:* `-i`, `-h` or `-e` on the value.

**Rank then Isolate** — `rank-then-isolate`. *Question:* which message should I be
looking at? *Signal:* the top-messages table re-ranked. *Reading:* occurrences name
the volume contributors, total duration names the time contributors — the right
ranking depends on whether the complaint is about how much or about how long (F12).
It is also the entry point for every Shape technique (F17). *Falsifier:* a ranking
metric the rows cannot support returns nothing to rank. *Command:* `-so duration -n 20`,
then `-i` on the winner.

**Outcome Isolation** — `outcome-isolation`. *Question:* which messages are failing,
and is one of them responsible? *Signal:* `TOP HIGHLIGHTED MESSAGES` under a failure
highlight beside the overall table, and the per-row state marker. *Reading:* failures
that a ranking by occurrences would never surface appear with their names, counts and
durations; the four states keep the figures honest (F5, F12). *Falsifier:* a format
that declines to classify produces no outcome at all, and a large unclassified share
means the classified pair is not the whole population (F5). *Command:* `-hf`, `-if`,
and `-ef -es` for the unclassified remainder.

**Remainder Analysis** — `remainder`. *Question:* with the known problem taken out, is
what is left healthy? *Signal:* the timeline before and after the exclusion, rescaled.
*Reading:* removing a dominant contributor lets the shape it was flattening become
readable — measured, two buckets that both drew a full-width bar separate to 17 and 13
blocks once the endpoint accounting for 40% of the lines is dropped (F15).
*Falsifier:* the exclusion removes that traffic from every total and rate as well, so
the remainder's figures are not the system's. *Command:* `-e <regex>`.

**Attribute Surfacing** — `attribute-surfacing`. *Question:* which user, session or
query string inside this one call is producing the errors, the volume or the slow
requests? *Signal:* one consolidated message row separating into a row per attribute
value. *Reading:* consolidation is what made the population readable; once a call is
isolated it is what hides the answer, and surfacing reverses it so the aggregation
happens per value (F14). *Falsifier:* applied before a call is isolated there is too
much noise in the view to read. *Command:* `-i <api>` with `-xu`, `-xs` or `-xqs`.

### Shape — group page `shape`

The grouping: tails and modality. The whole-population views cannot show modality —
across hundreds of thousands of requests the gaps fill in and there is no telling
whether what peeks out belongs to one call or to the time range (F17). Every technique
here therefore enters through Rank then Isolate. *See also* points at Population.

**Tail Excursion vs. Distribution Shift** — `tail-excursion`. *Question:* did a few
requests become very slow, or did everything become slower? *Signal:* the isolated
candidate's histogram with its percentile ticks. *Reading:* high kurtosis with an
unremarkable `p50` and `p90` is a small population suffering outliers concentrated in
the tail; low kurtosis with a slow `p50` is uniform slowness affecting everyone (F18).
*Falsifier:* the two are indistinguishable in `p50`/`p90` alone, so a reading taken
without the shape metric is not this technique. *Command:* `-so kurtosis -n 20`, then
`-i` and `-hg duration`.

**Bimodal Split** — `bimodal-split`. *Question:* is this one behaviour or two mashed
together? *Signal:* the isolated candidate's histogram showing two peaks with a valley
where the mean sits. *Reading:* above 0.555 is suspect multimodal, approaching 1.0
strongly so (F18). *Falsifier:* below about a hundred observations noise alone clears
the threshold, and very unequal modes can stay under it while the distribution is
genuinely bimodal (F18). *Command:* `-so bimodality_coef -n 20`, then `-i` and
`-hg duration`.

**Shape Comparison** — `shape-comparison`. *Question:* does this one thing have the
same shape as the population, or its own? *Signal:* the histogram's two overlaid
series with its two percentile rows — the population's and the highlighted subset's.
*Reading:* measured on an access log, a highlighted endpoint reads `p50 1ms`,
`p95 2ms`, `p99 3ms` as one tight column while the population reads `p50 2ms`,
`p95 308.6ms`, `p99 1s` across three decades (F19); the heatmap answers whether that
relationship holds across time buckets. *Falsifier:* the comparison is against the
population *including* the highlighted subset, so a dominant subset is partly
comparing against itself. *Command:* `-h <regex> -hg duration`, then `-hm duration`.

**Timeout Clustering** — `timeout-clustering`. *Question:* is something being killed
at a ceiling? *Signal:* the isolated candidate's histogram with a pile at a fixed
value rather than a tail. *Reading:* latency is naturally right-skewed, so near-zero
or negative skewness on a slow call is the signature of a cap — requests that should
run long are being cut off and accumulating at the limit (F18). *Falsifier:* a
naturally bounded operation is left-skewed without any timeout involved. *Command:*
`-so skewness -sa -n 20`, then `-i` and `-hg duration`.

### Comparison — group page `comparison`

The grouping: setting one body of data against another, whether two periods or two
corpora. *See also* points at Time.

**Period-over-Period Comparison** — `period-over-period`. *Question:* is this period
normal, and has behaviour changed since the baseline? *Signal:* several periods folded
onto one axis. *Reading:* two uses. Normalising — the period in question may be a poor
example of representative behaviour, and folding several together broadens the sample,
smooths one-off spikes and yields a generic profile; it is not good for finding
specific things. Comparing — a baseline corpus and a current one merged into one run
and folded by period align on the same times, so the analyst can see whether the
high-load and error periods line up or amplify (F8). *Falsifier:* the two corpora
cannot yet be told apart within the run, so the comparison takes a couple of
executions and is read by inference across them (F9, #534); and across mixed time
bases the alignment fails silently (#155). *Command:* `-pr week` over the merged
inputs.

**Status Composition Over Time** — `status-composition`. *Question:* is the mix
changing while the volume holds? *Signal:* the per-bucket legend composition beside
the success and failure percentage columns. *Reading:* 2xx giving way to 4xx at
constant volume is a different event from 5xx appearing on top of unchanged 2xx, and a
single failure percentage collapses both; the shortened totals are what make rows
comparable down the column, and a highlight splits each bucket's composition so one
call's statuses sit beside the population's — measured, a bucket whose every 5xx
belonged to the highlighted call (F20). *Falsifier:* the percentages are withheld when
the classified pair is not the whole population, and the counts are shown instead
(F5). *Command:* `-h <regex>` with the classification columns shown.

### Load — group page `load`

The grouping: how much was happening at once. Concurrency is one reading of a
timeline column, not the whole of it (F21, D7). *See also* points at Time.

**Load Over Time** — `load-over-time`. *Question:* how much was in flight, and did it
hit a ceiling? *Signal:* a bar-chart column of the distinct count per time bucket.
*Reading:* distinct sessions per bucket and distinct users per bucket are load
measures that appear on their own when the log carries the field; active threads in a
pool set against the request count says whether the pool is sized right, and a count
sitting at its maximum before throughput stops is the bottleneck (F21). *Falsifier:*
a distinct count is only a concurrency measure where the attribute is held for the
duration of the work. *Command:* `-tpas`, or `-tpa <pool>`.

**Custom Metric Tracking** — `custom-metric`. *Question:* what does a value the log
already reports look like over time? *Signal:* the analyst's own metric drawn as a
bar-chart column beside the others. *Reading:* any token or number the line carries
can be extracted under an aggregation function and graphed per bucket; the worked case
is a queue depth read from monitoring lines whose payload is a run of name-and-value
pairs, turning them into a queue observation over time (F21). *Falsifier:* a metric
whose spec matches nothing is reported after the read, and a value that is not
reported on every line is a sample, not a series. *Command:* `-udm` with the metric
spec.

### Correlation — group page `correlation`

The grouping: relating the same system's logs to each other. *See also* points at
Population.

**Cross-Log Correlation** — `cross-log-correlation`. *Question:* which of these logs
exhibits this condition? *Signal:* the marker column in the run summary's file list —
the check where a file contributed included lines, the highlight marker where it
matched the highlight criteria, and the cross where it contributed none (F3).
*Reading:* the same system's logs are separated by physical node, application
instance or date, so a yes or no per file is a statement about a node, an instance or
a day. Every include, exclude and highlight criterion drives the markers, not only a
text pattern: a duration threshold answers which files carried requests over a
minute, a failure filter reduces the run to the files that contain failures, and under
`-r` the answer names a folder as readily as a file (F22). *Falsifier:* a cross can
mean the file holds no such line or that filtering removed it, which are different
findings; and across mixed time bases the correlation fails silently (#155).
*Command:* `-hdmin <ms>` or `-if` over the file set, with `-r` for a tree.

## Planning walkthrough

| Phase | State |
|---|---|
| 1. Anatomy contract | Closed — D1, D2, D3 |
| 2. Interview, group by group | Closed — F7 to F22 across all six groups; roster changes D4 to D8 |
| 3. Content spec | Closed — one block per topic under *Content specification* |
| 4. Acceptance criteria and harness plan | Closed — R1 to R11, AC1 to AC12, D9 |
| 5. Delivery shape | Closed — D11, three drops |

Specification complete. All three drops implemented.

## Implementation

| Drop | State |
|---|---|
| 1 | Landed — the fourth category, the six group pages, the per-category introductions, Cross-Log Correlation |
| 2 | Landed — Time (3 techniques) and Population (7) |
| 3 | Landed — Shape (4), Comparison (2) and Load (2) |

Twenty-five topics reachable and listed; nineteen techniques and six group
pages. Every acceptance criterion from AC1 to AC11 is asserted by
`tests/validate-explain.sh`, which grew from 154 to 662 assertions across
nine new scenarios. AC12 stands on the compensating practice D9 settles:
every signal was produced by running that technique's own worked command
against a real log and matching the page to what came back.

Three findings the implementation added to the record:

- **F23 — the group page needed its own introduction.** R6 was written
  against the per-topic sentence that misdescribed every non-statistic
  topic. A per-category sentence fixes it for the technique leaves, but a
  group page is not a technique, and being introduced as one is the same
  defect in a smaller form. Group pages take a fourth sentence of their own.
- **F24 — the group table's row count is read from the registry, not
  declared in the harness.** A hardcoded count per group cannot detect the
  failure it exists to catch: a technique added to a group's roster but
  never given a row on its page. The harness reads the count from the
  registry the tool prints, and a probe adding a technique without a row
  now fails as it should.
- **F25 — no page needs the `pre` exemption AC5 grants it.** The rendered
  examples the heatmap and histogram pages carry run to 89 and 90 columns,
  and AC5 exempts verbatim `pre` blocks for that reason. Every one of the
  twenty-five new pages renders with no line over the terminal width at 80,
  120 and 200, generated signals included, so the exemption is unused by
  this work rather than relied on.

### Completion gate

Run on the commit being merged, with `$version_number` restored to
`0.18.0` first.

- **Full harness suite:** all 36 `tests/validate-*.sh` exit 0, each with a
  summary line showing assertions ran. No failures.
- **Before/after benchmark**, same machine, same session,
  `single-day-access-log-standard`: total time 9.1 s → 8.8 s (-3.0%),
  peak RSS 151.0 MB → 152.4 MB (+0.9%), lines read and included identical.
  Both inside the 5% threshold; the memory difference is the content strings
  the registry now holds. The before capture was taken from the base commit
  in a worktree; both result files were deleted afterwards.

## Issues filed from this work

All informational, none a gate on this issue.

| Issue | What it is | Where it touches this work |
|---|---|---|
| #534 | Highlight the lines contributed by a specific input file | Period-over-Period Comparison's before-and-after use is roundabout without it (F9) |
| #535 | Research: normalised message and error rates diverge at fine bucket widths | Resolution Zoom teaches the rates as the pair to watch across a zoom (F11) |
| #536 | Expose the thread name as an attribute | Attribute Isolation cannot address the thread until it lands (F16) |
| #537 | Expose the access-log remote host as an attribute | Attribute Isolation cannot address the caller until it lands (F16) |
