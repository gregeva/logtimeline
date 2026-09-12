# Feature: completing the log-level vocabulary

## Overview

Someone runs `ltl` over an application log and reads the category table to find
out what the application was saying. If the application logs through
`java.util.logging`, its two most serious levels are spelled `SEVERE` and
`WARNING`. Neither is in `ltl`'s recognised set, so every line carrying them is
read, matched against its format, and then discarded before it reaches any
count. The category table shows nothing, the timeline shows nothing, and the
only trace is that `LINES READ` is larger than `LINES INCLUDED` by a number
nobody can attribute.

That is the motivating consumer: a reader who is looking at a chart that is
quietly missing the lines they most wanted to see. The same applies to a
ThingWorx Edge C SDK log, which emits `AUDIT` and loses every one of those lines
today, and to any producer drawing on the syslog severity vocabulary
(`EMERGENCY`, `ALERT`, `CRITICAL`, `NOTICE`).

This drop adds seven names to the recognised set so that lines carrying them are
counted, coloured and displayed like any other level. It is the narrow list
edit. It does not make the discarding audible: that is the separate structural
work in #476 (log levels declared per format in the registry, with unregistered
levels reported at end of run).

## GitHub Issue

- #475 (BUG: severity levels a supported format can emit are missing from the
  log-level array and are silently discarded): the requirement.

## The mechanism

`read_and_process_logs()` gates every line on membership of one global set:

```perl
unless (exists $log_level_set{$category_bucket}) {
    $excluded_other++;
    next;
}
```

`%log_level_set` is built once from the static `@log_levels` array in GLOBALS.
The test is closed-world: whatever format matched the line, a level the array
does not carry is dropped into `$excluded_other`, a counter shared with
unrelated exclusion causes and surfaced only in `-V filter-summary` and the
aggregate export. `@log_levels` was written from the levels the corpus happened
to contain, while every producer format's level slot captures an arbitrary word
or token, so the two have never agreed.

Measured on a ten-line Windchill Method Server fixture carrying `FATAL`,
`CRITICAL`, `SEVERE`, `WARNING`, `NOTICE`, `ALERT`, `EMERGENCY`, `ERROR`, `WARN`
and `INFO`: `lines_read: 10`, `lines_unmatched: 0`, `excluded_other: 6`,
`lines_included: 4`. Every line matched its format; all six losses are the
category gate.

## Requirements

- **R1**: Seven severity names a supported format can emit are recognised:
  `CRITICAL`, `SEVERE`, `WARNING`, `NOTICE`, `ALERT`, `EMERGENCY`, `AUDIT`. A
  line carrying one is counted in `LINES INCLUDED` and appears as its own row in
  the category table with its own count.
- **R2**: A `CRITICAL` line is classified as a failure, because the shipped
  default classification rule already names `CRITICAL` and cannot currently
  reach one.
- **R3**: The default failure rule names the severities that denote a failure:
  `ERROR`, `FATAL`, `CRITICAL`, `SEVERE`, `ALERT`, `EMERGENCY`. `WARNING`,
  `NOTICE` and `AUDIT` are recognised levels that are not failures.
- **R4**: Each added level occupies every surface a category occupies, so none
  of them is half-present: the vocabulary, the colour table, the STATS CSV
  structural rules, and the classification default where R3 applies.
- **R5**: The added levels take their place in the vocabulary by severity, so
  the category table, the legend, the aggregate export and the STATS CSV header
  continue to read in one order.
- **R6**: The existing six-line vocabulary fixture
  `tests/fixtures/log-level-vocabulary.txt` and the committed regression baseline
  built from it are unchanged by this work.
- **R7**: A line whose level is outside the vocabulary is still dropped at the
  category gate and counted as an "other" exclusion. The fixture that stands for
  that case keeps standing for it, which means its rejected token can no longer
  be a name this work registers.

## Corrections to the issue body

Recorded here because the issue body still carries them.

1. **The fourth surface named in the issue no longer exists as written.** The
   issue says `features/447-message-control-character-normalisation.md` § D6
   (FATAL joins the log-level vocabulary) records the error-rate accumulation as
   the fourth surface a level must occupy. Since #453 (per-variant
   success/failure classification and an event-ledger property in the format
   registry) D13, `normalize_data_for_output()` no longer derives the error
   count from category names; it reads the bucket's classification failure
   counter. So "which levels count toward the error rate" is a question about
   the `%classification_default` failure alternation, not a fourth-surface edit.
   D6's record is trued up in the same commit as this document.

2. **The scope is eleven registry entries, not the Windchill Method Server
   format alone.** Entries whose level capture admits an arbitrary word or
   token: `thingworx_standard` (two variants), `thingworx_rac_client`,
   `connection_server_standard`, `integration_runtime_standard`,
   `connection_server_json`, `tw_analytics_v2`, `tw_analytics_worker`,
   `tw_edge_c_sdk`, `windchill_method_server`, and
   `classification_verification`. The Workgroup Manager format is the exception:
   it maps its severity letter through a table into the shared vocabulary, so an
   unmapped letter falls to the same gate rather than reaching it with an
   arbitrary token.

3. **Two surfaces exist beyond the four the issue names.** The descriptive-name
   lookup `%category_display_names` added by #463 (friendly descriptive names
   for log level categories in the summary table), which is optional; and the
   summary contribution-bar fill resolved by `summary_bar_color()`, which is a
   hard constraint on the colour choice rather than an edit (D4 below).

4. **The vocabulary order also sets the STATS CSV header order**, which the
   issue does not mention. Measured: the header goes from
   `timestamp,FATAL,ERROR,WARN,INFO,...` to a header carrying the new names
   interleaved by severity ahead of `FATAL`. The structural validator does not
   pin level column position (`tests/csv-output/rules/stats-columns.tsv` gives
   level columns `position = *`), so no harness breaks, but a machine-readable
   header changes and that is user-observable.

5. **`CRITICAL` being unreachable is already on the record.**
   `features/453-success-failure-classification-event-ledger.md` states the
   failure set is today's set plus `CRITICAL`, which no shipped format emits,
   and `features/396-windchill-method-server-log4j-format.md` records that
   `CRITICAL` is not a Log4j level. So this is a known consequence of a shipped
   decision, not a newly found contradiction. It still leaves `docs/usage.md`
   and `docs/explain/classification.md` publishing a rule that cannot fire.

6. **The statistics oracle's `AUDIT` entry is not undiscovered drift.**
   `tests/statistics-drift/oracle/calculate-reference.py` records in its own
   comment that `AUDIT` is retained as an inert entry so the oracle's set stays
   a superset and never drops a line `ltl` would keep. That is the safe
   direction, and the opposite of the `FATAL` case.

Everything else the issue cites is accurate against the current tree: the sub
name `read_and_process_logs()`, the array `@log_levels`, the harness
`tests/validate-log-level-vocabulary.sh`, and the `FATAL` precedent in
`features/447-message-control-character-normalisation.md` § D6.

## The seven names and the evidence for each

| Name | Evidence | Producer vocabulary |
|---|---|---|
| `CRITICAL` | The shipped default failure rule in `%classification_default` names it, and `docs/usage.md` and `docs/explain/classification.md` both publish that rule, so the tool already promises to classify a level it discards. | syslog severity 2 |
| `SEVERE` | The highest severity a `java.util.logging` application emits; a JUL-configured application logging through any diagnostics format loses its most serious lines. | `java.util.logging` |
| `WARNING` | `java.util.logging`'s spelling of `WARN`. | `java.util.logging` |
| `NOTICE` | syslog severity 5, between informational and warning. | syslog |
| `ALERT` | syslog severity 1, above `CRITICAL`. | syslog |
| `EMERGENCY` | syslog severity 0, the highest. | syslog |
| `AUDIT` | Emitted in the level position by the ThingWorx Edge C SDK format (`tw_edge_c_sdk`): 180 lines across the three Edge C SDK files in the test corpus, every one discarded today. Their per-file `-V filter-summary` `excluded_other` counts are 97, 72 and 14. Also already present as an inert entry in the statistics oracle's own level set. | ThingWorx Edge C SDK |

The first six are the names in the issue's table. `AUDIT` was found by scanning
the corpus for level tokens the vocabulary does not carry, and is the only one
of those with real lines behind it.

Three further tokens turned up in that scan and are **not** admitted: `START`,
`AUTH` and `TRAFFIC_CONTROL`, one or two lines each. They are startup and
control messages occupying the level slot rather than severities, and naming
them as categories would assert they are severities. They are left for #476 (log
levels declared per format in the registry, with unregistered levels reported at
end of run) to surface, which is the mechanism that can report a token without
promoting it.

## Locked decisions

### D1: The vocabulary is a static list and names are added by hand

The set of recognised levels stays a hand-written list. A name is admitted by a
person deciding it is a severity a producer emits, not by the tool inferring it
from what it sees. The gate stays closed-world.

Admission is on what the format's capture pattern allows plus a corpus scan for
tokens already being discarded. The stricter producer-only test is the test that
left `FATAL` discarded until #447 found it by accident, and none of these names
costs anything today because six of the seven appear nowhere in the corpus.

The seven names admitted are `CRITICAL`, `SEVERE`, `WARNING`, `NOTICE`,
`ALERT`, `EMERGENCY` (the issue's table) and `AUDIT` (the corpus scan).
`START`, `AUTH` and `TRAFFIC_CONTROL` are declined for the reason above.

*Architect decision, 2026-09-12.*

### D2: `CRITICAL` is admitted with the others and gets its own criterion

`CRITICAL` ships in this drop rather than as a separate one-name change. Adding
the name is one entry and makes three already-shipped statements true; the
alternative, removing `CRITICAL` from the default failure rule and from two
user-facing documents, would narrow what the tool promises for no gain.

Its verification differs from the other six, so it is asserted separately: a
`CRITICAL` line must appear under `FAILURE CLASSIFIED`, not merely as a row in
the category table. Being in the category table only proves the gate let it
through; reaching the failure count proves the rule the tool publishes actually
fires.

*Architect decision, 2026-09-12.*

### D3: The default failure rule gains `SEVERE`, `ALERT` and `EMERGENCY`

`%classification_default`'s failure alternation, today
`^(?:ERROR|FATAL|CRITICAL)$`, becomes
`^(?:ERROR|FATAL|CRITICAL|SEVERE|ALERT|EMERGENCY)$`.

`SEVERE` is `java.util.logging`'s highest severity and is that vocabulary's
equivalent of `FATAL`. `ALERT` and `EMERGENCY` sit above `CRITICAL` in syslog,
so a rule that calls `CRITICAL` a failure and stays silent about the two levels
above it would be incoherent.

`WARNING`, `NOTICE` and `AUDIT` stay outside the rule. `WARNING` is
`java.util.logging`'s `WARN` and `WARN` is not a failure today; `NOTICE` is
below informational in syslog; `AUDIT` records an action, not an outcome.

Because the alternation is published, it is changed on every surface in the same
commit:

| Surface | Change |
|---|---|
| `%classification_default` in `ltl` | the alternation gains the three names |
| `docs/usage.md` | the classification-default row quotes the pattern verbatim |
| `docs/explain/classification.md` | the sentence naming which levels are failures |
| `$explain_classification_intuition` in `ltl` | the in-tool `--explain classification` twin of that sentence |
| `tests/validate-format-detection.sh` | the verbatim assertion of `default_failure: category_bucket=^(?:ERROR|FATAL|CRITICAL)$`, which fails until updated |

The change propagates into every generated scan block through
`format_classification_src`, and into the error rate through the bucket's
failure counter read by `normalize_data_for_output()`. No format that declares
its own classification is affected, by definition of the default.

*Architect decision, 2026-09-12.*

### D4: Colours reuse existing exact colour strings; `AUDIT` takes cyan

`summary_bar_color()` resolves a category's contribution-bar fill by pulling the
hue digit out of a basic or bright ANSI form:

```perl
my ($hue) = $fg =~ /(?:^|\D)[349](\d)m/ or return undef;
return $bar_entry_by_hue{$hue};
```

A 256-colour definition resolves to no bar entry, and
`tests/validate-summary-contribution-bar.sh`'s
`check_every_category_has_a_fill` sweeps every non-rate member of the vocabulary
and fails when one has no fill. Reusing an existing level's exact colour string
satisfies the constraint by construction, which is what
`features/448-category-summary-share-and-bar.md` means when it says a new level
inherits its bar from the colour it is already given, with no new table.

| Level | Colour | Taken from |
|---|---|---|
| `CRITICAL` | `\033[0;31m` | red, as `FATAL` and `ERROR` |
| `SEVERE` | `\033[0;31m` | red, as `FATAL` and `ERROR` |
| `ALERT` | `\033[0;31m` | red, as `FATAL` and `ERROR` |
| `EMERGENCY` | `\033[0;31m` | red, as `FATAL` and `ERROR` |
| `WARNING` | `\033[0;33m` | yellow, as `WARN` |
| `NOTICE` | `\033[0;32m` | green, as `INFO` |
| `AUDIT` | `\033[0;36m` | cyan, as `CREATE` |

`AUDIT` is the one name that is not a severity, so it takes a colour of its own
rather than borrowing a severity's. Cyan is chosen because it is the one basic
hue in `%colors` that no log level uses today (magenta is `FORCE` and `TRACE`,
blue is `DEBUG` and `DATA`), it is neutral rather than alarming, and it is the
exact string `CREATE` already carries, so it is known to resolve through
`summary_bar_color()` against the cyan entry of `@column_colors`. The `-HL` twin
derives itself: `%colors` builds every highlighted twin in a loop.

Position in `@log_levels` is by severity, interleaved among the existing names.
The head of the array is already severity-ordered (`FORCE`, `FATAL`, `ERROR`,
`WARN`, `INFO`, `DEBUG`, `TRACE`) and the category table, the legend, the
aggregate export and the STATS CSV header all read by that order, so appending
would break the one ordering the output already has. Each name is written as its
`-HL` twin followed by itself, as the array's existing entries are.

The order becomes:

```
FORCE, EMERGENCY, ALERT, CRITICAL, SEVERE, FATAL, ERROR,
WARNING, WARN, NOTICE, INFO, AUDIT, DEBUG, TRACE, ...
```

`EMERGENCY`, `ALERT` and `CRITICAL` are syslog's three above `FATAL`'s
equivalent; `SEVERE` sits immediately above `FATAL` as the `java.util.logging`
name for the same band; `WARNING` precedes `WARN` as the longer spelling of the
same level; `NOTICE` sits between `WARN` and `INFO`, which is its syslog
position. `AUDIT` is placed after the whole severity block, immediately after
`INFO` and before `DEBUG`: it is not a severity and has no rank within the
block, and placing it after `INFO` keeps it out of the run of levels a reader
scans by seriousness while still leaving it above the debugging levels, which
are read as a separate group.

The STATS CSV header column order changes as a consequence. No harness pins
level column position, but the header is machine-readable and a consumer reading
by position would notice, so it gets a release-note line (see below).

*Architect decision, 2026-09-12.*

### D5: A second fixture, not an extension of the existing one

`tests/fixtures/log-level-vocabulary.txt` is six lines and is read by
`tests/validate-log-level-vocabulary.sh`, `tests/validate-category-names.sh`,
`tests/validate-format-detection.sh`, `tests/validate-statistics-demand.sh`,
and by both `tests/capture-regression.sh` and `tests/validate-regression.sh`,
which run the `errrate-diagnostics-highlighted-failure-w160` case over it
against the committed baseline at
`tests/reference-output/errrate-diagnostics-highlighted-failure-w160.txt`.

Extending it in place would change that baseline's line counts, category shares
and bar extents, requiring a recapture of a committed deliverable, and would
shift the expected counts three other harnesses read.

So the seven names go into a second committed fixture under `tests/fixtures/`,
named `.txt` (`*.log` is gitignored), with its own scenario in
`tests/validate-log-level-vocabulary.sh`. The existing fixture and the committed
baseline are untouched.

*Architect decision, 2026-09-12.*

### D6: No descriptive-name entries

None of the seven gets an entry in `%category_display_names`.
`features/463-friendly-log-level-category-names.md` D1 (one global lookup,
shared by every format) states that the log-level vocabulary names itself and
that only the HTTP status families needed the lookup, and R2 of the same
document means an absent entry is correct rather than a gap: the level shows its
own name.

`WARNING` and `WARN` appearing as two adjacent rows is the one case that could
read as a bug to someone who does not know one is `java.util.logging`'s
spelling. If it proves confusing in practice it is a one-line follow-up, not a
reason to make this drop the first departure from D1.

*Architect decision, 2026-09-12.*

### D7: Nothing about the silence ships here

No notice, no end-of-run report, no change to how `$excluded_other` is
surfaced. #476 (log levels declared per format in the registry, with
unregistered levels reported at end of run) owns the silence, and the issue body
is explicit that this is the narrow immediate fix and that neither issue blocks
the other.

The cost of holding the line is real and is recorded here: after this drop the
next unknown level is exactly as silent as these seven were, and the only reason
these were found is that #447 happened to look. That is the argument for #476,
not for widening this one.

*Architect decision, 2026-09-12.*

### D8: The decisions live in this document

No feature doc owned #475. This document owns it.
`features/447-message-control-character-normalisation.md` § D6 is a closed
decision about `FATAL` and does not grow a second subject; its forward pointer
to this issue is updated to name this document, and its stale fourth-surface
record is corrected in the same action per correction 1 above.

*Architect decision, 2026-09-12.*

## Every surface a level occupies, and what changes on each

Per added level *L*, with its `L-HL` twin.

| Surface | Where | What changes |
|---|---|---|
| Vocabulary | `@log_levels` and `%log_level_set`, GLOBALS in `ltl` | two entries, `L-HL` then `L`, at the position D4 fixes. The array order is the print order in the category table, the legend, the aggregate export and the STATS CSV header |
| Colour | `%colors` in `ltl` | one entry, the exact string D4 names; the `-HL` twin derives itself in the existing loop |
| Bar fill | `summary_bar_color()` in `ltl` | **no edit**, a constraint. The colour must be a basic or bright ANSI form or the category resolves to no fill and `tests/validate-summary-contribution-bar.sh` fails. D4's reuse satisfies it by construction |
| STATS CSV structural rules | `tests/csv-output/rules/stats-columns.tsv` | two rows, `L` and `L-HL`, each `*`/`int`/`no`/`0`/`level`, matching the shape of the existing level rows. Without them `tests/validate-csv-output.sh` fails on an unknown column |
| Classification default | `%classification_default` in `ltl` | only for `SEVERE`, `ALERT`, `EMERGENCY` per D3; `CRITICAL` is already named |
| Classification prose | `docs/usage.md`, `docs/explain/classification.md`, `$explain_classification_intuition` in `ltl` | the published failure set, per D3 |
| Descriptive name | `%category_display_names` in `ltl` | **no edit**, per D6 |
| Statistics oracle | `tests/statistics-drift/oracle/calculate-reference.py` `LOG_LEVELS` | the seven names are added, keeping the oracle's set a superset of the tool's. `AUDIT` is already there and stops being an inert entry |
| Fixture standing for an unregistered level | `tests/fixtures/log-level-outside-vocabulary.txt` | its rejected line's level token is replaced, because that token is `NOTICE` and this drop registers it |

That last row is the one surface the issue does not lead to and the
investigation did not find. `tests/fixtures/log-level-outside-vocabulary.txt` is
three lines: two `INFO` lines and one whose level is `NOTICE`, present precisely
because it is a level the vocabulary does not carry.
`tests/validate-filter-summary.sh`'s `vocabulary-rejection` scenario runs it and
asserts `excluded_other: 1`, then `assert_funnel_identities` reconciles the
whole funnel, so the scenario also depends on two of the three lines being
included. Registering `NOTICE` makes all three lines survive: the assertion
would read `excluded_other: 0` and the funnel identity would move with it. The
scenario would fail for the right reason, and it would stop testing what it
exists to test, because the fixture would no longer contain an unregistered
level at all.

Consumers that need no edit because they iterate the array rather than
duplicating it: `write_aggregate_export()` (category totals and the per-bucket
category series), `resolve_csv_column_family()` (every level column resolves to
the `level` family through a lookup over the array), `print_bar_graph()` (the
legend loop and the occurrences-column loop), and `print_summary_table()` (the
category table's rows and their order).

`-V` sections: none added, none changed. The added levels appear as data in the
existing aggregate-export category keys, and `filter-summary`'s
`excluded_other` falls on input carrying them.

`--help`: no level list, no new option, so no `print_help()` row and no
`docs/usage.md` option row.

## Harness plan

### The new fixture

A second fixture under `tests/fixtures/`, named `.txt`, one line per added
level plus controls, in the Windchill Method Server shape the existing
vocabulary fixture uses. Messages are neutral placeholders; no corpus text is
copied in.

It carries the seven added names and enough already-recognised levels to make
the classification assertions two-sided: at minimum one `INFO` line, so a run
over the fixture has both classified and unclassified lines.

One detail for whoever writes the error-rate style assertion: the existing one
builds its downgraded arm with `sed 's/ FATAL / INFO  /'`, padding to preserve
column width. A longer name such as `EMERGENCY` needs a different downgrade
expression; the fixture is written so the substitution is unambiguous.

### `tests/validate-log-level-vocabulary.sh`: the owning harness

A new scenario over the new fixture, alongside the existing
`method-server-levels` scenario, which is left exactly as it is.

- One `check_level_present` assertion per added level: `CRITICAL`, `SEVERE`,
  `WARNING`, `NOTICE`, `ALERT`, `EMERGENCY`, `AUDIT`. The existing checker reads
  the count out of the row rather than merely matching it, and a level with no
  row is a hard failure, which is precisely the invisible-loss condition.
- One `check_all_lines_included` assertion at the new fixture's line count:
  `LINES READ` equal to `LINES INCLUDED` proves the gate discarded nothing.
- One assertion for R2 (a `CRITICAL` line is classified as a failure) reading
  `FAILURE CLASSIFIED` from the render, not the category table. This is the
  criterion D2 separates out.
- One assertion for R3 (the added failure severities count as failures) shaped
  like the existing `check_error_rate_counts_fatal` two-arm comparison: a run
  carrying `SEVERE`, `ALERT` and `EMERGENCY` reports a strictly higher failure
  count than a run with those lines downgraded to a non-failure level.

Each assertion carries `asserts`, `produced_by` (function name, never a line)
and `contract` pointing at this document's decision by name, per
`tests/HARNESS-DESIGN.md` § Self-documenting assertions.

### Sabotage proof

Per `tests/HARNESS-DESIGN.md` § Proving a new assertion can fail, and following
the pattern `features/447-message-control-character-normalisation.md` § D6 set
for `FATAL`: every new assertion is demonstrated to fail before it is trusted to
pass.

The method is the one that found this defect. Take a copy of `ltl` in the
scratchpad, remove one added name from `@log_levels`, and run the new scenario:
that level's `check_level_present` must fail naming the level, and
`check_all_lines_included` must fail reporting the shortfall. For the
classification assertions, remove the added name from `%classification_default`
instead and confirm the failure-count assertions fail while the presence
assertions still pass, which proves the two are measuring different things.
Then the healthy path is run and confirmed to pass. Nothing tracked is modified
by the probe.

### The fixture that must keep an unregistered level

`tests/validate-filter-summary.sh`'s `vocabulary-rejection` scenario proves that
a matched line whose level is outside the vocabulary is dropped at the category
gate and counted under `excluded_other` rather than under any other cause. Its
fixture, `tests/fixtures/log-level-outside-vocabulary.txt`, carries `NOTICE` as
that outside level, so this drop takes the scenario's subject away from it.

The fix is to the fixture, not to the scenario: the rejected line's level token
is replaced with one that stays outside the vocabulary, and the expected
`excluded_other: 1` and the funnel identities are unchanged. The scenario keeps
asserting exactly what it asserted before, on a token that cannot be registered
out from under it.

The replacement token is `NOTAREALLEVEL`. It is chosen to be permanently safe
rather than merely absent today:

- It is a clearly invented token, not a severity name any producer uses, so no
  future issue can admit it to the vocabulary on producer evidence. A real but
  currently unregistered name such as `PANIC` or `VERBOSE` would put the
  scenario back in the same position the first time someone widens the list.
- It appears nowhere in `ltl` and nowhere in the statistics oracle's own level
  set, so registering it would be a deliberate act with nothing to recommend it.
- It is word characters only, so the Windchill Method Server format's `(\w+)`
  level slot still captures it and the line still matches its format. That
  matters: the scenario is about a line that matched and was then dropped at the
  gate, so a token that broke the match would silently convert the line from
  `excluded_other` into `lines_unmatched` and the scenario would assert the
  wrong cause while still looking plausible.
- It reads as what it is to anyone opening the fixture, which is the whole
  point of a fixture line that exists to be rejected.

Naming it in the fixture alone is not enough: the fixture is committed and
`git ls-files` confirms it is tracked, so the replacement lands in the same
commit as the vocabulary change, never after it.

### Other harnesses

| Harness | Why it is touched |
|---|---|
| `tests/validate-filter-summary.sh` | its `vocabulary-rejection` scenario asserts `excluded_other: 1` over a fixture whose outside level is `NOTICE`, which this drop registers. The fixture's token is replaced per the section above; the scenario's expected count and its funnel identities are unchanged |
| `tests/validate-format-detection.sh` | asserts `default_failure: category_bucket=^(?:ERROR\|FATAL\|CRITICAL)$` verbatim; fails until updated to D3's alternation |
| `tests/validate-category-names.sh` | its `unmapped-categories-keep-their-own-name` scenario loops over the levels in the shared fixture. D5 leaves that fixture alone, so the loop is unaffected. Per D6 the added levels have no descriptive-name entry, and asserting that they show their own names is a natural extension of that scenario over the new fixture |
| `tests/validate-summary-contribution-bar.sh` | `check_every_category_has_a_fill` sweeps the vocabulary out of the `ltl` source; no edit if D4's colours are used, and it is the check that catches a colour that does not resolve |
| `tests/validate-csv-output.sh` | reads `tests/csv-output/rules/stats-columns.tsv`; fails on a level column with no rule row |
| `tests/validate-explain.sh`, `tests/validate-doc-examples.sh` | guard the explain text and the documentation examples that D3 changes |
| `tests/validate-statistics-demand.sh`, `tests/validate-regression.sh`, `tests/capture-regression.sh` | read the existing fixture only, which D5 leaves untouched; listed so the drop confirms they are unaffected rather than assumes it |

## Acceptance criteria

Each criterion is triaged **before** implementation, per
`docs/test-driven-development.md` § Triage.

| # | Criterion | Triage | Method |
|---|---|---|---|
| AC1 | A run over the new fixture reports `LINES READ` equal to `LINES INCLUDED`: no line is discarded by the category gate. | assertable | `check_all_lines_included` in `tests/validate-log-level-vocabulary.sh`, new scenario |
| AC2 | Each of `CRITICAL`, `SEVERE`, `WARNING`, `NOTICE`, `ALERT`, `EMERGENCY`, `AUDIT` appears as its own row in the category table with a count greater than zero. | assertable | seven `check_level_present` assertions, same scenario |
| AC3 | A `CRITICAL` line is counted under `FAILURE CLASSIFIED`, not merely present in the category table. | assertable | new assertion reading `FAILURE CLASSIFIED` from the render |
| AC4 | `SEVERE`, `ALERT` and `EMERGENCY` lines are counted as failures, and `WARNING`, `NOTICE` and `AUDIT` lines are not. | assertable | two-arm comparison shaped like `check_error_rate_counts_fatal`, plus a run in which the only non-`INFO` lines are `WARNING`, `NOTICE` and `AUDIT` and `FAILURE CLASSIFIED` is zero |
| AC5 | `-V format-detection` prints the default failure rule as `^(?:ERROR\|FATAL\|CRITICAL\|SEVERE\|ALERT\|EMERGENCY)$`, and `docs/usage.md`, `docs/explain/classification.md` and `--explain classification` state the same set. | assertable | the verbatim pattern assertion in `tests/validate-format-detection.sh`, updated; `tests/validate-explain.sh` and `tests/validate-doc-examples.sh` over the prose |
| AC6 | Every added level resolves to a contribution-bar fill: no category in the vocabulary is left without one. | assertable | `check_every_category_has_a_fill` in `tests/validate-summary-contribution-bar.sh`, unchanged, run against the new vocabulary |
| AC7 | A STATS CSV written from a run carrying the added levels passes the structural validator: each new level column has a rule row in the `level` family. | assertable | `tests/validate-csv-output.sh` against the rules TSV |
| AC8 | The committed regression baseline `errrate-diagnostics-highlighted-failure-w160` is byte-identical after the change, and the existing `method-server-levels` scenario still passes with its six levels and its count of six. | assertable | `tests/validate-regression.sh` and the unchanged scenario in `tests/validate-log-level-vocabulary.sh` |
| AC9 | The added levels appear in the category table in severity order, with `AUDIT` after `INFO` and before `DEBUG`. | assertable | the rendered category table over the new fixture, read as ordered rows |
| AC10 | A line whose level is outside the vocabulary is still dropped at the category gate and counted under `excluded_other`, with the same expected count as before this change. | assertable | the `vocabulary-rejection` scenario of `tests/validate-filter-summary.sh`, unchanged, over the fixture whose rejected token has been replaced |
| AC11 | Each added level reads correctly as a coloured row in the rendered category table on a real terminal, including the two rows `WARNING` and `WARN` adjacent to each other. | unassertable by harness | `docs/test-driven-development.md` § Visual surfaces: the rendered output is looked at before the work is called done. Recorded as a known gap because no harness in this repository asserts that a rendered terminal surface reads correctly to a person; the general method is open research there |
| AC12 | Every assertion added here has been demonstrated to fail against a deliberately broken input before being trusted to pass. | assertable | the sabotage proof above, its output captured to the scratchpad and reported in the completion comment |

There is no criterion for the silence. D7 puts it outside this drop.

## Completion gate

The diff touches executable lines of `ltl` (`@log_levels`, `%colors`,
`%classification_default`, `$explain_classification_intuition`) and touches
`tests/validate-*.sh` plus a fixture a harness reads. Two rows of the scope test
in `docs/process/workflow.md` § 3 therefore apply and both require the same
thing:

- **Full harness suite**: required. Every `tests/validate-*.sh` exits 0 with
  assertions actually run, `CI=1 ./tests/validate-csv-output.sh` before
  `CI=1 ./tests/validate-statistics.sh`, each output captured once to the
  scratchpad and inspected there.
- **Before/after benchmark**: required. A `before` capture on the base commit
  before the first line of code, an `after` capture on the commit being merged
  with `$version_number` restored, compared on this machine in this session.

What the benchmark could plausibly move: nothing in the per-line path. The gate
stays one constant-time `exists` on `%log_level_set` whatever the array's
length. The array grows by fourteen entries, which costs the per-bucket loops in
`print_bar_graph()` and `write_aggregate_export()` fourteen extra hash tests per
bucket and `resolve_csv_column_family()` a longer linear scan per CSV column
name. Both are per bucket or per column, not per line. The benchmark is run
because the scope test requires it, and the expectation recorded here is no
measurable change; a metric worse by more than 5% is stop-and-investigate.

One thing worth saying plainly: six of the seven names appear nowhere in the
corpus, so the change is provably inert on every existing benchmark input. Two
committed fixtures are affected and no others: the new one this drop adds, and
`tests/fixtures/log-level-outside-vocabulary.txt`, whose rejected level token
`NOTICE` this drop registers and therefore replaces. The gate's value here is in
the new fixture's assertions, in the `vocabulary-rejection` scenario of
`tests/validate-filter-summary.sh` still reporting the same `excluded_other`
count, and in the regression baseline coming back unchanged.

## Release notes

One bullet, user-observable:

> Seven severity levels a supported log format can emit are now recognised
> instead of discarded: CRITICAL, SEVERE, WARNING, NOTICE, ALERT, EMERGENCY and
> AUDIT. Lines carrying them are counted and shown in the category table and the
> timeline. SEVERE, ALERT and EMERGENCY join ERROR, FATAL and CRITICAL as
> failures under the default classification rule. The STATS CSV header lists the
> new levels in severity order, so a consumer reading that file by column
> position rather than by name needs updating.

## Ordering

**#475 before #476** (log levels declared per format in the registry, with
unregistered levels reported at end of run). Both issue bodies state neither
blocks the other, and that holds: this work edits the existing global array,
while #476 moves level declarations into the format registry. The dependency
runs one way. If #476 landed first, these seven names would have to be declared
per format across eleven registry entries instead of added once to one array.
Doing this first is strictly cheaper, and #476 then inherits a complete
vocabulary to migrate rather than a known-incomplete one.

One fixture is shared across the boundary and is worth naming before #476 starts.
`tests/fixtures/log-level-outside-vocabulary.txt` is this repository's only
committed example of a line whose level is outside the vocabulary, so it is the
natural input for #476's own report scenario: a fixture carrying an unregistered
level is exactly what an end-of-run report naming the format and the levels has
to be asserted against. This drop replaces the fixture's rejected token with
`NOTAREALLEVEL` for the reason given in the harness plan, and that replacement
is what keeps the fixture usable by #476 rather than a name that a later
vocabulary edit could absorb. Whoever picks up #476 reads the fixture as it
stands after this drop, not as the issue body describes it.

One design choice would have coupled them: normalising the new names onto
existing categories as aliases, counting `WARNING` under `WARN` and `SEVERE`
under `FATAL`. That would pre-empt #476's first open question, whether an
unregistered level should be discarded or retained under a general category, and
it sits in tension with `features/463-friendly-log-level-category-names.md` D1,
whose premise is that a category name means the same thing whichever producer
emitted it. D1 of this document avoids it by adding real categories.

No relationship was found to the other issues in the next-up set. Nothing in
this blast radius touches a surface they own.

## Prototype

None indicated. No trigger in `prototype/README.md` fires: no data structure
changes shape, the per-line cost is unchanged, the added iterations are per
bucket and per CSV column rather than per line, and the verification method is
already demonstrated by `tests/validate-log-level-vocabulary.sh` and by the
sabotage proof `features/447-message-control-character-normalisation.md` § D6
recorded for `FATAL`.

## Sources

- `features/447-message-control-character-normalisation.md` § D6 (FATAL joins
  the log-level vocabulary): the worked precedent, the surfaces a category must
  occupy, and the sabotage proof.
- `features/395-wgm-client-log-format.md` § Log-category consistency: three of
  those surfaces and the record that no structural assertion binds them.
- `features/453-success-failure-classification-event-ledger.md` D13: why the
  error rate reads the bucket's classification failure counter rather than
  category names.
- `features/463-friendly-log-level-category-names.md` D1, R2: the
  descriptive-name lookup and why these levels get no entry.
- `features/448-category-summary-share-and-bar.md`: a new level inherits its
  bar from the colour it is already given, with no new table.
- `features/396-windchill-method-server-log4j-format.md`: the motivating
  format and its framework vocabulary.
- `tests/HARNESS-DESIGN.md` § Self-documenting assertions, § Proving a new
  assertion can fail, § Harnesses must fail on missing anchors, § Invocation
  coherence.
- `docs/test-driven-development.md` § Triage, § Visual surfaces.
- `docs/process/workflow.md` § 3: the completion-gate scope test.
