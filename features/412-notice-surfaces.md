# Notice surfaces: how the run tells the analyst what to know, and asks (#412)

## Overview

The analyst is told what they need to know about their run before they draw
conclusions from its figures, and is asked for a choice where the run can act
on one. This issue designs the notice surfaces that do this: interfaces that
present information and may capture the analyst's input or choice, adapted to
different situations and to different moments of the run. The deferred notices
shown before the timeline, the tables and the charts are one of them, presented
by category, the category telling the analyst how to read each notice.

Today each producer prints its own finished text to standard error at the
moment its condition is detected. The surfaces replace that with one producer
interface and a coherent presentation.

## GitHub Issue

https://github.com/gregeva/logtimeline/issues/412

Requirements are the issue body's eight: the producer/consumer mechanism,
categories, one standardised interface, relevance and restraint, visual design,
a `-V` section, the contract defined as an official pattern in
`docs/architecture-patterns.md`, and user input.

## Framing (architect, 2026-10-17)

- **The category is how the analyst is told to read the notice.** Every notice
  the tool can produce, now and in planned work, is placed in a category
  grouping, and the surfaces present them by category.
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
- **Placement of the deferred notices.** All data work finishes before any
  section is drawn, so every deferred notice is known before rendering starts.
  They are shown at that point, before the timeline, or afterwards in some form
  of modal presentation; which is a design question.
- **Notice surfaces, adapted to the situation and the moment.** What is
  designed is not one pane at one point of the run but notice surfaces, partly
  presenting information and potentially capturing the analyst's input or
  choice, which are adapted into different situations. Prototyping explores
  them to arrive at patterns to standardise on, and determines how, and if,
  each is implemented in `ltl`. Examples:
  - a single-line deprecation: a couple of lines on standard output, decorated
    a little;
  - early in processing, memory use is growing high: a yes or no on whether to
    continue (#44);
  - later, once statistical analysis has detected a pattern: a choice such as
    changing the sort order, which needs much more of the run to have happened
    before it can even be asked.
- **Input is captured coherently with the notice surfaces.** The choice points
  differ in moment and in what precedes them; how each is presented is
  coherent with the notice surfaces, so the analyst's input is captured and
  collected within them. Deferring notices is one pattern; capturing a choice
  at a given point of the run builds on the same surfaces and is a separate
  pattern, designed and prototyped here.
- **Restraint is choosing the surface, not merging notices.** The surface
  chosen is the one best adapted to the situation and the actual conditions;
  what happens in moving from one surface to another is determined once the
  surfaces themselves are understood. One such surface is a navigable list,
  scrolled up and down, in which a notice is selected to see more detail about
  it: more complicated, and powerful for many notices, where it is overkill
  for a simple informational message.
- **Presentation of information and choices is separate from the charts.**
  As what `ltl` can detect and present grows more complex, the rendering of
  the charts, the statistical information and the metadata describing them is
  separated from the notices and choice patterns. The issue was first framed
  as a structured area before the chart; that framing is too constrained.
  This concerns only the surfaces for the user, how the rendering and the
  user input occur; it has nothing to do with how the data is structured or
  processed.
- **The progress indicator is in scope.** A choice raised while the progress
  indication is displayed is one of the scenarios prototyped. If a modal
  dialogue proves the best way, that is the more straightforward to handle;
  if not, the part of the progress indication on screen is erased, a message
  is displayed followed by an input point (perhaps accepting a single
  character rather than waiting for enter), and the progress printing resumes
  cleanly.
- **A choice point with nobody at the keyboard follows industry practice.**
  The harnesses, Claude during development and the screenshot tool run `ltl`
  unattended, and a run must neither hang nor vary. Ways to handle it include
  taking the choices on standard input, so that they can be redirected, and a
  hidden option, along the lines of an always-yes, that tells `ltl` before a
  choice point comes up how to answer it. Every choice point has a default:
  the analyst is given a certain amount of time to intervene, and if they do
  not, the run goes on with the default. `ltl` has none of these today; how
  user input is supplied and handled is #748 (take the analyst's input at
  choice points, with a default and answers given ahead of time), and the
  surfaces are designed with it in mind.
- **A timed default shows a visible countdown.** The message and its
  question are printed with the yes/no block, followed in brackets by the
  seconds remaining until the default is taken; the line is redrawn every
  second as it counts down, while a single-character read (`Term::ReadKey`)
  accepts Y or N.
- **Glyphs and emoji are covered in a prototype.** Agreed in principle; how
  they render across terminals and fonts is tested before anything is decided.
- **A choice can be multi-stage.** A more complex choice is raised in stages:
  first the analyst is told there are options worth looking at that might
  change the output, and asked whether to look at them or continue as
  planned, a yes or no that defaults after a few seconds to continuing; only a
  yes leads on to the options themselves.
- **Notices found before the read are an example of the framing.** The
  notices raised at option parsing (inventory rows 1 to 11) are known before
  processing starts and before the progress line appears. A small slice could
  expose them at that point with an input asking whether the analyst wants to
  continue, or stop and correct them. Not a decision taken now; a use case
  for the surfaces and choice points the prototypes explore.
- **Out of scope: a notice surface displayed while the read and processing
  occur.** It could be interesting, but it would change how the current
  progress indication works and make the scope too large to manage. (A choice
  raised during the progress line, above, stays a prototyped scenario.)
- **Not part of this stage:** which questions are asked, and identifying every
  place they could be asked. There are a couple of key places where it is
  possible.
- **A surface's form follows what it carries.** A long list of guidance
  needs much of the terminal to show it; a single deprecation notice is a
  couple of lines and calls for no large surface. The design and the
  prototypes look at several forms to choose from, and decide which applies to
  which case. The same holds for the input display.
- **Where the output is read.** An analyst always reads `ltl` in a terminal;
  that is its intended and principal use. Piping is not a design goal: `ltl`
  accepts no piped input and does not intend its output to be piped. Data for
  other consumers goes through `-o` (two CSV files and one YAML file), and
  pictures for documents through the screenshot capability (an SVG and a PNG
  of a targeted section, `docs/process/screenshots.md`). The other readers of
  the terminal surface are the test harnesses, and Claude during development,
  which redirects the output to see how it rendered, stripping ANSI sequences
  where needed.
- **Standard error is temporary; the designed surface is on standard output.**
  The notices print to standard error today so that they stay out of standard
  output and the harnesses can capture and check them. Any designed terminal
  interface is on standard output, so this issue's `-V` section exposes the
  deferred notices, giving the harnesses a way to read them other than
  capturing standard error.
- **The surface works within the screenshot capability**, so the documentation
  can target it. What the screenshot tool handles today (standard output only,
  rows chosen by section through `-V section-layout`, no escape sequence other
  than a colour code) is a constraint of the tool as it is, not a boundary of
  the design: the design determined here feeds back into the screenshot tool,
  which adapts to it, with the balance between them found as part of the work.
- **A modal or pop-up must be introspectable by Claude's development tools**;
  for the analyst it raises no problem. `ltl` has no library for one today:
  what is relevant and possible is found in prototyping, and what is
  integrated into `ltl`, and how, is decided after it.
- **The existing behavioural-notices pattern is one kind of notice** within
  this surface, not the surface.

## Locked decisions

### D1 — Categories split by what the analyst does with the notice (architect, 2026-10-17; runtime condition added the same day)

| category | what the analyst does |
|---|---|
| data anomaly | checks the source data or the options before trusting the figures |
| your options | corrects the command |
| decision taken for you | knows what the run did instead of what was asked |
| figure caveat | reads the figures as covering less than they appear to |
| guidance | applies the suggested sort or filter next |
| runtime condition | is informed of a condition of the run's environment; what, if anything, they do depends on the message |

The test for a notice's category is the analyst's action, so the category
heading tells them how to read every notice under it. The inventory's
*informational* placements divide between *your options* and *decision taken
for you*; each notice is placed under D1 in the inventory below.

## Inventory of current notices

Every stderr emission in `ltl` (169 sites, from a scan of `print STDERR`,
`printf STDERR`, `warn`, `die` and `defer_notice`), on `release/0.20.0` at
`48278bf`. The categories are Claude's placements, not confirmed by the architect; they
are settled in the planning that precedes implementation, not now.

Phases: **options** = option settlement in `adapt_to_command_line_options()`
and its callees, printed before the read starts; **read** = inside
`read_and_process_logs()`'s read pass; **after read** = the end of
`read_and_process_logs()` and the tail of `pipeline_parse()`; **finalize** =
`pipeline_finalize()`.

### Notice candidates

| # | producer | phase | prefix today | says | category (D1) | remedy it carries |
|---|---|---|---|---|---|---|
| 1 | `parse_udm_configs` (9 sites) | options | `Warning:` | a `-udm` spec is malformed (bad regex, no name, key and pattern both given, function in the unit slot, counting with a transform, unknown function, fixed-string pattern under a counting aggregation) and is skipped, or a unit is ignored or unknown | your options | the corrected spelling, where one is evident |
| 2 | `parse_udm_configs` (2 sites) | options | `Note:` / `Warning:` | a repeated `-udm` is dropped; two specs resolve to one metric name and the later is skipped | your options | give them different names |
| 3 | `read_pattern_file`, `build_merged_regex` (8 sites) | options | `Warning:` | a pattern file is missing, unreadable, binary, empty, over 10 KB or over the pattern count; the merged regex is over its length limit | your options | none |
| 4 | `adapt_to_command_line_options` (4 sites) | options | none (bare `warn`) | a histogram or precision value is invalid and the default is used | your options | none |
| 5 | `adapt_to_command_line_options` | options | `Warning:` | a minimum bound exceeds its maximum: no entries can match, or be highlighted | your options | none |
| 6 | `adapt_to_command_line_options` (2 sites) | options | `Warning:` | the heatmap is disabled, or a histogram metric skipped, because the metric uses a counting aggregation | your options | none |
| 7 | `adapt_to_command_line_options` (2 sites) | options | `Note:` | `-n 0` leaves the listed options without effect; `-o` writes the stats CSV only | your options | none |
| 8 | `apply_parse_time_sort_gate` | options | `Note:` | `-so` cannot apply because an `--omit-*` option discards its metric; ordered by occurrences | your options | none |
| 9 | `resolve_discard_names` (2 sites) | options | `Note:` | `-d` removes a key a metric reads; the metric is switched off | your options | none |
| 10 | `apply_discard_precedence` (2 sites) | options | `Note:` | a key given to both `-x`/`-m` and `-d` is discarded | your options | none |
| 11 | `print_deprecation_notices` | options | `Warning:` | a deprecated option or spelling was used | your options | the replacement |
| 12 | `read_path_fall_back` | read (deferred) | `Note:` | the faster read path could not be prepared; large files read with the slower standard path | decision taken for you | none |
| 13 | `format_classification_rule_change` | read (deferred) | `Note:` | a file's classification rules changed at line N because the detected format changed | data anomaly | none |
| 14 | `defer_timestamp_impossible_notes` | read (deferred) | `Note:` | N of M lines of a format were not matched because their date cannot exist | data anomaly | `-lf <other variant>` if day and month are swapped |
| 15 | `defer_format_unit_notes` | read (deferred) | `Note:` | a detected format is written by more than one producer, which differ in date layout or duration unit, and nothing decided which | data anomaly | `-lf <variant>` or `-du <unit>` |
| 16 | `defer_format_unit_notes` | read (deferred) | `Note:` | `-du` is not applied to files whose format names the unit on each line | decision taken for you | none |
| 17 | `detect_and_parse_csv_header` | read (printed, not deferred) | `Warning:` | the CSV message column is not in the header | data anomaly | none |
| 18 | `emit_udm_csv_unbound_notices` | read (printed, not deferred) and finalize | `Note:` | a `-udm` names a column absent from N CSV headers | your options | none |
| 19 | `read_and_process_logs` | after read | `Note:` | a format's lines carried levels `ltl` does not recognise; those lines were not counted | data anomaly | none |
| 20 | `read_and_process_logs` | after read | `Note:` | N lines carried no value for a numerically filtered metric and were excluded | figure caveat | none |
| 21 | `read_and_process_logs` | after read | `Note:` | directories could not be read and were skipped in recursive selection | data anomaly | none |
| 22 | `resolve_byte_notation` | after read | `Note:` | the run's formats declare different byte notations; SI is used | decision taken for you | `-bn si` or `-bn iec` |
| 23 | `resolve_timestamp_precision` | after read | `Note:` | timestamps are shown to a coarser precision than asked, because the logs carry no finer | decision taken for you | none |
| 24 | `note_finer_duration_bounds` | after read | `Note:` | a duration bound is finer than the log's recorded unit | your options | none |
| 25 | `report_skipped_final_pass` | finalize | `Note:` | the final consolidation pass was skipped over N messages; the similarity at which the data clusters | decision taken for you, with guidance | a reference point for `--group-similar`; `--mask` for identifiers |
| 26 | `sort_fallback_to_occurrences` (2 texts) | finalize | `Note:` | the `-so` ranking could not be produced (no values observed, or none eligible); ordered by occurrences | decision taken for you | none |
| 27 | `bin_consolidation_notice` | finalize | `Note:` | consolidated rows' percentiles are approximate under the bin data model | figure caveat | `-mdm raw` |
| 28 | `emit_udm_zero_match_notices` | finalize | `Note:` plus indented `read as:`, `pattern:`, `hint:` lines | a `-udm` produced no metrics, with the interpretation acted on | your options | wrap a regex token key in slashes |
| 29 | `emit_udm_skipped_capture_notices` | finalize | `Note:` | N captured values were not numbers and were skipped | data anomaly | none |
| 30 | `emit_classification_percentage_notices` (3 texts) | finalize | `Note:` | the percentage columns are not shown; the shares are omitted; the percentages cover only operations the log records | figure caveat (all three texts; architect, 2026-10-17) | `--help formats` |
| 31 | `emit_classification_percentage_notices` | finalize | `Warning:` | N included lines matched neither classification | data anomaly | none |
| 32 | `read_index_file` | detect (`pipeline_detect()`) | none (bare `warn`) | the run index file exists but cannot be read; read-back skipped | runtime condition | none |
| 33 | `read_index_file` | detect (`pipeline_detect()`) | none (bare `warn`) | the run index file is malformed; read-back skipped | runtime condition | none |
| 34 | `write_index_file` | render (`pipeline_render()`) | none (bare `warn`) | the run index file could not be renamed into place after writing | runtime condition | none |
| 35 | `get_memory_usage` | read and after (registry and CSV compilation, memory measurement) | none (bare `warn`) | on Windows, process memory usage could not be read | runtime condition | none |

### Not notices

| emission | sites | reason |
|---|---|---|
| `print_usage` and the run-stopping errors (`_validate_dm`, `_validate_profile`, a file that cannot be opened, the CSV output that cannot be written, no file to read, with the `-r` quoting hint) | ~15 | the run stops at the error, before any notice is deferred |
| format-registry self-validation (`build_format_registry`, `compile_format_*`, `format_*_src`, `format_classification_resolve`, `derive_format_constraints`, `csv_block_for_file`) | ~50 | internal invariant failures: a defect in `ltl`, never a condition of the run |
| generated read loop (`generated_loop_*`, `read_path_text`) | ~12 | internal invariant failures, caught and turned into row 12 |
| `value_text`, `value_column`, `stat_consumer_active`, `index_row` | 4 | internal invariant failures |
| `--debug-layout`, `--validate-layout`, `merge_consolidation_overlapping_patterns` debug print | 9 | developer diagnostics behind hidden options |
| the filters note in `--help` | 1 | help text on standard output, not a notice |
| `detect_light_terminal_background` | 1 | its `stty` failure is raised inside an `eval` and never printed |

### Observations from the inventory

- **A notice has parts.** Eight of the 35 carry a remedy beside the statement
  (rows 1, 11, 14, 15, 22, 25, 27, 28), and several carry evidence: counts,
  files, lines, the interpretation acted on (row 28's indented lines). A
  producer contract that takes the statement, the evidence and the remedy
  separately would let a surface present each the same way.
- **No guidance producer exists today.** Guidance appears only as remedies
  inside other notices, and row 25 is the one notice whose remedy points at an
  analysis choice rather than a correction.
- **Five prefixes.** `Note:`, `Warning:`, no prefix, `Hint:` (on a run-stopping
  error), and six-space continuation lines. `Warning:` is used both for the
  analyst's own malformed input (row 1) and for a data anomaly (row 31).
- **Timing moves.** Rows 1 to 11 print today before the read starts, so an
  analyst who mistyped a pattern file or a `-udm` sees it at once and can stop
  a long run. Deferred to the end of the data work, they appear only after the read.
- **Two producers print during the read without deferral** (rows 17 and 18,
  via `detect_and_parse_csv_header`), while the read pass may own the terminal.
- **Granularity differs.** Some notices aggregate one line per run across
  files (rows 15, 21), some fire once per file (row 13), some once per metric
  (rows 26, 28).

## Planned producers

Notices specified in open issues and not yet built: a sweep of the 90 open
issues on 2026-10-17 (body, every comment, and the feature docs they own).
Every producer already registered on this issue's thread is shipped and sits in
the inventory above. The categories are Claude's placements, not confirmed by the architect; they
are settled in the planning that precedes implementation, not now.

| issue | fires when | knowable | category (D1) |
|---|---|---|---|
| #454 statistics describe a filtered subset | any line-discarding filter is active (`-i`/`-e`, `-if`/`-ef`, the numeric `min`/`max` filters; not highlights, not `-st`/`-et`) | options; after read for discard counts | figure caveat |
| #401 implied durations, warning A | implied durations are in use; states the maximum-gap ceiling in force | options; after read | figure caveat |
| #401 implied durations, warning B | logged and implied durations are mixed in one run | after read | figure caveat |
| #401 implied durations, suppressed gaps | gaps over the ceiling were suppressed (counted, never silently dropped) | after read | data anomaly, with a remedy (adjust the ceiling) |
| #61 derived metrics, disclosure | a canonical field (`duration`, `bytes`, `count`) carries derived values; derived and real mixed | after read | figure caveat |
| #61 derived metrics, gap in force | an inter-line function runs under a maximum-gap value the analyst did not give | options | decision taken for you |
| #372 paired start/end events | starts with no end, ends with no start, starts evicted (specified for `-V` only so far) | read; after read | data anomaly |
| #2 memory ceiling, engagement | memory pressure engages the adaptive path, with its fidelity trade-off | read | decision taken for you |
| #2 memory ceiling, insufficient | the budget cannot hold the request even after adapting; reduce scope or use `-g` | read; after read | decision taken for you, with a remedy |
| #44 source file heuristics, auto-applied | the heuristics change a setting (empty buckets omitted, bucket size, two passes) | before the read | decision taken for you |
| #17 duration unit auto-detection | the values contradict the detected or assumed unit; suggests `-du` | read, or the detection sample | data anomaly, with a remedy |
| #658 request start or end timestamp | start-or-end stamping is ambiguous, so the format's default is used | detection; after read | decision taken for you |
| #664 stall detection | held requests grow across buckets and release together; also marked in the timeline | after statistics | guidance |
| #193 timeout clusters | error entries cluster near a round timeout boundary | after statistics | guidance |
| #258 scenario knowledge set | the kind of input (GC log, access log) suggests related techniques | after detection | guidance, driven by the input's kind rather than a statistic |
| #535 rates at fine bucket widths | a bucket too narrow for its rates to carry meaning (open: notice, figure change or documentation) | options; after read | figure caveat, with a remedy (widen the bucket) |
| #582 regex specs for message options, misplaced pattern | a slash-delimited pattern given in the replacement slot is read as the pattern (its D9: "an informational message states the mistake and the run continues") | options | your options |
| #582 regex specs for message options, zero match | an `-x`/`-d`/`-m` spec matched nothing (its D10, D12) | after read | your options, with a remedy (wrap a regex in slashes) |
| #642 `-udm` default extraction | a value such as `1,000`, `0x10`, `Inf` (open: skip and report, or leave unmatched) | after read | data anomaly |
| #685 unreadable durations | a line's duration cannot be read; the lines skipped are reported | after read | data anomaly |
| #682 lines no format matched | lines read but matched by no format are reported | after read | data anomaly |
| #686 long forms of `-st`/`-et` | `--start` or `--end` is used: deprecated | options | your options |
| #581, #601 duplicated options | a deprecated duplicate option is used (open: whether a notice is the way) | options | your options |

Open issues that change a shipped notice: #630 removes the deprecated options
and with them their deprecation notices; #483 would end the "no classification
configured" notice (row 30) for GC logs; #697 and #681 change when a shipped
`-udm` notice fires (rows 18, 28); #469 replaces the mechanism behind row 27
without saying whether the notice still applies.

## Prototyping

Prototyping is many prototype scripts, built to be compared against each other
and adapted to different scenarios. They share elements, but the selection
criteria and the adaptation are worked on each prototype individually, and how
each case is decided and implemented is likely to differ (architect,
2026-10-17). Prototype feedback is captured throughout and at the end of the
prototyping stage, and is what the final requirements and specification are
settled from before anything is built into `ltl`; nothing about what is built
is scoped until the prototypes are delivered and validated.

The prototypes cover every example surface and choice point: the decorated
deprecation of a couple of lines, the yes or no while processing, the choice
offered once a pattern is detected, and the long list of guidance. During
prototyping it is chosen which is relevant where, and how each applies; once
validated they become patterns to draw on for future enhancements, even where
they are not implemented in `ltl` at first.

Prototypes are reviewed live. The architect works with Claude in one session
while running the prototypes in another, and gives feedback as he goes; Claude
takes it in, updates the findings and changes the prototypes accordingly, in a
collaborative development loop.

The surfaces are prototyped first: what the analyst sees and how they answer.
The producer interface (how code anywhere in the run registers a notice or a
choice, with a choice's options, default, timeout and what happens when it is
accepted), on which the requirement 7 pattern rests, is designed once the
surfaces are chosen.

The prototypes explore two visual languages: one matching `ltl`'s existing
look (the title banner, the box-drawing rules of the timeline and tables, the
colour table per column and background), and a new style, which the rest of
the output might later adopt.

Prototyping runs in stages, simplest first, each stage directing the next.
The early stages render from fixed sets of example notices, enough to choose a
direction; later stages are fed what real `ltl` runs produce, so that the
chosen surfaces become credible and relevant to `ltl`.

Prototyping runs in stages across platforms. macOS is the primary
development platform, so the prototypes start there; a round of decisions
selects the patterns to take forward, and only those are ported to Linux and
Windows, so that the work and validation fall on the selected patterns alone.
Final decisions are not made before it is known what is possible on the other
platforms: a pattern found infeasible or overly complicated on Windows is found
before implementation in `ltl`, not during it. The packaged binaries carry
every library the chosen patterns need.

The research the prototypes start from (what `ltl` has today, the kinds of
terminal surface, prompt practice, Perl libraries, unattended capture) is
`features/412-notice-surfaces-research.md`.

Prototyping is required on two counts of `prototype/README.md`: a new
capability whose shape has to be found, and (d) a verification method not yet
known, since asserting a rendered terminal surface is an open question in this
repository (`docs/test-driven-development.md` § Visual surfaces).

### Closing out prototyping (architect, 2026-10-17)

Individual prototypes need not meet these; the selected options must, before
the prototyping stage is closed:

- [ ] Each selected surface is judged by the architect in the terminal.
- [ ] Each selected surface has a demonstrated way to be captured and checked
      unattended, for the harnesses and for the screenshot tool.
- [ ] The prototype findings record what was chosen, what was learned along
      the way, and why each decision was made.

## Open items

- Each notice's placement under D1's five categories.
- What is built into `ltl`: scoped only after the prototypes are delivered and
  validated.

## Acceptance criteria

To be derived from the requirements once the categories and the contract are
agreed (`docs/test-driven-development.md`).
