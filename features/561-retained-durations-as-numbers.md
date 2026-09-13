# 561 — Retaining durations as numbers rather than as the strings the log carried

Issue #561 (retained durations keep a string buffer no consumer reads, doubling
the two duration-sample stores).

This document owns the specification, the acceptance criteria and the
implementation record for normalising the retained duration to a number at the
five sites where the raw statistics model copies it.

It continues #528 (a transform that assigns arithmetic into a shared record
lexical enlarges every duration the raw statistics model retains for the rest of
the run), whose prototype measured this exact candidate. The contract #528
landed — a transform may not leave a shared record lexical holding a value Perl
represents as a double — stands unchanged here and is not reopened.

## Status

**Specification and acceptance criteria written; implementation is blocked on one
architect decision.**

The change itself is five lines and behaves as the prototype measured: the two
duration-sample stores halve, the wall clock does not rise, and every rendered
terminal figure is identical. But a surface the prototype did not exercise does
change: under `-cp full` (`--csv-precision full`) on a format whose durations are
written with fractional milliseconds, the exported percentile and min/max columns
lose the trailing zeros the log line carried — `5.000` is exported as `5`, and
`35.010` as `35.01`. The numbers are equal; the spelling is not.

The issue's second "done when" clause requires every exported figure to be
identical, so this is a stop rather than a judgement to make here. The finding,
the measurement and the decision it needs are under *§ The exported-spelling
finding* below.

## The motivating consumer

**Memory of the two duration-sample stores on large raw-mode runs.**

In its default configuration `ltl` keeps every observed duration as a scalar in
an array so the exact percentiles can be computed at the end of the run: once per
time bucket in `%log_analysis`, and again per message key in `%log_messages`. On
a single-day access log that is hundreds of thousands of scalars in each store.

Each of those scalars is a copy of the shared record lexical `$duration`, and a
Perl copy inherits a body able to carry everything the source carries. The source
carries the string the log line held *and* the integer the index block's
`$fd->{duration_sum} += $duration` read out of it on the same line. So every
retained duration is a 64-byte three-representation body where a 24-byte
integer-only one would serve, because no consumer of either store ever reads the
string: the percentile path sorts numerically and indexes the sorted array, and
the moments path sums and squares.

Measured under #528's prototype on the 761,698-line access log
(`logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt`):
`MEMORY log_analysis` 55,742,644 bytes and `MEMORY log_messages` 57,600,664 in
the baseline against 25,274,724 and 27,132,744 normalised — 40 bytes saved on
each of the 761,698 retained durations in each store, 29.1 MB per store and
58.1 MB across both.

The consumer is therefore anyone running the tool in its default raw mode on a
large file, and the benefit is that the run fits where it previously did not.
The fractional-millisecond shape saves more: its baseline body is 72 bytes, not
64, because the fractional string's numeric read produces a double as well as an
integer, and sixty of the ninety really-big access files are that shape.

## The requirement, transcribed from the issue

Every duration `ltl` retains for the raw statistics model is kept as a number
rather than as the string the log line carried.

The issue's three "done when" clauses, verbatim in substance:

1. The two duration-sample stores use about half the memory they use today on the
   same input, as `-V benchmark-data` reports them.
2. Every figure the tool prints, exports or writes to CSV is identical to today
   on every input, including files with fractional-millisecond durations.
3. Run time is unchanged within the run-to-run spread, measured before and after
   on the same machine.

## The decisions carried over from the prototype's measured result

These are not new decisions. They are what #528's prototype established by
measurement, and this issue implements them rather than revisiting them.

### D1 — The operation is a numeric normalisation at the copy, not a change to the transform or to the data model

Carried from #528's *§ The ceiling on the alternatives*, which measured the two
alternatives against this one.

Normalising in the transform does not work: the retained value must be numeric at
the moment the copy is taken, and the shared lexical is read numerically by the
index block on every line before any retention site sees it, which re-establishes
the string-plus-integer shape whatever the transform left. **The copy is where
the representation is fixed.**

Storing the retained durations in a packed buffer reaches a lower floor than 24
bytes, but it is a data-model change owning the whole percentile and moments
path, and it is the subject of #426 (the per-message statistics store is one hash
per message; the as-built heap layout costs 5x on population traversal, on hold).
The 40-byte saving here is available without touching any consumer.

`int($duration)` is rejected: it buys nothing over the numeric normalisation on
the integer corpus and would truncate a value on the fractional shape, which the
arms are required to render identically.

### D2 — The five retention sites are the whole scope

Enumerated in #528's *§ The retention sites, enumerated*, located here by
grepping the current `read_and_process_logs()` rather than by the prototype's line
numbers. All five are present and unchanged in shape since the prototype ran:

| site | the line as it stands |
|---|---|
| per-bucket durations push | `push @{$log_analysis{$bucket}{durations}}, $duration` (guarded `unless $bucket_stats_capture_mode eq 'bin'`) |
| per-message durations push | `push @{$log_messages{$category}{$log_key}{durations}}, $duration` (guarded `unless $message_stats_capture_mode eq 'bin'`) |
| per-message first-sample store | `$stats_source->{durations} = [$duration] unless $message_stats_capture_mode eq 'bin'` |
| histogram values push | `push @{$histogram_values{duration}}, $duration;` |
| highlighted histogram values push | `push @{$histogram_values_hl{duration}}, $duration if $is_highlighted;` |

Sites 1 and 2 carry the whole retained population on a default run; site 3 fires
once per message key; sites 4 and 5 fire only when a histogram is drawn.

**Explicitly out of scope**, and verified untouched by the change:

- The per-file index block's `$fd->{duration_min}` and `$fd->{duration_max}`
  assignments. These assign `$duration` itself, and it is those assignments that
  put the string spelling into `ltl-index.csv`'s `duration_min` / `duration_max`
  columns. They are not retention sites for the statistics model and the change
  does not touch them: diffed on the fractional fixture, the index CSV's duration
  columns are byte-identical between the two builds.
- The numeric accumulations `$stats_source->{total_duration}`,
  `total_duration_num`, `sum_of_squares`, the per-bucket totals and the per-file
  index accumulators. They are arithmetic, not retained copies.
- The `$bytes` retention site `push @{$histogram_values{bytes}}, $bytes`, which
  #528's D4 recorded as costing nothing to leave alone: `$bytes` is already
  numeric on the paths reaching that push.

### D3 — The integer is already in the lexical, which is why the operation is free

The index block's `$fd->{duration_sum} += $duration` runs for every line with a
defined duration, ahead of the filters and ahead of every retention site. It has
already asked the lexical for its integer by the time any copy is taken. So the
normalisation reads a representation the lexical carries rather than computing a
new one, and what it replaces is the copy of a 64-byte three-representation body
with the construction of a 24-byte integer-only one.

Measured: the median wall clock does not rise. It fell 1.33% on the 761,698-line
corpus with the two arms' ranges overlapping at every stage, reproduced in two
independent staged runs. The defensible statement is that the operation is
**free**, not that it is an optimisation.

### D4 — No existing sub is reused, because none normalises a duration

Checked before writing, per the one-resolution-surface rule. `ltl` has no sub
that normalises a duration's representation. The one sub with an adjacent name,
`normalize` (`sub normalize { $_[0] =~ s/\.0+$//r }`), strips a trailing `.0`
from a **string** for display comparison — a formatting operation in a different
vocabulary, and using it here would reintroduce exactly the string buffer the
issue exists to remove.

The operation is `0 + $duration`, written inline at each site. It is the form the
prototype measured; wrapping it in a sub would add a per-retention sub call to
the hot path, which is the cost D39 of `features/log-format-registry.md` (a
single generated scan sub per scan order, zero per-line sub calls, write-direct
into file-scoped record lexicals) exists to avoid.

## The exported-spelling finding

**This is what blocks implementation, and it is the one thing the prototype's
correctness check could not have caught.**

### What was measured, against what, on what input

Two builds differing by the five lines and nothing else: the committed `ltl` at
`e922403`, and a scratch copy with `0 + $duration` at each of the five sites
(`diff` reports exactly five changed lines; `perl -c` passes on both).

Input: `tests/fixtures/format-detection/access-thread-session.txt`, the committed
12-line fixture of the `access_common_duration_thread_session` shape, whose
durations are written with three fractional decimal places (`5.000`, `8.001`,
`35.010`). That spec declares no duration transform, so the retained value is the
log line's own string.

### What was observed

Under `-cp full` (`--csv-precision full`), the STATS CSV row:

| column | committed | normalised |
|---|---|---|
| `duration_min` | `5.000` | `5` |
| `duration_p1` | `5.000` | `5` |
| `duration_p5` | `5.000` | `5` |
| `duration_p95` | `35.010` | `35.01` |

and in the MESSAGES CSV every retained-value column of a fractional key moves the
same way (`35.010` → `35.01`).

The values are numerically equal. Only the spelling changes, and it changes in one
direction: trailing zeros the log line carried are no longer exported.

**Every other surface checked is identical.** On the same fixture and build pair:

| surface | result |
|---|---|
| rendered terminal output, default | identical except `TOTAL TIME` and `MAXIMUM MEMORY USED` |
| rendered terminal output, `-ms` | identical except `MAXIMUM MEMORY USED` |
| rendered terminal output, `-hg duration` | byte-identical |
| rendered terminal output, `-hm duration` | byte-identical |
| STATS and MESSAGES CSV, `-cp default` | byte-identical |
| STATS and MESSAGES CSV, `-cp 3` and `-cp 6` | byte-identical |
| aggregate YAML export | identical except `total_time` |
| `ltl-index.csv` duration columns | byte-identical (including `duration_min 5.000`) |
| STATS and MESSAGES CSV, `-cp full`, integer-millisecond fixture | byte-identical |

So the drift is confined to one option value (`-cp full`) on formats whose
durations carry fractional decimals. `MAXIMUM MEMORY USED` moving is the saving
itself appearing, not a defect.

### Why the prototype did not see it

#528's prototype compared the arms by dumping every retained value and diffing —
4,052 lines on the integer corpus and 23,990 on the fractional specimen, identical
in both cases. That dump reads each retained scalar in **string context**, and
reading a numeric scalar in string context produces `5` from `0 + "5.000"` in both
arms only because the dump stringified the baseline's value the same way. The
check proved the values equal; it could not prove the exported spellings equal,
because it never exercised the export path that passes a retained scalar through
unformatted.

`-cp full` is that path: `format_csv_value()` returns `$value` unchanged when the
mode is `full`, so the retained scalar's own spelling reaches the file.

### The argument each way, stated in what it means for a user

**For accepting the change.** `-cp full` is documented as "raw precise floats"
(`docs/usage.md`, and `--help`). A trailing zero in `5.000` is not precision — it
is an artefact of how the log line was written, and `5.000` and `5` are the same
number to every consumer that parses the column. Today's output is already
internally inconsistent about it: in the same MESSAGES row, `duration_mean` (a
computed value) exports `35.01` while `duration_p50` (a retained value) exports
`35.010`. The change makes the column self-consistent. Nothing that parses the CSV
numerically is affected.

**Against accepting the change.** It is a user-observable change to an exported
figure on a documented option, and the issue says every exported figure is
identical. A consumer diffing CSVs across versions, or one doing a string
comparison on the column, sees a difference. The issue was filed on the premise —
recorded in `features/528-record-lexical-retained-representation.md` § The
disposition — that the tool would use half the memory "with no change to any
number it prints", and that premise is now known to be narrowly false.

### The decision this needs

Whether the `-cp full` spelling change is acceptable, and if it is, whether it is
a release-note line.

Three dispositions are available, and each is a different piece of work:

| disposition | what it means | cost |
|---|---|---|
| accept | `-cp full` exports `5` where it exported `5.000`, on fractional-duration formats only | the five-line change as specified, plus a release-note line and an acceptance criterion recording the accepted drift |
| preserve | the change lands and `-cp full` keeps today's spellings | a second retained store, or a re-read of the source string, at the sites — which gives back the memory the issue exists to save. Not recommended on the measurement |
| narrow | the change lands only at the sites that cannot reach `-cp full` | sites 4 and 5 (histogram) only, which carry no population on a default run — the saving would be approximately zero. Not recommended |

The recommendation is **accept**, because the saving is 58 MB on a 762,000-line
file and more on the fractional corpus, the affected surface is one option value,
the numbers are unchanged, and the new spelling agrees with what the option
already documents itself as producing. But it is a user-observable export change,
so it is the architect's call rather than one to make inside the implementation.

## Acceptance criteria

Triaged per `docs/test-driven-development.md` before implementation. Criteria are
derived from the issue's three "done when" clauses.

### Assertable

- [ ] **Assertable — clause 1, memory.** A run of
      `./ltl --disable-progress -mem -bs 1440 -oe -V benchmark-data -n 1
      tests/fixtures/tomcat-access-duration-spread.txt` reports a
      `MEMORY log_analysis` row at or below a ceiling derived from the normalised
      representation, and a `MEMORY log_messages` row likewise, both materially
      below today's figures on the same fixture.
      *Method:* a new scenario in `tests/validate-statistics-demand.sh`, following
      the shape #528 landed there (scenario-13, the retained-duration ceiling):
      exact `MEMORY` rows of `-V benchmark-data` rather than the rounded `-mem`
      summary (D5 of #528), a one-sided ceiling because the defect can only make
      the number larger, the fixture's line count asserted beside the threshold so
      a regenerated fixture re-derives the ceiling rather than absorbing it, and a
      missing row failing hard rather than reading as a value under the ceiling.
      The two ceilings are derived by running both builds five times each on the
      pinned fixture and placing each ceiling between the figures, as #528 derived
      its 33,000.
      *Note:* #528's existing scenario-13 ceiling of 33,000 bytes is an upper bound
      on `log_analysis` and this change lowers that row, so that scenario continues
      to pass unchanged; the new scenario asserts the lower figure the saving
      produces, which is what would regress if the normalisation were reverted.
- [ ] **Assertable — clause 2, correctness on the rendered surfaces.**
      `tests/validate-regression.sh` passes with its 74 stored references
      byte-identical, and `tests/validate-statistics.sh` and
      `tests/validate-csv-output.sh` pass.
      *Method:* the completion gate's full suite. The references cover the access,
      heatmap, histogram and highlight duration paths at four terminal widths and
      in both raw and bin capture modes, which is the population of rendered
      figures derived from the retained arrays.
- [ ] **Assertable — clause 2, correctness on the fractional shape.** On
      `tests/fixtures/format-detection/access-thread-session.txt`, the committed
      fractional-millisecond fixture from `docs/test-logs.md`'s family, the
      rendered output and the `-cp default` CSV export are byte-identical between
      the pre-change and post-change builds.
      *Method:* a scenario asserting the rendered figures on that fixture. Measured
      identical on both surfaces during specification.
- [ ] **Assertable — clause 2, the drift that is not identical.** The `-cp full`
      export on a fractional-duration format changes spelling as recorded under
      *§ The exported-spelling finding*.
      *Method:* measured during specification, both builds, recorded above.
      **This criterion currently fails clause 2 as the issue words it**, and is the
      subject of the blocking decision.

### Unassertable

- [ ] **Unassertable, recorded as a known gap.** That the saving holds at the
      761,698-line scale rather than only on a committed fixture. The corpus is
      gitignored and unrecoverable, so no harness can depend on it.
      *What is done instead:* the committed fixture carries the same signal at
      smaller scale and is what the harness asserts; the large-corpus figure is the
      gate's before/after benchmark, whose numbers go in the completion comment.

### Unknown

None. The verification method for every clause was settled by #528's prototype
and by the specification measurements above, which is why no further prototype is
in scope.

## The -V contract touched

**None.** The change reads no `-V` section and adds no key. The new assertions read
`MEMORY log_analysis` and `MEMORY log_messages` of `-V benchmark-data`, rows that
exist today, are produced by `named_structure_sizes()` through
`measure_memory_structures()`, and are gated on `-mem` as every structure row is.
The figures those rows carry change, which is the point of the issue, but the
section, its keys and its gating do not.

## Surfaces touched

| surface | change |
|---|---|
| `ltl`, `read_and_process_logs()` | five lines, one per retention site |
| `tests/validate-statistics-demand.sh` | new scenario asserting the normalised memory figures |
| `features/561-retained-durations-as-numbers.md` | this document |
| `--help`, `docs/usage.md` | none — no option is added or changed |
| `-cp full` exported spelling on fractional formats | changed; the blocking decision |

## Completion gate

Scope per `docs/process/workflow.md` § 3, applied to the diff.

**Full harness suite: required.** The diff touches executable lines of `ltl`, and
it touches `tests/validate-statistics-demand.sh`. Both rows read "required".

**Before/after benchmark: required.** The diff touches executable lines of `ltl`
on the per-line hot path. The gate stage captures `before` on the base commit and
`after` on the commit being merged, on a quiet machine.

**The expectation the benchmark is read against:** the two structure rows fall by
about half; peak memory falls; wall clock is unchanged within the run-to-run
spread, with a small fall inside the noise being the expected direction rather
than a signal. Any metric worse by more than 5% is stop-and-investigate, and on
this change a *rise* in either structure row means the normalisation is not
reaching the retention sites.

**`$version_number`** is stamped `0.18.1-561` on this branch and restored to
`0.18.1` before the gate runs.

## Release note

**Pending the blocking decision.**

If the `-cp full` spelling change is accepted, a bullet is owed: it is a
user-observable change to an exported figure. Wording would name what a user
sees — that `--csv-precision full` no longer carries a log line's trailing zeros
into the exported duration columns — and the memory reduction alongside it, since
a large run using about half the memory for duration samples is user-observable.

If the change is declined or narrowed, the release note follows whatever
disposition the architect takes, and the memory bullet stands on its own.

## Ordering against the other issues

- **#478** (the highlight decision is kept once at the tag point and read back)
  touched the same hot-path lines and is merged, so nothing here waits on it. The
  merged code was read directly rather than the pre-merge line numbers in that
  document; site 5's `$is_highlighted` is the read-back local that issue
  introduced, and the normalisation sits beside it without touching it.
- **#528** (the transform contract and the memory assertion for the retained
  representation) is the parent. Its contract and its scenario-13 assertion are
  unchanged by this work, and its ceiling continues to hold.
- **#426** (the per-message statistics store is one hash per message; the as-built
  heap layout costs 5x on population traversal, on hold) is downstream: the
  per-duration retained size it would reason about becomes 24 bytes rather than 64
  once this lands.
