# Success and failure percentage columns, and the analysis overview surface (#452)

**Issue:** #452 (FEATURE: Success and failure percentage columns for access logs and analysis overview surface)
**Branch:** `452-success-failure-percentage-columns` off `release/0.18.0`
**Status:** in implementation (scheduled by the architect, 2026-08-31). Trigger-(d)
prototype complete — AC3/AC5/AC6 assertable via the timeline-cell selector
(`prototype/452-timeline-cell-selector/FINDINGS.md`). Tuning items (D6 exact budget,
R5 final hide priorities) are settled on rendered output during development and
locked back here.

## Scope

Three deliverables, consuming #453 (per-variant success/failure classification and the
event-ledger registry property, delivered into `release/0.18.0`, PR #488):

1. **Two timeline columns** — success percentage (dark green) and failure percentage
   (dark red) — expressing per time bucket the share of *classified* lines that
   succeeded and failed. Denominator: `successes ÷ (successes + failures)`, the
   classified population; unclassified lines are outside the ratio (issue comment
   2026-08-31, matching the shipped run-summary rows).
2. **An analysis overview** reporting run-total successes, failures, total requests
   (= successes + failures), and the overall success and failure percentages —
   computed from the totalised counts, never an average of per-bucket percentages.
3. **Three mutually exclusive notices** qualifying the figure: partial coverage
   (non-ledger, explicitly enabled), unclassified lines detected (event-ledger
   formats), no classification configured.

Out of scope, inherited: the filtered-subset caution is #454 (notice that statistics
describe a filtered subset); the general notices *surface* is #412; access-log variant
detection quality is #444.

## What already ships — the substrate audit

The issue was written before #453 landed; much of what it specifies already exists.
Planning starts from the shipped code, not the issue's assumptions. This table records
what the code does today — design responses to it are in the open decisions.

| Needed by #452 | Already shipped (by #453 unless noted) |
|---|---|
| Per-bucket success/failure counts | `%bucket_outcomes` — `$bucket_outcomes{$bucket}[1]` successes, `[2]` failures, accumulated at the include point in `read_and_process_logs()`. Sparse: a bucket with no classified line has no key (#453 D30 — slot 0 never written). Already read at normalisation for the legend's error rate: `my $error_occurrences = $bucket_outcomes{$bucket} ? ($bucket_outcomes{$bucket}[2] // 0) : 0;` in `normalize_data_for_output()`, which stores the derived value for the render loop |
| Run totals | `$total_successes`, `$total_failures`, `$total_lines_included`, same include point |
| The classified denominator | Computed in two places today: `print_summary_table()` (`my $classified = $total_successes + $total_failures;`) and, inline, in `emit_format_detection_verbose()`. D13 extracts one shared reconciliation sub that every surface calls |
| RFC response-code families | Met by the shipped registry declarations: the access entries classify `success => '^(?:1xx|2xx|3xx)$'`, `failure => '^(?:4xx|5xx)$'` on `category_bucket` — the HTTP-specification families, not an ad-hoc list. #452 adds no classification rules (#453 D13: one classification surface) |
| Overall percentages in default output | The run summary's `SUCCESS CLASSIFIED` / `FAILURE CLASSIFIED` rows already render count + share over the classified population via `share_row_text()` → `format_percentage(mode => 'significant', digits => 3, parens => 1)`. Share suppressed on both rows when `$total_successes == 0` (failure-only logs would always read 100%). Note the presentation differs from this surface's decimals-mode row in `docs/percentage-presentation.md` — see AC10 |
| Run-level classification totals on `-V` | `=== format-detection / classification ===` (owned by `features/453-success-failure-classification-event-ledger.md` § `-V` section-contract changes): `lines_included`, `successes`, `failures`, `classified`, `unclassified`, `unclassified_pct`, `unmatched_lines`, `event_ledger_files: N/M`, `rule_changes`, `default_failure`. **Four of the overview's five figures already exist here; only the two percentages are missing** |
| Event-ledger property | Per-file only: `$format_detection{$file}{event_ledger}`, bound from `FR_EVENT_LEDGER` at first match and re-bound on a mid-file rules change. No run-level accessor exists; the only aggregate is the `event_ledger_files: N/M` string built inside `emit_format_detection_verbose()`. #453 D19 (mixed-run behaviour is the consumer's decision) hands the mixed-run rule to this issue |
| Percentage rendering | `format_percentage()` — the shared formatter; `docs/percentage-presentation.md` already carries this surface's row (3 decimals, the column's budget, rounded, `%` kept at every width). Trailing zeros are trimmed unconditionally, so the rendered value is variable-width (`100%`, `99.95%`, `99.995%` — never `100.000%`) |
| Notice channel | No notices surface exists — #412 is open and unstarted. What ships: `defer_notice()`/`flush_deferred_notices()` (flushed at end of read) and direct post-read `print STDERR "Note: …"` emitters (`bin_consolidation_notice()`, `emit_udm_zero_match_notices()`), each annotated in source as a registered producer for #412. Behavioural notices never gate on `--disable-progress` and never carry an ` at … line N` suffix |
| Classification vocabulary in user docs | `--help formats`, `--explain classification`, `docs/explain/classification.md`, `docs/usage.md` § Log formats and classification are in parity on option and consumer content (#453 D23). **But three of them still name a "reliability figure"** — the vocabulary the issue's 2026-08-31 correction retired for numbers — see the sweep list |

## Requirements

Stated in the architect's terms from the issue body (as corrected 2026-08-31: classified
denominator; two columns, not one; no number is named "reliability").

- **R1 — Two data-display columns, no bar.** Success percentage then failure
  percentage, after the occurrences column and before the duration column. Success in
  dark green, failure in dark red. Value only — no bar, no other visual treatment.
- **R2 — The classified denominator.** Per bucket: successes ÷ (successes + failures),
  read from `%bucket_outcomes` — the columns never re-derive an outcome (#453 D13: one
  classification surface; rendering reads counters). Unclassified lines are outside the
  ratio; their shortfall is notice 2's figure, never absorbed into the denominator.
- **R3 — Shared percentage formatter.** Values rendered by `format_percentage()` with
  this surface's parameters from `docs/percentage-presentation.md`: 3 decimals, the
  column's width budget, rounded, `%` retained at every width. The value's intrinsic
  budget is up to six characters for the number plus the `%` sign (issue: the width and
  degradation bullets stand); degradation drops decimals one at a time, never the `%`.
- **R4 — Centred value, headers attempting "Success"/"Failure".** The value is centred
  within the column's characters (architect, 2026-08-31: the small padding computation
  is accepted); headers truncate the way other headers do. (Header wording settled by D7:
  the plain words.)
- **R5 — Full layout participation.** Auto-hide and auto-size behave as for every other
  column. Provisional auto-hide placement, to be tuned on rendered output during
  development: failure is hidden just after the latency statistics block; success
  survives until just before the heatmap tier, outliving duration, bytes and count.
- **R6 — No colour attribution change elsewhere.** Inserting the two columns must not
  alter the colours attributed to any column that follows.
- **R7 — Default visibility gated on the event-ledger property.** Shown by default for
  an event-ledger format; hidden by default (explicitly enableable) for a classifying
  non-ledger format; hide options in the existing hide family, every option with short
  and long forms.
- **R8 — Analysis overview.** Run-total successes, failures, total requests
  (= classified), overall success percentage, overall failure percentage — from the
  totalised counts. The included-lines figure is reported alongside, never as the
  denominator. Where classification is off and the data does not exist, no line is
  printed — the standing verbose-surface behaviour, no policy of its own.
- **R9 — Three mutually exclusive notices**, each with its stated content:
  - *Notice 1 — partial coverage* (non-ledger format, columns explicitly enabled):
    names two blind spots in order of severity — primary, the log may not contain a
    line for every operation that executed, so operations can be missing from the
    figure entirely; secondary, the configured criteria may not attribute an executed
    operation correctly.
  - *Notice 2 — unclassified lines detected* (event-ledger formats): fires on any
    non-zero shortfall of successes + failures against lines included — no threshold —
    stating the count and the percentage of included lines that went unclassified, and
    advising investigating the format's detection patterns for coverage.
  - *Notice 3 — no classification configured* (columns explicitly requested for a
    format declaring no criteria): the columns are not shown, and the notice explains
    why rather than leaving them silently absent.
- **R10 — Documentation sweep.** The consumer enumerations in `--explain
  classification`, `--help formats`, `docs/explain/classification.md` and
  `docs/usage.md` § Log formats and classification gain the new columns and overview in
  the same change (#453 D23 parity). The coverage framing governs all user-facing text,
  and no number is named "reliability" anywhere.
- **R11 — Counters are over the analysis population, not the file.** Lines discarded by
  a filter never reach classification and are in none of the three counters, exactly as
  every other statistic is computed over what survived filtering; an analyst who
  filters to one endpoint family gets that family's success percentage. The general
  caution is #454's, not restated here.
- **R12 — Per-row eligibility (architect, 2026-08-31).** A percentage is printed for an
  aggregation row — the run-level overview, a time bucket's cells, and in the future a
  message row — only when *every* line contributing to that row comes from a format
  that is an event ledger **and** declares both success and failure classifications.
  Raw counts always print; only the percentage representation is gated. Motivating
  scenario: an access log (qualifies) analysed alongside a method-server diagnostics
  log (failure-only default classification) — the diagnostics errors and unclassified
  lines land in the same buckets, so the percentage would move for reasons unrelated to
  the access-log service; those buckets print no percentages, and buckets the
  diagnostics log did not touch keep theirs. The same predicate degrades the global
  statistics: a run with any non-qualifying contribution prints no run-level
  percentages.
- **R13 — Unclassified lines are surfaced, not suppressive (architect, 2026-08-31).**
  Unclassified lines (matched the format, matched neither classification) are ignored
  by the ratio — excluded from the denominator — and do **not** disqualify a row under
  R12; the percentages then represent what is known about the successes and failures.
  In exchange the leakage is called out: the run summary gains an `UNCLASSIFIED` row —
  no such row exists today; the count is currently `-V`-only. Vocabulary pinned by the
  architect (2026-08-31): `LINES INCLUDED` means anything matched (that survived
  filtering); `UNCLASSIFIED` means matched lines that matched neither the success nor
  the failure classification. The row carries the count and its share of included
  lines, alongside the classified rows; the user warning (notice 2) reports the leakage
  on qualifying formats.
- **R14 — Summary rows carry their percentages (architect, 2026-08-31).** All three
  rows show count plus percentage, the way the category rows do, each over its correct
  denominator: `SUCCESS CLASSIFIED` and `FAILURE CLASSIFIED` over the classified
  population (this is shipped #453 behaviour — `share_row_text()` already renders the
  share), and the new `UNCLASSIFIED` row over included lines (the same derivation as
  the `-V` block's `unclassified_pct`). The eligibility interaction is settled by D10:
  on an ineligible run the classified rows' shares are suppressed; counts and the
  `UNCLASSIFIED` share always print.

## Findings that reshape the issue's assumptions

Recorded so the walkthrough starts from the code, not from the issue text.

- **F1 — Almost no new accumulation is needed.** Every counter the ratio and the
  overview read already exists; the one addition is D2's per-bucket eligibility
  provenance count. The columns cannot diverge from the legend's error rate by
  construction — both derive from `%bucket_outcomes`.
- **F2 — The bar behaviour, not the width machinery, is what differs.** The existing
  width-sharing columns already do everything R5 asks (proportional distribution,
  auto-hide, width fed to the value formatter for truncation). What they also do is
  render a bar scaled against the run maximum (`$max_total{$key}` — meaningless for a
  percentage whose reference is 100). D1 resolves this: a declared value-only flag in
  the column schema suppresses the bar; the centred value print is a small new path in
  the render step (no timeline value cell centres today — headers do).
- **F3 — Placement requires static declaration.** `add_dynamic_column()` inserts only
  before `sep_graph_stats` (after duration/bytes/count). "After occurrences, before
  duration" means two static entries pushed between the occurrences and duration blocks
  of `build_column_layout()`.
- **F4 — R6 is already guaranteed for attribution, but two colour hazards are real.**
  Colour is a property of the layout entry, resolved by id everywhere — insertion
  shifts nothing by itself. But (a) dynamic columns (sessions, threadpools, UDMs) walk
  `@column_colors` indices from base 3, so how the new columns source their colour
  decides whether that walk moves (Q12); and (b) green is already the bytes column's
  hue — success and bytes will share a hue family on a default access-log view. Headers
  are rendered `bright-black` unconditionally and never read the column's colour;
  green/red headers would be new capability (Q9).
- **F5 — The data-presence loop overrides declared defaults.**
  `normalize_data_for_output()` sets `visible = 1` for any proportional column with
  data unless its id is in the `%hide_column` map — a default-off decision made in
  `build_column_layout()` is silently reversed unless the new ids are wired into that
  loop (Q13).
- **F6 — Geometry cost of two more width-sharing participants (resolved by D6).** Had
  the columns joined the proportional distribution, the focus share would decay 10
  points per extra column (`focus_share = max(25, 70 − (N−2)·10)`) and derived
  arithmetic at 160 columns showed secondaries falling below the 6-character minimum,
  auto-hiding the latency panel. D6 (minimal fixed budget, outside the proportional
  share) bounds the cost to the two small budgets instead. A side benefit: the
  `-ho, --hide-occurrences` focus-promotion trap (the first visible proportional column
  takes the focus width) no longer reaches these columns, since they are not
  proportional participants.
- **F7 — The overview's figures substantially exist.** Four of five are already on
  `format-detection / classification`; the overall percentages already render on the
  default output as the summary's classified rows. The issue's open question ("verbose
  only, or also default output?") is half-answered by shipped code: the shares are in
  the default output today, as each row's share of the classified population.
- **F8 — The three notices are not exhaustive; two shipped configurations fall through
  or misfire (resolved by D2's eligibility predicate).** (a) The java_gc_g1 format is `event_ledger => 1, classification =>
  'none'` (#453 D9, which expects it to exercise the no-classification notice):
  default-on by R7's letter, uncomputable, and as written notice 2 — not notice 3 —
  would fire, calling a deliberate declination "an accuracy defect in its configured
  patterns". (b) The global default classification declares failure only (no success
  criterion), so every diagnostics format under it yields success = 0: the columns
  would read 0%/100% wherever anything classified, the exact case the run summary
  deliberately suppresses its shares for. "Criteria for one outcome only" is a fourth
  state the notices don't cover.
- **F9 — Per-bucket denominators are legitimately zero.** `%bucket_outcomes` is sparse;
  buckets with no classified line (including injected empty buckets) have no entry.
  What a zero-denominator cell renders is undecided (Q4), and per the observation-count
  rule (CLAUDE.md 2026-07-09) it must be distinguishable from a measured 0%.
- **F10 — #503 (YAML aggregate export) needs raw values, not rendered strings.** Its
  contract is exact figures — no rounding — over the same classified denominator, plus
  an event-ledger state of true/false/mixed for the run. The per-bucket ratio must be
  computable from stored counts at export time; `format_percentage()` is presentation
  only. #503's field names are #503's to declare.
- **F11 — CSV is currently silent.** The MESSAGES CSV carries per-message `successes`/
  `failures` (#453); the STATS CSV has no per-bucket outcome columns, and a new layout
  entry emits nothing to CSV by itself (`@output_columns`/`@populated_graph_columns`
  are built from `@graph_columns`, not from `@column_layout`). Whether the per-bucket
  counts/percentages join the STATS CSV is Q8 — it is the natural substrate for #503.

## Locked decisions

- **D1 — Column model: reuse the existing machinery, no new column type (architect,
  2026-08-31).** The two columns are declared like the other columns — same
  `build_column_layout()` entry shape, same auto-hide participation, column width fed
  to the value formatter for degradation. Width allocation is D6's minimal fixed
  budget, not a proportional share. The column schema gains a
  declared field that suppresses bar rendering (a value-only flag on the layout entry —
  architect's direction, so the render path reads a declared property rather than
  special-casing ids); the render step then prints the `format_percentage()` value
  centred in the cell, with no `$max_total` scaling and no bar. The per-bucket ratio is
  computed once in `normalize_data_for_output()` from `%bucket_outcomes` and stored —
  the same point the error rate derives its per-bucket value — which also gives #503
  its raw unrounded figures (F10).
- **D2 — Per-row eligibility ladder (architect, 2026-08-31; supersedes the mixed-run
  question #453 D19 handed forward).** One predicate at every aggregation scope: a row
  prints percentages only if all of its contributing lines come from event-ledger
  formats declaring both success and failure classifications (R12). This resolves the
  mixed-run default (a mixed run's polluted buckets and its run-level figures print no
  percentages; untouched buckets keep theirs), and it resolves the declining ledger
  (java_gc_g1 declares no classifications, so nothing it touches is eligible) and the
  failure-only default (one-sided classification does not qualify — no fabricated
  0%/100%). Per-bucket evaluation needs provenance today's counters lack: one new
  per-bucket count of lines from non-qualifying sources, incremented at the include
  point — the single new per-line accumulation in the feature (noted against
  prototyping trigger (b): a conditional increment, same cost class as the shipped
  outcome increments).
- **D3 — Unclassified lines: ignored by the ratio, surfaced as leakage (architect,
  2026-08-31).** The lenient rung: unclassified lines never disqualify a row and never
  enter the denominator (R13). The visibility: an unclassified row in the run summary
  (count + share of included lines) and the notice-2 warning that the format's
  classification leaks.

- **D4 — Both criteria are the usability floor; the ledger property only sets the
  default (architect, 2026-08-31).** The percentages cannot be used at all unless a
  format declares *both* success and failure criteria — one-sided classification (the
  failure-only global default) never prints a percentage, explicitly requested or not.
  On that floor:
  - **Default-on** when every matched file's format is an event ledger (with both
    criteria — a declining ledger such as java_gc_g1 has nothing to compute and does
    not qualify); **default-off** otherwise.
  - **Explicit enable** by command-line option where the matched formats declare both
    criteria even without the event-ledger property — the analyst has specifically said
    "this is what I want measured as success and as failure", the unclassified count
    catches the gap, and notice 1 (partial coverage) carries the caveat. Under explicit
    enable the D2 per-row predicate relaxes its ledger requirement but keeps the
    both-criteria requirement: rows touched by a format lacking both criteria still
    print no percentage.
  - An explicit request against formats that do not declare both criteria shows no
    columns; notice 3's condition is accordingly *does not declare both criteria*
    (subsuming "none at all"), and its text explains why. (This notice-3 extension is
    Claude's alignment of the notice scheme to D4 — flagged for confirmation, not yet
    confirmed.)

- **D10 — Eligibility gating is fully consistent across every surface, present and
  future (architect, 2026-08-31).** No surface prints a success or failure percentage
  the D2/D4 ladder disqualified: the timeline cells, the run summary's classified-row
  shares, the `-V` overview keys — and the future export enhancements (#503's YAML
  aggregate and any per-file figures) inherit the same rule. Raw counts always print;
  the `UNCLASSIFIED` share (over included lines — a leakage figure, not a
  classified-denominator figure) always prints.

## Open decisions

None — D1–D16 cover the set; remaining tuning items (D6 exact budget, R5 final hide
priorities) are settled on rendered output during development and locked back here.
- ~~Q4~~ **D11 — Blank cells for absent measurements (architect, 2026-08-31).** Blank cell for both an
  ineligible row (D2) and an eligible bucket with no classified lines (consistent with
  how other
  columns render bucket-absent values), never `0%`; an all-success bucket renders
  `100%` and an all-failure bucket `0%` success / `100%` failure — the endpoints are
  the commonest access-log values, and AC2/AC14 state them explicitly.
- ~~Q5~~ **D5 — The overview lands as additive keys on the existing classification
  block (architect, 2026-08-31).** No new `-V` section: the overall success and failure
  percentages join `format-detection / classification` as additive keys (non-breaking
  per the section's stability contract), alongside the figures already there:
  `lines_included`, `successes`, `failures`, `classified` (the total-requests figure),
  and — architect's reminder, 2026-08-31 — the unclassified figures, which the block
  already carries as `unclassified` and `unclassified_pct` and which stay part of the
  overview's story (D3: leakage is always surfaced beside the percentages). The block
  also gains the run-level eligibility state (whether the run
  qualifies under D2/D4, and the provenance count behind it) so the printed-or-blank
  decision is observable. The percentages obey the same suppression as the rendered
  surfaces: nothing printed when the run is ineligible under the ladder. Section
  contract and `tests/validate-format-detection.sh` update in the same commit, per
  HARNESS-DESIGN; the issue's "may need to be created" is answered by the audit — the
  surface existed.
- ~~Q6~~ **D6 — Minimal footprint (architect, 2026-08-31).** The columns take the least
  space possible: they claim only their intrinsic budget — up to six characters for the
  number plus the `%` sign (R3), plus the standard column spacing — and do **not** join
  the proportional share distribution, so they cannot shrink the focus column or the
  other secondaries beyond the small fixed budget they occupy. They remain full
  auto-hide participants (non-proportional columns are already eligible hide victims —
  the latency panel is one today). The exact budget and whether it degrades below the
  full 3-decimal width before hiding are tuned on rendered output during development
  and locked here afterwards. This bounds F6's geometry cost to roughly the two fixed
  budgets rather than a re-division of the whole width.
- ~~Q7~~ **D8 — One option pair governs both columns: `--hide-classification` /
  `--show-classification` (architect, 2026-08-31).** Per-column hides and an
  `include-*` enable were rejected — the option surface is already hard to navigate,
  and one toggle is enough for now: hide turns the pair off where it is on by default;
  show is the D4 explicit enable where both criteria are declared without the ledger
  property. The word is *classification*, matching the mechanism's vocabulary on every
  shipped surface (`SUCCESS CLASSIFIED`, `--explain classification`) — deliberately
  distinct from the tool's *category* groupings (log-level/status-family groupings of
  messages), which the architect notes are themselves inconsistently named internally
  and are not this mechanism. Proposed short forms, free in the worktree and awaiting
  confirmation 2026-08-31: `-hcl` and `-scl`. Each option: GetOptions spec + `print_help()` row +
  `docs/usage.md` row + `_classify_argv_provenance()` list +
  `emit_runtime_config_verbose()` map, in one commit.
- ~~Q8~~ **D9 — Per-bucket raw counts join the STATS CSV in this drop (architect,
  2026-08-31).** `successes` and `failures` counts per time bucket — counts, not
  percentages: exact by construction (no rounding question), the percentages derivable
  precisely by any consumer, and the eligibility judgement stays the consumer's, per
  #503's own no-rounding contract. #503 (YAML aggregate export) then reads, never
  recomputes. Mechanics: header + row pushes in lockstep in the CSV builder, integer
  family mapping, and `tests/csv-output/rules/stats-columns.tsv` rows in the same
  commit.
- ~~Q9~~ **D7 — Headers are the plain words `Success` and `Failure` (architect,
  2026-08-31).** Each is exactly 7 characters — the same as the full value width
  (`99.995%`) — so the header fits D6's minimal budget with no extra cost; the `%` on
  every value carries the unit. Headers stay neutral like every other header (existing
  behaviour — colouring them would be new capability nobody asked for; the values
  themselves are green/red).
- ~~Q10~~ **D12 — Notices ride stderr; producers register for #412 (architect,
  2026-08-31).** The notices surface does not exist (#412 open, unstarted) and #452
  carries no native `blocked_by`. The three notices ship
  on the existing post-read stderr mechanism (the shape of
  `emit_udm_zero_match_notices()` — they need run totals, so after the read, not via
  `defer_notice()`), registered as producers for #412 both in source (as the shipped
  classification notices are) **and on issue #412 itself** (architect's instruction,
  2026-08-31: a comment on #412 registers this drop's three notice producers,
  including the unclassified-leakage warning, so the notices-surface planning knows
  its consumers) — no dependency edge needed. The issue body's "on the notices
  surface (#412)" is trued up to say the producers register for #412 and ride stderr
  until it lands.
- ~~Q11~~ **D13 — One reconciliation sub (architect, 2026-08-31).** The classified
  denominator is computed in two places today (`print_summary_table()` and
  `emit_format_detection_verbose()`), and the overview and the notices need the same
  numbers: one named reconciliation sub is extracted and every surface calls it (the
  one-resolution-surface rule) — no third or fourth inline copy.
- ~~Q12~~ **D14 — Colour by named definition, never by index (architect, 2026-08-31,
  with an amendment).** The two columns take named colour definitions and consume no
  `@column_colors` index, so the dynamic-column colour walk
  (sessions/threadpools/UDMs from base 3) is unchanged and R6 holds by construction.
  The architect's amendment: the named lookup hash has been built selectively, so the
  dark shades may not be present as usable entries — if the existing `green`/`red`
  entries' stops do not give a true dark green / dark red, register **new named colour
  definitions in the hash** (e.g. dark-green, dark-red) rather than repurposing or
  mutating existing entries.
- ~~Q13~~ **D15 — Single-sited visibility gate (architect, 2026-08-31).** The
  default-visibility decision
  (D2 eligibility, hide options, Q3's explicit enable) is resolved in exactly one place, and the
  new ids are excluded from the data-presence loop that force-shows proportional
  columns (F5). Without this the `build_column_layout()` default is silently reversed.
- ~~Q14~~ **D16 — Overview scope stays at the classification figures (architect,
  2026-08-31).** The mandated audit's findings, for the record: run-level
  figures that exist today and could join the overview: `lines_included`,
  `unmatched_lines`, `rule_changes` and `event_ledger_files` (all already on
  `format-detection / classification`); and the two run-level figures with a rendered
  surface but **no** `-V` surface at all — the per-category totals
  (`%category_totals`, the run summary's category rows) and the highlighted-line count
  (`$total_lines_highlighted`). Figures that do **not** exist and would be new
  accumulation (hence prototyping-scope hot-path work, out of this drop unless asked):
  run-level distinct sessions (per-bucket sets are deleted after reduction), run totals
  for duration/bytes/count, any run-level rate. Decision: the overview carries only
  the classification figures; `%category_totals` and `$total_lines_highlighted` are
  candidates for a separate future decision, not this drop.

## Acceptance criteria

Draft — to be agreed before implementation (`docs/test-driven-development.md`);
criteria marked (Qn) cannot be finalised until that decision is locked. Triage:
*Assertable* / *Unassertable* / *Unknown*.

- **AC1** (R2) — On a fixture with a known per-bucket mix — e.g. 3 successes, 1
  failure, 6 unclassified in one bucket — run at `-bs 1440 -oe`, the success cell reads
  `75%`, not `30%`: the denominator is `%bucket_outcomes` successes + failures, and
  unclassified lines move nothing. *Assertable* — rendered output on a crafted fixture;
  cross-checked against `-V format-detection / classification` totals summed over
  buckets.
- **AC2** (R3) — The rendered values are `format_percentage()` output with `mode =>
  'decimals', digits => 3` and the column's width budget: `100%` for an all-success
  bucket (trailing zeros trimmed, never `100.000%`), `99.95%` vs `99.995%`
  distinguishable at full width, decimals shed one at a time as width shrinks, the `%`
  present at every width. *Assertable* — width sweep, reading the rendered cell.
- **AC3** (R1, D1) — The success cell renders with no bar: decoded cell shows fill
  extent 0 and value text in the green foreground; failure likewise in red. The decoded
  foreground code alone cannot prove which colour table supplied it — the
  mechanism-substitution check is AC6, which is discriminating. *Unknown* — needs the
  timeline-cell selector; *Assertable* — the selector is demonstrated
  (`prototype/452-timeline-cell-selector/`): slice the column's cells by
  `--debug-layout` offsets, assert `fill_extent() == 0` and `text_colour()`
  equal to the named colour definition.
- **AC4** (R1) — `--debug-layout` lists the two new ids between `occurrences` and
  `duration` in array order. *Assertable* — trivial.
- **AC5** (R4) — The value is centred: on an odd remainder the extra space is on the
  left, so the value sits one column right of exact centre — the same geometry the
  header rule produces. *Assertable* — the selector's `centred_report()` states the rule and
  flags right-heavy and left-aligned values (prototype arm E).
- **AC6** (R6, Q12) — On a run carrying sessions, threadpools and a UDM, every column
  after the insertion point renders the same colours as the base commit: the new
  columns consume no palette index, so the dynamic-column colour walk is unchanged.
  *Assertable* — per-column `fill_colour()`/`text_colour()` comparison between a
  base-commit capture and the change, by column id (prototype finding: the
  discriminating form is the comparison, not a palette-index grep).
- **AC7** (R5) — Across a terminal-width sweep, the auto-hide sequence drops failure
  immediately after the latency panel and drops success only after duration, bytes,
  count, sessions and UDMs (provisional priorities ~65 and ~25; final values tuned on
  rendered output, then locked here). *Assertable* — `--debug-layout` hide-order values
  and auto-hidden markers; sabotage: swap the two priorities.
- **AC8** (R7, D2, D4) — Columns present by default on an all-ledger both-criteria run
  (access log); absent by default on a classifying non-ledger run
  (`log-level-vocabulary` fixture under the failure-only default) and on the declining
  ledger (java_gc_g1). The explicit enable option shows them on a both-criteria
  non-ledger run (notice 1 fires); an explicit request on a one-sided or declining run
  shows no columns and fires notice 3. *Assertable* — `--debug-layout` visibility plus
  `-V format-detection` `event_ledger:` cross-check and stderr assertions.
- **AC15** (R12, D2) — On a two-file run — a qualifying access log spanning all buckets
  and a non-qualifying diagnostics log overlapping some — the overlapped buckets print
  no percentages, the untouched buckets print the access log's stable figures, and the
  run-level overview prints counts but no percentages. Sabotage: the same run with the
  diagnostics file removed prints percentages everywhere. *Assertable* — rendered
  output on crafted fixtures; the eligibility provenance count cross-checked on `-V`.
- **AC16** (R13, D3) — On a qualifying run with unclassified lines, the run summary
  shows the unclassified row (count + share of included lines), the percentages still
  print (denominator excludes the unclassified), and the leakage warning fires; on a
  fully-classified run the row shows zero (or per the gating convention of the
  classified rows) and no warning fires. *Assertable* — summary-render and stderr
  assertions.
- **AC9** (R7, Q7) — Every new option appears with short and long forms in `--help` and
  `docs/usage.md` (enforced by `tests/validate-help-content.sh`), and in `-V
  runtime-config` provenance. Behaviourally, each hide option removes exactly its
  column. *Assertable* — existing harness plus `--debug-layout`.
- **AC10** (R8, Q5, Q11) — The overview's five figures are *numerically* equal, on the
  same run, to the shipped sources: `successes`/`failures`/`classified` on
  `format-detection / classification`, and the values behind the summary rows' shares —
  one reconciliation, no second accumulator. Rendered strings are asserted against each
  surface's own declared parameters (the summary renders significant/3 in parentheses;
  this surface decimals/3 — they legitimately differ in presentation). Zero-success
  suppression matches the run summary. *Assertable* — parity assertions in the owning
  harness.
- **AC11** (R9, Q3) — For each of the four classification configurations (all-ledger
  classifying with an unclassified shortfall; non-ledger explicitly enabled; declining
  format explicitly requested; fully-classified ledger), exactly the specified notice —
  and no other — appears on stderr; silence on the clean case. Notice 1 names both
  blind spots, primary (missing lines) before secondary (misattribution); notice 2
  states the shortfall count and its percentage of included lines and advises
  investigating the format's detection patterns for coverage; notice 3 states why the
  columns are not shown. Notices print regardless of `--disable-progress` and carry no
  ` at … line` suffix. *Assertable* — the notice-harness pattern
  (`tests/validate-numeric-criteria-notices.sh` shape), with an exactly-one-of-N count
  assertion.
- **AC12** (R10) — The consumer enumerations in `--explain classification` and
  `docs/usage.md` name the columns and the overview; all four classification surfaces
  stay in parity; no user-facing text names a number "reliability". *Assertable* —
  `tests/validate-explain.sh` / `validate-help-content.sh` plus doc review.
- **AC13** (overall visual) — The rendered timeline on a real access log, at 200/160/
  120 columns, is looked at before the work is called done: colours, centring,
  degradation, and the geometry trade of Q6. *Unassertable as a harness in full* — the
  per-property assertions above cover the parts; the composed look is verified by eye
  on real data (repo rule for visual surfaces), cost: minutes per iteration.
- **AC14** (Q4) — On a fixture where one bucket carries only unclassified lines and an
  adjacent bucket only failures, the first bucket's two cells render blank and the
  second renders `0%` success / `100%` failure — and the two rows are distinguishable
  in the decoded output. A measured zero and an absent measurement never look the same.
  *Assertable* — rendered output on a crafted fixture.

**Unknown-state triage — resolved 2026-08-31.** The trigger-(d) prototype ran and
exited with a demonstrated assertion method: `prototype/452-timeline-cell-selector/`
parses the `--debug-layout` table into per-column cell offsets (accumulated as the
layout engine spends width), slices a decoded timeline row to one column's cells,
and asserts colour, fill and centring per column. Demonstrated on the bytes column
(known fill table 256:46/34, inversion, extent) at widths 160 and 120 (auto-hide
active); validated against the #448 defect classes that apply to a timeline column
— S4 one-cell overdraw, S5 lost value colour, S6 twin shades flattened — each
reading differently from the correct slice; sabotaged offsets fail loudly (changed
slice content, or a hard die past the row end), and a missing debug table or column
id is a hard failure. AC3, AC5 and AC6 are therefore *Assertable*; productionising
is ≈70 lines moved into `tests/lib/rendered-output.pl` plus a
`render_column_report` wrapper in `tests/lib/rendered-output.sh`, done in the
implementation stage under HARNESS-DESIGN's assertion-change rules. One predicate
caveat recorded in the findings: `text_colour()` reads only the unfilled portion of
a slice — exactly right for these bar-less columns. No other prototype trigger
applies beyond the note on D2's provenance increment: no new data model (the store
ships), and the remaining work is per displayed cell.

## Hand-forward

- **Per-file success/failure percentages** — outputting the figures for a whole file
  (as distinct from the run and the bucket) is a future issue the architect named
  (2026-08-31); it inherits D2's eligibility predicate evaluated over the file's
  population. To be filed separately.
- **Per-message percentages** — the per-message outcome counts ship (#453, MESSAGES
  CSV `successes`/`failures` columns); a rendered per-message percentage is future
  scope and inherits the same predicate.

## Regression surface

Two default-on columns on access logs move rendered goldens: 38 of 74
`tests/reference-output/*.txt` scenarios bind an event-ledger format and re-bless
(the access, auto-hide, omit-family, error-rate-access and Apache
histogram/highlight scenarios, including their bin-mode variants) — the count is
conditional on the D2/Q3 gate, which keeps all 38 in scope.
`tests/validate-duration-display.sh` and `tests/validate-statistics-demand.sh` anchor
on access-log timelines at fixed widths; `tests/validate-doc-examples.sh` re-runs any
`docs/usage.md` timeline examples. Soft-wrap pressure at narrow widths lands on the
#497 known-failures registry (XPASS-aware — entries that stop overflowing are also
reported). The full-suite completion gate and the before/after benchmark run per the
per-feature workflow; the benchmark is expected flat (F1 — no new per-line work), which
is itself worth confirming.

## Record maintenance riding this drop (sweep items, architect to confirm)

- **The "reliability figure" vocabulary survives the 2026-08-31 correction on three
  user-facing surfaces and in the #453 feature doc**: the `--explain classification`
  text in `ltl`, `docs/explain/classification.md` (wiki-synced), `docs/usage.md`
  § Log formats and classification, and four occurrences in
  `features/453-success-failure-classification-event-ledger.md`. The correction: the
  numbers are success percentage and failure percentage; "reliability" names a
  dimension, never a number. True up with this drop's R10 sweep.
- `docs/percentage-presentation.md` still names a singular "Reliability column (#452)"
  — the reframe swept `features/448-category-summary-share-and-bar.md` and
  `features/453-success-failure-classification-event-ledger.md` but not this doc. True
  up to the two-column framing.
- The issue body still carries "The total-requests figure … is not the denominator"
  from before the 2026-08-31 comment that settled total requests *as* successes +
  failures; true up alongside the Q10 body edit.
- `features/user-defined-metrics.md` § Design Decisions row "Non-access-log support"
  still describes `$is_access_log`, retired by #453 D10 (every `$is_access_log` site
  mapped to `metrics_observed`).
- `docs/test-driven-development.md` § Visual surfaces still calls the rendered-surface
  assertion method "an open question"; `tests/lib/rendered-output.pl` and
  HARNESS-DESIGN § Asserting rendered output now answer it — and #452 is the first
  feature planned against it.
- HARNESS-DESIGN's reserved-names list lacks the shipped `format-detection /
  classification` sub-section (and others); the entry #452 touches gets added when the
  `-V` change lands.

## Merge gate

Per-feature workflow step 1 in full: the change touches `ltl` and harness expectations,
so every `tests/validate-*.sh` exits 0 on the merge commit, plus the before/after
benchmark on `single-day-access-log-standard` against a base-commit baseline captured
before the first code change. Version restored to `0.18.0` before the gate. Acceptance
criteria above pass; AC13's eye pass on real data is recorded in the completion
comment.
