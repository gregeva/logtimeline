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
Note: cannot apply -so/--sort-on <operand> because -XX/--long-option discards the
<metric> metric - the messages table is ordered by occurrences
```

**Absence (runtime), before the walk.** The metric was collectable but the run never
observed a value:

```
Note: no <metric> values were found - the requested sort (-so/--sort-on <operand>)
could not be produced, so the messages table is ordered by occurrences
```

**Absence (runtime), after the walk.** Values were observed, but no key reached the
statistic's eligibility floor. "No values were found" would be false here — the
values exist, there were never enough per message — so the reason is stated as what
the run had, not what it lacked (architect, 2026-08-28):

```
Note: the requested sort (-so/--sort-on <operand>) could not be produced from the
<metric> values in this run - the messages table is ordered by occurrences
```

Both carry the two parts locked in the specification interview: **why** the ranking
could not be produced, then **that the run fell back to occurrences ordering**.

Part 1 is load-bearing rather than explanatory: most sortable statistics render no
column, so the analyst has no other way to learn the metric was empty. The absence
notice fires even where statistic columns render blank on every row — a table of
blanks reports "no values here", not "your requested ordering was not applied", and
only the second explains the row order.

**Option names appear in both forms, short then long** — `-od/--omit-durations`,
and the sort option itself as `-so/--sort-on <operand>` (architect, 2026-08-28),
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

### D4 — Derived from existing accumulators; no new per-line work

The gate answers one question: **was the raw input to the resolved sort key's source
metric ever observed during the run.** That answer is **derived after the read loop
from accumulators the tool already maintains** — it is not a new per-line flag.

| family | existing state the answer is read from |
|---|---|
| duration | `$durations_observed` (set at the extraction site; already gates the table variant) |
| bytes | `$bytes_observed` (set inside the conditional the loop already enters) |
| count | count accumulation is per-bucket (`count_occurrences`); the run-wide answer is established without adding per-line work |
| occurrences | always satisfiable — the fallback target, needs no observation |

**Why derivation, not observation.** The mechanism originally proposed — a package
global set per line — is already measured in this codebase and already rejected:
`ltl:11453` records from #432 that a package-global read-compare-write on every line
cost **~1.5% of total runtime**, for a flag that only needs to know whether *any*
line carried the value. That is why the bytes observation was moved inside a
conditional the loop was already entering. Adding a fourth flag of the same shape
would re-introduce a cost this repository has already paid to remove, and would
repeat #478's pattern — per-line bookkeeping evaluated when it cannot affect the
result.

Deriving costs nothing per line, so the default `occurrences` sort — which #303 calls
sacred — is provably untouched: there is no new statement on the hot path to regress
it.

Also rejected, and for the same reason: a per-metric observation map
(`observed{duration}`, `observed{bytes}`, `observed{count}`, `observed{<udm>}`).
Registered on **#443**, whose zero-match notice must separate "the spec never
matched" from "the field is genuinely absent" — the same question, needing the
equivalent per-UDM state, with the better vantage point on where it should live.

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

Ships ad-hoc on the terminal — three `print STDERR "Note: ..."` sites
(`apply_parse_time_sort_gate()`, `sort_fallback_to_occurrences()` pre-walk and
post-walk texts). Registered on **#412** (notices surface — structured pre-chart
render area) on 2026-08-28 as producers to migrate to its producer/consumer model
when that work happens; #412 is not in 0.18.0.

Per the repository's CLI conventions the notice is **not** gated behind
`--disable-progress`: it is a behavioural notice reporting what the tool decided on
the user's behalf, not a progress indicator.

### D8 — A short addition to the existing statistics harness, asserting the path taken

New scenarios are a **short addition** to `tests/validate-statistics-demand.sh` — the
harness that already owns statistics-calculation path coverage, including
`scenario-3-sort-on-skewness` and `scenario-3b-sort-on-p99`, which assert the
`sort_selection` and `sort_calc` counters on exactly this code path with a 2026-07-13
sabotage record. No new harness; no restatement of coverage that already exists.

**The assertions are operational: they prove the path expected in a given situation
is the path taken.** Output-shape assertions alone (a notice printed, a column
missing) cannot distinguish a correct decision from a coincidence — an
occurrences-ordered table looks identical whether the gate fired for the right reason,
the wrong reason, or not at all. The D12 `-V` lines exist so the decision itself is
assertable:

| situation | path that must be taken |
|---|---|
| sort operand's family switched off at parse time | parse-time fallback; calculated-statistic branch **never entered** (no `sort_selection` telemetry at all, per D5) |
| family collectable but nothing observed in the run | pre-walk fallback; **population walk skipped**, not run-and-discarded |
| values observed, no key meets the eligibility floor | walk runs, `defined=0` with every key in `fill` |
| ordinary partial case (some keys rank) | unchanged behaviour, no notice — the #303 contract still holds (D6) |

The last row matters as much as the first three: the amendment is scoped to the
degenerate case, so a scenario proving the partial case did **not** change is part of
the addition.

**Scenario shapes are determined during development**, from what the implementation
actually distinguishes — the table above states what must be proved, not a
pre-committed scenario list. Coverage spans all three metric families (D2), since the
sweep found the defect in each.

The existing access log serves the parse-time cases (decided before a line is read);
`tests/fixtures/log-level-vocabulary.txt` reproduces the duration-free case. Per the
invocation-coherence rule (2026-08-23) each scenario inherits the harness's existing
`--disable-progress -ni --terminal-width 200` shape — these read a notice and a
counter line, never a bucket.

Each new assertion carries the `asserts`/`produced_by`/`contract` triple and a
sabotage proof recorded beside the existing record
(`tests/HARNESS-DESIGN.md` § Proving a new assertion can fail).

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

### D10 — No prototype is required; D4 removed the hot-path change

docs/process/workflow.md § Feature lifecycle makes prototyping mandatory when work introduces a new
per-line hot-path cost. **D4 removes that cost from the design**: the gate is derived
after the read loop from accumulators that already exist, so there is no new per-line
statement to size and nothing for a staged-scale prototype to compare.

This is the intended outcome of the "validate the premise" rule (2026-07-13), applied
before building rather than after: the premise of a prototype here was that a per-line
observation was needed. It is not. The relevant constant was already measured in this
codebase — `ltl:11453` records a package-global read-compare-write per line at **~1.5%
of total runtime** (#432), which is why the bytes observation rides a conditional the
loop already enters. Re-measuring it would rediscover a number the tree already
states.

**What is prototyped instead: nothing up front.** If the before/after benchmark under
D11 shows a regression, that is what licenses building and measuring optimisation
candidates — with the profile workflow
(`features/nytprof-profiling-workflow.md`) to locate it first, so the candidates
address a measured cause rather than a guess.

### D11 — Before/after benchmarking is still the gate

The prototype obligation is discharged by D10; the measurement obligation is not.
The benchmark runs before and after the change:

- **No regression on the default `occurrences` sort**, which #303 calls sacred. D4
  makes this expected rather than hoped for — there is no new hot-path statement —
  and the benchmark proves it rather than arguing it.
- **The claimed improvement is verified, not asserted.** The pre-walk skip is supposed
  to remove the +76% statistics-phase cost measured in #415, on the same shape of
  input. A fix whose benefit is never measured is indistinguishable from one that does
  nothing.
- **Time and memory both.** The gate holds per-run state only, so memory is expected
  flat; a deviation is a finding.

The `-V` lines added under D12 are the instrument for the second point: the fallback
decision is observable in the same run that is being timed.

### D12 — The gating state is exposed on `-V statistics-demand`

The variables the gate resolves — the sort key's resolved metric family, whether that
family's source was observed, and which of the three detection points fired — are
emitted on the `statistics-demand` section.

**Why that section.** It already owns "calculated-statistic sort selection
(defined/fill split, per-pass call attribution)" and already carries the
`sort_selection` and `sort_calc` lines this work sits directly alongside. The gating
state is the same subject one step earlier: what the sort path decided before it ran,
or decided instead of running. A second section would split one subject across two
surfaces.

**What it buys, and why it is not optional:**

- **Observing the situation.** A run that falls back can be interrogated for *why* —
  which family, observed or not, which detection point — instead of inferring it from
  an absent table column.
- **Finding bugs.** A fallback that fires when it should not, or fails to fire when it
  should, is otherwise invisible: both look like a table in occurrences order.
- **Tying the harness to it.** D8's scenarios currently assert a terminal notice and
  the absence of a `sort_selection` line. Exposed gating state gives them a positive
  assertion of the decision itself, rather than only its consequences — the
  difference between asserting the tool stayed quiet and asserting it decided
  correctly.

Adding these lines makes this a `-V` surface change, which carries the standing
obligations: `tests/HARNESS-DESIGN.md` is consulted before the section is touched, the
line shapes and the semantics of every emitted key are recorded in the owning feature
doc's section contract in the **same commit**, and each new assertion gets a sabotage
proof. The owning doc for this section is
`features/duration-statistics.md § -V statistics-demand section contract`.

## Performance obligation — MANDATORY, not discretionary

This issue is a performance fix, so measurement governs it. It is **no longer a
hot-path change**: D4 derives the gate from existing accumulators, so nothing is added
to the read loop. D10 records why that discharges the prototyping obligation; D11
records the benchmarking that still applies.

**The measurement that matters is before/after, both directions:**

1. **The default `occurrences` sort must not regress at all** (#303 calls it sacred).
   With no new per-line statement this is expected — the benchmark proves it.
2. **The claimed improvement is verified.** The pre-walk skip should remove the +76%
   statistics-phase cost measured in #415, on the same shape of input.
3. **Time and memory both.** Per-run state only, so memory is expected flat; a
   deviation is a finding.
4. **Profile if a delta is unexplained** — `features/nytprof-profiling-workflow.md`.
   A surprise is investigated, not accepted.

A regression is what licenses building optimisation candidates, located by profile
first so they address a measured cause rather than a guess.

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
