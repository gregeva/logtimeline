# Unsatisfiable statistic sort: notice and early objection (#418)

## Overview

`-so <statistic>` asks for the messages table to be ranked by a computed statistic.
When nothing in the run can produce that statistic, the tool currently ranks by
occurrences instead and says nothing — the analyst reads an occurrences-ordered
table believing it is the ranking they asked for.

Two distinct failures are in scope:

- **Silence.** The fallback is never announced on any surface.
- **Cost.** Where the outcome is knowable before the population walk, the run still
  performs it. Measured at +76% of the statistics phase on a 286,659-key file
  (#415 investigation; `-so p99`, `sort_selection: defined=0 fill=286659`).

## GitHub Issue

https://github.com/gregeva/logtimeline/issues/418

## Grounding: the blank cell cannot be the signal

The messages table renders five statistic columns — Min, P50, P99.9, CV %, Duration
(`print_message_summary`). The `-so` operand whitelist accepts 34 statistic operands.
Sorting by `p99`, `p9999`, `skewness`, `kurtosis`, `iqr`, `bytes_mean`, `count_max`
and most of the rest ranks by a value that never appears anywhere in terminal output.

This is why the `#303` contract's "the blank statistic column is the signal" does not
reach the degenerate case: for roughly 85% of sortable operands there is no cell to
be blank. Where the table drops to its basic variant (no durations observed, or
`-od`) there is no statistic column at all.

## Reproduction (committed fixtures, 2026-08-28)

| case | invocation | observed |
|---|---|---|
| never rankable, knowable at parse | `-so p99 -od tests/fixtures/tomcat-access-duration-spread.txt` | basic table variant, occurrences order, nothing on stdout or stderr |
| no durations in the data | `-so p99 tests/fixtures/log-level-vocabulary.txt` | basic table variant, occurrences order, silent |

**Family sweep, all three parse-time killers** (same fixture, `--disable-progress -ni`).
Every combination falls back to occurrences ordering with no output on any surface —
the defect is not confined to the duration family named in the issue body:

| family | combinations checked | result |
|---|---|---|
| duration | `-so p99 -od`, `-so impact -od`, `-so cv -od`, `-so iqr -od` | silent, 4 of 4 |
| bytes | `-so bytes_mean -ob`, `-so bytes_max -ob` | silent, 2 of 2 |
| count | `-so count_mean -oc`, `-so count_sum -oc` | silent, 2 of 2 |

## Locked decisions

### D1 — Two notices, both generic across metric families

The unsatisfiable sort produces one of two messages. Both are generic: the metric
family and the requested operand are placeholders, so every family is covered by the
same string rather than by per-family text.

**Contradiction (parse time).** The user switched the source metric off and asked to
sort on something derived from it. The message names the contradiction, not an
absence of data — the values were never collected, so "none were found" would
misdescribe what happened:

```
Note: cannot sort on <operand> because -XX/--long-option discards the <metric>
metric - the messages table is ordered by occurrences
```

**Absence (runtime).** The metric was collectable but nothing produced a value, or no
key reached the statistic's eligibility floor:

```
Note: no <metric> values were found - the requested sort on <operand> could not be
produced, so the messages table is ordered by occurrences
```

Both carry the two parts locked in the specification interview: **why** the ranking
could not be produced, then **that the run fell back to occurrences ordering**.

Part 1 is load-bearing rather than explanatory: most sortable statistics render no
column, so the analyst has no other way to learn the metric was empty. The absence
notice fires even where statistic columns render blank on every row — a table of
blanks reports "no values here", not "your requested ordering was not applied", and
only the second explains the row order.

**Option names appear in both forms, short then long** — `-od/--omit-durations`,
matching the existing `-os/--omit-stats` deprecation notice. The long form is the
self-documenting half: a notice is read by someone who may not have written the
command line, and `-od` alone does not say what it does. This applies to every
option named in user-facing output.

### D2 — Unsatisfiability is a property of the metric FAMILY, not of the operand

Every `-so` operand draws on one source metric. An operand is unsatisfiable exactly
when its family's source metric is absent, so the gates are written per family and
resolved once from `$sort_key`:

| family | source | operands | parse-time killer | runtime observation |
|---|---|---|---|---|
| duration ladder | duration | `duration`/`time`, `min`, `mean`, `max`, `std_dev`, `cv`, `impact`, p1–p99999, `iqr`, `skewness`, `kurtosis`, `bimodality_coef` | `-od` | `$durations_observed` (exists) |
| bytes | bytes | `bytes`/`size`, `bytes_occurrences`, `bytes_min`, `bytes_mean`, `bytes_max` | `-ob` | `$bytes_observed` (exists) |
| count | count | `count`, `count_occurrences`, `count_sum`, `count_min`, `count_mean`, `count_max` | `-oc` | none today |
| occurrences | line tally | `occurrences`/`total` | none — always satisfiable | n/a: the fallback target |

`-oc` as a parse-time killer for the count family is new here; it was not named in
the issue body, which cited only `-od` and (in the #432 close-out comment) `-ob`.

### D3 — Three detection points, each at the earliest moment its case is knowable

Applied uniformly across every family in the D2 table and every operand in it — not
only the cases named in the issue body. The `--omit-count` killer and the count
family's missing observation flag are in scope here for that reason.

- **At option parsing** — the family's source metric is switched off by an omit flag
  (`-so p99` with `-od`; `-so bytes_mean` with `-ob`; a count operand with `-oc`).
  Knowable before a line is read. Precedent: an inverted duration filter range warns
  up front and says what it did.
- **Before the walk** — the run observed no value of the family's source metric at
  all. Knowable once reading finishes. **This is where the measured +76% lives**: the
  entire population walk and re-sort is skipped, not merely short-circuited per key.
- **After the walk** — values exist, but no key met the statistic's eligibility floor
  (`n_floor`: 4 for shape moments, 2 for `std_dev`/`cv`, else 1). Already observable
  through the `sort_selection` telemetry counters as `defined=0`.

### D4 — One observation flag, resolved from the sort key, not a per-metric map

The runtime gate is a **single boolean**: was the raw input to the *resolved sort
key's source metric* ever seen. It is resolved at parse time from `$sort_key` to its
family and set where that family's raw value is extracted.

Rejected: a per-metric observation map (`observed{duration}`, `observed{bytes}`,
`observed{count}`, `observed{<udm>}`). It is more general and would serve `-V`
surfaces, but it puts per-metric bookkeeping on the hot path for every run including
the default sort, where nothing reads it — the same shape as #478 (highlight
bookkeeping evaluated per line when no highlight is active and when the metric is
absent). The single flag is set only when a statistic sort was actually requested.

The single flag also covers the count family, which has no observation flag today,
and gives runway for user-defined metrics as `-so` operands: a UDM name is not known
until `parse_udm_configs()` runs, and a family-keyed flag would need extending per
metric where a sort-key-resolved flag does not.

Registered on **#443** (user-defined metric diagnostics), whose zero-match notice
must distinguish "the spec never matched" from "the field is genuinely absent" — the
same observed/not-observed question, needing the equivalent per-UDM boolean.

### D5 — Parse-time cases fall back literally

Where parse time establishes that the sort can never rank anything, the sort key
falls back to occurrences at that point: the calculated-statistic branch is never
entered and the run behaves as if `occurrences` had been requested. The notice then
describes something the code did, rather than an outcome reached by another route.

### D6 — Amendment to the `-so` contract (#303)

`features/303-calculated-statistic-sort-path.md` point 4 locks *"No notice/warning
output when the fill block appears — the blank statistic column on fill rows is the
signal."* That holds for the **partial** case, where some keys rank and others do
not: a ranking was produced, and the blanks mark the keys outside it.

It is amended for the **degenerate** case only, where the defined block is empty. The
premise fails there on both halves: no ranking was produced at all, and for most
operands there is no rendered column in which a blank could appear. Partial ranking
is a ranking; an empty ranking is the tool doing something other than what was asked.

### D7 — Notice delivery

Ships ad-hoc on the terminal, on the surface that exists after message processing.
Registered on **#412** (notices surface — structured pre-chart render area) as a
producer to collect when that work happens; #412 is not in 0.18.0.

Per the repository's CLI conventions the notice is **not** gated behind
`--disable-progress`: it is a behavioural notice reporting what the tool decided on
the user's behalf, not a progress indicator.

### D8 — Harness placement: `tests/validate-statistics-demand.sh`

The existing `-so` coverage lives there — `scenario-3-sort-on-skewness` and
`scenario-3b-sort-on-p99` already assert the `sort_selection` and `sort_calc`
counters on exactly this code path, with the `asserts`/`produced_by`/`contract`
triple and a sabotage record dated 2026-07-13. New scenarios join them rather than
starting a new harness, so one harness owns the whole `-so` selection contract.

Scenarios to add, one per detection point in D3 plus the family sweep:

| scenario | invocation | asserts |
|---|---|---|
| parse-time contradiction, duration | `-so p99 -od` | contradiction notice on the terminal; **no** `sort_selection` line (the branch was never entered, per D5) |
| parse-time contradiction, bytes | `-so bytes_mean -ob` | same shape, bytes family |
| parse-time contradiction, count | `-so count_mean -oc` | same shape, count family |
| runtime absence | `-so p99` on a duration-free fixture | absence notice; walk skipped |
| post-walk floor unmet | `-so skewness` where no key reaches n≥4 | absence notice; `sort_selection: … defined=0 fill=<all>` |

The parse-time scenarios need no new fixture — the harness's existing access log
serves, since the contradiction is decided before a line is read. The runtime-absence
scenario needs a duration-free input; `tests/fixtures/log-level-vocabulary.txt`
already reproduces it (see the Reproduction table above).

Per the invocation-coherence rule (CLAUDE.md, 2026-08-23), each scenario is shaped to
what it asserts. These read a notice and a counter line, never a bucket, so they
inherit the harness's existing `--disable-progress -ni --terminal-width 200` shape
and add nothing that allocates buckets.

Each new assertion gets its own sabotage proof recorded in the harness beside the
existing record, per `tests/HARNESS-DESIGN.md` § Proving a new assertion can fail.

### D9 — The skipped walk is asserted through the existing telemetry, not #417 timings

Absence of the `sort_selection` line is already contractual in this harness and
already sabotage-proven: `scenario-1` asserts no such line under the default sort,
and `scenario-3` asserts none on the bucket store, with sabotage probe 3 (lines
emitted unconditionally) confirming both fail when the contract breaks.

A parse-time fallback (D5) therefore asserts **the same absence** — the branch was
never entered, so no telemetry exists to emit. That is a boolean the harness can
check today and it needs no new instrumentation.

The #417 sub-stage timings are rejected as the assertion vehicle: a timing is a
measurement, not an invariant, and asserting on one makes the harness sensitive to
machine speed. Timings remain the right instrument for the *performance* claim, which
is verified by benchmark (see the performance obligation above), not by harness.

### D10 — Prototype scope: the three metric surfaces, not an arm matrix

**What is prototyped: the three key surfaces where the observation is taken** —
duration, bytes, count. Each is measured for the cost of establishing whether its
family's source metric was observed during the run, at staged scale
(1k → 10k → 100k → millions), against the current read loop extracted verbatim as
baseline (2026-08-21 F9 rule; constants sliced from `ltl`, never restated).

**What is NOT prototyped up front:** a matrix of avoidance strategies. Optimisation
variants — folding the set into an existing conditional, hoisting it behind the
sort-requested gate, deriving the answer post-loop from existing accumulators — are
built and measured **only if the before/after benchmark shows a regression**. Guessing
at cheap forms and racing them against each other before knowing whether anything is
slow is the failure mode this issue's own performance obligation exists to prevent.

**The measured constant already in the tree.** `ltl:11453` records, from #432, that a
package-global read-compare-write on every line measured **~1.5% of total runtime**,
for a flag that only needs to know whether any line carried bytes — which is why the
bytes observation is set inside a conditional the loop was already entering. The
duration flag two lines above still uses the guarded read-compare-write form
(`$durations_observed = 1 if $durations_observed != 1 && …`). Both shapes are already
in the code; the prototype measures the surfaces against that known constant rather
than rediscovering it.

**Worth checking first, cheaply:** whether the answer is derivable post-loop from
state the read loop already maintains. `$durations_observed` and `$bytes_observed`
exist today; the count family accumulates `count_occurrences` per bucket. If
unsatisfiability can be read off existing accumulators, the per-line addition is not
needed for that family at all and the hot-path question dissolves rather than being
optimised.

### D11 — Before/after benchmarking is the gate, not the prototype

The prototype sizes the surfaces. The **benchmark decides**, run before and after
the change on the same input:

- **No regression on the default `occurrences` sort**, which #303 calls sacred. This
  is the path that must be provably untouched, since it is the one that never reads
  the flag.
- **The claimed improvement is verified**, not asserted: the pre-walk skip is
  supposed to remove the +76% statistics-phase cost measured in #415, on the same
  shape of input.
- **Time and memory both.** The flag is per-run state, so memory is expected flat;
  a deviation is a finding.

A regression found here is what licenses building the optimisation arms above —
and profiling per `features/nytprof-profiling-workflow.md` if the delta is
unexplained.

## Performance obligation — MANDATORY, not discretionary

This issue is both a hot-path change and a performance fix, so measurement governs it
at both ends. CLAUDE.md § Development Phases makes prototyping mandatory when work
introduces a new per-line hot-path cost; this does.

### The hot-path surface is exactly one thing

Of everything in this design, **only D4's observation flag executes per line.** The
parse-time gates, the pre-walk skip, the post-walk detection and both notices are all
once-per-run and cannot appear in a per-line profile.

That makes the prototype question narrow and answerable: what does setting the flag
cost per line, and can it be hoisted so a run that requested no statistic sort pays
nothing at all? #478 is the standing example of the failure mode — bookkeeping
evaluated per line when it cannot affect the result.

### Before implementation

1. **Prototype the flag** in `prototype/`, comparing candidates against the current
   code as baseline at staged scale (1k → 10k → 100k → millions). Per the 2026-08-21
   F9 rule the baseline arm is the production code path extracted verbatim — call
   shape, variable scoping and data movement included — not a convenience wrapper.
   Per the 2026-08-27 rule, constants are sliced from `ltl`, never restated from
   memory; where a value must be restated, the source symbol is named beside it.
2. **Record the measured result** (medians with ranges) and the lessons as decisions
   in this doc BEFORE writing production code.

### After implementation — both directions

3. **Regression check on the unaffected path.** The default `occurrences` sort is
   sacred (#303 design record) and must not regress at all. Benchmark before and
   after against the last released baseline.
4. **Improvement measurement on the affected path.** The pre-walk skip is claimed to
   remove the +76% statistics-phase cost measured in #415. That claim is verified by
   measurement on the same shape of input, not asserted — a fix whose benefit is
   never measured is indistinguishable from one that does nothing.
5. **Memory as well as time.** Both are captured; the flag is per-run state, so the
   expectation is flat, and a deviation from flat is a finding.
6. **Profile if the numbers are unexplained.** `features/nytprof-profiling-workflow.md`
   is the workflow; a surprising delta is investigated rather than accepted, and the
   profile-ready contract applies to anything given a counter.

Guessing at the cheap implementation and iterating through variants against the full
tool is not the process — the prototype exists so the candidate is chosen on measured
evidence in one pass.

## Open items

- None. Planning is complete; the prototype is the next executable step.

## Related

- **#415** (stats-drift investigation, closed) — where the cost was measured.
- **#426** (compact per-message store) — structural remedy for the traversal cost;
  not a gate.
- **#417** (sub-stage stats timing) — would make the skipped walk visible as a
  sub-stage delta; not required.
- **#478** (highlight bookkeeping on the hot path) — the anti-pattern D4 avoids.
- **#443** (user-defined metric diagnostics) — needs the equivalent per-UDM flag.
- **#412** (notices surface) — eventual collector for this notice.
