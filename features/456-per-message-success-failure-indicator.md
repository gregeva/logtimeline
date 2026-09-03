# Per-message success/failure indicator, and the classification states behind it (#456)

**Issue:** #456 (FEATURE: Per-message success/failure indicator in log messages and summary table)
**Branch:** `456-per-message-success-failure-indicator` off `release/0.18.0`
**Status:** requirements and specification, in definition with the architect
(2026-09-03). No code written. The classification data-model work below is
larger than the issue body describes and its split from the render change is an
open decision.

## Scope

The motivating consumer is the analyst reading the two message blocks — `TOP
HIGHLIGHTED MESSAGES` and `TOP OVERALL MESSAGES` — who can see how a message
ranks but not which side of the classification its lines fell on. One coloured
character alongside each row answers that at a glance, in the character position
the consolidation marker already occupies, costing the layout nothing.

Defining that indicator honestly turned out to require three states the tool
does not have. A row is not always uniform, a line's two classification rules can
both fire, and a window's success/failure pair can silently stop being that
window's whole population. Each of those is a gap in what the tool can currently
say, so the work divides into:

1. **The indicator** — a coloured character per message row in the two message
   blocks, carrying the row's classification state.
2. **`CLASSIFICATION CONFLICT`** — a new per-line outcome for a line that
   satisfies both the success and the failure criteria, counted per time bucket
   and for the run, and exported.
3. **`MIXED`** — a new message-scope state for a row whose lines were not
   uniform, with a global counter that the success and failure counters give
   their lines up to.
4. **A per-bucket unclassified count**, and the revised percentage-suppression
   rule that reads it.

Out of scope: a per-message *percentage* (the hand-forward in
`features/452-success-failure-percentage-columns.md` § Hand-forward); per-file
figures (same place); the notices surface itself (#412).

## What already ships — substrate audit (read off the tree, 2026-09-03)

| Needed | What the code does today |
|---|---|
| An indicator position | `print_message_summary()`: `my $row = $is_consolidated ? "~" : " " x $table_padding_outer;`. `$table_padding_outer` is 1, so the marker and the blank it replaces are the same single character and the indicator costs the layout nothing |
| Row colour independence | The block header ends in the block colour and the rule line beneath it resets with `NC`; message rows are then emitted as plain text with no escapes at all (confirmed on rendered output, `tests/fixtures/http-status-families.txt`). An indicator is therefore self-contained — colour, character, reset — with no block colour to restore |
| Per-message outcome counts | `$log_messages{$grouping}{$key}{outcomes}[1\|2]`, successes and failures. Merged across consolidation by `merge_consolidation_stats()` and projected onto the cluster's canonical entry in `group_similar_messages()` |
| Capture of those counts | Gated to `-o` alone by #517 (`$message_outcomes_demand`), which recovered the `%log_messages` growth #453 introduced and named this feature as the consumer that would rejoin its demand terms |
| Classification colours | `%colors`: `kelly-green` (256-colour 34) success, `rosso-corsa` (160) failure, `gold` (178) unclassified. Shared by the summary's classified rows and the timeline's `success`/`failure` columns (#452 D14) |
| Per-line outcome | `$line_outcome`: 0 unclassified, 1 success, 2 failure. Decided by the generated classifier in `format_classification_src()` |
| Per-bucket outcome counters | `%bucket_outcomes{$bucket}`: slot 1 successes, slot 2 failures, slot 3 the count of lines whose registry entry has `FR_PCT_QUALIFYING == 0`. Slot 0 is never written (#453 D30) |
| Run outcome counters | `$total_successes`, `$total_failures`, `$total_non_qualifying_lines`, all written at the include point in `read_and_process_logs()` |
| Unclassified | **Not counted anywhere, at any scope.** The run figure is a subtraction in `classification_reconciliation()`: `$total_lines_included - ($total_successes + $total_failures)`. There is no per-bucket equivalent and nothing derives one |
| Percentage suppression | `normalize_data_for_output()` falls back to `success_pct_count` / `failure_pct_count` on `$bucket_outcome->[3]` alone. Run level: `($classified > 0 && $total_non_qualifying_lines == 0)` |
| Consolidation timing | Checkpoint merges run inside the read loop (`run_consolidation_checkpoint()`); the final pass runs in `pipeline_finalize()`, after every file has been read (`group_similar_messages()`, on by default, `--no-final-pass` the hidden opt-out) |
| Message data per time bucket | Nothing holds it. `%log_messages` has no time dimension |
| User-facing statements of the marker | `--help` (`-g` row: "Consolidated entries are marked with ~ in the output"), `docs/usage.md:140` |

### Findings that shaped the requirements

- **F1 — A line matching both criteria is silently filed as a failure.**
  `format_classification_src()` compiles the decision as `($f) ? 2 : ($s) ? 1 :
  0`, so failure short-circuits and the success rule is never evaluated on such a
  line. Nothing on any surface says the two rules both fired. Adding the conflict
  state is therefore a correctness fix, not only a new figure.
- **F2 — Suppression today has exactly one path, and it is a property of the
  format, not of the line.** `FR_PCT_QUALIFYING` is set at registry build from
  the entry's declarations (`_cls_both && (event_ledger || $show_classification)`).
  An included line from a non-qualifying entry increments slot 3 whatever its own
  outcome was; an unclassified line from a *qualifying* entry increments nothing,
  and its window keeps printing a percentage over a denominator that is no longer
  the whole population.
- **F3 — Bucket counters cannot be trued up after the fact.** A consolidation
  merge sees the member keys' `outcomes` counts and nothing else. With no
  structure holding message data per time bucket, a merge knows a cluster has
  become non-uniform but not which buckets its lines fell in. Half the merges
  also happen after parsing has ended.
- **F4 — None of the three new states can fire on any format shipping today.**
  Conflict cannot, because the five access-family entries test `category_bucket`
  against disjoint alternations (`^(?:1xx|2xx|3xx)$` against `^(?:4xx|5xx)$`).
  Qualifying-source unclassified cannot, because on those entries every category
  the vocabulary gate admits is matched by one of the two rules. Mixed cannot,
  because the message key is prefixed with the exact status code
  (`[$log_level] …`) and consolidation clusters are partitioned by that same
  prefix (`$cat_gk = "$category|$grouping_key"`), so neither a key nor a cluster
  can hold two outcomes. All three become reachable with the first format that
  classifies on evidence outside the grouping key — #483 (success/failure
  classification criteria for the Java G1 GC log format) is the nearest
  candidate. D10 broadens the mixed test to a row mixing an outcome with
  unclassified lines, which does not change this: on those entries no included
  line goes unclassified, and on `java_gc_g1` every line does, so a row is
  uniform either way. **No rendered output moves on any shipping format**, and
  nothing in the current corpus exercises the new states; see § Acceptance
  criteria.

- **F5 — `MIXED` cannot be computed on a run that retains no messages.**
  `$capture_messages = ( $top_n_messages > 0 ) ? 1 : 0;`, so `-n 0` populates no
  `%log_messages` entries and there are no rows to test for uniformity. The
  run-level mixed count is then unavailable, and with it D9's suppression: the
  same data would print run-level percentages under `-n 0` and withhold them
  without it. To be resolved.

## Requirements

Stated in the architect's terms (2026-09-03).

- **R1 — One indicator character per message row, in the position the
  consolidation marker occupies.** Not consolidated: the bullet `•` (U+2022).
  Consolidated: the existing `~`, recoloured. The classification is carried by
  the character's colour in both cases; the marker never moves and the layout
  never changes.
- **R2 — Unclassified rows carry no indicator.** Absence of classification is
  not a finding about the message, and marking it would read as a negative
  pattern about the row. The position stays as it renders today — blank, or `~`
  in its current uncoloured form.
- **R3 — The indicator's colours are the classification colours already in
  use.** Success reads in the same shade as the `SUCCESS CLASSIFIED` summary row
  and the timeline's `success` column; failure likewise. One outcome, one colour,
  wherever it appears.
- **R4 — Both message blocks.** `TOP HIGHLIGHTED MESSAGES` and `TOP OVERALL
  MESSAGES`. The run summary table is not a target: it has no per-message row,
  and its classified rows already carry those colours on their own text.
- **R5 — A line that satisfies both criteria is its own outcome**, named
  `CLASSIFICATION CONFLICT`. It is neither a success nor a failure: the rules
  contradicted each other on that line, and the analyst needs to see that the
  criteria are wrong, not a figure derived as though they were right.
- **R6 — Conflict is counted per time bucket and for the run**, and exported in
  the YAML aggregate alongside the other outcome figures.
- **R7 — A window holding any conflict prints absolute counts, not
  percentages.** The line was not cleanly classified, so the classified pair is
  not that window's whole population and a share of it measures nothing.
- **R8 — An unclassified line from a format that declares both outcomes has the
  same effect.** On such a format every line should be classifiable; one that is
  not means something was missed, nobody knows what, and the denominator has
  quietly stopped being the population. This revises #452 D3 (see D6).
- **R9 — A message row whose lines were not uniform is `MIXED`.** Its lines
  leave the global success and failure counters and are counted in a global
  `MIXED` counter, so the run-level figures stay as reliable as the data allows.
- **R10 — Time-bucket counters record what was known when the bucket passed and
  are never revised.** Once a bucket has passed there is no visibility into what
  was in it, so mixed is a global and per-message figure only.
- **R11 — `MIXED` has its own colour**, used for both the summary table's mixed
  counter row and the indicator on a mixed message row.

## Locked decisions

- **D1 — The indicator is one character in the consolidation marker's position
  (architect, 2026-09-03).** `•` (U+2022) when the row is not consolidated, the
  existing `~` when it is. The consolidation marker is never displaced: when a
  row is both consolidated and classified, only the `~`'s colour changes. The
  position is `$table_padding_outer` wide — one character — so the width
  allocation in `print_message_summary()` is untouched.
- **D2 — Colour carries the classification, in both message blocks (architect,
  2026-09-03).** `kelly-green` for success, `rosso-corsa` for failure — the same
  `%colors` definitions the summary's classified rows and the timeline's
  percentage columns read, so an outcome has one colour everywhere. `MIXED` has
  its own colour, the same one on the indicator and on the summary table's mixed
  row. Unclassified has none (R2).
- **D3 — `CLASSIFICATION CONFLICT` is a per-line outcome (architect,
  2026-09-03).** A line whose success and failure criteria both evaluate true is
  neither, and takes a fourth value. It is counted at time-bucket and run scope
  and exported, like the other outcomes. This retires the short-circuit in F1.
- **D4 — `MIXED` is a message-scope state, and only the global counters move
  (architect, 2026-09-03).** A message row whose lines were not uniform is mixed;
  its success and failure counts are subtracted from the global success and
  failure counters and added to a global mixed counter. Per-bucket counters are
  not adjusted: they state what was known at parse time, and F3 shows there is no
  way to revise them without a structure that does not exist. The consequence is
  deliberate — the summary rows will no longer reconcile with the sum of the
  bucket counters, by exactly the mixed count.
- **D5 — Every line of a mixed row leaves its own counter for `MIXED`
  (architect, 2026-09-03).** The movement is mechanical and symmetric: when
  rows are formed and merged and a row's state resolves to mixed, each of its
  lines is subtracted from the counter it was counted in and added to the mixed
  counter. The architect's worked case: one line counted as a success and
  another as a failure each increment their global counter; the final
  consolidation pass merges the two messages into one entry; success decrements
  by one, failure decrements by one, mixed increments by two, and the
  consolidated entry's classification state becomes mixed. Under D10 the same
  applies to a mixed row's unclassified and conflict lines — the row is one
  representation and all of it is mixed. The run-level figures therefore become
  a five-way partition of counted quantities, and `unclassified` stops being
  the subtraction `included - (successes + failures)` that
  `classification_reconciliation()` computes today:

  ```
  SUCCESS + FAILURE + CLASSIFICATION CONFLICT + MIXED + UNCLASSIFIED = LINES INCLUDED
  ```

  *Implementation note, not a competing decision:* the same result is produced
  by one walk of the retained rows at end of parse, after the final
  consolidation pass, which also covers a row that resolves to mixed without
  having been consolidated. Whichever way it is realised, the arithmetic above
  is the contract.
- **D6 — Percentage suppression is one meaning with three paths (architect,
  2026-09-03).** A window falls back to absolute counts (the D17 mechanism:
  `success_pct_count` / `failure_pct_count`, the absent `%` telling the reader it
  is a count) when its success/failure pair is not its whole classified
  population. That happens when the window holds a line from a non-qualifying
  source (shipped), an unclassified line from a qualifying source (new), or a
  conflict (new). Run-level eligibility takes the same terms. **This revises
  #452 D3**, which had unclassified lines never disqualify a row — the lenient
  rung was wrong for a format that declares both outcomes, because there an
  unclassified line means the classification failed to catch something.
- **D7 — Counting the new suppression paths needs two new per-bucket slots
  (Claude, from D3 and D6).** Slot 4 for conflicts and slot 5 for unclassified
  lines from qualifying sources, written in the same per-line block that already
  writes slots 1, 2 and 3 — the same cost class as the shipped slot-3 increment,
  no new structure. The three suppression counts stay separate rather than
  folding into slot 3, because #503 D16 exports the non-qualifying count
  specifically to explain an absent percentage, and "the format did not qualify",
  "the rules matched nothing on this line" and "the rules contradicted each
  other" are three explanations a reader has to be able to tell apart.

- **D8 — Two new classification colours (architect, 2026-09-03).** `terracotta`
  = 256-colour **173** (`#d7875f`) for `MIXED`, matched to the swatch the
  architect supplied; `amethyst` = 256-colour **135** (`#af5fff`) for
  `CLASSIFICATION CONFLICT`. Both join the classification shades in `%colors`
  beside `kelly-green`, `rosso-corsa` and `gold`, named for the colour they are
  (#452 D14), and each reads the same wherever its state appears — the summary
  row and the message indicator. A muted terracotta keeps `MIXED` clear of `gold`
  at one-character size, which a pure orange such as 208 would not; a violet
  keeps `CLASSIFICATION CONFLICT` off the green–gold–orange–red axis entirely, so
  it cannot be read as a degree of good or bad, which it is not. Both are still
  judged on rendered output during implementation, as `kelly-green` and
  `rosso-corsa` were after 22 and 88 proved too dark on a build.

- **D9 — `MIXED` suppresses the run-level percentages (architect,
  2026-09-03).** Once a mixed row's lines are pulled out of the global success
  and failure counters, the run's classified denominator no longer covers every
  classified line, so a share of it is not a share of the population. With a
  non-zero mixed count the run summary's `SUCCESS CLASSIFIED` and `FAILURE
  CLASSIFIED` rows print their counts without a share, exactly as they already do
  on a run carrying a non-qualifying source. `mixed` joins `non_qualifying` in
  the run-level eligibility predicate in `classification_reconciliation()`. The
  per-bucket columns are untouched: they keep what was known when the bucket
  passed (D4).

- **D10 — A row's state is uniformity, and anything else is `MIXED`
  (architect, 2026-09-03).** A message row takes an outcome's colour only when
  every one of its lines carries that same state: all success, all failure, or
  all conflict (amethyst). Every other combination is `MIXED`, including a row
  mixing an outcome with unclassified lines — any uncertainty removes the
  expectation of certainty, and a row rendered as pure success when some of its
  lines were never classified would be read as a count of successful
  occurrences it is not. A row whose lines are all unclassified stays unmarked
  (R2). This supersedes Claude's proposal that unclassified lines be treated as
  leakage the row's state ignores.

## Open decisions

- **Q5 — The issue split.** The indicator is a render change on two tables;
  D3–D7 are a classification data-model change touching the per-line outcome, the
  bucket counters, eligibility across the timeline, the summary rows, `-V`, the
  YAML export, and a revision of a locked #452 decision. Whether that ships
  inside #456 or as its own issue with #456 blocked on it is the architect's
  call.

## Data model changes

| Change | Where | Cost |
|---|---|---|
| Fourth `$line_outcome` value for conflict | `format_classification_src()`, and every consumer of `$line_outcome`: the outcome filters and highlight criteria (`-is/-if/-es/-ef`, `-hs/-hf`, #455), the per-message `outcomes` array, `expect_outcomes` validation on every format spec | The compiled classifier stops short-circuiting on failure and evaluates both criteria |
| `%bucket_outcomes` slots 4 and 5 | The include point in `read_and_process_logs()` | Two conditional increments per line, the class of the shipped slot-3 increment |
| Global mixed counter, and `unclassified` becomes counted rather than derived | The point rows are formed and merged (D5); `classification_reconciliation()` stops subtracting | One pass over retained rows; no per-line cost |
| Per-message outcome capture back on for classified runs | `$message_outcomes_demand`, #517 D1 — its demand terms gain this feature's state, as #517 anticipated | One array increment per classified line, on default access-log runs. **The one measurable cost in the design**; the before/after benchmark has to carry it |
| Revised eligibility predicate | `normalize_data_for_output()` per bucket, `classification_reconciliation()` for the run | Arithmetic only |

## Surfaces to update in the same drop

- Timeline `success` / `failure` columns and the errRate column — eligibility only.
- Run summary: the new `CLASSIFICATION CONFLICT` and `MIXED` rows, printed on the
  `UNCLASSIFIED` pattern (only when non-zero), through `summary_colour()` so `-sm`
  prints the table plain.
- `-V` classification section: the new counters, and the section contract in
  `features/453-success-failure-classification-event-ledger.md`.
- YAML aggregate export: the new outcome figures at run and bucket scope, and the
  reason an absent percentage is absent (#503 D16 carries only the non-qualifying
  count today).
- STATS CSV and MESSAGES CSV outcome columns.
- `--help` (`-g` row) and `docs/usage.md:140`, which both state that a
  consolidated entry is marked with `~`, now also a classification carrier.
- `--explain classification` and `docs/explain/classification.md`.

## Acceptance criteria

To be agreed before code, per `docs/test-driven-development.md`. The blocker to
resolve first:

**No shipping format can reach conflict, mixed, or qualifying-source
unclassified (F4).** Every criterion below that exercises a new state therefore
needs a producer that does not exist yet — a registry entry declaring overlapping
or partial criteria, or #483 landing first. Which of those it is has to be
settled before the criteria can be written, and it is the one "unknown"
verification method in the feature.

Criteria that can be written now, against the shipped states:

1. The indicator renders in the two message blocks for success and failure rows,
   in the character position the consolidation marker occupies, with the table's
   column widths byte-identical to the base commit on the same run.
2. A consolidated row keeps `~` and changes only its colour; a non-consolidated
   row renders `•`.
3. An unclassified row renders exactly as it does today.
4. No runtime warnings: stderr carries no ` at ltl line N` lines on any criterion
   run.
5. Full suite green, and the before/after benchmark carries the per-line cost of
   re-enabled outcome capture.

## Merge gate

Full harness suite plus a before/after benchmark on this machine, per
`docs/process/workflow.md` § 3, on the commit being merged, with
`$version_number` restored to `0.18.0` first.
