# Feature: the opt-out prose sweep (#548)

## GitHub Issue

[#548](https://github.com/gregeva/logtimeline/issues/548): BUG: fifteen records still
describe the removed bin-counter opt-out flag and fields as live.

Delivered together with
[#546](https://github.com/gregeva/logtimeline/issues/546) (the histogram bin-counter `-V`
emitter labels a consumer unified when no value was observed), which owns the live
emitter defect. This issue owns the documentation sweep only. No production code.

## Motivating consumer

The next harness author who opens `features/225-test-harness-coverage-gaps.md` and reads
its section headed "`--exact-percentiles` policy". That section tells them, in the present
tense, that "All new fixtures use `--exact-percentiles`". They follow the instruction, the
run exits 1 with `Unknown option: exact-percentiles`, and the flag they were told to pin
their fixture with has not existed since the per-message bin-counter data model
(`features/287-message-stats-bin-counter-data-model.md`) removed it as a declared breaking
change. The same reader, checking the harness-design reference for the assertion shape to
copy, finds `tests/HARNESS-DESIGN.md` illustrating a well-documented assertion with
`consumers_active: none`, a line the tool has no emission site for.

The sweep exists so that instruction and illustration both name something the tool does.

## Requirement

Every passage under `features/`, `docs/`, `tests/` and `prototype/` that instructs a
reader to use `--exact-percentiles` or promises the `opt_out_active`, `opt_out_notice` or
`consumers_active` output is trued up against the opt-out contract as it now reads:
`features/187-histogram-bin-counter-percentiles.md` Decision 7 (user-facing opt-out through
the per-surface data-model selectors `-dm`, `-mdm`, `-bdm`, `-hmdm`, `-hgdm`, each
`<raw|bin>`, with no run-level banner and no run-level opt-out line), as re-locked
2026-08-27 under #460 (bin-model percentiles computed from the counters that captured
them), and Decision 8 (the `-V` reporting contract for the `=== histogram-bin-counters ===`
section) as amended by #546.

Records of what was measured or what shipped are not rewritten. Release notes under
`releases/` are immutable history and are not touched at all.

## Not in scope

- The live emitter defect and its harness assertion: #546 owns those.
- The three items #546 edits, listed under *Division of labour* below.
- Any change to `ltl`, to any `tests/validate-*.sh` assertion's meaning, or to `docs/usage.md`
  (whose "exact percentiles" hits are ordinary prose about exact versus interpolated
  percentiles and name no removed flag; the inventory grep returns no `docs/` hit at all).
- The direction of the `shares_partitions_with` declaration on the same emitter, noted as an
  open follow-up in `tests/validate-histogram-bin-counters.sh` and unrelated to the opt-out
  vocabulary.

## Division of labour with #546 (locked)

#546 edits these three, and this issue must not touch them, so the two branches do not
conflict:

1. `features/187-histogram-bin-counter-percentiles.md` Decision 8 (the `-V` reporting
   contract) and its R7 mirror bullet under the `-V` observability requirement: the five
   `consumers_active: none` passages and the non-parsing `ltl -ll <file> -V` example
   invocation.
2. `features/426-per-message-statistics-store.md`, the locked-decision inventory row for
   #187 Decision 7 that reads "Never amended; contradicted by shipped code" (Decision 7 was
   re-locked 2026-08-27 under #460).
3. `tests/HARNESS-DESIGN.md`, the worked examples under the heading "Self-documenting
   assertions" that cite `consumers_active: none` (the plain-language contract statement,
   the `assert_line` implementation shape, and the failure-output block).

This issue takes `tests/HARNESS-DESIGN.md`'s *other* opt-out hit, the key-rename example
under "Stability contract", which cites `opt_out_active` rather than `consumers_active` and
so falls outside #546's three worked examples.

## Inventory

Re-run in the worktree on the issue branch:

```
git grep -n -E 'exact-percentiles|exact_percentiles|opt_out_active|opt_out_notice|consumers_active' \
    -- features docs tests prototype releases README.md CLAUDE.md
```

124 hits across 22 files. The #546 brief's count of fifteen counted the prose records only;
this run also returns three executable or generated prototype artifacts
(`prototype/189-bin-counter-primitives.pl`, `prototype/426-revalidate-v4.pl`,
`prototype/426-results/revalidate-v4-all.txt`), the two `releases/` files, `features/187`
and `features/266`. No file in the brief's list is missing from this run, and `docs/` and
`README.md` and `CLAUDE.md` return no hit.

Classes: **(a)** record of the removal, stays as is; **(b)** history that must not be
rewritten; **(c)** live intent, trued up by this issue; **(d)** #546's, untouched here.

| File | Hits | Class | Disposition |
|---|---|---|---|
| `features/266-data-model-selectors.md` | 20 | a | The record of the selectors that replaced the flag, including the sentence "This issue does not remove `--exact-percentiles`. Removal is a separate follow-up gated on user migration." True as written when written. No edit. |
| `prototype/189-bin-counter-primitives.pl` | 18 | b | The prototype program whose run produced the validation report. An executable record of what was measured. No edit. |
| `features/34-histogram-bin-counter-mode.md` | 12 | c | Six passages describing the opt-out path in the present tense, plus three acceptance criteria marked done against the flag, plus one edge-case row and one cross-consumer validation bullet. Replacements below. |
| `tests/validate-runtime-config.sh` | 9 | c (2 hits), rejection assertion (7 hits) | The scenario asserting the flag is rejected stays exactly as it is. The header comment and the dead pattern alternative are trued up. Replacements below. |
| `features/426-per-message-statistics-store.md` | 7 | b (6 hits), d (1 hit) | The audit findings row and the divergence rows record what a grep over `ltl` returned on the day of the audit. No edit. The locked-decision inventory row for Decision 7 is #546's. |
| `features/189-bin-counter-primitives-implementation-readiness-audit.md` | 7 | b (5 hits), c (2 hits) | The audit-execution log, the delivery-sequence diagram and the PR-sequence list record an audit taken against a named commit. No edit. Two passages state a live recommendation for production code. Replacements below. |
| `tests/HARNESS-DESIGN.md` | 6 | c (1 hit), d (5 hits) | The key-rename example under "Stability contract" is this issue's. The three `consumers_active: none` worked examples are #546's. Replacement below. |
| `prototype/189-bin-counter-primitives-validation-report.md` | 6 | b, annotated | Discharge evidence for #187 Decision 10 (prototype validation mandatory before bin production code). Original text intact; one dated annotation added. Text below. |
| `features/287-message-stats-bin-counter-data-model.md` | 6 | a | The removal's own record, including the acceptance criterion that already names the removal in a parenthesis. No edit. |
| `features/225-test-harness-coverage-gaps.md` | 6 | c | The fixture policy, its future-audit sentence, the stability note for future maintainers, and the two sub-issue records of a deprecation warning that no longer exists. Replacements below. |
| `prototype/426-bin-primitives-revalidation-report.md` | 5 | b | A measured revalidation that names the drift as pre-existing and not caused by the store work. No edit. |
| `features/187-histogram-bin-counter-percentiles.md` | 5 | d | All five are `consumers_active: none`. #546's. |
| `prototype/426-results/revalidate-v4.md` | 3 | b | A per-aspect result file. No edit. |
| `prototype/426-results/revalidate-v4-all.txt` | 3 | b | Generated capture. No edit. |
| `features/213-consolidation-regression-investigation.md` | 3 | b | A three-way A/B measured while the flag existed. Rewriting would falsify what was measured. No edit. |
| `releases/v0.14.5.md` | 2 | b | Shipped release notes. Untouched by acceptance criterion 4 below. |
| `releases/v0.15.0.md` | 1 | b | The release note announcing the removal. Untouched. |
| `prototype/426-revalidate-v4.pl` | 1 | b | Scenario title in the revalidation program. No edit. |
| `features/bin-counter-accuracy-and-observability.md` | 1 | a | The drop record naming the drift as a finding: "the contract describes an exact-percentiles opt-out flag and two verbose lines that do not exist in the shipped emitter". This is the correct statement already. No edit. |
| `features/289-bucket-stats-bin-counter-data-model.md` | 1 | a | Out-of-scope bullet reading "Removal of `--exact-percentiles` (already removed in #287)". Correct as written. No edit. |
| `features/224-validate-statistics-test-harness.md` | 1 | c | One related-issue row calling the flag deprecated in the present tense. Replacement below. |
| `features/189-histogram-bin-counter-primitives.md` | 1 | c | One requirement bullet describing the opt-out in the present tense. Replacement below. |

## Replacements

Convention per document. `features/34`, `features/189-histogram-bin-counter-primitives.md`,
`features/189-bin-counter-primitives-implementation-readiness-audit.md`,
`features/224` and `tests/HARNESS-DESIGN.md` carry no dated-correction convention and get
plain replacements. `features/225` records sub-issue outcomes with dates throughout and
gets a dated note for the two sub-issue records; its policy sections get plain
replacements. The prototype report gets a dated annotation with its original text intact.

Each quoted sentence below is the current text, identified by the heading it sits under.

### `features/225-test-harness-coverage-gaps.md`

**Under the heading "`--exact-percentiles` policy".** Current:

> All new fixtures use `--exact-percentiles` for the same reason as the existing heatmap
> fixtures: pins to the sort-and-index path so the reference stays byte-stable while
> bin-counter precision work (#34/#187/#201) lands. `calculate_histogram_buckets()` at
> `ltl:5630-5635` dispatches through the same opt-out flag, so the policy applies to
> histogram fixtures too.
>
> A future audit (separate issue) should re-capture all fixtures without
> `--exact-percentiles` once the unified path is locked, and migrate the harness off the
> deprecated flag.

Replacement, with the heading renamed to "Data-model policy for regression fixtures":

> All new fixtures pin the raw data model with `-dm raw`, for the same reason the existing
> heatmap fixtures do: it holds the surface on the sort-and-index path, so the reference
> stays byte-stable across precision changes on the bin-counter path. The histogram
> surface resolves its data model through the same selector chain, in
> `calculate_histogram_buckets()`, so the policy covers histogram fixtures too. The
> selector set and its per-surface scope are locked in
> `features/187-histogram-bin-counter-percentiles.md` Decision 7 (user-facing opt-out
> through the per-surface data-model selectors) and owned by
> `features/266-data-model-selectors.md`.

The second paragraph, proposing a future audit to migrate the harness off the flag, is
deleted: `tests/validate-regression.sh` carries 27 `run_test` lines on `-dm raw` today, so
the migration the paragraph asks for has happened.

**Under the heading "Stability notes for future maintainers".** Current first bullet:

> - The `--exact-percentiles` flag is documented-deprecated (warning now fires per #231);
>   when it's removed, this harness needs to be re-captured against whatever the new
>   opt-out mechanism is, OR the harness has to migrate to non-byte-identical assertions
>   for heatmap/histogram (probably bin-counter-precision-aware tolerance bands). Captured
>   behavior here is anchored on the current opt-out flag.

Replacement:

> - Captured behaviour here is anchored on the raw data model, pinned per fixture with
>   `-dm raw`. The selectors are permanent and carry no retirement timeline per
>   `features/187-histogram-bin-counter-percentiles.md` Decision 7 (user-facing opt-out
>   through the per-surface data-model selectors), so the fixtures stay byte-stable without
>   a migration to tolerance bands. A fixture that needs to exercise the bin data model
>   instead asserts through the algorithm-aware oracle in `tests/validate-statistics.sh`,
>   not byte-identity.

**Under the heading for sub-issue #231 (CLI option parsing / conflict detection), the
silent-override-warnings table row 4.** Current:

> | 4 | `--exact-percentiles` | Silent; documented as deprecated | Deprecation warning on every use |

**And the scenarios table row 7.** Current:

> | 7 | warning-exact-percentiles-deprecated | Deprecation warning fires on `--exact-percentiles` |

Both rows are records of what sub-issue #231 shipped, in a document that records sub-issue
outcomes as shipped. They are not rewritten. A dated note is added immediately below the
scenarios table, in the document's own dated style:

> **2026-09-13:** the `--exact-percentiles` deprecation warning (site 4, scenario 7) no
> longer exists. The flag was removed in #287 (message-stats bin-counter data model) as a
> declared breaking change; `tests/validate-runtime-config.sh` now asserts that `ltl`
> rejects the flag as an unknown option. The three remaining silent-override warnings are
> unaffected.

### `features/34-histogram-bin-counter-mode.md`

**Under the heading "Overview", final sentence.** Current:

> The consumer either runs the unified path (post-migration) or its pre-migration code path
> (pre-migration or under `--exact-percentiles` opt-out per #187 Decision 7).

Replacement:

> The consumer either runs the unified path (post-migration) or its pre-migration code path
> (pre-migration, or when its surface resolves to the raw data model per #187 Decision 7,
> user-facing opt-out through the per-surface data-model selectors).

**Under the heading "Terminology", the pre-migration-path entry.** Current:

> - **Pre-migration path** — the consumer's current end-of-parse-from-retained-arrays code
>   (in `calculate_heatmap_buckets`, `calculate_histogram_buckets`). Survives post-migration
>   as the `--exact-percentiles` opt-out path per #187 Decision 7.

Replacement: the final sentence becomes "Survives post-migration as the path a surface runs
when it resolves to the raw data model per #187 Decision 7 (user-facing opt-out through the
per-surface data-model selectors)."

**Under the heading "R2 — No runtime mode-selection gate".** Current:

> - Post-validation, as the path engaged when the user opts out via `--exact-percentiles`
>   (per #187 Decision 7).

Replacement: "- Post-validation, as the path engaged when the user pins the surface to the
raw data model with `-hmdm raw`, `-hgdm raw` or the omnibus `-dm raw` (per #187 Decision 7)."

**Under the heading "R10 — Per-consumer `-V` path reporting".** Current:

> - `user_opt_out` — `--exact-percentiles` is active per #187 Decision 7.

Replacement: "- `user_opt_out` — the consumer's surface resolved to the raw data model per
#187 Decision 7."

**Under the heading "R11 — Pre-migration code path preserved through phase validation per
#187 R11".** Current:

> - Under `--exact-percentiles`, byte-identical pre-feature output per #187 R11a.

and

> After phase validation passes, the pre-migration code is retained as the
> `--exact-percentiles` opt-out surface per #187 Decision 7.

Replacements: "- Under the raw data model, byte-identical pre-feature output per #187 R11a."
and "After phase validation passes, the pre-migration code is retained as the raw
data model's execution path per #187 Decision 7."

**Under the heading "Edge cases", the opt-out row.** Current:

> | `--exact-percentiles` is set | All four consumers report `path: user_opt_out` and run the pre-migration code paths per #187 Decision 7 and R11 of this feature. |

Replacement:

> | `-dm raw` is set (or `-hmdm raw` and `-hgdm raw` together) | All four consumers report `path: user_opt_out` and run the pre-migration code paths per #187 Decision 7 and R11 of this feature. |

**Under the heading "Cross-consumer scenarios".** Current:

> - **Per-consumer opt-out**: confirm that `--exact-percentiles` applies to all four
>   consumers uniformly per #187 Decision 7 (global scope).

Replacement, which also corrects the scope word: Decision 7 locks per-surface scope, and the
four consumers sit on two surfaces.

> - **Per-surface opt-out**: confirm that `-hmdm raw` pins `heatmap_cells` and
>   `heatmap_markers` and that `-hgdm raw` pins `histogram_view` and `histogram_bins`, each
>   surface independently, per #187 Decision 7 (per-surface scope). The omnibus `-dm raw`
>   pins all four at once.

**Under the heading "Acceptance criteria", three criteria marked done.** Current:

> - [x] R11 holds: pre-migration code preserved verbatim as `calculate_heatmap_buckets_exact`
>   and `calculate_histogram_buckets_exact`; dispatched via `--exact-percentiles`.
> - [x] Under `--exact-percentiles`, all four consumers' output is byte-identical to the
>   pre-feature implementation per #187 R11a (validated on 148MB Tomcat).
> - [x] `tests/validate-regression.sh` passes 19/19 — heatmap regression tests re-keyed
>   against `--exact-percentiles` (PR #206) to keep them byte-stable across future precision
>   tweaks; bin-counter accuracy is independently covered by `tests/validate-percentile-mode.sh`.

These record a criterion that was verified, and the verification is not being re-asserted.
The dispatch mechanism named in each is the one the criterion is checked against today, so
each keeps its mark and names the current mechanism:

> - [x] R11 holds: pre-migration code preserved verbatim as `calculate_heatmap_buckets_exact`
>   and `calculate_histogram_buckets_exact`; dispatched on the resolved data model.
> - [x] Under the raw data model, all four consumers' output is byte-identical to the
>   pre-feature implementation per #187 R11a (validated on 148MB Tomcat).
> - [x] `tests/validate-regression.sh` passes 19/19 — heatmap regression tests keyed to the
>   raw data model (PR #206) to keep them byte-stable across future precision tweaks;
>   bin-counter accuracy is independently covered by the bin-model scenarios in
>   `tests/validate-statistics.sh`.

The third criterion also drops a reference to `tests/validate-percentile-mode.sh`, which is
not a file in the tree; the bin-model coverage it points at is the bin-data-model scenario
family recorded in `features/224-validate-statistics-test-harness.md`.

**Under the heading "Progress", the validation list.** Current:

> - `--exact-percentiles` output byte-identical to HEAD (pre-migration code preserved).

Replacement: "- Raw-data-model output byte-identical to HEAD (pre-migration code
preserved)." This is a record of a measurement whose subject is named by a flag; the
measurement itself is unchanged and the sentence names the same code path.

### `features/189-histogram-bin-counter-primitives.md`

**Under the heading "R10 — Pre-migration code path coexistence (per #187 R11 / R11a)".**
Current:

> - A migrated consumer with `--exact-percentiles` opt-out (per #187 Decision 7) reverts to
>   its pre-migration code path for that run.

Replacement:

> - A migrated consumer whose surface resolves to the raw data model (per #187 Decision 7,
>   user-facing opt-out through the per-surface data-model selectors) reverts to its
>   pre-migration code path for that run.

### `features/189-bin-counter-primitives-implementation-readiness-audit.md`

Five of this document's seven hits sit in the audit-execution log, the delivery-sequence
diagram and the PR-sequence list, each a record of an audit taken against a named commit of
`release/0.14.5`. Those stay. The two that state a recommendation for production code are
trued up, because a reader taking the recommendation would add a flag that no longer exists.

**Under the heading for the `print_help()` code surface.** Current:

> **Recommended change:** #189 production adds `--percentile-precision`, `-pbpd`, and
> `--exact-percentiles` to `print_help()` per Decision 2 line 1190-1193 and Decision 7 line 1429.

Replacement, which also drops the line-number citations:

> **Recommended change:** #189 production documents the precision lever and the data-model
> selectors in `print_help()` per #187 Decision 2 (the `buckets_per_decade` lever) and
> Decision 7 (user-facing opt-out through the per-surface data-model selectors). The lever
> is the single `-dmp` flag after #293 (precision lever unification) and the opt-out is the
> selector set `-dm` / `-mdm` / `-bdm` / `-hmdm` / `-hgdm`, each `<raw|bin>`.

**Under the heading for the option-parsing code surface.** Current:

> **Recommended change:** #189 production adds parsing for `--percentile-precision N`,
> `-pbpd N`, and `--exact-percentiles` per Decision 2's flag interaction contract (`-pbpd`
> wins on conflict against `--percentile-precision`). Validation rules per Decision 2 line
> 1130 (`4 ≤ -pbpd ≤ 616`; `1 ≤ --percentile-precision ≤ 9`). The `-hgbpd`/`-pbpd`
> interaction is a separate question — recorded in C7.

Replacement:

> **Recommended change:** #189 production adds parsing for the precision lever and the
> data-model selectors. The lever is the single `-dmp` flag after #293 (precision lever
> unification), validated over the tier range #187 Decision 2 locks; the selectors each take
> a `<raw|bin>` argument validated at parse time through one shared validator per Decision 7
> (user-facing opt-out through the per-surface data-model selectors). The two-flag conflict
> contract Decision 2 originally carried no longer arises, because there is one lever.

The third hit in this document, under the heading for the user-documentation code surface,
recommends analyst-facing prose on "when to consider `--exact-percentiles` opt-out" together
with a `--percentile-precision 1..9` tier table. That sentence is replaced in the same
vocabulary: "when to pin a surface to the raw data model with `-dm raw` or a per-surface
selector", and the tier table named as the `-dmp` tier table.

The recommendation under the heading for `calculate_statistics`, which ends "After every
consumer migrates, the function can be retired or kept as the `--exact-percentiles` opt-out
path (#187 R11a / Decision 7)", has its final clause replaced with "kept as the raw data
model's execution path (#187 R11a / Decision 7)".

### `features/224-validate-statistics-test-harness.md`

**Under the heading "Related issues", the row for #266.** Current, in part:

> Replaces the deprecated negative opt-out `--exact-percentiles` with positive selectors;
> enables the `bin-data-model` scenario family.

Replacement:

> Replaces the earlier negative opt-out with positive selectors; enables the
> `bin-data-model` scenario family.

The rest of the row, which records the surfaces that shipped bin counters, is unchanged.
Naming the removed flag is not the problem here; calling it "deprecated" in the present
tense is, and the row does not need the flag's name to say what #266 replaced.

### `tests/HARNESS-DESIGN.md`

**Under the heading "Stability contract", the key-rename example.** Current:

> **Renames and removals are breaking changes.** Renaming a section
> (`=== bin-counter-mode ===` → `=== histogram-bin-counters ===`) or a key
> (`opt_out_active` → `exact_percentiles_optout`) requires:

The section-rename half is a real rename that happened and stays. The key half invents a
rename of a key that does not exist. Replacement, using a key rename that happened:

> **Renames and removals are breaking changes.** Renaming a section
> (`=== bin-counter-mode ===` → `=== histogram-bin-counters ===`) or a key
> (`buckets_per_decade` → `data_model_precision`) requires:

The `buckets_per_decade` to `data_model_precision` rename is the run-level header change
that shipped under #293 (precision lever unification) and is recorded in
`features/426-per-message-statistics-store.md`'s locked-decision inventory row for #187
Decision 8.

### `tests/validate-runtime-config.sh`

**The header comment, concern 2.** Current:

> #   2. Silent-override warnings fire on the documented sites
> #      (-g non-numeric, -hm non-built-in without UDM,
> #      --exact-percentiles deprecation).

Replacement:

> #   2. Silent-override warnings fire on the documented sites
> #      (-g non-numeric, -hm non-built-in without UDM).

**The dead pattern alternative, in `scenario_no_warning_on_clean_run`.** Current:

>     assert_no_line "$RUN_STDERR" \
>         pattern     "is not numeric|is not a built-in metric|--exact-percentiles is deprecated" \

Replacement:

>     assert_no_line "$RUN_STDERR" \
>         pattern     "is not numeric|is not a built-in metric" \

The third alternative names a warning removed with the flag, so it can never match and the
assertion passes vacuously on that limb. Removing it is one line in the same vocabulary as
the header comment, it does not weaken the assertion (the two remaining alternatives are the
two warnings that exist), and it is the concrete instance of the vacuous-match failure mode
that #545 (harnesses accept an unknown scenario selector or flag silently) is about. **In
scope: yes.** See the gate section for what this line pulls in.

**Untouched:** `scenario_error_unknown_exact_percentiles` in its entirety, including its
`asserts`, `produced_by`, `contract` and pattern strings and the dispatch line that runs it.
That scenario asserts the rejection and is the one place under `tests/` where the removed
flag is invoked on purpose.

## The prototype report annotation

`prototype/189-bin-counter-primitives-validation-report.md` is the discharge evidence for
#187 Decision 10 (prototype validation as a hard prerequisite for #189 production code).
`prototype/README.md` records that a prototype's output is a decision in the owning feature
doc, which is why the report is not re-issued and not rewritten: what it measured, it
measured.

Four of the six render scenarios its V4 aspect enumerates name flags the CLI now rejects.
So the report, read cold, over-claims the coverage that discharged a mandatory gate. The
disposition is a dated annotation, placed immediately under the heading
"V4 — `=== PERCENTILE MODE ===` `-V` output samples" and before that section's "Hypothesis"
sub-heading, with every word of the original section left intact. Annotation text, verbatim:

> **Annotation added 2026-09-13 under #548.** Four of the six V4 render scenarios name
> command-line flags `ltl` no longer accepts, so they cannot be re-run against the tool as
> it ships. Scenario 2 (`--percentile-precision N` override) and scenario 3 (`-pbpd N`
> override) name the two precision flags dissolved by #293 (precision lever unification)
> into the single `-dmp` lever; scenario 4 (both flags, `-pbpd` wins) tested a conflict that
> the single lever makes unreachable; scenario 6 (`--exact-percentiles` opt-out) names the
> flag removed by #287 (message-stats bin-counter data model) as a declared breaking change,
> and with it the `opt_out_active` and `opt_out_notice` header lines, which have no emission
> site. The opt-out is now the per-surface data-model selectors locked in
> `features/187-histogram-bin-counter-percentiles.md` Decision 7, and it surfaces as the
> per-consumer `path: user_opt_out` line, with no run-level banner. Scenario 1 (default
> precision) and scenario 5 (overflow audit firing) remain reachable. The findings recorded
> below stand as the record of what was measured on the prototype in 2026-05; they are not
> a statement about the shipped tool's current flag surface. The same four scenarios were
> re-mapped onto the shipped tool under #426, recorded in
> `prototype/426-bin-primitives-revalidation-report.md` Finding H.

The cross-aspect table row reading "Decision 7 (opt-out flag) | V4 scenario 6 |
`--exact-percentiles` produces the locked banner + per-consumer `user_opt_out` line" is left
as it stands. It is inside the report's record of what was validated, and the annotation
above covers it.

## Decisions

**D1. Three classes, and only one of them is edited.** A passage is a record of the
removal, history, or live intent. Records of the removal (`features/266-data-model-selectors.md`,
`features/287-message-stats-bin-counter-data-model.md`,
`features/289-bucket-stats-bin-counter-data-model.md`,
`features/bin-counter-accuracy-and-observability.md`) already say the true thing and are not
touched. History (release notes, A/B analyses, prototype programs, prototype result files,
generated captures, audit-execution logs) is not rewritten, because rewriting it falsifies
what was measured or what shipped. Only live intent, a passage that instructs a reader to do
something or promises output, is trued up.

**D2. The test of live intent is whether following the passage fails.** An acceptance
criterion marked done is a record, not an instruction, so it keeps its mark; but where the
mechanism it names is the one a reader would check it against today, the mechanism is
renamed to the current one. A scenario table row in a sub-issue record is a record and gets
a dated note rather than a rewrite. A policy sentence in the present tense ("All new
fixtures use...") is an instruction and is rewritten outright.

**D3. `releases/` is not opened.** Both hits are shipped release notes, one announcing the
flag and one announcing its removal. Neither is edited, and no acceptance criterion below
greps them.

**D4. The prototype report is annotated, not re-issued and not rewritten.** Re-running the
reachable scenarios would be disproportionate for a gate whose subject, the unified
primitive helpers, has since shipped and is asserted by
`tests/validate-histogram-bin-counters.sh`. The annotation is dated and names the issue that
added it, which is the only change-history phrasing this sweep permits itself.

**D5. The dead pattern alternative in `tests/validate-runtime-config.sh` is in scope.**
One line, the same vocabulary as the header comment two lines above it in the same file, and
it is a vacuous assertion limb. Removing it is the same action as the header comment, not a
separate one.

**D6. Decision 7's scope word is corrected where this sweep opens the sentence.**
`features/34-histogram-bin-counter-mode.md`'s cross-consumer bullet calls the opt-out scope
"global". Decision 7 locks per-surface scope. The sweep is already rewriting that sentence,
so it states the scope correctly rather than carrying the old word into new text.

## Acceptance criteria

Each is assertable by grep and by reading. Triage below.

1. **The inventory grep over `features/`, `docs/`, `tests/` and `prototype/` returns only
   class (a), class (b), the rejection assertion, and the dated annotation.** Re-run the
   step-1 grep restricted to those four paths and read every hit. Every one falls in the
   inventory table above as class (a) or class (b), or is one of the seven hits inside
   `scenario_error_unknown_exact_percentiles`, or is inside the prototype report annotation
   or the `features/225` dated note. **Triage: assertable.** Grep plus a read of each hit.

2. **No passage under `features/`, `docs/`, `tests/` or `prototype/` instructs a reader to
   pass `--exact-percentiles` or promises `opt_out_active`, `opt_out_notice` or
   `consumers_active` output.** Read each class (c) passage after its replacement against
   `features/187-histogram-bin-counter-percentiles.md` Decision 7 (user-facing opt-out
   through the per-surface data-model selectors) and Decision 8 (the `-V` reporting contract)
   as amended by #546, and confirm each names a flag the tool accepts or output the emitter
   produces. **Triage: assertable by reading**, and grep-supported: after the sweep,
   `git grep -n 'exact-percentiles' -- features tests` returns nothing outside the class (a)
   and (b) files listed in the inventory table and the rejection assertion.

3. **`ltl --disable-progress` accepts every flag the replacement text names.** For each
   distinct invocation the replacements introduce (`-dm raw`, `-hmdm raw`, `-hgdm raw`,
   `-dmp`), run it against a committed fixture and confirm exit 0. **Triage: assertable by
   execution.** This is the criterion that catches a replacement naming a second flag that
   does not exist.

4. **`releases/` is byte-identical.** `git diff --stat release/0.18.1 -- releases/` is empty
   on the issue branch. **Triage: assertable by grep.**

5. **`tests/validate-runtime-config.sh` still asserts.** The harness runs end-to-end and its
   summary line shows assertions actually ran, with the rejection scenario among them and
   the clean-run scenario still failing if a warning fires. **Triage: assertable by
   execution.** Run the harness and read its summary, per the stability-contract step that
   requires confirming a harness still asserts rather than merely exits 0.

6. **No file #546 owns is touched.** `git diff --name-only` on the issue branch contains
   none of `features/187-histogram-bin-counter-percentiles.md`, and the diff to
   `features/426-per-message-statistics-store.md` is empty, and the diff to
   `tests/HARNESS-DESIGN.md` touches only the stability-contract key-rename example.
   **Triage: assertable by grep on the diff.**

## Completion gate

Per `docs/process/workflow.md` § 3, the scope test is applied to the diff, not to how the
change feels.

The diff touches `features/`, `prototype/`, `tests/HARNESS-DESIGN.md` and
`tests/validate-runtime-config.sh`. The first three sit in the exempt row (only
`tests/baseline/`, `build/`, `features/`, `docs/`, `releases/`, `patterns/`, `CLAUDE.md`;
`tests/HARNESS-DESIGN.md` is documentation under `tests/`, not a harness, and no harness
reads it). `tests/validate-runtime-config.sh` is a `tests/validate-*.sh` file, which is a
required row, and the table's last row settles the mix: an exempt path plus any required
path in the same commit is required.

**So the gate is the full one: the complete harness suite and a before/after benchmark on
this machine, with `$version_number` restored to `X.Y.Z` before the gate runs, on the commit
being merged.** That is a direct consequence of the one-line change in step 4 of the sweep
and nothing else. If the architect prefers the documentation-only skip, the disposition is to
drop the `tests/validate-runtime-config.sh` edits from this issue and file the dead pattern
alternative onto #545 (harnesses accept an unknown scenario selector or flag silently),
which is its natural home; the rest of the sweep then lands under a recorded skip.

The behaviour this change could have altered, named before launching the gate: the clean-run
scenario of `tests/validate-runtime-config.sh` now matches two stderr alternatives instead of
three. Nothing in `ltl` changes, so the benchmark is expected to be flat and its purpose here
is the table, not a hypothesis.

**Release notes: none.** The sweep is documentation, and the one harness line is a test-side
correction with no user-observable change. If the harness line is dropped per the paragraph
above, the answer is the same. Recorded so the close-out does not re-open the question.

## Ordering

**#546 lands first.** Both issues are delivered together and no `blocked_by` edge is needed,
because the two touch disjoint files: #546 owns
`features/187-histogram-bin-counter-percentiles.md`, the Decision 7 inventory row in
`features/426-per-message-statistics-store.md`, and the three `consumers_active: none`
worked examples in `tests/HARNESS-DESIGN.md`; this issue owns everything else in the sweep
and touches none of those three. The recommendation to land #546 first is about reading, not
about conflict: this issue's acceptance criterion 2 reads every replacement against
Decision 8 as #546 amends it, and doing that against the amended text is a real check rather
than a check against text that is about to change.

The only file both branches open is `tests/HARNESS-DESIGN.md`, at two different headings
("Stability contract" here, "Self-documenting assertions" there). If they land out of order
the rebase is mechanical, but the reading check is weaker.
