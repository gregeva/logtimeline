# Feature: log levels declared per format, and unregistered levels reported at end of run

## Overview

Someone runs `ltl` over a ThingWorx Edge C SDK log and reads the category table
to see what the device was doing. The file carries a handful of lines whose
level slot holds `START`, `AUTH` or `TRAFFIC_CONTROL`. Those tokens are not log
levels the tool recognises, so each line is matched against its format, then
rejected before it reaches any count. Nothing is printed. `LINES READ` exceeds
`LINES INCLUDED` by a number with no attribution, and the reader has no way to
learn that anything was dropped, let alone what.

That is the motivating consumer: a person who has no way to find out that the
tool threw data away. This drop does not give the lines back. It makes the loss
audible, and it puts the vocabulary each format emits where that format is
already described, so the next divergence between what a producer writes and
what the tool accepts is caught at startup rather than by accident.

Two things ship together, and they are two halves of one requirement. Each
registry entry declares the levels it emits, which gives the tool a statement of
what each producer is expected to write. And the levels seen but not registered
are collected during the read and reported once at the end of the run, naming
the format, the token and how many lines carried it.

## GitHub Issue

- #476 (BUG: log levels declared per format in the registry, with unregistered
  levels reported at end of run): the requirement.

## Requirements

- **R1**: Every registry entry states the log levels it emits. An entry that
  states nothing is taken to emit the standard severity set; an entry that
  states a list emits exactly that list.
- **R2**: The union of every entry's declared levels is exactly the recognised
  level vocabulary. A declared level absent from the global vocabulary fails
  the build, and so does a level named in a classification rule that no entry
  declares.
- **R3**: A level seen in the level position and not registered is collected
  during the read, with the format that produced it and a count of the lines
  that carried it.
- **R4**: At the end of the run the user is told, once per format, which
  unregistered levels that format produced, with a line count each, and that
  those lines were not counted.
- **R5**: The unregistered levels observed per file are reported in `-V` so a
  harness asserts a deterministic key rather than notice prose.
- **R6**: `ltl --help formats` states the levels each format declares.
- **R7**: An unregistered level is still rejected. `LINES READ`, `LINES
  INCLUDED`, the category table, the percentiles and every classification count
  are byte-identical to today on every input.

## The mechanism today

### One closed acceptor, several open producers

`read_and_process_logs()` decides which lines survive with a single global
membership test that does not know which format produced the value:

```perl
unless (exists $log_level_set{$category_bucket}) {				# this condition importantly only continues if the read/parsed log category is one of the ones defined
    $excluded_other++;
    next;
} elsif (!$csv_epoch_timestamp && $match_type == 13) {
```

`%log_level_set` is built once from the static `@log_levels` array in GLOBALS
(grep anchor `Defines the log level/type buckets`). The set is closed. The
patterns that fill `$category_bucket` are open, so the intersection is a
silent-drop path by construction: the gate cannot say what should have been
there, and it keeps no record of what it rejected, so nothing downstream can
report it.

Note the shape of that conditional. The vocabulary rejection is the **first arm
of a two-arm chain**, whose `elsif` handles the CSV timestamp parse for the
`csv` entry. That arm's own skip of an unparseable row sits inside it and
increments the same `$excluded_other`, which is why the counter pools two
unrelated causes. Any collection added here attaches to the vocabulary arm only:
written into the chain at the wrong point it would tally skipped CSV rows as
unregistered levels.

### Three producer shapes, not one

The issue speaks of "the level position" as if every format had one open word
slot. Three shapes exist, and the report has to read sensibly for each.

| Shape | Entries | What reaches the gate |
|---|---|---|
| Open word slot | The diagnostics entries: `mt1std` and `mt1gen` (`thingworx_standard`), `mt2` (`thingworx_rac_client`), `mt5` (`connection_server_json`), `mt7` (`tw_analytics_v2`), `mt8` (`tw_analytics_worker`), `mt10` (`connection_server_standard`), `mt10ir` (`integration_runtime_standard`), `mt11` (`tw_edge_c_sdk`), `mt17` (`windchill_method_server`), and the pin-only `mtvfy` (`classification_verification`) | Whatever word the producer wrote. `mt11` captures `^([^ ]+) `; `mt17` captures a word; `mtvfy` captures `level=([A-Z]+)` |
| Folded status | The seven access-family entries `mt3ts`, `mt12`, `mt9`, `mt19`, `mt20`, `mt3`, `mt4` | The `status_bucket` transform, `$status_code = $category_bucket; $category_bucket =~ s/(\d)\d{2}/$1xx/;`, folds a three-digit capture into `Nxx`. It spans `0xx` through `9xx`; only `1xx` to `5xx` are registered, so an out-of-range status is dropped |
| Mapped letter | `mt16` (`windchill_workgroup_manager`) | The `wgm_msgtype` transform, `$category_bucket = $wgm_msgtype_names{$category_bucket} // $category_bucket;`, maps ten letters into level names and **passes an unmapped letter through verbatim**, where the gate drops it. The report therefore has to name a bare letter and still read sensibly |

Two entries have no open slot at all. `mt6` (`java_gc_g1`) captures a closed
alternation of pause kinds from the pattern itself. The `csv` entry has no
level slot: both assembly branches assign `DATA` unconditionally, so it can
never trip the gate.

### Where the report belongs

`defer_notice()` pushes text onto `@deferred_notices`;
`flush_deferred_notices()` prints them to stderr and clears the list. The tail
of `read_and_process_logs()` already calls `flush_deferred_notices()` under the
comment "Notices raised while the read was running, held back so they did not
print into the progress line's row.", and then prints two notices of exactly
this shape: how many lines a numeric filter removed for carrying no value, and
the directories a recursive sweep could not open. This report is a third notice
at the same site.

### Where a declaration would be checked

`build_format_registry()` already runs the registry's executable self-tests over
every entry's samples, and a failure is a `die` naming the entry and the sub
that produced the fault:

```perl
die "ltl: format registry: entry '$spec->{name}' sample " . ($i + 1)
  . " does not match its own pattern (produced_by format_registry_specs(); the sample set is the entry's executable self-test):\n  $spec->{samples}[$i]\n"
```

Gates numbered 1 through 8 exist today. A declaration check is a further gate of
that family, using the same `die` mechanism and the same `produced_by` clause.

### The divergence this would have caught

`%classification_default` names a level the vocabulary does not carry:

```perl
my %classification_default = (
    failure => [ { category_bucket => '^(?:ERROR|FATAL|CRITICAL)$' } ],
);
```

`CRITICAL` is a failure name in the shipped classification rule and is absent
from `@log_levels`. Measured on a two-line Windchill Method Server fixture whose
only failure line is `CRITICAL`: `LINES READ 2`, `LINES INCLUDED 0`,
`FAILURE CLASSIFIED 0`, empty stderr, exit 0; `-V filter-summary` reports
`excluded_filter: 1, excluded_other: 1`. The line matched its format, was
classified a failure by the generated block, and was then dropped by the gate
before the failure counter could see it. #475 (severity levels a supported
format can emit are missing from the log-level array and are silently
discarded) closes that particular case by admitting `CRITICAL`; the build gate
in R2 above is what stops the next one.

## Corrections to the issue body

Recorded here because the issue body still carries them.

1. **"its display name if #463 lands" is wrong twice.** #463 (friendly
   descriptive names for log level categories in the summary table) is closed,
   and it landed with D1 (one global lookup, shared by every format) locked the
   opposite way from the issue's premise: one table, not a per-format
   declaration in the format registry, because a category name means the same
   thing whichever producer emitted it and the HTTP status families are common
   to every access entry. The issue's third open question therefore asks to
   reopen a locked decision rather than to decide a blank slate. D3 below
   settles it without reopening D1.

2. **"the only evidence being a discrepancy between two counters" understates
   what exists.** Since #503 (YAML aggregate export) `-V filter-summary` carries
   a dedicated `excluded_other: N` key, and `tests/validate-filter-summary.sh`
   has a `vocabulary-rejection` scenario over the committed fixture
   `tests/fixtures/log-level-outside-vocabulary.txt` asserting `excluded_other`
   is 1. It is a diagnostic surface rather than a user-facing one, and it pools
   the vocabulary gate with the unparseable-CSV-row skip so it names neither the
   level nor the format, but it exists, and this work keeps that scenario's
   contract intact.

3. **"the level position" as though every format had one open slot.** Three
   producer shapes exist, set out in § *The mechanism today* above. The access
   family was read as closed and is not: its folded-status slot spans `0xx` to
   `9xx` of which five values are registered. Measured on a six-line synthetic
   access fixture carrying statuses 200, 200, 404, 600, 000 and 999 with
   durations 10ms, 20ms, 15ms, 9000ms, 8000ms and 7000ms: `LINES READ 6`,
   `LINES INCLUDED 3`, and the render reports P50, P99 and P99.9 all at 20ms.
   A file whose worst request took nine seconds renders as a clean latency
   profile.

4. **`features/447-message-control-character-normalisation.md` § D6's fourth
   surface has moved.** D6's table says `FATAL` joins an `ERROR|5xx|4xx` regex
   in `normalize_data_for_output()`. That regex no longer exists: #453
   (per-variant success/failure classification and an event-ledger property in
   the format registry) D13 (one classification surface; rendering reads
   counters, never classifies) replaced it with a read of the bucket failure
   counter. The fourth surface a new level must occupy today is the
   classification criteria.

5. **#412 (notices surface, a structured pre-chart render area) is named as
   "the likely home", and the report does not depend on it.** `defer_notice()`
   and `flush_deferred_notices()` already ship, and the tail of
   `read_and_process_logs()` already prints two notices of this shape. The notices
   surface will re-home this notice when it re-homes every other one.

6. **The issue's reading of `features/395-wgm-client-log-format.md` §
   Log-category consistency is not what that section says.** The issue cites it
   for "nothing exposes the vocabulary outside the Perl source, so no structural
   check can assert it is complete". Read in full, the assertion that section
   finds missing is that every member of `@log_levels` has a CSV rules row, a
   vocabulary-to-rules-row coverage check, not a check that the vocabulary
   covers what formats emit. Its own proposed fix is still unbuilt and still
   correct for what it describes, and is not this work.

7. **No sub name, path or artifact the issue cites is wrong.** It names none by
   name, and both its descriptions ("one statically defined array of recognised
   log levels", "the log-format registry") match the tree.

## Locked decisions

### D1: An unregistered level is still rejected; this drop captures and reports it, and retains nothing

The gate keeps today's behaviour exactly. A line whose level is not registered
is skipped and counted in `$excluded_other`, as it is today. What changes is
that the token, the format that produced it and the line count are kept, and
reported once at the end of the run.

The requirement is to make the loss audible, not to change what the tool counts.
Retaining the lines, under their own name or under a catch-all category, is a
user-observable change to `LINES INCLUDED`, to the category table's composition,
to the percentiles and to every committed reference render. That deserves its
own decision, its own release note and its own measured drop; it is not smuggled
in behind a reporting feature.

**Two consequences are known, are not fixed here, and are stated plainly so the
record does not imply otherwise.**

- **A request to show only failures can still be answered "there are none" when
  a failure is present.** The vocabulary gate runs before the outcome-filter
  block in the same loop, so a line dropped at the gate never reaches the
  filter. Measured on a two-line fixture whose only failure line is `CRITICAL`:
  `-if` reports `LINES READ 2`, `LINES INCLUDED 0`, empty stderr, exit 0, and
  `-V filter-summary` shows `excluded_filter: 1, excluded_other: 1`. After this
  drop the user gets a report telling them a `CRITICAL` line was dropped; the
  result set is still empty.
- **A dropped line takes its duration out of the percentiles.** Occurrence and
  heatmap accumulation both sit below the gate in the same read loop. The
  six-line access measurement in correction 3 above is the demonstration: the
  nine-second request is absent from P99.9. After this drop the report says the
  statuses were dropped; the latency distribution is still the one computed from
  the survivors.

Both land on the same mechanism and both are real. Closing either is a
retention change, which is D1's excluded scope.

*Architect decision, 2026-09-12.*

### D2: Global union: each entry declares, the build unions, the gate is unchanged

Each registry entry declares the levels it emits. `build_format_registry()`
unions every declaration into the existing global level set. The per-line gate
in `read_and_process_logs()` is untouched: it stays one constant-time `exists`
on one global hash.

There is no per-format gate. A level legitimate for one format and seen in
another is accepted, exactly as today. That added strictness is the only part of
this design that would cost hot-path time, and it is not the requirement: the
requirement is that levels are declared where the format is described, and that
what is not declared is reported.

The declaration buys three things at zero per-line cost: the build gate in D5
below, the `--help formats` surface in D8, and the ability for the report to
name the format alongside the token.

**No prototype trigger fires.** Against the four triggers in
`prototype/README.md`: (a) a new or changed data model: the registry entry
schema gains one key and the live entry one slot, both read once at startup and
never per line, which is a startup structure and not a stored data model; (b) a
new per-line hot-path cost, none: the accept path is byte-identical, and the
only new work is on the reject branch, which runs zero times on every corpus
measured; (c) frequency times cost, where the reject branch's frequency is zero on
the corpora and its cost is one hash store; (d) an unknown verification method, where
the method is known and demonstrated, since `tests/validate-log-level-vocabulary.sh`
already asserts this invariant from a rendered surface, `tests/validate-filter-summary.sh`
already asserts the discard counter, and the notice is the same shape as two
notices existing harnesses already read.

*Architect decision, 2026-09-12.*

### D3: Only membership travels per format; colour, display order and naming stay global

The per-entry declaration carries membership and nothing else.

- **Colour stays global.** `%colors` is one table. `ERROR` is red whoever
  emitted it, and the argument #463 D1 (one global lookup shared by every format)
  makes against per-format declaration, that the same rows are duplicated across
  every access entry and free to drift apart, applies to colour without
  modification.
- **Display order stays global.** One category table renders every format's
  categories together, so the order is a property of the table, not of any
  producer.
- **Descriptive names stay global.** #463 D1 (one global lookup shared by every
  format) is **not reopened**. `features/463-friendly-log-level-category-names.md`
  gains one boundary sentence saying membership is declared per format while
  naming stays global, and D1 itself is unchanged.
- **Failure status stays where #453 (per-variant success/failure classification
  and an event-ledger property in the format registry) put it.** Whether a level
  counts toward the error rate already travels per format, in each entry's
  `classification` key, resolved against `%classification_default` at build
  time. That one has travelled already and is not moved again here.

*Decision by the architect's delegate, 2026-09-12, within the architect's
instruction that membership only travels.*

### D4: The declaration follows the classification shape: absent inherits the standard set, present replaces it

The new per-entry key takes the shape #453 D3 (global default classification,
overridden per entry by replacement) already locked for classification on the
same structure. An entry that declares nothing inherits the standard severity
set. An entry that declares a list replaces it entirely.

The registry gains no new idiom: a reader who knows how an entry's classification
resolves already knows how its levels resolve, and the user-facing sentence in
`docs/usage.md` and `ltl --help formats` about classification ("a format that
declares nothing inherits the default ... a format that declares one or both
outcomes replaces the default") reads the same way for levels.

Every entry whose declaration is not the plain inherited default states what it
declares and why:

| Entry (name, slug) | Declares | Why |
|---|---|---|
| `mt6` (`java_gc_g1`) | `Pause Young`, `Pause Full`, `Pause Remark`, `Pause Cleanup`, `To-space exhausted`, `Using G1` | Its categories are pause kinds, not severities. It replaces the standard set outright, and its declaration is exactly the closed alternation its own pattern captures |
| The seven access entries `mt3ts`, `mt12`, `mt9`, `mt19`, `mt20`, `mt3`, `mt4` | `1xx`, `2xx`, `3xx`, `4xx`, `5xx` | The producer writes a status code and the `status_bucket` transform folds it to a family. The five registered families are what the entry declares; `0xx` and `6xx` through `9xx` stay undeclared and are therefore reported when seen, which is the whole point of the declaration on this family |
| `mt16` (`windchill_workgroup_manager`) | The ten names the letter map produces: `CONFIG`, `DEBUG`, `ERROR`, `FINISH`, `INFO`, `START`, `TRACE`, `WARN`, `CREATE`, `DESTROY` | The producer writes a letter, not a level; the `wgm_msgtype` transform maps it. What the entry emits into `$category_bucket` is the mapped name, so those are the levels it declares. An unmapped letter passes through verbatim and is therefore undeclared by construction, which is the correct outcome |
| `csv` | `DATA` | It has no level slot: both CSV assembly branches assign `DATA` unconditionally, so `DATA` is the one and only level it can ever emit |
| `mtvfy` (`classification_verification`) | `INFO`, `WARN`, `ERROR`, `FATAL` | The pin-only verification producer captures `level=([A-Z]+)`. It declares the levels its samples and the fixture that exercises it carry, so the declaration describes the entry rather than accidentally widening the union. Note the known limit below |
| `mt11` (`tw_edge_c_sdk`) | `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FORCE`, `AUDIT` | The Edge C SDK writes `FORCE` and `AUDIT` alongside the standard severities, so it declares rather than inherits. `AUDIT` is admitted to the vocabulary by #475 (severity levels a supported format can emit are missing from the log-level array and are silently discarded); this entry's declaration is the record of which producer emits it. It does **not** declare `START`, `AUTH` or `TRAFFIC_CONTROL`; see D9 |

Every other entry declares nothing and inherits the standard severity set.

**Known limit, stated so it is not discovered later.** The build gate in D5
checks declarations against each entry's samples where samples exist. It can
say nothing useful about the `csv` entry, which has no pattern and no samples
that reach the level slot, nor about `mtvfy`, whose four samples do not span its
declaration. Those two entries are exactly where a wrong declaration would go
unnoticed, and the union check in D5 is what still constrains them.

*Decision by the architect's delegate, 2026-09-12, following the declaration
shape the architect named.*

### D5: One build gate over two directions: declarations are in the vocabulary, and classified names are declared

A further gate in `build_format_registry()`, in the family of the gates already
there and using the same `die` mechanism with a `produced_by` clause, asserts
two things.

- **Every declared level is a member of the global vocabulary.** An entry that
  declares a level the vocabulary does not carry fails the build, naming the
  entry and the level. This is what makes the union in D2 a statement rather
  than a side effect: the union cannot silently enlarge the vocabulary, so a
  declaration and the vocabulary can never drift apart in the direction where a
  level is declared and then dropped.
- **Every level named in a classification criterion is a member of the union.**
  Names read out of `%classification_default` and out of every entry's own
  `classification` key must each be declared by at least one entry. This is the
  cross-check that would have caught `CRITICAL` at startup instead of leaving it
  to be found by a run reporting `FAILURE CLASSIFIED 0` on a file whose only
  failure line was present.

The union of every entry's declarations must equal the recognised vocabulary at
the moment this work lands, which is what makes both directions checkable rather
than one.

A criterion pattern is a regex, so the names are read from the literal
alternations the criteria use, the same shape the registry already compiles into
literal sets. A criterion that is not a literal alternation over
`category_bucket` is outside what the gate can read and is skipped rather than
guessed at; no shipped criterion is of that kind today.

Cost: a handful of hash lookups per entry at startup, in a build that already
runs eight gates over every sample of every entry. Nothing per line.

*Architect decision, 2026-09-12, with the two directions and the union equality
as the architect stated them.*

### Amendment of 2026-09-13: the vocabulary is the global list plus what the formats declare

The architect's direction, given in dialog on 2026-09-13, replaces the
inheritance and gate framing above. It supersedes R1, R2, D4 and D5 where they
differ; the text of those sections is kept as the record of what was planned.

- **A format may declare levels or not.** Nothing is inferred from an entry that
  declares nothing. There is no "standard severity set" distinct from the global
  list: the global list is what the tool works from today and it stays the base.
- **The vocabulary a run uses is the global list combined with the levels the
  formats declare.** A declared level joins the vocabulary; it does not have to
  already be a member of the global list, and the global list does not have to
  be covered by declarations. R2's equality, D5's "every declared level is a
  member of the global vocabulary" direction and its union equality are dropped.
  What remains of D5 is the classification cross-check: a level named in a
  classification criterion that is neither in the global list nor declared by
  any entry fails the build, naming it, because that is the case that produced
  the `CRITICAL` divergence.
- **D4's table stands as the list of what each declaring entry adds**, read as
  additions rather than replacements. "Every other entry declares nothing and
  inherits the standard severity set" becomes "every other entry declares
  nothing". `--help formats` (D8) states the declared levels for an entry that
  declares any and says nothing about levels for one that does not.
- **Acceptance criteria.** AC6 (a declaration outside the global vocabulary
  fails the build) and AC8 (the union equals the vocabulary) fall. AC7 is
  restated: a level named in a classification criterion that is in neither the
  global list nor any declaration fails the build, naming it. AC9's "an entry
  that inherits says so" becomes "an entry that declares nothing shows no level
  line". Every other criterion stands.
- **When a declaration joins the vocabulary: at detection, not at build.** The
  architect's direction of 2026-09-13, given with its reason: with a hundred
  defined formats, their levels should not all be loaded all of the time, only
  once a format has been detected. So the global list is loaded up front, and a
  format's declared levels are added to the vocabulary set at the moment that
  format is detected for a file. D2's "the build unions every declaration into
  the existing global level set" is superseded on that one point; the rest of
  D2 stands: the per-line gate stays one constant-time `exists` on one global
  hash, and there is no per-format gate. The set only ever grows during a run,
  so a file read under one format is not affected by a later detection, and
  the classification cross-check that remains of D5 is evaluated over the
  global list plus every registry declaration, since it is a property of the
  registry rather than of a run.

### D6: One report line per format, each token with its line count, always printed

At the end of the run, one line per format that produced unregistered levels,
listing each token with the number of lines that carried it, and saying those
lines were not counted. It is raised through `defer_notice()` and printed by the
existing `flush_deferred_notices()` call at the tail of
`read_and_process_logs()`, beside the numeric-filter and unreadable-directory
notices, with the same `Note:` shape.

**It always prints.** It is a behavioural notice, and `--disable-progress`
suppresses progress indicators only.

Counts are what make the loss legible. "2 lines" reads as a rounding error and
"2,431 lines" reads as a problem, and the reader cannot tell which they have
without the number.

**A file whose every matched line carries an unregistered level is not a
separate, louder condition.** The count line already says it: a reader who sees
the format's whole matched population in the report has been told. A second
notice shape for the same fact would have to decide a threshold, and there is no
threshold to decide.

**The collection attaches to the vocabulary arm only.** That `unless` is the
first arm of a chain whose `elsif` handles the unparseable CSV timestamp, so a
collection written at the wrong point in the chain would tally CSV rows as
unregistered levels.

One wording constraint from the three producer shapes: the token may be a level
word (`SEVERE`), a folded status (`6xx`) or a Workgroup Manager letter (`Q`).
The line names the format and the raw token, so all three read sensibly to
someone looking at the file the tool just read.

*Architect decision, 2026-09-12.*

### D7: A new `-V` key under `format-detection`; `excluded_other` is untouched

The observed unregistered levels are reported per file as a new key inside the
existing `format-detection` per-file `file:` block, so the harness asserts a
deterministic key rather than notice prose. The `format-detection` section
already owns per-file format facts, which is what this is.

`excluded_other` in `filter-summary` stays exactly as it is, and so does its
cause list in `features/503-yaml-aggregate-export.md` § *`-V filter-summary`
section contract*. Splitting a dedicated vocabulary cause out of it would be an
addition and therefore non-breaking, but it would reword a contract two
harnesses read and buys nothing this key does not already give.

The `vocabulary-rejection` scenario in `tests/validate-filter-summary.sh`, which
asserts `excluded_other` is 1 over `tests/fixtures/log-level-outside-vocabulary.txt`,
keeps its contract unchanged.

*Architect decision, 2026-09-12.*

### D8: `ltl --help formats` states the levels each format declares

`print_help_formats()` renders one row per user-facing format through
`help_opt()`, stating the event-ledger property and how the format classifies.
It gains the declared levels in the same row, read from the compiled registry
the listing is already built from ("build_format_registry() unless
%format_registry_spec", so the listing is read from the same self-validated
specs).

Two shapes the renderer already has and this follows. A family is listed under
one heading with the property its members share stated once, so the seven access
entries state their five status families once rather than seven times. And an
entry that inherits says it inherits rather than restating the list, exactly as
the classification rows do.

The pin-only verification entry stays out of the listing: `print_help_formats()`
already skips an entry carrying `verification`, and this adds no reason to
change that.

No new CLI option is implied, so there is no `print_help()` option row and no
`docs/usage.md` option row. `docs/usage.md` § *Log formats and classification*
gains a sentence naming the levels as one of the things the listing states, so
`--help` and `docs/usage.md` continue to agree.

One thing worth stating because it changes what the assertion in AC9 is worth:
**the body of this listing is almost entirely unasserted today.** The only
assertion over it is a negative one in `tests/validate-classification-states.sh`,
that the verification-only entry never appears. `tests/validate-help-content.sh`
covers option-row agreement between the option table, `print_help()` and
`docs/usage.md`, not the content of `--help formats`. So the levels assertion in
AC9 is a new positive assertion over that surface rather than an extension of an
existing one.

*Architect decision, 2026-09-12.*

### D9: The Edge C SDK tokens are the first real-data case the report surfaces

The Edge C SDK corpus files emit `START`, `AUTH` and `TRAFFIC_CONTROL` in the
level position, one or two lines each. #475 declined to admit them to the
vocabulary, on the ground that they are startup and control messages occupying
the level slot rather than severities, and naming them as categories would
assert that they are severities.

`mt11` (`tw_edge_c_sdk`) therefore declares `TRACE`, `DEBUG`, `INFO`, `WARN`,
`ERROR`, `FORCE` and `AUDIT`, and declares none of those three. They are the
reason the report exists: a mechanism that can name a token without promoting it
to a category.

**One of the three is not dropped, and the declaration is what makes that
visible.** `START` is already a member of the global vocabulary, put there by
the Workgroup Manager letter map, which maps its `S` msgtype to `START`.
Measured on a four-line synthetic fixture in the Edge C SDK line shape carrying
`START`, `AUTH`, `TRAFFIC_CONTROL` and `INFO`: `lines_read: 4`,
`excluded_other: 2`, `lines_included: 2`, with `format: tw_edge_c_sdk` and
`matched_lines: 4`. So `AUTH` and `TRAFFIC_CONTROL` are dropped and reported;
`START` is silently counted as a category of a format that does not emit it as
one, because the global union accepts any member whoever declared it.

That is the global union of D2 behaving exactly as designed, and it is the case
a per-format gate would catch and this design does not. It is recorded here as a
known limit rather than fixed: closing it means checking the winning entry's own
set on the accept path of every matched line, which is the hot-path cost D2
excludes. The declaration makes the condition legible for the first time, which
is what lets a later issue decide it on evidence.

*Architect decision, 2026-09-12.*

### D10: The decisions live in this document

No feature doc owned #476. This one does. `features/log-format-registry.md`,
the registry's system of record, gains a forward pointer to it in the list where
it keeps per-drop pointers, and `features/463-friendly-log-level-category-names.md`
gains the boundary sentence D3 names. Neither grows a second subject.

*Decision by the architect's delegate, 2026-09-12.*

## The registry spec change

**The new per-entry key.** One key in each entry of `format_registry_specs()`,
holding the list of levels that entry emits. Absent means the standard severity
set; present replaces it (D4).

**Its default.** Resolved once in `build_format_registry()`, at the same point
the classification default is resolved per entry, so every compiled entry
carries a fully resolved level list and nothing consults the default after
build.

**Its live slot.** One new `FR_*` constant on the end of the contiguous numbered
block (the block runs to `FR_CLS_BOTH => 28` today, so the new slot is the next
integer). No existing slot is renumbered.

**Its build gate.** The two-direction check of D5, in
`build_format_registry()`, alongside the gates already there, failing the build
with a `die` naming the entry, the level and the sub that produced the fault.

**Its union.** `build_format_registry()` unions every resolved declaration; the
result is asserted equal to the global level set rather than allowed to define
it (D5). `@log_levels` keeps its other three jobs unchanged: display order,
highlight pairing of each level with its `-HL` twin, and the non-level members
`err-rate`, `msg-rate` and `empty` that every consumer excludes by regex. Those
three are not levels any producer emits and are outside every declaration.

## The report contract

One line per format, raised through `defer_notice()` during the read and printed
by `flush_deferred_notices()` at the tail of `read_and_process_logs()`, on
stderr, with the `Note:` prefix the neighbouring notices use. Each line names
the format, and each unregistered token it produced with the number of lines
that carried it, and states that those lines were not counted. Always printed.

No line is emitted for a format that produced no unregistered level, and no run
that lost nothing prints anything, which is every run over every corpus measured
today.

The collection is a new accumulator beside `$excluded_other`, which is a bare
scalar with no companion structure today. It tracks an observation count per
`(format, token)` pair, and both the report and the `-V` key are gated on that
count being greater than zero rather than on a key being defined, per CLAUDE.md
§ *Before writing or changing code*.

## The `-V` section contract

**Addition to `features/log-format-registry.md` § `-V format-detection`
section-contract.** Additive, per `tests/HARNESS-DESIGN.md` § *Stability
contract*; nothing is renamed and nothing is removed.

Per-file key, inside each `file:` block, two-space indent, emitted by
`emit_format_detection_verbose()` beside `matched_lines:` and `unmatched_lines:`:

```
  unregistered_levels: TOKEN=N,TOKEN=N,...|-
```

- Each entry is a raw token exactly as it reached the category gate, and the
  number of lines of this file that carried it.
- Order is descending by count, and by token ascending within an equal count, so
  the value is deterministic across runs on the same input.
- The literal `-` when the file produced none, which is every file in the
  current corpora. The key is always emitted, so a harness asserting it can
  distinguish "none observed" from "the key is gone", which is what
  `tests/HARNESS-DESIGN.md` § *Harnesses must fail on missing anchors* requires.
- The format that produced the tokens is the file's own `format:` key in the
  same block, so it is not repeated here.

`emit_format_detection_verbose()` emits the per-file key set from two branches,
one for a file with detection data and one placeholder branch for a file without
it, which emits the same keys with `-` and `0` values. The new key is added to
**both**, or a file with no detection data loses it and a harness asserting it
per file fails on the wrong cause.

The consumer is `tests/validate-format-detection.sh`, updated in the same commit
as the key, and run to see it assert.

## Surfaces touched

### `ltl`

| Surface | What changes |
|---|---|
| `format_registry_specs()` | One new key per entry that declares; the entries in D4's table state theirs, every other entry inherits |
| `build_format_registry()` | Resolves the declaration per entry against the standard set, unions the result, assigns the new slot, and runs the D5 two-direction gate |
| The `FR_*` constant block | One new slot on the end; no renumbering |
| `read_and_process_logs()`, the category gate | The vocabulary arm of the conditional chain gains the collection of the rejected token against the bound entry. `$excluded_other++` and `next` are unchanged; the accept path is untouched |
| `read_and_process_logs()`, the notice block at the tail | The report of D6, beside the numeric-filter and unreadable-directory notices |
| `emit_format_detection_verbose()` | The per-file `unregistered_levels:` key of the section contract above |
| `print_help_formats()` | The declared levels per format and per family, per D8 |

Unchanged and named so the drop confirms it rather than assumes it: `%colors`,
`%category_display_names` and `category_display_name()`, `%classification_default`
and every entry's `classification` key, `resolve_csv_column_family()`,
`normalize_data_for_output()`, `print_summary_table()`,
`write_aggregate_export()`, and `tests/csv-output/rules/stats-columns.tsv`. No
level is admitted or removed by this work, so no surface a level occupies moves.

### Harnesses

| Harness | Why it is touched |
|---|---|
| `tests/validate-format-detection.sh` | The consumer of the `format-detection` contract; asserts the new per-file key, both its populated and its `-` form |
| `tests/validate-log-level-vocabulary.sh` | The harness that owns this invariant; gains the report scenario and the byte-identical-counts assertion |
| `tests/validate-format-registry.sh` | Consumer of the `format-registry` contract. No key changes there, so it is run to confirm it is unaffected |
| `tests/validate-filter-summary.sh` | Its `vocabulary-rejection` scenario must keep asserting `excluded_other` is 1 over the same fixture, unchanged, per D7 |
| `tests/validate-help-content.sh` | Option-row agreement between the option table, `print_help()` and `docs/usage.md`. No option is added, so it is run to confirm it is unaffected |
| `tests/validate-classification-states.sh` | Holds the one existing assertion over `--help formats`, that the verification-only entry never appears there. D8 adds text to that listing, so this is run to see it still assert |
| `tests/validate-csv-output.sh` | No new level, so no new rules row. Run to confirm |
| `tests/validate-regression.sh` | The committed reference renders capture stdout; the report is stderr-only and no count moves, so they must come back byte-identical |

### Feature docs and user documentation

| Document | What changes |
|---|---|
| `features/476-per-format-log-level-declarations.md` | This document: the owning record |
| `features/log-format-registry.md` | The per-file key added to its `-V format-detection` section contract; the per-entry declaration added to § *Format Definition Properties*; a forward pointer to this document in the list where it keeps per-drop pointers |
| `features/463-friendly-log-level-category-names.md` | One boundary sentence: membership is declared per format while naming stays global. D1 itself is unchanged |
| `docs/usage.md` § *Log formats and classification* | A sentence naming the declared levels as one of the things `--help formats` states, so the two agree |
| `docs/explain/` | No change. The explain pages carry classification reasoning and percentile reasoning, neither of which this touches |

## Harness plan

### `tests/validate-log-level-vocabulary.sh`: the owning harness

A new scenario over `tests/fixtures/log-level-outside-vocabulary.txt`, the
committed three-line fixture (`git ls-files` confirms it is tracked) whose one
rejected line is the subject. #475 replaces that line's token with one that
stays outside the vocabulary permanently, and this scenario reads the same
fixture after that replacement.

- The report reaches stderr, names the format that produced the token, names the
  token, and carries the line count.
- The report is present when `--disable-progress` is given, since a behavioural
  notice is never suppressed by it.
- `LINES READ` and `LINES INCLUDED` over that fixture are what they are today,
  which is the assertion that D1 retained nothing.
- The existing `method-server-levels` scenario is left exactly as it is and must
  keep passing.

### `tests/validate-format-detection.sh`

- The per-file `unregistered_levels:` key carries the token and count for the
  file that has one.
- The same key reads `-` for a file that has none.

Both forms are asserted, because a key that is only ever seen in one state
cannot distinguish an absent key from an empty one.

### Assertion documentation

Every new assertion carries `asserts`, `produced_by` naming the sub in `ltl`
rather than a line, and `contract` pointing at this document's decision by
subject, per `tests/HARNESS-DESIGN.md` § *Self-documenting assertions*. Every
scenario invoking `ltl` includes the runtime-warning check from
`tests/lib/runtime-warnings.sh`. Each `ltl` invocation is shaped to the
assertion that reads it, on the smallest fixture carrying the signal, with
everything unread switched off (`-bs 1440 -oe` for the detection assertions),
per `tests/HARNESS-DESIGN.md` § *Invocation coherence*.

### Sabotage proof

Per `tests/HARNESS-DESIGN.md` § *Proving a new assertion can fail*, every new
assertion is demonstrated to fail before it is trusted to pass. The method: take
a copy of `ltl` in the scratchpad, suppress the collection at the gate, and
confirm the report assertions fail naming the missing token while the
count assertions still pass, which proves the two are measuring different
things. Then separately declare a level on an entry that the vocabulary does not
carry and confirm the build gate dies naming the entry and the level; and name a
level in a classification criterion that no entry declares and confirm the gate
dies on the other direction. Then run the healthy path and confirm it passes.
Nothing tracked is modified by the probe.

## Acceptance criteria

Each criterion is triaged **before** implementation, per
`docs/test-driven-development.md` § *Triage*.

| # | Criterion | Triage | Method |
|---|---|---|---|
| AC1 | A run over a file carrying an unregistered level prints a report on stderr naming the format, the token and the number of lines that carried it. | assertable | New scenario in `tests/validate-log-level-vocabulary.sh` over `tests/fixtures/log-level-outside-vocabulary.txt` |
| AC2 | The report prints when `--disable-progress` is given. | assertable | Same scenario; every harness invocation already passes `--disable-progress`, so the report is read from that run |
| AC3 | `LINES READ`, `LINES INCLUDED` and the category table over that fixture are what they are before the change: nothing is retained. | assertable | Same scenario, asserting the counts directly; and `tests/validate-regression.sh` returning the committed reference renders byte-identical |
| AC4 | `-V format-detection` reports the file's unregistered levels with counts in the per-file block, and reports `-` for a file that has none. | assertable | Two assertions in `tests/validate-format-detection.sh`, one per form |
| AC5 | `excluded_other` over that fixture is unchanged, and `tests/validate-filter-summary.sh`'s `vocabulary-rejection` scenario passes with its existing expected count. | assertable | The existing scenario, run unchanged |
| AC6 | An entry declaring a level the global vocabulary does not carry fails the build, naming the entry and the level. | assertable | Sabotage probe against a scratchpad copy of `ltl`; the gate dies and the message names both |
| AC7 | A level named in `%classification_default` or in an entry's own `classification` key that no entry declares fails the build, naming what is undeclared. | assertable | Sabotage probe against a scratchpad copy; this is the check that would have caught the `CRITICAL` divergence |
| AC8 | The union of every entry's declared levels equals the recognised vocabulary when this work lands. | assertable | The same build gate asserts it; a run of `ltl` on any input exits 0, which is the assertion, since the gate runs at every startup |
| AC9 | `ltl --help formats` states the levels each format declares, the access family states its five status families once, and an entry that inherits says so rather than restating the list. | assertable | A new scenario reading the `--help formats` render in `tests/validate-log-level-vocabulary.sh`. It is a new positive assertion over that listing, which carries only a negative one today (D8) |
| AC10 | The Edge C SDK entry declares `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FORCE` and `AUDIT`, and a file carrying `AUTH` and `TRAFFIC_CONTROL` in the level position has each reported with its count. `START` is not reported, because it is a member of the global vocabulary (D9). | assertable | A fixture in the Edge C SDK line shape, with neutral placeholder messages, in the vocabulary harness, asserting the two reported tokens and the absence of the third |
| AC11 | The report reads sensibly for all three producer shapes: a level word, a folded status, and an unmapped Workgroup Manager letter. | unassertable by harness | `docs/test-driven-development.md` § *Visual surfaces*: the rendered report is read on real input for each shape before the work is called done. Recorded as a known gap, because no harness here asserts that a rendered line reads correctly to a person; the general method is open research in this repository |
| AC12 | Every assertion added here has been demonstrated to fail against a deliberately broken input before being trusted to pass. | assertable | The sabotage proof above, its output captured once to the scratchpad and reported in the completion comment |

There is no criterion for admitting a level, for retaining a dropped line, or
for the two consequences D1 names as out of scope.

## Completion gate

Scope test per `docs/process/workflow.md` § 3, applied to the diff. The diff
touches executable lines of `ltl` (the registry specs, `build_format_registry()`,
the category gate, the notice block, `emit_format_detection_verbose()`,
`print_help_formats()`) and touches `tests/validate-*.sh` plus a fixture a
harness reads. Two rows of the scope table apply and both require the same
thing.

- **Full harness suite**: required. Every `tests/validate-*.sh` exits 0 with
  assertions actually run, `CI=1 ./tests/validate-csv-output.sh` before
  `CI=1 ./tests/validate-statistics.sh`, each output captured once to the
  scratchpad and inspected there.
- **Before/after benchmark**: required. A `before` capture on the base commit
  before the first line of code, an `after` capture on the commit being merged
  with `$version_number` restored, compared on this machine in this session.

What the benchmark could plausibly move: nothing on the per-line accept path,
which is byte-identical. The gate stays one constant-time `exists` on one global
hash. New work exists only on the reject branch, which runs zero times on every
corpus measured, and at startup, where the registry build gains a per-entry
resolution and a gate of the same class as the eight it already runs over every
sample of every entry. The expectation recorded here is no measurable change; a
metric worse by more than 5% is stop-and-investigate.

## Release notes

One bullet, user-observable:

> A log level a format emits but ltl does not recognise is now reported at the
> end of the run: one line per format, naming each unrecognised level and how
> many lines carried it. Those lines are still not counted, which the report
> says. Each format now declares the levels it emits, and `--help formats`
> lists them.

## Ordering and blocking

**#475 lands first, and #476 builds on the enlarged list.** #475 (severity
levels a supported format can emit are missing from the log-level array and are
silently discarded) is the narrow list edit; this work declares per format what
that list then contains, and its build gate asserts the union equals the
vocabulary at the moment it lands. Doing it the other way round would mean
declaring seven names across the entries that emit them rather than adding them
once to one array, and would leave the union check asserting against a
knowingly incomplete vocabulary.

The native edge is wanted. It is recorded with:

```bash
BLOCKER_ID=$(gh api repos/{owner}/{repo}/issues/475 --jq '.id')
gh api --method POST repos/{owner}/{repo}/issues/476/dependencies/blocked_by -F issue_id="$BLOCKER_ID"
```

and the issue body carries the agreeing `Blocked by #475` line, per
`docs/process/issues.md` § *Blocking relationships*.

**The shared fixture.** `tests/fixtures/log-level-outside-vocabulary.txt` is
three lines, one of which exists to be rejected at the category gate. #475
replaces that line's token with one that stays outside the vocabulary
permanently, because the token it carries today is one #475 registers. This
work's report scenario reads the same fixture after that replacement, and
`tests/validate-filter-summary.sh`'s `vocabulary-rejection` scenario keeps its
existing expected count over it throughout.

**No other issue in the next-up set shares a surface.** #528 (a transform
assigning arithmetic into a shared record lexical enlarges retained durations)
and #478 (highlight bookkeeping evaluated on the hot path when no highlight is
active) both change hot-path work in the same read loop, and would have
interacted had this work put anything on the accept path; under the global union
of D2 it does not, so they are independent. #472 (highlight bin-counter
sub-stores absent from `-V` telemetry), #527 (the statistics harness leaves an
aggregate export in the repository root) and #482 (two `-udm` specs with the
same name and aggregation but different transforms collapse into one column)
share no surface with the level vocabulary.

**#412** (notices surface, a structured pre-chart render area) is open and in
backlog. This report does not depend on it and does not block it: it is a notice
of the shape #412 will re-home along with every other notice.

**#387** (user-configurable YAML format definitions with a config folder and
file) is open and in backlog. Once formats are user-definable, the per-entry
level declaration is part of what a user defines, so this work landing first
means #387 inherits a settled schema.

## Prototype

None indicated. D2 sets out each of the four triggers in `prototype/README.md`
against this work and none fires: no stored data model changes shape, the
per-line accept path is byte-identical, the only new per-line work is on a
reject branch that runs zero times on every corpus measured, and the
verification method is known and demonstrated by two harnesses that already
assert on this invariant and this counter.

## Sources

- `features/log-format-registry.md` § *Format Definition Properties*, §
  *`-V format-detection` section-contract*, § *`-V format-registry`
  section-contract*, § *Pin-only entries*: what an entry declares, the per-file
  key shape, and the pin-only verification producer.
- `features/453-success-failure-classification-event-ledger.md` D3 and D15 (a
  global default resolved once at build, replaced per outcome by an entry that
  names it): the declaration shape D4 follows, on the same structure.
- `features/463-friendly-log-level-category-names.md` D1 (one global lookup
  shared by every format) and D5 (the lookup stays in GLOBALS beside the
  category vocabulary): why naming stays global under D3.
- `features/503-yaml-aggregate-export.md` § *`-V filter-summary` section
  contract*: the `excluded_other` cause list D7 leaves unchanged.
- `features/447-message-control-character-normalisation.md` § D6: the surfaces a
  category occupies, and the fourth-surface correction recorded above.
- `features/395-wgm-client-log-format.md` § *Log-category consistency*: what
  that section actually says a structural check cannot assert, per correction 6.
- `features/475-log-level-vocabulary-completion.md`: the vocabulary edit this
  builds on, the fixture-token replacement, and the three Edge C SDK tokens it
  declined to admit.
- `tests/HARNESS-DESIGN.md` § *Stability contract*, § *Self-documenting
  assertions*, § *Proving a new assertion can fail*, § *Harnesses must fail on
  missing anchors*, § *Invocation coherence*.
- `docs/test-driven-development.md` § *Triage*, § *Visual surfaces*.
- `prototype/README.md` § *When a prototype is mandatory*.
- `docs/process/workflow.md` § 3: the completion-gate scope test.
- `docs/process/issues.md` § *Blocking relationships*.
