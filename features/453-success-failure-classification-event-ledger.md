# Feature: Per-variant success/failure classification and the event-ledger property (#453)

## Status

- Issue: #453 (per-variant success/failure line classification and an event-ledger property in the format registry schema, retiring `$is_access_log`)
- Branch: `453-success-failure-classification-event-ledger` off `release/0.18.0`
- Phase: planning (requirements and specification closed 2026-08-28 with R1–R10, D1–D13; before-baseline `tests/baseline/results/0.18.0-453-before.tsv` committed)
- Umbrella: #23 / `features/log-format-registry.md` (system of record for the registry; § *1. Format Definition Properties* lists the per-format properties this issue extends)
- Consumers: #452 (reliability column and analysis-overview surface), #455 (success/failure filter and highlight criteria), #456 (per-message success/failure indicator), #193 (timeout detection on error responses)

## Overview

Two properties are added to every format registry entry — every variant, since an entry without a `variant_group` is the sole member and default of its own group:

1. **Classification** — how a line of this format is recognised as a *success* or a *failure*. A line matching neither is *unclassified*: a meaningful third outcome, never a default to one side.
2. **Event ledger** — a boolean marking the format as having maximal *coverage* of the operations it describes: every operation of that kind produces a line, so the absence of a line means the operation did not happen. It governs the *defaults* of consumers whose figures are only safe at face value under maximal coverage; it never governs their availability.

The variable `$is_access_log` is retired in the same work. It began as a metrics-detection gate for access logs; over time the understanding of what it actually gated developed into "a particular type of log" — the type now named *event ledger* — while the variable itself accumulated the unrelated meaning "metrics were observed on this line". The two meanings are separated into properties that name them.

The success and failure counts are brought into the existing data model — the per-bucket and per-message aggregations — not kept beside it.

## What the code does today (verified on the tree, 2026-08-28)

- **The error rate is not a per-line classification.** `errRate` is computed at chart-preparation time by summing bucket occurrences whose *category-bucket name* matches `FATAL|ERROR|5xx|4xx` (in the bar-graph preparation, `$error_occurrences += $occurrences if $category_bucket =~ /^(?:FATAL|ERROR|5xx|4xx)$/i`). Access logs reach that regex because a registry transform folds the HTTP status code into a family name (`1xx`..`5xx`) used as the category; diagnostics logs reach it through their log level. The "two hard-coded expressions" of the issue are therefore one bucket-name regex plus the status→family transform.
- **`$is_access_log` never means event ledger in practice.** Its 28 sites reduce to one meaning — *metrics observed on this line, or the format is always statistics-eligible* — and one external contract:
  - set statically by `stats_eligible => 1` on the spec (compiled into the generated block as `$is_access_log = 1`): `mt12` tomcat_codebeamer, `mt4` tomcat_access_common, `mt9` jboss_access, `mt3` tomcat_access_with_duration, `mt3us` httpd_access_with_duration, `mt6` java_gc_g1, `csv`;
  - set per line by message-metric probes declaring `marks_metrics_observed => 1` (`mt1std`, `mt10`, `mt10ir`) when ` bytes=`/` durationMs=` appear;
  - set per line, on any format, by the count probe (`$message =~ / count\s*=\s*(\d+)/`) and by UDM capture (`$is_access_log = 1 if %udm_values`);
  - set on both CSV paths (`$is_access_log = 1` beside `$match_type = 13`);
  - gates three statistics-capture paths: the consolidation stats-source build (`if ($is_access_log) { $stats_source->{total_bytes} ...`), per-message statistics (`## CAPTURE MESSAGE BASED STATISTICS DATA`), and per-bucket statistics (`## CAPTURE TIME-WINDOWS BASED STATISTICS DATA`);
  - reported per file as `is_access_log: yes|no` in `-V format-detection` (`emit_format_detection_verbose()`), asserted by `tests/validate-format-detection.sh` — its `contract` line already documents the real meaning: "metric presence is signaled via is_access_log=yes".
  - The `%format_detection` per-file schema comment and `FR_STATS` ("statistics-eligible: sets is_access_log statically") carry the same meaning.

## Requirements

- **R1 — Per-entry classification.** Each registry entry declares how its lines are recognised as successes and as failures. The declaration is data on the entry, alongside pattern, field map, time contract and duration unit — never logic in the processing code.
- **R2 — Field-targeted criteria.** A criterion names a record field and a pattern to match against that field's extracted value (e.g. `status_code`, `category_bucket`, `message`); the raw line is addressable as a field for formats that need it. Matching the raw line is not the primary mechanism: for access logs the signal is the extracted status code, and a whole-line pattern would be fragile across the access-log variants (#444).
- **R3 — Multiple criteria, any-of across / all-of within.** An outcome holds a list of criteria; a line has that outcome if *any* criterion matches. One criterion may name several field conditions, *all* of which must hold. Example: `failure: [ {category_bucket: ^(ERROR|FATAL|CRITICAL)$}, {category_bucket: ^WARN$, message: timed out} ]` — any ERROR/FATAL/CRITICAL line, or a WARN whose message says "timed out".
- **R4 — Cascading defaults.** A global default classification exists (today's behaviour, generalised: level-based failure for diagnostics logs, status-family-based for status-bearing formats). A format entry that declares an outcome *replaces* the default's list for that outcome; an entry that declares nothing inherits the default. A format may explicitly decline to classify, in which case nothing downstream can be computed and the consumer says so (#452 notice 3).
- **R5 — Three counters, carried together.** Successes, failures, and *lines included* — the existing counter, unchanged in meaning: matched lines that survived filtering. Lines a filter discarded never reach classification. A line no format recognised is unmatched and is thrown away; it has no timestamp, so it has no bucket and is never included — it stays in `unmatched_lines` on `-V format-detection`, which the `classification` sub-section also carries as a run total so the analyst sees it beside the shortfall. (The issue's original wording had unmatched lines counting as included; re-asserted by the architect on 2026-08-28 as a misunderstanding — an unmatched line does nothing else.) The classified total (successes + failures) and the shortfall against lines included, with its percentage, are available to consumers without being re-derived.
- **R6 — Counts join the existing aggregations.** Successes and failures are accumulated per time bucket and per message key in the existing data model, so per-bucket (#452 column) and per-message (#456) figures read the same stores as every other statistic.
- **R7 — Existing error rate unchanged for supported formats.** `errRate` is produced from the failure classification rather than the bucket-name regex, with no change to what a user observes on any format shipped today.
- **R8 — Event-ledger property, per entry.** Each entry declares whether it is an event ledger. The elected variant's flag becomes the file's property at variant election (per file), is reported on `-V format-detection`, and is what consumers read to decide their defaults.
- **R9 — `$is_access_log` retired.** Each meaning it carried is served by a property that names it; no change to what a user observes for supported formats. The "metrics observed" meaning is renamed, not redesigned.
- **R10 — User-facing framing is coverage.** Wherever the event-ledger property appears in user-facing text it carries a one-line definition — a format with maximum coverage of the operations executed: every operation of the kind the format describes produces a line — citing the Google SRE Workbook implementing-SLOs chapter (https://sre.google/workbook/implementing-slos/) as the reference for why a reliability figure is only meaningful over such a source. It is a coined term (issue § *Terminology*); it needs the definition every time.

## Locked decisions

- **D1 — Criteria target extracted fields, not the raw line** (2026-08-28). Rationale in R2. The raw line remains addressable as a field.
- **D2 — Any-of across criteria, all-of within a criterion** (2026-08-28). Both readings of "several rules" are needed — widening (level *or* message text) and narrowing (level *and* message text) — and the list-of-conjunctions structure carries both without a combinator vocabulary.
- **D3 — Global default classification, overridden per entry by replacement** (2026-08-28). Preserves today's behaviour for every format that declares nothing, and lets a format become more targeted without inheriting rules that do not apply to it.
- **D4 — A line matching both outcomes is a failure** (2026-08-28, carried as the assumption stated to the architect; not objected). The conservative reading for a reliability figure.
- **D5 — The `$is_access_log` retirement rides this branch** (2026-08-28). It is a rename to `metrics_observed` (the meaning the variable actually carries) plus the introduction of the event-ledger property as a first-class, per-file-bound property; not a large cleanup.
- **D6 — Event ledger is first-class and bound per file** (2026-08-28). The property lives on the entry, is fixed for a file when its variant is elected (and re-bound on a mid-file flip like every other variant-carried property), and replaces `$is_access_log` at every site where *the type of log* was the intended meaning.
- **D7 — Global default classification declares failure only** (2026-08-28). Success cannot be asserted from a diagnostics log: an `INFO` line is not evidence that an operation succeeded. Every non-failure diagnostics line is unclassified, so the reliability figure is unavailable by default on those logs — the coverage argument applied to the default.
- **D8 — `mt12` tomcat_codebeamer is an event ledger classified as the access family** (2026-08-28). One line per request, status code captured (`status_code` field, category folded to the `Nxx` family).
- **D9 — `mt6` java_gc_g1 is an event ledger whose classification is deferred to #483** (2026-08-28). Every pause is logged, so coverage is maximal; what makes a pause a success or a failure is a research question, filed as #483 (success/failure classification criteria for the Java G1 GC log format; blocked by this issue). Until it lands the entry declines to classify, exercising #452's "no classification configured" notice on a real format.

- **D10 — Every `$is_access_log` site maps to `metrics_observed`; no existing site becomes event-ledger-gated** (2026-08-28). The three statistics-capture gates stay on "metrics observed". *Metrics observed is not the same thing as event ledger* — a format may carry duration metrics with partial coverage, or maximal coverage with no metrics — and the event-ledger flag's first readers are this issue's reconciliation shortfall (a defect only on an event ledger) and #452's column default and notices. The `-V format-detection` key `is_access_log:` → `metrics_observed:` rename follows `tests/HARNESS-DESIGN.md` § stability contract (harness, umbrella section-contract, this doc, same commit). The observable-value rename mapping in `tests/baseline/compare-results.sh` (`TIMING_TMAP_AWK`) pairs benchmark TIMING rows across releases; `is_access_log` is not a benchmark row, so that table is not touched by this rename — if any renamed value does surface in a benchmark TSV, an old → new entry is added there in the same commit.

- **D11 — The R5 counters are emitted as a `format-detection / classification` sub-section** (2026-08-28). The counters are a property of classification, and the owning section and its harness (`tests/validate-format-detection.sh`) already exist. #452 reads the same accumulators onto its analysis-overview surface when it lands; this issue does not create that surface.

- **D12 — Highlighted lines are classified like every other line; the `errRate` exclusion of `-HL` buckets is a bug and is fixed here** (2026-08-28). Today a line matching a highlight filter has its category bucket renamed (`ERROR` → `ERROR-HL`, `5xx` → `5xx-HL`) and the anchored `errRate` regex never counts it, so the error rate drops by exactly the highlighted errors on any run with a highlight filter. Classification is independent of highlighting; R7's "no change to what a user observes" carries this one stated exception, and the release note records it as a bug fix.

- **D13 — One classification surface; rendering reads counters, it never classifies** (2026-08-28). Success and failure are decided once, per line, at classification time, and accumulated into the per-bucket and per-message stores (R6). The render-time `errRate` computation (`$error_occurrences += $occurrences if $category_bucket =~ /^(?:FATAL|ERROR|5xx|4xx)$/i` in the bar-graph preparation) is removed and the rate reads the bucket's failure counter. No second site — render, CSV, `-V`, a consumer issue — may re-derive an outcome from bucket names, levels or status codes.

## `$is_access_log` site inventory and replacement (confirmed 2026-08-28, D10)

| Site (function / snippet) | Meaning today | Proposed property |
|---|---|---|
| spec key `stats_eligible`, `FR_STATS`, generated `$is_access_log = 1` | format always yields metrics | `stats_eligible` stays as the spec key; generated block sets `$metrics_observed = 1` |
| probe `marks_metrics_observed` (mt1std/mt10/mt10ir) | metrics seen on this line | `$metrics_observed = 1` (name already right) |
| count probe, UDM capture (`$is_access_log = 1 if %udm_values`) | metrics seen on this line | `$metrics_observed = 1` |
| CSV paths (`$is_access_log = 1` beside `$match_type = 13`) | CSV rows are data rows | `$metrics_observed = 1` (CSV spec already `stats_eligible => 1`; the explicit set is then redundant and dropped) |
| consolidation stats-source build `if ($is_access_log)` | metrics present to merge | `$metrics_observed` |
| `## CAPTURE MESSAGE BASED STATISTICS DATA` `if( $is_access_log )` | metrics present to record | `$metrics_observed` |
| `## CAPTURE TIME-WINDOWS BASED STATISTICS DATA` `if( $is_access_log )` | metrics present to record | `$metrics_observed` |
| `%format_detection{...}{is_access_log}` and `-V` key `is_access_log:` | per file: any line observed metrics | two keys: `metrics_observed:` (same semantics as today's key) and `event_ledger:` (from the elected variant) — **a breaking `-V` rename** under `tests/HARNESS-DESIGN.md`; harness, `features/log-format-registry.md` § format-detection section-contract, and this doc updated in the same commit |
| `@format_record_fields` slot `is_access_log` | record field name | renamed `metrics_observed` (drop-in; the generated defaults treat it as a zero-default numeric) |

No site today is gated on "is this an event ledger". The event-ledger property gets its first consumers in #452 (column default, notices 1 and 2) and in this issue's own reconciliation counter (R5 shortfall is reported as a defect only on an event ledger — #452 notice 2).

## Per-format declarations (decided 2026-08-28; D7–D9)

| Entry | event_ledger | classification |
|---|---|---|
| `mt4` tomcat_access_common, `mt3` tomcat_access_with_duration, `mt3us` httpd_access_with_duration, `mt9` jboss_access, `mt12` tomcat_codebeamer | yes | success `status_code ^[123]\d\d$`; failure `status_code ^[45]\d\d$` |
| `mt6` java_gc_g1 | yes | declines to classify until #483 (GC pause success/failure criteria) lands |
| `csv` | no (user data; unknown coverage) | inherits the global default; `category_bucket` is `DATA`, so effectively unclassified unless #387 lets a user declare |
| all diagnostics formats (`mt1*`, `mt2`, `mt5`, `mt7`, `mt8`, `mt10*`, `mt11`, `mt16`, `mt17`) | no | inherit the global default: failure `category_bucket ^(ERROR|FATAL|CRITICAL)$`, no success criterion (D7) |

## `-V` section-contract changes (stub — completed at implementation)

- `format-detection` per-file block: `is_access_log:` → `metrics_observed:` (byte-identical semantics) and new `event_ledger: yes|no`.
- New sub-section `format-detection / classification` (D11), run-level: `lines_included`, `successes`, `failures`, `classified`, `unclassified`, `unclassified_pct`. Exact line shapes and counter semantics (what increments, when, edge cases) are locked at implementation and recorded here and in the umbrella's section-contract.

## Performance obligation

**Before/after measurement is part of the development process for this branch, not only the completion gate** (architect, 2026-08-28). The change touches the hot path, so a named set of benchmark cases is captured on the branch *before* any production code is written, labelled by the branch's version stamp (`0.18.0-453-before`), and **committed** under `tests/baseline/results/` so every subsequent step can be compared against it as a sanity check (`tests/baseline/compare-results.sh summary tests/baseline/results/0.18.0-453-before.tsv <step>.tsv`). The case set (decided 2026-08-28): `single-day-access-log-standard` (event ledger, status classification, gate case), `single-day-application-log-standard` (diagnostics default D7, `mt1` metric-bearing vs plain lines), `multi-day-custom-logs-standard` (UDM / count-probe path), `single-day-access-log-top25-consolidate` (consolidation stats-source gate). Intermediate step captures are labelled by step and are not deliverables unless the doc says otherwise.

Release baselines (`v*.tsv`) are captured on different hardware and are not comparable to captures made in the development environment; every comparison on this branch is against `0.18.0-453-before.tsv`.

Classification is a new per-line hot-path cost (one or more field regex matches per included line, on every format). Per CLAUDE.md § Development Phases 2(b) the prototype is **mandatory**, not a judgment call. Decisions that depend on it: the compiled shape of the criteria (per-entry closure compiled at registry build time, in the same manner as the D33 message-metric probes, vs interpreted list walk), and whether the global default is compiled into each entry's closure or evaluated as a fallback. The prototype extracts the production scan structure per `prototype/459-order-independence/extract-subs.sh` and measures on metric-bearing and metric-less lines.

## Planning

Walked piece by piece with the architect; each piece locks its decisions here before the next opens.

1. **Schema shape on a spec entry** — D14 (locked).
2. **Global default: where it lives, how an entry overrides it, how an entry declines** — D15 (locked).
3. **Hot-path evaluation** — D16 (locked).
4. **Data model** — D17 (locked).
5. **`$is_access_log` → `metrics_observed` rename and `event_ledger` per-file binding** — D18, D19 (locked).
6. **`-V format-detection / classification` section-contract** — line shapes and counter semantics — open.
7. **Prototype charter** — candidates, baseline arm, scale, exit criteria — open.
8. **Stages and merge gate** — order of landing, parity fixtures — open.

### 1. Schema shape — D14

- **D14 — A spec entry declares `classification` and `event_ledger` as plain data** (2026-08-28):

  ```perl
  classification => {
      success => [ { status_code => '^[123]\d\d$' } ],
      failure => [ { status_code => '^[45]\d\d$' } ],
  },
  event_ledger => 1,
  ```

  Each criterion is a hash of *field ⇒ pattern* — all conditions must hold (R3 all-of); each outcome is a list of criteria — any one suffices (R3 any-of). Field names are the record field names of `@format_record_fields` (`status_code`, `category_bucket`, `message`, …) plus `line` for the raw line (D1). `event_ledger` defaults to 0 when absent. How an entry inherits or declines is piece 2.

### 2. Global default — D15

- **D15 — One default structure, resolved once at registry build; declining is explicit and accepts two spellings** (2026-08-28).
  - `%classification_default` in GLOBALS has the same shape as an entry's `classification` value and is failure-only (D7): `failure => [ { category_bucket => '^(?:ERROR|FATAL|CRITICAL)$' } ]`, no `success` key.
  - `build_format_registry()` resolves each entry per outcome: an outcome the entry names replaces the default's list for that outcome (D3); an outcome it omits is inherited. Every compiled entry carries a fully resolved classification; the scan path never consults the default.
  - An **absent** `classification` key inherits the whole default. **Declining** is explicit and either spelling is accepted: `classification => 'none'` or `classification => {}` — both resolve to "classifies nothing", inherit nothing, and produce no classification code in the entry's generated block (the `mt6` case, D9), so a declining format pays nothing per line.
  - Hot-path impact of the declaration vocabulary is nil: sentinel, empty hash and absent key are read once at build time and never again; per-line cost is set solely by the resolved shape (piece 3).
  - User documentation (#387 user-defined formats, `docs/`) states the three forms — absent inherits, `'none'`/`{}` declines, a partial declaration replaces per outcome — in those words.

### 3. Hot-path evaluation — D16

Per-line order in `read_and_process_logs()` today: generated scan block (extraction → in-block metric probes and their masks → transforms → timestamp) → count-metric probe (masks `count=`) → thread pool → UDM capture (masks values) → filtering conditions → highlight (appends `-HL` to the category) → statistics capture. Filtering runs after the block, so an outcome cannot be *counted* inside it (R5); the bucket and message key exist only at statistics capture (R6).

- **D16 — Decide in the block, count after the filter** (2026-08-28).
  1. `build_format_registry()` compiles each entry's resolved classification into generated source — one generator, the D33 message-probe precedent — inlined into the entry's scan block after the transforms. It sets one per-line lexical, `$line_outcome`: `2` failure, `1` success, `0` unclassified. Failure is evaluated first, so D4 (both match → failure) costs nothing. A declining entry emits nothing; the lexical keeps its per-line default `0`.
  2. Counters — per bucket, per message key, and the run-level R5 set — increment at the existing statistics-capture point, after filtering. The `-HL` suffix is appended after the block, so highlighted lines classify normally (D12) with no special case.
  3. The CSV path never runs a scan block: the same generated source is compiled standalone into an `FR_CLASSIFY` closure the CSV branch calls — one generator, two call shapes.
  4. A `message` criterion sees the message as it stands at the end of the block: after the format's own metric masks (`bytes=?`), before the count/UDM masks. Documented in one sentence wherever criteria are described.
  - **Efficiency is a hard requirement, not a preference** (architect, 2026-08-28): everything here is per line on every format, so the prototype (piece 7) compares mechanisms, not just confirms one — at minimum: a literal-alternation pattern (`^(?:ERROR|FATAL|CRITICAL)$`, paid by every diagnostics line under the default) emitted as a hash-set lookup vs a regex; `status_code` family tests as generated integer compares vs a regex; `index()` pre-gates for literal message criteria; per-criterion inline regex vs precompiled `qr//` in a closure.

### 4. Data model — D17

- **D17 — Dedicated per-bucket outcome store; per-message keys on the existing entry; run totals beside `lines_included`** (2026-08-28).
  - **Per bucket:** `%bucket_outcomes{$bucket}{successes|failures}`, incremented at the include point (beside `$log_occurrences{$bucket}{$category_bucket}{occurrences}++; $total_lines_included++` — after filtering, outside the metrics gate). Deliberately *not* in `%log_analysis{$bucket}`: that hash's key set is the statistics population (`$stats_population_buckets = scalar keys %log_analysis`; the per-bucket statistics loop iterates it), and adding non-metric buckets to it would change the reported population and the statistics pass.
  - **Per message:** `successes` / `failures` keys on the `%log_messages{$category}{$log_key}` entry, incremented on both the metrics path and the plain path (every site where its `occurrences++` runs), carried in the consolidation stats source and summed by `merge_consolidation_stats()`.
  - **Run level:** `$total_successes`, `$total_failures` beside `$total_lines_included`; `classified`, `unclassified`, `unclassified_pct` derived at emission, never stored.
  - **`errRate`:** `$bucket_outcomes{$bucket}{failures} / $bucket_size_seconds * $rate_multiplier{$rate_unit}`; the category-name regex is removed (D13). For every shipped format the failure set equals today's `FATAL|ERROR|5xx|4xx` set (plus `CRITICAL`, which no shipped format emits), so the rate is byte-identical except for D12's highlighted-error fix.

### 5. Rename and per-file binding — D18, D19

- **D18 — Mechanical rename, one commit** (2026-08-28). `$is_access_log` → `$metrics_observed` at every inventory site; the record-field slot, `%format_detection{...}{is_access_log}` and the `-V format-detection` per-file key become `metrics_observed:` with byte-identical semantics; the `FR_STATS` and `%format_detection` schema comments follow. `tests/validate-format-detection.sh` has its assertion rewritten to the new key in the same commit, and its `asserts` text (which cites `ltl:4799-4802` line numbers) corrected to the function name. The umbrella `features/log-format-registry.md` format-detection section-contract, which lists `is_access_log:` among the byte-preserved keys, is amended to record the rename.

- **D19 — A mid-file flip follows the new occupant for `event_ledger` and for classification, and a criteria change is surfaced to the user and on the observability surface** (2026-08-28).
  - New slot `FR_EVENT_LEDGER`. `$fdd->{event_ledger}` is set from the bound entry at first bind and re-set when a flip changes the group's occupant for that file — never on the per-line path. Emitted as `event_ledger: yes|no` after `metrics_observed:`.
  - After a flip, lines are classified under the new occupant's resolved criteria (they are compiled into its scan block, so this is automatic). Lines classified *before* the flip are not revisited — the read is streaming — so the counters may carry outcomes decided under two rule sets.
  - Each compiled entry carries a **criteria signature** (a canonical string of its resolved classification, computed once at registry build) so the flip-time check is one string compare between the old and new occupant, on the rare flip path only. When the signatures differ, the tool:
    1. prints a user-facing note (a behavioural notice, never gated behind `--disable-progress`; on the #412 notices surface once it exists, on stderr in the `Note:` form of `format_variant_ambiguity_note()` until then): a classification rule change occurred mid-file at line N of `<file>` because the detected log format was adapted from `<old format>` to `<new format>`; lines before that point were classified under the previous rules;
    2. records it for the `classification` sub-section (piece 6): a run count `rule_changes: N` and one line per change — file, line number, old entry → new entry.
  - Run-level, the sub-section also carries `event_ledger_files: N/M`. What a consumer does when a run mixes ledger and non-ledger files is that consumer's decision (#452's column default) and is handed forward, not settled here.

## Open items

1. Expressibility in #387 (user-defined YAML formats): confirm the field+pattern, list-of-conjunctions shape maps onto what #387 will accept — checked at #387 planning, recorded here.

## Merge gate

Standard completion gate (CLAUDE.md per-feature step 1): full `tests/validate-*.sh` suite and the `single-day-access-log-standard` benchmark against `tests/baseline/results/v0.17.0.tsv` (or the latest released baseline), on the commit being merged, with `$version_number` restored to `0.18.0`. Parity fixtures for the retirement must include both metric-bearing and plain lines on `mt1std`, and an access-log fixture whose `errRate` is compared byte-for-byte before and after R7.
