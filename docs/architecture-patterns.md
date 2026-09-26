# Architecture patterns

The recurring mechanisms `ltl` is built from, one entry each: what the pattern
is, when a new capability should reach for it, why it has the shape it has, where
it is used, and which record owns its decisions. It is an index beside the
feature docs, not a replacement for them: where an owning record exists the entry
summarises and points; where none exists (activation flags, behavioural notices,
the one-resolution-surface rule, the operand pushback, the hot-loop discipline)
the entry is the record.

How to use it: before building, find the pattern the change fits and build on
it. A change that adds a consumption site of a pattern, or introduces a new one,
records it here in the same commit. Each entry's *status* says whether the
pattern is established or needs refinement, and names the finding that says why;
the findings live in `features/342-redundant-logic-surfaces-audit-report.md`
(the audit that opened this file) until the issue that resolves each one moves
them on.

Every consumption site is cited as `sub` plus a snippet found by `grep -F` inside
that sub; file-scope sites name the section. Names in this file are Perl
identifiers: it is a developer document and is not part of the wiki.

---

## Declarative table with one resolver

**Definition.** A vocabulary, a set of modes or a set of specs is held in one
file-scope table, and one named sub resolves a token against it. Every option
that takes the vocabulary calls the sub; every list a user sees (an error, a
help row, a `-V list`) is derived from the same table.

**Intended uses.** Any set of tokens two or more options accept; any mode set;
any per-item specification (a format, a section, a topic, a unit, a mask).
When a new option takes tokens an existing option takes, it calls the existing
resolver. When it takes a new vocabulary, it declares the table and the
resolver together.

**Reasoning.** A literal copy is faithful when written and wrong later: the
`-hm` and `-hg` operand parsers diverged twice before both were routed through
one resolver (`features/histogram-charts.md` § Command Line Interface). A table
the errors and help rows read cannot disagree with the parser.

**Consumption sites.**
- `time_unit_canonical` :: `return $time_unit_by_spelling{ lc $spelling };` over `@time_unit_ladder`, read by `-du`, `-ru`, `-bs` and the `-udm` unit slot; the three errors interpolate `$time_unit_list`.
- `adapt_to_command_line_options` :: `if (exists $verbose_section_registry{$name}) {` over `%verbose_section_registry`, which also serves `-V list` and the unknown-name warning.
- `_validate_profile` :: `return if defined $value && exists $profile_modes{$value};` over `%profile_modes`.
- `resolve_mask_names` :: `elsif ( exists $mask_patterns{$name} )       { $wanted{$name} = 1 }` over `%mask_patterns` and `@mask_order`.
- `resolve_explain_topic` :: `return exists $explain_topics{$key} ? $key : undef;` over `%explain_topics`.
- `resolve_visibility_name` :: `my $column = $column_aliases{$name} // $name;` over `@output_sections`, `@visibility_columns` and their alias tables.
- `resolve_csv_column_family` :: `return $csv_column_family{$column} if exists $csv_column_family{$column};` over `%csv_column_family`.
- `bpd_for_surface` :: `return $TIER_BPD{$surface}[$data_model_precision_level - 1];` over `%TIER_BPD`.

**Owning record.** `features/524-bucket-size-unit.md` D1 and D2 (the time-unit
ladder: one ladder at file scope, no sub keeps a table of its own) is the
worked contract; `features/histogram-charts.md` § Command Line Interface for
metric names; `tests/HARNESS-DESIGN.md` § Reserved section names for `-V`.

**Status.** Needs refinement. The audit's item 1 found the shape followed
unevenly: the metric-name resolver is called by two of six options that take
metric names; the `-so` vocabulary is written three times with no table; the
`-m`, `-pr` and `--help` errors list their vocabularies as literals beside the
tables they validate against; the byte-unit slot folds two spellings onto one
key and resolves nondeterministically.

---

## Declarative format registry compiled into generated, cached scan subs

**Definition.** Per-format behaviour is data: `format_registry_specs()` declares
each format's pattern, field map, transforms, time contract, duration unit,
guards, classification rules and sample lines. `build_format_registry()`
resolves the specs into live entries with per-entry closures; one scan sub per
most-recently-used order is generated from source strings and cached by order
signature; every generated sub is validated against every entry's sample lines
before it serves a line.

**Intended uses.** Adding or changing a log format, a classification rule, a
timestamp layout or a transform: edit the spec, never hot-loop code. A
run-scoped option that changes what the per-line code does for a format is
baked into the generated code at build (as the query-string strip and the
exposed metric set are), not tested per line.

**Reasoning.** The chained per-line conditional it replaced re-evaluated every
format's pattern on every line; the registry's move-to-front order runs the
known pattern first, and generation removes the branches a run does not need
(`features/58-format-registry-staged-detection.md` § R2 — Detection mechanism:
move-to-front ordered scan). Load-time validation makes a wrong spec fail at
startup rather than on line one of a real file (D24).

**Consumption sites.**
- `pipeline_detect` :: `build_format_registry();`
- `format_scan_sub_resolve` :: `$format_scan_sub_cache_hits++ if exists $format_scan_sub_cache{$sig};`
- `read_and_process_logs` :: `if ( $line_entry = $format_scan_sub->($_) ) {`
- `build_format_registry` :: `$entry->[FR_TIME_PARSE]      = compile_format_time_parser( $spec->{time}{layout} );`
- `format_entry_block_src` :: `if ($t eq 'strip_query_string') { next if $opts->{include_query_string}; }` (a run option folded into the generated code).

**Owning record.** `features/log-format-registry.md` (system of record; D31,
D39, D60) and `features/58-format-registry-staged-detection.md`; CLAUDE.md §
Architecture, *Format recognition*.

**Status.** Established. Two refinements on record from the audit: the time
parse exists as the generated source strings and again as closures in
`compile_format_time_parser`, tied by a comment (item 3, F3.1); and
`format_registry_set_occupant` does its own cache lookup instead of calling
`format_scan_sub_resolve`, so occupant swaps bypass the cache-hit telemetry
(item 8, F8.1).

---

## Generated code compiled from source strings

**Definition.** A sub builds Perl source text from declarations and `eval`s it
into a closure or a sub, once per distinct configuration, and validates the
result before use. The registry's scan sub, classifier and extractor are the
three instances.

**Intended uses.** A per-line path whose shape depends on run-scoped or
per-item configuration, where a per-line test of that configuration would
cost on every line. The generated text carries only the branches the
configuration needs.

**Reasoning.** A non-executing gate still costs: a correctly gated addition
measured about 1.6 percent on access logs with both binaries executing the
same statements per line (`features/567-discard-named-values-from-message.md`
§ Post-release finding). Generation is how the registry avoids paying per line
for options a run did not name.

**Consumption sites.**
- `compile_format_scan_sub` :: `my $sub = eval $src;`
- `compile_format_classifier` :: `my $closure = eval $src;`
- `compile_format_extractor` :: `my $closure = eval $src;`
- `format_validate_scan_sub` :: `my $saved_cache = timestamp_date_cache_snapshot();` (validation of the generated sub against sample lines, with run state saved and restored).

**Owning record.** `features/log-format-registry.md` D39 and D40 (scan-sub
generation and ordering) and D60 (zero generation at startup; generation at
election, promotion, occupant swap or pin).

**Status.** Established for the three sites. Whether the per-line loop body of
`read_and_process_logs` becomes a fourth is the audit's item 8 question,
measured in drop 2.

---

## Single column-layout source of truth

**Definition.** `@column_layout` holds every display column's id, name, width,
spacing, visibility and colour; dynamic columns are appended through
`add_dynamic_column()`; rendering, colour resolution and width fitting read the
layout and nothing else.

**Intended uses.** Any new timeline column. Anything that needs a column's
width or colour reads the layout entry; nothing keeps a second width.

**Reasoning.** Before the layout, widths, spacing and colours were scattered
across the renderers and drifted; the refactor made one declaration drive every
renderer (`features/column-layout-refactor.md` § Goals).

**Consumption sites.**
- `normalize_data_for_output` :: `# Resolve ALL metric colors from @column_layout (single source of truth)`
- `print_bar_graph` :: `## RENDER ROW BY ITERATING @column_layout`
- `normalize_data_for_output` :: `add_dynamic_column(\@column_layout, 'sessions', 'sessions', 3,`

**Owning record.** `features/column-layout-refactor.md` § Goals, § Layout Engine
Requirements, § Required Separation (the CSV and summary outputs stay out of the
layout by design).

**Status.** Established. The CSV columns have no equivalent declaration (item
6); the layout is deliberately not it.

---

## Bin-counter primitives

**Definition.** One substrate for every histogram-shaped consumer:
`partition_new()`, `bin_assign()`, `counter_update()`, `percentile()` and
`partition_rebin()`, with overflow and underflow counters and `-V` telemetry.

**Intended uses.** Any new consumer that bins values by magnitude (a heatmap,
a histogram, a percentile estimator, a per-message or per-bucket distribution)
uses the primitives rather than its own bins.

**Reasoning.** Four consumers had grown four binning schemes; one substrate
made their accuracy, memory and telemetry comparable and let the precision
lever act on all of them at once (`features/189-histogram-bin-counter-primitives.md`
§ Requirements).

**Consumption sites.**
- `read_and_process_logs` :: `counter_update(\%bucket_stats_counters, $bucket, $duration, $bucket_stats_buckets_per_decade) if $duration > 0;`
- `read_and_process_logs` :: `counter_update(\%histogram_counters_hl, 'duration', $duration, $histogram_stream_bpd) if $is_highlighted;`
- `finalize_histogram_unified` :: `my ($final_p, $final_bins) = partition_rebin(`

**Owning record.** `features/189-histogram-bin-counter-primitives.md` (R1 to
R12), locked by `features/187-histogram-bin-counter-percentiles.md`;
`features/bin-counter-accuracy-and-observability.md`.

**Status.** Established.

---

## Precision tiers: one lever, one table per surface

**Definition.** A single precision tier (1 to 9) indexes `%TIER_BPD`; each
surface's bins-per-decade is resolved once through `bpd_for_surface()` at
option settlement.

**Intended uses.** Any surface built on the bin-counter primitives takes its
resolution from the table by surface name; no surface keeps its own constant.

**Reasoning.** Per-surface precision options multiplied faster than users
could reason about them; one lever with a per-surface table keeps the surfaces
comparable (`features/293-precision-lever-unification.md`, the source-of-truth
table).

**Consumption sites.**
- `bpd_for_surface` :: `return $TIER_BPD{$surface}[$data_model_precision_level - 1];`
- `adapt_to_command_line_options` :: `$percentile_buckets_per_decade   = bpd_for_surface('message-stats');`

**Owning record.** `features/293-precision-lever-unification.md`.

**Status.** Established.

---

## Data-model selectors resolved once per surface

**Definition.** Each statistical surface resolves its data model (`raw` or
`bin`) through one resolver, `resolve_data_model($surface)` behind
`choose_data_model()`: the per-surface flag, then the omnibus flag, then
`undef`, which the caller replaces by the surface's default. Validation is one
sub with one error form.

**Intended uses.** Any new surface that can hold exact or binned data resolves
its model through the resolver, before the parse loop, into a run-scoped
capture-mode scalar.

**Reasoning.** One validator and one precedence chain for five options
(`features/266-data-model-selectors.md` § Validating `raw|bin` at option-parse
time and § Resolution at each call site).

**Consumption sites.**
- `_validate_dm` :: `return if defined $value && ($value eq 'raw' || $value eq 'bin');`
- `read_and_process_logs` :: `$heatmap_capture_mode       = choose_data_model('heatmap')       // 'bin';`
- `calculate_all_statistics` :: `my $dm = choose_data_model('bucket-stats') // 'raw';`

**Owning record.** `features/266-data-model-selectors.md`.

**Status.** Needs refinement: each surface's default is repeated at fourteen
call sites instead of held with the surface (item 1, F1.14), and the resolved
capture modes are tested per line as string compares (item 8).

---

## Demand gates: store-level booleans resolved at option settlement

**Definition.** A per-line capture runs only when some consumer of its output
is active. The decision is one boolean per store and family, resolved once in
the demand block of `adapt_to_command_line_options()` from the options and the
consumer registry, and tested per line. Two rules travel with it: downstream
reads are absence-tolerant (a consumer handles a field that was never
incremented), and every accumulator keeps an observation count so derived
values gate on `count > 0`, never on `defined` over a zero-initialised field.

**Intended uses.** Any new per-line capture whose output has consumers that
may be off: resolve the demand once, gate the capture on the boolean, and make
the readers tolerate absence. Any new accumulator keeps its count.

**Reasoning.** Capture without demand cost memory nobody read (the #349
producer/consumer decoupling measured 38 percent of message-store memory on
statistic-sort runs, `features/305-shape-moment-extended-percentile-demand.md`);
a `defined` test over a zeroed total reads "observed" when nothing was
(`features/426-per-message-statistics-store.md` § Findings, the #330 gate).

**Consumption sites.**
- `adapt_to_command_line_options` :: `$bytes_aggregate_demand = ( !$omit_bytes && (`
- `read_and_process_logs` :: `if( $bytes_aggregate_demand ) {`
- `read_and_process_logs` :: `$log_messages{$category}{$log_key}{outcomes}[$line_outcome]++ if $message_outcomes_demand && $line_outcome;`
- `read_and_process_logs` :: `if( $message_duration_stats_demand ) {`

**Owning record.** `features/516-bytes-aggregate-demand-gate.md` D1 and D2;
`features/517-message-outcomes-demand-gate.md` D1;
`features/305-shape-moment-extended-percentile-demand.md` § Store-level demand;
the CLAUDE.md checkpoint on observation counts.

**Status.** Needs refinement: the observation-count rule is violated at the
projection of zeroed totals (item 4, F4.10) and the bytes count is demand-gated
while its total is not (F4.11); the impact mean divides by the wrong count
(F4.5).

---

## Statistics-group consumer registry

**Definition.** `@STAT_CONSUMERS` declares each output surface with the store it
reads, an `active` predicate and the statistic groups it needs;
`%STAT_GROUP_FIELDS` maps each group to its fields;
`resolve_statistics_group_demand()` derives per-store, per-group demand from
them once, layered on the store-level gates.

**Intended uses.** Any new consumer of a statistic declares itself in the
registry rather than switching a computation on somewhere else; any new
statistic joins a group.

**Reasoning.** Consumers declared, demand derived: a computation runs when a
declared consumer is active and never otherwise
(`features/305-shape-moment-extended-percentile-demand.md` § The three gate
classes).

**Consumption sites.**
- `(file scope, GLOBALS)` :: `my @STAT_CONSUMERS = (` and `my %STAT_GROUP_FIELDS = (`
- `adapt_to_command_line_options` :: `resolve_statistics_group_demand();`
- `calculate_all_statistics` :: `$stats = calculate_statistics($aggregated_data, $bucket_demand);`

**Owning record.** `features/305-shape-moment-extended-percentile-demand.md`;
`features/duration-statistics.md` § Demand model.

**Status.** Established. One latent drift: the timeline latency column's
visibility is restated in the registry's `active` predicate, in the demand
block and in `build_column_layout` (audit, FP.1).

---

## Run-scoped activation flags resolved once

**Definition.** Option-shaped behaviour is reduced, at option settlement, to a
scalar flag (`$highlight_active`, `$discard_active`, `$outcome_filter_active`
and their siblings) so that the per-line loop tests one scalar rather than
re-deriving the decision. This entry is the record; no feature doc owns the
shape.

**Intended uses.** Any new per-line behaviour switched by options: resolve the
switch once, name the flag for what it activates, test the flag in the loop.
A per-line derivation of a decision that is constant for the run is the
anti-pattern.

**Reasoning.** The highlight decision was once re-derived from a category
suffix at thirteen loop sites; one boolean set at the tag point replaced them
(`features/478-highlight-decision-read-back.md` § 4. The mechanism today). A
gate costs about 0.4 percent per test on access logs even when it never fires
(`features/567-discard-named-values-from-message.md` § Post-release finding),
which is the cost a flag exists to bound.

**Consumption sites.**
- `adapt_to_command_line_options` :: `$highlight_active = ( defined($highlight_filter) || $numeric_highlight_active`
- `adapt_to_command_line_options` :: `$outcome_filter_active = ( $include_failure || $exclude_failure`
- `resolve_discard_names` :: `$discard_active = ( @discard_subs || $discard_field{'query-string'} ) ? 1 : 0;`
- `read_and_process_logs` :: `if( $discard_active ) {`

**Owning record.** This entry.

**Status.** Needs refinement. Thirty-eight run-scoped flags exist; the expose
and mask flags are set in their resolve subs and again in
`apply_discard_precedence` (audit, FP.3); the capture modes are string compares
in the loop rather than booleans (item 8); the loop carries about 107 tests of
run constants per line, whose cost drop 2 measures.

---

## `-V` telemetry sections as the test surface

**Definition.** Every machine-readable diagnostic is a named section registered
in `%verbose_section_registry` and `@verbose_section_order`, emitted by an
`emit_<section>_verbose` sub gated on `section_requested()`, ASCII only.
Harnesses assert on sections, never on rendered output.

**Intended uses.** Any new behaviour a harness must assert on gets a section
(or a key in one) in the same commit; the harness file is named for the
section it validates.

**Reasoning.** Rendered output is a visual surface that changes with width and
colour; a section is a stable contract with a declared producer
(`tests/HARNESS-DESIGN.md` § Application-observability contract, § Stability
contract).

**Consumption sites.**
- `(file scope, GLOBALS)` :: `my %verbose_section_registry = (`
- `emit_statistics_demand_verbose` :: `return unless section_requested('statistics-demand');`
- `emit_format_registry_verbose` :: `push @verbose_output, "scan_sub_cache_hits: $format_scan_sub_cache_hits";`

**Owning record.** `tests/HARNESS-DESIGN.md`.

**Status.** Established. One naming drift: the `histogram-bin-counters` section
has two emitters and its emitter sub carries an older name (audit, FP.2).

---

## One resolution surface per vocabulary

**Definition.** Parsing, matching, validation and formatting of a value class
go through one named sub, and every surface that handles the class calls it:
one parser per vocabulary, one formatter per value class, one guard policy per
input class. This entry is the definition; the CLAUDE.md checkpoint (*Grep for
the domain nouns first*) enforces it at the moment of writing code.

**Intended uses.** Before writing any parse, compare, format or guard: grep for
the domain noun; if a sub owns it, call it; if two sites already own it,
converge them in the same change.

**Reasoning.** Duplicated logic is a defect that surfaces later: every copy is
a place a future fix will miss, and the divergence is visible only to a user
who exercises two surfaces in one run. The audit that opened this file records
the state of every vocabulary and value class in `ltl` at 0.19.0.

**Consumption sites.**
- `adapt_to_command_line_options` :: `my $resolved = resolve_metric_operand($heatmap_metric);`
- `handle_histogram_option` :: `my $has_valid_metric = grep { defined builtin_metric_name($_) } @parts;`
- `print_bar_graph` :: `push @csv_data, format_csv_value($total_occurrences, 'occurrences');`
- `share_row_text` :: `my $share = format_percentage( $count / $denominator * 100,`

**Owning record.** This entry; worked contracts in
`features/histogram-charts.md` § Command Line Interface (metric operands),
`docs/percentage-presentation.md` (percentages),
`features/524-bucket-size-unit.md` D1 (time units).

**Status.** Needs refinement: the audit's items 1 to 7 list the copies.

---

## Named pipeline stages

**Definition.** `## MAIN ##` is a thin dispatcher over `pipeline_detect()`,
`pipeline_parse()`, `pipeline_accumulate()`, `pipeline_finalize()` and
`pipeline_render()`. Stages are roles with contracts, not strictly sequential
passes, and take resolved demand as explicit input.

**Intended uses.** New work is placed in the stage whose role it serves; a
timing is a sub-stage of its stage; nothing runs at file scope.

**Reasoning.** Named stages give timings, memory samples and the harnesses a
stable vocabulary for where a cost or a behaviour lives
(`features/180-named-pipeline-stages.md` R2 and R4).

**Consumption sites.**
- `MAIN` :: `pipeline_accumulate();`
- `pipeline_detect` :: `$elapsed_detect_registry_build = tv_interval($registry_build_start);`

**Owning record.** `features/180-named-pipeline-stages.md`;
`docs/staged-processing-pipeline.md` § Named Pipeline Stages (#180).

**Status.** Established.

---

## Staged processing: cheap inline match, periodic expensive discovery

**Definition.** Expensive discovery is separated from cheap continuous
matching: a per-line match against known patterns, a checkpoint-triggered
discovery pass over what did not match, an interleaved re-scan, and bounded
transient memory (the S1 to S5 pipeline of message consolidation).

**Intended uses.** Any per-line analysis whose full form is too expensive to
run on every line: run the cheap form inline and the expensive form at
checkpoints, with a bound on what is held between them.

**Reasoning.** Pairwise discovery on every line is quadratic; inline matching
against discovered patterns is linear, and checkpoints bound the discovery
cost (`docs/staged-processing-pipeline.md` § Core Principle and § Applicability
Beyond Fuzzy Consolidation).

**Consumption sites.**
- `consolidation_process_key` :: `my $entry = match_consolidation_patterns($category, $grouping_key, $capped_msg);`
- `read_and_process_logs` :: `run_consolidation_checkpoint($cat, $gk);`

**Owning record.** `docs/staged-processing-pipeline.md` (kept as the full
description; this entry indexes it); `features/fuzzy-message-consolidation.md`.

**Status.** Established.

---

## Section visibility and section boundaries

**Definition.** Output sections and timeline columns are named, aliased and
hidden through one resolver (`resolve_visibility_name()`) and one predicate
(`section_hidden()`); `open_section()` marks where each rendered section starts,
so rows can be counted per section.

**Intended uses.** Any new output section registers its name and parts in
`@output_sections`, opens itself through `open_section()`, and is hidden by
`--hide` with no option of its own.

**Reasoning.** Per-section hide options had multiplied; one resolver over one
name set made `--hide` and `--show` the single visibility surface
(`features/597-section-visibility.md` § Decisions).

**Consumption sites.**
- `apply_output_visibility` :: `my $resolved = resolve_visibility_name($given);`
- `print_bar_graph` :: `open_section('timeline');`

**Owning record.** `features/597-section-visibility.md`.

**Status.** Established; the metric-name arm of the resolver is item 1's F1.1,
F1.2 and F1.4.

---

## Sort gates at three pipeline points

**Definition.** Whether a `-so` operand can be satisfied is decided at parse
time, before the population walk and after it, each through a named gate sub
with a fallback to occurrences and a notice.

**Intended uses.** Any new sortable statistic declares what it needs to exist
(a metric, a demand, a minimum count) so the gates can decide before work is
spent on it.

**Reasoning.** An unsatisfiable sort once cost a full statistics pass to
discover (`features/418-unsatisfiable-sort-selection-cost.md`); the gates
decide as early as the information exists.

**Consumption sites.**
- `adapt_to_command_line_options` :: `apply_parse_time_sort_gate($sort_operand_typed);`
- `calculate_all_statistics` :: `apply_post_walk_sort_gate($sort_defined_keys);`

**Owning record.** `features/418-unsatisfiable-sort-selection-cost.md`,
`features/303-calculated-statistic-sort-path.md`,
`features/520-inert-sort-bytes-aggregate-demand.md`.

**Status.** Established.

---

## Behavioural notices, deferred while progress owns the terminal

**Definition.** A notice about behaviour (an auto-disable, a fallback, a limit
hit, a dropped line) always prints, regardless of `--disable-progress`, on
stderr. A notice raised while the read pass owns the terminal is queued with
`defer_notice()` and emitted by `flush_deferred_notices()` after the progress
line; end-of-run notices are emitted by `emit_<topic>_notices()` subs. This
entry is the record; no feature doc owns the mechanism.

**Intended uses.** Any message a user needs in order to understand what the
run did. `--disable-progress` never gates it; a notice raised inside the loop
is deferred, not printed over the progress line.

**Reasoning.** A notice hidden behind a progress switch is a notice a captured
session never sees (CLAUDE.md § Before writing or changing code; the
progress-side rationale in `docs/progress-indication-best-practices.md`).

**Consumption sites.**
- `defer_notice` :: `push @deferred_notices, $text;`
- `read_and_process_logs` :: `flush_deferred_notices();`
- `emit_classification_percentage_notices` :: `print STDERR "Warning: $r->{unclassified} included line(s) ($leak_pct%) matched neither the success nor the failure classification`
- `bin_consolidation_notice` :: `print STDERR "Note: $detail, so their percentiles are approximate"`

**Owning record.** This entry, until #412 (the notices surface) lands and
inventories every ad-hoc notice.

**Status.** Needs refinement: notices render counts and percentages three ways
(audit, item 2, F2.8 and F2.9); one warning is emitted inside the option
parser's warning capture and never prints (item 1, F1.17).

---

## Optional-operand options and the filename pushback

**Definition.** An option whose operand is optional (`-hm`, `-hg`, `-V`, `-g`,
`-mem`) may be followed by a filename that the option parser takes as its
value. The handler decides whether the value names something in the option's
vocabulary; if not, it pushes the value back onto `@ARGV` as a positional
argument and takes the option's default. This entry is the record.

**Intended uses.** Any new option with an optional operand follows the same
decision and says what it did.

**Reasoning.** Five options make the decision five ways: two warn, three are
silent, and a pushed-back name that is not a file is then dropped by the
file-list filter without a notice (audit, item 1, F1.6). One helper would make
the decision and the notice the same for all five.

**Consumption sites.**
- `handle_histogram_option` :: `unshift @ARGV, $opt_value;`
- `adapt_to_command_line_options` :: `unshift @ARGV, $heatmap_metric;`
- `adapt_to_command_line_options` :: `unshift @ARGV, $group_similar_sensitivity;`
- `adapt_to_command_line_options` :: `unshift @ARGV, $memory_usage_operand;`
- `adapt_to_command_line_options` :: `@in_files = grep { -f $_ } @in_files;`

**Owning record.** This entry.

**Status.** Needs refinement (F1.6, F1.17).

---

## Hot-loop discipline

**Definition.** The per-line loop pays once per line for everything it
carries. A feature that is off costs one falsy scalar read and no sub call; a
guard that is only needed on a rare branch sits on that branch (the
impossible-date guard on the memo-miss branch); a value constant for the run is
computed before the loop; any change to the loop is measured before and after
on the machine doing the work, with the interleaved method when the expected
effect is near the noise floor.

**Intended uses.** Any change to `read_and_process_logs` or the generated scan
sub, and any per-key path at high cardinality.

**Reasoning.** Measured: a non-executing gate cost about 1.6 percent on access
logs (`features/567-discard-named-values-from-message.md` § Post-release
finding); an outer activation wrapper around the highlight blocks was declined
on a measured 0.24 percent ceiling (`features/478-highlight-decision-read-back.md`);
the inline guard placement costs nothing on a cache hit
(`features/log-format-registry.md`, the #384 prototype findings); a
package-global read-compare-write on every line measured about 1.5 percent
before it was moved (the comment at the bytes-observed latch).

**Consumption sites.**
- `read_and_process_logs` :: `&& ( !$numeric_highlight_active || (`
- `format_entry_block_src` :: `my $miss_src = $layout =~ /^iso_/`
- `read_and_process_logs` :: `if( $bytes_observed_line && !$omit_bytes ) {`

**Owning record.** `features/312-numeric-criteria-highlight-selection.md` §
Core mechanism; `features/478-highlight-decision-read-back.md`;
`features/567-discard-named-values-from-message.md` § Post-release finding;
`docs/perl-performance-optimization.md`; `tests/baseline/README.md`.

**Status.** Needs refinement: the loop carries about 107 tests of run constants
per line and recomputes the millisecond bucket size and the key length per
line (audit, item 8, measured in drop 2).
