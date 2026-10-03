# #652 — The load-over-time explanation reads a thread pool's size as saturation

Issue #652 (Correct the load-over-time explanation, which reads a thread pool's
size as saturation). Owning record for the surface:
`features/504-explain-technique-topics.md` (the `--explain` technique family),
§ Load group content specification, F21 (the Concurrency technique is load over
time, and thread pools are one instance of it) and D7 (the Concurrency group
becomes Load, with two techniques), amended by this issue. Target: the 0.18.6 patch
release, forward-ported to release/0.19.0, which carries the same content (F10).

## Motivating consumer

An analyst holding an access log that carries thread names, asking one of two
questions: *is this pool too small*, or *did this server stall*. They read
`ltl --explain load-over-time` in the terminal, or the *Load Over Time* section of
the wiki's Analysis Techniques Reference, to learn how to read the thread-pool
column that `-tpas` or `-tpa` adds to the timeline. What they decide from it is
whether to grow the pool or go looking for whatever is holding its threads.

Today the page teaches them that a count sitting at the pool's size is a
bottleneck. On any busy server, at an hour-wide bucket or at the default width
(10 to 120 minutes, by terminal height), the count sits at the pool's size in every
bucket, busy or quiet (F2), so the page turns every healthy server into a saturated
one. It also leaves out the signal a real stall gives, which is the count *falling*
while requests keep arriving (F5).

## Requirement

From the issue, in its terms:

- Rewrite the example and its reading. At wide buckets the column shows the pool's
  size. Concurrency is read from the duration column (summed duration ÷ bucket
  length). Saturation is read from a thread count that falls below what the request
  count implies, with the duration surge where the held requests finish.
- Consider a better example: a real partial stall on another server of the same
  deployment.
- Possibly: an expected-thread-count reference (from the request count and the
  observed pool size) beside the column, so a shortfall is visible.

## Findings

Measured on release/0.18.6 (`c56ae7b`), on two days of a web application access
log in the thread-session shape (fractional millisecond duration, thread name and
session on every line), each day from a different server of the same deployment:
the day the current page quotes (the *example day*) and a day carrying a partial
stall on another server (the *stall day*). Every figure below was read from a
captured STATS CSV or rendered timeline (`-n 0 -tpas -du ms -o -V`, at `-bs 1h`,
`5`, `10` and `1`), or from a read-only pass over the log lines where a figure
needs each request's start time.

### F1 — what the column counts

`calculate_all_statistics()` sets each bucket's pool figure to the number of
distinct thread names of that pool that wrote at least one line in the bucket:

```perl
$log_stats{$bucket}{$threadpool} = scalar keys %{$log_threadpools{$bucket}{$threadpool}{plain}};
```

`read_and_process_logs()` fills it per line
(`$log_threadpools{$bucket}{$threadpool}{plain}{$thread} += 1;`), the pool being
the thread name less its trailing number (`( $threadpool ) = $thread =~ /(.*)-\d+$/;`).

A web server writes an access-log line when the request finishes. A thread held
by a request that has not finished writes nothing, so it is absent from every
bucket until the one where its request completes. On the stall day's log, 0 of
413,541 lines are out of timestamp order, so the timestamp marks completion in
this log family: a request that ran for sixteen minutes is stamped where it ended.

### F2 — at wide buckets the column is the pool's size

Share of buckets whose count reached the pool's size (182) on the example day, by
bucket width:

| Bucket width | Buckets | Lowest count | Median count | At pool size | Median requests per bucket |
|---|---:|---:|---:|---:|---:|
| 1 minute | 1,440 | 19 | 146.5 | under 1% | 292 |
| 5 minutes | 288 | 112 | 182 | 68% | 1,758 |
| 10 minutes | 144 | 167 | 182 | 85% | 3,543 |
| 1 hour | 24 | 182 | 182 | 100% | 21,612 |

At one hour the count is 182 from 00:00 to 14:00 and 183 from 15:00 to 23:00,
whether the hour carried 4,971 requests (03:00) or 45,527 (16:00). The count
reaches the pool's size once a bucket carries several times as many requests as
the pool has threads, which on a busy server is every bucket from a few minutes up.

The example's "throughput falls from 706 a minute to 537" is the day's ordinary
curve: the same pool count (183) carries 758.8 a minute at 16:00.

### F3 — concurrency is in the duration column

Summed duration ÷ bucket length is the average number of requests in flight over
the bucket (Little's Law). On the example day, hourly:

| Hour | Requests | Summed duration | In flight, on average | Pool column |
|---|---:|---:|---:|---:|
| 02:00 | 5,826 | 9,351,842 ms | 2.6 | 182 |
| 03:00 | 4,971 | 9,455,914 ms | 2.6 | 182 |
| 10:00 | 42,362 | 17,315,088 ms | 4.8 | 182 |
| 16:00 | 45,527 | 16,077,994 ms | 4.5 | 183 |

The rendered duration column reads this directly at an hour-wide bucket: `4.8h` of
work in an hour is about five requests in flight, against 182 threads. Across the
day the figure ranges from 2.5 to 4.8.

### F4 — at one-minute buckets the count follows the request count

If each request takes a random free thread, a bucket of *k* requests on a pool of
*N* touches on average N(1 − e^(−k/N)) distinct threads. Observed minus that
expectation, every one-minute bucket of the day:

| Day | Pool size N | Median | 5th percentile | 95th percentile | Largest shortfall |
|---|---:|---:|---:|---:|---:|
| Example day | 182 | +0.17 | −4.7 | +5.9 | −11.4 |
| Stall day | 196 | +1.04 | −5.1 | +7.5 | −63.5 (inside the stall) |

N is the largest one-minute count of the day; on both days it equals the distinct
threads of the pool over the whole day (183 and 196, within one). The model holds
only with N known. A pool grows under load and retires idle threads, and retired
threads return under new names, so the names seen over a day can exceed the live
pool at any instant and the live pool in a quiet hour is smaller than the ceiling.
The model's drift between the two days (+0.17 against +1.04) is that effect. It is
a finding about the column's behaviour, not a figure the tool can print (D4).

### F5 — a real stall reads as a shortfall, then a duration surge

The stall day, one-minute buckets, 21:38 to 21:57. *Held* is the number of distinct
threads whose request started before the minute and finished after it,
reconstructed from each line's end time less its duration.

| Minute | Requests | Pool column | Expected | Shortfall | Held | Summed duration (rendered) |
|---|---:|---:|---:|---:|---:|---:|
| 21:39 | 945 | 189 | 194 | 5 | 0 | 2.8m |
| 21:41 | 678 | 175 | 190 | 15 | 13 | 4m |
| 21:44 | 495 | 155 | 180 | 25 | 26 | 3.2m |
| 21:48 | 906 | 156 | 194 | 38 | 35 | 2.5m |
| 21:50 | 1,054 | 149 | 195 | 46 | 41 | 5.2m |
| 21:52 | 561 | 134 | 185 | 51 | 53 | 3.3m |
| 21:53 | 700 | 127 | 190 | 63 | 62 | 2.5m |
| 21:54 | 373 | 107 | 167 | 60 | 76 | 2m |
| 21:55 | 787 | 159 | 192 | 33 | 27 | 7.6h |
| 21:56 | 783 | 194 | 192 | −2 | 0 | 3.5h |
| 21:57 | 102 | 84 | 80 | −4 | 0 | 1.4m |

The shortfall tracks the held threads minute by minute. Requests keep arriving
throughout (295 to 1,054 a minute between 21:40 and 21:54), carried by the threads
still free. Nothing in the duration column marks the stall until it ends: 84
requests of a minute or longer complete in 21:55 and 21:56, the longest 991 seconds,
which started at about 21:38, where the count began to fall.

The surge is not concurrency. 7.6 hours finishing in one minute is 453 "in flight"
by summed duration ÷ bucket length, against a pool of 196: a held request's whole
duration lands in the bucket where it finishes. Summed duration ÷ bucket length is
an in-flight average only where requests are short against the bucket.

### F6 — the example does not draw what the tool draws

`ltl` renders the pool count as a column in each timeline row, after the duration,
bytes and sessions columns. The example's generator in the `## SUBS ##` explain
section prints the rows through `explain_timeline_rows()` (timestamp, legend,
error-and-message rate, occurrences bar, and nothing after it) and then a separate
line that the tool never draws:

```perl
$out .= "\n" . ' ' x 5 . $colors{'bright-black'} . 'threads in pool, per bucket:' . $colors{'NC'}
      . '   ' . $colors{'bright-yellow'} . '182   182   182' . $colors{'NC'} . "\n";
```

`explain_timeline_rows()` has no way to add the duration or a pool column, so the
reading the issue asks for (duration beside the count) cannot be drawn with it as
it stands.

### F7 — the worked commands read the pool's size

The page's commands are `ltl -tpas access.log`, `ltl -tpa "https-jsse-nio" access.log`
and `ltl -tpas -bs 10 access.log  # finer, to see a ceiling being reached`. The first
two run at the default bucket width, which `adapt_to_terminal_settings()` sets to
120, 90, 60, 30 or 10 minutes by terminal height. At 10 minutes 85% of the example
day's buckets already read the pool's size (F2), so the third command shows the
pool's size, not a ceiling being reached. The width where the count carries load
is about a minute.

### F8 — the page is wider than 80 columns at `--terminal-width 80`

Rendered at width 80, the signal rows are 86 to 91 columns and the third command
line is 90. Both are verbatim `pre` blocks, which the width assertion exempts, so
`tests/validate-explain.sh` passes; but F25 in the owning record ("no page needs the
`pre` exemption") is not true of this page. A signal that adds the duration and pool
columns will be wider still.

### F9 — the same reading is written in four other places

- The page's one-line question, *How much was in flight, and did it hit a ceiling?*,
  in the technique summary table, the Load group page's table, the page itself and
  the mirror. The question stands under the new reading; the answer changes.
- `docs/explain/techniques.md` § Load Over Time: the signal sentence ("a thread pool
  pinned at its ceiling while throughput falls away underneath it"), the reading
  paragraph and the third command, word for word as the terminal page.
- `docs/usage.md` § Thread Pool Activity: "This reveals infrastructure-level
  behavior — thread exhaustion, pool saturation, and correlation between thread
  utilization and latency spikes." The issue does not name it (D5 brings it in).
- The owning record: D7's technique row ("read for pool sizing when the count sits
  at its ceiling and circulates, and for the bottleneck where it reaches maximum and
  throughput stops"), F21, and the Load content specification.

### F10 — release/0.19.0 carries the same content

The load-over-time example block, its reading string, its command block,
`explain_timeline_rows()` and the mirror section are identical on
`origin/release/0.19.0`. The forward-port is a carry of the same change.

## Citation corrections

- The wiki's *Load Over Time* (`Analysis-Techniques-Reference`, synced from
  `docs/explain/techniques.md` by `build/sync-wiki.sh`) carries the reading and its
  numbers but not the rendered rows: `threads in pool, per bucket: 182 182 182` is in
  the terminal page only. The mirror describes the signal in a sentence.
- "At bucket widths of 5 minutes or more the column is the pool's size": on the
  example day, 68% of five-minute buckets and 85% of ten-minute buckets read the
  pool's size; from an hour, all of them. The count reaches the pool's size once a
  bucket carries several times as many requests as the pool has threads (F2).
- "Median deviation about +0.2 threads over a day" is the example day (+0.17 at
  N = 182). The stall day reads +1.04 at N = 196 (F4).
- The stall's request rate is 295 to 1,054 a minute between 21:40 and 21:54, not 400
  to 1,100 (two minutes fall below 400: 295 at 21:43, 373 at 21:54).
- The count returns to 194 in the minute after the surge (21:56); in the surge
  minute itself (21:55) it is 159.
- The issue carries both the `bug` and the `enhancement` label under an
  `Enhancement:` title; release-notes classification follows the label, so one of
  the two decides the section.

All other figures the issue quotes match the captures: the quoted text, the three
example rows, the 02:00, 03:00 and 10:00 hourly figures, the 2.6 and 4.8 averages,
the 189 → 107 fall, and 7.6 hours finishing in 21:55.

## Locked decisions

Decisions of the owning record that govern this surface and stand unchanged:

- **D3 of the explain-topics record (page anatomy)**: a technique page is the
  question, *The signal* as a `pre` block generated in code from the tool's own
  colours, *How to read it* including what falsifies the reading, *Command*,
  *See also*.
- **D9 of the explain-topics record (signal fidelity)**: every signal is produced by
  running the technique's own worked command against a real log and matching the
  page to what came back. Binds the new example's numbers.
- **R5, R10, R12 of the explain-topics record**: the signal is rendered, not
  described; no Perl identifiers, issue numbers or decision labels in the page or
  the mirror; mirror links are written as wiki page names.

Decisions locked for this issue (architect, 2026-10-03):

### D1 — D7's Load Over Time reading is amended

D7 of the explain-topics record read the column "for pool sizing when the count sits
at its ceiling and circulates, and for the bottleneck where it reaches maximum and
throughput stops". F1 and F5 overturn the second half: a held thread writes no line,
so a stall lowers the count. The amended reading, recorded under D7 in that file:
at wide buckets a count at the pool's size is the pool's size, busy or quiet;
concurrency is summed duration divided by bucket width; saturation shows at
one-minute buckets as a count falling below what the request count implies, ending
in a duration surge where the held requests finish.

### D2 — the page carries both example blocks

The signal is two captioned blocks, in the form the period-over-period and
tail-excursion pages already use: hourly rows of the example day (03:00, 10:00,
16:00) showing the pool's size whatever the load, then one-minute rows of the stall
day (21:50 to 21:56) showing the count falling and the release. Hourly only never
shows a stall; stall only drops the lesson the current page gets wrong.

### D3 — the pool count is drawn in the row by the renderer

`explain_timeline_rows()` gains optional trailing columns, duration and pool, that
existing callers leave empty and render unchanged. The Load Over Time rows then
look like a run's rows and every number equals the worked command's output (D9 of
the explain-topics record). The separate "threads in pool, per bucket" line goes.

### D4 — no expected-thread-count reference, in this issue or later

The expectation N(1 − e^(−k/N)) needs the live pool size, which the log does not
reliably give (F4): a column printing it would present an assumption as a fact.
Neither the column nor the formula nor a rule of thumb derived from it appears on
the page. The page states the comparison in plain words: against the count the
same request rate produced in the minutes before. The signal the analyst wants,
the stall itself, is the subject of #664 (detect a stall: requests held across
buckets and released together), a sub-issue of #657 (rebuild request concurrency
from each line's timestamp and duration), filed from this investigation. The page
may point at that reading once it exists; until then it teaches the shape.

### D5 — the user guide's sentence is corrected in the same change

`docs/usage.md` § Thread Pool Activity drops "thread exhaustion, pool saturation" in
favour of what the column shows, so the user guide and the explanation agree.

### D6 — the forward-port is a carry

The same change is applied to release/0.19.0 after the patch merges (F10).

## Contracts

What the reader of the terminal page and of the mirror observes after the change.

- **C1 — Pool size at wide buckets.** The page states that once a bucket carries
  several times as many requests as the pool has threads, every thread finishes at
  least one request in it and the column reads the pool's size, busy or quiet; at
  an hour, and at the default width on a busy server, the column is a reading of
  the pool's size, which is what pool sizing needs, and not a reading of load.
- **C2 — Concurrency from the duration.** The page states that summed duration ÷
  bucket width is the average number of requests in flight, with the example's own
  figure (about five in flight against a pool of 182 at the busiest hour).
- **C3 — Saturation as a shortfall.** The page states that at one-minute buckets
  the count follows the request count, that a count falling below what the same
  request rate produced in the minutes before, while requests keep arriving, is
  threads held by requests that have not finished, and that the stall ends in a
  duration surge in the bucket where the held requests finish.
- **C4 — What falsifies it.** The page states: the count is of threads that
  finished a request in the bucket, so a held thread is invisible until it
  finishes; the duration surge is a release, not concurrency, and can exceed the
  pool's size; where a log stamps a request with its start rather than its end, a
  held request's duration lands in the bucket where it began. The existing
  session and thread-reuse falsifier stays.
- **C5 — The signal is what the tool draws.** Each example row carries the pool
  count in the row, beside the occurrences and the duration, as a run draws it; no
  separate line the tool never prints. The numbers on the page are those a run of
  the page's worked command produces on a real log of the thread-session access-log
  family.
- **C6 — The worked commands match the reading.** One command reads the pool's size
  and the duration at an hour-wide bucket; one narrows to a window at a one-minute
  bucket to see a shortfall. No command claims a ceiling is seen at ten minutes.
- **C7 — Terminal page, mirror and user guide agree.** `docs/explain/techniques.md`
  § Load Over Time carries the same reading, numbers and commands, and
  `docs/usage.md` § Thread Pool Activity no longer claims the column reveals
  saturation; the wiki receives both at the next sync.
- **C8 — Release/0.19.0 carries the same change.**

### Content specification

*Signal*, two blocks (D2):

1. *A day at one-hour buckets — the pool's size, whatever the load:* three hourly
   rows of the example day (03:00, 10:00, 16:00: 82.8, 706 and 758.8 a minute;
   2.6h, 4.8h and 4.5h of duration; pool 182, 182, 183).
2. *A stall at one-minute buckets — threads held, then released:* consecutive rows
   21:50 to 21:56 of the stall day (requests 1,054 → 373 → 787 → 783; pool 149, 141,
   134, 127, 107, 159, 194; duration 5.2m … 2m, then 7.6h and 3.5h).

*Reading*, in order: what a distinct count measures; sessions and users (unchanged);
the pool column at wide buckets is the pool's size (C1); concurrency from the
duration (C2); the shortfall and the surge at one-minute buckets, with the stall's
numbers, compared against the minutes before (C3, D4); what falsifies it (C4).

*Command*: `ltl -tpas -bs 1h access.log` (the pool's size and the duration);
`ltl -tpa "https-jsse-nio" access.log` (one pool); `ltl -tpas -bs 1 -st 21:30 -et 22:00 access.log`
(a window at a minute, to see a shortfall).

## Acceptance criteria

Owning harness: `tests/validate-explain.sh`. A new scenario is added under the
`documented:` prefix the cross-log scenario established.

- [ ] **AC1 (C1–C4)** — Neither `ltl --explain load-over-time` nor the mirror carries
      the saturation reading: no "pinned at its ceiling", "clearest capacity signal"
      or "queue forming behind a limit". *Assertable:* new scenario
      `documented:load-over-time-reading`, `assert_no_line` over the stripped page and
      over `docs/explain/techniques.md`.
- [ ] **AC2 (C1, C2, C3)** — The page and the mirror each state the three readings:
      the pool's size at wide buckets, concurrency as summed duration over bucket
      width, saturation as a count below what the request rate produced before.
      *Assertable:* the same scenario, one `assert_line` per reading on a phrase fixed
      when the content is written. Cost: a phrase assertion breaks on rewording; the
      cross-log scenario accepts the same cost.
- [ ] **AC3 (C5, D3)** — Every row of the signal carries the pool count in the row,
      and the page has no line the tool never draws. *Unassertable, visual:* the page
      set beside the timeline its worked command draws on the real log at the same
      width; the existing `technique-signal:load-over-time` scenario keeps guarding
      that the colour escapes survive.
- [ ] **AC4 (C5)** — Every number in the signal and in the reading equals the
      value a run of the page's worked command produces on the source log, recorded
      in this document with the command. *Unassertable, visual:* recorded under
      *Implementation*.
- [ ] **AC5 (C6)** — The command block carries an hour-wide command and a one-minute
      windowed command, and no command claims a ceiling at ten minutes.
      *Assertable:* the `documented:load-over-time-reading` scenario, on the page
      and the mirror.
- [ ] **AC6 (C7, D5)** — `docs/usage.md` § Thread Pool Activity no longer carries
      "thread exhaustion, pool saturation". *Assertable:* the same scenario,
      `assert_no_line` over `docs/usage.md`.
- [ ] **AC7 (R10)** — No internals in the page or the mirror. *Assertable:* existing
      scenarios `no-internals:load-over-time` and `mirror:techniques`.
- [ ] **AC8 (D3 of the explain-topics record)** — The page keeps its anatomy, and
      every other technique page renders unchanged after the renderer change.
      *Assertable:* existing `technique-page-anatomy`, `all-topics-render`, `reflow`,
      and `tests/validate-regression.sh`.
- [ ] **AC9 (C8)** — On release/0.19.0 after the carry, the same scenarios pass.
      *Assertable:* `./tests/validate-explain.sh` on that branch.

## Scope of the gate

- **Hot path:** not touched. The change is the explain content (strings and the
  example generator, built once at start-up) and `explain_timeline_rows()`; the
  read loop, the accumulators and the statistics are unchanged.
- **Scope table** (`docs/process/workflow.md` § 3): the diff touches executable
  lines of `ltl`, so the full harness suite and a before/after benchmark
  (`single-day-access-log-standard`, the before captured on the base commit) are
  both required.
- **Harnesses on the surface:** `tests/validate-explain.sh` (`all-topics-render`,
  `reflow`, `technique-page-anatomy`, `technique-signals`, `technique-no-internals`,
  `mirror:techniques`, `wiki-link-form`), extended by `documented:load-over-time-reading`.
  No `-V` section or key changes.
- **Release note:** one bullet: *Correct `--explain load-over-time`: a thread pool
  at its size is the pool's size; saturation shows as a count below demand.*

## Implementation

### What was built

- **The renderer (D3).** `explain_timeline_rows()` takes an optional seventh row
  element: a list of trailing columns, each a column colour, a cell width, the value
  and the filled cells. When a row carries them, the bar area is padded to its 20
  cells, as a run pads it, and each column follows two spaces later, drawn the way
  `print_bar_graph()` draws a proportional column: the value preceded by one space,
  the filled cells on the column's background, the rest in its foreground. The
  colours are read from the run's own column colour table (`%column_color_lookup`):
  yellow for duration, the colour the duration column always takes, and magenta for
  the pool, the colour a thread-pool column takes on a log that also carries
  sessions. A row without the element renders exactly as before.
- **The signal (D2, C5).** The Load Over Time example is two captioned blocks, in
  the period-over-period form: three hourly rows of the example day and seven
  one-minute rows of the stall day, each row carrying its legend, rate, occurrences
  bar, duration and pool count. The separate `threads in pool, per bucket` line is
  gone. Cell widths are those a run draws at `--terminal-width 120` (duration 8,
  pool 7).
- **The reading (C1 to C4, D4).** Rewritten in the order the content specification
  gives. The comparison for a shortfall is stated against the count the same
  request rate produced in the minutes before, with the page's own rows (700
  requests from 127 threads at 21:53 against 694 from 141 at 21:51, and 783 from 194
  at 21:56); no expected count, formula or rule of thumb appears.
- **The commands (C6).** `ltl -tpas -bs 1h access.log`, `ltl -tpa "https-jsse-nio" access.log`
  and `ltl -tpas -bs 1 -st 21:30 -et 22:00 access.log`, the last with its comment on
  the following line, as other pages do, so the block fits 80 columns.
- **The mirror (C7).** `docs/explain/techniques.md` § Load Over Time carries the
  same reading, split into paragraphs, the same commands, and a signal sentence
  carrying the rows' numbers.
- **The user guide (D5).** `docs/usage.md` § Thread Pool Activity says what the
  column counts, that it reads the pool's size at wide buckets, that a shortfall at
  one-minute buckets is held threads, that in-flight work is read from the duration
  column, and points at `ltl --explain load-over-time`.
- **The owning record.** The Load Over Time entry of the Load content specification
  in `features/504-explain-technique-topics.md` carries the amended reading (D7's
  amendment was recorded there with the decisions), and F25 there notes this page's
  wider signal.
- **The harness.** `tests/validate-explain.sh` gains `documented:load-over-time-reading`.

### Source of every number (AC4)

Both worked commands were run on the source logs with `--disable-progress -V` and
`-n 0 -o` for the STATS CSV, at `--terminal-width 120` and `200` for the rendered
rows:

- `ltl -tpas -bs 1h` on the example day. Hourly rows from the CSV: 03:00, 4,971
  requests (4xx 8, 3xx 56, 2xx 4,907), 82.8 a minute, error rate 0.1, summed duration
  9,455,914 ms (rendered `2.6h`), pool 182; 10:00, 42,362 (5xx 17, 4xx 118, 3xx 197,
  2xx 42,030), 706 a minute, error rate 2.2, 17,315,088 ms (`4.8h`, the day's largest),
  pool 182; 16:00, 45,527 (4xx 20, 3xx 130, 2xx 45,377, the day's largest), 758.8 a
  minute, error rate 0.3, 16,077,994 ms (`4.5h`), pool 183. The day's largest pool
  count is 183.
- `ltl -tpas -bs 1 -st 21:30 -et 22:00` on the stall day. One-minute rows from the
  CSV, requests / 5xx / 4xx / 3xx / 2xx / error rate / summed duration / pool:
  21:50 1,054 / 15 / 3 / 5 / 1,031 / 18 / 314,260 ms (`5.2m`) / 149;
  21:51 694 / 7 / 4 / 3 / 680 / 11 / 198,375 (`3.3m`) / 141;
  21:52 561 / 7 / 0 / 3 / 551 / 7 / 199,261 (`3.3m`) / 134;
  21:53 700 / 4 / 2 / 5 / 689 / 6 / 147,892 (`2.5m`) / 127;
  21:54 373 / 6 / 1 / 3 / 363 / 7 / 120,359 (`2m`) / 107;
  21:55 787 / 9 / 2 / 3 / 773 / 11 / 27,183,226 (`7.6h`, the window's largest) / 159;
  21:56 783 / 0 / 0 / 4 / 779 / 0 / 12,502,884 (`3.5h`) / 194 (the window's largest).
  The window's largest request count is 1,054.
- Legends and rates are as the run draws them (`2xx: 42k`, `18:1.1k/m`). Bar cells are
  computed as the run computes them, the bucket's share of the view's largest request
  count over the 20 cells, rounded; duration and pool cells are the run's truncated
  share of the view's largest value over the cell width. Hourly bars 2, 18, 20;
  duration cells 4, 8, 7; pool cells 6, 6, 7. Stall bars 20, 13, 10, 13, 7, 15, 15;
  duration cells 0 for the five minute-valued rows, 8 and 3; pool cells 5, 5, 4, 4,
  3, 5, 7.
- The reading's figures are the same rows: 182 at 03:00 with 82.8 a minute and at
  10:00 with 706; 4.8 hours at 10:00, 4.81 in flight on average, against 182; the
  fall 149, 141, 134, 127, 107 at 1,054 to 373 a minute; 700 from 127 at 21:53 against
  694 from 141 at 21:51; 7.6 and 3.5 hours; 783 from 194 at 21:56.

### Rendered checks (AC3)

The page at `--terminal-width 120` was set beside both runs at the same width. Every
row carries the same timestamp, legend, rate, duration and pool count as the run's
row; the occurrences bar has the same proportion. The run draws columns the page
leaves out (the success percentage, and on the stall day bytes and sessions), and its
bar area is sized to the terminal's width where the page's is fixed at 20 cells. The colour escapes of a page
row and a run row are the same sequence: the column's background over the filled
cells, then its foreground. No line of the page is one the tool does not draw.

The signal rows are 110 columns (111 for the 10:00 row, whose legend fills its
34-cell field), against 86 to 91 before. They are verbatim `pre` blocks, exempt from
the width assertion as before; the command block now fits 80 columns, against 90
before.

### Acceptance criteria

- **AC1, AC2, AC5, AC6** — `./tests/validate-explain.sh --scenario documented:load-over-time-reading`:
  20 passed, 0 failed. Run with the same harness against the base commit's `ltl`,
  mirror and user guide: 1 passed (the exit code), 19 failed, so each assertion fails
  on the content it guards against. The phrases are matched over the page with its
  reflow joined, so a phrase broken across two terminal lines still matches; the
  mirror is cut to its own section so a phrase elsewhere cannot satisfy it.
- **AC3** — visual, recorded above.
- **AC4** — recorded above, every figure read from the captured CSVs and renders.
- **AC7** — `no-internals:load-over-time` 4 passed; `mirror:techniques` 27 passed.
- **AC8** — `technique-page-anatomy` 114 passed, `all-topics-render` 52, `reflow` 6,
  `technique-signals` 19 (the load-over-time page carries 294 escapes),
  `technique-topics-render` 100, `wiki-link-form` 5. Every one of the 38 other
  `--explain` topics was captured raw at widths 80, 120 and 200 before and after the
  change: all 114 captures are byte-identical; only the three load-over-time captures
  differ. `tests/validate-regression.sh` runs at the completion gate.
- **AC9** — the forward-port to release/0.19.0 follows the merge (D6).

### Found and left

`docs/purpose.md` (*Explore related signals*: "see if thread exhaustion correlates
with the latency spike") and `README.md` ("check thread pool saturation") name
saturation and exhaustion as things thread-pool tracking helps investigate. Neither
claims the count at the pool's size is saturation, so neither contradicts the
amended reading, and neither is among the places F9 lists; they are unchanged.
