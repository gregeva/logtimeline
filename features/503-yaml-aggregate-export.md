# YAML aggregate export describing the analysed population (#503)

## Status

- Issue: #503 (FEATURE: YAML aggregate export describing the analysed population, emitted with `-o`)
- Phase: **delivered** — PR #523 merged into `release/0.18.0` as a182e2a on 2026-09-03; issue closed. The full suite and the four before/after benchmark cases ran on 730f85f; the final two commits (the heatmap block nested under its metric and its harness, drift row and docs) were verified by the aggregate-export harness alone, the architect having waived the final full run so the release baseline can proceed. Planning history:  — every decision D1–D22 locked on 2026-09-02; the execution plan approved by the architect the same day, after every cited sub, variable, fixture and tooling site was re-verified on `release/0.18.0` at 159e886. All four drops are on branch `503-yaml-aggregate-export`, one commit each (§ *Drop 1 record*, § *Drops 2–4 record*); one PR follows the completion gate. Both `-V` contracts are locked (`aggregate-export` built from the draft the architect closed the planning on; § *Findings from the build* lists what the build settled beyond the draft). Produced from a code audit of `release/0.18.0`; every statement of the form "the code does X" was verified on that tree on 2026-09-02 and cites the producing sub and a snippet to grep for.
- Consumer inputs (outside this repository — the Performance Positioning methodology, v0.5, 2026-08-31): the consumer-requirements document (R1–R18 plus the §7 blocker and advisory tables), the illustrative export YAML hand-authored to it, and the methodology standard. Their vocabulary is the consumer's; this document restates every field in ltl's. The consumer's *structure* (provenance / population / measurements / series) is kept.
- Builds on: #453 (per-format success/failure classification and the event-ledger property), #452 (per-bucket success/failure counts in the STATS CSV and the percentage columns — its D10 [no surface prints a percentage the eligibility ladder disqualified; raw counts always print] applies to this export), #458 (`-n 0` retains nothing per message), #34 / #187 (histogram bin counters: the population-wide percentile surface), #460 (histogram and heatmap percentiles computed from the counters at capture resolution).
- Related, not gates: #454 (notice that statistics describe a filtered subset — open, backlog; the excluded-line accounting below is what that notice would report), #155 (parse timezone offsets and normalise to UTC — open, on hold; gates an honest `UTC` declaration), #504 (a second `--explain` topic family for analysis techniques — the same consumer's sibling request), #387 (user-configurable YAML format definitions — the only other YAML in the record, unrelated in content).

## Overview

When `-o` is active, ltl writes one YAML file per run beside the STATS CSV, describing the whole analysed population with **aggregates only**: what was read, what the run declared about it, the figures over the population, and the figures per time bucket. A `-n 0 -o` run therefore yields a complete machine-readable description of the population with no per-message artifact.

**Governing principle (architect, 2026-09-02): the export exposes what the run computed.** Every statistic and surface the tool produced for the run — the run summary, every column family of the STATS CSV, the histogram's population-wide statistics for each histogrammed metric, the heatmap's per-bucket percentiles — is written to the file when it is present, in ltl's own names, and nothing is computed for the file that the run did not already compute. The one exception is the population duration (R5), which is a subtraction of two values the run already holds and which joins the run summary at the same time. Consequently the run's options decide what the file contains: `-hg <metric>` is what makes population-wide percentiles for that metric exist, `-hm <metric>` is what makes per-bucket percentiles under the heatmap model exist, and a consumer that needs a figure asks for the option that produces it. The consumer's profile (its mandated option set) is where that is settled; ltl records, it does not enforce.

The file is read by a consumer that never sees the logs. Everything it needs to verify that the run executed cleanly must be in the file, and every figure must be exact: no rounding, no unit escalation, no formatting (the population duration additionally carries its human-readable form, by the architect's direction).

Two things the consumer asked for are deliberately **not** in the file, per the issue body: a second, semantic version (a change to what a field means is carried by the ltl version in provenance plus a release-note bullet), and a **named execution profile** — the consumer validates the invariant options from the recorded option set. The audit found the second exclusion is also forced by vocabulary: `profile` in ltl is `-pr/--profile`, timeline folding onto one canonical day or week, with a `-V profile` section and a `--help profile` topic (F10).

## Audit: the consumer's fields against the code (verified 2026-09-02)

Method: eight subsystem readers, each followed by an independent refuter that re-read the code for every claim, then a completeness pass over R1–R18 and every §7 condition. The first draft of this document mis-framed the population-percentile finding (it treated the histogram surface as a fallback and proposed a new store); the architect corrected it on 2026-09-02 and F1 below is the corrected finding.

### Findings that reshape the consumer's assumptions

- **F1 — Population-wide percentiles exist on the histogram surface, per metric, when `-hg` is active.** `-hg` (bare: every metric with data; or a comma list of `duration`, `bytes`, `count`, a UDM name — `handle_histogram_option()`) captures each metric into one bin-counter partition over the whole population (`counter_update(\%histogram_counters, $metric, ...)` in `read_and_process_logs()`). `finalize_histogram_unified()` then computes, per metric, the full ladder `p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999` plus `count`, `min`, `max`, `bucket_count`, `decades` into `%histogram_stats{$metric}` (`my %stats = (count => $n, min => $min, max => $max, ...)`), re-projects the partition onto the chart geometry, and deletes the partition. The highlighted subset gets the same set in `%histogram_stats_hl{$metric}`. Under `-hgdm raw` the same keys come from `calculate_histogram_buckets_exact()` by nearest rank. Three caveats an export must carry: the capture gate excludes non-positive values (`defined $duration && $duration > 0`); the stored `min`/`max` are the chart's adjusted extremes (`if ($min == $max) { $min = $min * 0.9 ...}` and `$min = 0.1 if $min <= 0;`), so the observed extremes are read from `%histogram_data_min{$metric}` / `%histogram_data_max{$metric}`; and each percentile is clamped to those adjusted extremes. The percentile values are also emitted at full precision on `-V histogram-percentile-ticks`, the cross-surface anchor for the harness. There is no population-wide statistic without `-hg` — the two other stores are per bucket and per message (`resolve_statistics_group_demand()`: `my %store_demand = ( bucket => ..., message => ... );`) and the per-bucket raw sample is freed per bucket.
- **F1b — Per-bucket percentiles exist on two surfaces.** The bucket store (`%log_stats{$bucket}`, duration only, demanded by the `stats-csv` consumer whenever `-o` is active, `raw` by default) carries the full ladder plus `min`, `mean`, `max`, `std_dev`, `cv`, `iqr` and the shape moments — the STATS CSV columns. The heatmap (`-hm <metric>`, exactly one metric per run, `bin` by default) captures one partition per bucket (`counter_update(\%heatmap_counters, $bucket, $heatmap_value, $heatmap_stream_bpd)`), and `finalize_heatmap_unified()` computes `p50 p95 p99 p999` per bucket (`for my $pair (['p50', 0.50], ['p95', 0.95], ['p99', 0.99], ['p999', 0.999]) { my ($v) = percentile($src, $q); ...`), then keeps only each value's **cell index** in `%heatmap_percentiles{$bucket}` and deletes the partition. The values exist at finalize and are discarded. For the export, `finalize_heatmap_unified()` computes the **full ladder** per bucket when `-o` is active and retains the values (architect, 2026-09-02) — one `percentile()` call per slug per bucket at finalize, from the partition that is already in hand, no per-line cost. The two surfaces agree on the population per bucket and differ in model.
- **F2 — `included = successes + failures + unclassified` is an identity, not a check.** `classification_reconciliation()` defines `my $unclassified = $total_lines_included - $classified;`. It holds by construction on every run. The signals that carry information are `unclassified > 0`, `pct_eligible`, `non_qualifying_lines`, and `unmatched_lines` (a blended run whose second producer is not in the registry raises no format signal at all — its lines land in `unmatched_lines`, not in a second detected format).
- **F3 — `read − included` is not "excluded by filter".** `$total_lines_read` counts every physical line; `$total_lines_included` counts lines that matched a registry format, carried a category in `%log_level_set`, parsed a timestamp, and survived every filter. The difference mixes format non-recognition (`unmatched_lines`), vocabulary rejection (`unless (exists $log_level_set{$category_bucket}) { next; }`), unparseable CSV rows, the time window, the `-pr` fold, and the content/outcome/numeric filters. No counter tallies filter drops (only `%numeric_filter_no_metric`, a stderr note, and `$profile_dropped_samples`, in `-V profile`). Measured: an unfiltered run on `tests/fixtures/message-control-characters-unmatched.txt` gives read 3 / included 2. The per-file `sum(match_count) − sum(sel_match_count)` from `%index_file_data` is a genuine filter-drop figure but is unsound on any run naming a path twice without `-r` (the per-file hash is re-initialised per read) and counts `-st/-et` drops as exclusions, which #454 (filtered-subset notice) scopes out by architect decision.
- **F4 — Three different windows exist, and the population duration is computed nowhere.** The **requested** bounds are `$filter_range_start/$filter_range_end` (raw user strings; `-et` is exclusive: `next if( ... $timestamp_epoch >= $filter_range_epoch{'end'} )`, so a 05:00→05:00 request is the half-open interval [start, end)). The **observed** bounds are `$output_timestamp_min/max`, the first and last *included line* (set from `$bucket_epoch`, which equals `$timestamp_epoch` except under `-pr`; verified: a fixture whose first line is 00:00:01 prints "between 2025-05-07 00:00:01" at `-bs 60 -s`). The **bucket** bounds are the floor-aligned series keys, which precede the observed start by up to one bucket by construction. `grep -n output_timestamp_max ltl` shows no subtraction anywhere: the population duration (`$output_timestamp_max − $output_timestamp_min`) is a value the run holds the inputs for and never states. Nothing tests alignment; a test over observed bounds reports false on every correctly-run analysis (the last included line falls short of the exclusive end), so it is computable only over parsed full-date filter bounds. A bare time-of-day `-st 05:00` populates `%filter_range_tod` (a repeating daily slice, exposed on no surface) and would pass a naive alignment test while the population is a set of daily fragments.
- **F5 — ltl cannot truthfully declare `time_base: UTC`.** Every format's in-line offset is discarded by a transform before parsing (`chop_tz_offset => q{ $timestamp_str =~ s/ \+\d{4}$//; }`) and the wall clock is read with `timegm`; rewriting a fixture's `+0000` to `-0500` produced a byte-identical run heading. The registry's declarative `time => { ..., tz => 'local' | 'utc' | 'offset_in_line' }` is stored (`$entry->[FR_TIME] = $spec->{time};`) and read by no code path. `format_epoch_iso()` deliberately emits no `Z`; nothing in the tool emits one. Honest declaration until #155 lands: the winning format's declared `tz` as intent, plus an explicit statement that offsets are not applied.
- **F6 — `-bs` is not always minutes, and the bucket count has two candidate sources.** `adapt_to_terminal_settings()`: seconds under `-s`, milliseconds under `-ms`, minutes otherwise; when `-bs` is absent the size is chosen from terminal height on a five-rung ladder (120/90/60/30/10 minutes), and a piped run (fallback height 24) silently takes 120-minute buckets. The unit-safe figure is `$bucket_size_seconds`. The series row count is `scalar keys %log_occurrences` (exported today as `COUNTS log_occurrences_entries` in `-V benchmark-data`), contiguous over the observed span because `initialize_empty_time_windows()` materialises empty buckets — unless `-oe`. `COUNTS log_analysis_entries` counts only metric-observed buckets and is the wrong figure for a series (measured: 10 vs 2 on a metric-less fixture).
- **F7 — The run-level and per-bucket percentage eligibility rules differ.** Run level: `my $eligible = ($classified > 0 && $total_non_qualifying_lines == 0) ? 1 : 0;` — one non-qualifying line anywhere removes both run-level percentages. Per bucket (`normalize_data_for_output()`): only buckets touched by a non-qualifying source lose theirs, getting `success_pct_count`/`failure_pct_count` instead (#452 D17 [ineligible windows show counts, not blanks]). A run can legitimately carry per-bucket percentages while the overall pair is absent. `%bucket_outcomes` slot 3 (the per-bucket non-qualifying count) is computed and exported nowhere; without it a reader cannot tell "disqualified" from "no classified line".
- **F8 — Percentile gating needs an observation count, which each surface holds differently.** The significance rule (`pN` needs `10/(1−N/100)` observations) is published in `--explain percentiles` and `docs/explain/statistics.md`, and the same text states ltl emits every percentile regardless. The histogram keeps `count` per metric; a heatmap partition's total is the sum `percentile()` already forms (`my $total_N = $under + $in_total + $over;`); under the default `raw` bucket model no per-bucket duration sample count survives `calculate_all_statistics()` (`calculate_statistics()` returns no count key), while `-bdm bin` keeps `$log_analysis{$bucket}{duration_count}`. `occurrences` is not a substitute — it counts every included line, not lines carrying a duration. Separately, `docs/usage.md` states `p999` needs ~1k where the explain surface and the arithmetic say ~10,000 (§ *Record corrections*).
- **F9 — Status families are ltl categories.** The keys are the bare `1xx`…`5xx`, but they live in `%category_totals` beside `INFO`, `ERROR`, `Pause Young`, `DATA`; an unobserved family is **absent** from the hash and from the STATS CSV header (no `1xx` column on a fixture without 1xx lines); and a highlight **replaces** the key (`$category_bucket .= '-HL'`), so `4xx` and `4xx-HL` partition the population. `%category_totals` is filled in `normalize_data_for_output()`, i.e. it exists only after the normalise stage. Run totals reach no machine surface today (rendered only, share denominator `LINES INCLUDED`).
- **F10 — Vocabulary collisions.** `profile` (timeline folding: `-pr`, `%profile_modes`, `-V profile`, `--help profile`). `bin_counter` (ltl's validated token is `bin`, features/266-data-model-selectors.md § "raw and bin are the only accepted values"; and the model resolves **per surface** — histogram/heatmap default `bin`, message-stats/bucket-stats default `raw` — so `percentile_model` cannot be one scalar). `p99.9`/`p99.99` (ltl slugs `p999`/`p9999`; ltl also carries `p99999`). `success`/`failure` (machine spelling is plural `successes`/`failures` everywhere; percentages are `success_pct`/`failure_pct`). `requests` (no such noun; success+failure is `classified`; `occurrences` is every included line). `unit: milliseconds` (unit tokens are `ns|us|ms|s`). `eligibility floor` (the n≥4 shape gate and #418's sort floor). `detected: access_log/combined` (ltl's identity is the format slug: `tomcat_access_with_duration`, `httpd_access_with_duration`, …; there is no Apache combined/common distinction).
- **F11 — No working directory, no directory concept, paths as supplied.** `grep -c "Cwd\|getcwd" ltl` is 0 (build/cpanfile's `requires 'Cwd';` is stale). `expand_recursive_pattern()` returns files only; nothing counts, groups or stores a directory. Every existing file surface prints the full path list verbatim — `FILES` in benchmark-data ("Paths are recorded exactly as the caller supplied them"), `file:` lines in format-detection, the run-summary pane — the opposite of R6. Under `-r` a root of `.` yields `env-01/apache` (no `./`), and a Windows-style pattern passes its root through verbatim (mixed separators).
- **F12 — `-n 0` guarantees message-text absence, not export-wide content absence.** The guarantee rests on the single `if( $capture_messages && defined( $message ) )` gate plus the forced `$group_similar_sensitivity = "none"`. Surfaces that still carry log-derived or operator-authored strings under `-n 0 -o`: thread-pool column names derived from the thread field (`( $threadpool ) = $thread =~ /(.*)-\d+$/;`, reaching the STATS CSV header — reproduced), UDM column names (operator text), the **STATS CSV filename** (`build_csv_filename()` embeds every non-file argv token: `-i 'secret/url/path'` produced `…-isecret_url_path.csv`), and `-V runtime-config`'s `include (merged):` full regex. `ltl-index.csv` is written by default and carries every file path plus the url-encoded include/exclude operands unless `-ni`. Under the governing principle these columns are exported when their options are used; the consumer's profile is what keeps them out of its runs.
- **F13 — No YAML writer is present yet, and the module is already chosen.** The `use` block carries no YAML or JSON module; `YAML`, `YAML::XS`, `YAML::PP`, `YAML::Tiny` are absent from the Homebrew Perl; `JSON::PP` and `CPAN::Meta::YAML` are core and unused. #387 (user-configurable YAML format definitions) locked `YAML::PP` as a hard dependency (D17). `build/cpanfile` is regenerated only when absent (`if [ ! -f cpanfile ]` in build/install-deps.sh and build/macos-setup.sh), so a new `use` does not propagate on its own; the Text::CSV / Text::CSV_PP precedent names the pure-Perl backend explicitly so PAR bundles it.
- **F14 — Every stored duration is milliseconds; `duration_unit_resolved` names the source unit.** `read_and_process_logs()` converts at the include point (`$duration = convert_duration_to_ms($duration, $duration_unit_override);`; measured `duration_max` 41 by default vs 0.041 under `-du us`). `$duration_unit_source` can only read `default` or `-du <value>` — a format-declared non-ms unit converts silently and never appears in provenance.
- **F15 — No surface serialises the effective invocation.** `print_run_options()` strips the file operands by value (`next if exists $argv_hash{$arg}`), which also drops any option value string-equal to a file operand (reproduced: `-e <fixture> <fixture>` echoed without the pattern), and does not shell-quote. `-V runtime-config` emits only supplied flags present in `%resolved_values` (75 keys; 29 long names can never appear), and `-lf`, `-pr`, `--detection-window` are absent from `_resolve_short_to_long()`'s `@specs` so appear nowhere. `%option_overrides` is declared and read but never written (the `; clamped from` annotation is dead: `-dmp 99` exports as `5` with no mark). `@ORIGINAL_ARGV` is snapshotted before the LTL_CONFIG splice; the environment half survives only as the raw `LTL_CONFIG:` row.
- **F16 — No generation timestamp, and two conventions disagree.** `write_index_file()` uses `strftime("%Y-%m-%dT%H:%M:%S", gmtime())` (UTC, no `Z`); `build_csv_filename()` uses `localtime()` in `YYYY-MM-DD_HHMMSS`. `-V benchmark-data` carries no date row.
- **F17 — The existing machine surfaces round.** `format_csv_value()` in the default `-cp` mode rounds the duration and percentile families to 0 decimals at the ms unit (`ms => 0` in `%decimals_by_unit`), strips trailing zeros, and forces rate columns to 1 decimal; only `-cp full` returns the stored double. The `-V` percentages are pre-rounded (`sprintf('%.3f', ...)`, `sprintf('%.1f', ...)`). `duration_nice`/`bytes_nice` are formatted strings. The export reads in-memory values (`classification_reconciliation()`'s unrounded ratios, the bare `%log_stats` keys, `%histogram_stats`), never a `-V` line and never `format_csv_value()`.
- **F18 — Declarations exist internally but not as values.** Distinct detected formats: `@format_legend_order` (counts slugs across the run; a mid-file change contributes a second entry — proved on `tests/fixtures/classification-format-switch.txt`). Event-ledger tri-state: arithmetic over `event_ledger_files: N/M` (ledger == bound → all; 0 → none; else mixed), with the known blind spot that `format_classification_rule_change()` overwrites the per-file flag with the last classifying entry's, and only when criteria signatures differ (#453 D32). "Classification configured": the useful definition is `FR_CLS_BOTH` / `%format_detection{$file}{cls_both}` — because `%classification_default` declares failure only, "both outcomes declared" equals "declares a success rule" equals exactly the five access-family entries; `java_gc_g1` declines (`FR_CLS_SIG == 0`). `cls_both` appears on no output surface. `-lf` produces the same per-file `format:` value without any detection (`apply_format_pin()`), so a pinned blended run satisfies "one format" trivially; `format_pin:` lives in `-V format-detection`. No format family/kind is declared anywhere — "is an access log" has no ltl-side signal.

## Requirements (ltl form)

Restated from the issue body and the architect's 2026-09-02 direction, corrected where the audit showed the consumer's wording could not be met as written. Consumer R-numbers in brackets.

- **R1 — One file per run, with `-o`.** YAML, aggregates only, written where the STATS CSV is written (the current directory), named by the STATS CSV convention **minus** the argument suffix (F12: the suffix discloses filter text). No new option. [consumer R1]
- **R2 — What the run computed is exported; nothing is computed for the file.** Every present surface is written under ltl's names: the run summary (category totals, line counts, the classification rows, timing and memory), every STATS CSV column family that is active (outcomes, categories, rates, duration statistics, bytes and count aggregates, user-defined metrics, thread-pool activity, sessions), the histogram's population-wide statistics for each histogrammed metric and its highlighted subset, and the heatmap's per-bucket percentiles for the heatmap metric. A surface that was not produced has no keys. The one computed addition is the population duration (R5). [architect, 2026-09-02; consumer R7]
- **R3 — No per-message content.** No message text, URL, or per-message record, whatever `-n` says: the top-messages table and the MESSAGES CSV are not mirrored. Category names are a closed vocabulary. Thread-pool and user-defined-metric names are log-derived or operator-chosen; they appear only when those options were used (R2), and the file name carries no argument text. The recorded invocation carries the operator's own filter patterns — a disclosure the operator made when they typed them; the file does not redact them. [consumer R2, R10; issue body]
- **R4 — Provenance.** ltl version; the two option strings exactly as the terminal prints them under the timeline — `options.command-line` and `options.environment` (D5); the population-selection signature exactly as `serialize_filters()` produces it for `ltl-index.csv`; the resolved data model per surface and the precision tier; the resolved duration source unit; the `-pr` fold mode and `-lf` pin when given; the generation instant. All of it is result-determining. The consumer's *contextual* class has no member: the working directory is not recorded (D9), so the block is absent and consumers already accept that. [consumer R3, R10]
- **R5 — The population duration, in the file.** The span from the earliest to the latest included timestamp (`$output_timestamp_max − $output_timestamp_min`); the file carries it as raw seconds and in the tool's time formatter's human-readable form. The run summary does not change (architect, 2026-09-02: the summary table stays as it is; the file exposes what it shows). [architect, 2026-09-02; consumer R5]
- **R6 — The observation window is the one the run summary states.** Start and end are the earliest and latest included timestamps — the two the file-list heading prints — with the population duration of R5 beside them in seconds and in the formatter's form. Nothing else: no requested-bounds block, no alignment flag; a consumer that wants to test alignment compares the two instants it is given (D7). The first and last bucket are what the series already carries. [consumer R5, narrowed; architect, 2026-09-02]
- **R7 — Format declarations, per matched format and for the run.** One entry per matched format slug (`@format_legend_order`), each with its event-ledger boolean; the two counts behind `event_ledger_files: N/M`; the mid-file rule-change count; and the run total of unmatched lines. No classification declaration per format (D10). Counts of the list and any all/none/mixed reading are the consumer's (D14). [consumer R4, §7 format blockers]
- **R8 — Source attribution without disclosure.** File count (reads, as `files:` reports today) and the count of files that contributed at least one included line; the count and list of directories containing selected files, **relative to where ltl was run from**. No file list, and the working directory itself is never recorded (D9). [consumer R6]
- **R9 — Line accounting as the funnel's stages.** `lines_read` (every line read), `lines_unmatched` (skipped because no format matched), the lines excluded by a filter criterion after matching, counted per cause — time window, `-pr` fold, content and outcome filters, numeric thresholds, other (vocabulary rejection, unparseable CSV rows) — and `lines_included` (passed every gate; the population the classification tallies partition). A CSV file's first line is metadata, matched to no format: it counts as unmatched (D22). The same counters are the `-V filter-summary` section and the run summary's line rows. [consumer R7 volume, R18; architect, 2026-09-02]
- **R10 — Outcome figures at both scales.** `lines_included`, `classified` (= successes + failures — the consumer's request total), `successes`, `failures`, `unclassified`, `success_pct` and `failure_pct` over the classified denominator **only when eligible** (#452 D10), `pct_eligible`, `non_qualifying_lines`; the category totals keyed by ltl category name; the same per bucket, with the bucket's non-qualifying count so an absent percentage is explained. [consumer R7]
- **R11 — Percentile depth follows the published rule at every scale.** Each `pN` is present only when its surface's observation count satisfies `10/(1−N/100)`; `min`, `mean`, `max` and counts are never gated. The STATS CSV is unchanged. [issue body; consumer R7]
- **R12 — Exact values.** Every number is the in-memory value. Nothing passes through `format_csv_value()`, `format_percentage()`, `format_time()` or a pre-rounded `-V` string; `-cp` does not apply to this file. The population duration's human-readable form, the total time and the peak memory are the stated exceptions (D13, D19). [consumer R8]
- **R13 — One structural version.** `schema_version: 1`. Adding a key is non-breaking; renaming or removing one, or changing a key's meaning, bumps it and is called out in the release notes. [consumer R9 as narrowed by the issue body]

## Proposed schema (draft — names are ltl's, structure is the consumer's)

Conventions: snake_case keys (the `-V` key convention); YAML booleans `true`/`false` (the three text conventions on `-V` — `yes|no`, `0|1`, bare `1` — are terminal conventions and none is a precedent for a data file); **absent means not produced, not observed, or not eligible**, never `null` or `0` (ltl's convention on every surface: an unobserved category has no column, an ineligible percentage has no key); timestamps taken from the logs are **the strings the terminal and the STATS CSV already print** — the heading's window bounds and the CSV's `timestamp` column, in the run's rendering (`%Y-%m-%d %H:%M` by default, seconds under `-s`/`-ms`, the folded day/time form under `-pr`) — while `generated_at`, a real clock reading, is ISO-8601 with `Z` (D6). Blocks are named for the ltl surface that produced them (`histogram`, `heatmap`, the STATS CSV families) so a figure's model and population are unambiguous. Illustrative values; `#` comments name the ltl source.

```yaml
schema_version: 1

provenance:
  determining:
    version: "0.18.0"                         # $version_number (benchmark-data `version`)
    generated_at: "2026-09-02T10:10:37Z"      # gmtime(); first 'Z' in the tool (D6)
    options:                                  # the two lines the terminal prints, verbatim, as YAML strings (D5)
      command-line: "-n 0 -o -hg -hm duration -bs 240 -st 2026-08-18 05:00:00 -et 2026-08-25 05:00:00 -r "
      environment: "-oe"                      # absent when LTL_CONFIG is unset
    filters: "-et=2026-08-25%2005%3A00%3A00;-st=2026-08-18%2005%3A00%3A00"
                                              # has_active_filters() ? serialize_filters() : '-'
    data_model:                               # -V percentile-algorithm, per surface; tokens raw|bin
      bucket_stats: raw
      message_stats: raw
      histogram: bin
      heatmap: bin
      precision: 5                            # -dmp tier ($data_model_precision_level; -V statistics-demand `data_model_precision`)
    duration_unit_resolved: ms                # source unit ($duration_unit_resolved); values are always ms
    duration_unit_source: default             # 'default' | '-du <unit>'
    profile: workday                          # -pr fold mode; absent when not folded (ltl's word — D8)
    format_pin: tomcat_access_with_duration   # -lf; absent when detection ran
  # no `contextual` block: the working directory is not recorded (D9)

population:
  formats:                                    # one per matched format, @format_legend_order order (D10)
    - name: tomcat_access_with_duration       # format slug (the `format:` / -lf vocabulary)
      event_ledger: true                      # the entry's event-ledger property
  files_bound: 63                             # M of `event_ledger_files: N/M` (D11)
  files_event_ledger: 63                      # N of `event_ledger_files: N/M`
  rule_changes: 0                             # mid-file classifying-entry changes (#453 D32)

  observation:                                # the window the run summary heading states (D7)
    start: "2026-08-18 05:00"                 # the heading's string, verbatim ($min_timestamp_str; "Mon 05:00" under -pr — D8)
    end: "2026-08-25 04:59"                   # the heading's string, verbatim ($max_timestamp_str)
    duration_seconds: 604797.595              # the population duration (R5), raw
    duration: "7 days"                        # the same, through the time formatter (R5)

  sources:
    files: 63                                 # scalar @in_files (reads; a path named twice without -r counts twice)
    files_matched: 63                         # files that contributed an included line (%in_files_matched > 0)
    directories: 3
    directory_list:                           # the files read, as supplied, minus the file part, distinct (D9)
      - env-01/apache
      - env-02/apache
      - env-03/apache

  lines:                                      # the funnel's stages (R9)
    read: 41961884                            # $total_lines_read
    unmatched: 0                              # skipped: no format matched (run total of per-file unmatched_lines)
    included: 41800000                        # $total_lines_included
    excluded:                                 # new counters (D12); a key is present when its cause was active
      time_window: 161884
      profile: 0
      filter: 0                               # -i/-e, pattern files, -if/-ef/-is/-es
      numeric: 0                              # -dmin/-dmax/-bmin/-bmax/-cmin/-cmax
      other: 0                                # vocabulary rejection, unparseable CSV rows
    highlighted: 0                            # $total_lines_highlighted; present when a highlight is active

measurements:                                 # the run summary, in machine form
  lines_included: 41800000
  classified: 41800000                        # successes + failures (the consumer's request total)
  successes: 41763950
  failures: 36050
  unclassified: 0
  success_pct: 99.9137559808612               # in-memory double; present only when pct_eligible (#452 D10)
  failure_pct: 0.0862440191388
  pct_eligible: true
  non_qualifying_lines: 0
  categories:                                 # %category_totals exactly as held: plain and -HL keys side by side (D14)
    2xx: 41472300
    3xx: 291650
    4xx: 30600
    4xx-HL: 118220
    5xx: 5450
  total_time: "3.1 min"                       # the TOTAL TIME row's string: format_time($elapsed_total, 's', 'medium', " ") (D19)
  max_memory_used: "393.8 MB"                 # the MAXIMUM MEMORY USED row's string: format_bytes($max_memory_usage, 'B') (D19)
  histogram:                                  # present per metric only when -hg captured it (F1)
    duration:
      data_model: bin                         # $histogram_capture_mode
      occurrences: 41799210                   # %histogram_stats{duration}{count} — values > 0 only
      min: 1                                  # %histogram_data_min{duration} (observed, not the chart's adjusted extreme)
      max: 61240                              # %histogram_data_max{duration}
      p50: 12                                 # each pN present only when occurrences >= 10/(1-N/100) (D15)
      p75: 48
      p90: 152
      p95: 348
      p99: 1240
      p999: 4820
      p9999: 11350
      p99999: 27100
      highlighted:                            # %histogram_stats_hl{duration}; present when a highlight is active
        occurrences: 118220
          p50: 210
          p95: 1900
    bytes:                                    # every histogrammed metric gets the same block; UDM metrics by name
      data_model: bin
      occurrences: 41799210
      min: 128
      max: 9437184
      p50: 2048
      p95: 65536
      p99: 524288

series:
  bucket_size_seconds: 14400                  # $bucket_size_seconds, unrounded
  bucket_count: 42                            # scalar keys %log_occurrences (= COUNTS log_occurrences_entries)
  omit_empty: false                           # -oe
  rate_unit: m                                # -ru token as held ($rate_unit: s|m|h|d); the CSV column suffix is its rendering
  buckets:
    - timestamp: "2026-08-18 04:00"           # the STATS CSV `timestamp` value, verbatim (floor-aligned bucket; precedes observation.start by design)
      occurrences: 1043122                    # every included line in the bucket
      successes: 1042215
      failures: 907                           # no per-bucket unclassified: ltl holds none, the consumer subtracts (D14)
      success_pct: 99.9130494803              # present only when the bucket is eligible (#452 D2/D17)
      failure_pct: 0.0869505197
      non_qualifying_lines: 0                 # %bucket_outcomes slot 3 — explains an absent percentage
      categories: { 2xx: 1034880, 3xx: 7335, 4xx: 772, 5xx: 135 }
      err_rate: 3.78                          # STATS CSV err-rate_<unit>; unit in series.rate_unit
      msg_rate: 4346.34                       # STATS CSV msg-rate_<unit>
      duration:                               # the bucket store (%log_stats{$bucket}) — the STATS CSV duration family
        data_model: raw                       # choose_data_model('bucket-stats')
        occurrences: 1043122                  # duration_count, retained on the raw path (D15)
        sum: 102440600                        # STATS CSV `duration` (the total; every family's total is `sum`, D21)
        min: 0
        mean: 98.2
        max: 38420
        std_dev: 412.7
        cv: 4.2
        p50: 11                               # the ladder, gated (D15)
        p75: 41
        p90: 128
        p95: 291
        p99: 1015
        p999: 6180
        iqr: 37
        skewness: 2.313                       # shape moments, present when n >= 4 as today
        kurtosis: 4.299
        bimodality_coef: 0.832
      bytes:                                  # STATS CSV bytes family, when active
        occurrences: 1043122
        sum: 3312640000
        min: 128
        mean: 3175.7
        max: 9437184
      count:                                  # STATS CSV count family, when active (any bucket holds a count observation; -oc switches capture off)
        occurrences: 3                        # count_occurrences, count_sum, count_min, count_mean, count_max, the five keys as held
        sum: 12
        min: 1
        mean: 4
        max: 7
      sessions: 812                           # STATS CSV `sessions`, when active; `sessions-HL` beside it under a highlight (D14)
      threadpools: { http-nio-8080-exec: 412, catalina-exec: 9 }    # -tpa/-tpas columns, when active, `-HL` twins beside them (R3 caveat)
      udm:                                    # user-defined metrics, by metric name, when active; `-HL` twins beside them
        job_ms: { occurrences: 14, sum: 8812, min: 12, mean: 629.4, max: 4100 }
        users: { distinct: 44 }
      heatmap:                                # present only when -hm captured it (F1b, D4); the metric a level below, as the histogram block (architect, 2026-09-03)
        duration:                             # $heatmap_metric; a -hm bytes run writes heatmap.bytes, comparable by name
          data_model: bin                     # $heatmap_capture_mode
          occurrences: 1043122                # the partition total percentile() forms; positive values only, as the histogram
          p1: 1                               # the full ladder, computed at finalize under -o, gated
          p5: 2
          p10: 3
          p25: 6
          p50: 12
          p75: 42
          p90: 131
          p95: 301
          p99: 1120
          p999: 6400
          p9999: 21800
    # ... an empty bucket carries occurrences: 0, the three outcome counts, and nothing else ...
```

## Field map (consumer field → ltl)

| Consumer field | Proposed key | ltl source (sub / variable) | Status today |
|---|---|---|---|
| `schema_version` | `schema_version` | new | missing |
| `provenance.determining.ltl_version` | `provenance.determining.version` | `$version_number` (benchmark-data `version`) | exists |
| `…profile` | *(dropped — issue body; F10)* | `-pr` is timeline folding | conflict |
| `…invocation` | `options.command-line` + `options.environment` | the two strings `print_run_options()` prints (F15 records their shape) | exists |
| *(issue body: population-selection options)* | `filters` | `serialize_filters()` (the `ltl-index.csv` `filters` column) | exists |
| `…percentile_model` | `data_model.*` + `precision` | `emit_percentile_algorithm_verbose()` per surface; `$data_model_precision_level` | conflict (scalar vs per-surface; `bin` not `bin_counter`) |
| `…generated_at` | `generated_at` | new (`gmtime()`; the index's `entry_date` convention plus `Z`) | missing |
| `provenance.contextual.cwd` | *(declined — D9: sensitive)* | never captured (F11) | missing |
| `population.format.detected` | `formats[].name` | `@format_legend_order` / `%format_legend` (slug) | exists |
| `…detected_count` | *(not carried — D14: count the `formats` list)* | `scalar @format_legend_order` | derivable |
| `…event_ledger` (`true/false/mixed`) | `files_event_ledger`, `files_bound` (the consumer reads all/none/mixed) | `emit_format_detection_verbose()` `event_ledger_files: N/M` | exists |
| `…classification_configured` | *(not carried — D10)* | `FR_CLS_BOTH` / `FR_CLS_SIG` (in memory only) | derivable |
| `observation.start/end` | `observation.start/end` | the heading's strings `$min_timestamp_str` / `$max_timestamp_str` in `print_summary_table()` (F4 records the other two windows) | exists |
| `…duration_seconds` | `observation.duration_seconds` | `$output_timestamp_max − $output_timestamp_min`, computed nowhere today | derivable |
| `…duration_label` | `observation.duration` | `format_time()` (architect: both forms) | derivable |
| `…boundary_aligned` | *(not carried — D7: the consumer compares start and end)* | — | — |
| `…time_base` | *(dropped — D20: every timestamp is milliseconds; no time-base declaration)* | — | — |
| `sources.file_count` | `sources.files`, `sources.files_matched` | `scalar @in_files`; `%in_files_matched` | exists / derivable |
| `sources.directory_count`, `directories` | `directories`, `directory_list` | the directory part of each path in `@in_files`, as supplied, distinct | derivable |
| `lines.read` | `lines.read` | `$total_lines_read` | exists |
| `lines.included` | `lines.included` | `$total_lines_included` | exists |
| `lines.excluded_by_filter` | `lines.excluded.*` + `lines.unmatched` | new counters; `unmatched_lines` exists in `-V format-detection / classification` | missing |
| `requests.total` | `measurements.classified` | `classification_reconciliation()` `classified` | exists |
| `responsiveness.unit` | *(not carried — D20: values are numeric; durations are ms, `provenance.duration_unit_resolved`)* | constant (F14) | — |
| `responsiveness.percentiles.*`, `maximum` | `measurements.histogram.duration.p*`, `.max` | `%histogram_stats{duration}` under `-hg` (F1) | exists when `-hg` |
| `reliability.success/failure/unclassified` | `successes`, `failures`, `unclassified` | `classification_reconciliation()` | exists |
| `reliability.success_percentage/failure_percentage` | `success_pct`, `failure_pct`, `pct_eligible` | `classification_reconciliation()` (unrounded in memory) | exists |
| `status_families.*` | `categories.*` | `%category_totals` (rendered only; `-HL` twins; absent when unobserved) | exists / conflict (F9) |
| `series.bucket_size_minutes` | `series.bucket_size_seconds` | `$bucket_size_seconds` | conflict (F6) |
| `series.bucket_count` | `series.bucket_count` | `scalar keys %log_occurrences` (`COUNTS log_occurrences_entries`) | exists |
| `series.buckets[].start` | `buckets[].timestamp` | the STATS CSV `timestamp` string (`$bucket_time_str` in `print_bar_graph()`) | exists |
| `…requests` | `buckets[].occurrences` (all included) and `successes + failures` | STATS CSV `occurrences` | conflict |
| `…success/failure` | `buckets[].successes/failures` | `%bucket_outcomes` slots 1/2 (STATS CSV, #452 D9) | exists |
| `…unclassified` | *(not carried per bucket — D14: the consumer subtracts)* | occurrences − successes − failures (#453 D30) | derivable |
| `…success_percentage` | `buckets[].success_pct/failure_pct` + `non_qualifying_lines` | `%log_stats{$bucket}{success_pct}` (#452 D1); slot 3 | derivable / missing |
| `…status_families` | `buckets[].categories` | `%log_occurrences{$bucket}{$category}` | exists |
| `…percentiles`, `maximum` | `buckets[].duration.*` and `buckets[].heatmap.<metric>.*` | `%log_stats{$bucket}` (STATS CSV columns); `finalize_heatmap_unified()` values under `-hm` (F1b) | exists / derivable |
| per-bucket gating input | `buckets[].duration.occurrences`, `buckets[].heatmap.<metric>.occurrences` | `duration_count` under `bin` only (F8); the heatmap partition total | missing on `raw` / derivable |

## Locked decisions (planning walkthrough, 2026-09-02)

Each is stated as what the tool will do. D1 and D2 were set by the issue body's framing and the architect's opening instruction; D3–D18 were locked one by one in the walkthrough. Items the walkthrough left open are in § *Open items*.

- **D1 — The file speaks ltl.** Every key is an existing ltl name where one exists (`p999`, `successes`, `success_pct`, `lines_included`, `classified`, `event_ledger`, `ms`, `bucket_size_seconds`, `histogram`, `heatmap`); the consumer translates. No key is invented where ltl has a word. *Set by the issue body's framing and the architect's 2026-09-02 instruction; recorded here so the record shows it.*
- **D2 — Structure follows the consumer's four blocks.** `provenance` / `population` / `measurements` / `series`, with `provenance` split into `determining` and `contextual`. The architect said the structure "conceptually and structurally seems okay" (2026-09-02).
- **D3 — Population-wide statistics come from the histogram surface and only when it ran (locked, architect, 2026-09-02).** `measurements.histogram.<metric>` is written for each metric `%histogram_stats` holds; no new store, no new per-line work. The block declares the histogram's data model, reads `count` as `occurrences`, and reads the **observed** extremes (`%histogram_data_min/max{$metric}`), not the chart's adjusted ones (F1). The non-positive-value exclusion is documented on the user surface (§ *Documentation*). A run without `-hg` has no population-wide percentiles, by the governing principle. *Architect, 2026-09-02.*
- **D4 — Per-bucket statistics come from the two surfaces that produce them, each under its own name (locked, architect, 2026-09-02).** `buckets[].duration` mirrors the STATS CSV duration family from the bucket store (whenever `-o` demands it — always, for this file); `buckets[].heatmap.<metric>` carries the heatmap metric's percentiles when `-hm` ran (the metric a level below, as the histogram block; architect, 2026-09-03). Under `-o`, `finalize_heatmap_unified()` computes the full ladder `p1 … p99999` per bucket (today it computes the four marker slugs) and retains the values beside the marker indices it already produces (`%heatmap_percentiles{$bucket}` gains the values) — a finalize-time change, one `percentile()` call per slug per bucket. **The rendered heatmap does not change** (architect, 2026-09-02): the additional percentiles exist in the data model for the file only. The histogram needs no such addition: `finalize_histogram_unified()` already computes all twelve slugs plus `count`, `min` and `max` per metric, of which the chart prints four. The two blocks are not merged: they differ in model and sometimes metric, and each is named for its producer.
- **D5 — The two option lines the terminal prints are copied into the file as two strings, untouched (locked, architect, 2026-09-02).** Nested as `options.command-line` and `options.environment`, the names the terminal lines carry. `command-line` is exactly the text `print_run_options()` prints after `command-line options:` (its `$cli_options` string: the arguments minus the file operands, pattern-file indicators appended, as today); `environment` is exactly the text after `environment options:` (`$ltl_config_raw`), absent when `LTL_CONFIG` is unset. Nothing is reordered, merged or added; the strings are built once and printed and written from the same value, and YAML-quoted only as the format requires. The echo's shape (F15) is not this issue's to change; its value-collision defect is filed separately (§ *Record corrections*).
- **D6 — `generated_at` is `gmtime()` in `%Y-%m-%dT%H:%M:%SZ` (locked, architect, 2026-09-02).** The index's `entry_date` convention plus the designator, because it is a real clock reading. Every timestamp taken from the logs is the string the terminal or the STATS CSV prints (D7, D8, D14), never a re-rendering.
- **D7 — The observation window is the one the run summary states, and nothing more (locked, architect, 2026-09-02).** `observation.start` and `observation.end` are the heading's two strings verbatim (`$min_timestamp_str` / `$max_timestamp_str`, rendered from `$output_timestamp_min/max` at the run's precision), `observation.duration_seconds` is the exact difference of the underlying epochs and `observation.duration` its formatted form (D13). No requested-bounds block, no exclusivity flag, no time-of-day flag, no alignment flag: the consumer tests alignment by comparing the two instants it is given, and the requested `-st`/`-et` values are visible in `options.command-line`. F4's account of the three windows stands as background.
- **D8 — Under `-pr` the file works exactly as it does otherwise (locked, architect, 2026-09-02).** The only difference is the timestamps: `observation.start`/`end` and every bucket `timestamp` are the same truncated day/time strings the terminal prints under a fold (`Mon 08:30`, or `08:30` for the single-day modes). `provenance.determining.profile` carries the mode as `-V profile` reports it. Same for `-lf`: `format_pin` is recorded and `formats` lists the pinned slug.
- **D9 — The working directory is never recorded; the directory list is the distinct directory parts of the files read (locked, architect, 2026-09-02).** The consumer's `contextual.cwd` is declined: it makes the file's contents sensitive, and the file is meant to leave the customer's premises. `directory_list` is nothing new: each path in `@in_files`, exactly as it was supplied (relative paths stay relative to where ltl ran, which is what the consumer asked for), with its file part removed, de-duplicated; `directories` counts the list. No working-directory lookup, no relativisation, no new import.
- **D10 — Each matched log format is listed with its event-ledger boolean, and nothing else (locked, architect, 2026-09-02).** `formats[]` carries `name` (the slug) and `event_ledger` per matched format. Classification is not part of the file's format block: the consumer's `classification_configured` is not carried (too complicated for what it buys; the outcome counters and `pct_eligible` already say what was classified).
- **D11 — The event-ledger state is the two counts ltl holds, nothing derived (locked by D14's rule, architect, 2026-09-02).** `files_event_ledger` and `files_bound` are the N and M of `event_ledger_files: N/M`; a file with no bind is in neither. The all/none/mixed reading is the consumer's own. The same-rules rebinding blind spot (#453 D32) is documented, not fixed here.
- **D12 — Excluded lines are counted per cause, at the `next` site that drops them (locked, architect, 2026-09-02).** One integer increment on the drop path only, five causes as in the schema; an included line pays nothing. The time window is its own cause because #454 (filtered-subset notice) excludes it from "line-discarding filters" by architect decision (2026-08-26). The increments are the same cost class as #452 D2's non-qualifying counter; the step 1(b) before/after gate is run on a case that carries active filters (CLAUDE.md § Before writing or changing code). The count is surfaced on three machine surfaces; the run summary table is **not** changed (architect, 2026-09-02, superseding the earlier `LINES EXCLUDED` row: the summary stays exactly as it is, and the file exposes the values the summary already shows, `LINES READ` and `LINES INCLUDED` among them): (1) **`-V`** — the reserved `filter-summary` section is built now, its first implementation (locked, architect, 2026-09-02; tests/HARNESS-DESIGN.md § Reserved section names lists it for #229/#230, both closed without building it, and features/230-filter-logic-coverage.md planned its aggregate totals "built in whichever lands first"). It carries the funnel's stages — `lines_read`, `lines_unmatched`, `lines_excluded` with the per-cause counts, `lines_included` — plus `lines_highlighted` (the sister row): contract in § *`-V filter-summary` section contract*. `benchmark-data` re-emits `lines_excluded` beside `lines_read` / `lines_included` (one source, two surfaces); (2) **fixtures** — the harness carries a scenario per cause so each counter is proved against a known drop count; (3) **the file** — `lines.unmatched`, `lines.excluded.*` and `lines.included` beside `lines.read`.
- **D13 — The population duration is in the file, in both forms (locked, architect, 2026-09-02; the run-summary heading span first recorded here was withdrawn the same day: the summary table stays as it is).** File: `observation.duration_seconds` (raw) and `observation.duration` (the formatted string, e.g. `14.4 hours`). Rendered through `format_time()` with its `long` name set, and two changes to that sub: (1) **precision is a parameter, three significant digits for this caller** — today the sub fixes one decimal (`sprintf("%.1f", $formatted_value)`), so `1.234 hours` reads `1.2 hours`; it gains a precision parameter whose absence keeps today's rendering, using the significant-digit rounding `format_percentage()` implements for its `significant` mode, converged into one helper rather than written twice; trailing zeros and a bare decimal are stripped, the rule every formatter follows (architect, 2026-09-02); (2) **the long form is singular at exactly one and plural otherwise** — `1 day`, `1.5 days`, `7 days` — which the sub already does (`$unit_name =~ s/s$// if $formatted_value == 1 && $format eq 'long';`), and which is asserted rather than assumed. Every existing caller keeps its current rendering.
- **D14 — The file represents ltl's data structures and the CSV format as they are; nothing is folded, derived or re-shaped for the consumer (locked, architect, 2026-09-02).** `categories` carries every category as `%category_totals` holds it — plain and `-HL` keys side by side, absent when unobserved — exactly as the STATS CSV columns do. A consumer that wants family totals runs ltl without a highlight. The same rule removes from the draft the derived run-level event-ledger state (D11), the per-bucket `unclassified` (ltl holds none per bucket; `occurrences`, `successes`, `failures` are there to subtract) and a count of the `formats` list.
- **D15 — The file leaves out a percentile that rests on too few values, on every block, measured against that block's own count (locked, architect, 2026-09-02).** The count is written in each block as `occurrences`, the `<metric>_occurrences` family name the STATS CSV already uses for bytes and count. On the raw bucket path the count exists as the denominator — `calculate_statistics()`: `my $duration_count = scalar @sorted;`, used for the mean, the standard deviation and every percentile index — but the sub returns `min p50 p95 p99 p999 cv` and the demanded groups without it, and `calculate_all_statistics()` then frees the list (`delete $log_analysis{$bucket}{durations};`), so it is computed and discarded; returning it is a one-key addition to that hash. The bin path already keeps it in the sidecar (`duration_count`). Background the decision rests on — the rule ltl publishes (`--explain percentiles`): a percentile is only meaningful with enough values behind it — about 40 for p75, 100 for p90, 200 for p95, 1,000 for p99, 10,000 for p999, 100,000 for p9999, a million for p99999 (`10 / (1 − N/100)`). ltl does not act on the rule anywhere: every surface computes and prints every percentile however few values there are, and the text tells the reader to check the occurrences column. The issue body says the file does act on it: a bucket carries only the percentiles its own values support, so a quiet overnight bucket has a p99 but no p9999, and a consumer renders the missing key as a gap. The file would be the first surface in ltl to withhold a figure on this rule. Three parts to decide: (1) withhold, or write every percentile and leave the judgement to the consumer, which has the count beside it either way; (2) if withholding, the count each block is measured against — histogram: the number of values captured, already stored as `count`; heatmap: the number of values in the bucket's partition, in hand at finalize; bucket store (the STATS CSV duration family): the raw path builds its statistics from the list of durations and discards the list without keeping its length, so a one-scalar-per-bucket `duration_count` has to be kept; (3) whether the population-wide histogram block follows the same rule as the buckets. Recommendation: withhold, on every block, with the block's count written as `occurrences` so a missing key is explained. `min`, `mean`, `max`, `sum` and the counts are never withheld; the STATS CSV keeps emitting every column as it does today. Acting on the rule anywhere obliges the `docs/usage.md` p999 threshold correction (§ *Record corrections*).
- **Extension under #456 (2026-09-03).** The outcome figures at both scales gain
  `conflicts` (the per-line classification-conflict count) and, at run scope,
  `mixed` (lines belonging to a non-uniform message row); `unclassified` becomes a
  counted quantity rather than `included - (successes + failures)`, and the five
  figures partition `lines_included`. The reason an absent percentage is absent
  gains its second and third causes beside `non_qualifying_lines` — a conflict in
  the window, and an unclassified line from a qualifying source — which D16 below
  requires the export to carry. Specification:
  `features/456-per-message-success-failure-indicator.md`. Keys as implemented
  (2026-09-03): `measurements.conflicts`, `measurements.mixed`,
  `measurements.unclassified_qualifying_lines` (always present, integers), and
  per bucket `conflicts` and `unclassified_qualifying_lines` beside
  `non_qualifying_lines`; a non-zero value in any of the three per-bucket
  causes explains an absent `success_pct`/`failure_pct` pair, and at run scope
  a non-zero `mixed` is the fourth cause. Rules: `tests/aggregate-export/rules/keys.tsv`.

- **D16 — Percentages follow #452 D10 at both scales, with the reason for absence carried (locked, architect, 2026-09-02).** Run level: `success_pct`/`failure_pct` present only when `pct_eligible`; `pct_eligible` and `non_qualifying_lines` always present. Per bucket: present only for an eligible bucket, exactly as `%log_stats{$bucket}` holds them; `non_qualifying_lines` always present (slot 3 of `%bucket_outcomes`, exported for the first time).
- **D17 — The file is written with `YAML::PP`, the module #387 already locked (inherited; architect, 2026-09-02).** #58's D37 (which re-scoped user-defined formats into #387, whose body carries it) makes `YAML::PP` a hard `use` dependency — pure Perl, expected PAR-safe on all three build platforms per #58 research finding F7, not yet proved by a build; `YAML::Tiny` (weaker validation) and `YAML::XS` (packing risk) were rejected there. This issue is the first to ship the import if it lands before #387, so it carries the packaging obligations: the `use YAML::PP;` line, a hand run of `build/generate-cpanfile.sh` (F13), `build/install-deps.sh` run from the build path so the module is installed on the system, and the three platform builds proven; staged in that order (architect, 2026-09-02). Numbers are written from the in-memory value; booleans as YAML `true`/`false`.
- **D18 — Names (locked, architect, 2026-09-02).** The file is `<stamp>-LTL-AGGREGATE.yaml` — the STATS/MESSAGES convention with the tag `AGGREGATE` and **without** the argument suffix, kept clean: the options are already in the file. The `-V` section is `aggregate-export` (the issue's own words; a section is named for the user-facing capability, tests/HARNESS-DESIGN.md § Naming rules) and reports what was written (path, byte size, blocks present, the gates that fired) — the observability surface for the file, never a second copy of its figures; the harness is `tests/validate-aggregate-export.sh`. Both reserved in HARNESS-DESIGN.md's list in the same change.
- **D19 — Total time and peak memory are in the file as the terminal prints them (locked, architect, 2026-09-02).** Two informational fields for the analyst reading the file: how long the run that produced it took and how much memory it needed. They are the `TOTAL TIME` and `MAXIMUM MEMORY USED` strings of the run summary, produced by the same calls (`format_time($elapsed_total, 's', 'medium', " ")`, `format_bytes($max_memory_usage, 'B')`), not raw numbers: the exact-values rule (R12) covers the measured figures, and these two describe the run, not the population.
- **D20 — No time-base block and no per-metric unit keys (locked, architect, 2026-09-02).** Every timestamp the tool holds is milliseconds with precision beyond the decimal; the registry's `tz` declaration is not exported. Metric values are numeric YAML fields; the duration unit is stated once in provenance (`duration_unit_resolved`), bytes are bytes, and a user-defined metric's unit is the operator's own configuration.
- **D21 — Every family's total is `sum` (locked, architect, 2026-09-02).** The store names the totals differently (`{duration}`, `{bytes}`, `{count_sum}`); inside each family block the file writes `sum`.
- **D22 — A CSV file's first line is metadata and counts as unmatched (locked, architect, 2026-09-02).** It matches no format; the stash `$potential_csv_header = $_; next;` increments the unmatched counter.

## Implementation plan (2026-09-02 — approved by the architect; drop 1 delivered, see § *Drop 1 record*)

Four drops, each proved by its own assertions before the next starts, each a commit and a push on the one issue branch `503-yaml-aggregate-export`. One PR and one completion gate when every drop is on the branch (architect, 2026-09-02: a drop is never a PR). Code is cited by sub and a snippet to grep for.

### Drop 1 — line accounting (D12, D22, R9)

All sites are in `read_and_process_logs()` unless stated.

- **Unmatched.** One run-level counter, incremented beside `$fdd->{unmatched_lines}++` (the `else` of `if ($is_line_match)`) and at the potential-CSV-header stash (`$potential_csv_header = $_; next;`, D22). `emit_format_detection_verbose()` prints the run-level counter as `unmatched_lines:` instead of re-summing per file.
- **Excluded, per cause,** one increment at each `next` after `$fdd->{matched_lines}++`. Other: the vocabulary gate (`unless (exists $log_level_set{$category_bucket}) { next; }`) and the unparseable CSV timestamp row (`$csv_skipped_timestamp_rows++`). Time window: the four `next` under `if (%filter_range_tod)` and the absolute `next if( $timestamp_epoch < $filter_range_epoch{'start'} || $timestamp_epoch >= $filter_range_epoch{'end'} )`, which is live on every run with open bounds and never fires without a window. Profile: `$profile_dropped_samples` already counts it (`samples_dropped:` on `-V profile`); `excluded_profile` reads the same variable. Filter: `next if( defined( $exclude_filter ) && match_filter($_, $exclude_filter) )`, its include twin, and the four `next` under `if( $outcome_filter_active )`. Numeric: the nine `next` in the duration, bytes and count threshold blocks, including `$numeric_filter_no_metric{duration}++; next;` (a subset of the cause, never added on top). A highlight never drops a line.
- **Key presence.** An `excluded_<cause>` key is written when its cause was in force: `has_active_filters()` (content, outcome, window, numeric) plus `$profile_mode`.
- **`-V filter-summary`.** Registered in `%verbose_section_registry` and `@verbose_section_order`; emitted from `print_verbose_output()`, which runs after `normalize_data_for_output()` sums `$total_lines_highlighted`. `benchmark-data` gains `print "lines_excluded\t...\n"` beside its `lines_read` / `lines_included` prints (one source, two surfaces). The HARNESS-DESIGN reserved-names entry moves to *Implemented*, owner this doc.
- **Harness** `tests/validate-filter-summary.sh`, `-bs 1440 -oe -ni` throughout. Fixtures: time window and content filter on `tests/fixtures/tomcat-access-duration-spread.txt`, outcome filter on `tests/fixtures/http-status-families.txt`, numeric on `tests/fixtures/numeric-highlight-boundary.txt`, unmatched on `tests/fixtures/message-control-characters-unmatched.txt`; three new `.txt` fixtures for the `-pr` fold, an unparseable CSV row and a non-zero vocabulary rejection, documented in `docs/test-logs.md` in the same commit. The summary table is asserted byte-identical to the base commit on the same run.
- **Proof.** The section contract locked (§ below); P1 before/after on a case with active filters; the suite and benchmark ran once at this drop as a checkpoint, the gate proper runs before the one PR.

### Drop 2 — population duration (D13)

- `significant_decimals($value, $digits)` extracted from `format_percentage()`'s significant branch (`my $magnitude = $value >= 100 ? 3 : $value >= 10 ? 2 : $value >= 1 ? 1 : 0;`), the seven percentage callers byte-identical. `format_time()` (`my ($value, $unit, $format, $space) = @_;`) gains a precision parameter; undefined keeps today's `sprintf("%.1f", $formatted_value)`, so all eight callers, including the two `long` callers in `print_bar_graph()` at `$col_w >= 15`, render as today. Trailing zeros and a bare decimal are stripped. Consumer: `observation.duration`.

### Drop 3 — retention for the file (D3, D4, D5, D7, D10, D15, D18)

- **Bucket duration count.** `duration_count => $duration_count` in `calculate_statistics()` (`my $duration_count = scalar @sorted;`) and `duration_count => $n` in `calculate_statistics_bin()`; both reach `%log_stats{$bucket}` through `%$stats,`. No consumer iterates the inner keys, so no surface changes.
- **`counter_entry_total($entry)`.** The sum `percentile()` forms (`my $total_N = $under + $in_total + $over;`) and `finalize_histogram_unified()` repeats (`$n += ($_ // 0) for @{$src->{bins}};`), converged into one sub the heatmap also calls.
- **Heatmap ladder under `-o`.** `finalize_heatmap_unified()`: the twelve slugs through `percentile($src, $q)` before the clamp, retained as `$heatmap_percentiles{$bucket}{values}{pN}` with `{occurrences}` before `delete $heatmap_counters{$bucket}`; `calculate_heatmap_buckets_exact()`: the same slugs by nearest rank over `@sorted_values` with `$count`. The render reads the four marker keys only (`$percentiles->{p50}` … `{p999}`) and is unchanged. Under `-o` the per-bucket lines are deposited in `%verbose_section_buffer{'aggregate-export'}` for the section.
- **Histogram extremes.** Bin: `%histogram_data_min/max` (tracked per line); raw: `%histogram_stats{$metric}{min,max}` (`min => $sorted[0], max => $sorted[-1]` in `calculate_histogram_buckets_exact()`). One reader chooses by `$histogram_capture_mode`.
- **Run stamp.** `build_csv_filename()` computes its `localtime()` stamp once per run; the aggregate name is that stamp plus `-LTL-AGGREGATE.yaml`, without `$safe_args`.
- **Option string.** `build_run_options_string()` returns what `print_run_options()` builds as `$cli_options` (its trailing space included); the printer and the writer both call it. `$ltl_config_raw` is file-scope and read directly.
- **Timestamp rendering.** A bucket-timestamp sub from `print_bar_graph()` (`strftime($output_timestamp_format, gmtime($bucket))`, `.%03d` from `$bucket % 1000` under `-ms`) and an observation-timestamp sub from `print_summary_table()` (`strftime($output_timestamp_format, gmtime($output_timestamp_min))`, fractional `.%03d`); each printer and the writer call theirs, so the file's strings are the CSV's and the heading's by construction. `-osum` is tested once (`return if $omit_summary;`) and stops nothing the writer reads.
- **Family surface.** The duration ladder `qw( min mean max std_dev p1 p5 p10 p25 p50 p75 iqr p90 p95 p99 p999 p9999 p99999 cv skewness kurtosis bimodality_coef )` in `print_bar_graph()` becomes a named list both it and the writer read; family activity is asked of `stats_csv_duration_columns_active()`, `stats_csv_bytes_columns_active()`, the count observation, `$session_data_found`, the thread-pool activity list and `@udm_configs`, as the CSV header asks.
- **Formats.** A run-level slug-to-registry-entry map (for `FR_EVENT_LEDGER`), and the ledger and bound counts lifted out of `emit_format_detection_verbose()` so the emitter and the writer read the same values.

### Drop 4 — the file (D1–D21)

- **Dependency, staged.** `use YAML::PP;` beside `use Text::CSV_PP;`; `build/generate-cpanfile.sh` by hand and both `build/cpanfile` and `build/cpanfile.windows` committed (the stale `requires 'Cwd';` leaves in the same regeneration); `build/install-deps.sh` from `build/` so the module is on the system; then the writer. The three `pp` invocations carry no `-M` flags, so `Module::ScanDeps` over the `use` block is what bundles the module; `YAML::PP` loads schema submodules by dynamic class name, so each platform build is run and inspected, and `-M YAML::PP::` is added to the three scripts if a build lacks them.
- **Writer.** At the tail of `pipeline_render()`, after the second `measure_memory_structures()` (the peak) and before `write_index_file()`. Reads: `classification_reconciliation()`; `%category_totals`; `$elapsed_total` and `$max_memory_usage` through `format_time($elapsed_total, 's', 'medium', " ")` and `format_bytes($max_memory_usage, 'B')`; `%histogram_stats` / `%histogram_stats_hl`; `%log_stats{$bucket}` (the families, `success_pct` / `failure_pct` / `success_pct_count`, `sessions`, thread pools, `udm_*`, with their `-HL` twins); `%bucket_outcomes` slots 1–3; `%log_occurrences{$bucket}` (categories, `err-rate`, `msg-rate`); `$heatmap_percentiles{$bucket}{values}`; the four `*_capture_mode` scalars; `$data_model_precision_level`; `$duration_unit_resolved` / `$duration_unit_source`; `$profile_mode`; `$log_format_pin`; `@in_files` and `%in_files_matched` (`> 0`); `@format_legend_order`, the ledger map and counts, `$format_cls_rule_changes`; `has_active_filters() ? serialize_filters() : '-'`; `$bucket_size_seconds`, `$omit_empty`, `$rate_unit`, `$heatmap_metric`; the line counters; `gmtime()` for `generated_at`.
- **`-V aggregate-export`.** Registered like `filter-summary`; printed directly at the writer's site (the `benchmark-data` way: `print "=== benchmark-data ===\n"`), because `print_verbose_output()` runs before the file exists. Contract locked before the harness (§ Observability).
- **Harness** `tests/validate-aggregate-export.sh`: a rules TSV per key (dotted key path, `int|float|bool|string`, `yes|no|conditional:<producing option>`, a `gate` column for the count threshold), unknown key a hard failure, the cross-surface checks in § Acceptance criteria. `tests/lib/csv-cache.sh` keeps the `.yaml` beside the two CSVs and exports `CSV_CACHE_AGGREGATE`; its `csv_cache_ltl_signature` digest is widened to the writer sub and the new rules file. One `-hg` row joins `tests/statistics-drift/scenarios.tsv`; the heatmap block is compared to the CSV on a scenario that pins both surfaces to the same model.
- **Benchmark.** `SCENARIOS+=("heatmap-histogram-export|-hm -hg -n 0 -o")` after `heatmap-histogram` in `tests/baseline/run-benchmark.sh`; `run_test` removes the files a `-o` scenario writes into the working directory after the run; `tests/baseline/compare-results.sh` gains the `scenarios[++ns]` and `slabel[11]` entries; the header's cross-product comment reads 7 × 11 = 77.
- **Docs.** `print_help()` `-o` row and `docs/usage.md` row and section (its example shaped so `tests/validate-doc-examples.sh` can execute it), `--explain percentiles` and `docs/explain/statistics.md` (the export applies the sample-size rule), `--explain histogram` (non-positive values excluded); HARNESS-DESIGN reserved names (`aggregate-export`, and the two shipped names it lacks); one release-note bullet.
- **Gate.** Full suite; before/after on `single-day-access-log-heatmap-histogram-export` with its `heatmap-histogram`, `no-messages` and `standard` siblings for the two deltas.

## Drop 1 record (branch `503-yaml-aggregate-export`, 2026-09-02)

What was built, where, and what the harness proved. Every site is named by sub; the snippets are what to grep for.

- **Counters.** `$total_lines_unmatched` and four scalars `$excluded_time_window`, `$excluded_filter`, `$excluded_numeric`, `$excluded_other`, declared beside `$total_lines_read`; the fold's drops stay in `$profile_dropped_samples`. Each `next` on a drop path in `read_and_process_logs()` became `if (…) { $excluded_<cause>++; next; }` at the same site: five time-window sites, the include/exclude pair, the four outcome sites, the nine numeric sites, the vocabulary gate and the unparseable-CSV row. An included line executes the same comparisons as before; nothing was added to its path.
- **Unmatched.** `note_unmatched_line($in_file)` holds the per-file detection-record template that the `else` of `if( $is_line_match )` carried inline, and increments both the per-file `unmatched_lines` and the run total. It is called from that `else` and from the CSV header stash (D22). Consequence on an existing surface: a CSV file's per-file `unmatched_lines` on `-V format-detection` now reads 1 for its header line where it read 0; no harness asserted the old value (`tests/validate-csv-input.sh` passes unchanged). `emit_format_detection_verbose()` prints the run total from the counter instead of re-summing the per-file values.
- **`-V filter-summary`.** `emit_filter_summary_verbose()` in the `emit_*_verbose()` chain of `pipeline_render()`, after `emit_bin_counter_mode_verbose()` and before `emit_format_detection_verbose()`, so it runs after `normalize_data_for_output()` has summed `$total_lines_highlighted`. Registered in `%verbose_section_registry` and `@verbose_section_order`. Every key prints on every run (a cause not in force reads 0); the presence rule in the schema belongs to the file, not the section. `lines_excluded_total()` is the one sum; `benchmark-data` prints `lines_excluded` from it between `lines_read` and `lines_included`.
- **Harness** `tests/validate-filter-summary.sh` (87 assertions): one scenario per cause with the drop count known by construction — absolute and time-of-day window (360 of 434 lines on `tomcat-access-duration-spread.txt`), `-pr workday` on the new `profile-weekend-fold.txt` (2 of 5), `-e catalog` (5 of 10) and `-ef` (4 of 10) on `http-status-families.txt`, `-dmin 100 -dmax 200` on `numeric-highlight-boundary.txt` (15 of 19), the new `log-level-outside-vocabulary.txt` (1 of 3, a NOTICE line the format matches and the vocabulary rejects), an unparseable CSV row generated in the harness (header unmatched, one row other, two included), a highlight (3 highlighted, 0 excluded), and the two causes composed (8 of 10). Every scenario asserts `read = unmatched + excluded + included`, `excluded = sum of the five`, equality with `format-detection / classification`'s `unmatched_lines`, and equality with the three `benchmark-data` rows. The summary-table scenario asserts `LINES READ` and `LINES INCLUDED` are present and no `LINES EXCLUDED`/`UNMATCHED` row exists. Sabotage proofs: dropping one outcome increment, adding one to the benchmark row, skipping the CSV-header count, and leaving the fold out of the sum each fail the harness on the assertion written for it.
- **Summary table unchanged**, measured: the run summary on three fixtures under `-dmin 0 -ef -st 2000-01-01` from the base commit (a worktree at `origin/release/0.18.0`) and from the branch differ only in the `TOTAL TIME` and `MAXIMUM MEMORY USED` values.
- **Records.** `tests/HARNESS-DESIGN.md` § Reserved section names: `filter-summary` moved to *Implemented* with this doc as owner, and the shipped `csv-output` and `percentile-algorithm` sections added (two of the § *Record corrections* below). `docs/test-logs.md`: rows for the two new fixtures and for the three existing fixtures the harness uses that it did not yet list.
- **Prototype P1 (D12) — before/after on this machine, single-day access log (761,698 lines), base commit 159e886 against the branch, single runs.** Default case: `parse/read_files` 9.8 s before, +2 ms and −45 ms on two after runs (0.0 % and −0.5 %); total 10 s, +5 ms and −48 ms; peak RSS 144.7 MB → 145.4 MB (+0.5 %). Every-filter-class case (`-st -et -i -e -ef -dmin 0 -pr week`, 760,411 lines included): `parse/read_files` 14.0 s → 13.8 s (−215 ms, −1.5 %); total 14.2 s → 14.0 s; peak RSS 143.6 MB → 144.5 MB (+0.7 %). The only stages above the 5 % mark on the first after run were `detect/registry_build` (9 → 11 ms) and `group_calc` (49 → 52 ms), neither touched by the diff; the second after run reversed both. Verdict: the drop-path counters cost nothing measurable on the included-line path or on a fully filtered run.

## Drops 2–4 record (branch `503-yaml-aggregate-export`, 2026-09-03)

- **Drop 2 (D13).** `significant_decimals($value, $digits)` is the one significant-digits rule; `format_percentage()` calls it where it computed the magnitude inline, and `format_time()` gains a fifth argument, the significant-digit count, whose absence keeps the one-decimal rendering every existing caller gets. Exercised on the sliced subs: 86400 s → `1 day`, 129600 → `1.5 days`, 604800 → `7 days`, 51840 → `14.4 hours`, 3723 → `1.03 hours`, 0.5 s → `500 milliseconds`; every default-path caller unchanged (`validate-duration-display.sh`, `validate-classification-percentages.sh`, `validate-summary-contribution-bar.sh`, `validate-regression.sh`).
- **Drop 3 (D3, D4, D5, D7, D15, D18).** `calculate_statistics()` and `calculate_statistics_bin()` return `duration_count`. `counter_entry_total($entry)` is the one partition sum, called by `percentile()`, `finalize_histogram_unified()` and the heatmap finalize. `@percentile_ladder` (slug, quantile) is the one list of the twelve slugs; the histogram's two inline lists read it. Under `-o`, `finalize_heatmap_unified()` and `calculate_heatmap_buckets_exact()` store `$heatmap_percentiles{$bucket}{values}{pN}` (unclamped, from the same `percentile()` call as the markers) and `{occurrences}` beside the four marker indices; the render reads the marker keys only and the rendered heatmap on `tomcat-access-duration-spread.txt` under `-hm duration -o` is byte-identical before and after. `run_file_stamp()` is the one local-time stamp per run; `build_run_options_string()` is what `print_run_options()` echoes; `format_bucket_timestamp()` and `format_observation_timestamp()` render the CSV timestamp and the heading bounds for the printers and the writer alike; `@duration_family_stats` is the STATS CSV duration family read by the header push, the row push and the writer; `format_ledger_file_counts()` is the N/M behind `event_ledger_files`.
- **Drop 4 (D1–D22).** `use YAML::PP;` (with `YAML::PP::Common` for the order-preserving tie and `JSON::PP` for the booleans) beside the CSV imports; `build/generate-cpanfile.sh` regenerated both cpanfiles (`YAML::PP` and `File::Glob` in, the unused `Cwd` out); `build/install-deps.sh` installed `YAML::PP` 0.41.0 on this machine's Homebrew Perl. `write_aggregate_export()` runs at the tail of `pipeline_render()` after the second `measure_memory_structures()` and before `write_index_file()`, gated on `-o`. It builds the four blocks as order-preserving mappings, numifies every numeric field so the file carries numbers never quoted strings, writes booleans as `true`/`false`, applies D15 per block against that block's `occurrences` (counting what it withholds), and mirrors the STATS CSV row: `@log_levels` order for categories, then the outcome counts and slot 3, then every populated graph column in the row's order (duration family, bytes, count, user-defined metrics, sessions, thread pools) and the heatmap block. `-V aggregate-export` prints at the writer's site. The three platform builds are **not yet run** (the `pp` bundling of `YAML::PP`'s dynamically loaded schema classes is unproven; § *Open items*).
- **Tooling.** `tests/lib/csv-cache.sh` keeps the `.yaml` beside the two CSVs (`CSV_CACHE_AGGREGATE`), treats a cache entry without it as a miss, and hashes subs named `aggregate` and the `tests/aggregate-export/rules/*.tsv` into its signature. `tests/statistics-drift/scenarios.tsv` gains `tomcat-histogram-export` (`-hg duration -hm duration -mdm bin -bdm bin`). `tests/baseline/run-benchmark.sh` gains `heatmap-histogram-export|-hm -hg -n 0 -o` after `heatmap-histogram`, and `run_test()` now runs every case in a scratch directory it removes, so a `-o` scenario never writes into the working directory; `compare-results.sh` carries the eleventh scenario and its label; the header reads 7 × 11 = 77; `tests/baseline/README.md` tier counts trued up (55 / 77; they read 45 / 63 against the 50 / 70 the code already had).
- **Harness** `tests/validate-aggregate-export.sh` with `tests/aggregate-export/validate-aggregate-export.pl` and `tests/aggregate-export/rules/keys.tsv` (key path, type, presence, gate): the checker parses strictly, fails on any key the rules do not name, checks types, required keys, that each percentile is present exactly when its block's count supports it, and the identities (classified = successes + failures, included = classified + unclassified, read = unmatched + excluded + included, bucket_count = buckets written, sum of bucket occurrences = included, sum of category totals = included, per-bucket successes + failures ≤ occurrences = sum of categories); its `compare` mode equates every per-bucket value the file and a STATS CSV both carry. Scenarios: both surfaces under `-n 0` (file count and name, no MESSAGES CSV, the section, cross-surface equalities with `filter-summary`, `format-detection / classification`, `benchmark-data` and `histogram-percentile-ticks`, the heatmap-ladder line, gating on a 444-line bucket, the CSV under `-cp full`, timestamps, the option string, no file name or path text); a ten-line bucket (no p50, no p75, min/mean/max/sum present, twelve withheld); no surfaces; the fold heading (`spanning Wed 10:00 to Sun 10:00`, `4 days`, folded bucket timestamps); the seconds heading; default `-cp` differs from the file on a fractional mean; relative and absolute directory lists with no working directory in the file; the environment option line; the pinned heatmap-versus-bucket-store comparison; and the oracle chain over every `scenarios.tsv` row through the CSV cache. 140 assertions on the full run (22 oracle-chain rows, 113–135 values each equal to the CSV). Sabotage proofs: the gate never withholding (the ten-line bucket carries a p50), the outcome counts swapped (the CSV comparison), the directory list keeping the file part, an unknown key in the file (the structural check), and a heatmap ladder value off by one (the pinned comparison and the section line) each fail the harness on the assertion written for it.

### `-V aggregate-export` section contract (locked as built, 2026-09-03; the draft the planning closed on)

```
=== aggregate-export ===
file: <stamp>-LTL-AGGREGATE.yaml
bytes: N
blocks: <comma list>
buckets_written: N
percentiles_gated: N
=== aggregate-export / heatmap-ladder ===
<bucket timestamp>\tmetric=<heatmap metric>\toccurrences=N\tp1=<value>\t...\tp99999=<value>
=== END aggregate-export / heatmap-ladder ===
=== END aggregate-export ===
```

- `file` — the file's name as written (relative to where ltl ran); `bytes` its size on disk.
- `blocks` — the blocks written, in writing order: `provenance`, `population`, `measurements.histogram` when `-hg` captured a metric, `measurements`, `series.heatmap` when `-hm` ran (the per-bucket `heatmap.<metric>` blocks; there is no series-level heatmap declaration), `series`.
- `buckets_written` — the entries of `series.buckets`, equal to `series.bucket_count`.
- `percentiles_gated` — the count of `pN` keys withheld under D15 across every block.
- `heatmap-ladder` sub-section, present when the bucket heatmap blocks are — one tab-separated line per bucket: the bucket's timestamp string, the heatmap metric, its partition count, and every ladder value as computed (ungated: the section shows what the writer had; the file shows what D15 kept).
- Printed directly at the writer's site after the file is written, so it appears after every section `print_verbose_output()` flushes and after the run summary. Only when `-o` and `-V aggregate-export` are both given.

## Findings from the build (2026-09-03)

- **The dependency's fixed cost (D17).** Loading `YAML::PP` with `YAML::PP::Common` and `JSON::PP` at startup costs every run about 9.5 MB of resident memory (a bare Perl at 3.3 MB, with the three modules 12.8 MB), read on the before/after gate as peak RSS up 5–8 % on the single-day access log whether or not a file is written; timings are unchanged. The modules are declared at the top and loaded statically like every other library (architect, 2026-09-03: libraries are never lazily loaded); the cost is the dependency's, settled when D17 chose it, not a disposition question. The booleans (`event_ledger`, `pct_eligible`, `omit_empty`) are `JSON::PP` boolean objects, the core class the YAML module renders as bare `true`/`false`; a second import, core so nothing is installed, chosen during the build and confirmed by the architect on 2026-09-03 over Perl's built-in booleans (which would bind every build Perl to 5.36 or newer).
- **Number rendering.** The file carries Perl's default rendering of each double (15 significant digits), the same rendering the STATS CSV writes under `-cp full`, so the oracle-to-file chain compares to the last digit. `-V histogram-percentile-ticks` prints 17 significant digits of the same values; the harness compares those numerically at a relative tolerance of 10⁻¹². Whether the file should carry 17 digits is the architect's call; nothing in the record asked for more than the CSV gives.
- **The sample-size rule applied literally.** D15's rule `10/(1−N/100)` gives p1 a floor of 10.1 observations, p5 10.5, p10 11.1, p25 13.3: the low percentiles are cheap under the rule as published, which was written for the upper tail. The file applies it as locked; a symmetric rule for the low tail would be a change to the published text and to D15.
- **The heatmap block nests its metric** (architect, 2026-09-03, on inspecting the full-day file): `buckets[].heatmap.<metric>.{data_model, occurrences, ladder}`, the histogram block's shape, so a run with another heatmap metric is comparable by name; the series-level `heatmap: {metric, data_model}` declaration of the draft is dropped as redundant. The duration-focused test scenarios drop `-hm`: the bucket store already carries every duration statistic, so the drift row `tomcat-histogram-export` and the harness's main scenario run `-hg duration` alone, and the pinned-comparison scenario proves the heatmap block. The benchmark scenario `heatmap-histogram-export` keeps `-hm`, being the cost case for both surfaces.
- **The pinned comparison (open item settled).** At the default tier the heatmap runs 616 bins per decade and the bucket store 53, so their ladders differ by model resolution. At tier 7 (`-dmp 7`) both are 616 and the two ladders agree on `p25`–`p95` on the spread fixture (the harness scenario `heatmap-vs-bucket-store-pinned`); `p1`–`p10` are not compared because the bucket store clamps to the observed extremes and the heatmap ladder is unclamped.
- **A CSV file's per-file `unmatched_lines`** on `-V format-detection` now reads 1 (its header) where it read 0 (drop 1); no harness asserted the old value.
- **The documented usage example is not executed** by `tests/validate-doc-examples.sh`: examples run from the repository root, and this one writes files where it runs; it carries the skip marker and a comment saying why.
- **`format_time()`'s `D` medium form** reads `day` and never pluralises (only the long form does); unchanged here, listed under § *Record corrections*.

## Completion gate (730f85f, 2026-09-03)

Full suite: 34 harnesses, every one asserting and passing (`validate-aggregate-export.sh` 140, `validate-filter-summary.sh` 87, statistics drift 22 scenarios). Before/after on this machine, single-day access log (761,698 lines), base commit 159e886 through a worktree against 730f85f, single runs:

| case | total before → after | peak RSS before → after |
|---|---|---|
| standard | 9.9 s → 9.4 s (−4.5 %) | 143.4 → 152.3 MB (+8.9 MB, +6.2 %) |
| no-messages (`-n 0`) | 7.7 s → 7.4 s (−3.5 %) | 88.8 → 96.0 MB (+7.2 MB, +8.1 %) |
| heatmap-histogram (`-hm -hg`) | 12.3 s → 12.1 s (−1.4 %) | 114.2 → 121.3 MB (+7.1 MB, +6.2 %) |
| heatmap-histogram-export (`-hm -hg -n 0 -o`) | 11.1 s → 10.8 s (−2.7 %) | 93.5 → 102.1 MB (+8.6 MB, +9.2 %) |

The memory rise is the same on every case, file written or not: the static module load recorded under § *Findings from the build* (D17). The export's own share, the export delta less the no-messages delta, is about 3 MB and no measurable time.

## Open items

- The three platform builds with `YAML::PP` bundled (D17): `build/macos-package.sh arm64` on this machine, the Docker Ubuntu and Windows builds where Docker is available; each binary run with `-o` on a fixture and the file parsed. `-M YAML::PP::` is added to the three `pp` invocations only if a build lacks the schema classes.

## Prototype charter

Mandatory triggers under docs/process/workflow.md § Feature lifecycle, step 2: (a) new or changed data model — none (D3/D4 read existing stores; computing the heatmap ladder at finalize and retaining it, and keeping a per-bucket duration count, are field additions to existing entries); (b) per-line hot-path cost — D12's drop-path counters only. Trigger (d), an unknown verification method, does not fire: the assertion method is known (below).

- **P1 — Drop-path counters (D12).** Measure the increments against the pre-change code on a case with every filter class active and on the default case. Exit: figures in the doc; a breach of the 5% gate is stop-and-investigate.
- **Assertion method (no prototype).** A data-driven validator over a rules TSV, the precedent being `tests/csv-output/rules/stats-columns.tsv` and `tests/validate-csv-output.sh`; cross-surface equalities — file values against `-V format-detection / classification` counts, `-V benchmark-data` counts, and `-V histogram-percentile-ticks` percentile values; and the reconciliation identities. The heatmap per-bucket values have no `-V` surface today; the `-V aggregate-export` section (D18) or an additive key on `-V heatmap-palette`'s owner is where the harness reads the expected value — settled in the walkthrough.

## Acceptance criteria (draft — triage in brackets)

- [ ] A `-n 0 -o` run writes exactly one `.yaml` beside the STATS CSV, its name carrying no argument text, and writes no MESSAGES CSV. [assertable]
- [ ] `lines.read`, `lines.unmatched`, each `lines.excluded.<cause>` and `lines.included` in the file equal the same-named `-V filter-summary` values on the same run, and `lines.unmatched` equals `-V format-detection`'s `unmatched_lines`. [assertable — cross-surface]
- [x] One fixture scenario per exclusion cause — time window, `-pr` fold, content filter, outcome filter, numeric threshold, vocabulary rejection — where the dropped count is known from the fixture, and the file's `lines.excluded.<cause>` and the `-V filter-summary` counter both carry it; the summary table is byte-identical before and after on the same run. [assertable — the `-V filter-summary` half delivered in drop 1 (`tests/validate-filter-summary.sh`); the file half joins in drop 4]
- [ ] `measurements.classified == successes + failures`, and `lines.included == classified + unclassified`, read from the same `classification_reconciliation()` call that feeds `-V format-detection / classification`; the file's counts equal that section's on the same run. [assertable — cross-surface]
- [ ] `success_pct` is absent from the run block whenever `-V` reports `pct_eligible: 0`, and present with full double precision otherwise; per bucket, absent exactly on the buckets the timeline renders as counts. [assertable]
- [ ] With `-hg duration`, every percentile `-V histogram-percentile-ticks` lists for the metric (the chart's selected ones) equals the same key in `measurements.histogram.duration`, and `max` equals the largest `duration_max` over the STATS CSV rows of the same run under `-cp full` (the population's maximum is some bucket's maximum); without `-hg`, `measurements.histogram` is absent. [assertable — cross-surface]
- [x] With `-hm duration`, every populated bucket carries the heatmap ladder under `heatmap.duration` down to the depth its `heatmap.duration.occurrences` supports, as the calculated percentile values (never the display projections), and on a scenario that pins the bucket store and the heatmap to the same model the values equal the STATS CSV's `duration_p*` of the same bucket under `-cp full`; without `-hm`, no bucket carries `heatmap`. [assertable — cross-surface; see § Open items on bins-per-decade]
- [ ] A bucket with fewer than 1,000 duration observations carries no `duration.p99`; one with fewer than 40 carries no `duration.p75`; `min`/`mean`/`max` are present on every bucket with at least one observation. [assertable]
- [ ] Every active STATS CSV column family on a run appears as a block of the same bucket in the file, with equal values under `-cp full`, the family set read from the same gates the CSV header reads (`stats_csv_duration_columns_active()`, `stats_csv_bytes_columns_active()`, the count, session, thread-pool and UDM activity tests); the two rate columns are excepted, because the CSV fixes them at one decimal in every `-cp` mode while the file carries the in-memory value. [assertable — cross-surface]
- [ ] On every scenario in `tests/statistics-drift/scenarios.tsv`, each per-bucket value the file carries and the CSV also carries equals the STATS CSV value of the same bucket and column from the same run, to the last digit (those scenarios pin `-cp full`; the rate columns and the per-bucket percentages, which are not CSV columns, are outside this check), and every column the block leaves out is one D15 (a percentile resting on too few values is withheld) gates on that block's own count. The STATS CSV rows are the ones the statistics harness has already validated against its NumPy/SciPy oracle (`tests/validate-statistics.sh` layer 3), so the file is tied to the oracle through the CSV: oracle → STATS CSV → file. Time-bucket rows only; the MESSAGES CSV and the run-level values are outside this chain. [assertable — cross-surface; runs in `tests/validate-aggregate-export.sh` over the CSV cache the statistics harness fills, so the two harnesses read the same run]
- [ ] `population.formats` lists the distinct slugs `-V format-detection`'s `legend:` names, in its order, on the format-switch fixture (2) and on a single-format fixture (1); `files_event_ledger` / `files_bound` equal that section's `event_ledger_files: N/M`. [assertable — cross-surface]
- [ ] `observation.start` and `observation.end` are byte-identical to the two timestamps in the run-summary heading, on a default run, under `-s` and under `-pr week` (where they read as weekday and time); `observation.duration_seconds` equals the difference of the underlying epochs, and `observation.duration` is that value through the time formatter's long form at three significant digits (`1 day`, `1.5 days`, `14.4 hours`); the heading is unchanged. [assertable]
- [ ] Every bucket `timestamp` is byte-identical to the STATS CSV `timestamp` value of the same row, including under `-pr`. [assertable — cross-surface]
- [ ] No value in the file passes through `format_csv_value()`: `duration.p95` in the file equals the STATS CSV's `duration_p95` only under `-cp full`, and differs under the default `-cp` on a fractional fixture. [assertable]
- [ ] `directory_list` equals the distinct directory parts of the paths given, as given, on a relative `-r` invocation and on an absolute one, and `directories` counts it; no file path and no working directory appears anywhere in the file. [assertable]
- [ ] `options.command-line` and `options.environment` in the file are byte-identical to the text after `command-line options:` and `environment options:` on the terminal for the same run, colour stripped. [assertable — cross-surface]
- [ ] The file parses under a strict YAML parser in the harness. [assertable]
- [ ] The step 1(b) before/after gate is run on a case with active filters and reports its figures. [assertable — process]
- [ ] The benchmark matrix in `tests/baseline/run-benchmark.sh` gains the export's expected use as a scenario: `heatmap-histogram-export|-hm -hg -n 0 -o`, the existing `heatmap-histogram` scenario plus the two options the use case adds (`-hm -hg` default to the duration metric, so this is `-hg duration -hm -n 0 -o`). Both surfaces feeding the file are on, so the file is as large as a run can make it, and it runs on every file selection of the tier, so the cost reads across the log populations. Its delta against `heatmap-histogram` on the same file selection carries two changes together, the export and the message store switched off; `no-messages` against `standard` on the same selection isolates the second, so the export's own cost is the difference of the two deltas. The before/after gate for this issue reports this scenario's figures. [assertable — process]
- Unassertable, recorded: that the recorded `options` string reproduces the run (a re-execution round-trip is a methodology-side check; the harness asserts the string is lossless against `@ORIGINAL_ARGV`, not that it re-runs).

## Observability and harness obligations

- New `-V aggregate-export` section (D18), owned by this doc: `file: <path>`, `bytes: N`, `blocks: <comma list of top-level and surface blocks written>`, `buckets_written: N`, `percentiles_gated: N` (pN keys withheld by D15), and the per-bucket heatmap ladder lines deposited at finalize. Printed directly at the writer's site, after the file is written, not through `print_verbose_output()`, which runs before the file exists. Section contract to be locked here before implementation; reserved-names entry in tests/HARNESS-DESIGN.md.
- Additive keys on existing sections (non-breaking): `lines_excluded` on `benchmark-data` (D12). The `COUNTS log_occurrences_entries` row is the one source for `bucket_count` (HARNESS-DESIGN.md § one source, two surfaces).
- New `-V filter-summary` section (D12, locked): the run's line accounting, contract below; same-named harness `tests/validate-filter-summary.sh`; the reserved-names entry in tests/HARNESS-DESIGN.md moves to *Implemented*, owned by this doc. The `inline_patterns:` / `*_files:` sub-sections #229/#230 sketched for it are not built here; they can join later as non-breaking additions.

### `-V filter-summary` section contract (locked, architect, 2026-09-02; built in drop 1)

Run-level, one block per run. Every key deterministic; harnesses assert values. The keys are the funnel's stages in order: read, unmatched, excluded (per cause), included, highlighted.

```
=== filter-summary ===
lines_read: N
lines_unmatched: N
lines_excluded: N
excluded_time_window: N
excluded_profile: N
excluded_filter: N
excluded_numeric: N
excluded_other: N
lines_included: N
lines_highlighted: N
=== END filter-summary ===
```

- `lines_read` / `lines_included` — `$total_lines_read` / `$total_lines_included`, unchanged in meaning (the `LINES READ` / `LINES INCLUDED` rows).
- `lines_unmatched` — the same run total `format-detection / classification` prints as `unmatched_lines`, computed once and read by both.
- `lines_excluded` — the sum of the five `excluded_*` counters (D12 causes: the time window; the `-pr` fold; the content and outcome filters `-i/-e/-ipf/-epf/-if/-ef/-is/-es`; the numeric thresholds `-dmin/-dmax/-bmin/-bmax/-cmin/-cmax`, including a line dropped for carrying no value for the filtered metric; other — category outside `%log_level_set`, unparseable CSV timestamp).
- `lines_highlighted` — `$total_lines_highlighted` (the `HIGHLIGHTED` row); `0` when no highlight is active.
- CSV cache (`tests/lib/csv-cache.sh`): a cache miss already runs `ltl … -o` in a scratch directory and keeps the two CSVs under deterministic names; it keeps the `.yaml` written beside them the same way and exports its path (`CSV_CACHE_AGGREGATE`), so the oracle-to-file chain above reads the file from the same run as the CSVs it is compared with.
- Benchmark tooling: the new `heatmap-histogram-export` scenario joins the scenario list `tests/baseline/compare-results.sh` hard-codes for its table view, and the `run_test` invocation for a scenario carrying `-o` writes its output files to a scratch directory and removes them after the run, never into the working directory. The cross-product comment at the head of `run-benchmark.sh` (7 file selections × 10 scenarios) is updated with the count.
- Harness `tests/validate-aggregate-export.sh`: rules TSV per key (type, required/conditional on the producing option, gate), the reconciliation identities, the cross-surface equalities above, a sabotage proof per new assertion, and the runtime-warning check. Its `ltl` invocations are shaped to the assertion (`-bs 1440 -oe` on the smallest fixture carrying the signal).

## Documentation surfaces

`print_help()` `-o` row and `docs/usage.md` (`-o` now writes a third file; the argument suffix is absent from its name; which options make which blocks exist); a `docs/usage.md` section describing the file by what a reader observes (no internals); `--explain percentiles` and `docs/explain/statistics.md` gain one sentence: the aggregate export applies the sample-size rule, the STATS CSV does not; `--explain histogram` states that population-wide statistics exclude non-positive values and that the export carries them. Release-note bullet: one, for the file.

## Record corrections found by the audit (sweep items — architect to confirm)

- `docs/usage.md` § sort options stated `p999` needs ~1k observations; the explain surface and the arithmetic say ~10,000. Corrected in drop 4 (`p99` ≥ ~1k, `p999` ≥ ~10k).
- `features/453-success-failure-classification-event-ledger.md` § *Per-format declarations* still shows the access family's criteria as `status_code ^[123]\d\d$`; its own D26 amended them to `category_bucket ^(?:1xx|2xx|3xx)$`, which is what the code declares.
- `tests/HARNESS-DESIGN.md` § Reserved section names lacked `csv-output` and `percentile-algorithm`, both shipped — added in drop 1.
- `-ic` is parsed, echoed on `-V runtime-config` and read by nothing (#514, count metric capture and display become explicit, records its retirement); the count family's presence in the STATS CSV, and so in this file, is decided by observation alone (`count_occurrences` on any bucket). The schema comment above says so; nothing here depends on `-ic`.
- `build/cpanfile` carried `requires 'Cwd';` while nothing in `ltl` uses it; gone with the drop 4 regeneration.
- `print_run_options()` drops an option value that is string-equal to a file operand (`-e <path> <path>` echoes without the pattern) — a display defect worth its own bug report.
- `-lf`, `-pr` and `--detection-window` are absent from `_resolve_short_to_long()`'s `@specs`, so `-V runtime-config` can never report them; `%option_overrides` is never written, so its clamp annotation is dead. Both are `-V runtime-config` defects outside this issue's scope.
- `$duration_unit_source` advertises an `auto-detected from <file>` value that no assignment produces; a format-declared non-ms unit converts silently.
- `format_time()`'s `D` unit names its `medium` form `day` while every other row's `medium` is plural (`usec`, `msec`, …); the `long` row D13 uses reads `days`.
- `tests/baseline/README.md` stated the `full` and `all` tiers as 45 and 63 tests against the 50 and 70 the code had; `run-benchmark.sh`'s `quick` description named `twx-unique-errors-standard` while `should_run_test()` matches `single-day-application-log-standard`. Both trued up in drop 4 (55 and 77 with the new scenario).
- `tests/HARNESS-DESIGN.md` § Reserved section names listed `filter-summary` under "reserved by sub-issues, not yet implemented" for #229/#230; moved to *Implemented* with this doc as owner in drop 1.

## Open questions for the consumer side (not ltl decisions)

- Boundary alignment is the consumer's own comparison of `observation.start` and `observation.end` (D7). Because `-et` is exclusive, the last included line falls short of a requested end by however long the log was quiet before it; a consumer applying "start and end share the time of day" must allow for that.
- The consumer's §7 blocker "format is not an access log" has no ltl-side signal: the registry declares no family or kind. The consumer keeps an allow-list of slugs, or asks for a declaration in a later issue.
- The consumer's mandated profile must include `-hg duration` (and `-hm duration` if it wants per-bucket percentiles under the heatmap model): population-wide percentiles exist only when the histogram ran (D3).
- Whether the consumer accepts a file whose run-level percentages are absent while per-bucket ones are present (F7), given its own rule refuses a percentage that disagrees with the counts but says nothing about an absent one.
- Whether the consumer's `included = success + failure + unclassified` check is retained knowing it cannot fail (F2), and whether `unmatched` and `non_qualifying_lines` replace it as the contamination signals.
