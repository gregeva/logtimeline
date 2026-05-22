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
| [#230](https://github.com/gregeva/logtimeline/issues/230) | Filter logic truth tables | OPEN |
| [#231](https://github.com/gregeva/logtimeline/issues/231) | CLI option parsing / conflict detection | OPEN |
| [#232](https://github.com/gregeva/logtimeline/issues/232) | `--help` content correctness | **CLOSED 2026-05-22** |
| [#233](https://github.com/gregeva/logtimeline/issues/233) | Empty / degenerate inputs | OPEN |
| [#234](https://github.com/gregeva/logtimeline/issues/234) | Documentation example execution | OPEN |
| [#235](https://github.com/gregeva/logtimeline/issues/235) | Extended heatmap/histogram rendering coverage | OPEN |

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
