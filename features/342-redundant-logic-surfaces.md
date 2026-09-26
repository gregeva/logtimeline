# Redundant logic surfaces and architectural patterns across `ltl` (Issue #342)

## Status

Specification in progress on branch `342-redundant-logic-surfaces` off
`release/0.19.0`, written section by section with the architect.

Decisions taken by the architect at the start of the work (2026-09-26):

- **This issue is an audit.** Its output is findings, categorised and prioritised,
  recorded in this document, plus `docs/architecture-patterns.md` and its two
  `CLAUDE.md` entries. It changes no executable line of `ltl`, so no before/after
  benchmark is captured on this branch.
- **The audit files no sub-issues.** Which findings become issues of their own, and
  which are grouped, is decided in discussion of the findings once they are recorded
  here. The audit record stays in this document whatever that discussion decides.
- **Delivery is staged in two drops on the issue branch** (decided 2026-09-26, after
  the item 8 measurement was confirmed in scope). Drop 1 is the audit of scope
  items 1 to 7 and the patterns sweep: the report's findings, the start of their
  triage, and the selective conversion of findings into issues. Drop 2 is scope
  item 8: the per-line loop inventory, the cost-curve measurement and the
  assessment of the two remedies. The benchmarking and profiling for drop 2 run in
  the background while drop 1's triage proceeds. **Each drop ends in its own PR
  against `release/0.19.0`** (the architect's instruction, overriding the
  one-PR-per-issue default), so that drop 1's findings are on the release branch
  before the issues created from them are cut off it. After drop 1's PR merges the
  issue stays open and `in progress`; the completion comment and the close come
  with drop 2's PR.
- **Every finding is cross-checked against the open issues** (the architect's
  instruction of 2026-09-26, given after the specification was written and
  transcribed here). For each finding the report names every open issue whose
  scope touches the same surface, and states the relationship in words: the issue
  would remove one of the copies, would add a copy or a reader of the vocabulary,
  depends on the contract the finding leaves open, or has already recorded the
  same observation. A finding with no open issue on its surface says so. The
  open-issue list is captured once per audit session (`gh issue list --state
  open`) and each relationship is read from the issue body, not from its title.
- **A fix to any finding follows the normal development workflow** (`docs/process/workflow.md`):
  its own issue, branch, specification, completion gate, and, where it touches the hot
  path (the per-line processing loop, sorts, anything executed per line or per key at
  high cardinality), a before/after benchmark on the machine doing the work.

---

## 1. The motivating consumer

The consumer is the next person who adds to `ltl` something that already has a
counterpart: an option that takes an operand other options also take, a rendered
value of a class a formatter already owns, a timestamp arm for a new format, a
derived mean or percentage, a range check, a CSV column, a message-key variant, or
a per-line branch in the read loop. That person has two questions, and today the
code answers neither reliably:

1. **Which named sub do I call?** For some vocabularies there is one and the rule
   is to use it (metric-name operands after #327; the time-unit ladder after #524;
   `raw|bin` validation after #266). For others there is none, and the author copies
   the nearest site, which is how every duplicate in this audit came to exist.
2. **Which established pattern do I build on?** The codebase already has recurring
   shapes (a declarative registry compiled once, a run-scoped activation flag tested
   per line, a demand gate resolved at option settlement, a `-V` section as the
   test surface, a single layout declaration driving every renderer), but they are
   described, where they are described at all, inside the feature doc of the issue
   that introduced each one. Nothing lists them, so an author building a new
   capability cannot find the pattern to conform to without already knowing it.

Two worked instances show what the absence of an answer costs.

**#327 (histogram selector not respecting the case sensitivity of user-defined
metric names).** `-hm` and `-hg` each parsed metric-name operands with their own
code. They diverged twice: `-hg` lowercased user-defined metric names, and `-hm`
matched built-in names case-sensitively against the documented case-insensitive
contract. The fix routed both through `builtin_metric_name()`,
`resolve_metric_operand()` and `available_metric_names()`, and
`features/histogram-charts.md` now states the contract that any new option taking
metric-name operands resolves through them. The scoping sweep for this audit found
that the contract holds for those two options only: `--hide`/`--show`, `-x` and `-d`
resolve the same names with their own literals, and `-so` with a third copy, so the
`time` alias and case folding differ between them today.

**#478 (the highlight decision re-derived from the category suffix throughout the
read loop).** The tag point in `read_and_process_logs()` computed "is this line
highlighted" once and kept no boolean; thirteen sites in the same loop re-derived
it with a regular expression on the category string, while one block had already
hoisted it into a local. The fix was thirteen one-line edits with a proven
equivalence argument, and the doc records that nothing mechanical prevents a
fourteenth site from appearing.

The pattern in both is the same. The duplicate is not wrong when written; it is a
faithful copy. It becomes wrong later, when one copy is changed for a reported case
and the others are not, and the divergence is visible only to a user who exercises
two options in the same run. The cost lands on whoever fixes the next report, who
has to find every copy again from scratch.

The consumer is served when the audit leaves behind:

- a table of every place a vocabulary, value class or decision is resolved more
  than once, each with the sub it should converge to and the evidence of whether the
  copies already disagree, so the next fix knows every site it has to reach; and
- a file that names each architectural pattern, says what it is for and why, and
  lists where it is used, so the next capability is built on a pattern rather than
  beside one, and so the file itself shows which patterns are worn thin enough to
  need refinement.

There is no user-observable change from the audit. Every convergence or
restructuring it motivates is its own issue with its own record.

---

## 2. Requirement

In the architect's terms, transcribed from the issue body and the directional
guidance of 2026-09-21, organised but not reinterpreted.

### Mandate

Review the entire `ltl` codebase against the shipped feature set and identify every
place where the same vocabulary, value class or decision is implemented more than
once (parsing, resolution, validation, matching, formatting, unit handling, alias
handling), and produce a harmonisation plan converging each to one named function.
Beyond duplicated code, identify the common architectural patterns that exist across
`ltl` and record them in a new file for tracking them. This is the systematic
follow-through on the rule that there is one resolution surface per vocabulary and
that duplicated logic is a defect: duplicated surfaces drift independently under
maintenance, and each copy is a place a future fix will miss.

### Scope of the sweep

For each category, enumerate all implementation sites, note observed or latent
divergences, and name the single function each should converge to.

1. **Option-operand vocabularies.** Options sharing operand sets (metric names, unit
   tokens, data-model selectors `raw|bin`, sort fields, rate units, colour and
   background selectors). Reference: the #327 convergence.
2. **Unit and value formatting.** Duration, bytes, count and number rendering
   (`format_time`, `format_bytes`, `format_duration`, `format_number`,
   `format_cv_display`, the CSV and display paths): any inline `sprintf` or
   arithmetic that restates what a formatter owns.
3. **Timestamp parsing.** The per-match-type parse arms in `read_and_process_logs()`
   (the substr/timegm ISO arm, the month-map Apache arm, the epoch arm) and the
   timestamp cache handling; #328 added a guard to only one arm.
4. **Aggregation and statistics gating.** Sites deriving mean or occurrence-gated
   values from accumulator pairs; #326 fixed one of at least two parallel mean
   derivations (per bucket versus per message).
5. **Filter and highlight range checks.** The twelve `-dmin`/`-dmax` to
   `-hcmin`/`-hcmax` bounds and their inclusive-boundary and inverted-range logic
   (#312 and #322 touched these as families); confirm one comparison surface.
6. **CSV emission column lists.** Header construction versus row emission for the
   MESSAGES and STATS CSVs, maintained in parallel and kept aligned by the #335
   unknown-column check; assess deriving both from one declaration.
7. **Message-key construction.** The repeated truncation expressions around the
   assembly of the message key.
8. **The structure of the per-line loop in `read_and_process_logs()`** (added
   2026-09-21). Not a duplication cluster but the structure of the loop itself, from
   a measured finding under #567: a correctly gated, non-executing addition still
   cost about 1.6 percent on access logs and 0 percent on an application log, the
   whole cost inside the loop sub's exclusive time, with both binaries executing the
   same statements per line. The reviewer is to:
   1. enumerate what the loop body carries per line that is constant for the run
      (every activation gate, every flag test on a capture, every option-shaped
      branch);
   2. establish the cost curve, not a single reading, by the #567 bisect method
      (interleaved rounds, both binaries, median of ten per candidate), because a
      single before/after pair cannot resolve an effect of this size;
   3. assess generating the per-line path per run, as the format scan sub is
      already generated and cached by scan-order signature, so that a run naming
      nothing carries none of the option-shaped branches;
   4. assess hoisting per-line option handling out of the loop body as the smaller
      alternative, and cost it against generation;
   5. check whether the effect generalises to the other log family that spends
      proportionally more time in the loop body (predicted, unverified).

   This is a measurement question before it is a refactoring question: any proposal
   here carries its own interleaved before/after, not a single pair.

### Architectural patterns

For each pattern the sweep finds, the new file defines and describes it, explains
its expected and intended uses, gives the architectural reasoning for it, and gives
examples of where it is used throughout the codebase. The file is another form of
index alongside the feature docs: patterns are refined over time and their
consumption sites understood, so that it can be established which patterns need
refinement. Its purpose is consistency and development best practice: when a new
enhancement presents, it is built on an established pattern rather than the code
simply being written.

### Deliverables

1. A findings table (site A, site B, vocabulary, observed divergence, target
   function), ranked by divergence risk. The issue body continues "followed by
   per-cluster convergence sub-issues for anything non-trivial"; that part is
   amended by the architect's decision of 2026-09-26 recorded in § Status: the audit
   files no sub-issues, and which findings become issues, and how they group, is
   decided in discussion once the findings are recorded here. Convergence changes
   themselves land as separate PRs with behaviour matrices proving parity; the
   #327 follow-up PR's test matrix is the template.
2. The architectural patterns file, `docs/architecture-patterns.md`, committed
   together with a row in the *Where to look* table of `CLAUDE.md` pointing at it,
   entering every pattern the investigation identifies with its definition,
   intended uses, reasoning and consumption sites.
3. In the same commit, a line in the *Before writing or changing code* checkpoint
   of `CLAUDE.md` that keeps the file current: before building, consult the file
   for a pattern that fits; a change that adds a consumption site of a pattern, or
   introduces a new pattern, records it in the file in the same commit.

### Constraints

- Convergence must not change documented behaviour except where copies already
  disagree; in that case the documented contract wins, and the deviation is called
  out in the PR body.
- Each converged surface gets its contract stated in the owning feature doc, as
  `features/histogram-charts.md` does for metric operands.

### Worked instance on record

The architect's comment of 2026-09-13 records #478 (the highlight decision
re-derived from the category suffix throughout the read loop) as a worked instance
of a duplicated resolution surface, specified in
`features/478-highlight-decision-read-back.md`, and delivered on its own rather than
held for this sweep.

---

## 3. Corrections to the issue body

Verified against the tree at the merge of PR #606 (`main` 7aa2bd5, the base of
`release/0.19.0`), by grep on `ltl` and on the feature docs. Each names what was
looked for and what was found; the audit's method (§ 4) is written to the corrected
picture, not to the issue's.

1. **`timestamp_cache` does not exist.** Zero hits in `ltl`. The cache of parsed
   timestamps is `%timestamp_date_cache`, mapping a date string to its midnight
   epoch, bounded at `TIMESTAMP_DATE_CACHE_MAX` (100) entries with oldest-insertion
   eviction, maintained by `timestamp_date_cache_add()` and cleared, snapshotted and
   restored by its sibling subs. In front of it, for scanned formats only, sits a
   last-seen memo (`$format_last_ts_str` / `$format_last_ts_epoch`) that reuses the
   previous line's epoch when the timestamp string is unchanged. The old name
   survives as history in `features/58-format-registry-staged-detection.md` and
   `features/log-format-registry.md`.

2. **The parse arms are not "per match type in `read_and_process_logs()`".** For
   every scanned format the arm is generated by `format_entry_block_src()` from the
   format's declared time layout (`iso_*` layouts take the substr/timegm arm,
   `apache_clf` the month-map arm) and inlined into the generated scan sub, so the
   line arrives in the loop with its epoch already set. Only two arms sit in
   `read_and_process_logs()`, both for CSV input: an ISO arm that calls the entry's
   time-parse closure, and an epoch arm. A second copy of the ISO and Apache arms
   exists as closures built by `compile_format_time_parser()`; only the ISO closure is
   ever called (by the CSV arm), and the Apache closure is built for seven entries and
   never invoked. Arms are selected by layout, not by match type.

3. **The #328 guard is on the CSV ISO arm only.** It is a shape check
   (`$timestamp_str !~ /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/`) that skips the row
   and counts it. The CSV epoch arm has no guard: epoch mode is decided from the
   first data line alone, and a later non-numeric value reaches `int()` under
   warnings. The Apache arm has no guard in either copy. The scanned ISO arms carry a
   different guard, added later, on impossible month and day values, which the CSV
   ISO arm lacks, so by reading a CSV value with month 13 reaches `timegm` unguarded.
   Neither by-reading gap was run.

4. **`read_and_process_logs()` is 1,619 physical lines, 1,008 of them code**, from
   `sub read_and_process_logs` to the next `sub`. The per-line loop (`while (1) {`
   to its closing brace before `close $fh`) is 1,343 physical lines, 830 code. The
   "around 870 lines" in the #567 post-release finding and the 2026-09-21 comment is
   closest to the loop's code-line count; the specification measures the loop and
   says so.

5. **Scan-sub generation is not in `build_format_registry()`.** Under the registry's
   D60 (zero code generation at startup, elevation by election) that sub resolves
   the specs, sets the scan order, stores the run options and clears the cache; it
   compiles nothing. Generation is `compile_format_scan_sub()`, and the cache keyed
   by order signature is in `format_scan_sub_resolve()`. A second inline
   lookup-or-compile in `format_registry_set_occupant()` computes the same signature
   without going through the resolve sub, so occupant swaps do not count toward the
   `scan_sub_cache_hits` telemetry. Only two run options are baked into the generated
   code today (`include_query_string`, the exposed metric set), plus one folded into a
   per-entry constant at build time (classification qualifying).

6. **Two of the vocabularies scope item 1 lists are not option-operand
   vocabularies, and several it omits are.** No option takes a log-level name
   (`@log_levels` and `%log_level_set` are consumed internally only;
   `features/475-log-level-vocabulary-completion.md` records "no level list, no new
   option"), and `-lbg`/`-dbg` are booleans, so there is no colour or background
   selector operand. Shared operand vocabularies the sweep found and the item does
   not name: sort fields and statistic names (`-so`, `--explain`, `--help statistics`),
   mask identifiers (`-m`, `-d`), parsed-field names (`-x`, `-d`, the `--hide` columns
   for session and user), section and column names (`--hide`, `--show`), byte and SI
   units (the `-udm` unit slot and two internal converters), and format names
   (`-lf`, `--help formats`).

7. **The #335 check aligns the header against the rules TSV, not the header against
   the row.** `check_column_structure()` in `tests/csv-output/validate-csv-output.pl`
   fails any header name absent from the rules TSV. Header-to-row alignment is a
   separate per-row field-count check, and the STATS row is padded to the header
   width before it is written, so a row that comes out short passes that check and
   is caught only if a type or range rule trips on the shifted values.

8. **`@column_layout` cannot already serve as the CSV declaration.** Each entry is
   one display column with display fields only (id, name, width, spacing,
   visibility, colour); the CSV carries families of statistics per metric, CSV-only
   columns and highlight twins that have no layout entry, and
   `features/column-layout-refactor.md` § Required Separation keeps the CSV out of the
   layout by design. Item 6's "assess deriving both from one declaration" therefore
   means a declaration that does not exist yet, not the layout.

9. **Every other sub the issue names exists once**: `format_time`, `format_bytes`,
   `format_duration`, `format_number`, `format_cv_display`, `builtin_metric_name`,
   `resolve_metric_operand`, `available_metric_names`, `build_format_registry`,
   `read_and_process_logs`. `tests/profile/results/567-access-log-regression/`
   (`hypothesis.md`, `analysis.md`) and
   `features/567-discard-named-values-from-message.md` § Post-release finding exist,
   and the numbers in the 2026-09-21 comment match them.

10. **Three delivered feature docs are stale on surfaces this audit reads.** Recorded
    here, not edited, since each is the record of a completed issue:
    `features/432-metric-aggregate-naming-parity.md` § F1 quotes a source comment
    ("BUG/ WRONG") and a grep target that no longer exist, the per-message bytes mean
    now dividing by `bytes_occurrences`; `features/fuzzy-message-consolidation.md`
    IQ-01 and IQ-02 describe a grouping key of level, thread, object and session and
    an observed length tracked on the message body, where the code groups on the
    level alone and measures the whole key; `features/user-defined-metrics.md` says
    all byte units are base 1024, where `convert_bytes` maps kB, MB, GB and TB as
    decimal and K, KB and the IEC units as binary.

One further correction to the plan's own inventory, so the numbers here are not
re-derived wrongly later: the scoping sweep's first pass attributed four sites to the
wrong enclosing sub (a file-scope table between two formatters, two banner comments
preceding a `sub` line, and one file-scope lexical inside the subs section); the
verifier corrected each, and this document cites code by an in-body snippet inside
the named sub, never by a comment above it.

---

## 4. Method per scope item

Each item below states what the item covers, what the scoping pass of 2026-09-26
found (a read-only inventory of `ltl` at 7aa2bd5, each site re-grepped by an
independent verifier), the search angles the audit runs to complete it, the shape of
evidence a finding carries, the locked decisions that bound any convergence, and the
questions the findings discussion has to settle. The scoping counts are a floor, not
the audit: the audit re-runs every angle and records what it finds in § 5.

Every finding, in every item, is cited by enclosing sub name plus an in-body snippet
that `grep -F` finds inside that sub. Line numbers are not recorded.

### Item 1: option-operand vocabularies

**What it covers.** Every set of operand tokens that two or more command-line
options accept, and every place such a token is parsed, matched, validated, listed
in an error message, or listed in a help row. One vocabulary is converged when one
named sub does the resolution and every option that takes the vocabulary calls it,
and the lists a user sees (errors, help) are derived from the same table the sub
reads.

**What scoping found.** Nine vocabularies are shared by two or more options. Their
state today:

| Vocabulary | Options sharing it | Shared surface today | State |
|---|---|---|---|
| Built-in and user-defined metric names | `-hm`, `-hg`, `-so`, `--hide`/`--show`, `-x`, `-d` | `builtin_metric_name()`, `resolve_metric_operand()`, `udm_config_by_name()`, `available_metric_names()` | Converged for `-hm` and `-hg` only. `--hide`/`--show`, `-x` and `-d` call `udm_config_by_name()` alone and match built-in names by their own literals; `-so` calls none of them |
| Time units | `-du`, `-ru`, `-bs`, the `-udm` unit slot | `@time_unit_ladder`, `time_unit_canonical()`, `$time_unit_list` | Converged in code (#524 D1). The help rows for all four write the unit list as a literal |
| Data model `raw\|bin` | `-dm`, `-bdm`, `-hmdm`, `-hgdm`, `-mdm` | `_validate_dm()`, `resolve_data_model()` / `choose_data_model()` | Validation converged (#266). Each surface's default (`// 'bin'`, `// 'raw'`) is repeated at fourteen call sites instead of held with the surface |
| Sort fields and statistic names | `-so`, `--explain`, `--help statistics` | none | The `-so` vocabulary is written three times: an allow-list, a regex ladder re-listing every name, and the help row (which omits eight accepted spellings). `%explain_aliases` says it mirrors `-so` and does not. The `-so` error names no vocabulary |
| Mask identifiers | `-m`, `-d` | `%mask_patterns` / `@mask_order` | `-m` resolves through the table; `-d` matches the same names by literal (`uuid`, `ipv4`, `ipv6`, `ip`) and reads only the pattern from the table. The `-m` error list is a literal, not derived |
| Parsed-field names | `-x`, `-d`, `--hide` (session, user) | none | `-x` accepts thread, session, user, query-string; `-d` accepts those plus object, and re-lists the set a second time inside the same sub |
| Byte and SI units | the `-udm` unit slot; internally `convert_bytes()` and `format_bytes()` | none | Three tables: `%byte_units` and `%si_units` in `parse_udm_configs()`, a second map in `convert_bytes()`, a third in `format_bytes()`. `K` means 1000 in one and 1024 in another. The help row repeats the list as a literal |
| Format names | `-lf`, `--help formats` | the format registry | Both derive from the registry but enumerate different structures with the verification filter written twice |
| Section and column names | `--hide`, `--show` and their per-column shorthands | `resolve_visibility_name()`, `%column_aliases`, `@visibility_columns` | One resolver; the built-in metric column names are yet another literal copy of the metric set |

Single-option vocabularies also seen, in scope only where their error text or help
row restates a table that exists: `-V` sections (fully converged through
`%verbose_section_registry`), `-pr` modes (validated against `%profile_modes`, error
text a literal), `--help` topics (an if/elsif chain; the dispatch error and the help
row disagree on the topic list), `-cp` modes (literal allow-list and literal error).

Sixteen concrete divergences were observed between copies. The ones that change what
a user gets:

- The `time` alias for duration works on `-hm`, `-hg` and `-so` and nowhere else;
  `-d time` falls through to the line-key path and removes a `time=` key from lines
  instead of omitting durations.
- Metric names fold case on `-hm`, `-hg` and `--hide`/`--show` and are exact on `-x`
  and `-d`, so `-x Bytes` becomes a line key.
- `durationMs` and `durationMS` are accepted as duration by `-x` and `-d` only, in
  three separate literal copies; `-hm` and `-hg` reject them.
- A user-defined metric can be named by its token key on `-x` and `-d` only.
- Three unknown-metric messages for `-hg`/`-hm` list three different vocabularies
  (one includes `time`, one names built-ins only, one names user-defined metrics and
  omits `time`), and `-hg` pushes an unknown operand back as a filename silently
  where `-hm` warns.
- The built-in metric set `duration`/`bytes`/`count` is written as a separate
  literal in at least eleven places, including four help rows.

**Search angles the audit runs.** Four, each blind to the others, so a site one
misses another finds:

1. *By option.* From the `GetOptions` block, every option whose handler or later
   resolution compares its value against a token: follow the variable to every
   `eq`, `=~`, `exists`, `grep` and hash lookup on it.
2. *By token.* For each token in each vocabulary (`duration`, `time`, `bytes`,
   `size`, `count`, `raw`, `bin`, each unit spelling, each mask name, each field
   name), every literal occurrence in `ltl`, classified as resolution, error text,
   help text, or internal consumer of already-resolved state (the last is out of
   scope for this item).
3. *By error and help text.* Every `print_usage`, `die`, `warn` and `help_opt` that
   enumerates accepted values: does the list come from the table or from a literal?
4. *By table.* For each existing table (`@time_unit_ladder`, `%mask_patterns`,
   `%verbose_section_registry`, `%profile_modes`, `@visibility_columns`,
   `@duration_family_stats`, the registry): every reader, and every place that
   should read it and does not.

**Evidence a finding carries.** The vocabulary; site A and site B (sub plus
snippet); what each does with the token (parse, match, validate, list); the
observed divergence, stated as what a user would see on each option with the same
input, or "identical today"; the target sub (existing, or the name and shape of one
to create); the documented contract the copies must satisfy, with its owner. Ranking
by divergence risk: copies that have already diverged rank above copies that differ
in behaviour today, which rank above identical copies.

**Locked decisions that bound convergence here.** Convergence uses these or raises
the conflict; it does not substitute.

- `features/histogram-charts.md` § Command Line Interface (from #327): built-in
  names match case-insensitively, `time` aliases `duration`, user-defined names are
  case-sensitive and match by name then base name; any new option taking metric-name
  operands resolves through the three named subs.
- `features/524-bucket-size-unit.md` D1 (one time-unit ladder at file scope, read by
  every time-unit surface; no sub keeps a unit table of its own) and D2 (the ladder
  and its spellings, locked; `m` is minute on time units only).
- `features/266-data-model-selectors.md` § Validating `raw|bin` at option-parse time
  (the one error form) and § Resolution at each call site.
- `features/432-metric-aggregate-naming-parity.md` D1 (a bare metric word on `-so`
  aliases its total) and D3 (duration keeps its bare CLI spellings; CSV headers take
  the prefix).
- `features/566-preserve-named-values-in-message.md` D6 (a built-in name on `-x`
  resolves before a key found in the line, with its list of accepted spellings) and
  `features/567-discard-named-values-from-message.md` D9 (the parsed fields `-d`
  names), D14 (built-in before line key on `-d`) and D15 (`-x` and `-d` accept the
  same names).
- `features/580-mask-uuid-and-ip-address.md` D5 (the `-m` option surface follows the
  `-x`/`-d` shape).
- `features/597-section-visibility.md` D24 (a user-defined metric's column is hidden
  by the name its column shows).
- `features/log-format-registry.md` D49 (a run-level format pin tops the precedence
  chain).

**Harnesses that read this surface**, which any convergence must keep green:
`validate-runtime-config`, `validate-help-content`, `validate-bucket-size-units`,
`validate-message-mask`, `validate-message-discard`, `validate-message-expose`,
`validate-udm-specs`, `validate-section-layout`, `validate-format-registry`,
`validate-format-detection`, `validate-explain`, `validate-statistics-demand`,
`validate-histogram-bin-counters`, `validate-profile`.

**Questions the findings discussion has to settle.** Each is a behaviour question,
not a refactoring one; the audit records the divergence and the discussion decides
which side of it is the contract.

- Should `-x time` and `-d time` mean the duration metric (the `time` alias of the
  #327 contract) or a `time=` key found in the line (566 D6 and 567 D14 as written)?
- Are `durationMs`/`durationMS` part of the shared metric vocabulary (so `-hm` and
  `-hg` accept them) or specific to the options that read keys from the line?
- Does the token-key fallback for user-defined metrics extend to `-hm`, `-hg` and
  `--hide`, or stay with `-x` and `-d`?
- Is `object` on `-d` but not `-x` a deliberate exception to 567 D15?
- Should `-so` resolve its bare metric words through `builtin_metric_name()`, given
  that it does not accept user-defined metric names today?
- `K` as 1000 in one byte table and 1024 in another is a correctness question
  before a duplication one: inside this audit's findings, or its own bug?
- Are help-row literals (unit lists, the `-so` vocabulary) in scope for "one
  resolution surface", or is their agreement with the tables a matter for
  `tests/validate-help-content.sh`?

### Item 2: unit and value formatting

**What it covers.** Every place a duration, byte count, count, unitless number,
percentage or timestamp is turned into text a person reads, and every `sprintf`,
`printf` or arithmetic that does so without calling the formatter that owns that
value class. Raw emission is out of scope where it is deliberate: numeric CSV cells
(which go through `format_csv_value()` for precision and must stay numeric), the
`-V` sections and the TIMING, MEMORY and MEMDIAG diagnostics, and the aggregate
export's exact values. The audit classifies every numeric `sprintf` as one or the
other and records the deliberate ones once, so the next reader does not re-audit
them.

**What scoping found.** Forty-one subs are named `format_*`; thirteen format a
value or timestamp, the rest belong to the log-format registry namespace. One owner
per value class exists:

| Value class | Owner | Wrappers and helpers |
|---|---|---|
| Duration | `format_time()` over `@time_unit_ladder` | `format_duration()` (latency cells, rounds to source resolution), `format_duration_total()` (totals; zero renders in the source unit) |
| Bytes | `format_bytes()` | private unit map, climbs by string length of the integer part |
| Count and unitless | `format_number()` | short/medium/long tiers (#501), `legend_category_total()` |
| Percentage | `format_percentage()` | `significant_decimals()` shared with `format_time()` |
| Coefficient of variation | `format_cv_display()` | none |
| Numeric CSV cell | `format_csv_value()` over `resolve_csv_column_family()` and `%csv_family_decimals` | none |
| Timestamp | `format_epoch_iso()`, `format_observation_timestamp()`, `format_bucket_timestamp()` | none |
| Metric-kind dispatch (time, bytes, number by built-in name or user-defined unit type) | `format_heatmap_value()`, partial | used by seven heatmap and histogram callers only |

Of about 115 numeric `sprintf`/`printf` sites outside the formatters, roughly 95 are
deliberate raw diagnostics, eight are in `write_index_file()`, and the rest restate
presentation formatting. Thirteen divergences were observed. The ones a user can see:

- A zero duration renders in the resolved source unit on the bar graph and totals
  (`format_duration_total()`, per #444 R17) but as `0ns` on heatmap and histogram
  labels, where `format_heatmap_value()` calls `format_time()` directly.
- Counts render with a space and two decimals in the timeline's proportional
  column, no space and one decimal on heatmap labels, and zero decimals on
  histogram ticks; a rate-type user-defined metric gets its unit suffix in the
  timeline and not on heatmap labels.
- Two private per-source-unit decimals tables exist, keyed by the same resolved
  duration unit with different values (display: ns 6, us 3; CSV: ns 9, us 6), both
  covering four of the ladder's tokens and defaulting to zero, contrary to #524 D1
  (no sub keeps a unit table of its own).
- Bytes have two unit maps and two climbing rules: `convert_bytes()` maps kB, MB, GB,
  TB as decimal and K, KB and the IEC units as binary; `format_bytes()` holds only
  the IEC units and promotes by digit count, so 1000 to 1023 bytes render as KiB.
- Trailing zeros are stripped by six separate idioms plus an unused `normalize()`
  sub; `format_number()` with two decimals keeps `1.50`, `format_cv_display()` never
  strips, where `docs/percentage-presentation.md` and #503 D13 state the rule every
  formatter follows.
- The unclassified-lines warning in `emit_classification_percentage_notices()`
  renders its percentage with an inline `sprintf` and its count raw, on a
  user-facing notice the percentage convention's exemption does not cover; sibling
  notices use `format_number()`, and two notices in the read loop print counts raw.
- The messages table and the thread-pool table print occurrences raw, three sites,
  where the legend uses `format_number()`.
- Milliseconds are rounded by `format_epoch_iso()` and truncated by
  `format_observation_timestamp()`; `write_index_file()` restates the ISO pattern
  inline and formats its means at fixed two decimals regardless of `-cp`.
- The metric-kind dispatch is written three times inside `format_heatmap_value()`,
  again in the timeline's display branch and again in its STATS CSV builder; the
  width-to-tier rule is written twice in `print_bar_graph()`.
- Three fit-to-width mechanisms: `format_duration()` sheds one fractional digit,
  `format_percentage()` loops decimals down, `format_cv_display()` fixes width by
  magnitude.

**Search angles the audit runs.**

1. *By formatter.* Every caller of each owner, wrapper and helper; for each call,
   the tier, decimals, space and width arguments passed, so that surfaces rendering
   the same class with different arguments are listed side by side.
2. *By idiom.* Every `sprintf`, `printf` and `%.Nf` in `ltl`; every `s/\.0+$//` and
   its variants; every `int(... + 0.5)`; every `strftime`. Each classified as
   deliberate raw (with the doc or rule that makes it so), presentation restatement,
   or internal.
3. *By surface.* Each rendered surface (timeline row, legend, messages table,
   thread-pool table, summary rows, notices, progress line, heatmap header and
   footer, histogram axes and legend, `--explain`) walked once for every number it
   prints and the path that number took.
4. *By unit table.* Every hash keyed by a unit spelling or a resolved unit
   (`%duration_display_decimals`, `%decimals_by_unit`, the byte maps, the SI map),
   against #524 D1.

**Evidence a finding carries.** The value class; site A and site B (sub plus
snippet) with the arguments or the inline expression each uses; the observed
divergence as the two strings a user sees for the same input value (the audit
produces them by calling the formatter and the inline path on a chosen value, not
by reading); the owning formatter it should route through; the contract and its
owner. Where the two sites are documented to differ (a CSV cell that must stay
numeric beside a `_nice` column), the finding records that and is closed as
deliberate.

**Locked decisions that bound convergence here.**

- `docs/percentage-presentation.md` (the convention; every presented percentage
  through `format_percentage()`; `-V` and machine-read diagnostics exempt; the
  histogram axis ticks listed as pending migration).
- `features/448-category-summary-share-and-bar.md` N1 (one shared percentage
  formatter) and its trailing-zero decision; `features/452-success-failure-percentage-columns.md`
  R3 (the same formatter for the outcome columns).
- `features/501-legend-category-total-shortening.md` D1 and D2 (`format_number()`
  takes a tier; three tiers).
- `features/524-bucket-size-unit.md` D1 (one time-unit ladder; no private unit
  tables) and its note that a zero duration renders `0ns` where `format_time()` is
  called directly.
- `features/444-access-log-format-family-and-user-surface.md` R17 / D16 (a zero
  total renders in the source unit).
- `features/503-yaml-aggregate-export.md` R12 (exact values in the export), D13
  (population duration through `format_time()` with significant digits; trailing
  zeros stripped as every formatter does) and D19 (total time and peak memory as
  the terminal prints them, same calls).
- `features/561-retained-durations-as-numbers.md` (`-cp full` passes
  `format_csv_value()` unchanged).
- `features/user-defined-metrics.md` (unit types display through `format_time()`,
  `format_bytes()`, `format_number()`); its base-1024 sentence is stale (§ 3, item 10).

**Harnesses that read this surface**: `validate-csv-output`,
`validate-duration-display`, `validate-bucket-size-units`,
`validate-classification-percentages`, `validate-aggregate-export`,
`validate-histogram-ticks`, `validate-statistics-demand`, `validate-progress-line`,
`validate-summary-contribution-bar`, `validate-category-names`. The rendered
surfaces are also frozen byte for byte by `validate-regression`; a convergence that
changes a rendered string is a behaviour change under this audit's first constraint
and must show that the copies already disagreed.

**Questions the findings discussion has to settle.**

- Is the zero-duration `0ns` on heatmap and histogram labels intended, or should
  `format_heatmap_value()` route durations through `format_duration_total()` as the
  timeline does?
- Are the two per-unit decimals tables meant to differ between display and CSV, and
  should both read the ladder (they cover ns, us, ms and s only)?
- Should bytes get one unit ladder shared by `convert_bytes()` and
  `format_bytes()`, and does `format_bytes()` keep its digit-count promotion (1000
  bytes as KiB)?
- Does the trailing-zero rule extend to `format_number()` with two decimals and to
  `format_cv_display()`'s fixed four-character cell?
- Are the raw occurrences in the messages and thread-pool tables, and the raw
  counts in two read-loop notices, deliberate, or should they follow
  `format_number()` as the legend and sibling notices do?
- Does `ltl-index.csv` honour `-cp` through `format_csv_value()`, or is the index
  outside the CSV precision contract?
- Timestamp rendering (rounding versus truncation of milliseconds): under this item
  or item 3?

### Item 3: timestamp parsing

**What it covers.** Every arm that turns a matched timestamp string into an epoch,
and then into a bucket key: the arms generated into the scan sub, the two CSV arms
in the read loop, the closure copies, the normalisation primitives spliced ahead of
a parse, the fractional-second handling, the date cache and the last-seen memo, and
the bucket arithmetic that follows. Off the per-line path, the other ISO parsers in
the file (the `-st`/`-et` bounds, the index file, the detection sample) are in scope
as copies of the same logic with different validity checks, not as hot-path sites.
The corrected picture of where the arms live is § 3, items 1 to 3.

**What scoping found.** Four live per-line arms and one shared cache:

| Arm | Where | Formats routed to it | Guard |
|---|---|---|---|
| ISO fixed-offset substr/timegm | generated by `format_entry_block_src()` into each scan block | every `iso_*` layout (with day and month offsets swapped for the day-first variant) | impossible month or day on the memo-miss branch, the line carried at the previous epoch and a probe signal raised |
| Apache month map | generated by `format_entry_block_src()` | the seven `apache_clf` entries | none; a token that is not a month name yields an undefined month |
| CSV ISO | `read_and_process_logs()`, calling the entry's time-parse closure | CSV input whose first data line is not numeric | the #328 shape check (skip and count the row); no month or day range check |
| CSV epoch | `read_and_process_logs()`, inline | CSV input whose first data line is numeric | none; decided from the first data line alone |

The date cache (`%timestamp_date_cache`, one midnight epoch per distinct date,
bounded at 100 entries) is shared by every ISO and Apache arm, inline and closure.
The last-seen memo (reuse the previous epoch when the string is unchanged) sits in
front of the scanned arms only; the CSV ISO arm goes straight to the cache and the
CSV epoch arm uses neither.

Divergences observed:

- The parse logic has two authorities. The source strings in
  `format_entry_block_src()` (inlined into every scanned format's block) and the
  closures in `compile_format_time_parser()` (built for every entry, called only by
  the CSV ISO arm) restate the same substr, timegm and month-map logic. A comment
  asserts they are the same; nothing checks it. The Apache closure is built for
  seven entries and never called.
- Guards differ per arm, as the table shows. Two gaps found by reading and not run:
  a CSV ISO value with month 13 passes the shape check and reaches `timegm`
  unguarded, which croaks; a non-numeric value after epoch detection reaches `int()`
  under warnings, giving a runtime warning and epoch zero.
- The fractional-second strip (`s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/` and its
  normalisation to milliseconds) is written in the generic frac source and again in
  the CSV ISO arm.
- CSV epoch detection (`/^\d+(\.\d+)?$/` on the timestamp field) is written twice in
  the read loop: on the confirmed-CSV data-line path and on the header-validation
  path.
- The pre-parse normalisation primitives (`t_to_space`, `comma_to_dot`,
  `chop_tz_offset`, `chop_tz_colon_offset`) are spliced into generated blocks by
  the spec's declaration; the CSV ISO arm gets none of them, so a timezone suffix
  on a CSV timestamp is dropped by the fixed offsets without comment.
- Four ISO-date parsers apply four validity policies: the inline arm (month and day
  range, no eval), the closure (none), `parse_iso_date_to_epoch()` (regex plus
  eval), `format_sample_probes()` (regex, range checks and eval, under both
  month-first and day-first readings).
- The epoch-to-bucket arithmetic (`int($epoch / $bucket_size) * $bucket_size`, with
  a millisecond branch) is in the read loop and again in
  `initialize_empty_time_windows()`, including the millisecond bucket size
  recomputed in both.
- The bucket size in milliseconds is recomputed per included line inside the
  millisecond branch, from a value fixed for the run (also an item 8 site).

**Search angles the audit runs.**

1. *By layout.* From `format_registry_specs()`, every declared time layout, frac
   contract and transform list; for each, the generated source it selects in
   `format_entry_block_src()` and the closure it selects in
   `compile_format_time_parser()`, diffed side by side.
2. *By primitive.* Every `timegm`, `strptime`, `gmtime`, `%format_month_map` read,
   `substr($timestamp_str`, and every regex on a timestamp variable, wherever it sits.
3. *By variable.* Every read and write of `$timestamp`, `$timestamp_str`,
   `$fractional_ms`, `$timestamp_epoch`, `$bucket`, `$bucket_epoch`, the memo pair
   and the cache, in and out of the loop, so that the single join point
   (`$timestamp_epoch = $timestamp + $fractional_ms / 1000`) and everything upstream
   of it are listed.
4. *By failure.* For each arm, the input that is well-formed for the arm's entry
   condition and invalid for its parse (month 13, day 32, a non-month token, a
   non-numeric epoch field, a timezone suffix), and what the arm does with it: this
   is where the audit runs `ltl` on minimal fixtures under `-V` to confirm or refute
   the two by-reading gaps, captured once to the scratchpad.

**Evidence a finding carries.** The arm or primitive; site A and site B (sub plus
snippet; for generated code, the source string in `format_entry_block_src()` is the
site, cited by the string's own text); the input class each accepts; the observed
divergence as what each does with the same input (confirmed by a run where the gap
was found by reading); the target: one source of truth for the parse logic, and the
same guard policy on every arm that can receive the same input; the contract and its
owner. The audit does not propose which arm's policy wins; that is a findings
decision, because the inline arm's guard is a locked hot-path design (below).

**Locked decisions that bound convergence here.**

- `features/log-format-registry.md` D31 (the time contract is compiled to per-layout
  parse closures, sharing the date cache), D60 (zero code generation at startup;
  scan-sub generation happens at election, promotion, occupant swap or pin), and
  the implementation notes N3 (timestamp cache invalidation) and N10 (the day-first
  ISO layout).
- `features/58-format-registry-staged-detection.md` A6 (the registry must preserve
  the exact semantics of the existing timestamp fast path) and P8 (the parity
  semantics of the timestamp cache; the closures achieve exact parity; the
  per-second cache once grew unbounded on sparse streams, which is why the cache is
  bounded and keyed by date).
- `features/log-format-registry.md` § #384 prototype findings, F3 (the probe sits in
  the cache-miss branch behind a timegm guard, so the guard costs nothing on a
  cache hit): the inline arm's guard placement is a measured hot-path decision, not
  a convenience.
- `features/user-defined-metrics.md` § CSV Columnar Input (the skip-and-warn
  contract for CSV timestamps that are neither epoch nor ISO, one warning per file).

**Harnesses that read this surface**: `validate-csv-input`, `validate-filter-summary`,
`validate-format-detection`, and `validate-format-registry` for the scan sub's
compile and cache counters. Every format's sample lines are also parsed on every run
by the registry's self-validation, so a change to a generated arm that alters an
epoch fails at startup.

**Questions the findings discussion has to settle.**

- Is the inline-versus-closure duplication in scope for convergence, given that D31
  and P8 locked the inline form for hot-path cost? One shape that keeps both is to
  generate the closure from the same source string the block uses; the audit records
  the option, not a decision.
- The two by-reading gaps (CSV month 13 reaching `timegm`; a non-numeric field after
  epoch detection): once confirmed by a run, are they findings inside this audit or
  bugs of their own?
- Should the CSV ISO arm receive the same normalisation primitives and the same
  month/day guard as the scanned ISO arms, or is CSV input a different contract?
- Are the off-loop ISO parsers (`-st`/`-et` bounds, the index file, the detection
  sample) to converge on one parser with one validity policy, or are their
  policies deliberately different?
- Does the issue body's wording ("per-match-type parse arms in
  `read_and_process_logs()`", "timestamp_cache") get trued up on the issue, per
  § 3?

### Item 4: aggregation and statistics gating

**What it covers.** Every site that derives a mean, rate, ratio, percentage,
variance or moment from an accumulator pair (a sum and its observation count), per
bucket, per message, per category, per file and per run; the gate each site puts in
front of the division; and the accumulators themselves, checked against the rule in
CLAUDE.md § Before writing or changing code: every accumulator tracks an observation
count, and derived output is gated on `count > 0`, never on `defined` over a
zero-initialised field.

**What scoping found.** Thirty-four or more derivation sites across a dozen subs,
and no shared helper: no sub in `ltl` derives a mean or a ratio for a caller. The
only shared derivation surfaces are `calculate_statistics()` (raw data model) and
`calculate_statistics_bin()` (bin data model) for the duration family, and those two
are parallel copies of the same mean, variance, coefficient-of-variation and moment
formulas. Every bytes, count and user-defined-metric mean is an inline ternary at
its site. The copies:

| Derivation | Copies | Where |
|---|---|---|
| Count mean | 4 | per bucket twice in `calculate_all_statistics()`, per message twice (sort pre-pass, group calculation) |
| Bytes mean | 4 | per bucket twice, the sort pre-pass, `print_message_summary()` |
| User-defined numeric mean | 3 | per bucket (stored, then recomputed four lines later for the display value), per message |
| Duration mean, variance, cv, moments | 2 | `calculate_statistics()`, `calculate_statistics_bin()` |
| Welford running mean | 3 | per message and per bucket in the read loop under the bin model, `merge_bin_state()` |
| Impact mean | 2 | the read loop, `group_similar_messages()` |
| Per-file index means | 6 | `write_index_file()`, three plus their selected-lines twins |
| Unclassified percentage | 2 | `emit_format_detection_verbose()`, `emit_classification_percentage_notices()`, from different inputs |

Divergences observed:

- **Divisor.** The duration mean divides by the duration observation count in both
  statistics subs, but the impact mean divides by all matched lines (occurrences) in
  both its copies. That is the defect shape #432 F1 found and fixed for the bytes
  mean (dividing by occurrences when not every line carries a value), still present
  for duration. No feature doc defines impact's divisor.
- **Gate shape.** The per-message count mean has three differently shaped gates:
  truthiness of the count in the sort pre-pass; `defined` sum and count and
  `count > 0` wrapped in a postfix `if defined count` in the group calculation
  (leaving the field untouched when the count is absent); `defined` sum and count
  and `count > 0` per bucket, in two identical copies. The per-bucket user-defined
  mean has no `defined`-sum guard, where the per-message copy gained one from the
  #326 fix; the per-bucket copy is safe only because counting aggregations exit the
  loop earlier.
- **Precision.** The per-message bytes mean is kept at full precision for sorting
  (a comment says rounding at rank time would manufacture ties) and rounded to an
  integer in `print_message_summary()` for both the table and the MESSAGES CSV; the
  per-bucket bytes mean in the STATS CSV is fractional. So the two CSVs disagree on
  the same statistic's precision.
- **Impact gate.** The read-loop copy gates on the current line's `duration > 0`;
  the consolidation copy gates on `defined total_duration && occurrences > 0 &&
  total_duration > 0`. Same quantity, different guards.
- **Raw versus bin.** `calculate_statistics()` gates on `occurrences > 0` then a
  non-empty retained-durations array; `calculate_statistics_bin()` on
  `occurrences // 0 > 0` then `duration_count > 0`. The formulas between them are
  restated, not shared.
- **Diagnostics.** The consolidation reduction percentage divides by
  `($keys_seen || 1)`, substituting a divisor for a zero count instead of gating.

Sites that violate the CLAUDE.md rule today:

- The impact mean, both copies: `defined` over a zero-initialised total, divided by
  occurrences rather than a duration count.
- The STATS CSV `duration_nice` and `bytes_nice` cells: `defined` over
  zero-initialised totals, so a bucket whose lines carried no duration writes a
  formatted zero rather than an empty cell.
- The timeline's latency-cell block: an `||` whose first disjunct is `defined` over
  the zero-initialised bytes total, so it is always true.
- The column-scaling maxima and the scaled keys in `normalize_data_for_output()`
  (with a highlight twin): `defined` over the same totals; harmless for a maximum,
  the shape nonetheless.
- The per-message bytes total is summed `if defined` over a zero-initialised field;
  `print_message_summary()` compensates by gating on `bytes_occurrences` (from #432).
- Two accumulators carry no unconditional observation count: the raw-model
  duration total (the count exists only in the bin model, as `duration_count`; the
  raw model has the length of the retained array), and the bytes total, whose
  `bytes_occurrences` is incremented only under the #516 demand flag while
  `total_bytes` accumulates regardless.

**Search angles the audit runs.**

1. *By operator.* Every `/` in `ltl` whose right operand is a count, occurrence,
   `$n`, denominator or `_occurrences` field, and every `* 100`; each classified by
   the quantity derived and the store it reads.
2. *By field pair.* For every accumulator field (`total_*`, `*_sum`,
   `*_occurrences`, `*_count`, `duration_count`, `successes`, `failures`,
   `classified`, `included`): where it is initialised (and to what), where it is
   incremented, under which gate, and where it is read.
3. *By gate.* Every `defined $x->{total_...}` and `defined $x->{...sum}` in a
   condition; every `if defined` postfix on an assignment of a derived value;
   every `|| 1` or `// 1` divisor.
4. *By surface pair.* For each statistic that reaches two surfaces (terminal table
   and MESSAGES CSV; STATS CSV and aggregate export; `-V` and a notice), the two
   derivations side by side, with gate, divisor and precision.

**Evidence a finding carries.** The derived quantity; site A and site B (sub plus
snippet) with each one's gate, divisor and precision; the observed divergence as the
value each produces from one accumulator state (chosen so the divergence shows:
lines without the metric, a zero count, a single observation); which of the two the
documented contract supports; the target (a named helper for mean and ratio
derivation with the gate built in, or a single statistics sub for both data models);
the contract and its owner. A rule violation with no observable consequence today
(a maximum over a zero-initialised total) is recorded as such and ranked last.

**Locked decisions that bound convergence here.**

- `features/432-metric-aggregate-naming-parity.md` D5 (bytes gains the full basic
  family on both CSV surfaces) and its F1 finding as corrected in § 3, item 10 (the
  per-message bytes mean divides by `bytes_occurrences`).
- `features/516-bytes-aggregate-demand-gate.md` D1 (one store-level demand flag for
  bytes aggregation, resolved once at option settlement) and D2 (downstream reads
  are absence-tolerant: a consumer of a bytes aggregate handles the field never
  having been incremented).
- `features/517-message-outcomes-demand-gate.md` D1 (the same shape for
  per-message outcomes).
- `features/426-per-message-statistics-store.md` § Findings (the #330 gate: a
  zero-initialised `total_duration` must not read as observed; the per-message
  duration-observed test is `duration_count > 0` in the bin model and the total
  `> 0` in the raw model).
- `features/duration-statistics.md` § Stores and primitives and § Demand model (which
  statistic groups each store computes, on demand).
- `features/user-defined-metrics.md` § Per-Message Storage and § Known Issues
  (the #326 fix: counting aggregations are skipped in the per-message mean
  derivation, and the sum is guarded).
- `features/312-numeric-criteria-highlight-selection.md` and the highlight twins:
  every per-bucket derivation has a `-HL` copy that must converge with it, not
  separately.

**Harnesses that read this surface**: `validate-statistics` (the drift engine and the
NumPy/SciPy oracle on every emitted statistic), `validate-statistics-demand`,
`validate-aggregate-export`, `validate-udm-counting`,
`validate-classification-percentages`, `validate-classification-states`,
`validate-csv-output`, `validate-bucket-size-units`. A convergence that changes a
derived value (the impact divisor, the bytes-mean precision) moves a statistic the
drift engine compares, so it is a behaviour change under the first constraint and
must show which copy the contract supports.

**Questions the findings discussion has to settle.**

- Is the impact mean intentionally weighted by all matched lines, or is it the
  #432 F1 divisor defect repeated for duration? Nothing on record defines it.
- Should a STATS CSV bucket with lines but no duration or bytes observations write
  an empty `duration_nice`/`bytes_nice` cell rather than a formatted zero?
- Is the MESSAGES CSV's integer-rounded bytes mean against the STATS CSV's
  fractional one a sanctioned difference under #432 D5?
- Does the CLAUDE.md rule require an unconditional observation count for the
  raw-model duration total and for bytes when demand is off, or is demand-gated
  presence, with absence-tolerant reads (#516 D2), the intended shape?
- Should the raw and bin duration statistics converge on one sub taking the store
  shape as a parameter, given that the two are the only shared derivation surfaces
  and restate the same formulas?

### Item 5: filter and highlight range checks

**What it covers.** The twelve bound options (six filters: `-dmin`/`-dmax`,
`-bmin`/`-bmax`, `-cmin`/`-cmax`; six highlights: `-hdmin`/`-hdmax`,
`-hbmin`/`-hbmax`, `-hcmin`/`-hcmax`), every site that compares a per-line value
against one, the min-against-max inverted-range check, and every place the set of
bound variables is enumerated by hand (activation, index signature, `-V` reporting,
provenance, the aggregate export, help).

**What scoping found.** Fourteen sites across nine subs and no shared comparison
sub. Value-against-bound comparisons exist only in `read_and_process_logs()`: three
per-metric filter blocks (an undefined-metric guard plus two comparisons each,
dropping on the complement, `< min` or `> max`, with an early `next`) and one
six-clause highlight predicate (testing the positive form, `>= min` and `<= max`)
inside the tag point behind `$numeric_highlight_active`. The inverted-range check in
`adapt_to_command_line_options()` is the only table-driven site: a twelve-row table
pairing min, max and both option names per metric, warning when both are defined
and min exceeds max. All comparison sites are inclusive at both ends. No user
threshold exists for user-defined metrics; their `udm_*_min`/`_max` fields are
aggregated statistics.

Divergences observed:

- One closed interval coded two ways in one sub (complement for the filter,
  positive for the highlight), equivalent today and kept equivalent by hand across
  six filter comparisons, three guards and six highlight clauses.
- Missing-metric accounting differs by family: the filter counts the drop
  (`$numeric_filter_no_metric{$metric}++`, `$excluded_numeric++`, and a notice after
  the run from #321); the highlight clause fails silently. By design under #312's
  "undefined metric never satisfies" and #321's resolution (visibility for the
  filter only), so a shared predicate would have to keep the asymmetry.
- The exclusion count has three consumers gated three ways: the aggregate export
  emits it only when a filter bound is defined; the `-V` filter summary prints it
  unconditionally; `lines_excluded_total()` adds it unconditionally.
- The bound-variable set is enumerated by hand at eight places with three different
  subsets: all twelve in `GetOptions`, the provenance map, the `-V` runtime-config
  registry and the inverted-range table; the six filters in `has_active_filters()`,
  `serialize_filters()` and the aggregate export; the six highlights in the
  activation test. Only the inverted-range table pairs min, max and option name.
- Help wording differs across the filter rows only in phrasing (`-dmin`/`-dmax`
  spell out "entries exactly at N are kept"; the others say "inclusive"), mirrored
  in `docs/usage.md`.
- The `=i` option type accepts negative integers with no further validation on any
  of the twelve.

**Search angles the audit runs.**

1. *By variable.* Every occurrence of `(filter|highlight)_(duration|bytes|count)_(min|max)`;
   the scoping verifier found no site beyond the fourteen by this angle, so the
   audit's job is to classify, not to find.
2. *By table.* The inverted-range table's twelve rows against every other
   enumeration, to establish whether one declaration (metric, filter min, filter
   max, highlight min, highlight max, option names) could feed all eight.
3. *By example text.* Every `--help` and `--explain` example and every `docs/usage.md`
   row that names one of the twelve, so a surface change knows its documentation
   sites.

**Evidence a finding carries.** The bound family; site A and site B (sub plus
snippet) with the comparison form and the guard; the observed divergence, or
"equivalent by hand"; the target (one declaration of the twelve bounds read by every
enumeration; one comparison surface if, and only if, it costs nothing per line when
no bound is given); the locked decision that governs it.

**Locked decisions that bound convergence here.** The #312 decisions table has no
Dxx labels and is cited by row name; #455 uses D1 to D8.

- `features/312-numeric-criteria-highlight-selection.md` § Decisions: *Within-metric
  semantics* (inclusive band, no outlier mode); *Across metrics* (AND); *Regex
  highlight × numeric* (AND, one tag point); *Undefined metric* (never satisfies);
  *Boundary normalisation* (all twelve are closed intervals, each bound applied only
  when given); *Inverted range* (validated once in option settlement, for all twelve;
  equal bounds silent); *Option surface* (highlight bounds stay out of the index
  signature).
- `features/312-numeric-criteria-highlight-selection.md` § Design, Core mechanism:
  a single tag point, and the hot-loop discipline that the numeric predicate is
  evaluated only when `$numeric_highlight_active`, so a run with no numeric
  highlight pays one falsy scalar read. This is the constraint on any shared
  comparison sub: a per-line call where there was a scalar test is a hot-path
  change with its own before/after.
- `features/455-success-failure-filter-highlight-criteria.md` D6 (criterion
  semantics compose by AND at the tag point) and D7 (filters join the filter
  surfaces, highlights do not).
- `features/478-highlight-decision-read-back.md` D1 to D7 (the tag point sets one
  per-line boolean; the `-HL` carrier is not replaced).

**Harnesses that read this surface**: `validate-numeric-criteria-notices` (the
inverted-range and missing-metric notices), `validate-runtime-config`,
`validate-index-read-back` (the filter signature), `validate-filter-summary`,
`validate-regression`. Four more pass these options as invocation settings without
asserting on them.

**Questions the findings discussion has to settle.**

- Should the `-V` filter summary's exclusion line and the aggregate export's
  exclusion key share one gating rule?
- Is negative-integer acceptance on the twelve `=i` options in scope for a
  range-check audit?
- Does one declaration of the bound set (feeding activation, index signature, `-V`,
  provenance, export and the inverted-range table) count as convergence under the
  first constraint, given that the comparison sites themselves stay inline for
  the hot-loop reason above?

### Item 6: CSV emission column lists

**What it covers.** Where the MESSAGES CSV, the STATS CSV, the run index CSV and
the YAML aggregate export each declare their columns, where each emits a header and
where each emits a row; the precision-family table that formats the cells; and the
rules TSVs under `tests/csv-output/rules/` that the harness treats as the
specification of the columns.

**What scoping found.** No single declaration covers either CSV.

| File | Header | Row | Shared parts |
|---|---|---|---|
| MESSAGES | one literal `qw` list of 41 names in `pipeline_render()`, plus `udm_csv_columns()` | a positional list of 41 values in `print_message_summary()`, 37 of them tagging the column name into `format_csv_value()`, plus `udm_csv_columns()` | `udm_csv_columns()` only; the duration names are a hand copy, not `@duration_family_stats` |
| STATS | `@output_columns`, built in `normalize_data_for_output()` by walking `@populated_graph_columns`, renamed (rate columns) and written in `pipeline_render()` | `print_bar_graph()` reads `@output_columns` for the category segment up to `occurrences`, then rebuilds everything after it by a second walk of `@populated_graph_columns` in a parallel if/elsif chain | `@duration_family_stats`, `udm_csv_columns()`, the two `stats_csv_*_columns_active()` gates |
| Aggregate export (#503) | its own walk of `@populated_graph_columns` in STATS order | same | `@duration_family_stats`, `udm_csv_columns()`, the two gates; its own literal bytes and count lists |
| Run index | `@index_columns` in `write_index_file()` | positional lists across four emit calls | `@index_columns` declared a second time, identical, in `read_index_file()` |

The precision-family table `%csv_column_family` is a third hand-kept list of the
fixed column names, with `resolve_csv_column_family()` handling dynamic columns by
pattern. The bytes family is written as a literal four times, the count family four
times, the user-defined fallback list three times plus once inside
`udm_csv_columns()`. Outside `ltl`, the column names are kept a fourth time in
`tests/csv-output/rules/messages-columns.tsv` and `stats-columns.tsv`.

Divergences observed:

- The precision-family labels disagree between `ltl` and the rules TSVs today:
  `duration_std_dev` and `duration_cv` are `shape` in `ltl` and `dispersion` in both
  TSVs; `impact` is `shape` in `ltl` and `duration` in the messages TSV. `ltl` has no
  `dispersion` family at all, and the comment on the table says it mirrors the TSVs.
  Whether emitted decimals differ needs a `-o` run; the scoping pass did not run it.
- The STATS row loop matches `/^(time|duration)$/i` where the header loop matches
  `/^(duration|bytes)$/`; no `time` key exists in the metric list, so the arm is
  dead, and if it ever matched the row would carry one more field than the header.
- The STATS header spells the rate columns with their unit suffix and the row
  formats the value under the bare name; both resolve to the same family, so the
  output agrees, by two different spellings.
- The STATS row is padded with empty fields to the header width before it is
  written, so the harness's per-row field-count check cannot catch a short row.
- The MESSAGES header and row agree today only because two hand-written lists of
  41 were written to match; the per-column locals pulled from the message store are
  a third per-column spelling on that side.

**Search angles the audit runs.**

1. *By emitter.* Every `$csv->print` and every `push @output_columns`, `push @row`,
   `push @csv_data`; for each, the list it emits and where that list came from.
2. *By family.* Every `qw(` containing `occurrences`, `min`, `mean`, `max` or `sum`,
   and every `"${key}_..."` construction, classified by CSV and by header or row.
3. *By rules TSV.* Each rules-TSV column against `ltl`'s header list and against
   `%csv_column_family`, three ways: present in both, present in one, family
   disagreeing. This is a mechanical diff the audit records in full.
4. *By harness.* What `tests/csv-output/validate-csv-output.pl` checks (structure,
   order, per-row field count, type and range) and what it cannot catch (a padded
   short row; a row value under the wrong header of the same type).

**Evidence a finding carries.** The CSV and the column or family; site A (header)
and site B (row), sub plus snippet; the third and fourth copies where they exist;
the observed divergence as what the file would contain (a family label, a field
count, a spelling); the target (one declaration per CSV, holding name, family and
gate, from which header, row, precision lookup and the aggregate export all read);
the owner. The rules TSVs are recorded as a copy but not as a target: they are
hand-maintained by design so that the harness checks the tool against a
specification the tool did not generate.

**Locked decisions that bound convergence here.**

- `features/column-layout-refactor.md` § Goals (one source of truth for display
  columns) and § Required Separation (data model versus rendering; CSV and summary
  outputs stay out of `@column_layout`). A single CSV declaration is a new
  declaration, not the layout (§ 3, item 8).
- `features/432-metric-aggregate-naming-parity.md` D3 (CSV headers take the
  `duration_` prefix), D5 (bytes gains the full basic family on both CSVs), D7 (the
  run index follows the same naming convention), D8 (the consumers are `-so` and the
  two CSV files; `@output_columns` drives the CSV only, the terminal render uses the
  layout).
- `features/224-validate-statistics-test-harness.md` Decision 5 (column-set scope is
  all or nothing: every emitted column has a rule or the harness fails) and
  Decision 10 (the shared CSV cache between harnesses, which fixes the run order of
  the completion gate).
- `features/503-yaml-aggregate-export.md` § `-V aggregate-export` section contract
  (locked as built): the export's series follow the STATS order.
- `tests/csv-output/README.md` § Rules TSV schema and § Updating rules when columns
  change: `ltl` and the rules TSV change in the same commit.

**Harnesses that read this surface**: `validate-csv-output`, `validate-statistics`
(the drift engine rolls up by the TSV family), `validate-category-names`,
`validate-aggregate-export`.

**Questions the findings discussion has to settle.**

- Does the family-label disagreement change any emitted decimals? Confirmed by a
  `-o` run inside the audit before the finding is ranked.
- Does the STATS row padding stay? It exists so a short row never breaks a
  consumer; it also blinds the harness to a short row.
- Is the `-so` operand vocabulary (item 1) a further copy of these column lists,
  as #432 D8 names it a consumer of the same `bytes_*` names?

### Item 7: message-key construction

**What it covers.** Every site that assembles the message key (`$log_key`) or the
consolidation's canonical key, the cut length applied to it, the field cuts applied
before assembly (thread, object), the places the key's shape is parsed back to
recover a field, and the two spellings of the 350-character cap.

**What scoping found.** Five copies of the cut ternary
(`($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 :
$max_log_message_length`): four in `read_and_process_logs()`, one per key variant
(level, thread and object; level and object; level and thread; level only), and one
in `group_similar_messages()` re-cutting a cluster's canonical form. The literal
`350` appears at exactly six lines in `ltl`: those five and the declaration of
`$consolidation_message_length_cap`, which nine consolidation re-cut sites read.
Nothing ties the two spellings together. `$max_log_message_length` has one
declaration, one assignment (the terminal width, in `adapt_to_terminal_settings()`)
and six readers (the five key sites and the `-V benchmark-data` CONFIG line).

Divergences observed:

- The fifth ternary copy, in `group_similar_messages()`, can only ever pick 350: the
  sub is called only when grouping is on. Its terminal-width branch is dead.
- The inline consolidation input re-cuts the already-cut key at the named cap right
  after it was cut to 350 under the same condition, so the second cut is a no-op.
- `-V benchmark-data` reports `max_log_message_length` as the terminal width, but
  under `-o` or `-g` the keys were cut at 350, so the reported value is not the
  length the run used. Benchmark TSVs under `tests/baseline/results/` carry it.
- The grouping key is derived two ways: the inline path takes the level directly,
  and `group_similar_messages()` parses it back from the key's first bracket at
  four sites. They agree only because every key variant puts the level first.
- The field cuts are written three ways: thread by a literal 20 (first characters),
  object by a local `$max_object_length = 25` re-declared per retained message
  (last characters), and the key by the ternary. None is a named global.
- `features/fuzzy-message-consolidation.md` IQ-01 and IQ-02 describe a grouping key
  and a length measure the code does not use (§ 3, item 10).

**Search angles the audit runs.**

1. *By variable.* Every write and read of `$log_key`, `$canonical_log_key`,
   `$max_log_message_length`, `$consolidation_message_length_cap`, `$truncated_thread`,
   `$truncated_object`, and every composite key built from `$log_key`
   (`"$category\x1f$log_key"`).
2. *By idiom.* Every `substr(` whose first argument is a key, a message, a thread
   name or an object, and every regex that reads a bracketed prefix off a key.
3. *By consumer.* Every harness and every reference baseline that freezes the key's
   shape, so a change to the assembly knows what it re-blesses: three harnesses
   assert exact bracketed keys from the MESSAGES CSV, three freeze it indirectly
   (control characters through the render, grouping through the cluster-membership
   records, regression through 74 terminal-width baselines).

**Evidence a finding carries.** Site A and site B (sub plus snippet); the cut or
derivation each applies; the observed divergence, or "identical, tied by nothing";
the target (one key-assembly sub taking the fields and returning the key, with the
cut length resolved once per run; one named cap; the grouping key carried, not
parsed back); the contract and its owner.

**Locked decisions that bound convergence here.**

- `features/fuzzy-message-consolidation.md` DD-06 (the 350-character cap when
  grouping is on, and the warning that a cut inside a UUID breaks consolidation) and
  the resolved IQ-02 (350 under grouping, terminal width otherwise).
- `features/150-final-pass-scalability.md` (the move from a terminal-width cut to
  350 under grouping, and why).
- `features/447-message-control-character-normalisation.md` D2 (normalisation
  happens once, at parse time, before key construction) and D5 (gated on a matched
  line); § Affected surfaces lists every consumer of the key, and reserves the unit
  separator as the category boundary.
- `features/580-mask-uuid-and-ip-address.md` (masking runs before the cut, so the
  cut keeps different text than it would on the unmasked line).
- `features/528-record-lexical-retained-representation.md` was checked and holds no
  contract on the key's shape.

**Harnesses that read this surface**: `validate-message-expose`,
`validate-message-mask`, `validate-message-discard`,
`validate-message-control-characters`, `validate-message-grouping`,
`validate-regression`, `validate-csv-output` (substring match on the message column
only), `validate-histogram-bin-counters` (the keying label only).

**Questions the findings discussion has to settle.**

- Should the key cut and the consolidation cap be one named value? They are equal
  by coincidence of spelling today, and DD-06 ties consolidation correctness to the
  key cut.
- Should `-V benchmark-data` report the cut the run used? Changing it moves a value
  the benchmark TSVs compare.
- Are the stale IQ-01 and IQ-02 texts trued up here or under their own issue?
- Does item 7 cover the display-only second cut of the key to the column width in
  `print_message_summary()` and `print_threadpool_summary()`, or key construction only?

### Item 8: the structure of the per-line loop

**What it covers.** Not a duplication cluster: the per-line loop of
`read_and_process_logs()` itself, and the cost of what it carries per line that is
constant for the run. The item has three parts, in the architect's order: an
inventory, a measurement, and an assessment of two remedies against that
measurement. It produces no code change. Any remedy it favours becomes its own
issue with its own interleaved before/after.

**Delivery.** This item is drop 2 of the issue (§ Status). Its measurement runs in
the background while drop 1's findings are triaged, and its record lands on the
issue branch when the analysis is written.

**The measured finding it starts from** (`tests/profile/results/567-access-log-regression/`).
Ten interleaved rounds of `single-day-access-log-standard` (a 148 MB access log,
50 runs) across the four #567 commits: base median 8.985 s, head 9.130 s, +1.61 %,
accumulating across the commits rather than stepping at one. A Thingworx
application log measured 0 % over the same pair. NYTProf on 100k-line samples put the
whole increase in the loop sub's exclusive time (1.659 s to 1.694 s, +2.1 %, on the
access log; 1.106 s to 1.109 s on the application log), with both binaries
executing the same 114 statements 100,000 times each: nothing #567 added executed.
The access-log path spends 1.66 s of its 2.63 s total exclusive time inside the loop
sub, the application-log path 1.11 s of 1.70 s, which is why one family pays and the
other does not.

**Part 1: inventory of what the loop carries per line.** The scoping pass counted
about 107 test sites of run-constant values in the loop body (`while (1) {` to its
closing brace, 1,343 lines, 830 code), by feature group:

| Group | Run-constant tests per line | Notes |
|---|---|---|
| Progress and diagnostics | 2 | `$show_memory_debug`; `$disable_progress` behind a modulo |
| User-defined metrics | 2 gates plus 3 loops | three `foreach` over `@udm_configs` with no outer gate (empty list, zero iterations, but the loop setup runs) |
| Discard, expose, mask | 5 gates plus 5 inner lookups | the #567 gates |
| Metric omission | 12 | `$omit_count` 3, `$omit_bytes` 4, `$omit_durations` 5 |
| Duration unit override | 2 | |
| Time window and profile | 3 plus one always-run range compare | the absolute range compare runs even with defaults |
| Filters | 6 outer plus 10 inner | pattern, outcome and the three numeric families |
| Highlight | 1 compound gate with 12 inner terms | plus about 20 reads of the per-line boolean below it |
| Bucket precision | 1 | and the millisecond bucket size recomputed per included line from a run constant |
| Message capture and consolidation | 16 | the key-length expression written four times; `$message_stats_capture_mode eq 'bin'` five times as a string compare |
| Bucket statistics | 8 | three string compares on the capture mode |
| Heatmap | 1 outer plus 5 inner | three string compares on the metric name |
| Histogram | 1 plus 1 plus 8 metric-selection tests plus 2 loops | |
| Thread pool | 1 compound of 3 terms | |
| Sessions, users | 0 | captured whenever the line carries one; the hide options are never consulted |
| Index-file tracking | 0 | two unconditional blocks; runs under `-ni` too |

Only two run options are baked into the generated scan sub today (the query-string
strip and the exposed metric set), and one is folded into a per-entry constant at
build time. Everything else is tested per line. The inventory the audit records
lists every site (sub plus snippet), its group, its frequency class (every line
read; every matched line; every included line; every retained message; every line
carrying a metric), and its form (boolean scalar, string compare, hash lookup, list
truth, `defined`), because the measurement in part 2 is designed around those
classes.

**Part 2: the cost curve.** The #567 method, applied to probe builds rather than to
commits: interleaved rounds, both binaries, same host, same hour, median of ten per
candidate, on `single-day-access-log-standard` with `single-day-application-log-standard`
as the control that should move less. Probes are behaviour-neutral edits of one
base binary, each measured against that base:

1. *Synthetic gate series.* N always-false boolean scalar tests inserted at one
   fixed point on the every-included-line path, for N in 0, 10, 20, 40. The slope is
   the per-gate cost; N = 40 exists so the slope is resolvable even if a single gate
   is inside the noise. This answers the architect's second question (does another
   gate cost another ~0.4 %?) as a line, not a reading.
2. *Form series.* The same N as string compares (`eq 'bin'`) and as hash lookups,
   to establish whether the loop's string-compare gates are a separate cost class.
3. *Hoist probe.* The existing string-compare gates replaced by booleans resolved
   once before the loop, and the three unguarded user-defined-metric loops placed
   behind one gate: behaviour-neutral by construction, and the smallest form of
   remedy (b) below, measured directly.
4. *Statement-count check.* NYTProf on the 100k-line samples
   (`tests/profile/run-profile.sh`) for the base and for the N = 40 probe, to confirm
   the probe added exactly N statements per line and nothing else, as the #567
   analysis confirmed its 114.

Every run passes `--disable-progress` and bare `-V`, captured once to the scratchpad.
Probe sources and the interleaving driver live under
`prototype/342-read-loop-cost-curve/`; the record follows the #567 shape,
`hypothesis.md` written before the first run and `analysis.md` after, under
`tests/profile/results/342-read-loop-cost-curve/`; the audit report cites the
numbers. Benchmark TSVs are labelled `342-probe-*` and deleted when the record is
written; the `full`, `xl` and `all` tiers are not used.

**Part 3: ceiling and the two remedies.** The per-gate slope times the inventory
count is the ceiling on what any remedy can recover from the gates themselves; the
hoist probe measures what the cheapest remedy actually recovers. Both remedies are
then assessed against that ceiling, on paper, without implementing either:

- *(a) Generate the per-line path per run*, as `compile_format_scan_sub()` builds the
  scan sub from source strings and caches it by scan-order signature. The loop body
  would be assembled from blocks selected by the run's options and compiled once,
  so a run naming nothing carries none of the option-shaped branches. Assessed on:
  the seam between the scan sub (already generated) and the body; how many of the
  107 sites the option signature could remove; the validation analogue (the registry
  self-validates every generated scan sub against sample lines at startup; a
  generated loop body needs an equivalent); debuggability of a 1,300-line eval; and
  the cost of the change against the measured ceiling.
- *(b) Hoist per-line option handling out of the loop body*: booleans for string
  compares, one gate per feature block, demand flags for session, user and index
  tracking, the run-constant recomputations (millisecond bucket size, the key
  length, the object cut) moved before the loop. Assessed on the same ceiling, with
  the hoist probe's measurement as its floor.

**Part 4: generalisation.** The prediction that the ScriptLog family (+6.11 % in the
same release capture) behaves like access logs because it spends proportionally more
time in the loop body is checked with one interleaved pair on a ScriptLog selection
from `docs/test-logs.md`, base against the N = 40 probe. Recorded as confirmed or
refuted.

**Divergences observed inside the loop**, which belong to items 1 to 7 and are
listed there, plus three the scoping pass found that belong here: the CSV data-line
arm and the lazy-detection confirm arm restate the same sequence; the per-file
detection record's initialiser is written twice with identical key lists; and the
Welford update is restated for the per-message and per-bucket stores (item 4). And
one in the generation mechanism: `format_registry_set_occupant()` does its own cache
lookup-or-compile instead of calling `format_scan_sub_resolve()`, so occupant swaps
bypass the `scan_sub_cache_hits` counter that the resolve sub's own comment says
every order change routes through.

**Locked decisions that bound this item.**

- `features/log-format-registry.md` D39 and D40 (scan-sub code generation and
  ordering), D60 (zero code generation at startup; generation at election,
  promotion, occupant swap or pin); `features/58-format-registry-staged-detection.md`
  D26 (pinned-closure move-to-front order) and its lean-loop obligation.
- `features/312-numeric-criteria-highlight-selection.md` § Core mechanism and
  `features/478-highlight-decision-read-back.md` D4 (no outer activation wrapper
  around the highlight blocks, on a measured 0.24 % ceiling): a precedent for how
  a per-line saving is weighed.
- `features/516-bytes-aggregate-demand-gate.md` D1 and
  `features/517-message-outcomes-demand-gate.md` D1 (store-level demand flags,
  resolved once): the established form of remedy (b).
- `features/567-discard-named-values-from-message.md` § Post-release finding and its
  disposition (the regression is accepted; the remedies are design changes larger
  than that issue): this item is where they are assessed.
- The architect's constraint on the issue: any proposal here carries its own
  interleaved before/after, not a single pair.

**Harnesses that read this surface**: none read the loop's structure. The
behaviour-neutrality of every probe is proven the way #478 proved its edits:
identical rendered output and identical `-V` sections on the same inputs, diffed in
the scratchpad, and `perl -c`.

**Questions the findings discussion has to settle.**

- Is the "~870 lines" figure to be restated as the loop's code-line count (830
  today) wherever it is cited?
- Should session and user capture and the per-file index tracking respond to the
  options that hide or disable their consumers, or is their data-only gating
  deliberate?
- Is the cache bypass in `format_registry_set_occupant()` a finding under this item
  or under the general sweep?
- Are string-compare gates a separate cost class worth converting on their own,
  independent of either remedy? (Answered by the form series.)

### The architectural patterns sweep

**What it covers.** Every recurring shape in `ltl` that a new capability should be
built on: what it is, what it is for, why it is that shape, and where it is used.
The output is `docs/architecture-patterns.md` (§ 5) and the pattern inventory in the
audit report.

**What scoping found.** Fifteen candidate patterns with one to four consumption
sites each. Twelve already have an owning doc, so the new file indexes them and
points at the owner:

| Candidate pattern | Single surface today | Owning record |
|---|---|---|
| Declarative format registry compiled into a generated, cached scan sub | `format_registry_specs()`, `build_format_registry()`, `compile_format_scan_sub()`, `format_scan_sub_resolve()` | `features/log-format-registry.md`, `features/58-format-registry-staged-detection.md` |
| Single column-layout source of truth | `@column_layout`, `add_dynamic_column()` | `features/column-layout-refactor.md` |
| Bin-counter primitives | `partition_new()`, `bin_assign()`, `counter_update()`, `percentile()`, `partition_rebin()` | `features/189-histogram-bin-counter-primitives.md` |
| Precision tiers, one lever per surface | `bpd_for_surface()` over `%TIER_BPD` | `features/293-precision-lever-unification.md` |
| Data-model selectors, resolved once per surface | `resolve_data_model()`, `choose_data_model()` | `features/266-data-model-selectors.md` |
| Demand gates, store-level booleans resolved at option settlement | the demand block in `adapt_to_command_line_options()` | `features/516-...`, `features/517-...`, `features/305-shape-moment-extended-percentile-demand.md` |
| Declarative consumer registry for statistics-group demand | `@STAT_CONSUMERS`, `%STAT_GROUP_FIELDS`, `resolve_statistics_group_demand()` | `features/305-...`, `features/duration-statistics.md` |
| `-V` telemetry sections as the test surface | `%verbose_section_registry`, `section_requested()`, `emit_*_verbose()` | `tests/HARNESS-DESIGN.md` |
| One resolution surface per vocabulary | `builtin_metric_name()` and siblings; `format_csv_value()` | CLAUDE.md checkpoint; `features/histogram-charts.md`; no doc of its own |
| Named pipeline stages | `pipeline_detect()`, `_parse()`, `_accumulate()`, `_finalize()`, `_render()` | `features/180-named-pipeline-stages.md`, `docs/staged-processing-pipeline.md` |
| Staged processing, cheap inline match and periodic expensive discovery (S1 to S5) | `match_consolidation_patterns()`, `run_consolidation_checkpoint()` | `docs/staged-processing-pipeline.md` |
| Section visibility and boundaries | `resolve_visibility_name()`, `section_hidden()`, `open_section()` | `features/597-section-visibility.md` |
| Sort gates at three pipeline points | `apply_parse_time_sort_gate()` and its two siblings | `features/418-...`, `features/303-...`, `features/520-...` |
| Run-scoped activation flags resolved once | `$highlight_active`, `$discard_active`, `$outcome_filter_active` and siblings | none |
| Behavioural notices, always printed, deferred while progress owns the terminal | `defer_notice()`, `flush_deferred_notices()`, the `emit_*_notices()` subs | none; the CLAUDE.md checkpoint only |

Further registry-shaped candidates the verifier surfaced and the audit scouts:
generated code compiled from source strings exists at three sites, not one
(`compile_format_scan_sub()`, `compile_format_classifier()`,
`compile_format_extractor()`), which bears on whether "generated per-run code" is a
pattern of its own; the `--explain` topic registry (`populate_explain_topics()`,
`features/504-explain-technique-topics.md`); the memory-structure registry
(`named_structure_sizes()`); and the user-defined-metric spec registry
(`parse_udm_configs()` and its resolvers, `features/user-defined-metrics.md`).

Divergences the scouting found inside patterns: the timeline latency column's
visibility is restated three times (the consumer registry's `active` predicate, the
demand block, and `build_column_layout()`), identical today; the
`histogram-bin-counters` section has two emitters, and the emitter sub's name tracks
an older section name against the harness naming rule; the activation flags for
expose and mask are set in their resolve subs and set again in
`apply_discard_precedence()`.

**Search angles the audit runs.**

1. *By registry.* Every hash or array at file scope whose values are specs, closures
   or predicates, and the resolver that reads it.
2. *By flag.* Every `*_active`, `*_demand`, `*_enabled` and `*_capture_mode` global:
   where it is resolved and how many places test it.
3. *By generation.* Every `eval $src` and the source-building sub behind it.
4. *By doc.* Every feature doc heading that names a mechanism as reusable ("template",
   "pattern", "applicability beyond", "single source of truth").

**Evidence a pattern entry carries.** Name; a one-paragraph definition; intended
uses (when a new capability should reach for it); the reasoning (usually a measured
finding: the cost it avoids or the drift it prevents), cited by what was measured;
at least two consumption sites (sub plus snippet); the owning record (doc path and
heading); status, either established or needing refinement, with the finding that
says why.

**Questions the findings discussion has to settle.**

- Does `docs/architecture-patterns.md` index `docs/staged-processing-pipeline.md`
  or absorb it? The latter already generalises beyond consolidation and carries
  the named-stages section.
- Do absence-tolerant downstream reads (#516 D2, #517 D2) and observation-count
  gating (the CLAUDE.md rule) get entries of their own or sit inside the demand-gate
  entry?
- Is generated per-run code one pattern (three sites today, and possibly a
  generated loop body under item 8) or part of the registry entry?
- Where does the one-resolution-surface rule's definition live: CLAUDE.md, the
  patterns file, or both with one pointing at the other?
- Are the explain-topic, memory-structure and user-defined-metric registries
  entries, or instances under one "declarative registry with a resolver" entry?

---

## 5. Deliverable contracts

Two documents carry this issue. This one is the specification. The audit report,
`features/342-redundant-logic-surfaces-audit-report.md`, is where the findings live,
opened with the scoping pass's verified inventory as its first entries and completed
by the audit. Issue comments point at the report; nothing lives only in a comment.

### The audit report

Per scope item, in the order of § 4:

- **Findings table.** One row per finding, identified `F<item>.<n>` (so `F1.3` is
  the third finding of item 1, and every later reference carries its meaning in the
  same sentence). Columns: vocabulary, value class or decision; site A and site B
  (sub plus snippet; further copies listed in a note); what each site does; observed
  divergence; target sub; contract and owner; category; priority; related open
  issues.
- **Related open issues** names every open issue whose scope touches the
  finding's surface, each with its relationship stated in words (removes a copy,
  adds a copy or a reader, depends on the open contract, already records the
  observation), or "none" when the sweep of the open-issue list found nothing.
  Each item's section also carries one list of the open issues that touch the
  item as a whole, so the findings discussion can see which issues a grouping
  would have to be sequenced against.
- **Category** is one of: *diverged* (the copies already disagree, and a user can
  observe it: recorded with the two observations); *latent* (the copies agree today
  and nothing ties them); *identical by construction* (agree because they read the
  same table; recorded so the reader knows the site was audited, ranked last); or
  *deliberate* (documented to differ; closed with the doc that says so). A finding
  in the loop or any other per-line or per-key path also carries the mark *hot
  path*, which is the benchmark obligation for whichever issue fixes it.
- **Priority** ranks by divergence risk first (diverged above latent above
  identical), then by user-visible consequence, then by the number of copies.
- **Site inventory.** Every site the angles found, including those that produced no
  finding, so a later reader can see coverage rather than infer it.
- **Questions for the findings discussion**, carried over from § 4 with the
  evidence that bears on each.

A closing section groups findings by target sub across items, as the starting point
for the discussion of which findings become issues and how they group. The grouping
is a proposal; the decision is the architect's and is recorded on the issue when
made.

The item 8 measurement is recorded under `tests/profile/results/342-read-loop-cost-curve/`
and summarised in the report with medians and ranges. It is drop 2; the report's
item 8 section says so until the record lands.

### `docs/architecture-patterns.md`

One entry per pattern, in the shape § 4 gives (name, definition, intended uses,
reasoning, consumption sites, owning record, status). An index, not a duplicate:
where an owning doc exists the entry summarises and points; where none exists
(activation flags, behavioural notices, the one-resolution-surface rule) the entry
is the record. `docs/staged-processing-pipeline.md` stays where it is unless the
discussion decides otherwise. The file names Perl identifiers, so it is a developer
document: it is not added to the wiki source map in `build/sync-wiki.sh`, and
`tests/validate-explain.sh` is run to confirm the map still matches the disk.

### The two `CLAUDE.md` edits, in the same commit as the patterns file

- A row in *Where to look*: `| Building on, or adding to, a recurring mechanism
  (registry, gate, generated sub, layout, notice) | docs/architecture-patterns.md |`.
- A line under *Before writing or changing code*: "Consult
  `docs/architecture-patterns.md` for a pattern that fits before building. A change
  that adds a consumption site of a pattern, or introduces a new one, records it
  there in the same commit."

Both are drafts for the architect's wording.

### Issue comments

One comment when the corrections (§ 3) are on the branch, pointing at them. One
when the report is complete, pointing at it and at the grouping proposal. The
completion comment per `docs/process/workflow.md` § 4, recording the gate skip.

---

## Acceptance criteria

Triaged per `docs/test-driven-development.md`.

**Assertable**

- [ ] Every site in every findings table and site inventory of the report is a
      (sub, snippet) pair for which `grep -F` of the snippet, restricted to the
      named sub's range in `ltl` at the audited commit, finds at least one line.
      *Method: a scratch script over the report's tables, run before the PR; a
      lookup that matches nothing is a failure of the report, never a pass.* File-scope
      sites name the section (`GLOBALS`, or the two subs they sit between).
- [ ] Every pattern entry in `docs/architecture-patterns.md` names at least two
      consumption sites that pass the same check, and an owning record whose path and
      heading exist.
      *Method: the same script, plus a heading grep per owning record.*
- [ ] Every finding categorised *diverged* carries the two observations (rendered
      strings, CSV cells, `-V` values or notices) produced by a run of `ltl` on a
      named fixture, captured once to the scratchpad; none rests on reading alone.
      In particular the two item 3 gaps found by reading are each confirmed or
      refuted by a run on a minimal fixture.
      *Method: the captures are cited in the report by fixture and options.*
- [ ] Every scope item's report section lists the search angles § 4 names for it
      and records each as run, so a reader can see coverage.
      *Method: review against § 4.*
- [ ] Every finding carries a related-open-issues entry, and every issue it names
      is open at the time the report section is written and is cited with its
      relationship in words.
      *Method: the same scratch script extracts every `#NNN` from the report's
      findings and runs `gh issue view --json state` on each; a closed or
      missing issue is a failure of the report.*
- [ ] The item 8 record reports, for each probe, the median and range of at least
      ten interleaved rounds against the base on the access log and the application
      log, the per-gate slope with its range, the NYTProf statement count for the
      base and the N = 40 probe, the ceiling computed from slope times inventory, and
      the ScriptLog pair.
      *Method: `analysis.md` under the record's directory; `hypothesis.md` is dated
      before the first run.* Drop 2.
- [ ] The patterns file, the *Where to look* row and the checkpoint line land in one
      commit.
      *Method: `git show --stat` of that commit.*
- [ ] `tests/validate-explain.sh` exits 0 after the patterns file is added, so the
      wiki source map still matches the disk.
- [ ] No finding names a customer, host, case or contributed-log provenance; sample
      lines are placeholders.
      *Method: review; `git grep` for the corpus path prefix in both documents.*

**Unassertable**

- [ ] The audit found every duplicate. There is no oracle for completeness. The
      mitigation is four blind angles per item (§ 4), the independent re-grep of every
      reported site, and a closing "what was not searched" note in the report; the
      architect decides whether that stands.
- [ ] The patterns file changes how the next capability is built. Only the
      checkpoint line and review can make it so.

**Unknown, proposed as prototyping scope**

- [ ] Whether a per-gate cost near 0.4 % can be resolved on this host at all. The
      synthetic gate series is designed so that the N = 40 probe is resolvable even
      when one gate is not, and the record either reports the slope with its range or
      reports the noise floor that prevented it. Cost: about five probe binaries times
      two files times ten interleaved rounds, roughly one hundred runs of nine to
      twelve seconds plus four profile runs, an afternoon of machine time on this
      host, with `hypothesis.md` and `analysis.md` as the record. Accepted by the
      architect on 2026-09-26 as drop 2 of the issue, run in the background while
      drop 1 is triaged.

---

## Completion gate

Scope per `docs/process/workflow.md` § 3, applied to each drop's diff at its PR.
The expected diff of either drop touches `features/`, `docs/`, `CLAUDE.md`, `prototype/` and
`tests/profile/results/`, and no executable line of `ltl`, no harness, no fixture.
The first four are the exempt row; `prototype/` and `tests/profile/results/` are
not named in the table, and are read as exempt on the table's own principle (they
change no behaviour of the tool and no assertion), which the completion comment
states. The full suite and the before/after benchmark are skipped, and the skip is
recorded in the completion comment. `perl -c ltl` runs because the branch carries the
`0.19.0-342` version stamp, restored to `0.19.0` before each PR.

No release-notes bullet: nothing a user observes changes.

---

## Ordering

The audit blocks nothing and nothing blocks it. Open issues that share its surfaces,
each tested dependency-first (can that issue reach a clean implementation before
this audit lands, and can this audit complete before it lands?):

- #601 (deprecate the options `--hide` and `--show` duplicate) and #581 (deprecate
  the omit options `--discard` duplicates): both remove copies that item 1 will list.
  Either order works; whichever lands second reads the other's record. Informational.
- #514 (count metric capture and display become explicit): touches the count family
  in items 4 and 6. Informational.
- #525 (a single option for timestamp precision): touches item 3's bucket
  arithmetic. Informational.
- #426 (per-message statistics store, on hold) and #469 (consolidated message
  histograms on a shared bucket): touch the stores item 4 derives from. Both on hold
  or in backlog; informational.
- #582 (regex spec grammar for message options): touches the `-x`/`-d`/`-m`
  operand surface of item 1. Informational.
- #454 (notice that statistics describe a filtered subset): a consumer of the
  behavioural-notices pattern. Informational.

No native `blocked_by` edge is recorded in either direction. The findings discussion
may create edges between the issues it files and any of the above; those are
recorded then, natively, with agreeing prose.

---

## What follows the audit

Nothing in this issue changes `ltl`. Every fix to a finding is its own issue,
grouped or single as the findings discussion decides, and follows
`docs/process/workflow.md` in full: branch, specification with acceptance criteria,
implementation, the complete harness suite, and, for any issue whose diff touches
the hot path (the per-line loop, the per-key paths, sorts, anything the *hot path*
mark in the report identifies), a before/after benchmark on the machine doing the
work, with the interleaved method where the expected effect is near the noise
floor. A convergence PR carries a behaviour matrix proving parity on the #327
follow-up's template, and states its converged surface's contract in the owning
feature doc, per the issue's two constraints.
