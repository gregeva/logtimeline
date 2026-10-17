# Notices pane: one place where the run tells the analyst what to know (#412)

## Overview

The analyst reads the notices pane before the timeline, the tables and the
charts, so that nothing they take from the rendered figures rests on a
condition they were not told about. Every notice the run raises is deferred to
it and presented by category, and the category tells the analyst how to read
the notice: something to check, something the tool decided, or somewhere to
look next.

Today each producer prints its own finished text to standard error at the
moment its condition is detected. The pane replaces that with one producer
interface and one renderer.

## GitHub Issue

https://github.com/gregeva/logtimeline/issues/412

Requirements are the issue body's eight: the producer/consumer mechanism,
categories, one standardised interface, relevance and restraint, visual design,
a `-V` section, the contract defined as an official pattern in
`docs/architecture-patterns.md`, and user input.

## Framing (architect, 2026-10-17)

- **The category is how the analyst is told to read the notice.** Every notice
  the tool can produce, now and in planned work, is placed in a category
  grouping, and the pane presents them by category.
- **A data anomaly** is something unexpected in how the data was encountered.
  The analyst judges whether it is expected: if so it is ignored; if not, they
  check the source data or the options given. It comes before the figures so
  that no false conclusion is drawn from them.
- **A detected pattern** comes from the statistics computed over the whole data
  set (for example a high bimodality coefficient on one API, or on the whole
  system). It sets up the analyst's next step: the sort or filter that isolates
  the behaviour, including behaviour the screen cannot show, such as a key
  outside the top N messages.
- **Decisions taken on the analyst's behalf** (fallbacks, metrics not found)
  read as informational.
- **The categories are not fixed at these.** Claude determines the full set
  from the inventory of current and planned notices, and the best way to
  display and communicate each.
- **Placement.** All data work finishes before any section is drawn, so every
  notice is known before rendering starts. The pane is shown at that point,
  before the timeline, or afterwards in some form of modal presentation; which
  is a design question.
- **Asking the analyst at the pane.** At the moment
  the pane is shown, the read is done and the rendering has not started. The
  pane is the place to say "this was detected; shall I do this before drawing
  the output?" for what can still be rendered differently from the captured
  data (for example more messages, or a different sort).
- **User input is part of this surface's design.** The surface designed and
  prototyped here includes the analyst's input, not only the deferred
  notices. Using that input design elsewhere is a separate pattern: #44's
  confirmation of a run estimated above 1 GB is asked before the read, far
  earlier than the pane, so it is not a deferred notice, but it takes the same
  form for a dialogue or input display at a different point in time. The
  design keeps the decision points in view: wherever the run could go back to
  the analyst with a question, it uses that form.
- **The pane's form follows what was deferred.** A long list of guidance
  needs much of the terminal to show it; a single deprecation notice is a
  couple of lines and calls for no large surface. The design and the
  prototype look at several forms to choose from, and decide which applies to
  which case. The same holds for the input display.
- **The existing behavioural-notices pattern is one kind of notice** within
  this surface, not the surface.

## Locked decisions

### D1 — Categories split by what the analyst does with the notice (architect, 2026-10-17)

| category | what the analyst does |
|---|---|
| data anomaly | checks the source data or the options before trusting the figures |
| your options | corrects the command |
| decision taken for you | knows what the run did instead of what was asked |
| figure caveat | reads the figures as covering less than they appear to |
| guidance | applies the suggested sort or filter next |

The test for a notice's category is the analyst's action, so the category
heading tells them how to read every notice under it. The inventory's
*informational* placements divide between *your options* and *decision taken
for you*; the placement of each notice under D1 is made in the inventory.

## Inventory of current notices

Every stderr emission in `ltl` (169 sites, from a scan of `print STDERR`,
`printf STDERR`, `warn`, `die` and `defer_notice`), on `release/0.20.0` at
`48278bf`. The proposed category is Claude's first placement, for the
architect to confirm.

Phases: **options** = option settlement in `adapt_to_command_line_options()`
and its callees, printed before the read starts; **read** = inside
`read_and_process_logs()`'s read pass; **after read** = the end of
`read_and_process_logs()` and the tail of `pipeline_parse()`; **finalize** =
`pipeline_finalize()`.

### Pane candidates

| # | producer | phase | prefix today | says | proposed category | remedy it carries |
|---|---|---|---|---|---|---|
| 1 | `parse_udm_configs` (9 sites) | options | `Warning:` | a `-udm` spec is malformed (bad regex, no name, key and pattern both given, function in the unit slot, counting with a transform, unknown function, fixed-string pattern under a counting aggregation) and is skipped, or a unit is ignored or unknown | informational | the corrected spelling, where one is evident |
| 2 | `parse_udm_configs` (2 sites) | options | `Note:` / `Warning:` | a repeated `-udm` is dropped; two specs resolve to one metric name and the later is skipped | informational | give them different names |
| 3 | `read_pattern_file`, `build_merged_regex` (8 sites) | options | `Warning:` | a pattern file is missing, unreadable, binary, empty, over 10 KB or over the pattern count; the merged regex is over its length limit | informational | none |
| 4 | `adapt_to_command_line_options` (4 sites) | options | none (bare `warn`) | a histogram or precision value is invalid and the default is used | informational | none |
| 5 | `adapt_to_command_line_options` | options | `Warning:` | a minimum bound exceeds its maximum: no entries can match, or be highlighted | informational | none |
| 6 | `adapt_to_command_line_options` (2 sites) | options | `Warning:` | the heatmap is disabled, or a histogram metric skipped, because the metric uses a counting aggregation | informational | none |
| 7 | `adapt_to_command_line_options` (2 sites) | options | `Note:` | `-n 0` leaves the listed options without effect; `-o` writes the stats CSV only | informational | none |
| 8 | `apply_parse_time_sort_gate` | options | `Note:` | `-so` cannot apply because an `--omit-*` option discards its metric; ordered by occurrences | informational | none |
| 9 | `resolve_discard_names` (2 sites) | options | `Note:` | `-d` removes a key a metric reads; the metric is switched off | informational | none |
| 10 | `apply_discard_precedence` (2 sites) | options | `Note:` | a key given to both `-x`/`-m` and `-d` is discarded | informational | none |
| 11 | `print_deprecation_notices` | options | `Warning:` | a deprecated option or spelling was used | informational | the replacement |
| 12 | `read_path_fall_back` | read (deferred) | `Note:` | the faster read path could not be prepared; large files read with the slower standard path | informational | none |
| 13 | `format_classification_rule_change` | read (deferred) | `Note:` | a file's classification rules changed at line N because the detected format changed | data anomaly | none |
| 14 | `defer_timestamp_impossible_notes` | read (deferred) | `Note:` | N of M lines of a format were not matched because their date cannot exist | data anomaly | `-lf <other variant>` if day and month are swapped |
| 15 | `defer_format_unit_notes` | read (deferred) | `Note:` | a detected format is written by more than one producer, which differ in date layout or duration unit, and nothing decided which | data anomaly | `-lf <variant>` or `-du <unit>` |
| 16 | `defer_format_unit_notes` | read (deferred) | `Note:` | `-du` is not applied to files whose format names the unit on each line | informational | none |
| 17 | `detect_and_parse_csv_header` | read (printed, not deferred) | `Warning:` | the CSV message column is not in the header | data anomaly or informational: to settle | none |
| 18 | `emit_udm_csv_unbound_notices` | read (printed, not deferred) and finalize | `Note:` | a `-udm` names a column absent from N CSV headers | informational | none |
| 19 | `read_and_process_logs` | after read | `Note:` | a format's lines carried levels `ltl` does not recognise; those lines were not counted | data anomaly | none |
| 20 | `read_and_process_logs` | after read | `Note:` | N lines carried no value for a numerically filtered metric and were excluded | informational | none |
| 21 | `read_and_process_logs` | after read | `Note:` | directories could not be read and were skipped in recursive selection | data anomaly | none |
| 22 | `resolve_byte_notation` | after read | `Note:` | the run's formats declare different byte notations; SI is used | informational | `-bn si` or `-bn iec` |
| 23 | `resolve_timestamp_precision` | after read | `Note:` | timestamps are shown to a coarser precision than asked, because the logs carry no finer | informational | none |
| 24 | `note_finer_duration_bounds` | after read | `Note:` | a duration bound is finer than the log's recorded unit | informational | none |
| 25 | `report_skipped_final_pass` | finalize | `Note:` | the final consolidation pass was skipped over N messages; the similarity at which the data clusters | informational, with guidance | a reference point for `--group-similar`; `--mask` for identifiers |
| 26 | `sort_fallback_to_occurrences` (2 texts) | finalize | `Note:` | the `-so` ranking could not be produced (no values observed, or none eligible); ordered by occurrences | informational | none |
| 27 | `bin_consolidation_notice` | finalize | `Note:` | consolidated rows' percentiles are approximate under the bin data model | informational | `-mdm raw` |
| 28 | `emit_udm_zero_match_notices` | finalize | `Note:` plus indented `read as:`, `pattern:`, `hint:` lines | a `-udm` produced no metrics, with the interpretation acted on | informational | wrap a regex token key in slashes |
| 29 | `emit_udm_skipped_capture_notices` | finalize | `Note:` | N captured values were not numbers and were skipped | data anomaly | none |
| 30 | `emit_classification_percentage_notices` (3 texts) | finalize | `Note:` | the percentage columns are not shown; the shares are omitted; the percentages cover only operations the log records | informational | `--help formats` |
| 31 | `emit_classification_percentage_notices` | finalize | `Warning:` | N included lines matched neither classification | data anomaly | none |

### Not pane material

| emission | sites | reason |
|---|---|---|
| `print_usage` and the run-stopping errors (`_validate_dm`, `_validate_profile`, a file that cannot be opened, the CSV output that cannot be written, no file to read, with the `-r` quoting hint) | ~15 | the run stops before anything renders, so there is no pane |
| format-registry self-validation (`build_format_registry`, `compile_format_*`, `format_*_src`, `format_classification_resolve`, `derive_format_constraints`, `csv_block_for_file`) | ~50 | internal invariant failures: a defect in `ltl`, never a condition of the run |
| generated read loop (`generated_loop_*`, `read_path_text`) | ~12 | internal invariant failures, caught and turned into row 12 |
| `value_text`, `value_column`, `stat_consumer_active`, `index_row` | 4 | internal invariant failures |
| `--debug-layout`, `--validate-layout`, `merge_consolidation_overlapping_patterns` debug print | 9 | developer diagnostics behind hidden options |
| the filters note in `--help` | 1 | help text on standard output, not a notice |
| run index read and write (`read_index_file`, `write_index_file`) | 3 warnings | side-file housekeeping: category to settle |
| `get_memory_usage` (Windows), `detect_light_terminal_background` | 2 | environment probes: category to settle |

### Observations from the inventory

- **A notice has parts.** Eight of the 31 carry a remedy beside the statement
  (rows 1, 11, 14, 15, 22, 25, 27, 28), and several carry evidence: counts,
  files, lines, the interpretation acted on (row 28's indented lines). A
  producer contract that takes the statement, the evidence and the remedy
  separately would let the pane present each the same way.
- **No guidance producer exists today.** Guidance appears only as remedies
  inside other notices, and row 25 is the one notice whose remedy points at an
  analysis choice rather than a correction.
- **Five prefixes.** `Note:`, `Warning:`, no prefix, `Hint:` (on a run-stopping
  error), and six-space continuation lines. `Warning:` is used both for the
  analyst's own malformed input (row 1) and for a data anomaly (row 31).
- **Timing moves.** Rows 1 to 11 print today before the read starts, so an
  analyst who mistyped a pattern file or a `-udm` sees it at once and can stop
  a long run. Deferred to the pane, they appear only after the read.
- **Two producers print during the read without deferral** (rows 17 and 18,
  via `detect_and_parse_csv_header`), while the read pass may own the terminal.
- **Granularity differs.** Some notices aggregate one line per run across
  files (rows 15, 21), some fire once per file (row 13), some once per metric
  (rows 26, 28).

## Planned producers

Notices specified in open issues and not yet built: a sweep of the 90 open
issues on 2026-10-17 (body, every comment, and the feature docs they own).
Every producer already registered on this issue's thread is shipped and sits in
the inventory above. Proposed category is Claude's first placement; *figure
caveat* and *pre-run confirmation* are kinds the three framed categories do not
hold, raised for the architect.

| issue | fires when | knowable | proposed category |
|---|---|---|---|
| #454 statistics describe a filtered subset | any line-discarding filter is active (`-i`/`-e`, `-if`/`-ef`, the numeric `min`/`max` filters; not highlights, not `-st`/`-et`) | options; after read for discard counts | figure caveat |
| #401 implied durations, warning A | implied durations are in use; states the maximum-gap ceiling in force | options; after read | figure caveat |
| #401 implied durations, warning B | logged and implied durations are mixed in one run | after read | figure caveat |
| #401 implied durations, suppressed gaps | gaps over the ceiling were suppressed (counted, never silently dropped) | after read | data anomaly, with a remedy (adjust the ceiling) |
| #61 derived metrics, disclosure | a canonical field (`duration`, `bytes`, `count`) carries derived values; derived and real mixed | after read | figure caveat |
| #61 derived metrics, gap in force | an inter-line function runs under a maximum-gap value the analyst did not give | options | informational |
| #372 paired start/end events | starts with no end, ends with no start, starts evicted (specified for `-V` only so far) | read; after read | data anomaly |
| #2 memory ceiling, engagement | memory pressure engages the adaptive path, with its fidelity trade-off | read | informational |
| #2 memory ceiling, insufficient | the budget cannot hold the request even after adapting; reduce scope or use `-g` | read; after read | informational, with a remedy |
| #44 source file heuristics, confirmation | the run's estimated memory exceeds 1 GB; asks for acceptance before continuing | before the read | pre-run confirmation |
| #44 source file heuristics, auto-applied | the heuristics change a setting (empty buckets omitted, bucket size, two passes) | before the read | informational |
| #17 duration unit auto-detection | the values contradict the detected or assumed unit; suggests `-du` | read, or the detection sample | data anomaly, with a remedy |
| #658 request start or end timestamp | start-or-end stamping is ambiguous, so the format's default is used | detection; after read | informational |
| #664 stall detection | held requests grow across buckets and release together; also marked in the timeline | after statistics | guidance |
| #193 timeout clusters | error entries cluster near a round timeout boundary | after statistics | guidance |
| #258 scenario knowledge set | the kind of input (GC log, access log) suggests related techniques | after detection | guidance, driven by the input's kind rather than a statistic |
| #535 rates at fine bucket widths | a bucket too narrow for its rates to carry meaning (open: notice, figure change or documentation) | options; after read | figure caveat, with a remedy (widen the bucket) |
| #582 regex specs for message options, misplaced pattern | a slash-delimited pattern given in the replacement slot is read as the pattern (its D9: "an informational message states the mistake and the run continues") | options | informational |
| #582 regex specs for message options, zero match | an `-x`/`-d`/`-m` spec matched nothing (its D10, D12) | after read | informational, with a remedy (wrap a regex in slashes) |
| #642 `-udm` default extraction | a value such as `1,000`, `0x10`, `Inf` (open: skip and report, or leave unmatched) | after read | data anomaly |
| #685 unreadable durations | a line's duration cannot be read; the lines skipped are reported | after read | data anomaly |
| #682 lines no format matched | lines read but matched by no format are reported | after read | data anomaly |
| #686 long forms of `-st`/`-et` | `--start` or `--end` is used: deprecated | options | informational |
| #581, #601 duplicated options | a deprecated duplicate option is used (open: whether a notice is the way) | options | informational |

Open issues that change a shipped notice: #630 removes the deprecated options
and with them their deprecation notices; #483 would end the "no classification
configured" notice (row 30) for GC logs; #697 and #681 change when a shipped
`-udm` notice fires (rows 18, 28); #469 replaces the mechanism behind row 27
without saying whether the notice still applies.

## Prototype scope

The prototype explores the design options for the surface and its input;
nothing about what is built into `ltl` is scoped until the prototypes are
delivered and validated (architect, 2026-10-17). It is required on two counts
of `prototype/README.md`: a new capability whose shape has to be found, and
(d) a verification method not yet known, since asserting a rendered terminal
surface is an open question in this repository
(`docs/test-driven-development.md` § Visual surfaces).

### Questions from the framing

| # | question | design options to compare |
|---|---|---|
| Q1 | Which forms the surface takes, and which case selects each | an inline section in the terminal output; a modal or pop-up surface over the output; a compact form of a line or two (a single deprecation); a large form taking much of the terminal (a long guidance list) |
| Q2 | Where it appears | before the timeline and its column titles, after all data work; or after the output is rendered, as a modal |
| Q3 | How each D1 category is presented | category headings with colour, ANSI characters and extended glyphs (for example a magnifying glass or a settings glyph); the layout of a notice's statement, evidence and remedy |
| Q4 | How the analyst is asked, and answers | the input display at the pane ("this was detected; shall I do this before drawing the output?"), for what can still be rendered differently from the captured data (more messages, a different sort); its form chosen by the same cases as Q1 |
| Q5 | One input form at every decision point | the pane's input design applied to a point before the read (#44's confirmation of a run estimated above 1 GB), to show the separate pattern can use it unchanged |
| Q6 | Relevance and restraint | what keeps the surface to a few well-chosen notices when many are raised |
| Q7 | The producer contract | what a producer supplies (the inventory suggests statement, evidence and remedy), proven by expressing notices from the inventory through it |
| Q8 | Verification | how a harness asserts which notices were produced, gated and shown (the `-V` section), and how the rendered surface is checked |

### Questions Claude raises, for the architect to accept or drop

- Where the output is not a terminal (redirected, captured, piped), what each
  form and the input become.
- How the forms behave at narrow widths, short terminal heights and on a light
  background.
- Rows 1 to 11 of the inventory print before the read today; whether the
  prototype shows them earlier than the pane, or only in it.

### Input the prototype runs on

Notice sets drawn from the inventory and the planned producers, one per case
Q1 must distinguish: a single notice (a deprecation); a handful across several
categories; a long list dominated by guidance; and a set that asks the analyst
a question.

## Open items

- Each notice's placement under D1's five categories.
- The prototype's questions, Q1 to Q8 under *Prototype scope*, and whether
  Claude's raised questions are taken into it.
- What is built into `ltl`: scoped only after the prototypes are delivered and
  validated.

## Acceptance criteria

To be derived from the requirements once the categories and the contract are
agreed (`docs/test-driven-development.md`).
