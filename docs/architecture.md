# Architecture

The map of `ltl`'s source: where things are, how a run flows, and which record
owns each area. The recurring mechanisms the tool is built from are in
`docs/architecture-patterns.md`, one entry each, read before any code is
written. This is a developer document, written in Perl identifiers; it is not
part of the wiki.

## The source

`ltl` is a single Perl file with three section markers, searched for rather
than reached by line number: `## GLOBALS ##` (`$version_number`, configuration,
data structures, options), `## SUBS ##` and `## MAIN ##`.

**Processing flow:** `adapt_to_command_line_options()` →
`read_and_process_logs()` → `calculate_all_statistics()` →
`normalize_data_for_output()` → `print_bar_graph()` → `print_summary_table()`.

## Format recognition

Runs through the format registry (marker `## FORMAT REGISTRY`): declarative
per-format specs in `format_registry_specs()` are built by
`build_format_registry()` into a live registry; one generated scan sub per
most-recently-used order is compiled on demand and cached by order signature.
Every run self-validates against each entry's sample lines. Detection evidence
comes from a read-only sample (`sample_file_for_detection()`: front, middle and
end parts) before a file's first line; variant groups share a line shape and
are scored by `select_format_variants()`; `-lf` pins a format. Each spec
declares its success/failure `classification` and `event_ledger` flag,
compiled into the scan block. Adding or changing a format means editing its
spec, never hot-loop code. User surfaces: `--help formats`,
`--explain classification`.

## Read path

Marker `## GENERATED READ LOOP`: a file above 2 MB is read by a body generated
per run from the per-line loop's own text, its `#@` gate markers resolved once
and compiled per file; at or below it, and under `-D`, by the loop itself,
which stays the one source and the reference. A gate added to the loop gets
its marker. User surfaces: `-D`, `-V read-path`.

## Key structures

`@format_registry` / `@format_scan_order` / `$format_scan_sub`;
`%log_occurrences` (tallies per bucket); `%log_analysis` (bucket statistics);
`%log_messages`; `%log_stats`; `%heatmap_data`; `@heatmap_boundaries` (N+1
boundaries for N columns).

## Column layout

`@column_layout` is the single source of truth for widths, spacing, visibility
and colours; dynamic columns via `add_dynamic_column()`; auto-hides at narrow
widths. `@column_colors` holds per-column ANSI definitions.

## Platform

`get_memory_usage()` reads process memory through `ps` on macOS,
`/proc/self/statm` on Linux and `Win32::API` (`K32GetProcessMemoryInfo`) on
Windows, branching on `$^O`.

## Heatmap

`-hm duration|bytes|count`, `-hmw <width>`, `-lbg`: logarithmic bucket
boundaries, gradients yellow/green/cyan by metric.

## Options for development

Hidden options, documented here and on no user surface: `--disable-progress`
(always passed from an agent session: `docs/toolchain-guidance.md` § Running
`ltl` from an agent session), `--terminal-width N` (the render width in a
non-TTY context), `--detection-window=N` and `--generated-loop-threshold=N`.
User options: `docs/usage.md`, `--help`.

## Records by area

| Area | Record |
|---|---|
| Format detection, extraction, classification | `features/log-format-registry.md` (system of record), `features/453-success-failure-classification-event-ledger.md` |
| Read path | `features/621-generated-read-loop-body.md` |
| Column rendering | `features/column-layout-refactor.md` |
| Heatmap and histogram | `features/heatmap.md`, `features/histogram-charts.md`, `docs/explain/` |
| Bin-counter substrate and precision tiers | `features/189-histogram-bin-counter-primitives.md`, `features/293-precision-lever-unification.md` |
| Notices and choices | `docs/notice-surfaces.md` |
