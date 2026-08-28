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

## Open items

- Harness placement: `tests/validate-statistics-demand.sh` carries the existing `-so`
  scenarios and the `sort_selection` counter assertions.
- Whether the skipped walk is asserted through the `sort_selection` telemetry
  (absence of the section) or through the #417 sub-stage timings.

## Related

- **#415** (stats-drift investigation, closed) — where the cost was measured.
- **#426** (compact per-message store) — structural remedy for the traversal cost;
  not a gate.
- **#417** (sub-stage stats timing) — would make the skipped walk visible as a
  sub-stage delta; not required.
- **#478** (highlight bookkeeping on the hot path) — the anti-pattern D4 avoids.
- **#443** (user-defined metric diagnostics) — needs the equivalent per-UDM flag.
- **#412** (notices surface) — eventual collector for this notice.
