# Feature: Test-harness coverage gaps (#225)

## Overview

This document is the **umbrella feature/requirements file** for issue #225 — a coordinated set of test-harness additions covering coverage gaps surfaced during the audit on 2026-05-21. Each sub-issue ships an independent harness; this file captures the merged requirements, decisions, and outcomes once each sub-issue lands.

Until a sub-issue ships, its scoping lives in a per-sub-issue research file (e.g. `features/232-help-coverage.md`). On sub-issue completion, its content is folded into a section here and the per-sub-issue file is deleted in the same commit.

## GitHub Issue

[#225](https://github.com/gregeva/logtimeline/issues/225) — umbrella for high-priority test-harness coverage gaps.

## Sub-issues and status

| Sub-issue | Coverage area | Status |
|---|---|---|
| [#227](https://github.com/gregeva/logtimeline/issues/227) | Packaged-binary smoke tests | **CANCELLED 2026-05-22** — cannot self-test locally without building a binary first; see issue for rationale |
| [#228](https://github.com/gregeva/logtimeline/issues/228) | Log format detection regression | **CLOSED 2026-05-22** |
| [#229](https://github.com/gregeva/logtimeline/issues/229) | Pattern file correctness | **CANCELLED 2026-05-22** — scope exceeded value; see issue for rationale |
| [#230](https://github.com/gregeva/logtimeline/issues/230) | Filter logic truth tables | **CANCELLED 2026-05-22** — depended on the cancelled #229 `-V filter-summary` section; see issue for rationale |
| [#231](https://github.com/gregeva/logtimeline/issues/231) | CLI option parsing / conflict detection | **CLOSED 2026-05-22** |
| [#232](https://github.com/gregeva/logtimeline/issues/232) | `--help` content correctness | **CLOSED 2026-05-22** |
| [#233](https://github.com/gregeva/logtimeline/issues/233) | Empty / degenerate inputs | **CANCELLED 2026-05-22** — depended on cancelled #229/#230 plus a different #228 shape than landed; see issue for rationale |
| [#234](https://github.com/gregeva/logtimeline/issues/234) | Documentation example execution | **CLOSED 2026-05-22** |
| [#235](https://github.com/gregeva/logtimeline/issues/235) | Extended heatmap/histogram rendering coverage | **CLOSED 2026-05-22** |

## Cross-cutting decisions

Decisions that apply across multiple sub-issues are captured here.

- **Harness language**: bash, matching the `tests/HARNESS-DESIGN.md` reference implementation (`tests/validate-histogram-bin-counters.sh`). Earlier per-sub-issue research often recommended Perl; the doctrine — issued after the research — supersedes.
- **Self-documenting assertions are mandatory.** Every assertion records `asserts`, `produced_by`, and `contract` fields surfaced on failure.
- **Hidden-option convention**: inline `# hidden` comment trailing the GetOptions line. Adopted by #232; available for any future sub-task that needs to distinguish intentionally-hidden from accidentally-missing flags.
- **`docs/usage.md` mismatches are hard failures** wherever a harness covers the usage-table surface. The wiki source-of-truth status (CLAUDE.md release-process step 15) makes usage.md part of the user-facing contract, not a soft reference.

---

## #232 — `--help` content correctness

### Status
**Closed 2026-05-22.** Implemented in PR #246, merge commit `8ea5b68`.

### Overview

`tests/validate-help-content.sh` — sibling to `validate-help-layout.sh` that covers content correctness rather than layout. Asserts:

1. Every flag declared in `GetOptions` appears in `print_help()` and in `docs/usage.md` — unless explicitly marked hidden.
2. Every GetOptions short form is documented in `--help`.
3. The version string emitted at every in-binary site (`-v`, `-V benchmark-data` TSV row) agrees with `$version_number` in source.

This sub-issue exists because of a documented history of drift (CLAUDE.md observation 2026-02-07: "When adding or modifying CLI options, update `print_help()` in ltl and the options reference in README.md").

### Code surfaces touched

- `tests/validate-help-content.sh` (new) — bash harness, 6 scenarios, 8 assertions.
- `ltl` — 10 GetOptions lines annotated with trailing `# hidden`.
- `docs/usage.md` — added `-hgb / --histogram-buckets` row (fixed drift identified during research).

### Scenarios

| # | Scenario | Asserts |
|---|---|---|
| A | help-contains-visible-longs | Every non-hidden GetOptions long appears in `--help` |
| B | usage-contains-visible-longs | Every non-hidden GetOptions long appears in `docs/usage.md` |
| C | help-short-forms-match-getopts | Every GetOptions short form appears in `--help` |
| D | dash-v-matches-version-number | `ltl -v` emits `Version: $version_number` |
| E | benchmark-data-version-matches | `ltl -V benchmark-data` emits the version TSV row with delimiter contract honored |
| F | description-quality (soft) | Placeholder tokens (TODO/FIXME/XXX/undocumented/TBD/tk/???) and single-word descriptions surface as warnings |

Self-test result on landing: **8 passed, 0 failed, 0 warnings.**

### GetOptions parser rule (codified)

The harness extracts `long`/`short` from each `'name1|name2'` GetOptions key by picking the **longer string as the long form**. This is robust where a contains-hyphen heuristic fails (e.g. `pause|p`, `start|st`, `end|et` — long forms with no hyphen and length < 6). Verified against all 75 current entries, including the five short-first declarations (`hgbpd`, `hgb`, `pbpd`, `pp`, `ep`) where the full spelling is on the right of the pipe but is still the longer string.

### Hidden-option convention (codified)

10 flags carry trailing `# hidden` comments on their GetOptions line:

- `disable-progress` — internal/agent-only flag
- `no-final-pass` — consolidation tuning
- `consolidation-trigger` — consolidation tuning
- `consolidation-ceiling` — consolidation tuning
- `consolidation-max-patterns` — consolidation tuning
- `final-threshold` — consolidation tuning
- `terminal-width` — test/automation hook (decided formally hidden during scoping)
- `debug-layout` — layout developer flag
- `validate-layout` — layout developer flag
- `help` — special-cased; PreProcessor aliases (`-?`, `/help`) handled outside GetOptions

The harness reads this annotation to distinguish intentionally-hidden flags from accidentally-missing ones.

### Drift fixed during this sub-task

`-hgb / --histogram-buckets` was declared in GetOptions (`ltl:4218`) and documented in `print_help()` (`ltl:1838`) but missing from the `docs/usage.md` Histogram options table (only `-hgbpd` was present at usage.md:238). This was the single concrete bug the proposed harness would have caught; fixed pre-emptively so the new harness passes on landing.

### Decisions locked

1. Hidden-option convention: inline `# hidden` comment on GetOptions line.
2. `-tw / --terminal-width`: formally hidden (it has a CI/non-TTY use case but is not user-facing for interactive analysis).
3. `docs/usage.md` mismatch is a hard failure (Scenario B).
4. Description-quality heuristic: warnings with full HARNESS-DESIGN.md documentation form.
5. Language: bash, per the HARNESS-DESIGN.md reference implementation. (Research initially recommended Perl; doctrine wins.)
6. One harness covers both mapping and version-consistency concerns.

### Stability notes for future maintainers

- The version string is currently emitted at three in-binary sites: `print_usage()` banner, `print_version()` (`-v`), and the `benchmark-data` TSV row in `print_verbose_output()` (`-V benchmark-data`). The harness asserts D and E cover the latter two; the banner is verified indirectly via `--help` exit code. If a new emission site is added, extend the harness with a matching assertion.
- The harness uses the `=== benchmark-data ===` / `=== END benchmark-data ===` delimiter contract from HARNESS-DESIGN.md. The `benchmark-data` section name is reserved (HARNESS-DESIGN.md § Reserved section names) — renames are breaking changes that require updating Scenario E's pattern in the same commit.

---

## #228 — Log format detection regression

### Status
**Closed 2026-05-22.** Implemented in PR #247, merge commit `55f44c1`.

### Overview

`tests/validate-format-detection.sh` — bash harness asserting that ltl's log-format auto-detection cascade resolves each fixture to the expected slug and `match_type`. Consumes a new `format-detection` `-V` section.

This sub-issue addresses the **silent unit-misinterpretation risk**: Apache HTTP Server's `%D` is microseconds, Tomcat 9's `%D` is milliseconds, both share the same access-log regex. Without a unit-level assertion, a 1000× off-by-unit error sails past percentile assertions because every percentile scales the same way.

### Scope reduction

7 of 14 internal `match_type` values have committed fixtures in `logs/` and are covered by the harness. The remaining 7 (`thingworx_rac_client`, `connection_server_json`, `java_gc_log`, `tw_analytics_v2`, `tw_analytics_worker`, `jboss_access`, `connection_server_standard`, `tomcat_access_common`) were deferred — they need either hand-crafted fixtures or to wait for the format-registry rewrite (#23).

### Code surfaces touched

- `ltl` — added `%match_type_to_slug` table near GLOBALS, `%format_detection` per-file accumulator, tracking sites in the line-scanning loop of `read_and_process_logs()` (both matched and unmatched branches), `emit_format_detection_verbose()` emitter, registration in `%verbose_section_registry` + `@verbose_section_order`, dispatch call from the main flow.
- `tests/validate-format-detection.sh` (new) — 7 scenarios, 16 assertions.
- `docs/test-logs.md` — corrected false claim about value-range autodetection (replaced with accurate `-du us` workaround).

### Scenarios

| # | Scenario | Fixture | Expected slug | `match_type` |
|---|---|---|---|---|
| 1 | tomcat9-ms | `localhost_access_log-twx01-...-5k.txt` | `tomcat_access_with_duration` | 3 |
| 2 | apache-httpd-us | `ApacheHTTP2Server-...2026-01-25.log` | `tomcat_access_with_duration` (misclassified — see below) | 3 |
| 3 | codebeamer | `codebeamer_access_log.2025-10-29.txt` | `tomcat_codebeamer` | 12 |
| 4 | thingworx-standard | `ApplicationLog.2025-05-05.0.log` | `thingworx_standard` | 1 |
| 5 | thingworx-with-metrics | `ScriptLog-DPMExtended-clean.log` | `thingworx_standard` (`is_access_log: yes`) | 1 |
| 6 | tw-edge-c-sdk | `rea-assets-5402_-TW_SSL_READ-...log` | `tw_edge_c_sdk` | 11 |
| 7 | csv-with-udm | `results_data_idonly-timestampMs.csv` | `csv` | 13 |

Self-test result on landing: **16 passed, 0 failed.**

### Bug fix folded into this sub-task

The match_type 12 (Codebeamer) regex captured only a single character for the duration field (`\[([0-9.])ms\]`), so any multi-digit duration like `[293ms]` fell through to match_type 3 (Tomcat). Changed to `\[([0-9.]+)ms\]`. Discovered during harness self-test against `logs/Codebeamber/codebeamer_access_log.2025-10-29.txt` which contains all multi-digit durations — every line of that fixture was being silently misclassified.

This is exactly the class of regression the harness is meant to surface.

### Doc fix folded into this sub-task

`docs/test-logs.md` previously claimed "ltl auto-detects the unit based on value ranges" — false. Replaced with accurate behavior (no autodetection; use `-du us` for Apache HTTP Server microsecond logs). Tracked for proper autodetection by issues #17/#23.

### Decisions locked

1. **Slug naming**: semantic descriptive form (e.g., `tomcat_access_with_duration`) rather than server+version (e.g., `tomcat9_access_d_ms`) or generic shape.
2. **Apache HTTP2 misclassification**: codified — Apache HTTP2 log and Tomcat 9 log resolve to the same slug today. When #23 splits the formats, the `apache-httpd-us` scenario will need an update.
3. **Single PR** vs. two-PR split: combined ltl changes + harness into one PR rather than two.

### Stability notes for future maintainers

- `%match_type_to_slug` in `ltl` GLOBALS is the **contract surface**. Slug values are stability-locked under `HARNESS-DESIGN.md § Stability contract` — renames require updating every consumer (currently just `tests/validate-format-detection.sh`) in the same commit.
- The `format-detection` `-V` section is reserved per `HARNESS-DESIGN.md § Reserved section names`.
- The Apache HTTP2 misclassification is a **known, intentional** mapping today, pending the format-registry rewrite (#23). The scenarios.apache-httpd-us assertion is the canary that will fail when #23 lands — that failure is the signal to update both the slug map and the harness in the same commit.
- The CSV path (match_type 13) requires `-udm <name>` to fire. A CSV file passed without `-udm` produces no matches and is intentional — the harness covers this with a positive scenario.

---

## #234 — Documentation example execution

### Status
**Closed 2026-05-22.** Implemented in PR #248, merge commit `d5fdac4`.

### Overview

`tests/validate-doc-examples.sh` (with `tests/extract-doc-examples.pl`) — runs every `ltl` example in `docs/usage.md` against real (truncated) fixtures, asserting exit 0 and non-empty stdout. Catches the documentation-drift class: option renames, removed flags, restructured `-V` blocks that break documented `-V | grep` patterns.

CLAUDE.md release-step 15 pushes `docs/usage.md` to the wiki at every release. Before this sub-issue, there was nothing between "release-branch ready" and "wiki overwritten with possibly-broken examples." This harness slots in at step 8b — after the version bump, before benchmarks — to gate broken examples from shipping.

### Code surfaces touched

- `tests/extract-doc-examples.pl` (new) — Perl extractor that streams markdown line-by-line, recognizes `bash`/`sh`/`shell` fences (plus unlabeled), honors `<!-- ltl-test: skip -->` immediately above a fence, and emits TSV rows `file<TAB>line<TAB>command` for each `ltl …`/`./ltl …` invocation. Handles `\` line continuations.
- `tests/validate-doc-examples.sh` (new) — bash-3.2 compatible driver. Truncates each source fixture to 1000 lines under `$TMP_DIR` at startup so the 37 example invocations complete in ~36s rather than ~1:45 against full multi-megabyte sources. Self-documenting failures per HARNESS-DESIGN.md.

No `ltl` code changes. No `docs/usage.md` edits (the substitution table lives in the harness).

### Substitution table

Maintained in `tests/validate-doc-examples.sh`:

| Placeholder | Fixture |
|---|---|
| `access.log` | `logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` |
| `app.log` | `logs/ThingworxLogs/ApplicationLog.log` |
| `error.log` | `logs/ThingworxLogs/ErrorLog.log` |

Per repo memory (`feedback_test_logs.md`), the corrupt `localhost_access_log.2025-03-21.txt` is never used.

### Self-test on landing

- Extracted: 45 candidate examples from `docs/usage.md`.
- Result: **37 passed, 0 failed, 8 skipped**.
- Skipped breakdown: 4 `-V` examples (deferred), 1 structural synopsis (`ltl [options] <logfile>`), 3 with `logs/*/access.log` style globs the substitution can't safely expand.
- Runtime: ~36 s.

### Decisions locked

1. **Hardcoded substitution table** in the harness rather than per-example annotations in docs. Keeps user-facing docs clean; one auditable place in the harness.
2. **Out of scope**: `demo-use-cases.md` (internal use), `docs/test-logs.md` (intentionally untouched in this PR), `README.md` / `CLAUDE.md` (no testable `ltl` examples beyond synopsis/build).
3. **`-V` examples deferred** — the `-V` surface is still being shaped by post-#226 follow-ups; pinning examples now would create more breakage than the harness catches.
4. **Release-gate only** — no per-PR CI integration. Slot in at step 8b of the release process.
5. **`docs/test-logs.md:191` corrupt-file reference left as-is in this PR** — separate ticket later.

### Stability notes for future maintainers

- The substitution table is the contract surface. Removing a placeholder is a breaking change for whatever example used it; adding one is non-breaking. When `docs/usage.md` introduces a new placeholder, add it to `SUBSTITUTION_KEYS`/`SUBSTITUTION_VALS` and to the substitution table above in the same commit.
- The bash-3.2 compatibility constraint (macOS system bash) is the reason for parallel arrays rather than `declare -A`. Keep that style when extending the harness.
- The `1000` line truncation is empirical. If a future example needs longer input (e.g., a time-window filter that excludes the first 1000 lines), bump `FIXTURE_LINES` rather than disabling truncation.
- `-V` examples (currently 4 in `docs/usage.md`) are excluded by a substring match on `" -V"`. When the `-V` surface stabilises and we want to bring those examples under test, remove that branch from `run_doc_example()`.

---

## #231 — CLI option parsing and conflict detection

### Status
**Closed 2026-05-22.** Implemented in PR #249, merge commit `d9dfcfd`.

### Overview

Extends the existing `runtime-config` `-V` section with two locked sub-sections (`command-line` and `environment-variable`), adds 4 stderr warnings for previously-silent override cases in `adapt_to_command_line_options()`, and ships `tests/validate-runtime-config.sh` as the harness covering both surfaces.

Targets the silent-override class: behaviors where ltl resolves a user input differently from what was asked (clamping, pushing back as positional, deprecation, env-vs-CLI override) but emits no signal. Four such sites covered in this sub-issue.

### Code surfaces touched

- `ltl` — provenance tracking in `adapt_to_command_line_options()` (`%option_provenance`, `_classify_argv_provenance()`, `_resolve_short_to_long()`); new `emit_runtime_config_verbose()` sub replacing the inline block; 4 new stderr warnings.
- `tests/validate-runtime-config.sh` (new) — bash harness, 12 scenarios, 23 assertions.

### Sub-sections (locked contract)

| Sub-section | Content |
|---|---|
| `command-line` | One row per long-flag-name supplied on the CLI. Always emits; empty body if no CLI flags. |
| `environment-variable` | One row per long-flag-name supplied via `LTL_CONFIG`. Always emits; empty body if no env var. When the same flag is also on the CLI, env-side row carries `; overridden`. |

A `defaults` sub-section was scoped at first but **dropped**: ltl resolves defaults at multiple sites scattered through `adapt_to_command_line_options()`, with several defaults emerging from user-input-dependent code paths (e.g., `$time_bucket_size` depends on the heatmap mode chosen by the user). No coherent snapshot point exists where "the defaults" are independent of user input. Defaults remain documented in `docs/usage.md` and `print_help()` — the canonical user-facing surface.

### Annotation grammar (locked, 3 forms)

- `value` — as resolved (no annotation)
- `value; overridden` — beaten by a same-flag CLI value (env-side row when both env and CLI supply the same flag)
- `value; clamped from <orig>` — out-of-range, clamped during validation (reserved for future use; no current emission site)

Semicolon-separated form matches the `histogram-bin-counters` (#189) precedent.

### Silent-override warnings (4 sites)

| # | Site | Behavior before | Behavior now |
|---|---|---|---|
| 1 | `-g <non-numeric>` | Silently pushed back as positional, default 85 threshold used | Warns to stderr |
| 2 | `-hm <non-builtin>` without `-udm` | Silently pushed back as positional, default `duration` used | Warns to stderr |
| 3 | `-pbpd` overriding `--percentile-precision` | Only visible via `-V histogram-bin-counters` | Also on stderr |
| 4 | `--exact-percentiles` | Silent; documented as deprecated | Deprecation warning on every use |

### Scenarios

| # | Scenario | Asserts |
|---|---|---|
| 1 | runtime-config-command-line | Section + command-line sub-section + supplied-flag rows present |
| 2 | runtime-config-env-only | LTL_CONFIG-supplied flag in environment-variable sub-section |
| 3 | runtime-config-env-overridden | Same flag in both sources: CLI in command-line, env in env sub-section with `; overridden` |
| 4 | warning-g-non-numeric | New stderr warning fires on `-g bogus` |
| 5 | warning-hm-non-builtin | New stderr warning fires on `-hm bogus` |
| 6 | warning-pbpd-overrides-pp | New stderr warning fires on `-pbpd 100 -pp 7` |
| 7 | warning-exact-percentiles-deprecated | Deprecation warning fires on `--exact-percentiles` |
| 8 | error-unknown-so | Exit 1, stdout has `invalid sort type` |
| 9 | error-unknown-du | Exit 1, stdout has `Invalid duration unit` |
| 10 | error-unknown-ru | Exit 1, stdout has `Invalid rate unit` |
| 11 | error-no-files | Exit 2, stdout has `unable to open any files` |
| 12 | no-warning-on-clean-run | No new warnings fire on baseline invocation |

Self-test result on landing: **23 passed, 0 failed.**

### Pinned current behavior (intentionally deferred)

- **Exit codes are inconsistent**: `print_usage()` paths exit 1, the no-files path exits 2. The harness pins both. Exit-code harmonization is a separate deferred ticket.
- **User-visible diagnostic text** (`Error: ...` lines) is emitted to **stdout** via `print_usage()`, not stderr. Only the bare `Died at ./ltl line N.` Perl trace goes to stderr. The harness asserts against stdout for the user-visible text and exit code for the failure signal.

### Decisions locked

1. **Single `-V` section** (extend `runtime-config`) rather than a new `option-resolution` section. `runtime-config` already exists; extending it avoids duplicate intent.
2. **Two sub-sections, not three** — defaults dropped due to ltl's interleaved default-resolution architecture.
3. **Annotation grammar**: `; overridden` / `; clamped from N` / no annotation. Semicolons match the #189 precedent.
4. **All 4 silent-override warnings shipped** rather than just the deprecation.
5. **Single PR** combining ltl changes + harness.

### Stability notes for future maintainers

- The `runtime-config` section is reserved per `HARNESS-DESIGN.md § Reserved section names`. The two sub-section names (`command-line`, `environment-variable`) are also stability-locked — renames are breaking changes that require updating `tests/validate-runtime-config.sh` in the same commit.
- The "env-side row shows the resolved value, not the original env-var value" behavior is a known limitation. When the same flag is in both env and CLI, the env-side row carries `; overridden` but its value is the resolved (CLI-supplied) value because reconstructing the original env value would require re-parsing `@env_args`. Documented in-code; revisit if a real harness scenario needs the original.
- The 4 stderr warnings are gated on specific input shapes. A regression that fires one on a clean run would be caught by scenario 12 (`no-warning-on-clean-run`).
- Naming: harness file is `tests/validate-runtime-config.sh` per `HARNESS-DESIGN.md § Naming rules`. Issue framing was "CLI option parsing"; section framing is `runtime-config`; the section wins the file name.

---

## #235 — Extended heatmap/histogram rendering coverage

### Status
**Closed 2026-05-22.** Implemented in PR #251, merge commit `5c05af2`.

### Overview

Extends `tests/validate-regression.sh` and `tests/capture-regression.sh` with 19 new byte-identical fixture combinations covering heatmap and histogram rendering surfaces not exercised today. Brings the byte-identical regression suite from 19 → 38 fixtures.

No `ltl` code changes — fixtures + harness wiring only.

### Code surfaces touched

- `tests/validate-regression.sh` — `APACHE_LOG` variable added; 19 new `run_test` invocations.
- `tests/capture-regression.sh` — mirror additions in lockstep.
- `tests/reference-output/` — 19 new fixture files (heatmap × 7, histogram × 11, composition × 1).

### New fixture inventory

| Surface | New fixtures |
|---|---|
| Heatmap at narrow widths | `heatmap-duration-w80`, `heatmap-duration-w100`, `heatmap-bytes-w120`, `heatmap-count-w100` |
| Light-background palette | `heatmap-lbg-duration-w160` |
| Custom heatmap width | `heatmap-hmw30-duration-w160`, `heatmap-hmw80-duration-w160` |
| Histogram single-metric × widths | `hg-duration-w80`, `hg-duration-w120`, `hg-duration-w160` |
| Histogram per metric | `hg-bytes-w160`, `hg-count-w160` |
| Multi-histogram panels | `hg-multi-duration-bytes-w160`, `hg-multi-all-w160` |
| Custom histogram dimensions | `hg-hgw30-duration-w160`, `hg-hgw50-multi-w160`, `hg-hgh4-duration-w160`, `hg-hgh16-duration-w160` |
| Composition (heatmap + histogram) | `hm-hg-duration-w160` |

### `--exact-percentiles` policy

All new fixtures use `--exact-percentiles` for the same reason as the existing heatmap fixtures: pins to the sort-and-index path so the reference stays byte-stable while bin-counter precision work (#34/#187/#201) lands. `calculate_histogram_buckets()` at `ltl:5630-5635` dispatches through the same opt-out flag, so the policy applies to histogram fixtures too.

A future audit (separate issue) should re-capture all fixtures without `--exact-percentiles` once the unified path is locked, and migrate the harness off the deprecated flag.

### Logs used

- **`SCRIPT_LOG`** (existing) — `ScriptLog-DPMExtended-clean.log` for heatmap scenarios and count-axis / three-panel histogram scenarios.
- **`APACHE_LOG`** (new) — `ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` for access-log-flavoured histogram fixtures. Clean Apache HTTP2 log, ~100 KB, bytes + microsecond-%D durations.

Per repo memory (`feedback_test_logs.md`), no new fixture uses the corrupt `localhost_access_log.2025-03-21.txt`. Existing `SCRIPT_LOG` variable retained as-is (not renamed to `DPM_LOG` as the research proposed) to avoid touching the 19 existing fixture invocations.

### Light-background determinism

Light-background auto-detection is **inert under shell redirection** — `ltl:2722` checks `-t STDOUT` before issuing the OSC 11 query. The capture script pipes output, so the auto-detect path returns 0 without querying the terminal. No `NO_COLOR=1` environment override needed for fixture stability.

**Issue #250** (filed during this work) tracks the missing explicit `--no-light-background` / `--dark-background` flag, which would be the proper defense if a future change to that auto-detect heuristic perturbs fixtures.

### Decisions locked

1. **`-lbg` capture environment**: rely on the non-TTY pipe check at `ltl:2722` (not `NO_COLOR=1`). After inspecting the auto-detect code, the safety is already in place.
2. **`-hgw 30` at narrow width is fine** — fixture rendering verified deterministic at that scale.
3. **Existing fixtures NOT migrated** off the corrupt 2025-03-21 log. Separate ticket if it happens.
4. **Composition fixture named `hm-hg-duration-w160`** (not `heatmap-hg-...` or `combo-...`).
5. **Both `-hgh 4` (low) AND `-hgh 16` (high) shipped** — guards layout drift symmetry. Brought new fixture count from 18 → 19.

### Self-test on landing

- `tests/validate-regression.sh`: **38 pass, 0 fail, 0 skip**
- **Idempotency confirmed**: two consecutive `capture-regression.sh` runs produce byte-identical fixture output (no non-determinism)
- Sibling harnesses unaffected: `validate-help-content` (8/0), `validate-format-detection` (16/0), `validate-help-layout` (9/0), `validate-runtime-config` (23/0)
- Capture runtime: ~47s wall-clock for all 38 fixtures

### Stability notes for future maintainers

- The `--exact-percentiles` flag is documented-deprecated (warning now fires per #231); when it's removed, this harness needs to be re-captured against whatever the new opt-out mechanism is, OR the harness has to migrate to non-byte-identical assertions for heatmap/histogram (probably bin-counter-precision-aware tolerance bands). Captured behavior here is anchored on the current opt-out flag.
- The light-background fixture (`heatmap-lbg-duration-w160`) is deterministic today only because of the non-TTY pipe check at `ltl:2722`. If `detect_light_terminal_background()` is ever refactored to engage under piped stdout, this fixture will perturb across machines. Issue #250 should land as the defensive measure before any such refactor.
- The `APACHE_LOG` variable is the canonical clean small-access-log fixture for new tests. Use it (not the corrupt 2025-03-21 file) for any future access-log-flavoured fixture.
- Both scripts must move in lockstep when fixtures are added — `validate-regression.sh` asserts on what `capture-regression.sh` produces.
