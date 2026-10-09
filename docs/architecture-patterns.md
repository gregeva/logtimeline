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
- `time_unit_canonical` :: `return $time_unit_by_spelling{ lc $spelling };` over `@time_unit_ladder`, read by `-du`, `-ru`, `-tp`, the `-udm` unit slot, and through `resolve_quantity_option` by `-bs` and the duration rows of `@quantity_options`; the errors interpolate `$time_unit_list`.
- `number_unit_canonical` :: `return $number_unit_by_spelling{ lc $spelling };` over `@number_unit_ladder` (every tier's spelling and the input-only `also` spellings), read through `resolve_quantity_option` by the count rows of `@quantity_options`; the `-udm` unit slot reads the ladder's `udm` symbols case-sensitively through `%udm_number_factor`; the count errors and `--help units` interpolate `$number_unit_list`.
- `byte_unit_canonical` :: `return $byte_unit_by_spelling{ lc $spelling };` over `@byte_unit_ladder` (each step's SI and IEC token and byte count, and on input its long-tier words), read by the `-udm` unit slot and through `resolve_quantity_option` by the byte rows of `@quantity_options`; the GC heap-size reader `gc_heap_size_bytes` reads each figure's prefix letter through `byte_prefix_bytes` (`%byte_unit_by_prefix`, a view of the ladder) at the notation the format declares; the unknown-unit warning interpolates `$time_unit_list` and `$byte_unit_list`.
- `print_help` :: `"Time: $time_unit_list. Bytes: $byte_unit_si_list are powers of 1000, $byte_unit_iec_list powers of 1024; ..."`: the `-du`, `-ru`, `-bs` and `-udm unit` rows interpolate both ladders' lists, never a literal; `tests/validate-help-content.sh` scenario `J-unit-list-parity` compares each row, and its `docs/usage.md` row, with the list the matching error or warning prints; scenario `K-name-list-parity` does the same for the name vocabularies (the `-hm`, `-hg`, `--hide` column and `-udm` function rows).
- `adapt_to_command_line_options` :: `if (exists $verbose_section_registry{$name}) {` over `%verbose_section_registry`, which also serves `-V list` and the unknown-name warning.
- `_validate_profile` :: `return if defined $value && exists $profile_modes{$value};` over `%profile_modes`.
- `builtin_metric_name` :: `return $lc if exists $builtin_metric{$lc};` over `@builtin_metrics` (name, layout column, family, help text, the stored key a bare `-so` word ranks by, deprecated spellings with the options that accept them), read by `-hm`, `-hg` and `-so`; `@graph_columns`, the metric entries of `@visibility_columns`, `%heatmap_metric_map`, `available_metric_names`, the internal metric loops and `resolve_value_kind` read its views, and every unknown-metric message and the `-hm`, `-hg`, `-x` and `-d` help rows interpolate `$builtin_metric_list` (#613 D5).
- `adapt_to_command_line_options` :: `my $sort_statistic = $statistic_by_spelling{ lc $sort_type };` over `@statistic_names` (typed name, stored key, aliases, deprecated spelling, `--explain` topic, place in the `-udm` function slot); `parse_udm_configs` reads `%udm_function_names`, `%udm_function_aliases` and `%udm_functions_of_kind` from it, `resolve_explain_topic` reads `%explain_aliases`, and the `--help statistics` and `--explain` alias notes and the `-udm` function help row are derived from it (#613 D8, D17).
- `resolve_mask_names` :: `my $identifier = $mask_identifier{ lc $given };` over `@mask_identifiers` (each name and the `%mask_patterns` entries it covers, `ip` among them) and `@mask_order`; `resolve_discard_names` reads the same table, and the `-m` error interpolates `$mask_identifier_list` (#613 D7).
- `resolve_message_name` :: `if ( my $field = $message_field{ lc $name } ) {` over `@message_fields` (the parsed fields and message parts `-x` and `-d` name, with what each option does to them), the one resolution `resolve_expose_names` and `resolve_discard_names` share; `@cleared_fields` is its view for the field-clearing flag (#613 D6).
- `resolve_explain_topic` :: `return exists $explain_topics{$key} ? $key : undef;` over `%explain_topics`.
- `resolve_visibility_name` :: `my $column = $column_aliases{$name} // $column_of_plural{$name} // $name;` over `@output_sections`, `@visibility_columns`, their alias tables and the plural names of the Sessions and Users columns.
- `resolve_csv_column_family` :: `return $csv_column_family{$column} if exists $csv_column_family{$column};` over `%csv_column_family`.
- `bpd_for_surface` :: `return $TIER_BPD{$surface}[$data_model_precision_level - 1];` over `%TIER_BPD`.
- `column_total_field` :: `return $column_total_field{$column} // $column;` over `%column_total_field`, read by the bar scaling in `normalize_data_for_output` and the timeline cell in `print_bar_graph`.

**Owning record.** `features/524-bucket-size-unit.md` D1 and D2 (the time-unit
ladder: one ladder at file scope, no sub keeps a table of its own) is the
worked contract; `features/histogram-charts.md` § Command Line Interface for
metric names; `tests/HARNESS-DESIGN.md` § Reserved section names for `-V`.

**Status.** Needs refinement, until #614 (operand checks and texts derive from
the vocabulary) lands. The audit's item 1 found the shape followed
unevenly. Since #613 (one vocabulary for names), every option that takes a
metric name resolves it through the built-in metric table: `-hm`, `-hg`, `-so`,
`-x` and `-d` through `builtin_metric_name`, `--hide` and `--show` through the
metric entries of `@visibility_columns`. The family-prefixed `-so`
names are a literal list beside the two tables; the `-pr` and `--help` errors
list their vocabularies as literals. Refined by #614.

---

## Quantity units

**Definition.** An option whose value is a count, a byte size or a duration is
a row of `@quantity_options`: its names, its kind (`count`, `bytes` or
`duration`), whether it is a bound (a fraction applies as written, a negative is
refused) or a size (it must be whole), and the scalar the run reads. Every row
is a string option whose text `resolve_quantity_option` reads once at
settlement: a bare number as it stands, in the option's base unit (milliseconds,
bytes, a count), or a number followed by a unit with no space, the unit read in
the row's kind only and matched without regard to case. Each kind's vocabulary
is its ladder: `@time_unit_ladder`, `@byte_unit_ladder`, `@number_unit_ladder`.
Everything the output prints for a kind, an input of that kind accepts. A value
the option cannot read stops the run with a usage error that quotes it and lists
the kind's units from the ladder. A numeric option that stays a bare number is a
key of `%bare_number_options`, with its reason.

**Intended uses.** Any new option whose value is a quantity: add a row (and, for
a bound, its role, end and signature), and the parse, the provenance, `-V
runtime-config`, `-V option-resolution` and the help sentence follow. Any new
numeric option that is not a quantity (a width, a percentage, a tier): add it
to `%bare_number_options` with its reason. An option with its own base unit
(`-bs`, whose bare number is in the run's unit) calls `resolve_quantity_option`
with a row of the same shape rather than splitting the text itself.

**Reasoning.** A quantity is written the way it is thought of (`-dmin 200us`,
`-gc 2M`, `-bs 7d`) and the tool does the arithmetic; a bare number keeps its
meaning, so no command line changes behaviour (`features/605-input-units.md`
D7). One declaration keeps the lists of the bound set from diverging (the
redundant-logic audit found eight hand-written copies), and one parse keeps the
grammar, the case rule and the rejection text the same on every option.

**Consumption sites.**
- `(file scope, GLOBALS)` :: `my @quantity_options = (`: the seventeen rows (the twelve numeric bounds, `-n`, `-gc` and the three hidden consolidation counts) beside the scalars the read loop compares; `%bare_number_options` beside it.
- `resolve_quantity_option` :: `my ($number, $spelling) = $text =~ /^($quantity_number_re)([A-Za-z]*)$/`: the one number-and-unit split, reading `%quantity_kind` (each kind's canonical sub, value, noun and list).
- `adapt_to_command_line_options` :: `( map { my $row = $_; ( quantity_option_spec($row) . '=s' => sub { $quantity_entered{ $row->{long} } = $_[1] } ) } @quantity_options ),`: the rows' `GetOptions` entries; the settlement loop beside it resolves each given row, and the `-bs` block calls `resolve_quantity_option` with its run unit as base.
- `adapt_to_command_line_options` :: `for my $min_row (grep { $_->{bound} && $_->{bound}{end} eq 'min' } @quantity_options) {`: the inverted-range check, quoting the values as typed; `has_active_filters`, `serialize_filters` and `quantity_bounds_given` read the rows' roles and signature flags.
- `note_finer_duration_bounds` :: `next unless $time_unit_step{$unit}{ms} < $time_unit_step{$finest}{ms};`: a duration bound typed finer than the log's declared unit gets a note.
- `emit_option_resolution_verbose` :: `grep { defined $quantity_entered{ $_->{long} } } @quantity_options;`: `-V option-resolution`, each given option as entered beside what it resolved to.
- `print_help` :: `$out .= help_opt("-$_->{short}, --$_->{long} <N>", bound_option_help($_)) for grep { $_->{bound} } @quantity_options;`: the bound rows in one phrasing; `quantity_unit_sentence` ends every unit-bearing row with its pointer to `print_help_units` (`ltl --help units`).
- `-tp` follows the pattern through `time_unit_canonical` directly: its value is a unit name, not a quantity.

**Owning record.** `features/605-input-units.md` (D1 to D24; § 5.2 the
declaration, § 5.3 the parse, § 5.4 the vocabularies); `docs/usage.md` § Units
for the user surface. Checked by `tests/validate-option-resolution.sh`:
`quantity-units-declared` (every `=i` or `=f` option is in
`%bare_number_options`, every row is a string option read by the parse, no
other number-and-unit split, no list of the bound set outside the declaration)
and `printed-spellings-accepted` (every spelling the three ladders print is
accepted on input of its kind).

**Status.** Established (#605).

---

## Declarative format registry compiled into generated, cached scan subs

**Definition.** Per-format behaviour is data: `format_registry_specs()` declares
each format's pattern, field map, transforms, time contract, duration unit,
byte notation (the format's declared unit convention for bytes), guards, classification rules and sample lines. `build_format_registry()`
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
- `format_entry_block_src` :: `if ($t eq 'strip_query_string') { next if $opts->{include_query_string}; }` (a run option folded into the generated code).
- `format_timestamp_src` :: `my $capture = $opts->{capture_fraction} // 1;` (the timestamp read gate folded into the generated code; entry *Timestamp precision: requested by the user, bounded by what each file carries*, rule 3).
- `csv_block_for_file` :: `my @order = $kind eq 'epoch' ? ('csv_epoch') : ('csv', 'csv_ddmm');` (the CSV template instantiated per header shape).

**Owning record.** `features/log-format-registry.md` (system of record; D31,
D39, D60) and `features/58-format-registry-staged-detection.md`; CLAUDE.md §
Architecture, *Format recognition*.

**Template entries.** An entry whose field positions come from the input
rather than from its spec is a template: its block is generated per input
shape through the same emitter and cache, validated on the input's own
sampled rows before it serves a line, one instance alive at a time. The `csv`
entry is the one instance (`features/615-csv-registry-entry.md` D1, D9, D10,
D11): each CSV file's header builds its block. A pattern entry of its own
waits for the second consumer, user-declared formats (#387).

**Status.** Established. One refinement on record from the audit:
`format_registry_set_occupant` does its own cache lookup instead of calling
`format_scan_sub_resolve`, so occupant swaps bypass the cache-hit telemetry
(item 8, F8.1). The cache bypass is #620.

---

## Generated code compiled from source strings

**Definition.** A sub builds Perl source text from declarations and `eval`s it
into a closure or a sub, once per distinct configuration, and validates the
result before use. The registry's scan sub, classifier and extractor, and the
block each CSV file's header instantiates, are the four instances.

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
- `compile_csv_block` :: `my $block = eval $src;` (the per-file CSV block, validated on the file's sampled rows by `csv_validate_block`).
- `format_validate_scan_sub` :: `my $saved_cache = timestamp_date_cache_snapshot();` (validation of the generated sub against sample lines, with run state saved and restored).

**Owning record.** `features/log-format-registry.md` D39 and D40 (scan-sub
generation and ordering) and D60 (zero generation at startup; generation at
election, promotion, occupant swap or pin).

**Status.** Established for the four sites. Whether the per-line loop body of
`read_and_process_logs` becomes a fifth is the audit's item 8 question,
measured in drop 2. The per-line loop body as a switchable generated variant is #621, not planned, after #620.

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
6); the layout is deliberately not it. The CSV column declaration is #618.

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
capture modes are tested per line as string compares (item 8). Both are #620 (the default held with the surface; the capture modes as booleans).

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
- `adapt_to_command_line_options` :: `$bucket_bytes_demand = ( !$omit_bytes && ( !$hide_bytes || $write_messages_to_csv ) ) ? 1 : 0;`
- `adapt_to_command_line_options` :: `$message_bytes_demand = ( !$omit_bytes && $capture_messages && (`
- `read_and_process_logs` :: `if( defined $bytes && $message_bytes_demand ) {`
- `read_and_process_logs` :: `if( $bytes_observed_line && $bucket_bytes_demand ) {`
- `read_and_process_logs` :: `$log_messages{$category}{$log_key}{outcomes}[$line_outcome]++ if $message_outcomes_demand && $line_outcome;`
- `read_and_process_logs` :: `if( $message_duration_stats_demand ) {`

**Owning record.** `features/516-bytes-aggregate-demand-gate.md` D1 and D2;
`features/616-gated-mean-derivation.md` D30 (a metric is processed only when a
line produces it and a surface demands it, at each store);
`features/517-message-outcomes-demand-gate.md` D1;
`features/305-shape-moment-extended-percentile-demand.md` § Store-level demand;
the CLAUDE.md checkpoint on observation counts.

**Status.** Established for the observation-count rule by #616 (counts kept
beside their totals under the same gate, a total projected only when counted,
bytes processed only when produced and demanded at each store). Needs
refinement for the per-line captures #620 gates (session, user and index
capture).

---

## Timestamp precision: requested by the user, bounded by what each file carries

**Definition.** The precision of a timestamp is the user's request, read,
rendered and written under six rules, each locked in the owning record:

1. **One request, through the time-unit ladder.** `-tp, --timestamp-precision`
   names minute, second, millisecond, microsecond or nanosecond, as the
   ladder's tokens or long spellings (D3, D6, D9). `-s` and `-ms` are
   deprecated, and either beside a `-tp` of another precision is a usage error
   (D5, D12).
2. **Precision is not width.** `-tp` sets how a timestamp is read, stored and
   rendered, never the bucket width; the bucket key's scale follows `-bs`
   alone, and at a whole-second width a line counts in the second it was
   written in (D11, D14, D20; `features/524-bucket-size-unit.md` D4).
3. **Read at the precision its consumers need.** The parse reads the
   sub-second part only when a consumer that measures with it is active: a
   precision finer than the second, a width that is not a whole number of
   seconds, a `-st`/`-et` bound with a fraction, the aggregate export under
   `-o`. The decision is settled once and compiled into the generated blocks,
   never tested per line, and reported only under `-V benchmark-data` (D11,
   D21, D22). Under `-tp ns` the digits are also kept as written, so exact
   bounds never pass through a float (D23).
4. **Never shown finer than the execution's processed files carry.** Each
   file's true precision is read from the unit its timestamp field states and
   the fraction digits it carries, through the ladder: a clock time states the
   second, so `.234` is a millisecond; the duration field's unit plays no
   part. A request finer than the finest precision any processed file carries
   gives way to that precision, with a stderr notice naming the precision used
   and what was found; a file carrying less than another does not lower the
   run (D4 as amended 2026-10-08, D10). It is the timestamp instance
   of the rule that a value never renders in a unit smaller than its stated
   unit (`features/617-width-to-format-rule.md` D4, D16).
5. **Rendered by one formatter.** Every site that renders or writes a
   timestamp, the output file-name stamp included, calls `format_timestamp`;
   the sub-second part is rounded half-up once, at the last digit shown,
   carrying into the second, minute and date; minute and second truncate
   (D1, D7, D8).
6. **The run index states each row's precision.** Each row's timestamps are
   written at the run's resolved precision, stated in `ts_precision`
   (`m` at minute, over whole-second strings); drift compares as numbers, at
   the run's precision or the row's when that is coarser, and an older row
   with `-` is read at the precision its digits carry (D13, D15 to D19).

Decision labels in this entry are those of
`features/525-timestamp-precision-option.md` unless another record is named.

**Intended uses.** Any input path that parses a timestamp takes its fraction
handling from the emitter under the read gate's compile options, and is a
source of its file's true precision, so every input obeys rules 3 and 4 alike
and every option that acts on the pattern acts on every input. Any new site
that renders or writes a timestamp calls `format_timestamp`. A new consumer
that measures with the sub-second part opens the read gate by joining its
condition, never by reading the fraction on its own.

**Reasoning.** Before the one formatter the same instant rendered two ways in
one run (`.122` in the heading, `.123` in the index for a `.123` line), and
`-ms` on a whole-second log printed `.000` on every label. The read gate is
decided per consumer, not per rendering: closed without the aggregate export
as a consumer, the export's population duration was measured between whole
seconds (`2.666` became `2`). Reading a fraction nobody uses costs a capture
and an exponent per line: the gate measured −4.0 % `parse/read_files` on a
generated application log with variable-length fractions, below noise on a
fixed three-digit format (`features/525-timestamp-precision-option.md` § 1,
§ 10 step 3d).

**Consumption sites.**
- `adapt_to_command_line_options` :: `my $canonical = time_unit_canonical($timestamp_precision_option);` (rule 1)
- `adapt_to_command_line_options` :: `$timestamp_capture_ns = $timestamp_precision eq 'ns' ? 1 : 0;` (rule 3)
- `adapt_to_terminal_settings` :: `$timestamp_capture_fraction =` (rule 3)
- `build_format_registry` :: `capture_fraction => $timestamp_capture_fraction, capture_ns => $timestamp_capture_ns` (rule 3, the compile options)
- `format_timestamp_src` :: `my $capture = $opts->{capture_fraction} // 1;` (rule 3; every generated block's timestamp, the CSV block's included)
- `read_and_process_logs` :: `if ($timestamp_capture_ns) {` (rule 3, the exact bounds)
- `sample_file_for_detection` :: `my $digits = $c[$o] =~ /:\d{2}:\d{2}[.,](\d+)/ ? length $1 : 0;` (rule 4, the digits a file carries)
- `csv_validate_block` :: `my $d = ($ts =~ /:\d{2}:\d{2}[.,](\d+)/ || $ts =~ /^\d+\.(\d+)$/) ? length $1 : 0;` (rule 4, the digits a CSV file carries)
- `resolve_timestamp_precision` :: `push @found, fraction_precision(` (rule 4, through the ladder)
- `format_timestamp` :: `my $ticks = timestamp_ticks($epoch, $opt{precision}, $opt{exact});` (rule 5)
- `write_index_file` :: `my $index_precision = index_timestamp_precision($timestamp_precision);` (rule 6)
- `detect_index_drift` :: `$live_n    = timestamp_ticks($live_v, $precision, $live_exact);` (rule 6, as numbers)

**Owning record.** `features/525-timestamp-precision-option.md` § 4 (D1 to
D23); `features/524-bucket-size-unit.md` D4 (width and precision separate);
`features/617-width-to-format-rule.md` D4, D16.

**Status.** Established. A run over several files takes the finest
precision any processed file carries (`resolve_timestamp_precision` ::
`my $limit = %file_precision ? $finest->(values %file_precision) : undef;`),
fixed under #525 reopened. CSV input reads its timestamps under the read gate
through the CSV block, and the rows that block is validated on are its
file's precision evidence (`features/615-csv-registry-entry.md` D16, D17).

---

## Observation counts and gated means

**Definition.** Every accumulator carries its observation count beside its
total, kept under the same demand gate as the total, and every mean is derived
by one helper, `mean_of($sum, $count)`, from a sum and that count, with the
gate inside: the mean is `undef` unless the count holds an observation. A total
is projected only when its count is positive, and is never pre-set to zero
before a line produces it. The helper runs after the read loop, never per line.

**Intended uses.** Any new mean, at any store or surface: call `mean_of` with
the accumulator's sum and count rather than dividing inline. Any new
accumulator keeps its count beside its sum, incremented through the entry
reference the sum's addition already holds (a lookup by the full message key
costs about 100 ns per line on the development host, an increment through a
reference about 20 ns).

**Reasoning.** The audit of redundant logic found eleven inline derivations of
a mean with three gate shapes, the per-bucket user-defined mean computed twice,
and a total projected as zero beside an empty mean for a bucket in which no
line carried the metric
(`features/342-redundant-logic-surfaces-audit-report.md` § Item 4). One helper
makes the count gate hold by construction, and the next change to a store's
representation retargets one site per quantity.

**Consumption sites.**
- `calculate_all_statistics` :: `count_mean    => mean_of( $log_analysis{$bucket}{count_sum}, $log_analysis{$bucket}{count_occurrences} ),`
- `calculate_all_statistics` :: `bytes_mean    => mean_of( $log_analysis{$bucket}{total_bytes}, $log_analysis{$bucket}{bytes_occurrences} ),`
- `calculate_all_statistics` :: `$log_stats{$bucket}{"udm_${name}_mean"} = mean_of( $log_analysis{$bucket}{"udm_${name}_sum"}, $occ );`
- `calculate_all_statistics` :: `$entry->{bytes_mean} = mean_of( $entry->{total_bytes}, $entry->{bytes_occurrences} );` (the sort pre-pass)
- `calculate_all_statistics` :: `$entry->{count_mean} = mean_of( $entry->{count_sum}, $entry->{count_occurrences} );` (the sort pre-pass)
- `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{count_mean} = mean_of(`
- `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{"udm_${name}_mean"} = mean_of( $sum, $occ );`
- `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{bytes_mean} = mean_of(` (the per-message bytes mean, stored precise)
- `write_index_file` :: `my $dur_avg         = format_csv_value( mean_of( $fd->{duration_sum}, $fd->{duration_occurrences} ),   'duration_mean', 2 ) // '';` and its five siblings
- `derive_moment_statistics` :: `my $mean = mean_of($total, $n);` (the duration mean, both data models)
- `impact_of` :: `my $mean = mean_of( $entry->{total_duration}, $entry->{duration_count} ) // 0;` (impact from the reported mean)

**Owning record.** `features/616-gated-mean-derivation.md` D1 to D4; the
CLAUDE.md checkpoint on observation counts. Cross-reference: *Precise storage,
formatting at the output boundary*, to which the same issue adds the
per-message bytes mean and the run index's means as sites.

**Status.** Established.

---

## Raw value arrays: sorted once, at their last use, in the form measured for each store

**Definition.** A store of raw values under the raw data model (a time bucket's
durations, a message row's durations, the heatmap's per-bucket values, the
histogram's per-metric values and their highlight twins) is sorted once, by the
computation that needs it in order, after consolidation has returned, when the
arrays are final. The form of the sort is chosen per store, from measurement:

| Store | Sorted how | Why (measured, `features/680-statistics-duration-copies.md` § 4) |
|---|---|---|
| Time bucket | taken out of its store, sorted into a fresh array, both freed after the bucket's statistics | sorted in place and then freed, its scalars return to Perl's free lists in sorted order, scattered through memory; the displayed rows' arrays allocated next come from those lists, and every pass over them misses the cache (§ 4.12) |
| Displayed message row, by default | copied, the copy sorted in place, the store untouched | the store keeps every row's data, neither reordered nor enlarged, for a later reader (an interactive re-ranking of the message table); sorting the copy into a second fresh array is slower and costs a second copy (§ 4.12) |
| Displayed message row, under `-mem release` | taken out of its store, sorted in place, freed after its statistics | releasing it is the mode's purpose |
| Message row under `-so` on a statistic | sorted in place in its store by the ranking pre-pass; the displayed rows' statistics read that order without sorting again | the values are sorted once and the messages ranked once |
| Heatmap bucket, histogram metric | counted over the unsorted values, then sorted in place for the percentiles, then deleted or emptied | the count needs no order, and a pass in sorted order over values sorted in place visits scalars scattered through memory (§ 4.8); in place, the histogram's whole-run array is not doubled |

In-place sorts go through one helper, `sort_numeric_in_place($arrayref)`: the
array is aliased to a named array and assigned back to itself, the only form
Perl sorts in place. A message row's array is released after its last use only
under `-mem release`; every other store releases its array after its
computation. A consolidation cluster hands its array to the row it becomes and
keeps no reference.

**Intended uses.** Any new statistic, percentile or distribution computed from
a raw store: sort once, at the last use, in the form the table gives for a store
of that kind, and measure before choosing another. A pass that does not need the
order runs before the sort.

**Reasoning.** Each form above was settled by measurement, and each obvious
alternative was measured to cost something:
- `sort { $a <=> $b } @$ref` reads the stored scalars and builds a second array,
  two arrays of the values at once; with a working copy made first, three.
- Perl's numeric sort converts every scalar of an array holding a non-integer
  to a larger type (24 to 56 bytes) and never converts it back, so sorting an
  array that stays in its store, in place or into a copy, leaves the store
  larger.
- After an in-place sort, neighbouring elements point to scalars in the order
  the read allocated them, so a pass in sorted order is up to five times slower
  than over a freshly allocated sorted array.
- An array sorted in place and then freed leaves the free lists in sorted,
  scattered order, and what is allocated next inherits the scatter.
- Releasing every message row's array after its last use costs the time to free
  millions of values and lowers the peak only when a raw heatmap or histogram
  runs after statistics, so it is opt-in.

**Consumption sites.**
- `sort_numeric_in_place` :: `@values_in_place = sort { $a <=> $b } @values_in_place;` (the helper)
- `calculate_statistics` :: `$values = [ sort { $a <=> $b } @$values ];` (a time bucket's array, into a fresh array)
- `calculate_statistics` :: `$values = [ @$values ] if $bucket_data->{durations_in_store};` (an array that stays in its store: the copy is sorted)
- `calculate_statistics` :: `sort_numeric_in_place($values);`
- `calculate_all_statistics` :: `my $bucket_durations = delete $log_analysis{$bucket}{durations};` (a time bucket's array taken out of the store)
- `calculate_all_statistics` :: `$aggregated_data->{durations_into_copy} = 1;` (the time bucket's form)
- `calculate_all_statistics` :: `? delete $log_messages{$category}{$log_key}{durations}` (a displayed row's array taken out of the store, under `-mem release`)
- `calculate_all_statistics` :: `delete $entry->{durations} unless exists $displayed{$log_key};` (rows not displayed, released at the selection, under `-mem release`)
- `calculate_all_statistics` :: `$aggregated_data->{durations_sorted} = 1 if $presorted{$log_key};` (the ranking pre-pass's order reused)
- `group_similar_messages` :: `$entry->{durations}          = delete $cluster->{durations} // [];` (a cluster hands its array to its row)
- `calculate_heatmap_buckets_exact` :: `my $sorted_values = sort_numeric_in_place($bucket_values);` (after the range count over the unsorted values)
- `calculate_histogram_buckets_exact` :: `my $sorted = sort_numeric_in_place($values_ref);` and its highlight twin (after the range and the bucket count over the unsorted values)

**Owning record.** `features/680-statistics-duration-copies.md` § 2 (the
resource guidelines), § 4 (the measurements behind each form), § 5 (the
decisions). Cross-reference: *Data-model selectors resolved once per surface*,
which decides whether a surface holds raw values at all; #354, whose promotion
of large messages to a bin partition removes their raw arrays.

**Status.** Established.

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
block and in `build_column_layout` (audit, FP.1). The drift is #620 (the layout and the demand block read the registry predicate).

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
- `settle_message_option_flags` :: `$discard_active    = ( @discard_subs || $discard_field{'query-string'} ) ? 1 : 0;`: the expose, mask and discard flags and `@mask_subs` are derived once, from their final lists, after the three resolvers and `apply_discard_precedence`, which only build and trim lists (#613 D9).
- `read_and_process_logs` :: `if( $discard_active ) {`

**Owning record.** This entry.

**Status.** Needs refinement. Thirty-eight run-scoped flags exist; the capture
modes are string compares in the loop rather than booleans (item 8); the loop
carries about 107 tests of run constants per line, whose cost drop 2 measures.
The capture modes and the run-constant tests are #620.

---

## `-V` telemetry sections as the test surface

**Definition.** Every machine-readable diagnostic is a named section registered
in `%verbose_section_registry` and `@verbose_section_order`, emitted by an
`emit_<section>_verbose` sub gated on `section_requested()`, ASCII only, in the
one content shape (`tests/HARNESS-DESIGN.md` § Content shape): `key: value`
facts with snake_case keys, entity blocks, `<entity>: <name> key=value` lines,
tab-separated bulk records, `yes`/`no` booleans and `-` for an absent value.
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

**Owning record.** `tests/HARNESS-DESIGN.md` (§ Content shape for the line
forms; `features/605-input-units.md` D25 to D29). Checked by
`tests/validate-verbose-content-shape.sh`, which runs every registered section
and fails on a line that departs from the shape.

**Status.** Established. One naming drift: the `histogram-bin-counters` section
has two emitters and its emitter sub carries an older name (audit, FP.2). The naming drift is noted on #469, the next change to that section.

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
- `adapt_to_command_line_options` :: `my $resolved = resolve_metric_operand($heatmap_metric, '-hm/--heatmap');`
- `handle_histogram_option` :: `my $has_valid_metric = grep { defined builtin_metric_name($_, '-hg/--histogram') } @parts;`
- `resolve_message_name` :: `my $metric = builtin_metric_name($name);`: the one resolution `-x` and `-d` share (#613 section 5.2): the parsed field, the identifier (`-d` only) and the built-in metric in any case, then a user-defined metric by its name, else a key written in the line, carrying the metrics it feeds (`probe_key_metric`, `udm_line_key`).
- `resolve_mask_names` :: `my $identifier = $mask_identifier{ lc $given };`: `-m` resolves through the identifier table `-d` reads.
- `print_bar_graph` :: `push @csv_data, format_csv_value($total_occurrences, 'occurrences');`
- `share_row_text` :: `my $share = value_text( $count / $denominator * 100, kind => 'percentage', budget => 'share row', width => $slack );`
- `write_index_file` :: `my $now_iso = format_timestamp(time(), precision => 's', shape => 'iso');`

**Owning record.** This entry; worked contracts in
`features/histogram-charts.md` § Command Line Interface (metric operands),
`docs/percentage-presentation.md` (percentages),
`features/524-bucket-size-unit.md` D1 (time units).

**Status.** Needs refinement: the audit's items 1 to 7 list the copies. Refined by #525 (one timestamp formatter), #614, #616 and #618, each closing the copies its stage of the #342 review assigned to it; #613 (one vocabulary for names) closed the metric, field, identifier and statistic names; #617 (one width-to-format rule) closed the number formatters (entry *Width-to-format rule: one dispatch per metric kind*); #605 closed the copies of the bound set and the number-and-unit split (entry *Quantity units*).

---

## Precise storage, formatting at the output boundary

**Definition.** A value in a data store (`%log_messages`, `%log_stats`,
`%log_analysis`, `%heatmap_data`, `%log_occurrences`) keeps the type and
precision the computation produced for its whole life. Rounding and unit
formatting happen only where the value leaves the tool, per surface, once per
write, and the result is never stored: the CSV writers pass numbers through
`format_csv_value`, and a nice column is rendered beside its raw twin in the
row being written.

**Intended uses.** Any stored statistic, total or mean, and any new renderer
of one. A renderer that wants a different tier, width or unit formats the
number itself at its own emit site; it never reads a string another surface
made.

**Reasoning.** Measured cases: the integer-truncated mean behind #271 made
the emitted standard deviation 15.664 against the reference implementation's
12.495 on a 155,109-sample access-log message; storage-time rounding behind
#268 hid any drift below display precision from the statistics harness; the
per-message duration total stored as its medium-tier string (until #273) left
no tier to any later renderer and needed a second numeric field beside it for
the sort and the CSV's raw cell.

**Consumption sites.**
- `calculate_statistics` :: `my $mean = $bucket_data->{total_duration} / $duration_count;`
- `print_bar_graph` :: `value_text($log_stats{$bucket}{duration_sum}, metric => 'duration', budget => 'nice cell')`
- `print_message_summary` :: `my $total_bytes = defined $total_bytes_num ? value_text( $total_bytes_num, metric => 'bytes', budget => 'nice cell' ) : undef;`
- `print_message_summary` :: `value_text( $total_duration, metric => 'duration', budget => $total_budget )` (the messages-table total, walked by its column width)
- `print_message_summary` :: `defined $total_duration ? value_text( $total_duration, metric => 'duration', budget => 'nice cell' ) : undef,` (the MESSAGES CSV `duration_nice`, beside `format_csv_value($total_duration,    'duration'),`)
- `format_csv_value` :: `my $family = resolve_csv_column_family($column);` (every CSV emit)

**Owning record.** `features/273-store-precise-duration-totals.md`, with
#268's completion record and `releases/v0.15.0.md`.

**Status.** Established. The per-message bytes mean (`print_message_summary` ::
`my $bytes_mean = $log_messages{$grouping}{$key}{bytes_mean};`) and the run
index's six means (`write_index_file`, through `format_csv_value` at a fixed two
decimals) are sites; the entry *Observation counts and gated means*
cross-references this one.

---

## Width-to-format rule: one dispatch per metric kind

**Definition.** Every number a person reads is rendered by one dispatch,
`value_text()`, given the value, its kind (or the metric whose kind
`resolve_value_kind()` resolves, with its floor: the source's resolved unit or
a metric's declared unit), and the name of a budget table row (`%value_budget`),
plus a width where the surface has one. A row names a tier (short, medium,
long: how far the number is abbreviated), a fit (tight or loose: the space
before the unit), a width where fixed, a precision where a record locks one,
and the surface's intent (`accurate`, `tabular` or `prose`; `precise`, the exact
value, only where a row names the switch that asks for it, as `-pv` does for
the legend). A row that names no tier walks for one
(`value_column()`, `value_walk_row()`): its intent (`%value_intent`) is a
tolerance and an order of what gives way, and the walk takes the first step at
which every value the surface shows fits and stays within that tolerance of its
most exact spelling. The digits come from the producer: the row's precision,
else the tier's maximum (`%tier_decimals`), never finer than the source's
resolution. A count of up to five digits shows unclimbed where that is exact
and no wider (`1800`, never `1.8k`); bytes and durations climb at their
ladder's steps (`%value_unclimbed_digits`, one field per kind). A value rounding up to the next step's size renders at that step;
trailing fractional zeros are stripped by `strip_trailing_zeros()`. The per-kind
formatters (`format_time`, `format_bytes`, `format_number`, `format_cv_display`,
`format_percentage`) are the dispatch's arms and have no other caller.

**Intended uses.** Any number a person reads: a timeline cell, a table cell, a
chart label, a summary row, a notice. A new surface adds a budget row (or reuses
one) and names its intent; it never calls an arm, passes decimals or chooses a
spacing. A notice names the row that fits what it exposes. Retuning a surface's
intent is a one-line edit of its row; retuning an intent is one entry of
`%value_intent`.

**Reasoning.** One value printed three ways in one run (`1.50 k`, `1.5k`,
`1.5k`), values cut by their columns (`999 millisecon`, 21 of 74 regression
goldens), a zero duration in the ladder's lowest unit (`0ns` beside `0ms`), and
five copies of "which formatter for this kind" with two of "which tier for this
width" (`features/617-width-to-format-rule.md` § 1).

**Consumption sites.**
- `value_text` :: `my $row = ref $p{budget} ? $p{budget} : $value_budget{ $p{budget} }`
- `resolve_value_kind` :: `my $config = udm_config_by_name($metric) or return { kind => 'count' };`
- `value_walk_row` :: `my $intent = $value_intent{ $row->{intent} // 'precise' };`
- `print_bar_graph` :: `$column_budget{ $col->{id} } = value_column( metric => timeline_column_metric( $col->{id} ), budget => 'timeline column',` (the timeline value columns, resolved once per column)
- `print_message_summary` :: `my $total_budget = value_column( metric => 'duration', budget => 'messages total',`
- `get_heatmap_column_header` and `render_histogram_legend` :: `budget => 'chart label'`; `format_histogram_dimensions_line` :: `budget => 'dimensions line'`
- `emit_classification_percentage_notices` :: `budget => 'notice share'`; `report_skipped_final_pass` :: `budget => 'notice'`
- `format_csv_value` :: `return strip_trailing_zeros(sprintf("%.${decimals}f", $value));`

**Owning record.** `features/617-width-to-format-rule.md` (D1 to D24). Its model
is the one-table-per-surface shape of *Precision tiers: one lever, one table per
surface*.

**Status.** Established.

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
- `emit_classification_percentage_notices` :: `print STDERR "Warning: " . value_text( $r->{unclassified}, kind => 'count', budget => 'notice' ) . " included line(s) ($leak_pct) matched`
- `bin_consolidation_notice` :: `print STDERR "Note: $detail, so their percentiles are approximate"`
- `print_deprecation_notices` :: `print STDERR "Warning: $notice->{spelling} is deprecated$notice->{as}$given: $notice->{advice}\n";`: the one way a deprecation prints. A deprecated option or spelling is recorded with `record_deprecation` as it is met (with the options a spelling was given on) and printed once at option settlement (#613 D17); the `-os`, `-uuid`, `-s` and `-ms` notices route through it.
- `resolve_discard_names` :: `print STDERR "Note: -d/--discard removes the key $name, which the $metric metric reads: the metric is switched off\n";`: a metric switched off because `-d` removed the key it reads says so, at option settlement (#613 D4, D12).

**Owning record.** This entry, until #412 (the notices surface) lands and
inventories every ad-hoc notice.

**Status.** Needs refinement: one warning is emitted inside the option
parser's warning capture and never prints (item 1, F1.17), refined by #614.
The numbers inside notices render through the one dispatch since #617: each
notice names the budget row for what it exposes, `notice` (prose) for a scale
and `notice exact` for a count a list beside it must agree with, and a share
the `notice share` percentage row (entry *Width-to-format rule: one dispatch
per metric kind*).

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

**Status.** Needs refinement (F1.6, F1.17). Refined by #614 (one pushback rule, a usage error for an argument that resolves to no file).

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
- `read_and_process_logs` :: `$log_key = substr("[$log_level] $message", 0, $max_log_message_length);`

**Owning record.** `features/312-numeric-criteria-highlight-selection.md` §
Core mechanism; `features/478-highlight-decision-read-back.md`;
`features/567-discard-named-values-from-message.md` § Post-release finding;
`docs/perl-performance-optimization.md`; `tests/baseline/README.md`.

**Status.** Needs refinement: the loop carries about 107 tests of run constants
per line and recomputes the millisecond bucket size per line (audit, item 8,
measured in drop 2). The key length is resolved once per run since #619 (one
per-run key cut). Refined by #620 (hoisting in measured steps) and, as a switchable follow-up, #621.
